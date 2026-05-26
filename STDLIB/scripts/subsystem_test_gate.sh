#!/usr/bin/env bash
# subsystem_test_gate.sh — V1->V2 transition gate (forward-reference #28).
#
# Exits 0 iff: every .iii corpus passes (run_all_corpora.sh) AND every
# subsystem test exe (<DIR>/build/iii_*_test.exe) exits 0. With --build it
# first runs the deterministic stdlib build and requires FAIL = 0.
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

# 1. .iii corpora (stdlib correctness + bench correctness + stage1) via the
#    canonical driver. Exit code is the count of failed tests (0 = all pass).
echo "[gate] run_all_corpora.sh ..."
if [ "$QUIET" -eq 1 ]; then
    bash "$ROOT/run_all_corpora.sh" --quiet >/dev/null 2>&1
else
    bash "$ROOT/run_all_corpora.sh" --quiet
fi
corpora_rc=$?
if [ "$corpora_rc" -ne 0 ]; then
    echo "[gate] FAIL: .iii corpora reported $corpora_rc failed test(s)"
    FAILED="$FAILED iii-corpora($corpora_rc)"
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
done < <(find . -name 'iii_*_test.exe' -type f 2>/dev/null | LC_ALL=C sort)
echo "[gate] subsystem exes: $((ss_total - ss_fail))/$ss_total passed"

# 3. Sovereign Forge closure meta-gate (SOVEREIGN_FORGE.md §2). TRUE function:
#    forge_check.sh recomputes every K1-K6 full-spec seal + the descent sub-closure
#    root and greps them in DOCS/SOVEREIGN-LEDGER.md, asserts no orphan generator,
#    and re-runs every per-citizen drift gate. A stale/inconsistent manifest fails.
echo "[gate] forge_check.sh (Sovereign Forge closure) ..."
if ! bash "$ROOT/COMPILER/BOOT/forge_check.sh" >/dev/null 2>&1; then
    echo "[gate] FAIL: Forge closure meta-gate -- DOCS/SOVEREIGN-LEDGER.md not self-consistent"
    FAILED="$FAILED forge-closure"
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
