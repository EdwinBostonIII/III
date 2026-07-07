#!/usr/bin/env bash
# run_completion.sh -- THE COMPLETION INVARIANT (III-COMPLETION-PLAN Part 3; III-UNIFIED-ARCHITECTURE §9).
#
#   III's unified sovereign stack is COMPLETE when this ONE meta-gate is green and is itself
#   sovereign-built.  It is a PROOF OBLIGATION, not a dashboard: every line is a real exit code,
#   every line has a falsifier that reddens it, and an ABSENT member is a RED (a named gap),
#   never a skip.  No subset switches exist here by design -- a capstone that can be filtered
#   can lie.  (Iterate on the MEMBERS with their own filters; run the capstone whole.)
#
#   Green today requires (in order):
#     floor_closure_gate.sh        I1: the 13-member trust floor imports nothing above msvcrt
#     build_stdlib.sh              Φ4: 719 modules FAIL=0 + coverage/gate/reach ratchets at pins
#                                      + cartographer I2 + the emit symbol-consistency gate
#     run_grand_unification.sh     Ω:  the unified pipeline (a/d+b+F2+e+f+g+Ω7)
#     run_seed_sovereign.sh        Φ1: ccsv builds iiis-0, byte-DDC   [ABSENT 2026-07-07 -- the
#                                      Step-1 long pole; this line is the capstone's honest RED]
#     run_ddc.sh                   Φ2: DDC closed incl. author-diversity lineage
#     run_conscience.sh            Φ3: every banner's gate runs green (50-line sweep)
#     run_zk_audit.sh              Φ6: every zk gadget's claimed bit-count matches its knobs
#     run_evergreen.sh             Φ7: every standalone program self-builds sovereignly, no stubs
#
# Exit 0 = the loop is CLOSED.  1 = at least one arc open (each named).  Logs per member under
# COMPILED/_completion_<name>.log.
set -u
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"

MEMBERS=(
    "floor_closure|bash STDLIB/sovir/floor_closure_gate.sh"
    "build_stdlib|bash STDLIB/scripts/build_stdlib.sh"
    "grand_unification|bash STDLIB/sovir/run_grand_unification.sh"
    "seed_sovereign|bash STDLIB/sovir/run_seed_sovereign.sh"
    "ddc|bash STDLIB/sovir/run_ddc.sh"
    "conscience|bash STDLIB/scripts/run_conscience.sh"
    "zk_audit|bash STDLIB/scripts/run_zk_audit.sh"
    "evergreen|bash STDLIB/scripts/run_evergreen.sh"
)

pass=0; fail=0; declare -a REDS
for row in "${MEMBERS[@]}"; do
    name="${row%%|*}"; cmd="${row#*|}"
    script="$ROOT/$(printf '%s' "$cmd" | awk '{print $2}')"
    if [ ! -f "$script" ]; then
        printf '[completion] RED  %-20s -- gate ABSENT (%s): the arc is OPEN by construction\n' "$name" "${script#$ROOT/}"
        fail=$((fail+1)); REDS+=("$name ABSENT")
        continue
    fi
    t0=$(date +%s)
    ( cd "$ROOT" && bash -c "$cmd" ) > "$ROOT/COMPILED/_completion_${name}.log" 2>&1
    rc=$?
    t1=$(date +%s)
    if [ "$rc" -eq 0 ]; then
        printf '[completion] PASS %-20s rc=0   %5ss\n' "$name" "$((t1-t0))"
        pass=$((pass+1))
    else
        printf '[completion] RED  %-20s rc=%-3s %5ss  (log: COMPILED/_completion_%s.log)\n' "$name" "$rc" "$((t1-t0))" "$name"
        fail=$((fail+1)); REDS+=("$name rc=$rc")
    fi
done

echo "-------------------------------------------------------------"
echo "[completion] arcs green=$pass open=$fail (of ${#MEMBERS[@]})"
if [ "$fail" -eq 0 ]; then
    echo "COMPLETION: GREEN -- the loop is closed; the only trusted things left are the silicon and the libc shim."
    exit 0
fi
printf '[completion] OPEN ARC: %s\n' "${REDS[@]}"
echo "COMPLETION: OPEN -- the stack is not complete until every arc above is green."
exit 1
