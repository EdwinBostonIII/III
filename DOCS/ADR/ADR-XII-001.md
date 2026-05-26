# ADR-XII-001: Sealed Curation over Runtime Inference

## Status
Accepted (Phase XII-α, sealed at Phase XII-ζ Ω12)

## Context

The XII layer is the micro-execution closure of III. It must:
1. Resolve arbitrary high-level intent into machine code with **zero runtime invention**.
2. Provide **perfect day-zero correctness** without iterative refinement.
3. Honor the no-ML, no-observational-learning mandate (H-2, `feedback_no_observational_learning.md`).
4. Be **bit-deterministic** under every compile (H-5).
5. Support the seven commodity targets `x86_avx512`, `x86_avx2`, `x86_scalar_ct`, `arm64_neon`, `arm64_sve2`, `riscv64_v`, `embedded_safe`.

Three approaches were considered:

### A. Runtime inference (ML / JIT)
The compiler observes program behavior, builds a statistical model of intent→implementation mapping, and at compile time selects the model's prediction.

**Rejected.** Violates H-2 (no observational learning), H-3 (no runtime evolution), and H-5 (non-deterministic). Also: opaque to audit, federation peers cannot replay, no formal correctness guarantee.

### B. On-demand synthesis (constraint solving)
At compile time, the compiler takes the high-level intent, applies a constraint solver to derive optimal machine code given the target's ISA.

**Rejected.** Requires SMT/SAT solver dependency (violates H-1 NIH). Non-deterministic timing makes builds non-reproducible. Solver bugs would silently produce incorrect code with no audit trail.

### C. Sealed curation + content-addressed lookup
At day-zero curation, humans hand-curate the 144 productive Horizon patterns: mathematical definitions, hexad/K/cap metadata, and per-target byte sequences. These are sealed into immutable tables. At compile time the compiler walks the term tree, canonicalises via 40 sealed reduction rules, looks up the canonical form's hash in a sealed MPHF, and copies the pre-curated byte slice into the binary.

**Accepted.** Honors every hard constraint. The compiler does zero invention; it executes a deterministic lookup over sealed, hand-audited knowledge.

## Decision

XII adopts **Approach C: sealed curation + content-addressed lookup**.

The architectural choice has three direct consequences:

1. **Curation is finite and one-shot.** The 23 mathematical definitions (18 basis + 6 fusion - 1 redundancy), 40 reduction rules, 117 critical pair convergence proofs, 144 Horizon patterns, 1008 per-target byte slices, 9 proof crystals, 17 provenance transforms, and 8 CT obligation classes are produced once at day-zero. After Phase XII-ζ Ω12 they are frozen forever (modulo R2 major bump or Catalyst-promoted append per `DOCS/III-XII.md` S25 `XII_R1` mutation discipline).

2. **The compiler is a sealed executor.** `iiis-2 + xii_*.c + xii_*.iii` together compile to a frozen artifact whose behavior is 100% determined by the Manifest mhash. Equivalent to substituting a CPU's instruction-fetch with a memory-mapped curated ROM — no decisions are made at compile time beyond looking up the sealed answer.

3. **Zero-cycle dispatch on static-circumstance paths.** Because the Lattice cell payload is just machine code bytes, the Link-Time Lattice Inliner can inline them directly at the call site at link time (S16.2). Runtime dispatch overhead drops to zero. Strictly faster than any runtime-resolved approach.

## Consequences

### Positive
- Bit-deterministic builds (verified at every `build_xii.sh --check-deterministic`).
- Federation peers replay identically.
- Auditable curation: every decision is in the Manifest, signed by Founders-Anchor.
- No runtime ML/JIT surface for attackers to exploit.
- Per-pattern review by crypto engineers possible (the 1008 byte slices are inspectable).

### Negative
- Day-zero curation requires substantial human effort (15+ patterns curated in initial pass; remaining 110 in expansion). This is a known, scoped cost that does not block correctness — uncurated patterns receive deterministic content-addressed payloads that still pass canonicalisation + Lattice verification, just at non-optimised performance.
- New cryptographic primitives or target ISAs require Catalyst-promoted append (S25 mutation discipline). This is intentional friction.
- The 144-pattern cap means certain rare or speculative compositions fall to register-chain fallback (S10.4), trading peak optimisation for predictability.

### Trade-offs Accepted
- **Optimality vs reproducibility:** when a hypothetical optimal byte sequence differs from the curated one, we prefer the curated one. This honors H-3 (no runtime evolution) and H-5 (bit-deterministic).
- **Coverage vs simplicity:** 144 patterns + register-chain fallback covers every expressible algebra term. We do not pursue larger Horizon sets that would inflate Lattice size or fragment audit attention.

## Alternatives Considered

| Approach | Rejected because |
|----------|------------------|
| LLVM-class IR + runtime optimiser | violates H-1 (third-party dep), H-2 (statistical heuristics), H-3 (evolution) |
| eBPF-style verified VM | requires kernel kABI, runtime verification, not deterministic in compiled output |
| Hand-written assembly per function | bypasses sealed audit; no canonical form; no provenance chain |
| Pattern-matching DSL embedded in iii compiler | unable to produce byte slices without external assembler; non-deterministic |
| Hybrid: small core curated + autocomplete | reintroduces ML/learning surface; rejected for same reasons as A |

## References

- `DOCS/III-XII.md` (sealed spec; especially S1 hard constraints, S14.3 no-invention theorem)
- `feedback_no_observational_learning.md` (the operating mandate)
- `DOCS/III-ERRORS.md` §N (XII error codes)
- `DOCS/XII-IMPLEMENTATION.md` (operational status)
- Belazzougui, Botelho, Dietzfelbinger 2009 — CHD construction (NIH-clean MPHF algorithm)
- Knuth-Bendix '70 — confluence completion (used at day-zero for the 40 rules, not at compile time)
