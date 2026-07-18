#!/usr/bin/env bash
# summit_gate.sh -- THE SUMMIT RITE: the two capstone theorems, re-derived
# from clean objects every run and sealed as EIDOLOS scrolls.
#
# The gate compiles the whole ascent with the IN-TREE compiler -- pyrgos (the
# constructible tower + the complex closure), riza (the real-closed engine),
# meris (Nekrasov localization), klisi (the perfectoid tilt), eidolos (the
# scroll) and summit (the composition) -- links the probe, and demands:
#   1. every organ battery GREEN (pyrgos 180..195, riza 210..217,
#      kyma 230..241 [Bell/CHSH emerged + Born selected by basis-invariance +
#      Kochen-Specker: the Peres-Mermin square's six operator identities
#      derived with emergent signs, 512-valuation enumeration ZERO/ceiling-5],
#      meris 250..254 [+ the Faulhaber/Stirling power-sum mint],
#      klisi 260..266 [+ the Hensel/Newton inverse faculty],
#      summit 280..285, gnosis 290..299 [+ the CHRONOMETER: arrival counts
#      and total work minted O(1) from the orbit oracle's decisions, and the
#      DIVISION BRIDGE: the live planner + Montgomery kernel on the
#      substrate identity],
#      noesis 300..306 [THE THERMODYNAMIC METER: deficit = valuation by
#      complete w=8 saturation; odd multipliers zero-heat (inverse-witnessed);
#      the chronometer's work RECOVERABLE ACTION; fold-deficit invariance
#      across every certified SR family; the law sealed as a scroll; and
#      THE WORLDS: all 19683 binary operations on the 3-carrier classified
#      -- reversibility = zero deficit = eternal return at every world,
#      latin purchases recurrence, the two group definitions coincide with
#      the three labeled groups forced, absorption purchases collapse,
#      association purchases fold freedom; censuses by two engines; the
#      purchase theorems sealed as the worlds scroll],
#      mneme 310..314 [THE ASSOCIATIVE MANIFOLD: 64-lane closure folded
#      from an append-only edge log, extent columns making the conjunctive
#      concept-fetch ONE AND; Warshall vs BFS two-engine equality; log-order
#      invariance; the four sealed laws registered LIVE and cross-checked
#      pair-by-pair against eidolos; dropped-edge teeth; the manifold law
#      sealed as a scroll],
#      katoptron 320..324 [THE MIRROR GATE: reduction-hom + valuation
#      truncation complete at the byte ring; shadow decides / substrate
#      confirms over every byte-class with klisi witnesses at w=64; the
#      decl-wall / slot-ceiling pre-flight meter proven exact on generated
#      corpora spanning both boundaries; the mirror economy strictly cheaper
#      with zero wrongful prunes; the lying mirror caught; the mirror law
#      sealed as a scroll],
#      synesis 330..339 [THE KNOWING-TOGETHER: eight organ testimonies
#      convened side by side into ONE coherent scroll with one address;
#      the cross-organ SURPLUS derived (theorems no single testimony
#      entails -- deficit = orbit_decision, work_total = faulhaber_mint,
#      born_rule = forced_exponent, tower_element < algebraic_number, ...)
#      under the complete 8-drop knockout matrix; the province map and the
#      six-word shared vocabulary derived; THE FRONTIER: the machine
#      counts its own unknown pairs; THE ABDUCTION: the complete
#      single-claim bridge set for the named gap; THE DISCHARGE: the
#      bridge DECIDED by noesis's meter (true spoken, false refuted,
#      undecidable counted), the union re-derived knowing more, the
#      frontier shrinking monotonically by exactly the closed pairs; the
#      why-chains of two surplus theorems reconstructed and length-checked
#      by a second engine; the union's witness carrying strictly more
#      geometry than any single testimony; the synesis law sealed as a
#      scroll; and THE DIALECTIC (arms 340..345): a DECIDER FLEET -- kyma
#      running the circuits (hzh = x, ss = z, xx = i, global phase exact),
#      meris running both partition engines, pyrgos running the tower sign
#      (the denesting), klisi walking its digits, noesis metering images,
#      and the JOINT domain demanding two organs agree ([mul 48 = depth 4]:
#      image-deficit 4 AND digit-depth 4) -- walking the whole frontier,
#      speaking a minimal ledger of decided truths, re-deriving the union
#      to a new deterministic name, monotone, and proving the FIXPOINT:
#      the fleet exhausted, the residue undecided-only; the dialectic law
#      sealed as a scroll; and THE HARVEST (arms 346..347): the machine
#      AUTHORS its own knowledge space -- the CAYLEY CHART (all 85 gate
#      words of length <= 3 pairwise decided by running circuits, the 32
#      operator classes EMERGING, congruence complete over 3570 pairs,
#      eidolos co-signing the partition, sealed as a sharded scroll) and
#      the KEYSTONE SWEEP (deficit = valuation for EVERY multiplier byte
#      by two-organ agreement, the dyadic histogram 127/64/32/16/8/4/2/1
#      derived -- the halving law of Z_2 at byte scale, sealed)]);
#   2. THEOREM I (the algebraic node): the crushing contact decided as an
#      exact node -- multiplicity by TWO engines (real-closed gcd with
#      reconstruction vs the 5-adic valuation slope), the contact
#      trichotomy, the product formula's place ledger, the tilt ledger
#      finite and distinct THROUGH the r=0 point;
#   3. THEOREM II (the forced Born weight): entanglement decided, the
#      complete 16-orbit of boolean assignments derived and EXCEEDED by
#      exact sign (Tsirelson 2*sqrt2 met exactly, two correlator engines),
#      the Born exponent surfaced as the UNIQUE basis-invariant weight,
#      the Bell probabilities forced by symmetry + null-weight;
#   4. the two EIDOLOS scrolls sealed with DETERMINISTIC canonical
#      addresses, entailing consequences absent from their text and
#      refusing the reversals;
#   5. the whole rite BYTE-DETERMINISTIC (two runs, one transcript).
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/summit"
K="$ROOT/STDLIB/build/kinesis"
mkdir -p "$T"

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent
    local src="$1" out="$2" try
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[summit_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[summit_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -4 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/aether/pyrgos.iii"  "$T/pyrgos.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/aether/kyma.iii"    "$T/kyma.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/riza.iii"    "$T/riza.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/meris.iii"   "$T/meris.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/aether/klisi.iii"   "$T/klisi.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"  "$T/eidolos.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/summit.iii"   "$T/summit.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/gnosis.iii"   "$T/gnosis.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/noesis.iii"   "$T/noesis.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/mneme.iii"    "$T/mneme.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/katoptron.iii" "$T/katoptron.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/synesis.iii"  "$T/synesis.o" || exit 2
cc_one "$K/hzprobe_main.iii"                 "$T/hzprobe_main.o" || exit 2

gcc -o "$T/hzprobe.exe" \
    "$T/riza.o" "$T/pyrgos.o" "$T/kyma.o" "$T/meris.o" "$T/klisi.o" "$T/summit.o" "$T/gnosis.o" "$T/noesis.o" "$T/mneme.o" "$T/katoptron.o" "$T/synesis.o" "$T/eidolos.o" \
    "$K/sqrt_sum_sign.o" "$K/kfield.o" "$K/arena.o" "$K/bigint.o" "$K/bigint_div.o" "$K/sha256.o" \
    "$T/hzprobe_main.o" \
    "$ROOT/STDLIB/build/iii/libiii_native.a" -lws2_32 -lkernel32 \
    || { echo "[summit_gate] LINK FAIL"; exit 3; }

"$T/hzprobe.exe" all > "$T/run1.txt" 2>&1
rc1=$?
"$T/hzprobe.exe" all > "$T/run2.txt" 2>&1
rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[summit_gate] BATTERY RED rc1=$rc1 rc2=$rc2"
    tail -6 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[summit_gate] NONDETERMINISM"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi
grep -q "^scroll gravity = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO GRAVITY SCROLL"; exit 6; }
grep -q "^scroll born    = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO BORN SCROLL"; exit 6; }
grep -q "^scroll gnosis  = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO GNOSIS SCROLL"; exit 6; }
grep -q "^scroll noesis  = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO NOESIS SCROLL"; exit 6; }
grep -q "^scroll worlds  = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO WORLDS SCROLL"; exit 6; }
grep -q "^scroll mneme   = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO MNEME SCROLL"; exit 6; }
grep -q "^scroll mirror  = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO MIRROR SCROLL"; exit 6; }
grep -q "^scroll synesis = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO SYNESIS SCROLL"; exit 6; }
grep -q "^scroll union   = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO UNION SCROLL"; exit 6; }
grep -q "^scroll dialect = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO DIALECTIC SCROLL"; exit 6; }
grep -q "^scroll cayley  = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO CAYLEY SCROLL"; exit 6; }
grep -q "^scroll sweep   = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO SWEEP SCROLL"; exit 6; }
grep -q "^the union knows: surplus=" "$T/run1.txt" || { echo "[summit_gate] NO UNION REPORT"; exit 6; }
grep -q "^the dialectic: spoke=" "$T/run1.txt" || { echo "[summit_gate] NO DIALECTIC REPORT"; exit 6; }
grep -q "^the cayley chart: words=85 classes=32 " "$T/run1.txt" || { echo "[summit_gate] NO CAYLEY CHART"; exit 6; }

# THE MIRROR ON REAL TISSUE: the pre-flight meter walks two live organ
# sources; grep is the independent second engine on the greppable dimensions
# (top-level decls and fn definitions -- both count line-anchored keywords).
for nm in noesis katoptron; do
    SRC="$ROOT/STDLIB/iii/omnia/$nm.iii"
    "$T/hzprobe.exe" preflight "$SRC" > "$T/pf_$nm.txt" 2>&1 \
        || { echo "[summit_gate] PREFLIGHT RED $nm"; cat "$T/pf_$nm.txt"; exit 7; }
    PD=$(grep -oE 'decls=[0-9]+' "$T/pf_$nm.txt" | head -1 | cut -d= -f2)
    PF=$(grep -oE 'fns=[0-9]+' "$T/pf_$nm.txt" | head -1 | cut -d= -f2)
    GD=$(grep -cE '^(fn|var|const|extern) ' "$SRC")
    GF=$(grep -cE '^fn ' "$SRC")
    if [ "$PD" != "$GD" ] || [ "$PF" != "$GF" ]; then
        echo "[summit_gate] MIRROR-GREP DISAGREE $nm: meter d=$PD f=$PF grep d=$GD f=$GF"
        exit 7
    fi
    echo "[summit_gate] preflight $nm: $(cat "$T/pf_$nm.txt")"
done
echo "[summit_gate] THE SUMMIT IS GREEN -- all scrolls sealed, byte-deterministic:"
grep "^scroll" "$T/run1.txt"
exit 0
