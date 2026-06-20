#!/usr/bin/env bash
# Teeth-first proof for 1506_huffman_decode_len_oob against the CURRENT lib (which still
# has the OLD, unguarded huffman).  Expect non-99 (arm 4 -> 5: old returns 0 not HF_E_LEN).
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
IIIS="$ROOT/COMPILED/iiis-2.exe"
BUILD_DIR="$ROOT/STDLIB/build/iii"
LIB="$BUILD_DIR/libiii_native.a"
SRC="$ROOT/STDLIB/corpus/1506_huffman_decode_len_oob.iii"
WORK="$ROOT/STDLIB/_negproof"
mkdir -p "$WORK"
OBJ="$WORK/1506.o"; EXE="$WORK/1506_old.exe"

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

echo "[negproof] compiling 1506..."
"$IIIS" "$SRC" --compile-only --out "$OBJ" || { echo "COMPILE FAIL"; exit 3; }
echo "[negproof] linking against CURRENT (old-huffman) lib..."
rm -f "$EXE"
gcc "$OBJ" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$EXE" || { echo "LINK FAIL"; exit 4; }
"$EXE"; rc=$?
echo "[negproof] 1506 vs OLD huffman exit = $rc  (expect non-99; teeth=5)"
[[ $rc -eq 99 ]] && { echo "*** NO TEETH ***"; exit 1; }
echo "[negproof] TEETH CONFIRMED (old huffman reddens)"
