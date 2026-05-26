# 26 aether/firmware_quarantine.iii — Implementation Spec

## Verdict
**PARTIAL.** The gospel candidate body has correct, complete *region-sheaf logic* (register / intersect / check / forbidden-at / attempt-publish) and the right witness externs, but it is **not buildable as written** and under-realizes the maximal intent. Blocking defects: (1) the entire `FQ_` const/var/`fq_` namespace **link-collides** with `numera/fp384.iii` (which already owns `FQ`, `FQ_P`, `FQ_R2`, `FQ_ONE`, `FQ_T`, `FQ_INIT`, `FQ_PM2`, `fq_dbl_raw`, `fq_csub_p`, `fq_copy`, `fq_add`, `fq_sub`, `fq_mul`, `fq_sqr`, `fq_inv`, and the `fq_*_x` exports — Trap 2 makes every module-scope `const`/`var` a global symbol `L_*`); (2) **local `var payload/in_c/out_c/fid : [u8; N]` inside `fq_attempt_publish`** (Trap 7 — local var arrays don't parse, they must be module-scope); (3) **off-house element-address idiom** `&FQ_PRODUCER[0u64] as *u8` / `&payload[0u64]` (no built aether module uses this; the realized substrate uses `((&ARR as u64)+off) as *u8`); (4) **no capability gate** on `fquar_register` (M8 — registering/altering the forbidden map is a privileged constitutional mutation and must require a rights bit); (5) `fq_init` is called lazily from inside `fq_check_write`/`fq_attempt_publish` — fine for laziness, but it also *re-publishes* nothing and silently registers defaults, which is acceptable, yet the lazy-init pattern uses a `let mut`-style flag the gospel never trips incorrectly here (kept, but hardened below).
Everything else (the anti-bricking sheaf rule, the witness payload encoding, the negative error codes) is sound and is preserved verbatim under the renamed namespace.

## Purpose
`aether::firmware_quarantine` is the **forbidden-region sheaf**: a static map of host physical-address windows whose section value is `FORBIDDEN` (firmware ROM, EFI variable store, management-engine firmware, TPM register window, OTP fuses, locked MMIO). It is the **anti-bricking guarantee** of the substrate (M5): the sheaf condition "any covering open set forbidden ⇒ the region is forbidden" means a write touching *any* byte of *any* forbidden region is refused, and no quarantine commit (Module 25) may apply such a write. Every memory-write path — the firmware-update facility, snapshot-lattice rollback (Module 31), and tissue regenerator (Module 43) — consults it.
**Hexad:** `kind_witness + kind_repair`. **Ring:** R−1 (constitutional). **K:** 1.00.

## Public API
All public fns return a status or a sentinel-typed value (W12). Error codes are negative `i32` (W9); booleans are `u8` 0/1 (W10).

```
fn fquar_init(cap_id: u64) -> i32 @export
fn fquar_register(req: *u8, cap_id: u64) -> u32 @export
fn fquar_check_write(addr: u64, len: u64) -> u8 @export
fn fquar_forbidden_at(addr: u64) -> u8 @export
fn fquar_attempt_publish(addr: u64, len: u64, producer: *u8) -> u64 @export
fn fquar_region_count() -> u32 @export
fn fquar_region_kind_at(addr: u64) -> u8 @export
```

Return conventions:
- `fquar_init(cap_id)` → `FQUAR_OK` / `FQUAR_E_CAP` (cap lacks `amend` right) / `FQUAR_E_FULL` (table overflow during default registration). Idempotent: second call with a valid cap is a no-op returning `FQUAR_OK`.
- `fquar_register(req, cap_id)` → slot index `u32` on success, or `FQUAR_SENT` (`0xFFFFFFFFu32`) on table-full / null-req / cap-denied. `req` is a 4-param aggregate-by-pointer (W2): a packed `[base:u64][len:u64][kind:u8]` descriptor (the gospel's 3 scalar params + the new `cap_id` would be 4, but folding `cap_id` in keeps the privileged path explicit; see Data Structures `FQUAR_REQ`).
- `fquar_check_write(addr,len)` → `1u8` iff `[addr, addr+len)` does **not** intersect any live forbidden region; `0u8` if forbidden (the write must be refused by the caller). Lazy-inits with the env cap if `FQUAR_INITED==0`.
- `fquar_forbidden_at(addr)` → `1u8` iff `addr` lies inside any forbidden region (= `1u8 - fquar_check_write(addr,1)`).
- `fquar_attempt_publish(addr,len,producer)` → witness fragment **index** (`u64`) of the published `FORBIDDEN_WRITE_ATTEMPT` fragment, or `0xFFFFFFFFFFFFFFFFu64` if no region was actually violated (nothing to witness) or the hook is full.
- `fquar_region_count()` → number of live regions (`u32`), for the boot-fold / topology-atlas consumers.
- `fquar_region_kind_at(addr)` → kind byte of the **first** forbidden region containing `addr`, or `0xFFu8` if none (queryable by callers building a refusal message).

## Constant Namespace
**PREFIX = `FQUAR_`** (functions `fquar_*`). The gospel's `FQ_` prefix **must not be used** — it collides with `numera/fp384.iii`. Grep confirmation:
- `grep '^const FQUAR_' STDLIB/` → **no matches** (clear).
- `grep '\bFQUAR_\w+|\bfquar_\w+' STDLIB/` → **no matches** (clear, fns + vars).
- `grep '^const FQ_' STDLIB/` → no `const` matches, **but** `grep '\bFQ_\w+' STDLIB/` → `fp384.iii: var FQ_P/FQ_R2/FQ_ONE/FQ_T/FQ_INIT/FQ_PM2` and `var FQ : [u32; …]`, plus `fn fq_dbl_raw/fq_csub_p/fq_copy/fq_add/fq_sub/fq_mul/fq_sqr/fq_inv/fq_set_u32/fq_set_limb/fq_get_limb/fq_*_x` — **the `FQ_`/`fq_` namespace is taken; renaming to `FQUAR_`/`fquar_` is mandatory.**

Module-level constants:
```
const FQUAR_OK     : i32 =  0i32
const FQUAR_E_FULL : i32 = -1i32
const FQUAR_E_BAD  : i32 = -2i32
const FQUAR_E_CAP  : i32 = -3i32          // capability denied (no amend right)
const FQUAR_SENT   : u32 = 0xFFFFFFFFu32

const FQUAR_KIND_FIRMWARE_ROM : u8 = 0u8
const FQUAR_KIND_EFI_VAR      : u8 = 1u8
const FQUAR_KIND_ME_FIRMWARE  : u8 = 2u8
const FQUAR_KIND_TPM          : u8 = 3u8
const FQUAR_KIND_FUSES        : u8 = 4u8
const FQUAR_KIND_MMIO_LOCKED  : u8 = 5u8
const FQUAR_KIND_NONE         : u8 = 0xFFu8   // "no region" sentinel for kind queries

const FQUAR_MAX_REGIONS : u32 = 256u32        // W8 bound — see Data Structures

// Capability right required to mutate the forbidden map (matches capability.iii bit 14 'amend').
const FQUAR_RIGHT_AMEND : u64 = 0x4000u64
```
Note: `FQUAR_RIGHT_AMEND` mirrors `capability.iii`'s `CAP_RIGHT_AMEND = 0x4000u64` (a private local copy of the public bit value — `capability.iii` does not `@export` its right constants, so the value is duplicated here as a documented spec constant, not re-imported).

## Data Structures
All module-scope, statically sized (W8). No local `var` arrays (Trap 7).

| Name | Type | Bytes (u64-slot model*) | Justification |
|---|---|---|---|
| `FQUAR_LIVE`     | `[u8;  256]`  | 2048 | per-slot occupancy flag; bound = `FQUAR_MAX_REGIONS`. |
| `FQUAR_BASE`     | `[u64; 256]`  | 2048 | region base physical address. |
| `FQUAR_LEN`      | `[u64; 256]`  | 2048 | region length in bytes. |
| `FQUAR_KIND`     | `[u8;  256]`  | 2048 | region kind tag. |
| `FQUAR_PRODUCER` | `[u8; 32]`    | 256  | this module's producer identifier (Keccak256 of `"aether::firmware_quarantine"`). |
| `FQUAR_OPID_ATTEMPT` | `[u8; 32]` | 256 | opid for the FORBIDDEN_WRITE_ATTEMPT fragment. |
| `FQUAR_PAYLOAD`  | `[u8; 32]`    | 256  | **module-scope** scratch for the 25-byte attempt payload (gospel had this as a function-local `var` — Trap 7 fix). |
| `FQUAR_IN_C`     | `[u8; 32]`    | 256  | module-scope in_commit scratch (was function-local). |
| `FQUAR_OUT_C`    | `[u8; 32]`    | 256  | module-scope out_commit scratch (was function-local). |
| `FQUAR_FID`      | `[u8; 32]`    | 256  | module-scope frag-id sink (was function-local). |
| `FQUAR_REQ`      | `[u8; 24]`    | 192  | caller-filled register request: bytes 0..7 base LE, 8..15 len LE, 16 kind (W2 aggregate-by-pointer for `fquar_register`). |
| `FQUAR_INITED`   | `u8 = 0u8`    | 8    | one-shot init flag. |

\* iiis allocates 8 bytes per array element regardless of declared element type (the u64-slot model documented in `witness_hook.iii`); a `[u8; 256]` therefore reserves 2048 bytes. This is harmless here — every array is indexed by element (`FQUAR_BASE[i]`), never by raw byte offset, so the backing width is transparent. The byte buffers (`FQUAR_PAYLOAD` etc.) are 32-element so the live data fits and is addressed via a `*u8` base pointer (`(&ARR as u64) as *u8`).

**`FQUAR_MAX_REGIONS = 256` bound justification (W8):** the forbidden map is a small fixed catalog — firmware ROM window, EFI var store, ME firmware, TPM, fuse bank, and a bounded set of locked MMIO ranges. Real x86_64 platforms expose well under a dozen such windows; the bone-marrow canonical region table (Module 27) and topology atlas (Module 36) add a handful more during Phase 5 hardware probing. 256 is >20× headroom and matches the slot-table size used by `quarantine.iii` / `capability.iii`. The module is **not reentrant** (single module-scope scratch set) — acceptable: the forbidden map is consulted on serialized write paths and mutated only at boot/probe under a capability.

## Dependencies (externs)
All providers are **already built** (no not-yet-built dependency blocks this module's Phase-2 implementation).

```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"          // Module 01 — BUILT
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"                                // Module 01 — BUILT (declared for symmetry; used only if id copying is needed)
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"   // Module 07 — BUILT
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"                                  // Module 07 — BUILT
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"                      // Module 37/cap — BUILT
```

Verified against the realized provider files:
- `identifier.iii`: `ident_from_bytes(input:*u8, in_len:u64, out:*u8) -> i32` and `ident_copy(src:*u8, dst:*u8) -> i32` — **gospel externs correct.**
- `witness_hook.iii`: `wh_publish(...) -> u64` and `wh_chain_root(out_id:*u8) -> i32` exist and are `@export` — **gospel externs correct** (this module is exempt from systemic defect #2: it already routes through `wh_publish`, and `witness_spine.iii`/`ws_emit_fragment` are NOT referenced — good).
- **Systemic defect #4 (algebraic time):** Module 26 needs no time extern. `wh_publish` advances algebraic time internally via `at_advance`. The gospel's `at_now` fiction does not appear here — clean.
- **Systemic defect #5 (capability):** the gospel body has **no** cap check; this spec ADDS the real `cap_verify_rights(id:u64, required:u64) -> u8` (confirmed exported by `capability.iii`) to gate `fquar_init`/`fquar_register`. The right value `0x4000` = `CAP_RIGHT_AMEND` (bit 14), the constitutional-mutation right.
- **No witness_hook accessor gap (systemic defect #6):** this module only *publishes*; it never reads back fragment fields, so it needs none of the not-yet-exported getters.

## Algorithm
NIH (M1): all logic is hand-rolled integer interval arithmetic + the in-tree Keccak256 (via `identifier`/`witness_hook`). No ML/heuristics (M3/M4) — every decision is an exact algebraic interval test. Determinism (M2/W5): outputs are pure functions of the region table and the query; the table is populated deterministically at init; bit-identity holds because the witness payload is a fixed little-endian byte encoding hashed by the deterministic Keccak256. No recursion (W15) — all loops are bounded `while i < FQUAR_MAX_REGIONS` index scans (explicit, no stack needed). No `break` (W14) — scans use a sentinel flag (`safe`, or `found_kind == FQUAR_KIND_NONE`) that gates the loop body; the loop counter always runs to the bound.

**`fquar_init(cap_id)`** — privileged one-shot.
1. If `cap_verify_rights(cap_id, FQUAR_RIGHT_AMEND) != 1u8` → return `FQUAR_E_CAP`. (M8: registering forbidden regions is constitutional.)
2. If `FQUAR_INITED == 1u8` → return `FQUAR_OK` (idempotent).
3. Clear all slots: `i=0; while i<FQUAR_MAX_REGIONS { FQUAR_LIVE[i]=0u8; i=i+1 }`.
4. Compute producer id: `ident_from_bytes("aether::firmware_quarantine", 27, &FQUAR_PRODUCER as *u8)`; opid: `ident_from_bytes("aether::firmware_quarantine::attempt", 36, &FQUAR_OPID_ATTEMPT as *u8)`.
5. Register the universal-minimum default: upper 16 MiB firmware-ROM window. Pack `FQUAR_REQ` = base `0xFFFFFFFFFF000000`, len `0x0000000001000000`, kind `FQUAR_KIND_FIRMWARE_ROM`; call the internal register helper (bypassing the cap re-check since we already verified). If it returns `FQUAR_SENT` → return `FQUAR_E_FULL`.
6. `FQUAR_INITED = 1u8`; return `FQUAR_OK`.
   *(Determinism: the default window is a compile-time constant; the producer/opid ids are Keccak256 of fixed strings. Bone-marrow/boot-fold add platform regions later via `fquar_register` under a cap — those inputs are themselves sealed.)*

**`fquar_register(req, cap_id)`** — privileged map mutation.
1. If `(req as u64) == 0u64` → return `FQUAR_SENT`.
2. If `cap_verify_rights(cap_id, FQUAR_RIGHT_AMEND) != 1u8` → return `FQUAR_SENT` (denied; sentinel because the return type is `u32`).
3. Decode `base` (LE bytes 0..7), `len` (LE bytes 8..15), `kind` (byte 16) from `req` via a `*u8` base pointer.
4. Linear scan for the first free slot `i` with `FQUAR_LIVE[i]==0u8`; write `FQUAR_BASE[i]=base; FQUAR_LEN[i]=len; FQUAR_KIND[i]=kind; FQUAR_LIVE[i]=1u8; return i`.
5. If no free slot → return `FQUAR_SENT`.
   *(M5 reversibility note: registration is purely additive to a static table; it cannot brick. There is intentionally NO `fquar_unregister` — removing a forbidden region is the one operation that could enable bricking, so the map is monotonically growing within a boot epoch. W16: divergences are not applicable; the table is anchored at boot. If a future caller needs region removal it must be a separate capability-gated, witnessed operation — out of scope for the anti-bricking guarantee.)*

**`fquar_intersects(a_base, a_len, b_base, b_len) -> u8`** (internal, ≤4 params W2). Half-open interval overlap test: returns `0u8` if `(a_base + a_len) <= b_base` OR `(b_base + b_len) <= a_base`; else `1u8`. All `u64` ordering compares — **safe** (Trap 3 is signed-int only; these are unsigned). Overflow note: `a_base + a_len` for the top-of-memory window `0xFFFFFFFFFF000000 + 0x1000000 = 0x10000000000000000` wraps to `0u64` in u64 — see Trap Exposure for the exact guard.

**`fquar_check_write(addr, len) -> u8`** — the hot anti-bricking gate.
1. If `FQUAR_INITED == 0u8` → call `fquar_init(CAP_ENV_ROOT=1u64)` lazily (the env cap always has `amend`). This guarantees the default forbidden window exists even if no explicit boot init ran.
2. `safe=1u8; i=0; while i<FQUAR_MAX_REGIONS { if safe==1u8 { if FQUAR_LIVE[i]==1u8 { if fquar_intersects(addr,len,FQUAR_BASE[i],FQUAR_LEN[i])==1u8 { safe=0u8 } } } i=i+1 }`. (Sentinel flag drives the body; loop runs to bound — W14.)
3. Return `safe`.
   *(Sheaf condition: ANY intersecting forbidden region ⇒ unsafe. Determinism: pure scan of a fixed table.)*

**`fquar_forbidden_at(addr) -> u8`** — return `1u8 - fquar_check_write(addr, 1u64)`.

**`fquar_region_kind_at(addr) -> u8`** — scan for first live region with `fquar_intersects(addr,1,base,len)==1`; return its `FQUAR_KIND[i]` (using a `found==0u8` sentinel to capture only the first), else `FQUAR_KIND_NONE`.

**`fquar_region_count() -> u32`** — scan, count slots with `FQUAR_LIVE[i]==1u8`.

**`fquar_attempt_publish(addr, len, producer) -> u64`** — witnessed refusal record (M6/M10).
1. Find the first violated region: `found_kind=FQUAR_KIND_NONE; found_base=0u64; i=0; while i<MAX { if found_kind==FQUAR_KIND_NONE { if FQUAR_LIVE[i]==1u8 { if fquar_intersects(addr,len,FQUAR_BASE[i],FQUAR_LEN[i])==1u8 { found_kind=FQUAR_KIND[i]; found_base=FQUAR_BASE[i] } } } i=i+1 }`.
2. If `found_kind == FQUAR_KIND_NONE` → return `0xFFFFFFFFFFFFFFFFu64` (no violation, nothing to witness).
3. Build the 25-byte payload in `FQUAR_PAYLOAD` via a `*u8` base pointer `pp = (&FQUAR_PAYLOAD as u64) as *u8`: bytes 0..7 = `addr` LE, 8..15 = `len` LE, 16..23 = `found_base` LE, 24 = `found_kind`. (Byte-by-byte `pp[z] = ((v >> (z*8)) & 0xFFu64) as u8` — Trap 5 avoidance, stores through `*u8`.)
4. `in_commit = wh_chain_root(&FQUAR_IN_C ...)`; `out_commit = ident_from_bytes(pp, 25, &FQUAR_OUT_C ...)` (Keccak256 of the payload).
5. `return wh_publish(producer, &FQUAR_OPID_ATTEMPT, &FQUAR_IN_C, &FQUAR_OUT_C, revtag=1u8, phase=0u8, pillar=1u16, antecedents=producer n_ante=0u32, payload=pp, payload_len=25u32, out_frag_id=&FQUAR_FID)`.
   *(M6: the refusal chains by hash to the witness spine. M10: reproducible — given the same `(addr,len,producer)` and region table, the payload bytes and thus the fragment are byte-identical. `revtag=1u8` marks it a reversible/observation-only fragment — recording a refusal changes no host state, consistent with W16/W17 reversibility. The gospel passed `producer` as the antecedents pointer with `n_ante=0`; with `n_ante=0` the antecedents pointer is ignored by `wh_publish`, so this is harmless — preserved.)*

## KAT Vectors (>= 3)
A Phase-2 `fquar_selftest() -> u64` (99 = pass) must check these byte-for-byte. Vectors 1–4 use the env cap (id `1u64`, all rights) for init.

1. **Default firmware-ROM window is forbidden.** After `fquar_init(1u64)`: `fquar_forbidden_at(0xFFFFFFFFFF000000u64) == 1u8`; `fquar_forbidden_at(0xFFFFFFFFFFFFFFFFu64) == 1u8` (last byte of the window); `fquar_check_write(0xFFFFFFFFFF000000u64, 1u64) == 0u8`. The kind: `fquar_region_kind_at(0xFFFFFFFFFF800000u64) == FQUAR_KIND_FIRMWARE_ROM (0u8)`.
2. **An ordinary RAM write is allowed.** `fquar_check_write(0x0000000000100000u64, 0x1000u64) == 1u8` (1 MiB, 4 KiB write — no intersection); `fquar_forbidden_at(0x0000000000100000u64) == 0u8`; `fquar_region_kind_at(0x100000u64) == FQUAR_KIND_NONE (0xFFu8)`.
3. **Register + boundary semantics (half-open).** `fquar_register(req={base=0x1000, len=0x1000, kind=FQUAR_KIND_TPM(3)}, 1u64)` returns slot `1u32` (slot 0 = default ROM). Then: `fquar_check_write(0x0FFFu64, 1u64) == 1u8` (byte just below base — allowed); `fquar_check_write(0x1000u64, 1u64) == 0u8` (first byte — forbidden); `fquar_check_write(0x1FFFu64, 1u64) == 0u8` (last byte — forbidden); `fquar_check_write(0x2000u64, 1u64) == 1u8` (one past end — allowed, half-open); `fquar_region_count() == 2u32`.
4. **Attempt-publish witnesses the violation and is reproducible.** With the TPM region from KAT 3, set a 32-byte `producer` (e.g. bytes `1..32`). `let f0 = fquar_attempt_publish(0x1000u64, 0x10u64, producer)` returns a valid fragment index (`f0 != 0xFFFFFFFFFFFFFFFFu64`). Verify `FQUAR_PAYLOAD[24] == FQUAR_KIND_TPM (3u8)`, `FQUAR_PAYLOAD[0] == 0x00u8` (`addr` low byte), `FQUAR_PAYLOAD[16] == 0x00u8` (`found_base=0x1000` low byte), `FQUAR_PAYLOAD[17] == 0x10u8` (`found_base` byte 1 = 0x10). Publishing the **same** call again yields a new index `f1 = f0 + 1` with a byte-identical `FQUAR_FID` to the first (the fragment id is a pure hash of identical fields except algebraic time — assert the payload bytes are identical run-to-run instead, since `at_time` differs by design; M10 reproducibility is over *recorded inputs*).
5. **Non-violating attempt-publish returns the no-violation sentinel.** `fquar_attempt_publish(0x100000u64, 0x10u64, producer) == 0xFFFFFFFFFFFFFFFFu64` (RAM address, no forbidden region intersected).
6. **Capability gate fails closed.** `fquar_register(req, 0u64) == FQUAR_SENT` (cap id 0 is invalid → `cap_verify_rights` returns 0 → denied). Prove the **negative**: a freshly attenuated cap **without** `amend` (e.g. `cap_attenuate(1, CAP_RIGHT_FS_READ, 0)`) likewise yields `fquar_register(req, that_cap) == FQUAR_SENT`, and the region count is unchanged — i.e. the gate refuses, it does not silently succeed.

## Trap Exposure
- **Trap 1 (multi-line `fn`):** every signature above is single-line — including the long `wh_publish` extern (one physical line). Phase 2 MUST keep them single-line. **Avoidance: enforced in the skeleton.**
- **Trap 2 (const/var = global symbol):** the original blocking defect. **Avoidance: full rename `FQ_`→`FQUAR_`, `fq_`→`fquar_`.** Grep-verified no `FQUAR_`/`fquar_` symbol exists anywhere in `STDLIB/`.
- **Trap 3 (signed-int ordering SIGSEGV):** **not exposed.** Every ordering compare in this module is on `u64`/`u32` (region bases, lengths, loop counters). Error codes are compared with `==`/`!=` only (W11). No `i64`/`i32` `<`/`>`/`<=`/`>=`.
- **Trap 4 (u32-in-u64-slot garbage before pointer math):** loop index `i` is `u32` and is used only for *array element* indexing (`FQUAR_BASE[i]`), never cast `as u64` and fed into raw pointer arithmetic, so the slot-garbage path is not hit. The one place a value becomes a pointer is `(&FQUAR_PAYLOAD as u64) as *u8` — `&ARR` is already a clean 64-bit address. **Avoidance: no `(u32_local as u64)` pointer arithmetic; if any is added, mask `& 0xFFFFFFFFu64`.**
- **Trap 5 (u32 pointer store width):** the payload bytes are written through a `*u8` base pointer one byte at a time (`pp[z] = (...) as u8`), never through a `*u32`/`*u64`. **Avoidance: byte-wise `*u8` stores only.**
- **Trap 6 (nested block comments):** none used. Single `/* ... */` header + `//` inline.
- **Trap 7 (local `var` arrays):** the **second blocking defect** — gospel declared `var payload/in_c/out_c/fid : [u8; N]` *inside* `fquar_attempt_publish`. **Avoidance: all four hoisted to module scope** (`FQUAR_PAYLOAD/FQUAR_IN_C/FQUAR_OUT_C/FQUAR_FID`). Documented non-reentrancy as a consequence.
- **Trap 8 (`} else {` one line):** no `else` clauses needed (all guards are `if ... { return }` early-exits). If Phase 2 introduces one, keep `} else {` on one line.
- **Trap 9 (em-dash in comments):** the skeleton uses ASCII `--` only; **no U+2014.**
- **Trap 10 (`let mut` checkpoint flag):** `fquar_check_write` uses `let mut safe : u8` as a loop sentinel, and `fquar_init` uses `FQUAR_INITED`. These are *loop/state* flags, not the misbehaving early-init-checkpoint pattern; the `safe` flag gates the loop body (the documented W14 idiom, used identically in the built `quarantine.iii`). **Acceptable; preserved.** The lazy-init `if FQUAR_INITED == 0u8 { fquar_init(...) }` is a module-scope `var` test, not a `let mut`.
- **Trap 11 (`a % b` after a call):** **no modulo anywhere** in this module. Not exposed.
- **Trap 12 (`@specialize *T` stride):** module is not generic; no `@specialize`. Not exposed.

**Additional codegen-idiom fix (not one of the 12, but house-style enforced by the realized substrate):** the gospel's element-address form `&FQUAR_PRODUCER[0u64] as *u8` and `&payload[0u64]` is **not used by any built aether module**; the realized idiom (32× in `witness_hook.iii`) is `((&ARR as u64) + offset) as *u8`, and for a base pointer `(&ARR as u64) as *u8`. The skeleton uses the realized form throughout. Bare module-scope indexing `FQUAR_BASE[i]` for read/write is fine (matches `fp384.iii`/`capability.iii`).

## Gap / Fix List
| # | Gap / violation in gospel body | Fix in this spec |
|---|---|---|
| G1 | **`FQ_`/`fq_` namespace link-collides** with `fp384.iii` (`FQ`, `FQ_P`, `FQ_R2`, `FQ_ONE`, `FQ_T`, `FQ_INIT`, `FQ_PM2`, `fq_*`). Trap 2 → multiple-definition linker error. | Rename all consts/vars to `FQUAR_*`, all fns to `fquar_*`. Grep-verified clear. |
| G2 | **Local `var payload/in_c/out_c/fid : [u8;N]` inside `fquar_attempt_publish`** (Trap 7) — does not parse. | Hoist to module scope: `FQUAR_PAYLOAD/FQUAR_IN_C/FQUAR_OUT_C/FQUAR_FID`. Note non-reentrancy. |
| G3 | **No capability gate** on map mutation (M8). Anyone could register/alter forbidden regions, or the map could be initialized by an unprivileged path. | Add `cap_id` param + `cap_verify_rights(cap_id, FQUAR_RIGHT_AMEND)` gate on `fquar_init` and `fquar_register`; new `FQUAR_E_CAP`; lazy-init uses `CAP_ENV_ROOT`. KAT 6 proves it fails closed. |
| G4 | **Off-house element-address idiom** `&ARR[0u64] as *u8` — not codegen-safe per the realized substrate's reconciliation note. | Use `((&ARR as u64)+off) as *u8` / `(&ARR as u64) as *u8` everywhere (matches `witness_hook.iii`). |
| G5 | **`fquar_register` would be a 4-scalar + cap = 5-param fn** if `cap_id` were added naively (W2 ≤4). | Fold `base/len/kind` into a `*u8` aggregate `FQUAR_REQ` (W2-compliant: `req` + `cap_id` = 2 params). |
| G6 | **Missing observability/queries** the gospel prose implies (consulted by boot-fold, topology-atlas, refusal messages) but the body omits. | Add `fquar_region_count()` and `fquar_region_kind_at(addr)` (both pure, W12-returning). |
| G7 | **u64 overflow in `intersects` for the top-of-memory window** (`base+len` wraps to 0). The gospel test `(a_base + a_len) <= b_base` is correct for the *query* side but the *region* side `(b_base + b_len)` wraps for the ROM window, making `(b_base+b_len) <= a_base` spuriously true (`0 <= anything`), which would wrongly mark high writes as **non**-intersecting. | Detect wrap: in `fquar_intersects`, if `(b_base + b_len) < b_base` (overflow), the region extends to the top of the address space — treat the upper bound as `0xFFFFFFFFFFFFFFFF` (i.e. skip the `(b_end <= a_base)` early-out when `b_end` wrapped). Same guard for `a`. Detailed in the skeleton TODO. **This is a latent anti-bricking *hole* in the gospel** (the very firmware-ROM default window it ships would not actually be protected at its top end). Highest-priority correctness fix. |
| — | **Verified correct & preserved:** witness externs (`wh_publish`/`wh_chain_root` exist, exported); no `witness_spine`/`ws_emit_fragment` fiction; no `at_now` fiction (time advanced inside the hook); negative `i32` error codes (W9); `u8` booleans (W10); sentinel-flag loops, no `break`/recursion (W14/W15); ≤4 params (W2); static slot table (W8); the sheaf/interval logic itself. | — |

**Mandate posture:** M1 (NIH, only identifier/witness_hook/capability deps), M2/W5 (deterministic interval test + LE-byte payload), M3/M4 (exact algebra, no learning), **M5 (this module IS the anti-bricking guarantee; G7 closes the one hole)**, M6/M10 (witnessed, reproducible refusal), M8 (G3 cap gate), M9/W16 (refusal recording is reversible/observation-only; map is monotone within an epoch — removal is intentionally absent), M19 (cost bounded: every op is an O(`FQUAR_MAX_REGIONS`) = O(256) scan).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/firmware_quarantine.iii
 *
 * III STDLIB - aether::firmware_quarantine
 *
 * Forbidden region sheaf. Anti-bricking enforcement (M5). Every host
 * physical-address window holding firmware/EFI-var/ME/TPM/fuse/locked-MMIO
 * state carries section value FORBIDDEN; any write intersecting any
 * forbidden region is refused, and no quarantine commit may apply it.
 *
 * Region kinds: FIRMWARE_ROM, EFI_VAR, ME_FIRMWARE, TPM, FUSES, MMIO_LOCKED.
 *
 * Hexad: kind_witness + kind_repair.  Ring: R-1 (constitutional).  K: 1.00.
 * Discipline: W2, W8, W13, W14.  PREFIX FQUAR_ (FQ_ collides with fp384.iii).
 */

module aether_firmware_quarantine

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

const FQUAR_OK     : i32 =  0i32
const FQUAR_E_FULL : i32 = -1i32
const FQUAR_E_BAD  : i32 = -2i32
const FQUAR_E_CAP  : i32 = -3i32
const FQUAR_SENT   : u32 = 0xFFFFFFFFu32

const FQUAR_KIND_FIRMWARE_ROM : u8 = 0u8
const FQUAR_KIND_EFI_VAR      : u8 = 1u8
const FQUAR_KIND_ME_FIRMWARE  : u8 = 2u8
const FQUAR_KIND_TPM          : u8 = 3u8
const FQUAR_KIND_FUSES        : u8 = 4u8
const FQUAR_KIND_MMIO_LOCKED  : u8 = 5u8
const FQUAR_KIND_NONE         : u8 = 0xFFu8

const FQUAR_MAX_REGIONS : u32 = 256u32
const FQUAR_RIGHT_AMEND : u64 = 0x4000u64   // == capability.iii CAP_RIGHT_AMEND (bit 14)

const FQUAR_ENV_CAP : u64 = 1u64            // == capability.iii CAP_ENV_ROOT

var FQUAR_LIVE         : [u8;  256]
var FQUAR_BASE         : [u64; 256]
var FQUAR_LEN          : [u64; 256]
var FQUAR_KIND         : [u8;  256]
var FQUAR_PRODUCER     : [u8; 32]
var FQUAR_OPID_ATTEMPT : [u8; 32]
var FQUAR_PAYLOAD      : [u8; 32]
var FQUAR_IN_C         : [u8; 32]
var FQUAR_OUT_C        : [u8; 32]
var FQUAR_FID          : [u8; 32]
var FQUAR_REQ          : [u8; 24]
var FQUAR_INITED       : u8 = 0u8

// Internal: add a region to the table WITHOUT a cap check (callers gate first).
// Returns slot index or FQUAR_SENT. // TODO: body per Algorithm fquar_register step 3-5.
fn fquar_add(base: u64, len: u64, kind: u8) -> u32 {
    // TODO: linear scan FQUAR_LIVE for first 0u8 slot; fill BASE/LEN/KIND; set LIVE=1u8; return i.
    return FQUAR_SENT
}

// Half-open interval overlap, overflow-safe (G7). // TODO: body per Algorithm fquar_intersects + G7 wrap guard.
fn fquar_intersects(a_base: u64, a_len: u64, b_base: u64, b_len: u64) -> u8 {
    // TODO: compute a_end = a_base + a_len, b_end = b_base + b_len.
    // TODO: a_wrap = (a_end < a_base) ; b_wrap = (b_end < b_base).
    // TODO: if (b_wrap == 0u8) { if b_end <= a_base { return 0u8 } }   // region ends at/below query start
    // TODO: if (a_wrap == 0u8) { if a_end <= b_base { return 0u8 } }   // query ends at/below region start
    // TODO: return 1u8.   // overlap (wrapped intervals reach top-of-memory, so they overlap any high addr)
    return 1u8
}

fn fquar_init(cap_id: u64) -> i32 @export {
    // TODO: if cap_verify_rights(cap_id, FQUAR_RIGHT_AMEND) != 1u8 { return FQUAR_E_CAP }
    // TODO: if FQUAR_INITED == 1u8 { return FQUAR_OK }
    // TODO: clear FQUAR_LIVE[0..FQUAR_MAX_REGIONS).
    // TODO: ident_from_bytes("aether::firmware_quarantine", 27u64, (&FQUAR_PRODUCER as u64) as *u8)
    // TODO: ident_from_bytes("aether::firmware_quarantine::attempt", 36u64, (&FQUAR_OPID_ATTEMPT as u64) as *u8)
    // TODO: if fquar_add(0xFFFFFFFFFF000000u64, 0x0000000001000000u64, FQUAR_KIND_FIRMWARE_ROM) == FQUAR_SENT { return FQUAR_E_FULL }
    // TODO: FQUAR_INITED = 1u8 ; return FQUAR_OK
    return FQUAR_OK
}

fn fquar_register(req: *u8, cap_id: u64) -> u32 @export {
    // TODO: if (req as u64) == 0u64 { return FQUAR_SENT }
    // TODO: if cap_verify_rights(cap_id, FQUAR_RIGHT_AMEND) != 1u8 { return FQUAR_SENT }
    // TODO: decode base (req[0..7] LE), len (req[8..15] LE), kind (req[16]) via *u8 base ptr.
    // TODO: return fquar_add(base, len, kind)
    return FQUAR_SENT
}

fn fquar_check_write(addr: u64, len: u64) -> u8 @export {
    // TODO: if FQUAR_INITED == 0u8 { fquar_init(FQUAR_ENV_CAP) }
    // TODO: safe=1u8 ; i=0u32 ; while i<FQUAR_MAX_REGIONS { if safe==1u8 { if FQUAR_LIVE[i]==1u8 { if fquar_intersects(addr,len,FQUAR_BASE[i],FQUAR_LEN[i])==1u8 { safe=0u8 } } } i=i+1u32 }
    // TODO: return safe
    return 1u8
}

fn fquar_forbidden_at(addr: u64) -> u8 @export {
    // TODO: return 1u8 - fquar_check_write(addr, 1u64)
    return 0u8
}

fn fquar_region_kind_at(addr: u64) -> u8 @export {
    // TODO: found=0u8 ; k=FQUAR_KIND_NONE ; i=0u32 ; scan: if found==0u8 && LIVE[i] && intersects(addr,1,...) { k=FQUAR_KIND[i] ; found=1u8 } ; return k
    return FQUAR_KIND_NONE
}

fn fquar_region_count() -> u32 @export {
    // TODO: n=0u32 ; i=0u32 ; while i<FQUAR_MAX_REGIONS { if FQUAR_LIVE[i]==1u8 { n=n+1u32 } i=i+1u32 } ; return n
    return 0u32
}

fn fquar_attempt_publish(addr: u64, len: u64, producer: *u8) -> u64 @export {
    // TODO: find first violated region -> found_kind (init FQUAR_KIND_NONE), found_base; sentinel-guarded scan.
    // TODO: if found_kind == FQUAR_KIND_NONE { return 0xFFFFFFFFFFFFFFFFu64 }
    // TODO: pp = (&FQUAR_PAYLOAD as u64) as *u8 ; write addr LE [0..7], len LE [8..15], found_base LE [16..23], found_kind [24] byte-wise.
    // TODO: wh_chain_root((&FQUAR_IN_C as u64) as *u8)
    // TODO: ident_from_bytes(pp, 25u64, (&FQUAR_OUT_C as u64) as *u8)
    // TODO: return wh_publish(producer, (&FQUAR_OPID_ATTEMPT as u64) as *u8, (&FQUAR_IN_C as u64) as *u8, (&FQUAR_OUT_C as u64) as *u8, 1u8, 0u8, 1u16, producer, 0u32, pp, 25u32, (&FQUAR_FID as u64) as *u8)
    return 0xFFFFFFFFFFFFFFFFu64
}

// Self-test: 99 = pass. // TODO: implement KAT vectors 1-6 from the spec.
fn fquar_selftest() -> u64 @export {
    // TODO: KAT1 default ROM forbidden ; KAT2 RAM allowed ; KAT3 register+boundary ; KAT4 attempt-publish payload bytes ; KAT5 no-violation sentinel ; KAT6 cap fails closed (negative).
    return 99u64
}
```
