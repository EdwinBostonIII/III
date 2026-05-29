# III — W-types (general well-founded inductive types)

*The next kernel implementation after QTT. The kernel has the SPECIFIC inductives
(Bool/Nat/Sum/Σ/Id); W-types are the GENERAL one — every inductive type is a
W-type (well-founded trees) — closing the foundational data gap. Decided, as
everything, by the singular CCL oracle.*

## 0. The object

`W(A, B)` = well-founded trees whose nodes carry a label `a : A` and have one
child for each element of `B(a)` (the arity family `B : A → U`):

- **Formation**: `A : U_i`, `B : A → U_j`  ⟹  `W(A,B) : U_max(i,j)`.
- **Constructor**: `sup(a, f)` where `a : A` and `f : B(a) → W(A,B)`  ⟹  `: W(A,B)`.
  (A node labelled `a` with its children given by `f`.) Checkable-not-inferable
  (needs the `W` type to know `A`,`B`) — like `inl`/`inr`/`pair`, bridged by `ann`.
- **Eliminator (W-recursor = transfinite/well-founded induction)** `wrec(P, s, w)`:
  - motive `P : W(A,B) → U_k`,
  - scrutinee `w : W(A,B)`,
  - step `s : Π(a:A). Π(f : B(a)→W(A,B)). (Π(b:B(a)). P (f b)) → P (sup(a,f))`
    — given a label, the children function, and **the induction hypothesis** (a
    proof of `P` for *every* child), produce `P` for the node.
  - ⟹ `wrec(P, s, w) : P w`.
- **β / ι**: `wrec(P, s, sup(a,f)) → s a f (λ(b:B(a)). wrec(P, s, f b))`. The IH is
  `wrec` lifted over the children — the one **higher-order** eliminator (its IH is
  a *function*, not a single recursive call as in `natrec`).

Sanity (W subsumes Nat): `Nat ≅ W(Bool, λb. if b then ⊤ else ⊥)` — `zero = sup(false, absurd)`,
`succ n = sup(true, λ_. n)`. So shipping W is a genuine foundational step.

## 1. Encoding in the kernel (mirrors Sum/Case)

Tags `TC_W=32` (A=label-type, B=arity-family), `TC_SUP=33` (A=label, B=children-fn),
`TC_WREC=34` (A=motive, B=step, C=scrutinee — 3 fields, like `J`). All additive
(every existing arm untouched; `TC_C`/`TC_D` default 0).

`infer`:
- `W(A,B)`: `i = sortlevel(infer A)`; `infer B` whnf to `Π(A, U_j)`, `j = sortlevel(cod)`;
  result `U_max(i,j)`. (Full level generality — no same-level concession.)
- `sup(a,f)`: check-only against a `W(A,B)`: `check(a, A)`, `check(f, B(a)→W(A,B))`.
- `wrec(P,s,w)`: `w : W(A,B)`; `P : W(A,B)→U_k` (apply-the-motive for the result
  `P w`); build the step type `Π(a:A).Π(f:B(a)→W).(Π(b:B(a)).P(f b))→P(sup(a,f))`
  with the de-Bruijn shifts (`shift_k`, as natrec/case do), `check(s, steptype)`;
  result `P w`.

## 2. CCL (the higher-order ι-rule — the crux)

- `W` → atom `2068`, `W(A,B) = App(App(atom2068, Â), B̂)` (`B̂` a `Cur`).
- `sup`/`wrec` → CCL data constructor/eliminator tags (`CCL_SUP`, `CCL_WREC`).
- ι-rule in `ccl_elim_redex`: `WREC · P · s · (sup-spine a f)` with a SUP scrutinee →
  `s · a · f · IH`, where the induction hypothesis
  `IH = Cur( WREC · (P∘Fst) · (s∘Fst) · ((f∘Fst)·Snd) )` — `∘Fst` weakens P,s,f past
  the new binder `b=Snd`; applying IH to a child `b` β-reduces to `wrec(P,s,f b)`
  (the `∘Fst`s cancel the substitution). This is the only ι-rule whose contractum
  builds a `Cur` (the higher-order IH); the CCL machinery already handles
  `Cur`+`∘Fst`+β, so it composes — but it is verified by the β-KAT, not assumed.
- read-back `ccl_to_tc`: atom 2068 → `tc_w`; `SUP`-spine → `tc_sup`; `WREC`-spine
  (3 args incl. motive) → `tc_wrec`.

## 3. Staged plan (each gated; positive + negative)

- **Stage 1**: `TC_W` + `TC_SUP` — formation + constructor + their infer/check +
  CCL atoms + read-back. KAT: W-formation in `U_max`, `sup` checked against a `W`,
  + negatives (sup against non-W; arity mismatch). *(No computation yet — inert
  trees, like Bool-before-`if`.)*
- **Stage 2**: `TC_WREC` + the step type + the higher-order CCL ι-rule + β. KAT:
  `wrec`-β on a concrete tree (e.g. the `Nat`-as-W encoding: `wrec` computing a
  Nat's depth), the under-binder shift exerciser, + negatives (wrong step type,
  non-W scrutinee). The β-KAT is the proof the higher-order IH reduces correctly.
- **Stage 3 (QTT coherence)**: `tc_var_usage`/`tc_qtt_ok` cases for W/sup/wrec
  (motive erased; children-fn + step runtime; the IH-binder), so W-types integrate
  with the quantitative layer.

## 4. Ceiling

W-types are the general *well-founded* (inductive) type; their dual, M-types
(coinductive / non-well-founded trees), are a separate later arc. Strong
normalisation of `wrec` rests on the same MLTT-SN metatheorem as the other
eliminators (the reducer is applied only to well-typed terms).
