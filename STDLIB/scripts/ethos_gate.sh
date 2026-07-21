#!/usr/bin/env bash
# ethos_gate.sh -- THE DISCIPLINE RITE, re-derived from clean objects every run.
#
# ETHOS (omnia/ethos.iii) is the callable form of DOCS/III-ETHOS-DEVELOPMENT-DISCIPLINE.md. It asserts the
# seven KEEP-laws through their LIVE enforcement primitives (the MANTIS firewall reach_oracle_admit_canonical,
# the ONTOS count-law ont_degrades/ont_verb, the EIDOLOS seat eol_*), adjudicates the three REJECT-traits to
# REFUSED two independent ways each, and proves the three refusals are ONE forgery -- a claim to a standing
# not earned. No new language, no new tool: it CALLS mantis (the wall), ontos (the refusal), eidolos (the
# judge). Exit 0 = green + byte-deterministic.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/ethos"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
[ -x "$IIIS" ] || { echo "[ethos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[ethos_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[ethos_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[ethos_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -12 "$out.log"; return 1
}

# ethos.o FIRST so its main wins under --allow-multiple-definition (ontos also carries a main).
cc_one "$ROOT/STDLIB/iii/omnia/ethos.iii"          "$T/ethos.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/ontos.iii"          "$T/ontos.o"          || exit 2   # ont_degrades / ont_verb -- the count-law
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"        "$T/eidolos.o"        || exit 2   # the ONE seat of judgment
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"           "$T/isub.o"           || exit 2   # eidolos folds through newer isub_*
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"        "$T/idfold.o"         || exit 2   # the identity seat
cc_one "$ROOT/STDLIB/iii/aether/bounty_attest.iii" "$T/bounty_attest.o"  || exit 2   # ontos dep (grace signature)
cc_one "$ROOT/STDLIB/iii/katabasis/kardia.iii"     "$T/kardia.o"         || exit 2   # ontos dep (live registry)
cc_one "$ROOT/STDLIB/iii/omnia/ptyxis.iii"         "$T/ptyxis.o"         || exit 2   # ontos dep (the fold)
cc_one "$ROOT/STDLIB/iii/aether/reach_oracle.iii"  "$T/reach_oracle.o"   || exit 2   # the DEFAULT-DENY firewall
cc_one "$ROOT/STDLIB/iii/numera/cad.iii"           "$T/cad.o"            || exit 2   # reach_oracle dep (content-address)
cc_one "$ROOT/STDLIB/iii/omnia/horos.iii"          "$T/horos.o"          || exit 2   # THE TRAIT WITNESS: the boundary-stones
cc_one "$ROOT/STDLIB/iii/omnia/praxis.iii"         "$T/praxis.o"         || exit 2   # THE TRAIT WITNESS: the trace judge
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii"      "$T/exec_cert.o"      || exit 2   # praxis dep (the tamper-evident fold)

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/ethos.exe"
    gcc -o "$T/ethos.exe" "$T/ethos.o" "$T/ontos.o" "$T/eidolos.o" "$T/isub.o" "$T/idfold.o" "$T/bounty_attest.o" "$T/kardia.o" "$T/ptyxis.o" "$T/reach_oracle.o" "$T/cad.o" "$T/horos.o" "$T/praxis.o" "$T/exec_cert.o" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/ethos.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[ethos_gate] LINK FAIL rc=$rc"; tail -18 "$T/link.log"; exit 3; }

STG="$T/ethos_run.exe"
cp "$T/ethos.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?
cp "$T/ethos.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] || { echo "[ethos_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -18 "$T/run1.txt"; exit 4; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[ethos_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "GREEN" "$T/run1.txt" || { echo "[ethos_gate] not green"; tail "$T/run1.txt"; exit 6; }
grep -q "ethos_witness_selfprove = 0" "$T/run1.txt" || { echo "[ethos_gate] THE TRAIT WITNESS absent or red -- the profile claim is unwitnessed"; tail "$T/run1.txt"; exit 7; }

echo "[ethos_gate] THE DISCIPLINE JUDGES ITSELF -- green + byte-deterministic:"
cat "$T/run1.txt"
exit 0
