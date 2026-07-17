#!/usr/bin/env bash
# COMPILER/BOOT/build_iii_eidolos.sh
#
# Build iii-eidolos: THE UNIVERSAL REASONING LANGUAGE as a standing tool.
# Five rules, three verbs (= is / < under / ~ mirrors -- the substrate triad,
# FLAT/BELOW/REFLECT with the bus's own numbering), exact measures, nestable
# brackets (mention vs use), one canonical scroll whose shape IS its address,
# and the unraveling (congruence + transitive order + the order-reversing
# involution).  NO gate, NO KAT: eol_selfprove (arms 70..81) re-derives every
# law at every invocation, before any verb may move.
#
# THE PURITY LAW made visible: the language links THREE translation units --
# the organ, the ONE identity seat (numera/idfold), and the tool face.  No
# ground organ, no bus, no faculty: the system speaks the language; the
# language never leans on the system.
#
# A LEAF tool build (the kardia/doxa mold): the PINNED in-tree compiler
# (COMPILED/iiis-2) + the committed stdlib archive.  The bootstrap chain is
# never touched.
#
# Usage: bash build_iii_eidolos.sh
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii-eidolos build]"
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
    "$III_ROOT/STDLIB/iii/omnia/eidolos.iii"
    "$III_ROOT/STDLIB/iii/verba/lexicon.iii"
    "$III_ROOT/STDLIB/iii/aether/logos_wire.iii"
    "$III_ROOT/STDLIB/iii/glossa/topos.iii"
    "$III_ROOT/STDLIB/iii/aether/admix.iii"
    "$III_ROOT/STDLIB/iii/oneiros/cassandra.iii"
    "$III_ROOT/STDLIB/iii/aether/lagrangian.iii"
    "$III_ROOT/STDLIB/iii/katabasis/autognosis.iii"
    "$III_ROOT/STDLIB/iii/aether/autophasis.iii"
    "$III_ROOT/STDLIB/iii/aether/xeno_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/substrate_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/katabasis/cpu_census.iii"
    "$III_ROOT/STDLIB/iii/katabasis/behavioral_fp.iii"
    "$III_ROOT/COMPILER/BOOT/cg_glossa_rules.iii"
    "$III_ROOT/COMPILER/BOOT/cg_phys_rules.iii"
    "$III_ROOT/STDLIB/iii/aether/glossa.iii"
    "$III_ROOT/STDLIB/iii/numera/idfold.iii"
    "$III_ROOT/STDLIB/iii/omnia/isub.iii"
    "$III_ROOT/STDLIB/iii/omnia/exec_cert.iii"
    "$III_ROOT/STDLIB/iii/numera/sha256.iii"
    "$III_ROOT/COMPILER/BOOT/eidolos_main.iii"
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

BIN="$OUT_DIR/iii-eidolos$BIN_SUFFIX"
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
