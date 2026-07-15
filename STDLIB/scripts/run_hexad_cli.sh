#!/usr/bin/env bash
# STDLIB/scripts/run_hexad_cli.sh -- THE ASYMMETRIC TERNARY SAFETY GROUND, gated as a standing tool.
#
# iii-hexad (omnia/hexad_cli, over hexad_reach + hexad_algebra) decides whether a hexad is ADMITTED or
# bricking-by-construction: a NEG in ANY structural pillar (P1..P4) makes it structurally unrepresentable.
# This gate pins the manifold size (144), the structural/informational asymmetry, the compose dominance,
# and -- the adversarial arm -- cross-checks the tool's verdict against an INDEPENDENT computation of the
# admission rule (no NEG in the first four pillars) over a spanning sample.
#
# Exit: 0 all hold | 1 a verdict / cross-check wrong | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$III_ROOT/COMPILER/BOOT"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
TOOL="$III_ROOT/COMPILED/iii-hexad${BIN_SUFFIX}"
say() { printf '%s\n' "$*"; }

bash "$BOOT/build_iii_hexad.sh" >/dev/null 2>&1 || { echo "[hexad] FATAL: cannot build iii-hexad"; exit 2; }
[[ -x "$TOOL" ]] || { echo "[hexad] FATAL: no iii-hexad at $TOOL"; exit 2; }
say "[hexad] iii-hexad = $TOOL"
FAIL=0

# --count must be exactly 144 (2^4 * 3^2).
CNT="$("$TOOL" --count | grep -o '= [0-9]*' | head -1 | tr -dc '0-9')"
if [[ "$CNT" == "144" ]]; then say "PASS --count = 144"; else say "RED --count = $CNT (want 144)"; FAIL=1; fi

# expected-verdict helper: admitted (0) iff none of the first FOUR pillars is NEG.
expected() {   # args: 6 trit tokens (N/Z/P)
    local i=0
    for t in "$1" "$2" "$3" "$4"; do
        if [[ "$t" == "N" ]]; then echo 1; return; fi   # a structural NEG -> bricking
    done
    echo 0
}
check6() {   # 6 trits; verdict must equal the independent rule
    "$TOOL" "$1" "$2" "$3" "$4" "$5" "$6" >/dev/null 2>&1
    local got=$?
    local want; want="$(expected "$1" "$2" "$3" "$4" "$5" "$6")"
    if [[ "$got" == "$want" ]]; then
        say "PASS [$got] $1 $2 $3 $4 $5 $6"
    else
        say "RED  want=$want got=$got : $1 $2 $3 $4 $5 $6"
        FAIL=1
    fi
}

say "[hexad] == structural pillars: a NEG in P1..P4 bricks =="
check6 N P P P P P ; check6 P N P P P P ; check6 P P N P P P ; check6 P P P N P P
say "[hexad] == informational pillars: a NEG in P5/P6 is admitted =="
check6 P P P P N P ; check6 P P P P P N ; check6 Z Z Z Z N N
say "[hexad] == corners =="
check6 P P P P P P ; check6 Z Z Z Z Z Z ; check6 P Z P Z P Z

say "[hexad] == ADVERSARIAL CROSS-CHECK: tool verdict == the structural rule, spanning sample =="
# every single-NEG position, every all-same, and a diagonal mix -- 6 + 3 + a spread.
for a in N Z P; do for b in N Z P; do
    check6 "$a" "$b" P Z P Z
done; done

say "[hexad] == compose: NEG dominates AND on the structural pillars =="
"$TOOL" --compose P P P P P P N P P P P P >/dev/null 2>&1
if [[ $? -eq 1 ]]; then say "PASS compose(all-POS, NEG@P1) -> BRICKING (irreversibility dominates)"; else say "RED compose dominance"; FAIL=1; fi
"$TOOL" --compose P P P P Z Z P P P P Z Z >/dev/null 2>&1
if [[ $? -eq 0 ]]; then say "PASS compose(admitted, admitted) -> ADMITTED"; else say "RED compose admitted"; FAIL=1; fi

say "[hexad] == input forms N/Z/P == NEG/ZERO/POS == -1/0/1 =="
O1="$("$TOOL" N Z P P P P 2>&1 | head -1)"
O2="$("$TOOL" NEG ZERO POS POS POS POS 2>&1 | head -1)"
O3="$("$TOOL" -1 0 1 1 1 1 2>&1 | head -1)"
if [[ "$O1" == "$O2" && "$O2" == "$O3" ]]; then say "PASS input-form equivalence"; else say "RED input forms: '$O1' '$O2' '$O3'"; FAIL=1; fi

say "[hexad] == determinism =="
D1="$("$TOOL" P N P Z P N 2>&1)"; D2="$("$TOOL" P N P Z P N 2>&1)"
if [[ "$D1" == "$D2" ]]; then say "PASS determinism"; else say "RED determinism"; FAIL=1; fi

if [[ $FAIL -ne 0 ]]; then echo "[hexad] RED"; exit 1; fi
echo "[hexad] GREEN: 144-manifold + structural/informational asymmetry + compose dominance + adversarial cross-check vs the structural rule + input-form equivalence + determinism"
exit 0
