/* ============================================================================
 * III-PERFORMANCE — Speed-Without-Sacrifice mandate
 * Spec: III-PERFORMANCE.md  (Wave 1, items 10-25)
 *
 * This module owns the runtime performance machinery whose correctness can be
 * verified independently of hardware:
 *   §1   hardware feature detection + dispatcher
 *   §3/§4 cache-aligned SCBA + pipelined ladder counters
 *   §6   lock-free witness ring (single-producer/single-consumer model)
 *   §7   Möbius-coherence rolling-sum fast path
 *   §8   compacted hexad-admissibility table (32 bytes)
 *   §9   cycle-dispatch O(1) table
 *   §10  zero-allocation per-CPU arena
 *   §13  per-CPU sub-key cache pinning + invalidation
 *   §14  witness-emission batching
 *   §15  NUMA-local ring affinity
 *   §16  hexad bitmap composition (modelled in scalar; SIMD path interface)
 *   §18  performance-budget instrument (per-stage cycle counts)
 * ============================================================================
 */
#ifndef III_PERFORMANCE_H
#define III_PERFORMANCE_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §17 — hardware-feature matrix.
 * ---------------------------------------------------------------------------- */
typedef struct iii_hwfeatures {
    bool sha_ni;
    bool sha3_ni;
    bool aes_ni;
    bool avx2;
    bool avx512_bw;
    bool avx512_vl;
    bool avx512_vaes;
    bool bmi1;
    bool bmi2;
    bool rdrand;
    bool rdseed;
    bool tsc;
    /* ARM */
    bool armv8_sha2;
    /* RISC-V */
    bool riscv_zksh;
} iii_hwfeatures_t;

/* Detected once at runtime init.  In a real build this is filled from CPUID;
 * here we expose a setter so tests can drive both feature-present and
 * feature-absent configurations. */
void iii_hw_detect(iii_hwfeatures_t *out);
void iii_hw_override(const iii_hwfeatures_t *features);
const iii_hwfeatures_t *iii_hw_features(void);

/* ----------------------------------------------------------------------------
 * Dispatcher selections — for each accelerated primitive, picks the best
 * available path.  iii_hw_dispatch_init() must be called after iii_hw_*().
 * ---------------------------------------------------------------------------- */
typedef enum iii_path {
    III_PATH_SOFTWARE     = 0,
    III_PATH_SHA_NI       = 1,
    III_PATH_SHA3_NI      = 2,
    III_PATH_AES_NI       = 3,
    III_PATH_AVX2         = 4,
    III_PATH_AVX512       = 5,
    III_PATH_ARM_SHA2     = 6,
    III_PATH_RISCV_ZKSH   = 7
} iii_path_t;

typedef struct iii_dispatch {
    iii_path_t sha256_path;
    iii_path_t blake3_path;
    iii_path_t shake256_path;
    iii_path_t hmac_path;
    iii_path_t hexad_compose_path;
    unsigned   hmac_simd_lanes;
} iii_dispatch_t;

void iii_hw_dispatch_init(iii_dispatch_t *out);
const char *iii_path_name(iii_path_t p);

/* ----------------------------------------------------------------------------
 * §3 — Sealed Closure Bit Array (SCBA), cache-aligned.
 *
 * 64-byte aligned; bit-tests touch a single L1 line.  Per-CPU read-only
 * replicas are managed externally by the runtime; we expose the bit-test API.
 * ---------------------------------------------------------------------------- */
#define III_SCBA_BIT_COUNT    1024u
#define III_SCBA_WORDS        (III_SCBA_BIT_COUNT / 64u)

typedef struct iii_scba {
    /* Words must remain 64-byte aligned; alignas not used to keep MSVC-compat. */
    uint64_t words[III_SCBA_WORDS];
    uint8_t  pad[64];
} iii_scba_t;

void iii_scba_clear(iii_scba_t *s);
void iii_scba_set(iii_scba_t *s, uint32_t bit);
void iii_scba_unset(iii_scba_t *s, uint32_t bit);
bool iii_scba_test(const iii_scba_t *s, uint32_t bit);

/* ----------------------------------------------------------------------------
 * §4 — Pipelined predicative ladder counters (Type₀..Type₆).
 *
 * Count of universe-level checks issued; the actual hardware-pipelined
 * scheduling is the codegen's job.  The runtime exposes the counter so the
 * audit chain can record proof-term ladder depth. */
#define III_LADDER_LEVELS  7u

typedef struct iii_ladder {
    uint64_t check_count[III_LADDER_LEVELS];
    uint64_t total;
} iii_ladder_t;

void iii_ladder_record(iii_ladder_t *l, unsigned level);

/* ----------------------------------------------------------------------------
 * §5 — Pre-warmed Trinity gate prediction.
 *
 * Tracks predictor hit/miss and exposes the steady-state hit rate.  Real
 * pre-warming is performed by the L2 prefetcher; we model the bookkeeping. */
typedef struct iii_prewarm {
    uint64_t predictions;
    uint64_t hits;
    uint64_t misses;
} iii_prewarm_t;

void iii_prewarm_record(iii_prewarm_t *p, bool predicted_correctly);
uint16_t iii_prewarm_hit_rate_q14(const iii_prewarm_t *p);

/* ----------------------------------------------------------------------------
 * §6 — lock-free witness ring (SP-SC model).
 *
 * A real substrate uses MPSC; here the model uses SPSC for testability.  The
 * concurrency primitives match: head/tail are 64-bit counters, slots are
 * indexed by (head|tail) mod CAP. */
#define III_RING_CAP      1024u
#define III_RING_SLOT_BYTES  128u

typedef struct iii_ring_slot {
    uint8_t bytes[III_RING_SLOT_BYTES];
} iii_ring_slot_t;

typedef struct iii_ring iii_ring_t;

iii_ring_t *iii_ring_create(uint32_t cpu_id, uint32_t numa_node);
void        iii_ring_destroy(iii_ring_t *r);

bool        iii_ring_try_push(iii_ring_t *r, const iii_ring_slot_t *slot);
bool        iii_ring_try_pop(iii_ring_t *r, iii_ring_slot_t *out);
size_t      iii_ring_occupancy(const iii_ring_t *r);
size_t      iii_ring_capacity(const iii_ring_t *r);
unsigned    iii_ring_occupancy_pct(const iii_ring_t *r);
uint32_t    iii_ring_numa_node(const iii_ring_t *r);
bool        iii_ring_is_saturated(const iii_ring_t *r);  /* §6.5 — >75% */

/* §14 — batched publish: takes N slots and publishes all atomically.  Returns
 * the count actually published (0 if insufficient capacity).  This is the
 * SPSC model; in a real MPSC the head fetch_add gives an atomic reservation. */
size_t iii_ring_try_push_batch(iii_ring_t            *r,
                               const iii_ring_slot_t *slots,
                               size_t                 n);

/* ----------------------------------------------------------------------------
 * §7 — Möbius-coherence rolling sum.
 *
 *   coherence_q14 = numerator / denominator  (sampled every N updates)
 * ---------------------------------------------------------------------------- */
#define III_MOBIUS_SAMPLE_PERIOD  1024u

typedef struct iii_mobius {
    uint64_t numerator;
    uint64_t denominator;
    uint64_t since_sample;
    uint16_t last_sample_q14;   /* Q14 fixed-point */
} iii_mobius_t;

void iii_mobius_init(iii_mobius_t *m);
void iii_mobius_update(iii_mobius_t *m, uint32_t numerator_inc, uint32_t denominator_inc);
uint16_t iii_mobius_sample(iii_mobius_t *m);

/* ----------------------------------------------------------------------------
 * §8 — compacted hexad-admissibility table (32 bytes).
 *
 *   18 bytes admissibility bits (144 hexads × 1 bit)
 *   14 bytes composition tags (144 hexads × 6 bits ≈ 108 bits)
 * ---------------------------------------------------------------------------- */
#define III_HEXAD_SLOT_COUNT  144u

typedef struct iii_hexad_table_compact {
    uint8_t admissible[18];     /* §8.2 */
    uint8_t composition[14];    /* §8.2 */
} iii_hexad_table_compact_t;

bool iii_hexad_compact_admit(const iii_hexad_table_compact_t *t, unsigned idx);
unsigned iii_hexad_compact_composition(const iii_hexad_table_compact_t *t, unsigned idx);
void iii_hexad_compact_set_admit(iii_hexad_table_compact_t *t, unsigned idx, bool admit);
void iii_hexad_compact_set_composition(iii_hexad_table_compact_t *t, unsigned idx, unsigned tag);

/* §16 — vector hexad composition (scalar fallback always; AVX-512 is a
 * separate code-gen entry point in the substrate).  Composes N hexads via
 * Z₃⁶ component-wise sum. */
typedef struct iii_hexad_z3_6 {
    uint8_t component[6];   /* each 0..2 */
} iii_hexad_z3_6_t;

void iii_hexad_compose_scalar(const iii_hexad_z3_6_t *src, unsigned n,
                              iii_hexad_z3_6_t *out);

/* ----------------------------------------------------------------------------
 * §9 — cycle-dispatch O(1) table.
 * ---------------------------------------------------------------------------- */
typedef int (*iii_cycle_handler_fn)(void *args, void *user);

#define III_CYCLE_DISPATCH_CAP   1024u

typedef struct iii_cycle_dispatch {
    iii_cycle_handler_fn  table[III_CYCLE_DISPATCH_CAP];
    void                 *user[III_CYCLE_DISPATCH_CAP];
    uint64_t              version;
    uint64_t              cached_version;       /* per-CPU cache emulation */
} iii_cycle_dispatch_t;

void iii_cycle_dispatch_init(iii_cycle_dispatch_t *d);
bool iii_cycle_dispatch_register(iii_cycle_dispatch_t *d,
                                 uint16_t              cycle_kind,
                                 iii_cycle_handler_fn  fn,
                                 void                 *user);
int  iii_cycle_dispatch_invoke(iii_cycle_dispatch_t *d,
                               uint16_t              cycle_kind,
                               void                 *args);

/* ----------------------------------------------------------------------------
 * §10 — Zero-allocation per-CPU arena (bump allocator).
 * ---------------------------------------------------------------------------- */
typedef struct iii_arena iii_arena_t;

iii_arena_t *iii_arena_create(size_t size);
void         iii_arena_destroy(iii_arena_t *a);
void        *iii_arena_acquire(iii_arena_t *a, size_t bytes);
void         iii_arena_release(iii_arena_t *a);   /* bump-pointer reset */
size_t       iii_arena_used(const iii_arena_t *a);
size_t       iii_arena_capacity(const iii_arena_t *a);

/* ----------------------------------------------------------------------------
 * §13 — Per-CPU sealed sub-key cache pin.
 * ---------------------------------------------------------------------------- */
typedef struct iii_subkey {
    uint8_t  key[32];
    uint64_t epoch;
    uint32_t flags;
    uint8_t  pad[20];      /* fill to 64-byte cache line */
} iii_subkey_t;

void iii_subkey_install(iii_subkey_t *s, const uint8_t key[32], uint64_t epoch);
void iii_subkey_invalidate(iii_subkey_t *s);

/* ----------------------------------------------------------------------------
 * §18 — performance-budget instrumentation.
 *
 * Records cycles spent in each hot-path stage so a build can verify the §18.1
 * targets.  Counters are per-thread and lock-free. */
typedef enum iii_perf_stage {
    III_PERF_SCBA_TEST            = 0,
    III_PERF_ACC_WALL_Y           = 1,
    III_PERF_CYCLE_DISPATCH       = 2,
    III_PERF_FORWARD_HANDLER      = 3,
    III_PERF_RING_PUSH            = 4,
    III_PERF_HMAC                 = 5,
    III_PERF_MOBIUS_UPDATE        = 6,
    III_PERF_SUBKEY_ACCESS        = 7,
    III_PERF_CLOSURE_FETCH        = 8,
    III_PERF_STAGE_COUNT          = 9
} iii_perf_stage_t;

typedef struct iii_perf {
    uint64_t cycles[III_PERF_STAGE_COUNT];
    uint64_t count [III_PERF_STAGE_COUNT];
} iii_perf_t;

void iii_perf_init(iii_perf_t *p);
void iii_perf_record(iii_perf_t *p, iii_perf_stage_t s, uint64_t cycles);
uint64_t iii_perf_average(const iii_perf_t *p, iii_perf_stage_t s);

const char *iii_perf_stage_name(iii_perf_stage_t s);

/* §18.1 budget targets (cycles).  Used by the conformance harness. */
extern const uint64_t III_PERF_BUDGET_CYCLES[III_PERF_STAGE_COUNT];

/* True iff every recorded average is within the §18.1 budget. */
bool iii_perf_within_budget(const iii_perf_t *p);

#ifdef __cplusplus
}
#endif

#endif /* III_PERFORMANCE_H */
