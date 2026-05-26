/* III-ABI — internal helpers shared by the validator, the lowerer,
 * and the marshaller.
 */
#include "abi_internal.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

const char *iii_abi_kind_name(iii_abi_kind_t k) {
    switch (k) {
        case IIIABI_KIND_NONE:    return "<none>";
        case IIIABI_C_MSVC_X64:   return IIIABI_NAME_C_MSVC_X64;
    }
    return "<unknown>";
}

const char *iii_abi_diag_name(int code) {
    switch (code) {
        case IIIABI_OK:                  return "OK";
        case IIIABI_E_NOT_EXTERN_DECL:   return "NOT_EXTERN_DECL";
        case IIIABI_E_MISSING_ABI:       return "MISSING_ABI";
        case IIIABI_E_BAD_ABI_NAME:      return "BAD_ABI_NAME";
        case IIIABI_E_NO_RING_ATTR:      return "NO_RING_ATTR";
        case IIIABI_E_BAD_RING:          return "BAD_RING";
        case IIIABI_E_FORBIDDEN_TYPE:    return "FORBIDDEN_TYPE";
        case IIIABI_E_NOT_EXTERN_ITEM:   return "NOT_EXTERN_ITEM";
        case IIIABI_E_TOO_MANY_PARAMS:   return "TOO_MANY_PARAMS";
        case IIIABI_E_INTERNAL:          return "INTERNAL";
        case IIIABI_E_NULL_ARG:          return "NULL_ARG";
        case IIIABI_E_BAD_ALIAS:         return "BAD_ALIAS";
        case IIIABI_E_NOT_FN_ITEM:       return "NOT_FN_ITEM";
    }
    return "UNKNOWN";
}

const char *iii_abi_type_name(iii_abi_type_kind_t t) {
    switch (t) {
        case IIIABI_T_VOID:  return "void";
        case IIIABI_T_BOOL:  return "bool";
        case IIIABI_T_U8:    return "u8";
        case IIIABI_T_U16:   return "u16";
        case IIIABI_T_U32:   return "u32";
        case IIIABI_T_U64:   return "u64";
        case IIIABI_T_I8:    return "i8";
        case IIIABI_T_I16:   return "i16";
        case IIIABI_T_I32:   return "i32";
        case IIIABI_T_I64:   return "i64";
        case IIIABI_T_F32:   return "f32";
        case IIIABI_T_F64:   return "f64";
        case IIIABI_T_PTR:   return "ptr";
        case IIIABI_T_ARRAY: return "array";
        case IIIABI_T_ALIAS: return "alias";
    }
    return "?";
}

const char *iii_abi_class_name(iii_abi_class_t c) {
    switch (c) {
        case IIIABI_CLS_VOID:    return "VOID";
        case IIIABI_CLS_INTEGER: return "INTEGER";
        case IIIABI_CLS_SSE:     return "SSE";
        case IIIABI_CLS_MEMORY:  return "MEMORY";
    }
    return "?";
}

const char *iii_abi_loc_name(iii_abi_loc_t l) {
    switch (l) {
        case IIIABI_LOC_NONE:        return "none";
        case IIIABI_LOC_RCX:         return "rcx";
        case IIIABI_LOC_RDX:         return "rdx";
        case IIIABI_LOC_R8:          return "r8";
        case IIIABI_LOC_R9:          return "r9";
        case IIIABI_LOC_XMM0:        return "xmm0";
        case IIIABI_LOC_XMM1:        return "xmm1";
        case IIIABI_LOC_XMM2:        return "xmm2";
        case IIIABI_LOC_XMM3:        return "xmm3";
        case IIIABI_LOC_STACK:       return "stack";
        case IIIABI_LOC_RAX:         return "rax";
        case IIIABI_LOC_XMM0_RET:    return "xmm0";
        case IIIABI_LOC_HIDDEN_PTR:  return "rcx[hidden-ret-ptr]";
    }
    return "?";
}

uint32_t iiiabi_type_size(iii_abi_type_kind_t t) {
    switch (t) {
        case IIIABI_T_VOID:  return 0;
        case IIIABI_T_BOOL:
        case IIIABI_T_U8:
        case IIIABI_T_I8:    return 1;
        case IIIABI_T_U16:
        case IIIABI_T_I16:   return 2;
        case IIIABI_T_U32:
        case IIIABI_T_I32:
        case IIIABI_T_F32:   return 4;
        case IIIABI_T_U64:
        case IIIABI_T_I64:
        case IIIABI_T_F64:
        case IIIABI_T_PTR:   return 8;
        case IIIABI_T_ARRAY: return 0; /* caller must use elem*size */
        case IIIABI_T_ALIAS: return 0;
    }
    return 0;
}

uint32_t iiiabi_type_align(iii_abi_type_kind_t t) {
    uint32_t s = iiiabi_type_size(t);
    return s == 0 ? 1 : s;
}

iii_abi_type_kind_t iiiabi_type_from_name(const char *s, size_t n) {
    if (!s || n == 0) return IIIABI_T_VOID;
    #define M(lit, k) if (n == sizeof(lit)-1 && memcmp(s, lit, n) == 0) return k
    M("bool", IIIABI_T_BOOL);
    M("u8",   IIIABI_T_U8);
    M("u16",  IIIABI_T_U16);
    M("u32",  IIIABI_T_U32);
    M("u64",  IIIABI_T_U64);
    M("i8",   IIIABI_T_I8);
    M("i16",  IIIABI_T_I16);
    M("i32",  IIIABI_T_I32);
    M("i64",  IIIABI_T_I64);
    M("f32",  IIIABI_T_F32);
    M("f64",  IIIABI_T_F64);
    #undef M
    return IIIABI_T_VOID;
}

size_t iiiabi_node_text(const iii_ast_node_t *n, char *out, size_t cap) {
    if (!n || !out || cap == 0) return 0;
    out[0] = '\0';
    if (!n->string_payload || n->string_len == 0) return 0;
    size_t copy = n->string_len < cap - 1 ? n->string_len : cap - 1;
    memcpy(out, n->string_payload, copy);
    out[copy] = '\0';
    return copy;
}

const iii_ast_node_t *iiiabi_unwrap_type(const iii_ast_node_t *t,
                                         int *out_ref_depth) {
    int depth = 0;
    while (t && t->kind == III_AST_TYPE && t->child_count >= 1) {
        const iii_ast_node_t *c = t->children[0];
        if (!c) break;
        /* parse_extern_type encodes `&T` as an III_AST_TYPE node whose
         * single child is itself a parsed type (also wrapped in
         * III_AST_TYPE, since iiip_parse_type wraps).  Each TYPE→TYPE
         * level corresponds to one `&`.  We unwrap once unconditionally
         * for the parameter's outer wrapper; subsequent TYPE→TYPE
         * counts as a `&`. */
        if (depth == 0) {
            t = c;
            depth = 1;
            continue;
        }
        if (c->kind == III_AST_TYPE) {
            t = c;
            ++depth;
            continue;
        }
        t = c;
        break;
    }
    if (out_ref_depth) {
        /* depth==1 means the param came out of one parse_extern_type
         * call with a non-ref body.  depth>=2 means at least one '&'. */
        *out_ref_depth = depth >= 2 ? depth - 1 : 0;
    }
    return t;
}

const iii_ast_node_t *iiiabi_find_ring_attr(const iii_ast_node_t *module) {
    if (!module || module->kind != III_AST_MODULE) return NULL;
    for (uint32_t i = 0; i < module->child_count; ++i) {
        const iii_ast_node_t *c = module->children[i];
        if (!c || c->kind != III_AST_MODULE_ATTR) continue;
        if (!c->string_payload) continue;
        if (c->string_len == 5 && memcmp(c->string_payload, "@ring", 5) == 0) {
            return c;
        }
    }
    return NULL;
}

size_t iiiabi_extract_abi_name(const iii_ast_node_t *extern_decl,
                               const uint8_t *src, size_t src_len,
                               char *out, size_t cap) {
    if (!extern_decl || !src || !out || cap == 0) return 0;
    out[0] = '\0';
    uint32_t s = extern_decl->span_start;
    uint32_t e = extern_decl->span_end;
    if (e > src_len) e = (uint32_t)src_len;
    if (s >= e) return 0;
    static const char NEEDLE[] = "@abi";
    for (uint32_t i = s; i + 4 <= e; ++i) {
        if (memcmp(src + i, NEEDLE, 4) != 0) continue;
        uint32_t j = i + 4;
        while (j < e && (src[j] == ' ' || src[j] == '\t')) ++j;
        if (j >= e || src[j] != '(') continue;
        ++j;
        /* find matching ')' (no nesting in @abi) */
        uint32_t k = j;
        while (k < e && src[k] != ')') ++k;
        if (k >= e) return 0;
        /* trim whitespace */
        while (j < k && (src[j] == ' ' || src[j] == '\t' ||
                         src[j] == '\n' || src[j] == '\r')) ++j;
        uint32_t end = k;
        while (end > j && (src[end-1] == ' ' || src[end-1] == '\t' ||
                           src[end-1] == '\n' || src[end-1] == '\r')) --end;
        size_t n = end - j;
        if (n >= cap) n = cap - 1;
        memcpy(out, src + j, n);
        out[n] = '\0';
        return n;
    }
    return 0;
}

size_t iiiabi_appendf(char *buf, size_t cap, size_t *pos,
                      const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    size_t p = pos ? *pos : 0;
    size_t avail = (p < cap) ? (cap - p) : 0;
    int n = vsnprintf(buf ? buf + p : NULL, avail, fmt, ap);
    va_end(ap);
    if (n < 0) n = 0;
    if (pos) *pos = p + (size_t)n;
    return (size_t)n;
}
