#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_prove.sh
#
# Build iii-prove: THE EQUIVALENCE PROVER AS A STANDING TOOL.
#
#     iii-prove <a.iii> <fnA> <b.iii> <fnB>    prove fnA == fnB over ALL 2^64 inputs
#     iii-prove --list <file.iii>              list a file's provable functions
#
# This makes III's disposer (numera/ser_kinduct_sym seq_equiv, over numera/bv_bits + numera/sat)
# independently useful on ARBITRARY user programs.  The tool links the compiler's own front end
# (lex/ast/parse) and its own SVIR backend (cg_svir) IN-PROCESS, so a user needs no build script,
# no driver, and no harness of their own: they point it at their source and get a verdict --
# PROVEN over every input, REFUTED with a concrete counterexample, or an honest UNDECIDED with the
# reason named.
#
# A LEAF tool build, exactly like build_iii_eval.sh: it uses the PINNED in-tree production compiler
# (COMPILED/iiis-2) and the committed stdlib archive.  The bootstrap chain (iiis-0..3), its objects,
# and its seals are never touched.
#
# Usage: bash build_iii_prove.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022

export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

LOG_TAG="[iii-prove build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-prove${BIN_SUFFIX}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out) OUT_BIN="$2"; shift 2 ;;
        *)     die 2 "unknown arg: $1" ;;
    esac
done

IIIS="$OUT_DIR/iiis-2${BIN_SUFFIX}"
[[ -x "$IIIS" ]] || die 2 "pinned compiler not found: $IIIS"

CC="${CC:-gcc}"
command -v "$CC" >/dev/null 2>&1 || die 2 "linker not found: $CC"

STDLIB_LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -f "$STDLIB_LIB" ]] || die 2 "stdlib archive not found: $STDLIB_LIB"

# The prover's TU closure: the compiler's FRONT half + its SVIR backend + the driver.
# cg_svir const-folds array/const initialisers through the definitional evaluator
# (iii_ev_const_value / iii_ev_elem_value), so eval.iii is part of the SVIR backend's closure --
# the same TU the meaning-lift uses; no second const-folder exists to drift.
# The disposer itself (ser_kinduct_sym, bv_bits, sat) comes from the stdlib archive.
# NOTHING from sema/sid/cg_r*/emit/link -- the same independence boundary the evaluator keeps.
TUS=( cg_sha lex_rt lex ast parse eval cg_svir prove_main )

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-prove-build.XXXXXX")"
trap '[[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true' EXIT
mkdir -p "$TMP_ROOT/obj" "$OUT_DIR"

OBJS=()
for tu in "${TUS[@]}"; do
    src="$BOOT_DIR/${tu}.iii"
    obj="$TMP_ROOT/obj/${tu}.iii.o"
    [[ -f "$src" ]] || die 3 "missing source: $src"
    OBJS+=("$obj")
    log "iiis-2 ${tu}.iii -> ${tu}.iii.o"
    ( cd "$BOOT_DIR" && "$IIIS" "${tu}.iii" --compile-only --out "$obj" ) \
        || die 3 "iii compile failed: $src"
done

# OneDrive/Defender transient-lock hardening: fresh inode + retry (the build_iii_eval discipline).
log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "${OBJS[@]}" "$STDLIB_LIB" -lws2_32 -lkernel32; then
        rc=0
    else
        rc=$?
    fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
