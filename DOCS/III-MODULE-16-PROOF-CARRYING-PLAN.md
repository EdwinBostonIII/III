# Module 16 — Proof-carrying: lean implementation plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

## Gate cleared

Written only because **M14 + M15 are verified**: `bj36x90u9` `run_corpus PASS=399 FAIL=0`,
`678_memo_soundness=99` + `679_synthesis_bounds=99` (the latter after root-fixing the `ss_init`
idempotency trap), memo/synthesis set unchanged; `run_xii 93/0`. This turn carried M7→M15, all
gate-green. No placeholder/deferral/flaw.

## Context + gap analysis (organs complete + comprehensively gated)

M16 = the certificate discipline: `proof_carrying.iii` (Merkle/Keccak256 vector + polynomial
commitments, log-time opening proofs; `pc_selftest` KATs 1–6 incl. the flip-byte + wrong-payload
negatives — gated `639`), `proof_term.iii` (inference-rule proof terms with replay verification;
`pt_kat` 7 vectors incl. cyclic/arity/conclusion-mismatch negatives — gated `636`),
`theorem_carrier.iii` (a theorem = statement + **verified** proof-term id + content-address +
dependency closure; `tc_alloc` refuses unless `pt_verify==0` and every dep is resident — gated
`647`), `curry_howard.iii` (proof-as-program — gated `619`). The apotheosis falsifier: "an opening
proof that doesn't verify in log-time; a `tc_alloc` admitting a theorem with `pt_verify≠0` or an
absent dependency; a constitutional clause citing an unresident theorem → red." **Clauses #1 + #2
are already gated** (`pc_selftest`, `tc_kat`); clause #3 + the Pass-1 unification ("every SovVal
carries a kernel-verified proof term") are **cross-module compounds** (M10/M18, M5/M9), deferred.

**The genuine additive gap:** an end-to-end **trust-chain integration** falsifier — build a
proof-term via the *public* `proof_term` API, verify it, admit it as a `theorem_carrier` theorem,
and prove the chain holds *and* refuses the negatives (an **unverified** proof-term → theorem
refused; an **absent dependency** → refused). The individual KATs test each organ; this binds
`proof_term → theorem_carrier` across the public boundary (the M16 "proven facts are
`theorem_carrier` artifacts" claim, executable).

## ADR — Corpus-only integration falsifier; the universal-proof-carrying unification deferred

`680_proof_chain.iii`, no module edits (the organs are complete). Rejected: implementing
"every SovVal proof-carries" now (cross-module M5/M9 compound) and the M10 clause-cites-theorem
binding (M10/M18 compound). Net `PASS = 399 + 1`.

## Files

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/corpus/680_proof_chain.iii` | the `pt → tc` trust-chain: a verified proof-term is admitted as a theorem; an unverified proof-term + an absent-dependency theorem are REFUSED. |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[680_proof_chain]=99` (after `[679_synthesis_bounds]=99`; re-glob the number free — the OneDrive sync adds numbers). |
| **NO CHANGE** | `proof_*`/`theorem_carrier`/`curry_howard`, `build_stdlib.sh` MODULES | corpus-only. |

## Step 0 — Pre-flight (read-only — the construction templates)

0.1 `glob STDLIB/corpus/680_*.iii` (+ confirm free; if taken — sync — pick the next). 0.2
**`proof_term.iii` `pt_kat_add` arg-record** (confirmed this turn): a `*u8` aggregate —
`[0..32]=term_id`, `[32]=rule_kind`, `[33..36]=0`, `[36..40]=pcount` LE32, `[40..44]=clen` LE32,
`[44..44+pc*4]=premise indices` LE32, `[44+pc*4 ..]=conclusion bytes`; `PT_RULE_AXIOM=0x01`,
`PT_OK=0`. A minimal verified term = `pt_init` → `pt_alloc(tid)` → one AXIOM step (pcount 0, clen
1, conclusion `0x41`) → `pt_finalize(tid)` → `pt_verify(tid)==PT_OK`. 0.3 **Read
`theorem_carrier.iii`'s `tc_pack_alloc_req` + `tc_alloc` + the `THMC_*` codes** (the alloc-req
byte layout: statement ptr/len, proof-term id, dep count/list; `THMC_OK=0`,
`THMC_E_VERIFY_FAIL=-4`, `THMC_E_DEP_ABSENT=-5`). This is mandatory — I will not assume the req
layout (the `ss_init`/`679` lesson: read the lifecycle before asserting). 0.4 Baseline
`run_corpus FAIL=0`, `run_xii 93/0`.

## Step 1 — `680_proof_chain.iii`

`module corpus_680`; externs the `pt_*` construction set + `tc_init`/`tc_pack_alloc_req`/`tc_alloc`
(+ `wh_init` bootstrap, per `pt_kat`/`tc_kat`); module-scope scratch for the arg-record, the
term-ids, and the tc req. `main()`:
- bootstrap (`wh_init`); `pt_init`; build + finalize a proof-term `T1`; assert `pt_verify(T1)==PT_OK`.
- `tc_init`; pack an alloc-req citing `T1` (verified, no deps); `tc_alloc(req)` → `THMC_OK` — the
  trust chain holds: a verified proof-term is admitted as a theorem.
- **prove the negative #1 (unverified):** build a proof-term `T2` and **do not finalize/verify**
  it (or finalize but leave it failing); pack an alloc-req citing `T2`; `tc_alloc` →
  `THMC_E_VERIFY_FAIL` (a theorem with `pt_verify≠0` is refused).
- **prove the negative #2 (absent dependency):** pack an alloc-req citing `T1` but declaring a
  dependency on a non-resident carrier id; `tc_alloc` → `THMC_E_DEP_ABSENT`.
- distinct return code per check; `99` on pass. (Exact req packing fixed by Step 0.3.)

## Step 2 — register + Step 3 — test (one gate)

Add `[680_proof_chain]=99`. Pinned `COMPILED/iiis-2.exe`: (1) compile-only `680` → `rc=0`. (2)
`build_stdlib.sh` → `FAIL=0`, `forge_check` green. (3) `run_corpus.sh` → `FAIL=0`,
`680_proof_chain=99`, `636`/`639`/`647`/`619` unchanged (`PASS=400`). (4) `run_xii 93/0`. (5)
Manual hand-check: `T1` genuinely verifies, `T2` genuinely fails verification, the absent-dep id
is genuinely non-resident.

**Single falsifier:** `680 ≠ 99`, or `636`/`639`/`647`/`619` changing, or `run_xii` regressing →
red, revert, diagnose before rebuild.

## Standards & mandates

NIH (libc + III); determinism (equality-only verdicts); W2 (≤4 params; the arg-record is the W2
aggregate `proof_term` itself uses); W8 (module-scope scratch); W15. Falsifier + prove-the-negative
(unverified-pt refused, absent-dep refused). Apotheosis: closes the `pt→tc` trust-chain integration
(M16 "proven facts are theorem_carrier artifacts"); the universal-proof-carrying (M5/M9) +
clause-cites-theorem (M10/M18) unifications deferred to those modules.

## Roadmap

1. Step 0: read `tc_pack_alloc_req` + `tc_alloc` + `THMC_*` (the req construction template).
2. Steps 1–2: the trust-chain falsifier + register.
3. Step 3: one gate → `680=99`, `FAIL=0`, `run_xii 93/0`, no regression.
