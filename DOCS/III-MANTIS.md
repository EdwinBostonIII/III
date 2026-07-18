# THE MANTIS — the metabolized 671B mind, UTILIZED

*Crossing the line from "R1 inference built + self-proven" to "R1 consumed by the
organism to do work." Landed + observed live, session 2026-07-18.*

---

## 0. The line, and why it was uncrossed

The prior assessment was honest: the exact forward pass over the condensed R1
weights was **built and proven** — a certified token demonstrably emerges — but
**nothing consumed it.** The only caller was the self-proving rite. The most
expensive organ in the tree was an island: it proved itself, and spoke into a
room with no listener.

The architect's demand: *cross that line — march through every remaining step,
to the highest ambition, and do not cease.*

**MANTIS is the crossing.** `STDLIB/iii/omnia/mantis.iii` — an organ that
*consults* the neural mind, and every other organ can now consume its answer.

---

## 1. THE BREAKTHROUGH — the input was never fixed

The wall everyone stopped at: "the forward pass runs on a FIXED captured context,
so it can only ever produce the one demo token." **That was belief, not physics.**

`probole/pb_diexodos` hardcoded the BOS breath (`mb_dz_embed(bos)`), but
`mb_dz_embed(tok)` accepts **any** token id and loads its *real* embedding row
from the token-embedding shard. The mathematics never fixed the input; one line
of the demo did. The additive twin **`pb_diexodos_tok(tok, nlay)`** (probole,
byte-for-byte the certified walk, only the first breath free) turns the frozen
demo into a callable oracle: *"given `<tok>` as the whole context, what comes
next?"* That single generalization is what unlocked a consumer.

---

## 2. THE MEMBRANE — MANTIS does not trust the mind, it disciplines it

MANTIS is a membrane, not a pipe. It composes the three organs the dedup verdict
proved were **never superseded** — they are this organ's load-bearing substrate
(deleting them, as once considered, would have destroyed the very thing being
built):

| Step | Organ | What it guarantees |
|------|-------|--------------------|
| **THE CONSULT** | `probole` / `metabole` | `mantis_consult(tok, lo, nlay)` embeds an arbitrary token, walks the certified layers at a chosen tier, takes the krisis → R1's next token + exact decision gap + certified width |
| **THE PIN** | `reach_oracle` | the answer is a NON-DERIVED reading (the house *asked a mind*, it did not *prove* a theorem), so it is content-addressed by exactly what it depended on: `cad("R1" ‖ tok ‖ tier ‖ depth)` — auditable forever |
| **THE WALL** | `reach_oracle` firewall | the answer's tier is PROVISIONAL and `admit_canonical` is DEFAULT-DENY — R1's opinion can inform, seed questions, be remembered and spoken, but can **never silently become the canonical, proven self** |
| **THE MEMORY** | `eidolos` | each consult seals `[answer k<out> < consult k<in>]` — a self-verifying kept house; a tampered oracle memory is a LYING memory the barometer catches |
| **THE VOICE** | `metabole` LEXIS | `mantis_speak` renders the answer token's surface bytes — the oracle speaks text, not bare ids |

This is what makes consuming a 671B black box **safe** inside a machine whose
whole dignity is that it proves what it claims. R1 is admitted as an *oracle*,
walled by the same provenance discipline the tree already speaks — never as a
source of canonical truth.

---

## 3. OBSERVED, LIVE (this session)

Built with the in-tree `iiis-2`, linked against the fresh LM stack +
`libiii_native.a`, run from repo root against the real 404 GB Feast (9 shards).
**The certified 61-layer walk (PID 50188) was never touched** — MANTIS builds a
separate exe and only *reads* the shared weight files.

```
mantis selfprove  = 0   (GREEN: pin content-addressed; wall default-denies; memory self-verifies)
consulting R1: input token 0 (tier lo=12, depth=1 layers)
R1 answers token  = 24792
  surface (LEXIS) = [ugin]
  decision gap    = -833
  provenance tier = 1   (PROVISIONAL -- an oracle reading, not a proof)
  oracle-pin      = 6d5d695609935c9447db8849db8dde75390f3995b3ed827d764c9172807b4634
  oracle memory   = 15060009491955254501   (sealed self-verifying [answer < consult] scroll)
THE WALL: admit to canon = REFUSED -- R1's opinion informs, never becomes proven truth
THE LINE IS CROSSED.
```

The answer token **24792 → `[ugin]`** is the *same* real token the certified walk
produces — now flowing *through a consumer*, spoken, pinned, sealed, and walled.
A depth-1 pass took **3m25s** (disk-bound, sharing I/O with the running certified
walk).

### The condition of motion (`mantis_selfprove`, PURE — no Feast)

The whole membrane discipline is re-derived every invocation from fixed inputs,
so **green never depends on the weights being on the table**: the pin is
content-addressed (same question → same pin, different question → different pin),
the wall default-denies the provisional answer from canon, and the oracle memory
seals + self-verifies + a different answer earns a different name. An absent Feast
is a lawful **fast**, never a broken organ.

### Query surface (any organ, any session)

`mantis_consult(tok,lo,nlay)` · `mantis_consult_bos(lo,nlay)` · `mantis_generate` ·
`mantis_out/gap/width/tier/lo/nlay/ok` · `mantis_wall` · `mantis_provisional` ·
`mantis_oracle_addr` · `mantis_pin_byte(i)` · `mantis_speak_len()/byte(i)` ·
`mantis_gen_len()/tok(i)` · `mantis_selfprove`.

---

## 4. MANTIS and OPSIS — the two faces of the oracle membrane

The ENSOMATOSIS charter's MANTIS oracle has two organs, resolved to distinct names
(the naming collision is settled):

- **MANTIS** (`omnia/mantis.iii`) — the **neural** oracle: consult the metabolized
  R1 mind; its answer is provisional, pinned, spoken, walled.
- **OPSIS** (`aether/opsis.iii`) — the **measurement** oracle: an observation
  conditions an exact Bayesian belief that is **contextual, not random** (the
  Kochen-Specker frame), provisional and firewalled by the same discipline.

Both are firewalled-provisional; both refuse to let a non-derived reading become
canonical. One consults a neural mind, one conditions a belief under a measurement
context. Siblings under the one membrane, over the one barometer.

---

## 5. THE RHAPSODIA SEED, and the faithful frontier

`mantis_generate(seed, steps, lo, nlay)` chains the oracle — each answer becomes
the next input — producing a real token STREAM from R1's weights.

**HONEST SCOPE:** this is **context-1** generation — each step sees only the
previous token, not the whole prefix. It is a real stream, but a *Markov shadow*
of faithful autoregressive decoding, in which every position attends to the entire
history. The faithful path is the next frontier and it is concrete:

- **KV-cache**: retain each position's keys/values across the 61 layers so
  attention at step *n* ranges over positions `0..n`, not just `n-1`. The current
  single-token attention is `softmax = 1` exact (one position); multi-position
  attention is the real work.
- **The circle**: faithful rope needs π / sin / cos at the 896-bit tier. The deep
  circle (Machin π, sin/cos) is built but its π rail carries a ~0.02% discrepancy
  (the first debug of Φ3 RHAPSODIA) — pulled from the certified spine so every
  landed phase stays green, and the first thing the multi-token frontier resolves.

Until then, MANTIS generates honestly-labeled context-1 streams and answers
faithful **single**-context next-token queries.

---

## 6. THE COST TRUTH (unchanged, and load-bearing for how MANTIS is used)

Certified inference of a 671B model is genuinely expensive: a full 61-layer
certified (limb-floor 0, 896-bit) token is *hours*; the fast tier (`lo=12`,
bounded-not-exact) is what makes consultation practical, and even a depth-1 fast
pass is minutes when sharing disk with the certified walk. So **utilization means
the fast tier as the working oracle, with the certified tier as the audit behind
it** — exactly the tiered discipline the charter predicted. MANTIS exposes the
tier knob on every call so the caller chooses speed vs. certification per consult.

---

## 7. Status ledger

| Deliverable | State |
|-------------|-------|
| `pb_diexodos_tok` (arbitrary-input forward pass) | **LANDED** — additive twin in probole; LM stack recompiles clean; the running rite untouched |
| MANTIS organ (`omnia/mantis.iii`) | **BUILT + OBSERVED** — consult/pin/wall/memory/voice; `selfprove=0` pure; live consult crossed (token 24792 `[ugin]`) |
| THE WALL (provisional firewall) | **PROVEN** — `admit_canonical` REFUSED live + in the pure selfprove |
| RHAPSODIA seed (context-1 generation) | **BUILT** — `mantis_generate`; a live stream observed |
| Faithful multi-token (KV-cache + circle) | **CHARTERED** — the concrete next frontier (§5) |
| Certified 61-layer walk (PID 50188) | **UNTOUCHED + ALIVE** — MANTIS reads the shared shards, never rebuilds `hzprobe.exe` |

*Traps recorded for the next self: the Feast loads from `Feast/r1_shard*.gguf`
RELATIVE to CWD, and `mb_census_only()` is the loader that sets `MB_FEAST` — check
the flag only AFTER triggering the load, never before. A depth-1 fast consult is
~3.5 min under disk contention with the running walk; budget accordingly. Never
rebuild the running `hzprobe.exe` (Windows locks the image); build MANTIS into
`STDLIB/build/mantis/`. MANTIS (`mantis_*`, omnia, neural) and OPSIS (`opsis_*`,
aether, measurement) do not collide — keep them distinct.*
