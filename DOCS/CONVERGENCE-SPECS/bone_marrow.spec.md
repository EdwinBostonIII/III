# 27 aether/bone_marrow.iii — Implementation Spec

## Verdict
**PARTIAL.** The gospel candidate body is a complete, correct Reed-Solomon erasure archive over GF(2^8) (write/encode/verify/scrub/recover/read), but it is incomplete against the module's *defining* mandate and contains hard defects. Missing: the **W30 bone-marrow seal** (compute + verify-at-boot of the corpus root that is "the substrate's deepest persistent identity") — the gospel body has NO seal function at all. Defects: (D1) every GF extern is doubly-wrong (`gf256_mul/inv/pow(u8)->u8` do not exist — the real `numera/galois.iii` exports `gf8_mul/gf8_pow/gf8_inv(u32)->u32`); (D2) seven function-local `var` arrays violate Trap 7; (D3) zero witness emission (M6/W16 violation — a seed archive that mutates persistent state with no provenance); (D4) zero capability mediation (M8 violation — `bm_write_data`/`bm_recover` rewrite the substrate's deepest store unguarded); (D5) `galois.iii` is itself not-yet-built. The core RS algorithm is sound and its consumer-facing signatures must be preserved byte-identically.

## Purpose
`aether/bone_marrow.iii` is the substrate's **replicated seed archive** — the persistent corpus from which every III module's source is reconstructed, protected by Reed-Solomon erasure coding over GF(2^8) (k=8 data + r=4 parity per stripe) and crowned by the **W30 seal**: a Keccak256 corpus root recomputed and verified at every boot *before any other module loads*. It IS the deepest persistent identity of the system; a seal mismatch halts boot. Hexad: `kind_witness + kind_repair`. Ring: **R-2** (the Sanctum — established at boot, not subsequently rewritten). K-vector: **1.00**.

## Public API
Core archive (signatures PRESERVED byte-identically from the gospel — `bm_recover` and `bm_verify_block` are externed by `aether/tissue_regen.iii`; the Phase-One boot stub calls `bm_scrub`/`bm_recover`/`bm_record_hash`):

```
fn bm_init() -> i32 @export
fn bm_write_data(stripe_id: u32, idx: u32, data: *u8) -> i32 @export
fn bm_encode_stripe(stripe_id: u32) -> i32 @export
fn bm_verify_block(stripe_id: u32, idx: u32) -> u8 @export
fn bm_scrub(stripe_id: u32) -> u32 @export
fn bm_recover(stripe_id: u32, lost_mask: u64) -> i32 @export
fn bm_read_data(stripe_id: u32, idx: u32, out: *u8) -> i32 @export
```

W30 seal — the maximal-intent additions (NEW, non-breaking):

```
fn bm_seal_compute(out_root: *u8) -> i32 @export
fn bm_seal_set(cap_id: u64) -> i32 @export
fn bm_verify_seal() -> u8 @export
fn bm_seal_root(out_root: *u8) -> i32 @export
```

Capability + witness wiring (NEW, non-breaking — see Algorithm for why this preserves the core sigs):

```
fn bm_init_cap(cap_id: u64) -> i32 @export
```

Return-status convention: every status-returning fn yields `i32` with `BM_OK = 0` and negative error codes (W9: errors are negative `i32`, compared by `==`/`!=` only per W11). Predicate returns are `u8` 0/1 (W10): `bm_verify_block`, `bm_verify_seal`. `bm_scrub` returns a `u32` count (a sentinel-typed value, W12). `bm_recover`/`bm_encode_stripe`/`bm_write_data`/`bm_read_data`/`bm_init`/`bm_init_cap`/`bm_seal_compute`/`bm_seal_set`/`bm_seal_root` return `i32` status (W12).

## Constant Namespace
**PREFIX = `MARROW_`** (confirmed assigned in `DOCS/CONVERGENCE-BUILD-LEDGER.md` line 65, status pending; `grep -rn "MARROW_" STDLIB` → **0 hits**, no collision). NOTE: the gospel body uses a `BM_` prefix on its constants and `bm_` on functions. The *function* names `bm_*` are the C-ABI symbols externed by consumers and are KEPT verbatim. The *constants* are renamed `BM_*` → `MARROW_*` to obey Trap 2 (every module-level `const` emits a linker-global `L_NAME`; `BM_OK`/`BM_K`/`BM_N` etc. would collide with any other module's short constants). Constant→symbol rename is invisible to consumers (they extern functions, not constants).

| const | type | value | note |
|---|---|---|---|
| `MARROW_OK`         | i32 | `0i32`  | |
| `MARROW_E_BAD`      | i32 | `-1i32` | bad argument / block not live |
| `MARROW_E_TOO_BAD`  | i32 | `-2i32` | > r blocks lost, unrecoverable |
| `MARROW_E_SINGULAR` | i32 | `-3i32` | survivor submatrix not invertible |
| `MARROW_E_DENIED`   | i32 | `-4i32` | capability check failed (NEW) |
| `MARROW_E_NOSEAL`   | i32 | `-5i32` | seal not yet recorded (NEW) |
| `MARROW_BLOCK_SZ`   | u32 | `4096u32` | 4 KiB data/parity block |
| `MARROW_K`          | u32 | `8u32`  | data blocks per stripe |
| `MARROW_R`          | u32 | `4u32`  | parity blocks per stripe |
| `MARROW_N`          | u32 | `12u32` | `MARROW_K + MARROW_R` |
| `MARROW_MAX_STRIPE` | u32 | `256u32` | stripe table bound (W8) |
| `MARROW_ALPHA`      | u32 | `2u32`  | primitive element of GF(2^8); **u32** to match `gf8_*` ABI |
| `MARROW_HASH_SZ`    | u64 | `32u64` | Keccak256 digest width |

## Data Structures
All module-scope (W8 statically sized; W6/W7 module-arena lifecycle; Trap 7 forbids function-local `var` arrays). **Defect D2 fix:** the gospel declared `cur`/`surv`/`lost`/`A`/`Ai`/`v`/`d` as function-local `var` arrays — all hoisted here.

| name | type | bytes | bound justification |
|---|---|---|---|
| `MARROW_BLOCK`    | `[u8; 12582912]` | 12 MiB | `256 stripes * 12 blocks * 4096` — full corpus capacity, gospel-exact (no down-scaling). Fits small code model's 2 GiB RIP-relative reach. |
| `MARROW_LIVE`     | `[u8; 3072]`     | 3 KiB  | `256 * 12` liveness flags. |
| `MARROW_HASH`     | `[u8; 98304]`    | 96 KiB | `256 * 12 * 32` recorded Keccak256 per block. |
| `MARROW_SEAL_ROOT`| `[u8; 32]`       | 32 B   | the recorded W30 corpus root (deepest persistent identity). |
| `MARROW_SEAL_CUR` | `[u8; 32]`       | 32 B   | scratch: freshly recomputed root for `bm_verify_seal` (was function-local). |
| `MARROW_HASH_CUR` | `[u8; 32]`       | 32 B   | scratch: recomputed block hash for `bm_verify_block` (D2: was `var cur[32]`). |
| `MARROW_SURV`     | `[u32; 8]`       | 32 B   | recover: surviving block indices (D2: was `var surv[8]`). Non-reentrant — see note. |
| `MARROW_LOST`     | `[u32; 4]`       | 16 B   | recover: lost block indices (D2: was `var lost[4]`). |
| `MARROW_A`        | `[u8; 64]`       | 64 B   | recover: k×k survivor matrix (D2: was `var A[64]`). |
| `MARROW_AI`       | `[u8; 64]`       | 64 B   | recover: A^{-1} (D2: was `var Ai[64]`). |
| `MARROW_V`        | `[u8; 8]`        | 8 B    | recover: per-byte survivor column (D2: was `var v[8]`). |
| `MARROW_D`        | `[u8; 8]`        | 8 B    | recover: per-byte reconstructed data column (D2: was `var d[8]`). |
| `MARROW_SEAL_LEN` | `[u8; 8]`        | 8 B    | seal-fold scratch: liveness/length bytes fed to keccak (canonicalizes the seal). |
| `MARROW_CAP`      | `u64 = 1u64`     | 8 B    | module authority capability id (NEW). Default `CAP_ENV_ROOT` (=1) so boot + existing consumers pass; `bm_init_cap` attenuates it. |
| `MARROW_SEAL_SET` | `u8 = 0u8`       | 1 B    | 1 once a seal root has been recorded (gates `bm_verify_seal`). |
| `MARROW_OPID`     | `[u8; 32]`       | 32 B   | witness op-id tag scratch (per-operation discriminator). |
| `MARROW_ZERO_ID`  | `[u8; 32]`       | 32 B   | canonical zero id (system producer / empty antecedent / empty in-commit). |

**Reentrancy note (W8/Trap 7 consequence):** hoisting `MARROW_SURV/LOST/A/AI/V/D` to module scope makes `bm_recover` non-reentrant. This is acceptable and correct for this module: bone-marrow recovery runs only on the serialized Phase-One boot path and the tissue-regen Tier-2 escalation, never concurrently. Flagged per briefing §3 Trap 7.

## Dependencies (externs)
All `extern @abi(c-msvc-x64)`. Provider NN and build status noted.

| extern | from | NN | built? |
|---|---|---|---|
| `fn gf8_mul(a: u32, b: u32) -> u32`   | `galois.iii` | 04 | **NOT YET BUILT** |
| `fn gf8_pow(base: u32, exp: u32) -> u32` | `galois.iii` | 04 | **NOT YET BUILT** |
| `fn gf8_inv(a: u32) -> u32`           | `galois.iii` | 04 | **NOT YET BUILT** |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | built ✓ |
| `fn ident_eq(a: *u8, b: *u8) -> u8`   | `identifier.iii` | 01 | built ✓ |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | built ✓ |
| `fn keccak256_init() -> i32`          | `keccak256.iii` | (numera) | built ✓ |
| `fn keccak256_update(input: *u8, len: u64) -> i32` | `keccak256.iii` | (numera) | built ✓ |
| `fn keccak256_final(out: *u8) -> i32` | `keccak256.iii` | (numera) | built ✓ |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | `capability.iii` | (aether) | built ✓ |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | `witness_hook.iii` | 07 | built ✓ |

**Defect D1 fix (systemic-defect class):** the gospel externed `gf256_mul/gf256_inv/gf256_pow(... : u8) -> u8 from "galois.iii"`. The real `numera/galois.iii` (gospel Layer 1 Module 04) exports **`gf8_mul/gf8_pow/gf8_inv`** taking/returning **`u32`** with the AES poly `0x11B` (verified against the galois gospel section, lines 938–976). The externs above are the corrected real names/types; call sites narrow `u8↔u32` (see Algorithm).

**Defect D5:** `galois.iii` is not yet built → the wave scheduler MUST order Module 04 (galois) before this module. `capability.iii`, `witness_hook.iii`, `keccak256.iii`, `identifier.iii` are all built.

**Systemic-defect cross-check (briefing §3.5):** (1) keccak — used `keccak256_init/update/final` from the real `keccak256.iii`, NOT `keccak.iii`; `ident_from_bytes` (which the gospel uses for hashing) internally calls `keccak256_oneshot` — kept. (2) witness emit — routed through real `wh_publish` in `witness_hook.iii`, never the fictional `ws_emit_fragment`/`witness_spine.iii`. (4) algebraic time — not referenced directly (witness_hook advances `at_advance` internally inside `wh_publish`); no `at_now` fiction. (5) capability — used real `cap_verify_rights`, never the fictional `cap_verify`.

## Algorithm

### `bm_init() -> i32`
Hand-rolled init. Zero `MARROW_LIVE[0 .. MARROW_MAX_STRIPE*MARROW_N)`; zero `MARROW_SEAL_ROOT[0..31]` and `MARROW_ZERO_ID[0..31]`; set `MARROW_CAP = 1u64` (CAP_ENV_ROOT default — keeps boot + consumers passing); set `MARROW_SEAL_SET = 0u8`. Deterministic (M2): pure memory writes. Returns `MARROW_OK`. **No `let mut` checkpoint-flag** (Trap 10): single counter loop only.

### `bm_init_cap(cap_id: u64) -> i32`  (NEW — M8)
Records the module's authority capability: `MARROW_CAP = cap_id`. A hardened deployment calls this after `bm_init` to attenuate from CAP_ENV_ROOT to a persist-write capability. Returns `MARROW_OK`. This is how capability mediation is added **without** changing the load-bearing `bm_write_data`/`bm_recover` signatures: the cap is threaded through module state, not the parameter list. Determinism: pure store.

### internal `bm_cap_ok() -> u8`  (NEW, non-export — M8)
Returns `cap_verify_rights(MARROW_CAP, CAP_RIGHT_PERSIST_WRITE)` (the real right-bit `0x0400u64` from `capability.iii`). Privileged mutators call this and refuse with `MARROW_E_DENIED` on `0u8`. Exact/algebraic (M4): a bitmask AND, no heuristic.

### internal `bm_block_ptr(stripe: u32, idx: u32) -> *u8`  / `bm_hash_ptr(...)` / `bm_live_idx(...)`
Offset math. **Defect-class Trap 4 fix:** every `u32`→`u64` widening in the offset is masked: `off = ((stripe as u64) & 0xFFFFFFFFu64) * (MARROW_N as u64) * (MARROW_BLOCK_SZ as u64) + ((idx as u64) & 0xFFFFFFFFu64) * (MARROW_BLOCK_SZ as u64)`, then `((&MARROW_BLOCK as u64) + off) as *u8` (element-address-of-static taken only inside this file — W1/W3). `bm_live_idx` returns `stripe * MARROW_N + idx` as `u32` (no pointer math; W4: result masked `& 0xFFFFFFFFu32`).

### internal `bm_record_hash(stripe, idx) -> i32`
`ident_from_bytes(bm_block_ptr(stripe,idx), MARROW_BLOCK_SZ as u64, bm_hash_ptr(stripe,idx))` → records Keccak256 of the 4 KiB block. Deterministic content hash (M6, W5 bit-identity). Returns `MARROW_OK`.

### `bm_write_data(stripe_id, idx, data: *u8) -> i32`  (signature PRESERVED)
1. `if bm_cap_ok() == 0u8 { return MARROW_E_DENIED }` (M8 — NEW gate, internal, sig unchanged).
2. Bounds: `if stripe_id >= MARROW_MAX_STRIPE { return MARROW_E_BAD }`; `if idx >= MARROW_K { return MARROW_E_BAD }` (only data positions writable directly).
3. Copy 4096 bytes `data → bm_block_ptr` via a single `u32` counter loop (W14 sentinel; no `break`).
4. `MARROW_LIVE[bm_live_idx] = 1u8`; `bm_record_hash`.
5. **Witness (M6/W16 — NEW):** `wh_publish(producer=&MARROW_ZERO_ID, opid=&MARROW_OPID["BM_WRITE"], in_commit=&MARROW_ZERO_ID, out_commit=bm_hash_ptr(stripe,idx), revtag=1u8 (reversible — old block recoverable via RS), phase=0u8, pillar=stripe as u16, antecedents=&MARROW_ZERO_ID, n_ante=0u32, payload=NULL/0, payload_len=0u32, out_frag_id=&MARROW_ZERO_ID-sink)`. Returns `MARROW_OK`. Determinism: out_commit is the deterministic block hash.

### `bm_read_data(stripe_id, idx, out: *u8) -> i32`  (signature PRESERVED)
Bounds (`idx >= MARROW_N` → bad; allows reading parity too); `if MARROW_LIVE[..] == 0u8 { return MARROW_E_BAD }`; copy 4096 bytes out via counter loop. **No capability gate** (read of own corpus is unprivileged; reversible/non-mutating, M9). No witness (pure read). Returns `MARROW_OK`.

### `bm_encode_stripe(stripe_id) -> i32`  (signature PRESERVED)
Vandermonde parity: `p_i = Σ_j d_j · alpha^(i·j)`, i∈[0,r), j∈[0,k), **per byte independently** (each of 4096 byte positions encoded separately — this is what makes it a systematic RS code, M15 algebraic determinism).
1. Bounds; verify all k data blocks live (else `MARROW_E_BAD`).
2. For each parity i: zero the parity block; for each data j: `coef = gf8_pow(MARROW_ALPHA, (i*jj) & 0xFFFFFFFFu32)` (the exponent stays a u32; **D1 narrowing** — `gf8_pow` is u32→u32); inner byte loop: `prod = gf8_mul(coef, dat[bb] as u32) as u8`; `par[bb] = par[bb] ^ prod`. Mark parity live; `bm_record_hash`.
No recursion (W15) — three nested counter loops (i, j, byte), each W14 sentinel. **Modulo-after-call (Trap 11): NONE** — the only reduction is GF reduction inside `gf8_mul`, never a `%` in this module.

### `bm_verify_block(stripe_id, idx) -> u8`  (signature PRESERVED — externed by tissue_regen)
Bounds → `0u8`; `if MARROW_LIVE == 0u8 { return 0u8 }`. Recompute hash into **`MARROW_HASH_CUR`** (D2: was function-local `var cur[32]`). `return ident_eq(&MARROW_HASH_CUR, bm_hash_ptr(stripe,idx))` (W10 boolean u8). Deterministic comparison.

### `bm_scrub(stripe_id) -> u32`  (signature PRESERVED)
Counter loop i∈[0,MARROW_N): if block live and `bm_verify_block == 0u8`, increment `bad`. Return `bad` count. No mutation, no capability gate (diagnostic read). W14 sentinel loop.

### `bm_recover(stripe_id, lost_mask: u64) -> i32`  (signature PRESERVED — externed by tissue_regen)
1. `if bm_cap_ok() == 0u8 { return MARROW_E_DENIED }` (M8 — recovery rewrites the deepest store).
2. Bounds.
3. Walk i∈[0,MARROW_N): test `bit = (lost_mask >> i) & 1`. If `bit==0` and live and `nsurv < MARROW_K`: `MARROW_SURV[nsurv]=i; nsurv++`. If `bit==1` and `nlost < MARROW_R`: `MARROW_LOST[nlost]=i; nlost++`.
4. `if nsurv < MARROW_K { return MARROW_E_TOO_BAD }`.
5. Build k×k matrix `MARROW_A`: row q = the encoding-matrix row of survivor `MARROW_SURV[q]` (data row = standard basis `e_idx`; parity row = `gf8_pow(MARROW_ALPHA, (i*k) & mask)` over k columns — **D1 narrowing**).
6. Invert via **Gauss-Jordan over GF(2^8)** into `MARROW_AI` (hand-rolled, M1): forward elimination with explicit pivot search (W14 sentinel — pivot found by `piv==MARROW_K` guard, not `break`), row swap in both A and Ai, normalize by `gf8_inv(pivot)`, eliminate column from all other rows via `gf8_mul`+XOR. Singular → `MARROW_E_SINGULAR`.
7. Per byte b∈[0,4096): gather survivor column into `MARROW_V[k]`; `MARROW_D[ii] = Σ_jj gf8_mul(MARROW_AI[ii,jj] as u32, MARROW_V[jj] as u32) as u8` (D1 narrowing). Write `MARROW_D[lidx]` back to each lost **data** position (`lidx < MARROW_K`).
8. Mark recovered data blocks live; `bm_record_hash` each.
9. Recompute parity for any lost **parity** position (`lidx >= MARROW_K`) from the now-complete data (same Vandermonde inner loop as `bm_encode_stripe`); mark live; rehash.
10. **Witness (M6/W16 — NEW):** `wh_publish(producer=&MARROW_ZERO_ID, opid=&MARROW_OPID["BM_RECOVER"], in_commit=&MARROW_ZERO_ID, out_commit=&MARROW_SEAL_ROOT or recovered-block hash, revtag=1u8, phase=0u8, pillar=stripe as u16, n_ante=0, payload=NULL,0, out_frag sink)`. Return `MARROW_OK`.
All explicit-stack/counter form (W15 no recursion). `MARROW_SURV/LOST/A/AI/V/D` are module-scope (D2/Trap 7); non-reentrant by design (flagged above).

### `bm_seal_compute(out_root: *u8) -> i32`  (NEW — W30, the maximal core)
Computes the **corpus root** = the deepest persistent identity, by a single deterministic streaming-Keccak256 fold over the *entire* recorded block-hash table in canonical order (NOT merkle: `merkle_compute_root` caps at `MK_MAX_LEAVES=1024` but the corpus has `256*12 = 3072` block hashes — a fold is the correct unbounded primitive and stays NIH):
```
keccak256_init()
for stripe in 0..MARROW_MAX_STRIPE:
  for idx in 0..MARROW_N:
    MARROW_SEAL_LEN[0] = MARROW_LIVE[bm_live_idx(stripe,idx)]   // canonicalize liveness into the digest
    keccak256_update(&MARROW_SEAL_LEN, 1u64)
    if live: keccak256_update(bm_hash_ptr(stripe,idx), 32u64)
    else:    keccak256_update(&MARROW_ZERO_ID, 32u64)           // dead slot = canonical zero (total function over the grid)
keccak256_final(out_root)
```
Folding liveness + (hash | zero) for *every* grid slot makes the seal a **total** function of the whole archive (M15): two archives with the same live-set and same block contents produce the identical 32-byte root; any single-byte block corruption or liveness change flips it (M2/W5 bit-identity, M6 content-chain). No recursion (W15: two nested counter loops). Deterministic, no capability needed (pure read → caller-supplied buffer). Returns `MARROW_OK`.

### `bm_seal_set(cap_id: u64) -> i32`  (NEW — W30 record, M8)
1. `if cap_verify_rights(cap_id, CAP_RIGHT_PERSIST_WRITE) == 0u8 { return MARROW_E_DENIED }` (sealing the corpus root is the single most privileged act in the substrate — explicit caller cap required, NOT the module default).
2. `bm_seal_compute(&MARROW_SEAL_ROOT)`; `MARROW_SEAL_SET = 1u8`.
3. **Witness (M6):** `wh_publish` with `out_commit = &MARROW_SEAL_ROOT`, `revtag = 0u8` (the seal record is **irreversible** — it defines identity; M9 explicit non-reversibility, capability-gated). Returns `MARROW_OK`.

### `bm_verify_seal() -> u8`  (NEW — W30 boot check; the law's enforcement point)
`if MARROW_SEAL_SET == 0u8 { return 0u8 }` (no seal → cannot pass; fail-closed). `bm_seal_compute(&MARROW_SEAL_CUR)`; `return ident_eq(&MARROW_SEAL_CUR, &MARROW_SEAL_ROOT)` (W10 u8). This is the function the boot fold calls **before any other module loads**; `0u8` ⇒ halt boot (W30: "a failed seal verification halts boot and demands operator intervention"). On `0u8`, the boot fold (not this fn — to keep `bm_verify_seal` a pure predicate) publishes the distress fragment. Deterministic comparison; M5 no-bricking is satisfied because failure refuses (halts) rather than mutates.

### `bm_seal_root(out_root: *u8) -> i32`  (NEW — getter)
`if MARROW_SEAL_SET == 0u8 { return MARROW_E_NOSEAL }`; `ident_copy(&MARROW_SEAL_ROOT, out_root)`. Returns `MARROW_OK`. Pure read.

## KAT Vectors (>= 3)
A Phase-2 self-test (`bm_selftest() -> u64`, 99 = pass) must check byte-for-byte. Block size in the KAT is reduced ONLY in the test harness if desired, but the canonical vectors below use the real 4 KiB blocks with deterministic fill.

1. **RS round-trip / single-block recovery (the core invariant).** `bm_init()`. Fill data block `(stripe=0, idx=j)` for j∈[0,8) with byte pattern `MARROW_BLOCK[..] = (j*37 + bytepos) & 0xFF`; `bm_write_data` each; `bm_encode_stripe(0)`. Snapshot block 0's 4096 bytes. Lose block 0: clear `MARROW_LIVE[0]`, zero `MARROW_BLOCK[0..4096)`; `bm_recover(0, 1u64)`. **Expect:** recovered `bm_read_data(0,0,out)` byte-for-byte equals the snapshot; `bm_verify_block(0,0) == 1u8`; `bm_scrub(0) == 0u32`. (Proves Gauss-Jordan inversion + per-byte reconstruction; this is the exact tissue_regen Tier-2 path.)

2. **Max-loss recovery boundary (r=4 simultaneous).** After test 1's clean stripe, lose 4 blocks `lost_mask = 0b1001_0001_0100` (mix of data idx 2, data idx 7, parity idx 8 — `0x494`): `bm_recover(0, 0x494u64)`. **Expect:** `MARROW_OK`, all four reconstructed, `bm_scrub(0) == 0`. Then lose 5 blocks (`0x4D4`, one more than r): `bm_recover` **Expect** `MARROW_E_TOO_BAD (-2i32)` (proves the `nsurv < MARROW_K` refusal — the negative case, not just the positive).

3. **W30 seal determinism + tamper detection.** After a clean stripe, `bm_seal_set(CAP_ENV_ROOT)`; capture `bm_seal_root(r0)`. Call `bm_seal_compute(r1)` again with no mutation → **Expect** `ident_eq(r0,r1)==1u8` and `bm_verify_seal()==1u8`. Now flip ONE byte of one live data block directly in `MARROW_BLOCK` (simulating undetected bit-rot) and `bm_record_hash` it, then `bm_verify_seal()` → **Expect** `0u8` (the recomputed root diverges; W30 halt path triggers). Re-running `bm_seal_compute` on the unmodified archive must reproduce `r0` exactly (cross-run bit-identity, M2/M10).

4. **Capability refusal (negative case, M8).** `bm_init()` then `bm_init_cap(some_cap_with_no_PERSIST_WRITE)`: `bm_write_data(0,0,data)` → **Expect** `MARROW_E_DENIED (-4i32)`; `bm_recover(0,1u64)` → **Expect** `MARROW_E_DENIED`. (Proves the gate FAILS on an under-privileged cap, per memory "prove the negative case.")

5. **Galois identity anchor (D1 correctness).** Direct: `gf8_mul(2u32, 0u32)==0`, `gf8_mul(1u32, 0x53u32)==0x53`, `gf8_pow(2u32,0u32)==1`, `gf8_inv(gf8_inv(0x53u32))==0x53` (involution). Anchors that the corrected externs are wired to the real GF(2^8) with poly 0x11B (standard AES field vectors).

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| 1 multi-line `fn` | yes (all sigs) | every signature emitted single-line; the long `wh_publish` extern is one physical line. |
| 2 module-const linker-global | **yes** | every const prefixed `MARROW_` (grep-confirmed 0 collisions); `BM_*`→`MARROW_*` rename. |
| 3 signed ordering-compare SIGSEGV | low | all error checks use `== / !=` against negative sentinels (W11); no `< 0`/`>=` on i32/i64. Loop bounds are on `u32`/`u64` (unsigned ordering is safe). |
| 4 u32-in-u64-slot garbage | **yes (primary)** | `bm_block_ptr`/`bm_hash_ptr` mask every `(stripe as u64)`/`(idx as u64)` with `& 0xFFFFFFFFu64` BEFORE the offset multiply (the gospel did `as u64` unmasked → flagged). |
| 5 u32 ptr-store width | low | block/hash bytes are `u8` stored through `*u8` byte loops; no `*u32` stores. |
| 6 nested block comments | no | header uses one `/* */`; all inline notes are `//` or single-level. No em-dash in comments (Trap 9). |
| 7 local `var` arrays | **yes (D2)** | ALL seven hoisted to module scope (`MARROW_HASH_CUR/SURV/LOST/A/AI/V/D` + seal scratch). Non-reentrancy of `bm_recover` flagged + justified (serialized boot/regen path). |
| 8 `} else {` one line | yes | `keccak`-style `if p==.. { } else { }` written on a single line wherever used (seal fold + verify). |
| 9 em-dash in comment | n/a | ASCII `--` only in comments. |
| 10 `let mut` checkpoint-flag | yes | loops use plain counters; the only flag is module-scope `MARROW_SEAL_SET`/pivot guard, never a function-local mutated bool. |
| 11 `%` modulo-after-call | **NO** | the module performs NO `%` operation; all GF reduction is inside `gf8_*` (poly XOR). Explicitly verified. |
| 12 `@specialize *T` stride | no | not generic; all arrays are concrete `u8`/`u32`. |

## Gap / Fix List
1. **(D1, systemic) GF externs doubly-wrong.** Gospel: `gf256_mul/gf256_inv/gf256_pow(... u8) -> u8 from "galois.iii"`. Real provider exports `gf8_mul/gf8_pow/gf8_inv(u32)->u32` (poly 0x11B), verified in the galois gospel section (Layer 1 Mod 04, lines 938–976). **Fix:** replace all three externs (see Dependencies); narrow at call sites `gf8_mul(coef, byte as u32) as u8`, exponent kept u32 masked; `MARROW_ALPHA` retyped `u32`.
2. **(D2, Trap 7) Seven function-local `var` arrays.** `var cur:[u8;32]` in `bm_verify_block`; `var surv:[u32;8]`, `var lost:[u32;4]`, `var A:[u8;64]`, `var Ai:[u8;64]`, `var v:[u8;8]`, `var d:[u8;8]` in `bm_recover`. iiis parses `var [T;N]` only at module scope. **Fix:** hoisted to the `MARROW_*` module-scope buffers (Data Structures); document `bm_recover` non-reentrancy.
3. **(D3, M6/W16) No witness emission.** A module that rewrites the substrate's deepest persistent store emitted zero provenance. **Fix:** `bm_write_data`, `bm_recover`, `bm_seal_set` each `wh_publish` a fragment (real hook, `from "witness_hook.iii"`); reversible writes carry `revtag=1`, the seal record carries `revtag=0`. Seal-verify failure's distress fragment is emitted by the boot fold caller (keeps `bm_verify_seal` a pure predicate).
4. **(D4, M8) No capability mediation.** `bm_write_data`/`bm_recover` rewrote R-2 state unguarded. **Fix:** internal `bm_cap_ok()` gate via `cap_verify_rights(MARROW_CAP, CAP_RIGHT_PERSIST_WRITE)`; `bm_seal_set` requires the caller's own `cap_id` to carry `CAP_RIGHT_PERSIST_WRITE`. Threaded through module state + new `bm_init_cap` so the **consumer signatures stay byte-identical** (critical: `bm_recover`/`bm_verify_block` are externed by `tissue_regen.iii`). Default cap = `CAP_ENV_ROOT` keeps the boot path green.
5. **(W30, the defining gap) No seal at all.** The gospel body has no `bm_seal_*`/`bm_verify_seal`. W30 (gospel §319–321) mandates the bone-marrow seal be verified at every boot before any module loads; the dispatch names this module "the substrate's deepest persistent identity." **Fix:** added `bm_seal_compute` (Keccak fold over the whole hash grid, total function), `bm_seal_set` (capability-gated record), `bm_verify_seal` (boot predicate), `bm_seal_root` (getter). Chose a streaming-Keccak fold over `merkle_compute_root` because the corpus has 3072 block hashes > merkle's `MK_MAX_LEAVES=1024`.
6. **(D5) `galois.iii` not yet built.** Wave scheduler must build Module 04 (galois) before Module 27. All other deps (identifier, keccak256, capability, witness_hook) are built.
7. **(Trap 4) Unmasked u32→u64 in offset math** in the gospel's `bm_block_ptr`/`bm_hash_ptr`. **Fix:** mask `& 0xFFFFFFFFu64` on each widened index before the multiply.
8. **(consistency) Constant prefix.** Gospel constants used `BM_`; renamed to `MARROW_` per assignment (Trap 2). Function symbols `bm_*` unchanged (ABI contract with consumers).
9. **(verified COMPLETE) the RS core math.** The Vandermonde encode, the encoding-matrix construction (basis rows for data, Vandermonde rows for parity), the Gauss-Jordan GF(2^8) inversion, and the per-byte `d = A^{-1}·v` reconstruction are algorithmically correct and W14/W15-clean; preserved verbatim apart from the D1 narrowing and D2 hoist.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/bone_marrow.iii
 *
 * III STDLIB - aether::bone_marrow
 *
 * Replicated seed archive. Reed-Solomon erasure coding over GF(2^8),
 * k=8 data + r=4 parity per stripe, crowned by the W30 bone-marrow
 * seal: a Keccak256 corpus root verified at every boot before any
 * other module loads. The substrate's deepest persistent identity.
 *
 * Block size: MARROW_BLOCK_SZ (4 KiB). Stripe width: MARROW_K + MARROW_R.
 * Recovers any r simultaneous block losses by Gauss-Jordan inversion of
 * the surviving k x k submatrix over GF(2^8).
 *
 * Hexad: kind_witness + kind_repair.  Ring: R-2.  K: 1.00.
 * Discipline: W2 (<=4 params), W8 (static tables), W9/W10 (neg-i32 / u8),
 *   W14 (sentinel loops, no break), W15 (no recursion). Trap 4 (masked
 *   offsets), Trap 7 (no local var arrays -- bm_recover non-reentrant).
 */
module aether_bone_marrow

extern @abi(c-msvc-x64) fn gf8_mul(a: u32, b: u32) -> u32 from "galois.iii"
extern @abi(c-msvc-x64) fn gf8_pow(base: u32, exp: u32) -> u32 from "galois.iii"
extern @abi(c-msvc-x64) fn gf8_inv(a: u32) -> u32 from "galois.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const MARROW_OK         : i32 =  0i32
const MARROW_E_BAD      : i32 = -1i32
const MARROW_E_TOO_BAD  : i32 = -2i32
const MARROW_E_SINGULAR : i32 = -3i32
const MARROW_E_DENIED   : i32 = -4i32
const MARROW_E_NOSEAL   : i32 = -5i32

const MARROW_BLOCK_SZ   : u32 = 4096u32
const MARROW_K          : u32 = 8u32
const MARROW_R          : u32 = 4u32
const MARROW_N          : u32 = 12u32
const MARROW_MAX_STRIPE : u32 = 256u32
const MARROW_ALPHA      : u32 = 2u32
const MARROW_HASH_SZ    : u64 = 32u64

// Right-bit literal mirrored from capability.iii (CAP_RIGHT_PERSIST_WRITE = 0x0400).
const MARROW_RIGHT_WRITE : u64 = 0x0400u64

var MARROW_BLOCK     : [u8; 12582912]   // 256 * 12 * 4096
var MARROW_LIVE      : [u8; 3072]       // 256 * 12
var MARROW_HASH      : [u8; 98304]      // 256 * 12 * 32
var MARROW_SEAL_ROOT : [u8; 32]
var MARROW_SEAL_CUR  : [u8; 32]
var MARROW_HASH_CUR  : [u8; 32]
var MARROW_SURV      : [u32; 8]
var MARROW_LOST      : [u32; 4]
var MARROW_A         : [u8; 64]
var MARROW_AI        : [u8; 64]
var MARROW_V         : [u8; 8]
var MARROW_D         : [u8; 8]
var MARROW_SEAL_LEN  : [u8; 8]
var MARROW_OPID      : [u8; 32]
var MARROW_ZERO_ID   : [u8; 32]
var MARROW_CAP       : u64 = 1u64
var MARROW_SEAL_SET  : u8  = 0u8

// ---- internal helpers (non-export) ----
fn bm_block_ptr(stripe: u32, idx: u32) -> *u8 { /* TODO: masked-offset addr per Algorithm (Trap 4) */ }
fn bm_hash_ptr(stripe: u32, idx: u32) -> *u8 { /* TODO: masked-offset addr per Algorithm */ }
fn bm_live_idx(stripe: u32, idx: u32) -> u32 { /* TODO: (stripe*MARROW_N+idx) & 0xFFFFFFFFu32 */ }
fn bm_cap_ok() -> u8 { /* TODO: return cap_verify_rights(MARROW_CAP, MARROW_RIGHT_WRITE) */ }
fn bm_record_hash(stripe: u32, idx: u32) -> i32 { /* TODO: ident_from_bytes(block, 4096, hash) */ }
fn bm_build_encoding_row(row: u32, out: *u8) -> i32 { /* TODO: basis row (row<K) / Vandermonde row (row>=K) per Algorithm */ }
fn bm_invert_8x8(mat: *u8, inv: *u8) -> i32 { /* TODO: Gauss-Jordan over GF(2^8) per Algorithm (gf8_inv/gf8_mul) */ }

// ---- public archive API (signatures PRESERVED) ----
fn bm_init() -> i32 @export { /* TODO: zero LIVE/SEAL/ZERO_ID; MARROW_CAP=1; MARROW_SEAL_SET=0 */ }
fn bm_init_cap(cap_id: u64) -> i32 @export { /* TODO: MARROW_CAP = cap_id */ }
fn bm_write_data(stripe_id: u32, idx: u32, data: *u8) -> i32 @export { /* TODO: cap gate; bounds; copy 4096; live; rehash; wh_publish */ }
fn bm_read_data(stripe_id: u32, idx: u32, out: *u8) -> i32 @export { /* TODO: bounds; live; copy 4096 out */ }
fn bm_encode_stripe(stripe_id: u32) -> i32 @export { /* TODO: per-byte Vandermonde parity via gf8_pow/gf8_mul; rehash parity */ }
fn bm_verify_block(stripe_id: u32, idx: u32) -> u8 @export { /* TODO: recompute into MARROW_HASH_CUR; ident_eq */ }
fn bm_scrub(stripe_id: u32) -> u32 @export { /* TODO: count bad live blocks via bm_verify_block */ }
fn bm_recover(stripe_id: u32, lost_mask: u64) -> i32 @export { /* TODO: cap gate; collect SURV/LOST; build A; invert; per-byte d=Ai*v; rewrite data; recompute lost parity; wh_publish */ }

// ---- W30 seal (NEW) ----
fn bm_seal_compute(out_root: *u8) -> i32 @export { /* TODO: keccak fold over LIVE+HASH grid per Algorithm */ }
fn bm_seal_set(cap_id: u64) -> i32 @export { /* TODO: cap_verify_rights(cap_id, MARROW_RIGHT_WRITE); seal_compute into ROOT; SEAL_SET=1; wh_publish revtag=0 */ }
fn bm_verify_seal() -> u8 @export { /* TODO: if !SEAL_SET return 0; seal_compute into CUR; ident_eq(CUR,ROOT) */ }
fn bm_seal_root(out_root: *u8) -> i32 @export { /* TODO: if !SEAL_SET return MARROW_E_NOSEAL; ident_copy(ROOT,out) */ }

// ---- self-test (99 = pass) ----
// var MARROW_T_* scratch buffers + fn bm_selftest() -> u64 @export per KAT Vectors 1-5.
```
