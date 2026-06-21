# III — Legacy Structure vs Inverse Structure
### How a state-primary `.iii` module differs from an event-primary inverse-substrate organ — and why both coexist
> **Date:** 2026-06-20 · **Author pass:** /deep-think · advisor-reviewed
> **Grounded in (read top-to-bottom):** legacy — `omnia/ripple_field.iii`, `omnia/vec.iii`,
> `numera/reversible.iii`, `omnia/crystal.iii`; inverse — `omnia/event_substrate.iii`, `omnia/isub.iii`,
> `omnia/dome.iii` (+ `III-EVENT-SUBSTRATE.md`, `III-DOME.md`, `III-INVERSE-LIBRARY.md`, `III-TRAJECTORY-AUDIT.md`).
> **Companion:** `III-COMPONENT-AUTHORING.md`.

---

## 0. THE FRAME — different, not better; coexisting, not superseding

This is **not** "old crude way → enlightened new way." The III source is emphatic that the inverse form is
a **different competence**, not a superior one (`III-DOME.md §1`: *"This is not 'the inverse form is a
better decider'"*; on the parity wall the **determinist wins** — control is the theorem's turf). The vast
majority of III is legacy state-primary and **stays** that way: an event-sourced `vec` would be absurd
overhead. The inverse substrate is a **specialized substrate for one region of competence** — reversible,
provenance-carrying, counterfactual-bearing deliberation / search / assimilation — and it **encapsulates**
the incumbent rather than replacing it (`xii_isub` *drives* the real `xii_rewrite`; it does not reimplement
it).

So read every row below as **"where the source of truth lives and what that buys / costs,"** never as a
quality ranking.

**Two traps this document refuses** (both refuted by the primary source it cites):
- *"Legacy is impure / crude."* False. `ripple_field` is **K=1.00**, a pure content-derived gradient with
  *"no observational learning."* `crystal` is **K=1.00**. Legacy can be every bit as pure and deterministic.
- *"Legacy has no content-addressing / no reversibility / no witnesses."* False. `crystal` is sha256 +
  MAC-sealed; `cad`/`mhash`/`identifier` are content-addressing; `reversible.iii` is a full transactional
  undo engine with witnessed commit/rollback. The inverse form's novelty is **not** that these exist —
  it is **where they sit structurally** (constitutive identity + chain, vs bolted onto a mutable record).

---

## 1. THE TWO STRUCTURES, CHARACTERIZED

### 1.1 Legacy (state-primary) — the dominant III module shape
The **stored state cell is the source of truth**; functions are **named operations on typed values** that
**read or destructively update** that cell. Canonical anatomy (from `vec.iii`, `crystal.iii`, `reversible.iii`):

- **A handle/slot table.** Module-scope parallel arrays (`VEC_BASE/CAP/LEN/LIVE`, `CRYSTAL_*`,
  `REV_SLOT_*`) with a fixed instance count; a value's **identity is an opaque handle** (`slot + 1`,
  `CRYSTAL_ID_BASE + slot`, an envelope index). A `LIVE` flag is the lifecycle.
- **Destructive update.** `vec_u8_set(id,i,v)` overwrites byte `i` — **the old value is gone forever**;
  `vec_u8_clear` zeros the length; `vec_u8_drop` frees the slot. The past is not recoverable.
- **Named, typed operations.** `vec_u8_push`, `l6_and`, `rf_node_potential` — the operator's name *is* the
  primitive, and it acts on a typed value.
- **Per-value sealing (when present).** `crystal` binds provenance into a **16-byte MAC over the record's
  fields**, sealing *one error value*. Witness = a property *of a value in a slot*, not of a history.
- **Lifecycle bounded by a table.** Exhaust the slots and you get a typed failure or a degenerate handle
  (the documented bigint 64-slot trap). State is finite and explicitly managed.

### 1.2 Inverse (event-primary) — the inverse-substrate organ shape
The **append-only event log is the source of truth**; **STATE is the side effect** — every state is a
**pure fold over a prefix** of that immutable log (from `event_substrate.iii`, `isub.iii`, `dome.iii`):

- **One append-only log.** `evt_perceive` / `isub_emit` / `dome_emit` is the **only** mutator; it
  **appends and erases nothing**. There is no state cell to overwrite.
- **State = a fold.** `evt_winner(upto)`, `dome_active_parity(p)`, `isub_witness_into()` are **fixed pure
  functions of a prefix** — same history ⇒ same answer, any prefix re-derivable (time-travel for free).
- **Content-addressed, nameless verbs.** `isub` stores uniform blocks `<verb∈{BELOW,REFLECT}, a, b>` whose
  **identity is `sha256(geometry)`**; the **verb slot structurally rejects any name** (a name is a large
  integer > 1 → the name-gate refuses it). No string/name field exists in the log.
- **Constitutive witness chain.** The witness **is** the hash-chain of identities
  `ROOT = sha256(ROOT_prev ‖ CAV_i)` — delete the content-address and the root cannot form. The witness is
  the substrate's spine, not a decoration on a value.
- **Reversal = branching, not truncation.** A `dome_rewind` **records the abandoned span and keeps it** in
  the witnessed log as **provenance**; only the *active fold* skips it. The failed branch survives.

---

## 2. THE DIFFERENTIAL (the spine — axis by axis)

| Axis | Legacy (state-primary) | Inverse (event-primary) | Grounded example |
|------|------------------------|--------------------------|------------------|
| **Source of truth** | the stored **state cell** | the **append-only event log**; state is a fold over it | `vec` buffer / `RF_NODE_*` cells **vs** `EVT_*` log + `evt_winner` |
| **The past** | **discarded** on update/commit | **retained** — every prefix re-derives a past state | `vec_u8_set` overwrites; `rev_commit` truncates the undo log **vs** `dome` rewind keeps the abandoned span; `evt_witness(upto)` |
| **Mutation model** | **destructive update** in place | **append-only**; nothing is ever erased | `vec_u8_set`, `rf_add_node`, undo-replay rewrites the live cell **vs** `isub_emit` / `dome_emit` (only mutator, append) |
| **Identity** | an **opaque handle / slot index** | a **content-address** = `sha256(footprint)` | `slot+1`, `CRYSTAL_ID_BASE+slot` **vs** `isub` CAV |
| **Names** | **named ops on typed values** (the name *is* the primitive) | **nameless verbs at geometry**; names structurally forbidden | `vec_u8_push`, `l6_and` **vs** `isub` `{BELOW,REFLECT}` + name-gate; `master_logic` *dissolves* the name |
| **Witness** | optional **per-value seal / emitted fragment** | **constitutive** — identity IS the hash, witness IS the chain | `crystal` 16-byte MAC; `reversible` `wh_publish` fragment **vs** `isub` `ROOT = sha256(ROOT_prev‖CAV)` |
| **Reversibility** | **undo log of inverse continuations**, replayed LIFO, then **discarded** | **branch-retaining fold** over the immutable log; rewind keeps provenance | `reversible.iii` `rev_rollback`/`rev_commit` **vs** `dome` `dome_rewind` + `dome_provenance_count` |
| **Proof locus** | **embedded** `*_selftest()->99` + in-module charter (verify/falsify/canary) | **external** corpus KAT asserting **geometry of execution** (provenance / shadow-race / lasso / Divergence Signature) + teeth | `rev_selftest`, `rev_compromise_run_charter` **vs** `1913`/`1903` KATs |
| **Cost (space)** | **O(1)** per update; bounded BSS (a table) | **log grows** with history; fold cost rides on log length | `vec` slot, `reversible` 8192-record cap **vs** `EVT_CAP`/`ISUB_CAP` log + per-call fold |
| **Cost (time read)** | **O(1)** read of the current cell | a **fold over a prefix** (O(active), with caveats — §4) | `vec_u8_at` **vs** `evt_maxprio(upto)` / `soc_active_max` |
| **Competence region** | fast committed computation; **control / decision** (determinist wins parity) | reversible, counterfactual-carrying **deliberation / search / assimilation** | containers, crypto, the parity *theorem* **vs** dome evasion-by-living, `assimilate`, `reverse_search` |

---

## 3. THE THREE SHARPEST CONTRASTS (deep dives)

### 3.1 `reversible.iii` (legacy undo) vs `dome.iii` (inverse rewind) — the decisive one
These solve the *same problem* (get back to an earlier state) with **opposite structures**:

- **Legacy = undo-and-discard.** `reversible.iii` is a **LIFO stack of transactional envelopes**. Each
  forward effect records an **inverse continuation** `(tag, a, b, c, d)` whose `tag` dispatches to an undo
  function (`rev_undo_mem_u8` writes the saved-old-byte back). **Rollback** (`rev_replay`) walks the
  records in reverse and **destructively mutates the live cell back to its old value**; **commit truncates
  the undo log** (`REV_REC_USED = start`). After either, **the trail is gone** — you cannot ask "what was
  the state at envelope-open," and a rolled-back branch leaves **no provenance**. It is *undo*, the
  determinist's "commit, then maybe reverse the commit."
- **Inverse = branch-and-retain.** `dome` never mutates a state cell. To rewind, `dome_rewind(bp)`
  **records the abandoned span `[bp, here)` and erases nothing**; the live state is just the fold over the
  *active* events (skipping the abandoned span). The failed branch **stays in the witnessed log forever**
  (`dome_provenance_count > 0`), so the system can **live a bad choice, see its consequence recur
  (`dome_recurred` — the lasso), rewind, and re-choose from the retained lesson** — keeping the
  counterfactual. `III-DOME.md`: *"Determinism commits and is blind to its own counterfactuals; the
  inverse form carries them."*

The one-line difference: **legacy reverses the world and forgets the road not taken; the inverse form
keeps every road and just re-reads the map.**

### 3.2 `ripple_field.iii` (spatial snapshot) vs `event_substrate.iii` (temporal fold)
The inverse organ's own header names this duality: *"Where ripple_field is the SPATIAL dual (state
primary, field a derived side effect over a graph), this is the TEMPORAL dual."*

- **`ripple_field` (legacy, pure, K=1.00):** the truth is the **current graph** (`RF_NODE_*`/`RF_EDGE_*`
  mutable cells); `rf_node_potential` is a **pure function of the graph *as it is right now***. It is fully
  deterministic and content-derived — **but it has no past.** Mutate the graph (`rf_add_edge`, `rf_reset`)
  and the prior field is unrecoverable; there is no history, no witness chain, no rewind.
- **`event_substrate` (inverse):** the truth is the **append-only history**; `evt_winner` is a fold over a
  **prefix in time**, so *any* past state is re-derivable, and the **infinitary** fold (`evt_inf_winner`)
  decides an eventually-periodic acceptance condition (parity over a found lasso) that a snapshot cannot
  even express.

This is the cleanest proof that the distinction is **not purity** — both are pure — but **spatial-snapshot
vs temporal-history**: *where in time the truth lives.*

### 3.3 `crystal.iii` (per-value seal) vs `isub.iii` (constitutive content-address)
Both use sha256. The structural placement is the whole difference:

- **`crystal` (legacy):** identity is still a **slot id** (`CRYSTAL_ID_BASE + slot`); the content-address
  (`site_hash`, `msg_hash`) and the 16-byte **MAC are fields bound *inside a mutable slot record*,**
  sealing **one error value** against forgery. Provenance is a `cause` **handle** (a prior crystal's slot
  id — which can dangle on slot reuse). Content-addressing is a **property of a value**.
- **`isub` (inverse):** the content-address **IS the identity of every event**, and the witness **IS the
  chain of those identities** (`ROOT = sha256(ROOT_prev ‖ CAV_i)`). There is no slot id and no name —
  **delete the CAV computation and the witness cannot be formed.** Content-addressing is the **substrate's
  spine**, and identical geometry → identical CAV gives **automatic recognize-and-merge dedup** (the basis
  of `assimilate`'s zero-redundancy web).

---

## 4. THE HONEST COST LEDGER (no sales sheet)

The inverse form's capabilities are **bought, not free** — and the source says so plainly:

- **Space:** legacy destructive update is **O(1) space**, a bounded table. The inverse log **grows with
  history**; reversibility and provenance mean *the abandoned branches are still in memory.* Bounded only
  by `EVT_CAP` / `ISUB_CAP` here — a real deployment must compact or cap.
- **Time:** a legacy read is **O(1)** off the current cell. An inverse read is a **fold over a prefix**.
  `III-TRAJECTORY-AUDIT.md §0` **retracts** the claimed O(active) bound: *"P3 (O(active) bound) is
  contradicted by the code — `soc_active_max` rescans the whole log per call."* The O(1) rolling witness
  holds **only for memoizable folds**; a non-memoizable fold is **O(n)** per query (a stated boundary).
- **Security:** tamper-**detection** holds for any avalanching witness (even a multiply-add/FNV hash);
  adversarial **resistance** holds **only** with a collision-resistant witness (`cad` sha256). Calling an
  FNV witness "secure" is the over-claim that got the §3 "theorem" retracted.
- **Established, not novel-crypto:** the pattern is **Event Sourcing + CQRS + a transparency log** in the
  inverse direction — *"established-sound; the novelty is the inversion and the bounded fluid edge, not the
  cryptography."*

So the trade is explicit: **legacy buys speed and bounded memory by forgetting; the inverse form buys
reversibility, provenance, time-travel, and tamper-evidence by remembering — and remembering has a price.**

---

## 5. A CORRELATION THAT DOES *NOT* HOLD — do not map inverse↔(K / Ring)

It is tempting and **wrong** to say "inverse = K 1.00 / pure, legacy = K 0.99 / impure." The primary
source refutes it directly:

| Module | Form | K | Ring |
|--------|------|---|------|
| `ripple_field` | **legacy** (state-primary) | **1.00** | R0 |
| `crystal` | **legacy** | **1.00** | R-1 |
| `event_substrate` | **inverse** | 1.00 | **R0** |
| `vec` | legacy | 0.99 | R0 |
| `reversible` | legacy | 0.99 | R-1 |

`K` drops to `0.99` from **resource-management side effects** (vec's arena allocation, reversible's
slot/log exhaustion), **not** from being legacy — and Ring tracks privilege, not form. The accurate
statement: the **append-only-fold shape makes purity *natural*** (a read can never mutate), but **purity
is not exclusive to it**, and many legacy organs are perfectly pure. Form ≠ purity ≠ privilege; keep the
axes independent.

---

## 6. ONE-PARAGRAPH SUMMARY

A **legacy** III module makes a **stored, typed state cell the source of truth**, gives values **opaque
handles**, exposes **named operations that read or destructively overwrite** that cell, and (when it
needs integrity or undo) **bolts a per-value seal or an undo-log onto the side** — buying **O(1) speed and
bounded memory by forgetting the past.** An **inverse** organ makes an **append-only, content-addressed,
witnessed event log the source of truth**, derives **all state as a pure fold over a prefix**, **forbids
names structurally** (verbs at geometry), makes the **content-address the constitutive identity and the
witness chain**, and **rewinds by branching (retaining the abandoned road) rather than truncating** —
buying **reversibility, provenance, time-travel, and tamper-evidence by remembering, at the cost of log
growth and fold time.** Neither is "better": most of III is and remains legacy, the determinist still wins
control-games, and the inverse substrate **encapsulates** the incumbent (`xii_isub` wraps the real
`xii_rewrite`) to add the one competence legacy structure cannot reach — *the reversible, debuggable,
provenance-complete trajectory.*
