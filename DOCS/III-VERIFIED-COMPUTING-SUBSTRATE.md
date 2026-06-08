# III Verified-Computing Substrate — Architecture Map

A self-contained, machine-checked computing substrate built entirely in self-hosted `.iii`, one module at a
time, each carrying a KAT that exits `99` and each validated **in-aggregate** linked against the real
`STDLIB/build/iii/libiii_native.a`.

**Aggregate evidence (2026-06-07):** clean build `PASS=557 FAIL=0 BUILD_EXIT=0`; recent-batch lib-link
validation `8/8 exit=99 ALL GREEN` (ids `1290`–`1297`), earlier `56/56` (ids `1232`–`1286`). Per-module:
each gated standalone via `iiis-2 --compile-only` + `gcc … -lkernel32` → `99`, **capability-swept** (grep
the CONCEPT, not just the prefix — see retirements below) and collision-swept (`@export` names unique
tree-wide), cold-audited against the `.iii` trap list, then wired into `build_stdlib.sh` MODULES +
`run_corpus.sh` EXPECTED. NIH throughout (libc + III BOOT headers only).

**Retirements (NIH-spirit, capability-audit):** `merkle_log` (duplicated the real SHA-256 `numera/merkle.iii`),
`logic_synth` (duplicated the `hdl.iii`/`hdl_optimize.iii`/`hdl_compiler.iii` HDL subsystem), and `sat_dpll`
(pre-commit, duplicated the CDCL `numera/sat.iii`) were removed: a green KAT on a hardcoded toy is not value
when a real, corpus-tested III subsystem already does it better. Pre-flight now greps the *capability*.

## Layers

### State & memory (separation logic, hardware memory model)
- `heaplet` (1232) separation algebra / disjoint-union monoid · `sep_logic` (1233) frame theorem ·
  `tso` (1234) x86-TSO model checker · `ptr_provenance` (1235) aliasing decision procedure ·
  `mem_rewrite` (1236) AoS→SoA layout rewrite · `csl` (1237) concurrent separation / non-interference

### Synthesis & equality saturation
- `congruence_closure` (1238) proof-producing · `mcmc_egraph` (1239) annealed Metropolis ·
  `relational_ematch` (1244) hash-join e-matching · `algo_synth` (1245) asymptotic synthesis

### Stratified trust chain & self-driving engine
- `k0_referee` (1247) frozen bisimulation referee · `golden_shift` (1248) verified cost descent ·
  `conjecture_refute` (1249) Popperian · `self_engine` (1250) real self-dispatch ·
  `verified_search` (1253) k0-gated frontier · `omega_engine` (1254) trace-verified grand unification

### Optimization (multi-objective, ripples, optimality)
- `pareto_frontier` (1255) · `verified_ripple` (1256) equivalence-preserving propagation ·
  `optimality_cert` (1257) verified cost floor · `ring_opt` (1260) Horner ring identity ·
  `matrix_ring` (1261) non-commutative ring + fast exponentiation

### Abstract interpretation (domains, engine, reduced product)
- `interval_lattice` (1265) · `kleene_fixpoint` (1267) ripple-to-convergence · `widening` (1268)
  termination on unbounded domains · `align_domain` (1269) SIMD width · `reduced_product` (1272)
  emergent precision from domain intersection · `range_check` (1283) overflow proof

### Loop optimization (the composition harmonies)
- `affine_check` (1263) polyhedral memory safety · `loop_optimizer` (1266) two-analysis strength reduction ·
  `vectorizer` (1270) four-module SIMD legality · `bce` (1271) bounds-check elimination ·
  `loop_pipeline` (1273) six-module full optimizing pass

### Frontend / SSA / dataflow
- `dominators` (1277) · `ssa` (1278) dominance-frontier phi placement · `gvn` (1279) value numbering ·
  `dce` (1280) liveness mark-sweep · `sccp` (1281) constant propagation · `liveness` (1285) backward dataflow

### Codegen backend
- `isel` (1276) maximal-munch tiling · `reg_alloc` (1274) interval-graph coloring ·
  `list_schedule` (1275) critical-path timing · `rewrite_schedule` (1264) verified phase-ordering

### Security, verification, trust
- `taint_analysis` (1282) information-flow · `translation_validation` (1284) trust-the-checker ·
  `proof_replay` (1286) LCF proof checking · `bmc` (1288) bounded model checking ·
  `kinduction` (1289) unbounded induction · `safety_prover` (1291) the complete k-induction verdict
  (SAFE/UNSAFE/UNKNOWN, unifying base + step) · `bft_quorum` (1262) Byzantine quorum intersection ·
  `contract_gate` (1259) zero-trust admission

### Family-proofs & abstract-interpretation payoffs (continuation arc)
- `value_range_prover` (1292) one abstract check proves a whole parameter family overflow-free
  (consumes `interval_lattice` + `range_check`) · `loop_bounds_prover` (1293) family-wide memory safety via
  monotonicity (consumes `affine_check`) · `branch_elim` (1294) dead-branch elimination from value ranges
  (consumes `interval_lattice`) — conditional constant propagation's emergent payoff

### Verified algorithms & data structures (verified against a reference)
- `dijkstra` (1290) single-source shortest paths · `rms` (1295) rate-monotonic schedulability
  (response-time analysis) · `binary_search` (1296) ≡ linear over all queries · `kmp` (1297) ≡ naive
  string match · `levenshtein` (1298) edit-distance DP · `knapsack` (1301) 0/1 DP ≡ brute force ·
  `fenwick` (1299) BIT ≡ naive prefix sums · `segment_tree` (1300) range-min ≡ naive ·
  `inversion_count` (1302) ≡ brute (consumes `fenwick` — a data structure put to work by an algorithm)

## Interconnection — the analyses feed the named subsystems (not islands)

The verified-analysis stack is not a parallel library; it is wired into III's existing production subsystems
as the substrate's "intelligence from the intersection." FIFTEEN connections (A/B by hand; 1–8 from a first
adversarial-verified discovery workflow — 48 agents, 37→12 genuine→8; c1–c4 from a second — 42 agents, 31→4;
c5 from a third — 19 agents, 8→1, the connection space thinning as it fills), each ADDITIVE, each gated on its
named corpus tests + the FULL corpus (911→925, FAIL=0 throughout):

- **`forcefield/sovereign_optimizer` consumes the analyses (the SECOND LEASH).** `sov_pcc` proves an
  optimization is meaning-preserving; the analysis stack (`range_check` / `branch_elim` / `value_range_prover`
  over `interval_lattice`) proves its SAFETY PRECONDITION (overflow-free narrowing, dead-branch fold, bounded
  loop accumulator). An optimization applies only when BOTH leashes hold — `sopt_analysis_kat`, wired into the
  production `sopt_flagship` step 8 (corpus `1311`). Full corpus `911/0`.
- **`sanctus/sovereign_witness` consumes `affine_check` (turned INWARD).** The witness decides affine-access
  safety in closed form over external traces; `affine_check` decides the same property in-line by exhaustive
  scan. `sw_crossval_affine_kat` proves the two sound procedures agree on PROVEN-vs-REFUTED for every in-range
  access (corpus `1312`). Full corpus `912/0`.

Eight more from the discovery workflow (each names a real pre-existing consumer; capability-audited; the
verifier even *rejected* two vacuous candidates — `sccp→dce` as a category error, `interval_lattice→snapshot_
lattice` as already structurally enforced):
1. **`reduced_product` → `sovereign_optimizer`** (parity-refined leash): the interval×parity reduced product
   tightens the second-leash preconditions by known parity, so strictly MORE optimizations pass, still sound
   (`sopt_refined_kat`, flagship step 9; corpus `1313`).
2. **`bft_quorum` + `value_range_prover` → `hotstuff`**: the consensus core carries its own machine-checked
   Byzantine quorum-intersection + vote-bound safety certificate, bound to the LIVE `f` (`1314`).
3. **`widening` → `kleene_fixpoint`**: one fixpoint engine for bounded lattices AND unbounded domains via the
   nabla operator — Cousot's Kleene+widening unified (`1315`).
4. **`dijkstra` → `topology_atlas`**: the federation atlas lifts from unweighted BFS to verified cost-aware
   shortest paths (unit weights ≡ BFS; weighted finds cheaper indirect routes) (`1316`).
5. **`congruence_closure` → `proof_ripple_unified`**: every admitted ripple MERGE carries a replayable
   labelled-edge proof chain (the data the synthesis kernel needs) (`1317`).
6. **`sccp` → `bce`**: a statically-constant array index discharges its bounds check in O(1); a VARYING index
   falls back to affine analysis — two dataflow analyses compose (`1318`).
7. **`taint_analysis` → `cap_handshake`**: a missing verify between untrusted wire input and capability
   derivation becomes a build-time KAT failure, not a runtime privilege-escalation (`1319`).
8. **`branch_elim` (`be_sound`) → `sovereign_optimizer`**: a dead-branch fold is admitted only when the
   abstract verdict AND an exhaustive concrete walkback agree — defense-in-depth (flagship step 10; `1320`).

Four more from the second discovery workflow (deeper subsystems; the verifier rejected the witness-chain LTL
path as non-additive and applied two primary-source honesty corrections):
- **c1. `theorem_commons` (+`sov_isa`) → `scythe_census`**: the optimization census cite-verifies the Theorem
  Commons — discovery (sov_isa enumeration) ⊕ registration (Commons admit) ⊕ citation checked mutually
  consistent at build time, the headline proof-carrying-optimization theorems citable AND census-certified (`1321`).
- **c2. `temporal_logic` → `hotstuff`**: a formal LTL LIVENESS proof `G(quorum⇒F(advance))` beside the safety
  theorems, via a new clean explicit-trace evaluator (the witness-chain path was infeasible); healthy trace
  holds, stalled trace fails (`1324`).
- **c3. `taint_analysis` → `aes_gcm`**: a build-time info-flow proof that key/nonce reach the ciphertext only
  through the AES encryption boundary, never as raw plaintext — a key-recovery-bug guard (`1323`).
- **c4. `liveness` → `reg_alloc`**: register allocation over a COMPUTED interference graph from the verified
  backward-dataflow liveness analysis, optimally colored (chromatic = max-overlap), not synthetic intervals (`1322`).
- **c5. `constitution` (predicate VM) → `memo_query`**: memo admission gains DYNAMIC predicate-level governance
  — a ratified clause's admissibility bytecode (`cons_eval_predicate`, e.g. `COP_PHASE_GE`) gates each
  admission over the op-view, strictly additional to the existing clause-presence + chain checks (`1325`).

The discriminator before adding any module: name the EXISTING subsystem that will call it. A green KAT on a
self-contained algorithm verified against a co-designed reference is a fixture; value is in the connection.

## Operating notes
- The repo lives under OneDrive; long builds were corrupted by sync-down until the **fresh-copy** technique
  (`cp build_stdlib.sh _arc_build.sh && bash _arc_build.sh`) gave the first clean `545/0`. Never
  `bash -c "$(cat script)"` — `set -u` + unbound `BASH_SOURCE` skips the corpus into a false green.
- `.iii` reserved-keyword identifiers found: `from`, `any`, `var` (all `expected IDENTIFIER, saw <kw>`).
- The whole arc composes: independent analyses must AGREE before a rewrite is admitted (`loop_optimizer`,
  `vectorizer`); proofs and transforms are re-checked by tiny kernels (`translation_validation`,
  `proof_replay`, `k0_referee`); higher precision emerges from domain intersection (`reduced_product`).
- **Two verification disciplines run throughout.** (1) *Verify-against-reference*: a fast/clever path is
  proven equivalent to an obvious one for the WHOLE input space, not spot-checked — `binary_search`≡linear,
  `kmp`≡naive, `knapsack`/`fenwick`/`segment_tree`/`inversion_count`≡their O(n)/O(n²) references, exhaustively.
  (2) *Family proofs*: a single abstract check certifies an unbounded family of concrete programs at once
  (`value_range_prover`, `loop_bounds_prover`, `branch_elim`) — abstract interpretation's one-check-covers-many.
- **Capability-audit before building** (lesson, 2026-06-07): pre-flight greps the CONCEPT (e.g. `merkle`,
  `crc-32`, `segment tree`), not just the symbol prefix — name-collision checks let shadow-reimplementations
  through. This caught `crc32` (already present) and `union_find` (in `ripple_unify`) before writing them, and
  found the three retired duplicates above. Genuine gaps confirmed and filled: Fenwick/segment tree.
