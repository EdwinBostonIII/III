# III — Sovereign Enhancement: the coordination that makes the improver non-vacuous
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

*The self-improvement faculties (ripple improver, PCC / inductive proof generator, HW/SX silicon
organs) produce **meaningful** enhancements iff they instantiate the Enhancement Theorem
**non-vacuously**. "Rubber stamp" is the precise name for any vacuous instantiation. This document is
the spec for the requisite connections. `/architect` + `/math-olympiad`, 2026-05-29.*

---

## 0. The theorem as spec

```
⊵ := λs's. φ(s')=φ(s) ∧ 𝒱(s)≤𝒱(s')          (dominance: integrity fixed, value not lower)
⊳ := λs's. φ(s')=φ(s) ∧ 𝒱(s)<𝒱(s')          (strict)
M := { s∈𝒜 : ∀t∈𝒜. 𝒱(t)≤𝒱(s) }   s★ := min_⊑ M
h1: 𝒜 ⊆ φ⁻¹(φ(s₀))   h2: s₀∈𝒜   h3: M≠∅
⊢ s★ ⊵ s₀  ∧  ( s★ ⊳ s₀  ⇔  s₀ ∉ M )
```

A run is **meaningful** when it commits `s★` with a proof of `s★ ⊳ s₀`, or abstains with a proof of
`s₀ ∈ M`. A run is a **rubber stamp** when it emits a verdict without either proof — i.e. when some
symbol (`𝒱`, `φ`, `𝒜`, `M`, `⊳`) is bound to an organ that **cannot say no**.

---

## 1. Binding table — each symbol to the organ that must compute it (non-vacuously)

| sym | III organ(s) | must compute | rubber-stamp failure if loose | non-vacuity obligation (a proven falsifier) |
|---|---|---|---|---|
| `s₀` | sealed tree (`iiis 4e138415`, lib, corpus 561/0) | the incumbent | — | seal reproduces bit-identically |
| `φ` | `commit_gate`(5-dim) ⊕ cartographer ⊕ `aeu` ⊕ `cad` seal ⊕ corpus | the **complete** integrity vector | a quality omitted ⇒ a destructive edit passes (`ŝ` leaks into `𝒜`) | ∃ bad edit each dimension **rejects** (de-risk KAT per organ) |
| `𝒱` | `ripple_metric` (J) ⊕ `phys_cost` (ρ/gates/depth/Landauer) | a **total**, exact, **certified-monotone** value | J degenerate ⇒ all moves tie (inert); J gameable ⇒ commits noise | ∃ pair `J(a)<J(b)` with `a` genuinely worse; ∃ noise-move with J **not** raised |
| `𝒜` | gated appliers (`ripple_apply`/`extract`/`pcc_synthesize`) ⊕ `commit_gate` | realizable ∧ φ-preserving feasible set | membership *asserted* not *proven* ⇒ infeasible passes | ∃ infeasible edit **rejected** at GATE0–3 |
| `M` | `ripple_loop` ⊕ `egraph` (superposition) ⊕ `congruence` | argmax J over the admissible **frontier** | greedy-first instead of argmax ⇒ misses `s★` | ∃ 2-element frontier where the loop picks the higher-J one |
| `s★` | `ripple_loop` selection ⊕ `cad` order (`⊑`) | the emergent commit | — | determinism: same input ⇒ same `s★` |
| `⊵`/`⊳` | `commit_gate` `cg_decide` | the dominance **verdict + certificate** | bare `u32` ⇒ an **unfalsifiable** stamp | action ⊢ `s★⊳s₀`; abstention ⊢ `s₀∈M` (kernel-checked) |
| certificate | `pcc_gate` (`tc_check`) ⊕ inductive gen (`tc_natrec`/`tc_J`/`tc_wrec`) | a kernel-checked proof of `⊳`, **universal** | corpus sample only ⇒ holds on tested inputs, not all | inductive proof: ∀ inputs behaviour preserved (not 561 samples) |

---

## 2. The five connections III still needs (grounded in the current code)

- **G1 — unify `φ` and prove it complete-enough.** Today the integrity checks are scattered across
  `commit_gate`'s 5 booleans, the cartographer, `aeu`, the `cad` seal, the corpus. They must compose
  into **one** `φ` such that `φ(s)=φ(s₀)` is THE non-destruction predicate, **and** each dimension
  must carry a proven falsifier (the VACUOUS-GATE map). *This is where the "excised" ceiling `ŝ∉𝒜`
  returns as an engineering obligation: `φ_checked` must be complete enough that the destructive
  maximum is actually rejected.* (`sov_pipeline` began the unification.)
- **G2 — make `𝒱` total + certified-monotone.** `ripple_metric` computes J and `phys_cost` computes
  ρ; they must scalarize to a single totally-ordered `𝒱`, and an increase in `𝒱` must be **proven**
  to correspond to a real improvement (no metric self-gaming — the no-observational-learning law).
  Without this, `s★⊳s₀` is undetectable and the loop is inert-or-noisy.
- **G3 — make M-search real.** `rl_run` proposes then gates; it must instead **enumerate** the
  admissible equivalence class (`egraph` superposition + `congruence`) and select the **argmax** J,
  not greedily stamp the first admissible move.
- **G4 — emit the bilateral certificate.** `cg_decide → u32` must become `cg_decide → proof`: on
  action a `tc_check`-able `s★⊳s₀`; on abstention a `tc_check`-able `s₀∈M`. **Silence on abstention is
  the rubber stamp** — "0 edits because verified-optimal" and "0 edits because never-checked" are
  externally identical and must be made internally distinct by the certificate.
- **G5 — wire the inductive bridge (sample → universal).** The kernel already has the eliminators
  (`tc_natrec`, `tc_J`, `tc_wrec`); the improver does not yet use them to lift φ-preservation from
  the **finite corpus** (a sample) to a **universal** guarantee. This is what turns "561 tests pass"
  (a stamp) into "behaviour preserved for all inputs" (a theorem).

---

## 3. The coordination (one pipeline, both paths certified)

```
ripple_metric ──𝒱(propose)──▶ egraph/congruence ──M(search 𝒜-frontier)──▶
        pcc_gate + inductive-gen ──certify( s∈𝒜 ∧ s★⊳s₀ , ∀inputs )──▶
                commit_gate ──dispose( φ-complete C2 )──▶ cad(seal)

abstention:  M = {s₀}  ⟹  emit ⊢ s₀∈M  (frontier-optimal)  ⟹  0 edits WITH proof
```

Statistics **propose** (`ripple_metric`); the kernel **disposes** (`pcc_gate`/`tc_check`). No
statistic ever decides — the no-ML-on-the-deciding-path law is exactly the KT clause below.

---

## 4. The anti-rubber-stamp invariant (the meta-law)

```
NV  (non-vacuity)        ∀ gate g.  ∃x.  g(x) = reject            (no gate that cannot say no)
KT  (kernel theorem)     commit  ⟸  tc_check(proof, ⊵∧⊳)         (propose/dispose; no statistic decides)
BC  (bilateral cert.)    action ⊢ s★⊳s₀     ∧     abstain ⊢ s₀∈M  (both proofs; never silence)
─────────────────────────────────────────────────────────────────
rubber-stamp(run)  ⟺  ¬NV(run) ∨ ¬KT(run) ∨ ¬BC(run)
```

---

## 5. Honest ceilings (what cannot be reached, named not hidden)

- **`φ`-completeness is undecidable** (program equivalence). So `φ_checked ⊆ φ_true` — a **sound
  under-approximation**. The obligation is not totality but **domination**: `φ_checked` must reject
  every admissible edit that `φ_true` would (the per-organ falsifier KATs discharge this case-by-case;
  the residual is explicit, never silent).
- **Global argmax over all edits is unbounded.** So `M` is the **egraph-reachable frontier** under
  proven rewrites; `s★` is **local-optimal**, and the abstention certificate `s₀∈M` is scoped to the
  frontier — **not** a global-optimality claim (asserting global would be the pattern-#4 error).
- **The inductive bridge covers inductively-characterised behaviour** (Nat/W/Id-structured) — not
  every invariant is inductively expressible; residual sampled invariants remain, named in the φ map.

So the guarantee is exact and bounded: *within the searched frontier, under a checked-and-dominating
`φ`, every commit is a kernel-proven strict improvement and every abstention a kernel-proven
frontier-optimum.* That is the most that is true — and it is never a stamp.

---

## 6. Roadmap (dependency order; each LIBNATIVE-sealed + a non-vacuity KAT that proves the gate FAILS)

1. **G2** `𝒱` total + certified-monotone (`ripple_metric`/`phys_cost`) — the value must discriminate.
2. **G1** `φ` unified + per-dimension falsifier ledger — integrity must reject.
3. **G3** real M-search (`ripple_loop`×`egraph`×`congruence`) — selection must find the argmax.
4. **G5** inductive φ-lift (`tc_natrec`/`tc_J`/`tc_wrec` → ∀-inputs preservation) — sample → theorem.
5. **G4** the bilateral certificate in `commit_gate` (capstone composing G1–G5) — action ⊢ `s★⊳s₀`,
   abstention ⊢ `s₀∈M`, both `tc_check`-ed.

Each increment is admitted by the very theorem it serves: it raises a faculty's value (discrimination,
completeness, search, universality, certification) while leaving `iiis 4e138415` and corpus semantics
fixed — `s★ ⊵ s₀` applied to III's own improver.
