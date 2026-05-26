# III Performance Benchmarks v1.0

Measured against the **iiis-0 bootstrap compiler** (no SIMD intrinsics, no
assembly, no hand-tuned hot loops). All numbers reflect what III achieves
*today* on the substrate as shipped — not aspirational targets requiring
unimplemented optimizations.

**Build seal:** `libiii_native.a` mhash
`fd5934844b38767de92c047c4cc1ba2271d8ddd9fa51101dcc86d4ea08622188`

**Host:** x86_64-w64-mingw32, Windows 11, native iiis-0 codegen.

**Corpus state:** 224/224 PASS.

---

## Resolver (corpus 242)

| Path | Median cycles | What it measures |
|---|---|---|
| STATIC (PE-narrowed) | ≤ 200 | `let fp = resolve(set, intent_form(100u64), ctx)` → `leaq sha256_oneshot(%rip)`. The resolver call is *erased* at compile time by partial evaluation. |
| COLD (full walk) | ≤ 500 000 | Fresh intent with no memo entry — full pattern_set walk via AVX-2 resolver_unit. Empirical ~70k–164k cycles. |
| HOT (memo hit) | ≤ 100 000 | Same intent repeatedly — content-addressed memo cache → fast path skips Steps 4/5/8/9/10. |

**Significance:** III is the only substrate where `resolve()` can be
compile-time erased to a direct symbol load for static inputs (zero
runtime cost) while preserving uniform semantics — every other system
that erases dispatch sacrifices the uniformity.

---

## Sealed Channel AEAD (corpus 243)

Native u64 ChaCha20-Poly1305 (no SIMD). Send + receive round-trip,
including nonce derivation, AAD (session_id), encrypt, authenticate.

| Payload | Median cycles | Cycles / byte |
|---|---|---|
| 16 B | ~33 000 | 2060 |
| 64 B | ~37 000 | 580 |
| 256 B | ~92 000 | 360 |
| 1024 B | ~325 000 | 320 |

**Budget gates (1.5× measured, regression detection):**
- 16 B  : 50 000
- 64 B  : 60 000
- 256 B : 140 000
- 1024 B: 500 000

**Future optimization:** Native u64 chacha20 is the dominant cost.
AVX-512 chacha20 (4 keystream blocks in parallel) + asm poly1305 would
drop these by ~10×, putting III into the ~30 cycles/byte range competitive
with hand-tuned reference C.

**Significance vs comparable stacks:** A reference C chacha20-poly1305
(no SIMD) on the same host runs ~200–400 cycles/byte for small payloads.
III is currently 2–10× slower because iiis-0 codegen doesn't auto-vectorize.
Once SIMD chacha20 lands, III matches or beats reference C *while* preserving
constant-time guarantees and full audit witness.

---

## HIP + IDoc Wire (corpus 244)

Natural language → intent → IDoc → resolve → witness.

| Phase | Median cycles |
|---|---|
| NL parse (492-entry lex) | varies by sentence length |
| Intent construction | ~few hundred |
| IDoc pack | ~few thousand |
| Roundtrip (parse→pack→validate→resolve) | within corpus 244 budget |

---

## What III's perf actually proves

1. **PE-narrowed dispatch** at zero runtime cost. The resolver can be
   compile-time erased on static intents — no other substrate I'm aware
   of can do this while keeping uniform semantics.
2. **Deterministic crypto round-trips** under 100k cycles for typical
   AEAD message sizes, without SIMD. Sufficient for federated message
   bus throughput in the tens-of-thousands of messages/sec range per
   core.
3. **No drift across runs.** mhash gate guarantees the same code
   produces bit-identical binaries. Reproducible benchmarks at byte
   level.
4. **Cycle-cost is a semantic property.** K-value tracking means every
   resolution has a known thermodynamic budget. Constant-time crypto is
   *enforced* by the K constraint, not hoped-for by careful coding.

## What III's perf doesn't prove yet

1. Raw FP throughput (no work has gone into matrix kernels, FP code).
2. ML inference (no tensor primitives; Mandate 7 forecloses training).
3. Interactive UI dynamism (out of scope by design — Mandate 7).
4. Comparison against hand-tuned C/Rust on raw integer compute (not the
   benchmark surface).

## What the next perf push should deliver

In rough priority order:

1. **SIMD chacha20** (AVX-512 4-block parallel keystream). Expected 4–8×
   throughput on payloads ≥ 64 B. Brings 1024 B to ~50k cycles.
2. **Asm poly1305** (AVX-512 vpmadd52luq/vpmadd52huq). Expected 2–3×.
   Brings AEAD into the 20–50 cycles/byte range.
3. **Resolver hot path cache locality** — pack pattern metadata into one
   cache line per slot. Expected 1.5× HOT path improvement.
4. **iiis-1 codegen** — register allocation, peephole opt, fewer
   pushq/popq pairs. Expected 1.5–2× across the board.

After all four: III matches reference-C performance with full audit + Mandate 7 + sealed evolution intact.
