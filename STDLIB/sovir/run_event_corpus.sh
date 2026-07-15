#!/usr/bin/env bash
# STDLIB/sovir/run_event_corpus.sh -- ROUTE V AS A CORPUS-SCALE MEANING-BEARER.
#
# The event-primary waist (STDLIB/sovir/svir_event.iii, gate run_event_waist.sh) is a fourth
# independent executor of .iii -- alongside native(cg_r3+x86), eval.iii (the Theta meaning-lift), and
# svir_interp (route S).  This gate promotes route V from the 19-probe square theater to the SAME
# corpus theater the meaning-lift uses: EVERY extern-free KAT (single-file, no imports -- executable
# by the standing tool iii-events with no linking), run event-primarily, its exit code pinned == the
# NATIVE compiled route's exit code.  The native route is the oracle; route V is the challenger; a
# disagreement is a SPLIT (red).  Programs cg_svir cannot yet emit, or that exceed the log capacity,
# are the honest FRONTIER -- named by class, counted, and pinned as an up-only ratchet floor (the
# Theta run_meaning.sh honest-frontier discipline: the covered count only rises).
#
# Exit: 0 green (0 splits AND covered >= the pinned floor) | 1 split/regression | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$III_ROOT/COMPILER/BOOT"
CORPUS="$III_ROOT/STDLIB/corpus"
W="$III_ROOT/STDLIB/build/eventcorpus"
RATCHET="$SCRIPT_DIR/event_corpus_ratchet.txt"
mkdir -p "$W"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
TOOL="$III_ROOT/COMPILED/iii-events${BIN_SUFFIX}"
EVAL_BIN="$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}"   # the Theta meaning-bearer -- a THIRD oracle,
                                                       # independent of cg_r3/x86 exactly as route V is
[[ -x "$IIIS" && -f "$LIB" ]] || { echo "[event-corpus] FATAL: missing toolchain"; exit 2; }
say() { printf '%s\n' "$*"; }

# stage [1]: the standing tool must exist and be current (rebuild via its leaf script -- no cascade).
if [[ ! -x "$TOOL" ]]; then
    bash "$BOOT/build_iii_events.sh" >/dev/null 2>&1 || { echo "[event-corpus] FATAL: cannot build iii-events"; exit 2; }
fi
say "[event-corpus] iii-events = $TOOL"

AGREE=0; SPLIT=0; FR_EMIT=0; FR_CAP=0; FR_OTHER=0; TOTAL=0
THREEWAY=0; XMODE=0   # THREEWAY: native==eval==routeV; XMODE: eval-vs-routeV disagreements (must stay 0)
: > "$W/_agree.list"; : > "$W/_split.list"; : > "$W/_frontier.list"
# THE THEATER: the meaning-lift corpus (STDLIB/corpus extern-free) + the BOOTSTRAP theater
# (stage1_corpus extern-free -- the programs that gate the seed chain; 20_sizeof lives here, the
# KAT whose four-way split exposed the sizeof silent-zero divergence this gate now pins healed).
for f in "$CORPUS"/[0-9]*.iii "$III_ROOT"/COMPILER/BOOT/stage1_corpus/[0-9]*.iii; do
    grep -q "extern" "$f" 2>/dev/null && continue        # single-file, import-free = the tool's domain
    TOTAL=$((TOTAL+1)); base="$(basename "$f" .iii)"
    # NATIVE oracle
    if ! "$IIIS" "$f" --compile-only --out "$W/n.o" >/dev/null 2>&1; then
        # native compile refused too -> not a route-V frontier; a negative-compile KAT. Skip (out of theater).
        echo "$base native-noncompile" >> "$W/_frontier.list"; FR_OTHER=$((FR_OTHER+1)); continue
    fi
    rm -f "$W/n$BIN_SUFFIX"
    gcc "$W/n.o" "$LIB" -lws2_32 -lkernel32 -o "$W/n$BIN_SUFFIX" >/dev/null 2>&1 || { echo "$base native-nolink" >> "$W/_frontier.list"; FR_OTHER=$((FR_OTHER+1)); continue; }
    cp "$W/n$BIN_SUFFIX" "/tmp/ec_n_$$$BIN_SUFFIX"; timeout 60 "/tmp/ec_n_$$$BIN_SUFFIX" >/dev/null 2>&1; RN=$?; rm -f "/tmp/ec_n_$$$BIN_SUFFIX"
    # ROUTE V challenger (the standing tool, in-process front-end + event executor)
    timeout 60 "$TOOL" --quiet "$f" >/dev/null 2>&1; RV=$?
    if [[ "$RN" == "$RV" ]]; then
        AGREE=$((AGREE+1)); echo "$base rc=$RN" >> "$W/_agree.list"
        # THIRD ORACLE: eval.iii (the Theta bearer).  213/214 = eval-abstain (out of its fragment) -- not
        # a disagreement.  A real eval verdict that differs from route V is an XMODE break: two bearers
        # BOTH independent of cg_r3/x86 must never split (that would be the common-mode blindness Theta names).
        if [[ -x "$EVAL_BIN" ]]; then
            timeout 60 "$EVAL_BIN" "$f" >/dev/null 2>&1; RE=$?
            if [[ "$RE" == 213 || "$RE" == 214 ]]; then :   # eval abstains -- fine, native==routeV stands
            elif [[ "$RE" == "$RV" ]]; then THREEWAY=$((THREEWAY+1))
            else XMODE=$((XMODE+1)); say "XMODE-SPLIT $base: eval=$RE route-V=$RV (two cg_r3-independent bearers disagree)"; fi
        fi
    elif [[ "$RV" == 6 ]]; then
        FR_EMIT=$((FR_EMIT+1)); echo "$base svir-emit-refused" >> "$W/_frontier.list"
    elif [[ "$RV" == 190 || "$RV" == 192 ]]; then
        FR_CAP=$((FR_CAP+1)); echo "$base log-capacity($RV)" >> "$W/_frontier.list"
    else
        SPLIT=$((SPLIT+1)); echo "$base N=$RN V=$RV" >> "$W/_split.list"
        say "SPLIT $base: native=$RN route-V=$RV"
    fi
done

FRONTIER=$((FR_EMIT+FR_CAP+FR_OTHER))
say "[event-corpus] covered(agree)=$AGREE  splits=$SPLIT  frontier=$FRONTIER (emit=$FR_EMIT cap=$FR_CAP other=$FR_OTHER)  total=$TOTAL"
say "[event-corpus] three-way (native==eval==routeV)=$THREEWAY  eval-vs-routeV disagreements=$XMODE (the common-mode-blindness kill: must be 0)"

# up-only ratchet: covered may only rise; splits must be zero.
FLOOR=0
[[ -f "$RATCHET" ]] && FLOOR="$(grep -E '^covered_floor=' "$RATCHET" | head -1 | cut -d= -f2 | tr -dc '0-9')"
FLOOR="${FLOOR:-0}"
FAIL=0
if [[ $SPLIT -ne 0 ]]; then say "[event-corpus] RED: $SPLIT split(s) -- route V disagrees with the native oracle"; FAIL=1; fi
if [[ $XMODE -ne 0 ]]; then say "[event-corpus] RED: $XMODE eval-vs-routeV disagreement(s) -- two cg_r3-independent bearers split"; FAIL=1; fi
if [[ $AGREE -lt $FLOOR ]]; then say "[event-corpus] RED: covered $AGREE < pinned floor $FLOOR (a KAT stopped being executable -- regression)"; FAIL=1; fi
if [[ $AGREE -lt 50 ]]; then say "[event-corpus] RED: anti-vacuity floor 50 not met (covered=$AGREE)"; FAIL=1; fi

if [[ $FAIL -eq 0 ]]; then
    # advance the ratchet on green (up-only)
    if [[ $AGREE -gt $FLOOR ]]; then
        {
            echo "# STDLIB/sovir/event_corpus_ratchet.txt -- route V corpus-scale coverage, UP-ONLY."
            echo "# Enforced by run_event_corpus.sh: covered may only rise; splits must be 0."
            echo "covered_floor=$AGREE"
            echo "# frontier at last green: emit-refused=$FR_EMIT capacity=$FR_CAP other=$FR_OTHER total=$TOTAL"
        } > "$RATCHET"
        say "[event-corpus] ratchet advanced: covered_floor $FLOOR -> $AGREE"
    fi
    say "[event-corpus] GREEN: $AGREE/$TOTAL extern-free KATs -- route V (event-primary) == native (rc), 0 splits; frontier $FRONTIER named"
    exit 0
fi
exit 1
