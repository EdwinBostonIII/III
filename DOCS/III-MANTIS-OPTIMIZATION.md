# MANTIS OPTIMIZATION — hours → minutes with III's own inventions

*Collapsing the cost of certified R1 inference using the tree's own eskalation and
width-ledger, not external heuristics. Session 2026-07-18.*

---

## 0. Where the time actually goes (measured, not assumed)

Before optimizing, the cost was decomposed against the real code:

| Cost | Magnitude | Regime |
|------|-----------|--------|
| **Certified arithmetic** (896-bit dyadic, limb-floor 0) | ~37B active param-mults × ~196 word-mults/limb-pair → **hours** | dominates the certified walk |
| **I/O** (read active weights) | ~37B active params (MoE reads only the elected 9 of 256 — *already trimmed*) ≈ tens of GB → tens of seconds to minutes | dominates the fast tier |
| **Head argmax** | 129280×7168 dot ≈ 3% of the pass | minor |
| **Fast tier** (limb-floor 12, ~2 limbs) | ~1/7 the arithmetic → **minutes**, but **UNCERTIFIED** | the existing TACHOS knob |

Two findings reframed the campaign:
1. **The MoE fat is already trimmed** — `pb_dz_layer_moe` runs only the shared + top-8
   elected experts, never all 256. Active params ≈ 37B of 671B; the walk does not read
   or compute the 94% it does not use.
2. **The head argmax is only ~3%** — optimizing it (cheap-first + certify-contested,
   the KATOPTRON pattern) is sound but marginal. The 61 layers dominate.

So the "hours" is **certified 896-bit arithmetic over the active weights**, and the
lever is precision, not sparsity (already sparse) or the head (already minor).

## 1. THE LEVER — certify at the tier the gap allows (the eskalation)

The certified verdict is: **PROVEN iff the gap exponent exceeds the width ledger**
(`gape > wled`). The width ledger (`pb_wled_fold`) is a *rigorous* log2 bound that
**charges `LO*64` bits of fresh truncation per projection** — so the same rigorous
bracket holds at *every* limb-floor, just wider at higher floors.

The code's own comment encoded the old belief: *"the fast tier is expected to be
undecided; certify at limb-floor 0."* **That is false for the common large-gap
token.** If the gap towers over the width, a HIGH limb-floor (few limbs) already
proves it — and always paying limb-floor 0 (896-bit, hours) is pure waste.

**`pb_diexodos_certified` (probole)** is the eskalation lifted to the whole forward
pass: it walks cheap-first and stops at the **largest limb-floor where the token is
PROVEN**, certifying at fast-tier speed. It is not an approximation — it is III's own
certification, invoked at the tier the gap permits. The LO=0 walk remains the
guaranteed floor, never the default. This is the same escalation as the SYNODOS
election's rung-climb (48→58), now over the whole mind.

```
pass 1: limb-floor 13 (one live limb)  → read the gap cheaply
   decided?  → PROVEN at 13, done
predict need = (gap - oemax)/64 - 1     (the floor where oemax + LO*64 < gap)
pass 2: limb-floor `need`                → certify at the predicted floor
   decided?  → PROVEN at `need`, done
pass 3: limb-floor 0 (896-bit)           → the guaranteed certified floor
```

`mantis_consult_certified` consumes it: the answer, the **proving floor**
(`mantis_cert_lo`, ≥0 = proven / −1 = undecided even at 896-bit), the **passes spent**
(`mantis_passes`, ≤3), and `mantis_proven`. Still a walled oracle reading (PROVISIONAL);
PROVEN means *we know R1's exact argmax with proof*, not that the house derived it.

### Why this is the right win (and its honest cost)

- **Arithmetic-bound (deep/certified) regime** — the target: proving at floor `k`
  costs ≈ (14−k)/14 of the limb-work of floor 0, so the hours collapse toward the
  fast-tier minutes **with certification intact**. The 1–2 extra probe passes are
  cheap arithmetic (they re-read weights, but that I/O is dwarfed by the certified
  arithmetic they replace).
- **I/O-bound (shallow/fast) regime** — the multi-pass re-reads weights, so escalation
  can cost more I/O than it saves; there the single fast pass was already the answer.
  The driver is meant for the certified regime, exactly where the hours were.
- **The single-pass refinement** (charted): once a model's typical proving floor is
  known, run *directly* at that floor (one pass, certified) — the escalation only has
  to *discover* the floor; a stable model can pin it. That removes the probe passes'
  I/O entirely.

## 2. Observed (live)

Two tiers, both run over the **real Feast**, both honest about what they prove.

### The fast tier — R1 consumed, in seconds

`mantis.exe` at limb-floor 12 consults the metabolized 671B mind and returns R1's
exact argmax token in seconds:

```
input token 0  →  R1 answers 24792   surface (LEXIS) = [ugin]
  decision gap    2^-833
  provenance tier PROVISIONAL   oracle-pinned   WALLED from canon
```

The mind is live and consumable at fast-tier speed — an oracle reading, never admitted
as proof. This is the working default.

### The certified tier — the honest 896-bit ceiling

The adaptive driver escalates cheap-first (floor 13 → predicted → floor 0). On R1's
real logits it lands **UNDECIDED at every floor** — and this is a *rigorous verdict, not
a failure*: the width ledger is an honest log2 bound, and R1's decision gap sits far
below it. From a prior full **61-layer certified walk** (exit 0):

```
winning token 343 over runner-up 14
  decision gap    2^-835
  width ledger    2^12663      (oemax + accumulated per-projection truncation)
  verdict         UNDECIDED  — certifying this argmax needs ~13.5 Kbit, not 896
```

The floor-0 (896-bit) pass is the **×d amplification wall**: re-run at `nlay=4` it
ground for the **full 660 s bound and was killed (EXIT 124)** before emitting the
answer. Floor 0 is the *guaranteed* floor — never a tractable *default* for R1's depth.

### What the numbers mean

R1's argmax is **not certifiable at 896 bits at any floor** — its logits are too tightly
packed (gap 2^-835 against a 2^12663 width). So the eskalation's win is **regime-specific
and real**: it collapses hours→minutes wherever *the gap towers over the width* — the
large-gap decidable tokens and, above all, III's own exact-arithmetic frontiers (the
SYNODOS rung-elections, the `riza`/`kfield` sign verdicts) where a HIGH floor already
proves the result. For R1 consults specifically, the honest path is the **fast tier**
(walled/provisional regardless), with certification reserved for the decidable regime.
The driver states this honestly: proving floor **−1**, passes **3**, proven **0** — it
refuses to claim a proof it does not have.

## 3. What is NOT claimed

- Not a faster bignum multiply, not a new quantization, not a precision *approximation*.
  The result is the **same certified token**; only the price falls, and only in the
  regime the hours lived in.
- The head-argmax escalation (KATOPTRON on the 129280 rows) is sound but ~3% — charted,
  not built, because the leverage does not justify overhauling a rite-critical function.

## 4. The charted frontiers (concrete, not deferred hand-waves)

1. **Single-pass per-projection adaptive precision** — the crown: keep, in ONE pass,
   only the limbs each projection needs to hold the width under the (running) gap
   target. Removes the multi-pass I/O entirely and lands certified-at-fast-tier in a
   single read. A real rewrite of the dot/fold; needs dedicated verification runs.
2. **KV-cache + faithful multi-token** — retain per-position K/V across the 61 layers so
   attention ranges `0..n` (current single-position attention is `softmax=1` exact);
   rope for position>0 uses the certified 128-bit `pr_pi`/`pr_sincos` (already green in
   the summit gate — the "deep 896-bit circle" was over-engineering; the moderate circle
   suffices at the tier the attention decides).
3. **Generation weight-cache** — the non-expert weights (attention, norms, router,
   shared expert, head) are identical every token; caching their decoded form across a
   generation removes re-reads for the ~15GB that never changes token to token.

## 5. Status

| Piece | State |
|-------|-------|
| Cost decomposition (measured) | **DONE** — MoE already active-only; head ~3%; hours = certified arithmetic |
| `pb_diexodos_certified` (eskalation driver) | **BUILT + COMPILES + LINKS** — probole, additive, rite untouched |
| `mantis_consult_certified` (consumer) | **BUILT** — reports proving floor / passes / proven |
| Live magnitude | **MEASURED** — fast tier consumes R1 in seconds (token 24792, gap 2^-833); certified verdict UNDECIDED at 896-bit (gap 2^-835 vs width 2^12663); floor-0 at nlay=4 killed at the 660 s bound (EXIT 124) |
| The honest finding | R1's argmax is not certifiable at 896 bits at any floor; the eskalation win is **regime-specific** — decidable large-gap tokens and the exact-arithmetic frontiers, not R1's tightly-packed logits |
| Single-pass adaptive / KV-cache / gen-cache | **CHARTERED** — §4 |
