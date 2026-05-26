#!/usr/bin/env bash
# C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\build_iiis0.sh
#
# Build the III Stage-0 bootstrap compiler (iiis-0[.exe]).
#
# Per ADR-021 §Boundaries: host-side build tools are gcc, ld, dlltool,
# signtool, bash, mingw-w64.  No third-party libraries linked.
#
# Per ADR-027 plan §13.1, Stage 0 is hand-written C in
# III/COMPILER/BOOT/.  This script compiles each TU and links them
# into III/COMPILED/iiis-0[.exe].
#
# Reproducibility (per ADR-027 §C-8): two consecutive runs over the
# same source tree produce a byte-identical iiis-0 binary.  Determinism
# is enforced by:
#   - SOURCE_DATE_EPOCH=0          (https://reproducible-builds.org/specs/source-date-epoch/)
#   - LC_ALL=C / TZ=UTC0 / LANG=C  (locale + timezone neutralisation)
#   - CCACHE_DISABLE=1             (ccache(1) bypass; avoid host cache state)
#   - gcc -frandom-seed=<basename> (gcc.gnu.org Code-Gen-Options: -frandom-seed)
#   - gcc -ffile-prefix-map=$PWD=. (gcc.gnu.org: -ffile-prefix-map for path normalisation)
#   - find ... | LC_ALL=C sort -V  (deterministic enumeration order)
#   - umask 022                    (deterministic mode bits on artifacts)
#
# Usage:
#   bash build_iiis0.sh [--mode release|debug] [--out <path>]
#                       [--check-deterministic] [--clean] [--help]
#
# Defaults: mode=release, out=III/COMPILED/iiis-0[.exe]
#
# ---------------------------------------------------------------------
# Exit codes (mirror III_EXIT_* in main.c when that TU lands; values
# are stable contract):
#   0   III_EXIT_OK              build succeeded
#   1   III_EXIT_USAGE           bad CLI flag / argument
#   2   III_EXIT_ENV             environment / toolchain missing
#   3   III_EXIT_COMPILE         a per-TU compile failed
#   4   III_EXIT_LINK            link step failed
#   5   III_EXIT_VERIFY          mhash mismatch vs golden iiis-0.mhash
#   6   III_EXIT_NONDETERMINISM  --check-deterministic divergence
#   7   III_EXIT_IO              filesystem / witness emission failed
# ---------------------------------------------------------------------
#
# Permissions note: on POSIX hosts run `chmod +x build_iiis0.sh` once.
# This repo is hosted on Windows where filesystem +x bits are not
# preserved; always invoke explicitly via `bash build_iiis0.sh ...`.

set -euo pipefail
IFS=$'\n\t'
umask 022

# Reproducibility env (exported globally so child gcc/ld see it).
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
III_EXIT_NONDETERMINISM=6
III_EXIT_IO=7

LOG_TAG="[iiis-0 build]"

log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
phase(){ printf '%s [PHASE] %s  t=%ss\n' "$LOG_TAG" "$1" "$SECONDS" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
OUT_DIR="$III_ROOT/COMPILED"
OBJ_DIR="$OUT_DIR/_obj_boot"

MODE="release"
# Default output binary name; .exe suffix appended on Windows-like hosts.
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
OUT_BIN="$OUT_DIR/iiis-0${BIN_SUFFIX}"
WITNESS="${OUT_BIN}.witness.json"
MHASH_OUT="${OUT_BIN}.mhash"
MHASH_GOLDEN="${BOOT_DIR}/iiis-0.mhash"

DO_CLEAN=0
DO_CHECK_DETERMINISTIC=0

usage() {
    cat <<'EOF' >&2
Usage: bash build_iiis0.sh [options]

Options:
  --mode release|debug      Build mode (default: release).
  --out <path>              Output binary path (default: III/COMPILED/iiis-0[.exe]).
  --check-deterministic     Build twice into separate temp dirs; compare mhash;
                            exit III_EXIT_NONDETERMINISM (6) on divergence.
  --clean                   Remove .o objects, iiis-0 binary, witness JSON,
                            and locally-emitted mhash file. Then exit.
  -h, --help                Show this help and exit.

Exit codes:
  0 OK  1 USAGE  2 ENV  3 COMPILE  4 LINK  5 VERIFY  6 NONDETERMINISM  7 IO
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)                  MODE="${2:-}"; shift 2 ;;
        --out)                   OUT_BIN="${2:-}"; WITNESS="${OUT_BIN}.witness.json"; MHASH_OUT="${OUT_BIN}.mhash"; shift 2 ;;
        --check-deterministic)   DO_CHECK_DETERMINISTIC=1; shift ;;
        --clean)                 DO_CLEAN=1; shift ;;
        -h|--help)               usage; exit "$III_EXIT_OK" ;;
        *)                       usage; die "$III_EXIT_USAGE" "unknown argument: $1" ;;
    esac
done

# --- --clean -----------------------------------------------------------------
if [[ "$DO_CLEAN" -eq 1 ]]; then
    log "clean: removing build artifacts"
    rm -rf "$OBJ_DIR"
    rm -f  "$OUT_BIN" "$WITNESS" "$MHASH_OUT"
    # Also sweep stray *.o in BOOT_DIR (e.g., legacy in-tree objects).
    find "$BOOT_DIR" -maxdepth 1 -name '*.o' -print -delete >&2 || true
    log "clean: done"
    exit "$III_EXIT_OK"
fi

# --- generate iii_compositions.h from .def (single source of truth) ----------
# The header is committed to the tree but is REGENERATED on every build to
# guarantee it tracks the .def. cg_r3.c #includes it; prespec.iii's
# auto-generated bulk-reg block is rewritten by the same script.
log "generating iii_compositions.h + prespec.iii bulk-reg from iii_compositions.def"
bash "$BOOT_DIR/gen_compositions.sh" >&2 || die "$III_EXIT_COMPILE" "gen_compositions.sh failed"

# --- toolchain detection -----------------------------------------------------
CC="${CC:-gcc}"
LD="${LD:-ld}"
command -v "$CC"        >/dev/null 2>&1 || die "$III_EXIT_ENV" "compiler not found: $CC"
command -v sha256sum    >/dev/null 2>&1 || die "$III_EXIT_ENV" "sha256sum not found (POSIX coreutils required)"

GCC_VERSION="$("$CC" --version | head -n1)"
if command -v "$LD" >/dev/null 2>&1; then
    LD_VERSION="$("$LD" --version | head -n1)"
else
    LD_VERSION="(invoked via $CC driver)"
fi

case "$MODE" in
    release) CFLAGS_OPT=(-O2 -DNDEBUG) ;;
    debug)   CFLAGS_OPT=(-O0 -g3)      ;;
    *)       die "$III_EXIT_USAGE" "unknown mode: $MODE" ;;
esac

# --- temp dir + EXIT trap ----------------------------------------------------
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iiis0-build.XXXXXX" 2>/dev/null || mktemp -d)"
cleanup_tmp() {
    [[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true
}
trap cleanup_tmp EXIT

# -----------------------------------------------------------------------------
# do_build <obj_dir> <out_bin>
#   Performs deterministic compile+link of all III/COMPILER/BOOT/*.c into
#   <out_bin>, with object files placed under <obj_dir>.  Echoes the mhash
#   (sha256, hex, lowercase) of the produced binary on stdout.  All other
#   logging goes to stderr.
# -----------------------------------------------------------------------------
do_build() {
    local _obj_dir="$1"
    local _out_bin="$2"
    mkdir -p "$_obj_dir" "$(dirname "$_out_bin")" \
        || die "$III_EXIT_IO" "mkdir failed: $_obj_dir / $(dirname "$_out_bin")"

    # Strict flags per ADR-027 §"NIH preservation" + reproducibility.
    # -frandom-seed: gcc.gnu.org Code-Gen-Options
    # -ffile-prefix-map: gcc.gnu.org Developer-Options (path normalisation)
    local _cflags_common=(
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
    )

    # ------------------------------------------------------------------
    # Deterministic source enumeration.
    # Plan §4.1 dictates a logical compile order
    #   (lex → ast → parse → hexad_check → sema → sid → proof → acc →
    #    ceiling → witness_alloc → cg_r3 → cg_r0 → cg_rm1 → cg_rm2 →
    #    jit_emit → link → emit → main)
    # but for *determinism by construction* we enumerate via
    # `find | LC_ALL=C sort -V`.  Compilation of independent TUs is
    # order-insensitive; only the final link order can affect bytes,
    # and we use the same sorted list for linking — which is itself
    # deterministic.
    # ------------------------------------------------------------------
    phase compile

    local _all_c
    # XII (Phase α-ζ) extensions live in COMPILER/BOOT/*xii*.c but belong
    # to iiis-2's build per DOCS/XII-IMPLEMENTATION.md §"Build hook".
    # iiis-0 is a MINIMAL bootstrap — it does not link xii_ldil.c (needs
    # sha256_oneshot from STDLIB) nor the XII-specific codegen/sema
    # extensions (need xii_canonicalise, xii_horizon_*, etc. from
    # STDLIB/iii/omnia/xii_*.iii).  The generator binaries (gen_xii_*.c)
    # are standalone tools invoked from build_xii.sh, not linked into
    # iiis-0.  All XII files are skipped via the !xii name pattern.
    _all_c="$( cd "$BOOT_DIR" && find . -maxdepth 1 -type f -name '*.c' \
                 ! -name '*_impl.c' \
                 ! -name '*xii*.c' \
                 ! -name 'gen_*.c' \
                 ! -name 'sign_*.c' \
                 ! -name 'verify_*.c' \
                 ! -name 'iiis1_*.c' \
                 | sed 's|^\./||' | LC_ALL=C sort -V )"

    # Optional TUs: skip-with-warning if absent; emit deterministic
    # sorted skip list to stderr at the end of the compile phase.
    local _optional=( ceiling.c hexad_check.c proof.c sema.c sid.c )
    local _skipped=()
    local _opt
    for _opt in "${_optional[@]}"; do
        if [[ ! -f "$BOOT_DIR/$_opt" ]]; then
            _skipped+=("$_opt")
        fi
    done

    if [[ -z "$_all_c" ]]; then
        die "$III_EXIT_COMPILE" "no *.c sources found in $BOOT_DIR"
    fi

    local _objs=()
    local _src _base _obj
    while IFS= read -r _src; do
        [[ -z "$_src" ]] && continue
        _base="${_src%.c}"
        _obj="$_obj_dir/$_base.o"
        _objs+=("$_obj")
        log "cc $_src -> $_obj"
        ( cd "$BOOT_DIR" && \
          "$CC" "${_cflags_common[@]}" "-frandom-seed=$_base" \
                -c "$_src" -o "$_obj" ) \
            || die "$III_EXIT_COMPILE" "compile failed: $_src"
    done <<< "$_all_c"

    if [[ "${#_skipped[@]}" -gt 0 ]]; then
        # Sort once more for explicit determinism of the report.
        local _sk
        _sk="$( printf '%s\n' "${_skipped[@]}" | LC_ALL=C sort -V )"
        log "skipped (optional, not present):"
        printf '%s   - %s\n' "$LOG_TAG" $_sk >&2
    fi

    # --- link -------------------------------------------------------------
    phase link
    log "link -> $_out_bin"
    "$CC" -o "$_out_bin" "${_objs[@]}" \
        || die "$III_EXIT_LINK" "link failed: $_out_bin"

    # --- mhash ------------------------------------------------------------
    phase verify
    local _mhash
    _mhash="$( sha256sum "$_out_bin" | cut -d' ' -f1 )"
    printf '%s\n' "$_mhash"
}

# --- --check-deterministic ---------------------------------------------------
if [[ "$DO_CHECK_DETERMINISTIC" -eq 1 ]]; then
    log "check-deterministic: building twice"
    BIN_A="$TMP_ROOT/A/iiis-0${BIN_SUFFIX}"
    BIN_B="$TMP_ROOT/B/iiis-0${BIN_SUFFIX}"
    HASH_A="$( do_build "$TMP_ROOT/A/obj" "$BIN_A" )"
    HASH_B="$( do_build "$TMP_ROOT/B/obj" "$BIN_B" )"
    log "build A mhash: $HASH_A"
    log "build B mhash: $HASH_B"
    if [[ "$HASH_A" != "$HASH_B" ]]; then
        die "$III_EXIT_NONDETERMINISM" "mhash divergence: $HASH_A vs $HASH_B"
    fi
    log "check-deterministic: OK ($HASH_A)"
    exit "$III_EXIT_OK"
fi

# --- normal build ------------------------------------------------------------
MHASH="$( do_build "$OBJ_DIR" "$OUT_BIN" )"
log "mhash: $MHASH"
printf '%s  %s\n' "$MHASH" "$(basename "$OUT_BIN")" > "$MHASH_OUT" \
    || die "$III_EXIT_IO" "failed to write $MHASH_OUT"

# --- golden mhash assertion --------------------------------------------------
if [[ -f "$MHASH_GOLDEN" ]]; then
    GOLDEN="$( awk '{print $1; exit}' "$MHASH_GOLDEN" )"
    if [[ "$MHASH" != "$GOLDEN" ]]; then
        die "$III_EXIT_VERIFY" "mhash mismatch: got $MHASH, golden $GOLDEN"
    fi
    log "verify: OK (matches $MHASH_GOLDEN)"
else
    log "verify: no golden $MHASH_GOLDEN (skipped)"
fi

# --- build witness sidecar ---------------------------------------------------
COMMIT="$( git -C "$III_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown" )"

# Deterministic env mhash: hash the sorted (key=value) reproducibility env.
ENV_MHASH="$(
    printf '%s\n' \
        "CCACHE_DISABLE=$CCACHE_DISABLE" \
        "LANG=$LANG" \
        "LC_ALL=$LC_ALL" \
        "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH" \
        "TZ=$TZ" \
      | LC_ALL=C sort \
      | sha256sum | cut -d' ' -f1
)"

SRC_LIST_JSON="$(
    cd "$BOOT_DIR" && find . -maxdepth 1 -type f -name '*.c' ! -name '*_impl.c' \
                  ! -name '*xii*.c' ! -name 'gen_*.c' ! -name 'sign_*.c' \
                  ! -name 'iiis1_*.c' \
        | sed 's|^\./||' | LC_ALL=C sort -V \
        | awk 'BEGIN{printf "["} { if(NR>1)printf ","; printf "\"%s\"",$0 } END{printf "]"}'
)"

# Escape backslashes + quotes for JSON values.
json_esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

{
    printf '{\n'
    printf '  "tool": "build_iiis0.sh",\n'
    printf '  "commit": "%s",\n'              "$(json_esc "$COMMIT")"
    printf '  "source_date_epoch": %s,\n'      "$SOURCE_DATE_EPOCH"
    printf '  "mode": "%s",\n'                 "$(json_esc "$MODE")"
    printf '  "gcc_version": "%s",\n'          "$(json_esc "$GCC_VERSION")"
    printf '  "ld_version": "%s",\n'           "$(json_esc "$LD_VERSION")"
    printf '  "source_files": %s,\n'           "$SRC_LIST_JSON"
    printf '  "output": "%s",\n'               "$(json_esc "$(basename "$OUT_BIN")")"
    printf '  "output_mhash": "%s",\n'         "$MHASH"
    printf '  "env_mhash": "%s"\n'             "$ENV_MHASH"
    printf '}\n'
} > "$WITNESS" || die "$III_EXIT_IO" "failed to write witness $WITNESS"

log "witness: $WITNESS"
log "OK: $OUT_BIN"
exit "$III_EXIT_OK"
