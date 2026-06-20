# III — Trajectory Audits & the Stubborn-Determinism Theorem
### Assuring an inverse-form system by the geometry of its execution, not its destination
> **Date:** 2026-06-20 · **Author pass:** /architect · /creative-solve · /math-olympiad (adversarial rigor)
> **Status:** RETRACTED-IN-PART (adversarial pass, 2026-06-20). The TA *framework* (§2) is a sound testing
> idea. The "theorem" (§3) does **NOT** survive as a theorem and the §-1905 demo is **NOT** the evil-twin of
> XII/nous — it folds a hand-authored integer sequence, not a real III execution. See §0 (Retraction).
> **Files:** `STDLIB/iii/omnia/dome_audit.iii` · `STDLIB/corpus/1905_dome_trajectory_audit.iii` (a
> self-demonstrating DOME demo — honest about being abstract; the REAL inverse-XII is `1906`, folding
> `xii_rewrite_apply_one` + `cad` sha256).

---

## 0. RETRACTION (adversarial verification, per the /math-olympiad discipline)

A fresh-context adversarial pass refuted the headline claims; recording it honestly:

- **§3 is not a theorem.** P1 (determinism) is the *definition* of a pure function, and `1905`'s
  `dome_w2 == dome_w` re-ran the identical hardcoded emit sequence — it proves the hash is a function,
  nothing about the substrate. P2, with the FNV gap honest, reduces to "sha256 has sha256's properties"
  (verifiable-logging re-labeled — established, not new). P3 (O(active) bound) is **contradicted by the
  code**: `soc_active_max` rescans the whole log per call. Verdict: **no confident theorem.**
- **`1905` is not XII's/nous's evil-twin.** It calls zero `xii_`/`nous_`/`cad_` symbols; the "rewrite
  system" is three integer constants and the result term is typed in by hand. It demonstrates *itself*.
- **Root cause:** the documented `apply_to_real_not_toy` trap — escalating descriptions over toy substrate.
- **Correction:** `1906_xii_inverse_real.iii` folds a REAL `xii_rewrite_apply_one` normalization, witnessed
  by REAL `cad` sha256 — closing P2 (real cryptographic assurance) and making it genuinely XII's inverse.

The §2 framework below stands as a *methodology*; §3 stays only as a recorded, refuted claim.

---

## 1. THE KAT FALLACY IN AN INVERSE SYSTEM

A Known-Answer Test verifies the **destination**: run f, assert `result == 42`. For a deterministic
theorem this is perfect. For an inverse-form society whose worth is **how it survived** — its rewinds,
its retained provenance, its cross-perception — a destination check validates the **shadow, not the
object**. We must assert the **fluid geometry of the execution itself**.

## 2. THE TRAJECTORY AUDIT (TA) — three structural assertions

| TA | Asserts | `dome_audit` |
|----|---------|--------------|
| **A. Provenance** | the system BLED — it identified a catastrophe, rewound, abandoned a branch | `ta_provenance_ok(prov)` |
| **B. Shadow Race** | the same volatile stream fed to BOTH twins; passes on the **asymmetry of survival** (A FATAL, B ALIVE), never a numeric equality | `ta_shadow_race_ok(a,b)` |
| **C. Lasso Resonance** | the **topology**: a consequence closed on itself (a lasso WAS seen) AND the lived outcome differs from the immediate temptation (it saw past the bait) | `ta_lasso_resonance_ok(rec,active,bait)` |

**Divergence Signature:** the dome's witnessed evasion is valid iff its witness **differs from the
classical deterministic witness** AND is **backed by provenance** — a proven evasion the determinist
could not find (`ta_divergence_ok`). This replaces `EXIT == 99` for dome modules: assurance is the
*signature of a proven evasion*, not a destination code. (1905 bridges to the build harness by exiting
99 iff the TA passes; the full vision is build-level Divergence-Signature checking.)

**Proven (1905):** A/B/C all hold on the rewrite shadow-race; teeth = disabling the rewind makes
`prov == 0`, which TA **A** catches (exit 12). The audit tests the reflex; remove the reflex and it fails.

---

## 3. THE STUBBORN-DETERMINISM THEOREM

> *Can a frozen, witnessed event-history be as stubbornly deterministic and secure as a theorem, while
> spending bounded effort only on the fluid edge?*

Let `H = (e0,…,e_{n-1})` be an append-only history, `φ` a pure fold, `W(H)` a deterministic digest.

1. **Determinism (stubbornness) — HOLDS unconditionally.** `φ(H)` and `W(H)` are pure functions of an
   immutable `H`; re-evaluation is byte-identical. *The frozen history is the axiom-set, the fold the
   derivation, the witness the proof.* **Proven:** 1905 `dome_w2 == dome_w` on a replayed evade-history.

2. **Assurance (tamper-evidence) — HOLDS, but split honestly.** Any single-event change moves `W`.
   - *Tamper-DETECTION* holds for any avalanching `W` (incl. the POC's FNV multiply-add). **Proven:**
     1905 `dome_w3 != dome_w` under a one-event tamper.
   - *Adversarial RESISTANCE* (no forgeable colliding history) holds **iff `W` is collision-resistant** —
     i.e. III's real **sha256** (`numera/cad`), **NOT** the FNV hash the POC uses. The POC demonstrates
     determinism + detection; **security-grade assurance is a one-swap upgrade to cad, not yet built.**
     *(This gap was caught by the adversarial pass — an FNV hash reads as "a witness" but is trivially
     collidable; calling it "secure" would be the over-claim.)*

3. **Bounded fluid regard (efficiency) — HOLDS for memoizable folds.** A rolling `W` is O(1) per append
   (frozen prefix cached); a monotone/incremental `φ` costs O(active), not O(n). Non-memoizable folds
   are O(n) — a stated boundary.

**Verdict (calibrated):** **YES** — the inverse substrate is as stubborn/deterministic as a theorem and
tamper-evident, at bounded fluid cost — **provided** (a) the witness is cryptographic (`cad` sha256) for
adversarial security, and (b) the fold is memoizable for the efficiency bound. The construction reduces
to **verifiable logging** (Merkle / transparency-log), which is established-sound — so this is not an
open conjecture but a known-good pattern applied in the *inverse* direction. The novelty is the inversion
(state-as-fold) and the bounded fluid edge, **not** the cryptography.

---

## 4. NEXT (to discharge the two conditions)

1. **Swap the witness to `cad` sha256** in dome_society / dome → security-grade assurance (resistance,
   not just detection). The one honest gap above.
2. **Memoize the frozen-prefix fold** (cache `φ`'s prefix contribution) → prove the O(active) bound live.
3. **Build-level TA**: teach `build_stdlib` to assure dome modules by Divergence Signature, not EXIT==99.
