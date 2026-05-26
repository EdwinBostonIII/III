#include "iii/token.h"
#include "iii/errors.h"

const char *iii_token_kind_name(iii_token_kind_t k) {
    switch (k) {
        case IIIK_INVALID: return "INVALID";
        case IIIK_KEYWORD: return "KEYWORD";
        case IIIK_MODIFIER: return "MODIFIER";
        case IIIK_OPERATOR: return "OPERATOR";
        case IIIK_PUNCT: return "PUNCT";
        case IIIK_IDENT: return "IDENT";
        case IIIK_INT_LIT: return "INT_LIT";
        case IIIK_MHASH_LIT: return "MHASH_LIT";
        case IIIK_TRIT_LIT: return "TRIT_LIT";
        case IIIK_HEXAD_LIT: return "HEXAD_LIT";
        case IIIK_Q14_LIT: return "Q14_LIT";
        case IIIK_STRING_LIT: return "STRING_LIT";
        case IIIK_BYTE_STRING_LIT: return "BYTE_STRING_LIT";
        case IIIK_RAW_STRING_LIT: return "RAW_STRING_LIT";
        case IIIK_HEX_STRING_LIT: return "HEX_STRING_LIT";
        case IIIK_DOC_COMMENT: return "DOC_COMMENT";
        case IIIK_EOF: return "EOF";
    }
    return "?";
}

const char *iii_int_suffix_name(iii_int_suffix_t s) {
    switch (s) {
        case IIIS_NONE: return "";
        case IIIS_U8: return "u8";
        case IIIS_U16: return "u16";
        case IIIS_U32: return "u32";
        case IIIS_U64: return "u64";
        case IIIS_I8: return "i8";
        case IIIS_I16: return "i16";
        case IIIS_I32: return "i32";
        case IIIS_I64: return "i64";
        case IIIS_Q: return "q";
        case IIIS_Q14: return "q14";
        case IIIS_T: return "t";
        case IIIS_TN: return "tn";
        case IIIS_TZ: return "tz";
        case IIIS_TP: return "tp";
    }
    return "?";
}

const char *iii_lex_error_code_name(iii_lex_error_code_t c) {
    switch (c) {
        case IIIE_NONE: return "NONE";
        case IIIE_ENC_001_BOM: return "LEX-ENC-001";
        case IIIE_ENC_002_CR: return "LEX-ENC-002";
        case IIIE_ENC_003_TRAILING_WS: return "LEX-ENC-003";
        case IIIE_ENC_004_NON_CANONICAL_EXT: return "LEX-ENC-004";
        case IIIE_ENC_005_TOO_LARGE: return "LEX-ENC-005";
        case IIIE_ENC_006_INVALID_UTF8: return "LEX-ENC-006";
        case IIIE_ENC_007_FORBIDDEN_CTRL: return "LEX-ENC-007";
        case IIIE_ENC_008_RAW_FORBIDDEN_IN_STRING: return "LEX-ENC-008";
        case IIIE_ID_001_KEYWORD_AS_IDENT: return "LEX-ID-001";
        case IIIE_ID_002_IDENT_TOO_LONG: return "LEX-ID-002";
        case IIIE_ID_003_RESERVED_DOUBLE_UNDERSCORE: return "LEX-ID-003";
        case IIIE_ID_004_WILDCARD_BIND: return "LEX-ID-004";
        case IIIE_ID_005_RESERVED_CATALYST_SLOT: return "LEX-ID-005";
        case IIIE_INT_001_USCORE_AFTER_PREFIX: return "LEX-INT-001";
        case IIIE_INT_002_USCORE_AT_START: return "LEX-INT-002";
        case IIIE_INT_003_USCORE_BEFORE_SUFFIX: return "LEX-INT-003";
        case IIIE_INT_004_OVERFLOW: return "LEX-INT-004";
        case IIIE_Q14_001_OUT_OF_RANGE: return "LEX-Q14-001";
        case IIIE_STR_001_UNESCAPED_NEWLINE: return "LEX-STR-001";
        case IIIE_STR_002_ODD_HEX: return "LEX-STR-002";
        case IIIE_STR_003_INVALID_ESCAPE: return "LEX-STR-003";
        case IIIE_STR_004_UNTERMINATED: return "LEX-STR-004";
        case IIIE_OP_001_NON_CANONICAL: return "LEX-OP-001";
        case IIIE_PUNCT_001_RESERVED_DOLLAR: return "LEX-PUNCT-001";
        case IIIE_PUNCT_002_RESERVED_PENDING: return "LEX-PUNCT-002";
        case IIIE_CMT_001_UNTERMINATED_BLOCK: return "LEX-CMT-001";
        case IIIE_CMT_002_DANGLING_DOC: return "LEX-CMT-002";
        case IIIE_WS_001_FORBIDDEN_WS: return "LEX-WS-001";
        case IIIE__COUNT: return "?";
    }
    return "?";
}

const char *iii_lex_error_code_message(iii_lex_error_code_t c) {
    switch (c) {
        case IIIE_NONE: return "";
        case IIIE_ENC_001_BOM: return "BOM forbidden";
        case IIIE_ENC_002_CR: return "CR forbidden";
        case IIIE_ENC_003_TRAILING_WS: return "trailing whitespace";
        case IIIE_ENC_004_NON_CANONICAL_EXT: return "non-canonical extension";
        case IIIE_ENC_005_TOO_LARGE: return "source exceeds 16 MiB";
        case IIIE_ENC_006_INVALID_UTF8: return "invalid UTF-8";
        case IIIE_ENC_007_FORBIDDEN_CTRL: return "forbidden control codepoint";
        case IIIE_ENC_008_RAW_FORBIDDEN_IN_STRING: return "raw forbidden codepoint inside string literal";
        case IIIE_ID_001_KEYWORD_AS_IDENT: return "keyword used as identifier";
        case IIIE_ID_002_IDENT_TOO_LONG: return "identifier exceeds 256-codepoint limit";
        case IIIE_ID_003_RESERVED_DOUBLE_UNDERSCORE: return "reserved double-underscore identifier";
        case IIIE_ID_004_WILDCARD_BIND: return "wildcard cannot be bound as a name";
        case IIIE_ID_005_RESERVED_CATALYST_SLOT: return "reserved Catalyst slot name";
        case IIIE_INT_001_USCORE_AFTER_PREFIX: return "underscore immediately after radix prefix";
        case IIIE_INT_002_USCORE_AT_START: return "underscore at start of integer literal";
        case IIIE_INT_003_USCORE_BEFORE_SUFFIX: return "underscore immediately before suffix";
        case IIIE_INT_004_OVERFLOW: return "literal exceeds suffix range";
        case IIIE_Q14_001_OUT_OF_RANGE: return "Q14 literal exceeds range";
        case IIIE_STR_001_UNESCAPED_NEWLINE: return "unescaped newline in string literal";
        case IIIE_STR_002_ODD_HEX: return "odd-length hex string";
        case IIIE_STR_003_INVALID_ESCAPE: return "invalid escape sequence";
        case IIIE_STR_004_UNTERMINATED: return "unterminated string literal";
        case IIIE_OP_001_NON_CANONICAL: return "non-canonical operator codepoint";
        case IIIE_PUNCT_001_RESERVED_DOLLAR: return "reserved character $ in user source";
        case IIIE_PUNCT_002_RESERVED_PENDING: return "reserved character — slot pending Catalyst promotion";
        case IIIE_CMT_001_UNTERMINATED_BLOCK: return "unterminated block comment";
        case IIIE_CMT_002_DANGLING_DOC: return "dangling doc comment";
        case IIIE_WS_001_FORBIDDEN_WS: return "forbidden whitespace codepoint";
        case IIIE__COUNT: return "?";
    }
    return "?";
}
