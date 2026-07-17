#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_closure.sh
#
# Build iii-closure: THE CLOSURE-PIN VERIFIER as a standing tool (ENTELECHEIA Ε3).
#
#   iii-closure root   <src1> <src2> ...
#   iii-closure verify <sealed-64hex> <src1> ...
#
# Derives a claim's closure root from the LIVE bytes of its ordered source set
# (sanctus/closure_graph) and checks it against a sealed pin (sanctus/closure's
# claim table).  A LEAF tool build (the build_iii_pulse mold): compile the two
# organs + the CLI with the pinned iiis-2, link them BEFORE the stdlib archive so
# the freshly-compiled closure.iii (with the claim table) overrides the archive's
# older copy.
#
# Usage: bash build_iii_closure.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-closure build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-closure${BIN_SUFFIX}"
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

GRAPH="$III_ROOT/STDLIB/iii/sanctus/closure_graph.iii"
CLOSURE="$III_ROOT/STDLIB/iii/sanctus/closure.iii"
SRC="$III_ROOT/STDLIB/iii/aether/closure_cli.iii"
[[ -f "$GRAPH"   ]] || die 3 "missing organ: $GRAPH"
[[ -f "$CLOSURE" ]] || die 3 "missing organ: $CLOSURE"
[[ -f "$SRC"     ]] || die 3 "missing source: $SRC"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-closure-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OGRAPH="$TMP_ROOT/closure_graph.iii.o"
OCLOSURE="$TMP_ROOT/closure.iii.o"
OCLI="$TMP_ROOT/closure_cli.iii.o"
log "iiis-2 closure_graph.iii -> closure_graph.iii.o"
"$IIIS" "$GRAPH"   --compile-only --out "$OGRAPH"   || die 3 "iii compile failed: $GRAPH"
log "iiis-2 closure.iii -> closure.iii.o"
"$IIIS" "$CLOSURE" --compile-only --out "$OCLOSURE" || die 3 "iii compile failed: $CLOSURE"
log "iiis-2 closure_cli.iii -> closure_cli.iii.o"
"$IIIS" "$SRC"     --compile-only --out "$OCLI"     || die 3 "iii compile failed: $SRC"

log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "$OCLI" "$OGRAPH" "$OCLOSURE" "$STDLIB_LIB" -lws2_32 -lkernel32; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
