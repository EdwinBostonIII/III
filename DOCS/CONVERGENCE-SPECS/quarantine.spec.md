# 25 aether/quarantine.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel candidate body has the right transactional shape (journal arena, slot table, witness-emit on enter/commit/abort) and uses the *correct* providers (`identifier.iii`, `witness_hook.iii::wh_publish/wh_chain_root/wh_get_frag_id` — none of the fictional externs), but it (1) is **not capability-mediated at all** (M8 violation — `q_enter`/`q_commit` declare a writable memory region and apply arbitrary memory writes with no capability check → trivially **bricks** the substrate, M5 violation), (2) declares **function-local `var` arrays** throughout (Trap 7 — will not compile as written), (3) forms pointers via `&ARR[expr]` element-address (house-style/codegen defect — the built tree never does this), (4) **ignores the `wh_publish` failure sentinel** (M6 — a transition that fails to witness proceeds silently with an uninitialised fragment id), (5) has a **dead/ambiguous `q_status`** that cannot report `0xFF=invalid`, and (6) uses the over-generic `Q_` const prefix (dispatch assigns `QUAR_`; `Q_*` module-scope `var`s already exist in the aggregated link via `corpus/386_fed_qc_gate.iii`). All gaps are closed below; the maximal realization adds capability gating at mint+apply and an **undo journal** so commit is reversible (M9).

## Purpose
`aether/quarantine.iii` is a first-class **transactional sandbox**: an explicit region of authoritative state into which all writes are *journaled* rather than applied; reads inside the quarantine consult the journal first and fall through to underlying state on miss; `q_commit` applies the journal atomically (in insertion order) and `q_abort` discards it. The construct is itself a **witnessed, reversible operation** — entering publishes a `QUARANTINE_ENTER` fragment (`in_commit` = witness chain root, `out_commit` = Keccak256 of the region descriptor); commit and abort publish fragments naming the enter fragment as antecedent, so the entire transaction is a hash-chained provenance unit.
- **Hexad kind:** `kind_motion + kind_witness` (it *moves* state under transaction and *witnesses* every transition).
- **Ring:** R0 (it touches authoritative process memory).
- **K-vector:** 0.99 (per gospel header).

## Public API
All signatures **single-line** (Trap 1). Status convention: privileged/mutating fns return `i32` (W9: negative error, `QUAR_OK=0`); the slot-minting fn returns a `u32` slot id or the `QUAR_SENT` sentinel (W12 sentinel-typed); `q_status` returns a `u8` state code (W10/W12).

```
fn q_init() -> i32 @export
fn q_enter(cap: u64, region_base: u64, region_len: u64) -> u32 @export
fn q_journal_write(slot: u32, addr: u64, data: *u8, len: u32) -> i32 @export
fn q_journal_read(slot: u32, addr: u64, out: *u8, len: u32) -> i32 @export
fn q_commit(cap: u64, slot: u32) -> i32 @export
fn q_abort(slot: u32) -> i32 @export
fn q_rollback(cap: u64, slot: u32) -> i32 @export
fn q_status(slot: u32) -> u8 @export
```

Notes per fn:
- `q_init` — idempotent table reset; `QUAR_OK`. (W12.)
- `q_enter(cap, region_base, region_len)` — **capability-gated mint** (the new `cap` is bit 0 of the gospel's intent realized: only a holder of `CAP_RIGHT_AMEND` over the region may open a writable sandbox). Returns slot id `[0,255]` or `QUAR_SENT` (`0xFFFFFFFFu32`) on cap-deny / table-full / witness-fail. **3 params (W2 OK).** The minted open slot *is* the attenuated write authority for the lifetime of the transaction (capability-as-handle), so `q_journal_write`/`q_journal_read` need no further cap arg — keeping them at ≤4 params (W2).
- `q_journal_write(slot, addr, data, len)` — record a write; `QUAR_OK` / `QUAR_E_BAD` / `QUAR_E_STATE` / `QUAR_E_BOUNDS` / `QUAR_E_FULL`. **4 params (W2 OK).**
- `q_journal_read(slot, addr, out, len)` — journal-first read with state fall-through; same error set minus FULL. **4 params.**
- `q_commit(cap, slot)` — **capability-gated apply** (re-verifies `CAP_RIGHT_AMEND`; the cap may have been revoked since enter — M9/M8). Captures the **undo journal** (prior bytes) *before* overwriting so the commit is reversible via `q_rollback`. Publishes the commit fragment. `QUAR_OK` / errors. **2 params.**
- `q_abort(slot)` — discard journal, mark aborted, publish abort fragment. `QUAR_OK` / errors. **1 param.** (No cap: aborting never mutates authoritative state — always safe, M5.)
- `q_rollback(cap, slot)` — **NEW (M9 closure):** for a *committed* slot, re-apply the undo journal in reverse insertion order, restoring pre-commit bytes; publish a `QUARANTINE_ROLLBACK` fragment naming the commit fragment as antecedent. Cap-gated (`CAP_RIGHT_AMEND`). `QUAR_OK` / `QUAR_E_STATE` (slot not in COMMIT). **2 params.**
- `q_status(slot)` — `0=open, 1=committed, 2=aborted, 3=rolled-back, 0xFF=invalid`. **1 param.**

## Constant Namespace
**PREFIX = `QUAR_`** (dispatch-assigned). Grep result: **no `QUAR_*` symbol exists anywhere in `STDLIB/`** (zero collisions). The gospel's `Q_*` prefix is **rejected** — `corpus/386_fed_qc_gate.iii` already declares module-scope `var Q_SEED/Q_PK/Q_SI/Q_SIGS/Q_QC/Q_BADQC/Q_BMH/Q_CR/Q_PR`, and every module-scope `var`/`const` emits a linker-global `L_<NAME>` (Trap 2); a test buffer named e.g. `Q_QC` would collide at aggregation. All consts/vars below carry `QUAR_`. (Public **function** names stay `q_*` — the gospel contract; C-ABI symbol grep shows only `q_init_seal_domain` in `sanctus/quality.iii`, so `q_init`, `q_enter`, `q_commit`, etc. are free.)

Module-level consts (name : type = value):
```
const QUAR_OK            : i32 =  0i32
const QUAR_E_FULL        : i32 = -1i32
const QUAR_E_BAD         : i32 = -2i32
const QUAR_E_STATE       : i32 = -3i32
const QUAR_E_BOUNDS      : i32 = -4i32
const QUAR_E_CAP         : i32 = -5i32   // capability denied (M8)
const QUAR_E_WITNESS     : i32 = -6i32   // wh_publish returned the u64 fail sentinel (M6)

const QUAR_MAX_SLOTS     : u32 = 256u32
const QUAR_MAX_JENT      : u32 = 65536u32
const QUAR_DATA_AREA     : u32 = 1048576u32      // 1 MiB packed forward journal
const QUAR_UNDO_AREA     : u32 = 1048576u32      // 1 MiB packed undo journal (M9)
const QUAR_SENT          : u32 = 0xFFFFFFFFu32
const QUAR_WH_FAIL       : u64 = 0xFFFFFFFFFFFFFFFFu64  // wh_publish failure sentinel

const QUAR_STATE_OPEN     : u8 = 0u8
const QUAR_STATE_COMMIT    : u8 = 1u8
const QUAR_STATE_ABORT     : u8 = 2u8
const QUAR_STATE_ROLLBACK  : u8 = 3u8
const QUAR_STATE_INVALID   : u8 = 0xFFu8

// capability right required to open/apply a quarantine over authoritative state.
// Bit value MUST equal aether/capability.iii::CAP_RIGHT_AMEND (0x4000); declared
// locally as a literal (not imported) because iiis has no cross-module const import.
const QUAR_RIGHT_AMEND    : u64 = 0x4000u64

const QUAR_PILLAR         : u16 = 1u16   // witness pillar id for quarantine ops
```
String-literal opid/producer seeds (`"aether::quarantine"`, `"aether::quarantine::enter"`, etc.) are used inline as `"..." as *u8` (confirmed valid in-tree: `omnia/hexad_pfs.iii:60-65`), not as named consts.

## Data Structures
All module-scope (Trap 7 — **no local `var` arrays**, unlike the gospel body). Sizes are fixed and justified (W8). Note: `[u8; N]` arrays in iiis reserve `N` bytes when small; the large arenas stay `[u8; …]` here (≤2 MiB total — well within the small code-model RIP reach; no need for the `[u64; N/8]` trick witness_hook uses for its 1 GiB arrays).

| Name | Type | Bytes | Bound justification |
|---|---|---|---|
| `QUAR_LIVE` | `[u8; 256]` | 256 | 1 flag per slot; `QUAR_MAX_SLOTS`=256 simultaneous transactions (matches capability.iii's 256 slot model). |
| `QUAR_STATE` | `[u8; 256]` | 256 | state code per slot; init to `QUAR_STATE_INVALID`. |
| `QUAR_REGION_BASE` | `[u64; 256]` | 2048 | region base addr per slot. |
| `QUAR_REGION_LEN` | `[u64; 256]` | 2048 | region length per slot. |
| `QUAR_JOUR_START` | `[u32; 256]` | 1024 | first forward-journal entry index for slot. |
| `QUAR_JOUR_END` | `[u32; 256]` | 1024 | one-past-last forward-journal entry. |
| `QUAR_UNDO_START` | `[u32; 256]` | 1024 | first undo-journal entry (set at commit). |
| `QUAR_UNDO_END` | `[u32; 256]` | 1024 | one-past-last undo-journal entry. |
| `QUAR_ENTER_FRAG` | `[u64; 256]` | 2048 | enter-fragment index per slot. |
| `QUAR_COMMIT_FRAG` | `[u64; 256]` | 2048 | commit-fragment index (antecedent for rollback). |
| `QUAR_ENTER_ID` | `[u8; 8192]` | 8192 | 256 × 32-byte enter fragment id. |
| `QUAR_COMMIT_ID` | `[u8; 8192]` | 8192 | 256 × 32-byte commit fragment id (rollback antecedent). |
| `QUAR_JE_ADDR` | `[u64; 65536]` | 524288 | per-entry target addr; `QUAR_MAX_JENT`=65536 writes across all open txns. |
| `QUAR_JE_LEN` | `[u32; 65536]` | 262144 | per-entry byte length. |
| `QUAR_JE_DATA_OFF` | `[u32; 65536]` | 262144 | per-entry offset into `QUAR_DATA`. |
| `QUAR_UE_ADDR` | `[u64; 65536]` | 524288 | undo-entry target addr (M9). |
| `QUAR_UE_LEN` | `[u32; 65536]` | 262144 | undo-entry length. |
| `QUAR_UE_DATA_OFF` | `[u32; 65536]` | 262144 | undo-entry offset into `QUAR_UNDO`. |
| `QUAR_DATA` | `[u8; 1048576]` | 1048576 | packed forward write payloads, no per-write metadata. |
| `QUAR_UNDO` | `[u8; 1048576]` | 1048576 | packed pre-commit (undo) bytes (M9). |
| `QUAR_JE_USED` | `u32 = 0u32` | 4 | high-water of forward journal entries. |
| `QUAR_DATA_USED` | `u32 = 0u32` | 4 | high-water of `QUAR_DATA`. |
| `QUAR_UE_USED` | `u32 = 0u32` | 4 | high-water of undo entries. |
| `QUAR_UNDO_USED` | `u32 = 0u32` | 4 | high-water of `QUAR_UNDO`. |
| `QUAR_PRODUCER` | `[u8; 32]` | 32 | producer id = ident("aether::quarantine"). |
| `QUAR_OPID_ENTER` | `[u8; 32]` | 32 | opid for enter. |
| `QUAR_OPID_COMMIT` | `[u8; 32]` | 32 | opid for commit. |
| `QUAR_OPID_ABORT` | `[u8; 32]` | 32 | opid for abort. |
| `QUAR_OPID_ROLLBACK` | `[u8; 32]` | 32 | opid for rollback. |
| `QUAR_INITED` | `u8 = 0u8` | 1 | one-time init guard. |
| `QUAR_DESC` | `[u8; 16]` | 16 | **module-scope** region descriptor scratch (was local `var desc`). |
| `QUAR_IN_C` | `[u8; 32]` | 32 | in_commit scratch (was local). |
| `QUAR_OUT_C` | `[u8; 32]` | 32 | out_commit scratch (was local). |
| `QUAR_FID` | `[u8; 32]` | 32 | fragment-id sink scratch (was local). |
| `QUAR_SUMBUF` | `[u8; 786432]` | 786432 | commit out_commit pre-image: per entry 8(addr)+4(len)=12 bytes × `QUAR_MAX_JENT`(65536) = 786432. **The gospel's `[u8;8192]` is a heap-smash bug** — 8192 holds only 682 entries but a single txn may hold up to 65536. Sized to the worst case (W8). |
| `QUAR_ABORTBUF` | `[u8; 64]` | 64 | abort/rollback out_commit pre-image ("abort"/"rollbk" ‖ enter_id). |

Total ≈ 8.0 MiB static — well within the 2 GiB small-code-model reach.
**Reentrancy note:** the module-scope scratch (`QUAR_DESC`/`QUAR_IN_C`/`QUAR_OUT_C`/`QUAR_FID`/`QUAR_SUMBUF`/`QUAR_ABORTBUF`) makes `q_enter`/`q_commit`/`q_abort`/`q_rollback` **non-reentrant**. Acceptable: these are serialized authoritative-state operations (same discipline as `identifier.iii` and `witness_hook.iii`, which serialize their hashing scratch). Documented for callers.

## Dependencies (externs)
Each declared `extern @abi(c-msvc-x64) fn … from "<module>.iii"`. Provider NN from the gospel layering.

| Extern | Provider (module / NN) | Built? | Confirmed signature (read from source) |
|---|---|---|---|
| `ident_from_bytes(input:*u8, in_len:u64, out:*u8) -> i32` | `numera/identifier.iii` (NN 01) | **BUILT** | matches gospel verbatim (`identifier.iii:33`). |
| `ident_copy(src:*u8, dst:*u8) -> i32` | `numera/identifier.iii` (NN 01) | **BUILT** | matches (`identifier.iii:65`). |
| `wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `aether/witness_hook.iii` (NN 07) | **BUILT** | matches gospel verbatim (`witness_hook.iii:144`). Failure sentinel `0xFFFFFFFFFFFFFFFFu64`; success returns frag idx (may be `0`). |
| `wh_chain_root(out_id:*u8) -> i32` | `aether/witness_hook.iii` (NN 07) | **BUILT** | exists (`witness_hook.iii:216`). |
| `wh_get_frag_id(idx:u64, out_id:*u8) -> i32` | `aether/witness_hook.iii` (NN 07) | **BUILT** | exists (`witness_hook.iii:198`). *(Declared for symmetry; not on the critical path — only needed if a consumer wants to re-read the enter id by index.)* |
| `cap_verify_rights(id:u64, required:u64) -> u8` | `aether/capability.iii` (NN, Layer 6) | **BUILT** | exists (`capability.iii:148`); returns 1 iff cap live, no ancestor revoked, and `(rights & required)==required`. |

**No not-yet-built dependencies.** Every provider (`identifier.iii`, `witness_hook.iii`, `capability.iii`) is already realized in `STDLIB/iii/`. The wave scheduler can place Module 25 immediately after Layer-2 `witness_hook` and the Layer-6 `capability` modules (both present). Quarantine does **not** need `algebraic_time.iii` directly — `wh_publish` advances algebraic time internally via `at_advance()`.

## Algorithm

### `q_init() -> i32`
1. `i=0; while i < QUAR_MAX_SLOTS { QUAR_LIVE[i]=0u8; QUAR_STATE[i]=QUAR_STATE_INVALID; i=i+1u32 }` — sentinel-driven loop (W14), **STATE initialised to `0xFF`** so a never-entered slot reports `invalid` (fixes gospel's ambiguous `q_status`).
2. Zero high-waters: `QUAR_JE_USED=0; QUAR_DATA_USED=0; QUAR_UE_USED=0; QUAR_UNDO_USED=0`.
3. Compute the four/five canonical ids via `ident_from_bytes("aether::quarantine…", len, QUAR_PRODUCER/OPID_*)`. (Lengths exact: "aether::quarantine"=18, "::enter"→25, "::commit"→26, "::abort"→25, "::rollback"→28.)
4. `QUAR_INITED=1u8; return QUAR_OK`.
**Determinism (M2):** all ids are Keccak256 of fixed ASCII — bit-identical every run, every CPU (M10). NIH (M1): hashing is `identifier.iii`→`keccak256.iii` (hand-rolled in-tree).

### `q_enter(cap, region_base, region_len) -> u32`
1. `if QUAR_INITED==0u8 { q_init() }`.
2. **M8 cap gate:** `if cap_verify_rights(cap, QUAR_RIGHT_AMEND) != 1u8 { return QUAR_SENT }` — only a holder of AMEND over authoritative state may declare a writable sandbox. *(This is the M5/M8 fix: without it, any caller could quarantine `[0, 2^64)` and `q_commit` arbitrary memory = bricking.)*
3. `slot = q_alloc_slot()` (linear scan for `QUAR_LIVE[i]==0u8`, return `QUAR_SENT` if none — W14, no break).
4. `if slot == QUAR_SENT { return QUAR_SENT }`.
5. Initialise slot: `QUAR_LIVE[slot]=1; QUAR_STATE[slot]=QUAR_STATE_OPEN; QUAR_REGION_BASE[slot]=region_base; QUAR_REGION_LEN[slot]=region_len; QUAR_JOUR_START[slot]=QUAR_JE_USED; QUAR_JOUR_END[slot]=QUAR_JE_USED`.
6. Build the 16-byte region descriptor in module-scope `QUAR_DESC`: little-endian `region_base` (8) ‖ `region_len` (8), byte-wise stores through a `*u8` (Trap 5-safe).
7. `wh_chain_root(QUAR_IN_C ptr)`; `ident_from_bytes(QUAR_DESC ptr, 16, QUAR_OUT_C ptr)` (out_commit = Keccak256(descriptor)).
8. `frag = wh_publish(QUAR_PRODUCER, QUAR_OPID_ENTER, QUAR_IN_C, QUAR_OUT_C, 0u8, 0u8, QUAR_PILLAR, QUAR_DESC, 0u32, QUAR_DESC, 16u32, QUAR_FID)`.
9. **M6 witness gate:** `if frag == QUAR_WH_FAIL { QUAR_LIVE[slot]=0u8; QUAR_STATE[slot]=QUAR_STATE_INVALID; return QUAR_SENT }` — a transition that fails to witness **refuses** (reverts the slot) rather than proceeding with an uninitialised id (fixes gospel defect F).
10. `QUAR_ENTER_FRAG[slot]=frag`; `ident_copy(QUAR_FID, q_enter_id_ptr(slot))`; `return slot`.
**Determinism/bit-identity (W5):** `out_commit` is a pure hash of the descriptor; the fragment id is reproducible from recorded fields (M10). All pointer formation via `((&ARR as u64)+off) as *u8` (idiom fix B).

### `q_journal_write(slot, addr, data, len) -> i32`
1. Validate: `if slot >= QUAR_MAX_SLOTS { return QUAR_E_BAD }`; `if QUAR_LIVE[slot]==0u8 { return QUAR_E_BAD }`; `if QUAR_STATE[slot] != QUAR_STATE_OPEN { return QUAR_E_STATE }`.
2. Bounds (M5): `if q_in_region(slot, addr, len)==0u8 { return QUAR_E_BOUNDS }`.
3. Capacity: `if QUAR_JE_USED >= QUAR_MAX_JENT { return QUAR_E_FULL }`; `if (QUAR_DATA_USED + len) > QUAR_DATA_AREA { return QUAR_E_FULL }`.
4. Record: `je=QUAR_JE_USED; QUAR_JE_ADDR[je]=addr; QUAR_JE_LEN[je]=len; QUAR_JE_DATA_OFF[je]=QUAR_DATA_USED`.
5. Copy payload byte-wise into `QUAR_DATA[QUAR_DATA_USED + k]` for `k in [0,len)` (W14 loop; `[u8]` element store = 1 byte, Trap 5-safe).
6. `QUAR_DATA_USED += len; QUAR_JE_USED = je+1; QUAR_JOUR_END[slot] = QUAR_JE_USED; return QUAR_OK`.
**No cap arg (W2):** the open slot is the authority minted at `q_enter`. **No ML/heuristic (M3/M4):** pure append.

### `q_journal_read(slot, addr, out, len) -> i32`
1. Same validation + bounds as write (minus capacity).
2. For each byte `i in [0,len)`: `byte_addr = addr + i`; scan the slot's forward-journal entries **backward** from `QUAR_JOUR_END[slot]` to `QUAR_JOUR_START[slot]` using a `found` flag (W14 — loop condition `j > start`, no break; once `found==1` the body is skipped). The newest entry covering `byte_addr` (`je_addr <= byte_addr < je_addr+je_len`) wins; copy `QUAR_DATA[QUAR_JE_DATA_OFF[j] + (byte_addr - je_addr)]` into `out[i]`.
3. On miss (`found==0`): fall through to underlying state — `out[i] = *(byte_addr as *u8)`.
**Determinism:** the journal-first resolution is exact and order-deterministic (insertion order is the tie-break, newest wins). Underlying-state reads are environmental but never witnessed here, so M10 is preserved (no fragment emitted on read). **Cost (W19):** O(len × entries-in-slot), both bounded by `QUAR_MAX_JENT` and the read length — bounded under the cost lattice.

### `q_commit(cap, slot) -> i32`
1. Validate slot (`QUAR_E_BAD`/`QUAR_E_STATE` as above; must be OPEN).
2. **M8 re-gate (cap may have been revoked since enter):** `if cap_verify_rights(cap, QUAR_RIGHT_AMEND) != 1u8 { return QUAR_E_CAP }`.
3. **M9 undo capture (NEW):** `QUAR_UNDO_START[slot]=QUAR_UE_USED`. For each forward entry `j in [start,end)`: capture the *current* underlying bytes at `[QUAR_JE_ADDR[j], +QUAR_JE_LEN[j])` into the undo journal (`QUAR_UE_ADDR/UE_LEN/UE_DATA_OFF`, payload bytes read via `*(p as *u8)` into `QUAR_UNDO`). Guard `QUAR_UE_USED < QUAR_MAX_JENT` and `QUAR_UNDO_USED + len <= QUAR_UNDO_AREA` → `QUAR_E_FULL` on overflow (refuse before any write — atomicity). `QUAR_UNDO_END[slot]=QUAR_UE_USED`.
4. **Apply:** for each forward entry in insertion order `j in [start,end)`, for `k in [0,len)`: `*((addr+k) as *u8) = QUAR_DATA[off + k]` (byte-wise; Trap 5-safe). *(Apply is split into a `q_apply_forward(slot)` helper to keep ≤20 locals — W13.)*
5. `QUAR_STATE[slot] = QUAR_STATE_COMMIT`.
6. Build commit `out_commit` pre-image in `QUAR_SUMBUF`: per entry, 8-byte LE addr ‖ 4-byte LE len; `off` accumulates `12` per entry. Hash via `ident_from_bytes(QUAR_SUMBUF, off, QUAR_OUT_C)`. `wh_chain_root(QUAR_IN_C)`.
7. `frag = wh_publish(QUAR_PRODUCER, QUAR_OPID_COMMIT, QUAR_IN_C, QUAR_OUT_C, 0u8, 0u8, QUAR_PILLAR, q_enter_id_ptr(slot), 1u32, QUAR_SUMBUF, off_u32, QUAR_FID)` — **enter fragment id as the single antecedent** (chain link). **M6 gate:** `if frag == QUAR_WH_FAIL { return QUAR_E_WITNESS }` (note: state already mutated; the undo journal makes this recoverable via `q_rollback`, so M5/M9 hold even on witness failure).
8. `QUAR_COMMIT_FRAG[slot]=frag; ident_copy(QUAR_FID, q_commit_id_ptr(slot)); QUAR_LIVE[slot]=0u8; return QUAR_OK`. *(Slot kept un-LIVE but STATE=COMMIT so `q_status`/`q_rollback` still see it; the undo journal stays valid because its `[start,end)` window is frozen.)*
**Determinism/M10:** `out_commit` is a pure function of recorded (addr,len) pairs — reproducible byte-identically. **W13:** undo-capture and apply are separate helpers; the commit body itself holds <20 locals.

### `q_rollback(cap, slot) -> i32` (NEW — M9 closure)
1. Validate slot; `if QUAR_STATE[slot] != QUAR_STATE_COMMIT { return QUAR_E_STATE }`.
2. **M8 gate:** `cap_verify_rights(cap, QUAR_RIGHT_AMEND)` → `QUAR_E_CAP`.
3. Re-apply the undo journal in **reverse** insertion order (`j` from `QUAR_UNDO_END[slot]` down to `QUAR_UNDO_START[slot]`, W14 flag-loop), writing saved bytes back: `*((QUAR_UE_ADDR[j]+k) as *u8) = QUAR_UNDO[QUAR_UE_DATA_OFF[j]+k]`. Reverse order makes overlapping writes restore the true pre-commit state.
4. `QUAR_STATE[slot] = QUAR_STATE_ROLLBACK`.
5. Publish a rollback fragment (`QUAR_OPID_ROLLBACK`, antecedent = **commit** fragment id `q_commit_id_ptr(slot)`, `revtag=1u8` marking a reversal), out_commit = Keccak256("rollbk" ‖ enter_id) in `QUAR_ABORTBUF`. **M6 gate** → `QUAR_E_WITNESS`. `return QUAR_OK`.
**M5/M9:** the substrate is always recoverable — a commit can be fully reversed; nothing is unrecoverable.

### `q_abort(slot) -> i32`
1. Validate slot; must be OPEN.
2. `QUAR_STATE[slot] = QUAR_STATE_ABORT` (the forward journal window is simply abandoned; high-waters are **not** rewound — entries are append-only within an epoch for witness reproducibility; space reclaim happens at `q_init`).
3. `wh_chain_root(QUAR_IN_C)`; out_commit = Keccak256("abort" ‖ enter_id) in `QUAR_ABORTBUF` (5 + 32 = 37 bytes). `frag = wh_publish(…, QUAR_OPID_ABORT, …, revtag=1u8, …, antecedent = enter id, n_ante=1, payload = QUAR_ABORTBUF, 37u32, …)`. **M6 gate** → `QUAR_E_WITNESS`.
4. `QUAR_LIVE[slot]=0u8; return QUAR_OK`. **No cap (M5):** abort only discards; it never touches authoritative state.

### `q_status(slot) -> u8`
1. `if slot >= QUAR_MAX_SLOTS { return QUAR_STATE_INVALID }`.
2. `return QUAR_STATE[slot]` — single return (gospel's dead `if QUAR_LIVE…` branch removed). Because `q_init` seeds `QUAR_STATE` to `0xFF`, a never-entered slot correctly reports `invalid`; OPEN/COMMIT/ABORT/ROLLBACK report their codes (fixes defect G).

### Internal helpers (not `@export`)
- `q_alloc_slot() -> u32` — linear free-slot scan (W14, no break).
- `q_in_region(slot, addr, len) -> u8` — `addr >= base && addr+len <= base+rlen`; **hardened** against u64 wrap: also require `len as u64 <= QUAR_REGION_LEN[slot]` and `addr - base <= rlen - len` computed without overflow (M5). Returns 0/1 (W10).
- `q_enter_id_ptr(slot) -> *u8` / `q_commit_id_ptr(slot) -> *u8` — `((&QUAR_ENTER_ID as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8` — **mask before pointer math** (Trap 4).
- `q_apply_forward(slot) -> i32`, `q_capture_undo(slot) -> i32` — split out of `q_commit` for W13.

## KAT Vectors (>= 3)
A module self-test `q_selftest() -> u64` returns `99u64` on full pass, else the failing step number (house convention, cf. `wh_selftest`/`ident_selftest`). Tests run against a real (`cap_env_init()`-minted) env cap and `wh_init(0u64)`.

1. **KAT-1 journal-first read (no underlying touch).** `cap = cap_env_init()` (has AMEND). Module-scope `QUAR_KAT_REGION : [u8; 256]` as the "underlying state"; `region_base = (&QUAR_KAT_REGION as u64)`, `region_len = 256`. `slot = q_enter(cap, base, 256)` → expect `slot==0u32`, `q_status(0)==QUAR_STATE_OPEN`. `q_journal_write(0, base+10, {0xAA,0xBB,0xCC}, 3)` → `QUAR_OK`. `q_journal_read(0, base+10, out, 3)` → `out == {0xAA,0xBB,0xCC}` (from journal). Read `base+9..base+12` (4 bytes spanning the boundary) → byte0 = underlying `QUAR_KAT_REGION[9]` (pre-set to `0x11`), bytes1..3 = `{0xAA,0xBB,0xCC}`. **Byte-for-byte.**

2. **KAT-2 commit applies + abort discards + status.** Continue: `QUAR_KAT_REGION[10..12]` are still their original values (e.g. `0x00`) *before* commit (writes were journaled, not applied) — assert that. `q_commit(cap, 0)` → `QUAR_OK`; now `QUAR_KAT_REGION[10..12] == {0xAA,0xBB,0xCC}` (applied) and `q_status(0)==QUAR_STATE_COMMIT`. Separately: `slot1 = q_enter(cap, base, 256)`; `q_journal_write(slot1, base+20, {0x99}, 1)`; `q_abort(slot1)` → `QUAR_OK`; `QUAR_KAT_REGION[20] == 0x00` (unchanged — discarded) and `q_status(slot1)==QUAR_STATE_ABORT`. **Byte-for-byte.**

3. **KAT-3 rollback reverses a commit (M9).** `slot2 = q_enter(cap, base, 256)`; pre-set `QUAR_KAT_REGION[30]=0x55`; `q_journal_write(slot2, base+30, {0x77}, 1)`; `q_commit(cap, slot2)` → `QUAR_KAT_REGION[30]==0x77`. `q_rollback(cap, slot2)` → `QUAR_OK`; `QUAR_KAT_REGION[30]==0x55` (restored) and `q_status(slot2)==QUAR_STATE_ROLLBACK`. **Byte-for-byte.**

4. **KAT-4 capability denial (M8/M5).** Mint an attenuated cap WITHOUT AMEND: `bad = cap_attenuate(cap, CAP_RIGHT_FS_READ, 0u64)`. `q_enter(bad, base, 256)` → returns `QUAR_SENT` (no slot minted). `q_commit(bad, 0)` on an existing open slot → `QUAR_E_CAP`, and the underlying region is **unchanged**. Proves the gate *fails closed* on bad input (not just passes on good).

5. **KAT-5 witness chaining (M6/M10).** After KAT-2's commit, `wh_get_frag_id(QUAR_ENTER_FRAG[0], id_e)` and the commit fragment's recorded antecedent both equal `q_enter_id_ptr(0)` — i.e. the commit fragment names the enter fragment as antecedent (assert the 32-byte ids match). Re-running the whole self-test from a fresh `wh_init`/`q_init` yields **identical** enter/commit fragment ids (determinism, M10).

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| **1 multi-line `fn`** | Potentially (long sigs) | Every signature kept single-line (see Public API + Skeleton). |
| **2 module-`const` linker-global** | **YES** | All consts/vars `QUAR_`-prefixed; grep confirms zero `QUAR_*` collisions (gospel's generic `Q_*` rejected — clashes risk with `corpus/386_fed_qc_gate.iii`'s `Q_*` vars). |
| **3 signed ordering SIGSEGV** | **No** | All ordering compares are on **u32/u64** (unsigned — safe and used freely in-tree, cf. `fed_admit`/`identifier`). Every `i32` (`QUAR_OK`/error codes) and the `u64` witness sentinel are compared with `==`/`!=` only (W11). |
| **4 u32-in-u64-slot ptr math** | **YES** | `q_enter_id_ptr`/`q_commit_id_ptr` mask `(slot as u64) & 0xFFFFFFFFu64` before `*32u64`. Any other u32→u64 used in pointer arithmetic (`off as u32` offsets into `QUAR_DATA`) are array-index element loads on `[u8]` (1-byte stride) — masked where they feed address computation. |
| **5 u32 ptr store width** | **No** | All stores into payload/undo/descriptor/sum buffers go through `*u8` element stores on `[u8;…]` arrays (1-byte `mov`). No `*u32` store anywhere. |
| **6 nested `/* */`** | **No** | Comments are single-level `//` or non-nested `/* */`. |
| **7 local `var` arrays** | **YES (gospel violates)** | **All** scratch arrays (`QUAR_DESC/IN_C/OUT_C/FID/SUMBUF/ABORTBUF` + KAT buffers) moved to **module scope** (gospel declared them function-local — would not compile). Reentrancy caveat documented. |
| **8 `} else {` one line** | n/a | No `else` blocks needed (early-return / flag style). If any added, kept on one line. |
| **9 em-dash in comment** | **YES (avoid)** | All comments use ASCII `--`, never `—`. |
| **10 `let mut flag` checkpoint** | Minor | `found`/`q_alloc_slot` use the flag-drives-loop or early-return idiom (the W14-safe shape), not a checkpoint-flag that misbehaves. |
| **11 `%` after call** | **No** | No modulo anywhere; all offsetting is additive. |
| **12 `@specialize *T` stride** | **No** | Not generic; element width is fixed (`u8`/`u32`/`u64` arrays). |

## Gap / Fix List
Each gospel-body defect with its fix (this module is **PARTIAL**):

1. **M8 — no capability mediation (CRITICAL).** Gospel `q_enter`/`q_commit` take no cap. **Fix:** add `cap: u64` to `q_enter` (mint gate) and `q_commit`/`q_rollback` (apply gate); verify `cap_verify_rights(cap, QUAR_RIGHT_AMEND)`. Writes/reads/abort stay cap-free (the open slot is the attenuated authority; abort never mutates). Keeps every fn ≤4 params (W2).
2. **M5 — bricking via unbounded region (CRITICAL, consequence of #1).** Without a cap gate any caller can `q_enter(0, 2^64)` then `q_commit` arbitrary memory. **Fix:** #1's cap gate + `q_in_region` overflow-hardening (no u64 wrap).
3. **M9 — commit is irreversible.** Gospel commit overwrites underlying bytes with no record of priors. **Fix:** added undo journal (`QUAR_UE_*`/`QUAR_UNDO`) captured *before* apply, plus the new `q_rollback` to reverse a commit. Default reversibility restored; the *destructive* step (commit) is the explicitly cap-gated exception M9 permits.
4. **M6 — witness failure ignored.** Gospel stores `wh_publish`'s return into `QUAR_ENTER_FRAG[slot]` and proceeds even when it is the `0xFFFF…FFFF` fail sentinel, then `ident_copy`s an uninitialised `fid`. **Fix:** every `wh_publish` call site checks `== QUAR_WH_FAIL`; `q_enter` reverts the slot and returns `QUAR_SENT`; commit/abort/rollback return `QUAR_E_WITNESS`.
5. **Trap 7 — function-local `var` arrays.** Gospel declares `var desc/in_c/out_c/fid/sumbuf` inside fns (uncompilable). **Fix:** all moved to module scope with `QUAR_` names.
6. **Idiom — `&ARR[expr]` element-address.** Gospel forms pointers via `&Q_ENTER_ID[(slot)*32]`, `&desc[0u64]`, `&in_c[0u64]`, etc. The built tree (witness_hook reconciliation note, identifier, fed_admit) **always** uses `((&ARR as u64)+off) as *u8`. **Fix:** rewrite every pointer formation to that idiom; combine with Trap-4 masking.
7. **`QUAR_SUMBUF` undersizing (heap smash).** Gospel's commit `var sumbuf : [u8; 8192]` holds only 682 (addr,len) pairs, but one transaction may journal up to `QUAR_MAX_JENT`=65536 entries → 786432-byte pre-image → **out-of-bounds write**. **Fix:** size `QUAR_SUMBUF` to the worst case (786432) (W8). Optionally cap per-txn entries; spec keeps full capacity (no down-scaling — maximal intent).
8. **`q_status` dead/ambiguous branch.** Gospel's two branches return the same value and it cannot emit `0xFF`. **Fix:** seed `QUAR_STATE` to `QUAR_STATE_INVALID` at init; single `return QUAR_STATE[slot]`; add `ROLLBACK` state code.
9. **Const prefix.** Gospel uses `Q_` (collision-prone). **Fix:** `QUAR_` per dispatch.
10. **W13 watch on `q_commit`.** With undo capture + apply + summary-hash + publish in one body, locals exceed 20. **Fix:** split `q_capture_undo`/`q_apply_forward` helpers.
11. **Lazy `wh_init` assumption.** `q_init` does not initialise the witness hook; if `wh_init` was never called, all publishes fail. Handled by #4 (refuse on witness fail), but **documented**: the embedding program must `wh_init` before any quarantine op (same contract every witness consumer has).

**Optional strengthening (noted, not mandated):** commit's `out_commit` currently commits only (addr,len) pairs; including the applied data offset/length count would bind the *content* too. Both are M10-reproducible; spec keeps the gospel's (addr,len) commitment to honor the documented intent, with this as a future hardening.

**Mandate coverage confirmed:** M1 (NIH — only `identifier`/`witness_hook`/`capability`, all in-tree, hashing hand-rolled), M2/M10 (witness ids = pure hashes of recorded fields), M3/M4 (no counting/threshold/heuristic — exact journal resolution), M5/M8/M9 (cap-gated + reversible, closed above), M6 (witness-or-refuse), M7 (Ring R0 honored — touches authoritative memory at R0), M15 (algebraic ops total over their bit width), M19 (all loops bounded by fixed module-scope sizes). No floating point.

## Implementation Skeleton
Structurally paste-ready. SINGLE-LINE signatures; bodies are `// TODO` per Algorithm §. No full bodies (Phase 2 writes those).

```iii
// III/STDLIB/iii/aether/quarantine.iii
//
// III STDLIB - aether::quarantine
// Transactional sandbox over authoritative state. Writes are journaled; reads
// consult the journal first. Commit applies the journal in insertion order and
// captures an undo journal so the commit is reversible (q_rollback). Abort
// discards the journal. Every transition is a witnessed fragment; mint and apply
// are capability-gated (CAP_RIGHT_AMEND).
//
// Hexad: kind_motion + kind_witness.  Ring: R0.  K: 0.99.
// Discipline: W2, W3, W8, W13, W14.  Non-reentrant (module-scope scratch).

module aether_quarantine

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_frag_id(idx: u64, out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

const QUAR_OK            : i32 =  0i32
const QUAR_E_FULL        : i32 = -1i32
const QUAR_E_BAD         : i32 = -2i32
const QUAR_E_STATE       : i32 = -3i32
const QUAR_E_BOUNDS      : i32 = -4i32
const QUAR_E_CAP         : i32 = -5i32
const QUAR_E_WITNESS     : i32 = -6i32

const QUAR_MAX_SLOTS     : u32 = 256u32
const QUAR_MAX_JENT      : u32 = 65536u32
const QUAR_DATA_AREA     : u32 = 1048576u32
const QUAR_UNDO_AREA     : u32 = 1048576u32
const QUAR_SENT          : u32 = 0xFFFFFFFFu32
const QUAR_WH_FAIL       : u64 = 0xFFFFFFFFFFFFFFFFu64

const QUAR_STATE_OPEN     : u8 = 0u8
const QUAR_STATE_COMMIT    : u8 = 1u8
const QUAR_STATE_ABORT     : u8 = 2u8
const QUAR_STATE_ROLLBACK  : u8 = 3u8
const QUAR_STATE_INVALID   : u8 = 0xFFu8

const QUAR_RIGHT_AMEND    : u64 = 0x4000u64   // == capability.iii CAP_RIGHT_AMEND
const QUAR_PILLAR         : u16 = 1u16

var QUAR_LIVE          : [u8;  256]
var QUAR_STATE         : [u8;  256]
var QUAR_REGION_BASE   : [u64; 256]
var QUAR_REGION_LEN    : [u64; 256]
var QUAR_JOUR_START    : [u32; 256]
var QUAR_JOUR_END      : [u32; 256]
var QUAR_UNDO_START    : [u32; 256]
var QUAR_UNDO_END      : [u32; 256]
var QUAR_ENTER_FRAG    : [u64; 256]
var QUAR_COMMIT_FRAG   : [u64; 256]
var QUAR_ENTER_ID      : [u8;  8192]
var QUAR_COMMIT_ID     : [u8;  8192]

var QUAR_JE_ADDR       : [u64; 65536]
var QUAR_JE_LEN        : [u32; 65536]
var QUAR_JE_DATA_OFF   : [u32; 65536]
var QUAR_UE_ADDR       : [u64; 65536]
var QUAR_UE_LEN        : [u32; 65536]
var QUAR_UE_DATA_OFF   : [u32; 65536]

var QUAR_DATA          : [u8;  1048576]
var QUAR_UNDO          : [u8;  1048576]
var QUAR_JE_USED       : u32 = 0u32
var QUAR_DATA_USED     : u32 = 0u32
var QUAR_UE_USED       : u32 = 0u32
var QUAR_UNDO_USED     : u32 = 0u32

var QUAR_PRODUCER      : [u8; 32]
var QUAR_OPID_ENTER    : [u8; 32]
var QUAR_OPID_COMMIT   : [u8; 32]
var QUAR_OPID_ABORT    : [u8; 32]
var QUAR_OPID_ROLLBACK : [u8; 32]
var QUAR_INITED        : u8 = 0u8

var QUAR_DESC          : [u8; 16]
var QUAR_IN_C          : [u8; 32]
var QUAR_OUT_C         : [u8; 32]
var QUAR_FID           : [u8; 32]
var QUAR_SUMBUF        : [u8; 786432]
var QUAR_ABORTBUF      : [u8; 64]

// ---- self-test scratch ----
var QUAR_KAT_REGION    : [u8; 256]
var QUAR_KAT_OUT       : [u8; 64]
var QUAR_KAT_ID_E      : [u8; 32]
var QUAR_KAT_ID_C      : [u8; 32]

// ---- internal helpers (not @export) ----
fn q_enter_id_ptr(slot: u32) -> *u8 { /* TODO: ((&QUAR_ENTER_ID as u64) + ((slot as u64)&0xFFFFFFFFu64)*32u64) as *u8  (Trap 4) */ }
fn q_commit_id_ptr(slot: u32) -> *u8 { /* TODO: same against QUAR_COMMIT_ID */ }
fn q_alloc_slot() -> u32 { /* TODO: W14 free-slot scan, return QUAR_SENT if none */ }
fn q_in_region(slot: u32, addr: u64, len: u32) -> u8 { /* TODO: overflow-safe bounds per Algorithm; W10 */ }
fn q_capture_undo(slot: u32) -> i32 { /* TODO: snapshot pre-commit bytes into QUAR_UE_*/QUAR_UNDO; W13 split */ }
fn q_apply_forward(slot: u32) -> i32 { /* TODO: apply QUAR_DATA bytes to underlying addrs in insertion order */ }

// ---- public API ----
fn q_init() -> i32 @export { /* TODO: body per Algorithm q_init (STATE<-INVALID, ids) */ }
fn q_enter(cap: u64, region_base: u64, region_len: u64) -> u32 @export { /* TODO: cap gate + mint + enter fragment + witness-or-refuse */ }
fn q_journal_write(slot: u32, addr: u64, data: *u8, len: u32) -> i32 @export { /* TODO: validate, bounds, capacity, append */ }
fn q_journal_read(slot: u32, addr: u64, out: *u8, len: u32) -> i32 @export { /* TODO: backward journal scan, state fall-through */ }
fn q_commit(cap: u64, slot: u32) -> i32 @export { /* TODO: cap re-gate, q_capture_undo, q_apply_forward, commit fragment, witness gate */ }
fn q_abort(slot: u32) -> i32 @export { /* TODO: mark ABORT, abort fragment, witness gate */ }
fn q_rollback(cap: u64, slot: u32) -> i32 @export { /* TODO: cap gate, reverse-apply undo journal, rollback fragment */ }
fn q_status(slot: u32) -> u8 @export { /* TODO: bounds check then return QUAR_STATE[slot] */ }

// ---- self-test (99 = pass) ----
fn q_selftest() -> u64 @export { /* TODO: KAT-1..KAT-5 per spec; return step number on fail, 99u64 on pass */ }
```
