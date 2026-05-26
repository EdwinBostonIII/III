# mig4 · Step 1 — Declarative rule representation (IMPLEMENTED + VERIFIED)

**Status: IMPLEMENTED + VERIFIED (mig4 Step 1 complete).**
Module `omnia/xii_rule_patterns.iii` (the §2 structural representation + the 49-rule descriptor table + the §5 structural matcher + the Step-2 accessors) and corpus `810_xii_rule_patterns` (the §6 faithfulness gate) are built into the live `libiii_native.a` and gated by `run_corpus.sh` (`[810_xii_rule_patterns]=99`). The KAT is GREEN (exit 99): table integrity (49 rows, first rid=1, last rid=105, every root a valid XII kind) + an **all-49 shape-acceptance sweep** (every descriptor row's intended shape is accepted) + **11 hand-fired faithfulness witnesses** (each first confirmed to fire the real engine matcher via `apply_specific`/`last_rule_fired`, then required to structurally match — the superset relation, so a mis-built witness fails as a distinct code, never a vacuous pass) + **5 negative arms** (a bare TRIT_VAL, a kind-mismatched FCOMPOSE against two rules, an unknown rule-id — all rejected). Per §1 the scope is the structural LHS only (guards + RHS stay engine-side as references, by design — overlap detection needs structure, not side-conditions); faithfulness is the sound over-approximation `structural_pattern(t) ⊇ match_R0NN(t)`. Purely additive — the engine cascade is untouched, so the differential gate is unaffected and the change is link-isolated (`XRP_`/`xrp_` is a grep-verified-unique namespace, so no existing test pulls the new object).

Evidence (the prior phase, retained): five read-only analysts extracted the exact LHS/RHS/side-condition/result-shape/ordering of all 49 rules (R001–R044 + trit 101–105) from `omnia/xii_rewrite.iii`, cross-checked against the source; R043/R044 (under-specified by the analysts) were read directly during implementation. This was the "read everything before editing" phase of the crash protocol.

---

## 1. The goal Step 1 actually serves (and the leverage it unlocks)

Step 1 exists to make critical-pair enumeration (Step 3) possible: to find rule overlaps you must **unify rule LHSs**, which needs the LHS as *data*, not a hand-coded `match_R0NN`. **Creative-solve insight that shrinks the work:** overlap detection needs only the LHS *term structure* (kinds + positions + free variables) — **not** the side-conditions. The guards (`struct_eq`, `cap_disjoint`, bit-field constraints, table lookups) only refine *joinability*, not *overlap*. So the declarative LHS captures structure; guards remain predicate-references. Faithfulness is then a **sound over-approximation**: `structural_pattern(t) ⊇ match_R0NN(t)` — we enumerate *at least* every real overlap, never miss a critical pair, and let Step 4's joinability check (run on concrete instances) do the precise work. This is both safer and far smaller than a fully guard-declarative rewrite.

## 2. The representation (the type to build)

A declarative rule = `{ id, lhs: Pattern, guard: GuardSpec, rhs: RhsSpec }`.

- **Pattern** (term-pattern tree): each node is either `Var(i)` (a free pattern variable, position `i`) or `Node(kind, child_a, child_b, child_c)` where children are Patterns or `ANY`. Shallow (≤2 levels suffices for all 49 — the deepest LHS is `FIF(p, FTHEN(a,x), FTHEN(a',x'))` and `FLOOP(FLOOP(b,n),m)`).
- **GuardSpec** (an enum tag + params, referencing existing helpers — *not* re-implemented):
  `NONE` · `IS_NULLFORM(kind, subform_sentinel)` (the `_is_compose_null`/`_is_then_null`/`_is_grant_noop`/`_is_pe_const_*` family) · `STRUCT_EQ(posA,posB)` · `CAP_DISJOINT(posA,posB)` · `CAP_ZERO(pos)` · `SUBFORM_EQ(posA,posB)` · `BITFIELD(pos, mask, rel, pos2, mask2)` (R023 high16==/low16-disjoint, R024 ring-chain, R028/29 state-eq, R031 equiv+pivot) · `SUBFORM_ORDER(posA, '>' , posB)` (R032/R042) · `TABLE(COMMUTE|COMPOSE, posA, posB)` (R028/29) · `TRIT_VAL(pos)`.
- **RhsSpec** — the 5 result shapes the evidence found (all must be representable):
  1. **PROJECT(pos)** — return an existing child ref (R013,R016–R022,R026,R027,R030,R033–R037,R039,R040). *No alloc, no mutation.*
  2. **FRESH_BASIS(kind, subform_fn)** — new leaf with a computed subform (R023,R024,R028,R029,R031 — bit-field arithmetic; 101–105 — the trit value function).
  3. **INPLACE(set_child_a, set_child_b, set_subform, set_aux)** — mutate `t`, return `t` (R001–R004,R014,R025,R032,R042).
  4. **FRESH_FUSION(kind, child-builders)** — new subtree (R005–R012,R015).
  5. (FRESH_BASIS covers trit.)

## 3. The result-shape + guard taxonomy (the verified evidence, distilled)

| Family | Rules | Root | RHS shape | Guard |
|---|---|---|---|---|
| Associativity | R001–R003 | FCOMPOSE/FTHEN/FWITH | INPLACE (re-nest right) | kind-only |
| Under-assoc | R004 | FUNDER | INPLACE (re-nest left; probes child_b) | kind-only |
| IF prefix-lift | R005,R007,R009,R011 | FIF | FRESH_FUSION | STRUCT_EQ(prefix) **+ CAP_DISJOINT(prefix,p)** |
| IF suffix-lift | R006,R008,R010,R012 | FIF | FRESH_FUSION | STRUCT_EQ(suffix) only |
| Loop | R013 / R014 / R015 | FLOOP | PROJECT / INPLACE(aux=n·m) / FRESH_FUSION | aux==1 / nested-loop+overflow-guard / CAP_DISJOINT |
| Null-identity (D) | R016,R017,R018,R019,R020 | FWITH/FCOMPOSE/FIF/FUNDER | PROJECT | IS_NULLFORM / IS_PE_CONST |
| Null (E) | R021,R022 | FTHEN | PROJECT | IS_THEN_NULL(child_a/b) |
| Merge (F) | R023,R024 | FCOMPOSE/FTHEN | FRESH_BASIS(bitfield) | BITFIELD (grant child-set union / lift ring-chain) |
| Self-loop | R025 | K17_LIFT(basis root!) | INPLACE(subform=TRIVIAL) | from_ring==to_ring ∧ ≠TRIVIAL |
| Seal/Prove (G) | R026,R027 | FTHEN/FCOMPOSE | PROJECT | IS_NULLFORM+kind / SUBFORM_EQ |
| ACT compose (H) | R028,R029 | FCOMPOSE/FTHEN | FRESH_BASIS(bitfield) | state-eq + **TABLE lookup** |
| Equal-branch (L) | R030 | FIF | PROJECT(child_b) | STRUCT_EQ(branches) ∧ CAP_ZERO(p) |
| MEAN transit | R031 | FTHEN | FRESH_BASIS(bitfield) | equiv-eq + pivot-eq |
| FORM sort | R032 / R042 | FCOMPOSE | INPLACE(swap) / FRESH (spine) | SUBFORM_ORDER(>) |
| Idempotent | R033,R034,R035 | FCOMPOSE/FCOMPOSE/FTHEN | PROJECT | SUBFORM_EQ |
| Null-collapse (M) | R036–R041 | FWITH/FCOMPOSE/FUNDER/FIF/FLOOP | PROJECT | IS_NULLFORM (+CAP_ZERO for R040) |
| Identity-lift | R043,R044 | FTHEN | PROJECT | IS_TRIVIAL_LIFT + `_is_then_null` exclusion |
| Trit | 101–105 | TRIT_op | FRESH_BASIS(trit-fn) | both children TRIT_VAL |

Trit value functions (subform = value+1; 0=NEG,1=ZERO,2=POS): NOT=`-a`, AND=`min`, OR=`max`, SUM=`clamp(a+b,±1)`, MUL=`a·b`.

## 4. The confluence question, answered by the evidence

The audit asked: is XII genuinely Church-Rosser, or only "priority-confluent"? The three documented pre-emptions — **R038 ≺ R017/R037**, **R040 ≺ R030**, **R041 ≺ R013/14/15** — are **Knuth-Bendix joining rules**, not divergence-hiders: on each overlap term every candidate rule produces the *identical* result (e.g. `FIF(p, K06_NULL, K06_NULL)` → both R030 and R040 return `child_b` = the null; they even share the `cap(p)==0` guard). The priority fixes *which rule-id is attributed*, never the value. So XII is genuinely confluent on these overlaps; the priority is a tie-break. **Step 3 must enumerate exactly these overlaps and Step 4 must confirm they join** (they do) — turning the hand-asserted 122 into a machine-verified set, and surfacing any overlap the hand-set sampled rather than checked.

## 5. The matcher / applier algorithm (main-session implementation)

- **Structural matcher** `pat_match(rule_id, t, out_binds) -> u8`: walk Pattern vs term; `Var` binds the subterm; `Node` checks kind + recurses; collect bindings. Pure, read-only. (Explicit-stack, no recursion — XII/category W15 discipline.)
- **Guard check** `pat_guard(rule_id, t, binds) -> u8`: dispatch the GuardSpec tag to the *existing* helper (`xii_rewrite_struct_eq`, `cap_set`, `cap_disjoint`, the subform-mask arithmetic, the COMMUTE/COMPOSE tables). Reuse — do not re-implement.
- **Applier** `pat_apply(rule_id, t, binds) -> u32`: dispatch the RhsSpec shape.

## 6. The faithfulness gate (the proof Step 1 must pass)

For every rule, over a term battery (a firing witness + near-misses): assert `pat_match ∧ pat_guard` agrees with the hand matcher (`xii_rewrite_apply_specific(id, t)` sets `last_rule_fired`), AND for the clean families (trit, the projection/null rules) full **byte-equivalence** of `pat_apply` vs the hand applier. The structural-only relation must be `⊇` (over-approximation sound for Step 3). Differential gate stays green throughout (the declarative layer is additive metadata; the engine keeps using its matchers until a later step).

## 7. Step-2 interface (what this hands forward)

The unifier (Step 2) consumes the **Pattern** trees: unify two LHS patterns (Var↔anything with occurs-check; Node↔Node by kind+children), producing an MGU; for each rule pair and each non-Var position, attempt unification to emit candidate critical overlaps → Step 3.

---

**Status of the chain:** Step 1 is DONE + VERIFIED (see the header). The matcher captures the structural LHS only — the sound over-approximation of §1; guards and RHS deliberately remain engine-side references, which is the design (it is exactly what critical-pair *overlap* detection needs), not an omission.

**Next — Step 2 (the unifier, §7).** It consumes the descriptor table through the accessors `xrp_rule_count()` / `xrp_rid_at` / `xrp_root_at` / `xrp_ca_at` / `xrp_cb_at` / `xrp_cc_at`: for each ordered rule pair, unify their LHS patterns (root kind ↔ root kind; each child constraint ↔ child constraint, where `XRP_ANY` is a free pattern variable that unifies with anything and two distinct concrete kinds fail to unify) to decide whether the two rules can fire on a common redex → a candidate critical overlap → Step 3 enumeration. The descriptor's depth-1 child-kind shape means unification is a fixed-arity kind-compatibility check (no occurs-check needed at this depth) — small, total, integer-only. mig4 remains a continuous, gated, multi-build program; nothing is marked done until its gate is green.
