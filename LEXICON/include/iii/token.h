/* III Lexicon — token kinds and record (per III-LEXICON.md §3) */
#ifndef III_TOKEN_H
#define III_TOKEN_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §3.1 token kinds — INVALID is the sentinel zero. */
typedef enum iii_token_kind {
    IIIK_INVALID = 0,
    IIIK_KEYWORD,
    IIIK_MODIFIER,
    IIIK_OPERATOR,
    IIIK_PUNCT,
    IIIK_IDENT,
    IIIK_INT_LIT,
    IIIK_MHASH_LIT,
    IIIK_TRIT_LIT,
    IIIK_HEXAD_LIT,
    IIIK_Q14_LIT,
    IIIK_STRING_LIT,
    IIIK_BYTE_STRING_LIT,
    IIIK_RAW_STRING_LIT,
    IIIK_HEX_STRING_LIT,
    IIIK_DOC_COMMENT,
    IIIK_EOF
} iii_token_kind_t;

/* Integer / Q14 / trit suffix enumerator (§9.1) */
typedef enum iii_int_suffix {
    IIIS_NONE = 0,
    IIIS_U8, IIIS_U16, IIIS_U32, IIIS_U64,
    IIIS_I8, IIIS_I16, IIIS_I32, IIIS_I64,
    IIIS_Q, IIIS_Q14,
    IIIS_T, IIIS_TN, IIIS_TZ, IIIS_TP
} iii_int_suffix_t;

/* §3.5 token record. */
typedef struct iii_token {
    iii_token_kind_t kind;
    uint32_t text_offset;
    uint32_t text_len;
    uint32_t line;
    uint32_t col;            /* 1-indexed codepoint column */
    uint32_t interned_id;    /* interned id for KEYWORD/MODIFIER/OPERATOR/IDENT/DOC_COMMENT/strings */
    uint64_t int_value;      /* INT_LIT, TRIT_LIT (sign-extended NEG), Q14_LIT (zero-extended) */
    uint8_t  int_suffix;     /* iii_int_suffix_t */
    uint8_t  mhash_value[32];/* MHASH_LIT */
    uint16_t hexad_packed;   /* HEXAD_LIT */
    /* Decoded string payload (for STRING/BYTE_STRING/RAW_STRING/HEX_STRING/DOC_COMMENT) */
    const uint8_t *string_payload;
    size_t   string_len;
} iii_token_t;

const char *iii_token_kind_name(iii_token_kind_t k);
const char *iii_int_suffix_name(iii_int_suffix_t s);

#ifdef __cplusplus
}
#endif
#endif
