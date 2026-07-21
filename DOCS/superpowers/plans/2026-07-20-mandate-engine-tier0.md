# Mandate Engine — Tier 0 Implementation Plan

> **EXECUTED 2026-07-21** (commits `e79d2ed2` DOKIMASIA, `9486d0fd` PRAXIS, + the binding).
> Adaptations forced by drift, recorded honestly: (1) plan arms 31-33 were taken by the grace
> arms — DOKIMASIA landed as arms **95/96/97**, wired as `rD` with cascade century **1200**;
> (2) the trace is keyed by **session_id**, not date — hooks are project-scoped, and a shared
> day-trace would let one session's green gate license another session's claim (the recorded
> cross-session disqualifier from the collaborator-gate rounds); (3) the judge carries all three
> ralph-loop guard properties — session isolation, fail-open on every anomaly, and a refusal
> ceiling of 3 that fails OPEN with a named override — because the runtime has **no built-in
> Stop-loop guard** (verified from production records); (4) `.claude/settings.json` is wired
> live but NOT committed — the tree's `.gitignore` line 4 deliberately excludes `.claude/`;
> (5) the gate_green pin demands the gate's own uppercase GREEN marker AND no nonzero
> `GATE_EXIT=` in the observed output — a RED gate cannot pin.

> **For agentic workers:** Use `superpowers:executing-plans` to implement this task-by-task.
> **Subagent-driven execution is BARRED for this plan** — the recorded project law is *no subagents on III*.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make process compliance refusable — a completion claim that the witnessed trace does not
determine is REFUSED by III, mechanically, at the moment the agent tries to stop.

**Architecture:** Three stones. (1) ONTOS gains the *evidential-mass meter* — an oracle whose verdict-map
carries 0 bits is a rubber stamp and is inadmissible as evidence. (2) PRAXIS wraps `exec_cert` (tamper-evident
O(1)/event fold) and `eidolos` (directed entailment closure) into a trace whose claims are judged by
`eol_judge_claim` — in-fold = stands, defect = refused. (3) Harness hooks bind it: the hook (never the agent)
authors pins, and the `Stop` hook refuses completion that the trace does not determine.

**Tech Stack:** `.iii` compiled by in-tree `COMPILED/iiis-2.exe`; bash gates; Claude Code hooks in
`.claude/settings.json`.

## Global Constraints

- Compiler is `COMPILED/iiis-2.exe` (`iii.exe` is the CLI, not the compiler).
- Every new `@export` must arrive with an arm that consumes it (RATCHET-DELTA-ZERO), or be cut.
- Library organs carry NO `main`; a `*_cli` module carries it.
- Reserved words: `any`, `from`, `mut` (as identifiers). Hoist large/FFI-addressed arrays to module `var`.
- Gates must be byte-deterministic across two runs.
- Fresh `isub.o` before archiving; `rm` before relink (OneDrive lock).
- **The agent may append claims; only the harness may append pins.**

**Scope:** Tier 0 only. Tiers 1–3 (DOKIMASIA corpus, HOROS, METRON, PHRONESIS, mandate-learning via
`governance.iii`) are separate subsystems and get their own plans. See
`DOCS/superpowers/specs/2026-07-20-kanon-mandate-engine-design.md`.

---

### Task 1: The evidential-mass meter (anti-sycophancy, measured)

**Files:**
- Modify: `STDLIB/iii/omnia/ontos.iii` (add exports after `ont_log2` at :247; add arm fn before `ont_show`; wire `main` at :656)
- Modify: `STDLIB/scripts/ontos_gate.sh` (expect the new arm line)

**Interfaces:**
- Consumes: internal `ont_image(size: u64) -> u64` (:172), `ont_log2(v: u64) -> u64` (:247), `ont_stand(s: u64) -> u64` (:282), module var `ONT_TBL : [u64; 256]`
- Produces: `ont_tbl_set(i: u64, v: u64) -> i32`, `ont_image_ext(size: u64) -> u64`, `ont_verdict_bits(size: u64) -> u64`, `ont_admissible(size: u64) -> u64`, `ontos_dokimasia_selfprove() -> u64`

- [x] **Step 1: Verify `ont_image` resets its seen-set**

Run: `sed -n '172,188p' STDLIB/iii/omnia/ontos.iii`

Expected: the body begins by zeroing `ONT_SEEN` (a `while i < 4u64 { ONT_SEEN[i] = 0u64 ... }` loop).
If it does NOT reset, add that loop as the first statement of `ont_image` — without it, a second
measurement inherits the first one's bits and every arm below is meaningless.

- [x] **Step 2: Write the failing arm**

Insert immediately before `fn ont_show()` in `STDLIB/iii/omnia/ontos.iii`:

```
/* ============ DOKIMASIA: the assay of an oracle, BEFORE it may serve as evidence ============
 * A verdict-map that answers the same thing to every probe has image 1 -> log2(1) = 0 bits -> its verdict
 * is INDEPENDENT of its input and carries no information about the claim. Such an oracle is a rubber
 * stamp, and it is refused as evidence by the same law that refuses being-from-nothing. This is
 * anti-sycophancy MEASURED, not hoped for: the probe set must contain known-bad mutants, and the oracle
 * must be shown to SEPARATE them. Symmetric by construction -- a constant REFUSER is equally empty. */
fn ontos_dokimasia_selfprove() -> u64 @export {
    /* ARM 31: THE RUBBER STAMP -- "pass" to all 8 probes (4 sound, 4 known-bad) -> image 1 -> 0 bits. */
    let mut i : u64 = 0u64
    while i < 8u64 { ont_tbl_set(i, 1u64)   i = i + 1u64 }
    if ont_image_ext(8u64) != 1u64 { return 31u64 }
    if ont_verdict_bits(8u64) != 0u64 { return 31u64 }
    if ont_admissible(8u64) != 0u64 { return 31u64 }
    if ont_stand("[verdict < probe]" as u64) != 0u64 { return 31u64 }

    /* ARM 32: THE SEPARATOR -- passes the 4 sound, fails the 4 mutants -> image 2 -> 1 bit -> ADMISSIBLE.
     * One honest bit is the minimum evidential mass an oracle may carry and still be heard. */
    let mut j : u64 = 0u64
    while j < 8u64 {
        if j < 4u64 { ont_tbl_set(j, 1u64) } else { ont_tbl_set(j, 0u64) }
        j = j + 1u64
    }
    if ont_image_ext(8u64) != 2u64 { return 32u64 }
    if ont_verdict_bits(8u64) != 1u64 { return 32u64 }
    if ont_admissible(8u64) != 1u64 { return 32u64 }

    /* ARM 33: THE CONSTANT REFUSER is ALSO a rubber stamp -- always-"fail" carries exactly as many bits
     * as always-"pass": zero. A pessimist oracle is no more admissible than a sycophant, and a mandate
     * engine that forgot this would be gamed by a trivially strict verifier. */
    let mut k : u64 = 0u64
    while k < 8u64 { ont_tbl_set(k, 0u64)   k = k + 1u64 }
    if ont_image_ext(8u64) != 1u64 { return 33u64 }
    if ont_admissible(8u64) != 0u64 { return 33u64 }

    return 0u64
}
```

- [x] **Step 3: Run the gate to verify it FAILS (exports do not exist yet)**

Run: `bash STDLIB/scripts/ontos_gate.sh 2>&1 | tail -5; echo "exit=$?"`
Expected: compile failure naming `ont_tbl_set` / `ont_image_ext` / `ont_verdict_bits` / `ont_admissible` as unknown.

- [x] **Step 4: Add the four exports**

Insert immediately after `ont_log2` (line 247) in `STDLIB/iii/omnia/ontos.iii`:

```
/* the probe set's verdicts, written from outside: ONT_TBL[i] = the oracle's answer to probe i */
fn ont_tbl_set(i: u64, v: u64) -> i32 @export { if i < 256u64 { ONT_TBL[i] = v }   return 0i32 }
/* how many DISTINCT verdicts the oracle produced across the probe set */
fn ont_image_ext(size: u64) -> u64 @export { return ont_image(size) }
/* the oracle's evidential mass, in bits: log2 of its verdict image */
fn ont_verdict_bits(size: u64) -> u64 @export { return ont_log2(ont_image(size)) }
/* THE ASSAY: may this oracle be heard as evidence at all? 0 bits = rubber stamp = REFUSED */
fn ont_admissible(size: u64) -> u64 @export { if ont_log2(ont_image(size)) >= 1u64 { return 1u64 }   return 0u64 }
```

- [x] **Step 5: Wire the arm into `main`**

In `fn main` (:656), after the `r6` line, add:

```
    let r7 : u64 = ontos_dokimasia_selfprove()
```

and after the `ontos_grace_selfprove = ` print line, add:

```
    ps("ontos_dokimasia_selfprove = " as u64)   pu(r7)   putchar(10i32)
```

and extend the final `bad` cascade so `r7` maps to `600u64 + r7` (follow the existing nesting style exactly).

- [x] **Step 6: Run the gate to verify it PASSES**

Run: `bash STDLIB/scripts/ontos_gate.sh 2>&1 | tail -12; echo "exit=$?"`
Expected: `ontos_dokimasia_selfprove = 0`, GREEN line, `exit=0`.

- [x] **Step 7: Commit**

```bash
git add STDLIB/iii/omnia/ontos.iii STDLIB/scripts/ontos_gate.sh
git commit -m "DOKIMASIA: an oracle's verdict-map must carry bits before it may serve as evidence"
```

---

### Task 2: PRAXIS — the pinned trace, and the claim it must determine

**Files:**
- Create: `STDLIB/iii/omnia/praxis.iii`
- Create: `STDLIB/iii/omnia/praxis_cli.iii`
- Create: `STDLIB/scripts/praxis_gate.sh`

**Interfaces:**
- Consumes: `eol_reset() -> i32`, `eol_read(addr: u64, len: u64) -> i64`, `eol_keep() -> u64`, `eol_judge_claim(base: u64, len: u64) -> u64` from `eidolos.iii`; `xc_begin() -> i32`, `xc_event_byte(b: u32) -> i32`, `xc_seal(out32: *u8) -> i32` from `exec_cert.iii`
- Produces: `px_begin() -> i32`, `px_pin(s: u64) -> u64`, `px_stand() -> u64`, `px_judge(s: u64) -> u64`, `px_count() -> u64`, `px_seal(out32: *u8) -> i32`, `praxis_selfprove() -> u64`

- [x] **Step 1: Write the organ with its failing arms**

Create `STDLIB/iii/omnia/praxis.iii`:

```
/* STDLIB/iii/omnia/praxis.iii -- PRAXIS (the deed): the WITNESSED TRACE, and the one law over it.
 *
 * THE LAW.  A claim stands only if the witnessed trace DETERMINES it. This is KANON's theorem
 * (x IN Fold(G) <=> membership) taken on its EIDOLOS twin rather than its rank meter -- because a
 * process trace is DIRECTED (RED before GREEN is a '<' relation) and the GF(2)/matroid closure is
 * UNDIRECTED. Applying rank here is the recorded SYMPLOKE category error; ANAMNESIS re-founded the
 * fold event-primary for exactly this reason, and PRAXIS inherits that correction.
 *
 * So: pinned events are READ into EIDOLOS and SEALED (eol_keep) -- they become the kept house, the Fold.
 * A claim is then judged by eol_judge_claim: 1 = derivable from the trace (STANDS), 0 = DEFECT (the
 * unearned assertion) -> REFUSED. The defect IS the lie, and it is measured, not suspected.
 *
 * TAMPER-EVIDENCE.  Every pinned byte is folded into omnia/exec_cert's incremental sha256 (O(1) per
 * event, O(32) memo). The same event stream seals bit-identically; one perturbed byte changes the seal.
 *
 * THE BOUNDARY THAT MAKES IT REAL.  The agent may append CLAIMS; only the harness may append PINS.
 * A pin is a thing no model can author -- a content digest, an exit code, a git object hash. A mandate
 * whose leaves are agent-authored strings is theatre. Ring R0. */
module omnia_praxis

extern @abi(c-msvc-x64) fn eol_reset() -> i32 from "eidolos.iii"
extern @abi(c-msvc-x64) fn eol_read(addr: u64, len: u64) -> i64 from "eidolos.iii"
extern @abi(c-msvc-x64) fn eol_keep() -> u64 from "eidolos.iii"
extern @abi(c-msvc-x64) fn eol_judge_claim(base: u64, len: u64) -> u64 from "eidolos.iii"
extern @abi(c-msvc-x64) fn xc_begin() -> i32 from "exec_cert.iii"
extern @abi(c-msvc-x64) fn xc_event_byte(b: u32) -> i32 from "exec_cert.iii"
extern @abi(c-msvc-x64) fn xc_seal(out32: *u8) -> i32 from "exec_cert.iii"

var PX_N : u64 = 0u64            /* how many events were pinned */
var PX_A : [u8; 32]              /* seal A (module var: a local array's address is not FFI-valid) */
var PX_B : [u8; 32]              /* seal B */

fn px_slen(s: u64) -> u64 { let p : *u8 = s as *u8   let mut i : u64 = 0u64   while p[i] != 0u8 { i = i + 1u64 }   return i }

/* open a fresh trace: empty house, fresh certificate */
fn px_begin() -> i32 @export { PX_N = 0u64   eol_reset()   xc_begin()   return 0i32 }

/* PIN one witnessed event: fold its bytes into the tamper-evident certificate, then read it into the house */
fn px_pin(s: u64) -> u64 @export {
    let p : *u8 = s as *u8
    let mut i : u64 = 0u64
    while p[i] != 0u8 { xc_event_byte(p[i] as u32)   i = i + 1u64 }
    xc_event_byte(10u32)
    if eol_read(s, i) < 0i64 { return 1u64 }
    PX_N = PX_N + 1u64
    return 0u64
}

/* SEAL the house: the pinned events become the Fold against which every claim is judged */
fn px_stand() -> u64 @export { return eol_keep() }

/* THE MANDATE: does the witnessed trace DETERMINE this claim? 1 = stands, 0 = DEFECT (refused) */
fn px_judge(s: u64) -> u64 @export { return eol_judge_claim(s, px_slen(s)) }

fn px_count() -> u64 @export { return PX_N }
fn px_seal(out32: *u8) -> i32 @export { return xc_seal(out32) }

fn praxis_selfprove() -> u64 @export {
    /* ARM 1: THE NAKED CLAIM -- an EMPTY trace does not determine completion. This is the whole point:
     * "it is done" with nothing witnessed is a DEFECT, and the seat refuses it. */
    px_begin()
    px_stand()
    if px_judge("[done < gate_green]" as u64) != 0u64 { return 1u64 }

    /* ARM 2: THE EARNED CLAIM -- pin the gate evidence, and the same claim now STANDS. */
    px_begin()
    if px_pin("[gate_green < exit_zero]" as u64) != 0u64 { return 2u64 }
    if px_pin("[done < gate_green]" as u64) != 0u64 { return 2u64 }
    px_stand()
    if px_judge("[done < exit_zero]" as u64) != 1u64 { return 2u64 }

    /* ARM 3: NO FREE LUNCH -- an UNRELATED pin does not buy the claim. Evidence must actually reach it. */
    px_begin()
    if px_pin("[readme < prose]" as u64) != 0u64 { return 3u64 }
    px_stand()
    if px_judge("[done < exit_zero]" as u64) != 0u64 { return 3u64 }

    /* ARM 4: TAMPER-EVIDENCE -- the same event stream seals bit-identically; a perturbed one does not. */
    px_begin()
    px_pin("[gate_green < exit_zero]" as u64)
    px_seal((&PX_A) as u64 as *u8)
    px_begin()
    px_pin("[gate_green < exit_zero]" as u64)
    px_seal((&PX_B) as u64 as *u8)
    let mut i : u64 = 0u64
    while i < 32u64 { if PX_A[i] != PX_B[i] { return 4u64 }   i = i + 1u64 }
    px_begin()
    px_pin("[gate_green < exit_one]" as u64)
    px_seal((&PX_B) as u64 as *u8)
    let mut d : u64 = 0u64
    let mut j : u64 = 0u64
    while j < 32u64 { if PX_A[j] != PX_B[j] { d = 1u64 }   j = j + 1u64 }
    if d != 1u64 { return 4u64 }

    /* ARM 5: the count is the witnessed count -- no phantom events. */
    px_begin()
    px_pin("[a < b]" as u64)
    px_pin("[b < c]" as u64)
    if px_count() != 2u64 { return 5u64 }

    return 0u64
}
```

- [x] **Step 2: Write the CLI carrier**

Create `STDLIB/iii/omnia/praxis_cli.iii`. The shell (the harness) authors the pins and passes them as
`argv[1]` (space-separated scrolls) with the claim as `argv[2]`. Exit 0 = STANDS, exit 1 = DEFECT.

```
/* STDLIB/iii/omnia/praxis_cli.iii -- the carrier: PRAXIS has no main (library organ); this does.
 * argv[1] = the pinned trace (scrolls, space-separated, authored by the HOOK not the agent)
 * argv[2] = the claim under judgment
 * exit 0 = the trace DETERMINES the claim (stands) | exit 1 = DEFECT (refused) | 2 = usage */
module omnia_praxis_cli

extern @abi(c-msvc-x64) fn putchar(c: i32) -> i32 from "msvcrt"
extern @abi(c-msvc-x64) fn px_begin() -> i32 from "praxis.iii"
extern @abi(c-msvc-x64) fn px_pin(s: u64) -> u64 from "praxis.iii"
extern @abi(c-msvc-x64) fn px_stand() -> u64 from "praxis.iii"
extern @abi(c-msvc-x64) fn px_judge(s: u64) -> u64 from "praxis.iii"
extern @abi(c-msvc-x64) fn praxis_selfprove() -> u64 from "praxis.iii"

fn pc_ps(sp: u64) -> u32 { let p : *u8 = sp as *u8   let mut i : u64 = 0u64   while p[i] != 0u8 { putchar(p[i] as i32)   i = i + 1u64 }   return 1u32 }

fn main(argc: i32, argv: u64) -> u64 {
    let av : *u64 = argv as *u64
    if argc < 3i32 {
        let r : u64 = praxis_selfprove()
        pc_ps("praxis_selfprove = " as u64)   putchar((48u64 + r) as i32)   putchar(10i32)
        if r == 0u64 { pc_ps("GREEN: the naked claim is refused; the earned claim stands; the trace is tamper-evident.\n" as u64) }
        return r
    }
    let trace : u64 = av[1]
    let claim : u64 = av[2]
    px_begin()
    px_pin(trace)
    px_stand()
    if px_judge(claim) == 1u64 { pc_ps("STANDS\n" as u64)   return 0u64 }
    pc_ps("DEFECT: the witnessed trace does not determine this claim -- REFUSED\n" as u64)
    return 1u64
}
```

- [x] **Step 3: Write the gate**

Create `STDLIB/scripts/praxis_gate.sh`, mirroring `STDLIB/scripts/henosis_gate.sh` exactly for its
`cc_one` settle-retry helper, `ROOT`/`IIIS`/`ARC` resolution, and its two-run byte-determinism check.
Its build directory MUST be exactly `T="$ROOT/STDLIB/build/praxis"` and the linked probe MUST be
`$T/praxis_cli.exe` — Task 3's `praxis_judge.sh` resolves that exact path.
It must: compile `eidolos.iii`, `exec_cert.iii`, `isub.iii` (fresh), `praxis.iii`, `praxis_cli.iii`;
link against `$ARC`; run the probe with no args and demand `praxis_selfprove = 0`; then run the
positive and negative CLI cases below and demand exit 0 and exit 1 respectively; then demand two
runs produce one identical transcript.

```bash
"$T/praxis_cli.exe" "[gate_green < exit_zero] [done < gate_green]" "[done < exit_zero]" ; rc=$?
[ "$rc" -eq 0 ] || { echo "[praxis_gate] earned claim did not stand (rc=$rc)"; exit 3; }
"$T/praxis_cli.exe" "[readme < prose]" "[done < exit_zero]" ; rc=$?
[ "$rc" -eq 1 ] || { echo "[praxis_gate] naked claim was NOT refused (rc=$rc)"; exit 4; }
```

- [x] **Step 4: Run the gate to verify it FAILS first**

Run: `bash STDLIB/scripts/praxis_gate.sh 2>&1 | tail -10; echo "exit=$?"`
Expected on the first attempt: a compile or link failure (the organ is new and unarchived). Fix
compile errors only — do not weaken an arm to make it pass.

- [x] **Step 5: Run the gate to verify it PASSES**

Run: `bash STDLIB/scripts/praxis_gate.sh 2>&1 | tail -10; echo "exit=$?"`
Expected: `praxis_selfprove = 0`, both CLI cases at their expected exit codes, byte-determinism OK, `exit=0`.

- [x] **Step 6: Commit**

```bash
git add STDLIB/iii/omnia/praxis.iii STDLIB/iii/omnia/praxis_cli.iii STDLIB/scripts/praxis_gate.sh
git commit -m "PRAXIS: the witnessed trace -- the naked claim is a DEFECT, the earned claim stands"
```

---

### Task 3: The binding — hooks author the pins, and Stop refuses the unearned claim

**Files:**
- Create: `STDLIB/scripts/praxis_pin.sh`
- Create: `STDLIB/scripts/praxis_judge.sh`
- Modify: `.claude/settings.json`

**Interfaces:**
- Consumes: `STDLIB/build/praxis/praxis_cli.exe` from Task 2
- Produces: a trace at `.praxis/<session>.trace`; a `Stop`-hook verdict

- [x] **Step 1: Read the exact hook schema — do not guess it**

Invoke the `update-config` skill. It owns `settings.json` hook configuration and the blocking
convention (which exit code / JSON shape actually blocks a `Stop`). Record the exact schema before
writing Step 3 — a hook that silently no-ops is worse than no hook, because it reads as enforcement.

- [x] **Step 2: Write the pin script (the harness authors pins, never the agent)**

Create `STDLIB/scripts/praxis_pin.sh`. It reads the hook's JSON payload on stdin, and appends ONE
scroll per observed event, where every leaf is a thing the model cannot author:

```bash
#!/usr/bin/env bash
# praxis_pin.sh -- PostToolUse: the HARNESS authors the pin. Content digests and exit codes only.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRACE="$ROOT/.praxis/$(date +%Y%m%d).trace"
mkdir -p "$ROOT/.praxis"
payload="$(cat)"
tool="$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).tool_name||"")}catch(e){console.log("")}})')"
case "$tool" in
  Edit|Write)
    f="$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).tool_input.file_path||"")}catch(e){console.log("")}})')"
    [ -f "$f" ] && printf '[edit_%s < sha_%s]\n' "$(basename "$f" | tr -c 'A-Za-z0-9' '_')" "$(sha256sum "$f" | cut -c1-12)" >> "$TRACE"
    ;;
  Bash)
    # a gate that exited zero is the only evidence that buys a completion claim
    printf '%s' "$payload" | grep -q '_gate\.sh' && printf '[gate_green < exit_zero]\n' >> "$TRACE"
    ;;
esac
exit 0
```

- [x] **Step 3: Write the judge script (the Stop mandate)**

Create `STDLIB/scripts/praxis_judge.sh`:

```bash
#!/usr/bin/env bash
# praxis_judge.sh -- Stop: refuse a completion claim the witnessed trace does not determine.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRACE="$ROOT/.praxis/$(date +%Y%m%d).trace"
CLI="$ROOT/STDLIB/build/praxis/praxis_cli.exe"
[ -x "$CLI" ] || exit 0                       # engine absent: stay silent, never fake enforcement
[ -f "$TRACE" ] || { echo "PRAXIS: NAMED DEFICIT -- no witnessed trace for today; nothing was pinned." >&2; exit 0; }
"$CLI" "$(tr '\n' ' ' < "$TRACE") [done < gate_green]" "[done < exit_zero]"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "PRAXIS REFUSES: the trace does not determine completion. MISSING PIN: a *_gate.sh run exiting 0 after the last edit." >&2
  exit 2                                      # replace with the exact blocking convention from Step 1
fi
exit 0
```

- [x] **Step 4: Test both scripts standalone BEFORE wiring them**

```bash
rm -rf .praxis && mkdir -p .praxis
bash STDLIB/scripts/praxis_judge.sh; echo "no-trace exit=$?"      # expect 0 + NAMED DEFICIT on stderr
printf '[readme < prose]\n' > ".praxis/$(date +%Y%m%d).trace"
bash STDLIB/scripts/praxis_judge.sh; echo "unearned exit=$?"      # expect nonzero + REFUSES line
printf '[gate_green < exit_zero]\n' >> ".praxis/$(date +%Y%m%d).trace"
bash STDLIB/scripts/praxis_judge.sh; echo "earned exit=$?"        # expect 0, silent
```

- [x] **Step 5: Wire the hooks**

Modify `.claude/settings.json` using the exact schema from Step 1, preserving the existing
`enabledPlugins` block. `PostToolUse` → `praxis_pin.sh`; `Stop` → `praxis_judge.sh`.

- [x] **Step 6: Verify the loop end-to-end in a live session**

Edit any file, do NOT run a gate, and attempt to stop. Expected: the `Stop` hook refuses and names the
missing pin. Then run a gate to green and stop again. Expected: silence.

- [x] **Step 7: Commit**

```bash
git add STDLIB/scripts/praxis_pin.sh STDLIB/scripts/praxis_judge.sh .claude/settings.json
git commit -m "THE BINDING: hooks author the pins; Stop refuses the claim the trace does not determine"
```

---

## Kill-switches (from the spec — check these during execution, not after)

- **>30% false refusals after two weeks** ⇒ the predicate set is wrong. Stop adding mandates and fix
  separation, or this becomes another disabled linter.
- **A `Stop` hook that mis-refuses makes a session unstoppable.** Every refusal MUST name the missing
  pin (it does, above), and any override MUST be recorded, never silent (NAMED-DEFICIT LAW).
- **If `praxis_judge.sh` cannot block** (Step 1 reveals `Stop` hooks are advisory in this harness
  version) ⇒ Task 3 delivers observation, not enforcement. Say so plainly in the commit message and
  do not describe the result as a mandate.
