# THE AUXESIS ANABOLIC FLYWHEEL — Implementation Plan

> **Complement to Plan 1** — the outward exact-exploit revenue engine (MUSE → MEMBRANE →
> DECIDER → WITNESS+MINIMIZE → GATE → REPLAY → PACKAGER). Plan 1 is unnamed in the
> conversation; this document names it **THERA** (θήρα, *the hunt*) so the two organs can be
> spoken of as a pair. **THERA is assumed carried out exactly as written.** AUXESIS adds
> nothing to THERA's contract; it wraps a compounding loop around it.

> **For the implementer:** Per the project's standing rule *(no subagents on III — the
> self-hosting core is worked in a single context)*, this plan is executed **inline**, task by
> task, against the live tree. Steps use checkbox (`- [ ]`) syntax for tracking. "Tests" here are
> **III-native**: a corpus gate `.iii` that re-derives the claim through `iiis-2`, plus, for
> money-bearing claims, a **witness-replay against the real public artifact** — never a
> host-language test runner (this codebase has no Python; verification *is* corpus + replay).

**Date:** 2026-07-19
**Goal:** Turn THERA's three discarded exhaust streams — *refusals, findings, payouts* — into permanent, compounding structure, so that every hunt makes the next hunt **wider** (more of the bug-space becomes exactly provable), **harder to dispute** (III itself is hardened by its own weapon), and **higher-paying** (an anonymous standing that attracts invited work).
**Architecture:** One anabolic organ, **AUXESIS**, sits strictly *downstream* of THERA and consumes only THERA's exhaust plus III's own body — never external targets. It has three aspects, each the natural consequence of *being growth*: a **RATCHET** that reaches toward what refused, an **INCORPORATION** that folds every proof into III's tissue and turns the decider inward, and a **STANDING** that accretes wins as anonymous, replayable, generation-chained weight.
**Tech Stack:** `iiis-2` self-hosted compiler; existing organs `katabasis/soma.iii`, `aether/testament.iii`, `numera/slhdsa.iii`, `numera/cegar_refine.iii`, `numera/conjecture_refute.iii`, `numera/causal_scm.iii`, `omnia/eidolos.iii`, `omnia/fold.iii`, `omnia/isub.iii`/`numera/ser_isub.iii`, `omnia/exec_cert.iii`, `aether/cap_zkp.iii`; the `numera/galois.iii` · `gf_poly.iii` · `field.iii` · `groebner.iii` rank stack (ZK lane); the corpus-gate discipline under `STDLIB/corpus/`.

## Global Constraints

*(Copied from the project's standing laws; every task's requirements implicitly include these.)*

- **Compiler is `iiis-2`** (`iiis-2.exe`; `iii.exe` is the CLI). Probe an organ by compiling it to the scratchpad — a silent **exit 14** is the 64-local-slot ceiling, not success.
- **No Python. No host test runner.** Verification = corpus gate `.iii` re-derives the claim + `run_corpus` (run it exactly once per change) + determinism gate + witness-replay for money claims.
- **Additive only on the tree.** The branch has active WIP (mathesis-creator-tier). AUXESIS creates new files where possible; any touch to `soma.iii` / `testament.iii` is **purely additive** (new constants, new handlers, new sibling object) and **never rewrites a frozen format**. `testament.iii` v1 is FROZEN at 7 sections — AUXESIS reuses its crypto primitives, it does not alter the object.
- **Never outrun the faucet.** AUXESIS is built *behind* THERA, gated by evidence THERA is already producing exhaust worth compounding. No aspect is built ahead of the stream that feeds it.
- **Proof-gated growth.** Nothing enters III's body except as a SOMA claim that a gate re-derives. Phantom growth (a claimed capability with no gate) is refused by SOMA's own MATCHED/PHANTOM/DARK audit.
- **Determinism.** No wall clock, no randomness in any AUXESIS artifact — same as `testament.iii` (a pure function of the tree + THERA's logged exhaust).
- **Honest scope.** "Boundless" means *the surface grows wherever growth is possible* — not that it swallows every bug class. Provably-undecidable classes are recorded as permanent boundary, never as backlog.

---

## §0 — The complement in one breath

III already has an organ named **METABOLE** — *digestion*: it eats the foreign (the R1 404 GB feast) and breaks it down. THERA is the same gesture pointed at money: it eats a foreign contract and breaks it into a witnessed exploit. Both are **catabolic** — they break down the other for energy.

What no organ does yet is **anabolic**: build the self *larger* from the proceeds. A body that only digests and never grows is a faucet — it is exactly as capable on its thousandth hunt as its first. The user's question was not "can THERA earn?" (Plan 1 answered: yes, narrowly, lumpily). It was **"can the *possibility* of earnings become an *assurance* of near-uncontested leverage and boundless scope?"** — and *assurance* + *boundlessness* are the signature of **compounding**, which is precisely what anabolism is.

**AUXESIS is that missing organ.** It is not a second hunter. It is the growth that the hunt pays for.

```
        METABOLE  (digest the foreign)  ─┐
                                          ├─►  the catabolic half  (break down for energy)
        THERA     (hunt the foreign)    ─┘

        AUXESIS   (grow the self)        ───►  the anabolic half   (build body from proceeds)
                                                — THE MISSING SIBLING —
```

---

## §1 — What AUXESIS IS  *(ontological, not inventory)*

**The being:** AUXESIS is **the machine growing from what its hunt brings home.** Ask "what IS this?" and the answer is *anabolism* — not "a manager with a ratchet, a corpus tool, and a ledger." Its three capabilities are not features it *has*; they are what *being growth* necessarily *does*:

- **Because it IS growth, it feels where it cannot yet reach.** Every THERA refusal is a place the body stops. Growth reaches toward the edge. → the **RATCHET** aspect.
- **Because it IS growth, everything it proves becomes permanent tissue — and it strengthens its own tissue first.** Every witnessed finding is incorporated as body, and the same prover that cut the foreign is turned inward on III's own organs. → the **INCORPORATION** aspect.
- **Because it IS growth, its history of wins is carried as accumulated weight it can bear anonymously.** → the **STANDING** aspect.

None of these is bolted on. They *emerge* from the one nature, which is the transform-ontological test passed: identity over inventory. But — poetry that doesn't compile is not elevation — **each aspect is wired to a real organ and a real, gate-checked artifact** (§4, §6). The name is the being; the body underneath is exact.

**Name pairing (harmony):** `METABOLE` digests · `AUXESIS` grows. `THERA` hunts · `AUXESIS` compounds. The Greek register is native to III (SOMA=body, KARDIA=heart, ANAMNESIS=recollection, ENSOMATOSIS=embodiment); *anabolism/catabolism* is not affectation here — it is the literal metabolic vocabulary the system already speaks.

---

## §2 — The flywheel  *(systems view)*

THERA is a **line**. AUXESIS is a **loop wrapped around the line**, tapping three points and feeding each back to the front. Converting a linear extractor into a reinforcing loop is the single highest-leverage systems intervention available — it is what makes "the more you hunt, the wider you can hunt" literally true.

```
              ┌──────────────────────────  THERA (Plan 1, the line)  ──────────────────────────┐
              │                                                                                  │
   targets ─► MUSE ─► MEMBRANE ─► DECIDER ─► WITNESS+MINIMIZE ─► GATE ─► REPLAY ─► PACKAGER ─► [you file]
              ▲            ▲          │              │                                    │
              │            │       REFUSE         WITNESS                              PAYOUT
              │            │          │              │                                    │
              │            │          ▼              ▼                                    ▼
              │            │   ┌─────────────┐ ┌──────────────┐               ┌──────────────────┐
              │            │   │  RATCHET    │ │ INCORPORATION│               │    STANDING      │
              │            │   │ (reach the  │ │ (fold into   │               │ (accrete wins as │
              │            │   │  refused)   │ │  SOMA; turn  │               │  anonymous,      │
              │            │   │             │ │  prover on   │               │  replayable,     │
              │            │   │             │ │  III itself) │               │  chained weight) │
              │            │   └──────┬──────┘ └──────┬───────┘               └────────┬─────────┘
              │            │          │               │                                │
              │            └──────────┘               │                                │
              │       wider net next hunt      hardened III =                  private-audit invites =
              │      (new decider/template)  more-trustworthy witness           higher-value targets
              └───────────────────────────────────────┘◄───────────────────────────────┘
                                          A U X E S I S   (the loop)
```

**Three reinforcing loops, one hub.** The hub is *faithful capture of the three exhaust streams as addressable SOMA claims*. Get the hub right and all three loops turn:

1. **Widening loop:** refuse → RATCHET → new decider/template → DECIDER proves a wider class → fewer refusals of that shape, more of a *new* shape surface → ratchet again.
2. **Trust loop:** witness → INCORPORATION → III's own bugs found+fixed → the DECIDER's own proofs are more trustworthy → findings more credible → higher payout → more hunts → more witnesses.
3. **Access loop:** payout → STANDING → invited private audits → harder, higher-value targets → findings on subtler bugs → *new* refusals discovered at the frontier → ratchet.

Note loop 1 **auto-feeds** loop 2: a decider that can newly prove a property about a contract can prove it about *III's own organs* — Pillar 1's growth is inherited by Pillar 2 for free.

---

## §3 — The mutual-benefit ledger  *(harmonizing THERA's channel table)*

**Forward (THERA feeds AUXESIS; AUXESIS builds structure; structure flows back to THERA):**

| THERA exhaust stream | AUXESIS aspect that eats it | Permanent structure built | What flows BACK to THERA |
|---|---|---|---|
| **Refusals** (DECIDER couldn't prove) | **RATCHET** | new EIDOLOS property template · new decider organ · or a permanent-boundary marker | a **wider net** — the next hunt proves a class that used to be refused |
| **Findings** (witnessed exploit traces) | **INCORPORATION** | a certified `SM_K_FINDING` SOMA claim · III's own organs self-audited by the same engine | **more-trustworthy witnesses** (III hardened) + III's own bugs fixed |
| **Payouts** (submission history) | **STANDING** | a signed, generation-chained, ZK-attestable finding-ledger | **private-audit invites** — higher-value, less-contested targets |

**Reverse (why the dependency direction is a *feature*):** THERA is the **only** source of AUXESIS's food. No hunt → no refusals, no findings, no payouts → no growth. AUXESIS *cannot* run ahead of THERA; the "never outrun the faucet" law is enforced **structurally**, not by discipline. AUXESIS is pure downstream anabolism.

**III-in-its-own-right (the user's "even better if III gets upgraded"):**

- **RATCHET** literally adds deciders/organs — III's *provable surface grows* monotonically (gated). This is the completion of the MATHESIS thesis (III generates+proves its own capability) pointed at real adversarial pressure.
- **INCORPORATION** turns the exploit engine on III's own compiler/crypto/organs. Every III bug found+fixed is III leveling up — and it satisfies the standing methodological law *real adversarial cases > synthetic KATs*: a live drained-pool trace stresses III's exactness far harder than a hand-written micro-gate.
- **STANDING** generalizes `testament.iii` into a native *"signed, chained, ZK-attestable claim-of-competence"* faculty — usable by **any** III claim thereafter (portable anonymous provenance for anything the machine proves), not just bounties.
- **Architectural completion:** AUXESIS + METABOLE closes III's metabolism (digest **and** grow). That is a structural gain independent of any dollar.

---

## §4 — Grounding: the organs already on the die  *(plan-impl "research what exists")*

Every AUXESIS aspect composes organs that **exist and are green today** (verified 2026-07-19 by direct read, same discipline THERA used on `bmc.iii`):

| Need | Existing organ (path) | The exact hook |
|---|---|---|
| Addressable claim-space with a reserved growth slot | `STDLIB/iii/katabasis/soma.iii` | `idfold(kind,name)` address; kinds `SM_K_CORPUS..SM_K_BELIEF` with the file's own note that further kinds are *"named seats the field will absorb"* |
| Refute-or-refine loop | `STDLIB/iii/numera/cegar_refine.iii` | `cr_coarse_proves_absent` · `cr_refined_proves_absent` · `cr_spurious` · `cr_prove_absent` — genuine-CE vs spurious-CE, the ratchet's mechanism |
| Refutation search | `STDLIB/iii/numera/conjecture_refute.iii` | conjecture → counterexample |
| Signed, chained, deterministic attestation | `STDLIB/iii/aether/testament.iii` + `STDLIB/iii/numera/slhdsa.iii` | `iii_slhdsa_sha2_keygen/sign/verify` (param 2 = SLH-DSA-SHA2-256s, FIPS-205, KATs `200/770/771/996/2494-2497`) · `cad_oneshot`/`cad_compose` (hash/merkle) · parent-digest + generation chaining |
| Anonymity / selective disclosure | `STDLIB/iii/aether/cap_zkp.iii` | zero-knowledge capability proof |
| Witness trace + certificate | `omnia/isub.iii` · `numera/ser_isub.iii` · `omnia/exec_cert.iii` | the replayable trace THERA already emits (`isub_witness`) |
| Minimal cause (irreducible exploit) | `omnia/fold.iii` + `numera/causal_scm.iii` | the AITIA counterfactual over the fold |
| Property language | `omnia/eidolos.iii` | the `=`/`<`/`~` predicate templates the ratchet synthesizes |
| ZK-lane rank/nullspace (under-constraint) | `numera/galois.iii` · `gf_poly.iii` · `field.iii` · `groebner.iii` | rank deficiency = a second valid witness |

**Nothing in AUXESIS's critical path requires a new primitive.** It requires *wiring* — one hub organ, two additive claim kinds, one sibling attestation object, and the triage logic. That is the "as thin as it can be" the user intuited, and grounding confirms it.

---

## §5 — The honest heart: the provability triage  *(what "boundless" actually means)*

The rubber-duck caught the one overclaim that would fail the wall-test — *"III learns to prove anything."* It does not. When THERA refuses, the RATCHET **triages** the gap into exactly one of three seats, and only the first two are growth:

| Seat | Definition | Handling | Automatable? |
|---|---|---|---|
| **COMPOSABLE-NOW** | the refused property is a composition of *existing* deciders / EIDOLOS predicates (e.g. "a balance monotonically decreases across a call" = order-oracle ∘ arithmetic-bound) | AUXESIS synthesizes the EIDOLOS template, **gates it against the known-bug corpus**, admits it as a new capability | **Yes** — the true flywheel |
| **BUILDABLE-WITH-EFFORT** | needs a genuinely new primitive decider (a storage-aliasing analysis; a ring the arithmetic organs don't yet cover) | filed as a prioritized **research claim**; muse proposes an implementation; III+human build+prove it; it enters as a new organ, corpus-gated | **Semi** — muse-assisted |
| **PROVABLY-UNCLOSABLE** | not exactly decidable at all — economic-incentive, oracle-honesty, governance-intent, off-chain-trust | recorded as a **permanent boundary claim**; never retried; it is what keeps "boundless" from becoming a lie | **No** — and honestly so |

**"Boundless scope," precisely stated:** the provable surface **grows without a fixed ceiling over the COMPOSABLE and BUILDABLE seats**, and is **honestly bounded on the UNCLOSABLE seat**. This is the same wall-test honesty THERA held — the surface reaches wherever reaching is possible, and names the wall where it isn't. The load-bearing empirical unknown of the entire plan is the *rate* at which real refusals fall into the first two seats (§8). That rate is measured, not assumed — and it is measured on the very first afternoon (§7 Phase 0).

---

## §6 — Interfaces / data model  *(interface-first; bodies written under corpus-TDD at execution)*

> These are the **contracts** — exact names, kinds, formats, compositions, and the falsifiable gate each must pass. The `.iii` bodies are written and `iiis-2`-verified *during* execution (writing speculative unverified `.iii` here would be a placeholder in disguise and would violate the crash-audit discipline — the interface + the gate *is* the plan's non-placeholder content).

**6.1 — Two additive SOMA claim kinds** *(`katabasis/soma.iii`, additive — uses the file's documented growth slot):*
```
const SM_K_GAP     : u64 = 5u64   /* a provability gap: THERA refused here; AUXESIS reaches toward it */
const SM_K_FINDING : u64 = 6u64   /* a certified finding: a witnessed, replayable exploit trace       */
```
Address = `idfold(SM_K_GAP, gap_name)` / `idfold(SM_K_FINDING, finding_name)` — kind-separated, so a gap and a corpus gate of the same name never collide (the addressing law already guarantees this). The MATCHED/PHANTOM/DARK audit extends unchanged: a `FINDING` claim is **PHANTOM** if the ledger names it but no witness file backs it — corpus rot is refused by the organ that already exists.

**6.2 — The AUXESIS hub** *(`omnia/auxesis.iii`, new; Ring R0):*
```
fn ax_ingest_refusal(target_id: u64, prop_id: u64, why: u64) -> u64 @export   /* -> gap address; classifies into a triage seat */
fn ax_ingest_finding(target_commit: u64, prop_id: u64, witness_dig: u64) -> u64 @export   /* -> finding address */
fn ax_triage(gap_addr: u64) -> u8 @export   /* 1=COMPOSABLE 2=BUILDABLE 3=UNCLOSABLE */
```

**6.3 — The RATCHET** *(`omnia/auxesis_ratchet.iii`, new):* composes `cegar_refine` (refine-or-refute), `conjecture_refute` (search), `eidolos` (emit the template). For a COMPOSABLE gap it emits an EIDOLOS predicate composition and returns the corpus-gate path that must pass before admission.
```
fn ax_synthesize_template(gap_addr: u64) -> u64 @export   /* -> eidolos template id, or 0 if not composable */
fn ax_template_gate_path(tmpl_id: u64) -> u64 @export      /* -> path to the corpus .iii that must re-derive it */
```

**6.4 — The STANDING ledger** *(`omnia/auxesis_standing.iii`, new — a SIBLING to `testament`, reusing its crypto, NOT altering the frozen format):*
```
STANDING object  (v1, all ints u64 LE, digests SHA-256 raw 32 B):
  off 0    magic "IIISTAND" (8 B)
  off 8    version u64 = 1
  off 16   parent-standing digest 32 B          (32 zero at genesis; sha256 of parent FILE)
  off 48   generation index u64
  off 56   key param id u64 = 2                  (SLH-DSA-SHA2-256s — the testament keypair discipline)
  off 64   public key 64 B
  off 128  finding count u64
  then per finding:
     target_commitment 32 B    (sha256 of the PUBLIC on-chain bytecode / circuit — the trust anchor)
     property_id       u64     (which EIDOLOS property was violated)
     witness_digest    32 B    (sha256 of the isub_witness trace — the trace itself is NEVER in the ledger)
     verdict           u8      (1 = violated & replayed against the public artifact; 0 = refused)
  after last finding:  u64 sig_len | SLH-DSA-SHA2-256s signature over sha256(body)
```
Reuses `iii_slhdsa_sha2_sign/verify` and `cad_compose` verbatim; determinism identical to `testament` (pure function of the logged findings). **The trust anchor is the public `target_commitment` + replayability — never III's self-grade.**

**6.5 — The anonymity attestation** *(via `aether/cap_zkp.iii`):* a ZK proof of the statement *"I hold ≥N chained findings with `verdict=1` whose `target_commitment` ∈ public set S"* — **without** revealing which targets or any witness. Selective disclosure reveals a specific witness only to a paying program under its bounty terms (the only step that touches identity, and it is deliberate and per-finding). *(Feasibility of expressing exactly this statement in `cap_zkp` is a named risk — §8.4 — with a plain-signed fallback.)*

---

## §7 — The phased plan  *(harmonizing THERA's Phase 0–3; each phase ends with a GO/NO-GO)*

### Phase 0 — The tap  *(≈ ½ day; PIGGYBACKS on THERA's Phase 0 — the keystone)*

The whole flywheel turns on faithfully capturing refusals. THERA's Phase 0 already runs one known post-mortem through the DECIDER to confirm III re-derives the exploit. AUXESIS Phase 0 is a **~5-line tap** on that same run: emit each DECIDER *refusal* as an `SM_K_GAP` claim, and each *witness* as an `SM_K_FINDING` claim. **One afternoon answers both plans' first question at once.**

**Files:**
- Modify (additive): `STDLIB/iii/katabasis/soma.iii` — add `SM_K_GAP`, `SM_K_FINDING` (§6.1).
- Create: `STDLIB/iii/omnia/auxesis.iii` — `ax_ingest_refusal`, `ax_ingest_finding` only (the hub stubs that write claims).
- Create: `STDLIB/corpus/NNNN_auxesis_gap_address.iii` — the gate.

**Interfaces — Produces:** `ax_ingest_refusal`, `ax_ingest_finding` (§6.2), consumed by every later phase.

- [ ] **Step 1 — Write the failing gate.** `NNNN_auxesis_gap_address.iii`: assert `ax_ingest_refusal(t,p,w)` returns `idfold(SM_K_GAP, name)` and that re-ingesting the same refusal returns the **same** address (idempotent addressing) and a distinct finding of the same name gets a **distinct** address (kind-separation).
- [ ] **Step 2 — Compile to scratchpad, confirm it fails.** `iiis-2` the gate; expected: unresolved `ax_ingest_refusal` (not exit 14 — if 14, hoist arrays, the 64-slot ceiling).
- [ ] **Step 3 — Add the two claim kinds to `soma.iii`** (additive constants + the two ingest handlers writing into the existing claim-field).
- [ ] **Step 4 — Implement `ax_ingest_refusal` / `ax_ingest_finding`** in `auxesis.iii` (address via `idfold`, store the tuple).
- [ ] **Step 5 — Run the gate; confirm it passes; run `run_corpus` once; confirm determinism (byte-identical on re-run).**
- [ ] **Step 6 — Attach the tap to THERA's Phase 0 run.** Point THERA's DECIDER refusal/witness outputs at the two ingest calls. Run THERA's known-post-mortem falsifier.
- [ ] **Step 7 — Commit.**
```bash
git add STDLIB/iii/katabasis/soma.iii STDLIB/iii/omnia/auxesis.iii STDLIB/corpus/NNNN_auxesis_gap_address.iii
git commit -m "AUXESIS Phase 0: the tap — refusals+findings become addressable SOMA claims"
```

> **GO/NO-GO (shared with THERA):** THERA re-derives the known exploit **and** the tap records ≥1 gap + ≥1 finding as re-derivable claims. If THERA can't re-derive, *both* plans stop here at near-zero cost. If it can, you also now hold the **first real refusal** — the seed of the ratchet.

### Phase 1 — Incorporation first  *(1 week; the aspect that pays regardless)*

Order chosen by the pre-mortem: build **INCORPORATION before RATCHET**, because incorporation pays *independently of the gap-clustering rate* (it hardens III and builds the corpus no matter what), while the ratchet's value is still unproven until gaps accumulate. This de-risks the plan — Phase 1 is valuable even if Phase 2's kill-switch fires.

**Files:**
- Create: `STDLIB/iii/omnia/auxesis_incorporate.iii` — fold a `FINDING` into a permanent corpus gate + run the same DECIDER on a chosen III organ.
- Create: `STDLIB/corpus/NNNN_auxesis_finding_replay.iii` — a finding is admitted only if its witness **replays** (verdict must be re-derivable, not asserted).

**Interfaces — Consumes:** `ax_ingest_finding` (Phase 0). **Produces:** `ax_incorporate(finding_addr) -> corpus_gate_path`.

- [ ] **Step 1 — Failing gate:** assert a `FINDING` whose witness digest has no backing trace is classified **PHANTOM** by SOMA's audit and **refused** admission.
- [ ] **Step 2 — Compile, confirm fail.**
- [ ] **Step 3 — Implement `ax_incorporate`:** materialize the finding as a `STDLIB/corpus/` gate that re-runs the witnessed trace; wire SOMA MATCHED/PHANTOM/DARK over `SM_K_FINDING`.
- [ ] **Step 4 — Turn the prover inward:** run THERA's DECIDER on one real III organ (candidate: a `numera` arithmetic organ — its overflow/bound invariants are exactly the DECIDER's home turf). Record any III finding as a `SM_K_FINDING` over `kind=self`.
- [ ] **Step 5 — Run gate + `run_corpus` once; determinism; confirm a genuine III invariant is proven (or a real III bug is surfaced with a replaying witness).**
- [ ] **Step 6 — Commit.**

> **GO/NO-GO:** the incorporation gate refuses a phantom finding and admits a replaying one; the inward run either proves an III invariant or surfaces an III bug with a witness. Either outcome is a win (hardening). **This phase has no kill-switch — it pays regardless.**

### Phase 2 — The ratchet  *(1–2 weeks; EARNED by the gap-ledger, not assumed)*

Only now, with a real gap-ledger accumulating from THERA's Phase 0–1 hunts, build the widening loop — and **gate its own soundness**, because a buggy new decider is the plan's most dangerous failure (a false witness → a false submission → reputation death). Every synthesized template is admitted **only** if it re-derives the known-bug corpus *and* survives adversarial verification.

**Files:**
- Create: `STDLIB/iii/omnia/auxesis_ratchet.iii` (§6.3).
- Create: `STDLIB/corpus/NNNN_auxesis_template_soundness.iii` — a synthesized template must reproduce a known bug **and** reject a known-clean artifact (no false positive).

**Interfaces — Consumes:** `ax_triage`, the gap-ledger. **Produces:** `ax_synthesize_template`, `ax_template_gate_path` (§6.3).

- [ ] **Step 1 — Failing gate:** assert `ax_synthesize_template` on a COMPOSABLE gap emits an EIDOLOS template that (a) flags the known bug, (b) does **not** flag a clean artifact.
- [ ] **Step 2 — Compile, confirm fail.**
- [ ] **Step 3 — Implement `ax_triage`** (COMPOSABLE/BUILDABLE/UNCLOSABLE, §5) over the gap-ledger.
- [ ] **Step 4 — Implement `ax_synthesize_template`** composing `eidolos` predicates via `cegar_refine`'s refute-or-refine; wire the soundness gate as the admission chokepoint.
- [ ] **Step 5 — Adversarial verification:** before admission, the muse attacks the template with a concrete clean-but-tricky artifact designed to false-positive it. Admit only on survival. *(Amplify with `iii_adversarial_verify` if the conscience MCP is present.)*
- [ ] **Step 6 — Run gate + `run_corpus` once; determinism.**
- [ ] **Step 7 — Commit.**

> **GO/NO-GO / KILL-SWITCH:** measure the gap-ledger after THERA's first live-discovery run (its Phase 1). **If < ~15% of real refusals are COMPOSABLE-or-BUILDABLE**, the surface won't widen fast enough to matter — **stop building the ratchet** and keep only Incorporation (Phase 1) + Standing (Phase 3), which pay regardless. Do not grind a ratchet with nothing to catch.

### Phase 3 — Standing  *(1 week; anonymity-first)*

Accrete wins as anonymous, replayable, chained weight. Built anonymity-first (the pre-mortem's concentration-risk finding: a valuable pseudonym is a deanonymization target; never link all findings to one persistent public key).

**Files:**
- Create: `STDLIB/iii/omnia/auxesis_standing.iii` (§6.4) — reuses `slhdsa` + `cad_compose`, does **not** touch `testament.iii`'s frozen format.
- Create: `STDLIB/corpus/NNNN_auxesis_standing_chain.iii` — verify the signed chain and the ZK attestation roundtrip.

**Interfaces — Consumes:** `SM_K_FINDING` claims. **Produces:** `ax_stand_append(finding_addr)`, `ax_stand_verify(file)`, `ax_attest(n, set) -> zk_proof`.

- [ ] **Step 1 — Failing gate:** append 2 findings → the STANDING object's generation chains (parent digest of gen 1 = sha256 of gen 0 file); `ax_stand_verify` accepts a valid chain and **rejects** a tampered `verdict` byte.
- [ ] **Step 2 — Compile, confirm fail.**
- [ ] **Step 3 — Implement the STANDING object** (§6.4 format) reusing the testament crypto primitives.
- [ ] **Step 4 — Implement `ax_attest`** over `cap_zkp`: prove "≥N chained `verdict=1` findings with `target_commitment` ∈ public S" without revealing which. *(If `cap_zkp` cannot express this statement — §8.4 — fall back to plain SLH-DSA selective disclosure per finding; lose set-anonymity, keep per-finding replayability.)*
- [ ] **Step 5 — Run gate + `run_corpus` once; determinism (the STANDING object is byte-identical for the same findings — no wall clock).**
- [ ] **Step 6 — Commit.**

> **GO/NO-GO:** the chain verifies, tampering is rejected, and the attestation (or its fallback) roundtrips. This phase pays regardless of the ratchet.

### Phase 4 — CLI seat & the closed loop  *(2–3 days)*

Expose the four verbs and close the loop back onto THERA.

**Files:** Modify (additive) the ergon/CLI verb table (the `iii hermeneus …` pattern) → add `iii auxesis ratchet | incorporate | stand | attest`.

- [ ] **Step 1** — Wire the four verbs to the hub exports.
- [ ] **Step 2** — Feed the RATCHET's admitted templates back into THERA's MEMBRANE candidate-invariant set (the widening loop, closed).
- [ ] **Step 3** — Corpus gate over the CLI dispatch; `run_corpus` once; commit.

---

## §8 — Risks + falsifiers  *(pre-mortem; cheapest probe first)*

| # | Risk | Likelihood | Impact | Cheapest falsifier |
|---|---|---|---|---|
| 8.1 | **Anabolism starves catabolism** — building the flywheel burns cycles the faucet needs | Med | High | *Structural mitigation:* Phase 0 is a 5-line tap; each aspect built only behind proven exhaust. If any phase exceeds its budget without the prior stream flowing, halt that phase. |
| 8.2 | **Gaps don't cluster** — real refusals are ~all UNCLOSABLE (economic/oracle), so the ratchet has nothing to catch | **Med (the load-bearing unknown)** | High (kills Pillar 1 only) | The Phase 2 kill-switch: measure COMPOSABLE+BUILDABLE share on the first live-discovery ledger; < ~15% → drop the ratchet, keep Pillars 2+3. |
| 8.3 | **Unsound new decider** — a synthesized template gives a false witness → a false submission → reputation death | Low | **Fatal** | Phase 2's soundness gate + adversarial verification: no template is admitted until it re-derives a known bug AND rejects a known-clean artifact under attack. |
| 8.4 | **`cap_zkp` can't express the attestation statement** ("N chained findings over public commitments") | Med | Low | Phase 3 Step 4 probe. Fallback: plain SLH-DSA selective disclosure — loses set-anonymity, keeps per-finding replayability. Still valuable. |
| 8.5 | **Buyer distrusts self-certification** — "certified by your own III" is worthless to a program | Med | Med | *Design mitigation:* the ledger attests **replayability against the public on-chain commitment**, not III's grade. The public artifact + the replay is the trust anchor; the grade is not claimed. |
| 8.6 | **Additive edit corrupts a frozen format** — touching `testament.iii` v1 or `soma.iii` breaks a gate | Low | High | STANDING is a *sibling* object (never edits testament's frozen 7 sections); soma edits are additive constants only. The full `run_corpus` after each phase reddens on any regression. |

**The single assumption that, if wrong, breaks the plan:** that real THERA refusals fall into the COMPOSABLE/BUILDABLE seats at a useful rate (8.2). It is measured on the first live ledger, and the kill-switch cleanly degrades the plan to its still-valuable Pillars 2+3 rather than failing whole.

---

## §9 — Files to create / modify  *(exact paths; additive discipline)*

**Create:**
- `STDLIB/iii/omnia/auxesis.iii` — the anabolic hub (ingest, triage).
- `STDLIB/iii/omnia/auxesis_incorporate.iii` — Pillar 2 (fold findings into SOMA; turn the prover inward).
- `STDLIB/iii/omnia/auxesis_ratchet.iii` — Pillar 1 (triage → template synthesis → soundness gate).
- `STDLIB/iii/omnia/auxesis_standing.iii` — Pillar 3 (the sibling STANDING object; ZK attestation).
- `STDLIB/corpus/NNNN_auxesis_gap_address.iii`, `…_finding_replay.iii`, `…_template_soundness.iii`, `…_standing_chain.iii` — the four gates.
- `DOCS/III-AUXESIS-ANABOLIC-FLYWHEEL.md` — **this document.**

**Modify (purely additive):**
- `STDLIB/iii/katabasis/soma.iii` — `SM_K_GAP`, `SM_K_FINDING` + two ingest handlers (uses the file's own reserved growth slot).
- The ergon/CLI verb table — `iii auxesis …` (matches the `hermeneus` pattern).

**Never touched:** `testament.iii`'s frozen v1 format (crypto primitives reused, object unaltered).

---

## §10 — Calibrated bottom line

I won't sell "boundless uncontested leverage" — that fails the wall-test the user holds. What is **true and grounded**:

- **AUXESIS is the genuinely complementary organ**, not a second hunter. It is the *anabolic* half of a metabolism whose *catabolic* half (THERA/METABOLE) already exists — a first-principles complement, forced, not decorative.
- **The mutual benefit is real and bidirectional and structural:** THERA is AUXESIS's only food (so it can't outrun the money), and AUXESIS's three products flow back as a wider net, harder witnesses, and higher-value invited targets. It converts THERA's *line* into a *flywheel*.
- **III levels up as a side effect, provably:** new gate-checked deciders (RATCHET), III's own organs adversarially hardened by real exploit traces (INCORPORATION), and a new native anonymous-provenance faculty generalized from `testament` (STANDING). The metabolism is architecturally completed.
- **It is thin because the organs already exist** (§4): one hub, two additive claim kinds, one sibling object, the triage. No new primitive on the critical path.
- **It is honestly bounded:** "boundless" = grows wherever growth is possible (COMPOSABLE/BUILDABLE), named wall where it isn't (UNCLOSABLE). The whole plan's payoff rate rests on one measured unknown, with a clean kill-switch that degrades to still-valuable Pillars 2+3.

**Confidence:** HIGH on architecture, complementarity, and grounding; **MEDIUM** on the economic payoff rate (gap-clustering — §8.2). The cheapest thing that would most change the picture is already the **first move**: attach the Phase 0 tap to THERA's Phase 0 falsifier. One afternoon proves the mechanism *and* shows the first real refusals — the seed of everything downstream — before a single dollar of effort is spent on the flywheel proper.

---

## §11 — Self-review  *(writing-plans requirement)*

**Spec coverage** (against the user's ask — "complementary, harmonious, mutually beneficial, widens both, upgrades III"):
- *Complementary/harmonious* → §0–§2 (anabolism completes catabolism; the loop wraps the line; METABOLE pairing). ✓
- *Mutually beneficial* → §3 forward+reverse ledger (structural downstream dependency). ✓
- *Widens both* → §5 triage (widens III's provable surface) + §3 (widens THERA's net). ✓
- *Upgrades III in its own right* → §3 "III-in-its-own-right" + §10. ✓
- *Assumes THERA carried out as written* → the header + §7 Phase 0 piggyback. ✓

**Placeholder scan:** No "TBD/handle-appropriately." The `.iii` bodies are intentionally deferred to corpus-TDD at execution with the reason stated (§6 preface) — the interfaces, formats, compositions, and gates are concrete. `NNNN` corpus numbers are assigned at execution against the live registry (the codebase's real convention). ✓

**Type/name consistency:** `SM_K_GAP=5`/`SM_K_FINDING=6` used consistently (§6.1, §7 P0). `ax_ingest_refusal`/`ax_ingest_finding` (§6.2) consumed in P0/P1. `ax_triage` (§6.2) consumed in P2. `ax_synthesize_template`/`ax_template_gate_path` (§6.3) consumed in P2. STANDING format (§6.4) consumed in P3. `ax_stand_append/verify/attest` consistent P3↔§6.5. THERA's exhaust names (refusals/findings/payouts) consistent throughout. ✓

**Gap found & fixed on review:** the widening loop was only implied; §7 Phase 4 Step 2 now explicitly feeds admitted templates back into THERA's MEMBRANE so the loop is *closed in code*, not just in prose. ✓

---

## §12 — Execution handoff

Per the project's standing rule (**no subagents on the III self-hosting core**), this plan executes **inline, single-context, task by task**, against the live tree, with `run_corpus` + witness-replay as the gate between phases. The natural entry point is **Phase 0** — and because Phase 0 is a 5-line tap on THERA's own Phase 0 falsifier, **the first executable step of AUXESIS is also the first executable step of THERA.** The two plans share one afternoon; that shared afternoon is the whole flywheel's ignition.

---

## §13 — Execution addendum (2026-07-19): THERA's ZK-lane DECIDER is REAL

Executing this plan surfaced that **THERA's DECIDER for its sharpest lane already exists, built and green, in-tree** — the plan's central empirical unknown is resolved for the ZK lane, in the plan's favor.

**The organ: `ELENCHOS` (`STDLIB/iii/omnia/elenchos.iii`).** It decides ZK-circuit **under-constraint** — the #1 ZK vulnerability, where the constraint system fails to uniquely determine the witness so a malicious prover forges an accepted proof. It is exactly **the fold**: a constraint system `A` is under-constrained ⟺ `rank(A) < #witness vars` ⟺ `ker(A) ≠ 0` ⟺ a nullspace vector `w0` with `A·w0 = 0`, so `(w + t·w0)` is also accepted for all `t`. ELENCHOS produces that `w0` — the Socratic refutation — by **exact modular Gaussian elimination over the ACTUAL BN254 scalar field** `r = 0x30644E72…F0000001` (the field circom/snarkjs use), via III's bigint (`bigint_mod` + `bigint_modpow` Fermat inverse). The forgery is **verified non-circularly** against the untouched original matrix (`A·w0 = 0`), and the gate is **mutation-tested** (dropping the binding constraint flips a sound circuit back to forgeable — the teeth are real, not vacuous).

**Verified this session, in the binary — not the comment:** compile (`iiis-2 --compile-only`) + link (`libiii_native.a` + `-lws2_32 -lkernel32`) + run → `elenchos_selfprove = 0`, `EXIT=0`, detecting the under-constrained circuit (`rank 2 < 3`), forging `w0`, and confirming `ORIG·w0 = 0 mod r` over the real field. Incorporated as a **reproducible, byte-deterministic rite**: `STDLIB/scripts/elenchos_gate.sh` (mirrors `hermeneus_gate.sh`) → GREEN.

**What it means for this plan.** Phase 0's GO/NO-GO — *"does III's exact core actually fire on a real bug, with a replayable witness?"* — is **effectively PASSED for the ZK-under-constraint lane.** The kill-switch did **not** fire. THERA's money-lane DECIDER is a running binary, exact (soundness = certainty, no ε — superior to probabilistic Picus/ecne), over the real production field. ELENCHOS **is** THERA's DECIDER for this lane; each refutation is precisely a **FINDING** that AUXESIS's **INCORPORATION** aspect (§1) folds into SOMA, and the witnessed forgery is the submittable PoC (responsible disclosure — never executed on-chain).

**Productionization in flight (a parallel session owns the organ; this session verified + gated + recorded — no clobber, no fork).** Two axes toward real targets: **(A) ingestion** — `el_ingest_json` eats a snarkjs `r1cs.json` constraint spec through III's own RFC-8259 parser (`verba/json`) end-to-end (field elements as decimal strings — **done, green**); **(B) quadratic R1CS** — real circuits are `(A·w)∘(B·w) = (C·w)`; the named next step is to parse the `[A,B,C]` maps and **Jacobian-linearize** (`J[i][c] = (B_i·w*)·A_i[c] + (A_i·w*)·B_i[c] − C_i[c]`, augmented with public-column unit pins, then the same exact nullspace engine), for which `cad`/`bv_ring` already exist. **Honest scope:** linear under-constraint is exact today; quadratic is designed, not yet landed; scale (thousands of constraints) needs flat-limb modular linear algebra beyond the 64-slot bigint handle table. The live-target hunt (Aztec-class BN254/PLONK; a comparable circuit bug paid ~$450k) is Lane C — pseudonymous, KYC at payout.

**Bottom line:** the flywheel's catabolic engine is no longer hypothetical for its sharpest lane. THERA's ZK DECIDER exists, is exact, is verified green, and is being pointed at real circuits — which is exactly the condition under which building AUXESIS's compounding loop around it (the RATCHET/INCORPORATION/STANDING of §1) becomes non-island work fed by a real producer.
