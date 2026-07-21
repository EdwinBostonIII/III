#!/usr/bin/env bash
# histos_conscience_gate.sh -- HISTOS stage 4: the web grown to the conscience spine.
#
# The MVP web (histos_gate.sh) is the exact-order chain. This grows it to TEN organs, so the
# behavioral witness rests on TWO subtrees that meet at it:
#   SUBSTRATE (exact): witness -> membrane -> krisis -> bigint      (the two-engine exact order)
#   LAW (conscience) : witness -> ethos -> {ontos, reach_oracle, praxis, horos}, rooted in eidolos
# The witness STANDS iff BOTH stand -- "measured (substrate) is not installed (law)" made structural.
#
# Cells are the organs' REAL selfproves (eol_selfprove, ontos_selfprove, praxis_selfprove,
# horos_selfprove, ethos_gate, a reach_oracle wall-KAT, the exact chain's selfproves). The gate
# proves the two subtrees are INDEPENDENTLY load-bearing:
#   break the WALL (reach_oracle -> default-allow): witness RED rooted reach_oracle, substrate GREEN
#   break the ENGINE (kr_sign -> tie):              witness RED rooted krisis, law GREEN
# Only both axes together hold the witness up, and the web names which one broke. Mutations are on
# COPIES -- the tracked sources are never touched. Clean-checkout-safe (compiles from source).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/histos_c"
CLO="$T/clo"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
PROBE="$ROOT/STDLIB/build/mantis/histos_conscience_probe.iii"
mkdir -p "$CLO"
[ -x "$IIIS" ] || { echo "[conscience] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ]  || { echo "[conscience] no archive: $ARC"; exit 2; }
[ -f "$PROBE" ] || { echo "[conscience] no probe: $PROBE"; exit 2; }

declare -A SRC
while IFS= read -r f; do SRC[$(basename "$f" .iii)]="$f"; done < <(
  find "$ROOT/STDLIB/build/mantis" -maxdepth 1 -name '*.iii' 2>/dev/null
  find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' -not -path '*/build/*'
)
closure() {
  local root="$1"; local -A seen=(); local -a q=("$root"); local cur dep s
  while [ ${#q[@]} -gt 0 ]; do
    cur="${q[0]}"; q=("${q[@]:1}"); [ -z "$cur" ] && continue
    [ -n "${seen[$cur]:-}" ] && continue; seen[$cur]=1
    s="${SRC[$cur]:-}"; [ -z "$s" ] && continue
    for dep in $(grep -oE 'from "[a-z_0-9]+\.iii"' "$s" 2>/dev/null | sed 's/from "//;s/\.iii"//' | sort -u); do
      [ -n "${seen[$dep]:-}" ] || q+=("$dep"); done
  done
  echo "${!seen[@]}"
}
compile_one() {
  local b="$1"; local s="${SRC[$b]:-}"
  [ -z "$s" ] && return 0
  [ -f "$CLO/$b.o" ] && return 0
  for try in 1 2 3; do
    "$IIIS" "$s" --compile-only --out "$CLO/$b.o" > "$CLO/$b.log" 2>&1 && [ -f "$CLO/$b.o" ] && return 0
    sleep 1
  done
  echo "[conscience] COMPILE FAIL $b: $(tail -1 "$CLO/$b.log")"; return 1
}

clo="$(closure histos_conscience_probe)"
for m in $clo; do compile_one "$m" || exit 3; done
compile_one histos_conscience_probe || exit 3

# build with an optional single-organ object swap (probe main first; target-first for organ mains)
build_c() {   # $1 out ; $2 swap-organ-name ("" = none) ; $3 swap-object ("" = none)
  local out="$1" swapn="$2" swapo="$3" m
  local objs=("$CLO/histos_conscience_probe.o" "$CLO/histos.o")
  for m in $clo; do
    [ "$m" = histos_conscience_probe ] && continue
    [ "$m" = histos ] && continue
    [ -n "$swapn" ] && [ "$m" = "$swapn" ] && continue
    [ -f "$CLO/$m.o" ] && objs+=("$CLO/$m.o")
  done
  [ -n "$swapo" ] && objs+=("$swapo")
  local try
  for try in 1 2 3 4 5; do
    rm -f "$out"
    gcc -o "$out" "${objs[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$out.link" 2>&1 && [ -f "$out" ] && return 0
    sleep 1
  done
  echo "[conscience] LINK FAIL ($out):"; grep -oE "undefined reference to .[a-z_0-9]+." "$out.link" | sort -u | head; return 1
}

# (1) the true grown web: all ten organs green, both subtrees stand
build_c "$T/true.exe" "" "" || exit 10
"$T/true.exe" > "$T/true.out" 2>&1; rt=$?
grep -q "^conscience web: behavioral_witness GREEN rooted-at none" "$T/true.out" || { echo "[conscience] TRUE: web not green"; cat "$T/true.out"; exit 11; }
grep -q "^subtrees: substrate(krisis)=GREEN law(eidolos)=GREEN" "$T/true.out" || { echo "[conscience] TRUE: a subtree is not green"; cat "$T/true.out"; exit 11; }
[ "$rt" -eq 0 ] || { echo "[conscience] TRUE: exit $rt"; cat "$T/true.out"; exit 11; }

# (2) break the WALL (reach_oracle -> default-allow) : the LAW subtree gives way, substrate holds
RO_SRC="${SRC[reach_oracle]}"
cp "$RO_SRC" "$T/ro_mut.iii"
sed -i 's/fn reach_oracle_admit_canonical(tier: u32) -> i32 @export {/fn reach_oracle_admit_canonical(tier: u32) -> i32 @export {\n    return 0i32/' "$T/ro_mut.iii"
grep -q "return 0i32" "$T/ro_mut.iii" || { echo "[conscience] wall mutation did not apply"; exit 12; }
"$IIIS" "$T/ro_mut.iii" --compile-only --out "$T/ro_mut.o" > "$T/ro_mut.clog" 2>&1 || { echo "[conscience] mutant reach_oracle did not compile"; tail -4 "$T/ro_mut.clog"; exit 12; }
build_c "$T/wall.exe" "reach_oracle" "$T/ro_mut.o" || exit 12
"$T/wall.exe" > "$T/wall.out" 2>&1; rw=$?
grep -q "^conscience web: behavioral_witness RED rooted-at reach_oracle" "$T/wall.out" || { echo "[conscience] WALL: web did not redden rooted at the wall"; cat "$T/wall.out"; exit 13; }
grep -q "^subtrees: substrate(krisis)=GREEN " "$T/wall.out" || { echo "[conscience] WALL: the substrate should still stand"; cat "$T/wall.out"; exit 13; }
[ "$rw" -eq 2 ] || { echo "[conscience] WALL: expected web-red exit 2, got $rw"; cat "$T/wall.out"; exit 13; }

# (3) break the ENGINE (kr_sign -> constant tie) : the SUBSTRATE subtree gives way, law holds
KR_SRC="${SRC[krisis]}"
cp "$KR_SRC" "$T/kr_mut.iii"
sed -i 's/fn kr_sign() -> i64 @export {/fn kr_sign() -> i64 @export {\n    return 0i64/' "$T/kr_mut.iii"
grep -q "return 0i64" "$T/kr_mut.iii" || { echo "[conscience] engine mutation did not apply"; exit 14; }
"$IIIS" "$T/kr_mut.iii" --compile-only --out "$T/kr_mut.o" > "$T/kr_mut.clog" 2>&1 || { echo "[conscience] mutant krisis did not compile"; tail -4 "$T/kr_mut.clog"; exit 14; }
build_c "$T/engine.exe" "krisis" "$T/kr_mut.o" || exit 14
"$T/engine.exe" > "$T/engine.out" 2>&1; re=$?
grep -q "^conscience web: behavioral_witness RED rooted-at krisis" "$T/engine.out" || { echo "[conscience] ENGINE: web did not redden rooted at krisis"; cat "$T/engine.out"; exit 15; }
grep -q "law(eidolos)=GREEN" "$T/engine.out" || { echo "[conscience] ENGINE: the law subtree should still stand"; cat "$T/engine.out"; exit 15; }
[ "$re" -eq 2 ] || { echo "[conscience] ENGINE: expected web-red exit 2, got $re"; cat "$T/engine.out"; exit 15; }

echo "[conscience] THE GROWN WEB STANDS -- ten organs, two subtrees meeting at the witness:"
echo "  true  : $(grep '^conscience web:' "$T/true.out")   [$(grep '^subtrees:' "$T/true.out")]"
echo "  wall  : $(grep '^conscience web:' "$T/wall.out")   [substrate holds]"
echo "  engine: $(grep '^conscience web:' "$T/engine.out")   [law holds]"
echo "[conscience] the witness rests on BOTH the exact substrate AND the conscience law; break"
echo "             either and it falls, and the web names which -- 'measured is not installed', structural."
exit 0
