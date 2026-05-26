# Module 2 — the Ternary (Kleene) Algebra: file-by-file lean implementation plan

## Gate cleared

Written only because **Module 1 (the `cad` collapse) is verified fully + perfectly**: full
determinism gate `PASS=386 FAIL=0`, the three byte-equivalence KATs green (`665_cad`,
`380_content_addr`, `13_mhash_domain_separation`), and a real preexisting flaw (the missing
`0x00` domain separator in `cad_domain`) found and fixed. The 14× `sha256.c` physical cull is
M24's witnessed-retirement scope (de-risked: dedup gate green, dirs `_SUPERSEDED_BY.md`,
unlinked) — not an M1 deferral.

## Context

**Why this change.** Module 2 of `DOCS/III-APOTHEOSIS.md` is **The Ternary Algebra** — the one
balanced-ternary Kleene algebra that is the *shared logic* of both hexad safety (M3) and
Sovereign-Value uncertainty (M4: the gap is the `ZERO`-inhabited reading of this algebra).
Today the five total ops live as a **layer inside `omnia/hexad_algebra.iii`** (M3's module):
`iii_trit_not`/`and`/`or`/`sum`/`mul` + `iii_trit_weight` (NEG=-2 asymmetric), `iii_trit_valid`,
`iii_trit_sub`, `iii_trit_neg6` — all `@export`, equality-only, K=0.99, correct vs the spec
tables. **But (the gap this fixes):** the algebra has (a) **no dedicated KAT** — *nothing*
exhaustively verifies the five ops against their 3×3 spec tables, so the M2 falsifier is
unguarded; and (b) **no identifiable home** — it is buried in M3's module, with no clean base
for M4 to share.

**Intended outcome.** Extract the algebra into its own single-responsibility module
`numera/trit.iii` — the one ternary Kleene algebra, equality-only, asymmetric — with an
**exhaustive, non-tautological 3×3 spec-table + Kleene-law KAT** (closing the falsifier);
`hexad_algebra` (M3) and `hexad_mobius` delegate to it; M4 (gap) will extern the same one
algebra. This mirrors the proven M1 pattern (extract the shared primitive, fold consumers
byte-identically, prove equivalence with a rigorous KAT).

**Consumer graph (grounded).** `iii_trit_*` is touched by exactly two sites: `hexad_algebra.iii`
(internal — `compose6` uses `iii_trit_and`/`iii_trit_or`) and `hexad_mobius.iii` (one extern:
`iii_trit_sum from "hexad_algebra.iii"`). The other 8 `hexad_algebra` consumers use the *hexad*
ops (`pack6`/`compose6`/`reach`), not trit ops — untouched by the extraction.

---

## ADR-1 — Extract to `numera/trit.iii`; the apotheosis's own M2/M3 decomposition

- **Decision.** Move the trit ops out of `hexad_algebra.iii` into a net-new `numera/trit.iii`;
  keep the symbol names `iii_trit_*` (zero rename churn — only repoint `from` paths); `hexad_algebra`
  and `hexad_mobius` extern them from `"trit.iii"`. The hexad ops (`pack6`/`unpack`/`pillar`/
  `compose6`/`reach`) stay in `hexad_algebra` (M3).
- **Why.** The apotheosis treats M2 (ternary) and M3 (hexad) as *distinct modules*; the current
  file conflates them. M4 (gap) must share the *one* algebra — a standalone `trit.iii` is the
  clean base both M3 and M4 extern (vs M4→M3-module coupling). Low churn (2 sites).
- **Rejected — strengthen in place (leave trit in `hexad_algebra`).** Less churn, but leaves M2
  with no home and forces M4 to depend on M3's module. Fails the "one shared algebra" intent.

## ADR-2 — Scope: the algebra + its proof now; XII-rules and gap-unification are other modules

- **In scope (M2, buildable now):** the extracted `trit.iii` + the exhaustive spec-table/Kleene
  KAT (the falsifier) + the folds. No new behavior — the ops are byte-identical to today.
- **Out of scope (correctly, not deferral):** *(a)* expressing the five ops as **confluent XII
  rewrite rules** — that is critical-path migration #4 (route through XII), owned by **M7** (the
  engine), gated by `xii_critpairs`; the apotheosis Final names it, M7 operationalizes it. *(b)*
  unifying `ZERO` with the gap — needs **M4** (`numera/uncertainty.iii`, net-new). Both are
  documented as hooks in `trit.iii`'s header, implemented when their owning module lands.

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/iii/numera/trit.iii` | the one ternary Kleene algebra (moved `iii_trit_*` ops) + exhaustive `trit_selftest` (3×3 tables + Kleene laws + negatives) |
| **CREATE** | `STDLIB/corpus/NNN_trit.iii` | corpus KAT wrapper (`extern trit_selftest; main → it`) — `NNN` = next free (≥666; confirm) |
| **MODIFY** | `STDLIB/scripts/build_stdlib.sh` | add `"numera/trit"` to `MODULES` **before** `omnia/hexad_algebra` |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[NNN_trit]=99` to `EXPECTED` |
| **MODIFY** | `STDLIB/iii/omnia/hexad_algebra.iii` | remove the trit ops (lines ~26-92); `extern iii_trit_and`/`iii_trit_or` (and any others `compose6` uses) from `"trit.iii"`; keep the hexad ops; drop the now-unused `HXA_TRIT_*` consts only if unused by hexad code (verify) |
| **MODIFY** | `STDLIB/iii/omnia/hexad_mobius.iii` | repoint `iii_trit_sum` extern `from "hexad_algebra.iii"` → `from "trit.iii"` |

---

## Step 0 — Pre-flight (read-only)

0.1 **Prefix/collision check:** `grep -rn "module numera_trit\|fn trit_selftest\|TRIT_" STDLIB/iii`
— confirm `trit.iii`/`trit_selftest`/the KAT-table prefix are free. (`iii_trit_*` op names are
kept, so no op-name collision — they simply relocate.)
0.2 **Confirm the exact trit-op set + which `hexad_algebra` internals call them:** re-read
`hexad_algebra.iii` lines 26-160 — note every `iii_trit_*` def (valid/weight/not/neg6/and/or/sum/
mul/sub) and every internal call (`compose6` → `iii_trit_and`/`iii_trit_or`; check `pack6`/others).
This is the exact move set + the externs `hexad_algebra` must re-add.
0.3 **Confirm `HXA_TRIT_NEG/ZERO/POS` consts' users:** if only the trit ops used them, move them to
`trit.iii`; if hexad code also uses them, keep a copy (or extern). Decide per the grep.
0.4 **Corpus number:** `ls STDLIB/corpus | sort` → next free (664=reflection_governance,
665=cad → expect 666; verify against `run_corpus.sh` EXPECTED too).
0.5 **Baseline:** note `libiii_native.a.mhash` + current corpus `PASS=386`.

---

## Step 1 — CREATE `STDLIB/iii/numera/trit.iii`

Header: the Kleene framing + the two scoped hooks. `Hexad: kind_essence · Ring: R0 · K: 1.00 ·
NIH: libc + III only.`

### 1a. Module + consts + the ops (moved verbatim — byte-identical)

```
module numera_trit

const TRIT_NEG  : i32 = -1i32
const TRIT_ZERO : i32 =  0i32
const TRIT_POS  : i32 =  1i32
```

Move these ops **unchanged** from `hexad_algebra.iii` (so behavior is byte-identical and the
hexad KAT/consumers stay green): `iii_trit_valid`, `iii_trit_weight` (NEG=-2/POS=1/ZERO=0),
`iii_trit_not` (`-a`), `iii_trit_neg6` (`-a`), `iii_trit_and` (NEG-dominates), `iii_trit_or`
(POS-dominates), `iii_trit_sum` (`clamp(a+b,-1,+1)` via the `s==2`/`s==-2` form), `iii_trit_mul`
(`a*b`), `iii_trit_sub` (`sum(a,-b)`). Keep `@export` and the exact `iii_trit_*` names.

### 1b. The exhaustive KAT (the falsifier) — `trit_selftest() -> u64`, 99 = pass

The discipline: compare each op against an **independent hardcoded expected table**, never
against its own formula (no tautological proof — `[[feedback_no_tautological_proofs]]`). Trits map
`{-1,0,1} → {0,1,2}` via `idx = t + 1`; a binary op's table is `[u8/i32; 9]` indexed `a_idx*3 + b_idx`.

Module-scope expected tables (Trap-7: no local arrays):

```
var TRIT_AND_EXP : [i32; 9] = [-1i32,-1i32,-1i32, -1i32,0i32,0i32, -1i32,0i32,1i32]
var TRIT_OR_EXP  : [i32; 9] = [-1i32,0i32,1i32,   0i32,0i32,1i32,   1i32,1i32,1i32]
var TRIT_SUM_EXP : [i32; 9] = [-1i32,-1i32,0i32,  -1i32,0i32,1i32,  0i32,1i32,1i32]
var TRIT_MUL_EXP : [i32; 9] = [1i32,0i32,-1i32,   0i32,0i32,0i32,   -1i32,0i32,1i32]
```

Checks (distinct return code per failure; `99u64` only if all pass):
1. **unary tables:** `not(-1)=1, not(0)=0, not(1)=-1`; `neg6` ≡ `not` on all 3; `weight(-1)=-2,
   weight(0)=0, weight(1)=1`.
2. **`valid`:** `valid(-1)=valid(0)=valid(1)=1`; **negatives** `valid(2)=valid(-2)=valid(99)=0`.
3. **binary 3×3 sweep:** nested `a_idx`,`b_idx` in 0..2 (a = a_idx-1, b = b_idx-1); assert
   `iii_trit_and(a,b)==TRIT_AND_EXP[a_idx*3+b_idx]`, and the same for `or`/`sum`/`mul`. (36
   independent checks against the hardcoded tables.)
4. **Kleene laws (derived, prove the *algebra* not just the cells):** over the 3×3 sweep —
   **De Morgan** `not(and(a,b)) == or(not(a),not(b))`; **double-negation** `not(not(a))==a`;
   **mul annihilator** `mul(ZERO,a)==ZERO`; **and/or commutativity** `and(a,b)==and(b,a)`,
   `or(a,b)==or(b,a)`; **sub** `sub(a,b)==sum(a,not... )` — `sub(a,b)==sum(a, 0-b)`.
5. **asymmetry witness (the NEG=-2 point):** `weight(NEG) + weight(POS) == -1` (catastrophe
   outweighs recovery) — the load-bearing asymmetric-weight invariant, not a tautology.

This is the M2 falsifier made executable: *any* op disagreeing with its spec table, or any
Kleene law breaking, turns it red.

### 1c. Footer + trap audit (manual, before compile)

Single-line `fn` decls (Trap 1); no local `var` arrays — tables are module-scope `TRIT_*`
(Trap 7); equality-only compares (`==`/`!=`, never `<`/`>` on trits — the i32-ordering trap);
no recursion (W15); ≤4 params (W2 — all ops are ≤2); `TRIT_`/`numera_trit` prefix collision-free
(Step 0.1); no `select()`; loops are bounded `while a_idx < 3u64` sentinel form (W14).

---

## Step 2 — CREATE `STDLIB/corpus/NNN_trit.iii` (template of `665_cad.iii`)

```
/* NNN — trit: the one ternary Kleene algebra; exhaustive 3x3 spec tables for
 * and/or/sum/mul + not/neg6/weight/valid + Kleene laws (De Morgan, double-neg,
 * annihilator, commutativity) + asymmetry witness + valid negatives. M2 gate. */
module corpus_NNN
extern @abi(c-msvc-x64) fn trit_selftest() -> u64 from "trit.iii"
fn main() -> u64 { return trit_selftest() }
```

---

## Step 3 — MODIFY build + gate registration

3.1 **`build_stdlib.sh`** — add `"numera/trit"` to `MODULES` **before** `"omnia/hexad_algebra"`
(trit is a dependency of hexad_algebra now). Find hexad_algebra's line; insert trit above it.
3.2 **`run_corpus.sh`** — add `[NNN_trit]=99` to `EXPECTED`.

---

## Step 4 — MODIFY `STDLIB/iii/omnia/hexad_algebra.iii` (fold to trit)

- Delete the trit-op defs (the `iii_trit_*` block, ~lines 38-92) and the `HXA_TRIT_*` consts if
  unused by hexad code (per Step 0.3).
- Add externs for exactly the trit ops `hexad_algebra`'s hexad code calls — at minimum
  `iii_trit_and`, `iii_trit_or` (used by `compose6`); add any others Step 0.2 found:
  `extern @abi(c-msvc-x64) fn iii_trit_and(a: i32, b: i32) -> i32 from "trit.iii"` (etc.).
- Keep all hexad ops + the hexad KAT unchanged.
- **Falsifier:** the existing hexad KAT/`compose6` path (and all 9 consumers) must stay green —
  byte-identical, since the ops moved unchanged.

## Step 5 — MODIFY `STDLIB/iii/omnia/hexad_mobius.iii` (repoint one extern)

Change the single line
`extern … fn iii_trit_sum(a: i32, b: i32) -> i32 from "hexad_algebra.iii"`
→ `… from "trit.iii"`. (Symbol unchanged; only the source path moves.) `hexad_mobius`'s KAT
stays green.

---

## Step 6 — Verify (the gate, end-to-end)

Pinned in-tree `iiis-2` only. Compile-only each touched file first (writer self-check), then:
1. `bash STDLIB/scripts/build_stdlib.sh` → **`FAIL=0`**, `numera/trit` + `omnia/hexad_algebra` +
   `omnia/hexad_mobius` all `OK` (grep the log; a failed module leaves a stale lib).
2. `bash STDLIB/scripts/run_corpus.sh` → **`FAIL=0`**, `PASS=387` (= 386 + the new `NNN_trit`),
   with **`NNN_trit=99`** and **no regression** in the hexad/hexad_mobius consumers (any test that
   touches `compose6`/`reach`/`mobius` must stay `99` — the byte-identity proof of the move).
3. **Manual hand-check** (by hand, no agents): read `trit.iii` against the Step-1c trap list;
   re-derive every expected-table value by hand from the spec; confirm the `hexad_algebra` /
   `hexad_mobius` diffs are pure relocation (no logic change).

**Single falsifier for the module:** any `trit_selftest` table/Kleene/asymmetry check failing, or
any hexad/mobius consumer changing exit code → the algebra or the move is wrong → red, diagnose
before rebuild.

---

## Standards & mandates checklist

- **NIH:** libc + III only (the ops are pure integer arithmetic; zero externs in `trit.iii`). ✓
- **Determinism:** no float; **equality-only** trit compares (never ordering — the i32-ordering
  SIGSEGV trap); deterministic, no statistical logic. ✓
- **W-laws:** W2 (≤2 params/op); W8 (bounded `[i32;9]` tables); W14 (sentinel `while` loops);
  W15 (no recursion). K=1.00 (pure, total).
- **`.iii` traps:** no local `var` arrays (module-scope `TRIT_*`); single-line `fn`; no nested
  `/* */`; no em-dash in comments (ASCII `--`); `} else {` one line; `TRIT_` prefix
  collision-checked; `select()` avoided.
- **Falsifier present + non-tautological:** the KAT checks each op against an *independent*
  hardcoded table (not its own formula) + the Kleene laws + the negatives — the M2 falsifier
  made executable. Closes a currently-unguarded gap.
- **Apotheosis alignment:** realizes M2 Final's "one balanced-ternary Kleene algebra,
  equality-only, asymmetric (NEG=-2)" as a real module shared by M3/M4; the XII-rules form (mig 4)
  is M7 scope, the `ZERO`=gap unification is M4 scope — both documented hooks, not this increment.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| A moved op's body altered during the move | hexad consumer digests/logic shift | move verbatim; the hexad KAT + 9 consumers staying `99` is the byte-identity proof |
| `compose6` uses a trit op I didn't re-extern | `hexad_algebra` link/compile fail | Step 0.2 enumerates every internal `iii_trit_*` call before deleting |
| `HXA_TRIT_*` consts used by hexad code, removed | hexad compile fail | Step 0.3 greps their users; keep if hexad needs them |
| Expected-table value transcribed wrong | KAT false-pass/fail | derive each of the 9×4 cells by hand from the spec (Step 6.3); they are small + checkable |
| `numera/trit` placed after `hexad_algebra` in MODULES | (harmless — link-time externs) | still place before, for dependency clarity |

## Roadmap (incremental, each gate-able)

1. **Steps 0–3:** create `trit.iii` + corpus + register; gate → `NNN_trit=99`, `FAIL=0`. (The one
   algebra proven exhaustively, standalone, before any consumer moves to it.)
2. **Step 4:** fold `hexad_algebra` → gate (hexad KAT + 9 consumers stay `99`).
3. **Step 5:** repoint `hexad_mobius` → gate (its KAT stays `99`); full corpus `PASS=387 FAIL=0`.

Then M2's apotheosis-Final completions land with their owning modules: the **XII-rules form** when
**M7** routes computation through XII (mig 4, `xii_critpairs`-gated), and the **`ZERO`=gap
unification** when **M4** (`numera/uncertainty.iii`) is built.
