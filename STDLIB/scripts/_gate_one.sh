#!/bin/bash
# standalone single-corpus-test gate (mirrors run_corpus.sh recipe) for quick C-series gating.
set -u
REPO="/c/Users/Edwin Boston/OneDrive/Desktop/III"
IIIS="$REPO/COMPILED/iiis-2.exe"
LIB="$REPO/STDLIB/build/iii/libiii_native.a"
BD="$REPO/STDLIB/build/iii"
SE=()
for o in resolver_unit.o resolver_unit_avx512.o bench_helpers.o; do
  [[ -f "$BD/$o" ]] && SE+=("$BD/$o")
done
for T in "$@"; do
  SRC="$REPO/STDLIB/corpus/${T}.iii"
  OBJ="/tmp/${T}.o"; EXE="/tmp/${T}.exe"
  if [[ ! -f "$SRC" ]]; then echo "MISSING_SRC ${T}"; continue; fi
  if ! "$IIIS" "$SRC" --compile-only --out "$OBJ" >/tmp/${T}.cc 2>&1; then
    echo "COMPILE_FAIL ${T}"; tail -4 /tmp/${T}.cc; continue
  fi
  rc=1
  for a in 1 2 3; do
    rm -f "$EXE"
    gcc "$OBJ" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" \
      -lws2_32 -lkernel32 -o "$EXE" >/tmp/${T}.link 2>&1
    rc=$?; [[ $rc -eq 0 && -f "$EXE" ]] && break; sleep 1
  done
  if [[ $rc -ne 0 ]]; then echo "LINK_FAIL ${T}"; tail -4 /tmp/${T}.link; continue; fi
  RUN="/tmp/run_${T}_$$.exe"; cp "$EXE" "$RUN"; "$RUN"; echo "EXIT_${T}=$?"
done
