#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_agon.sh
#
# Build iii-agon: THE AGON as a standing tool (ENTELECHEIA Ε2).
#
#   iii-agon root   <src_root.iii> <binary>
#   iii-agon verify <src-64hex> <src_root.iii> <img-64hex> <binary>
#
# Runs two common-mode-independent bearers of "the organism is itself" -- the
# SOURCE closure (sanctus/closure_graph) and the IMAGE birth-rite
# (katabasis/pulse) -- and folds their DIVERGENCE, perceiving each verdict as a
# witnessed event on omnia/event_substrate.  A LEAF tool build (the
# build_iii_closure mold): compile the four organs + the CLI with the pinned
# iiis-2, link them BEFORE the stdlib archive so the freshly-compiled organs
# override the archive's older copies.
#
# Usage: bash build_iii_agon.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-agon build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii-agon${BIN_SUFFIX}"
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

AGON="$III_ROOT/STDLIB/iii/katabasis/agon.iii"
GRAPH="$III_ROOT/STDLIB/iii/sanctus/closure_graph.iii"
PULSE="$III_ROOT/STDLIB/iii/katabasis/pulse.iii"
EVT="$III_ROOT/STDLIB/iii/omnia/event_substrate.iii"
SRC="$III_ROOT/STDLIB/iii/aether/agon_cli.iii"
for f in "$AGON" "$GRAPH" "$PULSE" "$EVT" "$SRC"; do
    [[ -f "$f" ]] || die 3 "missing organ/source: $f"
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/iii-agon-build.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" 2>/dev/null || true' EXIT
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OAGON="$TMP_ROOT/agon.iii.o"
OGRAPH="$TMP_ROOT/closure_graph.iii.o"
OPULSE="$TMP_ROOT/pulse.iii.o"
OEVT="$TMP_ROOT/event_substrate.iii.o"
OCLI="$TMP_ROOT/agon_cli.iii.o"

log "iiis-2 agon.iii -> agon.iii.o"
"$IIIS" "$AGON"  --compile-only --out "$OAGON"  || die 3 "iii compile failed: $AGON"
log "iiis-2 closure_graph.iii -> closure_graph.iii.o"
"$IIIS" "$GRAPH" --compile-only --out "$OGRAPH" || die 3 "iii compile failed: $GRAPH"
log "iiis-2 pulse.iii -> pulse.iii.o"
"$IIIS" "$PULSE" --compile-only --out "$OPULSE" || die 3 "iii compile failed: $PULSE"
log "iiis-2 event_substrate.iii -> event_substrate.iii.o"
"$IIIS" "$EVT"   --compile-only --out "$OEVT"   || die 3 "iii compile failed: $EVT"
log "iiis-2 agon_cli.iii -> agon_cli.iii.o"
"$IIIS" "$SRC"   --compile-only --out "$OCLI"   || die 3 "iii compile failed: $SRC"

log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "$OCLI" "$OAGON" "$OGRAPH" "$OPULSE" "$OEVT" "$STDLIB_LIB" -lws2_32 -lkernel32; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed: $OUT_BIN (after retries)"

log "OK: $OUT_BIN"
exit 0
