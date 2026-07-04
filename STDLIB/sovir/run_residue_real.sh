#!/usr/bin/env bash
# run_residue_real.sh -- the REAL-SEED residue ratchet (2026-07-04): the crush ladder against a REAL C file.
# The toy corpus (seed_loops_corpus.c) witnesses each rung; THIS gate witnesses the AT-SCALE truth: ccsv
# compiles sha256.c (real crypto C) to SVIR and the whole-module walk records every loop's verdict.  Measured
# at introduction: loops=4 crushed=0 deferred=4 -- every sha256 loop is a MEMORY-fragment loop (w[] schedule,
# rounds, byte packing), and the scalar ladder's interpreter honestly refuses memory opcodes BEFORE any fit,
# so the whole population is residue.  That is the roadmap: the next capability that crushes a real-seed loop
# (the B2 stride lift composed into the walk) MOVES this fingerprint, and this gate says so.  The slot sweep
# at introduction showed the ledger is accum-slot-invariant on this module (all 8 slots -> the same hash);
# the gate pins accum=0.  --reseal authorizes a new golden; an optional 2nd arg swaps the C seed.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/_seqprobe"; mkdir -p "$W"
GOLDEN="$S/_residue_real.golden"; MANIFEST="$W/_residue_real.txt"
RESEAL=0; [ "${1:-}" = "--reseal" ] && RESEAL=1
SRC="${2:-$S/sha256.c}"
say(){ echo "[residue-real] $*"; }
"$IIIS" "$S/ccsv.iii" --compile-only --out "$W/ccsv.o" >/dev/null 2>&1 || { say "FAIL ccsv"; exit 2; }
gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null
"$IIIS" "$ROOT/STDLIB/iii/numera/ser_antiunify.iii" --compile-only --out "$W/au.o" >/dev/null 2>&1
cp "$W/ccsv.exe" "$W/ccsv.rr.exe"; timeout 60 "$W/ccsv.rr.exe" "$SRC" > "$W/real_svir.iii" 2>/dev/null; rm -f "$W/ccsv.rr.exe"
"$IIIS" "$W/real_svir.iii" --compile-only --out "$W/real_svir.o" >/dev/null 2>&1 || { say "FAIL ccsv SVIR"; exit 2; }
cat > "$W/real_gate.c" <<'GEOF'
#include <stdio.h>
extern unsigned long long svir_ptr(); extern unsigned long long svir_len();
extern unsigned au_crush_svir_module(unsigned long long, unsigned long long, unsigned);
extern unsigned au_report_n(); extern unsigned au_report_verdict(unsigned); extern unsigned au_report_kind(unsigned);
extern unsigned long long au_report_delta(unsigned), au_report_off(unsigned), au_report_hash();
int main(){
  unsigned crushed = au_crush_svir_module(svir_ptr(), svir_len(), 0);
  unsigned n = au_report_n();
  for(unsigned i=0;i<n;i++) printf("  loop@%-4llu %s %s=%llu\n", au_report_off(i),
    au_report_verdict(i)?(au_report_kind(i)==2?"CRUSHED(qad)  ":au_report_kind(i)?"CRUSHED(mul)  ":"CRUSHED(add)  "):"DEFER(residue)",
    au_report_verdict(i)?(au_report_kind(i)==2?"q":au_report_kind(i)?"r":"d"):"d", au_report_delta(i));
  printf("loops=%u crushed=%u deferred=%u\n", n, crushed, n-crushed);
  printf("REPORT_HASH=%016llx\n", au_report_hash());
  return 0;
}
GEOF
gcc "$W/real_gate.c" "$W/real_svir.o" "$W/au.o" "$W/causal.o" "$W/absint.o" "$W/sks.o" "$W/bb.o" "$ROOT/STDLIB/build/iii/libiii_native.a" -lws2_32 -lkernel32 -o "$W/rgate.exe" 2>/dev/null || { say "FAIL link"; exit 2; }
cp "$W/rgate.exe" "$W/rgate.run.exe"; timeout 120 "$W/rgate.run.exe" > "$MANIFEST" 2>/dev/null; rm -f "$W/rgate.run.exe"
HASH=$(grep REPORT_HASH "$MANIFEST" | head -1 | cut -d= -f2)
cat "$MANIFEST"
if [ $RESEAL -eq 1 ]; then echo "$HASH" > "$GOLDEN"; say "RESEALED golden=$HASH (authorized)"; exit 0; fi
if [ ! -f "$GOLDEN" ]; then echo "$HASH" > "$GOLDEN"; say "SEALED (first run) golden=$HASH"; exit 0; fi
GOLD=$(cat "$GOLDEN")
if [ "$HASH" = "$GOLD" ]; then say "REAL-SEED RESIDUE STABLE $HASH -- sha256's loop population is memory-fragment residue; the scalar ladder's honest boundary, witnessed."; exit 0
else say "REAL-SEED RESIDUE DRIFT: $HASH != golden $GOLD -- a real-seed loop verdict CHANGED (a rung reached the real seed, or a regression). BUILD ABORT."; exit 1; fi
