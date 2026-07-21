# HISTOS — the living proof web

*Status: STAGES 1 + 2 + 3 LANDED + GATED (`STDLIB/scripts/histos_gate.sh`, exit 0,
byte-deterministic). Built on the resealed compiler `ec0ad523`. Spec:
`DOCS/superpowers/specs/2026-07-21-living-proof-web-design.md`.*

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

## Stage 3 (landed): unification with PARATHEKE — one standing, two axes

Stage 3 was going to bolt kardia cross-session persistence onto HISTOS. That would have
duplicated **PARATHEKE** — the concurrently-built standing-deposit ledger, which is already
kardia's reverification law across time. Instead the two are unified: they are the SAME
reverification-gated standing on two axes — PARATHEKE the **temporal** ledger (deposits
re-earned each read by re-sealing, `man_seal_order`), HISTOS the **spatial** web (organs
re-derived by the exact engines, `kr_sign`).

The seam is the R1-order claim `24792 > 1925`, which both already hold. The ontological move:
the deposit does not *call* the web — it **becomes a node in it** (`histos_paratheke_probe.iii`,
externing both organs read-only, modifying neither). The node `r1_order_standing` has:

- **its own cell** = PARATHEKE's `pk_std_line` re-derivation (the seal) — the temporal axis;
- **an edge** `[r1_order_standing < membrane_verdict]` onto the exact `witness→membrane→krisis`
  chain — the spatial axis.

`histos_stand(r1_order_standing)` is then `(seal re-derives) ∧ (exact substrate stands)`,
emergent from the web's recursive law — no coordinator, no new machinery.

**Why load-bearing (the gate asserts it):** the R1 deposit is ORDER-kind — `man_seal_order`
does NOT run `kr_sign`. So a mutated `kr_sign` leaves **PARATHEKE's seal STILL STANDING**, while
HISTOS's exact chain reddens:

```
true:  seal STANDS + web GREEN
mut :  seal STILL STANDS (the ledger's logos-seal alone misses the substrate break)
       web (histos, spatial): r1_order_standing RED (seal-cell GREEN) rooted-at krisis
```

Only the two axes TOGETHER catch the substrate break behind a valid seal — III's own
two-engine / no-self-grading law, lifted to whole organs. And the deposit gives the web-node
its PERMANENCE (a ledger entry, re-earned every session) without duplicating kardia. One
standing, two axes.

## Stage 4 (landed): the web grown to the conscience spine

The MVP is the exact-order chain. Stage 4 (`histos_conscience_probe.iii` +
`STDLIB/scripts/histos_conscience_gate.sh`) grows it to TEN organs, so the behavioral witness
rests on TWO subtrees that meet at it:

```
              ┌─ membrane ─ krisis ─ bigint                    (SUBSTRATE: the exact two-engine order)
behavioral_witness
              └─ ethos ─ {ontos, reach_oracle, praxis, horos}  (LAW: the conscience, rooted in eidolos)
```

Cells are the organs' REAL selfproves (`eol_selfprove`, `ontos_selfprove`, `praxis_selfprove`,
`horos_selfprove`, `ethos_gate`, a `reach_oracle` wall-KAT, plus the exact chain). The witness
STANDS iff BOTH subtrees stand — "measured (substrate) is not installed (law)" made *structural*.
The gate proves each subtree is independently load-bearing, on real mutated artifacts:

```
true  : behavioral_witness GREEN                        [substrate GREEN, law GREEN]
wall  : behavioral_witness RED rooted-at reach_oracle   [substrate holds — the witness needs the LAW]
engine: behavioral_witness RED rooted-at krisis         [law holds — the witness needs the SUBSTRATE]
```

Breaking the wall (reach_oracle → default-allow) collapses the law subtree while the exact
substrate stands; breaking the engine (kr_sign → tie) collapses the substrate while the law
stands. The web names which. (EIDOLOS is deeper still: it is both a node *and* the web's own
edge-judge via HOROS discharge — breaking it collapses the entire web, the universal root of
III's reasoning. That truth is noted, not gate-asserted, because with eidolos broken the web's
own machinery is unreliable — the clean deterministic teeth are the wall and the engine.)

## How it grows and what it subsumes

Organ by organ: each new node registers its cell + its edges to already-webbed organs.
`omnia_selfprove_gate.sh`'s 17 independent runs become 17 connected nodes; every PARATHEKE
deposit can become a web node (stage 3); every web node worth persisting gets a deposit. The
spatial web and the temporal ledger co-grow as one standing.

## Reproduce

```
bash STDLIB/scripts/histos_gate.sh             # stages 1 + 2 + 3 (MVP + PARATHEKE unification)
bash STDLIB/scripts/histos_conscience_gate.sh  # stage 4 (the grown web: substrate ∧ law)
```
