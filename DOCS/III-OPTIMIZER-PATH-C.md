# III — Path C: the kernel-governed, generator-emitted self-optimizing compiler

**2026-06-04.** Operator chose Path C: III's optimizer (sov_isa + CIC kernel) **discovers + proves** the
codegen rewrite rules; a generator **dual-emits** them into `cg_r3.c` + `cg_r3.iii` byte-identically
(fidelity preserved). This replaces the hand-coded peepholes (`dbaa986` strength reduction) with rules
**III itself certifies** — answering "where does the optimizer come in?": the kernel governs the rule-set.

## The architecture

```
cg_opt_rules.iii   (single source of truth: the SR rule table, a .iii data module)
      │
      ├──> CERTIFIER (the kernel-gate, a KAT):   for each rule  op(x,c) → emit(x,a):
      │       (1) WIDTH-INVARIANCE GUARD  — admit only if the equivalence holds at EVERY bit width
      │           (SR/shift family: yes; const-fold that can overflow: NO → REJECT).  THE soundness contribution.
      │       (2) KERNEL PROOF            — sov_pcc_verify proves op(x,c) ≡ emit(x,a) (∀x, via lam x:Nat.refl : Pi).
      │       a rule that fails either is REJECTED → the build fails.  III governs the rule-set.
      │
      ├──> GENERATOR (III, a .iii program): emits cg_opt_rules.h (C mirror) from the .iii table; DRIFT GATE
      │       proves the two are byte-equivalent in content (dual-emit, fidelity).
      │
      └──> cg_r3.{c,iii}: TABLE-DRIVEN peephole — look up (op, const) in the table → emit.  Same table both
              languages → iiis-0 ≡ iiis-2 holds.
```

## The unary-model soundness boundary (the reviewer's catch — load-bearing)

The kernel's Nat model (`sov_lower`) is **unary, unbounded** — it certifies *unbounded-integer*
equivalences. This is **sound only for WIDTH-INVARIANT rules**: `x*2^k = x<<k` holds bit-exactly at every
width (both truncate mod 2^w identically), so the idealized proof transfers. But a width-SENSITIVE rule
(general const-fold where `a+b`/`a*b` overflows) would be **falsely "proven"** by the unary model (it has
no mod-2^w) — exactly the "success from a proxy that doesn't match the real semantics" class
([[project-iii-soundness-audit]] increment-3 / FINDING #2). The kernel **cannot** flag this. Therefore:
**the certifier hard-rejects any non-width-invariant rule** until a fixed-width (mod-2^w) kernel theory
exists. That guard is the soundness contribution; the proof rides on top of it.

## Honesty floor

Even a kernel proof bottoms out in `sov_lower` *asserting* that `shl $k` means ×2^k and source `mul`
means ×. The kernel proves model-A ≡ model-B; that the models match the real x86 op + the real source op
is hand-written (the modeling layer). "III proves its own optimizations" is true **down to the modeling
layer** — not claimed beyond it.

## What lands now vs named follow-on

**Lands (this session):** the single-source table; the certifier with the width-invariance guard
(rejects non-width-invariant — prove-the-negative) + the kernel base-case proof (`mul(x,2)≡shl(x,1)`,
provable today by convertibility); the generator + drift gate; table-driven `cg_r3.{c,iii}`; re-key +
re-seal.

**Named follow-on (honest — the kernel CAN do these; the proof terms are real engineering):**
- **The inductive SR schema** — `∀k. mul(x,pow2(k)) ≡ shl(x,k)` by `natrec` (the eliminator EXISTS,
  `typecheck.iii:111` TC_NATREC, Brick-7 tested) + a distributivity lemma tower (`pow2(k+1)=2·pow2(k)`,
  `double(mul(x,m))=mul(x,2m)`). Makes III kernel-certify the WHOLE family, not just the base case.
- **A fixed-width (mod-2^w) kernel theory** — needed to safely admit width-SENSITIVE rules (const-fold).
  Until then the guard rejects them. The ratchet: every rule the kernel learns to prove is admitted; the
  guard never lets an unproven/width-sensitive rule through. The VALUE is the ratchet + the honest gate.
