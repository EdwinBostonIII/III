# P5 — The Type-Theoretic Spine: minimal-core design (first brick)

*Companion to DOCS/III-RIPPLE-FORCEFIELD-PLAN.md §3 P5. This is the actionable
spec for the FIRST brick only: a tiny total dependent type-checker for λΠ with a
predicative universe ladder. Subsequent bricks grow the ladder (Σ, identity,
graded/QTT, modalities). The discipline is the de Bruijn criterion: a SMALL
trusted kernel that CHECKS, never searches — search/automation is P3's job
(egraph), discharged into checkable certificates the kernel re-verifies.*

## 0. Why this shape

The trusted core of every proof assistant (the "de Bruijn criterion") is a
checker small enough to audit by eye. We build the smallest core that is already
a genuine dependent type theory: dependent function types (Π), λ-abstraction,
application, and a **universe ladder** `U0 : U1 : U2 : …`. That ladder is
load-bearing: a system with `U : U` is inconsistent (Girard's paradox), so the
single most important NEGATIVE the KAT must witness is that the kernel **rejects
`U0 : U0`**. (This is the type-theory analogue of the math-olympiad skill's
"does it prove RH?" red flag — if our checker accepts `Type : Type`, it proves
`False`, and the whole edifice is a yes-man.)

## 1. Term representation — flat module-global arena (no local arrays; iii trap)

A term is a node index into parallel module-global arrays (function-local arrays
indexed by a runtime var SEGFAULT — `[[feedback_iii_local_array_runtime_index]]`;
egraph/XII already use this arena style). One node:

```
TC_TAG  : [u8;  N]      /* node kind                            */
TC_A    : [u32; N]      /* child/sub-term index, or payload     */
TC_B    : [u32; N]      /* second child index                   */
```

Tags (the λΠ + universe fragment):

| tag        | meaning            | A field            | B field       |
|------------|--------------------|--------------------|---------------|
| `TC_VAR`   | de Bruijn index    | index `k` (payload)| —             |
| `TC_SORT`  | universe `Uℓ`      | level `ℓ` (payload)| —             |
| `TC_PI`    | `Π(A). B`          | dom type node `A`  | cod node `B`  |
| `TC_LAM`   | `λ(:A). t`         | dom type node `A`  | body node `t` |
| `TC_APP`   | `f a`              | fn node `f`        | arg node `a`  |

De Bruijn indices ⇒ no α-renaming; binders are nameless. In `TC_PI`/`TC_LAM`,
field `B`/`t` lives under ONE additional binder (the bound var is index 0 there).

Allocation: a bump cursor `TC_N : [u64;1]`; `tc_mk(tag,a,b) -> u32` writes a node,
returns its index. Bounded by `TC_CAP` (sentinel-guarded; overflow ⇒ error node).

## 2. Substitution & shifting (de Bruijn, the only subtle code)

Two primitives, both structural recursions over the arena. **Recursion is
confirmed supported and green**: the self-hosted iiis-2 parser is recursive-
descent (`iiip_parse_unary`/`iiip_parse_expr_prec` self-recurse;
`iiip_parse_primary`↔`iiip_parse_expr` mutually recurse). The `curry_howard`
"W15 no recursion" is a determinism *discipline*, not a compiler limit. So these
are written as natural recursive fns; depth = term depth (KAT terms are shallow).
A fuel counter on `whnf` turns any logic bug into a clean WRONG, never a hang:

- `tc_shift(t, d, c)` — add `d` to every free var with index `≥ c` (cutoff `c`
  rises by 1 under each binder). Needed when moving a term under binders.
- `tc_subst(t, j, s)` — replace free var `j` by term `s` (shifting `s` under the
  binders it crosses), decrementing higher free vars. β uses `tc_subst(body,0,arg)`.

β-reduction: `APP(LAM(_,t), a) ⇒ tc_shift(tc_subst(t, 0, tc_shift(a,1,0)), -1, 0)`
(standard; verified by the conversion KAT, not assumed).

## 3. Normalization & conversion (definitional equality)

`tc_whnf(t)` — weak-head normal form: repeatedly, if head is `APP(LAM…,…)`, β-step;
else stop. `tc_nf(t)` — full normal form (whnf, then recurse into children under
binders). Both are bump-allocating (produce fresh nodes; inputs immutable).

`tc_conv(x, y) -> u8` — definitional equality. **Minimal brick: β-normalize both,
compare structurally** (`tc_alpha_eq` on nf — which under de Bruijn is just
structural identity). η can fold in later (η-expand `LAM` vs neutral). The plan's
"conversion = XII" is the GROWTH path (drive βη as XII rewrite rules so confluence
is the existing XII theorem); the first brick uses direct NbE to stay auditable,
then we migrate the conversion oracle to XII and prove the two agree on a vector
set (a differential KAT, the same technique that de-risked P4.1 cpufeat).

Equality oracle option: `cad` digest of `tc_nf` (content-address of the normal
form) — fast equality, and it ties P5 to the same seal the whole system uses.
Brick 1 uses structural compare (no hash dependency in the trusted core);
`cad`-of-nf is an accelerator added once structural compare is the proven oracle.

## 4. Bidirectional typing — Γ ⊢ t ⇒ T  (infer) and Γ ⊢ t ⇐ T (check)

Context Γ = a module-global stack of TYPE node indices; `Γ[k]` (from the top) is
the type of var `k`, **shifted by k+1** when read (it was recorded under fewer
binders). `infer -> u32` returns a type node index, or the sentinel `TC_ERR` (0)
on failure — every caller checks for `TC_ERR` (no exceptions; explicit error
propagation, the iii idiom).

```
infer(Γ, VAR k)   = tc_shift(Γ[k], k+1, 0)              ; k in range else ERR
infer(Γ, SORT ℓ)  = SORT (ℓ+1)                          ; the anti-Girard ladder
infer(Γ, PI A B)  : i = sortLevelOf(infer(Γ,A))         ; A must be a type
                    j = sortLevelOf(infer(Γ,A::Γ, B))    ; B a type in extended ctx
                    = SORT max(i,j)                       ; predicative
infer(Γ, LAM A t) : require infer(Γ,A) is a SORT        ; A is a well-formed type
                    B = infer(A::Γ, t)                    ; body type under binder
                    = PI A B
infer(Γ, APP f a) : F = whnf(infer(Γ,f))                 ; must be a Π
                    require F == PI A B                   ; else ERR (not a function)
                    check(Γ, a, A)                        ; arg matches domain
                    = tc_subst(B, 0, a)                   ; dependent result
check(Γ, t, T)    : S = infer(Γ,t) ; require tc_conv(S, T) else ERR
```

`sortLevelOf(T)`: `whnf(T)` must be `SORT ℓ` ⇒ return ℓ; else ERR (a type was
expected but `t` did not have a universe as its type).

## 5. The KAT — accept positives, REJECT negatives (the load-bearing half)

`p5_kat() -> u64` (99 = all pass; else first-failing case id). Per
`[[feedback_no_autogen_stub_prove_negative]]` and `[[feedback_prove_positive_arms]]`,
EACH negative must fail for its OWN reason and each positive arm must be driven.

POSITIVES (must typecheck):
1. `U0 ⇒ U1`, `U1 ⇒ U2` (ladder).
2. `Π(A:U0). Π(_:A). A ⇒ U0` (a small type former is a type).
3. polymorphic identity `λ(A:U0). λ(x:A). x  ⇐  Π(A:U0). Π(_:A). A`.
4. application reduces the dependent codomain: `(λ(A:U0).λ(x:A).x) U0 ⇐ Π(_:U0).U0`,
   and the inferred type β-reduces to `Π(_:U0).U0` (drives §3 conversion).

NEGATIVES (must be REJECTED — `TC_ERR`), each a DISTINCT failure:
5. **`U0 : U0` rejected** — universe inconsistency (Girard). *The keystone negative.*
6. apply a non-function: `U0 U0` ⇒ ERR (head not a Π).
7. domain mismatch: `(λ(x:U0). x) (λ(y:U0).y)` — arg `λy.y : Π(_:U0)U0 ≠ U0` ⇒ ERR.
8. ill-scoped variable: `VAR 0` in the empty context ⇒ ERR (index out of range).
9. `λ(A:U0). A A` — `A : U0` applied to `A`; `whnf(U0)` is not a Π ⇒ ERR
   (a body that is ill-typed must sink the whole λ).

Positives 1–4 prove the checker is not vacuously rejecting; negatives 5–9 prove
it is not a yes-man. 5 is the one that would, if it ever flips, make the kernel
prove `False`.

## 6. Module / build wiring

- File: `STDLIB/iii/numera/typecheck.iii`, `module numera_typecheck`. (numera =
  the math core; sits beside `trit`, `curry_howard`, `egraph`.)
- NIH: trusted core depends on NOTHING but its own arena (no cad/keccak in brick
  1 — the smaller the trusted base, the better the de Bruijn criterion). Growth
  bricks may extern `cad`/`xii_*`.
- Add `numera/typecheck` to `build_stdlib.sh` MODULES; add corpus
  `841_typecheck_core` (EXPECTED 99) calling `p5_kat()`; gate = build FAIL=0 +
  corpus PASS≥baseline FAIL=0 + lib hash.

## 7. Scope honesty (what brick 1 is NOT)

No Σ, no identity types, no inductive families, no η in conversion, no
graded/QTT, no effects, no cumulativity (just `Uℓ : U(ℓ+1)`, no `Uℓ ≤ U(ℓ+1)`
subtyping). Predicative only. These are named growth bricks, each with its own
accept/reject KAT. Brick 1's claim is exactly: **a sound, total checker for λΠ +
a universe ladder, that rejects `Type : Type`.** Trust ceiling (per plan §3 P5):
self-consistency is unprovable (Gödel II); trust = the de Bruijn criterion + the
external metatheory KAT on the fragment.

## 8. Brick 2 — Σ types (dependent pairs) + type ascription

The canonical second connective, the dual of Π (the other half of BHK). Adds five
tags, extends the same six recursions, mirrors the Π machinery exactly.

| tag       | meaning        | A field     | B field      |
|-----------|----------------|-------------|--------------|
| `TC_SIG`  | `Σ(A).B`       | dom type    | cod (binder) |
| `TC_PAIR` | `⟨a, b⟩`       | first `a`   | second `b`   |
| `TC_FST`  | `fst p`        | pair `p`    | —            |
| `TC_SND`  | `snd p`        | pair `p`    | —            |
| `TC_ANN`  | `(t : T)`      | term `t`    | type `T`     |

`TC_ANN` (type ascription) is the standard bidirectional bridge: a bare pair is
**checkable, not inferable** (its B family is not recoverable from a,b), so to
project from a literal pair we ascribe it (`fst (⟨a,b⟩ : Σ…)`). `ANN` is
reduction-transparent: `whnf(ANN(t,T)) = whnf(t)`, and `nf` strips it — so
`alpha_eq`/`conv` never see `ANN` (no new alpha case needed).

- **shift/subst**: `SIG` like `PI` (B under one binder, `c+1`); `PAIR` like `APP`
  (both children at `c`); `FST`/`SND` one child at `c`; `ANN` both at `c`.
- **whnf**: `FST(p)` → whnf p; if `PAIR` take A else `FST(whnf p)`. `SND(p)`
  symmetric (take B). `ANN(t,_)` → whnf t. (Projection β + ascription strip.)
- **nf / alpha_eq**: `SIG`/`PAIR` are 2-child (like PI/APP); `FST`/`SND` are
  1-child (compare A only — never recurse on the unused B=0, the same ERR-safety
  rule as VAR/SORT).
- **infer**: `SIG(A,B)` = `U_max(i,j)` (exactly the PI rule). `FST(p)`:
  whnf(infer p) must be `SIG(A,B)` ⇒ `A`. `SND(p)`: ⇒ `subst(B, 0, FST(p))`
  (the dependent projection). `ANN(t,T)`: require `infer(T)` is a sort and
  `check(t,T)` ⇒ `T`. `PAIR` alone ⇒ ERR (not inferable).
- **check**: `PAIR ⟨a,b⟩` against expected `Σ(A,B)`: `check(a,A) && check(b, subst(B,0,a))`.

KAT `842_typecheck_sigma` (accept positives, reject negatives, each distinct):
- P: `Σ(A:U0).A : U1`. P: `⟨U1,U0⟩` checks against `Σ(A:U2).A` (a real dependent
  pair: the 2nd component `U0:U1` and `U1` is the 1st, so `A[0:=U1]=U1`). P (β):
  `fst(⟨U1,U0⟩:Σ(A:U2).A)` ≡ `U1`, `snd(…)` ≡ `U0`. P: `infer(snd …) : U1`.
- N: `⟨U1,U0⟩` against `Σ(A:U2).U2` rejected (2nd needs `U0:U2`, but `U0:U1`).
- N: `fst U0` rejected (`U0:U1`, whnf not `SIG`). N: `(U0 : U0)` ascription
  rejected (the keystone again, now through `ANN`).

Same gate shape; append `numera/typecheck` is already built so only the corpus
entry is new. (Brick 1 stays frozen; brick 2 only ADDS tags and match-arms.)

## 9. Brick 3 — Bool, then Brick 4 — identity types

**Brick 3 (Bool)** is the first base inductive and the prerequisite for testing
identity: the universe-only fragment has no closed inhabitants of small types, so
`transport`/`refl` examples have no witnesses until `true : Bool : U0` exists.
Tags `BOOL`/`TRUE`/`FALSE`/`IF` (the `if` needs the new `TC_C` 3rd field). `infer`:
`BOOL⇒U0`, `TRUE`/`FALSE⇒Bool`, `IF(s,t,e)` = check `s:Bool`, `infer t = T`, check
`e:T`, ⇒ `T` (non-dependent). `whnf`: `if(true,t,e)→t`, `if(false,t,e)→e`.

**Brick 4 (identity types: Id + refl + transport).** The soul of the system —
where equalities become statable and usable. Tags (all on the 3-field node):
`ID{A=type, B=lhs, C=rhs}` = `Id(A,a,b)`; `REFL{A=value}` = `refl a`;
`TRANSP{A=P, B=proof, C=base}` = transport (the minimal useful eliminator — full
`J` is a later brick).

- `infer(ID(A,a,b))`: `A:U_k`, check `a:A`, check `b:A` ⇒ `U_k`.
- `infer(REFL a)`: `A = infer a` ⇒ `ID(A, a, a)`.
- `infer(TRANSP(P,p,base))`: `whnf(infer p) = ID(A,a,b)`; `whnf(infer P) = Π(dom).cod`
  with `conv(dom,A)` and `cod` a sort under the binder (P : A→U_k); check
  `base : (P a)` (= `APP(P,a)`); ⇒ `(P b)` (= `APP(P,b)`).
- `whnf`: `TRANSP(P, refl, base) → base` (transport along reflexivity is identity).
- `shift`/`subst`/`nf`/`alpha_eq`: `ID`/`TRANSP` are 3-child (none binding);
  `REFL` is 1-child. (`alpha_eq` for `ID`/`TRANSP` compares all three.)

KAT `844_typecheck_id` on Bool data: `refl true : Id(Bool,true,true)`;
`Id(Bool,true,false) : U0` (formation, a possibly-empty type); `transport(λ_:Bool.Bool,
refl true, true) ≡ true` (β); negatives — `refl true : Id(Bool,true,false)` REJECTED
(refl only proves `a=a`); transport with `base : (P a)` of the wrong type REJECTED.
Then η, cumulativity, graded/QTT, and migrating `conv` to the XII oracle (with a
differential KAT that XII-conv agrees with NbE-conv) remain.

## 10. Brick 5 — Nat + iteration recursor (computation)

Bool gave data; Id gave equality; **Nat gives recursion** — the kernel's first
unbounded computation, so it can typecheck arithmetic. Tags: `NAT` (type),
`ZERO`, `SUCC{A=pred}`, `ITER{A=base z, B=step s, C=scrutinee n}` (the iteration
recursor — `iter z s n = sⁿ(z)`; the full dependent recursor `natrec` needs a
4th field/motive and is a later brick).

- `infer`: `NAT⇒U0`; `ZERO⇒Nat`; `SUCC n` = check `n:Nat` ⇒ `Nat`;
  `ITER(z,s,n)` = `infer z = T`, check `s : Π(_:T).T` (= `PI(T, shift(T,1,0))`),
  check `n : Nat` ⇒ `T`. (Non-dependent iteration; `s` is `T→T`.)
- `whnf`: `iter(z,s,zero) → z`; `iter(z,s,succ m) → APP(s, iter(z,s,m))` (then
  continue — call-by-name; terminates for Nat literals, fuel-guarded).
- `shift`/`subst`/`nf`/`alpha_eq`: `NAT`/`ZERO` leaves, `SUCC` 1-child, `ITER`
  3-child (none binding).

KAT `845_typecheck_nat`: `Nat:U0`, `zero:Nat`, `succ zero : Nat`;
`iter(true, λ_:Bool.false, zero) ≡ true` (base case) and
`iter(true, λ_:Bool.false, succ zero) ≡ false` (step fires once); negatives —
`succ true` REJECTED (arg not Nat), `iter(true, s, true)` REJECTED (scrutinee not
Nat), `iter` with `z:Bool` but `s:Nat→Nat` REJECTED (z/s type mismatch). All flat
dispatch (parser-nesting discipline). Then full `natrec` (dependent motive), `J`,
η, cumulativity.

## 12. Bricks 7 & 8 — the DEPENDENT eliminators (natrec + J): meticulous design

`iter` and `transport` are the NON-dependent eliminators. Their dependent
versions — `natrec` (induction over Nat) and `J` (path induction over Id) — are
what let the kernel PROVE `∀n. P n` and reason from equalities. They are the
hardest pieces, so this section derives the typing rules with the de Bruijn
indices explicit, then ADVERSARIALLY attacks the design (the gaps a closed KAT
would hide).

### 12.1 Encoding — `natrec` needs a 4th field; `J` fits in three

- **`natrec(P, z, s, n)`** — motive `P`, base `z`, step `s`, scrutinee `n`. None
  is recoverable from the others (`n` is the data; `P,z,s` the method bundle), so
  **4 explicit args ⇒ add `TC_D : [u32;16384]` + `tc_mk4`.** Additive (every
  existing node sets `D=0`); `shift`/`subst`/`nf`/`alpha_eq`/`strengthen` each
  gain a `NATREC` 4-child arm; `whnf`/`infer` gain the rule. Tag
  `TC_NATREC{A=P, B=z, C=s, D=n}`.
- **`J(C, d, p)`** (based path induction, Paulin) — motive `C`, base `d`, proof
  `p`. The endpoints `A,a,b` are **recovered from `infer(p) = Id(A,a,b)`**, so `J`
  needs only **3 explicit args ⇒ fits `TC_J{A=C, B=d, C=p}`** (D unused).

### 12.2 `natrec` typing — the shift is UNAVOIDABLE

In context Γ (where `P,z,s,n` live):
```
P : Π(_:Nat). U_ℓ                      -- motive: a Nat-indexed type family
z : P zero            = APP(P, zero)   -- (Γ-level; no shift)
s : Π(k:Nat). Π(_: P k). P (succ k)    -- step; THIS needs the shift:
      = PI(Nat, PI( APP(shift(P,1,0), #0),        -- "P k" under [k]:    P↑1, k=#0
                    APP(shift(P,2,0), SUCC(#1)) )) -- "P(succ k)" under [k,ih]: P↑2, k=#1
n : Nat
natrec(P,z,s,n) : P n = APP(P, n)      -- result (Γ-level; no shift)
```
`s` is a *function being checked*, and its type mentions `P` under one then two
binders ⇒ `P` must be shifted `+1`/`+2`. There is NO apply-the-motive shortcut
(unlike `J`): you cannot avoid constructing `s`'s Π-type.

β-rules (NO de Bruijn subtlety — every sub-term is Γ-level):
```
natrec(P,z,s, zero)    → z
natrec(P,z,s, succ m)  → APP(APP(s, m), natrec(P,z,s,m))   -- s m (rec m)
```
Subject reduction: `s m : P m → P(succ m)`, `rec m : P m`, so `s m (rec m) :
P(succ m)` = the result type at `succ m`. ✓ Sound.

### 12.3 `J` typing — APPLY the motive (no manual shift)

```
p : Id(A, a, b)                         -- whnf(infer p); extract a, b
da  = APP(APP(C, a), refl a)            -- the diagonal type  C a (refl a)
rty = APP(APP(C, b), p)                 -- the result type    C b p
require infer(da) is a sort             -- C is a motive at the diagonal
check d : da                            -- base lives at the diagonal (load-bearing!)
require infer(rty) is a sort            -- C b p is a type
J(C,d,p) : rty
```
Because `C` is *applied* to Γ-level terms (`a`/`b`/`refl a`/`p`), all four
sub-terms are at the Γ level — **no manual shift**; the existing `APP`/`infer`
(with its `cod[0:=arg]`) handles the dependency. β-rule:
```
J(C, d, p)  with whnf(p) = REFL → d
```
Subject reduction: when `p = refl a`, `b = a`, so `rty = C a (refl a) = da`, and
`d : da`. ✓ Sound. The base is forced to the DIAGONAL `(a, refl a)` — that single
constraint is the entire content of path induction; if the impl checked `d`
against `C b p` instead, `J` would be vacuous/unsound.

### 12.4 ADVERSARIAL — what a closed KAT silently HIDES (the load-bearing part)

Two independent ways a naive test passes a BROKEN eliminator:

1. **Closed context ⇒ the shift is a no-op.** In Γ = ∅, `P`/`A`/`a` are CLOSED,
   so `shift(P,k,0) = P`. A natrec impl that FORGOT to shift `P` (or shifted by
   the wrong amount) typechecks every closed example identically. The bug is
   invisible until natrec is typed UNDER A BINDER where `P` references it.

2. **Constant motive ⇒ the dependency collapses.** With `P = λ_.T` (or `C =
   λy.λ_.T`), `P zero = P(succ m) = T` and `C a (refl a) = C b p = T`: the
   diagonal-vs-general distinction VANISHES. A `J` impl that checked `d` against
   `C b p` instead of the diagonal passes every constant-motive test. Worse, in
   Γ=∅ the only inhabited `(b, p)` for `Id(A,a,b)` is `(a, refl)` — so the
   motive is only ever evaluated at the diagonal, and the dependency is
   structurally untestable with closed proofs.

**Therefore the KATs MUST type the eliminator under binders** (the only place
hypothetical `k`/`y`/`p` and non-closed `P`/`C` exist):
- **natrec (shift exerciser, POSITIVE):** typecheck
  `λ(P:Nat→U0). λ(z:P zero). λ(s:Π(k:Nat).P k→P(succ k)). λ(n:Nat). natrec(P,z,s,n)`.
  This forces `conv(declared type of s, built s-type)` — which only holds if
  `shift(P,1,0)`/`shift(P,2,0)` are exactly right. A shift bug ⇒ mismatch ⇒
  REJECT (caught). Plus closed β: `natrec(λ_.Bool, true, λk.λ_.false, succ zero)`
  reduces, `natrec(λ_.Nat, zero, λk.λih.succ ih, succ²zero) ≡ 2`.
- **J (diagonal exerciser, POSITIVE):** typecheck
  `λ(A:U0).λ(a:A).λ(C:Π(y:A).Id(A,a,y)→U0).λ(d:C a (refl a)).λ(b:A).λ(p:Id(A,a,b)). J(C,d,p)`.
  Plus closed β: `J(λy.λ_.Bool, true, refl true) ≡ true`.
- **Negatives:** natrec with `s` of the wrong type / `P` not `Nat→U` REJECTED;
  `J` with `d` NOT at the diagonal (`d : C b p`-shaped but not `C a (refl a)`)
  REJECTED; `J` proof not an `Id` REJECTED.

### 12.5 Build discipline & risk

Flat dispatch throughout (parser nesting ≤ 3 — `whnf` β uses the `took`-flag
pattern). Implement as TWO bricks: **brick 7 = natrec (+ `TC_D`/`tc_mk4`)**,
**brick 8 = J**, each its own corpus KAT (`847`, `848`), verify-then-extend.
Confidence: the typing rules + β are derived and subject-reduction-checked; the
ONE residual implementation risk is the natrec `shift` amounts — which §12.4's
under-binder positive is specifically constructed to catch. (If that KAT can't be
made to pass, the shift is wrong — do not ship a green-by-vacuity closed-only KAT.)

## 13. Brick 9 — ⊥ (Empty) + ⊤ (Unit): the trivial connectives

Clean, additive (no frozen-brick changes), and ⊥ is genuinely useful: negation
`¬A := A→⊥`, proof by contradiction, `absurd`. Tags `TC_UNIT`, `TC_TT`
(`tt:Unit`), `TC_EMPTY`, `TC_ABSURD{A=motive C, B=proof e}`.

- `infer`: `Unit:U0`; `tt:Unit`; `Empty:U0`; `absurd(C,e)`: require `infer(e)`
  whnf = `Empty`; `rty = APP(C,e)`; require `infer(rty)` is a sort; ⇒ `rty`.
  (Apply-the-motive like J — `C` and `e` are Γ-level, NO shift. The `APP(C,e)`
  implicitly forces `C:Empty→U`; the explicit `e:Empty` check localizes the error.)
- `whnf`: `Unit`/`tt`/`Empty` are leaves; `absurd` is ALWAYS neutral (Empty is
  uninhabited ⇒ `e` never reduces to a constructor ⇒ no β rule). So `absurd` is
  the rare eliminator with no β — its only content is the typing rule.
- `shift`/`subst`/`nf`/`alpha_eq`/`strengthen`: `Unit`/`tt`/`Empty` leaves;
  `absurd` 2-child (non-binding).

KAT `849_typecheck_bot`: `Unit:U0`, `tt:Unit`, `Empty:U0` (formation +
constructor); the under-binder absurd positive `λ(C:Empty→U0).λ(e:Empty).
absurd(C,e)` typechecks (closed has no `Empty` witness, so under-binder is the
only place to test it); negatives — `absurd(C, true)` REJECTED (proof not Empty),
`absurd` with `C:Bool→U` REJECTED (motive domain ≠ Empty). Then Sum (∨, with the
`ANN`-bridge for `inl`/`inr`), cumulativity, conversion-via-XII.

## 14. Brick 10 — cumulative universes (`U_i : U_j` for `i ≤ j`)

A SEMANTIC refinement, not a new type former: make `check` use SUBTYPING
(subsumption) instead of definitional equality, with `U_i ≤ U_j` when `i ≤ j`.
Shallow (sort-level only — no deep Π/Σ covariance), which is sound (a subset of
full cumulativity) and the standard ergonomic win.

```
fn tc_subtype(s, t):                 -- "s is a subtype of t"
    ns = nf(s) ; nt = nf(t)
    if ns is SORT and nt is SORT:    -- universe cumulativity
        if level(ns) > level(nt): return 0      -- (use '>' not '<=' for iii safety)
        return 1
    return alpha_eq(ns, nt)          -- otherwise: definitional equality
```
`check(t, T)` ends with `tc_subtype(infer t, T)` instead of `tc_conv`. `tc_conv`
itself is UNCHANGED (still pure equality, used wherever equality — not subtyping —
is meant). Subsumption then propagates through every `check` (APP args, eliminator
methods, the PAIR/`ANN` rules…) automatically.

**Soundness / non-regression (checked):** `subtype ⊇ conv`, so every POSITIVE
still passes. A negative `check(t,T)` with `infer t = U_i`, `T = U_j` survives iff
it is NOT the case that `i ≤ j`. All existing universe negatives are "higher :
lower" (`U0:U0` → `1≤0` false; `U1:U1` → `2≤1` false; …) ⇒ still REJECTED. The SOLE
casualty is brick 2's `842` N5 (`⟨U1,U0⟩ : Σ(_:U2).U2`, which needed `U0:U2`):
under cumulativity that is now (correctly) ACCEPTED, so the test is adapted to a
still-failing negative — e.g. `⟨U1, true⟩ : Σ(_:U2).U2` (1st `U1:U2` holds; 2nd
`true:U2` fails, `true` is not a type). Non-universe negatives (Bool≠Nat, refl≠,
proof-not-Id, …) are untouched.

KAT `850_typecheck_cumul`: POSITIVES `U0:U2`, `U1:U3` (the new subsumption);
NEGATIVES `U2:U1`, `U1:U0` (downward REJECTED), `true:U0` (non-type REJECTED, not
a sort-level relation). Plus the adapted `842` N5 and all of `841`–`849` re-green.
Then Sum (∨), conversion-via-XII.

## 15. Brick 11 — Sum types `A+B` (∨) with the dependent case eliminator

The remaining connective (disjunction). The most substantial brick: it fuses
natrec's shift, J's apply-the-motive, `TC_D`, and pairs' ANN-bridge.

**Tags:** `SUM{A=left, B=right}` (the type `A+B`); `INL{A=value}`, `INR{A=value}`
(check-only against a `SUM`, like `PAIR` vs `Σ`); `CASE{A=C, B=f, C=g, D=s}` (uses
`TC_D`).

**Formation** `infer(SUM(A,B))`: `A:U_i`, `B:U_j` ⇒ `U_max(i,j)` (non-dependent,
no push — unlike Σ).

**Constructors** (check-only, ANN-bridge for inference):
`check(INL(v), T)`: `whnf(T)=SUM(A,B)`; `check(v,A)`. `INR` symmetric with `B`.
`infer(INL/INR)=ERR` (use `ANN(inl v, A+B)` where a scrutinee must be inferred).

**Eliminator** `infer(CASE(C,f,g,s))` — the hybrid:
```
ts = whnf(infer s); require SUM(A,B)
rty = APP(C, s); require infer(rty) is a sort        -- C is a motive; result C s (apply-the-motive, NO shift)
C1  = shift(C, 1, 0)
check f : PI(A, APP(C1, INL(#0)))                    -- f : (a:A) -> C(inl a)   (shift, like natrec)
check g : PI(B, APP(C1, INR(#0)))                    -- g : (b:B) -> C(inr b)
⇒ rty
```
β: `case(C,f,g,s)` with `whnf(s)=INL(v) → APP(f,v)`; `INR(v) → APP(g,v)` (a
concrete `s=ANN(inl v,·)` whnf-strips ANN to `INL(v)`).

**shift/subst/nf/alpha_eq/strengthen:** `SUM` 2-child (non-binding), `INL`/`INR`
1-child, `CASE` 4-child. (`INL`/`INR` never reduce ⇒ no whnf entry for them; only
`CASE` gets a whnf β.)

**KAT `851_typecheck_sum`** (§12.4 discipline):
- closed β: `case(λ_.Bool, λa.a, λ_.false, (inl true : Bool+Bool)) ≡ true` (and
  `: Bool`); the `inr` branch likewise.
- **under-binder shift exerciser** (`A=B=Bool` concrete, `C/f/g/s` abstract):
  `λ(C:(Bool+Bool)→U0).λ(f:Π(a:Bool).C(inl a)).λ(g:Π(b:Bool).C(inr b)).λ(s:Bool+Bool). case(C,f,g,s)`
  typechecks IFF `shift(C,1,0)` is exact — traced: `infer(f)=PI(Bool,APP(var4,INL #0))`
  equals the built `PI(Bool,APP(shift(var3,1)=var4, INL #0))`.
- negatives: `inl v` checked against a non-`SUM` REJECTED; `case` scrutinee not a
  `SUM` REJECTED; `f` of the wrong type REJECTED.

Risk: the method-type construction (`APP(C1, INL(#0))`) is the novel part; the
under-binder positive is built to catch a wrong shift. Confidence high (shift is
the proven natrec pattern; apply-the-motive the proven J pattern).

## 16. Brick 12 — the metatheory KAT (canonicity + subject reduction)

The P5 plan's completion gate: "witnesses canonicity / subject-reduction on the
fragment." After 11 feature bricks, this CERTIFIES the kernel — no new kernel
code, just `p5_kat_meta()` composing `infer`/`nf`/`conv`/constructors, but it
verifies the two properties trust rests on.

**Canonicity** (computational adequacy): every CLOSED `t : Bool` has `nf(t)` a
CONSTRUCTOR (`true`/`false`), not a stuck neutral. Tested across EVERY eliminator
so a non-reducing one is caught:
- `if(true,true,false) ↝ true`; `iter(true,λ_.false, succ zero) ↝ false`;
  `natrec(λ_.Bool, true, λk.λ_.false, succ²zero) ↝ false`;
  `case(λ_.Bool, λa.a, λ_.false, inl true) ↝ true`;
  `J(λy.λ_.Bool, true, refl true) ↝ true`; nested `if(if(…),false,true) ↝ false`.
- Assertion: `TC_TAG[nf(t)] == TC_TRUE or TC_FALSE` (a constructor) AND `t : Bool`.
  A stuck/wrong nf ⇒ tag is `CASE`/`ITER`/… ⇒ FAIL.

**Subject reduction** (type safety): `infer(t) = T`, `infer(nf(t)) = T'`,
`conv(T,T') = 1` — β preserves types. Tested on `(λA.λx.x) U0` (β to `λx.x`,
type `Π(_:U0).U0` preserved) and the `case` redex.

KAT `852_typecheck_meta`. This is the de-Bruijn-criterion capstone: the kernel
is not just "passes spot checks" but "the closed-Bool fragment is canonical and
reduction-stable." (Full subject-reduction/canonicity proofs are external +
unbounded; this witnesses them on the corpus fragment — the honest claim.)

## 17. Brick 13 — W-types (the general well-founded inductive, HIGHER-ORDER)

`W(A,B)` = well-founded trees: node labels `A:U_i`, branching `B:A→U_j` (a node
labelled `a` has `B(a)`-many children). Subsumes Nat/Bool/Sum. The HARD one: the
constructor takes a FUNCTION, and the recursor's step takes a higher-order IH.

**Encoding (all ≤3 fields — no `TC_D`):** `W{A=A, B=B}`; `SUP{A=a, B=f}` where
`f : B(a)→W` is a function term; `WREC{A=C, B=h, C=w}`.

**Formation** `infer(W(A,B))`: `A:U_i`; `infer(B)` whnf `= PI(A',U_j)`,
`conv(A',A)`; ⇒ `U_max(i,j)`.

**Constructor** (check-only against `W`, ANN-bridge):
`check(SUP(a,f), T)`: `whnf(T)=W(A,B)`; `check(a,A)`; `check(f, PI(APP(B,a), shift(W(A,B),1,0)))`
(i.e. `f : B(a) → W`, non-dependent arrow).

**Eliminator** `infer(WREC(C,h,w))`:
```
whnf(infer w) = W(A,B)
rty = APP(C, w) ; require sort                      -- C : W→U, result C w (apply-the-motive)
check h : H_TYPE                                    -- the step (below) — the intricate part
⇒ rty
```
**The step type `H_TYPE`** (`h : (a:A)→(f:B(a)→W)→((b:B(a))→C(f b))→C(sup a f)`),
derived with de Bruijn EXPLICIT (`^k` = `shift(·,k,0)`; layers = binder depth from Γ):
```
H_TYPE =
 PI(A,                                              -- a:A           [Γ→layer1]
   PI( PI(APP(B^1,#0), W^2),                        -- f : B a → W   [layer1; W under the arrow-arg ⇒ ^2]
     PI( PI(APP(B^2,#1), APP(C^3, APP(#1,#0))),      -- ih: (b:B a)→C(f b)  [layer2; b internal⇒layer3: f=#1,b=#0,C^3]
       APP(C^3, SUP(#2,#1)) )))                      -- C(sup a f)    [layer3: a=#2, f=#1]
```
**β:** `wrec(C,h, sup a f) → h a f (λ(b:B a). wrec(C,h, f b))`, i.e.
`APP(APP(APP(h,a),f), LAM(APP(B,a), WREC(C^1, h^1, APP(f^1,#0))))` — the IH is a
λ wrapping a RECURSIVE wrec under the `b`-binder (`C,h,f` shifted `^1`, `b=#0`,
`f b = APP(f^1,#0)`). whnf must build this; termination is by the tree's
well-foundedness (each `f b` is structurally smaller), fuel-guarded.

**`shift`/`subst`/`nf`/`alpha_eq`/`strengthen`:** `W` 2-child (non-binding),
`SUP` 2-child, `WREC` 3-child. `whnf`: `WREC β` (when `whnf(w)=SUP`); `SUP`/`W`
neutral.

**ADVERSARIAL (the load-bearing gaps):**
1. The step type has FOUR distinct shifts (`B^1, W^2, B^2, C^3`) — far more than
   natrec's two. A closed motive makes ALL of them no-ops, so the under-binder
   KAT is mandatory AND the most elaborate yet:
   `λ(A:U0).λ(B:A→U0).λ(C:W(A,B)→U0).λ(h:H_TYPE).λ(w:W(A,B)). wrec(C,h,w)` — but
   `H_TYPE` itself must be written with the same de Bruijn, so the test is its own
   hardest derivation. **Mitigation:** fix `A=Bool, B=λ_.Unit` (then `W≅Nat`,
   `B a = Unit` always) to tame the indices, abstract only `C,h,w` (3 binders) —
   the shifts `C^3`/etc. still fire because `C` is a variable.
2. The β IHfn `λb. wrec(C^1,h^1, f^1 #0)` — a recursive call under a fresh binder.
   A wrong `^1` shift mis-references `C`/`h`/`f`. Tested by a CLOSED wrec that
   actually recurses (a 2-level tree), forcing the IHfn to fire and the result
   to depend on the subtree recursion.
3. Closed witnesses need real `sup`-trees: with `B=λ_.Empty`, `sup(a, λe.absurd…)`
   is a LEAF (Empty domain ⇒ vacuous `f`); with `B=λ_.Unit`, `sup(a, λ_.leaf)` is
   a 1-child node — these build finite trees to test β + canonicity.

**Risk: HIGH** — the step-type de Bruijn (4 shifts) and the β IHfn are the most
error-prone code in the kernel; the under-binder KAT + a recursing closed wrec
are built to catch a wrong shift. Verify-or-abstain: if the under-binder positive
can't be made to pass, the shift is wrong — do not ship.

## 18. Brick 14 — conversion via the XII rewrite engine

**The real XII API** (grounded, not guessed): `xii_term` is a 3-child node arena
(`xii_term_get_child_a/b/c(idx)->u32`); `xii_rewrite` offers `apply_one(t)->u32`
(ONE rewrite step, mutates in place + returns the ref — use
`xii_rewrite_last_rule_fired()` to detect firing, NOT `next==cur`),
`apply_specific(rule,t)`, `struct_eq(a,b)->u8`, `tables_reset()`; `xii_canonicalise`
drives normalization (apply_one to fixpoint). Confluence machinery exists:
`xii_critpair_enum`, `xii_conf_cert`, `xii_joinability`.

**The fundamental tension (the honest core of this design).** XII is a
FIRST-ORDER term rewriter; type-theory conversion is HIGHER-ORDER:
- **Arity:** `TC` nodes are 4-child (`natrec`/`case`); XII is 3-child ⇒ the 4th
  arg must be curried (`NATREC(P,z,s,n)` ≈ `app(natrec3(P,z,s), n)`) or wrapped.
- **Substitution (the deep wall):** β `(λx.t) a → t[x:=a]` and the ι-rules whose
  RHS substitutes (`natrec(succ m) → s m (rec m)`) are higher-order; first-order
  XII pattern rules cannot express them. Only the ι-*selection* rules with no
  substitution (`if(true,t,e)→t`, `fst⟨a,b⟩→a`, `case(inl v,f,g)→f v`*) are
  first-order. (*`f v` is an application, still first-order if `v` is a child —
  but `β` of that application is not.)

### Path A — full `conversion = XII` via a λσ explicit-substitution calculus
Encode terms AND delayed substitutions as first-order XII terms (Abadi–Cardelli–
Curien–Lévy λσ): β becomes `(λa)[s] → a[· / s]`-style first-order rules, and
substitution-propagation (`(t u)[s] → (t[s])(u[s])`, `#0[a·s]→a`, …) are
first-order rewrite rules. Then conversion = XII-normalize both + `struct_eq`.
**PRO:** conversion inherits XII's MACHINE-CHECKED confluence (run `critpair_enum`
+ `conf_cert` on the λσ ∪ ι rule set) — the strongest possible trust. **CON:**
λσ is a substantial calculus (~15 rules), and its termination/confluence in XII
must itself be certified; this is a research-grade brick, NOT a quick swap.
**Risk: HIGH.**

### Path B — hybrid (the tractable, recommended first step)
Keep the kernel's NbE (β/subst/`nf`, already proven green) as the reducer. Use
XII for what it does WELL + first-order:
1. **Equality oracle:** translate the kernel's NbE normal forms → XII terms, use
   `xii_rewrite_struct_eq` for the final equality instead of `tc_alpha_eq`.
2. **ι-fragment confluence cert:** register the first-order selection rules
   (`if`/`fst`/`snd`/`case`-on-constructor) in XII; `critpair_enum`+`conf_cert`
   PROVE that fragment confluent — so the kernel's reduction is canonical there
   by an external machine-checked proof.
**Risk: MED.** Connects to XII's verified machinery without the λσ research lift.

### The bridge (required for either path): the differential KAT `853_xii_conv`
`xii_conv(x,y) == nbe_conv(x,y)` (≡ `tc_conv`) on the WHOLE term corpus of
`841`–`852` (every positive/negative pair already built). If the XII oracle and
NbE agree on every vector, the migration is sound — and any divergence localizes
the bug to one term. This is the plan's "differential KAT that XII-conv agrees
with NbE-conv"; it is the gate for trusting ANY XII conversion path.

**Recommendation:** Path B (struct_eq oracle + ι-confluence cert + the
differential KAT) is the honest, tractable integration that genuinely "uses XII"
and raises trust (machine-checked confluence of the first-order fragment). Path A
(full λσ) is the acknowledged research frontier — designed here, but not claimed
as a single green brick. (Math-olympiad discipline: a theorem whose special case
is a famous open problem has a gap; a "brick" that hides a research calculus is
the same red flag — name it, don't pretend.)

## 19. Path C — eradicate bound variables (combinators); XII the SINGULAR oracle

The NO-COMPROMISE resolution (operator decision). Path A (λσ) fails the
termination gate — Melliès proved λσ does NOT preserve strong normalization. Path
B keeps two oracles (NbE + XII), violating H4 "One Engine". **Path C eliminates
substitution from the universe** so XII's first-order engine is universally
sufficient: no binders ⇒ no substitution ⇒ everything is first-order structural
rewrite ⇒ XII is the absolute singular oracle, and `critpair_enum`+`conf_cert`
certify confluence of the WHOLE type theory (not just the ι-fragment).

### Three architecture pillars (operator blueprint) + the math-olympiad refinements
1. **Arity → strict currying.** No 4-child node in XII. `natrec(P,z,s,n)` compiles
   to `APP(APP(APP(APP(NATREC,P),z),s),n)`; every node is binary `APP`. Honors the
   flat 3-field arena; no structural exception.
2. **Substitution → combinators.** Compile the MLTT λ-frontend to a CLOSED set of
   first-order combinators via bracket abstraction (`λ*`). No variables, no
   scopes, no substitution: `(λx. x+x) 3` ↝ `S add I 3 → add 3 (I 3) → add 3 3`
   — pure structural routing.
   - **REFINEMENT R1 (βη-faithfulness):** raw SKI *weak* reduction is β-only; the
     kernel has η (brick 6). Use **Curien's Categorical Combinatory Logic (CCL)** —
     a *confluent, first-order* system that captures λ-**βη** and is the internal
     language of a (locally) cartesian-closed category (the LCCC ⇒ dependent
     types). Equivalent fallback: SKI + Curry's `A_βη` extensionality axioms. SKI
     β alone would silently DROP η — itself a compromise; CCL keeps it.
   - **REFINEMENT R2 (untyped suffices ⇒ de-risk):** conversion is type-erased
     normalization, and the FRONTEND already does all dependent typing. So the
     backend combinators are **UNTYPED** — NO dependent-combinator *typing* is
     needed (that would be the LCCC research lift). Dependent combinators are only
     required to typecheck combinators directly; Path C typechecks on the frontend
     and only *computes* on combinators.
3. **Delete NbE → XII singular oracle.** Backend = untyped CCL; `xii_rewrite`'s
   `apply_one` does every computation by first-order matching; `critpair_enum`+
   `conf_cert` guarantee whole-theory confluence; typed CL is SN ⇒ the `xtm_gate`
   passes (unlike λσ). H4 "One Engine" honored.

### The pipeline
`MLTT term (typed on the frontend) → bracket-abstraction compiler → CCL term
(variable-free) → XII apply_one to normal form → xii_rewrite_struct_eq`. Eliminators
become combinator constants with first-order ι-rules — and CRUCIALLY no
substitution in their RHS, because the methods are already CLOSED combinators:
`natrec P z s (succ m) → APP(APP(s,m), natrec P z s m)` is pure application.

### Brick sequence (each verifiable; the differential KAT gates NbE-deletion)
- **B13 (first, proof-of-concept):** `numera/combinator.iii` — SKI constants +
  first-order reduction (`I x→x`, `K x y→x`, `S x y z→x z (y z)`) + bracket
  abstraction (`λ*x.x=I`, `λ*x.M=K M` if `x∉M`, `λ*x.(M N)=S(λ*x.M)(λ*x.N)`),
  tested on pure routing with atoms (`compile((λx.x) c) ↝ c`,
  `(λx.λy.x) c d ↝ c`, `(λx.λy.λz.(x z)(y z)) ↝ S` applied routes correctly).
  Self-contained; proves variable-free first-order reduction. KAT `853`.
- **B14:** data constructors + eliminator ι-rules as combinators (Bool/Nat/Sum/…
  selection rules, first-order).
- **B15:** upgrade SKI→CCL for βη (R1); wire `tc_conv` to compile→reduce→struct_eq;
  the **differential KAT** `xii_conv ≡ nbe_conv` over the whole `841`–`852` corpus.
- **B16:** delete NbE; register rules in the real `xii_rewrite`; run
  `critpair_enum`+`conf_cert` for whole-theory confluence. XII is the singular
  oracle.

**Risk: HIGH (a research-grade PHASE, not one brick)** — but R2 removes the LCCC
lift, each brick is corpus-gated, and the differential KAT is a hard gate before
the irreversible NbE-deletion. Verify-or-abstain at every step.

### 19.1 B14/B15 as built — the eliminator combinator set + the differential

**Motive erasure (the key R2 consequence).** Because the backend is UNTYPED, the
dependent eliminators' MOTIVES are type-only and ERASED in compilation:
`natrec(P,z,s,n)`→`NATREC·z·s·n`, `case(C,f,g,s)`→`CASE·f·g·s`, `J(C,d,p)`→`J·d·p`.
Every eliminator therefore collapses to a **≤3-arg first-order combinator**, fitting
the same flat spine-read `cb_step` (no 4-arg machinery needed). **Soundness of
erasure for the differential:** for a CLOSED, REDUCING term the motive vanishes in
the reduct (the value carries no `P`), so `cb_conv` (motive-blind) and `tc_conv`
(motive-normalised, but it disappears) agree. Erasure is unsound only for STUCK
neutrals — which the differential does not use.

**The combinator set (B13+B14, in `numera/combinator.iii`):**
- Combinators `S K I` (β routing) ; constructors `TRUE FALSE ZERO SUCC INL INR REFL`.
- Eliminators as first-order ι-rules in `cb_step` (NO substitution in any RHS —
  the methods are already closed combinators):
  - `I x→x` ; `K x y→x` (1/2-arg, head spine levels 1/2).
  - `J d (REFL a)→d` (2-arg, level 2 — fires when the proof reduces to `refl`).
  - `S x y z→x z (y z)` (3-arg, level 3).
  - `IF TRUE/FALSE t e→t / e` ; `ITER z s ZERO→z`, `ITER z s (SUCC m)→s(ITER z s m)`.
  - `NATREC z s ZERO→z`, `NATREC z s (SUCC m)→s m (NATREC z s m)` (the IH is
    `m` AND the recursive result — distinct from ITER).
  - `CASE f g (INL v)→f v`, `CASE f g (INR v)→g v`.

**The compiler `tc_to_cb` (B15, in `numera/typecheck.iii`).** A total structural
map `TC → CB-source` (`VAR→cb_var`, `LAM→cb_lam(body)` [type dropped], `APP→cb_app`,
`ANN→erase`, data/eliminators → their combinator constants with motives erased);
`cb_compile` then bracket-abstracts to a variable-free term. Type-formers/neutrals
fall back to a unique atom by tag (computational terms never reduce inside them).

**The differential KAT `p5_kat_cbconv` / corpus `855` (B15).** For each vector,
`cb_agrees(x,y) := [ cb_conv(compile x, compile y) == tc_conv(x,y) ]` — the
first-order combinator oracle must AGREE with NbE. Vectors: β, IF, ITER, NATREC,
CASE, J, nested, plus negatives (distinct constructors). Agreement on every vector
is the licence to retire NbE (B16). **η is deliberately EXCLUDED** — combinatory η
is global extensionality (not a local rule; `λf.λx.(f x)` compiles to
`S(S(KS)(S(KK)I))(KI)`, not a `S(K_)I` redex), so it needs the CCL upgrade. The
differential is honestly the **β+ι fragment**; βη is the named B-after-15 step.

## 20. B16–B18 — η via the e-graph, type-level lowering, the death of NbE

The operator blueprint, grounded in the VERIFIED `numera/egraph.iii` API (a real
e-graph: `eg_init`, `eg_add(sym,children,n)`, `eg_union`, `eg_rebuild` [congruence],
`eg_register_rule([lhs_n,rhs_n, <lhs preorder>, <rhs preorder>])` with
`eg_enc_sym(slot,arity)`/`eg_enc_var(idx)`, `eg_saturate(max)`, `eg_find`,
`eg_extract(req,out,outn)` [min-cost]).  Symbols are 32-byte interned ids; rules
are flat-preorder skeletons over symbol-slots + variables.

### 20.0 The empirical crux (states the falsifier up front)
`846` P1 is the NESTED η: `λf.λx.(f x) ≡ λf.f`. The whole phase rests on ONE
empirical question: **can BOUNDED e-graph saturation with the CCL βη axioms merge
the e-classes of two η-equal terms?** This is not provable a priori (saturation is
bounded at `EGRAPH_MAX_PASSES`); it is MEASURED by the differential KAT on the full
`846` corpus. Verify-or-abstain: if bounded saturation cannot reach η, B16 reports
the obstacle (and the fallback — type-directed η-expansion to the Π-arity, which
reuses the proven β engine) rather than shipping a false green.

### 20.1 CCL — the categorical combinators (why, not SKI)
η in SKI is not a local rule; in Curien's CCL it is the single STRUCTURAL axiom
`Λ(App ∘ ⟨x∘Fst, Snd⟩) = x`, which an e-graph CAN apply as an equation. Symbols
(all ≤2-ary ⇒ fit the e-graph): `Id`, `Comp(∘)/2`, `Pair⟨,⟩/2`, `Fst`, `Snd`,
`Cur(Λ)/1`, `App`, plus the data/eliminator atoms (B14 set) and type-former atoms
(B17). Compilation (de Bruijn → categorical, context = a product):
`#0 → Snd`; `#(k+1) → Comp(⟦#k⟧, Fst)`; `λ.b → Cur(⟦b⟧)`;
`f a → Comp(App, Pair(⟦f⟧, ⟦a⟧))`; atom `c → c`.
The **CCLβη axiom set** (registered as e-graph rules — equations; the e-graph makes
them bidirectional via union on match):
`Ass (x∘y)∘z=x∘(y∘z)`, `IdL Id∘x=x`, `IdR x∘Id=x`, `Fst∘⟨x,y⟩=x`, `Snd∘⟨x,y⟩=y`,
`⟨x,y⟩∘z=⟨x∘z,y∘z⟩`, `β: App∘⟨Cur(x)∘y, z⟩ = x∘⟨y,z⟩`,
`η/SP: Cur(App∘⟨x∘Fst,Snd⟩)=x`, `⟨Fst,Snd⟩=Id`.  Plus the ι-equations for the
data eliminators (IF/ITER/NATREC/CASE/J — first-order, already proven in B14).

### 20.2 Conversion via the e-graph (no extraction needed)
`xii_conv(x,y)`: `eg_init`; register the CCLβη+ι rules once; `cax=eg_add(⟦x⟧)`,
`cay=eg_add(⟦y⟧)` (bottom-up); `eg_saturate(N)`; return `eg_find(cax)==eg_find(cay)`.
Same e-class ≡ provably equal under the registered equational theory. (Extraction
is for B17's normal form, not for the yes/no conversion.)

### 20.3 B16 bricks
- **B16a — the η PoC (the falsifier first).** `numera/ccl.iii`: CCL symbols + the
  λ→CCL compiler + e-graph wiring + the axiom set.  KAT `856_ccl_eta`: drive the
  e-graph on the NESTED η pair `⟦λf.λx.fx⟧` vs `⟦λf.f⟧` and a NON-pair
  (`λf.λx.fx` vs `λf.λx.x`) — assert merge / no-merge.  This single test decides
  the phase. (Also re-prove β/ι merges so CCL subsumes B13–B15 semantics.)
- **B16b — wire `xii_conv` + the full η differential.** `cb_eta_conv` via the
  e-graph; extend `p5_kat_cbconv` (or a new `857_ccl_conv`) to assert
  `cb_eta_conv ≡ tc_conv` on ALL of `846` (P1 nested η, P2 no-conflation, P3
  strengthen-fail, P4 reflexive) PLUS the 14 β+ι vectors. On green, the e-graph
  oracle equals NbE on the FULL βη+ι theory.

### 20.4 B17 — epistemic lowering (type-level computation), architected
`infer` currently normalises TYPES with `tc_whnf`/`tc_nf`. Lower that to the
e-graph: extend the compiler to types — `U_k → atom CB_U(k)`, `Π → atom CB_PI`
(with its binder via `Cur`), `Id → atom CB_ID`, etc. (motives NO LONGER erased —
they are real subterms when computing a type). `eg_add` the type, `eg_saturate`,
`eg_extract` the min-cost normal form, map the preorder skeleton back to a TC node.
Bricks: B17a (type→CCL with type-former atoms + round-trip KAT TC→CCL→TC = nf),
B17b (route `infer`'s whnf/nf sites through it; re-green `841`–`855`).

### 20.5 B18 — the death of NbE + the bootstrap falsifier, architected
- B18a: re-wire `tc_conv`/`tc_subtype` call-sites to the e-graph oracle; re-green.
- B18b: re-wire `infer`/`check` type-computation to B17; re-green.
- B18c: SCORCHED EARTH — delete `tc_whnf/tc_nf/tc_shift/tc_subst/tc_alpha_eq/tc_conv`
  (~1000 lines). The kernel now computes ONLY via the e-graph. Re-green `841`–`855`
  with NbE gone — the e-graph is the singular oracle.
- B18d: the **bootstrap falsifier**. The differential is dead (no NbE reference).
  Soundness now rests on `xii_critpair_enum`+`xii_conf_cert`+`xii_termination`
  CERTIFYING the CCLβη+ι rule set locally-confluent + terminating (Newman ⇒
  confluent ⇒ the e-graph's equality is exactly the intended βη+ι theory). Emit the
  content-addressed seal of the certified rule set.

### 20.6 Risk ledger (verify-or-abstain at each)
1. **Bounded saturation achieves η** (B16a) — the crux; MEASURED, not assumed.
2. **CCL axiom set is correct + confluent** — `847`-style under-binder + the `846`
   negatives guard against over-merging (P2/P3 must NOT merge).
3. **`eg_extract` min-cost = a valid TC normal form** (B17) — round-trip KAT.
4. **`conf_cert` can certify the CCL rule set** (B18d) — if CCL+ι is not
   provably-terminating in `xii_termination`'s fragment, the seal cannot issue →
   report honestly rather than fake it.
The phase proceeds ONLY as each gate goes green; any hard obstacle is reported with
its partial result, never papered over.
