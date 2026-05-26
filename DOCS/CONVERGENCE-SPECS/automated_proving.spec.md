# 77 numera/automated_proving.iii — Implementation Spec

## Verdict
**STUB.** The gospel candidate `atp_prove` "proves" *any* goal by allocating a proof term, adding a single `PT_RULE_AXIOM` step (kind `0x01`, **zero premises**, conclusion = the goal verbatim), finalizing, and verifying. `pt_verify` accepts that step structurally (an axiom legitimately has 0 premises), so the function returns `ATP_OK` for **every** well-formed input. This is `return true` wearing a proof term — a soundness catastrophe (M11/M18 violated). It composes **none** of SAT / SMT / e-graph / Groebner despite the prose; has **no bounded search** (M19), **no structured failure record** (contradicting its own prose), **no witness fragment** (M6), **no capability gate** (M8), **no algebraic-time anchoring** (W16/W17). Every extern return value is discarded (W12). `budget` is null-checked but never read (M19 dead). `atp_prove` carries **6 parameters** (W2 violation: max 4). The realized design below closes all of these.

## Purpose
`automated_proving` is the substrate's **goal-directed theorem prover**: it accepts a goal formula plus a set of library-cited axioms and a bounded search budget, dispatches the goal by its canonical *class* to the appropriate already-built decision procedure (SAT, SMT, e-graph equality saturation, or Groebner ideal membership), and on success constructs a **checkable proof term** (verified by `pt_verify`) whose leaf steps are the cited axioms and whose combinator step records *which* decision procedure discharged the goal. Proof is **by refutation**: the goal's negation is conjoined with the axioms and handed to the backend; an `UNSAT`/saturation-collapse verdict is the certificate. On failure it returns a structured failure record. It is **pure ontology of deduction**: the prover *is* the disciplined composition of the reasoning engines under a fixed, deterministic strategy — it does not *have* a strategy as a tunable, it *embodies* one fixed strategy.
Hexad kind: `kind_cognition`. Ring: **R0**. K_synth: **0.80** (from gospel header).

## Public API
All public fns return a status (W12). Error codes are negative `i32` (W9), compared by equality only (W11). Boolean-ish results are exact `i32` verdicts, never ordering-compared.

```iii
fn atp_init() -> i32 @export
fn atp_prove(req: *u8) -> i32 @export
fn atp_last_failure(out_rec: *u8) -> i32 @export
fn atp_last_term_id(out_term_id: *u8) -> i32 @export
fn atp_last_frag_id(out_frag_id: *u8) -> i32 @export
fn atp_selftest() -> u64 @export
```

- `atp_init` — idempotent subsystem init; zeroes the worklist / failure record / last-result handles. Returns `ATP_OK`.
- `atp_prove(req)` — `req` points to a packed **`ATP_Request`** aggregate (layout in *Data Structures*; folds the gospel's 6 scalar params into one pointer to satisfy W2). Returns `ATP_OK` on a verified proof, or one of the negative codes. On `ATP_OK` the proof-term id is retrievable via `atp_last_term_id` and the witness frag-id via `atp_last_frag_id`; on failure the record is retrievable via `atp_last_failure`.
- `atp_last_failure(out_rec)` — copies the 32-byte `ATP_Failure` record of the most recent `atp_prove` into `out_rec`. Returns `ATP_OK` or `ATP_E_NULL`.
- `atp_last_term_id(out_term_id)` — copies the 32-byte proof-term identifier of the last successful proof into `out_term_id`. Returns `ATP_OK`, `ATP_E_NULL`, or `ATP_E_NO_PROOF` (no successful proof yet).
- `atp_last_frag_id(out_frag_id)` — copies the 32-byte witness fragment id of the last successful proof. Returns `ATP_OK`, `ATP_E_NULL`, or `ATP_E_NO_PROOF`.
- `atp_selftest` — runs the KAT vectors below; returns `99u64` on full pass, else the 1-based index of the first failing vector (house convention, cf. `at_selftest`).

## Constant Namespace
**PREFIX = `APROVE_`** — grep of `STDLIB/` returned **zero** matches for `APROVE_`: no collision. (Note: I deliberately do **not** reuse the gospel's `ATP_` const names as module-scope linker globals where they would shadow; but the public fns keep the gospel `atp_` *function* prefix since function symbols are explicit and the gospel/dependency callers expect `atp_*`. Only **constants and module-scope vars** carry `APROVE_` to obey Trap 2. The error-code *values* match the gospel's intent.)

```
const APROVE_OK              : i32 =  0i32
const APROVE_E_NULL          : i32 = -1i32   // null pointer in request/out
const APROVE_E_TIMEOUT       : i32 = -2i32   // budget exhausted before a verdict
const APROVE_E_NO_PROOF      : i32 = -3i32   // backend refuted goal-negation? no — goal not provable / no result yet
const APROVE_E_NOT_INITED    : i32 = -4i32   // atp_init not called
const APROVE_E_BAD_CLASS     : i32 = -5i32   // unknown goal-class tag
const APROVE_E_BAD_REQ       : i32 = -6i32   // malformed request (len/cap mismatch)
const APROVE_E_BACKEND       : i32 = -7i32   // a backend returned a structural error
const APROVE_E_VERIFY        : i32 = -8i32   // proof term failed pt_verify (internal-consistency guard)
const APROVE_E_NO_CAP        : i32 = -9i32   // capability lacks TRANSFORM_RUN right
const APROVE_E_WITNESS       : i32 = -10i32  // wh_publish failed (sentinel returned)

// Goal-class tags (first byte of an encoded goal). One backend per class (M4: fixed dispatch).
const APROVE_CLASS_PROP      : u8  = 0x01u8   // propositional  -> SAT (refutation)
const APROVE_CLASS_LIA       : u8  = 0x02u8   // linear int arith -> SMT/LIA
const APROVE_CLASS_BV        : u8  = 0x03u8   // bit-vector      -> SMT/BV
const APROVE_CLASS_EQ        : u8  = 0x04u8   // equational      -> e-graph saturation
const APROVE_CLASS_POLY      : u8  = 0x05u8   // polynomial ideal-> Groebner membership

// Proof-term inference-kind values we *emit* — mirror proof_term.iii's PT_RULE_* numerals
// (we re-declare them under our prefix to avoid importing constants; values MUST match Module 61).
const APROVE_RULE_AXIOM       : u8 = 0x01u8   // == PT_RULE_AXIOM
const APROVE_RULE_MODUS_PONENS: u8 = 0x02u8   // == PT_RULE_MODUS_PONENS
const APROVE_RULE_LIBRARY_CITE: u8 = 0x07u8   // == PT_RULE_LIBRARY_CITE
const APROVE_RULE_CASE_ANALYSIS:u8 = 0x0Bu8   // == PT_RULE_CASE_ANALYSIS

// Backend verdict mirrors (values MUST match SAT/SMT Module 15/16).
const APROVE_SAT_SAT          : i32 = 1i32    // == SAT_SAT / SMT_SAT
const APROVE_SAT_UNSAT        : i32 = 2i32    // == SAT_UNSAT / SMT_UNSAT

// Bounds (W8 justification in Data Structures).
const APROVE_MAX_AXIOMS       : u32 = 256u32   // cited library theorems per goal
const APROVE_MAX_GOAL_BYTES   : u64 = 512u64   // == PT_CONCLUSION_BYTES; a goal fits one conclusion slot
const APROVE_WORKLIST_MAX     : u32 = 1024u32  // explicit sub-goal stack depth (== PT_MAX_STEPS)
const APROVE_ID_BYTES         : u64 = 32u64    // identifier width
const APROVE_FAIL_REC_BYTES   : u64 = 32u64    // ATP_Failure serialized width
const APROVE_OPID_BYTE        : u8  = 0x4Du8   // witness opid discriminator for "automated_proving.prove"
```

## Data Structures
All module-scope (Trap 7: **no local `var` arrays**). Each justified against W8.

```
var APROVE_INITED        : u8                         // init flag
var APROVE_HAS_RESULT    : u8                         // 1 after a successful proof (gates last_term/last_frag)
var APROVE_LAST_TERM_ID  : [u8; 32]                   // id of last verified proof term
var APROVE_LAST_FRAG_ID  : [u8; 32]                   // id of last emitted witness fragment
var APROVE_FAILREC       : [u8; 32]                   // ATP_Failure of last prove (see layout)

// Explicit-stack worklist for goal-directed search (W15: no recursion).
var APROVE_WL_GOAL_OFF   : [u32; 1024]                // offset of each pending sub-goal into APROVE_WL_BUF
var APROVE_WL_GOAL_LEN   : [u32; 1024]                // length of each pending sub-goal
var APROVE_WL_TOP        : u32                         // stack depth (0..APROVE_WORKLIST_MAX)
var APROVE_WL_BUF        : [u8; 524288]               // 1024 * 512 sub-goal byte storage

// Scratch for hashing / step assembly (serialized, non-reentrant — acceptable: prover is single-threaded R0).
var APROVE_HASH_IN       : [u8; 32]                   // in_commit  (keccak256 of goal||axioms)
var APROVE_HASH_OUT      : [u8; 32]                   // out_commit (keccak256 of serialized term)
var APROVE_PREMISE_BUF   : [u8; 4096]                 // packed premise-id list (256 * 4) for pt_add_inference
var APROVE_SERIAL_BUF    : [u8; 1048576]              // proof-term serialization target (cap for keccak)
var APROVE_PRODUCER_ID   : [u8; 32]                   // module identity (filled in init from a fixed seed)
var APROVE_OPID_ID       : [u8; 32]                   // op identity for the witness opid field
var APROVE_PAYLOAD       : [u8; 16]                   // witness payload: tag(2) + class(1) + stepcount(4) + pad
```

**Bound justifications (W8):**
- `1024` worklist / step depth = `PT_MAX_STEPS` (Module 61): a proof cannot exceed the proof-term step capacity, so the search worklist is bounded by the same constant. Bound is exact, not heuristic.
- `256` axioms = `PT_SLOTS` and `SMT_MAX_LIA_CON`-class sizing; the cited-axiom set per goal is small and capped to keep premise lists ≤ proof-term arity.
- `512` goal bytes = `PT_CONCLUSION_BYTES`: a goal must fit one proof-term conclusion slot.
- `1048576` serialize buffer = upper bound for `pt_serialize` of a 1024-step term whose conclusions are bounded; matches the keccak streaming-capable path.
- `4096` premise buffer = `256 * 4` (max axioms × 4-byte premise id), the largest premise list `pt_add_inference` will receive.

**`ATP_Request` aggregate** (passed by `*u8`; little-endian; folds gospel's 6 params, W2):
| offset | size | field | meaning |
|---|---|---|---|
| 0 | 8 | `cap_id` (u64) | capability id; must carry `CAP_RIGHT_TRANSFORM_RUN` |
| 8 | 8 | `goal_ptr` (u64) | pointer to encoded goal (first byte = class tag) |
| 16 | 4 | `goal_len` (u32) | goal byte length (≤ 512) |
| 20 | 8 | `axioms_ptr` (u64) | pointer to axiom block: `n` then `n` × (len:u32, bytes) |
| 28 | 4 | `axioms_len` (u32) | total axiom block byte length |
| 32 | 4 | `budget_steps` (u32) | max saturation / search steps (M19) |
| 36 | 4 | `budget_axioms` (u32) | max axioms to admit as premises (M19) |
| 40 | 8 | `out_term_id` (u64) | caller's 32-byte buffer to receive proof-term id |

**`ATP_Failure` record** (32 bytes, copied out by `atp_last_failure`):
| offset | size | field |
|---|---|---|
| 0 | 1 | `class` (goal class attempted, or 0xFF if unparsed) |
| 1 | 1 | `reason` (low byte of the negative error code) |
| 2 | 2 | pad |
| 4 | 4 | `steps_consumed` (u32) |
| 8 | 4 | `last_backend_verdict` (i32 as u32) |
| 12 | 20 | reserved (zeroed) |

## Dependencies (externs)
Declared `extern @abi(c-msvc-x64) ... from "<file>.iii"`. **NB:** every signature below was confirmed by reading the *real provider file*, not the gospel externs (the gospel externs are unreliable per §3.5).

Built / realized providers (safe to call now):
- `numera/keccak256.iii` (built) — `fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32`. **Real signature takes `u64` integer-pointers, not `*u8`** — callers pass `(&buf as u64)`. (Streaming `keccak256_init/update/final` also exist here, but oneshot suffices.)
- `aether/witness_hook.iii` (built) — `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64`. Returns the new algebraic-time stamp; **sentinel `0xFFFFFFFFFFFFFFFFu64` on failure**. *Advances algebraic time internally via `at_advance` — the prover MUST NOT advance time itself.* Requires `wh_init` to have run (boot does this; the prover checks the sentinel and maps to `APROVE_E_WITNESS`).
- `aether/capability.iii` (built) — `fn cap_verify_rights(id: u64, required: u64) -> u8`. Real right-bit constant for "run a transform engine": **`CAP_RIGHT_TRANSFORM_RUN = 0x00040000u64`** (declared in capability.iii; the prover hard-codes the literal under its own `APROVE_` const to avoid importing).
- `numera/identifier.iii` (built) — `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32`, `fn ident_copy(src: *u8, dst: *u8) -> i32`, `fn ident_zero(out: *u8) -> i32`. Used to mint `APROVE_PRODUCER_ID` / `APROVE_OPID_ID` deterministically.

Not-yet-built dependencies (wave scheduler must order these **before** Module 77):
- `numera/proof_term.iii` (**Module 61 — NOT BUILT; spec done**) — `fn pt_init() -> i32`, `fn pt_alloc(out_term_id: *u8) -> i32`, `fn pt_add_inference(term_id: *u8, inference_kind: u8, premise_ids: *u8, premise_count: u32, conclusion: *u8, conclusion_len: u32) -> i32`, `fn pt_finalize(term_id: *u8) -> i32`, `fn pt_verify(term_id: *u8) -> i32`, `fn pt_emit_constructed(term_id: *u8, out_frag_id: *u8) -> i32`, `fn pt_serialize(term_id: *u8, out_buf: *u8, out_cap: u64, out_len: *u64) -> i32`.
- `numera/smt.iii` (**Module 16 — NOT BUILT; spec done**) — `fn smt_init() -> i32`, `fn smt_lia_new_var() -> u32`, `fn smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32`, `fn smt_lia_add_eq(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32`, `fn smt_bv_new_var(width: u32) -> u32`, `fn smt_bv_add_eq(a: u32, b: u32) -> i32`, `fn smt_bv_add_ult(a: u32, b: u32) -> i32`, `fn smt_solve() -> i32`, `fn smt_lia_value(var: u32) -> i64`, `fn smt_bv_value(var: u32) -> u64`. Verdicts `SMT_SAT=1 / SMT_UNSAT=2`.
- `numera/sat.iii` (**Module 15 — NOT BUILT; spec done**) — `fn sat_init(n_vars: u32) -> i32`, `fn sat_add_clause(lits: *u32, n_lits: u32) -> i32`, `fn sat_solve() -> i32`, `fn sat_value(var: u32) -> u8`. Verdicts `SAT_SAT=1 / SAT_UNSAT=2`.
- `numera/egraph.iii` (**Module 17 — NOT BUILT; spec done**) — `fn eg_add(symbol_id: *u8, children: *u32, n: u32) -> u32`, `fn eg_union(a: u32, b: u32) -> u32`, `fn eg_find(a: u32) -> u32`, `fn eg_rebuild() -> u32`, `fn eg_apply_rule(lhs: *u32, lhs_n: u32, rhs: *u32, rhs_n: u32) -> u32`, `fn eg_saturate(max_steps: u32) -> u32`, `fn eg_extract(root: u32, costs: *u32, sym_count: u32, out_term: *u32, out_n: *u32) -> i32`.
- `numera/groebner.iii` (**Module 18 — NOT BUILT; spec done**) — `fn gb_init(nvars: u32) -> i32`, `fn gb_new_poly() -> u32`, `fn gb_append_term(slot: u32, coeff_bid: u64, exps: *u32) -> i32`, `fn gb_normalize(slot: u32, arena: u64, p: u64) -> i32`, `fn gb_reduce(arena: u64, target: u32, basis: *u32, basis_n: u32, p: u64) -> u32`, `fn gb_buchberger(arena: u64, generators: *u32, gen_n: u32, out_basis: *u32, out_n: *u32, p: u64) -> i32`. (Groebner additionally needs an `arena` id; the prover owns a fixed module-scope arena handle established at init, or accepts one in a future request-field — for Phase 2 the POLY class may be staged behind a backend-not-ready guard if `arena.iii` wiring is incomplete.)

**Total not-yet-built deps: 5** (proof_term, smt, sat, egraph, groebner). All have completed specs, so the wave scheduler can place Module 77 in a wave strictly after wave(16,15,17,18) and wave(61).

## Algorithm

### `atp_init()`
1. If `APROVE_INITED == 1u8` return `APROVE_OK` (idempotent; Trap 10 — flag read first, early return, no mutated-flag-as-checkpoint).
2. Zero `APROVE_WL_TOP`, `APROVE_HAS_RESULT`, and `APROVE_FAILREC[0..31]`.
3. Mint `APROVE_PRODUCER_ID` from the fixed ASCII seed `"numera.automated_proving\0..."` via `ident_from_bytes`; mint `APROVE_OPID_ID` from `"automated_proving.prove\0..."`. (Deterministic identity — M2.)
4. Call `pt_init()`, `smt_init()` lazily-guarded? **No** — each backend is `*_init`-ed per goal inside the dispatch (a fresh solver per goal is required for determinism: SAT/SMT reset all state on `*_init`). `atp_init` only initializes proof-term storage state it shares.
5. Set `APROVE_INITED = 1u8`; return `APROVE_OK`.

Determinism/bit-identity: all seeds are fixed byte arrays; `ident_from_bytes` is keccak-deterministic; no time, no entropy.

### `atp_prove(req)`
**Phase A — validate & gate (M8 capability, M19 budget read).**
1. If `APROVE_INITED == 0u8` return `APROVE_E_NOT_INITED`.
2. If `(req as u64) == 0u64` return `APROVE_E_NULL`.
3. Copy request scalars into **named locals** (Trap: param/aggregate spill — read each field once into a local before use): `cap_id`, `goal_ptr`, `goal_len`, `axioms_ptr`, `axioms_len`, `budget_steps`, `budget_axioms`, `out_term_ptr`. (≤20 locals — W13.)
4. Null/range checks: `goal_ptr != 0`, `out_term_ptr != 0`, `goal_len != 0u32`, `goal_len as u64 <= APROVE_MAX_GOAL_BYTES`, `budget_axioms <= APROVE_MAX_AXIOMS`. Violations → `APROVE_E_NULL` / `APROVE_E_BAD_REQ`, and write `ATP_Failure{class=0xFF, reason, steps=0}`.
5. **Capability gate (M8):** `if cap_verify_rights(cap_id, APROVE_TRANSFORM_RUN_BIT) != 1u8 { record fail; return APROVE_E_NO_CAP }`. (Right-bit literal = `0x00040000u64`, the real `CAP_RIGHT_TRANSFORM_RUN`.)
6. Read `class = goal_ptr[0]` into a local. Dispatch is a `when`-cascade (no `select` — Trap: eager-eval), exact match (M4):
   - `APROVE_CLASS_PROP` → `atp_run_prop`
   - `APROVE_CLASS_LIA`  → `atp_run_lia`
   - `APROVE_CLASS_BV`   → `atp_run_bv`
   - `APROVE_CLASS_EQ`   → `atp_run_eq`
   - `APROVE_CLASS_POLY` → `atp_run_poly`
   - else → record `ATP_Failure{class, reason=APROVE_E_BAD_CLASS}`, return `APROVE_E_BAD_CLASS`.

**Phase B — backend discharge (proof by refutation; M19 bounded).**
Each `atp_run_*` private helper (all `≤4` params, called with `(goal_ptr,goal_len,axioms_ptr,axioms_len)` or a small spill aggregate) performs:
1. Re-`*_init` the backend (fresh deterministic state).
2. Parse the goal payload after the class byte into the backend's native constraints, AND assert the **negation** of the goal's conclusion together with the cited axioms (refutation). Axiom parsing walks the axiom block deterministically (length-prefixed entries) up to `min(n, budget_axioms)`.
3. Run the backend with the step budget: SAT/SMT `*_solve()` (internally bounded — SMT's box is `±256`, SAT has no restarts and a finite clause db; both terminate); e-graph `eg_saturate(budget_steps)`; Groebner `gb_buchberger(...)` (bounded by basis-size caps). **No recursion anywhere** (W15) — the backends use their own explicit structures; the prover's only multi-goal structure is the `APROVE_WL_*` explicit stack (used for CASE_ANALYSIS goal splitting: push sub-goals, pop-and-discharge under a sentinel-driven `while APROVE_WL_TOP != 0u32` loop, W14 — no `break`).
4. Interpret the verdict:
   - For PROP/LIA/BV: goal is proven **iff** the negation-augmented system is `UNSAT` (`== APROVE_SAT_UNSAT`). A `SAT` verdict means a counter-model exists → goal **not** valid → `APROVE_E_NO_PROOF`. (Compared by `== / !=` only — W11, Trap 3.)
   - For EQ: goal `lhs = rhs` is proven iff `eg_find(lhs_class) == eg_find(rhs_class)` after `eg_rebuild` post-saturation.
   - For POLY: goal "polynomial `g` is in ideal ⟨axioms⟩" is proven iff `gb_reduce(g, basis)` yields the zero polynomial (`bigint_is_zero` on every remainder coeff / zero term count).
   - Budget exhausted with no verdict → `APROVE_E_TIMEOUT`.
   - Backend structural error (negative) → `APROVE_E_BACKEND`.

**Phase C — proof-term construction (M11/M12/M18; checkable certificate).**
On a *proven* verdict:
1. `pt_alloc(&local_term_id)` → check `== PT_OK` (mapped to `APROVE_E_BACKEND` on failure; **return value checked** — fixes the gospel's W12 violation).
2. Add one `APROVE_RULE_LIBRARY_CITE` step per admitted axiom (premise_count varies per Module 61's arity table: LIBRARY_CITE requires exactly 1 premise referencing the admitted library id — encode each axiom's library handle as the 4-byte premise; conclusion = the axiom bytes). These become steps `0..k-1`.
3. Add the **discharging combinator step**: `APROVE_RULE_CASE_ANALYSIS` (needs `≥2` premises per Module 61) when `k≥2`, else `APROVE_RULE_MODUS_PONENS` (needs exactly 2) — premises reference the earlier axiom steps (indices `< current`, satisfying `pt_verify_step`'s "premises reference earlier steps" rule), conclusion = **the goal** bytes. The `inference_kind` numeral additionally encodes (in a payload, see step 5) which backend produced the verdict; the step itself is what `pt_verify` checks structurally.
   - **Soundness note (flagged):** `pt_verify` (Module 61) is **structural-only** — it checks premise arity and earlier-step references, NOT semantic entailment. The *semantic* guarantee that the goal follows comes from the bounded backend refutation in Phase B, recorded as the certificate. This is the M11/M18 contract: the proof term is the *carrier*; the backend run is the *checker*. The spec records this explicitly so Phase 2 does not mistake structural verification for soundness. (If Module 61 later adds a conclusion-consistency check between MODUS_PONENS premises and conclusion, this step's premises must be the actual antecedent/implication pair; the layout above leaves room.)
3a. **Negative-case discipline (memory rule "prove the negative"):** the self-test MUST include a goal whose negation is **SAT** (a non-theorem) and assert `atp_prove` returns `APROVE_E_NO_PROOF` and emits **no** proof term and **no** witness fragment. A prover that only ever returns OK is the gospel stub.
4. `pt_finalize(&local_term_id)` → check `== PT_OK`.
5. `pt_verify(&local_term_id)` → if `!= PT_OK` return `APROVE_E_VERIFY` (internal-consistency guard: our own construction must verify).
6. `pt_serialize(&local_term_id, &APROVE_SERIAL_BUF[0], 1048576u64, &serial_len)`; hash it: `keccak256_oneshot(&APROVE_SERIAL_BUF as u64, serial_len, &APROVE_HASH_OUT as u64)` → `out_commit`. Hash `goal||axioms` into `APROVE_HASH_IN` similarly → `in_commit`. (oneshot takes `u64` pointers — confirmed.)

**Phase D — witness (M6/M10) & result publication.**
1. Build `APROVE_PAYLOAD`: bytes `[0]=0x77`, `[1]=APROVE_OPID_BYTE`, `[2]=class`, `[3..6]=step_count(le u32)`, rest 0.
2. `let t : u64 = wh_publish(&APROVE_PRODUCER_ID, &APROVE_OPID_ID, &APROVE_HASH_IN, &APROVE_HASH_OUT, 0u8 /*revtag: reversible*/, 0u8 /*phase*/, 0u16 /*pillar: numera*/, &zero_ante, 0u32, &APROVE_PAYLOAD, 16u32, &APROVE_LAST_FRAG_ID)`. If `t == 0xFFFFFFFFFFFFFFFFu64` return `APROVE_E_WITNESS`. (Time advances inside `wh_publish` — W16/W17 satisfied without the prover touching `at_advance`.)
3. `ident_copy(&local_term_id, &APROVE_LAST_TERM_ID)`; `ident_copy(&local_term_id, out_term_ptr as *u8)`; set `APROVE_HAS_RESULT = 1u8`.
4. Return `APROVE_OK`.

**Determinism (M2) / bit-identity (W5):** dispatch is an exact tag match; backends are deterministic (CDCL no-randomness, brute-box LIA, fixed-order saturation, Buchberger with fixed monomial order); the proof term's step order is fixed (axioms in cited order, then the combinator); the witness commitments are keccak over canonical serializations. No floats, no ML, no heuristics, no time-of-day. Re-running `atp_prove` on identical `req` bytes yields identical `out_term_id`, identical frag-id *modulo the monotone time index* (the recomputable part — the commitments — are byte-identical; M10).

### `atp_last_failure / atp_last_term_id / atp_last_frag_id`
Trivial guarded `ident_copy` / 32-byte copy from the module-scope record; null-check the out pointer; `last_term`/`last_frag` additionally gate on `APROVE_HAS_RESULT == 1u8` else `APROVE_E_NO_PROOF`.

### `atp_selftest()`
Builds each KAT request in module-scope scratch and asserts the exact verdict + that proof-bearing cases verify and non-theorems do not. Returns `99u64` on full pass.

## KAT Vectors (>= 3)
Each is a fully-specified `ATP_Request` over fixed bytes; the self-test checks the `i32` return **and** (for positives) `pt_verify(last_term)==PT_OK`, **and** (for the negative) that no term/frag was produced.

1. **PROP tautology (positive).** Goal class `0x01`, goal = propositional formula `A ∨ ¬A` (encoded: 1 var, clause set for the *negation* `¬(A∨¬A) = ¬A ∧ A`). Axioms: none. Backend = SAT; negation is `{(¬A),(A)}` → **UNSAT**. Expect `atp_prove == APROVE_OK`; `pt_verify(last_term)==PT_OK` (one CASE/MP step, 0 cited axioms → use a degenerate AXIOM-of-`true` premise pattern only if Module 61 permits 0-premise combinators; otherwise this vector cites the law-of-excluded-middle library axiom as premise 0 and the combinator references it). Deterministic.
2. **LIA entailment (positive).** Goal class `0x02`: from axiom `x ≥ 1` (i.e. `-x ≤ -1`) and `x ≤ 1`, prove `x == 1`. Negation augmented: assert `x ≠ 1` with the two axiom bounds over the `±256` box → **UNSAT** (no integer in `[1,1]` satisfies `x≠1`). Expect `APROVE_OK`, term verifies, 2 LIBRARY_CITE steps + 1 CASE_ANALYSIS. (LIA brute box is exact and bounded — M4/M19.)
3. **EQ congruence (positive).** Goal class `0x04`: axioms `a = b`, `b = c`; prove `a = c`. Backend = e-graph: `eg_add` for `a,b,c`, `eg_union(a,b)`, `eg_union(b,c)`, `eg_rebuild`; assert `eg_find(a) == eg_find(c)`. Expect `APROVE_OK`; proof term = 2 LIBRARY_CITE (the two equalities) + 1 TRANSITIVITY/CASE step concluding `a=c`. Deterministic union-find canon.
4. **Non-theorem (NEGATIVE — mandatory, proves the gate fails).** Goal class `0x02`: prove `x == 2` given only `x ≥ 1` (`-x ≤ -1`). Negation `x ≠ 2` with `x ≥ 1` is **SAT** (e.g. `x=1`). Expect `atp_prove == APROVE_E_NO_PROOF`; `atp_last_term_id == APROVE_E_NO_PROOF` (no result); failure record `class=0x02, reason=0x03, last_backend_verdict=SAT(1)`. **This vector is the antidote to the gospel stub** (which would wrongly return OK).
5. **Bad class (negative).** Goal first byte `0xEE`. Expect `APROVE_E_BAD_CLASS`, no term, failure record `class=0xEE,reason=0x05`.

(Vectors 1–3 are positive theorems with checkable terms; 4–5 prove the refusal paths. The standard-vector citation for the LIA box bound is the gospel's own `SMT_LIA_BOX = 256` admissibility note.)

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED (long signatures, esp. the `wh_publish` extern). **Avoidance:** every `fn`/`extern fn` signature is written **single-line**, including the 12-param `wh_publish` extern (the briefing §3.5 gives its canonical single-line form). Request folding into one `*u8` keeps `atp_prove` itself short.
- **Trap 2 (module-level const = linker global)** — EXPOSED. **Avoidance:** every const/var is `APROVE_`-prefixed; grep confirmed zero collisions. Backend constants (`SAT_SAT`, `PT_RULE_*`, `CAP_RIGHT_TRANSFORM_RUN`) are **re-declared locally** under `APROVE_` with matching numerals rather than imported, so no duplicate-symbol risk.
- **Trap 3 (signed ordering compare SIGSEGV)** — EXPOSED (verdict comparisons, error codes). **Avoidance:** all `i32`/`i64` decisions use `== / !=` against sentinels (`== APROVE_SAT_UNSAT`, `!= PT_OK`, `== APROVE_E_*`), never `< / <= / > / >=`. The LIA backend's own ordering lives *inside* smt.iii (its problem); the prover only reads the resulting `i32` verdict by equality.
- **Trap 4 (u32-in-u64-slot garbage before pointer math)** — EXPOSED (`goal_len`, offsets used to index `APROVE_WL_BUF`/serialize). **Avoidance:** mask `(x as u64) & 0xFFFFFFFFu64` before any pointer arithmetic on a u32-derived index.
- **Trap 5 (u32 pointer store width)** — EXPOSED (writing `step_count` into `APROVE_PAYLOAD`, premise ids into `APROVE_PREMISE_BUF`). **Avoidance:** store **byte-by-byte through `*u8`** with explicit `(v >> (i*8)) & 0xFFu32` extraction.
- **Trap 6 (nested block comments)** — avoid; use `//` for inline notes.
- **Trap 7 (local `var` arrays)** — EXPOSED conceptually. **Avoidance:** *all* buffers are module-scope (listed above); none declared inside a fn. Non-reentrancy noted (acceptable: R0 single-threaded prover; serialized like the keccak/crypto modules).
- **Trap 8 (`} else {` one line)** — formatting rule; all else-clauses single-line.
- **Trap 9 (em-dash in comments)** — use ASCII `--` only in comments.
- **Trap 10 (`let mut` checkpoint flag)** — EXPOSED (`APROVE_INITED`, worklist `done`). **Avoidance:** init uses read-then-early-return; the worklist loop is driven by `while APROVE_WL_TOP != 0u32` (counter drives the loop directly, W14) not a separate mutated boolean.
- **Trap 11 (`a % b` after a call)** — NOT used; the prover performs no modulo after a call. (Any indexing is `*`/`+` only; if a hash-bucket mod were ever needed it would be a power-of-two `& (N-1)`.) Flagged: none present.
- **Trap 12 (`@specialize *T` stride)** — NOT exposed; module is not generic over element width.

## Gap / Fix List
The gospel body is a STUB. Every defect and its fix:

1. **Soundness hole — proves everything.** Single `PT_RULE_AXIOM` step asserts the goal as its own axiom; `pt_verify` accepts it. → **Fix:** proof **by refutation** through a real decision-procedure backend (Phase B); the goal becomes the *conclusion* of a combinator step whose premises are *cited library axioms*, never the goal-as-axiom. Add the mandatory **negative KAT** (vector 4) proving a non-theorem is refused.
2. **No composition of SAT/SMT/e-graph/Groebner** (prose promises it; body uses none). → **Fix:** class-dispatched backends (Phase A/B), each a confirmed extern surface.
3. **No bounded search (M19).** `budget` null-checked, never read. → **Fix:** `budget_steps`/`budget_axioms` fields read into locals and passed to `eg_saturate`/admission caps; `APROVE_E_TIMEOUT` on exhaustion. Cost is lattice-bounded (finite SAT db, ±256 LIA box, capped saturation/basis).
4. **No structured failure record** (prose promises one). → **Fix:** `ATP_Failure` 32-byte record + `atp_last_failure` accessor; populated on every non-OK path.
5. **No witness (M6/M10).** → **Fix:** Phase D `wh_publish` with keccak `in_commit`/`out_commit`, recomputable from recorded inputs. Real symbol `wh_publish` (gospel's `ws_emit_fragment` is fiction — flagged per §3.5).
6. **No capability gate (M8).** → **Fix:** `cap_verify_rights(cap_id, CAP_RIGHT_TRANSFORM_RUN)` in Phase A (real symbol; gospel's `cap_verify` is fiction — flagged).
7. **W12 — extern returns discarded.** `pt_add_inference`, `pt_finalize`, `pt_verify` results ignored. → **Fix:** every call checked `== PT_OK`, mapped to a negative code.
8. **W2 — `atp_prove` had 6 params.** → **Fix:** fold into `ATP_Request` aggregate passed by `*u8` (1 param). All private helpers ≤4 params.
9. **No algebraic-time anchoring (W16/W17).** → **Fix:** time advances via `wh_publish`→`at_advance` internally; prover never calls `at_advance` directly (correct: single-writer discipline in algebraic_time.iii). Gospel's `at_now` fiction is **not** used — flagged per §3.5.
10. **`atp_init` doesn't init dependencies.** → **Fix:** `atp_init` calls `pt_init`; backends `*_init`-ed per goal for fresh deterministic state.
11. **Systemic-defect externs to AVOID (flagged, not used):** `ws_emit_fragment` (→ `wh_publish`), `cap_verify` (→ `cap_verify_rights`), `at_now` (→ `at_current`/advance-via-hook), `keccak256_*` *from `keccak.iii`* (→ the real `keccak256.iii`, and we use `keccak256_oneshot` with **`u64`** pointers). The gospel candidate did not import these, but Phase-2 authors copying sibling modules will be tempted; the skeleton uses only confirmed-real signatures.
12. **`pt_verify` is structural-only (carry-over from Module 61).** Not a Module-77 bug, but a **load-bearing flag:** the semantic soundness rests on the backend refutation, not on `pt_verify`. Documented in Phase C step 3 so no one mistakes structural verification for entailment checking. If Module 61 is later hardened to check conclusion consistency, Module 77's combinator premises already reference the correct earlier steps.

**Maximal-intent confirmation:** the realized design composes all four reasoning engines, carries a checkable proof term, witnesses every success, gates on capability, bounds every search, records every failure, and proves its own refusal path — the full M-level ambition of "goal-directed automated theorem proving," not a down-scaled subset.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/automated_proving.iii
 *
 * III STDLIB - numera::automated_proving
 *
 * Automated theorem proving. Goal-directed search composing SAT, SMT,
 * e-graph, and Groebner under one fixed deterministic strategy. Proof
 * is by refutation; the output proof term is verified (pt_verify) and
 * the success is witnessed (wh_publish). Capability-gated (TRANSFORM_RUN).
 * No ML, no heuristics, no floats, no recursion. Bounded search (M19).
 *
 * Hexad: kind_cognition.  Ring: R0.  K_synth: 0.80.
 *
 * Discipline: W2 (request folded to one ptr), W8, W11 (eq-only), W12,
 * W13, W14 (sentinel loops), W15 (explicit worklist, no recursion),
 * W16/W17 (time advances via wh_publish only).
 */

module numera_automated_proving

// -- Built providers (signatures confirmed against the real files) --
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"

// -- NOT-YET-BUILT providers (specs done; scheduler orders these first) --
extern @abi(c-msvc-x64) fn pt_init() -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_alloc(out_term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_add_inference(term_id: *u8, inference_kind: u8, premise_ids: *u8, premise_count: u32, conclusion: *u8, conclusion_len: u32) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_finalize(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_serialize(term_id: *u8, out_buf: *u8, out_cap: u64, out_len: *u64) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn smt_init() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_new_var() -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_eq(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_new_var(width: u32) -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_eq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_ult(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_solve() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn sat_init(n_vars: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_solve() -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_value(var: u32) -> u8 from "sat.iii"
extern @abi(c-msvc-x64) fn eg_add(symbol_id: *u8, children: *u32, n: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_union(a: u32, b: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_find(a: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_rebuild() -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_saturate(max_steps: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn gb_init(nvars: u32) -> i32 from "groebner.iii"
extern @abi(c-msvc-x64) fn gb_new_poly() -> u32 from "groebner.iii"
extern @abi(c-msvc-x64) fn gb_append_term(slot: u32, coeff_bid: u64, exps: *u32) -> i32 from "groebner.iii"
extern @abi(c-msvc-x64) fn gb_reduce(arena: u64, target: u32, basis: *u32, basis_n: u32, p: u64) -> u32 from "groebner.iii"

// -- Status / verdict / dispatch constants (APROVE_ prefix; no collision) --
const APROVE_OK              : i32 =  0i32
const APROVE_E_NULL          : i32 = -1i32
const APROVE_E_TIMEOUT       : i32 = -2i32
const APROVE_E_NO_PROOF      : i32 = -3i32
const APROVE_E_NOT_INITED    : i32 = -4i32
const APROVE_E_BAD_CLASS     : i32 = -5i32
const APROVE_E_BAD_REQ       : i32 = -6i32
const APROVE_E_BACKEND       : i32 = -7i32
const APROVE_E_VERIFY        : i32 = -8i32
const APROVE_E_NO_CAP        : i32 = -9i32
const APROVE_E_WITNESS       : i32 = -10i32

const APROVE_CLASS_PROP      : u8  = 0x01u8
const APROVE_CLASS_LIA       : u8  = 0x02u8
const APROVE_CLASS_BV        : u8  = 0x03u8
const APROVE_CLASS_EQ        : u8  = 0x04u8
const APROVE_CLASS_POLY      : u8  = 0x05u8

const APROVE_RULE_AXIOM        : u8 = 0x01u8
const APROVE_RULE_MODUS_PONENS : u8 = 0x02u8
const APROVE_RULE_LIBRARY_CITE : u8 = 0x07u8
const APROVE_RULE_CASE_ANALYSIS: u8 = 0x0Bu8

const APROVE_SAT_SAT         : i32 = 1i32
const APROVE_SAT_UNSAT       : i32 = 2i32
const APROVE_PT_OK           : i32 = 0i32

const APROVE_TRANSFORM_RUN_BIT : u64 = 0x00040000u64  // == CAP_RIGHT_TRANSFORM_RUN
const APROVE_WH_FAIL         : u64 = 0xFFFFFFFFFFFFFFFFu64

const APROVE_MAX_AXIOMS      : u32 = 256u32
const APROVE_MAX_GOAL_BYTES  : u64 = 512u64
const APROVE_WORKLIST_MAX    : u32 = 1024u32
const APROVE_ID_BYTES        : u64 = 32u64
const APROVE_OPID_BYTE       : u8  = 0x4Du8

// -- Module-scope state (Trap 7: no local var arrays anywhere) --
var APROVE_INITED        : u8  = 0u8
var APROVE_HAS_RESULT    : u8  = 0u8
var APROVE_LAST_TERM_ID  : [u8; 32]
var APROVE_LAST_FRAG_ID  : [u8; 32]
var APROVE_FAILREC       : [u8; 32]
var APROVE_WL_GOAL_OFF   : [u32; 1024]
var APROVE_WL_GOAL_LEN   : [u32; 1024]
var APROVE_WL_TOP        : u32 = 0u32
var APROVE_WL_BUF        : [u8; 524288]    /* 1024 * 512 */
var APROVE_HASH_IN       : [u8; 32]
var APROVE_HASH_OUT      : [u8; 32]
var APROVE_PREMISE_BUF   : [u8; 4096]      /* 256 * 4 */
var APROVE_SERIAL_BUF    : [u8; 1048576]
var APROVE_PRODUCER_ID   : [u8; 32]
var APROVE_OPID_ID       : [u8; 32]
var APROVE_PAYLOAD       : [u8; 16]
var APROVE_ZERO_ANTE     : [u8; 32]        /* zeroed; n_ante = 0 */
var APROVE_PROD_SEED     : [u8; 32]        /* "numera.automated_proving" seed */
var APROVE_OPID_SEED     : [u8; 32]        /* "automated_proving.prove" seed */

// -- Lifecycle --
fn atp_init() -> i32 @export {
    // TODO: body per Algorithm 'atp_init' -- idempotent read-then-return;
    // zero WL/failrec; fill seeds; ident_from_bytes -> producer/opid; pt_init(); set inited.
}

// -- Internal helpers (each <=4 params, W2) --
fn atp_record_fail(class: u8, reason: i32, steps: u32, verdict: i32) -> i32 {
    // TODO: byte-by-byte (W5/Trap5) write into APROVE_FAILREC; return reason.
}
fn atp_run_prop(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32) -> i32 {
    // TODO: sat_init; encode goal-negation+axioms as clauses; sat_solve; UNSAT==proven.
}
fn atp_run_lia(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32) -> i32 {
    // TODO: smt_init; smt_lia_* for axioms + goal-negation; smt_solve; UNSAT==proven.
}
fn atp_run_bv(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32) -> i32 {
    // TODO: smt_init; smt_bv_* bit-blast; smt_solve; UNSAT==proven.
}
fn atp_run_eq(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32) -> i32 {
    // TODO: eg_add nodes; eg_union axiom equalities; eg_rebuild; eg_saturate(budget);
    //       proven iff eg_find(lhs)==eg_find(rhs).
}
fn atp_run_poly(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32) -> i32 {
    // TODO: gb_init; build basis from axioms; gb_reduce(goal); proven iff remainder==0.
}
fn atp_build_term(goal: *u8, goal_len: u32, n_axioms: u32, class: u8) -> i32 {
    // TODO: pt_alloc(checked); per-axiom LIBRARY_CITE step (byte-store premise ids, W5);
    //       combinator step (CASE_ANALYSIS if n>=2 else MODUS_PONENS) concluding goal;
    //       pt_finalize(checked); pt_verify(checked)->APROVE_E_VERIFY on fail.
}
fn atp_witness(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32) -> i32 {
    // TODO: pt_serialize -> APROVE_SERIAL_BUF; keccak256_oneshot serial -> HASH_OUT (u64 ptrs);
    //       keccak256_oneshot(goal||axioms) -> HASH_IN; build PAYLOAD (byte-store stepcount, W5);
    //       wh_publish(...) -> check != APROVE_WH_FAIL else APROVE_E_WITNESS; copy frag id.
}

// -- Public entry --
fn atp_prove(req: *u8) -> i32 @export {
    // TODO: body per Algorithm 'atp_prove' Phases A-D.
    // A: inited? null? read req fields to locals; range checks; cap_verify_rights gate.
    // A: class = req.goal_ptr[0]; when-cascade dispatch (no select) to atp_run_*.
    // B: verdict -> proven? else map to E_NO_PROOF/E_TIMEOUT/E_BACKEND + record fail.
    // C: atp_build_term(...) ; D: atp_witness(...) ; copy out_term_id; HAS_RESULT=1; OK.
}

// -- Accessors --
fn atp_last_failure(out_rec: *u8) -> i32 @export {
    // TODO: null-check; copy APROVE_FAILREC[0..31] -> out_rec; return OK.
}
fn atp_last_term_id(out_term_id: *u8) -> i32 @export {
    // TODO: null-check; gate HAS_RESULT else E_NO_PROOF; ident_copy LAST_TERM_ID.
}
fn atp_last_frag_id(out_frag_id: *u8) -> i32 @export {
    // TODO: null-check; gate HAS_RESULT else E_NO_PROOF; ident_copy LAST_FRAG_ID.
}

// -- Self-test (99u64 = pass) --
fn atp_selftest() -> u64 @export {
    // TODO: build KAT requests 1-5 in scratch; assert returns + pt_verify positives +
    //       no-term/no-frag on negative; return 99u64 or 1-based failing index.
}
```
