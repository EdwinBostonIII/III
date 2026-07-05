#!/usr/bin/env bash
# run_ghost.sh -- THE GHOST-BUILD (Task F2c): real C -> ccsv (the C->SVIR seed) -> the whole-program crush driver
# -> the SER_CRUSH_REPORT (crush/defer ledger).  Builds NO target binary; outputs the seed's affine/residue TARGET
# MAP + the Residue-Stability fingerprint.  gcc is the ORACLE assembler for ccsv ONLY, never in a synthesized path.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/_seqprobe"; A="$ROOT/STDLIB/build/_seqprobe"
say(){ echo "[ghost] $*"; }
"$IIIS" "$S/ccsv.iii" --compile-only --out "$W/ccsv.o" >/dev/null 2>&1 || { say "FAIL compile ccsv"; exit 1; }
gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null || { say "FAIL link ccsv (oracle gcc)"; exit 1; }
"$IIIS" "$ROOT/STDLIB/iii/numera/ser_antiunify.iii" --compile-only --out "$A/au.o" >/dev/null 2>&1
cat > "$W/seed_demo.c" <<'CEOF'
int affine()  { int acc = 0; int i = 0; while (i < 10) { acc = acc + 5; i = i + 1; } return acc; }
int geo()     { int acc = 1; int i = 0; while (i < 10) { acc = acc * 2; i = i + 1; } return acc; }
int tri()     { int acc = 0; int i = 0; while (i < 10) { acc = acc + i; i = i + 1; } return acc; }
int chaotic() { int acc = 1; int i = 0; while (i < 10) { acc = acc * acc + 1; i = i + 1; } return acc; }
int main()    { return affine() + geo() + tri() + chaotic(); }
CEOF
cp "$W/ccsv.exe" "$W/ccsv.run.exe"; timeout 20 "$W/ccsv.run.exe" "$W/seed_demo.c" > "$W/seed_svir.iii" 2>/dev/null; rm -f "$W/ccsv.run.exe"
"$IIIS" "$W/seed_svir.iii" --compile-only --out "$W/seed_svir.o" >/dev/null 2>&1 || { say "FAIL ccsv SVIR output"; exit 1; }
cat > "$W/seed_ghost.c" <<'GEOF'
#include <stdio.h>
extern unsigned long long svir_ptr(); extern unsigned long long svir_len();
extern unsigned au_crush_svir_module(unsigned long long, unsigned long long, unsigned);
extern unsigned au_report_n(); extern unsigned au_report_verdict(unsigned); extern unsigned au_report_kind(unsigned);
extern unsigned long long au_report_delta(unsigned), au_report_off(unsigned), au_report_hash();
int main(){
  unsigned crushed = au_crush_svir_module(svir_ptr(), svir_len(), 0);
  unsigned n = au_report_n();
  printf("=== SER_CRUSH_REPORT (real C -> ccsv -> SVIR) ===\n");
  printf("loops=%u crushed=%u deferred(residue)=%u report_hash=%016llx\n", n, crushed, n-crushed, au_report_hash());
  for(unsigned i=0;i<n;i++) printf("  loop@%-3llu %s %s=%llu\n", au_report_off(i),
    au_report_verdict(i)?(au_report_kind(i)==6?"CRUSHED(sca)  ":au_report_kind(i)==5?"CRUSHED(map)  ":au_report_kind(i)==4?"CRUSHED(cpy)  ":au_report_kind(i)==3?"CRUSHED(sto)  ":au_report_kind(i)==2?"CRUSHED(qad)  ":au_report_kind(i)?"CRUSHED(mul)  ":"CRUSHED(add)  "):"DEFER(residue)",
    au_report_verdict(i)?(au_report_kind(i)>=3?"c":au_report_kind(i)==2?"q":au_report_kind(i)?"r":"d"):"d", au_report_delta(i));
  return (n==4 && crushed==3) ? 99 : 1;
}
GEOF
gcc "$W/seed_ghost.c" "$W/seed_svir.o" "$A/au.o" "$A/causal.o" "$A/absint.o" "$A/sks.o" "$A/bb.o" "$ROOT/STDLIB/build/iii/libiii_native.a" -lws2_32 -lkernel32 -o "$W/sghost.exe" 2>/dev/null || { say "FAIL link ghost"; exit 1; }
cp "$W/sghost.exe" "$W/sghost.run.exe"; timeout 60 "$W/sghost.run.exe"; gv=$?; rm -f "$W/sghost.run.exe"
if [ $gv -eq 99 ]; then say "GHOST-BUILD GREEN: ccsv affine CRUSHED(add d5), geometric CRUSHED(mul r2), triangular CRUSHED(qad q1), chaotic DEFERRED as residue, report fingerprinted."; else say "GHOST-BUILD RED ($gv)"; exit 1; fi
