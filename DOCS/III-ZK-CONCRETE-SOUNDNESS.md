# III zkVM — Concrete Soundness Accounting (the quantitative oracle)

> **The honest word is the asterisk.** Everywhere the zk gate / docs / commits say a gadget is **SOUND**, it means
> **STRUCTURALLY sound**: *no prover can bypass the binding* (the permutation challenge is FS-derived from the
> committed access columns; a prover-chosen α is rejected — proven by the `zk_perm_malicious` / `ZK-FUSED arm 5`
> oracles). It does **NOT** yet mean **production-secure**. This file is the concrete-security number — the
> quantitative analog of the malicious-prover oracle: don't ship "SOUND" meaning 27 bits when the reader hears 128.

## Parameters (as built)

| Parameter | Value | Notes |
|---|---|---|
| Field `p` | `998244353` | `log₂p = 29.897` bits — a **30-bit** NTT-friendly prime |
| Blowup `B` | `4` | LDE rate `ρ = 1/4` (`D = B·N`) |
| FRI queries `Q` | `16` | `ZKAIR_QUERIES[16]` |
| Rows `N` | `8` | small; `D = 32` |
| Constraints | `≤ 17` | the fused zkVM |
| FS hash | bespoke square-mix (`air_perm_field`) + keccak Merkle | challenge derivation is NOT yet a vetted hash |

## Per-check soundness error (Schwartz–Zippel / FRI, union bound)

| Randomized check | Error ≈ | Bits | Limited by |
|---|---|---|---|
| Trace commitment (keccak Merkle) | `~2⁻¹²⁸` | 128 | keccak — **not** the bottleneck |
| Constraint-combination challenge (`air_derive_alphas`) | `~#con/p ≈ 17/2³⁰` | **~26** | 30-bit field |
| Permutation `α,β` (grand-product collision) | `~2n/p ≈ 16/2³⁰` | **~26** | 30-bit field |
| FRI folding challenges (`log₂D = 5` rounds) | `~5·deg/p` | **~25** | 30-bit field |
| FRI queries (`Q=16` at `ρ=1/4`) | `(1−(1−ρ)/2)^Q = (5/8)¹⁶` | **~11** | query count (the weakest) |
| Fiat–Shamir grinding | prover grinds `~2²⁷` to bias any one challenge | **~27 work** | 30-bit challenge space |

## Bottom line

- **Concrete soundness ≈ 2⁻¹¹** (dominated by the 16 FRI queries, unique-decoding regime); `~2⁻¹⁶` under a more
  conservative list-decoding count.
- Even with **infinite** FRI queries, every algebraic + folding challenge is **capped at ~2⁻²⁷ by the 30-bit field**.
- A determined prover can **grind ~2²⁷** (minutes-to-an-hour in C) to bias a challenge toward a colliding value.
- A production zkVM targets **80–128 bits**. **We deliver ~11–27.** The gap is *fundamental to the base field* — it
  is not a bug in any gadget; it is the field size.

## The two distinct weaknesses (do not conflate)

1. **Challenge-space size (30 bits)** → `~2²⁷` grinding + `~2⁻²⁷` cap, **uniform across ALL checks** (combination,
   permutation, FRI folding). This is the production blocker.
2. **`air_perm_field` is a bespoke hash**, not vetted — may admit an *algebraic shortcut* solving for a colliding α
   *below* `2²⁷`. Route FS challenges through **keccak** (already in the Merkle path). Cheap, correct — do regardless.

## The fix path (audit → number → targeted knob)

The number above shows **FRI is also weak** (folding capped at `2⁻²⁷`, queries at `2⁻¹¹`), not just the algebraic
challenges. Per the standard decision:

- **FRI weak ⇒ EXTENSION-FIELD challenges** (the production knob): the trace stays base-field, but the FS challenges,
  FRI folding, and OOD point lift to `GF(pᵏ)` with `pᵏ ≥ 2¹⁰⁰` (`k=3` → `2⁹⁰`). Touches field ops / NTT / FRI /
  Merkle — **build carefully, not blind** (it can redden the whole gate).
- **Cheap interim (brings everything to the 27-bit field cap, NOT production):** (a) keccak FS hash; (b) bump
  `Q = 16 → ≥ 27` so the FRI queries reach the field cap; (c) repeated independent challenges `k=3` for the *algebraic*
  checks → `2⁻⁸¹` for the permutation/combination *only* (FRI still field-capped). Interim ≠ production.

## Status ledger

- ✅ STRUCTURAL soundness (no bypass of the binding) — proven by the malicious-prover oracles. **Not blocked.**
- ⛔ PRODUCTION concrete soundness (80+ bits) — **blocked on extension-field challenges.** This is THE bottleneck
  between demo and production; surpassing it (not deferring) is the next phase.
