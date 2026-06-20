#!/usr/bin/env bash
# Verify egraph.iii consumers + the new falsifier against the REBUILT (guarded) lib.
# All expect 99.
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
IIIS="$ROOT/COMPILED/iiis-2.exe"
BD="$ROOT/STDLIB/build/iii"
LIB="$BD/libiii_native.a"
W="$ROOT/STDLIB/_negproof"
mkdir -p "$W"
SE=()
for n in omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o bench_helpers.o; do
  [ -f "$BD/$n" ] && SE+=("$BD/$n")
done

TESTS=(1507_egraph_flip_node_oob 614_egraph 906_eg_integrity 977_egraph_rule_wrap_guard 956_egraph_cost_lattice 1107_egraph_saturate_capacity_gap 1334_eg_kernel_merge 1335_bvd_rule_gate 1435_gate_outcomes_seal_quorum 1462_numera_slot_witness_gaps 1468_boundary_arena_caps 1479_egraph_incremental_rebuild 1481_egraph_dijkstra_extract 840_forcefield_optinvoke_egraph 915_sov_self_improve 1370_discovery_pipeline 1371_autonomous_cycle 1373_federated_adoption)
ALLOK=1
for t in "${TESTS[@]}"; do
  S="$ROOT/STDLIB/corpus/$t.iii"; O="$W/$t.o"; E="$W/$t.exe"
  "$IIIS" "$S" --compile-only --out "$O" >/dev/null 2>&1 || { echo "FAIL  $t : compile"; ALLOK=0; continue; }
  rm -f "$E"; ok=0
  for a in 1 2 3; do
    gcc "$O" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$E" >/dev/null 2>&1
    [ $? -eq 0 ] && [ -f "$E" ] && { ok=1; break; }; sleep 1
  done
  [ $ok -eq 0 ] && { echo "FAIL  $t : link"; ALLOK=0; continue; }
  "$E"; rc=$?
  if [ $rc -eq 99 ]; then echo "PASS  $t : 99"; else echo "FAIL  $t : exit $rc"; ALLOK=0; fi
done
echo "----"
[ $ALLOK -eq 1 ] && echo "ALL EGRAPH CONSUMERS GREEN" || echo "*** REGRESSION ***"
