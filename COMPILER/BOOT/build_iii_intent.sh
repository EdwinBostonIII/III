#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_intent.sh
#
# Build iii-intent: THE ORACLE OF REJECTION AS A STANDING TOOL.
#
#     iii-intent "<sentence>"     resolve a human intent to ONE interpretation, or REJECT with the reason
#
# This makes III's intent disambiguator (intent/disambiguate + intent_lex + lex_ontology + sat_arith)
# independently useful on ARBITRARY sentences: pure bitwise constraint satisfaction over a fixed
# 16-lexeme ontology, zero ML, deterministic.  A LEAF tool build (the build_iii_eval discipline):
# pinned in-tree iiis-2 + the committed stdlib archive; the bootstrap chain is never touched.
#
# Usage: bash build_iii_intent.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-intent build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"
SRC="$III_ROOT/STDLIB/iii/intent/intent_cli.iii"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-intent${BIN_SUFFIX}"
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

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-intent-build.XXXXXX")"
trap '[[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true' EXIT
OBJ="$TMP_ROOT/intent_cli.iii.o"

log "iiis-2 intent_cli.iii -> intent_cli.iii.o"
"$IIIS" "$SRC" --compile-only --out "$OBJ" || die 3 "iii compile failed: $SRC"

# the disambiguator + lexicon + ontology + sat_arith popcount all live in the archive; --whole-archive
# is unnecessary (the driver references them, so the linker pulls them).  OneDrive lock-retry.
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
