#!/usr/bin/env bash
# Phase 3 Step 3 negative-compile test for iiis-1 first-class intent
# types (param-level @hexad_kind static check at call sites).
#
# corpus/263_neg_intent_kind.iii MUST fail to compile.  Asserts:
#   1. iiis exit code != 0
#   2. asm output contains "III_INTENT_KIND_VIOLATION"

set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$STDLIB_DIR/corpus/263_neg_intent_kind.iii"
TMP_DIR="$STDLIB_DIR/build/corpus_neg"
mkdir -p "$TMP_DIR"
ASM="$TMP_DIR/263_neg.s"
LOG="$TMP_DIR/263_neg.log"

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
        echo "[neg263] FATAL: iiis not found" >&2
        exit 2
    fi
fi

echo "[neg263] using $IIIS"
echo "[neg263] compiling $SRC (expected to FAIL)"

set +e
"$IIIS" "$SRC" --emit-asm-only --out "$ASM" > "$LOG" 2>&1
RC=$?
set -e
ASM_REAL="$ASM"
[[ -f "$ASM.s" ]] && ASM_REAL="$ASM.s"

if [[ $RC -eq 0 ]]; then
    echo "[neg263] FAIL: iiis exit code 0 -- expected non-zero"
    exit 1
fi

if grep -q "III_INTENT_KIND_VIOLATION" "$ASM_REAL" 2>/dev/null \
   || grep -q "III_INTENT_KIND_VIOLATION" "$LOG" 2>/dev/null; then
    echo "[neg263] PASS: iiis rejected with III_INTENT_KIND_VIOLATION marker (rc=$RC)"
    exit 0
fi

echo "[neg263] FAIL: iiis exited non-zero (rc=$RC) but no marker found"
echo "[neg263] asm head:"
head -40 "$ASM_REAL" 2>/dev/null || echo "[neg263] (no asm produced)"
echo "[neg263] log head:"
head -40 "$LOG" 2>/dev/null || echo "[neg263] (no log produced)"
exit 1
