#!/usr/bin/env bash
# run_ripple_kats.sh -- gate for THE RIPPLE MERGE (the unified {BELOW,REFLECT} change-substrate; §9 "one primitive").
# Phase I  : omnia/involution  -- the canonical semantic-free engine (content-addr + provable involution + disposer-gate).
# Phase II : eidos/membrane    -- the orbiting Ω satellite (map[H]->Ω) + the LAZY membrane (vacuous free / crystal
#                                  verified via the EXISTING forge-resistant omnia::crystal_verify) + the
#                                  INVOLUTION-CLOSED proof (the undo is as proven as the action).
# (later)  : eidos/epoch (deterministic multi-writer fold), the disposer functors, the great subsumption.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"; O="$III/STDLIB/iii/omnia"; E="$III/STDLIB/iii/eidos"; A="$III/STDLIB/iii/aether"; LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"; pass=0; fail=0

"$I2" "$O/involution.iii" --compile-only --out "$OUT/involution.o" 2>"$OUT/i.log" || { echo "FAIL involution compile"; cat "$OUT/i.log"; exit 1; }
"$I2" "$E/membrane.iii"   --compile-only --out "$OUT/membrane.o"   2>"$OUT/m.log" || { echo "FAIL membrane compile";   cat "$OUT/m.log"; exit 1; }
"$I2" "$E/epoch.iii"      --compile-only --out "$OUT/epoch.o"      2>"$OUT/e.log" || { echo "FAIL epoch compile";      cat "$OUT/e.log"; exit 1; }
"$I2" "$E/disposer.iii"   --compile-only --out "$OUT/disposer.o"   2>"$OUT/d.log" || { echo "FAIL disposer compile";   cat "$OUT/d.log"; exit 1; }
"$I2" "$E/reactor.iii"    --compile-only --out "$OUT/reactor.o"    2>"$OUT/r.log" || { echo "FAIL reactor compile";    cat "$OUT/r.log"; exit 1; }
"$I2" "$E/eidolon.iii"    --compile-only --out "$OUT/eidolon.o"    2>"$OUT/eid.log" || { echo "FAIL eidolon compile";    cat "$OUT/eid.log"; exit 1; }
"$I2" "$A/sqrt_sum_sign.iii"  --compile-only --out "$OUT/sqrt_sum_sign.o"  2>"$OUT/ss.log"  || { echo "FAIL sqrt_sum_sign compile"; cat "$OUT/ss.log"; exit 1; }
"$I2" "$A/kfield.iii"  --compile-only --out "$OUT/kfield.o"  2>"$OUT/kfw.log" || { echo "FAIL kfield compile"; cat "$OUT/kfw.log"; exit 1; }
"$I2" "$A/ui_exact_big.iii"   --compile-only --out "$OUT/ui_exact_big.o"   2>"$OUT/ueb.log" || { echo "FAIL ui_exact_big compile"; cat "$OUT/ueb.log"; exit 1; }
"$I2" "$E/ripple_eidolon.iii" --compile-only --out "$OUT/ripple_eidolon.o" 2>"$OUT/re.log"  || { echo "FAIL ripple_eidolon compile"; cat "$OUT/re.log"; exit 1; }
"$I2" "$E/eid_plan.iii"       --compile-only --out "$OUT/eid_plan.o"       2>"$OUT/ep.log"  || { echo "FAIL eid_plan compile"; cat "$OUT/ep.log"; exit 1; }

run() {
  local name="$1" want="$2"; shift 2
  "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
  rm -f "$OUT/$name.exe"
  gcc "$OUT/$name.o" "$@" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
  local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"; timeout 120 "$st"; local rc=$?; rm -f "$st"
  if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2126_involution        99 "$OUT/involution.o" "$LIB"
run 2127_membrane          99 "$OUT/membrane.o" "$OUT/involution.o" "$LIB"
run 2128_involution_closed 99 "$OUT/membrane.o" "$OUT/involution.o" "$LIB"
run 2129_epoch             99 "$OUT/epoch.o" "$OUT/involution.o" "$LIB"
run 2130_disposers         99 "$OUT/disposer.o" "$OUT/involution.o" "$LIB"
run 2131_reactor           99 "$OUT/reactor.o" "$OUT/epoch.o" "$OUT/membrane.o" "$OUT/involution.o" "$LIB"   # the resident reactor loop (sound Dynamic Reactor)
run 2132_eidolon           99 "$OUT/eidolon.o" "$LIB"   # the self-identical primitive: exact where arithmetic is lossy
run 2133_ripple_eidolon    99 "$OUT/ripple_eidolon.o" "$OUT/eidolon.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$OUT/involution.o" "$LIB"   # eidolon wired INTO the ripple: exact-order edges
run 2134_planner           99 "$OUT/eid_plan.o" "$OUT/ripple_eidolon.o" "$OUT/eidolon.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$OUT/involution.o" "$LIB"   # exact-algebraic ripple-graph planner

echo "=== RIPPLE-MERGE KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
