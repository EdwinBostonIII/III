#!/usr/bin/env bash
# run_fnptr_gate.sh -- durable regression guard for the fn-pointer feature (ccsv codegen), INC-1 + INC-2.
#
# WHY a separate gate (not run_ccsv's cfeat): cfeat requires all-4 (svir_verify + sovereign-x86 + wasm + gcc).
# These KATs use CALL_INDIRECT, whose *codegen* lands in INC-1/INC-2; the x86/wasm computed-call is INC-3.
# So the honest standard here is the THREE oracles valid now: svir_verify (structural), svir_interp (the
# independent reference executor = runtime oracle), and gcc (reference semantics). Each KAT bakes in
# add/sub INDEX-SPACE-AGREEMENT teeth (a swapped dispatch -> wrong answer -> not 99).
#   test_fnptr.c  : INC-1 -- indirect call of a fn-ptr local/param + fn-name-as-value.
#   test_fnptr2.c : INC-2 -- field-indirect STATEMENT call obj->field(args); / obj.field(args); (the seed's
#                   G_EMIT.audit_fn(...); / st->witness_sink(...); shape) + fn-ptr-typedef field 8B sizing.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"
mkdir -p "$W"; say(){ echo "[fnptr-gate] $*"; }
"$IIIS" "$S/ccsv.iii"         --compile-only --out "$W/ccsv.o"         >/dev/null 2>&1 && gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null || { say "FAIL build ccsv"; exit 1; }
"$IIIS" "$S/svir_verify.iii"  --compile-only --out "$W/svir_verify.o"  >/dev/null 2>&1 || { say "FAIL svir_verify"; exit 1; }
"$IIIS" "$S/verify_each.iii"  --compile-only --out "$W/verify_each.o"  >/dev/null 2>&1 || { say "FAIL verify_each"; exit 1; }
"$IIIS" "$S/svir_interp.iii"  --compile-only --out "$W/svir_interp.o"  >/dev/null 2>&1 || { say "FAIL svir_interp"; exit 1; }

rc=0
for kat in test_fnptr.c test_fnptr2.c; do
  "$W/ccsv.exe" "$S/$kat" > "$W/g_k.iii" 2>/dev/null
  "$IIIS" "$W/g_k.iii" --compile-only --out "$W/gen_svir.o" >/dev/null 2>&1 || { say "FAIL iiis compile of ccsv($kat)"; rc=1; continue; }
  gcc "$W/verify_each.o" "$W/svir_verify.o" "$W/gen_svir.o" -o "$W/_ve_k.exe" 2>/dev/null
  vf=$("$W/_ve_k.exe" 2>/dev/null | grep '^#' | awk '{print $3}')
  gcc "$W/svir_interp.o" "$W/gen_svir.o" -o "$W/_in_k.exe" 2>/dev/null; "$W/_in_k.exe" >/dev/null 2>&1; ir=$?
  gcc "$S/$kat" -o "$W/_rf_k.exe" 2>/dev/null; "$W/_rf_k.exe" >/dev/null 2>&1; gr=$?
  if [ "$vf" = "0" ] && [ "$ir" = "99" ] && [ "$gr" = "99" ]; then say "PASS $kat (svir_verify=0 svir_interp=99 gcc=99)"; else say "FAIL $kat (vf=$vf interp=$ir gcc=$gr)"; rc=1; fi
done
[ "$rc" = "0" ] && say "ALL PASS -- fn-ptr INC-1 (indirect call + fn-name-value) + INC-2 (field-indirect statement call + 8B field), index-agreement sound"
exit $rc
