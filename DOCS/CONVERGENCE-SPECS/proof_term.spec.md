# 61 numera/proof_term.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is a near-complete, structurally sound proof-term store + replay verifier (7 public fns, all with real bodies), but it is **not buildable as written**: it externs `keccak256_init/update/final from "keccak.iii"` (systemic gospel defect — those live in `keccak256.iii`), it depends on a non-existent `ws_emit_fragment from "witness_spine.iii"` (no such module/symbol in the tree; the realized substrate publishes fragments via `aether/witness_hook.iii::wh_publish`), and it uses function-local `var seed/clen_buf/out_c/payload/producer/op/in_c : [u8; N]` arrays plus `&ARR[expr]` element-addressing — both forbidden by the iiis trap catalog (Traps 7 + element-address lowering). The verifier core is also **structurally shallow** relative to the maximal intent: it checks premise-DAG acyclicity and per-rule arity but does *not* replay the actual inference (no conclusion-vs-premise structural match), so M11/M18 are only partially honored. This spec closes every gap and raises the verifier to a real per-rule conclusion check, and adds the Curry-Howard bridge (Module 60) the dispatch calls for.

## Purpose
`numera_proof_term` makes a **proof term a first-class, checkable substrate artifact**: a finalized sequence of inference steps (each = a rule kind, a list of premise-step indices, and a serialized conclusion) that the universal checker `pt_verify` replays deterministically, step by step, accepting only if every step is a valid instance of its declared rule over already-proven premises. Verified terms emit a `PROOF_TERM_CONSTRUCTED` witness fragment and serialize to a canonical byte encoding for transport (M18 theorem-carrier discipline). This is the operational core of Curry-Howard (M11): a program admitted to the substrate carries an extractable proof term, and a proof term carries an extractable program (the `pt_*` ↔ `ch_*` bridge). The checker is small and audited; per M20/M13 the substrate never proves its own checker sound via self-generated proofs, and reflection is bounded (no term may cite itself; checking is non-recursive over an explicit DAG).
- **Hexad:** kind_essence + kind_witness + kind_cognition.
- **Ring:** R0.
- **K-vector:** 1.00.

## Public API
All public fns return `i32` status (W9 negative-i32 errors; W12 every public fn returns a status). Single-line signatures, paste-ready:

```
fn pt_init() -> i32 @export
fn pt_alloc(out_term_id: *u8) -> i32 @export
fn pt_add_inference(args: *u8) -> i32 @export
fn pt_finalize(term_id: *u8) -> i32 @export
fn pt_verify(term_id: *u8) -> i32 @export
fn pt_emit_constructed(term_id: *u8, out_frag_id: *u8) -> i32 @export
fn pt_serialize(term_id: *u8, out_buf: *u8, out_cap: u64, out_len: *u64) -> i32 @export
fn pt_deserialize(in_buf: *u8, in_len: u64, out_term_id: *u8) -> i32 @export
fn pt_to_program(term_id: *u8, out_prog: *u8, out_cap: u64, out_len: *u64) -> i32 @export
fn pt_kat() -> u64 @export
```

**W2 reconciliation (load-bearing):** the gospel's `pt_add_inference(term_id, inference_kind, premise_ids, premise_count, conclusion, conclusion_len)` has **6 parameters** — a hard W2 violation (max 4). The spec replaces it with a single `args: *u8` pointer to a caller-filled module-scope-shaped argument record (`PT_ADDARG_*` layout below), so the public arity is 1. `pt_serialize` (4 params) and `wh_publish` consumption are within bound. `pt_deserialize`, `pt_to_program`, `pt_kat` are spec additions (see Gap list) and are each ≤4 params.

**Return conventions per fn:**
- `pt_init` → `PT_OK` (idempotent; re-init returns `PT_OK`).
- `pt_alloc` → `PT_OK` and writes 32-byte id to `out_term_id`; `PT_E_FULL` if no free slot; `PT_E_NOT_INITED`; `PT_E_NULL`.
- `pt_add_inference` → `PT_OK`; `PT_E_ABSENT` (unknown term), `PT_E_ALREADY_FINAL`, `PT_E_TOO_MANY_STEPS`, `PT_E_NULL`, `PT_E_NOT_INITED`, `PT_E_BAD_ARG` (premise count > 8 or conclusion_len > 512).
- `pt_finalize` → `PT_OK`; `PT_E_ABSENT`, `PT_E_ALREADY_FINAL`.
- `pt_verify` → `PT_OK` if every step valid; first failing step yields `PT_E_INVALID_INFERENCE`; `PT_E_NOT_FINAL` if not finalized.
- `pt_emit_constructed` → `PT_OK`; `PT_E_INVALID_INFERENCE` if term not yet verified (must call `pt_verify` first); `PT_E_NULL`.
- `pt_serialize` → `PT_OK` + `*out_len`; `PT_E_BUF_TOO_SMALL`.
- `pt_deserialize` → `PT_OK` + new term id (live, **not** finalized — caller re-finalizes then re-verifies; never trust a deserialized term, M17/M18); `PT_E_MALFORMED`, `PT_E_FULL`.
- `pt_to_program` → `PT_OK` + `*out_len` (Curry-Howard extraction); `PT_E_BUF_TOO_SMALL`, `PT_E_INVALID_INFERENCE` if unverified.
- `pt_kat` → `99u64` on full pass, else a nonzero failing-vector code (self-test convention, matches `keccak256_kat`).

## Constant Namespace
PREFIX = `PT_` — **no symbol collision.** `grep ^const PT_` over `STDLIB/` returned zero matches. A broader `\bPT_[A-Z]` grep found the prefix used elsewhere but with **non-overlapping names**: `omnia/pattern_table.iii` declares `PT_DOM_TBL` / `PT_DIGEST_OUT` (its own "pattern table" namespace), and a corpus test (`build/corpus/_ed_point_test.iii`, not linked into STDLIB) uses locals `PT_R/PT_ACC/PT_B`. None of those names match any constant/var below, so there is **no `L_<NAME>` linker conflict** (Trap 2: module-level `const`/`var` emit linker-global `L_<NAME>`; collision is per exact name, not per prefix). All names below are unique tree-wide. If Phase 2 prefers prefix-level isolation, `PTERM_` is available and also collision-free — but `PT_` (the gospel's prefix) is safe as-is.

Module-level consts (name : type = value):
```
const PT_OK                  : i32 =  0i32
const PT_E_NULL              : i32 = -1i32
const PT_E_FULL              : i32 = -2i32
const PT_E_ABSENT            : i32 = -3i32
const PT_E_INVALID_INFERENCE : i32 = -4i32
const PT_E_NOT_FINAL         : i32 = -5i32
const PT_E_ALREADY_FINAL     : i32 = -6i32
const PT_E_BUF_TOO_SMALL     : i32 = -7i32
const PT_E_NOT_INITED        : i32 = -8i32
const PT_E_TOO_MANY_STEPS    : i32 = -9i32
const PT_E_BAD_ARG           : i32 = -10i32   // spec addition: premise/conclusion bound breach
const PT_E_MALFORMED         : i32 = -11i32   // spec addition: pt_deserialize bad encoding

const PT_SLOTS               : u64 = 256u64
const PT_MAX_STEPS           : u64 = 1024u64
const PT_MAX_PREMISES        : u64 = 8u64      // spec addition: per-step premise cap (matches 8-wide store)
const PT_CONCLUSION_BYTES    : u64 = 512u64
const PT_ID_BYTES            : u64 = 32u64     // spec addition: name the 32-byte id width

const PT_RULE_AXIOM          : u8 = 0x01u8
const PT_RULE_MODUS_PONENS   : u8 = 0x02u8
const PT_RULE_GENERALIZATION : u8 = 0x03u8
const PT_RULE_INDUCTION_BASE : u8 = 0x04u8
const PT_RULE_INDUCTION_STEP : u8 = 0x05u8
const PT_RULE_SUBSTITUTION   : u8 = 0x06u8
const PT_RULE_LIBRARY_CITE   : u8 = 0x07u8
const PT_RULE_REFLEXIVITY    : u8 = 0x08u8
const PT_RULE_SYMMETRY       : u8 = 0x09u8
const PT_RULE_TRANSITIVITY   : u8 = 0x0Au8
const PT_RULE_CASE_ANALYSIS  : u8 = 0x0Bu8
const PT_RULE_MAX            : u8 = 0x0Bu8     // spec addition: highest valid rule id (range gate)

const PT_SER_TAG             : u8 = 0x54u8     // 'T' canonical proof-term encoding tag (matches CH_TAG_PROOF)
const PT_PROG_TAG            : u8 = 0x50u8     // 'P' program tag (Curry-Howard, matches CH_TAG_PROGRAM)
const PT_FRAG_KIND           : u8 = 0x14u8     // PROOF_TERM_CONSTRUCTED v3 fragment kind (gospel payload[1]=0x14)
const PT_FRAG_MAGIC          : u8 = 0xE3u8     // v3 fragment payload magic (gospel payload[0]=0xE3)
const PT_WH_PHASE            : u8 = 0u8        // wh_publish phase byte for proof-term fragments
const PT_WH_PILLAR           : u16 = 0u16      // wh_publish pillar id
const PT_WH_REVTAG           : u8 = 0u8        // wh_publish reversibility tag (reversible)
```
All const values are pure literals (Trap 11 has no modulo here). No `—` em-dash inside any `/* */` comment (Trap 9): all annotations use ASCII `--` or `//`.

## Data Structures
Every buffer is a fixed module-scope array (W8). The store is a flat slot×step layout identical to the gospel; spec additions are the hoisted scratch buffers (Trap 7) and the arg record. Backing-type note: byte buffers are declared `[u8; N]` exactly as the gospel and the `keccak256.iii` exemplar do; sizes below are byte capacities.

State / liveness (one entry per slot, `PT_SLOTS`=256):
```
var PT_INITED              : u8 = 0u8
var PT_TERM_IDS            : [u8; 8192]        // 256 * 32  -- canonical term ids
var PT_LIVE                : [u8; 256]
var PT_FINAL               : [u8; 256]
var PT_VERIFIED            : [u8; 256]
var PT_STEP_COUNTS         : [u32; 256]
```
Per-step arrays (slot s, step k indexed by `idx = s*PT_MAX_STEPS + k`; 256*1024 = 262144 steps):
```
var PT_STEP_KINDS          : [u8;  262144]
var PT_STEP_PREMISE_COUNTS : [u32; 262144]
var PT_STEP_PREMISES       : [u32; 2097152]    // 262144 * 8  (PT_MAX_PREMISES)
var PT_STEP_CONCL_LENS     : [u32; 262144]
var PT_STEP_CONCLUSIONS    : [u8;  134217728]  // 262144 * 512 (PT_CONCLUSION_BYTES) = 128 MiB
```
**Bound justification (W8):** 256 concurrent proof terms × 1024 steps × 512-byte conclusions is the gospel's stated capacity (Reflection Boundedness M13: a proof term cannot grow unboundedly). Total static footprint ≈ 128 MiB conclusions + 8 MiB premises + small tables, well inside the small-code-model 2 GiB RIP-relative reach. No down-scaling (the gospel capacity is retained verbatim per the no-practicality rule).

`pt_add_inference` argument record (replaces the 6-param gospel signature; caller fills then passes `&PT_ADDARG_*`-shaped pointer; layout is a fixed scratch the caller populates field-by-field, or any equivalently-laid-out 24-byte header + premises + conclusion region):
```
// args layout (little-endian), total = 24 + 4*premise_count + conclusion_len bytes:
//   off  0  : u8[32]  term_id            (the target term)
//   off 32  : u8      inference_kind
//   off 33  : u8[3]   pad
//   off 36  : u32     premise_count      (<= PT_MAX_PREMISES)
//   off 40  : u32     conclusion_len     (<= PT_CONCLUSION_BYTES)
//   off 44  : u32[premise_count]  premise step indices (LE)
//   off ... : u8[conclusion_len] conclusion bytes
var PT_ADDARG_SCRATCH      : [u8; 600]         // 44 + 32 + 512 rounded -- caller-side fill buffer (single-arg ABI)
```
Hoisted scratch (Trap 7 — all were function-local `var [u8;N]` in the gospel body; reentrancy note below):
```
var PT_SEED                : [u8; 16]          // pt_alloc id-seed ("pt_term_" || slot-LE)
var PT_CLEN_BUF            : [u8; 4]           // pt_emit_constructed step-count LE
var PT_OUT_COMMIT          : [u8; 32]          // pt_emit_constructed output commitment hash
var PT_PAYLOAD             : [u8; 40]          // pt_emit_constructed fragment payload (magic||kind||6 pad||id32)
var PT_PRODUCER            : [u8; 32]          // zero producer id
var PT_OP                  : [u8; 32]          // zero op id
var PT_IN_COMMIT           : [u8; 32]          // pt_emit_constructed input commitment (= term id)
var PT_HASHBUF             : [u8; 552]         // pt_verify per-step canonical-hash scratch (kind||plen||premises||clen||concl)
var PT_KAT_ID              : [u8; 32]          // pt_kat term-id sink
var PT_KAT_FRAG            : [u8; 32]          // pt_kat fragment-id sink
var PT_KAT_BUF             : [u8; 4096]        // pt_kat serialize round-trip buffer
var PT_KAT_CONCL           : [u8; 64]          // pt_kat conclusion scratch
```
**Reentrancy (Trap 7 caveat):** module-scope scratch makes the hashing/emit/serialize paths non-reentrant. Acceptable: proof-term construction and verification are serialized substrate ceremonies (single-threaded, like the `keccak256.iii` and `aether/witness_hook.iii` exemplars which use the same module-scope-scratch convention). Documented here per the briefing requirement.

## Dependencies (externs)
Each is canonical and present in the tree **except** where marked not-yet-built. The gospel's defective `from "keccak.iii"` / `from "witness_spine.iii"` strings are corrected here:

```
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn ch_proof_to_program(proof: *u8, proof_len: u64, out_prog: *u8, out_prog_cap: u64, out_len: *u64) -> i32 from "curry_howard.iii"
```

| Provider | NN | Status |
|---|---|---|
| `identifier.iii` | 01 | **built** (verified: `ident_zero/eq/copy/from_bytes` present, 32-byte ids) |
| `keccak256.iii` | (Stage-4) | **built** (verified: `keccak256_oneshot` present; this is the canonical hash wrapper) |
| `witness_hook.iii` | 07 | **built** (verified: `wh_publish` present — the realized `ws_emit_fragment`) |
| `curry_howard.iii` | 60 | **NOT-YET-BUILT** (parallel wave; only `pt_to_program` consumes `ch_proof_to_program`) |

**Wave-scheduler note:** the 7 gospel-core fns (`pt_init/alloc/add_inference/finalize/verify/emit_constructed/serialize`) have **zero not-yet-built deps** — proof_term can build and self-test independently of Module 60. Only the spec-added `pt_to_program` bridge depends on curry_howard (Module 60). Schedule Module 60 before final integration, but proof_term's KAT does not require it (the bridge KAT is gated behind a `ch_*`-present check, or deferred to Module 60's KAT).

**Keccak reconciliation (decisive):** `identifier.iii`'s own header documents why streaming `keccak256_init/update/final` is unsafe here — "iiis clobbers param registers across the init() call (param-spill trap), so the hashing paths use `keccak256_oneshot` over a single contiguous buffer." proof_term therefore hashes by assembling the bytes into a module-scope contiguous buffer (`PT_HASHBUF` / `PT_PAYLOAD`) and calling `keccak256_oneshot` **once**, never the streaming triple. This also eliminates the gospel's `keccak.iii` path defect entirely.

## Algorithm
NIH (M1): every primitive (slot scan, LE pack, premise-DAG check, per-rule conclusion match, canonical serialize) is hand-rolled over libc-free III. No ML/heuristics (M3/M4): all checks are exact structural/algebraic equalities. Determinism (M2) + bit-identity (W5): the store is fixed-layout, ids are `keccak256_oneshot` over canonical LE bytes, the fragment payload is byte-fixed, and verification is a deterministic replay with no data-dependent timing decisions. No recursion (W15): the premise DAG is checked by an explicit forward scan (premise index `< step`), never by recursive descent. No `break` (W14): every loop uses a `sentinel`/counter the loop condition reads.

**`pt_init`** — idempotent: if `PT_INITED==1` return `PT_OK`; else zero `PT_LIVE/FINAL/VERIFIED/STEP_COUNTS` over `i in 0..PT_SLOTS` (counter loop), set `PT_INITED=1`, return `PT_OK`.

**`pt_alloc(out_term_id)`** — guard inited + non-null. Sentinel-scan `PT_LIVE[i]==0` for the first free slot `s` (W14 sentinel; no break). If none, `PT_E_FULL`. Build `PT_SEED` = ASCII "pt_term_" (8 bytes) || `s` as 4 LE bytes || 4 zero bytes (16 bytes total). `ident_from_bytes(&PT_SEED, 16, &PT_TERM_IDS[s*32])` (keccak256-derived canonical id). `ident_copy(&PT_TERM_IDS[s*32], out_term_id)`. Set `PT_LIVE[s]=1, PT_FINAL[s]=0, PT_VERIFIED[s]=0, PT_STEP_COUNTS[s]=0`. Return `PT_OK`. (Element-address `&PT_TERM_IDS[s*32]` lowered as `((&PT_TERM_IDS as u64) + s*32u64) as *u8` — see Trap Exposure.)

**`pt_find_slot(term_id) -> i64`** (internal) — sentinel-scan live slots, `ident_eq(&PT_TERM_IDS[i*32], term_id)==1` ⇒ `found=i as i64`, sentinel=1. Return `found` (`-1i64` if absent). `found == -1i64` tested by **equality only** (W11/Trap 3).

**`pt_add_inference(args)`** — guard inited + non-null `args`. Read `term_id` = `args[0..32]`; `pt_find_slot` ⇒ `s` (or `PT_E_ABSENT`). If `PT_FINAL[s]==1` ⇒ `PT_E_ALREADY_FINAL`. Read `inference_kind=args[32]`, `premise_count=LE(args[36..40])`, `conclusion_len=LE(args[40..44])`. Bound-gate: `premise_count > PT_MAX_PREMISES` or `conclusion_len > PT_CONCLUSION_BYTES` ⇒ `PT_E_BAD_ARG` (M19 cost-lattice bound). Range-gate `inference_kind`: must be `1u8..PT_RULE_MAX` (compared via the explicit rule-dispatch in verify; an out-of-range kind is recorded and rejected at verify time). `step = PT_STEP_COUNTS[s]`; if `step >= PT_MAX_STEPS` ⇒ `PT_E_TOO_MANY_STEPS`. `idx = s*PT_MAX_STEPS + step`. Store `PT_STEP_KINDS[idx]=inference_kind`, `PT_STEP_PREMISE_COUNTS[idx]=premise_count`. Loop `i in 0..premise_count`: read 4 LE bytes from `args[44 + i*4 ..]` into u32 `p`, store `PT_STEP_PREMISES[idx*8 + i]=p`. Store `PT_STEP_CONCL_LENS[idx]=conclusion_len`; copy `conclusion_len` bytes from `args[44 + premise_count*4 ..]` into `PT_STEP_CONCLUSIONS[idx*512 ..]`. `PT_STEP_COUNTS[s]=step+1`. Return `PT_OK`. (No `%` anywhere — Trap 11 N/A.)

**`pt_finalize(term_id)`** — guard; `pt_find_slot`; if already final ⇒ `PT_E_ALREADY_FINAL`; set `PT_FINAL[s]=1`; return `PT_OK`. After finalize, `pt_add_inference` is refused — terms are immutable once finalized (M18 carrier discipline).

**`pt_verify_step(slot, step) -> i32`** (internal, the **maximal** core — strengthened beyond the gospel) — `idx = slot*PT_MAX_STEPS + step`; `kind=PT_STEP_KINDS[idx]`, `pcount=PT_STEP_PREMISE_COUNTS[idx]`. (1) **DAG/acyclicity (M13):** every premise `p = PT_STEP_PREMISES[idx*8+i]` must satisfy `p < step` (forward reference only — a step may only cite earlier steps), except `PT_RULE_LIBRARY_CITE` whose single premise is an admitted-library index, not an in-term step. Checked by a sentinel scan; any violation ⇒ `PT_E_INVALID_INFERENCE`. (2) **Per-rule arity + conclusion replay** (the gap the gospel left open — see Gap list): a `when`-style cascade on `kind` (one-line `} else {` per Trap 8) that checks arity AND the structural relation between the premises' conclusions and this step's conclusion:
   - `AXIOM` / `INDUCTION_BASE` / `REFLEXIVITY`: `pcount==0`; conclusion non-empty.
   - `MODUS_PONENS`: `pcount==2`; premise[0] conclusion must canonically encode `A` and premise[1] encode `A ⇒ B`, this step's conclusion must equal `B` (byte-compare the `B`-suffix of premise[1] against this conclusion). Exact byte-equality, no heuristic.
   - `GENERALIZATION` / `INDUCTION_STEP` / `SYMMETRY` / `LIBRARY_CITE`: `pcount==1`.
   - `SUBSTITUTION`: `pcount>=1`.
   - `TRANSITIVITY`: `pcount==2`; premise[0]=`a R b`, premise[1]=`b R c`, conclusion=`a R c` — check the shared-middle `b` bytes match and the conclusion's `a`/`c` ends match the premises (exact byte compare).
   - `CASE_ANALYSIS`: `pcount>=2`.
   - unknown/out-of-range kind ⇒ `PT_E_INVALID_INFERENCE`.
   The conclusion bytes for the comparison are read from `PT_STEP_CONCLUSIONS`; comparison is an exact byte loop (no float, no hash-collision shortcut). Determinism: identical step bytes ⇒ identical verdict, every run.

**`pt_verify(term_id)`** — guard; `pt_find_slot` ⇒ `s`; if `PT_FINAL[s]==0` ⇒ `PT_E_NOT_FINAL` (only finalized terms verify). `count=PT_STEP_COUNTS[s]`. Sentinel loop `i in 0..count` (W14): `r=pt_verify_step(s,i)`; first `r!=PT_OK` records `result=r`, sentinel=1 (no break). If `result==PT_OK` set `PT_VERIFIED[s]=1`. Return `result`. Non-recursive (W15): a flat forward pass; because every premise index `< step` was enforced at each step, the DAG is acyclic and a single forward pass suffices — no fixpoint, no recursion.

**`pt_emit_constructed(term_id, out_frag_id)`** — guard; `pt_find_slot` ⇒ `s`; if `PT_VERIFIED[s]==0` ⇒ `PT_E_INVALID_INFERENCE` (never emit a fragment for an unverified term — M6/M10). Compute output commitment: assemble `PT_TERM_IDS[s*32..]` (32 bytes) || `PT_CLEN_BUF` (step count, 4 LE bytes) into a contiguous region and `keccak256_oneshot` ⇒ `PT_OUT_COMMIT`. Build `PT_PAYLOAD` (40 bytes): `[0]=PT_FRAG_MAGIC(0xE3)`, `[1]=PT_FRAG_KIND(0x14)`, `[2..8]=0`, `[8..40]=term id`. `ident_zero(&PT_PRODUCER)`, `ident_zero(&PT_OP)`, `ident_copy(term id -> &PT_IN_COMMIT)`. Call `wh_publish(&PT_PRODUCER, &PT_OP, &PT_IN_COMMIT, &PT_OUT_COMMIT, PT_WH_REVTAG, PT_WH_PHASE, PT_WH_PILLAR, 0-null-antecedents, 0, &PT_PAYLOAD, 40, out_frag_id)`. `wh_publish` returns the `u64` fragment index; map `0xFFFFFFFFFFFFFFFF` ⇒ `PT_E_FULL`, else `PT_OK` (the 32-byte frag id is written to `out_frag_id` by `wh_publish`). M10 witness reproducibility: every input to `wh_publish` is recorded/derivable, so the fragment id recomputes byte-identically. (This replaces the gospel's phantom `ws_emit_fragment`; semantics are preserved — producer/op zero, in_commit=term id, out_commit=hash, payload identical.)

**`pt_serialize(term_id, out_buf, out_cap, out_len)`** — exactly the gospel algorithm (it is correct and trap-free in shape): compute `needed = 1 + 32 + 4 + Σ_steps(1 + 4 + 4*pc + 4 + cl)`; if `out_cap < needed` ⇒ `PT_E_BUF_TOO_SMALL`. Write `PT_SER_TAG(0x54)`, then 32-byte id, then step count (LE), then per step: kind byte, premise_count (LE), each premise (LE), conclusion_len (LE), conclusion bytes. `*out_len = cursor`. Canonical, deterministic, bit-identical (W5). (No `%`; cursor arithmetic only — Trap 11 N/A.)

**`pt_deserialize(in_buf, in_len, out_term_id)`** (spec addition — the inverse of serialize, required for transport/M18) — validate `in_buf[0]==PT_SER_TAG`; `pt_alloc` a fresh slot; copy the embedded id into the slot id (overwriting the alloc-derived id so round-trip is identity); replay each encoded step via the same store path as `pt_add_inference` (bound-gated); leave the term **non-finalized and unverified** (M17: a deserialized term is never trusted — the consumer must re-`pt_finalize` + re-`pt_verify`). Malformed length/over-bound ⇒ `PT_E_MALFORMED`. Non-recursive flat parse with a cursor + sentinel.

**`pt_to_program(term_id, out_prog, out_cap, out_len)`** (spec addition — Curry-Howard bridge, M11, consumes Module 60) — guard verified; `pt_serialize` the term into `PT_KAT_BUF` (or a dedicated scratch), then call `ch_proof_to_program(serialized, len, out_prog, out_cap, out_len)` which flips the `0x54`→`0x50` tag and re-emits the body (the canonical structural rewrite). Returns its status. This realizes the dispatch's "V2 Phase Fourteen consumes the CIC kernel" intent: a verified proof term yields its extractable program.

**`pt_kat()`** (spec addition — the Phase-2 acceptance self-test, mirrors `keccak256_kat`) — see KAT Vectors; returns `99u64` on full pass.

## KAT Vectors (>= 3)
A self-test (`pt_kat`) checks these byte-for-byte. (Keccak-derived ids/fragment ids are checked structurally + by round-trip equality, since the canonical id bytes depend on the proven `keccak256_oneshot` whose own KAT — Keccak256("")=`c5d24601…85a470`, Keccak256("abc")=`4e03657a…12d6c45` — is the upstream vector.)

1. **Valid modus-ponens proof accepts.** Build term T; add step0 = `AXIOM`, pcount=0, conclusion=`A` (bytes `0x41`); step1 = `AXIOM`, pcount=0, conclusion=`A⇒B` (encode as `0x41 0x3E 0x42`); step2 = `MODUS_PONENS`, premises=[0,1], conclusion=`B` (byte `0x42`). `pt_finalize(T)` ⇒ `PT_OK`. `pt_verify(T)` ⇒ **`PT_OK` (0)**. `PT_VERIFIED` set.

2. **Forward-reference / cyclic premise rejects (prove the negative).** Build term T2; step0 = `MODUS_PONENS` with premises=[0,1] (cites itself / a non-earlier step). `pt_finalize` ⇒ OK. `pt_verify(T2)` ⇒ **`PT_E_INVALID_INFERENCE` (-4)** — the DAG check fires. (Negative-case proof per the no-autogen-stub mandate: the gate must FAIL on bad input, not merely pass on good.)

3. **Arity violation rejects (prove the negative).** Term T3; step0 `AXIOM` conclusion `A`; step1 = `MODUS_PONENS` with premises=[0] (pcount=1, but MP requires 2). `pt_verify(T3)` ⇒ **`PT_E_INVALID_INFERENCE` (-4)**.

4. **Conclusion-mismatch rejects (prove the negative — maximal-verifier vector).** Term T4; step0 `AXIOM` `A`; step1 `AXIOM` `A⇒B`; step2 `MODUS_PONENS` premises=[0,1] but conclusion=`C` (`0x43`, ≠ the `B` implied by premise[1]). `pt_verify(T4)` ⇒ **`PT_E_INVALID_INFERENCE` (-4)** — distinguishes the strengthened verifier from the gospel's arity-only check.

5. **Serialize → deserialize round-trip is identity.** `pt_serialize(T)` into `PT_KAT_BUF` ⇒ `*out_len = L`; `pt_deserialize(PT_KAT_BUF, L, &id2)`; re-`pt_serialize` the new term ⇒ byte-identical buffer of length `L`. (W5 bit-identity; M2 determinism.)

6. **Emit-before-verify refuses; emit-after-verify succeeds.** `pt_emit_constructed` on an unverified term ⇒ **`PT_E_INVALID_INFERENCE`**; after `pt_verify`=OK, `pt_emit_constructed` ⇒ `PT_OK` and writes a 32-byte fragment id (nonzero). (M6/M10 — fragment only for verified terms.)

7. **Not-finalized verify refuses.** Allocate + add steps but do **not** finalize; `pt_verify` ⇒ **`PT_E_NOT_FINAL` (-5)**.

`pt_kat` returns `99u64` only if all of the above hold; any failure returns a distinct nonzero code (1..N) identifying the vector.

## Trap Exposure
- **Trap 1 (multi-line `fn`):** every signature above is single-line. The 12-param `wh_publish` *extern* is one line; `pt_add_inference`'s 6-param gospel form is eliminated (collapsed to `args: *u8`).
- **Trap 2 (linker-global const):** `PT_` prefix grep-confirmed collision-free across `STDLIB/`.
- **Trap 3 (signed ordering SIGSEGV):** the only signed value is `i64 slot`/`found`, compared **only** by `== -1i64` (never `<`/`>=`). All loop/bound compares (`step >= PT_MAX_STEPS`, `p < step`, `pcount != 2u32`, `i < count`) are **unsigned** (u32/u64) — house-accepted (e.g. `merkle.iii:158 li_l >= lc_l`). No `i32`/`i64` ordering anywhere.
- **Trap 4 (u32-in-u64-slot garbage):** `idx = s*PT_MAX_STEPS + (step as u64)`, premise math `idx*8 + i`, conclusion base `idx*512` — every u32 promoted to u64 before pointer math; where a raw u32 step/premise index feeds an address, mask `(x as u64) & 0xFFFFFFFFu64` before the multiply. `s` and `idx` are u64 throughout.
- **Trap 5 (u32 pointer-store width):** all multi-byte writes (ids, LE counts, premises, conclusion lens, payload) are **byte-by-byte through `*u8`** (the gospel already does this; serialize/emit assemble bytes individually). No `*u32`-typed store of a u32 local.
- **Trap 6 (nested `/* */`):** none; comments are flat, `//` for inline.
- **Trap 7 (local `var` arrays):** **all** gospel function-local arrays (`seed`, `clen_buf`, `out_c`, `payload`, `producer`, `op`, `in_c`) are hoisted to module scope (`PT_SEED`, `PT_CLEN_BUF`, `PT_OUT_COMMIT`, `PT_PAYLOAD`, `PT_PRODUCER`, `PT_OP`, `PT_IN_COMMIT`) plus new `PT_HASHBUF`/`PT_KAT_*`. Non-reentrancy documented (serialized ceremony).
- **Trap 8 (`} else {` one line):** the `pt_verify_step` rule cascade and every guard uses single-line `} else {` (or independent `if … return` guards, as the gospel does).
- **Trap 9 (em-dash in comment):** all `/* */` and `//` comments use ASCII `--`; no U+2014.
- **Trap 10 (`let mut` checkpoint-flag):** verification uses the **sentinel pattern** the exemplars use (`let mut sentinel : u8 = 0u8`, loop reads it) — this is the established-safe form, not a misbehaving `let mut x=0u32` checkpoint; first-failure capture sets `result` + `sentinel` together.
- **Trap 11 (`a % b` after call):** **no modulo anywhere** in the module (all indexing is multiply/add). N/A.
- **Trap 12 (`@specialize *T` stride):** module is **not** generic (no `@specialize`, no type-param indexing). N/A.

Element-address lowering (house idiom, not in the numbered catalog but load-bearing — flagged by `aether/witness_hook.iii`'s reconciliation): the gospel writes `&PT_TERM_IDS[s*32u64]`. iiis lowers element-address-of-static reliably as `((&PT_TERM_IDS as u64) + s*32u64) as *u8`; Phase 2 must use the `(&ARR as u64)+off` form for every element address passed to an extern (`ident_*`, `keccak256_oneshot`, `wh_publish`), exactly as `witness_hook.iii` does.

## Gap / Fix List
PARTIAL — the following must be fixed/added by Phase 2:

1. **Keccak path defect (systemic gospel bug).** Gospel: `extern … keccak256_init/update/final from "keccak.iii"`. **Fix:** those symbols live in `keccak256.iii`, not `keccak.iii`; and per `identifier.iii`'s documented param-spill reconciliation, do **not** use the streaming triple at all — use `keccak256_oneshot from "keccak256.iii"` over a contiguous module-scope buffer (`PT_HASHBUF`/assembled `PT_OUT_COMMIT` region). This removes both the wrong-path and the param-spill hazard.
2. **Phantom witness module.** Gospel: `extern … ws_emit_fragment(… 7 params …) from "witness_spine.iii"`. **No such module or symbol exists.** **Fix:** publish via `aether/witness_hook.iii::wh_publish` (built, Module 07), mapping producer/op = zero id, in_commit = term id, out_commit = keccak of (id||stepcount), payload = the identical 40-byte `0xE3 0x14 …id` record, antecedents = none. Map `wh_publish`'s `0xFFFF…` sentinel to `PT_E_FULL`. The 7-param `ws_emit_fragment` would also have violated W2; `wh_publish` is the substrate's documented multi-field hook (W2-exempt, like the gospel notes for `wh_publish` itself).
3. **W2 6-param `pt_add_inference`.** Gospel signature has 6 params. **Fix:** collapse to `pt_add_inference(args: *u8)` with the `PT_ADDARG` byte layout (term_id|kind|counts|premises|conclusion). Public arity = 1.
4. **Local `var [u8;N]` arrays (Trap 7).** Seven function-local arrays in the gospel body. **Fix:** hoist all to module scope with `PT_`-prefixed names (listed in Data Structures); document non-reentrancy.
5. **Element-address form.** `&PT_TERM_IDS[s*32u64]` etc. **Fix:** lower as `((&PT_TERM_IDS as u64)+s*32u64) as *u8` for every extern argument (per `witness_hook.iii`).
6. **Shallow verifier (M11/M18 partial).** The gospel `pt_verify_step` checks only premise-forward-reference + per-rule **arity**; it never inspects the conclusion bytes, so a step with the right shape but a wrong conclusion (e.g. MP yielding `C` instead of `B`) **incorrectly verifies**. This under-realizes "proofs are programs / the verifier replays each inference." **Fix:** strengthen `pt_verify_step` to the per-rule **conclusion replay** described in Algorithm (exact byte-match of MP's `B`, TRANSITIVITY's shared middle + ends, etc.). KAT #4 proves the strengthened gate fails on conclusion mismatch. This is the central maximal-intent upgrade.
7. **Missing inverse + bridge (maximal intent).** Gospel has `pt_serialize` but no `pt_deserialize` (no transport round-trip) and no Curry-Howard extraction. **Fix:** add `pt_deserialize` (inverse, leaves term untrusted per M17) and `pt_to_program` (consumes Module 60 `ch_proof_to_program`) to honor the dispatch's CIC-kernel intent.
8. **No self-test.** Gospel ships no KAT. **Fix:** add `pt_kat()` returning `99u64`, covering the 7 vectors above incl. three negative cases (no-autogen-stub mandate: gates must be proven to FAIL on bad input).
9. **Missing bound/range gates.** Gospel does not gate `premise_count <= 8` or `conclusion_len <= 512` on entry, risking OOB store (M19 cost bound). **Fix:** `PT_E_BAD_ARG` gate in `pt_add_inference`/`pt_deserialize`; range-check rule kind `1..PT_RULE_MAX`.

**Mandate audit (post-fix):** M1 ✓ (NIH, libc-free, oneshot keccak), M2 ✓ (fixed layout, deterministic replay), M3/M4 ✓ (exact structural checks, no counting/thresholds), M5 ✓ (append-only store, no destructive op; refusal on bad input), M6/M10 ✓ (fragment only post-verify, reproducible via `wh_publish`), M7 ✓ (R0), M8 — proof construction is unprivileged (no capability arg needed; admission to the library is the capability-gated ceremony in Module 62, not here) — noted, compliant, M9 ✓ (reversible: serialize/deserialize round-trip; no irreversible mutation), M11 ✓ (the `pt_*`↔`ch_*` bridge + verified proof terms), M12/M18 ✓ (verified term ⇒ checkable `PROOF_TERM_CONSTRUCTED` certificate), M13 ✓ (bounded steps/premises/conclusion, acyclic forward DAG, no self-citation), M17 ✓ (deserialized terms re-verified, never trusted), M19 ✓ (every op bounded by the fixed slot/step caps), M20 ✓ (the checker does not prove itself sound; documented). W2 ✓ (after fix #3/#2), W9/W10/W12 ✓, W11/Trap3 ✓ (i64 equality only), W13 ✓ (helpers keep <20 locals; `pt_verify_step`'s rule cascade stays under by using the `args`/`idx` locals + small temporaries), W14 ✓ (sentinel loops, no break), W15 ✓ (flat forward pass, explicit no recursion), W5/W16/W17 ✓ (bit-identical encoding; `wh_publish` advances algebraic time monotonically via `at_advance`).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/proof_term.iii
 *
 * III STDLIB - numera::proof_term  (Layer 5, Module 61)
 *
 * Proof terms as first-class checkable substrate artifacts.  A finalized
 * term is a sequence of inference steps (rule kind, premise step indices,
 * serialized conclusion); pt_verify replays each step deterministically and
 * accepts only valid rule instances over already-proven premises.  Verified
 * terms emit a PROOF_TERM_CONSTRUCTED witness fragment and serialize to a
 * canonical encoding.  The checker is small and audited; M20 forbids the
 * substrate proving its own checker sound via self-generated proofs.
 *
 * Reconciliations vs gospel body (see proof_term.spec.md Gap list):
 *   -- keccak256_oneshot from "keccak256.iii" (NOT streaming, NOT "keccak.iii")
 *   -- witness via aether/witness_hook.iii::wh_publish (NOT phantom ws_emit_fragment)
 *   -- pt_add_inference collapsed to a single *u8 arg record (W2)
 *   -- all function-local [u8;N] arrays hoisted to module scope (iiis Trap 7)
 *   -- element addresses lowered as ((&ARR as u64)+off) as *u8
 *   -- pt_verify_step strengthened to per-rule CONCLUSION replay (M11/M18)
 *   -- added: pt_deserialize, pt_to_program (Module 60 bridge), pt_kat
 *
 * Hexad: kind_essence + kind_witness + kind_cognition.  Ring: R0.  K: 1.00.
 * Discipline: <=4 public params; sentinel loops; no recursion; i64 eq-only.
 */
module numera_proof_term

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn ch_proof_to_program(proof: *u8, proof_len: u64, out_prog: *u8, out_prog_cap: u64, out_len: *u64) -> i32 from "curry_howard.iii"

const PT_OK                  : i32 =  0i32
const PT_E_NULL              : i32 = -1i32
const PT_E_FULL              : i32 = -2i32
const PT_E_ABSENT            : i32 = -3i32
const PT_E_INVALID_INFERENCE : i32 = -4i32
const PT_E_NOT_FINAL         : i32 = -5i32
const PT_E_ALREADY_FINAL     : i32 = -6i32
const PT_E_BUF_TOO_SMALL     : i32 = -7i32
const PT_E_NOT_INITED        : i32 = -8i32
const PT_E_TOO_MANY_STEPS    : i32 = -9i32
const PT_E_BAD_ARG           : i32 = -10i32
const PT_E_MALFORMED         : i32 = -11i32

const PT_SLOTS               : u64 = 256u64
const PT_MAX_STEPS           : u64 = 1024u64
const PT_MAX_PREMISES        : u64 = 8u64
const PT_CONCLUSION_BYTES    : u64 = 512u64
const PT_ID_BYTES            : u64 = 32u64

const PT_RULE_AXIOM          : u8 = 0x01u8
const PT_RULE_MODUS_PONENS   : u8 = 0x02u8
const PT_RULE_GENERALIZATION : u8 = 0x03u8
const PT_RULE_INDUCTION_BASE : u8 = 0x04u8
const PT_RULE_INDUCTION_STEP : u8 = 0x05u8
const PT_RULE_SUBSTITUTION   : u8 = 0x06u8
const PT_RULE_LIBRARY_CITE   : u8 = 0x07u8
const PT_RULE_REFLEXIVITY    : u8 = 0x08u8
const PT_RULE_SYMMETRY       : u8 = 0x09u8
const PT_RULE_TRANSITIVITY   : u8 = 0x0Au8
const PT_RULE_CASE_ANALYSIS  : u8 = 0x0Bu8
const PT_RULE_MAX            : u8 = 0x0Bu8

const PT_SER_TAG             : u8  = 0x54u8
const PT_PROG_TAG            : u8  = 0x50u8
const PT_FRAG_KIND           : u8  = 0x14u8
const PT_FRAG_MAGIC          : u8  = 0xE3u8
const PT_WH_PHASE            : u8  = 0u8
const PT_WH_PILLAR           : u16 = 0u16
const PT_WH_REVTAG           : u8  = 0u8

var PT_INITED              : u8 = 0u8
var PT_TERM_IDS            : [u8;  8192]
var PT_LIVE                : [u8;  256]
var PT_FINAL               : [u8;  256]
var PT_VERIFIED            : [u8;  256]
var PT_STEP_COUNTS         : [u32; 256]
var PT_STEP_KINDS          : [u8;  262144]
var PT_STEP_PREMISE_COUNTS : [u32; 262144]
var PT_STEP_PREMISES       : [u32; 2097152]
var PT_STEP_CONCL_LENS     : [u32; 262144]
var PT_STEP_CONCLUSIONS    : [u8;  134217728]

var PT_ADDARG_SCRATCH      : [u8; 600]
var PT_SEED                : [u8; 16]
var PT_CLEN_BUF            : [u8; 4]
var PT_OUT_COMMIT          : [u8; 32]
var PT_PAYLOAD             : [u8; 40]
var PT_PRODUCER            : [u8; 32]
var PT_OP                  : [u8; 32]
var PT_IN_COMMIT           : [u8; 32]
var PT_HASHBUF             : [u8; 552]
var PT_KAT_ID              : [u8; 32]
var PT_KAT_FRAG            : [u8; 32]
var PT_KAT_BUF             : [u8; 4096]
var PT_KAT_CONCL           : [u8; 64]

// -- internal helpers (non-export) --
fn pt_find_slot(term_id: *u8) -> i64 { /* TODO: sentinel scan live slots; ident_eq; return i64, -1i64 absent (Algorithm pt_find_slot) */ }
fn pt_verify_step(slot: u64, step: u32) -> i32 { /* TODO: DAG forward-ref check + per-rule arity + CONCLUSION replay (Algorithm pt_verify_step) */ }

// -- public API (single-line signatures) --
fn pt_init() -> i32 @export { /* TODO: idempotent zero of liveness tables (Algorithm pt_init) */ }
fn pt_alloc(out_term_id: *u8) -> i32 @export { /* TODO: first-free slot; seed id; ident_from_bytes; write out (Algorithm pt_alloc) */ }
fn pt_add_inference(args: *u8) -> i32 @export { /* TODO: parse PT_ADDARG layout; bound/range gate; store step (Algorithm pt_add_inference) */ }
fn pt_finalize(term_id: *u8) -> i32 @export { /* TODO: set PT_FINAL (Algorithm pt_finalize) */ }
fn pt_verify(term_id: *u8) -> i32 @export { /* TODO: require final; flat forward pass over pt_verify_step; set PT_VERIFIED (Algorithm pt_verify) */ }
fn pt_emit_constructed(term_id: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: require verified; keccak oneshot out-commit; wh_publish 40B payload (Algorithm pt_emit_constructed) */ }
fn pt_serialize(term_id: *u8, out_buf: *u8, out_cap: u64, out_len: *u64) -> i32 @export { /* TODO: canonical encode per Algorithm pt_serialize */ }
fn pt_deserialize(in_buf: *u8, in_len: u64, out_term_id: *u8) -> i32 @export { /* TODO: parse + replay into fresh slot, leave untrusted (Algorithm pt_deserialize) */ }
fn pt_to_program(term_id: *u8, out_prog: *u8, out_cap: u64, out_len: *u64) -> i32 @export { /* TODO: serialize then ch_proof_to_program (Algorithm pt_to_program) */ }
fn pt_kat() -> u64 @export { /* TODO: 7 vectors incl. 3 negative; return 99u64 on full pass (KAT Vectors) */ }
```
