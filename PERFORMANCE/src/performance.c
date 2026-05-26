/* III-PERFORMANCE — runtime implementation. */
#include "iii/performance.h"
#include <stdlib.h>
#include <string.h>

/* ----------------------------------------------------------------------------
 * §17 — hardware features
 * ---------------------------------------------------------------------------- */
static iii_hwfeatures_t g_features;
static bool             g_features_set = false;

void iii_hw_detect(iii_hwfeatures_t *out) {
    if (!out) return;
    /* Conservative defaults — modern AMD-Zen has these by default. */
    memset(out, 0, sizeof(*out));
#if defined(__x86_64__) || defined(_M_X64)
    out->sha_ni     = false;   /* default off; caller may override after CPUID. */
    out->aes_ni     = true;
    out->avx2       = true;
    out->avx512_bw  = false;
    out->bmi1       = true;
    out->bmi2       = true;
    out->rdrand     = true;
    out->rdseed     = true;
    out->tsc        = true;
#elif defined(__aarch64__)
    out->armv8_sha2 = true;
    out->tsc        = true;
#elif defined(__riscv)
    out->riscv_zksh = false;
    out->tsc        = true;
#endif
}

void iii_hw_override(const iii_hwfeatures_t *features) {
    if (!features) return;
    g_features = *features;
    g_features_set = true;
}

const iii_hwfeatures_t *iii_hw_features(void) {
    if (!g_features_set) {
        iii_hw_detect(&g_features);
        g_features_set = true;
    }
    return &g_features;
}

void iii_hw_dispatch_init(iii_dispatch_t *out) {
    if (!out) return;
    memset(out, 0, sizeof(*out));
    const iii_hwfeatures_t *h = iii_hw_features();
    out->sha256_path = h->sha_ni     ? III_PATH_SHA_NI
                     : h->armv8_sha2 ? III_PATH_ARM_SHA2
                     : h->riscv_zksh ? III_PATH_RISCV_ZKSH
                                     : III_PATH_SOFTWARE;
    out->blake3_path = h->avx512_bw ? III_PATH_AVX512
                     : h->avx2       ? III_PATH_AVX2
                                     : III_PATH_SOFTWARE;
    out->shake256_path = h->sha3_ni ? III_PATH_SHA3_NI : III_PATH_SOFTWARE;
    out->hmac_path     = (h->avx512_bw || h->sha_ni) ? III_PATH_AVX512 : III_PATH_SOFTWARE;
    out->hexad_compose_path = h->avx512_bw ? III_PATH_AVX512 : III_PATH_SOFTWARE;
    out->hmac_simd_lanes = h->avx512_bw ? 8u : (h->avx2 ? 4u : 1u);
}

const char *iii_path_name(iii_path_t p) {
    switch (p) {
        case III_PATH_SOFTWARE:    return "software";
        case III_PATH_SHA_NI:      return "sha-ni";
        case III_PATH_SHA3_NI:     return "sha3-ni";
        case III_PATH_AES_NI:      return "aes-ni";
        case III_PATH_AVX2:        return "avx2";
        case III_PATH_AVX512:      return "avx512";
        case III_PATH_ARM_SHA2:    return "arm-sha2";
        case III_PATH_RISCV_ZKSH:  return "riscv-zksh";
        default:                   return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * §3 — SCBA
 * ---------------------------------------------------------------------------- */
void iii_scba_clear(iii_scba_t *s) { if (s) memset(s->words, 0, sizeof(s->words)); }
void iii_scba_set(iii_scba_t *s, uint32_t bit) {
    if (!s || bit >= III_SCBA_BIT_COUNT) return;
    s->words[bit >> 6] |= ((uint64_t)1u << (bit & 63));
}
void iii_scba_unset(iii_scba_t *s, uint32_t bit) {
    if (!s || bit >= III_SCBA_BIT_COUNT) return;
    s->words[bit >> 6] &= ~((uint64_t)1u << (bit & 63));
}
bool iii_scba_test(const iii_scba_t *s, uint32_t bit) {
    if (!s || bit >= III_SCBA_BIT_COUNT) return false;
    return (s->words[bit >> 6] >> (bit & 63)) & 1u;
}

/* ----------------------------------------------------------------------------
 * §4 — Ladder
 * ---------------------------------------------------------------------------- */
void iii_ladder_record(iii_ladder_t *l, unsigned level) {
    if (!l) return;
    if (level < III_LADDER_LEVELS) l->check_count[level]++;
    l->total++;
}

/* ----------------------------------------------------------------------------
 * §5 — Pre-warm
 * ---------------------------------------------------------------------------- */
void iii_prewarm_record(iii_prewarm_t *p, bool ok) {
    if (!p) return;
    p->predictions++;
    if (ok) p->hits++; else p->misses++;
}
uint16_t iii_prewarm_hit_rate_q14(const iii_prewarm_t *p) {
    if (!p || p->predictions == 0) return 0;
    return (uint16_t)((p->hits * 16384u) / p->predictions);
}

/* ----------------------------------------------------------------------------
 * §6 — Lock-free SPSC ring (model)
 * ---------------------------------------------------------------------------- */
struct iii_ring {
    iii_ring_slot_t  slots[III_RING_CAP];
    /* head: producer's next-write index; tail: consumer's next-read index. */
    uint64_t         head;
    uint64_t         tail;
    uint32_t         cpu_id;
    uint32_t         numa_node;
};

iii_ring_t *iii_ring_create(uint32_t cpu_id, uint32_t numa_node) {
    iii_ring_t *r = (iii_ring_t *)calloc(1, sizeof(*r));
    if (!r) return NULL;
    r->cpu_id = cpu_id;
    r->numa_node = numa_node;
    return r;
}
void iii_ring_destroy(iii_ring_t *r) { if (r) free(r); }

uint32_t iii_ring_numa_node(const iii_ring_t *r) { return r ? r->numa_node : 0u; }

bool iii_ring_try_push(iii_ring_t *r, const iii_ring_slot_t *slot) {
    if (!r || !slot) return false;
    if ((r->head - r->tail) >= III_RING_CAP) return false;
    r->slots[r->head % III_RING_CAP] = *slot;
    r->head++;
    return true;
}

bool iii_ring_try_pop(iii_ring_t *r, iii_ring_slot_t *out) {
    if (!r || !out) return false;
    if (r->head == r->tail) return false;
    *out = r->slots[r->tail % III_RING_CAP];
    r->tail++;
    return true;
}

size_t iii_ring_occupancy(const iii_ring_t *r) {
    if (!r) return 0;
    return (size_t)(r->head - r->tail);
}

size_t iii_ring_capacity(const iii_ring_t *r) {
    (void)r;
    return III_RING_CAP;
}

unsigned iii_ring_occupancy_pct(const iii_ring_t *r) {
    if (!r) return 0;
    uint64_t occ = r->head - r->tail;
    return (unsigned)((occ * 100u) / III_RING_CAP);
}

bool iii_ring_is_saturated(const iii_ring_t *r) {
    return iii_ring_occupancy_pct(r) > 75u;
}

size_t iii_ring_try_push_batch(iii_ring_t            *r,
                               const iii_ring_slot_t *slots,
                               size_t                 n)
{
    if (!r || !slots) return 0;
    size_t free_slots = III_RING_CAP - (size_t)(r->head - r->tail);
    if (n > free_slots) return 0;        /* §14 — atomic-or-nothing */
    for (size_t i = 0; i < n; ++i) {
        r->slots[(r->head + i) % III_RING_CAP] = slots[i];
    }
    r->head += n;
    return n;
}

/* ----------------------------------------------------------------------------
 * §7 — Möbius rolling sum
 * ---------------------------------------------------------------------------- */
void iii_mobius_init(iii_mobius_t *m) { if (m) memset(m, 0, sizeof(*m)); }

void iii_mobius_update(iii_mobius_t *m, uint32_t num_inc, uint32_t den_inc) {
    if (!m) return;
    m->numerator   += num_inc;
    m->denominator += den_inc;
    m->since_sample++;
    if (m->since_sample >= III_MOBIUS_SAMPLE_PERIOD) {
        iii_mobius_sample(m);
    }
}

uint16_t iii_mobius_sample(iii_mobius_t *m) {
    if (!m) return 0;
    if (m->denominator == 0) return 0;
    /* coherence_q14 = (num/den) in q14 */
    uint64_t q14 = (m->numerator * 16384ull) / m->denominator;
    if (q14 > 16384ull) q14 = 16384ull;
    m->last_sample_q14 = (uint16_t)q14;
    m->since_sample = 0;
    return m->last_sample_q14;
}

/* ----------------------------------------------------------------------------
 * §8 — Compacted hexad table
 * ---------------------------------------------------------------------------- */
bool iii_hexad_compact_admit(const iii_hexad_table_compact_t *t, unsigned idx) {
    if (!t || idx >= III_HEXAD_SLOT_COUNT) return false;
    return (t->admissible[idx >> 3] >> (idx & 7u)) & 1u;
}

unsigned iii_hexad_compact_composition(const iii_hexad_table_compact_t *t, unsigned idx) {
    if (!t || idx >= III_HEXAD_SLOT_COUNT) return 0;
    /* 6-bit field per slot; pack 2 fields per 12 bits = 1.5 bytes; we use a
     * simpler 6 bit lookup over 14 bytes by treating composition as a 6-bit
     * field starting at bit (idx * 6). */
    unsigned bit_off = idx * 6;
    unsigned byte_off = bit_off >> 3;
    unsigned shift   = bit_off & 7u;
    if (byte_off + 1 >= 14u) return 0;
    uint16_t w = (uint16_t)t->composition[byte_off] | ((uint16_t)t->composition[byte_off + 1] << 8);
    return (w >> shift) & 0x3Fu;
}

void iii_hexad_compact_set_admit(iii_hexad_table_compact_t *t, unsigned idx, bool admit) {
    if (!t || idx >= III_HEXAD_SLOT_COUNT) return;
    if (admit) t->admissible[idx >> 3] |=  (uint8_t)(1u << (idx & 7u));
    else       t->admissible[idx >> 3] &= (uint8_t)~(1u << (idx & 7u));
}

void iii_hexad_compact_set_composition(iii_hexad_table_compact_t *t, unsigned idx, unsigned tag) {
    if (!t || idx >= III_HEXAD_SLOT_COUNT) return;
    unsigned bit_off = idx * 6;
    unsigned byte_off = bit_off >> 3;
    unsigned shift   = bit_off & 7u;
    if (byte_off + 1 >= 14u) return;
    uint16_t w = (uint16_t)t->composition[byte_off] | ((uint16_t)t->composition[byte_off + 1] << 8);
    w &= ~(uint16_t)(0x3Fu << shift);
    w |=  (uint16_t)((tag & 0x3Fu) << shift);
    t->composition[byte_off]     = (uint8_t)(w);
    t->composition[byte_off + 1] = (uint8_t)(w >> 8);
}

/* §16 — scalar Z₃⁶ composition */
void iii_hexad_compose_scalar(const iii_hexad_z3_6_t *src, unsigned n, iii_hexad_z3_6_t *out) {
    if (!src || !out) return;
    memset(out, 0, sizeof(*out));
    for (unsigned i = 0; i < n; ++i) {
        for (unsigned c = 0; c < 6; ++c) {
            out->component[c] = (uint8_t)(((unsigned)out->component[c] + src[i].component[c]) % 3u);
        }
    }
}

/* ----------------------------------------------------------------------------
 * §9 — cycle dispatch
 * ---------------------------------------------------------------------------- */
void iii_cycle_dispatch_init(iii_cycle_dispatch_t *d) {
    if (!d) return;
    memset(d, 0, sizeof(*d));
}

bool iii_cycle_dispatch_register(iii_cycle_dispatch_t *d,
                                 uint16_t              cycle_kind,
                                 iii_cycle_handler_fn  fn,
                                 void                 *user)
{
    if (!d || !fn) return false;
    if (cycle_kind >= III_CYCLE_DISPATCH_CAP) return false;
    d->table[cycle_kind] = fn;
    d->user[cycle_kind]  = user;
    d->version++;
    return true;
}

int iii_cycle_dispatch_invoke(iii_cycle_dispatch_t *d,
                              uint16_t              cycle_kind,
                              void                 *args)
{
    if (!d) return -1;
    if (cycle_kind >= III_CYCLE_DISPATCH_CAP) return -2;
    iii_cycle_handler_fn fn = d->table[cycle_kind];
    if (!fn) return -3;
    /* §9.3 cache version emulation */
    d->cached_version = d->version;
    return fn(args, d->user[cycle_kind]);
}

/* ----------------------------------------------------------------------------
 * §10 — Per-CPU arena (bump allocator)
 * ---------------------------------------------------------------------------- */
struct iii_arena {
    uint8_t *base;
    size_t   size;
    size_t   used;
};

iii_arena_t *iii_arena_create(size_t size) {
    iii_arena_t *a = (iii_arena_t *)calloc(1, sizeof(*a));
    if (!a) return NULL;
    a->base = (uint8_t *)calloc(1, size);
    if (!a->base) { free(a); return NULL; }
    a->size = size;
    a->used = 0;
    return a;
}

void iii_arena_destroy(iii_arena_t *a) {
    if (!a) return;
    free(a->base);
    free(a);
}

void *iii_arena_acquire(iii_arena_t *a, size_t bytes) {
    if (!a || bytes == 0) return NULL;
    /* 8-byte align */
    size_t pad = (8 - (a->used & 7u)) & 7u;
    if (a->used + pad + bytes > a->size) return NULL;
    a->used += pad;
    void *p = a->base + a->used;
    a->used += bytes;
    return p;
}

void iii_arena_release(iii_arena_t *a) { if (a) a->used = 0; }
size_t iii_arena_used(const iii_arena_t *a)     { return a ? a->used : 0u; }
size_t iii_arena_capacity(const iii_arena_t *a) { return a ? a->size : 0u; }

/* ----------------------------------------------------------------------------
 * §13 — Per-CPU subkey
 * ---------------------------------------------------------------------------- */
void iii_subkey_install(iii_subkey_t *s, const uint8_t key[32], uint64_t epoch) {
    if (!s) return;
    memcpy(s->key, key, 32);
    s->epoch = epoch;
    s->flags |= 1u; /* installed */
}

void iii_subkey_invalidate(iii_subkey_t *s) {
    if (!s) return;
    memset(s->key, 0, 32);
    s->epoch = 0;
    s->flags = 0;
}

/* ----------------------------------------------------------------------------
 * §18 — Performance counters and budget
 * ---------------------------------------------------------------------------- */

const uint64_t III_PERF_BUDGET_CYCLES[III_PERF_STAGE_COUNT] = {
    [III_PERF_SCBA_TEST]            = 3,
    [III_PERF_ACC_WALL_Y]           = 3,
    [III_PERF_CYCLE_DISPATCH]       = 5,
    [III_PERF_FORWARD_HANDLER]      = 5,
    [III_PERF_RING_PUSH]            = 30,
    [III_PERF_HMAC]                 = 450,
    [III_PERF_MOBIUS_UPDATE]        = 2,
    [III_PERF_SUBKEY_ACCESS]        = 1,
    [III_PERF_CLOSURE_FETCH]        = 1
};

void iii_perf_init(iii_perf_t *p) { if (p) memset(p, 0, sizeof(*p)); }

void iii_perf_record(iii_perf_t *p, iii_perf_stage_t s, uint64_t cycles) {
    if (!p || s >= III_PERF_STAGE_COUNT) return;
    p->cycles[s] += cycles;
    p->count[s]++;
}

uint64_t iii_perf_average(const iii_perf_t *p, iii_perf_stage_t s) {
    if (!p || s >= III_PERF_STAGE_COUNT) return 0;
    if (p->count[s] == 0) return 0;
    return p->cycles[s] / p->count[s];
}

const char *iii_perf_stage_name(iii_perf_stage_t s) {
    switch (s) {
        case III_PERF_SCBA_TEST:        return "scba-test";
        case III_PERF_ACC_WALL_Y:       return "acc-wall-y";
        case III_PERF_CYCLE_DISPATCH:   return "cycle-dispatch";
        case III_PERF_FORWARD_HANDLER:  return "forward-handler";
        case III_PERF_RING_PUSH:        return "ring-push";
        case III_PERF_HMAC:             return "hmac";
        case III_PERF_MOBIUS_UPDATE:    return "mobius-update";
        case III_PERF_SUBKEY_ACCESS:    return "subkey-access";
        case III_PERF_CLOSURE_FETCH:    return "closure-fetch";
        default:                        return "unknown";
    }
}

bool iii_perf_within_budget(const iii_perf_t *p) {
    if (!p) return false;
    for (unsigned s = 0; s < III_PERF_STAGE_COUNT; ++s) {
        if (p->count[s] == 0) continue;     /* not measured -> trivially within */
        uint64_t avg = iii_perf_average(p, (iii_perf_stage_t)s);
        if (avg > III_PERF_BUDGET_CYCLES[s]) return false;
    }
    return true;
}
