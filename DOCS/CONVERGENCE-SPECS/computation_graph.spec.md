# 56 numera/computation_graph.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body sketches all 8 public functions and the index data model coherently, but it is **not paste-ready**: every cross-call argument uses the confirmed-broken `&STATIC[expr]` element-address form (W3/W1, the substrate's documented `&GLOBAL[0]` parser bug), and every working buffer is a forbidden function-local `var` array (Trap 7). It also depends on two not-yet-built modules (`witness_spine.iii`, `constitution.iii`), externs a `ca_compute` it never calls, hard-codes V3 fragment-field byte offsets that no built module yet defines, and leaves the bisimulation/anchor witness producer+opid as un-filled placeholders ("a sealed-call wrapper inserts these"). The algorithm shape is sound and maximal; the realization must be rewritten against the in-tree idioms below.

## Purpose
`numera_computation_graph` is the **chain-as-DAG**: it abstracts the witness chain into one strictly append-only, linearly-ordered *canonical line* (`branch_id == 0`) plus append-only *side branches* (non-zero `branch_id`) rooted at declared anchor fragments. It is the substrate's **bisimulation primitive** — the formal-equivalence operator (W41/W42) by which two computations are compared and by which a branch may later be admitted to canonical influence. Hexad kind: `kind_essence + kind_witness`. Ring: **R0**. K-vector: **1.00**.

## Public API
All public functions return a status `i32` (W9 negative-error / W12); booleans never escape as anything but a sentinel. Signatures are SINGLE-LINE (Trap 1) exactly as they must appear:

```
fn cg_init() -> i32 @export
fn cg_canonical_head(out_fid: *u8) -> i32 @export
fn cg_branch_head(branch_id: *u8, out_fid: *u8) -> i32 @export
fn cg_resolve_fragment(fid: *u8, out_branch_id: *u8, out_position: *u64) -> i32 @export
fn cg_walk_segment(seg: *u8) -> i32 @export
fn cg_bisimulate(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8) -> i32 @export
fn cg_anchor_declare(fid: *u8, clause_id: *u8) -> i32 @export
fn cg_anchor_query(fid: *u8, out_clause_id: *u8) -> i32 @export
```

Return-status convention per fn:
- `cg_init` → `CG_OK` always (idempotent).
- `cg_canonical_head` / `cg_branch_head` → `CG_OK`, or `CG_E_NOT_INITED`, `CG_E_NULL`, `CG_E_BRANCH_ABSENT`.
- `cg_resolve_fragment` → `CG_OK` (writes `*out_branch_id`, `*out_position`), or `CG_E_NOT_INITED`, `CG_E_NULL`, `CG_E_FRAGMENT_ABSENT`.
- `cg_walk_segment` → `CG_OK`, or `CG_E_NOT_INITED`, `CG_E_NULL`, `CG_E_BRANCH_ABSENT`, `CG_E_FRAGMENT_ABSENT`. (See Gap list: the gospel's 4-param `*u8` visitor-callback form is replaced by a single pointer to a `CG_SEGMENT_REQ` aggregate per W2 + the no-function-pointer discipline.)
- `cg_bisimulate` → `CG_OK` (writes `*out_witness_fid`), or `CG_E_NOT_INITED`, `CG_E_NULL`, `CG_E_FRAGMENT_ABSENT`, `CG_E_NOT_BISIMILAR`.
- `cg_anchor_declare` → `CG_OK`, or `CG_E_NOT_INITED`, `CG_E_NULL`, `CG_E_CLAUSE_ABSENT`, `CG_E_ALREADY_ANCHOR`, `CG_E_INDEX_FULL`.
- `cg_anchor_query` → `CG_OK` (writes `*out_clause_id`), or `CG_E_NOT_INITED`, `CG_E_NULL`, `CG_E_NOT_ANCHOR`.

Two **internal** (non-`@export`) helpers, called only within this file, keep the public fns under W13/W2:
```
fn cg_branch_slot_find(branch_id: *u8) -> i64
fn cg_anchor_slot_find(fid: *u8) -> i64
```
Both return a slot index `>= 0i64` on hit or the sentinel `-1i64` on miss (compared with `==`/`!=` only, W11).

## Constant Namespace
PREFIX = `CG_` . Grep result: `grep -rn "^const CG_" STDLIB/iii/` and `grep -rln "CG_OK|CG_E_|CG_BRANCH|CG_ANCHOR|CG_CANONICAL|CG_INITED|CG_IDENT" STDLIB/iii/` both return **no matches** — the `CG_` prefix is collision-free across the built tree. (The downstream Module 57 `branch_anchor.iii` uses `BA_`, and it *externs* `cg_anchor_query`/`cg_bisimulate` from this module — no symbol clash.)

Module-level constants (every `const NAME : T = V`):
```
const CG_OK                : i32 =  0i32
const CG_E_NULL            : i32 = -1i32
const CG_E_BRANCH_ABSENT   : i32 = -2i32
const CG_E_FRAGMENT_ABSENT : i32 = -3i32
const CG_E_CLAUSE_ABSENT   : i32 = -4i32
const CG_E_ALREADY_ANCHOR  : i32 = -5i32
const CG_E_NOT_ANCHOR      : i32 = -6i32
const CG_E_NOT_BISIMILAR   : i32 = -7i32
const CG_E_INDEX_FULL      : i32 = -8i32
const CG_E_NOT_INITED      : i32 = -9i32
const CG_BRANCH_SLOTS      : u64 = 1024u64
const CG_ANCHOR_SLOTS      : u64 = 4096u64
const CG_IDENT_BYTES       : u64 = 32u64
const CG_FRAG_CAP          : u64 = 4096u64      /* max witness-fragment serialization length */
const CG_OFF_OP_ID         : u64 = 64u64        /* fragment field offset: operation_id   */
const CG_OFF_IN_COMMIT     : u64 = 96u64        /* fragment field offset: input_commit    */
const CG_OFF_OUT_COMMIT    : u64 = 128u64       /* fragment field offset: output_commit   */
const CG_OFF_AT_TIME       : u64 = 160u64       /* fragment field offset: algebraic_time  */
const CG_OFF_BRANCH_ID     : u64 = 168u64       /* fragment field offset: branch_id (V3)  */
const CG_BISIM_LO          : u64 = 64u64        /* bisim compare window start (op_id)     */
const CG_BISIM_HI          : u64 = 160u64       /* bisim compare window end (excl)        */
const CG_PAYLOAD_KIND      : u8  = 0x10u8       /* V3 payload kind: BISIMULATION_WITNESS  */
const CG_PAYLOAD_TAG       : u8  = 0xE3u8       /* V3 payload tag byte                    */
const CG_PAYLOAD_LEN       : u64 = 80u64        /* bisim witness payload length           */
```
NOTE the field-offset constants (`CG_OFF_*`) are a **contract this module imposes on `witness_spine.iii`'s fragment serialization layout**; see Gap list — the gospel hard-codes the raw integers (148, 128, 64, 96) inline and they are mutually inconsistent (`cg_resolve_fragment` reads branch_id at 148 and time at 128, while `cg_bisimulate` reads output_commit at 128). They must be unified against the real witness_spine layout once Module 54 is built.

## Data Structures
All buffers are module-scope (Trap 7: no function-local `var` arrays). Byte-addressed identifier tables are declared `[u64; bytes/8]` per the witness_hook.iii discipline (iiis allocates 8 bytes per array element; `[u64; B/8]` reserves EXACTLY B bytes and is accessed transparently via byte-pointer arithmetic). W8: every table is statically sized with the bound justified.

| Name | Type | Bytes | Bound justification |
|------|------|-------|---------------------|
| `CG_INITED` | `u8` | 1 | boot-once flag |
| `CG_CANONICAL_HEAD` | `[u8; 32]` | 32 | single 256-bit fragment id of the canonical head |
| `CG_CANONICAL_LEN` | `u64` | 8 | canonical chain length (positions) |
| `CG_BRANCH_IDS` | `[u64; 4096]` | 32768 | 1024 branch slots × 32 B; bound = `CG_BRANCH_SLOTS` |
| `CG_BRANCH_HEADS` | `[u64; 4096]` | 32768 | 1024 × 32 B head id per branch |
| `CG_BRANCH_LENS` | `[u64; 1024]` | 8192 | per-branch length |
| `CG_BRANCH_LIVE` | `[u8; 1024]` | 1024 | per-branch liveness |
| `CG_BRANCH_COUNT` | `u64` | 8 | live branch count |
| `CG_ANCHOR_FIDS` | `[u64; 16384]` | 131072 | 4096 anchor slots × 32 B; bound = `CG_ANCHOR_SLOTS` |
| `CG_ANCHOR_CLAUSES` | `[u64; 16384]` | 131072 | 4096 × 32 B governing clause id |
| `CG_ANCHOR_LIVE` | `[u8; 4096]` | 4096 | per-anchor liveness |
| `CG_ANCHOR_COUNT` | `u64` | 8 | live anchor count |
| `CG_FRAG_L` | `[u64; 512]` | 4096 | left/scratch fragment serialization (was local `[u8;4096]`); `CG_FRAG_CAP` bytes |
| `CG_FRAG_R` | `[u64; 512]` | 4096 | right fragment serialization (was local `[u8;4096]`) |
| `CG_FRAG_L_LEN` | `u64` | 8 | length sink for `CG_FRAG_L` |
| `CG_FRAG_R_LEN` | `u64` | 8 | length sink for `CG_FRAG_R` |
| `CG_PAYLOAD` | `[u8; 80]` | 80 | bisim witness payload (was local `[u8;80]`) |
| `CG_SC_PRODUCER` | `[u8; 32]` | 32 | producer id scratch for emit (was local) |
| `CG_SC_OP` | `[u8; 32]` | 32 | operation id scratch for emit (was local) |
| `CG_SC_IN` | `[u8; 32]` | 32 | input-commit scratch for emit (was local) |
| `CG_SC_OUT` | `[u8; 32]` | 32 | output-commit scratch for emit (was local) |
| `CG_SC_LFID` | `[u8; 32]` | 32 | left-fid copy (param-spill safety before passing to extern) |
| `CG_SC_RFID` | `[u8; 32]` | 32 | right-fid copy |
| `CG_SC_BID` | `[u8; 32]` | 32 | branch-id copy scratch for slot-find |
| `CG_SC_CLAUSE` | `[u8; 32]` | 32 | clause-id copy scratch |
| `CG_SELFTEST_*` | `[u8; 32]` ×4 | 128 | KAT scratch ids |

Reentrancy note (Trap 7): the module-scope scratch makes `cg_bisimulate`, `cg_resolve_fragment`, and the slot-find helpers **non-reentrant** — acceptable, because R0 chain mutation is serialized through the single-threaded substrate gate (same posture as `content_addr.iii`'s `CA_BUF` and `witness_hook.iii`'s scratch). Flag for Phase 2: do not call these re-entrantly.

`CG_SEGMENT_REQ` aggregate (passed by pointer to `cg_walk_segment`, replacing the 4 scalar params + visitor callback — W2 + no-function-pointer discipline). Layout (a caller-owned 56-byte record, NOT a module-scope var):
```
offset 0  : branch_id        (32 B)   — chain to walk (zero = canonical)
offset 32 : from_pos         (u64)    — inclusive start position
offset 40 : to_pos           (u64)    — inclusive end position
offset 48 : out_count        (u64)    — written: number of fragments visited
```
Replay consumers read fragment ids in order via repeated `cg_resolve_fragment`/`ws_lookup_fragment` keyed by position; the segment walk returns the visited count rather than invoking a function pointer (W1/W3: no global pointer escape, no callback into caller code from inside the chain core).

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`:

| Extern (single-line) | From | NN | Built? |
|---|---|---|---|
| `fn ident_zero(out: *u8) -> i32` | identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | identifier.iii | 01 | **BUILT** (verified) |
| `fn ws_lookup_fragment(fid: *u8, out_fragment: *u8, out_len: *u64) -> i32` | witness_spine.iii | 54 | **NOT BUILT** |
| `fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32` | witness_spine.iii | 54 | **NOT BUILT** |
| `fn cons_find(clause_id: *u8) -> i32` | constitution.iii | (Layer 2/3 governance) | **NOT BUILT** |

Verified-built dependency `content_addr.iii` (Module 55) is in the tree with real API `ca_compute(producer, operation, input_commit, out) -> i32` (arity/semantics match the gospel extern). **However the gospel declares `ca_compute` and never calls it** — drop the unused extern (see Gap list). `algebraic_time.iii` is BUILT (`at_current`/`at_advance`/`at_init`), needed by Module 57 not by this module.

Wave-scheduler ordering: this module is **blocked on Module 54 (witness_spine.iii)** and **constitution.iii**. It must not enter Phase 2 build until both exist and their real signatures are confirmed; the `CG_OFF_*` field offsets and `ws_emit_fragment` producer/op arguments are contracts to reconcile against witness_spine's actual serialization. Downstream Modules **57, 58, 68, 69** extern `cg_*` from here.

> **Cross-batch gospel defect (flagged per dispatch):** the systemic `extern keccak256_init/update/final from "keccak.iii"` error does **not** occur in this module — Module 56 hashes nothing directly (it delegates content addressing to `ca_compute`/`ws_emit_fragment`). No keccak extern appears here. The note is recorded for completeness; no fix needed in this module.

## Algorithm
NIH (M1): pure index bookkeeping + byte comparison; no third-party anything. No ML/heuristics (M3/M4): every decision is exact equality on 32-byte ids or exact byte-XOR equality on fragment field windows. No recursion (W15): all scans are explicit `while` loops over fixed module-scope tables. Determinism (M2)/bit-identity (W5): outputs are functions only of recorded inputs and table contents; no time, no address values leak into outputs (positions come from the fragment's own `algebraic_time` field, not from wall-clock).

**`cg_init`** — idempotent boot. If `CG_INITED == 1u8` return `CG_OK`. Zero `CG_CANONICAL_HEAD` (via `ident_zero` on `(&CG_CANONICAL_HEAD as u64) as *u8`), set `CG_CANONICAL_LEN = 0`. Sentinel-loop `i` from 0 to `CG_BRANCH_SLOTS`: clear `CG_BRANCH_LIVE[i]=0`, `CG_BRANCH_LENS[i]=0`. Sentinel-loop `j` to `CG_ANCHOR_SLOTS`: clear `CG_ANCHOR_LIVE[j]=0`. Zero both counts; set `CG_INITED=1`.

**`cg_canonical_head`** — guard `CG_INITED`/null; `ident_copy((&CG_CANONICAL_HEAD as u64) as *u8, out_fid)`; return `CG_OK`. (Reversibility M9: pure read.)

**`cg_branch_slot_find`** (internal) — copy `branch_id` into `CG_SC_BID` first (param-spill safety, Trap 11 family). Sentinel-loop `i` 0..`CG_BRANCH_SLOTS` with an active flag `found_flag` (W14, no break): for each `i`, when `found_flag==0u8` and `CG_BRANCH_LIVE[i]==1u8`, compute the slot base pointer `((&CG_BRANCH_IDS as u64) + i*CG_IDENT_BYTES) as *u8` and compare with `ident_eq(slot_ptr, (&CG_SC_BID as u64) as *u8)`; on hit set `found = i as i64`, `found_flag=1u8`. Return `found` (init `-1i64`). The active flag drives the body only — the loop counter still bounds the `while` (per the iiis insertion-sort active-flag trap in memory; the flag does NOT replace the loop condition).

**`cg_branch_head`** — guard; `slot = cg_branch_slot_find(branch_id)`; if `slot == -1i64` return `CG_E_BRANCH_ABSENT`; `ident_copy(((&CG_BRANCH_HEADS as u64) + (slot as u64)*CG_IDENT_BYTES) as *u8, out_fid)`; `CG_OK`.

**`cg_resolve_fragment`** — guard all three pointers. `lookup = ws_lookup_fragment(fid, (&CG_FRAG_L as u64) as *u8, (&CG_FRAG_L_LEN as u64) as *u64)`; if `lookup != 0i32` return `CG_E_FRAGMENT_ABSENT`. Extract the 32-byte branch_id by copying `CG_FRAG_L[CG_OFF_BRANCH_ID + k]` into `out_branch_id[k]` for `k` 0..32 (byte loop). Read position: accumulate `p |= (CG_FRAG_L[CG_OFF_AT_TIME + k] as u64) << (k*8)` for `k` 0..8; write `*out_position = p`. The canonical line is `branch_id == 0` — the all-zero id — which `out_branch_id` will naturally carry. `CG_OK`. (Determinism: position is the fragment's own algebraic_time, recomputable from the stored fragment.)

**`cg_walk_segment`** — guard `seg`/`CG_INITED`. Read `branch_id` (offset 0), `from_pos` (offset 32), `to_pos` (offset 40) out of the `CG_SEGMENT_REQ`. Validate the branch exists (zero ⇒ canonical, else `cg_branch_slot_find`). Sentinel-loop position `pos` from `from_pos` while `pos != to_pos+1` (equality-bounded, W11/W14): each step resolves the fragment at that position by walking the spine (`ws_lookup_fragment` keyed by position once witness_spine exposes positional lookup), increments a visit counter. Write the counter to `seg+48`. Return `CG_OK`, or `CG_E_FRAGMENT_ABSENT` if a position has no fragment. (No callback — replay consumers re-derive ids by position; W1/W3 honored.)

**`cg_bisimulate`** — the W41/W42 primitive. Guard all three pointers. Copy `left_fid`→`CG_SC_LFID`, `right_fid`→`CG_SC_RFID` (param-spill safety before the extern calls). `ws_lookup_fragment` each into `CG_FRAG_L`/`CG_FRAG_R`; on either miss return `CG_E_FRAGMENT_ABSENT`. **Shallow bisimulation** = byte-exact equality of the `(operation_id, input_commit, output_commit)` field window `[CG_BISIM_LO, CG_BISIM_HI)`: accumulate `acc |= ((CG_FRAG_L[i] as u32) ^ (CG_FRAG_R[i] as u32))` for `i` in window (mask each side with `& 0xFFu32` since they are bytes; W4 on the u32 accumulator). If `acc != 0u32` return `CG_E_NOT_BISIMILAR`. Otherwise build `CG_PAYLOAD`: bytes 0..32 = left fid, 32..64 = right fid, byte 64 = `CG_PAYLOAD_TAG` (0xE3), byte 65 = `CG_PAYLOAD_KIND` (0x10), 66..80 = zero. Zero the four emit-scratch ids with `ident_zero`. Emit: `return ws_emit_fragment((&CG_SC_PRODUCER as u64) as *u8, (&CG_SC_OP as u64) as *u8, (&CG_SC_IN as u64) as *u8, (&CG_SC_OUT as u64) as *u8, (&CG_PAYLOAD as u64) as *u8, CG_PAYLOAD_LEN, out_witness_fid)`. The emitted fragment IS the bisimulation witness; it chains by hash (M6) and is recomputable from the two recorded fids (M10). **M11/M18 (Curry-Howard / theorem-carrier):** the witness fragment is the proof term — an equivalence claim cannot exist without it (W41); W42's merge gate (Module 57) consumes exactly this fragment. *Maximal-intent note:* the gospel calls the shallow form sufficient "for V2 closure"; the maximal realization additionally records, in payload bytes 66..80, the compared field-window hash and a depth marker so a future antecedent-walking deep bisimulation can extend the same witness format without a breaking change (see Gap list — producer/opid must be real, not zero).

**`cg_anchor_slot_find`** (internal) — copy `fid`→`CG_SC_*` scratch; sentinel-loop with active flag over `CG_ANCHOR_SLOTS`, `ident_eq` against `((&CG_ANCHOR_FIDS as u64)+i*32) as *u8`; return slot or `-1i64`.

**`cg_anchor_declare`** — guard. `if cons_find(clause_id) != 0i32 return CG_E_CLAUSE_ABSENT` (capability/governance gate, M8: the clause IS the capability authorizing a branch anchor). Check not-already: `if cg_anchor_slot_find(fid) != -1i64 return CG_E_ALREADY_ANCHOR`. Find a free slot via a second sentinel-loop (active flag) over `CG_ANCHOR_LIVE[j]==0u8`; if none, `CG_E_INDEX_FULL`. `ident_copy(fid, ((&CG_ANCHOR_FIDS as u64)+s*32) as *u8)`, `ident_copy(clause_id, ((&CG_ANCHOR_CLAUSES as u64)+s*32) as *u8)`, set `CG_ANCHOR_LIVE[s]=1`, `CG_ANCHOR_COUNT += 1`. `CG_OK`. (Append-only/M5: declaring an anchor never removes one; no un-anchor primitive exists — reversibility is by refusal, not deletion.)

**`cg_anchor_query`** — guard; `slot = cg_anchor_slot_find(fid)`; if `-1i64` return `CG_E_NOT_ANCHOR`; `ident_copy(((&CG_ANCHOR_CLAUSES as u64)+(slot as u64)*32) as *u8, out_clause_id)`; `CG_OK`.

## KAT Vectors (>= 3)
A `cg_selftest() -> u64 @export` (99 = pass) checks these byte-for-byte. Inputs use `ident_*` to fabricate deterministic ids; `ws_*`/`cons_*` are exercised via stub fragments once witness_spine/constitution exist (until then, KATs 4–5 are gated on those modules — noted as Phase-2-blocked).

1. **init + canonical head is zero.** After `cg_init()`, `cg_canonical_head(&CG_SELFTEST_A)` ⇒ `CG_OK` and `CG_SELFTEST_A` is all-zero (the genesis canonical head). Expect `ident_is_zero == 1`.
2. **anchor declare/query round-trip + already-anchor + absent.** With a present clause (cons_find==0): `cg_anchor_declare(fidX, clauseY)` ⇒ `CG_OK`; `cg_anchor_query(fidX, out)` ⇒ `CG_OK` and `out == clauseY` (ident_eq==1); a second `cg_anchor_declare(fidX, clauseY)` ⇒ `CG_E_ALREADY_ANCHOR`; `cg_anchor_query(fidZ, out)` for un-declared `fidZ` ⇒ `CG_E_NOT_ANCHOR`.
3. **clause-absent refusal (prove the negative).** With `cons_find(clauseW) != 0`, `cg_anchor_declare(fidV, clauseW)` ⇒ `CG_E_CLAUSE_ABSENT` (NOT `CG_OK`) — proves the governance gate FAILS closed, not just opens.
4. **bisimulation identity vs. mismatch (Phase-2, needs witness_spine).** Two fragments with byte-identical `[64,160)` windows ⇒ `cg_bisimulate` returns `CG_OK` and writes a non-zero `out_witness_fid`; flipping one byte in `output_commit` (offset 128) of the right fragment ⇒ `CG_E_NOT_BISIMILAR`. Re-running the identical case twice yields the **same** witness fid (M2/M10 determinism).
5. **not-inited guard (prove the negative).** Before `cg_init()` (fresh `CG_INITED==0`), every public fn returns `CG_E_NOT_INITED` — proves the boot gate FAILS closed.

## Trap Exposure
| # | Trap | Touched? | Avoidance in this spec |
|---|------|----------|------------------------|
| 1 | Multi-line `fn` | yes (every fn) | every signature in Public API is SINGLE-LINE. |
| 2 | Module-`const` linker-global | yes (24 consts) | all prefixed `CG_`; grep-confirmed no STDLIB collision. |
| 3 | Signed-ordering SIGSEGV | yes (slot sentinels `-1i64`) | compared with `==`/`!=` ONLY (`slot == -1i64`, `slot != -1i64`); never `<`/`>`/`<=`/`>=`. Loop bounds are `u64` unsigned compares. |
| 4 | u32-in-u64-slot garbage | yes (`i as i64`/slot math) | slot indices are `u64`/`i64` throughout; before any pointer math the index is multiplied as `u64` (`i*CG_IDENT_BYTES`), no `u32`→`u64` widen of a u32 local feeds pointer arithmetic. |
| 5 | u32 pointer store width | no | no `*u32` stores; all id/payload writes are byte (`*u8`) or whole-`u64` field writes. |
| 6 | Nested `/* */` | n/a | header + inline use single-level `/* */` and `//`; no nesting. |
| 7 | Local `var` arrays | **YES (primary gospel defect)** | EVERY gospel function-local array (`scratch_frag[4096]`, `left_frag`, `right_frag`, `payload[80]`, `producer/op/in/out[32]`) is relocated to module scope (`CG_FRAG_L/R`, `CG_PAYLOAD`, `CG_SC_*`). Non-reentrancy noted. |
| 8 | `} else {` one line | n/a | no `else` blocks in the design (guard-clause early-returns + sentinel flags). |
| 9 | Em-dash in comment | yes (prose) | all comments use ASCII `--`, never U+2014. |
| 10 | `let mut x=0u32` flag | yes (sentinel/active flags) | flags are `u8` (`found_flag`, `sentinel`) and follow the established active-flag-drives-body pattern; loop counter still bounds the `while`. Early-return used where a flag is unnecessary. |
| 11 | `%` after call | no modulo used | the design has NO `%`; all addressing is `*` (index×stride). Param-spill mitigated by copying every incoming `*u8` id into `CG_SC_*` scratch before passing to an extern. |
| 12 | `@specialize *T` stride | no | module is not generic; fixed 32-byte id stride, explicit byte loops. |
| — | **W3/W1 `&STATIC[expr]` element-address** (13th, broader-than-catalog) | **YES (pervasive gospel defect)** | the gospel passes `&CG_BRANCH_IDS[i*32u64]`, `&CG_CANONICAL_HEAD[0u64]`, etc. directly — the documented `&GLOBAL[0]` parser bug yields a non-address. Fix (proven in `witness_hook.iii`/`layered_seal.iii`): `((&ARR as u64) + off) as *u8`. Whole-array base passes use `(&ARR as u64) as *u8`. |

## Gap / Fix List
The candidate body is PARTIAL. Every gap with its fix:

1. **W3/W1 element-address-of-static (pervasive, build-breaking).** Gospel calls `ident_zero(&CG_CANONICAL_HEAD[0u64])`, `ident_copy(&CG_BRANCH_HEADS[(slot as u64)*32u64], out_fid)`, `ident_eq(&CG_BRANCH_IDS[i*32u64], branch_id)`, `&CG_ANCHOR_FIDS[i*32u64]`, `&CG_ANCHOR_CLAUSES[s*32u64]`, and on locals `&scratch_frag[0u64]`, `&payload[0u64]`, `&producer[0u64]`. **Fix:** replace every `&ARR[off]` with `((&ARR as u64) + off) as *u8` and every `&ARR[0u64]` with `(&ARR as u64) as *u8` (in-tree-verified idiom).
2. **Trap 7 — function-local `var` arrays.** Gospel declares `let mut scratch_frag : [u8; 4096]`, `let mut left_frag/right_frag : [u8; 4096]`, `let mut payload : [u8; 80]`, `let mut producer/op/in_commit/out_commit : [u8; 32]` inside fn bodies. **Fix:** all relocated to module scope (`CG_FRAG_L`, `CG_FRAG_R`, `CG_PAYLOAD`, `CG_SC_*`); document non-reentrancy.
3. **Not-yet-built dependencies.** `witness_spine.iii` (Module 54: `ws_lookup_fragment`, `ws_emit_fragment`) and `constitution.iii` (`cons_find`) do not exist in the tree. **Fix (scheduling):** mark this module blocked behind Module 54 + constitution; do not Phase-2-build until their real signatures are confirmed. KATs 4–5 are gated likewise.
4. **Unused extern `ca_compute`.** Gospel externs `ca_compute` from content_addr.iii but never calls it (content addressing happens inside `ws_emit_fragment`). **Fix:** drop the extern (dead import; keeps the dependency graph honest).
5. **Inconsistent / undefined fragment field offsets.** `cg_resolve_fragment` reads branch_id at byte **148** and algebraic_time at **128**; `cg_bisimulate` simultaneously treats **128** as output_commit and compares window **[64,160)**. These overlap and are internally contradictory, and no built module defines the V3 fragment layout. **Fix:** centralize as `CG_OFF_*` constants and reconcile against `witness_spine.iii`'s actual serialization once Module 54 lands (the offsets in this spec are the proposed contract: op_id 64, in_commit 96, out_commit 128, at_time 160, branch_id 168 — non-overlapping).
6. **Placeholder bisimulation-witness producer/opid (M11/M12/M18 hole).** Gospel zeroes `producer`/`op` and comments "a sealed-call wrapper inserts these" — i.e. an unfinished stub. A witness emitted with a zero producer and zero operation id is not a checkable certificate (M12) and not a theorem carrier (M18). **Fix:** the producer must be this module's canonical content-id and the op must a fixed `CG_BISIMULATION_WITNESS_OPID` (a compile-time 32-byte constant id, e.g. `ident_from_bytes` of the ASCII tag `"cg.bisimulation.witness"` computed once in `cg_init` into a module-scope `CG_SELF_PRODUCER`/`CG_BISIM_OPID`). Phase 2 must fill these, not leave zeros.
7. **W2 — `cg_walk_segment` arity + function-pointer visitor.** Gospel signature is `cg_walk_segment(branch_id, from_pos, to_pos, visitor_ctx)` (4 `*u8`/`u64` params) and the prose says "visitor receives each fragment id" — a callback, which violates the no-global-pointer-escape discipline (W1/W3) and pushes the param budget. **Fix:** collapse to `cg_walk_segment(seg: *u8)` over a `CG_SEGMENT_REQ` aggregate; return a visited-count in the aggregate; replay consumers re-derive ids positionally (no callback into caller code).
8. **`cg_branch_slot_find` active-flag shape (iiis trap, latent).** Gospel uses `sentinel`-gated body inside a counter-bounded `while` — this is the correct pattern, but the memory note "iiis-1 insertion-sort active-flag trap" warns the flag must NOT become the loop condition. **Fix:** keep the loop bounded by `i < CG_BRANCH_SLOTS`; the `found`/`sentinel` flag gates only the body. (Already correct in the gospel; preserved and called out so Phase 2 does not "optimize" it into a flag-driven `while`.)
9. **Param-spill hardening (Trap 11 family).** Incoming `*u8` ids (`branch_id`, `fid`, `left_fid`, `right_fid`, `clause_id`) are each used once then passed to an extern — exactly the single-use param-spill pattern. **Fix:** copy each into a `CG_SC_*` module buffer (assignment to a named location) before the extern call, so no extern reads an unspilled register/stack slot.
10. **Reversibility/append-only audit (M5/M9/W16/W17).** Confirmed compliant by design: no public fn deletes a branch, anchor, or canonical fragment; the only mutations are monotonic appends (anchor add, branch head advance) and the bisimulation witness emission (itself append-only via `ws_emit_fragment`). No bricking path. Algebraic time advances only inside `ws_emit_fragment` (monotonic), never reset here.
11. **M3/M4 audit.** No counting-and-promoting, no thresholds, no observation: bisimulation is exact byte-XOR equality, anchoring is exact id match + clause presence. Clean.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/computation_graph.iii -- Layer 3, Module 56.
 * Chain-as-DAG: canonical line (branch_id 0, append-only, linearly ordered)
 * plus append-only side branches rooted at declared anchors.  Provides the
 * bisimulation primitive (W41/W42): no equivalence claim without a witness;
 * no merge to canonical without bisimulation verification.
 * Hexad: kind_essence + kind_witness.  Ring: R0.  K: 1.00.
 * NIH: identifier.iii (built) + witness_spine.iii (Mod 54, pending) +
 *      constitution.iii (pending).  Hand-rolled index bookkeeping only.
 * Idioms: element-address via ((&ARR as u64)+off) as *u8 (W3 parser-bug
 *   workaround); all working buffers module-scope (no local var arrays);
 *   ASCII -- in comments only; equality-only signed compares (W11). */
module numera_computation_graph

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ws_lookup_fragment(fid: *u8, out_fragment: *u8, out_len: *u64) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> i32 from "constitution.iii"

const CG_OK                : i32 =  0i32
const CG_E_NULL            : i32 = -1i32
const CG_E_BRANCH_ABSENT   : i32 = -2i32
const CG_E_FRAGMENT_ABSENT : i32 = -3i32
const CG_E_CLAUSE_ABSENT   : i32 = -4i32
const CG_E_ALREADY_ANCHOR  : i32 = -5i32
const CG_E_NOT_ANCHOR      : i32 = -6i32
const CG_E_NOT_BISIMILAR   : i32 = -7i32
const CG_E_INDEX_FULL      : i32 = -8i32
const CG_E_NOT_INITED      : i32 = -9i32
const CG_BRANCH_SLOTS      : u64 = 1024u64
const CG_ANCHOR_SLOTS      : u64 = 4096u64
const CG_IDENT_BYTES       : u64 = 32u64
const CG_FRAG_CAP          : u64 = 4096u64
const CG_OFF_OP_ID         : u64 = 64u64
const CG_OFF_IN_COMMIT     : u64 = 96u64
const CG_OFF_OUT_COMMIT    : u64 = 128u64
const CG_OFF_AT_TIME       : u64 = 160u64
const CG_OFF_BRANCH_ID     : u64 = 168u64
const CG_BISIM_LO          : u64 = 64u64
const CG_BISIM_HI          : u64 = 160u64
const CG_PAYLOAD_TAG       : u8  = 0xE3u8
const CG_PAYLOAD_KIND      : u8  = 0x10u8
const CG_PAYLOAD_LEN       : u64 = 80u64

var CG_INITED         : u8  = 0u8
var CG_CANONICAL_HEAD : [u8; 32]
var CG_CANONICAL_LEN  : u64 = 0u64

var CG_BRANCH_IDS     : [u64; 4096]    /* 1024 * 32 bytes */
var CG_BRANCH_HEADS   : [u64; 4096]
var CG_BRANCH_LENS    : [u64; 1024]
var CG_BRANCH_LIVE    : [u8;  1024]
var CG_BRANCH_COUNT   : u64 = 0u64

var CG_ANCHOR_FIDS    : [u64; 16384]   /* 4096 * 32 bytes */
var CG_ANCHOR_CLAUSES : [u64; 16384]
var CG_ANCHOR_LIVE    : [u8;  4096]
var CG_ANCHOR_COUNT   : u64 = 0u64

var CG_FRAG_L         : [u64; 512]     /* 4096-byte fragment scratch (left) */
var CG_FRAG_R         : [u64; 512]     /* 4096-byte fragment scratch (right) */
var CG_FRAG_L_LEN     : u64 = 0u64
var CG_FRAG_R_LEN     : u64 = 0u64
var CG_PAYLOAD        : [u8; 80]
var CG_SC_PRODUCER    : [u8; 32]
var CG_SC_OP          : [u8; 32]
var CG_SC_IN          : [u8; 32]
var CG_SC_OUT         : [u8; 32]
var CG_SC_LFID        : [u8; 32]
var CG_SC_RFID        : [u8; 32]
var CG_SC_BID         : [u8; 32]
var CG_SC_CLAUSE      : [u8; 32]
var CG_SELF_PRODUCER  : [u8; 32]       /* this module's canonical producer id */
var CG_BISIM_OPID     : [u8; 32]       /* BISIMULATION_WITNESS operation id   */
var CG_OPTAG          : [u8; 23]       /* ASCII "cg.bisimulation.witness"      */

var CG_ST_A : [u8; 32]
var CG_ST_B : [u8; 32]
var CG_ST_C : [u8; 32]
var CG_ST_O : [u8; 32]

fn cg_init() -> i32 @export { /* TODO: body per Algorithm cg_init (zero head/tables, derive CG_SELF_PRODUCER + CG_BISIM_OPID via ident_from_bytes of CG_OPTAG, set CG_INITED) */ return CG_OK }
fn cg_canonical_head(out_fid: *u8) -> i32 @export { /* TODO: guard + ident_copy((&CG_CANONICAL_HEAD as u64) as *u8, out_fid) */ return CG_OK }
fn cg_branch_slot_find(branch_id: *u8) -> i64 { /* TODO: copy->CG_SC_BID; sentinel scan; ident_eq(((&CG_BRANCH_IDS as u64)+i*32) as *u8, ...); return slot or -1i64 */ return -1i64 }
fn cg_anchor_slot_find(fid: *u8) -> i64 { /* TODO: copy->scratch; sentinel scan CG_ANCHOR_FIDS; return slot or -1i64 */ return -1i64 }
fn cg_branch_head(branch_id: *u8, out_fid: *u8) -> i32 @export { /* TODO: guard; slot=cg_branch_slot_find; if == -1i64 -> CG_E_BRANCH_ABSENT; ident_copy of head slot */ return CG_OK }
fn cg_resolve_fragment(fid: *u8, out_branch_id: *u8, out_position: *u64) -> i32 @export { /* TODO: guard; ws_lookup_fragment into CG_FRAG_L; copy branch_id @CG_OFF_BRANCH_ID; assemble position @CG_OFF_AT_TIME; *out_position = p */ return CG_OK }
fn cg_walk_segment(seg: *u8) -> i32 @export { /* TODO: guard; read CG_SEGMENT_REQ (bid@0,from@32,to@40); validate branch; equality-bounded pos loop; write count@48 */ return CG_OK }
fn cg_bisimulate(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8) -> i32 @export { /* TODO: guard; copy fids->CG_SC_LFID/RFID; ws_lookup both; XOR window [CG_BISIM_LO,CG_BISIM_HI); if acc!=0 -> CG_E_NOT_BISIMILAR; build CG_PAYLOAD; ws_emit_fragment(CG_SELF_PRODUCER, CG_BISIM_OPID, ...) */ return CG_OK }
fn cg_anchor_declare(fid: *u8, clause_id: *u8) -> i32 @export { /* TODO: guard; if cons_find!=0 -> CG_E_CLAUSE_ABSENT; if cg_anchor_slot_find!=-1i64 -> CG_E_ALREADY_ANCHOR; find free slot or CG_E_INDEX_FULL; ident_copy fid+clause; mark live; count++ */ return CG_OK }
fn cg_anchor_query(fid: *u8, out_clause_id: *u8) -> i32 @export { /* TODO: guard; slot=cg_anchor_slot_find; if -1i64 -> CG_E_NOT_ANCHOR; ident_copy clause slot -> out */ return CG_OK }
fn cg_selftest() -> u64 @export { /* TODO: KAT 1-3 unconditional; KAT 4-5 gated on witness_spine/constitution; 99 = pass */ return 99u64 }
```
