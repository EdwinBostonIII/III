# III-APOTHEOSIS.md — the idealized III, built module by module

**What this is.** Not an architecture overview (that is `III-SOVEREIGN-CHARTER.md`).
This is the *whole improved system of our dreams*, derived one module at a time.
For every module: what it does today (read from source), a first-principles
enhancement, then a compounding pass — how the *enhanced* module pushes further
**and** lifts every module already written without bad redundancy — then the
committed idealized form. Each append builds on all priors. No compromise, no
tradeoff, no pragmatism over the best possible thing. III's total NIH mandate is
unlimited creative licence; precedent is not a constraint.

**The thesis the whole file serves (held, now stated).** The idealized III is:

> **One language** (III itself; the C reference tree is shed once its `.iii`
> ports are proven superior) · **one currency** (the Sovereign Value crosses
> every boundary) · **one conscience** (the Constitution gates every guarantee
> with verify ∧ falsify) · **one engine** (XII evaluates every morphism;
> confluence makes composition deterministic) · **one category** (every
> transform — compile, convert, prove, encrypt, federate — is a morphism over
> Sovereign Values) · **one body** (federation, immune/repair, time, memory bound
> as organs of the same organism). Deeper, not wider.

**Discipline (binding on every module here).** NIH (libc + III BOOT only); full
determinism (no float, equality-only trit/i64 compares, module-scope scratch,
W-laws); no statistical learning; monomorphic (kind-tag + `when`, never
fn-pointer dispatch); every guarantee carries a falsifier; nothing ships unless
`SEAL.mhash` + `libiii_native.a.mhash` + the verdict vector reproduce. An
enhancement that bends one of these has *failed*, by definition.

---

## Module ledger (deepest-first; ✎ = drafted here, ▢ = pending)

**Foundation — the value stack:** ✎1 Content-Address · ✎2 Ternary Algebra ·
✎3 Hexad · ✎4 Unified Uncertainty · ✎5 The Sovereign Value · ✎6 Witness & Commons
**Engine:** ✎7 XII · ✎8 SID/Reversibility · ✎9 Proof Kernel
**Conscience:** ✎10 The Constitution
**Cognition:** ✎11 Decision procedures (SAT/SMT/Gröbner/e-graph) · ✎12 Category ·
✎13 Cost · ✎14 Memo · ✎15 Synthesis · ✎16 Proof-carrying
**Representation:** ✎17 Transform pipeline (`tp_*`) + Babel · ✎18 The compiler
**Body:** ✎19 Federation · ✎20 Immune/Regen · ✎21 Time · ✎22 Memory ·
✎23 Katabasis/CHARIOT
**Pruning:** ✎24 The bloat-removal ledger (C reference tree, dead modules)

*Pass 1 (the 24 architectural organs) is complete, with the "what III becomes able
to do" capstone. Pass 2 — the long tail of individual leaf modules, each inheriting
the spine and treated by the same compounding method — continues:*
**Text/Verba:** ✎25 · **Crypto suite & agility:** ✎26 · **Collections:** ✎27 ·
**Observability:** ✎28 · **Sandbox:** ✎29 · **Resolver/dispatch:** ✎30 · **Net/IO:** ✎31

*Passes 1 & 2 complete — the whole idealized III is documented (24 organs + 7 leaf
clusters), one body, no module left as a parallel system. Pass 3 (continuing): per-file
depth within the highest-leverage clusters (the individual `tp_*` morphisms, each
crypto primitive, the `xii_curated_*` kernels) and a whole-document internal-consistency
audit (no module's final form may contradict another's) — then implementation begins
at Module 1 (the `cad` collapse) since each module's final form is implementation-ready.*

---

> **⚠ READING ORDER (canonical) — physical order is append-order, not reading-order.**
> This file was built by sequential append; several appends anchored on near-duplicate
> *ledger* text and so landed here (after the ledger) instead of at the document end,
> scrambling the physical section order. **All content is final, complete, and
> source-grounded — only the ordering is off.** Read in this canonical order:
> 1. **Module bodies** — M1–M24 (the 24 organs; physically near the *bottom*) then
>    M25–M31 (the 7 leaf clusters; physically *just below this note*).
> 2. **Capstone** — "What III becomes able to do" (after M24, near the bottom).
> 3. **The Harmony Invariants** — H1–H13, the enmeshment contract.
> 4. **The consistency audit** — M1–M31 against H1–H13 + the 7-migration critical path.
> 5. **Per-file depth** — M7·D1 (Horizon/curated), M17·D1 (`tp_*` morphism category).
>
> The single outstanding edit is a mechanical one-pass **reflow** into the order above
> (no content changes) — deferred deliberately rather than risk a blind 600-line move
> on irreplaceable content while the session is deep. The reflow is the next action.

---

## Module 25 — Verba / the text & meaning layer (`verba/glyph_core.iii`, `nl_lex.iii`, `string·rune·parse·format·regex·base64·base32·leb128·uri·path·ini·csv·html_escape·normalise_ascii·ast_intent·transform_form·timing_safe·uuid·ulid·pattern`)

**Today.** `glyph_core` is the **192-byte self-verifying Glyph V3**: `[form_id |
payload_len | payload(152) | sha256(...)]` — the mhash field makes **every glyph
verifiable in isolation** (a forged glyph fails `gv3_validate` with no external
lookup), and its form-ids already include `crystal`, `witness`, `proof`. `nl_lex` is
a **deterministic** NL lexer (sealed lexicon → typed tokens, **no statistics, no
fallbacks**). The rest are text codecs (`string`/`base64`/`regex`/...), intent
parsing (`ast_intent`/`transform_form`), constant-time compare (`timing_safe`), and
ids (`uuid`/`ulid` over xoshiro).

**Pass 1 — first principles.** The Glyph **is the serialized Sovereign Value (M5)** —
a 192-byte, self-verifying (M1 embedded) encoding that can carry `crystal`/`witness`/
`proof` forms. Recognize it as such: the wire/storage form of a SovVal. The text
codecs are **lossless morphisms (M12/M17)** between byte representations; `nl_lex`
makes human intent a *deterministic* input.

**Pass 2 — compound.** This gives the Sovereign Value its **storage & wire body**: a
SovVal serializes to a self-verifying Glyph, so values **persist (M22), transmit and
federate (M19), and chain (M6) by their embedded content-address (M1) — re-checking
in isolation, needing no external trust.** And `nl_lex`+`ast_intent` make **human
intent a proof-carrying SovVal**: deterministic parsing feeds synthesis (M15), which
returns a kernel-verified (M9) program — III takes a human request and hands back a
*proven* artifact, no ML anywhere. `timing_safe` is the `@constant_time` discipline on
secret-touching morphisms (M26); the codecs are lossless transforms in the
representation category (M17); `uuid`/`ulid` use the non-crypto PRNG, scoped away from
anything cryptographic. Push: because the Glyph self-verifies, III's *entire* storage
and wire layer is trustless — every byte that leaves or persists re-checks alone. No
bad redundancy: the Glyph is the serialized SovVal (not a second value type); the
codecs are morphisms (M17); `nl_lex` is the deterministic intent front-end into
synthesis (M15).

**Final — Verba.** `glyph_core` = the 192-byte self-verifying serialization of the
Sovereign Value (M5/M1) — the storage/wire/federation body (M22/M19/M6); `nl_lex`+
`ast_intent` turn human intent into a deterministic, proof-carrying SovVal feeding
synthesis (M15→M9); text codecs are lossless morphisms (M17/M12); `timing_safe` the
constant-time discipline (M26); ids via the scoped non-crypto PRNG. *Falsifier:* a
Glyph that validates against a wrong embedded hash; a non-deterministic intent parse;
a "lossless" codec whose round-trip ≠ identity; a `timing_safe` compare that branches
on secret data → red.

## Module 26 — Crypto suite & agility (`numera/` crypto: SHA/Keccak/SHAKE/BLAKE2s, HMAC/HKDF/PBKDF2/DRBG, AES{,GCM,SIV}, ChaCha20/Poly1305/XChaCha20, Ed25519/X25519/ECDSA/RSA, ML-KEM/ML-DSA/SLH-DSA, BLS12-381/Groth16/STARK; `III-CRYPTO-AGILITY`)

**Today.** A complete NIH crypto suite, all hand-rolled, KAT-proven. Crypto-agility
(the mandate doc) puts every primitive behind a `suite_id`-tagged uniform interface,
Q-Day-swappable. **But** several primitives are *orphaned* (BLAKE2s, PBKDF2, AES-SIV,
XChaCha20, ECDSA, RSA have no live `.iii` consumer — established earlier); the suite
registry is partly spec; and SHA-256 was hand-rolled 14× (M1/M24).

**Pass 1 — first principles.** Crypto operations are **morphisms (M12) that make
Sovereign Values confidential and authentic**, and a `suite_id` *is* the content-
address suite-tag (M1). Route all crypto through the `cad` (M1) suite registry — one
agile interface; the active suite is **constitutional (M10, Founder's-Anchor-cosigned
swap)**; every orphan is either given a real consumer or **pruned (M24)**.

**Pass 2 — compound.** Suite-tagging (M1) makes signed/sealed values **temporally
immune** — a Q-Day hash/signature swap leaves names and history verifiable (the M1
promise paid). Crucially, **the kernel never trusts crypto (M9): a signature, MAC, or
ZK proof is a re-checkable certificate (M16)** — verified, never trusted — which is
exactly what makes federation consensus-free (M19). The **ZK layer (BLS12-381/Groth16/
STARK) folds into proof-carrying (M16)** as succinct certificates; **PQ (ML-KEM/ML-DSA/
SLH-DSA) is the dormant temporal-immunity reserve** (charter NFR-1, ready not active).
Prune (M24) the orphans — BLAKE2s (SHA-256/Keccak do the work), PBKDF2 (no password
flow), AES-SIV/XChaCha20 (no consumer), ECDSA/RSA (interop-only, no live consumer) —
unless a real consumer or mandate is established. No bad redundancy: one agile crypto
interface over the one content-address (M1); ZK = proof-carrying (M16); orphans pruned.

**Final — Crypto suite & agility.** All crypto morphisms route through the `cad`
suite registry (M1), suite-tagged for Q-Day immunity; the active suite is
constitutional (M10/Anchor); every result is a re-checkable certificate (M16), never
trusted (M9/M19); ZK = succinct proof-carrying (M16); PQ = the dormant immunity
reserve; orphans pruned (M24) absent a real consumer. *Falsifier:* a crypto result
trusted without re-check; a suite swap not Anchor-cosigned; a retained primitive with
no consumer/mandate → red.

## Module 27 — Collections (`omnia/map·set·list·vec·queue·lru·fold·zip·crystal·dynamic_record·dynamic_impact·unify.iii`)

**Today.** Bounded (W8), monomorphic containers (`map`/`set`/`list`/`vec`/`queue`/
`lru`), combinators (`fold`/`zip`), `crystal` (**sealed, forge-resistant error
values**: provenance — site-hash, cap, causal predecessor, K-value — bound by a
16-byte MAC; `crystal_verify` fails for fabricated errors), `unify` (bounded Robinson
unification + occurs check), and dynamic typed records.

**Pass 1 — first principles.** An error is not a flag. `crystal` proves errors are
**sealed, provenance-bearing values** — so unify errors with the gap (M4): a failure
is a `Gap` whose root cause is a sealed `crystal`. Containers hold Sovereign Values
(M5), deterministically (Π5), bounded (W8). `unify` is the engine the kernel (M9) and
resolver (M30) share.

**Pass 2 — compound.** `crystal` collapses error-handling into the value model: a
failure is a gap (M4) carrying a sealed crystal (forge-resistant MAC, K-value, causal
chain = M6 provenance) — so **errors are as trustworthy as results; you cannot forge a
failure**, and a gap's provenance re-checks (M1/M6). `unify` is the *one* unification —
the kernel's type-checking (M9) and the resolver's matching (M30) are the same engine,
bounded. Containers hold SovVals deterministically (Π5), cost-bounded (M13/W8);
`fold`/`zip` are morphisms (M12). Push: because a crystal is sealed + content-addressed
(M1) + witnessed (M6), an error federates (M19) and re-checks like any value — a peer
can't be lied to about a failure. No bad redundancy: `crystal` = the sealed-error
reading of the gap/SovVal (M4/M5), not a separate error system; `unify` = the one
unification (M9/M30); containers hold SovVals.

**Final — Collections.** Bounded (W8), deterministic (Π5) containers of Sovereign
Values (M5); `crystal` = the sealed, forge-resistant, provenance-bearing error reading
of the gap (M4/M1/M6) — errors as trustworthy as results; `unify` = the one Robinson
engine shared by kernel (M9) and resolver (M30); `fold`/`zip` = morphisms (M12).
*Falsifier:* a forged crystal passing `crystal_verify`; a non-deterministic or
unbounded container op; a second unification engine → red.

## Module 28 — Observability (`omnia/obs_log·obs_metric·obs_trace·obs_observatory.iii`)

**Today.** `obs_observatory` is a **12-family threshold rollup** — named indicators
with current value + threshold; current > threshold "fires"; a collapsed-state u32
bitmask. The family-tag mapping is a **sealed const, not registered at runtime**.
Plus structured log/metric/trace.

**Pass 1 — first principles.** Observability is the system observing *itself*, and
the no-statistical-learning tenet means a threshold must **never adapt from observed
data** (an adaptive threshold is the forbidden threshold-trigger). So the OBSERVATORY
is a set of **constitutional predicate-clauses (M10)** over witnessed (M6) values with
**sealed, never-adapted thresholds**.

**Pass 2 — compound.** The OBSERVATORY *is* the Constitution (M10) running
continuously: each indicator family is a clause (a predicate over the witness chain
M6 / algebraic time M21); a family "firing" is a clause going red → which drives the
immune response (M20). So observability is not a parallel monitor — it is the
conscience evaluated over the witnessed stream, thresholds sealed (M1/M10). `obs_log`/
`obs_trace` are witness fragments (M6); `obs_metric` is a deterministic cost/K rollup
(M13). Push: the collapsed-state feeds temporal clauses (M21) — "family X *eventually*
clears" is an LTL guarantee, model-checked (M11). No bad redundancy: observability =
constitutional clauses (M10) over the witness stream (M6/M21), never an adaptive
learner. **Falsifier:** a threshold adapted at runtime from data; an observation not
witnessed; a firing that doesn't feed the verdict/immune loop.

## Module 29 — Sandbox (`omnia/sandbox_ctor·sandbox_exec·sandbox_quota.iii`)

**Today.** Construct a sandbox, execute within it, enforce quotas. (Distinct from
`quarantine` (M20), which sandboxes *state*; this sandboxes *execution*.)

**Pass 1 — first principles.** Sandboxed execution is a Sovereign-Value computation
(M5) under a **capability (M8) + cost-quota (M13)** grant, witnessed (M6), reversible
(M20). The quota *is* the cost budget; the boundary *is* the capability grant.

**Pass 2 — compound.** The sandbox is **not new machinery** — it is capability (M8) +
cost (M13) + reversibility (M20) applied to execution. `sandbox_quota` *is* the
cost-lattice budget (M13) enforced at runtime; `sandbox_exec` runs a SovVal
computation under it, witnessed (M6); on violation `quarantine` (M20) contains and
rolls back. Push: a sandboxed result is **proof-carrying (M16)** — it proves it stayed
within its cost/capability grant, so III can run untrusted code and hand back a proof
it never exceeded bounds. No bad redundancy: sandbox = cost (M13) + capability (M8) +
quarantine (M20) for execution. **Falsifier:** a sandboxed computation exceeding its
grant without containment; a result that can't prove bound-compliance → red.

## Module 30 — Resolver / dispatch (`omnia/resolver·resolver_memo·resolver_replay·resolution_init·resolution_meta_dispatch·codegen_dispatch·pattern_table·ai_resolve·call_context.iii`)

**Today.** Deterministic resolution: `resolver` (intent → binding + witness),
`ai_resolve` (NL prose + cap handle → witnessed binding or NOMATCH, **"no statistical
learning enters the parse→intent→resolve pipeline"**, capabilities sealed not
observed), memo/replay, and the dispatch tables (`resolution_meta_dispatch`,
`codegen_dispatch`).

**Pass 1 — first principles.** Resolution is intent→binding and must be
deterministic, capability-bounded (M8), witnessed (M6), and kernel-verified (M9).
`ai_resolve`: prose (M25 `nl_lex`) → unify (M27) against a *sealed* pattern set
(capability-bounded M8) → a witnessed binding (M6) — III's "AI" is **deterministic
symbolic resolution, the antithesis of ML**.

**Pass 2 — compound.** The resolver is the **generative front-door that orchestrates
the cognition layer**: intent (M25) → unify (M27) against patterns → synthesis (M15)
when there's no direct binding → kernel-verify (M9) → witnessed (M6), memoized (M14)
proof-carrying (M16) binding; `codegen_dispatch` routes to the compiler (M18). Because
it's deterministic + memoized + witnessed, the same intent always yields the same
proven binding — re-checkable and federatable (M19). Push: `ai_resolve` makes III a
**capability-bounded, proof-carrying intent resolver** — a human asks in prose and
receives a *proven, witnessed, bounded* binding, with no model weights anywhere. No
bad redundancy: the resolver reuses nl_lex (M25), unify (M27), synthesis (M15), kernel
(M9), witness (M6), memo (M14) — orchestration, not a new engine. **Falsifier:** any
statistical step in resolve; a binding not capability-bounded or unwitnessed; a
non-deterministic resolution → red.

## Module 31 — Net / IO, the membrane (`aether/net·tcp·inet·http·http_server·http_client·fs·handle·idoc.iii`)

**Today.** Sockets (`net`/`tcp`/`inet`), web (`http*`), filesystem (`fs`), OS handles
(`handle`), `idoc`. The external IO boundary.

**Pass 1 — first principles.** IO is the **nondeterministic external boundary**. Every
external input (packet, file, request) enters as a **quarantined (M20), sealed (M1),
capability-gated (M8), witnessed (M6) Sovereign Value** — never a determinism leak;
every output is a SovVal serialized to a self-verifying Glyph (M25) or Babel (M17).

**Pass 2 — compound.** Net/IO is the **membrane** converting external bytes ↔ Sovereign
Values. Nondeterministic inputs are ordered by federation/HotStuff (M19) when
consensus-relevant, always sealed + witnessed (M6) + capability-gated (M8); `http`/`tcp`
ride the sealed channel (M19); `fs` is **content-addressed (M1)** — files keyed by
content; `handle` is capability-bound OS resource (M8). Push: because every input is a
sealed, witnessed SovVal and every output a self-verifying Glyph (M25), **III's entire
interface to the world is trustless and auditable** — nothing crosses the membrane
untyped, unsealed, or unwitnessed. No bad redundancy: net/IO reuses quarantine (M20),
capability (M8), witness (M6), Glyph (M25), sealed channel (M19), content-address (M1)
— a membrane, not a new trust domain. **Falsifier:** an external input entering
un-quarantined/unwitnessed; a determinism path reading raw IO; an output that isn't a
self-verifying value → red.

---

*Pass 2 (the long-tail leaf clusters M25–M31) complete: text/meaning, crypto suite,
collections, observability, sandbox, resolver, net/IO — each shown to inherit the
spine and amplify it, with nothing left as a parallel system. The idealized III is now
documented end to end: 24 architectural organs + 7 leaf clusters, one body.*

---

# The Harmony Invariants — the enmeshment contract

"Perfectly harmonious and enmeshed" is not a feeling; it is a finite set of
system-wide invariants, each a **constitutional meta-clause (M10) with a falsifier**.
The 31 modules form *one body* iff all of these hold. They are the cross-cutting
conditions that every module's final form was written to satisfy — the proof that the
unification has no seams.

- **H1 · One value.** Every datum crossing any boundary is a Sovereign Value (M5) =
  `{payload (gap+provenance, M4) | hexad (M3) | witness (M6) | cost (M13)}`. A
  non-sovereign boundary is a type error (`@sovereign`, M5). *Falsifier:* a raw value
  at a boundary.
- **H2 · One name.** Every value, morphism, and clause is content-addressed by the one
  `cad` (M1); there is no second hash path. *Falsifier:* a hash that isn't `cad`.
- **H3 · One serialization.** Every SovVal serializes to a self-verifying 192-byte
  Glyph (M25); storage/wire/federation carry Glyphs that re-check in isolation.
  *Falsifier:* a persisted/transmitted value that needs external trust to verify.
- **H4 · One engine.** Every computation is evaluated by XII (M7); confluence makes
  order irrelevant; `egraph` (M11) is its cost-minimal strategy (M13). *Falsifier:* a
  second evaluator, or a term with two normal forms.
- **H5 · One logic.** Safety (hexad, M3) and uncertainty (gap, M4) are the one ternary
  Kleene algebra (M2); errors are sealed crystals (M27); all are readings of the
  SovVal. *Falsifier:* a safety/uncertainty/error value outside this algebra.
- **H6 · One kernel.** Every value is a CIC term (M9); bricking (M3) and over-budget
  (M13) are *type errors*; gaps (M4) are open terms. *Falsifier:* a bricking/over-K
  value that type-checks; a closed inhabitant of ⊥.
- **H7 · One conscience.** Every guarantee is a constitutional clause (M10) with a
  paired falsifier (verify ∧ falsify), instantaneous or temporal (M21); the charter
  seal is the build's terminal gate. *Falsifier:* a guarantee with no clause, or a
  clause with no falsifier.
- **H8 · One record.** Every operation emits a witness fragment (M6); the chain is
  append-only *and* provably forgettable (M20); `algebraic_time` (M21) is its clock.
  *Falsifier:* an operation with no witness; a redaction that breaks continuity.
- **H9 · One reversibility.** Every effect is reversible (SID inverse, M8),
  typed-irreversible (`Compromise` tier), or unrepresentable (bricking, M3); `mobius`
  is its safety projection. *Falsifier:* an irreversible effect with no `Compromise`
  tier.
- **H10 · Nothing trusted.** Every result — solve (M11), crypto (M26), federation
  (M19), memo (M14), regeneration (M20) — is a re-checkable certificate (M16); the
  producer is never trusted. *Falsifier:* a result consumed without re-checking its
  certificate.
- **H11 · One category.** Every transform — compile (M18), `tp_*` (M17), crypto (M26),
  federation (M19) — is a morphism (M12); composition is associative; coequalizer =
  egraph equality, pullback = consensus. *Falsifier:* a transform that isn't a lawful
  morphism.
- **H12 · One determinism.** No float; equality-only compares; deterministic
  allocation (M22) and scheduling; wall-clock (M21) and IO (M31) enter only as
  quarantined, sealed inputs; the build is bit-identical across iiis-0/1/2 (M18).
  *Falsifier:* any nondeterminism on a determinism path.
- **H13 · One language.** No C save the bootstrap trust root + `cic.c` (M24);
  everything else is corpus-green `.iii`. *Falsifier:* a retained C module whose `.iii`
  port passes its exact KAT.

These thirteen are the seam-test. Pass 3 audits the documented final forms against
them module by module (and deepens the high-leverage clusters to per-file granularity);
any contradiction found is a unification defect to fix before implementation. Continuing.

## Pass 3 — consistency audit, Foundation (M1–M6) against H1–H13

Auditing each foundation module's *final form* against the invariants. The point is to
surface **load-bearing migrations the final forms assume but that don't exist yet** —
honest implementation-ordering defects, not contradictions in the design.

- **M1 (cad)** — satisfies H2 (it *is* the one name), H10 (a digest re-checks), H12
  (deterministic). **Defect found (ordering):** H2 holds only *after* the 14× `sha256.c`
  collapse (M24) and after `wh_publish`/`category`/`memo` are repointed from raw
  Keccak/SHA to `cad`. → **Implementation step 1 is the `cad` collapse**, because H2 is
  a precondition of H3/H6/H8/H10. No design defect.
- **M2 (ternary)** — satisfies H5 (the one logic), H4 (ops as XII rules), H12
  (equality-only). **Defect (ordering):** "ops as confluent XII rules" requires the
  five trit ops to be *added to* `xii_rewrite`'s rule set and re-run through
  `xii_critpairs` (117 → 117+N pairs). Until then, H4 holds for the algebra but the
  ops are still hand-coded `when`. → second implementation step. No design defect.
- **M3 (hexad)** — satisfies H1/H5/H9. **Defect (load-bearing):** H6 says bricking is a
  *type error*, but `reach` is today a runtime bitmap. Making it a type error requires
  the SovVal to be a CIC inductive (M9) with the hexad as a refinement — so **H6 is only
  runtime until M9's inductive lands**. This is the single most important type-level
  step; flag it as gating H6.
- **M4 (uncertainty)** — satisfies H1 (payload facet), H5 (gap = ZERO reading), H10
  (provenance re-checks). No defect; `either`/`checked` delegation (M24) is additive.
- **M5 (SovVal)** — satisfies H1/H3/H6/H11 *by construction once it exists*. **Defect
  (biggest lift):** H1 ("every boundary value is a SovVal") is **aspirational until the
  `@sovereign` boundary checker (M5/§6) is built and every stdlib boundary is migrated**
  — today boundaries pass raw `u64`/pointers. This is the largest implementation effort
  and the truest measure of "systemwide." Stage it: checker first (a new negative test
  `III_NONSOVEREIGN_BOUNDARY`), then migrate boundaries cluster by cluster.
- **M6 (witness)** — satisfies H8 (the one record), H10 (re-verifiable). **Defect
  (ordering):** H2 requires frag-ids via `cad` (M1) — today `wh_publish` uses Keccak256
  directly; repoint after the M1 collapse. Provable forgetting (M20) is additive.

**Audit verdict (M1–6):** zero *design* contradictions against H1–H13; three
*load-bearing migrations* identified and ordered — (1) the `cad` collapse [M1/M24],
(2) the SovVal-as-CIC-inductive so bricking/over-K become type errors [M3/M5/M9/M13],
(3) the `@sovereign` boundary checker + boundary migration [M5/H1, the systemwide lift].
These three are the critical path; everything else is additive. Pass 3 continues with
the engine (M7–9), conscience (M10), cognition (M11–16), and the per-file depth passes.

## Pass 3 — consistency audit, Engine + Conscience (M7–M10) against H1–H13

- **M7 (XII)** — satisfies H4 (the one engine), H11 (rewrites are morphisms), H12
  (confluence = determinism), H8 (G-family witness folds). **Defect (the engine
  lift):** H4 "everything evaluated by XII" requires *lowering* the trit ops (M2), gap
  arithmetic (M4), `sv_op` (M5), the kernel's β/ι (M9), and `cg` (M18) to XII rules —
  today XII evaluates its own canonicalisation domain. Staged: add each rule family,
  re-run `xii_critpairs` (117 + N pairs must still converge) each time. Also the
  curated-kernel promotion needs the M7/M10 clause "curated machine code ≡ its rewrite
  normal form." No design defect.
- **M8 (SID)** — satisfies H9 (the one reversibility). **Defect (ordering):** requires
  (a) the `omnia/sid` → `crystal_deps` rename to clear the name collision, (b) wiring
  the SID-derived inverse *into* each witness fragment (M6) for lossless backward
  replay, (c) the `Compromise` tiers expressed at the type level (M3). No design defect.
- **M9 (kernel)** — satisfies H6 (the one kernel). **Two notes:** H6 systemwide depends
  on the SovVal-as-inductive critical-path item (M3/M5); and `cic.c` is C, so H13 ("one
  language") is satisfied **with the explicitly-accepted `cic.c` + `COMPILER/BOOT` trust-
  root carve-out (M24)** — the `numera/kernel.iii` port is the long-term H13-completion,
  honestly deferred, not faked. Also H4: the kernel must reduce via XII (the M7 routing).
- **M10 (Constitution)** — satisfies H7 (the one conscience). **Defect (the conscience
  lift):** H7 requires (a) a `falsifier` field per clause, (b) `run_charter()` fusing the
  positive corpus + `NNN_neg_*` + drift gates + closure meta-gate into one sealed verdict
  as the build's terminal gate, (c) the LTL field activated + a bounded model checker on
  `sat` (M11) for temporal clauses (M21), (d) the OBSERVATORY (M28) families and immune
  (M20) wiring registered as clauses. This is the conscience implementation. No design
  defect.

**Audit verdict (M7–10):** zero design contradictions; migrations (4) route all
computation through XII [H4/M7], (5) the `sid` rename + inverse-in-witness + type-level
`Compromise` [H9/M8], (6) `run_charter()` + falsifier-per-clause as the terminal gate
[H7/M10]. `cic.c`-in-C is the accepted H13 carve-out (trust root); the `.iii` kernel
port is the stated long-term completion. Pass 3 continues: cognition (M11–16),
representation (M17–18), body (M19–23), leaves (M25–31), then per-file depth.

## Pass 3 — consistency audit, Cognition (M11–M16) against H1–H13

- **M11 (decision layer)** — satisfies H10 (results are re-checkable certificates — the
  core invariant, *already* true in source: `smt_check_model`), H4 (egraph ⊂ XII), H12
  (deterministic solvers). **Defect (ordering):** egraph must be folded into XII's
  strategy set (migration 4), and `cic` must dispatch to `sat`/`smt`/`groebner` and
  re-check the certificate (the oracle wiring, M9). No design defect; the *most ready*
  cluster.
- **M12 (category)** — satisfies H11 (it *is* the category). **Defect (new migration
  7):** H11 requires **every** transform — compile (M18), `tp_*` (M17), crypto (M26),
  federation (M19) — *registered* as a morphism with `cat_check_assoc`, and the
  identifications coequalizer = egraph (M11) / pullback = consensus (M19) *implemented*,
  not just asserted. This is the "one category" registration lift. No design defect.
- **M13 (cost)** — satisfies H1/H12. **Tied to critical-path (2):** the cost facet and
  over-K-as-type-error live on the SovVal-as-CIC-inductive; no independent defect.
- **M14 (memo)** — satisfies H10 (hits re-verified, never trusted — *exemplary*, the
  source already enforces it) and H2 (content-addressed keys, after the `cad` collapse).
  No design defect; second-most-ready.
- **M15 (synthesis)** — satisfies H10 (outputs proof-carrying) and no-ML. **Defect
  (ordering):** "search the category" depends on migration 7 (morphism registration) +
  the cost facet (2); until then synthesis is search but not yet *category*-search. No
  design defect.
- **M16 (proof-carrying)** — satisfies H10 (the certificate discipline) and H6
  (kernel-verified). **Defect (ordering):** "every artifact proof-carries" depends on
  the compiler (M18) emitting certificates + the SovVal-inductive (2). No design defect.

**Audit verdict (M11–16):** zero design contradictions; H10 (nothing-trusted) is
already real in M11/M14 source — the strongest-grounded invariant. One new migration
surfaced: **(7) register every transform as a category morphism with associativity
checked** [H11/M12]. Decision (M11) and memo (M14) are implementation-ready now; the
rest chain off migrations 1/2/4/7.

## Pass 3 — consistency audit, Representation + Body + Leaves (M17–M31) against H1–H13

Tighter, since these inherit the same migrations. Recording only new findings:

- **M17 transforms+Babel** — H3 (Glyph/Babel self-verifying) ✓ now; H11 needs migration
  7 (register `tp_*` as morphisms); lossless = SID-iso (M8). **M18 compiler** — H12
  (triple-bit-identity = determinism) ✓ *already real*; but it is **where migrations
  2/4/6/7 converge** — `sema` = kernel-check (M9, mig 2) + constitutional-admit (M10,
  mig 6), `cg` = XII-emit (mig 4), passes = morphisms (mig 7), and H13 self-host port.
  The compiler is the integration apex; sequence it after 1–7 mature.
- **M19 federation** — H10 (consensus-free by certificate) ✓ by design; H11 needs the
  pullback-as-consensus *implementation* (mig 7); H1 needs `@sovereign` (mig 3). **M20
  immune** — H8/H9 ✓; the red→quarantine→bone_marrow wiring depends on `run_charter`
  (mig 6). **M21 time** — H12 ✓ (algebraic deterministic, wall-clock quarantined);
  temporal clauses are part of mig 6. **M22 memory** — H12 ✓ (deterministic bump); H1
  after mig 3. **M23 katabasis** — proven on metal ✓; `REJECT_HEXAD`-as-type-error needs
  mig 2, cycle-as-SovVal needs mig 3. **M24 bloat-removal** — *is* H13, gated by the
  equivalence KATs.
- **Leaves:** **M25 verba** — H3 exemplary (Glyph = serialized SovVal) ✓. **M26 crypto**
  — H10 ✓; suite-via-`cad` after mig 1; orphans pruned (M24). **M27 collections** — H5 ✓
  (crystal = sealed-error reading). **M28 observability** — sealed thresholds = no
  adaptive learning ✓; register families as clauses (mig 6). **M29 sandbox** — H8/H9 ✓;
  cost facet (mig 2). **M30 resolver** — H10 + no-ML ✓; category-search after mig 7.
  **M31 net/IO** — H12 ✓ (membrane quarantines); H1 after mig 3.

**Audit verdict (all 31):** **zero design contradictions against H1–H13.** Every
final form is consistent with the enmeshment contract; the gaps are all
*implementation migrations*, not design seams. The complete critical path:

> **(1)** `cad` collapse (14× `sha256.c` → one) · **(2)** SovVal as CIC inductive
> (bricking/over-K become type errors) · **(3)** the `@sovereign` boundary checker +
> systemwide boundary migration · **(4)** route all computation through XII · **(5)**
> `sid`→`crystal_deps` rename + inverse-in-witness + type-level `Compromise` · **(6)**
> `run_charter()` + falsifier-per-clause terminal gate + temporal/OBSERVATORY/immune
> wiring · **(7)** register every transform as a category morphism. Accepted carve-out:
> `cic.c` + `COMPILER/BOOT` stay C (trust root); the `.iii` kernel port completes H13
> long-term.

Implementation order is the critical-path order; the compiler (M18) is the apex where
all seven converge. Pass 3's remaining work is per-file depth (the individual `tp_*`
morphisms, each crypto primitive, the `xii_curated_*` kernels) — refinements within
clusters already proven consistent. Continuing.

## Pass 3 depth — M7·D1: the Horizon & Curated Kernels (`omnia/xii_horizon.iii`, `xii_curated_{crypto,payloads,arm64_crypto,riscv,extended,...}.iii`)

**Today.** `xii_horizon` is **144 sealed Horizon patterns** — H001–024 crypto hot
paths, H025–042 arithmetic, H043–060 memory-bound, H061–072 capability-checked,
H073–084 witness/provenance, H085–096 governance, H097–108 codegen-meta, H109–120
resolver-self, H121–126 hexad/trit (126 productive) + 12 guard + 6 reserved = 144.
**Each pattern carries metadata: hexad, primary_op, K-cost, cap_class, ct_kind
(constant-time class), prov_xform_id, productive flag** + a structural template that
`xii_horizon_construct(id)` walks to the canonical algebra term. `xii_curated_*` hold
the **per-ISA machine-code realizations** (x86_avx2, arm64_neon) — real sealed bytes,
constant-time-safe where `ct_kind > 0` (e.g. H005 poly1305 via PCLMULQDQ, H007 aes_gcm
via AES-NI).

**Pass 1 — first principles.** The Horizon is **the system's catalog of canonical
morphisms (M12)** — each pattern is a named morphism already tagged with its hexad
(M3), K-cost (M13), constant-time class (M26/M25), and provenance-transform (M6). The
curated kernels are its **per-target machine-code normal forms** — the cost-minimal
(M11/M13) extraction for each pattern on each ISA.

**Pass 2 — compound.** This is the single richest unification point in the whole
system: a Horizon pattern is a **fully-specified Sovereign morphism** — safety (hexad,
M3) + cost (M13) + constant-time discipline (`ct_kind`, M26) + provenance (M6) + a
canonical XII term (M7) — i.e. *every facet of the Sovereign Value, attached to a
morphism*. The curated kernels realize M7's superopt clause concretely: the machine
code **must be bit-identical to the pattern's rewrite normal form** (the promotion
gate) and constant-time where `ct_kind > 0`. Adding a Horizon pattern is therefore a
**constitutional promotion (M10)** gated on five proofs at once — confluence (M7
critpairs), cost-minimality (M13), bit-identity to normal form (M7), constant-time
(M26), and hexad-reachability (M3). Push: the Horizon is the **bridge from the category
(M12) to the metal (M23)** — a pattern's canonical term extracts to per-ISA curated
machine code (M18 `cg`), cost-minimal, and the katabasis gate (M23) admits the
resulting cycle. The crypto suite (M26) is *literally* H001–024 with curated kernels.
No bad redundancy: the Horizon is the morphism catalog (M12) carrying all SovVal facets;
`xii_curated_*` are its per-ISA normal forms (M7/M18); the per-target overrides are not
a separate codegen path but the cost-minimal extraction (M11/M13) made concrete.

**Final — Horizon & Curated Kernels.** `xii_horizon` = the 144-pattern catalog of
canonical Sovereign morphisms, each carrying hexad (M3) + K-cost (M13) + `ct_kind`
(M26) + provenance (M6) as a morphism (M12); `xii_curated_*` = per-ISA cost-minimal
(M11/M13) machine-code normal forms, **bit-identical to the rewrite normal form**
(M7/M10 gate) and constant-time where required (M26); adding a pattern is a
constitutional promotion (M10) gated on confluence + cost + bit-identity +
constant-time + reachability; the Horizon bridges category (M12) to metal (M23/M18),
and is the substrate of the crypto suite (M26). *Falsifier:* a curated kernel ≠ its
rewrite normal form; a `ct_kind>0` pattern whose machine code branches on secret data;
a pattern admitted without all five promotion proofs → red.

## Pass 3 depth — M17·D1: the `tp_*` pipeline as a labelled morphism category

The ~30 transforms (FROZEN SPEC §7B.6 slots) are the **morphisms of the representation
category** (M12); objects are FORMs. Grounded per-file, marking **iso** (lossless ⇒ an
SID-inverse exists, M8) vs **one-way** (lossy projection): `tp_iii_to_ast_bin` ⇄
`tp_ast_bin_to_iii` (III ⇄ AST-bin, **iso**); `tp_iii_to_asm` slot 16 (III → x86-ASM,
source embedded/recoverable); `tp_x86_assemble` ⇄ `tp_x86_disasm` (ASM ⇄ bytes,
**iso**); `tp_asm_to_pe` slot 19 (ASM → PE/COFF, one-way wrap); `tp_babel_json_cbor` ⇄
`tp_babel_cbor_json` slot 22 (JSON ⇄ CBOR, **iso**, payload verbatim); `tp_babel_text`
⇄ `tp_babel_text_back` (**iso**); `tp_iii_to_babel_json` ⇄ `tp_babel_json_to_iii`
(**iso**); `tp_ast_to_babel_json` ⇄ `tp_babel_json_to_ast` (**iso**); `tp_{raw,iii,pe}_hex`
(hex encode, iso); `tp_iii_to_md`/`tp_iii_to_latex`/`tp_ast_dot`/`tp_ripple_{dot,md}`
(**one-way** lossy views); `tp_iii_to_c99` (transpile, one-way); `tp_c99hdr_to_iii`
(ingest, one-way).

**Compounded.** Each is a labelled morphism (M12); the **iso pairs are SID-isomorphisms
(M8)** with round-trip-identity as their falsifier (M10). Every transform produces a
Sovereign Value (M5) carrying source provenance (M6) + cost (M13) and emits a witness.
The **compile composite** `III →cg→ ASM →tp_asm_to_pe→ PE` is exactly what the
behavioral quine-seal (M9/M18) bounds (source FORM + emitted PE FORM). The Babel iso-
cluster (JSON⇄CBOR⇄text) is the **external boundary functor** (M25/M31) — values leave
as self-verifying Glyphs/Babel and re-enter losslessly. The one-way doc/graph
transforms are **forgetful functors**: they drop structure for human view, carry a
`lossy` tag, and are **barred from trust/determinism paths** (H10/H3 — you cannot
reconstruct from them). No bad redundancy: ~30 converters become one labelled category
— iso morphisms (M8-invertible) + forgetful functors. *Falsifier:* an "iso" whose
round-trip ≠ identity; a forgetful view consumed as a trusted value; a transform that
drops provenance/cost → red.

> **First-principles corrections surfaced while drafting M1–M10** (each grounded in
> source, not memory): (a) `TYPES/src/cic.c` *already* has dependent Π-types +
> seven universes + `Trit`/`Hexad` inductives — the charter's "frontier" was wrong;
> the kernel is fuller than the POC. (b) `omnia/sid.iii` is a dependency navigator,
> not SID — a name collision to clear (→ `crystal_deps`). (c) `sha256.c` is
> duplicated **14×** across the C reference tree — the cleanest bloat cut, deferred
> to M24. (d) The immune/repair organs (`quarantine`, `bone_marrow`, `basal_probe`)
> are *built*, not spec-staged as the charter implied.

---

## Module 1 — The Content-Address (`numera/sha256.iii`, `keccak256.iii`, `sanctus/mhash.iii`)

**Today.** `numera/sha256.iii` is hand-rolled FIPS 180-4, **zero externs, K=1.00**,
fully unmasked (cg_r3 does the u32 truncation, so even the masks are gone),
NIST-vector-proven (corpus 02/15). `keccak256.iii` is the convergence-layer hash.
`sanctus/mhash.iii` (kind_origin, the Crown) wraps SHA-256 with domain separation
and a streaming `begin/domain/payload/final` discipline. **But** `sha256.c` is
duplicated **14 times** across the C reference tree (LEXICON, CATALYST,
CATALYST-EXT, FEDERATION, FOUNDERS-ANCHOR, GENESIS-VECTOR, GHOST-CODE, MODULES,
OBSERVABILITY, PLANETARY, POLYMORPHIC-DATA, SANDBOX, SOVEREIGN-WEB, TRINITY), and
content-addressing is split between `mhash` (SHA-256) and `keccak256`.

**Pass 1 — first principles.** There must be exactly **one** content-address
primitive in the whole system. Collapse `sha256`/`keccak256`/`mhash` into a single
`numera/cad.iii` (Content-Address) with a **pluggable, suite-tagged backend** —
the POC's Π20 proved the hand-rolled hash is byte-identical to the reference and
swappable, so the *address discipline* (domain separation + canonical bytes), not
the specific hash, is the primitive. Delete all 14 C copies; every subsystem that
hashed in C now links the one proven `.iii`.

**Pass 2 — compound.** A content-address is the substrate of everything below it:
it makes the Sovereign Value (M5) *named*, the Witness chain (M6) *linked*, the
quine-seal *behavioral*, and consensus-free agreement (M19) *possible*. So push it
further than v1: make the address **crypto-agile at the address layer** — the
digest carries a `suite_id`, so a value's name survives a Q-Day hash swap and old
names verify under their original suite. This is upstream of M5/M6, so they inherit
*temporal immunity for free* — no per-module migration. And the 14→1 collapse means
the kernel (M9), constitution (M10), and quine-seal all hash through **one
Π20-proven primitive**, so the behavioral seal covers the *entire* system with a
single audited hash — the hash-agnostic proof becomes systemwide, not local.
No bad redundancy: `keccak256` is retained only as a *registered alternate suite*,
not a parallel path.

**Final — `numera/cad.iii`.** The single Content-Address: NIH SHA-256 default +
Keccak-256 registered alternate, suite-tagged 256-bit digests, domain-separated,
streaming, the one addressing primitive every module calls. `sanctus/mhash` folds
in as `cad` with the Crown domain. **Provably better than the 14 C copies in every
way:** one source vs fourteen, KAT+Π20-proven vs unverified, determinism-sealed,
suite-agile. *Falsifier:* two distinct canonical inputs sharing a digest, or a
suite-swap that breaks an old name's verification → red.

---

## Module 2 — The Ternary Algebra (`omnia/hexad_algebra.iii`, trit layer)

**Today.** A balanced trit (NEG=-1, ZERO=0, POS=+1), **compared by equality only**
(the i64-ordering SIGSEGV trap), with five total ops: NOT (`-a`), AND (NEG
dominates), OR (POS dominates), SUM (clamped add), MUL (NEG·NEG=POS, ZERO
annihilator), plus an asymmetric `weight` (NEG=-2) so damage outweighs recovery.
It is used today purely as the *safety* algebra under the hexad.

**Pass 1 — first principles.** The trit is being used at half its power. It is, by
construction, a **Kleene strong three-valued logic**, where `ZERO` is not merely
"informational pillar" but *the unknown itself*. The first-principles move is to
recognize that III already has two things that are secretly one: the trit's `ZERO`
(safety) and the gap's "unknown" (M4). Unify them — `ZERO` becomes the canonical
"undetermined," and the trit ops become the sound propagation rules for partial
information. The safety algebra and the uncertainty algebra are the *same algebra*
at different arities.

**Pass 2 — compound.** This lifts M1 (trits/hexads are tiny, canonical
content-addresses — cheap to name and memoize) and it *is* the seed of M3 (a hexad
is six of these) and M4 (a gap is a `ZERO`-valent payload). Push further: make the
five trit ops **XII rewrite rules** (M7) rather than hand-coded `when`-cascades, so
the safety/uncertainty algebra is *evaluated by the universal engine* and its laws
(De Morgan, double-negation-as-recovery `MUL(NEG,NEG)=POS`) are **Knuth–Bendix
confluence-checked** instead of merely tested. Bidirectional: M7 gains a tiny,
total, provably-confluent rule set to anchor its critical-pair machinery on; M2
gains machine-proven algebraic laws. No bad redundancy: there is exactly one
ternary algebra, evaluated exactly one way, and the gap is not a second type but
the `ZERO`-inhabited reading of this one.

**Final — the Ternary Algebra.** One balanced-ternary Kleene algebra, equality-only,
five total ops expressed as confluent XII rules, asymmetric (NEG=-2) so catastrophe
dominates — the shared logic of *both* hexad safety pillars (M3) and Sovereign-Value
uncertainty (M4). *Falsifier:* any op disagreeing with the spec table on the 3×3
domain, or a non-confluent critical pair among the five rules → red.

---

## Module 3 — The Hexad (`hexad_algebra` compose · `hexad_reach` · `hexad_pfs` · `hexad_epistemic` · `hexad_mobius` · `hexad_dynamic`)

**Today.** Six trits packed base-3 into a u16 (0..728), six named pillars
(inverse-derivability, causality-depth, consent-recency, replication-tier,
adversariality-class, coherence-impact); `compose6` = AND on the four structural
pillars / OR on the two recovery pillars; `reach` admits exactly **144 of 729**
(NEG in any structural pillar → unrepresentable); `pfs` proves the six bricking
firmware ops untypable; `epistemic` adds confidence; `mobius` adds inverses;
`dynamic` adds promotion. Richer than the POC. Its C ancestors live in `HEXAD/src/`.

**Pass 1 — first principles.** The hexad is III's **safety type**, and a type
belongs *on the value*, not in a side-table consulted at runtime. Make the hexad
the type-level safety tag every Sovereign Value carries (M5), so a bricking
composition is not *rejected at runtime* but *unconstructible*. Delete the
`HEXAD/src/*.c` ancestors — the `.iii` ports are corpus-green and determinism-sealed,
i.e. provably superior in every dimension that matters to III.

**Pass 2 — compound.** This is six instances of M2 (so it inherits XII-evaluated,
confluence-checked ops) and it is content-addressed by M1 (a hexad is a 16-bit
canonical name). Two unifications push it further: (a) `hexad_epistemic`'s
confidence pillar **is** M4's gap — an unknown value's coherence-impact pillar is
`ZERO` (undetermined), so epistemics and uncertainty stop being two systems; (b)
`hexad_mobius`'s inverse **is** M8's SID inverse projected onto the safety lattice
— so reversibility is described once, not twice. `hexad_dynamic`'s promotion becomes
a *constitutional* act (M10), gated by a falsifier, not an ad-hoc mutation.
Bidirectional: M5 gains a structural impossibility (bricking is unsayable); M8 gains
a safety-typed inverse; M10 gains the only legal promotion path. No bad redundancy:
epistemic⊂gap, mobius⊂SID, dynamic⊂constitution — three apparent subsystems revealed
as facets of three deeper ones.

**Final — the Hexad.** The universal 6-trit safety type carried by every value;
`reach` (144/729) and `pfs` make catastrophe unrepresentable at the type level;
`epistemic` unifies with the gap (M4), `mobius` with SID (M8), `dynamic` with the
Constitution (M10). C ancestors removed. *Falsifier:* a constructable value whose
composed hexad is non-reachable, or a bricking op that types → red.

---

## Module 4 — The Unified Uncertainty (`omnia/either.iii`, `numera/checked.iii`, `hexad_epistemic.iii` → `numera/uncertainty.iii`)

**Today.** Partial information is handled three incompatible ways: `either.iii`
(left/right), `checked.iii` (overflow flags), `hexad_epistemic.iii` (confidence).
None is the single typed gap the charter needs; this is the one genuinely *new*
organ (POC `negknow.py` proved the shape).

**Pass 1 — first principles.** One typed gap: `Gap{ kind ∈
{essential, hole:NAME, redacted, derived}, reason, antecedents }`, with **total,
sound, maximally-precise** arithmetic (÷0 → gap; `0·unknown → Known(0)` — sound
*and* precise, the POC's hardest-won invariant) over the M2 ternary reading. A gap
is a first-class, content-addressed (M1) value that *explains itself*: a provenance
DAG walkable to named root causes.

**Pass 2 — compound.** This is the `ZERO`-inhabited reading of M2 (so it is not a
new algebra, just M2 applied to payloads) and it is M3's epistemic pillar made
computational. Push further: make the provenance DAG a **first-class negative-
knowledge value** — "unknown *because* sensor_3 is essential-gap, via X→Y→Z" — so
III reasons about *what it does not know* as rigorously as what it does. This lifts
every prior: M1 gains a reason to address gaps (their provenance is named state);
M2 gains its computational purpose (unknown-propagation, not just safety tags); M3
gains a sound epistemic pillar. Bidirectional with the not-yet-written: M5 carries a
gap as payload; M6 can redact a witness to a `redacted` gap (provable forgetting);
M16's proofs can be *partial* and stay sound. No bad redundancy: `either`/`checked`
keep their public APIs but **delegate** to this one gap; their duplicated handling
is deleted.

**Final — `numera/uncertainty.iii`.** The one typed gap: total + sound + precise
arithmetic, a content-addressed provenance DAG, `root_causes`/`explain`, the
`ZERO`-reading of the ternary algebra. `either`/`checked`/`epistemic` delegate.
*Falsifier:* an operation that raises, returns a wrong concrete for an unknown
input, or yields a derived gap with empty provenance → red.

---

## Module 5 — The Sovereign Value (`omnia/sovval.iii`, net-new)

**Today.** Does not exist. Values cross boundaries as raw scalars/pointers; safety
(M3), provenance (M6), uncertainty (M4), and cost are things modules *do*
separately, re-derived at each boundary.

**Pass 1 — first principles.** Promote one indivisible value to *the* currency:
`SovVal = { payload: Known|Gap (M4), hexad: u16 (M3), witness: frag_id (M6) }`,
with a single total `sv_op` that composes payloads (sound gap arithmetic), composes
hexads (`compose6`, refusing non-reachable results as a typed `Refused`), and emits
a witness. Gap-totality, safety-typing, provenance, and witnessing stop being
behaviors and become what a value **is**. The only thing that crosses any boundary
is a SovVal — so non-interference and gap-containment are *structural*.

**Pass 2 — compound.** The four-facet realization (the charter's FR-1′) adds a
**cost** facet now, not later: `SovVal = { payload, hexad, witness, cost }`, cost
joined via M13's cost-lattice, so the K-floor (≥0.85; gate ≥0.99) and the
"physics-boundary-only cost" mandate become a property the value *carries* — an
over-budget composition is `Refused` exactly like a bricking one. This lifts every
prior module into a single object: M1 names it, M2/M3 type its safety, M4 is its
payload-when-unknown, M6 is its provenance. And it sets the agenda for everything
above: M7 (XII) rewrites SovVals; M9 (kernel) type-checks them; M10 (constitution)
gates them; M17 (transforms) are morphisms *between* them; M19 (federation) ships
them across nodes. Push further still: `sv_op` is declared a **morphism in M12's
category**, so its associativity/identity are *functor laws checked by the
Constitution*, not assumed. No bad redundancy: there is one value type, and every
other "carrier" (raw bytes, `either`, tuples) becomes a *view* of it at a boundary.

**Final — `omnia/sovval.iii`.** `{payload, hexad, witness, cost}`; total `sv_op`
composing all four facets; `Refused` for non-reachable hexad **or** over-K cost;
the single currency of the system; a categorical morphism (M12). New language
support (`@variant` with real codegen for `payload`, `@sovereign fn` asserting a
boundary trades only SovVals — both with negative tests `III_VARIANT_NONEXHAUSTIVE`,
`III_NONSOVEREIGN_BOUNDARY`). *Falsifier:* a constructed SovVal with a non-reachable
hexad, an over-budget composition that is not `Refused`, or a boundary that admits a
non-sovereign value → red.

---

## Module 6 — The Witness & Commons (`aether/witness_hook.iii`, `numera/witness_spine.iii`, `numera/algebraic_time.iii`)

**Today.** `wh_publish` is the universal provenance hook: it validates, computes a
fragment id as **Keccak256 over all fields**, advances algebraic time, and appends
to an in-epoch log — **full gospel scale, 1M fragments / 64 MiB rolling payload,
not down-scaled**. The chain is append-only (`wh_revoke` marks, never deletes).
`witness_spine` is the master DAG: a frag-id hash table + per-pillar/producer/
operation reverse indices + per-epoch root store + a from-seed **replay verifier**,
all deterministic (power-of-two masks, no modulo/division, no recursion, sentinel
loops). `algebraic_time` is the strictly-monotonic logical clock. (`wh_chain_root`
exists — `witness_spine.iii:32`.)

**Pass 1 — first principles.** The witness is the system's **memory**, and memory
should not be a side-call you remember to make — it should be inseparable from
producing a value. So `wh_publish` becomes *the act of minting a Sovereign Value*
(M5): you cannot produce a value without producing its provenance. The chain's
fragment id routes through M1's content-address (`cad`), not a second Keccak path.

**Pass 2 — compound.** Unify the three files into one organ — hook (produce),
spine (index/replay), algebraic-time (clock) — and push it past v1 with **provable
forgetting** (charter FR-4): `witness_spine.redact(frag, reason)` replaces a
fragment's payload with a `redacted` gap (M4), re-seals the chain, and *proves*
integrity (chain still replays) ∧ continuity (independent fragments byte-identical)
∧ blast-radius (dependents become honest gaps pointing at the redaction). This
dissolves the append-only-vs-forgettable contradiction. Amplification across all
priors: **M1** gains its largest consumer (the chain is the system's heaviest
content-address user — and suite-tagging makes the *whole history* temporally
immune); **M4** gains the redaction use-case and a real provenance sink; **M5**'s
`witness` facet *is* the chain link, so every value is on the record by
construction; **M2/M3** ride along (each fragment carries its hexad pillar, already
in `wh_publish`'s signature). And it seeds the body: **M10** ratifies clauses *as*
witness fragments (`CLAUSE_RATIFICATION`); **M19** replicates the chain for
consensus-free agreement; **M20** logs distress/repair to it; **M21** *is*
`algebraic_time`. No bad redundancy: one chain — produced by the hook, indexed by
the spine, clocked by algebraic-time, forgettable by redaction. Four files, one organ.

**Final — the Witness & Commons.** `wh_publish` mints the provenance of every
SovVal (M5) through `cad` (M1, suite-agile → the entire history is Q-Day-proof);
`witness_spine` indexes, replays, and now **forgets with proof**; `algebraic_time`
clocks it; full 1M-fragment gospel scale retained verbatim. Append-only *and*
provably forgettable. *Falsifier:* a SovVal with no witness; a chain that fails
from-seed replay; a redaction that breaks continuity or leaves a dependent
concrete-but-meaningless → red.

---

## Module 7 — XII, the universal evaluator (`omnia/xii_term`, `xii_rewrite`, `xii_critpairs`, `xii_canonicalise`, `xii_curated_*`, `xii_horizon`, `xii_emit_gen`)

**Today.** XII is a *complete, proven* term-rewriting system — the most rigorous
engine in III. `xii_term` is the term arena (basis/fusion/if/loop constructors).
`xii_rewrite` is **40 sealed reduction rules** (associativity, IF common-subterm
lifting, LOOP reductions, identity/PE-const, cap-flow, witness/provenance folds,
state-transition, pattern folds), each a `match`/`apply` pair, **every rule strictly
decreasing MPO weight (termination, CRY-XII-TERM-001)**. `xii_critpairs` verifies all
**117 critical pairs converge** across 7 classes, giving **confluence by Newman's
lemma (CRY-XII-CONF-001)**. `xii_canonicalise` drives terms to normal form;
`xii_curated_*` hold pre-proven optimized machine-code kernels (crypto, RISC-V,
arm64); `xii_horizon` carries rewrite metadata; `xii_emit_gen` emits machine code
from XII terms. Sealed (`xii_rewrite.mhash`), K=1.0. **Yet today XII is used mainly
for its own canonicalisation domain — not as the system's evaluator.**

**Pass 1 — first principles.** A confluent, terminating, critical-pair-proven
rewrite system *is the definition of* a deterministic universal evaluator. The
first-principles act — and the one the user demanded ("XII is part of III; unify
them") — is to make XII **the evaluator of everything**. The trit ops (M2), the gap
arithmetic (M4), `sv_op` (M5), the kernel's β/ι reduction (M9), cost reductions
(M13), and the transforms (M17) all become rewrite rules over `xii_term`. There is
**one** evaluator; its confluence + termination make the *entire system* compute
deterministically and order-independently — the deepest possible form of Π3/Π4/Π5:
determinism is not tested, it is a *theorem about the one engine*.

**Pass 2 — compound.** This is the keystone that fuses the engine, and it pays the
debts I opened in earlier modules. **M2:** the five trit ops become XII rules, so
their laws are confluence-checked by `xii_critpairs` (the promise made in Module 2,
now paid). **M4:** gap arithmetic becomes rewrite rules — gap-totality is a rewrite
invariant. **M5:** `sv_op` *is* an XII rewrite, so its associativity is an XII
confluence fact — which is exactly what makes it a lawful morphism in M12's
category (the promise made in Module 5, paid here). **M6:** XII already has
*witness/provenance fold* rules (the G-family) — so every rewrite emits a witness
fragment; evaluation is self-recording. **M1:** the curated kernels are content-
addressed and `xii_rewrite.mhash`-sealed. Push past v1: the `xii_curated_*` kernels
become a **constitutionally-gated growing library of pre-proven morphisms** — adding
one is an M10 act admitted only if it (a) preserves confluence (re-run 117+N
critical pairs), (b) strictly decreases MPO (termination), and (c) is **bit-identical
to its own rewrite normal form** (the curated machine code ≡ what the rules produce).
That last clause makes superoptimization (cg_superopt) *sound by construction* and
ties M13 (cost): a curated kernel is a cost-minimal rewrite, and the cost facet (M5)
strictly decreases along it. No bad redundancy: the POC's `rewrite.py`, the kernel's
reducer, the cost optimizer, and the transform engine all **collapse into XII rules
over one arena** — there is not a second evaluator anywhere in the idealized system.

**Final — XII, the one engine.** The `xii_term` arena + the confluent (117-pair)
terminating (MPO) rule set, *extended* to evaluate trit/gap/`sv_op`/kernel/cost/
transform; `xii_curated_*` a constitutionally-gated library of bit-identical
pre-proven morphisms; every rewrite witnessed (M6, the G-family); `xii_emit_gen`
the compiler back-end (M18). The single deterministic evaluator of the one category
(M12). *Falsifier:* a rule that breaks any critical pair or fails to decrease MPO;
a curated kernel whose machine code ≠ its rewrite normal form; any term reducing to
two distinct normal forms → red.

---

## Module 8 — SID & Reversibility (`COMPILER/BOOT/sid.iii`, `numera/reversible.iii`, `aether/reversibility_audit.iii`, `hexad_mobius`)

**Today.** Reversibility is *three* mechanisms that don't know they're one, plus a
naming collision. `COMPILER/BOOT/sid.iii` is the real **Side-effect Inverse
Derivation** (compile-time, Ring R-2/R-1: derives an op's inverse). `numera/
reversible.iii` is **runtime transactional reversibility** (a LIFO stack of
capability-scoped envelopes; commit truncates the undo log, rollback replays every
undo in reverse and is witnessed; no recursion; privileged undos capability-gated).
`aether/reversibility_audit.iii` attests it. `hexad_mobius` gives the safety lattice
its inverses. And confusingly, `omnia/sid.iii` is a *Crystal-ID dependency-graph
navigator* — unrelated to SID, squatting on the name.

**Pass 1 — first principles.** Reversibility belongs *on the value*, not in a
transaction wrapper bolted around effects. Unify the three mechanisms into **one
inverse concept**: the compiler (BOOT/sid) derives an op's inverse at rewrite time;
the witness (M6) records the forward op *with* its derived inverse; rollback is
simply replaying the witness chain backward. Because the inverse is **derived, not
stored** (the POC's key insight), reversible time-travel costs no extra log. First,
clear the collision: rename `omnia/sid.iii` → `omnia/crystal_deps.iii` (it is a
dependency navigator), freeing "SID" for the one concept.

**Pass 2 — compound.** This pays the M3 debt: `hexad_mobius`'s inverse **is** the
SID inverse projected onto the safety lattice — one reversibility, two views, as
promised. It deepens M6: the witness chain becomes losslessly walkable *backward*
(the inverse rides each fragment), so the commons is a navigable Merkle-DAG of
computation you can run in reverse — and `numera/reversible`'s envelopes become
*views over chain segments*, not a separate undo log. It deepens M7: XII rewrite
rules that are bijective carry their inverse as a paired rule, and the G-family
witness folds record both directions — so reversibility is a rewrite property, not a
runtime bookkeeping layer. M5 gains a reversibility facet (a SovVal's witness records
forward + inverse). Push further into the Constitution (M10): an op is exactly one
of three — **reversible** (SID-derived inverse round-trips), **typed-irreversible**
(carries a `Compromise<LOW|MEDIUM>` tier per the EFFECTS spec), or **unrepresentable**
(`Compromise<HIGH>` = bricking, M3 `reach` forbids construction). Safety, reversibility,
and admission collapse into *one discipline*. No bad redundancy: the collision is
gone; compile-SID + runtime-reversible + mobius + audit become one organ with one
inverse, projected into hexad (M3), witness (M6), and gate (M10).

**Final — SID & Reversibility.** One inverse concept: derived by the compiler,
carried by every witness fragment (M6) for lossless backward replay (no extra log),
preserved by XII bijective rules (M7), projected into the safety lattice by
`hexad_mobius` (M3), attested by `reversibility_audit`, and gated by the Constitution
as reversible / typed-`Compromise` / unrepresentable (M10, M3). `omnia/sid` renamed
`crystal_deps`. *Falsifier:* a forward op whose derived inverse fails to round-trip;
an irreversible op with no `Compromise` tier; a `Compromise<HIGH>` value that
constructs → red.

---

## Module 9 — The Proof Kernel (`TYPES/src/cic.c`, `numera/proof_carrying.iii`, `proof_term.iii`, `theorem_carrier.iii`)

**Today — and a correction to the charter.** The v2 charter (and the POC) called
"dependent Π-types + universe stratification" the *remaining frontier*. Reading the
source proves that **wrong**: `TYPES/src/cic.c` is already a full Calculus of
Inductive Constructions kernel — de Bruijn terms, **β/ζ/δ/ι/η** reduction, whnf
conversion with η-expansion, a **seven-level universe (Prop, Type₀..Type₆)** with
**predicative Π for sorts < Type₆ and impredicative Type₆ (U-Top)**, and **seven
built-in inductives: Bool, Trit, Hexad, Phase, Tier, Epoch, List** with a schematic
ι rule. It is hand-rolled, NIH, no external prover. `proof_carrying.iii` is the
Curry–Howard certificate layer (Merkle/Keccak256 vector + polynomial commitments,
log-time verification, M11/M12). The POC's propositional `kernel.iii` is a pale
shadow of what III already has in C.

**Pass 1 — first principles.** Stop treating dependency/universes as a frontier;
`cic.c` *is* the soundness anchor (A1). Two first-principles acts: (a) make its
reduction engine **XII** (M7) — the β/ζ/δ/ι/η rules become XII rewrite rules over
`xii_term`, so the kernel's normalizer *is* the universal evaluator (the M7 promise,
paid here), and strong normalization / confluence are XII's existing theorems; (b)
recognize that two of its seven inductives — **`Trit` and `Hexad`** — are exactly
M2 and M3, so the kernel **already types the safety algebra**: a bad hexad is not
merely `reach`-forbidden, it is a *type error*.

**Pass 2 — compound.** This is where the whole tower locks together. Make the
**Sovereign Value (M5) a CIC inductive** — a dependent record `{ payload : Value,
hexad : Hexad, witness : FragId, cost : Cost }` whose reachability (M3) and K-floor
(M13) are **type-level refinements**, so `sv_op`'s refusal of bricking/over-budget
compositions is *type-checking*, not a runtime guard. The **gap (M4) is an open
term** — a metavariable / hole — so "compute with holes" (Π16) is literally the
kernel's open-term elaboration, sound by the kernel's own rules. **proof_carrying's
certificate is a witness fragment (M6)** — Curry–Howard means the proof term *is*
the witnessed program, so the certificate layer and the commons are one. Push
further than any prior pass: because the kernel reduces via XII and every value is a
checked CIC term, **every `.iii` artifact the compiler (M18) emits can carry its
cic-checked proof term** — all of III becomes proof-carrying, not just the kernel,
and the seven-level universe is the *third consistency pillar* (no Type:Type →
Girard-safe) that the charter wrongly called missing. No bad redundancy: the POC's
`kernel.iii` is **retired as superseded** by `cic.c`; `proof_term`/`theorem_carrier`/
`proof_carrying` are the one certificate discipline; there is one kernel.

**Final — the Proof Kernel.** `cic.c` (full CIC: β/ζ/δ/ι/η, 7-level
predicative/impredicative universe, 7 inductives) as the soundness anchor, reducing
via XII (M7); the Sovereign Value is a dependent inductive so bricking and
over-budget are *type errors* (M3, M13); gaps are open terms (M4); every emitted
artifact carries a Curry–Howard certificate that is a witness fragment (M6, M18).
Honest scope: `cic.c` remains the **trusted bootstrap kernel in C** (the one
foundational C, like `COMPILER/BOOT`); the in-language port `numera/kernel.iii` is
the stated goal, not a faked claim. *Falsifier:* a closed term inhabiting ⊥; a
bricking or over-K SovVal that type-checks; an emitted artifact whose certificate
fails to recompute; any `Type : Type` acceptance → red.

---

## Module 10 — The Constitution (`numera/constitution.iii`, `constitution_preserver.iii`)

**Today.** Already a charter engine: clauses keyed by `Keccak256(text)`, each
carrying a textual statement, an **LTL formula**, an **11-opcode admissibility
bytecode** (`cons_eval_predicate`), a witness-production rule, dependencies, and an
effective epoch; ratification publishes a `CLAUSE_RATIFICATION` witness fragment;
`constitution_preserver` guards it. **But** clauses are *instantaneous* predicates
judged in isolation, with **no paired falsifier**, the **LTL field carried but
unused**, and the constitution is **not** the build's terminal gate — the positive
corpus, the `NNN_neg_*` falsifiers, the drift gates, and the closure meta-gate all
run separately.

**Pass 1 — first principles.** The Constitution is the system's **conscience**, so
it must be the *single* authority over every guarantee, and every guarantee must
carry its **falsifier** — `HOLDS = verify ∧ falsify`, the POC's whole discipline.
Add a `falsifier` field per clause; write `run_charter()` to run all clauses'
verify ∧ falsify, seal the verdict vector into **one charter seal**, and become the
build's **terminal gate** — red unless all hold, all falsifiers are caught, and the
seal equals golden (DRIFT-driven reseal on intended change). Fuse the four
separate check-suites under it.

**Pass 2 — compound.** This is the binding act — every prior module's falsifier
*becomes a constitutional clause*: M1 (no digest collision), M2 (trit laws +
confluence), M3 (no bricking types), M4 (gap soundness), M5 (no non-sovereign
boundary), M6 (chain replays + redaction continuity), M7 (the 117 critical pairs
converge), M8 (inverse round-trips; `Compromise` tiers honored), M9 (⊥
uninhabited; no Type:Type). The Constitution is literally the **union of all module
falsifiers** — the system auditing itself. Now activate the dormant LTL field via
M21 (`temporal_logic`): clauses may be **temporal** — "the seal is *always*
reproducible," "a red verdict *eventually* quarantines (M20)" — not only
point-in-time. `constitution_preserver` becomes the **self-preservation meta-clause**
(amendment must be conservative, M8/Π8, or a witnessed ratified amendment).
Promotion of an XII curated kernel (M7) or a dynamic hexad (M3) is *gated here* —
the promises made in those modules are paid by this one gate. Push further: the
charter seal **is** the behavioral quine-seal — sealed over source + emitted code
(M9/M18) + verdict — so the Constitution proves "this is the auditor this seal
describes," Gödel-safely (instance check, never self-consistency). No bad
redundancy: the positive corpus, the `NNN_neg_*` falsifiers, the drift gates, the
closure meta-gate, and the POC's two mutation suites **all collapse into one
`run_charter()` with one seal**. There is one conscience.

**Final — the Constitution.** Every III guarantee is a clause with a paired
falsifier, instantaneous (11-opcode VM) or temporal (LTL, M21); `run_charter()`
seals the verdict vector into the one charter/quine seal and is the build's terminal
gate; ratification is witnessed (M6); promotion and amendment are gated (M3, M7, M8);
`constitution_preserver` is the self-preservation meta-clause; all legacy
check-suites fuse in. *Falsifier:* a guarantee with no clause; a clause with no
falsifier; a green build under any injected corruption; a seal that drifts without a
ratified amendment → red.

---

## Module 11 — The Decision Layer (`numera/sat.iii`, `smt.iii`, `groebner.iii`, `egraph.iii`)

**Today.** Four deterministic, NIH decision procedures, no statistical learning
anywhere. `sat` is CDCL — clause learning, 1UIP analysis, two-watched literals,
non-chronological backjump — but **no restarts, no randomness, no learned-from-data
heuristic; a fixed static decision order** (smallest unassigned var, positive
phase). `smt` is DPLL(T) over LIA (exact-rational Bland's-rule simplex +
branch-and-bound) and BV (bit-blasted into `sat`), combined by Nelson–Oppen to a
deterministic fixed point — and crucially **`smt_check_model` re-verifies any model**.
`egraph` is bounded **equality saturation + minimum-cost extraction** (union-find +
hashcons, no recursion). `groebner` is the algebraic (polynomial-ideal) procedure.
Today they stand alone, exercised by their own KATs.

**Pass 1 — first principles.** A proof kernel (M9) and a conscience (M10) need to
*decide* propositions in decidable theories. Make M11 their **oracle**: cic
dispatches a propositional goal to `sat`, an arithmetic/bit-vector goal to `smt`, a
polynomial goal to `groebner`. But the kernel must never *trust* a solver — so every
result returns as a **re-checkable certificate** (the SAT model, `smt_check_model`'s
transcript), and the kernel/Constitution accept it only by re-verifying. Solving is
untrusted; the certificate is sound.

**Pass 2 — compound.** The deepest unification in the cognition layer: **`egraph`
*is* XII (M7) under a different strategy.** XII = confluent rewriting to a single
normal form (for determinism); egraph = equality saturation (apply all rewrites,
keep all equal forms compactly) + min-cost extraction. They share one rule set.
Unify them: **one rewrite system (XII's 40 sealed rules + curated kernels), two
strategies** — `canonicalise` (normal form, M5/M7 determinism) and `saturate+extract`
(cost-minimal representative, M13 superoptimization). This pays M7's superopt promise
*and* binds M13: extraction minimizes the cost facet. Amplification across the tower:
**M9** gains theory oracles whose certificates it re-checks (untrusted solver, sound
kernel); **M10** gains SMT-decided admissibility for clauses too rich for the
11-opcode VM, and a **bounded model checker over `sat`** to *decide* the temporal
LTL clauses (M21); **M5** — a solver result is a proof-carrying Sovereign Value;
**M6** — `smt`'s transcript witness is a chain fragment. Push further into the body:
because every solve is deterministic + certificate-bearing, a solve done on one node
is a value any other node **re-checks without re-solving** (M19: consensus-free
agreement on results, not re-execution). No bad redundancy: `egraph` folds into XII
(one rewrite system, two strategies); the solvers are the kernel's oracle, never a
parallel reasoner; nothing is trusted — everything is re-checked.

**Final — the Decision Layer.** `sat`/`smt`/`groebner` are the kernel's (M9) and
Constitution's (M10) deterministic oracles for decidable theories; every result is a
re-checkable proof-carrying certificate (M5/M6/M9), never trusted. `egraph` is
unified into XII (M7) as the cost-minimal extraction strategy (M13) over the one
rewrite rule set. All NIH, no statistical learning, no recursion. *Falsifier:* a
solver result accepted without its certificate re-checking; a non-deterministic
solve; an egraph extraction that is not cost-minimal or contradicts an XII normal
form on an equality → red.

---

## Module 12 — Category (`numera/category.iii`)

**Today.** A real finite-category engine: objects (32-byte ids) and morphisms in
slot tables, with composition, identities, the **associativity law** (`cat_check_assoc`
proves `(h∘g)∘f = h∘(g∘f)`), and the universal constructions **pullback, pushout,
coequalizer**. Morphism id = `Keccak256(src ++ dst ++ op)`, composite =
`Keccak256(f ++ g)` — composite uniqueness is a deterministic function of inputs.
Today it stands alone.

**Pass 1 — first principles.** This is the abstract algebra of the thesis's "one
category." Declare it so: **every transform in III is a morphism here** — `sv_op`
(M5), XII rewrites (M7), kernel reductions (M9), the transforms (M17), compiler
passes (M18). Objects are Sovereign-Value *types* (the cic inductives, M9);
morphisms are the operations between them; content-addressed (M1).

**Pass 2 — compound.** This pays the M5/M7 promise — `sv_op`'s associativity *is*
`cat_check_assoc`, now a constitutional clause (M10) rather than an assumption. And
the universal constructions are revealed as the **unifiers of organs that looked
unrelated**: a **coequalizer is exactly an `egraph` equality class (M11)** (quotient
by a congruence); a **pullback is exactly federation agreement (M19)** (two nodes'
morphisms over a shared object meet at their pullback — consensus *is* a limit); the
**transform pipeline (M17) is a sub-category** of representations with functorial
conversions. So XII (composition), egraph (coequalizer), and federation (pullback)
are not three algebras — they are three *named constructions in this one category*.
Push further: content-address (M1) and witness (M6) every morphism, so the very
*shape* of all computation is itself a Sovereign Value, sealed by the Constitution
(M10). No bad redundancy: one category; everything else is a construction in it.

**Final — Category.** The abstract algebra of the one category: objects =
Sovereign-Value types (M9), morphisms = every III operation (M5/M7/M9/M17/M18),
content-addressed (M1) and witnessed (M6); associativity/identity are constitutional
clauses (M10); the universal constructions unify the body — coequalizer = egraph
equality (M11), pullback = federation agreement (M19), sub-category = the transform
pipeline (M17). *Falsifier:* a composition breaking `cat_check_assoc`; an operation
crossing a boundary that is not a lawful morphism (non-sovereign, M5) → red.

## Module 13 — Cost (`numera/cost_lattice.iii`, `cost_calculus.iii`)

**Today.** A bounded partial-order lattice over **six-dim microarch cost vectors**
(latency, throughput, register pressure, icache, dcache, energy), with two layers —
scalarizing weight orders (a total preorder via saturating dot) and the intrinsic
product lattice (meet = per-dim min/glb, join = per-dim max/lub, bottom = 0, top =
MAX). Standard orders seeded (server/realtime/lowpower/balanced). Pure: no externs,
no alloc, no FP, no recursion. Self-described "M19 boundedness foundation."
`cost_calculus` is the calculus over it. Today: a standalone analysis.

**Pass 1 — first principles.** Cost is the *measure* of computation, so it belongs
*on the value*. Make the 6-dim cost vector the **fourth facet of the Sovereign Value
(M5)**: `sv_op` joins costs (lattice lub), and the K-floor + "physics-boundary-only
cost" mandate become a lattice constraint — a composition exceeding budget is
`Refused`, exactly like a bricking hexad. Cost is intrinsic, never a separate pass.

**Pass 2 — compound.** This pays M5's fourth-facet promise and binds the engine:
**`egraph` min-cost extraction (M11) minimizes over *this* lattice** → the
cost-optimal morphism (superoptimization), and **XII's curated kernels (M7) are
lattice-minimal rewrites** — so M7/M11/M13 are one optimization, not three. It binds
M9: cost is a type-level refinement on the SovVal inductive (over-budget = type
error). It binds M10: the K-floor is a constitutional clause evaluated on the
lattice. It binds M12: **cost is a functor** from the category to the lattice (every
morphism has a cost; composite cost = join), so "the cheapest program/proof" is a
categorical+lattice optimization with a deterministic answer. Push further: the
scalarizing orders (server/realtime/lowpower/balanced) become **deployment contexts**
— the *same* Sovereign Value extracts to a *different* cost-optimal machine form
(M17→asm/PE) per target, all deterministic and witnessed. No bad redundancy: one
cost lattice — the SovVal facet (M5), the superopt target (M7/M11), the K-floor
measure (M10), a functor over the category (M12).

**Final — Cost.** The 6-dim microarch lattice as the Sovereign Value's fourth facet
(M5); `sv_op` joins cost; over-budget = `Refused`/type error (M9); the K-floor a
constitutional clause (M10); the minimization target for egraph/XII superoptimization
(M7/M11); a functor category→lattice (M12); scalarizing orders = deployment contexts
for cost-optimal extraction (M17). *Falsifier:* a composite cost that isn't the
lattice-join of its parts; an over-K value that constructs; an "optimal" extraction
that isn't lattice-minimal → red.

---

## Module 14 — Memo (`numera/memo_lattice.iii`, `aether/memo_query.iii`)

**Today.** A content-addressed cache of past computations: 32-byte content-address
keys (from `content_addr`, M1), values = `(output_commitment, chain_id)`. Its
load-bearing discipline is **soundness, not speed**: admission verifies the
producing chain *before* insert; a hit means "present, not stale," **never
"trusted"** — the caller MUST re-verify via `ws_lookup_id` before consuming;
stale entries are invisible; `ml_revalidate` replays the chain before un-staling.

**Pass 1 — first principles.** Determinism (the engine's Π5) + content-addressing
(M1) make a cache *correct by construction* — the same input has the same address
has the same output. So memoization should be a free, systemwide property: every
SovVal computed once is keyed by its content-address and reusable. But the existing
discipline is exactly right and must be kept: a cache is an *optimization, never an
authority* — every hit is re-checked against the witness chain (M6).

**Pass 2 — compound.** This is the efficiency layer over the whole engine, and it
binds cleanly: **M7** (XII normal forms) and **M11** (solver results) are memoized by
content-address — *solve/normalize once, re-check forever*; **M5** is the unit cached;
**M6** is the authority every hit re-verifies against; **M1** is the key. Push into
the body: **M19** federation *shares* the memo lattice — a result computed on one
node is a re-checkable cache entry for every other (consensus-free reuse, M11's
"agree by certificate" applied to caching). This realizes the POC's "provable
memoization" emergent at full scale. No bad redundancy: there is one cache, keyed by
the one content-address, authoritative only through the one witness chain.

**Final — Memo.** Provable, content-addressed (M1) memoization of every SovVal (M5);
hits re-verified against the witness chain (M6), never trusted; XII normal forms
(M7) and solver results (M11) cached; shared across federation (M19) for
consensus-free reuse. *Falsifier:* a hit consumed without chain re-verification; a
stale entry visible to lookup; a key that isn't the value's content-address → red.

## Module 15 — Synthesis (`numera/synthesis_spec.iii`, `symbolic_regression.iii`)

**Today.** Deterministic synthesis: `synthesis_spec` (search for an artifact meeting
a spec) and `symbolic_regression` (recover a closed-form expression). The
non-negotiable: **no statistical learning** — synthesis is exact enumerative /
algebraic search, never gradient fitting or data-driven heuristics (M3/M4).
(`synthesis_search`/`automated_proving` remain spec-only.)

**Pass 1 — first principles.** Synthesis is *search for a morphism satisfying a
spec*. Cast it into the one category (M12): enumerate candidate morphisms between the
spec's source and target Sovereign-Value types (M5/M9 inductives), bounded by cost
(M13), pruned by the decision layer (M11 SMT rejects infeasible candidates), with
equality saturation (M7/M11 egraph) collapsing equivalent candidates — and **verify
the winner with the kernel (M9)**. No ML; the search is exact and the result is
proven.

**Pass 2 — compound.** Synthesis becomes the *generative* face of the whole tower:
it searches the category (M12), measures with the cost lattice (M13) so the
synthesized artifact is **cost-optimal**, prunes with solvers (M11), canonicalizes
with XII (M7), and the output is a **proof-carrying (M16), witnessed (M6), memoized
(M14) Sovereign Value (M5)** — synthesis produces proven, cached, recorded results,
not guesses. `symbolic_regression` recovering a closed form is the same act over the
algebra (Gröbner, M11) rather than terms. Push further: a synthesized artifact, being
a proof-carrying SovVal, is **portable across federation (M19) and re-checkable** —
one node synthesizes, all verify without re-searching. No bad redundancy: synthesis
is not a new engine, it is *guided search in the one category* with the existing
kernel/solvers/cost/egraph as its sub-routines.

**Final — Synthesis.** Deterministic, no-ML search for a cost-optimal (M13) morphism
in the one category (M12) satisfying a spec, pruned by solvers (M11), canonicalized
by XII (M7), kernel-verified (M9); the output a proof-carrying (M16), witnessed (M6),
memoized (M14) SovVal (M5). *Falsifier:* a synthesized artifact that fails kernel
verification; any data-driven/statistical step; a non-deterministic synthesis → red.

## Module 16 — Proof-carrying (`numera/proof_carrying.iii`, `proof_term.iii`, `theorem_carrier.iii`, `curry_howard.iii`)

**Today.** The certificate discipline. `proof_carrying` = Merkle/Keccak256 vector +
polynomial commitments with log-time opening proofs. `proof_term` = the proof-term
representation. `theorem_carrier` = theorems as first-class artifacts (statement +
**verified** proof-term id + content-address + dependency closure; `tc_alloc` refuses
admission unless `pt_verify == 0` and every cited dependency is resident).
`curry_howard` = proof-as-program (M11/M12). All witnessed, NIH.

**Pass 1 — first principles.** Generalize M9 from "the kernel is proof-carrying" to
"**everything is**." Every SovVal (M5) carries a kernel-verified (M9) proof term;
every proven fact is a `theorem_carrier` artifact; Curry–Howard means the proof term
*is* the program, so the compiler (M18) emits programs that are their own proofs.

**Pass 2 — compound.** This closes the trust story for the whole system: the
system's trustworthiness reduces to **re-checking three things — the proof terms
(M9), the certificates (this module), and the witness chain (M6)** — all
content-addressed (M1), all re-verifiable by anyone. It binds the conscience: a
**constitutional clause (M10) may cite a theorem**, and `theorem_carrier`'s rule
("no op cites a theorem without its resident, verified carrier", M18) means the
Constitution's guarantees rest on *proven theorems*, not bare predicates. It binds
synthesis (M15: outputs are proof-carrying) and memo (M14: a cached result carries
its certificate, so a hit is re-checkable). Push further: federation (M19) ships
proof-carrying values, so a peer **verifies a result by re-checking its certificate,
never by trusting the producer** — the deepest form of consensus-free agreement.
No bad redundancy: one certificate discipline (commit + term + theorem + Curry–Howard),
one verifier (the kernel), one record (the chain).

**Final — Proof-carrying.** Every SovVal (M5) carries a kernel-verified (M9),
witnessed (M6), content-addressed (M1) proof term; proven facts are `theorem_carrier`
artifacts the Constitution (M10) may cite; Curry–Howard makes emitted programs (M18)
their own proofs; trust = re-checking term + certificate + chain. *Falsifier:* a
SovVal whose proof term fails kernel verification; a theorem admitted without a
verified carrier; a constitutional clause citing an absent theorem → red.

---

## Module 17 — Representation (`omnia/tp_*.iii` ×~30, `omnia/babel.iii`, `babel_intent.iii`)

**Today.** ~30 transform patterns (`tp_iii_to_asm/pe/c99/md/latex/babel_json/cbor/
ast_bin/x86_disasm/...`), each a FROZEN-SPEC slot, several **lossless 1:1** (e.g.
`iii→asm` embeds the source recoverably). `babel` is the interchange envelope codec
(JSON/CBOR), **mhash-covered with byte-stable lexicographic field order**. Today each
`tp_*` is a standalone converter.

**Pass 1 — first principles.** Each `tp_*` is a **morphism between representations**.
Cast them into the one category (M12): objects = FORMS (III, ASM, PE, C99,
Babel-JSON, CBOR, AST-bin), morphisms = the transforms; a **lossless** transform is
an SID-isomorphism (M8 — its inverse round-trips); Babel is the content-addressed
(M1) **boundary object** to the outside world.

**Pass 2 — compound.** The pipeline becomes a **representation sub-category** (M12):
every transform is a cost-known (M13), witnessed (M6) morphism producing Sovereign
Values (M5) that carry the source's content-address as provenance — so `iii→asm`
*records* what it came from, and lossless ⟹ an M8-verified isomorphism. This unifies
two things above: **the behavioral quine-seal (M9/M10) is a statement about this
sub-category** — it seals the *source* object and the *emitted* object, the two ends
of the compile morphism. And every transform **proof-carries (M16)**: it emits a
certificate that the image is faithful (lossless ⟹ kernel-checkable round-trip).
Push: `xii_emit` (M7) is the `iii→machine-code` morphism, and the compiler (M18) is
the composite morphism in exactly this sub-category. No bad redundancy: the ~30
`tp_*` are not ad-hoc converters but the morphisms of one representation category —
cost-known, witnessed, SID-invertible where lossless.

**Final — Representation.** The `tp_*` pipeline = the morphisms of a representation
sub-category (M12); lossless transforms = SID-isomorphisms (M8); Babel = the
content-addressed (M1) boundary object; each transform a cost-known (M13), witnessed
(M6), proof-carrying (M16) morphism over Sovereign Values (M5); `xii_emit` (M7) and
the compiler (M18) are composites in it. *Falsifier:* a "lossless" transform whose
round-trip ≠ identity; a transform that drops provenance/cost (not a lawful
morphism); a Babel envelope whose mhash doesn't cover its fields → red.

## Module 18 — The Compiler (`COMPILER/BOOT/` lex·parse·ast·sema·cg + the `.iii` self-host port)

**Today.** The bootstrap compiler `iiis-0` is hand-written C (lex → parse → ast →
sema → cg_r0/rm1/rm2/r3 → link) that compiles the 262 sealed `.iii` modules; `sema`
runs gates **D-1..D-12** + `hexad_check`; the in-language self-host port (`sema.iii`
and 18 stage-1 mirror TUs) is in progress; **triple-bit-identity** holds
(iiis-0 ≡ iiis-1 ≡ iiis-2). It is the thing that *makes* III.

**Pass 1 — first principles.** The compiler is the **composite morphism
III-source → PE** in the representation category (M17/M12): lex (text→tokens), parse
(tokens→AST), sema (AST→checked-AST), cg (checked-AST→machine-code). Make the AST
nodes **Sovereign Values** (M5 — each carries hexad/witness/cost/provenance); make
`sema`'s D-gates the **kernel type-check (M9) + constitutional admission (M10)**; make
`cg` the **XII-emit morphism (M7)**, cost-minimal via egraph extraction (M11/M13). The
compiler is not a separate program — it is a composite morphism in the one category.

**Pass 2 — compound.** The deepest self-hosting unification, paying many debts at
once. Complete the `.iii` self-host so the production compiler is **in III** (the
bootstrap C stays the trust root, like `cic.c`) — this is "one language." Then:
**triple-bit-identity *is* the determinism theorem (Π5) + the behavioral quine-seal**
— the compiler proves "I compile myself to identical bytes," an instance fixpoint
(M9/M10, Gödel-safe). `cg` = XII-emit (M7) means **codegen is rewriting to a
cost-minimal machine-code normal form** (M11/M13 superoptimization, sound because the
curated kernels are bit-identical to their rewrite normal forms — M7's clause). Every
emitted `.o` **carries its cic-checked (M9) certificate (M16)**, so the *entire build*
is proof-carrying and witnessed (M6). Push into the body: a compiled module is a
Sovereign Value a peer **re-checks by certificate without recompiling** (M19:
consensus-free build agreement). No bad redundancy: lex/parse/sema/cg are the
morphisms of the compile pipeline (M17); the bootstrap C is the trust anchor (M9-style);
`cg` is `xii_emit` (M7); the self-host completes one language.

**Final — The Compiler.** The composite morphism III-source→PE (M17/M12): lex/parse
build a Sovereign-Value AST (M5), `sema` = kernel-check (M9) + constitutional-admit
(M10, D-gates as clauses), `cg` = cost-minimal XII-emit (M7/M11/M13); triple-bit-
identity = determinism (Π5) + the self-compilation quine-seal; emits proof-carrying
(M16), witnessed (M6) artifacts; bootstrap C is the trust root, the `.iii` self-host
completes one language. *Falsifier:* a build not bit-identical across iiis-0/1/2; an
emitted `.o` whose certificate fails kernel re-check; a `sema` gate that is not a
constitutional clause → red.

## Module 19 — Federation (`aether/hotstuff{,_predict,_heal}.iii`, `fed_*.iii`, `sealed_channel.iii`, `node_identity.iii`, `cap_handshake`, `pattern_set_federation`, `topology_atlas`, `snapshot_lattice`)

**Today.** Deterministic **HotStuff BFT** (3-phase, quorum 2f+1, **leader = view mod
n — no randomness**, view-change on timeout, Ed25519-signed QCs), proven on a 4-node
harness under f=1 Byzantine/leader-failure/reconciliation. `node_identity` derives a
host's three Ed25519 keypairs (identity/comm/witness) + `node id = Keccak256(identity_pub)`
deterministically from a hardware-bound seed + constitutional secret (two hosts never
collide). `fed_*` gate admission (Sybil PoW, eclipse detection, tier, genesis, seal);
`sealed_channel` is X25519+ChaCha20-Poly1305; `topology_atlas`/`snapshot_lattice`
track the mesh.

**Pass 1 — first principles.** Federation is **Sovereign Values crossing node
boundaries**. The first-principles split: because every value is deterministic (Π5),
content-addressed (M1), and proof-carrying (M16), **two nodes computing the same
thing reach the same content-address without exchanging a message** — agreement on
deterministic *results* is free. Consensus (HotStuff) is needed **only to order
nondeterministic *inputs*** (external events). So federation = order the inputs
(BFT) + agree on results by re-checking certificates (M16), never by re-running.

**Pass 2 — compound.** This is the charter's "consensus-free agreement" made precise
*and* a payoff of M12: **federation agreement is a pullback** (two nodes' morphisms
over a shared object meet at their limit — M12), and a **Byzantine node is one whose
values fail certificate re-check (M16)** — structurally excluded, not out-voted. The
whole stack extends across nodes: the witness chain (M6) replicates; the memo lattice
(M14) is shared so a result computed once is re-checkable everywhere (M11); `sealed_
channel` ships SovVals (M5) encrypted; `node_identity` is the node's sovereign self.
Push: a federation is itself a **category** (nodes = objects, messages = morphisms),
so the mesh (`topology_atlas`) is a diagram and a consistent global state is its
limit. No bad redundancy: federation reuses the entire stack across nodes; the two
genuinely-different problems (order nondeterministic inputs vs agree on deterministic
results) get their two distinct mechanisms (HotStuff vs certificate re-check) and
nothing else.

**Final — Federation.** Sovereign Values across nodes: HotStuff (deterministic
leader, 2f+1) orders nondeterministic inputs; deterministic + content-addressed (M1)
+ proof-carrying (M16) results are agreed **consensus-free by certificate re-check**;
agreement = a categorical pullback (M12); `node_identity` the sovereign self; witness
chain (M6) + memo lattice (M14) replicate; Byzantine = certificate-failure =
structural exclusion. *Falsifier:* a deterministic result that needs a vote to agree;
a Byzantine value that passes certificate re-check; non-deterministic leader selection
→ red.

## Module 20 — Immune & Regeneration (`aether/quarantine.iii`, `bone_marrow.iii`, `basal_probe.iii`, `context_awareness.iii`, `triple_check.iii`)

**Today.** `quarantine` is a transactional sandbox over authoritative state — writes
journaled, reads fall through, `q_commit` captures a reversible undo journal,
`q_rollback`/`q_abort` unwind, **every transition witnessed and capability-gated**
(`CAP_RIGHT_AMEND`). `bone_marrow` is a **Reed–Solomon erasure-coded seed archive**
(GF(2⁸), k=8 + r=4), crowned by the W30 seal — a Keccak256 corpus root **verified at
every boot before any module loads** — recovering r losses by Gauss–Jordan over
GF(2⁸); "the substrate's deepest persistent identity," Ring R-2. `basal_probe`/
`context_awareness`/`triple_check` watch health. These are *built*, not spec-staged
(correcting the charter).

**Pass 1 — first principles.** This is the **detection→repair loop** the Constitution
needs. A red verdict (M10) must not merely refuse — it must **contain** (quarantine
the bad transition, which is reversible) and, if state is lost, **regenerate**
(bone_marrow from the erasure-coded seed). Wire it: Constitution-red → quarantine →
(rollback or) bone_marrow regeneration.

**Pass 2 — compound.** The immune system is **not new machinery** — it is M8
(reversibility) + M6 (witness) + M1 (content-address) + M10 (constitution) applied to
the repair loop. `quarantine`'s journaled-reversible-witnessed transition *is* an M8
reversible envelope plus an M6 witness; `bone_marrow`'s W30 boot seal *is* the M1
content-address / M10 closure root verified at boot. So the loop closes with organs
we already have: **M10 detects, M8 contains (reversibly), M1/M6 attest, M20 regenerates**.
Push: a regeneration is itself **proof-carrying (M16)** — the regenerated state must
re-check against the bone-marrow Keccak256 root, so recovery cannot silently restore
a corrupt self. And because the seed is erasure-coded and federated (M19), the marrow
is replicated — the system can regenerate from peers. No bad redundancy: the immune
layer is the constitution's repair arm expressed entirely in reversibility + witness +
content-address; quarantine = containment, bone_marrow = regeneration, two faces of
one loop.

**Final — Immune & Regeneration.** The detection→containment→regeneration loop:
Constitution-red (M10) → `quarantine` (reversible, witnessed containment = M8+M6) →
`bone_marrow` regeneration (erasure-coded seed, boot-verified against its Keccak256
root = M1, proof-carrying restoration = M16), replicated across federation (M19);
health probes (`basal_probe`/`context_awareness`/`triple_check`) feed the verdict.
*Falsifier:* a red verdict with no containment; a regeneration that doesn't re-check
against the marrow root; a quarantine transition that isn't reversible or witnessed
→ red.

## Module 21 — Time (`numera/algebraic_time.iii`, `tempora/{instant,deadline,duration,calendar,rfc3339}.iii`)

**Today.** Two times that don't know their roles differ. `algebraic_time` is the
strictly-monotonic **logical/causal** counter (deterministic, +1 per witness). `tempora/
instant` is **wall-clock** — a sealed monotonic instant (Win32 `GetTickCount64` + epoch
+ cap + a sha256 sealed tag, Phase D → HMAC), the one place III touches the OS clock;
`deadline`/`duration`/`calendar`/`rfc3339` build on it.

**Pass 1 — first principles.** Keep the two times rigorously apart by *role*. Causal
time (algebraic) is the **deterministic substrate** — replayable, the witness chain's
clock. Wall-clock (tempora) is **nondeterministic external input** — so it must enter
only as a sealed, capability-gated, *witnessed* Sovereign Value (M5/M6), never as a
determinism leak, and be ordered by HotStuff (M19) like any external event.

**Pass 2 — compound.** This activates the Constitution's dormant temporal power (M10):
**LTL clauses range over `algebraic_time`** — "the seal is *always* reproducible," "a
red verdict *eventually* quarantines (M20)" — which is sound precisely because
algebraic time is deterministic and replayable (M6/`witness_spine`), and the temporal
clauses are *decided* by a bounded model checker on `sat` (M11), making temporal
guarantees proof-carrying (M16). Meanwhile wall-clock (tempora) is a **quarantined
(M20) external input**, sealed (M1), capability-gated (M8), federated-ordered (M19);
`deadline`/`duration` become **cost-facet (M13) temporal budgets**. No bad redundancy:
two times, two roles — algebraic = deterministic causal substrate (temporal logic +
witness clock); tempora = sealed nondeterministic wall-clock input. Never conflated,
each load-bearing.

**Final — Time.** `algebraic_time` is the deterministic causal substrate for the
Constitution's temporal LTL clauses (M10), decided by bounded model checking (M11)
over the replayable witness chain (M6); `tempora` wall-clock enters only as a sealed
(M1), capability-gated (M8), witnessed (M6), federation-ordered (M19) input;
`deadline`/`duration` are cost-temporal budgets (M13). *Falsifier:* a determinism
path that reads wall-clock; a temporal clause not decided over algebraic time; an
unsealed `instant` → red.

## Module 22 — Memory (`memoria/{region,arena,arena_safe,region_safe}.iii`)

**Today.** Bump arenas over regions (`region_create/alloc/used/release/reset`); arena
1:1 region; the convenience surface most stdlib modules allocate from; `*_safe`
variants add bounds. `kind_substance`, Ring R0.

**Pass 1 — first principles.** **Deterministic bump-allocation is a determinism
requirement, not a convenience** — given a deterministic order, bump gives reproducible
addresses, and a non-deterministic allocator would break the seal (Π5). So the arena
is *the substance* under the Sovereign Value: every SovVal (M5) lives in an arena,
content-addressed (M1), witnessed (M6).

**Pass 2 — compound.** Memory and the witness chain are **dual**: the arena holds the
live values, the chain (M6) holds their provenance; **releasing an arena is a bounded
forgetting** — the complement of witness redaction (M20), so the two forgetting
mechanisms (drop-the-arena vs redact-the-fragment) unify under one accounting. Push:
the `*_safe` variants make allocation **capability-bounded (M8) and cost-aware (M13)**
— a computation cannot allocate past its grant (the K-floor as a memory bound), so
over-budget is refused at allocation, exactly as `sv_op` refuses an over-K composition
(M5). No bad redundancy: memoria is the substance layer; arenas hold SovVals,
deterministic-bump for reproducibility (Π5), capability+cost-bounded (M8/M13) for the
K-floor, dual to the witness chain for forgetting (M20).

**Final — Memory.** The arena is where Sovereign Values (M5) live — deterministic
bump-allocation for reproducible addresses (Π5), content-addressed (M1), witnessed
(M6), capability- and cost-bounded (M8/M13, the K-floor as a memory bound); arena
release is bounded forgetting, dual to witness redaction (M20). *Falsifier:* a
non-deterministic allocation address; an allocation past a capability/cost grant; a
live SovVal with no arena → red.

## Module 23 — Katabasis & CHARIOT (`katabasis/{gate,gate_verdict,cycle_term,cycle_admit,cycle_family,caps,seal}.iii`, the re-forged CHARIOT)

**Today.** The below-OS **gate**: given a sealed cycle TERM it reads family/target/
action and short-circuits in the §4.2 order **seal → cap → hexad → sid**, returning a
verdict (`KG_OK`/`REJECT_SEAL`/`REJECT_CAP`/`REJECT_HEXAD`); proven on metal at Ring 0.
CHARIOT (the harvested kernel/driver system) is being re-forged into 9 cycle families.

**Pass 1 — first principles.** The gate **is the Constitution (M10) at the metal** —
admission of a privileged hardware cycle by seal (M1 + Anchor), capability (M8), hexad
safety (M3), and SID reversibility (M8). Re-found it on the Sovereign Value: a cycle
*is* a SovVal (payload = the privileged op, hexad = its safety, witness = provenance,
cost = resource), so the gate consumes Sovereign Values and **`REJECT_HEXAD` becomes a
type error (M3/M9)** — an inadmissible cycle is *unconstructable*, not runtime-rejected.

**Pass 2 — compound.** This carries the whole tower beneath the OS. The seal check is
M1/M9 — the metal runs the **behavioral quine-seal below the operating system**, so
III attests "I am exactly this source and this executed behavior" at Ring −1/−2, the
charter's deepest payoff: a **self-attesting sovereign base** trustworthy even if
everything above it is compromised. CHARIOT's 9 cycle families are **9 morphism
classes (M12)** in the one category, each gated by the Constitution (M10), each
reversible-or-typed-`Compromise` (M8), each cost-bounded (M13). The gate's verdict is a
witnessed (M6), proof-carrying (M16) Sovereign Value. No bad redundancy: katabasis is
not a separate gate — it is M10 (Constitution) + M5 (Sovereign Value) + M9 (quine-seal)
+ M3/M8 (hexad/SID) applied to privileged cycles at the metal; CHARIOT's families are
morphism classes in the category.

**Final — Katabasis & CHARIOT.** The metal gate is the Constitution (M10) over
Sovereign-Value cycles (M5): seal (M1/M9 below-OS quine-attestation) → cap (M8) →
hexad (M3, `REJECT_HEXAD` = type error) → SID (M8); CHARIOT's 9 families are gated
morphism classes (M12), reversible-or-typed-`Compromise` (M8), cost-bounded (M13),
witnessed + proof-carrying (M6/M16); III becomes a self-attesting sovereign base
beneath the OS. *Falsifier:* an inadmissible cycle that constructs; a metal operation
not gated by the Constitution; a below-OS image whose quine-seal doesn't verify → red.

## Module 24 — The Bloat-Removal Ledger (the C reference tree, dead modules, collisions)

**Today (the bloat, grounded in source).** Per `NOTES/ARCHITECTURE.md`, the **32 R1
subsystem C directories are "parallel reference work"** superseded by the 262 sealed
`.iii` modules. Concretely: **`sha256.c` duplicated 14×** (LEXICON, CATALYST,
CATALYST-EXT, FEDERATION, FOUNDERS-ANCHOR, GENESIS-VECTOR, GHOST-CODE, MODULES,
OBSERVABILITY, PLANETARY, POLYMORPHIC-DATA, SANDBOX, SOVEREIGN-WEB, TRINITY) +
per-subsystem `crypto.c`; `HEXAD/src/hexad_*.c` (the ancestors of `omnia/hexad_*`);
the `omnia/sid.iii` name collision (a dep navigator squatting on SID); `either`/
`checked` duplicated gap handling; the POC's propositional `kernel.iii` (a shadow of
`cic.c`); and spec-only `CONVERGENCE-SPECS` entries with no `.iii` and no consumer.

**Pass 1 — first principles.** Unification *requires* removing the superseded — two
of everything (C ancestor + `.iii` port) is exactly the drift the charter forbids.
But removal must never be reckless: a module is retired **only when its `.iii`
replacement passes the *exact* KAT the original did** (per the standing rule that
only a module's own KAT proves redundancy — a proxy probe does not), the corpus stays
green, and the seal stays stable. Removal is **Constitution-gated (M10)**, witnessed
(M6), byte-equivalence-proven — never assumed.

**Pass 2 — compound.** M24 is the *dual of every prior module*: each enhancement made
a `.iii` organ provably superior to its C ancestor, so this module **retires the
ancestors** — 14× `sha256.c` → one `cad`/`sha256.iii` (M1, Π20-proven); `HEXAD/src/*`
→ `omnia/hexad_*` (M2/M3); `omnia/sid` → `crystal_deps` (M8, collision cleared);
`either`/`checked` → delegate to `uncertainty` (M4); POC `kernel.iii` → `cic.c` (M9).
**Keep the trust roots:** `COMPILER/BOOT` (the bootstrap C) and `TYPES/src/cic.c`
(the kernel, until its `.iii` port lands) — these are M9-style anchors, not bloat.
Prune only *genuine* spec vapor (a `.spec.md` with no `.iii`, no consumer, no
forward-ref); keep any spec with a built module or a mandate. Each deletion is a
witnessed, ratified amendment whose **falsifier is the byte-equivalence KAT**. Result:
**one language** — no C save the bootstrap trust root — *provably* (corpus green +
seal stable + the equivalence KATs). No bad redundancy remains anywhere: removing it
is this module's entire job.

**Final — The Bloat-Removal Ledger.** Retire every C reference module whose `.iii`
port passes the original's *exact* KAT and keeps the corpus green + seal stable
(Constitution-gated M10, witnessed M6, byte-equivalence-proven); collapse the 14×
`sha256.c` → M1, `HEXAD/src` → M3, the `sid` collision → M8, `either`/`checked` → M4,
POC `kernel.iii` → M9; prune spec-only vapor; keep `COMPILER/BOOT` + `cic.c` as trust
roots. *Falsifier:* a removal whose `.iii` port fails the C version's exact KAT; a
deletion that drifts the seal or reddens the corpus; removing a trust root → red.

---

# What III becomes able to do (once M1–M24 land)

Every capability below is grounded in the modules above; nothing today is lost — all
of it becomes *provable*, *intrinsic*, and *systemwide*.

1. **Refuse to ship or run an incoherent self.** The Constitution (M10) is the build's
   terminal gate; nothing goes green unless every guarantee holds *and* its falsifier
   still catches its broken case *and* the seal is stable.
2. **Make catastrophe unsayable, everywhere.** Bricking (M3) and over-budget (M13)
   are not runtime checks but *type errors* on the Sovereign Value (M5/M9) — from a
   single value up through the gate at the metal (M23).
3. **Carry proof in all computation.** Every `.iii` artifact (M18) carries a
   kernel-verified (M9), witnessed (M6) certificate (M16) — III hands anyone a sealed
   value whose every guarantee they recompute.
4. **Compute soundly on the unknown and explain its ignorance.** Typed gaps with
   provenance (M4) keep partial computation sound (M16) and trace every "unknown" to
   named root causes.
5. **Evaluate everything one way, deterministically.** XII (M7) is the single
   confluent, terminating evaluator; any order yields one normal form — determinism is
   a theorem, not a test.
6. **Optimize by cost, provably.** Cost is a value facet (M5/M13) and a functor over
   the category (M12); egraph extraction (M11) yields the cost-minimal morphism —
   sound superoptimization for any target context.
7. **Solve and synthesize with re-checkable proof.** SAT/SMT/Gröbner (M11) and
   synthesis (M15) produce proof-carrying values, never trusted — re-checked by the
   kernel (M9), no statistical learning anywhere.
8. **Forget on demand, with proof.** The witness commons (M6) is append-only *and*
   provably forgettable (redaction with integrity + continuity + blast-radius), with
   arena release (M22) as its dual.
9. **Reason and guarantee over time.** Temporal LTL clauses (M10/M21) over
   deterministic algebraic time, decided by bounded model checking (M11) — liveness
   and safety of III's own evolution.
10. **Agree across nodes without messages; heal when it can't.** Deterministic +
    proof-carrying values agree consensus-free by certificate (M19, a categorical
    pullback M12); HotStuff orders only nondeterministic inputs; a red verdict
    contains and regenerates (M20, from erasure-coded marrow).
11. **Attest its running self beneath the OS.** The behavioral quine-seal at the metal
    gate (M23/M9) proves "I am exactly this source and executed behavior" at Ring −1/−2
    — a self-attesting sovereign base, trustworthy even if everything above is compromised.
12. **Be one language, provably, and be picked up by a stranger.** The C reference
    tree retires (M24) into corpus-green `.iii`; trust collapses to a single green/red
    light anyone can run, audit, and re-seal — III stops being a relic one mind
    vouches for and becomes a transferable, self-proving sovereign foundation.

> The spine, restated now that all 24 are placed: **one language · one currency
> (the Sovereign Value) · one conscience (the Constitution) · one engine (XII) · one
> category (every transform a morphism) · one body (federation, immune, time, memory,
> metal).** Deeper, not wider. Nothing compromised; nothing tacked on; every organ
> made greater by the others and the whole made greater by each.
