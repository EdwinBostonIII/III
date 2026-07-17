#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_soma.sh
#
# Build iii-soma: THE SOMA -- the machine's claim-space as one addressable body,
# and the map-vs-territory audit (does the registry the mind reads match the
# gate files that actually exist?).  Organ-native: kardia for the map, the
# FindFirstFile directory primitive (aether/fs) for the territory -- no bash
# reads the machine's self.
#
# A LEAF tool build (the kardia mold): the PINNED in-tree compiler
# (COMPILED/iiis-2) + the committed stdlib archive.  Composes katabasis/kardia
# (leaf-linked) + aether/fs + aether/capability + numera/idfold (archive).
#
# Usage: bash build_iii_soma.sh
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-soma build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

IIIS="$OUT_DIR/iiis-2$BIN_SUFFIX"
[[ -x "$IIIS" ]] || die 2 "pinned compiler not found: $IIIS"
CC="${CC:-gcc}"
command -v "$CC" >/dev/null 2>&1 || die 2 "linker not found: $CC"
ARCHIVE="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -f "$ARCHIVE" ]] || die 2 "stdlib archive not found: $ARCHIVE"

SRCS=(
    "$III_ROOT/STDLIB/iii/katabasis/soma.iii"
    "$III_ROOT/STDLIB/iii/katabasis/kardia.iii"
    "$III_ROOT/COMPILER/BOOT/soma_main.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]] || die 3 "missing source: $s"; done

TMP_ROOT="$III_ROOT/STDLIB/build/soma"
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OBJS=()
for s in "${SRCS[@]}"; do
    b="$(basename "$s" .iii)"
    o="$TMP_ROOT/$b.iii.o"
    log "iiis-2 $b.iii"
    "$IIIS" "$s" --compile-only --out "$o" > "$TMP_ROOT/build_$b.log" 2>&1 || die 3 "iii compile failed: $s (see $TMP_ROOT/build_$b.log)"
    OBJS+=("$o")
done

BIN="$OUT_DIR/iii-soma$BIN_SUFFIX"
log "link -> $BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$BIN"
    if "$CC" -o "$BIN" "${OBJS[@]}" "$ARCHIVE" -lws2_32 -lkernel32 > "$TMP_ROOT/build_link.log" 2>&1; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed (see $TMP_ROOT/build_link.log)"
log "OK: $BIN"
exit 0
