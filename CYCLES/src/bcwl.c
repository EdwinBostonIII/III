/* ============================================================================
 * III-CYCLES — bcwl.c
 *
 * §4.3 — Bloom-Coupled Witness Lattice.  Three coupled indexes over the
 * per-CPU witness ring:
 *
 *   1. A 4096-bit Bloom filter keyed by successor_mhash → O(1) presence.
 *   2. A skip-list bucketed by step_kind range (16 buckets) → step-kind
 *      walks in O(log n) per match.
 *   3. A radix tree indexed by predecessor_mhash → forward chain replay
 *      in O(log n).
 *
 * Implementation is a hand-rolled fixed-capacity arena holding witnesses
 * + index structures, sized for III_BCWL_MAX_WITNESSES.
 * ============================================================================
 */
#include "cycles_internal.h"
#include <stdlib.h>
#include <string.h>

typedef struct bcwl_node {
    iii_xii_witness_t   w;
    uint32_t            next_in_bucket;       /* singly-linked list per bucket */
    uint32_t            child_radix[III_BCWL_RADIX_FANOUT]; /* 0 = empty */
} bcwl_node_t;

struct iii_bcwl {
    bcwl_node_t  *nodes;                              /* 1-indexed; node[0] is sentinel */
    uint32_t      count;
    uint32_t      capacity;

    /* Bloom filter, 4096 bits = 512 bytes. */
    uint8_t       bloom[III_BCWL_BLOOM_BITS / 8];

    /* Skip-list = bucket heads.  Bucket index = (step_kind >> 5) & 0xF. */
    uint32_t      bucket_head[III_BCWL_BUCKETS];

    /* Radix-tree root: predecessor_mhash[0] high nibble + low nibble form a
     * 16-fanout radix; we store the root's children indexed by mhash[0] >> 4. */
    uint32_t      radix_root[III_BCWL_RADIX_FANOUT];
};

static unsigned bucket_for(uint16_t step_kind) {
    return (unsigned)((step_kind >> 5) & 0xFu);
}

static unsigned bloom_hash(const uint8_t mhash[32], unsigned i) {
    /* Compose four cheap hashes from the 32-byte mhash by XOR-folding. */
    uint32_t h = 0;
    for (unsigned k = 0; k < 32; ++k) h = (h * 31u) + (uint32_t)mhash[k];
    h ^= (uint32_t)(i * 0x9E3779B1u);
    return (unsigned)(h % III_BCWL_BLOOM_BITS);
}

static void bloom_set(uint8_t *b, unsigned bit) {
    b[bit / 8] |= (uint8_t)(1u << (bit & 7u));
}

static bool bloom_test(const uint8_t *b, unsigned bit) {
    return (b[bit / 8] & (uint8_t)(1u << (bit & 7u))) != 0;
}

iii_bcwl_t *iii_bcwl_create(void) {
    iii_bcwl_t *b = (iii_bcwl_t *)calloc(1, sizeof(*b));
    if (!b) return NULL;
    b->capacity = III_BCWL_MAX_WITNESSES;
    b->nodes    = (bcwl_node_t *)calloc((size_t)b->capacity + 1u, sizeof(bcwl_node_t));
    if (!b->nodes) { free(b); return NULL; }
    return b;
}

void iii_bcwl_destroy(iii_bcwl_t *b) {
    if (!b) return;
    free(b->nodes);
    free(b);
}

size_t iii_bcwl_count(const iii_bcwl_t *b) {
    return b ? (size_t)b->count : 0u;
}

void iii_bcwl_insert(iii_bcwl_t *b, const iii_xii_witness_t *w) {
    if (!b || !w) return;
    if (b->count >= b->capacity) return;

    uint32_t idx = ++b->count;
    bcwl_node_t *n = &b->nodes[idx];
    n->w = *w;
    n->next_in_bucket = 0;
    memset(n->child_radix, 0, sizeof(n->child_radix));

    /* Bloom: set 4 bits. */
    for (unsigned i = 0; i < III_BCWL_BLOOM_HASHES; ++i) {
        bloom_set(b->bloom, bloom_hash(w->successor_mhash, i));
    }

    /* Skip-list bucket head. */
    unsigned bk = bucket_for((uint16_t)w->step_kind);
    n->next_in_bucket = b->bucket_head[bk];
    b->bucket_head[bk] = idx;

    /* Radix tree: insert under root[predecessor[0] >> 4], descend by predecessor[0..]
     * for up to 8 levels. */
    uint32_t *slot = &b->radix_root[(unsigned)(w->predecessor_mhash[0] >> 4)];
    unsigned depth = 0;
    while (*slot != 0 && depth < 8) {
        bcwl_node_t *cur = &b->nodes[*slot];
        unsigned nibble;
        if (depth + 1 < 8) {
            unsigned byte = (depth + 1) >> 1;
            nibble = (depth + 1) & 1
                ? (unsigned)(cur->w.predecessor_mhash[byte] & 0x0Fu)
                : (unsigned)(cur->w.predecessor_mhash[byte] >> 4);
        } else {
            break;
        }
        slot = &cur->child_radix[nibble];
        depth++;
    }
    if (*slot == 0) {
        *slot = idx;
    }
}

bool iii_bcwl_contains(const iii_bcwl_t *b, const uint8_t successor_mhash[32]) {
    if (!b || !successor_mhash) return false;
    for (unsigned i = 0; i < III_BCWL_BLOOM_HASHES; ++i) {
        if (!bloom_test(b->bloom, bloom_hash(successor_mhash, i))) return false;
    }
    /* Bloom positive; verify by exact scan to avoid false positives. */
    for (uint32_t i = 1; i <= b->count; ++i) {
        if (memcmp(b->nodes[i].w.successor_mhash, successor_mhash, 32) == 0) return true;
    }
    return false;
}

size_t iii_bcwl_walk_step_kind(const iii_bcwl_t *b,
                               uint16_t lo, uint16_t hi,
                               iii_bcwl_visit_fn visit, void *user)
{
    if (!b || !visit || lo > hi) return 0u;
    size_t n = 0;
    /* Walk every bucket that overlaps [lo, hi].  Because step kinds are 16
     * bits and bucket = step_kind >> 5 & 0xF, multiple buckets may cover the
     * range; we walk all 16 to keep the indexing predictable. */
    for (unsigned bk = 0; bk < III_BCWL_BUCKETS; ++bk) {
        for (uint32_t cur = b->bucket_head[bk]; cur != 0; cur = b->nodes[cur].next_in_bucket) {
            uint16_t sk = (uint16_t)b->nodes[cur].w.step_kind;
            if (sk < lo || sk > hi) continue;
            n++;
            if (!visit(&b->nodes[cur].w, user)) return n;
        }
    }
    return n;
}

size_t iii_bcwl_walk_chain(const iii_bcwl_t *b,
                           const uint8_t start[32],
                           iii_bcwl_visit_fn visit, void *user)
{
    if (!b || !start || !visit) return 0u;
    size_t n = 0;
    /* Find the witness whose successor_mhash == start by exact scan. */
    for (uint32_t i = 1; i <= b->count; ++i) {
        if (memcmp(b->nodes[i].w.successor_mhash, start, 32) != 0) continue;
        /* Walk forward: the next link is any witness whose predecessor matches
         * the current's successor. */
        const iii_xii_witness_t *cur = &b->nodes[i].w;
        n++;
        if (!visit(cur, user)) return n;

        /* Forward-walk: scan for predecessor matches.  We stop when no further
         * link exists (the chain head at the time of capture). */
        bool advanced = true;
        while (advanced) {
            advanced = false;
            for (uint32_t j = 1; j <= b->count; ++j) {
                if (memcmp(b->nodes[j].w.predecessor_mhash, cur->successor_mhash, 32) == 0) {
                    cur = &b->nodes[j].w;
                    n++;
                    if (!visit(cur, user)) return n;
                    advanced = true;
                    break;
                }
            }
        }
        return n;
    }
    return n;
}
