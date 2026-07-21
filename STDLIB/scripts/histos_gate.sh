#!/usr/bin/env bash
# histos_gate.sh -- THE LIVING PROOF WEB RITE (stage 1: the loom's logic, with teeth).
#
# HISTOS weaves III's self-proving organs into ONE web: nodes are organs, edges are cross-organ
# dependencies carrying an EIDOLOS obligation discharged by HOROS. A node STANDS only if its own
# cell is green AND every dependency (transitively) stands. This gate builds the loom FROM SOURCE
# (closure-based, clean-checkout-safe -- no dependence on prebuilt build/kinesis objects) and runs
# histos_selfprove, which proves the loom's logic with a mandatory negative:
#
#   THE CRUX (arm 3): breaking the krisis cell reddens the behavioral_witness node THROUGH the web
#   even though the witness's OWN cell stays green (its selfprove is the pure law, which never runs
#   the engines) -- and histos_reddened_by names `krisis` as the root. That is exactly what a
#   per-organ gate (omnia_selfprove_gate.sh) cannot do.
#
# Also proven: all three MVP edges discharge (real EIDOLOS entailment); a would-be cycle is refused
# by name; a non-entailing edge reddens its from-node. Byte-deterministic (run twice, cmp).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/histos"
CLO="$T/clo"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$CLO"
[ -x "$IIIS" ] || { echo "[histos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ]  || { echo "[histos_gate] no archive: $ARC"; exit 2; }

declare -A SRC
# build/mantis FIRST so the stage-2 probe sources resolve; STDLIB/iii + COMPILER/BOOT LAST so a
# real organ always wins the basename over any stale probe copy (last-wins).
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
  local b="$1"
  local s="${SRC[$b]:-}"
  [ -z "$s" ] && return 0
  [ -f "$CLO/$b.o" ] && return 0
  for try in 1 2 3; do
    "$IIIS" "$s" --compile-only --out "$CLO/$b.o" > "$CLO/$b.log" 2>&1 && [ -f "$CLO/$b.o" ] && return 0
    sleep 1
  done
  echo "[histos_gate] COMPILE FAIL $b: $(tail -1 "$CLO/$b.log")"; return 1
}

# the CLI carries main; compile it + histos + their closure
clo="$(closure histos_cli)"
for m in $clo; do compile_one "$m" || exit 3; done
compile_one histos_cli || exit 3

# link CLI main first (it wins under --allow-multiple-definition over any organ's main)
OBJS=("$CLO/histos_cli.o" "$CLO/histos.o"); for m in $clo; do
  [ "$m" = histos_cli ] && continue; [ "$m" = histos ] && continue; [ -f "$CLO/$m.o" ] && OBJS+=("$CLO/$m.o")
done
rc=1
for try in 1 2 3 4 5; do
  rm -f "$T/histos.exe"
  gcc -o "$T/histos.exe" "${OBJS[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && [ -f "$T/histos.exe" ] && break
  sleep 1
done
[ "$rc" -eq 0 ] || { echo "[histos_gate] LINK FAIL rc=$rc"; grep -oE "undefined reference to .[a-z_0-9]+." "$T/link.log" | sort -u | head; exit 4; }

STG="$T/histos_run.exe"
cp "$T/histos.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; r1=$?
cp "$T/histos.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; r2=$?; rm -f "$STG"
[ "$r1" -eq 0 ] && [ "$r2" -eq 0 ] || { echo "[histos_gate] SELF-REFUSED r1=$r1 r2=$r2"; tail -8 "$T/run1.txt"; exit 5; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[histos_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 6; }
grep -q "^histos_selfprove = 0" "$T/run1.txt" || { echo "[histos_gate] LOOM NOT GREEN"; tail -8 "$T/run1.txt"; exit 7; }
# the crux line, asserted verbatim: witness RED through the web with its own cell GREEN, rooted at krisis
grep -q "^the teeth: krisis cell RED -> behavioral_witness RED, own-cell GREEN, rooted-at krisis" "$T/run1.txt" \
  || { echo "[histos_gate] THE CRUX ABSENT -- the web did not redden a green-celled node via its dependency"; tail -8 "$T/run1.txt"; exit 8; }

echo "[histos_gate] STAGE 1 (loom logic) GREEN + byte-deterministic; the crux holds:"
cat "$T/run1.txt"

# ============================================================================
# STAGE 2: the same reddening on REAL ARTIFACTS. Build the real-verdict probe
# (histos_web_probe runs the four organs' actual selfproves), once against the
# true krisis and once against a krisis whose kr_sign is mutated to a constant
# tie. In the mutant build, krisis and membrane redden from their REAL runs, the
# witness's REAL pure-law selfprove still passes, and the WEB reddens the witness
# rooted at krisis -- real artifacts, not injected.
# ============================================================================
PROBE="$ROOT/STDLIB/build/mantis/histos_web_probe.iii"
[ -f "$PROBE" ] || { echo "[histos_gate] no stage-2 probe: $PROBE"; exit 9; }
KR_SRC="${SRC[krisis]}"

clo2="$(closure histos_web_probe)"
for m in $clo2; do compile_one "$m" || exit 3; done
compile_one histos_web_probe || exit 3

# object list for the probe (target main first), EXCLUDING krisis.o so we can swap it
build_web() {   # $1 = path to the krisis object to link ; $2 = output exe
  local krobj="$1" out="$2"
  local objs=("$CLO/histos_web_probe.o" "$CLO/histos.o")
  local m
  for m in $clo2; do
    [ "$m" = histos_web_probe ] && continue
    [ "$m" = histos ] && continue
    [ "$m" = krisis ] && continue
    [ -f "$CLO/$m.o" ] && objs+=("$CLO/$m.o")
  done
  objs+=("$krobj")
  local try
  for try in 1 2 3 4 5; do
    rm -f "$out"
    gcc -o "$out" "${objs[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$out.link" 2>&1 && [ -f "$out" ] && return 0
    sleep 1
  done
  echo "[histos_gate] stage2 LINK FAIL ($out):"; grep -oE "undefined reference to .[a-z_0-9]+." "$out.link" | sort -u | head; return 1
}

# (a) the true web -- all four real cells green
build_web "$CLO/krisis.o" "$T/web_true.exe" || exit 10
"$T/web_true.exe" > "$T/web_true.out" 2>&1; wt=$?
grep -q "^real cells: witness=green membrane=green krisis=green bigint=green" "$T/web_true.out" \
  || { echo "[histos_gate] STAGE 2 TRUE: not all real cells green"; cat "$T/web_true.out"; exit 11; }
grep -q "^web: behavioral_witness GREEN" "$T/web_true.out" \
  || { echo "[histos_gate] STAGE 2 TRUE: web not green"; cat "$T/web_true.out"; exit 11; }
[ "$wt" -eq 0 ] || { echo "[histos_gate] STAGE 2 TRUE: exit $wt"; cat "$T/web_true.out"; exit 11; }

# (b) mutate kr_sign to a constant tie (return 0i64 at entry) -- on a COPY; the tracked source is never touched
cp "$KR_SRC" "$T/krisis_mut.iii"
sed -i 's/fn kr_sign() -> i64 @export {/fn kr_sign() -> i64 @export {\n    return 0i64/' "$T/krisis_mut.iii"
grep -q "return 0i64" "$T/krisis_mut.iii" || { echo "[histos_gate] mutation did not apply (kr_sign signature drifted?)"; exit 12; }
"$IIIS" "$T/krisis_mut.iii" --compile-only --out "$T/krisis_mut.o" > "$T/krisis_mut.clog" 2>&1 \
  || { echo "[histos_gate] mutant krisis did not compile"; tail -4 "$T/krisis_mut.clog"; exit 12; }
build_web "$T/krisis_mut.o" "$T/web_mut.exe" || exit 12
"$T/web_mut.exe" > "$T/web_mut.out" 2>&1; wm=$?

# THE STAGE-2 CRUX, asserted on real artifacts: krisis+membrane really red, witness really green,
# the web reddens the witness and names krisis.
grep -q "^real cells: witness=green membrane=red krisis=red bigint=green" "$T/web_mut.out" \
  || { echo "[histos_gate] STAGE 2 MUT: real cells not (witness green, membrane+krisis red, bigint green)"; cat "$T/web_mut.out"; exit 13; }
grep -q "^web: behavioral_witness RED (own-cell GREEN) rooted-at krisis" "$T/web_mut.out" \
  || { echo "[histos_gate] STAGE 2 MUT: the web did not redden the green-celled witness rooted at krisis"; cat "$T/web_mut.out"; exit 13; }
[ "$wm" -eq 2 ] || { echo "[histos_gate] STAGE 2 MUT: expected web-red exit 2, got $wm"; cat "$T/web_mut.out"; exit 13; }

echo "[histos_gate] STAGE 2 (real artifacts) GREEN -- the true web stands; a mutated kr_sign reddens"
echo "              krisis + membrane from their REAL runs, the witness's REAL cell stays green,"
echo "              and the web reddens the witness rooted at krisis:"
echo "  true:  $(grep '^web:' "$T/web_true.out")"
echo "  mut :  $(grep '^web:' "$T/web_mut.out")"
echo "[histos_gate] THE LIVING PROOF WEB STANDS (stages 1 + 2)."
exit 0
