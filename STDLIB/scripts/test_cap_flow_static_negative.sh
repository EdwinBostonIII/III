#!/usr/bin/env bash
# Phase 3 Step 3 negative-compile test for @cap_required static cap-flow.
#
# Source corpus/262_neg_cap_flow.iii MUST fail to compile.  We assert:
#   1. iiis exit code != 0
#   2. asm output contains "III_CAP_FLOW_VIOLATION"
#
# The asm-comment marker is produced by the codegen in cg_r3.c at the
# moment the violation is detected, even though compilation halts on
# the error.  We capture stdout to a temp asm file and grep it.

set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$STDLIB_DIR/corpus/262_neg_cap_flow.iii"
TMP_DIR="$STDLIB_DIR/build/corpus_neg"
mkdir -p "$TMP_DIR"
ASM="$TMP_DIR/262_neg.s"
LOG="$TMP_DIR/262_neg.log"

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
        echo "[neg262] FATAL: iiis not found" >&2
        exit 2
    fi
fi

echo "[neg262] using $IIIS"
echo "[neg262] compiling $SRC (expected to FAIL)"

# iiis emits asm with --emit-asm-only; the violation comment is written
# to the asm stream at the moment of rejection.
set +e
"$IIIS" "$SRC" --emit-asm-only --out "$ASM" > "$LOG" 2>&1
RC=$?
set -e
# iiis adds .s suffix to --out when emit-asm-only is set, so the real
# output path is "$ASM.s".  Cover both.
ASM_REAL="$ASM"
[[ -f "$ASM.s" ]] && ASM_REAL="$ASM.s"

if [[ $RC -eq 0 ]]; then
    echo "[neg262] FAIL: iiis exit code 0 -- expected non-zero (static check should have rejected)"
    exit 1
fi

# Even on compile failure, the asm-comment marker should be present
# in either the asm file (if partial) or the stderr log.
if grep -q "III_CAP_FLOW_VIOLATION" "$ASM_REAL" 2>/dev/null \
   || grep -q "III_CAP_FLOW_VIOLATION" "$LOG" 2>/dev/null; then
    echo "[neg262] PASS: iiis rejected with III_CAP_FLOW_VIOLATION marker (rc=$RC)"
    exit 0
fi

echo "[neg262] FAIL: iiis exited non-zero (rc=$RC) but no III_CAP_FLOW_VIOLATION marker found"
echo "[neg262] asm head:"
head -40 "$ASM_REAL" 2>/dev/null || echo "[neg262] (no asm produced)"
echo "[neg262] log head:"
head -40 "$LOG" 2>/dev/null || echo "[neg262] (no log produced)"
exit 1
