# III Structural Audit — Plan Part 4 · Wave 4: Vacuous gates made load-bearing
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> **✅ AUDIT-VERIFIED INTEGRATED (2026-05-30).** Every W4.1–W4.5 gate is live in the working
> system, load-bearing, and falsifier-gated: charter_terminal self-populates; proof_pair /
> proof_ripple_corpus_equiv_verify / babel_intent_receive / quality_q7 lint / resolver_replay /
> xii_curate / mandate / pattern_set_fed_fetch / dynamic_impact / resolution_init / base32 /
> reflection / xii_emit_gen all made load-bearing with prove-the-negative KATs (corpus 700,
> 903, 904, 940–950). Confirmed by `build_stdlib` PASS=429 FAIL=0 (forge/trusted-base/cartographer
> green) + fast_check on each falsifier. (Commits pending the user's go-ahead.)


> Read `-PLAN-00-DOCTRINE.md` + `-VERIFICATION.md` first. Seal class: **STDLIB_GATE**. Line numbers
> observed 2026-05-29, advisory. **This whole wave is the system-wide form of invariant I4 +
> `feedback_no_autogen_stub_prove_negative` + the §6.5 synthesis: every gate must be able to say
> *no*, and that ability must be *witnessed by a falsifier KAT that drives a bad input to a
> rejection.*** The unifying defect (RIPPLE-14, the X26 root cause) is a lifecycle bug: a registry
> populated only by a private function reachable from the selftest, so the production path and the
> test path see different module states → a sealed false-GREEN over an empty registry.

**The Wave-4 doctrine, applied to every gate below:** resolve the per-gate binary explicitly (no
"superposition" — ENHANCE-17/CUT-15): either (a) **make it load-bearing** — the return must depend on
the real computation, the registry must be **self-populating** on the production path (not only from
the selftest), and a falsifier KAT must prove it rejects a bad input; or (b) **remove it** where
verification confirms no check was ever intended (the honest move only when there is genuinely nothing
to compute). Surpass-only defaults to (a).

---

## W4.1 · The lifecycle root: self-populating gate entries (RIPPLE-14 / II-CHARTERTERMINAL-1) [HOLDS]

**Verified (in-session):** HOLDS. `charter_terminal.iii ct_run_charter` (`@export`, :177) folds
`CT_CLAUSE_COUNT` (:178); the populator `ct_register_all` (:190) is **not** `@export` and is called
only from `ct_selftest` (:231). A stranger calling the public gate with `CT_CLAUSE_COUNT==0` gets an
empty loop → `ct_seal_verdict(0)` → returns `CT_VERDICT_GREEN` (99): a sealed false-GREEN over an
empty registry. This is the template defect for the whole X26 family.

**Files:** Modify `numera/charter_terminal.iii`; Test: extend `corpus/{NNN}_charter_terminal` (the
existing `ct_selftest` already has the canary arm at :238-239).

- [x] **Step 1 — Falsifier KAT first (fresh-state):** in a fresh process state (no prior
  `ct_register_all`), call `ct_run_charter()` directly and assert it does **NOT** return
  `CT_VERDICT_GREEN` over the empty registry — it must either self-populate first or refuse. Confirm
  it FAILS today (returns 99 over the empty registry).
- [x] **Step 2 — Make the entry self-populating.** At the top of `ct_run_charter`, if
  `CT_CLAUSE_COUNT == 0u32` (or always, idempotently) call `ct_register_all()` so the **production**
  path populates the thirteen clauses itself — the registry is no longer reachable only from the
  selftest. (Keep `ct_register_all` private; just call it from the public entry.)
- [x] **Step 3 — Add an empty-registry guard as defense in depth:** if after `ct_register_all`,
  `CT_CLAUSE_COUNT != CT_INVARIANTS`, return a RED code rather than seal an empty/partial verdict.
- [x] **Step 4 — Run:** the fresh-state falsifier now passes (self-populates → real verdict); the
  existing canary arm (:238-239, registering `CT_KIND_CANARY` drives RED at index 14) still passes;
  `ct_selftest()==99`. Commit: `fix(charter_terminal): RIPPLE-14 self-populating terminal gate (no sealed false-GREEN over an empty registry) + fresh-state falsifier`.

## W4.2 · The X26 vacuous-gate set, each made load-bearing + falsifier (ENHANCE-17 / CUT-15) [HOLDS]

**Verified:** all named gates exhibit (or, for `resolver_memo`/`resolver_replay`, are demonstrably
untested for) the vacuity today; none was touched by the recent G1–G5 commits. Per gate, apply the
W4.1 doctrine. **CUT-15 binary:** `quality_q7`'s check (a) "no forbidden behaviour" is a bare
`g_resolver_lint_passed` flag set unconditionally with no backing lint — the clearest **removal**
candidate (or give it a real lint); decide explicitly.

Each gate is its own falsifier-first sub-task. For every one: (i) write a KAT that drives a *bad*
input/empty state and asserts **rejection** (fails today); (ii) make the return depend on the real
computation + self-populate any registry on the production path; (iii) add the positive arm (good
input → GREEN); (iv) seal gate. Schedule:

- [x] **`proof_ripple_resolution`** — "always returns one, never recomputes the roots." Make the
  verdict recompute the ripple roots and compare; falsifier: a tampered root → reject.
- [x] **`irreducibility_proof`** — "always OK, always counts to 361." Make OK depend on the actual
  irreducibility check; falsifier: a reducible input → not-OK (and the count reflects real work).
- [x] **`quality_q7`** (CUT-15) — **decide:** either back check (a) with a real forbidden-behaviour
  lint (then falsifier: a forbidden pattern → reject), **or remove** check (a) so it stops
  advertising a guarantee it does not provide. Default surpass-only = add the real lint.
- [x] **`babel_intent`** — "validates by finding a three-byte substring." Replace the substring test
  with the real intent validation; falsifier: a string containing the 3-byte substring but with
  invalid intent → reject.
- [x] **`resolver_memo` / `resolver_replay`** — guards never exercised. Add KATs that drive the guard
  conditions (memo collision / replay divergence) and assert rejection; wire the guard onto the
  production path if it is currently selftest-only.
- [x] **`xii_curate`** — "the same ceremony id finalizes twelve times." Make finalize idempotent /
  reject a re-finalize of the same ceremony id; falsifier: second finalize of the same id → reject.
- [x] **`mandate`** — "reports satisfied for a dead chain id." Make satisfaction depend on a live
  chain; falsifier: a dead/unknown chain id → not-satisfied.
- [x] **`pattern_set_federation`** — "a fetch that omits its own ancestry check." Add the ancestry
  check to the fetch; falsifier: a node whose ancestry fails → reject.
- [x] Commit per gate: `fix(<gate>): ENHANCE-17 make load-bearing + falsifier KAT (drives a bad input to rejection)`. Where (b)-removal is chosen, commit `cut(<gate>): CUT-15 remove vacuous check that advertises a guarantee it cannot provide`.

## W4.3 · Partially-built capabilities in the dynamic/resolution layers (ENHANCE-16) [HOLDS]

**Verified:** all three sub-claims exact. `dynamic_impact aggregate_ux` unimplemented;
`aggregate_perf` a stub of its contract with a sign bug on negative inputs (II-DYNIMP-1/2/3);
`resolution_init` always returns success even on a failed registration step (II-RESINIT-1);
`base32` decoder accepts illegal pad counts → decodes malformed input "successfully" (II-BASE32-2).

- [x] **`dynamic_impact`** — falsifier first: a negative-input case asserting `aggregate_perf` returns
  the correct (sign-correct) value, and `aggregate_ux` returns its real contract value (not a stub).
  Fail first; implement both fully (no stub, no sign bug); pass.
- [x] **`resolution_init`** — falsifier first: a deliberately failing registration step asserting
  `resolution_init` returns **failure** (today returns success). Fail first; thread the registration
  return; pass.
- [x] **`base32`** decoder — falsifier first: an input with an illegal pad count is **rejected**
  (today decodes "successfully", II-BASE32-2). Fail first; add the RFC 4648 pad-count validation
  (`=` count ∈ {0,1,3,4,6} per final quantum); pass. (The builder-return half of base32 is W0.1.)
- [x] Commit per: `fix(<mod>): ENHANCE-16 complete the declared capability + falsifier`.

## W4.4 · `reflection_constrained`/`reflection_governance` contract mismatch (RIPPLE-13) [PARTIALLY_WRONG]

**Verified:** `F-RFLG-1` **HOLDS verbatim** — `reflection_governance` gate requires `AMEND (0x4000)`
while `reflection_constrained` dispatcher requires `ATTEST (0x0800)`; a capability satisfying one
fails the other, invisible in selftest only because the root cap grants every bit. `F-RFLC-2` (the
4096-vs-80-byte buffer mismatch) is real in spirit; the specific "80 byte" is imprecise — the
implementer must measure the actual producer/consumer sizes.

- [x] **Step 1 — Falsifier KAT first (the part the selftest hides):** construct a capability that
  grants **exactly one** of {AMEND, ATTEST} (not the all-granting root) and assert the cooperating
  path is **consistent** — today it fails one side. Fail first.
- [x] **Step 2 — Make the right a single shared constant.** Decide the correct required right for the
  cooperating operation and define it **once** (`REFLECT_REQUIRED_RIGHT`), referenced by both the
  governance gate and the constrained dispatcher (eliminate the two independent declarations that
  happen to agree only under the root cap).
- [x] **Step 3 — Make the buffer size a single shared constant.** Measure the actual producer write
  size and consumer allocation; define `REFLECT_BUF_BYTES` once; both modules size from it (close
  F-RFLC-2's producer/consumer mismatch). Falsifier: a producer write at the true max must fit the
  consumer's allocation (today it overruns).
- [x] **Step 4 — Run:** the single-right KAT passes; buffer KAT passes; commit:
  `fix(reflection): RIPPLE-13 single shared right + buffer-size constant (close AMEND≠ATTEST and the producer/consumer overrun)`.

## W4.5 · `xii_emit_gen_produce` — keep + cover (CUT-16) [WRONG → keep+KAT]

**Verified:** **WRONG.** The premise "no live caller of consequence" is false — `xii_emit_gen_produce`
has a load-bearing build-time caller (`gen_xii_lattice…`, the emitter-catalog generator). It is **not**
dead; do **not** remove it. The latent/forward-looking concern (the emitted catalog) is addressed by
*testing* the catalog, not by removal.

- [x] **Step 1 — Falsifier/coverage KAT first:** assert the emitted catalog `xii_emit_gen_produce`
  generates is well-formed (every cell emits the expected fragment; no crypto horizon `< 24` emits a
  curated body — cross-checks the W1.1 chokepoint). Fail first if the catalog is currently untested.
- [x] **Step 2 — Record the corrected status** (no removal): annotate the function with its live
  caller and the coverage KAT id.
- [x] **Step 3 — Run; pass.** Commit: `test(xii_emit_gen): CUT-16 cover the live emitter catalog (function is NOT dead; removal premise was wrong)`.

---

### Wave-4 completeness check
Every gate the audit names is scheduled with the same discipline: a falsifier KAT that drives a bad
input to a rejection (proving the gate can say *no*), the return made to depend on the real
computation, and any registry made self-populating on the production path so the test and production
paths see the same state (RIPPLE-14 root). The remove-vs-complete binary is resolved explicitly per
gate (no superposition). CUT-16's removal is **retired** (the function is live; replaced by coverage).
This wave operationalizes the §6.5 synthesis — "prove the negative" — system-wide. **Next:**
`-PLAN-5-WAVE56.md` (the de-deferred forge/frozen passes + the seal-gated compiler pass).
