# Hexad Compose Authority

Declares the canonical hexad compose rule and the authority implementation
against which the substrate's multiple hexad implementations are reconciled.
This document only **declares** the authority and records the known drift; the
source-level reconciliation is forward reference #8 (discharged at Stage 8.1).

## Real implementations in the substrate

(Adapted to the real tree — there are no `numera/hexad*.iii` modules; the hexad
algebra lives in the C reference subsystem and the compiler.)

- `HEXAD/src/hexad_algebra.c` — the **spec-correct** pillar-position-aware
  compose rule: AND on pillars P1..P4, OR on pillars P5..P6. **Canonical.**
- `COMPILER/BOOT/hexad_check.c` — the simplified "NEG-dominates" uniform rule
  used by the compiler's fast admission path. Drifts from canonical on the
  P5..P6 (OR) pillars.
- `TYPES/src/hexad.c` — the type-system's copy, also the simplified rule.
- `DOCS/III-HEXAD.md` — the prose specification; states the pillar-position
  rule (agrees with the canonical implementation).

## Canonical rule

The authority is `HEXAD/src/hexad_algebra.c`. Its compose:
- pillars P1..P4 (the "necessity" pillars): logical AND of the operands;
- pillars P5..P6 (the "possibility" pillars): logical OR of the operands.

## Drift and reconciliation (forward reference #8) — PROVEN ANALYSIS (2026-05-22)

The earlier text here was WRONG. The divergence is not a rare edge case: an
exhaustive sweep (HEXAD/tests/hexad_bricking_proof.c + the brick-delta probe)
shows the simplified uniform "NEG-dominates everywhere" rule in
`COMPILER/BOOT/hexad_check.{c,iii}` (+ stage1_port) and `TYPES/src/hexad.c`
differs from the canonical pillar-position rule on **471,416 of 531,441**
hexad pairs (89%). Two coupled defects were found, and a single correct
synthesis was machine-proven:

DEFECT A (compose): the compiler + TYPES apply NEG-dominates uniformly to all
six pillars; III-HEXAD.md 3.1 mandates **AND on structural P1..P4, OR on
informational P5..P6** (= `HEXAD/src/hexad_algebra.c::iii_hexad_compose6`,
which is correct).

DEFECT B (admission, the real bricking gap): both `bitmap_init`s do
`memset(0xFF)` then clear only the 6 exact brick patterns -> they admit
723/729 hexads, including **717 hexads that carry a structural-pillar NEG**.
III-HEXAD.md 2.1 says any NEG in P1..P4 is structurally unrepresentable; the
correct admission set is the **144** hexads with no structural NEG. The
referenced precomputed bitmap `INCLUDE/xii_asym_reach6.h` does not exist.

COUPLING (why "adopt canonical compose" alone is UNSAFE): adopting the
canonical compose while keeping the 6-pattern bitmap ADMITS 1,250 compositions
the legacy rule bricked — a silent anti-bricking regression the corpus cannot
catch. The fix must change compose AND admission together.

THE PROVEN SYNTHESIS (one rule, no modes, bricking impossible by theorem):
  - compose = canonical (AND on P1..P4, OR on P5..P6), byte-identical at all
    three sites;
  - admission = structural rule (admissible iff no NEG in P1..P4).
Because AND makes structural-NEG sticky (`AND(NEG,.)=NEG`), the theorem
`admitted(a o b) == admitted(a) AND admitted(b)` holds for all 531,441 pairs
(0 violations), all 6 bricks are non-admitted, and **0** bricks are reachable
by composing two admitted hexads. Bricking is structurally impossible, not
pattern-matched. This is strictly safer than the status quo (which leaks 717
structural-NEG hexads), satisfies byte-identity, and is efficient (6 trit
table lookups).

COMPLETE FIX (each a hard gate before the next):
  1. compose -> canonical in hexad_check.c, hexad_check.iii,
     stage1_port/hexad_check.iii, TYPES/src/hexad.c (hexad_algebra.c already
     correct);
  2. admission -> structural rule in the compiler + TYPES `bitmap_init`
     (clear every hexad with a structural-pillar NEG; admits 144);
  3. permanent guards: HEXAD/tests/hexad_bricking_proof.c (theorem) +
     a Cartesian byte-identity test across all three composes;
  4. rebuild iiis-0/1/2 (hexad_check is compiled into the compiler) +
     build_stdlib + full corpus -> MUST stay green (proves no live module
     relied on the lax 723-admit rule; a break = a real structural-NEG hexad
     to fix then-and-there, never to relax the rule for);
  5. re-baseline iii_hexad_bitmap_hash (canonical-state input) + golden
     reseal + twin-build determinism.

STATUS: synthesis PROVEN + persisted (hexad_bricking_proof.c). Step 4 is a
seal-critical compiler bootstrap reseal + a substrate-wide admission
tightening governed by the CRASH-DEBUGGING PROTOCOL (read/verify-in-binary,
no rushing) — it is staged for execution with that full care, not a
mechanical edit.
