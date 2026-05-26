# 20 STDLIB/iii/numera/quine_verifier.iii — Implementation Spec

## Verdict
PARTIAL — the candidate body expresses the correct algorithm (canonical-order fold of registered module identities into a master Keccak256, compared by equality against the recorded seed) and the four-function public API is shaped right, but it does not compile/run safely as written: it externs the streaming `keccak256_*` from the wrong file (`keccak.iii`, which never exports them), uses three forbidden function-local `var` arrays (Trap 7), uses the `&ARR[expr]` element-address form that iiis does not lower correctly, writes its insertion sort in the exact shape of the documented iiis-1 active-flag clobber trap (W14/Trap 10), calls `ident_cmp` twice per inner iteration (redundant + param-spill exposure), interleaves streaming Keccak with pointer arithmetic without the call-clobber-safe scratch discipline, has multi-line `fn`/extern signatures (Trap 1), and passes a wrong antecedents argument to `wh_publish`. All are mechanical and closed below; no algorithm redesign is required.

## Purpose
`numera::quine_verifier` is the substrate's bootstrap self-verification (W25, Discipline Four). It reconstructs the seed identity from running state — folding every boot-registered module's `(module_id || source_hash)` pair, in canonical lexicographic order of `module_id`, into a single master Keccak-256 digest — and compares that digest **by bit-identical equality only** against the seed identifier recorded in Ring −2. On success it publishes a Quine Verification Witness fragment so the self-proof is itself chained. It IS the fixed-point check that the running system is the system the seed names; it holds no opinion and makes no estimate (M3/M4) — it recomputes and compares.
Hexad kind: `kind_witness`. Ring: R−2 (the recorded seed lives here). K-vector: K = 1.00.

## Public API
All public functions are `@export`, single-line signatures, W12-compliant (every public fn returns a status or a sentinel-typed value):

```
fn qv_init() -> i32 @export
fn qv_register_module(module_id: *u8, source_hash: *u8) -> i32 @export
fn qv_set_target(target: *u8) -> i32 @export
fn qv_seed_target(out_id: *u8) -> i32 @export
fn qv_verify() -> u8 @export
fn qv_verify_publish() -> u64 @export
fn qv_selftest() -> u64 @export
```

Return-status conventions:
- `qv_init`, `qv_register_module`, `qv_set_target`, `qv_seed_target` → `i32`; `QV_OK = 0i32` on success, negative `i32` error (W9). Compared by `== / !=` only (W11).
- `qv_verify` → `u8` boolean (W10): `1u8` = reconstructed digest equals recorded seed; `0u8` = mismatch or precondition unmet (no target set).
- `qv_verify_publish` → `u64` sentinel-typed: returns the published witness fragment index on success, or `0xFFFFFFFFFFFFFFFFu64` on verification failure / witness-area-full (W12 sentinel-typed value). NOTE: the gospel prose says "returns the fragment index, or sentinel on verification failure"; the candidate returns `0xFFFF...` on failure, and fragment index 0 is a legal success — so the failure sentinel MUST be all-ones, never `0u64`. The candidate's `return 0xFFFFFFFFFFFFFFFFu64` is correct; do **not** "simplify" it to `0u64`.
- `qv_reconstruct` (private, no `@export`) → `i32`; internal helper, `QV_OK`/negative.
- `qv_selftest` → `u64`; `99u64` = pass, small positive = failing step (house KAT convention).

## Constant Namespace
PREFIX = `QV_` . Grep of `STDLIB/` (`^const QV_`, `^var QV_`, `QV_OK`, `QV_E_FULL`, `QV_MAX*`) returns **no collision** — the `QV_` prefix is unused elsewhere in the tree; it is safe. (Trap 2: every module-scope `const` emits a linker-global `L_NAME`; these names are unique.)

Module-level constants:
```
const QV_OK          : i32 =  0i32
const QV_E_FULL      : i32 = -1i32
const QV_E_NO_TARGET : i32 = -2i32     // new: explicit code for qv_seed_target with no target set
const QV_E_NULL      : i32 = -3i32     // new: null-pointer guard for register/set/seed
const QV_MAX_MODULES : u32 = 512u32
const QV_ID_BYTES    : u64 = 32u64     // identifier width (mirrors IDENT_BYTES; local copy avoids cross-module const import)
const QV_FAIL_SENT   : u64 = 0xFFFFFFFFFFFFFFFFu64   // verify_publish failure sentinel
```
Rationale for `QV_E_NO_TARGET`/`QV_E_NULL`: the candidate returns a bare `-1i32` from `qv_seed_target` (colliding in meaning with `QV_E_FULL`); distinct named codes keep W9 error codes unambiguous and W11-comparable. `QV_ID_BYTES` and `QV_FAIL_SENT` replace magic literals (`32u64`, `0xFFFF...`) for single-source clarity. The candidate's `const QV_OK`/`QV_E_FULL`/`QV_MAX_MODULES` are kept verbatim.

## Data Structures
All module-scope (Trap 7 — **no** function-local `var` arrays). Sizes justified under W8.

| Name | Type | Bytes | Justification (W8) |
|------|------|-------|--------------------|
| `QV_MOD_LIVE`   | `[u8; 512]`    | 512   | one liveness flag per module slot; bound = `QV_MAX_MODULES`. |
| `QV_MOD_ID`     | `[u8; 16384]`  | 16384 | 512 slots × 32-byte module identifier. |
| `QV_MOD_SRC`    | `[u8; 16384]`  | 16384 | 512 slots × 32-byte source-content hash. |
| `QV_MOD_COUNT`  | `u32` (scalar) | 4     | live module count; ≤ `QV_MAX_MODULES`. |
| `QV_SEED_TARGET`| `[u8; 32]`     | 32    | recorded seed identifier from Ring −2. |
| `QV_TARGET_SET` | `u8` (scalar)  | 1     | 0/1 flag: has the target been set. |
| `QV_PRODUCER`   | `[u8; 32]`     | 32    | this module's producer identifier (for the witness). |
| `QV_OPID`       | `[u8; 32]`     | 32    | the verify operation identifier (for the witness). |
| `QV_INITED`     | `u8` (scalar)  | 1     | 0/1 flag: module initialized. |
| `QV_ORDER`      | `[u32; 512]`   | 2048* | **NEW** — sort permutation index array; replaces the candidate's illegal function-local `var order : [u32; 512]`. Bound = `QV_MAX_MODULES`. (*iiis allocates 8 B per array element regardless of declared elem type — the u64-slot model; 512×8 = 4096 B reserved. Access is by `QV_ORDER[i]` scalar indexing only, never reinterpreted as bytes, so the slot width is transparent.) |
| `QV_RECON_OUT`  | `[u8; 32]`     | 32    | **NEW** — reconstructed master digest sink; replaces the candidate's function-local `var cur : [u8;32]` in `qv_verify`. |
| `QV_WIT_IN`     | `[u8; 32]`     | 32    | **NEW** — witness in-commitment (chain root); replaces function-local `var in_c`. |
| `QV_WIT_OUT`    | `[u8; 32]`     | 32    | **NEW** — witness out-commitment (= seed target); replaces function-local `var out_c`. |
| `QV_WIT_FID`    | `[u8; 32]`     | 32    | **NEW** — published fragment-id sink; replaces function-local `var fid`. |
| `QV_ZERO_ID`    | `[u8; 32]`     | 32    | **NEW** — canonical zero identifier, used as the `antecedents` argument to `wh_publish` (n_ante = 0). Zeroed in `qv_init`. |

Self-test scratch (module-scope, only touched by `qv_selftest`):
| `QV_T_A`,`QV_T_B`,`QV_T_C` | `[u8; 32]` each | 32 | three synthetic module identifiers. |
| `QV_T_HA`,`QV_T_HB`,`QV_T_HC` | `[u8; 32]` each | 32 | their synthetic source hashes. |
| `QV_T_TARGET` | `[u8; 32]` | 32 | expected master digest computed by the test itself. |
| `QV_T_GOT`    | `[u8; 32]` | 32 | digest read back via `qv_seed_target` / compare buffer. |

Non-reentrancy note: like every hashing module in the tree (`sha256.iii`, `keccak256.iii`, `witness_hook.iii`), state is module-singleton. III has no threads in the bit-identical path, so serialized use is safe; flagged here per Trap 7.

## Dependencies (externs)
Each `extern @abi(c-msvc-x64)` is a **single line** (Trap 1). Providing module + NN, and not-yet-built status:

```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out: *u8) -> i32 from "witness_hook.iii"
```

| Extern | Provider | NN | Built? |
|--------|----------|----|--------|
| `ident_from_bytes`, `ident_eq`, `ident_cmp`, `ident_copy` | `numera/identifier.iii` | Module 01 | **BUILT** (present in tree; verified signatures match). |
| `keccak256_init`, `keccak256_update`, `keccak256_final` | `numera/keccak256.iii` | Stage-4 closure module | **BUILT** (present; these symbols live HERE, **not** in `keccak.iii`). |
| `wh_publish`, `wh_chain_root` | `aether/witness_hook.iii` | Module 07 | **BUILT** (present; `wh_publish` is 12-arg, signature verified verbatim). |

**Critical correction (build-breaking):** the gospel candidate writes `... keccak256_init() ... from "keccak.iii"` (and `_update`/`_final` likewise). `keccak.iii` exports **only** the low-level sponge primitives (`keccak_state_zero`, `keccak_f1600`, `keccak_absorb`, `keccak_squeeze`, `keccak_pack_rate_dom`) — it has **no** `keccak256_init/update/final`. The streaming wrapper is in `keccak256.iii`. `witness_hook.iii` (the canonical consumer) externs them from `"keccak256.iii"`. The spec's externs above are corrected accordingly. **No new not-yet-built dependencies** are introduced; all three providers already exist.

## Algorithm

Determinism (M2) and bit-identity (W5) hold because: (a) inputs are fixed 32-byte byte arrays compared/hashed as raw bytes — no floats, no platform widths; (b) the fold order is a total order (lexicographic byte order of `module_id` via `ident_cmp`, with the live-count `QV_MOD_COUNT` as the exact element set); (c) Keccak-256 is a fixed permutation; (d) comparison is byte-equality only (M3/M4 — no thresholds, no "close enough", M16 anchored by exact digest). NIH (M1): the only algorithms are insertion sort (hand-rolled here) and Keccak-256 (hand-rolled in `keccak256.iii`); no third-party code. No recursion anywhere (W15) — the sort uses an explicit index-permutation array `QV_ORDER`, not recursive partitioning.

### `qv_init() -> i32`
Zero `QV_MOD_LIVE[0..QV_MAX_MODULES)`, set `QV_MOD_COUNT = 0`, `QV_TARGET_SET = 0`. Zero `QV_ZERO_ID[0..32)`. Derive the producer identifier `QV_PRODUCER = ident_from_bytes("numera::quine_verifier", 22)` and the op identifier `QV_OPID = ident_from_bytes("numera::quine_verifier::verify", 30)`. Set `QV_INITED = 1`. Return `QV_OK`.
- **Element-address fix:** the candidate writes `&QV_PRODUCER[0u64] as *u8`; iiis lowers element-address-of inconsistently, so use the house idiom `(&QV_PRODUCER as u64) as *u8` (per `witness_hook.iii`/`identifier.iii`). Same for `QV_OPID`.
- The two ASCII literal lengths (22, 30) are byte counts of `"numera::quine_verifier"` and `"numera::quine_verifier::verify"` respectively; keep them as the literal `u64`s — do not compute a strlen (no libc string call in the bit-identical path).

### `qv_register_module(module_id: *u8, source_hash: *u8) -> i32`
Guard `QV_INITED == 1` implicitly (caller contract); guard nulls: `if (module_id as u64) == 0u64 return QV_E_NULL`, same for `source_hash` (W-robustness; candidate omitted these). Guard capacity: `if QV_MOD_COUNT >= QV_MAX_MODULES return QV_E_FULL`. Let `idx = QV_MOD_COUNT`. Compute the byte offset once into a local `u64`: `off = (idx as u64) & 0xFFFFFFFFu64) * QV_ID_BYTES` — the mask is **Trap 4** avoidance (u32→u64 slot may carry high-bit garbage before pointer math). Copy 32 bytes of `module_id` into `QV_MOD_ID` at `off`, and 32 bytes of `source_hash` into `QV_MOD_SRC` at `off`, via byte loop with `((&QV_MOD_ID as u64)+off)[k]` addressing. Set `QV_MOD_LIVE[idx] = 1`, `QV_MOD_COUNT = idx + 1`. Return `QV_OK`.

### `qv_set_target(target: *u8) -> i32`
Guard `if (target as u64) == 0u64 return QV_E_NULL`. `ident_copy(target, (&QV_SEED_TARGET as u64) as *u8)`. Set `QV_TARGET_SET = 1`. Return `QV_OK`. (Element-address fix vs candidate's `&QV_SEED_TARGET[0u64]`.)

### `qv_seed_target(out_id: *u8) -> i32`
Guard `if (out_id as u64) == 0u64 return QV_E_NULL`. `if QV_TARGET_SET == 0u8 return QV_E_NO_TARGET` (named code vs candidate's bare `-1i32`). `ident_copy((&QV_SEED_TARGET as u64) as *u8, out_id)`. Return `QV_OK`.

### `qv_reconstruct(out: *u8) -> i32` (private)
Hand-rolled **insertion sort** over the index-permutation array `QV_ORDER`, then a streaming Keccak-256 fold. Explicit-stack/iterative (W15 — no recursion).

1. Initialize permutation: `i=0; while i < QV_MOD_COUNT { QV_ORDER[i] = i; i = i + 1 }`.
2. Insertion sort by `module_id` ascending. **This is the load-bearing fix.** The candidate's inner loop is the documented iiis-1 *active-flag clobber* trap: it drives `while q > 0u32` and then sets `q = 0u32` inside an `if` to terminate, which clobbers the insertion index and corrupts the order. The correct form drives the **while condition itself with the active flag** and decrements `q` only on a real swap. Concrete shape (W14 sentinel/flag; **no `break`**; ident_cmp called **once** per iteration into a local — avoids the double-call redundancy and the modulo-after-call-family param-spill exposure):
   ```
   let mut p : u32 = 1u32
   while p < QV_MOD_COUNT {
       let mut q : u32 = p
       let mut active : u8 = 1u8
       while active == 1u8 {
           if q == 0u32 { active = 0u8 } else {
               let lhs_idx : u32 = QV_ORDER[q - 1u32]
               let rhs_idx : u32 = QV_ORDER[q]
               let loff : u64 = ((lhs_idx as u64) & 0xFFFFFFFFu64) * QV_ID_BYTES
               let roff : u64 = ((rhs_idx as u64) & 0xFFFFFFFFu64) * QV_ID_BYTES
               let lp : *u8 = ((&QV_MOD_ID as u64) + loff) as *u8
               let rp : *u8 = ((&QV_MOD_ID as u64) + roff) as *u8
               let c : i32 = ident_cmp(lp, rp)
               if c == 1i32 {
                   let tmp : u32 = QV_ORDER[q - 1u32]
                   QV_ORDER[q - 1u32] = QV_ORDER[q]
                   QV_ORDER[q] = tmp
                   q = q - 1u32
               } else { active = 0u8 }
           }
       }
       p = p + 1u32
   }
   ```
   - `ident_cmp` returns `-1/0/1` (verified in `identifier.iii`): `1i32` ⇔ `lhs > rhs`, so swapping on `c == 1i32` yields **ascending** byte order. Equal ids (`c == 0`) do not swap — the sort is stable for the dedup-free registration set, and equal `module_id`s would in any case fold identical bytes. Compare by `== / != 1i32` only (W11 — no `< 0` / `>` on the i32 result; **Trap 3** avoidance). The candidate's `== 1i32` test was already W11-correct; the bug was solely the termination flag.
   - `loff`/`roff` masking is **Trap 4** avoidance (the `*32` pointer math on a u32-derived index).
3. Streaming fold: `keccak256_init()`. Then `k=0; while k < QV_MOD_COUNT { idx = QV_ORDER[k]; off = ((idx as u64)&0xFFFFFFFFu64)*QV_ID_BYTES; keccak256_update(((&QV_MOD_ID as u64)+off) as *u8, 32u64); keccak256_update(((&QV_MOD_SRC as u64)+off) as *u8, 32u64); k = k + 1 }`. Then `keccak256_final(out)`.
   - **Param-spill discipline (Trap 11 family / param-spill):** `keccak256_update`'s pointer/len arguments are computed into named locals (`off`, then the cast pointer) before the call, and each `keccak256_update` argument is a single local expression. This mirrors `witness_hook.iii::wh_epoch_close`, which successfully interleaves `keccak256_update` with `((&WH_FRAG_ID as u64)+i*32u64)` indexing inside a loop — proving the streaming API is robust when arguments are local-materialized. (If a future iiis regression shows update-call clobber, the fallback is the `identifier.iii` reconciliation: concatenate all `(id||src)` pairs into a module-scope `QV_FOLDBUF : [u8; 32768]` and call `keccak256_oneshot` once. The streaming form is preferred to avoid a second 32 KiB buffer; both are bit-identical.)
4. Return `QV_OK`.

### `qv_verify() -> u8`
`if QV_TARGET_SET == 0u8 return 0u8`. `qv_reconstruct((&QV_RECON_OUT as u64) as *u8)`. Return `ident_eq((&QV_RECON_OUT as u64) as *u8, (&QV_SEED_TARGET as u64) as *u8)` — `ident_eq` is the constant-time 32-byte equality (M3/M4: pure byte-equality, no tolerance). (Trap 7 fix: `QV_RECON_OUT` is module-scope, replacing the candidate's `var cur`.)

### `qv_verify_publish() -> u64`
`if qv_verify() == 0u8 return QV_FAIL_SENT`. Build the witness commitments in module-scope buffers (Trap 7 fix): `wh_chain_root((&QV_WIT_IN as u64) as *u8)` (in-commit = current chain root), `ident_copy((&QV_SEED_TARGET as u64) as *u8, (&QV_WIT_OUT as u64) as *u8)` (out-commit = verified seed identity). Publish a witness fragment whose **payload is the 32-byte verified seed identity** (`QV_WIT_OUT`), with `n_ante = 0` and the antecedents pointer = `QV_ZERO_ID` (canonical zero id), `revtag = 0`, `phase = 0`, `pillar = 5u16` (Layer 5). Single-line call:
```
return wh_publish((&QV_PRODUCER as u64) as *u8, (&QV_OPID as u64) as *u8, (&QV_WIT_IN as u64) as *u8, (&QV_WIT_OUT as u64) as *u8, 0u8, 0u8, 5u16, (&QV_ZERO_ID as u64) as *u8, 0u32, (&QV_WIT_OUT as u64) as *u8, 32u32, (&QV_WIT_FID as u64) as *u8)
```
- **wh_publish argument fix:** the candidate passed `payload` (its local) as **both** the `antecedents` (position 8) and `payload` (position 10) arguments while also passing `0u32` for `payload_len` (position 11) on the antecedents side — i.e. it set `payload_len = 0u32` then `32u32`, conflating the two. The correct mapping (verified against `witness_hook.iii::wh_publish` 12-arg signature and the `wh_append_resolution` exemplar): antecedents = `QV_ZERO_ID` with `n_ante = 0u32`; payload = `QV_WIT_OUT` with `payload_len = 32u32`. M6/M10: the published fragment chains by hash and is byte-recomputable from `(producer, opid, in_commit, out_commit, ..., payload)` — all recorded.
- W16/W17: the fragment is produced under the append-only witness chain; `wh_publish` advances algebraic time monotonically. No reversibility violation — publishing a proof fragment is additive.

### `qv_selftest() -> u64`
Self-contained KAT (99 = pass). See KAT Vectors. Uses only module-scope `QV_T_*` scratch.

## KAT Vectors (>= 3)
The master digest is `Keccak256` over the concatenation, in ascending-`module_id` order, of each `(module_id[32] || source_hash[32])`. The self-test computes the expected target by an **independent path** (direct `keccak256_*` over a hand-built buffer in known order), sets it as the target, and checks `qv_verify` reproduces it — so the gate is byte-exact, not tautological.

1. **Empty system (zero modules).** `qv_init()`; register nothing; set target = `Keccak256("")` = `c5d24601...85a470` (the canonical empty-sponge digest, verified in `keccak256.iii::keccak256_kat`); `qv_verify()` must return `1u8` (the fold of zero pairs is `Keccak256("")`). Then corrupt target byte 0 and assert `qv_verify() == 0u8`. → checks the empty-fold base case and that mismatch is detected.

2. **Canonical-order independence (3 modules registered out of order).** Build three identifiers with a **known** byte ordering: `A = 0x00 0x00...`, `B = 0x11 0x00...`, `C = 0x22 0x00...` (so lexicographic order is A < B < C), with source hashes `HA/HB/HC = 0xAA.. / 0xBB.. / 0xCC..`. Register them in the scrambled order **C, A, B**. Independently compute `expected = Keccak256(A||HA || B||HB || C||HC)` (ascending) via direct `keccak256_init/update*/final` into `QV_T_TARGET`. `qv_set_target(QV_T_TARGET)`; assert `qv_verify() == 1u8`. → checks the insertion sort produces canonical order regardless of registration order (the load-bearing fix), and the fold matches.

3. **Order-sensitivity (negative).** Same three modules, but set the target to `Keccak256(C||HC || B||HB || A||HA)` (descending). Assert `qv_verify() == 0u8` — the reconstruction sorts ascending, so a descending target must NOT match. → proves the verifier is genuinely order-fixing, not order-agnostic.

4. **Witness publication round-trip.** With the case-2 modules and matching target, `qv_verify_publish()` must return a fragment index `!= QV_FAIL_SENT` (i.e. not all-ones); `qv_seed_target(QV_T_GOT)` then equals `QV_T_TARGET` byte-for-byte. With a corrupted target, `qv_verify_publish()` must return `QV_FAIL_SENT`. → checks publish-on-success / sentinel-on-failure and that the payload (seed identity) is the verified target.

`qv_selftest` returns `99u64` only if all four pass; otherwise a small positive step code (1..N) identifying the first failing assertion.

## Trap Exposure
| # | Trap | Exposed? | Avoidance in this module |
|---|------|----------|--------------------------|
| 1 | Multi-line `fn`/extern decl | YES (candidate violates) | Every `fn` signature and every `extern` is on ONE line — including the 12-arg `wh_publish` extern and its call site (candidate wrapped both). |
| 2 | Module-`const` linker-global | YES | All consts prefixed `QV_`; grep confirms no `QV_*` collision in `STDLIB/`. |
| 3 | Signed-int ordering compare SIGSEGV | YES | `ident_cmp` result compared by `== 1i32` / `else` only — never `< 0` / `>`. All `i32` status checks use `== / !=`. |
| 4 | u32-in-u64-slot pointer-math garbage | YES | Every index→offset (`idx * 32`) masks first: `((idx as u64) & 0xFFFFFFFFu64) * QV_ID_BYTES`, in `register`, `reconstruct` sort, and `reconstruct` fold. |
| 5 | u32 pointer-store width | NO | No `*u32` stores of u32-locals; `QV_ORDER[i] = u32` is a typed array element store (8-byte slot, scalar — not byte-reinterpreted), and all byte copies go through `*u8`. |
| 6 | Nested `/* */` comments | Avoid | No nested block comments; inline notes use `//`. |
| 7 | Local `var` arrays | YES (candidate violates ×5) | `QV_ORDER`, `QV_RECON_OUT`, `QV_WIT_IN`, `QV_WIT_OUT`, `QV_WIT_FID` (and `QV_ZERO_ID`, `QV_T_*`) are ALL module-scope. Non-reentrancy noted (serialized; no threads in the bit-identical path). |
| 8 | `} else {` not one line | Avoid | All `} else {` written on one line (the sort and guards). |
| 9 | Em-dash in comment | Avoid | ASCII `--` only in comments. |
| 10 | `let mut flag` checkpoint misbehavior | YES (candidate's sort) | The sort's `active` flag **drives the `while` condition itself** (`while active == 1u8`), decrementing `q` only on a real swap — the documented iiis-1 insertion-sort fix. No `q = 0u32` short-circuit inside an `if`. |
| 11 | `a % b` / stale-divisor after call (param-spill) | YES | No modulo anywhere. `keccak256_update` arguments are local-materialized before each call (offset → local → cast pointer); `ident_cmp` is called **once** per inner-loop iteration into local `c` (candidate called it twice). Mirrors `witness_hook.iii` interleave pattern. |
| 12 | `@specialize *T` 8-byte stride | NO | Module is not generic; no `@specialize`. |

## Gap / Fix List
The candidate is PARTIAL. Every gap and the fix:

1. **[BUILD-BREAKING] Wrong extern source for streaming Keccak.** Candidate: `keccak256_init/update/final ... from "keccak.iii"`. `keccak.iii` exports only the low-level sponge primitives; the streaming wrapper lives in `keccak256.iii`. **Fix:** extern all three `from "keccak256.iii"` (as `witness_hook.iii` does).
2. **[Trap 7] Five function-local `var` arrays.** `var order : [u32;512]` (qv_reconstruct), `var cur : [u8;32]` (qv_verify), `var in_c/out_c/fid : [u8;32]` (qv_verify_publish) — iiis parses `var` arrays only at module scope. **Fix:** promote to module-scope `QV_ORDER`, `QV_RECON_OUT`, `QV_WIT_IN`, `QV_WIT_OUT`, `QV_WIT_FID`.
3. **[Trap 10 / W14 / MEMORY: iiis-1 insertion-sort active-flag trap] Sort termination clobbers the index.** Candidate inner loop `while q > 0u32 { ... if ident_cmp != 1 { q = 0u32 } }` sets the insertion index to 0 to terminate, corrupting the order. **Fix:** drive the loop with a dedicated `active` flag in the `while` condition; decrement `q` only on a true swap; set `active = 0` on no-swap-or-q==0. (Algorithm §qv_reconstruct.)
4. **[Trap 11 family] `ident_cmp` called twice per iteration.** Candidate evaluates `ident_cmp(lp, rp)` in two separate `if` statements. Redundant work AND exposes the second call to the param-spill / stale-result family. **Fix:** call once into a local `let c : i32`.
5. **[Element-address idiom] `&ARR[expr] as *u8` throughout.** Candidate uses `&QV_PRODUCER[0u64]`, `&QV_SEED_TARGET[0u64]`, `&QV_MOD_ID[(idx as u64)*32u64]`, `&cur[0u64]`, etc. iiis does not reliably lower element-address-of. **Fix:** use `((&ARR as u64) + off) as *u8` (the documented `witness_hook.iii`/`identifier.iii` reconciliation). For base address use `(&ARR as u64) as *u8`.
6. **[Trap 4] Unmasked u32→u64 in pointer math.** Candidate `(idx as u64) * 32u64`, `(lhs_idx as u64) * 32u64`, etc., with `idx`/`lhs_idx`/`rhs_idx` being `u32`. **Fix:** mask `((x as u64) & 0xFFFFFFFFu64) * QV_ID_BYTES` before every such multiply.
7. **[Trap 1] Multi-line signatures.** The `wh_publish` extern (candidate spans 5 lines) and its call site (candidate spans 2 lines). **Fix:** single-line both.
8. **[wh_publish argument bug] Wrong antecedents/payload mapping.** Candidate passes its `payload` local (= out-commit pointer) as the `antecedents` argument with `n_ante = 0u32` AND passes `0u32` then `32u32` so the payload-length wiring is muddled; it also uses the out-commit as payload. **Fix:** antecedents = `QV_ZERO_ID`, `n_ante = 0u32`; payload = `QV_WIT_OUT` (the verified seed identity), `payload_len = 32u32`. (Matches the `wh_append_resolution` exemplar.)
9. **[Robustness / W9] Missing null guards & ambiguous error code.** `qv_register_module`/`qv_set_target`/`qv_seed_target` accept pointers without null checks; `qv_seed_target` returns a bare `-1i32` overlapping `QV_E_FULL`'s meaning. **Fix:** add `QV_E_NULL` guards and a distinct `QV_E_NO_TARGET = -2i32`.
10. **[Missing acceptance gate] No self-test.** The candidate ships no KAT. Every built numera module (`sha256`, `keccak256`, `identifier`, `witness_hook`) exports a `*_selftest`/`*_kat` returning `99`. **Fix:** add `qv_selftest()` per KAT Vectors — the Phase-2 acceptance gate.
11. **[Mandate review — no violations of intent, all PASS]:** M1 NIH (only identifier/keccak256/witness_hook externs; insertion sort hand-rolled) ✔; M2/M3/M4 (deterministic fold + byte-equality, no ML/heuristics/thresholds) ✔; M5 (verify is read-only; publish is additive append — no bricking) ✔; M6/M10 (witness fragment chains by hash, byte-recomputable) ✔; M7 (Ring −2 honored — the recorded seed lives there; verifier consumes it) ✔; M8 (capability: see note) ; M11/M12 (the published Quine Verification Witness IS the checkable certificate that the running system equals the seed — Curry-Howard self-proof) ✔; M13/M20 (reflection bounded — it folds *identifiers* exposed by the seed sheaf, never module source, never itself recursively; the self-reference is a single fixed-point equality, not unbounded introspection) ✔; M16 (divergence anchored by exact master digest) ✔; W5/W15/W14/W2/W13 ✔ (max params = `wh_publish`'s 12, but that is the documented gospel multi-field hook — this module's own fns are ≤2 params; W13 locals well under 20 per fn).
    - **M8 note (capability-mediation):** the gospel API for the verify/publish path is capability-free (it reads module-scope registered state and the recorded target). This matches the bootstrap self-verification role (W25/Discipline Four) where the verifier is invoked once by the boot path that already holds authority; there is no privileged mutation to gate. Flagged as an intentional, role-justified exception, not an oversight — no fix required, but noted so the wave scheduler/auditor sees it was considered.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures. No fn bodies (Phase 2 writes those per Algorithm §).

```iii
/* III/STDLIB/iii/numera/quine_verifier.iii -- Layer 5, Module 20 (gospel).
 *
 * Bootstrap self-verification (W25, Discipline Four).  Reconstruct the seed
 * identity from running state -- fold every boot-registered module's
 * (module_id || source_hash), in canonical ascending module_id order, into a
 * master Keccak-256 -- and compare by bit-identical EQUALITY against the seed
 * identifier recorded in Ring -2.  On success, publish a Quine Verification
 * Witness fragment.
 *
 * Hexad: kind_witness.  Ring: R-2.  K: 1.00.
 * NIH: depends only on identifier.iii, keccak256.iii, witness_hook.iii.
 * Reconciliations vs gospel candidate: streaming keccak externed from
 * keccak256.iii (NOT keccak.iii); function-local var arrays -> module scope;
 * &ARR[expr] -> ((&ARR as u64)+off) as *u8; insertion-sort active-flag fix;
 * single-call ident_cmp; masked u32->u64 pointer math; wh_publish arg fix.
 */
module numera_quine_verifier

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out: *u8) -> i32 from "witness_hook.iii"

const QV_OK          : i32 =  0i32
const QV_E_FULL      : i32 = -1i32
const QV_E_NO_TARGET : i32 = -2i32
const QV_E_NULL      : i32 = -3i32
const QV_MAX_MODULES : u32 = 512u32
const QV_ID_BYTES    : u64 = 32u64
const QV_FAIL_SENT   : u64 = 0xFFFFFFFFFFFFFFFFu64

var QV_MOD_LIVE    : [u8;  512]
var QV_MOD_ID      : [u8;  16384]
var QV_MOD_SRC     : [u8;  16384]
var QV_MOD_COUNT   : u32 = 0u32

var QV_SEED_TARGET : [u8; 32]
var QV_TARGET_SET  : u8  = 0u8

var QV_PRODUCER    : [u8; 32]
var QV_OPID        : [u8; 32]
var QV_INITED      : u8  = 0u8

var QV_ORDER       : [u32; 512]     // sort permutation (Trap 7: was function-local)
var QV_RECON_OUT   : [u8; 32]       // reconstructed master digest sink
var QV_WIT_IN      : [u8; 32]       // witness in-commit (chain root)
var QV_WIT_OUT     : [u8; 32]       // witness out-commit (= seed target)
var QV_WIT_FID     : [u8; 32]       // published fragment-id sink
var QV_ZERO_ID     : [u8; 32]       // canonical zero id (antecedents, n_ante=0)

var QV_T_A   : [u8; 32]
var QV_T_B   : [u8; 32]
var QV_T_C   : [u8; 32]
var QV_T_HA  : [u8; 32]
var QV_T_HB  : [u8; 32]
var QV_T_HC  : [u8; 32]
var QV_T_TARGET : [u8; 32]
var QV_T_GOT    : [u8; 32]

fn qv_init() -> i32 @export { /* TODO: body per Algorithm: zero LIVE, COUNT=0, TARGET_SET=0, zero ZERO_ID, derive PRODUCER/OPID via ident_from_bytes, INITED=1 */ }

fn qv_register_module(module_id: *u8, source_hash: *u8) -> i32 @export { /* TODO: null guards -> QV_E_NULL; capacity -> QV_E_FULL; off=((idx as u64)&0xFFFFFFFFu64)*QV_ID_BYTES; byte-copy 32 into MOD_ID/MOD_SRC; LIVE[idx]=1; COUNT=idx+1 */ }

fn qv_set_target(target: *u8) -> i32 @export { /* TODO: null guard; ident_copy(target,(&QV_SEED_TARGET as u64) as *u8); TARGET_SET=1 */ }

fn qv_seed_target(out_id: *u8) -> i32 @export { /* TODO: null guard; if !TARGET_SET -> QV_E_NO_TARGET; ident_copy(SEED_TARGET, out_id) */ }

fn qv_reconstruct(out: *u8) -> i32 { /* TODO: init QV_ORDER; insertion sort by module_id ascending (active-flag in while-cond, single ident_cmp into local c, swap on c==1i32, masked offsets); keccak256_init; fold update(MOD_ID@off,32)+update(MOD_SRC@off,32) in QV_ORDER sequence; keccak256_final(out) */ }

fn qv_verify() -> u8 @export { /* TODO: if !TARGET_SET -> 0u8; qv_reconstruct((&QV_RECON_OUT as u64) as *u8); return ident_eq(RECON_OUT, SEED_TARGET) */ }

fn qv_verify_publish() -> u64 @export { /* TODO: if qv_verify()==0u8 -> QV_FAIL_SENT; wh_chain_root(WIT_IN); ident_copy(SEED_TARGET,WIT_OUT); single-line wh_publish(PRODUCER,OPID,WIT_IN,WIT_OUT,0u8,0u8,5u16,ZERO_ID,0u32,WIT_OUT,32u32,WIT_FID) */ }

fn qv_selftest() -> u64 @export { /* TODO: KAT 1 empty-fold==Keccak256("") ; KAT 2 scrambled-register A<B<C ascending fold match ; KAT 3 descending target mismatch ; KAT 4 verify_publish index!=QV_FAIL_SENT + seed_target round-trip ; return 99u64 on all-pass else step code */ }
```
