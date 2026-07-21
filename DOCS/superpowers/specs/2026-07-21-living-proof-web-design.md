# THE LIVING PROOF WEB (HISTOS) — Design Spec

> **For agentic workers:** REQUIRED SUB-SKILL: after this spec is approved, use
> superpowers:writing-plans to produce the task-by-task implementation plan.

**Goal:** Bind III's ~30 self-proving organs — today independent islands — into ONE
reverification-gated proof web, where a change in any organ transitively reddens every
organ whose soundness depends on it, *with a named semantic reason*, and a node's standing
persists across sessions only while its evidence chain still re-derives against the living
body.

**Architecture:** A thin new organ, **HISTOS** (ἱστός, the loom), that COMPOSES four
existing organs — it registers no new reasoning primitive and reimplements nothing:

- **self_cartographer** (`scarto_map`) — the warp: the real inter-organ dependency threads,
  derived from live externs (never hand-declared, so the web can't drift from the truth).
- **kardia** (`kd_reg` class C2, `kd_pin_all`, `kd_cell_due`, `kd_derive_c1`, `kd_ledger_*`)
  — the cells: each organ's self-proof as a reverification-gated node whose reach-pin folds
  its transitive closure and goes DUE-OWNED the instant a dependency drifts.
- **HOROS** (`hr_register`, `hr_discharge`) — the knots: cross-organ semantic edges, an
  obligation `[A_export < B_verdict]` discharged by an EIDOLOS chain naming B's live primitive.
- **EIDOLOS** (through `px_judge` inside `hr_discharge`) — the judge: is each knot sound.

**Tech Stack:** `.iii` (compiled by the resealed `iiis-2` / `ec0ad523`); bash gate in the
`summit_gate`/`omnia_selfprove_gate` idiom; no new external dependency.

## Global Constraints

- **No islands.** HISTOS calls `hr_*`, `kd_*`, `eol_*`/`px_*`, `scarto_*`; it MUST NOT
  reimplement entailment, content-addressing, drift-detection, or graph extraction.
- **Reverification-gated permanence (the chosen model).** A node STANDS across sessions
  iff its kardia cell is derived-green (not DUE) AND its HOROS out-edges still discharge.
  On drift the node reddens *itself* — self-cleaning, never a frozen golden. Adopted (not
  self-derived) standing is never counted green (kardia's birth law).
- **Differential, not declared.** Edges are validated against `scarto_map`'s live graph, in
  katoptron's discipline: the web reddens if it diverges from the real dependency structure.
- **Determinism.** Integer-only; the weave re-derives byte-identically each run.
- **Capacity honesty.** HOROS caps at 32 stones per registrar; HISTOS partitions the web so
  no single registrar exceeds the cap, and REFUSES (names it) rather than truncating.
- **Built on the resealed compiler** `ec0ad523`; every claim verified in the artifact, twice.

---

## The problem, precisely

`omnia_selfprove_gate.sh` (this session) is the island problem in miniature: it runs 17
organs' `*_selfprove` in a loop, each independent. Nothing encodes that (say) the exact-order
membrane's soundness DEPENDS ON the krisis kernel's, so a broken kernel does not
*automatically* redden the membrane's standing — a human must notice. And a green verdict
carries no durable, re-checkable standing into the next session. Two missing bindings:

1. **Cross-organ entailment edges** — the graph of "A is sound *because* B is."
2. **Reverification-gated permanence for the semantic verdict** — kardia gates *byte* drift
   today; the *entailment* (does B's verdict still discharge A's obligation?) is not gated.

## The design

### Nodes — a kardia C2 cell per webbed organ
Each organ in the web is registered as a kardia **class-2** cell (`kd_reg(name,len,2,exp)`):
an organ-linked gate whose reach-pin (`kd_pin_all`) folds its transitive extern closure. This
is *already* how kardia tracks organ-linked gates — HISTOS reuses it verbatim. A cell is
`kd_cell_due` exactly when a closure member drifts; `kd_derive_c1` re-runs the organ's
self-proof and records a DERIVED verdict (green/red), the only kind that counts.

### Edges — a HOROS stone per cross-organ dependency
For each dependency A→B, HISTOS registers `hr_register("A→B", "[A < B_verdict]")` and
discharges it with a chain naming B's live primitive:
`hr_discharge(i, "[A < B_primitive] [B_primitive < B_verdict]")`. `hr_discharge` composes
PRAXIS/EIDOLOS — the same entailment substrate that judges completion — so a discharge is
`1` iff the evidence house *determines* the obligation, `0` otherwise.

### The web — transitive closure, reverification-gated
`histos_stand(node)` is **recursive**: GREEN iff (a) the node's kardia cell is derived-green
and not DUE, AND (b) for every out-edge to B, the edge *discharges* (the entailment is
well-formed) AND `histos_stand(B)` is GREEN. Condition (b)'s discharge is a *static* EIDOLOS
entailment — it proves the dependency is real and sound, but it never reddens on its own; the
RED propagates through the recursion. Transitivity is therefore explicit: a node is red iff
its own cell is red or any node it transitively depends on is red. (A DAG is assumed — the
dependency graph has no cycles; HISTOS refuses a cycle by name, mirroring EIDOLOS's `<`-cycle
refusal, rather than looping.)

**Why the recursion is load-bearing, not kardia alone.** kardia's reach-pin folds the closure,
so a change in B flips A's cell DUE and A re-derives. But if A's *own* self-proof does not
exercise B at runtime, A re-derives GREEN even though B is broken — a per-organ gate would
call A sound. The web's recursion is exactly what catches this: `histos_stand(A)` is RED
because `histos_stand(B)` is RED, regardless of A's own green cell. This is the case the MVP
is built to demonstrate (see the witness node below).

### The semantic layer — reddened-by (the reason, not just the hash)
`histos_reddened_by(node)` walks the out-edges to the *root* broken verdict and names it: "A
is red because B's verdict, which discharges A's stone `[A < B_verdict]`, no longer stands."
This is what kardia alone cannot say (it knows only "some byte changed"). It is the whole
point of layering HOROS entailment onto kardia drift.

### Permanence across sessions — the ledger
HISTOS persists the web via kardia's existing append-only ledger (`kd_ledger_append` /
`kd_ledger_load`, event-primary, last-wins fold, deterministic sequence numbers — no wall
clock). A later session loads the ledger, re-pins against the live tree (`kd_pin_all`), and
every node whose closure is unchanged KEEPS its standing; every drifted node is DUE and
re-derives. Standing is permanent-under-reverification, exactly the chosen model.

## Components (files)

- **Create** `STDLIB/iii/omnia/histos.iii` — the loom. Exports: `histos_weave()` (register
  cells + edges for the webbed set), `histos_discharge()` (discharge all edges),
  `histos_stand(node)`, `histos_reddened_by(node)`, `histos_selfprove()` (the gated MVP with
  mutation teeth). Composes `scarto_*`, `kd_*`, `hr_*`, `px_*`/`eol_*`. No `main` in the
  library path; a `histos_cli.iii` carries `main` for the gate (library-organ discipline).
- **Create** `STDLIB/iii/omnia/histos_cli.iii` — `weave | stand <node> | why <node>` driver.
- **Create** `STDLIB/scripts/histos_gate.sh` — builds the MVP web from source (closure-based,
  clean-checkout-safe, like `omnia_selfprove_gate.sh`); proves it green; MUTATES a dependency
  and proves transitive reddening with the named root cause; restores; then the cross-session
  arm (persist ledger, reload, confirm standing + drift-reddening).
- **Create** `DOCS/III-HISTOS-LIVING-PROOF-WEB.md` — the doc-of-record.
- **Reuse unchanged:** `horos.iii`, `kardia.iii`, `self_cartographer.iii`, `eidolos.iii`,
  `praxis.iii`. (If a real capacity or API limit surfaces, fix it in the owning organ with
  its own gate — not by forking logic into HISTOS.)

## The MVP — the exact-order chain (this session's work as the first web)

```
behavioral_witness ──[< membrane_verdict]──▶ membrane (pb_head_order_trusted)
                                              └──[< krisis_verdict]──▶ krisis (kr_sign)
                                                                       └──[< bigint_verdict]──▶ bigint (bigint_cmp)
```

Four nodes, three edges, each already self-proving (`ethos_r1_selfprove`, `pb_attn_selfprove`,
`kr_selfprove`, bigint's KATs). The edges and their discharge chains:

| Edge | Obligation | Discharge chain (names the live primitive) |
|---|---|---|
| witness→membrane | `[witness < membrane_verdict]` | `[witness < pb_head_order_trusted] [pb_head_order_trusted < membrane_verdict]` |
| membrane→krisis | `[membrane < krisis_verdict]` | `[membrane < kr_sign] [kr_sign < krisis_verdict]` |
| krisis→bigint | `[krisis < bigint_verdict]` | `[krisis < bigint_cmp] [bigint_cmp < bigint_verdict]` |

### The teeth (the negative that makes it a proof)
`histos_gate.sh`, after proving the web green, mutates `kr_sign` to return the wrong sign,
rebuilds, and asserts the transitive reddening — including the case that proves the web beats
per-organ gates:

- **krisis** cell reddens directly (`kr_selfprove` arm 1 checks `kr_sign()` on the truncation
  refutation; a wrong sign fails) → derived-RED.
- **membrane** cell reddens directly: its self-proof (`pb_attn_selfprove` arm 35) exercises
  engine A, which uses `kr_sign`; engine B (separate-logits) does not, so the two now DISAGREE
  and `pb_head_order_trusted` returns REFUSE −1000 → derived-RED.
- **witness** — the load-bearing case. Its self-proof is the *pure law* (`ethos_r1_selfprove`),
  which takes given signs and never calls the engines, so its cell **re-derives GREEN**. A
  per-organ gate (`omnia_selfprove_gate.sh`) would report the witness SOUND. But
  `histos_stand(witness)` is **RED**, because `histos_stand(membrane)` is red — and
  `histos_reddened_by(witness)` names `krisis` as the transitive root. **This is the whole
  value of the web in one assertion: it reddens a node whose own proof still passes, because a
  dependency broke, and names why.**

Then restore `kr_sign` and reconfirm the whole web green. Transitive reddening proven in the
artifact — not asserted.

### Cross-session
Persist the web ledger; a fresh process `kd_ledger_load`s it, `kd_pin_all`s against the live
tree, and asserts: unchanged nodes KEEP standing (no re-run needed), and a one-byte drift in
`kr_sign`'s source flips exactly the krisis subtree DUE — permanence-under-reverification,
observed.

## How it grows (and subsumes the islands)
Organ by organ: each new node registers its C2 cell + its edges to already-webbed organs;
`histos_weave` extends by one entry. `omnia_selfprove_gate.sh`'s 17 independent runs become 17
connected nodes — the gate becomes the web's node-registration pass. No big-bang wiring; the
graph accretes and the gate proves the subtree it currently covers. Partition across HOROS
registrars as the node count approaches 32, refusing (named) rather than truncating.

## Out of scope (YAGNI)
- Compiler/linker-level refusal of an undischarged export (HOROS defers this; the gate is the
  enforcement point, as today).
- Wiring all ~30 organs in this plan — the MVP is the 4-node exact-order chain; growth is
  incremental and separately gated.
- Any new reasoning primitive. The krisis kernel and EIDOLOS remain the decision substrate;
  HISTOS only connects them.
- A visualization/UI of the graph (the verdict + the named root cause are text).

## Success criteria
1. `histos_gate.sh` exit 0: the MVP web weaves, all edges discharge, all cells derived-green,
   byte-deterministic twice.
2. The mutation arm: breaking `kr_sign` reddens krisis→membrane→witness transitively, and
   `histos_reddened_by(witness)` names `krisis`; restore returns green.
3. The cross-session arm: reload keeps unchanged standing; an injected drift reddens exactly
   the affected subtree.
4. No reimplementation: HISTOS's externs show it calling `hr_*`, `kd_*`, `scarto_*`, `px_*`.
