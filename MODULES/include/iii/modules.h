/* ============================================================================
 * III-MODULES — Module & Complementarity System (Safety-First Revision)
 * Spec: III-MODULES.md  (Doc-ID A10, R1.A10)
 *
 * Implements:
 *   §1 — modules as content-addressed witnessed nodes (closure_root)
 *   §2 — name resolution as mathematical discovery (closure-pinned imports)
 *   §3 — structured cross-module transmission (witnessed reductions)
 *   §4 — the complementarity principle
 *   §5 — Ring-gated promotion (LOW/MEDIUM/HIGH risk × LOW/MEDIUM/HIGH benefit)
 *   §6 — codegen-first validation + deployment flags
 *   §10 — dynamic module fusion (append-only)
 *   §11 — operator frontend (proposal queue)
 * ============================================================================
 */
#ifndef III_MODULES_H
#define III_MODULES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* Hexad arithmetic (Z_3^6 component-wise sum) lives in PERFORMANCE. */
#include "iii/performance.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §1 — module identity
 * ---------------------------------------------------------------------------- */
typedef uint64_t iii_mod_id_t;

#define III_MOD_NAME_MAX           96u
#define III_MOD_VERSION_MAX        16u
#define III_MOD_MAX_IMPORTS        32u
#define III_MOD_MAX_EXPORTS        32u
#define III_MOD_MAX                512u

typedef struct iii_mod_import {
    char     qualified_name[III_MOD_NAME_MAX];
    uint8_t  closure_pin[32];        /* 32 zero bytes = unpinned */
    bool     pinned;
} iii_mod_import_t;

typedef struct iii_mod_export {
    char     name[III_MOD_NAME_MAX];
    uint8_t  item_mhash[32];
} iii_mod_export_t;

/* §5 ring-gating decision-tree enum (renamed from iii_ring_t to avoid
 * collision with PERFORMANCE's iii_ring_t which names the witness ring
 * buffer).  Use PHASES's iii_phase_ring_t for the canonical ring-lattice
 * ordering; this enum is purely a tag for §5 risk-benefit dispatch. */
typedef enum iii_mod_ring {
    III_MR_USER       = 3,
    III_MR_KERNEL     = 0,
    III_MR_HYPERVISOR = 1,
    III_MR_SANCTUM    = 2
} iii_mod_ring_t;

typedef struct iii_module {
    iii_mod_id_t           module_id;
    char                   qualified_name[III_MOD_NAME_MAX];
    char                   version[III_MOD_VERSION_MAX];
    uint8_t                closure_root[32];              /* §1.2 — module identity */
    uint8_t                canonical_source_mhash[32];
    uint8_t                r1_specification_root[32];
    uint8_t                manifest_signature[64];        /* Ed25519 over manifest */

    iii_mod_import_t       imports[III_MOD_MAX_IMPORTS];
    unsigned               import_count;
    iii_mod_export_t       exports[III_MOD_MAX_EXPORTS];
    unsigned               export_count;

    /* Ring set the module was authored for (bitmap: 1<<R-2, 1<<R-1, 1<<R0, 1<<R3) */
    uint8_t                ring_set;

    /* §4 complementarity input — module's aggregate Z_3^6 safety hexad
     * (composed over its exported cycles). */
    iii_hexad_z3_6_t       aggregate_hexad;

    /* SRPA-observed metrics */
    uint16_t               coherence_q14;
    uint16_t               performance_q14;          /* 1.0 = perfectly tuned */

    /* Append-only supersedure */
    bool                   superseded;
    iii_mod_id_t           superseded_by;
} iii_module_t;

/* ----------------------------------------------------------------------------
 * §6 — deployment flags
 * ---------------------------------------------------------------------------- */
typedef enum iii_deploy_flag {
    III_DEPLOY_NONE             = 0,
    III_DEPLOY_SAFE_APPROVED    = 1,
    III_DEPLOY_SAFE_FLAGGED     = 2,
    III_DEPLOY_UNSAFE_REJECTED  = 3
} iii_deploy_flag_t;

const char *iii_deploy_flag_name(iii_deploy_flag_t f);

/* ----------------------------------------------------------------------------
 * §5 — risk/benefit classification
 * ---------------------------------------------------------------------------- */
typedef enum iii_level {
    III_LVL_LOW    = 0,
    III_LVL_MEDIUM = 1,
    III_LVL_HIGH   = 2
} iii_level_t;

typedef enum iii_validation_ring {
    III_VR_REJECT     = 0,    /* don't deploy */
    III_VR_KERNEL     = 1,    /* Ring 0 */
    III_VR_HYPERVISOR = 2,    /* Ring -1 */
    III_VR_SANCTUM    = 3     /* Ring -2 */
} iii_validation_ring_t;

iii_validation_ring_t iii_modules_select_validation_ring(iii_level_t risk,
                                                          iii_level_t benefit);

const char *iii_validation_ring_name(iii_validation_ring_t r);

/* ----------------------------------------------------------------------------
 * §1.3 — closure manifest
 * ---------------------------------------------------------------------------- */
typedef struct iii_module_manifest {
    uint8_t closure_root[32];
    uint8_t canonical_source_mhash[32];
    uint8_t r1_root[32];
    uint8_t imports_mhash[32];     /* SHA-256 of (qualified_name||closure_pin) per import */
    uint8_t exports_mhash[32];
    uint8_t cycle_table_mhash[32];
    uint8_t hexad_table_mhash[32];
    uint8_t proof_certificates_mhash[32];
    uint8_t signature[64];
} iii_module_manifest_t;

void iii_module_manifest_compute(const iii_module_t *m, iii_module_manifest_t *out);

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */
typedef struct iii_module_runtime iii_module_runtime_t;

iii_module_runtime_t *iii_module_runtime_create(void);
void iii_module_runtime_destroy(iii_module_runtime_t *rt);

/* §1 — register a module.  Computes closure_root from the canonical source. */
iii_mod_id_t iii_module_register(iii_module_runtime_t *rt,
                                 const char            *qualified_name,
                                 const char            *version,
                                 const uint8_t         *canonical_source,
                                 size_t                 source_len,
                                 uint8_t                ring_set);

/* §1 — add an import (pinned or unpinned). */
bool iii_module_add_import(iii_module_runtime_t *rt,
                           iii_mod_id_t          mid,
                           const char           *qualified_name,
                           const uint8_t         closure_pin[32]);

/* §1 — add an export. */
bool iii_module_add_export(iii_module_runtime_t *rt,
                           iii_mod_id_t          mid,
                           const char           *name,
                           const uint8_t         item_mhash[32]);

/* Lookup */
const iii_module_t *iii_module_lookup(const iii_module_runtime_t *rt,
                                      iii_mod_id_t                mid);
const iii_module_t *iii_module_lookup_by_name(const iii_module_runtime_t *rt,
                                              const char                  *qualified_name);
size_t iii_module_runtime_count(const iii_module_runtime_t *rt);

/* Set SRPA-observed metrics */
void iii_module_set_metrics(iii_module_runtime_t *rt,
                            iii_mod_id_t          mid,
                            uint16_t              coherence_q14,
                            uint16_t              performance_q14);

/* §4 — set the module's aggregate Z_3^6 hexad (composed over its cycles). */
void iii_module_set_hexad(iii_module_runtime_t   *rt,
                          iii_mod_id_t            mid,
                          const iii_hexad_z3_6_t *hexad);

/* ----------------------------------------------------------------------------
 * §2 — name resolution
 * ---------------------------------------------------------------------------- */
typedef enum iii_resolve_status {
    III_RES_OK               = 0,
    III_RES_NOT_FOUND        = 1,
    III_RES_CLOSURE_MISMATCH = 2,    /* MOD-RES-001 */
    III_RES_AMBIGUOUS        = 3,
    III_RES_INVALID          = 4
} iii_resolve_status_t;

const char *iii_resolve_status_name(iii_resolve_status_t s);

iii_resolve_status_t iii_module_resolve(const iii_module_runtime_t *rt,
                                        const char                  *qualified_name,
                                        const uint8_t               *closure_pin_or_null,
                                        iii_mod_id_t                *out_mid);

/* ----------------------------------------------------------------------------
 * §3 — cross-module transmission record
 * ---------------------------------------------------------------------------- */
typedef enum iii_tx_path {
    III_TX_PATH_GENERIC      = 0,    /* full marshalling */
    III_TX_PATH_SPECIALIZED  = 1,    /* PIP + SRPA-specialised */
    III_TX_PATH_FUSED        = 2     /* Catalyst-fused */
} iii_tx_path_t;

typedef struct iii_tx_record {
    iii_mod_id_t   from_module;
    iii_mod_id_t   to_module;
    iii_tx_path_t  path;
    bool           glyph_bound;
    bool           epistemic_marshal;
    uint16_t       coherence_delta_q14;   /* signed via uint */
    uint8_t        predecessor_mhash[32];
    uint8_t        successor_mhash[32];
    uint16_t       cycle_overhead;        /* estimated */
} iii_tx_record_t;

bool iii_module_transmit(iii_module_runtime_t *rt,
                         iii_mod_id_t           from,
                         iii_mod_id_t           to,
                         iii_tx_record_t       *out);

/* ----------------------------------------------------------------------------
 * §4 — complementarity test
 * ---------------------------------------------------------------------------- */
typedef struct iii_complementarity_result {
    bool          complementary;
    uint16_t      hexad_admissible;       /* 0/1 */
    uint16_t      coherence_path_q14;
    uint16_t      performance_q14;
} iii_complementarity_result_t;

void iii_module_complementarity(const iii_module_runtime_t   *rt,
                                iii_mod_id_t                  a,
                                iii_mod_id_t                  b,
                                iii_complementarity_result_t *out);

/* ----------------------------------------------------------------------------
 * §5 + §6 — propose a module change (load, fuse, supersede), validate, deploy.
 * ---------------------------------------------------------------------------- */
typedef enum iii_change_kind {
    III_CHANGE_LOAD         = 0,
    III_CHANGE_SUPERSEDE    = 1,
    III_CHANGE_FUSE         = 2,
    III_CHANGE_RESOLUTION   = 3
} iii_change_kind_t;

typedef struct iii_module_change {
    iii_change_kind_t  kind;
    iii_mod_id_t       primary;
    iii_mod_id_t       secondary;        /* for SUPERSEDE / FUSE */
    iii_level_t        risk;
    iii_level_t        benefit;
    bool               codegen_passed;
    bool               structural_invariants_held;
    bool               semantic_baseline_match;
} iii_module_change_t;

typedef struct iii_deploy_outcome {
    iii_deploy_flag_t       flag;
    iii_validation_ring_t   ring;
    bool                    deployed;
    iii_mod_id_t            new_module_id;
} iii_deploy_outcome_t;

void iii_module_propose_and_deploy(iii_module_runtime_t      *rt,
                                   const iii_module_change_t *ch,
                                   iii_deploy_outcome_t      *out);

/* ----------------------------------------------------------------------------
 * §10 — dynamic module fusion (append-only)
 * ---------------------------------------------------------------------------- */
iii_mod_id_t iii_module_fuse(iii_module_runtime_t *rt,
                             iii_mod_id_t          a,
                             iii_mod_id_t          b);

/* §11 — operator frontend: list pending proposals */
typedef struct iii_proposal_summary {
    iii_change_kind_t  kind;
    iii_mod_id_t       primary;
    iii_mod_id_t       secondary;
    iii_deploy_flag_t  flag;
    iii_validation_ring_t ring;
    uint16_t           est_coherence_gain_q14;
} iii_proposal_summary_t;

size_t iii_module_proposals(const iii_module_runtime_t *rt,
                            iii_proposal_summary_t      *out_buf,
                            size_t                       cap);

uint64_t iii_module_witness_count(const iii_module_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_MODULES_H */
