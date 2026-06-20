#!/usr/bin/env bash
# Standalone RED/GREEN probe for a corpus KAT against the CURRENT libiii_native.a.
# Usage: bash _probe_w6.sh <corpus_basename_without_ext>
set -u
ROOT="C:/Users/Edwin Boston/OneDrive/Desktop/III"
IIIS="$ROOT/COMPILED/iiis-2.exe"
BUILD="$ROOT/STDLIB/build/iii"
NAME="$1"
SRC="$ROOT/STDLIB/corpus/${NAME}.iii"
OBJ="$ROOT/STDLIB/build/_probe_w6.iii.o"
EXE="$ROOT/STDLIB/build/_probe_w6.exe"
LIB="$BUILD/libiii_native.a"

# Side-effect set: registration TUs that must be whole-archived for live paths.
SE_NAMES=(omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o
  omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o omnia_resolver_memo.iii.o
  omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o
  omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o aether_pattern_set_federation.iii.o
  sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o
  verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o bench_helpers.o)
SE=()
for n in "${SE_NAMES[@]}"; do [[ -f "$BUILD/$n" ]] && SE+=("$BUILD/$n"); done

rm -f "$OBJ" "$EXE"
"$IIIS" "$SRC" --compile-only --out "$OBJ"
echo "compile_rc=$?"
[[ -f "$OBJ" ]] || { echo "NO OBJ"; exit 91; }
gcc "$OBJ" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$EXE" 2>&1 | tail -5
echo "link_rc=${PIPESTATUS[0]}"
[[ -f "$EXE" ]] || { echo "NO EXE"; exit 92; }
STAGED="/tmp/probe_w6_$$.exe"
cp "$EXE" "$STAGED"
"$STAGED"; rc=$?
rm -f "$STAGED"
echo "PROBE_EXIT=$rc"
