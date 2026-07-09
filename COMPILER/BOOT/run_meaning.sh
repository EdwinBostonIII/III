#!/usr/bin/env bash
# COMPILER/BOOT/run_meaning.sh — THE MEANING GATE (Theta-0, the Meaning Lift)
#
# Differentially executes .iii programs through BOTH meaning-bearers:
#   route N (native): pinned iiis-2 --compile-only -> gcc link -> run
#   route E (eval)  : iii_eval (lex+parse+definitional evaluator; NO sema/cg)
# and asserts rc equality observed through the SAME channel (bash $?), so
# truncation semantics cancel.  PASS requires the III_EVAL_OK marker AND
# rc_N == rc_E.
#
# Sections:
#   1. self-test    comparator teeth (two-path): a synthetic divergence MUST
#                   classify DIVERGE; an unsupported construct MUST classify
#                   UNSUPPORTED (never PASS).  Gate-of-the-gate.
#   2. probes       meaning_probes/p*.iii — ALL must PASS (hard floor).
#   3. corpus       every extern-free, non-negative corpus KAT — PASS count
#                   must be >= the pinned ratchet (meaning_ratchet.txt,
#                   up-only).  UNSUPPORTED is named per code/kind, never red;
#                   DIVERGE is ALWAYS red (that is the instrument firing).
#
# Exit: 0 green | 1 divergence | 2 env | 3 probe red | 4 ratchet | 5 selftest
set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
CORPUS_DIR="$III_ROOT/STDLIB/corpus"
RUN_DIR="$III_ROOT/STDLIB/build/meaning"
mkdir -p "$RUN_DIR"
LOG="$RUN_DIR/run_meaning.log"
: > "$LOG"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
LIB_ARCHIVE="$III_ROOT/STDLIB/build/iii/libiii_native.a"
RATCHET_FILE="$BOOT_DIR/meaning_ratchet.txt"

[[ -x "$IIIS" ]]      || { echo "[meaning] FATAL: no pinned iiis-2 at $IIIS"; exit 2; }
[[ -f "$LIB_ARCHIVE" ]] || { echo "[meaning] FATAL: no stdlib archive"; exit 2; }
if [[ ! -x "$EVAL_BIN" ]]; then
    echo "[meaning] iii_eval missing -- building"
    bash "$BOOT_DIR/build_iii_eval.sh" || exit 2
fi

say() { printf '%s\n' "$*" | tee -a "$LOG"; }

# ── run one file through both routes; sets CLASS/RCN/RCE/EVOUT ──────────────
# CLASS in {PASS, DIVERGE, EVAL_UNSUPPORTED, EVAL_TIMEOUT, NATIVE_CFAIL,
#           NATIVE_LFAIL, NATIVE_TIMEOUT}
run_pair() {
    local src="$1" base obj exe staged rc out
    base="$(basename "$src" .iii)"
    obj="$RUN_DIR/${base}.o"
    exe="$RUN_DIR/${base}${BIN_SUFFIX}"
    CLASS="" ; RCN="" ; RCE="" ; EVOUT=""
    rm -f "$obj"
    timeout 60 "$IIIS" "$src" --compile-only --out "$obj" >>"$LOG" 2>&1
    rc=$?
    if [[ $rc -ne 0 ]]; then CLASS="NATIVE_CFAIL"; RCN=$rc; return; fi
    rc=1
    local _la
    for _la in 1 2 3; do
        rm -f "$exe"
        gcc "$obj" "$LIB_ARCHIVE" -lws2_32 -lkernel32 -o "$exe" >>"$LOG" 2>&1
        rc=$?
        [[ $rc -eq 0 && -f "$exe" ]] && break
        sleep 1
    done
    if [[ $rc -ne 0 ]]; then CLASS="NATIVE_LFAIL"; RCN=$rc; return; fi
    staged="/tmp/meaning_$$_${RANDOM}${BIN_SUFFIX}"
    cp "$exe" "$staged"
    timeout 120 "$staged" >>"$LOG" 2>&1
    RCN=$?
    rm -f "$staged"
    if [[ $RCN -eq 124 ]]; then CLASS="NATIVE_TIMEOUT"; return; fi
    EVOUT="$(timeout 120 "$EVAL_BIN" "$src" 2>>"$LOG")"
    RCE=$?
    if [[ $RCE -eq 124 ]]; then CLASS="EVAL_TIMEOUT"; return; fi
    case "$EVOUT" in
        *III_EVAL_OK*)
            if [[ "$RCN" == "$RCE" ]]; then CLASS="PASS"; else CLASS="DIVERGE"; fi
            ;;
        *III_EVAL_FAIL*)
            CLASS="EVAL_UNSUPPORTED"
            ;;
        *)
            CLASS="EVAL_UNSUPPORTED"
            EVOUT="(no marker) $EVOUT"
            ;;
    esac
}

# ═══ 1. SELF-TEST (comparator teeth, two-path) ══════════════════════════════
say "[meaning] == selftest =="
ST_DIR="$RUN_DIR/selftest"
mkdir -p "$ST_DIR"
# (a) a program whose two routes AGREE -> must classify PASS
cat > "$ST_DIR/st_agree.iii" <<'IIEOF'
module st_agree
fn main() -> u64 { return 42u64 }
IIEOF
run_pair "$ST_DIR/st_agree.iii"
if [[ "$CLASS" != "PASS" ]]; then say "[meaning] SELFTEST RED: agree-case classified $CLASS (rcN=$RCN rcE=$RCE)"; exit 5; fi
# (b) the comparator MUST be able to say DIVERGE: run the agree-case
#     against a FAKE eval route that prints the OK marker but exits with
#     a different rc -- end-to-end classification must say DIVERGE.
cat > "$ST_DIR/fake_eval.sh" <<'SHEOF'
#!/usr/bin/env bash
echo "III_EVAL_OK ret=0x000000000000002b"
exit 43
SHEOF
chmod +x "$ST_DIR/fake_eval.sh"
EVAL_BIN_REAL="$EVAL_BIN"
EVAL_BIN="$ST_DIR/fake_eval.sh"
run_pair "$ST_DIR/st_agree.iii"
EVAL_BIN="$EVAL_BIN_REAL"
if [[ "$CLASS" != "DIVERGE" ]]; then say "[meaning] SELFTEST RED: fake-route mismatch classified $CLASS (want DIVERGE)"; exit 5; fi
# (c) an unsupported construct (match) -> must classify EVAL_UNSUPPORTED,
#     never PASS (proves the unsupported channel is not counted green).
cat > "$ST_DIR/st_unsup.iii" <<'IIEOF'
module st_unsup
fn pick(x: u64) -> u64 {
    match x { 0 => { return 1u64 } _ => { return 2u64 } }
}
fn main() -> u64 { return pick(0u64) + 98u64 }
IIEOF
run_pair "$ST_DIR/st_unsup.iii"
if [[ "$CLASS" == "PASS" ]]; then say "[meaning] SELFTEST RED: unsupported construct classified PASS"; exit 5; fi
say "[meaning] selftest OK (agree=PASS, mismatch-arm live, unsup=$CLASS)"

# ═══ 2. PROBES (hard floor: every probe must PASS) ══════════════════════════
say "[meaning] == probes =="
PROBE_FAIL=0
PROBE_N=0
for src in "$BOOT_DIR"/meaning_probes/p*.iii; do
    [[ -f "$src" ]] || continue
    PROBE_N=$((PROBE_N + 1))
    run_pair "$src"
    if [[ "$CLASS" == "PASS" ]]; then
        say "PASS  probe $(basename "$src") rc=$RCN"
    else
        say "RED   probe $(basename "$src") class=$CLASS rcN=${RCN:-} rcE=${RCE:-} ev=${EVOUT:-}"
        PROBE_FAIL=$((PROBE_FAIL + 1))
    fi
done
if [[ $PROBE_FAIL -ne 0 ]]; then say "[meaning] PROBE FLOOR RED: $PROBE_FAIL/$PROBE_N"; exit 3; fi
say "[meaning] probe floor GREEN: $PROBE_N/$PROBE_N"

# ═══ 3. CORPUS (extern-free slice, up-only ratchet) ═════════════════════════
say "[meaning] == corpus (extern-free, non-negative) =="
PASS=0; DIV=0; UNSUP=0; SKIP=0; TOTAL=0
declare -A UNSUP_BY
DIVLIST=()
for src in $(grep -L "extern" "$CORPUS_DIR"/[0-9]*_*.iii 2>/dev/null | LC_ALL=C sort); do
    base="$(basename "$src" .iii)"
    case "$base" in *_neg_*|*_neg) continue ;; esac
    TOTAL=$((TOTAL + 1))
    run_pair "$src"
    case "$CLASS" in
        PASS)
            PASS=$((PASS + 1))
            say "PASS  $base rc=$RCN"
            ;;
        DIVERGE)
            DIV=$((DIV + 1))
            DIVLIST+=("$base rcN=$RCN rcE=$RCE $EVOUT")
            say "DIVERGE $base rcN=$RCN rcE=$RCE ev=$EVOUT"
            ;;
        EVAL_UNSUPPORTED)
            UNSUP=$((UNSUP + 1))
            key="$(printf '%s' "$EVOUT" | grep -o 'code=[0-9]* .*kind=[0-9]*' | head -1)"
            UNSUP_BY["${key:-unknown}"]=$(( ${UNSUP_BY["${key:-unknown}"]:-0} + 1 ))
            say "UNSUP $base $EVOUT"
            ;;
        *)
            SKIP=$((SKIP + 1))
            say "SKIP  $base class=$CLASS rcN=${RCN:-}"
            ;;
    esac
done

say "[meaning] corpus: total=$TOTAL pass=$PASS diverge=$DIV unsupported=$UNSUP native-skip=$SKIP"
say "[meaning] unsupported census (the named frontier):"
for k in "${!UNSUP_BY[@]}"; do say "  $k -> ${UNSUP_BY[$k]}"; done | LC_ALL=C sort | tee -a "$LOG" >/dev/null

if [[ $DIV -ne 0 ]]; then
    say "[meaning] DIVERGENCE RED (the instrument fired -- adjudicate per Theta-4):"
    for d in "${DIVLIST[@]}"; do say "  $d"; done
    exit 1
fi

RATCHET=0
[[ -f "$RATCHET_FILE" ]] && RATCHET="$(tr -dc '0-9' < "$RATCHET_FILE")"
RATCHET="${RATCHET:-0}"
if [[ $PASS -lt $RATCHET ]]; then
    say "[meaning] RATCHET RED: pass=$PASS < pinned=$RATCHET"
    exit 4
fi
if [[ $PASS -gt $RATCHET ]]; then
    say "[meaning] ratchet can rise: pass=$PASS > pinned=$RATCHET (raise meaning_ratchet.txt)"
fi
say "[meaning] GREEN: probes $PROBE_N/$PROBE_N, corpus $PASS/$TOTAL pass, 0 divergence, ratchet=$RATCHET"
exit 0
