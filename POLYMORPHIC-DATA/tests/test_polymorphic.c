#include "iii/polymorphic.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_size(void) {
    SECTION("§1 layout");
    TEST(sizeof(iii_glyph_t) == 192);
    TEST(III_GLYPH_BYTES == 192);
    TEST(III_GLYPH_PAYLOAD_BYTES == 191);
}

static void test_constructors(void) {
    SECTION("§1.6 constructors");
    iii_glyph_t g;
    g = iii_glyph_null();
    TEST(g.type_tag == III_FORM_NULL);

    g = iii_glyph_int64(-42);
    TEST(g.type_tag == III_FORM_INTEGER_64);
    TEST(iii_glyph_get_int64(&g) == -42);

    g = iii_glyph_int64(INT64_MAX);
    TEST(iii_glyph_get_int64(&g) == INT64_MAX);

    g = iii_glyph_timestamp(1234567890ull);
    TEST(g.type_tag == III_FORM_TIMESTAMP);
    TEST(iii_glyph_get_timestamp(&g) == 1234567890ull);

    bool emb;
    g = iii_glyph_string("Hello, World!", 13, &emb);
    TEST(emb);
    TEST(g.type_tag == III_FORM_STRING_UTF8);
    char out[32]; size_t len;
    TEST(iii_glyph_get_string(&g, out, sizeof(out), &len));
    TEST(len == 13);
    TEST(strcmp(out, "Hello, World!") == 0);

    uint8_t hash[32]; for (unsigned i = 0; i < 32; ++i) hash[i] = (uint8_t)(i + 0x80);
    g = iii_glyph_mhash(hash);
    TEST(g.type_tag == III_FORM_MHASH);
    uint8_t back[32];
    TEST(iii_glyph_get_mhash(&g, back));
    TEST(memcmp(hash, back, 32) == 0);

    int8_t pillars[6] = {1, -1, 0, 1, 0, -1};
    g = iii_glyph_hexad(pillars);
    TEST(g.type_tag == III_FORM_HEXAD);
    TEST(g.payload[0] == 2 && g.payload[1] == 0 && g.payload[2] == 1);

    g = iii_glyph_extension(0xABCD);
    TEST(g.type_tag == III_FORM_EXTENSION);
    TEST(g.payload[0] == 0xAB && g.payload[1] == 0xCD);

    /* Names */
    TEST(strcmp(iii_glyph_form_name(III_FORM_INTEGER_64), "INTEGER_64") == 0);
    TEST(strcmp(iii_glyph_form_name(III_FORM_OPERATOR_INTENT), "OPERATOR_INTENT") == 0);
    TEST(strcmp(iii_glyph_form_name(III_FORM_EXTENSION), "EXTENSION") == 0);
}

static void test_canonical(void) {
    SECTION("§3 canonical");
    iii_glyph_t a = iii_glyph_int64(42);
    uint8_t buf[256];
    size_t n = iii_glyph_canonical_encode(&a, buf, sizeof(buf));
    TEST(n == III_GLYPH_BYTES);
    TEST(buf[0] == III_FORM_INTEGER_64);

    iii_glyph_t b;
    size_t consumed = iii_glyph_canonical_decode(buf, n, &b);
    TEST(consumed == III_GLYPH_BYTES);
    TEST(b.type_tag == a.type_tag);
    TEST(memcmp(b.payload, a.payload, III_GLYPH_PAYLOAD_BYTES) == 0);

    /* mhash is deterministic */
    uint8_t h1[32], h2[32];
    iii_glyph_canonical_mhash(&a, h1);
    iii_glyph_canonical_mhash(&b, h2);
    TEST(memcmp(h1, h2, 32) == 0);
}

static void test_detect(void) {
    SECTION("§2 encoding detection");
    TEST(iii_detect_encoding((const uint8_t *)"{\"a\":1}", 7) == III_ENC_JSON);
    TEST(iii_detect_encoding((const uint8_t *)"[1,2,3]", 7) == III_ENC_JSON);
    TEST(iii_detect_encoding((const uint8_t *)"<?xml version='1.0'?>", 21) == III_ENC_XML);
    TEST(iii_detect_encoding((const uint8_t *)"PK\x03\x04", 4) == III_ENC_ZIP);

    /* Glyph V3 detection: exactly 192 bytes with valid form id. */
    uint8_t g[192]; memset(g, 0, sizeof(g));
    g[0] = 0x01;
    TEST(iii_detect_encoding(g, 192) == III_ENC_GLYPH_V3);
}

static void test_json(void) {
    SECTION("§2 JSON parser");
    iii_glyph_t g;
    const char *s1 = "42";
    TEST(iii_json_parse((const uint8_t *)s1, strlen(s1), &g) == 2);
    TEST(g.type_tag == III_FORM_INTEGER_64);
    TEST(iii_glyph_get_int64(&g) == 42);

    const char *s2 = "\"hi\"";
    TEST(iii_json_parse((const uint8_t *)s2, strlen(s2), &g) == 4);
    TEST(g.type_tag == III_FORM_STRING_UTF8);

    const char *s3 = "null";
    TEST(iii_json_parse((const uint8_t *)s3, strlen(s3), &g) == 4);
    TEST(g.type_tag == III_FORM_NULL);

    const char *s4 = "true";
    TEST(iii_json_parse((const uint8_t *)s4, strlen(s4), &g) == 4);
    TEST(iii_glyph_get_int64(&g) == 1);

    const char *s5 = "[1, 2, 3]";
    TEST(iii_json_parse((const uint8_t *)s5, strlen(s5), &g) > 0);
    TEST(g.type_tag == III_FORM_LIST);

    const char *s6 = "{\"a\": 1, \"b\": \"hello\", \"c\": [1,2,3]}";
    TEST(iii_json_parse((const uint8_t *)s6, strlen(s6), &g) > 0);
    TEST(g.type_tag == III_FORM_MAP);

    /* Empty array / object */
    const char *s7 = "[]";
    TEST(iii_json_parse((const uint8_t *)s7, 2, &g) == 2);
    TEST(g.type_tag == III_FORM_LIST);

    const char *s8 = "{}";
    TEST(iii_json_parse((const uint8_t *)s8, 2, &g) == 2);
    TEST(g.type_tag == III_FORM_MAP);

    /* Negative number */
    const char *s9 = "-100";
    TEST(iii_json_parse((const uint8_t *)s9, 4, &g) == 4);
    TEST(iii_glyph_get_int64(&g) == -100);
}

static int test_int_handler(const iii_glyph_t *g, void *u);
static int test_str_handler(const iii_glyph_t *g, void *u);

static void test_dispatch(void) {
    SECTION("§4 dispatch");
    iii_glyph_dispatch_t d;
    iii_glyph_dispatch_init(&d);

    static int int_count = 0;
    static int str_count = 0;
    iii_glyph_dispatch_register(&d, III_FORM_INTEGER_64, test_int_handler, &int_count);
    iii_glyph_dispatch_register(&d, III_FORM_STRING_UTF8, test_str_handler, &str_count);

    iii_glyph_t a = iii_glyph_int64(99);
    TEST(iii_glyph_dispatch_invoke(&d, &a) == 1);
    iii_glyph_t b = iii_glyph_string("x", 1, NULL);
    TEST(iii_glyph_dispatch_invoke(&d, &b) == 2);
    /* Unhandled form */
    iii_glyph_t c = iii_glyph_null();
    TEST(iii_glyph_dispatch_invoke(&d, &c) == -2);
}

static int test_int_handler(const iii_glyph_t *g, void *u) { (void)g; (*(int *)u)++; return 1; }
static int test_str_handler(const iii_glyph_t *g, void *u) { (void)g; (*(int *)u)++; return 2; }

static void test_cons(void) {
    SECTION("§5 hash-cons");
    iii_glyph_cons_t *c = iii_glyph_cons_create(64);
    iii_glyph_t a = iii_glyph_int64(123);
    iii_glyph_t b = iii_glyph_int64(123);
    iii_glyph_t d = iii_glyph_int64(456);

    bool hit;
    iii_glyph_handle_t h1 = iii_glyph_cons_insert(c, &a, &hit);
    TEST(h1 != 0);
    TEST(!hit);

    iii_glyph_handle_t h2 = iii_glyph_cons_insert(c, &b, &hit);
    TEST(h2 == h1);   /* same canonical form */
    TEST(hit);

    iii_glyph_handle_t h3 = iii_glyph_cons_insert(c, &d, &hit);
    TEST(h3 != h1);
    TEST(!hit);

    iii_glyph_t out;
    TEST(iii_glyph_cons_lookup(c, h1, &out));
    TEST(iii_glyph_get_int64(&out) == 123);

    TEST(iii_glyph_cons_hits(c) == 1);
    TEST(iii_glyph_cons_misses(c) == 2);

    iii_glyph_cons_destroy(c);
}

static void test_streaming(void) {
    SECTION("§6 streaming");
    iii_stream_runtime_t *rt = iii_stream_runtime_create();
    iii_stream_id_t id = iii_stream_create(rt, 0, 64);
    TEST(id != 0);

    const char *part1 = "Hello, ";
    const char *part2 = "World!";
    TEST(iii_stream_append(rt, id, (const uint8_t *)part1, strlen(part1)));
    TEST(iii_stream_append(rt, id, (const uint8_t *)part2, strlen(part2)));
    TEST(iii_stream_chunk_count(rt, id) == 2);

    uint8_t buf[64]; size_t n;
    n = iii_stream_read(rt, id, 0, buf, sizeof(buf));
    TEST(n == 13);
    TEST(memcmp(buf, "Hello, World!", 13) == 0);

    /* Read with offset */
    n = iii_stream_read(rt, id, 7, buf, sizeof(buf));
    TEST(n == 6);
    TEST(memcmp(buf, "World!", 6) == 0);

    TEST(iii_stream_close(rt, id));
    TEST(iii_stream_is_closed(rt, id));
    TEST(!iii_stream_append(rt, id, (const uint8_t *)"x", 1));

    iii_stream_runtime_destroy(rt);
}

int main(void) {
    test_size();
    test_constructors();
    test_canonical();
    test_detect();
    test_json();
    test_dispatch();
    test_cons();
    test_streaming();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
