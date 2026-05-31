# III — Interior-Logic Atlas (formal)

A single formal theory. **Def** introduces a symbol; **Ax** stipulates a property
true by construction; **Thm** states one that follows (a falsifier is a refutation);
**Lim** states a boundary. No proposition names an artifact or its method — faculties
relate only by *shared symbols*. The **Glossary (§G)** maps every theory `Tₙ`, symbol,
and method to its III realization with the witnessing test `[✅NNN]`.

**Distinction discipline (uninterpretation).** Every non-logical constant is a *value of
distinction*: a mark fixed only by the axioms that relate it, never by its spelling.
Replace any such constant by a fresh symbol and each proposition stands unchanged — so
every `Ax`/`Thm`/`Lim` is a **schema**, true in *every* structure satisfying `Σ`; III is
one model, exhibited by the interpretation `⟦·⟧` of §G. No artifact, method, or eponym
occurs in a proposition: a residual one is demoted to a typed `Σ⁺` constant (below) and
its name discharged to §G. A bracketed `⟦x⟧ = …` is interpretation, never premise.

## Notation

- `𝔹 = {0,1}`. A **predicate** `D : X → 𝔹` is, by this typing, **total and decidable**.
- `𝒫(X)` powerset; `X ⊎ Y` disjoint union; `Xⁿ`, `X*` finite tuples/strings; `‖`
  concatenation; `|·|` cardinality.
- Relations on `X`: `Eq(X)` equivalences, `PO(X)` partial orders, `TO(X)` total orders;
  `≺` the strict part of `⪯`. For `→ ⊆ X²`: `→*` / `→⁺` the reflexive-transitive /
  transitive closure, `→^{≤B}` the `≤B`-fold image; `x ↓ y :⟺ ∃z. x →* z ∧ y →* z`;
  `SN(→) :⟺ WF(→)` (no infinite chain); `CR(→) :⟺ (←* ∘ →*) ⊆ ↓`.
- `μΦ` least fixed point of monotone `Φ`; `argmin_⪯ S`, `argmax_⪯ S` (ties → least
  index, a fixed `∈ TO`); `<_lex` the lex order on `ℕᵏ` (`∈ WF`).
- `⊨` satisfaction; `[x]_≡` the `≡`-class of `x`; `⌜·⌝` a syntactic encoding;
  `Con(Σ)` consistency of `Σ`.

---

## Σ — Signature

`𝕋` (terms) · `⊢ : 𝕋² → 𝔹` (judgement `t ⊢ T`) · `▷ ⊆ 𝕋²`, `nf : 𝕋 → 𝕋`, `≡ ∈ Eq(𝕋)` ·
`⪯ ∈ PO(𝕋)` (cumulativity) · `𝔻`, `𝒞 : 𝕋 → 𝔻` · `κ : 𝕋 ↠ 𝕂`, `⊑ ∈ PO` (cost) ·
`𝒢`, `𝒱 : 𝒢 → ℕ`, `Φ : 𝒢 → 𝔹`, `M ⊆ 𝒢`, `⊳ ⊆ 𝒢²` · `⊕ : 𝕋² → 𝕋` · `(P,D)` a
**faculty**: a generator `P` and a disposer `D : 𝕋 → 𝔹`.

### Σ₀ — Master law

- **Ax D1.** `x ∈ im P` is *admitted* `:⟺ D(x) = 1`, `D : 𝕋 → 𝔹`.
- **Ax D2.** `∃!⊢` such that `∀D. ∃e. D = e ∘ ⊢` (every disposer factors through `⊢`).
- **Ax D3.** `D = f(derivation)`, `D ⊥ (freq, sample, param)` (no `D` reads a statistic).
- **Ax D4.** `∀D. (∃x. D(x)=0) ∧ (∃y. D(y)=1)`.
- **Thm D5.** `Π := ⋀_{i=1}^{5} Fᵢ` (T6) `: 𝕋 → 𝔹` is a faculty; D4 holds of each `Fᵢ`.
- **Ax D6.** a mutation `δΣ ∈ 𝕋`; admitted `⟺ G(δΣ)=1` (T7) — `Σ` self-mutates under
  the same `D`.

### Σ⁺ — residual constants (uninterpreted; `⟦·⟧` in §G)

Each is a typed mark carrying no property beyond those stated here; spellings are mnemonic.

- `𝔉` a finite index set, `|𝔉| = 9`; `req : 𝔉 → ℍ`, `inv : 𝔉 → 𝔹`.
- `ℭ` records, projections `fam:ℭ→𝔉`, `act:ℭ→ℍ`, `tgt`, `cap`, `rv,xp:ℭ→𝔹`, `rg : tgt → ℍ`.
- `z,u ∈ ℍ` distinguished: `¬reach(z)`; `reach(u)` and `u` is `⊕`-neutral on pillars `1..4`.
- `A` an operator alphabet, `|A| = 6`; `R ⊆ 𝕋²` oriented, `|R| = 40`.
- `↑ : 𝔹² → 𝔹` the Sheffer stroke, `a ↑ b := ¬(a∧b)`; `∧,∨,¬,⊕` are derived terms over `↑`.
- `𝖽 : Sᴺ → Sᴺ` a unit-delay (one-step memory) on streams; `Ops` a finite operation set on `𝕍 ∈ {𝔹,𝕂₃}`.
- `𝖳 : 𝔽_p^N → 𝔽_p^N`, `(𝖳s)_k = Σⱼ sⱼ·ωʲᵏ`, `ωᴺ = 1` — an exact, invertible spectral map.
- `ℱ` records, projections `φ₁,…,φ₅`; `Hσ : 𝔹*→𝔻` a `σ∈{0,1}`-indexed keyed-digest family.
- `Ω` an ambient host carrier; `dimᵢ` (`i∈1..5`) the coordinates of `G`; `Hₙ` (`n∈1..13`) the invariant family.

---

## Part I — Kernel

**T1 — `⊢`.** A predicative `λΠΣ`-calculus with intensional identity,
the finite types, the naturals, `W`-types, and a quantitative (`0/1/ω`) overlay. It is
the unique relation of **D2**; every later theory's `D` factors through it. Presented
as a formal system over de Bruijn syntax.

**1.1 Raw terms.** `𝕋` is generated inductively (`n ∈ ℕ` a de Bruijn index, `i ∈ ℕ` a
universe level):

```
t,T ::= n | Uᵢ                                      (variable, universe)
      | Π T.T | λ T.t | t·t                          (Π : form, intro, elim)
      | Σ T.T | ⟨t,t⟩ | π₁ t | π₂ t                  (Σ)
      | T＋T | inl t | inr t | case(T; t; t; t)       (＋ : motive; on-l; on-r; scrut)
      | Id(T,t,t) | refl t | J(T; t; t)               (Id : type; motive; base; proof)
      | 𝟘 | absurd(T; t)                              (⊥ : motive; proof)
      | 𝟙 | ⋆   | 𝟚 | tt | ff | if(T; t; t)           (⊤ ; Bool, non-dependent elim)
      | 𝐍 | ze | su t | natrec(T; t; t; t)            (ℕ : motive; base; step; scrut)
      | W T.T | sup(t,t) | wrec(T; t; t)              (W : motive; step; scrut)
```

In a binder (`Π A.B`, `λ A.t`, `Σ A.B`, `W A.B`) the body lies under one fresh
variable `0`; `J/case/natrec/wrec` motives lie under the binders their elimination
introduces. No names occur; hence `α`-equivalence is literal identity (`Thm 1.8.0`).

**1.2 Contexts and structural maps.** `Γ ::= ⋄ ∣ Γ·A`, `|⋄|=0`, `|Γ·A|=|Γ|+1`; `Γₙ`
is the `n`-th type from the top. Shifting `↑ᵏ : 𝕋→𝕋` raises every free index by `k`
above a cutoff; single substitution `t{u}` replaces index `0` by `u` and lowers the
rest. **Lem 1.2.1 (substitution):** `(t{u}){v} = (t{↑¹v}){u{v}}` and `↑`, `{·}`
commute with every former — the equalities the eliminator result-types depend on.

**1.3 Reduction `▷`.** The contraction rules (β; the surjective-pairing/product-`η`
rule is *omitted* — `Lim 1.8.9`):

```
β    (λA.t)·u            ▷ t{u}                  σ   πᵢ⟨a₁,a₂⟩  ▷ aᵢ
＋   case(C;f;g;inl a)   ▷ f·a                        case(C;f;g;inr b) ▷ g·b
Id   J(C;d;refl a)       ▷ d
𝟚    if(C;t;e) tt        ▷ t                          if(C;t;e) ff ▷ e
𝐍    natrec(C;z;s;ze)    ▷ z                          natrec(C;z;s;su n) ▷ s·n·natrec(C;z;s;n)
W    wrec(C;s;sup(a,f))  ▷ s·a·f·(λb. wrec(C;s; f·b))
η    f : Π A.B           ▷ λA.((↑¹f)·0)            (η for Π only, at typed redices)
```

`▷` is the compatible (congruence) closure of these; `▷*` its reflexive-transitive
closure; `↓` joinability.

**1.4 Conversion.** `nf := λt.` the `▷`-normal form (total on typed terms by
`1.8.2–3`); `t ≡ u :⟺ nf t = nf u`. `≡ ∈ Eq(𝕋)`.

**1.5 Typing `Γ ⊢ t : T`** (least relation closed under):

```
        n < |Γ|                              ─────────────────────
(var) ─────────────────────          (sort) Γ ⊢ Uᵢ : U_{i+1}
       Γ ⊢ n : ↑ⁿ⁺¹(Γₙ)

       Γ ⊢ A:Uᵢ   Γ·A ⊢ B:Uⱼ                 Γ ⊢ A:Uᵢ   Γ·A ⊢ t:B
(Π-F)─────────────────────────       (Π-I)──────────────────────────
       Γ ⊢ Π A.B : U_{max(i,j)}              Γ ⊢ λA.t : Π A.B

       Γ ⊢ f:Π A.B   Γ ⊢ a:A                 (Σ-F like Π-F)
(Π-E)──────────────────────────       (Σ-I) Γ⊢a:A  Γ⊢b:B{a} ⟹ Γ⊢⟨a,b⟩:Σ A.B
       Γ ⊢ f·a : B{a}                  (Σ-E) Γ⊢p:Σ A.B ⟹ π₁p:A , π₂p:B{π₁p}

(Id-F) Γ⊢A:Uᵢ Γ⊢a,b:A ⟹ Γ⊢Id(A,a,b):Uᵢ      (Id-I) Γ⊢a:A ⟹ Γ⊢refl a:Id(A,a,a)
(Id-E,J) Γ⊢p:Id(A,a,b)  Γ⊢d : C·a·(refl a) ⟹ Γ ⊢ J(C;d;p) : C·b·p

(𝟘) 𝟘:U₀ ;  Γ⊢e:𝟘 ⟹ absurd(C;e):C·e          (𝟙) 𝟙:U₀ , ⋆:𝟙
(𝟚) 𝟚:U₀ , tt,ff:𝟚 ;  Γ⊢s:𝟚 Γ⊢u:T Γ⊢v:T ⟹ if(T;u;v) s : T     (non-dependent)
(＋) Γ⊢A,B:U ⟹ A＋B:U_{max} ; inl/inr checked vs a stated A＋B ;
       case(C;f;g;s): s:A＋B, f:Πa.C(inl a), g:Πb.C(inr b) ⟹ C·s
(𝐍) 𝐍:U₀, ze:𝐍, (Γ⊢n:𝐍⟹su n:𝐍) ; natrec(C;z;s;n): C:𝐍→U, z:C·ze,
       s:Πk:𝐍. C·k→C·(su k), n:𝐍 ⟹ C·n
(W) Γ⊢A:Uᵢ Γ·A⊢B:Uⱼ ⟹ W A.B:U_{max} ; wrec(C;s;w): w:W A.B,
       s:Πa:A.Π(f:B{a}→W).((Πb.C·(f·b))→C·sup(a,f)) ⟹ C·w

       Γ ⊢ t:A    A ⪯ B    Γ ⊢ B:Uᵢ
(conv)──────────────────────────────────
       Γ ⊢ t : B
```

**1.6 Cumulativity.** `⪯ := ≡ ∪ { (Uᵢ,Uⱼ) : i ≤ j }` (the realized order is shallow:
sort-level, else `≡`). `Thm:` `⪯ ∈ PO(𝕋)` and `≡ ⊆ ⪯`.

**1.7 Algorithm (bidirectional).** Partial `infer : Ctx×𝕋 ⇀ 𝕋` (the rules read
upward, with `↑/{·}` as in 1.5) and `chk(Γ,t,T) := (infer(Γ,t)↓S) ∧ (S ⪯ T)`, mutually
recursive. `Thm 1.7.1 (adequacy):` `infer(Γ,t)↓S ⟹ Γ⊢t:S`, and `Γ⊢t:T ⟹
infer(Γ,t)↓S` with `S ⪯ T` — the algorithm is sound and complete for `⊢`.

**1.8 Metatheory** (dependency-ordered; the de Bruijn trusted-core guarantees):
- **Thm 1.8.1.** `CR(▷)`: `←*∘▷* ⊆ ↓`. (Local confluence of the
  critical pairs above + `SN(▷)` (1.8.2) ⟹ `CR`; product-`η`'s absence is what keeps this.)
- **Thm 1.8.2 (Strong normalization).** `SN(▷)` on well-typed terms (a reducibility-
  candidates / logical-relations model interpreting each former; predicativity is
  essential).
- **Cor 1.8.3.** `nf` is total on typed terms and `≡` is decidable (normalize; compare
  by 1.8.0).
- **Thm 1.8.4 (Subject reduction).** `Γ⊢t:T ∧ t▷t' ⟹ Γ⊢t':T`.
- **Thm 1.8.5 (Decidability of `⊢`).** `chk : 𝕋²→𝔹` is total (1.7 + 1.8.3); `⊢` only
  *checks*, never searches — the de Bruijn criterion.
- **Thm 1.8.6 (Canonicity / consistency).** `⋄ ⊬ t : 𝟘` for every `t`. (By 1.8.2–3 a
  closed term has a normal form; a closed normal inhabitant of `𝟘` would be a
  `𝟘`-introduction, of which there are none.) Equivalently: the logic is consistent.
- **Thm 1.8.7 (Predicativity — the keystone).** The rule `Γ ⊢ Uᵢ : Uᵢ` is
  **not** admissible; adjoining it (`Type:Type`) inhabits `𝟘` (the impredicative-
  universe paradox), contradicting 1.8.6. The stratification `U₀ : U₁ : ⋯` (sort rule)
  is exactly its negation, and is what `D2`'s soundness rests on.
- **Lim 1.8.9.** Adjoining surjective pairing / product-`η` breaks `1.8.1`; it
  is therefore excluded — the convertibility checker is `T2`, not an `Σ`-`η` theory.

**1.9 Quantitative overlay (QTT).** Semiring `𝕄 = ({0,1,ω}, +, ·, 0, 1)` with `1+1 =
ω` and `ω·x = ω` for `x ≠ 0`; join `⊔`; preorder `⊑_𝕄 = {(0,0),(1,1),(0,ω),(1,ω),
(ω,ω)}`. A *graded* context assigns each binder a multiplicity; a graded judgement
`Γ ⊢_γ t : T` carries a usage vector `γ ∈ 𝕄^{|Γ|}`, with `(Π-E)` *adding* the usages
of `f` and `a` (scaled by the binder's multiplicity) and a branch *joining* by `⊔`. A
binder is *well-used* iff its computed usage `⊑_𝕄` its declared `m`. **Thm 1.9.1
(conservativity):** erasing all multiplicities (`m ↦ ω`) maps `⊢_γ` onto `⊢`; grading
is a sound overlay that never changes inhabitation, only restricts it (`m=1` ⇒ used
exactly once, `m=0` ⇒ erased, `m=ω` ⇒ unrestricted).

**T2 — `(ℂ, ▷_C, nf_C)`.** A categorical-combinator algebra as a directed,
terminating, confluent rewrite that *realizes* T1's `≡` with no substitution.

**2.1 Combinators.** `ℂ ∋ c ::= Id ∣ c∘c ∣ ⟨c,c⟩ ∣ Fst ∣ Snd ∣ Cur(c) ∣ App ∣ κ_a` —
the morphisms of a cartesian-closed category (`∘` composition, `⟨,⟩` pairing, `Fst/Snd`
projections, `Cur` currying, `App` evaluation, `κ_a` atoms).

**2.2 Compilation `γ : 𝕋 → ℂ`** (the de Bruijn context is an iterated product; a closed
term is a morphism from the point):
```
γ(0) = Snd        γ(n+1) = γ(n) ∘ Fst   (so γ(n) = Snd∘Fstⁿ)
γ(λA.b) = Cur(γ b)        γ(f·a) = App ∘ ⟨γ f, γ a⟩        γ(κ_a) = κ_a
```

**2.3 Reduction `▷_C`** (oriented; surjective pairing omitted):
```
(idˡ) Id∘x → x      (idʳ) x∘Id → x      (ass) (x∘y)∘z → x∘(y∘z)
(dp)  ⟨x,y⟩∘z → ⟨x∘z, y∘z⟩        (dcur) Cur(x)∘y → Cur( x ∘ ⟨y∘Fst, Snd⟩ )
(fst) Fst∘⟨x,y⟩ → x  (snd) Snd∘⟨x,y⟩ → y
(β)  App∘⟨Cur(x)∘y, z⟩ → x∘⟨y,z⟩   (β₀) App∘⟨Cur(x), z⟩ → x∘⟨Id, z⟩
(η)  Cur(App∘⟨x∘Fst, Snd⟩) → x      (wk) κ_a∘y → κ_a
```
`▷_C` = the compatible closure; `nf_C` its normal form; `ρ : NF_C ⇀ 𝕋` the read-back,
`ρ∘γ = id` (mod `≡`).

**2.4 Metatheory.**
- **Thm 2.4.1 (SN).** `SN(▷_C)` — a monotone polynomial interpretation strictly drops
  on each rule.
- **Thm 2.4.2 (WCR).** every critical pair of `{idˡ…wk}` joins (finite check).
- **Thm 2.4.3 (CR).** `WCR` (2.4.2) + `SN` (2.4.1) ⟹ `CR`, so `nf_C` unique.
- **Thm 2.4.4 (adequacy).** `x ≡_{βηι} y ⟺ nf_C(γ x) = nf_C(γ y)` — sound and complete
  for `β`, full function-`η`, and `ι` on `im γ`. This is exactly T1's `≡` (Def 1.4),
  computed without substitution.
- **Def 2.4.5.** `conv(x,y) := [ nf_C(γ x) = nf_C(γ y) ] : 𝕋²→𝔹`, the convertibility decision T1 calls.
- **Thm 2.4.6 (certificate).** `CR(▷_C)` is a `𝒞`-sealed (T3) re-checkable object: a
  fast path hashing each rule's one-step image, a deep path re-deriving 2.4.1–2.4.2.
- **Lim 2.4.7.** surjective pairing / product-`η` is excluded; adjoining it loses CR
  — the formal reason T1 (Lim 1.8.9) defers conversion to this theory.

**T3 — `𝒞 : 𝕋 ↪ 𝔻`.** A keyed injection giving every term a collision-free name.

**3.1 Space.** `𝔻 = 𝔹²⁵⁶`; a suite `σ ∈ {0,1}` selects `Hσ : 𝔹*→𝔻` (a two-element
keyed-digest family); `𝒞_σ := Hσ ∘ enc`, `enc : 𝕋 → 𝔹*`. **Ax (side-tag).** `σ` indexes the
family but is *not* in the image: `𝒞_σ(x)` equals the bare `Hσ(enc x)`, no framing — so
a suite change is behavior-preserving.

**3.2 Security (standing assumptions, treated as idealizations).** each `Hσ` is
**deterministic**, **collision-resistant** (`Pr[𝒞x=𝒞y ∧ x≠y]` negligible), and
**2nd-preimage resistant**; hence `𝒞_σ` is taken injective: `𝒞x = 𝒞y ⟹ x ≡ y`.

**3.3 Structured addresses.** `compute(p,o,i)=H(p‖o‖i)`, `compose(l,r)=H(l‖r)`,
`branch(c,b)=H(c‖b)`; the streaming `Hˢ = begin·(dom‖δ)*·payload*·final`,
separator `δ=0x00` closing every domain.
- **Thm 3.3.1 (domain separation).** distinct domain/payload partitions yield distinct
  preimages ⟹ `Hˢ` is injective on well-separated inputs; a boundary cannot be
  forged by payload content.

**3.4 Equality.** `eq_𝔻(d,d') := [ ⋁ⱼ (dⱼ ⊕ d'ⱼ) = 0 ]`, by XOR-accumulation over all
256 bits — time independent of the first differing bit (constant-time, no early exit).

**3.5 Behavior-preservation (collapse theorem).** each `compute/compose/branch/Hˢ`
output is byte-identical to the bare `Hσ` of its concatenation; so folding the legacy
address paths into one primitive changes no digest and drifts no seal. A 1-bit input
change changes the digest (3.2); a null or unknown-suite input is rejected by a
distinct code.

**T4 — `𝕋/≡` (congruence closure).** The global quotient, a union-find over
content-addresses, with a faithfulness gate.

**4.1 Carrier.** interned terms `x₁,…,x_N`, each with key `𝒞(xᵢ)` (T3) and cost
`cost(xᵢ) ∈ ℕ`; a *class* is a block of a partition `κ : [N] ↠ 𝕂`.

**4.2 Structure.** a forest `par : [N]→[N]` (roots = fixed points), ranks `rk`; `find`
path-compressed, `union` by rank. **Thm 4.2.1.** `m` operations cost
`O(m·α(N))` (`α` a fixed near-constant, `α ∈ o(log*)`); `find i = find j ⟺ κi = κj`.

**4.3 Merge modes.**
- **automatic:** `𝒞(xᵢ) = 𝒞(xⱼ) ⟹ κi := κj` (sound by 3.2: equal address ⟹ `≡`).
- **certified:** `μ(i,j,π)` unions `κi,κj` iff `π ⊢ (xᵢ ≡ xⱼ)` (a discharged T1 proof);
  the surviving root keeps `min_⊑` of the two class costs.
- **Ax 4.3.1 (faithfulness).** `π = ∅ ⟹ μ(i,j,∅) = 0`. No unproven equality is ever
  posited.

**4.4 Soundness & ring.** **Thm 4.4.1.** the induced relation `{(i,j) : κi=κj}` is
`⊆ ≡`: every union is justified by 3.2 or a T1-proof, so `𝕂` is a *sound* quotient of
`(𝕋,≡)`. **Def.** ring `:= |𝕂|` (distinct classes among the interned); `cost_𝕂(c) :=
min_⊑ { cost(xᵢ) : κi = c }`, maintained at the root — the realization references
resolve to.

**T5 — `(sat_R, ext)` (bounded equality saturation).** A congruence-closed family of
`≡`-classes under a rule set `R`, with min-cost extraction; the classical realization
of *superposition* (T17′).

**5.1 Objects.** an *e-node* `f(c₁,…,c_k)` (symbol `f`, child class-ids); an *e-class*
a union-find block of e-nodes. **Congruence invariant:** `(∀i. cᵢ = c'ᵢ) ⟹ f(c⃗) ≡
f(c⃗')`. A hash-cons `H : (f,c⃗) ↦ node` makes interning idempotent.

**5.2 Operations.** `add(f,c⃗)` interns an e-node and returns its class; `union(a,b)`
merges two classes; `rebuild` re-canonicalizes the parents of merged classes to a
fixpoint. **Thm 5.2.1.** after `rebuild`, `≡_{eg}` is the *least* congruence containing
the asserted unions.

**5.3 Saturation.** for a rule `ℓ→r` and each match `σ`, `union(σℓ, σr)`; iterate all
rules + `rebuild` to a fixpoint or step bound `B` (matcher/instantiator are explicit
worklists, no recursion). `B < ∞ ⟹ sat_R` terminates.

**5.4 Extraction.** cost `γ : node→ℕ` lifts to `cost(c) = min_{f(c⃗)∈c}(γ f + Σᵢ
cost cᵢ)`; `ext(c) := argmin` by a bounded fixpoint DP (deterministic).

**5.5 Theorems.**
- **Thm 5.5.1 (soundness).** every class of `sat_R[t]` is `⊆ ≡_R` (the congruence `R`
  generates from `[t]`); `ext[t] ∈ [t]`, so `ext[t] ≡_R t` — extraction realizes an
  equality `R` proves, never fabricates one.
- **Thm 5.5.2 (superposition).** `|[t]| ≥ 2 ⟺ [t]` holds `≥2` distinct realizations at
  once.
- **Lim 5.5.3.** `sat_R` is bounded (not the full deductive closure); `ext` is
  `γ`-minimal over `sat_R[t]`, not over `[t]` — exact global extraction is NP-hard,
  bounded here.

**T6 — `Π = F₁∧…∧F₅`.** The product faculty: the five canonical disposers,
each factoring through the one `⊢` (D2) and each carrying a refuter (D4).

**6.1 The five faculties** `Fᵢ : 𝕋 → 𝔹`:

| | `Fᵢ` | admits | refuter (D4) |
|---|---|---|---|
| F₁ conversion | `conv` (2.4.5) | `conv(1,1) = 1` | `conv(0,1) = 0` |
| F₂ induction | `∀ₙ` (T13′) | a true universal | a false `∀` has no typed step ⟹ 0 |
| F₃ superposition | `[\|[t]\| ≥ 2]` (5.5.2) | a multi-realization class | a singleton ⟹ 0 |
| F₄ proof-opt | `chk(λ.refl i : ∀.Id(i,o))` (T23) | `i ≡ o` proven | a tampered `o` ⟹ 0 |
| F₅ admission | `admit_R ∧ verify` (T23) | a meaning-preserving rule | a meaning-changing one ⟹ 0 |

**6.2.** `Π := ⋀ᵢ Fᵢ`. **Thm 6.2.1.** `Π : 𝕋→𝔹`, factors through `⊢`, and each `Fᵢ`
satisfies D4 — `Π` is un-riggable: no stage can be forced to pass.
**6.3.** `Π` is the kernel dimension `π` of `G` (T7); `Π = 1 ⟺ ⊢` and every faculty are
live and sound — the executable content of D5.

**T7 — `G : 𝕋 → 𝔹`.** The admission predicate on a mutation `x`, with a located
verdict and a bilateral certificate.

**7.1 The five dimensions** (fixed order; located reject = first failing index):
```
ρ(x) := admit_R(x)            rule set root-confluent ∧ terminating          (T17)
h(x) := [ Ȟ¹(𝔘ₓ) = 0 ]        the cover's `Ȟ¹` vanishes ⟹ sections glue
s(x) := [ 𝒞x = d ] ∨ wit(x)    seal matches the declared d, or drift witnessed (T3)
c(x) ∈ 𝔹                        conservativity flag
π(x) := [ Π(x) = 1 ]           kernel + all five faculties sound             (T6)
G := ρ ∧ h ∧ s ∧ c ∧ π : 𝕋 → 𝔹
```
**Thm 7.1.1.** `G` total; `verdict(x) = ADMIT` if `G(x) = 1`, else `min{ i : dimᵢ(x)=0 }`.

**7.2 The consistency ceiling.** **Thm 7.2.1.** `Con(Σ) ⟹ Σ ⊬ Con(Σ)`. Hence
`c` cannot be a `Σ`-derived predicate for a change that *raises proof-theoretic
strength*; it is a stipulated flag, and `¬c ⟹ G = 0` on any unmarked strengthening.
The ceiling is recorded, not evaded: the gate refuses to self-certify new strength.

**7.3 Bilateral certificate** (a commit is a theorem about the move):
- **action** `⊢ (s★ ⊳ s₀) := Φ(s★) ∧ (𝒱 s★ > 𝒱 s₀) ∧ π`.
- **abstention** `⊢ (s₀ ∈ M) := srch(M) ∧ (∀c ∈ M. 𝒱 c ≤ 𝒱 s₀)`.
- **Thm 7.3.1 (BC).** each conjunct admits a D4 refuter; a verified `s₀ ∈ M` ("0 edits,
  proven frontier-optimal") is formally distinct from an unchecked "0 edits" — the
  rubber stamp is unrepresentable.

**T8 — `δΣ ↦ G(δΣ)`.** **Ax (D6).** a mutation `δΣ ∈ 𝕋` of the signature itself is
admitted iff `G(δΣ) = 1` (T7). The `π` conjunct makes `Σ`'s own evolution disposed by
the one `⊢` it defines — the fixed point at which T-seal (Part XI) operates; **Cor.**
`Σ` cannot enlarge its trusted base without `⊢` certifying the enlargement, except
across the stipulated `c` of 7.2.

---

## Part II — Decision theories  (`D : Class → 𝔹`)

**T9 — Boolean satisfiability.**
**9.1** `φ = ⋀ᵢ Cᵢ ∈ CNF` over variables `V`, `Cᵢ = ⋁ⱼ ℓᵢⱼ`, `ℓ ∈ Lit = V ⊎ ¬V`.
`sat(φ) :⟺ ∃α : V→𝔹. α ⊨ φ`; the disposer `D := sat : CNF → 𝔹`.
**9.2 A conflict-driven transition system** — on states `M ∥ φ` (trail `M` = a sequence
of literals, some flagged `ᵈ` as decisions):
```
Unit       M ∥ φ ⟶ M ℓ ∥ φ        if (C∨ℓ) ∈ φ, M ⊨ ¬C, ℓ undef in M
Decide     M ∥ φ ⟶ M ℓᵈ ∥ φ        ℓ undef   (heuristic: least v, positive phase)
Backjump   M ℓᵈ N ∥ φ ⟶ M ℓ' ∥ φ   on conflict: conflict-clause analysis ⟹ learned C', jump
Fail       M ∥ φ ⟶ UNSAT           conflict at decision level 0
```
**Ax.** the `Decide` order is fixed and total; no restart, no clause deletion, no
randomness.
**9.3 Thm.** the system terminates; `D(φ)=1` returns a model (the trail `α ⊨ φ`),
`D(φ)=0` returns a resolution derivation of `□` from the learned clauses; the verdict
is reproducible bit-for-bit.

**T10 — satisfiability modulo `LIA ⊕ BV`.**
**10.1** atoms `A = A_LIA ⊎ A_BV`: `A_LIA = { Σᵢ cᵢxᵢ ⋈ b : ⋈ ∈ {≤,≥,=} }` over `ℤ`;
`A_BV` fixed-width unsigned (`1..64`). `sat_T(Γ) :⟺ ∃m. m ⊨_T Γ`; `D := sat_T`.
**10.2 Lazy theory combination.** the Boolean skeleton (each atom ↦ a fresh proposition)
is solved by `T9`; for each Boolean model its atom-conjunction is decided by a theory solver:
- **LIA:** an exact-rational vertex search (anti-cycling pivot ⟹ termination) + integer
  split on a non-integral basic variable;
- **BV:** expanded bitwise into `T9`;
- **combination:** the two solvers exchange entailed equalities of the
  shared integer variables, iterated to a fixpoint.
**10.3 Thm.** `LIA` and `BV` are signature-disjoint and stably infinite ⟹ the combination
is sound, complete, and terminating; a returned `m` is re-checked by `m ⊨_T Γ`.

**T11 — verified satisfiability** (the disposer split into an untrusted oracle and a
trusted checker — the `(P,D)` of Σ₀ made internal).
**11.1** `D = (P, V)`: `P : CNF → 𝔹 × Cert` is the `T9` search (untrusted);
`V : CNF × 𝔹 × Cert → 𝔹` is the trusted checker.
**11.2 Certificates.**
- **SAT:** `cert = α`; `V(φ, 1, α) := (α ⊨ φ)` — re-evaluate every clause.
- **UNSAT:** `cert = ϱ`, a resolution DAG: each non-leaf node is the resolvent of two
  parents on a pivot `p` (`(A∨p), (B∨¬p) ⊢ A∨B`), leaves `⊆ φ`; `V(φ, 0, ϱ) := (∀
  step valid) ∧ (□ ∈ ϱ)`.
**11.3 Thm (P-independent soundness).** `∀P. V(φ, P(φ)) = 1 ⟹` the verdict is correct.
The trusted base is `V` alone (small, total); `P` may be arbitrarily complex or buggy.
(a refutation-checking discipline; this is `D2`'s factoring made explicit — search
proposes, the small checker disposes.)

**T12 — canonical ideal bases over `𝔽_p`.**
**12.1** ring `𝔽_p[x₁,…,x_v]`; a polynomial is a `≤_grlex`-descending list of terms
`(c ∈ 𝔽_p^×, α ∈ ℕ^v)`; `LT, LM, LC` lead term/monomial/coeff under graded-lex
`≤_grlex ∈ TO`.
**12.2** multivariate division `→_G` (reduce modulo a set `G`); `S`-polynomial
`S(f,g) = (ℓ/LT f)·f − (ℓ/LT g)·g`, `ℓ = lcm(LM f, LM g)`.
**12.3** `G` is a **canonical basis** of `I = ⟨G⟩ :⟺ ⟨LT(I)⟩ = ⟨LT(G)⟩`. **Thm 12.3.1.**
`G` is canonical ⟺ `∀ f,g ∈ G. S(f,g) →_G^* 0`.
**12.4** algorithm: close `G` under `S`-polynomials, skipping coprime-leading pairs
(**Criterion 1:** `gcd(LM f, LM g)=1 ⟹ S(f,g) →_G^* 0`); then inter-reduce and make
monic ⟹ the reduced basis `B`.
**12.5 Thm (canonical form).** for the fixed order, `B(I)` is unique; hence `I = J ⟺
B(I) = B(J)`, and `f ∈ I ⟺ f →_B^* 0` (the `→_B`-normal form is unique). `B` carries a
`𝒞`-digest (T3) for witnessing.

**T13 — finite fields.**
**13.1** `𝔽_{2^k} = 𝔽₂[x]/(m)`, `m` irreducible of degree `k` (`k=8`: `x⁸+x⁴+x³+x+1`;
`k=128`: `x¹²⁸+x⁷+x²+x+1`); `𝔽_p` the prime field. Each carries `(+, ·, ⁻¹, ^)`.
**13.2** in `𝔽_{2^k}`: `+ = ⊕`, `· =` carry-less product `mod m`,
`^ =` binary exponentiation; in every field `a⁻¹ = a^{q-2}` (`q = |𝔽|`),
`0⁻¹ := 0`.
**13.3 Minimal recurrence.** `lfsr : 𝔽ⁿ → ℕ × 𝔽[x]` returns the minimal length `L` and
connection polynomial `C` of the shortest linear recurrence generating the sequence.
**Thm 13.3.1.** `L` is the sequence's linear complexity (minimal), in `O(n²)` field ops.
**13.4 Interpolation.** for distinct `xᵢ`, `lag` returns the unique `P ∈ 𝔽[x]_{<n}` with
`P(xᵢ) = yᵢ`: `P(z) = Σᵢ yᵢ ∏_{j≠i} (z − xⱼ)·(xᵢ − xⱼ)⁻¹`. **Ax.** every path is
fixed-iteration exact field arithmetic; outputs are bit-identical cross-run/CPU.

**T14 — finite categories.**
**14.1** `𝒞 = (Obj, Mor, dom, cod, id, ∘)`, `Obj ⊆ 𝔻`; a morphism `m` has `dom m, cod m
∈ Obj` and `id_x = 𝒞(x ‖ x ‖ "id")`; for `cod f = dom g`, `g ∘ f = 𝒞(f ‖ g)`.
**14.2 Axioms.** `id_{cod f} ∘ f = f = f ∘ id_{dom f}`; `(h∘g)∘f = h∘(g∘f)`.
**Thm 14.2.1 (well-defined composition).** `𝒞` is a deterministic function of its
arguments (T3), so a composite's identity is determined by `(f,g)` — composites are
unique, and the "unique" of each universal property is *realized* by the
content-address (no separate tie-break).
**14.3 Finite (co)limits.** pullback `A ×_C B`, pushout, and coequalizer each exist
and are characterized by their universal cone, realized on the finite slot tables.
**Thm.** associativity (14.2) is the verified law.

**T15 — sheaves on a finite site.**
**15.1** a base `(𝒪, ⊆)` of opens with inclusions; a presheaf `F : 𝒪ᵒᵖ → Set` with
restrictions `ρ^U_V : F(U)→F(V)` for `V ⊆ U`, functorial (`ρ^U_U = id`, `ρ^V_W∘ρ^U_V =
ρ^U_W`).
**15.2 Sheaf condition.** for a cover `{Uᵢ}` of `U`, the diagram `F(U) → ∏ᵢ F(Uᵢ) ⇉
∏_{i,j} F(Uᵢ∩Uⱼ)` is an **equalizer**: a *matching family* `{sᵢ}` (`ρ(sᵢ)=ρ(sⱼ)` on
each `Uᵢ∩Uⱼ`) glues to a **unique** `s ∈ F(U)` with `ρ^U_{Uᵢ}(s) = sᵢ`.
**15.3 Ax (no vacuous gluing).** an unregistered overlap `Uᵢ∩Uⱼ ∉ dom ⟹ glue = ⊥`
(refusal), never vacuous agreement.
**15.4** `glue{sᵢ} := 𝒞(sort{sᵢ})` (T3) — independent of cover order. **Thm 15.4.1.**
`glue` succeeds iff the family is matching and every overlap registered, and the glued
section is then unique (the equalizer's universal property).

**T16 — linear temporal logic (bounded).**
**16.1 Syntax.** `φ ::= a ∣ ¬φ ∣ φ∧φ ∣ φ∨φ ∣ φ→φ ∣ Xφ ∣ Gφ ∣ Fφ ∣ φUφ ∣ Oφ ∣ Hφ ∣
φSφ` (future `X,G,F,U`; past `O,H,S`).
**16.2 Semantics** over a finite trace `τ = τ₀…τ_{L-1}`, `(τ,i) ⊨ φ`:
```
(τ,i)⊨Xφ ⟺ i+1<L ∧ (τ,i+1)⊨φ        (τ,i)⊨φUψ ⟺ ∃k∈[i,L). (τ,k)⊨ψ ∧ ∀i≤j<k.(τ,j)⊨φ
(τ,i)⊨Fφ ⟺ ∃k∈[i,L). (τ,k)⊨φ         (τ,i)⊨Gφ ⟺ ∀k∈[i,L). (τ,k)⊨φ
(O,H,S = the mirror over [0,i])
```
**16.3 Algorithm.** a table `T[a][i]` over (sub-formula `a`, position `i`) filled
bottom-up in arena post-order: a propositional pass per position, then each temporal
node by a closed-form `O(L)` recurrence over its child's full row — no recursion, no
pointer stack. **Thm 16.3.1.** `T[φ][i] = [(τ,i) ⊨ φ]`; `holds` is total and exact for
`L < ∞`.

**T16′ — bisimulation witness.**
**16′.1** a labeled computation DAG; `R ⊆ Comp²` is a **bisimulation** iff it is
symmetric and `(a,b) ∈ R` implies every step of `a` is matched by a step of `b` to an
`R`-related state (and vice-versa); `∼ := ⋃ { R : R a bisimulation }` (the greatest).
**16′.2 Realized check.** `a ∼ b :⟺ (obs a = obs b) ∧ (∃! ctx. {res a, res b} ⊆ ctx)`
— observable-window equality `(op, in-commit, out-commit)` plus both resolving in the
chain-DAG under one cross-branch/epoch context.
**16′.3 Ax.** `a ∼ b ⟹ ∃ w. wit(w, a, b)` — a content-addressed witness fragment `w`
(the two computation ids + the base-proof reference) is the *only* admissible evidence
of `∼`; no equivalence is asserted without it.

---

## Part III — Quantum / math

**T17′ — `adm` (the realization criterion).**
**1.** a pattern `q` (a computational schema) is **admissible** iff
`adm(q) := exact(q) ∧ det(q) ∧ snd(q) ∧ bdd(q)`: `exact` (no float — values in
`ℤ/𝔽_p/ℚ`), `det` (bit-identical replay — `q` is a function, not a distribution),
`snd` (`q = e ∘ ⊢` wherever it touches meaning), `bdd` (bounded integer state).
**Ax.** `float(q) ∨ samples(q) ∨ anneals(q) ⟹ ¬adm(q)`.
**2. Correspondence `≙`** (an exact classical realization per quantum primitive):

| quantum primitive | exact realization | theory |
|---|---|---|
| superposition | the e-class `[t]` | T5 |
| interference | min-plus / congruence merge | T4 |
| Fourier transform | `𝖳` over `𝔽_p` | T31 |
| reversibility | the `𝒞`-witness trail | T29 |
| stabilizer/syndrome | codes over `𝔽_{2ᵏ}` | T13 |

**3. Lim.** amplitude amplification and structured quantum walks map to *structure only*:
`adm` admits the branch-and-prune skeleton, but `¬∃` complexity speedup absent quantum
hardware — the `O(√N)` is not realized, only the oracle-marking shape.

**T18 — `𝕂₃` (the Kleene 3-algebra).**
**1.** carrier `𝕂₃ = {−,0,+}`, chain `− ≺ 0 ≺ +`; `x∧y := min`, `x∨y := max`, `¬x :=
−x` (`− ↦ +`, `0 ↦ 0`, `+ ↦ −`); bounds `⊥ = −`, `⊤ = +`.
**2. Thm (structure).** `(𝕂₃, ∧, ∨, −, +)` is a bounded distributive lattice and `¬`
an order-reversing involution; hence `(𝕂₃, ∧, ∨, ¬)` is a **De Morgan algebra**:
`¬¬x = x`, `¬(x∧y) = ¬x∨¬y`, `¬(x∨y) = ¬x∧¬y`, with distributivity, absorption,
commutativity, associativity.
**3. Thm (Kleene, not Boolean).** the Kleene law `x ∧ ¬x ⪯ y ∨ ¬y` holds for all `x,y`,
yet excluded middle and non-contradiction both fail at `0`: `0 ∨ ¬0 = 0 ≠ +` and `0 ∧
¬0 = 0 ≠ −`. So `𝕂₃` is a proper Kleene/De Morgan algebra (the `0` = "unknown" is its
own negation, neither true nor false), not Boolean.
**4. weight.** `w : 𝕂₃ → ℤ`, `w(−) = −2, w(0) = 0, w(+) = +1`; `w(−) + w(+) = −1 < 0`
— risk-asymmetric (a `−` outweighs an opposed `+`). `w` is *not* a lattice morphism: it
encodes the asymmetry the order alone does not.

**T19 — `ℍ = 𝕂₃⁶`.**
**1.** `ℍ = 𝕂₃⁶`, packed base-3 into `[0,728]`; pillars `1..4` *structural*, `5..6`
*modal*. composition `(a ⊕ b)ᵢ = (a ∧ b)ᵢ` for `i ∈ 1..4`, `(a ∨ b)ᵢ` for `i ∈ 5..6`
(T18 coordinatewise).
**2. Thm (commutative monoid).** `(ℍ, ⊕)` is commutative and associative with unit
`e = (+,+,+,+,−,−)` (`∧`-unit `+` on `1..4`, `∨`-unit `−` on `5..6`) — a product of six
coordinate monoids.
**3.** `reach(h) :⟺ ∀i ∈ 1..4. hᵢ ≠ −`. **Thm (count).** `|reach| = 2⁴·3² = 144`
(pillars `1..4 ∈ {0,+}`, pillars `5..6` free).
**4. Thm (closure).** `reach` is a sub-monoid: `reach(a) ∧ reach(b) ⟹ reach(a⊕b)` (a
`min` of two non-`−` is non-`−`); and `¬reach` is an `⊕`-ideal: `¬reach(a) ⟹ ∀b.
¬reach(a⊕b)` (a structural `−` is absorbing under `min`). Hence bricking is
unrecoverable (the basis of T-desc's Thm).
**5. Ax (admission).** `axiom-valid(d) :⟺ reach(hexad d)` — the single gate T-phi,
T-aeu, and T-desc all invoke.

**T13′ — `∀ₙ`.**
**1.** for a motive `P : 𝐍 → U`, base `z`, step `s`, and a *fresh* variable `n`:
`∀ₙ P := chk( natrec(P, z, s, n), P·n )`.
**2. Thm (soundness).** `∀ₙ P = 1 ⟹ ⊢ z : P·ze` and `⊢ s : Πk:𝐍. P·k → P·(su k)`
(the premises of `natrec`'s typing, T1-(𝐍)). These are the base and step of an
induction, so by `𝐍`-induction `∀n:𝐍. P·n` is inhabited — a genuine universal, not a
finite sample.
**3. Thm (refusal).** if no well-typed step `s : Πk. P·k → P·(su k)` exists (a *false*
universal), `natrec(P,z,s,n)` fails to type-check and `∀ₙ P = 0`. So the bridge
certifies exactly the true universals — sample agreement is neither sufficient nor used.
**4. Lim.** coverage = motives expressible by the structural recursors `natrec / wrec /
J` (`𝐍 / W / Id`); a property not so expressible remains a sample, certifiable only
where a recursor witnesses it.

**T20 — `𝕍` (total uncertain arithmetic).**
**1.** carrier `𝕍 = { known(n) : n ∈ ℤ } ⊎ { gap(r, a⃗) : r ∈ Reason, a⃗ ∈ 𝕍* }`,
`Reason ⊇ {div0, hole, redacted, derived}`.
**2.** `op : Op × 𝕍 × 𝕍 → 𝕍`, total: both-`known` ⟹ compute in `ℤ`, with `÷0 ↦
gap(div0, ⟨⟩)`; otherwise ⟹ `gap(derived, antecedents)`, antecedents = the gap
operands.
**3. Thm (total ∧ sound ∧ precise).** `op` is total (never traps); `op(known a, known
b)` = the exact `ℤ`-result; and `0 · x = known 0` for *all* `x ∈ 𝕍` — the annihilator
holds even over a gap (strictly more defined than strict propagation).
**4.** `roots(g) := leaves(→_anc^* g)` (transitive antecedent closure, by worklist);
`addr(g) := 𝒞(r ‖ a⃗ ‖ |a⃗|)` (T3). **Thm.** `addr` deterministic (equal gaps share)
and injective-in-practice (distinct gaps differ). **Ax (well-formed).** `r = 0 ∨ (kind
= derived ∧ a⃗ = ⟨⟩) ⟹ malformed`.

**T21 — exact symbolic regression.**
**1.** alphabet `A = Op ⊎ Term` (declared operators + terminals); a candidate `e ∈
Tree(A)` serialized to postfix; `eval : Tree(A) × Pt → ℚ` exact (signed-magnitude
Q32.32; no `≺` on signed — only `=` and unsigned-magnitude compares).
**2. Enumeration.** the space `A^{≤β}` (depth `≤ β`) by a big-endian odometer over
(shape, then op/terminal fills) in lexicographic postfix order; a prefix `p` is pruned
*wholesale* when `underflow(p) ∨ depth(p) > β ∨ height(p) ⊁ 1` (it can never extend to
a single-rooted tree of depth `≤ β`); each slot ranges only over realizable arities.
**Thm (boundedness).** the visited set is finite — the prune makes `A^{≤β}` traversal
terminate (e.g. height-`≤5` collapses `~1.1·10⁹` shapes to `~4.6·10⁵`).
**3.** `fit(e) :⟺ ∀ (x,y) ∈ data. |eval(e,x) − y| ⪯ τ` (an independent verifier, pure
over `(e, data)`).
**4. Ax (first-fit).** `canon := first_{<_lex} { e : fit(e) }` — no fitness score,
hence nothing to game. **Thm.** `canon` is reproducible and order-deterministic.
**Lim.** coverage `= A^{≤β}`; nothing is claimed beyond the bounded alphabet/depth.

---

## Part IV — Self-evolution

**T-val — `𝒱`.**
**1.** a state `s ∈ 𝒢` is a labeled digraph `(N,E)`: each node `n` carries `(cap_n ∈
𝔻, int_n ∈ Intent)`; each edge `e` carries `(used_e, wit_e ∈ 𝔹)`.
**2.** three counts `: 𝒢 → ℕ` — `good(s) = #{e : used_e}`, `noise(s) = #{e : ¬used_e ∧
¬wit_e}`, `sep(s) = #{ {i,j} : i≠j ∧ cap_i = cap_j ∧ int_i = int_j }`.
**3.** `𝒱(s) := K + good(s) − noise(s) − sep(s)`, offset `K` keeping `𝒱 ≥ 0`; `𝒱 :
𝒢 → ℕ`.
**4. Ax (hard constraints).** `used_e ⟹ ¬removable(e)` (a load-bearing edge is
irreducible); `int_i ≠ int_j ⟹ ¬unifiable(i,j)` (an intent-distinct pair is a
deliberate variation point).
**5. Thm (non-gameability).** `𝒱` is a function of the three structural counts alone,
so `Δ𝒱 > 0 ⟺ Δgood > 0 ∨ Δnoise < 0 ∨ Δsep < 0`; a relabeling/cosmetic move (no count
change) leaves `𝒱` fixed — only a real structural gain raises it.
**6. Lim.** `𝒱` is a decidable graph proxy for the objective "minimal structure
preserving the proven capability set"; the capability-level minimum (`≡` of programs)
is undecidable and not claimed.

**T-phi — `Φ` (and its non-vacuity).**
**1.** `Φ : 𝒢 → 𝔹`, `Φ(s) := G(s) ∧ reach(hexad s)` — gate-admissible (T7, all five
dimensions) AND axiom-valid (T19).
**2. Thm (non-vacuity ledger; D4 made constructive).** every conjunct of `Φ`
discriminates: for each gate dimension `dimᵢ` there exist `bad_i` (`dimᵢ(bad_i)=0`,
returning the located reject `i`) and `good` (`G(good)=1`); an unwitnessed seal-drift
is rejected, a witnessed one admitted; a `reach` hexad admitted, a `¬reach`
(incl. out-of-range) one rejected. Hence no conjunct of `Φ` is identically `⊤`.
**3. Lim.** `Φ = Φ_checked` is a sound *under-approximation* of `Φ_true` (semantic
non-destruction `= ≡`-of-programs, undecidable): `Φ ⟹ Φ_true` is discharged per-organ;
the converse is undecidable. `Φ` never over-admits — it can only abstain.

**T-arg — `argmax_𝒱`.**
**1.** a frontier `M = {c₁,…,c_m} ⊆ 𝒢` with values `𝒱(cₖ)` and an incumbent `s₀`.
**2.** `argmax M := c_{k*}`, `k* = min{ k : 𝒱(cₖ) = max_j 𝒱(cⱼ) }` (ties → least index,
a deterministic `⊑`); `best := argmax M` if `𝒱(argmax M) > 𝒱(s₀)`, else `⊥`.
**3. Thm.** `best = ⊥ ⟺ ∀c ∈ M. 𝒱(c) ≤ 𝒱(s₀) ⟺ s₀ ∈ M` (a frontier-optimum) — this
`⊥` is exactly the abstention certificate `⊢ s₀ ∈ M` of 7.3.
**4. Lim.** `M` is the *supplied* frontier (the `sat_R`/congruence-reachable set under
proven rewrites); `best` is frontier-local — the global argmax over all states is
unbounded, not computed.

**T-uni — `unify`.**
**1.** `unify(i,j,π) := IntentGate(i,j) ∧ SoundMerge(i,j,π)`, where `IntentGate :=
(cap_i = cap_j) ∧ (int_i = int_j)` and `SoundMerge := (κi = κj) ∨ μ(i,j,π)` (T4: same
class, or a `⊢`-proof-closed merge).
**2. Thm (intent necessity).** `IntentGate` is evaluated first and is necessary: even a
valid `π ⊢ (xᵢ ≡ xⱼ)` does not unify an intent-distinct pair — `int_i ≠ int_j ⟹
unify = 0` for every `π`. Behavioral equality is necessary but **not sufficient**.
**3. Cor.** a sound self-refactorer is *not* "merge every provably-equal pair": the
deliberate variation points (T-val Ax) are preserved.

**T-loop — `fix(merge)`.**
**1.** a step `merge(i,j)` fires iff `G(·) = 1` (T7) ∧ `unify(i,j,·) = 1` (T-uni); each
pass applies all firing merges, repeating until a pass fires none (`fix`).
**2. Thm (termination).** each `merge` strictly decreases `sep` (T-val), bounded below
by `0`; `sep ∈ WF` ⟹ `fix` in `≤ |N|` passes.
**3. Thm (monotone ascent).** each `merge` has `Δsep < 0 ∧ Δgood = Δnoise = 0 ⟹ Δ𝒱 >
0` (T-val Thm) — the loop is strictly `𝒱`-ascending to a local optimum.
**4. Ax (kernel-down freeze).** `π` (the kernel dimension of `G`) is `Π = 1` (T6);
`π = 0 ⟹ G = 0 ⟹ ∄ merge` — a down prover halts all self-editing.

**T-cut — `cut`.**
**1.** `cut(e) := G(·) ∧ ¬used_e ∧ ¬wit_e` — admissible (T7) ∧ `e` carries no
capability ∧ `e` is not witnessed-keep.
**2. Thm (safety).** `used_e ⟹ ¬cut(e)` (a load-bearing edge is never cut, T-val Ax —
`cut` is capability-preserving); `wit_e ⟹ ¬cut(e)` (witnessed intent respected).
**3.** `sweep := { e : cut(e) }` is the de-noising plan; applying it gives `Δnoise < 0
∧ Δgood = 0 ⟹ Δ𝒱 > 0`. With T-uni/T-loop (on `sep`), the loop now acts on every
reducible term of `𝒱`.

**T-ext — `ext_F`.**
**1.** extraction proposes a new provider `F` holding only logic already present in the
graph `G_s` — never generative synthesis. Admitted iff `ext_F := G(·) ∧ C₁∧C₂∧C₃∧C₄`.
**2. C₁ (capability conservation).** `∀ x ∈ exports(F). 𝒞(x) ∈ im(𝒞|_{G_s})` —
interning each export creates **no** new congruence class (T4). **Thm.** `∃ x ∈
exports(F). 𝒞(x) ∉ im(𝒞) ⟹ ¬ext_F` (a fresh address = a hallucinated capability).
**3. C₂ (size boundary).** `saved > |F| + ovh` — the dedup dividend strictly exceeds the
new-file overhead (header + imports + indirection); i.e. `Δ𝒱 > 0` after the penalty.
**4. C₃ (acyclicity).** inserting `caller → F` keeps the dependency graph a DAG iff
`F ⊬→ caller` (`F` does not already reach the caller), decided by a visited-guarded DFS
(terminating).
**5. C₄ (anti-thrash).** `int(F) ∉ { int(parent) }` — the provider carries a distinct
intent class, so T-uni refuses to merge it back; without `C₄` the loop oscillates
extract↔merge.
**6.** each `Cᵢ` is decidable and discharged by an organ already in Σ (T4, 𝒱,
reachability, T-uni).

**T22 — `verify(P,S) := chk(P,S)`.**
**1.** a specification is a type `S ∈ 𝕋` (built with T1's `Π/Σ/Id/𝐍/…` — the type *is*
the intent); a program is the computational content `⌜P⌝` of a proof term `P`
(propositions-as-types, programs-as-proofs).
**2.** `verify(P,S) := chk(P,S)` (1.7) — the kernel *evaluates the proof against the
spec*; it never runs the program.
**3. Thm (soundness).** `chk(P,S) = 1 ⟹ P : S ⟹ ⌜P⌝ ⊨ S` on **all** inputs (the
realizability of `S`); a single missing/false axiom ⟹ `P ⊬ S ⟹ chk = 0` ⟹ the program
is destroyed.
**4. Def.** `admit_P := G(·) ∧ verify(P,S)` — the only admissible route for
*genuinely new* logic.
**5. Lim (propose/dispose asymmetry).** the proposer's *search* for `P` may fail
(`search(S) ↦ ⊥` — `S` may be uninhabited or simply not found: an honest abstain); the
kernel's *check* `chk` is total and always terminates with the correct verdict.
Creativity is unbounded; the leash is absolute.

**T23 — `opt`, `admit(r)`.**
**1.** a rule set `R ⊆ { (l,r) : l ≡ r }` of *true identities* (e.g. `x·2 = x≪1`,
`x+0 = x`, `x·1 = x`, `x·0 = 0`, `1+1 = 2`); the e-class `[t]_R` (T5); cost `= ⟨·,w⟩`
(T-cost); `opt(t) := ext([t]_R)`.
**2. Soundness (re-derivation).** `verify(i,o) := chk( λ. refl i : Π_.
Id(i,o) )` — the kernel re-derives `in ≡ out` as a theorem. **Thm.** `R = ∅ ⟹ opt =
id` (no rules ⟹ singleton class ⟹ no movement, no fabricated equality); a tampered
`o ≠ opt(t) ⟹ verify = 0` (the leash holds even if the optimizer lies).
**3. Interference.** `interf([a],[b]) := verify(a,b)` — two classes merge iff the
kernel proves their values equal; a non-equal merge is refused.
**4. Self-admission (Σ subject to itself).** `admit(r) := (CR_root ∧ SN)(R ∪ {r}) ∧
verify(l_r, r_r)` — **operational** (T17) ∧ **semantic** (23.2). **Thm (the gap).**
`(CR_root ∧ SN) ⊬ verify`: the operational test alone admits a meaning-changing rule
(`add(x,0) → succ(x)`, confluent+terminating yet false), which `verify` rejects — both
gates are load-bearing, neither implies the other.
**5. Contingent evolution.** `opt →_𝒞 propagate`: the optimum is content-addressed;
`𝒞`-equal optima converge to one address (a re-optimized-but-equal source does *not*
propagate — no spurious change), a different optimum gets a new address and propagates
to a recompute fixpoint.

**T-enh — `⊵`.**
**1.** the enhancement order `⊵ ⊆ 𝒢²`: `s★ ⊵ s₀ :⟺ Φ(s★) ∧ 𝒱(s★) ≥ 𝒱(s₀)` —
integrity preserved (T-phi) and value not lowered (T-val); `⊳` its strict part.
**2. Construction.** `s★ := argmax_𝒱 { s ∈ M : Φ(s) }` over the Φ-filtered feasible
frontier (T-arg); abstain iff `s₀ ∈ M`.
**3. Thm (dichotomy).** `s★ ⊳ s₀ ⟺ s₀ ∉ M`: either a strict improvement is found or
`s₀` is a proven frontier-optimum — no third outcome, no vacuous "stay".
**4. Ax (the anti-rubber-stamp law `NV ∧ KT ∧ BC`).** **NV** (D4): every gate `Φ,𝒱,G`
can reject. **KT** (D2): every acceptance factors through `⊢` (T6). **BC** (7.3): an
action carries `⊢ s★⊳s₀`, an abstention `⊢ s₀∈M`, neither derivable vacuously.
**5. Thm (no rubber stamp).** by NV∧KT∧BC, "0 edits" splits into two *distinct* states:
the certified `⊢ s₀∈M` (verified-optimal) vs the *underivable* "unchecked 0 edits" —
the improver cannot emit an uncertified verdict.
**6. Lim.** `Φ` is undecidable-complete (T-phi); `M` is the reachable frontier, so `s★`
is local (T-arg); the inductive lift (T13′) covers Nat/W/Id only.

---

## Part V — Proposer

**T-prop — `P : 𝕋 → 𝕋*` (statistical proposal under deterministic disposal).**
**1. Ax (the prime directive).** let `Stat` = the class of fitted/statistical maps. For
every faculty `(P,D)`: `Stat ∩ paths(D) = ∅` while `Stat ⊆ paths(P)` is permitted — a
fitted map may *propose* but never *decide or assert*. (The redrawn no-ML line:
deciding-vs-proposing, not learning-vs-not.)
**2.** a proposer `P : 𝕋 → 𝕋*` ranks candidates; each is filtered by some `D` (`⊢` /
T-con / T-cost / T17). `P` reorders rule application only by `swap(a,b) :⟺ ¬∃`
non-joining overlap of `a,b` (T17's `reorderable`); within a proven cascade the order
is fixed.
**3. Thm (conservativity — the operational keystone).** `nf(x ∣ P\text{ on}) = nf(x ∣
P\text{ off})` for all `x`: `P` changes the *order* of rule application, never the
normal form. (The counterfactual "removing `P` changes an output" is inexpressible by
a runtime predicate; established by a two-run differential.)
**4. Def (outcomes).** search `∈ {sat, gap, ref}`; synthesis `∈ {can, gap, ref, prov}`
(canonical / gap / refuted / provisional). **Ax (soundness floor).** `correct ⟹ ∃π.
chk(π, ·)` — a "correct" without a kernel-checked proof is downgraded to `gap`, never
`can`.
**5. Ax (seal & wall).** `param(P)` is `𝒞`-sealed, versioned, `cost(P) ≤ β`; only a
`can ∧ chk`-certified value crosses a trust boundary; the fitting procedure
`fit ∉ Σ` (out-of-tree). **Thm.** `∀D. D ⊥ fit` ⟹ a weak `P` only raises `#gap` and
**never** yields a wrong *admit* — the closure makes any weights safe.

---

## Part VI — Rewrite engine

**T17 — `(𝕋, A, R, nf_R)`.**
**1.** a term algebra `(𝕋, {⊕_a}_{a∈A})`, `A` a six-element operator alphabet (`|A| = 6`,
`A = {a₁,…,a₆}`) + leaves; a finite oriented rule set `R` (`|R| = 40`: associativity,
common-subterm lifting, loop reduction, identity / partial-evaluation, folds); `nf_R` the
`R`-normal form (a T2-style directed reduction).
**2. Thm (termination, SN).** `∃ μ : 𝕋 → ℕ³`, `μ = (weight, size, mis-nesting)`, with
`∀r ∈ R, ∀t. μ(r·t) <_lex μ(t)`: a collapse/eval rule drops component 1; a branch-lift
keeps 1 and drops 2; an associativity rule keeps 1,2 and drops 3. `<_lex ∈ WF` (three
bounded-below naturals) ⟹ `R` terminates.
**3. Thm (root confluence).** `CR_root(R)`: every critical-pair overlap *at the root*
joins. **(local lift via `SN`).** `CR_root ∧ SN ⟹ nf_R` unique on the reorderable subset.
**4. Lim (not globally confluent — stated, not hidden).** `CR(R) = 0`: there are `k`
subterm overlaps that do **not** join at root; each is resolved by one fixed strategy
`ς` (and counted). So `nf_R` is a **deterministic** normaliser (`ς` ⟹ one normal form
per term), not a globally-confluent one.
**5. Def.** `admit_R :⟺ CR_root(R) ∧ SN(R)` (the `ρ` of T7); `swap(a,b)` (T-prop) iff
`a,b` have no non-joining overlap; the confluence certificate is `𝒞`-sealed (T3),
`verify ∈ { rehash` (fast — hash each rule's one-step image)`, reprove` (deep — re-run
2+3)`}`.
**6. Def (lowerings — structured computation as `nf_R`).** the six operators carry distinct
algebras: `a₁,a₂` are monoids; `a₃` is left-unital + right-absorbing; `a₄`
is left-associative + right-absorbing; `a₅` is selection; `a₆` is iteration. each
domain's values are leaves, its evaluation `nf_R`, its admission `admit_R`. **Thm
(interoperation).** a mixed program over all six operators collapses in one `nf_R`.

---

## Part VII — Silicon

**T-hdl — `(N, eval, equiv)`.**
**1.** a list `N = (g₁,…,gₘ)` is a topologically ordered operation list (inputs precede
consumers) over `𝕍 ∈ {𝔹, 𝕂₃}`, each `gₖ ∈ Ops` (the boolean + Kleene connectives, a
source/constant, and one unit-delay `𝖽`). `eval(N, ·) : 𝕍ⁿ → 𝕍` is one forward pass
(topological ⟹ no recursion).
**2. Certification.** `equiv(a,b) :⟺ ∀α ∈ 𝕍ⁿ. eval_a(α) = eval_b(α)` — the exhaustive
truth table (`2ⁿ` for `𝔹`, `3ⁿ` for `𝕂₃`). **Ax.** a lowering `src ↦ N` is admitted
iff `equiv(N, src)`: correct *by proof*, not by sampling.
**3. Physical cost.** `gates = #{g ∉ {source, const}}`; `depth = ` longest
input→output chain; `wires = Σ_g indeg(g)`; `land = #{g : irreversible₂(g)} · kT·ln2`
(the thermodynamic erasure floor); `crit = ` the `delay`-weighted longest path; `fan = Σ_net (fanout)²`.
**4. Sequential.** the delay `𝖽` outputs its held state; `step := eval ; latch` — one
synchronous clock (a bounded map, not a fixpoint search).
**5. Optimizer.** proven rewrites `¬¬x → x`, `∧(x,x) → x`, `∨(x,x) → x`; the
live-gate count strictly drops when a rewrite bypasses redundancy (local cost descent).
**6. Lim.** the Minimum Circuit Size Problem and placement/routing are NP-hard and
**excluded**; the certified netlist is the output, consumed by a downstream toolchain.

**T-aeu — `D = ⋀_{i<n} ℓᵢ`.**
**1.** `n` predicate lanes `ℓᵢ : 𝔻 → 𝔹` (e.g. `ℓ₁ =` well-formed `(hexad < 729)`,
`ℓ₂ = reach`, T19); verdict `D := ⋀_{i<n} ℓᵢ` — every lane checked in parallel, one
combinational pass, zero sequential steps.
**2. Thm (certified realization).** the conjunction built from the Sheffer stroke
(`a∧b = (a↑b)↑(a↑b)`) satisfies `equiv(⋀_↑, ⋀_native)` over all
lane-bit combinations (T-hdl).
**3. Thm (scalable).** an `n`-input `↑`-derived `∧`-tree (left fold) is `equiv` to native
`n`-way `∧` over all `2ⁿ` inputs, `n ∈ 2..16`.
**4.** thus `D = 1 ⟺ axiom-valid(datum)` — T19's admission realized in hardware.

**T-cost — `cost : G → ℕ⁶`.**
**1.** a cost is `c ∈ ℕ⁶ = (lat, thr, reg, ic, dc, en)` — latency, throughput, register
pressure, icache, dcache, energy.
**2. Two orders.** the scalarizing total preorder `c ⪯_w c' :⟺ ⟨w,c⟩ ≤ ⟨w,c'⟩`
(saturating dot, overflow-guarded) for a weight `w ∈ ℕ⁶`; and the intrinsic product
lattice `(ℕ⁶, ∧ = min, ∨ = max, ⊥ = 0⃗, ⊤ = M⃗)`. four weights (server / realtime /
lowpower / balanced) are seeded immutably.
**3.** `cost(G) ∈ ℕ⁶` for an operation/dependency graph `G`: `lat =` an analytic
in-order-issue / OoO-complete / in-order-retire pipeline recurrence (bounded by
`MAXCYC` ⟹ `∈ SN`; a cyclic dependency ↦ refuse, never hang); the other five `=` exact
per-opcode integer polynomials.
**4. Thm.** `cost` is total and deterministic (no measurement / sampling / learning;
bit-identical cross-run/CPU); it is the `⊑` that T5 and T23 minimize over, refined to
physical units by T-hdl.

---

## Part VIII — Governance

**T-con — `(Hₙ)_{n=1}^{13}`, `run`.**
**1.** invariants `(Hₙ)_{n=1}^{13}` (coherence properties `Σ`
must satisfy; e.g. `H4`: every computation reduces through the one engine to a unique
normal form `= nf_R` uniqueness, T17).
**2.** each is a self-falsifying clause `Cₙ = (vₙ, fₙ, canaryₙ)`, `vₙ, fₙ : 𝔹`: `vₙ`
(`Hₙ` holds on a good witness), `fₙ` (the clause catches a bad witness — `¬Hₙ`
detected); `holdₙ := vₙ ∧ fₙ`.
**3. Ax (anti-vacuity).** a `canaryₙ` falsely asserting `¬Hₙ` must force the fold to
`0`; a clause that ignored its bad witness would itself fail.
**4.** `run := ⋀ₙ holdₙ`; on failure `run` returns `min{ n : ¬holdₙ }` — the index *is*
the failing invariant's number (clauses registered `H1..H13` in order).
**5. Thm.** `run` *folds the invariants' own falsifiers* (does not re-prove them):
ship/run iff `(∀n. Hₙ) ∧ (∀n. fₙ catches ¬Hₙ) ∧ (𝒞 reproduces)`. On green, `run`
content-addresses its verdict (T3) — a stable seal.
**6. Def (preserve).** `preserve := ⋀ₙ holds(φₙ, τ, ·)` — the LTL checker (T16) run for
each clause's formula against the live trace, witnessing per epoch.
**7. Def (reflect).** every reflection request passes `adm-target ∧ cap ∧ ratify`; its
output proof is enqueued, never applied directly.
**8. Lim.** `Σ ⊬ Con(Σ)` (7.2): the self-soundness target is forbidden — Σ cannot
reflect on its own consistency.

---

## Part IX — Descent

**T-desc — `Ξ : ℭ → 𝔹`.**
**1.** a record `c ∈ ℭ`, `c = (fam ∈ 𝔉, tgt, act ∈ ℍ, cap)`, `|𝔉| = 9`.
**2.** `s(c) := 𝒞(fam ‖ tk ‖ act ‖ tgt ‖ cap)` over a canonical record (T3) —
position-independent (structurally-equal records seal identically) and tamper-evident
(any field change changes `s`).
**3. The four checks.** `χ₁(c) :⟺ (act_r & req(fam)) = req(fam) ∧ ¬rv(c) ∧
¬xp(c)` (every required right held, no ambient grant); `χ₂(c) :⟺ reach(act ⊕
rg(tgt))` (T19); `χ₃(c) :⟺ inv(fam)` (reversibility where required).
**4.** `Ξ(c) := χ₀ ⟶ χ₁ ⟶ χ₂ ⟶ χ₃` (short-circuit, fixed order; `χ₀ := [s(c) = d]` the
declared-seal match; located verdict = first failing check). `Ξ` *decides*; it performs no effect.
**5. Thm (absorption-impossibility, exhaustive).** `∀a ∈ ℍ. ¬reach(a ⊕ z)` (no `a`
launders a structural-`−` target into admissibility) `∧ reach(a ⊕ u) = reach(a)` (a
neutral target neither grants nor removes admissibility — `a` alone decides), over all
`|ℍ| = 729`. By T19's closure (`¬reach` an `⊕`-ideal), the absorbing `z` is
unrecoverable, not guarded.
**6. Def.** each generated table `Tᵢ = gen(σᵢ)` is fixed by one source `σᵢ`, held by a
`drift-check` (`Tᵢ = gen(σᵢ)`), and `𝒞`-sealed.

---

## Part X — Witness

**T29 — `(φ, spine, replay)`.**
**1.** the chain is an append-only DAG; a fragment `φ = (φ₁,…,φ₅) ∈ ℱ`
(producer, operation, pillar, commitment-vector, antecedent-vector), identified by `𝒞(φ)` (T3).
**2.** the spine indexes published fragments: a map `𝒞(φ) ↦ idx`, reverse maps
`pillar/producer/operation ↦ {idx}`, per-epoch roots.
**3.** `replay : seed → 𝔹` re-verifies the chain from a seed by re-attesting every link
(each step an exact index/mask/32-byte compare; no recursion).
**4. Ax.** the spine *indexes and re-attests*: `spine ∉ im(produce)` — it never mints a
fragment, only records and re-checks ones the producer published.

**T30 — `mem`, `lookup`.**
**1.** a cache `mem : 𝔻 ⇀ (com, chain, conf)` keyed by a content-address (T3); value =
(output commitment, producing-chain id, confidence `∈ [0,100]`).
**2. Ax (admission).** `insert(k,v) ⟹ chain(v) ∈ verified` — an unregistered producing
chain never enters the lattice.
**3. Thm (present ≠ trusted).** `lookup(k) = OK ⟺ (k ∈ dom mem) ∧ ¬stale(k)` — meaning
*present and current*, **not** trusted: the caller must re-verify `chain(v)` (T29)
before consuming. A stale entry is invisible to `lookup`, un-staled only by `reval :=
replay` (full chain re-verification).

**T31 — `dist`, `σ = 𝖳(s)`.**
**1.** a per-path timing signal `s ∈ 𝔽_p^N` (`p = 998244353`, `N = 64`); its spectrum
`σ := 𝖳(s)`, `(𝖳s)_k = Σⱼ sⱼ ωʲᵏ` — the integer-exact spectral map (the T17′
realization of a Fourier transform; `ω` a primitive `N`-th root, `ωᴺ = 1`).
**2.** `dist(path, σ) := ‖σ − base_path‖_𝔽` — the exact in-field distance to a
capability-gated baseline; `witness(path) := 𝒞(path ‖ t ‖ σ)` (T33, T3).
**3. Ax.** this theory *reports*, it does not *learn*: it computes closed-form
measures and reports `dist`; it never adapts, counts-and-promotes, or
threshold-triggers. The anomaly **decision belongs to the caller**: `decision ∉ T31`.

**T32 — branch anchoring.**
**1.** the canonical line `L` is append-only; a branch is anchored at a fragment a
branch-anchor clause declares admissible, and *isolated* by a non-canonical pillar + a
branch-id antecedent (canonical reads never see branch fragments).
**2. Ax (gated merge).** `merge_into_canon ⟺ clause-gated ∧ re-verified ∼` — canonical
is appended to **only** through a clause-gated merge carrying a freshly re-verified
bisimulation witness (T16′). **Thm.** `L` stays append-only and every divergence is
witnessed (W34/W42).

**T33 — algebraic time.**
**1.** `t : ℕ`, a strictly monotone counter; `advance := (t := t+1)` is invoked *only*
by the witness hook on a published fragment (single writer); `current, compare, dist`
are reads.
**2. Ax.** time is algebraic, not wall-clock: `t` is a pure function of the publish
sequence, so the same run yields the same stamps (`run ↦ run ⟹ t ↦ t`). A wall-clock
budget is refused at construction — it would break determinism.

---

## Part XI — Extra-Σ

**T-map — the cartographer (extra-Σ).**
**1.** the dependency relation `𝒜 : Mod → 𝒫(Mod)` (module ↦ its imports/externs),
viewed through five lenses + a master map.
**2.** `gate :⟺ (¬∃ duplicate @export) ∧ (¬∃ un-allowlisted cycle in 𝒜)` — fails the
build on a duplicate exported symbol or a non-allowlisted dependency cycle.
**3. Ax.** `T-map ∉ Σ`: it *reasons about* Σ (editable, not in the sealed trust root)
and has erred before — its verdicts are advisory until cross-checked against the ground
graph.

**T-seal — the immune system (extra-Σ).**
**1.** a bootstrap chain `s₀ → s₁ → s₂ → s₃` where `sₖ` compiles `sₖ₊₁` from source
(`s₀` a frozen seed).
**2. Ax (fixed point).** `s₁ = s₂ = s₃ =: 𝒞_★` byte-for-byte (`𝒞_★ = 4e1384…`) — the
golden seal; any drift `sᵢ ≠ 𝒞_★ ⟹ 0`.
**3.** the closure gate `:= (∀m. build(m) = ok) ∧ (∀t. pass(t)) ∧ ledger-consistent ∧
(𝒞 = 𝒞_★)`; a reseal lands iff closure `= 1`.
**4. Thm.** T-seal disposes on Σ's *own reproduction* — it is T8's `G` for the compiler
itself (D6): Σ may reseal only when the full closure (build + corpus + ledger + fixed
point) is green.

**T-ring — the descent substrate (extra-Σ).**
**1.** the hypervisor-depth tables `(SVM registers, VMEXIT set, ring lattice)` of an
ambient host `Ω` (`⊏ Ω`) — the physical/virtualization state beneath the application
layer.
**2.** T-desc re-expresses them in `𝕋` (the `gen(.def)` tables) and gates every
cross-ring cycle by `gate` (T-desc); `Ω` is the territory the descent maps, not part of
the sealed `.iii` Σ.

**T-babel — the ingestion bridge (extra-Σ).**
**1.** `β : Ext → 𝕋` maps external (non-III) forms and intents into `𝕋`.
**2. Ax.** `im β` enters only through some `D` — an ingested form is subject to the same
disposers (`⊢`, `G`, T-con) as a native term; `β` *translates*, it never bypasses a
gate.

**T-reach — the federation reach (extra-Σ).**
**1.** extends a verdict from one node to another. **Ax (federation wall).** a value
crosses a boundary iff `can ∧ cert` — canonical (T-prop) and carrying a `chk`-checked
certificate.
**2. Thm.** a remote claim is re-verified *locally* (by the receiver's `⊢`), never
trusted on assertion — soundness does not cross the wire, only certificates do.

---

## §G — Glossary  (theory / symbol ↦ realization)

**Symbols.** `𝕋, ⊢, chk` ≙ `typecheck`(`tc_infer/tc_check`); `▷, nf, ≡` ≙ `ccl`+
`tc_conv`; `⪯` ≙ `tc_subtype`; `𝒞, 𝔻` ≙ `cad`/`sha256`/`keccak256`; `κ, 𝕂, μ` ≙
`congruence`; `[·], sat_R, ext` ≙ `egraph`; `⊑, ℕ⁶` ≙ `cost_lattice`; `𝒱` ≙
`ripple_metric.rm_value`; `Φ` ≙ `integrity`; `M, argmax` ≙ `ripple_search`; `⊳, ⊢(·⊳·)`
≙ `commit_gate.cg_cert_*`; `⊕, ℍ, reach, 𝕂₃, w` ≙ `hexad_algebra`+`hexad_reach`+`trit`;
`Π` ≙ `sov_pipeline`; `G` ≙ `commit_gate.cg_decide`.

**Theories.** T1 `typecheck`[✅916/933/922]; T2 `ccl`[✅846/855/863]; T3 `cad`[✅665];
T4 `congruence`[✅912]; T5 `egraph`[✅614/906]; T6 `sov_pipeline`[✅916]; T7/T8
`commit_gate`[✅864/934]. T9 `sat`[✅613] (method: CDCL, fixed order); T10 `smt`[✅635]
(simplex+B&B / bit-blast / Nelson-Oppen); T11 `sat_at_scale`[✅637]; T12 `groebner`
[✅638] (Buchberger+Crit-1); T13 `galois`[✅612] (`lfsr` = Berlekamp-Massey, `lag` =
Lagrange); T14 `category`[✅620/676]; T15 `sheaf`[✅621]; T16 `temporal_logic`[✅644];
T16′ `bisimulation_witness`[✅656]. (no `decision_oracle` module; corpus 675 = this
dispatch.) T17′ `DOCS/III-QUANTUM-PRINCIPLE-AND-MATH-AUDIT`; T18 `trit`[✅666]; T19
`hexad_algebra`+`hexad_reach`[✅667/671]; T13′ `induct`[✅933]; T20 `uncertainty`[✅668];
T21 `symbolic_regression`[✅631]. T-val `ripple_metric`[✅917/930]; T-phi `integrity`
[✅931]; T-arg `ripple_search`[✅932]; T-uni `ripple_unify`[✅918]; T-loop `ripple_loop`
[✅919]; T-cut `ripple_cut`[✅920]; T-ext `ripple_extract`[✅921]; T22 `pcc_gate`[✅922];
T23 `sov_isa`[✅915/916]; T-enh `DOCS/III-SOVEREIGN-ENHANCEMENT-COORDINATION`. T-prop ≙
`nous/*`; T17 ≙ `omnia/xii_*`+`sanctus/xii_antidrift`[✅810–826] (`μ`-triple =
weight/node/assoc, `ς` = route-discharge); T-hdl `hdl`[✅923/924/926/927/928]; T-aeu
`aeu`[✅925/929]; T-cost `cost_lattice`+`cost_calculus`+`microarch_model`[✅615/640/616]
(the `lat` recurrence = the analytic pipeline); T-con `h1..h13_charter`+
`charter_terminal`+`constitution_preserver`+`reflection_governance`[✅674/688–699];
T-desc `katabasis/*`[✅600–609]; T29 `witness_spine`[✅633]; T30 `memo_lattice`[✅646];
T31 `entropy_monitor`[✅618] (`NTT` over `p = 998244353`); T32 `branch_anchor`[✅650];
T33 `algebraic_time`; T-map `III-CARTOGRAPHER/cartographer.py`; T-seal `build_iiis*`/
`build_stdlib`/`run_corpus`/`forge_check` + MHASH-LEDGER (`𝒞_★ = 4e1384…`); T-ring
CHARIOT / Ring−1; T-babel `omnia/babel*`[✅902/903]; T-reach `aether/reach_oracle` +
`DOCS/III-THE-REACH-ARCHITECTURE`.

**Demoted readings (`⟦·⟧`).** Each entry is the *intended interpretation* of a `Σ⁺`
constant, or the *name* of a result demoted from a proposition. None is a premise: the
theorems above hold verbatim under any consistent reassignment of these marks.

*`Σ⁺` constants.*
- `𝔉 = {1,…,9}` ⟦effect kinds⟧ ≙ ReadMetal, WriteMetal, Census, Snapshot/Reverse,
  Descend/VMRUN, Observe, SelfVerify, CapOp, CoprocDispatch; `req` ⟦required-rights
  mask⟧, `inv` ⟦reversibility flag⟧; `Tᵢ = gen(σᵢ)` ⟦descent tables⟧ ≙ SVM layout,
  VMEXIT set, ring lattice, BAR layout, census, cycle-family.
- `z` ⟦`BRICK`⟧, `u` ⟦`SAFE`⟧ `∈ ℍ`; `Ξ` ⟦the descent `gate`⟧; `s` ⟦`seal`⟧;
  `χ₀,χ₁,χ₂,χ₃` ⟦`seal_ok, cap_ok, hex_ok, sid_ok`⟧; `rv,xp` ⟦`revoked, expired`⟧;
  `rg` ⟦`region`⟧.
- `A = {a₁,…,a₆}` ⟦XII operators⟧ ≙ compose, then, with, under, if, loop; `R` ⟦the 40
  XII rules⟧.
- `Hσ` ⟦digest suite⟧: `H₀` ≙ SHA-256, `H₁` ≙ Keccak-256; `Hˢ` ⟦the streaming **Crown**⟧.
- `↑` ≙ NAND (Sheffer stroke); `Ops` ⟦netlist gate kinds⟧ ≙ {IN, const, BUF, NOT, AND,
  OR, XOR, NAND, TNOT, TAND, TOR, DFF}; `𝖽` ⟦`DFF` / unit delay⟧.
- `𝖳` ⟦number-theoretic transform (NTT)⟧, `p = 998244353`; `ℱ` ⟦witness-fragment
  records⟧; `w` ≙ `BISIMULATION_WITNESS` ( Ax W41 ); `Ω` ⟦host OS / Ring−1 substrate⟧.

*Eponyms / named methods* (demoted from labels and bodies):
- T1: 1.8.1 ≙ Church–Rosser; its `SN`-lift ≙ Newman's lemma; 1.8.7 ≙ Girard's paradox
  via Hurkens' term; 1.8.9 / 2.4.7 ≙ Klop's counterexample. T2: `(ℂ,▷_C)` ≙ Curien's CCL.
- T4: 4.2.1 ≙ Tarjan; `α` ≙ inverse Ackermann. T7: `Ȟ¹` ≙ Čech `H¹`; 7.2.1 ≙ Gödel-II /
  Löb. T9: §9.2 ≙ CDCL; conflict analysis ≙ 1-UIP. T10: §10.2 ≙ DPLL(T); vertex search ≙
  simplex + Bland + branch-and-bound; combination ≙ Nelson–Oppen. T11: ≙ DRAT.
- T12: "canonical basis" ≙ Gröbner basis; 12.3.1 ≙ Buchberger. T13: `a^{q-2}` ≙ Fermat;
  binary exponentiation ≙ square-and-multiply; carry-less product ≙ Russian-peasant;
  `lfsr` ≙ Berlekamp–Massey (13.3.1 ≙ Massey); `lag` ≙ Lagrange. T17′: §3 ≙ Grover.
  T22: §1 ≙ Curry–Howard, the `verify`/`admit_P` route ≙ proof-carrying code (PCC). T23:
  23.2 ≙ translation validation. T-hdl: `land` ≙ Landauer. T-val §6 / T-ext C₂: the
  minimal-structure objective ≙ MDL (minimum description length).

*Demoted role-nouns* (old descriptive title ↦ theory; each title now leads with its
governing symbol): T1 disposer · T2 conversion oracle · T3 content address · T4
congruence closure · T5 e-graph · T6 pipeline · T7 commit gate · T8 self-gate · T13′
induction bridge · T17′ realization criterion / quantum lens · T18 Kleene 3-algebra ·
T19 hexad algebra · T20 typed gap · T17 XII normalizer · T-val value functional · T-phi
integrity predicate · T-arg value-maximal selection · T-uni certified unification ·
T-loop convergent refactoring loop · T-cut certified noise removal · T-ext topological
extraction · T22 proof-carrying code · T23 proof-carrying optimization & self-admission ·
T-enh Enhancement Theorem · T-prop the Proposer · T-hdl logic→silicon lowering · T-aeu
axiom-enforcement unit · T-cost cost field · T-con constitution · T-desc descent gate ·
T29 witness spine · T30 memo lattice · T31 spectral accountant. The III `Hₙ` ≙ the
Harmony Invariants; law-tags HW2/HW3/SX1/SX3/SX4/W41 are recorded here, not in a Thm.

---

*Closure on Σ₀: `∀` faculty `= (P,D)`; `∀D. D = e ∘ ⊢`; `G` admits; `𝒞_★` holds. T5,
T4, T13′, T-val, T-hdl, T-prop share `⊢` and `𝒞` as Σ-symbols — the formal content of
"used through the same means."*
