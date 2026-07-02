# Organ C — the Witnessed Sense (`sanctus/observe`) Implementation Plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> **✅ IMPLEMENTED + GREEN (2026-06-04):** built, gated, verified on metal — KAT exit **99**.
> As-built corpus id is **1100** (`1100_obs_witnessed`, module `corpus_1100`) — renumbered from
> the planned 1092 because the mid-reseal WIP had taken 1092 (`gate_cp1_guard`). `build_stdlib`
> GATE PASS **459/0**; `sanctus/observe.iii` + the KAT exist; uncommitted (commit gated). The code
> blocks below use the original 1092 — substitute **1100**.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement
> this plan task-by-task. (NOT subagent-driven — III has a standing no-subagents rule; execute
> inline in the main session.) Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Admit live nondeterminism into III through a witnessed boundary — every nondeterministic
observation (a clock reading, an RNG draw, a network/sensor byte) is recorded as a witness fragment
so the run is nondeterministic *live* but bit-identical *on replay*.

**Architecture:** A thin module `sanctus/observe.iii` sits *over* the existing `aether/witness_hook.iii`.
In LIVE mode `obs_observe` publishes the observed value as a fragment payload (content-address in
`out_commit`, a reserved `opid` tag marking the fragment KIND = `NONDET_OBSERVE` — the read-dual of
the 17 witnessed IRPD privileged writes) and passes the value through to the caller. In REPLAY mode it
re-injects the recorded payload via `wh_get_payload` and ignores the live world. An observation that
cannot be witnessed (bad length / spine full) returns a sentinel and writes nothing — the new
bricking-class (`@safety(UNREPLAYABLE)` made executable).

**Tech Stack:** III (`.iii`), compiled by the pinned `COMPILED/iiis-2.exe`; built into
`libiii_native.a` by `STDLIB/scripts/build_stdlib.sh`; tested by the corpus KAT harness
`STDLIB/scripts/run_corpus.sh`. Dependencies (all built + corpus-green today): `aether/witness_hook`
(`382_witness_hook`, `988_witness_redact`), `keccak256`, `numera/algebraic_time` (`381_algebraic_time`).

---

## How III "tests" work (read this first — the toolchain is not pytest)

- A **unit test is a corpus KAT**: a file `STDLIB/corpus/NNNN_name.iii` whose `fn main() -> u64`
  returns **`99` on pass** and a distinct small code (`1`, `2`, …) at the first failing assertion.
  It is registered in `run_corpus.sh`'s `EXPECTED` table as `[NNNN_name]=99`. A KAT with **no**
  `EXPECTED` entry is a **FATAL** harness error (by design — no silent miscount).
- **Build:** `bash STDLIB/scripts/build_stdlib.sh`. This compiles every module in the `MODULES`
  array into `libiii_native.a`. **A failed module leaves the archive STALE → later tests
  false-pass.** Always confirm the run prints **`FAIL = 0`** (grep for it); never trust a green
  corpus after a build you didn't verify ended `FAIL = 0`.
- **Run:** `bash STDLIB/scripts/run_corpus.sh`. Each KAT is compiled (`iiis --compile-only`),
  linked against `libiii_native.a`, run staged in `/tmp`, and its exit code compared to `EXPECTED`.
  The script's exit code **is the FAIL count**. Look for `PASS  1092_obs_witnessed : exit=99`.
- **Compiler is pinned:** the harness uses `COMPILED/iiis-2.exe`. Do **not** set `IIIS=` to any
  other binary (a stale external compiler silently measures against the wrong grammar → phantom
  regressions).
- **Determinism gate / reseal:** organ C is a **stdlib** module the **compiler never references**.
  Per ADR-027 discipline, a compiler-unreferenced `libiii_native.a` addition **does not drift**
  the `iiis-1`/`iiis-2` seed, so **no reseal is required**. The gate for this work is exactly:
  `build_stdlib` ends `FAIL = 0`, `1092_obs_witnessed = 99`, and **no other corpus entry regresses**.
  (Belt-and-braces optional: run the seal-gated `COMPILER/BOOT/build_iiis2.sh` and let the DRIFT
  gate confirm a no-op. Not required; do not reseal by hand.)

### iiis idiom rules this plan obeys (from the live codebase + CLAUDE.md trap list)
- **Module-scope arrays only** for anything indexed by a runtime/loop variable (a *function-local*
  `var [T;N]` indexed by a runtime index segfaults). All buffers below are module-scope `OBS_*`.
- **`u64`/`u32` + equality only.** No signed-`i64` ordering compares (`< <= > >=` on a possibly
  negative `i64` compile *unsigned*). All comparisons here are `==`/`!=` or `u64`/`u32` ordering.
- **Address-of idiom:** `&ARR as *u8` and `&ARR as u64` (exactly as `988_witness_redact.iii` uses).
- No `i64` literal immediately before `{`. No `%`/`/` after a call. None occur here.

---

## File structure

| Action | File | Responsibility |
|--------|------|----------------|
| **CREATE** | `STDLIB/iii/sanctus/observe.iii` | the Witnessed Sense: `obs_observe` (LIVE record+passthrough / REPLAY re-inject), mode, accessors |
| **CREATE** | `STDLIB/corpus/1092_obs_witnessed.iii` | the falsifier KAT (drives the module's public API; `main → 99`) |
| **MODIFY** | `STDLIB/scripts/build_stdlib.sh` | add `"sanctus/observe"` to `MODULES` immediately after `"aether/witness_hook"` |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[1092_obs_witnessed]=99` to the `EXPECTED` table |

---

## ADR-1 — `NONDET_OBSERVE` is one new fragment KIND over `witness_hook`, not new substrate

`aether/witness_hook.iii` already **records a value and produces its content-address in one act**:
`wh_publish(... payload, payload_len, out_frag_id)` stores the payload (recoverable via
`wh_get_payload`) and returns a monotonic fragment index (or `0xFFFF…FF` when the 1 048 576-fragment
spine is full). Therefore organ C adds **no new storage and no new replay machinery**:

- **KIND marker.** The fragment's `opid` is a reserved 32-byte tag (`byte0 = 0x0B`) marking
  `NONDET_OBSERVE`. This mirrors `sanctus/witness.iii`'s distinguished `cap_id` ranges
  (`0xFFFFFF00` ripple, `0xFFFFFE00` resolve): a verifier classifies the witness *kind* by the tag
  without parsing the body.
- **Content-address.** The observed value's `keccak256` goes in `out_commit` (recoverable via
  `wh_get_out_commit`). (`frag_id` itself is `keccak256` over *all* fields, so the value's own
  address must be carried explicitly in `out_commit`.)
- **Replay log = the spine.** LIVE records the frag index in an in-order list `OBS_IDX`; REPLAY walks
  that list and re-injects each recorded payload with `wh_get_payload`, ignoring the live argument.
- **The bricking-class.** If the value cannot be witnessed (`len == 0`, `len > OBS_MAX_LEN`, list
  full, or `wh_publish` fails), `obs_observe` returns `OBS_SENTINEL` and **writes nothing** to the
  caller's out buffer. An unwitnessable observation never passes a value through.

**Single falsifier:** `1092_obs_witnessed ≠ 99` — a decoy live value leaking through replay, a
missing/incorrect content-address, replay past the record not refused, or an unwitnessable
observation writing a value.

---

## Step 0 — Pre-flight (read-only, no edits)

- [ ] **0.1 Prefix is free.** Run: `grep -rn "module sanctus_observe\|fn obs_observe\|OBS_SENTINEL" STDLIB/iii` — expect **no matches**.
- [ ] **0.2 Corpus id is free.** Run: `grep -n "1092_" STDLIB/scripts/run_corpus.sh` — expect **no matches** (next free id is 1092; current max is 1091).
- [ ] **0.3 Externs exist.** Confirm signatures in the live source (used verbatim below):
  - `grep -n "fn wh_publish\|fn wh_get_payload\|fn wh_get_out_commit\|fn wh_init" STDLIB/iii/aether/witness_hook.iii`
  - `grep -n "fn keccak256_oneshot" STDLIB/iii/*/keccak256.iii`
  - `grep -n "fn at_current" STDLIB/iii/numera/algebraic_time.iii`
- [ ] **0.4 Baseline.** Run `bash STDLIB/scripts/build_stdlib.sh` and confirm it ends `FAIL = 0`; then `bash STDLIB/scripts/run_corpus.sh` and record `PASS=<N> FAIL=0`. This `N` is the regression baseline; after this plan it must be `N+1`.

---

## Task 1: Failing KAT — register `1092_obs_witnessed` and watch it fail to link

**Files:**
- Create: `STDLIB/corpus/1092_obs_witnessed.iii`
- Modify: `STDLIB/scripts/run_corpus.sh` (add the `EXPECTED` entry)

- [ ] **Step 1: Write the KAT** (`STDLIB/corpus/1092_obs_witnessed.iii`)

```iii
/* 1092_obs_witnessed.iii — falsifier for Organ C (sanctus/observe, the Witnessed Sense).
 * Proves the boundary is sound:
 *   (1) LIVE passes the observed value through AND returns a real handle;
 *   (2) the witness is content-addressed to the value (out_commit == keccak256(value));
 *   (2b) each witnessed observation advances algebraic time;
 *   (3) REPLAY re-injects the RECORDED value and IGNORES a decoy live value (no leak);
 *   (4) replay past the recorded set is REFUSED (the divergence guard);
 *   (5) an unwitnessable observation (len 0) is REFUSED and writes NOTHING.
 * Drives DIFFERENT values live vs replay so the re-injection cannot be faked by reading
 * the world (no-tautological-proof). 99 = pass. */
module corpus_1092

extern @abi(c-msvc-x64) fn obs_init() -> i32 from "observe.iii"
extern @abi(c-msvc-x64) fn obs_set_mode(m: u8) -> i32 from "observe.iii"
extern @abi(c-msvc-x64) fn obs_count() -> u64 from "observe.iii"
extern @abi(c-msvc-x64) fn obs_observe(source_id: u32, live_ptr: *u8, len: u32, out_ptr: *u8) -> u64 from "observe.iii"
extern @abi(c-msvc-x64) fn obs_commit_of(k: u64, out: *u8) -> i32 from "observe.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"

const OBS_MODE_REPLAY : u8  = 1u8
const OBS_SENTINEL    : u64 = 0xFFFFFFFFFFFFFFFFu64

var VX   : [u8; 8]    /* observed value #1                         */
var VX2  : [u8; 8]    /* observed value #2                         */
var VY   : [u8; 8]    /* decoy live value for replay (must NOT leak) */
var VOUT : [u8; 8]    /* passthrough / re-injection sink           */
var REF  : [u8; 32]   /* keccak256(VX) reference commitment        */
var GOT  : [u8; 32]   /* recorded out_commit                       */

fn fill8(p: u64, b: u8) -> i32 {
    let q : *u8 = p as *u8
    let mut i : u64 = 0u64
    while i < 8u64 { q[i] = b  i = i + 1u64 }
    return 0i32
}

fn eq8(a: u64, b: u64) -> u8 {
    let pa : *u8 = a as *u8
    let pb : *u8 = b as *u8
    let mut i : u64 = 0u64
    while i < 8u64 { if pa[i] != pb[i] { return 0u8 }  i = i + 1u64 }
    return 1u8
}

fn main() -> u64 {
    obs_init()
    let mut i : u64 = 0u64
    while i < 8u64 {
        VX[i]  = 0x41u8 + (i as u8)
        VX2[i] = 0x51u8 + (i as u8)
        VY[i]  = 0x99u8
        i = i + 1u64
    }

    /* (1) LIVE observe #1 -> valid handle + passthrough */
    fill8(&VOUT as u64, 0xEEu8)
    let h1 : u64 = obs_observe(7u32, &VX as *u8, 8u32, &VOUT as *u8)
    if h1 == OBS_SENTINEL { return 1u64 }
    if eq8(&VOUT as u64, &VX as u64) != 1u8 { return 2u64 }

    /* (2) content-address: recorded out_commit == keccak256(VX) */
    keccak256_oneshot(&VX as u64, 8u64, &REF as u64)
    obs_commit_of(0u64, &GOT as *u8)
    i = 0u64
    while i < 32u64 { if GOT[i] != REF[i] { return 3u64 }  i = i + 1u64 }

    /* (2b) the witnessed observation advanced algebraic time */
    let t_before : u64 = at_current()
    fill8(&VOUT as u64, 0xEEu8)
    let h2 : u64 = obs_observe(7u32, &VX2 as *u8, 8u32, &VOUT as *u8)
    if h2 == OBS_SENTINEL { return 4u64 }
    if at_current() == t_before { return 5u64 }
    if obs_count() != 2u64 { return 6u64 }

    /* (3) REPLAY re-injects the RECORDED value, ignoring the decoy VY */
    obs_set_mode(OBS_MODE_REPLAY)
    fill8(&VOUT as u64, 0xEEu8)
    let r1 : u64 = obs_observe(7u32, &VY as *u8, 8u32, &VOUT as *u8)
    if r1 == OBS_SENTINEL { return 7u64 }
    if eq8(&VOUT as u64, &VX as u64) != 1u8 { return 8u64 }
    if eq8(&VOUT as u64, &VY as u64) == 1u8 { return 9u64 }

    fill8(&VOUT as u64, 0xEEu8)
    let r2 : u64 = obs_observe(7u32, &VY as *u8, 8u32, &VOUT as *u8)
    if r2 == OBS_SENTINEL { return 10u64 }
    if eq8(&VOUT as u64, &VX2 as u64) != 1u8 { return 11u64 }

    /* (4) replay past the record is refused */
    let r3 : u64 = obs_observe(7u32, &VY as *u8, 8u32, &VOUT as *u8)
    if r3 != OBS_SENTINEL { return 12u64 }

    /* (5) bricking-class: unwitnessable (len 0) LIVE observation refused, nothing written */
    obs_init()
    fill8(&VOUT as u64, 0xEEu8)
    let bad : u64 = obs_observe(7u32, &VX as *u8, 0u32, &VOUT as *u8)
    if bad != OBS_SENTINEL { return 13u64 }
    i = 0u64
    while i < 8u64 { if VOUT[i] != 0xEEu8 { return 14u64 }  i = i + 1u64 }

    return 99u64
}
```

- [ ] **Step 2: Register the KAT.** In `STDLIB/scripts/run_corpus.sh`, add to the `EXPECTED=( … )` table (next to `[1091_ripple_synthesizer]=99`):

```bash
    [1092_obs_witnessed]=99
```

- [ ] **Step 3: Run to verify it FAILS (the red).**

Run: `bash STDLIB/scripts/run_corpus.sh 2>&1 | grep 1092_obs_witnessed`
Expected: `FAIL  1092_obs_witnessed : link rc=...` (undefined reference to `obs_init`/`obs_observe`/… — the module does not exist yet). This is the correct failing state; do **not** proceed if it instead reports `FATAL: no EXPECTED entry` (Step 2 was skipped).

---

## Task 2: Create the module `sanctus/observe.iii`

**Files:**
- Create: `STDLIB/iii/sanctus/observe.iii`

- [ ] **Step 1: Write the module** (complete; no stubs):

```iii
/* STDLIB/iii/sanctus/observe.iii — Organ C: the Witnessed Sense.
 *
 * Live nondeterminism in, determinism on replay. Every nondeterministic observation (a clock
 * reading, an RNG draw, a network/sensor byte) is published as a witness FRAGMENT via wh_publish:
 * the observed value is the fragment payload, its content-address is out_commit, and a reserved
 * opid tag marks the fragment KIND = NONDET_OBSERVE (the read-dual of the 17 IRPD privileged
 * writes). The spine IS the replay log: LIVE passes the value through AND records it; REPLAY
 * re-injects the recorded payload (wh_get_payload) and ignores the live world, so a replay of a
 * nondeterministic run is bit-identical.
 *
 * The new bricking-class: an observation that CANNOT be witnessed (len 0, len > OBS_MAX_LEN,
 * list full, publish failure) returns OBS_SENTINEL and writes NOTHING to the caller's out buffer.
 * (@safety(UNREPLAYABLE) made executable.)
 *
 * Hexad: kind_witness.  Ring: R-1.  K: 1.00.  NIH: witness_hook + keccak256.
 * Discipline: module-scope arrays (W8 bounded); u64/u32 + equality only; single writer; no recursion.
 */
module sanctus_observe

extern @abi(c-msvc-x64) fn wh_init(initial_time: u64) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_payload(idx: u64, out_buf: *u8, max_len: u64, out_len: *u64) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_out_commit(idx: u64, out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"

const OBS_OK          : i32 = 0i32
const OBS_MODE_LIVE   : u8  = 0u8
const OBS_MODE_REPLAY : u8  = 1u8
const OBS_SENTINEL    : u64 = 0xFFFFFFFFFFFFFFFFu64
const OBS_MAX_LEN     : u32 = 4096u32
const OBS_CAP         : u64 = 65536u64

var OBS_OPID    : [u8; 32]      /* KIND tag: byte0 = 0x0B (NONDET_OBSERVE)  */
var OBS_PROD    : [u8; 32]      /* producer = source_id (low 4 bytes)        */
var OBS_INCOM   : [u8; 32]      /* zero in-commit                            */
var OBS_ANTE    : [u8; 32]      /* zero antecedents (n_ante = 0)             */
var OBS_COMMIT  : [u8; 32]      /* content-address of the observed value     */
var OBS_FRAG    : [u8; 32]      /* frag-id sink                              */
var OBS_SCRATCH : [u8; 4096]    /* the observed value (witnessed + passed through) */
var OBS_IDX     : [u64; 65536]  /* frag indices of observations, in order    */
var OBS_OUTLEN  : [u64; 1]      /* wh_get_payload out_len sink               */
var OBS_N       : u64 = 0u64    /* count recorded (LIVE)                     */
var OBS_CURSOR  : u64 = 0u64    /* next observation to re-inject (REPLAY)    */
var OBS_MODE    : u8  = 0u8

fn obs_zero32(p: u64) -> i32 {
    let b : *u8 = p as *u8
    let mut i : u64 = 0u64
    while i < 32u64 { b[i] = 0u8  i = i + 1u64 }
    return 0i32
}

fn obs_copy(dst: u64, src: u64, len: u32) -> i32 {
    let d : *u8 = dst as *u8
    let s : *u8 = src as *u8
    let n : u64 = len as u64
    let mut i : u64 = 0u64
    while i < n { d[i] = s[i]  i = i + 1u64 }
    return 0i32
}

fn obs_init() -> i32 @export {
    wh_init(0u64)
    obs_zero32(&OBS_OPID as u64)
    OBS_OPID[0u64] = 0x0Bu8
    obs_zero32(&OBS_PROD as u64)
    obs_zero32(&OBS_INCOM as u64)
    obs_zero32(&OBS_ANTE as u64)
    OBS_N = 0u64
    OBS_CURSOR = 0u64
    OBS_MODE = OBS_MODE_LIVE
    return OBS_OK
}

fn obs_set_mode(m: u8) -> i32 @export {
    OBS_MODE = m
    if m == OBS_MODE_REPLAY { OBS_CURSOR = 0u64 }
    return OBS_OK
}

fn obs_mode() -> u8 @export { return OBS_MODE }
fn obs_count() -> u64 @export { return OBS_N }

/* The witnessed sense. Returns the observation handle (frag idx) or OBS_SENTINEL. */
fn obs_observe(source_id: u32, live_ptr: *u8, len: u32, out_ptr: *u8) -> u64 @export {
    if OBS_MODE == OBS_MODE_REPLAY {
        if OBS_CURSOR >= OBS_N { return OBS_SENTINEL }              /* replay diverged */
        let idx : u64 = OBS_IDX[OBS_CURSOR]
        let gp : i32 = wh_get_payload(idx, out_ptr, len as u64, &OBS_OUTLEN as *u64)
        if gp != OBS_OK { return OBS_SENTINEL }
        if OBS_OUTLEN[0u64] != (len as u64) { return OBS_SENTINEL } /* shape mismatch */
        OBS_CURSOR = OBS_CURSOR + 1u64
        return idx
    }
    /* LIVE: refuse the unwitnessable BEFORE touching out_ptr (bricking-class). */
    if len == 0u32 { return OBS_SENTINEL }
    if len > OBS_MAX_LEN { return OBS_SENTINEL }
    if OBS_N >= OBS_CAP { return OBS_SENTINEL }
    obs_copy(&OBS_SCRATCH as u64, live_ptr as u64, len)
    keccak256_oneshot(&OBS_SCRATCH as u64, len as u64, &OBS_COMMIT as u64)
    obs_zero32(&OBS_PROD as u64)
    OBS_PROD[0u64] = (source_id & 0xFFu32) as u8
    OBS_PROD[1u64] = ((source_id >> 8u32) & 0xFFu32) as u8
    OBS_PROD[2u64] = ((source_id >> 16u32) & 0xFFu32) as u8
    OBS_PROD[3u64] = ((source_id >> 24u32) & 0xFFu32) as u8
    let idx : u64 = wh_publish(&OBS_PROD as *u8, &OBS_OPID as *u8, &OBS_INCOM as *u8, &OBS_COMMIT as *u8, 0u8, 0u8, 0u16, &OBS_ANTE as *u8, 0u32, &OBS_SCRATCH as *u8, len, &OBS_FRAG as *u8)
    if idx == OBS_SENTINEL { return OBS_SENTINEL }                  /* spine full: refuse */
    OBS_IDX[OBS_N] = idx
    OBS_N = OBS_N + 1u64
    obs_copy(out_ptr as u64, &OBS_SCRATCH as u64, len)             /* pass through only after witnessed */
    return idx
}

/* The recorded content-address (out_commit) of the k-th observation. */
fn obs_commit_of(k: u64, out: *u8) -> i32 @export {
    if k >= OBS_N { return -1i32 }
    return wh_get_out_commit(OBS_IDX[k], out)
}
```

- [ ] **Step 2: Compile-only sanity** (catches syntax/trap issues before the full build).

Run: `COMPILED/iiis-2.exe STDLIB/iii/sanctus/observe.iii --compile-only --out /tmp/observe.iii.o`
Expected: exit `0`, no diagnostic. If it errors, fix the module (do **not** edit the compiler).

---

## Task 3: Wire the module into the build and rebuild

**Files:**
- Modify: `STDLIB/scripts/build_stdlib.sh` (the `MODULES` array)

- [ ] **Step 1: Add the module to `MODULES`.** Insert immediately after the `"aether/witness_hook"` line:

```bash
    "aether/witness_hook"
    "sanctus/observe"
```

- [ ] **Step 2: Build and verify `FAIL = 0`.**

Run: `bash STDLIB/scripts/build_stdlib.sh 2>&1 | tail -20`
Expected: the summary line shows `FAIL = 0` and `TOTAL = <prev+1>`. If any module shows FAIL, the
archive is now STALE — fix the cause before running the corpus (a green corpus over a stale archive
is a false pass).

---

## Task 4: Run the corpus — `1092 = 99`, zero regression (the green)

- [ ] **Step 1: Run the full corpus.**

Run: `bash STDLIB/scripts/run_corpus.sh 2>&1 | tail -8`
Expected: `PASS=<baseline+1>  FAIL=0  SKIP=...`

- [ ] **Step 2: Confirm the new KAT specifically.**

Run: `bash STDLIB/scripts/run_corpus.sh 2>&1 | grep 1092_obs_witnessed`
Expected: `PASS  1092_obs_witnessed : exit=99`

- [ ] **Step 3: Confirm no regression.** The `PASS` count must be exactly the Step 0.4 baseline `+1`
  and `FAIL=0`. If any previously-passing entry now fails, stop and root-cause (do not green-wash).

- [ ] **Step 4: Hand-verify the soundness core.** Read the `1092` log's exit was `99`, then sanity-read
  the KAT's step (3): replay returned `VX`/`VX2` while the live arg was the decoy `VY`. This is the
  organ's whole claim — replay re-injects the witnessed value, not the world.

---

## Task 5: Commit (GATED — only on explicit user authorization)

The working tree is **mid-reseal** (many modified `COMPILED/` + `COMPILER/BOOT/` artifacts). Do **not**
sweep those into a commit. Commit **only** the four organ-C paths, and **only** when the user says to.

- [ ] **Step 1 (gated): stage exactly the organ-C files.**

```bash
git add STDLIB/iii/sanctus/observe.iii STDLIB/corpus/1092_obs_witnessed.iii STDLIB/scripts/build_stdlib.sh STDLIB/scripts/run_corpus.sh
```

- [ ] **Step 2 (gated): commit.**

```bash
git commit -m "feat(observe): Organ C — the Witnessed Sense (NONDET_OBSERVE over witness_hook)

Live nondeterminism in, deterministic replay out: obs_observe records each
observation as a witness fragment (value=payload, content-address=out_commit,
opid tag = NONDET_OBSERVE) and passes it through in LIVE mode; REPLAY re-injects
the recorded payload and ignores the live world. Unwitnessable observations are
refused (the bricking-class). KAT 1092_obs_witnessed=99; build_stdlib FAIL=0.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review (run after writing; fixed inline)

- **Spec coverage:** contemplation §2-C claims (NONDET_OBSERVE = read-dual of IRPD writes; live/replay;
  auditability strengthened; bricking-class for unwitnessable) → covered by Task 2 (`obs_observe`
  LIVE/REPLAY + sentinel) and Task 1 KAT assertions (1)–(5). ✓
- **Placeholder scan:** no TBD/TODO; every code step is complete `.iii`. ✓
- **Type/signature consistency:** the KAT's `extern` signatures for `obs_init/obs_set_mode/obs_count/
  obs_observe/obs_commit_of` match Task 2's definitions exactly; `wh_publish/wh_get_payload/
  wh_get_out_commit/wh_init/keccak256_oneshot` match the live `witness_hook.iii`/`keccak256.iii`
  signatures read during planning. `OBS_SENTINEL` is identical (`0xFFFFFFFFFFFFFFFFu64`) in module and KAT. ✓
- **`out_commit` round-trip verified (not assumed):** `wh_publish` stores `out_commit` verbatim
  (`witness_hook.iii:173`) and `wh_get_out_commit` returns it verbatim (`:270`), so KAT check (2) —
  recorded commit == `keccak256(value)` — is sound. `wh_publish`'s sentinel return covers all four
  failure modes (un-inited, spine full, >32 antecedents, payload-area overflow), so the bricking-class
  guard is complete; `at_advance()` fires once per publish (`:174`), so check (2b) holds. ✓
- **Known residual risk:** `wh_publish` advances algebraic time internally; the KAT's (2b) assumes at
  least one advance per publish — robust (it checks "moved", not a specific delta). If a future
  `witness_hook` change stops advancing time, (2b) reddens — a *correct* signal, not a flake.

## Out of scope (the wider Witnessed Sense — staged, not deferred)
Cross-run replay (re-running a program against a *prior* run's persisted spine via `witness_hook`'s
PFS rotation), a witnessed wall-clock/RNG `tempora`/`xoshiro` adapter, and the reactive event loop are
**follow-on** work: this plan delivers the sound *primitive* (record + re-inject + refuse), which is the
load-bearing core every reactive use builds on. Organ D (distributed/consensus) depends on this module.
