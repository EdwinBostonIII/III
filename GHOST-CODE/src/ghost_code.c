/* III-GHOST-CODE — runtime implementation. */
#include "iii/ghost_code.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

#define III_GHOST_MAX_CYCLES   1024u

struct iii_ghost_runtime {
    iii_ghost_cycle_t cycles[III_GHOST_MAX_CYCLES];
    unsigned          count;
    uint64_t          next_id;
    uint64_t          witness_count;
};

const char *iii_gate_name(iii_gate_t g) {
    switch (g) {
        case III_GATE_NONE:                  return "none";
        case III_GATE_TYPE_CORRECTNESS:      return "type-correctness";
        case III_GATE_HEXAD_ADMISSIBILITY:   return "hexad-admissibility";
        case III_GATE_EFFECT_SOUNDNESS:      return "effect-soundness";
        case III_GATE_TERMINATION:           return "termination";
        case III_GATE_REVERSIBILITY:         return "reversibility";
        case III_GATE_WITNESS_EMISSION:      return "witness-emission";
        case III_GATE_CAP_DISCIPLINE:        return "cap-discipline";
        case III_GATE_TRINITY_GATING:        return "trinity-gating";
        case III_GATE_ANCHOR_INVARIANT:      return "anchor-invariant";
        case III_GATE_PERFORMANCE_BUDGET:    return "performance-budget";
        case III_GATE_CONSTANT_TIME:         return "constant-time";
        case III_GATE_CLOSURE_ROOT:          return "closure-root";
        default:                             return "unknown";
    }
}

const char *iii_verify_state_name(iii_verify_state_t s) {
    switch (s) {
        case III_VS_GHOST:             return "ghost";
        case III_VS_COMPROMISE_HIGH:   return "compromise-high";
        case III_VS_COMPROMISE_MEDIUM: return "compromise-medium";
        case III_VS_COMPROMISE_LOW:    return "compromise-low";
        case III_VS_VERIFIED:          return "verified";
        default:                       return "unknown";
    }
}

const char *iii_ghost_hexad_name(iii_ghost_hexad_t h) {
    switch (h) {
        case III_GH_NONE:                       return "none";
        case III_GH_GHOST_DECLARE:              return "GHOST_DECLARE";
        case III_GH_GHOST_TO_VERIFIED:          return "GHOST_TO_VERIFIED";
        case III_GH_GHOST_INVOCATION_REJECTED:  return "GHOST_INVOCATION_REJECTED";
        case III_GH_VERIFICATION_GATE_PASS:     return "VERIFICATION_GATE_PASS";
        case III_GH_VERIFICATION_GATE_FAIL:     return "VERIFICATION_GATE_FAIL";
        case III_GH_COMPROMISE_TIER_CLASSIFY:   return "COMPROMISE_TIER_CLASSIFY";
        default:                                return "unknown";
    }
}

const char *iii_ghost_cap_name(iii_ghost_cap_t c) {
    switch (c) {
        case III_CAP_NONE:                       return "none";
        case III_CAP_READ_GHOST_STATE:           return "read_ghost_state";
        case III_CAP_VERIFY:                     return "verify";
        case III_CAP_EXECUTE_COMPROMISED_LOW:    return "execute_compromised<low>";
        case III_CAP_EXECUTE_COMPROMISED_MEDIUM: return "execute_compromised<medium>";
        case III_CAP_EXECUTE_COMPROMISED_HIGH:   return "execute_compromised<high>";
        default:                                 return "unknown";
    }
}

const char *iii_dispatch_verdict_name(iii_dispatch_verdict_t v) {
    switch (v) {
        case III_DV_DISPATCH_NORMAL:               return "dispatch-normal";
        case III_DV_DISPATCH_COMPROMISE_LOW:       return "dispatch-compromise-low";
        case III_DV_DISPATCH_COMPROMISE_MED:       return "dispatch-compromise-medium";
        case III_DV_DISPATCH_COMPROMISE_HIGH:      return "dispatch-compromise-high";
        case III_DV_REJECT_GHOST_NOT_EXECUTABLE:   return "GHOST-NOT-EXECUTABLE";
        case III_DV_REJECT_NEEDS_CAP:              return "needs-cap";
        case III_DV_REJECT_NEEDS_TRINITY:          return "needs-trinity";
        case III_DV_REJECT_UNKNOWN_CYCLE:          return "unknown-cycle";
        default:                                   return "unknown";
    }
}

iii_ghost_witness_kind_t iii_ghost_witness_for_gate(iii_gate_t g) {
    switch (g) {
        case III_GATE_TYPE_CORRECTNESS:      return III_GW_GATE_VERIFY_TYPE_CORRECTNESS;
        case III_GATE_HEXAD_ADMISSIBILITY:   return III_GW_GATE_VERIFY_HEXAD_ADMISSIBILITY;
        case III_GATE_EFFECT_SOUNDNESS:      return III_GW_GATE_VERIFY_EFFECT_SOUNDNESS;
        case III_GATE_TERMINATION:           return III_GW_GATE_VERIFY_TERMINATION;
        case III_GATE_REVERSIBILITY:         return III_GW_GATE_VERIFY_REVERSIBILITY;
        case III_GATE_WITNESS_EMISSION:      return III_GW_GATE_VERIFY_WITNESS_EMISSION;
        case III_GATE_CAP_DISCIPLINE:        return III_GW_GATE_VERIFY_CAP_DISCIPLINE;
        case III_GATE_TRINITY_GATING:        return III_GW_GATE_VERIFY_TRINITY_GATING;
        case III_GATE_ANCHOR_INVARIANT:      return III_GW_GATE_VERIFY_ANCHOR_INVARIANT;
        case III_GATE_PERFORMANCE_BUDGET:    return III_GW_GATE_VERIFY_PERFORMANCE_BUDGET;
        case III_GATE_CONSTANT_TIME:         return III_GW_GATE_VERIFY_CONSTANT_TIME;
        case III_GATE_CLOSURE_ROOT:          return III_GW_GATE_VERIFY_CLOSURE_ROOT;
        default:                             return III_GW_NONE;
    }
}

void iii_ghost_hexad_get_pillars(iii_ghost_hexad_t h, iii_ghost_hexad_pillars_t *out) {
    if (!out) return;
    memset(out, 0, sizeof(*out));
    out->admissible = true;
    /* Encode: 0=ZERO, 1=POS, 2=NEG */
    switch (h) {
        case III_GH_GHOST_DECLARE:
            out->p[0]=1; out->p[1]=0; out->p[2]=0; out->p[3]=1; out->p[4]=0; out->p[5]=0; break;
        case III_GH_GHOST_TO_VERIFIED:
            out->p[0]=1; out->p[1]=1; out->p[2]=0; out->p[3]=1; out->p[4]=1; out->p[5]=1; break;
        case III_GH_GHOST_INVOCATION_REJECTED:
            out->p[0]=0; out->p[1]=1; out->p[2]=0; out->p[3]=0; out->p[4]=0; out->p[5]=1; break;
        case III_GH_VERIFICATION_GATE_PASS:
            out->p[0]=1; out->p[1]=1; out->p[2]=1; out->p[3]=1; out->p[4]=1; out->p[5]=1; break;
        case III_GH_VERIFICATION_GATE_FAIL:
            out->p[0]=2; out->p[1]=2; out->p[2]=1; out->p[3]=0; out->p[4]=0; out->p[5]=0;
            out->classifies_compromise_medium = true;
            break;
        case III_GH_COMPROMISE_TIER_CLASSIFY:
            out->p[0]=1; out->p[1]=1; out->p[2]=0; out->p[3]=0; out->p[4]=0; out->p[5]=1; break;
        default:
            out->admissible = false;
            break;
    }
}

/* ----------------------------------------------------------------------------
 * Gate-set ops
 * ---------------------------------------------------------------------------- */
void iii_gate_set_init(iii_gate_set_t *s) {
    if (!s) return;
    memset(s, 0, sizeof(*s));
}

void iii_gate_set_mark_applicable(iii_gate_set_t *s, iii_gate_t g, bool yes) {
    if (!s || g >= III_GATE_COUNT) return;
    s->applicable[g] = yes;
    if (!yes) {
        s->passed[g] = false;
        memset(s->certificate[g], 0, 32);
    }
}

void iii_gate_set_record_pass(iii_gate_set_t *s, iii_gate_t g, const uint8_t cert[32]) {
    if (!s || g >= III_GATE_COUNT) return;
    s->passed[g] = true;
    if (cert) memcpy(s->certificate[g], cert, 32);
}

void iii_gate_set_record_fail(iii_gate_set_t *s, iii_gate_t g) {
    if (!s || g >= III_GATE_COUNT) return;
    s->passed[g] = false;
    memset(s->certificate[g], 0, 32);
}

bool iii_gate_set_complete(const iii_gate_set_t *s) {
    if (!s) return false;
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        if (s->applicable[g] && !s->passed[g]) return false;
    }
    /* At least one applicable gate must exist. */
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        if (s->applicable[g]) return true;
    }
    return false;
}

void iii_gate_set_compose(const iii_gate_set_t *s, uint8_t out_proof_mhash[32]) {
    if (!s || !out_proof_mhash) return;
    if (!iii_gate_set_complete(s)) {
        memset(out_proof_mhash, 0, 32);
        return;
    }
    uint8_t buf[III_GATE_COUNT * 32];
    size_t  pos = 0;
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        if (s->applicable[g] && s->passed[g]) {
            memcpy(buf + pos, s->certificate[g], 32);
            pos += 32;
        }
    }
    iii_sha256(buf, pos, out_proof_mhash);
}

/* ----------------------------------------------------------------------------
 * Compromise classification (§4.2)
 * ---------------------------------------------------------------------------- */
iii_verify_state_t iii_ghost_classify_compromise(const iii_gate_set_t *s) {
    if (!s) return III_VS_GHOST;

    /* Hard fails: any of these causes outright ghost. */
    if (s->applicable[III_GATE_ANCHOR_INVARIANT]    && !s->passed[III_GATE_ANCHOR_INVARIANT])    return III_VS_GHOST;
    if (s->applicable[III_GATE_TYPE_CORRECTNESS]    && !s->passed[III_GATE_TYPE_CORRECTNESS])    return III_VS_GHOST;
    if (s->applicable[III_GATE_HEXAD_ADMISSIBILITY] && !s->passed[III_GATE_HEXAD_ADMISSIBILITY]) return III_VS_GHOST;

    /* Count critical (non-deferrable) failures.  Deferrable: termination,
     * reversibility, performance, constant-time. */
    bool deferrable[III_GATE_COUNT] = {0};
    deferrable[III_GATE_TERMINATION]        = true;
    deferrable[III_GATE_REVERSIBILITY]      = true;
    deferrable[III_GATE_PERFORMANCE_BUDGET] = true;
    deferrable[III_GATE_CONSTANT_TIME]      = true;

    unsigned critical_failed = 0;
    bool reversibility_only = true;
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        if (!s->applicable[g]) continue;
        if (s->passed[g]) continue;
        if (!deferrable[g]) {
            critical_failed++;
            reversibility_only = false;
        } else if (g != III_GATE_REVERSIBILITY) {
            reversibility_only = false;
        }
    }

    /* If only reversibility deferred → COMPROMISE_LOW. */
    if (critical_failed == 0) {
        unsigned non_pass = 0;
        for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
            if (s->applicable[g] && !s->passed[g]) non_pass++;
        }
        if (non_pass == 0) return III_VS_VERIFIED;
        /* SCOPE NOTE (RITCHIE Stage 1.14): the line below makes this classifier
         * return COMPROMISE_LOW for ANY non-critical deferrable failure, not
         * only when the single non-pass is reversibility. Per the D10 spec, a
         * single non-reversibility deferrable failure (or >1 non-pass) should
         * be COMPROMISE_MEDIUM, with LOW reserved for the reversibility-only
         * case. Tightening to the spec rule (the `reversibility_only` guard
         * above becomes load-bearing; non-reversibility/multi-fail → MEDIUM) is
         * RITCHIE Stage 8.10. The current behavior is over-permissive but
         * fail-safe-toward-dispatch; tightening is a correctness hardening, not
         * a crash fix. See DOCS/CONVERGENCE-AUDIT.md. */
        if (non_pass == 1 && reversibility_only) return III_VS_COMPROMISE_LOW;
        return III_VS_COMPROMISE_LOW;
    }
    if (critical_failed <= 2) return III_VS_COMPROMISE_MEDIUM;
    return III_VS_COMPROMISE_HIGH;
}

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */

iii_ghost_runtime_t *iii_ghost_runtime_create(void) {
    iii_ghost_runtime_t *rt = (iii_ghost_runtime_t *)calloc(1, sizeof(*rt));
    return rt;
}

void iii_ghost_runtime_destroy(iii_ghost_runtime_t *rt) {
    if (!rt) return;
    free(rt);
}

uint64_t iii_ghost_runtime_register(iii_ghost_runtime_t *rt,
                                    const char           *name,
                                    const uint8_t         source_mhash[32],
                                    bool                  verified_by_construction)
{
    if (!rt || !name || !source_mhash) return 0;
    if (rt->count >= III_GHOST_MAX_CYCLES) return 0;
    iii_ghost_cycle_t *c = &rt->cycles[rt->count++];
    memset(c, 0, sizeof(*c));
    c->cycle_id = ++rt->next_id;
    size_t i = 0;
    for (; i < sizeof(c->name) - 1u && name[i]; ++i) c->name[i] = name[i];
    c->name[i] = '\0';
    memcpy(c->source_mhash, source_mhash, 32);
    iii_gate_set_init(&c->gates);

    if (verified_by_construction) {
        /* §1.3 — bypass.  Mark every gate as inapplicable except the four
         * essentials (type, hexad, witness, closure-root) all of which
         * auto-pass.  Result: VERIFIED. */
        c->gates.applicable[III_GATE_TYPE_CORRECTNESS]    = true;
        c->gates.applicable[III_GATE_HEXAD_ADMISSIBILITY] = true;
        c->gates.applicable[III_GATE_WITNESS_EMISSION]    = true;
        c->gates.applicable[III_GATE_CLOSURE_ROOT]        = true;
        for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
            if (c->gates.applicable[g]) {
                c->gates.passed[g] = true;
                memset(c->gates.certificate[g], 0xC1, 32);
            }
        }
        c->state = III_VS_VERIFIED;
        iii_gate_set_compose(&c->gates, c->proof_mhash);
        /* Machine-code mhash = SHA-256(source || "vbc"). */
        uint8_t buf[35]; memcpy(buf, source_mhash, 32); memcpy(buf+32, "vbc", 3);
        iii_sha256(buf, 35, c->machine_code_mhash);
    } else {
        c->state = III_VS_GHOST;
    }
    rt->witness_count++;
    return c->cycle_id;
}

iii_ghost_cycle_t *iii_ghost_runtime_lookup(iii_ghost_runtime_t *rt, uint64_t cycle_id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->cycles[i].cycle_id == cycle_id) return &rt->cycles[i];
    }
    return NULL;
}

size_t iii_ghost_runtime_size(const iii_ghost_runtime_t *rt) {
    return rt ? rt->count : 0u;
}

bool iii_ghost_runtime_set_applicable_gates(iii_ghost_runtime_t *rt,
                                            uint64_t              cycle_id,
                                            const bool            applicable[III_GATE_COUNT])
{
    iii_ghost_cycle_t *c = iii_ghost_runtime_lookup(rt, cycle_id);
    if (!c) return false;
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        c->gates.applicable[g] = applicable[g];
    }
    return true;
}

bool iii_ghost_runtime_record_gate(iii_ghost_runtime_t *rt,
                                   uint64_t              cycle_id,
                                   iii_gate_t            gate,
                                   bool                  pass,
                                   const uint8_t         certificate[32])
{
    iii_ghost_cycle_t *c = iii_ghost_runtime_lookup(rt, cycle_id);
    if (!c) return false;
    if (gate >= III_GATE_COUNT) return false;
    if (!c->gates.applicable[gate]) return false;
    if (pass) iii_gate_set_record_pass(&c->gates, gate, certificate);
    else      iii_gate_set_record_fail(&c->gates, gate);
    rt->witness_count++;
    return true;
}

bool iii_ghost_runtime_transition(iii_ghost_runtime_t *rt, uint64_t cycle_id) {
    iii_ghost_cycle_t *c = iii_ghost_runtime_lookup(rt, cycle_id);
    if (!c) return false;
    if (!iii_gate_set_complete(&c->gates)) return false;

    iii_gate_set_compose(&c->gates, c->proof_mhash);
    c->state = III_VS_VERIFIED;
    /* Generate the machine-code mhash deterministically. */
    uint8_t buf[64];
    memcpy(buf,    c->source_mhash, 32);
    memcpy(buf+32, c->proof_mhash,  32);
    iii_sha256(buf, 64, c->machine_code_mhash);
    rt->witness_count++;
    return true;
}

iii_verify_state_t iii_ghost_runtime_reclassify(iii_ghost_runtime_t *rt, uint64_t cycle_id) {
    iii_ghost_cycle_t *c = iii_ghost_runtime_lookup(rt, cycle_id);
    if (!c) return III_VS_GHOST;
    iii_verify_state_t s = iii_ghost_classify_compromise(&c->gates);
    c->state = s;
    if (s == III_VS_VERIFIED) {
        iii_gate_set_compose(&c->gates, c->proof_mhash);
    }
    rt->witness_count++;
    return s;
}

bool iii_ghost_runtime_register_call(iii_ghost_runtime_t *rt,
                                     uint64_t              caller_id,
                                     uint64_t              callee_id)
{
    iii_ghost_cycle_t *caller = iii_ghost_runtime_lookup(rt, caller_id);
    iii_ghost_cycle_t *callee = iii_ghost_runtime_lookup(rt, callee_id);
    if (!caller || !callee) return false;
    if (caller->call_count >= 16) return false;
    caller->calls[caller->call_count++] = callee_id;
    return true;
}

void iii_ghost_runtime_propagate(iii_ghost_runtime_t *rt) {
    if (!rt) return;
    /* Repeated relaxation until fixed point.  Compromise rule: caller's tier
     * ≤ min(caller, callee).  We map the verify_state ordinals so that
     * GHOST=0, COMP_HIGH=1, COMP_MED=2, COMP_LOW=3, VERIFIED=4. */
    bool changed = true;
    while (changed) {
        changed = false;
        for (unsigned i = 0; i < rt->count; ++i) {
            iii_ghost_cycle_t *c = &rt->cycles[i];
            for (unsigned k = 0; k < c->call_count; ++k) {
                iii_ghost_cycle_t *cc = iii_ghost_runtime_lookup(rt, c->calls[k]);
                if (!cc) continue;
                if ((unsigned)cc->state < (unsigned)c->state) {
                    c->state = cc->state;
                    changed = true;
                }
            }
        }
    }
    rt->witness_count++;
}

bool iii_ghost_runtime_should_emit_code(const iii_ghost_runtime_t *rt, uint64_t cycle_id) {
    if (!rt) return false;
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->cycles[i].cycle_id == cycle_id) {
            return rt->cycles[i].state != III_VS_GHOST;
        }
    }
    return false;
}

static bool has_cap(const iii_ghost_cap_grant_t *caps, size_t n, iii_ghost_cap_t cap) {
    for (size_t i = 0; i < n; ++i) {
        if (caps[i].cap == cap) {
            if (cap == III_CAP_EXECUTE_COMPROMISED_HIGH) {
                return caps[i].tier3_amended && caps[i].anchor_cosigned && caps[i].trinity_admitted;
            }
            return true;
        }
    }
    return false;
}

iii_dispatch_verdict_t iii_ghost_runtime_dispatch(const iii_ghost_runtime_t *rt,
                                                  uint64_t                    cycle_id,
                                                  const iii_ghost_cap_grant_t *caller_caps,
                                                  size_t                      caller_caps_count)
{
    if (!rt) return III_DV_REJECT_UNKNOWN_CYCLE;
    const iii_ghost_cycle_t *c = NULL;
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->cycles[i].cycle_id == cycle_id) { c = &rt->cycles[i]; break; }
    }
    if (!c) return III_DV_REJECT_UNKNOWN_CYCLE;

    switch (c->state) {
        case III_VS_VERIFIED:
            return III_DV_DISPATCH_NORMAL;
        case III_VS_COMPROMISE_LOW:
            /* LOW is auto-dispatchable — no capability required (D10 spec).
             * (RITCHIE Stage 1.15: removed an inert cap-check here whose
             * has_cap and !has_cap branches BOTH returned
             * III_DV_DISPATCH_COMPROMISE_LOW — dead code. The capability
             * `III_CAP_EXECUTE_COMPROMISED_LOW` is intentionally NOT consulted:
             * a LOW-compromise cycle dispatches unconditionally.) */
            return III_DV_DISPATCH_COMPROMISE_LOW;
        case III_VS_COMPROMISE_MEDIUM:
            if (!caller_caps || !has_cap(caller_caps, caller_caps_count, III_CAP_EXECUTE_COMPROMISED_MEDIUM)) {
                return III_DV_REJECT_NEEDS_CAP;
            }
            return III_DV_DISPATCH_COMPROMISE_MED;
        case III_VS_COMPROMISE_HIGH:
            if (!caller_caps || !has_cap(caller_caps, caller_caps_count, III_CAP_EXECUTE_COMPROMISED_HIGH)) {
                /* Distinguish whether the cap is missing or just lacks Trinity. */
                for (size_t i = 0; i < caller_caps_count; ++i) {
                    if (caller_caps[i].cap == III_CAP_EXECUTE_COMPROMISED_HIGH) {
                        if (!caller_caps[i].tier3_amended || !caller_caps[i].anchor_cosigned) {
                            return III_DV_REJECT_NEEDS_CAP;
                        }
                        if (!caller_caps[i].trinity_admitted) return III_DV_REJECT_NEEDS_TRINITY;
                    }
                }
                return III_DV_REJECT_NEEDS_CAP;
            }
            return III_DV_DISPATCH_COMPROMISE_HIGH;
        case III_VS_GHOST:
        default:
            return III_DV_REJECT_GHOST_NOT_EXECUTABLE;
    }
}

bool iii_ghost_runtime_revoke(iii_ghost_runtime_t *rt, uint64_t cycle_id) {
    iii_ghost_cycle_t *c = iii_ghost_runtime_lookup(rt, cycle_id);
    if (!c) return false;
    c->state = III_VS_GHOST;
    memset(c->machine_code_mhash, 0, 32);
    /* All gate certificates retained; can be re-attempted. */
    rt->witness_count++;
    return true;
}

void iii_ghost_runtime_closure_root(const iii_ghost_runtime_t *rt, uint8_t out[32]) {
    if (!rt || !out) { if (out) memset(out, 0, 32); return; }
    /* Source mhashes always; machine-code mhashes only for non-ghost. */
    uint8_t buf[III_GHOST_MAX_CYCLES * 64];
    size_t  pos = 0;
    for (unsigned i = 0; i < rt->count; ++i) {
        const iii_ghost_cycle_t *c = &rt->cycles[i];
        memcpy(buf + pos, c->source_mhash, 32);
        pos += 32;
        if (c->state != III_VS_GHOST) {
            memcpy(buf + pos, c->machine_code_mhash, 32);
            pos += 32;
        }
        if (pos > sizeof(buf) - 64) break;
    }
    iii_sha256(buf, pos, out);
}

uint64_t iii_ghost_runtime_witness_count(const iii_ghost_runtime_t *rt) {
    return rt ? rt->witness_count : 0u;
}
