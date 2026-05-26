#!/usr/bin/env bash
# seal_sources.sh — Regenerate STDLIB/build/SOURCES.mhash and CLOSURE.mhash.
#
# Walks every .iii file under STDLIB/iii/ in canonical sort order
# (LC_ALL=C sort -V), computes its SHA-256, and emits a deterministic
# manifest with paths normalized to `iii/<namespace>/<module>.iii`
# (no STDLIB/ prefix; matches the pre-existing 46-line format used by
# the substrate before this convergence step).
#
# CLOSURE.mhash is then SHA-256(SOURCES.mhash file content), written
# with path `build/SOURCES.mhash`.
#
# Authored during RITCHIE Convergence Plan Stage 0.3.  The existing
# SOURCES.mhash was hand-rolled at substrate-creation time and covered
# only 46 modules; the live `.iii` tree has grown to 246 modules.  No
# pre-existing generator script was present (verified by grep -rln
# 'SOURCES.mhash' under STDLIB/scripts/).
#
# NIH discipline (Contract C2 of the RITCHIE plan):
#   Tools used: sha256sum, find, sort, awk, printf, mv, mkdir, wc.
#   All coreutils.  No third-party.  No external dependency.
#
# Determinism discipline (Contract C3):
#   LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1 umask 022.
#   sort -V (deterministic version-aware).  Atomic writes via .tmp + mv.
#
# Usage:
#   bash STDLIB/scripts/seal_sources.sh              # regenerate
#   bash STDLIB/scripts/seal_sources.sh --verify     # twin-build determinism check
#   bash STDLIB/scripts/seal_sources.sh --help       # show this banner

set -euo pipefail
IFS=$'\n\t'
umask 022

export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$STDLIB_DIR/iii"
BUILD_DIR="$STDLIB_DIR/build"

DO_VERIFY=0

usage() {
    sed -n '1,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verify) DO_VERIFY=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *)
            printf 'seal_sources: unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$SRC_DIR" ]]; then
    printf 'seal_sources: SRC_DIR not found: %s\n' "$SRC_DIR" >&2
    exit 2
fi

mkdir -p "$BUILD_DIR"

SOURCES_OUT="$BUILD_DIR/SOURCES.mhash"
CLOSURE_OUT="$BUILD_DIR/CLOSURE.mhash"
TMP_SUFFIX="$$.$(date -u +%s%N 2>/dev/null || echo 0).tmp"
TMP_SOURCES="$BUILD_DIR/.SOURCES.mhash.$TMP_SUFFIX"
TMP_CLOSURE="$BUILD_DIR/.CLOSURE.mhash.$TMP_SUFFIX"

cleanup() {
    rm -f -- "$TMP_SOURCES" "$TMP_CLOSURE"
}
trap cleanup EXIT

# Pass 1: walk every iii/**/*.iii in canonical order, hash each, emit manifest.
# The cd to STDLIB_DIR is critical: paths in the manifest are recorded as
# `iii/<ns>/<mod>.iii` without a STDLIB/ prefix, matching the historical
# 46-line format.
(
    cd "$STDLIB_DIR"
    find iii -type f -name '*.iii' | LC_ALL=C sort -V | while IFS= read -r path; do
        if [[ ! -f "$path" ]]; then
            printf 'seal_sources: file vanished during walk: %s\n' "$path" >&2
            exit 3
        fi
        # sha256sum -b emits "<hash> *<path>\n" (binary-mode marker).
        sha256sum -b "$path"
    done
) > "$TMP_SOURCES"

# Atomic publish.
mv -- "$TMP_SOURCES" "$SOURCES_OUT"

# Pass 2: closure root = sha256 of SOURCES.mhash content.
# Path stored as `build/SOURCES.mhash` (no STDLIB/ prefix).
(
    cd "$STDLIB_DIR"
    sha256sum -b "build/SOURCES.mhash"
) > "$TMP_CLOSURE"

mv -- "$TMP_CLOSURE" "$CLOSURE_OUT"

trap - EXIT
cleanup

SOURCES_HASH=$(sha256sum -b "$SOURCES_OUT" | awk '{print $1}')
CLOSURE_LINE=$(cat "$CLOSURE_OUT")
SOURCES_LINES=$(wc -l < "$SOURCES_OUT")

printf '[seal_sources] SOURCES.mhash = %s\n' "$SOURCES_HASH"
printf '[seal_sources] CLOSURE = %s\n' "$CLOSURE_LINE"
printf '[seal_sources] modules sealed: %s\n' "$SOURCES_LINES"

# Optional determinism verification (Contract C3 NO-DRIFT-VERIFY analogue).
if [[ "$DO_VERIFY" -eq 1 ]]; then
    VERIFY_TMP_SOURCES="$BUILD_DIR/.SOURCES.mhash.verify.$$.tmp"
    VERIFY_TMP_CLOSURE="$BUILD_DIR/.CLOSURE.mhash.verify.$$.tmp"

    verify_cleanup() {
        rm -f -- "$VERIFY_TMP_SOURCES" "$VERIFY_TMP_CLOSURE"
    }
    trap verify_cleanup EXIT

    (
        cd "$STDLIB_DIR"
        find iii -type f -name '*.iii' | LC_ALL=C sort -V | while IFS= read -r path; do
            sha256sum -b "$path"
        done
    ) > "$VERIFY_TMP_SOURCES"

    (
        cd "$STDLIB_DIR"
        # Use the just-rebuilt verify file to compute its closure (not the
        # SOURCES_OUT, which is already published — the verify is independent).
        # Trick: temporarily expose VERIFY_TMP_SOURCES under build/SOURCES.mhash.verify
        # so sha256sum's recorded path matches the format.
        cp -- "$VERIFY_TMP_SOURCES" "build/SOURCES.mhash.verify.$$"
        sha256sum -b "build/SOURCES.mhash.verify.$$" | \
            sed 's| \*build/SOURCES.mhash.verify\.[0-9]*| *build/SOURCES.mhash|'
        rm -f -- "build/SOURCES.mhash.verify.$$"
    ) > "$VERIFY_TMP_CLOSURE"

    if ! cmp -s -- "$SOURCES_OUT" "$VERIFY_TMP_SOURCES"; then
        printf '[seal_sources] FAIL: SOURCES.mhash twin-build DIVERGED — nondeterminism in source set\n' >&2
        diff -u "$SOURCES_OUT" "$VERIFY_TMP_SOURCES" >&2 || true
        exit 6
    fi
    if ! cmp -s -- "$CLOSURE_OUT" "$VERIFY_TMP_CLOSURE"; then
        printf '[seal_sources] FAIL: CLOSURE.mhash twin-build DIVERGED\n' >&2
        diff -u "$CLOSURE_OUT" "$VERIFY_TMP_CLOSURE" >&2 || true
        exit 6
    fi

    verify_cleanup
    trap - EXIT

    printf '[seal_sources] --verify: BIT-IDENTICAL (twin-build determinism)\n'
fi
