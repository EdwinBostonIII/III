#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_events.sh
#
# Build iii-events: THE EVENT-PRIMARY EXECUTOR AS A STANDING TOOL.
#
#     iii-events <file.iii>              run a .iii program as an append-only retirement log;
#                                        output/result read back out of the log by the validating fold
#     iii-events --quiet <file.iii>      pure program behavior (exit = program rc)
#     iii-events --tamper <file.iii>     corrupt one recorded event -> the fold MUST refuse 193
#
# This makes route V (STDLIB/sovir/svir_event.iii, gated by run_event_waist.sh) independently useful
# on ARBITRARY user programs: the compiler's own front end (lex/ast/parse) + its own SVIR backend
# (cg_svir) + the event-primary executor, all IN-PROCESS.  No script, no glue, no operator.
#
# A LEAF tool build, exactly like build_iii_prove.sh: it uses the PINNED in-tree production compiler
# (COMPILED/iiis-2) and the committed stdlib archive.  The bootstrap chain (iiis-0..3), its objects,
# and its seals are never touched.
#
# Usage: bash build_iii_events.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022

export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

LOG_TAG="[iii-events build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
SOVIR_DIR="$III_ROOT/STDLIB/sovir"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-events${BIN_SUFFIX}"
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

# The tool's TU closure: the compiler's FRONT half + its SVIR backend (the same independence
# boundary iii-prove keeps: NOTHING from sema/sid/cg_r*/emit/link) + route V's executor organ
# (svir_event, from STDLIB/sovir -- the ONE out-of-dir TU) + the driver.
BOOT_TUS=( cg_sha lex_rt lex ast parse eval cg_svir events_main )

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-events-build.XXXXXX")"
trap '[[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true' EXIT
mkdir -p "$TMP_ROOT/obj" "$OUT_DIR"

OBJS=()
for tu in "${BOOT_TUS[@]}"; do
    src="$BOOT_DIR/${tu}.iii"
    obj="$TMP_ROOT/obj/${tu}.iii.o"
    [[ -f "$src" ]] || die 3 "missing source: $src"
    OBJS+=("$obj")
    log "iiis-2 ${tu}.iii -> ${tu}.iii.o"
    ( cd "$BOOT_DIR" && "$IIIS" "${tu}.iii" --compile-only --out "$obj" ) \
        || die 3 "iii compile failed: $src"
done
obj="$TMP_ROOT/obj/svir_event.iii.o"
[[ -f "$SOVIR_DIR/svir_event.iii" ]] || die 3 "missing source: $SOVIR_DIR/svir_event.iii"
OBJS+=("$obj")
log "iiis-2 svir_event.iii -> svir_event.iii.o"
( cd "$SOVIR_DIR" && "$IIIS" "svir_event.iii" --compile-only --out "$obj" ) \
    || die 3 "iii compile failed: $SOVIR_DIR/svir_event.iii"

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
