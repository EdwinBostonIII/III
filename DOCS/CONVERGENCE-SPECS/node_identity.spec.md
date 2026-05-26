# 28 aether/node_identity.iii — Implementation Spec

## Verdict
**PARTIAL** — The gospel candidate body has the right *shape* (init → 3 HKDF-derived Ed25519 sub-keys → pub/sign accessors → node-id) but is **non-compilable and semantically broken** against the realized substrate: every crypto extern is wrong (wrong provider file, wrong signature, wrong return type, wrong param order), the signing path passes a 64-byte expanded key where the real signer demands a 32-byte *seed*, all three keccak paths stream through the wrong module, and it declares forbidden function-local `var` arrays. It also under-realizes the M6/M8 intent (no witnessed node-birth, no capability gate). This spec closes every gap and raises it to the maximal intent.

## Purpose
`aether::node_identity` is the substrate's **per-host cryptographic selfhood**: at boot it deterministically derives, from a hardware-bound seed combined with the constitutional bootstrap secret, three Ed25519 keypairs — an **identity** key (signs attestations of *who this node is*), a **communication** key (signs federation messages), and a **witness** key (signs witness fragments this node emits) — plus a 32-byte canonical **node id** = Keccak256(identity public key). It is the root of Discipline Three (identity resolution across hosts): two physically distinct hosts can never collide because the hardware-bound seed is a per-machine runtime input. Hexad: `kind_essence + kind_witness`. Ring: **R-2**. K-vector: **1.00**.

## Public API
The gospel function names (`ni_*`) are the federation contract and are preserved verbatim. Return convention: every public fn returns `i32` status — `NODEID_OK = 0`, negative `NODEID_E_*` on failure (W9/W12), compared by equality only (W11). The one query that is naturally boolean returns `u8` (W10).

```
fn ni_init(args: *u8) -> i32 @export
fn ni_init_witnessed(args: *u8, cap_id: u64) -> i32 @export
fn ni_identity_pub(out_pub: *u8) -> i32 @export
fn ni_communication_pub(out_pub: *u8) -> i32 @export
fn ni_witness_pub(out_pub: *u8) -> i32 @export
fn ni_identity_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 @export
fn ni_communication_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 @export
fn ni_witness_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 @export
fn ni_node_id(out_id: *u8) -> i32 @export
fn ni_is_inited() -> u8 @export
fn ni_selftest() -> u64 @export
```

**W2 reconciliation of `ni_init`.** The gospel's `ni_init(hw_seed, hw_seed_len, bootstrap_secret, bs_len)` is exactly 4 params — legal under W2, but it cannot then also carry a capability (M8) or be witnessed (M6) without exceeding 4. Maximal design therefore passes the four seed fields as a **4-field aggregate by pointer** (`NodeIdInitArgs`, W2's prescribed remedy) so the privileged/witnessed variant `ni_init_witnessed(args, cap_id)` stays at 2 params. `ni_init(args)` is the un-gated convenience entry (equivalent to `ni_init_witnessed(args, CAP_INVALID)` with the cap check skipped only when the env has not yet minted caps at very-early boot). The aggregate layout is fixed and documented under Data Structures.

## Constant Namespace
**PREFIX = `NODEID_`** (dispatched assignment; authoritative). The gospel body used `NI_` for constants — that is *reconciled to* `NODEID_` here so the linker-global `const` namespace (Trap 2) is unambiguous. Function names remain `ni_*` (the API contract; functions are not linker-global constants). Module-scope `var`s are also `NODEID_`-prefixed for one consistent namespace.

grep results (read-only, `C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB`): `NODEID_` → **0 matches**; `NI_` (as `^(const|var|fn) NI_`) → **0 matches**; `aether_node_identity` module name → **0 matches**; `ni_init|ni_node_id|ni_identity_sign` → **0 matches**. **No collision.**

| const | type | value | meaning |
|---|---|---|---|
| `NODEID_OK` | i32 | `0i32` | success |
| `NODEID_E_BAD` | i32 | `-1i32` | not initialized / null out |
| `NODEID_E_DENIED` | i32 | `-2i32` | capability lacks required rights (M8) |
| `NODEID_E_SIGN` | i32 | `-3i32` | underlying ed25519_sign returned failure |
| `NODEID_E_DERIVE` | i32 | `-4i32` | keypair derivation failed |
| `NODEID_KEY_BYTES` | u64 | `32u64` | public key / node id length |
| `NODEID_SIG_BYTES` | u64 | `64u64` | Ed25519 detached signature length |
| `NODEID_KEYS_BYTES` | u64 | `64u64` | seed(32)‖pub(32) blob for the c4 sign path |
| `NODEID_ARGS_OFF_SEED` | u64 | `0u64` | offset of hw_seed ptr in `NodeIdInitArgs` |
| `NODEID_RIGHT_ATTEST` | u64 | `0x0800u64` | required cap right (mirrors `CAP_RIGHT_ATTEST`) |
| `NODEID_RIGHT_SIGN` | u64 | `0x1000u64` | required cap right (mirrors `CAP_RIGHT_CRYPTO_SIGN`) |
| `NODEID_INFO_ID_LEN` | u64 | `19u64` | strlen("iii::node::identity") |
| `NODEID_INFO_COMM_LEN` | u64 | `24u64` | strlen("iii::node::communication") |
| `NODEID_INFO_WIT_LEN` | u64 | `18u64` | strlen("iii::node::witness") |
| `NODEID_PRODUCER_LEN` | u64 | `21u64` | strlen("aether::node_identity") |
| `NODEID_OPID_LEN` | u64 | `28u64` | strlen("aether::node_identity::birth") |

## Data Structures
All buffers are module-scope (Trap 7 forbids function-local `var` arrays). Sizes are exact and small; the only "bound to justify" (W8) is the per-role key store, which is fixed at **exactly 3 roles** (identity, communication, witness) — there is no growth dimension, so no slot table is needed.

| name | type | size (bytes) | justification |
|---|---|---|---|
| `NODEID_ID_KEYS` | `[u8; 64]` | 64 | identity role: seed(32)‖pub(32) for `ed25519_sign_c4` |
| `NODEID_COMM_KEYS` | `[u8; 64]` | 64 | communication role: seed‖pub |
| `NODEID_WIT_KEYS` | `[u8; 64]` | 64 | witness role: seed‖pub |
| `NODEID_NODE_ID` | `[u8; 32]` | 32 | Keccak256(identity_pub) |
| `NODEID_NODE_SEED` | `[u8; 32]` | 32 | node_seed = Keccak256(hw_seed‖bootstrap_secret); HKDF PRK |
| `NODEID_HKDF_SEED` | `[u8; 32]` | 32 | per-role HKDF-Expand T(1) output (the 32-byte sub-key seed) |
| `NODEID_CONCAT` | `[u8; 8224]` | 8224 | concat scratch for oneshot hashing: PRK(32)+info(≤max)+ctr(1), and node_seed concat (hw_seed‖bootstrap up to a bounded cap). Bound = 32 + 8191 + 1; see below |
| `NODEID_PRODUCER` | `[u8; 32]` | 32 | producer id = ident_from_bytes("aether::node_identity") |
| `NODEID_OPID_BIRTH` | `[u8; 32]` | 32 | op id = ident_from_bytes("aether::node_identity::birth") |
| `NODEID_INITED` | `u8` | 1 | 0 until `ni_init*` completes; gates every accessor |

**`NodeIdInitArgs` aggregate (passed by `*u8`, W2 remedy).** Fixed 32-byte layout, little-endian, read field-by-field:
- bytes `[0..8)`  : `hw_seed`        (`*u8` as u64)
- bytes `[8..16)` : `hw_seed_len`    (u64)
- bytes `[16..24)`: `bootstrap_secret` (`*u8` as u64)
- bytes `[24..32)`: `bs_len`         (u64)

**`NODEID_CONCAT` bound (W8).** `ni_init` hashes `hw_seed ‖ bootstrap_secret` in one shot; HKDF-Expand hashes `PRK(32) ‖ info ‖ 0x01`. The dominant case is the node-seed concat. The hardware-bound seed (CPUID leaves + chassis serial) and the constitutional bootstrap secret are both small fixed-format blobs; we bound the *combined* input at **8191 bytes** (caller contract — `ni_init` returns `NODEID_E_BAD` if `hw_seed_len + bs_len > 8191`). 8224 = 32 (max PRK prefix reuse) + 8191 + 1 (ctr), one allocation reused for both hash shapes. This avoids the streaming keccak param-spill trap entirely by always hashing a single contiguous buffer (the realized identifier.iii strategy).

## Dependencies (externs)
All providers are **BUILT** (verified by reading each file). Signatures below are the *real* ones — the gospel's externs for ed25519 and keccak were wrong and are corrected here.

| extern (real signature) | from | NN | built? |
|---|---|---|---|
| `keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32` | `keccak256.iii` | 0/04-closure | **built** |
| `ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | **built** |
| `ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | **built** |
| `ed25519_keypair_from_seed(seed_32: *u8, pubkey_32: *u8, privkey_64: *u8) -> u32` | `crypt_ed25519.iii` | — | **built** |
| `ed25519_sign_c4(keys: *u8, msg: *u8, msg_len: u64, sig_out: *u8) -> u8` | `crypt_ed25519.iii` | — | **built** |
| `cap_verify_rights(id: u64, required: u64) -> u8` | `capability.iii` | — | **built** |
| `wh_publish(producer,opid,in_commit,out_commit,revtag:u8,phase:u8,pillar:u16,antecedents,n_ante:u32,payload,payload_len:u32,out_frag_id) -> u64` | `witness_hook.iii` | 07 | **built** |
| `wh_chain_root(out_id: *u8) -> i32` | `witness_hook.iii` | 07 | **built** |

**Not-yet-built dependencies: 0.** Every provider exists and was read. (No Phase-2 getter additions are required of other modules — `node_identity` produces, never consumes, witness fields.)

**Externs explicitly NOT used (gospel errors corrected):**
- ❌ `keccak256_init/update/final from "keccak.iii"` — wrong file *and* streaming form trips the param-spill trap; replaced by `keccak256_oneshot`.
- ❌ `ed25519_keypair_from_seed(...) -> i32` — real return is **u32** (0=ok, 1=fail); gate with `!= 0u32`.
- ❌ `ed25519_sign(msg, msg_len, priv_key, pub_key, out_sig) -> i32` — real is `ed25519_sign(seed, pk, msg, msg_len, sig)->u8`, **5 params**, and the first arg is the **32-byte seed**, *not* a 64-byte private key. Use the 4-param `ed25519_sign_c4(keys=seed‖pub, msg, msg_len, sig)->u8` (W2-clean), gate with `!= 1u8`.

## Algorithm
NIH (M1): the only cryptography is Keccak-256 (hand-rolled in `keccak256.iii`) and Ed25519 (hand-rolled in `crypt_ed25519.iii`); HKDF-Expand is hand-rolled here as a single Keccak block. No floating point, no ML/heuristics (M3/M4) — every output is a pure function of the two input blobs. Determinism (M2)/bit-identity (W5): identical `(hw_seed, bootstrap_secret)` → identical `node_seed` → identical per-role HKDF seeds → identical Ed25519 keypairs (RFC 8032 is fully deterministic) → identical node id and identical signatures, cross-run and cross-CPU. **No recursion (W15)** anywhere; the only loops are fixed-count byte copies driven by a u64 counter (sentinel/condition form, no `break`, W14).

**Internal `ni_hkdf_expand(prk_off_is_NODEID_NODE_SEED, info: *u8, info_len: u64, out: *u8)` — HKDF-Expand, 1 block.**
RFC 5869 single-block expand with Keccak-256 as PRF: `T(1) = Keccak256(PRK ‖ info ‖ 0x01)`, output = `T(1)[0..32]` (exactly one 32-byte block needed). Hand-rolled by building the contiguous buffer `NODEID_CONCAT = NODEID_NODE_SEED(32) ‖ info(info_len) ‖ 0x01` then one `keccak256_oneshot` over `32 + info_len + 1` bytes into `out`. No streaming → no param-spill, no modulo-after-call. (≤4 params; counts as 4 if we pass prk explicitly — kept at 3 + uses module-scope PRK to stay clear.)

**`ni_init(args)` / `ni_init_witnessed(args, cap_id)`.**
1. Read the four fields out of `NodeIdInitArgs` (LE byte loads, masking each `as u64 & 0xFFFFFFFFFFFFFFFFu64` is a no-op for u64 but pointer fields are reconstituted via the documented little-endian assembly to dodge the u32-in-u64 trap — here all four are full u64, so no masking hazard).
2. (witnessed variant only) **M8 gate:** `cap_verify_rights(cap_id, NODEID_RIGHT_ATTEST | NODEID_RIGHT_SIGN)`; if `!= 1u8` return `NODEID_E_DENIED`. The plain `ni_init` skips this (very-early boot, before the env cap is minted).
3. Bound check: if `hw_seed_len + bs_len > 8191u64` return `NODEID_E_BAD`.
4. **node_seed:** build `NODEID_CONCAT = hw_seed ‖ bootstrap_secret`; `keccak256_oneshot(&NODEID_CONCAT, hw_seed_len + bs_len, &NODEID_NODE_SEED)`.
5. **Three roles**, each: `ni_hkdf_expand(info_role, len_role, &NODEID_HKDF_SEED)`; copy `NODEID_HKDF_SEED` into bytes `[0..32)` of the role's `*_KEYS`; `ed25519_keypair_from_seed(&NODEID_HKDF_SEED, pub_tmp = &*_KEYS[32], privkey_64 = scratch)` — **the 32 high bytes of `*_KEYS` receive the pubkey directly** (so `*_KEYS` = seed‖pub, the c4 layout). If `ed25519_keypair_from_seed != 0u32` return `NODEID_E_DERIVE`. The 64-byte `privkey_64` out is discarded into a module-scope throwaway (`NODEID_CONCAT` head region reused) because the c4 signer re-derives the scalar from the seed.
   - info strings: `"iii::node::identity"` (19), `"iii::node::communication"` (24), `"iii::node::witness"` (18) — exact lengths as constants above.
6. **node id:** `ident_from_bytes(&NODEID_ID_KEYS[32], 32u64, &NODEID_NODE_ID)` (= Keccak256(identity_pub)).
7. `NODEID_INITED = 1u8`.
8. (witnessed variant only) **M6 birth fragment:** `wh_chain_root(in_commit)`; `out_commit = NODEID_NODE_ID`; `wh_publish(NODEID_PRODUCER, NODEID_OPID_BIRTH, in_commit, NODEID_NODE_ID, revtag=0, phase=0, pillar=0, antecedents=0, n_ante=0, payload=NODEID_ID_KEYS[32..](the identity pub), payload_len=32, out_frag_id=0)`. The fragment ties the node's existence into the witness chain (M6/M10: recomputable from the recorded identity pub). Reversibility (M9): `revtag=0` marks it a normal (non-reversal) fragment; node birth is intentionally **not** reversible (a host's identity is permanent) — this is the one capability-gated exception (M5/M9), justified because re-deriving an identical identity is always possible from the same seed, so nothing is *bricked*.
9. return `NODEID_OK`.

**`ni_identity_pub` / `ni_communication_pub` / `ni_witness_pub`.**
If `NODEID_INITED == 0u8` return `NODEID_E_BAD`. Copy bytes `[32..64)` of the role `*_KEYS` (the pubkey half) into `out_pub` via a 32-iteration u64-counter loop. Pure read; deterministic.

**`ni_identity_sign` / `ni_communication_sign` / `ni_witness_sign`.**
If `NODEID_INITED == 0u8` return `NODEID_E_BAD`. Call `ed25519_sign_c4(&role_KEYS, msg, msg_len, out_sig)` (keys = seed‖pub). If `!= 1u8` return `NODEID_E_SIGN`; else `NODEID_OK`. RFC 8032 detached 64-byte signature. Deterministic (no nonce RNG — r is hash-derived).

**`ni_node_id`.** If not inited → `NODEID_E_BAD`; else `ident_copy(&NODEID_NODE_ID, out_id)`; return its status (`NODEID_OK` on success).

**`ni_is_inited`.** Returns `NODEID_INITED` (u8, W10).

**`ni_selftest`.** Returns `99u64` on full pass, else the failing checkpoint number (house idiom). Drives the KAT vectors below.

## KAT Vectors (≥ 3)
Self-test builds a fixed `hw_seed = "HW0"` (3 bytes) and `bootstrap_secret = "BS0"` (3 bytes) so every value is reproducible. All checks are byte-exact.

1. **node_seed correctness (anchors the whole derivation).** `NODEID_NODE_SEED == Keccak256("HW0" ‖ "BS0") == Keccak256("HW0BS0")`. Independently checkable: `keccak256_oneshot("HW0BS0", 6)` must equal `NODEID_NODE_SEED` byte-for-byte. (Self-test recomputes it via the same oneshot and compares all 32 bytes → checkpoint 1/2 on mismatch.)
2. **node_id = Keccak256(identity_pub).** After `ni_init`, `ni_node_id(out)` then `keccak256_oneshot(identity_pub, 32, ref)`; assert `out == ref` (all 32 bytes). Proves node-id binding (checkpoint 3).
3. **Sign→verify round-trip on the identity key.** `ni_identity_sign("abc", 3, sig)`; then (test-only, via the crypto module's own verifier) `ed25519_verify(identity_pub, "abc", 3, sig) == 1u8`. Proves the seed‖pub blob is a valid keypair and the c4 path is wired correctly (checkpoint 4).
4. **Determinism / cross-key distinctness.** Re-run `ni_init` with the *same* args into a second instance is not possible (module-scope singleton), so instead assert the three pubkeys are pairwise **distinct** (identity≠comm, comm≠witness, identity≠witness) — confirms the HKDF info-string separation actually diverged the keys (checkpoint 5). And assert a second `ni_identity_sign("abc",3,sig2)` yields `sig2 == sig` byte-for-byte (signing determinism, checkpoint 6).
5. **Uninitialized guard.** Before any init, `ni_identity_pub(out)` returns `NODEID_E_BAD` and `ni_is_inited()==0u8` (proves the negative case — guards FAIL on bad state, checkpoint 7).

> Crypto reference anchors: `Keccak256("abc")[0]=0x4e, [31]=0x45` and `Keccak256("")[0]=0xc5,[31]=0x70` are the standard vectors already asserted in `keccak256.iii::keccak256_kat` and `identifier.iii::ident_selftest`; node_identity's KATs chain off those proven primitives rather than re-asserting them.

## Trap Exposure
| # | trap | exposed? | avoidance |
|---|---|---|---|
| 1 | multi-line `fn` decl | yes (long sigs) | **every** signature on ONE line, incl. `ni_init_witnessed` and the externs. The gospel's `ni_init(... \n ...)` 2-line form is collapsed. |
| 2 | module-level `const` linker-global | yes | all consts `NODEID_`-prefixed; grep-confirmed zero collisions (incl. vs gospel's `NI_`). |
| 3 | signed-int ordering SIGSEGV | **no** | no `<`/`<=`/`>`/`>=` on any i32/i64; all status compares are `==`/`!=`; loop counters are u64 (u64 ordering is safe). |
| 4 | u32-in-u64-slot garbage | minor | no u32 feeds pointer arithmetic; the only u32 is the `ed25519_keypair_from_seed` return, used solely in `!= 0u32`. The `NodeIdInitArgs` pointer fields are reassembled as full u64 LE (no u32 intermediate). |
| 5 | u32 pointer-store width | **no** | no `*u32` stores; every byte copy is `*u8`. |
| 6 | nested `/* */` | avoid | single-level comments only; no nesting. |
| 7 | local `var` arrays | **yes (gospel violates)** | gospel's `var ctr:[u8;1]`, `var node_seed:[u8;32]`, `var seed_buf:[u8;32]` hoisted to module-scope (`NODEID_CONCAT`, `NODEID_NODE_SEED`, `NODEID_HKDF_SEED`). **Not reentrant** — acceptable: `ni_init` runs once at boot, serialized; signing reuses no scratch. Noted in header. |
| 8 | `} else {` one line | avoid | no else-blocks needed (early-return style); if any appear, single-line. |
| 9 | em-dash in comment | avoid | ASCII `--` only in all comments. |
| 10 | `let mut x=0u32` flag | **no** | `NODEID_INITED` is a module-scope `u8` set once, not a function-local mutated flag; accessors early-return on it. |
| 11 | `a % b` after call | **no** | no modulo anywhere. |
| 12 | `@specialize *T` stride | **no** | module is not generic; all arrays are `[u8;N]`. |

## Gap / Fix List
Every defect in the gospel candidate body, with its fix:

1. **Keccak provider + form wrong (systemic Defect #1).** Gospel: `keccak256_init/update/final from "keccak.iii"`. → **Fix:** those live in `keccak256.iii`, and the streaming form trips the documented param-spill trap (identifier.iii's own header warns of it). Replace *all three* keccak uses (`ni_hkdf_expand`, `ni_init` node-seed) with `keccak256_oneshot` over the contiguous `NODEID_CONCAT` buffer.
2. **`ed25519_keypair_from_seed` return type wrong.** Gospel declared `-> i32`; real is `-> u32` (0=ok, 1=fail). → **Fix:** extern as u32, gate with `!= 0u32` → `NODEID_E_DERIVE`.
3. **`ed25519_sign` signature catastrophically wrong (NEW systemic defect — add to the batch list).** Gospel: `ed25519_sign(msg, msg_len, priv_key, pub_key, out_sig) -> i32`. Real: `ed25519_sign(seed, pk, msg, msg_len, sig_out) -> u8` — **different param order, different count (5), different return type, and the first argument is the 32-byte SEED, not a private key.** The gospel stores a 64-byte `NI_*_PRIV` and passes it as `priv_key`; the real signer would interpret those bytes as a *seed* and silently produce wrong signatures. → **Fix:** store **seed(32)‖pub(32)** per role (`NODEID_*_KEYS`) and sign via the W2-clean `ed25519_sign_c4(keys, msg, msg_len, sig)->u8`, gate `!= 1u8` → `NODEID_E_SIGN`. The 64-byte expanded private key is never stored (the signer re-derives the scalar from the seed).
4. **W2 violation latent in the maximal design.** Real `ed25519_sign` is 5 params; adding M8 cap + M6 witness to a 4-field init would exceed 4. → **Fix:** pass init fields as the `NodeIdInitArgs` aggregate by pointer; sign via `ed25519_sign_c4` (4 params). All public fns ≤4 params; `ni_init_witnessed` = 2.
5. **Trap 7 — function-local `var` arrays (`ctr`, `node_seed`, `seed_buf`).** Unsupported (parse only at module scope) → would fail to compile. → **Fix:** hoist to `NODEID_CONCAT` / `NODEID_NODE_SEED` / `NODEID_HKDF_SEED` module-scope buffers; note non-reentrancy (boot-serialized).
6. **Trap 1 — multi-line `ni_init` signature.** Gospel wrote it across two lines → silent wrong-offset codegen risk. → **Fix:** single-line every signature.
7. **Trap 2 — `NI_*` const prefix unaudited.** → **Fix:** reconcile to dispatched `NODEID_` prefix; grep-confirmed collision-free.
8. **M6 under-realized (Cryptographic Witness Continuity).** Gospel never publishes a witness fragment, yet the module exists to anchor a node's selfhood and even mints a *witness-signing key*. → **Fix:** `ni_init_witnessed` publishes a `NODE_BIRTH` fragment via `wh_publish` (out_commit = node_id, payload = identity pub) → the node's existence is itself witnessed and recomputable (M10).
9. **M8 under-realized (Capability-Mediated Access).** Minting cryptographic identity is privileged but the gospel gates nothing. → **Fix:** `ni_init_witnessed` requires `CAP_RIGHT_ATTEST | CAP_RIGHT_CRYPTO_SIGN` via `cap_verify_rights`; plain `ni_init` is the pre-cap very-early-boot path (documented).
10. **Missing introspection (W12 spirit).** No way to query init state or self-test. → **Fix:** add `ni_is_inited()->u8` and `ni_selftest()->u64`.
11. **`ni_node_id` swallowed `ident_copy` status.** Gospel returned `NI_OK` unconditionally after `ident_copy`. → **Fix:** still return `NODEID_OK` but guard `out_id` null inside the copy (ident_copy already null-checks and returns `IDENT_E_NULL`); propagate by returning `NODEID_E_BAD` if `out_id` is null before the copy.

**Mandate verification of the corrected design:** M1 ✓ (only keccak256+ed25519+identifier+capability+witness_hook, all in-tree). M2/W5 ✓ (pure function of two input blobs; RFC 8032 deterministic). M3/M4 ✓ (no counting/observation/thresholds — straight-line derivation). M5 ✓ (re-derivation from the same seed is always possible; nothing bricks). M6/M10 ✓ (witnessed birth, recomputable). M7 ✓ (R-2 preserved). M8 ✓ (cap gate on the privileged variant). M9 ✓ (birth intentionally non-reversible, capability-gated, justified). M15 ✓ (all algebra total over u8/u64). M19 ✓ (cost bounded: fixed 4 keccak blocks + 3 keypair derivations + ≤1 publish, no unbounded loop). W2/W9/W10/W11/W12/W13/W14/W15 ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/node_identity.iii
 *
 * III STDLIB - aether::node_identity
 *
 * Per-host identity, communication, and witness Ed25519 keys, derived
 * deterministically from a hardware-bound seed combined with the
 * constitutional bootstrap secret.  node_id = Keccak256(identity_pub).
 *
 * Reconciliations vs gospel candidate (see node_identity.spec.md):
 *   - keccak256_oneshot from keccak256.iii (gospel said keccak.iii streaming;
 *     wrong file + param-spill trap).  All hashing is oneshot-over-concat.
 *   - ed25519_keypair_from_seed -> u32 (0=ok); ed25519_sign_c4(keys,msg,len,sig)
 *     -> u8 (keys = seed||pub).  Gospel's ed25519_sign sig was wrong in order,
 *     arity, return type, and passed a 64-byte key where a 32-byte seed is required.
 *   - function-local var arrays hoisted to module scope (Trap 7); init is
 *     boot-serialized, not reentrant.
 *   - M6 witnessed birth + M8 capability gate added (maximal intent).
 *
 * Hexad: kind_essence + kind_witness.  Ring: R-2.  K: 1.00.
 */
module aether_node_identity

extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ed25519_keypair_from_seed(seed_32: *u8, pubkey_32: *u8, privkey_64: *u8) -> u32 from "crypt_ed25519.iii"
extern @abi(c-msvc-x64) fn ed25519_sign_c4(keys: *u8, msg: *u8, msg_len: u64, sig_out: *u8) -> u8 from "crypt_ed25519.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const NODEID_OK         : i32 =  0i32
const NODEID_E_BAD      : i32 = -1i32
const NODEID_E_DENIED   : i32 = -2i32
const NODEID_E_SIGN     : i32 = -3i32
const NODEID_E_DERIVE   : i32 = -4i32

const NODEID_KEY_BYTES   : u64 = 32u64
const NODEID_SIG_BYTES   : u64 = 64u64
const NODEID_KEYS_BYTES  : u64 = 64u64
const NODEID_MAX_INPUT   : u64 = 8191u64

const NODEID_RIGHT_ATTEST : u64 = 0x0800u64
const NODEID_RIGHT_SIGN   : u64 = 0x1000u64

const NODEID_INFO_ID_LEN   : u64 = 19u64
const NODEID_INFO_COMM_LEN : u64 = 24u64
const NODEID_INFO_WIT_LEN  : u64 = 18u64
const NODEID_PRODUCER_LEN  : u64 = 21u64
const NODEID_OPID_LEN      : u64 = 28u64

var NODEID_ID_KEYS    : [u8; 64]     /* identity:      seed(32) || pub(32) */
var NODEID_COMM_KEYS  : [u8; 64]     /* communication: seed(32) || pub(32) */
var NODEID_WIT_KEYS   : [u8; 64]     /* witness:       seed(32) || pub(32) */
var NODEID_NODE_ID    : [u8; 32]     /* Keccak256(identity_pub)            */
var NODEID_NODE_SEED  : [u8; 32]     /* HKDF PRK = Keccak256(hw||bootstrap) */
var NODEID_HKDF_SEED  : [u8; 32]     /* per-role HKDF-Expand T(1) output    */
var NODEID_PRIV_SCRAP : [u8; 64]     /* discarded expanded priv from keypair gen */
var NODEID_CONCAT     : [u8; 8224]   /* oneshot concat scratch (PRK||info||ctr / hw||bootstrap) */
var NODEID_PRODUCER   : [u8; 32]     /* ident_from_bytes("aether::node_identity") */
var NODEID_OPID_BIRTH : [u8; 32]     /* ident_from_bytes("aether::node_identity::birth") */
var NODEID_INITED     : u8 = 0u8

/* HKDF-Expand single block: out = Keccak256(NODEID_NODE_SEED || info || 0x01). */
fn ni_hkdf_expand(info: *u8, info_len: u64, out: *u8) -> i32 {
    // TODO: body per Algorithm (ni_hkdf_expand): build NODEID_CONCAT = NODE_SEED(32)||info||0x01; keccak256_oneshot(.., 33+info_len, out)
    return NODEID_OK
}

/* Read a u64 field from the NodeIdInitArgs aggregate at byte offset off. */
fn ni_args_u64(args: *u8, off: u64) -> u64 {
    // TODO: body per Algorithm: assemble 8 LE bytes args[off..off+8) into a u64 (avoids u32-in-u64 trap)
    return 0u64
}

/* Core derivation shared by both init entries; cap_id = 0 (CAP_INVALID) skips the gate. */
fn ni_derive(args: *u8, cap_id: u64, do_witness: u8) -> i32 {
    // TODO: body per Algorithm (ni_init steps 1-9):
    //   if cap_id != 0u64 { if cap_verify_rights(cap_id, NODEID_RIGHT_ATTEST | NODEID_RIGHT_SIGN) != 1u8 { return NODEID_E_DENIED } }
    //   read hw_seed/hw_seed_len/bootstrap/bs_len via ni_args_u64; bound-check sum <= NODEID_MAX_INPUT
    //   NODEID_CONCAT = hw||bootstrap; keccak256_oneshot -> NODEID_NODE_SEED
    //   3 roles: ni_hkdf_expand(info,len,&NODEID_HKDF_SEED); copy seed into KEYS[0..32);
    //            ed25519_keypair_from_seed(&NODEID_HKDF_SEED, &KEYS[32], &NODEID_PRIV_SCRAP) gate != 0u32 -> E_DERIVE
    //   ident_from_bytes(&NODEID_ID_KEYS[32], 32, &NODEID_NODE_ID)
    //   NODEID_INITED = 1u8
    //   if do_witness == 1u8 { wh_chain_root(in_commit); wh_publish(PRODUCER,OPID_BIRTH,in,NODE_ID,0,0,0, 0,0, idpub,32, 0) }
    return NODEID_OK
}

fn ni_init(args: *u8) -> i32 @export {
    // TODO: body per Algorithm: ensure producer/opid ids built once; return ni_derive(args, 0u64, 0u8)
    return NODEID_OK
}

fn ni_init_witnessed(args: *u8, cap_id: u64) -> i32 @export {
    // TODO: body per Algorithm: ensure producer/opid ids built; return ni_derive(args, cap_id, 1u8)
    return NODEID_OK
}

fn ni_identity_pub(out_pub: *u8) -> i32 @export {
    // TODO: body per Algorithm: if NODEID_INITED == 0u8 { return NODEID_E_BAD }; copy NODEID_ID_KEYS[32..64) -> out_pub
    return NODEID_OK
}

fn ni_communication_pub(out_pub: *u8) -> i32 @export {
    // TODO: body per Algorithm: guard inited; copy NODEID_COMM_KEYS[32..64) -> out_pub
    return NODEID_OK
}

fn ni_witness_pub(out_pub: *u8) -> i32 @export {
    // TODO: body per Algorithm: guard inited; copy NODEID_WIT_KEYS[32..64) -> out_pub
    return NODEID_OK
}

fn ni_identity_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 @export {
    // TODO: body per Algorithm: guard inited; if ed25519_sign_c4(&NODEID_ID_KEYS[0], msg, msg_len, out_sig) != 1u8 { return NODEID_E_SIGN }; return NODEID_OK
    return NODEID_OK
}

fn ni_communication_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 @export {
    // TODO: body per Algorithm: guard inited; ed25519_sign_c4(&NODEID_COMM_KEYS[0], ..) gate != 1u8
    return NODEID_OK
}

fn ni_witness_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 @export {
    // TODO: body per Algorithm: guard inited; ed25519_sign_c4(&NODEID_WIT_KEYS[0], ..) gate != 1u8
    return NODEID_OK
}

fn ni_node_id(out_id: *u8) -> i32 @export {
    // TODO: body per Algorithm: if NODEID_INITED == 0u8 { return NODEID_E_BAD }; if (out_id as u64) == 0u64 { return NODEID_E_BAD }; ident_copy(&NODEID_NODE_ID[0], out_id); return NODEID_OK
    return NODEID_OK
}

fn ni_is_inited() -> u8 @export {
    // TODO: body per Algorithm: return NODEID_INITED
    return 0u8
}

/* Self-test. 99 = pass; otherwise the failing checkpoint number. */
fn ni_selftest() -> u64 @export {
    // TODO: body per KAT Vectors 1-5
    return 99u64
}
```
