#!/usr/bin/env bash
# Stage 3.6 negative-compile test for multi-hop type-alias resolution.
#
# corpus/275_neg_type_alias_multihop.iii MUST fail to compile.  Asserts:
#   1. iiis exit code != 0
#   2. asm/log output contains "III_INTENT_KIND_VIOLATION"
#
# This passes ONLY with multi-hop resolution: the param's kind is 3 alias
# hops deep (CKind->BKind->AKind), so single-hop resolution would skip the
# check and the file would compile (rc 0), failing assertion (1).

set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$STDLIB_DIR/corpus/275_neg_type_alias_multihop.iii"
TMP_DIR="$STDLIB_DIR/build/corpus_neg"
mkdir -p "$TMP_DIR"
ASM="$TMP_DIR/275_neg.s"
LOG="$TMP_DIR/275_neg.log"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

IIIS="${IIIS:-}"
if [[ -z "$IIIS" ]]; then
    if [[ -x "/c/Users/Edwin Boston/OneDrive/Desktop/III/COMPILED/iiis-0$BIN_SUFFIX" ]]; then
        IIIS="/c/Users/Edwin Boston/OneDrive/Desktop/III/COMPILED/iiis-0$BIN_SUFFIX"
    elif command -v iiis >/dev/null 2>&1; then
        IIIS="$(command -v iiis)"
    else
        echo "[neg275] FATAL: iiis not found" >&2
        exit 2
    fi
fi

echo "[neg275] using $IIIS"
echo "[neg275] compiling $SRC (expected to FAIL)"

set +e
"$IIIS" "$SRC" --emit-asm-only --out "$ASM" > "$LOG" 2>&1
RC=$?
set -e
ASM_REAL="$ASM"
[[ -f "$ASM.s" ]] && ASM_REAL="$ASM.s"

if [[ $RC -eq 0 ]]; then
    echo "[neg275] FAIL: iiis exit code 0 -- expected non-zero (single-hop would skip the 3-hop kind)"
    exit 1
fi

if grep -q "III_INTENT_KIND_VIOLATION" "$ASM_REAL" 2>/dev/null \
   || grep -q "III_INTENT_KIND_VIOLATION" "$LOG" 2>/dev/null; then
    echo "[neg275] PASS: iiis rejected the 3-hop-alias mismatch with III_INTENT_KIND_VIOLATION (rc=$RC)"
    exit 0
fi

echo "[neg275] FAIL: iiis exited non-zero (rc=$RC) but no marker found"
echo "[neg275] asm head:"
head -40 "$ASM_REAL" 2>/dev/null || echo "[neg275] (no asm produced)"
echo "[neg275] log head:"
head -40 "$LOG" 2>/dev/null || echo "[neg275] (no log produced)"
exit 1
