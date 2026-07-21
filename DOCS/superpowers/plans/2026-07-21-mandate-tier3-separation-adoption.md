# Mandate Engine — Tier 3: separation measured on real history; adoption through governance

> **For agentic workers:** Use `superpowers:executing-plans` (subagents BARRED — no subagents on III).

**Goal:** A candidate mandate is adopted ONLY if its verdict-map is admissible (DOKIMASIA) and its
separation on REAL labeled history clears the threshold — and adoption walks the live
`governance.iii` state machine to SEALED, with the quorum-less promote proven to REJECT.

**Architecture:** `mandate_gate.sh` derives labeled instances LIVE from git history (BAD = the
targets of Revert commits — claims machine-contradicted by the repo's own record; GOOD = recent
claim-commits never reverted, balanced count), scores the hand-written baseline predicate P0
("claims a state, carries no gate/corpus evidence in the same commit"), assays P0's verdict
bitstring through `dokimasia_cli.exe`, computes separation, and adjudicates: cleared → the
`mandate_adopt_cli.exe 1` path (propose → sandbox → trivial-cert prove → 2y/1n vote → promote
ACCEPTED → seal SEALED); not cleared → `mandate_adopt_cli.exe 0` refuses adoption with nothing
proposed. The refusal branch is ALSO exercised every run (teeth).

**Honest boundaries (named, not hidden):** n is small (the branch carries 2 reverts) — the rig
reports its probe table and refuses to adjudicate below 2+2; MANTIS-proposes-a-predicate is
DEFERRED until the recorded mantis.iii WIP lands (concurrent-session law) — the scoring +
adoption machinery this tier builds is exactly what that step will plug into; a candidate that
fails separation is REFUSED adoption and that is a lawful green outcome of the gate.

**Governance facts (verified from source + corpus 1456):** statuses PENDING 0 / SANDBOXED 1 /
PROVEN 2 / ACCEPTED 3 / REJECTED 4 / SEALED 5; votes only in PROVEN; threshold yes*3 >= 2*(yes+no);
promote without quorum PERMANENTLY REJECTS (-6) and a re-promote is -7; the trivial old==new cert
path is `governance_prove_equivalence(pid, 5, 5, 0)`.

## Tasks

- [ ] `STDLIB/iii/omnia/mandate_adopt_cli.iii` — driver: selfprove arms (lifecycle to PROVEN;
      quorum-less promote REJECTS permanently; votes refused outside PROVEN; full adoption to
      SEALED) + rig mode (`1` = adopt to SEALED exit 0; `0` = refuse, nothing proposed, exit 1).
- [ ] `STDLIB/scripts/mandate_gate.sh` — the rig: derive/label/score/assay/adjudicate + driver
      selfprove + refusal-branch teeth + two-run byte-determinism. Named `*_gate.sh` so its GREEN
      pins as `[gate_green < exit_zero]` in the live trace (the engines compose).
- [ ] Commit: "TIER 3: separation measured on the repo's own record; adoption through the live governance machine"
