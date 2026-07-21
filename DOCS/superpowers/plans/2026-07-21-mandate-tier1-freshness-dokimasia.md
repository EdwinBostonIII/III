# Mandate Engine — Tier 1: the freshness mandate + the assay made callable

> **For agentic workers:** Use `superpowers:executing-plans` (subagents BARRED — no subagents on III).
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close Tier 0's named ordering gap — an edit AFTER the last green gate makes a completion
claim STALE and refused — and give DOKIMASIA a compiled CLI so any oracle's verdict-map can be
assayed from the shell (consumer for Tier 0b's MCP swap and Tier 3's separation rig).

**Architecture:** PRAXIS learns order: `px_pin` scans pinned bytes for `[edit_` / `[gate_green`
prefixes and records last-seen offsets; `px_fresh()` = a green gate exists and no edit follows it.
The CLI splits verdicts three ways (STANDS 0 / DEFECT 1 / STALE 3) so the Stop judge names the
exact deficit. `dokimasia_cli.iii` feeds a verdict bitstring into the live ONTOS meters.

**Tech Stack:** `.iii` via in-tree `COMPILED/iiis-2.exe`; bash gates; the live hook scripts.

## Global Constraints

- Compiler `COMPILED/iiis-2.exe`; library organs carry NO main; CLI carriers go FIRST in the link
  line (`--allow-multiple-definition`, first main wins).
- EIDOLOS idents are LOWERCASE-only (07-21 first-blood trap).
- Every new `@export` arrives with a consuming arm (RATCHET-DELTA-ZERO) or is cut.
- RED-first: arms referencing new fns go in BEFORE the fns; the gate must fail by name first.
- Gates byte-deterministic across two runs. Reserved words: `any`, `from`, `mut`.
- Registered mandates this tier does NOT build, with reasons: read-before-edit (the harness Edit
  tool already refuses unread edits natively — a duplicate is redundancy); crash-phase-order (an
  agent-authored phase marker violates the pin law; the .sov workflow lives in another tree);
  no-self-grading (discharged by construction — pins are harness-authored); RED-first-for-tests
  (rides DOKIMASIA: a never-failed test is a 0-bit oracle — enforcement lands with Tier 0b/3
  consumers).

---

### Task 1: px_fresh — the ordering law inside PRAXIS

**Files:**
- Modify: `STDLIB/iii/omnia/praxis.iii` (vars after `PX_B`; `px_match`+`px_fresh` after `px_slen`; scan inside `px_pin`; arms 6-9 at the end of `praxis_selfprove`)
- Modify: `STDLIB/iii/omnia/praxis_cli.iii` (extern `px_fresh`; three-way verdict)
- Modify: `STDLIB/scripts/praxis_gate.sh` (fresh + stale CLI cases)

**Interfaces:**
- Consumes: existing `px_begin/px_pin/px_stand/px_judge` and the CLI/gate from Tier 0.
- Produces: `px_fresh() -> u64 @export` (1 = a `[gate_green` pin exists and no `[edit_` pin
  follows it; else 0); CLI exit 3 = STALE with a `STALE:` line.

- [ ] **Step 1: RED — add arms 6-9 to `praxis_selfprove` (they call `px_fresh`, which does not exist)**

Append before `return 0u64` in `praxis_selfprove`:

```
    /* ARM 6: THE STALE GREEN -- an edit AFTER the last green gate leaves the claim uncovered.
     * Order is the point: the same two pins in the other order are ARM 7 and STAND. */
    px_begin()
    px_pin("[gate_green < exit_zero]" as u64)
    px_pin("[edit_praxis_iii < sha_aaaa]" as u64)
    if px_fresh() != 0u64 { return 6u64 }

    /* ARM 7: THE COVERED EDIT -- the gate ran green AFTER the edit: fresh, covered, standing. */
    px_begin()
    px_pin("[edit_praxis_iii < sha_aaaa]" as u64)
    px_pin("[gate_green < exit_zero]" as u64)
    if px_fresh() != 1u64 { return 7u64 }

    /* ARM 8: NO EDITS -- a green gate alone is fresh (there is nothing uncovered). */
    px_begin()
    px_pin("[gate_green < exit_zero]" as u64)
    if px_fresh() != 1u64 { return 8u64 }

    /* ARM 9: NO GATE -- edits alone are never fresh; freshness cannot be bought without a gate. */
    px_begin()
    px_pin("[edit_praxis_iii < sha_aaaa]" as u64)
    if px_fresh() != 0u64 { return 9u64 }
```

- [ ] **Step 2: run `bash STDLIB/scripts/praxis_gate.sh 2>&1 | tail -4` — expect COMPILE FAIL naming `px_fresh` (TYPE-IDENT-001)**

- [ ] **Step 3: implement — vars, matcher, scan, `px_fresh`**

After `var PX_B : [u8; 32]` add:

```
var PX_OFF   : u64 = 0u64        /* absolute byte offset across all pins (order clock) */
var PX_LASTE : u64 = 0u64        /* offset+1 of the last "[edit_"     pin seen (0 = never) */
var PX_LASTG : u64 = 0u64        /* offset+1 of the last "[gate_green" pin seen (0 = never) */
```

After `px_slen` add:

```
/* does s[i..] begin with the literal lit? Bounded: stops at either NUL, never reads past. */
fn px_match(s: u64, i: u64, lit: u64) -> u64 {
    let p : *u8 = s as *u8
    let q : *u8 = lit as *u8
    let mut k : u64 = 0u64
    while q[k] != 0u8 {
        if p[i + k] != q[k] { return 0u64 }
        k = k + 1u64
    }
    return 1u64
}

/* THE FRESHNESS LAW: a claim is covered only if a green gate stands AFTER the last edit.
 * Same-event ties cannot occur (offsets strictly increase). */
fn px_fresh() -> u64 @export {
    if PX_LASTG == 0u64 { return 0u64 }
    if PX_LASTE == 0u64 { return 1u64 }
    if PX_LASTE < PX_LASTG { return 1u64 }
    return 0u64
}
```

In `px_begin`, extend the reset: `PX_N = 0u64   PX_OFF = 0u64   PX_LASTE = 0u64   PX_LASTG = 0u64`.

In `px_pin`, inside the byte loop, after `xc_event_byte(p[i] as u32)` add the scan:

```
        if px_match(s, i, "[edit_" as u64) == 1u64 { PX_LASTE = PX_OFF + i + 1u64 }
        if px_match(s, i, "[gate_green" as u64) == 1u64 { PX_LASTG = PX_OFF + i + 1u64 }
```

and after the loop (before `xc_event_byte(10u32)`... immediately after it is fine) add:
`PX_OFF = PX_OFF + i + 1u64`.

- [ ] **Step 4: three-way CLI verdict**

In `praxis_cli.iii` add extern `fn px_fresh() -> u64 from "praxis.iii"` and replace the judge tail:

```
    if px_judge(claim) == 1u64 {
        if px_fresh() == 1u64 { pc_ps("STANDS\n" as u64)   return 0u64 }
        pc_ps("STALE: an edit follows the last green gate -- the claim is not covered; REFUSED\n" as u64)
        return 3u64
    }
    pc_ps("DEFECT: the witnessed trace does not determine this claim -- REFUSED\n" as u64)
    return 1u64
```

- [ ] **Step 5: gate cases — fresh stands, stale refused**

In `praxis_gate.sh` `rite()`, after the naked case add:

```bash
    "$stg" "[edit_praxis_iii < sha_aaaa] [gate_green < exit_zero] [done < gate_green]" "[done < exit_zero]" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 0 ] || { echo "[praxis_gate] covered edit did not stand (rc=$rc)"; tail -4 "$out"; rm -f "$stg"; return 8; }
    "$stg" "[gate_green < exit_zero] [edit_praxis_iii < sha_aaaa] [done < gate_green]" "[done < exit_zero]" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 3 ] || { echo "[praxis_gate] STALE was NOT refused with 3 (rc=$rc)"; tail -4 "$out"; rm -f "$stg"; return 9; }
```

and to the transcript demands add: `grep -q "STALE" "$T/run1.txt" || { echo "[praxis_gate] no STALE in transcript"; exit 7; }`

- [ ] **Step 6: run `bash STDLIB/scripts/praxis_gate.sh; echo GATE_EXIT=$?` — expect GREEN, GATE_EXIT=0, STALE present**

- [ ] **Step 7: commit**

```bash
git add STDLIB/iii/omnia/praxis.iii STDLIB/iii/omnia/praxis_cli.iii STDLIB/scripts/praxis_gate.sh
git commit -m "THE FRESHNESS LAW: an edit after the last green gate makes the claim STALE"
```

### Task 2: the Stop judge names STALE; tree-scoped edit pins

**Files:**
- Modify: `STDLIB/scripts/praxis_judge.sh` (rc=3 branch)
- Modify: `STDLIB/scripts/praxis_pin.sh` (only files under the III tree pin as edits)

- [ ] **Step 1: judge rc=3 branch** — replace the two-line fail-open tail after the STANDS check:

```bash
if [ "$rc" -eq 0 ]; then rm -f "$GUARD"; exit 0; fi   # STANDS: earned and fresh
if [ "$rc" -ne 1 ] && [ "$rc" -ne 3 ]; then rm -f "$GUARD"; exit 0; fi   # engine anomaly: fail-open
echo $((n + 1)) > "$GUARD"
if [ "$rc" -eq 3 ]; then
  printf '{"decision":"block","reason":"PRAXIS REFUSES (STALE): edits were pinned AFTER the last green gate -- the claim no longer covers the work. Re-run the gate that covers what you changed, then finish. Refusal %s of 3; the ceiling fails open."}\n' "$((n + 1))"
else
  printf '{"decision":"block","reason":"PRAXIS REFUSES: the witnessed trace does not determine completion. MISSING PIN: [gate_green < exit_zero] -- no *_gate.sh run went GREEN in this session after your edits. Run the gate that covers what you changed (its GREEN output is pinned automatically), then finish. Refusal %s of 3; the ceiling fails open."}\n' "$((n + 1))"
fi
exit 0
```

- [ ] **Step 2: tree-scope the pinner** — in `praxis_pin.sh` node code, Edit/Write branch, after
computing `f`, skip files outside the tree (memory files, scratchpad — they are not tree changes
and must not stale a covered claim): pass ROOT via env (`export III_TREE="$ROOT"` next to
PRAXIS_DIR) and guard:

```js
      const troot = (process.env.III_TREE || "").replace(/\\/g, "/").toLowerCase();
      const fn = f.replace(/\\/g, "/").toLowerCase();
      if (!troot || !fn.startsWith(troot + "/")) return;   /* outside the tree: not an edit pin */
```

- [ ] **Step 3: standalone verify both** — synthesize: (a) stale trace -> judge blocks with STALE
wording; (b) out-of-tree edit payload -> no pin appended; (c) in-tree edit payload -> pin appended.

- [ ] **Step 4: commit**

```bash
git add STDLIB/scripts/praxis_judge.sh STDLIB/scripts/praxis_pin.sh
git commit -m "THE JUDGE NAMES STALE; only tree edits pin"
```

### Task 3: dokimasia_cli — the assay from the shell

**Files:**
- Create: `STDLIB/iii/omnia/dokimasia_cli.iii`
- Modify: `STDLIB/scripts/ontos_gate.sh` (build + probe the CLI)

**Interfaces:**
- Consumes: `ont_tbl_set(i,v)`, `ont_image_ext(n)`, `ont_verdict_bits(n)`, `ont_admissible(n)` (Tier 0 exports).
- Produces: `STDLIB/build/ontos/dokimasia_cli.exe` — argv[1] = verdict bitstring ("1"=pass,"0"=fail
  per probe, 2..256 probes); prints `image=I bits=B admissible=A`; exit 0 admissible / 1 rubber
  stamp / 2 usage. Consumers: Tier 0b `iii_dokimasia`, Tier 3 separation rig.

- [ ] **Step 1: write the CLI**

```
/* STDLIB/iii/omnia/dokimasia_cli.iii -- the assay from the shell: may this oracle be HEARD?
 * argv[1] = the oracle's verdict over a pinned probe set, as a bitstring ("1" pass / "0" fail).
 * The probe set MUST contain known-bad mutants; a map that cannot separate them carries 0 bits.
 * exit 0 = admissible (>=1 bit) | 1 = rubber stamp (constant map, 0 bits) | 2 = usage. */
module omnia_dokimasia_cli

extern @abi(c-msvc-x64) fn putchar(c: i32) -> i32 from "msvcrt"
extern @abi(c-msvc-x64) fn ont_tbl_set(i: u64, v: u64) -> i32 from "ontos.iii"
extern @abi(c-msvc-x64) fn ont_image_ext(size: u64) -> u64 from "ontos.iii"
extern @abi(c-msvc-x64) fn ont_verdict_bits(size: u64) -> u64 from "ontos.iii"
extern @abi(c-msvc-x64) fn ont_admissible(size: u64) -> u64 from "ontos.iii"

fn dk_ps(sp: u64) -> u32 { let p : *u8 = sp as *u8   let mut i : u64 = 0u64   while p[i] != 0u8 { putchar(p[i] as i32)   i = i + 1u64 }   return 1u32 }
fn dk_pu(v: u64) -> u32 { if v >= 10u64 { dk_pu(v / 10u64) }   putchar((48u64 + (v % 10u64)) as i32)   return 1u32 }

fn main(argc: i32, argv: u64) -> u64 {
    let av : *u64 = argv as *u64
    if argc < 2i32 { dk_ps("usage: dokimasia_cli <verdict-bitstring over the probe set>\n" as u64)   return 2u64 }
    let s : u64 = av[1]
    let p : *u8 = s as *u8
    let mut n : u64 = 0u64
    while p[n] != 0u8 {
        if p[n] == 49u8 { ont_tbl_set(n, 1u64) } else {
            if p[n] == 48u8 { ont_tbl_set(n, 0u64) } else { dk_ps("usage: bitstring must be 0/1 only\n" as u64)   return 2u64 }
        }
        n = n + 1u64
    }
    if n < 2u64 { dk_ps("usage: need >= 2 probes\n" as u64)   return 2u64 }
    if n > 256u64 { dk_ps("REFUSED: probe set wider than the seat (256)\n" as u64)   return 2u64 }
    dk_ps("image=" as u64)   dk_pu(ont_image_ext(n))
    dk_ps(" bits=" as u64)   dk_pu(ont_verdict_bits(n))
    dk_ps(" admissible=" as u64)   dk_pu(ont_admissible(n))
    putchar(10i32)
    if ont_admissible(n) == 1u64 { dk_ps("HEARD: the oracle separates; its verdict may serve as evidence.\n" as u64)   return 0u64 }
    dk_ps("REFUSED: a rubber stamp (0 bits) -- this oracle's verdict is independent of its input.\n" as u64)
    return 1u64
}
```

- [ ] **Step 2: extend `ontos_gate.sh`** — after the existing GREEN checks add:

```bash
cc_one "$ROOT/STDLIB/iii/omnia/dokimasia_cli.iii" "$T/dokimasia_cli.o" || exit 2
rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/dokimasia_cli.exe"
    gcc -o "$T/dokimasia_cli.exe" "$T/dokimasia_cli.o" "$T/ontos.o" "$T/eidolos.o" "$T/isub.o" "$T/idfold.o" "$T/bounty_attest.o" "$T/kardia.o" "$T/ptyxis.o" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/dk_link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/dokimasia_cli.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[ontos_gate] DOKIMASIA CLI LINK FAIL rc=$rc"; tail -8 "$T/dk_link.log"; exit 3; }
DK="$T/dokimasia_cli.exe"
"$DK" "11110000" > "$T/dk1.txt" 2>&1; [ $? -eq 0 ] || { echo "[ontos_gate] separator not HEARD"; cat "$T/dk1.txt"; exit 8; }
"$DK" "11111111" > "$T/dk2.txt" 2>&1; [ $? -eq 1 ] || { echo "[ontos_gate] rubber stamp not REFUSED"; cat "$T/dk2.txt"; exit 8; }
"$DK" "00000000" > "$T/dk3.txt" 2>&1; [ $? -eq 1 ] || { echo "[ontos_gate] constant refuser not REFUSED"; cat "$T/dk3.txt"; exit 8; }
"$DK" "11110000" > "$T/dk4.txt" 2>&1
cmp -s "$T/dk1.txt" "$T/dk4.txt" || { echo "[ontos_gate] DOKIMASIA CLI nondeterminism"; exit 8; }
grep -q "image=2 bits=1 admissible=1" "$T/dk1.txt" || { echo "[ontos_gate] wrong assay numbers"; cat "$T/dk1.txt"; exit 8; }
echo "[ontos_gate] DOKIMASIA CLI: separator HEARD (exit 0), both constant maps REFUSED (exit 1), deterministic."
```

- [ ] **Step 3: run `bash STDLIB/scripts/ontos_gate.sh; echo GATE_EXIT=$?` — expect GREEN + the new DOKIMASIA CLI line, GATE_EXIT=0**

- [ ] **Step 4: commit**

```bash
git add STDLIB/iii/omnia/dokimasia_cli.iii STDLIB/scripts/ontos_gate.sh
git commit -m "DOKIMASIA FROM THE SHELL: the assay is now a compiled verb"
```
