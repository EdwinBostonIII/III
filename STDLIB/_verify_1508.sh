#!/usr/bin/env bash
# Verify heaplet/liveness/matrix_ring consumers (direct + transitive via csl/reg_alloc/
# sep_logic) + the new combined falsifier against the REBUILT (guarded) lib.  All expect 99.
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

TESTS=(1508_accessor_bounds_heaplet_liveness_matrix 1232_heaplet 1261_matrix_ring 1285_liveness 1465_dark_surface_gaps 1233_sep_logic 1237_csl 1274_reg_alloc 1322_reg_alloc_liveness 1413_transform_taint_seal 1502_analysis_accessor_bounds)
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
[ $ALLOK -eq 1 ] && echo "ALL WAVE-18 CONSUMERS GREEN" || echo "*** REGRESSION ***"
