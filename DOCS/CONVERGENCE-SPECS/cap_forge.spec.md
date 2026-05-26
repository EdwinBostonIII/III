# 37 aether/cap_forge.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is a coherent skeleton with a correct deforge-cascade core (W15 work-list), but it is **internally contradictory** (header API uses `u32` cap-slot args; the actual code uses `*u8` identifier-triple args), it externs **three fictional capability primitives** (`cap_grant`, single-arg `cap_revoke`, and the wrong-file keccak trio), its dependency registry is **never populated** so the de-forge cascade can never fire, and it never integrates the real `aether/capability.iii` model (u64 id + u64 rights bitmask) at all. Every gap is closed below; the maximal intent (content-addressed forge derivation + witnessed transitive de-forge over the REAL capability fabric) is realized.

## Purpose
`aether::cap_forge` is the **capability fibration synthesizer** (Layer 7). It forges new derived capabilities from existing ones via three immutable operations — `compose` (A then B, scope = union), `restrict` (A narrowed to a resource subset), `split` (A partitioned into a disjoint sub-capability) — each producing a content-addressed derived capability whose subject/op/resource identifiers are Keccak256 derivations over the antecedents' identifiers. Every forge publishes a `CAP_FORGE` witness fragment naming the antecedent capability ids and the new capability id as out-commit; de-forging is automatic and witnessed: when any antecedent capability is revoked, every transitively dependent forged capability is revoked in topological order with a chain of `CAP_DEFORGE` fragments. The forged fibration is **immutable after forging** (W18/M8 — no field of a live forged slot is mutable except its LIVE/revocation bit). Hexad: `kind_motion + kind_witness`. Ring: **R−1**. K-vector: **1.00**.

## Public API
All slot-returning functions use the sentinel `CFORGE_SENT = 0xFFFFFFFFu32` for failure (W12). All `-> i32` return `CFORGE_OK`/negative error (W9). All `-> u8` are boolean 0/1 (W10).

```
fn cf_init() -> i32 @export
fn cf_forge_compose(cap_a: u64, cap_b: u64, rights_mask: u64, out_cap: *u64) -> u32 @export
fn cf_forge_restrict(cap_a: u64, sub_resource: *u8, rights_mask: u64, out_cap: *u64) -> u32 @export
fn cf_forge_split(cap_a: u64, partition_pred: u32, partition_index: u32, out_cap: *u64) -> u32 @export
fn cf_deforge_cascade(revoked_cap: u64) -> u32 @export
fn cf_add_dependency(derived_slot: u32, source_slot: u32) -> i32 @export
fn cf_slot_of_cap(cap: u64) -> u32 @export
fn cf_forged_cap(slot: u32) -> u64 @export
fn cf_forged_frag(slot: u32) -> u64 @export
fn cf_is_live(slot: u32) -> u8 @export
fn cf_kind(slot: u32) -> u8 @export
fn cf_dependency_count(slot: u32) -> u32 @export
fn cf_dependency_at(slot: u32, idx: u32) -> u32 @export
fn cf_count() -> u32 @export
fn cf_selftest() -> u64 @export
```

Return-status notes:
- `cf_forge_*` return the **forged slot index** (`u32`) and write the **forged capability id** (`u64` from `cap_attenuate`) into `*out_cap`; on failure they return `CFORGE_SENT` and write `0u64` (the invalid cap id) to `*out_cap`. Four-param ceiling (W2) is exactly met by folding `rights_mask` + `out_cap` into the signature; `compose`/`restrict` are at 4, `split` at 4.
- `cf_deforge_cascade` returns the **count** (`u32`) of forged capabilities revoked (0 on bad input, never a sentinel — count is total-by-construction).
- `cf_add_dependency`, `cf_init` return `i32` status.
- `cf_slot_of_cap`/`cf_dependency_at` return `CFORGE_SENT` when absent.
- `cf_selftest` returns `99u64` on pass (house idiom, cf. `wh_selftest`).

**Antecedent capacity (W2 escape):** `compose` legitimately has two antecedent capabilities. Rather than thread both through a >4-param call, the forged slot's antecedent set is recorded **inside** `cf_forge_compose` (it knows both `cap_a` and `cap_b`); `cf_forge_restrict`/`cf_forge_split` record their single antecedent. `cf_add_dependency` remains exported for explicit cross-forge fibration edges (a forged cap used as antecedent to a later forge), but auto-population fixes the dead-cascade defect.

## Constant Namespace
`PREFIX = CFORGE_` — **grep of `STDLIB/` returned no collision** (no existing `CFORGE_` symbol; the gospel's own `CF_` prefix collides with nothing either, but `CFORGE_` is the assigned prefix and is used throughout). Module-level constants:

| name | type | value |
|---|---|---|
| `CFORGE_OK` | i32 | `0i32` |
| `CFORGE_E_BAD` | i32 | `-1i32` |
| `CFORGE_E_FULL` | i32 | `-2i32` |
| `CFORGE_E_DENIED` | i32 | `-3i32` |
| `CFORGE_SENT` | u32 | `0xFFFFFFFFu32` |
| `CFORGE_MAX_FORGED` | u32 | `2048u32` |
| `CFORGE_MAX_ANTE` | u32 | `4u32` |
| `CFORGE_KIND_COMPOSE` | u8 | `0u8` |
| `CFORGE_KIND_RESTRICT` | u8 | `1u8` |
| `CFORGE_KIND_SPLIT` | u8 | `2u8` |
| `CFORGE_PILLAR` | u16 | `2u16` |
| `CFORGE_PHASE` | u8 | `6u8` |
| `CFORGE_REVTAG_FORGE` | u8 | `0u8` |
| `CFORGE_REVTAG_DEFORGE` | u8 | `1u8` |
| `CFORGE_NO_EXPIRY` | u64 | `0u64` |

No constant named `OK`/`MAX`/`BUF_LEN`/`SENT` is emitted unprefixed (Trap 2 honored). `CFORGE_SENT` value equals the `cons_find`/`cap_slot_of` sentinel `0xFFFFFFFFu32` by design (§3.5-3 convention).

## Data Structures
All module-scope, statically sized (W8). Bound `CFORGE_MAX_FORGED = 2048` matches the gospel and is justified: the forged-capability population in a single address space is bounded by the live capability slot table (`capability.iii` `CAP_MAX_INSTANCES = 256`) times a small composition fan-out; 2048 gives 8× headroom and keeps the largest array (identifier triples) at 192 KiB, well inside the small code model's RIP-relative reach.

| name | type | size (elems) | bytes | purpose / bound |
|---|---|---|---|---|
| `CFORGE_LIVE` | `[u8; 2048]` | 2048 | 2048 | slot occupancy (1 = forged & not de-forged) |
| `CFORGE_KIND` | `[u8; 2048]` | 2048 | 2048 | 0 compose / 1 restrict / 2 split |
| `CFORGE_CAPID` | `[u64; 2048]` | 2048 | 16384 | the forged capability id (`cap_attenuate` result) |
| `CFORGE_SUBJECT` | `[u8; 65536]` | 65536 | 65536 | 2048 × 32-byte subject identifier |
| `CFORGE_OP` | `[u8; 65536]` | 65536 | 65536 | 2048 × 32-byte op identifier |
| `CFORGE_RESOURCE` | `[u8; 65536]` | 65536 | 65536 | 2048 × 32-byte resource identifier |
| `CFORGE_FRAG` | `[u64; 2048]` | 2048 | 16384 | `CAP_FORGE` fragment index from `wh_publish` |
| `CFORGE_ANTE_CNT` | `[u32; 2048]` | 2048 | 8192 | antecedent count per forged slot (≤ `CFORGE_MAX_ANTE`) |
| `CFORGE_ANTE` | `[u32; 8192]` | 8192 | 32768 | 2048 × 4 antecedent **forged-slot** ids |
| `CFORGE_ANTE_CAP` | `[u64; 8192]` | 8192 | 65536 | 2048 × 4 antecedent **capability** ids (for source-revocation test) |
| `CFORGE_USED` | `u32` (scalar) | — | — | running count of live forged slots |
| `CFORGE_PRODUCER` | `[u8; 32]` | 32 | 32 | producer identifier `ident("aether::cap_forge")` |
| `CFORGE_OPID_FORGE` | `[u8; 32]` | 32 | 32 | op id `ident("aether::cap_forge::forge")` |
| `CFORGE_OPID_DEFORGE` | `[u8; 32]` | 32 | 32 | op id `ident("aether::cap_forge::deforge")` |
| `CFORGE_INITED` | `u8` (scalar) | — | — | init guard |
| `CFORGE_REVOKED_SET` | `[u8; 2048]` | 2048 | 2048 | de-forge work-list bitmap (module scope — Trap 7; **non-reentrant**, see Trap Exposure) |
| `CFORGE_INC` | `[u8; 32]` | 32 | 32 | scratch: in-commit (chain root) for `wh_publish` |
| `CFORGE_OUTC` | `[u8; 32]` | 32 | 32 | scratch: out-commit (Keccak of forged triple) |
| `CFORGE_FID` | `[u8; 32]` | 32 | 32 | scratch: fragment-id sink for `wh_publish` |
| `CFORGE_PBUF` | `[u8; 8]` | 8 | 8 | scratch: split partition_pred‖index little-endian bytes |
| `CFORGE_ANTE_IDBUF` | `[u8; 128]` | 128 | 128 | scratch: up to 4 antecedent 32-byte ids packed for `wh_publish` antecedents param |

No local `var` arrays anywhere (Trap 7): the gospel's function-local `var in_c/out_c/fid/pbuf` are all hoisted to the prefixed module-scope scratch buffers above.

## Dependencies (externs)
Every extern below is declared `extern @abi(c-msvc-x64) fn ... from "<file>.iii"`. **All providers are already BUILT** — there are **zero not-yet-built dependencies**. The gospel's three fictional externs are removed and replaced with the real symbols.

| extern | from | provider NN | status | note |
|---|---|---|---|---|
| `ident_from_bytes(input:*u8, in_len:u64, out:*u8) -> i32` | `identifier.iii` | — | BUILT | numera/identifier.iii |
| `ident_copy(src:*u8, dst:*u8) -> i32` | `identifier.iii` | — | BUILT | |
| `ident_eq(a:*u8, b:*u8) -> u8` | `identifier.iii` | — | BUILT | |
| `keccak256_init() -> i32` | `keccak256.iii` | — | BUILT | **gospel said `keccak.iii` — WRONG (Defect #1)** |
| `keccak256_update(input:*u8, len:u64) -> i32` | `keccak256.iii` | — | BUILT | |
| `keccak256_final(out:*u8) -> i32` | `keccak256.iii` | — | BUILT | |
| `wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `witness_hook.iii` | 07 | BUILT | signature verified byte-for-byte against the built file |
| `wh_chain_root(out_id:*u8) -> i32` | `witness_hook.iii` | 07 | BUILT | |
| `cap_attenuate(parent_id:u64, rights_mask:u64, expires_at:u64) -> u64` | `capability.iii` | — | BUILT | **replaces fictional `cap_grant` (Defect #5)** |
| `cap_revoke(authority_id:u64, target_id:u64) -> i32` | `capability.iii` | — | BUILT | **real 2-arg form; gospel's single-arg `cap_revoke(frag:u64)` is FICTION** |
| `cap_verify_rights(id:u64, required:u64) -> u8` | `capability.iii` | — | BUILT | used to confirm antecedent rights before forging |
| `cap_is_revoked(id:u64) -> u8` | `capability.iii` | — | BUILT | used by cascade to detect a revoked source capability |
| `cap_rights(id:u64) -> u64` | `capability.iii` | — | BUILT | read antecedent rights for the union/restriction mask |

Optional getters from §3.5-6 (witness_hook accessors): **not required** by this module. cap_forge holds its own `CFORGE_FRAG[]` and `CFORGE_CAPID[]`, so it never needs to read fragment fields back out of witness_hook. No Phase-2 getter additions are blocked on this module.

## Algorithm

### `cf_init() -> i32`
Zero `CFORGE_LIVE[0..2048]`; set `CFORGE_USED = 0`; derive the three identifiers with `ident_from_bytes`:
- producer = `ident("aether::cap_forge")` (17 bytes)
- forge opid = `ident("aether::cap_forge::forge")` (24 bytes)
- deforge opid = `ident("aether::cap_forge::deforge")` (26 bytes)

Set `CFORGE_INITED = 1`; return `CFORGE_OK`. Deterministic (M2): the identifiers are fixed Keccak/SHA derivations over constant byte strings, byte-identical every run (W5). The single zeroing loop is a counted sentinel loop, no break (W14). **Idempotent** — if already inited, the zeroing re-runs harmlessly (init never frees live caps in practice it is called once; re-init is a documented reset only when no forged caps are live).

### `cf_alloc() -> u32` (internal)
Linear scan `i = 0..CFORGE_MAX_FORGED`; return first `i` with `CFORGE_LIVE[i] == 0`; else `CFORGE_SENT`. Counted loop, early return on hit (no flag — Trap 10 avoided). Deterministic: lowest free slot always chosen.

### `cf_compose_hash(tag:*u8, tag_len:u64, a:*u8, b:*u8, out:*u8) -> i32` (internal)
`out = Keccak256(tag ‖ a[0..32] ‖ b[0..32])` via streaming `keccak256_init/update×3/final`. Hand-rolled Keccak (M1, provider is NIH). Content-addressed ⇒ deterministic + bit-identical (M2/W5). Used for compose (all three fields) and restrict (resource field only).

### `cf_forge_compose(cap_a:u64, cap_b:u64, rights_mask:u64, out_cap:*u64) -> u32`
1. If `CFORGE_INITED == 0` call `cf_init()`.
2. **Validate antecedents (M8):** `cap_a` and `cap_b` must both be non-zero, non-revoked. Use `cap_is_revoked(cap_a)`/`cap_is_revoked(cap_b)` — if either returns 1, write `0u64` to `*out_cap`, return `CFORGE_SENT` (`CFORGE_E_DENIED` path collapses to sentinel for a slot-returning fn).
3. `slot = cf_alloc()`; if `CFORGE_SENT`, write `0u64` to `*out_cap`, return `CFORGE_SENT`.
4. `CFORGE_KIND[slot] = CFORGE_KIND_COMPOSE`.
5. Derive the forged identifiers from the **antecedent capability ids** (the cap ids are the stable content-address inputs — we serialize each `u64` cap id to its 8 little-endian bytes, padded into the 32-byte subject/op/resource derivation tags). Specifically, build a 32-byte identifier of each antecedent via `ident_from_bytes(&capid_le8, 8, tmp)` is **not** used; instead the two cap ids are written little-endian into a scratch and hashed: `subject_new = Keccak256("compose::subject" ‖ id8(cap_a) ‖ id8(cap_b))`, similarly `compose::op`, `compose::resource`. (Using the cap ids — not raw `*u8` triples — fixes the API contradiction and binds the derivation to the real capability fabric.)
6. **Forge the real capability:** `new_rights = (cap_rights(cap_a) | cap_rights(cap_b)) & rights_mask` — compose's action is "exercise A then B" so the derived right-set is the **union** of A's and B's rights, attenuated by the caller's `rights_mask`. Parent for `cap_attenuate` is `cap_a` (the primary antecedent; the cascade tracks `cap_b` as an explicit antecedent too). `new_cap = cap_attenuate(cap_a, new_rights, CFORGE_NO_EXPIRY)`. If `new_cap == 0u64`, free slot, write `0`, return sentinel.
   - *Note (M9/W18):* the forged cap is a genuine attenuation child of `cap_a` in `capability.iii`, so the substrate's existing revocation walk already kills it if `cap_a` is revoked. cap_forge's cascade additionally covers the `cap_b` antecedent edge (which the parent-chain walk does **not** see), making de-forging total.
7. `CFORGE_CAPID[slot] = new_cap`.
8. **Record antecedents (fixes dead-cascade defect):** `CFORGE_ANTE_CNT[slot] = 2`; `CFORGE_ANTE_CAP[slot*4+0] = cap_a`; `CFORGE_ANTE_CAP[slot*4+1] = cap_b`; the forged-slot antecedent entries `CFORGE_ANTE[slot*4+k]` are set to `CFORGE_SENT` unless the antecedent cap is itself a forged cap (resolved via `cf_slot_of_cap`).
9. `CFORGE_LIVE[slot] = 1`; `CFORGE_USED += 1`.
10. **Publish `CAP_FORGE` fragment:** in_commit = `wh_chain_root`; out_commit = `Keccak256(subject_new ‖ op_new ‖ resource_new)`; antecedents buffer = `id8(cap_a)` and `id8(cap_b)` packed as two 32-byte ids (`n_ante = 2`); payload = out_commit (32 bytes); `revtag = CFORGE_REVTAG_FORGE`, `phase = CFORGE_PHASE`, `pillar = CFORGE_PILLAR`. `CFORGE_FRAG[slot] = wh_publish(...)`.
11. Write `new_cap` to `*out_cap`; return `slot`.

Determinism (M2/M10): every byte fed to `cap_attenuate`, `cap_rights`, and `wh_publish` is a pure function of `(cap_a, cap_b, rights_mask)` and the deterministic capability-slot/witness state; the published fragment is byte-recomputable from those inputs (M10). No recursion (W15). No modulo-after-call (Trap 11 N/A — no `%`).

### `cf_forge_restrict(cap_a:u64, sub_resource:*u8, rights_mask:u64, out_cap:*u64) -> u32`
As compose but single antecedent:
- subject_new/op_new = **copy** of `cap_a`'s identifiers? — No: cap ids are opaque `u64`, so restrict derives `subject_new = Keccak256("restrict::subject" ‖ id8(cap_a))`, `op_new = Keccak256("restrict::op" ‖ id8(cap_a))`, `resource_new = Keccak256("restrict::resource" ‖ id8(cap_a) ‖ sub_resource[0..32])`. The resource narrows; subject/op are content-stable rederivations of the same antecedent.
- `new_rights = cap_rights(cap_a) & rights_mask` (narrow only — never widen; M8/least-privilege).
- `new_cap = cap_attenuate(cap_a, new_rights, CFORGE_NO_EXPIRY)`.
- `CFORGE_ANTE_CNT = 1`; `CFORGE_ANTE_CAP[slot*4+0] = cap_a`; `CFORGE_KIND = CFORGE_KIND_RESTRICT`.
- Publish `CAP_FORGE` with `n_ante = 1`, antecedents = `id8(cap_a)`.

### `cf_forge_split(cap_a:u64, partition_pred:u32, partition_index:u32, out_cap:*u64) -> u32`
- `resource_new = Keccak256("split::resource" ‖ id8(cap_a) ‖ le4(partition_pred) ‖ le4(partition_index))` (8-byte `CFORGE_PBUF` packs pred‖index little-endian, exactly as the gospel's `pbuf`).
- subject_new = `Keccak256("split::subject" ‖ id8(cap_a))`, op_new = `Keccak256("split::op" ‖ id8(cap_a))`.
- `new_rights = cap_rights(cap_a) & rights_mask` — split sub-capability inherits the parent's rights unchanged for v1.0 (`rights_mask = cap_rights(cap_a)` effectively, but caller may pass a narrower mask). Since this fn has no `rights_mask` slot (4-param ceiling already met by `out_cap`), the split inherits **`cap_rights(cap_a)` verbatim** — a split partitions the *resource*, not the rights. `new_cap = cap_attenuate(cap_a, cap_rights(cap_a), CFORGE_NO_EXPIRY)`.
- `CFORGE_ANTE_CNT = 1`; `CFORGE_ANTE_CAP[slot*4+0] = cap_a`; `CFORGE_KIND = CFORGE_KIND_SPLIT`.
- Publish `CAP_FORGE` with `n_ante = 1`.

### `cf_add_dependency(derived_slot:u32, source_slot:u32) -> i32`
Records an explicit fibration edge from one forged slot to another (when a forged cap is later used as an antecedent to a further forge, and the auto-population in step 8 could not resolve it because the source was forged after). Bounds-check both `< CFORGE_MAX_FORGED`, both `LIVE`, and `CFORGE_ANTE_CNT[derived] < CFORGE_MAX_ANTE` → append `source_slot` to `CFORGE_ANTE[derived*4 + n]`, also store `CFORGE_ANTE_CAP[derived*4+n] = CFORGE_CAPID[source_slot]`, increment count. Return `CFORGE_OK` or `CFORGE_E_BAD`. (Identical to the gospel's `cf_add_dependency`, with the cap-id mirror added.)

### `cf_slot_of_cap(cap:u64) -> u32`
Linear scan for the live slot whose `CFORGE_CAPID[i] == cap`; return `i` or `CFORGE_SENT`. Counted loop, early return.

### `cf_deforge_cascade(revoked_cap:u64) -> u32`
The maximal de-forge: when `revoked_cap` (any capability id — forged or a base antecedent) is revoked, revoke every forged capability transitively depending on it, in topological order, each witnessed. **Hand-rolled fixpoint over a bitmap work-list (W15 — no recursion):**
1. Zero `CFORGE_REVOKED_SET[0..2048]`.
2. **Seed:** for each live slot `s`, if any of its `CFORGE_ANTE_CAP[s*4+k]` (k < count) equals `revoked_cap`, OR `CFORGE_CAPID[s] == revoked_cap`, set `CFORGE_REVOKED_SET[s] = 1`. (Also: if `revoked_cap` is itself a forged cap, its own slot seeds the set.) This connects the *capability* layer to the forged-slot layer — the missing link in the gospel.
3. **Fixpoint:** `changed = 1`; while `changed == 1`: `changed = 0`; for each live slot `s` not yet in the set, scan its antecedent **forged-slot** ids `CFORGE_ANTE[s*4+k]`; if any names a slot already in the set, mark `s`, set `changed = 1`. (`hit` flag drives the inner scan without `break` — W14.) Terminates: the set is monotone non-decreasing and bounded by 2048, so at most 2048 outer passes.
4. **Apply (topological by construction — a slot is only revoked after all its antecedents were marked in an earlier pass):** for each `s` with `CFORGE_REVOKED_SET[s] == 1` and `CFORGE_LIVE[s] == 1`: call `cap_revoke(CFORGE_CAPID[s], CFORGE_CAPID[s])` — *self-authority revoke is invalid in capability.iii (authority must dominate target); instead revoke via the parent that minted it.* The correct call is `cap_revoke(parent_authority, CFORGE_CAPID[s])`; since cap_forge minted the cap as a child of its primary antecedent `CFORGE_ANTE_CAP[s*4+0]`, use that as authority: `cap_revoke(CFORGE_ANTE_CAP[s*4+0], CFORGE_CAPID[s])`. Set `CFORGE_LIVE[s] = 0`; `CFORGE_USED -= 1`; `total += 1`; publish a `CAP_DEFORGE` fragment (revtag = `CFORGE_REVTAG_DEFORGE`, out_commit = `Keccak256` of the forged triple, antecedents = the now-dead cap id). Skip the slot equal to `revoked_cap`'s own slot (it was revoked by the external caller, not by the cascade) to avoid double counting.
5. Return `total`.

Determinism (M2): the bitmap fixpoint visits slots in fixed ascending order each pass; the revocation order is therefore reproducible, and the `CAP_DEFORGE` chain is byte-identical for identical pre-states (M10). No ML/heuristic — pure transitive-closure (M3/M4). M5 (no bricking): revocation is the *recoverable refusal* state; a forged cap can be re-forged from live antecedents. **Reversibility (M9):** de-forge is capability-gated (only fires from an actual upstream revocation) and fully witnessed, satisfying the "reversible unless capability-gated otherwise" rule.

### Query accessors
`cf_forged_cap(slot)` → `CFORGE_CAPID[slot]` (or `0u64` if dead/oob); `cf_forged_frag(slot)` → `CFORGE_FRAG[slot]`; `cf_is_live(slot)` → `CFORGE_LIVE[slot]`; `cf_kind(slot)` → `CFORGE_KIND[slot]`; `cf_dependency_count(slot)` → `CFORGE_ANTE_CNT[slot]` (0 if dead/oob); `cf_dependency_at(slot, idx)` → `CFORGE_ANTE[slot*4+idx]` or `CFORGE_SENT`; `cf_count()` → `CFORGE_USED`. All bounds-checked, all counted/early-return, all W12-compliant.

## KAT Vectors (>= 3)
The self-test (`cf_selftest`) runs these and returns `99u64` iff all pass. The capability fabric must be bootstrapped first: `cap_env_init()` returns `CAP_ENV_ROOT = 1`; `wh_init(0)` arms the witness log.

**KAT-1 — Restrict narrows rights, forges a live child.**
Setup: `root = cap_env_init()` (id 1, all rights). `base = cap_attenuate(root, CAP_RIGHT_FS_READ|CAP_RIGHT_FS_WRITE, 0)` (rights `0x6`). Input: `cf_forge_restrict(base, sub_res32, CAP_RIGHT_FS_READ, &outcap)` where `sub_res32` = 32 zero bytes.
Expected: returns slot `0`; `outcap != 0`; `cf_forged_cap(0) == outcap`; `cap_rights(outcap) == 0x2u64` (FS_READ only — write was masked out); `cf_kind(0) == 1`; `cf_dependency_count(0) == 1`; `cf_is_live(0) == 1`; `cf_count() == 1`; `cap_verify_rights(outcap, CAP_RIGHT_FS_READ) == 1` and `cap_verify_rights(outcap, CAP_RIGHT_FS_WRITE) == 0`.

**KAT-2 — Compose unions rights; out-commit is the Keccak of the forged triple.**
Setup (continuing): `capA = cap_attenuate(root, CAP_RIGHT_FS_READ, 0)` (0x2); `capB = cap_attenuate(root, CAP_RIGHT_NET_DIAL, 0)` (0x20). Input: `cf_forge_compose(capA, capB, 0xFFFFFFFFFFFFFFFFu64, &outcap2)`.
Expected: returns slot `1`; `cap_rights(outcap2) == (0x2|0x20)&parentRights == 0x2u64` — **note** `cap_attenuate(capA, …)` intersects with `capA`'s rights (`0x2`), so the realized child rights = `(0x2|0x20) & 0x2 = 0x2`; the KAT asserts exactly `0x2u64` (documents that the attenuation child can never exceed its parent — the union is the *requested* mask, the capability fabric enforces the parent ceiling). `cf_dependency_count(1) == 2`; `cf_dependency_at(1,0)` resolves to the `capA` antecedent record; `cf_kind(1) == 0`. Witness check: the `CAP_FORGE` fragment id at `cf_forged_frag(1)` equals `wh_get_frag_id` of that index, and recomputing `Keccak256(subject1‖op1‖resource1)` reproduces the stored out-commit byte-for-byte (M10).

**KAT-3 — Transitive de-forge cascade.**
Setup: forge `D1 = restrict(base,…)` (slot 0, cap `c0`); forge `D2 = compose(c0, capB,…)` (slot 1, antecedent caps `{c0, capB}`); `cf_add_dependency(1, 0)` to record the forged-slot edge `1←0`. Revoke the upstream: `cap_revoke(root, base)` (root dominates base), then `cf_deforge_cascade(base)`.
Expected: `base` is an antecedent of `c0`? — `c0`'s antecedent cap is `base` ⇒ slot 0 seeds the set; slot 1 has `c0`(=slot0) as a forged-slot antecedent ⇒ marked in the fixpoint. Return value `== 2` (both forged caps revoked). After: `cf_is_live(0) == 0`, `cf_is_live(1) == 0`, `cf_count() == 0`, `cap_is_revoked(c0) == 1`, `cap_is_revoked(outcap2) == 1`. Two `CAP_DEFORGE` fragments were published (witness next-idx advanced by 2 beyond the forge fragments). Re-running `cf_deforge_cascade(base)` returns `0` (idempotent — nothing live left to revoke), proving the fixpoint terminates and the cascade is total.

**KAT-4 (negative — prove the guard FAILS on bad input).**
`cf_forge_compose(0u64, capB, mask, &outcap)` (antecedent `0` = invalid cap) → returns `CFORGE_SENT`, `outcap == 0u64`, `cf_count()` unchanged. `cf_forge_restrict(revoked_cap, …)` where `revoked_cap` was `cap_revoke`d → returns `CFORGE_SENT` (the `cap_is_revoked` guard fires). `cf_dependency_at(9999u32, 0u32)` → `CFORGE_SENT`. `cf_deforge_cascade(0u64)` → `0` (no slot names cap 0). This proves the negative path, not merely the happy path (MEMORY: prove the negative case).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED (long signatures: `wh_publish` extern, `cf_forge_compose`). Avoidance: every `fn`/`extern` signature is on a **single physical line** in the skeleton below; none wrap. The `wh_publish` extern is one line even though it spans ~120 cols.
- **Trap 2 (module-level `const` is linker-global)** — EXPOSED. Avoidance: every const is `CFORGE_`-prefixed; grep of `STDLIB/` confirms no collision. No bare `OK`/`MAX`/`SENT`.
- **Trap 3 (signed-int ordering compare SIGSEGV)** — **NOT exposed.** Every comparison on `i32` constants is equality (`== CFORGE_OK`). All loop bounds and slot comparisons are on `u32`/`u64` (unsigned ordering `<` is safe; the trap is signed-only). The `cf_alloc`/cascade loops use `i < CFORGE_MAX_FORGED` on `u32` — legal.
- **Trap 4 (`u32`-in-`u64`-slot garbage before pointer math)** — EXPOSED in the `slot*32` identifier-pointer arithmetic. Avoidance: compute element pointers as `((&CFORGE_SUBJECT as u64) + (slot as u64)*32u64) as *u8` with `slot` masked `(slot as u64) & 0xFFFFFFFFu64` before the multiply, mirroring witness_hook's `(&ARR as u64)+off` idiom. `slot` originates as a `u32` local from `cf_alloc`.
- **Trap 5 (`u32` pointer store width)** — **NOT exposed.** No `*u32` element stores; the antecedent arrays are written via plain `CFORGE_ANTE[idx] = v` (array-index assignment on a `[u32;…]` module array compiles correctly — the trap is specifically writing through a `*u32` pointer derived from a u32 local). The little-endian `le4`/`le8` packing writes through `*u8` (`CFORGE_PBUF`/`CFORGE_ANTE_IDBUF`) byte-by-byte, which is the trap-5-safe path.
- **Trap 6 (nested `/* */`)** — avoided; comments use a single block level + `//`.
- **Trap 7 (local `var` arrays)** — EXPOSED (gospel used function-local `var in_c/out_c/fid/pbuf` and `var revoked_set`). Avoidance: all hoisted to module-scope prefixed scratch (`CFORGE_INC/OUTC/FID/PBUF/REVOKED_SET/ANTE_IDBUF`). **Reentrancy note:** the shared scratch makes the forge/cascade fns **non-reentrant**; acceptable because cap_forge is invoked serially on the R−1 control path (single-threaded with respect to the capability fabric), exactly like `witness_hook` and `capability`. Documented for Phase 2.
- **Trap 8 (`} else {` split)** — avoided; any else is single-line `} else {`.
- **Trap 9 (em-dash in comment)** — avoided; ASCII `--` only in all comments.
- **Trap 10 (`let mut flag` checkpoint)** — partially exposed (the cascade's `changed` flag legitimately drives the fixpoint `while changed == 1u8`, which is the W14 sentinel pattern, not a misused checkpoint). The `hit` inner flag is read-once per outer-pass slot; safe. No checkpoint-flag-then-test antipattern; allocation uses early-return instead.
- **Trap 11 (`a % b` after call)** — **NOT exposed.** No modulo anywhere; all indexing uses `slot*32` / `slot*4` multiplies (`CFORGE_MAX_ANTE = 4` is a power of two, so even a future mask is byte-safe).
- **Trap 12 (`@specialize *T` stride)** — **NOT exposed.** No generics; all arrays are concrete `[u8;…]`/`[u32;…]`/`[u64;…]`.

## Gap / Fix List
The gospel candidate body is PARTIAL. Every defect and its fix:

1. **API/code contradiction (CRITICAL).** Header documents `cf_forge_compose(cap_a:u32, cap_b:u32)` (cap *slots*), but the `.iii` body's signature is `cf_forge_compose(cap_a_subj:*u8, cap_a_op:*u8, cap_a_res:*u8, cap_b_subj:*u8, cap_b_op:*u8, cap_b_res:*u8)` — **six `*u8` params, violating W2's 4-param ceiling**, and operating on raw identifier triples that the real `capability.iii` does not expose. **Fix:** the realized API takes `u64` capability ids (the real capability model), reads their identifiers/rights via the built `cap_rights`/`cap_attenuate`, and stays ≤4 params by folding `rights_mask`+`out_cap` in. (Spec'd above.)

2. **Fictional extern `cap_grant` (Defect §3.5-5).** `extern cap_grant(subject:*u8, op:*u8, resource:*u8, scope:u16, pred_slot:u32) -> u64 from "capability.iii"` — **does not exist**; verified by reading the entire built `capability.iii`. **Fix:** use `cap_attenuate(parent_id:u64, rights_mask:u64, expires_at:u64) -> u64`. Forged caps are genuine attenuation children.

3. **Fictional extern `cap_revoke(grant_frag:u64) -> i32` (Defect §3.5-5).** The real `cap_revoke` is `cap_revoke(authority_id:u64, target_id:u64) -> i32` and requires the authority to dominate the target. **Fix:** cascade calls `cap_revoke(CFORGE_ANTE_CAP[s*4+0], CFORGE_CAPID[s])` — the minting parent is the dominating authority.

4. **Wrong-file keccak externs (Defect §3.5-1).** Gospel: `extern keccak256_init/update/final from "keccak.iii"`. `keccak.iii` exports only `keccak_f1600/absorb/squeeze`. **Fix:** `from "keccak256.iii"` (verified to export the streaming trio + `keccak256_oneshot`).

5. **Dead de-forge cascade (CRITICAL logic gap).** All three forge fns set `CFORGE_ANTE_CNT[slot] = 0` and the comment claims "compose tracks resource antecedence via hash." Nothing ever populates antecedents, so `cf_deforge_cascade` can **never** mark a dependent slot — the central feature is inert. Additionally the cascade's seed only looks at the forged-slot bitmap, never connecting a revoked **capability id** to the slots that derive from it. **Fix:** (a) each forge auto-records its antecedent capability ids in `CFORGE_ANTE_CAP[]` and count; (b) the cascade seed step matches `revoked_cap` against `CFORGE_ANTE_CAP[]` and `CFORGE_CAPID[]`, bridging the capability layer to the slot layer. Now revoking a base antecedent cascades correctly (KAT-3).

6. **W2 violation in cascade revoke call.** Gospel `cap_revoke(CF_FRAG[s2])` passes the **witness fragment index** as if it were a cap id, to a fictional single-arg revoke. **Fix:** as item 3 — revoke the **capability id** with the minting authority.

7. **Local `var` arrays (Trap 7).** `var in_c/out_c/fid/pbuf` (every forge fn) and `var revoked_set:[u8;2048]` (cascade) are function-local — unsupported by iiis-0 (parse only at module scope). **Fix:** hoisted to module-scope prefixed scratch buffers (`CFORGE_INC/OUTC/FID/PBUF/REVOKED_SET`). Documented non-reentrant.

8. **`out_frag_id` always non-null but scratch reused.** Gospel passes `fp = &fid[0]` (local) as `out_frag_id`. Built `wh_publish` guards `if (out_frag_id as u64) != 0u64` before copying — fine — but the local buffer is the Trap-7 problem. **Fix:** module-scope `CFORGE_FID`.

9. **`cf_init` re-zero races live caps.** `cf_forge_*` call `cf_init()` if `CFORGE_INITED == 0`; but `cf_init` zeroes `CFORGE_LIVE` unconditionally only on first call (guarded by the `INITED` flag in the realized version). Gospel's `cf_init` is **not** idempotent-safe (it zeroes LIVE every call). **Fix:** the auto-init path checks `CFORGE_INITED` and only the *flagged* first init zeroes; explicit re-init is a documented reset (caller's responsibility to have no live forged caps). Identifiers are re-derivable harmlessly.

10. **Determinism of `cap_attenuate` parent ceiling (documented, not a bug).** Because `cap_attenuate` intersects requested rights with the parent's, `compose`'s "union of rights" can never exceed `cap_a`'s rights (the parent). This is **correct least-privilege behavior** (M8) and is asserted in KAT-2 so Phase 2 does not "fix" it into a privilege escalation. For a true union exceeding `cap_a`, both antecedents would have to share a common ancestor with the union — out of scope for v1.0; flagged for the fibration-lattice follow-up.

11. **Witness `pillar/phase/revtag` magic numbers.** Gospel hardcodes `0u8, 6u8, 2u16`. **Fix:** named constants `CFORGE_PHASE=6`, `CFORGE_PILLAR=2`, `CFORGE_REVTAG_FORGE=0`, `CFORGE_REVTAG_DEFORGE=1` (preserves the gospel's values; adds provenance per M14).

**Mandate audit (realized spec):** M1 ✓ (only libc-free III providers; Keccak/identifier/capability/witness all NIH). M2/M10 ✓ (content-addressed, byte-recomputable). M3/M4 ✓ (transitive closure, no learning/heuristic). M5 ✓ (revocation recoverable). M6/M16 ✓ (CAP_FORGE/CAP_DEFORGE fragments chain by hash via `wh_chain_root` in-commit). M7 ✓ (R−1 honored). M8 ✓ (every forge validates + attenuates a real capability; cascade gated on real revocation). M9 ✓ (reversible/refusal; de-forge witnessed). M18 ✓ (forged fibration immutable post-forge except its LIVE bit). M19 ✓ (cascade bounded ≤2048 passes × 2048 slots — finite cost lattice). M13/M20 ✓ (no self-reflection). No mandate violated by the realized design.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures. No fn bodies (Phase 2 writes those per Algorithm §).

```iii
/* III/STDLIB/iii/aether/cap_forge.iii
 *
 * III STDLIB - aether::cap_forge
 *
 * Capability fibration synthesizer. Forge operations on REAL capabilities
 * (u64 id + u64 rights bitmask, per aether/capability.iii):
 *   cf_forge_compose(a,b)  -- chain A then B; rights = (rights(A)|rights(B)) & mask
 *   cf_forge_restrict(a,s) -- narrow A's resource to subset s; rights &= mask
 *   cf_forge_split(a,p,i)  -- partition A's resource by predicate p, index i
 * Each forge attenuates a child cap from the primary antecedent and publishes
 * a CAP_FORGE witness fragment naming the antecedent cap ids.
 *
 * De-forging is automatic + witnessed: when an antecedent capability is
 * revoked, every transitively dependent forged cap is revoked in topological
 * order (bitmap fixpoint work-list, W15), each via a CAP_DEFORGE fragment.
 *
 * Hexad: kind_motion + kind_witness.  Ring: R-1.  K: 1.00.
 * Discipline: W2, W4, W8, W12, W13, W14, W15, W18 (immutable fibration).
 * Non-reentrant: module-scope scratch (iiis local var arrays are module-scope only).
 */

module aether_cap_forge

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_attenuate(parent_id: u64, rights_mask: u64, expires_at: u64) -> u64 from "capability.iii"
extern @abi(c-msvc-x64) fn cap_revoke(authority_id: u64, target_id: u64) -> i32 from "capability.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn cap_is_revoked(id: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn cap_rights(id: u64) -> u64 from "capability.iii"

const CFORGE_OK            : i32 =  0i32
const CFORGE_E_BAD         : i32 = -1i32
const CFORGE_E_FULL        : i32 = -2i32
const CFORGE_E_DENIED      : i32 = -3i32
const CFORGE_SENT          : u32 = 0xFFFFFFFFu32
const CFORGE_MAX_FORGED    : u32 = 2048u32
const CFORGE_MAX_ANTE      : u32 = 4u32
const CFORGE_KIND_COMPOSE  : u8  = 0u8
const CFORGE_KIND_RESTRICT : u8  = 1u8
const CFORGE_KIND_SPLIT    : u8  = 2u8
const CFORGE_PILLAR        : u16 = 2u16
const CFORGE_PHASE         : u8  = 6u8
const CFORGE_REVTAG_FORGE  : u8  = 0u8
const CFORGE_REVTAG_DEFORGE: u8  = 1u8
const CFORGE_NO_EXPIRY     : u64 = 0u64

var CFORGE_LIVE        : [u8;  2048]
var CFORGE_KIND        : [u8;  2048]
var CFORGE_CAPID       : [u64; 2048]
var CFORGE_SUBJECT     : [u8;  65536]
var CFORGE_OP          : [u8;  65536]
var CFORGE_RESOURCE    : [u8;  65536]
var CFORGE_FRAG        : [u64; 2048]
var CFORGE_ANTE_CNT    : [u32; 2048]
var CFORGE_ANTE        : [u32; 8192]
var CFORGE_ANTE_CAP    : [u64; 8192]
var CFORGE_USED        : u32 = 0u32

var CFORGE_PRODUCER    : [u8; 32]
var CFORGE_OPID_FORGE  : [u8; 32]
var CFORGE_OPID_DEFORGE: [u8; 32]
var CFORGE_INITED      : u8 = 0u8

var CFORGE_REVOKED_SET : [u8; 2048]
var CFORGE_INC         : [u8; 32]
var CFORGE_OUTC        : [u8; 32]
var CFORGE_FID         : [u8; 32]
var CFORGE_PBUF        : [u8; 8]
var CFORGE_ANTE_IDBUF  : [u8; 128]

/* --- internal element-pointer helpers (Trap-4 safe: mask slot before *32) --- */
fn cf_subj_ptr(slot: u32) -> *u8 { return ((&CFORGE_SUBJECT as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }
fn cf_op_ptr(slot: u32) -> *u8 { return ((&CFORGE_OP as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }
fn cf_res_ptr(slot: u32) -> *u8 { return ((&CFORGE_RESOURCE as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }

/* --- internal: alloc lowest free slot; CFORGE_SENT if full --- */
fn cf_alloc() -> u32 { return 0u32 } // TODO: body per Algorithm cf_alloc

/* --- internal: id8(cap) little-endian into 8-byte region of an out buffer --- */
fn cf_id8(cap: u64, out8: *u8) -> i32 { return CFORGE_OK } // TODO: body per Algorithm (le8 packing, *u8 byte stores)

/* --- internal: out = Keccak256(tag || a[0..32] || b[0..32]) --- */
fn cf_compose_hash(tag: *u8, tag_len: u64, a: *u8, b: *u8, out: *u8) -> i32 { return CFORGE_OK } // TODO: body per Algorithm cf_compose_hash

/* --- internal: out_commit = Keccak256(subject||op||resource) of a forged slot --- */
fn cf_slot_commit(slot: u32, out: *u8) -> i32 { return CFORGE_OK } // TODO: body per Algorithm (used by forge + deforge publish)

fn cf_init() -> i32 @export { return CFORGE_OK } // TODO: body per Algorithm cf_init

fn cf_forge_compose(cap_a: u64, cap_b: u64, rights_mask: u64, out_cap: *u64) -> u32 @export { return CFORGE_SENT } // TODO: body per Algorithm cf_forge_compose
fn cf_forge_restrict(cap_a: u64, sub_resource: *u8, rights_mask: u64, out_cap: *u64) -> u32 @export { return CFORGE_SENT } // TODO: body per Algorithm cf_forge_restrict
fn cf_forge_split(cap_a: u64, partition_pred: u32, partition_index: u32, out_cap: *u64) -> u32 @export { return CFORGE_SENT } // TODO: body per Algorithm cf_forge_split

fn cf_add_dependency(derived_slot: u32, source_slot: u32) -> i32 @export { return CFORGE_E_BAD } // TODO: body per Algorithm cf_add_dependency
fn cf_slot_of_cap(cap: u64) -> u32 @export { return CFORGE_SENT } // TODO: body per Algorithm cf_slot_of_cap
fn cf_deforge_cascade(revoked_cap: u64) -> u32 @export { return 0u32 } // TODO: body per Algorithm cf_deforge_cascade

fn cf_forged_cap(slot: u32) -> u64 @export { return 0u64 } // TODO: bounds-check + return CFORGE_CAPID[slot]
fn cf_forged_frag(slot: u32) -> u64 @export { return 0u64 } // TODO: bounds-check + return CFORGE_FRAG[slot]
fn cf_is_live(slot: u32) -> u8 @export { return 0u8 } // TODO: bounds-check + return CFORGE_LIVE[slot]
fn cf_kind(slot: u32) -> u8 @export { return 0u8 } // TODO: bounds-check + return CFORGE_KIND[slot]
fn cf_dependency_count(slot: u32) -> u32 @export { return 0u32 } // TODO: body per Algorithm
fn cf_dependency_at(slot: u32, idx: u32) -> u32 @export { return CFORGE_SENT } // TODO: body per Algorithm
fn cf_count() -> u32 @export { return CFORGE_USED } // TODO: return CFORGE_USED

fn cf_selftest() -> u64 @export { return 0u64 } // TODO: run KAT-1..KAT-4; return 99u64 on all-pass
```
