# Ξ-Ω AUTOPHASIS + Ξ-ΣΥΝ SYNAPSE — the discovery→native-organ loop, and the constitution-pinned wire

**Executed 2026-07-17.** Two standing mandates of the arc closed, both stored-answer-free,
both leaf-linked (no compiler surface, no archive write — safe while the corpus judge ran).

## The wound this closes

The arc's oldest open grievance: *III once discovered an ontology and a maneuver more
efficient than what it could express, and a human had to reformat it into III by hand.*
For an autonomous system that is a refusal-grade defect. GLOSSA closed it for **vocabulary**
(the machine mints words). AUTOPHASIS closes it for **structure** (the machine presses a whole
discovered algebra into a native organ), and SYNAPSE lets one III hand that discovery to
another instance of itself over a wire without ever trusting a stranger.

## Ξ-Ω AUTOPHASIS — the self-utterance (`iii-substrate autophasis <outdir>`)

The press hunts the **fair magma universe's own enumeration** (`aether/xeno_ontogenesis`,
the anti-rigging bijection `step ↔ (n, idx)`) under a **global pre-stated criterion** — the
first non-associative quasigroup in fair order at the smallest populated carrier — and presses
it into a native, sealed, computable organ (`STDLIB/iii/aether/autophasis.iii`):

- `omega_op(a,b)` — the discovered operation, pressed cell-exact.
- `omega_ld / omega_rd` — **left and right division, the reversal maneuver SYNTHESIZED from
  the table by the press**, unique-solution verified (a non-unique solution refuses the press).
  The reversal is not stored; it is derived from the structure — a quasigroup's rows and columns
  are permutations, so `a\b` is simply the unique `x` in row `a` equal to `b`.
- `omega_wa/wb/wc` — the lex-first associativity-violating triple: the organ carries its own
  falsifiable claim.
- `omega_census_*` — the fairness dispositions (every table/quasigroup/associative/non-assoc
  counted, at every swept carrier — nothing assumed).
- `autophasis_set_id()` — FNV over the emitted foldable bytes (two-pass fold/write through the
  shared GLOSSA press plumbing — one emitter, two tiers).

**Measured, this die:** n=1 → 1 table / 1 QG / 0 non-assoc; n=2 → 16 / 2 / 0; n=3 → 19683 / 12 /
9 non-assoc. Selected: **carrier 3, fair index 4069, witness (0,0,1)**, set id 79138004628686176.
Two presses byte-identical (determinism voter has teeth).

**Gate 2763** (`STDLIB/corpus/2763_autophasis.iii`, stored-answer-free): re-hunts the universe
with an INDEPENDENT associativity engine, re-derives carrier + index + full census, checks the
pressed table cell-by-cell against the universe, re-proves the quasigroup + all four division
laws FROM THE PRESSED FNS over every pair, re-derives the witness, checks the totality guards,
and **refutes a corrupted table** (a flipped cell → `RED TABLE`, rc 13). Green = exit 99.

**Honesty boundary (the eidolon adjudication law, restated not hidden):** at n=3 the pressed
algebra is a human-charted class (labelled Latin squares, OEIS A002860). The **invention is the
CAPABILITY** — discovery → authored native organ → machine-proved, autonomously — **not** a
novelty claim on the n=3 object. Grade: **SOVEREIGN / MEASURED.** The novelty frontier the xeno
header names (ISA atoms with no classical pedigree) is where the same press points next; novelty
there remains an adjudication, never asserted here.

## katabasis/autognosis — the base-level self-knowledge

`STDLIB/iii/katabasis/autognosis.iii`: III knows, as a linkable fact, **what law it runs under.**
It folds the three sealed identities — NOMOS (`cgphys_set_id`, the rewrite constitution), GLOSSA
(`cgglossa_set_id` / `glossa_set_id`, the vocabulary), AUTOPHASIS (`autophasis_set_id`, the
pressed discovery) — into `autognosis_root()`, **THE CONSTITUTION ROOT**. The coherence law:
GLOSSA is one law with two seats; if the lexicon seat and the tongue seat disagree, the
self-model is broken and the root is **REFUSED (0)** rather than computed over a lie. Nothing is
stored — every id is read from its sealed seat at link time, so the root is as live as the law.

## Ξ-ΣΥΝ SYNAPSE — the constitution-pinned wire (`iii-substrate synapse [port]`)

`STDLIB/iii/aether/synapse.iii`: III's own NIH protocol (the grammar, the pinning law, the
refusal order are invented here). The **envelope** is III's own `babel_wire` with its proven
**content-address-as-integrity** law (the message id IS the mhash of its payload — a corrupted
frame is a *different, unasked* message, undeliverable). The **protocol organ is R0-pure and
never touches a socket**, which is exactly what makes every rule provable in-process; the
**transport** is composed at the tool layer from `aether/net` (capability-gated loopback TCP).

- **HELLO** — the constitution handshake. Each side compares the peer's NOMOS + GLOSSA +
  AUTOPHASIS ids and claimed root against its OWN sealed seats and the re-folded payload. Two
  IIIs speak only after proving they are **the same being under the same sealed law**. An
  incoherent self-model cannot even build a HELLO (`autognosis_root()==0` refuses the frame).
- **ASK / VERDICT** — a proof obligation, not a byte relay. `kind 1` (GLOSSA): the server answers
  by **speaking the machine's own minted words BARE** (`popcnt64`, `andn64`, …); `kind 2`
  (AUTOPHASIS): the pressed discovery's `omega_op` + a live re-check of all four division laws.
  The asker RE-VERIFIES content + nonce, then **cross-derives the answer with its own engine** —
  delivery proves integrity, never truth.
- **The refusal order** (lexicographic gravity, every code named): unparseable before foreign
  constitution before executed obligation. Codes −1…−13.

**Ripple:** this is the self-reference-over-a-wire seat the arc owed — one III pushes a
re-derivation obligation to another instance of itself and cross-checks the verdict against its
own engines, refusing all strangers.

**Gate 2764** (`STDLIB/corpus/2764_synapse.iii`, stored-answer-free, no sockets — all rules
provable in-process): self-fold == independent fold; HELLO CONCUR; **4 foreign constitutions
refused BY NAME**; content / crc / seal / short / facet refusals walked; **7 minted words × 26
points (battery + LCG) served over frames and cross-checked against the gate's own bit-loop
evaluators**; every `omega` pair served and checked against the organ; nonce binding; 4 serve
refusals (unknown kind, OOB word, OOB carrier, corrupted ask). Green = exit 99.

**Real-socket demo** (`iii-substrate synapse`): two endpoints over OS loopback proved the same
being (mutual HELLO), served `popcnt64(0xDEAD…)=48` cross-derived, served the pressed discovery
with division laws holding, and **refused a payload byte flipped after sealing**. Exit 0 green.

## What lands where (leaf, no archive/compiler write)

| File | Role |
|---|---|
| `STDLIB/iii/aether/autophasis.iii` | the machine-authored organ (GENERATED; regeneration is the only lawful edit) |
| `STDLIB/iii/katabasis/autognosis.iii` | the base-level self-knowledge (constitution root + coherence law) |
| `STDLIB/iii/aether/synapse.iii` | the constitution-pinned wire protocol (R0-pure) |
| `STDLIB/corpus/2763_autophasis.iii` | stored-answer-free re-derivation gate (exit 99) |
| `STDLIB/corpus/2764_synapse.iii` | stored-answer-free in-process protocol gate (exit 99) |
| `STDLIB/iii/aether/substrate_cli.iii` | `+autophasis` press tier, `+synapse` real-socket demo |
| `COMPILER/BOOT/build_iii_substrate.sh` | leaf-links the new organs into `iii-substrate` |
| `STDLIB/scripts/run_standing_tools.sh` | AUTOPHASIS + SYNAPSE standing arms |

Gates 2763/2764 are standing-owned; their run_corpus.sh SKIP registration + the full corpus/
standing judges land after the live corpus exits (never edit a running script).
