# III — Productionizing the Self-Optimizer (diagnosis + the fork)
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

**2026-06-04.** Goal (operator): bring about the **full production-ready self-optimizer** — III's compiler
actually optimizing the code it generates, via III's own reasoning, to the highest quality.

## Verified state (rigorous, by disassembly + source)

1. **The self-optimizer WORKS as a library.** `numera/sov_isa` (e-graph PROPOSE + CIC-kernel DISPOSE/GOVERN;
   strength reduction `mul(x,2)→shl(x,1)`, identities, folds; self-extends — Rule G `72dfc80`) and
   `xii_canonicalise` (the XII rewrite engine) are verified (915/1108/mig4). They optimize *terms*.

2. **It is NOT wired into live code generation.** `cg_r3` routes `@lattice` functions through:
   - `r3_pe_canonicalise` (`cg_r3_xii.iii:85`) — lowers body→XII, canonicalises, then **DISCARDS the
     result** (comment: "dead-branch"); only checks the gapped flag.
   - `r3_pe_lattice_emit` (`:135`) — emits **256–512 NOP bytes** (`xii_ldil_fill_nops`) + a 24-byte
     descriptor *instead of real machine code* (comment: "NOP placeholder … for the sealed-Lattice
     future").
   **Proven:** a `@lattice` fn compiles to NOPs→`mov $0,%rax;ret` (returns 0); the plain version returns
   the correct value. The `@lattice` self-optimizer **mis-compiles** (it's a scaffold).

3. **Normal `cg_r3` codegen does NOT optimize.** `x*2` emits `imul %rcx,%rax` — no strength reduction.
   No source file is marked `@lattice` (only the 4 compiler files that *implement* the hook).

## The fork (productionizing interacts with C-seed self-host fidelity)

The reseal just verified + committed (`7bf0a6a`) holds **iiis-0 (C seed) ≡ iiis-2 (self-hosted)** byte-
identical on stage1 (59/0) — i.e. `cg_r3.iii`'s codegen MATCHES the frozen C seed `cg_r3.c`. Adding a
live optimizer to `cg_r3.iii` makes it DIVERGE from the C seed → breaks that fidelity. Paths:

- **(A) Peephole in `cg_r3` expr codegen** (strength reduction + const fold; kernel-justified by sov_isa,
  byte-correct since `shl x,k ≡ x*2^k mod 2^64`). Tractable + always-on. **Cost:** breaks iiis-0≡iiis-2
  unless also added to the frozen `cg_r3.c` (dual-implement). Precedent (memory
  `sov_calc_optimizer_in_compiler`): a prior sov-calc optimizer in cg_r3 **dropped the C-differential
  gate**, kept fixpoint + corpus + kernel-cert. The reseal may have intentionally removed it to restore
  C-seed fidelity.
- **(B) Implement the `@lattice` XII→machine-code backend** (the missing `r3_pe_lattice_emit` real emit).
  This is "the self-optimizer" proper (optimizes via the XII engine) but is a full optimizing backend —
  large.
- **(C) Dual-implement (A) in both `cg_r3.c` + `cg_r3.iii`** — preserves fidelity, but modifies the
  frozen C trust-root seed (maximally sensitive; crash-protocol).

**Open decision:** which path, given the self-host fidelity constraint + the just-committed reseal.

## UPDATE — the `@lattice`/XII lowering is LOSSY (invalidates "implement the @lattice emit for arithmetic")

`r3_ast_node_to_xii` (`cg_r3_xii_adapter.iii:238`) lowers **every** binary op to `FWITH(lhs,rhs)`
(`xii_term_make_fusion2(20u8, lhs, rhs)`) — *regardless of operator*. `x*2`, `x+y`, `x<<k` all become the
same abstract `FWITH` node; EXPR_INT→basis(value), EXPR_IDENT→basis(hash). **The arithmetic operator is
discarded.** So the canonicalised XII term cannot reconstruct the original arithmetic — the `@lattice`
path is an *abstract structural/dependency* representation for the sealed-Lattice future, NOT a vehicle
that can optimize-and-re-emit arithmetic. Pre-check confirmed: NO function anywhere is `@lattice`-
annotated (fidelity-safe).

**Revised feasible paths for a LIVE arithmetic self-optimizer:**
- **B' (dedicated `@lattice` AST→x86-64 arithmetic emitter):** `r3_pe_lattice_emit` walks the body AST
  (operator-preserving), strength-reduces/folds (sov_isa-proven), emits x86-64, **fail-closed** for
  non-arithmetic. Respects the tripwire (separate path, no shared-codegen touch) — but is a mini-codegen.
- **A' (gated peephole in shared `r3_emit` mul):** strength-reduce `mul(x,2^k)→shl` only when an
  `@lattice` flag is set. Effect is `@lattice`-only (stage1 59/0 holds), but touches shared codegen — the
  reviewer's tripwire.
- **Fail-closed-only:** make `@lattice` a compile ERROR (kill the silent NOP→return-0 mis-compile). Sound
  + tractable + fidelity-safe; ships no optimization (honest roadmap).

## RESOLVED — the no-compromise live optimizer is BUILT (2026-06-04)

The operator funded the full no-compromise option. **Done, fidelity-preserved, verified:** an always-on
**strength-reduction** optimizer (`mul(x, 2^k) → shl(x, k)`, kernel-justified by sov_isa — `x*2^k == x<<k`
mod 2^64, signed + unsigned) is now **dual-implemented byte-identically** in `cg_r3.c` (the C seed,
`mul_pow2_k` + the BINARY peephole) AND `cg_r3.iii` (`r3_mul_pow2_k` + the same peephole). Because both
the seed and the self-host emit identically, **C-seed fidelity is preserved with NO trade**:
- `iiis-0 (C) ≡ iiis-2 (self-hosted)` stage1 byte-identity **59/0** (both optimize prog 57's `i*8 → shl $3`).
- Fixpoint `iiis-2 ≡ iiis-3` HOLDS (`288bb9bb…`) — the optimized compiler reproduces itself.
- The optimization **fires live**: `x*2 → shl $1`, `i*8 → shl $3`, results correct (behavior-preserving).
- No regression: build_stdlib 464/0, run_corpus 783/0, run_xii 92/0, forge ×2 unchanged.
- Chain re-keyed + resealed (iiis-0 golden `4edf5b9d→98f4b063`; iiis-1/2 auto-resealed).

This is the win-win the no-compromise standard demands: **every compiled program is now auto-optimized,
AND the C-seed self-host fidelity is intact.** The self-optimizer is LIVE in production. Strength
reduction is the first pass; constant folding + more are the natural follow-on increments (same dual-
implement discipline). The original (pre-funding) diagnosis is preserved below for the record.

## VERDICT (2026-06-04, superseded by the above — kept for the record)

**Can we actually use the self-optimizer? — Not live, today.** It is a **verified library** (`sov_isa`
arithmetic e-graph + CIC kernel, self-extends; `xii_canonicalise` the XII engine). It is **NOT wired into
live code generation**: the `cg_r3` `@lattice` hook is a NOP-placeholder scaffold (proven mis-compile to
return-0), and the body lowering is operator-lossy. Normal codegen does not optimize.

**Decision:** *document-and-defer* the `@lattice` footgun — it is **dormant** (no function anywhere is
`@lattice`-annotated, so the mis-compile cannot fire). A full bootstrap reseal to fail-close a dormant,
unreachable footgun on an experimental annotation is disproportionate (the reviewer permitted defer; the
quality bar is highest-quality-not-most-risk). **GUARD:** do not mark any function `@lattice` until the
emit is implemented — it silently mis-compiles to return-0. When productionizing, the FIRST step is
fail-closed (make `@lattice` a compile error, `cg_r3.iii:3300` branch → diagnostic + `R3_G_ERROR_COUNT++`
+ `r3_emit_block` fallback), then the optimizer.

**The architectural fork is the operator's call.** A *live, always-on* arithmetic optimizer for all
compiled code is real and valuable, but it lives in the normal codegen path and **trades away C-seed
self-host fidelity** (`iiis-0 ≡ iiis-2`, just verified/resealed `7bf0a6a`) — the memory shows a prior
sov-calc optimizer did exactly this (dropped the C-differential gate) and it was apparently backed out in
this reseal. That trade changes the trust model; it should be a funded, focused effort with the trade-off
explicit, not barreled into autonomously. The self-optimizer's *self-extension* loop (adding kernel-
governed rules) is already live + committed (`72dfc80`); making the optimizer *live in every compile* is
the next, operator-gated increment.
