/* III Lexicon — diagnostic codes (§12.3) */
#ifndef III_ERRORS_H
#define III_ERRORS_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum iii_lex_error_code {
    IIIE_NONE = 0,

    IIIE_ENC_001_BOM,
    IIIE_ENC_002_CR,
    IIIE_ENC_003_TRAILING_WS,
    IIIE_ENC_004_NON_CANONICAL_EXT,
    IIIE_ENC_005_TOO_LARGE,
    IIIE_ENC_006_INVALID_UTF8,
    IIIE_ENC_007_FORBIDDEN_CTRL,
    IIIE_ENC_008_RAW_FORBIDDEN_IN_STRING,

    IIIE_ID_001_KEYWORD_AS_IDENT,
    IIIE_ID_002_IDENT_TOO_LONG,
    IIIE_ID_003_RESERVED_DOUBLE_UNDERSCORE,
    IIIE_ID_004_WILDCARD_BIND,
    IIIE_ID_005_RESERVED_CATALYST_SLOT,

    IIIE_INT_001_USCORE_AFTER_PREFIX,
    IIIE_INT_002_USCORE_AT_START,
    IIIE_INT_003_USCORE_BEFORE_SUFFIX,
    IIIE_INT_004_OVERFLOW,

    IIIE_Q14_001_OUT_OF_RANGE,

    IIIE_STR_001_UNESCAPED_NEWLINE,
    IIIE_STR_002_ODD_HEX,
    IIIE_STR_003_INVALID_ESCAPE,
    IIIE_STR_004_UNTERMINATED,

    IIIE_OP_001_NON_CANONICAL,

    IIIE_PUNCT_001_RESERVED_DOLLAR,
    IIIE_PUNCT_002_RESERVED_PENDING,

    IIIE_CMT_001_UNTERMINATED_BLOCK,
    IIIE_CMT_002_DANGLING_DOC,

    IIIE_WS_001_FORBIDDEN_WS,

    IIIE__COUNT
} iii_lex_error_code_t;

typedef struct iii_lex_error {
    iii_lex_error_code_t code;
    uint32_t byte_offset;
    uint32_t line;
    uint32_t col;
    char message[192];
    char suggestion[128];
} iii_lex_error_t;

const char *iii_lex_error_code_name(iii_lex_error_code_t c);
const char *iii_lex_error_code_message(iii_lex_error_code_t c);

#ifdef __cplusplus
}
#endif
#endif
