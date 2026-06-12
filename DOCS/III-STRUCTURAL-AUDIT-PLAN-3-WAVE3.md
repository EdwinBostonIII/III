# III Structural Audit — Plan Part 3 · Wave 3: Consumers heal · Performance · Primitives · Hardening · Dead-matter

> **AUDIT STATUS (2026-05-30, verified vs live code):**
> - **✅ INTEGRATED:** W3.3 crystal id-band (965), W3.4 cgr_contains (964), W3.6 cpufeat AVX-512DQ,
>   W3.8 sov_isa cc_evaluate (963), W3.10 keccak block-absorb (960), W3.11 Straus–Shamir,
>   W3.14 xoshiro jump (961), W3.15 bv_ring colstack (962), W3.16 sov_pcc wired, W3.17 Merkle
>   domain-sep (966), W3.19 ecdsa low-s/slhdsa/fe25519, W3.20 pq nibble guard (967),
>   W3.22-COMBINE-10 (murmur3→endian), W3.23/24/27/28 dead-matter cuts (CUT-1/2/5/6 gone).
> - **RE-VERIFIED 2026-06-12 (live-tree fan-out + W3.7 landed):** W3.1 DONE (see body),
>   **W3.7 DONE** — egg-style parents index + dirty worklist landed in egraph.iii (eg_par_append/
>   EGRAPH_DIRTY, eg_rebuild incremental with eg_rebuild_full as gated fallback + oracle;
>   differential falsifier corpus 1479 proves byte-identical seal vs full wipe on a forced
>   cross-pass cascade), W3.9 DONE (bigint_div.iii Knuth Alg-D, corpus 757/990), W3.5 DONE
>   (optinvoke mhash_domain), W3.26 DONE (CUT-4 collapsed).
> - **⛔ GAP (re-verified open):** W3.22-COMBINE-8 (checked→option table), W3.18 AES gmul
>   data-dependent branch + S-box (PARTIAL), W3.21 three micro-fixes (PARTIAL), W3.12/13
>   perf sub-items (PARTIAL), W3.29 dead u32 masks, W3.30 CUT-10 residue.
> - **✅ W3.25 CUT-3 — NOW CLOSED (this pass):** code-fix was already in (`ma_in_flight` deleted,
>   O(1) `NEXT_ISSUE − RETIRED_COUNT`); its **missing mandatory ROB-saturation falsifier** is now
>   added — corpus 952 (ROB_CAP=2 vs 8 back-pressure proves issue gates on the in-flight counter).
> - **◻ TO RE-VERIFY (spot-check each before check-off):** W3.5 (A-OI-2 optinvoke domain-sep),
>   W3.12 perf cluster, W3.13 support-module cluster, W3.18 fp256/aes constant-time, W3.21
>   soundness micro-fixes, W3.26 CUT-4, W3.29 CUT-8, W3.30 CUT-10/11.


> Read `-PLAN-00-DOCTRINE.md` + `-VERIFICATION.md` first. All line numbers observed 2026-05-29,
> advisory — re-`Grep` the named symbol before editing. Seal class for every task here is
> **STDLIB_GATE** unless noted (no bootstrap reseal): `bash STDLIB/scripts/build_stdlib.sh` → grep
> `FAIL = 0`; `bash STDLIB/scripts/run_corpus.sh` GREEN + the task's new falsifier KAT. **Every task
> is falsifier-first** (write the KAT, see it fail, fix, see it pass) per I4, and proves
> bit-identical determinism (I1) where it touches a hot path or hash.

This wave depends on Wave 0 (the organs) and Wave 2 (the trusted base). It is grouped:
3A consumers heal · 3B performance · 3C new primitives · 3D soundness hardening · 3E dead matter.

---

## 3A · Consumers heal (shared-dependency corrections)

### W3.1 · Migrate the linear scans onto `caindex` (COMBINE-3 consumers) [DONE 2026-05-30]
**Verified + CLOSED.** caindex redesigned caller-owned (no cross-consumer collision). Migrated:
`math_library_curation` (W0.3), `theorem_carrier` (16384-scan→O(1)), `computation_graph` (anchor
table→O(1); branch table intentionally NOT migrated — no insert path, would be dead state),
`ripple_metric rm_sep` (all-pairs→O(N) bucket-and-group: Σ C(m,2)), `ripple_loop rl_run`
(all-pairs→O(N): hoist loop-invariant cg_decide, bucket by group key, union each member with its
rep = N−G merges). `omnia/unify` + `omnia/lru` EXCLUDED (u64-keyed, not 32-byte content-ids).
- [x] **Step 1** — determinism KATs: 754 (cg anchor positive round-trip + governance-not-bypassed),
  755 (rm_sep == O(N²) ground-truth over rm_unifiable, order-independent, group sizes 5/3/10),
  756 (rl_run == N−G across group sizes, intent-variation split, both gates fail closed).
- [x] **Step 2** — scans replaced via cai_put/cai_get; all-pairs sites bucket-and-group as specified.
- [x] **Step 3** — existing oracles byte-identical green (645/917/919/930/932) + full corpus 618/0.

### W3.2 · NTT heals the silent large-multiply break (RIPPLE-2) [HOLDS] — discharged by W0.7
**Verified:** HOLDS; D-KARA-1 silent-wrong-product live. The fix and its falsifier
(`{NNN}_bigint_ntt_largemul`) are **W0.7 Steps 1+5**. This entry exists for traceability; no
separate task. Confirm the W0.7 large-multiply KAT covers every `bigint` consumer (RSA keygen,
ed25519) via a downstream KAT.

### W3.3 · Crystal minting id-band (RIPPLE-3) [PARTIALLY_WRONG — path]
**Verified:** minter is **`omnia/crystal.iii`** (not numera). `crystal_slot_of` + `CRYSTAL_ID_BASE
0x10000` confirmed. Consumers `scalar_provenance` (D-SP-1), `field_crystal` (D-FC-1/FC-COLLIDE-1),
`checked_crystal` (D-CC-1), `q128_f64`.
- [ ] **Step 1** — falsifier KAT first: drive a case where a success id collides with a crystal id
  (FC-COLLIDE-1) and assert they are now disjoint (crystal ids ≥ `CRYSTAL_ID_BASE`). Also assert
  D-SP-1: `scalar_provenance` passes a **parent id** (not an operand value) into the chain. Fail first.
- [ ] **Step 2** — fix in the shared minter `omnia/crystal.iii` (id allocation is a system-wide
  contract; per-file fixes are the wrong altitude): mint into the disjoint high band; ensure all four
  consumers resolve through `crystal_slot_of` (the transparent property the audit notes).
- [ ] **Step 3** — pass the KAT + all four consumers' corpus byte-identically where unaffected.
  Commit: `fix(crystal): RIPPLE-3 disjoint crystal id band in the shared minter; close FC-COLLIDE-1/D-SP-1/D-CC-1`.

### W3.4 · `cgr_contains` read-only query (RIPPLE-4) [PARTIALLY_WRONG]
**Verified:** A-RX-1/A-RX-2 core HOLDS (`ripple_extract`'s audit probe interns the address it
audits → history-dependent, false-admits at capacity). Correction: A-RL-1 is misattributed (it is a
dead outer-loop defect, not the `cg_decide` hoist) — fix the citation, keep the query fix.
- [ ] **Step 1** — falsifier KAT first: call the capability audit twice and at ring capacity; assert
  the verdict is **call-history-independent** and that a hallucinated export is **rejected** even at
  capacity (today it false-admits). Fail first.
- [ ] **Step 2** — add `cgr_contains(ring, addr) -> u8` (pure read-only membership) to
  `numera/congruence.iii`; rewrite `forcefield/ripple_extract.iii rx_export_in_g` to use it,
  **never mutating** the audited ring.
- [ ] **Step 3** — pass; commit: `fix(congruence,ripple_extract): RIPPLE-4 add read-only cgr_contains; audit probe no longer mutates the audited ring`.

### W3.5 · cad/builder error-contract sweep (RIPPLE-5/RIPPLE-6) [PARTIALLY_WRONG/HOLDS] — partly W0.1
**Verified:** RIPPLE-6 four builder-push citations discard returns (live). RIPPLE-5: `cad` thesis
holds; corrections — A-CG-1 already sealed-correct in `cg_seal_ok` (verify per-site, not blanket);
A-OI-2 is a **domain-separation** defect (prefix a fixed domain via `mhash_domain`), not a swallowed
return. The base32/format/inet builder sweep is **W0.1 Step 5**; this task covers the remaining cad
sites + A-OI-2.
- [ ] **Step 1** — falsifier KAT first per remaining site: force a `cad_oneshot` null/zero input
  (writes nothing) and assert the caller does **not** false-match on stale bytes; for A-OI-2 assert
  two different domains produce different `oi_seal`. Fail first.
- [ ] **Step 2** — capture+check the `cad_oneshot` return at each unaudited `*_oneshot` site (lever
  X23 sweep); add the `mhash_domain` prefix to `optinvoke oi_seal` (A-OI-2). Leave already-fixed
  `cg_seal_ok` (cite it as the template).
- [ ] **Step 3** — pass; commit: `fix(cad-consumers): RIPPLE-5 audit every *_oneshot return; A-OI-2 domain-separate optinvoke seal`.

### W3.6 · `cpufeat` AVX-512DQ + forced-path KATs (RIPPLE-8) [PARTIALLY_WRONG]
**Verified:** D-BI-1 HOLDS (no `cpufeat_has_avx512dq`; `bigint.iii:570` gates an AVX-512 path needing
DQ → crash on AVX-512F-only CPUs). X17 evidence set partly misattributed; the forced-path-KAT
discipline is the fix.
- [ ] **Step 1** — add `cpufeat_has_avx512dq()` (bit-17 detection) to `numera/cpufeat.iii`; gate
  `bigint.iii:570` on it. Falsifier: a unit test that, with DQ masked off, the scalar path is taken
  (no DQ instruction emitted/executed). Fail first.
- [ ] **Step 2 (the X17 discipline)** — add a **forced-path KAT** per accelerated module (`sha256`,
  `sha512`, `chacha20`, `mlkem`, `bigint`): run the scalar, AVX2, and AVX-512 paths on one fixed
  vector and assert **byte-identical** output (closes the determinism-across-machines hazard the
  audit names — today bit-identity is asserted only in comments). This is the I1 guard for SIMD.
- [ ] **Step 3** — pass; commit: `fix(cpufeat,bigint): RIPPLE-8 D-BI-1 AVX-512DQ detection + X17 forced-path bit-identity KATs (scalar≡AVX2≡AVX-512)`.

---

## 3B · Performance (the engine runs hotter)

### W3.7 · Incremental egraph rebuild (ENHANCE-1) [HOLDS]
**Verified:** HOLDS, no line drift (`eg_rebuild:494-515`, wipe `:502-503`, `eg_saturate:925-947`).
Today wipes the full 262144-slot hashcons every pass. **Surpass:** deferred-rebuild dirty worklist;
**drain in ascending class id** for determinism (I1).
- [ ] **Step 1** — determinism KAT first: assert incremental rebuild yields **byte-identical** egraph
  state + seal to the full-wipe rebuild on a multi-step saturation fixture (and a worklist-order
  independence assertion). Fail first.
- [ ] **Step 2** — maintain a dirty worklist of touched classes; canonicalize only affected parents;
  drain ascending class id. Keep the full wipe as a gated fallback (mirror W0.6's pattern).
- [ ] **Step 3** — `614_egraph`/`906_eg_integrity` byte-identical; commit: `perf(egraph): ENHANCE-1 incremental deferred rebuild (ascending-class-id drain; seal byte-identical)`.

### W3.8 · Real micro-arch cost field (ENHANCE-4 / SEPARATE-3) [HOLDS/DRIFTED]
**Verified:** stub all-ones at `sov_isa.iii:161-170`. **Key correction:** the 6-vector producer
**already exists** — `cost_calculus.iii cc_evaluate:237` (byte-compatible 6×u64). So the fix is to
delegate, not build a new model (and `SI_CVEC:97` is `[u64;6]`, drop-in).
- [ ] **Step 1** — gradient KAT first: assert `SI_CVEC` for `SI_MUL` vs `SI_SHL` vs `SI_ADD` differ
  per-dimension, and that two ops with equal mul-count but different latency extract to **different**
  realizations (positive arm); a flat re-seed FAILS the assert (negative arm). Fail first.
- [ ] **Step 2** — in `sov_isa.iii` add `extern fn cc_evaluate(req:*u8,out_cost:*u64) from
  "cost_calculus.iii"` + `cc_init`; rewrite `sov_isa_op_cost(tag)` to build a single-op req per tag,
  call `cc_evaluate(req,&SI_CVEC)`, then `cl_dot_slot(CL_BALANCED,...)` as today. Map `SI_*` tags to
  `cost_calculus` opcodes via a module-scope static table (no local arrays — trap list).
- [ ] **Step 3** — re-pin `874_sov_isa_descent`/`876_sov_isa_optimizer` to the new cost-justified
  extractions (they WILL change — that is the point) + gradient KAT passes. Commit: `feat(sov_isa): ENHANCE-4/SEPARATE-3 real 6-D cost field via cost_calculus.cc_evaluate (stub all-ones retired)`.

### W3.9 · Knuth Algorithm D for bigint division (ENHANCE-5) [DONE 2026-05-30]
**CLOSED.** `bigint_div_qr` is now Knuth Algorithm D (base-2^32 half-limb, ~64×); bit-serial RETAINED
as `bigint_div_qr_bitserial` (differential oracle + one-line revert). Corpus 757 gates it: differential
(== bit-serial) AND invariant (q·b+r==a ∧ r<b) over 300 random + crafted edges (single-digit divisor,
2^32 boundary, scaled Warren add-back trigger). RSA (373) + div KATs (47/48) + full corpus 618/0 green.
All u64 arith (no i64 traps), module-global digit arrays, / and % off array loads (no modulo-after-call).
- [ ] **Step 1** — KAT first: random + adversarial divisors (incl. high-bit-set, single-limb, full-
  width) asserting quotient/remainder == the current bit-serial reference (byte-identical). Fail first
  against a deliberately broken normalization to prove the negative.
- [ ] **Step 2** — implement Knuth Alg D (normalize, estimate q̂ with the two-limb correction,
  multiply-subtract, add-back) over the limb arrays; keep the bit-serial as a gated reference oracle.
- [ ] **Step 3** — RSA/ed25519 KATs + the new KAT pass; commit: `perf(bigint_div): ENHANCE-5 Knuth Algorithm D (O(limbs²); bit-serial kept as oracle)`.

### W3.10 · Block-oriented Keccak absorb (ENHANCE-7) [HOLDS]
**Verified:** HOLDS; per-byte absorb at the cited site (`:52-61`); THE hot path (every content
address/witness id). Mirror `keccak.iii`'s existing block routine; bit-identical.
- [ ] **Step 1** — byte-identity KAT first: assert block-absorb produces the **identical** digest to
  the per-byte absorb on multi-block + partial-final-block inputs. Fail first.
- [ ] **Step 2** — replace the per-byte loop with block absorb (full rate blocks at once + a partial
  tail), reusing the existing block routine.
- [ ] **Step 3** — every Keccak/content-address KAT byte-identical; commit: `perf(keccak): ENHANCE-7 block-oriented absorb on the content-address hot path (digest byte-identical)`.

### W3.11 · Straus–Shamir double-scalar verify (ENHANCE-8) [HOLDS]
**Verified:** HOLDS; `crypt_ed25519 ed25519_verify`, `ecdsa_p256` do two independent scalar muls.
Public-verify-side data → table-select raises no constant-time concern; honest constant factor (~2×).
- [ ] **Step 1** — KAT first: RFC/test-vector verify results **byte-identical** to the current
  two-mul implementation (accept/reject unchanged) on valid + invalid signatures. Fail first.
- [ ] **Step 2** — interleave the two scalar muls into one doubling per bit with a 4-entry table
  select (`{O, P, Q, P+Q}`). Precompute `P+Q` once.
- [ ] **Step 3** — verify KATs byte-identical; commit: `perf(ed25519,ecdsa): ENHANCE-8 Straus-Shamir interleaved double-scalar verify (~2×; results identical)`.

### W3.12 · Constant-factor sweep (ENHANCE-9 cluster) [HOLDS]
**Verified:** all sub-claims present. Each is an independent micro-task (own byte-identity KAT,
seal gate). Schedule as sub-tasks — for each, the KAT asserts byte-identical output to the current
slow path:
- [ ] `aes.iii` InvMixColumns via xtime chains (E2-AES-2, ~10× fewer ops).
- [ ] `crc32.iii` slice-by-8 (D-CRC-1, 4–8×).
- [ ] `sha512.iii` hoist the per-block CPUID out of the block loop (E2-512-1; today 16 detects/block).
- [ ] `fn256.iii`/`fn384.iii` fewer Newton iterations (D-FN-1/D-FN384-1) — prove convergence bound.
- [ ] `fe25519.iii` dedicated squaring + `dbl-2008-hwcd` doubling (E-FE-2/E-FE-3).
- [ ] `mlkem`/`mldsa` Montgomery PQ primes (E-MLK-2/E-MLD-2) — **discharged by W0.5 Step 3**.
- [ ] `mldsa` in-place NTT vs 512 copy-moves (E-MLD-3).
- [ ] Commit each: `perf(<mod>): ENHANCE-9 <fix> (output byte-identical)`.

### W3.13 · Support-module structural wins (ENHANCE-10 cluster) [HOLDS]
**Verified:** 12-item cluster all present. Each its own KAT; note A-COSTLAT-1 is a **correctness+perf**
fix (subtractive Euclid can hang on adversarial input). The `sema` sub-item (G-SEMA-1/2) is **Wave 6**
(BOOTSTRAP_SEAL); A-PQ-1 is **W0.6**; A-MA-1 is **W3.E CUT-3**. Remaining sub-tasks:
- [ ] Stein binary GCD replacing subtractive Euclid (A-COSTLAT-1) + a hang-on-adversarial-input
  falsifier (the negative the old code fails).
- [ ] Difference-array sweep for register pressure, O(n) (A-CC-1).
- [ ] CSR adjacency for the pleroma gauge, O(V+E) (A-PL-1).
- [ ] Memo-lattice probe stopping at the resolved slot (A-ML-1).
- [ ] Math-library O(1) admission (D-ML-1).
- [ ] Uncertainty-DAG memoization O(V+E) (F-UNC-1).
- [ ] Buchberger 2nd criterion to prune S-pairs (F-GB-2).
- [ ] Combinator optimized bracket abstraction to stop exponential output growth (F-CB-1).
- [ ] Each: byte-identity (or for A-COSTLAT-1, terminate-vs-hang) KAT + seal gate.

---

## 3C · New primitives

### W3.14 · `xoshiro` jump / long_jump (ENHANCE-11) [HOLDS]
**Verified:** HOLDS. **Surpass:** add `jump` (2^128) and `long_jump` (2^192) computed from the
polynomial of the state matrix over GF(2) — exact non-overlapping substream splitting.
- [ ] **Step 1** — KAT first: assert `jump` advances exactly 2^128 (verify against the known xoshiro256**
  jump polynomial on a fixed seed; substreams provably non-overlapping over a bounded draw count).
  Fail first.
- [ ] **Step 2** — implement `jump`/`long_jump` with the published GF(2) jump polynomials (NIH: the
  polynomial constants are part of the algorithm spec, hand-coded, not a dependency).
- [ ] **Step 3** — pass; commit: `feat(xoshiro): ENHANCE-11 jump/long_jump for exact non-overlapping substreams`.

### W3.15 · `bv_ring` beyond six variables (ENHANCE-12) [HOLDS]
**Verified:** HOLDS. **Surpass:** extend the 64-wide single-register all-valuations decider to a
column-stack of u64 words for >6 vars; stays exact (no float, no sampling — within the deterministic
gate).
- [ ] **Step 1** — KAT first: a 7- and 8-variable formula whose validity is known; assert the
  column-stack decider returns the exact verdict; assert a satisfying assignment is recoverable. Fail
  first (current decider caps at 6 vars).
- [ ] **Step 2** — generalize the all-valuations bitset to ⌈2^k / 64⌉ u64 columns; iterate the
  Boolean ops per column.
- [ ] **Step 3** — pass; commit: `feat(bv_ring): ENHANCE-12 column-stack all-valuations decider for >6 variables (exact)`.

### W3.16 · Wire the proof-carrying primitive behind the optimizer (ENHANCE-13) [PARTIALLY_WRONG]
**Verified:** PARTIALLY_WRONG. `zk_snark` Groth16 is genuinely unwired (only corpus 375). **But** the
optimizer's proof-carrying disposer is the kernel (`typecheck`+`ccl`), and the actual unwired-PCC
primitive in that pipeline is **`sov_pcc`** (A-PCC-1), not Groth16. **Corrected fix:** wire `sov_pcc`
behind the proposal pipeline (`sov_pipeline`); expose `zk_snark` separately as a latent capability if
desired, but do not conflate it with "the" PCC.
- [ ] **Step 1** — KAT first: a proposed optimization with a valid PCC certificate is **admitted**,
  and one with an invalid/absent certificate is **rejected** by the pipeline (prove the negative).
  Fail first (sov_pcc not invoked today).
- [ ] **Step 2** — invoke `sov_pcc` from `sov_pipeline`'s "propose → kernel disposes" gate; the
  kernel (`tc_conv`) remains the arbiter; `sov_pcc` carries the certificate.
- [ ] **Step 3** — pass; commit: `feat(sov_pipeline): ENHANCE-13 wire sov_pcc (A-PCC-1) behind the optimizer proposal gate; reject uncertified proposals`.

---

## 3D · Soundness hardening

### W3.17 · Domain-separated, arity-framed Merkle hashing (ENHANCE-18) [HOLDS]
**Verified:** HOLDS; `forcefield/ripple.iii` Merkle DAG has no leaf/node domain separation, no length
framing → second-preimage / leaf-as-node confusion. `cad`'s `0x00` separator means no new primitive.
- [ ] **Step 1** — falsifier KAT first: construct a leaf value equal to a child address and assert it
  does **not** collide with the one-input computed cell (today it does). Fail first.
- [ ] **Step 2** — tag leaves vs interior nodes (distinct domain byte, reuse `cad`'s separator) and
  prefix an explicit arity in `rn_hash`/`rn_recompute`.
- [ ] **Step 3** — assert `rn_graph_root` changes only as intended; commit: `fix(ripple): ENHANCE-18 domain-separate + arity-frame the Merkle DAG (close leaf-as-node 2nd-preimage)`.

### W3.18 · Constant-time claims matched to reality (ENHANCE-19) [PARTIALLY_WRONG]
**Verified:** PARTIALLY_WRONG — **x25519 cswap already branch-free (fixed)**. Remaining: `fp256`
borrow branches on secret (D-FP-1); `aes` S-box indexed by secret + branch in field multiply
(E2-AES-1).
- [ ] **Step 1** — falsifier KAT first per site: assert no secret-dependent branch/index remains
  (a data-independence assertion — e.g. equal cycle/op trace across secret values, or a structural
  check that the S-box access is masked). Fail first.
- [ ] **Step 2** — `fp256`: branch-free masked borrow. `aes`: bitsliced or masked S-box + branch-free
  field multiply. If a site cannot be made constant-time without larger work, **drop the
  `@constant_time` annotation** until it holds (an unfounded assertion is worse than honest absence).
- [ ] **Step 3** — pass; commit: `fix(fp256,aes): ENHANCE-19 branch-free constant-time (or drop the annotation); x25519 already done`.

### W3.19 · Standards conformance / canonical encoding (ENHANCE-20) [PARTIALLY_WRONG*] — gaps closed in-session
**Verified (in-session):** all three sub-claims HOLD. E-EC-2: `ecdsa_p256 verify:76-81` checks only
`r≠0`,`s≠0` — no upper-range (`<n`) or low-s. E-SLH-2: `slhdsa` mixes `SHA-256[0..n]` (H_n/PRF) with
`SHAKE-256` (H_msg) — neither FIPS-205 family. E-FE-4: no canonical-decode reject in `fe25519`.
- [ ] **Step 1** — falsifier KATs first: (a) ECDSA: a high-s (malleable) signature is **rejected**
  (today accepted); a `s ≥ n` signature rejected. (b) SLH-DSA: a FIPS-205 SHA2 KAT vector
  **verifies** (today fails to interoperate). (c) fe25519: a non-canonical encoding (`y ≥ p` /
  bad high bit) is **rejected** on decode. Fail first.
- [ ] **Step 2** — ECDSA: add `1 ≤ r,s ≤ n-1` range check + low-s (`s ≤ n/2`) enforcement. SLH-DSA:
  conform to a single FIPS-205 family (use the SHA2 family's MGF1/HMAC-SHA2 for H_msg/PRF, or the
  SHAKE family throughout) — **or** rename the module to its true non-standard instantiation (the
  audit's "conform or correct the claim"; surpass-only prefers conform). fe25519: add the RFC 8032
  canonical decode checks.
- [ ] **Step 3** — pass; commit: `fix(ecdsa,slhdsa,fe25519): ENHANCE-20 range/low-s + FIPS-205 conformance + RFC8032 canonical decode`.

### W3.20 · Degenerate cases fail rather than emit invalid output (ENHANCE-22) [PARTIALLY_WRONG]
**Verified:** per-sub-claim status: E-RSA-1 HOLDS (`rsa.iii:485-491` ships `d=0` as success when
`φ%e==0`); E-EC-3 HOLDS (sign never retries on degenerate `r==0`/`s==0`; only `sign_det` retries on
`k==0`); E-PQD-2 (zero-nibble underflow) verify individually.
- [ ] **Step 1** — falsifier KAT first per sub-claim: RSA keygen with `φ%e==0` is **rejected** (today
  ships dead key); ECDSA sign retries (or rejects) on degenerate `r==0`/`s==0`; PQ dispatcher rejects
  a zero suite low-nibble (today underflows). Fail first.
- [ ] **Step 2** — uniform "reject or retry, never proceed with an invalid artifact": RSA reject
  (`E_DEGENERATE`); ECDSA retry the nonce on `r==0`/`s==0`; PQ dispatcher guard the nibble.
- [ ] **Step 3** — pass; commit: `fix(rsa,ecdsa,pqdispatch): ENHANCE-22 degenerate cases reject/retry (no invalid artifact)`.

### W3.21 · Soundness micro-fixes (ENHANCE-23) [PARTIALLY_WRONG]
**Verified:** one of four already done — verify each individually before scheduling:
- [ ] `merkle.iii` make the dead `cur_idx` load-bearing so it binds the leaf index into verification
  (MERKLE-2, **strengthens** soundness) — if still open. Falsifier: a leaf presented at the wrong
  index is **rejected**.
- [ ] `bv_ring` model shift-by-width to match the x86 mask (C-BV-1) so a rewrite is not certified
  against semantics the target does not honor — if still open.
- [ ] polynomial commitment: domain-separate leaves by index → position-binding not multiset
  (C-PC-3) — if still open. Falsifier: a permuted-leaf commitment is distinguished.
- [ ] `nous_search` distinguish oracle capacity error from genuine "no answer exists" (C-NS-1) so a
  resource error is never reported as a trusted refutation — if still open. Falsifier: capacity error
  ≠ refutation code.
- [ ] Each: falsifier-first, seal gate. Commit per item.

### W3.22 · Direct duplications (COMBINE-8/10/11) + COMBINE-9/12 cross-refs [HOLDS]
**Verified:** COMBINE-8 HOLDS (`checked` u64 table duplicates `option`'s); COMBINE-10 HOLDS
(`murmur3` LE load == `endian_load_u32_le`, endian.iii:36-42); COMBINE-11 HOLDS but over-generalized
(double-eval only in 4 sat ops). COMBINE-9 reduction half = **W0.5 Step 4**; COMBINE-12 header
repoint = **W2.4 Step 2**.
- [ ] **COMBINE-8** — unify `checked`'s u64 table onto `omnia/option`'s (D-CHK-2). KAT: byte-identical
  results; commit `refactor(checked): COMBINE-8 reuse option's u64 table`.
- [ ] **COMBINE-10** — `murmur3_32:40-44` calls `endian_load_u32_le` (add the extern). KAT 88 stays
  byte-identical; commit `refactor(murmur3): COMBINE-10 reuse endian_load_u32_le`.
- [ ] **COMBINE-11** — route the four double-evaluating `sat_arith` ops onto `scalar`'s single-pass
  saturating ops (D-SA-1, scope to the 4 ops only — not a blanket rewrite). KAT byte-identical;
  commit `refactor(sat_arith): COMBINE-11 delegate the 4 double-eval ops to scalar`.

---

## 3E · Dead matter (delete) — precise removals

> **Removal hazard (I5 + adversarial discipline):** each was confirmed dead by an exhaustive
> tree-wide + machine-code reference search. **Never `replace_all`** on a prefix-colliding symbol
> (CUT-5). Each task: confirm-dead → delete → prove the existing KAT stays GREEN byte-identical.

### W3.23 · CUT-1 — `TL_VAL_FILLED` 4 MB dead BSS [HOLDS]
File: **`numera/temporal_logic.iii`** (not tempora). `TL_VAL_FILLED:82` (4 MB, write-only, no reader),
sole setter `tl_filled_set:111-116`, ~20 call sites (clear loop `:408`; `tl_prop_node` 245/254/261/268/279;
`tl_temp_node` ~13 sites; `tl_kat_inject:489`).
- [ ] Delete line 82, `tl_filled_set:111-116`, the `tl_filled_set(rs,rp,0u8)` at :408 (keep the
  `tl_val_set` zero-clear), and every `tl_filled_set(...)` statement. Update
  `DOCS/CONVERGENCE-SPECS/temporal_logic.spec.md` (drop the FILLED-memoization narrative).
- [ ] `644_temporal_logic`=99 byte-identical (every read uses `tl_val_get` on `TL_VAL`). Commit:
  `cut(temporal_logic): CUT-1 delete write-only TL_VAL_FILLED (4 MB BSS + O(subf*L) clear)`.

### W3.24 · CUT-2 — dead cost-lattice constants [HOLDS] (asymmetric)
File: `numera/cost_lattice_synth.iii`. **Surpass (asymmetric):** *wire in* `CLS_DESC_BYTES:78` as a
named-offset schema (`CLS_DESC_DIM_OFF=0`, `CLS_DESC_DECL_OFF=8`, `CLS_DESC_OBS_OFF=16`,
`CLS_DESC_BYTES=CLS_DESC_OBS_OFF+8`) at the three hardcode sites (pack `:286/290-292`, emit-read
`:331/336-337`, scratch `CLS_KDESC:94`); **delete** `CLS_DIM_RESERVED:66` (unreferenced AND
duplicates `CLS_K_END=13`). Emitted bytes unchanged (compile-time const fold → I1).
- [ ] Apply the asymmetric fix; `642_cost_lattice_synth` + `cls_selftest` GREEN byte-identical; sync
  the spec docs. Commit: `cut(cost_lattice_synth): CUT-2 wire CLS_DESC_BYTES as offset schema; delete dead CLS_DIM_RESERVED`.

### W3.25 · CUT-3 — `ma_in_flight` retired by O(1) counter [HOLDS]
File: `numera/microarch_model.iii`. Delete `ma_in_flight:169-179`; at `:201` seed `in_flight` from
`UARCH_NEXT_ISSUE - UARCH_RETIRED_COUNT` (exact; underflow impossible since `RETIRED_COUNT ≤
NEXT_ISSUE`). **Mandatory falsifier (the audit omits it):** the KATs never saturate the ROB
(`ROB_CAP=224`, `n≤3`), so add a small-`ROB_CAP` (e.g. 2) KAT with dependent ops asserting the exact
back-pressure cycle count — without it `616`=99 passes for both the scan and a broken subtraction.
- [ ] Falsifier-first (ROB-saturation KAT fails on a broken subtraction), then the cut; `616`=99
  byte-identical trace hash; update `microarch_model.spec.md` Algorithm 4. Commit:
  `cut(microarch_model): CUT-3 ma_in_flight -> O(1) counter subtraction + ROB-saturation falsifier`.

### W3.26 · CUT-4 — unreachable return in `ripple_unify` [DRIFTED→HOLDS-on-substance]
File: `forcefield/ripple_unify.iii`. `ru_certify_unify:49-51` — after the certified
`cgr_union_certified` returns 1, `cgr_find(i)==cgr_find(j)` is a proven post-condition, so `:51 return
0` is unreachable. Collapse `:50-51` to a direct `return 1u32`.
- [ ] Collapse; `918_ripple_unify`=99 byte-identical (no arm reaches :51). Commit:
  `cut(ripple_unify): CUT-4 collapse unreachable return-0 to certified return-1`.

### W3.27 · CUT-5 — `XJN_NJ` dead BSS [HOLDS] (prefix hazard)
File: `omnia/xii_joinability.iii`. Delete **only** line 62 `var XJN_NJ : [u64;4]`. **Do NOT
`replace_all`** — `XJN_NJ_I/_J/_P` (`:63-65`) and `XJN_TALLY` (`:61`) are LIVE and share the prefix.
- [ ] Delete line 62 only; verify the emitted `.o.s` loses `L_XJN_NJ` but keeps `L_XJN_NJ_I/_J/_P`;
  `813_xii_joinability`=99. Commit: `cut(xii_joinability): CUT-5 delete dead XJN_NJ (single line; siblings untouched)`.

### W3.28 · CUT-6 / CUT-7 — dead fixed-point scales & redundant Massey [HOLDS/DRIFTED]
- [ ] **CUT-6** — `numera/fixed_extra.iii`: delete dead `FX16_SCALE`/`FX24_SCALE`/`FX48_SCALE`
  (D-FX-4) after a tree-wide ref check; commit `cut(fixed_extra): CUT-6 delete dead FX*_SCALE`.
- [ ] **CUT-7** — `numera/galois.iii`: delete the redundant Massey comparison (D-GAL-2; locate the
  exact dead branch by Grep — source gave no line); a galois KAT stays GREEN. Commit:
  `cut(galois): CUT-7 delete redundant dead Massey comparison`.

### W3.29 · CUT-8 — the dead u32 masks (X9 sweep) [HOLDS]
Files: `scalar.iii` (D-SC-2), `checked.iii` (D-CHK-4), `murmur3.iii` (D-MUR-2), `fold`, `either`
(+ false "u31" comment), `sha256_dispatch.iii` (+ dead `_selected`). Each `& 0xFFFFFFFF` on an
already-u32 value is a no-op.
- [ ] Remove each dead mask + the dead `_selected` + fix the `either` "u31" comment, **after**
  confirming the value is already u32-typed (so removal is bit-identical — assert via KAT). Commit:
  `cut(X9): CUT-8 remove dead u32 masks across scalar/checked/murmur3/fold/either/sha256_dispatch`.

### W3.30 · CUT-10 / CUT-11 — dead refs & the empty certificate [HOLDS]
- [ ] **CUT-10** — remove/repoint dead references: `fold`'s dead `iter_u8_remaining` extern;
  `nous_value`'s stale "49 by 49 selection sort" label (work is linear); `nous_socket`'s R001-R004
  order-table entries (retired rule ids — wasted compares); `xii_joinability`'s retired R001-R003
  range test (B-JN-1). Re-express in live rule ids or delete. Commit per file.
- [ ] **CUT-11** — `nous_completion`'s "convergence certificate" binds nothing (constant hash of a
  single zero byte; non-ZERO but information-free). **Surpass:** make it bind the actual pair count +
  budget (so it is a real certificate), with a falsifier KAT proving a changed pair-count changes the
  cert. Commit: `fix(nous_completion): CUT-11 bind real pair-count+budget into the convergence certificate`.

---

### Wave-3 completeness check
Every Wave-3 finding is scheduled: consumer migrations onto the Wave-0 organs (3A), the performance
sweep (3B) with byte-identity KATs guarding determinism, the three new primitives (3C), the soundness
hardening (3D) each with a falsifier, and the precise dead-matter removals (3E) each confirmed dead by
exhaustive + machine-code reference search and proven byte-identical. Items discharged elsewhere are
cross-referenced (RIPPLE-2→W0.7, A-PQ-1→W0.6, COMBINE-9→W0.5, COMBINE-12→W2.4, sema→Wave 6).
**Next:** `-PLAN-4-WAVE4.md` (vacuous gates made load-bearing).
