#!/usr/bin/env bash
# run_residue_real.sh -- the REAL-SEED residue ratchet (2026-07-04): the crush ladder against the WHOLE
# real-C population in sovir/.  The toy corpus witnesses each rung; THIS gate witnesses the AT-SCALE truth:
# ccsv compiles every real C file below to SVIR and the whole-module walk records every loop's verdict.
#
# History of this gate doing its job (each drift -> BUILD ABORT -> authorized reseal):
#   intro     : sha256.c only, 4/4 loops DEFER (memory fragment untouched)      golden 45b11a82e112591e
#   STORE rung: M[i]=0    -> CRUSHED(sto) s4 v0 w4                              golden d82d059e9b1ca497
#   COPY rung : W[t]=M[t] -> CRUSHED(cpy) s4 d1000... width-masked pass-through golden 2a822ee9954efc29
#   population: the gate now covers EVERY ccsv-compilable real C file; the golden is the per-file hash
#               MANIFEST (one line per file), so a drift names exactly WHICH file's ledger moved.
#
# The schedule/rounds loops are PERMANENT honest residue: cryptographic diffusion has no low-degree
# closed form (a "crushable" SHA round would be a break, not a rung).  The gate pins accum=0.
# --reseal authorizes a new golden.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/_seqprobe"; mkdir -p "$W"
GOLDEN="$S/_residue_real.golden"; SUMMARY="$W/_residue_real_summary.txt"
RESEAL=0; [ "${1:-}" = "--reseal" ] && RESEAL=1
FILES="sha256.c aes128.c chacha20.c hmac_sha256.c sha256_full.c sha256_generic.c ceiling_sha_core.c"
say(){ echo "[residue-real] $*"; }
"$IIIS" "$S/ccsv.iii" --compile-only --out "$W/ccsv.o" >/dev/null 2>&1 || { say "FAIL ccsv"; exit 2; }
gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null
"$IIIS" "$ROOT/STDLIB/iii/numera/ser_antiunify.iii" --compile-only --out "$W/au.o" >/dev/null 2>&1
cat > "$W/real_gate.c" <<'GEOF'
#include <stdio.h>
extern unsigned long long svir_ptr(); extern unsigned long long svir_len();
extern unsigned au_crush_svir_module(unsigned long long, unsigned long long, unsigned);
extern unsigned au_report_n(); extern unsigned au_report_verdict(unsigned); extern unsigned au_report_kind(unsigned);
extern unsigned au_report_why(unsigned);
extern unsigned long long au_report_delta(unsigned), au_report_off(unsigned), au_report_hash();
static const char*WHY[9]={"crush","frag ","nofit","refut","symtp","poisn","multi","memft","nest "};
int main(){
  unsigned crushed = au_crush_svir_module(svir_ptr(), svir_len(), 0);
  unsigned n = au_report_n();
  for(unsigned i=0;i<n;i++){
    unsigned w = au_report_why(i); if (w > 8) w = 0;
    if (au_report_verdict(i)) printf("  loop@%-4llu %s %s=%llu\n", au_report_off(i),
      au_report_kind(i)==6?"CRUSHED(sca)  ":au_report_kind(i)==5?"CRUSHED(map)  ":au_report_kind(i)==4?"CRUSHED(cpy)  ":au_report_kind(i)==3?"CRUSHED(sto)  ":au_report_kind(i)==2?"CRUSHED(qad)  ":au_report_kind(i)?"CRUSHED(mul)  ":"CRUSHED(add)  ",
      au_report_kind(i)>=3?"c":au_report_kind(i)==2?"q":au_report_kind(i)?"r":"d", au_report_delta(i));
    else printf("  loop@%-4llu DEFER[%s]   d=%llu\n", au_report_off(i), WHY[w], au_report_delta(i));
  }
  printf("loops=%u crushed=%u deferred=%u\n", n, crushed, n-crushed);
  printf("REPORT_HASH=%016llx\n", au_report_hash());
  return 0;
}
GEOF
: > "$SUMMARY"
for f in $FILES; do
    cp "$W/ccsv.exe" "$W/ccsv.rr.exe"; timeout 60 "$W/ccsv.rr.exe" "$S/$f" > "$W/real_svir.iii" 2>/dev/null; rm -f "$W/ccsv.rr.exe"
    "$IIIS" "$W/real_svir.iii" --compile-only --out "$W/real_svir.o" >/dev/null 2>&1 || { say "FAIL ccsv SVIR for $f"; exit 2; }
    gcc "$W/real_gate.c" "$W/real_svir.o" "$W/au.o" "$W/causal.o" "$W/absint.o" "$W/sks.o" "$W/bb.o" "$ROOT/STDLIB/build/iii/libiii_native.a" -lws2_32 -lkernel32 -o "$W/rgate.exe" 2>/dev/null || { say "FAIL link for $f"; exit 2; }
    cp "$W/rgate.exe" "$W/rgate.run.exe"; timeout 240 "$W/rgate.run.exe" > "$W/_rr_one.txt" 2>/dev/null; rc=$?; rm -f "$W/rgate.run.exe"
    if [ $rc -ne 0 ]; then say "FAIL crush run for $f (rc=$rc)"; exit 2; fi
    echo "== $f =="
    cat "$W/_rr_one.txt"
    H=$(grep REPORT_HASH "$W/_rr_one.txt" | head -1 | cut -d= -f2)
    L=$(grep "^loops=" "$W/_rr_one.txt" | head -1)
    echo "$f $H $L" >> "$SUMMARY"
done
if [ $RESEAL -eq 1 ]; then cp "$SUMMARY" "$GOLDEN"; say "RESEALED golden manifest (authorized):"; sed 's/^/[residue-real]   /' "$GOLDEN"; exit 0; fi
if [ ! -f "$GOLDEN" ]; then cp "$SUMMARY" "$GOLDEN"; say "SEALED (first run) golden manifest:"; sed 's/^/[residue-real]   /' "$GOLDEN"; exit 0; fi
if cmp -s "$SUMMARY" "$GOLDEN"; then
    say "REAL-SEED RESIDUE STABLE ($(wc -l < "$SUMMARY" | tr -d ' ') files) -- the certified fraction frozen, the data-dependent residue witnessed."
    exit 0
fi
say "REAL-SEED RESIDUE DRIFT -- a real-seed ledger CHANGED (a rung reached a file, or a regression).  BUILD ABORT.  Diff:"
diff "$GOLDEN" "$SUMMARY" | sed 's/^/[residue-real]   /'
exit 1
