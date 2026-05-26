#!/usr/bin/env bash
# Phase 3 Step 3 negative-compile test for @returns_hexad static
# return-kind check.

set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$STDLIB_DIR/corpus/265_neg_return_kind.iii"
TMP_DIR="$STDLIB_DIR/build/corpus_neg"
mkdir -p "$TMP_DIR"
ASM="$TMP_DIR/265_neg.s"
LOG="$TMP_DIR/265_neg.log"

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
        echo "[neg265] FATAL: iiis not found" >&2
        exit 2
    fi
fi

echo "[neg265] using $IIIS"
echo "[neg265] compiling $SRC (expected to FAIL)"

set +e
"$IIIS" "$SRC" --emit-asm-only --out "$ASM" > "$LOG" 2>&1
RC=$?
set -e
ASM_REAL="$ASM"
[[ -f "$ASM.s" ]] && ASM_REAL="$ASM.s"

if [[ $RC -eq 0 ]]; then
    echo "[neg265] FAIL: iiis exit code 0 -- expected non-zero"
    exit 1
fi

if grep -q "III_RETURN_KIND_VIOLATION" "$ASM_REAL" 2>/dev/null \
   || grep -q "III_RETURN_KIND_VIOLATION" "$LOG" 2>/dev/null; then
    echo "[neg265] PASS: iiis rejected with III_RETURN_KIND_VIOLATION marker (rc=$RC)"
    exit 0
fi

echo "[neg265] FAIL: iiis exited non-zero (rc=$RC) but no marker found"
echo "[neg265] asm head:"
head -40 "$ASM_REAL" 2>/dev/null
echo "[neg265] log head:"
head -40 "$LOG" 2>/dev/null
exit 1
