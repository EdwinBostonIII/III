# 69 aether/memo_query.iii — Implementation Spec

## Verdict
**PARTIAL** — The gospel candidate body is trap-clean and compiles structurally, and it correctly realizes the *literal* 3-function surface (`mq_init`, `mq_compute_key`, `mq_lookup_verified`) with chain verification before result release (W36). But it falls short of the **maximal M17 / W50 intent**: it silently discards the `K_memo` confidence dimension that `ml_lookup` returns, it collapses the distinct `ML_E_STALE` signal into `MQ_E_ABSENT` (erasing the staleness channel W50 requires the query layer to honor), it carries two **dead externs** (`ident_zero`, `ident_copy` — never called), and it emits **no witness fragment of its own** for the verified-lookup event (M6/M10). This spec preserves the gospel surface verbatim and augments it to close those gaps.

## Purpose
`aether_memo_query` is the substrate's **public federated query interface over the memo lattice** — the single sanctioned door through which any caller obtains a memoized result. It IS the *enforcement boundary* of M17 (Memoization Sovereignty): a memo result is never handed to a caller until the producing witness-chain segment has been verified (`ws_verify_segment`) and (maximal intent) the entry's confidence `K_memo` and liveness (non-stale) have been affirmed. It owns no cache of its own; it composes content-addressing (Module 55), the memo lattice (Module 58), and the witness spine to turn a `(producer, operation, input)` triple into a *trusted* `(commit, chain_id)` pair or an exact refusal. **Hexad:** `kind_motion + kind_cognition`. **Ring:** R0. **K:** 1.00.

## Public API

Literal gospel surface (preserved verbatim):

```iii
fn mq_init() -> i32 @export
fn mq_compute_key(producer: *u8, operation: *u8, input_commit: *u8, out_key: *u8) -> i32 @export
fn mq_lookup_verified(key: *u8, out_commit: *u8, out_chain_id: *u8) -> i32 @export
```

Maximal-intent augmented surface (closes the M17/W50/M6 gaps; all additive, none break the gospel signatures):

```iii
fn mq_lookup_verified_k(key: *u8, out_commit: *u8, out_chain_id: *u8, out_k_memo: *u8) -> i32 @export
fn mq_query(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 @export
fn mq_min_confidence() -> u8 @export
fn mq_set_min_confidence(cap: *u8, min_k: u8) -> i32 @export
fn mq_selftest() -> i32 @export
```

- **Return convention (W9/W12):** every fn returns a status. `i32` returns are `MQ_OK (0)` on success or a **negative** `i32` error (W9). `mq_min_confidence` returns the configured floor as a `u8` (0..100), a sentinel-typed value (W12 satisfied — the whole `u8` range is meaningful, no error channel needed; the companion setter carries the status).
- `mq_compute_key`: pure pass-through to `ca_compute`; status is `MQ_OK` or `MQ_E_*`. Output `out_key` is the 32-byte content address.
- `mq_lookup_verified`: gospel-exact. Returns `MQ_OK` only if (lookup hit) **and** (chain verified). Augmented to additionally enforce the confidence floor and distinguish stale (see Algorithm).
- `mq_lookup_verified_k`: identical to `mq_lookup_verified` but also writes the affirmed `K_memo` (0..100) to `out_k_memo`, so a caller may inspect confidence after a trusted hit. `mq_lookup_verified` is defined as the `out_k_memo = NULL`-equivalent thin wrapper over the same core.
- `mq_query`: the one-call convenience composing `mq_compute_key` → `mq_lookup_verified` (compute the key from the triple, then verified-lookup). `out` receives the 32-byte output commitment on `MQ_OK`. (Maximal intent: a caller should be able to ask "is `(producer,operation,input)` memoized and trustworthy?" in one capability-free read.)
- `mq_set_min_confidence`: **capability-mediated** (M8). Adjusting the confidence floor is a policy act; it requires a non-null `cap` capability pointer. Default floor is `MQ_K_FLOOR_DEFAULT` (1 — any positive confidence; a stale entry is `K_memo == 0` so the default floor already rejects stale, see W50 note). Reversible (M9/W16): the prior floor is recorded so the change is invertible; out-of-band re-set restores it. `min_k` must be `0..=100` (else `MQ_E_RANGE`).
- `mq_selftest`: deterministic in-module KAT driver (returns count of failed vectors as a negative sentinel, or `MQ_OK`).

## Constant Namespace

**PREFIX = `MQ_`** — Grep of `C:\...\III\STDLIB\` (`\bMQ_[A-Z_]+\b`, and `^const MQ_|^var MQ_|fn mq_`) returns **zero matches**: the prefix is collision-free across the entire built tree. (Trap 2 satisfied — no other module declares these linker-global symbols.)

```iii
const MQ_OK             : i32 =  0i32     // gospel
const MQ_E_NULL         : i32 = -1i32     // gospel — a required pointer arg was null
const MQ_E_ABSENT       : i32 = -2i32     // gospel — no live entry for key
const MQ_E_VERIFY_FAIL  : i32 = -3i32     // gospel — chain segment failed verification
const MQ_E_NOT_INITED   : i32 = -4i32     // gospel — mq_init not yet called
const MQ_E_STALE        : i32 = -5i32     // NEW — entry present but marked stale (W50 channel; was collapsed into ABSENT)
const MQ_E_LOW_CONF     : i32 = -6i32     // NEW — entry verified but K_memo below the configured floor
const MQ_E_CAP          : i32 = -7i32     // NEW — capability arg null/invalid (M8, mq_set_min_confidence)
const MQ_E_RANGE        : i32 = -8i32     // NEW — min_k out of 0..=100
const MQ_KEY_BYTES      : u64 = 32u64     // NEW — identifier/key width (matches ML_KEY_BYTES / CA_BYTES)
const MQ_K_FLOOR_DEFAULT: u8  = 1u8       // NEW — default confidence floor (>0 rejects stale, K_memo==0)
const MQ_K_MAX          : u8  = 100u8     // NEW — K_memo domain ceiling (ml stores 0..100)
```

All error codes are distinct negative `i32` (W9) and pairwise unequal (so W11 `==`/`!=` discrimination is unambiguous). The numeric values of `MQ_OK..MQ_E_NOT_INITED` are kept **byte-identical to the gospel** so any already-written caller keying off `-1..-4` is unbroken.

## Data Structures

The module owns **no cache** (the lattice does). It needs only tiny module-scope policy/scratch state. All are fixed-size module-scope `var`s (W8) — no local `var` arrays (Trap 7), so the only reentrancy caveat is the witness scratch (serialized, acceptable, noted).

```iii
var MQ_INITED      : u8  = 0u8           // gospel — init guard
var MQ_MIN_K       : u8  = 1u8           // NEW — current confidence floor (default MQ_K_FLOOR_DEFAULT)
var MQ_PREV_MIN_K  : u8  = 1u8           // NEW — prior floor, for reversibility (M9/W16) of mq_set_min_confidence
var MQ_KMEMO_SCRATCH : [u8; 1]           // NEW — 1-byte sink for ml_lookup's out_k_memo when caller passes none
var MQ_WIT_PAYLOAD : [u8; 72]            // NEW — witness fragment payload for a verified-lookup event (M6/M10)
var MQ_WIT_PRODUCER: [u8; 32]            // NEW — zero-identifier producer for the lookup fragment
var MQ_WIT_OP      : [u8; 32]            // NEW — zero-identifier op for the lookup fragment
var MQ_WIT_INC     : [u8; 32]            // NEW — in-commit (= key) scratch for the fragment
var MQ_WIT_OUTC    : [u8; 32]            // NEW — out-commit scratch for the fragment
var MQ_WIT_FID     : [u8; 32]            // NEW — fragment-id sink
var MQ_ST_PRODUCER : [u8; 32]            // NEW — selftest: synthetic producer identifier
var MQ_ST_OP       : [u8; 32]            // NEW — selftest: synthetic operation identifier
var MQ_ST_INC      : [u8; 32]            // NEW — selftest: synthetic input commit
var MQ_ST_KEY      : [u8; 32]            // NEW — selftest: computed key
var MQ_ST_COMMIT   : [u8; 32]            // NEW — selftest: looked-up commit sink
var MQ_ST_CHAIN    : [u8; 32]            // NEW — selftest: looked-up chain-id sink
```

**Bound justification (W8):** every buffer is exactly one identifier (`MQ_KEY_BYTES = 32`) or the lattice's documented 72-byte fragment payload — these are the substrate's fixed identifier/fragment widths (`ML_KEY_BYTES`, `CA_BYTES`, the 72-byte `MEMO_*` payload in Module 58), not tunables. `MQ_KMEMO_SCRATCH` is 1 byte because `ml_lookup`'s `out_k_memo` is a single `u8`. No slot table is required because the module is stateless beyond the policy floor.

**Witness-scratch reentrancy note:** `MQ_WIT_*` and `MQ_ST_*` are module-scope and therefore **not reentrant** — `mq_lookup_verified*` and `mq_selftest` must not be called concurrently. This is consistent with the whole STDLIB serialized-call discipline (Module 58 itself uses module-scope payload buffers the same way) and is acceptable for the deterministic single-threaded substrate. Flagged per Trap 7.

## Dependencies (externs)

```iii
extern @abi(c-msvc-x64) fn ca_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn ml_lookup(key: *u8, out_commit: *u8, out_chain_id: *u8, out_k_memo: *u8) -> i32 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn ws_verify_segment(chain_id: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
```

| extern | provider module NN | built? | notes |
|---|---|---|---|
| `ca_compute` | **55** numera/content_addr.iii | **YES (built)** | signature verified byte-exact against the built file (line 30); returns `CA_OK==0i32` on success, negative on null — so the `mq_compute_key` pass-through correctly yields `MQ_OK`. `content_addr` is the *single source* of triple-Keccak256 (M17/W36). |
| `ident_zero`, `ident_copy` | **(numera/identifier.iii)** | **YES (built)** | signatures verified (lines 27, 65). In the gospel body these were imported but **never used** (dead externs). In this spec they ARE used — by the new witness-emission path (`ident_zero` to zero the producer/op, `ident_copy` to set in/out commit). The gospel's dead-extern defect is thereby *resolved by giving them a real call site* rather than deleting them. |
| `ml_lookup` | **58** numera/memo_lattice.iii | **NOT YET BUILT** | parallel module; signature taken from gospel `ml_lookup(key, out_commit, out_chain_id, out_k_memo) -> i32`, returns `ML_OK(0)` / `ML_E_ABSENT(-2)` / `ML_E_STALE(-3)` / `ML_E_NOT_INITED(-8)` / `ML_E_NULL(-1)`. **Wave scheduler: order Module 58 before Module 69.** |
| `ws_verify_segment` | **(numera/witness_spine.iii)** | **NOT YET BUILT** | signature from gospel; returns 0 on verified, non-zero on failure. **Order before Module 69.** |
| `ws_emit_fragment` | **(numera/witness_spine.iii)** | **NOT YET BUILT** | signature taken byte-exact from Module 58's extern block (it calls the same fn). Needed only for the maximal-intent lookup-fragment emission. **Order before Module 69.** |

**Not-yet-built dependency count: 3 modules** — `memo_lattice.iii` (58), `witness_spine.iii`, and the `witness_spine` fragment emitter (same module). `content_addr.iii` and `identifier.iii` are already built.

**Gospel-defect note (systemic keccak):** my module does not `extern` keccak directly — it routes all hashing through `ca_compute`, which (per its own header, content_addr.iii lines 8-10) already reconciles the gospel's wrong `keccak256_init/update/final` streaming form into `keccak256_oneshot`. So the known `extern keccak256_* from "keccak.iii"` defect does **not** appear in this module, and the correct path (`keccak256_oneshot`, living in `keccak256.iii`) is used transitively. Flagged for completeness.

## Algorithm

All control flow uses the sentinel/early-return form (W14, no `break`; no `while` ordering-compare on signed values). All status comparisons are `==`/`!=` on negative `i32` (W11, Trap 3). No modulo, no `@specialize`, no `u32` pointer math in this module (Traps 4/5/11/12 not reached).

### `mq_init() -> i32`
Gospel-exact. Idempotent guard: `if MQ_INITED == 1u8 { return MQ_OK }`; set `MQ_INITED = 1u8`; initialize `MQ_MIN_K = MQ_K_FLOOR_DEFAULT`, `MQ_PREV_MIN_K = MQ_K_FLOOR_DEFAULT`; `return MQ_OK`. *Determinism (M2):* no inputs, constant effect. *No ML (M3):* the floor is a fixed constant, never derived from observed history.

### `mq_compute_key(producer, operation, input_commit, out_key) -> i32`
Gospel-exact. (1) `if MQ_INITED == 0u8 { return MQ_E_NOT_INITED }`. (2) Four null checks (each `(p as u64) == 0u64 → MQ_E_NULL`). (3) `return ca_compute(producer, operation, input_commit, out_key)`. The hand-rolled method is **Keccak256 of the canonical `producer||operation||input_commit` concatenation**, owned by Module 55 (NIH M1 — no third-party hash). *Bit-identity (W5/M2):* `ca_compute` concatenates into a fixed buffer and one-shot-hashes; identical 96-byte input → identical 32-byte address on every run/CPU. *Note:* `ca_compute` re-checks nulls, so the wrapper's checks are defense-in-depth that return the module-specific `MQ_E_NULL`; this is intentional, not redundant-to-remove (the caller sees an `MQ_*` code, never a `CA_*` code).

### `mq_lookup_verified_k(key, out_commit, out_chain_id, out_k_memo) -> i32` (the core; `mq_lookup_verified` delegates here)
The maximal M17/W50/M6 realization. Steps, in exact order:
1. `if MQ_INITED == 0u8 { return MQ_E_NOT_INITED }`.
2. Null-check `key`, `out_commit`, `out_chain_id` → `MQ_E_NULL`. (`out_k_memo` MAY be null: if null, the lattice still requires a non-null sink, so we point it at `&MQ_KMEMO_SCRATCH[0]`.)
3. Choose the k-sink: `let kp : *u8 = out_k_memo if non-null else &MQ_KMEMO_SCRATCH[0]` (expressed as a `when`-style select without side effects; both branches are pure address selection, so no eager-eval trap — Trap-list select() caveat is about *side effects*, none here, but the skeleton uses an explicit `if`/assignment to be safe).
4. `let rc : i32 = ml_lookup(key, out_commit, out_chain_id, kp)`.
5. **Distinguish the lattice outcome by equality only (Trap 3 / W11):**
   - `if rc == ML_OK ( 0i32) {}` → proceed.
   - `if rc == ML_E_STALE (-3i32) { return MQ_E_STALE }` — surface the W50 staleness channel the gospel erased.
   - `else { return MQ_E_ABSENT }` — every other non-zero (absent / not-inited / null) collapses to absent *from the query layer's perspective* (the lattice already emitted its own diagnostic fragment). We compare against the two named sentinels with `==` and fall through with a single `MQ_E_*` return per branch; no ordering compare, no `break`.
6. **Verify the producing chain BEFORE trust (W36, the module's reason to exist):** `if ws_verify_segment(out_chain_id) != 0i32 { return MQ_E_VERIFY_FAIL }`.
7. **Affirm confidence (maximal M17 / W50):** read the affirmed confidence `let k : u8 = kp[0u64]`; `if k < MQ_MIN_K { return MQ_E_LOW_CONF }`. *This is the one place a `<` appears, and it is on a `u8` (unsigned), which is **not** the SIGSEGV family — Trap 3 is specifically signed `i32`/`i64` ordering. Unsigned `u8` ordering is safe and is used throughout the exemplars (e.g. `score >= FED_ADMIT_MIN_SCORE` on `u64` in fed_admit.iii line 85).* Since `MQ_K_FLOOR_DEFAULT == 1`, a stale entry (which the lattice would have flagged at step 5, but defense-in-depth) or any `K_memo == 0` entry is rejected here too.
8. **Emit a verified-lookup witness fragment (M6/M10):** build `MQ_WIT_PAYLOAD` (72 bytes): byte0=`0xE3`, byte1=`0x10` (a fresh `MEMO_QUERY_VERIFIED` tag distinct from Module 58's `0x0D/0x0E/0x0F`), bytes[8..40)=`key`, bytes[40..72)=`out_chain_id`. Zero `MQ_WIT_PRODUCER`/`MQ_WIT_OP` via `ident_zero`; `ident_copy(key, MQ_WIT_INC)`, `ident_copy(out_commit, MQ_WIT_OUTC)`. Call `ws_emit_fragment(producer, op, in_c, out_c, payload, 72u64, fid)`. The fragment's success is *not* gated into the return (a verified result is still returned even if the audit-trail emit returns an error) — but its rc is folded so a future hardening can elevate it; per gospel minimality we return `MQ_OK` after a successful verify+confidence. *M10 reproducibility:* the payload is a pure function of `(key, out_commit, out_chain_id)`, all recorded, so the fragment is byte-recomputable.
9. `return MQ_OK`.

*Why this is not ML (M3):* every gate is an exact algebraic predicate over sealed inputs — a hash equality, a chain-verification boolean, and a constant-floor `u8` comparison. Nothing counts occurrences, observes frequency, or adapts a threshold from history. The floor `MQ_MIN_K` changes only by an explicit **capability-gated** policy call, never by the data flowing through.

### `mq_lookup_verified(key, out_commit, out_chain_id) -> i32`
Gospel surface, preserved. Body: `return mq_lookup_verified_k(key, out_commit, out_chain_id, 0u8 as *u8)` — i.e. delegate to the core with a null k-sink (the core then routes to `MQ_KMEMO_SCRATCH`). Behavior is a **strict superset-compatible refinement** of the gospel: same `MQ_OK`/`MQ_E_NULL`/`MQ_E_NOT_INITED`/`MQ_E_VERIFY_FAIL` semantics; the only observable change is that a *stale* entry now returns the new `MQ_E_STALE (-5)` instead of `MQ_E_ABSENT (-2)`, and a *below-floor* entry returns `MQ_E_LOW_CONF (-6)`. (With the default floor of 1, the sole behavioral delta vs. the literal gospel for a normally-admitted entry — which Module 58 admits at `K_memo = 100` — is *nil*; the new codes fire only on genuinely stale/degraded entries the gospel would have mishandled.)

### `mq_query(producer, operation, input_commit, out) -> i32`
One-call composition (4 params, W2-clean). (1) init + 4 null checks. (2) Compute the key into `MQ_ST_KEY`-style local? — no: use a dedicated module-scope `MQ_QUERY_KEY : [u8; 32]` scratch (add to Data Structures; one more 32-byte buffer, same justification). Actually fold into the witness path: compute key into a 32-byte scratch via `mq_compute_key(producer, operation, input_commit, &scratch)`; if `!= MQ_OK` return it. (3) `return mq_lookup_verified(&scratch, out, &chain_scratch)` where `chain_scratch` is a module-scope 32-byte sink (`MQ_QUERY_CHAIN`). The caller gets only `out` (the commitment); the chain-id is verified internally and discarded. *Determinism:* fully a function of the three inputs.

> Data-structure addendum (for `mq_query`): add `var MQ_QUERY_KEY : [u8; 32]` and `var MQ_QUERY_CHAIN : [u8; 32]` (module-scope, 32 bytes each, same identifier-width justification; serialized-call caveat as above).

### `mq_min_confidence() -> u8`
`return MQ_MIN_K`. Pure read.

### `mq_set_min_confidence(cap, min_k) -> i32` (capability-mediated, reversible — M8/M9)
(1) `if MQ_INITED == 0u8 { return MQ_E_NOT_INITED }`. (2) `if (cap as u64) == 0u64 { return MQ_E_CAP }` — a null capability is refused (M8: privileged policy change requires an explicit capability argument). (3) Range: `if min_k > MQ_K_MAX { return MQ_E_RANGE }` (`u8` ordering, safe). (4) **Reversibility (M9/W16):** `MQ_PREV_MIN_K = MQ_MIN_K; MQ_MIN_K = min_k`. A subsequent call with `min_k = MQ_PREV_MIN_K` exactly inverts it; no state is destroyed. (5) `return MQ_OK`. *Note on capability checking:* the gospel for Module 69 does not itself define a capability type; this spec treats `cap` as an opaque non-null witness/capability pointer (the substrate's standard `*u8` capability handle, as in fed_admit's `ratifier_capability`/`qc_ptr` pattern). A Phase-2 hardening MAY route `cap` through the constitution/capability verifier; the minimal contract is non-null.

### `mq_selftest() -> i32`
Deterministic KAT driver returning `MQ_OK` if all vectors pass, else a negative count sentinel. It exercises the *trap-relevant* and *determinism* properties that do **not** require the not-yet-built lattice (so the test is runnable the moment Modules 58/witness_spine land): key-stability (KAT-1/2) and null-rejection (KAT-3); the lattice-dependent verified-lookup path (KAT-4/5) is gated behind `ml_init` availability and runs in the integration tier. See KAT Vectors.

## KAT Vectors (>= 3)

All identifiers below are 32-byte buffers. "0x41-fill" = all 32 bytes = `0x41`. Content addresses are `Keccak256(producer||operation||input_commit)` — the *exact value* is whatever `keccak256_oneshot` (FIPS-202 Keccak-f[1600], the substrate's single hash) produces; the KAT asserts **determinism and equality relations** byte-for-byte (the concrete 32-byte digest is pinned by `content_addr.iii::ca_selftest`, Module 55, which this module reuses by composition rather than re-pinning a hash constant here).

1. **KAT-1 (key determinism / bit-identity, M2/W5):**
   `mq_init()` then `mq_compute_key(P, O, I, K1)` with `P`=0x41-fill, `O`=0x42-fill, `I`=0x43-fill → `MQ_OK`; run again into `K2` → `MQ_OK` and **`K1 == K2` byte-for-byte (all 32 bytes equal)**. Asserts the hash path is deterministic and the single-line signature bound params to the right offsets (Trap 1 guard).

2. **KAT-2 (key sensitivity / no collision):**
   `mq_compute_key(P, O, I, K1)` vs `mq_compute_key(P, O, I2, K3)` where `I2` differs from `I` in byte 0 only (`0x43`→`0x44`) → both `MQ_OK` and **`K1 != K3`** (the 32-byte outputs differ). Confirms the key is a true content address of all three inputs, not a truncation.

3. **KAT-3 (null + not-inited rejection, W9/W12/M8):**
   Before `mq_init`: `mq_lookup_verified(K, C, CH)` → `MQ_E_NOT_INITED (-4)`. After init: `mq_compute_key(0, O, I, K)` → `MQ_E_NULL (-1)`; `mq_lookup_verified(K, 0, CH)` → `MQ_E_NULL (-1)`; `mq_set_min_confidence(0, 50)` → `MQ_E_CAP (-7)`; `mq_set_min_confidence(VALIDCAP, 200)` → `MQ_E_RANGE (-8)`. **Proves the negative case** (per the user's "prove the guard FAILS on bad input" rule), each error code distinct.

4. **KAT-4 (verified hit, integration tier — requires Modules 58 + witness_spine):**
   Given `ml_init()` and an entry admitted via `ml_admit(K, COMMIT, CHAIN)` with a CHAIN that `ws_verify_segment` accepts (K_memo=100): `mq_compute_key(P,O,I,K)` then `mq_lookup_verified_k(K, C, CH, &kk)` → `MQ_OK`, `C == COMMIT`, `CH == CHAIN` (byte-for-byte), and `kk == 100u8`. Asserts W36 release-after-verify and K_memo surfacing.

5. **KAT-5 (refusal channels, integration tier):**
   (a) Look up a key with no admitted entry → `MQ_E_ABSENT (-2)`. (b) After `ml_mark_stale(K)`, `mq_lookup_verified(K, C, CH)` → `MQ_E_STALE (-5)` (the channel the gospel erased). (c) With an entry whose chain `ws_verify_segment` rejects → `MQ_E_VERIFY_FAIL (-3)`. (d) Raise the floor: `mq_set_min_confidence(VALIDCAP, 100)`, then look up an entry whose `K_memo` is, say, 50 → `MQ_E_LOW_CONF (-6)`; then `mq_set_min_confidence(VALIDCAP, MQ_PREV)` restores and the same lookup → `MQ_OK` (reversibility, M9). **Proves every guard rejects on its specific bad input and that the reversal works.**

## Trap Exposure

| # | Trap | Touched? | Avoidance |
|---|---|---|---|
| 1 | Multi-line `fn` decl → silent wrong codegen | **YES (all fns)** | Every signature in the skeleton is **single-line**, incl. the 4-param `mq_compute_key`/`mq_query`/`ws_emit_fragment` extern. KAT-1 byte-equality is the empirical guard against mis-bound offsets. |
| 2 | Module-level `const` is linker-global | **YES** | Every const/var is `MQ_`-prefixed; grep proved zero collision across `STDLIB/`. |
| 3 | Signed `i32`/`i64` ordering compare → SIGSEGV | **YES (status codes, ml rc)** | **All** status discrimination uses `==`/`!=` against named sentinels (`rc == ML_OK`, `rc == ML_E_STALE`, `... != 0i32`, `... != MQ_OK`). The only `<`/`>` in the module are on **`u8`** values (`k < MQ_MIN_K`, `min_k > MQ_K_MAX`) — unsigned, *not* the crashing family. No `i64`/`i32` ordering anywhere. |
| 4 | `u32`-in-`u64`-slot garbage before pointer math | **NO** | No `u32`→`u64` pointer arithmetic; the only pointer math is `&MQ_WIT_PAYLOAD[8u64 + k]` style with `u64` index `k`. The mask is moot. |
| 5 | `u32` pointer store width clobbers neighbor | **NO** | All buffer writes are `u8` stores through `*u8` (payload bytes, `kp[0]` read). No `*u32` stores. |
| 6 | Nested `/* */` comments | **NO (avoided)** | Header + inline comments use only single-level `/* */` and `//`; no nesting. |
| 7 | Local `var` arrays unsupported | **YES (avoided)** | **No** local `var` arrays. All scratch (`MQ_WIT_*`, `MQ_ST_*`, `MQ_QUERY_*`, `MQ_KMEMO_SCRATCH`) is **module-scope**. Serialized-call (non-reentrant) caveat documented in Data Structures. |
| 8 | `} else {` must be one line | **YES** | The step-5 lattice-outcome cascade and the k-sink selection write `} else {` on one physical line. (Where avoidable, an early-return cascade is preferred over `else`.) |
| 9 | Em-dash in `/* */` terminates comment early | **YES (avoided)** | All comments use ASCII `--` and `->`; **no U+2014**. (This spec doc uses em-dashes freely; the *generated .iii* must not.) |
| 10 | `let mut x = 0u32` checkpoint-flag misbehaves | **YES (avoided)** | No mutated checkpoint flag drives control flow; every decision is an **early return**. The only `let mut` in the gospel (`k_memo`) is replaced by reading `kp[0]` directly after the call. |
| 11 | `a % b` after a call returns quotient/stale divisor | **NO** | No modulo anywhere in the module. |
| 12 | `@specialize *T` indexed stride defaults to 8 | **NO** | No generics / `@specialize`; all element access is concrete `u8`. |

## Gap / Fix List

The gospel candidate body is **trap-clean and faithfully realizes the literal 3-fn surface** — the following are the gaps between that body and the **maximal M17/W50/M6 intent**, each with the fix this spec applies. (No mandate is *violated* by the gospel body; rather, three are *under-realized*.)

1. **GAP — `K_memo` silently discarded (under-realizes M17/W50).** Gospel `mq_lookup_verified` allocates `let mut k_memo : u8 = 0u8`, passes `&k_memo` to `ml_lookup`, and **never reads it**. The confidence dimension that is the whole point of the lattice's `out_k_memo` is thrown away. **FIX:** the core `mq_lookup_verified_k` reads `kp[0]`, enforces it against the capability-set floor `MQ_MIN_K` (`MQ_E_LOW_CONF`), and (in the `_k` variant) returns it to the caller. The thin `mq_lookup_verified` preserves the gospel signature by delegating with a null sink.

2. **GAP — `ML_E_STALE` collapsed into `MQ_E_ABSENT` (under-realizes W50).** Gospel: `if lookup != 0i32 { return MQ_E_ABSENT }` — a stale entry (lattice rc `-3`) is reported as if absent, hiding the staleness channel W50 says the query layer must honor. **FIX:** step-5 cascade compares `rc == ML_E_STALE` first and returns the new `MQ_E_STALE (-5)`; only genuinely-absent/uninit rc collapse to `MQ_E_ABSENT`. (Backward-compatible: with default policy, normally-admitted entries are unaffected; the new code fires only on truly stale entries.)

3. **GAP — dead externs (M14 provenance hygiene).** Gospel imports `ident_zero` and `ident_copy` but **never calls them** — dead linker references. **FIX:** rather than delete (the maximal path keeps the audit trail), give them a real call site in the new witness-emission path (`ident_zero` zeroes the fragment producer/op; `ident_copy` sets in/out commit). Both externs are now load-bearing.

4. **GAP — no own witness for the verified-lookup event (under-realizes M6/M10).** The gospel query layer leaves no chained trace that *a verified lookup occurred at this boundary* (Module 58 emits MEMO_HIT for the lattice read, but not for the *query-interface trust decision*). **FIX:** step 8 emits a `MEMO_QUERY_VERIFIED` fragment (tag `0xE3 0x10`) capturing `(key, chain_id, out_commit)`; payload is a pure function of recorded inputs (M10 reproducible). Emission failure does not revoke an already-verified result (gospel-minimal return semantics preserved).

5. **GAP — no confidence policy / no capability surface (under-realizes M8).** The gospel exposes no way to set a trust floor, and has no capability-mediated action at all. **FIX:** add `mq_min_confidence` (read) and the **capability-gated, reversible** `mq_set_min_confidence` (M8/M9). Default floor `1` makes the addition behavior-neutral until a capability holder raises it.

6. **GAP — no self-test (acceptance-gate hygiene).** Gospel has no KAT driver. **FIX:** `mq_selftest` runs KAT-1..3 standalone (no lattice needed) and is the Phase-2 byte-for-byte acceptance gate; KAT-4/5 run in the integration tier once Modules 58/witness_spine land.

**Mandate audit summary (gospel body):** M1 ✔ (NIH via composition, no third-party). M2 ✔ (deterministic; bit-identity via `ca_compute`). M3 ✔ (no learning — *and the new floor is a constant/capability-set value, never data-derived*). M4 ✔ (exact predicates). M5 ✔ (read-only query, nothing to brick). **M6 ◑→✔** (gap 4 fixed). M7 ✔ (R0, matches header). **M8 ✔** (gap 5 adds the capability surface; the gospel's read-only lookups need none). M9 ✔ (lookups are pure reads; the one mutator is reversible). M10 ✔ (fragment recomputable). M11/M18 n/a (no proof terms here). M12 n/a. M13/M20 ✔ (no self-reflection). M14 ◑→✔ (dead-extern hygiene, gap 3). M15 ✔ (no algebra beyond `u8` floor compare, total). M16 n/a. **M17 ◑→✔** (the module's reason to exist; gaps 1+2 complete the sovereignty enforcement — verify-before-trust *and* confidence/staleness gating). M19 ✔ (bounded: one hash + one lookup + one verify + one emit, constant cost). 

**W-law audit (skeleton):** W2 ✔ (≤4 params — `mq_compute_key`, `mq_query`, `ws_emit_fragment` are exactly 4; `mq_lookup_verified_k` is 4). W9 ✔ (negative `i32` errors). W10 ✔ (`mq_min_confidence` is the only non-`i32` return; it's a sentinel-typed `u8`). W11 ✔ (equality-only on signed). W12 ✔ (every public fn returns a status/sentinel). W13 ✔ (largest fn `mq_lookup_verified_k` uses < 20 named locals). W14 ✔ (early-return cascades, no `break`). W15 ✔ (no recursion — flat composition). W8 ✔ (fixed module-scope buffers, bounds justified). W36/W50 ✔ (verify + staleness gating before release).

## Implementation Skeleton

```iii
/* III/STDLIB/iii/aether/memo_query.iii
 *
 * III STDLIB - aether::memo_query
 *
 * Public, M17-enforcing query interface over the memo lattice. Every
 * successful lookup returns a result only after (a) the producing
 * witness-chain segment verifies and (b) the entry's confidence clears
 * the configured floor and is non-stale. No own cache -- composes
 * content_addr (55), memo_lattice (58), witness_spine. W36/W50 bind:
 * no consumption without verification; no use of stale entries.
 *
 * Public API:
 *   mq_init() -> i32
 *   mq_compute_key(producer, operation, input_commit, out_key) -> i32
 *   mq_lookup_verified(key, out_commit, out_chain_id) -> i32         (gospel surface)
 *   mq_lookup_verified_k(key, out_commit, out_chain_id, out_k_memo) -> i32
 *   mq_query(producer, operation, input_commit, out) -> i32
 *   mq_min_confidence() -> u8
 *   mq_set_min_confidence(cap, min_k) -> i32                         (capability-gated, reversible)
 *   mq_selftest() -> i32
 *
 * Hexad: kind_motion + kind_cognition.  Ring: R0.  K: 1.00.
 * NIH: content_addr.iii, memo_lattice.iii, witness_spine.iii, identifier.iii.
 * Comments use ASCII -- only (no em-dash, Trap 9). No nested block comments (Trap 6).
 */

module aether_memo_query

extern @abi(c-msvc-x64) fn ca_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn ml_lookup(key: *u8, out_commit: *u8, out_chain_id: *u8, out_k_memo: *u8) -> i32 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn ws_verify_segment(chain_id: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"

const MQ_OK              : i32 =  0i32
const MQ_E_NULL          : i32 = -1i32
const MQ_E_ABSENT        : i32 = -2i32
const MQ_E_VERIFY_FAIL   : i32 = -3i32
const MQ_E_NOT_INITED    : i32 = -4i32
const MQ_E_STALE         : i32 = -5i32
const MQ_E_LOW_CONF      : i32 = -6i32
const MQ_E_CAP           : i32 = -7i32
const MQ_E_RANGE         : i32 = -8i32

/* mirror of the memo_lattice (58) rc sentinels we discriminate on (W11/Trap3). */
const MQ_ML_OK           : i32 =  0i32
const MQ_ML_E_STALE      : i32 = -3i32

const MQ_KEY_BYTES       : u64 = 32u64
const MQ_PAYLOAD_BYTES   : u64 = 72u64
const MQ_K_FLOOR_DEFAULT : u8  = 1u8
const MQ_K_MAX           : u8  = 100u8
const MQ_TAG_HI          : u8  = 0xE3u8
const MQ_TAG_LO          : u8  = 0x10u8     /* MEMO_QUERY_VERIFIED (distinct from 58's 0D/0E/0F) */

var MQ_INITED        : u8  = 0u8
var MQ_MIN_K         : u8  = 1u8
var MQ_PREV_MIN_K    : u8  = 1u8

var MQ_KMEMO_SCRATCH : [u8; 1]
var MQ_WIT_PAYLOAD   : [u8; 72]
var MQ_WIT_PRODUCER  : [u8; 32]
var MQ_WIT_OP        : [u8; 32]
var MQ_WIT_INC       : [u8; 32]
var MQ_WIT_OUTC      : [u8; 32]
var MQ_WIT_FID       : [u8; 32]
var MQ_QUERY_KEY     : [u8; 32]
var MQ_QUERY_CHAIN   : [u8; 32]
var MQ_ST_PRODUCER   : [u8; 32]
var MQ_ST_OP         : [u8; 32]
var MQ_ST_INC        : [u8; 32]
var MQ_ST_KEY        : [u8; 32]
var MQ_ST_KEY2       : [u8; 32]
var MQ_ST_COMMIT     : [u8; 32]
var MQ_ST_CHAIN      : [u8; 32]

fn mq_init() -> i32 @export {
    // TODO: body per Algorithm "mq_init" -- idempotent guard; set floor = MQ_K_FLOOR_DEFAULT.
}

fn mq_compute_key(producer: *u8, operation: *u8, input_commit: *u8, out_key: *u8) -> i32 @export {
    // TODO: body per Algorithm "mq_compute_key" -- not-inited + 4 null checks; return ca_compute(...).
}

fn mq_lookup_verified_k(key: *u8, out_commit: *u8, out_chain_id: *u8, out_k_memo: *u8) -> i32 @export {
    // TODO: body per Algorithm "mq_lookup_verified_k":
    //   1) not-inited guard; null-check key/out_commit/out_chain_id (out_k_memo may be null).
    //   2) kp = out_k_memo if non-null else &MQ_KMEMO_SCRATCH[0u64].
    //   3) rc = ml_lookup(key, out_commit, out_chain_id, kp).
    //   4) if rc == MQ_ML_OK {} else { if rc == MQ_ML_E_STALE { return MQ_E_STALE } else { return MQ_E_ABSENT } }   (== only, Trap3)
    //   5) if ws_verify_segment(out_chain_id) != 0i32 { return MQ_E_VERIFY_FAIL }   (W36)
    //   6) let k : u8 = kp[0u64]; if k < MQ_MIN_K { return MQ_E_LOW_CONF }          (u8 ordering = safe)
    //   7) emit MEMO_QUERY_VERIFIED fragment via ident_zero/ident_copy + ws_emit_fragment (M6/M10).
    //   8) return MQ_OK.
}

fn mq_lookup_verified(key: *u8, out_commit: *u8, out_chain_id: *u8) -> i32 @export {
    // TODO: body per Algorithm "mq_lookup_verified" -- delegate: return mq_lookup_verified_k(key, out_commit, out_chain_id, 0u8 as *u8).
}

fn mq_query(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm "mq_query":
    //   not-inited + 4 null checks; rc = mq_compute_key(producer, operation, input_commit, &MQ_QUERY_KEY[0u64]); if rc != MQ_OK return rc;
    //   return mq_lookup_verified(&MQ_QUERY_KEY[0u64], out, &MQ_QUERY_CHAIN[0u64]).
}

fn mq_min_confidence() -> u8 @export {
    // TODO: return MQ_MIN_K.
}

fn mq_set_min_confidence(cap: *u8, min_k: u8) -> i32 @export {
    // TODO: body per Algorithm "mq_set_min_confidence":
    //   not-inited guard; if (cap as u64) == 0u64 { return MQ_E_CAP } (M8);
    //   if min_k > MQ_K_MAX { return MQ_E_RANGE };
    //   MQ_PREV_MIN_K = MQ_MIN_K; MQ_MIN_K = min_k; return MQ_OK.   (M9 reversible)
}

fn mq_selftest() -> i32 @export {
    // TODO: body per KAT Vectors 1-3 (standalone, lattice-free):
    //   init; fill MQ_ST_PRODUCER/OP/INC; compute key twice -> assert byte-equal (KAT-1);
    //   perturb INC byte0 -> compute MQ_ST_KEY2 -> assert key != key2 (KAT-2);
    //   assert null/not-inited/cap/range rejections (KAT-3, prove-the-negative);
    //   return MQ_OK or a negative failure-count sentinel.
}
```
