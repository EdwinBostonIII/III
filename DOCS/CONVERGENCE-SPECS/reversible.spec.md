# 05 numera/reversible.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally close and idiomatic, but it (a) calls a non-existent extern `bigint_drop_ext` (the real symbol is `bigint_drop`), (b) depends on an unbuilt indirect-call primitive module `rev_invoke.iii`, (c) violates W2 in two functions (`rev_record4` = 6 params, `rev_invoke_undo` = 5 params), (d) carries a structural non-LIFO log-overlap / permanent-orphan leak in its per-slot `[start,end)` range model with no compaction function, (e) can perform an indirect call through a null function pointer in `rev_rollback` (M5 brick risk), and (f) emits no witness continuity on commit/rollback and does no capability mediation of the memory-restore undo (M6/M8/M10/W16 gaps). Each is closed in the Gap/Fix list below; the maximal design is an explicit envelope **stack** with capability-scoped envelopes and witnessed rollback.

## Purpose
`numera::reversible` is the substrate's **transactional envelope**: the ontological embodiment of M9 (reversibility-by-default). State-mutating operations execute inside a reversible scope that records a **backward continuation** (a tagged undo record) for every effect. On `commit` the effects persist and the undo log is discarded; on `rollback` every recorded undo is replayed in strict reverse order, restoring the prior state. Undo kinds are extensible via a boot-time tag→undo-fn dispatch table. **Hexad:** `kind_essence` (it IS the property of being undoable, not a service that does undo). **Ring:** R-1 (sub-kernel transactional substrate). **K-vector:** 0.99 in the gospel header (envelope-slot / record-log exhaustion is the only non-totality); this spec keeps K = 0.99 — adding witness emission does not lower K because witness publication degrades to a no-op pre-boot rather than failing the transaction.

## Public API
All signatures are **single-line** (Trap 1). Return conventions noted per fn (W9/W10/W12).

```
fn rev_init() -> i32 @export
```
Idempotent boot: clears slot/tag tables, resets the record log, registers the five built-in undo tags. Returns `REV_OK` / negative `REV_E_*`. (W9/W12.)

```
fn rev_register_undo(tag: u32, undo_fn: u64) -> i32 @export
```
Register an undo function (address as `u64`, callee ABI `fn(a,b,c,d:u64)->i32`) for `tag` in `[1, REV_MAX_TAGS)`. Tag 0 is reserved. Returns `REV_OK` / `REV_E_BAD_TAG`. (W9/W12.)

```
fn rev_begin(cap: u64) -> u32 @export
```
Begin a new envelope; pushes onto the envelope stack. `cap` is the capability token authorizing the effects this envelope will record (M8); `0u64` is the ambient/unprivileged capability (memory-restore undos refused — see Gap E). Returns the slot id (`0 .. REV_MAX_SLOTS-1`) or the sentinel `REV_SLOT_NONE` (`0xFFFFFFFFu32`) on exhaustion. **Sentinel-typed return** (W12); the caller distinguishes failure by `== REV_SLOT_NONE`. (Gospel widens the signature from `rev_begin()` to `rev_begin(cap)` — Gap E; still ≤4 params, W2-OK.)

```
fn rev_record(slot: u32, tag: u32, a: u64, b: u64) -> i32 @export
```
Append a 2-arg undo record (`c=d=0`) to the **top** envelope identified by `slot`. Returns `REV_OK` / `REV_E_BAD_SLOT` / `REV_E_BAD_TAG` / `REV_E_OOM_LOG` / `REV_E_NOT_TOP` / `REV_E_CAP`. (W9/W12.) **4 params — W2-OK.**

```
fn rev_record_quad(slot: u32, tag: u32, quad: *u64) -> i32 @export
```
Append a 4-arg undo record; `quad` points to 4 contiguous `u64` (`a,b,c,d`). **Replaces the gospel's 6-param `rev_record4`** (Gap F / W2). Same return set as `rev_record`. **3 params — W2-OK.**

```
fn rev_commit(slot: u32) -> i32 @export
```
Commit (and pop) the top envelope: discard its undo records without invoking them, truncating the log. Returns `REV_OK` / `REV_E_BAD_SLOT` / `REV_E_NOT_TOP`. Publishes a commit witness fragment when the witness hook is booted (M6/W16). (W9/W12.)

```
fn rev_rollback(slot: u32) -> i32 @export
```
Invoke every undo record of the top envelope in reverse order, then pop the slot and truncate the log. Skips records whose `fn_addr == 0u64` (M5). Publishes a rollback witness fragment when booted (M6/M10/W16). Returns `REV_OK` / `REV_E_BAD_SLOT` / `REV_E_NOT_TOP`. (W9/W12.)

```
fn rev_nest_begin(slot: u32) -> u32 @export
```
Return a checkpoint (current `END` of `slot`) that can later be individually rolled back without disturbing earlier records of the same envelope. Returns the checkpoint index or `REV_SLOT_NONE` on bad slot. **Sentinel-typed return** (W12).

```
fn rev_nest_rollback(slot: u32, checkpoint: u32) -> i32 @export
```
Roll back the top envelope's records down to `checkpoint` (must satisfy `START <= checkpoint <= END`), replaying undos in reverse, leaving records below `checkpoint` intact. Returns `REV_OK` / `REV_E_BAD_SLOT` / `REV_E_NOT_TOP` / `REV_E_BAD_CKPT`. (W9/W12.)

```
fn rev_compact() -> i32 @export
```
**New (Gap C).** Deterministically reclaim orphaned record space: because envelopes are a strict stack, `REV_REC_USED` always equals the top live slot's `END` (or 0 if none); this fn re-derives and asserts that invariant, returning `REV_OK` or `REV_E_INVARIANT` if a non-stack mutation is ever detected. No hidden GC, no observation — pure invariant restoration (M3/M4 clean). (W9/W12.)

```
fn rev_depth() -> u32 @export
```
Diagnostic: number of live (stacked) envelopes. Used by self-tests to detect slot leaks. Returns count `0 .. REV_MAX_SLOTS`. (Sentinel-free pure value.)

```
fn rev_records_used() -> u32 @export
```
Diagnostic: current `REV_REC_USED`. Used by KATs to assert log truncation on commit/rollback. Pure value.

Internal (non-`@export`) helpers: `rev_alloc_slot() -> u32`, `_rev_is_top(slot: u32) -> u8`, and the five built-in undo bodies (`rev_undo_mem_u8`, `rev_undo_mem_u64`, `rev_undo_drop_bigint`, `rev_undo_release_slot`, `rev_undo_witness_revoke`), each `fn(a,b,c,d:u64)->i32` (4 params — W2-OK; this is the mandated trampoline callee shape).

## Constant Namespace
**PREFIX = `REV_`** — grep over `STDLIB/iii/numera`, `STDLIB/iii/sanctus`, `STDLIB/iii/omnia`, and a tree-wide module/public-fn scan returned **no collision** (`grep "^const REV_"`, `numera_reversible`, and every public `rev_*` name = no matches outside this not-yet-built module; the broad whole-tree ripgrep timed out on the OneDrive tree, but each targeted directory scan and the unique module-name scan were clean). Module name `numera_reversible` is unique.

| const | type | value | note |
|---|---|---|---|
| `REV_OK` | i32 | `0i32` | success (W9) |
| `REV_E_OOM_SLOT` | i32 | `-1i32` | envelope slot table full |
| `REV_E_OOM_LOG` | i32 | `-2i32` | record log full |
| `REV_E_BAD_SLOT` | i32 | `-3i32` | slot oob / not live |
| `REV_E_BAD_TAG` | i32 | `-4i32` | tag oob / 0 / unregistered |
| `REV_E_BAD_CKPT` | i32 | `-5i32` | checkpoint out of `[start,end]` |
| `REV_E_NOT_TOP` | i32 | `-6i32` | **new (Gap C/H)**: commit/record/rollback on a non-top envelope (LIFO violated) |
| `REV_E_CAP` | i32 | `-7i32` | **new (Gap E)**: effect requires a capability the envelope lacks |
| `REV_E_INVARIANT` | i32 | `-8i32` | **new (Gap C)**: `rev_compact` detected a non-stack log state |
| `REV_SLOT_NONE` | u32 | `0xFFFFFFFFu32` | **new**: explicit sentinel for `rev_begin`/`rev_nest_begin`/`rev_alloc_slot` (was a bare literal in the gospel) |
| `REV_MAX_SLOTS` | u32 | `64u32` | envelope stack depth bound (W8) |
| `REV_MAX_RECORDS` | u32 | `8192u32` | undo-record log bound (W8) |
| `REV_MAX_TAGS` | u32 | `256u32` | undo-tag table bound (W8) |
| `REV_TAG_MEM_RESTORE_U8` | u32 | `1u32` | a=addr, b=old_value (low byte) |
| `REV_TAG_MEM_RESTORE_U64` | u32 | `2u32` | a=addr, b=old_value |
| `REV_TAG_DROP_BIGINT` | u32 | `3u32` | a=bigint_id |
| `REV_TAG_RELEASE_SLOT` | u32 | `4u32` | a=slot_table_addr, b=slot_idx |
| `REV_TAG_WITNESS_REVOKE` | u32 | `5u32` | a=fragment_index |
| `REV_WIT_OPID_LEN` | u64 | `26u64` | byte length of the witness op-id string literals (commit/rollback) |

(`REV_SLOT_NONE` is introduced so the sentinel `0xFFFFFFFFu32` is named once and reused — it is a constant, not a runtime value, so no W1/W3 concern.)

## Data Structures
All module-scope (Trap 7 — no local `var` arrays). Reentrancy: the entire module is **single-threaded / non-reentrant** (shared mutable slot stack + record log); acceptable for the serialized substrate (same posture as `bigint.iii`'s slot table). **Undo bodies MUST NOT call back into `rev_record*`/`rev_rollback`** (would corrupt the shared log — see Gap H).

| name | type | size | bound justification (W8) |
|---|---|---|---|
| `REV_SLOT_LIVE` | `[u8; 64]` | 64 | one byte per envelope; `REV_MAX_SLOTS`. 64 simultaneous nested transactions is far beyond the substrate's deepest call-tree (witnessed crypto + arena cycles nest ≤ a handful). |
| `REV_SLOT_START` | `[u32; 64]` | 64 | per-slot log range start. |
| `REV_SLOT_END` | `[u32; 64]` | 64 | per-slot log range end (exclusive). |
| `REV_SLOT_CAP` | `[u64; 64]` | 64 | **new (Gap E)**: capability token bound at `rev_begin`; checked when recording privileged (memory-restore / slot-release) undos. |
| `REV_SLOT_ORDER` | `[u32; 64]` | 64 | **new (Gap C/H)**: push order, so the LIFO "top" is unambiguous even though slot ids are reused by the freelist. `REV_TOP_ORDER` increments on each `rev_begin`. |
| `REV_REC_TAG` | `[u32; 8192]` | 8192 | undo tag per record; `REV_MAX_RECORDS`. 8192 records covers the largest single transaction (e.g. a multi-limb bigint chain or a batch witness publish) with margin; bounded ⇒ no runtime alloc (M-discipline, K=0.99). |
| `REV_REC_A` | `[u64; 8192]` | 8192 | undo arg a. |
| `REV_REC_B` | `[u64; 8192]` | 8192 | undo arg b. |
| `REV_REC_C` | `[u64; 8192]` | 8192 | undo arg c. |
| `REV_REC_D` | `[u64; 8192]` | 8192 | undo arg d. |
| `REV_REC_USED` | `u32` (scalar) | 1 | high-water mark of the log; always == top live slot's `END` under the stack invariant. |
| `REV_TOP_ORDER` | `u32` (scalar) | 1 | **new**: monotone push counter feeding `REV_SLOT_ORDER` (W17 — algebraic time advances monotonically across envelope opens). |
| `REV_UNDO_FN` | `[u64; 256]` | 256 | undo-fn address per tag; `REV_MAX_TAGS`. 256 distinct effect kinds is generous (5 built-in + room for every subsystem to register its own). |
| `REV_TAG_LIVE` | `[u8; 256]` | 256 | registration bit per tag. |
| `REV_QUAD_SCRATCH` | `[u64; 4]` | 4 | **new (Gap F)**: module-scope 4-u64 buffer so `rev_record` can synthesize a `quad` for the shared `rev_record_quad` core without a local `var` array (Trap 7). Non-reentrant (consistent with module posture). |

Address-of-static (`&REV_*`) is taken **only inside this file** (W1/W3); no global pointer escapes — the only addresses leaving the module are the witness payload pointers passed to `wh_publish` (read-only to the callee) and the undo-fn addresses, which are this module's own static functions registered at boot.

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"` (single-line, Trap 1):

| extern | from | providing NN | built? |
|---|---|---|---|
| `fn rev_invoke_undo(undo_fn: u64, a: u64, b: u64, c: u64, d: u64) -> i32` | `rev_invoke.iii` | **— (not in gospel module list; sibling primitive)** | **NOT BUILT** — must be scheduled before Module 05. The single privileged indirect-call trampoline: in a `metal {}` block it moves args into `rcx/rdx/r8/r9` + 5th on the Win64 shadow-stack slot and `call`s through the address register. Isolating it here keeps `reversible.iii` pure (no `metal`). This is the **one sanctioned >4-arg extern** (callee shape is the fixed `fn(a,b,c,d)` = 4; W2 governs the callee). |
| `fn bigint_drop(id: u64) -> i32` | `bigint.iii` | Module 04 (numera/bigint) | **BUILT** — confirmed `fn bigint_drop(id: u64) -> i32 @export` at `bigint.iii:144`. **The gospel's `bigint_drop_ext` does not exist** (Gap A). |
| `fn wh_revoke(idx: u64) -> i32` | `witness_hook.iii` | aether/witness_hook | **BUILT** — confirmed `fn wh_revoke(idx: u64) -> i32 @export` at `witness_hook.iii:193`. |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | `witness_hook.iii` | aether/witness_hook | **BUILT** — used only by the optional commit/rollback witness emission (M6/W16). Signature confirmed at `witness_hook.iii:144`. |
| `fn wh_chain_root(out_id: *u8) -> i32` | `witness_hook.iii` | aether/witness_hook | **BUILT** — confirmed `witness_hook.iii:216`; supplies the prior chain head for the in-commitment of the rollback witness. |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | numera/identifier | **BUILT** — used to commit the rollback payload (Keccak-256). |

Not-yet-built dependency count for the wave scheduler: **1** (`rev_invoke.iii`). All others are built. (If the scheduler treats `rev_invoke.iii` as part of this work item, schedule it as a 2-fn micro-module: `rev_invoke_undo` + a self-test; it has no further deps.)

## Algorithm
NIH (M1): every mechanism is hand-rolled over fixed arrays + libc-free logic; only the indirect call (`rev_invoke.iii`) and witness/identifier hashing are externs into already-NIH III modules. No ML/heuristics (M3/M4): all control flow is exact (bounds checks, equality tests, monotone counters); there is **no counting-to-promote, no observation, no threshold**. Determinism (M2) and bit-identity (W5): outputs depend only on the recorded `(tag,a,b,c,d)` sequence and registration table; reverse replay over a fixed array is order-deterministic; the same input transaction yields byte-identical undo effects and byte-identical witness commitments. No recursion (W15): every traversal is an explicit `while` over a `u32` index — the "stack" of envelopes is the `REV_SLOT_*` arrays, not the call stack.

- **`rev_init`** — two sentinel loops (`while i < REV_MAX_SLOTS`, `while t < REV_MAX_TAGS`) zero `REV_SLOT_LIVE` and `REV_TAG_LIVE`/`REV_UNDO_FN`; set `REV_REC_USED = 0`, `REV_TOP_ORDER = 0`; then five `rev_register_undo` calls bind the built-in tags to `(rev_undo_* as u64)`. Idempotent (re-running re-zeros). Returns `REV_OK`.

- **`rev_register_undo`** — reject `tag >= REV_MAX_TAGS` (unsigned compare — no Trap 3) and `tag == 0u32`; store `REV_UNDO_FN[tag] = undo_fn`, `REV_TAG_LIVE[tag] = 1u8`; return `REV_OK`. Indexing by `tag` (u32) into typed arrays — compiler scales by stride; no manual `as u64` pointer math (no Trap 4).

- **`rev_alloc_slot`** — sentinel loop `while i < REV_MAX_SLOTS`: first slot with `REV_SLOT_LIVE[i] == 0u8` returns `i`; else `REV_SLOT_NONE`. (W14 — no `break`; early return on hit.)

- **`rev_begin(cap)`** — `s = rev_alloc_slot()`; if `REV_SLOT_NONE` return it. Set `REV_SLOT_LIVE[s]=1`, `REV_SLOT_START[s]=REV_REC_USED`, `REV_SLOT_END[s]=REV_REC_USED`, `REV_SLOT_CAP[s]=cap`, `REV_TOP_ORDER = REV_TOP_ORDER + 1u32` (W17 monotone), `REV_SLOT_ORDER[s]=REV_TOP_ORDER`. Return `s`.

- **`_rev_is_top(slot) -> u8`** — returns `1u8` iff `slot` is live and `REV_SLOT_ORDER[slot]` is the maximum order among live slots (i.e. the top of the stack). Implemented as one sentinel loop tracking the running max order + its slot; compares the argument's order to that max. This is the LIFO guard that fixes the non-LIFO overlap bug (Gap H). Pure read; no Trap exposure.

- **`rev_record(slot,tag,a,b)`** — write `a,b,0,0` into `REV_QUAD_SCRATCH[0..3]`, then `return rev_record_quad(slot, tag, &REV_QUAD_SCRATCH[0] as *u64)`. (4 params; W2-OK.)

- **`rev_record_quad(slot,tag,quad)`** — validate: `slot >= REV_MAX_SLOTS` → `REV_E_BAD_SLOT`; `REV_SLOT_LIVE[slot]==0` → `REV_E_BAD_SLOT`; `_rev_is_top(slot)==0` → `REV_E_NOT_TOP` (records only land on the open top envelope, preserving contiguous `[start,end)` — Gap H); `tag >= REV_MAX_TAGS` or `REV_TAG_LIVE[tag]==0` → `REV_E_BAD_TAG`; **capability gate (Gap E)**: if `tag == REV_TAG_MEM_RESTORE_U8` or `== REV_TAG_MEM_RESTORE_U64` or `== REV_TAG_RELEASE_SLOT` and `REV_SLOT_CAP[slot]==0u64` → `REV_E_CAP`; `REV_REC_USED >= REV_MAX_RECORDS` → `REV_E_OOM_LOG`. Then `idx = REV_REC_USED`; read `quad[0..3]` (caller buffer) into `REV_REC_A/B/C/D[idx]`; `REV_REC_TAG[idx]=tag`; `REV_REC_USED = idx + 1u32`; `REV_SLOT_END[slot] = REV_REC_USED`; return `REV_OK`.

- **`rev_commit(slot)`** — validate live + `_rev_is_top` (else `REV_E_NOT_TOP`); read `start=REV_SLOT_START[slot]`; **optional witness** (if witness booted): `wh_publish` a commit fragment whose payload encodes `(REV_SLOT_ORDER[slot], REV_SLOT_END[slot]-start)` and whose in-commit = `wh_chain_root`. Set `REV_SLOT_LIVE[slot]=0`; since it is the top, `REV_SLOT_END[slot]==REV_REC_USED` always holds under the stack invariant, so `REV_REC_USED = start` (truncate). Return `REV_OK`. (Persisting effects is a no-op — the forward effects already happened; commit just drops the undo log.)

- **`rev_rollback(slot)`** — validate live + `_rev_is_top`; `start=REV_SLOT_START[slot]`, `end=REV_SLOT_END[slot]`; sentinel reverse loop `let mut i:u32 = end; while i > start { i = i - 1u32; tag=REV_REC_TAG[i]; fn_addr=REV_UNDO_FN[tag]; if fn_addr != 0u64 { rev_invoke_undo(fn_addr, REV_REC_A[i], REV_REC_B[i], REV_REC_C[i], REV_REC_D[i]) } }` — the `fn_addr != 0u64` guard prevents a null indirect call (Gap G / M5). **Optional witness**: publish a rollback fragment (payload = `(order, end-start)`, in-commit = chain root) so the rollback is itself chained + reproducible (M6/M10/W16). Then `REV_SLOT_LIVE[slot]=0`; `REV_REC_USED = start` (top ⇒ `end==REV_REC_USED`). Return `REV_OK`. Determinism: reverse index walk over fixed arrays — bit-identical replay.

- **`rev_nest_begin(slot)`** — validate live (else `REV_SLOT_NONE`); return `REV_SLOT_END[slot]` (a checkpoint index). No mutation.

- **`rev_nest_rollback(slot,checkpoint)`** — validate live + `_rev_is_top`; `start=REV_SLOT_START[slot]`, `end=REV_SLOT_END[slot]`; reject `checkpoint > end` **or `checkpoint < start`** (Gap I) → `REV_E_BAD_CKPT`; reverse loop `while i > checkpoint { i=i-1; ... rev_invoke_undo guarded by fn_addr!=0 ... }`; set `REV_SLOT_END[slot]=checkpoint`; since top, `REV_REC_USED = checkpoint`. Return `REV_OK`. Leaves records in `[start,checkpoint)` intact.

- **`rev_compact`** — pure invariant restoration (Gap C): single sentinel loop finds the live slot with max `REV_SLOT_ORDER`; if none, assert `REV_REC_USED == 0u32` (else set it 0 and it was already correct under the stack discipline); if one, assert `REV_REC_USED == REV_SLOT_END[top]`. Returns `REV_OK`, or `REV_E_INVARIANT` if the assert ever fails (defensive; under the LIFO API it cannot). No GC heuristic — exact algebra over the stack.

- **`rev_depth` / `rev_records_used`** — one sentinel loop counting `REV_SLOT_LIVE[i]==1` / direct read of `REV_REC_USED`.

- **Built-in undo bodies** (callee ABI `fn(a,b,c,d:u64)->i32`, ≤4 params): `rev_undo_mem_u8` writes `(b & 0xFFu64) as u8` through `a as *u8` at `[0u64]`; `rev_undo_mem_u64` writes `b` through `a as *u64` at `[0u64]`; `rev_undo_drop_bigint` returns `bigint_drop(a)` (corrected name, Gap A); `rev_undo_release_slot` writes `0u8` through `a as *u8` at `[b]`; `rev_undo_witness_revoke` returns `wh_revoke(a)`. Each returns `REV_OK` on the memory paths. **Note (Trap 5):** `rev_undo_mem_u64` stores a full `u64` through a `*u64` where the value `b` is a genuine `u64` parameter (not a `u32`-in-`u64` slot), so the 8-byte `movq` is correct here — no byte-by-byte needed. `rev_undo_mem_u8`/`rev_undo_release_slot` store a single byte through `*u8` — correct width.

## KAT Vectors (>= 3)
Self-test exercises a module-scope `[u8; 8]` / `[u64; 4]` target buffer (declared at module scope, Trap 7) and asserts byte-for-byte.

1. **Commit discards, no undo runs.** `rev_init()`; `let t : u8 buffer REV_KAT_BUF[0]=0xAA`; `s=rev_begin(1u64)`; record `REV_TAG_MEM_RESTORE_U8, a=&REV_KAT_BUF[0], b=0x11`; set `REV_KAT_BUF[0]=0xFF` (the "forward effect"); `rev_commit(s)`. **Expected:** `REV_KAT_BUF[0]==0xFF` (undo NOT applied), `rev_records_used()==0` (log truncated), `rev_depth()==0`.

2. **Rollback restores in reverse order.** `rev_init()`; `REV_KAT_BUF[0]=0x00`; `s=rev_begin(1u64)`; record `MEM_RESTORE_U8 a=&buf[0] b=0x01`; set `buf[0]=0x10`; record `MEM_RESTORE_U8 a=&buf[0] b=0x10`; set `buf[0]=0x20`; `rev_rollback(s)`. **Expected:** undos replay LIFO → first restores `0x10`, then restores `0x01`, so final `REV_KAT_BUF[0]==0x01`; `rev_records_used()==0`; `rev_depth()==0`.

3. **u64 memory restore.** `rev_init()`; `REV_KAT_Q[0]=0u64`; `s=rev_begin(1u64)`; record `MEM_RESTORE_U64 a=&REV_KAT_Q[0] b=0xDEADBEEFCAFEBABEu64`; set `REV_KAT_Q[0]=0x1122334455667788u64`; `rev_rollback(s)`. **Expected:** `REV_KAT_Q[0]==0xDEADBEEFCAFEBABEu64` (full 8-byte restore — guards Trap 5 store width).

4. **Nested checkpoint rollback leaves outer intact.** `rev_init()`; `buf[0]=0x00`; `s=rev_begin(1u64)`; record `MEM_RESTORE_U8 a=&buf[0] b=0x01`; set `buf[0]=0x01`; `cp=rev_nest_begin(s)`; record `MEM_RESTORE_U8 a=&buf[0] b=0x02`; set `buf[0]=0x02`; `rev_nest_rollback(s, cp)`. **Expected:** inner undo restores `0x01` → `REV_KAT_BUF[0]==0x01`; `rev_records_used()==cp` (one record remains); `rev_depth()==1` (outer still open). Then `rev_commit(s)` ⇒ `rev_records_used()==0`, `rev_depth()==0`.

5. **Capability gate refuses unprivileged memory restore (Gap E).** `rev_init()`; `s=rev_begin(0u64)` (ambient cap); `r=rev_record(s, REV_TAG_MEM_RESTORE_U8, &buf[0], 0x55)`. **Expected:** `r == REV_E_CAP`; `rev_records_used()==0`.

6. **Non-top record/commit refused (Gap H).** `rev_init()`; `s1=rev_begin(1u64)`; `s2=rev_begin(1u64)`; `r=rev_record(s1, REV_TAG_WITNESS_REVOKE, 0u64, 0u64)`. **Expected:** `r == REV_E_NOT_TOP` (s1 is not the top); `rev_commit(s1)` also returns `REV_E_NOT_TOP`; `rev_commit(s2)` then `rev_commit(s1)` both `REV_OK`.

7. **Bad-tag and slot exhaustion.** `rev_init()`; `s=rev_begin(1u64)`; `rev_record(s, 0u32, 0,0) == REV_E_BAD_TAG`; `rev_record(s, 250u32, 0,0) == REV_E_BAD_TAG` (unregistered). Open `REV_MAX_SLOTS` envelopes ⇒ the next `rev_begin` returns `REV_SLOT_NONE`.

(Negative-case proof per MEMORY discipline: KATs 5–7 prove the gates **fail** on bad input, not merely that the happy path passes.)

## Trap Exposure
- **Trap 1 (multi-line fn):** EXPOSED (every signature). Avoidance: all `fn`/`extern` signatures single-line, including the 6-field `wh_publish` extern and the 5-arg `rev_invoke_undo` extern — both kept on one physical line.
- **Trap 2 (const prefix):** EXPOSED. Avoidance: every const is `REV_`-prefixed; collision-checked clean (see Constant Namespace).
- **Trap 3 (signed ordering compare):** NOT EXPOSED. Every compare is either unsigned (`u32`/`u64` bounds, `i > start`, `checkpoint > end`) or `i32` equality (`r != 0i32` on the `wh_get`/extern returns, `tag == 0u32`). No `i32`/`i64` `< <= > >=`. Error codes compared by `==`/`!=` only (W11).
- **Trap 4 (u32-in-u64-slot pointer math):** NOT EXPOSED. Array indices (`tag`, `slot`, `idx`, `i`) index typed arrays directly (compiler-scaled stride); no manual `base + (idx as u64)*stride`. The only `as u64` are function-address registrations and the genuine-u64 undo args.
- **Trap 5 (u32 pointer store width):** EXPOSED in undo bodies. Avoidance: `rev_undo_mem_u64` stores a true `u64` param through `*u64` (8-byte `movq` is correct); byte/`*u8` stores in `rev_undo_mem_u8` / `rev_undo_release_slot` are single-byte. No `u32`-origin value is stored through a `*u32`. KAT 3 asserts the full-width restore.
- **Trap 6 (nested block comments):** NOT EXPOSED — no nested `/* */`; ASCII only.
- **Trap 7 (local var arrays):** EXPOSED conceptually (KATs + the quad path need scratch). Avoidance: `REV_QUAD_SCRATCH`, `REV_KAT_BUF`, `REV_KAT_Q` are **module-scope** `var` arrays; no function-local `var [..]`. Documented non-reentrant.
- **Trap 8 (`} else {`):** NOT EXPOSED — the design uses guard-clause early returns, not `if/else`. Any `else` introduced in Phase 2 must be `} else {` on one line.
- **Trap 9 (em-dash in comment):** EXPOSED (prose-heavy header). Avoidance: ASCII `--` everywhere; no U+2014. (The gospel source shows backslash-escapes, not em-dashes; Phase 2 must transcribe with ASCII `--`.)
- **Trap 10 (`let mut` flag):** NOT EXPOSED — loop counters drive their own `while` condition (W14); no mutated checkpoint-flag. Early-return guard pattern used for validation.
- **Trap 11 (modulo-after-call):** NOT EXPOSED — no `%` operator anywhere in the module.
- **Trap 12 (`@specialize *T` stride):** NOT EXPOSED — not generic; all arrays are concretely typed.

## Gap / Fix List
PARTIAL — gaps and the exact fix for each:

- **A. `bigint_drop_ext` does not exist (hard build break).** Gospel: `extern ... fn bigint_drop_ext(id: u64) ... from "bigint.iii"` and `rev_undo_drop_bigint` calls it. **Fix:** declare `extern ... fn bigint_drop(id: u64) -> i32 from "bigint.iii"` (verified symbol, `bigint.iii:144`) and call `bigint_drop(a)`.
- **B. `rev_invoke.iii` not built (missing dependency).** The indirect-call trampoline is an extern into an unbuilt sibling module. **Fix:** wave-schedule `rev_invoke.iii` before Module 05; define it as a 2-fn micro-module (`rev_invoke_undo(undo_fn,a,b,c,d)->i32` via a `metal {}` Win64 indirect `call`, + a self-test). This is the only place a `metal` block is needed; `reversible.iii` stays pure `.iii`. Marked NOT BUILT in Dependencies.
- **C. Permanent record-log leak + no compaction (W8/M5).** Gospel only truncates the log when committing/rolling-back the most-recent envelope; any non-LIFO commit orphans records forever ⇒ `REV_E_OOM_LOG` after enough cycles ⇒ the substrate silently cannot open transactions. **Fix:** make envelopes a strict **stack** (`REV_SLOT_ORDER` + `_rev_is_top`); commit/rollback only the top (else `REV_E_NOT_TOP`), so truncation is always exact. Add `rev_compact()` for explicit invariant restoration. No hidden GC (M3/M4 clean).
- **D. No witness continuity on commit/rollback (M6/M10/W16).** A rollback is a state transition that must chain by hash and be reproducible; the gospel emits nothing. **Fix:** `rev_commit`/`rev_rollback` publish a fragment via `wh_publish` (payload encodes envelope order + record count; in-commit = `wh_chain_root`; out-commit = `ident_from_bytes` of the payload). Gated on witness-boot so the core transacts pre-boot (keeps K=0.99). Satisfies W16 (fragments under reversibility) and W17 (monotone `REV_TOP_ORDER`).
- **E. No capability mediation of privileged undos (M8/M5).** `rev_undo_mem_u8/u64` and `rev_undo_release_slot` write to **arbitrary** addresses with no authorization — an M8 violation and an M5 brick risk (could restore over unrelated memory). **Fix:** `rev_begin(cap)` binds a capability into `REV_SLOT_CAP[slot]`; `rev_record_quad` refuses the three privileged tags when `cap == 0u64` (`REV_E_CAP`). Memory-restore is thus only recordable inside a capability-scoped envelope. (KAT 5.)
- **F. W2 violation — `rev_record4` has 6 params.** **Fix:** replace with `rev_record_quad(slot, tag, quad: *u64)` (3 params; the 4 u64 args travel in a caller/`REV_QUAD_SCRATCH` buffer); keep `rev_record(slot,tag,a,b)` (4 params) as the common 2-arg convenience, which fills `REV_QUAD_SCRATCH` and delegates.
- **G. Null indirect call on unregistered tag (M5 brick).** `rev_rollback`/`rev_nest_rollback` read `REV_UNDO_FN[tag]` and call it unconditionally; a tag that was valid at record time but whose registration was somehow cleared (or any future code path) yields `fn_addr == 0u64` → null `call`. **Fix:** guard every trampoline call with `if fn_addr != 0u64 { ... }`.
- **H. Non-LIFO range model is unsound (M2 correctness).** Per-slot `[start,end)` only stays contiguous if records are appended to the most-recently-opened envelope; the gospel `rev_record` lets any live slot append, so slot A's range can swallow slot B's records. **Fix:** the LIFO `_rev_is_top` guard in `rev_record_quad` (and commit/rollback) — records only land on the top envelope, guaranteeing contiguous, non-overlapping ranges. (KAT 6.)
- **I. `rev_nest_rollback` under-validates the checkpoint.** Gospel checks `checkpoint > end` but not `checkpoint < start`, so a too-small checkpoint would replay another envelope's records. **Fix:** also reject `checkpoint < REV_SLOT_START[slot]` → `REV_E_BAD_CKPT`.
- **J. Sentinel literal un-named.** Gospel returns the bare literal `0xFFFFFFFFu32` from `rev_begin`/`rev_alloc_slot`/`rev_nest_begin`. **Fix (clarity, not a bug):** name it `REV_SLOT_NONE` once and reuse; callers compare `== REV_SLOT_NONE` (W12 sentinel discipline made explicit).
- **K. Reentrancy of undo bodies (M5).** Because the log is shared module state, an undo fn that calls `rev_record*`/`rev_rollback` corrupts it. **Fix (contract):** documented invariant — undo functions are leaf operations over the four `u64` args + externs (`bigint_drop`, `wh_revoke`, raw memory); they MUST NOT re-enter the reversible API. Noted in the module header and the Data-Structures reentrancy note.

Mandates explicitly satisfied after fixes: M1 (NIH — only `bigint`/`witness_hook`/`identifier`/`rev_invoke` III externs), M2/M15 (deterministic, total over the bounded log), M3/M4 (no learning/heuristics — exact bounds + LIFO stack), M5 (no brick — null-fnptr guard, capability gate, no unrecoverable state), M6/M10/W16 (witnessed, reproducible rollback), M8 (capability-scoped envelopes), M9 (reversibility is the module's essence), M19 (cost bounded by the fixed `[start,end)` span). M7 ring R-1 preserved. M11–M14/M17/M18/M20 are not in this module's remit (no proof terms / memo / theorem carriers here) — noted as out-of-scope rather than violated.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/reversible.iii
 *
 * III STDLIB - numera::reversible
 *
 * Transactional envelopes with explicit backward continuations,
 * organised as a strict LIFO stack of capability-scoped envelopes.
 * On commit the forward effects persist and the undo log truncates;
 * on rollback every recorded undo is replayed in reverse order and
 * the rollback is witnessed.
 *
 * Each undo record is: u32 tag + four u64 args (a,b,c,d).
 * The tag table is set up at boot (rev_init). Tag 0 is reserved.
 * Undo bodies are leaf ops; they MUST NOT re-enter the reversible API.
 * Module state is non-reentrant (single-threaded substrate use).
 *
 * Hexad: kind_essence.  Ring: R-1.  K: 0.99 (slot/log exhaustion).
 * Discipline: W2 (<=4 params), W8 (static tables), W13 (<=20 locals),
 * W14 (sentinel loops, no break), W17 (monotone envelope order).
 */

module numera_reversible

extern @abi(c-msvc-x64) fn rev_invoke_undo(undo_fn: u64, a: u64, b: u64, c: u64, d: u64) -> i32 from "rev_invoke.iii"
extern @abi(c-msvc-x64) fn bigint_drop(id: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn wh_revoke(idx: u64) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"

const REV_OK             : i32 =  0i32
const REV_E_OOM_SLOT     : i32 = -1i32
const REV_E_OOM_LOG      : i32 = -2i32
const REV_E_BAD_SLOT     : i32 = -3i32
const REV_E_BAD_TAG      : i32 = -4i32
const REV_E_BAD_CKPT     : i32 = -5i32
const REV_E_NOT_TOP      : i32 = -6i32
const REV_E_CAP          : i32 = -7i32
const REV_E_INVARIANT    : i32 = -8i32

const REV_SLOT_NONE      : u32 = 0xFFFFFFFFu32
const REV_MAX_SLOTS      : u32 = 64u32
const REV_MAX_RECORDS    : u32 = 8192u32
const REV_MAX_TAGS       : u32 = 256u32

const REV_TAG_MEM_RESTORE_U8  : u32 = 1u32
const REV_TAG_MEM_RESTORE_U64 : u32 = 2u32
const REV_TAG_DROP_BIGINT     : u32 = 3u32
const REV_TAG_RELEASE_SLOT    : u32 = 4u32
const REV_TAG_WITNESS_REVOKE  : u32 = 5u32
const REV_WIT_OPID_LEN        : u64 = 26u64

/* Envelope stack (slot tables). */
var REV_SLOT_LIVE   : [u8;  64]
var REV_SLOT_START  : [u32; 64]
var REV_SLOT_END    : [u32; 64]
var REV_SLOT_CAP    : [u64; 64]
var REV_SLOT_ORDER  : [u32; 64]

/* Undo record log. */
var REV_REC_TAG     : [u32; 8192]
var REV_REC_A       : [u64; 8192]
var REV_REC_B       : [u64; 8192]
var REV_REC_C       : [u64; 8192]
var REV_REC_D       : [u64; 8192]
var REV_REC_USED    : u32 = 0u32
var REV_TOP_ORDER   : u32 = 0u32

/* Tag dispatch: undo_fn = address of fn(a,b,c,d:u64)->i32. */
var REV_UNDO_FN     : [u64; 256]
var REV_TAG_LIVE    : [u8;  256]

/* Scratch (module-scope; Trap 7) + KAT targets. */
var REV_QUAD_SCRATCH : [u64; 4]
var REV_KAT_BUF      : [u8;  8]
var REV_KAT_Q        : [u64; 4]

fn rev_alloc_slot() -> u32 {
    // TODO: body per Algorithm -- sentinel loop, first free slot or REV_SLOT_NONE
}

fn _rev_is_top(slot: u32) -> u8 {
    // TODO: body per Algorithm -- 1u8 iff slot is the live max-order envelope
}

fn rev_init() -> i32 @export {
    // TODO: body per Algorithm -- zero tables, reset counters, register 5 built-in tags
}

fn rev_register_undo(tag: u32, undo_fn: u64) -> i32 @export {
    // TODO: body per Algorithm -- bounds + tag!=0; store fn + live bit
}

fn rev_begin(cap: u64) -> u32 @export {
    // TODO: body per Algorithm -- alloc slot, set range=USED, bind cap, bump order
}

fn rev_record(slot: u32, tag: u32, a: u64, b: u64) -> i32 @export {
    // TODO: body per Algorithm -- fill REV_QUAD_SCRATCH{a,b,0,0}; delegate to rev_record_quad
}

fn rev_record_quad(slot: u32, tag: u32, quad: *u64) -> i32 @export {
    // TODO: body per Algorithm -- validate slot/top/tag/cap/log; append record; advance END+USED
}

fn rev_commit(slot: u32) -> i32 @export {
    // TODO: body per Algorithm -- top-only; optional commit witness; clear live; truncate to START
}

fn rev_rollback(slot: u32) -> i32 @export {
    // TODO: body per Algorithm -- top-only; reverse replay (guard fn_addr!=0); witness; truncate
}

fn rev_nest_begin(slot: u32) -> u32 @export {
    // TODO: body per Algorithm -- live check; return END as checkpoint
}

fn rev_nest_rollback(slot: u32, checkpoint: u32) -> i32 @export {
    // TODO: body per Algorithm -- top-only; validate START<=checkpoint<=END; reverse replay to checkpoint
}

fn rev_compact() -> i32 @export {
    // TODO: body per Algorithm -- assert REV_REC_USED == top END (or 0); REV_E_INVARIANT on mismatch
}

fn rev_depth() -> u32 @export {
    // TODO: body per Algorithm -- count live slots
}

fn rev_records_used() -> u32 @export {
    // TODO: body per Algorithm -- return REV_REC_USED
}

/* ============ Built-in undo bodies (callee ABI fn(a,b,c,d)->i32) ============ */

fn rev_undo_mem_u8(a: u64, b: u64, c: u64, d: u64) -> i32 {
    // TODO: body per Algorithm -- (a as *u8)[0] = (b & 0xFF) as u8
}

fn rev_undo_mem_u64(a: u64, b: u64, c: u64, d: u64) -> i32 {
    // TODO: body per Algorithm -- (a as *u64)[0] = b   (true u64; 8-byte store correct, Trap 5)
}

fn rev_undo_drop_bigint(a: u64, b: u64, c: u64, d: u64) -> i32 {
    // TODO: body per Algorithm -- return bigint_drop(a)   (corrected name, Gap A)
}

fn rev_undo_release_slot(a: u64, b: u64, c: u64, d: u64) -> i32 {
    // TODO: body per Algorithm -- (a as *u8)[b] = 0u8
}

fn rev_undo_witness_revoke(a: u64, b: u64, c: u64, d: u64) -> i32 {
    // TODO: body per Algorithm -- return wh_revoke(a)
}
```
