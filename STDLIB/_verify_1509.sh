#!/usr/bin/env bash
# Verify bv_bits/omega_engine/sep_logic/csl consumers (direct + heaviest transitive via
# bv_dispose/cg_autocatalyst) + the new falsifier against the REBUILT lib.  All expect 99.
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

TESTS=(1509_accessor_bounds_bvbits_omega_seplogic_csl 1345_bv_bits 1233_sep_logic 1237_csl 1254_omega_engine 1358_shift_laws 1216_bv_dispose 1122_cg_autocatalyst 1335_bvd_rule_gate 1366_mixed_dispose 1413_transform_taint_seal 1444_gate_outcomes_bv_dispose)
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
[ $ALLOK -eq 1 ] && echo "ALL WAVE-19 CONSUMERS GREEN" || echo "*** REGRESSION ***"
