#!/usr/bin/env bash
# Verify the resolver_memo.iii consumers (+ the new falsifier) against the REBUILT
# (fixed) lib.  All five must exit 99.
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
IIIS="$ROOT/COMPILED/iiis-2.exe"
BUILD_DIR="$ROOT/STDLIB/build/iii"
LIB="$BUILD_DIR/libiii_native.a"
WORK="$ROOT/STDLIB/_negproof"
mkdir -p "$WORK"

SE_NAMES=(omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o
  omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o
  omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o
  omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o
  omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o
  aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o
  sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o
  verba_nl_lex.iii.o resolver_hot.o resolver_unit.o
  resolver_unit_avx512.o bench_helpers.o)
SE=()
for n in "${SE_NAMES[@]}"; do [[ -f "$BUILD_DIR/$n" ]] && SE+=("$BUILD_DIR/$n"); done

TESTS=(1505_resolver_memo_fifo 202_memo_determinism 230_memo_content_addressing 242_bench_resolver 943_resolver_memo_guards)
ALLOK=1
for t in "${TESTS[@]}"; do
  SRC="$ROOT/STDLIB/corpus/$t.iii"
  OBJ="$WORK/$t.o"; EXE="$WORK/$t.exe"
  "$IIIS" "$SRC" --compile-only --out "$OBJ" >/dev/null 2>&1 || { echo "FAIL  $t : compile"; ALLOK=0; continue; }
  rm -f "$EXE"
  ok=0
  for a in 1 2 3; do
    gcc "$OBJ" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$EXE" >/dev/null 2>&1
    [[ $? -eq 0 && -f "$EXE" ]] && { ok=1; break; }
    sleep 1
  done
  [[ $ok -eq 0 ]] && { echo "FAIL  $t : link"; ALLOK=0; continue; }
  "$EXE"; rc=$?
  if [[ $rc -eq 99 ]]; then echo "PASS  $t : 99"; else echo "FAIL  $t : exit $rc"; ALLOK=0; fi
done
echo "----"
[[ $ALLOK -eq 1 ]] && echo "ALL RESOLVER_MEMO CONSUMERS GREEN" || echo "*** REGRESSION ***"
