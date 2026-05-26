/* COMPILER/BOOT/gen_xii_anchor_keypair.c
 *
 * Founders-Anchor Ed25519 keypair generator (one-shot, sealed seed).
 *
 * SECURITY NOTE: The seed used by this tool MUST be a sealed sanctum-derived
 * value generated outside the build environment. For Phase XII-ζ Ω12,
 * the curator runs this tool inside a sanctum-mode operation, captures
 * the keypair, then DESTROYS the source seed file. This binary keeps the
 * private key only in the sealed sanctum store; the public key is written
 * to FOUNDERS-ANCHOR/anchor_pubkey.bin (32 bytes) for embedding into the
 * Manifest at offset 0x310.
 *
 * Usage: gen_xii_anchor_keypair <seed_file> <pubkey_out> <privkey_out>
 *
 * Inputs:
 *   seed_file:   64 bytes of secret entropy (sealed sanctum origin)
 *
 * Outputs:
 *   pubkey_out:  32-byte Ed25519 public key
 *   privkey_out: 64-byte Ed25519 expanded private key (32 secret + 32 pub)
 *
 * NIH: libc only. Ed25519 from STDLIB/iii/numera/crypt_ed25519.iii (linked).
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Externs from STDLIB/iii/numera/crypt_ed25519.iii (linked at build time). */
extern uint32_t ed25519_keypair_from_seed(const uint8_t *seed_32,
                                          uint8_t *pubkey_32,
                                          uint8_t *privkey_64);
extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

int
main(int argc, char **argv)
{
    if (argc < 4) {
        fprintf(stderr, "usage: %s <seed_file> <pubkey_out> <privkey_out>\n", argv[0]);
        fprintf(stderr, "  seed_file must be 64 bytes of sealed entropy\n");
        return 1;
    }

    /* Read seed. */
    FILE *sf = fopen(argv[1], "rb");
    if (!sf) { fprintf(stderr, "cannot open seed: %s\n", argv[1]); return 1; }
    uint8_t seed[64];
    if (fread(seed, 1, 64, sf) != 64) {
        fclose(sf);
        fprintf(stderr, "seed must be exactly 64 bytes\n");
        return 1;
    }
    fclose(sf);

    /* Compress to 32-byte ed25519 seed via SHA-256 of the 64-byte input. */
    uint8_t seed32[32];
    sha256_oneshot(seed, 64, seed32);

    /* Derive keypair. */
    uint8_t pubkey[32];
    uint8_t privkey[64];
    if (ed25519_keypair_from_seed(seed32, pubkey, privkey) != 0) {
        fprintf(stderr, "ed25519_keypair_from_seed failed\n");
        return 2;
    }

    /* Write pubkey. */
    FILE *pf = fopen(argv[2], "wb");
    if (!pf) { fprintf(stderr, "cannot write pubkey: %s\n", argv[2]); return 2; }
    if (fwrite(pubkey, 1, 32, pf) != 32) { fclose(pf); return 2; }
    fclose(pf);

    /* Write privkey (HANDLE WITH CARE; sealed sanctum storage only). */
    FILE *kf = fopen(argv[3], "wb");
    if (!kf) { fprintf(stderr, "cannot write privkey: %s\n", argv[3]); return 2; }
    if (fwrite(privkey, 1, 64, kf) != 64) { fclose(kf); return 2; }
    fclose(kf);

    /* Wipe local buffers (sealed sanctum hygiene). */
    memset(seed, 0, 64);
    memset(seed32, 0, 32);
    memset(privkey, 0, 64);

    printf("[anchor-kg] pubkey written: %s (32 bytes)\n", argv[2]);
    printf("[anchor-kg] privkey written: %s (64 bytes)\n", argv[3]);
    return 0;
}
