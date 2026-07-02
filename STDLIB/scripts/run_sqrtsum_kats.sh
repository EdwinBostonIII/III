#!/usr/bin/env bash
# run_sqrtsum_kats.sh -- gate for the GENERAL sum-of-square-roots sign predicate (sqrt_sum_sign.iii):
# bigint_isqrt (handle-frugal) + ui_sqrt_sum_sign (separation-bound, arbitrary n, exact-zero detection).
# Links libiii_native.a (bigint/arena) and, for the agreement KAT, ui_exact_big.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/sqrt_sum_sign.iii" --compile-only --out "$OUT/sqrt_sum_sign.o" 2>"$OUT/s.log" || { echo "FAIL sqrt_sum_sign compile"; cat "$OUT/s.log"; exit 1; }
"$I2" "$A/kfield.iii"       --compile-only --out "$OUT/kfield.o"       2>"$OUT/kfw.log" || { echo "FAIL kfield compile"; cat "$OUT/kfw.log"; exit 1; }
"$I2" "$A/exact_surd_value.iii" --compile-only --out "$OUT/exact_surd_value.o" 2>"$OUT/esv.log" || { echo "FAIL exact_surd_value compile"; cat "$OUT/esv.log"; exit 1; }
"$I2" "$A/billiard.iii" --compile-only --out "$OUT/billiard.o" 2>"$OUT/bil.log" || { echo "FAIL billiard compile"; cat "$OUT/bil.log"; exit 1; }
"$I2" "$A/csg_tree.iii" --compile-only --out "$OUT/csg_tree.o" 2>"$OUT/ctr.log" || { echo "FAIL csg_tree compile"; cat "$OUT/ctr.log"; exit 1; }
"$I2" "$A/gas.iii" --compile-only --out "$OUT/gas.o" 2>"$OUT/gas.log" || { echo "FAIL gas compile"; cat "$OUT/gas.log"; exit 1; }
"$I2" "$A/gas_big.iii" --compile-only --out "$OUT/gas_big.o" 2>"$OUT/gb2.log" || { echo "FAIL gas_big compile"; cat "$OUT/gb2.log"; exit 1; }
"$I2" "$A/lattice_march.iii" --compile-only --out "$OUT/lattice_march.o" 2>"$OUT/lmr.log" || { echo "FAIL lattice_march compile"; cat "$OUT/lmr.log"; exit 1; }
"$I2" "$A/constraint.iii" --compile-only --out "$OUT/constraint.o" 2>"$OUT/cnr.log" || { echo "FAIL constraint compile"; cat "$OUT/cnr.log"; exit 1; }
"$I2" "$A/cspace.iii" --compile-only --out "$OUT/cspace.o" 2>"$OUT/csr.log" || { echo "FAIL cspace compile"; cat "$OUT/csr.log"; exit 1; }
"$I2" "$A/arc_sweep.iii" --compile-only --out "$OUT/arc_sweep.o" 2>"$OUT/asw.log" || { echo "FAIL arc_sweep compile"; cat "$OUT/asw.log"; exit 1; }
"$I2" "$A/resultant.iii" --compile-only --out "$OUT/resultant.o" 2>"$OUT/rsl.log" || { echo "FAIL resultant compile"; cat "$OUT/rsl.log"; exit 1; }
"$I2" "$A/refract.iii" --compile-only --out "$OUT/refract.o" 2>"$OUT/rfr.log" || { echo "FAIL refract compile"; cat "$OUT/rfr.log"; exit 1; }
"$I2" "$A/ui_exact_big.iii"  --compile-only --out "$OUT/ui_exact_big.o"  2>"$OUT/u.log" || { echo "FAIL ui_exact_big compile"; cat "$OUT/u.log"; exit 1; }
"$I2" "$A/verb_geom.iii"     --compile-only --out "$OUT/verb_geom.o"     2>"$OUT/v.log" || { echo "FAIL verb_geom compile"; cat "$OUT/v.log"; exit 1; }
"$I2" "$A/traj_kinematics.iii" --compile-only --out "$OUT/traj_kinematics.o" 2>"$OUT/t.log" || { echo "FAIL traj_kinematics compile"; cat "$OUT/t.log"; exit 1; }
"$I2" "$A/exact_denest.iii"  --compile-only --out "$OUT/exact_denest.o"  2>"$OUT/d.log" || { echo "FAIL exact_denest compile"; cat "$OUT/d.log"; exit 1; }
"$I2" "$A/csg_kernel.iii"    --compile-only --out "$OUT/csg_kernel.o"    2>"$OUT/csg.log" || { echo "FAIL csg_kernel compile"; cat "$OUT/csg.log"; exit 1; }
"$I2" "$A/photon_route.iii"  --compile-only --out "$OUT/photon_route.o"  2>"$OUT/pr.log" || { echo "FAIL photon_route compile"; cat "$OUT/pr.log"; exit 1; }
"$I2" "$A/cyclotomic_se3.iii" --compile-only --out "$OUT/cyclotomic_se3.o" 2>"$OUT/cse3.log" || { echo "FAIL cyclotomic_se3 compile"; cat "$OUT/cse3.log"; exit 1; }
"$I2" "$A/q23_sign.iii"      --compile-only --out "$OUT/q23_sign.o"      2>"$OUT/q23s.log" || { echo "FAIL q23_sign compile"; cat "$OUT/q23s.log"; exit 1; }
"$I2" "$A/collide.iii"       --compile-only --out "$OUT/collide.o"       2>"$OUT/col.log" || { echo "FAIL collide compile"; cat "$OUT/col.log"; exit 1; }
"$I2" "$A/delaunay.iii"      --compile-only --out "$OUT/delaunay.o"      2>"$OUT/dln.log" || { echo "FAIL delaunay compile"; cat "$OUT/dln.log"; exit 1; }
"$I2" "$A/sturm.iii"         --compile-only --out "$OUT/sturm.o"         2>"$OUT/stm.log" || { echo "FAIL sturm compile"; cat "$OUT/stm.log"; exit 1; }
"$I2" "$A/aether_lens.iii"   --compile-only --out "$OUT/aether_lens.o"   2>"$OUT/al.log" || { echo "FAIL aether_lens compile"; cat "$OUT/al.log"; exit 1; }
"$I2" "$A/algnum.iii"        --compile-only --out "$OUT/algnum.o"        2>"$OUT/an.log" || { echo "FAIL algnum compile"; cat "$OUT/an.log"; exit 1; }

run() {
    local name="$1" want="$2"; shift 2
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    timeout 150 "$st"; local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2120_bigint_isqrt   99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"
run 2121_sqrt_sum_sign  99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$LIB"
run 2122_lazy_real      99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$LIB"   # lazy tier-1 interval + tier-3 escalation, counted
run 2123_lazy3          99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$LIB"   # ATTACK 1+3: canonicalization Tier 2 + adaptive-F windowing
run 2124_transcendental 99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$LIB"   # ATTACK 2: transcendental tristate (UNKNOWN, no panic)
run 2125_verb_geom      99   "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/ui_exact_big.o" "$LIB"   # GRAPH RESTORED: e-class equivalence substrate + sign cache
run 2137_adaptive_sign  99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"   # TIER 2.5: linear-independence + adaptive precision -- bypasses the exponential separation bound per-instance
run 2138_symmetry_quotient 99 "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # SYMMETRY QUOTIENT: real Euclidean perimeter comparisons -- pay the exact-sign wall once per distinct shape (similarity/relabel/swap orbit)
run 2139_padic_barrier   99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # P-ADIC WALL FACE: factoring-free modular sieve is UNSOUND (mod p destroys perfect-square factors); sound arm needs factoring => redundant
run 2140_adaptive_big    99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # TIER 2.5 BIGINT-COEFF: adaptive sign for caller-owned bigint magnitudes (the ui_sqrt_sum_sign_big / ui_arc_cover_full render-scale path)
run 2141_cyclotomic_rotation 99 "$OUT/cyclotomic_se3.o" "$LIB"  # EXACT cyclotomic rotation: rational-multiple-of-π angles in ℚ(√2,√3); 24×15° returns bit-exact to identity; DEDUPED onto cyclotomic_se3::q23_mul (pure organ, no Σ√ dep)
run 2142_se3_screw       99   "$OUT/cyclotomic_se3.o" "$LIB"  # EXACT SE(3) screw: 3D rotation closure + SO(3) non-commutativity + exact screw translation in ℚ(√2,√3); DEDUPED onto cyclotomic_se3::q23_mul
run 2143_traj_arclen     99   "$OUT/traj_kinematics.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # LOAD-BEARING: traj_len_sign consumes the bigint adaptive tier -- exact gantry-trajectory length comparison (3+ independent surds at bigint scale)
run 2144_lattice_pathfind 99  "$OUT/traj_kinematics.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # HIGH-END PATHFINDING: exact lattice Dijkstra (lattice_shortest_path) -- frontier ordered by EXACT Sqrt-sum length; matches brute-min, resolves a float-blind Pell near-tie
run 2145_denest          99   "$OUT/exact_denest.o"  # TOWER DENESTING: exact rank-1 sqrt of a+b*sqrt(d) in Q(sqrt d) -- decides square-vs-extension, verified root; rejects the norm-square-but-not-alpha case
run 2146_compactor       99   "$OUT/traj_kinematics.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # FRONTIER COMPACTOR: drop settled Dijkstra distances (dead to the search) -> peak handles = frontier width; correct + behavior-preserving on a 100-node graph
run 2147_lattice_oracle  99   "$OUT/traj_kinematics.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # Oh QUOTIENT ORACLE: O(1) exact shortest king-move-lattice distance via octahedral symmetry; oracle==greedy, greedy beats both competitors
run 2150_csg_kernel      99   "$OUT/csg_kernel.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/exact_denest.o" "$LIB"  # UNSHATTERABLE CSG: exact quadric membership/incidence (Sum-sqrt) + tangency (integer) + triple-point corner (denest); float-breaks near-tie witness
run 2151_photon_route    99   "$OUT/photon_route.o" "$OUT/traj_kinematics.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # PHOTONIC LATTICE ROUTING: O(1) O_h bulk geodesic (millions of nodes, zero memory) + exact zero-loss near-tie compare + frontier-compacted defect detour
run 2152_mechanism       99   "$OUT/cyclotomic_se3.o" "$OUT/q23_sign.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # ZERO-DRIFT KINEMATICS: exact ℚ(√2,√3) rotation, bit-exact home after 2400 steps (100 rev) + q23_sign exact reach ordering (Σ√ unification) + SE(3) screw
run 2153_collision       99   "$OUT/collide.o" "$OUT/cyclotomic_se3.o" "$OUT/q23_sign.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # NO-TUNNELING COLLISION: exact swept-segment vs sphere (endpoints clear yet HIT) + certified tangency + rotated-tool Σ√ membership (cyclotomic_se3 ⊗ geometry)
run 2154_delaunay        99   "$OUT/delaunay.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # ROBUST PREDICATES: exact orient2d/incircle2d (consistent signs, no invalid topology) + Fibonacci-Cassini float-blind witness (exact -1 where a double returns 0) + Delaunay flip + Σ√ orient
run 2156_sturm           99   "$OUT/sturm.o" "$LIB"  # EXACT ROOT ISOLATION: Sturm's theorem, exact real-root count/isolation; positive-at-both-endpoints-yet-2-roots-inside witness (endpoint-sampling finds 0, Sturm counts 2); squarefree-part gcd
run 2155_aether_lens     99   "$OUT/aether_lens.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # EXACT RAY-CAST: floating-point-free ray∩quadric CSG -- integer sign(Delta) hit/miss/tangent + n=3 surd depth order (z-FIGHT KILLER: fixed f=10 straddles [-2,+2], exact resolves +1) + n=2 surd DERIVED 8-bit Lambert; renders a shaded sphere as first light
run 2157_algnum          99   "$OUT/algnum.o" "$OUT/sturm.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # EXACT ALGEBRAIC NUMBERS: sign/total-order/decidable-EQUALITY (the zero problem) -- sqrt(2) three ways decided EQUAL via gcd-shared-root (a refine-to-epsilon impostor loops/guesses); sqrt(2)<cbrt(3)/<99/70 by refinement; face1⊗face6 -- Sturm sign == Sigma-sqrt separation-bound sign over a rational fan; composes sturm.iii + sqrt_sum_sign.iii
run 2159_kf_weld        99   "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/exact_surd_value.o" "$LIB"  # THE WELD GATE: kfield Galois-tower sign as Tier 3 -- differential vs the separation-bound oracle (19/39 overflow family -> 39/39 guarded abstains; Pell near-ties DECIDED in pure i64 by the tower; rank-collapse {6,10,15} F2-embed; rank-4 abstain->adaptive fallback).  THEOREM: bounded-rank Galois-tower sign == separation-bound sign
run 2148_theorem_fuzzer  99   "$OUT/kfield.o" "$LIB"  # QUOTIENT-KIT landed: generative coincidence-fuzzer over kfield (CONSTRUCT/IDENTIFY verbs; identity pairs collide, control does not)
run 2149_universal_block 99   "$OUT/kfield.o" "$LIB"  # QUOTIENT-KIT landed: the universal block -- kfield four verbs = ONE kernel; addr-coincidence <=> sign-zero (IDENTIFY <=> DECIDE)
run 2167_billiard_reversal 99 "$OUT/billiard.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # EXACT TIME-REVERSIBLE BILLIARDS (charter Phase 1): 12 events forward + reverse = BIT-EXACT return + wall palindrome (irrational 45-deg offset orbit); Q32.32 twin picks the WRONG wall on the certified near-tie; corner tie CERTIFIED and refused
run 2168_csg_tree       99 "$OUT/csg_tree.o" "$OUT/csg_kernel.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/exact_denest.o" "$LIB"  # ALGEBRAIC CSG DAG (charter Phase 5): 1000 successive drills, the 1000th op as precise as the 1st (depth composes booleans not arithmetic); ON-certificate carried through 1000 ops; leaf exactness at 2^62 where a 53-bit-mantissa twin collapses R^2 and R^2+1
run 2169_gas_reversal   99 "$OUT/gas.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # THE EXACT MICROCANONICAL GAS (Program II Phase I): N-body hard-cube gas -- pair collisions = integer component SWAPS (energy+momentum = INTEGER IDENTITIES at every event); ensemble involution R.F^7.R.F^7 == id BIT-EXACT; two-pair simultaneity CERTIFIED and refused
run 2170_swept_leaf     99 "$OUT/csg_tree.o" "$OUT/csg_kernel.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$OUT/exact_denest.o" "$LIB"  # THE SWEPT-SPHERE LEAF (Program II Phase II / Vector I base): CSG leaves as continuous spacetime volumes -- exact clamped-parabola membership at ANY t; ON-certificates through booleans; 100-pass zigzag depth-independent; the snapshot CAM twin leaves PHANTOM MATERIAL at t*=5/8 where the exact leaf proves the cut
run 2171_lattice_march  99 "$OUT/lattice_march.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # INFINITE PERIODIC TIR OPTICS (Phase 4 / Vector III): 2,999,997 exact crossings to the sphere at x-cell 999999 (EXACT integers, zero drift, zero storage); 50-bounce mirror labyrinth retraced BIT-EXACTLY; disc==0 certified tangent; corner-tie double-step vs the biased-DDA twin entering a mirror cell the true ray never touches
run 2172_constraint     99 "$OUT/constraint.o" "$OUT/sturm.o" "$OUT/delaunay.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # EXACT 1-DOF CONSTRAINT RESOLUTION (Phase 3 + II-V / Vector II): Sturm count/isolate + gcd(p,pPRIME) SINGULARITY certificate (the irrational tangent config sqrt2 EXACTLY bracketed); sign-sampling is STRUCTURALLY blind to tangential roots (1 vs 2, even with exact evaluation); the incircle flip-instant isolated and cross-certified by delaunay incircle2d == 0
run 2173_cspace         99 "$OUT/cspace.o" "$OUT/arc_sweep.o" "$OUT/sturm.o" "$OUT/cyclotomic_se3.o" "$OUT/q23_sign.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # THE EXACT C-SPACE COMPILER (II-III / Vector I): 24x6x3 cyclotomic states decided by q23_sign (irrational blocked certificate); TRANSLATION edges SWEPT-certified -- a both-endpoints-free edge is KILLED where the tip sweep tunnels (the endpoint-only twin walks through, 4 vs 6); BFS discovered the k=2 ZERO-CLEARANCE tangent corridor (10 < the author-planned 12); rotation arc-sweep = charted OPEN
run 2175_arc_sweep      99 "$OUT/arc_sweep.o" "$OUT/cspace.o" "$OUT/sturm.o" "$OUT/cyclotomic_se3.o" "$OUT/q23_sign.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # ROTATIONAL ARC-SWEEP CERTIFICATE (Program III Vector VI): Weierstrass quartic + R(180) integer chart + machine-derived /1000 covers; the arc GRAZE with free endpoints REFUSED (rotational tunneling no endpoint sampler sees); the certified planner circles the ring 22 moves where the twin sweeps through matter in 2; C-space rotation edges now CONTINUOUSLY certified
run 2176_gas_big       99 "$OUT/gas_big.o" "$OUT/gas.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # TRANS-ENVELOPE THERMODYNAMICS (Program III Vector V): the i64 gas honestly refuses at 2^61 magnitude; the bigint ensemble continues the SAME scenario (involution exact AS RATIONALS) and runs 200 events deep -- velocities never migrate (integer identities); handle-table discipline: sign calls in their own dropped arenas
run 2177_resultant     99 "$OUT/resultant.o" "$OUT/sturm.o" "$LIB"  # RESULTANT ELIMINATION (Program III Vector VII): gamma = alpha + beta constructed via interpolated Bareiss Sylvester determinants -- the classical minimal polynomials of cbrt2+sqrt3 (deg 6) and sqrt2+sqrt3 (deg 4) derived COEFFICIENT-FOR-COEFFICIENT, then composed back through sturm (2 real roots; gamma bracketed in (2.9,3]) -- roots closed under +
run 2179_resultant_big  99 "$OUT/resultant.o" "$LIB"  # MODULAR-CRT DETERMINANT ENGINE (charted v2): 16-prime Gauss + Garner CRT + certified permanent bound -- v1 Bareiss REFUSES at cbrt(2^31)+sqrt3 (overflow) and at D=12 (guard); v2 derives both EXACTLY (constant 2^62-27; monic deg-12 with t^11=t^10=0, R(0)=73, both real roots bracketed by exact Horner); Bareiss==CRT twin weld on the shared envelope; coefficient-beyond-i64 certified refusal
run 2180_resultant_closure 99 "$OUT/resultant.o" "$OUT/sturm.o" "$LIB"  # CLOSURE VERBS (charter increment 2): roots closed under * (norm forms (t^2-6)^2, t^6-108; rs_prod_big t^12-648 where v1 guard-refuses) and INVERSE (x^4-10x^2+1 SELF-reversed; 1/cbrt2 -> 2x^3-1; f(0)=0 and g(0)=0 certified refusals) + content strip -- THE GOLDEN RATIO composed (1+sqrt5)*(1/2) via sum,prod,primitive -> t^2-t-1, sturm 1 root in [1,2] and 1 in [-1,0]; zero-lead Sylvester degeneracy HARDENED to refusal
run 2181_arc_tangency   99 "$OUT/sturm.o" "$OUT/arc_sweep.o" "$LIB"  # ROOT MULTIPLICITY (charter increment 3): touch-vs-cross discriminator via iterated gcd(p,p') PRS -- (u^2-2)^2(u^2-3) mult 2 at sqrt2 / 1 at sqrt3 with BOTH-ENDS-NEGATIVE blindness witness (-26,-3); the arc_sweep GRAZE (N=400u^2(u^2+1), as_cert refuses 0) certified EVEN=touch vs r2=226 crossing certified ODD -- same conservative verdict, different certificate; -1 rootless / -2 ambiguous refusals
run 2178_refract       99 "$OUT/refract.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # BOUNDED-RANK REFRACTION (Program III Vector VIII): the designed 45<->30-degree closed class pair (n^2 = 1|2) -- Snell-squared as a CERTIFIED integer identity per transition; the exact slab theorem (exit parallel, lateral shift (300+100sqrt3)/3); the EXACT critical angle (residue 0); TIR certified (+2); no tower, ever
run 2174_gas_demon      99 "$OUT/gas.o" "$OUT/verb_geom.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"  # THE SPEED-SELECTIVE MEMBRANE (Vector IV, the exact Maxwell demon): slow particles CONFINED (3 exact membrane bounces, contact-on-membrane legal), the fast particle passes and works the far wall; energy an integer identity at every event; the DIRECTION-BLIND gate is reversal-symmetric -- the involution holds WITH the demon active (a reversible demon pumps no entropy, gated)

echo "=== SQRT-SUM-SIGN KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
