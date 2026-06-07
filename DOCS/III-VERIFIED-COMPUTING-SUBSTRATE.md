# III Verified-Computing Substrate — Architecture Map

A self-contained, machine-checked computing substrate built entirely in self-hosted `.iii`, one module at a
time, each carrying a KAT that exits `99` and each validated **in-aggregate** linked against the real
`STDLIB/build/iii/libiii_native.a`.

**Aggregate evidence (2026-06-07):** clean build `PASS=545 FAIL=0 BUILD_EXIT=0`; complete corpus lib-link
validation `56/56 exit=99 ALL GREEN` (ids `1232`–`1286`). Per-module: each gated standalone via
`iiis-2 --compile-only` + `gcc … -lkernel32` → `99`, collision-swept (`@export` names unique tree-wide),
cold-audited against the `.iii` trap list, then wired into `build_stdlib.sh` MODULES + `run_corpus.sh`
EXPECTED. NIH throughout (libc + III BOOT headers only).

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
  `list_schedule` (1275) critical-path timing · `rewrite_schedule` (1264) verified phase-ordering ·
  `logic_synth` (1258) verified gate netlist

### Security, verification, trust
- `taint_analysis` (1282) information-flow · `translation_validation` (1284) trust-the-checker ·
  `proof_replay` (1286) LCF proof checking · `bmc` (1288) bounded model checking ·
  `bft_quorum` (1262) Byzantine quorum intersection · `contract_gate` (1259) zero-trust admission ·
  `merkle_log` (1287) authenticated append-only log

## Operating notes
- The repo lives under OneDrive; long builds were corrupted by sync-down until the **fresh-copy** technique
  (`cp build_stdlib.sh _arc_build.sh && bash _arc_build.sh`) gave the first clean `545/0`. Never
  `bash -c "$(cat script)"` — `set -u` + unbound `BASH_SOURCE` skips the corpus into a false green.
- `.iii` reserved-keyword identifiers found: `from`, `any`, `var` (all `expected IDENTIFIER, saw <kw>`).
- The whole arc composes: independent analyses must AGREE before a rewrite is admitted (`loop_optimizer`,
  `vectorizer`); proofs and transforms are re-checked by tiny kernels (`translation_validation`,
  `proof_replay`, `k0_referee`); higher precision emerges from domain intersection (`reduced_product`).
