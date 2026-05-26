/* COMPILER/BOOT/verify_xii_manifest.c
 *
 * Founders-Anchor Manifest signature verifier (anti-drift check 8).
 *
 * Reads xii_manifest.bin (1040 bytes), and verifies that the 64-byte Ed25519
 * signature at offset 0x330 is a valid signature over bytes [0x000..0x32F]
 * under the public key embedded at offset 0x310.  This is the standalone,
 * deterministic counterpart to the (unimplemented) `iiis --verify-anchor-
 * signature` compiler flag the anti-drift suite previously invoked.
 *
 * Exit 0 = signature valid; 2 = invalid; 1 = I/O error.
 *
 * NIH: libc + the substrate's own crypt_ed25519.iii (ed25519_verify).
 */
#include <stdint.h>
#include <stdio.h>

#define MANIFEST_BYTES 1040
#define SIG_OFFSET     0x330
#define PUBKEY_OFFSET  0x310
#define SIGNED_BYTES   0x330   /* signature covers [0x000..0x32F] */

extern uint8_t ed25519_verify(const uint8_t *pubkey, const uint8_t *msg,
                              uint64_t msg_len, const uint8_t *sig);

int
main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <manifest_path>\n", argv[0]);
        return 1;
    }
    FILE *f = fopen(argv[1], "rb");
    if (!f) { fprintf(stderr, "cannot open manifest: %s\n", argv[1]); return 1; }
    uint8_t m[MANIFEST_BYTES];
    if (fread(m, 1, MANIFEST_BYTES, f) != MANIFEST_BYTES) {
        fclose(f);
        fprintf(stderr, "manifest must be %d bytes\n", MANIFEST_BYTES);
        return 1;
    }
    fclose(f);

    uint8_t v = ed25519_verify(m + PUBKEY_OFFSET, m, SIGNED_BYTES, m + SIG_OFFSET);
    if (v == 1) {
        printf("[verify-manifest] Founders-Anchor signature VALID\n");
        return 0;
    }
    fprintf(stderr, "[verify-manifest] Founders-Anchor signature INVALID\n");
    return 2;
}
