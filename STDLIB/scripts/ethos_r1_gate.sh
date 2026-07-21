#!/usr/bin/env bash
# ethos_r1_gate.sh -- THE BEHAVIORAL WITNESS RITE: the trait-witness seat pointed at the
# digested R1, through the wall.  Re-derived from clean sources every run.
#
# The trait witness (ethos.iii, THE TRAIT WITNESS 88956ad6) made the PROFILE a measured
# claim against III's own live law.  This rite swaps the answerer to the model itself:
#
#   THE PURE LAW (always, no Feast) -- ethos_r1_selfprove.  The COMPOSITION this probe
#     adds (assay + anti-commutation + EIDOLOS seal + the DEFAULT-DENY wall + the PRAXIS
#     judgment) proven over a GIVEN order pair, with a MANDATORY NEGATIVE: a broken
#     frame-insensitive answerer (does not anti-commute) is CAUGHT, and the constant
#     forgery is refused by DOKIMASIA.  This is the gate's clean-checkout teeth -- the
#     engines that PRODUCE the order are separately gated in summit_gate (probole arms
#     31-38, two engines agree / a forged engine caught).
#
#   THE REAL WALK (only when the Feast is on the table) -- the live 671B forward pass
#     decides R1's real head order (token 24792 over 1925) by two independent exact
#     engines, seals it in EIDOLOS, and renders the whole verdict against the model:
#     MEASURED IS NOT INSTALLED.  Feast-gated in the fail-open idiom of summit_gate.
#
# Exit 0 = the law stands (green + byte-deterministic), and -- if the Feast is present --
# the real model bears the verdict.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/ethos_r1"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
PROBE="$ROOT/STDLIB/build/mantis/ethos_r1_probe.iii"
mkdir -p "$T"
[ -x "$IIIS" ] || { echo "[ethos_r1_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ]  || { echo "[ethos_r1_gate] no archive: $ARC"; exit 2; }
[ -f "$PROBE" ] || { echo "[ethos_r1_gate] no probe: $PROBE"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[ethos_r1_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[ethos_r1_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -12 "$out.log"; return 1
}

# the probe main FIRST so it wins under --allow-multiple-definition (several deps carry a main).
cc_one "$PROBE"                                       "$T/ethos_r1_probe.o" || exit 2
# the exact-order membrane (6acd3abe)
cc_one "$ROOT/STDLIB/iii/omnia/probole.iii"           "$T/probole.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/metabole.iii"          "$T/metabole.o"       || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/mantis.iii"            "$T/mantis.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/numera/krisis.iii"           "$T/krisis.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/peras.iii"             "$T/peras.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"           "$T/eidolos.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"              "$T/isub.o"           || exit 2
# the seat's own law (assay / wall / judge)
cc_one "$ROOT/STDLIB/iii/omnia/ontos.iii"             "$T/ontos.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"           "$T/idfold.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/katabasis/kardia.iii"        "$T/kardia.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/ptyxis.iii"            "$T/ptyxis.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/aether/bounty_attest.iii"    "$T/bounty_attest.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/aether/reach_oracle.iii"     "$T/reach_oracle.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/numera/cad.iii"              "$T/cad.o"            || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/horos.iii"             "$T/horos.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/praxis.iii"            "$T/praxis.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii"         "$T/exec_cert.o"      || exit 2
# the exact substrate (compiled from source -- no dependence on prebuilt build/kinesis objects)
cc_one "$ROOT/STDLIB/iii/memoria/arena.iii"           "$T/arena.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/numera/bigint.iii"           "$T/bigint.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/numera/bigint_div.iii"       "$T/bigint_div.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/aether/sqrt_sum_sign.iii"    "$T/sqrt_sum_sign.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/aether/kfield.iii"           "$T/kfield.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/numera/sha256.iii"           "$T/sha256.o"         || exit 2

# an ARRAY, not a space-joined string: $ROOT lives under a path with a space
# ("Edwin Boston"), and an unquoted string would word-split every object path.
OBJS=(
    "$T/ethos_r1_probe.o" "$T/probole.o" "$T/metabole.o" "$T/mantis.o" "$T/krisis.o" "$T/peras.o"
    "$T/eidolos.o" "$T/isub.o" "$T/ontos.o" "$T/idfold.o" "$T/kardia.o" "$T/ptyxis.o" "$T/bounty_attest.o"
    "$T/reach_oracle.o" "$T/cad.o" "$T/horos.o" "$T/praxis.o" "$T/exec_cert.o"
    "$T/arena.o" "$T/bigint.o" "$T/bigint_div.o" "$T/sqrt_sum_sign.o" "$T/kfield.o" "$T/sha256.o"
)

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/ethos_r1.exe"
    gcc -o "$T/ethos_r1.exe" "${OBJS[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/ethos_r1.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[ethos_r1_gate] LINK FAIL rc=$rc"; tail -18 "$T/link.log"; exit 3; }

# --- THE PURE LAW: no Feast, always has teeth, byte-deterministic ------------
STG="$T/ethos_r1_run.exe"
cp "$T/ethos_r1.exe" "$STG"; "$STG" > "$T/pure1.txt" 2>&1; p1=$?
cp "$T/ethos_r1.exe" "$STG"; "$STG" > "$T/pure2.txt" 2>&1; p2=$?
[ "$p1" -eq 0 ] && [ "$p2" -eq 0 ] || { echo "[ethos_r1_gate] PURE LAW REFUSED p1=$p1 p2=$p2"; tail -6 "$T/pure1.txt"; rm -f "$STG"; exit 4; }
cmp -s "$T/pure1.txt" "$T/pure2.txt" || { echo "[ethos_r1_gate] PURE NONDETERMINISM"; diff "$T/pure1.txt" "$T/pure2.txt" | head; rm -f "$STG"; exit 5; }
grep -q "^ethos_r1_selfprove = 0" "$T/pure1.txt" || { echo "[ethos_r1_gate] PURE LAW NOT GREEN"; tail "$T/pure1.txt"; rm -f "$STG"; exit 6; }
echo "[ethos_r1_gate] THE LAW: $(head -1 "$T/pure1.txt")"

# --- THE REAL WALK: only when the Feast is on the table (fail-open) ----------
if [ -d "$ROOT/Feast" ] && ls "$ROOT/Feast"/*.gguf >/dev/null 2>&1; then
    echo "[ethos_r1_gate] Feast present -- walking the real R1 (token 24792 vs 1925, lo=12)"
    cp "$T/ethos_r1.exe" "$STG"; "$STG" 24792 1925 1 12 > "$T/real1.txt" 2>&1; r1=$?
    cp "$T/ethos_r1.exe" "$STG"; "$STG" 24792 1925 1 12 > "$T/real2.txt" 2>&1; r2=$?
    [ "$r1" -eq 0 ] && [ "$r2" -eq 0 ] || { echo "[ethos_r1_gate] REAL WALK REFUSED r1=$r1 r2=$r2"; tail -12 "$T/real1.txt"; rm -f "$STG"; exit 7; }
    cmp -s "$T/real1.txt" "$T/real2.txt" || { echo "[ethos_r1_gate] REAL NONDETERMINISM"; diff "$T/real1.txt" "$T/real2.txt" | head; rm -f "$STG"; exit 8; }
    grep -q "^the order: trusted(24792,1925) = 1   trusted(1925,24792) = -1" "$T/real1.txt" || { echo "[ethos_r1_gate] ORDER NOT DECIDED/ANTI-COMMUTING"; tail "$T/real1.txt"; rm -f "$STG"; exit 8; }
    grep -q "^the assay: real map {1,0} image=2 -> HEARD   constant forgery {1,1} -> REFUSED" "$T/real1.txt" || { echo "[ethos_r1_gate] ASSAY DID NOT SEPARATE"; tail "$T/real1.txt"; rm -f "$STG"; exit 8; }
    grep -q "witness addr = 5743271528433377647" "$T/real1.txt" || { echo "[ethos_r1_gate] SEAL ADDR DRIFTED (expected the recorded pure-gate address)"; tail "$T/real1.txt"; rm -f "$STG"; exit 8; }
    grep -q "^the wall: oracle-tier map -> REFUSED canonical" "$T/real1.txt" || { echo "[ethos_r1_gate] WALL DID NOT REFUSE THE ORACLE MAP"; tail "$T/real1.txt"; rm -f "$STG"; exit 8; }
    grep -q "^VERDICT: measured is not installed" "$T/real1.txt" || { echo "[ethos_r1_gate] VERDICT ABSENT"; tail "$T/real1.txt"; rm -f "$STG"; exit 8; }
    rm -f "$STG"
    echo "[ethos_r1_gate] THE BEHAVIORAL WITNESS STANDS ON THE REAL MODEL -- byte-deterministic:"
    cat "$T/real1.txt"
    exit 0
fi

rm -f "$STG"
echo "[ethos_r1_gate] Feast absent -- the pure law stands (the real walk skips, fail-open):"
cat "$T/pure1.txt"
exit 0
