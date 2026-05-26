# Module 3 — the Hexad (safety type): file-by-file lean implementation plan

## Gate cleared

Written only because **Module 2 (the Ternary Algebra) is verified fully + perfectly**: full
gate `PASS=387 FAIL=0`, `666_trit=99` (exhaustive 3×3 spec tables + Kleene laws + asymmetry +
valid negatives), zero regression in any hexad consumer. No placeholder/deferral/flaw.

## Context

**Why this change.** Module 3 of `DOCS/III-APOTHEOSIS.md` is **The Hexad** — the universal
6-trit safety type whose `reach` (144/729) and `pfs` make catastrophe *unrepresentable*. The
machinery is built and **correct** (verified by reading, below) across six modules:
`hexad_algebra` (pack/compose6/add/sub/mul, now over `trit.iii`), `hexad_reach` (the 144-byte
admission bitmap), `hexad_pfs` (the 6 bricking ops), `hexad_epistemic`, `hexad_mobius`,
`hexad_dynamic`. **The gap (this fixes):** there is **no dedicated KAT** for the M3 Final
falsifier — *nothing* exhaustively proves "exactly 144 of 729 reachable", "the 6 PFS ops are
non-reachable (bricking untypable)", or "compose6 stays in the reachable set". Same unguarded
pattern as M1/M2.

**Correctness pre-verified (no preexisting flaw):** `hexad_reach.iii` admits a hexad iff no NEG
in pillars 1..4 (idx 0..3) → `2^4·3^2 = 144`, then clears the 6 PFS hexads (a no-op, since each
PFS op sets a NEG in pillars 0..3 — confirmed in `hexad_pfs._hxp_fill`). PFS op enum is 1-based
(0=none, 1..6 valid, `HXP_PFS_COUNT=7`); `reach`'s `op=1; op<7` loop is consistent — **no
off-by-one**. So M3 needs *no code fix* — only the falsifier wired.

**Intended outcome.** Add `iii_hexad_reach_selftest()` to `hexad_reach.iii` (it owns the bitmap
+ already externs `unpack6`/`pfs`) — an exhaustive, non-tautological safety KAT — plus a corpus
test. Additive only; the six hexad modules are untouched (no extraction — the hexad is already
modular, unlike M2's buried trit layer).

## ADR-1 — Additive falsifier (no refactor); KAT lives in `hexad_reach`

- **Decision.** M3's increment is *only* the exhaustive safety KAT, added to `hexad_reach.iii`
  (the reachability owner) + a corpus wrapper. No module is moved or rewritten.
- **Why.** The hexad is already a clean 6-module decomposition; the apotheosis M2/M3 split is
  satisfied. The only deficit is verification. Mirrors M1/M2's "close the falsifier" discipline.

## ADR-2 — Scope: the safety falsifier now; facet-unifications and type-lift are other modules

- **In scope (M3, buildable now):** prove the M3 Final falsifier — reach=144/729 (+ the 729-wide
  predicate), the 6 PFS non-reachable, compose6 closure.
- **Out of scope (correctly, not deferral — documented hooks):** *(a)* `reach` becomes a
  **type error** (the `Hexad` CIC inductive) → migration #2 + **M9** (SovVal-as-inductive); the
  runtime bitmap is M3's current form. *(b)* `epistemic` ⊂ the gap → **M4**. *(c)* `mobius` ⊂
  SID → **M8**. *(d)* `dynamic` promotion ⊂ the Constitution → **M10**. *(e)* delete
  `HEXAD/src/*.c` ancestors → **M24** (witnessed retirement, like M1's `sha256.c`).

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **MODIFY** | `STDLIB/iii/omnia/hexad_reach.iii` | add `extern iii_hexad_compose6` (from hexad_algebra) + `extern iii_hexad_pfs_kind` (from hexad_pfs); add `iii_hexad_reach_selftest() -> u64` (the exhaustive safety KAT) |
| **CREATE** | `STDLIB/corpus/667_hexad_reach.iii` | corpus wrapper (`extern iii_hexad_reach_selftest; main → it`) |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[667_hexad_reach]=99` to `EXPECTED` (hexad_reach is already in MODULES) |

(`hexad_reach` is already built — no `build_stdlib` MODULES change.)

---

## Step 0 — Pre-flight (read-only)

0.1 Confirm `hexad_reach.iii` has no existing `selftest`/`_kat` (it does not) and `iii_hexad_reachable`/`iii_hexad_reachable_count`/`iii_hexad_pfs` signatures (verified above).
0.2 Confirm `iii_hexad_compose6(a:u16,b:u16)->u16` and `iii_hexad_pfs_kind(h:u16)->u32` exact signatures (for the new externs).
0.3 Corpus number: next free after `666_trit` → expect `667`; verify against `ls STDLIB/corpus` + `run_corpus.sh`.
0.4 Baseline: corpus `PASS=387`, seal `libiii_native.a.mhash`.

---

## Step 1 — MODIFY `STDLIB/iii/omnia/hexad_reach.iii` (add the exhaustive safety KAT)

Add two externs after the existing ones:
```
extern @abi(c-msvc-x64) fn iii_hexad_compose6(a: u16, b: u16) -> u16 from "hexad_algebra.iii"
extern @abi(c-msvc-x64) fn iii_hexad_pfs_kind(h: u16) -> u32 from "hexad_pfs.iii"
```
Add a scratch reuse of `HXR_TRITS` (the module already has `[i32;6]`) for the predicate check.

`iii_hexad_reach_selftest() -> u64` (99 = pass), checks:
1. **count == 144** — `iii_hexad_reachable_count() != 144u64` → `return 1u64`. (The `2^4·3^2`
   admission; this also proves the 6 PFS clears were no-ops, i.e., PFS ⊆ non-admitted.)
2. **729-wide predicate match (exhaustive, non-tautological)** — for `h` in `0..728`: recompute
   the predicate INDEPENDENTLY (`iii_hexad_unpack6(h, &HXR_TRITS)`, then `pred = 1` unless any
   of `HXR_TRITS[0..3] == -1`), and assert `iii_hexad_reachable(h) == pred`. Mismatch → `2u64`.
   (Independent recompute, not the bitmap's own builder — so a builder bug turns it red.)
3. **PFS bricking untypable** — for `op` in `1..6`: `iii_hexad_reachable(iii_hexad_pfs(op)) != 0`
   → `3u64`; and round-trip `iii_hexad_pfs_kind(iii_hexad_pfs(op)) != op` → `4u64`.
4. **compose6 closure** — pick a witness reachable hexad `HPOS` (all-POS = pack of six `+1`,
   reachable). For `h` in `0..728` where `iii_hexad_reachable(h)==1`: assert
   `iii_hexad_reachable(iii_hexad_compose6(h, HPOS))==1`, `iii_hexad_reachable(iii_hexad_compose6(HPOS, h))==1`,
   and `iii_hexad_reachable(iii_hexad_compose6(h, h))==1`. Any non-reachable composite of
   reachables → `5u64`. (Proves AND-on-min preserves non-NEG structural pillars — catastrophe
   cannot be *composed into existence*.)
5. **negative (a constructed bricking composes to non-reachable, as it must)** — compose a PFS
   hexad with `HPOS`: `iii_hexad_reachable(iii_hexad_compose6(iii_hexad_pfs(1), HPOS))` — with
   AND-on-structural, a NEG pillar stays NEG → still non-reachable; assert `== 0` → else `6u64`.
   (Proves you cannot "recover" a bricking hexad into the reachable set by composition.)
   `return 99u64`.

Trap audit: single-line `fn`; `HXR_TRITS` module-scope scratch (no local arrays); equality-only
compares; bounded `while h < 729u64` (W14); no recursion; the `(1u32 << ...)` bit idiom already
in the file uses the `let one : u32 = 1u32` guard (the `(NUM` partial-hexad misparse — reuse it
if any shifts are added; the KAT needs none).

## Step 2 — CREATE `STDLIB/corpus/667_hexad_reach.iii`

```
/* 667 — hexad safety: reach == exactly 144/729 + the 729-wide reachability
 * predicate + the 6 PFS bricking ops non-reachable (untypable) + compose6
 * closure over the reachable set + bricking-stays-unreachable-under-compose.
 * M3 hexad-safety-type gate (closes the previously-unguarded M3 falsifier). */
module corpus_667
extern @abi(c-msvc-x64) fn iii_hexad_reach_selftest() -> u64 from "hexad_reach.iii"
fn main() -> u64 { return iii_hexad_reach_selftest() }
```

## Step 3 — MODIFY `STDLIB/scripts/run_corpus.sh`

Add `[667_hexad_reach]=99` to `EXPECTED` (after `[666_trit]=99`).

---

## Step 4 — Verify (the gate, end-to-end)

Pinned `iiis-2`. Compile-only `hexad_reach.iii` first (writer self-check), then:
1. `bash STDLIB/scripts/build_stdlib.sh` → `FAIL=0`, `omnia/hexad_reach` `OK`.
2. Normal-link-run `667_hexad_reach` → `exit=99` (the exhaustive safety proof on metal).
3. `bash STDLIB/scripts/run_corpus.sh` → `FAIL=0`, `PASS=388` (387 + `667`), `667_hexad_reach=99`,
   and the hexad consumers (`261`/`389`/`390`) + all hexad-using tests stay `99` (no regression —
   the KAT is purely additive, reads-only).
4. **Manual hand-check:** re-derive `144 = 2^4·3^2` by hand; confirm the independent predicate in
   the KAT matches the spec rule (no NEG in pillars 0..3); confirm compose6 closure logic
   (AND=min preserves non-NEG).

**Single falsifier:** `iii_hexad_reach_selftest` returning ≠99 (count≠144, a predicate mismatch,
a PFS op reachable, a reachable-pair composing to non-reachable, or a bricking composing back to
reachable) → red, diagnose.

---

## Standards & mandates checklist

- **NIH:** libc + III only (externs are all in-tree hexad/sha modules). ✓
- **Determinism:** no float; equality-only; deterministic bounded sweeps; no statistical logic. ✓
- **W-laws:** W8 (bounded `[u8;144]` bitmap, `[i32;6]` scratch); W14 (sentinel `while h<729`);
  W15 (no recursion). K=1.00.
- **`.iii` traps:** module-scope scratch (`HXR_TRITS`); single-line `fn`; the `(NUM` partial-hexad
  misparse guarded by `let one : u32 = 1u32` (already in-file); no `select()`.
- **Falsifier present + non-tautological:** the KAT recomputes the reachability predicate
  *independently* (not via the bitmap builder), and proves compose-closure + bricking-exclusion
  — the M3 Final falsifier made executable. Closes a currently-unguarded gap.
- **Apotheosis alignment:** realizes M3 Final's "reach (144/729) + pfs make catastrophe
  unrepresentable" as an executable proof. The type-level lift (reach as a CIC type error) =
  M9/mig-2; `epistemic`/`mobius`/`dynamic` unifications = M4/M8/M10; `HEXAD/src` cull = M24 — all
  documented hooks, not this increment.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| compose6 closure sweep too slow (729 iters × unpack) | KAT runtime | bounded (729, deterministic); witness-partner form (3 composes/h) not full 144² |
| `HPOS` (all-POS) not actually reachable | closure check vacuous | all-POS has no NEG in pillars 0..3 → reachable by the rule; assert `iii_hexad_reachable(HPOS)==1` first |
| independent predicate accidentally mirrors the builder | tautological check | recompute from `unpack6` + the `-1` test directly in the KAT (different code path than `iii_hexad_init`) |
| adding the KAT perturbs `hexad_reach` behavior | consumer regression | additive `@export` fn only; reads-only; the 261/389/390 + full corpus prove no regression |

## Roadmap

1. **Steps 0–3:** add the KAT + corpus + register; gate → `667_hexad_reach=99`, `FAIL=0`,
   `PASS=388`, no regression. (The hexad safety type proven exhaustively.)

Then M3's apotheosis-Final completions land with their owning modules: the **type-level reach**
(reach as a `Hexad`-inductive type error) when **M9** + migration 2 land; `epistemic`/`mobius`/
`dynamic` unifications with **M4**/**M8**/**M10**; the `HEXAD/src/*.c` cull with **M24**.
