# Exact certified rank of DeepSeek-R1's MoE routers

Exact rank (III's `gfp` engine) pointed at **real R1 weights** from the Feast (`Feast/r1_shard01.gguf`).
Target: the MoE router `blk.L.ffn_gate_inp.weight`, `[7168 × 256]`, **F32** (raw floats, no dequant) — 256
experts, each a 7168-dim routing vector. Its rank is the **routing dimensionality**: rank < 256 would mean some
experts are linearly redundant in routing space (prunable). Tool: `STDLIB/iii/omnia/weightrank.iii` +
`gfp.iii`, `build/mantis/weightrank.exe`. Method: read a real `256 × 1024` block, quantize to fixed-point at a
chosen resolution, exact rank over GF(p). Two primes agreeing certifies the rank over ℚ, tolerance-free.

## Finding 1 — the routers are certified full rank

| router | rank (p) | rank (q) | verdict |
|---|---|---|---|
| blk.3–8 (all 6 in shard01) | 256 | 256 | **CERTIFIED FULL** |

A `256 × 1024` submatrix reaching rank 256 certifies the full `256 × 7168` router is rank 256 (submatrix rank ≤
full rank ≤ 256). Both primes agree ⇒ exact over ℚ. **R1's 256 experts are linearly independent in routing
space.** Consequence: expert pruning by *linear* routing redundancy is impossible here — any expert reduction
must be non-linear. That is a certified negative, and a useful one.

## Finding 2 — the certified quantization floor of the router

Rank of the blk.3 router block as the fixed-point resolution coarsens (each rank is exact):

```
2^-20 … 2^-5 :  256/256   (full routing rank preserved)
2^-4        :  230/256
2^-3        :   14/256
2^-2        :    0/256
```

**The router keeps its full routing rank, certified, down to 2^-5 (≈5–6 fractional bits), then collapses.**
That is a tolerance-free quantization floor: below ~5 fractional bits the experts start colliding and routing
dimensionality is lost.

## Finding 3 — the floor is *not uniform*: early layers are more precision-sensitive

Certified rank/256 of each router at the transition resolutions (same `256 × 1024` block for all, so the
comparison is apples-to-apples):

```
layer   2^-6  2^-5  2^-4  2^-3
blk.3   256   256   230    14
blk.4   256   256   247    40
blk.5   256   256   256   101
blk.6   256   256   256   145
blk.7   256   256   256   228
blk.8   256   256   256   173
```

Clear, monotone-ish trend: **later MoE-layer routers tolerate coarser quantization than earlier ones.** At
2^-4, blk.3 has already lost 26 dims while blk.5–8 are still full. At 2^-3, blk.3 retains only 14/256 but blk.7
retains 228/256. This is a **certified, per-layer, mixed-precision guide for R1's routers**: the early-MoE
routers (blk.3–4) need more bits; the later ones can be quantized harder with no loss of routing rank.

## Honest scope

- Full-precision full-rank (Finding 1) is **certified exactly** (submatrix saturation + two-prime agreement).
- The coarse-resolution ranks (Findings 2–3) are computed on a `256 × 1024` block, so at coarse scales they are
  **lower bounds** on the full-router rank (more columns could recover some rank). The *comparison across
  layers* is fair (identical block for all), and the qualitative results — a floor near 2^-5, early layers more
  sensitive — are robust. Tightening the exact transition numbers means re-running with more columns.
- "Quantize the router to N bits" here means the *routing-rank-preserving* floor, not an end-to-end accuracy
  claim; the exact rank certifies expert distinguishability, which is necessary (not sufficient) for routing
  fidelity.

## Why this needed exact arithmetic

Every number above is a certified integer with **no ε**. Floating-point "numerical rank" would require an
arbitrary tolerance and give a different answer for each choice — precisely the ambiguity that makes a
per-layer quantization floor un-certifiable by float. The exact GF(p) rank, two-prime-checked, removes the
tolerance entirely.

## Next targets (unbuilt)

The genuinely large certified low-rank in R1 is the **MLA / factored attention** (`attn_q_a/b`, `attn_kv_a/b`)
— designed low-rank, but stored Q4_K/Q6_K. Reaching it needs a K-quant dequantizer; then exact rank of each
factor would certify R1's designed compression exactly, and reveal any *further* exact compressibility below the
designed bottleneck.
