# 29 aether/boot_fold.iii — Implementation Spec

## Verdict
PARTIAL — the fold skeleton and witness routing are structurally sound and the externs are *mostly* against real symbols, but the body (a) externs the streaming Keccak from the WRONG file (`keccak.iii`, which does not export `keccak256_init/update/final`); (b) omits the prose-mandated *final-hash-vs-seed sanity check wired into execution*; (c) omits the prose-mandated *Distress Witness hard-halt* on mismatch / inadmissibility entirely; (d) uses five function-local `var` arrays (Trap 7) inside `bf_execute`; (e) leaves M8/M9 (capability gate + reversibility tag) unaddressed for a privileged boot operation. All are closable without changing the algebraic shape.

## Purpose
`aether::boot_fold` IS the boot sequence reified as a deterministic algebraic left-fold over the constitutional bootstrap list: `state_0 = empty`, `state_{n+1} = effect(clause_n, state_n)`, `final = state_N`. Each entry names a constitutional clause (whose admissibility predicate gates the step) and an effect operation id; the fold walks the list in order, evaluates the clause predicate against a synthetic boot operation profile, advances the state root by Keccak256-folding `(prev_root || op_id || ordinal)`, and publishes one `BOOT_STEP` witness fragment per entry chaining pre→post state roots. The final root is compared to the seed identifier; a mismatch is a hard halt that emits a Distress Witness. **Hexad:** `kind_motion + kind_witness`. **Ring:** R-2. **K:** 1.00.

## Public API
```
fn bf_init() -> i32 @export
fn bf_append_step(clause_id: *u8, effect_op_id: *u8) -> i32 @export
fn bf_execute(boot_cap: u64) -> i32 @export
fn bf_final_state_root(out_root: *u8) -> i32 @export
fn bf_verify_against_seed(target: *u8) -> u8 @export
fn bf_seal_root(out_root: *u8) -> i32 @export
```
Return conventions (W9/W12):
- `bf_init`/`bf_append_step`/`bf_final_state_root`/`bf_seal_root` return `i32` status (`BF_OK = 0`, negatives on error — W9). Every public fn returns a status or sentinel-typed value (W12).
- `bf_execute` returns `i32`: `BF_OK` on a fully-admitted, seed-matching fold; `BF_E_INADM` if any clause is unknown / inadmissible; `BF_E_CAP` if `boot_cap` lacks the boot right; `BF_E_SEED` if the final root ≠ recorded seed (after emitting the Distress Witness — M5: refusal, never bricking). Compared via `== / !=` only (W11).
- `bf_verify_against_seed` returns `u8` (0/1 — W10): 1 iff the *sealed* final root equals `target`.

`bf_execute` gains a `boot_cap: u64` parameter vs. the gospel (M8 capability mediation; see Gap/Fix #5). Still ≤ 4 params (W2).

## Constant Namespace
PREFIX = `BFOLD_`  (dispatch-assigned). The gospel body used the bare `BF_` prefix; grep of the built tree shows **no collision for either `BF_` or `BFOLD_`** (`grep -r "BFOLD_\|^const BF_\|^var BF_\|fn bf_" STDLIB/` → empty). Per the briefing's PREFIX directive and Trap 2 (module-level `const` is linker-global) the spec standardizes on the longer, future-proof `BFOLD_` for every module-scope `const` **and** every module-scope `var` (vars are also global symbols). Function names keep the established `bf_` verb prefix (function symbols are namespaced by the C-ABI export name and do not collide).

| const | type | value |
|---|---|---|
| `BFOLD_OK`        | i32 | `0i32` |
| `BFOLD_E_FULL`    | i32 | `-1i32` |
| `BFOLD_E_INADM`   | i32 | `-2i32` |
| `BFOLD_E_CAP`     | i32 | `-3i32` |
| `BFOLD_E_SEED`    | i32 | `-4i32` |
| `BFOLD_E_NOSEED`  | i32 | `-5i32` |
| `BFOLD_MAX_STEPS` | u32 | `512u32` |
| `BFOLD_ID_BYTES`  | u64 | `32u64` |
| `BFOLD_FOLD_LEN`  | u64 | `72u64`  (32 prev + 32 op_id + 8 ordinal) |
| `BFOLD_RIGHT_BOOT`| u64 | `<boot-right bit from capability.iii>` (see Dep note) |
| `BFOLD_REVTAG`    | u8  | `1u8`   (boot-fold steps are reversible-by-replay; W16) |

`CONS_SENT` (`0xFFFFFFFFu32`) is the absence sentinel owned by `constitution.iii`; boot_fold compares `cons_find`'s result to the literal `0xFFFFFFFFu32` directly (does **not** redeclare it — Trap 2).

## Data Structures
All module-scope (Trap 7: no local `var` arrays). Bound justification per W8.

| name | type | bytes | bound justification |
|---|---|---|---|
| `BFOLD_CLAUSE_ID` | `[u8; 16384]` | 16384 | `BFOLD_MAX_STEPS(512) * 32`. Boot list is a fixed constitutional artifact; 512 clauses bounds the entire bootstrap (the gospel's chosen ceiling). |
| `BFOLD_OP_ID`     | `[u8; 16384]` | 16384 | same — one 32-byte effect op id per step. |
| `BFOLD_LEN`       | `u32` (`= 0u32`) | 4 | current append count, `< BFOLD_MAX_STEPS`. |
| `BFOLD_STATE_ROOT`| `[u8; 32]` | 32 | running fold accumulator (the live state root). |
| `BFOLD_SEED`      | `[u8; 32]` | 32 | recorded seed identifier the final root must equal (set by `bf_init`-time `bf_set_seed`/copy; see Gap #2). |
| `BFOLD_SEALED`    | `[u8; 32]` | 32 | final root snapshot taken by `bf_seal_root`, the value `bf_verify_against_seed` checks (decouples "verify" from a still-mutating `BFOLD_STATE_ROOT`). |
| `BFOLD_PRODUCER`  | `[u8; 32]` | 32 | `ident("aether::boot_fold")`, the canonical step producer. |
| `BFOLD_OPID_STEP` | `[u8; 32]` | 32 | `ident("aether::boot_fold::step")`, the `BOOT_STEP` op id. |
| `BFOLD_INITED`    | `u8` (`= 0u8`) | 1 | one-time init guard. |
| `BFOLD_SEED_SET`  | `u8` (`= 0u8`) | 1 | 1 once a seed has been recorded (gates `BFOLD_E_NOSEED`). |
| `BFOLD_SCRATCH_PREV` | `[u8; 32]` | 32 | was local `var prev` — previous root copy for the fold buffer. |
| `BFOLD_SCRATCH_FOLD` | `[u8; 80]` | 80 | was local `var buf` — `prev||op||ordinal` fold preimage (72 used, 80 reserved as in gospel). |
| `BFOLD_SCRATCH_INC`  | `[u8; 32]` | 32 | was local `var in_c` — witness in-commit (chain root). |
| `BFOLD_SCRATCH_OUTC` | `[u8; 32]` | 32 | was local `var out_c` — witness out-commit (new state root). |
| `BFOLD_SCRATCH_FID`  | `[u8; 32]` | 32 | was local `var fid` — `wh_publish` fragment-id sink. |
| `BFOLD_SCRATCH_DW`   | `[u8; 96]` | 96 | distress payload: `expected(32)||actual(32)||ordinal(8)||reserved` for `dw_produce` on seed mismatch. |

**Reentrancy:** `bf_execute` is **not** reentrant (shared module-scope scratch + accumulator). This is correct and acceptable — boot folds exactly once at substrate bring-up; concurrent boot is meaningless. Noted per Trap 7.

## Dependencies (externs)
All `extern @abi(c-msvc-x64)`. NN = providing gospel module.

| extern | from | NN | built? |
|---|---|---|---|
| `fn ident_from_bytes(input:*u8, in_len:u64, out:*u8) -> i32` | `identifier.iii` | 01 | **BUILT** (lives in `numera/identifier.iii`; basename resolution makes the gospel's `from "identifier.iii"` correct) |
| `fn ident_copy(src:*u8, dst:*u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `fn ident_eq(a:*u8, b:*u8) -> u8` | `identifier.iii` | 01 | **BUILT** |
| `fn keccak256_init() -> i32` | `keccak256.iii` | (Stage-4 wrapper) | **BUILT** — gospel said `keccak.iii`; **WRONG**, fixed (Gap #1) |
| `fn keccak256_update(input:*u8, len:u64) -> i32` | `keccak256.iii` | — | **BUILT** |
| `fn keccak256_final(out:*u8) -> i32` | `keccak256.iii` | — | **BUILT** |
| `fn wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `witness_hook.iii` | 07 | **BUILT** (signature matches verbatim) |
| `fn wh_chain_root(out_id:*u8) -> i32` | `witness_hook.iii` | 07 | **BUILT** |
| `fn cons_find(clause_id:*u8) -> u32` | `constitution.iii` | 13 | **NOT-YET-BUILT** — `-> u32`, sentinel `0xFFFFFFFFu32` (confirmed in gospel §Module 13) |
| `fn cons_eval_predicate(slot:u32, op_producer:*u8, op_id:*u8, op_phase:u8, op_pillar:u16, op_revtag:u8, ante_ids:*u8, n_ante:u32) -> u8` | `constitution.iii` | 13 | **NOT-YET-BUILT** (signature confirmed verbatim in Module 13) |
| `fn cap_verify_rights(id:u64, required:u64) -> u8` | `capability.iii` | (built aether/capability.iii) | **BUILT** — added for M8 (Gap #5); read file for exact right-bit name to fill `BFOLD_RIGHT_BOOT` |
| `fn dw_produce(kind:u8, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `distress_witness.iii` | 48 | **NOT-YET-BUILT** — for the hard-halt Distress Witness (Gap #3); use `DW_KIND_AUDIT_FAILURE` |

**Not-yet-built deps to order before this module:** `constitution.iii` (NN 13), `distress_witness.iii` (NN 48). `distress_witness.iii` itself transitively depends on `node_identity.iii` (NN 28) and `context_awareness.iii` (NN 46) — boot_fold only needs `dw_produce`'s 4-arg surface, so the scheduler must merely have NN 13 and NN 48 land first.

> **Systemic defect note (§3.5):** defect #1 (keccak from wrong file) is PRESENT and fixed here. Defect #2 (`ws_emit_fragment`) — N/A: gospel already routes through `wh_publish`, correct. Defect #3 (`cons_find -> u32 / 0xFFFFFFFFu32`) — gospel already correct, preserved. Defect #4 (`at_now`) — N/A: boot_fold never calls algebraic time directly (time advances inside `wh_publish`). Defect #5 (`cap_verify` fiction) — boot_fold did NOT gate by capability at all; this spec ADDS `cap_verify_rights` (the real symbol). Defect #6 (witness_hook getters) — N/A: boot_fold publishes, does not read fragment fields.

## Algorithm

### `bf_init() -> i32`
NIH: direct field zeroing, no library. Set `BFOLD_LEN = 0`; sentinel-loop (W14, flag-free counter) zero `BFOLD_STATE_ROOT[0..31]` and `BFOLD_SEALED[0..31]`; derive `BFOLD_PRODUCER = ident_from_bytes("aether::boot_fold", 17)` and `BFOLD_OPID_STEP = ident_from_bytes("aether::boot_fold::step", 23)`; `BFOLD_SEED_SET = 0`; `BFOLD_INITED = 1`; return `BFOLD_OK`. Determinism (M2): output depends only on the two compile-time string literals → bit-identical (W5). No seed is fabricated here (a zero seed would be a heuristic — M4).

### `bf_set_seed(seed: *u8) -> i32` *(new helper, Gap #2)*
`ident_copy(seed, &BFOLD_SEED)`, `BFOLD_SEED_SET = 1`, return `BFOLD_OK`. The seed identifier is supplied by `node_identity` at bring-up (the substrate's recorded boot-image identity). Folded as the post-condition oracle, not derived inside boot_fold (M2: the comparison target is recorded input, not a self-consistent tautology — defeats the "verify against itself" anti-pattern).

### `bf_append_step(clause_id: *u8, effect_op_id: *u8) -> i32`
If `BFOLD_INITED == 0` call `bf_init()`. If `BFOLD_LEN >= BFOLD_MAX_STEPS` return `BFOLD_E_FULL` (W9). `off = (BFOLD_LEN as u64) * 32u64` — `BFOLD_LEN` is `u32`; mask is unnecessary because it is already `< 512` and the `as u64` of a value `< 2^32` is exact, but the cast is taken **after** widening (no pointer math on a raw u32). Sentinel-loop copy 32 bytes of `clause_id` and `effect_op_id` into the slot. `BFOLD_LEN = BFOLD_LEN + 1u32`. Return `BFOLD_OK`. Deterministic byte copy; reversible (append-only list, droppable by re-init — M9).

### `bf_execute(boot_cap: u64) -> i32`
1. **Capability gate (M8, Gap #5):** `if cap_verify_rights(boot_cap, BFOLD_RIGHT_BOOT) == 0u8 { return BFOLD_E_CAP }`. Privileged boot action requires an explicit capability arg.
2. **Init + seed guards:** `if BFOLD_INITED == 0u8 { return BFOLD_E_INADM }`; `if BFOLD_SEED_SET == 0u8 { return BFOLD_E_NOSEED }`.
3. **Fold (explicit iteration, W15 — no recursion):** counter `i : u32`, `0 → BFOLD_LEN`, single-flag sentinel pattern (`ok : u8`, W14, no `break`). For each `i` while `ok == 1u8`:
   - `cl_ptr = (&BFOLD_CLAUSE_ID as u64) + (i as u64)*32u64`, `op_ptr` similarly. (Pointer math uses `(i as u64)` where `i < 512`; value is exact, but per Trap 4 the index is widened **before** the multiply and the base is a `u64` address — no u32-in-u64 garbage.)
   - `cl_slot = cons_find(cl_ptr)`; `if cl_slot == 0xFFFFFFFFu32 { ok = 0u8 }` (Trap 3 / defect #3 — equality vs the u32 sentinel, never ordering).
   - If still `ok`: `admit = cons_eval_predicate(cl_slot, &BFOLD_PRODUCER, op_ptr, 0u8, 0u16, 0u8, cl_ptr, 1u32)`; `if admit == 0u8 { ok = 0u8 }`. (Boot_fold is the canonical producer of its own steps; the synthetic op profile is phase 0 / pillar 0 / revtag 0, antecedent = the clause id itself.)
   - If still `ok`: **state fold.** Copy `BFOLD_STATE_ROOT → BFOLD_SCRATCH_PREV` (sentinel loop). Build `BFOLD_SCRATCH_FOLD`: bytes `[0..31] = prev`, `[32..63] = op_ptr[0..31]`, `[64..71] = ordinal(i) little-endian` via 8 explicit byte masks `((ii >> 8k) & 0xFFu64) as u8` (no `%`, so Trap 11 N/A; byte stores through a `*u8` view, so Trap 5 N/A). `ident_from_bytes(&BFOLD_SCRATCH_FOLD, BFOLD_FOLD_LEN, &BFOLD_STATE_ROOT)` → new root = Keccak256 of the 72-byte preimage. Determinism (M2): root_{n+1} is a pure function of `(root_n, op_id_n, n)`; identical lists fold to identical roots cross-CPU (W5, Keccak is byte-exact). NIH: hashing is the substrate's own keccak256 (M1).
   - **Witness (M6/M10):** `wh_chain_root(&BFOLD_SCRATCH_INC)`; `ident_copy(&BFOLD_STATE_ROOT, &BFOLD_SCRATCH_OUTC)`; `wh_publish(&BFOLD_PRODUCER, &BFOLD_OPID_STEP, &BFOLD_SCRATCH_INC, &BFOLD_SCRATCH_OUTC, BFOLD_REVTAG, 0u8, 0u16, cl_ptr, 1u32, op_ptr, 32u32, &BFOLD_SCRATCH_FID)`. The `BOOT_STEP` fragment records pre-root (in_commit), post-root (out_commit), clause id (antecedent), and ordinal (encoded into the folded root); it is byte-recomputable from `(prev_root, op_id, i)` (M10). `revtag = BFOLD_REVTAG = 1` marks the step reversible (W16).
   - `i = i + 1u32` (advance the counter unconditionally; the `ok` flag gates the *work*, not the *increment* — avoids the insertion-index clobber family the project memory warns about).
4. **Inadmissibility halt (M5 — refusal, not bricking):** `if ok == 0u8 { dw_produce(DW_KIND_AUDIT_FAILURE, &BFOLD_SCRATCH_DW, <len>, &BFOLD_SCRATCH_FID); return BFOLD_E_INADM }`.
5. **Seed sanity (prose-mandated, Gap #2):** `let m : u8 = ident_eq(&BFOLD_STATE_ROOT, &BFOLD_SEED)`. `if m == 0u8 {` build `BFOLD_SCRATCH_DW` = `BFOLD_SEED(32) || BFOLD_STATE_ROOT(32) || BFOLD_LEN(8)`; `dw_produce(DW_KIND_AUDIT_FAILURE, &BFOLD_SCRATCH_DW, 72u32, &BFOLD_SCRATCH_FID)`; `return BFOLD_E_SEED }` — **hard halt with immediate Distress Witness** exactly as the prose requires; M5-safe (the substrate refuses to proceed; nothing is bricked, the fold is replayable).
6. **Seal:** `bf_seal_root(&BFOLD_SEALED)` (snapshot the matched final root); return `BFOLD_OK`.

### `bf_final_state_root(out_root: *u8) -> i32`
`ident_copy(&BFOLD_STATE_ROOT, out_root)`; return `BFOLD_OK`. (Live root — may differ from sealed if `bf_execute` halted; callers wanting the *accepted* boot root read `bf_seal_root`.)

### `bf_seal_root(out_root: *u8) -> i32`
`ident_copy(&BFOLD_SEALED, out_root)`; return `BFOLD_OK`. The sealed root is set only on a fully-admitted, seed-matching fold (step 6), so it is the canonical "this boot succeeded" commitment.

### `bf_verify_against_seed(target: *u8) -> u8`
`return ident_eq(&BFOLD_SEALED, target)` — checks the **sealed** root (W10: 0/1). Constant-time equality via `ident_eq` (no early-out timing leak). The gospel compared the *live* `BFOLD_STATE_ROOT`, which is wrong when a fold halted mid-way; the spec checks the sealed value.

## KAT Vectors (>= 3)
The self-test (`bf_kat() -> u64`, `99 = pass`) seeds a deterministic two-step list and asserts the folded roots byte-for-byte. All clause/op ids are fixed module-scope buffers so the KAT is reproducible. Keccak vectors anchor on the **proven** keccak256 KAT (`Keccak256("abc")[0]=0x4e, [31]=0x45`) already in `keccak256.iii`.

1. **Empty fold root = init root.** `bf_init()`; no steps; `bf_final_state_root(r)` → `r == BFOLD_STATE_ROOT == 32 zero bytes`. (`r[0]==0x00 … r[31]==0x00`.) Establishes `state_0 = empty`.
2. **Single-step fold is Keccak256 of the 72-byte preimage.** `bf_init()`; set `op_id = [0x11;32]`; manually fold once: preimage `= 32 zero || 0x11*32 || ordinal 0 (8 zero bytes)`. Expected `BFOLD_STATE_ROOT == keccak256_oneshot(preimage, 72)` computed by the test harness with the same `keccak256.iii` → assert all 32 bytes equal. (Proves the fold function = `Keccak256(prev||op||ord)` exactly; ties the determinism claim to a byte-exact oracle.)
3. **Two-step determinism + order-sensitivity.** Append `(op=A)` then `(op=B)`; record `root_AB`. Re-`bf_init()`, append `(op=B)` then `(op=A)`; record `root_BA`. Assert `root_AB != root_BA` (ordinal is folded in → the fold is non-commutative, i.e. order-sensitive as a boot sequence must be). Then re-run the `A,B` order a second time and assert `root_AB' == root_AB` byte-for-byte (cross-run bit-identity, M2/W5).
4. **Seed mismatch is refused, not silent.** `bf_set_seed([0xEE;32])` (a seed that cannot equal any real fold root); run a one-step `bf_execute(valid_cap)` → expect return `BFOLD_E_SEED` (i.e. `-4i32`) AND `bf_verify_against_seed(&BFOLD_STATE_ROOT) == 0u8` (sealed root was never set because the fold was refused). Proves the negative case (memory: "prove every gate FAILS on bad input").
5. **Capability gate denies a zero cap.** `bf_execute(0u64)` (no rights) → expect `BFOLD_E_CAP` (`-3i32`) with `BFOLD_LEN` unchanged and no fragment published. (Requires `capability.iii` + a test cap minted with `BFOLD_RIGHT_BOOT` for the positive path in KAT 4.)

> KATs 1–3 are self-contained (only `keccak256.iii` + `identifier.iii`, both built) and run in Phase 2 immediately. KATs 4–5 are gated on `constitution.iii` / `distress_witness.iii` / `capability.iii`; the harness skips them with a recorded SKIP until those land, then they become the full acceptance gate.

## Trap Exposure
- **Trap 1 (multi-line `fn`):** every signature above is single-line — including the 12-arg `wh_publish` extern, which MUST stay on one line in the skeleton (the gospel wraps it across 4 lines; this spec keeps the extern declaration one logical line — see skeleton note). Avoidance: emit each `fn`/`extern fn` on a single physical line.
- **Trap 2 (module-level `const`/`var` are linker-global):** every const and var is `BFOLD_`-prefixed; grep-confirmed collision-free. `CONS_SENT` is NOT redeclared (compared as the `0xFFFFFFFFu32` literal).
- **Trap 3 (signed ordering SIGSEGV):** all comparisons in the module are unsigned (`u8`/`u32`/`u64`) or equality against negative-i32 status (W11). The `cl_slot == 0xFFFFFFFFu32` test is unsigned equality. No `< / <= / > / >=` on any `i32`/`i64`.
- **Trap 4 (u32-in-u64 slot garbage):** the only pointer arithmetic is `(&ARR as u64) + (i as u64)*32u64` where `i : u32 < 512`. `i` is widened with `as u64` *before* the multiply and added to a true `u64` base. To be defensive the skeleton masks `(i as u64) & 0xFFFFFFFFu64` at each index site (cost-free, removes any doubt).
- **Trap 5 (u32 pointer store width):** the ordinal bytes and all id copies are written through `*u8` views one byte at a time (`bp[k] = (...) as u8`); no `*u32` stores of u32 locals. Safe.
- **Trap 6 (nested `/* */`):** comments are flat; inner annotations use `//` or `(...)`. No nesting.
- **Trap 7 (local `var` arrays):** the gospel's five function-local arrays (`prev`, `buf`, `in_c`, `out_c`, `fid`) are **hoisted to module scope** (`BFOLD_SCRATCH_*`). Documented non-reentrant; acceptable (single boot).
- **Trap 8 (`} else {` one line):** any else in the byte-encode/guards is written `} else {` on one line. (The fold uses flag-gated `if`s, minimal else.)
- **Trap 9 (em-dash in comment):** all comments use ASCII `--`; no U+2014.
- **Trap 10 (`let mut` checkpoint flag):** `bf_execute`'s `ok : u8` flag drives the `while` condition itself (`while i < BFOLD_LEN` with inner `if ok == 1u8` work-gate and unconditional increment) — it is a loop-body gate, not a one-shot checkpoint; this is the project-blessed pattern. No mutated-flag-as-checkpoint misuse.
- **Trap 11 (`a % b` after call):** **N/A** — no modulo anywhere; ordinal encoding is pure shift+mask.
- **Trap 12 (`@specialize *T` stride):** **N/A** — module is not generic; all arrays are concrete `[u8; N]`.

## Gap / Fix List
1. **Keccak extern from wrong file (systemic defect #1) — FIX.** Gospel lines export `keccak256_init/update/final from "keccak.iii"`. `keccak.iii` exports only `keccak_state_zero / keccak_f1600 / keccak_absorb / keccak_squeeze / keccak_pack_rate_dom` (grep-confirmed). Change all three `from "keccak.iii"` → `from "keccak256.iii"`. (The streaming API is genuinely provided by `keccak256.iii`.) *Note:* boot_fold actually only needs `ident_from_bytes` (which internally hashes), so the three keccak externs are arguably unused by the realized algorithm — but they are kept (corrected) in case Phase 2 prefers direct streaming for the fold; if unused at implementation time, **drop them** rather than ship dead externs.
2. **Prose-mandated final-hash-vs-seed check is not wired into execution — FIX.** Prose: "The final state is hashed and compared to the seed identifier ...; the comparison failing is a hard halt." The gospel `bf_execute` never compares to a seed, and `bf_verify_against_seed` (a) is never called by execute and (b) compares the *live* root, not a recorded seed. Fix: add `BFOLD_SEED` + `bf_set_seed` (seed = recorded boot-image identity from node_identity), and step 5 of `bf_execute` performs the `ident_eq(final, seed)` comparison and returns `BFOLD_E_SEED` on mismatch. (The prose says "hashed" — the running fold root IS already a Keccak256 chain; comparing the final fold root to the recorded seed satisfies it. If node_identity records the seed as `Keccak256(final_root)` rather than the root itself, Phase 2 must re-hash `BFOLD_STATE_ROOT` once before the compare; the spec's `bf_seal_root` is the hook for that one extra hash. Decide against node_identity's actual seed schema when NN 28 lands.)
3. **Prose-mandated Distress Witness on hard-halt is absent — FIX.** Both the inadmissibility halt and the seed-mismatch halt must "produce an immediate Distress Witness." Gospel emits none. Fix: extern `dw_produce` from `distress_witness.iii` (NN 48) and call it with `DW_KIND_AUDIT_FAILURE` and a payload carrying `(expected_seed, actual_root, ordinal)` before returning the error. (`distress_witness.iii` is not-yet-built → flagged for the scheduler.)
4. **Five function-local `var` arrays (Trap 7) — FIX.** `prev[32]`, `buf[80]`, `in_c[32]`, `out_c[32]`, `fid[32]` inside `bf_execute` are local `var` arrays; iiis only parses `var` arrays at module scope. Hoist to `BFOLD_SCRATCH_PREV/_FOLD/_INC/_OUTC/_FID` (done in Data Structures). Without this the body will not compile.
5. **No capability mediation (M8) — FIX.** Boot is a maximally privileged action; the gospel `bf_execute()` takes no capability. Per M8 + systemic defect #5 (use the *real* `cap_verify_rights`, not the fictional `cap_verify`), add `boot_cap: u64` and gate with `cap_verify_rights(boot_cap, BFOLD_RIGHT_BOOT)`. Read `aether/capability.iii` for the exact boot/admin right-bit constant to assign `BFOLD_RIGHT_BOOT`.
6. **No reversibility tag on the witness (M9/W16) — FIX (minor).** Gospel publishes with `revtag = 0u8`. Boot steps are reversible-by-replay (the whole fold is a pure function of the recorded list + seed); set `revtag = BFOLD_REVTAG = 1u8` so the witness chain records reversibility (W16: fragments produced under reversibility).
7. **`bf_verify_against_seed` checks the wrong buffer — FIX (minor).** It compares the live `BFOLD_STATE_ROOT`; after a halt that is a partial root. Point it at `BFOLD_SEALED` (set only on success). Behavior on the happy path is unchanged; the failure path becomes correct.
8. **Verified-correct (no change):** the core left-fold shape, ordinal little-endian byte encoding, `cons_find`/`cons_eval_predicate` signatures and the `0xFFFFFFFFu32` sentinel gate, the `wh_publish` argument order, the `wh_chain_root`→in_commit / new-root→out_commit witness wiring, the `bf_append_step` bounds check, and the `BFOLD_MAX_STEPS = 512` bound all match the realized substrate and the mandates. No ML/heuristic/float anywhere (M2/M3/M4). Cost is bounded: ≤ 512 steps, each O(1) hash+publish (M19).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/boot_fold.iii  -- Layer 6, Module 29.
 *
 * Boot as an algebraic fold over the constitutional bootstrap list:
 *   state_0   = empty (32 zero bytes)
 *   state_n+1 = Keccak256( state_n || op_id_n || ordinal_n )
 *   final     = state_N, sealed iff it equals the recorded seed identity.
 * One BOOT_STEP witness fragment per entry (pre-root -> post-root, clause
 * antecedent).  Inadmissible clause or seed mismatch -> hard halt + Distress
 * Witness (M5 refusal, never bricking).  Capability-gated (M8).
 *
 * Hexad: kind_motion + kind_witness.  Ring: R-2.  K: 1.00.
 * Discipline: W2, W8, W9, W10, W11, W12, W14, W15, W16.
 */
module aether_boot_fold

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"
extern @abi(c-msvc-x64) fn cons_eval_predicate(slot: u32, op_producer: *u8, op_id: *u8, op_phase: u8, op_pillar: u16, op_revtag: u8, ante_ids: *u8, n_ante: u32) -> u8 from "constitution.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn dw_produce(kind: u8, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "distress_witness.iii"
// NOTE: keccak256_init/update/final are NOT externed here -- bf folds via
// ident_from_bytes (which hashes internally).  If Phase 2 streams directly,
// add them with `from "keccak256.iii"` (NOT "keccak.iii"; see Gap #1).

const BFOLD_OK        : i32 =  0i32
const BFOLD_E_FULL    : i32 = -1i32
const BFOLD_E_INADM   : i32 = -2i32
const BFOLD_E_CAP     : i32 = -3i32
const BFOLD_E_SEED    : i32 = -4i32
const BFOLD_E_NOSEED  : i32 = -5i32
const BFOLD_MAX_STEPS : u32 = 512u32
const BFOLD_ID_BYTES  : u64 = 32u64
const BFOLD_FOLD_LEN  : u64 = 72u64
const BFOLD_REVTAG    : u8  = 1u8
// const BFOLD_RIGHT_BOOT : u64 = <fill from aether/capability.iii right-bit>

var BFOLD_CLAUSE_ID   : [u8; 16384]   // 512 * 32
var BFOLD_OP_ID       : [u8; 16384]
var BFOLD_LEN         : u32 = 0u32
var BFOLD_STATE_ROOT  : [u8; 32]
var BFOLD_SEED        : [u8; 32]
var BFOLD_SEALED      : [u8; 32]
var BFOLD_PRODUCER    : [u8; 32]
var BFOLD_OPID_STEP   : [u8; 32]
var BFOLD_INITED      : u8 = 0u8
var BFOLD_SEED_SET    : u8 = 0u8
var BFOLD_SCRATCH_PREV : [u8; 32]
var BFOLD_SCRATCH_FOLD : [u8; 80]
var BFOLD_SCRATCH_INC  : [u8; 32]
var BFOLD_SCRATCH_OUTC : [u8; 32]
var BFOLD_SCRATCH_FID  : [u8; 32]
var BFOLD_SCRATCH_DW   : [u8; 96]

fn bf_init() -> i32 @export {
    // TODO: body per Algorithm bf_init -- zero state/sealed, derive producer + step opid, clear seed_set, set inited.
}

fn bf_set_seed(seed: *u8) -> i32 @export {
    // TODO: body per Algorithm bf_set_seed -- ident_copy seed into BFOLD_SEED, set BFOLD_SEED_SET = 1. (Gap #2)
}

fn bf_append_step(clause_id: *u8, effect_op_id: *u8) -> i32 @export {
    // TODO: body per Algorithm bf_append_step -- init-guard, BFOLD_E_FULL bound, 32-byte copy into both slots, BFOLD_LEN += 1.
}

fn bf_execute(boot_cap: u64) -> i32 @export {
    // TODO: body per Algorithm bf_execute --
    //   (1) cap_verify_rights gate -> BFOLD_E_CAP
    //   (2) inited + seed_set guards -> BFOLD_E_INADM / BFOLD_E_NOSEED
    //   (3) sentinel while i < BFOLD_LEN, flag ok, unconditional i increment:
    //         cons_find (== 0xFFFFFFFFu32 sentinel), cons_eval_predicate,
    //         fold BFOLD_STATE_ROOT = ident_from_bytes(prev||op||ordinal, 72),
    //         wh_publish BOOT_STEP (revtag = BFOLD_REVTAG).
    //   (4) ok==0 -> dw_produce(AUDIT_FAILURE) ; return BFOLD_E_INADM
    //   (5) ident_eq(final, seed)==0 -> dw_produce(AUDIT_FAILURE) ; return BFOLD_E_SEED
    //   (6) bf_seal_root(&BFOLD_SEALED) ; return BFOLD_OK
}

fn bf_final_state_root(out_root: *u8) -> i32 @export {
    // TODO: ident_copy(&BFOLD_STATE_ROOT, out_root) ; return BFOLD_OK.
}

fn bf_seal_root(out_root: *u8) -> i32 @export {
    // TODO: ident_copy(&BFOLD_SEALED, out_root) ; return BFOLD_OK.
}

fn bf_verify_against_seed(target: *u8) -> u8 @export {
    // TODO: return ident_eq(&BFOLD_SEALED, target).  (Gap #7 -- sealed, not live.)
}

// ---- self-test (99 = pass), KATs 1-3 self-contained; 4-5 gated on NN 13/48/cap ----
var BFOLD_T_OPA : [u8; 32]
var BFOLD_T_OPB : [u8; 32]
var BFOLD_T_REF : [u8; 32]
var BFOLD_T_R1  : [u8; 32]
var BFOLD_T_R2  : [u8; 32]

fn bf_kat() -> u64 @export {
    // TODO: bodies per KAT Vectors 1-5 -- empty root all-zero; single-step == keccak256_oneshot(preimage,72);
    //   two-step order-sensitivity + cross-run identity; seed-mismatch refusal; zero-cap denial. Return 99u64 on pass.
}
```
