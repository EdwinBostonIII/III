#!/usr/bin/env bash
# run_conscience.sh -- Φ3 exit gate (III-COMPLETION-PLAN Part 3 / III-UNIFIED-ARCHITECTURE §9):
#
#   EVERY "CLOSED/PROVEN/GATED" banner in the tree must carry a RUNNABLE realization -- this meta-gate
#   RUNS the full gate set and reports every real exit code.  A DECORATIVE claim (a gate script that
#   exists but is never exercised, or a banner whose gate is missing) cannot survive it.
#
# WHAT IT RUNS (completeness by construction, not by hand-list):
#   1. AUTO-DISCOVERED: every run_*.sh under STDLIB/scripts, STDLIB/sovtc, STDLIB/sovir, COMPILER/BOOT.
#      A newly-added run_*.sh is picked up automatically -- a gate cannot rot unexecuted.  Any discovered
#      gate that must NOT run here needs an EXCLUDE row WITH A REASON below (printed, auditable).
#   2. SPINE GATES (not named run_*): build_stdlib (ratchets + cartographer), build_iiis2 --check-corpus
#      (stage-1 equivalence + rm2 + cg_r0), the emitter/seed/census/floor gates.
#
# DISCIPLINE: sequential (parallel corpus runs starve commits on this box -- EAGAIN/exit-126 class).
# Each gate gets a generous timeout; a timeout IS a failure (a gate that cannot finish is not a gate).
#
# CONSCIENCE_FILTER=<ERE> runs the matching subset (iteration aid).  The Φ3 CLAIM is only the FULL run.
# FALSIFIER: delete/break any listed gate, or add a run_*.sh that fails -> this meta-gate reddens.
#
# Exit 0 = every gate green.  1 = at least one red (each named).  2 = enumeration/spec violation.
set -u
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
FILTER="${CONSCIENCE_FILTER:-.}"

# ---- gates that are discovered but must not run inside this sweep: name|reason ----
EXCLUDES=(
    "run_conscience.sh|self (this meta-gate)"
    "run_completion.sh|the RETIRED capstone parent (2026-07-17, ERGON constitution): entry kept so a resurrected copy never recurses"
    "run_residue_hunt.sh|exploratory hunter (unbounded search), not a pass/fail gate; its findings land as run_residue_gate"
)
excluded_reason() { local b="$1"; local e; for e in "${EXCLUDES[@]}"; do [ "${e%%|*}" = "$b" ] && { echo "${e#*|}"; return 0; }; done; return 1; }

# ---- the spine gates (command lines, run from ROOT) ----
SPINE=(
    "build_stdlib|bash STDLIB/scripts/build_stdlib.sh"
    "emit_symbol_consistency_gate|bash STDLIB/scripts/emit_symbol_consistency_gate.sh"
    "build_iiis2_check_corpus|bash COMPILER/BOOT/build_iiis2.sh --check-corpus"
    "floor_closure_gate|bash STDLIB/sovir/floor_closure_gate.sh"
    "emit_sovereign_gate|bash COMPILER/BOOT/emit_sovereign_gate.sh"
    "seed_text_identity_gate|bash COMPILER/BOOT/seed_text_identity_gate.sh"
    "basal_census_gate|bash COMPILER/BOOT/basal_census_gate.sh"
    "witness_zero_gate|bash STDLIB/sovtc/witness_zero_gate.sh"
    "inproc_emit_gate|bash STDLIB/sovtc/inproc_emit_gate.sh"
)

TIMEOUT_S="${CONSCIENCE_TIMEOUT_S:-7200}"

declare -a NAMES CMDS
# spine first (build_stdlib early: later gates read its artifacts)
for row in "${SPINE[@]}"; do NAMES+=("${row%%|*}"); CMDS+=("${row#*|}"); done
# auto-discovered run_* gates
for d in STDLIB/scripts STDLIB/sovtc STDLIB/sovir COMPILER/BOOT; do
    for f in "$ROOT/$d"/run_*.sh; do
        [ -f "$f" ] || continue
        b="$(basename "$f")"
        if r="$(excluded_reason "$b")"; then
            printf '[conscience] EXCLUDED %-28s -- %s\n' "$b" "$r"
            continue
        fi
        NAMES+=("${b%.sh}")
        CMDS+=("bash $d/$b")
    done
done

pass=0; fail=0; ran=0; declare -a REDS
total=${#NAMES[@]}
echo "[conscience] gate set: $total lines (spine ${#SPINE[@]} + discovered $((total - ${#SPINE[@]}))); filter='$FILTER'"
i=0
while [ "$i" -lt "$total" ]; do
    name="${NAMES[$i]}"; cmd="${CMDS[$i]}"; i=$((i+1))
    if ! printf '%s' "$name" | grep -qE "$FILTER"; then continue; fi
    ran=$((ran+1))
    t0=$(date +%s)
    ( cd "$ROOT" && timeout "$TIMEOUT_S" bash -c "$cmd" ) > "$ROOT/COMPILED/_conscience_${name}.log" 2>&1
    rc=$?
    t1=$(date +%s)
    if [ "$rc" -eq 0 ]; then
        printf '[conscience] PASS %-34s rc=0   %4ss\n' "$name" "$((t1-t0))"
        pass=$((pass+1))
    else
        printf '[conscience] FAIL %-34s rc=%-3s %4ss  (log: COMPILED/_conscience_%s.log)\n' "$name" "$rc" "$((t1-t0))" "$name"
        fail=$((fail+1)); REDS+=("$name rc=$rc")
    fi
done

echo "-------------------------------------------------------------"
echo "[conscience] ran=$ran pass=$pass fail=$fail (of $total enumerated)"
if [ "$fail" -gt 0 ]; then
    printf '[conscience] RED: %s\n' "${REDS[@]}"
    echo "CONSCIENCE: FAIL -- a banner's gate is red; the claim above it is DECORATIVE until fixed."
    exit 1
fi
if [ "$ran" -lt "$total" ]; then
    echo "CONSCIENCE: PARTIAL (filter subset green -- the Φ3 claim requires the unfiltered run)"
    exit 0
fi
echo "CONSCIENCE: PASS -- every enumerated gate is runnable and green."
exit 0
