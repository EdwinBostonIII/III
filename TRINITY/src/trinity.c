/* III-TRINITY implementation */
#include "iii/trinity.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

#define III_TRINITY_CACHE_BUCKETS  4096u

typedef struct iii_trinity_cache_entry {
    uint64_t                    tuple_hash;
    iii_predictive_outcome_t    outcome;
    bool                        used;
} iii_trinity_cache_entry_t;

struct iii_trinity_runtime {
    iii_scba_bitarray_t scba;
    iii_trinity_cache_entry_t cache[III_TRINITY_CACHE_BUCKETS];

    /* Catalyst-promoted predicates (§6).  When set, replaces default checks. */
    iii_trinity_conjunct_fn intent_admit;
    iii_trinity_conjunct_fn cap_admit;
    iii_trinity_conjunct_fn causality_admit;
    iii_trinity_conjunct_fn sanctum_admit;
    void *intent_user;
    void *cap_user;
    void *causality_user;
    void *sanctum_user;

    /* §8 — risk-driven dynamic layer activation */
    uint16_t risk_q14;

    uint64_t witness_count;
};

const char *iii_trinity_layer_name(iii_trinity_layer_t l) {
    switch (l) {
        case III_LAYER_NONE:    return "none";
        case III_LAYER_SCBA:    return "Layer 1: SCBA";
        case III_LAYER_ACC:     return "Layer 2: ACC Wall-Y";
        case III_LAYER_TRINITY: return "Layer 3: Trinity";
        default:                return "unknown";
    }
}

const char *iii_trinity_status_name(iii_trinity_status_t s) {
    switch (s) {
        case III_TRIN_OK:                       return "ok";
        case III_TRIN_INTENT_REJECT:            return "TRINITY_INTENT_REJECT";
        case III_TRIN_CAP_REJECT:               return "TRINITY_CAP_REJECT";
        case III_TRIN_CAUSALITY_REJECT:         return "TRINITY_CAUSALITY_REJECT";
        case III_TRIN_SANCTUM_REJECT:           return "TRINITY_SANCTUM_REJECT";
        case III_TRIN_ACC_WALL_Y_REJECT:        return "ACC_WALL_Y_REJECT";
        case III_TRIN_SCBA_BIT_REJECT:          return "SCBA_BIT_REJECT";
        case III_TRIN_HEXAD_UNREPRESENTABLE:    return "HEXAD_UNREPRESENTABLE";
        case III_TRIN_MOBIUS_COHERENCE_FAIL:    return "MOBIUS_COHERENCE_FAIL";
        case III_TRIN_CEILING_VIOLATION:        return "CEILING_VIOLATION";
        case III_TRIN_EPISTEMIC_LOW_CONFIDENCE: return "EPISTEMIC_LOW_CONFIDENCE";
        case III_TRIN_WAAC_VIOLATION:           return "WAAC_VIOLATION";
        case III_TRIN_INVALID:                  return "invalid";
        default:                                return "unknown";
    }
}

const char *iii_trinity_witness_kind_name(iii_trinity_witness_kind_t k) {
    switch (k) {
        case III_TRIN_W_TRINITY_REJECT:    return "TRINITY_REJECT";
        case III_TRIN_W_TRINITY_PROMOTE:   return "TRINITY_PROMOTE";
        case III_TRIN_W_GHOST_ADMIT:       return "GHOST_ADMIT";
        case III_TRIN_W_LAYER_ESCALATE:    return "LAYER_ESCALATE";
        default:                           return "unknown";
    }
}

void iii_scba_init(iii_scba_bitarray_t *s) { if (s) memset(s->bits, 0, sizeof(s->bits)); }
void iii_scba_bit_set(iii_scba_bitarray_t *s, uint16_t bit) {
    if (!s) return;
    s->bits[bit >> 3] |= (uint8_t)(1u << (bit & 7u));
}
void iii_scba_bit_clear(iii_scba_bitarray_t *s, uint16_t bit) {
    if (!s) return;
    s->bits[bit >> 3] &= (uint8_t)~(1u << (bit & 7u));
}
bool iii_scba_bit_test(const iii_scba_bitarray_t *s, uint16_t bit) {
    if (!s) return false;
    return (s->bits[bit >> 3] >> (bit & 7u)) & 1u;
}

bool iii_acc_wall_y_admit(const iii_acc_delta_t *delta) {
    if (!delta) return false;
    /* Admit iff every pillar is in {ZERO=1, POS=2}; NEG=0 in pillars 1..4 is
     * structurally untypable (per the hexad reachability theorem); NEG in 5/6
     * is allowed but escalates to Layer 3 (the caller decides; here we admit
     * the ACC-only path iff all six are ZERO/POS). */
    for (unsigned i = 0; i < 6; ++i) {
        if (delta->pillars[i] == 0) return false;
    }
    return true;
}

void iii_trinity_input_init_defaults(iii_trinity_input_t *in) {
    if (!in) return;
    memset(in, 0, sizeof(*in));
    in->coherence_floor_q14         = III_TRINITY_DEFAULT_FLOOR_Q14;
    in->confidence_threshold_q14    = III_TRINITY_DEFAULT_CONFIDENCE_Q14_THRESHOLD;
}

iii_trinity_runtime_t *iii_trinity_runtime_create(void) {
    return (iii_trinity_runtime_t *)calloc(1, sizeof(iii_trinity_runtime_t));
}
void iii_trinity_runtime_destroy(iii_trinity_runtime_t *rt) { if (rt) free(rt); }

void iii_trinity_runtime_scba_set(iii_trinity_runtime_t *rt, uint16_t bit) {
    if (rt) iii_scba_bit_set(&rt->scba, bit);
}
void iii_trinity_runtime_scba_clear(iii_trinity_runtime_t *rt, uint16_t bit) {
    if (rt) iii_scba_bit_clear(&rt->scba, bit);
}

static uint64_t cache_index(uint64_t tuple_hash) {
    return tuple_hash % III_TRINITY_CACHE_BUCKETS;
}

void iii_trinity_runtime_cache(iii_trinity_runtime_t *rt,
                               uint64_t                tuple_hash,
                               iii_predictive_outcome_t outcome)
{
    if (!rt) return;
    iii_trinity_cache_entry_t *e = &rt->cache[cache_index(tuple_hash)];
    e->tuple_hash = tuple_hash;
    e->outcome    = outcome;
    e->used       = true;
}

iii_predictive_outcome_t iii_trinity_runtime_lookup(const iii_trinity_runtime_t *rt,
                                                    uint64_t                       tuple_hash)
{
    if (!rt) return III_PRED_NONE;
    const iii_trinity_cache_entry_t *e = &rt->cache[cache_index(tuple_hash)];
    if (!e->used || e->tuple_hash != tuple_hash) return III_PRED_NONE;
    return e->outcome;
}

void iii_trinity_runtime_promote_intent_admit(iii_trinity_runtime_t   *rt,
                                              iii_trinity_conjunct_fn  fn,
                                              void                    *user)
{
    if (!rt) return;
    rt->intent_admit = fn; rt->intent_user = user;
    rt->witness_count++;
}
void iii_trinity_runtime_promote_cap_admit(iii_trinity_runtime_t   *rt,
                                           iii_trinity_conjunct_fn  fn,
                                           void                    *user)
{
    if (!rt) return;
    rt->cap_admit = fn; rt->cap_user = user;
    rt->witness_count++;
}
void iii_trinity_runtime_promote_causality_admit(iii_trinity_runtime_t   *rt,
                                                 iii_trinity_conjunct_fn  fn,
                                                 void                    *user)
{
    if (!rt) return;
    rt->causality_admit = fn; rt->causality_user = user;
    rt->witness_count++;
}
void iii_trinity_runtime_promote_sanctum_admit(iii_trinity_runtime_t   *rt,
                                               iii_trinity_conjunct_fn  fn,
                                               void                    *user)
{
    if (!rt) return;
    rt->sanctum_admit = fn; rt->sanctum_user = user;
    rt->witness_count++;
}

void iii_trinity_runtime_set_risk(iii_trinity_runtime_t *rt, uint16_t risk_q14) {
    if (!rt) return;
    rt->risk_q14 = risk_q14;
}
uint16_t iii_trinity_runtime_risk(const iii_trinity_runtime_t *rt) {
    return rt ? rt->risk_q14 : 0u;
}

iii_trinity_layer_t iii_trinity_runtime_min_layer(const iii_trinity_runtime_t *rt) {
    if (!rt) return III_LAYER_TRINITY;
    /* §8.1: <0.25 → Layer 1 only; <0.6 → Layer 1+2; else full Layer 3. */
    if (rt->risk_q14 < (uint16_t)(0.25 * 16384.0)) return III_LAYER_SCBA;
    if (rt->risk_q14 < (uint16_t)(0.60 * 16384.0)) return III_LAYER_ACC;
    return III_LAYER_TRINITY;
}

/* ----------------------------------------------------------------------------
 * Conjunct evaluation
 * ---------------------------------------------------------------------------- */
static bool eval_intent(const iii_trinity_runtime_t *rt, const iii_trinity_input_t *in) {
    if (rt && rt->intent_admit) return rt->intent_admit(in->intent_id, rt->intent_user);
    return in->intent_valid;
}
static bool eval_cap(const iii_trinity_runtime_t *rt, const iii_trinity_input_t *in) {
    if (rt && rt->cap_admit) return rt->cap_admit(in->cap_id, rt->cap_user);
    return in->cap_valid;
}
static bool eval_causality(const iii_trinity_runtime_t *rt, const iii_trinity_input_t *in) {
    if (rt && rt->causality_admit) return rt->causality_admit(in->causality_id, rt->causality_user);
    return in->causality_valid;
}
static bool eval_sanctum(const iii_trinity_runtime_t *rt, const iii_trinity_input_t *in) {
    if (rt && rt->sanctum_admit) return rt->sanctum_admit(in->sanctum_frame_id, rt->sanctum_user);
    return in->sanctum_state_valid;
}

static uint64_t tuple_hash_compute(const iii_trinity_input_t *in) {
    uint8_t buf[40];
    for (unsigned i = 0; i < 8; ++i) buf[i]      = (uint8_t)(in->intent_id      >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[8+i]    = (uint8_t)(in->cap_id          >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[16+i]   = (uint8_t)(in->causality_id    >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[24+i]   = (uint8_t)(in->sanctum_frame_id>> (i*8));
    /* Mix in composed_delta and scba bit. */
    memcpy(buf + 32, in->composed_delta.pillars, 6);
    buf[38] = (uint8_t)(in->scba_bit & 0xFFu);
    buf[39] = (uint8_t)(in->scba_bit >> 8);
    uint8_t h[32];
    iii_sha256(buf, sizeof(buf), h);
    uint64_t v = 0;
    for (unsigned i = 0; i < 8; ++i) v |= ((uint64_t)h[i] << (i * 8));
    return v;
}

/* ----------------------------------------------------------------------------
 * Layered admit
 * ---------------------------------------------------------------------------- */

static iii_trinity_status_t admit_internal(iii_trinity_runtime_t       *rt,
                                           const iii_trinity_input_t   *in,
                                           iii_convergence_point_t     *out_cp,
                                           bool                          ghost)
{
    if (!rt || !in) return III_TRIN_INVALID;
    iii_convergence_point_t cp; memset(&cp, 0, sizeof(cp));
    cp.tuple_hash = tuple_hash_compute(in);

    /* §4 — epistemic escalation */
    bool epistemic_escalate = false;
    if (in->uncertainty_present && in->confidence_q14 < in->confidence_threshold_q14) {
        epistemic_escalate = true;
    }

    iii_trinity_layer_t min_layer = iii_trinity_runtime_min_layer(rt);

    /* Layer 1 — SCBA bit-test */
    if (iii_scba_bit_test(&rt->scba, in->scba_bit)) {
        cp.admitting_layer = III_LAYER_SCBA;
        if (!epistemic_escalate && min_layer == III_LAYER_SCBA) {
            iii_sha256(&cp, sizeof(cp), cp.convergence_mhash);
            if (out_cp) *out_cp = cp;
            if (!ghost) rt->witness_count++;
            return III_TRIN_OK;
        }
    }

    /* Layer 2 — ACC Wall-Y composed-delta admit */
    bool acc_pass = iii_acc_wall_y_admit(&in->composed_delta);
    if (!acc_pass) {
        if (out_cp) *out_cp = cp;
        rt->witness_count++;
        return III_TRIN_ACC_WALL_Y_REJECT;
    }
    if (cp.admitting_layer == III_LAYER_NONE) cp.admitting_layer = III_LAYER_ACC;
    if (!epistemic_escalate && min_layer <= III_LAYER_ACC) {
        iii_sha256(&cp, sizeof(cp), cp.convergence_mhash);
        if (out_cp) *out_cp = cp;
        if (!ghost) rt->witness_count++;
        return III_TRIN_OK;
    }

    /* Layer 3 — full Trinity */
    cp.admitting_layer = III_LAYER_TRINITY;
    cp.intent_passed     = eval_intent(rt, in);
    cp.cap_passed        = eval_cap(rt, in);
    cp.causality_passed  = eval_causality(rt, in);
    cp.sanctum_passed    = eval_sanctum(rt, in);
    cp.coherence_q14     = in->projected_coherence_q14;

    if (!cp.intent_passed)    { if (out_cp) *out_cp = cp; rt->witness_count++; return III_TRIN_INTENT_REJECT; }
    if (!cp.cap_passed)       { if (out_cp) *out_cp = cp; rt->witness_count++; return III_TRIN_CAP_REJECT; }
    if (!cp.causality_passed) { if (out_cp) *out_cp = cp; rt->witness_count++; return III_TRIN_CAUSALITY_REJECT; }
    if (!cp.sanctum_passed)   { if (out_cp) *out_cp = cp; rt->witness_count++; return III_TRIN_SANCTUM_REJECT; }

    /* §5 — Möbius coherence floor */
    if (in->coherence_floor_q14 > 0 && in->projected_coherence_q14 < in->coherence_floor_q14) {
        if (out_cp) *out_cp = cp;
        rt->witness_count++;
        return III_TRIN_MOBIUS_COHERENCE_FAIL;
    }

    /* §4 — epistemic check (post all-conjuncts).  If still low confidence
     * and the operator has not pre-confirmed via cognitive primitives, we
     * reject with EPISTEMIC_LOW_CONFIDENCE.  In the model the caller flags
     * via uncertainty_present + confidence_q14.  We treat it as soft-reject
     * unless intent_id specifically encodes operator-confirmation (= 0xC0NF). */
    if (epistemic_escalate && in->intent_id != III_TRINITY_OPERATOR_CONFIRMATION_INTENT_ID) {
        if (out_cp) *out_cp = cp;
        rt->witness_count++;
        return III_TRIN_EPISTEMIC_LOW_CONFIDENCE;
    }

    iii_sha256(&cp, sizeof(cp), cp.convergence_mhash);
    if (out_cp) *out_cp = cp;
    if (!ghost) rt->witness_count++;
    return III_TRIN_OK;
}

iii_trinity_status_t iii_trinity_admit(iii_trinity_runtime_t       *rt,
                                       const iii_trinity_input_t   *in,
                                       iii_convergence_point_t     *out_cp)
{
    return admit_internal(rt, in, out_cp, false);
}

iii_trinity_status_t iii_trinity_predictive_admit(iii_trinity_runtime_t      *rt,
                                                  const iii_trinity_input_t   *in,
                                                  iii_convergence_point_t     *out_cp)
{
    if (!rt || !in) return III_TRIN_INVALID;
    uint64_t th = tuple_hash_compute(in);
    iii_predictive_outcome_t po = iii_trinity_runtime_lookup(rt, th);
    if (po == III_PRED_ADMIT) {
        if (out_cp) {
            memset(out_cp, 0, sizeof(*out_cp));
            out_cp->admitting_layer = III_LAYER_SCBA;
            out_cp->tuple_hash = th;
        }
        rt->witness_count++;
        return III_TRIN_OK;
    }
    if (po == III_PRED_DENY) {
        rt->witness_count++;
        return III_TRIN_INTENT_REJECT;       /* generic rejection — caller can map */
    }
    /* III_PRED_NONE / III_PRED_ESCALATE → fall through to full admit */
    iii_trinity_status_t st = admit_internal(rt, in, out_cp, false);
    /* Cache the result. */
    iii_predictive_outcome_t cached = (st == III_TRIN_OK) ? III_PRED_ADMIT : III_PRED_DENY;
    iii_trinity_runtime_cache(rt, th, cached);
    return st;
}

iii_trinity_status_t iii_trinity_ghost_admit(iii_trinity_runtime_t       *rt,
                                             const iii_trinity_input_t   *in,
                                             iii_convergence_point_t     *out_cp)
{
    return admit_internal(rt, in, out_cp, true);
}

uint64_t iii_trinity_runtime_witness_count(const iii_trinity_runtime_t *rt) {
    return rt ? rt->witness_count : 0u;
}
