/* hexad_bricking_proof.c — exhaustive proof of bricking-by-construction.
 *
 * Proves, over all 729 x 729 = 531,441 hexad pairs, that under the SPEC's
 * single canonical compose (III-HEXAD.md 3.1: AND on structural pillars
 * P1..P4, OR on informational P5..P6) together with the SPEC's admission
 * rule (2.1: a hexad is admissible iff NO structural pillar P1..P4 is NEG):
 *
 *   (T1) admitted(a compose b) == admitted(a) AND admitted(b)   [no violations]
 *   (T2) all six PFS bricking patterns are non-admitted          [6/6 blocked]
 *   (T3) NO composition of two admitted hexads is ever a brick    [0 reachable]
 *
 * Together: bricking is STRUCTURALLY IMPOSSIBLE, not pattern-matched. AND on
 * the structural pillars makes NEG sticky (AND(NEG, .) = NEG, III-HEXAD.md
 * 1.3: "no amount of POS can restore it"), so a structural-NEG poisons the
 * result forever and can never be admitted.
 *
 * This is the canonical guard for FORWARD_REFERENCES #8.  It also documents
 * WHY the legacy "block 6 exact patterns" admission (compiler hexad_check.c +
 * TYPES hexad.c bitmap_init, which admit 723/729) is a bricking gap: it does
 * NOT enforce the structural rule and admits 717 structural-NEG hexads.
 *
 * exit 0 iff all three theorems hold.  Pure C, no deps, no intrinsics.
 */
#include <stdio.h>
#include <stdint.h>

/* trit: 0=NEG, 1=ZERO, 2=POS (the substrate's base-3 packed convention). */
static int t_and(int a, int b) { static const int T[3][3] = {{0,0,0},{0,1,1},{0,1,2}}; return T[a][b]; }
static int t_or (int a, int b) { static const int T[3][3] = {{0,1,2},{1,1,2},{2,2,2}}; return T[a][b]; }

static void unpack(uint16_t p, int o[6]) { for (int i = 0; i < 6; ++i) { o[i] = p % 3; p = (uint16_t)(p / 3); } }
static uint16_t pack(const int o[6]) { uint16_t v = 0, b = 1; for (int i = 0; i < 6; ++i) { v = (uint16_t)(v + o[i] * b); b = (uint16_t)(b * 3); } return v; }

static uint16_t compose(uint16_t a, uint16_t b) {
    int pa[6], pb[6], pc[6];
    unpack(a, pa);
    unpack(b, pb);
    for (int i = 0; i < 4; ++i) pc[i] = t_and(pa[i], pb[i]);   /* structural P1..P4: AND */
    for (int i = 4; i < 6; ++i) pc[i] = t_or(pa[i], pb[i]);    /* informational P5..P6: OR */
    return pack(pc);
}

/* Spec admission (2.1): admissible iff no NEG in structural pillars 0..3. */
static int admitted(uint16_t h) {
    int o[6];
    unpack(h, o);
    for (int i = 0; i < 4; ++i) if (o[i] == 0) return 0;
    return 1;
}

/* The six PFS bricking patterns (P0..P5), per III-HEXAD.md 4.3. */
static const int BRICK[6][6] = {
    {0,0,0,0,1,1},  /* capsule_update   */
    {0,0,0,1,1,1},  /* microcode_load   */
    {0,0,1,0,1,1},  /* bootorder_set    */
    {0,1,0,0,1,1},  /* real_nvram_write */
    {1,0,0,0,1,1},  /* me_psp_mailbox   */
    {0,0,0,0,0,1}   /* smram_write      */
};

int main(void) {
    long violations = 0;
    long brick_from_admitted = 0;
    for (int a = 0; a < 729; ++a) {
        for (int b = 0; b < 729; ++b) {
            uint16_t c = compose((uint16_t)a, (uint16_t)b);
            int lhs = admitted(c);
            int rhs = admitted((uint16_t)a) && admitted((uint16_t)b);
            if (lhs != rhs) ++violations;                       /* T1 */
            if (admitted((uint16_t)a) && admitted((uint16_t)b)) {
                for (int k = 0; k < 6; ++k) {
                    if (c == pack(BRICK[k])) { ++brick_from_admitted; break; }  /* T3 */
                }
            }
        }
    }
    int bricks_blocked = 0;
    for (int k = 0; k < 6; ++k) if (!admitted(pack(BRICK[k]))) ++bricks_blocked;  /* T2 */

    int spec_admitted = 0;
    for (int h = 0; h < 729; ++h) if (admitted((uint16_t)h)) ++spec_admitted;

    printf("T1 admitted(a.b)==adm(a)&&adm(b): violations=%ld\n", violations);
    printf("T2 bricks blocked by structural rule: %d/6\n", bricks_blocked);
    printf("T3 brick reachable from two admitted: %ld\n", brick_from_admitted);
    printf("spec-admitted hexads: %d/729 (legacy 6-pattern bitmap admits 723)\n", spec_admitted);

    int ok = (violations == 0) && (bricks_blocked == 6) && (brick_from_admitted == 0) && (spec_admitted == 144);
    printf("%s\n", ok ? "PROOF HOLDS: bricking is structurally impossible." : "PROOF FAILED.");
    return ok ? 0 : 1;
}
