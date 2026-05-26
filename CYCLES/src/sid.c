/* ============================================================================
 * III-CYCLES — sid.c
 *
 * §3 of III-CYCLES.md.  SID — Side-effect Inverse Derivation.  The 32-step
 * type-level classifier that produces the cycle's inverse, hexad composition,
 * PIP blob classification, witness step kind allocation, and inverse replay
 * plan.
 *
 * MODELLED REFERENCE — scope note (RITCHIE Stage 1.13):
 *   This file is the STRUCT-DRIVEN reference model of the 32-step SID: it
 *   classifies a pre-populated `iii_sid_input_t` descriptor, NOT a parsed AST.
 *   The LIVE compile-time SID that actually walks every `forward` body's AST
 *   at compile time (BOOT and SELF) is `COMPILER/BOOT/sid.c`.  The prior phrase
 *   "runs at compile-time over every `forward` body" described the live impl,
 *   not this model; the two share the 32-step rule set and per-step error codes
 *   but this reference operates on the descriptor, not the syntax tree.
 *
 * Each step is enumerated explicitly with a per-step error code so that
 * compilation diagnostics can point at the exact failure site.  No SMT, no
 * external constraint solver — every check is a direct, hand-rolled rule.
 * ============================================================================
 */
#include "cycles_internal.h"
#include <string.h>

/* Names for SE kinds and SID errors. */

const char *iii_se_kind_name(iii_se_kind_t k) {
    switch (k) {
        case III_SE_NONE:             return "none";
        case III_SE_MSR_WRITE:        return "msr_write";
        case III_SE_CR_WRITE:         return "cr_write";
        case III_SE_NPT_ENTRY_WRITE:  return "npt_entry_write";
        case III_SE_VMCB_FIELD_WRITE: return "vmcb_field_write";
        case III_SE_IOMMU_DTE_WORD:   return "iommu_dte_word";
        case III_SE_AVIC_TBL_WRITE:   return "avic_tbl_write";
        case III_SE_MSRPM_BIT_SET:    return "msrpm_bit_set";
        case III_SE_IOPM_BIT_SET:     return "iopm_bit_set";
        case III_SE_PKRU_WRITE:       return "pkru_write";
        case III_SE_XCR0_WRITE:       return "xcr0_write";
        case III_SE_CAP_ACQUIRE:      return "cap_acquire";
        case III_SE_CAP_RELEASE:      return "cap_release";
        case III_SE_PAGE_ALLOC:       return "page_alloc";
        case III_SE_PAGE_FREE:        return "page_free";
        case III_SE_DPC_ARM:          return "dpc_arm";
        case III_SE_DPC_CANCEL:       return "dpc_cancel";
        case III_SE_NMI_INSTALL:      return "nmi_install";
        default:                      return "unknown";
    }
}

const char *iii_compromise_tier_name(iii_compromise_tier_t t) {
    switch (t) {
        case III_COMPROMISE_NONE:   return "none";
        case III_COMPROMISE_LOW:    return "low";
        case III_COMPROMISE_MEDIUM: return "medium";
        case III_COMPROMISE_HIGH:   return "high";
        default:                    return "unknown";
    }
}

const char *iii_sid_step_name(iii_sid_step_t s) {
    switch (s) {
        case III_SID_NONE:                       return "none";
        case III_SID_WALK_AST:                   return "01-walk-ast";
        case III_SID_CLASSIFY_KINDS:             return "02-classify-kinds";
        case III_SID_CAPTURE_PRIOR:              return "03-capture-prior";
        case III_SID_CONSTRUCT_INVERSE_RECORD:   return "04-construct-inverse-record";
        case III_SID_VERIFY_ROUNDTRIP:           return "05-verify-roundtrip";
        case III_SID_COMPOSE_HEXAD:              return "06-compose-hexad";
        case III_SID_EMIT_INVERSE_REDUCTION:     return "07-emit-inverse-reduction";
        case III_SID_REGISTER_TABLE:             return "08-register-table";
        case III_SID_THREAD_WITNESS:             return "09-thread-witness";
        case III_SID_PIP_CLASSIFY:               return "10-pip-classify";
        case III_SID_CHECK_COHERENCE:            return "11-check-coherence";
        case III_SID_TRINITY_DISCHARGE:          return "12-trinity-discharge";
        case III_SID_CEILING_MEMBERSHIP:         return "13-ceiling-membership";
        case III_SID_ALLOCATE_STEP_KIND:         return "14-allocate-step-kind";
        case III_SID_BIND_PLAN_ANCHOR:           return "15-bind-plan-anchor";
        case III_SID_FEDERATION_TIER:            return "16-federation-tier";
        case III_SID_EPOCH_CONSISTENCY:          return "17-epoch-consistency";
        case III_SID_GLYPH_DRIFT:                return "18-glyph-drift";
        case III_SID_EPISTEMIC_CLASSIFY:         return "19-epistemic-classify";
        case III_SID_GHOST_METADATA:             return "20-ghost-metadata";
        case III_SID_HOT_PATH_HINT:              return "21-hot-path-hint";
        case III_SID_EMIT_DESCRIPTOR:            return "22-emit-descriptor";
        case III_SID_OBSERVATORY_REGISTER:       return "23-observatory-register";
        case III_SID_VERIFY_NO_RAW_PRIVILEGED:   return "24-verify-no-raw-privileged";
        case III_SID_RING_MARSHAL_CHECK:         return "25-ring-marshal-check";
        case III_SID_CAP_BALANCE:                return "26-cap-balance";
        case III_SID_EMIT_REPLAY_PLAN:           return "27-emit-replay-plan";
        case III_SID_CONSTITUTIONAL_MANIFEST:    return "28-constitutional-manifest";
        case III_SID_WAAC_CHECK:                 return "29-waac-check";
        case III_SID_FINAL_REDUCTION:            return "30-final-reduction";
        case III_SID_RING_BIND:                  return "31-ring-bind";
        case III_SID_RETURN_TO_TYPECHECKER:      return "32-return";
        default:                                 return "unknown";
    }
}

const char *iii_sid_error_name(iii_sid_error_t e) {
    switch (e) {
        case III_SID_OK:                       return "ok";
        case III_SID_E_PARSE_IRPD_001:         return "PARSE-IRPD-001";
        case III_SID_E_TYPE_SID_001:           return "TYPE-SID-001";
        case III_SID_E_TYPE_SID_002:           return "TYPE-SID-002";
        case III_SID_E_TYPE_SID_003:           return "TYPE-SID-003";
        case III_SID_E_TYPE_SID_004:           return "TYPE-SID-004";
        case III_SID_E_TYPE_HEXAD_002:         return "TYPE-HEXAD-002";
        case III_SID_E_TYPE_SID_005:           return "TYPE-SID-005";
        case III_SID_E_TYPE_CYCLE_001:         return "TYPE-CYCLE-001";
        case III_SID_E_TYPE_WIT_001:           return "TYPE-WIT-001";
        case III_SID_E_TYPE_PIP_001:           return "TYPE-PIP-001";
        case III_SID_E_TYPE_MOB_001:           return "TYPE-MOB-001";
        case III_SID_E_TYPE_TRIN_001:          return "TYPE-TRIN-001";
        case III_SID_E_TYPE_CEIL_001:          return "TYPE-CEIL-001";
        case III_SID_E_TYPE_WIT_002:           return "TYPE-WIT-002";
        case III_SID_E_TYPE_PLAN_001:          return "TYPE-PLAN-001";
        case III_SID_E_TYPE_FED_001:           return "TYPE-FED-001";
        case III_SID_E_TYPE_EPOCH_001:         return "TYPE-EPOCH-001";
        case III_SID_E_TYPE_LIN_003:           return "TYPE-LIN-003";
        case III_SID_E_TYPE_EPI_001:           return "TYPE-EPI-001";
        case III_SID_E_TYPE_GHOST_001:         return "TYPE-GHOST-001";
        case III_SID_E_TYPE_SRPA_001:          return "TYPE-SRPA-001";
        case III_SID_E_TYPE_CYCLE_002:         return "TYPE-CYCLE-002";
        case III_SID_E_TYPE_OBS_001:           return "TYPE-OBS-001";
        case III_SID_E_PARSE_IRPD_002:         return "PARSE-IRPD-002";
        case III_SID_E_TYPE_RING_001:          return "TYPE-RING-001";
        case III_SID_E_TYPE_LIN_002:           return "TYPE-LIN-002";
        case III_SID_E_TYPE_INV_001:           return "TYPE-INV-001";
        case III_SID_E_TYPE_CEIL_002:          return "TYPE-CEIL-002";
        case III_SID_E_TYPE_WAAC_001:          return "TYPE-WAAC-001";
        case III_SID_E_TYPE_CYCLE_003:         return "TYPE-CYCLE-003";
        case III_SID_E_TYPE_CYCLE_004:         return "TYPE-CYCLE-004";
        case III_SID_E_TYPE_CYCLE_005:         return "TYPE-CYCLE-005";
        default:                               return "unknown";
    }
}

const char *iii_pip_kind_name(iii_pip_kind_t k) {
    switch (k) {
        case III_PIP_NONE:         return "none";
        case III_PIP_STATIC_BYTES: return "static-bytes";
        case III_PIP_DYNAMIC_FN:   return "dynamic-fn";
        case III_PIP_COMPOSED:     return "composed";
        default:                   return "unknown";
    }
}

const char *iii_catalyst_status_name(iii_catalyst_status_t s) {
    switch (s) {
        case III_CATALYST_OK:               return "ok";
        case III_CATALYST_E_RATE_CAP:       return "rate-cap";
        case III_CATALYST_E_COHERENCE:      return "coherence-below-floor";
        case III_CATALYST_E_TRINITY:        return "trinity-undischarged";
        case III_CATALYST_E_NOT_CANDIDATE:  return "not-candidate";
        case III_CATALYST_E_VALIDATION:     return "codegen-validation-failed";
        case III_CATALYST_E_NOT_FOUND:      return "original-not-found";
        case III_CATALYST_E_INVARIANT:      return "invariant-violation";
        default:                            return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * compose_hexad — bitwise OR of all per-call hexads.  The composed bitmap
 * must remain a member of `xii_asym_reach6` (the admissible set).  We model
 * `xii_asym_reach6` as a small, fixed set of permitted bitmasks; for the
 * canonical 17 SE kinds we admit any non-zero bitmap whose population count
 * is ≤ 6 (the "hexad" condition: at most six concurrent safety axes).
 * ---------------------------------------------------------------------------- */
static unsigned popcount16(uint16_t x) {
    unsigned n = 0;
    while (x) { n += (unsigned)(x & 1u); x >>= 1; }
    return n;
}

static uint16_t compose_hexad(const iii_sid_call_t *calls, unsigned count) {
    uint16_t h = 0;
    for (unsigned i = 0; i < count; ++i) h |= calls[i].per_call_hexad;
    return h;
}

static bool hexad_admissible(uint16_t h) {
    return h != 0 && popcount16(h) <= 6u;
}

/* PIP classification (§3.2 step 10).  STATIC if every SE kind's inverse is a
 * fixed byte sequence (we treat MSR_WRITE, CR_WRITE, PKRU_WRITE, XCR0_WRITE
 * as STATIC); DYNAMIC if any SE kind requires runtime reconstruction
 * (NPT_ENTRY_WRITE, IOMMU_DTE_WORD, AVIC_TBL_WRITE); COMPOSED if both. */
static iii_pip_kind_t pip_classify(const iii_sid_call_t *calls, unsigned count) {
    bool has_static  = false;
    bool has_dynamic = false;
    for (unsigned i = 0; i < count; ++i) {
        switch (calls[i].kind) {
            case III_SE_MSR_WRITE:
            case III_SE_CR_WRITE:
            case III_SE_PKRU_WRITE:
            case III_SE_XCR0_WRITE:
            case III_SE_MSRPM_BIT_SET:
            case III_SE_IOPM_BIT_SET:
                has_static = true;
                break;
            case III_SE_NPT_ENTRY_WRITE:
            case III_SE_VMCB_FIELD_WRITE:
            case III_SE_IOMMU_DTE_WORD:
            case III_SE_AVIC_TBL_WRITE:
            case III_SE_PAGE_ALLOC:
            case III_SE_PAGE_FREE:
            case III_SE_DPC_ARM:
            case III_SE_DPC_CANCEL:
            case III_SE_NMI_INSTALL:
            case III_SE_CAP_ACQUIRE:
            case III_SE_CAP_RELEASE:
                has_dynamic = true;
                break;
            default: break;
        }
    }
    if (has_static && has_dynamic) return III_PIP_COMPOSED;
    if (has_static)                return III_PIP_STATIC_BYTES;
    if (has_dynamic)               return III_PIP_DYNAMIC_FN;
    return III_PIP_NONE;
}

/* Step-kind allocation (§3.2 step 14): given the dominant SE kind, pick a
 * reserved slot in the IRPD_PRIVILEGED_WRITE band [0x0010..0x002F]. */
static uint16_t allocate_step_kind(const iii_sid_call_t *calls, unsigned count) {
    /* Dominant kind = the one with the most calls. */
    unsigned counts[III_SE_COUNT];
    for (unsigned i = 0; i < III_SE_COUNT; ++i) counts[i] = 0;
    for (unsigned i = 0; i < count; ++i) {
        if ((unsigned)calls[i].kind < III_SE_COUNT) counts[calls[i].kind]++;
    }
    unsigned best = 0;
    iii_se_kind_t dom = III_SE_NONE;
    for (unsigned i = 1; i < III_SE_COUNT; ++i) {
        if (counts[i] > best) { best = counts[i]; dom = (iii_se_kind_t)i; }
    }
    if (dom == III_SE_NONE) return 0;
    return (uint16_t)(0x0010u + (uint16_t)dom);
}

/* Inverse replay bitmap (§3.2 step 27): bit i corresponds to call i in the
 * forward; set if the i-th call needs an inverse step at rollback.  All 17
 * SE kinds require an inverse, so the bitmap is dense. */
static uint32_t emit_replay_plan(const iii_sid_call_t *calls, unsigned count) {
    uint32_t bm = 0;
    for (unsigned i = 0; i < count && i < 32; ++i) {
        if (calls[i].kind != III_SE_NONE) bm |= (1u << i);
    }
    return bm;
}

/* ----------------------------------------------------------------------------
 * The 32-step driver.  Each step performs its check; on failure it sets the
 * output's failed_at_step and error fields and returns immediately.
 * ---------------------------------------------------------------------------- */

static void fail(iii_sid_output_t *out, iii_sid_step_t s, iii_sid_error_t e) {
    out->ok = false;
    out->failed_at_step = s;
    out->error = e;
}

void iii_sid_run(const iii_sid_input_t *in, iii_sid_output_t *out) {
    memset(out, 0, sizeof(*out));
    out->ok = false;

    if (!in) { fail(out, III_SID_WALK_AST, III_SID_E_PARSE_IRPD_001); return; }

    /* Step 1 — walk AST: caller pre-walked.  Reject if raw privileged write. */
    if (in->raw_privileged_outside_irpd) {
        fail(out, III_SID_WALK_AST, III_SID_E_PARSE_IRPD_001);
        return;
    }

    /* Step 2 — classify kinds.  Every call must have a known SE kind. */
    for (unsigned i = 0; i < in->call_count; ++i) {
        if (in->calls[i].kind == III_SE_NONE || in->calls[i].kind >= III_SE_COUNT) {
            fail(out, III_SID_CLASSIFY_KINDS, III_SID_E_TYPE_SID_001);
            return;
        }
    }

    /* Step 3 — capture prior values.  Each call's prior_value_captured must hold. */
    for (unsigned i = 0; i < in->call_count; ++i) {
        if (!in->calls[i].prior_value_captured) {
            fail(out, III_SID_CAPTURE_PRIOR, III_SID_E_TYPE_SID_002);
            return;
        }
    }

    /* Step 4 — construct inverse record.  For every kind we have a layout in
     * STDLIB/sid; the construction can only fail if a call has no kind, which
     * we've already rejected.  Treat as always succeeding except on call_count==0. */
    if (in->call_count == 0 && !in->pure_) {
        fail(out, III_SID_CONSTRUCT_INVERSE_RECORD, III_SID_E_TYPE_SID_003);
        return;
    }

    /* Step 5 — verify roundtrip. */
    if (!in->pure_ && !in->roundtrip_ok) {
        fail(out, III_SID_VERIFY_ROUNDTRIP, III_SID_E_TYPE_SID_004);
        return;
    }

    /* Step 6 — compose hexad, check admissibility. */
    uint16_t composed = compose_hexad(in->calls, in->call_count);
    if (in->pure_ && composed == 0) {
        composed = in->declared_hexad;  /* pure cycles inherit declared hexad */
    }
    if (!hexad_admissible(composed)) {
        fail(out, III_SID_COMPOSE_HEXAD, III_SID_E_TYPE_HEXAD_002);
        return;
    }
    out->composed_hexad = composed;

    /* Step 7 — emit inverse Reduction (always succeeds at the modelling level). */

    /* Step 8 — register in cycle table.  Modelled by the caller's later
     * register call; we don't fail here unless pure_ and call_count==0 (already
     * caught) — we treat it as succeeding. */

    /* Step 9 — thread witness predecessor/successor mhashes.  Always succeeds
     * in the model unless witness elision is mis-applied to a non-pure cycle. */
    if (in->witness_elide && !in->pure_) {
        fail(out, III_SID_THREAD_WITNESS, III_SID_E_TYPE_WIT_001);
        return;
    }

    /* Step 10 — PIP classification. */
    out->pip_kind = pip_classify(in->calls, in->call_count);
    /* For pure cycles we admit III_PIP_NONE; for effectful, NONE is a failure. */
    if (!in->pure_ && out->pip_kind == III_PIP_NONE && in->call_count > 0) {
        fail(out, III_SID_PIP_CLASSIFY, III_SID_E_TYPE_PIP_001);
        return;
    }

    /* Step 11 — Möbius coherence floor. */
    if (in->coherence_floor_q14 > 0 && in->coherence_q14 < in->coherence_floor_q14) {
        fail(out, III_SID_CHECK_COHERENCE, III_SID_E_TYPE_MOB_001);
        return;
    }

    /* Step 12 — Trinity discharge. */
    if (!in->trinity_discharged) {
        fail(out, III_SID_TRINITY_DISCHARGE, III_SID_E_TYPE_TRIN_001);
        return;
    }

    /* Step 13 — Ceiling membership. */
    if (!in->ceiling_admitted) {
        fail(out, III_SID_CEILING_MEMBERSHIP, III_SID_E_TYPE_CEIL_001);
        return;
    }

    /* Step 14 — Allocate step kind. */
    if (in->pure_ && in->call_count == 0) {
        out->allocated_step_kind = 0; /* pure-no-effect → no step kind needed */
    } else {
        uint16_t sk = allocate_step_kind(in->calls, in->call_count);
        if (sk == 0) { fail(out, III_SID_ALLOCATE_STEP_KIND, III_SID_E_TYPE_WIT_002); return; }
        out->allocated_step_kind = sk;
    }

    /* Step 15 — Plan anchor. */
    if (in->plan_anchor_id == 0) {
        fail(out, III_SID_BIND_PLAN_ANCHOR, III_SID_E_TYPE_PLAN_001);
        return;
    }

    /* Step 16 — Federation tier match. */
    if (!in->federation_match) {
        fail(out, III_SID_FEDERATION_TIER, III_SID_E_TYPE_FED_001);
        return;
    }

    /* Step 17 — Epoch consistency: cycle epoch ≤ current epoch unless
     * @epoch_bridge is set. */
    if (!in->epoch_bridge && in->cycle_epoch > in->current_epoch) {
        fail(out, III_SID_EPOCH_CONSISTENCY, III_SID_E_TYPE_EPOCH_001);
        return;
    }

    /* Step 18 — Glyph drift. */
    if (!in->glyphs_resolved) {
        fail(out, III_SID_GLYPH_DRIFT, III_SID_E_TYPE_LIN_003);
        return;
    }

    /* Step 19 — Epistemic uncertainty (always succeeds at this level). */

    /* Step 20 — Ghost metadata: only legal on pure+witness_elide. */
    if (in->witness_elide && !in->pure_) {
        fail(out, III_SID_GHOST_METADATA, III_SID_E_TYPE_GHOST_001);
        return;
    }

    /* Step 21 — Hot-path hint: always succeeds.  (No semantic check beyond
     * the modifier presence; SRPA consumes it later.) */

    /* Step 22 — Emit descriptor (modelled as always successful). */

    /* Step 23 — Observatory registration: only on @candidate_for_promotion. */
    /* (No-op at the modelling level; caller will register separately.) */

    /* Step 24 — Verify no raw privileged outside IRPD (defence in depth). */
    if (in->raw_privileged_outside_irpd) {
        fail(out, III_SID_VERIFY_NO_RAW_PRIVILEGED, III_SID_E_PARSE_IRPD_002);
        return;
    }

    /* Step 25 — Ring marshalling check. */
    if (!in->ring_marshalling_available) {
        fail(out, III_SID_RING_MARSHAL_CHECK, III_SID_E_TYPE_RING_001);
        return;
    }

    /* Step 26 — Capability balance. */
    if (!in->cap_balanced) {
        fail(out, III_SID_CAP_BALANCE, III_SID_E_TYPE_LIN_002);
        return;
    }

    /* Step 27 — Emit replay plan. */
    out->inverse_replay_bitmap = emit_replay_plan(in->calls, in->call_count);

    /* Step 28 — Constitutional manifest contribution. */
    if (!in->constitutional_manifest_ok) {
        fail(out, III_SID_CONSTITUTIONAL_MANIFEST, III_SID_E_TYPE_CEIL_002);
        return;
    }

    /* Step 29 — WAAC check. */
    if (!in->waac_ok) {
        fail(out, III_SID_WAAC_CHECK, III_SID_E_TYPE_WAAC_001);
        return;
    }

    /* Step 30 — Final Reduction emission (always succeeds). */
    /* Step 31 — Ring bind (always succeeds in the model). */
    /* Step 32 — Return to typechecker. */

    out->ok = true;
    out->failed_at_step = III_SID_RETURN_TO_TYPECHECKER;
    out->error = III_SID_OK;
}
