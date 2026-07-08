# III — THE UNIFICATION LEVERAGE MAP: locating the biggest unification effort

> **STATUS: ANALYSIS (LOCATED, not executed).** A systems-map pass (2026-07-07/08) answering one question:
> *which unification effort would realize III's full capabilities — and go beyond them.*
> Every number marked **[measured]** was produced by a command run against the live tree during this pass;
> claims from docs/ledgers are marked **[recorded]**. This doc locates and programs; it executes nothing.
> Companions: `III-COMPLETION-PLAN.md` (Φ1–Φ7, the plan of record this doc builds on),
> `III-UNIFIED-ARCHITECTURE.md` (rev.3, whose §8 realization program ends at "weld run_completion.sh"),
> `III-SOVEREIGN-STACK-ARCHITECTURE.md` (the SVIR spine), `III-SYSTEMS-MAP.md` (genuine-output census).

---

## 0. The verdict in one paragraph

III today is **two systems bound at a single point**. System one — the *trust waist*: an 82-line SVIR
verifier **[measured]**, a committed ~2^-86 zkVM, byte-level DDC, XII proof-carrying canonicalisation,
sealed-channel transport, BFT federation, a provenance certificate — all real, all adversary-gated. System
two — the *capability body*: 811 faculty modules **[measured]** and 1,831 corpus KATs **[measured]** of
exact arithmetic, geometry, physics, crypto, logic — compiled by cg_r3 straight to x86, **never touching
the waist**. The Grand Unification gate binds them at exactly one computation (the R0 ripple fold
675673294) **[recorded]**. The biggest unification effort, and the one that goes *beyond* current
capabilities, is **THE WAIST LIFT (Λ)**: after Φ1 closes the trust floor, route the capability body itself
through the verified waist — so that verification, independent-frontend DDC, attestation, portability, and
federation stop being properties of one demo and become **ambient properties of every III computation**,
terminating in the fixpoint where the compiler itself runs as verified SVIR. The measured tree says this is
not a dream: the body is ~95% pure integer compute **[measured]**, the anchor already carries every opcode
class the body needs **[measured]**, and ccsv just proved the method scales by taking a real 865-function C
compiler to structural zero **[recorded]**.

---

## 1. The map (boundary, components, couplings)

**Boundary.** Inside: the repo (COMPILER, STDLIB, DOCS, COMPILED) + sibling tools. Outside: the OS loader,
CPU/microcode (the named irreducible TCB), node (wasm witness), and the frozen gcc reference used only as a
*witness*, never a producer.

**Components and their one responsibility:**

| Region | Members | Responsibility | Trust status |
|---|---|---|---|
| Trust floor (I1) | 13 members: svir_verify (82 ln **[measured]**), svir_prog/x86/wasm/interp/dis, ccsv, iiisv, iiisv2, sovas, sovparse, sovcoff, sovld | verify + translate + assemble + link SVIR; imports nothing above msvcrt | CLOSED, gate-enforced (`floor_closure_gate.sh`) **[recorded, gate exists — measured]** |
| Compiler (R3) | COMPILER/BOOT lex/parse/sema/cg_r3 (.iii, self-hosted) | .iii → x86-64 native, sovereign emit | fixpoint iiis-2≡iiis-3, corpus-determinism **[recorded]** |
| Capability body (R5) | 811 faculty modules **[measured]** (numera/omnia/eidos/aether/…) | the organs: exact arith, geometry, physics, crypto, e-graph, XII, zk gadgets | corpus KATs + ratchets; **not waist-routed** |
| Corpus (R6) | 1,831 KATs **[measured]** | behavioral proof of the body | native route only |
| The GU pipeline | run_grand_unification.sh: Ω.a–Ω.g + Ω7 | canonicalise+prove+attest+ship+federate+cert **one computation** | green **[recorded]** |
| The capstone | run_completion.sh, 8 arcs | the completion invariant | 7/8 arcs exist; `run_seed_sovereign.sh` ABSENT = the honest RED **[measured]** |

**The load-bearing edge (where behavior lives):** the single coupling between body and waist is the R0
ripple's shared fold — *one* computation with two proven views. Everything the waist can do (verify,
attest, DDC, ship, federate, certify) reaches the body **through that one edge**. Widen that edge and the
whole system changes character; leave it and the waist stays a certified island of trust beside an
uncertified continent of capability.

**Feedback loops:**
- **B1 (balancing, healthy):** ratchets — coverage/dark/under-proven pins, corpus determinism, carto gate.
  They defend the *current* equilibrium: a capable body, self-consistent, reproducible.
- **R1 (reinforcing, the engine):** the closure loop — faculty→cg_r3→seal→gate→faculty. Each capability
  hardens the toolchain that builds the next. This loop made the body big.
- **R2 (reinforcing, currently starved):** the *trust* loop — waist-verified artifacts feeding back as
  trusted building blocks. Today R2 cycles only through the floor + one demo. **The Λ intervention feeds
  R2 the body**, which is what "greater than the sum" scales on.

---

## 2. Live measurements grounding the feasibility claim (2026-07-07/08)

| Fact | Value | How measured |
|---|---|---|
| Trust anchor size | **82 lines** | `wc -l STDLIB/sovir/svir_verify.iii` |
| Anchor ISA already carries | CALL_INDIRECT **0x73**, typed memory **0x84–0x89**, imports **0x8A** | grep on svir_verify.iii |
| Body modules | **811** .iii under STDLIB/iii | find \| wc |
| Corpus KATs | **1,831** | find STDLIB/corpus -maxdepth 1 |
| Body modules with `metal` blocks | **10** — all numera crypto kernels (aes_gcm, bigint, blake2s, chacha20, drbg, keccak, poly1305, sha256, sha256_ni, sha512) | grep -l |
| Body modules touching OS symbols | **32** (aether: window/net/fs/stoma/ipc…) | grep -l kernel32\|user32\|ws2_32\|… |
| ⇒ pure-integer-compute body | **~769/811 ≈ 95%** | arithmetic on the above |
| `extern fn` in body | **0** | grep |
| Φ1 frontier | ccsv structural floor **0/865, all six seed modules** (07-05); behavioral layer opened and first divergences closed (07-07) | memory ledger **[recorded]**; remaining: behavioral parity → 0x8A cross-module link (sovld by name) → `stage1_corpus` byte-match → author `run_seed_sovereign.sh` |
| Capstone state | run_completion.sh exists, **8 arcs, 1 ABSENT** (seed_sovereign); never yet run green | script read; no `_completion_*.log` exists |

The decisive earlier fact **[recorded]**: SVIR was scoped on 2026-06-23 as "useless for general computing —
the deliberate trade." Since then the waist gained typed memory, indirect calls, imports, a 4MiB linear
memory, a size-tracked heap, varargs, and a full C-subset frontend that compiles the *largest real program
in the tree* (the 865-function iiis-0 seed) to structural zero. The "narrow domain" boundary has already
been crossed empirically — by the trust floor's own Φ1 campaign. The body (integer-only, no floats, no
objects, arena memory) violates **none** of SVIR's deliberate exclusions.

---

## 3. Candidate unification efforts, Meadows-ranked

Weakest → strongest leverage:

1. **Tune parameters** (more KATs, NQ knobs, ratchet pins — Φ4/Φ6 hygiene). *The low-leverage move a
   reviewer would reach for.* Valuable, already programmed, changes nothing structural.
2. **Capability-consumer unification** (one Studio/field surface; genuine-output breadth). Consumer-side;
   the reunification (W0–W8) + run_evergreen already police this equilibrium.
3. **{BELOW,REFLECT} → one primitive.** Real surplus, small scope (the architecture doc's step 6).
4. **Information flow: weld the capstone** — run_completion.sh 8/8. This is the *completion invariant*
   going green: the strongest move **inside** the current goal. Blocked on exactly one arc: **Φ1**.
5. **Φ5 XII→SVIR one-object binding** (INTENT≡EXECUTION as one artifact). Strong, currently elective —
   and *subsumed by 6*.
6. **⟨THE PICK⟩ paradigm change — THE WAIST LIFT (Λ):** the body routes through the waist. This changes
   what the system *is*: from "a verified floor beside a capable body, bound at one point" to **one
   verified computer** whose every capability is a verifiable, attestable, portable, federatable
   computation. Highest Meadows rung available; everything above rung 4 feeds it; Φ1 (rung 4's blocker)
   is its prerequisite *and* its proven method.

**Why Λ is "the biggest … and beyond":** the completion plan realizes *full capabilities as currently
defined* (its Part 3 literally defines "complete"). Λ is what the completed system is *for* — it converts
the GU from an existence proof ("this CAN be done to one computation") into the system's ambient mode
("this IS what every computation gets"). No other candidate spans trust + language + toolchain + transport
+ federation at once.

---

## 4. The Λ program (each rung: exit gate + falsifier, house discipline)

**Λ0 — Close Φ1 (prerequisite, in flight; the plan of record already owns it).**
Behavioral parity per seed module (interp-mhash == gcc) → cross-module link over 0x8A imports (sovld,
by-name) → sovereign iiis-0 **byte-matches** gcc-built iiis-0 on `stage1_corpus` → author
`run_seed_sovereign.sh` → **run_completion.sh 8/8 green = FULL CAPABILITIES, defined sense.**
*Falsifier:* one flipped emitted opcode reddens svir_verify; one perturbed seed byte reddens the byte-DDC.

**Λ1 — First real organs onto the waist.** Pick 3 theorem-bearing pure-compute faculties (e.g. bigint
isqrt, e-graph mul-plan, Sturm root isolation) and lower them to SVIR. Route A (coverage-first): an SVIR
*backend* beside cg_r3's x86 emitter — reuses the self-hosted front/sema that already parses the whole
language. Route B (diversity, later): grow iiisv (402 ln **[measured]**) toward full .iii as the
independent second frontend. The ccsv campaign is the measured precedent (a *foreign* language, 865 fns,
183→0): .iii is the home language — no preprocessor, no varargs, no struct-by-value walls.
*Exit gate:* `run_body_svir.sh` — for each organ: svir_verify=0 AND interp/x86/wasm output ≡ cg_r3-native
output. *Falsifier:* flipped opcode → verify red; any output divergence → differential red.

**Λ2 — ISA closure audit.** Enumerate every construct the body actually uses vs the anchor's ISA. The
anchor already holds every needed *class* (typed mem, indirect calls, imports **[measured]**); the audit
either finds **zero or few** gaps (each a deliberate, one-sitting-auditable addition) or triggers the
architecture doc's anticipated fork to a TIERED anchor. ADR-1's 82-line audit budget is the binding
constraint — the body lowers *into* the waist; the waist does not grow to meet the body.
*Falsifier:* an anchor diff that can't be read in one sitting = the rung failed; stop and tier.

**Λ3 — The corpus becomes a differential oracle.** Every waist-routed module's corpus KATs run on BOTH
routes (cg_r3-native and SVIR→x86/wasm) and must agree. This is an up-only ratchet (N modules on both
routes; N never decreases). 1,831 KATs **[measured]** become a permanent two-route compiler oracle — every
future corpus addition automatically tests both compilers.
*Falsifier:* any behavioral divergence reddens the axis; deleting a routed module from the axis reddens
the ratchet.

**Λ4 — The GU carries a REAL capability.** Replace/augment the R0 demo leg: one real organ result (a
geometry theorem, an SLH-DSA signature, a fourbar synthesis) → XII-canonicalise where a term exists (Φ5
lands here naturally, as *one object through both stages*) → zk-attest its fold/invariant → ship over
sealed_channel → federate → provenance-cert. **Honest zk scope:** attest folds, summaries, and bounded
kernels (chunked/recursive for long runs) — not every cycle of arbitrary computations; the verification/
DDC/portability legs (Λ1–Λ3) are total, the attestation leg is selective by design.
*Falsifier:* tampered result/proof/cert each reddens its arm (the GU's existing adversary pattern).

**Λ5 — The fixpoint (endgame flag).** cg_r3.iii itself routes through the waist: the compiler runs as
verified SVIR, and the 82-line anchor verifies the compiler that compiles the anchor's own toolchain.
run_completion gains a final arc asserting the waist-fixpoint. Trusting-trust answered constructively at
*every* layer, not only at the seed.
*Falsifier:* the SVIR-routed compiler diverging from the native fixpoint on `stage1_corpus` reddens.

---

## 5. What "beyond" cashes out to (capabilities III does not have today)

1. **Proof-carrying exact computation as an ambient property** — any organ's result ships with a committed
   ~2^-86 proof + provenance cert; receivers verify without re-executing (Ω.f generalized from demo to
   product).
2. **A 1,831-test differential compiler oracle** — permanent, automatic, two independent code-generation
   routes agreeing on the whole corpus (compiler correctness amplification for free, forever).
3. **Host-independence of the body** — every pure organ runs on wasm (and any future SVIR translator
   target) — the capabilities stop being win64-bound.
4. **INTENT≡EXECUTION on real work** — Φ5's one-object binding, upgraded from elective demo to the normal
   shape of a computation that carries an XII term.
5. **The attested-compiler fixpoint** — the strongest self-hosting claim available: the verified ISA runs
   the compiler that emits the verified ISA.
6. **A verifiable compute fabric** — Ω.g federation certifying *real* results makes multi-node III a
   Byzantine-tolerant fabric for exact mathematics, not a transport demo.

---

## 6. Named limits and risks (the cost, or it is not a decision)

- **metal kernels (10 modules [measured]):** fast paths stay native; pure-.iii sibling paths route through
  the waist with equivalence KATs binding the pair. The named limit: the *fast* path's trust remains
  corpus-level.
- **OS boundary (32 aether modules [measured]):** shims stay native; compute cores route. UI/net I/O is
  attested at the boundary (content-addressed in/out), not inside.
- **zk trace length:** long computations attest folds/invariants or chunked recursion — stated in Λ4;
  never claim "every computation zk-attested end-to-end."
- **Performance:** the SVIR route is the *verification* route; cg_r3-native remains the *fast* route;
  Λ3's differential binds them. No capability is slowed; a trust dimension is added.
- **ADR-1 audit budget:** the real structural risk. Mitigation is Λ2's audit-first discipline + the
  architecture doc's pre-planned TIERED-anchor fork.
- **Index-space agreement (the fn-ptr obligation) and OOB-trap teeth:** already pinned as obligations in
  the Φ1 campaign; they carry over verbatim to body lowering.
- **Failure cascade to break:** floor drift (a seed divergence) cascades everywhere — Φ1's byte-DDC is the
  breaker; a body-route divergence is contained by Λ3's differential gate (it reddens one axis, not the
  tree).

---

## 7. Confidence + what would confirm or refute this model

**Calibrated confidence:** HIGH that the split (§1) and the measurements (§2) are the true structure — they
were measured, not recalled. MEDIUM-HIGH that Λ1's first rung lands at ccsv-like cost — the language is
friendlier, the front-end exists, but cg_r3's emitter internals may resist a second backend more than
estimated. MEDIUM on Λ5 timescale (endgame flag, not a schedule).

**Watch to confirm:** (a) Φ1's `stage1_corpus` byte-match — if the behavioral campaign stalls on
reentrancy/heap semantics, Λ1's estimate inflates; (b) Λ2's audit result — zero-or-few opcode gaps confirms
"the body was built lowerable," many gaps refutes it; (c) the first Λ3 differential run — early divergences
concentrated in cg_r3 optimizations (e-graph strength reduction) would be *good news* (the oracle working),
divergences in SVIR translators would mean the waist needs hardening first.

**The one-sentence answer:** *finish Φ1, weld the capstone — then lift the body onto the waist (Λ): that is
the biggest unification in the tree, the one that turns III from a verified floor beside a capable body
into one verified computer, and every rung of it is gate-checkable with the falsifier discipline the tree
already speaks.*
