# Module 9 — the Proof Kernel: file-by-file lean implementation plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

## Gate cleared

Written only because **Module 8 (SID & Reversibility) is verified fully + perfectly**: main
corpus `bbkwp8bws` `FAIL=0` with `671_hexad_mobius=99` (the exhaustive 729-hexad Möbius
round-trip falsifier — involution two ways + negatives + floor) and the M3/reversibility
regression set `{667,666,634,649,101,102,103}` + `670` all `=99` and no registered file
missing; `run_xii 93/0`; build `FAIL=0`; `forge_check` green (a preexisting census-ledger
drift root-caused + legitimately re-sealed). No placeholder/deferral/flaw.

## Context

`DOCS/III-APOTHEOSIS.md` Module 9 — "The Proof Kernel." `TYPES/src/cic.c` (C, 888 lines) is
**already a full Calculus of Inductive Constructions kernel**: de-Bruijn terms, β/ζ/δ/ι/η
reduction, a seven-level predicative/impredicative universe (no `Type:Type`), and **seven
built-in inductives** — including **`Trit` (ctors NEG/ZERO/POS = M2)** and **`Hexad` (one
arity-6 ctor over six `Trit`s = M3, built on M2 *inside the kernel*)**. The `.iii` proof organs
are the Curry–Howard *certificate* layer, all gated:
`numera/proof_carrying.iii` (Merkle/polynomial commitments + certificates, `639=99`),
`numera/proof_term.iii` (propositional inference-rule proof-term checker — MP/transitivity
replay, `636=99`), `numera/theorem_carrier.iii` (theorems bundling a verified proof-term +
dependency closure, `647=99`). **None of these is the CIC kernel** — `cic.c` is — and
`numera/kernel.iii` (the in-language port) does **not** exist.

**The apotheosis Depth-D1 names the keystone exactly:** *"Three of III's core ontologies are
already CIC inductives — the safety algebra (`Trit`/`Hexad`)… 'Make safety a type' is not a
distant frontier; the kernel types it today. **What remains is to bind the runtime hexad (M3
`reach`) to the `Hexad` inductive so a non-reachable composition is rejected by ι-reduction
rather than a bitmap.**"* The Key Move: *"to admit a proof — `iii_term_typecheck` (Term → Type |
⊥)."* Falsifier: *"a closed inhabitant of ⊥; **a `Hexad` term accepted whose six trits compose
to a non-reachable pattern**; a `Type:Type` acceptance; a SovVal record that type-checks under
an over-K `Cost` refinement → red."*

**Honest scope (the apotheosis insists on it):** *"`cic.c` stays the C trust root until
`numera/kernel.iii` ports it (the honest H13 completion)… the in-language port is the stated
goal, not a faked claim."*

## ADR-1 — Scope: the lean keystone is the inductive *safety-typing judgment* (M3 reach as a type rule), in a new honestly-named fragment; the full CIC port is the deferred H13 goal

- **Decision.** Module 9 = a new `numera/safety_type.iii` realizing the named "what remains":
  the **Trit and Hexad inductives' typing judgments**, with **M3 `reach` as the Hexad
  constructor's well-formedness rule** — so a non-reachable Hexad term is **⊥ (a type error)**,
  not merely a `reach`-bitmap miss. This pays the **M2 + M3 debt at the type level** and closes
  apotheosis falsifier clause #2 ("a Hexad term accepted whose six trits compose to a
  non-reachable pattern → red") for the `.iii` side. Exhaustive over all 729 hexads.
- **Rejected — create a `numera/kernel.iii` claiming the full CIC port.** The apotheosis is
  explicit: that port is the H13 *goal*, "not a faked claim"; `cic.c` remains the trusted C
  root. A 70-line fragment named `kernel.iii` would mis-signal a ported kernel. So the module
  is named `safety_type.iii` (it types the safety algebra) and its header states plainly that
  β/ζ/δ/ι/η, universes, Π, the dependent-record SovVal, and gaps-as-open-terms are the
  cic.c-anchored H13 continuation — **not** done here.
- **Rejected — edit `cic.c`.** It is the trusted-bootstrap C kernel (Ring R-2/R-1), the SID/CIC
  analogue the apotheosis keeps in C; out of stdlib-`.iii` scope and high-risk.
- **Rejected — bolt the judgment onto `proof_term`/`theorem_carrier`.** Those are *propositional*
  (inference-rule replay), a different domain from CIC inductive typing; a focused module is
  cleaner and doesn't muddy their audited checkers.
- **Consequence.** The Pass-2 compound — SovVal as a CIC dependent record (`sv_op`'s refusal =
  type error), the gap (M4) as an open term, every emitted artifact carrying a cic-checked proof
  term — lands with the **H13 `numera/kernel.iii` port** (and M10 for the constitution gate),
  exactly as the apotheosis routes it. Net: `PASS = corpus + 1`.

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/iii/numera/safety_type.iii` | the inductive safety-typing judgment: `safety_trit_judge` (M2 Trit well-formedness), `safety_hexad_judge` (packed Hexad: M3 reach as the typing rule), `safety_hexad_term_judge` (constructor-term `hexad(t₁…t₆)`: each `tᵢ` a Trit, then composed-reachable), `safety_type_selftest` (99=pass). |
| **CREATE** | `STDLIB/corpus/672_safety_type.iii` | corpus KAT wrapper (`extern safety_type_selftest; main → it`). |
| **MODIFY** | `STDLIB/scripts/build_stdlib.sh` | add `"numera/safety_type"` to `MODULES` (after `numera/hexad`-family deps / before consumers; it depends on `omnia/hexad_reach` + `omnia/hexad_algebra`). |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[672_safety_type]=99` to `EXPECTED` (after `[671_hexad_mobius]=99`). |
| **KEEP** | `omnia/hexad_reach.iii`, `omnia/hexad_algebra.iii`, `numera/trit.iii`, `proof_*`/`theorem_carrier`, `TYPES/src/cic.c` | the proven inductives/reach `safety_type` judges over — untouched. |

## ADR-2 — The verdict lattice (equality-compared, no ordering)

`SAFETY_TYPE0 : i32 = 0` (well-typed — the type `Type₀`); `SAFETY_BOT_UNREACHABLE : i32 = -1`
(⊥ — a non-reachable Hexad: the safety violation); `SAFETY_BOT_MALFORMED : i32 = -2` (⊥ — an
ill-formed Trit, or a packed Hexad ≥ 729). Verdicts are compared with `==`/`!=` only (the i32
ordering trap forbids `<`/`>`). Two distinct ⊥ codes so the falsifier can assert *which* ⊥.

## Step 0 — Pre-flight (read-only)

0.1 `glob STDLIB/corpus/672_*.iii` → empty (`671_hexad_mobius` is the current max). 0.2
`grep -rn "SAFETY_\|fn safety_\|numera_safety_type" STDLIB/iii` → confirm the `SAFETY_`/`safety_`
prefix + module name are free (Trap 2). 0.3 Confirm the externs' signatures:
`iii_hexad_reachable(h:u16)->u8` + `iii_hexad_reachable_count()->u64` (`hexad_reach.iii`),
`iii_hexad_pack6(addr:u64)->u16` + `iii_hexad_unpack6(h:u16,addr:u64)->u8` (`hexad_algebra.iii`).
0.4 Baseline: `run_corpus FAIL=0`, `run_xii 93/0`.

## Step 1 — CREATE `STDLIB/iii/numera/safety_type.iii`

```
module numera_safety_type
extern @abi(c-msvc-x64) fn iii_hexad_reachable(h: u16) -> u8 from "hexad_reach.iii"
extern @abi(c-msvc-x64) fn iii_hexad_reachable_count() -> u64 from "hexad_reach.iii"
extern @abi(c-msvc-x64) fn iii_hexad_pack6(pillars_addr: u64) -> u16 from "hexad_algebra.iii"
extern @abi(c-msvc-x64) fn iii_hexad_unpack6(h: u16, out_addr: u64) -> u8 from "hexad_algebra.iii"

const SAFETY_TYPE0           : i32 =  0i32
const SAFETY_BOT_UNREACHABLE : i32 = -1i32
const SAFETY_BOT_MALFORMED   : i32 = -2i32
const SAFETY_HEXAD_MAX       : u16 = 729u16

/* Trit inductive well-formedness (= M2): a Trit is exactly {NEG,ZERO,POS} = {-1,0,+1}. */
fn safety_trit_judge(v: i32) -> i32 @export {
    if v == -1i32 { return SAFETY_TYPE0 }
    if v == 0i32  { return SAFETY_TYPE0 }
    if v == 1i32  { return SAFETY_TYPE0 }
    return SAFETY_BOT_MALFORMED
}
/* Packed Hexad typing: an out-of-range packing is ill-formed; M3 reach is the typing rule
 * (a non-reachable Hexad is bottom, not a bitmap miss). */
fn safety_hexad_judge(h: u16) -> i32 @export {
    if h >= SAFETY_HEXAD_MAX { return SAFETY_BOT_MALFORMED }
    if iii_hexad_reachable(h) == 0u8 { return SAFETY_BOT_UNREACHABLE }
    return SAFETY_TYPE0
}
/* Constructor-term typing of hexad(t1..t6): each constituent a well-typed Trit (M2), THEN the
 * composed Hexad reachable (M3) -- the "ι-reduction rather than a bitmap". 1 param (W2). */
fn safety_hexad_term_judge(trits_addr: u64) -> i32 @export {
    let p : *i32 = trits_addr as *i32
    let mut bad : u8 = 0u8
    let mut i : u64 = 0u64
    while i < 6u64 {
        if safety_trit_judge(p[i]) != SAFETY_TYPE0 { bad = 1u8 }
        i = i + 1u64
    }
    if bad == 1u8 { return SAFETY_BOT_MALFORMED }
    let h : u16 = iii_hexad_pack6(trits_addr)
    if iii_hexad_reachable(h) == 0u8 { return SAFETY_BOT_UNREACHABLE }
    return SAFETY_TYPE0
}
```

Plus a module-scope `var SAFETY_KAT_TRITS : [i32; 6]` and `safety_type_selftest()->u64`:
1. Trit: `judge(-1/0/1)==TYPE0`; `judge(2)/judge(-2)/judge(127)==BOT_MALFORMED` (codes 1–6).
2. **Hexad EXHAUSTIVE** over `h in [0,729)`: `safety_hexad_judge(h) == (reachable(h) ? TYPE0 :
   BOT_UNREACHABLE)` (codes 7–8); count the `TYPE0` verdicts and assert
   `== iii_hexad_reachable_count()` (code 10) — the typing/reach binding is exact, not hardcoded;
   and the packed view agrees with the constructor-term view: `safety_hexad_term_judge(unpack6(h))
   == safety_hexad_judge(h)` (code 9, two independent paths).
3. Out-of-range Hexad ⊥-MALFORMED: `judge(729)/judge(1000)==BOT_MALFORMED` (codes 11–12).
4. **The named falsifier (negative):** a constructor term with a malformed Trit is ⊥-MALFORMED
   *before* reach (M2 gate fires first): `unpack6(0)` then set `TRITS[0]=2`; assert
   `term_judge==BOT_MALFORMED` (code 13). And implicitly via code 8: a non-reachable composition
   is ⊥-UNREACHABLE, never accepted.
5. `return 99u64`.

## Step 1f — In-file trap audit (before compile)

Single-line `fn`s; no local `var` arrays (only module-scope `SAFETY_KAT_TRITS`); `&SAFETY_KAT_TRITS
as u64` for the address (never `&ARR[0]`); equality-only compares (verdicts + trit values via
`==`; the loop counter `i < 6u64` and `h < 729u64` are **unsigned** ordering, house-accepted;
`h >= SAFETY_HEXAD_MAX` is **u16** unsigned, safe); monomorphic `if`-cascade (no `||`, no
fn-pointer, no `select`); `SAFETY_` prefix collision-checked; ≤4 params every fn; W14 bounded
sentinel loops, W15 no recursion.

## Step 2–4 — corpus + registration

`672_safety_type.iii`: `module corpus_672` / `extern safety_type_selftest()->u64 from
"safety_type.iii"` / `main → it`. Add `"numera/safety_type"` to `build_stdlib.sh` MODULES;
`[672_safety_type]=99` to `run_corpus.sh`.

## Step 5 — Verify (the gate)

Pinned `COMPILED/iiis-2.exe`. (1) compile-only `safety_type.iii` + `672` → `rc=0`. (2)
`build_stdlib.sh` → `FAIL=0`, `safety_type` aggregated (+ `forge_check` green — watch the
OneDrive-sync hazard: if it FATALs on a forge-closure violation, re-verify the drifted katabasis
artifact is legitimate then re-seal per `forge_check.sh --print`). (3) `run_corpus.sh` →
`FAIL=0`, `672_safety_type=99`, regression set unchanged — esp. `667_hexad_reach=99`,
`666_trit=99`, `671_hexad_mobius=99`, `639/636/647` (proof layer) `=99`. (4) `run_xii 93/0`.
(5) Manual hand-check: re-derive that the `TYPE0` count equals `iii_hexad_reachable_count()` and
that `term_judge`'s M2 gate precedes the M3 reach check.

**Single falsifier:** `672_safety_type ≠ 99`, or any regression-set test changing exit code, or
`run_xii` regressing → red, revert, diagnose before any rebuild.

## Standards & mandates

NIH (libc + III `hexad_reach`/`hexad_algebra`/`trit`); determinism (no float; equality-only
verdicts/trits; monomorphic dispatch; no statistical logic); W2 (≤1 param each), W8 (`<729`,
`<6`, `[i32;6]`), W14 (sentinel loops), W15 (no recursion); falsifier exhaustive (729 hexads +
the Trit domain) + the named negative (non-reachable/malformed term ⊥) + the count-binding to
M3. K 1.00 (pure). Apotheosis: realizes M9 Pass-1 ("make safety a type"; bind M3 reach to the
Hexad inductive; closes falsifier clause #2 for the `.iii` side); the full CIC port + SovVal
dependent record + gaps-as-open-terms deferred to the H13 `numera/kernel.iii` per the honest
scope.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| reachable-count ≠ 144 (my assumption) | code 10 fails | assert against `iii_hexad_reachable_count()` (not a literal) — self-consistent with M3 |
| `pack6(unpack6(h)) ≠ h` | code 9 fails | base-3 pack/unpack is a proven round-trip for `h<729` (M3, `667`) |
| over-reach (faking the kernel) | violates honest scope | named `safety_type`, not `kernel`; header states the H13 deferral explicitly |
| OneDrive sync re-drifts forge-closure | build FATAL | re-seal per the documented forge_check `--print` flow; gate is the safety net |

## Roadmap

1. Steps 0–4: create the module + corpus + register.
2. Step 5: gate → `672_safety_type=99`, `FAIL=0`, `run_xii 93/0`, no regression.
