# HERMENEUS — the English-to-EIDOLOS front-end (design spec)

- **Date:** 2026-07-19
- **Status:** DESIGN — architecture approved (hybrid muse; name HERMENEUS; self-proof required for *both* proposer backends). **Not yet implemented.** This document is a plan; every "proves"/"is exact" below is a claim about code to be written, to be discharged by `hermeneus_selfprove` at build time.
- **Organ (planned):** `STDLIB/iii/omnia/hermeneus.iii`
- **Charter (planned, on landing):** `DOCS/III-HERMENEUS-CHARTER.md`
- **Ring:** R0. **Hexad:** `kind_passage` (a meaning crosses the membrane) + `kind_witness`.

---

## 1. The gap this closes (stated precisely)

Two halves of the pipeline are already proven, and they meet nowhere:

- **The exact middle & back-end.** `omnia/diadosis.iii` takes claims *already* in EIDOLOS
  `[ thing verb thing ]` form, reduces them to the minimal basis, content-addresses the reduced
  house, ripples a bounded handle, and lets any consumer reconstruct the identical closure —
  `closure(B) = closure(G)`, delivery bit-faithful (`diadosis.iii:95–151`). Beneath it,
  `omnia/eidolos.iii` is the language itself: `<` **under** · `=` **is** · `~` **mirrors**;
  canonical spelling → address. **Both consume claims that are already EIDOLOS.**
- **The two membranes that don't cross meaning.** `aether/xenos.iii` is the "one door," but it
  admits foreign **JSON** and transduces its *structure* (containment → `<`); an English word it
  cannot read as a lawful token becomes an opaque fold `x H L` — it moves shape, not meaning.
  `omnia/mantis.iii` consults the R1 oracle but emits provenance scrolls `[answer < consult]`,
  not translations.

**Missing:** the step that turns an English **sentence** into **semantic** claims whose verb
(`<`/`=`/`~`) reflects the sentence's actual relation. That is the front-end. HERMENEUS is it.

---

## 2. The one law the front-end obeys

> The statistical part may **propose**; only the exact law plus a human **decides**.

Not a single epsilon of hallucination may enter the exact core. This is already the tree's ethos
in three built places, which HERMENEUS **composes** (it adds no new island, no new inference):

- **MANTIS's WALL** — a provisional oracle reading can inform, seed, be remembered and spoken, but
  never silently becomes the canonical proven self (`admit_canonical` is default-deny).
- **XENOS's re-derivation** — the foreign is judged by the house's own re-derivation, never by
  trust in the input's shape; `lx_check` names any alien word; every refusal is named and counted.
- **DIADOSIS's exact reduction** — closure-preserving minimal basis, faithful content-addressed
  delivery.

---

## 3. The organ: five faculties

| # | Faculty | What it does | Reused proven pattern |
|---|---------|--------------|-----------------------|
| 1 | **PROPOSER** (the muse, *provisional by construction*) | English utterance → *candidate* claims | MANTIS wall (provisional tier) |
| 2 | **VETTING** (exact law, before the human looks) | candidate must be a coherent scroll (`eol_read`/`eol_addr`; no cycle/self-under) and its words audited (`lx_check`); else refused + counted | XENOS re-derivation + lexicon |
| 3 | **READ-BACK** (claims → English gloss) | render each claim to canonical English so the human confirms *meaning*, not brackets | new; inverse of the deterministic proposer |
| 4 | **CONFIRM-GATE** (the quarantine) | a vetted proposal stands PROVISIONAL; only a recorded human "confirm," content-addressed to *exactly* the proposal it approves, promotes it | MANTIS pin + default-deny |
| 5 | **DELIVERY** (the seam) | on confirm, claims enter DIADOSIS — proven exact from here | DIADOSIS hand-off |

**Data flow:**

```
English
  │
  ▼
[1 PROPOSER]───────────────┐  (deterministic in-house grammar)
  │  candidate claims       │
  │  (PROVISIONAL)          └──[1' EXTERNAL DOOR]  (any LLM's JSON proposal, admitted via XENOS law)
  ▼
[2 VETTING]  eol coherence + lx_check vocabulary → refuse+count on failure
  │
  ▼
[3 READ-BACK]  claims → canonical English gloss
  │
  ▼
  HUMAN  reads English-in beside English-out, confirms or rejects
  │
  ▼
[4 CONFIRM-GATE]  pin = cad(english ‖ addr); default-deny without a matching confirm
  │
  ▼
[5 DELIVERY] ──► DIADOSIS.reduce → publish (content-addressed) → ripple (bounded handle)
                 (already proven: closure(B)=closure(G), faithful delivery)
```

---

## 4. The hybrid muse and its **asymmetric** self-proof (the crux)

**Principle:** *A muse cannot be proven honest. The quarantine that makes a dishonest muse harmless
CAN be proven — and is, at every invocation.* The two backends differ only in how much **more**
than the shared quarantine each can prove about itself.

### 4a. Deterministic proposer (`hm_propose_det`) — proves the most

A small, exact pattern grammar over the **unambiguous fragment** of English. It is a *known finite
function*, so it can prove properties of itself:

Canonical patterns (the birth fragment — grows only by earned patterns, never by guessing):

| English template | Claim | Verb |
|------------------|-------|------|
| `A before B`, `A must be proven before B`, `A precedes B`, `A is under B` | `[A < B]` | `<` under |
| `A is B`, `A equals B`, `A is exactly B` | `[A = B]` | `=` is |
| `A mirrors B`, `A is the dual of B`, `A reflects B` | `[A ~ B]` | `~` mirrors |

`A` and `B` are noun phrases reduced to lawful EIDOLOS words/measures by the same `xn_word_lawful`
quotient XENOS already uses (case-fold, single-space tokens; anything not a lawful phrase makes the
*whole* utterance unrecognized — never a silently-mangled claim).

What it proves about **itself** (beyond the shared quarantine in §4c):

- **Exactness on its domain** — for each canonical template `Eᵢ`, `hm_propose_det(Eᵢ)` emits exactly
  `[claimᵢ]`, verified by `eol_addr` equality against the hand-written claim.
- **Total refusal off-domain** — an utterance matching no template emits **zero** claims and
  increments `hm_rgrammar`. This is the zero-hallucination property, *proven*: the proposer never
  invents a claim from English it did not recognize.
- **Determinism** — same utterance twice → same address.

### 4b. External door (`hm_admit_ext`) — proves *only the door*, never the muse

Any out-of-tree LLM proposes a translation as JSON:

```json
{ "speak": "hermeneus", "english": "dream must be proven before it becomes law",
  "claims": ["[dream < proof]"], "address": <D> }
```

Admitted through XENOS discipline (reuse `aether/xenos.iii` where possible; a `hermeneus`-tagged
envelope so it is not confused with a raw `eidolos` guest). What it proves:

- **Re-derivation** — a truthful proposal re-derives its stated address `D`; the claims are a
  coherent scroll. It is left **PROVISIONAL**.
- **Refusal, named** — a lying address → `lying`; incoherent/cyclic → `cycle`; alien vocabulary →
  flagged by `lx_check`; a foreign axiom → `soul`; over-envelope → `throat`.
- It makes **no** claim about whether the English was translated correctly. The muse is a black
  box; the door is not. Translation quality is the human's judgment alone.

### 4c. The shared quarantine theorems (the real guarantee — both backends)

1. **Inverse round-trip** (read-back faithfulness). On the fragment, `hm_gloss` (claim→English) and
   `hm_propose_det` (English→claim) are mutual inverses:
   - `parse(gloss(C)) ≡ C` by address, for every `C` the proposer can produce;
   - `gloss(parse(E)) ≡ E` canonically, for every `E` in the recognized domain.
   Non-tautological: it forces gloss and grammar to agree, so the English the human confirms means
   *exactly* the claim that will cross. (Kin to the intent ⊣ intuition adjunction already in tree.)
2. **The wall** (no back-channel to the core). Delivery is a total function of (standing proposal,
   matching confirm):
   - `hm_deliver()` before any confirm → DENIED; DIADOSIS untouched.
   - `hm_confirm(p)` yields pin `= cad(english_p ‖ addr_p)`; a different proposal `p′` → a different
     pin. A confirm for X cannot release Y.
   - `hm_deliver()` with standing proposal == the confirmed one → PERMITTED; otherwise → DENIED.
3. **Seam-exactness** (HERMENEUS is a pure gate). For any confirmed claim-set `S`,
   `addr(DIADOSIS.reduce(S via hermeneus)) == addr(DIADOSIS.reduce(S fed directly))`
   (`dd_reduce_addr`). The front-end adds nothing and loses nothing; it only *gates*.
4. **Vetting** — a cyclic proposal is refused `cycle` (DIADOSIS never reached); an alien-word
   proposal has its first undefined word named by `lx_check`; a well-formed one derives its address
   and stands PROVISIONAL.
5. **End-to-end closure** — a derivable/dropped original claim is still entailed after the full
   English → confirm → DIADOSIS pipeline (the DIADOSIS closure theorem, lifted through the gate).

---

## 5. `hermeneus_selfprove` — the condition of motion (no gate, no KAT)

One `@export fn hermeneus_selfprove() -> u64` re-derives every law above at every invocation,
returning `0` on green and the failing arm number otherwise (the DIADOSIS/XENOS idiom). It is
**pure** — it needs no external muse and no weights to prove the *discipline* (the deterministic
proposer, the read-back inverse, the wall, the seam). An absent external muse is a lawful **fast**,
exactly as an absent Feast is for MANTIS. Draft arm map (final numbering fixed in the plan):

- **1–3** deterministic exactness: each verb's canonical template → its exact claim address.
- **4** total refusal off-domain (`hm_rgrammar` bumped, 0 claims).
- **5** determinism (same English twice → same address).
- **6–7** read-back inverse both directions (`parse∘gloss` and `gloss∘parse`).
- **8** vetting refuses a cycle; **9** vetting names an alien word.
- **10** external door admits a truthful proposal (re-derives its address, PROVISIONAL).
- **11** external door refuses a lying address (`hm_rlying`).
- **12** wall: `hm_deliver` before confirm is DENIED.
- **13** pin: confirm is content-addressed to its proposal; different proposal → different pin.
- **14** wall: `hm_deliver` after a *mismatched* confirm is DENIED.
- **15** release: `hm_deliver` after the *matching* confirm is PERMITTED.
- **16** seam-exactness: delivered address == `dd_reduce_addr` of the raw claims.
- **17** end-to-end closure: a dropped original claim still entailed at the consumer.
- **18** negative wall: a claim outside the confirmed closure is not delivered-as-known.

Each arm compares independently-derived quantities (addresses, pins, counters) — none is
tautological.

---

## 6. Interfaces (units and their boundaries)

Each unit answers *what it does / how you use it / what it depends on* without exposing internals.

- `hm_propose_det(english: u64, len: u64) -> u64` — deterministic muse; fills the candidate scroll,
  returns claim count (0 = refused, `hm_rgrammar` bumped).
- `hm_admit_ext(json: u64, len: u64) -> u64` — external-muse door; verdict surface mirrors XENOS
  (`hm_ext_verdict`, `hm_ext_reason`, `hm_ext_addr`).
- `hm_vet() -> u64` — vet the standing candidate (0 = coherent+audited; else a named reason).
- `hm_gloss(claim_base: u64, claim_len: u64, out: u64) -> u64` — render one claim to English.
- `hm_readback(out: u64) -> u64` — gloss the whole standing candidate for the human.
- `hm_confirm(english: u64, len: u64, addr: u64, out_pin: u64) -> u32` — record a human confirm;
  returns 1 iff it matches the standing proposal, writing the content-addressed pin.
- `hm_deliver() -> u64` — release the confirmed proposal into DIADOSIS; returns the DIADOSIS
  handle, or the wall sentinel if unconfirmed/mismatched.
- `hm_selfprove() -> u64 @export`, `hm_show() -> i32 @export` (the live demo), plus accessors and
  the named refusal counters below.

---

## 7. Composition & purity

Imports (all already in the house — NIH clean, no new inference):

- `omnia/eidolos.iii` — the tongue (`eol_read`/`eol_keep`/`eol_reduce`/`eol_judge_claim`/`eol_addr`/
  `eol_witness`/`eol_verify`/`eol_write`).
- `omnia/diadosis.iii` — the proven back-end (`dd_reduce_addr`, `dd_publish`, `dd_resolve`,
  `dd_ripple`, `dd_consumer_entails`). **These are not `@export` today** — only
  `diadosis_selfprove` consumes them, which is exactly the island MANTIS's header warns against.
  Composing DIADOSIS therefore requires promoting those five faculties to `@export`: a minimal,
  purely additive change (no logic touched), each new export consumed by HERMENEUS and covered by
  a self-prove arm, so the ratchet stays clean.
- `verba/lexicon.iii` — `lx_check` and the alien-word readout.
- `aether/xenos.iii` — the external-muse door, **reused unchanged**: the muse emits an UNSIGNED
  claim-array `["[dream < proof]", …]` (or a CONFORMING envelope), `xn_admit` vets it by the house's
  own re-derivation and leaves the admitted claims standing in the eidolos state; HERMENEUS reads
  them via `eol_kept_claims`/`eol_kept_claim_base` and glosses them *itself* for read-back (so the
  human sees III's own reading of the muse's claims, not the muse's self-description). No XENOS edit.
- `numera/idfold.iii` — the pin (`cad(english ‖ addr)`), folded exactly as XENOS folds names.

The system speaks the language; the language never leans on the system: HERMENEUS imports no ground
organ, no faculty, no parser.

---

## 8. Envelopes (named, counted — never silent)

Bounds mirror EIDOLOS/XENOS: candidate ≤ 256 claims; utterance ≤ 16384 bytes; gloss ≤ 24576 bytes;
one external envelope ≤ 16384 bytes. Every refusal lands in a named counter:
`hm_rgrammar` (off-domain utterance), `hm_rcap` (over an envelope), `hm_rlaw` (incoherent scroll),
`hm_ralien` (alien vocabulary), `hm_rlying` (external stated-address mismatch),
`hm_rwall` (delivery attempted unconfirmed/mismatched).

---

## 9. Honest scope (matching the EIDOLOS charter's own)

Pure `.iii` **cannot** "understand arbitrary English," and this spec claims no such thing. It **can**
(a) exactly translate an unambiguous fragment, and (b) safely quarantine an external muse's guesses
everywhere else. No claim of comprehension — a claim of **exact translation where provable, exact
quarantine otherwise**. Mechanism novelty: none claimed (pattern grammars, content addressing,
human-in-the-loop confirmation, provisional/canonical firewalls are all decades-old). What is III's
own is the *unification*: one door where a fallible muse's proposal is judged by the house's own
re-derivation, glossed back for a human, quarantined behind a pinned confirm, and delivered into a
back-end already proven exact — with the whole discipline re-proven as a condition of motion.

---

## 10. Open design choices (to settle in the plan)

1. **External door: reuse `xenos.iii`.** *Resolved:* reuse `xn_admit` **unchanged** — the muse
   emits an UNSIGNED claim-array (or a CONFORMING `speak:eidolos` envelope), XENOS vets it by
   re-derivation and stands the claims; HERMENEUS reads the standing claims and glosses them itself.
   No new envelope grade, no XENOS edit. (A `hermeneus`-tagged envelope was considered and rejected:
   it would fall through XENOS as a STRANGER and be transduced structurally, not semantically.)
2. **Confirm persistence: in-memory vs a guest-book file.** *Recommendation:* mirror `xenos.gbk` —
   a self-verifying EIDOLOS event line per confirm/reject (`STDLIB/data/hermeneus.gbk`), so the
   quarantine's history is auditable and tamper-evident, not process-local state.
3. **Deterministic grammar's fragment scope.** *Recommendation:* birth with the three verbs'
   canonical templates only (§4a table); grow strictly by earned patterns, each added with its own
   exactness + refusal arm. Never widen coverage by relaxing refusal.

---

## 11. Verification & landing

- `hermeneus_selfprove` green (arms of §5) as the condition of motion — pure, runs on any machine.
- `hm_show` live demo: an English sentence → candidate → read-back → (simulated) confirm →
  DIADOSIS handle, printed end to end.
- Wire into the standing-tools evergreen gate alongside diadosis/xenos, prose and exits unchanged.
- On green: write `DOCS/III-HERMENEUS-CHARTER.md` and add the memory pointer.

---

## 12. What this explicitly does NOT do

- It does not put the statistical translator *inside* III (the deterministic proposer is not
  statistical; the external muse lives out of tree).
- It does not auto-cross any proposal — human confirm is mandatory, mechanized by the wall.
- It does not change any DIADOSIS or EIDOLOS *behavior*. The only edit to an existing organ is
  promoting DIADOSIS's five faculties to `@export` (additive, arm-covered) so the proven back-end
  can finally be composed instead of remaining an island. XENOS and EIDOLOS are untouched.
