/* III-POLYMORPHIC-DATA — implementation. */
#include "iii/polymorphic.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

/* ----------------------------------------------------------------------------
 * Names
 * ---------------------------------------------------------------------------- */

const char *iii_glyph_form_name(iii_glyph_form_t f) {
    switch (f) {
        case III_FORM_NULL:               return "NULL";
        case III_FORM_INTEGER_64:         return "INTEGER_64";
        case III_FORM_INTEGER_BIG:        return "INTEGER_BIG";
        case III_FORM_RATIONAL_64:        return "RATIONAL_64";
        case III_FORM_RATIONAL_BIG:       return "RATIONAL_BIG";
        case III_FORM_TRIT:               return "TRIT";
        case III_FORM_HEXAD:              return "HEXAD";
        case III_FORM_MHASH:              return "MHASH";
        case III_FORM_TIMESTAMP:          return "TIMESTAMP";
        case III_FORM_STRING_UTF8:        return "STRING_UTF8";
        case III_FORM_BYTES:              return "BYTES";
        case III_FORM_LIST:               return "LIST";
        case III_FORM_MAP:                return "MAP";
        case III_FORM_OPTION:             return "OPTION";
        case III_FORM_RESULT:             return "RESULT";
        case III_FORM_TUPLE:              return "TUPLE";
        case III_FORM_RECORD:             return "RECORD";
        case III_FORM_ENUM_VARIANT:       return "ENUM_VARIANT";
        case III_FORM_FN_POINTER:         return "FN_POINTER";
        case III_FORM_CAP:                return "CAP";
        case III_FORM_WITNESS_HANDLE:     return "WITNESS_HANDLE";
        case III_FORM_GLYPH_HANDLE:       return "GLYPH_HANDLE";
        case III_FORM_REDUCTION_HANDLE:   return "REDUCTION_HANDLE";
        case III_FORM_PROOF_HANDLE:       return "PROOF_HANDLE";
        case III_FORM_SANCTUM_HANDLE:     return "SANCTUM_HANDLE";
        case III_FORM_ARCH_BINARY:        return "ARCH_BINARY";
        case III_FORM_LEGACY_BINARY:      return "LEGACY_BINARY";
        case III_FORM_LEGACY_FILE_HANDLE: return "LEGACY_FILE_HANDLE";
        case III_FORM_NETWORK_PACKET:     return "NETWORK_PACKET";
        case III_FORM_CRYPTO_KEY:         return "CRYPTO_KEY";
        case III_FORM_CRYPTO_SIG:         return "CRYPTO_SIG";
        case III_FORM_ZK_PROOF:           return "ZK_PROOF";
        case III_FORM_ROLLUP_HANDLE:      return "ROLLUP_HANDLE";
        case III_FORM_CAUSAL_DAG_NODE:    return "CAUSAL_DAG_NODE";
        case III_FORM_JIT_REGION_HANDLE:  return "JIT_REGION_HANDLE";
        case III_FORM_OBS_THRESHOLD:      return "OBS_THRESHOLD";
        case III_FORM_FED_PEER_HANDLE:    return "FED_PEER_HANDLE";
        case III_FORM_OPERATOR_INTENT:    return "OPERATOR_INTENT";
        case III_FORM_EXTENSION:          return "EXTENSION";
        default:                          return "RESERVED";
    }
}

const char *iii_encoding_name(iii_encoding_t e) {
    switch (e) {
        case III_ENC_GLYPH_V3:  return "glyph-v3";
        case III_ENC_JSON:      return "json";
        case III_ENC_CBOR:      return "cbor";
        case III_ENC_MSGPACK:   return "msgpack";
        case III_ENC_TOML:      return "toml";
        case III_ENC_INI:       return "ini";
        case III_ENC_XML:       return "xml";
        case III_ENC_YAML:      return "yaml";
        case III_ENC_PROTOBUF:  return "protobuf";
        case III_ENC_BSON:      return "bson";
        case III_ENC_AVRO:      return "avro";
        case III_ENC_ASN1:      return "asn1";
        case III_ENC_TAR:       return "tar";
        case III_ENC_ZIP:       return "zip";
        case III_ENC_HDF5:      return "hdf5";
        case III_ENC_PARQUET:   return "parquet";
        default:                return "unknown";
    }
}

const char *iii_poly_witness_kind_name(iii_poly_witness_kind_t k) {
    switch (k) {
        case III_POLYW_GLYPH_CONS_HIT:    return "glyph-cons-hit";
        case III_POLYW_GLYPH_CONS_MISS:   return "glyph-cons-miss";
        case III_POLYW_DESERIALIZE:       return "poly-deserialize";
        case III_POLYW_SERIALIZE:         return "poly-serialize";
        case III_POLYW_DISPATCH:          return "poly-dispatch";
        case III_POLYW_STREAM_CREATE:     return "stream-create";
        case III_POLYW_STREAM_APPEND:     return "stream-append";
        case III_POLYW_STREAM_CLOSE:      return "stream-close";
        case III_POLYW_CANONICAL_MISMATCH:return "canonical-mismatch";
        default:                          return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * §1 — constructors
 * ---------------------------------------------------------------------------- */

iii_glyph_t iii_glyph_null(void) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_NULL;
    return g;
}

static void put_be64(uint8_t *p, uint64_t v) {
    for (unsigned i = 0; i < 8; ++i) p[i] = (uint8_t)(v >> ((7 - i) * 8));
}

static uint64_t get_be64(const uint8_t *p) {
    uint64_t v = 0;
    for (unsigned i = 0; i < 8; ++i) v = (v << 8) | p[i];
    return v;
}

static void put_be32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >>  8);
    p[3] = (uint8_t)(v);
}

static uint32_t get_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] <<  8) |  (uint32_t)p[3];
}

iii_glyph_t iii_glyph_int64(int64_t value) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_INTEGER_64;
    put_be64(g.payload, (uint64_t)value);
    return g;
}

iii_glyph_t iii_glyph_trit(int8_t v) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_TRIT;
    g.payload[0] = (v < 0) ? 0 : (v == 0) ? 1 : 2;
    return g;
}

iii_glyph_t iii_glyph_hexad(const int8_t pillars[6]) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_HEXAD;
    for (unsigned i = 0; i < 6; ++i) {
        g.payload[i] = (pillars[i] < 0) ? 0 : (pillars[i] == 0) ? 1 : 2;
    }
    return g;
}

iii_glyph_t iii_glyph_mhash(const uint8_t hash[32]) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_MHASH;
    if (hash) memcpy(g.payload, hash, 32);
    return g;
}

iii_glyph_t iii_glyph_timestamp(uint64_t ts) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_TIMESTAMP;
    put_be64(g.payload, ts);
    return g;
}

iii_glyph_t iii_glyph_string(const char *s, size_t len, bool *embedded) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_STRING_UTF8;
    if (len <= III_GLYPH_PAYLOAD_BYTES - 4u) {
        if (embedded) *embedded = true;
        put_be32(g.payload, (uint32_t)len);
        if (s && len) memcpy(g.payload + 4, s, len);
    } else {
        if (embedded) *embedded = false;
        /* Caller should allocate an extended glyph and pass GLYPH_HANDLE. */
        put_be32(g.payload, (uint32_t)len);
    }
    return g;
}

iii_glyph_t iii_glyph_bytes(const uint8_t *b, size_t len, bool *embedded) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_BYTES;
    if (len <= III_GLYPH_PAYLOAD_BYTES - 4u) {
        if (embedded) *embedded = true;
        put_be32(g.payload, (uint32_t)len);
        if (b && len) memcpy(g.payload + 4, b, len);
    } else {
        if (embedded) *embedded = false;
        put_be32(g.payload, (uint32_t)len);
    }
    return g;
}

iii_glyph_t iii_glyph_glyph_handle(uint32_t handle) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_GLYPH_HANDLE;
    put_be32(g.payload, handle);
    return g;
}

iii_glyph_t iii_glyph_witness_handle(uint32_t handle) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_WITNESS_HANDLE;
    put_be32(g.payload, handle);
    return g;
}

iii_glyph_t iii_glyph_extension(uint16_t extended_id) {
    iii_glyph_t g; memset(&g, 0, sizeof(g));
    g.type_tag = III_FORM_EXTENSION;
    g.payload[0] = (uint8_t)(extended_id >> 8);
    g.payload[1] = (uint8_t)(extended_id);
    return g;
}

/* Accessors */

int64_t iii_glyph_get_int64(const iii_glyph_t *g) {
    if (!g || g->type_tag != III_FORM_INTEGER_64) return 0;
    return (int64_t)get_be64(g->payload);
}

uint64_t iii_glyph_get_timestamp(const iii_glyph_t *g) {
    if (!g || g->type_tag != III_FORM_TIMESTAMP) return 0;
    return get_be64(g->payload);
}

bool iii_glyph_get_string(const iii_glyph_t *g, char *out, size_t cap, size_t *out_len) {
    if (!g || g->type_tag != III_FORM_STRING_UTF8) return false;
    uint32_t len = get_be32(g->payload);
    if (out_len) *out_len = len;
    if (!out || cap == 0) return true;
    size_t take = (len < cap - 1u) ? len : cap - 1u;
    memcpy(out, g->payload + 4, take);
    out[take] = '\0';
    return true;
}

bool iii_glyph_get_bytes(const iii_glyph_t *g, uint8_t *out, size_t cap, size_t *out_len) {
    if (!g || g->type_tag != III_FORM_BYTES) return false;
    uint32_t len = get_be32(g->payload);
    if (out_len) *out_len = len;
    if (!out) return true;
    size_t take = (len < cap) ? len : cap;
    memcpy(out, g->payload + 4, take);
    return true;
}

bool iii_glyph_get_mhash(const iii_glyph_t *g, uint8_t out[32]) {
    if (!g || g->type_tag != III_FORM_MHASH) return false;
    if (out) memcpy(out, g->payload, 32);
    return true;
}

/* ----------------------------------------------------------------------------
 * §3 — canonical encoding (we encode as: 1 byte tag + entire 191 byte payload).
 * Multi-byte numerics are already big-endian; strings/bytes are length-prefixed.
 * ---------------------------------------------------------------------------- */

size_t iii_glyph_canonical_encode(const iii_glyph_t *g, uint8_t *out, size_t cap) {
    if (!g || cap < III_GLYPH_BYTES) return 0;
    out[0] = g->type_tag;
    memcpy(out + 1, g->payload, III_GLYPH_PAYLOAD_BYTES);
    return III_GLYPH_BYTES;
}

size_t iii_glyph_canonical_decode(const uint8_t *in, size_t in_len, iii_glyph_t *out) {
    if (!in || !out || in_len < III_GLYPH_BYTES) return 0;
    out->type_tag = in[0];
    memcpy(out->payload, in + 1, III_GLYPH_PAYLOAD_BYTES);
    return III_GLYPH_BYTES;
}

void iii_glyph_canonical_mhash(const iii_glyph_t *g, uint8_t out[32]) {
    if (!g || !out) { if (out) memset(out, 0, 32); return; }
    uint8_t buf[III_GLYPH_BYTES];
    iii_glyph_canonical_encode(g, buf, sizeof(buf));
    iii_sha256(buf, sizeof(buf), out);
}

/* ----------------------------------------------------------------------------
 * §2 — encoding detection
 * ---------------------------------------------------------------------------- */
iii_encoding_t iii_detect_encoding(const uint8_t *data, size_t len) {
    if (!data || len == 0) return III_ENC_UNKNOWN;
    /* Glyph V3: first byte is a known form id < 0x26 or == 0xFF, AND length is
     * exactly 192. */
    if (len == III_GLYPH_BYTES && (data[0] <= 0x25 || data[0] == 0xFF)) {
        return III_ENC_GLYPH_V3;
    }
    /* JSON: starts with '{', '[', '"', whitespace, number, t/f/n. */
    {
        size_t i = 0;
        while (i < len && (data[i] == ' ' || data[i] == '\t' || data[i] == '\n' || data[i] == '\r')) ++i;
        if (i < len) {
            uint8_t c = data[i];
            if (c == '{' || c == '[' || c == '"' || c == '-' || (c >= '0' && c <= '9')
                || c == 't' || c == 'f' || c == 'n') {
                return III_ENC_JSON;
            }
        }
    }
    /* XML */
    if (len >= 5 && memcmp(data, "<?xml", 5) == 0) return III_ENC_XML;
    /* TAR (ustar) */
    if (len >= 263 && memcmp(data + 257, "ustar", 5) == 0) return III_ENC_TAR;
    /* ZIP */
    if (len >= 4 && data[0] == 'P' && data[1] == 'K' && data[2] == 0x03 && data[3] == 0x04) return III_ENC_ZIP;
    /* HDF5 */
    if (len >= 8 && memcmp(data, "\x89HDF\r\n\x1a\n", 8) == 0) return III_ENC_HDF5;
    /* Parquet (header magic) */
    if (len >= 4 && memcmp(data, "PAR1", 4) == 0) return III_ENC_PARQUET;
    /* MessagePack: heuristic - leading byte distinct values */
    if (len >= 1) {
        uint8_t b = data[0];
        if (b == 0xC0 || b == 0xC2 || b == 0xC3 || (b >= 0x80 && b <= 0x8F)
            || (b >= 0x90 && b <= 0x9F) || (b >= 0xA0 && b <= 0xBF)) {
            return III_ENC_MSGPACK;
        }
    }
    return III_ENC_UNKNOWN;
}

/* ----------------------------------------------------------------------------
 * §2 — JSON parser (NIH).  Subset: null, true, false, numbers (i64), strings
 * (no escapes beyond \", \\, \n, \t, \r), arrays, objects.
 * ---------------------------------------------------------------------------- */

typedef struct js {
    const uint8_t *p;
    const uint8_t *end;
} js_t;

static void js_skip_ws(js_t *j) {
    while (j->p < j->end && (*j->p == ' ' || *j->p == '\t' || *j->p == '\n' || *j->p == '\r')) j->p++;
}

static bool js_match(js_t *j, const char *kw) {
    size_t n = strlen(kw);
    if ((size_t)(j->end - j->p) < n) return false;
    if (memcmp(j->p, kw, n) != 0) return false;
    j->p += n;
    return true;
}

static int js_read_int64(js_t *j, int64_t *out) {
    const uint8_t *start = j->p;
    bool neg = false;
    if (j->p < j->end && *j->p == '-') { neg = true; j->p++; }
    if (j->p >= j->end || *j->p < '0' || *j->p > '9') return 0;
    int64_t val = 0;
    while (j->p < j->end && *j->p >= '0' && *j->p <= '9') {
        val = val * 10 + (*j->p - '0');
        j->p++;
    }
    if (j->p < j->end && (*j->p == '.' || *j->p == 'e' || *j->p == 'E')) {
        /* Floating-point — currently unsupported; revert. */
        j->p = start;
        return 0;
    }
    *out = neg ? -val : val;
    return 1;
}

static int js_read_string(js_t *j, char *buf, size_t cap, size_t *out_len) {
    if (j->p >= j->end || *j->p != '"') return 0;
    j->p++;
    size_t n = 0;
    while (j->p < j->end && *j->p != '"') {
        if (*j->p == '\\' && j->p + 1 < j->end) {
            j->p++;
            char c;
            switch (*j->p) {
                case '"':  c = '"'; break;
                case '\\': c = '\\'; break;
                case '/':  c = '/';  break;
                case 'n':  c = '\n'; break;
                case 't':  c = '\t'; break;
                case 'r':  c = '\r'; break;
                case 'b':  c = '\b'; break;
                case 'f':  c = '\f'; break;
                default:   c = (char)*j->p; break;
            }
            if (n < cap) buf[n] = c;
            n++;
            j->p++;
        } else {
            if (n < cap) buf[n] = (char)*j->p;
            n++;
            j->p++;
        }
    }
    if (j->p >= j->end) return 0;
    j->p++; /* consume closing " */
    *out_len = n;
    return 1;
}

static int js_value(js_t *j, iii_glyph_t *out);

static int js_value(js_t *j, iii_glyph_t *out) {
    js_skip_ws(j);
    if (j->p >= j->end) return 0;

    if (js_match(j, "null"))  { *out = iii_glyph_null(); return 1; }
    if (js_match(j, "true"))  { *out = iii_glyph_int64(1); return 1; }
    if (js_match(j, "false")) { *out = iii_glyph_int64(0); return 1; }

    if (*j->p == '"') {
        char buf[III_GLYPH_PAYLOAD_BYTES - 4];
        size_t len = 0;
        if (!js_read_string(j, buf, sizeof(buf), &len)) return 0;
        *out = iii_glyph_string(buf, len, NULL);
        return 1;
    }

    if (*j->p == '-' || (*j->p >= '0' && *j->p <= '9')) {
        int64_t v = 0;
        if (!js_read_int64(j, &v)) return 0;
        *out = iii_glyph_int64(v);
        return 1;
    }

    if (*j->p == '[') {
        /* Encode as LIST with embedded count; we store the count and the first
         * up-to-N children inline as 16-byte mhash slots.  For simplicity we
         * record only the count and treat children as parsed and discarded. */
        j->p++;
        uint32_t count = 0;
        js_skip_ws(j);
        if (j->p < j->end && *j->p == ']') { j->p++; *out = iii_glyph_null();
            out->type_tag = III_FORM_LIST; put_be32(out->payload, 0); return 1; }
        for (;;) {
            iii_glyph_t child;
            if (!js_value(j, &child)) return 0;
            count++;
            js_skip_ws(j);
            if (j->p < j->end && *j->p == ',') { j->p++; continue; }
            if (j->p < j->end && *j->p == ']') { j->p++; break; }
            return 0;
        }
        memset(out, 0, sizeof(*out));
        out->type_tag = III_FORM_LIST;
        put_be32(out->payload, count);
        return 1;
    }

    if (*j->p == '{') {
        j->p++;
        uint32_t count = 0;
        js_skip_ws(j);
        if (j->p < j->end && *j->p == '}') { j->p++; *out = iii_glyph_null();
            out->type_tag = III_FORM_MAP; put_be32(out->payload, 0); return 1; }
        for (;;) {
            char keybuf[64]; size_t klen = 0;
            js_skip_ws(j);
            if (!js_read_string(j, keybuf, sizeof(keybuf), &klen)) return 0;
            js_skip_ws(j);
            if (j->p >= j->end || *j->p != ':') return 0;
            j->p++;
            iii_glyph_t child;
            if (!js_value(j, &child)) return 0;
            count++;
            js_skip_ws(j);
            if (j->p < j->end && *j->p == ',') { j->p++; continue; }
            if (j->p < j->end && *j->p == '}') { j->p++; break; }
            return 0;
        }
        memset(out, 0, sizeof(*out));
        out->type_tag = III_FORM_MAP;
        put_be32(out->payload, count);
        return 1;
    }

    return 0;
}

size_t iii_json_parse(const uint8_t *in, size_t in_len, iii_glyph_t *out) {
    if (!in || !out) return 0;
    js_t j; j.p = in; j.end = in + in_len;
    if (!js_value(&j, out)) return 0;
    js_skip_ws(&j);
    return (size_t)(j.p - in);
}

/* ----------------------------------------------------------------------------
 * Serde registration table
 * ---------------------------------------------------------------------------- */
static iii_serde_fn  g_serde_fns[17] = {0};
static void         *g_serde_users[17] = {0};

bool iii_serde_register(iii_encoding_t e, iii_serde_fn fn, void *user) {
    if ((unsigned)e >= 17u) return false;
    g_serde_fns[e]  = fn;
    g_serde_users[e] = user;
    return true;
}

size_t iii_serde_deserialize(iii_encoding_t e,
                             const uint8_t *in, size_t in_len,
                             iii_glyph_t *out)
{
    if (!in || !out) return 0;
    if (e == III_ENC_GLYPH_V3) return iii_glyph_canonical_decode(in, in_len, out);
    if (e == III_ENC_JSON)     return iii_json_parse(in, in_len, out);
    if ((unsigned)e < 17u && g_serde_fns[e]) {
        return g_serde_fns[e](in, in_len, out, g_serde_users[e]);
    }
    return 0;
}

/* ----------------------------------------------------------------------------
 * §5 — hash-consing
 * ---------------------------------------------------------------------------- */
struct iii_glyph_cons {
    iii_glyph_t  *glyphs;
    uint8_t      *mhashes;     /* 32 bytes per slot */
    uint32_t      capacity;
    uint32_t      count;
    uint32_t      hits;
    uint32_t      misses;
};

iii_glyph_cons_t *iii_glyph_cons_create(uint32_t capacity) {
    if (capacity == 0) capacity = 1024u;
    iii_glyph_cons_t *c = (iii_glyph_cons_t *)calloc(1, sizeof(*c));
    if (!c) return NULL;
    c->capacity = capacity;
    c->glyphs   = (iii_glyph_t *)calloc(capacity, sizeof(iii_glyph_t));
    c->mhashes  = (uint8_t *)calloc(capacity, 32);
    if (!c->glyphs || !c->mhashes) { iii_glyph_cons_destroy(c); return NULL; }
    return c;
}

void iii_glyph_cons_destroy(iii_glyph_cons_t *c) {
    if (!c) return;
    free(c->glyphs);
    free(c->mhashes);
    free(c);
}

iii_glyph_handle_t iii_glyph_cons_insert(iii_glyph_cons_t *c,
                                         const iii_glyph_t *g,
                                         bool *was_hit)
{
    if (!c || !g) return 0;
    uint8_t mh[32];
    iii_glyph_canonical_mhash(g, mh);
    /* Linear scan for now (capacity bounded). */
    for (uint32_t i = 0; i < c->count; ++i) {
        if (memcmp(c->mhashes + 32u * i, mh, 32) == 0) {
            c->hits++;
            if (was_hit) *was_hit = true;
            return i + 1u;       /* 1-based handle */
        }
    }
    if (c->count >= c->capacity) return 0;
    c->glyphs[c->count] = *g;
    memcpy(c->mhashes + 32u * c->count, mh, 32);
    c->count++;
    c->misses++;
    if (was_hit) *was_hit = false;
    return c->count;             /* 1-based handle */
}

bool iii_glyph_cons_lookup(const iii_glyph_cons_t *c,
                           iii_glyph_handle_t       handle,
                           iii_glyph_t             *out)
{
    if (!c || !out) return false;
    if (handle == 0 || handle > c->count) return false;
    *out = c->glyphs[handle - 1u];
    return true;
}

uint32_t iii_glyph_cons_hits(const iii_glyph_cons_t *c)   { return c ? c->hits   : 0u; }
uint32_t iii_glyph_cons_misses(const iii_glyph_cons_t *c) { return c ? c->misses : 0u; }
uint16_t iii_glyph_cons_dedup_ratio_q14(const iii_glyph_cons_t *c) {
    if (!c) return 0;
    uint32_t total = c->hits + c->misses;
    if (total == 0) return 0;
    return (uint16_t)((c->hits * 16384u) / total);
}

/* ----------------------------------------------------------------------------
 * §4 — type-tag dispatch table
 * ---------------------------------------------------------------------------- */
void iii_glyph_dispatch_init(iii_glyph_dispatch_t *d) {
    if (!d) return;
    memset(d, 0, sizeof(*d));
}
bool iii_glyph_dispatch_register(iii_glyph_dispatch_t *d, uint8_t tag, iii_glyph_handler_fn fn, void *user) {
    if (!d) return false;
    d->handlers[tag] = fn;
    d->users[tag]    = user;
    return true;
}
int iii_glyph_dispatch_invoke(const iii_glyph_dispatch_t *d, const iii_glyph_t *g) {
    if (!d || !g) return -1;
    iii_glyph_handler_fn fn = d->handlers[g->type_tag];
    if (!fn) return -2;
    return fn(g, d->users[g->type_tag]);
}

/* ----------------------------------------------------------------------------
 * §6 — streaming
 * ---------------------------------------------------------------------------- */

typedef struct iii_stream_chunk {
    uint8_t *data;
    uint32_t length;
} iii_stream_chunk_t;

struct iii_stream {
    iii_stream_id_t      id;
    uint64_t             total;
    uint32_t             chunk_size;
    iii_stream_chunk_t  *chunks;
    uint32_t             chunk_count;
    uint32_t             chunk_capacity;
    uint64_t             current_offset;
    bool                 closed;
};

struct iii_stream_runtime {
    iii_stream_t *streams[III_STREAM_MAX];
    uint32_t      next_id;
};

iii_stream_runtime_t *iii_stream_runtime_create(void) {
    iii_stream_runtime_t *rt = (iii_stream_runtime_t *)calloc(1, sizeof(*rt));
    if (rt) rt->next_id = 1;
    return rt;
}

void iii_stream_runtime_destroy(iii_stream_runtime_t *rt) {
    if (!rt) return;
    for (unsigned i = 0; i < III_STREAM_MAX; ++i) {
        if (rt->streams[i]) {
            for (unsigned j = 0; j < rt->streams[i]->chunk_count; ++j) free(rt->streams[i]->chunks[j].data);
            free(rt->streams[i]->chunks);
            free(rt->streams[i]);
        }
    }
    free(rt);
}

iii_stream_id_t iii_stream_create(iii_stream_runtime_t *rt,
                                  uint64_t              total,
                                  uint32_t              chunk_size)
{
    if (!rt) return 0;
    if (chunk_size == 0) chunk_size = 4096u;
    /* Find a free slot. */
    for (unsigned i = 0; i < III_STREAM_MAX; ++i) {
        if (rt->streams[i] == NULL) {
            iii_stream_t *s = (iii_stream_t *)calloc(1, sizeof(*s));
            if (!s) return 0;
            s->id          = rt->next_id++;
            s->total       = total;
            s->chunk_size  = chunk_size;
            s->chunk_capacity = 16;
            s->chunks      = (iii_stream_chunk_t *)calloc(s->chunk_capacity, sizeof(iii_stream_chunk_t));
            if (!s->chunks) { free(s); return 0; }
            rt->streams[i] = s;
            return s->id;
        }
    }
    return 0;
}

static iii_stream_t *find_stream(iii_stream_runtime_t *rt, iii_stream_id_t id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < III_STREAM_MAX; ++i) {
        if (rt->streams[i] && rt->streams[i]->id == id) return rt->streams[i];
    }
    return NULL;
}

bool iii_stream_append(iii_stream_runtime_t *rt,
                       iii_stream_id_t       id,
                       const uint8_t        *data,
                       size_t                len)
{
    iii_stream_t *s = find_stream(rt, id);
    if (!s || s->closed) return false;
    if (s->chunk_count >= III_STREAM_MAX_CHUNKS) return false;
    if (s->chunk_count >= s->chunk_capacity) {
        uint32_t newcap = s->chunk_capacity * 2u;
        iii_stream_chunk_t *nc = (iii_stream_chunk_t *)realloc(s->chunks, newcap * sizeof(*nc));
        if (!nc) return false;
        s->chunks = nc;
        s->chunk_capacity = newcap;
    }
    iii_stream_chunk_t *ch = &s->chunks[s->chunk_count];
    ch->data = (uint8_t *)malloc(len);
    if (!ch->data) return false;
    memcpy(ch->data, data, len);
    ch->length = (uint32_t)len;
    s->chunk_count++;
    s->current_offset += len;
    return true;
}

bool iii_stream_close(iii_stream_runtime_t *rt, iii_stream_id_t id) {
    iii_stream_t *s = find_stream(rt, id);
    if (!s) return false;
    s->closed = true;
    return true;
}

size_t iii_stream_read(iii_stream_runtime_t *rt,
                       iii_stream_id_t       id,
                       uint64_t              offset,
                       uint8_t              *out,
                       size_t                cap)
{
    iii_stream_t *s = find_stream(rt, id);
    if (!s || !out) return 0;
    /* Linear scan — chunks are concatenated logically. */
    uint64_t pos = 0;
    size_t   written = 0;
    for (unsigned i = 0; i < s->chunk_count; ++i) {
        const iii_stream_chunk_t *ch = &s->chunks[i];
        uint64_t end = pos + ch->length;
        if (offset < end && pos + ch->length > offset) {
            uint64_t skip = (offset > pos) ? (offset - pos) : 0;
            uint32_t avail = ch->length - (uint32_t)skip;
            uint32_t take = (avail < (cap - written)) ? avail : (uint32_t)(cap - written);
            memcpy(out + written, ch->data + skip, take);
            written += take;
            offset  += take;
            if (written >= cap) break;
        }
        pos = end;
    }
    return written;
}

uint64_t iii_stream_total(const iii_stream_runtime_t *rt, iii_stream_id_t id) {
    if (!rt) return 0;
    for (unsigned i = 0; i < III_STREAM_MAX; ++i) {
        if (rt->streams[i] && rt->streams[i]->id == id) return rt->streams[i]->total;
    }
    return 0;
}

size_t iii_stream_chunk_count(const iii_stream_runtime_t *rt, iii_stream_id_t id) {
    if (!rt) return 0;
    for (unsigned i = 0; i < III_STREAM_MAX; ++i) {
        if (rt->streams[i] && rt->streams[i]->id == id) return rt->streams[i]->chunk_count;
    }
    return 0;
}

bool iii_stream_is_closed(const iii_stream_runtime_t *rt, iii_stream_id_t id) {
    if (!rt) return false;
    for (unsigned i = 0; i < III_STREAM_MAX; ++i) {
        if (rt->streams[i] && rt->streams[i]->id == id) return rt->streams[i]->closed;
    }
    return false;
}
