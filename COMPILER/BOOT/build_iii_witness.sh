#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_witness.sh
#
# Build iii-witness: THE STRANGER'S TESTAMENT VERIFIER as a standing tool.
#
#   iii-witness verify <testament.dat> [pkpin|none] [parent|none] [root|none] [manifest|none]
#
# TIER-1 (minutes, no toolchain): format + SLH-DSA signature + key pin + generation chain +
# monotone law.  FULL: also re-derives every digest, the FORGE chain, and the RADICAL cert
# against the committed tree.  A LEAF tool build (the build_iii_crypto mold).
#
# Usage: bash build_iii_witness.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-witness build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-witness${BIN_SUFFIX}"
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

ORGAN="$III_ROOT/STDLIB/iii/aether/testament.iii"
SRC="$III_ROOT/STDLIB/iii/aether/witness_cli.iii"
[[ -f "$ORGAN" ]] || die 3 "missing organ: $ORGAN"
[[ -f "$SRC"   ]] || die 3 "missing source: $SRC"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-witness-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OORG="$TMP_ROOT/testament.iii.o"
OCLI="$TMP_ROOT/witness_cli.iii.o"
log "iiis-2 testament.iii -> testament.iii.o"
"$IIIS" "$ORGAN" --compile-only --out "$OORG" || die 3 "iii compile failed: $ORGAN"
log "iiis-2 witness_cli.iii -> witness_cli.iii.o"
"$IIIS" "$SRC" --compile-only --out "$OCLI" || die 3 "iii compile failed: $SRC"

log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "$OCLI" "$OORG" "$STDLIB_LIB" -lws2_32 -lkernel32; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
