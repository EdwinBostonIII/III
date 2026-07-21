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
while IFS= read -r f; do SRC[$(basename "$f" .iii)]="$f"; done < <(find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' -not -path '*/build/*')
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

echo "[histos_gate] THE LIVING PROOF WEB STANDS -- loom green + byte-deterministic; the crux holds:"
cat "$T/run1.txt"
exit 0
