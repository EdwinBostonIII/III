# GENESIS-VECTOR/ — Superseded by `STDLIB/iii/sanctus/genesis.iii`

The C reference implementation in `GENESIS-VECTOR/src/` is **not** linked
by the live build chain. The active production implementations live at:

* `STDLIB/iii/sanctus/genesis.iii` — Legitimate-signing model with
  polymorphic packaging, Trinity-gated first invocation.
* `STDLIB/iii/aether/fed_genesis.iii` — Federation-side genesis-vector
  binding for cross-tier seal anchoring.

Together these implement D17 (`DOCS/III-GENESIS-VECTOR.md`).

## C-only surface still pending port (RITCHIE Stage 1.9 honesty amendment)

Supersession is **not yet complete**. The C reference carries the full
**deployment-installer** half of D17 that the live `.iii` does not yet
implement: **7 packaging targets** (MSI / DEB / RPM / PKG / ARMV8_DEB /
RISCV_DEB / EMBEDDED), **6 signing authorities** (DigiCert / Sectigo / … /
GPG), the Trinity 4-flag pre-discharge bundle, certificate-validity policy,
and post-install verification. **Reconciliation = RITCHIE Stage 7.26**
(`sanctus/genesis_deploy.iii`). See `DOCS/CONVERGENCE-AUDIT.md`.

## What this directory still contains

| File | Role |
|---|---|
| `README.md` | D17 specification narrative — keep. |
| `src/*.c` | C reference implementation — historical. |
| `tests/*.c` | Reference test bench — historical. |

## Action policy

* **Do not** add new functionality to `src/` or `tests/`. New work goes
  into `STDLIB/iii/sanctus/genesis.iii` or `STDLIB/iii/aether/fed_genesis.iii`.
* **Do** keep `README.md` updated when the spec evolves.

## Cross-reference

* Spec: `DOCS/III-GENESIS-VECTOR.md` (D17)
* Live impls: `STDLIB/iii/sanctus/genesis.iii`, `STDLIB/iii/aether/fed_genesis.iii`
* Index: `R1-SUBSYSTEMS.md` (repo root) — search for `GENESIS-VECTOR/`
