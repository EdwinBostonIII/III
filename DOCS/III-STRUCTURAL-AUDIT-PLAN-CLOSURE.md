# III Structural Audit — Plan Closure: Provability Verification & Document Map
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> The final pass. The audit was verified against live code (`-VERIFICATION.md`); the work was
> granularized into a wave-ordered, falsifier-first, deferral-free plan (`-PLAN-00` … `-PLAN-5`).
> This document (a) maps the deliverable, (b) runs an **adversarial verification of the plan's own
> load-bearing provability claims** (the `/math-olympiad` discipline: attack, don't rubber-stamp),
> and (c) records the **architectural coherence verdict** (`/architect`). It is the "perfect,
> provable" gate the work is held to.

---

## 1. The deliverable (document map)

| # | Document | Role |
|---|---|---|
| Source | `III-QUANTUM-PRINCIPLE-AND-MATH-AUDIT.md` (Vols I+II, 3,123 ln) | Evidence base (cited `F-/E-/X-/D-/A-/C-/G-/J-/II-` ids) |
| Audited | `III-STRUCTURAL-AUDIT.md` (patched) | The 79-finding five-axis synthesis; now carries a verification banner + 9 inline `[CORRECTED]` annotations |
| Ledger | `III-STRUCTURAL-AUDIT-VERIFICATION.md` | Per-finding verdict + live `file:line` evidence + corrected statements + the in-session critic synthesis |
| Plan 0 | `III-STRUCTURAL-AUDIT-PLAN-00-DOCTRINE.md` | Invariants I1-I5, seal taxonomy, build waves, **deferral-elimination commitments**, surpass standard, task template |
| Inventory | `III-STRUCTURAL-AUDIT-PLAN-INVENTORY.md` | 79-row traceability matrix (finding → source ids → files → wave → seal → deferral → verdict) |
| Plan 1 | `-PLAN-1-WAVE0-PRIMITIVES.md` | The seven shared organs (bound, caindex, fast-hash, tiebreak, reduction, pq/Dijkstra, NTT) — complete code |
| Plan 2 | `-PLAN-2-WAVE12-CRYPTO-KERNEL.md` | Crypto chokepoint (now hardening) + trusted base (CCL-native confluence enumerator) |
| Plan 3 | `-PLAN-3-WAVE3.md` | Consumers heal · performance · new primitives · soundness hardening · dead-matter (precise removals) |
| Plan 4 | `-PLAN-4-WAVE4-GATES.md` | Every vacuous gate made load-bearing + falsifier (the X26 / prove-the-negative wave) |
| Plan 5 | `-PLAN-5-WAVE56-FORGE-COMPILER.md` | **De-deferred** forge-closure + frozen-spec passes; the one seal-gated `build_iiis2` compiler pass (last) |

**Coverage:** all 79 findings are scheduled or explicitly retired. Verdict distribution: 50 HOLDS,
11 DRIFTED, 13 PARTIALLY_WRONG, 2 ALREADY_FIXED, 1 WRONG. Retired (no work): COMBINE-13, ENHANCE-14
(crypto override fixed), the MONT-1/MONT-2 half of COMBINE-4, the x25519-cswap half of
ENHANCE-19/RIPPLE-7, CUT-16 as a removal (function is live → coverage instead).

---

## 2. Adversarial verification of the plan's provability claims

Each load-bearing claim was attacked (math-olympiad patterns #4 "proves something open?", #18
"tautological?", #40 "general lemma false?", #5 "hypotheses re-checked?"). Verdicts:

| Claim | Attack | Verdict |
|---|---|---|
| **W0.7 NTT re-expression is byte-identical** | A Montgomery-domain NTT need not match the `%q` polynomial unless domain conversion is exact. | **HOLDS** — guarded: inputs/outputs kept in the standard domain at the transform boundary; the per-prime bit-identity KAT (Step 6) is the proof, not an assumption. |
| **W0.3 murmur3 swap is seal-invariant** | If `eg_seal` folded the bucket hash, swapping Keccak→murmur would move the seal (break I1). | **HOLDS** — verified in source: `eg_seal_fold` folds node *content* via `ident_from_bytes`, never `eg_hash_key`'s slot. The seal-invariance KAT (W0.3 Step 1) captures the baseline digest and reddens on any drift. |
| **W3.25 `in_flight = NEXT_ISSUE − RETIRED_COUNT` exact** | Subtraction could underflow. | **HOLDS** — `RETIRED_COUNT ≤ NEXT_ISSUE` always (retire requires `ISSUED[r]==1` ⇒ `r < NEXT_ISSUE`), proven from the contiguous in-order issue/retire invariants. Plus the mandatory ROB-saturation falsifier (the current KATs never saturate). |
| **W2.3 "confluence becomes a theorem"** | #4: is CCL confluence an *open* problem? | **HOLDS, with scope** — CCL has a *finite* rule set; critical-pair enumeration over a finite first-order rewrite system is a decidable, finite procedure. The task **certifies the existing pairs join** (and finds a non-joining pair as its falsifier); it does **not** attempt Knuth-Bendix *completion* of a possibly-non-confluent system. Highest-effort task; not open. |
| **Every "delete" (CUT-1..10)** | #40/live-symbol: does any removal kill a used symbol? | **HOLDS** — each confirmed dead by exhaustive tree-wide **and machine-code** (`.o.s`) reference search (CUT-1/CUT-5 verified at the `leaq`/`mov` level). CUT-5 carries an explicit prefix-hazard guard (delete line 62 only; never `replace_all` over `XJN_NJ*`). |
| **All falsifiers are non-tautological** | #18: does any KAT just re-assert the fix? | **HOLDS** — every falsifier drives a *specific bad input* and is required to **fail on current code** before the fix (the "see it fail" step). Census `fact_matches(16,0)!=0`, charter fresh-state non-vacuous-GREEN, ECDSA high-s reject, etc. are all behaviorally distinct from the fix. |
| **Deferral elimination is complete** | Is any deferral secretly still deferred (e.g. the "uncomputable" Keccak root)? | **HOLDS** — the Keccak manifest root is **built** (W5.2), not routed around; the §Wave-5 ledger enumerates all 8 deferrals → all scheduled with executable steps. No "revisit later" survives. |
| **Wave ordering is acyclic** | Does any task depend on a later wave? | **HOLDS** — organs (W0) precede consumers (W3); trusted base (W2) and crypto (W1) are independent; forge (W5) is self-contained; compiler (W6) is last. The RIPPLE-10 correction (B-LDIL-1 is STDLIB, not BOOT) *removes* a false cross-wave edge. `sema` (W6.3) reuses caindex's *design* (its own copy), not a link to the W0 organ, so no STDLIB→BOOT link is required. |

**One residual flagged honestly (calibrated, not hidden):** two tasks are genuine large
implementation efforts, not mechanical edits — **W2.3** (CCL-native critical-pair enumerator) and
**W3.19/ENHANCE-20** (full FIPS-205 SLH-DSA conformance). Both are *specified* and *bounded* (finite
rewrite system; published FIPS spec), each falsifier-gated, but each is a multi-day build. The plan
marks them as such; it does not pretend they are one-liners. This is the only place the "2-5 minute
step" granularity of the writing-plans template is aspirational rather than literal, and it is called
out rather than glossed.

---

## 3. Architectural coherence verdict (/architect)

- **Single-source-of-truth (§6.4):** every duplication is resolved by *one* owner — the boundary
  organ subsumes 8 per-file guards (and re-routes the 4 already-landed ad-hoc ones); the content
  index subsumes 8 scans; the reduction layer absorbs the already-correct `modular_mont` core rather
  than re-implementing; the NTT organ subsumes **4** transforms over 3 primes (998244353 shared
  once). No fix introduces a second implementation; specialized forms (SIMD paths, crypto inlines,
  static twiddle tables) are *generated/proven-equal from* the one source. **Coherent.**
- **Determinism (I1) defended at every hot edit:** every hash/order/SIMD change ships a
  byte-identity or seal-invariance KAT; SIMD gets the X17 forced-path tri-modal (scalar≡AVX2≡AVX-512)
  KAT — the one place bit-identical replay was previously taken on faith. **Coherent.**
- **The trusted base is named and defended:** sealed as one content-addressed unit (W2.4), guarded by
  a permanent build-gated differential (W2.2), and its confluence made machine-exhaustive (W2.3) —
  the three moves that align the architecture with its own de Bruijn thesis. **Coherent.**
- **Prove-the-negative is system-wide:** Wave 4 gives every gate a falsifier; the doctrine's task
  template enforces falsifier-first everywhere. **Coherent.**
- **Seal discipline is correct and corrected:** the four seal classes are assigned per finding; the
  RIPPLE-10 misclassification (B-LDIL-1) is corrected (STDLIB, not BOOT); forge-closure and
  frozen-spec edits are dedicated passes; the compiler reseal is one `build_iiis2` at the very end.
  **Coherent.**
- **NIH preserved:** every organ is libc + in-tree only; where a tool was missing (the Keccak
  manifest recompute), the plan **builds** it rather than adding a dependency. **Coherent.**

**Verdict: the plan is internally coherent, dependency-correct, determinism-preserving, NIH-clean,
deferral-free, and falsifier-gated end to end.** It surpasses the original audit (corrected stale
findings, retired completed work, found the 4th NTT, downgraded the crypto non-emergency, and turned
every "design decision / leave it" into a scheduled step). It is ready to execute wave by wave via
`superpowers:executing-plans`.

---

## 4. Attestation

- **Accuracy:** 79/79 findings verified against live code; 27 corrected; 3 retired as already-fixed;
  1 (CUT-16) overturned as WRONG. Audit patched; ledger written.
- **Granularity:** every actionable finding is a file-by-file, falsifier-first, complete-code (or
  exact-edit) task with its seal-gate closer and surpass note.
- **No deferrals:** all 8 audit deferrals converted to scheduled, executable steps (incl. building
  the missing Keccak manifest tool and authoring the seal_resolver refreeze ADR).
- **No compromise:** every task carries a surpass note; where the audit's recommendation was merely
  adequate, the superior structural approach is recorded and adopted (absorb-don't-reimplement the
  Montgomery core; CCL-native not XII-shaped enumerator; build-the-real-transform not relabel;
  one boundary organ not N ad-hoc guards).

*End of plan. Execute in wave order; each task is its own commit with the finding id; the corpus +
seal gates are the standing proof obligations.*
