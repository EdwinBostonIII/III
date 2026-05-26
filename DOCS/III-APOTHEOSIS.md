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
W-laws); no statistical learning **on any DECIDE/ASSERT path** — permitted ONLY on a
PROPOSE-AND-CHECKED path (the redrawn Prime Directive; the `nous` proposer faculty,
DOCS/III-NOUS-ARCHITECTURE.md §5, ranks candidates the deterministic engine then checks);
monomorphic (kind-tag + `when`, never
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

*Passes 1 & 2 are complete — the whole idealized III is documented (24 architectural
organs + 7 leaf clusters), one body, no module left as a parallel system. **This file
is in canonical reading order:** the module bodies run deepest-first (M1 → M31), each
carrying its per-file depth inline — `M7·D1` (the Horizon & curated kernels) sits under
Module 7, `M17·D1` (the `tp_*` morphism category) under Module 17 — then the "what III
becomes able to do" capstone, then the errata against the charter, then the **Harmony
Invariants** (H1–H13, the enmeshment contract), then the **consistency audit** that
checks every module's final form against them and extracts the seven-step implementation
critical path. Pass 3 (continuing) deepens specifics, nuance, and per-file granularity
**in place** beside the relevant module — never as a tail append. Implementation begins
at Module 1 (the `cad` collapse); every module's final form is implementation-ready.*

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

### Module 1 · Depth D1 — the two address paths and the mechanics of the collapse

**Today (grounded).** The live substrate already runs *two* content-address paths that
disagree on the hash. `numera/content_addr.iii` computes `ca_compute(producer,
operation, input_commit) = Keccak256(producer ‖ operation ‖ input_commit)` and
`ca_compose(left, right) = Keccak256(left ‖ right)` — and its own header declares it
"the single source of content-address Keccak256 in the substrate … no ad-hoc Keccak256
of (producer, operation, input) triples elsewhere" (W36/W50; K=1.00; Ring R0; NIH =
`identifier.iii` + `keccak256.iii`). `sanctus/mhash.iii` (the Crown) addresses through
**SHA-256** with domain separation + streaming `begin/domain/payload/final`. So today the
substrate is single-source *per hash* yet carries two hashes — Keccak-256 for
computation-addressing, SHA-256 for the Crown/seal — which is exactly the duplication the
collapse dissolves.

**The collapse, concretely.** `cad` is one primitive presenting `ca_compute` /
`ca_compose` / Crown-`mhash` as one API over one *address discipline* (canonical byte
order + domain separation), parameterised by a registered `suite ∈ {SHA-256, Keccak-256}`
— the hash becomes a suite tag (M1 agility), never a fork in the call graph. A value's
name is then `(suite, digest)`, so a Q-Day suite swap leaves every prior name verifiable
under its original suite, and `ca_compose` (the `Keccak256(left ‖ right)` Merkle step) is
recognised as the witness chain's link operation (M6) rather than a second hash path.

**A compiler-trap invariant the design must preserve.** `content_addr`'s header records
*why* it does not stream: the gospel's `keccak256_init/update/final` could not be used
because **iiis clobbers parameter registers across the `init()` call** (the documented
param-spill family), so it concatenates the three 32-byte inputs into a bounded 96-byte
scratch (`CA_BUF`) and calls `keccak256_oneshot`. `cad` inherits this as a hard
constraint: its streaming discipline must be spill-safe (oneshot over bounded scratch, or
params copied to locals before the call). The address primitive is shaped by a real
codegen trap, not by taste — and that constraint is itself a falsifiable clause.

**Implementation-agility and address-agility are one discipline.** `sha256_dispatch.iii`
is the concrete realization of the M7·D1 clause "curated kernel ≡ rewrite normal form":
it dispatches SHA-256 between the software path (`sha256.iii`) and a SHA-NI fast path
(`SHA256RNDS2` / `SHA256MSG1` / `SHA256MSG2`) chosen by `cpufeat_has_sha()`, attaching a
`@dynamic_impact(perf, ux)` provenance crystal when the fast path activates — **the output
is bit-identical across paths; only the cost facet (M13) changes.** This is
determinism-safe because the path is a function of *sealed hardware capability*, not
observed workload (never the forbidden adaptive trigger — III's no-statistical-learning
tenet), and the two paths are output-equal. So "which hash" (address agility) and "which
kernel" (implementation agility) are the same move: a tagged choice that never alters the
value, only its suite or its cost. *Falsifier:* two address paths disagreeing on the
digest of one canonical input; a `cad` suite or a `sha256_dispatch` path that changes the
output rather than only the cost; any Keccak/SHA of a `(producer, operation, input)`
triple computed outside `cad`; a streaming address call that reads a spilled param slot
→ red.

**Key moves.** The move is *to name a value* — `ca_compute`/`ca_compose` (`bytes → (suite,digest)`); the illegal move is two canonical inputs sharing a digest.

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

### Module 2 · Depth D1 — the five total ops, by table

**Today (read).** `omnia/hexad_algebra.iii` (trit layer): `iii_trit_not` (NEG↔POS, ZERO→ZERO
= `-a`), `iii_trit_and` (NEG dominates; POS iff both POS), `iii_trit_or` (POS dominates; NEG
iff both NEG), `iii_trit_sum` (NEG-biased clamped add = `clamp(a+b,-1,+1)`), `iii_trit_mul`
(NEG·NEG=POS, ZERO annihilator, = `a·b`), plus the **asymmetric `iii_trit_weight` (NEG = -2)**
so one unit of damage outweighs one of recovery, and the `iii_trit_valid` guard. All compared
by equality only (the i64-ordering SIGSEGV trap). Five total ops over a three-element domain.

**The unification.** Each op becomes one XII rewrite rule (M7), so the algebra's laws — De
Morgan, double-negation-as-recovery (`mul(NEG,NEG)=POS`), the SUM clamp — are **Knuth–Bendix
confluence-checked** by `xii_critpairs`, not merely unit-tested, and they are exactly the
`Trit` CIC inductive's eliminator (M9·D1). The `weight` asymmetry is the seed of the hexad's
structural-pillar dominance (M3·D1, AND on pillars 1..4) and of the cost lattice's
catastrophe-bias (M13); the gap (M4) is this same algebra read with `ZERO` = unknown — one
algebra, two arities, never two. *Falsifier:* an `iii_trit_sum` that doesn't clamp to
[-1,+1]; an `iii_trit_mul` where ZERO fails to annihilate; a `weight` not NEG = -2; any
ordering (`<`/`>`) compare on a trit → red.

**Key moves.** The move is *to combine safety/uncertainty* — the five trit ops as XII rules (`Trit×Trit → Trit`); the illegal move disagrees with its spec table.

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

### Module 3 · Depth D1 — why exactly 144 of 729, and the compose arithmetic

**Today (read).** `omnia/hexad_algebra.iii`: a hexad is **6 trits packed base-3
(little-endian by pillar) into a u16, range 0..728** (`HXA_HEXAD_MAX = 729 = 3⁶`);
`iii_hexad_pack6` packs six `i32 ∈ {-1,0,+1}`, `iii_hexad_pillar(h,p)` reads pillar `p`,
`iii_hexad_compose6(a,b)` composes. The composition is asymmetric by design: **AND on the
four *structural* pillars (idx 0..3)** — `NEG` dominates, `POS` iff both `POS` — and **OR on
the two *recovery* pillars (idx 4..5)** — `POS` dominates, `NEG` iff both `NEG`. Structural
damage propagates (catastrophe is sticky); recovery accrues.

**Why exactly 144/729 — the arithmetic, not the assertion.** `reach` admits a hexad iff **no
structural pillar is `NEG`** — i.e. pillars 1..4 each ∈ {`ZERO`,`POS`} (2 choices) while the
two recovery pillars range freely (3 choices): **2⁴ × 3² = 16 × 9 = 144** of 729. The other
585 hexads are *unrepresentable* — and `pfs` proves the six bricking firmware ops land among
them, so they are unconstructable. This is the precise sense of "catastrophe is unsayable":
not forbidden by a check, but *absent from the type's inhabitants*.

**The unifications.** This is six instances of M2 (so `compose6`'s AND/OR are the M2 trit
ops, XII-evaluated and confluence-checked, M7), and it is the `Hexad` CIC inductive of M9·D1
(one ctor of arity 6 over `Trit`) — so making `reach` a *type* means binding the runtime
`iii_hexad_packed_admitted` (the M18 `TYPE-HEXAD-002` gate) to that inductive, whereupon a
non-reachable composition fails `ι`-reduction rather than a bitmap lookup. `epistemic` ⊂ the
gap (M4), `mobius` ⊂ SID (M8), `dynamic` promotion ⊂ the Constitution (M10). The C ancestors
in `HEXAD/src/*.c` retire (M24) once the `.iii` ports pass their exact KATs. *Falsifier:* a
constructable value whose composed hexad is one of the 585 non-reachable patterns; a
`compose6` disagreeing with AND-on-1..4 / OR-on-5..6; a bricking op that types → red.

**Key moves.** The move is *to compose safety* — `iii_hexad_compose6` (`Hexad×Hexad → Hexad | Refused`); the illegal move yields a non-reachable hexad that still constructs.

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

### Module 4 · Depth D1 — the three handlings the one gap absorbs

**Today (read).** Partial information is handled three incompatible ways: `omnia/either.iii`
(a `left`/`right` disjunction), `numera/checked.iii` (overflow-checked arithmetic returning
`option_u32`/`option_u64` with `did_overflow` predicates), and `hexad_epistemic` (a
confidence pillar). None is the single typed gap the charter needs; the POC's `negknow.py`
proved the unifying shape — one `PGap` carrying `kind`, `reason`, and an `antecedents`
provenance DAG.

**The unification.** One typed gap `Gap{ kind ∈ {essential, hole:NAME, redacted, derived},
reason, antecedents }`, the **`ZERO`-inhabited reading of the M2 ternary algebra** — not a new
algebra, just M2 applied to payloads. Its arithmetic is **total, sound, and maximally
precise**: `÷0 → gap`; the hardest-won POC invariant `0 · unknown → Known(0)` (sound *and*
precise — zero annihilates even an unknown). `either`/`checked`/`epistemic` keep their public
APIs but **delegate** to this one gap; their duplicated handling is deleted (M24). The
provenance DAG is a **first-class negative-knowledge value** — "unknown *because* sensor_3 is
an essential-gap, via X→Y→Z" — content-addressed (M1) and walkable to named root causes, so
III reasons about *what it does not know* as rigorously as what it does. This lifts the tower:
a gap is a SovVal payload (M5); a redacted witness fragment becomes a `redacted` gap (M6/M20);
a proof may be *partial* and stay sound (M16); the kernel treats it as an **open term**
(M9·D1). *Falsifier:* an operation that raises instead of returning a gap; a wrong concrete
for an unknown input (`0 · unknown ≠ Known(0)`, or `÷0` not a gap); a derived gap with empty
provenance → red.

**Key moves.** The move is *to compute on the unknown* — the gap arithmetic (`Gap-carrying op → Gap | Known`); the illegal move returns `0·unknown ≠ Known(0)` or raises on `÷0`.

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

### Module 5 · Depth D1 — the language support the currency needs

**Where it stands.** The Sovereign Value is net-new, but its two language hooks are not
invented from nothing. `@variant` is already a **corpus-tested modifier**
(`STDLIB/corpus/110_modifier_variant.iii`), so the tagged union `payload : Known | Gap` has
a real codegen precedent; `@sovereign` is the genuinely new one (it lives only in the
charter and this file today). The POC's `sovval.py` proved the *shape* —
`{payload, hexad, witness, cost}` with one total `sv_op` composing all four facets and
returning `Refused` on a non-reachable hexad or an over-K cost.

**`@variant` — exhaustiveness as a gate.** `payload` is a CIC sum (M9): `Known(Term) |
Gap(GapKind, provenance)`. The compiler lowers `@variant` to a tagged union with a
**match-exhaustiveness D-gate** — an inexhaustive match is `III_VARIANT_NONEXHAUSTIVE`,
proved by a negative corpus case (a deliberately non-exhaustive match that *must* fail to
compile). It stays monomorphic (kind-tag + `when`, never fn-pointer dispatch), so it obeys
the dispatch tenet.

**`@sovereign fn` — the boundary checker, and the systemwide lift.** `@sovereign` asserts a
function trades only Sovereign Values across its boundary; `sema` rejects a `@sovereign`
boundary carrying a raw `u64`/pointer with `III_NONSOVEREIGN_BOUNDARY`. This is
**critical-path item (3)** and the truest measure of "systemwide": today stdlib boundaries
pass raw scalars, so the checker is built first (one new negative test), then boundaries are
migrated cluster by cluster until H1 ("every boundary value is a SovVal") holds everywhere.
It plugs into the *existing* compile-time hexad gate — `sema` already emits
**`TYPE-HEXAD-002` (hexad unrepresentable)** and **`TYPE-HEXAD-001` (hexad missing on
cycle)** via `iii_hexad_packed_admitted`, so the reach check (M3) is *already* a D-gate;
`@sovereign` extends that machinery from cycles to every boundary value.

**`sv_op` is one categorical morphism.** Composition routes through XII (M7), so `sv_op`'s
associativity is an XII confluence fact, registered in M12 with `cat_check_assoc` and made a
constitutional clause (M10) — never assumed. *Falsifier:* a `@variant` match that compiles
non-exhaustively; a `@sovereign` boundary that admits a raw value; an `sv_op` whose
associativity fails `cat_check_assoc`; a constructed SovVal with a non-reachable hexad or
over-K cost that is not `Refused` → red.

**Key moves.** `sv_op` is the **generating move** (the archetype, not an identity arrow) — every Sovereign morphism in every other module specializes it (`SovVal × SovVal → SovVal | Refused`); the illegal move is a composition that escapes `Refused` on a non-reachable hexad or over-K cost.

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

### Module 6 · Depth D1 — one chain: hook, spine, clock, at gospel scale

**Today (read).** Three files, one organ. `aether/witness_hook.iii`: `wh_publish`
validates, computes `frag_id = Keccak256(all fields)`, advances algebraic time, appends to
the in-epoch log, and returns the fragment index; `wh_revoke` *marks* revoked (append-only,
never deletes). Scale is gospel, not down-sized: **`WH_MAX_FRAGMENTS = 1_048_576`** (1 M
fragments). `numera/witness_spine.iii` is the master DAG — a `frag_id → index` hash table +
**per-pillar / per-producer / per-operation reverse indices** + a **per-epoch root store** +
a **from-seed chain-replay verifier**. `numera/algebraic_time.iii` (Layer 0, Module 03) is a
strictly-monotonic `u64` advanced **+1 per published fragment by `at_advance`, which only
`witness_hook` may call** — causal order is sealed to publication.

**The unifications, concretely.** `frag_id = Keccak256(producer ‖ opid ‖ in/out_commit ‖
at_time ‖ …)` routes through `cad` after the M1 collapse, so the whole 1 M-fragment history is
suite-tagged → Q-Day-immune (M1's largest consumer). **One subtlety the build proved (bug #6):
because the chain fid embeds `at_time` (monotonic — each publication is unique), it is *not*
reproducible; re-publishing the same payload yields a different fid.** A move's *reproducible*
witness (the M10 re-derivation the Move contract demands) must therefore key on the
**content-address of the payload alone, `at_time` excluded** — `cg_bisimulate` was fixed to
derive its verifiable witness via `ident_from_bytes(payload)`, not the stamped fid, or
`ba_verify_bisimulation`'s byte-match could never succeed. The chain id is for *ordering*; the
content-address is for *re-verification*. The spine's per-pillar reverse index carries each
fragment's hexad
pillar (M3) — provenance is *typed*. The append-only-vs-forgettable tension dissolves via
**`witness_spine.redact(frag, reason)`**: replace the payload with a `redacted` gap (M4),
re-seal, and *prove* integrity (chain still replays from seed) ∧ continuity (independent
fragments byte-identical) ∧ blast-radius (dependents become honest gaps citing the
redaction). Because `at_advance` is the sole monotone clock, the replay verifier is a total
function of the seed — replay *is* determinism (Π5) made auditable. The `witness` facet of a
SovVal (M5) **is** this `frag_id`, so producing a value and recording it are one act; M10
ratifies clauses *as* fragments (`CLAUSE_RATIFICATION`); M21 *is* `algebraic_time`; M8's
derived inverse rides each fragment for backward replay. *Falsifier:* a SovVal with no
`frag_id`; a chain that fails from-seed replay; an `at_advance` called from outside
`witness_hook`; a redaction that breaks continuity → red.

**Key moves.** The move is *to record provenance* — `wh_publish` (`value → FragId`); the illegal move mints a value with no fragment.

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

### Module 7 · Depth D1 — the Horizon & Curated Kernels (`omnia/xii_horizon.iii`, `xii_curated_{crypto,payloads,arm64_crypto,riscv,extended,...}.iii`)

**Today.** `xii_horizon` is **144 sealed Horizon patterns** — H001–024 crypto hot
paths, H025–042 arithmetic, H043–060 memory-bound, H061–072 capability-checked,
H073–084 witness/provenance, H085–096 governance, H097–108 codegen-meta, H109–120
resolver-self, H121–126 hexad/trit (126 productive) + 12 guard + 6 reserved = 144.
**Each pattern carries metadata: hexad, primary_op, K-cost, cap_class, ct_kind
(constant-time class), prov_xform_id, productive flag** + a structural template that
`xii_horizon_construct(id)` walks to the canonical algebra term. `xii_curated_*` hold
the **per-ISA machine-code realizations** (x86_avx2, arm64_neon) — real sealed bytes,
constant-time-safe where `ct_kind > 0` (e.g. H005 poly1305 via PCLMULQDQ, H007 aes_gcm
via AES-NI). Registration is `xii_emit_gen_override(horizon_id, target, payload, size)`,
and a single pattern is curated for *multiple* ISAs — `H003 chacha20_block` ships both an
x86_avx2 sequence (`vpaddd`/`vpxor`/`vpsrldq`) and an arm64_neon sequence (`add.4s`/
`eor.16b`) — concrete proof of one canonical term with many per-target normal forms.

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

**Key moves.** The move is *to evaluate* — `xii_rewrite` apply (`Term → Term`); the illegal move drives a term to two distinct normal forms.

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

### Module 8 · Depth D1 — three mechanisms, one inverse, and the collision the source flags

**Today (read).** Reversibility is three files that don't yet know they're one. (1)
`COMPILER/BOOT/sid.iii` — the **Side-effect Inverse Derivation** port of `sid.c`, mirroring
the `sid.h` ABI (Ring R-2/R-1), with `iii_sid_state_t` collapsed to module-singleton state
(`iii_sid_create` returns a sentinel; every entry ignores its `s` arg — the W13/spill
discipline). It *derives* an op's inverse at compile/rewrite time. (2) `numera/reversible.iii`
— runtime transactional reversibility: **a strict LIFO stack of capability-scoped
envelopes**; commit persists forward effects and truncates the undo log; rollback replays
**each undo in reverse and is witnessed**; an undo record is `u32 tag + four u64 args
(a,b,c,d)`. (3) `hexad_mobius` gives the safety lattice its inverses. And the collision is
real and *self-flagged*: `omnia/sid.iii`'s own header declares it the "Crystal-ID dependency
graph navigator … **NOT to be confused with `COMPILER/BOOT/sid.iii`**" — two unrelated things
squatting on "sid."

**The unification.** One inverse concept: BOOT-`sid` *derives* it, the witness chain (M6)
*records* the forward op with its derived inverse, and rollback is replaying the chain
backward — so `reversible.iii`'s LIFO envelopes are recognised as **views over witness-chain
segments**, not a separate undo log, and reversible time-travel costs no extra log (the
inverse is derived, not stored). The `(tag, a, b, c, d)` undo record *is* a backward witness
fragment. `hexad_mobius`'s inverse **is** the SID inverse projected onto the safety lattice
(M3 — paid here). The Constitution (M10) then classifies every op as **reversible** (derived
inverse round-trips), **typed-irreversible** (`Compromise<LOW|MEDIUM>` per the EFFECTS spec
— the `COP_REVTAG_EQ` opcode reads exactly this tag), or **unrepresentable**
(`Compromise<HIGH>` = bricking, M3 `reach` forbids construction). Step zero is to clear the
collision: `omnia/sid.iii` → `omnia/crystal_deps.iii`. *Falsifier:* a forward op whose
derived inverse fails to round-trip; an irreversible op with no `Compromise` tier; a
`Compromise<HIGH>` value that constructs; the name `sid` still bound to two modules → red.

**Key moves.** The move is *to reverse* — inverse-derivation + `q_rollback` (`Op → Op⁻¹`); the illegal move's inverse fails to round-trip.

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

### Module 9 · Depth D1 — what `cic.c` already proves, constructor by constructor

**Today (888 lines, read).** `TYPES/src/cic.c` is de-Bruijn-indexed CIC: `iii_term_lift`
shifts indices under binders; `iii_term_whreduce` is weak-head reduction (**β** by
substitution, **ι** by match-on-constructor, **δ** by `let`/definition unfold, **ζ** for
`let`); `iii_term_eta_eq` decides conversion by whnf-ing both sides, comparing
structurally, and recursing under `Lam`/`Pi` with **η**-expansion. The universe is **seven
levels**, **predicative Π for sorts < Type₆** and **impredicative at Type₆** — so there is
no `Type : Type`, the Girard paradox is excluded, and that exclusion is the kernel's third
consistency pillar (the one the charter wrongly called missing).

**The seven inductives, with their exact constructors** (the part the charter missed):
`Bool`; **`Trit : Type₀` with ctors `NEG`/`ZERO`/`POS`** (= M2); **`Hexad : Type₀` with one
constructor of arity 6** — a `Hexad` term is literally `hexad(t₁ … t₆)` over six `Trit`s
(= M3 built on M2, *inside the kernel*); **`Phase : Type₀` with ctors
`R-2`/`R-1`/`R0`/`R3`** (= the katabasis ring lattice, M23); **`Tier : Type₀` with ctors
`transient`/`host_file`/`federation`/`constitutional`** (= the witness/compromise tier
ladder, M6/M8); `Epoch` wrapping a `u64` (= algebraic time, M21); and `List`. A malformed
inductive is rejected with `TYPE_PROOF_007_BAD_INDUCTIVE`.

**Why this is the keystone.** Three of III's core ontologies are *already* CIC inductives —
the safety algebra (`Trit`/`Hexad`), the ring lattice (`Phase`), and the tier ladder
(`Tier`). "Make safety a type" is therefore not a distant frontier; the kernel types it
today. What remains is to bind the runtime hexad (M3 `reach`) to the `Hexad` inductive so a
non-reachable composition is rejected by `ι`-reduction rather than a bitmap. The Pass-2
SovVal move is then exact: add a dependent record `SovVal { payload : Term, hexad : Hexad,
witness : FragId, cost : Cost }` (or an eighth inductive) whose **reachability and K-floor
are Π-typed refinements** over the existing `Hexad` and a `Cost` inductive — `sv_op`'s
refusal of a bricking/over-budget composition becomes `iii_term_typecheck` returning
`TYPE_PROOF_007_*`, and a gap (M4) is an *open term* (a metavariable) the kernel already
elaborates. The POC's propositional `kernel.iii` is a shadow of this and is retired (M24);
`cic.c` stays the C trust root until `numera/kernel.iii` ports it (the honest H13
completion). *Falsifier:* a closed inhabitant of ⊥; a `Hexad` term accepted whose six trits
compose to a non-reachable pattern; a `Type : Type` acceptance; a SovVal record that
type-checks under an over-K `Cost` refinement → red.

**Key moves.** The move is *to admit a proof* — `iii_term_typecheck` (`Term → Type | ⊥`); the illegal move type-checks a closed inhabitant of ⊥.

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

### Module 10 · Depth D1 — the admissibility VM, and where the falsifier and LTL plug in

**Today (851 lines, read).** A clause is a first-class object: textual statement, LTL
formula, an admissibility-predicate **bytecode**, a witness-production rule, dependencies,
and an effective epoch; `clause_id = Keccak256(textual)` (→ `cad` after the M1 collapse).
Ratification publishes a `CLAUSE_RATIFICATION` witness fragment (M6) on the Part VII
`clause_payload` schema (`clause_id(32) | textual_len(u16) | textual | ltl_len(u32) | ltl |
…`). Bounds are gospel: **`CONS_MAX_CLAUSES = 1024`** (W8), a **1 MiB `CONS_LTL_BUF`**, slot
tables sized `[;1024]`; evaluation is **non-reentrant** over module-scope context (the
W13/param-spill discipline — `cons_eval_predicate` sets `CONS_EV_*` before its dispatch
loop).

**The 11-opcode admissibility VM — and the deep fact about it.** Five boolean combinators —
`COP_TRUE 0x01`, `COP_FALSE 0x02`, `COP_AND 0x03`, `COP_OR 0x04`, `COP_NOT 0x05` — over six
predicates that read a witness fragment: `COP_PRODUCER_EQ`, `COP_OP_EQ` (provenance, M6),
`COP_REVTAG_EQ` (reversibility tag, M8), `COP_PHASE_GE` (ring precedence over the bounded
`Phase` domain, M23/M9), `COP_PILLAR_EQ lo hi` (a **hexad pillar-range** test — `reach` in
opcode form, M3), and `COP_HAS_ANTE` (antecedent presence, M6). **The crucial observation:
every predicate reads exactly a Sovereign-Value facet** — provenance, reversibility, ring,
hexad, antecedent. The Constitution already speaks the SovVal's language; that is *why* M5
and M10 lock together, and why making the SovVal the clause's input type is a unification,
not a bolt-on.

**Where the two gaps plug in.** (a) *Falsifier.* Today a clause has no paired negation — the
VM verifies but does not falsify. Add a second bytecode field (the same 11 opcodes) to the
`clause_payload` schema; then `HOLDS = cons_eval_predicate(verify, w) ∧
cons_eval_predicate(falsify, w_bad)` — the clause must *catch* a constructed bad witness,
not merely pass a good one (the POC's whole discipline, and the standing "prove the
negative" rule). (b) *LTL.* The evaluator now exists — **`numera/temporal_logic.iii` is built
(`tl_eval` over a witness-chain window), and `constitution_preserver` already drives it** — but
the `ltl` / `CONS_LTL_BUF` field per clause is **not yet folded into the gate**. `run_charter()`
closes that gap by compiling each temporal clause to a bounded model-checking query
(`tl_eval` / `sat`, M11) over the replayable `algebraic_time` chain (M21) — "the seal is
*always* reproducible," "a red verdict *eventually* quarantines (M20)." `run_charter()` then
fuses the positive corpus + `NNN_neg_*` falsifiers + drift gates + closure meta-gate into
one sealed verdict vector and is the build's terminal gate. *Falsifier:* a clause with no
falsifier bytecode; a `falsify` predicate that passes on its bad witness; an LTL field that
never reaches the model checker; a `run_charter` green under injected corruption → red.

**Key moves.** The move is *to judge* — `cons_eval_predicate` + `run_charter` (`Witness → Verdict`); the illegal move returns green under injected corruption.

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

### Module 11 · Depth D1 — determinism inside the solvers, and egraph-as-XII-strategy

**Today (read).** `sat.iii` (661 lines) is CDCL with **two-watched literals**, **1UIP**
conflict analysis, **non-chronological backjumping**, and clause learning — and its
determinism is *structural*: a **fixed static decision order**, **no restarts, no
randomness, no clause deletion, no learned-from-data heuristic** (the counters
`sat_n_decisions`/`sat_n_conflicts`/`sat_n_learned` exist for audit only). `smt.iii` (2107
lines) is DPLL(T) over two convex theories — **LIA** (exact-rational **Bland's-rule
simplex** + branch-and-bound in a `±2²⁰` box, ≤256 vars / ≤1024 constraints) and **BV**
(1..64-bit, **bit-blasted into `sat`**) — combined by **Nelson–Oppen** equality exchange
over shared integer vars, and **`smt_check_model` re-verifies every SAT model**.
`egraph.iii` is **bounded equality saturation + minimum-cost extraction** on union-find +
open-addressed hashcons, **no recursion** (W15: the matcher/instantiator use explicit
stacks).

**The two unifications, made precise.** (1) *H10 is already real here, not aspirational:*
`smt_check_model` **is** the re-check discipline — a model is a certificate the kernel and
Constitution re-verify, never trust; the solver is an untrusted oracle. (2) *`egraph` is
XII (M7) under a second strategy over one rule set:* XII canonicalisation = confluent
rewriting to a single normal form (determinism, M5/M7); egraph = apply *all* rewrites, keep
every equal form compactly, then extract the **cost-minimal** representative (M13). Same 40
sealed rules + curated kernels; two read-outs. So "superoptimization" is not a separate
optimizer — it is min-cost extraction over the egraph of XII's own rules, and the
**coequalizer of M12 is exactly an egraph equality class**. The kernel (M9) and
Constitution (M10) dispatch decidable goals to these oracles and re-check the returned
certificate; a result proven on one node is re-checked (not re-solved) on every other
(M19). *Falsifier:* a solver result consumed without `*_check_model`; any non-determinism
(a restart, a randomized phase, a data-derived heuristic) in a solve; an egraph extraction
that is not cost-minimal or disagrees with an XII normal form on an equality → red.

**Key moves.** The move is *to decide* — `smt_check_model`/`sat`/`groebner` (`Goal → Certificate`); the illegal move's certificate is consumed without re-check.

---

## Module 12 — Category (`numera/category.iii`)

**Today.** A real finite-category engine: objects (32-byte ids) and morphisms in
slot tables, with composition, identities, the **associativity law** (`cat_check_assoc`
proves `(h∘g)∘f = h∘(g∘f)`), and the universal constructions **pullback, pushout,
coequalizer**. Morphism id = `Keccak256(src ++ dst ++ op)`; **composition concatenates
op-words** (`w(f∘g) = w(f) ‖ w(g)`) — associative *by construction*, since a nested
`Keccak256(f_id ‖ g_id)` would encode the bracketing and is **not** associative (a real
`category.iii` bug, fixed); composite uniqueness is a deterministic function of inputs.
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

### Module 12 · Depth D1 — objects, morphisms, and the universal constructions by hash

**Today (read).** `numera/category.iii`: finite categories as fixed slot tables — **objects =
32-byte ids**, **morphism id = `Keccak256(src_id ‖ dst_id ‖ op)`**, **composition = op-word
concatenation** (`w(f) ‖ w(g)` — the flat primitive-op sequence, *associative by
construction*; the tempting `Keccak256(f_id ‖ g_id)` is a binary tree that encodes the
bracketing and is **not** associative — a real bug `category.iii` fixed), **identity op =
`Keccak256(obj_id ‖ "id")`** — so composite uniqueness is a deterministic function of inputs
(no fresh-name allocation). It implements
**composition, identities, the associativity law (`cat_check_assoc`), and the universal
constructions pullback / pushout / coequalizer**; API `cat_add_object` / `cat_add_morphism` /
`cat_morphism_src` / `_dst` / `cat_find_*`.

**The unification.** Because morphism ids are `Keccak256`, they route through `cad` after the
M1 collapse — **the very shape of computation is content-addressed**. The universal
constructions are the spine's unifiers made concrete: **coequalizer = an egraph equality class
(M11·D1)**, **pullback = federation agreement (M19·D1)**, the **`tp_*` pipeline = a
sub-category (M17·D1)**. `sv_op`'s associativity (M5) *is* `cat_check_assoc`, ratified as a
constitutional clause (M10) rather than assumed; cost is a **functor to the lattice
(M13·D1)**. So XII (composition), egraph (coequalizer) and federation (pullback) are three
*named constructions in one category*, not three algebras. *Falsifier:* a composite whose
op-word ≠ `w(f) ‖ w(g)` (or a nested-hash composite that re-encodes bracketing); a
composition that breaks `cat_check_assoc`; a claimed
pullback/coequalizer that isn't the universal one for its diagram → red.

**Key moves.** The move is *to register a move* (the meta-move) — `cat_add_morphism` + `cat_check_assoc`; the illegal move is a composite that breaks associativity.

---

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

### Module 13 · Depth D1 — the six dimensions, the two orders, and cost-as-facet

**Today (read).** `numera/cost_lattice.iii` is a bounded partial-order lattice over **six-dim
microarch cost vectors**: `c[0]` latency, `c[1]` throughput, `c[2]` register pressure, `c[3]`
icache footprint, `c[4]` dcache footprint, `c[5]` energy. Two layers: (1) **scalarizing
orders** — a `u64` weight vector induces a total preorder via saturating dot product; (2) the
**intrinsic product lattice** — `meet` = per-dim min (glb), `join` = per-dim max (lub),
`⊥` = 0-vector, `⊤` = MAX-vector. Four standard orders ship with exact weights: **`server`
(1,4,1,1,1,0)**, **`realtime` (8,1,1,2,2,0)**, **`lowpower` (2,1,1,1,1,8)**, **`balanced`
(2,2,1,1,1,1)**; orders are **immutable once registered**. Pure — no externs, no alloc, no
FP, no recursion.

**The unification: cost is the fourth SovVal facet.** `sv_op` **joins** costs by the lattice
`lub`, so a composite's cost is the join of its parts and the K-floor / "physics-boundary-only
cost" mandate is a lattice constraint — an over-budget composition is `Refused` exactly like a
bricking hexad (M5/M9: an over-K `Cost` refinement is a *type error*). This binds the engine:
**egraph min-cost extraction (M11) minimizes over this lattice** → the cost-optimal morphism
(superopt), and **XII's curated kernels (M7) are lattice-minimal rewrites** — M7/M11/M13 are
one optimization, not three. It is a **functor M12 → lattice** (every morphism has a cost;
composite cost = join). And the four scalarizing orders are **deployment contexts**: the
*same* SovVal extracts to a *different* cost-optimal machine form per target (M17 → asm/PE,
M18 `cg`) — `sha256_dispatch`'s software-vs-SHA-NI choice (M1·D1) is exactly this, the cost
facet changing while the value does not. *Falsifier:* a composite cost that isn't the
lattice-join of its parts; an over-K value that constructs; an "optimal" extraction that isn't
lattice-minimal under the active order → red.

**Key moves.** The move is *to account cost* — the lattice `join` (`Cost×Cost → Cost`); the illegal move's composite cost isn't the join of its parts.

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

### Module 14 · Depth D1 — soundness over speed: the re-check that makes a cache safe

**Today (read).** `numera/memo_lattice.iii`: **32-byte content-address keys** (from
`content_addr.iii`, M1) → **`(output_commitment, chain_id)` values with a per-entry `K_memo`
confidence**. Its load-bearing discipline is in the header verbatim: **admission verifies the
producing chain (`ws_lookup_id`) BEFORE insertion**; **`ml_lookup` returning `MEMOL_OK` means
"present, not stale," NOT "trusted" — the caller MUST call `ws_lookup_id(out_chain_id)` and
get OK before consuming**; **a stale entry is invisible to lookup**; and **`ml_revalidate`
replays the chain before clearing the stale mark (no un-stale without reval)**.

**The unification.** This is H10 (nothing-trusted) made operational at the cache layer —
*exemplary*, and already real in source: a hit is a re-checkable pointer into the witness
chain (M6), never an authority. Determinism (Π5) + content-addressing (M1) make the cache
*correct by construction* — same input, same address, same output — so memoization is a free
systemwide property: XII normal forms (M7) and solver certificates (M11·D1) are cached and
re-checked, never re-trusted. Federation (M19) **shares** the lattice: a result computed once
is a re-checkable entry for every peer (consensus-free reuse). *Falsifier:* a hit consumed
without the mandated `ws_lookup_id` re-verification; a stale entry visible to `ml_lookup`; an
un-stale without an `ml_revalidate` replay; a key that isn't the value's `cad` → red.

**Key moves.** The move is *to reuse* — `ml_lookup`/`ml_revalidate` (`Key → (commitment, chain)`); the illegal move consumes a hit without `ws_lookup_id`.

---

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

### Module 15 · Depth D1 — the spec language and the search that builds on it

**Today (read).** `numera/synthesis_spec.iii` is the **canonical specification language** for
synthesis problems — bounded at `SYNSPEC_SLOTS = 128` live specs and `SYNSPEC_MAX_CONSTRAINTS
= 32` predicates per spec (W8) — that **`synthesis_search` (module 63) and `synthesis_witness`
(64) build upon**; `symbolic_regression` recovers a closed-form expression. The non-negotiable
is in the source: **no statistical learning** — exact enumerative / algebraic search, never
gradient fitting.

**The unification.** A spec is a `{source-type, target-type, constraints}` triple over
Sovereign-Value types (M5/M9 inductives), so synthesis is **search for a morphism in the one
category (M12)**: enumerate candidate morphisms, prune infeasible ones with the decision layer
(M11 SMT), collapse equivalents with the egraph (M7/M11), measure with the cost lattice so the
winner is **cost-optimal (M13)**, and **verify it with the kernel (M9)**. The output is a
proof-carrying (M16), witnessed (M6), memoized (M14) SovVal — a *proven, cached, recorded*
artifact, portable across federation (M19: one node synthesizes, all verify without
re-searching). `symbolic_regression` is the same act over the algebra (Gröbner, M11).
*Falsifier:* a synthesized artifact that fails kernel verification (M9); any data-driven step;
a spec exceeding 128 slots / 32 constraints that isn't refused; a non-deterministic synthesis
→ red.

**Key moves.** The move is *to build a move* — `synthesis_search` (`Spec → proven morphism`); the illegal move emits an artifact that fails kernel verification.

---

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

### Module 16 · Depth D1 — the certificate machinery: Merkle + polynomial, log-time

**Today (read).** `numera/proof_carrying.iii`: **vector and polynomial commitments, all Merkle
(Keccak256) based, every opening proof verifying in deterministic time bounded by log of the
committed length** (`PROOFC_LAYER` = 1024 × 32 current Merkle layer; `PROOFC_LEAVES` the
coefficient leaves; `pc_pair_commute` an order-independent pairing; `pc_collapse_one` folds a
layer by one level). `numera/theorem_carrier.iii`: a theorem is `statement + verified
proof-term id + content-address + dependency closure`, and **`tc_alloc` refuses admission
unless `pt_verify == 0` and every cited dependency is resident**. `curry_howard.iii` makes the
proof term the program.

**The unification.** This closes the trust story: the system's trustworthiness reduces to
**re-checking three content-addressed (M1) things — proof terms (M9), these certificates, and
the witness chain (M6)** — all recomputable by anyone. A **constitutional clause (M10) may
cite a theorem**, so the conscience rests on *proven theorems*, not bare predicates
(`theorem_carrier`'s resident-and-verified rule enforces it). Synthesis (M15) outputs
proof-carry; a memo (M14) hit carries its certificate; federation (M19) ships them — a peer
verifies by re-checking, never by trusting the producer. *Falsifier:* an opening proof that
doesn't verify in log-time against its Merkle root; a `tc_alloc` admitting a theorem with
`pt_verify ≠ 0` or an absent dependency; a constitutional clause citing an unresident theorem
→ red.

**Key moves.** The move is *to carry proof* — `pc_verify`/`tc_alloc` (`Artifact → certificate`); the illegal move admits a theorem with `pt_verify ≠ 0`.

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

### Module 17 · Depth D1 — the `tp_*` pipeline as a labelled morphism category

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

**Key moves.** The move is *to convert* — each `tp_*` (`FormA → FormB`); the illegal move is a "lossless" transform whose round-trip ≠ identity.

---

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

### Module 18 · Depth D1 — the self-host status and the D-gates as clauses

**Today (read).** The BOOT pipeline is now **largely `.iii`**: `lex.iii` → `parse.iii` →
`ast.iii` → `sema.iii` → `cg_r0`/`cg_rm1`/`cg_rm2`/`cg_r3.iii` → `emit.iii` → `link.iii`,
driven by `main.iii`, with `hexad_check.iii`, `sid.iii`, `proof.iii`, `witness_alloc.iii`,
and `jit_emit.iii` beside them. `sema.iii` states its contract directly: **"behavioural
parity with the C reference: same gates D-1..D-12, same error codes, same side-table
queries. No placeholders."** Triple-bit-identity (iiis-0 ≡ iiis-1 ≡ iiis-2) holds.

**The D-gates are already proto-clauses.** `sema` emits real admissibility codes —
**`TYPE-HEXAD-001`** (hexad missing on a cycle), **`TYPE-HEXAD-002`** (hexad unrepresentable
= the `reach` rejection, M3), **`TYPE-IRPD-001`** (raw privileged op outside an `irpd`
region, M8/M23) — via `iii_hexad_packed_admitted(packed)` at compile time. So "make `sema`'s
D-gates constitutional admission (M10)" is not a rewrite from scratch; it is registering the
twelve existing gates as clauses with paired falsifiers, each already backed by a negative
corpus case.

**Why the compiler is the apex.** It is where migrations **(2)(4)(6)(7)** converge in one
artifact: `lex`/`parse` build a **Sovereign-Value AST** (M5 — each node carrying
hexad/witness/cost/provenance, mig 3); `sema` = **kernel type-check** (M9, mig 2) +
**constitutional admit** (M10, mig 6 — the D-gates as clauses); `cg` = the **XII-emit
morphism** (M7, mig 4), cost-minimal by egraph extraction (M11/M13); the passes register as
**morphisms** (M12, mig 7); and **triple-bit-identity *is* the determinism theorem (Π5) plus
the self-compilation quine-seal** — the compiler proves "I compile myself to identical
bytes," an instance fixpoint (Gödel-safe, M9/M10). Every emitted `.o` carries its
cic-checked (M9) certificate (M16), so the whole build is proof-carrying; a peer re-checks a
compiled module by certificate without recompiling (M19). The bootstrap C stays the trust
root (like `cic.c`); the `.iii` self-host completes "one language" (M24). *Falsifier:* a
build not bit-identical across iiis-0/1/2; an emitted `.o` whose certificate fails kernel
re-check; a `sema` D-gate not expressible as a constitutional clause with a falsifier → red.

**Key moves.** The move is *to compile* — `sema` admit + `cg` emit (`AST → object | reject`); the illegal move is a build not bit-identical across iiis-0/1/2.

---

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

### Module 19 · Depth D1 — the deterministic BFT, byte-exact, and why a QC is a certificate

**Today (read).** `aether/hotstuff.iii`: **safety via the locked-block discipline,
liveness via view-change on timeout, leader = `view mod n`** (closed-form, no randomness —
the determinism mandate forbids random leader selection), **quorum 2f+1**, with real
vote-bitmap aggregation and f+1 new-view collection (`hs_handle_vote`, `hs_handle_new_view`,
`hs_tick`, `hs_committed_head`). The wire is byte-exact: a **Block (424 B)** =
`parent_qc(256) ‖ view(8,LE) ‖ …`; a **Vote (108 B)** = `block_mhash(32) ‖ view(8) ‖
voter_id(4) ‖ voter_sig(64)`, the signature taken over `block_mhash ‖ view`; a **QC** =
`block_mhash(32) ‖ view(8) ‖ n_sigs(4) ‖ 64-B signatures`. Companions: `hotstuff_heal`
(reconciliation) and `hotstuff_predict`.

**The deep fact: a QC is a content-addressed certificate.** A vote signs the **`block_mhash`
(M1 content-address)**, so a quorum certificate is `2f+1` Ed25519 signatures (M26) over one
content-address — a re-checkable certificate (M16) a peer verifies by checking sigs against
the `block_mhash`, **never by re-running consensus**. This is precisely "consensus-free
agreement": BFT is needed *only* to order nondeterministic *inputs* (external events get a
total order via the leader sequence); deterministic, content-addressed, proof-carrying
*results* need no vote — two nodes computing the same SovVal reach the same `mhash` and
agree for free. A **Byzantine node is one whose values fail certificate re-check** —
structurally excluded, not out-voted — and federation agreement is the categorical
**pullback** (M12) of two nodes' morphisms over a shared object. *Falsifier:* a
deterministic result that needs a vote to agree; a QC accepted whose sigs don't verify over
its `block_mhash`; a leader chosen by anything but `view mod n`; a Byzantine value passing
certificate re-check → red.

**Key moves.** The move is *to agree* — `hs_handle_vote` + QC-verify (`block → QC`); the illegal move makes a deterministic result need a vote.

---

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

### Module 20 · Depth D1 — containment and regeneration, byte-exact

**Today (read).** `aether/quarantine.iii` is a **transactional sandbox over authoritative
state**: writes are journaled, reads consult the journal first and fall through on miss;
`q_commit` applies the journal in insertion order **and captures an undo journal so the
commit is reversible** (`q_rollback`); `q_abort` discards. **Every transition is a witnessed
fragment chained to the enter fragment** (M6), and mint/apply are **capability-gated
(`CAP_RIGHT_AMEND`, `0x4000`)** (M8). `aether/bone_marrow.iii` is a **Reed–Solomon
erasure-coded seed archive** over **GF(2⁸), k=8 data + r=4 parity per stripe** (4 KiB
blocks), crowned by the **W30 seal — a Keccak256 corpus root verified at every boot before
any module loads** (Ring R-2); it recovers **any r simultaneous losses by Gauss–Jordan
inversion of the surviving k×k submatrix** over GF(2⁸) (`gf8_mul`/`gf8_pow`/`gf8_inv` from
`galois.iii`).

**The unification — and a trap-shaped detail.** The immune system is **not new machinery**:
`quarantine`'s journaled-reversible-witnessed transition *is* an M8 reversible envelope plus
an M6 witness; `bone_marrow`'s W30 boot seal *is* the M1 content-address / M10 closure root
checked at boot. So the loop closes with organs already built — **M10 detects (red verdict)
→ M8 contains (reversible quarantine) → M1/M6 attest → M20 regenerates (bone_marrow)** — and a
regeneration is itself **proof-carrying (M16)**: restored state must re-check against the
bone-marrow Keccak256 root, so recovery cannot silently restore a corrupt self. Because the
seed is erasure-coded *and* federated (M19), the marrow replicates — the system can
regenerate from peers. (Trap-shaped detail, grounded: `bone_marrow`'s header records that
`gf8_*` take/return **`u32`, not `u8`**, and that call sites **narrow u8 ↔ u32 and mask every
u32 index** — the documented u32-in-u64-slot discipline; the erasure math's correctness
depends on that masking, so it is a falsifiable invariant, not a style note.) *Falsifier:* a
red verdict with no containment; a regeneration that doesn't re-check against the marrow
root; a quarantine transition that isn't reversible or witnessed; an unmasked u32 index in
the GF(2⁸) reconstruction → red.

**Key moves.** The move is *to contain & regenerate* — `q_commit` + bone-marrow regen (`state → state'`); the illegal move restores state un-checked against the marrow root.

---

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

### Module 21 · Depth D1 — the two clocks, and the one place III touches the OS

**Today (read).** Two clocks by role. `numera/algebraic_time.iii` (M6·D1) is the deterministic
causal counter. `tempora/instant.iii` is the **sealed monotonic wall-clock** — the *single*
place III reads the OS clock: Phase C backs it with **Win32 `GetTickCount64`** (`extern … from
"kernel32"`), and each instant carries **`u64 tick + per-process epoch + cap_id + a 16-byte
sealed tag = sha256(tick ‖ epoch ‖ cap)`** (Phase D promotes the seal to **HMAC under a
Sanctum slot-4 sealed sub-key** for forge-resistance). `deadline`/`duration`/`calendar`/
`rfc3339` build on it.

**The unification.** The roles never conflate. Causal time (algebraic) is the **deterministic
substrate** the Constitution's LTL clauses (M10·D1) range over, decided by bounded model
checking (M11) — sound *because* it is replayable (M6). Wall-clock (`tempora`) is
**nondeterministic external input**, so it enters only as a sealed (M1), capability-gated
(`cap_id`, M8), witnessed (M6), federation-ordered (M19) Sovereign Value — never a determinism
leak. `deadline`/`duration` become **cost-facet temporal budgets (M13)**. The single
`GetTickCount64` call is the *entire* OS-clock attack surface, sealed and capability-bound.
*Falsifier:* a determinism path that reads `tempora` wall-clock; a temporal clause not decided
over algebraic time; an `instant` without its sealed tag / `cap_id`; a second OS-clock call
site outside `tempora/instant` → red.

**Key moves.** The move is *to clock* — `at_advance` / sealed `instant` (`event → stamped`); the illegal move lets a determinism path read wall-clock.

---

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

### Module 22 · Depth D1 — the bump arena as a determinism requirement

**Today (read).** `memoria/region.iii`: `region_create(bytes)` makes one backing allocation;
`region_alloc(r, n, align)` **bump-allocates within it**; `region_release(r)` frees the whole
buffer; `region_used`/`region_capacity`/`region_remaining` query it. `arena.iii` is a 1:1
arena over a region; the `*_safe` variants add bounds. Ring R0, `kind_substance`.

**The unification.** **Deterministic bump-allocation is a determinism *requirement*, not a
convenience**: given a deterministic op order, bump yields **reproducible addresses**, and a
non-deterministic allocator would break the seal (Π5). So the arena is *the substance* under
the Sovereign Value — every SovVal (M5) lives in an arena, content-addressed (M1), witnessed
(M6). Memory and the witness chain are **dual**: the arena holds the live values, the chain
(M6) holds their provenance, and **releasing an arena is a bounded forgetting** — the
complement of witness redaction (M20), so the two forgetting mechanisms unify under one
accounting. The `*_safe` variants make allocation **capability- and cost-bounded (M8/M13)** —
the K-floor as a memory bound, so over-budget is refused at allocation exactly as `sv_op`
refuses an over-K composition (M5). *Falsifier:* a non-deterministic allocation address; an
allocation past a capability/cost grant; a live SovVal with no arena; an arena release that
doesn't account as a bounded forgetting → red.

**Key moves.** The move is *to place a value* — `region_alloc` (`(n,align) → addr`); the illegal move returns a non-deterministic address.

---

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

### Module 23 · Depth D1 — the §4.2 gate decision, externs and order

**Today (read).** `katabasis/gate.iii` (Increment 12) is "the III Gate's brain": given a
sealed cycle **TERM** (Inc 11) plus the seal + capability *outcomes*, it reads the cycle's
family / target / action straight from the term's kernel and **short-circuits in the §4.2
order `seal → cap → hexad → sid`**, returning a verdict (the `KGV_*` codes of
`gate_verdict.iii`, pinned by corpus 602). It computes hexad admission in full via
`katabasis_cycle_admit(family, target_kind, target, action_hexad) → u8` (Inc 5) and
SID-inverse derivability via `katabasis_cycle_has_inverse(family) → u8` (Inc 3); the action
hexad comes from `katabasis_cycle_action_hexad(cycle_idx)`. Crucially, **no metal is
performed in the gate — it is the *decision*; performing + witnessing follow only once the
verdict is `OK`.** The substrate is ~15 files (`cycle_term`, `cycle_admit`, `cycle_family`,
`ring_lattice`, `svm_layout`, `bar_layout`, `vmexit`, `census`, `seal`, `caps`,
`bricking`, …).

**The unification: the gate is the Constitution at the metal.** The four short-circuit
checks are exactly four Sovereign-Value facets — **seal** = content-address + Anchor (M1/M9),
**cap** = capability (M8), **hexad** = safety reach (M3), **sid** = reversibility (M8) — and
the §4.2 ordering is a cost-ordered (M13) early-out (cheapest, most-decisive check first).
So a cycle *is* a SovVal (payload = the privileged op, hexad = its safety, witness =
provenance, cost = resource), and `REJECT_HEXAD` becomes a **type error** once the SovVal is
a CIC inductive (M9, mig 2) — an inadmissible cycle is *unconstructable*, not
runtime-rejected. The seal check runs the **behavioral quine-seal below the OS** (M1/M9), so
III attests "I am exactly this source and executed behavior" at Ring −1/−2. CHARIOT's 9
families are 9 morphism classes (M12), each gated here, each reversible-or-typed-`Compromise`
(M8), each cost-bounded (M13); the verdict is a witnessed (M6), proof-carrying (M16) SovVal.
(Proven on metal: Tier-2 Ring-0, Win32 err 50, no BSOD.) *Falsifier:* a metal operation
performed before an `OK` verdict; the §4.2 checks evaluated out of `seal → cap → hexad → sid`
order; a verdict code outside the corpus-602-pinned `KGV_*` set → red.

**Key moves.** The move is *to admit metal* — `katabasis_gate_admit` (`cycle → verdict`); the illegal move performs metal before an OK verdict.

---

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

### Module 24 · Depth D1 — the retirement ledger, enumerated

**Today (read, verified).** The bloat is real and counted: **`sha256.c` exists 14× across the
C reference tree** (confirmed: 14 copies outside `build/`), the **`HEXAD/src/` C ancestors**
are present, and the **`omnia/sid.iii` name collision** is self-flagged in source (M8·D1).
The retirement targets, each gated on its `.iii` port passing the C version's *exact* KAT:

| Retire | Into | Proof gate |
| --- | --- | --- |
| 14× `sha256.c` + per-subsystem `crypto.c` | one `cad` / `sha256.iii` (M1) | Π20 byte-identity + corpus 02/15 |
| `HEXAD/src/hexad_*.c` | `omnia/hexad_*` (M2/M3) | hexad KAT + the 144-reach check |
| `omnia/sid.iii` (navigator) | renamed `omnia/crystal_deps.iii` (M8) | link-resolves; SID confusion gone |
| `either` / `checked` duplicated handling | delegate to `uncertainty` (M4) | gap KATs |
| POC propositional `kernel.iii` | `cic.c` (M9) | superseded; cic KATs |
| `CRYPTO-AGILITY/src` C dispatcher | `.iii` suite registry over `cad` (M26·D1) | each primitive's own KAT |
| spec-only entries with no `.iii`, no consumer | deleted | no forward-ref exists |

**Keep the trust roots:** `COMPILER/BOOT` (bootstrap C) and `TYPES/src/cic.c` (until
`numera/kernel.iii` lands) — M9-style anchors, not bloat. Each deletion is a **witnessed (M6),
constitutionally-ratified (M10) amendment whose falsifier is the byte-equivalence KAT** — so
M24 is the *dual of every prior module*: each enhancement made a `.iii` organ provably superior
to its C ancestor, and this module retires the ancestor only once that superiority is proven.
*Falsifier:* a retirement whose `.iii` port fails the C version's exact KAT; a deletion that
drifts the seal or reddens the corpus; removing a trust root; a "spec vapor" deletion that
actually had a consumer or forward-reference → red.

**Key moves.** The move is *to retire* — the byte-equivalence amendment (`C-module → ∅`); the illegal move deletes a module whose `.iii` port fails the exact KAT.

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

### Module 25 · Depth D1 — the 192-byte Glyph as the serialized Sovereign Value

**Today (read).** `verba/glyph_core.iii` (Phase 14h) is the **sealed 192-byte Glyph V3**:
`[0..3] form_id (u32 LE) | [4..7] payload_len (u32 LE) | [8..159] payload (152 B) |
[160..191] sha256(form_id ‖ payload_len ‖ payload[0..152])`. `gv3_compute_mhash` recomputes
the trailing 32 bytes from the rest; `gv3_validate` checks the recorded value — so **a
corrupt or forged glyph fails validation with no external lookup** (`gv3_total_bytes()` =
192, `gv3_payload_cap()` = 152).

**The unification: a Glyph *is* a serialized Sovereign Value (M5).** `form_id` is the value's
FORM/type (the M9 inductive tag), `payload` (≤ 152 B) is its body, and the trailing hash is
its **embedded content-address (M1)** — exactly what makes the Glyph self-verifying (the H3
invariant exemplar). So storage, wire, and federation carry Glyphs that re-check in
isolation: every byte that persists or leaves the system re-validates alone, needing no
external trust. Three consequences. (a) After the M1 collapse the integrity field becomes a
**suite-tagged `cad` digest**, so the *entire* historical storage/wire layer is Q-Day-immune
— old glyphs verify under their original suite. (b) A value larger than 152 B becomes a
**Merkle-DAG of Glyphs linked by `ca_compose`** (M1/M6) — the 152-byte cap is a chunking
boundary, not a ceiling. (c) `nl_lex` + `ast_intent` turn human prose into a deterministic,
proof-carrying SovVal (→ synthesis M15 → kernel M9), and `timing_safe` is the
`@constant_time` discipline (M26) on any secret-touching glyph. *Falsifier:* a Glyph that
validates against a wrong embedded hash; a SovVal whose serialized-Glyph round-trip ≠
identity; a value > 152 B not chunked into a verifiable Glyph DAG; a non-deterministic
`nl_lex` parse → red.

**Key moves.** The move is *to serialize* — `gv3_validate` + (de)serialize (`SovVal ⇄ Glyph`); the illegal move is a Glyph that validates against a wrong embedded hash.

---

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

### Module 26 · Depth D1 — the suite as curated, constant-time morphisms

**The real inventory (grounded in `numera/`).** Hashes & XOFs: `sha256`, `sha512`,
`sha3_256`, `sha3_512`, `keccak`/`keccak256`, `shake128`, `shake256`, `blake2s`.
MAC/KDF/DRBG: `hmac`, `hkdf`, `pbkdf2`, `drbg`. AEAD & stream: `chacha20`,
`chacha20_poly1305`, `xchacha20_poly1305`, `poly1305`, `aes`, `aes_gcm`, `aes_siv`.
Signature/KEX & fields: `crypt_ed25519`, `x25519`, `ecdsa_p256`/`ecdsa_p384`,
`ec256`/`ec384`, `fe25519`, `fp256`, `rsa`. Post-quantum: `mlkem` (ML-KEM), `mldsa`
(ML-DSA), `slhdsa` (SLH-DSA / SPHINCS+). Zero-knowledge (the corpus `zk` layer, not
`numera/`): `zk_stark`, `374_zk_field_bls12381`, `375_zk_snark_groth16`.

**Each primitive is a typed morphism** (M12), and the trichotomy mirrors M17·D1 exactly:
a **hash/XOF is a one-way forgetful functor** (`bytes → digest`; the absence of an inverse
*is* its security property); a **cipher is an iso pair** (`encrypt ⇄ decrypt`, an
SID-isomorphism M8 whose round-trip-identity is its falsifier); a **signature / MAC / KEM
/ ZK proof is a `value → certificate`** whose verify is a re-check (M16), never a trust
(M9/M19) — the kernel consumes the certificate, it does not believe the producer. This is
exactly why federation is consensus-free: a peer re-runs `verify`, it never re-signs.

**Constant-time is enforced, not asserted.** The discipline is real per-function
attributes — `@constant_time` (28 sites), `@side_channel_resistant` (12), `@crystal`
(13), `@provenance_linked_error` (8). `x25519` carries `@crystal @side_channel_resistant
@constant_time`; `poly1305`'s `set_key`/`update`/`finalize` carry `@side_channel_resistant
@constant_time`. These lower to `xii_horizon`'s `ct_kind (0..8)` field (offset 7; bit 7 =
productive), so "constant-time" is checked at *two* levels — the source attribute and the
Horizon pattern's class — and a curated kernel for a `ct_kind > 0` pattern whose bytes
branched on secret data would fail promotion (M7/M10).

**The crypto suite *is* H001–024 with curated kernels — proven, not claimed.**
`omnia/xii_curated_crypto.iii` registers real sealed machine code via
`xii_emit_gen_override(horizon_id, target, payload, size)` for `H003 chacha20_block`
(x86_avx2 *and* arm64_neon), `H004 chacha20_round_pair`, `H005 poly1305_block`
(PCLMULQDQ), `H007 aes_gcm_encrypt` (AES-NI + PCLMULQDQ), `H016 blake2s_block`, and `H017
hmac_sha256` — "constant-time-safe where the pattern's `ct_kind > 0`." So "crypto
morphisms route through the Horizon" is concrete: ChaCha20, Poly1305, AES-GCM, BLAKE2s
and HMAC are Horizon patterns with hand-curated, sealed, per-ISA bytes that **must be
bit-identical to their `.iii` reference output** (the M7·D1 promotion gate) — superopt
that is sound by construction.

**The agility migration, made specific.** The `suite_id`-tagged uniform interface does
not yet live in `.iii`; it is the **CRYPTO-AGILITY C reference tree** (`crypto.c`
dispatcher + `aes_gcm.c`, `chacha20_poly1305.c`, `ed25519.c`, `mlkem.c`, `mldsa.c`,
`slhdsa.c`, `sha2.c`, `sha3.c`, `x25519.c`). M26's "route all crypto through the `cad`
suite registry" is therefore a concrete lift — re-express that dispatcher in `.iii` over
the one `cad` (M1), then retire `CRYPTO-AGILITY/src` (M24) once each `.iii` primitive
passes the C version's *exact* KAT. The PQ trio (`mlkem`/`mldsa`/`slhdsa`) is the dormant
temporal-immunity reserve (charter NFR-1, ready not active); the ZK trio folds into
proof-carrying (M16) as succinct certificates.

**Sharper orphan analysis (feeds M24).** A primitive is an orphan only with *no* live
consumer *and* no consumed curated kernel. `blake2s` is the subtle case: it has a curated
kernel (`H016 blake2s_block`) yet no live protocol consumer — so it is pruned *together
with* H016 unless H016 is itself consumed; `pbkdf2` (no password flow),
`aes_siv`/`xchacha20_poly1305` (no consumer), and `ecdsa_*`/`rsa` (interop-only) are
pruned absent a real consumer or mandate. *Falsifier:* a crypto result trusted without
re-check; a curated kernel (`H00x`) whose output differs from its `.iii` reference; a
`ct_kind > 0` pattern whose bytes branch on secret data; a retained primitive *and* its
curated kernel with no consumer → red.

**Key moves.** The move is *to make confidential/authentic* — each primitive (`value → cipher | certificate`); the illegal move's result is trusted without re-check.

---

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

### Module 27 · Depth D1 — the crystal: a forge-resistant error, byte-exact

**Today (read).** `omnia/crystal.iii`: a **sealed error crystal** is a forge-resistant error
value. Its provenance — **`site_hash` (sha256 of the source span, 32 B), `cap_id` (u64, the
capability it was minted under), causal predecessor, and K-value at mint** — is bound by a
**16-byte MAC over `(domain ‖ all fields ‖ sealed sub-key)`**. An attacker who fabricates a
fake error **fails `crystal_verify` because they lack the sub-key**. The key is staged: Phase
D derives a per-process key from a one-shot timestamp + cap-tree salt; Phase E swaps in a
**Sanctum slot-4 sealed sub-key**. Storage is bounded (`CRYSTAL_MAC : [u8; 4096]` = 256 × 16,
W8).

**The unification: an error is a sealed, provenance-bearing value — a gap with a MAC.** A
failure is a `Gap` (M4) whose root cause is a `crystal`: forge-resistant (the 16-byte MAC),
content-addressed (M1, the `site_hash`), capability-scoped (M8, the `cap_id`), causally
chained (M6, the predecessor), and K-tagged (M13). So **errors are as trustworthy as results
— you cannot forge a failure**; and because a crystal is sealed + addressed + witnessed it
**federates (M19) and re-checks like any value**, so a peer cannot be lied to about a failure.
This is the sealed-error *reading* of the gap/SovVal (M4/M5), not a separate error system;
`unify` (M27) stays the one Robinson engine shared by kernel (M9) and resolver (M30).
*Falsifier:* a fabricated crystal that passes `crystal_verify` (a forged MAC); a failure that
is not a gap carrying a crystal; a crystal missing its `site_hash`/`cap_id`/K-value provenance
→ red.

**Key moves.** The move is *to seal a failure* — `crystal_verify` / `unify` (`error → sealed crystal`); the illegal move is a forged crystal that passes verify.

---

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

### Module 28 · Depth D1 — the observatory as a sealed-threshold constitutional clause

**Today (read).** `omnia/obs_observatory.iii` (Phase 14c) is a **12-family threshold
rollup**: twelve named indicator families, each with a current value and a threshold; when
**`current > threshold` the family fires**, and a single **u32 collapsed-state bitmask**
reports every firing family at once (e.g. family 2 = peer-divergence). The crucial property
is stated in the header: the **family-tag mapping is a sealed `const`, NOT adapted at
runtime** ("hardcoded-dynamism"). API: `obs_observatory_set_threshold`/`_threshold`/`_update`/
`_value` per family.

**The unification: observability is the Constitution running continuously, with sealed
thresholds.** The no-statistical-learning tenet forbids a threshold that *adapts from observed
data* (an adaptive threshold is the forbidden threshold-trigger). The sealed-const mapping is
exactly that guarantee in source — thresholds are set, never learned. So the OBSERVATORY is a
set of **constitutional predicate-clauses (M10)** over witnessed (M6) values: each family is a
clause, a family "firing" is a clause going red, the u32 bitmask is a verdict vector, and a
red family **drives the immune response (M20)**. `obs_log`/`obs_trace` are witness fragments
(M6); `obs_metric` is a deterministic cost/K rollup (M13). Pushed further, the collapsed-state
feeds **temporal clauses (M21)** — "family X *eventually* clears" is an LTL guarantee
model-checked (M11) — so observability is the conscience evaluated over the witnessed stream,
not a parallel monitor. *Falsifier:* a family-tag mapping mutated at runtime rather than
sealed; a `> threshold` comparison on a determinism path that isn't a bounded total compare;
an indicator value not sourced from a witness fragment → red.

**Key moves.** The move is *to observe* — `obs_observatory_update` (`(family,v) → fire?`); the illegal move adapts a threshold at runtime from data.

---

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

### Module 29 · Depth D1 — quota as an append-only, un-evadable budget

**Today (read).** `omnia/sandbox_quota.iii` tracks **memory and CPU quota**:
`sandbox_quota_record_alloc(sb_id, n_bytes)` and `_record_cpu(sb_id, micros)` **return 0 if the
new total would exceed the budget**; `_mem_used(sb_id)` queries it. The critical design choice
is in the header: **quota records are append-only — there is no "release" call** — precisely to
defeat the **use-after-quota** attack where an adversarial sandbox repeatedly allocates and
frees to slip past a budget. `sandbox_ctor` constructs the boundary; `sandbox_exec` runs within
it.

**The unification.** The sandbox is **not new machinery** — it is capability (M8) + cost (M13)
+ reversibility (M20) applied to *execution*: the quota *is* the cost-lattice budget (M13)
enforced at runtime, the boundary *is* the capability grant (M8), and a violation hands off to
`quarantine` (M20) for reversible containment. The append-only quota is the **un-gameable**
reading of the cost facet — you cannot "free" your way back under budget, exactly as a SovVal's
cost only *joins* upward (M13·D1). A sandboxed result is therefore **proof-carrying (M16)**: it
proves it stayed within its cost/capability grant, so III can run untrusted code and return a
proof it never exceeded bounds. *Falsifier:* a sandbox exceeding its grant without containment;
a quota with a "release" path (the use-after-quota hole); a result that can't prove
bound-compliance → red.

**Key moves.** The move is *to spend budget* — `sandbox_quota_record_*` (`(sb,n) → admit | refuse`); the illegal move offers a "release" path (use-after-quota).

---

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

### Module 30 · Depth D1 — "AI" as deterministic symbolic resolution, grounded

**Today (read).** `omnia/ai_resolve.iii` is the generative front door, and its pipeline is
**fully deterministic**: the **HIP-2 NL parser (`verba/hip.iii`)** turns text → intent;
**`resolve` (`omnia/resolver.iii`)** turns intent → binding + witness against the **global
pattern set (`pattern_table.iii`)**; the caller's **capability handle is a *sealed input*
(`cap_id`), not observed**; failure returns a **privacy-preserving `NOMATCH`**. The header
states the law outright: **"No statistical learning enters the parse→intent→resolve
pipeline,"** and **"the resolver's pattern set bounds what an AI on this substrate"** can do.

**The unification: the antithesis of ML, by construction.** III's "AI" is intent → `unify`
(M27) against a *sealed, capability-bounded* (M8) pattern set → a witnessed (M6),
kernel-verifiable (M9) binding — no model weights, no gradients, no observe-and-adapt (the
no-statistical-learning tenet, enforced at the pipeline boundary). The resolver
*orchestrates* the cognition layer rather than adding an engine: intent (M25 / `hip`) →
`unify` (M27, the one Robinson engine shared with the kernel) → **synthesis (M15) when there
is no direct binding** → kernel-verify (M9) → witnessed (M6), memoized (M14), proof-carrying
(M16) binding; `codegen_dispatch` routes to the compiler (M18). Because it is deterministic +
memoized + witnessed, **the same prose always yields the same proven binding** — re-checkable
and federatable (M19). So III answers a human request in prose with a *proven, witnessed,
capability-bounded* artifact, and "AI safety" is a structural property here: the pattern set
is the hard bound on capability, sealed not learned. *Falsifier:* any statistical or
data-derived step in parse→intent→resolve; a binding that is not capability-bounded or not
witnessed; a non-deterministic resolution (same prose + caps → two bindings) → red.

**Key moves.** The move is *to resolve* — `ai_resolve`/`resolve` (`intent → binding + witness`); the illegal move admits any statistical step in the pipeline.

---

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

### Module 31 · Depth D1 — the membrane: capability-gated handles, content-addressed files

**Today (read).** `aether/fs.iii` is a **capability-gated** filesystem surface: every op first
calls **`cap_verify_rights(id, required)`** (from `capability.iii`) and works through
**`handle_alloc(kind, fd, cap_id)`** / `handle_close` / `handle_drop` (from `handle.iii`) — so
an OS resource is a **handle bound to a capability** (M8). `net`/`tcp`/`inet` are the socket
surface, `http*` the web surface, `idoc` the document surface.

**The unification.** Net/IO is the **membrane** converting external bytes ↔ Sovereign Values.
Every external input enters as a **quarantined (M20), sealed (M1), capability-gated (M8),
witnessed (M6) SovVal** — never a determinism leak; every output is a SovVal serialized to a
**self-verifying Glyph (M25·D1)** or Babel (M17). Nondeterministic inputs are **ordered by
HotStuff (M19) when consensus-relevant**; `http`/`tcp` ride the sealed channel (M19); `fs` is
**content-addressed (M1)** — files keyed by content; a `handle` is a capability-bound OS
resource (the `cap_id` argument to `handle_alloc`). So III's entire interface to the world is
trustless and auditable — nothing crosses the membrane untyped, unsealed, or unwitnessed.
*Falsifier:* an external input entering un-quarantined or unwitnessed; an `fs`/`net` op that
skips `cap_verify_rights`; a determinism path reading raw IO; an output that isn't a
self-verifying value → red.

**Key moves.** The move is *to cross the membrane* — `handle_alloc` + `fs`/`net` ops (`external bytes ⇄ SovVal`); the illegal move lets an input enter un-quarantined or unwitnessed.

---

*Pass 2 (the long-tail leaf clusters M25–M31) complete: text/meaning, crypto suite,
collections, observability, sandbox, resolver, net/IO — each shown to inherit the
spine and amplify it, with nothing left as a parallel system. The idealized III is now
documented end to end: 24 architectural organs + 7 leaf clusters, one body.*

---

## What III becomes able to do (once M1–M31 land)

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

> The spine, restated now that all 31 are placed: **one language · one currency
> (the Sovereign Value) · one conscience (the Constitution) · one engine (XII) · one
> category (every transform a morphism) · one body (federation, immune, time, memory,
> metal).** Deeper, not wider. Nothing compromised; nothing tacked on; every organ
> made greater by the others and the whole made greater by each.

---

## Errata — corrections to the charter, surfaced during the build

These were found by reading source, not recalling it; each is folded into the relevant
module above and collected here as the charter's correction record.

> **First-principles corrections surfaced while drafting M1–M10** (each grounded in
> source, not memory): (a) `TYPES/src/cic.c` *already* has dependent Π-types +
> seven universes + `Trit`/`Hexad` inductives — the charter's "frontier" was wrong;
> the kernel is fuller than the POC. (b) `omnia/sid.iii` is a dependency navigator,
> not SID — a name collision to clear (→ `crystal_deps`). (c) `sha256.c` is
> duplicated **14×** across the C reference tree — the cleanest bloat cut, deferred
> to M24. (d) The immune/repair organs (`quarantine`, `bone_marrow`, `basal_probe`)
> are *built*, not spec-staged as the charter implied.

---

## The Move — the per-operation Sovereign Morphism contract

The thirty-one modules answer *what III is made of*; M5 answers *what a value is*. Neither
answers the question this whole file is really about — *what makes it one body* — because
that property lives in no module and no value. It lives in the **operation**: the move that
carries a value across a boundary. A file is a unit of storage; a value is a unit of meaning;
**a move is a unit of obligation.** Bind the contract to the move and enmeshment becomes
*invariant under refactoring* — split a file, merge two, relocate an operation, and the
one-body claim cannot change or be faked, because the obligation travels with the meaning,
never with the filename. This is the stratum between M5 (the value, a noun) and H1–H13 (the
global theorem): the **local contract whose fold is that theorem** — so the Harmony Invariants
below are this section's corollary, not a separate authority.

**The collapse: one obligation, seven entailments.** The contract is not a checklist bolted
beside the value. It is a single statement — *every operation crossing a `@sovereign` boundary
is an arrow in the one category (M12) whose objects are SovVal-types* — and being such an
arrow *forces* the rest, because the category machinery already exists:

- registered by `cat_add_morphism` with `cat_check_assoc` passing ⟹ lawful composition (H11);
- an arrow over SovVal-types must carry the four facets, so payload-soundness (M4),
  hexad-`Refused` (M3) and cost-`Refused` (M13) are the *typing of its domain and codomain*,
  not side-checks (H1/H5/H6);
- its id `cad(src ‖ dst ‖ op)` (M1) makes its application a witness fragment (M6) (H2/H8);
- its falsifier is a clause `run_charter` folds (M10) (H7);
- its reversibility tag is what `COP_REVTAG_EQ` reads (M8) (H9);
- it returns a certificate the consumer re-checks (M16), never trusts (H10).

So `sv_op` is not the contract's *example* — it is the **generating morphism** every other
specializes (the archetype, *not* an identity arrow: this is composition, not identity), and
every move is "do what `sv_op` does, for your arrow." H1–H13 is the fold of all moves; the
Constitution stops being an authored authority and *becomes* that fold.

**The interface (`SovMorphism`).** A move is a CIC dependent record (M9) — a function *plus*
the proofs the kernel checks, so legality is a **typecheck, not an audit**:

| Field | Obligation | Module |
| --- | --- | --- |
| `apply : A → B` | the operation itself (internal scratch is free — only the boundary binds) | — |
| `payload_law` | propagates `Known`/`Gap` with sound gap arithmetic | M4 |
| `hexad_law` | `hexad(apply x)` is reachable, else type-level `Refused` | M3 |
| `cost_law` | `cost(apply x)` = lattice-join of inputs, `≤` grant, else `Refused` | M13 |
| `witness` | a `FragId` emitted per application | M6 |
| `morphism_id` | `cad(src ‖ dst ‖ op)`, registered via `cat_add_morphism` | M1/M12 |
| `falsifier` | a constructed bad input + the verdict it MUST turn red | M10 |
| `inverse` | `Reversible(derived)` \| `Compromise(LOW\|MED)` \| `Unrepresentable` | M8 |
| `certificate` | a re-checkable proof handed to the consumer | M16 |
| `defer` | ledger of `(obligation, reason, safety_falsifier)`; **empty iff Final** | M10 |

`@sovereign fn f(a: A) -> B` elaborates to "`f : SovMorphism(A,B)`"; `sema`'s D-gate (M18·D1)
checks the proofs and emits `III_NONSOVEREIGN_BOUNDARY` if `A` or `B` is a raw type at the
boundary — the **referee ruling the move legal at the instant it is played.** Computation
*inside* `apply` is unconstrained; the contract attaches at the boundary and nowhere else
(deeper, not wider).

**The ninth field is what makes the audit live.** `defer` carries, for an unfinished move,
*which* obligations it postpones and a falsifiable "why this is safe meanwhile." This turns the
consistency audit from authored prose into a computation: **`Hk` holds systemwide iff no
admitted move defers an obligation `Hk` depends on**, and the seven-migration critical path is
precisely the deferral-closure emptying out. A move with empty `defer` is `Final`; each
module's body above is the set of its moves' targets.

**The checker is itself a move (the fixpoint).** `is_sov_morphism : Candidate → Verdict` is
*itself* `: SovMorphism(Candidate, Verdict)` — registered, witnessed, carrying its own
falsifier (a known non-morphism it must reject). The contract is **closed under itself**,
Gödel-safely: it checks each move as an *instance*, never its own consistency — the same
instance-fixpoint as the behavioral quine-seal (M9/M10/M18).

**Why this is the only choice (an elimination from the tenets), held to exact strength.** The
contract's **core** is the unique fixpoint of III's tenets, each forced by contradiction: bind
to the *file* → fakeable by refactoring (rejected); a *checklist beside the value* → a second
source of truth that drifts (rejected); a checker that *trusts* → H10 (rejected). No survivor
remains, so value-bound ∧ single-source ∧ recheck-not-trust is forced *unconditionally*. The
**scope** — boundary-only — is forced by the *text* of H1, which is literally a predicate over
values *crossing a boundary*; "deeper, not wider" only makes boundary-only least-wasteful, not
the sole sound scope, so the honest claim cites H1, not parsimony. The no-statistical-learning
tenet forces the shape of the *tooling* (the development surface below), not of the contract.
What survives is one design — value-bound, single-source, boundary-only, re-check-not-trust,
self-closed. Determinism here is not a lowered standard; it is the *strongest* standard, because
the core is provably the only one the constraints admit. (Premise-Ledger row **T9** holds this
proof to precisely this strength — core unconditional, scope conditional on H1's text.)

### The Move · D1 — the development surface (the introspection dividend)

Everything that makes the contract a burden to satisfy is the very thing that makes the system
**describe itself.** A move that registers, carries a falsifier, declares its inverse, joins
its cost and emits a witness has — for free, simply by being trustworthy — also made itself
queryable, verifiable, discoverable, and replayable. So the development surface is not a new
authority that computes anything fresh; it is a **live fold over the artifacts every move
already produces**, exactly as the Constitution is the fold of every falsifier. One structure,
two readings: one faces the auditor, one faces the maker. It is **parasitic on the contract and
is not a second source of truth.**

The five reads, each a primitive that already exists:

- **"Does this morphism exist?"** → `cat_find_morphism`, keyed on a morphism's **behavioral
  normal form under XII (M7)** — not its type signature alone, or two ops sharing one signature
  but computing differently would false-match. This is the direct cure for the duplication this
  file is haunted by: before adding `sha256` you *query the category by what it computes*; the
  fourteenth copy is a query **hit**, and on a miss the synthesizer (M15) + resolver (M30) propose
  a kernel-rechecked (M9) composite. You never write copy #2.
- **"What is defended?"** → `run_charter`'s verdict vector (M10): which invariants hold, which
  falsifiers still catch their bad case.
- **"How did we get here?"** → `ws_replay` from seed (M6) with derived inverses (M8): any red
  verdict winds backward to the exact move that introduced it. The witness chain is a debugger
  by construction; time-travel is a consequence of the discipline, not a feature.
- **"What is the cheapest path?"** → egraph min-cost extraction over the cost lattice (M11/M13).
- **"What is still aspirational?"** → the defer-ledger fold: the live H1–H13 audit and the
  seven-migration progress surface.

**The authoring loop is `run_charter` itself.** Because the falsifier is executable and
`run_charter` is already the green/red light that ships the system, you **write the bad move
first** — the case that must be refused — and the same gate tells you the instant your operation
correctly turns it red, whether adding it preserves confluence (re-run the 117 critical pairs,
M7), whether it still decreases the MPO termination measure, and whether the seal reproduces.
There is no gap between "passes my tests" and "is admissible" — they are the identical check.

**Developability rises with enmeshment — but the claim splits by strength.** The *supply* claim
is unconditional: the set of reusable composites is monotonically non-decreasing, because adding
an arrow never removes a reuse opportunity. The *hit-rate* claim — that the next needed move is
increasingly likely to already exist — is conditional: it holds only where the type-graph is
densely connected (the closure grows faster than linearly) and demand is local (the next need
stays within the region the closure covers), and it falls the moment a needed move introduces a
genuinely new SovVal-type. Where both premises hold, the thing that is hard to build becomes, as
it is built, the thing that makes further building easier — a self-accelerating loop rather than
software's usual accumulating entropy. (Premise-Ledger row **T8** holds each half to its
strength — supply unconditional, hit-rate premised.)

Two constraints keep the surface inside the tenets. It is a **pure deterministic reader**: it
observes, folds, queries, and replays, but never learns from data or adapts a heuristic — its
suggestions come from category-search and deterministic synthesis (M15/M30), never a model with
weights. And it must **work gracefully over a half-finished system**: during early development
most moves are `Today`, not `Final`, and that is exactly where it earns its keep — surfacing the
undefended moves and the non-sovereign boundaries when the body is least complete.

*Falsifier:* an operation crossing a `@sovereign` boundary that is not a registered category
morphism; a move whose stated facet-law fails the kernel; a `defer` entry with no safety
falsifier; the checker exempting itself from the contract; a development-surface suggestion
sourced from anything but category-search or deterministic synthesis; an invariant claimed
systemwide while a move it depends on still defers → red.

---

## The Harmony Invariants — the enmeshment contract

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

These thirteen are the seam-test. The consistency audit below checks every documented
final form against them, module by module, and extracts the implementation critical
path; any contradiction found would be a unification defect to fix before implementation.

---

## The consistency audit — every final form against the Harmony Invariants

### Consistency audit · Foundation (M1–M6) against H1–H13

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

---

### Consistency audit · Engine + Conscience (M7–M10) against H1–H13

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

---

### Consistency audit · Cognition (M11–M16) against H1–H13

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

---

### Consistency audit · Representation + Body + Leaves (M17–M31) against H1–H13

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
all seven converge. Pass 3's per-file depth now lives **inline beside each module** —
M7·D1 (the Horizon & curated kernels) under Module 7, M17·D1 (the `tp_*` morphism
category) under Module 17 — and continues to sharpen specifics in place, each refinement
landing beside the module it deepens, within clusters already proven consistent.

---

## From the dream to the build — alignment, and the leverage the live build gives

**Alignment verdict (checked against `DOCS/CONVERGENCE-BUILD-LEDGER.md`, 2026-05-25).** The
apotheosis is **largely system-aligned**: nearly every module it describes is a real
convergence module, and **46 are KAT-green + hand-verified** (build 351/0, corpus PASS=384
FAIL=0, deterministic), with Wave-4 at 8 more (656–663). More than aligned — the build is
*independently converging on the same disciplines*: Batch-4's redesign theme ("untrusted oracle
+ independent re-verification + certificate + witness + cap-gate + bounded search") is the
Sovereign-morphism contract discovered from the other side; `automated_proving`'s refutation
prover + checkable proof term is M16; the verifier-separated pattern is H10. Four drifts were
found and **corrected in place above**: M12's composite-op (the live `category.iii` uses
associative **op-word concatenation**, not the non-associative `Keccak256(f_id‖g_id)` — a bug it
fixed); M6's witness (`frag_id` embeds `at_time`, so re-verification keys on the payload
content-address, per build bug #6); M10's LTL (`temporal_logic.iii` / `tl_eval` is *built* now,
not "unevaluated"); and the idealized codegen/consensus targets (`cg_superopt`,
`algebraic_consensus`) are named below as the specced Wave-4 forms the dream points toward.

**What the live build already gives the migration.** The critical path is *not* a green field —
most of it is **formalizing a discipline the build already practices by hand**, and every
migration's falsifier is *already runnable* on a gate that exists:

| Migration | Leverage that exists today | Difficulty |
| --- | --- | --- |
| **(1) `cad` collapse** | the determinism gate (mhash, corpus 384/0) makes the falsifier — seal-drift / a broken consumer — runnable now; manual-audit is the method | mechanical |
| **(2) SovVal as CIC inductive** | `cic.c` already types `Trit`/`Hexad` (7 inductives); the `proof_term`→`tc_verify` machinery is proven (652) | moderate |
| **(3) `@sovereign` checker** | `sema`'s D-gates exist; `TYPE-HEXAD-002` *is* a compile-time reach gate — `@sovereign` is the same kind of gate + a negative corpus arm | easy (the checker) |
| **(3′) boundary migration** | — no shortcut: every raw-scalar boundary must become a SovVal | **irreducible** |
| **(4) route through XII** | `xii_rewrite` + `xii_critpairs` (117 pairs, MPO) exist; `cg_superopt` (specced) *is* egraph + cost + SMT-verified superopt | **hardest (T4)** |
| **(5) `sid`→`crystal_deps` + inverse** | the safe-rename pattern is *proven* (bug #7: `tc_init`→`tck_init`, compiler-unreferenced, no seal drift, ADR-027); `reversible.iii` built | easy rename |
| **(6) `run_charter` + falsifiers** | the build *already* runs a green/red fold (corpus + negative arms + determinism mhash); `temporal_logic`/`tl_eval` built; "prove the negative" is daily practice | formalization |
| **(7) register morphisms** | `category.iii` (`cat_add_morphism`/`cat_check_assoc`, word-concat associativity) built + verified | moderate |
| **The Move contract** | every convergence module already registers (build_stdlib), carries a negative-arm KAT (the falsifier), emits `wh_publish` witnesses, is mhash-content-addressed, is cap-gated, and re-checks-not-trusts | **already lived by hand** |

**Where it is torture no matter what — honestly.** Three things the architecture can make
*verifiable* but never *cheap*: **(a)** XII confluence preservation (T4 — confluence is not
modular; each folded rule family risks a divergent critical pair; `xii_critpairs` is the
cheapest falsifier in the system, but re-proving convergence is real work and the likeliest
single collapse); **(b)** the `@sovereign` boundary migration — thousands of stdlib boundaries
moving from raw scalars to SovVals, one by one (the systemwide lift); **(c)** the proof
obligations (T3 — closed proof terms must be *supplied*; building the lone verifiable axiom term
for the `math_library` 652 vertical was itself a multi-step labor, and no design removes it,
only one that makes a faked proof turn red). The build has already paid this tax in miniature —
7 bugs found by hand, the 652 five-module vertical, the BSS-wall frugal refactor *at full gospel
scale* — which is the evidence the tax is real **and** payable.

**The leverage, as one fact.** The build ledger is *itself the manual development surface* the
introspection dividend describes — a by-hand fold of what is defended, deferred, and verified.
The integration does not *invent* that surface; it **mechanizes the discipline the build already
executes by hand** — register-the-move, carry-its-falsifier, emit-its-witness,
re-check-don't-trust — into the type system (`@sovereign` → `cic.c`) and the category registry.
So III right now makes integration easier in the one sense that matters: the gates already make
every migration's falsifier runnable, and the practice already exists to formalize. The three
irreducibles remain irreducible — and the apotheosis's own Premise Ledger (T3, T4) is where it
said so first.

---

## The Premise Ledger — every meta-theorem and the condition under which it holds

A theorem with an unstated premise is a guarantee with no falsifier — which this system forbids
of anything it governs, and therefore forbids of its account of itself. The consistency audit
above checked the *modules* against H1–H13; this ledger checks the *document's own meta-theorems*
against their premises. Each row is a clause: the claim, the condition under which it holds (and
is unique), and the constructed bad case that must turn it red. The meta-document submits to the
same verify ∧ falsify discipline as everything below it.

- **T1 · The collapse.** *Claim:* one obligation — be an arrow in the one category — entails the
  other seven. *Holds iff* the category's objects are SovVal-types and the four facets are carried
  by the *typing* of an arrow's domain and codomain (payload-soundness M4, hexad-reachability M3,
  cost-monotonicity M13 are the morphism's type, not guards run beside it), and `cat_add_morphism`,
  `cat_check_assoc`, the `cad` id, `COP_REVTAG_EQ`, and the `run_charter` fold are each built and
  sound. *Falsifier:* a registered, associativity-passing morphism for which any one facet is still
  enforced by a *separate runtime check* — so a bricking composition type-checks yet is caught only
  at runtime: the entailment leaked; that obligation was smuggled, not entailed → red.

- **T2 · The archetype.** *Claim:* `sv_op` is the **generating** Sovereign morphism every other
  specializes — a *generating* morphism, not an identity arrow. *Holds iff* every lawful arrow's
  facet-composition reduces to "do what `sv_op` does for this arrow," and the associativity under
  audit is the category's *composition* axiom (`(h∘g)∘f = h∘(g∘f)`, binary), never a property
  attributed to a lone arrow. *Falsifier:* a lawful Sovereign morphism whose facet-handling is not
  an instance of `sv_op`'s discipline (so `sv_op` was not the archetype), or any place the design
  tests `sv_op`'s associativity as a *unary* property, making the test vacuous → red.

- **T3 · Legality is a decidable type, so enmeshment is a theorem (the master row).** *Claim:*
  admitting a move is type-checking a `SovMorphism(A,B)` record, which is decidable. *Holds iff* the
  kernel checks each record **and** every admitted move arrives with its proof terms *supplied as
  closed terms — never holes, axioms, or postulates*: "every move legal" must mean the proofs exist
  and are discharged, not merely that they could in principle be checked. (`cic.c` has no
  `Axiom`/`admit` form, so a closed proof term is the only discharge — the falsifier is already
  buildable: the kernel refuses open terms in shipped moves.) *Falsifier:* any shipped move whose
  obligation is met by an axiom, an admit, or an open metavariable standing in for a proof → red.
  The irreducible human labor of constructing proofs cannot be removed by any design; it can only
  be made *visible* — a move that fakes it can be made to turn red, and that is the whole of what
  honesty buys here.

- **T4 · Composition (the quietest risk).** *Claim:* local legality composes into global H1–H13.
  *Holds iff* three independent things each hold: the category laws (associativity checked for
  *every* registered arrow); the engine's confluence (the 117+N critical pairs *still* converge
  after each rule family — trit M2, gap M4, `sv_op` M5, kernel β/ι M9, cost M13, transforms M17 —
  is folded in, **because confluence is not modular: two confluent rule sets can compose to one
  that is not**); and the kernel's strong normalization (MPO decrease preserved as the rule set
  grows). *Falsifier:* a rule family after which `xii_critpairs` reports a divergent pair, or any
  term with two distinct normal forms → red. This falsifier is built and is the *cheapest in the
  system to run* — which matters, because this is the single likeliest point at which the whole
  design collapses, and the one the rest of the document is quietest about.

- **T5 · The fixpoint terminates at the trust root.** *Claim:* the checker is itself a Sovereign
  morphism, closed under itself, Gödel-safe. *Holds iff* the checker is checked as an *instance*
  (never admitted by an argument about its own consistency) **and** the dependency regress
  terminates *exactly* at the declared trust root — `cic.c` + `COMPILER/BOOT` (the H13 carve-out,
  M24) — with every rung above that root an attested Sovereign morphism. *Falsifier:* the checker
  admitting itself by a self-consistency claim (the Tarski/Gödel-unsafe move), or any link in the
  checker's dependency chain that is neither a Sovereign morphism nor part of the carved-out root —
  an un-attested rung the closure silently leaned on → red. Closure *above a declared floor* is more
  forced, and more honest, than closure that pretends to have no floor.

- **T6 · The defer ledger (where unsoundness hides).** *Claim:* `Hk` holds systemwide exactly when
  no admitted move defers an obligation `Hk` depends on, so the critical path is the
  deferral-closure emptying out. *Holds iff* every deferral carries a *discharged, self-falsifying*
  "safe meanwhile" argument — a clause that catches its own violation, since a deferral is itself a
  move ("unfinished-op → admitted-anyway") recursively governed by The Move. *Falsifier:* a
  deferral whose "safe meanwhile" clause passes on its own constructed bad case — green while the
  unsoundness it claims absent is present → red. This is the single place unsoundness can hide
  behind a green board, so deferral falsifiers must be the **highest-scrutiny** clauses in the whole
  conscience, never the lowest.

- **T7 · The dividend is parasitic.** *Claim:* the development surface reads the five structures
  backward and introduces no second source of truth. *Holds iff* every answer is reconstructible
  from what admitted moves already populated (category, verdict vector, witness chain, cost lattice,
  defer-ledger) — the surface storing and asserting nothing of its own — **and** discovery keys on a
  morphism's *behavioral normal form under XII (M7)*, not its type signature alone. *Falsifier:* a
  surface query returning an answer not derivable from the populated structures; a weighted-model
  suggestion ASSERTED as the answer without a checker deriving it from those structures (the nous
  amendment permits a weighted model to PROPOSE-and-be-checked, never to DECIDE); or a duplication-cure "hit"
  matched by signature that is *not* behaviorally identical — which would mean the key was the
  interface, not the behavior → red.

- **T8 · Developability rises with enmeshment (split by strength).** *Claim (supply, unconditional):*
  the set of reusable composites is monotonically non-decreasing — adding an arrow never removes a
  reuse opportunity; holds without premise. *Claim (hit-rate, conditional):* the next needed move is
  increasingly likely to already exist — *holds iff* the type-graph is densely connected (the
  closure grows faster than linearly) **and** demand is local (the next need stays within the region
  the closure covers). *Falsifier (hit-rate only):* a development episode whose needed move
  introduces a genuinely new SovVal-type, so no existing composite applies and the hit-rate did not
  rise — the locality premise was false there → red. The supply theorem survives untouched; only its
  dressing as a claim about *demand* can fall.

- **T9 · The only-choice proof (split by forcing).** *Claim (core, unconditional):* value-binding ∧
  single-source ∧ recheck-not-trust is forced — each by contradiction (refactoring-invariance, the
  no-second-source rule, H10) — leaving no survivor; value-binding is what carries M5's
  refactoring-invariance from data to behavior. *Claim (scope, conditional):* boundary-only *holds
  iff* it is forced by the *text* of H1 (literally a predicate over values *crossing a boundary*),
  not by the softer "deeper, not wider" (under which boundary-only is merely least-wasteful, not the
  only sound option). The no-statistical-learning stroke forces the shape of the *tooling*, not of
  the contract. *Falsifier:* an alternative contract satisfying all five tenets yet differing in its
  core (a second fixpoint, breaking uniqueness), or a restatement of H1 as a non-boundary predicate
  under which boundary-only is no longer forced (revealing the scope was parsimony all along) → red.

- **T10 · The ledger audits itself.** *Claim:* this table is itself a guarantee, and therefore
  carries its own premise and falsifier, closed under itself as the checker is in T5. *Holds iff*
  every load-bearing claim the design rests on has a row here with a discharged premise and a
  *constructible* falsifier. *Falsifier:* a claim the design depends on with no row (an unaudited
  theorem), or any row above whose falsifier cannot in fact be constructed and run (a premise that
  only *sounds* checkable) → red. The ledger is green only when it audits itself; there is no
  vantage from which it is exempt.

> **The honest reading.** T1–T2 establish the contract; **T3 and T4 are the load-bearing pair** on
> which "enmeshment is a theorem" actually rests — the proofs must be *supplied* as closed terms
> (T3, irreducible human labor made visible, never faked), and confluence must be *re-proven* after
> every rule family because it is not modular (T4, the cheapest gate and the likeliest collapse).
> T5–T6 close the self-reference and guard the one place unsoundness can hide behind green. T7–T9
> hold the development surface and the two proofs to their *exact* strength, no more. T10 turns the
> discipline on the ledger itself. Everything else in this document is forced once T3 and T4 hold —
> and neither can be discharged by design alone, only by the work.
