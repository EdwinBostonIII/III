# III EIDOS — Optimizer Soundness Invariant (Phase 6, honest)

**The invariant.** cg_r3 emits a non-naive reduction (a shift/add/sub multiply form, or a
`mulhi>>s` magic division) **only if that form was machine-proven equivalent to the source
expression over all 2⁶⁴**. Otherwise it emits the naive form (`imul` / `divq`), which is
unconditionally correct. Therefore the compiler **can never emit a wrong reduction for any
input** — proven-or-fallback, with a correct fallback.

## Why it holds — the structural choke point (this is the proof, not a test)

In `cg_r3.iii`'s `R3_K_EXPR_BINARY` arm there is exactly **one** path to each reduced emission:

- **Multiply** (`COMPILER/BOOT/cg_r3.iii`, the `op==3` block): `r3_emit_*` of a shift form is
  reachable **only** when `seg_mul_plan(v)` returns a kind ≠ `SMP_IMUL`. In
  `ser_egraph.iii`, `seg_mul_plan` returns a non-IMUL kind **only after** `bv_equal(formb, x*v) == 1`
  — bv_ring's sound polynomial decision over Z/2⁶⁴ (poly-equal ⇒ equal for every u64). Unproven ⇒
  `SMP_IMUL` ⇒ naive `imul`.
- **Division** (the `op==4` magic block): `r3_emit_*` of `mulhi>>s` is reachable **only** when
  `seg_div_plan(d)` returns `SDP_MAGIC`, which it returns **only after** the Granlund-Montgomery bound
  (`mulhi(m,d)==2^s ∧ 0<m·d mod 2⁶⁴≤2^s`) holds — the GM theorem's *sufficient* condition, so the
  reduction is correct for all x regardless of how `magicu` computed `(m,s)`. Bound fails ⇒
  `SDP_GENERAL` ⇒ naive `divq`.

There is no other path to these emissions. So **emitted ⇒ proven** by construction. This is finite,
structural control-flow safety of the optimizer — **not** "unbounded" anything (per the
session retrospective's calibration of the verification membrane).

## How it is verified (each can FAIL — these are not theater)

1. **Structural** — the single choke point above (auditable in the source).
2. **Behavioral** — `run_corpus.sh` runs the whole STDLIB corpus under the *new* e-graph-wired iiis-2.
   A wrong or unproven reduction would make some program diverge (wrong exit code). Critically this
   includes the `bb_*`/`sat` **prover KATs compiled by the new compiler** — the anti-circularity guard:
   a miscompiled proof oracle reddens here.
3. **Universality** — `opt/universality_gate.sh`: random, un-pre-shaped constants, each self-checking
   the e-graph form against the compiler's *own* `imul`/`divq` reference on the CPU over the wrap edges.
4. **Unit** — corpus KATs `2062` (multiply plan) / `2063` (magic division) execute the synthesized
   forms and confirm they compute `v·x` / `x/d` exactly.

## The teeth (the falsifier — proves the gate is not vacuous)

`opt/soundness_falsifier.sh` (run on demand; destructive — it rebuilds): temporarily delete the
`bv_equal` check in `seg_mul_plan` (or the GM bound in `seg_div_plan`), rebuild, and confirm that
`run_corpus` **and** `universality_gate` go RED — a wrong reduction now reaches a program. Then revert.
If breaking the gate does **not** redden a gate, the gate proved nothing. (It does: the e-graph's
cost model would emit a shift form for a constant bv_ring can't prove, diverging from the reference.)

The invariant is thus both **structurally guaranteed** and **empirically falsifiable** — the honest
bar, not a pass-only model constructed to never fail.
