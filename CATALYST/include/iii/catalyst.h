/* ============================================================================
 * III-CATALYST — Dynamic Transformation Catalyst
 * Spec: III-CATALYST.md  (Doc-ID B1, R1.B1)
 *
 * Implements the eight promotion gates, the rate caps, the seven synthesis
 * categories (cycle / keyword / hexad / module fusion / Trinity refinement /
 * SID rule / specialization hint), the operator overrides, and the witness
 * emission for catalyst-promoted changes.
 * ============================================================================
 */
#ifndef III_CATALYST_H
#define III_CATALYST_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §2.3 — rate caps */
#define XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK   8u
#define XII_PHASE_PROMOTE_RATE                       4u
#define XII_MOD_PROMOTE_RATE                        16u
#define XII_KEYWORD_PROMOTE_RATE                     1u

/* §1.1 — promotion categories */
typedef enum iii_cat_promotion_kind {
    III_CAT_NONE                 = 0,
    III_CAT_CYCLE                = 1,
    III_CAT_KEYWORD              = 2,
    III_CAT_HEXAD                = 3,
    III_CAT_MODULE_FUSION        = 4,
    III_CAT_TRINITY_REFINEMENT   = 5,
    III_CAT_SID_RULE             = 6,
    III_CAT_SPECIALIZATION_HINT  = 7,
    III_CAT_PHASE                = 8     /* counts against XII_PHASE_PROMOTE_RATE */
} iii_cat_promotion_kind_t;

const char *iii_cat_promotion_kind_name(iii_cat_promotion_kind_t k);

/* §2.1 — eight gates */
typedef enum iii_cat_gate {
    III_CGATE_OBSERVATORY_SAT     = 0,
    III_CGATE_MOBIUS_COHERENCE    = 1,
    III_CGATE_TRINITY             = 2,
    III_CGATE_CEILING             = 3,
    III_CGATE_HEXAD_REACH         = 4,
    III_CGATE_CODEGEN             = 5,
    III_CGATE_RING_GATING         = 6,
    III_CGATE_DEPLOY_FLAG         = 7,
    III_CGATE_COUNT               = 8
} iii_cat_gate_t;

const char *iii_cat_gate_name(iii_cat_gate_t g);

typedef struct iii_cat_gates {
    bool passed[III_CGATE_COUNT];
    uint8_t sub_witness[III_CGATE_COUNT][32];
} iii_cat_gates_t;

bool iii_cat_gates_all_passed(const iii_cat_gates_t *g);
unsigned iii_cat_gates_first_failure(const iii_cat_gates_t *g);

/* §6 deployment flag mirrors III-MODULES */
typedef enum iii_cat_deploy_flag {
    III_CAT_DF_NONE             = 0,
    III_CAT_DF_SAFE_APPROVED    = 1,
    III_CAT_DF_SAFE_FLAGGED     = 2,
    III_CAT_DF_UNSAFE_REJECTED  = 3
} iii_cat_deploy_flag_t;

const char *iii_cat_deploy_flag_name(iii_cat_deploy_flag_t f);

/* Validation ring (mirrors III-MODULES) */
typedef enum iii_cat_validation_ring {
    III_CAT_VR_REJECT     = 0,
    III_CAT_VR_KERNEL     = 1,
    III_CAT_VR_HYPERVISOR = 2,
    III_CAT_VR_SANCTUM    = 3
} iii_cat_validation_ring_t;

/* §2 — promotion request */
typedef struct iii_cat_promotion_request {
    iii_cat_promotion_kind_t kind;
    uint8_t                  candidate_source_mhash[32];
    uint16_t                 candidate_hexad;             /* 6-bit pillar bitmap */
    uint16_t                 projected_coherence_q14;
    uint16_t                 coherence_floor_q14;
    bool                     observatory_saturated;
    bool                     trinity_admitted;
    bool                     ceiling_admitted;
    bool                     hexad_reachable;
    bool                     codegen_passed;
    bool                     semantic_baseline_match;
    iii_cat_validation_ring_t target_ring;
} iii_cat_promotion_request_t;

/* §2.2 — promotion outcome */
typedef struct iii_cat_promotion_outcome {
    iii_cat_gates_t          gates;
    iii_cat_deploy_flag_t    flag;
    iii_cat_validation_ring_t ring;
    bool                     promoted;
    uint8_t                  promote_witness_mhash[32];
} iii_cat_promotion_outcome_t;

/* §7 — witness step kinds */
typedef enum iii_cat_witness_kind {
    III_CATW_NONE                       = 0,
    III_CATW_MNEME_CATALYST_PROMOTE     = 0x01C7,
    III_CATW_CATALYST_REJECT            = 0x01C8,
    III_CATW_CATALYST_RATE_CAP          = 0x01C9,
    III_CATW_CATALYST_REVOKE            = 0x01CA,
    III_CATW_CATALYST_PAUSE             = 0x01CB,
    III_CATW_CATALYST_RESUME            = 0x01CC,
    III_CATW_CATALYST_CONSTRAIN         = 0x01CD
} iii_cat_witness_kind_t;

const char *iii_cat_witness_kind_name(iii_cat_witness_kind_t k);

/* Runtime */
typedef struct iii_catalyst iii_catalyst_t;

iii_catalyst_t *iii_catalyst_create(void);
void            iii_catalyst_destroy(iii_catalyst_t *c);

/* §2 — submit a promotion request.  Returns the eight-gate evaluation +
 * deploy flag + ring + witness mhash in `out`.  Increments the per-tick rate
 * counter for the matching category. */
void iii_catalyst_propose(iii_catalyst_t                  *c,
                          const iii_cat_promotion_request_t *req,
                          iii_cat_promotion_outcome_t       *out);

/* §2.3 — chronos tick */
void iii_catalyst_tick(iii_catalyst_t *c);

/* Per-tick promotion counters */
uint32_t iii_catalyst_cycle_count_this_tick(const iii_catalyst_t *c);
uint32_t iii_catalyst_phase_count_this_tick(const iii_catalyst_t *c);
uint32_t iii_catalyst_module_count_this_tick(const iii_catalyst_t *c);
uint32_t iii_catalyst_keyword_count_this_tick(const iii_catalyst_t *c);

/* §4.3 — operator overrides */
bool iii_catalyst_pause(iii_catalyst_t *c);
bool iii_catalyst_resume(iii_catalyst_t *c);
bool iii_catalyst_is_paused(const iii_catalyst_t *c);

bool iii_catalyst_revoke(iii_catalyst_t *c, const uint8_t promotion_witness_mhash[32]);
bool iii_catalyst_reject(iii_catalyst_t *c, const uint8_t proposal_mhash[32]);
bool iii_catalyst_constrain(iii_catalyst_t *c,
                            iii_cat_promotion_kind_t kind,
                            uint32_t                 max_rate);

uint32_t iii_catalyst_rate_cap(const iii_catalyst_t *c, iii_cat_promotion_kind_t kind);
uint64_t iii_catalyst_witness_count(const iii_catalyst_t *c);
uint64_t iii_catalyst_promotion_count(const iii_catalyst_t *c);
uint64_t iii_catalyst_revocation_count(const iii_catalyst_t *c);

#ifdef __cplusplus
}
#endif

#endif /* III_CATALYST_H */
