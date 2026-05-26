# 32 aether/phase_orchestrator.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally close (twelve-phase state machine, per-pillar in-flight counters, per-phase entry/exit clause tables, a three-step Quiescence close, an ordered entry path) and most of it is trap-clean, but it has **five load-bearing gaps**: (1) **it never runs the quine self-verification at the phase boundary**, which is the single defining duty of this module per W25 / the dispatch brief and the gospel's own orchestration prose (L22006, L22018) — the headline omission; (2) **four `var` arrays declared inside `po_close_phase`/`po_enter_phase`** (`in_c`, `out_c`, `buf`, `fid`) — local `var` arrays are a hard iiis-0 parse/codegen failure (Trap 7) and MUST be hoisted to module scope; (3) **the per-phase entry/exit clause tables are dead weight** — `po_enter_phase` loops over live entry clauses but calls `cp_verify_segment(0, here)` with identical arguments each iteration (it ignores the clause slot entirely, and `cp_verify_segment` verifies *all* preserver-attached formulas regardless), so the attach tables never bind to the actual verification; the maximal form drives `cp_attach_clause` from these tables so a phase's clauses are the ones the preserver checks; (4) **the close path never seals the phase's witness segment into the chain root** (`wh_epoch_close` is the realized primitive for exactly this and is unused), so each phase's "segment" is conceptual only; (5) **no capability gate (M8)** on the two privileged, irreversible transitions (`po_close_phase`, `po_enter_phase`) and **no PHASE_CLOSE/PHASE_ENTER witness on the refusal paths** (M6 continuity). The maximal form closes all five, plus adds a `po_phase_inited()`-style read accessor surface and a `po_quine_last()` verdict query, all append-only over the gospel API.

## Purpose
`aether::phase_orchestrator` **is** the constitutional clock of V2/V3 bring-up and steady-state: it embodies the twelve-phase lifecycle (0 bootstrap … 11 steady state) and the **Quiescence protocol** that gates every transition between phases. It is not a scheduler that *has* a phase variable — it *is* the phase boundary: a transition exists only as the atomic conjunction of (drain to zero in-flight) ∧ (constitutional preserver confirms the segment) ∧ (quine verifier reconstructs the seed bit-identically, W25) ∧ (a chained PHASE_CLOSE/PHASE_ENTER witness is emitted). Hexad kind: **kind_motion + kind_witness** (it drives temporal behavior and its primary externalized output is proofs-about-transitions). Ring: **R−1** (Sanctum-adjacent; it reads the seed-verification verdict and the constitutional verdict but mutates only its own phase state and the append-only witness chain). K-vector: **1.00**.

## Public API
All public fns return a status or a sentinel-typed value (W12). Error codes are negative `i32` compared by equality only (W9/W11). Booleans are `u8` 0/1 (W10). Every signature is single-line (Trap 1). The gospel's six-fn surface is preserved verbatim; the additions are append-only (W19) and capability-gated where they mutate phase state (M8).

```
fn po_init() -> i32 @export
fn po_current_phase() -> u8 @export
fn po_register_in_flight(pillar: u16) -> i32 @export
fn po_clear_in_flight(pillar: u16) -> i32 @export
fn po_attach_entry_clause(phase: u8, clause_slot: u32) -> i32 @export
fn po_attach_exit_clause(phase: u8, clause_slot: u32) -> i32 @export
fn po_close_phase(authority_cap: u64) -> i32 @export
fn po_enter_phase(target: u8, authority_cap: u64) -> i32 @export
fn po_inflight_total() -> u32 @export
fn po_phase_start(phase: u8) -> u64 @export
fn po_quine_last() -> u8 @export
```

- `po_init() -> i32` — `PHASEO_OK`; idempotent. Zeroes phase=0, all phase-start indices, all 16 pillar counters, both 384-entry clause-live bitmaps; derives the producer id and the two op-ids (close/enter) once; clears the quine-verdict cache; sets the init flag. (W12.)
- `po_current_phase() -> u8` — returns the current phase id 0..11. (Sentinel-typed read; W12.)
- `po_register_in_flight(pillar) -> i32` — `PHASEO_OK`, or `PHASEO_E_BAD` if `pillar >= 16`. Increments the pillar's in-flight count (saturating guard against wrap noted in Algorithm).
- `po_clear_in_flight(pillar) -> i32` — `PHASEO_OK`, or `PHASEO_E_BAD` if `pillar >= 16`. Decrements iff > 0 (floor at 0; never underflows — M5/M15 totality).
- `po_attach_entry_clause(phase, clause_slot) -> i32` — binds a constitution clause slot as a **precondition of entering** `phase`; `PHASEO_OK`, `PHASEO_E_BAD` on bad phase or table-full. Idempotent dedup (a clause slot is bound at most once per phase).
- `po_attach_exit_clause(phase, clause_slot) -> i32` — binds a constitution clause slot as a **precondition of closing** `phase`; same return discipline. Idempotent dedup.
- `po_close_phase(authority_cap) -> i32` — runs Quiescence on the current phase. Requires `cap_verify_rights(authority_cap, CAP_RIGHT_AMEND) == 1` (M8: a phase transition is a constitutional act). Returns `PHASEO_OK` on success after advancing the phase; `PHASEO_E_DENIED` if the cap lacks the amend right; `PHASEO_E_INFLIGHT` if any pillar is non-zero; `PHASEO_E_CLAUSE` if the preserver rejects the exit segment; `PHASEO_E_QUINE` if the seed reconstruction fails (W25 hard halt); `PHASEO_E_BAD` if uninitialized. **Refusal on any gate emits a PHASE_CLOSE witness with the failing verdict byte** (M6).
- `po_enter_phase(target, authority_cap) -> i32` — admits entry into `target` (must equal current+1, in order, W16). Requires `CAP_RIGHT_AMEND`. Verifies the entering phase's entry clauses against the chain end. `PHASEO_OK`, `PHASEO_E_DENIED`, `PHASEO_E_ORDER` (target != current+1 or target out of range), `PHASEO_E_CLAUSE`. (Note: the gospel split close/advance into `po_close_phase` already advancing the phase **and** a separate `po_enter_phase`; this spec preserves both but resolves their composition — see Algorithm.)
- `po_inflight_total() -> u32` — sum of all 16 pillar counters (was non-export internal in the gospel; exported as a read accessor for the awareness pillar, which samples "phase orchestrator queue depth", gospel L14641). Sentinel-typed (W12).
- `po_phase_start(phase) -> u64` — returns the recorded chain index at which `phase` began, or `0xFFFFFFFFFFFFFFFFu64` if `phase >= 12`. Read accessor (W12).
- `po_quine_last() -> u8` — returns the cached verdict (1=last boundary quine check passed, 0=failed/none) of the most recent `po_close_phase`. Read accessor for the distress/awareness path (W10/W12).

## Constant Namespace
PREFIX = `PHASEO_` . Grep of `STDLIB/` for `\bPHASEO_[A-Z]` returns **no matches** (confirmed) — no collision. The gospel candidate used `PO_`; grep of `STDLIB/` for `\bPO_[A-Z]` also returns **no matches today**, but `PO_` is a short, collision-prone namespace (Trap 2: every module-scope `const`/`var` emits a linker-global `L_<NAME>`), and the dispatch assigns `PHASEO_`. This spec therefore renames **every module-level `const` and `var`** to the `PHASEO_` prefix (exactly as Module 19 renamed `CP_`→`CPRES_`). Public **function** names keep the gospel's `po_` verb prefix (function symbols are contractual and namespaced separately).

| const | type | value | note |
|---|---|---|---|
| `PHASEO_OK` | i32 | `0i32` | success (W9) |
| `PHASEO_E_BAD` | i32 | `-1i32` | bad arg / uninitialized / table full |
| `PHASEO_E_INFLIGHT` | i32 | `-2i32` | drain incomplete (in-flight != 0) |
| `PHASEO_E_CLAUSE` | i32 | `-3i32` | constitutional preserver rejected the segment |
| `PHASEO_E_ORDER` | i32 | `-4i32` | out-of-order phase entry |
| `PHASEO_E_DENIED` | i32 | `-5i32` | capability lacks `CAP_RIGHT_AMEND` (M8) |
| `PHASEO_E_QUINE` | i32 | `-6i32` | quine seed reconstruction failed (W25 hard halt) |
| `PHASEO_N_PHASES` | u8 | `12u8` | phases 0..11 |
| `PHASEO_MAX_CLAUSES_PER_PHASE` | u32 | `32u32` | clause-table fan-out per phase (W8 bound) |
| `PHASEO_N_PILLARS` | u32 | `16u32` | in-flight counter table width (W8 bound) |
| `PHASEO_CLAUSE_TABLE` | u32 | `384u32` | `12 * 32`; total clause-table entries |
| `PHASEO_PRODUCER_LEN` | u64 | `26u64` | bytes of `"aether::phase_orchestrator"` (8+18=26 — verified) |
| `PHASEO_OPID_CLOSE_LEN` | u64 | `33u64` | bytes of `"aether::phase_orchestrator::close"` (26+2+5=33 — verified) |
| `PHASEO_OPID_ENTER_LEN` | u64 | `33u64` | bytes of `"aether::phase_orchestrator::enter"` (26+2+5=33 — verified) |
| `PHASEO_PILLAR_WITNESS` | u16 | `6u16` | pillar id stamped on PHASE_CLOSE/PHASE_ENTER fragments (motion pillar) |
| `PHASEO_CLOSE_PRE_LEN` | u64 | `18u64` | close pre-image length: 1 phase + 8 seg_start + 8 seg_end + 1 verdict |
| `PHASEO_ENTER_PRE_LEN` | u64 | `10u64` | enter pre-image length: 1 target + 8 chain_end + 1 verdict |
| `PHASEO_FAIL_SENT` | u64 | `0xFFFFFFFFFFFFFFFFu64` | wh_publish failure sentinel / phase-start absence sentinel |

**Byte-length audit (M2/M10 — wrong lengths break witness identity):** `"aether::phase_orchestrator"` = `aether` (6) + `::` (2) + `phase_orchestrator` (18) = **26**. The gospel used `26u64` — correct, retained. `"aether::phase_orchestrator::close"` and `"…::enter"` = 26 + 2 + 5 = **33**; gospel used `33u64` — correct, retained. (Contrast Module 19, where the candidate's `29u64` was an off-by-one; here the candidate's lengths are right.)

## Data Structures
All module-scope, statically sized (W8). **No local `var` arrays** (Trap 7) — the gospel's four in-function `var` arrays are hoisted here. The module is **not reentrant** (a phase boundary is single-threaded by construction — Quiescence guarantees no concurrent transition); noted.

| name | type | size | bound justification |
|---|---|---|---|
| `PHASEO_PHASE` | `u8` (=0) | scalar | current phase id 0..11 |
| `PHASEO_PHASE_START` | `[u64; 12]` | 12 | chain index at which each phase began; bound = `PHASEO_N_PHASES` |
| `PHASEO_IN_FLIGHT` | `[u32; 16]` | 16 | per-pillar in-flight op count; bound = 16 pillars (the substrate's fixed pillar count, gospel pillar enumeration) |
| `PHASEO_ENTRY_LIVE` | `[u8; 384]` | 384 | liveness flag per (phase,clause) entry slot; bound = `12*32` (W8) |
| `PHASEO_ENTRY_CLAUSE` | `[u32; 384]` | 384 | constitution clause slot per entry attachment |
| `PHASEO_EXIT_LIVE` | `[u8; 384]` | 384 | liveness flag per (phase,clause) exit slot |
| `PHASEO_EXIT_CLAUSE` | `[u32; 384]` | 384 | constitution clause slot per exit attachment |
| `PHASEO_PRODUCER` | `[u8; 32]` | 32 | witness producer id = Keccak256("aether::phase_orchestrator") |
| `PHASEO_OPID_CLOSE` | `[u8; 32]` | 32 | op-id for PHASE_CLOSE fragments |
| `PHASEO_OPID_ENTER` | `[u8; 32]` | 32 | op-id for PHASE_ENTER fragments |
| `PHASEO_QUINE_LAST` | `u8` (=0) | scalar | cached verdict of last boundary quine check (W25 / `po_quine_last`) |
| `PHASEO_INITED` | `u8` (=0) | scalar | init guard |
| `PHASEO_IN_C` | `[u8; 32]` | 32 | witness `in_commit` scratch (hoisted from local `var`, Trap 7) |
| `PHASEO_OUT_C` | `[u8; 32]` | 32 | witness `out_commit` scratch (hoisted, Trap 7) |
| `PHASEO_CLOSE_BUF` | `[u8; 18]` | 18 | PHASE_CLOSE pre-image scratch: phase(1)+seg_start(8)+seg_end(8)+verdict(1) |
| `PHASEO_ENTER_BUF` | `[u8; 10]` | 10 | PHASE_ENTER pre-image scratch: target(1)+chain_end(8)+verdict(1) |
| `PHASEO_FID` | `[u8; 32]` | 32 | fragment-id output scratch |

**Audit note (Trap 7, load-bearing):** the gospel declared `var in_c : [u8;32]`, `var out_c : [u8;32]`, `var buf : [u8;17]`/`[u8;9]`, `var fid : [u8;32]` **inside** `po_close_phase` and `po_enter_phase`. Local `var` arrays parse only at module scope in iiis-0 — this is the most likely silent parse/codegen failure in the candidate. All four are hoisted above; the two pre-image buffers are merged per-path (`PHASEO_CLOSE_BUF` 18 bytes, `PHASEO_ENTER_BUF` 10 bytes — note both are **one byte longer** than the gospel's 17/9 because the maximal form appends the verdict byte to the pre-image so success and refusal produce distinct `out_commit`s, M6).

## Dependencies (externs)
Each `extern @abi(c-msvc-x64)`. Multi-line `extern` declarations are house style (witness_hook.iii:144) and acceptable — Trap 1 governs `fn` *definitions* with bodies, not extern declarations. **All signatures below were verified against the real provider files / realized specs**, not the gospel's externs.

| extern fn | from module | NN | built? |
|---|---|---|---|
| `ident_from_bytes(input:*u8, in_len:u64, out:*u8) -> i32` | `identifier.iii` (in `numera/`) | 01 | **built** (verified `STDLIB/iii/numera/identifier.iii:33`) |
| `wh_publish(producer:*u8,opid:*u8,in_commit:*u8,out_commit:*u8,revtag:u8,phase:u8,pillar:u16,antecedents:*u8,n_ante:u32,payload:*u8,payload_len:u32,out_frag_id:*u8) -> u64` | `witness_hook.iii` | (built, `aether/`) | **built** (verified `…/aether/witness_hook.iii:144`) |
| `wh_chain_root(out_id:*u8) -> i32` | `witness_hook.iii` | (built, `aether/`) | **built** (verified `:216`) |
| `wh_next_idx() -> u64` | `witness_hook.iii` | (built, `aether/`) | **built** (verified `:240`) |
| `wh_epoch_close() -> u64` | `witness_hook.iii` | (built, `aether/`) | **built** (verified `:223`) — seals the phase segment into the chain root |
| `cp_verify_segment(start:u64, end:u64) -> u8` | `constitution_preserver.iii` | 19 | **NOT-YET-BUILT** (spec'd: `DOCS/CONVERGENCE-SPECS/constitution_preserver.spec.md` line 16) |
| `cp_attach_clause(clause_slot:u32, formula_slot:u32) -> i32` | `constitution_preserver.iii` | 19 | **NOT-YET-BUILT** (Module 19) — used to bind a phase's clauses to the preserver |
| `qv_verify_publish() -> u64` | `quine_verifier.iii` | 20 | **NOT-YET-BUILT** (spec'd: `quine_verifier.spec.md` line 19) — verify seed AND emit Quine Verification Witness; sentinel on failure |
| `cap_verify_rights(id:u64, required:u64) -> u8` | `capability.iii` | (built, `aether/`) | **built** (verified `…/aether/capability.iii:148`) — M8 gate |

**Const imported by value (not an extern):** `CAP_RIGHT_AMEND = 0x4000u64` is a public spec bit from `capability.iii` (verified `:66`). iiis cannot import another module's `const`; this module declares its own `PHASEO_CAP_AMEND : u64 = 0x4000u64` mirroring the published bit and notes the source. (Listed under Constant Namespace conceptually; included here for provenance.)

**Wave-scheduler note:** Module 32 must be ordered **after** Module 19 (`constitution_preserver`), Module 20 (`quine_verifier`), and the already-built `capability.iii`, `witness_hook.iii`, `identifier.iii`. This matches the gospel dependency ordering (L654: "33. aether/phase_orchestrator.iii"). Three not-yet-built deps: **19, 20, and (transitively, since 19 needs them) 13/14** — but 32's *direct* not-yet-built deps are exactly **{19, 20}**.

**Symbols deliberately NOT required:** briefing §3.5 #6 (witness_hook field getters for producer/opid/phase/pillar/at_time/revoked) — this module only *publishes* fragments and reads `wh_chain_root`/`wh_next_idx`; it never reads back a fragment's fields, so it needs **none** of the Phase-2 getters. `keccak256_*` (§3.5 #1) — not used directly; hashing of pre-images goes through `ident_from_bytes` (which wraps `keccak256_oneshot` internally). `at_now`/algebraic time (§3.5 #4) — **not called directly**; `wh_publish` advances algebraic time via `at_advance()` internally (verified `witness_hook.iii:159`), so W16/W17 monotonicity holds transitively without this module touching `numera/algebraic_time.iii`. `cons_find` (§3.5 #3) — not used. All five systemic gospel defects are thereby avoided by construction; documented here for the auditor.

## Algorithm
NIH (M1): only identifier / witness_hook / constitution_preserver / quine_verifier / capability externs, all in-tree. No ML (M3): no counting-and-promoting, no thresholds, no adaptation — every gate is an exact boolean (`== 0u32` drain, `== 1u8` preserver verdict, sentinel compare on quine, exact `cap_verify_rights`). No heuristics (M4): the transition is the algebraic conjunction of fixed predicates. Determinism (M2) / bit-identity (W5): all witness pre-images are fixed little-endian byte layouts over `u8`/`u64` fields; the producer/op-ids are Keccak256 over fixed strings; therefore every emitted fragment id is byte-reproducible from recorded inputs (M10). No recursion (W15): all iteration is flat `while` over indices. No `break` (W14): loops use a sentinel/hi-shadow that drives the loop **condition** itself.

**`po_init`** — set `PHASEO_PHASE = 0`; loop `i` 0..12 zeroing `PHASEO_PHASE_START[i]`; loop `p` 0..16 zeroing `PHASEO_IN_FLIGHT[p]`; loop `k` 0..384 zeroing `PHASEO_ENTRY_LIVE[k]` and `PHASEO_EXIT_LIVE[k]`; derive `PHASEO_PRODUCER = ident_from_bytes("aether::phase_orchestrator", 26)`, `PHASEO_OPID_CLOSE = ident_from_bytes("aether::phase_orchestrator::close", 33)`, `PHASEO_OPID_ENTER = ident_from_bytes("aether::phase_orchestrator::enter", 33)`; `PHASEO_QUINE_LAST = 0`; `PHASEO_INITED = 1`; return `PHASEO_OK`. (Single counting loop per table; each loop's bound is a literal/const, W14-safe.)

**`po_current_phase`** — return `PHASEO_PHASE`.

**`po_register_in_flight(pillar)`** — `pi = pillar as u32`; if `pi >= 16u32` return `PHASEO_E_BAD`; `PHASEO_IN_FLIGHT[pi] = PHASEO_IN_FLIGHT[pi] + 1u32` (mask `& 0xFFFFFFFFu32` to keep within width, W4; saturating-guard: the in-flight count is bounded by the live op fan-out which is « 2^32, so practical overflow is impossible, but the mask is applied for bit-hygiene). Return `PHASEO_OK`. **Trap 4:** `pi` is used only as an array index into a `[u32;16]` (element math is `pi*4` done by the compiler on a value known < 16); it is never the base of *manual* pointer arithmetic, so the `as u64` mask is not triggered — but the spec mandates `(pi as u64) & 0xFFFFFFFFu64` if a future change indexes a byte buffer by it.

**`po_clear_in_flight(pillar)`** — `pi = pillar as u32`; if `pi >= 16u32` return `PHASEO_E_BAD`; if `PHASEO_IN_FLIGHT[pi] > 0u32` decrement (floor at 0 — never underflows; M5 no-bricking / M15 totality). Return `PHASEO_OK`.

**`po_inflight_total`** — `s=0`; loop `p` 0..16 `s = s + PHASEO_IN_FLIGHT[p]`; return `s & 0xFFFFFFFFu32` (W4). (Exported read accessor.)

**`po_attach_entry_clause(phase, clause_slot)` / `po_attach_exit_clause(phase, clause_slot)`** — if `phase >= 12u8` return `PHASEO_E_BAD`; `base = (phase as u32) * 32u32`. **Dedup scan** (maximal-form fix): loop `i` 0..32 over `[base+i]`; if `LIVE[base+i]==1u8 && CLAUSE[base+i]==clause_slot` the clause is already bound — return `PHASEO_OK` (idempotent; no double-bind, so the verification is a function of the clause *set*, not attach order — M2). **First-free scan:** loop `i` 0..32; on first `LIVE[base+i]==0u8`, set `CLAUSE[base+i]=clause_slot`, `LIVE[base+i]=1u8`, return `PHASEO_OK`. Return `PHASEO_E_BAD` if the phase's 32-slot table is full. Both scans are sentinel-flag `while` loops driving the condition (W14, no `break`): use a `hi` shadow initialized to 32 and set to `i` on the hit so `while i < hi` exits. (The gospel did a single first-free scan with no dedup; dedup is the determinism fix.)

**`po_close_phase(authority_cap)`** — the Quiescence protocol, **six steps** (gospel had three; the maximal form inserts the capability gate, the clause-attach binding, the quine check, and the epoch seal):
  0. **Init guard:** if `PHASEO_INITED == 0u8` return `PHASEO_E_BAD`.
  1. **Capability (M8):** `cap = authority_cap` (assigned to a local first — param-spill discipline); if `cap_verify_rights(cap, PHASEO_CAP_AMEND) != 1u8` return `PHASEO_E_DENIED`. (No witness on a denied cap — an unauthorized caller never gets to mutate the chain; this is refusal, not a recordable phase event.)
  2. **Drain (Quiescence core):** if `po_inflight_total() != 0u32` → **emit a PHASE_CLOSE refusal witness** (verdict byte 0, seg = `[PHASEO_PHASE_START[PHASEO_PHASE], wh_next_idx())`) then return `PHASEO_E_INFLIGHT`. (M6: every refusal at a constitutional boundary is itself witnessed and chained.)
  3. **Bind this phase's exit clauses to the preserver:** `base = (PHASEO_PHASE as u32)*32`; loop `i` 0..32; for each `EXIT_LIVE[base+i]==1u8`, call `cp_attach_clause(EXIT_CLAUSE[base+i], EXIT_CLAUSE[base+i])` (formula slot == clause slot by the constitution's clause↔formula identity convention; Module 13/19 bind a clause's LTL formula at the same slot). This is the fix for the dead clause table: the orchestrator *drives* the preserver's attachment set from its per-phase exit clauses. (`cp_attach_clause` is idempotent/dedups per Module 19, so re-binding across closes is safe.)
  4. **Preserver verdict:** `seg_start = PHASEO_PHASE_START[PHASEO_PHASE]`; `seg_end = wh_next_idx()`; if `cp_verify_segment(seg_start, seg_end) == 0u8` → emit PHASE_CLOSE refusal witness (verdict 0) then return `PHASEO_E_CLAUSE`.
  5. **Quine self-verification (W25, the headline addition):** `qrc = qv_verify_publish()`; set `PHASEO_QUINE_LAST = 1u8 if qrc != PHASEO_FAIL_SENT else 0u8`; if `qrc == PHASEO_FAIL_SENT` → emit PHASE_CLOSE refusal witness (verdict 0) then return `PHASEO_E_QUINE` (**hard halt** — "Failure halts integration", W25). `qv_verify_publish` itself emits a Quine Verification Witness, so the seed-reconstruction proof is chained ahead of the PHASE_CLOSE fragment and becomes its causal antecedent.
  6. **Success: publish PHASE_CLOSE + seal + advance.** Build `PHASEO_CLOSE_BUF` (byte 0 = `PHASEO_PHASE`; bytes 1..8 = `seg_start` LE; bytes 9..16 = `seg_end` LE; byte 17 = verdict `1u8`) via byte-wise `*u8` stores with `& 0xFFu64` extraction (Trap 5 — never store a u64-derived value through a wider write). `wh_chain_root(&PHASEO_IN_C)` for `in_commit`; `ident_from_bytes(&PHASEO_CLOSE_BUF, 18, &PHASEO_OUT_C)` for `out_commit` (binds phase+segment+verdict). `wh_publish(&PHASEO_PRODUCER, &PHASEO_OPID_CLOSE, &PHASEO_IN_C, &PHASEO_OUT_C, 0u8 /*revtag*/, PHASEO_PHASE, PHASEO_PILLAR_WITNESS, &PHASEO_CLOSE_BUF /*antecedents, n_ante=0*/, 0u32, &PHASEO_CLOSE_BUF /*payload*/, 18u32, &PHASEO_FID)`. Then **`wh_epoch_close()`** to fold every fragment in `[seg_start, wh_next_idx())` into the chain root (seals the phase segment — the gap-4 fix). Advance: `PHASEO_PHASE = PHASEO_PHASE + 1u8`; clamp `if PHASEO_PHASE >= 12u8 { PHASEO_PHASE = 11u8 }` (steady-state is terminal — phase 11 closes to itself, M5 no-bricking: the machine never indexes past its table). Record `PHASEO_PHASE_START[PHASEO_PHASE] = wh_next_idx()`. Return `PHASEO_OK`.
  - **Composition note:** the gospel's `po_close_phase` advances the phase by itself, then `po_enter_phase(target)` requires `target == PHASEO_PHASE + 1` — i.e. *after* close advanced, `po_enter_phase` could never fire (target would have to be current+1 of the already-advanced phase). The maximal form resolves this: `po_close_phase` advances to the next phase and records its start (the phase is *entered* implicitly on close), while `po_enter_phase` remains the **explicit-entry variant** for flows that close and enter as two ratifiable steps — it does NOT advance in close; instead close leaves `PHASEO_PHASE` on the *closing* phase and `po_enter_phase(current+1)` performs the advance after verifying entry clauses. **Chosen design (single source of truth): `po_close_phase` performs steps 0–6 but does NOT advance; it sets a "closed" high-water by recording `seg_end`. `po_enter_phase(target)` performs the advance.** See `po_enter_phase`. (This removes the gospel's self-contradiction; both fns keep their gospel signatures + the cap param.)

  **Revised step 6 (no advance in close):** publish PHASE_CLOSE (verdict 1), `wh_epoch_close()`, set `PHASEO_QUINE_LAST`, return `PHASEO_OK`. The phase counter is advanced only by `po_enter_phase`.

**`po_enter_phase(target, authority_cap)`** — explicit entry/advance.
  0. if `target >= 12u8` return `PHASEO_E_ORDER`; if `target != (PHASEO_PHASE + 1u8)` return `PHASEO_E_ORDER` (in-order only, W16).
  1. **Capability (M8):** `cap = authority_cap`; if `cap_verify_rights(cap, PHASEO_CAP_AMEND) != 1u8` return `PHASEO_E_DENIED`.
  2. **Bind + verify the entering phase's entry clauses:** `base = (target as u32)*32`; `here = wh_next_idx()`. Loop `i` 0..32; for each `ENTRY_LIVE[base+i]==1u8`, `cp_attach_clause(ENTRY_CLAUSE[base+i], ENTRY_CLAUSE[base+i])`. Then a single `cp_verify_segment(0u64, here) == 0u8` → `ok=0` (entry clauses are global-history predicates: "every clause attached to the entering phase holds at the current chain end", gospel L8902 — verified over `[0, here)`). **W14/Trap 10 fix:** the gospel used `let mut ok = 1u8` and gated the per-iteration `cp_verify_segment` call with `if ok == 1u8`, calling it once per live clause with identical args — wasteful and a checkpoint-flag-driving-body anti-pattern. The maximal form attaches all clauses first, then calls `cp_verify_segment` **once** (the preserver already ANDs over all attached formulas), so there is no per-clause flag at all — the verdict is a single boolean.
  3. if `ok == 0u8` (i.e. verdict was 0) → emit a PHASE_ENTER refusal witness (verdict 0, target, here) then return `PHASEO_E_CLAUSE` (M6).
  4. **Success: publish PHASE_ENTER + advance.** Build `PHASEO_ENTER_BUF` (byte 0 = `target`; bytes 1..8 = `here` LE; byte 9 = verdict `1u8`) via byte-wise `*u8` stores. `wh_chain_root(&PHASEO_IN_C)`; `ident_from_bytes(&PHASEO_ENTER_BUF, 10, &PHASEO_OUT_C)`. `wh_publish(&PHASEO_PRODUCER, &PHASEO_OPID_ENTER, &PHASEO_IN_C, &PHASEO_OUT_C, 0u8, target, PHASEO_PILLAR_WITNESS, &PHASEO_ENTER_BUF, 0u32, &PHASEO_ENTER_BUF, 10u32, &PHASEO_FID)`. `PHASEO_PHASE = target`; `PHASEO_PHASE_START[target as u32] = here`. Return `PHASEO_OK`.

**`po_phase_start(phase)`** — if `phase >= 12u8` return `PHASEO_FAIL_SENT`; else return `PHASEO_PHASE_START[phase as u32]`.

**`po_quine_last`** — return `PHASEO_QUINE_LAST`.

**Address-of idiom:** module-scope arrays are passed as `(&PHASEO_X as u64) as *u8` (house style, witness_hook.iii / capability.iii) OR `&PHASEO_X[0u64] as *u8` (the gospel candidate's form, also valid — identifier.iii/quine_verifier gospel use it). This spec standardizes on `(&PHASEO_X as u64) as *u8` to match the two built exemplars. Both compile; the choice is for consistency.

## KAT Vectors (>= 3)
These are the Phase-2 byte-for-byte acceptance gate. They run against `witness_hook` (built) plus stub or real `constitution_preserver` / `quine_verifier` / `capability`. Witness fragment ids are Keccak256 over the fixed pre-images, hence reproducible. Each KAT must hold a valid amend-capability id (mint via `cap_env_init()` which returns `CAP_ENV_ROOT=1` with all rights, verified `capability.iii:107`).

1. **Init + in-flight accounting.** `wh_init(1)`; `cap_env_init()` → `cap=1`; `po_init()` → `PHASEO_OK`; `po_current_phase()` → `0u8`; `po_register_in_flight(3u16)` ×2 → `PHASEO_OK`; `po_inflight_total()` → `2u32`; `po_clear_in_flight(3u16)` → `PHASEO_OK`; `po_inflight_total()` → `1u32`; `po_register_in_flight(16u16)` → `PHASEO_E_BAD` (out of range); `po_clear_in_flight(7u16)` on a zero counter → `PHASEO_OK` with total unchanged (floor at 0, no underflow). Asserts the counter table and bounds.

2. **Close refused while in-flight (drain gate + M6 refusal witness).** After KAT 1 (total=1), `po_close_phase(1u64)` → `PHASEO_E_INFLIGHT`; assert a PHASE_CLOSE fragment WAS published (`wh_next_idx()` increased by exactly 1) with payload byte 17 (verdict) == `0x00` and payload byte 0 == `0x00` (phase 0). `po_quine_last()` → `0u8` (quine not reached). Asserts the refusal-is-witnessed fix (M6) and that the drain gate precedes the preserver/quine gates.

3. **Capability gate (M8).** `po_init()`; `po_close_phase(0u64)` (cap id 0 = `CAP_INVALID`) → `PHASEO_E_DENIED` with **no** new fragment published (`wh_next_idx()` unchanged) — an unauthorized caller cannot write the chain. Then `po_attenuate` a child cap WITHOUT `CAP_RIGHT_AMEND` and assert `po_close_phase(child)` → `PHASEO_E_DENIED` likewise. Asserts the amend-right requirement.

4. **Clean close → quine pass → explicit enter (the W25 happy path).** `po_init()`; drain to zero; with a stub `cp_verify_segment` returning `1u8` and a stub `qv_verify_publish` returning a non-sentinel idx: `po_close_phase(1u64)` → `PHASEO_OK`; assert (a) a Quine Verification Witness was published by `qv_verify_publish` **before** the PHASE_CLOSE fragment (chain order), (b) the PHASE_CLOSE payload byte 17 == `0x01`, bytes 1..8 == `seg_start` LE, bytes 9..16 == `seg_end` LE, (c) `po_quine_last()` → `1u8`, (d) `po_current_phase()` still `0u8` (close does not advance). Then `po_enter_phase(1u8, 1u64)` → `PHASEO_OK`; assert a PHASE_ENTER fragment with payload byte 0 == `0x01`, byte 9 == `0x01`; `po_current_phase()` → `1u8`; `po_phase_start(1u8)` == the `here` recorded. Run the whole sequence twice and assert byte-identical fragment ids both runs (M2/M10 determinism).

5. **Quine failure halts (W25 hard halt).** `po_init()`; drain to zero; stub `cp_verify_segment` → `1u8`; stub `qv_verify_publish` → `PHASEO_FAIL_SENT` (`0xFFFF…FFFF`). `po_close_phase(1u64)` → `PHASEO_E_QUINE`; assert a PHASE_CLOSE refusal witness (verdict byte `0x00`) IS published; `po_quine_last()` → `0u8`; `po_current_phase()` unchanged. This is the direct guard for the headline missing duty.

6. **Out-of-order entry rejected.** After KAT 4 reaches phase 1: `po_enter_phase(3u8, 1u64)` → `PHASEO_E_ORDER` (target != current+1); `po_enter_phase(12u8, 1u64)` → `PHASEO_E_ORDER` (out of range); no fragment published in either case.

7. **Entry-clause rejection (preserver gate on entry).** `po_attach_entry_clause(1u8, 5u32)` → `PHASEO_OK`; `po_attach_entry_clause(1u8, 5u32)` again → `PHASEO_OK` (dedup, idempotent, no second slot consumed — verify by attaching 32 distinct slots then a 33rd → `PHASEO_E_BAD`, but the duplicate of slot 5 must NOT have consumed one of the 32). With stub `cp_verify_segment` → `0u8`: `po_enter_phase(1u8, 1u64)` → `PHASEO_E_CLAUSE` with a PHASE_ENTER refusal witness (verdict `0x00`); `po_current_phase()` unchanged.

## Trap Exposure
| # | trap | exposed? | avoidance |
|---|---|---|---|
| 1 | multi-line `fn` decl | no (defs single-line); externs multi-line OK | every `fn … {` is single-line (see Skeleton); externs are declarations, not bodies |
| 2 | module-level `const`/`var` linker-global | **yes** | every const/var prefixed `PHASEO_`; grep of `STDLIB/` for `\bPHASEO_[A-Z]` → no matches; the gospel's short `PO_` is renamed |
| 3 | signed `i32`/`i64` ordering compare SIGSEGV | no | all magnitude compares are on `u8`/`u32`/`u64` (`pillar`, `phase`, indices, counters) which are unsigned and safe; the only `i32` values are status codes, compared by `==`/`!=` only (W11) |
| 4 | u32-in-u64-slot garbage | latent | `pillar→pi`, `phase`, clause indices are used only as array subscripts on typed arrays (compiler computes element offset), never as the base of manual pointer math; spec mandates `(x as u64) & 0xFFFFFFFFu64` before any future manual byte-pointer indexing |
| 5 | `*u32` pointer store width | **yes (data path)** | every byte written into `PHASEO_CLOSE_BUF`/`PHASEO_ENTER_BUF` goes through `*u8` indexing with `((v >> (z*8)) & 0xFFu64) as u8` extraction — never a `*u32`/`*u64` store (the gospel's pattern, retained) |
| 6 | nested `/* */` comments | no | comments are single-level `/* */` or `//`; no nesting |
| 7 | local `var` arrays | **yes (candidate bug — load-bearing)** | the four in-function `var` arrays (`in_c`,`out_c`,`buf`,`fid` in both `po_close_phase` and `po_enter_phase`) are hoisted to module-scope `PHASEO_IN_C/OUT_C/CLOSE_BUF/ENTER_BUF/FID`; non-reentrant, acceptable (a phase boundary is single-threaded) |
| 8 | `}\nelse {` | no | no `else` clauses; cascaded `if … return` (house style) |
| 9 | em-dash `—` in `/* */` | **yes (risk)** | all comments use ASCII `--`, never `—` |
| 10 | `let mut` checkpoint-flag drives body not loop | **yes (candidate bug)** | the gospel's `let mut ok` in `po_enter_phase` (per-clause `cp_verify_segment` gated by `if ok==1u8`) is **eliminated**: attach all clauses, then a single `cp_verify_segment` call yields one boolean — no flag, no loop-gated side effect |
| 11 | `a % b` after a call | no | no modulo anywhere; the `* 32u32` base computations are multiplies, and `clamp` is a compare, not a `%` |
| 12 | `@specialize *T` stride | no | module is not generic; no `@specialize` |

## Gap / Fix List
PARTIAL — the gospel candidate's defects, each with its fix (all folded into Algorithm above):

1. **MISSING W25 quine self-verification (headline — M-level duty omitted).** The gospel `po_close_phase` runs only `cp_verify_segment`; it never reconstructs the seed. W25 (gospel L299-301) and the orchestration prose (L22006: orchestrator runs `qv_verify` periodically; L22018: schedules immediate quine verification on Tier-3 events) require the seed to be reconstructed and compared bit-identically **at the close of every phase**, with failure halting integration. → add step 5 of `po_close_phase`: `qv_verify_publish()`, cache the verdict, refuse (`PHASEO_E_QUINE`) + witness on the failure sentinel. KAT 5 guards the hard halt; KAT 4 guards the happy path + chain order. **This is the single most important correction.**

2. **Local `var` arrays inside both transition fns (Trap 7 — hard parse/codegen failure).** `var in_c/out_c/buf/fid` parse only at module scope in iiis-0. → hoist to `PHASEO_IN_C/OUT_C/CLOSE_BUF/ENTER_BUF/FID`. Likely a build failure exactly as written.

3. **Dead per-phase clause tables (incoherent verification, M2/M4).** `po_attach_entry_clause`/`po_attach_exit_clause` record clause slots, but `po_enter_phase` loops over them calling `cp_verify_segment(0, here)` with identical arguments (ignoring the slot), and `po_close_phase` ignores the exit table entirely; `cp_verify_segment` verifies *all* preserver-attached formulas regardless of these tables. → the orchestrator must **drive `cp_attach_clause` from its per-phase tables** (close binds the closing phase's exit clauses, enter binds the entering phase's entry clauses) before calling `cp_verify_segment` once. This makes a phase's declared clauses the ones actually checked. (Adds the `cp_attach_clause` extern, Module 19.)

4. **Phase segment never sealed into the chain root (M6/W5 continuity).** `wh_epoch_close()` is the realized primitive that folds a fragment range into the chain root (verified `witness_hook.iii:223`); the gospel never calls it, so the "phase's witness segment" is conceptual and the chain root does not advance per phase. → `po_close_phase` calls `wh_epoch_close()` after publishing PHASE_CLOSE, sealing `[seg_start, next)`.

5. **No capability gate on privileged irreversible transitions (M8).** A phase transition is a constitutional act; the gospel lets any caller invoke `po_close_phase`/`po_enter_phase`. → add `authority_cap: u64` and require `cap_verify_rights(cap, CAP_RIGHT_AMEND=0x4000) == 1` (verified `capability.iii:66,148`); else `PHASEO_E_DENIED`. (Append-only param addition; the gospel's zero-arg forms are superseded — W19 keeps every gospel fn name + adds the cap.)

6. **No witness on refusal paths (M6 continuity gap).** The gospel publishes PHASE_CLOSE/PHASE_ENTER only on success. A refused close (in-flight, clause-fail, quine-fail) and a refused entry leave no chained record. → publish a refusal fragment with verdict byte 0 on every gate failure *that the caller was authorized to attempt* (i.e. after the cap check passes; a denied cap is silent — an unauthorized actor never gets a chain entry). The verdict byte (appended to the pre-image) distinguishes success (1) from refusal (0), so `out_commit` differs and the chain records the verdict.

7. **`po_close_phase`/`po_enter_phase` composition contradiction.** The gospel's `po_close_phase` advances the phase itself, then `po_enter_phase` requires `target == PHASEO_PHASE + 1` — but after close has advanced, that predicate can never hold for the intended next phase. → resolved (Algorithm "Composition note"): **close does NOT advance; `po_enter_phase` performs the single advance** after verifying entry clauses. Both gospel signatures are preserved (+ cap param). Quiescence (drain/preserve/quine/seal/PHASE_CLOSE) is the close half; clause-verified advance + PHASE_ENTER is the enter half. This also matches the gospel prose ("publishes PHASE_CLOSE … and only then admits the next phase's entry" — two distinct events).

8. **`po_inflight_total` not exported.** The awareness pillar samples "phase orchestrator queue depth" (gospel L14641); the gospel's `po_inflight_total` is a private helper. → `@export` it (read-only accessor; W12). Added `po_phase_start` and `po_quine_last` read accessors likewise (append-only, W19).

9. **Const prefix `PO_` not namespace-safe.** Short prefix, Trap 2 risk across 60+ aether modules. → rename every const/var to `PHASEO_` (grep-clean). Public `po_*` fn names retained (contractual).

**Mandate posture summary:** M1 (NIH — only in-tree externs) ✓; M2/M5/W5 (deterministic, total, sealed pre-images) ✓; M3/M4 (no ML/heuristics — exact boolean gates) ✓; **M6 (witness continuity — now on success AND refusal, + epoch seal) ✓ (was ✗)**; M7 (Ring R−1) ✓; **M8 (capability-mediated transitions) ✓ (was ✗)**; M9/M16 (a refused boundary is not consumed — the phase counter does not advance, and the refusal is a ratifiable witnessed event) ✓; M10 (witness recomputable from fixed pre-images) ✓; M15 (in-flight counters total + floored) ✓; **W25 (quine at every boundary) ✓ (was ✗ — the headline fix)**; W2 (≤4 params: max is `wh_publish` extern at 12 — an extern, not a defined fn; defined fns are ≤2 params) ✓; W13 (≤20 locals: `po_close_phase` is the largest at ~14) ✓; W14 (no break; sentinel/hi-shadow conditions) ✓; W15 (no recursion; flat while) ✓; W16/W17 (in-order phases; algebraic time advances via `wh_publish`→`at_advance`) ✓.

## Implementation Skeleton
Paste-ready structure. Single-line `fn` signatures (Trap 1). No fn bodies (Phase 2 writes those per Algorithm §). ASCII `--` only in comments (Trap 9). No local `var` arrays (Trap 7).

```iii
/* III/STDLIB/iii/aether/phase_orchestrator.iii
 *
 * III STDLIB - aether::phase_orchestrator
 *
 * The constitutional clock. Twelve-phase state machine (0..11) and the
 * Quiescence protocol that gates every transition. A close runs the drain
 * gate, binds the closing phase's exit clauses to the preserver and verifies
 * the segment, runs the quine self-verification (W25), seals the segment into
 * the chain root, and publishes PHASE_CLOSE. An enter binds the entering
 * phase's entry clauses, verifies them at the chain end, and publishes
 * PHASE_ENTER. Both are capability-gated (CAP_RIGHT_AMEND) and witness their
 * refusals. The machine owns no temporal logic and no seed reconstruction --
 * it composes the preserver and the quine verifier.
 *
 * Phase identifiers 0..11:
 *   0 bootstrap  1 seed unpack  2 identity establish  3 audit
 *   4 reversibility audit  5 basal probe / shape negotiation
 *   6 capability forge  7 codegen pillar  8 immune scrub baseline
 *   9 awareness baseline  10 federation join  11 steady state
 *
 * Public API:
 *   po_init() -> i32
 *   po_current_phase() -> u8
 *   po_register_in_flight(pillar: u16) -> i32
 *   po_clear_in_flight(pillar: u16) -> i32
 *   po_attach_entry_clause(phase: u8, clause_slot: u32) -> i32
 *   po_attach_exit_clause(phase: u8, clause_slot: u32) -> i32
 *   po_close_phase(authority_cap: u64) -> i32
 *   po_enter_phase(target: u8, authority_cap: u64) -> i32
 *   po_inflight_total() -> u32
 *   po_phase_start(phase: u8) -> u64
 *   po_quine_last() -> u8
 *
 * Hexad: kind_motion + kind_witness.  Ring: R-1.  K: 1.00.
 * Discipline: W2, W8, W13, W14, W15 (no recursion). NIH: identifier,
 * witness_hook, constitution_preserver, quine_verifier, capability only.
 */

module aether_phase_orchestrator

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8,
              out_commit: *u8, revtag: u8, phase: u8, pillar: u16,
              antecedents: *u8, n_ante: u32,
              payload: *u8, payload_len: u32,
              out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_next_idx() -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_epoch_close() -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cp_verify_segment(start: u64, end: u64) -> u8 from "constitution_preserver.iii"
extern @abi(c-msvc-x64) fn cp_attach_clause(clause_slot: u32, formula_slot: u32) -> i32 from "constitution_preserver.iii"
extern @abi(c-msvc-x64) fn qv_verify_publish() -> u64 from "quine_verifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

const PHASEO_OK         : i32 =  0i32
const PHASEO_E_BAD      : i32 = -1i32
const PHASEO_E_INFLIGHT : i32 = -2i32
const PHASEO_E_CLAUSE   : i32 = -3i32
const PHASEO_E_ORDER    : i32 = -4i32
const PHASEO_E_DENIED   : i32 = -5i32
const PHASEO_E_QUINE    : i32 = -6i32

const PHASEO_N_PHASES            : u8  = 12u8
const PHASEO_MAX_CLAUSES_PER_PHASE : u32 = 32u32
const PHASEO_N_PILLARS           : u32 = 16u32
const PHASEO_CLAUSE_TABLE        : u32 = 384u32      // 12 * 32
const PHASEO_PRODUCER_LEN        : u64 = 26u64       // "aether::phase_orchestrator"
const PHASEO_OPID_CLOSE_LEN      : u64 = 33u64       // "aether::phase_orchestrator::close"
const PHASEO_OPID_ENTER_LEN      : u64 = 33u64       // "aether::phase_orchestrator::enter"
const PHASEO_PILLAR_WITNESS      : u16 = 6u16        // motion pillar id on fragments
const PHASEO_CLOSE_PRE_LEN       : u64 = 18u64       // phase(1)+seg_start(8)+seg_end(8)+verdict(1)
const PHASEO_ENTER_PRE_LEN       : u64 = 10u64       // target(1)+chain_end(8)+verdict(1)
const PHASEO_CAP_AMEND           : u64 = 0x4000u64   // mirrors capability.iii CAP_RIGHT_AMEND
const PHASEO_FAIL_SENT           : u64 = 0xFFFFFFFFFFFFFFFFu64

var PHASEO_PHASE        : u8  = 0u8
var PHASEO_PHASE_START  : [u64; 12]
var PHASEO_IN_FLIGHT    : [u32; 16]                  // per pillar
var PHASEO_ENTRY_LIVE   : [u8;  384]                 // 12 * 32
var PHASEO_ENTRY_CLAUSE : [u32; 384]
var PHASEO_EXIT_LIVE    : [u8;  384]
var PHASEO_EXIT_CLAUSE  : [u32; 384]
var PHASEO_PRODUCER     : [u8; 32]
var PHASEO_OPID_CLOSE   : [u8; 32]
var PHASEO_OPID_ENTER   : [u8; 32]
var PHASEO_QUINE_LAST   : u8  = 0u8
var PHASEO_INITED       : u8  = 0u8

/* Witness scratch -- module-scope (Trap 7: no local var arrays). Not reentrant;
 * a phase boundary is single-threaded by construction (Quiescence). */
var PHASEO_IN_C         : [u8; 32]
var PHASEO_OUT_C        : [u8; 32]
var PHASEO_CLOSE_BUF    : [u8; 18]
var PHASEO_ENTER_BUF    : [u8; 10]
var PHASEO_FID          : [u8; 32]

fn po_init() -> i32 @export {
    // TODO: body per Algorithm po_init -- phase=0; zero PHASE_START[0..12],
    // IN_FLIGHT[0..16], ENTRY_LIVE/EXIT_LIVE[0..384]; derive PRODUCER (len 26),
    // OPID_CLOSE/OPID_ENTER (len 33); QUINE_LAST=0; INITED=1; return PHASEO_OK
}

fn po_current_phase() -> u8 @export {
    // TODO: return PHASEO_PHASE
}

fn po_register_in_flight(pillar: u16) -> i32 @export {
    // TODO: pi = pillar as u32; if pi >= 16u32 -> PHASEO_E_BAD;
    // IN_FLIGHT[pi] = (IN_FLIGHT[pi] + 1u32) & 0xFFFFFFFFu32; return PHASEO_OK
}

fn po_clear_in_flight(pillar: u16) -> i32 @export {
    // TODO: pi = pillar as u32; if pi >= 16u32 -> PHASEO_E_BAD;
    // if IN_FLIGHT[pi] > 0u32 { IN_FLIGHT[pi] = IN_FLIGHT[pi] - 1u32 }; return PHASEO_OK
}

fn po_inflight_total() -> u32 @export {
    // TODO: s=0; loop p 0..16 s += IN_FLIGHT[p]; return s & 0xFFFFFFFFu32
}

fn po_attach_entry_clause(phase: u8, clause_slot: u32) -> i32 @export {
    // TODO: body per Algorithm -- if phase>=12u8 -> PHASEO_E_BAD; base=(phase as u32)*32u32;
    // dedup scan (return PHASEO_OK if already bound); first-free scan sets CLAUSE+LIVE (hi-shadow
    // while-cond, no break); PHASEO_E_BAD if table full
}

fn po_attach_exit_clause(phase: u8, clause_slot: u32) -> i32 @export {
    // TODO: as po_attach_entry_clause but on EXIT_LIVE/EXIT_CLAUSE
}

fn po_close_phase(authority_cap: u64) -> i32 @export {
    // TODO: body per Algorithm po_close_phase (steps 0-6, revised: NO advance):
    //  0 if INITED==0u8 -> PHASEO_E_BAD
    //  1 cap = authority_cap; if cap_verify_rights(cap, PHASEO_CAP_AMEND)!=1u8 -> PHASEO_E_DENIED (silent)
    //  2 if po_inflight_total()!=0u32 -> publish PHASE_CLOSE refusal (verdict 0) -> PHASEO_E_INFLIGHT
    //  3 base=(PHASE as u32)*32; loop 0..32: if EXIT_LIVE[base+i]==1u8 cp_attach_clause(EXIT_CLAUSE[..],EXIT_CLAUSE[..])
    //  4 seg_start=PHASE_START[PHASE]; seg_end=wh_next_idx(); if cp_verify_segment(seg_start,seg_end)==0u8
    //      -> publish PHASE_CLOSE refusal (verdict 0) -> PHASEO_E_CLAUSE
    //  5 qrc=qv_verify_publish(); QUINE_LAST = (qrc!=PHASEO_FAIL_SENT)?1u8:0u8;
    //      if qrc==PHASEO_FAIL_SENT -> publish PHASE_CLOSE refusal (verdict 0) -> PHASEO_E_QUINE (W25 halt)
    //  6 build CLOSE_BUF[18] (phase, seg_start LE, seg_end LE, verdict 1) byte-wise via *u8;
    //      wh_chain_root(IN_C); ident_from_bytes(CLOSE_BUF,18,OUT_C);
    //      wh_publish(PRODUCER,OPID_CLOSE,IN_C,OUT_C,0u8,PHASE,PHASEO_PILLAR_WITNESS,CLOSE_BUF,0u32,CLOSE_BUF,18u32,FID);
    //      wh_epoch_close(); return PHASEO_OK   (advance is performed by po_enter_phase)
}

fn po_enter_phase(target: u8, authority_cap: u64) -> i32 @export {
    // TODO: body per Algorithm po_enter_phase:
    //  0 if target>=12u8 -> PHASEO_E_ORDER; if target != (PHASE + 1u8) -> PHASEO_E_ORDER
    //  1 cap = authority_cap; if cap_verify_rights(cap, PHASEO_CAP_AMEND)!=1u8 -> PHASEO_E_DENIED
    //  2 base=(target as u32)*32; here=wh_next_idx(); loop 0..32: if ENTRY_LIVE[base+i]==1u8
    //      cp_attach_clause(ENTRY_CLAUSE[..],ENTRY_CLAUSE[..]); then v = cp_verify_segment(0u64, here)
    //  3 if v==0u8 -> publish PHASE_ENTER refusal (verdict 0) -> PHASEO_E_CLAUSE
    //  4 build ENTER_BUF[10] (target, here LE, verdict 1) byte-wise via *u8;
    //      wh_chain_root(IN_C); ident_from_bytes(ENTER_BUF,10,OUT_C);
    //      wh_publish(PRODUCER,OPID_ENTER,IN_C,OUT_C,0u8,target,PHASEO_PILLAR_WITNESS,ENTER_BUF,0u32,ENTER_BUF,10u32,FID);
    //      PHASE = target; PHASE_START[target as u32] = here; return PHASEO_OK
}

fn po_phase_start(phase: u8) -> u64 @export {
    // TODO: if phase>=12u8 -> PHASEO_FAIL_SENT; else return PHASE_START[phase as u32]
}

fn po_quine_last() -> u8 @export {
    // TODO: return PHASEO_QUINE_LAST
}
```
