#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_kardia.sh
#
# Build iii-kardia: THE HEART -- validation dissolved from batch runs into being.
#
#     iii-kardia prove                 the self-proof alone (every law arm, every falsifier)
#     iii-kardia birth  [--ledger D]   ingest the claim registry, pin the tree, adopt the lineage
#     iii-kardia status [--ledger D]   is the being green?  answered from the ledger, O(changed)
#     iii-kardia beat  N [--ledger D]  re-derive up to N DUE runnable cells
#     iii-kardia audit N [--ledger D]  re-derive up to N ADOPTED cells (retire inherited trust)
#
# Every verification claim becomes a CELL (name, class, expected exit, reach-pin,
# last verdict, mode); a cell is DUE exactly when its reach-pin drifts; adopted
# standing is never counted as proven-green; every verb SELF-PROVES before it may
# move.  There is deliberately NO corpus gate and NO standing arm for this tool:
# its verification lives inside it and runs at every invocation.
#
# A LEAF tool build: the PINNED in-tree compiler (COMPILED/iiis-2) + the committed
# stdlib archive (which carries the sanctus/mhash -> numera/cad -> numera/sha256
# chain).  The bootstrap chain is never touched.
#
# Usage: bash build_iii_kardia.sh
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022

export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

LOG_TAG="[iii-kardia build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"
IIIS="$OUT_DIR/iiis-2.exe"
[[ -x "$IIIS" ]] || IIIS="$OUT_DIR/iiis-2"
ARCHIVE="$III_ROOT/STDLIB/build/iii/libiii_native.a"
ORGAN="$III_ROOT/STDLIB/iii/katabasis/kardia.iii"
MAIN="$III_ROOT/COMPILER/BOOT/kardia_main.iii"
TMP_ROOT="$III_ROOT/STDLIB/build/kardia"
mkdir -p "$TMP_ROOT"

[[ -x "$IIIS" ]]    || die 2 "no pinned iiis-2 at $IIIS"
[[ -f "$ARCHIVE" ]] || die 2 "no stdlib archive at $ARCHIVE"
[[ -f "$ORGAN" ]]   || die 2 "no organ at $ORGAN"
[[ -f "$MAIN" ]]    || die 2 "no main at $MAIN"

OORG="$TMP_ROOT/kardia.iii.o"
OMAIN="$TMP_ROOT/kardia_main.iii.o"

log "iiis-2 kardia.iii -> kardia.iii.o"
"$IIIS" "$ORGAN" --compile-only --out "$OORG" > "$TMP_ROOT/build_organ.log" 2>&1 || die 3 "organ compile failed (see $TMP_ROOT/build_organ.log)"
log "iiis-2 kardia_main.iii -> kardia_main.iii.o"
"$IIIS" "$MAIN" --compile-only --out "$OMAIN" > "$TMP_ROOT/build_main.log" 2>&1 || die 3 "main compile failed (see $TMP_ROOT/build_main.log)"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN="$OUT_DIR/iii-kardia.exe" ;;
    *)                                  BIN="$OUT_DIR/iii-kardia"     ;;
esac
log "link -> $BIN"
rm -f "$BIN"
gcc "$OMAIN" "$OORG" "$ARCHIVE" -lws2_32 -lkernel32 -o "$BIN" > "$TMP_ROOT/build_link.log" 2>&1 || die 4 "link failed (see $TMP_ROOT/build_link.log)"
log "OK: $BIN"
