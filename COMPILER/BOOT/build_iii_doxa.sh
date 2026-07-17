#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_doxa.sh
#
# Build iii-doxa: THE BELIEF ORGAN -- the type system for belief enforced as
# law.  Two books (modal asserts / statistical prefers), a per-context bit
# ledger with the solvency law, DERIVED-only evidence (the foreign law),
# dreams proven zero-residue, tombstone unlearning proven bit-identical, the
# exact question economy.  Like the heart: NO gate, NO KAT, NO standing arm --
# every verb self-proves before it may move, and the live loop settles the
# mind's stakes against evidence only iii-kardia can write.
#
# A LEAF tool build (the kardia/substrate mold): the PINNED in-tree compiler
# (COMPILED/iiis-2) + the committed stdlib archive.  The composed organs
# (cassandra -> lagrangian; entangle -> admix -> autognosis -> the sealed
# constitution seats; idfold) are LEAF-LINKED fresh.  The bootstrap chain is
# never touched.
#
# Usage: bash build_iii_doxa.sh
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-doxa build]"
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
    "$III_ROOT/STDLIB/iii/katabasis/doxa.iii"
    "$III_ROOT/STDLIB/iii/oneiros/cassandra.iii"
    "$III_ROOT/STDLIB/iii/aether/lagrangian.iii"
    "$III_ROOT/STDLIB/iii/aether/entangle.iii"
    "$III_ROOT/STDLIB/iii/aether/admix.iii"
    "$III_ROOT/STDLIB/iii/katabasis/autognosis.iii"
    "$III_ROOT/STDLIB/iii/aether/autophasis.iii"
    "$III_ROOT/STDLIB/iii/aether/xeno_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/substrate_ontogenesis.iii"
    "$III_ROOT/COMPILER/BOOT/cg_glossa_rules.iii"
    "$III_ROOT/COMPILER/BOOT/cg_phys_rules.iii"
    "$III_ROOT/STDLIB/iii/aether/glossa.iii"
    "$III_ROOT/STDLIB/iii/numera/idfold.iii"
    "$III_ROOT/COMPILER/BOOT/doxa_main.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]] || die 3 "missing source: $s"; done

TMP_ROOT="$III_ROOT/STDLIB/build/doxa"
mkdir -p "$TMP_ROOT" "$OUT_DIR"

OBJS=()
for s in "${SRCS[@]}"; do
    b="$(basename "$s" .iii)"
    o="$TMP_ROOT/$b.iii.o"
    log "iiis-2 $b.iii"
    "$IIIS" "$s" --compile-only --out "$o" > "$TMP_ROOT/build_$b.log" 2>&1 || die 3 "iii compile failed: $s (see $TMP_ROOT/build_$b.log)"
    OBJS+=("$o")
done

BIN="$OUT_DIR/iii-doxa$BIN_SUFFIX"
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
