# III — The Sovereign Ripple Calculus & the Ripple Loop

*Architecture answer to: "Can III understand intra-file logic and ripple/interaction
logic well enough to dynamically create selective, particular, optimal ripples through
file editing — maximizing unification and good complexity, minimizing noise and
separation?"*  (`/architect` + `/math-olympiad` rigor, 2026-05-29)

---

## 0 · Verdict (calibrated — the honest answer, not the flattering one)

**YES, precisely scoped — and III already holds ~80% of the machinery.** III can run a
**sound, monotone, propose-and-check ripple optimizer**: it proposes file edits that add
/ remove / merge functional connections, *proves* each one behaviour-preserving and
objective-improving with its own kernel, and applies only the proven ones. Every applied
ripple is a theorem.

**NO to the trap reading.** "**Optimal**" cannot mean *global* optimum, and "understand
ripple logic" cannot mean *arbitrary* comprehension — those specialize to undecidable /
NP-hard problems (see §3). A system that claimed them would be lying. The achievable
"optimal" is **local-optimal under proven-sound moves, over the decidable fragment, with
honest abstention everywhere else.** That is not a weakness — it is the only kind of
self-modification that is *safe*, and it is exactly III's existing discipline (propose
freely, the kernel decides).

---

## 1 · The Ripple Calculus (formalizing C − (A+B) = x)

Let the system be files `M = {m₁…mₙ}`. Give each set of files a **capability measure**
`Cap : 2^M → Capabilities` — *what behaviours it provably provides* (its `@export`s and
their verified contracts), **not** its line count.

- **Naive sum**   `A ⊕ B = Cap(A) ⊔ Cap(B)`   (as if independent)
- **Actual**     `C = Cap(A ∪ B)`
- **Emergence**   `x = C ⊖ (A ⊕ B)`   ← the ripple. The user's `C − (A+B) = x` exactly.

`x` is the **non-additivity** of capability under composition — the synergy/conflict term
(the software analogue of *interaction information* in a partial-information
decomposition). Decompose it onto the four targets:

| Term | Sign | Meaning | The target |
|---|---|---|---|
| `x_syn`  | **+** | A,B together do what neither does alone, via a load-bearing edge | **good complexity** (grow) |
| `x_red`  | − | A,B duplicate a capability | **unification** (merge it away) |
| `x_conf` | − | A,B are connected but the edge carries no capability | **noise** (cut it) |
| `x_sep`  | latent | A,B *should* synergize/share but don't (unrealized `x_syn`) | **separation** (connect/unify) |

### The objective — Minimal Description, Full Capability (the MDL principle)

"Good complexity vs. noise" is made **provable**, not aesthetic, by one principle:

> **The ideal structure is the *minimal* one that preserves the *whole proven capability
> set*.**  `J(G) = −DescriptionLength(G)` subject to `Cap(G) = Cap(G*)` (capability-invariant).

This gives sharp, checkable definitions:

- A ripple `r` is **noise** ⟺ `Cap(G) = Cap(G − r)` — removable with *zero* capability
  loss (provably-dead edge / orphan / accidental coupling). **Cut it.**
- A ripple `r` is **good complexity** ⟺ `Cap(G) ⊋ Cap(G − r)` — load-bearing; removing it
  *loses* a capability. It is irreducible. **Keep / grow it.**
- **Unification** = two modules/functions are congruence-equal (same capability) → merging
  shortens `DL` at constant `Cap`. **Merge.**
- **Separation** = congruence-equal capability implemented on both sides of a boundary
  (duplication) → unify across it.

So: *maximize J = compress the structure to its capability-essential core.* Good
complexity is the **Kolmogorov-irreducible** part; noise is the **compressible excess**.

---

## 2 · The hard boundary: statistics may PROPOSE, only the kernel may DECIDE

This is the load-bearing constraint (III's charter: *"statistical learning is forbidden on
any path that DECIDES; permitted only on a path that PROPOSES and is CHECKED"*).

- **Proposer** — *may* be heuristic, similarity-based, even an ML signal. It only
  *suggests* candidate ripples. Wrong guesses are free; they're filtered.
- **Decider** — *pure proof*, no statistics. For each candidate it must PROVE
  behaviour-preservation + capability-invariance + objective-gain. Every applied edit is a
  kernel theorem.

"III understands ripple logic" therefore means precisely: **the decider can *prove* which
ripples are good.** The only actionable understanding is provable understanding.

---

## 3 · The undecidability ceiling (math-olympiad pattern #4 — and why it's fine)

Each naive form of the goal specializes to a known-impossible problem:

| Naive goal | Specializes to | Verdict |
|---|---|---|
| "know if two files have the same capability" (to unify) | program equivalence | **undecidable** (Rice) |
| "find the optimal ripple structure" | modularity / graph-partition optimum | **NP-hard** |
| "detect what capability emerges" | non-trivial semantic property | **undecidable** (Rice) |
| "globally optimal edits" | — | **uncomputable** |

The resolution is not to give up — it is to act on the **decidable fragment** and
**abstain** elsewhere. III's `congruence` already does exactly this: it merges *only* on a
discharged equality proof and is silent otherwise. So the loop makes **locally** optimal,
**provably-sound** moves and *converges to a local optimum of J* — never claiming the
global one. Honest scope beats false reach.

### The 2×2 counterexample that refines the objective (pattern #40)

Tempting lemma: *"unify every congruence-equal duplicate."* **False** — and III's own tree
is the counterexample: `numera/cpufeat` (userspace) and `cpufeat_kernel` (Ring-0) are
near-identical yet **intentionally** separate (different evolution axes / rings — found and
allowlisted earlier this very project). Likewise the **two load-bearing cycles**
(`typecheck↔ccl`, `constitution↔temporal_logic`) look like noise to a naive optimizer but
are *good complexity* the session already proved irreducible.

⟹ **Intent is not kernel-provable.** The objective must preserve *capability* **and**
*witnessed intent*. The loop unifies only **accidental** duplication, never an intended
variation point, and **abstains** wherever intent is the deciding factor (carrying explicit
witness markers, like the cartographer's `gate_allow.json`). This is the same
abstain-don't-guess discipline the kernel uses everywhere.

---

## 4 · The architecture: the Sovereign Ripple Loop

```
        ┌──────────────┐   candidates    ┌───────────────────────────┐
        │  PROPOSER     │ ───────────────▶│  DECIDER  (pure proof)     │
        │ (untrusted;   │                 │  per candidate edit e:     │
        │  heuristic ok)│                 │   1 behaviour-preserving?  │ sov_pcc / congruence
        │  signals:     │                 │   2 ΔJ>0 (DL↓, Cap fixed)? │ ripple_metric
        │  cartographer │                 │   3 coherence non-↓?       │ pleroma  (H¹=0)
        │  egraph/AST   │◀── re-measure ──│   4 intent-preserving?     │ witness markers
        │  sim          │                 │   5 admissible?            │ commit_gate (§8.2)
        └──────────────┘                 └────────────┬──────────────┘
                ▲                                       │ all 5 hold
                │            loop until DRY             ▼
                └──────────────────────────────  APPLIER: emit .iii edit
                  (no proven-improving move left)  → determinism + corpus + reseal gate
```

- **Termination is guaranteed**: every applied edit strictly drops `DL` at constant `Cap`
  on a finite structure → a well-founded measure → the loop reaches a local optimum ("dry")
  and stops. (Loop-until-dry, K consecutive empty rounds.)
- **The commit_gate closure**: every self-edit passes `commit_gate` — *the gate we just
  made kernel-aware in §8.2*. So the ripple loop's edits are governed by the unified kernel
  faculties (conversion, induction, superposition, proof-carrying opt, kernel-governed
  admission). The work just finished is literally this loop's safety floor.

### What already exists vs. what is net-new

| Capability the loop needs | III faculty | Status |
|---|---|---|
| ripple graph (inter-file connections) | **cartographer** (Tarjan-SCC, instability `Ce/(Ca+Ce)`, systems map) | ✅ exists |
| intra-file semantics | **compiler** (lex/parse/sema → AST+types) + **typecheck** kernel | ✅ exists |
| unification *proof* | **congruence** (kernel-proof-gated dedup) | ✅ exists |
| coherence (good-vs-noise structure) | **pleroma** (H¹=0) + cartographer (cycles/orphans/dup) | ✅ exists |
| proof-carrying optimization | **sov_isa** (egraph propose + cost_lattice + kernel dispose) | ✅ exists (arithmetic; pattern generalizes) |
| admission of a self-edit | **commit_gate** (kernel-aware, §8.2) | ✅ exists |
| the ripple-objective metric `J` | — | **NET-NEW** |
| the certified-refactoring library | `congruence`-merge is the seed | **NET-NEW** |
| the loop driver | — | **NET-NEW** |

III is ~80% of the way there: **every deciding organ exists**; the net-new parts are the
*objective metric*, a *library of certified edit-transformations*, and the *driver* — all
compositions, all gated.

---

## 5 · Decisions (ADRs)

- **ADR-1 — Optimality is local-under-proof, never global.** The loop converges to a local
  optimum of `J` via sound moves; it *never* claims the global optimum (NP-hard) and
  abstains on the undecidable fragment. Honest scope is a feature.
- **ADR-2 — Proposer untrusted, decider proven.** Statistics/heuristics confined to
  proposal; every applied ripple is a kernel theorem. (The charter, enforced structurally.)
- **ADR-3 — Good-vs-noise = MDL.** A ripple is noise iff *provably* removable at constant
  capability; good complexity iff load-bearing. Decidable via congruence/dead-detection;
  abstain otherwise.
- **ADR-4 — Capability *and* intent preserved; certified refactorings only.** III never
  free-form rewrites itself. It applies a closed library of proven-sound transformations
  (merge-equal, cut-dead, extract-shared), each through commit_gate + the full
  determinism/corpus/reseal gate. Intended variation points (witnessed) are never unified.
- **ADR-5 — Compose, don't reinvent.** Reuse cartographer + congruence + pleroma + sov_isa
  + commit_gate. Net-new is minimal (metric + library + driver).

## 6 · Risks

| Risk | Mitigation |
|---|---|
| Self-edit miscompiles III | certified-refactorings-only + commit_gate + full reseal + CRASH-protocol; edits are *transformations with proofs*, not free generation |
| Objective-gaming (optimize the DL proxy, lose capability) | `Cap`-invariance is a **hard proven constraint**, not part of the maximand — the kernel checks real behaviour, not the proxy |
| Unifying an intended variation point | witnessed-intent markers + abstention (ADR-4); the cpufeat/cycle precedent is the test oracle |
| Loop never terminates | `J`/`DL` strictly decreases on a finite well-founded measure → provably dry |
| Proposer too weak (misses good ripples) | acceptable — a missed ripple is lost value, not a *wrong* edit; soundness never depends on the proposer |

## 7 · Roadmap (each increment ends corpus-green + sealed; bottom-up, safe-first)

1. **`ripple_metric.iii` — measure, don't edit.** Compute `J`'s components over III's
   *actual* module graph: noise (provably-removable edges/orphans), unification
   opportunities (congruence-equal pairs), separation, load-bearing edges (good
   complexity). Read-only; a genuine "use on III" (III measures its own ripple structure
   *provably*). KAT with falsifiers. **The safe foundation — no self-editing yet.**
2. **One certified refactoring: congruence-proven unification.** Wire `congruence`'s
   existing equality proof to actually *merge* an accidental duplicate + reseal. The
   highest-value, already-validated class (the dedup discipline from `congruence`).
3. **The closed loop + commit_gate-gated application**, loop-until-dry, on the single
   refactoring class. Every edit through §8.2's gate + the reseal machinery.
4. **Expand the certified library**: cut-dead-ripple, extract-shared-capability — each a
   proven transformation with its own falsifier KAT.

### III's ripple structure *today* (grounding, from the cartographer)

**592 nodes · 1098 ripple-edges · 18 domains · 2 cycles** (live cartographer; `GATE: PASS` —
**0 dup-exports, 0 un-allowlisted cycles**). The 2 cycles are allowlisted as proven good
complexity (*not* noise). The 4 duplicate basenames
(`parse/xii_ldil/ripple/resolver_replay`) are the loop's first real questions: accidental
duplication (unify) or intended variation (preserve)?

---

## 8 · The one-sentence answer

**Yes:** III can comprehend its ripple logic well enough to make *selective, particular,
provably-good* edits to its own functional structure — as a sound, monotone, kernel-checked
propose-and-check loop over the decidable fragment — because its deciding organs already
exist and the gate that governs its evolution is already kernel-aware; it **cannot** (and
no system can) reach a *global* optimum or detect *arbitrary* emergence, and the discipline
that makes it safe is precisely the refusal to pretend otherwise.
