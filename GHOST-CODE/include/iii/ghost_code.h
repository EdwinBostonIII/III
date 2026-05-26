/* ============================================================================
 * III-GHOST-CODE — Ghost-Code-Until-Verified Discipline
 * Spec: III-GHOST-CODE.md  (Wave 4, items 63-71)
 *
 * Code is ghost until verified, and ghost code does not execute.  Twelve
 * verification gates produce per-gate partial certificates; their composition
 * is the cycle's complete proof.  Cycles classify into one of five states:
 * Ghost / Compromise.LOW / Compromise.MEDIUM / Compromise.HIGH / Verified.
 *
 * This module owns:
 *   §1 — @ghost declaration syntax bookkeeping
 *   §2 — the 12 verification gate hierarchy
 *   §3 — ghost-to-verified transition
 *   §4 — SE compromise tier classification
 *   §5 — ghost-code emission ban
 *   §6 — hexad classification of ghost operations
 *   §7 — witness emission for transitions
 *   §8 — cap discipline for ghost-code consumers
 *   §9 — closure-root impact bookkeeping
 * ============================================================================
 */
#ifndef III_GHOST_CODE_H
#define III_GHOST_CODE_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §2 — the 12 gates.
 * ---------------------------------------------------------------------------- */
typedef enum iii_gate {
    III_GATE_NONE                       = 0,
    III_GATE_TYPE_CORRECTNESS           = 1,
    III_GATE_HEXAD_ADMISSIBILITY        = 2,
    III_GATE_EFFECT_SOUNDNESS           = 3,
    III_GATE_TERMINATION                = 4,
    III_GATE_REVERSIBILITY              = 5,
    III_GATE_WITNESS_EMISSION           = 6,
    III_GATE_CAP_DISCIPLINE             = 7,
    III_GATE_TRINITY_GATING             = 8,
    III_GATE_ANCHOR_INVARIANT           = 9,
    III_GATE_PERFORMANCE_BUDGET         = 10,
    III_GATE_CONSTANT_TIME              = 11,
    III_GATE_CLOSURE_ROOT               = 12,
    III_GATE_COUNT                      = 13   /* one past the last */
} iii_gate_t;

const char *iii_gate_name(iii_gate_t g);

/* Gate-applicability flags — populated by the proof kernel from the cycle's
 * declaration modifiers.  A gate that is not applicable does not need to
 * pass for the cycle to verify (e.g. termination doesn't apply to
 * @compromise cycles, constant-time doesn't apply to non-crypto code). */
typedef struct iii_gate_set {
    bool applicable[III_GATE_COUNT];
    bool passed[III_GATE_COUNT];
    uint8_t certificate[III_GATE_COUNT][32];   /* per-gate partial certificate hash */
} iii_gate_set_t;

void iii_gate_set_init(iii_gate_set_t *s);
void iii_gate_set_mark_applicable(iii_gate_set_t *s, iii_gate_t g, bool yes);
void iii_gate_set_record_pass(iii_gate_set_t *s, iii_gate_t g, const uint8_t cert[32]);
void iii_gate_set_record_fail(iii_gate_set_t *s, iii_gate_t g);

/* True iff every applicable gate has passed. */
bool iii_gate_set_complete(const iii_gate_set_t *s);

/* The complete proof certificate: SHA-256 of the ordered list of applicable
 * gates' partial-certificate hashes.  Only meaningful when complete. */
void iii_gate_set_compose(const iii_gate_set_t *s, uint8_t out_proof_mhash[32]);

/* ----------------------------------------------------------------------------
 * §1 / §4 — verification states.
 * ---------------------------------------------------------------------------- */
typedef enum iii_verify_state {
    III_VS_GHOST                = 0,
    III_VS_COMPROMISE_HIGH      = 1,
    III_VS_COMPROMISE_MEDIUM    = 2,
    III_VS_COMPROMISE_LOW       = 3,
    III_VS_VERIFIED             = 4
} iii_verify_state_t;

const char *iii_verify_state_name(iii_verify_state_t s);

/* §4.2 classifier: given the gate-set, classify into a verification state. */
iii_verify_state_t iii_ghost_classify_compromise(const iii_gate_set_t *s);

/* ----------------------------------------------------------------------------
 * §6 — ghost-related hexads.
 * ---------------------------------------------------------------------------- */
typedef enum iii_ghost_hexad {
    III_GH_NONE                       = 0,
    III_GH_GHOST_DECLARE              = 1,
    III_GH_GHOST_TO_VERIFIED          = 2,
    III_GH_GHOST_INVOCATION_REJECTED  = 3,
    III_GH_VERIFICATION_GATE_PASS     = 4,
    III_GH_VERIFICATION_GATE_FAIL     = 5,
    III_GH_COMPROMISE_TIER_CLASSIFY   = 6
} iii_ghost_hexad_t;

const char *iii_ghost_hexad_name(iii_ghost_hexad_t h);

/* §6.2 — pillar reachability.  The 6 pillars are encoded as a 12-bit value
 * with two bits per pillar: 00 = ZERO, 01 = POS, 10 = NEG. */
typedef struct iii_ghost_hexad_pillars {
    uint8_t p[6];      /* 0=ZERO, 1=POS, 2=NEG per pillar */
    bool    admissible;
    bool    classifies_compromise_medium;   /* if any P is NEG */
} iii_ghost_hexad_pillars_t;

void iii_ghost_hexad_get_pillars(iii_ghost_hexad_t h, iii_ghost_hexad_pillars_t *out);

/* ----------------------------------------------------------------------------
 * §7 — witness step kinds for ghost transitions.
 * ---------------------------------------------------------------------------- */
typedef enum iii_ghost_witness_kind {
    III_GW_NONE                            = 0x0000,
    III_GW_GHOST_DECLARE                   = 0x0901,
    III_GW_GATE_VERIFY_TYPE_CORRECTNESS    = 0x0902,
    III_GW_GATE_VERIFY_HEXAD_ADMISSIBILITY = 0x0903,
    III_GW_GATE_VERIFY_EFFECT_SOUNDNESS    = 0x0904,
    III_GW_GATE_VERIFY_TERMINATION         = 0x0905,
    III_GW_GATE_VERIFY_REVERSIBILITY       = 0x0906,
    III_GW_GATE_VERIFY_WITNESS_EMISSION    = 0x0907,
    III_GW_GATE_VERIFY_CAP_DISCIPLINE      = 0x0908,
    III_GW_GATE_VERIFY_TRINITY_GATING      = 0x0909,
    III_GW_GATE_VERIFY_ANCHOR_INVARIANT    = 0x090A,
    III_GW_GATE_VERIFY_PERFORMANCE_BUDGET  = 0x090B,
    III_GW_GATE_VERIFY_CONSTANT_TIME       = 0x090C,
    III_GW_GATE_VERIFY_CLOSURE_ROOT        = 0x090D,
    III_GW_GHOST_TO_VERIFIED               = 0x090E,
    III_GW_COMPROMISE_TIER_CLASSIFY        = 0x090F,
    III_GW_GHOST_INVOCATION_REJECTED       = 0x0910,
    III_GW_VERIFICATION_REVOKED            = 0x0911,
    III_GW_VERIFIED_TO_GHOST               = 0x0912
} iii_ghost_witness_kind_t;

iii_ghost_witness_kind_t iii_ghost_witness_for_gate(iii_gate_t g);

/* ----------------------------------------------------------------------------
 * §8 — cap discipline.  Three caps are exposed for ghost-code consumers.
 * ---------------------------------------------------------------------------- */
typedef enum iii_ghost_cap {
    III_CAP_NONE                  = 0,
    III_CAP_READ_GHOST_STATE      = 1,
    III_CAP_VERIFY                = 2,
    III_CAP_EXECUTE_COMPROMISED_LOW    = 3,
    III_CAP_EXECUTE_COMPROMISED_MEDIUM = 4,
    III_CAP_EXECUTE_COMPROMISED_HIGH   = 5
} iii_ghost_cap_t;

const char *iii_ghost_cap_name(iii_ghost_cap_t c);

/* §8.4 — granting CAP_EXECUTE_COMPROMISED_HIGH requires Tier-3 amendment +
 * Anchor cosignature.  The runtime tracks whether each cap has been granted
 * to a particular caller and the conditions that apply. */
typedef struct iii_ghost_cap_grant {
    iii_ghost_cap_t  cap;
    uint64_t         caller_id;
    bool             tier3_amended;       /* required for HIGH */
    bool             anchor_cosigned;     /* required for HIGH */
    bool             trinity_admitted;    /* required for HIGH on each invocation */
} iii_ghost_cap_grant_t;

/* ----------------------------------------------------------------------------
 * §1 / §3 / §5 / §9 — runtime: a register of ghost cycles + transitions.
 * ---------------------------------------------------------------------------- */

typedef struct iii_ghost_cycle {
    uint64_t            cycle_id;
    char                name[64];
    uint8_t             source_mhash[32];     /* declaration hash — always in closure root */
    uint8_t             machine_code_mhash[32]; /* zero unless verified */
    iii_verify_state_t  state;
    iii_gate_set_t      gates;
    uint8_t             proof_mhash[32];
    /* Composition propagation (§4.4) — caller-set list of dependencies */
    uint64_t            calls[16];
    unsigned            call_count;
} iii_ghost_cycle_t;

typedef struct iii_ghost_runtime iii_ghost_runtime_t;

iii_ghost_runtime_t *iii_ghost_runtime_create(void);
void iii_ghost_runtime_destroy(iii_ghost_runtime_t *rt);

/* §1 — register a cycle.  Initial state is GHOST (or VERIFIED if `bypass`
 * is true and the cycle is verified-by-construction per §1.3). */
uint64_t iii_ghost_runtime_register(iii_ghost_runtime_t *rt,
                                    const char           *name,
                                    const uint8_t         source_mhash[32],
                                    bool                  verified_by_construction);

iii_ghost_cycle_t *iii_ghost_runtime_lookup(iii_ghost_runtime_t *rt, uint64_t cycle_id);
size_t iii_ghost_runtime_size(const iii_ghost_runtime_t *rt);

/* §1 — declare which gates apply to this cycle. */
bool iii_ghost_runtime_set_applicable_gates(iii_ghost_runtime_t *rt,
                                            uint64_t              cycle_id,
                                            const bool            applicable[III_GATE_COUNT]);

/* §2 — record a gate's verification.  Pass = true installs the partial
 * certificate; false marks the gate as failed (the cycle stays ghost or
 * drops compromise tier). */
bool iii_ghost_runtime_record_gate(iii_ghost_runtime_t *rt,
                                   uint64_t              cycle_id,
                                   iii_gate_t            gate,
                                   bool                  pass,
                                   const uint8_t         certificate[32]);

/* §3 — attempt to transition ghost → verified.  Returns true iff every
 * applicable gate passed.  Updates the cycle's state and proof_mhash. */
bool iii_ghost_runtime_transition(iii_ghost_runtime_t *rt, uint64_t cycle_id);

/* §4 — re-classify the cycle's compromise tier from its current gate set. */
iii_verify_state_t iii_ghost_runtime_reclassify(iii_ghost_runtime_t *rt, uint64_t cycle_id);

/* §4.4 — composition propagation: register a call from `caller` to `callee`.
 * The caller's tier becomes max(caller, callee). */
bool iii_ghost_runtime_register_call(iii_ghost_runtime_t *rt,
                                     uint64_t              caller_id,
                                     uint64_t              callee_id);

void iii_ghost_runtime_propagate(iii_ghost_runtime_t *rt);

/* §5 — emission ban: returns true iff this cycle should produce machine
 * code in the binary.  False for ghost cycles. */
bool iii_ghost_runtime_should_emit_code(const iii_ghost_runtime_t *rt, uint64_t cycle_id);

/* §3 — invocation: returns the dispatch verdict.  Verified cycles dispatch
 * normally; compromise tiers require the corresponding cap; ghost cycles
 * are rejected. */
typedef enum iii_dispatch_verdict {
    III_DV_DISPATCH_NORMAL          = 0,
    III_DV_DISPATCH_COMPROMISE_LOW  = 1,
    III_DV_DISPATCH_COMPROMISE_MED  = 2,
    III_DV_DISPATCH_COMPROMISE_HIGH = 3,
    III_DV_REJECT_GHOST_NOT_EXECUTABLE = 4,
    III_DV_REJECT_NEEDS_CAP         = 5,
    III_DV_REJECT_NEEDS_TRINITY     = 6,
    III_DV_REJECT_UNKNOWN_CYCLE     = 7
} iii_dispatch_verdict_t;

const char *iii_dispatch_verdict_name(iii_dispatch_verdict_t v);

iii_dispatch_verdict_t iii_ghost_runtime_dispatch(const iii_ghost_runtime_t *rt,
                                                  uint64_t                    cycle_id,
                                                  const iii_ghost_cap_grant_t *caller_caps,
                                                  size_t                      caller_caps_count);

/* §7 — verification revocation. */
bool iii_ghost_runtime_revoke(iii_ghost_runtime_t *rt, uint64_t cycle_id);

/* §9 — closure-root contribution: returns the SHA-256 of all source mhashes
 * (always) + all verified machine-code mhashes (only for verified cycles). */
void iii_ghost_runtime_closure_root(const iii_ghost_runtime_t *rt, uint8_t out[32]);

/* §7 — witness count for transitions emitted so far. */
uint64_t iii_ghost_runtime_witness_count(const iii_ghost_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_GHOST_CODE_H */
