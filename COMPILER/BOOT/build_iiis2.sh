#!/usr/bin/env bash
# C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\build_iiis1.sh
#
# Build iiis-2: the first mixed (C + .iii) Stage-0 compiler.
#
# Per the b-stage1-build plan-row: iiis-2 = (all C TUs except those that
# have been ported to .iii) + (their .iii.o counterparts produced by
# iiis-0).  Each successful TU port replaces one .c in this build.
#
# Currently ported:
#   - ceiling.iii   (replaces ceiling.c)
#
# Reproducibility env mirrors build_iiis0.sh exactly (SOURCE_DATE_EPOCH,
# locale, ccache).  iiis-0 is invoked with no env tweaks: its determinism
# is its own contract (verified by build_iiis0.sh --check-deterministic).
#
# Usage:
#   bash build_iiis1.sh [--mode release|debug] [--out <path>]
#                       [--check-corpus] [--clean] [--help]
#
# Exit codes mirror build_iiis0.sh.

set -euo pipefail
IFS=$'\n\t'
umask 022

export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

III_EXIT_OK=0
III_EXIT_USAGE=1
III_EXIT_ENV=2
III_EXIT_COMPILE=3
III_EXIT_LINK=4
III_EXIT_VERIFY=5
III_EXIT_IO=7

LOG_TAG="[iiis-2 build]"

log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
phase(){ printf '%s [PHASE] %s  t=%ss\n' "$LOG_TAG" "$1" "$SECONDS" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

MODE="release"
OUT_BIN="$OUT_DIR/iiis-2${BIN_SUFFIX}"
IIIS0_BIN="$OUT_DIR/iiis-1${BIN_SUFFIX}"
DO_CHECK_CORPUS=0
DO_CLEAN=0

# TUs ported from C to .iii.  Each entry maps "name.c" -> compile name.iii
# via iiis-0 instead of gcc.  Keep this list LC_ALL=C sorted.
PORTED_TUS=( acc affine_audit ast ceiling cg_r0 cg_r3 cg_r3_xii cg_r3_xii_adapter cg_rm1 cg_rm2 cg_sha emit emit_sanctum hexad_check iii_cg_pe_iiis1 jit_emit lex lex_rt link main parse proof sema sema_xii_adapter sid witness_alloc xii_ldil )

usage() {
    cat <<'EOF' >&2
Usage: bash build_iiis1.sh [options]

Options:
  --mode release|debug      Build mode (default: release).
  --out <path>              Output binary path (default: III/COMPILED/iiis-2[.exe]).
  --check-corpus            After build, run stage1_corpus through iiis-0 AND iiis-2
                            and assert byte-identical .o output for every program.
  --clean                   Remove iiis-2 artifacts and ported .iii.o files; exit.
  -h, --help                Show this help and exit.

Exit codes:
  0 OK  1 USAGE  2 ENV  3 COMPILE  4 LINK  5 VERIFY  7 IO
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)            MODE="${2:-}"; shift 2 ;;
        --out)             OUT_BIN="${2:-}"; shift 2 ;;
        --check-corpus)    DO_CHECK_CORPUS=1; shift ;;
        --clean)           DO_CLEAN=1; shift ;;
        -h|--help)         usage; exit "$III_EXIT_OK" ;;
        *)                 usage; die "$III_EXIT_USAGE" "unknown argument: $1" ;;
    esac
done

if [[ "$DO_CLEAN" -eq 1 ]]; then
    log "clean: removing iiis-2 artifacts"
    rm -f "$OUT_BIN" "${OUT_BIN}.witness.json" "${OUT_BIN}.mhash"
    for tu in "${PORTED_TUS[@]}"; do
        rm -f "$BOOT_DIR/${tu}.iii.o"
    done
    log "clean: done"
    exit "$III_EXIT_OK"
fi

CC="${CC:-gcc}"
command -v "$CC"     >/dev/null 2>&1 || die "$III_EXIT_ENV" "compiler not found: $CC"
command -v sha256sum >/dev/null 2>&1 || die "$III_EXIT_ENV" "sha256sum not found"
[[ -x "$IIIS0_BIN"   ]] || die "$III_EXIT_ENV" "iiis-0 binary not found: $IIIS0_BIN  (run build_iiis0.sh first)"

case "$MODE" in
    release) CFLAGS_OPT=(-O2 -DNDEBUG) ;;
    debug)   CFLAGS_OPT=(-O0 -g3)      ;;
    *)       die "$III_EXIT_USAGE" "unknown mode: $MODE" ;;
esac

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iiis1-build.XXXXXX")"
trap '[[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true' EXIT

mkdir -p "$OUT_DIR" "$TMP_ROOT/obj"

# ----- compile C TUs (excluding ported) ------------------------------------
phase compile-c

CFLAGS_COMMON=(
    "${CFLAGS_OPT[@]}"
    -std=c11
    -Wall -Wextra -Werror
    -Wno-unused-parameter
    -Wno-unused-function
    -Wno-unused-variable
    -fno-strict-aliasing
    "-ffile-prefix-map=${BOOT_DIR}=."
    "-ffile-prefix-map=${III_ROOT}=."
    -I"$BOOT_DIR"
    -I"$III_ROOT"
    -DIIIS_XII_ENABLED
)

STDLIB_LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"

# Build a regex of basenames-without-.c that are ported.
PORTED_RE="^($(IFS='|'; echo "${PORTED_TUS[*]}"))\.c\$"

ALL_C="$( cd "$BOOT_DIR" && find . -maxdepth 1 -type f -name '*.c' \
            ! -name 'gen_*.c' \
            ! -name 'sign_*.c' \
            ! -name 'verify_*.c' \
            ! -name 'iiis1_link_stubs.c' \
            ! -name 'rm2_driver.c' \
            | sed 's|^\./||' | LC_ALL=C sort -V )"

OBJS=()
COMPILED_SRCS=()
while IFS= read -r src; do
    [[ -z "$src" ]] && continue
    if [[ "$src" =~ $PORTED_RE ]]; then
        log "skip $src (ported to .iii)"
        continue
    fi
    base="${src%.c}"
    obj="$TMP_ROOT/obj/${base}.o"
    OBJS+=("$obj")
    COMPILED_SRCS+=("$src")
    log "cc $src -> $obj"
    ( cd "$BOOT_DIR" && \
      "$CC" "${CFLAGS_COMMON[@]}" "-frandom-seed=$base" \
            -c "$src" -o "$obj" ) \
      || die "$III_EXIT_COMPILE" "compile failed: $src"
done <<< "$ALL_C"

# ----- compile ported .iii TUs via iiis-0 ----------------------------------
phase compile-iii
for tu in "${PORTED_TUS[@]}"; do
    src="$BOOT_DIR/${tu}.iii"
    obj="$TMP_ROOT/obj/${tu}.iii.o"
    [[ -f "$src" ]] || die "$III_EXIT_COMPILE" "missing ported source: $src"
    OBJS+=("$obj")
    log "iiis-0 $src -> $obj"
    ( cd "$BOOT_DIR" && "$IIIS0_BIN" "${tu}.iii" --compile-only --out "$obj" ) \
      || die "$III_EXIT_COMPILE" "iii compile failed: $src"
done

# ----- link ----------------------------------------------------------------
phase link
log "link -> $OUT_BIN"
if [[ -f "$STDLIB_LIB" ]]; then
    log "linking with stdlib (XII enabled): $STDLIB_LIB"
    # The previous build needed -Wl,--allow-multiple-definition because
    # acc.iii independently declared the same module-scope globals as
    # numera/sha256.iii (SHA_K, SHA_H, SHA_W, SHA_BUF, SHA_BUFLEN,
    # SHA_BITS).  acc.iii's copies have been renamed to ACC_SHA_*; the
    # only SHA_* globals now live in numera/sha256.iii.  No duplicate
    # symbols remain, so the workaround is dropped.  If a future TU
    # introduces another collision, the link will fail and the offending
    # symbol must be prefixed (per the CLAUDE.md module-scope const trap).
    "$CC" -o "$OUT_BIN" "${OBJS[@]}" "$STDLIB_LIB" \
      || die "$III_EXIT_LINK" "link failed: $OUT_BIN"
else
    die "$III_EXIT_LINK" "stdlib not found; build STDLIB/scripts/build_stdlib.sh first"
fi

# ----- mhash + witness -----------------------------------------------------
phase verify
MHASH="$( sha256sum "$OUT_BIN" | cut -d' ' -f1 )"
log "mhash: $MHASH"
printf '%s  %s\n' "$MHASH" "$(basename "$OUT_BIN")" > "${OUT_BIN}.mhash" \
    || die "$III_EXIT_IO" "failed to write ${OUT_BIN}.mhash"

PORTED_LIST="$( IFS=,; printf '%s' "${PORTED_TUS[*]}" )"
# Deterministic source-file provenance: the C TUs actually compiled into iiis-2
# (sorted ALL_C order), so the witness records the XII subsystem TUs
# (cg_r3_xii.c, xii_ldil.c, sema_xii.c, the adapters) that ship in the binary.
SRC_JSON="$( printf '"%s",' "${COMPILED_SRCS[@]}" | sed 's/,$//' )"
{
    printf '{\n'
    printf '  "tool": "build_iiis1.sh",\n'
    printf '  "ported_tus": "%s",\n' "$PORTED_LIST"
    printf '  "mode": "%s",\n'       "$MODE"
    printf '  "iiis0_used": "%s",\n' "$(basename "$IIIS0_BIN")"
    printf '  "output": "%s",\n'     "$(basename "$OUT_BIN")"
    printf '  "source_files": [%s],\n' "$SRC_JSON"
    printf '  "output_mhash": "%s"\n' "$MHASH"
    printf '}\n'
} > "${OUT_BIN}.witness.json" || die "$III_EXIT_IO" "witness write failed"

log "witness: ${OUT_BIN}.witness.json"
log "OK: $OUT_BIN"

# ----- optional: corpus equivalence check ----------------------------------
if [[ "$DO_CHECK_CORPUS" -eq 1 ]]; then
    phase check-corpus
    CORPUS_DIR="$BOOT_DIR/stage1_corpus"
    [[ -d "$CORPUS_DIR" ]] || die "$III_EXIT_VERIFY" "no corpus dir: $CORPUS_DIR"
    PASS=0; FAIL=0; FAILED_NAMES=""
    for prog in "$CORPUS_DIR"/*.iii; do
        name="$(basename "$prog" .iii)"
        out0="$TMP_ROOT/${name}_iiis0.o"
        out1="$TMP_ROOT/${name}_iiis1.o"
        rel_prog="stage1_corpus/${name}.iii"
        if ! ( cd "$BOOT_DIR" && "$IIIS0_BIN" "$rel_prog" --compile-only --out "$out0" >/dev/null 2>&1 ); then
            FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name(iiis0)"; continue
        fi
        if ! ( cd "$BOOT_DIR" && "$OUT_BIN"   "$rel_prog" --compile-only --out "$out1" >/dev/null 2>&1 ); then
            FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name(iiis1)"; continue
        fi
        h0="$( sha256sum "$out0" | cut -d' ' -f1 )"
        h1="$( sha256sum "$out1" | cut -d' ' -f1 )"
        if [[ "$h0" != "$h1" ]]; then
            FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name(diff)"
        else
            PASS=$((PASS+1))
        fi
    done
    log "corpus equivalence: $PASS passed, $FAIL failed"
    if [[ "$FAIL" -gt 0 ]]; then
        log "failed:$FAILED_NAMES"
        die "$III_EXIT_VERIFY" "corpus equivalence FAILED"
    fi

    # Ring -2 (cg_rm2 sanctum) end-to-end gate. The determinism corpus above does NOT exercise
    # --ring R-2, so cg_rm2 can silently rot (e.g. its node-kind constants drifting from ast.iii --
    # the exact bug class found 2026-06-02). This proves it still emits correct, RUNNABLE machine
    # code: sealed_call do_thing(7) must compute 3*7 == 21. Falsifiable -- break a kind/op constant.
    if [[ -f "$BOOT_DIR/check_rm2.sh" ]]; then
        phase check-rm2
        if ! bash "$BOOT_DIR/check_rm2.sh" "$OUT_BIN"; then
            die "$III_EXIT_VERIFY" "Ring -2 (cg_rm2) end-to-end check FAILED"
        fi
    fi

    # Ring 0 (cg_r0) crypto + u32-width gates.  The 59/0 corpus above is Ring-3 (cg_r3) and check_rm2 is
    # Ring -2 (cg_rm2); NEITHER exercises cg_r0, the Ring-0 backend used by KATABASIS kernel drivers.  A
    # u32-width regression in cg_r0 (the 2026-06-04 bug class: 8-byte-uniform codegen leaks a high-half
    # carry/shift bit into a later shr/cmp/div/mod -> wrong sha256 at Ring-0) is invisible to every other
    # gate -- it surfaced only on a metal kernel load (M23 quine-seal fail-closed).  These two gates prove
    # cg_r0 emits correct crypto (sha256("abc")==FIPS) + correct u32 width (cg_r0 == cg_r3 differential).
    if [[ -f "$BOOT_DIR/cg_r0_crypto_gate.sh" ]]; then
        phase check-cg-r0
        if ! IIIS="$OUT_BIN" bash "$BOOT_DIR/cg_r0_crypto_gate.sh"; then
            die "$III_EXIT_VERIFY" "cg_r0 crypto gate FAILED (Ring-0 backend mis-compiles sha256)"
        fi
        if [[ -f "$BOOT_DIR/cg_r0_width_gate.sh" ]]; then
            if ! IIIS="$OUT_BIN" bash "$BOOT_DIR/cg_r0_width_gate.sh"; then
                die "$III_EXIT_VERIFY" "cg_r0 width gate FAILED (Ring-0 backend mishandles u32 width)"
            fi
        fi
    fi
fi

exit "$III_EXIT_OK"

