#!/usr/bin/env bash
# ontos_gate.sh -- THE BEING-SIGNATURE RITE, re-derived from clean objects every run.
#
# ONTOS (omnia/ontos.iii) speaks real III primitives' being-signatures to EIDOLOS (omnia/eidolos.iii) -- the
# system's single seat of judgment -- and lets its unraveling render the verdict: pure being (1,1,1) STANDS,
# reversible (~) and lossy (<) signatures cohere, THE SHADOW [being < being] is REFUSED (the unwilting), a lossy
# cycle is refused, reversibility=order-reversal is DERIVED, and an unsound-ZK forgery is refused by the SAME
# self-under law. No new language, no new tool -- EIDOLOS judging the primitives per its own perfection.
# Exit 0 = green + byte-deterministic.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/ontos"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
[ -x "$IIIS" ] || { echo "[ontos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[ontos_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[ontos_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[ontos_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -10 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/ontos.iii"   "$T/ontos.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii" "$T/eidolos.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"    "$T/isub.o"    || exit 2   # eidolos calls newer isub_* than the archive
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii" "$T/idfold.o"  || exit 2   # the ONE identity seat eidolos folds through
cc_one "$ROOT/STDLIB/iii/aether/bounty_attest.iii" "$T/bounty_attest.o" || exit 2   # the REAL ed25519 grace signature
cc_one "$ROOT/STDLIB/iii/katabasis/kardia.iii"     "$T/kardia.o"        || exit 2   # III's LIVE entity registry
cc_one "$ROOT/STDLIB/iii/omnia/ptyxis.iii"         "$T/ptyxis.o"        || exit 2   # the FOLD -- a real organ, judged by the exported law

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/ontos.exe"
    gcc -o "$T/ontos.exe" "$T/ontos.o" "$T/eidolos.o" "$T/isub.o" "$T/idfold.o" "$T/bounty_attest.o" "$T/kardia.o" "$T/ptyxis.o" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/ontos.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[ontos_gate] LINK FAIL rc=$rc"; tail -14 "$T/link.log"; exit 3; }

STG="$T/ontos_run.exe"
cp "$T/ontos.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?
cp "$T/ontos.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] || { echo "[ontos_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -14 "$T/run1.txt"; exit 4; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[ontos_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "GREEN" "$T/run1.txt" || { echo "[ontos_gate] not green"; tail "$T/run1.txt"; exit 6; }
grep -q "ontos_dokimasia_selfprove = 0" "$T/run1.txt" || { echo "[ontos_gate] DOKIMASIA arm absent or red -- the oracle assay is not wired"; tail "$T/run1.txt"; exit 7; }

# --- DOKIMASIA CLI: the assay as a compiled verb (consumers: the MCP swap, the separation rig) ---
cc_one "$ROOT/STDLIB/iii/omnia/dokimasia_cli.iii" "$T/dokimasia_cli.o" || exit 2
rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/dokimasia_cli.exe"
    gcc -o "$T/dokimasia_cli.exe" "$T/dokimasia_cli.o" "$T/ontos.o" "$T/eidolos.o" "$T/isub.o" "$T/idfold.o" "$T/bounty_attest.o" "$T/kardia.o" "$T/ptyxis.o" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/dk_link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/dokimasia_cli.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[ontos_gate] DOKIMASIA CLI LINK FAIL rc=$rc"; tail -8 "$T/dk_link.log"; exit 3; }
DK="$T/dokimasia_cli.exe"
"$DK" "11110000" > "$T/dk1.txt" 2>&1; [ $? -eq 0 ] || { echo "[ontos_gate] separator not HEARD"; cat "$T/dk1.txt"; exit 8; }
"$DK" "11111111" > "$T/dk2.txt" 2>&1; [ $? -eq 1 ] || { echo "[ontos_gate] rubber stamp not REFUSED"; cat "$T/dk2.txt"; exit 8; }
"$DK" "00000000" > "$T/dk3.txt" 2>&1; [ $? -eq 1 ] || { echo "[ontos_gate] constant refuser not REFUSED"; cat "$T/dk3.txt"; exit 8; }
"$DK" "11110000" > "$T/dk4.txt" 2>&1
cmp -s "$T/dk1.txt" "$T/dk4.txt" || { echo "[ontos_gate] DOKIMASIA CLI nondeterminism"; exit 8; }
grep -q "image=2 bits=1 admissible=1" "$T/dk1.txt" || { echo "[ontos_gate] wrong assay numbers"; cat "$T/dk1.txt"; exit 8; }
echo "[ontos_gate] DOKIMASIA CLI: separator HEARD (exit 0), both constant maps REFUSED (exit 1), deterministic."

echo "[ontos_gate] THE ONE LAW JUDGES THE PRIMITIVES -- green + byte-deterministic:"
cat "$T/run1.txt"
exit 0
