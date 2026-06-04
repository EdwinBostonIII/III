# Organ E — the Forked Walk (`forcefield/forked_walk`) Implementation Plan

> **✅ IMPLEMENTED + GREEN (2026-06-04):** built, gated, verified on metal — KAT exit **99**.
> As-built corpus id is **1101** (`1101_forked_walk`, module `corpus_1101`) — renumbered from the
> planned 1093 (mid-reseal WIP churn on the corpus table). `build_stdlib` GATE PASS **460/0**;
> `forcefield/forked_walk.iii` + the KAT exist; uncommitted (commit gated). The code blocks below
> use the original 1093 — substitute **1101**.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this
> plan task-by-task. (NOT subagent-driven — III has a standing no-subagents rule; execute inline.)
> Steps use checkbox (`- [ ]`) syntax.

**Goal:** Explore candidate branches speculatively, leave no trace on the ones not taken, and commit
the best branch **as a disposer decision on value — never a race** — with every rollback witnessed.

**Architecture:** A thin driver `forcefield/forked_walk.iii` composes two already-built, corpus-green
organs: `numera/reversible.iii` (transactional envelopes — `rev_begin` opens one, forward effects
record undos, `rev_rollback` replays them in reverse *and witnesses it*, `rev_commit` keeps them) and
`forcefield/commit_gate.iii` (the disposer — `cg_cert_action` grants a commit certificate **only if
the branch's value strictly rises**; `cg_cert_abstain` certifies "frontier searched, nothing beat the
incumbent," making a *verified-optimal* no-op distinct from a never-checked one). The walk explores
each branch in an envelope, rolls it back, remembers the best by value (ties broken by smaller target
— order-free), then re-applies and commits the winner through the disposer, or abstains.

**Tech Stack:** III (`.iii`), pinned `COMPILED/iiis-2.exe`; built by `STDLIB/scripts/build_stdlib.sh`
into `libiii_native.a`; tested by `STDLIB/scripts/run_corpus.sh`. Dependencies (built + corpus-green
today): `numera/reversible` (`634_reversible`, `610_rev_invoke`), `forcefield/commit_gate`
(`864_forcefield_commit_gate`).

---

## How III "tests" work (condensed — see III-ORGAN-C-WITNESSED-SENSE-PLAN.md §"How III tests work" for the full version)

- A unit test is a **corpus KAT**: `STDLIB/corpus/NNNN_name.iii`, `fn main() -> u64` returns **`99`**
  on pass / a distinct small code at the first failing check, registered as `[NNNN_name]=99` in
  `run_corpus.sh`'s `EXPECTED` table (a missing entry is a **FATAL** harness error).
- **Build:** `bash STDLIB/scripts/build_stdlib.sh` — must end **`FAIL = 0`** (a failed module leaves
  `libiii_native.a` STALE → false passes; always confirm `FAIL = 0`).
- **Run:** `bash STDLIB/scripts/run_corpus.sh` — exit code = FAIL count.
- **Compiler pinned** to `COMPILED/iiis-2.exe`; never override `IIIS=`.
- **Determinism gate / reseal:** `forked_walk` is a **stdlib** module the **compiler never
  references** → no seed drift → **no reseal** (ADR-027). The gate for this work is exactly:
  `build_stdlib` `FAIL = 0`, `1093_forked_walk = 99`, no other corpus entry regresses.

### iiis idiom rules this plan obeys
- **Module-scope arrays only** for runtime-indexed state (function-local arrays segfault). All state
  is module-scope `FW_*`.
- **`u64` ordering is SAFE** (the SIGSEGV trap is *signed i64* only — confirmed in
  `algebraic_time.iii`); the walk compares values with `u64` `>`/`<` plus `==`/`!=`. No `i64` ordering.
- **Address-of:** `&FW_CELL as u64`. No `i64` literal before `{`; no `%`/`/` after a call.

---

## File structure

| Action | File | Responsibility |
|--------|------|----------------|
| **CREATE** | `STDLIB/iii/forcefield/forked_walk.iii` | the speculate→dispose→commit driver over `reversible` + `commit_gate` |
| **CREATE** | `STDLIB/corpus/1093_forked_walk.iii` | the falsifier KAT (`main → 99`) |
| **MODIFY** | `STDLIB/scripts/build_stdlib.sh` | add `"forcefield/forked_walk"` to `MODULES` after `"forcefield/commit_gate"` |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[1093_forked_walk]=99` to `EXPECTED` |

---

## ADR-1 — the Forked Walk is a DRIVER over two built organs, not new substrate

- **Speculation + witnessed rollback** is `numera/reversible.iii`: `rev_begin(cap)` opens an envelope,
  `rev_record(slot, REV_TAG_MEM_RESTORE_U64, &cell, prior)` records the inverse, the forward mutation
  is applied, and `rev_rollback(slot)` replays the inverse (emitting a witnessed rollback fragment via
  `wh_publish`) leaving the state byte-for-byte as before. A loser branch therefore leaves **no trace**.
- **The commit is a disposer decision, not a race** — `forcefield/commit_gate.iii`:
  `cg_cert_action(CG_ADMIT, v_before, v_after, proof_ok)` returns `CG_CERT (99)` **iff `v_after >
  v_before`** (and φ admits and the proof checks); `cg_cert_abstain(searched, frontier_best,
  v_incumbent)` returns `CG_CERT` iff `searched == 1` and `frontier_best <= v_incumbent`, else
  `CG_CERT_UNSEARCHED (14)` / `CG_CERT_IMPROVABLE (15)`. So the winner is chosen by **value**, and an
  abstention must prove the frontier was actually searched.
- **Path-independence:** the walk keeps the strictly-greater value; on a tie it keeps the **smaller
  target**. Both are order-free, so the committed winner is independent of exploration order.

**Single falsifier:** `1093_forked_walk ≠ 99` — a loser leaving a trace, the best not committed when it
strictly improves, a different order changing the winner, an abstention granted **without** a searched
frontier (a race-commit), or a rollback not restoring the incumbent exactly.

---

## Step 0 — Pre-flight (read-only)

- [ ] **0.1 Prefix free:** `grep -rn "module forcefield_forked_walk\|fn fw_explore\|FW_BEST_TGT" STDLIB/iii` → no matches.
- [ ] **0.2 Corpus id free:** `grep -n "1093_" STDLIB/scripts/run_corpus.sh` → no matches.
- [ ] **0.3 Externs exist (signatures used verbatim below):**
  - `grep -n "fn rev_init\|fn rev_begin\|fn rev_record\b\|fn rev_rollback\|fn rev_commit" STDLIB/iii/numera/reversible.iii`
  - `grep -n "fn cg_cert_action\|fn cg_cert_abstain" STDLIB/iii/forcefield/commit_gate.iii`
  - Confirm `REV_TAG_MEM_RESTORE_U64 = 2`, `cg` reject `CG_CERT_UNSEARCHED = 14`, grant `99`.
- [ ] **0.4 Baseline:** `bash STDLIB/scripts/build_stdlib.sh` ends `FAIL = 0`; `bash STDLIB/scripts/run_corpus.sh` → record `PASS=<N> FAIL=0`. (If Organ C landed first, this `N` already includes `1092`.)

---

## Task 1: Failing KAT — register `1093_forked_walk` and watch it fail to link

**Files:** Create `STDLIB/corpus/1093_forked_walk.iii`; Modify `STDLIB/scripts/run_corpus.sh`.

- [ ] **Step 1: Write the KAT** (`STDLIB/corpus/1093_forked_walk.iii`)

```iii
/* 1093_forked_walk.iii — falsifier for Organ E (forcefield/forked_walk, the Forked Walk).
 * Proves the speculate->dispose->commit pattern is sound:
 *   (1) a speculatively-explored branch leaves NO trace (the cell rolls back);
 *   (2) the best branch (by value) is remembered across a fan of branches;
 *   (3) the disposer COMMITS the winner iff it strictly improves (the cell becomes the winner);
 *   (4) path-independence: a different exploration ORDER yields the SAME winner;
 *   (5) when nothing beats the incumbent, the walk ABSTAINS (a granted certificate; cell unchanged);
 *   (6) NEGATIVE (disposer, not race): an abstention WITHOUT a searched frontier is REFUSED;
 *   (7) the witnessed rollback restores the incumbent EXACTLY.
 * 99 = pass. */
module corpus_1093

extern @abi(c-msvc-x64) fn fw_init(incumbent: u64) -> i32 from "forked_walk.iii"
extern @abi(c-msvc-x64) fn fw_explore(target: u64) -> u64 from "forked_walk.iii"
extern @abi(c-msvc-x64) fn fw_commit() -> u32 from "forked_walk.iii"
extern @abi(c-msvc-x64) fn fw_cell_value() -> u64 from "forked_walk.iii"
extern @abi(c-msvc-x64) fn fw_best() -> u64 from "forked_walk.iii"
extern @abi(c-msvc-x64) fn cg_cert_abstain(searched: u32, frontier_best: u64, v_incumbent: u64) -> u32 from "commit_gate.iii"

const CG_CERT            : u32 = 99u32
const CG_CERT_UNSEARCHED : u32 = 14u32

fn main() -> u64 {
    /* (1) speculative exploration leaves NO trace */
    fw_init(100u64)
    let v1 : u64 = fw_explore(150u64)
    if v1 != 150u64 { return 1u64 }
    if fw_cell_value() != 100u64 { return 2u64 }

    /* (2) best branch remembered across a fan */
    fw_explore(300u64)
    fw_explore(200u64)
    if fw_best() != 300u64 { return 3u64 }
    if fw_cell_value() != 100u64 { return 4u64 }

    /* (3) disposer commits the winner (strict improvement) */
    if fw_commit() != CG_CERT { return 5u64 }
    if fw_cell_value() != 300u64 { return 6u64 }

    /* (4) path-independence: different order, same winner */
    fw_init(100u64)
    fw_explore(200u64)
    fw_explore(300u64)
    fw_explore(150u64)
    if fw_best() != 300u64 { return 7u64 }
    if fw_commit() != CG_CERT { return 8u64 }
    if fw_cell_value() != 300u64 { return 9u64 }

    /* (5) abstain when nothing beats the incumbent (cell unchanged) */
    fw_init(500u64)
    fw_explore(150u64)
    fw_explore(300u64)
    fw_explore(200u64)
    if fw_commit() != CG_CERT { return 10u64 }
    if fw_cell_value() != 500u64 { return 11u64 }

    /* (6) NEGATIVE: an unsearched abstention is refused (a commit is a disposer decision, not a race) */
    if cg_cert_abstain(0u32, 0u64, 500u64) != CG_CERT_UNSEARCHED { return 12u64 }

    /* (7) witnessed rollback restores the incumbent exactly */
    fw_init(0xDEADBEEFu64)
    fw_explore(0x11111111u64)
    if fw_cell_value() != 0xDEADBEEFu64 { return 13u64 }

    return 99u64
}
```

- [ ] **Step 2: Register the KAT.** In `STDLIB/scripts/run_corpus.sh`, add to `EXPECTED`:

```bash
    [1093_forked_walk]=99
```

- [ ] **Step 3: Run to verify it FAILS (the red).**

Run: `bash STDLIB/scripts/run_corpus.sh 2>&1 | grep 1093_forked_walk`
Expected: `FAIL  1093_forked_walk : link rc=...` (undefined reference to `fw_*` — the module does not
exist yet). Not the `FATAL: no EXPECTED entry` message (that would mean Step 2 was skipped).

---

## Task 2: Create the module `forcefield/forked_walk.iii`

**Files:** Create `STDLIB/iii/forcefield/forked_walk.iii`.

- [ ] **Step 1: Write the module** (complete; no stubs):

```iii
/* STDLIB/iii/forcefield/forked_walk.iii -- Organ E: the Forked Walk.
 *
 * Explore candidate branches speculatively, leave no trace on the ones not taken, and commit the
 * best branch as a DISPOSER decision on value -- never a race. A driver over two built organs:
 *   - numera/reversible (rev_begin/rev_record/rev_rollback/rev_commit): each branch is a
 *     transactional envelope; rev_rollback replays the recorded inverse (WITNESSED) so a loser
 *     leaves the state byte-for-byte unchanged.
 *   - forcefield/commit_gate (cg_cert_action/cg_cert_abstain): the winner is committed iff its value
 *     strictly rises; an abstention must prove the frontier was searched (UNSEARCHED is refused).
 *
 * Path-independent: the walk keeps the strictly-greater value, and on a TIE keeps the smaller target
 * -- both order-free, so the committed winner does not depend on exploration order.
 *
 * SCOPE (honest): this is the sound SEQUENTIAL speculate->dispose->commit core. reversible is
 * single-threaded LIFO (non-reentrant), so true PARALLEL branch exploration is the external
 * worktree/process layer (scripts/ripple_extract.sh + ripple_apply.sh + git worktrees, with this
 * gate as the merge disposer) -- staged, not part of this .iii organ.
 *
 * Hexad: kind_sensitivity (admission).  Ring: R0.  K: 0.99 (envelope/log exhaustion).
 * NIH: composes reversible + commit_gate only.  Determinism: u64 ==/</> + module-scope state.
 */
module forcefield_forked_walk

extern @abi(c-msvc-x64) fn rev_init() -> i32 from "reversible.iii"
extern @abi(c-msvc-x64) fn rev_begin(cap: u64) -> u32 from "reversible.iii"
extern @abi(c-msvc-x64) fn rev_record(slot: u32, tag: u32, a: u64, b: u64) -> i32 from "reversible.iii"
extern @abi(c-msvc-x64) fn rev_rollback(slot: u32) -> i32 from "reversible.iii"
extern @abi(c-msvc-x64) fn rev_commit(slot: u32) -> i32 from "reversible.iii"
extern @abi(c-msvc-x64) fn cg_cert_action(phi_verdict: u32, v_before: u64, v_after: u64, proof_ok: u32) -> u32 from "commit_gate.iii"
extern @abi(c-msvc-x64) fn cg_cert_abstain(searched: u32, frontier_best: u64, v_incumbent: u64) -> u32 from "commit_gate.iii"

const FW_OK                   : i32 = 0i32
const REV_TAG_MEM_RESTORE_U64 : u32 = 2u32      /* reversible's u64 memory-restore undo tag */
const REV_SLOT_NONE           : u32 = 0xFFFFFFFFu32
const CG_ADMIT                : u32 = 99u32      /* commit_gate's all-five-hold verdict      */
const CG_CERT                 : u32 = 99u32      /* commit_gate's granted certificate        */
const FW_CAP                  : u64 = 1u64       /* non-zero cap authorizes the MEM_RESTORE undo */
const FW_E_SLOT               : u32 = 0xFFFFFFFEu32

var FW_CELL      : [u64; 1]    /* the shared state; value = FW_CELL[0]            */
var FW_INCUMBENT : u64 = 0u64  /* the value at walk start                        */
var FW_BEST      : u64 = 0u64  /* best branch value seen                         */
var FW_BEST_TGT  : u64 = 0u64  /* target achieving FW_BEST (smaller wins a tie)  */
var FW_HAVE_BEST : u8  = 0u8
var FW_SEARCHED  : u32 = 0u32

fn fw_cell_value() -> u64 @export { return FW_CELL[0u64] }
fn fw_best() -> u64 @export { return FW_BEST }
fn fw_have_best() -> u8 @export { return FW_HAVE_BEST }

/* Begin a walk from an incumbent state value. */
fn fw_init(incumbent: u64) -> i32 @export {
    rev_init()
    FW_CELL[0u64] = incumbent
    FW_INCUMBENT = incumbent
    FW_BEST = 0u64
    FW_BEST_TGT = 0u64
    FW_HAVE_BEST = 0u8
    FW_SEARCHED = 0u32
    return FW_OK
}

/* Speculatively explore ONE branch: record the inverse, apply the forward mutation, evaluate,
 * remember if best (strict >, ties -> smaller target), then ROLL BACK (witnessed) -- no trace. */
fn fw_explore(target: u64) -> u64 @export {
    let cur : u64 = FW_CELL[0u64]
    let s : u32 = rev_begin(FW_CAP)
    if s == REV_SLOT_NONE { return 0u64 }
    rev_record(s, REV_TAG_MEM_RESTORE_U64, &FW_CELL as u64, cur)
    FW_CELL[0u64] = target
    let v : u64 = FW_CELL[0u64]
    FW_SEARCHED = 1u32
    if FW_HAVE_BEST == 0u8 {
        FW_HAVE_BEST = 1u8
        FW_BEST = v
        FW_BEST_TGT = target
        rev_rollback(s)
        return v
    }
    if v > FW_BEST {
        FW_BEST = v
        FW_BEST_TGT = target
    }
    if v == FW_BEST {
        if target < FW_BEST_TGT { FW_BEST_TGT = target }
    }
    rev_rollback(s)
    return v
}

/* Dispose: commit the best branch IFF it strictly beats the incumbent (a value decision, not a
 * race); else certify abstention (frontier searched, nothing better). Returns CG_CERT (99) on a
 * granted certificate, or the located reject code. */
fn fw_commit() -> u32 @export {
    if FW_HAVE_BEST == 1u8 {
        if FW_BEST > FW_INCUMBENT {
            let cur : u64 = FW_CELL[0u64]
            let s : u32 = rev_begin(FW_CAP)
            if s == REV_SLOT_NONE { return FW_E_SLOT }
            rev_record(s, REV_TAG_MEM_RESTORE_U64, &FW_CELL as u64, cur)
            FW_CELL[0u64] = FW_BEST_TGT
            let cert : u32 = cg_cert_action(CG_ADMIT, FW_INCUMBENT, FW_BEST, 1u32)
            if cert == CG_CERT {
                rev_commit(s)
                return CG_CERT
            }
            rev_rollback(s)
            return cert
        }
    }
    return cg_cert_abstain(FW_SEARCHED, FW_BEST, FW_INCUMBENT)
}
```

- [ ] **Step 2: Compile-only sanity.**

Run: `COMPILED/iiis-2.exe STDLIB/iii/forcefield/forked_walk.iii --compile-only --out /tmp/forked_walk.iii.o`
Expected: exit `0`, no diagnostic. Fix the module if it errors (never the compiler).

---

## Task 3: Wire into the build and rebuild

**Files:** Modify `STDLIB/scripts/build_stdlib.sh` (`MODULES`).

- [ ] **Step 1: Add to `MODULES`.** Insert immediately after the `"forcefield/commit_gate"` line:

```bash
    "forcefield/commit_gate"
    "forcefield/forked_walk"
```

- [ ] **Step 2: Build and verify `FAIL = 0`.**

Run: `bash STDLIB/scripts/build_stdlib.sh 2>&1 | tail -20`
Expected: `FAIL = 0`, `TOTAL = <prev+1>`. If any module FAILs, the archive is STALE — fix before
running the corpus.

---

## Task 4: Run the corpus — `1093 = 99`, zero regression

- [ ] **Step 1:** `bash STDLIB/scripts/run_corpus.sh 2>&1 | tail -8` → `PASS=<baseline+1>  FAIL=0`.
- [ ] **Step 2:** `bash STDLIB/scripts/run_corpus.sh 2>&1 | grep 1093_forked_walk` → `PASS  1093_forked_walk : exit=99`.
- [ ] **Step 3:** Confirm `PASS` is exactly the Step 0.4 baseline `+1` and `FAIL=0`; root-cause any regression (never green-wash).
- [ ] **Step 4: Hand-verify the disposer-not-race core.** Confirm the KAT's check (6): `cg_cert_abstain(searched=0,…)` returned `CG_CERT_UNSEARCHED (14)`, not a grant — a commit/abstain must prove it searched, the property that makes the Forked Walk's selection a disposer decision rather than a race.

---

## Task 5: Commit (GATED — only on explicit user authorization)

The working tree is **mid-reseal**; do **not** sweep those artifacts. Stage only the four organ-E paths.

- [ ] **Step 1 (gated):** `git add STDLIB/iii/forcefield/forked_walk.iii STDLIB/corpus/1093_forked_walk.iii STDLIB/scripts/build_stdlib.sh STDLIB/scripts/run_corpus.sh`
- [ ] **Step 2 (gated): commit:**

```bash
git commit -m "feat(forked_walk): Organ E — the Forked Walk (speculate -> dispose -> commit)

Explore branches speculatively over reversible envelopes; each is rolled back
(witnessed) leaving no trace; the best by value is committed through the
commit_gate disposer (cg_cert_action, strict improvement) or abstains
(cg_cert_abstain, searched frontier). The committed winner is a value decision,
not a race; path-independent (ties -> smaller target). KAT 1093_forked_walk=99;
build_stdlib FAIL=0.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review (run after writing; fixed inline)

- **Spec coverage:** contemplation §2-E (try branches, commit the winner, roll back losers via SID;
  "committed-branch selection must be a *disposer* decision, not a race" — advisor) → covered by
  Task 2 (`fw_explore` speculate+rollback, `fw_commit` via `cg_cert_action`/`cg_cert_abstain`) and KAT
  checks (1)–(7), with (6) being the explicit disposer-not-race negative arm. ✓
- **Placeholder scan:** no TBD/TODO; every code step complete. ✓
- **Type/signature consistency:** the KAT's `extern` signatures for `fw_init/fw_explore/fw_commit/
  fw_cell_value/fw_best` match Task 2 exactly; `rev_init/rev_begin/rev_record/rev_rollback/rev_commit`
  and `cg_cert_action/cg_cert_abstain` match the live `reversible.iii`/`commit_gate.iii` read during
  planning; `REV_TAG_MEM_RESTORE_U64=2`, `CG_ADMIT=CG_CERT=99`, `CG_CERT_UNSEARCHED=14` match source. ✓
- **Residual risk:** `cg_cert_action`'s `proof_ok` is passed `1u32` (the value-improvement *is* the
  proof here). A future organ that carries a real preservation proof should thread it through; for the
  Forked Walk's value-only selection, `1u32` is correct and the strict-`>` check is the teeth.

## Out of scope (the parallel fan-out — staged, not deferred)
True **parallel** branch exploration (many git worktrees each exploring a branch concurrently, merged
by this gate) is the external process layer — `scripts/ripple_extract.sh` + `ripple_apply.sh` + git
worktrees, with `commit_gate`/`fw_commit` as the merge disposer. This plan delivers the sound
*sequential* core (speculate → witnessed-rollback → disposer-commit) that the fan-out orchestrates;
`reversible` is single-threaded LIFO, so the parallelism cannot live inside the `.iii` substrate.
