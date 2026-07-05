#!/usr/bin/env bash
# run_fnptr_gate.sh -- durable regression guard for the fn-pointer feature: INC-1 + INC-2 + INC-3.
#
# INC-3 lands CALL_INDIRECT on the SOVEREIGN backends, so the standard here is now ALL-5 per C KAT:
#   svir_verify (structural) + svir_interp (independent reference executor) + sovereign x86
#   (svir_x86 -> sovas -> sovlink+crt0_sov PE, no gcc in the artifact path) + wasm (svir_wasm ->
#   node host) + gcc (reference C semantics) -- exit 99 on every executor.  Each KAT bakes in
#   add/sub INDEX-SPACE-AGREEMENT teeth (a swapped dispatch -> wrong answer -> not 99), which now
#   run on the sovereign backends too.
#   test_fnptr.c  : INC-1 -- indirect call of a fn-ptr local/param + fn-name-as-value.
#   test_fnptr2.c : INC-2 -- field-indirect STATEMENT call obj->field(args); / obj.field(args); (the
#                   seed's G_EMIT.audit_fn(...); / st->witness_sink(...); shape) + fn-ptr-typedef
#                   field 8B sizing + the INC-3 composition tooth: putchar forces the wasm env.putc
#                   IMPORT (IC=1), shifting every wasm func index -- table/elem/type must follow.
#
# OOB TRAP teeth (the "hard Layer-3 gate" svir_interp.iii:123 names): _svir_ci_oob.iii is a hand-laid
# module whose fn0 runs CONST 5 ; CALL_INDIRECT 0 with nfunc=2.  Its body completes cleanly at 99 if
# the executor does NOT trap, so silent dispatch reads 99 -> RED.  Pinned trap codes:
#   interp = 199 (OOB_IND sentinel) ; x86 = 199 (__svci fall-through -> ExitProcess(199)) ;
#   wasm = 1 (native table-bounds RuntimeError, node uncaught).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"
BOOT="$ROOT/STDLIB/build/_sovboot"
mkdir -p "$W"; say(){ echo "[fnptr-gate] $*"; }
"$IIIS" "$S/ccsv.iii"         --compile-only --out "$W/ccsv.o"         >/dev/null 2>&1 && gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null || { say "FAIL build ccsv"; exit 1; }
"$IIIS" "$S/svir_verify.iii"  --compile-only --out "$W/svir_verify.o"  >/dev/null 2>&1 || { say "FAIL svir_verify"; exit 1; }
"$IIIS" "$S/verify_each.iii"  --compile-only --out "$W/verify_each.o"  >/dev/null 2>&1 || { say "FAIL verify_each"; exit 1; }
"$IIIS" "$S/svir_interp.iii"  --compile-only --out "$W/svir_interp.o"  >/dev/null 2>&1 || { say "FAIL svir_interp"; exit 1; }
"$IIIS" "$S/svir_x86.iii"     --compile-only --out "$W/svir_x86.o"     >/dev/null 2>&1 || { say "FAIL svir_x86"; exit 1; }
"$IIIS" "$S/svir_wasm.iii"    --compile-only --out "$W/svir_wasm.o"    >/dev/null 2>&1 || { say "FAIL svir_wasm"; exit 1; }

# run one SVIR object through the four SVIR-side executors; echoes "vf ir xr wr"
# Every produced artifact is rm -f'd FIRST: a failed producer must yield a MISSING artifact (rc 127/nonzero),
# never a stale one masquerading as green (the stale-_rf_k.exe lesson: a gcc compile failure read 99).
run_svir_arms(){ # $1 = the compiled SVIR-carrier .o ; $2 = a tag for scratch names
  rm -f "$W/_ve_$2.exe" "$W/_in_$2.exe" "$W/_tx_$2.exe" "$W/_$2.s" "$W/_$2.o2" "$W/_$2.x86.exe" "$W/_tw_$2.exe" "$W/_$2.wasm"
  gcc "$W/verify_each.o" "$W/svir_verify.o" "$1" -o "$W/_ve_$2.exe" 2>/dev/null
  local vf; vf=$("$W/_ve_$2.exe" 2>/dev/null | grep '^#' | awk '{print $3}')
  gcc "$W/svir_interp.o" "$1" -o "$W/_in_$2.exe" 2>/dev/null; "$W/_in_$2.exe" >/dev/null 2>&1; local ir=$?
  gcc "$W/svir_x86.o" "$1" -o "$W/_tx_$2.exe" 2>/dev/null; "$W/_tx_$2.exe" > "$W/_$2.s" 2>/dev/null
  timeout 20 "$BOOT/sovas_main.exe" "$W/_$2.s" > "$W/_$2.o2" 2>/dev/null
  timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/_$2.o2" > "$W/_$2.x86.exe" 2>/dev/null
  chmod +x "$W/_$2.x86.exe" 2>/dev/null; "$W/_$2.x86.exe" >/dev/null 2>&1; local xr=$?
  gcc "$W/svir_wasm.o" "$1" -o "$W/_tw_$2.exe" 2>/dev/null; "$W/_tw_$2.exe" > "$W/_$2.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/_$2.wasm" >/dev/null 2>&1; local wr=$?
  echo "$vf $ir $xr $wr"
}

rc=0
for kat in test_fnptr.c test_fnptr2.c; do
  "$W/ccsv.exe" "$S/$kat" > "$W/g_k.iii" 2>/dev/null
  "$IIIS" "$W/g_k.iii" --compile-only --out "$W/gen_svir.o" >/dev/null 2>&1 || { say "FAIL iiis compile of ccsv($kat)"; rc=1; continue; }
  read -r vf ir xr wr <<< "$(run_svir_arms "$W/gen_svir.o" "k")"
  rm -f "$W/_rf_k.exe"; gcc "$S/$kat" -o "$W/_rf_k.exe" 2>/dev/null; "$W/_rf_k.exe" >/dev/null 2>&1; gr=$?
  if [ "$vf" = "0" ] && [ "$ir" = "99" ] && [ "$xr" = "99" ] && [ "$wr" = "99" ] && [ "$gr" = "99" ]; then
    say "PASS $kat (svir_verify=0 svir_interp=99 x86=99 wasm=99 gcc=99)"
  else
    say "FAIL $kat (vf=$vf interp=$ir x86=$xr wasm=$wr gcc=$gr)"; rc=1
  fi
done

# ---- OOB TRAP teeth ----
"$IIIS" "$S/_svir_ci_oob.iii" --compile-only --out "$W/_ci_oob.o" >/dev/null 2>&1 || { say "FAIL compile _svir_ci_oob"; exit 1; }
read -r ovf oir oxr owr <<< "$(run_svir_arms "$W/_ci_oob.o" "oob")"
if [ "$oir" = "199" ] && [ "$oxr" = "199" ] && [ "$owr" = "1" ]; then
  say "PASS oob-trap (interp=199 x86=199 wasm=1(native trap) -- no executor silently dispatches an OOB index)"
else
  say "FAIL oob-trap (interp=$oir x86=$oxr wasm=$owr ; expect 199/199/1)"; rc=1
fi

[ "$rc" = "0" ] && say "ALL PASS -- fn-ptr INC-1 (indirect call + fn-name-value) + INC-2 (field-indirect statement call + 8B field) + INC-3 (sovereign x86 __svci computed call + wasm call_indirect funcref table, OOB trapping), index-agreement sound on every executor"
exit $rc
