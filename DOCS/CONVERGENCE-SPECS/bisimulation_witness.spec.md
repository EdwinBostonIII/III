# 80 aether/bisimulation_witness.iii — Implementation Spec

## Verdict
STUB — the gospel candidate body compiles in shape but realizes **none** of its stated mission. The prose promises "the substrate-level bisimulation witness producer … composes `cg_bisimulate` with additional structural checks for cross branch and cross epoch bisimulations." The body does exactly one thing: `bw_construct_witness` null-guards three pointers and **forwards verbatim to `cg_bisimulate`**. There are zero additional structural checks, zero cross-branch / cross-epoch resolution, no capability gate (M8), and — most importantly — it produces **no witness of its own**: it returns whatever shallow `0x10` fragment `cg_bisimulate` already emits. As written it is a pure pass-through wrapper that adds nothing over Module 56, so W41's substrate-level claim ("no equivalence claim without a *bisimulation witness*") is not actually discharged at Layer 9 — the module is the documented "halfassed" stub. Every gap is closed below; the maximal intent (a composite, capability-gated, cross-branch/cross-epoch bisimulation witness whose payload carries both computation ids **and** the base proof-term reference per the Part VI `0x10` catalog) is realized, not down-scaled. Two of its three real dependencies (`cg_bisimulate`, `cg_resolve_fragment` from Module 56) are not-yet-built; one systemic-defect correction applies (the gospel routes emission through Module 56's `cg_bisimulate`, which itself externs the fictional `ws_emit_fragment` — Module 80 emits its own composite witness through the BUILT `wh_publish` instead, so it does not inherit that defect).

## Purpose
`aether_bisimulation_witness` is the **substrate-level bisimulation witness producer**: given two previously-witnessed computations (by fragment id), it constructs the formal equivalence proof object that W41 requires before any equivalence claim may be made, composing Module 56's shallow `cg_bisimulate` primitive with the **deeper structural checks** the primitive deliberately skips — that both fragments resolve in the chain-as-DAG, and the **cross-branch** (different `branch_id`) and **cross-epoch** (different algebraic-time position) context under which the equivalence holds. It emits one canonical `BISIMULATION_WITNESS` fragment (V3 payload kind `0x10`) whose inner payload carries the two computation ids and the proof-term reference (the base witness fid), so the equivalence is a checkable, chained, reproducible certificate (M6/M10/M11/M12/M18). It is the producer consumed by `cp_branch_merge` ceremonies (Module 57's `ba_verify_bisimulation` re-check) and by future V3 federated (cross-node) bisimulation. Hexad: **kind_witness**. Ring: **R0**. K-vector: **1.00**.

## Public API
All public functions return a status `i32` (W9 negative-error codes / W12: every public fn returns a status). No boolean-`u8` public fn in this module. Signatures are SINGLE-LINE (Trap 1) exactly as they must appear:

```
fn bw_init() -> i32 @export
fn bw_construct_witness(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8, cap_id: u64) -> i32 @export
fn bw_selftest() -> u64 @export
```

Two **internal** (non-`@export`) helpers keep the public fns under W13/W2:
```
fn bw_resolve_ctx(fid: *u8, slot: u64) -> i32
fn bw_emit_witness(out_witness_fid: *u8) -> i32
```
`bw_resolve_ctx` resolves one fid into the module-scope context slots (`slot` selects left=0 / right=1); returns `BW_OK` or `BW_E_FRAGMENT_ABSENT`. `bw_emit_witness` assembles the composite `0x10` payload from the recorded context and emits one fragment via `wh_publish`; returns `BW_OK` or `BW_E_EMIT`.

Return-status convention per fn:
- `bw_init` → `BW_OK` always (idempotent boot; derives the cached opid).
- `bw_construct_witness` → `BW_OK` (writes `*out_witness_fid` with the **composite** witness fid), or `BW_E_NOT_INITED`, `BW_E_NULL`, `BW_E_DENIED` (capability check failed, M8), `BW_E_FRAGMENT_ABSENT` (either fid not in the chain), `BW_E_NOT_BISIMILAR` (the shallow `cg_bisimulate` rejected — the field windows differ), `BW_E_EMIT` (witness publication failed: chain full / payload area full).
- `bw_selftest` → `99u64` on full pass, else the failing step number (house convention).

### API CHANGE vs gospel (flagged)
The gospel's `bw_construct_witness(left_fid, right_fid, out_witness_fid)` is **3 params with no capability argument**, violating **M8** (a privileged action — publishing a substrate attestation that two computations are equivalent — must require an explicit capability) and **W16** (witness fragments produced under a governed surface). **Fix:** add `cap_id: u64` as the 4th parameter (total 4 → W2-clean). The caller must hold `CAP_RIGHT_ATTEST (0x0800)`; `bw_construct_witness` checks it via `cap_verify_rights(cap_id, BW_REQ_RIGHTS)` and returns `BW_E_DENIED` on failure **before** any chain read or emission. This is the maximal, mandate-honoring surface; `cap_id` is `u64` (no pointer, no W2 budget pressure on the pointer fields).

## Constant Namespace
PREFIX = `BW_` . **Grep confirmed (2026-05-23):** `grep -rn "\bBW_" STDLIB/` and `grep -rn "\bbw_" STDLIB/` both return **no matches** — neither the `BW_` const prefix nor the `bw_` function prefix collides with any built symbol. (Module 57 `branch_anchor.iii` uses `BANCHOR_`/`ba_`; Module 56 uses `CG_`/`cg_`; the phase-17 orchestration refers to this module by the bare name `bw`, consistent with the `bw_*` exports.) The gospel body already uses `BW_`; preserved.

Module-level constants (every `const NAME : T = V`):
```
const BW_OK                  : i32 =  0i32
const BW_E_NULL              : i32 = -1i32
const BW_E_NOT_INITED        : i32 = -2i32
const BW_E_DENIED            : i32 = -3i32   // capability check failed (M8)
const BW_E_FRAGMENT_ABSENT   : i32 = -4i32   // cg_resolve_fragment miss
const BW_E_NOT_BISIMILAR     : i32 = -5i32   // cg_bisimulate rejected the pair
const BW_E_EMIT              : i32 = -6i32   // wh_publish returned the u64 sentinel

const BW_IDENT_BYTES         : u64 = 32u64
const BW_REQ_RIGHTS          : u64 = 0x0800u64                 // CAP_RIGHT_ATTEST (capability.iii)
const BW_U64_SENT            : u64 = 0xFFFFFFFFFFFFFFFFu64     // wh_publish failure sentinel
const BW_PAYLOAD_TAG         : u8  = 0xE3u8                    // V3 payload sentinel (Part VI)
const BW_PAYLOAD_KIND        : u8  = 0x10u8                    // BISIMULATION_WITNESS (Part VI catalog, line 530)
const BW_PAYLOAD_LEN         : u32 = 152u32                    // composite payload length (see Data Structures)
const BW_OPTAG_LEN           : u64 = 23u64                     // "bw.bisimulation.witness" minus NUL = 23 ASCII bytes
```
Notes: `BW_REQ_RIGHTS` is the bit value of `CAP_RIGHT_ATTEST` read from the BUILT `capability.iii` (bit 11 = `0x0800u64`). It is re-declared as a local prefixed const (not imported) because `.iii` has no cross-module const import and re-export of another module's const would collide at link (Trap 2); the value is pinned to the public spec bit assignment and noted as a contract-on-`capability.iii`. `BW_PAYLOAD_KIND = 0x10` matches Part VI exactly and matches the kind byte Module 56's `cg_bisimulate` writes — intentional: the substrate-level composite witness is the *same catalog kind*, distinguished by its richer payload (it carries the base proof-term reference and the cross-branch/epoch context, where the Module 56 shallow form leaves those zero).

## Data Structures
All buffers are module-scope (Trap 7: no function-local `var` arrays — the gospel body had none, and none are introduced). Identifier slots are `[u8; 32]` directly (these are small; the `[u64; B/8]` byte-capacity trick is only needed for the multi-MiB tables in `witness_hook`/`computation_graph`, not here). W8: every table is statically sized; the bound is justified.

| Name | Type | Bytes | Bound justification |
|------|------|-------|---------------------|
| `BW_INITED` | `u8` | 1 | boot-once flag |
| `BW_LEFT_FID` | `[u8; 32]` | 32 | param-spill-safe copy of `left_fid` before extern calls (Trap 11) + payload source |
| `BW_RIGHT_FID` | `[u8; 32]` | 32 | param-spill-safe copy of `right_fid` |
| `BW_BASE_WITNESS` | `[u8; 32]` | 32 | the proof-term reference: fid that `cg_bisimulate` produced |
| `BW_CTX_BRANCH` | `[u8; 64]` | 64 | two 32-byte branch ids: left @[0..32), right @[32..64) (from `cg_resolve_fragment`) |
| `BW_CTX_POS` | `[u64; 2]` | 16 | two positions (algebraic-time/epoch index): left @[0], right @[1] |
| `BW_PAYLOAD` | `[u8; 152]` | 152 | composite `0x10` witness payload (layout below) |
| `BW_ZERO_ID` | `[u8; 32]` | 32 | canonical all-zero id (producer / in_commit / out_commit / antecedent slots for `wh_publish`) |
| `BW_SELF_PRODUCER` | `[u8; 32]` | 32 | this module's canonical producer id = Keccak256("bw.bisimulation.witness") via `ident_from_bytes`, derived once in `bw_init` |
| `BW_BISIM_OPID` | `[u8; 32]` | 32 | the BISIMULATION_WITNESS operation id (same derivation; the op tag IS the module identity for this op) |
| `BW_OPTAG` | `[u8; 23]` | 23 | ASCII bytes "bw.bisimulation.witness" (no NUL) used to derive producer/opid |
| `BW_OUT_TMP` | `[u8; 32]` | 32 | out_frag_id sink for the `wh_publish` call (the composite witness fid) |
| `BW_T_*` (selftest) | `[u8; 32]` ×4 + `[u8;152]` | ~280 | KAT scratch (left/right/out ids + payload read-back) |

**Composite `BISIMULATION_WITNESS` payload layout (`BW_PAYLOAD`, 152 bytes).** This is the maximal realization of the Part VI line-530 spec ("the inner payload carries the two computation identifiers and the proof term reference"):
```
offset   0 : 0xE3                       (1 B)  V3 payload sentinel
offset   1 : 0x10                       (1 B)  BISIMULATION_WITNESS kind
offset   2 : reserved 0x00,0x00,0x00,0x00,0x00,0x00 (6 B)  pad to 8-byte alignment
offset   8 : left_fid                   (32 B) computation id A
offset  40 : right_fid                  (32 B) computation id B
offset  72 : base_witness_fid           (32 B) proof-term reference (the cg_bisimulate output)
offset 104 : left_branch_id             (32 B) cross-branch context A (0 = canonical line)
offset 136 : right_branch_id            (32 B) cross-branch context B
                                        --> NOTE: positions are NOT in the hashed payload (see below)
```
Total hashed payload = **152 bytes** = `BW_PAYLOAD_LEN`. Cross-**epoch** context (the two positions in `BW_CTX_POS`) is deliberately **excluded from the payload bytes** and used only as a structural *check input* (see Algorithm): including a raw position in the witness would make the witness fid depend on wall-position rather than on the computations' content, breaking M10 reproducibility for a re-derivation that lands the same pair at a different chain position. The branch ids ARE content (they identify *which* computations), so they are hashed; the positions are transient chain bookkeeping, so they gate the check but do not enter the certificate. This is the load-bearing M2/M10/W5 design decision and is called out in the Gap list.

Reentrancy note (Trap 7): the module-scope scratch makes `bw_construct_witness` **non-reentrant** — acceptable, because R0 chain mutation is serialized through the single-threaded substrate gate (identical posture to `witness_hook.iii`'s `WH_*` scratch, `computation_graph`'s `CG_*` scratch, and `branch_anchor`'s `BANCHOR_*` scratch). Flag for Phase 2: do not call re-entrantly.

## Dependencies (externs)
Each is a single-line `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`. Status noted; **two providers are NOT-YET-BUILT** (both entry points are Module 56) and gate this module.

| Extern (corrected, real signature) | From | NN | Built? |
|---|---|---|---|
| `fn ident_zero(out: *u8) -> i32` | identifier.iii | 01 | **BUILT** (verified in-tree) |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_is_zero(a: *u8) -> u8` | identifier.iii | 01 | **BUILT** (verified) |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | capability.iii | (aether, BUILT) | **BUILT** (verified — real M8 check; `cap_verify` does NOT exist) |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | witness_hook.iii | 07 | **BUILT** (verified — real emit primitive; `ws_emit_fragment` is fiction) |
| `fn cg_bisimulate(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8) -> i32` | computation_graph.iii | 56 | **NOT-YET-BUILT** (spec done; blocked on witness_spine + constitution) |
| `fn cg_resolve_fragment(fid: *u8, out_branch_id: *u8, out_position: *u64) -> i32` | computation_graph.iii | 56 | **NOT-YET-BUILT** (spec done) |

**Externs the gospel did NOT declare but the maximal realization requires:** `cg_resolve_fragment` (for the cross-branch/cross-epoch checks the prose demands), `cap_verify_rights` (M8 gate), `wh_publish` + the `ident_*` family (to emit the module's own composite witness rather than re-export Module 56's shallow one).

**Externs to NOT declare (systemic-defect avoidance):** the gospel's single extern `cg_bisimulate from "computation_graph.iii"` is **correct in signature and provider** (verified against Module 56's designed API). It is retained. However, Module 56's *body* emits its `0x10` fragment through the fictional `ws_emit_fragment` (a known systemic defect, flagged for the Module 56 agent); Module 80 does **not** inherit that defect because it does not rely on `cg_bisimulate`'s emission as its product — it treats the `cg_bisimulate` output fid as the *base proof-term reference* and emits its **own** composite witness through the BUILT `wh_publish`. (Should Module 56's `cg_bisimulate` fail to emit until witness_spine lands, Module 80's structural check + own emission still produces a valid Layer-9 witness; the base-reference field then carries whatever fid `cg_bisimulate` wrote, gated by the `CG_OK` return — see Algorithm and Gap §G6.)

**Not-yet-built dependency count: 2** (`cg_bisimulate` + `cg_resolve_fragment`, both Module 56). Wave-scheduler ordering: Modules 01/07 + capability.iii are BUILT; Module 56 (`computation_graph.iii`) must build first (itself blocked on Module 54 `witness_spine.iii` + `constitution.iii`); then this module. Downstream: Module 57 `branch_anchor.iii` consumes `cg_bisimulate` directly (not `bw_*`), but the phase-17 orchestration and future federation consume `bw_construct_witness`.

## Algorithm
NIH (M1): no third-party anything — all hashing flows through the in-substrate `ident_*`/keccak path; all comparison is exact. No ML/heuristics (M3/M4): every decision is an exact capability bit-mask check, an exact `cg_bisimulate` field-window equality (delegated), or an exact fragment-presence check — no counting, no thresholds, no observation. Determinism (M2)/bit-identity (W5): the composite witness fid is a pure Keccak256 (inside `wh_publish`) over the producer/opid/commit/payload bytes, all of which are functions only of the two input fids and the base witness fid — recomputable byte-identically from the recorded inputs (M10); positions are excluded from the hashed bytes precisely so a re-derivation of the same computation pair at a different chain position yields the *same* witness (see Data Structures). No recursion (W15): the only cross-fn calls are `bw_construct_witness → bw_resolve_ctx` (×2) and `→ bw_emit_witness` (depth-2 call chain, not recursion); no self-call.

**`bw_init`** — idempotent boot. `if BW_INITED == 1u8 { return BW_OK }`. `ident_zero((&BW_ZERO_ID as u64) as *u8)`. Populate `BW_OPTAG` with the 23 ASCII bytes of "bw.bisimulation.witness" (byte-by-byte literal assignment, module scope). Derive the cached producer and op ids once: `ident_from_bytes((&BW_OPTAG as u64) as *u8, BW_OPTAG_LEN, (&BW_SELF_PRODUCER as u64) as *u8)` and likewise into `BW_BISIM_OPID` (the producer and opid are both Keccak256 of the same module-identity tag — the module IS the producer and the op IS its sole operation; this is the M11/M12/M18 fix for Module 56's "computed externally / a sealed-call wrapper inserts these" placeholder hole). Set `BW_INITED = 1u8`; return `BW_OK`.

**`bw_resolve_ctx(fid, slot)`** (internal) — resolve one fragment's chain context. Compute the destination branch-id pointer `bp = ((&BW_CTX_BRANCH as u64) + slot * 32u64) as *u8` and position pointer `pp = ((&BW_CTX_POS as u64) + slot * 8u64) as *u64`. Call `let r : i32 = cg_resolve_fragment(fid, bp, pp)`; `if r != 0i32 { return BW_E_FRAGMENT_ABSENT }` (compared by `!=` only — Trap 3/W11). Return `BW_OK`. (This is the cross-branch/cross-epoch *resolution* the gospel omitted entirely: it confirms each fragment actually exists in the DAG and records its branch id + position. `slot` is always 0 or 1, clean in its u64 slot — Trap 4 safe; pointer math is `u64` base + `u64` offset.)

**`bw_emit_witness(out_witness_fid)`** (internal) — assemble + publish the composite witness.
1. Build `BW_PAYLOAD` (152 B, layout in Data Structures): `BW_PAYLOAD[0]=BW_PAYLOAD_TAG (0xE3)`, `BW_PAYLOAD[1]=BW_PAYLOAD_KIND (0x10)`, bytes 2..8 = 0. Counter loop `k in 0..32` (W14, counter-bounded): `BW_PAYLOAD[8+k]=BW_LEFT_FID[k]`, `BW_PAYLOAD[40+k]=BW_RIGHT_FID[k]`, `BW_PAYLOAD[72+k]=BW_BASE_WITNESS[k]`, `BW_PAYLOAD[104+k]=BW_CTX_BRANCH[k]` (left branch), `BW_PAYLOAD[136+k]=BW_CTX_BRANCH[32+k]` (right branch).
2. Publish: `let idx : u64 = wh_publish((&BW_SELF_PRODUCER as u64) as *u8, (&BW_BISIM_OPID as u64) as *u8, (&BW_ZERO_ID as u64) as *u8, (&BW_ZERO_ID as u64) as *u8, 0u8 /*revtag: irreversible attestation*/, 0u8 /*phase*/, 0u16 /*pillar: canonical*/, (&BW_ZERO_ID as u64) as *u8, 0u32 /*n_ante*/, (&BW_PAYLOAD as u64) as *u8, BW_PAYLOAD_LEN, out_witness_fid)`.
3. `if idx == BW_U64_SENT { return BW_E_EMIT }` (compared by `==` only — Trap 3/W11). Return `BW_OK`. The published fragment IS the substrate-level bisimulation witness; it chains by hash (M6), advances algebraic time monotonically inside `wh_publish` (W16/W17 — Module 80 never touches the clock directly), and is recomputable from its recorded bytes (M10). It is canonical (`pillar=0`, `n_ante=0`): a bisimulation witness is a statement about two existing computations, not a branch fragment.

**`bw_construct_witness(left_fid, right_fid, out_witness_fid, cap_id)`** — the W41 substrate-level primitive. Steps, in order:
1. `if BW_INITED == 0u8 { return BW_E_NOT_INITED }` (boot gate fails closed).
2. Null-guard each pointer: `if (left_fid as u64) == 0u64 { return BW_E_NULL }`; same for `right_fid`, `out_witness_fid`.
3. **Capability gate (M8):** `if cap_verify_rights(cap_id, BW_REQ_RIGHTS) == 0u8 { return BW_E_DENIED }`. Emitting a substrate attestation requires `CAP_RIGHT_ATTEST`; refusal is total and happens before any chain read or write (reversibility-by-refusal, M5/M9).
4. **Param-spill hardening (Trap 11):** `ident_copy(left_fid, (&BW_LEFT_FID as u64) as *u8)`; `ident_copy(right_fid, (&BW_RIGHT_FID as u64) as *u8)`. Both incoming ids are single-use-then-passed-to-extern, the exact param-spill pattern; copying to a named module buffer first guarantees no extern reads an unspilled slot. All subsequent reads use `BW_LEFT_FID`/`BW_RIGHT_FID`.
5. **Cross-branch / cross-epoch resolution (the gospel's missing structural checks):** `let rl = bw_resolve_ctx((&BW_LEFT_FID as u64) as *u8, 0u64)`; `if rl != 0i32 { return BW_E_FRAGMENT_ABSENT }`. `let rr = bw_resolve_ctx((&BW_RIGHT_FID as u64) as *u8, 1u64)`; `if rr != 0i32 { return BW_E_FRAGMENT_ABSENT }`. After this, `BW_CTX_BRANCH[0..32)`/`[32..64)` hold the two branch ids and `BW_CTX_POS[0]`/`[1]` the two positions. (The "cross branch" and "cross epoch" qualifiers in the prose mean exactly this: the two computations may live on *different branches* and at *different epochs/positions*; the producer records both contexts in the witness so a verifier knows which two points it certifies. No equality on branch/position is imposed — two computations on different branches at different epochs CAN be bisimilar; that is the whole point of W42 merge.)
6. **Shallow bisimulation (delegated base proof term):** `let b = cg_bisimulate((&BW_LEFT_FID as u64) as *u8, (&BW_RIGHT_FID as u64) as *u8, (&BW_BASE_WITNESS as u64) as *u8)`; `if b != 0i32 { return BW_E_NOT_BISIMILAR }`. This runs Module 56's exact-byte equality over the `(op_id, in_commit, out_commit)` window `[64,160)` and writes the base witness fid into `BW_BASE_WITNESS`. Module 80 takes that fid as the **proof-term reference** embedded in its composite witness (M11/M18 — the witness travels with its proof term).
7. **Emit the composite witness:** `return bw_emit_witness(out_witness_fid)`. On success `*out_witness_fid` holds the Layer-9 composite witness fid (distinct from `BW_BASE_WITNESS`); on emission failure returns `BW_E_EMIT`.

*Maximal-intent note (why this is not a wrapper):* the gospel returned Module 56's shallow fid directly. The realized form (a) gates on capability, (b) proves both fragments resolve in the DAG, (c) records cross-branch + cross-epoch context, and (d) emits a *richer* witness whose payload carries both computation ids AND the base proof-term reference per the Part VI `0x10` catalog (line 530) — so the substrate-level claim is a self-contained, checkable certificate (M12) rather than an alias of the primitive. The "V3 federated bisimulation in future federation work" (gospel prose) extends this same payload format with cross-node fields without a breaking change, because the branch-context fields are already present.

**`bw_selftest`** — see KAT Vectors; returns `99u64` on full pass, else the failing step number.

## KAT Vectors (>= 3)
A `bw_selftest() -> u64 @export` (99 = pass) checks these byte-for-byte; they become the Phase-2 acceptance gate. The bisimulation/resolve steps require the not-yet-built Module 56, so KATs 2–4 run against a booted substrate where `cg_init` has run, two fragments have been published via `wh_publish`, and a capability with `CAP_RIGHT_ATTEST` exists (e.g. `cap_env_init()` → `CAP_ENV_ROOT`, which carries all rights). Pure-local steps (KAT 1, KAT 5) run unconditionally. The orchestration's own acceptance check (Apotheosis Phase 17, gospel line 22202) is KAT 2.

1. **init + opid derivation (unconditional, M11/M12 hole closed).** After `bw_init()`: `BW_INITED == 1u8`; `ident_is_zero((&BW_SELF_PRODUCER as u64) as *u8) == 0u8` and `ident_is_zero((&BW_BISIM_OPID as u64) as *u8) == 0u8` (producer and opid are the non-zero Keccak256 of the tag — proves they are NOT the gospel's zero placeholders); and `ident_eq(&BW_SELF_PRODUCER, &BW_BISIM_OPID) == 1u8` is **expected** only if both derive from the identical tag (they do here) — assert equal to pin the derivation. A second `bw_init()` is idempotent (still `BW_OK`, ids unchanged).

2. **identical computations → witness emitted (the orchestration acceptance test, M2/M10).** Publish two fragments whose `(op_id, in_commit, out_commit)` triples are byte-identical (deterministic execution produces such pairs). With a cap holding `ATTEST`: `bw_construct_witness(L, R, &out, cap)` ⇒ `BW_OK`, `ident_is_zero(&out) == 0u8` (a real `0x10` fragment id was written), and `wh_next_idx()` increased by exactly 1 (one composite witness published). Re-running the **same** pair (same fids, same content) yields a **byte-identical** `out` fid (M2/M10 — positions excluded from the payload guarantee this even if the second call lands at a later chain index). Inspect the published payload (`wh_get_payload`): byte 0 == `0xE3`, byte 1 == `0x10`, bytes [8..40) == L, bytes [40..72) == R, bytes [72..104) == the `cg_bisimulate` base witness fid (non-zero).

3. **non-bisimilar pair → refusal, no witness (prove the negative, W41).** Publish two fragments whose `output_commit` differ in one byte. `bw_construct_witness(L, R2, &out, cap)` ⇒ **`BW_E_NOT_BISIMILAR (-5i32)`** (NOT `BW_OK`), and `wh_next_idx()` is **unchanged** (no fragment emitted — the producer never claims equivalence it cannot prove). Proves the shallow gate FAILS closed and that Module 80 does not emit a witness on a failed bisimulation.

4. **capability refusal (prove the negative, M8).** With a capability `cap_noattest` that does NOT hold `CAP_RIGHT_ATTEST` (e.g. `cap_attenuate(CAP_ENV_ROOT, 0x0002u64 /*fs_read only*/, 0u64)`): `bw_construct_witness(L, R, &out, cap_noattest)` ⇒ **`BW_E_DENIED (-3i32)`**, and `wh_next_idx()` is **unchanged** (the gate fires before any read/emit). Also `bw_construct_witness(L, R, &out, 0u64 /*CAP_INVALID*/)` ⇒ `BW_E_DENIED`. Proves the M8 gate FAILS closed (the exact assertion the gospel body, having no gate at all, would FAIL).

5. **fragment-absent + null + uninit guards (prove the negatives, W12).** Before `bw_init()` (fresh `BW_INITED==0`): `bw_construct_witness(L, R, &out, cap)` ⇒ `BW_E_NOT_INITED (-2i32)`. After init: `bw_construct_witness(0 as *u8, R, &out, cap)` ⇒ `BW_E_NULL (-1i32)`. With a fabricated fid never published to the chain: `bw_construct_witness(bogus, R, &out, cap)` ⇒ `BW_E_FRAGMENT_ABSENT (-4i32)` (proves `bw_resolve_ctx` rejects an unresolvable fragment, not silently proceeds). Each negative leaves `wh_next_idx()` unchanged.

## Trap Exposure
| # | Trap | Touched? | Avoidance in this spec |
|---|------|----------|------------------------|
| 1 | Multi-line `fn` | yes (every fn + the 12-arg `wh_publish` extern) | every signature in Public API, Skeleton, and the `wh_publish` extern is a single physical line, no wrapping. |
| 2 | Module-`const` linker-global | yes (15 consts) | all prefixed `BW_`; grep-confirmed no STDLIB collision (`BW_`/`bw_` both clean). `BW_REQ_RIGHTS` re-declares `CAP_RIGHT_ATTEST`'s value rather than importing it (no cross-module const import; importing would link-collide). |
| 3 | Signed-ordering SIGSEGV | yes (every status compare) | **every** comparison is `==`/`!=` against `0i32` / a named `i32` const / `BW_U64_SENT`; never `<`/`<=`/`>=`/`>` on any signed value. Loop counters are `u64` (unsigned ordering is safe). |
| 4 | u32-in-u64-slot garbage | minimal | the only indices feeding pointer math are the `slot` arg (0/1) and the `k` loop counter (0..32), both `u64` throughout; offsets are `slot*32u64`/`slot*8u64`/`8+k`. No `u32`→`u64` widen of a u32 local feeds pointer arithmetic. `cap_verify_rights` returns `u8` (compared, not used in math). |
| 5 | u32 pointer store width | no | no `*u32` stores; every payload/id write is a byte (`*u8`) store via array index, and the position write is owned by `cg_resolve_fragment` (a `*u64` it writes, not Module 80). |
| 6 | Nested `/* */` | n/a | header + inline use single-level `/* */` and `//`; no nesting. |
| 7 | Local `var` arrays | **none introduced** | the gospel body had no local arrays; the realized form puts **all** scratch (`BW_LEFT_FID`, `BW_RIGHT_FID`, `BW_BASE_WITNESS`, `BW_CTX_*`, `BW_PAYLOAD`, `BW_ZERO_ID`, `BW_SELF_PRODUCER`, `BW_BISIM_OPID`, `BW_OPTAG`, `BW_OUT_TMP`) at module scope. Non-reentrancy noted. |
| 8 | `} else {` one line | n/a | the design has no `else` (guard-clause early-returns + counter loops). Any `else` Phase 2 adds must be one-line. |
| 9 | Em-dash in comment | yes (prose comments) | all comments use ASCII `--`, never U+2014. |
| 10 | `let mut x=0u32` flag | no | no checkpoint-flag pattern; `bw_init` is idempotent via early-return; the design uses no mutated `u32` flags at all. |
| 11 | `%` after call | no modulo used | the design has NO `%`; all addressing is `*` (index×stride). Param-spill mitigated by copying `left_fid`/`right_fid` into `BW_LEFT_FID`/`BW_RIGHT_FID` (assignment to a named location) before any extern call (step 4). |
| 12 | `@specialize *T` stride | no | module is not generic; fixed 32-byte id stride, explicit byte loops. |
| — | **W3/W1 `&STATIC[expr]` element-address** (broader-than-catalog, the pervasive defect in Modules 56/57 gospel bodies) | latent (any element-address) | the gospel Module 80 body used only whole-array passes and is clean, but the realized form needs element addresses (`BW_CTX_BRANCH+slot*32`, `BW_PAYLOAD+8+k` is an index store not an address-of). **Avoidance:** all *addresses* passed to externs use the proven idiom `((&ARR as u64) + off) as *u8` / `(&ARR as u64) as *u8` (as in `witness_hook.iii`); never `&ARR[expr]`. Byte *stores* use the natural `BW_PAYLOAD[8+k] = ...` index form (a store, not an address-of — safe). |

## Gap / Fix List
The candidate body is a STUB. Every gap with its fix:

- **§G1 (mission, the core defect) — no structural checks; pure pass-through.** The gospel `bw_construct_witness` null-guards and `return cg_bisimulate(left_fid, right_fid, out_witness_fid)`. It performs **none** of the promised "additional structural checks for cross branch and cross epoch bisimulations," and it produces no witness of its own — it returns Module 56's shallow `0x10` fragment, so Layer 9 adds nothing. **Fix:** the 7-step `bw_construct_witness` above: capability gate → param-spill copy → `bw_resolve_ctx` ×2 (cross-branch/cross-epoch resolution) → `cg_bisimulate` (base proof term) → `bw_emit_witness` (composite Layer-9 witness). The module now discharges W41 at the substrate level with its own checkable, chained certificate.

- **§G2 (M8, blocking) — no capability gate.** Publishing a substrate attestation that two computations are equivalent is a privileged action; the gospel gates it on nothing. **Fix:** add `cap_id: u64` (4th param, W2-clean) + `cap_verify_rights(cap_id, BW_REQ_RIGHTS)` against `CAP_RIGHT_ATTEST (0x0800)` from the BUILT `capability.iii`; `BW_E_DENIED` on failure, before any chain access. (`cap_verify` does not exist — the real symbol is `cap_verify_rights(id, required) -> u8`; systemic defect #5 corrected.)

- **§G3 (M11/M12/M18, blocking) — no proof-term reference / no self-witness.** A substrate-level equivalence claim must be a *checkable certificate* (M12) carrying a *proof term* (M11/M18). The gospel emits nothing of its own. **Fix:** `bw_emit_witness` builds the Part VI `0x10` payload (line 530: "two computation identifiers and the proof term reference") = `0xE3‖0x10‖pad‖left_fid‖right_fid‖base_witness_fid‖left_branch‖right_branch` (152 B) and publishes it via `wh_publish` with a derived non-zero producer/opid. The `cg_bisimulate` output fid is embedded as the proof-term reference.

- **§G4 (M11/M12 hole inherited from Module 56) — zero producer/opid placeholder.** Module 56's `cg_bisimulate` zeroes producer/op with the comment "computed externally / a sealed-call wrapper inserts these" — a witness with a zero producer and zero op is not a theorem carrier. Module 80 must NOT replicate this. **Fix:** `bw_init` derives `BW_SELF_PRODUCER = BW_BISIM_OPID = Keccak256("bw.bisimulation.witness")` once via `ident_from_bytes`; `bw_emit_witness` uses them. KAT 1 asserts both are non-zero.

- **§G5 (systemic defect #2, latent inheritance) — emission via fictional `ws_emit_fragment`.** Module 56's body (which `cg_bisimulate` is part of) routes its `0x10` emission through `ws_emit_fragment from "witness_spine.iii"`, which does not exist (the real emit primitive is `wh_publish`). **Fix in Module 80:** Module 80 does **not** use `cg_bisimulate`'s emission as its product; it emits its own composite witness through the BUILT `wh_publish`. (The defect itself is in Module 56 and is flagged for that agent; Module 80 is insulated.)

- **§G6 (cross-module integration risk, flagged not papered) — `cg_bisimulate` may not yet emit a usable base fid.** Because Module 56's emission is broken until `witness_spine` lands, `cg_bisimulate`'s `out_witness_fid` may be zero / unpopulated in early integration. **Fix / Phase-2 decision:** Module 80 treats `cg_bisimulate`'s **return code** (`CG_OK`) as the bisimulation verdict (that is reliable — it is the field-window equality, computed before the broken emit) and embeds whatever fid it wrote as the base reference; the *composite* witness is still validly emitted by `wh_publish`. If `BW_BASE_WITNESS` comes back zero (Module 56 emit not yet functional), the composite witness still carries the two computation ids and a zero proof-term reference, which downstream re-verification (Module 57 `ba_verify_bisimulation`) tolerates because it re-runs `cg_bisimulate` itself. Flagged explicitly as the one residual integration coupling to confirm once Module 56 builds.

- **§G7 (M2/M10/W5, design decision) — positions must NOT enter the hashed payload.** A naive "record cross-epoch context" would hash the two positions into the witness, making the witness fid depend on chain placement and breaking reproducibility for a re-derivation of the same pair at a different position. **Fix:** positions (`BW_CTX_POS`) gate the structural check (both fragments must resolve, yielding a position) but are excluded from `BW_PAYLOAD`; only the branch ids (which are content identifying *which* computations) are hashed. Documented in Data Structures; KAT 2 proves the re-derivation yields a byte-identical fid.

- **§G8 (W15) — recursion check.** No recursion: `bw_construct_witness` calls `bw_resolve_ctx` (×2) and `bw_emit_witness` (depth-2 chain), none of which self-call. Clean.

- **Mandate sweep (verified):** M1 (NIH — only identifier/keccak/cap/hook/cg, all in-substrate) ✓; M2/M5/M10 (determinism, refusal-not-bricking, witness reproducibility) ✓ via the algebraic-clock-inside-`wh_publish` + position-exclusion; M3/M4 (no ML/heuristics) ✓ — exact bit-mask cap check + delegated exact field equality, no counting/observing/thresholds; M6 (witness continuity) ✓ — the composite witness chains by hash; M8 (capability mediation) ✓ via §G2; M9/W16/W17 (reversibility default, governed witness, monotonic time) ✓ — the witness is an irreversible attestation (`revtag=0`) emitted under the cap gate; algebraic time advances only inside `wh_publish`, never reset here; M11/M12/M18 (Curry-Howard / verifiability / theorem carrier) ✓ via §G3/§G4. W2 (4 params max — `bw_construct_witness` is exactly 4) ✓; W13 (≤20 locals — the two internal helpers keep each fn small) ✓; W9/W11/W12 (negative-i32 errors, equality-only compares, status returns) ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/bisimulation_witness.iii -- Layer 9, Module 80.
 * Substrate-level bisimulation witness producer.  Composes Module 56's
 * shallow cg_bisimulate (op_id/in_commit/out_commit field-window equality)
 * with the deeper structural checks the primitive skips: that both
 * fragments resolve in the chain-as-DAG, and the cross-branch / cross-epoch
 * context under which the equivalence holds.  Emits one canonical
 * BISIMULATION_WITNESS fragment (V3 payload kind 0x10, Part VI) whose payload
 * carries the two computation ids and the base proof-term reference.  W41:
 * no equivalence claim without a bisimulation witness.
 * Hexad: kind_witness.  Ring: R0.  K: 1.00.
 * NIH: identifier.iii (built) + capability.iii (built) + witness_hook.iii
 *      (built) + computation_graph.iii (Module 56, pending).
 * Idioms: element-address via ((&ARR as u64)+off) as *u8 (W3 parser-bug
 *   workaround); all scratch module-scope (no local var arrays); ASCII --
 *   in comments only; equality-only signed compares (W11). */
module aether_bisimulation_witness

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_is_zero(a: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cg_bisimulate(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8) -> i32 from "computation_graph.iii"
extern @abi(c-msvc-x64) fn cg_resolve_fragment(fid: *u8, out_branch_id: *u8, out_position: *u64) -> i32 from "computation_graph.iii"

const BW_OK                  : i32 =  0i32
const BW_E_NULL              : i32 = -1i32
const BW_E_NOT_INITED        : i32 = -2i32
const BW_E_DENIED            : i32 = -3i32
const BW_E_FRAGMENT_ABSENT   : i32 = -4i32
const BW_E_NOT_BISIMILAR     : i32 = -5i32
const BW_E_EMIT              : i32 = -6i32

const BW_IDENT_BYTES         : u64 = 32u64
const BW_REQ_RIGHTS          : u64 = 0x0800u64
const BW_U64_SENT            : u64 = 0xFFFFFFFFFFFFFFFFu64
const BW_PAYLOAD_TAG         : u8  = 0xE3u8
const BW_PAYLOAD_KIND        : u8  = 0x10u8
const BW_PAYLOAD_LEN         : u32 = 152u32
const BW_OPTAG_LEN           : u64 = 23u64

var BW_INITED        : u8  = 0u8
var BW_LEFT_FID      : [u8; 32]
var BW_RIGHT_FID     : [u8; 32]
var BW_BASE_WITNESS  : [u8; 32]
var BW_CTX_BRANCH    : [u8; 64]      /* left branch @[0..32), right @[32..64) */
var BW_CTX_POS       : [u64; 2]      /* left pos @[0], right pos @[1] (NOT hashed) */
var BW_PAYLOAD       : [u8; 152]
var BW_ZERO_ID       : [u8; 32]
var BW_SELF_PRODUCER : [u8; 32]      /* Keccak256("bw.bisimulation.witness") */
var BW_BISIM_OPID    : [u8; 32]      /* same derivation -- module identity */
var BW_OPTAG         : [u8; 23]      /* ASCII "bw.bisimulation.witness"      */
var BW_OUT_TMP       : [u8; 32]

/* selftest scratch */
var BW_T_L    : [u8; 32]
var BW_T_R    : [u8; 32]
var BW_T_OUT  : [u8; 32]
var BW_T_PAY  : [u8; 152]

fn bw_resolve_ctx(fid: *u8, slot: u64) -> i32 { /* TODO: body per Algorithm bw_resolve_ctx -- bp=((&BW_CTX_BRANCH as u64)+slot*32) as *u8; pp=((&BW_CTX_POS as u64)+slot*8) as *u64; cg_resolve_fragment; !=0i32 -> BW_E_FRAGMENT_ABSENT */ return BW_OK }
fn bw_emit_witness(out_witness_fid: *u8) -> i32 { /* TODO: body per Algorithm bw_emit_witness -- build 0xE3 0x10 (152B) payload [L|R|base|Lbr|Rbr]; wh_publish(BW_SELF_PRODUCER,BW_BISIM_OPID,ZERO,ZERO,0,0,0,ZERO,0,BW_PAYLOAD,BW_PAYLOAD_LEN,out); ==BW_U64_SENT -> BW_E_EMIT */ return BW_OK }
fn bw_init() -> i32 @export { /* TODO: body per Algorithm bw_init -- idempotent; ident_zero BW_ZERO_ID; fill BW_OPTAG "bw.bisimulation.witness"; ident_from_bytes(OPTAG,23)->SELF_PRODUCER & BISIM_OPID; set BW_INITED */ return BW_OK }
fn bw_construct_witness(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8, cap_id: u64) -> i32 @export { /* TODO: body per Algorithm bw_construct_witness -- not-inited guard; 3 null guards; cap_verify_rights(cap_id,BW_REQ_RIGHTS)==0 -> BW_E_DENIED; copy fids->BW_LEFT_FID/RIGHT_FID; bw_resolve_ctx(L,0)+bw_resolve_ctx(R,1); cg_bisimulate(L,R,BW_BASE_WITNESS)!=0 -> BW_E_NOT_BISIMILAR; return bw_emit_witness(out) */ return BW_OK }
fn bw_selftest() -> u64 @export { /* TODO: KAT 1 + 5 unconditional; KAT 2-4 gated on Module 56 + a booted cap; 99 = pass else failing step number */ return 99u64 }
```
