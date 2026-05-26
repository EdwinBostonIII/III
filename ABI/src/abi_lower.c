/* III-ABI — signature lowering & alias resolution.
 *
 * Implements the C-MSVC-x64 calling convention descriptor for an
 * EXTERN_ITEM (fn …) AST node.  See iii/abi.h §5 for the convention.
 */
#include "abi_internal.h"

#include <stdio.h>
#include <string.h>

/* Power-of-two test. */
static int is_pow2(uint32_t n) { return n != 0 && (n & (n - 1)) == 0; }

static iii_abi_class_t classify(iii_abi_type_kind_t t,
                                uint32_t size,
                                int by_ref) {
    if (by_ref) return IIIABI_CLS_INTEGER;
    switch (t) {
        case IIIABI_T_VOID:  return IIIABI_CLS_VOID;
        case IIIABI_T_F32:
        case IIIABI_T_F64:   return IIIABI_CLS_SSE;
        case IIIABI_T_PTR:
        case IIIABI_T_BOOL:
        case IIIABI_T_U8: case IIIABI_T_U16: case IIIABI_T_U32: case IIIABI_T_U64:
        case IIIABI_T_I8: case IIIABI_T_I16: case IIIABI_T_I32: case IIIABI_T_I64:
            return IIIABI_CLS_INTEGER;
        case IIIABI_T_ARRAY:
        case IIIABI_T_ALIAS:
            /* Aggregates pass in INTEGER class iff size ∈ {1,2,4,8} and
             * power-of-two; otherwise MEMORY (by hidden ref). */
            if (size == 1 || size == 2 || size == 4 || size == 8) {
                if (is_pow2(size)) return IIIABI_CLS_INTEGER;
            }
            return IIIABI_CLS_MEMORY;
    }
    return IIIABI_CLS_MEMORY;
}

/* Resolve an IDENT alias declared inside the same extern_decl by
 * scanning its EXTERN_ITEM children with op_id==1.  Recurses through
 * one alias level (alias-of-alias is supported up to depth 8). */
int iiiabi_resolve_alias(const iii_ast_node_t *extern_decl,
                         const char *alias_name, size_t alias_len,
                         iii_abi_type_kind_t *out_type,
                         uint32_t            *out_size,
                         uint32_t            *out_align,
                         uint32_t            *out_elem_count,
                         iii_abi_type_kind_t *out_elem_type) {
    if (!extern_decl || !alias_name) return 0;
    char buf[64];
    if (alias_len >= sizeof buf) return 0;
    memcpy(buf, alias_name, alias_len);
    buf[alias_len] = '\0';

    for (int depth = 0; depth < 8; ++depth) {
        const iii_ast_node_t *match = NULL;
        for (uint32_t i = 0; i < extern_decl->child_count; ++i) {
            const iii_ast_node_t *it = extern_decl->children[i];
            if (!it || it->kind != III_AST_EXTERN_ITEM) continue;
            if (it->op_id != 1) continue;
            char nm[64];
            iiiabi_node_text(it, nm, sizeof nm);
            if (strcmp(nm, buf) == 0) { match = it; break; }
        }
        if (!match || match->child_count == 0) return 0;
        const iii_ast_node_t *t = match->children[0];

        /* Strip wrappers. */
        while (t && t->kind == III_AST_TYPE && t->child_count >= 1)
            t = t->children[0];
        if (!t) return 0;

        if (t->kind == III_AST_PRIMITIVE_TYPE) {
            char pn[32]; iiiabi_node_text(t, pn, sizeof pn);
            iii_abi_type_kind_t k = iiiabi_type_from_name(pn, strlen(pn));
            if (k == IIIABI_T_VOID) return 0;
            if (out_type) *out_type = k;
            if (out_size) *out_size = iiiabi_type_size(k);
            if (out_align) *out_align = iiiabi_type_align(k);
            if (out_elem_count) *out_elem_count = 0;
            if (out_elem_type) *out_elem_type = IIIABI_T_VOID;
            return 1;
        }
        if (t->kind == III_AST_ARRAY_TYPE) {
            uint32_t n = (uint32_t)t->int_value;
            iii_abi_type_kind_t et = IIIABI_T_VOID;
            if (t->child_count >= 1) {
                const iii_ast_node_t *e = t->children[0];
                while (e && e->kind == III_AST_TYPE && e->child_count >= 1)
                    e = e->children[0];
                if (e && e->kind == III_AST_PRIMITIVE_TYPE) {
                    char pn[32]; iiiabi_node_text(e, pn, sizeof pn);
                    et = iiiabi_type_from_name(pn, strlen(pn));
                }
            }
            uint32_t es = iiiabi_type_size(et);
            uint32_t ea = iiiabi_type_align(et);
            uint32_t total = n * es;
            if (out_type) *out_type = IIIABI_T_ARRAY;
            if (out_size) *out_size = total;
            if (out_align) *out_align = ea;
            if (out_elem_count) *out_elem_count = n;
            if (out_elem_type) *out_elem_type = et;
            return 1;
        }
        if (t->kind == III_AST_BASE_TYPE) {
            /* Alias-of-alias: rebind buf and recurse. */
            char nm[64]; iiiabi_node_text(t, nm, sizeof nm);
            size_t l = strlen(nm);
            if (l == 0 || l >= sizeof buf) return 0;
            memcpy(buf, nm, l);
            buf[l] = '\0';
            continue;
        }
        return 0;
    }
    return 0;
}

int iiiabi_describe_type(const iii_ast_node_t *extern_decl,
                         const iii_ast_node_t *type_node,
                         iii_abi_param_t      *out) {
    if (!out) return IIIABI_E_NULL_ARG;
    memset(out, 0, sizeof *out);

    /* Unit return is encoded as `()` — III_AST_TUPLE_TYPE with no
     * children, wrapped in III_AST_TYPE. */
    if (!type_node) {
        out->type = IIIABI_T_VOID;
        out->cls  = IIIABI_CLS_VOID;
        return IIIABI_OK;
    }

    /* Strip outer wrapper. */
    const iii_ast_node_t *t = type_node;
    int ref_layers = 0;
    if (t->kind == III_AST_TYPE && t->child_count >= 1) {
        t = t->children[0];
    }
    /* Each additional III_AST_TYPE wrapper = one '&' layer. */
    while (t && t->kind == III_AST_TYPE && t->child_count >= 1) {
        ref_layers++;
        t = t->children[0];
    }
    if (!t) {
        out->type = IIIABI_T_VOID;
        out->cls  = IIIABI_CLS_VOID;
        return IIIABI_OK;
    }
    if (t->kind == III_AST_TUPLE_TYPE && t->child_count == 0) {
        out->type = IIIABI_T_VOID;
        out->cls  = IIIABI_CLS_VOID;
        return IIIABI_OK;
    }

    if (ref_layers > 0) {
        /* Reference to anything is a pointer (8 bytes). */
        out->type = IIIABI_T_PTR;
        out->size = 8;
        out->align = 8;
        /* Record pointee for diagnostic. */
        if (t->kind == III_AST_PRIMITIVE_TYPE) {
            char pn[32]; iiiabi_node_text(t, pn, sizeof pn);
            out->elem_type = iiiabi_type_from_name(pn, strlen(pn));
        } else if (t->kind == III_AST_ARRAY_TYPE) {
            out->elem_type = IIIABI_T_ARRAY;
            out->elem_count = (uint32_t)t->int_value;
        } else if (t->kind == III_AST_BASE_TYPE) {
            out->elem_type = IIIABI_T_ALIAS;
        }
        out->cls = IIIABI_CLS_INTEGER;
        return IIIABI_OK;
    }

    if (t->kind == III_AST_PRIMITIVE_TYPE) {
        char pn[32]; iiiabi_node_text(t, pn, sizeof pn);
        iii_abi_type_kind_t k = iiiabi_type_from_name(pn, strlen(pn));
        if (k == IIIABI_T_VOID) return IIIABI_E_FORBIDDEN_TYPE;
        out->type  = k;
        out->size  = iiiabi_type_size(k);
        out->align = iiiabi_type_align(k);
        out->cls   = classify(k, out->size, 0);
        return IIIABI_OK;
    }
    if (t->kind == III_AST_ARRAY_TYPE) {
        uint32_t n = (uint32_t)t->int_value;
        iii_abi_type_kind_t et = IIIABI_T_VOID;
        if (t->child_count >= 1) {
            const iii_ast_node_t *e = t->children[0];
            while (e && e->kind == III_AST_TYPE && e->child_count >= 1)
                e = e->children[0];
            if (e && e->kind == III_AST_PRIMITIVE_TYPE) {
                char pn[32]; iiiabi_node_text(e, pn, sizeof pn);
                et = iiiabi_type_from_name(pn, strlen(pn));
            }
        }
        out->type       = IIIABI_T_ARRAY;
        out->elem_count = n;
        out->elem_type  = et;
        uint32_t es = iiiabi_type_size(et);
        out->size  = n * es;
        out->align = iiiabi_type_align(et);
        out->cls   = classify(IIIABI_T_ARRAY, out->size, 0);
        return IIIABI_OK;
    }
    if (t->kind == III_AST_BASE_TYPE) {
        char nm[64]; iiiabi_node_text(t, nm, sizeof nm);
        iii_abi_type_kind_t rt = IIIABI_T_VOID;
        uint32_t rs = 0, ra = 0, rec = 0;
        iii_abi_type_kind_t ret = IIIABI_T_VOID;
        if (!iiiabi_resolve_alias(extern_decl, nm, strlen(nm),
                                  &rt, &rs, &ra, &rec, &ret)) {
            return IIIABI_E_BAD_ALIAS;
        }
        if (rt == IIIABI_T_ARRAY) {
            out->type       = IIIABI_T_ALIAS;
            out->elem_count = rec;
            out->elem_type  = ret;
            out->size       = rs;
            out->align      = ra;
            out->cls        = classify(IIIABI_T_ALIAS, rs, 0);
        } else {
            out->type  = rt;
            out->size  = rs;
            out->align = ra;
            out->cls   = classify(rt, rs, 0);
        }
        return IIIABI_OK;
    }
    return IIIABI_E_FORBIDDEN_TYPE;
}

/* Assign register/stack locations.  `start_reg_idx` allows the caller
 * to push the first slot to RDX et al. when a hidden ret-ptr consumes
 * RCX. */
static void assign_locations(iii_abi_signature_t *sig, uint32_t start_reg_idx) {
    static const iii_abi_loc_t INT_REGS[4] = {
        IIIABI_LOC_RCX, IIIABI_LOC_RDX, IIIABI_LOC_R8, IIIABI_LOC_R9
    };
    static const iii_abi_loc_t SSE_REGS[4] = {
        IIIABI_LOC_XMM0, IIIABI_LOC_XMM1, IIIABI_LOC_XMM2, IIIABI_LOC_XMM3
    };
    int32_t stack_off = 0;
    for (uint32_t i = 0; i < sig->param_count; ++i) {
        iii_abi_param_t *p = &sig->params[i];
        uint32_t slot = i + start_reg_idx;
        p->by_hidden_ref = (p->cls == IIIABI_CLS_MEMORY) ? 1 : 0;
        if (p->cls == IIIABI_CLS_MEMORY) {
            /* hidden pointer in INTEGER slot */
            if (slot < 4) p->loc = INT_REGS[slot];
            else { p->loc = IIIABI_LOC_STACK; p->stack_offset = stack_off; stack_off += 8; }
        } else if (p->cls == IIIABI_CLS_SSE) {
            if (slot < 4) p->loc = SSE_REGS[slot];
            else { p->loc = IIIABI_LOC_STACK; p->stack_offset = stack_off; stack_off += 8; }
        } else if (p->cls == IIIABI_CLS_INTEGER) {
            if (slot < 4) p->loc = INT_REGS[slot];
            else { p->loc = IIIABI_LOC_STACK; p->stack_offset = stack_off; stack_off += 8; }
        } else {
            p->loc = IIIABI_LOC_NONE;
        }
    }
    sig->shadow_space = 32;
    sig->stack_arg_bytes = (uint32_t)stack_off;
    /* Total caller-side stack reservation: shadow + stack args, rounded
     * up to 16 to maintain ABI alignment at the call site. */
    uint32_t total = sig->shadow_space + sig->stack_arg_bytes;
    if (total & 15u) total = (total + 15u) & ~15u;
    sig->total_stack = total;
}

static void assign_return(iii_abi_signature_t *sig) {
    switch (sig->ret.cls) {
        case IIIABI_CLS_VOID:    sig->ret.loc = IIIABI_LOC_NONE;     sig->hidden_ret_ptr = 0; break;
        case IIIABI_CLS_INTEGER: sig->ret.loc = IIIABI_LOC_RAX;      sig->hidden_ret_ptr = 0; break;
        case IIIABI_CLS_SSE:     sig->ret.loc = IIIABI_LOC_XMM0_RET; sig->hidden_ret_ptr = 0; break;
        case IIIABI_CLS_MEMORY:  sig->ret.loc = IIIABI_LOC_HIDDEN_PTR; sig->hidden_ret_ptr = 1; break;
    }
}

int iii_abi_lower_signature(const iii_ast_node_t *extern_decl,
                            const iii_ast_node_t *extern_item,
                            iii_abi_signature_t *sig_out) {
    if (!sig_out) return IIIABI_E_NULL_ARG;
    memset(sig_out, 0, sizeof *sig_out);
    sig_out->abi = IIIABI_C_MSVC_X64;
    sig_out->shadow_space = 32;

    if (!extern_item || extern_item->kind != III_AST_EXTERN_ITEM)
        return IIIABI_E_NOT_EXTERN_ITEM;
    if (extern_item->op_id != 0) return IIIABI_E_NOT_FN_ITEM;

    iiiabi_node_text(extern_item, sig_out->name, sizeof sig_out->name);

    /* Children: zero or more III_AST_PARAM, then a return type child. */
    uint32_t n_children = extern_item->child_count;
    if (n_children == 0) {
        sig_out->ret.type = IIIABI_T_VOID;
        sig_out->ret.cls  = IIIABI_CLS_VOID;
        assign_return(sig_out);
        sig_out->total_stack = 32;
        return IIIABI_OK;
    }

    /* The last child is the return type (PARAM nodes precede it). */
    const iii_ast_node_t *ret_node = NULL;
    uint32_t param_end = n_children;
    /* Find the trailing non-PARAM child as return. */
    for (uint32_t i = n_children; i > 0; --i) {
        const iii_ast_node_t *c = extern_item->children[i - 1];
        if (c && c->kind != III_AST_PARAM) {
            ret_node = c;
            param_end = i - 1;
            break;
        }
    }

    if (param_end > IIIABI_MAX_PARAMS) return IIIABI_E_TOO_MANY_PARAMS;

    for (uint32_t i = 0; i < param_end; ++i) {
        const iii_ast_node_t *p = extern_item->children[i];
        if (!p || p->kind != III_AST_PARAM) continue;
        iii_abi_param_t *pp = &sig_out->params[sig_out->param_count];
        memset(pp, 0, sizeof *pp);
        iiiabi_node_text(p, pp->name, sizeof pp->name);
        const iii_ast_node_t *ty = p->child_count >= 1 ? p->children[0] : NULL;
        int rc = iiiabi_describe_type(extern_decl, ty, pp);
        if (rc != IIIABI_OK) return rc;
        sig_out->param_count++;
    }

    int rc = iiiabi_describe_type(extern_decl, ret_node, &sig_out->ret);
    if (rc != IIIABI_OK) return rc;
    assign_return(sig_out);

    /* If return-by-hidden-ptr, RCX is consumed: shift all args one
     * register to the right. */
    uint32_t start_reg = sig_out->hidden_ret_ptr ? 1u : 0u;
    assign_locations(sig_out, start_reg);
    return IIIABI_OK;
}

/* ---------------------------------------------------------------- */
/* §7 — synthetic builder for tools/tests.                          */
/* ---------------------------------------------------------------- */

void iii_abi_signature_init(iii_abi_signature_t *sig, const char *name) {
    if (!sig) return;
    memset(sig, 0, sizeof *sig);
    sig->abi = IIIABI_C_MSVC_X64;
    sig->shadow_space = 32;
    if (name) {
        size_t l = strlen(name);
        if (l >= sizeof sig->name) l = sizeof sig->name - 1;
        memcpy(sig->name, name, l);
        sig->name[l] = '\0';
    }
}

int iii_abi_signature_set_return(iii_abi_signature_t *sig,
                                 iii_abi_type_kind_t ret) {
    if (!sig) return IIIABI_E_NULL_ARG;
    memset(&sig->ret, 0, sizeof sig->ret);
    sig->ret.type  = ret;
    sig->ret.size  = iiiabi_type_size(ret);
    sig->ret.align = iiiabi_type_align(ret);
    sig->ret.cls   = classify(ret, sig->ret.size, 0);
    return IIIABI_OK;
}

int iii_abi_signature_add_param(iii_abi_signature_t *sig,
                                const char *name,
                                iii_abi_type_kind_t type,
                                uint32_t elem_count,
                                iii_abi_type_kind_t elem_type) {
    if (!sig) return IIIABI_E_NULL_ARG;
    if (sig->param_count >= IIIABI_MAX_PARAMS) return IIIABI_E_TOO_MANY_PARAMS;
    iii_abi_param_t *p = &sig->params[sig->param_count];
    memset(p, 0, sizeof *p);
    if (name) {
        size_t l = strlen(name);
        if (l >= sizeof p->name) l = sizeof p->name - 1;
        memcpy(p->name, name, l);
        p->name[l] = '\0';
    }
    p->type = type;
    if (type == IIIABI_T_ARRAY) {
        p->elem_count = elem_count;
        p->elem_type  = elem_type;
        uint32_t es = iiiabi_type_size(elem_type);
        p->size  = elem_count * es;
        p->align = iiiabi_type_align(elem_type);
    } else {
        p->size  = iiiabi_type_size(type);
        p->align = iiiabi_type_align(type);
    }
    p->cls = classify(type, p->size, 0);
    sig->param_count++;
    return IIIABI_OK;
}

void iii_abi_signature_finalize(iii_abi_signature_t *sig) {
    if (!sig) return;
    /* Recompute classes (in case the builder set fields directly). */
    for (uint32_t i = 0; i < sig->param_count; ++i) {
        iii_abi_param_t *p = &sig->params[i];
        if (p->size == 0 && p->type != IIIABI_T_VOID && p->type != IIIABI_T_ARRAY) {
            p->size  = iiiabi_type_size(p->type);
            p->align = iiiabi_type_align(p->type);
        }
        p->cls = classify(p->type, p->size, 0);
    }
    sig->ret.cls = classify(sig->ret.type, sig->ret.size, 0);
    assign_return(sig);
    uint32_t start_reg = sig->hidden_ret_ptr ? 1u : 0u;
    assign_locations(sig, start_reg);
}
