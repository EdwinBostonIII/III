#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_exact.sh
#
# Build iii-exact: EXACT SIGN OF A SUM OF SQUARE ROOTS AS A STANDING TOOL.
#
#   iii-exact "<a1> <b1> <a2> <b2> ...">     decide sign(a1*sqrt(b1) + a2*sqrt(b2) + ...) EXACTLY
#   iii-exact --cmp "<terms A>" "<terms B>"  decide whether (sum A) <, =, or > (sum B), EXACTLY
#   exit: 1 = NEGATIVE | 0 = EXACTLY ZERO | 2 = POSITIVE | 3 = usage/parse error
#
# Floating point gets sign(sum a_i sqrt(b_i)) wrong near a tie, and every geometry predicate built on
# it inherits the error.  This is the separation-bound engine (aether/sqrt_sum_sign over the bigint
# arena) pointed at YOUR terms.  A LEAF tool build (the build_iii_eval mold): the pinned in-tree
# compiler + the committed archive; the bootstrap chain and its seals are never touched.
#
# Usage: bash build_iii_exact.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-exact build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-exact${BIN_SUFFIX}"
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

SRC="$III_ROOT/STDLIB/iii/aether/exact_cli.iii"
[[ -f "$SRC" ]] || die 3 "missing source: $SRC"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-exact-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

# exact_cli composes aether/sqrt_sum_sign (+ its kfield sibling), which are separate TUs, not archived.
OBJS=()
for tu in kfield sqrt_sum_sign; do
    o="$TMP_ROOT/${tu}.iii.o"
    log "iiis-2 ${tu}.iii -> ${tu}.iii.o"
    "$IIIS" "$III_ROOT/STDLIB/iii/aether/${tu}.iii" --compile-only --out "$o" || die 3 "iii compile failed: ${tu}.iii"
    OBJS+=("$o")
done
OBJ="$TMP_ROOT/exact_cli.iii.o"
log "iiis-2 exact_cli.iii -> exact_cli.iii.o"
"$IIIS" "$SRC" --compile-only --out "$OBJ" || die 3 "iii compile failed: $SRC"
OBJS+=("$OBJ")

# OneDrive/Defender transient-lock hardening: fresh inode + retry.
log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "${OBJS[@]}" "$STDLIB_LIB" -lws2_32 -lkernel32; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
