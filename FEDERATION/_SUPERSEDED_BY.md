# FEDERATION/ — Superseded by `STDLIB/iii/aether/fed_*.iii`

The C reference implementation in `FEDERATION/src/` is **not** linked by
the live build chain. The active production implementations live at:

* `STDLIB/iii/aether/fed_tier.iii` — 5-tier hierarchy (host / cluster /
  region / sovereign / planetary).
* `STDLIB/iii/aether/fed_sybil.iii` — Sybil resistance (PoW-stake hybrid).
* `STDLIB/iii/aether/fed_eclipse.iii` — Eclipse-attack detection
  (peer-set divergence).
* `STDLIB/iii/aether/fed_admit.iii` — Planetary-tier admission gates.
* `STDLIB/iii/aether/fed_genesis.iii` — Genesis-vector binding (D17).
* `STDLIB/iii/aether/fed_seal.iii` — Cross-tier seal anchoring.

Together these implement R1.B2 (`DOCS/III-FEDERATION.md`).

## C-only surface still pending port (RITCHIE Stage 1.9 honesty amendment)

Supersession is **not yet complete**. The C reference carries a **4-tier
outbound persistence model** (transient / host_file / federation /
constitutional) and explicit **quorum specifications** (3/2, 5/3, and
federation-wide unanimous-consent) that the live `aether/fed_*.iii` family
does not yet implement. **Reconciliation = RITCHIE Stage 7.29** (add the
4-tier persistence model + quorum discipline to `aether/fed_tier.iii`).
The Byzantine-safe quorum mechanism itself (HotStuff BFT) is **Stage 5**.
See `DOCS/CONVERGENCE-AUDIT.md`.

## What this directory still contains

| File | Role |
|---|---|
| `README.md` | R1.B2 specification narrative — keep. |
| `src/*.c` | C reference implementation — historical. |
| `tests/*.c` | Reference test bench — historical. |

## Action policy

* **Do not** add new functionality to `src/` or `tests/`. New work goes
  into the appropriate `STDLIB/iii/aether/fed_*.iii` module.
* **Do** keep `README.md` updated when the spec evolves.

## Cross-reference

* Spec: `DOCS/III-FEDERATION.md` (R1.B2)
* Live impls: `STDLIB/iii/aether/fed_*.iii` (six modules)
* Index: `R1-SUBSYSTEMS.md` (repo root) — search for `FEDERATION/`
