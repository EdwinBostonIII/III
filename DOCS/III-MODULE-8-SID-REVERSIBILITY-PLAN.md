# Module 8 — SID & Reversibility: file-by-file lean implementation plan

## Gate cleared

Written only because **Module 7 (XII, the one engine) is verified fully + perfectly**:
main-corpus gate `bfya4tnf5` → `PASS=391 FAIL=0`, `670_xii_trit=99` (XII evaluates the M2
ternary algebra — all five trit ops over the full 3×3 domain == the proven `iii_trit_*`, plus a
nested term reducing to one normal form), and `run_xii_corpus` `PASS=93 FAIL=0` (the 117
critical pairs converge + MPO termination *with* the five trit rules added). The disjointness
theorem (trit kinds 24–29 share no symbol with K01–K18 → zero new critical pairs) is both
argued and machine-verified; the positive arms are proven live. No placeholder/deferral/flaw.

## Context

`DOCS/III-APOTHEOSIS.md` Module 8 — "SID & Reversibility." **Today:** reversibility is *three
mechanisms that don't know they're one*, plus a naming collision:

- `COMPILER/BOOT/sid.iii` — the real **Side-effect Inverse Derivation** (compile-time, Ring
  R-2/R-1; derives an op's inverse). The *trusted bootstrap C-port* (like `cic.c` for M9).
- `numera/reversible.iii` (530L) — runtime transactional reversibility: a LIFO stack of
  capability-scoped undo envelopes; commit truncates the log, rollback replays each undo in
  reverse and is witnessed. Gated by `634_reversible=99` (KAT codes 1–47, negatives 5–7).
- `aether/reversibility_audit.iii` (564L) — proof-carrying gate: bit-blasts `y=f(x)`,`z=g(y)`
  into SMT, asserts `x≠z`; **UNSAT proves `g(f(x))=x` over the whole bit-vector domain**
  (reversible → admit + pass witness), SAT → counterexample (refused). Gated by
  `649_reversibility_audit=99` (KATs 1–5, negatives 2–3).
- `omnia/hexad_mobius.iii` (71L) — gives the safety lattice (M3) its inverses: the inverse is
  the **active-negation** of the forward hexad (pillars 2–5 negated, 1 & 6 fixed), which is
  involutive, so the pair round-trips and `forward + inverse` cancels to ZERO on the active band.
- **Collision:** `omnia/sid.iii` was a *Crystal-ID dependency-graph navigator* squatting on the
  `sid` name (unrelated to the compiler SID).

**The apotheosis Final** unifies these into *one inverse concept*: derived by the compiler,
carried by every witness fragment (M6) for lossless backward replay, preserved by XII bijective
rules (M7), **projected into the safety lattice by `hexad_mobius` (M3 — paid here)**, attested by
`reversibility_audit`, gated by the Constitution as reversible / typed-`Compromise` /
unrepresentable (M10). *Falsifier:* "a forward op whose derived inverse fails to round-trip; an
irreversible op with no `Compromise` tier; a `Compromise<HIGH>` value that constructs; **the name
`sid` still bound to two modules** → red."

## What is already done (verified this session, read-only)

- **Step zero — the collision — is cleared at the module/file level.** `glob` finds only
  `COMPILER/BOOT/sid.iii` (the real SID), `omnia/crystal_deps.iii` (the renamed navigator), and
  `omnia/hexad_mobius.iii`. **`omnia/sid.iii` does not exist.** The navigator's consumers
  (`101/102/103_sid_*`) already extern `from "crystal_deps.iii"`. So `sid` (as a *module*) names
  exactly one thing — the compiler's. The stale `omnia_sid.iii.o` that broke the XII gate last
  session was the last build vestige (purged). The `sid_*` *symbol* names retained inside
  `crystal_deps` are a documented, link-stable navigator-domain choice (its header) — distinct
  from the compiler's `iii_sid_*` symbols, in a separate binary; no collision.
- **Two of the three round-trip laws are gated:** runtime (`634_reversible=99`) and whole-domain
  SMT (`649_reversibility_audit=99`).
- **`Compromise<HIGH>` construction is already forbidden + gated by M3** (`667_hexad_reach`:
  bricking-stays-unreachable). Falsifier clause #3 is covered.

## The gap (the genuine M8 increment)

The **third** round-trip law — `hexad_mobius`'s inverse projected onto the safety lattice (the
M3 debt the apotheosis Pass-2 names: "`hexad_mobius`'s inverse **is** the SID inverse projected
onto the safety lattice — M3 paid here") — is **ungated**: `hexad_mobius.iii` has the full
machinery (`make`/`valid`/`roundtrip`/`admits`/accessors) but **no `selftest` and no `*mobius*`
corpus test.** Falsifier clause #1 ("a forward op whose derived inverse fails to round-trip") is
unverifiable for the safety-lattice view. This is exactly analogous to M3's missing exhaustive
`reach` KAT and M7's trit-debt: the law exists in source, but is not a gate-runnable falsifier.

Plus one collision residue: `crystal_deps.iii` line 1 is a header path-banner still naming the
nonexistent `…/omnia/sid.iii` (cosmetic, but a flaw — names a file that no longer exists).

## ADR-1 — Scope: the lean keystone is the Möbius round-trip falsifier; the systemwide unification lands with its modules

- **Decision.** Module 8 = (a) make the Möbius round-trip law an **exhaustive, gate-runnable
  falsifier** over the full 729-hexad domain (paying the M3-mobius debt, closing falsifier clause
  #1 for the safety-lattice view — the third and final reversibility mechanism to get its
  round-trip law gated), and (b) clear the last collision residue (the stale header path).
- **Rejected — implement the full apotheosis unification now** (witness fragment carries the
  derived inverse for backward chain replay; `reversible`'s envelopes become views over chain
  segments; the Constitution trichotomy `reversible/typed-Compromise/unrepresentable`; the
  `Compromise<LOW|MEDIUM>` tier + `COP_REVTAG_EQ`). The apotheosis itself routes these to
  **M6-deepening** (the witness chain) and **M10** (the Constitution): "Push further into the
  Constitution (M10)." Pulling M10's trichotomy into M8 would be the over-reach the cadence
  forbids, not a no-compromise gain — it lands, fully, when M10 is built. Falsifier clause #2
  (irreversible op with no `Compromise` tier) is therefore an M10 deliverable, exactly as the
  apotheosis structures it.
- **Rejected — touch `COMPILER/BOOT/sid.iii`.** It is the trusted bootstrap C-port (Ring
  R-2/R-1 compiler internals), the SID analogue of `cic.c` which M9 explicitly keeps as "the
  trusted bootstrap kernel in C." Editing it is out of stdlib-module scope and high-risk.
- **Consequence.** After M8 the *one round-trip law* is gate-verified in all three of its views:
  runtime (`634`), whole-domain SMT (`649`), and safety-lattice involution (`671`, new). "One
  inverse, three views" becomes executable + falsifiable. Net: `PASS = 391 + 1`.

## ADR-2 — Leave the `sid_*` symbols in `crystal_deps`; fix only the stale header path

- **Decision.** Do **not** rename `crystal_deps`'s `sid_*` functions / `SID_*` consts to a
  `cdep_*`/`CDEP_*` prefix. The `crystal_deps` header documents these as deliberately retained
  ("link-stable; the navigator's own domain, distinct from the compiler SID's symbols"); the
  apotheosis falsifier is about the name `sid` bound to two *modules* (cleared), not symbols; no
  stdlib reversibility module uses `SID_*` (they use `REV_`/`RVA_`/`HXM_`), so there is no
  `L_SID_*` collision risk. Renaming would contradict a documented decision and ripple into
  `101/102/103` + `ripple.iii` for zero falsifier benefit.
- **Do** fix `crystal_deps.iii:1` — the path banner naming the nonexistent `omnia/sid.iii` → the
  real `omnia/crystal_deps.iii`. Comment-only: the compiled `.o` is byte-identical (comments are
  lexed out), so zero seal drift, zero regression risk; it completes the rename cleanly.

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **MODIFY** | `STDLIB/iii/omnia/hexad_mobius.iii` | add `iii_hexad_mobius_selftest()->u64` (99=pass) + two module-scope `[u32;3]` scratch buffers — the exhaustive round-trip falsifier. **Additive**: no existing fn touched. |
| **MODIFY** | `STDLIB/iii/omnia/crystal_deps.iii` | line-1 header path banner `…/omnia/sid.iii` → `…/omnia/crystal_deps.iii` (comment-only; byte-identical `.o`). |
| **CREATE** | `STDLIB/corpus/671_hexad_mobius.iii` | corpus KAT wrapper (`extern iii_hexad_mobius_selftest; main → it`). |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[671_hexad_mobius]=99` to `EXPECTED` (after `[670_xii_trit]=99`). |
| **KEEP** | `numera/reversible.iii`, `aether/reversibility_audit.iii`, `omnia/hexad_algebra.iii`, `numera/trit.iii` | the proven mechanisms `hexad_mobius` composes — untouched (read-verified complete). |

---

## Step 0 — Pre-flight (read-only)

0.1 **Confirm `671` is the next free corpus number:** `glob STDLIB/corpus/671_*.iii` → empty;
`670_xii_trit` is the current max. If taken, pick the next free and adjust.
0.2 **Confirm `hexad_mobius` is in `build_stdlib` MODULES** (so the selftest symbol is built and
`671` can link it): `grep hexad_mobius STDLIB/scripts/build_stdlib.sh`.
0.3 **Confirm the round-trip arithmetic** (already established): `iii_hexad_unpack6` is valid iff
`h<729` (so the valid domain is exactly `[0,729)`); `iii_hexad_active_neg` negates idx 1–4 and is
involutive; `iii_trit_sum(t,−t)=clamp(0)=0` (gated by `666_trit`, the exhaustive 3×3 SUM table).
0.4 **Record the baseline:** `run_corpus` is `391/0`; `run_xii_corpus` is `93/0`. The collapse
must perturb neither except the additive `671`.

## Step 1 — MODIFY `STDLIB/iii/omnia/crystal_deps.iii` (collision residue)

Edit line 1 only: replace the banner path `…\STDLIB\iii\omnia\sid.iii` with
`…\STDLIB\iii\omnia\crystal_deps.iii`. No code change.

## Step 2 — MODIFY `STDLIB/iii/omnia/hexad_mobius.iii` (the keystone falsifier)

Append two module-scope scratch buffers + `iii_hexad_mobius_selftest`. The buffer is the 3×u32
field layout `make`/`valid`/`roundtrip`/`admits` already use `(forward, inverse, floor_ppm)`.

```
/* ---- M8 keystone: exhaustive Mobius round-trip falsifier ----
 * The one inverse concept projected onto the M3 safety lattice (apotheosis M8, M3 debt paid).
 * Buffers are the 3-u32 (forward, inverse, floor) layout the API operates on. */
var HXM_KAT_BUF : [u32; 3]
var HXM_KAT_BAD : [u32; 3]

fn iii_hexad_mobius_selftest() -> u64 @export {
    /* Exhaustive positive: EVERY valid hexad's Mobius pair round-trips + involution holds. */
    let mut h : u64 = 0u64
    while h < 729u64 {
        let hv : u16 = h as u16
        iii_hexad_mobius_make(&HXM_KAT_BUF as u64, hv, 0u32)
        /* structurally valid: iv == active_neg(fw) AND active_neg(iv) == fw (involution) */
        if iii_hexad_mobius_valid(&HXM_KAT_BUF as u64) != 1u8 { return 1u64 }
        /* round-trip law (independent path: unpack + trit_sum cancellation on the active band) */
        if iii_hexad_mobius_roundtrip(&HXM_KAT_BUF as u64) != 1u8 { return 2u64 }
        if iii_hexad_mobius_forward(&HXM_KAT_BUF as u64) != hv { return 3u64 }
        if iii_hexad_mobius_inverse(&HXM_KAT_BUF as u64) != iii_hexad_active_neg(hv) { return 4u64 }
        /* the involution theorem stated INDEPENDENTLY (different op than roundtrip's trit_sum) */
        if iii_hexad_active_neg(iii_hexad_active_neg(hv)) != hv { return 5u64 }
        /* default floor applied (floor_ppm 0 -> HXM_FLOOR_Q = 920000) */
        if iii_hexad_mobius_floor(&HXM_KAT_BUF as u64) != 920000u32 { return 6u64 }
        h = h + 1u64
    }
    /* ---- negatives: the gates REJECT a non-inverse / non-cancelling pair ----
     * h=2 unpacks to [+1,-1,-1,-1,-1,-1]; its active band (idx 1..4 = -1) is nonzero, so
     * active_neg(2) != 2. Build the correct pair, then CORRUPT the inverse field to fw. */
    iii_hexad_mobius_make(&HXM_KAT_BAD as u64, 2u16, 0u32)
    let bp : *u32 = &HXM_KAT_BAD as *u32
    bp[1u64] = 2u32                                   /* iv := fw (no longer the active-negation) */
    if iii_hexad_mobius_valid(&HXM_KAT_BAD as u64) != 0u8 { return 7u64 }       /* active_neg(2)!=2 */
    if iii_hexad_mobius_roundtrip(&HXM_KAT_BAD as u64) != 0u8 { return 8u64 }   /* SUM(-1,-1)!=0 */
    /* coherence floor gate: below refused, at/above admitted */
    iii_hexad_mobius_make(&HXM_KAT_BUF as u64, 0u16, 920000u32)
    if iii_hexad_mobius_admits(&HXM_KAT_BUF as u64, 919999u32) != 0u8 { return 9u64 }
    if iii_hexad_mobius_admits(&HXM_KAT_BUF as u64, 920000u32) != 1u8 { return 10u64 }
    if iii_hexad_mobius_admits(&HXM_KAT_BUF as u64, 920001u32) != 1u8 { return 11u64 }
    /* defensive: an out-of-range hexad (>=729) yields the 0 sentinel, never wild unpack */
    if iii_hexad_active_neg(729u16) != 0u16 { return 12u64 }
    return 99u64
}
```

**Why this is a real (non-tautological) falsifier.** Check 5 (the involution, via `active_neg`
composition) and check 2 (the round-trip, via independent `unpack6` + `trit_sum` cancellation)
verify the *same law* by *two different operations* — satisfying the "two-path tests must drive
different rules" rule. Checks 7–8 are prove-the-negative arms (a corrupted inverse must make both
`valid` and `roundtrip` return 0). Check 1 spans all 729 hexads (the count assertion is implicit:
every one must pass). Check 12 proves the out-of-range guard.

## Step 3 — CREATE `STDLIB/corpus/671_hexad_mobius.iii`

```
/* 671_hexad_mobius.iii -- M8 keystone: the Mobius inverse round-trips on the M3 safety lattice.
 * Exhaustive over all 729 hexads: active-negation is involutive, forward+inverse cancels to ZERO
 * on the active band (the one inverse concept projected onto the safety lattice), + negatives.
 * Main-corpus convention: rc 99 on pass; 1..12 = which check failed. */
module corpus_671
extern @abi(c-msvc-x64) fn iii_hexad_mobius_selftest() -> u64 from "hexad_mobius.iii"
fn main() -> u64 { return iii_hexad_mobius_selftest() }
```

## Step 4 — MODIFY `STDLIB/scripts/run_corpus.sh`

Add `    [671_hexad_mobius]=99` to the `EXPECTED` map immediately after `[670_xii_trit]=99`.

## Step 5 — Verify (the gate, end-to-end)

Run from repo root with the **pinned** `COMPILED/iiis-2.exe`.

1. **Compile-only** `hexad_mobius.iii` and `671_hexad_mobius.iii` → both `rc=0` (catches traps
   before the lib build).
2. `bash STDLIB/scripts/build_stdlib.sh` → require **`FAIL = 0`** and `hexad_mobius` aggregated
   (grep the log for `FAIL = 0`; a failed module leaves a stale lib that can false-pass).
3. `bash STDLIB/scripts/run_corpus.sh` → require **`FAIL=0`**, `671_hexad_mobius=99`, and the
   regression set unchanged — notably `667_hexad_reach=99`, `666_trit=99`, `634_reversible=99`,
   `649_reversibility_audit=99`, `101/102/103_sid_*=99`. Net `PASS = 392`.
4. `bash STDLIB/scripts/run_xii_corpus.sh` → require **`PASS=93 FAIL=0`** (M8 doesn't touch XII;
   confirms no cross-effect).
5. **Manual hand-check** (by hand, no agents): re-read `hexad_mobius.iii` against the trap list;
   re-derive `h=2 → [+1,-1,-1,-1,-1,-1]` and confirm both negatives fire; confirm the
   `crystal_deps.iii` diff is comment-only.

**The single falsifier for the whole module:** `671_hexad_mobius` ≠ 99, or any of
`{667,666,634,649,101,102,103}` changing exit code, or `run_xii_corpus` regressing → red, revert,
diagnose before any rebuild.

---

## Standards & mandates checklist (every box ticked before "done")

- **NIH:** only `libc` + III (`hexad_algebra`, `trit`); no third-party. ✓
- **Determinism:** no float (the floor is a u32 ppm, integer); **equality-only compares**
  (`==`/`!=` on hexads, trits, floor — never `<`/`>` on i32/i64; the one `<` in `admits` is the
  preexisting `current_q_ppm < p[2]` on **u32**, which is safe and unchanged); monomorphic
  dispatch (no fn-pointer); no statistical/observational logic. ✓
- **W-laws:** W2 (≤4 params — `selftest` is 0, `make` is 3); W8 (bounded `while h < 729`, scratch
  `[u32;3]`); W14 (sentinel loops, no `break`); W15 (no recursion).
- **`.iii` traps:** single-line `fn`; **no local `var` arrays** (scratch is module-scope
  `HXM_KAT_*`); no nested `/* */`, no `—` em-dash (use `--`), no literal `*/` in prose; `} else {`
  N/A; `HXM_` prefix already in use in-file (no new collision — append to the existing namespace);
  `&HXM_KAT_BUF as u64` passed as the buffer address (the documented `&GLOBAL as u64` form `make`
  already uses), never `&ARR[0]` (byte-read trap).
- **Falsifier present + exhaustive:** all 729 hexads (positive) + involution theorem (independent
  path) + prove-the-negative (corrupted inverse → `valid`=0, `roundtrip`=0) + floor gate +
  out-of-range guard. ✓
- **K-value:** `hexad_mobius` K floor 0.98 unchanged (selftest is additive, pure).
- **Apotheosis alignment:** realizes M8 Final's "projected into the safety lattice by
  `hexad_mobius` (M3 — paid here)" and closes falsifier clause #1 for the lattice view; honors
  ADR-1 (the Constitution trichotomy / witness-fragment-inverse correctly deferred to M10 / M6 per
  the apotheosis's own routing) and ADR-2 (collision cleared at the module level; `sid_*` symbols
  left per the documented decision).

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `h=2` active band is actually zero | negatives 7–8 don't fire (false pass) | verified `h=2 → [+1,-1,-1,-1,-1,-1]`; idx 1–4 = −1 (nonzero, active band); gate catches it if wrong |
| selftest tautological (re-checks `make`) | weak falsifier | check 2 (roundtrip via `unpack`+`trit_sum`) and check 5 (involution via `active_neg`) verify the law by two independent ops |
| adding selftest perturbs `hexad_mobius` consumers | regression | additive only (new fn + new scratch vars); no existing fn/const touched; Step-5 gate confirms `667`/others stay 99 |
| `671` number taken | gate mis-registers | Step 0.1 globs it free first |
| comment edit changes the `.o`/seal | spurious drift | comments are lexed out → byte-identical `.o`; verified by `667`/consumers staying green |

## Roadmap (each step independently gate-able)

1. **Steps 0–4:** add the falsifier + corpus + register + comment fix.
2. **Step 5:** gate → `671_hexad_mobius=99`, `FAIL=0` (392/0), `run_xii_corpus 93/0`, no regression.

The increment is additive and reversible; M8 never goes green unless the Möbius round-trip law is
proven exhaustively and the existing reversibility gates (`634`, `649`) plus the M3 lattice
(`667`) stay green.
