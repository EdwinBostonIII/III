# 60 numera/curry_howard.iii — Implementation Spec

## Verdict
**PARTIAL** — all five public functions are present and structurally sound, and the gospel's "tag-toggle canonical rewrite" *is* the intended operational Curry-Howard correspondence (not a stub), but the candidate body has two hard dependency defects (both `extern` blocks point at non-existent symbols/files), three trap exposures (local `var` arrays — Trap 7; `let mut` counters — Trap 10/W14; multi-line risk on the witness extern — Trap 1), and the M11 inverse-totality + M19 cost-bound + M10 witness-reproducibility properties are *asserted in prose but neither enforced nor KAT-covered*. None of these change the algorithm; they change the externs, the storage class of scratch buffers, the loop shape, and add the gating + KATs. Closed below.

## Purpose
`numera_curry_howard` is the operational realization of the Curry-Howard correspondence for the III substrate: it IS the bijection between the substrate's *program* encoding (tag byte `0x50` 'P') and its *proof-term* encoding (tag byte `0x54` 'T'). Because the substrate is engineered so that a program serialization is a **syntactic variant** of its proof-term serialization (identical body, differing lead tag), the map and its inverse are a single **canonical structural rewrite** — toggle the tag, copy the body verbatim — and the two directions are exact inverses by construction (clause `cp_curry_howard_total`). The module also publishes witnessed `PROGRAM_FROM_PROOF` (kind `0x15`) and `PROOF_FROM_PROGRAM` (kind `0x16`) fragments so every translation is provenance-anchored.
**Hexad:** `kind_essence + kind_cognition`. **Ring:** R0. **K-vector:** 1.00.

## Public API
All five are `@export`; each is a SINGLE-LINE signature exactly as it must appear.

```
fn ch_program_to_proof(program: *u8, program_len: u64, out_proof: *u8, out_proof_cap: u64, out_len: *u64) -> i32 @export
fn ch_proof_to_program(proof: *u8, proof_len: u64, out_prog: *u8, out_prog_cap: u64, out_len: *u64) -> i32 @export
fn ch_verify_correspondence(program: *u8, program_len: u64, proof: *u8, proof_len: u64) -> u8 @export
fn ch_emit_program_from_proof(proof: *u8, proof_len: u64, out_frag_id: *u8) -> i32 @export
fn ch_emit_proof_from_program(program: *u8, program_len: u64, out_frag_id: *u8) -> i32 @export
```

Return-status conventions:
- `ch_program_to_proof` / `ch_proof_to_program` — `i32` status (W9/W12): `CURRYH_OK (0)` on success, negative error otherwise. `out_len` set only on `OK`.
- `ch_verify_correspondence` — `u8` boolean (W10): `1` = correspond, `0` = do not / malformed / null. (A predicate cannot fail-with-status; W12 satisfied by the sentinel-typed `u8`.)
- `ch_emit_program_from_proof` / `ch_emit_proof_from_program` — `i32` status (W9/W12): `CURRYH_OK` on a published fragment; `CURRYH_E_NULL` on null arg; `CURRYH_E_WITNESS` if the witness publisher refuses (log full / uninit). `out_frag_id` (32 bytes) written only on `OK`.

W2 check: arities are 5,5,4,3,3 — `ch_program_to_proof`/`ch_proof_to_program` are **5 params**, exceeding W2's hard limit of 4. **Fix:** see Gap List G7 — the cap/out_len pair is folded into a 3-field aggregate passed by pointer, OR (preferred, see G7 rationale) the public ABI is retained verbatim because it is the gospel-frozen Curry-Howard surface that Modules 61/62 link against, and the W2 exception is documented. Decision recorded in G7.

## Constant Namespace
**PREFIX = `CURRYH_`** — grep of `STDLIB/` returns **no** `CURRYH_` symbol (zero collisions); prefix is clear. (The gospel body used the shorter `CH_` prefix, which collides in principle with any future `CH_*`; renamed to the assigned `CURRYH_`.)

| const | type | value | note |
|---|---|---|---|
| `CURRYH_OK` | `i32` | `0i32` | success |
| `CURRYH_E_NULL` | `i32` | `-1i32` | a required pointer was null |
| `CURRYH_E_BUF_TOO_SMALL` | `i32` | `-2i32` | `out_*_cap < *_len` |
| `CURRYH_E_MALFORMED` | `i32` | `-3i32` | bad length or wrong lead tag |
| `CURRYH_E_NO_CORRESPONDENCE` | `i32` | `-4i32` | reserved (verify uses `u8`; kept for symmetry / future status form) |
| `CURRYH_E_WITNESS` | `i32` | `-5i32` | **NEW** — `wh_publish` returned the `u64` failure sentinel |
| `CURRYH_TAG_PROGRAM` | `u8` | `0x50u8` | 'P' lead tag |
| `CURRYH_TAG_PROOF` | `u8` | `0x54u8` | 'T' lead tag |
| `CURRYH_FRAG_PROGRAM_FROM_PROOF` | `u8` | `0x15u8` | **NEW (named)** v3 fragment kind (gospel §line 535) |
| `CURRYH_FRAG_PROOF_FROM_PROGRAM` | `u8` | `0x16u8` | **NEW (named)** v3 fragment kind (gospel §line 536) |
| `CURRYH_V3_MAGIC` | `u8` | `0xE3u8` | **NEW (named)** v3 extended-payload sentinel (gospel §line 503) |
| `CURRYH_PAYLOAD_LEN` | `u64` | `72u64` | fixed witness payload size (2 header + 6 pad + 32 in + 32 out) |
| `CURRYH_MAX_BODY` | `u64` | `67108863u64` | **NEW** — bound on body length we will copy / hash (M19); = `wh` 64 MiB payload area − 1. Refuse longer inputs rather than overrun. |

Trap-2 note: every const above carries the `CURRYH_` prefix, so no module-global `L_*` linker symbol collides (verified: no other STDLIB const begins `CURRYH_`).

## Data Structures
The gospel body used **function-local `var [u8; N]` arrays** (`in_c`, `out_c`, `payload`, `producer`, `op`) — **Trap 7 violation** (local var arrays parse only at module scope). All are promoted to module-scope, uniquely prefixed scratch. The module is serialized/non-reentrant (single sponge state in `keccak256.iii` already enforces this); the scratch buffers inherit that contract — documented below.

| name | type | fixed size | bound justification (W8) |
|---|---|---|---|
| `CURRYH_IN_C` | `[u8; 32]` | 32 B | Keccak-256 input-commitment digest (fixed 256-bit) |
| `CURRYH_OUT_C` | `[u8; 32]` | 32 B | Keccak-256 output-commitment digest (fixed 256-bit) |
| `CURRYH_PAYLOAD` | `[u8; 72]` | 72 B | exactly `CURRYH_PAYLOAD_LEN`: 2 tag bytes + 6 reserved + 32 in_commit (off 8) + 32 out_commit (off 40); fixed v3 marker-fragment layout |
| `CURRYH_PRODUCER` | `[u8; 32]` | 32 B | canonical zero identifier (system producer) for `wh_publish` |
| `CURRYH_OP` | `[u8; 32]` | 32 B | canonical zero op-id for `wh_publish` |
| `CURRYH_TAG1` | `[u8; 1]` | 1 B | single-byte staging for the toggled lead tag fed to `keccak256_update` (avoids taking `&` of a `let` local) |
| `CURRYH_FRAG_SINK` | `[u8; 32]` | 32 B | local sink when caller's `out_frag_id` is non-null we copy through; also receives `wh_publish` frag id |

No `[u8; N]` is declared inside any `fn` body (Trap 7 cleared). Reentrancy note: emit functions are **not reentrant** (shared scratch + shared `keccak256` sponge); they are called on the serialized admission path, which is single-threaded by substrate discipline — flagged, acceptable per the same rule that governs `witness_hook.iii` and `keccak256.iii`.

## Dependencies (externs)
Declared **single-line** (Trap 1). The gospel's extern block is **wrong on two counts** and is corrected here:

```
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
```

| symbol | providing module | NN | built? | notes |
|---|---|---|---|---|
| `ident_zero` | `numera/identifier.iii` | (built) | ✅ | confirmed `fn ident_zero(out:*u8)->i32 @export` at identifier.iii:27 |
| `keccak256_init` / `_update` / `_final` | `numera/keccak256.iii` | (built) | ✅ | confirmed @export keccak256.iii:46/52/62. **GOSPEL DEFECT:** body externed these `from "keccak.iii"` — WRONG; `keccak.iii` exports only the low-level sponge (`keccak_state_zero`, `keccak_f1600`, `keccak_absorb`, `keccak_pack_rate_dom`, `keccak_squeeze`). Re-pathed to `keccak256.iii`. (This is the known systemic gospel defect; sibling Module 61 repeats it.) |
| `wh_publish` | `aether/witness_hook.iii` | **07** | ✅ | confirmed @export witness_hook.iii:144. **GOSPEL DEFECT:** body externed `ws_emit_fragment(...) -> i32 from "witness_spine.iii"` — that file and symbol **do not exist** anywhere in STDLIB or the gospel. Re-targeted onto the real canonical fragment publisher `wh_publish` (returns `u64` frag index, `0xFFFFFFFFFFFFFFFFu64` = failure sentinel). |

Dropped externs vs. gospel: `ident_copy` is no longer needed (we copy the frag id with a byte loop / let `wh_publish` write `out_frag_id` directly). **No not-yet-built dependency** — every required symbol is already built. Wave scheduler: Module 60 is **unblocked today**.

## Algorithm

### `ch_program_to_proof` / `ch_proof_to_program` (the canonical rewrite, M11)
Symmetric; describe `ch_program_to_proof` (the inverse swaps tags `0x50`↔`0x54`).
1. Null-guard each pointer via **equality-only** compares: `if (program as u64) == 0u64 { return CURRYH_E_NULL }` (and `out_proof`, `out_len`). (W11 / Trap 3 — never `< 0`.)
2. `if program_len < 1u64 { return CURRYH_E_MALFORMED }` — `u64`, unsigned, no signed-ordering trap; `<` on `u64` is safe (Trap 3 is signed-only).
3. **M19 cost bound:** `if program_len > CURRYH_MAX_BODY { return CURRYH_E_MALFORMED }` — refuse before any copy; guarantees the copy loop is bounded by a compile-time constant (cost lattice closed).
4. Tag check: `if program[0u64] != CURRYH_TAG_PROGRAM { return CURRYH_E_MALFORMED }`.
5. Capacity: `if out_proof_cap < program_len { return CURRYH_E_BUF_TOO_SMALL }`.
6. Write toggled tag: `out_proof[0u64] = CURRYH_TAG_PROOF`.
7. **Verbatim body copy**, byte loop, sentinel-driven counter `i = 1u64 .. program_len` (no `break`; W14). Each `out_proof[i] = program[i]`.
8. `*out_len = program_len`; `return CURRYH_OK`.

**Method (NIH, M1):** a hand-rolled single-tag canonical rewrite — no library, no parser, no normalizer. **Why no normalization engine / no recursion (W15, M19):** the gospel design freezes the program encoding as a syntactic variant of the proof encoding, so the correspondence is *definitionally* a tag toggle + identity on the body. There is no term tree to traverse, hence **no recursion and no explicit term stack are needed** — the only loop is the bounded linear copy of step 7. This is strictly stronger than "non-recursive": it is non-iterative-over-structure (a flat byte copy), and terminating in exactly `program_len ≤ CURRYH_MAX_BODY` steps. **Determinism (M2)/bit-identity (W5):** output is a pure function of the input bytes (toggle one known constant, copy the rest); no time, no allocation, no state read — bit-identical across runs and CPUs.

**Inverse totality (M11 / clause `cp_curry_howard_total`):** for any `b` with `b[0]=0x50`, `ch_proof_to_program(ch_program_to_proof(b)) == b` byte-for-byte, because: toggle('P')→'T'→'P' is identity on the tag, and copy∘copy is identity on the body. Symmetric for a proof input. This is now an explicit KAT (K4/K5) rather than only a prose claim.

### `ch_verify_correspondence` (predicate, M11 inverse witness)
1. `u8`-return null guards (`return 0u8`).
2. `if program_len != proof_len { return 0u8 }`; `if program_len < 1u64 { return 0u8 }`.
3. Lead-tag check both sides: program byte0 == `0x50`, proof byte0 == `0x54`, else `0u8`.
4. **Constant-time-ish XOR accumulate over the body** (offset 1..len): `acc : u32`, `acc = acc | ((program[i] as u32) ^ (proof[i] as u32))`. (Mask: each byte is `as u32` of a `u8` so the high 24 bits are already zero; no Trap-4 pointer math here, and the OR cannot set high garbage — but per W4 the final test uses `if acc == 0u32`.) Loop is sentinel-driven (W14), bounded by `len ≤` the inputs.
5. `if acc == 0u32 { return 1u8 } return 0u8`.
**M2/W5:** pure function of the two byte strings; equality decided algebraically (XOR/OR fold), never a heuristic (M4). No early `break` (W14) — folds the whole body so timing does not leak the first-difference position (defensive; the substrate is deterministic so this is belt-and-suspenders, noted not load-bearing).

### `ch_emit_program_from_proof` (kind `0x15`) and `ch_emit_proof_from_program` (kind `0x16`)
Symmetric; describe `ch_emit_program_from_proof`.
1. Null guards (`proof`, `out_frag_id`) → `CURRYH_E_NULL`.
2. **M19 bound:** `if proof_len > CURRYH_MAX_BODY { return CURRYH_E_MALFORMED }` and `if proof_len < 1u64 { return CURRYH_E_MALFORMED }` — needed so `proof_len - 1u64` in the hash step cannot underflow a `u64` (a 0-length input would make `proof_len - 1u64` wrap to `0xFFFF...` and hand a catastrophic length to `keccak256_update`). **This underflow guard is absent in the gospel body — added (G4).**
3. **Input commitment:** `keccak256_init(); keccak256_update(proof, proof_len); keccak256_final(&CURRYH_IN_C[0u64])`.
4. **Output (program) commitment without materializing the program:** the extracted program is `proof` with byte0 toggled to `0x50` and the body unchanged, so hash it streaming: stage `CURRYH_TAG1[0]=CURRYH_TAG_PROGRAM`; `keccak256_init(); keccak256_update(&CURRYH_TAG1[0u64], 1u64); keccak256_update(((&proof[0u64] as u64)+1u64) as *u8, proof_len - 1u64); keccak256_final(&CURRYH_OUT_C[0u64])`. (Element-address `&proof[1u64]` is expressed as base-plus-offset pointer arithmetic to match house idiom and avoid any `&ARR[expr]` form.)
5. **Build the 72-byte v3 marker payload:** zero is implicit (module-scope `var` is zero-init); set `CURRYH_PAYLOAD[0]=CURRYH_V3_MAGIC (0xE3)`, `CURRYH_PAYLOAD[1]=CURRYH_FRAG_PROGRAM_FROM_PROOF (0x15)`; copy `CURRYH_IN_C[0..31]`→offset 8, `CURRYH_OUT_C[0..31]`→offset 40 via a single sentinel loop `k = 0..32`.
6. **Producer/op = canonical zero id:** `ident_zero(&CURRYH_PRODUCER[0u64]); ident_zero(&CURRYH_OP[0u64])`.
7. **Publish via the real witness spine:** `let fid : u64 = wh_publish(&CURRYH_PRODUCER[0u64], &CURRYH_OP[0u64], &CURRYH_IN_C[0u64], &CURRYH_OUT_C[0u64], 0u8 /*revtag*/, 0u8 /*phase*/, 0u16 /*pillar*/, (0u64 as *u8) /*no antecedents*/, 0u32 /*n_ante*/, &CURRYH_PAYLOAD[0u64], CURRYH_PAYLOAD_LEN as u32, out_frag_id)`.
8. **Failure mapping (M5/M10):** `if fid == 0xFFFFFFFFFFFFFFFFu64 { return CURRYH_E_WITNESS }` (compare-by-equality to the sentinel; Trap 3 / W11 honored — never `< 0`). Else `return CURRYH_OK`. `wh_publish` itself writes `out_frag_id` on success (witness_hook.iii:186-188), so no extra copy.

**M10 witness reproducibility:** `in_commit = Keccak256(proof[0..len])`, `out_commit = Keccak256(0x50 || proof[1..len])`; both are recomputable byte-identically from the recorded `proof` + the constant tag, so the emitted fragment's commitments are reproducible. **M6 chain continuity:** `wh_publish` advances algebraic time and folds the frag id into the append-only chain (witness_hook.iii) — Module 60 inherits proper witness continuity instead of the gospel's stub `ws_emit_fragment` that did not exist. **W16/W17:** the fragment is produced under reversibility (the rewrite is its own inverse) and algebraic time advances monotonically inside `wh_publish`.

## KAT Vectors (>= 3)
A `curryh_kat() -> u64 @export` self-test (return `99u64` = all pass; else first failing case number), using module-scope scratch input buffers (Trap 7).

- **K1 (program→proof tag toggle + body identity).** Input `program = [0x50, 0x61, 0x62, 0x63]` ("Pabc"), `program_len=4`. Expected: `ch_program_to_proof` → `CURRYH_OK`, `out_len=4`, `out_proof = [0x54, 0x61, 0x62, 0x63]` ("Tabc"). Check all 4 bytes.
- **K2 (proof→program inverse direction).** Input `proof = [0x54, 0x61, 0x62, 0x63]`. Expected: `ch_proof_to_program` → `OK`, `out=[0x50,0x61,0x62,0x63]`, `out_len=4`.
- **K3 (verify correspondence true / false).** `ch_verify_correspondence([0x50,0x61,0x62,0x63],4,[0x54,0x61,0x62,0x63],4) == 1u8`; mutate one body byte of the proof (`0x62`→`0x63`) → `== 0u8`; wrong proof tag (`0x55`) → `0u8`; mismatched lengths → `0u8`.
- **K4 (inverse-totality round-trip, M11 / `cp_curry_howard_total`).** For `program = [0x50,0x00,0xFF,0x10,0x54]` (body deliberately contains both tag-valued bytes `0x54`/`0x50` to prove only byte0 is touched), `len=5`: `ch_program_to_proof` then `ch_proof_to_program` reproduces the original 5 bytes exactly. Symmetric proof→program→proof on `[0x54,...]`.
- **K5 (error paths).** `program_len=0` → `CURRYH_E_MALFORMED`; wrong lead tag `0x51` → `CURRYH_E_MALFORMED`; `out_proof_cap=2 < len=4` → `CURRYH_E_BUF_TOO_SMALL`; null `out_len` → `CURRYH_E_NULL`. (Proves the negative cases FAIL, per the substrate's "prove the negative" discipline — not just that valid input passes.)
- **K6 (witness commitment determinism, M10).** Requires `wh_init(0u64)` first. `ch_emit_proof_from_program([0x50,0x61,0x62,0x63],4,&sink)` returns `CURRYH_OK`; recompute `Keccak256("Pabc")` independently via `keccak256_oneshot` and assert it equals `CURRYH_IN_C`; recompute `Keccak256("Tabc")` and assert it equals `CURRYH_OUT_C`. (Anchors M10 reproducibility byte-for-byte.) Keccak-256("") reference for sponge sanity: first byte `0xc5` (per keccak256.iii KAT).
- **K7 (emit underflow guard).** `ch_emit_program_from_proof(&buf, 0u64, &sink)` → `CURRYH_E_MALFORMED` (proves the added `proof_len<1` guard FAILS the zero-length case rather than wrapping `proof_len-1`).

## Trap Exposure
| # | trap | exposed? | avoidance |
|---|---|---|---|
| 1 | multi-line `fn` decl | **YES** (the real `wh_publish` is multi-line in its own source) | every signature **and** the `wh_publish` extern in THIS file are written single-line; my five `fn` defs are single-line. |
| 2 | module-level `const` is linker-global | **YES** | all 14 consts carry `CURRYH_` prefix; grep-verified no `CURRYH_` collision in STDLIB. |
| 3 | signed-ordering compare SIGSEGV | **YES** (status/sentinel handling) | all status/sentinel tests use `==`/`!=` (e.g. `fid == 0xFFFF...u64`, `tag != CURRYH_TAG_PROGRAM`); length compares are on **`u64`** (unsigned — `<` is safe, trap is signed-only). No `i32`/`i64` ordering anywhere. |
| 4 | `u32`-in-`u64`-slot garbage | low | no `u32` local is widened `as u64` for pointer math. The only pointer arithmetic (`(&proof[0]+1)`, `(&ARR)+k`) uses `u64` operands throughout. `payload_len as u32` is a narrowing for the `wh_publish` arg, not a slot read. |
| 5 | `u32` pointer store width | **no** | all byte writes are through `*u8` of `u8` values (`out[i]=program[i]`, payload bytes); never `p[0]=v_u32`. |
| 6 | nested `/* */` | avoid | comments are single-level; inline notes use `//` or `( )`. |
| 7 | local `var [N]` arrays | **YES (gospel violated it)** | all scratch (`CURRYH_IN_C/OUT_C/PAYLOAD/PRODUCER/OP/TAG1/FRAG_SINK`) moved to **module scope**; none declared in a fn body. Non-reentrancy documented (matches `keccak256.iii`/`witness_hook.iii`). |
| 8 | `} else {` one line | minor | the verify/emit bodies prefer early-return; any `} else {` (e.g. tag toggle staging) kept on one physical line. |
| 9 | em-dash in `/* */` | avoid | ASCII `--` only in all comments. |
| 10 | `let mut x = 0u32` flag misbehaves | **YES** (gospel uses `let mut i`/`let mut acc`) | loop counters `i`/`k` are fine as monotonic counters (not checkpoint flags); `acc` in verify is an accumulator, not a 0/1 flag — acceptable. No boolean `let mut` flag drives control flow; predicates use early return. |
| 11 | `a % b` after a call | **no** | the algorithm performs **no modulo** anywhere. |
| 12 | `@specialize *T` stride | **no** | module is not generic; all buffers are concrete `[u8; N]`, stride is 1 byte. |

## Gap / Fix List
- **G1 (M1/dependency, blocking) — wrong keccak path.** Body: `extern keccak256_init/update/final from "keccak.iii"`. `keccak.iii` does **not** export those (only the low-level sponge). **Fix:** `from "keccak256.iii"` (the canonical streaming wrapper; confirmed @export). This is the dispatch-flagged systemic defect.
- **G2 (M6/M10/dependency, blocking) — non-existent witness spine.** Body: `extern ws_emit_fragment(...) -> i32 from "witness_spine.iii"`; neither the file nor the symbol exists in STDLIB or the gospel. **Fix:** re-target onto the real built publisher `wh_publish` from `aether/witness_hook.iii` (Module 07), mapping fields: producer/op = zero-id, in_commit/out_commit = the two Keccak digests, revtag/phase=0, pillar=0, no antecedents, the 72-byte v3 payload, `payload_len=72`, `out_frag_id` passthrough; treat the `u64` `0xFFFF...` return as failure → `CURRYH_E_WITNESS`. Drop the now-unused `ident_copy` extern.
- **G3 (Trap 7, blocking compile) — local `var` arrays.** `let mut in_c : [u8;32]` etc. parse only at module scope in iiis-0. **Fix:** promote all seven scratch buffers to module-scope `var` with `CURRYH_` names (see Data Structures); document non-reentrancy.
- **G4 (M19/safety, correctness) — unguarded `proof_len - 1u64` underflow.** Both emit functions compute `proof_len - 1u64` (resp. `program_len - 1u64`) with only a null guard, no length guard. A zero-length input wraps to `0xFFFFFFFFFFFFFFFFu64` and feeds a catastrophic length to `keccak256_update` → OOB read / SIGSEGV. **Fix:** add `if *_len < 1u64 { return CURRYH_E_MALFORMED }` before the toggled-tag hash (K7 proves the guard fires).
- **G5 (M19 cost bound) — unbounded copy/hash.** The rewrite and the emit hashes are bounded only by the caller's length, with no ceiling — the cost lattice is not closed. **Fix:** introduce `CURRYH_MAX_BODY` and refuse longer inputs in all four length-taking functions; the copy/hash loops are then provably ≤ a compile-time constant (M19 satisfied).
- **G6 (Trap 2 / naming) — prefix collision risk.** Body used `CH_*`. **Fix:** rename every const to the assigned `CURRYH_*`; add named constants for the magic bytes (`CURRYH_V3_MAGIC`, `CURRYH_FRAG_PROGRAM_FROM_PROOF/PROOF_FROM_PROGRAM`) instead of bare `0xE3/0x15/0x16` literals, for auditability against gospel §503/§535/§536.
- **G7 (W2) — 5-param public functions.** `ch_program_to_proof` / `ch_proof_to_program` take 5 params (1 over the W2 limit). **Decision:** **retain the 5-param ABI verbatim** and document the W2 exception, because (a) this is the gospel-frozen Curry-Howard surface that Modules 61 (`proof_term`) and 62 (`theorem_carrier`) link against by exact signature, so an aggregate refactor would desync the whole layer; (b) the W2 rule's intent (spill-bug avoidance, Trap 11 family) is mitigated here because none of the 5 params is a single-use param consumed by a nested call before being read — each is used directly in this frame. The aggregate-by-pointer alternative is noted but **not** adopted to preserve cross-module ABI; Phase 2 must keep the signature exactly as in Public API.
- **G8 (M11 enforcement gap) — inverse totality only asserted.** The gospel states `cp_curry_howard_total` but the body never round-trips. **Fix:** K4 makes the inverse law an executable acceptance gate (program→proof→program and proof→program→proof reproduce the input byte-for-byte, with tag-valued body bytes to prove only byte0 is touched).
- **G9 (W15/M19 clarification) — "non-recursive normalization."** The dispatch flagged that type-checking/normalization must be non-recursive + bounded. **Finding:** the gospel's design has **no normalization step at all** — the correspondence is a flat, bounded byte copy with a single tag toggle. There is therefore no term tree, no recursion, and no need for an explicit term stack; W15 is satisfied vacuously and M19 by `CURRYH_MAX_BODY`. The spec explicitly states this so Phase 2 does **not** over-engineer a term normalizer the encoding does not require (and must not, since that would be unbidden scope and a new cost-unbounded surface).

**Verified-correct (kept from gospel body):** the 72-byte payload framing (`0xE3` v3 magic + kind byte, in_commit@8, out_commit@40) matches sibling witness-emitting modules and gospel §503/§535/§536; the tag constants `0x50`/`0x54`; the XOR/OR equality fold in `ch_verify_correspondence`; the streaming "hash the toggled program without materializing it" technique; the canonical-zero producer/op identifiers.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/curry_howard.iii
 *
 * numera::curry_howard -- the operational Curry-Howard correspondence.
 * Programs (tag 0x50 'P') and proof terms (tag 0x54 'T') are syntactic
 * variants: the map is a canonical structural rewrite -- toggle the lead
 * tag, copy the body verbatim -- and the two directions are exact
 * inverses by construction (clause cp_curry_howard_total, M11). Each
 * translation publishes a witnessed v3 fragment (kind 0x15 / 0x16).
 *
 * Hexad: kind_essence + kind_cognition.  Ring: R0.  K: 1.00.
 * NIH: identifier.iii, keccak256.iii, witness_hook.iii (all built).
 * Non-reentrant: shared module-scope scratch + shared keccak256 sponge;
 *   called on the serialized admission path (cf. witness_hook.iii).
 * Discipline: W2 (5-param CH surface retained by ABI, see spec G7), W9,
 *   W10, W11/Trap3 (equality-only sentinel tests), W14 (sentinel loops,
 *   no break), W15 (no recursion -- the rewrite is a flat bounded copy),
 *   M19 (CURRYH_MAX_BODY bounds every copy/hash).
 */

module numera_curry_howard

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const CURRYH_OK                      : i32 =  0i32
const CURRYH_E_NULL                  : i32 = -1i32
const CURRYH_E_BUF_TOO_SMALL         : i32 = -2i32
const CURRYH_E_MALFORMED             : i32 = -3i32
const CURRYH_E_NO_CORRESPONDENCE     : i32 = -4i32
const CURRYH_E_WITNESS               : i32 = -5i32
const CURRYH_TAG_PROGRAM             : u8  = 0x50u8
const CURRYH_TAG_PROOF               : u8  = 0x54u8
const CURRYH_V3_MAGIC                : u8  = 0xE3u8
const CURRYH_FRAG_PROGRAM_FROM_PROOF : u8  = 0x15u8
const CURRYH_FRAG_PROOF_FROM_PROGRAM : u8  = 0x16u8
const CURRYH_PAYLOAD_LEN             : u64 = 72u64
const CURRYH_MAX_BODY                : u64 = 67108863u64

var CURRYH_IN_C      : [u8; 32]    /* input commitment digest        */
var CURRYH_OUT_C     : [u8; 32]    /* output commitment digest       */
var CURRYH_PAYLOAD   : [u8; 72]    /* v3 marker fragment payload      */
var CURRYH_PRODUCER  : [u8; 32]    /* canonical zero producer id      */
var CURRYH_OP        : [u8; 32]    /* canonical zero op id            */
var CURRYH_TAG1      : [u8; 1]     /* single-byte toggled-tag stage   */
var CURRYH_FRAG_SINK : [u8; 32]    /* frag id sink / KAT scratch      */

/* KAT-only module-scope input buffers (Trap 7: no local var arrays). */
var CURRYH_KAT_PROG  : [u8; 8]
var CURRYH_KAT_PROOF : [u8; 8]
var CURRYH_KAT_OUT   : [u8; 8]
var CURRYH_KAT_RT    : [u8; 8]
var CURRYH_KAT_REF   : [u8; 32]

fn ch_program_to_proof(program: *u8, program_len: u64, out_proof: *u8, out_proof_cap: u64, out_len: *u64) -> i32 @export {
    // TODO: body per Algorithm "ch_program_to_proof": null guards (==0u64),
    // program_len<1 -> MALFORMED, program_len>CURRYH_MAX_BODY -> MALFORMED,
    // tag check 0x50, cap check, out_proof[0]=0x54, sentinel copy 1..len, *out_len.
}

fn ch_proof_to_program(proof: *u8, proof_len: u64, out_prog: *u8, out_prog_cap: u64, out_len: *u64) -> i32 @export {
    // TODO: body per Algorithm (inverse of above): tag check 0x54,
    // out_prog[0]=0x50, sentinel copy, M19 bound, *out_len.
}

fn ch_verify_correspondence(program: *u8, program_len: u64, proof: *u8, proof_len: u64) -> u8 @export {
    // TODO: body per Algorithm "ch_verify_correspondence": u8 null guards,
    // len-equal, len>=1, tags 0x50/0x54, XOR|OR fold over body, acc==0 -> 1u8.
}

fn ch_emit_program_from_proof(proof: *u8, proof_len: u64, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm "ch_emit_program_from_proof": null guards,
    // proof_len in [1, CURRYH_MAX_BODY] (G4 underflow guard), in_commit =
    // Keccak256(proof), out_commit = Keccak256(0x50 || proof[1..]),
    // build 72B payload (0xE3,0x15, in@8,out@40), zero producer/op,
    // wh_publish(...), fid==0xFFFFFFFFFFFFFFFFu64 -> CURRYH_E_WITNESS.
}

fn ch_emit_proof_from_program(program: *u8, program_len: u64, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm "ch_emit_proof_from_program": as above with
    // tag 0x54 and kind 0x16; out_commit = Keccak256(0x54 || program[1..]).
}

fn curryh_kat() -> u64 @export {
    // TODO: K1..K7 per KAT Vectors; return 99u64 on all-pass else first failing case.
}
```
