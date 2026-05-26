# 13 numera/constitution.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically complete and the witness-payload serializer matches the Part VII schema, but it ships **four blocking compiler-trap violations** (Trap 7: four function-local `var` arrays), **three W2 violations** (7/8/8-parameter public functions), **three dead externs that name symbols absent from `keccak.iii`** (would fail the link), and several M5 (No-Bricking) robustness gaps in the predicate interpreter (unbounded stack push, missing operand-length guards, missing producer-not-set guard). All are mechanical to close; the core design is sound and maximal.

## Purpose
`numera::constitution` makes constitutional clauses first-class substrate objects. A clause carries a textual statement, an LTL formula, an admissibility-predicate **bytecode**, a witness-production rule, dependencies on prior clauses, and an effective epoch (algebraic time). Clauses live in a fixed slot table keyed by `clause_id = Keccak256(textual)`. Ratification publishes a `CLAUSE_RATIFICATION_OPID` witness fragment whose payload follows the Part VII `clause_payload` schema; the embedded admissibility predicate is a stack-machine bytecode evaluated by `cons_eval_predicate` over a candidate operation's attributes (producer, op-id, phase, pillar, revtag, antecedents). It is the law-bearing essence of the substrate: clauses are the data structure the preserver continuously checks the chain against.
- **Hexad:** `kind_essence`
- **Ring:** R−1 (supervisor layer; this is governing-law state, write-mediated by the witness hook)
- **K:** 1.00 (scalar; deterministic, total — no allocation that can fail at this layer because all storage is module-scope static)

## Public API
All five are `@export`. Return-status conventions per W9/W12 are noted inline.

```iii
fn cons_init() -> i32 @export
```
Returns `CONS_OK` (0i32). Idempotent reset of the slot table + arenas + canonical ids. (W12: status return.)

```iii
fn cons_find(clause_id: *u8) -> u32 @export
```
Returns the live slot index, or the sentinel `CONS_SENT` (0xFFFFFFFFu32) if not found. (W12: sentinel-typed value.)

```iii
fn cons_ratify(req: *u8) -> u64 @export
```
**W2-compliant maximal form** (see Gap §G2). `req` points to a `cons_ratify_req` aggregate (layout in Data Structures). Returns the witness fragment index, or `0xFFFFFFFFFFFFFFFFu64` on any failure (arena full / duplicate clause / slot table full). The clause id is written through the `out_clause_id` field of the aggregate. (W12: sentinel-typed u64.)

```iii
fn cons_supersede(req: *u8) -> u64 @export
```
**W2-compliant maximal form.** `req` points to a `cons_supersede_req` aggregate (a `cons_ratify_req` plus a leading `prior_id` field). Ratifies the new clause, then records `prior_id` in the new slot's `CONS_SUPERSEDES` row. Returns the new fragment index or the u64 sentinel if `prior_id` is unknown or ratify fails. (W12: sentinel-typed u64.)

```iii
fn cons_eval_predicate(slot: u32, opv: *u8, ante_ids: *u8, n_ante: u32) -> u8 @export
```
**W2-compliant maximal form** (4 params exactly). `opv` points to a `cons_op_view` aggregate carrying `(op_producer[32], op_id[32], op_phase u8, op_pillar u16, op_revtag u8)`. Evaluates the slot's admissibility-predicate bytecode against the operation view and antecedent list. Returns `1u8` (admissible / no predicate present) or `0u8` (refused / bad slot). (W10: boolean u8 return.)

> **Gospel-form note:** the gospel writes these as flat-parameter signatures —
> `cons_ratify(textual,textual_len,ltl,ltl_len,pred,pred_len,out_clause_id) -> u64`,
> `cons_supersede(prior_id,…same…) -> u64`,
> `cons_eval_predicate(slot,op_producer,op_id,op_phase,op_pillar,op_revtag,ante_ids,n_ante) -> u8`.
> Those are 7/8/8 params and **violate W2**. Phase 2 must implement the aggregate-by-pointer forms above. The flat forms MAY additionally be retained as thin `@export` shims that pack the aggregate, if call-site compatibility is required — but the canonical entry points are the 4-or-fewer-param pointer forms. (Note: the dependency `witness_hook.iii::wh_publish` itself ships with 13 params, so the tree tolerates wide signatures in practice; nevertheless this spec honors the W2 mandate literally and treats the aggregate form as the contract.)

## Constant Namespace
**PREFIX = `CONS_`** (clause-bytecode opcodes use the sub-prefix `COP_`).
Grep result: `grep -rn "^const CONS_\|^var CONS_\|^const COP_\|CONSTIT_" STDLIB/` returns **no matches** — neither `CONS_`, `COP_`, nor the dispatch-suggested `CONSTIT_` collide with any existing STDLIB symbol. PREFIX retained as `CONS_` (the gospel body already uses it; switching to `CONSTIT_` would be gratuitous and the dispatch invited adjustment-with-note — noted here, kept as `CONS_`).

Module-level consts (all carry the linker-global `L_` symbol per Trap 2; prefix makes them unique):

| name | type | value |
|---|---|---|
| `CONS_OK` | i32 | `0i32` |
| `CONS_E_FULL` | i32 | `-1i32` |
| `CONS_E_NOT_FOUND` | i32 | `-2i32` |
| `CONS_SENT` | u32 | `0xFFFFFFFFu32` |
| `CONS_U64_SENT` | u64 | `0xFFFFFFFFFFFFFFFFu64` (new — replaces the inline magic literal repeated 6× in the body) |
| `CONS_MAX_CLAUSES` | u32 | `1024u32` |
| `CONS_TEXT_AREA` | u64 | `1048576u64` |
| `CONS_LTL_AREA` | u64 | `1048576u64` |
| `CONS_PRED_AREA` | u64 | `524288u64` |
| `CONS_ID_BYTES` | u64 | `32u64` (new — names the identifier width; removes magic `32u64`) |
| `CONS_PL_MAX` | u64 | `8192u64` (new — the payload-scratch bound, see Data Structures) |
| `CONS_STACK_MAX` | u32 | `256u32` (new — predicate eval stack depth bound) |
| `COP_TRUE` | u8 | `0x01u8` |
| `COP_FALSE` | u8 | `0x02u8` |
| `COP_AND` | u8 | `0x03u8` |
| `COP_OR` | u8 | `0x04u8` |
| `COP_NOT` | u8 | `0x05u8` |
| `COP_PRODUCER_EQ` | u8 | `0x10u8` |
| `COP_OP_EQ` | u8 | `0x11u8` |
| `COP_REVTAG_EQ` | u8 | `0x12u8` |
| `COP_PHASE_GE` | u8 | `0x13u8` |
| `COP_PILLAR_EQ` | u8 | `0x14u8` |
| `COP_HAS_ANTE` | u8 | `0x15u8` |

## Data Structures
All module-scope (Trap 7 forbids function-local `var` arrays). Sizes mirror `CONS_MAX_CLAUSES = 1024`, the gospel-declared clause ceiling for the V1+ constitution.

**Slot tables (bound = 1024 clauses; W8 — the constitution is a small, curated, append-mostly law set; 1024 is the gospel ceiling):**
| name | type | size | purpose / bound justification |
|---|---|---|---|
| `CONS_LIVE` | `[u8; 1024]` | 1024 | liveness flag per slot |
| `CONS_ID` | `[u8; 32768]` | 1024×32 | clause id (Keccak256 of textual) per slot |
| `CONS_SUPERSEDES` | `[u8; 32768]` | 1024×32 | id of the clause this one supersedes; all-zero if none |
| `CONS_TEXT_OFF` | `[u64; 1024]` | 1024 | offset into `CONS_TEXT_BUF` |
| `CONS_TEXT_LEN` | `[u64; 1024]` | 1024 | textual length |
| `CONS_LTL_OFF` | `[u64; 1024]` | 1024 | offset into `CONS_LTL_BUF` |
| `CONS_LTL_LEN` | `[u64; 1024]` | 1024 | LTL length |
| `CONS_PRED_OFF` | `[u64; 1024]` | 1024 | offset into `CONS_PRED_BUF` |
| `CONS_PRED_LEN` | `[u64; 1024]` | 1024 | predicate bytecode length |
| `CONS_EFFECTIVE` | `[u64; 1024]` | 1024 | effective epoch (algebraic time at ratify) |

**Append arenas (W6/W7 — module-scope, explicit `*_USED` lifecycle cursors reset by `cons_init`):**
| name | type | size | bound justification |
|---|---|---|---|
| `CONS_TEXT_BUF` | `[u8; 1048576]` | 1 MiB | `CONS_TEXT_AREA`; ~1 KiB avg statement × 1024 |
| `CONS_LTL_BUF` | `[u8; 1048576]` | 1 MiB | `CONS_LTL_AREA`; LTL encodings |
| `CONS_PRED_BUF` | `[u8; 524288]` | 512 KiB | `CONS_PRED_AREA`; predicate bytecode |
| `CONS_TEXT_USED` | `u64 = 0u64` | — | append cursor |
| `CONS_LTL_USED` | `u64 = 0u64` | — | append cursor |
| `CONS_PRED_USED` | `u64 = 0u64` | — | append cursor |

**Canonical ids + init flag:**
| name | type | size | purpose |
|---|---|---|---|
| `CONS_RATIFY_OPID` | `[u8; 32]` | 32 | `Keccak256("numera::constitution::ratify")`, filled in `cons_init` |
| `CONS_PRODUCER` | `[u8; 32]` | 32 | `Keccak256("numera::constitution")`, filled in `cons_init` |
| `CONS_INITED` | `u8 = 0u8` | — | one-time-init guard |

**Hoisted scratch (replaces the four illegal function-local `var` arrays — Trap 7 fix). Serialized use only; non-reentrant (noted in Trap Exposure):**
| name | type | size | replaces |
|---|---|---|---|
| `CONS_CID` | `[u8; 32]` | 32 | `var cid` in `cons_ratify` |
| `CONS_IC` | `[u8; 32]` | 32 | `var ic` (in-commit) in `cons_ratify` |
| `CONS_PL_BUF` | `[u8; 8192]` | 8192 | `var pl_buf` (payload scratch) in `cons_ratify`; bound = `CONS_PL_MAX`, ≥ 32+2+textual+4+ltl+4+pred+4+8+4 worst case fits because the three lengths are arena-bounded and the V1 clauses are small — **Phase 2 MUST add a guard `if total_payload_len > CONS_PL_MAX { return CONS_U64_SENT }` before serializing** (gap §G5) |
| `CONS_STACK` | `[u8; 256]` | 256 | `var stack_buf` in `cons_eval_predicate`; depth bound `CONS_STACK_MAX` |
| `CONS_ZERO_ID` | `[u8; 32]` | 32 | new — an all-zero id to pass as the `antecedents` arg when `n_ante == 0` (replaces passing the payload pointer as the antecedents pointer, §G6) |

**Aggregate request/view layouts** (passed by `*u8`; Phase 2 reads fields at fixed byte offsets — no struct type needed, matching house style of raw-pointer payloads):
- `cons_ratify_req`: `out_clause_id_ptr (u64 @0)`, `textual_ptr (u64 @8)`, `textual_len (u64 @16)`, `ltl_ptr (u64 @24)`, `ltl_len (u64 @32)`, `pred_ptr (u64 @40)`, `pred_len (u64 @48)` — 56 bytes.
- `cons_supersede_req`: `prior_id_ptr (u64 @0)` then the `cons_ratify_req` fields at @8..@63 — 64 bytes.
- `cons_op_view`: `op_producer (u8[32] @0)`, `op_id (u8[32] @32)`, `op_phase (u8 @64)`, `op_revtag (u8 @65)`, `op_pillar (u16 @66)` — 68 bytes.

## Dependencies (externs)
All providers are **already built** — no not-yet-built dependency; the wave scheduler may run this module immediately.

```iii
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
```

| extern | provider module NN | built? |
|---|---|---|
| `ident_from_bytes`, `ident_copy`, `ident_eq` | Module 01 `numera/identifier.iii` | ✅ built |
| `wh_publish` | `aether/witness_hook.iii` | ✅ built (signature verified identical to gospel) |
| `at_current` | Module 03 `numera/algebraic_time.iii` | ✅ built |

**DELETE these three gospel externs (gap §G1):**
```
extern ... fn keccak256_init()   ... from "keccak.iii"   // dead + wrong module
extern ... fn keccak256_update() ... from "keccak.iii"   // dead + wrong module
extern ... fn keccak256_final()  ... from "keccak.iii"   // dead + wrong module
```
They are **never called** in the body, and they name symbols that do **not** exist in `keccak.iii` (which exports the sponge primitives `keccak_absorb`/`keccak_squeeze`/`keccak_f1600`/…). The streaming `keccak256_*` API actually lives in `keccak256.iii`. Because the body computes every digest through `ident_from_bytes` (which wraps `keccak256_oneshot` — itself Keccak256, KAT-verified `Keccak256("abc")[0]=0x4e`), these externs are pure dead weight and would only introduce undefined-symbol link risk. Remove all three.

## Algorithm
Determinism (M2) holds throughout: every operation is integer/byte arithmetic over fixed-width values with no float, no RNG, no time-of-day, no observation/threshold (M3/M4 clean). Bit-identity (W5) holds because the only "time" used is `at_current()` (a strictly-monotonic algebraic counter advanced solely by the witness hook) and all serialization is explicit little-endian byte writes. No recursion (W15): `cons_supersede` calls `cons_ratify` — that is a finite call chain of depth 2, **not** recursion (neither function calls itself); all loops are sentinel/counter `while` loops (W14, no `break`).

**`cons_init`** — counter loop zeroes `CONS_LIVE[0..1024]`; computes `CONS_RATIFY_OPID = ident_from_bytes("numera::constitution::ratify", 28)` and `CONS_PRODUCER = ident_from_bytes("numera::constitution", 20)`; zeroes the three `*_USED` cursors; zeroes `CONS_ZERO_ID`; sets `CONS_INITED = 1`. Returns `CONS_OK`.

**`cons_find(clause_id)`** — single counter loop `i in 0..CONS_MAX_CLAUSES`; for each live slot, if not yet found, compare via `ident_eq(cons_id_ptr(i), clause_id)`; record first match in `found`. Returns `found` (or `CONS_SENT`). Deterministic linear scan; hand-rolled (M1), no early `break` (W14) — the `found == CONS_SENT` guard makes the loop side-effect-stable after the first hit. `cons_id_ptr(slot)` is a private helper returning `&CONS_ID[slot*32]`.

**`cons_alloc_slot`** (private) — counter loop returning the first slot with `CONS_LIVE[i] == 0`, else `CONS_SENT`. (Early `return i` from inside the loop is permitted — it is not a `break`; it terminates the function.)

**`cons_ratify(req)`** — deterministic sequence:
1. If `CONS_INITED == 0` call `cons_init()`.
2. Decode the aggregate fields (textual/ltl/pred ptr+len, out_clause_id).
3. Bounds-check each arena: `if (CONS_TEXT_USED + textual_len) > CONS_TEXT_AREA { return CONS_U64_SENT }` (and likewise LTL, PRED).
4. **New (§G5):** compute the worst-case payload length and `if pl_total > CONS_PL_MAX { return CONS_U64_SENT }`.
5. `ident_from_bytes(textual, textual_len, CONS_CID)` → candidate clause id.
6. Duplicate check: `if cons_find(CONS_CID) != CONS_SENT { ident_copy(CONS_CID, out_clause_id); return CONS_U64_SENT }`.
7. `slot = cons_alloc_slot()`; if `CONS_SENT` return sentinel.
8. `ident_copy(CONS_CID, cons_id_ptr(slot))`; zero the slot's `CONS_SUPERSEDES` row (counter loop, 32 bytes).
9. Append `textual` into `CONS_TEXT_BUF` at `CONS_TEXT_USED` (counter loop), set `CONS_TEXT_OFF/LEN[slot]`, advance cursor. Same for LTL and PRED arenas.
10. `CONS_EFFECTIVE[slot] = at_current()`; `CONS_LIVE[slot] = 1`.
11. `ident_from_bytes(textual, textual_len, CONS_IC)` → in-commit (= clause id; the schema's in/out commit).
12. **Serialize the Part VII `clause_payload`** into `CONS_PL_BUF` with an explicit little-endian byte cursor `off`: clause_id(32) ‖ textual_len(u16 LE) ‖ textual ‖ ltl_len(u32 LE) ‖ ltl ‖ pred_len(u32 LE) ‖ pred ‖ effective_epoch(u64 LE) ‖ dependency_count(u32 LE = 0). **(§G7: the gospel omits the `witness_rule_len(u32)` + `witness_rule` fields that Part VII specifies between `predicate` and `effective_epoch`. Phase 2 MUST insert `witness_rule_len(u32 LE = 0)` (empty rule, V1 form) at that position to match the schema, or the payload diverges from the declared layout and downstream parsers misread.)** All length prefixes via byte-masked shifts (`(v >> k) & 0xFFu64`), never multi-byte stores (Trap 5-safe).
13. `frag_idx = wh_publish(&CONS_PRODUCER, &CONS_RATIFY_OPID, CONS_IC, CONS_CID, 0u8, 0u8, 0u16, &CONS_ZERO_ID, 0u32, CONS_PL_BUF, pl_len, out_clause_id)` — note the `in_commit = CONS_IC`, `out_commit = CONS_CID (clause id)`, `antecedents = CONS_ZERO_ID` (was incorrectly the payload ptr, §G6).
14. `ident_copy(CONS_CID, out_clause_id)`; return `frag_idx`.

**`cons_supersede(req)`** — decode `prior_id`; `prior_slot = cons_find(prior_id)`; if `CONS_SENT` return `CONS_U64_SENT`. Build a `cons_ratify_req` view over the embedded fields and call `cons_ratify`. Then `new_slot = cons_find(out_clause_id)`; if found, copy `prior_id` (32 bytes, counter loop) into the new slot's `CONS_SUPERSEDES` row. Return the ratify result. (Depth-2 call chain, not recursion.)

**`cons_eval_predicate(slot, opv, ante_ids, n_ante)`** — stack-machine interpreter over the slot's bytecode:
1. Guards: `if slot >= CONS_MAX_CLAUSES { return 0u8 }` (unsigned u32 compare — **safe**, the SIGSEGV trap is signed only); `if CONS_LIVE[slot] == 0u8 { return 0u8 }`. **New (§G8): `if CONS_INITED == 0u8 { return 0u8 }`.**
2. `off = CONS_PRED_OFF[slot]`, `len = CONS_PRED_LEN[slot]`; `if len == 0u64 { return 1u8 }` (no predicate ⇒ admissible — the gospel's intended "open" default).
3. `buf = &CONS_PRED_BUF[off]`; layout = `u8 const_count` then `const_count × 32-byte` identifier constants, then the instruction stream. `ip = 1 + const_count*32`.
4. Decode `opv` aggregate into locals (op_producer ptr, op_id ptr, op_phase, op_pillar, op_revtag).
5. Sentinel loop `while ip < len` gated by a `halted` flag (W14). Per opcode (`if opc == COP_x` cascade — **no `select()`**, Trap-safe; the briefing forbids `select` for side-effecting dispatch):
   - `COP_TRUE/FALSE`: push 1/0.
   - `COP_AND/OR`: if `sp >= 2`, fold top two with `&`/`|`, `sp -= 1`.
   - `COP_NOT`: if `sp >= 1`, logical-negate top (via two `if` writes, no ordering).
   - `COP_PRODUCER_EQ ci` / `COP_OP_EQ ci`: read 1 operand byte (const-pool index), push `ident_eq(op_producer|op_id, &const_table[ci*32])`.
   - `COP_REVTAG_EQ v`: read 1 byte; push `(v == op_revtag)` via equality only (W11-style; these are u8, equality is correct and trap-safe).
   - `COP_PHASE_GE v`: read 1 byte; push `(op_phase >= v)` — **unsigned u8 ordering, safe** (the iiis SIGSEGV trap is signed-i64/i32 only, confirmed by `algebraic_time.iii` using u64 `<`/`>` freely).
   - `COP_PILLAR_EQ v_lo v_hi`: read 2 bytes; reassemble u16; push equality.
   - `COP_HAS_ANTE ci`: read 1 byte; inner counter loop over `n_ante` with a `hit` flag (no `break`); push `hit`.
   - **New (§G3): every push first checks `if sp < CONS_STACK_MAX` (else set `halted = 1`); every multi-byte operand read first checks `ip + k <= len` (else `halted = 1`).** This makes the interpreter total over arbitrary byte input (M5 No-Bricking, M15 algebraic-total).
6. After the loop: `if sp >= 1 { result = CONS_STACK[sp-1] }`; `if sp == 0 { result = 1u8 }`. Return `result`.

The interpreter is the M11/M12 surface: the predicate bytecode is the proof-term / checkable certificate that an operation is constitutionally admissible; evaluation is total and deterministic, so any OK verdict is byte-reproducible from `(predicate bytes, op view, antecedents)` — M10/M17 hold (no memoization here; verdicts are recomputed, never cached).

## KAT Vectors (>= 3)
A `cons_selftest() -> u64` (99 = pass) drives these; each asserts byte-for-byte.

1. **Ratify → find round-trip + clause-id KAT.** `cons_init()`; ratify a clause with `textual = "abc"` (3 bytes), empty ltl, empty pred. Expect: return value `!= CONS_U64_SENT` (a valid frag idx, first publish ⇒ `0u64`); `out_clause_id[0] == 0x4eu8` and `out_clause_id[31] == 0x45u8` (this IS `Keccak256("abc")`, the identifier-module KAT vector); and `cons_find(out_clause_id)` returns slot `0u32`. Re-ratifying the same `"abc"` returns `CONS_U64_SENT` (duplicate refused) and does **not** allocate a second slot.

2. **Predicate interpreter — boolean algebra.** Install a slot whose predicate bytecode = `[const_count=0]` then `[COP_TRUE, COP_FALSE, COP_OR]` ⇒ eval returns `1u8`; `[COP_TRUE, COP_FALSE, COP_AND]` ⇒ `0u8`; `[COP_FALSE, COP_NOT]` ⇒ `1u8`; empty predicate (`len==0`) ⇒ `1u8`. (Drives push/fold/negate and the open-default path.)

3. **Predicate interpreter — attribute matches.** const pool = one 32-byte id `P`. Bytecode `[COP_PRODUCER_EQ 0]` with op-view `op_producer = P` ⇒ `1u8`; with `op_producer != P` ⇒ `0u8`. `[COP_PHASE_GE 5]` with `op_phase = 7` ⇒ `1u8`, with `op_phase = 3` ⇒ `0u8`. `[COP_PILLAR_EQ 0x34 0x12]` with `op_pillar = 0x1234u16` ⇒ `1u8`. `[COP_HAS_ANTE 0]` with `ante_ids = [P]`, `n_ante = 1` ⇒ `1u8`; with `n_ante = 0` ⇒ `0u8`.

4. **Supersede chains.** Ratify clause A (`textual="alpha"`), then `cons_supersede(prior=A_id, textual="beta",…)` → clause B. Expect: B's slot's `CONS_SUPERSEDES` row equals `A_id` (32-byte compare); `cons_find(A_id)` still returns A's slot (supersession does not delete); `cons_find(B_id)` returns B's slot.

5. **No-bricking robustness (negative case — proves the guard FAILS on bad input, not just passes).** Install a predicate of `[COP_AND]` with empty stack (`sp==0`): eval must return `1u8` (sp==0 ⇒ open) without reading out of bounds. Install a truncated `[COP_PRODUCER_EQ]` with the operand byte missing (`ip` would read at `len`): eval must halt cleanly and return a defined value, **not** SIGSEGV. Install a 300-push bytecode (`COP_TRUE × 300`) against `CONS_STACK_MAX = 256`: eval must halt at the 256th push, **not** overflow `CONS_STACK`.

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| 1 — multi-line `fn` decl | yes (every fn) | **Every signature single-line.** The W2 aggregate refactor keeps each ≤4 params, all single-line. |
| 2 — module-`const` linker-global | yes (23 consts) | All prefixed `CONS_`/`COP_`; grep confirms no STDLIB collision. |
| 3 — signed-int ordering SIGSEGV | **no** | The only ordering compares are on **unsigned** u8/u32/u64 (`slot >= CONS_MAX_CLAUSES`, `op_phase >= v`, `sp >= 2`, `ip < len`, cursor `+len > AREA`). Confirmed safe — `algebraic_time.iii` documents the trap as signed-only and uses u64 `<`/`>` freely. No `i32`/`i64` ordering anywhere; the i32 consts are touched by equality/return only. |
| 4 — u32-in-u64-slot garbage | yes (ptr math) | All pointer arithmetic uses **u64** locals/expressions (`(slot as u64)*32u64`, `off+q`). Where a u32 (`const_count`, `ci`, `n_ante`, `sp`) feeds an address, cast to u64 **and mask** `& 0xFFFFFFFFu64` before the multiply (`(const_count as u64 & 0xFFFFFFFFu64)*32u64`, `(ci as u64 & 0xFFFFFFFFu64)*32u64`). **§G4: the gospel does `(ci as u64)*32u64` without the mask — Phase 2 must add the mask.** |
| 5 — u32 pointer store width | **no** | The module never stores through a `*u32`. Every multi-byte field is written byte-by-byte through `*u8` with `(v >> k) & 0xFFu64` extraction (the bigint house pattern). |
| 6 — nested `/* */` comments | yes (header) | Header block comment contains no nested `/* */`; opcode list uses `//` or plain lines. |
| 7 — local `var` arrays | **YES — gospel violates 4×** | `cid`, `ic`, `pl_buf`, `stack_buf` hoisted to module scope as `CONS_CID`/`CONS_IC`/`CONS_PL_BUF`/`CONS_STACK` (see Data Structures). **Consequence: `cons_ratify` and `cons_eval_predicate` are non-reentrant** — acceptable because constitutional ratification/evaluation is a serialized ceremony at R−1 (single-writer, like `witness_hook` which is itself serialized). Documented in the module header. |
| 8 — `} else {` one line | low | Body uses paired `if`/`if` for the negation case (no `else`); any `else` introduced in Phase 2 must be one-line. |
| 9 — em-dash in comment | yes (prose) | Use ASCII `--` in all comments; no U+2014. |
| 10 — `let mut` checkpoint flag | partial | The `found`/`hit`/`halted` flags drive loop conditions / guard side effects (the W14 pattern), not a checkpoint that the trap targets. Acceptable; keep the flag driving the `while`/guard, not a post-hoc `== next` check. |
| 11 — modulo-after-call | **no** | No `%` operator anywhere in the module (grep-confirmed). All indexing is `*`/`+`. |
| 12 — `@specialize *T` stride | **no** | No generics; every buffer is `*u8` with explicit byte offsets. |

## Gap / Fix List
The candidate body is PARTIAL. Each gap below is blocking unless marked.

- **§G1 (blocking, link) — three dead externs naming absent symbols.** `keccak256_init/update/final from "keccak.iii"` are never called and do not exist in `keccak.iii` (they live in `keccak256.iii`). **Fix:** delete all three extern lines.
- **§G2 (blocking, W2) — three over-arity public functions.** `cons_ratify`(7), `cons_supersede`(8), `cons_eval_predicate`(8) exceed the 4-param limit. **Fix:** the aggregate-by-pointer signatures in Public API (`cons_ratify_req`, `cons_supersede_req`, `cons_op_view`). Optionally keep flat shims for compatibility.
- **§G3 (blocking, M5/M15) — unbounded predicate stack + missing operand-length guards.** `sp` increments with no `< CONS_STACK_MAX` check (stack-buffer overflow on a long bytecode); operand reads (`buf[ip]`, `buf[ip+1]`) don't verify `ip+k <= len` (out-of-bounds read at the end of the stream). **Fix:** guard every push with `if sp < CONS_STACK_MAX` (else `halted = 1`); guard every operand read with `if ip + k <= len` (else `halted = 1`). KAT §5 proves these guards fail closed.
- **§G4 (blocking, Trap 4) — unmasked u32→u64 in pointer math.** `(ci as u64) * 32u64` and `(const_count as u64) * 32u64` lack the `& 0xFFFFFFFFu64` mask; a high-bit-garbage u32 slot yields a wild address. **Fix:** mask before every such multiply.
- **§G5 (blocking, M5) — payload scratch can overflow.** `CONS_PL_BUF` is 8192 bytes but `textual_len + ltl_len + pred_len` can be far larger (each arena is ≥512 KiB). The gospel writes into `pl_buf[off+…]` with no total-length check ⇒ overflow. **Fix:** before serializing, compute `pl_total = 32+2+textual_len+4+ltl_len+4+4+pred_len+8+4` (incl. the §G7 witness_rule field) and `if pl_total > CONS_PL_MAX { return CONS_U64_SENT }`. (Bound `CONS_PL_MAX` may be raised, but a guard is mandatory either way.)
- **§G6 (correctness) — `antecedents` arg is the payload pointer.** The gospel call passes `pl` (the payload buffer) as `wh_publish`'s `antecedents` with `n_ante = 0u32`. Harmless today (witness_hook skips antecedents when `n_ante == 0`), but semantically wrong and fragile. **Fix:** pass `&CONS_ZERO_ID` as `antecedents`.
- **§G7 (blocking, schema) — payload omits the `witness_rule` field.** Part VII's `clause_payload` places `u8[4] witness_rule_len` + `u8[witness_rule_len] witness_rule` **between** `predicate` and `effective_epoch`. The gospel serializer jumps straight from `pred` to `effective_epoch`, so the on-chain payload does not match the declared schema and any conformant parser misreads `effective_epoch`/`dependency_count`. **Fix:** insert `witness_rule_len (u32 LE = 0)` (empty rule, V1 form) after the predicate block; the public API can later accept a `witness_rule` ptr+len, but V1 ratify writes a zero-length rule.
- **§G8 (robustness) — `cons_eval_predicate` lacks an init guard.** If called before `cons_init`, `CONS_PRED_OFF/LEN[slot]` are zero and `CONS_LIVE[slot]==0` already returns `0u8`, so it is *currently* safe — but add `if CONS_INITED == 0u8 { return 0u8 }` for defense-in-depth and parity with `cons_ratify`.
- **§G9 (clarity, non-blocking) — magic literals.** `0xFFFFFFFFFFFFFFFFu64` appears 6×, `32u64` many times, `8192`/`256` once. **Fix:** the new consts `CONS_U64_SENT`, `CONS_ID_BYTES`, `CONS_PL_MAX`, `CONS_STACK_MAX` (already in Constant Namespace).

Mandate posture (what was verified clean): **M1** (only libc-free III deps: identifier/witness_hook/algebraic_time, all hand-rolled, after §G1 deletes the bogus externs); **M2/W5** deterministic byte arithmetic + algebraic time only; **M3/M4** no learning/heuristics — pure structural dispatch; **M6/M10** ratify emits a witness fragment whose payload is byte-reproducible (after §G7 fixes the schema); **M7** Ring R−1 respected; **M8** ratification is the capability surface (R−1 single-writer); **M11/M12** predicate bytecode is the checkable admissibility certificate; **M15** interpreter total after §G3; **M5** no-bricking after §G3/§G5. No M-level *ambition* was down-scaled — the bytecode ISA is implemented in full (all 11 opcodes), the full Part VII payload is serialized, and supersession/dependency tracking are present.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/constitution.iii
 *
 * III STDLIB -- numera::constitution
 *
 * Constitutional clauses, ratification, admissibility evaluation.
 * Clauses are ratified by publishing a CLAUSE_RATIFICATION_OPID witness
 * fragment whose payload follows the Part VII clause_payload schema.
 * The admissibility predicate is a stack-machine bytecode (11 opcodes)
 * interpreted by cons_eval_predicate against a candidate operation view.
 *
 * NON-REENTRANT: cons_ratify and cons_eval_predicate use module-scope
 * scratch (Trap 7 forbids local var arrays). Ratification/evaluation is
 * a serialized R-1 ceremony (single-writer), so this is safe.
 *
 * Predicate bytecode opcodes:
 *   COP_TRUE  COP_FALSE  COP_AND  COP_OR  COP_NOT
 *   COP_PRODUCER_EQ ci   COP_OP_EQ ci   COP_REVTAG_EQ v
 *   COP_PHASE_GE v       COP_PILLAR_EQ lo hi   COP_HAS_ANTE ci
 *
 * Pred buffer layout: u8 const_count, const_count*32-byte id constants,
 * then the instruction stream.
 *
 * Hexad: kind_essence.  Ring: R-1.  K: 1.00.
 * Discipline: W2 (aggregate args), W8, W13, W14, W15.
 */

module numera_constitution

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"

const CONS_OK          : i32 =  0i32
const CONS_E_FULL      : i32 = -1i32
const CONS_E_NOT_FOUND : i32 = -2i32
const CONS_SENT        : u32 = 0xFFFFFFFFu32
const CONS_U64_SENT    : u64 = 0xFFFFFFFFFFFFFFFFu64
const CONS_MAX_CLAUSES : u32 = 1024u32
const CONS_TEXT_AREA   : u64 = 1048576u64
const CONS_LTL_AREA    : u64 = 1048576u64
const CONS_PRED_AREA   : u64 = 524288u64
const CONS_ID_BYTES    : u64 = 32u64
const CONS_PL_MAX      : u64 = 8192u64
const CONS_STACK_MAX   : u32 = 256u32

const COP_TRUE        : u8 = 0x01u8
const COP_FALSE       : u8 = 0x02u8
const COP_AND         : u8 = 0x03u8
const COP_OR          : u8 = 0x04u8
const COP_NOT         : u8 = 0x05u8
const COP_PRODUCER_EQ : u8 = 0x10u8
const COP_OP_EQ       : u8 = 0x11u8
const COP_REVTAG_EQ   : u8 = 0x12u8
const COP_PHASE_GE    : u8 = 0x13u8
const COP_PILLAR_EQ   : u8 = 0x14u8
const COP_HAS_ANTE    : u8 = 0x15u8

var CONS_LIVE        : [u8;  1024]
var CONS_ID          : [u8;  32768]
var CONS_SUPERSEDES  : [u8;  32768]
var CONS_TEXT_OFF    : [u64; 1024]
var CONS_TEXT_LEN    : [u64; 1024]
var CONS_TEXT_BUF    : [u8;  1048576]
var CONS_TEXT_USED   : u64 = 0u64
var CONS_LTL_OFF     : [u64; 1024]
var CONS_LTL_LEN     : [u64; 1024]
var CONS_LTL_BUF     : [u8;  1048576]
var CONS_LTL_USED    : u64 = 0u64
var CONS_PRED_OFF    : [u64; 1024]
var CONS_PRED_LEN    : [u64; 1024]
var CONS_PRED_BUF    : [u8;  524288]
var CONS_PRED_USED   : u64 = 0u64
var CONS_EFFECTIVE   : [u64; 1024]

var CONS_RATIFY_OPID : [u8; 32]
var CONS_PRODUCER    : [u8; 32]
var CONS_ZERO_ID     : [u8; 32]
var CONS_INITED      : u8 = 0u8

/* Hoisted scratch (Trap 7 -- no local var arrays). Serialized use only. */
var CONS_CID    : [u8; 32]
var CONS_IC     : [u8; 32]
var CONS_PL_BUF : [u8; 8192]
var CONS_STACK  : [u8; 256]

fn cons_id_ptr(slot: u32) -> *u8 {
    // returns &CONS_ID[slot*32]; mask slot before the multiply (Trap 4)
    return (&CONS_ID[((slot as u64) & 0xFFFFFFFFu64) * 32u64]) as *u8
}

fn cons_init() -> i32 @export {
    // TODO: body per Algorithm cons_init -- zero CONS_LIVE, compute
    // CONS_RATIFY_OPID + CONS_PRODUCER, zero CONS_ZERO_ID + cursors, set CONS_INITED
}

fn cons_find(clause_id: *u8) -> u32 @export {
    // TODO: body per Algorithm cons_find -- linear scan, first-match flag, no break (W14)
}

fn cons_alloc_slot() -> u32 {
    // TODO: first slot with CONS_LIVE[i]==0, else CONS_SENT
}

fn cons_ratify(req: *u8) -> u64 @export {
    // TODO: body per Algorithm cons_ratify steps 1-14.
    // Decode cons_ratify_req aggregate; arena bounds; CONS_PL_MAX guard (G5);
    // clause id via ident_from_bytes -> CONS_CID; dup check; alloc slot;
    // append text/ltl/pred; CONS_EFFECTIVE = at_current(); serialize Part VII
    // payload INCLUDING witness_rule_len=0 (G7) into CONS_PL_BUF; wh_publish
    // with antecedents = &CONS_ZERO_ID (G6). Single-line signature (Trap 1).
}

fn cons_supersede(req: *u8) -> u64 @export {
    // TODO: body per Algorithm cons_supersede -- find prior; call cons_ratify
    // over embedded req; record prior_id in new slot's CONS_SUPERSEDES row.
    // Depth-2 call chain, NOT recursion (W15 ok).
}

fn cons_eval_predicate(slot: u32, opv: *u8, ante_ids: *u8, n_ante: u32) -> u8 @export {
    // TODO: body per Algorithm cons_eval_predicate.
    // Guards (slot, live, CONS_INITED G8); decode cons_op_view; sentinel loop
    // on ip<len with halted flag (W14); 11-opcode if-cascade (no select);
    // bound every push by CONS_STACK_MAX and every operand read by ip+k<=len (G3);
    // mask ci/const_count before *32 (Trap 4). Return CONS_STACK[sp-1] or 1u8.
}

/* Self-test.  99 = pass.  Drives KAT vectors 1-5. */
fn cons_selftest() -> u64 @export {
    // TODO: KAT 1 (ratify "abc" -> clause_id[0]=0x4e,[31]=0x45; find; dup refused)
    // KAT 2 (boolean algebra TRUE/FALSE/AND/OR/NOT + empty-open)
    // KAT 3 (PRODUCER_EQ/PHASE_GE/PILLAR_EQ/HAS_ANTE match + non-match)
    // KAT 4 (supersede records prior_id; prior still findable)
    // KAT 5 (negative: empty-stack AND -> 1u8; truncated operand -> no SIGSEGV;
    //        300 pushes halt at 256 -- guards fail closed)
}
```
