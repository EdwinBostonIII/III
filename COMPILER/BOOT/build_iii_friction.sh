#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_friction.sh
#
# Build iii-friction: THE FRICTION LOGOS driven -- the measured-cycle ledger
# (omnia/friction over omnia/bench) with its falsifier battery and the first
# sealed races (rot spellings; the PDEP alien-atom race).  A LEAF tool build
# (the build_iii_pulse mold): compile the organ + CLI with the pinned iiis-2,
# link the stdlib archive (bench + bench_helpers + cpufeat + cpu_census come
# from the archive).
#
# Usage: bash build_iii_friction.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-friction build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-friction${BIN_SUFFIX}"
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

SRCS=(
    "$III_ROOT/STDLIB/iii/omnia/friction.iii"
    "$III_ROOT/STDLIB/iii/aether/isa_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/isa_friction_judge.iii"
    "$III_ROOT/STDLIB/iii/aether/friction_cli.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]] || die 3 "missing source: $s"; done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-friction-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OBJS=()
for s in "${SRCS[@]}"; do
    b="$(basename "$s" .iii)"
    o="$TMP_ROOT/$b.iii.o"
    log "iiis-2 $b.iii"
    "$IIIS" "$s" --compile-only --out "$o" || die 3 "iii compile failed: $s"
    OBJS+=("$o")
done

log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "${OBJS[@]}" "$STDLIB_LIB" -lws2_32 -lkernel32; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
