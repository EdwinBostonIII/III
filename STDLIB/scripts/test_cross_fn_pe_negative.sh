#!/usr/bin/env bash
# C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\scripts\test_cross_fn_pe_negative.sh
#
# iiis-2 cross-function Partial-Evaluator narrowing — both-directions
# asm assertion (RITCHIE Stage 3.4).
#
#   POSITIVE  (corpus 272_cross_fn_pe.iii):  intent traces to a user fn
#             whose body returns a literal intent_form(100) -> the PE
#             MUST narrow resolve() to a direct load.  The emitted asm
#             MUST contain `# III_PE_DIRECT_LOAD`.
#   NEGATIVE  (corpus 273_cross_fn_dynamic_intent.iii):  the user fn
#             returns its PARAMETER (NON_STATIC) -> the PE MUST NOT
#             narrow.  The asm MUST NOT contain `# III_PE_DIRECT_LOAD`,
#             yet the program MUST still compile (it is valid; the
#             resolver dispatch is simply left at runtime).
#
# This mirrors scripts/test_*_static_negative.sh.  `IIIS=...` overrides
# the compiler (default: COMPILED/iiis-0.exe).
set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$STDLIB_DIR/build/corpus_pe"
mkdir -p "$TMP_DIR"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) S=".exe" ;;
    *)                                  S=""     ;;
esac

IIIS="${IIIS:-}"
if [[ -z "$IIIS" ]]; then
    if [[ -x "/c/Users/Edwin Boston/OneDrive/Desktop/III/COMPILED/iiis-0$S" ]]; then
        IIIS="/c/Users/Edwin Boston/OneDrive/Desktop/III/COMPILED/iiis-0$S"
    elif command -v iiis >/dev/null 2>&1; then
        IIIS="$(command -v iiis)"
    else
        echo "[pe-neg] FATAL: iiis not found" >&2
        exit 2
    fi
fi
echo "[pe-neg] using $IIIS"

MARK="# III_PE_DIRECT_LOAD"
fail=0

# --- POSITIVE cross-check: 272 MUST narrow (marker present) -----------------
POS_SRC="$STDLIB_DIR/corpus/272_cross_fn_pe.iii"
"$IIIS" "$POS_SRC" --emit-asm-only --out "$TMP_DIR/272" >/dev/null 2>&1
POS_RC=$?
POS_ASM="$TMP_DIR/272.s"
if [[ $POS_RC -ne 0 ]]; then
    echo "[pe-neg] FAIL: 272 compile rc=$POS_RC (expected 0)"; fail=1
elif [[ ! -f "$POS_ASM" ]]; then
    echo "[pe-neg] FAIL: 272 emitted no asm at $POS_ASM"; fail=1
elif ! grep -qF "$MARK" "$POS_ASM"; then
    echo "[pe-neg] FAIL: 272 missing PE marker — narrowing did NOT fire"; fail=1
else
    echo "[pe-neg] OK: 272 narrowed (PE direct-load marker present)"
fi

# --- NEGATIVE: 273 MUST compile but MUST NOT narrow (marker absent) ---------
NEG_SRC="$STDLIB_DIR/corpus/273_cross_fn_dynamic_intent.iii"
"$IIIS" "$NEG_SRC" --emit-asm-only --out "$TMP_DIR/273" >/dev/null 2>&1
NEG_RC=$?
NEG_ASM="$TMP_DIR/273.s"
if [[ $NEG_RC -ne 0 ]]; then
    echo "[pe-neg] FAIL: 273 compile rc=$NEG_RC (it is a VALID program; expected 0)"; fail=1
elif [[ ! -f "$NEG_ASM" ]]; then
    echo "[pe-neg] FAIL: 273 emitted no asm at $NEG_ASM"; fail=1
elif grep -qF "$MARK" "$NEG_ASM"; then
    echo "[pe-neg] FAIL: 273 HAS PE marker — narrowed a NON_STATIC (param-return) intent"; fail=1
else
    echo "[pe-neg] PASS: 273 did NOT narrow (NON_STATIC intent correctly refused)"
fi

if [[ $fail -eq 0 ]]; then
    echo "[pe-neg] ALL PASS: cross-fn PE narrows the static case, refuses the dynamic case"
    exit 0
fi
echo "[pe-neg] FAILED"
exit 1
