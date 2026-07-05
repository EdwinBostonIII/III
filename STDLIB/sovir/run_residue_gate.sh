#!/usr/bin/env bash
# run_residue_gate.sh -- THE REFINERY (Task F2c #1): the Residue-Stability RATCHET.  Regenerate the SER_CRUSH_REPORT
# from REAL ccsv output every build and gate its FNV fingerprint against a sealed golden.  If a CRUSHED function
# reverts to DEFERRED (residue drift) or a proven delta changes, the hash moves and the build ABORTS.  --reseal
# authorizes a new golden; an optional 2nd arg is the C corpus to crush.  gcc is ccsv's oracle assembler ONLY.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/_seqprobe"; mkdir -p "$W"
GOLDEN="$S/_residue_manifest.golden"; MANIFEST="$W/_residue_manifest.txt"   # regenerable -> build probe dir (never dirties sovir/)
RESEAL=0; [ "${1:-}" = "--reseal" ] && RESEAL=1
say(){ echo "[residue] $*"; }
"$IIIS" "$S/ccsv.iii" --compile-only --out "$W/ccsv.o" >/dev/null 2>&1 || { say "FAIL ccsv"; exit 2; }
gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null
"$IIIS" "$ROOT/STDLIB/iii/numera/ser_antiunify.iii" --compile-only --out "$W/au.o" >/dev/null 2>&1
SRC="${2:-$S/seed_loops_corpus.c}"
[ -f "$SRC" ] || cat > "$SRC" <<'CEOF'
int affine()  { int acc = 0; int i = 0; while (i < 10) { acc = acc + 5; i = i + 1; } return acc; }
int geo()     { int acc = 1; int i = 0; while (i < 10) { acc = acc * 2; i = i + 1; } return acc; }
int tri()     { int acc = 0; int i = 0; while (i < 10) { acc = acc + i; i = i + 1; } return acc; }
int chaotic() { int acc = 1; int i = 0; while (i < 10) { acc = acc * acc + 1; i = i + 1; } return acc; }
int main()    { return affine() + geo() + tri() + chaotic(); }
CEOF
cp "$W/ccsv.exe" "$W/ccsv.run.exe"; timeout 20 "$W/ccsv.run.exe" "$SRC" > "$W/seed_svir.iii" 2>/dev/null; rm -f "$W/ccsv.run.exe"
"$IIIS" "$W/seed_svir.iii" --compile-only --out "$W/seed_svir.o" >/dev/null 2>&1 || { say "FAIL ccsv SVIR"; exit 2; }
cat > "$W/seed_gate.c" <<'GEOF'
#include <stdio.h>
extern unsigned long long svir_ptr(); extern unsigned long long svir_len();
extern unsigned au_crush_svir_module(unsigned long long, unsigned long long, unsigned);
extern unsigned au_report_n(); extern unsigned au_report_verdict(unsigned); extern unsigned au_report_kind(unsigned);
extern unsigned long long au_report_delta(unsigned), au_report_off(unsigned), au_report_hash();
int main(){
  unsigned crushed = au_crush_svir_module(svir_ptr(), svir_len(), 0);
  unsigned n = au_report_n();
  for(unsigned i=0;i<n;i++) printf("  loop@%-3llu %s %s=%llu\n", au_report_off(i),
    au_report_verdict(i)?(au_report_kind(i)==4?"CRUSHED(cpy)  ":au_report_kind(i)==3?"CRUSHED(sto)  ":au_report_kind(i)==2?"CRUSHED(qad)  ":au_report_kind(i)?"CRUSHED(mul)  ":"CRUSHED(add)  "):"DEFER(residue)",
    au_report_verdict(i)?(au_report_kind(i)>=3?"c":au_report_kind(i)==2?"q":au_report_kind(i)?"r":"d"):"d", au_report_delta(i));
  printf("loops=%u crushed=%u deferred=%u\n", n, crushed, n-crushed);
  printf("REPORT_HASH=%016llx\n", au_report_hash());
  return 0;
}
GEOF
gcc "$W/seed_gate.c" "$W/seed_svir.o" "$W/au.o" "$W/causal.o" "$W/absint.o" "$W/sks.o" "$W/bb.o" "$ROOT/STDLIB/build/iii/libiii_native.a" -lws2_32 -lkernel32 -o "$W/sgate.exe" 2>/dev/null || { say "FAIL link"; exit 2; }
cp "$W/sgate.exe" "$W/sgate.run.exe"; "$W/sgate.run.exe" > "$MANIFEST" 2>/dev/null; rm -f "$W/sgate.run.exe"
HASH=$(grep REPORT_HASH "$MANIFEST" | head -1 | cut -d= -f2)
cat "$MANIFEST"
if [ $RESEAL -eq 1 ]; then echo "$HASH" > "$GOLDEN"; say "RESEALED golden=$HASH (authorized)"; exit 0; fi
if [ ! -f "$GOLDEN" ]; then echo "$HASH" > "$GOLDEN"; say "SEALED (first run) golden=$HASH"; exit 0; fi
GOLD=$(cat "$GOLDEN")
if [ "$HASH" = "$GOLD" ]; then say "RESIDUE STABLE $HASH -- affine-fraction frozen, residue witnessed."; exit 0
else say "RESIDUE DRIFT: $HASH != golden $GOLD -- a crush verdict/delta CHANGED. BUILD ABORT."; exit 1; fi
