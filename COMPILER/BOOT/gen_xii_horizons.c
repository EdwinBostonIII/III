/* COMPILER/BOOT/gen_xii_horizons.c
 *
 * XII MPHF horizon-seeding pipeline (per DOCS/III-XII.md S26 + the gospel
 * Stage-6 gate "the MPHF is seeded with real horizon master hashes and
 * xii_chd_verify_collision_free returns zero").
 *
 * For each of the 144 horizon patterns, derives a REAL master hash from the
 * horizon's canonical definition (id || primary_op || ct_kind || productivity)
 * via SHA-256 -- not the synthetic values corpus 355 uses to exercise the CHD.
 * Seeds these 144 real hashes into the CHD minimal perfect hash, constructs it,
 * and verifies it is collision-free (every horizon hash maps back to its own
 * index).  Emits the seed golden = SHA-256 over the 144 concatenated master
 * hashes, so the seeding is byte-deterministic and ledgerable.
 *
 * Exit 0 = seeded + constructed + collision-free; non-zero = failure stage.
 *
 * NIH: libc + the substrate's own xii_horizon.iii / xii_chd.iii / sha256.iii.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define N_HORIZONS 144

extern int      xii_horizon_init(void);
extern uint8_t  xii_horizon_is_productive(uint32_t id);
extern uint8_t  xii_horizon_ct_kind(uint32_t id);
extern uint8_t  xii_horizon_primary_op(uint32_t id);
extern int32_t  xii_chd_set_hash(uint32_t idx, uint32_t hash_lo, uint32_t hash_hi);
extern uint8_t  xii_chd_construct(void);
extern uint32_t xii_chd_verify_collision_free(void);
extern uint8_t  xii_chd_built(void);
extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

static void
put_u32_le(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)(v & 0xFF);
    p[1] = (uint8_t)((v >> 8) & 0xFF);
    p[2] = (uint8_t)((v >> 16) & 0xFF);
    p[3] = (uint8_t)((v >> 24) & 0xFF);
}

int
main(int argc, char **argv)
{
    const char *golden_out = (argc >= 2) ? argv[1] : NULL;

    xii_horizon_init();

    /* Derive + seed the 144 real horizon master hashes. */
    uint8_t all_hashes[N_HORIZONS * 32];
    for (uint32_t id = 0; id < N_HORIZONS; ++id) {
        uint8_t def[8];
        put_u32_le(def, id);
        def[4] = xii_horizon_primary_op(id);
        def[5] = xii_horizon_ct_kind(id);
        def[6] = xii_horizon_is_productive(id);
        def[7] = 0;
        uint8_t mh[32];
        sha256_oneshot(def, 8, mh);
        memcpy(all_hashes + id * 32, mh, 32);

        uint32_t lo = (uint32_t)mh[0] | ((uint32_t)mh[1] << 8) |
                      ((uint32_t)mh[2] << 16) | ((uint32_t)mh[3] << 24);
        uint32_t hi = (uint32_t)mh[4] | ((uint32_t)mh[5] << 8) |
                      ((uint32_t)mh[6] << 16) | ((uint32_t)mh[7] << 24);
        xii_chd_set_hash(id, lo, hi);
    }

    if (xii_chd_construct() != 1) {
        fprintf(stderr, "[xii-horizons] FATAL: CHD construction failed\n");
        return 2;
    }
    if (xii_chd_built() != 1) {
        fprintf(stderr, "[xii-horizons] FATAL: CHD not built\n");
        return 3;
    }
    uint32_t fails = xii_chd_verify_collision_free();
    if (fails != 0) {
        fprintf(stderr, "[xii-horizons] FATAL: %u collisions in MPHF\n", fails);
        return 4;
    }

    /* Seed golden = SHA-256 over the 144 real master hashes. */
    uint8_t golden[32];
    sha256_oneshot(all_hashes, sizeof(all_hashes), golden);

    printf("[xii-horizons] %d real horizon master hashes seeded; MPHF collision-free\n", N_HORIZONS);
    printf("[xii-horizons] seed golden: ");
    for (int i = 0; i < 32; ++i) printf("%02x", golden[i]);
    printf("\n");

    if (golden_out) {
        FILE *g = fopen(golden_out, "w");
        if (!g) { fprintf(stderr, "[xii-horizons] cannot write %s\n", golden_out); return 5; }
        for (int i = 0; i < 32; ++i) fprintf(g, "%02x", golden[i]);
        fprintf(g, "\n");
        fclose(g);
    }
    return 0;
}
