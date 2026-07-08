#!/usr/bin/env bash
# run_seed_verify.sh -- Phi1 (R1) RELIABLE per-function SVIR verify instrument over the iiis-0 C seed.
#
# Measures, for each seed module (COMPILER/BOOT/{lex,sema,emit,ast,cg_r3,parse}.c), how many of its functions
# ccsv emits as STRUCTURALLY-VALID SVIR (svir_verify accepts) vs how many fail -- the "183/659"-class number,
# but reproducibly and with the function NAMES.  STRUCTURAL only: a passing function may still be behaviorally
# wrong (ccsv is permissive), so a dropping count is NOT progress without a per-construct behavioral test
# (run_ccsv.sh's cfeat pattern).  This script measures; it does not certify behavior.
#
# Reliability gates (run BEFORE trusting any seed reading -- the discipline the prior 38-round grind lacked):
#   - POSITIVE hand control  (_ve_goodmod): a valid module must report "# 1 0 0 0".
#   - NEGATIVE hand control  (_ve_badmod) : an unknown-opcode module must report "# 1 1 2 2".
#   - POSITIVE pipeline ctrl (sha256.c)   : a known-all-99 real file must report verify_fail=0.
#   - SELF-CHECK per module : the first in-order nonzero per-fn rc MUST equal whole-module svir_verify's rc.
# gcc here is the HARNESS/oracle (links instrument tools, builds ccsv.exe); the trusted artifact path
# ccsv->SVIR->sovas->sovld stays gcc-free.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"; SEED="$ROOT/COMPILER/BOOT"
mkdir -p "$W"
say(){ echo "[seed-verify] $*"; }
fail=0

# --- build instrument pieces ---
"$IIIS" "$S/svir_verify.iii" --compile-only --out "$W/svir_verify.o" >/dev/null 2>&1 || { say "FAIL compile svir_verify.iii"; exit 1; }
"$IIIS" "$S/verify_each.iii"  --compile-only --out "$W/verify_each.o"  >/dev/null 2>&1 || { say "FAIL compile verify_each.iii"; exit 1; }
"$IIIS" "$S/ccsv.iii" --compile-only --out "$W/ccsv.o" >/dev/null 2>&1 && gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null || { say "FAIL build ccsv.exe"; exit 1; }

run_ve(){ # $1 = module-under-test .o ; echoes instrument stdout (per-fn "idx rc" lines + "# nfunc fail firstnz whole")
  gcc "$W/verify_each.o" "$W/svir_verify.o" "$1" -o "$W/_ve.exe" 2>/dev/null && "$W/_ve.exe" 2>/dev/null
}

# --- INSTRUMENT CONTROLS ---
"$IIIS" "$S/_ve_goodmod.iii" --compile-only --out "$W/_ve_goodmod.o" >/dev/null 2>&1 || { say "FAIL compile _ve_goodmod"; exit 1; }
"$IIIS" "$S/_ve_badmod.iii"  --compile-only --out "$W/_ve_badmod.o"  >/dev/null 2>&1 || { say "FAIL compile _ve_badmod"; exit 1; }
gsum=$(run_ve "$W/_ve_goodmod.o" | grep '^#'); say "control POSITIVE (good module): [$gsum]  expect [# 1 0 0 0]"
bsum=$(run_ve "$W/_ve_badmod.o"  | grep '^#'); say "control NEGATIVE (bad  module): [$bsum]  expect [# 1 1 2 2]"
[ "$gsum" = "# 1 0 0 0" ] || { say "INSTRUMENT BROKEN: positive control failed -- aborting (a green reading would be worthless)"; exit 1; }
[ "$bsum" = "# 1 1 2 2" ] || { say "INSTRUMENT BROKEN: negative control failed -- aborting (cannot detect failures)"; exit 1; }

# --- POSITIVE PIPELINE CONTROL: sha256.c (known all-99) ---
"$W/ccsv.exe" "$S/sha256.c" > "$W/gen_sha.iii" 2>/dev/null
"$IIIS" "$W/gen_sha.iii" --compile-only --out "$W/gen_sha.o" >/dev/null 2>&1 || { say "FAIL iiis-2 compile of ccsv(sha256.c)"; exit 1; }
shasum=$(run_ve "$W/gen_sha.o" | grep '^#'); shafail=$(echo "$shasum" | awk '{print $3}')
say "control PIPELINE (sha256.c)  : [$shasum]  expect fail=0"
[ "$shafail" = "0" ] || { say "REGRESSION: sha256.c has $shafail verify-failures (expected 0) -- instrument or ccsv broke"; exit 1; }
say "=== INSTRUMENT VALIDATED (3 controls + self-check armed). Measuring the seed. ==="

# --- SEED MEASUREMENT ---
total=0; totfn=0
for m in lex sema emit ast cg_r3 parse main; do
  "$W/ccsv.exe" "$SEED/$m.c" > "$W/seed_$m.iii" 2>/dev/null
  "$IIIS" "$W/seed_$m.iii" --compile-only --out "$W/seed_$m.o" >/dev/null 2>&1 || { say "$m.c: FAIL iiis-2 compile of ccsv output (cannot measure)"; fail=1; continue; }
  "$W/ccsv.exe" "$SEED/$m.c" dbg > "$W/names_$m.txt" 2>/dev/null    # "idx: name"
  out=$(run_ve "$W/seed_$m.o"); echo "$out" | grep -v '^#' > "$W/ve_$m.txt"
  sum=$(echo "$out" | grep '^#')
  nfn=$(echo "$sum"|awk '{print $2}'); ffail=$(echo "$sum"|awk '{print $3}'); fnz=$(echo "$sum"|awk '{print $4}'); whole=$(echo "$sum"|awk '{print $5}')
  sc="ok"; if [ -n "${fnz:-}" ] && [ "$fnz" != "0" ] && [ "$fnz" != "$whole" ]; then sc="SELFCHECK-MISMATCH(firstnz=$fnz whole=$whole)"; fail=1; fi
  say "$m.c: nfunc=$nfn verify_fail=$ffail firstnz=$fnz whole=$whole [$sc]"
  total=$((total+${ffail:-0})); totfn=$((totfn+${nfn:-0}))
done
say "================ SEED TOTAL: verify_fail=$total over nfunc=$totfn functions (7 modules -- the WHOLE iiis-0 seed incl. main.c) ================"
# STRUCTURAL-ZERO RATCHET (2026-07-08): the whole seed reached verify_fail=0 (866 module fns + 344
# main.c fns incl. the appended double runtime).  Down-only: any future ccsv/seed edit that reopens a
# structural failure reddens this gate -- 0 is the pin, not a hope.
if [ "$total" != "0" ]; then say "RATCHET RED: verify_fail=$total (pin is 0)"; fail=1; fi
exit $fail
