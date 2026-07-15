#!/usr/bin/env bash
# STDLIB/scripts/run_intent_cli.sh -- THE ORACLE OF REJECTION, gated as a standing tool.
#
# iii-intent (intent/intent_cli, over disambiguate + intent_lex + lex_ontology + sat_arith) resolves a
# human intent sentence to ONE interpretation or REJECTS with the reason -- pure bitwise constraint
# satisfaction over a fixed 16-lexeme ontology, deterministic, zero ML.  This gate builds the tool via
# its leaf script and pins ALL FIVE verdict classes on sentences with KNOWN verdicts (derived from the
# ontology's own masks, not from the tool's output), plus determinism.
#
# Exit: 0 all verdicts + determinism hold | 1 a verdict wrong | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$III_ROOT/COMPILER/BOOT"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
TOOL="$III_ROOT/COMPILED/iii-intent${BIN_SUFFIX}"
say() { printf '%s\n' "$*"; }

# stage [1]: build the tool fresh via its leaf script (no chain touch).
bash "$BOOT/build_iii_intent.sh" >/dev/null 2>&1 || { echo "[intent] FATAL: cannot build iii-intent"; exit 2; }
[[ -x "$TOOL" ]] || { echo "[intent] FATAL: no iii-intent at $TOOL"; exit 2; }
say "[intent] iii-intent = $TOOL"

FAIL=0
# each row: EXPECTED_EXIT | sentence.  Verdicts derived from the ontology masks (lex_ontology.iii):
#   lock=FREEZE|ENCRYPT|DENY(7) database=FREEZE(1) freeze=FREEZE(1) disk=FREEZE(1) encrypt=ENCRYPT(2)
#   key=ENCRYPT(2) deny=DENY(4) network=DENY(4) port=DENY(4) hash=DET(8) deterministic=DET(8)
#   generate=DET|STOCH(24) random=STOCH(16) expire=TTL(32) ttl=TTL(32).  0 RESOLVED 1 CONTRADICTION
#   2 AMBIGUOUS 3 EMPTY.
check() {
    local want="$1"; shift
    local sentence="$1"
    "$TOOL" "$sentence" >/dev/null 2>&1
    local got=$?
    if [[ "$got" == "$want" ]]; then
        say "PASS [$got] $sentence"
    else
        say "RED  want=$want got=$got : $sentence   ($("$TOOL" "$sentence" | head -1))"
        FAIL=1
    fi
}

say "[intent] == RESOLVED (0): the masks intersect to exactly one bit =="
check 0 "lock the database"       # 7 & 1 = 1 (FREEZE)
check 0 "freeze the disk"         # 1 & 1 = 1 (FREEZE)
check 0 "expire the ttl"          # 32 & 32 = 32 (TTL)
check 0 "encrypt the key"         # 2 & 2 = 2 (ENCRYPT)
check 0 "deny the port"           # 4 & 4 = 4 (DENY)
check 0 "lock the network"        # 7 & 4 = 4 (DENY) -- lock disambiguated by network

say "[intent] == CONTRADICTION (1): the masks share no bit =="
check 1 "encrypt the network port"  # 2 & 4 & 4 = 0
check 1 "generate a key"            # 24 & 2 = 0
check 1 "freeze the port"           # 1 & 4 = 0

say "[intent] == AMBIGUOUS (2): more than one interpretation survives =="
# NOTE (honest): the ontology has exactly two multi-bit lexemes -- lock(FREEZE|ENCRYPT|DENY) and
# generate(DET|STOCH) -- and every other operator is single-bit, so ANY second operator narrows them
# to RESOLVED or CONTRADICTION.  The genuine AMBIGUOUS cases are therefore the bare multi-bit words
# (and a repeat, which the tokenizer keeps).  A two-word ambiguity is structurally impossible here.
check 2 "lock"                    # 7 -- three bits survive
check 2 "generate"               # 24 -- two bits survive
check 2 "lock lock"              # 7 & 7 = 7 -- still three bits (repeat, not narrowed)

say "[intent] == EMPTY (3): no operator lexeme =="
check 3 "the cat sat on the mat"
check 3 "hello world"

say "[intent] == determinism: same sentence, identical bytes twice =="
A="$("$TOOL" "lock the database" 2>&1)"
B="$("$TOOL" "lock the database" 2>&1)"
if [[ "$A" == "$B" ]]; then say "PASS determinism"; else say "RED determinism: '$A' vs '$B'"; FAIL=1; fi

if [[ $FAIL -ne 0 ]]; then echo "[intent] RED"; exit 1; fi
echo "[intent] GREEN: RESOLVED/CONTRADICTION/AMBIGUOUS/EMPTY all pinned on known-verdict sentences + determinism"
exit 0
