/* COMPILER/BOOT/gen_anchor_seed.c
 *
 * Founders-Anchor ceremony seed generator (Phase XII-zeta Omega12).
 *
 * Produces a 64-byte seed from the §4.7 hardware-entropy DRBG: RDSEED/RDRAND
 * physical entropy seeds an HMAC-DRBG-SHA-512 instance, whose output is the
 * sealed anchor seed.  This is REAL physical entropy (not a fixed/test value);
 * the resulting seed (and the keypair derived from it by gen_xii_anchor_keypair)
 * is unpredictable, as a root of trust must be.  The seed is written once,
 * sealed off-device (single-host enactment: sealed file + operator attestation),
 * and the source destroyed; only the public key is committed to the repo.
 *
 * NIH: libc + the substrate's own drbg.iii (HMAC-DRBG) seeded by cpufeat.iii's
 * RDSEED detection.  Usage: gen_anchor_seed <seed_out_64>
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern int32_t iii_drbg_hw_entropy(uint64_t out, uint64_t n);
extern int32_t iii_drbg_instantiate(uint64_t entropy, uint64_t elen,
                                    uint64_t nonce, uint64_t nlen,
                                    uint64_t perso, uint64_t plen);
extern int32_t iii_drbg_generate(uint64_t out, uint64_t n_bytes,
                                 uint64_t addl, uint64_t alen);
extern uint8_t cpufeat_has_rdseed(void);
extern uint8_t cpufeat_has_rdrand(void);

int
main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <seed_out_64>\n", argv[0]);
        return 1;
    }
    if (cpufeat_has_rdseed() == 0 && cpufeat_has_rdrand() == 0) {
        fprintf(stderr, "[anchor-seed] FATAL: no RDSEED/RDRAND hardware entropy available\n");
        return 2;
    }

    uint8_t entropy[48];
    uint8_t nonce[16];
    uint8_t perso[32] = "III-FOUNDERS-ANCHOR-v1-XII-zeta";  /* domain separation */
    uint8_t seed[64];

    /* 48 bytes of physical entropy (3/2 * 256-bit security) + 16-byte nonce. */
    if (iii_drbg_hw_entropy((uint64_t)(uintptr_t)entropy, 48) != 0) {
        fprintf(stderr, "[anchor-seed] FATAL: iii_drbg_hw_entropy(48) failed\n");
        return 3;
    }
    if (iii_drbg_hw_entropy((uint64_t)(uintptr_t)nonce, 16) != 0) {
        fprintf(stderr, "[anchor-seed] FATAL: iii_drbg_hw_entropy(16) failed\n");
        return 3;
    }
    if (iii_drbg_instantiate((uint64_t)(uintptr_t)entropy, 48,
                             (uint64_t)(uintptr_t)nonce, 16,
                             (uint64_t)(uintptr_t)perso, 31) != 0) {
        fprintf(stderr, "[anchor-seed] FATAL: iii_drbg_instantiate failed\n");
        return 4;
    }
    if (iii_drbg_generate((uint64_t)(uintptr_t)seed, 64, 0, 0) != 0) {
        fprintf(stderr, "[anchor-seed] FATAL: iii_drbg_generate(64) failed\n");
        return 5;
    }

    FILE *f = fopen(argv[1], "wb");
    if (!f) { fprintf(stderr, "[anchor-seed] cannot write %s\n", argv[1]); return 6; }
    if (fwrite(seed, 1, 64, f) != 64) { fclose(f); return 6; }
    fclose(f);

    /* sanctum hygiene: wipe local buffers. */
    memset(entropy, 0, 48);
    memset(nonce, 0, 16);
    memset(seed, 0, 64);
    printf("[anchor-seed] 64-byte HW-entropy DRBG seed written: %s\n", argv[1]);
    return 0;
}
