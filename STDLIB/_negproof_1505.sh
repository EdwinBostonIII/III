#!/usr/bin/env bash
# Teeth-first proof for 1505_resolver_memo_fifo against the CURRENT (pre-rebuild,
# buggy) lib.  Expect non-99 (arm 6 -> 11).
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
IIIS="$ROOT/COMPILED/iiis-2.exe"
BUILD_DIR="$ROOT/STDLIB/build/iii"
LIB="$BUILD_DIR/libiii_native.a"
SRC="$ROOT/STDLIB/corpus/1505_resolver_memo_fifo.iii"
WORK="$ROOT/STDLIB/_negproof"
mkdir -p "$WORK"
OBJ="$WORK/1505.o"
EXE="$WORK/1505_old.exe"

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

echo "[negproof] compiling 1505..."
"$IIIS" "$SRC" --compile-only --out "$OBJ"
if [[ $? -ne 0 ]]; then echo "[negproof] COMPILE FAIL"; exit 3; fi

echo "[negproof] linking against CURRENT (buggy) lib..."
rm -f "$EXE"
gcc "$OBJ" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" \
  -lws2_32 -lkernel32 -o "$EXE"
if [[ $? -ne 0 ]]; then echo "[negproof] LINK FAIL"; exit 4; fi

"$EXE"
rc=$?
echo "[negproof] 1505 vs OLD lib exit = $rc  (expect non-99; teeth=11)"
if [[ $rc -eq 99 ]]; then echo "[negproof] *** NO TEETH: 1505 passed the buggy lib ***"; exit 1; fi
echo "[negproof] TEETH CONFIRMED (old lib reddens)"
