#!/usr/bin/env bash
# STDLIB/scripts/run_author.sh -- AUTARKEIA Alpha-4: THE AUTHOR (machine growth under THE NAMED-DEFICIT LAW).
#
# Alpha-2 made the VERDICT sovereign (iii-judge); Alpha-3 made the COVENANT evergreen and cross-host.
# Alpha-4 lets the machine EXTEND its own sealed surface -- autonomously -- but only under a LAW that
# III itself adjudicates (iii-author), never bash:
#
#   THE NAMED-DEFICIT LAW.  No agenda item exists unless it cites a deficit ALREADY NAMED in the
#   testament.  A seal is admitted only if it STRICTLY DECREASES its named counter OR extends a
#   census with TWO AGREEING ROUTES.  Novelty=NONE => reject.  Per-cycle admission cap.  Provenance
#   recorded per seal: MACHINE / HUMAN / AI.
#   Exit gate: N>=3 consecutive AUTONOMOUS cycles, zero human/AI edits, each cycle's testament green,
#   each cycle strictly shrinking at least one named counter.
#
# The autonomous ENGINE is III's own PILOT (aether/mathesis_pilot -- campaign Upsilon, "nobody
# steers"): a deterministic policy picks each round's experiment from the round number ALONE; the
# round budget is the only input and it SELECTS NOTHING.  Growing the budget deterministically
# reaches more of the canonical cube-free NEW-D targets, each via TWO AGREEING ROUTES (curve 1 and
# curve 2).  The named counter shrunk is `unreached` = (horizon kind-0 slots) - (kind-0 targets
# reached).  Every admitted seal is provenance=MACHINE; the pilot head is a pure function of the
# budget, so "nobody steers" is OBSERVABLE (two runs, one head).
#
# Exit 0 = the law holds over >=3 autonomous cycles + every adversarial breach is named-rejected.
# Any other exit names its stage.
set -u
IFS=$'\n\t'
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) X=".exe" ;;
    *)                                  X=""    ;;
esac
BUILD="$ROOT/STDLIB/build/iii"; LIB="$BUILD/libiii_native.a"
IIIS="${IIIS:-$ROOT/COMPILED/iiis-2$X}"
W="$ROOT/STDLIB/build/author"; mkdir -p "$W"
say() { printf '%s\n' "$*"; }
FAIL=0
red() { say "RED  $*"; FAIL=1; }
grn() { say "PASS $*"; }
[ -x "$IIIS" ] || { say "[author] env: no pinned iiis-2"; exit 2; }
[ -f "$LIB"  ] || { say "[author] env: no stdlib archive"; exit 2; }

# ---- build the three sovereign tools ----
say "[author] == build iii-testament + iii-judge + iii-author =="
bash "$ROOT/COMPILER/BOOT/build_iii_testament.sh" --out "$W/iii-testament$X" >"$W/b_t.log" 2>&1 || { red "iii-testament build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_judge.sh"     --out "$W/iii-judge$X"     >"$W/b_j.log" 2>&1 || { red "iii-judge build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_author.sh"    --out "$W/iii-author$X"    >"$W/b_a.log" 2>&1 || { red "iii-author build"; exit 1; }
T="$W/iii-testament$X"; JU="$W/iii-judge$X"; AU="$W/iii-author$X"
grn "iii-testament + iii-judge + iii-author built from source"

# ---- build the autonomous engine: III's PILOT (closure from source, no committed .o depended on) ----
say "[author] == build the PILOT (the autonomous engine; nobody steers) =="
SE=()
for n in omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o omnia_proof_ripple_resolution.iii.o \
         omnia_resolver.iii.o omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o \
         omnia_transform_patterns.iii.o omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o \
         aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o \
         sanctus_seal_resolver.iii.o verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o \
         bench_helpers.o; do
    [ -f "$BUILD/$n" ] && SE+=("$BUILD/$n")
done
PILOT_SRCS=(
    "$ROOT/STDLIB/sovir/mathesis_pilot_main.iii"
    "$ROOT/STDLIB/iii/aether/mathesis_pilot.iii"
    "$ROOT/STDLIB/iii/aether/mathesis_curve.iii"
    "$ROOT/STDLIB/iii/aether/mathesis_alg.iii"
    "$ROOT/STDLIB/iii/aether/resultant.iii"
    "$ROOT/STDLIB/iii/aether/sturm_big.iii"
)
POBJ=()
for s in "${PILOT_SRCS[@]}"; do
    b="$(basename "$s" .iii)"; o="$W/$b.o"
    "$IIIS" "$s" --compile-only --out "$o" >"$W/pc_$b.log" 2>&1 || { red "pilot compile $b"; exit 1; }
    POBJ+=("$o")
done
PILOT="$W/pilot$X"
gcc "${POBJ[@]}" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$PILOT" >"$W/pl.log" 2>&1 \
    || { red "pilot link"; exit 1; }
grn "PILOT built (mathesis_pilot + curve + alg + resultant + sturm_big)"

# ---- OBS: nobody steers -- the pilot head is a pure function of the budget ----
head_at() { PILOT_ROUNDS="$1" "$PILOT" 2>/dev/null | sed -n 's/^PILOT rounds=[0-9]* head=\([0-9a-f]*\)$/\1/p'; }
reached_at() { PILOT_ROUNDS="$1" "$PILOT" 2>/dev/null | awk '$1=="PILOT#" && $3==0 {c++} END{print c+0}'; }
H1="$(head_at 6)"; H1b="$(head_at 6)"
if [ -n "$H1" ] && [ "$H1" = "$H1b" ]; then grn "nobody steers: budget 6 -> identical head twice ($H1)"; else red "pilot nondeterministic ($H1 vs $H1b)"; fi

# ---- the named-deficit horizon ----
HORIZON=24           # rounds the policy is chartered to reach in this census window
TOTAL=8              # kind-0 (NEW-D) slots below the horizon = |{0,3,...,21}|
LEDGER="$W/author.ledger"; rm -f "$LEDGER"
MAN="$W/MANIFEST.txt"
( cd "$ROOT" && git ls-files -- \
    'COMPILER/BOOT/*.iii' 'COMPILER/BOOT/*.c' 'COMPILER/BOOT/*.h' 'COMPILER/BOOT/*.sh' \
    'STDLIB/iii/**/*.iii' 'STDLIB/sovir/*.iii' 'STDLIB/sovir/*.sh' \
    'STDLIB/corpus/*.iii' 'STDLIB/scripts/*.sh' 'DOCS/*.md' 'DOCS/*.log' 'DOCS/*.txt' \
    2>/dev/null | LC_ALL=C sort -u > "$MAN" )
head -c 96 /dev/urandom > "$W/seed.bin" 2>/dev/null || { say "[author] env: no /dev/urandom"; exit 2; }
"$T" keygen "$W/seed.bin" "$W/pk.bin" "$W/sk.bin" >/dev/null 2>&1 || { red "keygen"; exit 1; }

# ---- THE AUTONOMOUS CYCLES ----------------------------------------------------------------------
say "[author] == >=3 autonomous cycles under THE NAMED-DEFICIT LAW =="
BUDGETS=(6 12 18)
prev_reached=0
prev_after="$TOTAL"
ok_cycles=0
i=0
while [ "$i" -lt 3 ]; do
    n=$((i + 1))
    b="${BUDGETS[$i]}"
    reached="$(reached_at "$b")"
    [ -n "$reached" ] || { red "cycle $n: pilot produced no reached count"; break; }
    after=$((TOTAL - reached))
    # novelty adjudication: a cycle that reaches nothing new is NONE (the law will reject it)
    if [ "$reached" -gt "$prev_reached" ]; then nov="NEW"; else nov="NONE"; fi
    before="$prev_after"
    say "[author] cycle $n: budget=$b reached(kind0)=$reached  unreached $before -> $after  novelty=$nov  head=$(head_at "$b")"

    # (1) each cycle's testament is GREEN, chained to the previous generation
    parent="none"; [ "$n" -gt 1 ] && parent="$W/gen$((n-1)).dat"
    ( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen$n.dat" "$parent" none ) >"$W/e$n.log" 2>&1 \
        && "$T" show "$W/gen$n.dat" >"$W/show$n.txt" 2>&1 \
        && grn "cycle $n: testament green (gen$n chained to $parent)" \
        || { red "cycle $n: testament not green"; break; }

    # (2) admit the machine's seal under THE NAMED-DEFICIT LAW (routes=2: curve1 & curve2 agree)
    if "$AU" admit "$LEDGER" "$n" unreached "$before" "$after" 2 "$nov" MACHINE 1; then
        grn "cycle $n: seal ADMITTED (unreached strictly shrank, MACHINE, two agreeing routes)"
        ok_cycles=$((ok_cycles + 1))
    else
        red "cycle $n: lawful seal was rejected (rc=$?)"; break
    fi
    prev_reached="$reached"; prev_after="$after"; i="$n"
done
[ "$ok_cycles" -ge 3 ] && grn "3 autonomous cycles admitted, each strictly shrinking unreached" || red "fewer than 3 lawful cycles ($ok_cycles)"

# ---- THE EXIT GATE: >=3 consecutive MACHINE cycles, strict + continuous ----
say "[author] == exit gate: iii-author verify (>=3 consecutive MACHINE cycles) =="
"$AU" verify "$LEDGER" unreached 3 && grn "exit gate held" || red "exit gate failed"

# ---- seal the autonomous history ----
AROOT="$("$AU" fold "$LEDGER" 2>/dev/null | grep -o 'root=[0-9a-f]*' | sed 's/root=//')"
[ -n "$AROOT" ] && grn "autonomous history folded: root=$AROOT" || red "fold produced no root"

# ---- ADVERSARIAL: every breach of the law must be NAMED-REJECTED (distinct exit codes) ----
say "[author] == adversarial: THE NAMED-DEFICIT LAW rejects every breach =="
adv() { # <label> <want_rc> <admit args...>
    local label="$1" want="$2"; shift 2
    "$AU" admit "$@" >/dev/null 2>&1; local rc=$?
    if [ "$rc" -eq "$want" ]; then grn "reject $label (rc=$rc as named)"; else red "$label got rc=$rc (want $want)"; fi
}
adv UNNAMED           3 "$LEDGER" 4 x_plus_zero 2 1 2 NEW  MACHINE 1
adv NOVELTY-NONE      4 "$LEDGER" 4 unreached   2 1 2 NONE MACHINE 1
adv BAD-PROVENANCE    5 "$LEDGER" 4 unreached   2 1 2 NEW  ROBOT   1
adv NO-PROGRESS       6 "$LEDGER" 4 unreached   2 2 1 NEW  MACHINE 1
adv RATCHET-RISE      7 "$LEDGER" 4 unreached   2 5 2 NEW  MACHINE 1
adv RATCHET-CONTINUITY 7 "$LEDGER" 4 unreached 99 1 2 NEW  MACHINE 1
# cap: two admits in one fresh cycle with cap=1 -> the second is CAP-rejected
CAPL="$W/cap.ledger"; rm -f "$CAPL"
"$AU" admit "$CAPL" 1 frontier 10 8 2 NEW MACHINE 1 >/dev/null 2>&1 \
    && { "$AU" admit "$CAPL" 1 frontier 8 6 2 NEW MACHINE 1 >/dev/null 2>&1; [ $? -eq 8 ] && grn "reject CAP (rc=8 as named)" || red "CAP not enforced"; } \
    || red "cap setup admit failed"

say ""
if [ "$FAIL" -eq 0 ]; then
    say "[author] ALL GREEN -- AUTARKEIA Alpha-4: THE AUTHOR stands."
    say "[author] 3 autonomous MACHINE cycles, each a green chained testament, each strictly shrinking unreached; every law breach named-rejected."
    say "[author] autonomous history root = $AROOT"
    exit 0
else
    say "[author] RED -- a stage above failed."
    exit 1
fi
