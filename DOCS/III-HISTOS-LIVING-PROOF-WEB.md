# HISTOS — the living proof web

*Status: STAGES 1 + 2 LANDED + GATED (`STDLIB/scripts/histos_gate.sh`, exit 0, byte-deterministic).
Stage 3 (kardia cross-session permanence) follows. Built on the resealed compiler `ec0ad523`.
Spec: `DOCS/superpowers/specs/2026-07-21-living-proof-web-design.md`.*

## What it is

III's ~30 organs each self-prove in **isolation**. A per-organ gate (e.g. this session's
`omnia_selfprove_gate.sh`) calls an organ SOUND whenever its own selfprove passes — even if an
organ it silently depends on has broken. HISTOS (ἱστός, the loom) weaves the islands into ONE
web:

- **Nodes** are organs, each carrying a cell verdict (green / red / unknown).
- **Edges** are cross-organ dependencies `A→B`, each carrying an EIDOLOS obligation
  `[a < b_verdict]` **discharged by HOROS** (`hr_register` + `hr_discharge`, which composes
  PRAXIS/EIDOLOS — the same directed entailment that judges completion).
- **A node STANDS** iff its own cell is green AND every out-edge discharges AND — recursively —
  every organ it depends on stands.

**No island, no new primitive.** The edge's soundness is decided by the existing HOROS/EIDOLOS
substrate; the only new thing is the loom — the recursive stand and the named root cause. The
graph is a DAG: a would-be cycle is refused by name at edge creation (mirroring EIDOLOS's
`<`-cycle refusal), so the recursion terminates. Unknown/red verdicts both fail the stand
(fail-closed: unproven is not standing).

## Why the recursion is load-bearing (the crux)

kardia already reddens a cell when a byte in its transitive closure drifts. But if a node's
**own** selfprove does not exercise its dependency at runtime, the node re-derives GREEN while
the dependency is broken — and a per-organ gate calls it sound. The web's recursion is exactly
what catches this, and `histos_reddened_by` **names why**.

The MVP is this session's exact-order chain:

```
behavioral_witness ──▶ membrane (pb_head_order_trusted) ──▶ krisis (kr_sign) ──▶ bigint (bigint_cmp)
```

Break the krisis cell and:
- **krisis** reddens (its own cell).
- **membrane** reddens (its selfprove runs engine A, which uses `kr_sign`; engine B does not, so
  the two disagree and `pb_head_order_trusted` returns REFUSE −1000).
- **behavioral_witness** reddens **through the web**, *while its own cell stays GREEN* — its
  selfprove is the pure law (`ethos_r1_selfprove`), which never runs the engines. A per-organ
  gate would call the witness sound. `histos_reddened_by(witness)` names **krisis** as the root.
- **bigint**, independent of krisis, stays green.

That single behavior — reddening a node whose own proof passes, and naming the root — is what
per-cell gates cannot give. It is the gate's asserted crux line:

```
the teeth: krisis cell RED -> behavioral_witness RED, own-cell GREEN, rooted-at krisis
```

## Stage 1 (landed): the loom's logic, proven pure

`histos.iii` (the loom) + `histos_cli.iii` (voice + judge). `histos_selfprove` proves the
machinery with a mandatory negative, using **injected** verdicts to test propagation — the
legitimate way to test that red flows along the web, exactly as HOROS injects a bogus obligation
to test its refusal:

1. the MVP weaves; all three edges DISCHARGE (real EIDOLOS entailment);
2. all cells green → the whole web stands;
3. **the teeth** — krisis red → krisis/membrane/witness red, witness own-cell green, `reddened_by`
   names krisis, bigint stays green;
4. restore → the web stands again (self-cleaning);
5. a would-be cycle (bigint→witness) is refused by name;
6. a non-entailing edge does not discharge and reddens its from-node despite green cells.

Composes only `horos.iii` (`hr_register`/`hr_discharge`/`hr_find`); weaving is idempotent (an
existing stone is reused, so the narrative and the judge can both weave in one process).

## Stage 2 (landed): the same, on real artifacts

`histos_web_probe.iii` runs the four organs' REAL selfproves (`ethos_r1_selfprove`,
`pb_attn_selfprove`, `kr_selfprove`, a bigint KAT) and feeds their true verdicts into the web.
The gate builds it twice: once against the true krisis, once against a krisis whose `kr_sign` is
mutated to a constant tie (injected on a COPY — the tracked source is never touched). The
asserted result:

```
true:  web: behavioral_witness GREEN (own-cell GREEN) rooted-at none
mut :  web: behavioral_witness RED  (own-cell GREEN) rooted-at krisis
       real cells: witness=green membrane=red krisis=red bigint=green
```

The mutant reddens krisis and membrane from their **real** runs (membrane's engine A uses
`kr_sign`; engine B does not, so they disagree and `pb_head_order_trusted` REFUSES), the
witness's **real** pure-law selfprove still passes (own-cell GREEN), and the WEB reddens the
witness, naming the DEEPEST red (`krisis`) as the origin. Real artifacts, real mutation, correct
root-cause. `histos_reddened_by` seeks the deepest red on the failing path, so it names the
origin even when intermediate nodes (membrane) are red in their own right.

## Stage 3 (next): permanence, reverification-gated

Register each node as a kardia class-2 cell (reach-pin folds the transitive closure) and persist
the web via kardia's append-only ledger. A later session reloads, re-pins against the live tree,
KEEPS the standing of every unchanged node, and reddens exactly the subtree whose source drifted
— permanence-under-reverification, never a frozen golden.

## Reproduce

```
bash STDLIB/scripts/histos_gate.sh     # stage 1: exit 0, byte-deterministic, the crux asserted
```
