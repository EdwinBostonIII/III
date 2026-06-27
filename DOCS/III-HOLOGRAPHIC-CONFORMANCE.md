# III — Holographic Conformance: the zero-runtime conformance check, with the conscience line drawn

**Built 2026-06-26, against the LIVE tree. Every claim below was *run* (gate `run_legA.sh` → `conform.exe`=99),
not relayed.** The user's vision: a "Zero-Runtime Holographic Debugger" — crush a module to an O(1) tensor,
crush an architecture invariant to a "mold," intersect them in the SMT layer, and on a violation trace a
counter-example witness back to the exact node — *without ever running the module*. This document records the
**real, sound, gated realization** of that vision and, per `/iii-master:iii-math-conscience`, the **exact
boundary** between what is PROVEN and what the framing overclaims.

> **LABEL (audit-honest, advisor-checked):** this is a **sound, gated CAPABILITY on the verification membrane —
> NOT load-bearing.** Its only caller is its own KAT (`_au_conform_kat.iii`); nothing in the live trusted path
> (cg_r3 / build_stdlib / ccsv / the seed pipeline / the GU gate) consumes it. Removing it reddens only its own
> KAT. It is real and verified; it bears no system load yet. The genuinely load-bearing thread remains the ccsv
> Φ1 trust floor (verify-fails 183→66, `DOCS/III-SEED-FLOOR-PROGRESS.md`) — this capability does not advance it.

## What was built (PROVEN-IN-CODE)

`ser_antiunify.iii: au_conform_bound(base, boff, blen, accum, acc0, bound) -> {OK|VIOL|DEFER}` + accessors
`au_conform_iter()` (breach iteration), `au_conform_witness()` (bit-level breaking state), `au_conform_delta()`.

| Phase (user's framing) | Real mechanism it maps to (composition, no island) | Status |
|---|---|---|
| **1 — Architecture invariant ("the Mold")** | the boundary constraint `P(accum) = "accum < bound"`, built as a bv_bits circuit by `sks_ult` (ser_kinduct_sym). `sks_mask_eq`/`sks_consv_prove` give the other invariant templates. | **REAL** |
| **2 — Module projection ("the Key")** | `au_topo_amputate` crushes the loop body to its closed form `acc' = acc + delta`, **PROVEN over all 2⁶⁴** by the symbolic guillotine (`au_svir_step_sym` vs the fuzz-extracted delta — behavioral resonance, no opcode pattern-match). | **REAL** (affine fragment) |
| **3 — SMT isomorphic intersect** | `sks_prove(P(x), P(x+delta), x, acc0)` — the bit-blast miter `P(x) & ~P(x+delta)`, decided UNSAT over all 2⁶⁴. No CPU execution of the module; two closed forms meet in the solver. | **REAL** |
| **4 — Causal traceback / pinpoint** | on VIOLATION: `au_conform_iter()` = the FIRST `n` with `acc0 + n·delta ≥ bound` — a **closed-form breach iteration** computed from the proven `(acc0, delta)` ("drift outside the bound at iteration N", no run); `au_conform_witness()` = the bit-level breaking state from `sks_counterexample`. | **REAL** (iteration-precise **in the no-wrap regime**: a positive `delta` with `delta ≤ 2⁶⁴−bound`; the mod-2⁶⁴ wrapping/decrement regime is **guarded** → iteration DEFERRED `AU_NONE64`, violation still PROVEN, never a wrong number — KAT case 6; SVIR-node precision = §Boundary) |

**Gate (`run_legA.sh` → `conform.exe`=99, 24 KATs ALL GREEN, no regression):** a delta-0 body → PROVEN CONFORM;
`acc += 5` vs bound 100 → VIOLATES with breach iteration **20** (and 21 for bound 103, 14 for acc0=30); a
geometric `acc *= 2` body → **DEFER**. The teeth that matter: the geometric module is **never falsely blessed**.

## The conscience line (what the vision OVERCLAIMS — stated, not blurred)

The vision says III "crushes *arbitrary* human logic into O(1) polynomials" so conformance is "mathematically
impossible to crash" for *any* module. **That is false in general, and the gate does not claim it:**

1. **Only the AFFINE fragment crushes.** `au_topo_amputate` proves `acc' = acc + delta` only when the orbit is
   arithmetic (constant first difference) AND the symbolic step confirms it over 2⁶⁴. A non-affine module
   (geometric, data-dependent, nested-without-a-closed-inner, memory-coupled) returns **`AU_CONF_DEFER`** — the
   honest residue, exactly like the crush ledger's defer. The O(1) verdict is REAL *for what crushes*; it is a
   bounded fragment, not "arbitrary logic." Universal crushing is the documented boundary of the whole crush
   stack (`DOCS/III-AUTOPOIETIC-SEED-SYNTHESIS-PLAN.md`), not solved here.
2. **The invariant is a single-accumulator boundary** (`accum < bound`), not an arbitrary architectural
   contract over memory regions / I/O / causal-step budgets. Richer invariants (`sks_mask_eq`, `sks_consv_prove`
   over 2¹²⁸) exist as primitives; wiring them into the conformance gate is future work, not a claim made now.
3. **"Bypasses the CPU execution layer for infinitely many modules concurrently"** is an aspiration. What is
   real: ONE module's affine closed form is checked against ONE boundary invariant by ONE 2⁶⁴ miter — fast and
   runtime-free, but bounded as in (1)+(2). A whole-program conformance ledger (per-loop verdict across a real
   SVIR module) is the natural next stone, attaching to the existing `au_crush_report` walk.
4. **"Reverse resonance to the exact SVIR node (line 42)"** — the gate pinpoints the **iteration** of breach
   exactly (closed form) and the **loop** (its `boff`); resolving to the precise *opcode offset* of the
   offending update is the un-built remainder of Phase 4.

## Why this is sound (and where the trust rests)

The verdict is only as sound as `au_topo_amputate` (the crush is PROVEN over 2⁶⁴, not sampled) and `sks_prove`
(the membrane's k-induction-step miter, `bb_equal` over 2⁶⁴). Both are pre-existing, gate-checked organs of the
verification membrane. The conformance gate adds **no new trusted axiom** — it is a composition. A module that
those organs cannot prove is DEFERRED, never approved. That refusal-by-default is the entire reason the claim is
honest: the gate's value is that it tells you *which* modules it can certify O(1) and *which* it cannot, instead
of pretending to certify all of them.
