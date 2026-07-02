#!/usr/bin/env bash
# run_all_corpora.sh -- THE ONE SWEEP: every corpus and family gate in the III repo, in order,
# with an aggregated PASS/FAIL summary.  Exit 0 iff every runner is green.
#
# Rewritten by the reunification (III-REUNIFICATION-PLAN W2): the 2026-05-08 original chained only
# {stdlib, bench, stage1} and assumed it lived at repo root; the family-runner system (nine delegated
# families) postdates it.  This version lives in STDLIB/scripts/, derives the repo root correctly,
# and chains EVERY runner the corpus architecture names -- a family cited by run_corpus.sh's SKIP
# dispatch but absent from the RUNNERS list below fails the count teeth before anything runs.
#
# Usage:
#   bash STDLIB/scripts/run_all_corpora.sh              # run everything
#   bash STDLIB/scripts/run_all_corpora.sh --quiet      # two-line tails per runner
#   bash STDLIB/scripts/run_all_corpora.sh --skip-core  # skip the (long) core run_corpus.sh sweep
set -u
IFS=$'\n\t'

export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
S="$III_ROOT/STDLIB/scripts"

QUIET=0; SKIP_CORE=0
for a in "$@"; do
    case "$a" in
        --quiet) QUIET=1 ;;
        --skip-core) SKIP_CORE=1 ;;
        -h|--help) sed -n '2,15p' "${BASH_SOURCE[0]}" >&2; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

# THE FAMILY LIST -- one line per runner (order: fast families first, long sweeps last).
RUNNERS=(
    "$S/run_xii_corpus.sh"
    "$S/run_xii_antidrift.sh"
    "$S/run_ui_kats.sh"
    "$S/run_bigcov_kats.sh"
    "$S/run_field_kats.sh"
    "$S/run_sqrtsum_kats.sh"
    "$S/run_aether_lens_kats.sh"
    "$S/run_ripple_kats.sh"
    "$S/run_topo_kats.sh"
    "$S/run_bench_corpus.sh"
    "$S/run_autogenesis_corpus.sh"
    "$S/run_nous_corpus.sh"
    "$III_ROOT/COMPILER/BOOT/stage1_corpus/run_corpus.sh"
)

# COMPLETENESS TEETH: every family runner run_corpus.sh's dispatch cites must appear above,
# so a newly-added family cannot be silently missing from the one sweep.
MISSING=0
for cited in $(grep -o "run_[a-z_]*\.sh" "$S/run_corpus.sh" | sort -u); do
    [[ "$cited" == "run_corpus.sh" ]] && continue
    found=0
    for r in "${RUNNERS[@]}"; do [[ "$(basename "$r")" == "$cited" ]] && found=1; done
    if [[ $found -eq 0 ]]; then
        echo "[all-corpora] MISSING from RUNNERS: $cited (cited by run_corpus.sh dispatch)"
        MISSING=1
    fi
done
[[ $MISSING -ne 0 ]] && exit 4

FAILED=0; RAN=0
run_one() {
    local r="$1"; local name; name="$(basename "$(dirname "$r")")/$(basename "$r")"
    if [[ ! -f "$r" ]]; then echo "[all-corpora] ABSENT runner: $r"; FAILED=$((FAILED+1)); return; fi
    echo "=== [$name] ==="
    local log="/tmp/allcorp_$$_$(basename "$r").log"
    if (cd "$III_ROOT" && bash "$r") >"$log" 2>&1; then
        RAN=$((RAN+1))
        if [[ $QUIET -eq 1 ]]; then tail -2 "$log"; else tail -4 "$log"; fi
    else
        RAN=$((RAN+1)); FAILED=$((FAILED+1))
        echo "[all-corpora] FAIL: $name (tail follows)"
        tail -12 "$log"
    fi
    rm -f "$log"
}

if [[ $SKIP_CORE -eq 0 ]]; then run_one "$S/run_corpus.sh"; fi
for r in "${RUNNERS[@]}"; do run_one "$r"; done

echo "==================================================="
echo "[all-corpora] runners=$RAN failed=$FAILED"
if [[ $FAILED -eq 0 ]]; then exit 0; fi
if [[ $FAILED -gt 255 ]]; then exit 255; fi
exit $FAILED
