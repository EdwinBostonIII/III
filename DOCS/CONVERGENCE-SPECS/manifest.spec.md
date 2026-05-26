# 08 aether/manifest.iii — Implementation Spec

## Verdict
**PARTIAL** — `mf_attach` is substantially complete and sound, but the verify surface is a stub: `mf_verify` is hardcoded `return 0u8` (always-fail), and `mf_verify_by_idx` calls `wh_get_out_commit`, an accessor that does **not** exist in the built `witness_hook.iii` (only the gospel *addendum* adds it). The gospel body also uses the wrong keccak module (`keccak.iii` instead of `keccak256.iii`), declares externs inside function bodies, and has a multi-line `fn` signature (Trap 1). Maximal intent (a self-describing, byte-reproducible, capability-witnessed provenance manifest) is realizable but requires the fixes in the Gap/Fix list.

## Purpose
`aether::manifest` attaches a **provenance manifest** to every artifact the substrate produces. A manifest is *itself* a witness fragment (published through `wh_publish` with `operation_id = MANIFEST_OPID`), so provenance inherits the witness chain's hash-continuity, revocation, and algebraic-time ordering for free. The manifest records — in a fixed, little-endian, self-describing payload — the producing module, the operation type, the input commitment, the prior witness-chain head, and the artifact's output commitment, so any consumer holding the in-band fragment id can recompute every commitment byte-for-byte and confirm an artifact matches its manifest. Hexad: **kind_witness**. Ring: **R0**. K-vector: **1.00** (no slot exhaustion of its own; bounded by the underlying witness-hook capacity).

## Public API
```iii
fn mf_init() -> i32 @export
```
Idempotent boot: computes `MANIFEST_OPID = Keccak256("aether::manifest::attach")` into module scratch and sets the inited flag. Returns `MF_OK` (W9/W12 status). Safe to call repeatedly.

```iii
fn mf_attach(req: *u8) -> u64 @export
```
W2 aggregate form (5 logical inputs → one `*MfAttachReq`-shaped buffer, see Data Structures). Computes `in_commit`, `out_commit`, builds the self-describing manifest payload, publishes a witness fragment with `opid = MANIFEST_OPID`, writes the 32-byte fragment id into the caller's `out_manifest_id` slot, and **returns the fragment index** (a sentinel-typed `u64`; `0xFFFFFFFFFFFFFFFFu64` on failure — W12). NOTE: the gospel's 5-parameter signature violates W2 (≤4 params); this spec mandates the aggregate-by-pointer form.

```iii
fn mf_verify_by_idx(idx: u64, artifact_payload: *u8, payload_len: u64) -> u8 @export
```
Primitive verify against a known fragment index: re-derives `out_commit = Keccak256(artifact_payload[0..payload_len])`, reads the fragment's stored output commitment and stored length, and returns `1u8` iff both the recomputed commitment and the supplied length match (W10 reproducibility). Boolean return is `u8` (W10).

```iii
fn mf_verify(manifest_id: *u8, artifact_payload: *u8, payload_len: u64) -> u8 @export
```
Identifier-keyed verify: resolves `manifest_id` → fragment index via the local reverse index, then delegates to `mf_verify_by_idx`. Returns `1u8`/`0u8` (W10). The gospel body stubs this to `0u8`; this spec specifies the full reverse-lookup algorithm.

```iii
fn mf_producer(idx: u64, out: *u8) -> i32 @export
```
Copies the manifest fragment's producer id (32 bytes) to `out`. Returns `MF_OK`/`MF_E_BAD_IDX` (W9/W12). Accessor for consumers walking provenance.

```iii
fn mf_op(idx: u64, out: *u8) -> i32 @export
```
Copies the recorded operation type id (32 bytes) from the manifest payload to `out`. `MF_OK`/`MF_E_BAD_IDX`.

```iii
fn mf_chain_head_at(idx: u64, out: *u8) -> i32 @export
```
Copies the prior chain head recorded at attach time (32 bytes) to `out`. `MF_OK`/`MF_E_BAD_IDX`. Lets a consumer anchor the artifact to a specific point in the witness chain (M6/M16 ratifiability).

```iii
fn mf_selftest() -> u64 @export
```
Returns `99u64` on full pass, or a small nonzero failure code (house convention, mirrors `wh_selftest`).

## Constant Namespace
**PREFIX = `MANIFEST_`** — confirmed **no collision**. `grep` of `STDLIB/` for `MANIFEST_` returns only `XAT_E_MANIFEST_TAMPER_RUNTIME`, `XSL_E_MANIFEST_TAMPER`, `XSL_MANIFEST_BYTES`, and `C372_MANIFEST*` — all of which embed the *word* `MANIFEST` inside a **different** module prefix (`XAT_`, `XSL_`, `C372_`); none is a `MANIFEST_`-prefixed module-level const. No `MANIFEST_…` linker symbol exists. The short `MF_`-prefixed status constants also have no collision (`grep "^const MF_"` is empty across `STDLIB/`).

> Note on the gospel body: it uses the **short** prefix `MF_` (`MF_OK`, `MF_E_NULL`, `MF_OPID`, `MF_INITED`). The dispatch assigns PREFIX `MANIFEST_`. To honor the dispatch and Trap 2, **all module-level constants and module-scope `var`s in the built module use the `MANIFEST_` prefix**, not `MF_`. (The public *function* names retain the `mf_` idiom, matching the gospel's documented API surface and the consumers in higher layers; only linker-global `const`/`var` names take the long prefix, since those are what Trap 2 governs.)

Module-level constants (all `MANIFEST_`-prefixed):

| name | type | value | role |
|---|---|---|---|
| `MANIFEST_OK` | `i32` | `0i32` | success status (W9) |
| `MANIFEST_E_NULL` | `i32` | `-1i32` | null pointer argument |
| `MANIFEST_E_BAD_IDX` | `i32` | `-2i32` | fragment index out of range |
| `MANIFEST_E_NOT_FOUND` | `i32` | `-3i32` | manifest_id not in reverse index |
| `MANIFEST_E_FULL` | `i32` | `-4i32` | underlying witness hook full |
| `MANIFEST_PAYLOAD_LEN` | `u64` | `136u64` | fixed manifest-payload byte length (see Data Structures) |
| `MANIFEST_PILLAR` | `u16` | `5u16` | witness pillar slot for manifests (matches gospel) |
| `MANIFEST_OPID_STRLEN` | `u64` | `24u64` | byte length of `"aether::manifest::attach"` |
| `MANIFEST_MAX_INDEX` | `u64` | `1048576u64` | reverse-index bound = WH_MAX_FRAGMENTS (W8) |
| `MANIFEST_SENT` | `u64` | `0xFFFFFFFFFFFFFFFFu64` | not-found / failure sentinel (W12) |

All error codes are distinct negative `i32` (W9) and compared only by `==`/`!=` (W11/Trap 3).

## Data Structures
All module scope (Trap 7 — no local `var` arrays). Reverse-index capacity = the witness hook's `WH_MAX_FRAGMENTS` (1,048,576), so every fragment index a manifest can occupy is addressable (W8 bound justification: a manifest fragment cannot have an index ≥ the hook's own fragment ceiling, so the index table cannot be overrun).

| name | type | bytes | purpose / W8 justification |
|---|---|---|---|
| `MANIFEST_OPID` | `[u8; 32]` | 32 | cached `Keccak256("aether::manifest::attach")`; written once at init |
| `MANIFEST_INITED` | `u8` | 1 | idempotent-init flag |
| `MANIFEST_PAYLOAD_SCRATCH` | `[u8; 136]` | 136 | serialized manifest payload built in `mf_attach` (serialized, single-threaded use — acceptable per Trap 7) |
| `MANIFEST_IDX_KEYS` | `[u64; 4194304]` | 33 554 432 | reverse index: 32-byte manifest fragment id per slot (`1048576*32` bytes, declared as `[u64; N/8]` per the witness-hook byte-buffer convention) |
| `MANIFEST_IDX_VALS` | `[u64; 1048576]` | 8 388 608 | reverse index: fragment index for the id in the matching key slot |
| `MANIFEST_IDX_LIVE` | `[u8; 1048576]` | 1 048 576 | reverse-index slot occupancy flags |
| `MANIFEST_IDX_COUNT` | `u64` | 8 | number of live reverse-index entries |
| `MANIFEST_RDBUF` | `[u8; 136]` | 136 | scratch for `wh_get_payload` reads in verify/accessors |
| `MANIFEST_CMP_OC` | `[u8; 32]` | 32 | recomputed out_commit scratch in verify |
| `MANIFEST_T_*` (self-test) | various | — | KAT scratch buffers (producer/op/payload/id sinks), mirroring `wh_selftest` |

**Manifest payload layout (`MANIFEST_PAYLOAD_LEN = 136` bytes, little-endian):**
```
[  0 ..   8)  artifact payload_len            (u64 LE)
[  8 ..  16)  attach algebraic-time stamp     (u64 LE)  — recoverable for ratification
[ 16 ..  48)  prior witness chain head        (32 bytes)
[ 48 ..  80)  in_commit  = K256(producer||op||chain_head)  (32 bytes)
[ 80 .. 112)  op id (operation type)          (32 bytes)
[112 .. 136)  out_commit = K256(artifact bytes)(32 bytes)  -- redundant w/ fragment field, kept for self-description
```
This supersedes the gospel's 40-byte payload (which stored only `payload_len || chain_head`). The maximal intent — "the manifest records: producing module, operation type, input commitment, prior witness chain head" — requires `op`, `in_commit`, and `out_commit` to live *in the manifest payload itself* so a consumer can fully reconstruct provenance from the payload alone (the producer id is already a first-class fragment field via `wh_publish`).

## Dependencies (externs)
All declared at **module scope** (the gospel's body-local externs are corrected to top-of-file). Each `extern @abi(c-msvc-x64)`:

| extern | from | providing NN | built? |
|---|---|---|---|
| `ident_from_bytes(input:*u8,in_len:u64,out:*u8)->i32` | `identifier.iii` | 01 | **built** |
| `ident_copy(src:*u8,dst:*u8)->i32` | `identifier.iii` | 01 | **built** |
| `ident_eq(a:*u8,b:*u8)->u8` | `identifier.iii` | 01 | **built** |
| `ident_zero(out:*u8)->i32` | `identifier.iii` | 01 | **built** |
| `keccak256_init()->i32` | `keccak256.iii` | (Layer 0/1 crypto) | **built** |
| `keccak256_update(input:*u8,len:u64)->i32` | `keccak256.iii` | — | **built** |
| `keccak256_final(out:*u8)->i32` | `keccak256.iii` | — | **built** |
| `wh_publish(...12 args...)->u64` | `witness_hook.iii` | 07 | **built** |
| `wh_chain_root(out_id:*u8)->i32` | `witness_hook.iii` | 07 | **built** |
| `wh_get_payload(idx:u64,out_buf:*u8,max_len:u64,out_len:*u64)->i32` | `witness_hook.iii` | 07 | **built** |
| `wh_get_frag_id(idx:u64,out_id:*u8)->i32` | `witness_hook.iii` | 07 | **built** |
| `wh_get_at_time(idx:u64)->u64` | `witness_hook.iii` | 07 | **NOT BUILT** (gospel addendum only) |
| `wh_get_out_commit(idx:u64,out:*u8)->i32` | `witness_hook.iii` | 07 | **NOT BUILT** (gospel addendum only) |
| `wh_get_producer(idx:u64,out:*u8)->i32` | `witness_hook.iii` | 07 | **NOT BUILT** (gospel addendum only) |

**Not-yet-built dependency count: 3** — `wh_get_out_commit`, `wh_get_producer`, `wh_get_at_time` are specified in the gospel's *Turn-One Addendum* (lines 1789-1869) but are **absent from the current built `witness_hook.iii` (316 lines, none present)**. The wave scheduler must land these three witness-hook accessors **before** Module 08 verify/accessor functions compile. *Mitigation if accessors slip:* `mf_attach` and `mf_verify_by_idx`'s length check depend only on built exports (`wh_publish`, `wh_get_payload`, `wh_get_frag_id`), so a degraded build that stores `out_commit` **inside** the manifest payload (offset 112, already in the maximal layout) can verify the commitment via `wh_get_payload` alone — `wh_get_out_commit` becomes an optimization, not a hard requirement. The spec's Algorithm uses the payload-resident `out_commit` as the source of truth precisely to keep the not-yet-built accessors off the critical verification path.

## Algorithm

### `mf_init` (NIH: Keccak256 via `ident_from_bytes`)
1. If `MANIFEST_INITED == 1u8` return `MANIFEST_OK` (idempotent, early-return — Trap 10 avoided, no mutated checkpoint flag).
2. `s := "aether::manifest::attach" as *u8`; `ident_from_bytes(s, MANIFEST_OPID_STRLEN, &MANIFEST_OPID)`. (`MANIFEST_OPID_STRLEN = 24`; the literal is exactly 24 bytes — confirmed by character count.)
3. Zero `MANIFEST_IDX_COUNT`; set `MANIFEST_INITED = 1u8`; return `MANIFEST_OK`.
Determinism (M2): the opid is a pure hash of a fixed literal → identical every run, every CPU. Bit-identity (W5): the literal bytes are the reproducible representation.

### `mf_attach(req: *u8)` (NIH: Keccak256 streaming + oneshot)
`req` points to the aggregate (`artifact_payload:*u8`, `payload_len:u64`, `producer:*u8`, `op:*u8`, `out_manifest_id:*u8` — fixed offsets, see skeleton).
1. If `MANIFEST_INITED == 0u8` call `mf_init()`.
2. Null-guard each pointer field; on any null return `MANIFEST_SENT`.
3. `wh_chain_root(&chain_head)` — read current chain head (`chain_head` is a slice of `MANIFEST_PAYLOAD_SCRATCH[16..48]`, written in place).
4. `in_commit = Keccak256(producer[0..32] || op[0..32] || chain_head[0..32])` via streaming `keccak256_init/update×3/final`, output into `MANIFEST_PAYLOAD_SCRATCH[48..80]`. (Three contiguous 32-byte updates; no modulo-after-call, no param-spill exposure since each `keccak256_update` takes only `(ptr,len)`.)
5. `out_commit = Keccak256(artifact_payload[0..payload_len])` via `ident_from_bytes` → `MANIFEST_PAYLOAD_SCRATCH[112..136]`. (`ident_from_bytes` is `keccak256_oneshot` internally — robust against the init-call param-spill trap, per identifier.iii's own reconciliation note.)
6. Serialize the fixed payload into `MANIFEST_PAYLOAD_SCRATCH`: bytes `[0..8) = payload_len` LE (byte-by-byte through `*u8`, Trap 5); `[8..16) = 0` placeholder for time (the published fragment's authoritative time comes from `wh_publish`/`at_advance`; the placeholder keeps the payload length fixed and is reproducible because it is a constant 0 here); `[16..48)` already holds chain_head; `[48..80)` in_commit; `[80..112) = op[0..32]` (copied); `[112..136)` out_commit.
7. `idx := wh_publish(producer, &MANIFEST_OPID, &in_commit_slice, &out_commit_slice, 0u8 /*revtag*/, 0u8 /*phase*/, MANIFEST_PILLAR, &zero_id /*0 antecedents*/, 0u32, &MANIFEST_PAYLOAD_SCRATCH, MANIFEST_PAYLOAD_LEN as u32, out_manifest_id)`.
8. If `idx == 0xFFFFFFFFFFFFFFFFu64` return `MANIFEST_SENT` (hook full → M5 refusal, never corruption).
9. **Register reverse index**: linear-scan-free append — `slot := MANIFEST_IDX_COUNT`; if `slot < MANIFEST_MAX_INDEX`: copy the 32-byte fragment id from `out_manifest_id` into `MANIFEST_IDX_KEYS[slot*32..]`, set `MANIFEST_IDX_VALS[slot] = idx`, `MANIFEST_IDX_LIVE[slot] = 1u8`, `MANIFEST_IDX_COUNT = slot + 1`. (Append is O(1); lookup is the linear scan in `mf_verify`.)
10. Return `idx`.
Determinism (M2)/reproducibility (M10): every commitment is a hash of recorded inputs; replaying the same `req` against the same chain head yields the identical fragment id. No recursion (W15 — straight-line). No `break` (W14 — the only loops are bounded byte copies driven by a counter < 32 or < payload_len).

### `mf_verify_by_idx(idx, artifact_payload, payload_len)`
1. `wh_get_payload(idx, &MANIFEST_RDBUF, MANIFEST_PAYLOAD_LEN, &out_len)`; if return `!= 0i32` (Trap 3: `!=`, not `<`) return `0u8`.
2. If `out_len != MANIFEST_PAYLOAD_LEN` return `0u8`.
3. Decode `stored_len` from `MANIFEST_RDBUF[0..8]` (LE, byte-by-byte ORs into a `u64`). If `stored_len != payload_len` return `0u8`.
4. `ident_from_bytes(artifact_payload, payload_len, &MANIFEST_CMP_OC)` — recompute out_commit.
5. Compare `MANIFEST_CMP_OC[0..32]` against the **payload-resident** out_commit `MANIFEST_RDBUF[112..136]` via `ident_eq`. Return that `u8`. (Using the payload-resident commitment, not `wh_get_out_commit`, keeps verify off the not-yet-built accessor path — see Dependencies mitigation.)
Reproducibility (M10): the OK result is recomputable byte-identically from `artifact_payload` + the stored payload alone.

### `mf_verify(manifest_id, artifact_payload, payload_len)`
1. Null-guard; resolve `idx`: sentinel-loop linear scan over `MANIFEST_IDX_COUNT` live slots (`found := MANIFEST_SENT`; on first `ident_eq(MANIFEST_IDX_KEYS+slot*32, manifest_id) == 1u8` set `found := MANIFEST_IDX_VALS[slot]`; the loop condition is driven by the counter `i < MANIFEST_IDX_COUNT` — W14, no `break`; once `found != SENT` the inner `ident_eq` is skipped via an `if found == MANIFEST_SENT` guard, exactly the `cat_find_object` idiom).
2. If `found == MANIFEST_SENT` return `0u8`.
3. Return `mf_verify_by_idx(found, artifact_payload, payload_len)`.
M4 (no heuristics): exact id equality, no fuzzy match. M3 (no ML): the reverse index is an exact key→value map populated only at attach, never observed/promoted.

### `mf_producer` / `mf_op` / `mf_chain_head_at`
- `mf_producer`: prefer built path — read the manifest payload via `wh_get_payload`; producer is NOT in the payload (it is a fragment field), so this accessor uses `wh_get_producer(idx,out)` (NOT-BUILT accessor). *Degraded-build fallback:* return `MANIFEST_E_NOT_FOUND` if the accessor is unavailable. Bound by `idx`.
- `mf_op`: `wh_get_payload(idx,&MANIFEST_RDBUF,...)`; copy `MANIFEST_RDBUF[80..112]` → `out`. Built-only path. `MANIFEST_OK`/`MANIFEST_E_BAD_IDX`.
- `mf_chain_head_at`: `wh_get_payload`; copy `MANIFEST_RDBUF[16..48]` → `out`. Built-only path.
All three index-bound and W12-status-returning; all loops counter-driven (W14).

## KAT Vectors (>= 3)
A `mf_selftest` initializes `wh_init(0u64)` + `mf_init()` then checks:

1. **Attach returns index 0, fragment id non-zero, reverse index populated.**
   Input: `producer = bytes[i]=i+1`, `op = bytes[i]=i+50`, `artifact = 64 bytes payload[i]=3i+1`, `payload_len=64`.
   Expected: `mf_attach(&req) == 0u64`; `out_manifest_id` is not all-zero (OR-accumulate `!= 0`); `MANIFEST_IDX_COUNT == 1`.

2. **Verify-by-idx succeeds on the exact artifact, fails on a one-byte mutation.**
   Expected: `mf_verify_by_idx(0u64, artifact, 64u64) == 1u8`; after `artifact[0] ^= 0xFF`, `mf_verify_by_idx(0u64, artifact_mut, 64u64) == 0u8`; and with correct bytes but wrong length `mf_verify_by_idx(0u64, artifact, 63u64) == 0u8`.

3. **Verify-by-id round-trips through the reverse index.**
   Expected: `mf_verify(out_manifest_id, artifact, 64u64) == 1u8`; `mf_verify(<all-zero id>, artifact, 64u64) == 0u8` (not found → 0).

4. **Commitment determinism / re-derivation (M10).**
   Re-run: a second `mf_init()` (idempotent) leaves `MANIFEST_OPID` byte-identical; recomputing `out_commit = Keccak256(artifact[0..64])` independently and `ident_eq` against `MANIFEST_RDBUF[112..136]` after a `wh_get_payload(0,…)` yields `1u8`. (`Keccak256` correctness is itself pinned by `identifier.iii`'s vector `Keccak256("abc")[0]=0x4e, [31]=0x45`; this module relies on that gate, no new crypto vector introduced.)

`mf_selftest` returns `99u64` on all-pass; `1u64..N` for the first failing check.

## Trap Exposure
- **Trap 1 (multi-line `fn`)**: the gospel's `mf_attach(...)` and the `wh_publish` extern are **multi-line — VIOLATION**. *Fix:* every signature single-line. `mf_attach` is reduced to one `*u8` aggregate param (also satisfies W2), so its signature trivially fits one line; the `wh_publish` extern is written on a single physical line (long, but unbroken).
- **Trap 2 (linker-global const)**: avoided — every module-level `const`/`var` carries the `MANIFEST_` prefix; grep-confirmed no collision.
- **Trap 3 (signed ordering compare SIGSEGV)**: all `i32` status checks use `==`/`!=` (e.g., `if r != 0i32`), never `<`/`>`. Length/index comparisons are on `u64`/`u32` (unsigned — unaffected by Trap 3, which is signed-only). VIOLATION-free.
- **Trap 4 (u32-in-u64-slot)**: `payload_len` arrives as `u64`; the only `u32` is the `wh_publish` `payload_len` arg, produced by `MANIFEST_PAYLOAD_LEN as u32` (a constant 136 — no high-bit garbage). Reverse-index offsets use `slot * 32u64` with `slot:u64`. No `u32 as u64` feeding pointer math without the surrounding value being a known-small constant; where a decoded length is reassembled it is built explicitly from `u64` byte loads. Safe.
- **Trap 5 (u32 pointer store width)**: the serialized `payload_len`/length fields are written **byte-by-byte through `*u8`** (the witness_hook idiom), never `p[0]=v_u32`. Compliant.
- **Trap 6 (nested block comments)**: none — no `/* */` nested; inline notes use `--` only.
- **Trap 7 (local var arrays)**: all scratch (`MANIFEST_PAYLOAD_SCRATCH`, `MANIFEST_RDBUF`, `MANIFEST_CMP_OC`, the reverse-index tables) is **module scope**. The module is single-threaded/serialized (manifests are published one at a time under the witness lock), so module-scope scratch is acceptable; noted explicitly.
- **Trap 8 (`} else {`)**: spec uses no `else`; all control flow is guarded early-returns and counter loops. If Phase 2 introduces an `else`, it must be on one line.
- **Trap 9 (em-dash in comment)**: skeleton uses ASCII `--` exclusively; no U+2014.
- **Trap 10 (`let mut` checkpoint flag)**: `mf_init` uses an **early-return** on `MANIFEST_INITED == 1u8` rather than a mutated checkpoint flag mid-body. `MANIFEST_INITED` is a module-scope `var` set once, read as a gate — not a per-call `let mut`.
- **Trap 11 (`a % b` after call)**: **no modulo anywhere** in this module. All addressing is `slot * 32u64` (multiply, not mod). VIOLATION-free.
- **Trap 12 (`@specialize *T` stride)**: module is **not generic**; no `@specialize`. N/A.

## Gap / Fix List
The candidate body is PARTIAL/stubbed. Each gap with its fix:

1. **`mf_verify` is a hardcoded `return 0u8` stub (gospel lines 1731-1738).** It can never validate a manifest. *Fix:* implement the reverse-index linear scan (`mf_verify` Algorithm) populated by `mf_attach`, then delegate to `mf_verify_by_idx`. Requires the new `MANIFEST_IDX_*` tables.

2. **`mf_verify_by_idx` depends on `wh_get_out_commit`, which does NOT exist in the built `witness_hook.iii`.** (The accessor is only in the gospel Turn-One Addendum, not the 316-line built file.) *Fix:* source the out_commit from the **manifest payload itself** (offset `[112..136]`), which `mf_attach` now writes, read via the already-built `wh_get_payload`. This removes the hard dependency on the not-yet-built accessor and makes verify reproducible from payload alone (M10). The three addendum accessors (`wh_get_out_commit`/`wh_get_producer`/`wh_get_at_time`) are still listed as deps for the optional `mf_producer` accessor and must be landed by the wave scheduler, but verify no longer blocks on them.

3. **Wrong extern source: `keccak256_init/update/final from "keccak.iii"` (gospel lines 1699-1701).** `keccak.iii` (`module numera_keccak`) provides only low-level `keccak_f1600`/`keccak_absorb`/`keccak_squeeze`; the streaming `keccak256_*` API lives in **`keccak256.iii`** (confirmed: `keccak256_init/update/final/oneshot` at keccak256.iii:46/52/62/35). *Fix:* extern from `"keccak256.iii"`.

4. **Externs declared inside function bodies (gospel lines 1699-1701 inside `mf_attach`; line 1766 inside `mf_verify_by_idx`).** Non-idiomatic and risks duplicate-decl friction. *Fix:* hoist all externs to module scope (matches `witness_hook.iii`/`fed_admit.iii` house style).

5. **W2 violation: `mf_attach` has 5 parameters.** *Fix:* pass a single `*u8` aggregate (`MfAttachReq`: `artifact_payload`, `payload_len`, `producer`, `op`, `out_manifest_id` at fixed offsets). One param → W2 satisfied and signature fits one physical line (also resolves Trap 1 for this fn).

6. **Element-address form `&MF_OPID[0u64]`, `&in_commit[0u64]` (gospel lines 1682, 1693-1695, etc.).** The built tree's house style (witness_hook, fed_admit) is `(&ARR as u64) as *u8` / `((&ARR as u64) + off) as *u8`; the witness_hook reconciliation explicitly notes `&ARR[expr]` was converted away. *Fix:* use the `(&ARR as u64 + off) as *u8` form throughout for module-scope buffers.

7. **Trap 2 prefix mismatch: gospel uses short `MF_` for module-level `const`/`var`.** Dispatch PREFIX is `MANIFEST_`. *Fix:* rename every module-level `const`/`var` to `MANIFEST_…`; keep `mf_` only on public *function* names (consumers reference those; functions are not the Trap-2 hazard).

8. **`mf_attach` local `var in_commit/out_commit/chain_head/manifest_payload` arrays (gospel lines 1690-1692, 1710).** Trap 7 says local `var` arrays parse only at module scope. *Fix:* fold all four into the single module-scope `MANIFEST_PAYLOAD_SCRATCH` (chain_head→[16..48], in_commit→[48..80], out_commit→[112..136]) plus the payload is the buffer itself; no function-local arrays remain.

9. **Maximal-intent payload under-spec.** Gospel payload is 40 bytes (`payload_len || chain_head` only), dropping op/in_commit/out_commit from the self-describing record, so a consumer cannot reconstruct the operation type or commitments from the manifest payload alone. *Fix:* adopt the 136-byte layout (Data Structures) carrying time, chain_head, in_commit, op, out_commit — realizing "records producing module, operation type, input commitment, prior witness chain head" in full.

10. **No self-test in the gospel body.** Every built module ships `*_selftest` returning `99`. *Fix:* add `mf_selftest` per KAT Vectors.

**Mandate check (clean after fixes):** M1 (only libc + BOOT-tier `identifier`/`keccak256`/`witness_hook` — all III modules, no third-party). M2/W5 (pure hashes of recorded bytes). M3/M4 (exact id map, no observation/promotion, no heuristics). M5 (hook-full → sentinel refusal, never corruption). M6/M10 (manifest *is* a witness fragment; commitments recomputable). M8 (the *producer* capability is the implicit gate — only a holder of a valid producer id publishes; the module itself adds no new privilege, consistent with R0). M16 (chain_head recorded → ratifiable anchor). M19 (cost bounded: O(payload_len) hash + O(MANIFEST_IDX_COUNT) lookup, both bounded by W8 caps). No mandate violation remains.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/manifest.iii
 *
 * III STDLIB - aether::manifest
 *
 * Provenance manifests. Every artifact carries a manifest fragment id.
 * A manifest IS a witness fragment (opid = MANIFEST_OPID). The 136-byte
 * payload self-describes: artifact length, attach-time placeholder, prior
 * chain head, in_commit, op id, out_commit. A local reverse index maps a
 * manifest fragment id back to its witness-hook index for id-keyed verify.
 *
 * Public API:
 *   mf_init() -> i32
 *   mf_attach(req: *u8) -> u64           -- req = MfAttachReq aggregate
 *   mf_verify_by_idx(idx: u64, artifact_payload: *u8, payload_len: u64) -> u8
 *   mf_verify(manifest_id: *u8, artifact_payload: *u8, payload_len: u64) -> u8
 *   mf_producer(idx: u64, out: *u8) -> i32
 *   mf_op(idx: u64, out: *u8) -> i32
 *   mf_chain_head_at(idx: u64, out: *u8) -> i32
 *   mf_selftest() -> u64
 *
 * MfAttachReq aggregate (caller-owned, little-endian, byte offsets):
 *   [ 0.. 8) artifact_payload pointer (u64)
 *   [ 8..16) payload_len (u64)
 *   [16..24) producer pointer (u64)
 *   [24..32) op pointer (u64)
 *   [32..40) out_manifest_id pointer (u64)
 *
 * Hexad: kind_witness.  Ring: R0.  K: 1.00.
 * Discipline: W2 (aggregate req), W8 (bounded reverse index), W12, W14.
 */
module aether_manifest

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_payload(idx: u64, out_buf: *u8, max_len: u64, out_len: *u64) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_frag_id(idx: u64, out_id: *u8) -> i32 from "witness_hook.iii"
/* NOT-YET-BUILT (gospel addendum): land in witness_hook.iii before mf_producer compiles */
extern @abi(c-msvc-x64) fn wh_get_producer(idx: u64, out: *u8) -> i32 from "witness_hook.iii"

const MANIFEST_OK          : i32 =  0i32
const MANIFEST_E_NULL      : i32 = -1i32
const MANIFEST_E_BAD_IDX   : i32 = -2i32
const MANIFEST_E_NOT_FOUND : i32 = -3i32
const MANIFEST_E_FULL      : i32 = -4i32

const MANIFEST_PAYLOAD_LEN : u64 = 136u64
const MANIFEST_PILLAR      : u16 = 5u16
const MANIFEST_OPID_STRLEN : u64 = 24u64
const MANIFEST_MAX_INDEX   : u64 = 1048576u64
const MANIFEST_SENT        : u64 = 0xFFFFFFFFFFFFFFFFu64

/* MANIFEST_OPID = Keccak256("aether::manifest::attach"); cached at boot. */
var MANIFEST_OPID    : [u8; 32]
var MANIFEST_INITED  : u8 = 0u8

/* serialized manifest payload built in mf_attach (single-threaded use) */
var MANIFEST_PAYLOAD_SCRATCH : [u8; 136]

/* reverse index: fragment-id -> witness-hook index.  Bound = WH_MAX_FRAGMENTS. */
var MANIFEST_IDX_KEYS  : [u64; 4194304]   /* 1048576 * 32 bytes */
var MANIFEST_IDX_VALS  : [u64; 1048576]
var MANIFEST_IDX_LIVE  : [u8;  1048576]
var MANIFEST_IDX_COUNT : u64 = 0u64

/* verify / accessor scratch */
var MANIFEST_RDBUF : [u8; 136]
var MANIFEST_CMP_OC : [u8; 32]
var MANIFEST_ZERO_ID : [u8; 32]

/* ---- self-test scratch ---- */
var MANIFEST_T_PROD : [u8; 32]
var MANIFEST_T_OP   : [u8; 32]
var MANIFEST_T_PAY  : [u8; 64]
var MANIFEST_T_MID  : [u8; 32]
var MANIFEST_T_REQ  : [u8; 40]

fn mf_init() -> i32 @export {
    // TODO: body per Algorithm mf_init -- idempotent early-return on MANIFEST_INITED==1u8;
    // ident_from_bytes("aether::manifest::attach", 24, &MANIFEST_OPID); zero count; set inited.
    return MANIFEST_OK
}

fn mf_attach(req: *u8) -> u64 @export {
    // TODO: body per Algorithm mf_attach -- decode 5 req fields; null-guard;
    // wh_chain_root -> scratch[16..48]; in_commit = K256(producer||op||head) streaming -> [48..80];
    // out_commit = ident_from_bytes(artifact) -> [112..136]; serialize len LE [0..8] byte-wise,
    // time placeholder [8..16], copy op -> [80..112]; wh_publish(...,MANIFEST_PAYLOAD_LEN as u32,...);
    // sentinel-check; append reverse-index slot; return idx.
    return MANIFEST_SENT
}

fn mf_verify_by_idx(idx: u64, artifact_payload: *u8, payload_len: u64) -> u8 @export {
    // TODO: body per Algorithm mf_verify_by_idx -- wh_get_payload(idx,&MANIFEST_RDBUF,136,&out_len);
    // check rc != 0i32 / out_len != 136; decode stored_len[0..8]; require stored_len==payload_len;
    // ident_from_bytes(artifact)->MANIFEST_CMP_OC; return ident_eq(CMP_OC, RDBUF[112..136]).
    return 0u8
}

fn mf_verify(manifest_id: *u8, artifact_payload: *u8, payload_len: u64) -> u8 @export {
    // TODO: body per Algorithm mf_verify -- null-guard; sentinel-loop linear scan over
    // MANIFEST_IDX_COUNT live slots (found-guard idiom, W14); if not found return 0u8;
    // else return mf_verify_by_idx(found, artifact_payload, payload_len).
    return 0u8
}

fn mf_producer(idx: u64, out: *u8) -> i32 @export {
    // TODO: body per Algorithm -- index-bound; wh_get_producer(idx,out) (NOT-BUILT dep);
    // degraded fallback returns MANIFEST_E_NOT_FOUND. Returns MANIFEST_OK / MANIFEST_E_BAD_IDX.
    return MANIFEST_E_BAD_IDX
}

fn mf_op(idx: u64, out: *u8) -> i32 @export {
    // TODO: body per Algorithm -- wh_get_payload(idx,&MANIFEST_RDBUF,136,&out_len);
    // rc/out_len check; copy MANIFEST_RDBUF[80..112] -> out (32 bytes); return MANIFEST_OK.
    return MANIFEST_E_BAD_IDX
}

fn mf_chain_head_at(idx: u64, out: *u8) -> i32 @export {
    // TODO: body per Algorithm -- wh_get_payload; copy MANIFEST_RDBUF[16..48] -> out (32 bytes).
    return MANIFEST_E_BAD_IDX
}

fn mf_selftest() -> u64 @export {
    // TODO: body per KAT Vectors 1-4 -- wh_init(0); mf_init(); build req in MANIFEST_T_REQ;
    // attach; assert idx==0 & id nonzero & count==1; verify_by_idx pass/mutate-fail/len-fail;
    // verify by id pass / zero-id fail; return 99u64 on all-pass else first failing code.
    return 99u64
}
```
