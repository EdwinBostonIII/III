#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_typecheck.sh
#
# Build iii-typecheck: THE DEPENDENT-TYPE KERNEL AS A STANDING TOOL.
#
#   iii-typecheck <term-file>                      infer the term's type, or refuse
#   iii-typecheck --check <term-file> <type-file>  check term : type
#   exit: 0 well-typed/checked | 4 kernel REFUSED | 3 parse | 2 file | 1 usage
#
# The kernel (numera/typecheck: lambda-Pi + predicative universes, Sigma/Bool/Id/Nat/Unit/Empty/
# Sum/W, CCL conversion oracle) comes UNCHANGED from the committed archive; the CLI is an untrusted
# S-expression front end over the kernel's own constructors and serializer.  A LEAF tool build
# (the build_iii_eval mold): the pinned in-tree compiler + the committed archive; the bootstrap
# chain and its seals are never touched.
#
# Usage: bash build_iii_typecheck.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-typecheck build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-typecheck${BIN_SUFFIX}"
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

SRC="$III_ROOT/STDLIB/iii/aether/typecheck_cli.iii"
[[ -f "$SRC" ]] || die 3 "missing source: $SRC"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-typecheck-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OBJ="$TMP_ROOT/typecheck_cli.iii.o"
log "iiis-2 typecheck_cli.iii -> typecheck_cli.iii.o"
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
