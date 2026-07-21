#!/usr/bin/env bash
# paratheke_gate.sh -- THE STANDING DEPOSIT under its own teeth (Paths A+B+C+D).
#
# PARATHEKE is the cross-session reasoning ledger: entries are EIDOLOS scrolls,
# chained by scroll address, minted only by re-derivation, and re-EARNED through
# the live engines on every read (verdicts are never read as truth).  This gate
# proves the law eight ways -- every mutating probe runs on a COPY, so the gate
# is idempotent on the tracked ledger:
#   A  the pure selfprove (no filesystem), twice, rc 0, byte-identical
#   B  the REAL tracked ledger stands whole against the live body
#      (a DUE ledger self-heals: the re-earn lines are appended, then it must stand)
#   C  the teeth on tampered copies: a flipped verdict is a CONTRADICTION; one
#      bent pin nybble breaks the chain at exactly the next link; a drifted
#      deciding source is named DUE -- three DIFFERENT refusals, each by name
#   D  the stand sweep is byte-deterministic
#   E  Path B, the oracle door: a TRUE claim ratchets in (the copy grows and
#      stands); a FORGED claim is ORACLE REFUTED and deposits nothing
#   F  Path C, the growth loop: two clicks -- each folds standing bodies into a
#      NOVEL union deposit with provenance, and the grown copy stands
#   G  Path D, the web atom: the standing entail theorem's premise is bent on a
#      copy -> the logos refuses the theorem as a CONTRADICTION
#   H  the discharge edge: the order entry's measurement obligation is owned by
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
ED="$ROOT/STDLIB/iii/omnia/eidolos.iii"
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
echo "[paratheke] A: paratheke_selfprove = 0 (pure law incl. Paths B/C/D arms, byte-deterministic)"

# ---- B: the real tracked ledger stands (self-healing on DUE) ----
"$CLI" stand "$JR" "$KR" "$PR" "$ED" > "$T/stand1.out" 2>&1; sr=$?
if [ "$sr" -eq 4 ]; then
  echo "[paratheke] B: ledger DUE -> re-earning under the live body (append, never rewrite)"
  "$CLI" reearn "$JR" "$KR" "$PR" "$ED" > "$T/heal_raw.txt" 2>&1; hr=$?
  [ "$hr" -eq 4 ] || { echo "[paratheke] reearn did not heal (rc=$hr) (not green)"; exit 7; }
  tr -d '\r' < "$T/heal_raw.txt" >> "$JR"
  "$CLI" stand "$JR" "$KR" "$PR" "$ED" > "$T/stand1.out" 2>&1; sr=$?
fi
[ "$sr" -eq 0 ] || { echo "[paratheke] the ledger does not stand (rc=$sr) (not green)"; tail -4 "$T/stand1.out"; exit 7; }
grep -q "PARATHEKE STANDS" "$T/stand1.out" || { echo "[paratheke] stand summary absent (not green)"; exit 7; }
echo "[paratheke] B: $(tail -1 "$T/stand1.out")"

# ---- C: the teeth (three DIFFERENT refusals, each by name) ----
sed '1s/verdict_p/verdict_n/' "$JR" > "$T/tam_verdict.jrnl"
"$CLI" stand "$T/tam_verdict.jrnl" "$KR" "$PR" "$ED" > "$T/tam1.out" 2>&1; t1=$?
{ [ "$t1" -eq 1 ] && grep -q "contradiction-with-live-body" "$T/tam1.out"; } \
  || { echo "[paratheke] TOOTH FAIL: flipped verdict not refused as contradiction (rc=$t1) (not green)"; exit 8; }
sed '1s/pin_k[0-9a-f]\{16\}/pin_k0123456789abcdef/' "$JR" > "$T/tam_pin.jrnl"
"$CLI" stand "$T/tam_pin.jrnl" "$KR" "$PR" "$ED" > "$T/tam2.out" 2>&1; t2=$?
{ [ "$t2" -eq 1 ] && grep -q "chain-bent-at-this-link" "$T/tam2.out"; } \
  || { echo "[paratheke] TOOTH FAIL: bent pin did not break the chain at the next link (rc=$t2) (not green)"; exit 8; }
"$CLI" stand "$JR" "$PR" "$PR" "$ED" > "$T/tam3.out" 2>&1; t3=$?
{ [ "$t3" -eq 4 ] && grep -q "DUE pin-drift" "$T/tam3.out"; } \
  || { echo "[paratheke] TOOTH FAIL: drifted deciding source not named DUE (rc=$t3) (not green)"; exit 8; }
echo "[paratheke] C: teeth bite -- contradiction / chain-bent / DUE, three refusals by name"

# ---- D: the stand sweep is byte-deterministic ----
"$CLI" stand "$JR" "$KR" "$PR" "$ED" > "$T/stand2.out" 2>&1; sd=$?
[ "$sd" -eq 0 ] || { echo "[paratheke] restand REFUSED (rc=$sd) (not green)"; exit 9; }
cmp -s "$T/stand1.out" "$T/stand2.out" || { echo "[paratheke] stand NONDETERMINISM (not green)"; exit 9; }
echo "[paratheke] D: stand sweep byte-deterministic"

# ---- E: Path B, the oracle door (on a COPY; the tracked ledger is never touched) ----
cp "$JR" "$T/door.jrnl"
"$CLI" propose "$T/door.jrnl" "$KR" "$PR" "$ED" z p,1,10,1 n,1,10,1 > "$T/prop_true_raw.txt" 2>&1; pt=$?
[ "$pt" -eq 0 ] || { echo "[paratheke] DOOR FAIL: true claim did not ratchet (rc=$pt) (not green)"; tail -2 "$T/prop_true_raw.txt"; exit 10; }
tr -d '\r' < "$T/prop_true_raw.txt" >> "$T/door.jrnl"
"$CLI" stand "$T/door.jrnl" "$KR" "$PR" "$ED" > "$T/door_stand.out" 2>&1; ds=$?
[ "$ds" -eq 0 ] || { echo "[paratheke] DOOR FAIL: ratcheted copy does not stand (rc=$ds) (not green)"; exit 10; }
cp "$T/door.jrnl" "$T/door_before_forge.jrnl"
"$CLI" propose "$T/door.jrnl" "$KR" "$PR" "$ED" p p,1,10,1 n,1,10,1 > "$T/prop_forged.out" 2>&1; pf=$?
{ [ "$pf" -eq 1 ] && grep -q "ORACLE REFUTED" "$T/prop_forged.out"; } \
  || { echo "[paratheke] DOOR FAIL: forged claim not refuted (rc=$pf) (not green)"; exit 10; }
cmp -s "$T/door.jrnl" "$T/door_before_forge.jrnl" || { echo "[paratheke] DOOR FAIL: a refuted claim changed the ledger (not green)"; exit 10; }
echo "[paratheke] E: the oracle door -- a true claim ratchets in; a forged claim is REFUTED and deposits nothing"

# ---- F: Path C, the growth loop (two clicks on the copy, each novel, each standing) ----
"$CLI" grow "$T/door.jrnl" "$KR" "$PR" "$ED" > "$T/grow1_raw.txt" 2>&1; g1=$?
[ "$g1" -eq 0 ] || { echo "[paratheke] LOOP FAIL: first growth did not fold (rc=$g1) (not green)"; exit 11; }
tr -d '\r' < "$T/grow1_raw.txt" > "$T/grow1.txt"
cat "$T/grow1.txt" >> "$T/door.jrnl"
"$CLI" stand "$T/door.jrnl" "$KR" "$PR" "$ED" > "$T/loop1.out" 2>&1; l1=$?
[ "$l1" -eq 0 ] || { echo "[paratheke] LOOP FAIL: grown ledger does not stand (rc=$l1) (not green)"; exit 11; }
"$CLI" grow "$T/door.jrnl" "$KR" "$PR" "$ED" > "$T/grow2_raw.txt" 2>&1; g2=$?
[ "$g2" -eq 0 ] || { echo "[paratheke] LOOP FAIL: second growth did not fold (rc=$g2) (not green)"; exit 11; }
tr -d '\r' < "$T/grow2_raw.txt" > "$T/grow2.txt"
cmp -s "$T/grow1.txt" "$T/grow2.txt" && { echo "[paratheke] LOOP FAIL: growth is not novel (not green)"; exit 11; }
cat "$T/grow2.txt" >> "$T/door.jrnl"
"$CLI" stand "$T/door.jrnl" "$KR" "$PR" "$ED" > "$T/loop2.out" 2>&1; l2=$?
[ "$l2" -eq 0 ] || { echo "[paratheke] LOOP FAIL: twice-grown ledger does not stand (rc=$l2) (not green)"; exit 11; }
echo "[paratheke] F: the growth loop -- two novel folds deposited with provenance, $(tail -1 "$T/loop2.out")"

# ---- G: Path D, the web atom (bend the standing theorem's premise on a copy) ----
grep -q "kind_entail" "$JR" || { echo "[paratheke] WEB FAIL: no standing entail theorem in the ledger (not green)"; exit 12; }
sed 's/pb_k00000000000060d8/pb_k00000000000060d9/' "$JR" > "$T/tam_web.jrnl"
"$CLI" stand "$T/tam_web.jrnl" "$KR" "$PR" "$ED" > "$T/tam_web.out" 2>&1; tw=$?
{ [ "$tw" -eq 1 ] && grep -q "contradiction-with-live-body" "$T/tam_web.out"; } \
  || { echo "[paratheke] WEB FAIL: bent premise not refused by the logos (rc=$tw) (not green)"; exit 12; }
echo "[paratheke] G: the web atom -- a bent premise and the logos refuses the theorem"

# ---- H: the discharge edge (the order entry's measurement obligation) ----
bash "$ROOT/STDLIB/scripts/ethos_r1_gate.sh" > "$T/ethos.out" 2>&1; er=$?
[ "$er" -eq 0 ] || { echo "[paratheke] discharge edge REFUSED: ethos_r1_gate rc=$er (not green)"; tail -4 "$T/ethos.out"; exit 13; }
echo "[paratheke] H: discharge edge -- $(tail -1 "$T/ethos.out")"

echo "[paratheke] THE STANDING DEPOSIT GREEN -- ledger, door, loop, and web all re-earn; nothing is trusted, everything is re-derived."
exit 0
