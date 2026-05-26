/* III TYPES — test runner.  ≥ 30 tests covering every spec section. */
#include "iii/types.h"
#include "iii/types_term.h"
#include "iii/types_hexad.h"
#include "iii/types_errors.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;

#define CHECK(name, cond) do { \
    if (cond) { g_pass++; printf("  PASS  %s\n", name); } \
    else      { g_fail++; printf("  FAIL  %s  (%s:%d)\n", name, __FILE__, __LINE__); } \
} while (0)

/* ---- Universe (§2) ---- */
static void test_universe(void) {
    printf("[Universe §2]\n");
    CHECK("succ Type_0 = Type_1", iii_universe_succ(III_U_TYPE0) == III_U_TYPE1);
    CHECK("succ Prop = Type_0",   iii_universe_succ(III_U_PROP)  == III_U_TYPE0);
    CHECK("succ Type_6 = Type_6", iii_universe_succ(III_U_TYPE6) == III_U_TYPE6);
    CHECK("Pi predicative max",   iii_universe_pi(III_U_TYPE2, III_U_TYPE3) == III_U_TYPE3);
    CHECK("Pi impredicative top", iii_universe_pi(III_U_TYPE4, III_U_TYPE6) == III_U_TYPE6);
    CHECK("Prop lift to Type_0",  iii_universe_lift_allowed(III_U_PROP, III_U_TYPE0));
    CHECK("no implicit cumulativity",
          !iii_universe_lift_allowed(III_U_TYPE1, III_U_TYPE2));
}

/* ---- Hexad (§4) ---- */
static void test_hexad(void) {
    printf("[Hexad §4]\n");
    iii_hexad_t h = { { III_TRIT_POS, III_TRIT_NEG, III_TRIT_ZERO,
                        III_TRIT_POS, III_TRIT_NEG, III_TRIT_ZERO } };
    uint16_t p = iii_hexad_pack(&h);
    iii_hexad_t back; iii_hexad_unpack(p, &back);
    CHECK("pack/unpack roundtrip", iii_hexad_eq(&h, &back));
    CHECK("ZERO is identity",
          iii_trit_compose(III_TRIT_POS, III_TRIT_ZERO) == III_TRIT_POS);
    CHECK("NEG dominates",
          iii_trit_compose(III_TRIT_POS, III_TRIT_NEG) == III_TRIT_NEG);
    iii_hexad_t neg = iii_hexad_neg(&h);
    iii_hexad_t neg2 = iii_hexad_neg(&neg);
    CHECK("neg involution", iii_hexad_eq(&h, &neg2));
    int unreach = 0;
    for (int b = 0; b < (int)III_BRICK__COUNT; ++b) {
        iii_hexad_t bh = iii_hexad_brick((iii_brick_t)b);
        if (!iii_hexad_admitted(&bh)) unreach++;
    }
    CHECK("all 6 bricking hexads forbidden", unreach == 6);
    uint8_t bmh1[32], bmh2[32];
    iii_hexad_bitmap_hash(bmh1);
    iii_hexad_bitmap_hash(bmh2);
    CHECK("bitmap hash deterministic", memcmp(bmh1, bmh2, 32) == 0);
}

/* ---- Reduction (§3) ---- */
static void test_reduction(void) {
    printf("[Reduction §3]\n");
    iii_type_env_t *e = iii_type_env_create();
    iii_type_t *F = iii_ty_prim(e, III_PRIM_I32);
    iii_type_t *I = iii_ty_prim(e, III_PRIM_I32);
    iii_hexad_t H = { { III_TRIT_ZERO, III_TRIT_POS, III_TRIT_POS,
                        III_TRIT_ZERO, III_TRIT_ZERO, III_TRIT_ZERO } };
    iii_phase_set_t P = { (1u << III_RING_R0) };
    iii_epoch_t E = { 1 };
    iii_type_t *r = iii_ty_reduction(e, F, I, H, P, E);
    CHECK("Reduction intro", r && r->kind == III_TY_REDUCTION);
    CHECK("Reduction at Type_6", r && iii_type_universe(r) == III_U_TYPE6);
    iii_type_t *fwd = iii_ty_reduction_proj(e, r, "forward");
    CHECK("proj forward", fwd == F);
    iii_type_t *inv = iii_ty_reduction_proj(e, r, "inverse");
    CHECK("proj inverse", inv == I);
    iii_type_t *bad = iii_ty_reduction_proj(e, r, "bogus");
    CHECK("proj unknown emits", bad == NULL);
    iii_type_t *r_inv = iii_ty_reduction_inverse(e, r);
    CHECK("inverse swaps F/I", r_inv && r_inv->r_forward == I && r_inv->r_inverse == F);
    iii_type_env_destroy(e);
}

/* ---- Ring (§5) ---- */
static void test_ring(void) {
    printf("[Ring §5]\n");
    iii_phase_set_t s = { (1u << III_RING_R0) | (1u << III_RING_R3) };
    CHECK("phase set valid", iii_phase_set_valid(s));
    iii_phase_set_t bad = { 0 };
    CHECK("empty set invalid", !iii_phase_set_valid(bad));
    CHECK("R3↔R0 marshals",
          iii_phase_marshal_exists(III_RING_R3, III_RING_R0));
    CHECK("R3↔R-2 forbidden",
          !iii_phase_marshal_exists(III_RING_R3, III_RING_R_MINUS_2));
}

/* ---- Tier/Epoch (§6) ---- */
static void test_tier_epoch(void) {
    printf("[Tier/Epoch §6]\n");
    CHECK("tier max", iii_tier_max(III_TIER_TRANSIENT, III_TIER_FEDERATION) == III_TIER_FEDERATION);
    iii_type_env_t *e = iii_type_env_create();
    iii_type_env_set_current_epoch(e, 5);
    iii_type_t *inner = iii_ty_prim(e, III_PRIM_I32);
    iii_epoch_t e1 = {3}, e2 = {4};
    iii_type_t *a = iii_ty_epoch_tag(e, inner, e1);
    iii_type_t *b = iii_ty_epoch_tag(e, inner, e2);
    iii_type_t *bridge_no = iii_ty_epoch_bridge(e, a, b, false);
    CHECK("cross-epoch needs @epoch_bridge", bridge_no == NULL);
    iii_type_t *bridge_yes = iii_ty_epoch_bridge(e, a, b, true);
    CHECK("epoch bridge with attribute OK", bridge_yes != NULL);
    iii_type_env_destroy(e);
}

/* ---- Capability (§7) ---- */
static void test_capability(void) {
    printf("[Capability §7]\n");
    iii_type_env_t *e = iii_type_env_create();
    iii_type_t *cap = iii_ty_cap(e, III_CAP_WRITE, 42);
    CHECK("cap at Type_4", cap && iii_type_universe(cap) == III_U_TYPE4);
    iii_type_env_bind_linear(e, 100, cap);
    CHECK("first use OK", iii_ty_linear_use(e, 100) != NULL);
    size_t before = iii_type_env_diag_count(e);
    (void)iii_ty_linear_use(e, 100);
    CHECK("second use emits TYPE-LIN-001",
          iii_type_env_diag_count(e) > before &&
          iii_type_env_diag_at(e, before)->code == TYPE_LIN_001_USED_TWICE);
    iii_type_env_destroy(e);

    iii_type_env_t *e2 = iii_type_env_create();
    iii_type_t *cap2 = iii_ty_cap(e2, III_CAP_READ, 7);
    iii_type_env_bind_linear(e2, 200, cap2);
    int errs = iii_type_env_check_linear_complete(e2);
    CHECK("dropped-unused detected", errs > 0);
    iii_type_env_destroy(e2);
}

/* ---- Epistemic (§8) ---- */
static void test_epistemic(void) {
    printf("[Epistemic §8]\n");
    iii_uncertainty_t a = {1, 16384, 0};
    iii_uncertainty_t b = {1, 8192,  2};
    iii_uncertainty_t c = iii_uncertainty_combine(a, b);
    CHECK("combine confidence q14 product", c.confidence_q14 == 8192);
    CHECK("combine question count adds",    c.question_count == 2);
}

/* ---- Constitutional (§9) ---- */
static void test_constitutional(void) {
    printf("[Constitutional §9]\n");
    iii_type_env_t *e = iii_type_env_create();
    iii_type_t *p1 = iii_ty_prop(e, III_PROP_CEILING_MEMBERSHIP);
    iii_type_t *p2 = iii_ty_prop(e, III_PROP_MOBIUS_COHERENCE);
    iii_type_t *p3 = iii_ty_prop(e, III_PROP_TRINITY_ADMIT);
    CHECK("ceiling : Prop", p1 && iii_type_universe(p1) == III_U_PROP);
    CHECK("möbius : Prop", p2 && iii_type_universe(p2) == III_U_PROP);
    CHECK("trinity : Prop", p3 && iii_type_universe(p3) == III_U_PROP);
    iii_type_env_destroy(e);
}

/* ---- Bidirectional (§10) ---- */
static void test_bidir(void) {
    printf("[Bidirectional §10]\n");
    iii_type_env_t *e = iii_type_env_create();
    iii_type_t *h = iii_ty_hole(e, III_U_TYPE0);
    CHECK("hole created", h && h->kind == III_TY_HOLE);
    /* Unsolved hole should be reported. */
    int u = iii_holes_solve(e);
    CHECK("unresolved hole counted", u == 1);
    iii_type_env_destroy(e);

    iii_type_env_t *e2 = iii_type_env_create();
    iii_type_t *h2 = iii_ty_hole(e2, III_U_TYPE0);
    h2->hole_solution = iii_ty_prim(e2, III_PRIM_I32);
    int u2 = iii_holes_solve(e2);
    CHECK("solved hole not reported", u2 == 0);
    iii_type_env_destroy(e2);
}

/* ---- CIC kernel (§11) ---- */
static void test_cic(void) {
    printf("[CIC §11]\n");
    iii_term_kernel_t *k = iii_term_kernel_create();
    /* λ x:Type_0. x — should type-check at Π Type_0. Type_0 */
    iii_term_t *T0 = iii_tm_sort(k, III_SORT_TYPE0);
    iii_term_t *idf = iii_tm_lam(k, "x", T0, iii_tm_var(k, 0));
    iii_term_t *out_ty = NULL;
    int rc = iii_term_typeof(k, NULL, 0, idf, &out_ty);
    CHECK("identity typecheks", rc == 0 && out_ty && out_ty->kind == III_TM_PI);

    /* β-step:  (λ x:Type_0. x) Type_0  →  Type_0  */
    iii_term_t *app = iii_tm_app(k, idf, T0);
    iii_term_t *step = iii_term_whreduce(k, app);
    CHECK("β step", step != NULL);

    /* ι on Bool: match true with ... */
    iii_term_t *btrue  = iii_tm_ctor(k, III_IND_BOOL, 0, NULL, 0);
    iii_term_t *armT   = iii_tm_sort(k, III_SORT_TYPE0);
    iii_term_t *armF   = iii_tm_sort(k, III_SORT_PROP);
    iii_term_t *arms[2] = { armT, armF };
    iii_term_t *m = iii_tm_match(k, III_IND_BOOL, btrue, T0, arms, 2);
    iii_term_t *m_step = iii_term_whreduce(k, m);
    CHECK("ι step on true", m_step == armT);

    /* convertibility identical terms */
    CHECK("convertible self", iii_term_convertible(k, idf, idf));

    /* Hexad literal lifts. */
    iii_term_t *hx = iii_tm_hexad(k, 364u);
    CHECK("hexad literal", hx && hx->kind == III_TM_HEXAD);

    iii_term_kernel_destroy(k);
}

/* ---- CIC bricking-as-type-error (§11 / H6 mig2) ---- */
static void test_cic_bricking(void) {
    printf("[CIC bricking H6 §11/mig2]\n");
    iii_term_kernel_t *k = iii_term_kernel_create();
    /* A reachable hexad literal (364 = all-ZERO) type-checks to Hexad. */
    iii_term_t *good = iii_tm_hexad(k, 364u);
    iii_term_t *gty = NULL;
    int grc = iii_term_typeof(k, NULL, 0, good, &gty);
    CHECK("reachable hexad literal typechecks",
          grc == 0 && gty && gty->kind == III_TM_IND && gty->ind_id == III_IND_HEXAD);
    /* A bricking hexad literal is a TYPE ERROR (prove the negative). */
    iii_hexad_t brick = iii_hexad_brick(III_BRICK_CAPSULE_UPDATE);
    iii_term_t *bad = iii_tm_hexad(k, iii_hexad_pack(&brick));
    iii_term_t *bty = NULL;
    int brc = iii_term_typeof(k, NULL, 0, bad, &bty);
    CHECK("bricking hexad literal rejected (TYPE_HEXAD_005_BRICKING)",
          brc == (int)TYPE_HEXAD_005_BRICKING && bty == NULL);
    /* All six PFS bricks rejected by the kernel. */
    int rejected = 0;
    for (int b = 0; b < (int)III_BRICK__COUNT; ++b) {
        iii_hexad_t hb = iii_hexad_brick((iii_brick_t)b);
        iii_term_t *tb = iii_tm_hexad(k, iii_hexad_pack(&hb));
        iii_term_t *tty = NULL;
        if (iii_term_typeof(k, NULL, 0, tb, &tty) == (int)TYPE_HEXAD_005_BRICKING) rejected++;
    }
    CHECK("all 6 bricking hexad literals rejected", rejected == 6);
    /* Structural ctor path: a bricking hexad from six concrete trits is rejected too. */
    iii_hexad_t bw = iii_hexad_brick(III_BRICK_SMRAM_WRITE);
    iii_term_t *trits[6];
    for (int i = 0; i < 6; ++i) trits[i] = iii_tm_trit(k, bw.pillar[i]);
    iii_term_t *bctor = iii_tm_ctor(k, III_IND_HEXAD, 0, trits, 6);
    iii_term_t *cty = NULL;
    int crc = iii_term_typeof(k, NULL, 0, bctor, &cty);
    CHECK("bricking hexad ctor (6 trits) rejected",
          crc == (int)TYPE_HEXAD_005_BRICKING && cty == NULL);
    /* A reachable hexad ctor still type-checks (positive ctor arm). */
    iii_hexad_t okh; iii_hexad_unpack(364u, &okh);
    iii_term_t *otrits[6];
    for (int i = 0; i < 6; ++i) otrits[i] = iii_tm_trit(k, okh.pillar[i]);
    iii_term_t *octor = iii_tm_ctor(k, III_IND_HEXAD, 0, otrits, 6);
    iii_term_t *oty = NULL;
    int orc = iii_term_typeof(k, NULL, 0, octor, &oty);
    CHECK("reachable hexad ctor typechecks",
          orc == 0 && oty && oty->kind == III_TM_IND && oty->ind_id == III_IND_HEXAD);
    iii_term_kernel_destroy(k);
}

/* ---- Hexad-tag rule (§4.1) ---- */
static void test_hexad_tag(void) {
    printf("[Hexad-tag §4.1]\n");
    iii_type_env_t *e = iii_type_env_create();
    iii_type_t *inner = iii_ty_prim(e, III_PRIM_I32);
    iii_hexad_t H = { {III_TRIT_ZERO, III_TRIT_POS, III_TRIT_POS,
                       III_TRIT_ZERO, III_TRIT_ZERO, III_TRIT_ZERO} };
    iii_type_t *t = iii_ty_hexad_tag(e, inner, H);
    CHECK("hexad-tag admitted", t && t->kind == III_TY_HEXAD_TAG);
    iii_hexad_t brick = iii_hexad_brick(III_BRICK_CAPSULE_UPDATE);
    iii_type_t *bad = iii_ty_hexad_tag(e, inner, brick);
    CHECK("bricking hexad rejected", bad == NULL);
    iii_type_env_destroy(e);
}

/* ---- Module driver ---- */
static void test_module_driver(void) {
    printf("[Module driver §12]\n");
    iii_type_env_t *e = iii_type_env_create();
    /* Synthesize a minimal AST: a single LITERAL inside a MODULE. */
    iii_ast_node_t lit = { .kind = III_AST_LITERAL, .int_value = 42 };
    iii_ast_node_t *kids[1] = { &lit };
    iii_ast_node_t mod = { .kind = III_AST_MODULE, .children = kids, .child_count = 1 };
    iii_typed_module_t *m = iii_check_module(e, &mod);
    CHECK("module checked", m != NULL);
    iii_type_t *t = iii_typed_lookup(m, &lit);
    CHECK("literal annotated", t != NULL);
    free(m);
    iii_type_env_destroy(e);
}

/* ---- Proof (§11.3) ---- */
static void test_proof(void) {
    printf("[Proof §11.3]\n");
    iii_type_env_t *e = iii_type_env_create();
    iii_term_kernel_t *k = iii_type_env_kernel(e);
    iii_term_t *T = iii_tm_sort(k, III_SORT_TYPE0);
    iii_term_t *idf = iii_tm_lam(k, "x", T, iii_tm_var(k, 0));
    iii_term_t *idfTy = NULL;
    iii_term_typeof(k, NULL, 0, idf, &idfTy);
    uint16_t hexes[2] = { 364u, 365u };
    iii_proof_cert_t *c = iii_proof_cert_create(e, idf, idfTy, hexes, 2);
    CHECK("cert created", c != NULL);
    bool ok = iii_proof_verify(e, c);
    CHECK("cert verifies", ok);
    free(c->hexad_witnesses);
    free(c);
    iii_type_env_destroy(e);
}

/* ---- Errors module sanity ---- */
static void test_errors(void) {
    printf("[Errors]\n");
    CHECK("err name present",
          strstr(iii_type_err_code_name(TYPE_HEXAD_002_OUT_OF_REACH), "HEXAD") != NULL);
    CHECK("err message present",
          iii_type_err_code_message(TYPE_LIN_001_USED_TWICE)[0] != '\0');
}

int main(void) {
    test_universe();
    test_hexad();
    test_reduction();
    test_ring();
    test_tier_epoch();
    test_capability();
    test_epistemic();
    test_constitutional();
    test_bidir();
    test_cic();
    test_cic_bricking();
    test_hexad_tag();
    test_module_driver();
    test_proof();
    test_errors();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail ? 1 : 0;
}
