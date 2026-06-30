#!/usr/bin/env bash
# run_fnptr_gate.sh -- durable regression guard for the fn-pointer feature, INCREMENT 1 (ccsv codegen).
#
# WHY a separate gate (not run_ccsv's cfeat): cfeat requires all-4 (svir_verify + sovereign-x86 + wasm + gcc).
# INC-1 lands ccsv's CALL_INDIRECT *codegen*; the x86/wasm backends do NOT yet implement the computed-call
# (that is INC-3).  So INC-1's honest standard is the THREE oracles that are valid now: svir_verify (structural),
# svir_interp (the independent reference executor -- the runtime oracle), and gcc (the reference semantics).
# test_fnptr.c bakes in the INDEX-SPACE-AGREEMENT teeth: add->14, sub->6; a swap of their indices yields r1=6,
# r2=14 -> returns 1, not 99.  So a 99 here proves the indirect dispatch hits the RIGHT function.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"
mkdir -p "$W"; say(){ echo "[fnptr-gate] $*"; }
"$IIIS" "$S/ccsv.iii"         --compile-only --out "$W/ccsv.o"         >/dev/null 2>&1 && gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null || { say "FAIL build ccsv"; exit 1; }
"$IIIS" "$S/svir_verify.iii"  --compile-only --out "$W/svir_verify.o"  >/dev/null 2>&1 || { say "FAIL svir_verify"; exit 1; }
"$IIIS" "$S/verify_each.iii"  --compile-only --out "$W/verify_each.o"  >/dev/null 2>&1 || { say "FAIL verify_each"; exit 1; }
"$IIIS" "$S/svir_interp.iii"  --compile-only --out "$W/svir_interp.o"  >/dev/null 2>&1 || { say "FAIL svir_interp"; exit 1; }

"$W/ccsv.exe" "$S/test_fnptr.c" > "$W/g_fnptr.iii" 2>/dev/null
"$IIIS" "$W/g_fnptr.iii" --compile-only --out "$W/gen_svir.o" >/dev/null 2>&1 || { say "FAIL iiis compile of ccsv(test_fnptr.c)"; exit 1; }
# 1. structural: svir_verify must accept every function (fail count = 0)
gcc "$W/verify_each.o" "$W/svir_verify.o" "$W/gen_svir.o" -o "$W/_ve_fnptr.exe" 2>/dev/null
vsum=$("$W/_ve_fnptr.exe" 2>/dev/null | grep '^#'); vfail=$(echo "$vsum" | awk '{print $3}')
# 2. runtime: the reference interpreter (independent executor) -- index-agreement teeth -> 99
gcc "$W/svir_interp.o" "$W/gen_svir.o" -o "$W/_interp_fnptr.exe" 2>/dev/null
"$W/_interp_fnptr.exe" >/dev/null 2>&1; ir=$?
# 3. reference: gcc semantics -> 99
gcc "$S/test_fnptr.c" -o "$W/_ref_fnptr.exe" 2>/dev/null; "$W/_ref_fnptr.exe" >/dev/null 2>&1; gr=$?
say "svir_verify=[$vsum] (fail=$vfail)  svir_interp=$ir  gcc=$gr  (all want: fail=0, interp=99, gcc=99)"
if [ "$vfail" = "0" ] && [ "$ir" = "99" ] && [ "$gr" = "99" ]; then say "PASS -- fn-ptr INC-1: indirect call + fn-name-value, index-agreement sound"; exit 0; fi
say "FAIL"; exit 1
