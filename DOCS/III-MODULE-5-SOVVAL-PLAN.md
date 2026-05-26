# Module 5 — the Sovereign Value (the currency): file-by-file lean implementation plan

## Gate cleared

Written only because **Module 4 (the typed gap) is verified fully + perfectly**: full gate
`PASS=389 FAIL=0`, `668_uncertainty=99` (total/sound/precise/÷0-gap/provenance/cad-addr), zero
regression. No placeholder/deferral/flaw.

## Context

**Why this change.** Module 5 of `DOCS/III-APOTHEOSIS.md` is **The Sovereign Value** — the single
currency every boundary trades: `SovVal = { payload, hexad, witness, cost }`, with a total `sv_op`
composing all four facets and returning **`Refused`** for a non-reachable hexad or an over-budget
cost. It does not exist today (values cross boundaries as raw scalars). **All four facet-modules
are now built** — payload = M4 (`uncertainty`, just shipped), hexad = M3 (`hexad_*`), witness =
M1 (`cad` content-address) / M6 (chain, later), cost = M13 (`cost_lattice`) — so the SovVal can
be assembled now as the composition of proven organs.

**Intended outcome.** Create net-new `omnia/sovval.iii`: the SovVal cell + `sv_make` (constructor,
Refuses a non-reachable hexad or over-budget cost at construction) + `sv_op` (total compose of all
four facets, Refuses likewise) + facet accessors + the exhaustive falsifier KAT. The
`@variant`/`@sovereign` **language support** (the compiler-level migration #2/#3 — the systemwide
boundary lift) is a documented hook, scoped to the compiler work; the `.iii` value + `sv_op` is
this increment.

## ADR-1 — `SovVal` cell layout (by pointer; the four facets inline)

```
ucell payload : [0..16)    (M4: tag@0 KNOWN/GAP, i64 body@8)
u16   hexad   : [16..18)   (M3, padded)
u8    status  : [18]       (SV_OK=0 | SV_REFUSED=1)
u8[5] pad     : [19..24)
u8[32] witness: [24..56)   (M1: cad content-address of the value's provenance)
u64[6] cost   : [56..104)  (M13: six-dim microarch cost vector)
```
Total 104 bytes, passed `*u8`; callers use module-scope scratch SovVal cells.

## ADR-2 — Scope: the `.iii` currency + `sv_op` now; the language/boundary lift is the compiler's

- **In scope (M5 core, net-new, buildable now):** `omnia/sovval.iii` — the cell, `sv_make`,
  `sv_op` (compose payload via M4, hexad via M3 + Refuse-if-non-reachable, cost via M13 +
  Refuse-if-over-budget, witness via M1 `cad`), accessors, the exhaustive falsifier KAT.
- **Out of scope (compiler-level, scoped — documented hooks, the systemwide lift):** `@variant`
  real codegen for `payload` (a tagged CIC sum) → **compiler / migration #2**, with the negative
  test `III_VARIANT_NONEXHAUSTIVE`; `@sovereign fn` boundary checker (rejects a raw scalar at a
  `@sovereign` boundary) → **compiler / migration #3**, with `III_NONSOVEREIGN_BOUNDARY` — this is
  the "every boundary trades only SovVals" systemwide migration (`sema`'s D-gate, the M18·D1
  machinery). `sv_op` registered as a **category morphism** (associativity = `cat_check_assoc`) →
  **M12**. Witness as a real **chain fragment** (`wh_publish`) instead of a `cad` commitment →
  **M6** integration. The SovVal-as-CIC-inductive (so Refused = a *type error* not a runtime flag)
  → **M9 + migration #2**. Same dependency-scoping as M2→M7, M3→M9, M4→M5.

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/iii/omnia/sovval.iii` | the SovVal cell + `sv_make`/`sv_op`/accessors + `sv_selftest` (the falsifier) |
| **CREATE** | `STDLIB/corpus/669_sovval.iii` | corpus wrapper (`extern sv_selftest; main → it`) |
| **MODIFY** | `STDLIB/scripts/build_stdlib.sh` | add `"omnia/sovval"` to `MODULES` (after `numera/cost_lattice` + `numera/uncertainty` + `omnia/hexad_reach` — all its facet deps must precede only for clarity; link-time resolves regardless) |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[669_sovval]=99` |

---

## Step 0 — Pre-flight (read-only)
0.1 Prefix check: `grep -rn "module omnia_sovval\|fn sv_\|SV_" STDLIB/iii` — confirm free.
0.2 Confirm exact facet signatures: `unc_apply(op:u32,a:*u8,b:*u8,out:*u8)->i32` + `unc_set_known`/
`unc_set_gap`/`unc_is_gap` (M4); `iii_hexad_compose6(a:u16,b:u16)->u16` + `iii_hexad_reachable(h:u16)
->u8` (M3); `cl_join(c:*u64,cp:*u64,out:*u64)->i32` + `cl_le_product(c:*u64,cp:*u64)->u8` +
`cl_bottom`/`cl_top` (M13); `cad_oneshot(suite:u32,msg:*u8,len:u64,out:*u8)->i32` (M1).
0.3 Corpus number: next free after `668` → expect `669`; verify.
0.4 Decide the budget ceiling for the over-K test: a fixed `SV_BUDGET` cost vector (module-scope),
e.g., `cl_top` minus headroom, or a seeded order's bound. For the KAT, a concrete budget where a
known cost is within and another exceeds.
0.5 Baseline: corpus `PASS=389`, seal.

## Step 1 — CREATE `omnia/sovval.iii`
Header: the four-facet currency over M1/M3/M4/M13; Refused = non-reachable hexad ∨ over-K cost;
`@variant`/`@sovereign` are the compiler hooks. `Hexad: kind_essence · Ring: R0 · K: 1.00 · NIH:
uncertainty + hexad_algebra + hexad_reach + cost_lattice + cad`.

### 1a. consts + externs + scratch
- externs: M4 (`unc_apply`/`unc_set_known`/`unc_set_gap`/`unc_is_gap`/`unc_known_val`),
  M3 (`iii_hexad_compose6`/`iii_hexad_reachable`), M13 (`cl_join`/`cl_le_product`/`cl_top`),
  M1 (`cad_oneshot`).
- consts: `SV_OK=0i32`, `SV_REFUSED=1i32`, offsets (`SV_OFF_PAYLOAD=0`, `SV_OFF_HEXAD=16`,
  `SV_OFF_STATUS=18`, `SV_OFF_WITNESS=24`, `SV_OFF_COST=56`), `SV_BYTES=104`,
  `SV_STATUS_OK=0u8`/`SV_STATUS_REFUSED=1u8`.
- module-scope `SV_BUDGET:[u64;6]` (the K-floor cost ceiling, set by `sv_init`).

### 1b. accessors (byte-exact, mind the typed-ptr + u32/u64 traps)
`sv_payload_ptr(sv)->*u8` (=sv+0), `sv_hexad(sv)->u16`, `sv_set_hexad`, `sv_status(sv)->u8`,
`sv_set_status`, `sv_witness_ptr(sv)->*u8` (=sv+24), `sv_cost_ptr(sv)->*u64` (=sv+56),
`sv_is_refused(sv)->u8`.

### 1c. `sv_witness_recompute(sv)` — the M1 content-address of the value's provenance
Serialize `payload(16)‖hexad(2)‖cost(48)` into a module-scope `SV_WBUF[66]` (byte-by-byte, mind
the u32/u64 store-width trap), then `cad_oneshot(SHA=0, SV_WBUF, 66, sv_witness_ptr(sv))`. The
witness facet = a content-address commitment (the full chain-fragment witness is M6's integration).

### 1d. `sv_make(payload_cell:*u8, hexad:u16, cost:*u64, out:*u8) -> i32` (4 params, W2)
1. copy `payload_cell` (16B) → out payload; set out hexad, copy cost (48B) → out cost.
2. **Refuse non-reachable hexad:** `if iii_hexad_reachable(hexad)==0u8` → set status REFUSED; return SV_REFUSED.
3. **Refuse over-budget cost:** `if cl_le_product(out_cost, &SV_BUDGET)==0u8` → status REFUSED; return SV_REFUSED.
4. else status OK; `sv_witness_recompute(out)`; return SV_OK.

### 1e. `sv_op(op:u32, a:*u8, b:*u8, out:*u8) -> i32` (4 params, W2) — total compose
1. **payload:** `unc_apply(op, sv_payload_ptr(a), sv_payload_ptr(b), sv_payload_ptr(out))` (M4 —
   total/sound/precise; gap arithmetic propagates).
2. **hexad:** `h = iii_hexad_compose6(sv_hexad(a), sv_hexad(b))`; `if iii_hexad_reachable(h)==0` →
   status REFUSED, return SV_REFUSED. else set out hexad = h. (Reachable∘reachable=reachable by
   M3 closure, so for valid inputs this never Refuses — but the gate is present + correct.)
3. **cost:** `cl_join(sv_cost_ptr(a), sv_cost_ptr(b), sv_cost_ptr(out))` (lub); `if
   cl_le_product(sv_cost_ptr(out), &SV_BUDGET)==0` → status REFUSED, return SV_REFUSED.
4. **witness + status:** status OK; `sv_witness_recompute(out)`; return SV_OK.

### 1f. `sv_selftest() -> u64` (99 = pass) — the M5 falsifier, executable
1. **sv_make OK path:** a reachable hexad (e.g. 728 all-POS) + a within-budget cost + Known
   payload → SV_OK, status OK, witness non-zero.
2. **Refuse non-reachable hexad (the catastrophe gate):** `sv_make` with a non-reachable hexad
   (e.g. a PFS bricking hexad, or pillar-0=NEG) → SV_REFUSED, status REFUSED.
3. **Refuse over-budget cost:** `sv_make` with a cost exceeding `SV_BUDGET` (set one dim above the
   ceiling) → SV_REFUSED.
4. **sv_op sound payload:** two OK SovVals, Known(7)/Known(5), `sv_op(ADD)` → out payload
   Known(12), status OK, hexad = compose6 of the two (reachable).
5. **sv_op precise gap:** one SovVal Known(0), other Gap → `sv_op(MUL)` → out payload Known(0)
   (M4 annihilator carried through the currency).
6. **sv_op cost = join, within budget → OK; over budget → Refused** (compose two whose joined
   cost exceeds the ceiling).
7. **witness determinism:** `sv_make` the same value twice → identical witness (M1).
8. **totality:** every `sv_make`/`sv_op` returns SV_OK or SV_REFUSED (never crash/raise).
`return 99u64`.

### 1g. trap audit: single-line fn; module-scope scratch (`SV_*`); equality-only; W2 (≤4 params —
`sv_make`/`sv_op` are 4); byte-by-byte u32/u64 stores in `sv_witness_recompute`; no recursion;
`SV_` prefix collision-checked; `cl_le_product`/`iii_hexad_reachable` are the two Refuse gates.

## Step 2 — CREATE `STDLIB/corpus/669_sovval.iii`
```
module corpus_669
extern @abi(c-msvc-x64) fn sv_selftest() -> u64 from "sovval.iii"
fn main() -> u64 { return sv_selftest() }
```

## Step 3 — wire `build_stdlib` (`"omnia/sovval"`) + `run_corpus` (`[669_sovval]=99`).

## Step 4 — Verify
1. compile-only `sovval.iii`; 2. `build_stdlib` FAIL=0, `omnia/sovval` OK; 3. normal-link-run
`669`=99; 4. full `run_corpus` FAIL=0, `PASS=390`, no regression; 5. manual hand-check (re-derive
the Refuse gates + the sound/precise/cost cases).

**Single falsifier:** `sv_selftest`≠99 (a constructed SovVal with a non-reachable hexad not
Refused, an over-budget composition not Refused, a non-total op, a wrong payload, a
non-deterministic witness) → red.

## Standards checklist
NIH (libc + III facet modules); determinism (no float, equality-only, the cost lattice's unsigned
compares); W2 (≤4 params via the SovVal-cell-by-pointer), W8 (bounded cell + budget), W15 (no
recursion); K=1.00; the **falsifier proves the two Refuse gates** (non-reachable hexad ∨ over-K
cost) + the carried gap-arithmetic — the M5 Final falsifier. Apotheosis: realizes M5 Final
(`{payload,hexad,witness,cost}`, total `sv_op`, `Refused`, the single currency composing
M1/M3/M4/M13). `@variant`/`@sovereign` (the systemwide boundary lift) = compiler/migration-2-3;
`sv_op`-as-morphism = M12; chain-witness = M6; SovVal-as-CIC-inductive (Refused as a *type* error)
= M9 — documented hooks.

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| 104-byte cell offset math wrong | facet cross-talk | explicit `SV_OFF_*` consts; KAT round-trips each facet before compose |
| cost facet `*u64` vs byte offset confusion | wrong cost compose | `sv_cost_ptr` returns `*u64` at byte 56 (56/8=7, 8-aligned ✓); KAT asserts join result |
| witness serialization u32/u64 store-width trap | non-deterministic witness | byte-by-byte stores into `SV_WBUF`; KAT asserts determinism |
| `SV_BUDGET` chosen so nothing/everything Refuses | vacuous over-K test | pick a budget where one KAT cost is ≤ and another exceeds exactly one dim |
| Refuse-hexad path unreachable (closure) | the gate looks dead | test it via `sv_make` (constructor) with a non-reachable hexad — the real trigger |

## Roadmap
1. Steps 0–3: net-new `sovval.iii` + KAT + register → `669=99`, `FAIL=0`, `PASS=390`. (The
   currency, assembled from the four proven facets, with both Refuse gates proven.)
Then M5's systemwide completions land with their owning work: `@variant`/`@sovereign` + the
boundary migration (compiler, mig 2/3), `sv_op`-as-morphism (M12), chain-witness (M6),
SovVal-as-CIC-inductive (M9).
