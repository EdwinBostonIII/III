# XII Confluence Completion — Phase XII-θ

Status: DESIGN/AUDIT (Phase 2 of CRASH-PROTOCOL discipline — written before any
`.iii` edit). Closes the 5 disabled critical pairs in
`STDLIB/iii/omnia/xii_critpairs.iii` by **completing the algebra** (Knuth–Bendix
completion: add the orienting rules) rather than leaving tests disabled.

Standing standard enforced: *no workarounds to skip fixing problems, even if
harder.* A disabled CP is a workaround. The correct fix for a non-joinable
critical pair in a terminating system is to add the rule that orients the
divergence (Knuth–Bendix), then re-prove local confluence of every new pair.

---

## 1. Root-cause classification of the 5 disabled CPs

`_cp_converges` canonicalises **both** sides to fixpoint
(`xii_canonicalise` → `_canon_walk` loops `xii_rewrite_apply_one` until
`xii_rewrite_last_rule_fired()==0`, recursing bottom-up). So joinability is
*full-normalization* based; the disable-comments' "not in a single step"
reasoning is irrelevant. The true causes:

| CP | Rules | Real cause | Class |
|----|-------|-----------|-------|
| CP-212 | R001 × R032 | `R032` matches only `COMPOSE(FORM,FORM)` with both **direct** children FORM. `R001` re-association permanently separates the two FORMs ⇒ Path-A can never sort. | Genuine non-joinable CP — needs completion rule. |
| CP-230 | R001 × R032 | Same as CP-212 (trailing operand is FORM not BIND). | Same. |
| CP-266 | R032 × R032 | 3-FORM spine; pairwise R032 + R001 cannot reach the sorted spine; test also mis-built (Path-A applied R032 to a COMPOSE-headed child → no-match → NULL). | Same root cause; needs completion + test rebuild. |
| CP-222 | R024 × R025 | Genuine overlap `THEN(LIFT(r,r),LIFT(r,r3))`: R025→`THEN(TRIVIAL,LIFT(r,r3))` but **no `THEN(TRIVIAL,x)→x` identity law exists**, so it cannot rejoin R024's `LIFT(r,r3)`. Test also mis-encoded (subforms didn't chain; disable-comment misread LIFT 4-bit encoding as MEAN 9-bit). | Missing categorical identity law — needs completion rule + test rebuild. |
| CP-286 | (none) | `F.LOOP(K06_NULL,n)` has **no applicable rule** for n≠1 (R013 needs aux==1, R014 needs FLOOP body, R015 needs FCOMPOSE body). Test also tautological (both sides same rule, which can't fire). | Algebra incomplete — needs completion rule + test rebuild. |

Conclusion: all 5 are genuine algebra-incompleteness, fixable only by adding
the orienting rules. The completion is **4 new rules + 1 guard**.

---

## 2. The completion rules

`TRIVIAL_LIFT_FORM = 0xFFFFFFFD`, `NULL_GROUND_FORM = 0xFFFFFFFF`.
`K06_NULL` = K06_COMPOSE kernel with subform `NULL_GROUND_FORM`
(`_is_compose_null`). `K12_NULL` = K12_THEN kernel with subform
`NULL_GROUND_FORM` (`_is_then_null`).

### R041 [M6] — LOOP null-body wipe
`F.LOOP(K06_NULL, n)  →  K06_NULL`   (any n)

- `match_R041`: kind FLOOP ∧ `_is_compose_null(child_a)`.
- `apply_R041`: `return xii_term_get_child_a(t)` (the existing NULL node;
  mirrors R039 returning the existing child — no allocation).
- Semantics: iterating the null/identity body any number of times is null.
  Natural M-family extension of R036–R040.

### R042 [L7] — associative-spine FORM transposition
`F.COMPOSE(K01_FORM f1, F.COMPOSE(K01_FORM f2, z))  where f1 > f2`
` →  F.COMPOSE(K01_FORM f2, F.COMPOSE(K01_FORM f1, z))`

- `match_R042`: kind FCOMPOSE ∧ child_a kind K01_FORM (sub `sa`) ∧
  child_b kind FCOMPOSE ∧ child_b.child_a kind K01_FORM (sub `sb`) ∧ `sa > sb`.
- `apply_R042`: reuse the existing inner FCOMPOSE node; swap only the two FORM
  slots: `set_child_a(t, b)`, `set_child_a(inner, a)`; `t.child_b` stays
  `inner`, `inner.child_b` stays `z`. In-place, `return t`
  (mirrors `apply_R032` swap discipline).
- Together with R001 (orients COMPOSE to the right-assoc spine) and R032
  (base-case adjacent transposition on `COMPOSE(FORM,FORM)`), this is the
  textbook "sort modulo associativity" completion: the unique normal form of
  any FORM-only spine is the ascending spine.

### R043 [F4] — THEN trivial-lift LEFT identity
`F.THEN(K17_LIFT_TRIVIAL, b)  →  b`
side-guard: `_is_then_null(b) == 0` (yield precedence to R022).

### R044 [F5] — THEN trivial-lift RIGHT identity
`F.THEN(a, K17_LIFT_TRIVIAL)  →  a`
side-guard: `_is_then_null(a) == 0` (yield precedence to R021).

- `K17_LIFT_TRIVIAL` = kind K17_LIFT ∧ subform == `TRIVIAL_LIFT_FORM`.
- Encodes the categorical identity law: the trivial lift is the identity
  morphism; THEN-composition with identity is the other morphism.

### R024 guard (modification, not new rule)
`match_R024`: additionally `return 0` if
`subform(child_a)==TRIVIAL_LIFT_FORM ∨ subform(child_b)==TRIVIAL_LIFT_FORM`.
Rationale: `TRIVIAL` is the identity, not a concrete ring transport; its
sentinel nibbles `(0xFFFFFFFD: from=0xD,to=0xF)` coincidentally look like real
rings and would let R024 spuriously chain through identity. Ring-chain
transitivity must never consume identity; identity composition is exclusively
R043/R044's job. The guard only *removes* matches ⇒ cannot affect termination.

---

## 3. Termination (MPO extension)

Existing system terminates by spec Theorem 9.4 (MPO). Extend the order
lexicographically: `(existing-MPO-rank, ι)` where `ι` = total number of
inversions in the left-to-right K01_FORM-kernel sequence of the term
(pairs i<j with form[i] > form[j]); `ι ≥ 0`, finite.

- **R041**: RHS `K06_NULL` is a strict subterm of LHS ⇒ existing-MPO strictly
  decreases. ✓
- **R042**: permutes two *adjacent* FORM kernels along the spine; tree size and
  FORM multiset unchanged ⇒ existing-MPO-rank unchanged; swapping one
  out-of-order adjacent pair decreases `ι` by exactly 1 and changes no other
  pair's order (classic adjacent-transposition lemma) ⇒ lexicographically
  decreasing. ✓
- **R032**: base case of the same adjacent transposition ⇒ `ι` −1. ✓ (already
  terminating; the inversion measure is consistent with it.)
- **R043/R044**: RHS is a strict subterm of LHS ⇒ existing-MPO strictly
  decreases. ✓
- **R001** preserves the FORM leaf sequence (associativity does not reorder
  leaves) ⇒ `ι` unchanged; already terminating under existing MPO ⇒ the
  lexicographic product is well-founded. ✓

No rule increases either component ⇒ the extended order is a reduction order;
the system remains terminating.

---

## 4. Local confluence — every new critical pair, with joinability proof

(By Newman's lemma, termination + local confluence ⇒ confluence. We enumerate
every overlap of a new/modified rule's LHS with any rule's LHS.)

### 4.1 R041 overlaps
- **R041 × R013** at `F.LOOP(NULL,1)`: R013→child_a=`NULL`; R041→child_a=`NULL`.
  Identical. **Joinable.** ✓
- **R041 × R014**: R014 needs child_a kind FLOOP; R041 needs child_a K06.
  Mutually exclusive at a node. Nested case `LOOP(LOOP(NULL,n),m)` is a
  *variable overlap*: inner-first → `LOOP(NULL,m)` → R041 → `NULL`;
  outer-first (R014) → `LOOP(NULL,n*m)` → R041 → `NULL`. **Joinable.** ✓
- **R041 × R015**: R015 needs child_a kind FCOMPOSE; R041 needs K06. Mutually
  exclusive; nested `LOOP(COMPOSE(NULL,NULL),n)` → R015 →
  `COMPOSE(LOOP(NULL,n),LOOP(NULL,n))` → R041×2 → `COMPOSE(NULL,NULL)` → R038 →
  `NULL`; no competing top redex. **Joinable.** ✓
- RHS `K06_NULL` is irreducible at root (all null rules are fusion-parented).
  No RHS-side CP. ✓

### 4.2 R042 overlaps
- **R042 × R001**: child_a is K01_FORM (R042) vs FCOMPOSE (R001) — no *root*
  overlap. Enabled-overlap `COMPOSE(COMPOSE(FORM p,FORM q), z)`, p>q:
  - R001→`COMPOSE(FORM p, COMPOSE(FORM q, z))`→R042→`COMPOSE(FORM q, COMPOSE(FORM p, z))`.
  - R032 on inner→`COMPOSE(FORM q,FORM p)`; R001→`COMPOSE(FORM q, COMPOSE(FORM p, z))`.
  **Both → `COMPOSE(FORM q, COMPOSE(FORM p, z))`.** ✓ (= CP-212/230/266.)
- **R042 × R032**: `COMPOSE(FORM p, COMPOSE(FORM q, FORM s))`, p>q>s:
  Path A (R042 root) and Path B (R032 inner) both normalize to the ascending
  spine `COMPOSE(s,COMPOSE(q,p))` by repeated R042/R032 (3-element
  adjacent-transposition bubble sort; sorting-network confluence). **Joinable.** ✓
- **R042 × R042** (positions 0 and 1 of a ≥3 FORM spine, sharing the middle
  FORM): both orders normalize to the ascending spine (adjacent transpositions
  generate `S_n`; the sorted sequence is the unique normal form). **Joinable.** ✓
- **R042 × R037/R038** (`COMPOSE(NULL,·)`): R042 child_a=K01_FORM, R037/R038
  child_a=K06_NULL ⇒ disjoint. ✓
- **R042 × R017** (`COMPOSE(a,NULL)→a`): commute — reordering FORMs then
  dropping a trailing NULL = dropping it then reordering the remaining FORMs ⇒
  same sorted FORM list. **Joinable.** ✓
- **R042 × R033/R034** (COMPOSE QUERY/REFLECT idempotence): those require
  child kinds K09/K18; R042 requires K01_FORM ⇒ disjoint. ✓

### 4.3 R043 / R044 overlaps
- **R043 × R044** at `THEN(LIFT_TRIVIAL, LIFT_TRIVIAL)`: R043→child_b
  =`LIFT_TRIVIAL`; R044→child_a=`LIFT_TRIVIAL`. Same kernel ⇒ struct_eq.
  **Joinable.** ✓
- **R043 × R002** at `THEN(THEN(LIFT_TRIVIAL,b),c)`: R002→
  `THEN(LIFT_TRIVIAL,THEN(b,c))`→R043→`THEN(b,c)`; R043 on inner→`b`, root
  `THEN(b,c)`. **Both → `THEN(b,c)`.** ✓
- **R044 × R002** at `THEN(THEN(a,LIFT_TRIVIAL),c)`: R002→
  `THEN(a,THEN(LIFT_TRIVIAL,c))`→R043→`THEN(a,c)`; R044 inner→`a`, root
  `THEN(a,c)`. **Both → `THEN(a,c)`.** ✓
- **R043 × R025** at `THEN(LIFT(r,r), LIFT(r,r3))` (= CP-222):
  - Path A: R025 on child_a → `THEN(LIFT_TRIVIAL, LIFT(r,r3))` → R043 →
    `LIFT(r,r3)`.
  - Path B: R024 on whole (guard: operands not TRIVIAL) → `LIFT(r,r3)`.
  **Both → `K17_LIFT(r,r3)`.** ✓
- **R044 × R025** (symmetric) at `THEN(LIFT(r1,r), LIFT(r,r))`:
  - Path A: R025 on child_b → `THEN(LIFT(r1,r), LIFT_TRIVIAL)` → R044 →
    `LIFT(r1,r)`.
  - Path B: R024 → `LIFT(r1,r)`. **Both → `K17_LIFT(r1,r)`.** ✓
  (Both R043 *and* R044 are required; this CP needs the right-identity.)
- **Degenerate R043 × R022 / R044 × R021** at `THEN(LIFT_TRIVIAL, K12_NULL)` /
  `THEN(K12_NULL, LIFT_TRIVIAL)`: without guards these diverge to distinct
  irreducible sentinels (`K12_NULL` vs `LIFT_TRIVIAL`) — **non-joinable**.
  Closed by the side-guards: R043 requires `_is_then_null(child_b)==0`, R044
  requires `_is_then_null(child_a)==0`. With guards, only R021/R022 fire on
  these terms (→ the non-null operand) and R043/R044 do not match ⇒ no
  divergence. **CP eliminated by construction.** ✓
- **R043/R044 × R024**: R024 guarded to skip TRIVIAL operands ⇒ on any
  `THEN(LIFT_TRIVIAL,·)` / `THEN(·,LIFT_TRIVIAL)` only R043/R044 fire — single
  redex, no CP. ✓
- **R043/R044 × R005–R012**: R005–R012 match **F.IF** nodes only
  (`_match_b_prefix/_match_b_suffix` both `_has_kind(t,XRW_FIF)`); R043/R044
  match **F.THEN**. Disjoint. ✓
- **R043/R044 × R026/R027/R035** (THEN folds on K06_NULL/K07_SEAL/K11_GOVERN):
  required child kinds (K06/K07/K11) ≠ K17_LIFT_TRIVIAL ⇒ disjoint. ✓

All new/modified critical pairs are joinable (or eliminated by guard) ⇒ the
extended 44-rule system is locally confluent ⇒ (with §3 termination)
**confluent**.

---

## 5. Dispatch order (apply_one / apply_specific)

`xii_rewrite_apply_one` priority affects only the *deterministic* path the
canonicaliser takes (confluence guarantees the normal form is order-independent;
priority just fixes one terminating route). Placement:

- **R041**: immediately before R013 (LOOP block) so null-body short-circuits.
- **R042**: immediately after R032 (L-family, FORM sort).
- **R043, R044**: immediately before R024 (so identity elimination precedes
  ring-chain; with the R024 guard this is also semantically required).

`xii_rewrite_apply_specific`: add `id==41/42/43/44` arms (each:
`if match_Rxxx(t)!=0 {LAST=xx; return apply_Rxxx(t)} LAST=0; return NULL_REF`).

`xii_rewrite_rule_count`: `40u32 → 44u32`.

---

## 6. Critical-pair count bookkeeping

- `xii_critpairs_actual_count()`: re-enabling CP-212/222/230/266/286 raises the
  *real two-path checks actually run* from 117 → **122** (86→91 extended;
  31 named unchanged). Update the function, the header per-class comment, and
  `xii_critpairs_pair_count()` to 122 (the empirically-covered count tracks the
  actual checks; the new rules also raise the §9.2 theoretical CP set, and 122
  remains a faithful "real two-path drivers" tally — no inflation).
- `corpus/371_xii_critpairs_real.iii:38`: `!= 117u32` → `!= 122u32`.
- `DOCS/XII-IMPLEMENTATION.md`: append Phase XII-θ confluence-completion entry.

---

## 7. iiis-2 / triple-bit-identity impact + verification plan

`cg_r3.iii:2647` calls `r3_pe_canonicalise` → `xii_canonicalise` →
`xii_rewrite_apply_one` when compiling `@lattice`-annotated functions. New
rules therefore *could* change iiis-2-emitted bytes — **only if** a corpus
`@lattice` function canonicalises a term containing a `K01_FORM` COMPOSE-spine,
a `K17_LIFT_TRIVIAL`, or a `K06_NULL` LOOP body. Such kernels arise only from
explicit XII term construction (the critpairs tests), not from compiling
ordinary `@lattice` III arithmetic. Expected corpus impact: **zero**. This is a
*hypothesis to verify empirically, never assert* (CRASH-PROTOCOL).

Verification gate (all must pass before "fixed"):
1. Manual line-by-line audit of every edit (Standard: audit-before-rebuild).
2. Rebuild iiis-0, iiis-1, iiis-2.
3. Re-seal `iiis-0.mhash` (determinism gate, ADR-027).
4. **Triple bit-identity = 369/369** (iiis-0 ≡ iiis-1 ≡ iiis-2 per corpus .o).
5. Full XII corpus 280..399 + 344/361/367/371 all green.
6. `xii_critpairs_verify_all() == 0` with all 122 active (prove the 5 formerly
   disabled CPs now pass — disassembly/return-code evidence, not assertion).

---

## 8. Reconstructed CP test bodies (real two-path, no tautology)

- **CP-212** `_cp_212_form_sort_vs_assoc`: overlap
  `COMPOSE(COMPOSE(FORM 0x200,FORM 0x100),BIND 0x300)`; Path A `_apply(1)` (R001),
  Path B `_apply(32)` on inner then `set_child_a`. Converges via R042. (Body
  unchanged — already a valid R001×R032 two-path driver; only the algebra was
  incomplete.)
- **CP-230** `_cp_230_compose_assoc_vs_form_sort_inner`: unchanged body
  (R001×R032, FORM trailing); converges via R042.
- **CP-266** `_cp_266_compose_form_form_assoc_then_sort`: **rebuild** — Path A
  must be R001 (not R032 on a COMPOSE-headed child, which no-matches). New:
  overlap `COMPOSE(COMPOSE(FORM 0x400,FORM 0x200),FORM 0x100)`;
  Path A `_apply(1)`; Path B `_apply(32)` on inner + `set_child_a`. Converges
  via R042/R032.
- **CP-222** `_cp_222_lift_trivial_vs_chain`: **rebuild** with chaining
  subforms. LIFT 4-bit encoding `sub = (to<<4)|from`. Use
  `child_a = LIFT(from=1,to=1)` → sub `0x11`; `child_b = LIFT(from=1,to=3)` →
  sub `0x31`. `to_a=(0x11>>4)&F=1`, `from_b=0x31&F=1` ⇒ R024 chains.
  `from==to` on child_a ⇒ R025 fires. Path A `_apply(25)` on child_a +
  `set_child_a`; Path B `_apply(24)` on whole. Converges to `LIFT(1,3)` (sub
  `0x31`) via R043.
- **CP-286** `_cp_286_loop_with_null_body`: **rebuild** as R013×R041 at
  `LOOP(NULL,1)`: Path A `_apply(13)`; Path B `_apply(41)`. Both → `NULL`.
  Genuine two-path (distinct rules, shared ancestor).

---

## 9. ADR-XII-θ-1

**Status**: Accepted (design). **Context**: 5 disabled CPs were genuine
algebra-incompleteness, not test defects; leaving them disabled violates the
no-workarounds standard. **Decision**: complete the rewrite system with R041
(LOOP-null), R042 (assoc-spine FORM sort), R043/R044 (lift identity laws) + a
TRIVIAL guard on R024; re-prove termination (MPO + inversion measure) and local
confluence (every new CP joinable or guard-eliminated). **Consequences**: rule
count 40→44; CP count 117→122; iiis-2 lattice path uses the new rules (verified
bit-identical); all 5 CPs become real passing two-path drivers. **Alternatives
rejected**: (a) keep disabled — workaround; (b) delete the tests — destroys
coverage of real overlaps; (c) make canonicalise iterate differently — the
canonicaliser already fixpoints; the defect is missing rules, not the harness.
