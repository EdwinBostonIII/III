#!/usr/bin/env bash
# run_membrane_gates.sh -- the AGGREGATE for the autopoietic-membrane proof gates (2026-07-04).
#
# WHY THIS EXISTS: run_legA / run_ghost / run_residue_gate were each standalone, driven by NO
# aggregate -- so nothing re-ran them when an organ changed, and run_legA's unit-KAT sources rotted
# invisibly (swept from a build dir; reconstructed 2026-07-04).  A gate nobody runs rots.  This
# driver runs all three under real rc capture so ANY one going red reddens ONE sweep.  Each child
# carries its own teeth; this only composes their verdicts.
#
#   run_legA.sh          -- 26 Leg-A unit gates (SVIR<->SVIR prover, aliasing oracle, ETAT B0/B2
#                           memory, control-as-mux, loop-crush family through the geometric and
#                           quadratic rungs + the symbolic-freedom soundness gate, Merkle TCB,
#                           fold, netlist)
#   run_ghost.sh         -- the ghost-build over REAL ccsv output (affine CRUSHED(add d5),
#                           geometric CRUSHED(mul r2), triangular CRUSHED(qad q1), chaotic
#                           deferred as residue, report fingerprinted)
#   run_residue_gate.sh  -- the residue-stability RATCHET (toy corpus report hash vs sealed golden)
#   run_residue_real.sh  -- the REAL-SEED residue ratchet (ccsv(sha256.c): the at-scale crush/defer map;
#                           at introduction 4/4 loops are memory-fragment residue -- the honest boundary)
#
# A SOURCE-TRACKING TEETH is asserted first: every run_legA KAT source must be git-tracked, so the
# "swept from a build dir" failure mode cannot recur silently -- if a gate source is untracked, this
# reddens BEFORE running anything.
#
# exit 0 iff the tracking teeth holds AND all three child gates are green.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
S="$ROOT/STDLIB/sovir"
fail=0
say(){ echo "[membrane] $*"; }

# --- SOURCE-TRACKING TEETH: the lesson that created this file, enforced. ---
KATS_DIR="$S/kats"
if [ -d "$KATS_DIR" ]; then
    untracked="$(cd "$ROOT" && git ls-files --others --exclude-standard -- "STDLIB/sovir/kats/*.iii" 2>/dev/null)"
    if [ -n "$untracked" ]; then
        say "FAIL: Leg-A KAT source(s) UNTRACKED -- would rot on a git clean:"
        printf '%s\n' "$untracked" | sed 's/^/[membrane]   /'
        fail=1
    else
        n="$(ls "$KATS_DIR"/*.iii 2>/dev/null | wc -l)"
        say "tracking teeth: all $n Leg-A KAT sources are git-tracked"
    fi
else
    say "FAIL: $KATS_DIR missing"; fail=1
fi

runchild(){  # $1 = script basename
    local g="$1"
    say "--- $g ---"
    if bash "$S/$g" >/dev/null 2>&1; then
        say "$g : GREEN"
    else
        say "$g : RED (rc=$?)"
        fail=1
    fi
}

runchild run_legA.sh
runchild run_ghost.sh
runchild run_residue_gate.sh
runchild run_residue_real.sh

echo "============================================================"
if [ "$fail" -eq 0 ]; then
    say "ALL MEMBRANE GATES GREEN -- Leg A (26) + ghost-build + toy ratchet + real-seed ratchet, sources tracked."
    exit 0
fi
say "MEMBRANE GATES: RED"
exit 1
