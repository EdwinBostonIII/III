# III — THE EVENT-PRIMARY WAIST: the inversion made the ground of execution
### route V: SVIR executed as an append-only retirement log; state, output, and result = a validating fold over history
> **Date:** 2026-07-14 · **Status: BUILT + GATE GREEN same session** (`run_event_waist.sh` exit 0:
> 3 organ-law gates at 99 · **differential 19/19 route-S ≡ route-V (rc + stdout bytes) over the real
> square-probe SVIR modules + the extern-free independence probes** · tamper tooth 193 on real module
> bytes · two full runs byte-identical · **THE STANDING TOOL `iii-events`** (route V on arbitrary user
> programs, `COMPILER/BOOT/build_iii_events.sh` → `COMPILED/iii-events`; see III-STANDING-TOOLS.md) with
> gate-authored-probe parity, source-level rc+output parity, tamper 193, and verdict determinism arms).
> **Files:** `STDLIB/sovir/svir_event.iii` (the organ) · `STDLIB/sovir/svir_event_main.iii` (driver) ·
> `STDLIB/corpus/2750/2751/2752` (laws · replay independence · recurrence) ·
> `STDLIB/sovir/run_event_waist.sh` (family owner; SKIP-registered in `run_corpus.sh`).
> Companion: `III-EVENT-SUBSTRATE.md` (the organ-scale inversion this carries to the waist).

---

## 1. THESIS

`omnia/event_substrate` (KATs 1900/1901) proved the inversion at organ scale: *the EVENT is primary;
STATE is a deterministic fold over an append-only history.* What remained state-primary was the thing
underneath everything: **execution itself**. `svir_interp` — the waist's reference executor — steps
registers, stack, and memory in place; its history dies as it runs. This campaign builds **route V**:
an SVIR v1/v2 executor whose only durable product is the **retirement log** — one event per executed
instruction, carrying the consumed operands and produced result — and whose observable behavior
(program output, program result) is **read out of the log by a fold**, not out of the live machine.

The two engines, non-tautological by construction:

| Engine | What it does | What it may NOT do |
|---|---|---|
| **PRODUCER** (`sve_run`) | walks the module, reference semantics op-for-op (silent-pop-0, shift masks, sentinels 198/199, argv staging, arena save/restore — parity with `svir_interp` FIRST), appending one event per retirement | it never prints; its final machine state is erased before the fold reads anything |
| **GROUND** (`sve_replay`) | folds `(data image, log)` alone — **no program text, no control-flow logic**: maintains its own stack/locals/memory folds, re-derives every event's result through the same semantics doors, checks every recorded operand against its own fold, prints the output at fold time, recomputes the witness | it never touches the module's code bytes; the log IS the flow |

Discipline that makes the fold well-defined: **pops before append, pushes after append** in the
producer — so "the state after event T" is one canonical thing, and the producer's during-run
snapshots (every 1024 events, captured lazily at the next append) must equal the fold's
`sve_state_at(T)` re-derivation. That two-path arm caught a real defect during construction
(the phantom-return-value bug, §4) — the inversion audits its own builder.

## 2. THE EVENT

`(meta, a, b, r)` per retirement; `meta` packs `op | kind | depth | fn | pc | width`. Kinds:
`K_EXEC` (value ops: operands checked, result re-derived), `K_CTRL` (IF/BR_IF conditions checked),
`K_CALL` (frame opens; args move stack→locals in the fold), `K_RET` (result leaves the callee's
stack and re-enters as the caller's value; at depth 0 it IS the program result), `K_SHIM`
(the deterministic CRT tier malloc/free/putchar/VirtualAlloc/VirtualFree/Sleep — call+result+return
fused; putchar prints at fold time). Witness = order-sensitive multiply-add fold (FNV64 prime) over
every field of every event — determinism/tamper grade by declared scope (content-address sealing is
`omnia/involution`'s job; not re-authored).

## 3. NAMED REFUSALS (never silent)

| rc | Meaning |
|---|---|
| 190 | log capacity exceeded (4,194,304 events; a lowered test-door limit in the KATs) |
| 192 | capacity hit AND a row-recurrence lasso found in the log (an observed-recurrence REPORT, never a non-termination theorem) |
| 193 | replay divergence — the fold refutes the log (tamper, or a producer bug); `sve_diverge_at/why` pin the row |
| 198/199 | unresolved import / OOB indirect call — the reference's sentinels, mirrored |

## 4. VERIFICATION (all green this session, negative arms first)

- **2750 laws** (exit 99): malformed module refused; capacity door 190; result 55 + output `*` read
  from the log; witness producer==fold; **tamper teeth on every field class** (meta/a/b/r poked →
  193 or witness-mismatch; restored → heals); prefix folds `state_at(2)=[33,9]`, `state_at(3)=[42]`;
  fresh-run witness identical.
- **2751 replay independence** (exit 99): ~1,819-event module (memory + two-function CALL + a
  300-iteration loop); fold re-derives result 88; **replay idempotent**; **two-path prefix arm**:
  every producer snapshot equals the log-derived prefix state — this arm caught the
  **phantom-return-value defect** (replay pushed the return without popping the callee's result;
  rc and result still agreed — only the prefix state exposed the corrupted stack depth) and forced
  the pops-before/pushes-after canon; locals-fold and memory-fold tamper teeth (LOCAL_GET / LD8
  results poked → 193; restored → heals).
- **2752 recurrence** (exit 99): terminating module → finite log closed by `K_RET@depth0` (the
  termination witness); **pure loop → 192 with lasso length 1**; **counting loop → 190 with NO
  lasso** (the counter rides in the rows; no identical window exists) — the positive-and-negative
  pair proving the instrument reads structure, not hope.
- **THE DIFFERENTIAL** (`run_event_waist.sh` stage [4]): the production `cg_svir` harness (the same
  8 TUs the sealed backend gate builds) emits the REAL SVIR modules of all **17 square probes**;
  route S (`svir_interp`) and route V must agree on **rc AND stdout bytes**: **17/17 AGREE**
  (sq01..sq17, including sq15_crt's shim tier — 3 output bytes equal — and sq05_recur/sq06_loops at
  1,763/944 events). The shim-frame defect this stage exposed (a `K_CALL` frame never closed by a
  shim) was fixed as §2's fused K_SHIM semantics — found by the differential, on real modules.
- **Teeth on real bytes** (stage [5]): `--tamper` (one bit of one field of the middle event of
  sq06_loops' real log) → **193**; `--stats` twice → **byte-identical** (`EVN=944 WIT=9bbf9c20e8c8c85e`).

## 5. WHAT THIS IS — AND IS NOT (locked scope)

- **IS:** the waist's execution semantics carried by an event-primary bearer: the log alone (plus the
  module's constant data image) determines output, result, witness, and any past state; every claim
  is re-derived and checked by a second engine that shares only the semantics doors (`ebinop`,
  memory load/store) with the producer. It is the fourth meaning-bearer (native ≡ eval ≡ svir_interp
  ≡ **svir_event**) on the square theater, differential-pinned.
- **IS NOT:** a replacement for `svir_interp` (route S remains the reference; V is the ground-of-record
  formulation), a non-termination prover (192 is an observed-recurrence report), or a cryptographic
  audit chain (the witness is fold-grade; involution/mhash own sealing). The impure CRT surface
  (fopen/fread/system/…) is refused by name — the deterministic tier only; this keeps route V inside
  the closed/offline law (`III-BEYOND-DETERMINISM` L4) that replay requires.
- **CAPACITY:** 4M events (128 MB log columns) — every square probe fits with 3 orders of margin
  (max observed 1,763); capacity exhaustion is the named 190/192 refusal, and the gate prints
  EXCLUDED-BY-CAPACITY loudly if a future probe outgrows it (anti-vacuity floor 15/17 holds).

## 6. WHY THIS MATTERS (the ontology, one paragraph)

The process-ontology claim — *state is a summary of events, not a substance* — is now load-bearing at
the layer every III route shares. A program's run IS its history; the history is witnessed, replayable,
tamper-evident, prefix-re-derivable, and its recurrences are readable; and a second engine that never
saw the program reproduces the entire observable behavior from the history alone. Route S answers
"what does this module compute?"; route V answers "what happened, such that anything was computed at
all?" — and the gate proves the two answers byte-equal on the production theater.
