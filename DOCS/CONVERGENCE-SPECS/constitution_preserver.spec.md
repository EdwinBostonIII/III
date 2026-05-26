# 19 numera/constitution_preserver.iii — Implementation Spec

## Verdict
PARTIAL — the candidate body delegates correctly to the LTL model checker (`tl_eval`) and the witness hook, and its public surface, slot table, and W14 sentinel-flag loops are structurally sound; but it carries (a) an off-by-one byte length in the producer-ID derivation (breaks deterministic witness identity, M2/M10), (b) a hardcoded `0..epoch_end` segment start that ignores the previous epoch boundary (incomplete enforcement, the body's own comment admits it), (c) a witness published **only on success** so failed epochs leave no chained Compliance Witness (M6 continuity gap), and (d) the `let mut ok` checkpoint-flag drives nested guards rather than the loop conditions (Trap 10 / known iiis-0 let-mut-flag + active-flag traps). The maximal form closes all four plus adds reversible epoch-boundary state and a `cp_clear`.

## Purpose
`numera::constitution_preserver` is the active enforcement organ of the constitution: at every epoch boundary it evaluates each ratified clause's LTL formula against the witness-chain segment for that epoch, emits a per-epoch **Constitutional Compliance Witness** (chained by hash to the prior chain root), and reports the verdict that gates Quiescence exit (exit is refused when any clause fails). It is a pure model-checker driver — it owns no temporal logic itself; it binds clause slots to formula slots and calls the recursion-free fixpoint evaluator in `temporal_logic.iii`. Hexad: `kind_witness` (its primary output is proofs about other modules' behavior). Ring: R−1. K-vector: 1.00.

## Public API
All public fns return a status (W12). Booleans are `u8` (W10: 1=holds, 0=fails). Error codes are negative `i32` compared by equality only (W9/W11). Every signature is single-line (Trap 1).

```
fn cp_init() -> i32 @export
fn cp_attach_clause(clause_slot: u32, formula_slot: u32) -> i32 @export
fn cp_detach_clause(clause_slot: u32) -> i32 @export
fn cp_verify_segment(start: u64, end: u64) -> u8 @export
fn cp_verify_epoch(epoch_end: u64) -> u8 @export
fn cp_last_failure(out_clause: *u8, out_position: *u64) -> i32 @export
fn cp_clear() -> i32 @export
```

- `cp_init() -> i32` — returns `CP_OK`; idempotent re-init clears the attachment table, the last-failure record, and the epoch cursor. Derives the producer/op identifiers once.
- `cp_attach_clause(clause_slot, formula_slot) -> i32` — `CP_OK` on success, `CP_E_FULL` if the table is exhausted, `CP_E_BAD` if a live attachment already binds this `clause_slot` (idempotent dedup; an append-only clause may be re-attached only after detach — W19 clauses are append-only, so attachments mirror that and are not silently overwritten).
- `cp_detach_clause(clause_slot) -> i32` — reversibility partner of attach (M9); `CP_OK` if a live row was cleared, `CP_E_BAD` if no live row bound that clause. (Addition over the gospel API; the gospel surface is preserved and only extended — append-only, W19.)
- `cp_verify_segment(start, end) -> u8` — evaluates every **live** attached formula at every position in `[start, end)`; returns 1 iff all hold, else records the first failure (clause id + position) and returns 0. Read-only except the last-failure record.
- `cp_verify_epoch(epoch_end) -> u8` — verifies `[CP_LAST_EPOCH_END, epoch_end)`, **publishes a Compliance Witness in both the success and failure cases** (verdict byte 1/0), advances `CP_LAST_EPOCH_END` to `epoch_end` only on success (a failed epoch is not consumed — the boundary is reversible/ratifiable, M16), and returns the verdict.
- `cp_last_failure(out_clause, out_position) -> i32` — `CP_OK` and writes the recorded clause id (32 bytes) + position; `CP_E_BAD` if no failure is recorded.
- `cp_clear() -> i32` — clears the last-failure record and resets the epoch cursor to 0 without dropping attachments (reversibility / re-verification support, M9). Returns `CP_OK`.

## Constant Namespace
PREFIX = `CPRES_`  (grep of `STDLIB/` for `CPRES_`: **no matches** — no collision; confirmed clear). The gospel candidate used the shorter `CP_` prefix; `CP_` is **not** grep-clean as a module-const namespace guarantee across 70+ numera modules, so this spec adopts the assigned `CPRES_` prefix on every module-level `const` and `var` (Trap 2 — module-level `const`/`var` emit linker-global `L_<NAME>` symbols; the prefix must be unique). Public function names retain the gospel's `cp_` verb prefix (function symbols are namespaced differently and the gospel API names are contractual).

| const | type | value | note |
|---|---|---|---|
| `CPRES_OK` | i32 | `0i32` | success (W9) |
| `CPRES_E_FULL` | i32 | `-1i32` | attachment table exhausted |
| `CPRES_E_BAD` | i32 | `-2i32` | bad/duplicate slot or no record |
| `CPRES_MAX_ATT` | u32 | `1024u32` | = `CONS_MAX_CLAUSES`; one attachment per clause |
| `CPRES_PRODUCER_LEN` | u64 | `30u64` | byte length of `"numera::constitution_preserver"` (**corrected from 29**) |
| `CPRES_COMPLY_LEN` | u64 | `38u64` | byte length of `"numera::constitution_preserver::comply"` |
| `CPRES_PILLAR` | u16 | `5u16` | constitutional pillar id for the witness |
| `CPRES_PAYLOAD_LEN` | u32 | `9u32` | epoch-end (8 LE bytes) + verdict (1 byte) |

## Data Structures
All module-scope, statically sized (W8). No local `var` arrays (Trap 7); the witness scratch buffers below are module-scope. The module is **not reentrant** — verification is serialized at an epoch boundary, which is single-threaded by construction; noted.

| name | type | size | bound justification |
|---|---|---|---|
| `CPRES_ATT_LIVE` | `[u8; 1024]` | 1024 | one liveness flag per attachable clause; bound = `CONS_MAX_CLAUSES` (W8) |
| `CPRES_ATT_CLAUSE` | `[u32; 1024]` | 1024 | constitution clause slot per attachment |
| `CPRES_ATT_FORMULA` | `[u32; 1024]` | 1024 | temporal-logic formula slot per attachment |
| `CPRES_LAST_CLAUSE_ID` | `[u8; 32]` | 32 | identifier of the clause of the last failure (Keccak256 width) |
| `CPRES_LAST_POSITION` | `u64` (=0) | scalar | chain position of the last failure |
| `CPRES_LAST_VALID` | `u8` (=0) | scalar | 1 iff a failure record is present |
| `CPRES_LAST_EPOCH_END` | `u64` (=0) | scalar | previous epoch boundary; segment start for `cp_verify_epoch` |
| `CPRES_PRODUCER_ID` | `[u8; 32]` | 32 | witness producer identifier |
| `CPRES_COMPLY_OPID` | `[u8; 32]` | 32 | Compliance-Witness operation identifier |
| `CPRES_INITED` | `u8` (=0) | scalar | init guard |
| `CPRES_IN_C` | `[u8; 32]` | 32 | witness `in_commit` scratch (was local `var` — hoisted to module scope, Trap 7) |
| `CPRES_OUT_C` | `[u8; 32]` | 32 | witness `out_commit` scratch (hoisted, Trap 7) |
| `CPRES_BUF` | `[u8; 16]` | 16 | epoch-end+verdict pre-image / payload scratch (hoisted, Trap 7) |
| `CPRES_FID` | `[u8; 32]` | 32 | fragment-id output scratch (hoisted, Trap 7) |

**Audit note (Trap 7):** the gospel body declared `var in_c : [u8;32]`, `var out_c`, `var buf`, `var fid` **inside** `cp_verify_epoch`. Local `var` arrays parse only at module scope in iiis-0 — these MUST be hoisted to module-scope (`CPRES_*`) buffers. This is the single most likely silent-compile/parse failure in the candidate and is corrected above.

## Dependencies (externs)
Multi-line `extern` declarations are house style (witness_hook.iii:144, constitution.iii gospel:3461) and are acceptable — Trap 1 governs `fn` *definitions* with bodies, not externs. Each extern is `@abi(c-msvc-x64)`.

| extern fn | from module | NN | built? |
|---|---|---|---|
| `ident_from_bytes(input:*u8,in_len:u64,out:*u8) -> i32` | identifier.iii | 01 | **built** |
| `ident_copy(src:*u8,dst:*u8) -> i32` | identifier.iii | 01 | **built** |
| `wh_publish(producer,opid,in_commit,out_commit,revtag:u8,phase:u8,pillar:u16,antecedents,n_ante:u32,payload,payload_len:u32,out_frag_id) -> u64` | witness_hook.iii | (built in `aether/`) | **built** |
| `wh_chain_root(out:*u8) -> i32` | witness_hook.iii | (built in `aether/`) | **built** |
| `tl_eval(slot:u32,chain_start:u64,chain_end:u64,position:u64) -> u8` | temporal_logic.iii | 14 | **NOT-YET-BUILT** |
| `cons_id_export(slot:u32,out_id:*u8) -> i32` | constitution.iii | 13 | **NOT-YET-BUILT** (also requires an append-only accessor add to Module 13) |

**Wave-scheduler note:** this module (19) must be ordered **after** Module 13 (constitution) and Module 14 (temporal_logic). The `from "witness_hook.iii"` extern path is what the gospel and temporal_logic.iii both use; the built copy lives at `aether/witness_hook.iii` — the linker resolves by module symbol, so the `from "witness_hook.iii"` token is correct as written (it matches `module numera_...`'s sibling resolution used by the already-passing constitution/temporal externs). No change required.

**`cons_id_export` provenance:** the gospel note (line 6565) specifies this as an *additional* accessor on `numera/constitution.iii`: it copies `CONS_ID[slot*32 .. slot*32+32]` into the caller's buffer and returns `CONS_OK` — the reverse of `cons_find`. Module 13's gospel body exposes `cons_id_ptr(slot) -> *u8` (a non-`@export` helper) and `cons_find`; `cons_id_export` is the missing `@export` wrapper. It is an **append-only** addition to Module 13 (W19) and is flagged here so Module 13's spec carries it.

## Algorithm
NIH (M1): no third-party code — only identifier/witness/temporal_logic/constitution externs, all in-tree. No ML (M3): the decision is the exact boolean conjunction of `tl_eval` over a finite position grid; no counting, no thresholds, no adaptation. No heuristics (M4): the verdict is the algebraic AND of every formula at every position. Determinism (M2)/bit-identity (W5): every input (segment endpoints, attachment table, formula contents, chain contents) is fixed; `tl_eval` is itself a deterministic fixpoint evaluator; the witness pre-image is a fixed little-endian byte layout; therefore the verdict and the published Compliance-Witness fragment id are byte-reproducible. No recursion (W15): all iteration is flat `while` over indices; the only "recursion" (subformula descent) lives inside `temporal_logic.iii`'s explicit-stack evaluator, not here.

**`cp_init`** — set `CPRES_ATT_LIVE[0..MAX) = 0`; derive `CPRES_PRODUCER_ID = ident_from_bytes("numera::constitution_preserver", 30)` and `CPRES_COMPLY_OPID = ident_from_bytes("numera::constitution_preserver::comply", 38)`; clear `CPRES_LAST_VALID`, `CPRES_LAST_EPOCH_END`; set `CPRES_INITED = 1`; return `CPRES_OK`. **Fix vs candidate:** length literal `30u64` (candidate had `29u64`, an off-by-one over `"numera::constitution_preserver"` = 8+22 = 30 bytes — wrong byte count yields a different producer identifier and thus a non-reproducible witness, violating M2/M10). `38u64` for the comply op-id is correct (30 + `::` + `comply` = 38) and is retained.

**`cp_attach_clause`** — first scan all live rows for an existing `CPRES_ATT_CLAUSE[i] == clause_slot` (dedup; return `CPRES_E_BAD` on collision so an append-only clause is never double-bound); then scan for the first `CPRES_ATT_LIVE[i] == 0`, set it live with the clause+formula slots, return `CPRES_OK`; return `CPRES_E_FULL` if none free. Both scans are sentinel-flag `while` loops (W14, no `break`). **Maximal-form change vs candidate:** the candidate omitted dedup and overwrote nothing (it just took the first free slot, allowing two attachments for the same clause). Dedup makes attachment a function of the clause set (determinism of the verify pass independent of attach order).

**`cp_detach_clause`** — sentinel-flag scan for the live row with matching `clause_slot`; clear its `CPRES_ATT_LIVE`; return `CPRES_OK`, else `CPRES_E_BAD`. (Reversibility partner, M9.)

**`cp_verify_segment(start, end)`** — clear `CPRES_LAST_VALID`. Outer loop over attachments `a = 0..MAX`; inner loop over `pos = start..end`. For each live attachment, read `f = CPRES_ATT_FORMULA[a]`, call `v = tl_eval(f, start, end, pos)`; if `v == 0`, record the failure (`cons_id_export(CPRES_ATT_CLAUSE[a], &CPRES_LAST_CLAUSE_ID)`, `CPRES_LAST_POSITION = pos`, `CPRES_LAST_VALID = 1`) and stop further work. Return the verdict `u8`.
  - **W14 / Trap 10 fix (load-bearing):** the candidate used `let mut ok = 1u8` and gated **inner statements** with `if ok == 1u8` while the loops kept iterating to their natural bound. Per the documented iiis-0 let-mut checkpoint-flag trap and the insertion-sort active-flag trap, the flag must **drive the loop condition itself**, not merely gate the body. Realize it with a fused continue-counter on each loop: e.g. outer `while a < CPRES_MAX_ATT` is replaced by a guard variable `go_a` that is set to `CPRES_MAX_ATT` (forcing loop exit) on first failure — `while a < go_a`, with `go_a` initialized to `CPRES_MAX_ATT` and assigned `a` (or `0`) at failure so the condition fails. Same transform on the inner `pos` loop (`pos_hi` shadow). This both fixes the trap and is the early-exit the gospel intends ("returns 0 on first failure"). No `break` (W14).
  - Determinism: positions are visited in fixed ascending order; the first failure in (attachment-index, position) lexicographic order is the recorded one — a total function of the inputs.

**`cp_verify_epoch(epoch_end)`** — `ok = cp_verify_segment(CPRES_LAST_EPOCH_END, epoch_end)`. Build the witness pre-image in `CPRES_BUF`: bytes 0..7 = `epoch_end` little-endian, byte 8 = verdict (`ok`). `wh_chain_root(&CPRES_IN_C)` for `in_commit`; `ident_from_bytes(&CPRES_BUF, 9, &CPRES_OUT_C)` for `out_commit` (binds endpoint+verdict). `wh_publish(&CPRES_PRODUCER_ID, &CPRES_COMPLY_OPID, &CPRES_IN_C, &CPRES_OUT_C, 0u8 /*revtag*/, 0u8 /*phase*/, CPRES_PILLAR, &CPRES_BUF /*antecedents, n_ante=0*/, 0u32, &CPRES_BUF /*payload*/, CPRES_PAYLOAD_LEN, &CPRES_FID)`. On `ok == 1`, advance `CPRES_LAST_EPOCH_END = epoch_end`. Return `ok`.
  - **M6 fix (load-bearing):** the candidate published the witness **only inside `if ok == 1u8`** — a failed epoch produced no fragment, breaking the "Compliance Witness per epoch" guarantee and the hash-chain continuity (M6/W16). The maximal form publishes in **both** cases with the verdict byte distinguishing them (1 success / 0 failure); the chain therefore records every epoch verdict and a failed epoch is itself a witnessed, ratifiable event (M16).
  - **M5/M2 fix (load-bearing):** the candidate hardcoded `cp_verify_segment(0u64, epoch_end)` (its own comment flags this as a build shortcut). The maximal form tracks `CPRES_LAST_EPOCH_END` so each epoch verifies exactly its own segment `[prev, end)` — the actual semantics the gospel intro states ("from the previous epoch end to epoch_end"). The cursor advances **only on success** so a failed epoch is not silently consumed (reversibility/no-bricking, M5/M9): re-running after remediation re-verifies the same segment.
  - **Trap 11:** no `%` anywhere. **Trap 3:** no signed ordering compares (`ok` tested by `== 1u8`/`== 0u8`). **Trap 4:** `epoch_end`/positions are `u64`; the `u32` clause/formula slots are passed as `u32` params (never as the base of pointer arithmetic), so no `as u64` mask is required — but the spec records that if a future change indexes a byte buffer by a `u32` slot it MUST mask `(slot as u64) & 0xFFFFFFFFu64` first. **Trap 5:** all byte stores into `CPRES_BUF` go through `*u8` indexing with `& 0xFFu64` extraction (the candidate's pattern, retained) — no `*u32` store-width hazard.

**`cp_last_failure`** — if `CPRES_LAST_VALID == 0` return `CPRES_E_BAD`; else `ident_copy(&CPRES_LAST_CLAUSE_ID, out_clause)`, `*out_position = CPRES_LAST_POSITION`, return `CPRES_OK`.

**`cp_clear`** — `CPRES_LAST_VALID = 0`, `CPRES_LAST_EPOCH_END = 0`; return `CPRES_OK` (reversibility, M9).

## KAT Vectors (>= 3)
These are the Phase-2 byte-for-byte acceptance gate. They exercise the preserver against a stub/real `temporal_logic` + `constitution`; the witness fragment ids are computed by the in-tree Keccak256 over the fixed pre-image, so they are reproducible.

1. **Empty-table pass.** `cp_init()`; with **no** attachments, `cp_verify_segment(0, 100)` → `1` (vacuous truth: AND over the empty clause set). `cp_verify_epoch(100)` → `1`; the published `out_commit` MUST equal `ident_from_bytes([0x64,0,0,0,0,0,0,0, 0x01], 9)` (epoch_end=100=0x64 LE, verdict=1) = `Keccak256(64 00 00 00 00 00 00 00 01)` truncated to the identifier's 32-byte form; assert the 32-byte `out_frag_id` returned is non-zero and deterministic across two runs (run twice, assert byte-equal).
2. **All-true clause holds.** Attach one clause whose formula slot is a `tl` `ALWAYS(ATOM)` with the atom a predicate that holds at every position of `[0,3)` (stub `tl_eval` returns 1). `cp_verify_segment(0, 3)` → `1`; `cp_last_failure(out, &pos)` → `CPRES_E_BAD` (no failure recorded). Verdict byte in the epoch witness = `0x01`.
3. **First failure recorded at exact position.** Attach a clause whose formula is false **only at position 2** of `[0,5)` (stub `tl_eval` returns 0 iff `position == 2`). `cp_verify_segment(0, 5)` → `0`; `cp_last_failure(out_clause, &pos)` → `CPRES_OK` with `pos == 2u64` and `out_clause` byte-equal to `cons_id_export(clause_slot)`. `cp_verify_epoch(5)` → `0`, **and a Compliance Witness IS published** with verdict byte `0x00` (asserts the M6 fix); `CPRES_LAST_EPOCH_END` MUST remain `0` (failed epoch not consumed — asserts the M5 fix).
4. **Dedup + detach.** `cp_attach_clause(7, 11)` → `CPRES_OK`; `cp_attach_clause(7, 12)` → `CPRES_E_BAD` (duplicate clause); `cp_detach_clause(7)` → `CPRES_OK`; `cp_attach_clause(7, 12)` → `CPRES_OK` (re-bind after detach). Asserts attach idempotence/reversibility (M9, W19).
5. **Producer-ID length regression.** Assert `CPRES_PRODUCER_ID == Keccak256("numera::constitution_preserver")` computed over **30** bytes (not 29); a 29-byte hash MUST NOT match. This is the direct guard for the off-by-one fix (M2/M10).

## Trap Exposure
| # | trap | exposed? | avoidance |
|---|---|---|---|
| 1 | multi-line `fn` decl | no (defs single-line); externs multi-line are OK | every `fn ... {` is single-line; externs are declarations, not bodies (house style) |
| 2 | module-level `const`/`var` linker-global | **yes** | every const/var prefixed `CPRES_`; grep of `STDLIB/` for `CPRES_` returned no matches |
| 3 | signed ordering compare SIGSEGV | no | no `i32`/`i64` `<`/`>`; statuses compared by `==`/`!=` only (W11) |
| 4 | u32-in-u64-slot garbage | latent | clause/formula slots passed as `u32` params, never as pointer-math base; spec mandates `& 0xFFFFFFFFu64` mask if ever indexed |
| 5 | `*u32` store width | no | all byte stores into `CPRES_BUF` go through `*u8` with `& 0xFFu64` |
| 6 | nested `/* */` | no | comments use `//` or single-level `/* */`; no nesting |
| 7 | local `var` arrays | **yes (candidate bug)** | the four `var` arrays in `cp_verify_epoch` hoisted to module-scope `CPRES_IN_C/OUT_C/BUF/FID` |
| 8 | `}\nelse {` | no | no `else` clauses used; cascaded `if` returns (house style) |
| 9 | em-dash in comment | **yes (risk)** | all comments use ASCII `--`, never `—` |
| 10 | `let mut` checkpoint-flag | **yes (candidate bug)** | the `ok` flag is refactored to drive each loop's **condition** (continue-counter / hi-shadow), not just gate the body; first-failure early-exit without `break` |
| 11 | `a % b` after call | no | no modulo anywhere |
| 12 | `@specialize *T` stride | no | module is not generic; no `@specialize` |

## Gap / Fix List
PARTIAL — the gospel candidate's gaps, each with the fix folded into the Algorithm above:

1. **Off-by-one producer length (M2/M10, correctness).** `ident_from_bytes(p1, 29u64, …)` over `"numera::constitution_preserver"` (30 bytes). → use `30u64` (`CPRES_PRODUCER_LEN`). Without this, the producer identifier — and therefore every Compliance-Witness fragment id — is non-reproducible. KAT 5 guards it.
2. **Hardcoded epoch start (M5/M2; gospel intro vs body mismatch).** `cp_verify_epoch` calls `cp_verify_segment(0u64, epoch_end)` and admits it in a comment. → track `CPRES_LAST_EPOCH_END`, verify `[prev, end)`, advance only on success. KAT 3 guards the no-consume-on-failure behavior.
3. **Witness only on success (M6/W16 continuity gap).** The candidate publishes inside `if ok == 1u8` only. → publish in **both** branches with verdict byte 1/0; a failed epoch is a witnessed, ratifiable event (M16). KAT 3 asserts the failure witness.
4. **`let mut ok` checkpoint-flag drives body, not loop (Trap 10 + active-flag trap).** The candidate's loops run to their full bound after failure, gating each statement with `if ok == 1u8`. → make the flag drive the loop condition (continue-counter / hi-shadow), giving a true first-failure early-exit with no `break` (W14). Behaviorally identical verdict; trap-safe and not wasteful.
5. **Local `var` arrays in `cp_verify_epoch` (Trap 7).** `var in_c/out_c/buf/fid` parse only at module scope in iiis-0. → hoist to `CPRES_IN_C/OUT_C/BUF/FID`. Likely a hard parse/codegen failure as written.
6. **No dedup / no detach (determinism + M9 reversibility).** Candidate allows two attachments per clause and offers no removal. → `cp_attach_clause` dedups (`CPRES_E_BAD` on duplicate); add `cp_detach_clause` and `cp_clear` (append-only-compatible, W19). KAT 4 guards it.
7. **Const prefix not namespace-safe.** Candidate uses `CP_` which is not grep-clean as a linker-global guarantee across 70+ numera modules. → rename every const/var to `CPRES_` (Trap 2). Public `cp_*` fn names retained (gospel-contractual).
8. **Dependency carry-over (not a defect, a scheduling note).** `cons_id_export` is an append-only `@export` accessor that Module 13's spec must add (gospel note, line 6565); `tl_eval` is Module 14. Both NOT-YET-BUILT — module 19 schedules after 13 and 14.

**M8 (capability) note:** verification is read-only (it mutates only the append-only witness chain and the last-failure record), so it is reversibility-safe (M9) and does not require a capability argument; the *enforcement* (refusing Quiescence exit) is the caller's gate keyed off the returned verdict. The gospel API is preserved; no capability parameter is added (W19/contract). Flagged for the auditor's awareness, resolved as compliant.

## Implementation Skeleton
Paste-ready structure. Single-line signatures. No fn bodies (Phase 2 writes those per Algorithm §). ASCII `--` only in comments (Trap 9).

```iii
/* III/STDLIB/iii/numera/constitution_preserver.iii
 *
 * III STDLIB - numera::constitution_preserver
 *
 * Active enforcement of constitutional clauses. Runs the temporal-logic
 * model checker for every clause's LTL formula against the current chain
 * segment and publishes a Constitutional Compliance Witness per epoch
 * (success AND failure). The model checker is the recursion-free fixpoint
 * form in temporal_logic.iii; this module owns no temporal logic itself.
 *
 * Public API:
 *   cp_init() -> i32
 *   cp_attach_clause(clause_slot: u32, formula_slot: u32) -> i32
 *   cp_detach_clause(clause_slot: u32) -> i32
 *   cp_verify_segment(start: u64, end: u64) -> u8
 *   cp_verify_epoch(epoch_end: u64) -> u8
 *   cp_last_failure(out_clause: *u8, out_position: *u64) -> i32
 *   cp_clear() -> i32
 *
 * Hexad: kind_witness.  Ring: R-1.  K: 1.00.
 * Discipline: W2, W8, W13, W14, W15 (no recursion). NIH: identifier,
 * witness_hook, temporal_logic, constitution only.
 */

module numera_constitution_preserver

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8,
              out_commit: *u8, revtag: u8, phase: u8, pillar: u16,
              antecedents: *u8, n_ante: u32,
              payload: *u8, payload_len: u32,
              out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn tl_eval(slot: u32, chain_start: u64, chain_end: u64, position: u64) -> u8 from "temporal_logic.iii"
extern @abi(c-msvc-x64) fn cons_id_export(slot: u32, out_id: *u8) -> i32 from "constitution.iii"

const CPRES_OK           : i32 =  0i32
const CPRES_E_FULL       : i32 = -1i32
const CPRES_E_BAD        : i32 = -2i32

const CPRES_MAX_ATT      : u32 = 1024u32
const CPRES_PRODUCER_LEN : u64 = 30u64    // "numera::constitution_preserver" -- 30 bytes (corrected)
const CPRES_COMPLY_LEN   : u64 = 38u64    // "numera::constitution_preserver::comply"
const CPRES_PILLAR       : u16 = 5u16
const CPRES_PAYLOAD_LEN  : u32 = 9u32     // 8 LE epoch-end bytes + 1 verdict byte

var CPRES_ATT_LIVE       : [u8;  1024]
var CPRES_ATT_CLAUSE     : [u32; 1024]
var CPRES_ATT_FORMULA    : [u32; 1024]

var CPRES_LAST_CLAUSE_ID : [u8; 32]
var CPRES_LAST_POSITION  : u64 = 0u64
var CPRES_LAST_VALID     : u8  = 0u8
var CPRES_LAST_EPOCH_END : u64 = 0u64

var CPRES_PRODUCER_ID    : [u8; 32]
var CPRES_COMPLY_OPID    : [u8; 32]
var CPRES_INITED         : u8  = 0u8

/* Witness scratch -- module-scope (Trap 7: no local var arrays). Not reentrant;
 * verification is serialized at the epoch boundary. */
var CPRES_IN_C           : [u8; 32]
var CPRES_OUT_C          : [u8; 32]
var CPRES_BUF            : [u8; 16]
var CPRES_FID            : [u8; 32]

fn cp_init() -> i32 @export {
    // TODO: body per Algorithm cp_init -- zero ATT_LIVE; derive PRODUCER_ID (len 30)
    // and COMPLY_OPID (len 38); clear LAST_VALID + LAST_EPOCH_END; set INITED; return CPRES_OK
}

fn cp_attach_clause(clause_slot: u32, formula_slot: u32) -> i32 @export {
    // TODO: body per Algorithm cp_attach_clause -- dedup scan (CPRES_E_BAD on dup),
    // then first-free scan (sentinel-flag while, no break); CPRES_E_FULL if none
}

fn cp_detach_clause(clause_slot: u32) -> i32 @export {
    // TODO: body per Algorithm cp_detach_clause -- clear matching live row; CPRES_E_BAD if none
}

fn cp_verify_segment(start: u64, end: u64) -> u8 @export {
    // TODO: body per Algorithm cp_verify_segment -- clear LAST_VALID; outer over
    // attachments, inner over positions; tl_eval each; on first 0 record failure
    // via cons_id_export + LAST_POSITION; flag drives loop CONDITIONS (Trap 10), no break
}

fn cp_verify_epoch(epoch_end: u64) -> u8 @export {
    // TODO: body per Algorithm cp_verify_epoch -- ok = cp_verify_segment(CPRES_LAST_EPOCH_END, epoch_end);
    // build CPRES_BUF (8 LE epoch-end bytes + verdict byte = ok); wh_chain_root -> CPRES_IN_C;
    // ident_from_bytes(CPRES_BUF,9) -> CPRES_OUT_C; wh_publish in BOTH cases (M6); advance
    // CPRES_LAST_EPOCH_END only when ok == 1u8; return ok
}

fn cp_last_failure(out_clause: *u8, out_position: *u64) -> i32 @export {
    // TODO: body per Algorithm cp_last_failure -- CPRES_E_BAD if !LAST_VALID; else copy id + position
}

fn cp_clear() -> i32 @export {
    // TODO: body per Algorithm cp_clear -- LAST_VALID = 0; LAST_EPOCH_END = 0; return CPRES_OK
}
```
