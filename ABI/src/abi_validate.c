/* III-ABI — validation of EXTERN_DECL nodes per III-ABI.md.
 *
 * Enforces the conformance criteria of §5:
 *   C-ABI-1  c-msvc-x64 is the only admitted ABI name.
 *   C-ABI-2  extern blocks appear only in R0 / R3 modules.
 *   C-ABI-4  Higher-kinded III types are not admitted as extern args.
 *   §1.2.4   No naked extern — must live inside a module with a
 *            @ring set ⊆ {R0, R3}.
 *   §1.2.5   extern_type admits only primitives, &T, [T;N], aliases.
 *
 * (C-ABI-3 — wrapping every extern call in a synthesized cycle —
 *  is the lowering pass's responsibility, not the ABI gatekeeper's.
 *  The CYCLE node is emitted by the marshaller's prologue/epilogue
 *  description, see iii_abi_marshal_call.)
 */
#include "abi_internal.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

static void diag_set(iii_abi_diag_t *d, int code,
                     const iii_ast_node_t *n,
                     const char *fmt, ...) {
    if (!d) return;
    d->code = code;
    d->span_start = n ? n->span_start : 0;
    d->span_end   = n ? n->span_end   : 0;
    d->line       = n ? n->line       : 0;
    d->col        = n ? n->col        : 0;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(d->message, sizeof(d->message), fmt, ap);
    va_end(ap);
}

static void diag_ok(iii_abi_diag_t *d) {
    if (!d) return;
    d->code = IIIABI_OK;
    d->span_start = d->span_end = d->line = d->col = 0;
    snprintf(d->message, sizeof(d->message), "ok");
}

/* §1.2.2 — module ring set must be a non-empty subset of {R0, R3}. */
static int validate_ring(const iii_ast_node_t *module,
                         const iii_ast_node_t *extern_decl,
                         iii_abi_diag_t *out_diag) {
    const iii_ast_node_t *ring_attr = iiiabi_find_ring_attr(module);
    if (!ring_attr) {
        diag_set(out_diag, IIIABI_E_NO_RING_ATTR, extern_decl,
                 "extern @abi(c-msvc-x64) requires enclosing module "
                 "with @ring(R0) or @ring(R3) (PARSE-EXTERN-001)");
        return IIIABI_E_NO_RING_ATTR;
    }
    /* Ring attr child should be III_AST_RING_SET. */
    const iii_ast_node_t *set = NULL;
    for (uint32_t i = 0; i < ring_attr->child_count; ++i) {
        if (ring_attr->children[i] &&
            ring_attr->children[i]->kind == III_AST_RING_SET) {
            set = ring_attr->children[i];
            break;
        }
    }
    if (!set || set->child_count == 0) {
        diag_set(out_diag, IIIABI_E_NO_RING_ATTR, ring_attr,
                 "@ring(...) is empty");
        return IIIABI_E_NO_RING_ATTR;
    }
    int saw_r0 = 0, saw_r3 = 0;
    for (uint32_t i = 0; i < set->child_count; ++i) {
        const iii_ast_node_t *r = set->children[i];
        if (!r) continue;
        /* R-1 / R-2 carry int_value < 0 in negated form. */
        int64_t iv = (int64_t)r->int_value;
        if (iv != 0) {
            /* `int_value` is set to -(N) for R-N; any non-zero means
             * R-1 or R-2. */
            diag_set(out_diag, IIIABI_E_BAD_RING, r,
                     "extern blocks rejected from privileged ring "
                     "(TYPE-EXTERN-001)");
            return IIIABI_E_BAD_RING;
        }
        if (r->string_payload && r->string_len == 2 &&
            r->string_payload[0] == 'R') {
            char c = (char)r->string_payload[1];
            if (c == '0') { saw_r0 = 1; continue; }
            if (c == '3') { saw_r3 = 1; continue; }
        }
        diag_set(out_diag, IIIABI_E_BAD_RING, r,
                 "ring '%.*s' is not a legal extern host (only R0/R3)",
                 (int)(r->string_len), (const char *)r->string_payload);
        return IIIABI_E_BAD_RING;
    }
    if (!saw_r0 && !saw_r3) {
        diag_set(out_diag, IIIABI_E_BAD_RING, set,
                 "@ring set contains no R0 or R3");
        return IIIABI_E_BAD_RING;
    }
    return IIIABI_OK;
}

/* Per §1.2.5 — admit only primitive / &T / [T;N] / IDENT-alias. */
static int validate_extern_type(const iii_ast_node_t *t,
                                const iii_ast_node_t *extern_decl,
                                iii_abi_diag_t *out_diag) {
    if (!t) return IIIABI_OK;
    /* Strip the parameter's outer wrapper. */
    const iii_ast_node_t *inner = t;
    if (inner->kind == III_AST_TYPE && inner->child_count >= 1) {
        inner = inner->children[0];
    }
    /* Walk references. */
    while (inner && inner->kind == III_AST_TYPE && inner->child_count >= 1) {
        inner = inner->children[0];
    }
    if (!inner) return IIIABI_OK;
    switch (inner->kind) {
        case III_AST_PRIMITIVE_TYPE: {
            char buf[32];
            iiiabi_node_text(inner, buf, sizeof buf);
            iii_abi_type_kind_t k = iiiabi_type_from_name(buf, strlen(buf));
            if (k == IIIABI_T_VOID) {
                /* "string"/"mhash" are primitives in III but not legal
                 * across the C bridge. */
                diag_set(out_diag, IIIABI_E_FORBIDDEN_TYPE, inner,
                         "extern bridge rejects higher-kinded primitive "
                         "'%s' (only u8..u64, i8..i64, f32, f64, bool)",
                         buf);
                return IIIABI_E_FORBIDDEN_TYPE;
            }
            return IIIABI_OK;
        }
        case III_AST_ARRAY_TYPE: {
            /* Element must itself be a legal extern_type; recurse. */
            if (inner->child_count == 0) return IIIABI_OK;
            return validate_extern_type(inner->children[0],
                                        extern_decl, out_diag);
        }
        case III_AST_BASE_TYPE: {
            /* IDENT — must resolve against the same extern block. */
            char name[64];
            iiiabi_node_text(inner, name, sizeof name);
            size_t nlen = strlen(name);
            iii_abi_type_kind_t rt; uint32_t rs, ra, rec; iii_abi_type_kind_t ret;
            if (!iiiabi_resolve_alias(extern_decl, name, nlen,
                                      &rt, &rs, &ra, &rec, &ret)) {
                diag_set(out_diag, IIIABI_E_BAD_ALIAS, inner,
                         "unknown extern type alias '%s' "
                         "(must be declared inside this extern block)",
                         name);
                return IIIABI_E_BAD_ALIAS;
            }
            return IIIABI_OK;
        }
        default:
            diag_set(out_diag, IIIABI_E_FORBIDDEN_TYPE, inner,
                     "extern bridge rejects AST kind %d "
                     "(higher-kinded III type)", (int)inner->kind);
            return IIIABI_E_FORBIDDEN_TYPE;
    }
}

static int validate_items(const iii_ast_node_t *extern_decl,
                          iii_abi_diag_t *out_diag) {
    for (uint32_t i = 0; i < extern_decl->child_count; ++i) {
        const iii_ast_node_t *it = extern_decl->children[i];
        if (!it || it->kind != III_AST_EXTERN_ITEM) continue;
        if (it->op_id == 0) {
            /* fn — last child is return, others are PARAM nodes. */
            for (uint32_t j = 0; j < it->child_count; ++j) {
                const iii_ast_node_t *c = it->children[j];
                if (!c) continue;
                if (c->kind == III_AST_PARAM) {
                    /* PARAM child[0] is its type. */
                    if (c->child_count >= 1) {
                        int r = validate_extern_type(c->children[0],
                                                     extern_decl, out_diag);
                        if (r != IIIABI_OK) return r;
                    }
                } else {
                    int r = validate_extern_type(c, extern_decl, out_diag);
                    if (r != IIIABI_OK) return r;
                }
            }
        } else if (it->op_id == 1) {
            /* type alias: child[0] is the type expression. */
            if (it->child_count >= 1) {
                int r = validate_extern_type(it->children[0],
                                             extern_decl, out_diag);
                if (r != IIIABI_OK) return r;
            }
        }
    }
    return IIIABI_OK;
}

int iii_abi_validate_extern(const iii_ast_node_t *module,
                            const iii_ast_node_t *extern_decl,
                            const uint8_t *src, size_t src_len,
                            iii_abi_diag_t *out_diag) {
    diag_ok(out_diag);
    if (!extern_decl) {
        diag_set(out_diag, IIIABI_E_NULL_ARG, NULL, "extern_decl is NULL");
        return IIIABI_E_NULL_ARG;
    }
    if (extern_decl->kind != III_AST_EXTERN_DECL) {
        diag_set(out_diag, IIIABI_E_NOT_EXTERN_DECL, extern_decl,
                 "node is not III_AST_EXTERN_DECL (got kind %d)",
                 (int)extern_decl->kind);
        return IIIABI_E_NOT_EXTERN_DECL;
    }

    /* §1.1 — must carry @abi modifier. */
    if (extern_decl->op_id == 0) {
        diag_set(out_diag, IIIABI_E_MISSING_ABI, extern_decl,
                 "extern declaration is missing @abi(...) clause");
        return IIIABI_E_MISSING_ABI;
    }

    /* §1.2.1 — name must be exactly c-msvc-x64. */
    char name[64];
    size_t n = iiiabi_extract_abi_name(extern_decl, src, src_len,
                                       name, sizeof name);
    if (n == 0) {
        diag_set(out_diag, IIIABI_E_MISSING_ABI, extern_decl,
                 "extern @abi(...) clause is empty or unreadable");
        return IIIABI_E_MISSING_ABI;
    }
    if (n != strlen(IIIABI_NAME_C_MSVC_X64) ||
        memcmp(name, IIIABI_NAME_C_MSVC_X64, n) != 0) {
        diag_set(out_diag, IIIABI_E_BAD_ABI_NAME, extern_decl,
                 "ABI name '%s' is not admitted; only '%s' is legal "
                 "(C-ABI-1)", name, IIIABI_NAME_C_MSVC_X64);
        return IIIABI_E_BAD_ABI_NAME;
    }

    /* §1.2.2 / §1.2.4 — ring restriction. */
    if (module) {
        int r = validate_ring(module, extern_decl, out_diag);
        if (r != IIIABI_OK) return r;
    }

    /* §1.2.5 / C-ABI-4 — extern_type discipline. */
    int r = validate_items(extern_decl, out_diag);
    if (r != IIIABI_OK) return r;

    diag_ok(out_diag);
    return IIIABI_OK;
}

int iii_abi_validate_module(const iii_ast_node_t *module,
                            const uint8_t *src, size_t src_len,
                            iii_abi_diag_t *out_diag) {
    diag_ok(out_diag);
    if (!module) {
        diag_set(out_diag, IIIABI_E_NULL_ARG, NULL, "module is NULL");
        return IIIABI_E_NULL_ARG;
    }
    for (uint32_t i = 0; i < module->child_count; ++i) {
        const iii_ast_node_t *c = module->children[i];
        if (!c || c->kind != III_AST_EXTERN_DECL) continue;
        int r = iii_abi_validate_extern(module, c, src, src_len, out_diag);
        if (r != IIIABI_OK) return r;
    }
    return IIIABI_OK;
}
