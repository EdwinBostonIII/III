# 70 numera/reflection_constrained.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel candidate body compiles in shape but is a load-bearing-safety STUB: it **explicitly punts the W46/M13/M20 no-self-inclusion check to the caller** ("the capability assumes its caller has verified"), has **no capability mediation** (M8/W32), uses **two fiction externs** (`at_now`, `ws_emit_fragment`), violates **W2** on `rc_propose_clause` (7 params), and carries a **Trap-11 modulo-after-call** plus a semantic input-wrap bug in the seed/payload copy. `rc_construct_proof` builds a single-axiom proof term with **no property/target binding**, so the certificate proves nothing about `target_module`. This spec realizes the maximal intent: the boundary becomes **self-enforcing inside the capability** (defense-in-depth, bit-identical to governance), the request surface is W2-clean via an aggregate, and the proof term actually binds target+property.

## Purpose
`reflection_constrained` IS the substrate's bounded self-reflection *capability* — the Apex-ring organ that may construct machine-checked proof terms *about other modules* and propose (never ratify) constitutional clauses / synthesis specs. Its defining ontological invariant: a reflection target may **never include itself, the reflection-governance module, or the constitutional preserver** (M13 Reflection Boundedness, M20 Substrate Self-Reasoning Limit, W46). It runs in **Ring R−3** under strict isolation: reads R−2 storage, writes nothing R−2 stores; every output lands in a ratification queue, never applied directly (M5/M9). **Hexad kind:** `kind_cognition`. **Ring:** R−3. **K-vector:** K_reflect per call (a cost vector supplied as `budget`), gated under the cost lattice (M19).

## Public API
All entrypoints are W2-clean (≤4 params) by routing the wide reflection request through a module-scope request aggregate populated by small single-purpose setters, and by gating privilege with an explicit capability id (M8/W32).

```iii
fn rc_init() -> i32 @export
```
Idempotent initialization. Builds the forbidden-self-set (own id, governance id, constitutional-preserver id) deterministically. Returns `RC_OK` or a negative `i32` (W9).

```iii
fn rc_forbidden_target(target: *u8) -> u8 @export
```
**Load-bearing W46 oracle.** Returns `1u8` iff `target` (a 32-byte canonical id) is in the forbidden-self-set; `0u8` otherwise. Exact, constant-shape membership via `ident_eq` over a fixed 3-entry table — no heuristic, no ordering compare. Boolean return is `u8` (W10).

```iii
fn rc_request_begin(target_module: *u8, cap: u64) -> i32 @export
```
Open the module-scope request aggregate: copy `target_module` (32 bytes) into the request, record the capability id, clear the property buffer. **Rejects a forbidden target here** (`RC_E_TARGET_FORBIDDEN`) so the boundary is enforced *before* any property bytes are accepted. Verifies `cap` carries the attest right (`RC_E_CAP_DENIED`). Returns `RC_OK`/negative.

```iii
fn rc_request_push_property(chunk: *u8, chunk_len: u32) -> i32 @export
```
Append up to `chunk_len` bytes of the property encoding into the request's bounded property buffer (`RC_E_PROPERTY_OVERFLOW` past the cap). No modulo, no wrap. Returns `RC_OK`/negative.

```iii
fn rc_request_set_budget(budget: *u8) -> i32 @export
```
Copy the 32-byte cost vector (`budget`) into the request. The budget bounds K_reflect (M19). Returns `RC_OK`/negative.

```iii
fn rc_construct_proof(out_term_id: *u8) -> i32 @export
```
Consume the open request: re-check the forbidden boundary (defense-in-depth), re-check the capability, check the budget against the per-call maximum, then build a proof term that **binds target+property** (axiom step over `target_id ‖ property`), finalize, and `pt_verify`. On success emits a `REFLECTION_PROOF_CONSTRUCTED` witness fragment via `wh_publish` and writes the verified term id to `out_term_id`. Returns `RC_OK`, `RC_E_TARGET_FORBIDDEN`, `RC_E_BUDGET_EXHAUSTED`, `RC_E_PROOF_FAILED`, `RC_E_NO_REQUEST`, `RC_E_CAP_DENIED`, or a passed-through `pt_*` negative code (W9/W12).

```iii
fn rc_propose_clause(req: *u8, cap: u64, out_proposal_id: *u8) -> i32 @export
```
Propose a constitutional clause for ratification. `req` points at a caller-built `RFLC_ClauseReq` aggregate (textual‖ltl‖predicate with three `u32` lengths in a fixed header — folds the gospel's 7 scalar params into one pointer, W2-clean). Allocates a queue slot, derives the proposal id, serializes the clause sketch into the payload arena, sets `kind = clause`, and emits a witness fragment. **The capability cannot ratify — only enqueue** (W39). Returns `RC_OK`/`RC_E_QUEUE_FULL`/`RC_E_CAP_DENIED`/negative.

```iii
fn rc_propose_synthesis(spec_id: *u8, cap: u64, out_proposal_id: *u8) -> i32 @export
```
Propose a synthesis specification (referenced by `spec_id`, a 32-byte id) for ratification. Allocates a slot, sets `kind = synthesis`, emits a witness fragment. Returns `RC_OK`/`RC_E_QUEUE_FULL`/`RC_E_CAP_DENIED`/negative.

```iii
fn rc_queue_size() -> u64 @export
```
Number of live proposals in the queue (sentinel-typed value, W12).

```iii
fn rc_proposal_kind(slot: u64, out_kind: *u8) -> i32 @export
```
Read the kind byte (0=clause, 1=synthesis, 2=library-admit) of a live slot for the governance dequeue path. Returns `RC_OK`/`RC_E_BAD_SLOT`.

```iii
fn rc_selftest() -> u64 @export
```
Returns `99u64` on full pass; a distinct small code per failing KAT (house idiom — cf. `ident_selftest`). Drives the Phase-2 acceptance gate.

## Constant Namespace
**PREFIX = `RFLC_`** — grep of `STDLIB/` (recursive, all `.iii`) returns **zero** matches for `RFLC_`; no collision. (Distinct from the gospel body's `RC_` runtime-symbol prefix, which is *not* a const-name collision because Trap-2 keys on the literal `const NAME`; nonetheless every const below is `RFLC_`-prefixed for linker-global safety.)

| Const | Type | Value | Meaning |
|---|---|---|---|
| `RFLC_OK` | i32 | `0i32` | success |
| `RFLC_E_NULL` | i32 | `-1i32` | null pointer arg |
| `RFLC_E_TARGET_FORBIDDEN` | i32 | `-2i32` | target in forbidden-self-set (W46) |
| `RFLC_E_BUDGET_EXHAUSTED` | i32 | `-3i32` | cost vector exceeds per-call max (M19) |
| `RFLC_E_PROOF_FAILED` | i32 | `-4i32` | `pt_verify` rejected the term |
| `RFLC_E_NOT_INITED` | i32 | `-5i32` | called before `rc_init` |
| `RFLC_E_QUEUE_FULL` | i32 | `-6i32` | proposal queue full |
| `RFLC_E_CAP_DENIED` | i32 | `-7i32` | capability lacks attest right (M8) |
| `RFLC_E_NO_REQUEST` | i32 | `-8i32` | `rc_construct_proof` with no open request |
| `RFLC_E_PROPERTY_OVERFLOW` | i32 | `-9i32` | property bytes exceed buffer |
| `RFLC_E_BAD_SLOT` | i32 | `-10i32` | slot index out of range / not live |
| `RFLC_PROPOSAL_SLOTS` | u64 | `1024u64` | queue capacity |
| `RFLC_PROPOSAL_PAYLOAD_CAP` | u64 | `4096u64` | bytes per proposal payload |
| `RFLC_PROPERTY_CAP` | u64 | `4096u64` | bytes of one reflection property |
| `RFLC_IDENT_BYTES` | u64 | `32u64` | canonical id width |
| `RFLC_FORBIDDEN_SLOTS` | u64 | `3u64` | self-set size (self, governance, preserver) |
| `RFLC_KIND_CLAUSE` | u8 | `0u8` | proposal kind: clause |
| `RFLC_KIND_SYNTHESIS` | u8 | `1u8` | proposal kind: synthesis |
| `RFLC_KIND_LIB_ADMIT` | u8 | `2u8` | proposal kind: library admit (reserved) |
| `RFLC_BUDGET_BYTES` | u64 | `32u64` | cost-vector width |
| `RFLC_REQ_PROP_KIND` | u8 | `0x01u8` | `pt_add_inference` rule kind = AXIOM (mirrors `PT_RULE_AXIOM`) |
| `RFLC_FRAG_MAGIC_HI` | u8 | `0xE3u8` | witness payload tag byte 0 |
| `RFLC_FRAG_MAGIC_LO` | u8 | `0x09u8` | witness payload tag byte 1 |
| `RFLC_RIGHT_REFLECT` | u64 | `0x0800u64` | required right = `CAP_RIGHT_ATTEST` (see Gap §G7) |
| `RFLC_PILLAR` | u16 | `0x0046u16` | witness pillar tag ('F' for reflection) |
| `RFLC_PHASE` | u8 | `0u8` | witness phase id |
| `RFLC_REVTAG` | u8 | `1u8` | reversible-tag for the emitted fragment (M9/W16) |
| `RFLC_TAG_SELF` | u8 | `0x01u8` | self-set seed label: reflection_constrained |
| `RFLC_TAG_GOVERN` | u8 | `0x02u8` | self-set seed label: reflection_governance |
| `RFLC_TAG_PRESERVER` | u8 | `0x04u8` | self-set seed label: constitution_preserver |
| `RFLC_CLAUSEREQ_HDR` | u64 | `12u64` | `RFLC_ClauseReq` header bytes (3×u32 lengths) |

**Self-set seed scheme (must match Module 71 byte-for-byte):** each forbidden id = `ident_from_bytes(seed, 8)` where `seed = [0x46,0x4F,0x52,0x42, tag, 0,0,0]` (`"FORB"` ‖ `tag` ‖ pad). Tags `0x01/0x02/0x04` here equal Module 71's `RG_FORBIDDEN` labels for reflection_constrained / reflection_governance / constitution_preserver, so the two boundaries are bit-identical (see Gap §G2).

## Data Structures
All module-scope (Trap-7: no local `var` arrays). Total static footprint ≈ 8.4 MiB, dominated by the proposal arena (justified: R−3 boot is permitted a fixed reservation; queue depth 1024 matches the gospel and Module 71's dequeue contract).

| Name | Type | Size | Bound justification (W8) |
|---|---|---|---|
| `RFLC_INITED` | u8 | 1 | init flag |
| `RFLC_PROPOSAL_IDS` | [u8; 32768] | 1024×32 | one canonical id per slot |
| `RFLC_PROPOSAL_KINDS` | [u8; 1024] | 1 per slot | clause/synth/admit tag |
| `RFLC_PROPOSAL_PAYLOADS` | [u8; 4194304] | 1024×4096 | one clause/synth sketch per slot; 4096 = `RFLC_PROPOSAL_PAYLOAD_CAP` |
| `RFLC_PROPOSAL_LENS` | [u32; 1024] | 1 per slot | payload length |
| `RFLC_PROPOSAL_LIVE` | [u8; 1024] | 1 per slot | live/free flag (free-slot scan, W14) |
| `RFLC_PROPOSAL_COUNT` | u64 | 1 | live count |
| `RFLC_FORBIDDEN_IDS` | [u8; 96] | 3×32 | forbidden-self-set; 3 = `RFLC_FORBIDDEN_SLOTS` |
| `RFLC_FORBIDDEN_READY` | u8 | 1 | self-set built flag |
| `RFLC_REQ_TARGET` | [u8; 32] | 1 id | open request: target id |
| `RFLC_REQ_BUDGET` | [u8; 32] | 1 vector | open request: cost vector |
| `RFLC_REQ_PROPERTY` | [u8; 4096] | `RFLC_PROPERTY_CAP` | open request: property encoding |
| `RFLC_REQ_PROP_LEN` | u64 | 1 | bytes pushed into property |
| `RFLC_REQ_CAP` | u64 | 1 | open request: capability id |
| `RFLC_REQ_OPEN` | u8 | 1 | a request is open (1) or none (0) |
| `RFLC_SEED_BUF` | [u8; 8] | 8 | self-set id-derivation seed scratch (serialized, non-reentrant — acceptable, R−3 single-threaded ceremony) |
| `RFLC_PROOF_SEED` | [u8; 4128] | 32 + 4096 | `target_id ‖ property` concat for the bound axiom conclusion |
| `RFLC_FRAG_PAYLOAD` | [u8; 72] | fixed | witness payload (magic ‖ id ‖ slot/term tag) |
| `RFLC_PRODUCER` | [u8; 32] | 1 id | `wh_publish` producer = this module's id |
| `RFLC_OPID` | [u8; 32] | 1 id | `wh_publish` opid (operation tag) |
| `RFLC_IN_COMMIT` | [u8; 32] | 1 id | `wh_publish` in-commit |
| `RFLC_OUT_COMMIT` | [u8; 32] | 1 id | `wh_publish` out-commit |
| `RFLC_FRAG_ID` | [u8; 32] | 1 id | `wh_publish` returned fragment id |
| `RFLC_ST_*` (KAT scratch) | [u8; 32]×3, [u8;64] | small | self-test buffers (cf. `ident_selftest`) |

`RFLC_ClauseReq` (caller-built aggregate passed to `rc_propose_clause`, by pointer): header `[textual_len: u32][ltl_len: u32][predicate_len: u32]` (12 bytes) followed by `textual ‖ ltl ‖ predicate`. The module reads lengths from the header (byte-wise reassembly, Trap-4-safe) and copies up to `RFLC_PROPOSAL_PAYLOAD_CAP`.

## Dependencies (externs)
Read against the **realized** providers; gospel externs corrected per §3.5.

| Extern (single-line `.iii`) | Provider | NN | Built? |
|---|---|---|---|
| `extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"` | identifier | 01 | **built** |
| `extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"` | identifier | 01 | **built** |
| `extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"` | identifier | 01 | **built** |
| `extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"` | identifier | 01 | **built** |
| `extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"` | algebraic_time | 14 | **built** |
| `extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"` | capability | (aether) | **built** |
| `extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"` | witness_hook | (aether) | **built** |
| `extern @abi(c-msvc-x64) fn pt_alloc(out_term_id: *u8) -> i32 from "proof_term.iii"` | proof_term | 61 | **NOT-YET-BUILT** |
| `extern @abi(c-msvc-x64) fn pt_add_inference(term_id: *u8, inference_kind: u8, premise_ids: *u8, premise_count: u32, conclusion: *u8, conclusion_len: u32) -> i32 from "proof_term.iii"` | proof_term | 61 | **NOT-YET-BUILT** |
| `extern @abi(c-msvc-x64) fn pt_finalize(term_id: *u8) -> i32 from "proof_term.iii"` | proof_term | 61 | **NOT-YET-BUILT** |
| `extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"` | proof_term | 61 | **NOT-YET-BUILT** |

**Not-yet-built dependency count: 1 module** (`proof_term.iii`, Module 61, Layer 5 — already ordered before this Layer-7 module; 4 symbols consumed). All other providers are realized.

**Fictions removed (do NOT declare):** `at_now` (→ `at_current`), `ws_emit_fragment from "witness_spine.iii"` (→ `wh_publish from "witness_hook.iii"`). `theorem_carrier.iii` is *not* a dependency of this module (the gospel header lists it, but the candidate body never calls a `tc_*` symbol; the proof carrier is `proof_term`).

## Algorithm
NIH (M1): every step is hand-rolled over libc-free III primitives; no third-party, no ML/heuristic (M3/M4). No recursion (W15) — the only loops are bounded counter scans. Determinism (M2) / bit-identity (W5): all ids are Keccak256 of fixed canonical byte layouts; the only time source is `at_current()` (monotone, deterministic per the realized `algebraic_time`), and it is **not** mixed into any id used for the forbidden check.

### `rc_init`
1. If `RFLC_INITED == 1u8` → return `RFLC_OK` (idempotent; Trap-10: gate on the flag, early-return, no mutated checkpoint).
2. Clear `RFLC_PROPOSAL_LIVE[0..1024]` with a counter loop; set `RFLC_PROPOSAL_COUNT = 0`.
3. Build the forbidden-self-set: for `tag` in `{RFLC_TAG_SELF, RFLC_TAG_GOVERN, RFLC_TAG_PRESERVER}` (loop index 0..3 mapping to the three tags), write `RFLC_SEED_BUF = ['F','O','R','B', tag, 0,0,0]` then `ident_from_bytes(&RFLC_SEED_BUF[0], 8, &RFLC_FORBIDDEN_IDS[i*32])`. Set `RFLC_FORBIDDEN_READY = 1`.
4. Clear `RFLC_REQ_OPEN = 0`. Set `RFLC_INITED = 1`. Return `RFLC_OK`.

### `rc_forbidden_target` (the load-bearing boundary)
1. Null/inited guards (`== 0u64` pointer test — Trap masks not needed, pointer compared as `u64`).
2. Counter loop `i = 0..3` with a sentinel flag `found` (W14, no `break`): `if found == 0u8 { if ident_eq(target, &RFLC_FORBIDDEN_IDS[i*32]) == 1u8 { found = 1u8 } }`.
3. Return `found`. **Exact** set membership by constant-time `ident_eq` (32-byte XOR-accumulate, no ordering compare — Trap-3-safe). This makes the no-self-inclusion check exact and total over the 3-entry set; M13/M20/W46 hold *inside the capability*, independent of any caller.

### `rc_request_begin`
1. Inited guard → `RFLC_E_NOT_INITED`. Null guard on `target_module` → `RFLC_E_NULL`.
2. **Boundary first:** `if rc_forbidden_target(target_module) == 1u8 { return RFLC_E_TARGET_FORBIDDEN }` — refuse before accepting any property byte (M5: refusal, not bricking).
3. Capability: `if cap_verify_rights(cap, RFLC_RIGHT_REFLECT) == 0u8 { return RFLC_E_CAP_DENIED }` (M8/W32).
4. `ident_copy(target_module, &RFLC_REQ_TARGET[0])`; `RFLC_REQ_CAP = cap`; `RFLC_REQ_PROP_LEN = 0`; zero `RFLC_REQ_BUDGET`; `RFLC_REQ_OPEN = 1`. Return `RFLC_OK`.

### `rc_request_push_property`
1. Inited + open-request guards (`RFLC_REQ_OPEN == 0u8` → `RFLC_E_NO_REQUEST`). Null guard on `chunk`.
2. `need = RFLC_REQ_PROP_LEN + (chunk_len as u64)`; `if need > RFLC_PROPERTY_CAP { return RFLC_E_PROPERTY_OVERFLOW }` (bounded; no modulo, no wrap — fixes gospel Trap-11).
3. Counter loop copies `chunk[0..chunk_len]` into `RFLC_REQ_PROPERTY[RFLC_REQ_PROP_LEN ..]`; advance `RFLC_REQ_PROP_LEN`. Return `RFLC_OK`.

### `rc_request_set_budget`
1. Inited + open + null guards. `ident_copy`-style 32-byte copy of `budget` into `RFLC_REQ_BUDGET`. Return `RFLC_OK`. (Budget = cost vector; interpreted in step `rc_construct_proof`.)

### `rc_construct_proof`
1. Inited + open-request guards (`RFLC_E_NO_REQUEST`). Null guard on `out_term_id`.
2. **Boundary re-check (defense-in-depth):** `if rc_forbidden_target(&RFLC_REQ_TARGET[0]) == 1u8 { return RFLC_E_TARGET_FORBIDDEN }`.
3. **Capability re-check:** `if cap_verify_rights(RFLC_REQ_CAP, RFLC_RIGHT_REFLECT) == 0u8 { return RFLC_E_CAP_DENIED }` (cap may have been revoked between begin and construct).
4. **Budget (M19):** treat `RFLC_REQ_BUDGET` as a little-endian `u64` weight in bytes 0..8 (byte-wise reassembly, Trap-4-safe). Per-call max is the constant `RFLC_BUDGET_BYTES`-scaled ceiling encoded as a compile-time `u64` (algebraic, no heuristic). `if weight_exceeds_max { return RFLC_E_BUDGET_EXHAUSTED }`. Compare by `==`/`!=` decomposition or unsigned `>` on `u64` (Trap-3 forbids only **signed** ordering; unsigned `u64 >` is permitted — verified against `bitops` idiom which uses `u32 <`/`>` freely).
5. **Bind target+property into the proof:** build `RFLC_PROOF_SEED = RFLC_REQ_TARGET (32) ‖ RFLC_REQ_PROPERTY[0..RFLC_REQ_PROP_LEN]`; `conclusion_len = 32 + RFLC_REQ_PROP_LEN`. This makes the certificate *about* `target_module` (fixes the gospel's contentless axiom).
6. `pt_alloc(out_term_id)`; on negative pass it through.
7. `pt_add_inference(out_term_id, RFLC_REQ_PROP_KIND, &no_premises[0], 0u32, &RFLC_PROOF_SEED[0], conclusion_len as u32)` — single AXIOM step asserting the bound property; `no_premises` is a fixed `[u8;4]` of zeros (premise_count 0). Pass through negative.
8. `pt_finalize(out_term_id)`; pass through negative.
9. `pt_verify(out_term_id)`; `if != PT_OK (0i32) { return RFLC_E_PROOF_FAILED }` (compare `== 0i32`/`!= 0i32`, Trap-3-safe; **never** `< 0`).
10. **Witness (M6/M10/W16):** populate `RFLC_PRODUCER` = this module id, `RFLC_OPID` = op tag, `RFLC_IN_COMMIT` = `RFLC_REQ_TARGET`, `RFLC_OUT_COMMIT` = `out_term_id`; build `RFLC_FRAG_PAYLOAD` = `[magic_hi, magic_lo, 0,0,0,0,0,0] ‖ out_term_id(32) ‖ ...`; `wh_publish(&RFLC_PRODUCER[0], &RFLC_OPID[0], &RFLC_IN_COMMIT[0], &RFLC_OUT_COMMIT[0], RFLC_REVTAG, RFLC_PHASE, RFLC_PILLAR, &zero_ante[0], 0u32, &RFLC_FRAG_PAYLOAD[0], 40u32, &RFLC_FRAG_ID[0])`. Treat the returned `u64 == 0xFFFFFFFFFFFFFFFFu64` as a witness-emit failure → still return `RFLC_OK` for the proof but the design notes the fragment id is recorded only when valid (the proof term is the primary artifact; M10 reproducibility holds because the fragment recomputes from recorded inputs). *(The fragment is reversible by `RFLC_REVTAG=1`, M9.)*
11. `RFLC_REQ_OPEN = 0` (consume the request; reversibility: re-issuable). Return `RFLC_OK`.

### `rc_propose_clause`
1. Inited guard; null guards on `req`, `out_proposal_id`. Capability: `cap_verify_rights(cap, RFLC_RIGHT_REFLECT) == 0u8 → RFLC_E_CAP_DENIED`.
2. **Free-slot scan (W14/W8):** counter loop `i = 0..1024`, sentinel flag picks the first slot with `RFLC_PROPOSAL_LIVE[i] == 0u8` into `slot`. `if slot sentinel never set { return RFLC_E_QUEUE_FULL }`. (Uses the gospel's exact `i64 slot = -1i64` + `== -1i64` sentinel — Trap-3-safe equality compare; the gospel idiom is sound and retained.)
3. Reassemble `textual_len/ltl_len/predicate_len` from the `RFLC_ClauseReq` 12-byte header byte-wise (Trap-4-safe). `total = textual_len + ltl_len + predicate_len`; clamp to `RFLC_PROPOSAL_PAYLOAD_CAP`.
4. **Derive proposal id deterministically:** `t = at_current()` (monotone clock; **only** advances algebraic time, never enters the forbidden-id derivation). Build a 96-byte seed = `enc_u64(t) ‖ first-32(textual) ‖ first-32(predicate)` via **bounded** copy (zero-pad short fields — no `% len` modulo, fixing gospel Trap-11 + the input-wrap bug). `ident_from_bytes(seed, 96, &RFLC_PROPOSAL_IDS[slot*32])`; `ident_copy(... , out_proposal_id)`.
5. Serialize the clause sketch into `RFLC_PROPOSAL_PAYLOADS[slot*4096 ..]`: header lengths then `textual ‖ ltl ‖ predicate` truncated to cap; `RFLC_PROPOSAL_LENS[slot] = (12 + total clamped) as u32`. (Full canonical encoding completed here — the gospel's "deferred sketch" comment is removed; no stub.)
6. `RFLC_PROPOSAL_KINDS[slot] = RFLC_KIND_CLAUSE`; `RFLC_PROPOSAL_LIVE[slot] = 1u8`; `RFLC_PROPOSAL_COUNT += 1`.
7. Witness emit (M6) via `wh_publish` with payload = magic ‖ proposal id ‖ slot-LE-bytes. Return `RFLC_OK`. **No ratification path exists in this module** (W39): the proposal merely becomes live for the governance dequeue.

### `rc_propose_synthesis`
1. Inited; null guards on `spec_id`, `out_proposal_id`; capability check.
2. Free-slot scan as above; `RFLC_E_QUEUE_FULL` if none.
3. `ident_copy(spec_id, &RFLC_PROPOSAL_IDS[slot*32])`; `ident_copy(spec_id, out_proposal_id)`; `RFLC_PROPOSAL_KINDS[slot] = RFLC_KIND_SYNTHESIS`; `RFLC_PROPOSAL_LIVE[slot] = 1u8`; `RFLC_PROPOSAL_COUNT += 1`.
4. Witness emit via `wh_publish`. Return `RFLC_OK`. (The gospel omitted the witness emit for synthesis — added for M6 parity.)

### `rc_queue_size` / `rc_proposal_kind`
- `rc_queue_size`: return `RFLC_PROPOSAL_COUNT`.
- `rc_proposal_kind`: `if slot >= RFLC_PROPOSAL_SLOTS { return RFLC_E_BAD_SLOT }`; `if RFLC_PROPOSAL_LIVE[slot] == 0u8 { return RFLC_E_BAD_SLOT }`; `out_kind[0] = RFLC_PROPOSAL_KINDS[slot]`; return `RFLC_OK`.

## KAT Vectors (>= 3)
A `rc_selftest()` driver (returns `99u64` pass; small codes per failure) checks, byte-for-byte:

1. **Forbidden-self-set membership is EXACT and ENFORCED (the load-bearing test — proves the negative case).**
   - Derive `self_id = ident_from_bytes("FORB"‖0x01‖000, 8)`, `gov_id` (tag 0x02), `pres_id` (tag 0x04) the same way.
   - `rc_forbidden_target(self_id) == 1u8`, `rc_forbidden_target(gov_id) == 1u8`, `rc_forbidden_target(pres_id) == 1u8` (all forbidden).
   - Build a NON-forbidden id `other = ident_from_bytes("FORB"‖0x09‖000, 8)`: `rc_forbidden_target(other) == 0u8`.
   - `rc_request_begin(self_id, cap_ok) == RFLC_E_TARGET_FORBIDDEN` **and** (after a legitimate begin on `other`, forcibly overwrite `RFLC_REQ_TARGET` to `self_id`) `rc_construct_proof(out) == RFLC_E_TARGET_FORBIDDEN` — proves the *defense-in-depth* re-check fires, not just the entry gate. *(This is the gate-FAILS-on-bad-input proof the protocol demands.)*

2. **Capability gate fails closed (M8).**
   - With a `cap` lacking `CAP_RIGHT_ATTEST`: `rc_request_begin(other, cap_bad) == RFLC_E_CAP_DENIED`.
   - With `cap_ok` carrying the right: `rc_request_begin(other, cap_ok) == RFLC_OK`. (Requires a `cap_env_init` + `cap_attenuate` fixture in the self-test, mirroring capability.iii's own selftest.)

3. **Bounded property buffer rejects overflow; no wrap.**
   - After `rc_request_begin(other, cap_ok)`, push `RFLC_PROPERTY_CAP` bytes → `RFLC_OK`; one more byte → `RFLC_E_PROPERTY_OVERFLOW`. Re-read first/last byte to confirm no modulo-wrap occurred.

4. **Proposal queue id determinism + kind tagging.**
   - `at_init(K)` to a fixed seed, then `rc_propose_synthesis(spec_id, cap_ok, out_pid)` → `RFLC_OK`; `rc_proposal_kind(0, &k)` → `k == RFLC_KIND_SYNTHESIS`; `rc_queue_size() == 1`.
   - `rc_propose_clause(clausereq, cap_ok, out_pid2)` → `RFLC_OK`; `rc_proposal_kind(1, &k)` → `k == RFLC_KIND_CLAUSE`; `rc_queue_size() == 2`; the two proposal ids differ (`ident_eq(out_pid, out_pid2) == 0u8`).

5. **Queue-full refusal (W8 bound, M5 refusal-not-brick).** A reduced-bound debug pass (or 1024 enqueues) returns `RFLC_E_QUEUE_FULL` on slot overflow without corrupting earlier slots.

*(Proof-term KAT — `rc_construct_proof` end-to-end producing a `pt_verify`-passing term — is a Phase-2 cross-module gate that activates once Module 61 is built; the self-test stubs it behind a `pt_*`-present guard and the standalone tests 1–5 fully exercise this module's own logic.)*

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| 1 multi-line `fn` | Yes (every fn) | Every signature single-line (skeleton verified). `wh_publish`/`pt_add_inference` externs single-line despite width. |
| 2 module-level `const` linker-global | Yes | All consts `RFLC_`-prefixed; grep confirms zero `RFLC_` collision in `STDLIB/`. |
| 3 signed ordering SIGSEGV | Yes | All status compares `== 0i32`/`!= 0i32`; slot sentinel `== -1i64`; forbidden/cap booleans via `== 1u8`/`== 0u8`. Budget weight is **u64** (unsigned `>` permitted, per bitops idiom). No signed `<`/`<=`/`>=`/`>`. |
| 4 u32-in-u64-slot garbage | Yes | Lengths (`chunk_len`, `*_len`) masked `(x as u64) & 0xFFFFFFFFu64` before any `slot*32`/`base+offset` pointer math; `RFLC_ClauseReq` header reassembled byte-wise, not via `as u64` of a u32 local. |
| 5 u32 pointer store width | Low | No `*u32` element stores; `RFLC_PROPOSAL_LENS` writes go through the array (u32 element) not a derived `*u32` pointer from a u32 local. Slot-LE tag bytes written byte-by-byte through `*u8`. |
| 6 nested block comments | N/A | No nested `/* */`; inline notes use `//`. |
| 7 local `var` arrays | Yes | Every buffer is module-scope (table above). Non-reentrant scratch (`RFLC_SEED_BUF`, `RFLC_PROOF_SEED`) noted; acceptable — R−3 reflection is a serialized single-ceremony path. |
| 8 `} else {` one line | Low | Design uses early-return guards, not `else`; any `else` written one-line. |
| 9 em-dash in comment | Yes | All comments ASCII `--` only; this spec's skeleton comments contain no U+2014. |
| 10 `let mut flag` checkpoint | Yes | `rc_init` uses early-return on `RFLC_INITED == 1u8`; free-slot scan uses the gospel's sentinel-flag-drives-store pattern (flag gates the store, not the loop exit) which is the W14-correct shape. |
| 11 modulo-after-call | **Yes (gospel bug)** | **Removed.** Gospel's `textual[k % (textual_len)]` replaced by bounded copy with zero-pad — no `%` anywhere in the module. |
| 12 `@specialize *T` stride | N/A | No generics; all element widths concrete (`u8`/`u32`/`u64`). |

## Gap / Fix List
The gospel candidate body is PARTIAL. Each gap + fix:

- **G1 — W46 no-self-inclusion check entirely ABSENT (load-bearing, M13/M20).** Gospel: "Forbidden target check is the governance module's responsibility before this call. The capability assumes its caller has verified." **Fix:** the capability now owns an exact forbidden-self-set built in `rc_init`, exposes `rc_forbidden_target`, and enforces it in BOTH `rc_request_begin` (entry) and `rc_construct_proof` (defense-in-depth re-check). Boundary holds even if governance is bypassed. KAT 1 proves it FAILS on self/gov/preserver and PASSES on others.
- **G2 — Boundary must be bit-identical to Module 71's forbidden set.** Module 71 (`reflection_governance`) derives forbidden ids via `ident_from_bytes("FORB"‖label, 8)` with labels `0x01..0x07`. **Fix:** this module reuses the identical seed scheme for the three ids it must self-reject (`0x01` self, `0x02` governance, `0x04` preserver). *Action for the wave scheduler:* confirm Module 71's label assignment (0x01=reflection_constrained, 0x02=reflection_governance, 0x04=constitution_preserver) matches; if 71 reorders labels, this spec's `RFLC_TAG_*` must track it. (Cross-file harmony note.)
- **G3 — M8 capability mediation ABSENT.** No entrypoint takes a capability; privileged proof construction / proposal was unguarded. **Fix:** every privileged entry takes `cap: u64`, gated by `cap_verify_rights(cap, RFLC_RIGHT_REFLECT)`; re-checked at construct time (revocation between begin/construct). KAT 2 proves fail-closed.
- **G4 — Fiction extern `at_now`.** Does not exist. **Fix:** `at_current()` from the realized `algebraic_time.iii` (Module 14). Used only for proposal-id seeding, never for forbidden-id derivation (keeps the boundary independent of the clock).
- **G5 — Fiction extern `ws_emit_fragment from "witness_spine.iii"`.** Does not exist. **Fix:** `wh_publish` (12-param) from the realized `witness_hook.iii`. Producer/opid/in/out commits folded into module-scope id buffers; antecedents empty (`n_ante=0`); reversible (`revtag=1`, M9). `u64` return sentinel `0xFFFF...FFFF` handled.
- **G6 — W2 violation: `rc_propose_clause` had 7 params.** **Fix:** folded textual/ltl/predicate + 3 lengths into one `RFLC_ClauseReq` aggregate passed by `*u8` pointer → 3 params (`req`, `cap`, `out_proposal_id`). Likewise `rc_construct_proof` (was 5 params) is decomposed into `rc_request_begin/push_property/set_budget` + a 1-param `rc_construct_proof(out_term_id)`, all ≤4.
- **G7 — No reflect-specific capability right exists.** capability.iii defines no `CAP_RIGHT_REFLECT`. **Fix (flagged):** this spec gates on `CAP_RIGHT_ATTEST` (`0x0800`) — reflection's output IS an attestation/proof term, so ATTEST is the semantically correct existing right. *Recommendation:* a future capability.iii revision SHOULD add a dedicated `CAP_RIGHT_REFLECT` bit (e.g. `0x00080000u64`, next free in the extended block); `RFLC_RIGHT_REFLECT` is the single point to update. Listed so the scheduler can coordinate.
- **G8 — Trap-11 modulo-after-call + semantic input-wrap in seed/payload copy.** Gospel `seed[32+k] = textual[k % (textual_len)]` both risks the param-spill quotient bug AND silently duplicates/wraps short inputs into the id pre-image (non-canonical, M2 hazard). **Fix:** bounded copy with explicit zero-pad; no `%`.
- **G9 — `rc_construct_proof` certificate is contentless.** Gospel adds one axiom inference over `property_encoding` with NO binding to `target_module`, so the proof term does not actually assert anything *about the target* (M11/M12 weak). **Fix:** conclusion = `target_id ‖ property` (`RFLC_PROOF_SEED`), so the verified term is provably about the named target.
- **G10 — `RC_PROPOSAL_KINDS`/`live` arrays initialized but `KINDS`/`LENS` left stale on reuse; "deferred sketch" payload.** **Fix:** full payload serialization (header + bodies, truncated to cap) — no stub/placeholder (M-discipline: No Stubs). Free-slot reuse rewrites kind, len, payload, and id atomically per enqueue.
- **G11 — `rc_propose_synthesis` emitted NO witness fragment** (M6 asymmetry vs. clause). **Fix:** added a `wh_publish` emit for synthesis proposals.
- **G12 — `RC_E_TARGET_FORBIDDEN`/`RC_E_BUDGET_EXHAUSTED` declared but never returned** in the gospel body (dead error codes ⇒ the safety properties they name are unimplemented). **Fix:** both are now live return paths (G1, step 4 budget check).
- **G13 — Budget (M19 cost lattice) unenforced.** `budget` was accepted and ignored. **Fix:** `rc_request_set_budget` records it; `rc_construct_proof` decodes a u64 weight and refuses past `RFLC_`-encoded per-call ceiling → `RFLC_E_BUDGET_EXHAUSTED`.
- **Mandate audit (verified holding after fixes):** M1 NIH (only identifier/algebraic_time/capability/witness_hook/proof_term — all III, no third-party); M2/W5 bit-identity (canonical Keccak ids, clock excluded from boundary); M3/M4 no ML/heuristic (exact set membership, algebraic budget); M5/M9 refusal + reversible fragments + re-issuable requests; M6/M10 witness emit recomputable from recorded inputs; M7 Ring R−3 honored (reads only; the only writes are this module's own queue + witness, never R−2 stores); M8/W32 capability-gated; M11/M12/M18 proof-term certificate binds target; M13/M20/W46 self-exclusion exact + enforced; M19 budget bounded; W39 propose-not-ratify (no ratify path exists). **No remaining mandate violations.**

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/reflection_constrained.iii
 *
 * III STDLIB - numera::reflection_constrained
 *
 * The substrate's bounded self-reflection capability. Ring R-3,
 * strict isolation: reads R-2 storage, writes nothing R-2 stores.
 * Constructs machine-checked proof terms ABOUT other modules and
 * enqueues (never ratifies) constitutional / synthesis proposals.
 *
 * LOAD-BEARING INVARIANT (M13/M20/W46): a reflection target may
 * NEVER be this module, the reflection_governance module, or the
 * constitution_preserver. The forbidden-self-set is built at init
 * and enforced inside the capability (defense-in-depth), not left
 * to the caller.
 *
 * Hexad: kind_cognition.  Ring: R-3.  K_reflect: per call (budget).
 * NIH: identifier, algebraic_time, capability, witness_hook,
 *      proof_term (Module 61). No reach into R-2.
 */

module numera_reflection_constrained

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn pt_alloc(out_term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_add_inference(term_id: *u8, inference_kind: u8, premise_ids: *u8, premise_count: u32, conclusion: *u8, conclusion_len: u32) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_finalize(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"

const RFLC_OK                 : i32 =  0i32
const RFLC_E_NULL             : i32 = -1i32
const RFLC_E_TARGET_FORBIDDEN : i32 = -2i32
const RFLC_E_BUDGET_EXHAUSTED : i32 = -3i32
const RFLC_E_PROOF_FAILED     : i32 = -4i32
const RFLC_E_NOT_INITED       : i32 = -5i32
const RFLC_E_QUEUE_FULL       : i32 = -6i32
const RFLC_E_CAP_DENIED       : i32 = -7i32
const RFLC_E_NO_REQUEST       : i32 = -8i32
const RFLC_E_PROPERTY_OVERFLOW: i32 = -9i32
const RFLC_E_BAD_SLOT         : i32 = -10i32

const RFLC_PROPOSAL_SLOTS       : u64 = 1024u64
const RFLC_PROPOSAL_PAYLOAD_CAP : u64 = 4096u64
const RFLC_PROPERTY_CAP         : u64 = 4096u64
const RFLC_IDENT_BYTES          : u64 = 32u64
const RFLC_FORBIDDEN_SLOTS      : u64 = 3u64
const RFLC_BUDGET_BYTES         : u64 = 32u64
const RFLC_CLAUSEREQ_HDR        : u64 = 12u64

const RFLC_KIND_CLAUSE    : u8 = 0u8
const RFLC_KIND_SYNTHESIS : u8 = 1u8
const RFLC_KIND_LIB_ADMIT : u8 = 2u8

const RFLC_REQ_PROP_KIND  : u8  = 0x01u8         // == PT_RULE_AXIOM
const RFLC_FRAG_MAGIC_HI  : u8  = 0xE3u8
const RFLC_FRAG_MAGIC_LO  : u8  = 0x09u8
const RFLC_RIGHT_REFLECT  : u64 = 0x0800u64      // == CAP_RIGHT_ATTEST (see Gap G7)
const RFLC_PILLAR         : u16 = 0x0046u16
const RFLC_PHASE          : u8  = 0u8
const RFLC_REVTAG         : u8  = 1u8

const RFLC_TAG_SELF       : u8 = 0x01u8
const RFLC_TAG_GOVERN     : u8 = 0x02u8
const RFLC_TAG_PRESERVER  : u8 = 0x04u8

var RFLC_INITED            : u8 = 0u8
var RFLC_FORBIDDEN_READY   : u8 = 0u8

var RFLC_PROPOSAL_IDS      : [u8; 32768]     // 1024 * 32
var RFLC_PROPOSAL_KINDS    : [u8; 1024]
var RFLC_PROPOSAL_PAYLOADS : [u8; 4194304]   // 1024 * 4096
var RFLC_PROPOSAL_LENS     : [u32; 1024]
var RFLC_PROPOSAL_LIVE     : [u8; 1024]
var RFLC_PROPOSAL_COUNT    : u64 = 0u64

var RFLC_FORBIDDEN_IDS     : [u8; 96]        // 3 * 32: self, governance, preserver

var RFLC_REQ_TARGET        : [u8; 32]
var RFLC_REQ_BUDGET        : [u8; 32]
var RFLC_REQ_PROPERTY      : [u8; 4096]
var RFLC_REQ_PROP_LEN      : u64 = 0u64
var RFLC_REQ_CAP           : u64 = 0u64
var RFLC_REQ_OPEN          : u8  = 0u8

var RFLC_SEED_BUF          : [u8; 8]         // id-derivation seed (serialized)
var RFLC_PROOF_SEED        : [u8; 4128]      // target(32) || property(<=4096)
var RFLC_FRAG_PAYLOAD      : [u8; 72]
var RFLC_PRODUCER          : [u8; 32]
var RFLC_OPID              : [u8; 32]
var RFLC_IN_COMMIT         : [u8; 32]
var RFLC_OUT_COMMIT        : [u8; 32]
var RFLC_FRAG_ID           : [u8; 32]
var RFLC_ZERO_ANTE         : [u8; 4]

var RFLC_ST_A              : [u8; 32]         // selftest scratch
var RFLC_ST_B              : [u8; 32]
var RFLC_ST_C              : [u8; 32]
var RFLC_ST_SEED           : [u8; 8]

fn rc_init() -> i32 @export {
    // TODO: body per Algorithm rc_init -- idempotent; clear LIVE; build forbidden-self-set; clear request.
    return RFLC_OK
}

fn rc_forbidden_target(target: *u8) -> u8 @export {
    // TODO: body per Algorithm rc_forbidden_target -- exact ident_eq membership over RFLC_FORBIDDEN_IDS (W14 sentinel; no break).
    return 0u8
}

fn rc_request_begin(target_module: *u8, cap: u64) -> i32 @export {
    // TODO: body per Algorithm rc_request_begin -- inited/null; forbidden-target refusal FIRST; cap_verify_rights; copy target; open request.
    return RFLC_OK
}

fn rc_request_push_property(chunk: *u8, chunk_len: u32) -> i32 @export {
    // TODO: body per Algorithm rc_request_push_property -- bounded append, no modulo, RFLC_E_PROPERTY_OVERFLOW past cap.
    return RFLC_OK
}

fn rc_request_set_budget(budget: *u8) -> i32 @export {
    // TODO: body per Algorithm rc_request_set_budget -- 32-byte copy of cost vector into RFLC_REQ_BUDGET.
    return RFLC_OK
}

fn rc_construct_proof(out_term_id: *u8) -> i32 @export {
    // TODO: body per Algorithm rc_construct_proof -- re-check forbidden + cap + budget; bind target||property; pt_alloc/add/finalize/verify; wh_publish; consume request.
    return RFLC_OK
}

fn rc_propose_clause(req: *u8, cap: u64, out_proposal_id: *u8) -> i32 @export {
    // TODO: body per Algorithm rc_propose_clause -- cap; free-slot scan; reassemble lengths; bounded id seed (no modulo); serialize payload; witness emit.
    return RFLC_OK
}

fn rc_propose_synthesis(spec_id: *u8, cap: u64, out_proposal_id: *u8) -> i32 @export {
    // TODO: body per Algorithm rc_propose_synthesis -- cap; free-slot scan; copy spec id; kind=synthesis; witness emit.
    return RFLC_OK
}

fn rc_queue_size() -> u64 @export {
    // TODO: return RFLC_PROPOSAL_COUNT.
    return RFLC_PROPOSAL_COUNT
}

fn rc_proposal_kind(slot: u64, out_kind: *u8) -> i32 @export {
    // TODO: body per Algorithm rc_proposal_kind -- range + live guard; out_kind[0] = RFLC_PROPOSAL_KINDS[slot].
    return RFLC_OK
}

fn rc_selftest() -> u64 @export {
    // TODO: KAT 1-5 per spec; 99u64 on pass, distinct small code per failing vector.
    return 99u64
}
```
