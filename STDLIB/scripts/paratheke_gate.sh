#!/usr/bin/env bash
# paratheke_gate.sh -- THE STANDING DEPOSIT under its own teeth.
#
# PARATHEKE is the cross-session reasoning ledger: entries are EIDOLOS scrolls,
# chained by scroll address, minted only by re-derivation, and re-EARNED through
# the live kernel on every read (verdicts are never read as truth).  This gate
# proves the law five ways:
#   A  the pure selfprove (no filesystem), twice, rc 0, byte-identical
#   B  the REAL tracked ledger stands whole against the live body
#      (a DUE ledger self-heals: the re-earn lines are appended, then it must stand)
#   C  the teeth on tampered copies: a flipped verdict is a CONTRADICTION; one
#      bent pin nybble breaks the chain at exactly the next link; a drifted
#      deciding source is named DUE -- three DIFFERENT refusals, each by name
#   D  the stand sweep is byte-deterministic
#   E  the discharge edge: the order entry's measurement obligation is owned by
#      ethos_r1_gate (pure law always; the real 671B walk when the Feast is present)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/paratheke"
CLO="$T/clo"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
JR="$ROOT/STDLIB/iii/omnia/paratheke.jrnl"
KR="$ROOT/STDLIB/iii/numera/krisis.iii"
PR="$ROOT/STDLIB/build/mantis/ethos_r1_probe.iii"
mkdir -p "$CLO"
[ -x "$IIIS" ] || { echo "[paratheke] no compiler: $IIIS (not green)"; exit 2; }
[ -f "$ARC" ]  || { echo "[paratheke] no archive: $ARC (not green)"; exit 2; }
[ -f "$JR" ]   || { echo "[paratheke] the tracked ledger is absent: $JR (not green)"; exit 2; }
[ -f "$PR" ]   || { echo "[paratheke] the probe source is absent: $PR (not green)"; exit 2; }

declare -A SRC
while IFS= read -r f; do SRC[$(basename "$f" .iii)]="$f"; done \
  < <(find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' -not -path '*/build/*')

closure() {  # echo the transitive .iii closure of $1 (basenames)
  local root="$1"; local -A seen=(); local -a q=("$root"); local cur dep src
  while [ ${#q[@]} -gt 0 ]; do
    cur="${q[0]}"; q=("${q[@]:1}"); [ -z "$cur" ] && continue
    [ -n "${seen[$cur]:-}" ] && continue; seen[$cur]=1
    src="${SRC[$cur]:-}"; [ -z "$src" ] && continue
    for dep in $(grep -oE 'from "[a-z_0-9]+\.iii"' "$src" 2>/dev/null | sed 's/from "//;s/\.iii"//' | sort -u); do
      [ -n "${seen[$dep]:-}" ] || q+=("$dep"); done
  done
  echo "${!seen[@]}"
}
compile_one() {  # basename -> $CLO/base.o (cached, source-mtime-fresh)
  local b="$1"
  local src="${SRC[$b]:-}"
  [ -z "$src" ] && return 0                       # provided by the archive
  if [ -f "$CLO/$b.o" ] && [ "$src" -nt "$CLO/$b.o" ]; then rm -f "$CLO/$b.o"; fi
  [ -f "$CLO/$b.o" ] && return 0
  for try in 1 2 3; do
    "$IIIS" "$src" --compile-only --out "$CLO/$b.o" > "$CLO/$b.log" 2>&1 && [ -f "$CLO/$b.o" ] && return 0
    sleep 1
  done
  echo "[paratheke] COMPILE FAIL $b: $(tail -1 "$CLO/$b.log")"; return 1
}

clo=$(closure "paratheke_cli")
for m in $clo; do compile_one "$m" || { echo "[paratheke] closure did not compile (not green)"; exit 3; }; done
OBJS=("$CLO/paratheke_cli.o")
for m in $clo; do [ "$m" = "paratheke_cli" ] && continue; [ -f "$CLO/$m.o" ] && OBJS+=("$CLO/$m.o"); done
CLI="$T/paratheke_cli.exe"
rc=1
for try in 1 2 3; do
  rm -f "$CLI"
  gcc -o "$CLI" "${OBJS[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && [ -f "$CLI" ] && break
  sleep 1
done
[ "$rc" -eq 0 ] || { echo "[paratheke] LINK FAIL (not green)"; grep -oE "undefined reference to .[a-z_0-9]+." "$T/link.log" | sort -u | head; exit 4; }

# ---- A: the pure law, twice, byte-identical ----
"$CLI" > "$T/sp1.out" 2>&1; r1=$?
"$CLI" > "$T/sp2.out" 2>&1; r2=$?
if [ "$r1" -ne 0 ] || [ "$r2" -ne 0 ]; then echo "[paratheke] selfprove REFUSED (rc1=$r1 rc2=$r2) $(head -1 "$T/sp1.out") (not green)"; exit 5; fi
cmp -s "$T/sp1.out" "$T/sp2.out" || { echo "[paratheke] selfprove NONDETERMINISM (not green)"; exit 6; }
echo "[paratheke] A: paratheke_selfprove = 0 (pure law, byte-deterministic)"

# ---- B: the real tracked ledger stands (self-healing on DUE) ----
"$CLI" stand "$JR" "$KR" "$PR" > "$T/stand1.out" 2>&1; sr=$?
if [ "$sr" -eq 4 ]; then
  echo "[paratheke] B: ledger DUE -> re-earning under the live body (append, never rewrite)"
  "$CLI" reearn "$JR" "$KR" "$PR" > "$T/heal_raw.txt" 2>&1; hr=$?
  [ "$hr" -eq 4 ] || { echo "[paratheke] reearn did not heal (rc=$hr) (not green)"; exit 7; }
  tr -d '\r' < "$T/heal_raw.txt" >> "$JR"
  "$CLI" stand "$JR" "$KR" "$PR" > "$T/stand1.out" 2>&1; sr=$?
fi
[ "$sr" -eq 0 ] || { echo "[paratheke] the ledger does not stand (rc=$sr) (not green)"; tail -4 "$T/stand1.out"; exit 7; }
grep -q "PARATHEKE STANDS" "$T/stand1.out" || { echo "[paratheke] stand summary absent (not green)"; exit 7; }
echo "[paratheke] B: $(tail -1 "$T/stand1.out")"

# ---- C: the teeth (three DIFFERENT refusals, each by name) ----
sed '1s/verdict_p/verdict_n/' "$JR" > "$T/tam_verdict.jrnl"
"$CLI" stand "$T/tam_verdict.jrnl" "$KR" "$PR" > "$T/tam1.out" 2>&1; t1=$?
{ [ "$t1" -eq 1 ] && grep -q "contradiction-with-live-body" "$T/tam1.out"; } \
  || { echo "[paratheke] TOOTH FAIL: flipped verdict not refused as contradiction (rc=$t1) (not green)"; exit 8; }
sed '1s/pin_k[0-9a-f]\{16\}/pin_k0123456789abcdef/' "$JR" > "$T/tam_pin.jrnl"
"$CLI" stand "$T/tam_pin.jrnl" "$KR" "$PR" > "$T/tam2.out" 2>&1; t2=$?
{ [ "$t2" -eq 1 ] && grep -q "chain-bent-at-this-link" "$T/tam2.out"; } \
  || { echo "[paratheke] TOOTH FAIL: bent pin did not break the chain at the next link (rc=$t2) (not green)"; exit 8; }
"$CLI" stand "$JR" "$PR" "$PR" > "$T/tam3.out" 2>&1; t3=$?
{ [ "$t3" -eq 4 ] && grep -q "DUE pin-drift" "$T/tam3.out"; } \
  || { echo "[paratheke] TOOTH FAIL: drifted deciding source not named DUE (rc=$t3) (not green)"; exit 8; }
echo "[paratheke] C: teeth bite -- contradiction / chain-bent / DUE, three refusals by name"

# ---- D: the stand sweep is byte-deterministic ----
"$CLI" stand "$JR" "$KR" "$PR" > "$T/stand2.out" 2>&1; sd=$?
[ "$sd" -eq 0 ] || { echo "[paratheke] restand REFUSED (rc=$sd) (not green)"; exit 9; }
cmp -s "$T/stand1.out" "$T/stand2.out" || { echo "[paratheke] stand NONDETERMINISM (not green)"; exit 9; }
echo "[paratheke] D: stand sweep byte-deterministic"

# ---- E: the discharge edge (the order entry's measurement obligation) ----
bash "$ROOT/STDLIB/scripts/ethos_r1_gate.sh" > "$T/ethos.out" 2>&1; er=$?
[ "$er" -eq 0 ] || { echo "[paratheke] discharge edge REFUSED: ethos_r1_gate rc=$er (not green)"; tail -4 "$T/ethos.out"; exit 10; }
echo "[paratheke] E: discharge edge -- $(tail -1 "$T/ethos.out")"

echo "[paratheke] THE STANDING DEPOSIT GREEN -- the ledger re-earns across sessions; nothing is trusted, everything is re-derived."
exit 0
