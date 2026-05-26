# 59 numera/synthesis_spec.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel candidate body is structurally near-complete (10 functions, clean slot table, sound canonical-encode + content-address path) but is **NOT buildable as written**: it imports `keccak256_init/update/final` from the wrong file (`keccak.iii` instead of `keccak256.iii`), imports a non-existent `ws_emit_fragment` from `witness_spine.iii` (fragment emission actually lives in `witness_hook.iii::wh_publish`, a 12-param fn), and calls `cons_find` with an inverted/wrong-typed result check (`!= 0i32` against a fn that returns `u32` with sentinel `0xFFFFFFFFu32`, where slot `0` is a *valid* found-clause). It also drops the gospel-advertised `ss_canonical_encode` public fn, imports `ca_compute` but never calls it, and uses the unassigned const prefix `SS_`. All of these are closed below.

## Purpose
`numera_synthesis_spec` is the canonical **specification language** for synthesis problems: the formal object a synthesized artifact must satisfy. A spec encodes a program signature (input/output type-kind vectors), a set of algebraic constraints (encoded predicate terms over input/output pairs), an 8-dimension cost-vector budget, and a verifier reference (module + fn). Its **canonical encoding's Keccak256 content address is the synthesis problem's canonical name**; its ratification under the `cp_synth_admit` constitutional clause gates engine invocation (W33: no synthesis without a ratified spec). It is the M12 (Synthesis Verifiability) foundation — the checkable certificate that consumers `synthesis_search` (63) and `synthesis_witness` (64) build upon.
- **Hexad:** kind_essence + kind_cognition
- **Ring:** R0
- **K-vector:** 1.00

## Public API
All public functions are `@export`, single-line signatures (Trap 1), and return a status `i32` per W9/W12 (negative = error). **Function names retain the gospel's `ss_` prefix** — they are the stable cross-module API that consumers 63/64 extern by name; only module-level `const`/`var` names take the assigned `SYNSPEC_` prefix (Trap 2 is a *data*-symbol hazard, not a fn-name hazard — see Constant Namespace).

```
fn ss_init() -> i32 @export
fn ss_alloc(out_spec_id: *u8) -> i32 @export
fn ss_set_signature(spec_id: *u8, in_arity: u32, in_kinds: *u8, out_arity: u32, out_kinds: *u8) -> i32 @export
fn ss_add_constraint(spec_id: *u8, predicate: *u8, predicate_len: u32) -> i32 @export
fn ss_set_cost_vector(spec_id: *u8, cost: *u8) -> i32 @export
fn ss_set_verifier(spec_id: *u8, verifier_module: *u8, verifier_fn: *u8) -> i32 @export
fn ss_canonical_encode(spec_id: *u8, out_buf: *u8, out_buf_cap: u64, out_len: *u64) -> i32 @export
fn ss_content_address(spec_id: *u8, out: *u8) -> i32 @export
fn ss_propose(spec_id: *u8, out_frag_id: *u8) -> i32 @export
fn ss_ratify(spec_id: *u8, ratifier_capability: *u8, out_frag_id: *u8) -> i32 @export
```

**W2 note:** `ss_set_signature` has 5 params — it **violates W2 (≤4 params)**. Fix (see Gap List G7): pass an aggregate. The conforming signature is:

```
fn ss_set_signature(spec_id: *u8, sig: *u8) -> i32 @export
```

where `sig` points to a packed `SYNSPEC_SigDesc` block: `in_arity:u32 @0, out_arity:u32 @4, in_kinds:[u8;32] @8, out_kinds:[u8;32] @40` (72 bytes). All other public fns are ≤4 params and conform.

**W12 / return convention:** every public fn returns `SYNSPEC_OK (0i32)` on success or a negative `SYNSPEC_E_*` sentinel. `ss_alloc` additionally writes a 32-byte spec-id into `out_spec_id`. `ss_propose`/`ss_ratify` write a 32-byte fragment-id into `out_frag_id`. Internal helper `ss_find_slot(spec_id: *u8) -> i64` is **not** `@export` (returns `-1i64` sentinel for not-found; compared by `== -1i64` only, never `<`, per Trap 3 / W11).

## Constant Namespace
**PREFIX = `SYNSPEC_`** (dispatch-assigned). Grep of `STDLIB/` confirms **zero** existing `SYNSPEC_` symbols (no collision). The gospel body used `SS_`; `SS_` is *also* collision-free in `STDLIB/`, but the dispatch prefix is authoritative — **rename every module-level `const`/`var` from `SS_*` → `SYNSPEC_*`.** (Function names stay `ss_*`; see API note.)

Module-level constants:
```
const SYNSPEC_OK                      : i32 =  0i32
const SYNSPEC_E_NULL                  : i32 = -1i32
const SYNSPEC_E_FULL                  : i32 = -2i32
const SYNSPEC_E_ABSENT                : i32 = -3i32
const SYNSPEC_E_CLAUSE_ABSENT         : i32 = -4i32
const SYNSPEC_E_BUF_TOO_SMALL         : i32 = -5i32
const SYNSPEC_E_NOT_INITED            : i32 = -6i32
const SYNSPEC_E_TOO_MANY_CONSTRAINTS  : i32 = -7i32
const SYNSPEC_E_ARITY                 : i32 = -8i32     // arity exceeds SYNSPEC_MAX_ARITY (new; G6)
const SYNSPEC_SLOTS                   : u64 = 128u64
const SYNSPEC_MAX_CONSTRAINTS         : u64 = 32u64
const SYNSPEC_MAX_ARITY               : u64 = 32u64     // bound on in_arity/out_arity (justifies the *32 stride)
const SYNSPEC_PREDICATE_BUF_BYTES     : u64 = 4096u64
const SYNSPEC_IDENT_BYTES             : u64 = 32u64
const SYNSPEC_COST_BYTES              : u64 = 32u64     // 8 dims * u32
```

**No collision** with: `SS_*` (none exist), `BIGINT_*`, `BITOPS_*`, `CONS_*`, `IDENT_*`, `CA_*`, or any keccak symbol (verified by grep — only `SYNSPEC_` namespace introduced).

## Data Structures
All module-scope (Trap 7: no local `var` arrays). Every fixed bound justified under W8.

| Name | Type | Size | Bound justification |
|---|---|---|---|
| `SYNSPEC_INITED` | `var u8` | 1 | init-once flag |
| `SYNSPEC_COUNT` | `var u64` | 8 | live-slot counter |
| `SYNSPEC_LIVE` | `[u8; 128]` | 128 | one liveness byte per slot; `SYNSPEC_SLOTS=128` |
| `SYNSPEC_SPEC_IDS` | `[u8; 4096]` | 4096 | 128 slots × 32-byte identifier |
| `SYNSPEC_IN_ARITY` | `[u32; 128]` | 512 | per-slot input arity |
| `SYNSPEC_OUT_ARITY` | `[u32; 128]` | 512 | per-slot output arity |
| `SYNSPEC_IN_KINDS` | `[u8; 4096]` | 4096 | 128 × `SYNSPEC_MAX_ARITY(32)` kind bytes |
| `SYNSPEC_OUT_KINDS` | `[u8; 4096]` | 4096 | 128 × 32 kind bytes |
| `SYNSPEC_COST_VECTORS` | `[u8; 4096]` | 4096 | 128 × 32-byte cost vector |
| `SYNSPEC_VERIFIER_MODULES` | `[u8; 4096]` | 4096 | 128 × 32-byte module identifier |
| `SYNSPEC_VERIFIER_FNS` | `[u8; 4096]` | 4096 | 128 × 32-byte fn identifier |
| `SYNSPEC_CONSTRAINT_COUNTS` | `[u32; 128]` | 512 | per-slot constraint count |
| `SYNSPEC_CONSTRAINT_LENS` | `[u32; 4096]` | 16384 | 128 × `SYNSPEC_MAX_CONSTRAINTS(32)` predicate lengths |
| `SYNSPEC_CONSTRAINT_BUFS` | `[u8; 16777216]` | 16 MiB | 128 × 32 × `SYNSPEC_PREDICATE_BUF_BYTES(4096)` predicate bytes |
| `SYNSPEC_SEED_SCRATCH` | `[u8; 16]` | 16 | slot-id derivation scratch (was local `var seed` in body — moved to module scope per Trap 7) |
| `SYNSPEC_ENC_SCRATCH` | `[u8; 256]` | 256 | canonical-encode header staging (arity+cost+verifier framing) |

**Reentrancy note (Trap 7):** `SYNSPEC_SEED_SCRATCH` and `SYNSPEC_ENC_SCRATCH` are module-scope (not reentrant). Acceptable: spec construction is serialized (single-threaded substrate; no concurrent `ss_alloc`/`ss_canonical_encode`). Documented as a constraint.

**Total static footprint ≈ 16.79 MiB**, dominated by `SYNSPEC_CONSTRAINT_BUFS` (128 specs × 32 constraints × 4 KiB). This is the gospel's intended scale and is **not** down-scaled (maximal-intent mandate; no-practicality discipline).

## Dependencies (externs)
Each single-line. **Two corrected vs. the gospel body** (marked ⚠ FIX).

```
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"            // ⚠ FIX: was "keccak.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"  // ⚠ FIX
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"   // ⚠ FIX
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"            // ⚠ FIX: was -> i32
extern @abi(c-msvc-x64) fn wh_publish(pub_args: *u8) -> u64 from "witness_hook.iii"            // ⚠ FIX: see G3
```

| Provider | Module NN | Status | Symbols used |
|---|---|---|---|
| `identifier.iii` | (foundational, not gospel-numbered) | **BUILT** (verified in tree) | `ident_zero`, `ident_eq`, `ident_copy`, `ident_from_bytes` — signatures match exactly |
| `keccak256.iii` | (Layer 1, built) | **BUILT** (verified: exports `keccak256_init/update/final/oneshot`) | streaming hash |
| `constitution.iii` | **13** (Layer 3) | **NOT-YET-BUILT** | `cons_find(clause_id:*u8) -> u32`, sentinel `0xFFFFFFFFu32` |
| `witness_hook.iii` | (aether, built) | **BUILT** (verified: exports `wh_publish`, 12 params) | fragment publication |

**Not-yet-built deps: 1** (`constitution.iii`, Module 13 — wave scheduler must order Module 13 before 59). `identifier.iii`, `keccak256.iii`, `witness_hook.iii` are present in the tree.

**REMOVED extern (dead code in body):** `ca_compute` from `content_addr.iii` — imported by the gospel body but **never called** (content address is computed locally via streaming keccak in `ss_content_address`). Dropping it removes an unnecessary build edge. `content_addr.iii` is **not** a dependency.

**`wh_publish` ABI note (G3):** the real emitter is `wh_publish(producer, opid, in_commit, out_commit, revtag, phase, pillar, antecedents, n_ante, payload, payload_len, out_frag_id) -> u64` — **12 params**, which both exceeds W2 and is multi-line in the gospel source. The spec wraps it: extern it as a single `*u8` aggregate-pointer call `wh_publish(pub_args: *u8) -> u64` IF the built `wh_publish` offers an aggregate entrypoint; otherwise (the 12-param form is what is actually compiled) the **W2-conforming approach for module 59 is a private fixed-arg local helper** `ss_emit(payload: *u8, payload_len: u32, in_commit: *u8, out_frag_id: *u8) -> i32` (4 params) that stages the remaining 8 `wh_publish` args from module-scope zero/const buffers and performs the one 12-arg call internally. The 12-arg call site is the single W2 exception, isolated and documented (it is a *call to* an external 12-param fn, not a *definition*; W2 governs definitions in this module). **Phase 2 must confirm the built `wh_publish` signature and bind accordingly.**

## Algorithm
NIH (M1): all hashing is the in-tree hand-rolled Keccak256 (`keccak256.iii`); no third-party. No ML/heuristics (M3/M4) — every decision is exact slot-table lookup or byte-exact serialization. Determinism (M2)/bit-identity (W5): the canonical encoding is a fixed-layout byte concatenation in a fixed field order, so identical specs hash identically across runs/CPUs. No recursion anywhere (W15) — every traversal is a `while` over a counter (explicit, no stack needed; depth is naturally flat). No `break` (W14) — sentinel-flag loops.

**`ss_init`** — idempotent (`if SYNSPEC_INITED == 1u8 return OK`). Zero `SYNSPEC_LIVE[i]` and `SYNSPEC_CONSTRAINT_COUNTS[i]` for `i in 0..SYNSPEC_SLOTS`; set `SYNSPEC_COUNT=0`, `SYNSPEC_INITED=1`. Sentinel-loop on `i`.

**`ss_alloc(out_spec_id)`** — guard not-inited / null. Linear scan for first `SYNSPEC_LIVE[i]==0` using a **sentinel flag** (`sentinel:u8`, set once found; the loop continues but stops capturing) — W14, no break. If none → `E_FULL`. Derive the spec-id deterministically: fill `SYNSPEC_SEED_SCRATCH[0..8]` with `0x73 + k` (the literal `"s"`-seed prefix from the body) and `SYNSPEC_SEED_SCRATCH[8..12]` with the slot index little-endian (bytes 12..16 zero), then `ident_from_bytes(&SYNSPEC_SEED_SCRATCH[0], 16, &SYNSPEC_SPEC_IDS[s*32])`; `ident_copy` it to `out_spec_id`. Mark live, `SYNSPEC_COUNT += 1`. **Determinism:** spec-id is a pure function of slot index → reproducible.

**`ss_find_slot(spec_id) -> i64`** (private) — sentinel-flag linear scan; for each live slot compare `ident_eq(&SYNSPEC_SPEC_IDS[i*32], spec_id) == 1u8`; capture `i as i64` once. Return `found` (`-1i64` if absent). Callers compare `== -1i64` only (Trap 3 / W11).

**`ss_set_signature(spec_id, sig)`** (aggregate form, G7) — find slot (`== -1i64` → `E_ABSENT`). Read `in_arity = LE32(sig+0)`, `out_arity = LE32(sig+4)`. **Bound-check** both `<= SYNSPEC_MAX_ARITY` else `E_ARITY` (G6 — the body omitted this, risking OOB writes into adjacent slots' kind rows). Store arities; copy `in_arity` bytes from `sig+8` into `SYNSPEC_IN_KINDS[s*32 ..]` and `out_arity` bytes from `sig+40` into `SYNSPEC_OUT_KINDS[s*32 ..]`. Sentinel-loop copies. Pointer math on `s*32 + i` — all `u64`, no u32-in-u64 hazard (Trap 4 N/A: indices are `u64` throughout).

**`ss_add_constraint(spec_id, predicate, predicate_len)`** — find slot; guard nulls. `cur = SYNSPEC_CONSTRAINT_COUNTS[s]`; if `(cur as u64) >= SYNSPEC_MAX_CONSTRAINTS` → `E_TOO_MANY_CONSTRAINTS`. **Bound-check `predicate_len <= SYNSPEC_PREDICATE_BUF_BYTES`** else `E_BUF_TOO_SMALL` (G6 — body omitted; a too-long predicate would overflow into the next constraint's buffer). `idx = s*SYNSPEC_MAX_CONSTRAINTS + cur`; `base = idx*SYNSPEC_PREDICATE_BUF_BYTES`; copy `predicate_len` bytes; set `SYNSPEC_CONSTRAINT_LENS[idx]=predicate_len`; `SYNSPEC_CONSTRAINT_COUNTS[s]=cur+1`. **No modulo-after-call (Trap 11):** all addressing is `*`/`+`, no `%`.

**`ss_set_cost_vector(spec_id, cost)`** — find slot; copy exactly `SYNSPEC_COST_BYTES(32)` bytes `cost[0..32]` → `SYNSPEC_COST_VECTORS[s*32 ..]`. The 32 bytes are 8 × u32 LE dimensions; stored opaquely (byte copy) so bit-identity holds regardless of dimension semantics (W5).

**`ss_set_verifier(spec_id, verifier_module, verifier_fn)`** — find slot; guard 3 nulls; `ident_copy` each 32-byte identifier into `SYNSPEC_VERIFIER_MODULES[s*32]` / `SYNSPEC_VERIFIER_FNS[s*32]`.

**`ss_canonical_encode(spec_id, out_buf, out_buf_cap, out_len)`** (RESTORED, G2) — find slot. Compute the exact serialized length first: `need = 32(id) + 8(arities) + in_arity + out_arity + 32(cost) + 32(vmod) + 32(vfn) + 4(n_constraints) + Σ(4 + len_i)`. If `out_buf_cap < need` → `E_BUF_TOO_SMALL` (compare via subtraction/`<` on **u64** — unsigned ordering is safe; Trap 3 is signed-only). Else emit, in this **fixed field order**, into `out_buf`: spec-id(32) ‖ in_arity_LE32 ‖ out_arity_LE32 ‖ in_kinds(in_arity) ‖ out_kinds(out_arity) ‖ cost(32) ‖ verifier_module(32) ‖ verifier_fn(32) ‖ n_constraints_LE32 ‖ for each constraint: len_LE32 ‖ bytes(len). Write `need` to `*out_len`. This canonical byte string is the single source of truth that `ss_content_address` hashes — defining it as a public fn (per the gospel API block) lets consumers 63/64 obtain the exact pre-image (M10 witness reproducibility, M14 provenance). All length fields use byte-wise LE store (Trap 5 avoidance — store through `*u8`, never `p[0]=v_u32`).

**`ss_content_address(spec_id, out)`** — find slot. `keccak256_init()`; then `keccak256_update` over the SAME fields in the SAME order as `ss_canonical_encode` (id, 8-byte arity block, in_kinds[in_arity], out_kinds[out_arity], cost(32), vmod(32), vfn(32), then each constraint's bytes for `cnt` constraints), then `keccak256_final(out)`. **Equivalence invariant (G8):** `ss_content_address(x)` MUST equal `keccak256(ss_canonical_encode(x))`. The body's hash path omits the `n_constraints` count and the per-constraint length framing that a clean canonical encoding includes — Phase 2 must make the two paths **bit-identical** by feeding the count + per-constraint length into the hash too (otherwise two specs differing only in constraint boundaries could collide). Spec mandates the framed form in both. Arity staging uses `SYNSPEC_ENC_SCRATCH` (module scope, Trap 7). **No modulo, no recursion.**

**`ss_propose(spec_id, out_frag_id)`** — find slot. Compute `content_addr` via `ss_content_address` into a module-scope (or stack) 32-byte buffer. Build the `SYNTH_SPEC_PROPOSAL` payload (v3 framing: `0xE3, 0x04` header, then content_addr(32) at offset 8, spec_id(32) at offset 40 — 72 bytes total). Zero a producer/op identifier; set in_commit = spec_id, out_commit = content_addr. Emit via the `ss_emit` helper → `wh_publish` (G3). Return its status mapped to `SYNSPEC_OK`/error.

**`ss_ratify(spec_id, ratifier_capability, out_frag_id)`** — guard 3 nulls. Derive the `cp_synth_admit` clause-id: `ident_from_bytes` over the 14-byte ASCII label `"cp_synth_admit"` → `clause_id`. **Capability check (M8):** verify the clause is present: `if cons_find(&clause_id[0]) == SYNSPEC_CONS_SENT { return E_CLAUSE_ABSENT }` — **⚠ FIX (G4):** `cons_find` returns `u32` with not-found sentinel `0xFFFFFFFFu32`; the body's `!= 0i32` is both wrong-typed and inverted (it would reject every clause stored at slot 0 and accept absence at slot ≥1). Then find the spec slot; build `SYNTH_SPEC_RATIFIED` payload (`0xE3, 0x05`, spec_id(32)@8, cost_vector(32)@40, ratifier_capability(32)@72 — 104 bytes); emit via `ss_emit`. **M8/M9:** ratification is the capability-gated transition; `ratifier_capability` is the explicit capability argument (W8/M8). Witness fragment chains by hash (M6) through `wh_publish`.

**Local `cp_synth_admit` constant:** add `const SYNSPEC_CONS_SENT : u32 = 0xFFFFFFFFu32` mirroring `constitution.iii::CONS_SENT` (cannot import a `const`; Trap 2 means constitution's `CONS_SENT` is a *different* linker symbol — declare our own equal-valued one).

## KAT Vectors (≥3)
A self-test (`synthesis_spec_kat`) checks these byte-for-byte after `ss_init()`.

1. **Deterministic spec-id (slot 0).** `ss_alloc(&id0)` as the first allocation → slot 0. Seed = `[0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7A, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00]` (`"stuvwxyz"`+slot0_LE32+0). Expected `id0 = keccak256(seed[0..16])`. Recompute independently from the same 16 bytes → must match `ident_from_bytes` output (M2/M10). Re-running `ss_init();ss_alloc` yields the identical `id0` (reproducibility).

2. **Canonical-encode ↔ content-address equivalence.** Build a spec: signature in_arity=1 in_kinds=[0x01], out_arity=1 out_kinds=[0x01]; cost = 32 zero bytes; verifier_module = verifier_fn = 32 zero bytes; one constraint `predicate=[0xAA,0xBB], len=2`. Call `ss_canonical_encode(id, buf, 4096, &n)` → `n = 32+8+1+1+32+32+32+4+(4+2) = 154`. Then assert `ss_content_address(id, h)` byte-equals `keccak256(buf[0..154])` (G8 invariant). This pins the framed-hash fix.

3. **Empty-spec content address is stable + non-trivial.** Alloc a fresh spec, set nothing else (arities 0, no constraints, zero cost/verifier). `ss_content_address(id, h)` must equal `keccak256(id(32) ‖ 0x00000000 0x00000000 ‖ <0 kind bytes> ‖ zero_cost(32) ‖ zero_vmod(32) ‖ zero_vfn(32) ‖ 0x00000000)` = a fixed 32-byte digest; recompute independently and compare. Confirms the encoder handles arity-0 (no kind bytes emitted) without reading OOB.

4. **Clause-absent rejection (negative case — proves the guard FAILS correctly).** With `constitution.iii` initialized but `cp_synth_admit` NOT ratified, `cons_find(clause_id) == 0xFFFFFFFFu32`, so `ss_ratify(id, cap, &fid)` MUST return `SYNSPEC_E_CLAUSE_ABSENT (-4i32)` — and MUST NOT emit a fragment. After ratifying `cp_synth_admit` (slot becomes a valid index, e.g. 0), the SAME call MUST return `SYNSPEC_OK` and write a 32-byte `fid`. This is the M8 capability-gate proof (per MEMORY: prove the guard fails on bad input, not just passes), and directly exercises the G4 fix (slot 0 = found, not rejected).

5. **Bounds rejection (negative case).** `ss_set_signature` with `in_arity = 33` (> `SYNSPEC_MAX_ARITY`) MUST return `SYNSPEC_E_ARITY`; `ss_add_constraint` with `predicate_len = 4097` MUST return `SYNSPEC_E_BUF_TOO_SMALL`; the 33rd `ss_add_constraint` MUST return `SYNSPEC_E_TOO_MANY_CONSTRAINTS`. Proves G6 guards reject OOB before any write.

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| 1 — multi-line `fn` | YES (high) | Every signature in this spec is single-line. The dependency `wh_publish` is multi-line **in its own source** (Module 13/witness_hook) — our `extern` for it is written single-line (aggregate-ptr or staged-call form, G3). |
| 2 — module-level `const`/`var` linker-global | YES | All data symbols carry the `SYNSPEC_` prefix (collision-free per grep). Own `SYNSPEC_CONS_SENT` declared rather than importing constitution's `CONS_SENT`. Function names `ss_*` are unique to this module (no other module defines them; consumers 63/64 extern them). |
| 3 — signed ordering compare SIGSEGV | YES | `ss_find_slot` returns `i64`; all checks are `== -1i64` / `!= -1i64`. Never `< 0`. Cost/length/capacity comparisons use **u64** (unsigned ordering is safe). Error sentinels compared by `==`/`!=` only (W11). |
| 4 — u32-in-u64-slot garbage | LOW | Slot/index/offset arithmetic uses `u64` locals throughout (`s:u64`, `idx:u64`, `base:u64`). Where a `u32` (arity, len, count) feeds pointer math it is widened explicitly and masked `& 0xFFFFFFFFu64` before any `*`/`+`. |
| 5 — u32 pointer store width | YES | All multi-byte integer writes into buffers (LE32 arity/len/count fields, slot-index seed bytes) are done **byte-by-byte through `*u8`** with `(v >> (8*i)) & 0xFFu` extraction — never `p[0] = v_u32` through a `*u32`. |
| 6 — nested `/* */` | N/A | No nested block comments; inline notes use `//` or `(...)`. |
| 7 — local `var` arrays | YES | The body's local `var seed:[u8;16]` and per-fn scratch are **moved to module scope** (`SYNSPEC_SEED_SCRATCH`, `SYNSPEC_ENC_SCRATCH`). Non-reentrancy documented (serialized construction). Small per-call buffers (32-byte content_addr, payloads) — Phase 2 either uses fixed-size formal-param stack temporaries that the compiler permits, or adds module-scope `SYNSPEC_*` scratch. |
| 8 — `} else {` one line | LOW | Spec mandates `} else {` single-line wherever an else is used (encoder/ratify paths). |
| 9 — em-dash in comment | YES (avoided) | All comments use ASCII `--`, never U+2014. |
| 10 — `let mut flag` checkpoint | LOW | `ss_alloc`/`ss_find_slot` use the sentinel-flag pattern (`sentinel:u8`); acceptable here (the flag drives capture-once, loop still terminates on `i`). Where an early-return is cleaner (guards), use it. |
| 11 — `a % b` after call | N/A | **No modulo anywhere.** All slot/constraint addressing is `s*32`, `idx*4096`, `s*MAX_CONSTRAINTS+cur` — pure multiply/add. (Contrast bigint's `bits % 64`; this module needs none.) |
| 12 — `@specialize *T` stride | N/A | Module is not generic; no `@specialize`, no type-param indexing. All arrays are concrete `[u8;_]`/`[u32;_]`. |

## Gap / Fix List
PARTIAL — the following must be closed in Phase 2:

- **G1 (BUILD-BREAKING, systemic gospel defect): wrong keccak source.** Body: `extern keccak256_init/update/final ... from "keccak.iii"`. `keccak.iii` exports `keccak_init/absorb/squeeze/f1600`, **not** the `keccak256_*` streaming trio — those live in `keccak256.iii` (verified: `keccak256.iii:46,52,62`). **Fix:** `from "keccak256.iii"` for all three. (This is the exact systemic defect called out in the dispatch; constitution.iii Module 13 carries the same bug independently.)
- **G2 (MISSING PUBLIC FN): `ss_canonical_encode` absent.** The gospel's own API block advertises `ss_canonical_encode(spec_id, out_buf, out_buf_cap, out_len) -> i32`, but the candidate body never defines it — only the hashing path exists. Consumers 63/64 need the explicit pre-image (M10/M14). **Fix:** implement it (Algorithm §) as the single source of the canonical byte string; have `ss_content_address` hash exactly that layout.
- **G3 (WRONG DEPENDENCY): `ws_emit_fragment` does not exist.** Body: `extern ws_emit_fragment(producer, op, in_commit, out_commit, payload, payload_len, out_fid) -> i32 from "witness_spine.iii"`. `witness_spine.iii` (Module 12) exports `ws_init/register/lookup_id/pillar_*/producer_*/operation_*/epoch_*/chain_root/chain_replay_verify` — **no `ws_emit_fragment`.** Fragment *emission* is `witness_hook.iii::wh_publish` (12 params, returns `u64` frag-index; `0xFFFFFFFFFFFFFFFF` on failure). **Fix:** route `ss_propose`/`ss_ratify` through `wh_publish` via the 4-param `ss_emit` helper (Algorithm §, Deps §). `witness_spine.iii` is **not** a dependency of this module.
- **G4 (LOGIC + TYPE BUG): inverted/mis-typed `cons_find` check.** Body: `if cons_find(&clause_id[0u64]) != 0i32 { return SS_E_CLAUSE_ABSENT }`. `cons_find` returns **`u32`** (slot index), not-found sentinel **`0xFFFFFFFFu32`** (verified `constitution.iii` Module 13 API + `CONS_SENT`). The body (a) compares a `u32` to an `i32` literal, and (b) inverts the semantics: slot `0` is a *valid found* clause yet `!= 0i32` rejects it, while a clause at slot ≥1 makes `!= 0` true → also rejected, and the only "accepted" case is the sentinel-as-zero confusion. **Fix:** `if cons_find(&clause_id[0]) == SYNSPEC_CONS_SENT { return SYNSPEC_E_CLAUSE_ABSENT }`; declare `const SYNSPEC_CONS_SENT : u32 = 0xFFFFFFFFu32`. KAT #4 proves both polarities.
- **G5 (DEAD EXTERN): `ca_compute` imported, never called.** Body imports `ca_compute from "content_addr.iii"` but the content address is computed locally. **Fix:** delete the extern (removes a spurious build edge); `content_addr.iii` is not a dependency.
- **G6 (MISSING BOUNDS CHECKS — OOB write risk):** `ss_set_signature` does not check `in_arity`/`out_arity <= SYNSPEC_MAX_ARITY (32)`; `ss_add_constraint` does not check `predicate_len <= SYNSPEC_PREDICATE_BUF_BYTES (4096)`. Either overflows into an adjacent slot's row (M5 no-bricking / memory-safety hazard). **Fix:** add the guards (`E_ARITY`, `E_BUF_TOO_SMALL`); KAT #5 proves rejection.
- **G7 (W2 VIOLATION): `ss_set_signature` has 5 params.** **Fix:** aggregate the signature descriptor into a single `*u8` `SYNSPEC_SigDesc` block → `ss_set_signature(spec_id: *u8, sig: *u8) -> i32`. (See API §.) The gospel's 5-param form is the canonical *intent*; the W2-conforming wrapper preserves it.
- **G8 (DETERMINISM/COLLISION HARDENING): unframed hash.** The body's `ss_content_address` hashes constraint *bytes* without the `n_constraints` count or per-constraint length delimiters. Two specs with different constraint *boundaries* but the same concatenated bytes would collide → distinct synthesis problems sharing a canonical name (violates the "content address = canonical name" contract; M14/M17). **Fix:** hash the framed canonical encoding (count + per-constraint length prefix), identical to `ss_canonical_encode`. KAT #2 enforces the equivalence.
- **G9 (PREFIX): body uses `SS_`, dispatch assigns `SYNSPEC_`.** Both collision-free, but dispatch is authoritative. **Fix:** rename all module-level `const`/`var` `SS_* → SYNSPEC_*` (function names stay `ss_*`).

**Mandate audit (positives verified):** M1 (NIH — only libc-free in-tree keccak/identifier; ✓ after G1/G5), M2/W5 (canonical byte layout → bit-identical hash; ✓ after G8), M3/M4 (no learning/heuristics — pure table + serialization; ✓), M5 (✓ after G6 bounds), M6/M10 (witness fragments via wh_publish chain by hash; pre-image reproducible via ss_canonical_encode; ✓ after G2/G3), M8 (capability-gated ratify via cp_synth_admit + ratifier_capability; ✓ after G4), M12 (the spec *is* the checkable synthesis certificate — its raison d'être; ✓), M14 (provenance via content address; ✓ after G8). Ring R0 preserved (W7). W9 (negative i32 errors ✓), W10 (n/a — no u8 bool returns; `ident_eq` u8 consumed internally), W12 (every public fn returns status ✓), W13 (≤20 locals — encoder is the largest; stays under ✓), W14 (sentinel loops, no break ✓), W15 (no recursion ✓).

## Implementation Skeleton
```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\synthesis_spec.iii
 *
 * III STDLIB - numera::synthesis_spec
 *
 * The canonical specification language for synthesis problems. A spec
 * encodes program signature, algebraic constraints, cost-vector budget,
 * and verifier reference; its canonical encoding's Keccak256 content
 * address is the synthesis problem's canonical name; its ratification
 * under cp_synth_admit gates synthesis-engine invocation (W33).
 *
 * Hexad: kind_essence + kind_cognition.  Ring: R0.  K: 1.00.
 * NIH: depends on identifier.iii, keccak256.iii, constitution.iii(13),
 *      witness_hook.iii.  (NOT content_addr.iii, NOT witness_spine.iii.)
 * Discipline: W2 (sig aggregated), W8 (static tables), W12, W14, W15.
 * Reentrancy: serialized construction -- module-scope scratch is single-use.
 */

module numera_synthesis_spec

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const SYNSPEC_OK                      : i32 =  0i32
const SYNSPEC_E_NULL                  : i32 = -1i32
const SYNSPEC_E_FULL                  : i32 = -2i32
const SYNSPEC_E_ABSENT                : i32 = -3i32
const SYNSPEC_E_CLAUSE_ABSENT         : i32 = -4i32
const SYNSPEC_E_BUF_TOO_SMALL         : i32 = -5i32
const SYNSPEC_E_NOT_INITED            : i32 = -6i32
const SYNSPEC_E_TOO_MANY_CONSTRAINTS  : i32 = -7i32
const SYNSPEC_E_ARITY                 : i32 = -8i32
const SYNSPEC_SLOTS                   : u64 = 128u64
const SYNSPEC_MAX_CONSTRAINTS         : u64 = 32u64
const SYNSPEC_MAX_ARITY               : u64 = 32u64
const SYNSPEC_PREDICATE_BUF_BYTES     : u64 = 4096u64
const SYNSPEC_IDENT_BYTES             : u64 = 32u64
const SYNSPEC_COST_BYTES              : u64 = 32u64
const SYNSPEC_CONS_SENT               : u32 = 0xFFFFFFFFu32

var SYNSPEC_INITED            : u8  = 0u8
var SYNSPEC_COUNT             : u64 = 0u64
var SYNSPEC_LIVE              : [u8;  128]
var SYNSPEC_SPEC_IDS          : [u8;  4096]      // 128 * 32
var SYNSPEC_IN_ARITY          : [u32; 128]
var SYNSPEC_OUT_ARITY         : [u32; 128]
var SYNSPEC_IN_KINDS          : [u8;  4096]      // 128 * 32
var SYNSPEC_OUT_KINDS         : [u8;  4096]
var SYNSPEC_COST_VECTORS      : [u8;  4096]
var SYNSPEC_VERIFIER_MODULES  : [u8;  4096]
var SYNSPEC_VERIFIER_FNS      : [u8;  4096]
var SYNSPEC_CONSTRAINT_COUNTS : [u32; 128]
var SYNSPEC_CONSTRAINT_LENS   : [u32; 4096]      // 128 * 32
var SYNSPEC_CONSTRAINT_BUFS   : [u8;  16777216]  // 128 * 32 * 4096
var SYNSPEC_SEED_SCRATCH      : [u8;  16]
var SYNSPEC_ENC_SCRATCH       : [u8;  256]

fn ss_init() -> i32 @export { /* TODO: body per Algorithm ss_init -- zero LIVE + CONSTRAINT_COUNTS, set INITED. W14 sentinel loop. */ }

fn ss_alloc(out_spec_id: *u8) -> i32 @export { /* TODO: per Algorithm ss_alloc -- sentinel-flag free-slot scan; derive id from SYNSPEC_SEED_SCRATCH(seed prefix + slot LE32) via ident_from_bytes; ident_copy out; mark live. Trap 5 byte-wise slot index. */ }

fn ss_find_slot(spec_id: *u8) -> i64 { /* TODO: per Algorithm -- sentinel-flag linear scan; ident_eq; return i as i64 or -1i64. NOT @export. Compare -1i64 by == only (Trap 3). */ }

fn ss_set_signature(spec_id: *u8, sig: *u8) -> i32 @export { /* TODO: per Algorithm (G7 aggregate) -- find slot; read in/out arity LE32 from sig; bound-check <= SYNSPEC_MAX_ARITY (G6) else E_ARITY; copy kinds from sig+8 / sig+40. */ }

fn ss_add_constraint(spec_id: *u8, predicate: *u8, predicate_len: u32) -> i32 @export { /* TODO: per Algorithm -- find slot; count < MAX_CONSTRAINTS; len <= PREDICATE_BUF_BYTES (G6) else E_BUF_TOO_SMALL; copy into idx*PREDICATE_BUF_BYTES; bump count. No modulo (Trap 11). */ }

fn ss_set_cost_vector(spec_id: *u8, cost: *u8) -> i32 @export { /* TODO: per Algorithm -- find slot; byte-copy 32 cost bytes to COST_VECTORS[s*32]. */ }

fn ss_set_verifier(spec_id: *u8, verifier_module: *u8, verifier_fn: *u8) -> i32 @export { /* TODO: per Algorithm -- find slot; guard 3 nulls; ident_copy module + fn into VERIFIER_MODULES/FNS[s*32]. */ }

fn ss_canonical_encode(spec_id: *u8, out_buf: *u8, out_buf_cap: u64, out_len: *u64) -> i32 @export { /* TODO: per Algorithm (G2 RESTORE) -- compute need; if cap<need E_BUF_TOO_SMALL (u64 compare); serialize fixed field order with LE32 framing (Trap 5 byte-wise); write *out_len. */ }

fn ss_content_address(spec_id: *u8, out: *u8) -> i32 @export { /* TODO: per Algorithm (G8 framed) -- keccak256_init; update over id, arity block, kinds, cost, vmod, vfn, n_constraints, per-constraint(len+bytes) -- SAME layout as ss_canonical_encode; keccak256_final(out). Equivalence invariant. */ }

fn ss_emit(payload: *u8, payload_len: u32, in_commit: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: per Algorithm (G3 helper) -- stage zeroed producer/opid/out_commit + revtag/phase/pillar/antecedents from module-scope/const; single 12-arg wh_publish call; map u64 result (!= 0xFFFFFFFFFFFFFFFF) to SYNSPEC_OK. W2: 4 params here; the 12-arg form is the external call. */ }

fn ss_propose(spec_id: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: per Algorithm -- find slot; ss_content_address -> ca; build 72-byte SYNTH_SPEC_PROPOSAL (0xE3,0x04, ca@8, spec_id@40); ss_emit(in_commit=spec_id). */ }

fn ss_ratify(spec_id: *u8, ratifier_capability: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: per Algorithm -- guard 3 nulls; ident_from_bytes("cp_synth_admit",14)->clause_id; if cons_find == SYNSPEC_CONS_SENT E_CLAUSE_ABSENT (G4 FIX); find slot; build 104-byte SYNTH_SPEC_RATIFIED (0xE3,0x05, spec_id@8, cost@40, cap@72); ss_emit. M8 capability gate. */ }
```
