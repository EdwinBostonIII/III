# III — Graded / Quantitative Type Theory (QTT) layer

*The next enhancement after the Ripple-Forcefield plan (P0–P6 complete). Named in
P5's own goal ("graded/QTT layer = region/cost_lattice/scalar_provenance") but
never built. Turns the kernel from "what is provable" into "what is provable
**under what resource discipline**" — linear/affine/erased types (the Atkey-QTT /
Idris-2 frontier), still decided by the singular CCL oracle.*

## 0. Interpretation (the non-trivial reading)

QTT (Atkey 2018) attaches a **multiplicity** from a semiring to every binder and
context entry, tracking how many times a variable may be used:

- `0` = **erased** (compile-time/type-level only; must NOT be used at runtime),
- `1` = **linear** (used **exactly** once),
- `ω` = **unrestricted** (used any number of times, including zero).

The trivial reading — a decorative annotation with no usage check — is rejected.
The intended reading is full usage-checking: the kernel computes each binder's
actual usage and verifies it against the declared multiplicity.

## 1. The multiplicity semiring R = {0, 1, ω}  (encode ω = 2)

The "zero-one-many" commutative semiring. Two operations + an ordering:

- **add** (combine two use-sites — sequential/parallel use):
  `0+0=0, 0+1=1, 1+1=ω, x+ω=ω`. Implementation: `add(a,b) = if a+b ≥ 2 then ω else a+b`.
  (Saturating: two linear uses become ω, the only non-obvious case, is forced by
  `1+1=ω` — you cannot use a linear variable twice.)
- **mul** (scale a usage by a multiplicity — a var used inside an arg applied q times):
  `0·x=0, 1·x=x, ω·ω=ω, ω·1=ω`. Implementation:
  `mul(a,b) = if a==0 ∨ b==0 then 0 elif a==2 ∨ b==2 then ω else 1`.
- **fits(computed, declared)** (the discipline — is the actual usage admissible?):
  declared `0` ⇒ computed must be `0`; declared `1` ⇒ computed must be `1` (exact —
  linear is exactly-once, not at-most-once); declared `ω` ⇒ computed may be anything.
  Implementation: `fits(c,d) = if d==ω then 1 elif c==d then 1 else 0`.

These satisfy the commutative-semiring laws (0 = +-identity, 1 = ·-identity, ·
distributes over +, 0 annihilates ·). Verified by exhaustive 3×3 KAT tables.

## 2. The usage rule — single-multiplicity formulation

Rather than a usage *vector* over the context (awkward in iii — needs temporaries
and clobbers a global), compute usage **one variable at a time**:

> `tc_var_usage(t, k) → R`  =  the multiplicity with which term `t` uses de Bruijn
> variable `#k`.

Rules (runtime subterms accumulate; **type-level subterms are erased = 0**):

- `VAR #j`        → `1` if `j==k` else `0`.
- `APP(f, a)`     → `add( usage(f,k),  mul( q_f, usage(a,k) ) )`, where `q_f` =
  the multiplicity of `f`'s Π-domain (infer `f`, whnf to a Π, read its mult; a
  well-typed app's `f` is always a Π — non-Π falls back to ω, never hit).
- `LAM(_, body)`  → `usage(body, k+1)` (inside the binder, outer `#k` is `#(k+1)`;
  the domain is type-level ⇒ 0).
- `PAIR(a,b)`→`add(u(a),u(b))`; `FST/SND(p)`→`u(p)`; `IF(s,t,e)`→`add(u(s),add(u(t),u(e)))`;
  `SUCC(n)`→`u(n)`; `ANN(t,_)`→`u(t)`.
- `PI/SIG/SORT/BOOL/NAT/UNIT/EMPTY/ZERO/TRUE/FALSE/TT` (types & closed atoms) → `0`.

The discipline check:

> `tc_qtt_ok(t)` → recurse over `t`; at every `LAM` with declared multiplicity `q`,
> require `fits( usage(body, 0), q )`; reject (0) at the first violation, else 1.

**Soundness (adversarially self-checked):** shadowing is handled by the `k+1`
shift under LAM; the argument is correctly scaled by the function's multiplicity
(`f a` uses `a` exactly `q_f` times); `ω` admits zero uses (unrestricted = no
constraint); nested/shared binders are each checked independently. The meta-
property "a QTT-passing term respects its multiplicities" is a metatheorem
witnessed by the KAT's positive + negative arms, not claimed in-kernel.

## 3. Integration (additive, zero-regression)

- A parallel array `TC_MULT : [u32; 16384]`, indexed by node. BSS-zero =
  **"unmarked" → decodes to ω**, so every existing (un-annotated) Π/λ passes QTT
  trivially (unrestricted). Codes: `0=unmarked→ω, 1=erased(0), 2=linear(1), 3=ω`.
- Constructors `tc_pi_q(dom,cod,code)` / `tc_lam_q(dom,body,code)` set `TC_MULT`.
- QTT is a **layer**: `tc_qtt_ok` runs *after* `tc_infer` type-checks a term.
  `infer`/`check`/`tc_conv` and the CCL oracle are **untouched** — no regression.
  (A later brick may fuse usage into `check` so it is enforced, not just checkable.)

## 4. Brick sequence (the P5 cadence — each gated, positive + negative)

- **B1 — DONE (green).** `TC_MULT` array (BSS-zero=unmarked→ω, zeroed in tc_mk/3/4);
  semiring (`tcq_decode/add/mul/fits`); `tc_pi_q`/`tc_lam_q`; multiplicity carried
  through the CCL round-trip via **mult-specific PI atoms** (ω=2060 unchanged →
  zero-regression; erased=2065, linear=2066 — so Π^q of differing mult are
  non-convertible), and `infer(LAM)` propagates the binder's q into its Π type;
  `tc_arg_mult`/`tc_var_usage`/`tc_qtt_ok` (context-aware). KAT `865`: semiring laws
  (8) + linear-used-once/erased-unused/ω-used-once ADMIT + linear-unused/erased-used
  REJECT + **the q-scaling keystone** (`λ^ω g:(Bool→^q Bool). λ^1 x. g x`: ADMIT for
  q=linear, REJECT for q=ω — identical syntax, verdict flips on g's domain
  multiplicity, which only works because mult survives ctx-lookup+whnf). Falsifiable:
  neutering `tcq_fits` → 865 fails at the fits-teeth check. infer/check/tc_conv and
  the CCL reducer are otherwise untouched (no regression).
- **B2 — DONE (green).** Usage through the eliminators: `tc_var_usage` refined —
  IF/CASE branches combine by the semiring **JOIN** `tcq_lub(a,b)=a if a==b else ω`
  (only one branch runs, so a var used once in *each* branch is still linear), not
  the sum; NATREC/CASE/J/TRANSP/ABSURD motives erased (mult 0); the recursor step
  (ITER/NATREC) used ω (dynamic depth). Closed a brick-1 **soundness gap**: the
  fallback `→0` for INL/INR/REFL/eliminators undercounted (an erased var used inside
  `inl x` was wrongly admitted) — now exhaustive. `tc_qtt_ok` rewritten exhaustive +
  context-aware (PI/SIG push their binder so lams in codomains get the right
  context). KAT `866`: the IF join pair (`if(true,x,x)` ADMIT vs `if(true,x,false)`
  REJECT for linear), the INL soundness fix, recursor-ω, type-position erasure;
  falsifiable (lub→sum → 866 fails the join law).
- **B4 — DONE (green).** ERASURE SOUNDNESS. ★ The math-olympiad "step back"
  dissolved the need for a fragile `tc_erase` de-Bruijn transform: **erasure is
  already realized by the normalizer** — an erased argument is substituted but,
  unused at runtime, vanishes in the normal form. The rigorous content is the
  **irrelevance theorem**: `f Bool ≡ f Nat` for a mult-0 type arg A (the kernel's
  own equality, the CCL oracle, cannot observe the erased argument — domain-erased
  conversion), so dropping A is sound; contrasted with `g true ≢ g false` (a
  relevant arg IS observable). KAT `867`: QTT-validity of the erased marking +
  irrelevance + nf-witness (`(f Bool) true → true`, A gone) + the relevant
  negative. Inherently two-sided (a degenerate always-1 oracle fails the relevant
  arm, always-0 fails the irrelevance arm).
- **B3 — SUBSUMED (not a separate brick).** The 0/1 mode's content — type
  subterms / motives at multiplicity 0 — is already realized: b2 erases motives
  and binder domains by the per-tag rule (each kernel position has a *fixed* mode,
  so a per-position rule is exact), and b4 proves the resulting erased-arg
  irrelevance. A formal mode judgment would add only extensibility, no new
  observable capability; recorded honestly rather than implemented as busywork.

## 5. Ceiling

Usage soundness is a metatheorem (witnessed, not self-certified — same status as
the kernel's other metatheory). The semiring is fixed to {0,1,ω}; a general graded
modal layer over an arbitrary ordered semiring is a later generalization, not B1.
