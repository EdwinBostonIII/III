#!/usr/bin/env bash
# build_crypto_test.sh -- build (and run) the crypto-agility conformance test.
#
# FORWARD_REFERENCES #3.  Produces CRYPTO-AGILITY/build/iii_crypto_test.exe
# (the subsystem-test-gate convention) and runs it; exits with the test's
# exit code (0 = all suites pass).
#
# The AEAD / Ed25519 / X25519 / ML-KEM / ML-DSA / SLH-DSA / SHA layers are the
# self-contained C in src/.  ECDSA-P256/P384 and RSA-3072/4096 dispatch (in
# crypto.c) bridge -- single-source, no second C copy -- to the proven .iii
# implementations (numera/ecdsa_p256.iii, ecdsa_p384.iii, rsa.iii over
# ec256/fn256/fp256, ec384/fn384, bigint/arena/drbg) compiled into
# libiii_native.a.  The canonical SHA-256 header lives in LEXICON/include.
#
# Prereq: STDLIB/scripts/build_stdlib.sh has produced libiii_native.a with the
# in-tree iiis-2 compiler (its own pin discipline).
set -u
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
OUT="$SCRIPT_DIR/build"
EXE="$OUT/iii_crypto_test.exe"
mkdir -p "$OUT"

if [[ ! -f "$LIB" ]]; then
    echo "[build_crypto_test] FATAL: $LIB missing -- run STDLIB/scripts/build_stdlib.sh first" >&2
    exit 2
fi

gcc -O2 -Wall -Wextra \
    -I "$SCRIPT_DIR/include" -I "$ROOT/LEXICON/include" \
    "$SCRIPT_DIR"/src/*.c "$SCRIPT_DIR"/tests/test_crypto.c \
    "$LIB" -lmsvcrt -o "$EXE" \
    || { echo "[build_crypto_test] FATAL: compile/link failed" >&2; exit 1; }

echo "[build_crypto_test] built $EXE"
"$EXE"
