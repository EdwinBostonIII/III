# 11 numera/proof_carrying.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically sound and nearly complete (Merkle vector commitments, Horner/`gfp` polynomial evaluation, inclusion proofs, certificate composition all present and deterministic), but it is **not paste-ready**: it commits **Trap 7** in every function (function-local `var [u8;N]` arrays — illegal, parse only at module scope), declares an `extern` **inside a function body** (`bigint_copy` in `pc_eval_poly`), carries three **dead `keccak.iii` externs** the body never calls (and which name the wrong file — the real wrappers live in `keccak256.iii`), uses the `PC_` prefix instead of the assigned `PROOFC_`, and is **missing the polynomial opening/verification proofs** (`pc_open_poly` / `pc_verify_poly`) that the prose intro explicitly promises ("Opening at a point `z` is provided by Lagrange interpolation … followed by an inclusion proof"). The maximal intent of the prose is a full polynomial-commitment opening scheme; the candidate stops at evaluation. Spec below closes every gap.

## Purpose
`numera::proof_carrying` is the substrate's **vector- and polynomial-commitment carrier**: it binds a sequence of 32-byte field elements (or a polynomial's coefficient vector) to a single 32-byte Merkle root, emits logarithmic-size inclusion proofs (Merkle paths), verifies them in deterministic `O(log n)` time, evaluates committed polynomials at a point by Horner's method over `GF(p)`, **opens** a committed polynomial at a point (committed evaluation + inclusion proof), and composes/verifies proof certificates that additionally bind a producer identifier and the live witness chain root. It is the operational embodiment of **M11 Curry-Howard** (a proof term is a checkable program: path + binding) and **M12 Synthesis Verifiability** (every committed artifact carries a byte-recomputable certificate). Hexad: **kind_witness**. Ring: **R0**. K-vector: **0.99**.

## Public API
All signatures SINGLE-LINE (Trap 1). W9: error codes negative `i32`. W10: boolean returns `u8` (0/1). W12: every public fn returns a status or a sentinel-typed value (`u64` bigint id, sentinel `0`).

```
fn pc_commit_vec(items: *u8, n: u64, out_root: *u8) -> i32 @export
fn pc_open_vec(items: *u8, n: u64, idx: u64, out_path: *u8, out_path_len: *u64) -> i32 @export
fn pc_verify_vec(root: *u8, leaf: *u8, idx: u64, n: u64, path: *u8, path_len: u64) -> u8 @export
fn pc_commit_poly(coeffs: u64, n_coeffs: u64, p: u64, out_root: *u8) -> i32 @export
fn pc_eval_poly(arena: u64, coeffs: u64, n_coeffs: u64, z: u64, p: u64) -> u64 @export
fn pc_open_poly(arena: u64, coeffs: u64, n_coeffs: u64, z: u64, p: u64, out_eval: *u8, out_path: *u8, out_path_len: *u64) -> i32 @export
fn pc_verify_poly(root: *u8, z_leaf: *u8, idx: u64, n_coeffs: u64, path: *u8, path_len: u64) -> u8 @export
fn pc_coeff_leaf(arena: u64, bid: u64, out_leaf: *u8) -> i32 @export
fn pc_attach_proof(payload: *u8, payload_len: u64, producer: *u8, out_certificate: *u8) -> i32 @export
fn pc_verify_proof(payload: *u8, payload_len: u64, certificate: *u8) -> u8 @export
fn pc_cert_producer(certificate: *u8, out_producer: *u8) -> i32 @export
fn pc_cert_chain_root(certificate: *u8, out_root: *u8) -> i32 @export
fn pc_selftest() -> u64 @export
```

Return conventions:
- `pc_commit_vec / pc_open_vec / pc_commit_poly / pc_open_poly / pc_attach_proof / pc_coeff_leaf / pc_cert_producer / pc_cert_chain_root` → `i32`: `PROOFC_OK` (0) or a negative error.
- `pc_verify_vec / pc_verify_poly / pc_verify_proof` → `u8`: `1` valid, `0` invalid (W10).
- `pc_eval_poly` → `u64`: a bigint id (sentinel `0` = `PROOFC_INVALID`, caller drops on success).
- `pc_selftest` → `u64`: `0` = all KATs pass; non-zero = failing-KAT bitmask.

`pc_open_poly` requires `W2` relief: it is a 9-field operation. **Per W2, parameters beyond 4 are passed via an aggregate.** This spec packs the four scalars `(coeffs, n_coeffs, z, p)` plus `arena` and the three out-pointers — 8 logical args — through a single module-scope **request block** `PROOFC_OPEN_REQ` (see Data Structures); the public signature exposes only `(arena, *req)` to honor W2. The expanded form above is the *logical* contract; the *physical* signature is:

```
fn pc_open_poly(arena: u64, req: *u8) -> i32 @export
```

where `req` points to a `PROOFC_OpenReq` byte layout (documented in Data Structures). Same technique used by `keccak.iii::keccak_absorb` (4-arg pack) — Trap-free and W2-compliant.

## Constant Namespace
PREFIX = `PROOFC_`  (grep of `STDLIB/` confirms **no collision**: no `PROOFC_` symbol exists anywhere in the tree, and no existing module named `numera_proof_carrying`). The gospel candidate used `PC_`; that is **changed to `PROOFC_`** here per dispatch. (`PC_` would also not collide today, but the assigned prefix is mandatory.)

```
const PROOFC_OK         : i32 =  0i32
const PROOFC_E_BAD_LEN  : i32 = -1i32
const PROOFC_E_BAD_IDX  : i32 = -2i32
const PROOFC_E_OOM      : i32 = -3i32
const PROOFC_E_NULL     : i32 = -4i32
const PROOFC_E_TOO_BIG  : i32 = -5i32     /* n or n_coeffs exceeds PROOFC_MAX_LEAVES */
const PROOFC_INVALID    : u64 = 0u64       /* sentinel bigint id (matches bigint.iii BIGINT_INVALID) */
const PROOFC_LEAF_BYTES : u64 = 32u64
const PROOFC_MAX_LEAVES : u64 = 1024u64    /* layer/leaf buffers sized 1024 * 32 = 32768 (W8) */
const PROOFC_MAX_LIMBS  : u64 = 128u64     /* coeff limb scratch 128 * 8 = 1024 bytes (W8) */
const PROOFC_CERT_BYTES : u64 = 96u64      /* payload_hash(32) || producer(32) || chain_root(32) */
const PROOFC_REQ_BYTES  : u64 = 64u64      /* OpenReq layout, see Data Structures */
```

Every constant is single-typed (Trap 2: prefix prevents linker-global collisions with other modules' `OK` / `MAX` / `INVALID`).

## Data Structures
All scratch is **module-scope** (Trap 7: function-local `var [u8;N]` arrays are illegal). Each is uniquely `PROOFC_`-prefixed. **Not reentrant** — acceptable: every public fn runs serialized hashing (the same discipline keccak.iii and identifier.iii rely on; flagged here explicitly).

| Name | Type | Size (bytes) | Bound justification (W8) |
|------|------|--------------|--------------------------|
| `PROOFC_LAYER` | `[u8; 32768]` | 32768 | `PROOFC_MAX_LEAVES` (1024) × 32. Holds the current Merkle layer during commit/open; collapses in place. Matches the candidate's `layer_buf`. |
| `PROOFC_LEAVES` | `[u8; 32768]` | 32768 | 1024 coefficient leaves × 32, for `pc_commit_poly` / `pc_open_poly`. Separate from `PROOFC_LAYER` because poly commit hashes into leaves, then the *vector* path reuses `PROOFC_LAYER`. |
| `PROOFC_LIMB` | `[u8; 1024]` | 1024 | `PROOFC_MAX_LIMBS` (128) limbs × 8 bytes. Canonical LE limb serialization of one coefficient bigint before hashing to a leaf. Matches candidate `lim_buf`. |
| `PROOFC_CUR` | `[u8; 32]` | 32 | Single running node in `pc_verify_vec` / `pc_verify_poly`. Replaces candidate local `cur_buf`. |
| `PROOFC_NXT` | `[u8; 32]` | 32 | Single next node in verify loop. Replaces candidate **in-loop** `nxt` (the worst Trap-7 site). |
| `PROOFC_HBUF` | `[u8; 32]` | 32 | Payload-hash recompute scratch in `pc_verify_proof`. Replaces candidate `h_buf`. |
| `PROOFC_REQ_SCRATCH` | `[u8; 64]` | 64 | Decoded `OpenReq` mirror if a caller passes a packed block; also the self-test's request builder. |

`PROOFC_OpenReq` byte layout (the `req: *u8` argument to `pc_open_poly`), all little-endian:
```
[0..8]   coeffs        (u64 : bigint-id-array pointer cast to u64)
[8..16]  n_coeffs      (u64)
[16..24] z             (u64)
[24..32] p             (u64)
[32..40] out_eval      (u64 : *u8, 32-byte committed evaluation leaf)
[40..48] out_path      (u64 : *u8)
[48..56] out_path_len  (u64 : *u64)
[56..64] reserved      (u64, must be 0)
```
No global pointer escape (W1/W3): `&PROOFC_*` is taken **only inside this file**. No module-scope arena (W6/W7): the only arena is the caller-supplied `arena: u64` parameter, threaded to bigint/gfp; its lifecycle is the caller's.

## Dependencies (externs)
All at **module scope** (the candidate's inline `extern bigint_copy` inside `pc_eval_poly` is **hoisted out** — Fix list). `from "X.iii"` is a basename reference resolved by the linker regardless of subdirectory.

```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_encode_pair(a: *u8, b: *u8, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn bigint_from_u64(arena: u64, v: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_copy(arena: u64, src: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_drop(id: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_get_limb(id: u64, i: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_len_limbs(id: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn gfp_mul(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_add(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
```

Provider status:
| Extern | Module NN | Built? |
|--------|-----------|--------|
| `ident_*` | Module 01 `numera/identifier.iii` | **BUILT** (verified: `ident_from_bytes` = Keccak256(input); `ident_encode_pair` = Keccak256(a‖b)) |
| `wh_chain_root` | Module 07 `aether/witness_hook.iii` | **BUILT** (verified exact sig `wh_chain_root(out_id: *u8) -> i32`) |
| `bigint_*` | Module 02 `numera/bigint.iii` | **BUILT** (all six verified, incl. `bigint_copy(arena, src) -> u64`) |
| `gfp_mul`, `gfp_add` | **Module 04 `numera/galois.iii`** | **NOT-YET-BUILT** — gospel defines it (Layer 1, Module 04) with exact matching signatures `gfp_mul/gfp_add(arena,a,b,p) -> u64`, but no `galois.iii` exists in `STDLIB/iii/numera/`. **Wave scheduler MUST order galois.iii before this module.** Note: `numera/field.iii` exists with same-shape `fp_mul/fp_add`; if galois.iii slips, Phase 2 may substitute `field.iii` `fp_*` (rename externs), but the gospel-canonical name is `gfp_*`. |

**REMOVED externs (Fix list):** the candidate's `keccak256_init`, `keccak256_update`, `keccak256_final` `from "keccak.iii"` are **dead** (never called in the body — hashing goes through `ident_from_bytes` / `ident_encode_pair`) **and mis-named** (the real wrappers are in `numera/keccak256.iii`, module `numera_keccak256`, not `keccak.iii`). They are deleted. No `category.iii` extern: vector/polynomial commitments do not consume the category API, so the dispatch's "depends on category.iii (Module 09)" note does **not** manifest as an extern here — flagged as informational, no action.

## Algorithm
All hashing is Keccak256 (via `identifier.iii`), which is total + deterministic, so **M2 / W5 bit-identity** holds: identical leaf bytes ⇒ identical root, cross-run, cross-CPU. No ML/heuristics (**M3/M4**): tree shape and node ordering are fixed algebraic rules. **No recursion (W15)**: every tree walk is an explicit in-place layer-collapse loop over the module-scope `PROOFC_LAYER` array (an explicit stack/scratch, not the call stack). **No `break` (W14)**: all loops are sentinel/counter driven (`while count > 1u64`, `while i < n`, etc.).

**`pc_commit_vec(items, n, out_root)`** — Merkle root over `n` 32-byte leaves.
1. Guard `n > PROOFC_MAX_LEAVES` → `PROOFC_E_TOO_BIG`; guard null `items`/`out_root` → `PROOFC_E_NULL`.
2. `n == 0` → write 32 zero bytes to `out_root`, return `PROOFC_OK` (empty-vector canonical root = 0^32).
3. Layer 0: for `i in 0..n`, `ident_from_bytes(items + i*32, 32, PROOFC_LAYER + i*32)` (leaf = Keccak256(leaf-bytes)).
4. Collapse: `while count > 1`: `half = (count+1)/2`; for `j in 0..half`: `l=2j`, `r=l+1`; if `r<count` pair-hash `(l,r)` **commutatively** (compare via `ident_cmp`; smaller-first; `c==1` ⇒ `encode_pair(r,l)`, else `encode_pair(l,r)`) into `PROOFC_LAYER+j*32`; if `r>=count` (odd tail) `encode_pair(l,l)` (duplicate). `count = half`.
5. `ident_copy(PROOFC_LAYER, out_root)`. Determinism: commutative ordering removes left/right ambiguity so the root is independent of any incidental swap — a single canonical value per multiset-ordered vector.

**`pc_open_vec(items, n, idx, out_path, out_path_len)`** — inclusion proof.
1. `idx >= n` → `PROOFC_E_BAD_IDX`; size/null guards as above.
2. Build layer 0 as in commit.
3. `while count > 1`: `sib = cur_idx XOR 1`; if `sib < count` copy `PROOFC_LAYER+sib*32` into `out_path + path_len*32`, else copy self (`cur_idx`, the duplicated odd leaf); `path_len += 1`; collapse one layer in place (same commutative rule); `count = half`; `cur_idx = cur_idx / 2`.
4. `*out_path_len = path_len` (= ceil(log2 n)). Determinism: sibling selection is `idx XOR 1` — pure bit algebra, no data-dependent branching beyond bounds.

**`pc_verify_vec(root, leaf, idx, n, path, path_len)`** — verify path.
1. `idx >= n` → `0u8`.
2. `ident_from_bytes(leaf, 32, PROOFC_CUR)`.
3. `while i < path_len`: read sibling `path + i*32`; **commutatively** combine `PROOFC_CUR` and sibling into `PROOFC_NXT` (`ident_cmp` smaller-first — must match commit's rule exactly); `ident_copy(PROOFC_NXT, PROOFC_CUR)`; `i += 1`.
4. Return `ident_eq(PROOFC_CUR, root)`. **M10 / M18**: an OK verdict is byte-recomputable from `(leaf, idx, path)` alone. **Note**: `idx` is *not* consumed in the fold because the commutative ordering makes direction irrelevant — this is correct and matches the candidate; `n`/`idx` only bound-check.

**`pc_coeff_leaf(arena, bid, out_leaf)`** *(new helper, extracted from candidate's inlined poly-leaf logic)* — canonical leaf of one coefficient.
1. `limbs = bigint_len_limbs(bid)`; guard `limbs > PROOFC_MAX_LIMBS` → `PROOFC_E_TOO_BIG`.
2. For `k in 0..limbs`: `lv = bigint_get_limb(bid,k)`; serialize LE **byte-by-byte** into `PROOFC_LIMB + k*8` (8 explicit `& 0xFFu64` byte stores — Trap 5).
3. `ident_from_bytes(PROOFC_LIMB, limbs*8, out_leaf)`. Canonical: little-endian limb order with normalized (high-limb-nonzero) bigints ⇒ one leaf per field value (M14 provenance: the leaf is a pure function of the value).

**`pc_commit_poly(coeffs, n_coeffs, p, out_root)`** — commit a polynomial = Merkle root of its coefficient leaves.
1. Size/null guards. `cp = coeffs as *u64` (array of bigint ids).
2. For `i in 0..n_coeffs`: `pc_coeff_leaf(/* arena implied 0 — see note */ , cp[i], PROOFC_LEAVES + i*32)`. *(Leaf hashing needs no arena; `pc_coeff_leaf` takes `arena` only for signature symmetry and ignores it — or drop the param; spec keeps it for a uniform helper and passes `0u64`.)*
3. `return pc_commit_vec(PROOFC_LEAVES, n_coeffs, out_root)`. `p` is accepted for API symmetry with `pc_eval_poly`/`pc_open_poly` (coefficients are assumed already reduced mod `p`; committing does not re-reduce — flagged: if the maximal contract requires reduction, Phase 2 reduces each `cp[i]` via `gfp_add(arena, cp[i], zero, p)` first, which needs `arena` ≠ 0 — see Gap list).

**`pc_eval_poly(arena, coeffs, n_coeffs, z, p)`** — Horner evaluation over GF(p), returns bigint id.
1. `n_coeffs == 0` → `bigint_from_u64(arena, 0)`.
2. `acc = bigint_copy(arena, cp[n_coeffs-1])` (own a mutable copy of the top coefficient).
3. `i = n_coeffs - 1`; `while i > 0`: `i -= 1`; `mul_res = gfp_mul(arena, acc, z, p)`; `bigint_drop(acc)`; `add_res = gfp_add(arena, mul_res, cp[i], p)`; `bigint_drop(mul_res)`; `acc = add_res`.
4. Return `acc`. **No modulo-after-call (Trap 11)**: all reduction is inside `gfp_mul`/`gfp_add`; this module performs no `%` operator at all. **No signed ordering compare (Trap 3)**: the loop tests `i > 0u64` on an **unsigned** `u64` — *safe* (Trap 3 is signed-only); the descending counter uses `while i > 0u64 { i -= 1; … }` which is the W14 sentinel form and avoids any `i >= 0i64` underflow trap.

**`pc_open_poly(arena, req)`** *(req → OpenReq layout)* — commit-evaluation opening at `z`.
1. Decode `req`: `coeffs, n_coeffs, z, p, out_eval, out_path, out_path_len` (LE u64 loads from `req`); guard `reserved == 0`.
2. `ev_id = pc_eval_poly(arena, coeffs, n_coeffs, z, p)`; if `ev_id == PROOFC_INVALID` → `PROOFC_E_OOM`.
3. `pc_coeff_leaf(arena, ev_id, out_eval)` — the committed evaluation leaf = Keccak256(LE-limbs of f(z)).
4. **Opening proof = inclusion proof of the evaluation in the *augmented* leaf vector.** Maximal-intent realization of the prose ("inclusion proof of the evaluation point's commitment"): the committed vector is `[coeff_leaf(0..n_coeffs-1)]`; the opening binds `f(z)` by (a) recomputing `f(z)` deterministically (step 2) and (b) producing the **Merkle path of coefficient leaf at canonical index `idx_z`**, where `idx_z` is the Reed–Solomon evaluation-domain index of `z` if `z` is a domain point, else the appended position. For the canonical RS domain `idx_z` is supplied by the caller in `reserved`-adjacent space (Phase 2 extends OpenReq with `idx_z` if domain mapping is required); for the **coefficient-vector commitment** (the candidate's actual scheme) the opening returns the path of the leaf the verifier will recompute from `out_eval`. `pc_open_vec(PROOFC_LEAVES-rebuilt, n_coeffs, idx_z, out_path, out_path_len)`.
5. `bigint_drop(ev_id)`; return `PROOFC_OK`. (Determinism: Horner + Keccak + fixed path = byte-identical opening for fixed inputs.)

**`pc_verify_poly(root, z_leaf, idx, n_coeffs, path, path_len)`** — verify a polynomial opening: identical to `pc_verify_vec(root, z_leaf, idx, n_coeffs, path, path_len)` where `z_leaf` is the committed evaluation leaf the prover sent (the verifier independently recomputes `z_leaf = pc_coeff_leaf(f(z))` if it holds `f(z)`, or trusts the supplied leaf and checks only inclusion). Returns `u8`.

**`pc_attach_proof(payload, payload_len, producer, out_certificate)`** — compose 96-byte certificate.
1. Null guards. `out[0..32] = ident_from_bytes(payload, payload_len)` (payload hash).
2. `ident_copy(producer, out+32)` (producer binding — **M8 capability/identity binding**).
3. `wh_chain_root(out+64)` (live witness chain root at attach time — **M6 witness continuity**: the certificate is anchored into the hash chain).
4. Return `PROOFC_OK`. (Layout exactly matches candidate; documented in Data Structures.)

**`pc_verify_proof(payload, payload_len, certificate)`** — recompute and compare.
1. `ident_from_bytes(payload, payload_len, PROOFC_HBUF)`.
2. Return `ident_eq(PROOFC_HBUF, certificate)` (compares against `certificate[0..32]`). **M10**: verdict recomputable from `(payload, certificate)` alone.

**`pc_cert_producer` / `pc_cert_chain_root`** *(new accessors)* — copy `certificate[32..64]` / `certificate[64..96]` out (null-guarded `ident_copy`); enable a verifier to check producer identity and chain anchoring without re-parsing offsets.

**`pc_selftest()`** — runs the KAT vectors below in-process, returns 0 on full pass (drives Phase-2 acceptance).

## KAT Vectors (>= 3)
Hash primitive is Keccak256 (FIPS 202). All vectors are byte-checkable by `pc_selftest`.

1. **Single-leaf commit = leaf hash.** `items = L` (32 bytes, `L = 0x00..00`), `n = 1`. Expected `out_root = Keccak256(L)`. With `L = 32×0x00`: `Keccak256(0^32) = 290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563`. Verifies layer-0 hashing and the `count==1` early stop.

2. **Empty vector.** `n = 0`. Expected `out_root = 0x00…00` (32 zero bytes). Edge-case sentinel for `pc_commit_vec`.

3. **Two-leaf commit + open + verify round-trip.** `items = [A, B]`, `A = Keccak256("a")`, `B = Keccak256("b")` (or any distinct 32-byte values), `n = 2`.
   - `pc_commit_vec` → `root = ident_encode_pair(min(H(A),H(B)), max(...))` where `H(x)=Keccak256(x)` (commutative order by `ident_cmp`).
   - `pc_open_vec(items, 2, 0, path, &plen)` → `plen = 1`, `path[0..32] = H(B)`.
   - `pc_verify_vec(root, A, 0, 2, path, 1)` → `1u8`. **Negative:** `pc_verify_vec(root, A, 0, 2, path_with_one_byte_flipped, 1)` → `0u8` (proves the gate FAILS on a corrupted path, not merely passes — per the "prove the negative" discipline).

4. **Odd-leaf (3) commit + open + verify.** `items = [A,B,C]`, `n = 3`. Verify the odd-tail duplication (`encode_pair(C,C)`) and that `pc_open_vec(…,2,…)` + `pc_verify_vec` round-trips for the duplicated leaf. **Negative:** verify with `idx = 3` (out of range) → `0u8`.

5. **Horner evaluation over GF(p).** `p = 97` (`bigint_from_u64`), `coeffs = [c0=5, c1=3, c2=2]` (i.e. `2z^2 + 3z + 5`), `z = 4`. Expected `f(4) = 2*16 + 3*4 + 5 = 49`, `49 mod 97 = 49`. `pc_eval_poly(arena, coeffs, 3, 4, 97)` → bigint id whose value (single limb) `== 49`. **Negative / wrap:** `z = 10` → `2*100+3*10+5 = 235`, `235 mod 97 = 41`; assert `== 41` (proves modular reduction actually fires, not pass-through).

6. **Certificate attach + verify.** `payload = "III"` (3 bytes), `producer = 0x11×32`. `pc_attach_proof` → `cert[0..32] = Keccak256("III")`, `cert[32..64] = producer`, `cert[64..96] = wh_chain_root`. `pc_verify_proof("III", 3, cert)` → `1u8`. **Negative:** `pc_verify_proof("II", 2, cert)` → `0u8`. `pc_cert_producer(cert, out)` → `out == producer`.

(KAT 1's `Keccak256(0^32)` digest is the standard empty-state-of-32-zeros value; Phase 2 confirms against the live `keccak256.iii` `keccak256_oneshot` output to lock byte-identity.)

## Trap Exposure
| Trap | Exposed? | Avoidance |
|------|----------|-----------|
| 1 Multi-line `fn` | YES (13 fns) | **Every** signature in this spec is single-line; skeleton below is single-line. The candidate's `pc_open_vec` / `pc_commit_poly` / `pc_eval_poly` signatures wrap across lines in the gospel — **must be flattened** (Fix list). |
| 2 Module-`const` linker-global | YES | All consts `PROOFC_`-prefixed; grep confirms no collision. |
| 3 Signed ordering SIGSEGV | NO | No signed `i32`/`i64` ordering compares anywhere. All loop counters are `u64` with `>` / `<` (unsigned, safe) or sentinel `> 0u64`. Error codes compared by `==`/`!=` only (W11) — e.g. `ident_cmp` result tested `c == 1i32` / `c != 1i32`, never `c < 0`. |
| 4 u32-in-u64-slot garbage | NO | This module uses `u64` for all indices/pointers; the only `u32` is `ident_cmp`'s `i32` result, never used in pointer math. Pointer arithmetic uses `(base as u64 + i*32u64) as *u8` with `u64` `i`. |
| 5 u32 pointer-store width | YES (`pc_coeff_leaf`) | Limb serialization stores **byte-by-byte through `*u8`** with explicit `(lv >> k*8) & 0xFFu64` extraction (matches candidate `pc_commit_poly` limb loop — preserved exactly). No `*u32` stores. |
| 6 Nested `/* */` | NO | Comments are single-level; no nesting. |
| 7 Local `var [N]` arrays | **YES — primary defect** | Candidate declares `layer_buf`, `cur_buf`, `nxt` (in-loop!), `leaves_buf`, `lim_buf`, `h_buf` as **function-local** `var` arrays — **illegal**. **All hoisted to module scope** as `PROOFC_LAYER / PROOFC_CUR / PROOFC_NXT / PROOFC_LEAVES / PROOFC_LIMB / PROOFC_HBUF` (see Data Structures). Non-reentrancy noted and accepted (serialized hashing). |
| 8 `} else {` one line | LOW | Skeleton uses the `if c == 1i32 {…}` / `if c != 1i32 {…}` paired-guard idiom (the exemplar's house style) — **no `else` at all** in the hot paths; any `else` introduced in Phase 2 must be `} else {` on one line. |
| 9 Em-dash in comment | NO | All comments use ASCII `--`; no U+2014 anywhere in the skeleton. |
| 10 `let mut flag` checkpoint | LOW | No checkpoint-flag pattern; `ident_cmp` (the one place a flag could appear) already uses the early-`sentinel` form in the dependency, not here. |
| 11 `%` after call | NO | **Zero `%` operators.** All modular reduction delegated to `gfp_mul`/`gfp_add`. (The candidate's `(count+1)/2` is integer division by a literal, not modulo, and not after a spill-prone call — safe.) |
| 12 `@specialize *T` stride | NO | No generics; all element widths are concrete (32-byte leaves, 8-byte limbs/ids) with explicit `*32u64` / `*8u64` strides. |

## Gap / Fix List
Verdict PARTIAL — the following must be closed by Phase 2:

1. **Trap 7 (blocking, all fns).** Move every function-local `var [u8;N]` to module scope (`PROOFC_LAYER`, `PROOFC_LEAVES`, `PROOFC_LIMB`, `PROOFC_CUR`, `PROOFC_NXT`, `PROOFC_HBUF`). The in-loop `var nxt : [u8;32]` inside `pc_verify_vec` is the most dangerous (declared per-iteration). **Fix:** as specified in Data Structures.
2. **Trap 1 (blocking).** Flatten the multi-line signatures of `pc_open_vec`, `pc_commit_poly` (single-line already but verify), `pc_eval_poly`, `pc_attach_proof`, `pc_verify_proof` to one line each. **Fix:** single-line forms in Public API / Skeleton.
3. **Inline extern (blocking, style + possible codegen).** `pc_eval_poly` declares `extern … fn bigint_copy … from "bigint.iii"` **inside the function body** (gospel line 3007). Hoist to module scope. **Fix:** in Dependencies block above.
4. **Dead + mis-pathed externs.** Remove `keccak256_init/update/final from "keccak.iii"` (never called; wrong file — real module is `numera/keccak256.iii`). **Fix:** deleted from extern list.
5. **Prefix.** Rename all `PC_*` consts to `PROOFC_*` per dispatch. **Fix:** Constant Namespace.
6. **Missing maximal API (M11/M12 completeness).** The prose promises polynomial **opening** ("Lagrange interpolation … followed by an inclusion proof of the evaluation point's commitment") and a matching **verify**; the candidate ships only `pc_eval_poly`. **Fix:** add `pc_open_poly` (+ `OpenReq` block, W2-compliant) and `pc_verify_poly`, plus the `pc_coeff_leaf` helper extracted from `pc_commit_poly`'s inline limb loop, and `pc_cert_producer`/`pc_cert_chain_root` accessors so the certificate's producer/chain-root bindings are actually consumable (otherwise `pc_attach_proof` writes fields nothing reads — M12 incompleteness).
7. **Coefficient reduction ambiguity.** `pc_commit_poly` commits coefficients **without** reducing mod `p`; if two representations of the same residue are committed, roots differ (M2 risk only if callers pass unreduced coeffs). **Fix (maximal):** Phase 2 reduces each coefficient via `gfp_add(arena, cp[i], bigint_from_u64(arena,0), p)` before hashing — but this requires `pc_commit_poly` to receive a usable `arena` (currently it has `p` but threads no arena to a reducer). Spec keeps `arena`-free commit as the default (assumes pre-reduced, the candidate's contract) and documents the reducing variant as the maximal option; Phase 2 chooses per the KAT (KAT 5 uses already-reduced coeffs, so default suffices for acceptance).
8. **Not-yet-built dependency `galois.iii` (scheduling).** `gfp_mul`/`gfp_add` come from Module 04 `numera/galois.iii`, which the gospel specifies but which is **absent from `STDLIB/`**. The wave scheduler must build galois.iii (Layer 1) before this module (Layer 3). Fallback documented: `numera/field.iii` `fp_mul/fp_add` (present) are signature-compatible substitutes if galois slips.
9. **Bounds hardening (M5 no-bricking / W8).** Candidate's `layer_buf` is sized 32768 (1024 leaves) but **never guards `n <= 1024`** — `n = 2000` overflows `PROOFC_LAYER` → memory corruption. **Fix:** `pc_commit_vec`/`pc_open_vec`/`pc_commit_poly` all guard `n > PROOFC_MAX_LEAVES` → `PROOFC_E_TOO_BIG`; `pc_coeff_leaf` guards `limbs > PROOFC_MAX_LIMBS`. This is a genuine safety gap in the candidate, not cosmetic.
10. **Null guards (W12/M5).** Candidate omits null-pointer checks on `items`/`out_root`/`leaf`/`producer`. **Fix:** add `(p as u64) == 0u64 → PROOFC_E_NULL` (or `0u8` for verifiers) at each public entry, matching identifier.iii/keccak.iii house style.
11. **Self-test (acceptance gate).** Candidate has no `pc_selftest`; the dependency modules (`identifier.iii`, `keccak.iii`) all expose one. **Fix:** add `pc_selftest()` running KATs 1–6, returning a failing-bit mask.

Mandate cross-check (post-fix): M1 NIH ✓ (only libc-free III deps), M2/W5 ✓ (Keccak determinism), M3/M4 ✓ (no learning/heuristics), M5 ✓ (bounds + null guards added), M6 ✓ (`wh_chain_root` anchor), M8 ✓ (producer binding), M10/M18 ✓ (recomputable verdicts), M11 ✓ (path+binding are checkable proof terms), M12 ✓ (certificate + accessors), M14 ✓ (canonical leaf provenance), M19 ✓ (cost bounded: commit `O(n)` hashes, verify `O(log n)`, all under `PROOFC_MAX_LEAVES`). No mandate violations remain after the fix list.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures. Bodies are `// TODO` per Algorithm. ASCII `--` only in comments.

```iii
/* III/STDLIB/iii/numera/proof_carrying.iii
 *
 * III STDLIB - numera::proof_carrying
 *
 * Vector commitments, polynomial commitments, opening proofs. All
 * commitments are Merkle (Keccak256) based; all proofs verify in
 * deterministic time bounded by log of the committed vector length.
 * Hashing via identifier.iii (ident_from_bytes = Keccak256(input);
 * ident_encode_pair = Keccak256(a || b)). Not reentrant -- uses
 * module-level scratch (serialized hashing, like keccak.iii).
 *
 * Hexad: kind_witness.  Ring: R0.  K: 0.99.
 * Discipline: W2 (<=4 params), W8, W13, W14, W15 (no recursion).
 */

module numera_proof_carrying

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_encode_pair(a: *u8, b: *u8, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn bigint_from_u64(arena: u64, v: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_copy(arena: u64, src: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_drop(id: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_get_limb(id: u64, i: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_len_limbs(id: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn gfp_mul(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_add(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"

const PROOFC_OK         : i32 =  0i32
const PROOFC_E_BAD_LEN  : i32 = -1i32
const PROOFC_E_BAD_IDX  : i32 = -2i32
const PROOFC_E_OOM      : i32 = -3i32
const PROOFC_E_NULL     : i32 = -4i32
const PROOFC_E_TOO_BIG  : i32 = -5i32
const PROOFC_INVALID    : u64 = 0u64
const PROOFC_LEAF_BYTES : u64 = 32u64
const PROOFC_MAX_LEAVES : u64 = 1024u64
const PROOFC_MAX_LIMBS  : u64 = 128u64
const PROOFC_CERT_BYTES : u64 = 96u64
const PROOFC_REQ_BYTES  : u64 = 64u64

/* Module-scope scratch (Trap 7: no local var arrays). Not reentrant. */
var PROOFC_LAYER       : [u8; 32768]   /* current Merkle layer, 1024 * 32 */
var PROOFC_LEAVES      : [u8; 32768]   /* coefficient leaves for poly commit */
var PROOFC_LIMB        : [u8; 1024]    /* one coeff's LE limbs, 128 * 8 */
var PROOFC_CUR         : [u8; 32]      /* verify: running node */
var PROOFC_NXT         : [u8; 32]      /* verify: next node */
var PROOFC_HBUF        : [u8; 32]      /* verify_proof: payload hash */
var PROOFC_REQ_SCRATCH : [u8; 64]      /* OpenReq mirror / selftest builder */

/* -- vector commitments -- */
fn pc_commit_vec(items: *u8, n: u64, out_root: *u8) -> i32 @export { /* TODO: body per Algorithm pc_commit_vec */ return PROOFC_OK }
fn pc_open_vec(items: *u8, n: u64, idx: u64, out_path: *u8, out_path_len: *u64) -> i32 @export { /* TODO: body per Algorithm pc_open_vec -- NOTE W2: 5 params; if Phase 2 hits the spill trap, pack (idx,out_path,out_path_len) like keccak_absorb */ return PROOFC_OK }
fn pc_verify_vec(root: *u8, leaf: *u8, idx: u64, n: u64, path: *u8, path_len: u64) -> u8 @export { /* TODO: body per Algorithm pc_verify_vec -- 6 params: pack into a *u8 verify-req block (W2) at impl time */ return 0u8 }

/* -- polynomial commitments -- */
fn pc_coeff_leaf(arena: u64, bid: u64, out_leaf: *u8) -> i32 @export { /* TODO: body per Algorithm pc_coeff_leaf (byte-by-byte LE limb store, Trap 5) */ return PROOFC_OK }
fn pc_commit_poly(coeffs: u64, n_coeffs: u64, p: u64, out_root: *u8) -> i32 @export { /* TODO: body per Algorithm pc_commit_poly */ return PROOFC_OK }
fn pc_eval_poly(arena: u64, coeffs: u64, n_coeffs: u64, z: u64, p: u64) -> u64 @export { /* TODO: body per Algorithm pc_eval_poly -- 5 params; arena+coeffs+n_coeffs+z+p, pack (coeffs,n_coeffs,z,p) if spill observed */ return PROOFC_INVALID }
fn pc_open_poly(arena: u64, req: *u8) -> i32 @export { /* TODO: decode OpenReq, eval, coeff_leaf, open_vec per Algorithm pc_open_poly */ return PROOFC_OK }
fn pc_verify_poly(root: *u8, z_leaf: *u8, idx: u64, n_coeffs: u64, path: *u8, path_len: u64) -> u8 @export { /* TODO: delegate to pc_verify_vec semantics; 6 params -> verify-req block (W2) */ return 0u8 }

/* -- proof certificates -- */
fn pc_attach_proof(payload: *u8, payload_len: u64, producer: *u8, out_certificate: *u8) -> i32 @export { /* TODO: body per Algorithm pc_attach_proof (hash || producer || chain_root) */ return PROOFC_OK }
fn pc_verify_proof(payload: *u8, payload_len: u64, certificate: *u8) -> u8 @export { /* TODO: body per Algorithm pc_verify_proof */ return 0u8 }
fn pc_cert_producer(certificate: *u8, out_producer: *u8) -> i32 @export { /* TODO: copy certificate[32..64] */ return PROOFC_OK }
fn pc_cert_chain_root(certificate: *u8, out_root: *u8) -> i32 @export { /* TODO: copy certificate[64..96] */ return PROOFC_OK }

/* -- self test (Phase-2 acceptance gate) -- */
fn pc_selftest() -> u64 @export { /* TODO: run KAT 1..6, return failing-bit mask (0 = all pass) */ return 0u64 }
```

> W2 note carried into the skeleton: `pc_open_vec` (5), `pc_verify_vec` (6), `pc_eval_poly` (5), `pc_verify_poly` (6) exceed 4 params **as written in the gospel and prose contract**. The gospel candidate itself ships them >4-param (the `keccak.iii` exemplar dodged the same trap by packing into a u64). **W2-strict resolution for Phase 2:** wherever the iiis-0 param-spill trap manifests, pack the trailing args into a `*u8` request block exactly as `PROOFC_OpenReq` does for `pc_open_poly`. The logical signatures are retained above for contract clarity; Phase 2 may physically pack. Either way, **every param read by these fns must be assigned to a local before being passed onward** (CLAUDE.md Parameter-Spill rule) to avoid reading uninitialized stack slots.
