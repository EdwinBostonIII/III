# III-APOTHEOSIS-MIGRATIONS-ARCH.md — deep architectural designs for the migration critical path

**What this is.** The *deep* architect designs for the seven-migration critical path (migrations
**1–6** herein; mig7/morphism-registration is the 7th, designed in `III-APOTHEOSIS-PREP.md` §mig7).
It escalates the lightweight completion-maps in `III-APOTHEOSIS-PREP.md` to full, current-state-
investigated designs. **Each design was preceded by fresh investigation of the live tree** (file:line
citations are from 2026-05-25); each is meticulous by intent.

**III-adapted architect framing (the framework, mapped to a sovereign deterministic substrate — not
a web app):** "Requirements/NFRs" = the Harmony Invariant the migration lands + the **falsifier**
(prove-the-negative, the acceptance test that must turn red on the bad case); "Pattern" = the proven
`.iii` idiom; "Components" = the touched modules + their changes; "Data/API" = the byte layouts +
the **extern contracts** (signatures pinned to real providers, §VII); "Cross-cutting" = determinism
(seal stability), witness, capability, the **iiis trap catalog** audit, NIH; "Deployment" = the
`build_stdlib` + `run_corpus` + DRIFT-reseal gate; "ADRs" = the load-bearing decisions; "Roadmap" =
the ordered, gated implementation steps. The standing law applies: no stubs, prove the negative,
read evidence first, manual-audit before rebuild, follow the gospel verbatim.

**Per-migration template (uniform across 1–6):** §A Objective + falsifier · §B Current state
(investigated) · §C Architecture (components, contracts, mechanism) · §D Cross-cutting (determinism,
traps, witness/cap, NIH) · §E Decisions (ADR-style) · §F Risks · §G Implementation roadmap.

---

# MIGRATION 1 — the `cad` collapse / H2 "one name"

## §A · Objective + falsifier
**Objective (H2):** every content-address in III is computed by the **one** `cad` primitive; there
is no second hash path. A value's name is `(suite, digest)`, so a Q-Day suite swap leaves all prior
names verifiable. **Falsifier (the acceptance test):** a `Keccak256`/`SHA-256` of a `(producer,
operation, input)` triple, of a Merkle link, or of any id — **computed outside `cad`** → red. (Post
mig6, this becomes a constitutional clause.)

## §B · Current state (investigated 2026-05-25, file:line)
- **`numera/cad.iii` — BUILT** (`665_cad=99`; build_stdlib:361). The one primitive:
  `cad_oneshot(suite,msg,len,out)` (`:53`), `cad_compute`/`cad_compose`/`cad_branch_key`,
  streaming `cad_begin`/`cad_domain`/`cad_payload`/`cad_final`, `cad_eq`/`cad_is_zero`. Suites:
  **`CAD_SUITE_SHA256=0`** (Crown default), **`CAD_SUITE_KECCAK256=1`** (triple-address). cad.iii's
  header states the collapse is **seal-drift-free** per suite (suite N is byte-identical to its
  backend).
- **M24#1 done:** 14× `sha256.c` retired.
- **`aether/witness_hook.iii` — REPOINTED (done, this turn):** `wh_compute_frag_id` + chain-root
  now hash via `cad_begin(WH_SUITE_KECCAK)` (:107/314); `at_time` kept in the frag-id (bug-#6 trap
  avoided); M6 redaction built. Compile-verified. Residual: `wh_redact`'s commitment (:221) + the
  selftest still call `keccak256_oneshot` directly.
- **`numera/content_addr.iii` — STILL BUILT** (build_stdlib:362); the M1 retirement target. API
  `ca_compute`(:31)/`ca_compose`(:35)/`ca_branch_key`(:39)/`ca_eq`(:42).
- **3 external `ca_*` consumers, un-repointed:** `aether/memo_query.iii:139` (`ca_compute`),
  `numera/symbolic_regression.iii:1229` (`ca_compute`), `katabasis/seal.iii:22,59` (`ca_eq`).
- **`numera/category.iii` morphism-id, un-repointed:** `cat_compute_word_id` computes
  `Keccak256(src‖dst‖op_word)` via a single `keccak256_oneshot(&CATEGORY_IDPRE,64+wbytes,out)`
  (:166); params pre-concatenated (already spill-safe).
- **~35 modules call `keccak256_*`/`Keccak256` directly** — a triage set (content-address callers
  vs hash-primitive callers).

## §C · Architecture
- **The collapse.** `cad` is the *address discipline* (canonical byte order + domain separation +
  suite tag) over a pluggable, proven NIH backend (SHA-256 / Keccak-256). The hash becomes a
  **suite tag, never a fork in the call graph** (monomorphic if-equality cascade on the tag —
  cad.iii:17, the dispatch tenet).
- **Repoint contracts (all drop-in or byte-identical):**
  - `ca_compute(p,o,i,out)` → `cad_compute(p,o,i,out)` — identical signature.
  - `ca_compose(l,r,out)` → `cad_compose(l,r,out)` — identical.
  - `ca_eq(a,b)` → `cad_eq(a,b)` — identical.
  - content-address via raw `keccak256_oneshot(msg,len,out)` → `cad_oneshot(CAD_SUITE_KECCAK256,
    msg,len,out)` — **byte-identical output** (the digest bytes are the backend's; the suite is
    out-of-band metadata, not hashed in — this is *the* enabling invariant, proven by the
    witness_hook repoint leaving the seal stable).
- **`content_addr.iii` retirement:** after the 3 consumers repoint to `cad_*`, `content_addr.iii`
  is unreferenced → retire (M24), drop from build_stdlib:362. cad subsumes it.
- **The triage rule** (for the ~35 keccak callers): a caller is a **content-address computer**
  (hashes a producer/op/input triple, a Merkle link, an id → **repoint to `cad`**) or a
  **hash-primitive user** (a MAC, a commitment whose spec *is* keccak, or the address primitives
  themselves — `cad.iii`/`keccak256.iii`/`identifier.iii` → **keep**). cad legitimately *wraps*
  keccak256: that is the one path, not a second one.

## §D · Cross-cutting
- **Determinism (the keystone enabler):** `cad_oneshot(CAD_SUITE_KECCAK256,…)` ≡ `keccak256(…)`
  byte-for-byte (cad.iii header; witness_hook proved seal-stable). So **every repoint is
  seal-neutral** — no DRIFT reseal needed for a pure ca→cad / keccak→cad(KECCAK) swap. This is what
  makes mig1 mechanical.
- **Suite-agility (the M1 payoff):** once collapsed, the suite tag gives every name + the whole
  witness history temporal (Q-Day) immunity for free — upstream of M5/M6, no per-module migration.
- **Traps:** cad streaming (`cad_begin`/payload/final) must be spill-safe (M1·D1 — content_addr
  couldn't stream over live params; cad's streaming is module-singleton `CAD_ACTIVE` state, so it
  is). category's repoint stays a oneshot (already spill-safe). KAT-4 (`category` bit-for-bit
  morphism-id) must hold post-repoint — guaranteed by byte-identity.
- **NIH:** cad wraps the hand-rolled in-tree `keccak256.iii`/`sha256.iii`; no third-party path.

## §E · Decisions (ADR-style)
- **ADR-M1.1 — suite-tagged address (SHA default + Keccak alternate), not a single hash.**
  *Rationale:* Q-Day immunity (old names verify under their original suite) — the M1 thesis.
  *Consequence:* a value's name is `(suite,digest)`; +1 tag byte out-of-band. *Accepted.*
- **ADR-M1.2 — exploit byte-identity for a seal-neutral repoint.** *Rationale:* `cad(KECCAK)` ≡
  `keccak256`, so consumers repoint without a reseal (proven by witness_hook). *Consequence:* mig1
  is mechanical, not a determinism event. *Accepted.*
- **ADR-M1.3 — retire `content_addr.iii` (not keep as a shim).** *Rationale:* H2 "one name" +
  H13 "one language" forbid a parallel address module. *Consequence:* 3 consumers must repoint
  first (the falsifier: deleting it while a consumer links it → red). *Accepted.*

## §F · Risks
| Risk | Impact | Mitigation |
|---|---|---|
| A content-address caller mis-triaged (left on raw keccak) | H2 incomplete | the falsifier (mig6 clause) catches any non-`cad` content-address |
| `cad_oneshot` suite tag leaks into the digest bytes | morphism-id / frag-id drift, KAT-4 breaks | **verified byte-identical** (cad header; witness_hook seal-stable); confirm KAT-4 after the category repoint |
| `content_addr.iii` deleted with a live consumer | link failure | retire only after grep proves 0 `ca_*` consumers |
| cad streaming param-spill (M1·D1) | wrong digest, silent | cad streaming is module-singleton state (spill-safe); audit any new streaming call |

## §G · Implementation roadmap (ordered, gated)
1. **✓ DONE (this turn — `--compile-only` verified, byte-identical) — repointed the 3 `ca_*`
   consumers** (content_addr was already folded to `cad`, so this is byte-identical; `memo_query:139`, `symbolic_regression:1229`,
   `katabasis/seal:22,59`): `ca_compute`→`cad_compute`, `ca_eq`→`cad_eq` (extern source
   `content_addr.iii`→`cad.iii`). Build + corpus; **seal stable** (byte-identical).
2. **Repoint `category` morphism-id** (`cat_compute_word_id:166`): `keccak256_oneshot`→
   `cad_oneshot(CAD_SUITE_KECCAK256,…)`. **Verify KAT-4** (corpus `620_category`) bit-for-bit.
   (Naturally lands with mig7, since category is the morphism registry.)
3. **Triage the ~35 keccak callers** per §C; repoint content-address computers; leave primitives.
4. **Retire `content_addr.iii`** (M24): grep 0 `ca_*` consumers → drop build_stdlib:362 + delete.
   Gate: corpus green + seal stable + the M24 byte-equivalence rule.
5. **Land the H2 falsifier as a constitutional clause** (mig6): "no content-address outside `cad`."

---

# MIGRATION 2 — SovVal as a CIC inductive (the keystone: "catastrophe unsayable" → a *type error*)

## §A · Objective + falsifier
**Objective (H6):** the Sovereign Value (M5) becomes a CIC term so that a **non-reachable hexad
(bricking, M3)** and an **over-K cost (M13)** are **type errors** — `sv_op`'s runtime
`SV_STATUS_REFUSED` becomes `iii_term_typecheck` refusing the term. A gap (M4) is an *open term*
(metavariable). **Falsifier:** a bricking or over-K `SovVal` that **type-checks**; a `Hexad` term
whose six trits compose to a non-reachable pattern yet is accepted; any `Type:Type`; a closed
inhabitant of ⊥ → red.

## §B · Current state (investigated 2026-05-25, `TYPES/src/cic.c`)
- **`cic.c` is the C trust root** (H13 carve-out, kept) — a full CIC kernel: β/ζ/δ/ι/η, 7-level
  predicative/impredicative universe (no `Type:Type`), de Bruijn terms.
- **Inductives are a *simple* schema** — `iii_ind_decl_t { iii_ind_id_t id; iii_sort_t sort;
  uint16_t ctor_count; uint16_t ctor_arity[8]; }` (:550–558). Crucially, the comment (:555–557):
  *"we treat all constructor arguments as of type Self-or-payload-primitive"* — **the schema carries
  ctor-arity COUNTS, not per-argument TYPES, and no refinement predicate.** `iii_term_positivity_ok`
  (:577) gates user-defined inductives (always-pass for built-ins).
- **7 built-ins** in `g_inductives[III_IND__COUNT]` (:560–575): Bool(2), **Trit(3)**, **Hexad(1 ctor,
  arity 6 over Trit)**, Phase(4), Tier(4), Epoch(1·1), List(2: nil, cons·2). **Trit + Hexad are
  already inductives** — safety is already typed in the kernel.
- **Type-checker `typeof_rec`** (:646+) uses the existing **Π machinery** (`III_TM_PI`, :667;
  predicative/impredicative sort rules); ctor/match typing emits **`TYPE_PROOF_007_BAD_INDUCTIVE`**
  (:729/736/741/748/761) and `TYPE_PROOF_008_PATTERN_NONEXHAUSTIVE` (:753); ι-reduction at :402.
- **M5's runtime `status`-Refused** (`sovval.iii`, `sv_is_refused` reads `SV_STATUS_REFUSED`) is the
  safe-meanwhile: the value is *sound* now, just refused at runtime, not at type-check.

## §C · Architecture
The objective needs **dependent refinements** (`reach(hexad)=⊤`, `cost≤K`) on the SovVal. The simple
schema (arity counts, no per-arg types, no predicate) cannot express them directly — so there are
two routes, and the choice is the load-bearing decision (ADR-M2.1).

- **Route B (recommended) — Curry–Howard proof-obligation, using the *existing* Π machinery (no
  schema change).** Add three CIC objects:
  1. a **`Cost` inductive** (cic.c has none) — the K-floor carrier;
  2. a **`Reach : Hexad → Prop`** predicate and an **`LeK : Cost → Prop`** predicate (as inductive
     families or as Π-typed propositions reducing to `Bool`-truth via ι);
  3. the **`SovVal` constructor as a dependent function** —
     `sovval : (p:Term) → (h:Hexad) → (w:FragId) → (c:Cost) → Reach h → LeK c → SovVal`.
  To **construct** a SovVal you must supply a `Reach h` proof and an `LeK c` proof. For a **bricking**
  `h` (non-reachable) no `Reach h` term inhabits the type, and for an **over-K** `c` no `LeK c` term
  does — so the SovVal is **unconstructable**: bricking/over-K is a *type error* (the proof obligation
  cannot be discharged), exactly the objective. This is pure CIC (Curry–Howard: the proof is the
  program) and reuses Π + the 7-level universe already in `cic.c`.
- **Binding reach to the kernel.** `Reach h` reduces (ι) to `true` iff `iii_hexad_reachable(h)` —
  i.e., the runtime reach predicate (`hexad_reach.iii`) is mirrored as a kernel-checkable proposition
  (the canonical proof of `Reach h` for a reachable `h` is the ι-normal `eq_refl : reachable h = true`;
  for the 585 non-reachable patterns the equality has no proof). So the M3 144/729 reach becomes the
  *inhabitation* of `Reach`.
- **The runtime ⇄ type-level bridge.** `sv_op` stays as M5 built it (runtime status-Refused = the
  fast path); the kernel SovVal is the *certificate*: an emitted/checked SovVal carries its
  `Reach`+`LeK` proofs, so `iii_term_typecheck` returning `TYPE_PROOF_007_*` *is* the refusal. The two
  agree by construction (both gate on `iii_hexad_reachable` + `cl_le_product`).
- **Gap = open term.** A `Gap` payload (M4) is a metavariable / open term the kernel already
  elaborates — "compute with holes" is the kernel's open-term path, no new machinery.

## §D · Cross-cutting
- **Trust root (H13/T5):** this edits `cic.c` (C). Honest scope — `cic.c` stays the trusted C kernel
  (the `numera/kernel.iii` port is the long-term H13 completion, not faked). The edit is gated by
  cic.c's existing KATs **plus new `TYPE_PROOF_007` negative tests** (a bricking SovVal term MUST
  fail to type-check).
- **Determinism:** `typeof_rec`/`normalize` are pure; adding inductives/propositions doesn't touch
  the seal of the `.iii` archive (cic.c is the kernel, not a stdlib module). No float, no ML.
- **Traps:** N/A at the .iii level (C edit); the C positivity check (`iii_term_positivity_ok`) must
  pass for any *user-defined* form of `Cost`/`Reach` (built-ins skip it).
- **NIH:** no new dependency; all CIC, hand-rolled.

## §E · Decisions (ADR-style)
- **ADR-M2.1 — Route B (Curry–Howard proof-obligation) over Route A (schema extension).**
  *Route A* = extend `iii_ind_decl_t` to carry per-arg **types** + a refinement predicate, making
  `SovVal` a typed record with a kernel-side reach/cost check. *Route B* = leave the schema, express
  the refinement as Π-typed proof obligations (`Reach h`, `LeK c`) the ctor demands. **Decision: B** —
  it is CIC-pure (the kernel *already* has Π + universes; bricking-is-unconstructable falls out of
  inhabitation), avoids mutating the inductive-schema ABI, and makes the guarantee a *theorem* not a
  side-check (Premise-Ledger T1: the facet-law is the typing, not a guard). *Consequence:* the
  `Reach`/`LeK` proofs must be **supplied as closed terms** (T3 — irreducible labor; see §F).
- **ADR-M2.2 — add a `Cost` inductive (the K-floor carrier).** cic.c has Trit/Hexad but no Cost;
  `LeK` needs it. *Accepted.*
- **ADR-M2.3 — keep M5's runtime `status`-Refused as the fast path + safe-meanwhile.** The kernel
  SovVal is the *certificate* (re-checkable); the runtime gate is the hot path. They must agree
  (both on `iii_hexad_reachable`/`cl_le_product`). *Accepted.*

## §F · Risks
| Risk | Impact | Mitigation |
|---|---|---|
| **The proof obligations are real labor (T3)** — `Reach h`/`LeK c` proofs must be *supplied* as closed terms, never axiom/admit | mig2 is the hardest non-XII migration | `cic.c` has no `Axiom`/`admit`, so a faked proof can't type-check (the falsifier is buildable); the `Reach` proof for a reachable `h` is the ι-normal `eq_refl` — mechanical once the predicate is wired |
| Editing the C trust root | a kernel bug undermines *everything* (A1 soundness anchor) | gate on **all** existing cic KATs + new `TYPE_PROOF_007` negatives; no behavior change to the 7 existing inductives |
| Runtime gate ≠ type-level gate (they could diverge) | a SovVal refused at runtime but type-accepted (or vice-versa) | both gate on the *same* `iii_hexad_reachable`+`cl_le_product`; a cross-check KAT (runtime-Refused ⇔ typecheck-fails) |
| Schema simplicity (arity-only) tempts Route A's ABI change | drift in the kernel ABI | Route B avoids it entirely |

## §G · Implementation roadmap (ordered, gated)
1. **Add the `Cost` inductive** to `g_inductives` (:560) (+ `III_IND_COST`, bump `III_IND__COUNT`).
   **Verified site-set (the kernel touch-points adding an inductive must update):** the three
   inductive-kind bounds-checks `cic.c:728/735/747` (`ind_id`/`ctor_ind`/`match_ind >= III_IND__COUNT`
   → `TYPE_PROOF_007`) and the kind switch `:825` (`case III_IND__COUNT: break;`). KAT: a `Cost` term
   type-checks; a malformed one is `TYPE_PROOF_007`.
2. **Wire `Reach : Hexad → Prop`** so `Reach h` ι-reduces to inhabited iff `iii_hexad_reachable(h)`
   (mirror `hexad_reach.iii`'s 144/729). KAT: `Reach (reachable_h)` has a closed proof; `Reach
   (bricking_h)` has none (the negative — prove the negative).
3. **Add `LeK : Cost → Prop`** over the K-floor (mirror `cl_le_product` vs the grant). KAT: over-K
   `LeK c` uninhabited.
4. **Add the `SovVal` dependent constructor** (Route B signature). KAT: a reachable+within-budget
   SovVal type-checks; **a bricking or over-K SovVal FAILS to type-check with `TYPE_PROOF_007`**
   (the keystone negative arm).
5. **Bridge:** emit `sv_op`'s result as a kernel SovVal certificate; add the cross-check KAT
   (runtime `SV_STATUS_REFUSED` ⇔ kernel typecheck-fails). `iii_term_typecheck`'s refusal is now the
   M3/M13 enforcement.
6. **Constitutional clause (mig6):** "no bricking/over-K SovVal type-checks; ⊥ uninhabited." Keep
   `cic.c` as the C trust root; note `numera/kernel.iii` as the long-term H13 completion.

---

# MIGRATION 3 — the `@sovereign` boundary checker (the systemwide lift, H1)

## §A · Objective + falsifier
**Objective (H1):** every datum crossing a `@sovereign` boundary is a Sovereign Value; a raw value
at such a boundary is a **compile error**. This is the "every boundary trades only SovVals"
systemwide lift. **Falsifier:** a `@sovereign` boundary that admits a raw `u64`/pointer (the checker
didn't fire); a raw boundary the checker passes; **the checker exempting itself** (T5 — the checker
is itself a `@sovereign` move) → red. The positive arm: an all-SovVal `@sovereign fn` compiles clean.

## §B · Current state (investigated 2026-05-25, `COMPILER/BOOT/`)
- **The gate machinery exists in `sema.iii`** (the in-language self-host; mirrored by `sema.c`):
  reads **fn modifiers** via `iii_ast_fn_modifier_count`/`_at` (:106–107) and **type modifiers** via
  `iii_ast_type_modifier_count`/`_at` (:115–116); modifier names by offset/length
  (`iii_ast_modifier_name_offset`/`_length`); a **hard-coded inline modifier-name set** (:1133,
  "small set, easier inline than a table"); a **numbered diagnostic table** (:561 — `3→TYPE-HEXAD-001`
  hexad-missing-on-cycle, `4→TYPE-HEXAD-002` hexad-unrepresentable).
- **The reach D-gate exists:** `iii_hexad_packed_admitted(packed:u32)->u8` (:31, from
  `hexad_check.c`/`.iii` — the 144/729 admission bitmap). `TYPE-HEXAD-002` *is already* a compile-time
  type-level reject — **the exact model `@sovereign` extends from cycles to boundary values.**
- **`@sovereign` is net-new** (grep: no `sovereign`/`III_NONSOVEREIGN` in COMPILER).
- **★ The recognition gap (the meticulous finding):** the real M5 (`sovval.iii`) passes SovVals as
  **raw `*u8` cells** with manual offset accessors (`sv_hexad` reads `sv[16..24)`, etc.) — it is
  **not** a `@variant`/named type. So at the boundary `sema` sees `*u8`, **indistinguishable from any
  other `*u8`.** The apotheosis (M5·D1) pairs "`@variant` payload codegen + `@sovereign` boundary
  checker" (and `@variant` is corpus-tested, `110_modifier_variant`), implying SovVal *is* a
  recognizable `@variant` type — which the current M5 is not. **mig3 therefore entails giving SovVal
  a sema-recognizable type before the boundary check can mean anything.**

## §C · Architecture
- **`@sovereign` = a new fn-modifier** + a new diagnostic code. Concretely: add `"sovereign"` to the
  inline modifier-name set (sema.iii:1133); add **`III_NONSOVEREIGN_BOUNDARY`** as the next code in
  the diagnostic table (:561, e.g. `5→"TYPE-SOVEREIGN-001"`); on a fn carrying `@sovereign`, walk its
  param types + return type and emit the code if any is a **non-SovVal** type at the boundary.
- **Resolving the recognition gap (the load-bearing sub-decision, ADR-M3.1):**
  - *Option A — name the type:* M5 exposes a **named `SovVal` type** (a `@variant` tagged union, or a
    distinct nominal type) so a param reads `a : SovVal`, which sema checks against the SovVal type
    id. Cleanest + matches the apotheosis (`@variant`), but **changes M5's `*u8`-cell API** (migrate
    the offset accessors to variant projections).
  - *Option B — a SovVal type-modifier:* keep the `*u8` cell but mark the param's type with a
    `@sovval` type-modifier (sema reads type modifiers, :115–116) that `@sovereign` checks for.
    Less invasive to M5; weaker (a structural tag, not a real type).
  - **Recommendation: A** (named `@variant` SovVal) — H1 wants boundary values to *be* SovVals, and a
    nominal type makes "raw value at boundary" a genuine type mismatch (not a tag convention). It is
    more work (M5 API migration) but is the honest H1.
- **Extends the existing gate, doesn't reinvent it:** `@sovereign` is the same *kind* of D-gate as
  `TYPE-HEXAD-002` (a compile-time type-level reject via `sema`), widened from cycle-hexads to every
  boundary value. The negative test is `corpus/711_neg_nonsovereign_boundary.iii` — a `@sovereign fn`
  with a raw `u64` param that **MUST fail to compile** with `III_NONSOVEREIGN_BOUNDARY` (the
  prove-the-negative arm, wired like the `262_neg_*` family — an expected-compile-failure, not exit 99).
- **Computation inside `apply` is unconstrained** — the contract binds only at the boundary
  (deeper-not-wider; apotheosis T9: scope forced by H1's text, a predicate over values *crossing*).

## §D · Cross-cutting
- **Determinism (the gravest constraint):** a `sema` change must preserve **triple-bit-identity**
  (iiis-0 ≡ iiis-1 ≡ iiis-2) and pass the determinism reseal — adding a modifier + a diagnostic must
  not perturb codegen of existing modules (the modifier is inert unless `@sovereign` is present).
  Run the corpus + DRIFT gate after the sema change (this is a *compiler* change — Directive 7's
  "no redundant rebuild" does NOT apply; a grammar/sema change mandates the corpus regression).
- **The irreducible part (T3′):** after the checker, **every raw-scalar stdlib boundary** migrates to
  SovVal, cluster by cluster (the inside-out Wave A–E order in `III-APOTHEOSIS-PREP.md` §mig3). No
  design removes this labor; the checker makes each un-migrated boundary a **red compile** (mechanical
  progress: remaining = count of `III_NONSOVEREIGN_BOUNDARY` errors).
- **Witness/cap:** N/A (compile-time). **NIH:** sema is in-tree.
- **Traps:** sema.iii is .iii — the full trap catalog applies to the checker code (single-line fns,
  `==`/`!=`, etc.); the new diagnostic string follows the existing table's encoding.

## §E · Decisions (ADR-style)
- **ADR-M3.1 — name the SovVal type (Option A) over a structural tag (Option B).** *Rationale:* H1 is
  "every boundary value *is* a SovVal"; a nominal `@variant` type makes a raw boundary a real type
  error, and matches the apotheosis's `@variant`+`@sovereign` pairing. *Consequence:* M5's `*u8`-cell
  API migrates to variant projections — extra work, sequenced before the boundary migration. *Accepted
  (recommended).*
- **ADR-M3.2 — checker FIRST, then migrate boundaries cluster-by-cluster.** *Rationale:* the checker
  + the `711` negative test land cheaply (extend existing machinery); they then make the irreducible
  migration mechanically visible (red compiles). *Accepted.*
- **ADR-M3.3 — `@sovereign` self-applies (the fixpoint, T5).** `is_sov_morphism`/the checker is itself
  a `@sovereign` move, checked as an instance, never by self-consistency. *Accepted.*

## §F · Risks
| Risk | Impact | Mitigation |
|---|---|---|
| **The recognition gap** — M5's `*u8` cells aren't a type | the checker can't distinguish SovVal from raw `*u8` | ADR-M3.1: name the SovVal type first (Option A); the `@variant` precedent (corpus 110) exists |
| A sema change drifts the seal / breaks triple-bit-identity | the determinism story collapses | the modifier is inert unless present; run the full corpus + DRIFT reseal; verify iiis-0≡1≡2 |
| The boundary migration is enormous (T3′) | the longest-tail effort | inside-out Wave order; W2-aggregate boundaries (one ptr) are a type-swap; progress = red-compile count → 0 |
| Checker exempts itself (T5) | Gödel-unsafe | the checker is a checked `@sovereign` instance, with its own falsifier (a known non-morphism it must reject) |

## §G · Implementation roadmap (ordered, gated)
1. **Name the SovVal type** (ADR-M3.1): M5 exposes `SovVal` as a `@variant`/nominal type; migrate the
   `sv_*` accessors. Gate: `669_sovval` still 99; sovval `--compile-only`.
2. **Add the `@sovereign` modifier** to sema's inline name set (:1133) + **`III_NONSOVEREIGN_BOUNDARY`**
   to the diagnostic table (:561). Inert unless present.
3. **Implement the boundary check:** on `@sovereign` fns, walk param/return types; emit the code on a
   non-SovVal boundary type. Reuse the `iii_hexad_packed_admitted`-style D-gate shape.
4. **Wire `corpus/711_neg_nonsovereign_boundary.iii`** (expected-compile-FAIL) + a positive arm.
   **Run the full corpus + DRIFT reseal**; confirm triple-bit-identity.
5. **Migrate boundaries cluster-by-cluster** (Wave A–E); track remaining = `III_NONSOVEREIGN_BOUNDARY`
   count → 0. H1 holds when 0 + corpus green.
6. **Constitutional clause (mig6):** "no `@sovereign` boundary admits a raw value."

---

# MIGRATION 4 — route all computation through XII (the one engine, H4 — the T4-hardest)

## §A · Objective + falsifier
**Objective (H4):** every computation is evaluated by the **one** XII rewrite engine; confluence
makes order irrelevant, so determinism (Π5) becomes a *theorem about the one engine*, not a per-module
test. The trit ops (M2), gap arithmetic (M4), `sv_op` (M5), the kernel's β/ι (M9), cost reductions
(M13), and the transforms (M17) all become XII rewrite rules. **Falsifier:** a rule that breaks any
critical pair, or fails to strictly decrease the MPO measure; **any term reducing to two distinct
normal forms** → red. This is the single likeliest point of total collapse (Premise-Ledger T4) and
the cheapest falsifier in the system to run.

## §B · Current state (investigated 2026-05-25, `omnia/`)
- **`xii_rewrite.iii` — the engine, BUILT.** Each rule is a **`match_RNNN(t)->u8`** (LHS matches at
  `t`) + **`apply_RNNN(t)->u32`** (rewritten term ref) pair (:20–21). **40 rules R001–R040**, fired in
  **numeric order** in `xii_rewrite_apply_one` (:25). **Termination: every rule strictly decreases
  MPO weight** (S9.3, CRY-XII-TERM-001, :23). Curated commute/compose tables for K05_ACT (R028/R029).
  Operates over `xii_term` (the term arena).
- **`xii_critpairs.iii` — the confluence proof, BUILT.** The 40 rules form **117 critical pairs across
  7 classes** (:8–15): C1 null-position (24), C2 A-vs-Null (12), C3 B-vs-fusion (32), C4 LOOP (12), C5
  IF-vs-L (15), C6 G/H-vs-A (10), C7 witness/SEAL (10). **Theorem CRY-XII-CONF-001: confluent iff all
  117 converge; Newman's lemma + termination ⇒ global confluence** (:21–23). Sealed (`xii_rewrite.mhash`).
- **Today XII evaluates only its own canonicalisation domain** — none of trit/gap/`sv_op`/kernel/cost
  /transforms is yet lowered to rules. So H4 holds *for XII's own domain*; the lift is to fold the
  others in.

## §C · Architecture — the per-family lowering protocol (run for EACH family, never batched)
The engine's structure dictates a fixed, repeatable checklist. For a family F (its k ops):
1. **Express each op as a `match_R(F,i)`/`apply_R(F,i)` pair** over `xii_term` (the existing 40-rule
   form). Start with **M2's 5 trit ops** — smallest, total, and they anchor the critical-pair
   machinery on a provably-confluent micro-set.
2. **Assign each rule an MPO weight that strictly decreases** (RHS < LHS in the MPO order; S9.3).
   A rule that doesn't decrease is **rejected here** (it breaks CRY-XII-TERM-001 / termination).
3. **Wire into `xii_rewrite_apply_one`** at the next numeric slot (R041…R040+N), preserving the
   numeric-order firing.
4. **Re-run `xii_critpairs` over the new 117 + N pairs — ALL must converge.** The N new pairs are F's
   rules' overlaps with the existing 40 *and with each other*, distributed across the 7 classes. A
   **divergent pair = STOP**: orient the rule or add a joining rule before proceeding. **This is the
   gate.**
5. **Add a corpus test per rule** (the USER's sequential 670+ range) + a confluence test exercising
   the new pairs. **Curated-kernel clause (M7/M10):** any curated machine-code kernel for F must be
   **bit-identical to its rewrite normal form** (superopt sound by construction).

**Order (least-risky first):** trit (M2) → gap (M4) → cost (M13) → `sv_op` (M5) → kernel β/ι (M9) →
`cg`/transforms (M17/M18). **Each step ends at a green 117+N critpairs run before the next begins.**

## §D · Cross-cutting
- **Determinism = the objective, not a side-effect.** Confluence (117+N converge) + termination (MPO)
  make XII produce one normal form for any reduction order — Π5 as a *theorem*. This is *why* H4 is
  the deepest determinism guarantee (and `sv_op`'s associativity becomes an XII confluence fact, M5→M12).
- **Seal:** folding rules changes `xii_rewrite.iii` → `xii_rewrite.mhash` drifts → **DRIFT-driven
  reseal is expected and correct** here (an intended change); the gate is the 117+N critpairs + corpus.
- **Traps:** the match/apply bodies are .iii — full trap catalog (single-line fns, `==`/`!=`, no
  `idivq`, byte-stores). The MPO-weight computation must be exact (M4 no-heuristic).
- **NIH:** XII is in-tree; no external rewrite engine.

## §E · Decisions (ADR-style)
- **ADR-M4.1 — lower the families to XII rules (not keep them hand-coded `when`-cascades).**
  *Rationale:* H4 "one engine"; the families' laws (De Morgan, `0·unknown=Known(0)`, `sv_op`
  associativity) become **Knuth–Bendix confluence-checked** by `xii_critpairs`, not merely
  unit-tested. *Consequence:* the 117→117+N re-proof per family (the T4 cost). *Accepted.*
- **ADR-M4.2 — trit (M2) first.** Smallest, total, anchors the critical-pair machinery; pays the M2
  "ops as confluent XII rules" debt first. *Accepted.*
- **ADR-M4.3 — per-family gate, never batch.** Re-run 117+N after *each* family; a batch would make a
  divergent pair impossible to localize. *Accepted.*

## §F · Risks
| Risk | Impact | Mitigation |
|---|---|---|
| **Confluence is NOT modular (T4)** — two confluent rule sets can compose to a non-confluent one | the single likeliest TOTAL design collapse | `xii_critpairs` is the cheapest falsifier in the system; per-family gate localizes the divergent pair; resolve by orientation or a joining rule |
| A folded rule fails to strictly decrease MPO | non-termination (infinite rewrite) | reject at step 2; the MPO measure is exact (CRY-XII-TERM-001) |
| Re-proving 117+N is real work | slow, irreducible | mechanical (the falsifier is runnable); not cheap (T4 honest) |
| A curated kernel ≠ its rewrite normal form | unsound superopt | the M7/M10 promotion clause (bit-identity) gates it |

## §G · Implementation roadmap (ordered, gated)
1. **trit (M2):** 5 match/apply rules, MPO-assigned; wire into `apply_one`; **re-run 117+N → green**;
   corpus tests. (Anchors the machinery.)
2. **gap (M4):** gap-propagation + `0·unknown=Known(0)` + `÷0→gap` as rules; re-run; green.
3. **cost (M13):** lattice-join reductions as rules; re-run; green.
4. **`sv_op` (M5):** the four-facet compose as rules → its associativity becomes an XII confluence
   fact (feeds M12/cat_check_assoc); re-run; green.
5. **kernel β/ι (M9):** the cic.c reduction as XII rules (the M7-promise + mig2 synergy); re-run; green.
6. **`cg`/transforms (M17/M18):** codegen as XII-emit; re-run; green. Each step **DRIFT-reseals** +
   passes corpus. **Constitutional clause (mig6):** "all 117+N critical pairs converge; no term has
   two normal forms."

---

# MIGRATION 5 — SID inverse-in-witness + type-level `Compromise` (H9 — the rename already landed)

## §A · Objective + falsifier
**Objective (H9):** every effect is exactly one of — **reversible** (a SID-derived inverse
round-trips), **typed-irreversible** (`Compromise<LOW|MED>`), or **unrepresentable**
(`Compromise<HIGH>` = bricking, M3 `reach` forbids construction). The derived inverse **rides the
witness fragment**, so rollback is replaying the witness chain backward (inverse
*derived/recorded-in-chain, not separately logged* — no extra log). **Falsifier:** a forward op whose
derived inverse fails to round-trip; an irreversible op with **no** `Compromise` tier; a
`Compromise<HIGH>` value that constructs; the name `sid` bound to two modules → red.

## §B · Current state (investigated 2026-05-25)
- **The collision-clear is DONE (P1, verified):** `omnia/sid` → `omnia/crystal_deps`; ADR-027 confirms
  the rename was seal-neutral. The *last* falsifier clause above is already green.
- **★ Two distinct inverse domains exist (the meticulous finding):**
  - **`COMPILER/BOOT/sid.iii` — the METAL/katabasis inverse derivation (Ring R-2/-1).** Processes a
    privileged "cycle" (`sid.c::sid_process_cycle` wire format, byte-exact) and derives the inverse of
    **17 privileged side-effect kinds** — `SID_SE_MSR_WRITE`/`CR_WRITE`/`NPT_ENTRY_WRITE`/
    `VMCB_FIELD_WRITE`/`IOMMU_DTE_WORD`/`AVIC_TBL_WRITE`/`MSRPM_BIT_SET`/`IOPM_BIT_SET`/`PKRU_WRITE`/
    `XCR0_WRITE`/`CAP_ACQUIRE`/`CAP_RELEASE`/`PAGE_ALLOC`/`PAGE_FREE`/`DPC_ARM`/`DPC_CANCEL`/
    `NMI_INSTALL` (:40–57), with an **`irreversible` flag** (wire offset 9/16) marking ops with **no
    derivable inverse** — the `Compromise` seed.
  - **`numera/reversible.iii` — the RUNTIME transactional inverse (Ring R0).** A LIFO of
    `(tag,a,b,c,d)` undo records (`REV_REC_TAG/A/B/C/D`, 8192; tags `REV_TAG_MEM_RESTORE_U8/U64`/
    `DROP_BIGINT`/`RELEASE_SLOT`/`WITNESS_REVOKE`), `rev_invoke_undo(fn,a,b,c,d)`, **already
    witnessing** commit/rollback via `wh_publish`.
  - **`omnia/hexad_mobius.iii`** — the inverse projected onto the M3 safety lattice.
- **The carrier exists:** `wh_publish`'s **`revtag: u8`** (the M8 tag) + `payload` can carry the undo
  record; the constitution VM reads the tag via **`COP_REVTAG_EQ`** (M10). These three are **not yet
  unified** into one inverse concept on the witness chain.

## §C · Architecture
- **One inverse concept, two domains, one carrier.** BOOT-`sid` *derives* the inverse at
  compile/process-cycle time (metal); `reversible` *records* the `(tag,a,b,c,d)` undo (runtime); both
  are written **into the witness fragment** (M6) via `revtag` + payload. **Rollback = walk the witness
  chain backward**, replaying each fragment's embedded inverse via `rev_invoke_undo`. So `reversible`'s
  `REV_REC_*` LIFO becomes a **view over a witness-chain segment**, not a separate store — the inverse
  costs no extra log.
- **The 3-way classification (the unifying M10 clause):** **reversible** = an invertible `SID_SE_*`
  (metal) or `REV_TAG_*` (runtime) whose `rev_invoke_undo` round-trips; **typed-irreversible** =
  BOOT-`sid`'s `irreversible` flag → `Compromise<LOW|MED>` (the `COP_REVTAG_EQ` opcode reads exactly
  this tier); **unrepresentable** = `Compromise<HIGH>` = bricking, **M3 `reach` forbids construction**
  (ties to mig2 — a HIGH SovVal doesn't type). `hexad_mobius` = the same inverse projected on the
  safety lattice (M3 debt paid).

## §D · Cross-cutting
- **Two rings, one chain:** BOOT-`sid` is R-2/-1 (katabasis metal); `reversible` is R0; the **witness
  chain (M6) is the ring-agnostic carrier** unifying them (a metal inverse and a runtime undo are both
  backward witness fragments).
- **Determinism:** rollback replays the chain from seed — a total function of the seed (Π5 auditable,
  via M6's replay verifier).
- **Seal:** rename was seal-neutral (P1/ADR-027); wiring the inverse into `wh_publish` payloads is a
  `reversible`/`witness_hook` change → DRIFT reseal as intended; gate on `634_reversible` + `633`/`382`.
- **Traps:** `reversible.iii` is .iii (`(tag,a,b,c,d)`=4×u64, byte-store discipline); BOOT-`sid` mirrors
  the C wire format byte-for-byte. **NIH:** inverse derived, never an external diff.

## §E · Decisions (ADR-style)
- **ADR-M5.1 — derived/recorded-in-chain inverse, not a separate undo log.** *Rationale:* the inverse
  is derivable, so reversible time-travel costs no extra log; the chain is already the record.
  *Accepted.*
- **ADR-M5.2 — the `revtag` byte carries the 3-way tier**, read by `COP_REVTAG_EQ`. *Accepted.*
- **ADR-M5.3 — unify metal (BOOT-sid) + runtime (reversible) via the witness chain, not by merging the
  modules** (different rings, different effect kinds; a fragment is ring-agnostic). *Accepted.*

## §F · Risks
| Risk | Impact | Mitigation |
|---|---|---|
| Metal (R-2) and runtime (R0) domains are genuinely different | a forced merge breaks one | unify via the witness chain, not by merging modules (ADR-M5.3) |
| A derived inverse that doesn't round-trip | rollback corrupts state | round-trip KAT per effect kind (the 17 `SID_SE_*` + the `REV_TAG_*`) |
| An irreversible op with no `Compromise` tier | silent irreversibility (H9 hole) | BOOT-`sid`'s `irreversible` flag MUST map to a tier; the clause catches an untiered op |
| `Compromise<HIGH>` constructs | bricking sayable | M3 `reach` + mig2 (HIGH doesn't type) |

## §G · Implementation roadmap (ordered, gated)
1. **(DONE) rename** `omnia/sid`→`crystal_deps` (P1).
2. **Wire the inverse into the witness fragment:** reversible forward op → `wh_publish` with the
   `revtag` tier + the `(tag,a,b,c,d)` undo in the payload. Gate: `634` + `633` green.
3. **Rollback = backward chain replay** via `rev_invoke_undo`; `REV_REC_*` becomes a chain view.
   Round-trip KAT per effect kind.
4. **The 3-way classification clause (mig6):** BOOT-`sid` `irreversible` → `Compromise` tier;
   `COP_REVTAG_EQ` reads it; untiered irreversible → red; `hexad_mobius` = lattice projection.
5. **Tie `Compromise<HIGH>` to mig2** (a HIGH SovVal is unrepresentable — doesn't type-check).

---

# MIGRATION 6 — `run_charter()` + falsifier-per-clause, the build's terminal gate (H7)

## §A · Objective + falsifier
**Objective (H7):** the Constitution becomes the **single** authority over every guarantee, each
clause carrying its **falsifier** (`HOLDS = verify ∧ falsify`); `run_charter()` runs them all, seals
the verdict vector into one charter seal, and is the build's **terminal gate** — green only if every
clause holds, every falsifier catches its bad case, and the seal equals golden. **Falsifier:** a
guarantee with no clause; a clause with no falsifier bytecode; a `falsify` predicate that passes on
its own bad witness (vacuous); an LTL field that never reaches the model checker; a `run_charter`
**green under injected corruption** → red.

## §B · Current state (investigated 2026-05-25, `numera/`)
- **`constitution.iii` — BUILT** (`632_constitution=99`). The **11-opcode admissibility VM**:
  `COP_TRUE/FALSE/AND/OR/NOT` (combinators) + `COP_PRODUCER_EQ`/`COP_OP_EQ`/`COP_REVTAG_EQ`/
  `COP_PHASE_GE`/`COP_PILLAR_EQ`/`COP_HAS_ANTE` (predicates that read a witness fragment's facets)
  (:67–77). `cons_eval_predicate(slot, opv, ante_ids, n_ante) -> u8` (:569). The `clause_payload`
  schema (:32) is `clause_id(32) | textual_len | textual | ltl_len | ltl | …` — it **carries the LTL
  field**, stored in `CONS_LTL_OFF`/`_LEN`/`_BUF` (:85–94). `cons_find`/`cons_init`;
  `CONS_MAX_CLAUSES=1024` (W8), 1 MiB `CONS_LTL_BUF`. Ratification publishes a `CLAUSE_RATIFICATION`
  witness fragment (M6).
- **`temporal_logic.iii` — BUILT** (`644`). The **bounded model checker exists**:
  `tl_eval(slot, chain_start, chain_end, position) -> u8` (:434), `tl_holds_on_segment(slot, start,
  end) -> u8` (:449), formula builders (`tl_append_atom/not/bin/unary_temp`, `tl_set_root`), and
  `tl_eval_atom` references **constitution predicates** at link time (:473) — so LTL atoms *are*
  constitution predicates over the chain.
- **The three gaps (= apotheosis M10·D1, grep-confirmed):** **(a) no falsifier field** per clause
  (`falsif` → 0 hits); **(b) no `cons_run_charter`** (0 hits); **(c) the LTL field is carried but
  never folded** into a gate (the model checker exists but the clause's `ltl` field isn't run through
  it). The positive corpus, the `NNN_neg_*` falsifiers, the drift gates, and the closure meta-gate
  run **separately**, not under one conscience.

## §C · Architecture
- **(a) Falsifier bytecode per clause.** Add a **second 11-opcode predicate** to the `clause_payload`
  schema (the same VM, no new opcodes). Then **`HOLDS = cons_eval_predicate(verify, w) ∧
  cons_eval_predicate(falsify, w_bad)`** — the clause must *catch* a constructed bad witness, not
  merely pass a good one. This makes "prove the negative" structural in the conscience.
- **(b) `cons_run_charter()`** (existing `cons_` prefix — **no new namespace reservation**): iterate
  all live clauses, evaluate `verify ∧ falsify`, **seal the verdict vector into one charter seal**,
  and **fuse the four legacy suites** — the positive corpus, the `NNN_neg_*` falsifiers, the drift
  gates, the closure meta-gate — into one terminal verdict. Red unless all hold + all falsifiers
  catch + the seal equals golden (DRIFT-reseal on intended change).
- **(c) LTL activation — the machinery already exists.** For each clause with an `ltl` field
  (:32/CONS_LTL_BUF), build the `tl` formula (`tl_append_*`) and evaluate via
  **`tl_holds_on_segment(slot, chain_start, chain_end)`** over the replayable `algebraic_time` chain
  (M21). The atoms are constitution predicates (already linked, :473). "The seal is *always*
  reproducible"; "a red verdict *eventually* quarantines (M20)."
- **Every prior module's falsifier becomes a clause:** M1 (no digest outside cad — mig1) … M9 (⊥
  uninhabited — mig2) … the M4/M5 KAT falsifiers, the H1 `@sovereign` falsifier (mig3), the H4
  117+N-converge falsifier (mig4), the H9 round-trip falsifier (mig5). The Constitution becomes the
  **union of all module falsifiers** — the system auditing itself. **OBSERVATORY (M28) families +
  immune (M20)** register as clauses (the red→quarantine→bone_marrow loop).

## §D · Cross-cutting
- **The charter seal IS the behavioral quine-seal** — sealed over source + emitted code (M9/M18) +
  the verdict vector — so the Constitution proves "this is the auditor this seal describes",
  Gödel-safely (instance check, never self-consistency — T5).
- **Determinism:** the verdict vector is a deterministic fold; `run_charter` reseals (DRIFT-driven)
  only on intended change; this is the build's terminal gate (the existing corpus + mhash + neg-arm
  practice, mechanized into one light).
- **The authoring loop (The Move · D1):** write the **bad move first** (the case that must be
  refused); `run_charter` is both the test and the ship-gate — no gap between "passes my tests" and
  "is admissible."
- **Traps:** `constitution.iii` is .iii (the falsifier bytecode follows the existing schema encoding;
  the LTL window indices are u64 — unsigned compares safe). **NIH:** the VM + tl_eval are in-tree.

## §E · Decisions (ADR-style)
- **ADR-M6.1 — falsifier as a 2nd 11-opcode predicate (reuse the VM), not a new mechanism.**
  *Rationale:* the VM already reads SovVal facets; a paired predicate is the minimal, uniform way to
  encode `verify ∧ falsify`. *Accepted.*
- **ADR-M6.2 — `run_charter` fuses the 4 legacy suites into one sealed verdict** (not keep them
  separate). *Rationale:* H7 "one conscience" — one green/red light anyone can run. *Accepted.*
- **ADR-M6.3 — LTL via the existing `tl_eval`/`tl_holds_on_segment`** (not a new model checker).
  *Rationale:* the bounded MC is built (corpus 644) + already links constitution predicates; mig6 only
  wires the clause `ltl` field in. *Accepted.*

## §F · Risks
| Risk | Impact | Mitigation |
|---|---|---|
| **Deferral falsifiers (T6)** — a deferral's "safe meanwhile" clause that passes on its own bad case | the **one place unsoundness hides behind a green board** | deferral falsifiers are the **highest-scrutiny** clauses; each must catch its own violation (P4's defer-ledger discipline) |
| A `falsify` predicate vacuously passes on `w_bad` | a guarantee that doesn't actually guard | the meta-falsifier: `run_charter` green under injected corruption → red (the falsify must *catch* the injection) |
| Fusion incompleteness (a guarantee with no clause) | a silent un-audited path | the H7 falsifier: "a guarantee with no clause"; enumerate every module's falsifier as a clause |
| The seal fails to reseal on intended change / drifts silently | the determinism story | DRIFT-driven reseal; golden = BARE mhash; the seal covers source+emitted+verdict |

## §G · Implementation roadmap (ordered, gated)
1. **Add the falsifier bytecode field** to the `clause_payload` schema (2nd 11-opcode predicate).
   KAT: a clause whose `falsify` passes on its `w_bad` is rejected.
2. **Write `cons_run_charter()`:** fold `verify ∧ falsify` over all clauses → sealed verdict vector;
   fuse positive corpus + `NNN_neg_*` + drift + closure. KAT: green on a clean tree; **red under an
   injected corruption** (the meta-falsifier).
3. **Wire the LTL fold:** each clause's `ltl` field → `tl_holds_on_segment` over the `algebraic_time`
   chain. KAT: "always-reproducible-seal" temporal clause holds; a violated one reddens.
4. **Register every module's falsifier as a clause** (M1–M9 + the migration falsifiers) + OBSERVATORY
   (M28) families + immune (M20). 
5. **Make `run_charter` the build's terminal gate** — red unless all hold + all falsifiers catch +
   seal = golden. This is H7; it also lands the constitutional clauses for mig1/2/3/4/5 (each
   migration's falsifier).
