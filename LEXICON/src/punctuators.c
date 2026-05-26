/* Punctuators — both ASCII single-byte and the two non-ASCII (≤ ≥) forms. */
#include <stdint.h>
#include <stddef.h>

/* Returns nonzero if cp is a recognized punctuator first-codepoint (single
 * codepoint forms or first codepoint of a multi-byte sequence). */
int iii_lex_is_punct_start(uint32_t cp) {
    switch (cp) {
        case '(': case ')': case '{': case '}': case '[': case ']':
        case '<': case '>': case ',': case ';': case ':': case '.':
        case '=': case '!': case '-':
        case '|': case '_': case '?': case '&':
        case 0x2264: /* ≤ */
        case 0x2265: /* ≥ */
            return 1;
        default: return 0;
    }
}

/* Token-name string for a single-codepoint punctuator (used by tool output). */
const char *iii_lex_punct_name_cp(uint32_t cp) {
    switch (cp) {
        case '(': return "(";
        case ')': return ")";
        case '{': return "{";
        case '}': return "}";
        case '[': return "[";
        case ']': return "]";
        case '<': return "<";
        case '>': return ">";
        case ',': return ",";
        case ';': return ";";
        case ':': return ":";
        case '.': return ".";
        case '=': return "=";
        case '|': return "|";
        case '_': return "_";
        case '?': return "?";
        case '&': return "&";
        case 0x2264: return "<=";
        case 0x2265: return ">=";
        default: return "?";
    }
}

int iii_lex_is_reserved_dollar(uint32_t cp) { return cp == '$'; }
int iii_lex_is_reserved_pending(uint32_t cp) {
    return cp == '^' || cp == '~' || cp == '\'' || cp == '`';
}
