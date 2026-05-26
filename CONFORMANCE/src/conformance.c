/* III-CONFORMANCE implementation. */
#include "iii/conformance.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

const char *iii_conf_group_name(iii_conf_group_t g) {
    switch (g) {
        case III_CG_CORE_LANGUAGE: return "Core Language";
        case III_CG_SUBSTRATE:     return "Substrate & Runtime";
        case III_CG_COGNITIVE:     return "Cognitive Layer";
        case III_CG_RESOLUTION:    return "Resolution";
        default:                   return "unknown";
    }
}

const char *iii_conf_status_name(iii_conf_status_t s) {
    switch (s) {
        case III_CR_PASS: return "PASS";
        case III_CR_FAIL: return "FAIL";
        case III_CR_SKIP: return "SKIP";
        default:          return "NONE";
    }
}

static const iii_conf_criterion_t kCriteria[III_CONF_COUNT] = {
    /* Core Language C-1..C-15 */
    { 1, III_CG_CORE_LANGUAGE, "C-1",  "Closure Root Determinism",        "TESTS/conformance/closure_root_determinism.III"},
    { 2, III_CG_CORE_LANGUAGE, "C-2",  "Phase-Polymorphism Soundness",     "TESTS/conformance/phase_poly_soundness.III"},
    { 3, III_CG_CORE_LANGUAGE, "C-3",  "SID Inverse Round-Trip",           "TESTS/conformance/sid_round_trip.III"},
    { 4, III_CG_CORE_LANGUAGE, "C-4",  "Hexad Unrepresentability",         "TESTS/conformance/hexad_unrep.III"},
    { 5, III_CG_CORE_LANGUAGE, "C-5",  "Sealed-Call Surface Match",        "TESTS/conformance/sealed_call_surface.III"},
    { 6, III_CG_CORE_LANGUAGE, "C-6",  "DRTM Quote Chain Verifiable",      "TESTS/conformance/drtm_chain_verify.III"},
    { 7, III_CG_CORE_LANGUAGE, "C-7",  "Closure-Pinned Imports",           "TESTS/conformance/closure_pin_drift.III"},
    { 8, III_CG_CORE_LANGUAGE, "C-8",  "Mobius Coherence Floor Maintained","TESTS/conformance/coherence_burnin.III"},
    { 9, III_CG_CORE_LANGUAGE, "C-9",  "Predictive Trinity Hot-Path Latency","BENCHES/predictive_trinity_latency.III"},
    {10, III_CG_CORE_LANGUAGE, "C-10", "Epistemic Escalation",             "TESTS/conformance/epistemic_escalation.III"},
    {11, III_CG_CORE_LANGUAGE, "C-11", "Ring-Gated Promotion",             "TESTS/conformance/ring_gated_promote.III"},
    {12, III_CG_CORE_LANGUAGE, "C-12", "Codegen Validation Before Deploy", "TESTS/conformance/codegen_validation.III"},
    {13, III_CG_CORE_LANGUAGE, "C-13", "Explicit Deployment Flags",        "TESTS/conformance/deployment_flags.III"},
    {14, III_CG_CORE_LANGUAGE, "C-14", "Ghost Effects + Witness Elision",  "TESTS/conformance/ghost_effects.III"},
    {15, III_CG_CORE_LANGUAGE, "C-15", "Catalyst: Witnessed/Federated/Reversible", "TESTS/conformance/catalyst_promote_replay.III"},
    /* Substrate C-16..C-25 */
    {16, III_CG_SUBSTRATE,     "C-16", "IRPD-Only Privileged Writes",      "TESTS/conformance/irpd_only.III"},
    {17, III_CG_SUBSTRATE,     "C-17", "Witness Continuity Across Rings",  "TESTS/conformance/witness_continuity.III"},
    {18, III_CG_SUBSTRATE,     "C-18", "Three-Layer Ceiling Never Bypassed","TESTS/conformance/three_layer_always.III"},
    {19, III_CG_SUBSTRATE,     "C-19", "Linear Capabilities Glyph-Bound",  "TESTS/conformance/cap_linearity.III"},
    {20, III_CG_SUBSTRATE,     "C-20", "Inverse Rings Consistent",         "TESTS/conformance/inverse_ring_consistency.III"},
    {21, III_CG_SUBSTRATE,     "C-21", "OBSERVATORY Saturation Respected", "TESTS/conformance/observatory_saturation.III"},
    {22, III_CG_SUBSTRATE,     "C-22", "Phoenix Bookmark Round-Trip",      "TESTS/conformance/phoenix_bookmark.III"},
    {23, III_CG_SUBSTRATE,     "C-23", "DRTM Epoch Advancement VDF",       "TESTS/conformance/drtm_vdf.III"},
    {24, III_CG_SUBSTRATE,     "C-24", "Sanctum Sealed Calls Trinity-Gated","TESTS/conformance/sanctum_trinity.III"},
    {25, III_CG_SUBSTRATE,     "C-25", "Self-Hosting Compiler Sealed-Call","TESTS/conformance/self_host_compile.III"},
    /* Cognitive C-26..C-30 */
    {26, III_CG_COGNITIVE,     "C-26", "Narrative Self Witnessed",         "TESTS/conformance/narrative_self.III"},
    {27, III_CG_COGNITIVE,     "C-27", "Cognitive Primitives First-Class", "TESTS/conformance/cognitive_primitives.III"},
    {28, III_CG_COGNITIVE,     "C-28", "Frontend Operates Without Module Knowledge","TESTS/conformance/frontend_opacity.III"},
    {29, III_CG_COGNITIVE,     "C-29", "User Actions Traceable",           "TESTS/conformance/user_action_traceability.III"},
    {30, III_CG_COGNITIVE,     "C-30", "Operator Zero-Knowledge",          "TESTS/conformance/operator_zero_knowledge.III"},
    /* Resolution C-31..C-33 (FROZEN SPEC III-RES-FROZEN-001 §14; ADR-RES-011 / ADR-RES-006) */
    {31, III_CG_RESOLUTION,    "C-31", "Resolution Determinism",           "TESTS/conformance/resolution_determinism.III"},
    {32, III_CG_RESOLUTION,    "C-32", "Pattern Compilation",              "TESTS/conformance/pattern_compilation.III"},
    {33, III_CG_RESOLUTION,    "C-33", "Transform Pattern Equivalence Proof","TESTS/conformance/transform_pattern_equivalence.III"}
};

const iii_conf_criterion_t *iii_conf_criterion_at(unsigned idx) {
    return (idx < III_CONF_COUNT) ? &kCriteria[idx] : NULL;
}

const iii_conf_criterion_t *iii_conf_criterion_lookup(const char *code) {
    if (!code) return NULL;
    for (unsigned i = 0; i < III_CONF_COUNT; ++i) {
        if (strcmp(kCriteria[i].code, code) == 0) return &kCriteria[i];
    }
    return NULL;
}

/* ----------------------------------------------------------------------------
 * Verifier
 * ---------------------------------------------------------------------------- */
typedef struct iii_conf_test_binding {
    iii_conf_test_fn fn;
    void            *user;
    bool             bound;
} iii_conf_test_binding_t;

struct iii_conf_verifier {
    iii_conf_test_binding_t bindings[III_CONF_COUNT];
    uint8_t                  pin[32];
    bool                     pin_set;
};

iii_conf_verifier_t *iii_conf_verifier_create(void) {
    return (iii_conf_verifier_t *)calloc(1, sizeof(iii_conf_verifier_t));
}
void iii_conf_verifier_destroy(iii_conf_verifier_t *v) { if (v) free(v); }

bool iii_conf_bind_test(iii_conf_verifier_t *v, const char *code,
                        iii_conf_test_fn fn, void *user)
{
    if (!v || !code || !fn) return false;
    const iii_conf_criterion_t *c = iii_conf_criterion_lookup(code);
    if (!c) return false;
    unsigned idx = c->number - 1u;
    if (v->bindings[idx].bound) return false;
    v->bindings[idx].fn = fn;
    v->bindings[idx].user = user;
    v->bindings[idx].bound = true;
    return true;
}

void iii_conf_run(iii_conf_verifier_t *v, iii_conf_result_t *out) {
    if (!v || !out) return;
    memset(out, 0, sizeof(*out));
    for (unsigned i = 0; i < III_CONF_COUNT; ++i) {
        if (!v->bindings[i].bound) {
            out->status[i] = III_CR_SKIP;
            out->skipped++;
        } else {
            int rc = v->bindings[i].fn(v->bindings[i].user);
            out->status[i] = (rc == 0) ? III_CR_PASS : III_CR_FAIL;
            if (rc == 0) out->passed++;
            else         out->failed++;
        }
    }
    /* Compliance percentage: passed / (passed + failed); skip excluded. */
    unsigned active = out->passed + out->failed;
    if (active == 0) out->compliance_q14 = 0;
    else out->compliance_q14 = (uint16_t)((out->passed * 16384u) / active);
}

void iii_conf_verifier_set_pin(iii_conf_verifier_t *v, const uint8_t pin[32]) {
    if (!v || !pin) return;
    memcpy(v->pin, pin, 32);
    v->pin_set = true;
}

bool iii_conf_verifier_check_pin(const iii_conf_verifier_t *v, const uint8_t expected[32]) {
    if (!v || !v->pin_set || !expected) return false;
    return memcmp(v->pin, expected, 32) == 0;
}

size_t iii_conf_format_result(const iii_conf_result_t *r, char *out, size_t cap) {
    if (!r || !out || cap == 0) return 0;
    int n = snprintf(out, cap,
        "passed=%u failed=%u skipped=%u compliance_q14=%u/%u\n",
        r->passed, r->failed, r->skipped, r->compliance_q14, 16384u);
    return (n > 0) ? (size_t)n : 0u;
}
