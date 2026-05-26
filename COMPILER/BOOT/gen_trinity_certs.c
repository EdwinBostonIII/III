/* COMPILER/BOOT/gen_trinity_certs.c
 *
 * Generates the 12 Trinity admit certs Ω1..Ω12 with real content
 * derived from the sealed sources of each ceremony.
 *
 * Per DOCS/III-XII.md S17 + S26.16. Each cert is 114 bytes:
 *   0..3   : ceremony_id, spec_version, reserved_0
 *   4..19  : intent_crystal_lo[16]    SHA-256(ceremony_input_file)[0..15]
 *   20..35 : cap_witness[16]          SHA-256("CAP_CURATE_XII:omega_N")[0..15]
 *   36..51 : causality_crystal_hi[16] SHA-256(prev_cert_or_zero)[0..15]
 *   52..67 : sanctum_state_hi[16]     SHA-256("XII_SANCTUM_STATE_v1")[0..15]
 *   68..75 : timestamp_utc            sealed SOURCE_DATE_EPOCH (0 for hermetic)
 *   76..79 : sequence_no              N (1..12)
 *   80..81 : flags                    0x03 (anchor_pre_admit + trinity_post_admit)
 *   82..113: signature_lo[32]         SHA-256(all prior bytes)
 *
 * For Phase XII-ζ Ω12, this tool runs once at curation. Each cert is
 * written to COMPILER/BOOT/ceremonies/omega_N.cert.
 *
 * NIH: libc + Win32. SHA-256 from numera/sha256.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CERT_BYTES 114

extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

/* Ceremony input file paths per spec §17.1 (each ceremony's sealed source). */
static const char *ceremony_sources[12] = {
    "STDLIB/iii/omnia/xii_term.iii",          /* Ω1 Basis Definition */
    "STDLIB/iii/omnia/xii_basis.iii",         /* Ω2 Fusion Definition */
    "STDLIB/iii/omnia/xii_hj.iii",            /* Ω3 HJ Table */
    "STDLIB/iii/omnia/xii_savings.iii",       /* Ω4 ΔK Table */
    "STDLIB/iii/omnia/xii_rewrite.iii",       /* Ω5 Rule Curation */
    "STDLIB/iii/omnia/xii_critpairs.iii",     /* Ω6 Confluence Proof */
    "STDLIB/iii/omnia/xii_canonicalise.iii",  /* Ω7 Termination Proof */
    "STDLIB/iii/omnia/xii_horizon.iii",       /* Ω8 Horizon Selection */
    "STDLIB/iii/omnia/xii_emit_gen.iii",      /* Ω9 Target Mapping */
    "STDLIB/iii/omnia/xii_chd.iii",           /* Ω10 MPHF */
    "STDLIB/iii/omnia/xii_circ.iii",          /* Ω11 Circ Feasibility */
    "STDLIB/iii/sanctus/xii_curate.iii",      /* Ω12 Final Seal */
};

static int
hash_file_low16(const char *path, uint8_t out16[16])
{
    FILE *f = fopen(path, "rb");
    if (!f) { memset(out16, 0, 16); return -1; }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 0) { fclose(f); memset(out16, 0, 16); return -1; }
    uint8_t *data = (uint8_t *)malloc((size_t)sz);
    if (!data) { fclose(f); return -1; }
    if (fread(data, 1, (size_t)sz, f) != (size_t)sz) {
        free(data); fclose(f); memset(out16, 0, 16); return -1;
    }
    fclose(f);
    uint8_t full[32];
    sha256_oneshot(data, (uint64_t)sz, full);
    memcpy(out16, full, 16);
    free(data);
    return 0;
}

static void
hash_string_low16(const char *s, uint8_t out16[16])
{
    uint8_t full[32];
    sha256_oneshot((const uint8_t *)s, (uint64_t)strlen(s), full);
    memcpy(out16, full, 16);
}

static void
write_u64_be(uint8_t *out, uint64_t val)
{
    for (int i = 0; i < 8; ++i) out[i] = (uint8_t)((val >> ((7 - i) * 8)) & 0xFF);
}

static void
write_u32_le(uint8_t *out, uint32_t val)
{
    out[0] = (uint8_t)(val & 0xFF);
    out[1] = (uint8_t)((val >> 8) & 0xFF);
    out[2] = (uint8_t)((val >> 16) & 0xFF);
    out[3] = (uint8_t)((val >> 24) & 0xFF);
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <repo_root>\n", argv[0]);
        return 1;
    }
    const char *repo = argv[1];

    uint8_t prev_cert_hash[32] = {0};
    char path[1024];
    char cap_witness_label[64];

    for (int omega = 1; omega <= 12; ++omega) {
        uint8_t cert[CERT_BYTES];
        memset(cert, 0, CERT_BYTES);

        cert[0] = (uint8_t)omega;
        cert[1] = 0x01;  /* spec_version */
        /* cert[2..3]: reserved_0 = 0 */

        /* intent_crystal_lo[16] = SHA-256(ceremony source file)[0..15] */
        snprintf(path, sizeof(path), "%s/%s", repo, ceremony_sources[omega - 1]);
        hash_file_low16(path, cert + 4);

        /* cap_witness[16] = SHA-256("CAP_CURATE_XII:omega_N")[0..15] */
        snprintf(cap_witness_label, sizeof(cap_witness_label),
                 "CAP_CURATE_XII:omega_%d", omega);
        hash_string_low16(cap_witness_label, cert + 20);

        /* causality_crystal_hi[16] = SHA-256(prev_cert_hash)[0..15] */
        if (omega == 1) {
            hash_string_low16("XII_CURATION_ROOT_v1", cert + 36);
        } else {
            uint8_t causality[32];
            sha256_oneshot(prev_cert_hash, 32, causality);
            memcpy(cert + 36, causality, 16);
        }

        /* sanctum_state_hi[16] = SHA-256("XII_SANCTUM_STATE_v1")[0..15] */
        hash_string_low16("XII_SANCTUM_STATE_v1", cert + 52);

        /* timestamp_utc: SOURCE_DATE_EPOCH (0 for hermetic) BE u64 */
        write_u64_be(cert + 68, 0);

        /* sequence_no: omega (LE u32) */
        write_u32_le(cert + 76, (uint32_t)omega);

        /* flags: anchor_pre_admit | trinity_post_admit = 0x03 */
        cert[80] = 0x03;
        cert[81] = 0x00;

        /* signature_lo[32] = SHA-256(cert[0..81])[0..31] */
        sha256_oneshot(cert, 82, cert + 82);

        /* Write cert. */
        snprintf(path, sizeof(path),
                 "%s/COMPILER/BOOT/ceremonies/omega_%d.cert", repo, omega);
        FILE *out = fopen(path, "wb");
        if (!out) { fprintf(stderr, "cannot write %s\n", path); return 2; }
        if (fwrite(cert, 1, CERT_BYTES, out) != CERT_BYTES) { fclose(out); return 2; }
        fclose(out);

        /* Update prev_cert_hash for next iteration. */
        sha256_oneshot(cert, CERT_BYTES, prev_cert_hash);

        printf("[trinity-cert] Ω%d -> %s\n", omega, path);
    }

    /* Write the trinity_admit aggregate (32 bytes mhash + 24 bytes metadata). */
    /* Recompute: SHA-256 over concatenated 12 * 114-byte certs. */
    uint8_t concat[12 * CERT_BYTES];
    for (int omega = 1; omega <= 12; ++omega) {
        snprintf(path, sizeof(path),
                 "%s/COMPILER/BOOT/ceremonies/omega_%d.cert", repo, omega);
        FILE *cf = fopen(path, "rb");
        if (!cf) { fprintf(stderr, "missing cert: %s\n", path); return 2; }
        fread(concat + ((omega - 1) * CERT_BYTES), 1, CERT_BYTES, cf);
        fclose(cf);
    }
    uint8_t admit[56];
    memset(admit, 0, 56);
    sha256_oneshot(concat, 12 * CERT_BYTES, admit);
    write_u32_le(admit + 32, 12);     /* cert_count */
    write_u32_le(admit + 36, 1);      /* curation_epoch_id (Ω12 epoch = 1) */
    /* admit[40..55] reserved zero */

    snprintf(path, sizeof(path), "%s/COMPILER/BOOT/ceremonies/trinity_admit.bin", repo);
    FILE *af = fopen(path, "wb");
    if (!af) { fprintf(stderr, "cannot write %s\n", path); return 2; }
    fwrite(admit, 1, 56, af);
    fclose(af);

    printf("[trinity-cert] 12 certs + trinity_admit (56 bytes) written\n");
    return 0;
}
