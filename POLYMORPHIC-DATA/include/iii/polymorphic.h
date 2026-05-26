/* ============================================================================
 * III-POLYMORPHIC-DATA — Glyph V3 universal value type
 * Spec: III-POLYMORPHIC-DATA.md  (Wave 6, items 47-53)
 *
 * Glyph V3 is a 192-byte structure: 1 byte type-tag + 191 bytes form-specific
 * payload.  Every value in III is a Glyph V3 (or a graph of Glyphs via
 * GLYPH_HANDLE).  The form catalogue is closure-pinned; we expose the 0x00
 * .. 0x25 well-known forms plus EXTENSION (0xFF).
 *
 * Implements:
 *   §1 — Glyph V3 layout + constructors per form
 *   §2 — polymorphic deserialization (JSON built-in; other parsers register
 *        via iii_serde_register at runtime)
 *   §3 — cross-architecture canonical encoding (big-endian, key-sorted maps,
 *        NFC-aware where applicable)
 *   §4 — type-tag dispatch table
 *   §5 — hash-consing (mhash → handle)
 *   §6 — streaming polymorphic data
 *   §7 — polymorphic-data witness kinds
 * ============================================================================
 */
#ifndef III_POLYMORPHIC_H
#define III_POLYMORPHIC_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §1 — Glyph V3 (exactly 192 bytes).
 * ---------------------------------------------------------------------------- */
#define III_GLYPH_BYTES        192u
#define III_GLYPH_PAYLOAD_BYTES (III_GLYPH_BYTES - 1u)

typedef enum iii_glyph_form {
    III_FORM_NULL              = 0x00,
    III_FORM_INTEGER_64        = 0x01,
    III_FORM_INTEGER_BIG       = 0x02,
    III_FORM_RATIONAL_64       = 0x03,
    III_FORM_RATIONAL_BIG      = 0x04,
    III_FORM_TRIT              = 0x05,
    III_FORM_HEXAD             = 0x06,
    III_FORM_MHASH             = 0x07,
    III_FORM_TIMESTAMP         = 0x08,
    III_FORM_STRING_UTF8       = 0x09,
    III_FORM_BYTES             = 0x0A,
    III_FORM_LIST              = 0x0B,
    III_FORM_MAP               = 0x0C,
    III_FORM_OPTION            = 0x0D,
    III_FORM_RESULT            = 0x0E,
    III_FORM_TUPLE             = 0x0F,
    III_FORM_RECORD            = 0x10,
    III_FORM_ENUM_VARIANT      = 0x11,
    III_FORM_FN_POINTER        = 0x12,
    III_FORM_CAP               = 0x13,
    III_FORM_WITNESS_HANDLE    = 0x14,
    III_FORM_GLYPH_HANDLE      = 0x15,
    III_FORM_REDUCTION_HANDLE  = 0x16,
    III_FORM_PROOF_HANDLE      = 0x17,
    III_FORM_SANCTUM_HANDLE    = 0x18,
    III_FORM_ARCH_BINARY       = 0x19,
    III_FORM_LEGACY_BINARY     = 0x1A,
    III_FORM_LEGACY_FILE_HANDLE= 0x1B,
    III_FORM_NETWORK_PACKET    = 0x1C,
    III_FORM_CRYPTO_KEY        = 0x1D,
    III_FORM_CRYPTO_SIG        = 0x1E,
    III_FORM_ZK_PROOF          = 0x1F,
    III_FORM_ROLLUP_HANDLE     = 0x20,
    III_FORM_CAUSAL_DAG_NODE   = 0x21,
    III_FORM_JIT_REGION_HANDLE = 0x22,
    III_FORM_OBS_THRESHOLD     = 0x23,
    III_FORM_FED_PEER_HANDLE   = 0x24,
    III_FORM_OPERATOR_INTENT   = 0x25,
    III_FORM_EXTENSION         = 0xFF
} iii_glyph_form_t;

const char *iii_glyph_form_name(iii_glyph_form_t f);

typedef struct iii_glyph {
    uint8_t type_tag;
    uint8_t payload[III_GLYPH_PAYLOAD_BYTES];
} iii_glyph_t;

/* §1.6 — constructors */
iii_glyph_t iii_glyph_null(void);
iii_glyph_t iii_glyph_int64(int64_t value);
iii_glyph_t iii_glyph_trit(int8_t v);                /* -1, 0, +1 → 0, 1, 2 */
iii_glyph_t iii_glyph_hexad(const int8_t pillars[6]);
iii_glyph_t iii_glyph_mhash(const uint8_t hash[32]);
iii_glyph_t iii_glyph_timestamp(uint64_t ts);
iii_glyph_t iii_glyph_string(const char *s, size_t len, bool *embedded);
iii_glyph_t iii_glyph_bytes(const uint8_t *b, size_t len, bool *embedded);
iii_glyph_t iii_glyph_glyph_handle(uint32_t handle);
iii_glyph_t iii_glyph_witness_handle(uint32_t handle);
iii_glyph_t iii_glyph_extension(uint16_t extended_id);

/* Accessors */
int64_t  iii_glyph_get_int64(const iii_glyph_t *g);
uint64_t iii_glyph_get_timestamp(const iii_glyph_t *g);
bool     iii_glyph_get_string(const iii_glyph_t *g, char *out, size_t cap, size_t *out_len);
bool     iii_glyph_get_bytes(const iii_glyph_t *g, uint8_t *out, size_t cap, size_t *out_len);
bool     iii_glyph_get_mhash(const iii_glyph_t *g, uint8_t out[32]);

/* ----------------------------------------------------------------------------
 * §3 — canonical encoding.  Returns the byte length consumed; canonical-form
 * is big-endian, length-prefixed, key-sorted-for-MAPs, NFC-string-normalised.
 * ---------------------------------------------------------------------------- */
size_t iii_glyph_canonical_encode(const iii_glyph_t *g, uint8_t *out, size_t cap);

/* Canonical decode.  Returns 0 on failure, else the number of input bytes
 * consumed. */
size_t iii_glyph_canonical_decode(const uint8_t *in, size_t in_len, iii_glyph_t *out);

/* mhash of the canonical encoding (SHA-256). */
void iii_glyph_canonical_mhash(const iii_glyph_t *g, uint8_t out[32]);

/* ----------------------------------------------------------------------------
 * §2 — polymorphic deserialization.  We provide a JSON parser fully and a
 * registration mechanism for the rest; tests exercise JSON.
 * ---------------------------------------------------------------------------- */
typedef enum iii_encoding {
    III_ENC_UNKNOWN     = 0,
    III_ENC_GLYPH_V3    = 1,
    III_ENC_JSON        = 2,
    III_ENC_CBOR        = 3,
    III_ENC_MSGPACK     = 4,
    III_ENC_TOML        = 5,
    III_ENC_INI         = 6,
    III_ENC_XML         = 7,
    III_ENC_YAML        = 8,
    III_ENC_PROTOBUF    = 9,
    III_ENC_BSON        = 10,
    III_ENC_AVRO        = 11,
    III_ENC_ASN1        = 12,
    III_ENC_TAR         = 13,
    III_ENC_ZIP         = 14,
    III_ENC_HDF5        = 15,
    III_ENC_PARQUET     = 16
} iii_encoding_t;

const char *iii_encoding_name(iii_encoding_t e);

iii_encoding_t iii_detect_encoding(const uint8_t *data, size_t len);

/* Returns 0 on failure, else the number of bytes parsed.  Stores the result
 * in `out`.  For JSON, only scalars + lists + maps + strings are mapped.
 * Other encodings register parsers via iii_serde_register(). */
typedef size_t (*iii_serde_fn)(const uint8_t *in, size_t in_len, iii_glyph_t *out, void *user);

bool iii_serde_register(iii_encoding_t e, iii_serde_fn fn, void *user);

size_t iii_serde_deserialize(iii_encoding_t e,
                             const uint8_t *in, size_t in_len,
                             iii_glyph_t *out);

/* JSON built-in.  Exposed for tests and tooling. */
size_t iii_json_parse(const uint8_t *in, size_t in_len, iii_glyph_t *out);

/* ----------------------------------------------------------------------------
 * §5 — Hash-consing.
 * ---------------------------------------------------------------------------- */
typedef uint32_t iii_glyph_handle_t;

typedef struct iii_glyph_cons iii_glyph_cons_t;

iii_glyph_cons_t *iii_glyph_cons_create(uint32_t capacity);
void              iii_glyph_cons_destroy(iii_glyph_cons_t *c);

/* Insert (or look up) the glyph.  Returns the assigned handle.  Sets *was_hit
 * to true if the cons-table already had this glyph. */
iii_glyph_handle_t iii_glyph_cons_insert(iii_glyph_cons_t *c,
                                         const iii_glyph_t *g,
                                         bool *was_hit);

bool iii_glyph_cons_lookup(const iii_glyph_cons_t *c,
                           iii_glyph_handle_t       handle,
                           iii_glyph_t             *out);

uint32_t iii_glyph_cons_hits(const iii_glyph_cons_t *c);
uint32_t iii_glyph_cons_misses(const iii_glyph_cons_t *c);
uint16_t iii_glyph_cons_dedup_ratio_q14(const iii_glyph_cons_t *c);

/* ----------------------------------------------------------------------------
 * §6 — Streaming Glyphs.
 * ---------------------------------------------------------------------------- */
typedef uint32_t iii_stream_id_t;

#define III_STREAM_MAX             64u
#define III_STREAM_MAX_CHUNKS      4096u

typedef struct iii_stream iii_stream_t;
typedef struct iii_stream_runtime iii_stream_runtime_t;

iii_stream_runtime_t *iii_stream_runtime_create(void);
void                  iii_stream_runtime_destroy(iii_stream_runtime_t *rt);

iii_stream_id_t iii_stream_create(iii_stream_runtime_t *rt,
                                  uint64_t              total_size_or_zero,
                                  uint32_t              chunk_size);

bool iii_stream_append(iii_stream_runtime_t *rt,
                       iii_stream_id_t       id,
                       const uint8_t        *data,
                       size_t                len);

bool iii_stream_close(iii_stream_runtime_t *rt, iii_stream_id_t id);

size_t iii_stream_read(iii_stream_runtime_t *rt,
                       iii_stream_id_t       id,
                       uint64_t              offset,
                       uint8_t              *out,
                       size_t                cap);

uint64_t iii_stream_total(const iii_stream_runtime_t *rt, iii_stream_id_t id);
size_t   iii_stream_chunk_count(const iii_stream_runtime_t *rt, iii_stream_id_t id);
bool     iii_stream_is_closed(const iii_stream_runtime_t *rt, iii_stream_id_t id);

/* ----------------------------------------------------------------------------
 * §7 — witness kinds.
 * ---------------------------------------------------------------------------- */
typedef enum iii_poly_witness_kind {
    III_POLYW_NONE              = 0,
    III_POLYW_GLYPH_CONS_HIT    = 0x0B01,
    III_POLYW_GLYPH_CONS_MISS   = 0x0B02,
    III_POLYW_DESERIALIZE       = 0x0B03,
    III_POLYW_SERIALIZE         = 0x0B04,
    III_POLYW_DISPATCH          = 0x0B05,
    III_POLYW_STREAM_CREATE     = 0x0B06,
    III_POLYW_STREAM_APPEND     = 0x0B07,
    III_POLYW_STREAM_CLOSE      = 0x0B08,
    III_POLYW_CANONICAL_MISMATCH= 0x0B09
} iii_poly_witness_kind_t;

const char *iii_poly_witness_kind_name(iii_poly_witness_kind_t k);

/* ----------------------------------------------------------------------------
 * §4 — type-tag dispatch table.
 * ---------------------------------------------------------------------------- */
typedef int (*iii_glyph_handler_fn)(const iii_glyph_t *g, void *user);

typedef struct iii_glyph_dispatch {
    iii_glyph_handler_fn  handlers[256];
    void                 *users[256];
} iii_glyph_dispatch_t;

void iii_glyph_dispatch_init(iii_glyph_dispatch_t *d);
bool iii_glyph_dispatch_register(iii_glyph_dispatch_t *d,
                                 uint8_t              type_tag,
                                 iii_glyph_handler_fn fn,
                                 void                *user);
int  iii_glyph_dispatch_invoke(const iii_glyph_dispatch_t *d, const iii_glyph_t *g);

#ifdef __cplusplus
}
#endif

#endif /* III_POLYMORPHIC_H */
