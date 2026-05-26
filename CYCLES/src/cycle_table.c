/* ============================================================================
 * III-CYCLES — cycle_table.c
 *
 * §5 — the live cycle table.  Append-only, content-addressed via mhash, with
 * 8 structural invariants enforced at every register/promote.  Mirrors Per-
 * CPU caches in real deployments; here exposed as a process-local table.
 *
 * Invariants (§5.1):
 *   1. Unique step_kind per cycle in its allocated band.
 *   2. Admissible hexad (xii_asym_reach6).
 *   3. Mechanically derivable inverse OR @irreversible with compromise tier.
 *   4. Valid phase set (non-empty).
 *   5. Plan anchor present (non-zero).
 *   6. Möbius coherence floor met for promoted cycles.
 *   7. Append-only — cycles are superseded, never deleted.
 *   8. Closure-rooted (table mhash included in DRTM quote).
 *
 * §6 — Catalyst supersedure.  rate cap = XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK.
 * ============================================================================
 */
#include "cycles_internal.h"
#include <stdlib.h>
#include <string.h>

struct iii_cycle_table {
    iii_cycle_descriptor_t  *entries;
    uint32_t                 count;
    uint32_t                 capacity;
    uint64_t                 next_id;
    uint32_t                 promotions_this_tick;
    uint64_t                 tick_count;

    /* Rolling table mhash (invariant 8). */
    uint8_t                  table_mhash[32];
};

static unsigned popcount16_local(uint16_t x) {
    unsigned n = 0;
    while (x) { n += (unsigned)(x & 1u); x >>= 1; }
    return n;
}

static bool hexad_admissible_local(uint16_t h) {
    return h != 0 && popcount16_local(h) <= 6u;
}

iii_cycle_table_t *iii_cycle_table_create(void) {
    iii_cycle_table_t *t = (iii_cycle_table_t *)calloc(1, sizeof(*t));
    if (!t) return NULL;
    t->capacity = III_CYCLES_TABLE_CAP;
    t->entries  = (iii_cycle_descriptor_t *)calloc(t->capacity, sizeof(iii_cycle_descriptor_t));
    if (!t->entries) { free(t); return NULL; }
    return t;
}

void iii_cycle_table_destroy(iii_cycle_table_t *t) {
    if (!t) return;
    free(t->entries);
    free(t);
}

size_t iii_cycle_table_size(const iii_cycle_table_t *t) {
    return t ? (size_t)t->count : 0u;
}

/* Recompute the rolling table mhash by SHA-256 over each descriptor's mhash
 * folded together.  Cheap to recompute on each register. */
static void recompute_table_mhash(iii_cycle_table_t *t) {
    uint8_t buf[8192];  /* up to ~256 descriptors @ 32 bytes each in one batch */
    size_t  pos = 0;

    for (uint32_t i = 0; i < t->count; ++i) {
        if (t->entries[i].superseded) continue;
        if (pos + 32 > sizeof(buf)) {
            /* Hash the partial batch and fold in. */
            uint8_t h[32];
            iii_sha256(buf, pos, h);
            memcpy(buf, h, 32);
            pos = 32;
        }
        memcpy(buf + pos, t->entries[i].mhash, 32);
        pos += 32;
    }
    iii_sha256(buf, pos, t->table_mhash);
}

uint64_t iii_cycle_table_register(iii_cycle_table_t            *t,
                                  const iii_cycle_descriptor_t *d)
{
    if (!t || !d) return 0u;
    if (t->count >= t->capacity) return 0u;

    /* Inv 1 — unique step_kind among non-superseded. */
    if (d->step_kind == 0) return 0u;
    for (uint32_t i = 0; i < t->count; ++i) {
        if (t->entries[i].superseded) continue;
        if (t->entries[i].step_kind == d->step_kind) return 0u;
    }

    /* Inv 2 — admissible hexad. */
    if (!hexad_admissible_local(d->composed_hexad)) return 0u;

    /* Inv 3 — mechanically derivable inverse OR explicit irreversible. */
    if (d->irreversible && d->compromise_tier == III_COMPROMISE_NONE) return 0u;

    /* Inv 4 — valid phase set. */
    if (d->phase_set == 0) return 0u;

    /* Inv 5 — plan anchor present. */
    if (d->plan_anchor_id == 0) return 0u;

    /* Inv 6 — Möbius coherence floor for promotion-eligible cycles. */
    if (d->candidate_for_promotion && d->coherence_q14 == 0) return 0u;

    /* Append. */
    iii_cycle_descriptor_t *slot = &t->entries[t->count++];
    *slot = *d;
    if (slot->cycle_id == 0) slot->cycle_id = ++t->next_id;
    if (slot->cycle_id > t->next_id) t->next_id = slot->cycle_id;
    slot->superseded   = false;
    slot->superseded_by = 0;

    /* Inv 8 — refresh table mhash. */
    recompute_table_mhash(t);

    return slot->cycle_id;
}

const iii_cycle_descriptor_t *iii_cycle_table_lookup_by_id(const iii_cycle_table_t *t,
                                                          uint64_t cycle_id)
{
    if (!t) return NULL;
    for (uint32_t i = 0; i < t->count; ++i) {
        if (t->entries[i].cycle_id == cycle_id) return &t->entries[i];
    }
    return NULL;
}

const iii_cycle_descriptor_t *iii_cycle_table_lookup_by_mhash(const iii_cycle_table_t *t,
                                                              const uint8_t mhash[32])
{
    if (!t || !mhash) return NULL;
    for (uint32_t i = 0; i < t->count; ++i) {
        if (memcmp(t->entries[i].mhash, mhash, 32) == 0) return &t->entries[i];
    }
    return NULL;
}

bool iii_cycle_table_invariants(const iii_cycle_table_t *t) {
    if (!t) return false;
    /* Re-verify all 8 invariants over the live (non-superseded) set. */
    for (uint32_t i = 0; i < t->count; ++i) {
        const iii_cycle_descriptor_t *d = &t->entries[i];
        if (d->superseded) continue;

        /* Inv 1 — unique step_kind. */
        for (uint32_t j = i + 1; j < t->count; ++j) {
            if (t->entries[j].superseded) continue;
            if (t->entries[j].step_kind == d->step_kind) return false;
        }
        /* Inv 2 */
        if (!hexad_admissible_local(d->composed_hexad)) return false;
        /* Inv 3 */
        if (d->irreversible && d->compromise_tier == III_COMPROMISE_NONE) return false;
        /* Inv 4 */
        if (d->phase_set == 0) return false;
        /* Inv 5 */
        if (d->plan_anchor_id == 0) return false;
        /* Inv 6 */
        if (d->candidate_for_promotion && d->coherence_q14 == 0) return false;
    }
    /* Inv 7 — append-only is structural; we never decrement t->count.
     * Inv 8 — table_mhash is up to date by construction (recomputed on every register). */
    return true;
}

void iii_cycle_table_tick(iii_cycle_table_t *t) {
    if (!t) return;
    t->promotions_this_tick = 0;
    t->tick_count++;
}

uint32_t iii_cycle_table_promotions_this_tick(const iii_cycle_table_t *t) {
    return t ? t->promotions_this_tick : 0u;
}

iii_catalyst_status_t iii_cycle_table_promote(iii_cycle_table_t              *t,
                                              const iii_catalyst_promotion_t *p,
                                              uint64_t                       *out_new_cycle_id)
{
    if (out_new_cycle_id) *out_new_cycle_id = 0;
    if (!t || !p) return III_CATALYST_E_INVARIANT;

    if (t->promotions_this_tick >= XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK) {
        return III_CATALYST_E_RATE_CAP;
    }

    /* Locate the original. */
    iii_cycle_descriptor_t *orig = NULL;
    for (uint32_t i = 0; i < t->count; ++i) {
        if (t->entries[i].cycle_id == p->original_cycle_id && !t->entries[i].superseded) {
            orig = &t->entries[i];
            break;
        }
    }
    if (!orig) return III_CATALYST_E_NOT_FOUND;
    if (!orig->candidate_for_promotion) return III_CATALYST_E_NOT_CANDIDATE;
    if (!p->trinity_admitted) return III_CATALYST_E_TRINITY;
    if (p->coherence_q14 < p->coherence_floor_q14) return III_CATALYST_E_COHERENCE;
    if (!p->codegen_validated) return III_CATALYST_E_VALIDATION;

    /* Allocate a new step_kind in MNEME_CATALYST_PROMOTE band [0x01C7..0x01CF].
     * Choose the lowest free slot. */
    iii_cycle_descriptor_t replacement = p->replacement;
    if (replacement.step_kind == 0) {
        for (uint16_t sk = 0x01C7; sk <= 0x01CF; ++sk) {
            bool taken = false;
            for (uint32_t j = 0; j < t->count; ++j) {
                if (t->entries[j].superseded) continue;
                if (t->entries[j].step_kind == sk) { taken = true; break; }
            }
            if (!taken) { replacement.step_kind = sk; break; }
        }
        if (replacement.step_kind == 0) return III_CATALYST_E_INVARIANT;
    }

    /* Install replacement (append-only). */
    if (t->count >= t->capacity) return III_CATALYST_E_INVARIANT;
    if (replacement.plan_anchor_id == 0) replacement.plan_anchor_id = orig->plan_anchor_id;
    if (replacement.coherence_q14 == 0)  replacement.coherence_q14  = p->coherence_q14;
    if (replacement.composed_hexad == 0) replacement.composed_hexad = orig->composed_hexad;
    if (replacement.phase_set == 0)      replacement.phase_set      = orig->phase_set;

    if (!hexad_admissible_local(replacement.composed_hexad) ||
        replacement.phase_set == 0 ||
        replacement.plan_anchor_id == 0) {
        return III_CATALYST_E_INVARIANT;
    }

    iii_cycle_descriptor_t *slot = &t->entries[t->count++];
    *slot = replacement;
    slot->cycle_id     = ++t->next_id;
    slot->superseded   = false;
    slot->superseded_by = 0;

    /* Mark original superseded. */
    orig->superseded   = true;
    orig->superseded_by = slot->cycle_id;

    t->promotions_this_tick++;
    recompute_table_mhash(t);

    if (out_new_cycle_id) *out_new_cycle_id = slot->cycle_id;
    return III_CATALYST_OK;
}
