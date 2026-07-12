#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_crypto.sh
#
# Build iii-crypto: THE POST-QUANTUM STACK AS A STANDING TOOL.
#
#   iii-crypto keygen <level> <seed> <pk> <sk>       ML-DSA (FIPS 204) keypair, deterministic in the seed
#   iii-crypto sign   <level> <sk> <file> <sig>      sign ANY file
#   iii-crypto verify <level> <pk> <file> <sig>      exit 0 = VALID, 4 = INVALID
#   iii-crypto seal   <key> <nonce> <file> <out>     ChaCha20-Poly1305 AEAD
#   iii-crypto open   <key> <nonce> <sealed> <out>   exit 0 = AUTHENTIC, 4 = FORGED
#   iii-crypto hash   <file>                         SHA-256
#
# III's crypto is FIPS/ACVP-conformant and KAT-gated -- but a PQC stack you cannot point at a file is a
# conformance exhibit, not a capability.  This is the surface.  A LEAF tool build (the build_iii_eval mold):
# the pinned in-tree compiler + the committed archive; the bootstrap chain and its seals are never touched.
#
# Usage: bash build_iii_crypto.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-crypto build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-crypto${BIN_SUFFIX}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out) OUT_BIN="$2"; shift 2 ;;
        *)     die 2 "unknown arg: $1" ;;
    esac
done

IIIS="$OUT_DIR/iiis-2${BIN_SUFFIX}"
[[ -x "$IIIS" ]] || die 2 "pinned compiler not found: $IIIS"
CC="${CC:-gcc}"
command -v "$CC" >/dev/null 2>&1 || die 2 "linker not found: $CC"
STDLIB_LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -f "$STDLIB_LIB" ]] || die 2 "stdlib archive not found: $STDLIB_LIB"

SRC="$III_ROOT/STDLIB/iii/aether/crypto_cli.iii"
[[ -f "$SRC" ]] || die 3 "missing source: $SRC"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-crypto-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OBJ="$TMP_ROOT/crypto_cli.iii.o"
log "iiis-2 crypto_cli.iii -> crypto_cli.iii.o"
"$IIIS" "$SRC" --compile-only --out "$OBJ" || die 3 "iii compile failed: $SRC"

# OneDrive/Defender transient-lock hardening: fresh inode + retry.
log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "$OBJ" "$STDLIB_LIB" -lws2_32 -lkernel32; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
