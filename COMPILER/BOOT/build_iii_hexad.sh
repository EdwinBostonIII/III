#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_hexad.sh
#
# Build iii-hexad: THE ASYMMETRIC TERNARY SAFETY GROUND, made runnable.
#
#     iii-hexad <P1..P6>                is a hexad admitted, or bricking-by-construction?
#     iii-hexad --count                 the 144-manifold size
#     iii-hexad --compose <6> <6>       compose two hexads (AND on P1..4, OR on P5..6)
#
# Composes omnia/hexad_reach + hexad_algebra (the standing safety algebra).  A LEAF tool build
# (build_iii_eval discipline): pinned in-tree iiis-2 + committed archive; bootstrap chain untouched.
#
# Usage: bash build_iii_hexad.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-hexad build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"
SRC="$III_ROOT/STDLIB/iii/omnia/hexad_cli.iii"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-hexad${BIN_SUFFIX}"
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
[[ -f "$SRC" ]] || die 3 "missing source: $SRC"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-hexad-build.XXXXXX")"
trap '[[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true' EXIT
OBJ="$TMP_ROOT/hexad_cli.iii.o"

log "iiis-2 hexad_cli.iii -> hexad_cli.iii.o"
"$IIIS" "$SRC" --compile-only --out "$OBJ" || die 3 "iii compile failed: $SRC"

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
