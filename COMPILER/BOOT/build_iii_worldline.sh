#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_line.sh
#
# Build iii-worldline: GAMMA-1, THE EXACT PLANE -- geometry re-founded on the
# unified organism.  Points are eidolon identities (canonical surd sums,
# equality by the linear-independence theorem), order is the exact
# separation-bound sign oracle, and the line SPEAKS its total order as an
# EIDOLOS covering chain whose unraveling answers every pairwise fact.
# The two-path cross-proof runs the superseded planner (eid_plan) beside it.
# NO gate, NO KAT: ep_selfprove (arms 110..115) at every invocation.
#
# A LEAF tool build: pinned COMPILED/iiis-2 + the committed archive; the
# bootstrap chain is never touched.
# Usage: bash build_iii_line.sh
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-worldline build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s FATAL: %s\n' "$LOG_TAG" "$*" >&2; exit "${2:-2}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)               BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

IIIS="$OUT_DIR/iiis-2$BIN_SUFFIX"
[[ -x "$IIIS" ]] || die "pinned compiler not found: $IIIS" 2
CC="${CC:-gcc}"
command -v "$CC" >/dev/null 2>&1 || die "linker not found: $CC" 2
ARCHIVE="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -f "$ARCHIVE" ]] || die "stdlib archive not found: $ARCHIVE" 2

SRCS=(
    "$III_ROOT/STDLIB/iii/eidos/exact_worldline.iii"
    "$III_ROOT/STDLIB/iii/aether/kfield.iii"
    "$III_ROOT/STDLIB/iii/memoria/arena.iii"
    "$III_ROOT/STDLIB/iii/numera/bigint.iii"
    "$III_ROOT/STDLIB/iii/numera/cpufeat.iii"
    "$III_ROOT/STDLIB/iii/numera/typecheck.iii"
    "$III_ROOT/STDLIB/iii/numera/ccl.iii"
    "$III_ROOT/STDLIB/iii/numera/cost_lattice.iii"
    "$III_ROOT/STDLIB/iii/numera/combinator.iii"
    "$III_ROOT/STDLIB/iii/numera/weave_blocks.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_reach.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_pfs.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_algebra.iii"
    "$III_ROOT/STDLIB/iii/numera/trit.iii"
    "$III_ROOT/STDLIB/iii/omnia/eidolos.iii"
    "$III_ROOT/STDLIB/iii/numera/idfold.iii"
    "$III_ROOT/STDLIB/iii/omnia/isub.iii"
    "$III_ROOT/STDLIB/iii/omnia/exec_cert.iii"
    "$III_ROOT/STDLIB/iii/numera/sha256.iii"
    "$III_ROOT/COMPILER/BOOT/worldline_main.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]] || die "missing source: $s" 3; done

TMP_ROOT="$III_ROOT/STDLIB/build/eidolos"
mkdir -p "$TMP_ROOT"

OBJS=()
for s in "${SRCS[@]}"; do
    b="$(basename "$s" .iii)"
    o="$TMP_ROOT/$b.o"
    log "iiis-2 $b.iii"
    "$IIIS" "$s" --compile-only --out "$o" > "$TMP_ROOT/build_$b.log" 2>&1 || die "iii compile failed: $s (see $TMP_ROOT/build_$b.log)" 3
    OBJS+=("$o")
done

BIN="$OUT_DIR/iii-worldline$BIN_SUFFIX"
log "link -> $BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$BIN"
    if "$CC" -o "$BIN" "${OBJS[@]}" "$ARCHIVE" -lws2_32 -lkernel32 > "$TMP_ROOT/build_link.log" 2>&1; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die "link failed (see $TMP_ROOT/build_link.log)" 4
log "OK: $BIN"
exit 0
