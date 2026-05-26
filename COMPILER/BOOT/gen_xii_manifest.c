/* COMPILER/BOOT/gen_xii_manifest.c
 *
 * Generates xii_manifest.bin (1040 bytes) per DOCS/III-XII.md S26.11.
 * Generates xii_manifest.mhash.golden alongside.
 *
 * Usage: gen_xii_manifest <repo_root>
 *
 * The Manifest captures the curation state:
 *   - 23 sealed mhash fields (R1 root, horizon, rewrite, ... seals)
 *   - 4 ceremonial seals (Founders-Anchor pubkey, signature, Trinity admit,
 *     timestamp)
 *   - 96 reserved bytes
 *
 * Crystal seals (CRY-XII-*-001) are bound as:
 *
 *   crystal_mhash = SHA-256(
 *       LE_u32(len(crystal_id)) ||
 *       crystal_id_bytes        ||
 *       LE_u32(n_sources)       ||
 *       FOR each source:
 *           LE_u64(source_len)  ||
 *           source_content_bytes
 *   )
 *
 * This is content-addressed: anyone who recomputes from the same sealed
 * source files plus the same crystal_id reproduces the same mhash bit-for-
 * bit. Tampering with any source or the crystal_id changes the hash.
 *
 * The Anchor pubkey (0x310, 32B) and Trinity admit blob (0x370, 56B) are
 * loaded BEFORE the manifest is signed so the Anchor signature covers
 * them. The signature itself (0x330, 64B) is patched in by
 * sign_xii_manifest after this tool runs.
 *
 * NIH: libc only. SHA-256 from numera/sha256 (must be linked).
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define XII_MANIFEST_BYTES 1040

extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

/* Field offsets per S26.11. */
#define OFF_MAGIC                0x000
#define OFF_SPEC_VERSION         0x008
#define OFF_RESERVED_0           0x00C
#define OFF_R1_ROOT              0x010
#define OFF_HORIZON_SEAL         0x030
#define OFF_REWRITE_SEAL         0x050
#define OFF_CONFLUENCE_SEAL      0x070
#define OFF_TERMINATION_SEAL     0x090
#define OFF_DECIDABILITY_SEAL    0x0B0
#define OFF_COHESION_SEAL        0x0D0
#define OFF_KIND_SEAL            0x0F0
#define OFF_K_SEAL               0x110
#define OFF_CAP_SEAL             0x130
#define OFF_PROV_SEAL            0x150
#define OFF_NOINV_SEAL           0x170
#define OFF_LATTICE_SEAL         0x190
#define OFF_MPHF_PRIMARY_SEAL    0x1B0
#define OFF_MPHF_SECONDARY_SEAL  0x1D0
#define OFF_HORIZON_REACH_SEAL   0x1F0
#define OFF_TARGET_TABLE_SEAL    0x210
#define OFF_DK_COMPOSE_SEAL      0x230
#define OFF_HJ_TABLE_SEAL        0x250
#define OFF_CIRC_FEASIBLE_SEAL   0x270
#define OFF_CT_CLASSES_SEAL      0x290
#define OFF_TARGETS_SEAL         0x2B0
#define OFF_PROV_XFORMS_SEAL     0x2D0
#define OFF_CHD_SALT_RECORD      0x2F0
#define OFF_ANCHOR_PUBKEY        0x310
#define OFF_ANCHOR_SIGNATURE     0x330
#define OFF_TRINITY_ADMIT        0x370
#define OFF_TIMESTAMP_UTC        0x3A8
#define OFF_RESERVED_1           0x3B0

#define MAX_CRYSTAL_SOURCES 4

struct crystal_def {
    size_t   manifest_offset;
    const char *crystal_id;
    const char *sources[MAX_CRYSTAL_SOURCES];   /* NULL-terminated list */
};

/* CRY-XII-*-001 crystal-id  to-source-file map.
 * Multi-source crystals concatenate their inputs in declaration order, so
 * the binding is order-deterministic. */
static const struct crystal_def g_crystals[] = {
    { OFF_HORIZON_SEAL,        "HORIZON-SEAL",
        { "STDLIB/iii/omnia/xii_horizon.iii", NULL } },
    { OFF_REWRITE_SEAL,        "REWRITE-SEAL",
        { "STDLIB/iii/omnia/xii_rewrite.iii", NULL } },
    /* route-S: the confluence proof is now the sealed Confluence-Core Certificate (xii_conf_cert,
     * corpus 826) -- it content-addresses the rule semantics + the route-R discharge of all 20
     * residual non-joins, SUPERSEDING the retired hand-enumerated critical-pair file (xii_critpairs).
     * The next signed seal ceremony rebakes this crystal over the cert source. */
    { OFF_CONFLUENCE_SEAL,     "CRY-XII-CONF-001",
        { "STDLIB/iii/omnia/xii_conf_cert.iii", NULL } },
    { OFF_TERMINATION_SEAL,    "CRY-XII-TERM-001",
        { "STDLIB/iii/omnia/xii_canonicalise.iii", NULL } },
    { OFF_DECIDABILITY_SEAL,   "CRY-XII-DEC-001",
        { "STDLIB/iii/omnia/xii_canonicalise.iii",
          "STDLIB/iii/omnia/xii_rewrite.iii", NULL } },
    { OFF_COHESION_SEAL,       "CRY-XII-COH-001",
        { "STDLIB/iii/omnia/xii_lattice.iii",
          "STDLIB/iii/omnia/xii_basis.iii", NULL } },
    { OFF_KIND_SEAL,           "CRY-XII-KIND-001",
        { "STDLIB/iii/omnia/xii_rewrite.iii",
          "STDLIB/iii/omnia/xii_hj.iii", NULL } },
    { OFF_K_SEAL,              "CRY-XII-K-001",
        { "STDLIB/iii/omnia/xii_rewrite.iii",
          "STDLIB/iii/omnia/xii_basis.iii", NULL } },
    { OFF_CAP_SEAL,            "CRY-XII-CAP-001",
        { "STDLIB/iii/omnia/xii_rewrite.iii",
          "STDLIB/iii/omnia/xii_basis.iii", NULL } },
    { OFF_PROV_SEAL,           "CRY-XII-PROV-001",
        { "STDLIB/iii/numera/xii_subforms.iii", NULL } },
    { OFF_NOINV_SEAL,          "CRY-XII-NOINV-001",
        { "STDLIB/iii/omnia/xii_canonicalise.iii", NULL } },
    { OFF_LATTICE_SEAL,        "LATTICE-SEAL",
        { "COMPILED/xii_lattice.bin", NULL } },
    { OFF_MPHF_PRIMARY_SEAL,   "MPHF-PRIMARY-SEAL",
        { "STDLIB/iii/omnia/xii_chd.iii", NULL } },
    { OFF_MPHF_SECONDARY_SEAL, "MPHF-SECONDARY-SEAL",
        { "STDLIB/iii/omnia/xii_chd.iii",
          "STDLIB/iii/omnia/xii_horizon.iii", NULL } },
    { OFF_HORIZON_REACH_SEAL,  "HORIZON-REACH-SEAL",
        { "STDLIB/iii/omnia/xii_horizon_reach.iii", NULL } },
    { OFF_TARGET_TABLE_SEAL,   "TARGET-TABLE-SEAL",
        { "STDLIB/iii/numera/xii_nop_tables.iii", NULL } },
    { OFF_DK_COMPOSE_SEAL,     "DK-COMPOSE-SEAL",
        { "STDLIB/iii/omnia/xii_savings.iii", NULL } },
    { OFF_HJ_TABLE_SEAL,       "HJ-TABLE-SEAL",
        { "STDLIB/iii/omnia/xii_hj.iii", NULL } },
    { OFF_CIRC_FEASIBLE_SEAL,  "CIRC-FEASIBLE-SEAL",
        { "STDLIB/iii/omnia/xii_circ.iii", NULL } },
    { OFF_CT_CLASSES_SEAL,     "CT-CLASSES-SEAL",
        { "STDLIB/iii/omnia/xii_basis.iii", NULL } },
    { OFF_TARGETS_SEAL,        "TARGETS-SEAL",
        { "STDLIB/iii/numera/xii_nop_tables.iii",
          "STDLIB/iii/omnia/xii_kernel_emit.iii", NULL } },
    { OFF_PROV_XFORMS_SEAL,    "PROV-XFORMS-SEAL",
        { "STDLIB/iii/numera/xii_subforms.iii", NULL } },
};

#define NUM_CRYSTALS (sizeof(g_crystals) / sizeof(g_crystals[0]))

static void
write_magic(uint8_t *buf)
{
    /* "XII\x01M\x00\x00\x00" */
    buf[0] = 0x58; buf[1] = 0x49; buf[2] = 0x49; buf[3] = 0x01;
    buf[4] = 0x4D; buf[5] = 0x00; buf[6] = 0x00; buf[7] = 0x00;
}

static void
write_u32_le(uint8_t *out, uint32_t val)
{
    out[0] = (uint8_t)(val & 0xFF);
    out[1] = (uint8_t)((val >> 8) & 0xFF);
    out[2] = (uint8_t)((val >> 16) & 0xFF);
    out[3] = (uint8_t)((val >> 24) & 0xFF);
}

static void
write_u64_le(uint8_t *out, uint64_t val)
{
    for (int i = 0; i < 8; ++i) {
        out[i] = (uint8_t)((val >> (i * 8)) & 0xFF);
    }
}

static void
write_u64_be(uint8_t *out, uint64_t val)
{
    for (int i = 0; i < 8; ++i) {
        out[i] = (uint8_t)((val >> ((7 - i) * 8)) & 0xFF);
    }
}

/* Streaming append-buffer for crystal computation. */
struct stream {
    uint8_t *data;
    size_t   len;
    size_t   cap;
};

static int
stream_grow(struct stream *s, size_t need)
{
    if (s->cap >= need) { return 0; }
    size_t new_cap = s->cap ? s->cap : 4096;
    while (new_cap < need) { new_cap *= 2; }
    uint8_t *grown = (uint8_t *)realloc(s->data, new_cap);
    if (!grown) { return -1; }
    s->data = grown;
    s->cap = new_cap;
    return 0;
}

static int
stream_write(struct stream *s, const void *bytes, size_t n)
{
    if (stream_grow(s, s->len + n) != 0) { return -1; }
    memcpy(s->data + s->len, bytes, n);
    s->len += n;
    return 0;
}

static void
stream_free(struct stream *s)
{
    free(s->data);
    s->data = NULL;
    s->len = 0;
    s->cap = 0;
}

/* Read full file into stream. Returns 0 on success, -1 on missing/IO error.
 * On missing file the stream is unchanged and the manifest seal stays zero. */
static int
stream_append_file(struct stream *s, const char *path)
{
    FILE *f = fopen(path, "rb");
    if (!f) { return -1; }
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return -1; }
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return -1; }
    if (fseek(f, 0, SEEK_SET) != 0) { fclose(f); return -1; }
    if (stream_grow(s, s->len + (size_t)sz) != 0) { fclose(f); return -1; }
    if (sz > 0 && fread(s->data + s->len, 1, (size_t)sz, f) != (size_t)sz) {
        fclose(f);
        return -1;
    }
    fclose(f);
    s->len += (size_t)sz;
    return 0;
}

/* Compute one crystal mhash per the framing rule documented at the top of
 * this file. Writes 32 bytes at buf + manifest_offset. Returns 0 on success,
 * -1 if any source file is missing (manifest seal will remain zero). */
static int
emit_crystal(uint8_t *buf, const struct crystal_def *cd, const char *repo)
{
    struct stream s;
    s.data = NULL; s.len = 0; s.cap = 0;

    size_t id_len = strlen(cd->crystal_id);
    uint8_t id_len_le[4];
    write_u32_le(id_len_le, (uint32_t)id_len);
    if (stream_write(&s, id_len_le, 4) != 0) { stream_free(&s); return -1; }
    if (stream_write(&s, cd->crystal_id, id_len) != 0) { stream_free(&s); return -1; }

    /* Count non-NULL sources. */
    uint32_t n_sources = 0;
    while (n_sources < MAX_CRYSTAL_SOURCES && cd->sources[n_sources]) { n_sources++; }
    uint8_t n_le[4];
    write_u32_le(n_le, n_sources);
    if (stream_write(&s, n_le, 4) != 0) { stream_free(&s); return -1; }

    for (uint32_t i = 0; i < n_sources; ++i) {
        char abspath[1024];
        snprintf(abspath, sizeof(abspath), "%s/%s", repo, cd->sources[i]);

        /* Read the file into a temporary stream so we know its length. */
        struct stream src;
        src.data = NULL; src.len = 0; src.cap = 0;
        if (stream_append_file(&src, abspath) != 0) {
            fprintf(stderr, "[xii-manifest] missing source: %s (%s)\n",
                    abspath, cd->crystal_id);
            stream_free(&src);
            stream_free(&s);
            return -1;
        }
        uint8_t len_le[8];
        write_u64_le(len_le, (uint64_t)src.len);
        if (stream_write(&s, len_le, 8) != 0) {
            stream_free(&src); stream_free(&s); return -1;
        }
        if (src.len > 0 && stream_write(&s, src.data, src.len) != 0) {
            stream_free(&src); stream_free(&s); return -1;
        }
        stream_free(&src);
    }

    /* Hash the framed input. */
    sha256_oneshot(s.data, (uint64_t)s.len, buf + cd->manifest_offset);
    stream_free(&s);
    return 0;
}

/* Read a 32-byte hex SHA-256 (with optional trailing whitespace) into out. */
static int
read_hex32(const char *path, uint8_t *out_32)
{
    FILE *f = fopen(path, "r");
    if (!f) { return -1; }
    char hex[80];
    if (!fgets(hex, sizeof(hex), f)) { fclose(f); return -1; }
    fclose(f);
    for (int i = 0; i < 32; ++i) {
        unsigned int b;
        if (sscanf(hex + (i * 2), "%2x", &b) != 1) { return -1; }
        out_32[i] = (uint8_t)b;
    }
    return 0;
}

/* Read up to `cap` raw bytes from path into out. Returns bytes read or -1. */
static long
read_raw(const char *path, uint8_t *out, size_t cap)
{
    FILE *f = fopen(path, "rb");
    if (!f) { return -1; }
    size_t n = fread(out, 1, cap, f);
    fclose(f);
    return (long)n;
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <repo_root>\n", argv[0]);
        return 1;
    }
    const char *repo = argv[1];

    uint8_t buf[XII_MANIFEST_BYTES];
    memset(buf, 0, sizeof(buf));

    write_magic(buf + OFF_MAGIC);
    write_u32_le(buf + OFF_SPEC_VERSION, 1);
    /* OFF_RESERVED_0 stays zero. */

    /* R1 root: read DOCS/R1.mhash hex into 0x010. If absent, stays zero
     * (pre-R1 build). */
    {
        char path[1024];
        snprintf(path, sizeof(path), "%s/DOCS/R1.mhash", repo);
        if (read_hex32(path, buf + OFF_R1_ROOT) != 0) {
            /* No fatal error -- R1 may not yet be sealed when XII is
             * sealed first. Manifest can be re-generated with R1 once
             * available. */
            memset(buf + OFF_R1_ROOT, 0, 32);
        }
    }

    /* Compute every crystal/material seal. Missing sources are fatal --
     * a sealed Manifest cannot point at non-existent inputs. */
    int hard_fail = 0;
    for (size_t i = 0; i < NUM_CRYSTALS; ++i) {
        if (emit_crystal(buf, &g_crystals[i], repo) != 0) {
            hard_fail = 1;
        }
    }
    if (hard_fail) {
        fprintf(stderr, "[xii-manifest] FATAL: one or more crystal sources missing; "
                        "manifest not sealable\n");
        return 3;
    }

    /* CHD salt record: 32 bytes total. Byte 0 = salt; bytes 1..31 = first 31
     * bytes of SHA-256(salt). (The full 32-byte hash overruns into 0x310 if
     * placed in full, so we keep the documented 1+31 layout.) */
    {
        uint8_t salt = 0;
        uint8_t hash[32];
        sha256_oneshot(&salt, 1, hash);
        buf[OFF_CHD_SALT_RECORD] = salt;
        memcpy(buf + OFF_CHD_SALT_RECORD + 1, hash, 31);
    }

    /* Anchor pubkey @ 0x310 (32 bytes). Loaded from FOUNDERS-ANCHOR if
     * the keypair generator has run. If absent, stays zero AND we report
     * an error so the operator knows the seal is incomplete. */
    {
        char path[1024];
        snprintf(path, sizeof(path), "%s/FOUNDERS-ANCHOR/anchor_pubkey.bin", repo);
        long n = read_raw(path, buf + OFF_ANCHOR_PUBKEY, 32);
        if (n != 32) {
            fprintf(stderr, "[xii-manifest] WARNING: anchor_pubkey.bin not loaded "
                            "(%ld bytes); 0x310 stays zero. Run "
                            "gen_xii_anchor_keypair first.\n", n);
            memset(buf + OFF_ANCHOR_PUBKEY, 0, 32);
        }
    }

    /* Anchor signature @ 0x330: zero. sign_xii_manifest patches it in
     * AFTER this tool writes the manifest. */
    memset(buf + OFF_ANCHOR_SIGNATURE, 0, 64);

    /* Trinity admit blob @ 0x370 (56 bytes). Loaded from ceremonies/. */
    {
        char path[1024];
        snprintf(path, sizeof(path),
                 "%s/COMPILER/BOOT/ceremonies/trinity_admit.bin", repo);
        long n = read_raw(path, buf + OFF_TRINITY_ADMIT, 56);
        if (n != 56) {
            fprintf(stderr, "[xii-manifest] WARNING: trinity_admit.bin not loaded "
                            "(%ld bytes); 0x370 stays zero. Run "
                            "gen_trinity_certs first.\n", n);
            memset(buf + OFF_TRINITY_ADMIT, 0, 56);
        }
    }

    /* Timestamp @ 0x3A8: SOURCE_DATE_EPOCH (0 for hermetic) BE. */
    write_u64_be(buf + OFF_TIMESTAMP_UTC, 0);

    /* Reserved_1 @ 0x3B0: 96 zero bytes (already zero from memset). */

    /* Write the manifest. */
    char path[1024];
    snprintf(path, sizeof(path), "%s/COMPILER/BOOT/xii_manifest.bin", repo);
    FILE *out = fopen(path, "wb");
    if (!out) { fprintf(stderr, "cannot write %s\n", path); return 2; }
    if (fwrite(buf, 1, XII_MANIFEST_BYTES, out) != XII_MANIFEST_BYTES) {
        fclose(out); fprintf(stderr, "short write\n"); return 2;
    }
    fclose(out);

    /* Compute and write the PRE-SIG mhash. sign_xii_manifest will overwrite
     * this file with the POST-SIG mhash once the signature is patched in.
     * Keeping the pre-sig hash visible here as a build artifact lets the
     * operator diff against the post-sig hash to confirm the signature was
     * the only mutation. */
    uint8_t mhash[32];
    sha256_oneshot(buf, XII_MANIFEST_BYTES, mhash);
    snprintf(path, sizeof(path),
             "%s/COMPILER/BOOT/xii_manifest.mhash.presig", repo);
    FILE *gh = fopen(path, "wb");
    if (!gh) { fprintf(stderr, "cannot write %s\n", path); return 2; }
    for (int i = 0; i < 32; ++i) fprintf(gh, "%02x", mhash[i]);
    fprintf(gh, "\n");
    fclose(gh);

    /* Also write the customary golden file so callers that pre-date the
     * presig split still find the manifest mhash; sign_xii_manifest will
     * overwrite it with the post-sig hash. */
    snprintf(path, sizeof(path),
             "%s/COMPILER/BOOT/xii_manifest.mhash.golden", repo);
    FILE *g2 = fopen(path, "wb");
    if (!g2) { fprintf(stderr, "cannot write %s\n", path); return 2; }
    for (int i = 0; i < 32; ++i) fprintf(g2, "%02x", mhash[i]);
    fprintf(g2, "\n");
    fclose(g2);

    printf("[xii-manifest] manifest written: %d bytes\n", XII_MANIFEST_BYTES);
    printf("[xii-manifest] pre-sig mhash: ");
    for (int i = 0; i < 32; ++i) printf("%02x", mhash[i]);
    printf("\n");
    return 0;
}
