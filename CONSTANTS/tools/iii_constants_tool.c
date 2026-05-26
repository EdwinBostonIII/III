/* III CONSTANTS — command-line tool.
 *
 * Subcommands:
 *   dump
 *   lookup <NAME>
 *   root
 *   validate <PATH> <NAME> <NEW_VALUE>
 *
 *     PATH is one of: catalyst-append | amend-apply | r2-bump
 *     NEW_VALUE encoding:
 *       - For numeric (U64/S64/Q14/BOOL): a decimal integer (or 0xHEX).
 *       - For BAND/TUPLE2:                "lo,hi" decimal or hex.
 *       - For STRING:                     literal UTF-8 string.
 *       - For BYTES:                      hex string (e.g. "deadbeef").
 */
#include "iii/constants.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <ctype.h>

static void hex_print(const uint8_t *b, size_t n)
{
    for (size_t i = 0; i < n; ++i) printf("%02x", b[i]);
}

static void print_value(const iii_constant_info_t *e)
{
    switch (e->type_tag) {
    case III_CT_U64: {
        uint64_t v = 0;
        for (int k = 0; k < 8; ++k) v |= ((uint64_t)e->value_bytes[k]) << (8*k);
        printf("%" PRIu64 " (0x%" PRIx64 ")", v, v);
        break;
    }
    case III_CT_S64: {
        uint64_t v = 0;
        for (int k = 0; k < 8; ++k) v |= ((uint64_t)e->value_bytes[k]) << (8*k);
        printf("%" PRId64, (int64_t)v);
        break;
    }
    case III_CT_Q14: {
        int16_t v = (int16_t)((uint16_t)e->value_bytes[0]
                            | ((uint16_t)e->value_bytes[1] << 8));
        printf("%d (Q14 ≈ %.5f)", v, (double)v / 16384.0);
        break;
    }
    case III_CT_BAND:
    case III_CT_TUPLE2: {
        uint32_t a = (uint32_t)e->value_bytes[0]
                   | ((uint32_t)e->value_bytes[1] << 8)
                   | ((uint32_t)e->value_bytes[2] << 16)
                   | ((uint32_t)e->value_bytes[3] << 24);
        uint32_t b = (uint32_t)e->value_bytes[4]
                   | ((uint32_t)e->value_bytes[5] << 8)
                   | ((uint32_t)e->value_bytes[6] << 16)
                   | ((uint32_t)e->value_bytes[7] << 24);
        if (e->type_tag == III_CT_BAND)
            printf("0x%04x..0x%04x (%u slots)", a, b, b - a + 1);
        else
            printf("(%u, %u)", a, b);
        break;
    }
    case III_CT_BOOL:
        printf("%s", e->value_bytes[0] ? "true" : "false");
        break;
    case III_CT_STRING:
        fputc('"', stdout);
        fwrite(e->value_bytes, 1, e->value_len, stdout);
        fputc('"', stdout);
        break;
    case III_CT_BYTES:
        printf("0x");
        hex_print(e->value_bytes, e->value_len);
        break;
    }
}

static void print_entry(const iii_constant_info_t *e)
{
    printf("[%04u] %-44s %-7s %-19s %s ", e->hash_slot, e->name,
           iii_constant_type_str(e->type_tag),
           iii_constant_tier_str(e->mutation_tier),
           e->section);
    print_value(e);
    printf("  (%s, units=%s)\n", e->source, e->units);
}

static int cmd_dump(void)
{
    size_t n = iii_constant_count();
    for (uint32_t i = 1; i <= n; ++i) print_entry(iii_constant_at(i));
    printf("--\ntotal=%zu\n", n);
    return 0;
}

static int cmd_lookup(const char *name)
{
    const iii_constant_info_t *e = iii_constant_lookup(name);
    if (!e) { fprintf(stderr, "not found: %s\n", name); return 1; }
    print_entry(e);
    return 0;
}

static int cmd_root(void)
{
    char hex[65];
    iii_constant_compute_ledger_root_hex(hex);
    printf("R1.D2 (constants ledger root) = %s\n", hex);
    return 0;
}

/* ---- value parsing for validate ---- */

static int parse_int(const char *s, int64_t *out)
{
    char *end = NULL;
    int base = 10;
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) base = 16;
    long long v = strtoll(s, &end, base);
    if (end == s || *end != '\0') return -1;
    *out = (int64_t)v;
    return 0;
}

static void enc_u64(uint64_t v, uint8_t out[8])
{
    for (int k = 0; k < 8; ++k) out[k] = (uint8_t)((v >> (8*k)) & 0xFF);
}

static int hex_nibble(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int encode_new_value(const iii_constant_info_t *e, const char *s,
                            uint8_t *buf, size_t buf_cap, size_t *out_len)
{
    switch (e->type_tag) {
    case III_CT_U64: case III_CT_S64: {
        int64_t v;
        if (parse_int(s, &v) != 0) return -1;
        if (buf_cap < 8) return -1;
        enc_u64((uint64_t)v, buf);
        *out_len = 8;
        return 0;
    }
    case III_CT_Q14: {
        int64_t v;
        if (parse_int(s, &v) != 0) return -1;
        if (buf_cap < 2) return -1;
        buf[0] = (uint8_t)((uint64_t)v & 0xFF);
        buf[1] = (uint8_t)(((uint64_t)v >> 8) & 0xFF);
        *out_len = 2;
        return 0;
    }
    case III_CT_BAND: case III_CT_TUPLE2: {
        const char *comma = strchr(s, ',');
        if (!comma) return -1;
        char lhs[32];
        size_t llen = (size_t)(comma - s);
        if (llen >= sizeof(lhs)) return -1;
        memcpy(lhs, s, llen); lhs[llen] = '\0';
        int64_t lo, hi;
        if (parse_int(lhs, &lo) != 0) return -1;
        if (parse_int(comma + 1, &hi) != 0) return -1;
        if (buf_cap < 8) return -1;
        uint32_t a = (uint32_t)lo, b = (uint32_t)hi;
        for (int k = 0; k < 4; ++k) buf[k]   = (uint8_t)((a >> (8*k)) & 0xFF);
        for (int k = 0; k < 4; ++k) buf[4+k] = (uint8_t)((b >> (8*k)) & 0xFF);
        *out_len = 8;
        return 0;
    }
    case III_CT_BOOL: {
        if (!strcmp(s, "true") || !strcmp(s, "1"))  { buf[0] = 1; *out_len = 1; return 0; }
        if (!strcmp(s, "false") || !strcmp(s, "0")) { buf[0] = 0; *out_len = 1; return 0; }
        return -1;
    }
    case III_CT_STRING: {
        size_t n = strlen(s);
        if (n > buf_cap) return -1;
        memcpy(buf, s, n);
        *out_len = n;
        return 0;
    }
    case III_CT_BYTES: {
        size_t n = strlen(s);
        if (n & 1) return -1;
        size_t ob = n / 2;
        if (ob > buf_cap) return -1;
        for (size_t i = 0; i < ob; ++i) {
            int hi = hex_nibble((unsigned char)s[2*i]);
            int lo = hex_nibble((unsigned char)s[2*i+1]);
            if (hi < 0 || lo < 0) return -1;
            buf[i] = (uint8_t)((hi << 4) | lo);
        }
        *out_len = ob;
        return 0;
    }
    }
    return -1;
}

static int cmd_validate(const char *path, const char *name, const char *value)
{
    const iii_constant_info_t *e = iii_constant_lookup(name);
    if (!e) { printf("validate: %s\n", iii_constant_validate_str(III_CV_NOT_FOUND)); return 1; }

    uint8_t buf[1024];
    size_t  buf_n = 0;
    if (encode_new_value(e, value, buf, sizeof(buf), &buf_n) != 0) {
        printf("validate: INVALID_VALUE (parse failure for type=%s)\n",
               iii_constant_type_str(e->type_tag));
        return 1;
    }

    iii_constant_validate_t r;
    if      (!strcmp(path, "catalyst-append")) r = iii_constant_validate_catalyst_append(name, buf, buf_n);
    else if (!strcmp(path, "amend-apply"))     r = iii_constant_validate_amend_apply(name, buf, buf_n);
    else if (!strcmp(path, "r2-bump"))         r = iii_constant_validate_r2_bump(name, buf, buf_n);
    else { fprintf(stderr, "unknown path: %s\n", path); return 2; }

    printf("validate %s on %s -> %s\n", path, name, iii_constant_validate_str(r));
    return r == III_CV_OK ? 0 : 1;
}

static int usage(void)
{
    fprintf(stderr,
        "usage: iii_constants_tool <command> [args]\n"
        "  dump\n"
        "  lookup <NAME>\n"
        "  root\n"
        "  validate <catalyst-append|amend-apply|r2-bump> <NAME> <NEW_VALUE>\n");
    return 2;
}

int main(int argc, char **argv)
{
    if (argc < 2) return usage();
    if (!strcmp(argv[1], "dump"))   return cmd_dump();
    if (!strcmp(argv[1], "root"))   return cmd_root();
    if (!strcmp(argv[1], "lookup")) {
        if (argc < 3) return usage();
        return cmd_lookup(argv[2]);
    }
    if (!strcmp(argv[1], "validate")) {
        if (argc < 5) return usage();
        return cmd_validate(argv[2], argv[3], argv[4]);
    }
    return usage();
}
