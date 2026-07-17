#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1
LOG="[iii-motion build]"; log(){ printf '%s %s\n' "$LOG" "$*" >&2; }; die(){ printf '%s FATAL: %s\n' "$LOG" "$*" >&2; exit "${2:-2}"; }
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$SD/../.." && pwd)"; OUT="$ROOT/COMPILED"
case "$(uname -s 2>/dev/null||echo x)" in MINGW*|MSYS*|CYGWIN*) X=".exe";; *) X="";; esac
IIIS="$OUT/iiis-2$X"; [[ -x "$IIIS" ]]||die "no compiler" 2; CC="${CC:-gcc}"; A="$ROOT/STDLIB/build/iii/libiii_native.a"; [[ -f "$A" ]]||die "no archive" 2
SRCS=(
  "$ROOT/STDLIB/iii/eidos/exact_motion.iii"
  "$ROOT/STDLIB/iii/aether/sqrt_sum_sign.iii"
  "$ROOT/STDLIB/iii/aether/kfield.iii"
  "$ROOT/STDLIB/iii/memoria/arena.iii"
  "$ROOT/STDLIB/iii/numera/bigint.iii"
  "$ROOT/STDLIB/iii/numera/bv_ring.iii"
  "$ROOT/STDLIB/iii/numera/cpufeat.iii"
  "$ROOT/STDLIB/iii/numera/typecheck.iii"
  "$ROOT/STDLIB/iii/numera/ccl.iii"
  "$ROOT/STDLIB/iii/numera/cost_lattice.iii"
  "$ROOT/STDLIB/iii/numera/combinator.iii"
  "$ROOT/STDLIB/iii/numera/weave_blocks.iii"
  "$ROOT/STDLIB/iii/omnia/hexad_reach.iii"
  "$ROOT/STDLIB/iii/omnia/hexad_pfs.iii"
  "$ROOT/STDLIB/iii/omnia/hexad_algebra.iii"
  "$ROOT/STDLIB/iii/numera/trit.iii"
  "$ROOT/STDLIB/iii/numera/sha256.iii"
  "$ROOT/COMPILER/BOOT/motion_main.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]]||die "missing $s" 3; done
T="$ROOT/STDLIB/build/eidolos"; mkdir -p "$T"; OBJS=()
for s in "${SRCS[@]}"; do b="$(basename "$s" .iii)"; o="$T/$b.o"; log "iiis-2 $b.iii"; "$IIIS" "$s" --compile-only --out "$o" >"$T/m_$b.log" 2>&1||die "compile $s (see $T/m_$b.log)" 3; OBJS+=("$o"); done
BIN="$OUT/iii-motion$X"; log "link -> $BIN"; rc=1
for _ in 1 2 3; do rm -f "$BIN"; if "$CC" -o "$BIN" "${OBJS[@]}" "$A" -lws2_32 -lkernel32 >"$T/m_link.log" 2>&1; then rc=0; break; fi; sleep 1; done
[[ $rc -eq 0 ]]||die "link failed (see $T/m_link.log)" 4
log "OK: $BIN"; exit 0
