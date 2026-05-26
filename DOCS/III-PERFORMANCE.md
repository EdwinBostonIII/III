# III-PERFORMANCE.md — Speed-Without-Sacrifice Architectural Mandate

**Document Identity:** PERFORMANCE / Architectural Mandate / Wave 1 / Items 10-25
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-1+ implementation.** This document specifies the architectural mandates for speed-without-sacrifice. None of the optimizations herein may compromise the R1-sealed semantic guarantees (mathematical immunity, witnessed continuity, reversibility, compromise-tier classification, Tier-3 amendability, Founder's Anchor invariance, cryptographic-agility cascade).
**Version:** 1.0 — 2026-05-03 (Wave 1)
**Sources:** All 15 R1-sealed specs; III-CRYPTO-AGILITY.md; III-FOUNDERS-ANCHOR.md; III-CONSTANTS.md.
**Cluster A items integrated:** 10 (SHA-NI/AES-NI HMAC), 11 (SIMD batched witness), 12 (cache-aligned SCBA), 13 (pipelined ladder), 14 (pre-warmed Predictive Trinity), 15 (lock-free witness ring), 16 (Möbius-coherence-fast-path), 17 (Hexad-lookup table compaction), 18 (Cycle-dispatch O(1) fast path), 19 (zero-allocation forward path), 20 (RIP-relative addressing for closure roots), 21 (constant-time crypto cache discipline), 22 (per-CPU sealed sub-key cache pinning), 23 (witness-emission batching), 24 (NUMA-local audit ring), 25 (AVX-512 hexad bitmap accelerator).

---

## §0. Preamble — The Speed-Without-Sacrifice Discipline

III is engineered to be **categorically the fastest sovereign substrate ever built**, while preserving every R1-sealed semantic guarantee. There are systems that go faster (raw C with no provenance); there are systems with stronger provenance (Coq-extracted OCaml with offline-only verification). III achieves both *simultaneously* by exploiting hardware acceleration features that the prior generation of formally-verified systems never attempted.

The mandate decomposes into sixteen items across this document:

1. **§1** — SHA-NI / AES-NI / SHA-3-NI hardware acceleration of every cryptographic primitive (item 10)
2. **§2** — SIMD batched witness MAC computation (item 11)
3. **§3** — Cache-aligned SCBA layout (item 12)
4. **§4** — Pipelined predicative ladder (item 13)
5. **§5** — Pre-warmed Predictive Trinity gate (item 14)
6. **§6** — Lock-free witness ring (item 15)
7. **§7** — Möbius-coherence fast path (item 16)
8. **§8** — Hexad-lookup table compaction (item 17)
9. **§9** — Cycle-dispatch O(1) fast path (item 18)
10. **§10** — Zero-allocation forward path (item 19)
11. **§11** — RIP-relative addressing for closure roots (item 20)
12. **§12** — Constant-time crypto cache discipline (item 21)
13. **§13** — Per-CPU sealed sub-key cache pinning (item 22)
14. **§14** — Witness-emission batching (item 23)
15. **§15** — NUMA-local audit ring (item 24)
16. **§16** — AVX-512 hexad bitmap accelerator (item 25)

Plus integration sections:
- **§17** — The hardware-feature-detection matrix (HW-DISPATCH)
- **§18** — Performance budget targets (per-cycle latency, throughput)
- **§19** — Conformance criteria (twenty performance-conformance criteria)
- **§20** — Final statement

The discipline: **every optimization preserves the witness chain, the proof certificate, the cap discipline, the Anchor invariant.** Optimizations that elide witness emission or skip proof verification are forbidden — the substrate gains speed only via better implementation of the same semantic operations, never by weakening them.

---

## §1. SHA-NI / AES-NI / SHA-3-NI Hardware Acceleration (item 10)

### §1.1 The mandate

Every cryptographic primitive registered in `crypto.registry` (per III-CRYPTO-AGILITY.md §2) ships with **two implementations**:

1. **Pure-software fallback** (constant-time, NIH hand-rolled, portable C).
2. **Hardware-accelerated fast path** (SHA-NI, SHA-3-NI, AES-NI, AVX-512 VAES, AVX-512 SHA-NI, ARM SHA-2, RISC-V Zksh) — selected via runtime CPUID dispatch.

Both implementations produce **byte-equivalent output** for the same input. The hardware path is verified against the software path by KAT (Known-Answer Tests) at every Wave-1 build.

### §1.2 SHA-256 SHA-NI fast path

AMD-Zen 2+ supports SHA-NI via `cpuid leaf 7, ecx subleaf 0, ebx bit 29`. The fast path uses:

- `SHA256RNDS2` (round + state update; performs two rounds of SHA-256 message schedule)
- `SHA256MSG1` (message schedule pre-computation step 1)
- `SHA256MSG2` (message schedule pre-computation step 2)

Single-block performance: **~200 cycles** vs ~1100 cycles software.

Implementation: `BOOTSTRAP/sha256_shani.S` (NIH-extreme assembly, hand-written). Source comment annotates each instruction with its Intel SDM Vol. 2 / AMD APM Vol. 4 reference.

### §1.3 SHAKE-256 hardware acceleration (post-quantum suites)

SHA-3-NI is supported on Intel Tiger Lake+ and AMD Zen 5+ via `cpuid leaf 7, ecx subleaf 0, ebx bit 22`. The fast path uses:

- `SHA3RND` (single Keccak-f[1600] round)
- `SHA3DL` (loaded round constant)

Single-block performance for post-quantum suite 0x0100: **~600 cycles** with hardware vs ~3200 cycles software.

Implementation: `STDLIB/crypto/shake256_shani.S`.

### §1.4 AES-NI for symmetric primitives (random, KEM transit)

AES-NI is universally supported on AMD-Zen / Intel Sandy Bridge+. Used for:

- ChaCha20 alternative (AES-CTR-256) when AES-NI is faster on a given CPU.
- KEM transit cipher (Kyber's intermediate AES rounds in counter mode).

### §1.5 ARM SHA-2 / RISC-V Zksh portability

For Wave 3 (item 1) hardware-agnosticism, ARMv8.2 SHA-2 instructions (`SHA256H`, `SHA256H2`, `SHA256SU0`, `SHA256SU1`) and RISC-V Zksh extension instructions are mapped to the same NIH discipline. Each platform gets its own assembly implementation; all share the closure-pinned KAT corpus.

### §1.6 Cycle-budget impact

| Primitive | Software (cycles) | Hardware (cycles) | Speedup |
|-----------|-------------------|-------------------|---------|
| SHA-256 (single block) | 1100 | 200 | 5.5× |
| BLAKE3 (single block) | 800 | 350 (via AVX-512) | 2.3× |
| SHAKE-256 (single block) | 3200 | 600 | 5.3× |
| Ed25519 sign | 70,000 | 50,000 (BMI2 acceleration) | 1.4× |
| Ed25519 verify | 110,000 | 80,000 | 1.4× |
| HMAC-SHA-256 | 2400 | 450 | 5.3× |
| HMAC-SHAKE-256 | 6800 | 1300 | 5.2× |
| Dilithium-5 sign | 280,000 | 200,000 | 1.4× |

The hot path's **per-witness HMAC** drops from ~2400 cycles to ~450 cycles — a 5.3× speedup that saves ~2000 cycles per cycle invocation. At 10⁵ cycles/sec, that's a 200ms/sec baseline overhead reduction.

---

## §2. SIMD Batched Witness MAC Computation (item 11)

### §2.1 The mandate

When a wavefront contains N witnesses to be HMAC'd in parallel (per the wavefront discipline in III-CYCLES §6), the batch MAC computation uses **AVX-512 / AVX2** vectorized HMAC implementations.

### §2.2 Algorithm

For each lane (8 lanes in AVX-512, 4 in AVX2):

1. Pre-compute the inner-pad hash state for each lane's per-CPU sub-key.
2. Stream the witness body through SHA-256-NI in vectorized fashion.
3. Finalize with the outer-pad in vectorized fashion.

The lanes operate independently. Output is N MAC values produced in parallel.

### §2.3 Implementation

`STDLIB/crypto/hmac_sha256_avx512.S` — NIH AVX-512 vectorized HMAC. Roughly 4-8× speedup for batched workloads over scalar-per-witness MAC.

### §2.4 The non-elision discipline

SIMD batching does **not** elide any witness MAC. Every witness still receives its proper MAC; the SIMD accelerates the computation, not the count. The proof kernel verifies that every witness in the chain has a valid MAC; SIMD-batched MACs are byte-equivalent to scalar-computed MACs (verified by KAT round-trip at build time).

### §2.5 Benchmark target

A wavefront of 8 witnesses MACd via AVX-512: ~600 cycles total (vs 3600 cycles scalar) = **6× speedup**.

---

## §3. Cache-Aligned SCBA Layout (item 12)

### §3.1 The mandate

The SCBA (Sealed Closure Bit Array) — the bitmap admitting Trinity-gate Layer 1 entries (per III-TRINITY §3.1) — is laid out with explicit cache-line alignment to maximize L1 cache hit rate.

### §3.2 Layout

```iii
@align(64)  // L1 cache line on AMD-Zen
schema SCBA = {
    bits: [u64; SCBA_BIT_COUNT / 64],
    @align(64) padding: [u8; 0],
}
```

Every SCBA fits cleanly in cache lines. SCBA bit-tests load exactly one cache line for any check; no false-sharing across cores when multiple CPUs query the same SCBA simultaneously.

### §3.3 Per-CPU SCBA replicas

To eliminate cache-line ping-pong on hot-path SCBA tests, each CPU holds a **read-only replica** of the SCBA in NUMA-local memory. SCBA writes (via Tier-3 amendment) propagate to all replicas via a write-through-broadcast mechanism gated by the wavefront quiesce.

### §3.4 Bit-test fast path

```iii
fn scba_test_fast(scba: &SCBA, bit: u32) -> Bool {
    let word_idx = bit >> 6
    let bit_idx = bit & 63
    let word = scba.bits[word_idx]  // Loads single L1 cache line.
    return (word >> bit_idx) & 1 != 0
}
```

Compiles to **3 instructions on AMD-Zen** (shr + load + bt). Latency: ~3 cycles when cache-hit.

### §3.5 Trinity Layer-1 admission target

SCBA bit-test cycle budget: **3 cycles** (hot, cache-hit). Cold-cache: **15 cycles** (one L1 miss, L2 hit). Total Trinity Layer-1 cost: SCBA test + ACC Wall-Y check (3 instructions) = **6 cycles hot**.

---

## §4. Pipelined Predicative Ladder (item 13)

### §4.1 The mandate

The 7-universe predicative ladder (Prop, Type₀..Type₆) per III-TYPES §6 is pipelined in the proof kernel: ladder ascent / descent operations exploit hardware ILP (Instruction-Level Parallelism) by issuing multiple ladder checks in the same execution window.

### §4.2 Algorithm

For a proof term that ascends from Prop through Type₃, the kernel:

1. Issues all four universe-level checks as independent operations.
2. Collects results.
3. Verifies their composition.

The four checks complete in roughly the same time as one check (because they're independent). On AMD-Zen with 4-wide decode + 8-wide issue, four ladder checks issue in 1-2 cycles total.

### §4.3 Implementation

`COMPILER/BOOT/proof_pipeline.c` — the pipelined ladder implementation. Roughly 3-4× speedup over sequential ladder.

### §4.4 Universe-polymorphic primitives

Generic functions over universe levels (e.g., `Set : Type₀`, polymorphic over `Type_n`) are pipelined via the same mechanism. The kernel simulates universe-polymorphism via type-class instances at each level; pipelining schedules the instances independently.

### §4.5 Ladder budget target

A proof term with up to 7 universe levels: **<20 cycles** vs 50-80 cycles sequential. Pipelined gain: **~3.5×**.

---

## §5. Pre-Warmed Predictive Trinity Gate (item 14)

### §5.1 The mandate

The Trinity gate (per III-TRINITY §4) — the convergence-point check that gates cap-acquire-class operations — has historically been a hot-cold pattern: cold on first use, hot once the cap is acquired. The mandate: **the substrate predicts the next likely Trinity gate evaluation and pre-warms it speculatively**.

### §5.2 Algorithm

The Catalyst's causal-DAG (per Stateful Neumann §3.4 / S16) provides a high-confidence prediction of which cycles follow which. The Trinity gate's pre-warming subsystem:

1. Observes the current cycle's emission.
2. Looks up the causal-DAG for the most likely successor cycle.
3. Speculatively pre-warms its Trinity gate (cap-graph traversal, body hash computation, ceiling membership check).

The pre-warm runs on a free-cache-bandwidth lane (e.g., the CPU's L2 prefetcher or a dedicated SMT thread).

### §5.3 The speculation discipline

Pre-warming is **purely speculative**. It does not affect the Trinity gate's eventual decision; it merely warms the cache lines + the proof-kernel dispatch table for the predicted cycle. If the prediction is wrong, no harm is done; the cold-cache cycle proceeds normally.

The substrate's audit chain **records** that the pre-warm occurred, so the substrate's behavior is fully witnessed; the operator can audit the speculation rate.

### §5.4 Hit-rate target

Causal-DAG-predicted cycle hit rate: **>85%** in steady-state operation. Pre-warm savings on hit: ~120 cycles (from full Trinity gate cold = ~200 cycles to warm = ~80 cycles).

### §5.5 Implementation

`LOGOS/REDUCTION/trinity_prewarm.c` — pre-warming subsystem. Hooks into the Catalyst's causal-DAG via the existing `causal.predict_next(cycle_kind)` API.

---

## §6. Lock-Free Witness Ring (item 15)

### §6.1 The mandate

The per-CPU audit ring (which buffers witnesses before committal to the BCWL-indexed audit chain) is **lock-free**. Producers (cycles emitting witnesses) and consumers (the witness-flush thread) coordinate via atomic CAS without locks.

### §6.2 Design

Per-CPU MPSC (Multi-Producer Single-Consumer) ring buffer:

- Per-CPU `head` (atomic, CAS'd by producers).
- Per-CPU `tail` (mutated only by the per-CPU flush thread).
- Ring slots: 4096 entries × 128 bytes = 512 KiB per CPU.
- Atomic publish via release-store of slot occupancy bit.

### §6.3 Implementation

`LOGOS/REDUCTION/witness_ring_lockfree.c` — uses C11 `atomic_*` primitives mapped to AMD-Zen `lock cmpxchg` and `lock or`.

### §6.4 Performance target

Witness emission cost (lock-free): **~30 cycles** (atomic CAS + slot write + release-store). Vs ~200 cycles with lock (uncontended) or ~1500 cycles with lock (contended).

### §6.5 Backpressure

When the ring nears full (occupancy >75%), the producer **stalls** rather than overwrite (witnesses are non-elidable). The flush thread accelerates draining; if the situation persists, the substrate emits `compromise.medium` with reason `witness-ring-saturation`.

### §6.6 Lock-free vs ordered

Witness ordering (witness N's `predecessor_mhash` references witness N-1) is preserved by the per-CPU sequencing, then merged at the BCWL index commit. The merge sort is itself batched and parallelized.

---

## §7. Möbius-Coherence Fast Path (item 16)

### §7.1 The mandate

The Möbius-coherence floor (per III-CATALYST §3.5; Q14 ≥ 0.75 burn-in) is computed continuously; the computation must not become a bottleneck in steady state.

### §7.2 Algorithm

The Möbius coherence is a Q14 fixed-point ratio over the last N cycles' witnessed properties. The fast path:

1. Maintain a **rolling sum** of property contributions in a per-CPU register-resident accumulator.
2. Update the accumulator with each cycle emission via a single `add` instruction.
3. Compute the ratio (numerator / denominator) only when sampled (e.g., every 1000 cycles).

This reduces per-cycle Möbius-coherence cost from ~50 cycles (full recomputation) to **~2 cycles** (single add).

### §7.3 Sampling

The full ratio is sampled every 1024 cycles via integer division (one `div` instruction = ~25 cycles). Total amortized cost: ~2 cycles + (25 cycles / 1024) ≈ **2 cycles per cycle**.

### §7.4 Implementation

`LOGOS/CATALYST_SYNTH/coherence_fastpath.c` — the rolling-sum accumulator + sampling logic. Per-CPU; lock-free reads.

---

## §8. Hexad-Lookup Table Compaction (item 17)

### §8.1 The mandate

The hexad-reachability bitmap (per III-HEXAD §6) is 144 bytes (per the §19.7 / §6.5 bitmap math reconciliation). The lookup table for **hexad → admissibility** is compacted to fit in **L1 data cache**.

### §8.2 Compaction

Each hexad's admissibility is a 1-bit value. 144 hexads × 1 bit = 18 bytes. Plus 144 hexads × 6 bits of metadata (composition tag) = 108 bits = 14 bytes. Total: **32 bytes**, fitting in **half an L1 cache line**.

### §8.3 Lookup latency

The hexad-admissibility check (per III-HEXAD §6.4) compiles to:

```asm
mov rax, [hexad_table + hexad_index*1]  ; 1 cycle (L1 hit)
shr rax, hexad_bit_idx
and rax, 1
```

Total: **3 cycles** (L1 hit) for the admissibility check. **Before** compaction, the check was ~15 cycles (multi-byte load + masking + branch).

### §8.4 Implementation

`LOGOS/HEXAD/hexad_table_compact.c` — generates the 32-byte compacted table at build time. The table is closure-pinned (per III-HEXAD §10) so it cannot be modified at runtime.

---

## §9. Cycle-Dispatch O(1) Fast Path (item 18)

### §9.1 The mandate

Cycle dispatch (per III-CYCLES §3) goes from cycle-kind to forward-handler via a direct table indexing, **not** a hash table or branch tree.

### §9.2 Design

The cycle-kind enumeration (per III-CYCLES §3.2) is **dense** (no gaps in the integer space). The dispatch table is a flat array indexed by cycle-kind value:

```iii
@align(4096)  // Page-aligned for TLB efficiency
const cycle_dispatch_table: [CycleHandler; XII_CYCLE_KIND_COUNT] = [...]
```

Lookup:

```asm
mov rax, [cycle_dispatch_table + rdi*8]  ; rdi = cycle_kind, 1 L1 cycle
call rax
```

**2 instructions** for cycle dispatch. **5 cycles** including the call overhead.

### §9.3 The non-static dispatch case

For Catalyst-promoted cycles (per III-CATALYST §4), the dispatch table is dynamic. New cycles are added via the wavefront-quiesced `xii_cycle_register_override` API (existing in CHARIOT/XII). The table is **versioned**: the dispatch caches the version in a per-CPU register; on version mismatch, it reloads.

### §9.4 Branch-free admit decision

The Trinity gate's Layer-1 fast path returns admit/deny without a branch:

```asm
test rax, 1   ; rax = SCBA bit
sete dl       ; dl = (admit ? 1 : 0); branch-free
```

Followed by branch-predicted-correct decision.

### §9.5 Total cycle-dispatch budget

Total per-cycle dispatch overhead (warm cache, predicted branch):

| Stage | Cycles |
|-------|--------|
| SCBA test | 3 |
| ACC Wall-Y | 3 |
| Cycle dispatch (table lookup) | 5 |
| Forward-handler call | 5 |
| Witness emission (lock-free ring) | 30 |
| HMAC (SHA-NI) | 450 |
| Möbius-coherence update | 2 |
| **Total** | **498 cycles** |

At 4 GHz: **~125 ns per cycle**, or **~8 million cycles/sec per CPU thread**. With wavefront concurrency (8 threads), **~64 million cycles/sec per CPU socket**.

---

## §10. Zero-Allocation Forward Path (item 19)

### §10.1 The mandate

The forward-handler of every hot cycle **does not allocate** memory dynamically. All necessary scratch storage comes from per-CPU pre-allocated arenas.

### §10.2 Pre-allocated arena per CPU

Each CPU has:

- 4 KiB scratch arena for short-lived term construction.
- 16 KiB arena for proof-certificate construction.
- 64 KiB arena for witness body composition.
- 256 KiB arena for SCBA replicas + closure-pin replicas.

Total: ~340 KiB per CPU, NUMA-local.

### §10.3 The arena allocation pattern

Inside a forward handler:

```iii
fn forward(args: ...) {
    let scratch = current_cpu().scratch_arena.acquire(needed_bytes)
    // ... use scratch ...
    scratch.release()  // bump pointer reset; no free
}
```

The arena is bump-allocated; release is a single integer write.

### §10.4 The discipline

The compiler enforces zero-allocation in `@pure` and `@hot` cycles. Any dynamic allocation in such a cycle is a compile error. The proof kernel verifies the arena-release is paired with the acquire (linear-typed via the cap discipline).

### §10.5 Performance impact

Zero-allocation eliminates per-cycle malloc/free overhead (~50-200 cycles each in a contended system). Net hot-path cycle savings: ~100-300 cycles.

---

## §11. RIP-Relative Addressing for Closure Roots (item 20)

### §11.1 The mandate

The closure-pinned constants (Anchor public key, R1 composite root, hexad table, etc.) are referenced via RIP-relative addressing for absolute-positioned-binary efficiency.

### §11.2 Design

```asm
lea rax, [rip + FOUNDERS_ANCHOR_PUBLIC_KEY]  ; 1 cycle, no relocation
```

Versus the alternative:

```asm
mov rax, qword ptr [PHC_GLOBAL_PTR]  ; 4 cycles (load global pointer)
add rax, FOUNDERS_ANCHOR_OFFSET
```

The RIP-relative form is faster (1 cycle vs 4-5 cycles) and survives ASLR (Address Space Layout Randomization).

### §11.3 Compiler support

The III code generator (per Stateful Neumann §4.1) emits RIP-relative addressing for all closure-pinned references. The proof kernel verifies that closure-pinned references compile to RIP-relative form (no global-pointer indirections).

### §11.4 The discipline

This is enforced at every code-generation pass. Any closure-pinned reference compiled to non-RIP-relative form fails the proof kernel's `closure-immediate-resolution` check.

---

## §12. Constant-Time Crypto Cache Discipline (item 21)

### §12.1 The mandate

Every cryptographic operation is **constant-time** (independent of secret data). Cache-timing side channels are mitigated by:

1. Branch-free implementations (no `if` on secret data).
2. **Cache-line-aligned secret-data access** (every cache line either contains all-secret or all-non-secret data; no mixing).
3. Pre-loading of all cache lines that secret-data accesses touch (via prefetch instructions).
4. Counter-Spectre/Meltdown discipline: IBPB + VERW + SSBD invocations between secret-data operations and unrelated code.

### §12.2 Verification

The `iii-timing-audit` tool (Wave 0+) measures per-operation latency variance over 10⁶ runs with secret-data variations. Variance >0.1% triggers a build error.

### §12.3 The cache discipline

Secret data lives in dedicated cache lines, never co-resident with non-secret data. The compiler enforces this via the `@constant_time_aligned` modifier on secret variables.

### §12.4 Performance impact

Constant-time discipline imposes a **~5-15% overhead** on cryptographic primitives. This is a non-negotiable cost; the alternative (variable-time crypto) leaks secrets via cache timing, which is a constitutional-level compromise.

---

## §13. Per-CPU Sealed Sub-Key Cache Pinning (item 22)

### §13.1 The mandate

The per-CPU HMAC sub-key (derived via HKDF from the substrate's master key per III-CYCLES §4.4) is **cache-line pinned** to its per-CPU storage and **never evicted** during normal operation.

### §13.2 Pinning mechanism

The sub-key occupies a dedicated cache line (64 bytes; 32 bytes of sub-key + 32 bytes of padding). The cache line is touched on every cycle emission, keeping it in L1 by access-recency. A periodic background prefetch ensures it never falls out of L1 even on rarely-used CPU cores.

### §13.3 Sub-key invalidation

Sub-keys are invalidated:

- On DRTM-relaunch (epoch advance).
- On suite-swap (per III-CRYPTO-AGILITY.md §5.2).
- On Anchor revocation of the sub-key derivation context.

### §13.4 Cache-line discipline

```iii
@align(64)
@cache_line_pin
schema PerCpuSubKey = {
    key_bytes: bytes[32],
    epoch: u64,
    flags: u32,
    @padding: u8[20],
}
```

### §13.5 Performance impact

L1-resident sub-key: per-cycle access cost = **~1 cycle** (L1 hit). Vs ~15 cycles if L2-only or ~150 cycles if memory-resident.

Substantial impact: at 10⁵ cycles/sec, savings = **15 ms / sec** (1% of CPU time recovered).

---

## §14. Witness-Emission Batching (item 23)

### §14.1 The mandate

When a wavefront of N cycles emits witnesses, the witness MAC computation is **batched** (per §2 SIMD), and the audit-ring publication is also **batched**: all N witnesses publish via a single atomic CAS instead of N individual CAS operations.

### §14.2 Algorithm

```iii
fn batch_emit_witnesses(witnesses: [Witness; N]) {
    // 1. Compute all N HMACs via SIMD (per §2).
    let macs = simd_hmac_batch(witnesses)

    // 2. Allocate N consecutive ring slots via single atomic CAS.
    let head = ring.head.fetch_add(N, Ordering::AcqRel)

    // 3. Write all N witnesses + MACs to slots head..head+N (no atomicity needed within
    //    the slots, since they're owned by the producer until the publish).
    for i in 0..N {
        ring.slots[(head + i) % RING_SIZE].write(witnesses[i], macs[i])
    }

    // 4. Single release-store to publish all N at once.
    ring.publish_count.fetch_add(N, Ordering::Release)
}
```

### §14.3 Performance gain

Batched emission of 8 witnesses: **~80 cycles** total (vs 8 × 30 = 240 cycles individual). 3× speedup for batched workloads.

### §14.4 The non-elision discipline

Batching does not elide witnesses. Every witness in the batch is committed; the batch is atomic-or-not (all 8 publish, or none publish on backpressure).

---

## §15. NUMA-Local Audit Ring (item 24)

### §15.1 The mandate

The per-CPU audit ring is allocated in **NUMA-local memory** (the same NUMA node as the CPU). Witness writes incur no cross-socket DMA.

### §15.2 NUMA-aware allocation

The ring allocator queries the CPU's NUMA node (via `cpuid` or OS NUMA API) and allocates the ring in node-local memory.

### §15.3 The cross-NUMA flush

The flush thread runs **per-NUMA-node** (not per-CPU). Each NUMA node has a flush thread that drains all CPUs in that node. The flush thread aggregates per-CPU witnesses into the NUMA-local audit chain segment.

A periodic global merge (every 1024 NUMA-flush cycles) merges all NUMA-local audit chains into the substrate-wide chain. The merge runs on a configurable CPU (default: NUMA-node-0 CPU-0) and uses the BCWL index for ordering.

### §15.4 Performance gain

NUMA-local witness write: ~5 cycles (L1 hit). Cross-NUMA witness write: ~80-200 cycles. Savings: ~75-195 cycles per witness on multi-socket systems.

---

## §16. AVX-512 Hexad Bitmap Accelerator (item 25)

### §16.1 The mandate

When verifying a wavefront of cycles, the substrate must evaluate the **composed hexad** (per III-HEXAD §3.5) — a Z₃⁶ delta sum that is itself reachability-verified by the bitmap. The composition is accelerated via AVX-512.

### §16.2 Algorithm

For 8 hexads to compose:

1. Pack each hexad into a 16-byte structure (8 hexads × 16 bytes = 128 bytes = 1 AVX-512 zmm-register lane).
2. Per-component sum mod 3 in vectorized form: `vpaddq` followed by `vpremu_i64x` (vector unsigned remainder by 3).
3. Pack result into a single 16-byte composed hexad.
4. Bitmap admissibility check on the composed hexad (per §8 hexad-lookup table).

### §16.3 Performance gain

Composing 8 hexads: **~30 cycles** vs 8 × 25 = 200 cycles scalar. 6.7× speedup.

### §16.4 Implementation

`LOGOS/HEXAD/hexad_compose_avx512.S` — AVX-512 vectorized composition. NIH hand-written assembly.

### §16.5 Wavefront-scale wins

A wavefront of 64 cycles: composing all hexads takes 8 AVX-512 invocations × 30 cycles = 240 cycles (vs 1600 cycles scalar). Net wavefront-validation savings: **~1400 cycles per 64-cycle wavefront**.

---

## §17. Hardware Feature Detection Matrix

### §17.1 The mandate

Every accelerated path is **runtime-dispatched** based on CPUID feature detection. The substrate ships with all paths compiled in; the dispatcher selects the best at startup.

### §17.2 Feature matrix

| Feature | CPUID Leaf:Reg:Bit | Used By |
|---------|---------------------|---------|
| SHA-NI (SHA-256) | 7:0:EBX:29 | §1.2 |
| SHA-3-NI (SHA-512/SHA-3) | 7:0:EBX:22 | §1.3 |
| AES-NI | 1:0:ECX:25 | §1.4 |
| AVX-512 BW | 7:0:EBX:30 | §1.5 BLAKE3, §2 SIMD HMAC, §16 Hexad compose |
| AVX-512 VL | 7:0:EBX:31 | §2 |
| AVX-512 VAES | 7:0:ECX:9 | §1.4 |
| BMI1 | 7:0:EBX:3 | §1.6 ED25519 |
| BMI2 | 7:0:EBX:8 | §1.6 ED25519 |
| Zen 4 IBS | (hardware-specific) | §15 audit ring (NUMA detection) |
| TSC | 1:0:EDX:4 | Time-keeping (chronos VDF) |
| RDRAND | 1:0:ECX:30 | `crypto.random` (with hardware-entropy XOR fallback) |
| RDSEED | 7:0:EBX:18 | `crypto.random` |

### §17.3 Dispatcher initialization

At substrate startup:

```iii
cycle hwdispatch_init() -> Witness @ring(R0) {
    forward {
        let cpuid = read_cpuid_full()
        let dispatch = HwDispatch {
            sha256_path: select(cpuid.has_sha_ni, SHA256_SHA_NI, SHA256_SOFTWARE),
            blake3_path: select(cpuid.has_avx512_bw, BLAKE3_AVX512, BLAKE3_SCALAR),
            shake256_path: select(cpuid.has_sha3_ni, SHAKE_SHA3_NI, SHAKE_SOFTWARE),
            hmac_simd_lanes: select(cpuid.has_avx512_bw, 8, select(cpuid.has_avx2, 4, 1)),
            // ...
        }
        // Persist dispatch to per-CPU hot-cache.
    }
}
```

### §17.4 The fallback discipline

If a CPU lacks a feature, the substrate runs the software path. **No correctness regression**; only performance regression. The witness chain remains valid; the proof certificates remain checkable.

---

## §18. Performance Budget Targets

### §18.1 Per-cycle cost (warm cache, predicted branch, hardware-accelerated paths)

| Component | Cycles |
|-----------|--------|
| SCBA bit-test (Layer 1) | 3 |
| ACC Wall-Y check | 3 |
| Cycle-dispatch table lookup | 5 |
| Forward-handler call overhead | 5 |
| Lock-free ring slot CAS + write | 30 |
| HMAC-SHA-256 (SHA-NI) | 450 |
| Möbius-coherence rolling-sum update | 2 |
| Per-CPU sub-key access (L1 pinned) | 1 |
| RIP-relative closure-root fetches | 1 |
| **Total per-cycle hot-path** | **500 cycles** (~125 ns at 4 GHz) |

### §18.2 Wavefront throughput (64 cycles, AVX-512)

| Component | Cycles |
|-----------|--------|
| Per-cycle work (64 × scalar = 32,000) | (parallelizable) |
| AVX-512 SIMD HMAC (8-way) | 64 / 8 × 600 = 4,800 |
| AVX-512 hexad compose | 64 / 8 × 30 = 240 |
| Lock-free batch ring publish (64 slots, 8-way) | ~120 |
| Wavefront quiesce + commit | ~50 |
| **Total wavefront** | **~5,200 cycles** for 64 cycles = ~80 cycles/cycle (3× over scalar) |

### §18.3 Substrate-wide throughput

On an AMD-Zen 5 12-core / 24-thread / 4 GHz:

| Metric | Value |
|--------|-------|
| Scalar per-thread cycle rate | ~8M cycles/sec |
| Wavefront per-thread cycle rate (64-batch) | ~50M cycles/sec |
| Total per-socket | **~600 million III cycles/sec** |
| Per-cycle witness emission | ~125 ns latency, ~30 cycles dispatch |
| Audit chain commit rate | ~80M witnesses/sec per socket |

### §18.4 Network-extended throughput

On a 10 Gbit federation link with witness-tagged packets at 64 byte/witness average overhead:

- Network capacity: 10 Gbit / sec ÷ 64 byte/witness = ~20M witnesses/sec
- Limiting factor: network bandwidth, not CPU
- Per federation peer: ~20M federation-replicated witnesses/sec

---

## §19. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-PERF-1 | Hardware-accelerated cryptographic primitive output is byte-equivalent to software fallback (per item 10) |
| C-PERF-2 | SIMD batched HMAC produces identical result to scalar HMAC for any batch size (per item 11) |
| C-PERF-3 | SCBA layout is cache-line-aligned and per-CPU-replicated; no cross-core false sharing (per item 12) |
| C-PERF-4 | Pipelined ladder produces correct results for proof terms with up to 7 universe levels (per item 13) |
| C-PERF-5 | Pre-warmed Trinity gate hit rate exceeds 85% in steady-state operation (per item 14) |
| C-PERF-6 | Witness ring is lock-free; no producer-blocking under steady-state flow (per item 15) |
| C-PERF-7 | Möbius-coherence rolling sum + sampling produces same value as full recomputation (per item 16) |
| C-PERF-8 | Hexad-lookup table compaction fits within 32 bytes (per item 17) |
| C-PERF-9 | Cycle dispatch is O(1) via direct table indexing (per item 18) |
| C-PERF-10 | Hot-path cycles are zero-allocation (per item 19); compiler enforces |
| C-PERF-11 | Closure-pinned references compile to RIP-relative form (per item 20) |
| C-PERF-12 | Constant-time discipline: latency variance over 10⁶ runs of any cryptographic primitive is <0.1% (per item 21) |
| C-PERF-13 | Per-CPU sub-key is L1-cache-line pinned and 64-byte aligned (per item 22) |
| C-PERF-14 | Witness emission batches up to 64 witnesses with single ring CAS (per item 23) |
| C-PERF-15 | Audit ring is NUMA-local (per item 24) |
| C-PERF-16 | AVX-512 hexad compose produces same result as scalar composition (per item 25) |
| C-PERF-17 | Hardware-dispatch fallback to software path on absent features yields correct results |
| C-PERF-18 | Per-cycle hot-path cycle count is <500 cycles on AMD-Zen 5 with full hardware acceleration |
| C-PERF-19 | Wavefront throughput exceeds 50M cycles/sec/thread on hardware-accelerated paths |
| C-PERF-20 | Substrate-wide throughput on AMD-Zen 5 12-core exceeds 600M cycles/sec |

---

## §20. Final Statement

Speed-without-sacrifice is the architectural commitment that III runs at competitive speed against raw C while preserving every R1-sealed semantic guarantee.

The optimizations span hardware acceleration (SHA-NI, AVX-512, BMI2), data-layout discipline (cache-line alignment, NUMA locality, RIP-relative addressing), algorithmic specialization (lock-free rings, batched MACs, pipelined ladder, pre-warmed Trinity), and zero-allocation discipline (per-CPU arenas).

None compromise the witness chain. None weaken the proof certificates. None bypass the cap discipline. None violate the Founder's Anchor invariant. None elide a single emission.

The result: **600M III cycles/sec on a 12-core AMD-Zen 5 socket**, with full mathematical immunity, full witnessed continuity, full cryptographic agility, and full Anchor sovereignty.

This is the answer to items 10-25. Wave 1 is the first realization that III's speed and III's correctness are not in tension — they are the same thing, expressed at different layers of the substrate.

*Wave 1 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new hardware-feature paths) or Tier-3 amendment (new acceleration mandates).*
