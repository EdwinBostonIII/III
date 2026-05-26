/* ============================================================================
 * III-CYCLES — wavefront.c
 *
 * §8 — wavefront composition.  A wavefront accumulates effects whose hexads
 * are OR-composed (Wall-Y composition); the composed hexad must remain
 * admissible.  On commit, the runtime emits witnesses for every effect in
 * canonical order, and the final witness's mhash becomes the wavefront's
 * commit boundary entry in the audit spine.
 * ============================================================================
 */
#include "cycles_internal.h"
#include <stdlib.h>
#include <string.h>

typedef struct wf_effect {
    iii_se_kind_t kind;
    uint16_t      hexad;
} wf_effect_t;

struct iii_wavefront {
    uint16_t        declared_hexad;
    uint16_t        composed_hexad;
    wf_effect_t     effects[III_WAVEFRONT_MAX_EFFECTS];
    unsigned        effect_count;
    bool            committed;
};

static unsigned popcount16_local2(uint16_t x) {
    unsigned n = 0;
    while (x) { n += (unsigned)(x & 1u); x >>= 1; }
    return n;
}

iii_wavefront_t *iii_wavefront_begin(uint16_t declared_hexad) {
    iii_wavefront_t *w = (iii_wavefront_t *)calloc(1, sizeof(*w));
    if (!w) return NULL;
    w->declared_hexad = declared_hexad;
    w->composed_hexad = declared_hexad;
    return w;
}

void iii_wavefront_end(iii_wavefront_t *w) {
    if (!w) return;
    free(w);
}

bool iii_wavefront_add_effect(iii_wavefront_t *w, iii_se_kind_t kind, uint16_t per_kind_hexad) {
    if (!w || w->committed) return false;
    if (w->effect_count >= III_WAVEFRONT_MAX_EFFECTS) return false;
    if (kind == III_SE_NONE || kind >= III_SE_COUNT) return false;
    w->effects[w->effect_count].kind  = kind;
    w->effects[w->effect_count].hexad = per_kind_hexad;
    w->effect_count++;
    w->composed_hexad |= per_kind_hexad;
    return true;
}

uint16_t iii_wavefront_composed_hexad(const iii_wavefront_t *w) {
    return w ? w->composed_hexad : 0u;
}

bool iii_wavefront_admit(const iii_wavefront_t *w) {
    if (!w) return false;
    if (w->composed_hexad == 0) return false;
    return popcount16_local2(w->composed_hexad) <= 6u;
}

size_t iii_wavefront_commit(iii_wavefront_t *w,
                            iii_witness_emitter_t *e,
                            iii_wavefront_terminator_t terminator)
{
    if (!w || !e || w->committed) return 0u;
    if (!iii_wavefront_admit(w)) return 0u;

    /* Emit one witness per effect (canonical insertion order), then a
     * wavefront-commit witness in the WAVEFRONT band [0x0070..0x007F]. */
    iii_xii_witness_t out;
    size_t n = 0;
    for (unsigned i = 0; i < w->effect_count; ++i) {
        iii_witness_request_t req;
        memset(&req, 0, sizeof(req));
        req.step_kind     = (uint16_t)(0x0010u + (uint16_t)w->effects[i].kind);
        req.hexad_packed  = w->effects[i].hexad;
        req.flags         = 0;
        iii_witness_emit(e, &req, &out);
        n++;
    }

    /* Commit boundary witness. */
    iii_witness_request_t commit_req;
    memset(&commit_req, 0, sizeof(commit_req));
    /* §5.3: WAVEFRONT band 0x0070..0x007F.  Allocate slots:
     *   0x0070 = wavefront-begin
     *   0x0071 = wavefront-commit (quiescent)
     *   0x0072 = wavefront-commit (barrier)
     *   0x0073 = wavefront-commit (timeout)
     *   0x0074 = wavefront-commit (operator)
     *   0x0075 = wavefront-rollback
     */
    uint16_t commit_kind;
    switch (terminator) {
        case III_WAVEFRONT_BARRIER:    commit_kind = 0x0072; break;
        case III_WAVEFRONT_TIMEOUT:    commit_kind = 0x0073; break;
        case III_WAVEFRONT_OPERATOR:   commit_kind = 0x0074; break;
        case III_WAVEFRONT_QUIESCENT:
        default:                       commit_kind = 0x0071; break;
    }
    commit_req.step_kind    = commit_kind;
    commit_req.hexad_packed = w->composed_hexad;
    iii_witness_emit(e, &commit_req, &out);
    n++;

    w->committed = true;
    return n;
}
