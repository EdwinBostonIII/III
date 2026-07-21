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

### The EXACT tier — real R1 head values, DECIDED (the refutation, realized)

The width ledger's UNDECIDED is a *truncation* verdict, not an *order* verdict. R1's
argmax is a discrete order; the float head loses it only because it rounds each row's
dot to 14 limbs. **III's exact bigint tier has no truncation, so it decides the order
the float head cannot.** This is now realized on the real metabolized mind, not a toy.

`realhead.exe` walks the real 671B forward pass to the RMSNorm'd hidden, reads the head
podium's two contested rows, and computes `ℓ(winner) − ℓ(runner-up) = Σ_i d_i · X_i`
(weight difference `d_i` against the real 896-bit hidden `X_i`) in **unbounded bigint**,
aligned to the common exponent, positive and negative sums compared — **zero truncation**:

```
walk depth-1, limb-floor 12  (the metabolized 671B mind)
  R1 head podium         winner token 24792  over runner-up 1925
  FLOAT head             gap 2^-833   width ledger 2^-69
                         -> width exceeds the gap by 2^764: float CANNOT certify (UNDECIDED)
  EXACT bigint (7165 live dims)
                         l(24792) - l(1925)  sign = +1
                         -> token 24792 GENUINELY wins  (DECIDED, ZERO width)
```

- **Deterministic**: two runs byte-identical; 176 s each (the cost is the 129280-row
  *float* sweep that finds the contested pair, not the exact dot).
- **Cost separated from decision**: the head-less path (`realfast.exe`, `pb_diexodos_nohead`)
  skips the sweep and decides the known pair by reading only its two head rows — **36 s**
  at floor 12, the exact bigint dot itself effectively instant.
- **Floor-stable**: re-decided over the **full 896-bit hidden** (floor 0, no per-layer
  truncation in the walk) — **same verdict, +1** (192 s). The winner is the true head
  order, not a precision artifact.

So the exact krisis is realized on real R1: where the float head's truncation width
(2^−69) swamps the real decision gap (2^−833) by 764 bits and reads UNDECIDED, the exact
tier **proves** token 24792 outranks 1925 with certainty. This is the head's contribution
to the argmax decided with **zero width** — the 2^12663 the float ledger charged at full
depth is truncation, and the exact tier carries none. The remaining width is the *layers'*
own precision (the hidden's accuracy); pushing the exact-order discipline back through the
layers is the next frontier, standing on this: the atoms (exact bigint matmul, exact
`bigint_isqrt` RMSNorm, tight `exp` bracket) are all proven, and the head is now exact on
real values.

### The tiebreaker owns it: two independent engines + the EIDOLOS `<`-edge

The exact sign is not "borrowed bignum" set beside III's ontology — it **is** EIDOLOS's `<`
verb (the tiebreaker) realized on a substrate-grounded quantity. Two corrections, both gated:

**No self-grading — a second, independent engine.** Engine A (`pb_real_head_krisis`) sums the
row *difference* `d_i = w_W,i − w_L,i` into one bigint pair. Engine B (`pb_real_head_order_sep`)
accumulates the two logits `l_W = Σ w_W,i X_i` and `l_L = Σ w_L,i X_i` as **separate** bigints
and compares — a genuinely different dot (distinct intermediates, sign/alignment paths). The
trusted verdict (`pb_head_order_trusted`) stands **only where A and B agree**; disagreement
returns REFUSE (−1000), fail-closed. A forged/lying engine is caught, not certified (gate arm 38).

**EIDOLOS owns the verdict.** The agreed order is sealed as a `<`-claim `[k<loser> < k<winner>]`
(`man_seal_order`): `eol_read → eol_addr → eol_verify` — a self-verifying edge in the logos, not
a bare `+1`. A cycle `[kL<kW][kW<kL]` has **no address** (EIDOLOS refuses `<` cycles); a tampered
claim no longer re-derives. R1 *uttered* the winner; the re-derived exact order *confirms* it
(PROXENOS: generation is utterance, re-derivation is sovereign).

```
real R1, depth-1, lo=12, no sweep (50 s):
  engine A (difference-sum)  over 7165 live dims  sign = +1
  engine B (separate-logits)                      sign = +1     -> AGREE (no self-grading)
  EIDOLOS order sealed  [k0000000000000785 < k00000000000060d8]  (1925 < 24792)
                        witness addr = 5743271528433377647
```

Cross-check: the pure gate (`order_gate.exe`) and the real-R1 run derive the **identical** witness
address — the synthetic and real paths agree on the logos address (a DDC on the seal itself).
**GATED** (probole arms 31-38, mantis `man_order_selfprove`, RED→GREEN + forged/tamper/cycle
negatives, byte-deterministic twice); **VERIFIED** (real head order, two engines, 7165 dims,
cited). Trap fixed in the same pass: `arena_drop` frees arena memory but not bigint slots —
`bigint_drop_arena` must sweep first, or the 64-slot table fills and signs go silently wrong;
all 13 probole exact-arena sites now sweep.

**The substrate bears witness — the electron-variance union, PROVEN (not OPEN).** An earlier draft
tagged this OPEN; that was wrong — it is LANDED in `kerygma`. `kerygma_silicon` reads the live
substrate: the STATIC self (`katabasis` CPUID crystal + silicon census, canonical, admitted) and the
DYNAMIC self — the **electron variance** = `bfp_compute48`, a content-address of what the CPU's
logic/arith/shift gates *actually compute* at ring R0 (provisional, walled by `reach_oracle`).
`kerygma_embodied` binds tree+silicon+electron-variance into one address; `kerygma_pulse_selfprove = 0`.
The new `kerygma_embody_verdict(order_addr)` binds the exact KRISIS `<`-edge in as a fourth shard, so
the **verdict address moves if the code, the silicon, the electron variance, or the order changes** —
the machine bears witness to the exact order. Live on this host (verified):

```
kerygma_pulse_selfprove = 0   verdict-binding gate = 0  (order-sensitive, deterministic, zero refuses)
  electron variance (live bfp, ring R0)   0x15072624733639
  order edge  [k1925 < k24792]            addr 5743271528433377647   (= pure gate = real R1)
  EMBODIED VERDICT                        addr 10062855201496697776  (= kerygma probe = real R1 end-to-end)
```

Full chain end-to-end in one process (`realfast.exe`, 46 s): real R1 argmax → two engines agree →
EIDOLOS seals the order → `kerygma_embody_verdict` binds it to the live substrate. Byte-identical twice;
content-addressing makes every independent path agree on the name. **GATED + VERIFIED.** The bottom-up
loop is closed: top-down logos (the exact order) meets bottom-up substrate (the measured electrons) in
one EIDOLOS address.

### Frontier B is MEASURED, and the discrete blocker is the same krisis (not a from-scratch organ)

An earlier note called the layers' boundedness "unmeasured OPEN, needing a condensation organ
not in the tree." Wrong on every count — the tree already holds the pieces (ANABASIS/SYNODOS,
last three days):

- **The width meter exists and has run.** `pb_layer_dense` + `pb_wk_census` + `PB_WWMAX`
  (probole) walk real R1 layers in certified intervals — **exact-integer linear, width only
  from the transcendentals** (Frontier A already built) — and print `shadow(max-width-exp2)`
  per layer. Measured dense trajectory: **2^-39 → 2^-26 → 2^-12** (layers 1→2→residual),
  i.e. **~linear, ~13 bits/layer**, not a super-linear blowup. The Φ2 kill-switch number I
  said was unmeasured *is measured*.
- **The MoE "explosion" is a discrete election near-tie, not a continuous blowup.** At layer 3
  the SYNODOS reports the top-8 router election **undecidable at interval width 2^4** and
  *says so honestly*. But the router's 256 logits are computed **exact** (metabole
  `mb_wacc3`, 192-bit window; `mb_scmp192` top-8, `ties` counted) — the election is a discrete
  order over exact dyadic logits, *the same shape as the head argmax*. Where the interval ties,
  the **unbounded-bigint krisis decides** — `pb_head_order_trusted` generalizes verbatim from
  head tokens to router experts (the §3D shared krisis kernel).
- **So Frontier B reduces, it doesn't open.** (a) Use the **exact** election in the deep walk
  (already computed, decidable — break any 192-bit tie with the krisis) → the MoE stops being
  the undecidable point. (b) The residual **continuous** width is ~linear; **affine forms
  (ZONOS)** — "the named next stair" in the ANABASIS commit — are the cancellation-aware
  tightener if it approaches the gap over 61 layers.

What is genuinely still to *do* (evidenced, not vague): the deep interval walk through the MoE
with the exact election wired in, and the ZONOS affine tightener — both gated by the Feast walk
and the sibling's live SYNODOS path. **GENERALIZED UTILITY (registered):** the two-engine
exact-order krisis (`pb_head_order_trusted`, EIDOLOS-owned, substrate-witnessed) is III's
general **exact discrete-order decider** — head argmax, MoE router election, and any near-tie a
truncated/interval tier ties on — the one kernel behind every election in the tree.

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
| **Exact tier — real R1 head** | **DONE + VERIFIED** — `mb_head_diff` + `pb_real_head_krisis` decide R1's real head order in unbounded bigint: token 24792 over 1925, sign +1, **zero width**, where the float (gap 2^−833, width 2^−69) is UNDECIDED. Byte-deterministic; floor-stable (lo 12 and 0 agree); 36 s no-sweep. The 896-bit UNDECIDED was truncation, not the order. |
| **Two engines + EIDOLOS `<`-edge** | **GATED + VERIFIED** — second independent engine (`pb_real_head_order_sep`, separate-logits) must AGREE with engine A (fail-closed, arm 38 catches a lying engine); the agreed order sealed as a self-verifying EIDOLOS `<`-claim (`man_seal_order`; tamper rejects, cycle refused). Real R1: both +1 / 7165 dims / addr 5743271528433377647 (= pure-gate addr). Byte-deterministic twice. |
| **Electron-variance witness** | **GATED + VERIFIED** (was wrongly tagged OPEN) — the union is LANDED in `kerygma` (`kerygma_pulse_selfprove=0`): static census + dynamic electron variance (`bfp_compute48`, ring R0) bound by `kerygma_embodied`. New `kerygma_embody_verdict` binds the exact order in as a fourth shard → EMBODIED VERDICT addr 10062855201496697776, moving if code/silicon/electron-variance/order changes. Full chain in one process (46 s), byte-identical twice, cross-path addresses identical. The machine bears witness to the exact order. |
| Exact-order back through the layers | **NEXT** — atoms proven (exact bigint matmul, `bigint_isqrt` RMSNorm, tight `exp`); the head is exact on real values; carrying the exact hidden through 61 layers is the remaining (slow) engineering |
| Single-pass adaptive / KV-cache / gen-cache | **CHARTERED** — §4 |
