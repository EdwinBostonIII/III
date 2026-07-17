#!/usr/bin/env bash
# subsystem_test_gate.sh — V1->V2 transition gate (forward-reference #28).
#
# Exits 0 iff: the canonical corpus passes (run_corpus.sh), the standing fleet
# re-derives its laws (iii-ergon census -- the ERGON work-proof, 2026-07-17;
# the retired one-sweep run_all_corpora is superseded), AND every subsystem
# test exe (<DIR>/build/iii_*_test.exe) exits 0. With --build it first runs
# the deterministic stdlib build and requires FAIL = 0.
#
# Non-zero exit lists the failing gate(s). The pass/fail is TRUE function:
# every exe is actually executed and its exit code checked; nothing is
# asserted from file existence. See DOCS/SUBSYSTEM_TEST_GATE_SPECIFICATION.md.
#
# Usage:
#   bash STDLIB/scripts/subsystem_test_gate.sh            # corpora + subsystem exes
#   bash STDLIB/scripts/subsystem_test_gate.sh --build    # + deterministic stdlib build first
#   bash STDLIB/scripts/subsystem_test_gate.sh --quiet    # summary only

set -u
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT" || { echo "[gate] cannot cd to repo root" >&2; exit 2; }

DO_BUILD=0
QUIET=0
for a in "$@"; do
    case "$a" in
        --build) DO_BUILD=1 ;;
        --quiet) QUIET=1 ;;
        -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "[gate] unknown arg: $a" >&2; exit 2 ;;
    esac
done

FAILED=""

# 0. Optional: deterministic stdlib build, require FAIL = 0.
if [ "$DO_BUILD" -eq 1 ]; then
    echo "[gate] stdlib build (IIIS=COMPILED/iiis-2.exe) ..."
    bl="$(IIIS="$ROOT/COMPILED/iiis-2.exe" bash "$ROOT/STDLIB/scripts/build_stdlib.sh" 2>&1)"
    if ! printf '%s\n' "$bl" | grep -q 'FAIL = 0'; then
        echo "[gate] FAIL: stdlib build did not report 'FAIL = 0'"
        FAILED="$FAILED stdlib-build"
    fi
fi

# 1. .iii corpus via the canonical driver (2026-07-17, ERGON constitution: the one-sweep
#    run_all_corpora was retired with the batch family runners; run_corpus.sh is the one
#    canonical driver -- its dispatch heart-adopts the retired families).
echo "[gate] run_corpus.sh ..."
if [ "$QUIET" -eq 1 ]; then
    bash "$ROOT/STDLIB/scripts/run_corpus.sh" >/dev/null 2>&1
else
    bash "$ROOT/STDLIB/scripts/run_corpus.sh"
fi
corpora_rc=$?
if [ "$corpora_rc" -eq 126 ] || [ "$corpora_rc" -eq 127 ]; then
    echo "[gate] FAIL: .iii corpus driver did not run (spawn rc=$corpora_rc) -- a harness fault, not a test count"
    FAILED="$FAILED iii-corpora-spawn($corpora_rc)"
elif [ "$corpora_rc" -ne 0 ]; then
    echo "[gate] FAIL: .iii corpus red (driver rc=$corpora_rc)"
    FAILED="$FAILED iii-corpora($corpora_rc)"
fi

# 1b. THE WORK-PROOF (2026-07-17): the standing fleet re-derives its laws in one process --
#     introspection roster + kardia + soma + doxa + absorbed families (iii-ergon census; no
#     stored expectation consulted).  Soft dependency like 3b: skipped on a checkout without
#     the built tool, so the SHA-gated levels above still judge.
if [ -x "$ROOT/COMPILED/iii-ergon.exe" ]; then
    echo "[gate] iii-ergon census (standing-fleet work-proof) ..."
    if ! "$ROOT/COMPILED/iii-ergon.exe" census >/dev/null 2>&1; then
        echo "[gate] FAIL: ERGON census -- a standing organ did not derive its law"
        FAILED="$FAILED ergon-census"
    fi
fi

# 2. Subsystem test exes: actually run each and check exit code.
echo "[gate] subsystem test exes ..."
ss_total=0
ss_fail=0
while IFS= read -r exe; do
    [ -x "$exe" ] || continue
    ss_total=$((ss_total + 1))
    name="$(basename "$exe")"
    if ! "$exe" >/dev/null 2>&1; then
        rc=$?
        echo "[gate] FAIL: $name (exit $rc)"
        ss_fail=$((ss_fail + 1))
        FAILED="$FAILED $name"
    fi
done < <(find . -name 'iii_*_test.exe' -type f -not -path '*/.claude/*' 2>/dev/null | LC_ALL=C sort)
# NOTE: skip .claude worktrees -- they hold STALE orphan copies of every subsystem exe (built at the
# worktree's past commit); running them validates the gate against dead binaries and 5x-inflates the
# process-spawn load (30 exes -> 6), which under the post-1GB-witness-corpus commit pressure was the
# documented source of a transient iii_lex_test teardown segfault (the binary passes 77/77 + 40/40 in
# isolation). Mirrors the carto-gate .claude skip.
if [ "$ss_total" -eq 0 ]; then
    # HONEST EMPTINESS (2026-07-04): the R1 C subsystem provinces (TYPES/HEXAD/LEXICON/...) were
    # AMPUTATED in the C->.iii port era -- their directories no longer exist, so zero exes is the
    # tree's truth, not missing coverage; the .iii corpora above are the successors.  The find
    # still judges any exe that reappears (drift would be executed and checked, never vacuous).
    echo "[gate] subsystem exes: 0 present (R1 C provinces amputated; .iii corpora are the successors)"
else
    echo "[gate] subsystem exes: $((ss_total - ss_fail))/$ss_total passed"
fi

# 3. Sovereign Forge closure meta-gate (SOVEREIGN_FORGE.md §2). TRUE function:
#    forge_check.sh recomputes every K1-K6 full-spec seal + the descent sub-closure
#    root and greps them in DOCS/SOVEREIGN-LEDGER.md, asserts no orphan generator,
#    and re-runs every per-citizen drift gate. A stale/inconsistent manifest fails.
echo "[gate] forge_check.sh (Sovereign Forge closure) ..."
if ! bash "$ROOT/COMPILER/BOOT/forge_check.sh" >/dev/null 2>&1; then
    echo "[gate] FAIL: Forge closure meta-gate -- DOCS/SOVEREIGN-LEDGER.md not self-consistent"
    FAILED="$FAILED forge-closure"
fi

# 3b. W5.2 (RIPPLE-11 level D): the manifest Keccak-256 closure root -- the THIRD level,
#     recomputed over the SAME sorted citizen seals via the in-tree numera/keccak.iii.  Editing
#     any forge citizen now reddens ALL THREE levels in one pass (the half-sealed-manifest
#     hazard is structurally impossible).  Soft dependency: skipped (not failed) if the tool or
#     the freshly-built lib is unavailable, so a clean checkout still gates the SHA-256 levels.
if [ -f "$ROOT/COMPILER/BOOT/forge_manifest_keccak.sh" ] && [ -f "$ROOT/STDLIB/build/iii/libiii_native.a" ]; then
    echo "[gate] forge_manifest_keccak.sh (manifest Keccak-256 closure level D) ..."
    if ! bash "$ROOT/COMPILER/BOOT/forge_manifest_keccak.sh" >/dev/null 2>&1; then
        echo "[gate] FAIL: manifest Keccak closure level -- recomputed root not recorded in DOCS/SOVEREIGN-LEDGER.md"
        FAILED="$FAILED forge-keccak-manifest"
    fi
fi

# 4. AUTHOR-DIVERSITY (2026-07-04): every joint where independently-authored implementations
#    can witness the same bytes, enforced -- compiler lineages (gcc vs MSVC seeds), the hash
#    witness triangle (III/cad + GNU + Microsoft) on every sealed anchor + committed golden,
#    consumer witnesses (binutils parse, OS-loader execute), NIST vectors on the hasher.
#    Soft dependency like 3b: skipped on a checkout without the built toolchain.
if [ -f "$ROOT/STDLIB/scripts/author_diversity_gate.sh" ] && [ -f "$ROOT/STDLIB/build/iii/libiii_native.a" ]; then
    echo "[gate] author_diversity_gate.sh (independent-authorship witnesses) ..."
    if ! bash "$ROOT/STDLIB/scripts/author_diversity_gate.sh" >/dev/null 2>&1; then
        echo "[gate] FAIL: author-diversity gate -- an independent-authorship joint disagrees"
        FAILED="$FAILED author-diversity"
    fi
fi

# 5. AUTOPOIETIC MEMBRANE (2026-07-04): the Leg-A proof gates (SVIR<->SVIR equivalence prover,
#    aliasing oracle, ETAT B0/B2 memory, control-as-mux, loop-crush family, Merkle TCB, netlist)
#    + ghost-build over real ccsv + residue ratchet, WITH the source-tracking teeth.  This closes
#    the "gate nobody runs" recursion: run_membrane_gates protects Leg-A; the belt (the tree's
#    top-level advance gate) protects run_membrane_gates.  Soft dependency like the legs above.
if [ -f "$ROOT/STDLIB/sovir/run_membrane_gates.sh" ] && [ -f "$ROOT/STDLIB/build/iii/libiii_native.a" ]; then
    echo "[gate] run_membrane_gates.sh (autopoietic Leg-A membrane) ..."
    if ! bash "$ROOT/STDLIB/sovir/run_membrane_gates.sh" >/dev/null 2>&1; then
        echo "[gate] FAIL: membrane gates -- a Leg-A proof gate is red or a KAT source is untracked"
        FAILED="$FAILED membrane"
    fi
fi

echo "============================================================"
if [ -n "$FAILED" ]; then
    echo "[gate] GATE FAILED:$FAILED"
    echo "============================================================"
    exit 1
fi
echo "[gate] GATE PASSED — all .iii corpora + $ss_total subsystem exes green."
echo "============================================================"
exit 0
