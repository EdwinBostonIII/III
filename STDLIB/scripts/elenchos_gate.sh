#!/usr/bin/env bash
# elenchos_gate.sh -- THE REFUTATION RITE: re-derived from clean objects every run.
#
# ELENCHOS (omnia/elenchos.iii) is the ZK under-constraint engine over the REAL BN254 scalar
# field r (the field circom/snarkjs use).  The #1 ZK-circuit vulnerability is UNDER-CONSTRAINT:
# the constraint system fails to uniquely determine the witness, so a malicious prover forges an
# accepted proof.  Over the field this IS the fold: A under-constrained <=> rank(A) < #witness
# vars <=> ker(A) != 0 <=> a nullspace vector w0 with A*w0 = 0.  ELENCHOS produces that w0 -- the
# Socratic refutation -- via exact modular Gaussian elimination (III bigint, Fermat inverse), and
# VERIFIES it against the UNTOUCHED original matrix (non-circular).
#
# This rite compiles ELENCHOS with the IN-TREE compiler (composing only numera/bigint(+div) +
# memoria/arena, all in libiii_native.a), links its own probe main, and demands:
#   1. THE ENGINE GREEN (elenchos_selfprove = 0): CASE 1 an under-constrained circuit is detected
#      AND its forgery verified over real BN254; CASE 2 a sound circuit stays silent; CASE 3 the
#      TEETH -- dropping the binding row flips a sound circuit back to forgeable (no vacuous pass).
#   2. THE LIVE DEMO prints the refutation of the under-constrained BN254 circuit end to end.
#   3. The whole rite BYTE-DETERMINISTIC (two runs, one transcript) -- exactness has no epsilon.
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/elenchos"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[elenchos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[elenchos_gate] no archive: $ARC (run build_stdlib.sh)"; exit 2; }

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent (the settle-retry law)
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[elenchos_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[elenchos_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -6 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/elenchos.iii" "$T/elenchos.o" || exit 2

# link the probe (elenchos's own main is the sole global main; deps resolve from the archive).
# stage the exe under build/ (OneDrive-watched); the run is staged to /tmp below (AV exec policy).
rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/elenchos.exe"
    gcc -o "$T/elenchos.exe" "$T/elenchos.o" "$ARC" -lws2_32 -lkernel32 > "$T/link.log" 2>&1
    rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/elenchos.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[elenchos_gate] LINK FAIL rc=$rc (after 5 lock-retries)"; tail -6 "$T/link.log"; exit 3; }

# stage outside the OneDrive-watched tree (Defender exec-policy hardening, per run_corpus.sh)
STG="/tmp/elenchos_$$_$RANDOM.exe"

# 1. THE CONDITION OF MOTION + 3. DETERMINISM: run the self-proving probe twice.
cp "$T/elenchos.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?; rm -f "$STG"
cp "$T/elenchos.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[elenchos_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2 (elenchos_selfprove != 0)"
    tail -8 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[elenchos_gate] NONDETERMINISM"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi

# 2. THE LIVE REFUTATION + GREEN VERDICT.  Text-ROBUST greps (the organ's demo text is under active
#    co-development -- the ingester's exact wording churns): the load-bearing gate is exit 0 + byte
#    determinism above; here we require only stable invariants -- the real BN254 field is named and a
#    refutation verdict is reached.  (If a co-writer's WIP has the organ mid-refactor, exit != 0 above
#    already fails this rite with SELF-REFUSED -- correctly RED until their edits settle.)
grep -q "BN254" "$T/run1.txt" \
    || { echo "[elenchos_gate] no BN254 field named"; tail -8 "$T/run1.txt"; exit 6; }
grep -q "soundness refuted" "$T/run1.txt" \
    || { echo "[elenchos_gate] no refutation verdict"; tail -8 "$T/run1.txt"; exit 6; }

echo "[elenchos_gate] THE REFUTATION IS GREEN -- under-constraint detected + forgery verified over real BN254, byte-deterministic:"
grep -Ei "under-constrained|refuted" "$T/run1.txt" | head -3
exit 0
