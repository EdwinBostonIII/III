/* COMPILER/BOOT/sign_xii_manifest.c
 *
 * Founders-Anchor Manifest signer.
 *
 * Reads xii_manifest.bin (1040 bytes), signs bytes [0x000..0x32F] with
 * the Anchor's Ed25519 private key, patches the 64-byte signature into
 * the Manifest at offset 0x330, recomputes the Manifest mhash, and
 * writes the new golden hash to xii_manifest.mhash.golden.
 *
 * Usage: sign_xii_manifest <manifest_path> <privkey_path> <golden_out>
 *
 * SECURITY NOTE: This tool MUST run inside a sealed sanctum where the
 * private key file is protected (TPM-sealed, sanctum-resident, etc.).
 * The build environment never holds the private key in plaintext outside
 * this tool's process lifetime.
 *
 * NIH: libc only. Ed25519 from STDLIB/iii/numera/crypt_ed25519.iii.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MANIFEST_BYTES 1040
#define SIG_OFFSET     0x330
#define SIG_BYTES      64
#define SIGNED_BYTES   0x330  /* signature covers [0..0x32F] */
#define PUBKEY_OFFSET  0x310
#define PUBKEY_BYTES   32

/* The native crypt_ed25519.iii exports the combined-key signer
 * ed25519_sign_c4(keys, msg, msg_len, sig) where keys = seed(32)||pubkey(32)
 * -- exactly the 64-byte expanded private key this tool reads -- and returns
 * 1 on success.  (The 5-arg ed25519_sign(seed, pk, ...) is the lower-level
 * form; calling it with this tool's 4 args mis-binds the registers and
 * segfaults.) */
extern uint8_t ed25519_sign_c4(const uint8_t *keys_64,
                               const uint8_t *msg, uint64_t msg_len,
                               uint8_t *sig_64);
extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

int
main(int argc, char **argv)
{
    if (argc < 4) {
        fprintf(stderr, "usage: %s <manifest_path> <privkey_path> <golden_out>\n", argv[0]);
        return 1;
    }

    /* Read manifest. */
    FILE *mf = fopen(argv[1], "rb");
    if (!mf) { fprintf(stderr, "cannot open manifest: %s\n", argv[1]); return 1; }
    uint8_t manifest[MANIFEST_BYTES];
    if (fread(manifest, 1, MANIFEST_BYTES, mf) != MANIFEST_BYTES) {
        fclose(mf);
        fprintf(stderr, "manifest must be %d bytes\n", MANIFEST_BYTES);
        return 1;
    }
    fclose(mf);

    /* Read privkey. */
    FILE *kf = fopen(argv[2], "rb");
    if (!kf) { fprintf(stderr, "cannot open privkey: %s\n", argv[2]); return 1; }
    uint8_t privkey[64];
    if (fread(privkey, 1, 64, kf) != 64) {
        fclose(kf);
        memset(privkey, 0, 64);
        fprintf(stderr, "privkey must be 64 bytes\n");
        return 1;
    }
    fclose(kf);

    /* Sign manifest[0..0x32F] with the combined-key signer (returns 1 on
     * success). */
    uint8_t sig[SIG_BYTES];
    if (ed25519_sign_c4(privkey, manifest, SIGNED_BYTES, sig) != 1) {
        memset(privkey, 0, 64);
        fprintf(stderr, "ed25519_sign_c4 failed\n");
        return 2;
    }

    /* Wipe privkey immediately. */
    memset(privkey, 0, 64);

    /* Patch signature into manifest at 0x330. */
    memcpy(manifest + SIG_OFFSET, sig, SIG_BYTES);

    /* Write the now-signed manifest back. */
    FILE *out = fopen(argv[1], "wb");
    if (!out) { fprintf(stderr, "cannot rewrite manifest: %s\n", argv[1]); return 2; }
    if (fwrite(manifest, 1, MANIFEST_BYTES, out) != MANIFEST_BYTES) {
        fclose(out); return 2;
    }
    fclose(out);

    /* Compute final manifest mhash and write golden. */
    uint8_t mhash[32];
    sha256_oneshot(manifest, MANIFEST_BYTES, mhash);

    FILE *gf = fopen(argv[3], "w");
    if (!gf) { fprintf(stderr, "cannot write golden: %s\n", argv[3]); return 2; }
    for (int i = 0; i < 32; ++i) fprintf(gf, "%02x", mhash[i]);
    fprintf(gf, "\n");
    fclose(gf);

    printf("[anchor-sign] manifest signed; mhash: ");
    for (int i = 0; i < 32; ++i) printf("%02x", mhash[i]);
    printf("\n");
    return 0;
}
