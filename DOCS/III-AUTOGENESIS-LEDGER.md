# III Autogenesis Ledger

The per-cycle hash-chain produced by `sanctus/autogenesis`. Each entry binds the cycle's before/after
state roots and the admitted-theorem root into a tamper-evident chain anchored to the federation
closure root (`fed_genesis`), or — when no federation genesis is set — to the deterministic genesis
tag `cad("III-AUTOGENESIS-GENESIS")`.

## Chain rule

```
ledger_0      = fed_genesis_closure_root        (or cad("III-AUTOGENESIS-GENESIS") when unset)
ledger_{n+1}  = cad( ledger_n ‖ before_root_n ‖ after_root_n ‖ theorem_root_n )
```

- `before_root` / `after_root` = `cad` over the 256-block `vbd` disk image (`ab_state_root`),
  pre- and post-stage.
- `theorem_root` = `cad` over the persisted theorem registry image (`tg_root`).
- Every term is a 32-byte content address; the chain is deterministic (same cycles → same head) and
  tamper-evident (changing any entry changes the head).

## Recorded artifacts (genesis cycle, apprentice default, hermetic run)

| Field | Value |
|-------|-------|
| `libiii_native.a` SHA-256 | `F1AF28B7DD91BC4A69CCEE7E5FEAC60ADC97DE79E6E191865DE1364BE0264E47` |
| Genesis anchor | `cad("III-AUTOGENESIS-GENESIS")` (no `fed_genesis` set in the hermetic run) |
| Ledger head after cycle 1 | `3fed1dd201b70edfd80e9ff33bfac5ee1fc08434945351ec7dc38dd608ef3042` |
| Box state root after cycle 1 | `30eaf47660ef6f8b04d13a18944a612a02f82b5b9f466be2afc542fa7de20ca5` |
| Candidates gathered | `ag_ncand` ≥ 4 (harmony baselines + refactor COMBINE/CUT) |
| Validation | `ag_valid` = 99 |
| Commit | apprentice-gated (refused without `CAP_RIGHT_AUTOGENESIS_COMMIT` or an operator/quorum signature — KAT 1409) |

## Reproduction

```
bash STDLIB/scripts/build_stdlib.sh            # PASS=605 FAIL=0, all ratchets at 0
bash STDLIB/scripts/run_autogenesis_corpus.sh  # KATs 1400-1409 = 99 + propose-only GREEN
```

The ledger head is recomputed each run; in a federated deployment with `fed_genesis_set`, `ledger_0`
becomes the federation closure root and the chain proves lawful descent of every self-modification.

## Notes

- The genesis cycle above is the apprentice default: it PROPOSES, PROVES, STAGES, and REVERTS without
  committing to the sealed tree (the `vbd` envelope is the staging area). A committed cycle requires
  `CAP_RIGHT_AUTOGENESIS_COMMIT` or a presented operator/quorum authorization.
- A self-modified III re-anchors to the same `fed_genesis` closure root, so the chain remains a proof
  of lawful descent regardless of how many cycles the loop has run.
