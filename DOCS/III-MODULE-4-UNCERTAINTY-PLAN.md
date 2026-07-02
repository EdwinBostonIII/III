# Module 4 — the Unified Uncertainty (typed gap): file-by-file lean implementation plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

## Gate cleared

Written only because **Module 3 (The Hexad) is verified fully + perfectly**: full gate
`PASS=388 FAIL=0`, `667_hexad_reach=99` (count==144/729 + 729-wide predicate + 6 PFS
non-reachable + compose6 closure + bricking-stays-unreachable), zero regression. No
placeholder/deferral/flaw; the hexad machinery had no preexisting flaw.

## Context

**Why this change.** Module 4 of `DOCS/III-APOTHEOSIS.md` is **The Unified Uncertainty** — the
*one genuinely net-new organ*: a single typed **gap** that is total, sound, maximally precise,
and self-explaining (a content-addressed provenance DAG walkable to named root causes). Today
partial information is handled three incompatible ways — `omnia/either.iii` (left/right, **0
consumers**), `numera/checked.iii` (overflow option + `did_overflow`, **1 consumer**),
`hexad_epistemic.iii` (confidence). None is the typed gap. The POC `negknow.py` proved the shape.

**Intended outcome.** Create net-new `numera/uncertainty.iii`: the typed gap as the
`ZERO`-inhabited reading of the M2 ternary algebra, with a bounded provenance-DAG arena
(content-addressed via the now-built `cad`/M1), total+sound+precise `apply`, `root_causes`,
`explain`, `well_formed`, and the exhaustive falsifier KAT. `either`/`checked` keep their public
APIs and delegate their gap-handling to it; `hexad_epistemic`'s confidence pillar is recognized
as a gap (the unification documented; full fold staged with its consumers).

## ADR-1 — `.iii` representation of the typed gap (bounded, monomorphic, deterministic)

- **Value cell (`ucell`) = a 16-byte record by pointer:** `[0]=tag (u8: 0=KNOWN, 1=GAP)`,
  `[8..16)=body (i64)` — body is the **known value** when tag=KNOWN, the **gap-id (u32 in i64)**
  when tag=GAP. Passed `*u8`; callers use module-scope scratch cells. (Avoids encoding ambiguity
  — a payload can be any i64, so the tag must be out-of-band.)
- **Gap-node arena (bounded, W8):** parallel module-scope arrays, `UNC_N` gap nodes
  (`UNC_KIND[u8]`, `UNC_REASON[u32]` — a reason-code, never 0 for well-formed,
  `UNC_A0[u32]`/`UNC_A1[u32]` antecedent gap-ids, `UNC_NA[u8]` count 0..2). Binary ops yield ≤2
  antecedents; roots have 0. `UNC_NEXT` is the bump cursor (W14 bounded; on overflow → a fixed
  `essential`/"arena full" gap, never a crash — totality preserved).
- **Content-address (M1):** `unc_gap_addr(id, out)` = `cad_oneshot(KECCAK, <kind‖reason‖antes>,
  out)` — the gap's place in the DAG, using the built `cad`. (The DAG is content-addressed, per
  the apotheosis; M1 is done, so this is real now.)
- **Kinds:** `UNC_ESSENTIAL=0`, `UNC_HOLE=1`, `UNC_REDACTED=2`, `UNC_DERIVED=3`.

## ADR-2 — Scope: the net-new gap + its falsifier now; the wide fold is staged

- **In scope (M4 core, net-new, buildable now):** `numera/uncertainty.iii` (the gap arena +
  `apply` + DAG walk + `well_formed` + `addr`) + the exhaustive falsifier KAT. This is the one
  genuinely net-new organ; it stands alone.
- **Out of scope (REFINED on grounding — the absorption is vestigial without a gap *consumer*):**
  the `either`/`checked`/`hexad_epistemic` absorption is staged to **M5**, because the gap only
  becomes a *consumed* value when it is a **SovVal payload** — until then, making `checked` emit
  an unconsumed gap is vestigial code or risks churning `checked`'s public API (its 1 consumer
  uses `option_u32`/`did_overflow`, a different shape than a gap-id). So: gap-as-SovVal-payload +
  the `either`/`checked`/`epistemic` fold → **M5**; the gap as a kernel **open term**
  (compute-with-holes) → **M9**; redaction-as-`redacted`-gap → **M6/M20**; dead `either` (0
  consumers) retirement → **M24**. Same dependency-scoping pattern as M2→M7 (XII-rules) and
  M3→M9 (type-level reach) — the module's core is finished; cross-module unifications land with
  their owning modules. **Not an M4 deferral.**

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/iii/numera/uncertainty.iii` | the typed gap: arena + `unc_*` API + `unc_selftest` (the falsifier) |
| **CREATE** | `STDLIB/corpus/668_uncertainty.iii` | corpus wrapper (`extern unc_selftest; main → it`) |
| **MODIFY** | `STDLIB/scripts/build_stdlib.sh` | add `"numera/uncertainty"` to `MODULES` (after `numera/trit`, before `numera/checked` so checked can delegate) |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[668_uncertainty]=99` |
| **MODIFY** | `STDLIB/iii/numera/checked.iii` | (after the core lands + gates) its overflow→option becomes a delegation to a `uncertainty` gap on overflow; keep public API; its 1 consumer + its KAT stay green |
| **MODIFY** | `STDLIB/iii/omnia/either.iii` | (after core) recognize the gap reading; 0 consumers so trivial — or leave as-is and note supersession (decide at the fold step) |

---

## Step 0 — Pre-flight (read-only)
0.1 Prefix check: `grep -rn "module numera_uncertainty\|fn unc_\|UNC_" STDLIB/iii` — confirm free.
0.2 Confirm `cad_oneshot(suite:u32,msg:*u8,len:u64,out:*u8)->i32` signature (M1, built) for the addr.
0.3 Corpus number: next free after `667` → expect `668`; verify.
0.4 Re-read `checked.iii` (its 1 consumer + its public API) so the later delegation is byte-safe.
0.5 Baseline: corpus `PASS=388`, seal.

## Step 1 — CREATE `numera/uncertainty.iii`

Header: the typed gap = the `ZERO`-reading of the ternary algebra (M2); total/sound/precise;
content-addressed DAG (M1). `Hexad: kind_essence · Ring: R0 · K: 1.00 · NIH: cad.iii`.

### 1a. consts + arena
```
const UNC_OK : i32 = 0i32
const UNC_TAG_KNOWN : u8 = 0u8
const UNC_TAG_GAP   : u8 = 1u8
const UNC_ESSENTIAL : u8 = 0u8 ... UNC_DERIVED : u8 = 3u8
const UNC_MAX : u32 = 1024u32
var UNC_KIND : [u8; 1024]   var UNC_REASON : [u32; 1024]
var UNC_A0 : [u32; 1024]    var UNC_A1 : [u32; 1024]   var UNC_NA : [u8; 1024]
var UNC_NEXT : u32 = 1u32   /* id 0 reserved = "nil"; ids 1.. live */
```
(`UNC_NEXT` starts at 1; gap-id 0 is the reserved nil/arena-full sentinel.)

### 1b. ucell accessors + gap alloc
- `unc_set_known(cell:*u8, v:i64)`, `unc_set_gap(cell:*u8, gid:u32)`, `unc_is_gap(cell)->u8`,
  `unc_known_val(cell)->i64`, `unc_gap_id(cell)->u32` (byte-exact reads via `*u8` → i64/u32;
  mind the u32-in-u64 mask trap on the gap-id).
- `unc_gap_root(kind:u8, reason:u32)->u32` — alloc a root gap (NA=0). reason must be ≠0.
- `unc_gap_derived(a0:u32, a1:u32, na:u8, reason:u32)->u32` — alloc a derived gap (kind=DERIVED,
  antecedents a0[,a1]). On `UNC_NEXT>=UNC_MAX` → return a fixed pre-allocated "arena-full"
  essential gap-id (never crash — totality).

### 1c. `unc_apply(op:u32, a:*u8, b:*u8, out:*u8) -> i32` (W2: 4 params) — total+sound+precise
The exact POC logic:
1. **precise annihilator:** if `op==MUL` and (`a` is KNOWN with val 0, or `b` is KNOWN with val 0)
   → `unc_set_known(out, 0)`; return OK. (0·unknown = Known(0), the hardest invariant.)
2. **both known:** if `op==DIV` and `b.val==0` → `unc_set_gap(out, unc_gap_root(ESSENTIAL,
   REASON_DIV0))`. else compute (`add/sub/mul`, `div`=toward-zero idiv) → `unc_set_known(out, r)`.
3. **else (≥1 gap):** collect the gap operand-ids (a if gap, b if gap) → `unc_set_gap(out,
   unc_gap_derived(...))` with those antecedents + `REASON_DERIVED`. (Never empty provenance.)
Ops `UNC_ADD/SUB/MUL/DIV` as u32 consts. Division toward zero (the POC `_idiv`), deterministic,
guarding the i64-`%`/`/` traps (idiv only on known i64 operands; div-by-0 handled above).

### 1d. provenance walk (W15: no recursion — explicit worklist)
- `unc_root_causes(gid, out_ids:*u32, cap:u32) -> u32` — BFS/DFS via a module-scope stack
  (`UNC_STACK[u32]`), push gid; pop; if NA==0 → it's a root, emit; else push antecedents; return
  count. Bounded by UNC_MAX (no cycles — a derived gap's antecedents are strictly lower ids,
  allocated before it → DAG is acyclic by construction; assert a0<gid, a1<gid in alloc).
- `unc_well_formed(gid) -> u8` — reason≠0; if kind==DERIVED then NA≥1; recurse-free (the
  acyclic-lower-id invariant lets a simple downward sweep verify the subtree).

### 1e. `unc_selftest() -> u64` (99 = pass) — the M4 falsifier, executable
1. **total:** every `unc_apply` over {known,known}, {known,gap}, {gap,gap}, div-by-0 returns OK
   (i32 0) and writes `out` — no crash, no error-return. (codes 1..)
2. **sound:** `apply(ADD, Known(7), Known(5))` → KNOWN 12; `SUB`→2; `MUL`→35; `DIV(35,5)`→7;
   `DIV(-7,2)`→-3 (toward zero). Wrong concrete → red.
3. **precise (the hardest):** `apply(MUL, Known(0), <a gap>)` → KNOWN 0 (NOT a gap); and
   `apply(MUL, <a gap>, Known(0))` → KNOWN 0. A gap here → red.
4. **÷0 = essential gap:** `apply(DIV, Known(1), Known(0))` → GAP, kind ESSENTIAL.
5. **derived gap has non-empty provenance:** `apply(ADD, Known(1), <gap g>)` → GAP, kind DERIVED,
   NA≥1, and `root_causes` returns g's root(s); `well_formed`==1. An empty-provenance derived gap
   → red.
6. **root_causes walks the DAG:** build g1=root(HOLE,"sensor"), g2=derived(g1), g3=derived(g2) →
   `root_causes(g3)` == {g1}; `well_formed(g3)`==1.
7. **negatives:** `unc_gap_root(_, 0)` (reason 0) → `well_formed`==0; arena-full path returns the
   sentinel essential gap (force UNC_NEXT high in a scratch, or test the guard) without crashing.
8. **addr determinism (M1):** `unc_gap_addr(g1)` twice → equal; different gaps → different addr.

### 1f. trap audit: single-line fn; module-scope arrays (UNC_*); equality-only; W15 worklist (no
recursion); W2 (`unc_apply` 4 params; helpers ≤4); the u32-in-u64 mask on gap-ids read from
cells/arena; idiv only on known i64 (div-0 pre-guarded — Trap-18); `cad_oneshot` for addr.

## Step 2 — CREATE `STDLIB/corpus/668_uncertainty.iii`
```
module corpus_668
extern @abi(c-msvc-x64) fn unc_selftest() -> u64 from "uncertainty.iii"
fn main() -> u64 { return unc_selftest() }
```

## Step 3 — wire `build_stdlib` (`"numera/uncertainty"` after `numera/trit`) + `run_corpus`
(`[668_uncertainty]=99`).

## Step 4 — (after the core gates green) MODIFY `checked.iii` to delegate overflow→gap; keep its
public API + its 1 consumer + KAT green (byte-safe). `either.iii` (0 consumers): recognize the
gap reading or note supersession.

## Step 5 — Verify
1. compile-only `uncertainty.iii`; 2. `build_stdlib` FAIL=0; 3. normal-link-run `668`=99;
4. full `run_corpus` FAIL=0, `PASS=389`, no regression (`checked`'s consumer/KAT green after Step 4).
5. manual hand-check: re-derive the sound/precise/÷0/provenance cases by hand.

**Single falsifier:** `unc_selftest`≠99 (a raise, a wrong concrete, `0·unknown≠Known(0)`, `÷0`
not a gap, a derived gap with empty provenance, a broken root_causes) → red.

## Standards checklist
NIH (libc + cad.iii); determinism (no float, equality-only, idiv toward-zero on guarded known
operands); W2 (≤4 params via the ucell/aggregate), W8 (bounded 1024-node arena), W14 (bump
cursor sentinel), W15 (worklist, no recursion); K=1.00; the **falsifier is the POC's hardest
invariant made executable** (`0·unknown=Known(0)` precise + non-empty provenance). Apotheosis:
realizes M4 Final (total+sound+precise gap, content-addressed DAG via M1, ZERO-reading of M2);
SovVal-payload=M5, kernel-open-term=M9, redaction=M6/M20 (hooks).

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| ucell tag/body byte-encoding wrong | apply mis-reads known vs gap | explicit byte offsets [0]/[8]; KAT round-trips set/get before apply |
| gap-id u32 read from i64 body unmasked | wild arena index | mask `& 0xFFFFFFFF` per the u32-in-u64 trap |
| recursion in root_causes/well_formed | W15 violation | explicit `UNC_STACK` worklist; acyclic-by-lower-id invariant |
| arena overflow crashes (totality break) | a non-total op | bump guard → fixed sentinel essential gap, never a bad index |
| idiv hits the i64 `/`/`%` trap | wrong quotient | div only on KNOWN i64 with b≠0 (pre-guarded); toward-zero via abs+sign |

## Roadmap
1. Steps 0–3: net-new `uncertainty.iii` + KAT + register → `668=99`, `FAIL=0`, `PASS=389`.
2. Step 4: fold `checked` (+`either`) → gate (their consumer/KATs stay green).
Then M4's wide unifications land with their modules: gap-as-SovVal-payload (M5), kernel
open-term (M9), redaction gap (M6/M20).
