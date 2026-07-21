# III as an exact topological scanner for neural weights

The AI ecosystem (PyTorch/JAX/CUDA) analyzes network weights through floating-point SVD, which needs an
arbitrary tolerance ε and *smears* any rank-deficiency across dense principal components. III treats a
K-quantized weight as what it algebraically **is** — a dyadic rational in ℤ[½] — and maps it into a prime field,
so rank, nullspace, and dependency structure come out **exact, tolerance-free, and hardware-independent**. This
document records the organs built for that and the certified findings on real DeepSeek-R1.

Every result is two-prime certified (GF(2³¹−1) and a second 31-bit prime agree ⇒ the value over ℚ) and, where a
dequant is involved, rests on a reader **verified bit-for-bit against an independent implementation**.

## The organs

| Organ | What it is | Verification |
|---|---|---|
| `kquant` | III-native exact Q4_K dequantizer: mantissa = weight·2²⁴, exact (dyadic) | hand-KAT (fp16 + full block) **and** bit-identical to metabole's dual-engine dequant on real R1 blocks (`kqcross`) |
| `gfp` | exact rank over GF(p) (Gauss–Jordan, Fermat inverse), prime-parameterized | `gfp_selfprove`, mutation-tested |
| `axioma` | proves the fold's rank is a **matroid rank function** (R1–R3) over GF(2) & GF(p) | 600 random instances, non-vacuity guard, mutation-tested |
| `attnrank` | streaming exact rank of MLA factors through the verified dequant | two-prime; early-exit at saturation |
| `circuit` | **exact matroid-circuit + nullspace extraction** with reconstruction verification | self-test finds a planted circuit; rejects column-subset false positives; two-prime |

## Certified findings on DeepSeek-R1 (shard 01)

1. **MoE routers (`ffn_gate_inp`, F32) — full rank.** All routers rank 256/256 at operational precision. R1's 256
   experts are linearly independent in routing space; expert pruning cannot be linear. (`weightrank`, `circuit`)

2. **Router quantization floor.** Routing rank is preserved down to ~2⁻⁵ (≈5–6 fractional bits); below that the
   *block* rank drops, but on the **full** 7168 columns the collapse is experts rounding to exactly zero, not
   genuine dependency. (`weightrank`, corrected by `circuit`'s full-column verification.)

3. **MLA up-projections — full rank.** `attn_kv_b` [512×32768] rank 512/512 and `attn_q_b` [1536×24576] rank
   1536/1536, every layer. DeepSeek's designed KV/Q latent bottlenecks are **fully used**; the Q4_K quantization
   introduced **no** exact low-rank collapse below the bottleneck. No "accidental" compression there. (`attnrank`)

4. **Router is structurally clean.** `circuit` finds **zero** non-trivial exact circuits among the experts at every
   precision (both primes agree). Combined with the passing self-test (it *does* find a planted circuit), this is
   a certified statement that the router contains no exact linear dependency — no redundant-expert padding, no
   hidden nullspace to sideload into. (`circuit`)

## Why these are things floating point structurally cannot produce

- **Zero-ε, data-independent:** a certified boolean ("this dimension is *exactly* dependent, or it is not") with no
  validation dataset and no calibration — impossible for SVD, which must threshold a singular value.
- **The grid, not the noise:** K-quants are discrete grids in ℤ[½]; III sees whether the grid itself collapsed
  the rank, where float sees a fuzzy full-rank cloud.
- **Circuits, not components:** by the matroid (Steinitz) structure, a dependency is returned as the exact set of
  original rows involved — the physical experts/heads — not a dense rotated basis.
- **Hardware-independent:** Fermat inverses over GF(p) yield the same integer on any machine; the "truth" of the
  structure is severed from BF16/FMA rounding differences.

## Honest scope

Trained weights are generically full rank, so the certified findings here are mostly *clean negatives* — which is
exactly the value for **integrity / provenance**: III can certify that a model's components carry no injected exact
circuits (supply-chain / watermark scanning). The extractor's power is demonstrated by the passing planted-circuit
self-test; when a real deficiency exists, it will name and verify the exact circuit. Not yet scanned: the MLA
*down*-projections (`attn_kv_a`, `attn_q_a`, ne0=7168, need the wide/transposed path) and the FFN experts. The
exact-nullspace applications the structure enables — certified zero-bleed editing, ghost-subspace watermarking,
factual-boundary mapping — are downstream of this scanner and remain to be built.
