/* COMPILER/BOOT/gen_xii_r1.c
 *
 * Computes XII_R1 = SHA-256(R1 ‖ xii_manifest.mhash ‖ xii_lattice.mhash ‖ xii_horizon_reach.mhash).
 * Per DOCS/III-XII.md S19.3 + S25.
 *
 * Usage: gen_xii_r1 <repo_root>
 *
 * Reads:
 *   $REPO/DOCS/R1.mhash                       (if present; else 32 zero bytes)
 *   $REPO/COMPILER/BOOT/xii_manifest.mhash.golden
 *   $REPO/COMPILED/xii_lattice.mhash.golden
 *   $REPO/STDLIB/iii/omnia/xii_horizon_reach.iii    (hash the source file)
 *
 * Writes:
 *   $REPO/DOCS/XII_R1.mhash                   (the composite root, hex + newline)
 *
 * NIH: libc only.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

static int
read_hex32(const char *path, uint8_t *out_32)
{
    FILE *f = fopen(path, "r");
    if (!f) { memset(out_32, 0, 32); return -1; }
    char hex[80];
    if (!fgets(hex, sizeof(hex), f)) { fclose(f); memset(out_32, 0, 32); return -1; }
    fclose(f);
    for (int i = 0; i < 32; ++i) {
        unsigned int b;
        if (sscanf(hex + (i * 2), "%2x", &b) != 1) { memset(out_32, 0, 32); return -1; }
        out_32[i] = (uint8_t)b;
    }
    return 0;
}

static int
hash_file(const char *path, uint8_t *out_32)
{
    FILE *f = fopen(path, "rb");
    if (!f) { memset(out_32, 0, 32); return -1; }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 0) { fclose(f); memset(out_32, 0, 32); return -1; }
    uint8_t *data = (uint8_t *)malloc((size_t)sz);
    if (!data) { fclose(f); return -1; }
    fread(data, 1, (size_t)sz, f);
    fclose(f);
    sha256_oneshot(data, (uint64_t)sz, out_32);
    free(data);
    return 0;
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <repo_root>\n", argv[0]);
        return 1;
    }
    const char *repo = argv[1];
    char path[1024];

    uint8_t r1[32], manifest_h[32], lattice_h[32], reach6_h[32];

    snprintf(path, sizeof(path), "%s/DOCS/R1.mhash", repo);
    read_hex32(path, r1);

    snprintf(path, sizeof(path), "%s/COMPILER/BOOT/xii_manifest.mhash.golden", repo);
    read_hex32(path, manifest_h);

    snprintf(path, sizeof(path), "%s/COMPILED/xii_lattice.mhash.golden", repo);
    read_hex32(path, lattice_h);

    snprintf(path, sizeof(path), "%s/STDLIB/iii/omnia/xii_horizon_reach.iii", repo);
    hash_file(path, reach6_h);

    uint8_t concat[128];
    memcpy(concat,      r1,         32);
    memcpy(concat + 32, manifest_h, 32);
    memcpy(concat + 64, lattice_h,  32);
    memcpy(concat + 96, reach6_h,   32);

    uint8_t xii_r1[32];
    sha256_oneshot(concat, 128, xii_r1);

    snprintf(path, sizeof(path), "%s/DOCS/XII_R1.mhash", repo);
    FILE *out = fopen(path, "w");
    if (!out) { fprintf(stderr, "cannot write %s\n", path); return 2; }
    for (int i = 0; i < 32; ++i) fprintf(out, "%02x", xii_r1[i]);
    fprintf(out, "\n");
    fclose(out);

    printf("[xii] XII_R1 = ");
    for (int i = 0; i < 32; ++i) printf("%02x", xii_r1[i]);
    printf("\n");
    return 0;
}
