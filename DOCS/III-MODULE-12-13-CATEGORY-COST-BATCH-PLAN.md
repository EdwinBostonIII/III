# Modules 12 + 13 — Category & Cost: batch implementation plan

## Gate cleared

Written only because **M11 (the Decision Layer) is verified**: `b3shuoi11` `run_corpus PASS=395
FAIL=0`, `675_decision_oracle=99` (SMT oracle: re-check + determinism + sound-UNSAT), all decision
procedures (`613/614/635/637/638`) + the synced `674_h2_charter` `=99`; `run_xii 93/0`. No
placeholder/deferral/flaw.

## Batch (per the new cadence: ≤3, test once, fewer if 2–3× effort)

M12 (Category) + M13 (Cost) — **two** modules. Both are moderate/light (M11 was the heavy 2–3×
solo batch). They co-belong: the apotheosis routes **coequalizer = egraph class (M11→M12)** and
**cost = egraph min-cost extraction target (M13→M11)**, so the egraph-as-XII compound (M11 clause
#3) becomes reachable only once both land. Tested together with one combined gate.

## Context + gap analysis (the existing KATs are thorough)

- **M12 `category.iii`** (gated `620_category`/`cat_kat`): a finite-category engine — objects
  (32-byte ids), morphisms (`id = Keccak256(src‖dst‖op)`, **composition = op-word concatenation**,
  associative *by construction*; the nested-hash composite is the fixed bug), `cat_check_assoc`,
  `cat_identity`, pullback/pushout/coequalizer. `cat_kat` **already** tests composition,
  associativity, non-composable refusal, coequalizer. **Gap:** the **category identity law**
  (`id∘f = f = f∘id`) is *not* exercised, and associativity only over a 3-chain.
- **M13 `cost_lattice.iii`** (gated `615_cost_lattice`/`cl_selftest`): a pure 6-dim microarch
  lattice — `cl_join` (lub=per-dim max), `cl_meet` (glb=per-dim min), `cl_le_product` (product
  order), `cl_bottom`/`cl_top`, scalarizing orders. `cl_selftest` **already** tests join/meet
  values, idempotence, `a≤join`/`glb≤a`, bottom/top identities, dot saturation. **Gap:** the
  lattice **axioms** it omits — **commutativity, associativity, absorption**, the **lub
  universality** (join is the *least* upper bound, not merely *an* upper bound), and an
  **incomparability** witness (a genuine *partial*, not total, order).

The apotheosis keystones proper — "every transform is a morphism" / "cost is the 4th SovVal
facet" / coequalizer=egraph / cost-functor / egraph min-cost extraction — are **cross-module
unifications** binding M5/M7/M11/M19; those land as the egraph-as-XII compound (their own effort),
not here. The lean, additive, falsifiable keystone for each module is **closing its axiom gap** —
exactly the M3 pattern (a complete subsystem with no preexisting flaw gets a stronger exhaustive
falsifier).

## ADR — Corpus-only, additive; close the axiom gaps; defer the cross-module unifications

- **Decision.** Two corpus falsifiers, no module edits (the engines are complete; the keystones
  *prove the remaining laws*): `676_cat_laws.iii` (identity law + 4-chain associativity +
  composition content-address determinism + non-composable negative) and
  `677_cost_lattice_laws.iii` (commutativity + associativity + absorption + lub-universality +
  incomparability negative).
- **Rejected — implement coequalizer=egraph / cost-functor / cost-as-SovVal-facet now.** Those
  are the cross-module unifications (M11 egraph, M12 functor, M5 SovVal) = the egraph-as-XII
  compound; they bind modules across the tower and are their own effort, per the apotheosis.
- **Consequence.** M12 + M13 each have their full algebraic laws gated (identity for the category;
  the lattice axioms + universality for cost), strengthening the falsifier set. Net: `PASS = 395 +
  2`. No module change ⇒ lib unchanged; only two corpus files + registration.

## Files

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/corpus/676_cat_laws.iii` | identity law (`id_A∘f=f`, `f∘id_B=f`) + 4-chain associativity + compose-determinism + non-composable negative (`extern cat_init/cat_add_object/cat_add_morphism/cat_identity/cat_compose/cat_morph_eq/cat_morphism_src/cat_morphism_dst`). |
| **CREATE** | `STDLIB/corpus/677_cost_lattice_laws.iii` | commutativity + associativity + absorption + lub-universality + incomparability (`extern cl_init/cl_join/cl_meet/cl_le_product/cl_eq/cl_top`). |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[676_cat_laws]=99` + `[677_cost_lattice_laws]=99` (after `[675_decision_oracle]=99`). |
| **NO CHANGE** | `category.iii`, `cost_lattice.iii`, `build_stdlib.sh` MODULES | corpus-only batch. |

## Step 0 — Pre-flight

0.1 `676`/`677` free (globbed). 0.2 APIs confirmed (read this session): `cat_add_object(id32)->slot`
(any distinct 32-byte id), `cat_add_morphism(src,dst,op32,out)->slot`, `cat_identity(obj_slot,
out)->morph_slot`, `cat_compose(f,g,out)->slot` (f then g; needs `dst(f)==src(g)`; `CATEGORY_SENT
=0xFFFFFFFF` on refusal), `cat_morph_eq(f,g)->u8`; `cl_join/cl_meet(c,cp,out)->i32 (CL_OK=0)`,
`cl_le_product(c,cp)->u8`, `cl_eq(c,cp)->u8`, `cl_top(out)`. Cost vectors are `[u64;6]`. 0.3
Baseline `run_corpus FAIL=0`, `run_xii 93/0`.

## Step 1 — `676_cat_laws.iii`

`module corpus_676`; module-scope `[u8;32]` ids `OBJ_A/B/C/D/E` (distinct fills), op-words
`OP_F/G/H/K`, `OUT`/`OUT2` sinks. `main()`:
- `cat_init`; fill + `cat_add_object` for A..E (slots `sa..se`); `cat_add_morphism` for `f(A→B)`,
  `g(B→C)`, `h(C→D)`, `k(D→E)`.
- **identity law:** `idA = cat_identity(sa, OUT)`; `idB = cat_identity(sb, OUT2)`; assert
  `cat_morph_eq(cat_compose(idA, f), f)==1` (left id) and `cat_morph_eq(cat_compose(f, idB),
  f)==1` (right id).
- **4-chain associativity:** `((f∘g)∘h)∘k == f∘(g∘(h∘k))` via nested `cat_compose` + `cat_morph_eq`.
- **determinism / content-address:** `cat_compose(f,g)` twice → identical slot (composite id is a
  deterministic function of inputs).
- **prove the negative:** `cat_compose(f, h)` (`dst(f)=B ≠ src(h)=C`) `== CATEGORY_SENT`.
- distinct return code per check; `99` on pass.

## Step 2 — `677_cost_lattice_laws.iii`

`module corpus_677`; module-scope `[u64;6]` `CA/CB/CC/CO1/CO2/CO3/CU`. `main()`:
- `cl_init`; `CA=(5,10,2,3,4,1)`, `CB=(7,6,2,1,9,0)`, `CC=(2,2,8,4,1,3)` (distinct, incomparable).
- **commutativity:** `join(CA,CB)==join(CB,CA)`; `meet(CA,CB)==meet(CB,CA)` (via `cl_eq`).
- **associativity:** `join(join(CA,CB),CC)==join(CA,join(CB,CC))`; same for `meet`.
- **absorption:** `join(CA, meet(CA,CB))==CA`; `meet(CA, join(CA,CB))==CA`.
- **lub-universality:** `CO1=join(CA,CB)`; assert `le_product(CA,CO1)==1 ∧ le_product(CB,CO1)==1`
  (upper bound); build `CU = CO1` with one dim bumped (a *looser* common upper bound); assert
  `le_product(CO1,CU)==1` (join ≤ CU — least-ward) ∧ `le_product(CU,CO1)==0` (CU strictly above) —
  the join is the *tight* lub below a looser upper bound.
- **incomparability (partial, not total, order):** `le_product(CA,CB)==0 ∧ le_product(CB,CA)==0`.
- `99` on pass.

## Step 3 — register + Step 4 — combined test (one gate for the batch)

Add both `[676_cat_laws]=99` + `[677_cost_lattice_laws]=99` to `run_corpus.sh`. Then, pinned
`COMPILED/iiis-2.exe`: (1) compile-only `676` + `677` → `rc=0`. (2) `build_stdlib.sh` → `FAIL=0`,
`forge_check` green (synced-state health). (3) `run_corpus.sh` → `FAIL=0`, **both new tests `=99`**,
`620_category`/`615_cost_lattice` + the prior keystones unchanged (`PASS=397`). (4) `run_xii 93/0`.
(5) Manual hand-check: the identity law uses a real `cat_identity` arrow; the lub-universality CU
is genuinely a looser upper bound; the incomparable vectors cross in two dims.

**Single falsifier (the batch):** `676 ≠ 99` or `677 ≠ 99`, or `620`/`615` changing, or `run_xii`
regressing → red, revert, diagnose before any rebuild.

## Standards & mandates

NIH (libc + III `category`/`cost_lattice`); determinism (equality-only `cl_eq`/`cat_morph_eq`/slot
`==`; no float; `cost_lattice` is pure); W2 (each fn ≤4 params; `main` 0); W8 (`[u8;32]`/`[u64;6]`
module-scope scratch, no local arrays); W14/W15. Falsifiers present + prove-the-negative
(non-composable compose; incomparability). Apotheosis: closes M12's identity-law gap + M13's
lattice-axiom/universality gap (the additive-falsifier pattern of M3); the cross-module
unifications (every-transform-a-morphism, cost-as-SovVal-facet, coequalizer=egraph, cost-functor)
are the deferred egraph-as-XII compound.

## Roadmap

1. Steps 0–3: two corpus law-falsifiers + register.
2. Step 4: one combined gate → `676`/`677 = 99`, `FAIL=0`, `run_xii 93/0`, no regression.
