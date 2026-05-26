/* ============================================================================
 * III-PHASES — test_phases.c
 *
 * Unit tests exercising every public-API surface in the PHASES module:
 *   §1 ring lattice and phase-set bitmaps
 *   §2 phase polymorphism and synthesis
 *   §3 cross-ring constructor lookup
 *   §4 marshalling rules (all five)
 *   §5 dynamic phase promotion + rate cap
 *   §6 phase.current()
 *   §7 ghost phases
 *   §8 predictive phase specialisation
 *   SHA-256 against the standard test vectors
 *
 * No external test framework — each test asserts via the TEST() macro and
 * counts passes/failures.  Exit code 0 = all pass, 1 = any fail.
 * ============================================================================
 */
#include "iii/phases.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int  g_passed  = 0;
static int  g_failed  = 0;
static char g_section[64];

#define SECTION(name) do { snprintf(g_section, sizeof(g_section), "%s", (name)); \
    fprintf(stdout, "\n[%s]\n", g_section); } while (0)

#define TEST(cond) do {                                                    \
    if (cond) {                                                            \
        g_passed++;                                                        \
        fprintf(stdout, "  PASS  %s\n", #cond);                            \
    } else {                                                               \
        g_failed++;                                                        \
        fprintf(stdout, "  FAIL  %s  @ %s:%d\n", #cond, __FILE__, __LINE__);\
    }                                                                      \
} while (0)

/* SHA-256 from mhash.c — exposed via extern for testing. */
void iii_phases_sha256(const void *data, size_t len, uint8_t out[32]);

/* ----------------------------------------------------------------------------
 * §1. Ring lattice and phase-set bitmaps
 * ---------------------------------------------------------------------------- */

static void test_lattice(void) {
    SECTION("§1 lattice");

    /* Lattice order */
    TEST(iii_phase_leq(III_RING_SANCTUM, III_RING_USER));
    TEST(iii_phase_leq(III_RING_KERNEL,  III_RING_USER));
    TEST(!iii_phase_leq(III_RING_USER,   III_RING_SANCTUM));
    TEST(iii_phase_leq(III_RING_KERNEL,  III_RING_KERNEL));   /* reflexive */

    TEST(iii_phase_lt(III_RING_HYPERVISOR, III_RING_KERNEL));
    TEST(!iii_phase_lt(III_RING_KERNEL,    III_RING_KERNEL));

    /* Meet / join */
    TEST(iii_phase_meet(III_RING_KERNEL, III_RING_USER) == III_RING_KERNEL);
    TEST(iii_phase_join(III_RING_KERNEL, III_RING_USER) == III_RING_USER);
    TEST(iii_phase_meet(III_RING_SANCTUM, III_RING_KERNEL) == III_RING_SANCTUM);
    TEST(iii_phase_join(III_RING_SANCTUM, III_RING_KERNEL) == III_RING_KERNEL);

    /* Adjacency */
    TEST(iii_phase_adjacent(III_RING_SANCTUM, III_RING_HYPERVISOR));
    TEST(iii_phase_adjacent(III_RING_KERNEL,  III_RING_USER));
    TEST(!iii_phase_adjacent(III_RING_SANCTUM, III_RING_USER));

    /* Names */
    TEST(strcmp(iii_phase_ring_name(III_RING_SANCTUM),    "R-2") == 0);
    TEST(strcmp(iii_phase_ring_name(III_RING_HYPERVISOR), "R-1") == 0);
    TEST(strcmp(iii_phase_ring_name(III_RING_KERNEL),     "R0")  == 0);
    TEST(strcmp(iii_phase_ring_name(III_RING_USER),       "R3")  == 0);

    TEST(strcmp(iii_phase_ring_long_name(III_RING_SANCTUM), "Sanctum") == 0);
}

static void test_phase_sets(void) {
    SECTION("§1 phase-set bitmaps");

    iii_phase_set_t s = III_PHASE_SET_EMPTY;
    TEST(iii_phase_set_is_empty(s));
    TEST(iii_phase_set_cardinality(s) == 0);

    s = iii_phase_set_singleton(III_RING_KERNEL);
    TEST(iii_phase_set_contains(s, III_RING_KERNEL));
    TEST(!iii_phase_set_contains(s, III_RING_USER));
    TEST(iii_phase_set_cardinality(s) == 1);

    s = iii_phase_set_pair(III_RING_KERNEL, III_RING_USER);
    TEST(iii_phase_set_cardinality(s) == 2);
    TEST(iii_phase_set_min(s) == III_RING_KERNEL);
    TEST(iii_phase_set_max(s) == III_RING_USER);

    s = iii_phase_set_add(s, III_RING_HYPERVISOR);
    TEST(iii_phase_set_cardinality(s) == 3);
    TEST(iii_phase_set_min(s) == III_RING_HYPERVISOR);

    s = iii_phase_set_add(s, III_RING_SANCTUM);
    TEST(iii_phase_set_equal(s, III_PHASE_SET_ALL));
    TEST(iii_phase_set_cardinality(s) == 4);

    /* Subset */
    iii_phase_set_t a = iii_phase_set_pair(III_RING_KERNEL, III_RING_USER);
    iii_phase_set_t b = III_PHASE_SET_ALL;
    TEST(iii_phase_set_subset(a, b));
    TEST(!iii_phase_set_subset(b, a));

    /* Difference */
    iii_phase_set_t d = iii_phase_set_difference(b, a);
    TEST(iii_phase_set_contains(d, III_RING_SANCTUM));
    TEST(iii_phase_set_contains(d, III_RING_HYPERVISOR));
    TEST(!iii_phase_set_contains(d, III_RING_KERNEL));

    /* Format */
    char buf[64];
    iii_phase_set_format(III_PHASE_SET_ALL, buf, sizeof(buf));
    TEST(strcmp(buf, "{R-2,R-1,R0,R3}") == 0);

    iii_phase_set_format(III_PHASE_SET_EMPTY, buf, sizeof(buf));
    TEST(strcmp(buf, "{}") == 0);
}

/* ----------------------------------------------------------------------------
 * §3. Cross-ring constructor lookup
 * ---------------------------------------------------------------------------- */

static void test_constructors(void) {
    SECTION("§3 constructors");

    TEST(iii_phase_constructor_for(III_RING_USER,       III_RING_KERNEL)     == III_XR_IOCTL);
    TEST(iii_phase_constructor_for(III_RING_KERNEL,     III_RING_USER)       == III_XR_IOCTL);
    TEST(iii_phase_constructor_for(III_RING_USER,       III_RING_HYPERVISOR) == III_XR_MAGIC_MSR);
    TEST(iii_phase_constructor_for(III_RING_HYPERVISOR, III_RING_KERNEL)     == III_XR_VMRUN);
    TEST(iii_phase_constructor_for(III_RING_HYPERVISOR, III_RING_SANCTUM)    == III_XR_SANCTUM_GATE);

    /* Indirect — no direct constructor between R3 and R-2. */
    TEST(iii_phase_constructor_for(III_RING_USER, III_RING_SANCTUM) == III_XR_NONE);
    TEST(iii_phase_constructor_for(III_RING_KERNEL, III_RING_SANCTUM) == III_XR_NONE);

    /* Self-edge */
    TEST(iii_phase_constructor_for(III_RING_KERNEL, III_RING_KERNEL) == III_XR_NONE);

    /* Chain length */
    TEST(iii_phase_chain_length(III_RING_KERNEL, III_RING_KERNEL) == 0);
    TEST(iii_phase_chain_length(III_RING_USER, III_RING_KERNEL) == 1);
    TEST(iii_phase_chain_length(III_RING_USER, III_RING_SANCTUM) == 2);

    /* Next hop */
    TEST(iii_phase_next_hop(III_RING_USER, III_RING_SANCTUM) == III_RING_HYPERVISOR);
    TEST(iii_phase_next_hop(III_RING_KERNEL, III_RING_SANCTUM) == III_RING_HYPERVISOR);
    TEST(iii_phase_next_hop(III_RING_USER, III_RING_KERNEL) == III_RING_KERNEL);
}

/* ----------------------------------------------------------------------------
 * §2. Phase polymorphism and synthesis
 * ---------------------------------------------------------------------------- */

static void test_phase_poly(void) {
    SECTION("§2 phase polymorphism");

    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    TEST(rt != NULL);

    iii_phase_cycle_t *c = iii_phase_runtime_register_cycle(rt, "read_msr", III_PHASE_SET_ALL);
    TEST(c != NULL);
    TEST(iii_phase_set_cardinality(c->declared_phases) == 4);

    /* Single explicit body at R-1; the other three should synthesise. */
    TEST(iii_phase_cycle_add_body(c, III_RING_HYPERVISOR, 0xCAFEBABEu, XII_STEP_KIND_IRPD_MSR_READ));

    /* Validate fails before synthesis (only one ring covered out of four). */
    TEST(!iii_phase_cycle_validate(c));

    int s = iii_phase_cycle_synthesize(c);
    TEST(s == 3);

    TEST(iii_phase_cycle_validate(c));
    TEST(iii_phase_cycle_seal(c));
    TEST(c->sealed);

    /* Adding a body after sealing must fail. */
    TEST(!iii_phase_cycle_add_body(c, III_RING_KERNEL, 0xDEADBEEFu, XII_STEP_KIND_R0_MSR_READ));

    /* Lookup */
    iii_phase_lowering_t *lw = iii_phase_cycle_lowering(c, III_RING_KERNEL);
    TEST(lw != NULL && lw->synthesized);

    iii_phase_lowering_t *lwh = iii_phase_cycle_lowering(c, III_RING_HYPERVISOR);
    TEST(lwh != NULL && lwh->explicit_body && !lwh->synthesized);

    /* Ghost-phase mark */
    TEST(iii_phase_cycle_mark_ghost(c, iii_phase_set_singleton(III_RING_USER)) == false); /* sealed */

    iii_phase_runtime_destroy(rt);
}

/* ----------------------------------------------------------------------------
 * §4. Marshalling rules
 * ---------------------------------------------------------------------------- */

static void test_marshalling(void) {
    SECTION("§4 marshalling");

    iii_phase_marshal_t m;
    memset(&m, 0, sizeof(m));

    /* Direct R3 -> R0 (IOCTL) — should pass. */
    m.src = III_RING_USER;
    m.dst = III_RING_KERNEL;
    m.constructor = III_XR_NONE; /* runtime fills */
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_OK);

    /* Indirect R3 -> R-2 — must fail (no direct constructor). */
    m.src = III_RING_USER;
    m.dst = III_RING_SANCTUM;
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_ERR_NO_CONSTRUCTOR);

    /* Glyph drift */
    m.src = III_RING_USER;
    m.dst = III_RING_KERNEL;
    m.glyph_bound = true;
    memset(m.src_glyph_mhash, 0xAA, 32);
    memset(m.dst_glyph_mhash, 0xBB, 32);
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_ERR_GLYPH_DRIFT);

    /* Glyph match */
    memset(m.dst_glyph_mhash, 0xAA, 32);
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_OK);

    /* Asymmetric (one zero, one set) */
    memset(m.src_glyph_mhash, 0xAA, 32);
    memset(m.dst_glyph_mhash, 0,    32);
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_ERR_GLYPH_DRIFT);

    /* Disable glyph binding for further tests */
    memset(&m, 0, sizeof(m));
    m.src = III_RING_USER;
    m.dst = III_RING_KERNEL;

    /* Uncertainty: high uncertainty crossing into a more privileged ring,
     * no operator confirmation -> reject. */
    m.uncertainty_present = true;
    m.confidence_q12      = 2000u;  /* 0.488 */
    m.operator_confirmed  = false;
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_ERR_UNCERTAINTY);

    /* Operator confirms -> ok */
    m.operator_confirmed  = true;
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_OK);

    /* High confidence -> no gating */
    m.confidence_q12      = 4000u;  /* 0.977 */
    m.operator_confirmed  = false;
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_OK);

    /* Coherence */
    memset(&m, 0, sizeof(m));
    m.src = III_RING_USER;
    m.dst = III_RING_KERNEL;
    m.required_coherence_q12 = 3000u;
    m.current_coherence_q12  = 1000u;
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_ERR_COHERENCE);

    m.current_coherence_q12  = 3500u;
    TEST(iii_phase_marshal_check(&m) == III_PHASE_MARSHAL_OK);

    /* Apply: emits successor mhash deterministically. */
    memset(&m, 0, sizeof(m));
    m.src = III_RING_USER;
    m.dst = III_RING_KERNEL;
    memset(m.predecessor_mhash, 0x42, 32);
    TEST(iii_phase_marshal_apply(&m) == III_PHASE_MARSHAL_OK);
    /* successor must differ from predecessor */
    TEST(memcmp(m.predecessor_mhash, m.successor_mhash, 32) != 0);
    /* same input -> same output (deterministic) */
    iii_phase_marshal_t m2 = m;
    iii_phase_marshal_apply(&m2);
    TEST(memcmp(m.successor_mhash, m2.successor_mhash, 32) == 0);

    /* Inverse */
    iii_phase_marshal_t inv;
    iii_phase_marshal_inverse(&m, &inv);
    TEST(inv.src == III_RING_KERNEL);
    TEST(inv.dst == III_RING_USER);
    TEST(memcmp(inv.predecessor_mhash, m.successor_mhash, 32) == 0);
}

/* ----------------------------------------------------------------------------
 * §5. Dynamic phase promotion
 * ---------------------------------------------------------------------------- */

static void test_promotion(void) {
    SECTION("§5 promotion");

    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    iii_phase_cycle_t *c = iii_phase_runtime_register_cycle(rt, "adaptive",
                                iii_phase_set_singleton(III_RING_USER));
    iii_phase_cycle_add_body(c, III_RING_USER, 0x1u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_seal(c);

    iii_phase_promote_request_t req;
    memset(&req, 0, sizeof(req));
    req.cycle                       = c;
    req.target_ring                 = III_RING_KERNEL;
    req.hot                         = true;
    req.invocation_frequency        = 1024;
    req.hexad_admissible_at_target  = true;
    req.trinity_discharged          = true;
    req.coherence_q12               = 4000u;
    req.coherence_floor_q12         = 2000u;

    /* Fails: cycle not marked candidate */
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_ERR_NOT_CANDIDATE);

    iii_phase_cycle_mark_candidate(c);

    /* Succeeds */
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_OK);
    TEST(iii_phase_set_contains(c->declared_phases, III_RING_KERNEL));

    /* Already at ring */
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_ERR_ALREADY_AT_RING);

    /* Coherence below floor */
    req.target_ring        = III_RING_HYPERVISOR;
    req.coherence_q12      = 100u;
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_ERR_COHERENCE);

    /* Trinity reject */
    req.coherence_q12      = 4000u;
    req.trinity_discharged = false;
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_ERR_TRINITY_REJECT);

    /* Hexad reject */
    req.trinity_discharged          = true;
    req.hexad_admissible_at_target  = false;
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_ERR_HEXAD_REJECT);

    /* Rate cap: keep promoting different cycles until cap exceeded */
    req.hexad_admissible_at_target = true;
    req.target_ring                = III_RING_HYPERVISOR;

    /* Already at 1 promotion this tick. */
    TEST(iii_phase_runtime_promote_count_this_tick(rt) == 1u);
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_OK);  /* 2 */
    /* Need new cycles for the next promotions to avoid ALREADY_AT_RING. */
    iii_phase_cycle_t *c2 = iii_phase_runtime_register_cycle(rt, "x2",
                                iii_phase_set_singleton(III_RING_USER));
    iii_phase_cycle_add_body(c2, III_RING_USER, 0x2u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_mark_candidate(c2);
    iii_phase_cycle_seal(c2);
    req.cycle = c2;
    req.target_ring = III_RING_KERNEL;
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_OK);  /* 3 */

    iii_phase_cycle_t *c3 = iii_phase_runtime_register_cycle(rt, "x3",
                                iii_phase_set_singleton(III_RING_USER));
    iii_phase_cycle_add_body(c3, III_RING_USER, 0x3u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_mark_candidate(c3);
    iii_phase_cycle_seal(c3);
    req.cycle = c3;
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_OK);  /* 4 */

    iii_phase_cycle_t *c4 = iii_phase_runtime_register_cycle(rt, "x4",
                                iii_phase_set_singleton(III_RING_USER));
    iii_phase_cycle_add_body(c4, III_RING_USER, 0x4u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_mark_candidate(c4);
    iii_phase_cycle_seal(c4);
    req.cycle = c4;
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_ERR_RATE_CAP);

    /* New tick resets the cap */
    iii_phase_runtime_tick(rt);
    TEST(iii_phase_runtime_promote(rt, &req) == III_PHASE_PROMOTE_OK);

    /* Demote */
    TEST(iii_phase_runtime_demote(rt, c4, III_RING_KERNEL) == III_PHASE_PROMOTE_OK);
    TEST(!iii_phase_set_contains(c4->declared_phases, III_RING_KERNEL));

    iii_phase_runtime_destroy(rt);
}

/* ----------------------------------------------------------------------------
 * §6. Epistemic phases
 * ---------------------------------------------------------------------------- */

static void test_epistemic(void) {
    SECTION("§6 phase.current()");

    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    TEST(iii_phase_runtime_current(rt) == III_RING_USER);

    iii_phase_runtime_set_current(rt, III_RING_HYPERVISOR);
    TEST(iii_phase_runtime_current(rt) == III_RING_HYPERVISOR);

    iii_phase_runtime_set_current(rt, III_RING_SANCTUM);
    TEST(iii_phase_runtime_current(rt) == III_RING_SANCTUM);

    iii_phase_runtime_destroy(rt);
}

/* ----------------------------------------------------------------------------
 * §7. Ghost phases
 * ---------------------------------------------------------------------------- */

static void test_ghost(void) {
    SECTION("§7 ghost");

    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    iii_phase_cycle_t *c = iii_phase_runtime_register_cycle(rt, "audit_only",
                                iii_phase_set_pair(III_RING_USER, III_RING_KERNEL));
    iii_phase_cycle_add_body(c, III_RING_USER,   0x1u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_add_body(c, III_RING_KERNEL, 0x2u, XII_STEP_KIND_R0_MSR_READ);
    iii_phase_cycle_mark_ghost(c, iii_phase_set_singleton(III_RING_USER));
    iii_phase_cycle_seal(c);

    uint8_t pred[32];
    for (unsigned i = 0; i < 32; ++i) pred[i] = (uint8_t)i;

    iii_phase_ghost_witness_t gw;
    TEST(iii_phase_runtime_ghost_observe(rt, c, III_RING_USER, pred, &gw));
    TEST(gw.cycle_id == c->cycle_id);
    TEST(gw.ring == III_RING_USER);
    TEST(gw.step_kind == XII_STEP_KIND_GHOST_OBSERVE);

    /* Cannot observe at a ring not declared */
    TEST(!iii_phase_runtime_ghost_observe(rt, c, III_RING_SANCTUM, pred, &gw));

    iii_phase_runtime_destroy(rt);
}

/* ----------------------------------------------------------------------------
 * §8. Predictive phase specialisation
 * ---------------------------------------------------------------------------- */

static void test_predictive(void) {
    SECTION("§8 predictive");

    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    iii_phase_cycle_t *c = iii_phase_runtime_register_cycle(rt, "hot_cycle",
                                iii_phase_set_pair(III_RING_USER, III_RING_KERNEL));
    iii_phase_cycle_add_body(c, III_RING_USER,   0x1u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_add_body(c, III_RING_KERNEL, 0x2u, XII_STEP_KIND_R0_MSR_READ);
    iii_phase_cycle_seal(c);

    iii_phase_ring_t hot;
    /* Not enough invocations yet */
    TEST(!iii_phase_cycle_hottest_ring(c, &hot));

    /* Drive 100 invocations, 90 at R0, 10 at R3 — R0 should win. */
    for (unsigned i = 0; i < 90; ++i) iii_phase_runtime_observe_invocation(rt, c, III_RING_KERNEL);
    for (unsigned i = 0; i < 10; ++i) iii_phase_runtime_observe_invocation(rt, c, III_RING_USER);

    TEST(iii_phase_cycle_hottest_ring(c, &hot));
    TEST(hot == III_RING_KERNEL);

    /* Specialise */
    TEST(iii_phase_runtime_specialize(rt, c, III_RING_KERNEL) == III_PHASE_SPECIALIZE_OK);
    TEST(c->specialized_ring == III_RING_KERNEL);
    /* Already specialised */
    TEST(iii_phase_runtime_specialize(rt, c, III_RING_KERNEL) == III_PHASE_SPECIALIZE_ALREADY);

    /* Despecialise */
    TEST(iii_phase_runtime_despecialize(rt, c) == III_PHASE_SPECIALIZE_OK);
    TEST(c->specialized_ring == III_RING_COUNT);
    TEST(iii_phase_runtime_despecialize(rt, c) == III_PHASE_SPECIALIZE_ERR_NO_HOT_RING);

    iii_phase_runtime_destroy(rt);
}

/* ----------------------------------------------------------------------------
 * Witness ring + count
 * ---------------------------------------------------------------------------- */

static void test_witnesses(void) {
    SECTION("witnesses");

    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    iii_phase_cycle_t *c = iii_phase_runtime_register_cycle(rt, "w",
                                iii_phase_set_pair(III_RING_USER, III_RING_KERNEL));
    iii_phase_cycle_add_body(c, III_RING_USER,   0x1u, XII_STEP_KIND_R3_MAGIC_MSR_READ);
    iii_phase_cycle_add_body(c, III_RING_KERNEL, 0x2u, XII_STEP_KIND_R0_MSR_READ);
    iii_phase_cycle_mark_candidate(c);
    iii_phase_cycle_seal(c);

    uint64_t before = iii_phase_runtime_witness_count(rt);

    iii_phase_promote_request_t req;
    memset(&req, 0, sizeof(req));
    req.cycle                       = c;
    req.target_ring                 = III_RING_HYPERVISOR;
    req.hexad_admissible_at_target  = true;
    req.trinity_discharged          = true;
    req.coherence_q12               = 4000u;
    iii_phase_runtime_promote(rt, &req);

    uint64_t after = iii_phase_runtime_witness_count(rt);
    TEST(after == before + 1u);

    iii_phase_witness_t w;
    TEST(iii_phase_runtime_witness_at(rt, after, &w));
    TEST(w.step_kind == XII_STEP_KIND_PHASE_PROMOTE);
    TEST(w.cycle_id == c->cycle_id);

    iii_phase_runtime_destroy(rt);
}

/* ----------------------------------------------------------------------------
 * SHA-256 against the FIPS test vectors
 * ---------------------------------------------------------------------------- */

static int hex_eq(const uint8_t hash[32], const char *hex) {
    static const char *digits = "0123456789abcdef";
    for (unsigned i = 0; i < 32; ++i) {
        unsigned hi = (unsigned)(hash[i] >> 4);
        unsigned lo = (unsigned)(hash[i] & 0x0Fu);
        if (hex[2*i + 0] != digits[hi]) return 0;
        if (hex[2*i + 1] != digits[lo]) return 0;
    }
    return 1;
}

static void test_sha256(void) {
    SECTION("SHA-256 vectors");

    uint8_t h[32];

    iii_phases_sha256("", 0, h);
    TEST(hex_eq(h, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));

    iii_phases_sha256("abc", 3, h);
    TEST(hex_eq(h, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"));

    iii_phases_sha256("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56, h);
    TEST(hex_eq(h, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"));

    /* Long input — 1,000,000 'a' characters per FIPS-180-4 example. */
    char *big = (char *)malloc(1000000);
    if (big) {
        memset(big, 'a', 1000000);
        iii_phases_sha256(big, 1000000, h);
        TEST(hex_eq(h, "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"));
        free(big);
    }
}

/* ----------------------------------------------------------------------------
 * main
 * ---------------------------------------------------------------------------- */

int main(void) {
    test_lattice();
    test_phase_sets();
    test_constructors();
    test_phase_poly();
    test_marshalling();
    test_promotion();
    test_epistemic();
    test_ghost();
    test_predictive();
    test_witnesses();
    test_sha256();

    fprintf(stdout, "\n=== %d passed, %d failed ===\n", g_passed, g_failed);
    return g_failed == 0 ? 0 : 1;
}
