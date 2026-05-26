# 64 numera/synthesis_witness.iii — Implementation Spec

## Verdict
STUB — the gospel candidate body compiles structurally but is hollow at its heart: `sw_verify_candidate` returns `SW_OK` unconditionally (an explicit self-admitted "stub that defers"), so the module emits a `SYNTH_VERIFIED` certificate for *any* candidate. This is a direct M12 / W38 violation (solver output accepted without a real verifier check). It additionally `extern`s two functions that do not exist in the providing module (`ws_emit_fragment`, `ws_lookup_fragment` are NOT in witness_spine.iii — the same systemic gospel defect as the keccak case), declares local `[u8; N]` arrays inside function bodies (Trap 7 — will not parse), and hard-codes a replay byte offset (`buf[260]`) admitted in-comment to be a guess. PARTIAL pieces (the NULL/init guards, the emit payload framing, the pt_verify gate on emit, the SYNTH_VERIFIED `0xE3 0x07` opcode tag) are sound and are kept.

## Purpose
`synthesis_witness` is the substrate's **synthesis verifier and certificate producer**: the single gate through which every candidate program emitted by the bounded search engine (Module 63) must pass before it is allowed into the witness chain. It replays each algebraic constraint of a ratified specification against the candidate, treating constraint satisfaction as a proof obligation checked by the universal proof checker (`pt_verify`), assembles the per-constraint results into a deterministic **verification transcript**, and on full success emits that transcript as a `SYNTH_VERIFIED` fragment whose replay by any later reader re-establishes correctness (M12). It is the operational realization of W38 ("no solver output without verifier check"). Hexad: `kind_witness + kind_cognition`. Ring: **R0**. K: **1.00**.

## Public API
All signatures are single-line (Trap 1). Status convention: every fn returns negative-`i32` error codes (W9) and a status on every path (W12); booleans, where used internally, are `u8` (W10).

```
fn sw_init() -> i32 @export
fn sw_verify_candidate(spec_id: *u8, candidate_id: *u8) -> i32 @export
fn sw_emit_verified(spec_id: *u8, candidate_id: *u8, proof_term_id: *u8, out_frag_id: *u8) -> i32 @export
fn sw_replay_transcript(verified_frag_id: *u8) -> i32 @export
fn sw_transcript_address(spec_id: *u8, candidate_id: *u8, out: *u8) -> i32 @export
fn sw_selftest() -> u64 @export
```

- `sw_init()` → `SW_OK` (idempotent; clears the module-scope scratch generation guard). W12 status.
- `sw_verify_candidate(spec_id, candidate_id)` → `SW_OK` iff **every** constraint in `spec_id` is satisfied by `candidate_id`; `SW_E_CONSTRAINT_VIOLATED` on the **first** failure; `SW_E_SPEC_ABSENT` / `SW_E_CANDIDATE_ABSENT` / `SW_E_NULL` / `SW_E_NOT_INITED` on the guard paths. This is the load-bearing fn the gospel left as a stub.
- `sw_emit_verified(spec_id, candidate_id, proof_term_id, out_frag_id)` → fragment publish status. Re-runs `sw_verify_candidate` (W38: never emit on an unverified candidate), gates on `pt_verify(proof_term_id) == 0`, frames the canonical transcript payload, and publishes via the witness hook. Returns `SW_E_CONSTRAINT_VIOLATED` if verification fails, `SW_E_PROOF_INVALID` if the proof term is invalid, else the publish status.
- `sw_replay_transcript(verified_frag_id)` → `SW_OK` iff the stored transcript re-verifies (proof term re-checks AND the recomputed transcript content-address matches the one sealed in the payload). `SW_E_*` otherwise. Reads its **own** payload layout (no guessed offset).
- `sw_transcript_address(spec_id, candidate_id, out)` → writes the 32-byte canonical transcript content-address into `out`; `SW_OK`. Deterministic naming of a verification (M2/W5); reused by emit and replay so the sealed address and the recomputed address are bit-identical.
- `sw_selftest()` → `99u64` on success, else a small nonzero failure code (house KAT idiom; mirrors `keccak256_kat` / `ident_selftest`).

## Constant Namespace
PREFIX = `SYNWIT_` (note: the gospel candidate uses the shorter `SW_` prefix; the dispatch assigns `SYNWIT_`. `SW_` collides with no existing STDLIB symbol either, but per Trap 2 the dispatch-assigned prefix is authoritative — **all module-level consts below use `SYNWIT_`**). Grep of `STDLIB/` and `COMPILER/` for both `SYNWIT_` and `sw_*`/`SW_*` returned **no collisions**.

Public function names retain the gospel `sw_` verb prefix (the dependency Module 63 `extern`s `sw_verify_candidate` by that exact name — renaming the functions would break the parallel module). Only **constants** and **module-scope buffers** carry `SYNWIT_`.

| const | type | value | meaning |
|---|---|---|---|
| `SYNWIT_OK` | i32 | `0i32` | success |
| `SYNWIT_E_NULL` | i32 | `-1i32` | a required pointer arg is null |
| `SYNWIT_E_SPEC_ABSENT` | i32 | `-2i32` | spec_id not registered in synthesis_spec |
| `SYNWIT_E_CANDIDATE_ABSENT` | i32 | `-3i32` | candidate_id has no resolvable encoding |
| `SYNWIT_E_CONSTRAINT_VIOLATED` | i32 | `-4i32` | a constraint predicate evaluated false |
| `SYNWIT_E_PROOF_INVALID` | i32 | `-5i32` | pt_verify rejected the proof term |
| `SYNWIT_E_NOT_INITED` | i32 | `-6i32` | sw_init not called |
| `SYNWIT_E_LOOKUP` | i32 | `-7i32` | fragment / payload lookup failed |
| `SYNWIT_E_BAD_PAYLOAD` | i32 | `-8i32` | stored payload malformed (tag/len mismatch) |
| `SYNWIT_E_TRANSCRIPT` | i32 | `-9i32` | recomputed transcript address ≠ sealed address |
| `SYNWIT_ID_BYTES` | u64 | `32u64` | identifier width |
| `SYNWIT_MAX_CONSTRAINTS` | u64 | `32u64` | bound on constraints per spec (mirrors `SS_MAX_CONSTRAINTS`) |
| `SYNWIT_PRED_CAP` | u64 | `4096u64` | per-constraint predicate buffer cap (mirrors `SS_PREDICATE_BUF_BYTES`) |
| `SYNWIT_PAYLOAD_CAP` | u64 | `4096u64` | transcript payload buffer cap |
| `SYNWIT_TAG_HI` | u8 | `0xE3u8` | synthesis opcode namespace byte |
| `SYNWIT_TAG_LO` | u8 | `0x07u8` | SYNTH_VERIFIED subtype (from gospel) |
| `SYNWIT_HDR_LEN` | u64 | `8u64` | fixed header bytes before the id triple |
| `SYNWIT_OFF_SPEC` | u64 | `8u64` | payload offset of spec_id |
| `SYNWIT_OFF_CAND` | u64 | `40u64` | payload offset of candidate_id |
| `SYNWIT_OFF_PROOF` | u64 | `72u64` | payload offset of proof_term_id |
| `SYNWIT_OFF_ADDR` | u64 | `104u64` | payload offset of sealed transcript address |
| `SYNWIT_OFF_NCONS` | u64 | `136u64` | payload offset of constraint-count (4 bytes LE) |
| `SYNWIT_OFF_RESULTS` | u64 | `140u64` | payload offset of per-constraint result bytes |
| `SYNWIT_PAYLOAD_LEN` | u64 | `172u64` | total emitted payload length (140 + 32 result bytes) |

`SYNWIT_PAYLOAD_LEN = 172` = 8 header + 3×32 ids + 32 sealed address + 4 ncons + 32 result bytes (one `u8` verdict per possible constraint, `SYNWIT_MAX_CONSTRAINTS = 32`). This is a fixed, self-documenting layout the module **owns** — replaying reads these named offsets, not the gospel's guessed `260`.

## Data Structures
All scratch is **module-scope** (Trap 7 — no local `var`/`let mut` arrays). Sizes are static (W8). The module is **not reentrant** across these buffers — acceptable because synthesis verification is serialized (one candidate verified at a time, exactly like keccak256/identifier/content_addr scratch reuse); flagged here per Trap 7.

| buffer | type | size | bound justification |
|---|---|---|---|
| `SYNWIT_INITED` | u8 | scalar `0u8` | one-shot init guard (W6/W7 lifecycle) |
| `SYNWIT_PAYLOAD` | [u8; 4096] | `SYNWIT_PAYLOAD_CAP` | transcript framing + lookup readback; 4096 ≥ `SYNWIT_PAYLOAD_LEN`(172) and ≥ any future result-vector growth; matches `SS_PREDICATE_BUF_BYTES` house bound |
| `SYNWIT_RESULTS` | [u8; 32] | `SYNWIT_MAX_CONSTRAINTS` | one verdict byte per constraint; bound = max constraints a spec may hold (`SS_MAX_CONSTRAINTS = 32`) |
| `SYNWIT_PRED` | [u8; 4096] | `SYNWIT_PRED_CAP` | one constraint predicate term fetched from the spec; bound = `SS_PREDICATE_BUF_BYTES` |
| `SYNWIT_CAND_ENC` | [u8; 4096] | `SYNWIT_PRED_CAP` | candidate encoding fetched for substitution |
| `SYNWIT_PRODUCER` | [u8; 32] | `SYNWIT_ID_BYTES` | producer id for wh_publish (sw module self-id, zero) |
| `SYNWIT_OP` | [u8; 32] | `SYNWIT_ID_BYTES` | op id for wh_publish (zero — SYNTH_VERIFIED op) |
| `SYNWIT_INC` | [u8; 32] | `SYNWIT_ID_BYTES` | in_commit = spec_id copy |
| `SYNWIT_OUTC` | [u8; 32] | `SYNWIT_ID_BYTES` | out_commit = candidate_id copy |
| `SYNWIT_ADDR` | [u8; 32] | `SYNWIT_ID_BYTES` | recomputed transcript content-address scratch |
| `SYNWIT_TERM` | [u8; 32] | `SYNWIT_ID_BYTES` | proof-term id extracted on replay |
| `SYNWIT_ADDR_SEAL` | [u8; 32] | `SYNWIT_ID_BYTES` | sealed address read back on replay (compared to recomputed) |
| `SYNWIT_ADDRBUF` | [u8; 104] | 96+pad | concat scratch for transcript-address hash (spec‖cand‖results), passed to keccak256_oneshot |
| `SYNWIT_PLEN` | [u64; 1] | scalar | payload length holder (call-clobber-safe, per keccak256.iii idiom) |
| `SYNWIT_LIDX` | [u64; 1] | scalar | resolved fragment index from ws_lookup_id |
| `SYNWIT_KMSG`/`SYNWIT_KOUT`/`SYNWIT_KREF` | [u8; …] | KAT | self-test scratch (mirrors keccak256_kat) |

W1/W3: every `&SYNWIT_*` address-of-static is taken only inside this file; no global pointer escapes (the ids handed to `wh_publish` are copies in module scratch, not caller pointers retained).

## Dependencies (externs)
Each as `extern @abi(c-msvc-x64) fn … from "<module>.iii"`. **Build-status** column: BUILT = present in `STDLIB/iii/...`; NYB = not-yet-built (wave scheduler must order before Phase-2 link/test of this module).

| extern fn | from | NN | status |
|---|---|---|---|
| `ident_zero(out: *u8) -> i32` | identifier.iii | 01 | **BUILT** |
| `ident_copy(src: *u8, dst: *u8) -> i32` | identifier.iii | 01 | **BUILT** |
| `ident_eq(a: *u8, b: *u8) -> u8` | identifier.iii | 01 | **BUILT** |
| `keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32` | keccak256.iii | (built) | **BUILT** |
| `pt_verify(term_id: *u8) -> i32` | proof_term.iii | 61 | **NYB** |
| `ss_content_address(spec_id: *u8, out: *u8) -> i32` | synthesis_spec.iii | 59 | **NYB** |
| `ss_constraint_count(spec_id: *u8, out_n: *u32) -> i32` | synthesis_spec.iii | 59 | **NYB — REQUIRES NEW ACCESSOR (see Gap list)** |
| `ss_get_constraint(spec_id: *u8, k: u32, out_buf: *u8, cap: u64, out_len: *u64) -> i32` | synthesis_spec.iii | 59 | **NYB — REQUIRES NEW ACCESSOR** |
| `ss_get_verifier(spec_id: *u8, out_module: *u8, out_fn: *u8) -> i32` | synthesis_spec.iii | 59 | **NYB — REQUIRES NEW ACCESSOR** |
| `sy_get_candidate_encoding(candidate_id: *u8, out_buf: *u8, cap: u64, out_len: *u64) -> i32` | synthesis_search.iii | 63 | **NYB — REQUIRES NEW ACCESSOR** |
| `wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | witness_hook.iii | (aether, built) | **BUILT** |
| `wh_get_payload(idx: u64, out_buf: *u8, max_len: u64, out_len: *u64) -> i32` | witness_hook.iii | (aether, built) | **BUILT** |
| `ws_lookup_id(frag_id: *u8, out_idx: *u64) -> i32` | witness_spine.iii | 12 | **NYB** |

**NOT-YET-BUILT dependency modules (4):** `proof_term.iii` (61), `synthesis_spec.iii` (59), `synthesis_search.iii` (63), `witness_spine.iii` (12). (`witness_hook.iii`, `identifier.iii`, `keccak256.iii` are built.)

> **REJECTED gospel externs** (do not use — they do not exist in the named provider): `ws_emit_fragment(...)` and `ws_lookup_fragment(...)` from witness_spine.iii. witness_spine's actual public API (gospel Module 12) is `ws_init / ws_register / ws_lookup_id / ws_pillar_* / ws_producer_* / ws_operation_* / ws_epoch_* / ws_chain_root / ws_chain_replay_verify`. Fragment **emission** is owned by `witness_hook.iii::wh_publish`; **payload retrieval** is `ws_lookup_id` (frag_id → idx) followed by `wh_get_payload(idx, …)`. This correction is the synthesis_witness analogue of the keccak `keccak256_init/update/final from "keccak.iii"` defect.

## Algorithm

### `sw_init`
Set `SYNWIT_INITED = 1u8` (idempotent: if already 1, return `SYNWIT_OK`). No allocation. Determinism: trivial. (Early-return on the already-inited path — avoids the mutated-flag-as-checkpoint pattern of Trap 10.)

### `sw_verify_candidate` — the real verifier (replaces the gospel stub)
NIH method: **deterministic constraint replay**, no dispatch-by-name (a deterministic substrate cannot indirect-call an arbitrary `(module, fn)` at runtime without a dynamic-dispatch hazard; M2/M4). Instead the verifier treats the spec's verifier reference as *documentation of the rule family* and checks each algebraic constraint predicate directly. Steps:
1. Guards: `SYNWIT_INITED == 0u8 → SYNWIT_E_NOT_INITED`; null `spec_id`/`candidate_id` (`(p as u64) == 0u64`) → `SYNWIT_E_NULL`.
2. Resolve the candidate's encoding: `sy_get_candidate_encoding(candidate_id, &SYNWIT_CAND_ENC[0], SYNWIT_PRED_CAP, &SYNWIT_PLEN[0])`; nonzero → `SYNWIT_E_CANDIDATE_ABSENT`.
3. Fetch constraint count: `ss_constraint_count(spec_id, &n)`; nonzero → `SYNWIT_E_SPEC_ABSENT`. `n` is `u32`, masked `& 0xFFFFFFFFu32` before any use (W4) and never used in pointer math without `& 0xFFFFFFFFu64` (Trap 4).
4. **Sentinel loop** over `k = 0 .. n` (W14, no `break`): a `u8 violated` flag and a `u8 done` flag drive the loop; while `k < n && done == 0u8`:
   - `ss_get_constraint(spec_id, k, &SYNWIT_PRED[0], SYNWIT_PRED_CAP, &len)` → predicate term bytes.
   - Evaluate the predicate against `SYNWIT_CAND_ENC` by **constructing the inference and checking it with `pt_verify`**: the predicate term is the conclusion "candidate ⊨ constraint_k"; the verifier folds (predicate ‖ candidate-encoding) into a content-address that *is* the proof-term id of the obligation, then calls `pt_verify` on it. `pt_verify == 0i32` → constraint satisfied; `!= 0i32` → `SYNWIT_RESULTS[k] = 0u8`, `violated = 1u8`, `done = 1u8`. On satisfied: `SYNWIT_RESULTS[k] = 1u8`.
   - `k = k + 1u64` (advanced only while `done == 0u8`, per the keccak/identifier sentinel idiom).
5. Result: `violated == 1u8 → SYNWIT_E_CONSTRAINT_VIOLATED`, else `SYNWIT_OK`.

Determinism (M2)/bit-identity (W5): constraint order is the spec's stored order (a fixed array index `k`); predicate bytes and candidate encoding are byte-exact inputs; `pt_verify` is itself deterministic (M11 audited core). No counting/threshold/learning (M3) — the verdict is the exact AND of all per-constraint checks. No ordering compares on signed ints — every `pt_verify`/return-code test is `== 0i32` / `!= 0i32` (Trap 3 / W11). No recursion (W15) — single explicit `while` over `k`, no call stack.

### `sw_transcript_address`
Concatenate `spec_id ‖ candidate_id ‖ SYNWIT_RESULTS[0..MAX-1]` into `SYNWIT_ADDRBUF` (32+32+32 = 96 bytes, hashed in one shot) and `keccak256_oneshot(&SYNWIT_ADDRBUF, 96u64, out)`. This is the deterministic canonical name of *this* verification (the transcript), reused identically by emit (to seal) and replay (to recompute). M17/W36 discipline: content addressing flows through keccak256_oneshot, no ad-hoc hashing.

### `sw_emit_verified`
1. Guards: not-inited → `SYNWIT_E_NOT_INITED`; null `spec_id`/`candidate_id`/`proof_term_id`/`out_frag_id` → `SYNWIT_E_NULL`.
2. **W38 enforcement (the gospel omits this):** call `sw_verify_candidate(spec_id, candidate_id)`; if `!= SYNWIT_OK` return that code. No certificate is ever emitted for an unverified candidate. (After this call, `SYNWIT_RESULTS` holds the per-constraint verdicts; note Trap 11 — there is no `a % b` after this call, so no modulo-after-call hazard.)
3. Proof gate: `pt_verify(proof_term_id)`; `!= 0i32 → SYNWIT_E_PROOF_INVALID`.
4. Compute sealed address: `sw_transcript_address(spec_id, candidate_id, &SYNWIT_ADDR[0])`.
5. Frame `SYNWIT_PAYLOAD` (byte-by-byte through the `[u8]` buffer — never a wide `*u32` store; Trap 5): `[0]=SYNWIT_TAG_HI`, `[1]=SYNWIT_TAG_LO`, `[2..7]=0`; copy `spec_id`→`OFF_SPEC`, `candidate_id`→`OFF_CAND`, `proof_term_id`→`OFF_PROOF`, `SYNWIT_ADDR`→`OFF_ADDR` (32 bytes each via a 32-iter `while`); write `n` (constraint count) as 4 LE bytes at `OFF_NCONS`, each byte `((n >> (8*i)) & 0xFFu32) as u8`; copy `SYNWIT_RESULTS[0..31]`→`OFF_RESULTS`.
6. Prepare publish ids: `ident_zero(&SYNWIT_PRODUCER[0])`, `ident_zero(&SYNWIT_OP[0])`, `ident_copy(spec_id, &SYNWIT_INC[0])`, `ident_copy(candidate_id, &SYNWIT_OUTC[0])`.
7. `wh_publish(&SYNWIT_PRODUCER[0], &SYNWIT_OP[0], &SYNWIT_INC[0], &SYNWIT_OUTC[0], 0u8 /*revtag: reversible, W16*/, 0u8 /*phase*/, 0u16 /*pillar: synthesis*/, &SYNWIT_PRODUCER[0] /*no antecedents*/, 0u32, &SYNWIT_PAYLOAD[0], (SYNWIT_PAYLOAD_LEN) as u32, out_frag_id)` → returns the fragment **idx** (`u64`). On the sentinel error idx `0xFFFFFFFFFFFFFFFFu64`, return `SYNWIT_E_LOOKUP`; else `SYNWIT_OK`. (Compare the sentinel by `==` only, never `<`/`>=`; Trap 3.)

Reversibility (M5/M9/W16): `revtag = 0` marks the fragment reversible; emission adds a witness fragment, never mutates prior state irreversibly. M6/M10: the fragment id chains by hash (wh_publish computes it from idx+content); the OK certificate is recomputable byte-identically from the recorded spec/candidate/proof ids + results (that is exactly what replay does).

### `sw_replay_transcript` — reads its OWN layout (replaces the guessed `buf[260]`)
1. Guards: not-inited → `SYNWIT_E_NOT_INITED`; null `verified_frag_id` → `SYNWIT_E_NULL`.
2. Resolve idx: `ws_lookup_id(verified_frag_id, &SYNWIT_LIDX[0])`; `!= 0i32 → SYNWIT_E_LOOKUP`.
3. Fetch payload: `wh_get_payload(SYNWIT_LIDX[0], &SYNWIT_PAYLOAD[0], SYNWIT_PAYLOAD_CAP, &SYNWIT_PLEN[0])`; `!= 0i32 → SYNWIT_E_LOOKUP`.
4. Validate framing: `SYNWIT_PAYLOAD[0] != SYNWIT_TAG_HI` or `[1] != SYNWIT_TAG_LO` or `SYNWIT_PLEN[0] != SYNWIT_PAYLOAD_LEN` → `SYNWIT_E_BAD_PAYLOAD` (all `==`/`!=` tests; Trap 3).
5. Extract `proof_term_id` from `OFF_PROOF` into `SYNWIT_TERM` (32-iter copy); the sealed address from `OFF_ADDR` into `SYNWIT_ADDR_SEAL`; the results from `OFF_RESULTS` into `SYNWIT_RESULTS`; the spec/candidate ids from `OFF_SPEC`/`OFF_CAND` (into `SYNWIT_INC`/`SYNWIT_OUTC` reused as scratch).
6. Re-verify the proof term: `pt_verify(&SYNWIT_TERM[0]) != 0i32 → SYNWIT_E_PROOF_INVALID`.
7. Recompute the transcript address from the extracted spec/candidate ids + the extracted results (`sw_transcript_address` over the readback ids) and compare to `SYNWIT_ADDR_SEAL` via `ident_eq`; mismatch (`ident_eq == 0u8`) → `SYNWIT_E_TRANSCRIPT`.
8. Return `SYNWIT_OK`.

This makes replay a true re-derivation (M10/M12): a reader recomputes the certificate's content address from the recorded inputs and checks both the proof and the seal — no trust, no magic offset. Determinism: identical payload → identical recomputed address.

### `sw_selftest`
House KAT (returns `99u64` on pass). Because the heavyweight checks depend on NYB modules, the self-test exercises the parts that are self-contained: (a) `sw_init` idempotence; (b) `sw_verify_candidate`/`sw_emit_verified` correctly **reject** before init and on null args (proving the negative case — the guards FAIL closed, not open); (c) `sw_transcript_address` is deterministic (same inputs → identical 32 bytes across two calls) and order-sensitive (swapping spec/candidate changes the address); (d) payload framing round-trips: frame `SYNWIT_PAYLOAD` from known ids then re-extract and compare. Phase-2 integration KATs (below) run once the NYB deps land.

## KAT Vectors (≥ 3)
Concrete, byte-checkable. (1)–(3) are self-contained and become the Phase-2 acceptance gate for this module in isolation; (4)–(5) are integration vectors gated on the NYB deps.

1. **Guards fail closed (negative case).** Before `sw_init`: `sw_verify_candidate(&id, &id)` → `-6` (`SYNWIT_E_NOT_INITED`). After `sw_init`: `sw_verify_candidate(0 as *u8, &id)` → `-1` (`SYNWIT_E_NULL`); `sw_emit_verified(&id, &id, &id, 0 as *u8)` → `-1`. Proves the gate does not pass on bad input.
2. **Transcript address determinism + sensitivity.** With `spec_id = ident_from_bytes("S")`, `candidate_id = ident_from_bytes("C")`, and `SYNWIT_RESULTS = all 1u8`: `sw_transcript_address(S, C, a1)` then again `(S, C, a2)` ⇒ `a1 == a2` byte-for-byte (32/32 equal). Then `sw_transcript_address(C, S, a3)` ⇒ `a3 != a1` (order matters). Expected `a1` is fixed: `a1 = Keccak256( S ‖ C ‖ 0x01×32 )` — concrete 32-byte value pinned at Phase-2 implementation time from the proven keccak256_oneshot (cite: this module's own first green build, recorded into the spec as the golden vector, exactly as keccak256.iii pins `Keccak256("") = c5d24601…85a470`).
3. **Payload framing round-trip.** Build `SYNWIT_PAYLOAD` via the emit framing path from `spec=S, candidate=C, proof=P, addr=A, n=3, results=[1,1,1,0,…]`; then run the replay extraction path on `SYNWIT_PAYLOAD`: extracted `proof_term_id == P` (32/32), extracted sealed addr `== A`, extracted `results[0..2] == [1,1,1]`, and tag bytes `== 0xE3,0x07`. Establishes that emit and replay agree on the layout the module owns (no `buf[260]` guess).
4. **(integration, gated on M59/M61/M63) Full accept.** A ratified spec `S` with 2 satisfiable constraints + a candidate `C` whose encoding satisfies both + a valid proof term `P`: `sw_verify_candidate(S, C)` → `0`; `sw_emit_verified(S, C, P, f)` → `0` and `f` is a nonzero 32-byte frag id; `sw_replay_transcript(f)` → `0`.
5. **(integration) Reject path.** Same `S` but candidate `C2` failing constraint #1: `sw_verify_candidate(S, C2)` → `-4` (`SYNWIT_E_CONSTRAINT_VIOLATED`); `sw_emit_verified(S, C2, P, f)` → `-4` and **no fragment is published** (W38 — verify the witness-hook idx did not advance).

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| 1 — multi-line `fn` | YES (the built `wh_publish` exemplar is multi-line; tempting to mirror) | **Every** signature in this spec/skeleton is single-line, including the 12-arg `wh_publish` extern and `sw_emit_verified`. |
| 2 — module-level const linker-global | YES (gospel used bare `SW_OK` etc.) | All consts prefixed `SYNWIT_`; grep-confirmed no collision with `SYNWIT_`/`SW_`/`SS_`/`PT_`/`WS_`/`WH_` symbols. |
| 3 — signed ordering compare SIGSEGV | YES (return-code & sentinel-idx tests) | All i32/i64 comparisons are `== 0i32` / `!= 0i32` / `== 0xFFFFFFFFFFFFFFFFu64`; never `<`/`<=`/`>`/`>=`. The gospel `i64 slot = -1i64` ordering pattern from synthesis_spec is **not** reproduced here. |
| 4 — u32-in-u64-slot garbage | YES (`n` constraint count used in loop bound & LE encode) | Mask `(n as u64) & 0xFFFFFFFFu64` before any use as a loop bound or in pointer/offset math; mask `& 0xFFFFFFFFu32` before shifts. |
| 5 — u32 pointer store width | YES (writing `n` into the payload) | Write the 4 count bytes individually through the `[u8]` payload buffer (`payload[OFF+i] = ((n >> (8*i)) & 0xFFu32) as u8`), never `*u32` store. |
| 6 — nested `/* */` | low | Header/comments use a single non-nested block; inline notes use `//`. |
| 7 — local `var` arrays | YES (gospel body declared `let mut payload:[u8;104]`, `[u8;32]×4`, `[u8;4096]` **inside** fns) | **All** buffers moved to module scope with `SYNWIT_` names. Non-reentrancy noted (serialized verification — safe, same as keccak/identifier). |
| 8 — `} else {` split | possible | Any else is written `} else {` on one line; the verify/replay logic is structured to prefer guard-and-continue (sentinel flags) over deep if/else, minimizing else use. |
| 9 — em-dash in comment | YES (this is prose-heavy) | All comments use ASCII `--`; no U+2014 anywhere in the .iii. |
| 10 — `let mut x=0u32` checkpoint flag | YES (verify uses `violated`/`done` flags) | Flags are `u8` and drive the sentinel loop condition itself (`while k < n && done == 0u8`), per the corrected insertion-sort/keccak idiom; `sw_init` uses early-return not a mutated checkpoint. |
| 11 — `a % b` after call | NO | The algorithm contains no modulo after a call (constraint indexing is `k = k + 1`, bounds are `<` against a fetched count; no `%`). Explicitly verified — none introduced. |
| 12 — `@specialize *T` stride | NO | Module is not generic; all buffers are concrete `[u8;N]`/`[u64;N]`. |

## Gap / Fix List (Verdict = STUB)
Every defect in the gospel candidate body, with the fix:

1. **`sw_verify_candidate` is a no-op stub returning `SW_OK`** (gospel lines ~18559-18567, comment "The implementation here is a stub that defers"). **Severity: critical — M12/M3/W38 violation** (emits a verified certificate for any input; this is precisely the "halfassed" core). **Fix:** the real constraint-replay algorithm above — fetch the spec's constraints, evaluate each against the candidate encoding via `pt_verify`-checked obligations, AND the results, return `SYNWIT_E_CONSTRAINT_VIOLATED` on first failure.
2. **Phantom externs `ws_emit_fragment` / `ws_lookup_fragment` from "witness_spine.iii"** (gospel lines 18535-18536) — these functions do not exist in witness_spine (Module 12 exports `ws_lookup_id`/`ws_register`/… , not these). **Fix:** emit via `witness_hook.iii::wh_publish`; look up via `witness_spine.iii::ws_lookup_id` + `witness_hook.iii::wh_get_payload`. (Same systemic gospel defect class as the keccak `init/update/final from "keccak.iii"` error — proof_term.iii and synthesis_spec.iii carry the identical phantom extern and need the same correction.)
3. **Local array declarations inside fn bodies** — `let mut payload : [u8; 104]`, `let mut producer/op/in_c/out_c : [u8; 32]`, `let mut buf : [u8; 4096]`, `let mut term_id : [u8; 32]` (gospel lines 18577-18607). **Severity: will not parse (Trap 7).** **Fix:** all moved to module-scope `SYNWIT_*` buffers (Data Structures table).
4. **Guessed replay offset `buf[260u64 + k]`** with the comment "offset depends on V2 layout … V3 extended payload starting at byte 188". **Severity: correctness — the verifier guesses a layout it does not own.** **Fix:** the module defines and owns the payload layout (named `SYNWIT_OFF_*` constants); replay reads `proof_term_id` from `SYNWIT_OFF_PROOF` (72) of its own `SYNWIT_PAYLOAD_LEN`(172) payload, and additionally re-derives + checks the sealed transcript address (the gospel replay only re-ran pt_verify and never checked the transcript itself).
5. **No W38 gate on emit** — gospel `sw_emit_verified` checks `pt_verify` but never calls `sw_verify_candidate`, so it would happily emit `SYNTH_VERIFIED` for a candidate that fails its constraints (given any valid proof term). **Fix:** emit re-runs `sw_verify_candidate` first and aborts with `SYNWIT_E_CONSTRAINT_VIOLATED` on failure.
6. **Missing synthesis_spec read accessors.** Module 59 (gospel) exposes no `ss_constraint_count` / `ss_get_constraint` / `ss_get_verifier`, yet a real verifier must read the constraints. **Fix / cross-module action:** these three accessors must be added to synthesis_spec.iii (the data — `SS_CONSTRAINT_COUNTS`, `SS_CONSTRAINT_LENS`, `SS_CONSTRAINT_BUFS`, `SS_VERIFIER_MODULES`, `SS_VERIFIER_FNS` — already exists in M59; only getters are missing). Flagged to the wave scheduler as a required M59 amendment. Likewise `sy_get_candidate_encoding` must be added to synthesis_search.iii (M63 stores candidate encodings via `sy_emit_candidate`; a getter is needed). Until then KATs 4-5 are blocked; KATs 1-3 are not.
7. **`SW_` vs `SYNWIT_` prefix.** Per dispatch + Trap 2, module-level consts use `SYNWIT_`; function names keep `sw_` (Module 63 externs them by that name). Documented above.
8. **Mandate posture confirmed:** M1 (only libc + identifier/keccak/witness_hook/proof_term/synthesis_spec — all III) ✓; M2/M15 (constraint AND is total + deterministic over the fixed bound) ✓; M5/M9 (revtag=0 reversible emission) ✓; M6/M10 (hash-chained fragment, recomputable certificate) ✓; M11/M18 (constraint obligations checked as proof terms) ✓; M12 (replayable transcript) ✓; M13/M20 (the verifier never verifies itself; pt_verify's own soundness is out of scope, audited elsewhere — noted, do not add self-reflection) ✓; M19 (cost is bounded: ≤ `SYNWIT_MAX_CONSTRAINTS` constraint checks, each a single pt_verify; no unbounded loop) ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/synthesis_witness.iii
 *
 * III STDLIB -- numera::synthesis_witness
 *
 * The synthesis verifier and certificate producer. Replays every
 * algebraic constraint of a ratified specification against a candidate,
 * checking each as a proof-term obligation (pt_verify); on full success
 * emits a SYNTH_VERIFIED transcript fragment whose replay re-derives
 * correctness (M12, W38). No solver output is admitted without this check.
 *
 * Hexad: kind_witness + kind_cognition.  Ring: R0.  K: 1.00.
 * NIH: identifier.iii, keccak256.iii, proof_term.iii, synthesis_spec.iii,
 *      synthesis_search.iii, witness_spine.iii, witness_hook.iii.
 * Discipline: every verification produces a recomputable transcript;
 * the verifier never reasons about itself (M20). All ids are 32 bytes.
 * NOTE: module-scope scratch -- verification is serialized, not reentrant.
 */
module numera_synthesis_witness

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn ss_content_address(spec_id: *u8, out: *u8) -> i32 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn ss_constraint_count(spec_id: *u8, out_n: *u32) -> i32 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn ss_get_constraint(spec_id: *u8, k: u32, out_buf: *u8, cap: u64, out_len: *u64) -> i32 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn ss_get_verifier(spec_id: *u8, out_module: *u8, out_fn: *u8) -> i32 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn sy_get_candidate_encoding(candidate_id: *u8, out_buf: *u8, cap: u64, out_len: *u64) -> i32 from "synthesis_search.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_payload(idx: u64, out_buf: *u8, max_len: u64, out_len: *u64) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn ws_lookup_id(frag_id: *u8, out_idx: *u64) -> i32 from "witness_spine.iii"

const SYNWIT_OK                   : i32 =  0i32
const SYNWIT_E_NULL               : i32 = -1i32
const SYNWIT_E_SPEC_ABSENT        : i32 = -2i32
const SYNWIT_E_CANDIDATE_ABSENT   : i32 = -3i32
const SYNWIT_E_CONSTRAINT_VIOLATED : i32 = -4i32
const SYNWIT_E_PROOF_INVALID      : i32 = -5i32
const SYNWIT_E_NOT_INITED         : i32 = -6i32
const SYNWIT_E_LOOKUP             : i32 = -7i32
const SYNWIT_E_BAD_PAYLOAD        : i32 = -8i32
const SYNWIT_E_TRANSCRIPT         : i32 = -9i32

const SYNWIT_ID_BYTES        : u64 = 32u64
const SYNWIT_MAX_CONSTRAINTS : u64 = 32u64
const SYNWIT_PRED_CAP        : u64 = 4096u64
const SYNWIT_PAYLOAD_CAP     : u64 = 4096u64
const SYNWIT_TAG_HI          : u8  = 0xE3u8
const SYNWIT_TAG_LO          : u8  = 0x07u8
const SYNWIT_HDR_LEN         : u64 = 8u64
const SYNWIT_OFF_SPEC        : u64 = 8u64
const SYNWIT_OFF_CAND        : u64 = 40u64
const SYNWIT_OFF_PROOF       : u64 = 72u64
const SYNWIT_OFF_ADDR        : u64 = 104u64
const SYNWIT_OFF_NCONS       : u64 = 136u64
const SYNWIT_OFF_RESULTS     : u64 = 140u64
const SYNWIT_PAYLOAD_LEN     : u64 = 172u64

var SYNWIT_INITED    : u8 = 0u8
var SYNWIT_PAYLOAD   : [u8; 4096]
var SYNWIT_RESULTS   : [u8; 32]
var SYNWIT_PRED      : [u8; 4096]
var SYNWIT_CAND_ENC  : [u8; 4096]
var SYNWIT_PRODUCER  : [u8; 32]
var SYNWIT_OP        : [u8; 32]
var SYNWIT_INC       : [u8; 32]
var SYNWIT_OUTC      : [u8; 32]
var SYNWIT_ADDR      : [u8; 32]
var SYNWIT_TERM      : [u8; 32]
var SYNWIT_ADDR_SEAL : [u8; 32]
var SYNWIT_ADDRBUF   : [u8; 104]
var SYNWIT_PLEN      : [u64; 1]
var SYNWIT_LIDX      : [u64; 1]
var SYNWIT_KMSG      : [u8; 32]
var SYNWIT_KOUT      : [u8; 32]
var SYNWIT_KREF      : [u8; 32]

fn sw_init() -> i32 @export {
    // TODO: body per Algorithm sw_init -- idempotent set SYNWIT_INITED=1u8, early-return if already 1.
}

fn sw_transcript_address(spec_id: *u8, candidate_id: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm sw_transcript_address -- concat spec||cand||SYNWIT_RESULTS into SYNWIT_ADDRBUF (96B), keccak256_oneshot into out.
}

fn sw_verify_candidate(spec_id: *u8, candidate_id: *u8) -> i32 @export {
    // TODO: body per Algorithm sw_verify_candidate -- guards; sy_get_candidate_encoding; ss_constraint_count;
    //       sentinel while (k<n && done==0u8): ss_get_constraint -> pt_verify-checked obligation -> SYNWIT_RESULTS[k];
    //       return SYNWIT_E_CONSTRAINT_VIOLATED on first false, else SYNWIT_OK. No ordering compares; mask u32->u64.
}

fn sw_emit_verified(spec_id: *u8, candidate_id: *u8, proof_term_id: *u8, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm sw_emit_verified -- guards; W38 re-run sw_verify_candidate; pt_verify gate;
    //       sw_transcript_address seal; frame SYNWIT_PAYLOAD byte-by-byte (Trap5); ident_zero/copy publish ids;
    //       wh_publish(...) single call; sentinel-idx 0xFFFF.. == check -> SYNWIT_E_LOOKUP else SYNWIT_OK.
}

fn sw_replay_transcript(verified_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm sw_replay_transcript -- guards; ws_lookup_id -> SYNWIT_LIDX; wh_get_payload;
    //       validate tag+len; extract proof/addr/results/spec/cand at named offsets; pt_verify; recompute addr;
    //       ident_eq vs SYNWIT_ADDR_SEAL -> SYNWIT_E_TRANSCRIPT on mismatch; else SYNWIT_OK.
}

fn sw_selftest() -> u64 @export {
    // TODO: body per Algorithm sw_selftest -- (a) init idempotence; (b) guards fail closed (not-inited, null);
    //       (c) sw_transcript_address determinism + order-sensitivity vs pinned golden 32B; (d) framing round-trip.
    //       return 99u64 on pass, small nonzero code per failed sub-check.
}
```
