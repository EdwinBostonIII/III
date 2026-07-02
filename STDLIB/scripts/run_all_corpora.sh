#!/usr/bin/env bash
# run_all_corpora.sh
#
# Unified driver for every test corpus in the III repo.  Runs each
# corpus in turn and reports an aggregated PASS/FAIL summary.  Exits 0
# iff every corpus passes; otherwise exits with the count of failed
# tests across all corpora (capped at 255 for shell-portable exit codes).
#
# Corpora driven (in order):
#   1. STDLIB/scripts/run_corpus.sh                — 254 stdlib correctness tests
#                                                    (XII 280..372 + perf benchmarks
#                                                     237/242/243/244 are delegated)
#   2. STDLIB/scripts/run_bench_corpus.sh          —   4 perf benchmarks
#                                                    (correctness hard-gated;
#                                                     timing host-relative advisory)
#   3. COMPILER/BOOT/stage1_corpus/run_corpus.sh   —  57 stage-1 language probes
#
# Usage:
#   bash run_all_corpora.sh                  # run all corpora
#   bash run_all_corpora.sh --skip-stdlib    # skip the stdlib corpus
#   bash run_all_corpora.sh --skip-stage1    # skip the stage-1 corpus
#   bash run_all_corpora.sh --quiet          # suppress per-test output; print summary only
#   bash run_all_corpora.sh --help           # show this help
#
# Created during the 2026-05-08 architectural refactor (item 8 of the
# 10-item harmonization sequence).  See NOTES/ARCHITECTURE.md.

set -u
IFS=$'\n\t'

# Reproducibility env (matches build_iiis0.sh / build_stdlib.sh).
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$SCRIPT_DIR"

STDLIB_RUNNER="$III_ROOT/STDLIB/scripts/run_corpus.sh"
BENCH_RUNNER="$III_ROOT/STDLIB/scripts/run_bench_corpus.sh"
STAGE1_RUNNER="$III_ROOT/COMPILER/BOOT/stage1_corpus/run_corpus.sh"

SKIP_STDLIB=0
SKIP_BENCH=0
SKIP_STAGE1=0
QUIET=0

usage() {
    cat <<'EOF' >&2
Usage: bash run_all_corpora.sh [options]

Options:
  --skip-stdlib   Skip STDLIB/scripts/run_corpus.sh.
  --skip-bench    Skip STDLIB/scripts/run_bench_corpus.sh.
  --skip-stage1   Skip COMPILER/BOOT/stage1_corpus/run_corpus.sh.
  --quiet         Suppress per-test output; print summary only.
  -h, --help      Show this help and exit.

Exit code: 0 if every corpus passes; otherwise count of failed tests
(capped at 255 for shell-portable exit codes).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-stdlib)  SKIP_STDLIB=1; shift ;;
        --skip-bench)   SKIP_BENCH=1; shift ;;
        --skip-stage1)  SKIP_STAGE1=1; shift ;;
        --quiet)        QUIET=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              printf 'unknown argument: %s\n' "$1" >&2; usage; exit 1 ;;
    esac
done

run_corpus() {
    local _name="$1"
    local _runner="$2"
    if [[ ! -f "$_runner" ]]; then
        printf '[run_all_corpora] WARN: runner not found: %s — skipping %s\n' "$_runner" "$_name" >&2
        return 0
    fi
    printf '\n============================================================\n'
    printf '  %s\n' "$_name"
    printf '============================================================\n'
    if [[ "$QUIET" -eq 1 ]]; then
        bash "$_runner" >/dev/null 2>&1
    else
        bash "$_runner"
    fi
    return $?
}

TOTAL_FAIL=0

if [[ "$SKIP_STDLIB" -eq 0 ]]; then
    run_corpus "STDLIB Conformance Corpus (254 correctness tests; XII + perf benchmarks delegated)" "$STDLIB_RUNNER"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        TOTAL_FAIL=$((TOTAL_FAIL + rc))
        printf '[run_all_corpora] STDLIB corpus failed (rc=%s)\n' "$rc" >&2
    else
        printf '[run_all_corpora] STDLIB corpus PASS\n' >&2
    fi
else
    printf '[run_all_corpora] STDLIB corpus SKIPPED\n' >&2
fi

# Performance benchmark corpus (237/242/243/244).  Its exit code counts
# ONLY correctness regressions; timing budgets are host-relative
# advisories that never fail the suite (RITCHIE Stage 0.7-FIX).
if [[ "$SKIP_BENCH" -eq 0 ]]; then
    run_corpus "STDLIB Performance Benchmark Corpus (4 benchmarks; timing advisory)" "$BENCH_RUNNER"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        TOTAL_FAIL=$((TOTAL_FAIL + rc))
        printf '[run_all_corpora] Bench corpus CORRECTNESS failure (rc=%s)\n' "$rc" >&2
    else
        printf '[run_all_corpora] Bench corpus PASS (correctness; timing advisories may print)\n' >&2
    fi
else
    printf '[run_all_corpora] Bench corpus SKIPPED\n' >&2
fi

if [[ "$SKIP_STAGE1" -eq 0 ]]; then
    run_corpus "Stage-1 Verification Corpus (57 tests)" "$STAGE1_RUNNER"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        TOTAL_FAIL=$((TOTAL_FAIL + rc))
        printf '[run_all_corpora] Stage-1 corpus failed (rc=%s)\n' "$rc" >&2
    else
        printf '[run_all_corpora] Stage-1 corpus PASS\n' >&2
    fi
else
    printf '[run_all_corpora] Stage-1 corpus SKIPPED\n' >&2
fi

printf '\n============================================================\n'
printf '  Overall: '
if [[ "$TOTAL_FAIL" -eq 0 ]]; then
    printf 'ALL CORPORA PASSED\n'
else
    printf 'TOTAL FAILED TESTS = %s\n' "$TOTAL_FAIL"
fi
printf '============================================================\n'

# Cap at 255 for portable shell exit codes.
if [[ "$TOTAL_FAIL" -gt 255 ]]; then
    TOTAL_FAIL=255
fi
exit "$TOTAL_FAIL"
