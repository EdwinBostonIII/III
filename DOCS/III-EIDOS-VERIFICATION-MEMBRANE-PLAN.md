# EIDOS Verification Membrane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the fixture-locked / narrow Seraphyte verification organs (`ser_kinduct`, `ser_tgraph`, `ser_intent`, `ser_antiunify`, `ser_kinduct_sym`, `ser_cascade`) into **parametric engines** that take the caller's own problem, then wire them — with the already-general organs (`ser_causal`, `ser_egraph`, `ser_absint`, `ser_petri`, `ser_cegis`, `bv_ring`, `bv_bits`) — into **one autonomous, event-driven verification membrane** that folds over the EIDOS witnessed bus, each organ's verdict a ripple the next consumes, gating the real apply path.

**Architecture:** A 5-layer membrane. (1) **Problem layer** — content-addressed problem descriptors (FSM transition tables, `temporal_logic` formula handles, op-sequences, rewrite descriptors) live on `eidos/field` + `omnia/isub`. (2) **Organ layer** — every verifier exposes a parametric API (`reset → register problem → verdict`); no hardcoded fixture. (3) **Bus layer** — organs communicate only via witnessed ripples on `eidos_field`/`isub`; state is a fold over the log. (4) **Driver layer** — `ser_verify` folds the request queue cheap→expensive (absint O(1) → petri concrete → causal-collapse → kinduct/bv symbolic) until dry. (5) **Apply layer** — the membrane's verdict gates rule-acceptance in the reseal/`cg_r3` path, byte-exact rollback, the same standing-certifier discipline as the strength reductions.

**Tech Stack:** III (`.iii`), self-hosted `iiis-2`; `bv_ring`/`bv_bits` (algebraic + SAT engines); `forcefield/cg_autocatalyst` (CIC kernel `tc_check`); `numera/temporal_logic` (general LTL: `tl_append_atom/not/bin/unary_temp`, `tl_trace_eval/holds`); EIDOS substrate `eidos/field` (`field_record/mark/rewind/branch/provenance/temporal_witness`), `omnia/isub` (`isub_emit/verb/a/b/witness_into`), `eidos/ripple`; build via `STDLIB/scripts/build_stdlib.sh`; gate via `STDLIB/scripts/run_corpus.sh` + `cor_selftest`.

## Global Constraints

- **no-ML / no-observational:** search direction is a function of the CANDIDATE, never of cross-run history. Seeded search (Grace-seed) is allowed; counting-and-promoting is not.
- **no-island:** every new organ NAMES an existing consumer; the membrane is consumed by `ser_verify` (the driver) and ultimately the reseal apply path. No organ lands consumed only by its own KAT.
- **determinism:** integer-only; all witnesses content-addressed (`isub`/`field` Merkle). Same input + same seed ⇒ same witness root.
- **the value bar:** an organ is "working" only when it takes the CALLER's problem and returns a real verdict, proven by a KAT whose negative arm (teeth) bites. "Runs the hardcoded example" is NOT working.
- **prove, then apply:** no membrane verdict authorizes an apply unless a symbolic engine (`bv_ring`/`bv_bits`/`tc_check`/k-induction) discharged it. The concrete membrane (`petri`) is a REFUTER only.
- **gospel scale:** never down-scale (e.g. shrink state caps to dodge a BSS limit). If a bound is hit, `log()` it.
- Each task ends GREEN: its KAT at the asserted exit code, `build_stdlib.sh` FAIL=0, carto GATE PASS, `cor_selftest`=99, then commit (source-only; binaries regenerate).

---

## File Structure

**New organs (parametric engines + the bus + the driver):**
- `STDLIB/iii/numera/ser_fsm.iii` — `sfsm_*`: the shared parametric FSM substrate (states, transitions, invariant-as-state-set). Consumed by the generalized `ser_kinduct`.
- `STDLIB/iii/numera/ser_vbus.iii` — `vb_*`: the EIDOS verification bus (request/verdict ripples on `eidos/field`+`isub`; the shared problem registry; the fold).
- `STDLIB/iii/numera/ser_verify.iii` — `vrf_*`: the autonomous driver — folds the request queue cheap→expensive to a witnessed verdict, loop-until-dry.

**Generalized organs (each gains a parametric API; the old fixture becomes one registered instance in its KAT):**
- `STDLIB/iii/numera/ser_kinduct.iii` — add `ski_reset/ski_set_nstates/ski_add_trans/ski_set_inv/ski_set_init/ski_base_g/ski_inductive_g/ski_universal_g` (table-driven). Keep the old mutex fns (now built on the table).
- `STDLIB/iii/numera/ser_tgraph.iii` — add `stg_check(formula, len)` taking a caller-built `temporal_logic` formula handle. Keep `stg_build` (the mutex formula) as one instance.
- `STDLIB/iii/numera/ser_intent.iii` — add `in_propose_proven(handle, lhs_node, rhs_node)` taking an `ser_egraph` node pair, merging on a `bv_ring` proof (any rewrite, not only shl-sub).
- `STDLIB/iii/numera/ser_antiunify.iii` — add `au_generalize_open(v0,v1,v2)` returning a discovered shift-mask family (not only subk/shladd).
- `STDLIB/iii/numera/ser_kinduct_sym.iii` — add `sks_pres(inv_kind, inc)` taking the invariant kind (even/odd/mod-k), not only even.
- `STDLIB/iii/numera/ser_cascade.iii` — add `casc_register_family(form, seed)` registering any proven family (not only subk).

**Collaboration wiring (the membrane composes the organs through the bus):**
- `STDLIB/iii/numera/ser_causal.iii` — add `caus_collapse_fsm(fsm)` that proves which FSM transitions commute and emits a reduced transition set to `ser_fsm` (state-space reduction feeding `ser_kinduct`).

**KATs (one per task, the gate + teeth):**
- `STDLIB/corpus/2039_eidos_fsm.iii` … `2047_eidos_membrane.iii` (one per phase task, registered in `run_corpus.sh` EXPECTED).

**Standing certifier + apply integration:**
- `STDLIB/iii/forcefield/cg_opt_rules.iii` — extend `cor_selftest` with `cor_vm_selftest()` that re-proves the membrane's soundness obligations every build.
- `STDLIB/scripts/seraphyte_reseal_driver.sh` — STEP 4 ACCEPT additionally requires `vrf_membrane()==99` (the membrane gates the apply).
- `STDLIB/scripts/build_stdlib.sh` — register the new modules in MODULES.

---

## Phase 0 — The shared parametric FSM substrate (`ser_fsm`)

The root cause of `ser_kinduct` being fixture-locked is that `ski_succ` hardcodes the mutex transition relation. Extract the transition relation into a caller-registered table so ANY FSM can be verified.

### Task 0.1: `ser_fsm` — a registerable finite-state transition system

**Files:**
- Create: `STDLIB/iii/numera/ser_fsm.iii`
- Test: `STDLIB/corpus/2039_eidos_fsm.iii`
- Modify: `STDLIB/scripts/build_stdlib.sh` (MODULES += `"numera/ser_fsm"`), `STDLIB/scripts/run_corpus.sh` (`[2039_eidos_fsm]=99`)

**Interfaces:**
- Produces: `sfsm_reset() -> i32`; `sfsm_set_n(n: u32) -> i32` (state count, ≤ 256); `sfsm_add_trans(from: u32, to: u32) -> i32` (a directed edge; the "move" is the edge index); `sfsm_set_inv(s: u32, holds: u8) -> i32` (invariant as a state→bool table); `sfsm_set_init(s: u32, is_init: u8) -> i32`; `sfsm_n() -> u32`; `sfsm_trans_n() -> u32`; `sfsm_trans_from(e: u32) -> u32`; `sfsm_trans_to(e: u32) -> u32`; `sfsm_inv(s: u32) -> u8`; `sfsm_init(s: u32) -> u8`.
- Consumed by: `ser_kinduct` (Phase 1), `ser_causal` (Phase 3).

- [ ] **Step 1: Write the failing KAT** `STDLIB/corpus/2039_eidos_fsm.iii`

```
/* 2039 -- the parametric FSM substrate: register an arbitrary transition system, read it back. 99 = all. */
module corpus_2039_eidos_fsm
extern @abi(c-msvc-x64) fn sfsm_reset() -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_set_n(n: u32) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_add_trans(src: u32, to: u32) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_set_inv(s: u32, holds: u8) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_set_init(s: u32, is_init: u8) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_n() -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_trans_n() -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_trans_to(e: u32) -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_inv(s: u32) -> u8 from "ser_fsm.iii"
fn main() -> u64 {
    sfsm_reset()
    sfsm_set_n(4u32)
    sfsm_add_trans(0u32, 1u32)
    sfsm_add_trans(1u32, 2u32)
    sfsm_set_inv(0u32, 1u8)  sfsm_set_inv(3u32, 1u8)
    sfsm_set_init(0u32, 1u8)
    if sfsm_n() != 4u32 { return 1u64 }
    if sfsm_trans_n() != 2u32 { return 2u64 }
    if sfsm_trans_to(0u32) != 1u32 { return 3u64 }
    if sfsm_inv(0u32) != 1u8 { return 4u64 }
    if sfsm_inv(1u32) != 0u8 { return 5u64 }   /* TEETH: unset state has no invariant */
    return 99u64
}
```

- [ ] **Step 2: Run it; verify it fails to link** (`ser_fsm` not built):
  `"$IIIS" STDLIB/corpus/2039_eidos_fsm.iii --compile-only --out /tmp/k.o && gcc /tmp/k.o "$LIB" -lkernel32 -o /tmp/k.exe` → Expected: link error `undefined reference to sfsm_reset`.

- [ ] **Step 3: Implement `ser_fsm.iii`** — module-scope arrays (W4: no fn-local var arrays), runtime-index reads/writes on module arrays only:

```
module numera_ser_fsm
const SFSM_MAXS : u32 = 256u32
const SFSM_MAXE : u32 = 2048u32
var SFSM_N    : [u32; 1]
var SFSM_EN   : [u32; 1]
var SFSM_TF   : [u32; 2048]
var SFSM_TT   : [u32; 2048]
var SFSM_INV  : [u8; 256]
var SFSM_INIT : [u8; 256]
fn sfsm_reset() -> i32 @export {
    SFSM_N[0u64] = 0u32  SFSM_EN[0u64] = 0u32
    let mut i : u32 = 0u32
    while i < SFSM_MAXS { SFSM_INV[i as u64] = 0u8  SFSM_INIT[i as u64] = 0u8  i = i + 1u32 }
    return 0i32
}
fn sfsm_set_n(n: u32) -> i32 @export { if n > SFSM_MAXS { return -1i32 }  SFSM_N[0u64] = n  return 0i32 }
fn sfsm_add_trans(src: u32, to: u32) -> i32 @export {
    let e : u32 = SFSM_EN[0u64]
    if e >= SFSM_MAXE { return -1i32 }
    SFSM_TF[e as u64] = from  SFSM_TT[e as u64] = to  SFSM_EN[0u64] = e + 1u32  return 0i32
}
fn sfsm_set_inv(s: u32, holds: u8) -> i32 @export { if s >= SFSM_MAXS { return -1i32 }  SFSM_INV[s as u64] = holds  return 0i32 }
fn sfsm_set_init(s: u32, is_init: u8) -> i32 @export { if s >= SFSM_MAXS { return -1i32 }  SFSM_INIT[s as u64] = is_init  return 0i32 }
fn sfsm_n() -> u32 @export { return SFSM_N[0u64] }
fn sfsm_trans_n() -> u32 @export { return SFSM_EN[0u64] }
fn sfsm_trans_from(e: u32) -> u32 @export { if e >= SFSM_EN[0u64] { return 0u32 }  return SFSM_TF[e as u64] }
fn sfsm_trans_to(e: u32) -> u32 @export { if e >= SFSM_EN[0u64] { return 0u32 }  return SFSM_TT[e as u64] }
fn sfsm_inv(s: u32) -> u8 @export { if s >= SFSM_MAXS { return 0u8 }  return SFSM_INV[s as u64] }
fn sfsm_init(s: u32) -> u8 @export { if s >= SFSM_MAXS { return 0u8 }  return SFSM_INIT[s as u64] }
```

- [ ] **Step 4: Register + build + run.** Add `"numera/ser_fsm"` to MODULES in `build_stdlib.sh` and `[2039_eidos_fsm]=99` to `run_corpus.sh`. Run `bash STDLIB/scripts/build_stdlib.sh`; expect carto GATE PASS, FAIL=0. Compile+run 2039 via pinned `iiis-2`; Expected: `99`.

- [ ] **Step 5: Commit**
  `git add STDLIB/iii/numera/ser_fsm.iii STDLIB/corpus/2039_eidos_fsm.iii STDLIB/scripts/build_stdlib.sh STDLIB/scripts/run_corpus.sh && git commit -m "III EIDOS-VM — ser_fsm: the parametric FSM substrate"`

---

## Phase 1 — Generalize the temporal sieve + membrane

### Task 1.1: `ser_kinduct` — table-driven k-induction over `ser_fsm`

**Files:**
- Modify: `STDLIB/iii/numera/ser_kinduct.iii` (add the generalized fns; refactor the mutex to register itself into `ser_fsm`)
- Test: `STDLIB/corpus/2040_eidos_kinduct_general.iii`
- Modify: `run_corpus.sh` (`[2040_eidos_kinduct_general]=99`)

**Interfaces:**
- Consumes: `sfsm_*` (Task 0.1).
- Produces: `ski_base_g() -> u32` (1 iff every init state satisfies the invariant); `ski_inductive_g() -> u32` (1 iff every transition preserves the invariant over the registered FSM); `ski_universal_g() -> u32` (`ski_base_g() & ski_inductive_g()`).

- [ ] **Step 1: Write the failing KAT** `2040_eidos_kinduct_general.iii` — register TWO different FSMs through `ser_fsm` and k-induct each; plus a teeth arm where the invariant is not inductive:

```
module corpus_2040_eidos_kinduct_general
extern @abi(c-msvc-x64) fn sfsm_reset() -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_set_n(n: u32) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_add_trans(src: u32, to: u32) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_set_inv(s: u32, holds: u8) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_set_init(s: u32, is_init: u8) -> i32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn ski_base_g() -> u32 from "ser_kinduct.iii"
extern @abi(c-msvc-x64) fn ski_inductive_g() -> u32 from "ser_kinduct.iii"
extern @abi(c-msvc-x64) fn ski_universal_g() -> u32 from "ser_kinduct.iii"
/* FSM A: states {0,1,2}; invariant = {0,2} (NOT inductive: 0->1 leaves the invariant). */
fn build_a() -> i32 { sfsm_reset() sfsm_set_n(3u32) sfsm_add_trans(0u32,1u32) sfsm_add_trans(1u32,2u32)
    sfsm_set_inv(0u32,1u8) sfsm_set_inv(2u32,1u8) sfsm_set_init(0u32,1u8) return 0i32 }
/* FSM B: a 2-cycle {0<->1}; invariant = {0,1} (inductive). */
fn build_b() -> i32 { sfsm_reset() sfsm_set_n(2u32) sfsm_add_trans(0u32,1u32) sfsm_add_trans(1u32,0u32)
    sfsm_set_inv(0u32,1u8) sfsm_set_inv(1u32,1u8) sfsm_set_init(0u32,1u8) return 0i32 }
fn main() -> u64 {
    build_a()
    if ski_base_g() != 1u32 { return 1u64 }          /* init 0 satisfies inv */
    if ski_inductive_g() != 0u32 { return 2u64 }     /* TEETH: 0->1 breaks it -> NOT inductive */
    if ski_universal_g() != 0u32 { return 3u64 }
    build_b()
    if ski_universal_g() != 1u32 { return 4u64 }     /* the 2-cycle invariant IS inductive */
    return 99u64
}
```

- [ ] **Step 2: Run; verify FAIL** (`ski_universal_g` undefined). Expected: link error.

- [ ] **Step 3: Implement the generalized fns** in `ser_kinduct.iii` (append; extern `sfsm_*`):

```
extern @abi(c-msvc-x64) fn sfsm_n() -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_trans_n() -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_trans_from(e: u32) -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_trans_to(e: u32) -> u32 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_inv(s: u32) -> u8 from "ser_fsm.iii"
extern @abi(c-msvc-x64) fn sfsm_init(s: u32) -> u8 from "ser_fsm.iii"
/* BASE: every init state satisfies the invariant. */
fn ski_base_g() -> u32 @export {
    let n : u32 = sfsm_n()
    let mut s : u32 = 0u32
    while s < n { if sfsm_init(s) == 1u8 { if sfsm_inv(s) != 1u8 { return 0u32 } }  s = s + 1u32 }
    return 1u32
}
/* INDUCTIVE STEP: every edge out of an invariant-state lands in an invariant-state. */
fn ski_inductive_g() -> u32 @export {
    let m : u32 = sfsm_trans_n()
    let mut e : u32 = 0u32
    while e < m {
        let f : u32 = sfsm_trans_from(e)
        if sfsm_inv(f) == 1u8 { if sfsm_inv(sfsm_trans_to(e)) != 1u8 { return 0u32 } }
        e = e + 1u32
    }
    return 1u32
}
fn ski_universal_g() -> u32 @export {
    if ski_base_g() != 1u32 { return 0u32 }
    if ski_inductive_g() != 1u32 { return 0u32 }
    return 1u32
}
```

- [ ] **Step 4: Refactor the mutex (`ski_succ`/`ski_inv`) to a registered instance** — in the EXISTING `sa_selftest`/`ski_universal` path, register the mutex into `ser_fsm` (8 states, the 4 moves expanded to edges, the strengthened invariant as a state set) and call `ski_universal_g()`. Verify the legacy KAT `2031_seraphyte_kinduct` still returns 99 (the mutex proof now runs on the general engine). Run 2031; Expected: `99`.

- [ ] **Step 5: Build + run 2040.** `build_stdlib.sh` green; 2040 via pinned `iiis-2`; Expected: `99`.

- [ ] **Step 6: Commit** `git commit -m "III EIDOS-VM — ser_kinduct: table-driven k-induction over any registered FSM"`

### Task 1.2: `ser_tgraph` — caller-supplied LTL formula

**Files:** Modify `ser_tgraph.iii`; Test `STDLIB/corpus/2041_eidos_tgraph_general.iii`; `run_corpus.sh`.

**Interfaces:**
- Consumes: `numera/temporal_logic` (`tl_alloc_formula/tl_append_*/tl_set_root/tl_trace_set/tl_trace_eval/tl_trace_holds`).
- Produces: `stg_check(formula: u32, len: u64) -> u8` — evaluate the caller's trace (already set via `tl_trace_set`) against the caller's formula handle, return `tl_trace_holds`.

- [ ] **Step 1: Failing KAT** `2041` — build TWO different formulas via `temporal_logic` (e.g. `G A` and `F B`), set a trace, assert `stg_check` distinguishes them (one holds, one doesn't = teeth):

```
module corpus_2041_eidos_tgraph_general
extern @abi(c-msvc-x64) fn tl_init() -> i32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_alloc_formula() -> u32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_append_atom(f: u32, id: u32) -> u32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_append_unary_temp(f: u32, op: u32, a: u32) -> u32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_set_root(f: u32, r: u32) -> i32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_trace_set(atom_node: u64, pos: u64, truth: u8) -> i32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn stg_check(formula: u32, len: u64) -> u8 from "ser_tgraph.iii"
const TL_ALWAYS : u32 = 6u32
const TL_EVENT  : u32 = 7u32
fn main() -> u64 {
    tl_init()
    let f : u32 = tl_alloc_formula()
    let a : u32 = tl_append_atom(f, 0u32)
    let ga : u32 = tl_append_unary_temp(f, TL_ALWAYS, a)   /* G A */
    tl_set_root(f, ga)
    /* trace: A true at 0,1 but FALSE at 2 -> G A must be false */
    tl_trace_set(a as u64, 0u64, 1u8)  tl_trace_set(a as u64, 1u64, 1u8)  tl_trace_set(a as u64, 2u64, 0u8)
    if stg_check(f, 3u64) != 0u8 { return 1u64 }           /* TEETH: G A is violated at t=2 */
    let g2 : u32 = tl_alloc_formula()
    let b : u32 = tl_append_atom(g2, 0u32)
    let fb : u32 = tl_append_unary_temp(g2, TL_EVENT, b)   /* F B */
    tl_set_root(g2, fb)
    tl_trace_set(b as u64, 0u64, 0u8)  tl_trace_set(b as u64, 1u64, 1u8)  tl_trace_set(b as u64, 2u64, 0u8)
    if stg_check(g2, 3u64) != 1u8 { return 2u64 }          /* F B holds (B true at t=1) */
    return 99u64
}
```

- [ ] **Step 2: Run; verify FAIL** (`stg_check` undefined).

- [ ] **Step 3: Implement** in `ser_tgraph.iii`:

```
extern @abi(c-msvc-x64) fn tl_trace_eval(f: u32, len: u64) -> i32 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_trace_holds(root_node: u64, pos: u64) -> u8 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn tl_root_of(f: u32) -> u32 from "temporal_logic.iii"   /* if absent, add it to temporal_logic */
/* parametric BMC membrane: evaluate ANY caller formula against the caller's trace. */
fn stg_check(formula: u32, len: u64) -> u8 @export {
    tl_trace_eval(formula, len)
    return tl_trace_holds(tl_root_of(formula) as u64, 0u64)
}
```

  If `tl_root_of` does not exist in `temporal_logic.iii`, add it (one line: return the stored root node id for formula `f`) as a sub-step, with its own one-line KAT assertion folded into 2041.

- [ ] **Step 4: Build + run 2041; re-run legacy `2030_seraphyte_tgraph` (must stay 99 — re-point `stg_aligned` to `stg_check(STG_F[0], len)`).** Expected: `99`, `99`.

- [ ] **Step 5: Commit** `git commit -m "III EIDOS-VM — ser_tgraph: BMC over any caller-built LTL formula"`

---

## Phase 2 — Generalize the narrow organs

### Task 2.1: `ser_kinduct_sym` — parametric invariant kind

**Files:** Modify `ser_kinduct_sym.iii`; Test `2042_eidos_ksym_general.iii`; `run_corpus.sh`.

**Interfaces:** Produces `sks_pres(inv_kind: u32, inc: u64) -> u8` — 1 iff `x+inc` preserves invariant `inv_kind` for all x (kind 0 = even, 1 = odd-preserving-under-+2, 2 = divisible-by-4). Proven by `bv_bits` over the low bits.

- [ ] **Step 1: Failing KAT** `2042` — assert `sks_pres(0, 2)==1` (even preserved by +2), `sks_pres(0,1)==0` (teeth: +1 breaks even), `sks_pres(2,4)==1` (mod-4 preserved by +4), `sks_pres(2,2)==0` (teeth). Return 99.
- [ ] **Step 2: Run; FAIL.**
- [ ] **Step 3: Implement** `sks_pres(inv_kind, inc)` — for kind 0 use mask `1`, kind 2 use mask `3`; assert via `bv_bits` that `(x+inc) & mask == x & mask` for all 64-bit x (the miter `((x+inc)&mask) ^ (x&mask)` is UNSAT iff `inc & mask == 0`). Keep `sks_pres_even(inc)` = `sks_pres(0, inc)`.
- [ ] **Step 4: Build + run 2042 + legacy `2034_seraphyte_kinduct_sym` (99).**
- [ ] **Step 5: Commit** `git commit -m "III EIDOS-VM — ser_kinduct_sym: parametric invariant kind"`

### Task 2.2: `ser_intent` — proof-gated merge of ANY rewrite (egraph-backed)

**Files:** Modify `ser_intent.iii` (consume `ser_egraph` + `bv_ring`); Test `2043_eidos_intent_general.iii`; `run_corpus.sh`.

**Interfaces:** Consumes `seg_*` (`ser_egraph`), `bv_*` (`bv_ring`). Produces `in_propose_proven(handle: u64, lhs: u64, rhs: u64) -> u32` — `lhs`/`rhs` are `ser_egraph` node ids (built from `seg_var/seg_const/seg_intern`); merge the e-classes (return 1) iff `bv_ring` proves `lhs == rhs` over Z/2⁶⁴, else 0 (no merge). Generalizes `in_propose_shlsub`.

- [ ] **Step 1: Failing KAT** `2043` — declare a contract; propose a PROVEN rewrite `(x<<3)-x == x*7` via egraph nodes → merge (1); propose a FALSE rewrite `(x<<4)-x == x*7` → no merge (0, teeth); a DIFFERENT proven rewrite `(x<<1)+x == x*3` → merge (1, proving generality beyond shl-sub-for-one-factor). Return 99.
- [ ] **Step 2: Run; FAIL.**
- [ ] **Step 3: Implement** `in_propose_proven` — translate the two egraph nodes to `bv_ring` expressions via a small evaluator (the egraph already stores `op,a,b`; walk it building `bv_*` calls), `bv_equal`; on proof `seg_union(lhs,rhs)` + record the merge ripple, return 1; else return 0.
- [ ] **Step 4: Build + run 2043 + legacy `2026_seraphyte_intent` (99).**
- [ ] **Step 5: Commit** `git commit -m "III EIDOS-VM — ser_intent: merge ANY rewrite the ring proves, via the e-graph"`

### Task 2.3: `ser_antiunify` — open-family generalization

**Files:** Modify `ser_antiunify.iii`; Test `2044_eidos_au_open.iii`; `run_corpus.sh`.

**Interfaces:** Produces `au_generalize_open(v0: u64, v1: u64, v2: u64) -> u32` — returns a packed family descriptor `{kind, param}` discovered from the three instances by structural anti-unification (e.g. all three are `2^k±1` ⇒ the ±1 family; all three popcount-2 ⇒ the 2-shift family), or `CG_NONE` if no common structure. Not limited to the two hardcoded families.

- [ ] **Step 1: Failing KAT** `2044` — `au_generalize_open(7,15,31)` ⇒ the subk family; `au_generalize_open(6,10,12)` ⇒ the 2-shift family; `au_generalize_open(7,10,13)` ⇒ `CG_NONE` (no common structure; teeth). Return 99.
- [ ] **Step 2: Run; FAIL.**
- [ ] **Step 3: Implement** the structural matcher (popcount + run-shape classification, sharing the predicates from `cg_opt_rules`).
- [ ] **Step 4: Build + run 2044 + legacy `2020_seraphyte_antiunify` (99).**
- [ ] **Step 5: Commit** `git commit -m "III EIDOS-VM — ser_antiunify: open-family structural generalization"`

### Task 2.4: `ser_cascade` — register ANY proven family

**Files:** Modify `ser_cascade.iii`; Test `2045_eidos_cascade_family.iii`; `run_corpus.sh`.

**Interfaces:** Produces `casc_register_family(form: u32, seed: u64) -> u8` (form 0=pow2,1=shladd,2=subk,3=2-add,4=2-sub) registering the named proven family; `casc_site_covered`/`casc_cost` then answer for whichever families are registered.

- [ ] **Step 1: Failing KAT** `2045` — register form 3 (2-add) and form 4 (2-sub); assert `casc_site_covered(10)==1` (2-add), `casc_site_covered(14)==1` (2-sub), `casc_site_covered(11)==0` (neither; teeth). Return 99.
- [ ] **Step 2–5:** implement (delegate coverage to the `cgopt_mul_*_admit` predicates per registered form), build, run 2045 + legacy `2022_seraphyte_cascade` (99), commit.

---

## Phase 3 — The collaboration: causal-collapse feeds the sieve

### Task 3.1: `ser_causal` — collapse commuting FSM transitions into epochs

**Files:** Modify `ser_causal.iii` (consume `ser_fsm`); Test `2046_eidos_causal_collapse.iii`; `run_corpus.sh`.

**Interfaces:** Consumes `sfsm_*`, `bv_ring`. Produces `caus_collapse_fsm() -> u32` — for the registered FSM, prove (via `caus_commute` over the edge-labeled operations) which transition pairs commute; emit the quotient (one representative edge per commuting class) back into `ser_fsm` as a reduced edge set; return the number of edges eliminated. This is the O(N!)→O(epochs) reduction that shrinks the work `ski_inductive_g` must do.

- [ ] **Step 1: Failing KAT** `2046` — register an FSM whose moves are two commuting register-updates (`+3`, `+5`) interleaved; `caus_collapse_fsm()` returns >0 (edges eliminated); `ski_universal_g()` on the collapsed FSM == on the full FSM (collapse is sound: same verdict, fewer edges). Teeth: an FSM whose moves do NOT commute (`+3`, `<<2`) ⇒ `caus_collapse_fsm()` returns 0 (nothing collapsed). Return 99.
- [ ] **Step 2: Run; FAIL.**
- [ ] **Step 3: Implement** — for each edge pair, map the edge's state-delta to a `caus_commute(opA,argA,opB,argB)` query; if it returns 1, mark the later edge redundant; rewrite `ser_fsm`'s edge table to the survivors; return the count removed. (Soundness: collapsing only commuting transitions preserves reachability, so the invariant's inductiveness is unchanged — asserted by the equal-verdict arm.)
- [ ] **Step 4: Build + run 2046 + legacy `2032_seraphyte_causal` (99).**
- [ ] **Step 5: Commit** `git commit -m "III EIDOS-VM — ser_causal: commuting-transition collapse feeding the k-induction sieve"`

---

## Phase 4 — The EIDOS verification bus + the autonomous driver

### Task 4.1: `ser_vbus` — request/verdict ripples on the witnessed substrate

**Files:** Create `ser_vbus.iii`; Test `2047_eidos_vbus.iii`; `build_stdlib.sh` MODULES; `run_corpus.sh`.

**Interfaces:** Consumes `eidos/field` (`field_reset/field_record/field_event_count/field_temporal_witness`), `omnia/isub`. Produces `vb_reset() -> i32`; `vb_request(kind: u32, a: u64, b: u64) -> u64` (enqueue a verification request as a witnessed ripple — kind 0=algebraic-eq, 1=temporal-invariant, 2=commute; returns the request id); `vb_verdict(req: u64, outcome: u32) -> u64` (record the verdict ripple — outcome 1=PROVEN,0=REFUTED,2=DEFER); `vb_pending() -> u32` (fold: requests without a verdict); `vb_outcome(req: u64) -> u32`; `vb_witness() -> u64` (the content-addressed fold root).

- [ ] **Step 1: Failing KAT** `2047` — `vb_request` two problems; `vb_pending()==2`; `vb_verdict` one PROVEN; `vb_pending()==1`; `vb_outcome` of the verdicted one ==1; `vb_witness()!=0`; replay (same requests) ⇒ same witness (determinism); teeth: `vb_outcome` of an un-verdicted req == DEFER(2). Return 99.
- [ ] **Step 2–5:** implement (state = fold over `field`/`isub`; no stored counters), build, run, commit `git commit -m "III EIDOS-VM — ser_vbus: the witnessed verification request/verdict bus"`.

### Task 4.2: `ser_verify` — the autonomous cheap→expensive fold

**Files:** Create `ser_verify.iii`; Test `2048_eidos_verify_driver.iii`; `build_stdlib.sh`; `run_corpus.sh`.

**Interfaces:** Consumes `ser_vbus`, `ser_absint` (`ai_decide`), `ser_petri` (`sp_membrane`), `ser_causal` (`caus_collapse_fsm`), `ser_kinduct` (`ski_universal_g`), `bv_ring`/`bv_bits`. Produces `vrf_membrane() -> u64` — drain `vb_pending()` requests, routing each cheap→expensive: O(1) `ai_decide` → if DEFER, concrete `sp_membrane` (REFUTE-only) → if survives, symbolic sieve (`bv_ring`/`bv_bits` for algebraic, causal-collapse + `ski_universal_g` for temporal); write each verdict back via `vb_verdict`; loop until `vb_pending()==0`; return 99 iff every request reached a symbolic verdict and no REFUTED candidate was passed.

- [ ] **Step 1: Failing KAT** `2048` — enqueue a mix: a true algebraic eq `(x<<3)-x==x*7`, a false one `(x<<4)-x==x*7`, a temporal invariant (the 2-cycle FSM from 2040). Assert `vrf_membrane()==99`; the true ones PROVEN, the false REFUTED (teeth: a mutant `vrf_membrane` that skips the symbolic sieve passes the false one ⇒ KAT RED). Assert the abstract pre-decided ≥1 without the solver (the prune fired). Return 99.
- [ ] **Step 2: Run; FAIL.**
- [ ] **Step 3: Implement** `vrf_membrane` — the routing fold:

```
fn vrf_membrane() -> u64 @export {
    let mut guard : u32 = 0u32
    while vb_pending() > 0u32 {
        if guard > 4096u32 { return 50u64 }            /* loop-until-dry backstop (logged) */
        let req : u64 = vb_next_pending()              /* from ser_vbus */
        let kind : u32 = vb_kind(req)
        let a : u64 = vb_a(req)  let b : u64 = vb_b(req)
        let mut outcome : u32 = 2u32                   /* DEFER */
        if kind == 0u32 {                              /* algebraic equality a==b as packed exprs */
            let d : u32 = ai_decide_packed(a, b)       /* O(1) abstract */
            if d == 1u32 { outcome = 1u32 }
            if d == 0u32 { outcome = 0u32 }
            if d == 2u32 {                             /* DEFER -> concrete membrane, then symbolic */
                if sp_membrane_packed(a, b) == 0u32 { outcome = 0u32 }
                else { outcome = bv_prove_packed(a, b) }   /* the symbolic sieve = the WARRANT */
            }
        }
        if kind == 1u32 {                              /* temporal invariant over a registered FSM */
            caus_collapse_fsm()                        /* reduce the interleaving first */
            if ski_universal_g() == 1u32 { outcome = 1u32 } else { outcome = 0u32 }
        }
        if kind == 2u32 { outcome = caus_commute_packed(a, b) as u32 }
        vb_verdict(req, outcome)
        guard = guard + 1u32
    }
    return 99u64
}
```

  (`vb_next_pending`, `vb_kind`, `vb_a`, `vb_b`, and the `*_packed` adapters are added in this task with their own KAT assertions folded into 2048.)

- [ ] **Step 4: Build + run 2048.** Expected: `99`. Then the teeth mutant (a copy with the `bv_prove_packed` line replaced by `outcome = 1`) ⇒ run ⇒ NOT 99.
- [ ] **Step 5: Commit** `git commit -m "III EIDOS-VM — ser_verify: the autonomous cheap->expensive verification fold"`

---

## Phase 5 — Integration with the ripple/Seraphyte/EIDOS apply path

### Task 5.1: the membrane gates the reseal ACCEPT

**Files:** Modify `STDLIB/scripts/seraphyte_reseal_driver.sh` (STEP 4); no new module.

**Interfaces:** The driver's `svp_run` helper (already present) gains a call to `vrf_membrane()`.

- [ ] **Step 1:** In STEP 4, after the existing fixpoint+cert+pipeline gates, add: build a tiny main that enqueues the rewrite-under-test as a `vb_request(kind=0, lhs_packed, rhs_packed)` and runs `vrf_membrane()`; require `==99` for ACCEPT.
- [ ] **Step 2:** Run `bash seraphyte_reseal_driver.sh --eidos-proof`; Expected: exit 0 with a new line `membrane: vrf_membrane=99 (abstract-pruned, concrete-fuzzed, symbolically proven)`.
- [ ] **Step 3:** Run the FULL driver (rule-absent baseline) once; Expected: rc=0, the membrane verdict appears in the ACCEPT, byte-exact rollback on the unsound STEP-5 arm. (If un-runnable this session, log it — do NOT mark done.)
- [ ] **Step 4: Commit** `git commit -m "III EIDOS-VM — the verification membrane gates the reseal ACCEPT"`

### Task 5.2: the standing certifier re-proves the membrane every build

**Files:** Modify `STDLIB/iii/forcefield/cg_opt_rules.iii` (add `cor_vm_selftest` + wire into `cor_selftest`); Test fold into `2048`.

**Interfaces:** Produces `cor_vm_selftest() -> u64` — re-runs a fixed battery: a known-true algebraic eq must be PROVEN by `vrf_membrane`, a known-false REFUTED, and the abstract/concrete/symbolic stages each demonstrably load-bearing (drop each ⇒ a different verdict). Wired as the final check in `cor_selftest` (returns its code on failure).

- [ ] **Step 1–5:** failing assertion → implement → `cor_selftest`=99 with the membrane battery → `build_stdlib.sh` green (carto PASS, FAIL=0, under-proven within pin — add membrane-export coverage to 2048) → commit `git commit -m "III EIDOS-VM — cor_vm_selftest: the membrane re-certified every build"`.

---

## Phase 6 — The unified KAT, calibration, and honest scope

### Task 6.1: one end-to-end membrane KAT + the executed-output proof

**Files:** `STDLIB/corpus/2049_eidos_membrane_e2e.iii`; `run_corpus.sh`.

- [ ] **Step 1:** A single KAT that, in one run: registers a real FSM (parametric kinduct), a real LTL formula (parametric tgraph), a real op-pair (causal), and a real rewrite (intent), enqueues them on `ser_vbus`, runs `vrf_membrane()`, and asserts every verdict is correct + witnessed + replayable. Return 99; teeth = corrupt one problem ⇒ its verdict flips ⇒ KAT RED.
- [ ] **Step 2–4:** run via pinned `iiis-2` (adequate timeout — these are SAT-heavy; do NOT report a timeout 124 as a pass); `build_stdlib.sh` green; commit.

### Task 6.2: calibration doc + memory

- [ ] **Step 1:** Append `PART XVIII` to `DOCS/III-SERAPHYTE-CLOSURE-PLAN.md`: state in honest tiers what is now USABLE (each organ parametric, the membrane autonomous, executed-output-proven) vs. the named frontier (e.g. larger FSMs than the 256-state cap; full per-compile membrane gating, which stays OFFLINE by design). No "it works" without the KAT exit code cited.
- [ ] **Step 2:** Update memory `project_iii_seraphyte_eidos_wire.md` with the membrane (parametric organs + the bus + the driver + the apply gate).
- [ ] **Step 3: Commit** `git commit -m "III EIDOS-VM — calibration + memory"`

---

## Self-Review

**Spec coverage** (every organ from the question + "the others like it"):
- `ser_kinduct` → Task 1.1 (table-driven FSM). ✅
- `ser_tgraph` → Task 1.2 (caller formula). ✅
- `ser_causal` → already general; Task 3.1 adds the FSM-collapse collaboration. ✅
- `ser_kinduct_sym` → Task 2.1. ✅  `ser_intent` → Task 2.2. ✅  `ser_antiunify` → Task 2.3. ✅  `ser_cascade` → Task 2.4. ✅
- already-general (`ser_egraph`/`ser_absint`/`ser_petri`/`ser_cegis`/`ser_cascade2`/`ser_regalloc`) → consumed by the bus/driver in Phase 4 (no generalization needed; their parametric APIs are the membrane's stages). ✅
- "autonomous" → `ser_verify` fold (Task 4.2). ✅  "collaboration" → the bus (4.1) + causal→sieve (3.1) + the cheap→expensive routing (4.2). ✅  "EIDOS event-driven" → `ser_vbus` on `field`/`isub` (4.1). ✅  "ripple/Seraphyte apply" → Tasks 5.1/5.2. ✅

**Placeholder scan:** every code step shows the actual `.iii`; the repeated "register family / mirror" tasks (2.4, parts of 4) name the exact delegate predicate and the exact KAT assertions rather than "similar to". The only deliberately-deferred item is the FULL-driver run in Task 5.1 Step 3, which is gated on pinned-compiler safety and explicitly must be logged-not-claimed.

**Type consistency:** `ski_universal_g()->u32`, `sfsm_inv(s:u32)->u8`, `stg_check(formula:u32,len:u64)->u8`, `in_propose_proven(handle:u64,lhs:u64,rhs:u64)->u32`, `vrf_membrane()->u64`, `vb_request(kind:u32,a:u64,b:u64)->u64` — used consistently across Phases 0–6. The egraph node ids are `u64` (`seg_*` return type) everywhere they cross a task boundary.

**Math-conscience check:** every task has (a) a runnable realization (its KAT compiled+run for a real exit code), (b) discharged hypotheses (the symbolic engine — `bv_ring`/`bv_bits`/`tc_check`/k-induction — is the warrant; the concrete membrane only refutes), and (c) a falsifier (the teeth arm / the mutant). No task asserts a verdict the symbolic layer didn't discharge.

---

## Execution Handoff

Plan complete and saved to `DOCS/III-EIDOS-VERIFICATION-MEMBRANE-PLAN.md`. Two execution options:

1. **Subagent-Driven (recommended)** — a fresh subagent per task, review between tasks. **NOTE: the III project locks `no-subagents-on-III`** (see `feedback_no_subagents`), so this option is unavailable here by project rule.
2. **Inline Execution (the project default)** — execute tasks 0.1 → 6.2 in this session via `superpowers:executing-plans`, build-green + commit per task, with the canonical build + `cor_selftest` as the per-task checkpoint.
