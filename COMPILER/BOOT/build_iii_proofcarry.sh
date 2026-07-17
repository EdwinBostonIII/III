#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1
LOG_TAG="[iii-proofcarry build]"
log(){ printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die(){ printf '%s FATAL: %s\n' "$LOG_TAG" "$*" >&2; exit "${2:-2}"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_DIR="$III_ROOT/COMPILED"
case "$(uname -s 2>/dev/null||echo x)" in MINGW*|MSYS*|CYGWIN*) SFX=".exe";; *) SFX="";; esac
IIIS="$OUT_DIR/iiis-2$SFX"; [[ -x "$IIIS" ]]||die "no compiler $IIIS" 2
CC="${CC:-gcc}"; ARCHIVE="$III_ROOT/STDLIB/build/iii/libiii_native.a"; [[ -f "$ARCHIVE" ]]||die "no archive" 2
SRCS=(
  "$III_ROOT/STDLIB/iii/eidos/proofcarry.iii"
  "$III_ROOT/STDLIB/iii/omnia/eidolos.iii"
  "$III_ROOT/STDLIB/iii/numera/idfold.iii"
  "$III_ROOT/STDLIB/iii/omnia/isub.iii"
  "$III_ROOT/STDLIB/iii/omnia/exec_cert.iii"
  "$III_ROOT/STDLIB/iii/numera/sha256.iii"
  "$III_ROOT/COMPILER/BOOT/proofcarry_main.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]]||die "missing $s" 3; done
TMP="$III_ROOT/STDLIB/build/eidolos"; mkdir -p "$TMP"; OBJS=()
for s in "${SRCS[@]}"; do b="$(basename "$s" .iii)"; o="$TMP/$b.o"; log "iiis-2 $b.iii"
  "$IIIS" "$s" --compile-only --out "$o" >"$TMP/bld_$b.log" 2>&1||die "compile $s (see $TMP/bld_$b.log)" 3; OBJS+=("$o"); done
BIN="$OUT_DIR/iii-proofcarry$SFX"; log "link -> $BIN"; rc=1
for _ in 1 2 3; do rm -f "$BIN"; if "$CC" -o "$BIN" "${OBJS[@]}" "$ARCHIVE" -lws2_32 -lkernel32 >"$TMP/bld_link.log" 2>&1; then rc=0; break; fi; sleep 1; done
[[ $rc -eq 0 ]]||die "link failed (see $TMP/bld_link.log)" 4
log "OK: $BIN"; exit 0
