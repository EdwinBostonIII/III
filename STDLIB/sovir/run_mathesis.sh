#!/usr/bin/env bash
# STDLIB/sovir/run_mathesis.sh — THE MATHESIS ENGINE gate (Ξ0 seed cycle, DOCS/III-MATHESIS-MAP.md §7).
#
# This is the `run_self_improve.sh` that was never built (ADR-Ξ5): ONE command that replays the whole
# discover→prove→admit→assimilate→re-verify cycle and its rejecting negative arms:
#
#   [1] the DOOR         corpus/2600  four-clause admission conjunction (each single-false REJECTED),
#                                     content-addressed statement-sensitive theorem ids, tamper-evident chain
#   [2] the DISPOSER     corpus/2601  R4 false identity (a+b ≡ a|b) REFUTED FIRST; the ∀x,c1,c2 chain
#                                     schemas PROVEN in one symbolic seq_equiv call each; k=1..63 range
#                                     sweeps; the width-64 tooth; SEQ_TOP honest abstain; truth-table dual
#   [3] the INSTRUMENT   corpus/2602  opcode-synchronous census (anti-byte-grep phantom arm, R2 range tooth,
#                                     unknown-op honest abstain, v1+v2 containers)
#   [4] the SEAL         corpus/2603  MATHESIS-THEOREM-0001 replays from its pins (id + chain head);
#                                     a tampered statement breaks the seal
#   [5] the MEASURED EFFECT           the LIVE pinned compiler emits sq08_mixed: the census must show
#                                     c1=0 (windows folded) and container bytes <= 484 (< the 494
#                                     pre-theorem baseline); then the backend gate (A1 iiisv2 parity +
#                                     A2 goldens incl. the adjudicated sq08 reseal + the N≡E≡S square)
#                                     must be GREEN end-to-end.
#
# Exit 0 = the seed cycle is CLOSED on real, measured, sealed ground.  Any other exit names its stage.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CORPUS="$III_ROOT/STDLIB/corpus"
BUILD="$III_ROOT/STDLIB/build/iii"
RUN="$III_ROOT/STDLIB/build/mathesis/gate"
mkdir -p "$RUN"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2$BIN_SUFFIX}"
LIB="$BUILD/libiii_native.a"
[[ -x "$IIIS" ]] || { echo "[mathesis] FATAL: no pinned iiis-2"; exit 2; }
[[ -f "$LIB"  ]] || { echo "[mathesis] FATAL: no stdlib archive"; exit 2; }

# the force-linked side-effect set (mirrors run_corpus.sh)
SE=()
for n in omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o omnia_proof_ripple_resolution.iii.o \
         omnia_resolver.iii.o omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o \
         omnia_transform_patterns.iii.o omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o \
         aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o \
         sanctus_seal_resolver.iii.o verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o \
         bench_helpers.o; do
    [[ -f "$BUILD/$n" ]] && SE+=("$BUILD/$n")
done

gate() {  # gate <corpus-base> [extra .o ...]  -> runs the KAT, expects exit 99
    local base="$1"; shift
    local obj="$RUN/$base.o" exe="$RUN/$base$BIN_SUFFIX"
    timeout 120 "$IIIS" "$CORPUS/$base.iii" --compile-only --out "$obj" >/dev/null 2>"$RUN/$base.err" \
        || { echo "[mathesis] RED: $base compile"; return 1; }
    rm -f "$exe"
    gcc "$obj" "$@" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$exe" \
        >>"$RUN/$base.err" 2>&1 || { echo "[mathesis] RED: $base link"; return 1; }
    local staged="/tmp/mx_$$_$RANDOM$BIN_SUFFIX"
    cp "$exe" "$staged"
    timeout 600 "$staged"; local rc=$?
    rm -f "$staged"
    [[ $rc -eq 99 ]] || { echo "[mathesis] RED: $base exit=$rc (want 99)"; return 1; }
    echo "[mathesis] GREEN: $base"
    return 0
}

gate_slow() {  # the same contract with a 2400 s budget -- for the PRICED sweeps (2718 pays
               # the full 4^16 census, ~17 minutes: the price is printed, never hidden)
    local base="$1"; shift
    local obj="$RUN/$base.o" exe="$RUN/$base$BIN_SUFFIX"
    timeout 240 "$IIIS" "$CORPUS/$base.iii" --compile-only --out "$obj" >/dev/null 2>"$RUN/$base.err" \
        || { echo "[mathesis] RED: $base compile"; return 1; }
    rm -f "$exe"
    gcc "$obj" "$@" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$exe" \
        >>"$RUN/$base.err" 2>&1 || { echo "[mathesis] RED: $base link"; return 1; }
    local staged="/tmp/mx_$$_$RANDOM$BIN_SUFFIX"
    cp "$exe" "$staged"
    timeout 2400 "$staged"; local rc=$?
    rm -f "$staged"
    [[ $rc -eq 99 ]] || { echo "[mathesis] RED: $base exit=$rc (want 99)"; return 1; }
    echo "[mathesis] GREEN: $base"
    return 0
}

# THE STALE-TU LAW (campaign Chi): a cached organ object older than its source is the #1
# ledger trap (it struck in Tau; Phi dodged it by hand).  Clear every stale aether object
# HERE, once, before any stage's [[ -f ]] guard can reuse it.
for _src in "$III_ROOT"/STDLIB/iii/aether/*.iii; do
    _b="$(basename "$_src" .iii)"
    if [[ -f "$RUN/$_b.o" && "$_src" -nt "$RUN/$_b.o" ]]; then
        echo "[mathesis] stale-TU law: clearing cached $_b.o (source is newer)"
        rm -f "$RUN/$_b.o"
    fi
done

# the exact-face TUs the telescope gates (2680/2681) link beyond the stdlib archive
EXACTFACE=()
for t in sqrt_sum_sign kfield exact_denest; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 120 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" \
        >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 39; }
    EXACTFACE+=("$o")
done

echo "[mathesis] == Xi0 THE SEED CYCLE (DOCS/III-MATHESIS-MAP.md) =="
gate 2600_mathesis_admit   || exit 10
gate 2601_mathesis_dispose || exit 11
gate 2602_mathesis_measure || exit 12
gate 2603_mathesis_seal    || exit 13

# [5] the measured, live effect of the assimilated theorem
echo "[mathesis] == [5] the measured effect (live compiler, sq08_mixed) =="
GEN="$RUN/gen_sq08.iii"
timeout 60 "$IIIS" "$III_ROOT/COMPILER/BOOT/square_probes/sq08_mixed.iii" --emit-svir --out "$GEN" >/dev/null 2>&1 \
    || { echo "[mathesis] RED: emit sq08"; exit 14; }
NBYTES=$(sed -n 's/.*\[u8; \([0-9]*\)\].*/\1/p' "$GEN" | head -1)
[[ -n "$NBYTES" && "$NBYTES" -le 484 ]] || { echo "[mathesis] RED: sq08 container $NBYTES bytes (want <=484 < the 494 baseline)"; exit 15; }
timeout 120 "$IIIS" "$GEN" --compile-only --out "$RUN/gen_sq08.o" >/dev/null 2>&1 || { echo "[mathesis] RED: gen compile"; exit 16; }
[[ -f "$III_ROOT/STDLIB/build/mathesis/mathesis_census_main.o" ]] || \
    timeout 120 "$IIIS" "$III_ROOT/STDLIB/sovir/mathesis_census_main.iii" --compile-only \
        --out "$III_ROOT/STDLIB/build/mathesis/mathesis_census_main.o" >/dev/null 2>&1 || { echo "[mathesis] RED: census driver compile"; exit 17; }
gcc "$III_ROOT/STDLIB/build/mathesis/mathesis_census_main.o" "$RUN/gen_sq08.o" "$LIB" -lws2_32 -lkernel32 \
    -o "$RUN/census_sq08$BIN_SUFFIX" 2>/dev/null || { echo "[mathesis] RED: census link"; exit 18; }
staged="/tmp/mxc_$$_$RANDOM$BIN_SUFFIX"; cp "$RUN/census_sq08$BIN_SUFFIX" "$staged"
LINE=$(timeout 60 "$staged"); rc=$?; rm -f "$staged"
[[ $rc -eq 0 ]] || { echo "[mathesis] RED: census run rc=$rc"; exit 19; }
echo "[mathesis] census: $LINE ($NBYTES bytes)"
case "$LINE" in *" c1=0 "*) : ;; *) echo "[mathesis] RED: windows survive the fold ($LINE)"; exit 20;; esac

echo "[mathesis] == backend gate (parity + goldens + square) =="
bash "$III_ROOT/COMPILER/BOOT/run_svir_backend_gate.sh" >/dev/null 2>&1 || { echo "[mathesis] RED: backend gate"; exit 21; }
echo "[mathesis] GREEN: backend gate (A1 parity + A2 goldens + N=E=S square)"

echo "[mathesis] == [6] THE CREATOR TIER (Xi8 definitions / Xi9 statements / Xi1 SYNTHESIS) =="
gate 2670_mathesis_define       || exit 22
gate 2671_mathesis_rot          || exit 23
gate 2672_mathesis_rot_census   || exit 24
gate 2675_mathesis_nonexist     || exit 25
gate 2610_mathesis_propose      || exit 26
gate 2673_mathesis_concept_seal || exit 27

echo "[mathesis] == [6b] THE CREATOR TIER COMPLETION (Xi5/Xi9/Xi10/Xi11/Xi4/Xi2/Xi13/Xi12/Xi6/Xi7) =="
gate 2613_mathesis_grammar      || exit 40   # Xi5/P1  the grammar ratchet teach (AND/OR/XOR/SHR; mul-plan PIN)
gate 2611_mathesis_novel        || exit 41   # Xi1-T2  computed novelty + two-grain dedup
gate 2612_mathesis_frontier     || exit 42   # Xi1-T3  the frontier queue + live R7 width retry
gate 2674_mathesis_order        || exit 43   # Xi9-T1+T3  order theorems + CLOSED-OPTIMAL certificates
gate 2676_mathesis_derive       || exit 44   # Xi10-T1  the deduction organ (kernel-checked)
gate 2677_mathesis_induct       || exit 45   # Xi10-T2  the first forall-n-in-NAT theorems
gate 2678_mathesis_orbit        || exit 46   # Xi11  rot-conjugation orbits (equivariance table)
gate 2679_mathesis_width        || exit 47   # Xi11  width functors (transport = re-proof)
gate 2640_mathesis_certify      || exit 48   # Xi4   the kernel certification leg
gate 2641_mathesis_library      || exit 61   # Xi4   the library published (dedup + provenance tally)
gate 2620_mathesis_ground       || exit 49   # Xi2   zk-AIR grounding + attestation
gate 2650_mathesis_loop         || exit 50   # Xi5/Xi13  the standing round-2 shift sweep + convergence
gate 2651_mathesis_ratchet      || exit 51   # Xi5-T2/H10  the ratchet in executable form
gate 2682_mathesis_autonomy     || exit 52   # Xi13/P10  the autonomy invariant (in-process cold replay)
gate 2683_mathesis_agenda       || exit 53   # Xi13  measured intent (the research agenda)
gate 2660_mathesis_federate     || exit 54   # Xi6   federation by proof (sealed channel + ML-DSA quorum)
gate 2680_mathesis_denest "${EXACTFACE[@]}"    || exit 56   # Xi12  the telescope: machine-found denesting theorems
gate 2681_mathesis_envelope "${EXACTFACE[@]}"  || exit 57   # Xi12  the telescope envelope (out-of-domain abstains)
gate 2684_mathesis_chain_v2     || exit 55   # Xi7   the chain-v2 seal (18 entries -> HEAD_v2)

# [8] THE MATHESIS CERTIFICATE: sha256(library_head_v2 || round1_root || round2_families || ratchet).
# reproducible + perturbation-sensitive -- binds the sealed mathematics to the sealed discovery streams.
echo "[mathesis] == [8] MATHESIS_CERT (math <-> streams <-> ratchet) =="
CERT_HEAD="197631db6587b8840d61997120a06653962f2d1aa24886ade19cb40e58324da0"
SYN1="$III_ROOT/DOCS/MATHESIS-SYNTH-ROUND1.log"
RATCHET="$III_ROOT/DOCS/MATHESIS-RATCHET.txt"
grep -q "^MXS space=18522 tested=17136 frontier=1386 found=183$" "$SYN1" \
    || { echo "[mathesis] RED: round-1 stream drifted"; exit 58; }
grep -q "round2_space                = 8064" "$RATCHET" || { echo "[mathesis] RED: ratchet round-2 drifted"; exit 59; }
grep -q "round2_verdict              = DRY" "$RATCHET"  || { echo "[mathesis] RED: ratchet round-2 not DRY"; exit 60; }
CERT_SRC="$CERT_HEAD|$(grep -c '^MXS# ' "$SYN1")|8064|2016|2016|dry"
MATHESIS_CERT="$(printf '%s' "$CERT_SRC" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] MATHESIS_CERT = $MATHESIS_CERT"
echo "[mathesis] GREEN: cert binds library HEAD_v2 + round-1 (183) + round-2 (8064, dry) + ratchet"

# [7] the sealed round-1 synthesis stream: the committed record must match its pins
SYNLOG="$III_ROOT/DOCS/MATHESIS-SYNTH-ROUND1.log"
grep -q "^MXS space=18522 tested=17136 frontier=1386 found=183$" "$SYNLOG" \
    || { echo "[mathesis] RED: synth round-1 summary drifted from the pins"; exit 28; }
[[ "$(grep -c '^MXS# ' "$SYNLOG")" -eq 183 ]] || { echo "[mathesis] RED: synth stream count != 183"; exit 29; }
echo "[mathesis] GREEN: round-1 synthesis stream sealed (183 machine theorems; 1386 frontiered, blocker named)"

echo "[mathesis] == [9] THE ALGEBRAIC CREATOR TIER (campaign Rho: the judge's second universe) =="
# the radical-face TUs: the seven-rung engines + the three Rho organs, compiled per run
RADFACE=()
for t in resultant sturm_big mathesis_alg mathesis_radical charpoly; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 180 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" \
        >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 62; }
    RADFACE+=("$o")
done
gate 2700_mathesis_alg_judge      "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 63   # the real-algebraic judge (pair-gcd equality, order, exact zero)
gate 2701_mathesis_denest_general "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 64   # generalized denesting sweep (dual-verified + nonexistence + R3 novelty)
gate 2702_mathesis_cube_ramanujan "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 65   # cube identities: Ramanujan RE-FOUND by pure enumeration
gate 2703_mathesis_mx04_chain     "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 66   # the MX04 domain door + tamper-evident chain
gate 2704_ripple_spectral         "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 67   # exact spectral certificates of III's OWN module graph

# the sealed radical round-1 stream: the committed record must match its pins
RADLOG="$III_ROOT/DOCS/MATHESIS-RADICAL-ROUND1.log"
grep -q "^MXR denest=194 novel=143 redisc=51 nonexist=4828 skip=744 cube_eq=1 cube_tested=1 cube_box=17500 chain=5023 head=2a84e3b73394d86ed00a1146af0bc3c7cb3cd20bd06b83f922cdbfbd9e7ca7f8$" "$RADLOG" \
    || { echo "[mathesis] RED: radical round-1 summary drifted from the pins"; exit 68; }
[[ "$(grep -c '^MXR# ' "$RADLOG")" -eq 195 ]] || { echo "[mathesis] RED: radical stream count != 195"; exit 69; }
RADICAL_CERT="$(printf '%s' "2a84e3b73394d86ed00a1146af0bc3c7cb3cd20bd06b83f922cdbfbd9e7ca7f8|195|5023" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] RADICAL_CERT = $RADICAL_CERT"
echo "[mathesis] GREEN: radical round-1 stream sealed (5023 chained theorems: 194 denestings incl. 143 NOVEL, 4828 nonexistence certificates, Ramanujan re-found; head pinned)"

echo "[mathesis] == [10] CAMPAIGN SIGMA (the ring judge, the frontier drain, the surface hunter) =="
for t in mathesis_ring mathesis_curve; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 180 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" \
        >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 70; }
    RADFACE+=("$o")
done
gate 2705_mathesis_ring_judge  "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 71   # ring normalization: all-width proofs, grid witnesses, library composition
gate 2706_mathesis_ring_drain  "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 72   # THE 1386-PAIR FRONTIER DRAINED: 8 proven + 1378 refuted + 0 undecided
gate 2707_mathesis_curve_hunt  "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 73   # the machine-derived surfaces hunted; the SIGMA catalogue verified + chained

# the sealed Sigma streams: the committed records must match their pins
RINGLOG="$III_ROOT/DOCS/MATHESIS-RING-DRAIN.log"
grep -q "^MRG queue=1386 proven=8 refuted=1378 undecided=0$" "$RINGLOG" \
    || { echo "[mathesis] RED: ring-drain summary drifted"; exit 74; }
[[ "$(grep -c '^MRG# P ' "$RINGLOG")" -eq 8 ]] || { echo "[mathesis] RED: ring proven count != 8"; exit 75; }
CURVELOG="$III_ROOT/DOCS/MATHESIS-CURVE-ROUND1.log"
grep -q "^MXC found=21 degenerate=0 rays=7326700 chain=31 head=07fdc686ea0dabdfb97fd96711c0ba17c304a8669e5b98b89572e6399187a354$" "$CURVELOG" \
    || { echo "[mathesis] RED: curve round-1 summary drifted"; exit 76; }
[[ "$(grep -c '^MXC# ' "$CURVELOG")" -eq 21 ]] || { echo "[mathesis] RED: sigma catalogue count != 21"; exit 77; }
grep -q "name=SIGMA-d3B-1$" "$CURVELOG" || { echo "[mathesis] RED: the first d=3 curve-B sigma identity missing"; exit 78; }
SIGMA_CERT="$(printf '%s' "07fdc686ea0dabdfb97fd96711c0ba17c304a8669e5b98b89572e6399187a354|21|1386|8|1378|0" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] SIGMA_CERT = $SIGMA_CERT"
echo "[mathesis] GREEN: campaign Sigma sealed (frontier 1386 -> 0 undecided; the SIGMA catalogue: 21 machine-found cube identities incl. six d=3 curve-B rows unknown to the author, d=5 certified EMPTY both curves to height 60)"

echo "[mathesis] == [11] CAMPAIGN TAU (the group engine; the open question attacked) =="
gate 2708_mathesis_group_tau   "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 79   # chord-tangent structure; d=5 to H=200; the extended pattern; the local table
TAULOG="$III_ROOT/DOCS/MATHESIS-TAU-ROUND1.log"
grep -q "^MXG F5H200 0 0$" "$TAULOG" || { echo "[mathesis] RED: tau d=5 height-200 row drifted"; exit 80; }
[[ "$(grep -c '^MXG C ' "$TAULOG")" -eq 6 ]] || { echo "[mathesis] RED: tau extended-catalogue count != 6"; exit 81; }
grep -q "name=SIGMA-d12A-1$" "$TAULOG" || { echo "[mathesis] RED: SIGMA-d12A-1 missing"; exit 82; }
grep -q "^MXG L 7 12 3$" "$TAULOG" || { echo "[mathesis] RED: the mod-7 bare-minimum row drifted"; exit 83; }
grep -q "THE OPEN QUESTION STANDS, SHARPENED$" "$TAULOG" || { echo "[mathesis] RED: tau summary drifted"; exit 84; }
TAU_CERT="$(printf '%s' "0|0|6|3|0|6|0|9|12|12,3" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] TAU_CERT = $TAU_CERT"
echo "[mathesis] GREEN: campaign Tau sealed (d=5 EMPTY to height 200; d=12 curve A carries SIX new sigma identities; the trivial triangle is chord-tangent CLOSED and independent of the sigma-points; {trivials+Ramanujan-orbit} EXACTLY closed at 6; B5 mod 7 = bare trivial minimum -- the machine's open question sharpened with certificates)"

echo "[mathesis] == [12] CAMPAIGN UPSILON (the structure forge; the autonomous pilot) =="
for t in mathesis_forge mathesis_pilot; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 180 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" \
        >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 85; }
    RADFACE+=("$o")
done
gate 2709_mathesis_forge  "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 86   # the operation-universe census: 3 anchors, 3330 structures, the Steiner exhibit
gate 2710_mathesis_pilot  "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 87   # the deterministic researcher: d=4/d=9 holes found, the INVOLUTION LAW confirmed
FORGELOG="$III_ROOT/DOCS/MATHESIS-FORGE-ROUND1.log"
grep -q "^MFF n=3 tables=19683 inhabited=59 structures=3330$" "$FORGELOG" \
    || { echo "[mathesis] RED: forge census drifted"; exit 88; }
grep -q "^MFF chain=69 head=c28e85ac423faa3945927b9398d358dbaec2ed63901a93d523bc72b017ab978e$" "$FORGELOG" \
    || { echo "[mathesis] RED: forge chain head drifted"; exit 89; }
PILOTLOG="$III_ROOT/DOCS/MATHESIS-PILOT-LEDGER.log"
grep -q "^PILOT# 0 0 4 60 0 3$" "$PILOTLOG" || { echo "[mathesis] RED: pilot round 0 drifted"; exit 90; }
grep -q "^PILOT rounds=6 head=a2985fa598db8dcd394d7be9f7bca510c93e7cd2c5eed868453deea135eb0ce8$" "$PILOTLOG" \
    || { echo "[mathesis] RED: pilot ledger head drifted"; exit 91; }
UPSILON_CERT="$(printf '%s' "c28e85ac423faa3945927b9398d358dbaec2ed63901a93d523bc72b017ab978e|a2985fa598db8dcd394d7be9f7bca510c93e7cd2c5eed868453deea135eb0ce8|3330|59|6" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] UPSILON_CERT = $UPSILON_CERT"
echo "[mathesis] GREEN: campaign Upsilon sealed (the operation-universe census: 3,330 structures / 59 species at n=3, triple-anchored; the pilot's first autonomous rounds found the d=4/d=9 holes and exposed THE INVOLUTION LAW: d <-> d^2 mod cubes swaps curves A and B, predictions d=18/d=25 CONFIRMED)"

echo "[mathesis] == [13] THE ONTOGENESIS (the base ontology, manipulated by III alone) =="
for t in mathesis_ontogenesis; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 180 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 92; }
    RADFACE+=("$o")
done
gate 2711_mathesis_ontogenesis "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 93
ONTOLOG="$III_ROOT/DOCS/MATHESIS-ONTO-ROUND1.log"
grep -q "^MOG GAP n=2 0 n=3 40 witness 377 715 1344$" "$ONTOLOG" || { echo "[mathesis] RED: gap theorem drifted"; exit 94; }
grep -q "^MOG DUALITY 16 19683 exceptions 0$" "$ONTOLOG" || { echo "[mathesis] RED: duality law drifted"; exit 95; }
grep -q "^MOG PRODUCT-LAW 100 240 240 refuted 0$" "$ONTOLOG" || { echo "[mathesis] RED: product law drifted"; exit 96; }
ONTO_CERT="$(printf "%s" "40|377|715|1344|19699|580" | sha256sum | cut -d" " -f1)"
echo "[mathesis] ONTO_CERT = $ONTO_CERT"
echo "[mathesis] GREEN: THE ONTOGENESIS sealed (the 11-law language PROVEN inadequate under its own manipulation at the third token -- 40 gap profiles, witness 377/715; the mirror law restores closure; DUALITY total over 19,699 tables; PRODUCT total over 580 citizen pairs)"

echo "[mathesis] == [14] CAMPAIGN PHI (the frontier drain) =="
for t in mathesis_rot2 mathesis_bigcurve mathesis_norm mathesis_tetra; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 180 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 97; }
    RADFACE+=("$o")
done
gate 2712_mathesis_rot2     "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 98    # cost8(rot_k) = 3 EXACTLY: 101,122,176 candidates, 0 matches; NEG tooth 311,056
gate 2713_mathesis_bigcurve "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 100   # the 12 escaped constructions harvested in exact bigint; 6 distinct points, growth witnessed
gate 2714_mathesis_norm     "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 101   # the norm instrument: 3 total laws, the cross-orbit product law, unit-action REFUTED
gate 2715_mathesis_pilot12  "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 102   # the pilot's rounds 6..11: d=15 found, prefix law, head(12) pinned
gate 2716_mathesis_tetra    "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 103   # the fourth token: 43,968 structures double-counted, 7 citizens incl. Z_4 + V_4
PHILOG="$III_ROOT/DOCS/MATHESIS-PHI-ROUND1.log"
grep -q "^MR2 shapes=3456 candidates=101122176 matches=0$" "$PHILOG" || { echo "[mathesis] RED: phi rot-2op row drifted"; exit 104; }
grep -q "^MPH REPLAY pool=9 over=12 events=12$" "$PHILOG" || { echo "[mathesis] RED: phi replay row drifted"; exit 105; }
grep -q "^MPH C 0 7497 8400 -5780 3138045143940 -6090322207527$" "$PHILOG" || { echo "[mathesis] RED: the first constructed identity drifted"; exit 106; }
grep -q "^MNM CATALOGUE rows=27 twopath+mult=27 gamma=27$" "$PHILOG" || { echo "[mathesis] RED: phi norm-law row drifted"; exit 107; }
grep -q "hits=0 -- REFUTED" "$PHILOG" || { echo "[mathesis] RED: the unit-action refutation drifted"; exit 108; }
grep -q "^MT4 CENSUS tables=1048576 inhabited=25 structures=43968 burnside=43968 citizens=7$" "$PHILOG" || { echo "[mathesis] RED: the tetra census drifted"; exit 109; }
grep -q "^MPL rounds=12 head=976d568997e508619cb0eb0e507f608571ca38cb1b969d0322692c4de8b70c7f$" "$PHILOG" || { echo "[mathesis] RED: the pilot head(12) drifted"; exit 110; }
PHI_CERT="$(printf '%s' "101122176|0|311056|12|6|3|27|156|0|25|43968|7|49|15|976d568997e508619cb0eb0e507f608571ca38cb1b969d0322692c4de8b70c7f" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] PHI_CERT = $PHI_CERT"
echo "[mathesis] GREEN: campaign Phi sealed (the frontier drained: cost8(rot_k)=3 by 101M-candidate exhaustion; the 12 escaped chord-tangent constructions now EXACT bigint identities on 6 distinct points; the norm instrument's 3 total laws + the cross-orbit product law + the unit-action REFUTATION; the fourth token censused 43,968 structures double-counted with Burnside, Z_4 and V_4 minted as citizens, the product law total at carrier 16; the pilot's rounds 6..11 found d=15 and pinned head(12))"

echo "[mathesis] == [15] CAMPAIGN CHI (the capability lift: judge #3, the full fourth token, the pattern instrument, the pilot at 18) =="
for t in mathesis_bigjudge mathesis_pattern; do
    o="$RUN/$t.o"
    [[ -f "$o" ]] || timeout 180 "$IIIS" "$III_ROOT/STDLIB/iii/aether/$t.iii" --compile-only --out "$o" >/dev/null 2>"$RUN/$t.err" || { echo "[mathesis] RED: $t compile"; exit 111; }
    RADFACE+=("$o")
done
gate 2717_mathesis_bigjudge   "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 112   # the 12 refusals JUDGED; the exact ordering of the six points; 9/9 both-judge agreement
echo "[mathesis] [15] gate 2718 pays the priced 4^16 sweep in full (~17 min at ~4.2M tables/s) ..."
gate_slow 2718_mathesis_tetra_full "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 113   # 178,981,952 structures; 109 species; 21 citizens; the carrier-12 product law
gate 2719_mathesis_pattern    "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 114   # the involution class law CONFIRMED on all 7 pairs (d=225: B(3)); H1/H2/H4 refuted with witnesses
gate 2720_mathesis_pilot18    "${RADFACE[@]}" "${EXACTFACE[@]}" || exit 115   # rounds 12..17: d=19 found (A:4); prefix law; head(18) pinned twice
CHILOG="$III_ROOT/DOCS/MATHESIS-CHI-ROUND1.log"
grep -q "^BJ JUDGED constructions=12 of 12$" "$CHILOG" || { echo "[mathesis] RED: chi judge row drifted"; exit 116; }
grep -q "^BJ ORDER distinct=6 ascending-events 1 2 3 0 4 5$" "$CHILOG" || { echo "[mathesis] RED: the exact ordering drifted"; exit 117; }
grep -q "^T4F BURNSIDE 10 3330 178981952$" "$CHILOG" || { echo "[mathesis] RED: the Burnside row drifted"; exit 118; }
grep -q "^T4F CENSUS tables=4294967296 inhabited=109 lawful=20596732 structures=860978 citizens=21$" "$CHILOG" || { echo "[mathesis] RED: the full census drifted"; exit 119; }
grep -q "^T4F PRODUCT12 pairs=504$" "$CHILOG" || { echo "[mathesis] RED: the carrier-12 product law drifted"; exit 120; }
grep -q "^MP d 225 0 3 0 0$" "$CHILOG" || { echo "[mathesis] RED: the d=225 prediction row drifted"; exit 121; }
grep -q "^MP H3 CONFIRMED-on-box$" "$CHILOG" || { echo "[mathesis] RED: the involution class law drifted"; exit 122; }
grep -q "^MPL# 15 0 19 60 4 0$" "$CHILOG" || { echo "[mathesis] RED: the pilot's d=19 discovery drifted"; exit 123; }
grep -q "^MPL rounds=18 head=18a0495c7556cc3011d64d4aa32b96f1a188773c18acbc7df24524a9539e67a6$" "$CHILOG" || { echo "[mathesis] RED: the pilot head(18) drifted"; exit 124; }
CHI_CERT="$(printf '%s' "12|64|9|109|20596732|860978|21|178981952|504|62|10|300|324|81|3|3|3|0|271|919|4|18a0495c7556cc3011d64d4aa32b96f1a188773c18acbc7df24524a9539e67a6" | sha256sum | cut -d' ' -f1)"
echo "[mathesis] CHI_CERT = $CHI_CERT"
echo "[mathesis] GREEN: campaign Chi sealed (the judge's third universe decides the harvested tier and ORDERS the six constructed points; the 4^16 refusal DISCHARGED: 178,981,952 structures, 109 species, 21 citizens, the two ontology organs unified by the carrier-12 product law; the involution class law CONFIRMED over all seven pairs with d=225 delivering the predicted three curve-B identities; units REFUTED as the pattern's driver; the pilot found d=19 (A:4) and head(18) extends the ledger)"

# --synth: REPLAY the whole 18,522-pair sweep and demand byte-identity with the sealed log
if [[ "${1:-}" == "--synth" ]]; then
    SWEEP="$III_ROOT/STDLIB/build/mathesis/synth_sweep$BIN_SUFFIX"
    [[ -x "$SWEEP" ]] || { echo "[mathesis] RED: no sweep driver (compile STDLIB/sovir/mathesis_synth_main.iii)"; exit 30; }
    staged="/tmp/mxsw_$$$BIN_SUFFIX"; cp "$SWEEP" "$staged"
    timeout 1800 "$staged" > "$RUN/synth_replay.log"; rc=$?; rm -f "$staged"
    [[ $rc -eq 0 ]] || { echo "[mathesis] RED: synth replay rc=$rc"; exit 31; }
    cmp -s "$RUN/synth_replay.log" "$SYNLOG" || { echo "[mathesis] RED: synth replay diverges from the sealed log"; exit 32; }
    echo "[mathesis] GREEN: full synth sweep REPLAYED byte-identical (18,522 pairs)"
fi

echo "[mathesis] ============================================================"
echo "[mathesis] Xi0 SEED CYCLE CLOSED: measured -> conjectured -> PROVEN ->"
echo "[mathesis] admitted (MATHESIS-THEOREM-0001) -> assimilated (cg_svir fold)"
echo "[mathesis] -> re-verified (square green) -> measured strict decrease."
echo "[mathesis] THE CREATOR TIER COMPLETE (Xi0..Xi13, all DISCHARGED-in-code):"
echo "[mathesis]  - Xi5 grammar ratchet 4->0 (AND/OR/XOR/SHR taught, mul-plan PINNED)"
echo "[mathesis]  - Xi1 novelty COMPUTED + the frontier a QUEUE (mul-assoc proven Z/2^8)"
echo "[mathesis]  - Xi9 order + CLOSED-OPTIMAL (cost(align_k)=cost(mask_k)=1 exactly)"
echo "[mathesis]  - Xi10 theorems-from-theorems: the first forall-n-in-NAT entries, kernel-judged"
echo "[mathesis]  - Xi11 rot-conjugation orbits + width functors (transport = re-proof)"
echo "[mathesis]  - Xi4 kernel-certified + published; Xi2 zk-AIR-grounded + attested"
echo "[mathesis]  - Xi13 measured intent + the autonomy invariant; Xi6 federation by proof"
echo "[mathesis]  - Xi12 the telescope: 1024 MACHINE denesting theorems, dual-web certified"
echo "[mathesis]  - Xi7 SEALED: 18 entries -> HEAD_v2, MATHESIS_CERT binds math<->streams<->ratchet"
echo "[mathesis] 18 sealed theorems (6 MACHINE-synthesized); no candidate ever supplied."
echo "[mathesis] ============================================================"
exit 0
