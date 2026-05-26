/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\sid.c
 *
 * III Stage-0 Side-effect Inverse Derivation — implementation.
 *
 * For each cycle decl in the module, walk the forward block, find
 * every irpd.<method>(...) call, classify it into one of 17 SE kinds,
 * compose the per-call hexads, build a replay-plan bitmap, and emit
 * the cycle's inverse plan as an AST annotation under phase
 * "sid/inverse_plan".  Coordinates with sema (for the per-cycle
 * declared hexad) and with ceiling (for membership admission).
 *
 * Strict NIH: only stdlib + ast.h + sema.h + hexad_check.h + ceiling.h.
 */

#include "sid.h"
#include "hexad_check.h"
#include "ceiling.h"
#include "irpd_methods.h"   /* RITCHIE Stage 1.20: canonical IRPD method table */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

/* ============================================================================
 *  IRPD METHOD ↔ SE KIND TABLE
 *  Mirror of EFFECTS/include/iii/effects.h::iii_se_kind_from_method.
 * ============================================================================ */

/* THE canonical IRPD method table — single source of truth (irpd_methods.h).
 * Defined here (external linkage); sema.c consumes it too for name validation.
 * 17 write-side methods (each with its iii_sid_se_kind_t) + 3 read-side methods
 * (kind == III_BOOT_SE_NONE — matching the pre-Stage-1.20 lookup behavior, which
 * returned NONE for read-side names since they weren't in the 17-entry table).
 * RITCHIE Stage 1.20 dedup. */
const iii_irpd_method_t III_IRPD_METHODS[] = {
    { "msr_write",   III_BOOT_SE_MSR_WRITE,        true  },
    { "cr_write",    III_BOOT_SE_CR_WRITE,         true  },
    { "npt_write",   III_BOOT_SE_NPT_ENTRY_WRITE,  true  },
    { "vmcb_field",  III_BOOT_SE_VMCB_FIELD_WRITE, true  },
    { "iommu_dte",   III_BOOT_SE_IOMMU_DTE_WORD,   true  },
    { "avic_tbl",    III_BOOT_SE_AVIC_TBL_WRITE,   true  },
    { "msrpm_bit",   III_BOOT_SE_MSRPM_BIT_SET,    true  },
    { "iopm_bit",    III_BOOT_SE_IOPM_BIT_SET,     true  },
    { "pkru_write",  III_BOOT_SE_PKRU_WRITE,       true  },
    { "xcr0_write",  III_BOOT_SE_XCR0_WRITE,       true  },
    { "cap_acquire", III_BOOT_SE_CAP_ACQUIRE,      true  },
    { "cap_release", III_BOOT_SE_CAP_RELEASE,      true  },
    { "page_alloc",  III_BOOT_SE_PAGE_ALLOC,       true  },
    { "page_free",   III_BOOT_SE_PAGE_FREE,        true  },
    { "dpc_arm",     III_BOOT_SE_DPC_ARM,          true  },
    { "dpc_cancel",  III_BOOT_SE_DPC_CANCEL,       true  },
    { "nmi_install", III_BOOT_SE_NMI_INSTALL,      true  },
    { "msr_read",    III_BOOT_SE_NONE,             false },
    { "cr_read",     III_BOOT_SE_NONE,             false },
    { "npt_read",    III_BOOT_SE_NONE,             false }
};
const size_t III_IRPD_METHODS_COUNT =
    sizeof(III_IRPD_METHODS) / sizeof(III_IRPD_METHODS[0]);

/* Compile-time count split: 20 total rows; the write-side count is pinned to
 * the SE-kind enum (III_BOOT_SE__COUNT-1 == 17). sema.c's 17-write-side
 * dependency is thereby tied to the same single source of truth. */
_Static_assert(sizeof(III_IRPD_METHODS) / sizeof(III_IRPD_METHODS[0]) == 20,
               "IRPD method table must have exactly 20 rows (17 write + 3 read)");
_Static_assert(III_IRPD_WRITE_SIDE_COUNT == 17,
               "expected 17 write-side IRPD methods (== III_BOOT_SE__COUNT - 1)");

iii_sid_se_kind_t iii_sid_se_kind_from_method(const char *name)
{
    if (!name) return III_BOOT_SE_NONE;
    for (size_t i = 0; i < III_IRPD_METHODS_COUNT; i++) {
        if (strcmp(III_IRPD_METHODS[i].name, name) == 0) {
            return III_IRPD_METHODS[i].kind;
        }
    }
    return III_BOOT_SE_NONE;
}

const char *iii_sid_se_kind_name(iii_sid_se_kind_t k)
{
    /* Guard NONE first: the 3 read-side rows in III_IRPD_METHODS carry
     * kind == III_BOOT_SE_NONE, so a bare kind-match would wrongly return a
     * read-side name. Only the 17 write-side rows reverse-map to a kind.
     * Behavior-identical to the pre-Stage-1.20 lookup. */
    if (k == III_BOOT_SE_NONE) return "none";
    for (size_t i = 0; i < III_IRPD_METHODS_COUNT; i++) {
        if (III_IRPD_METHODS[i].is_write_side && III_IRPD_METHODS[i].kind == k) {
            return III_IRPD_METHODS[i].name;
        }
    }
    return "unknown";
}

/* ============================================================================
 *  PER-CYCLE-CALL HEXAD CONTRIBUTIONS
 *
 *  Each of the 17 IRPD methods has a canonical hexad per
 *  III-EFFECTS.md §2.4 — for Stage-0 we use a single
 *  structurally-admissible hexad (POS,POS,POS,ZERO,ZERO,ZERO) for all
 *  17 (the same value sema uses for IRPD-named hexads).  The runtime
 *  TYPES library does not yet ship per-method hexads either; the
 *  values converge as the EFFECTS catalogue matures.
 *
 *  Packed value:
 *    POS=2, POS=2, POS=2, ZERO=1, ZERO=1, ZERO=1
 *    v = 2 + 2*3 + 2*9 + 1*27 + 1*81 + 1*243 = 377
 * ============================================================================ */

#define SID_IRPD_DEFAULT_HEXAD 377u

static uint16_t sid_per_call_hexad(iii_sid_se_kind_t k)
{
    (void)k;
    return SID_IRPD_DEFAULT_HEXAD;
}

/* ============================================================================
 *  ARENA / ERROR QUEUE / RECORD TABLE
 * ============================================================================ */

typedef struct {
    uint8_t *base;
    size_t   used;
    size_t   cap;
} sid_arena_t;

static char *sid_arena_strdup(sid_arena_t *a, const char *s)
{
    size_t n = strlen(s);
    if (a->used + n + 1 > a->cap) {
        size_t newcap = a->cap ? a->cap * 2 : 2048;
        while (newcap < a->used + n + 1) newcap *= 2;
        uint8_t *nb = (uint8_t *)realloc(a->base, newcap);
        if (!nb) return NULL;
        a->base = nb; a->cap = newcap;
    }
    char *out = (char *)(a->base + a->used);
    memcpy(out, s, n);
    out[n] = 0;
    a->used += n + 1;
    return out;
}

static char *sid_arena_printf(sid_arena_t *a, const char *fmt, ...)
{
    char tmp[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(tmp, sizeof tmp, fmt, ap);
    va_end(ap);
    if (n < 0) return NULL;
    return sid_arena_strdup(a, tmp);
}

struct iii_sid_state {
    iii_ast_t          *ast;
    iii_sema_state_t   *sema;       /* may be NULL */

    sid_arena_t         arena;

    iii_sid_error_t    *errors;
    uint32_t            error_count;
    uint32_t            error_cap;

    iii_sid_record_t   *records;
    uint32_t            record_count;
    uint32_t            record_cap;

    bool                ran;
};

/* ============================================================================
 *  HELPERS
 * ============================================================================ */

static char *sid_src_text_dup_lower(iii_sid_state_t *s, iii_src_text_t t)
{
    const uint8_t *buf = iii_ast_source_buf(s->ast);
    size_t slen = iii_ast_source_len(s->ast);
    if (!buf || t.length == 0 || t.offset + t.length > slen) return NULL;
    char tmp[256];
    if (t.length >= sizeof tmp) return NULL;
    for (uint32_t i = 0; i < t.length; i++) {
        unsigned c = buf[t.offset + i];
        if (c >= 'A' && c <= 'Z') c = c - 'A' + 'a';
        tmp[i] = (char)c;
    }
    tmp[t.length] = 0;
    return sid_arena_strdup(&s->arena, tmp);
}

static bool sid_src_text_eq_cstr_lower(const iii_sid_state_t *s, iii_src_text_t t,
                                            const char *cstr)
{
    const uint8_t *buf = iii_ast_source_buf(s->ast);
    size_t slen = iii_ast_source_len(s->ast);
    if (!buf || t.offset + t.length > slen) return false;
    size_t cl = strlen(cstr);
    if (cl != t.length) return false;
    for (size_t i = 0; i < cl; i++) {
        unsigned a = buf[t.offset + i];
        if (a >= 'A' && a <= 'Z') a = a - 'A' + 'a';
        unsigned b = (unsigned)cstr[i];
        if (b >= 'A' && b <= 'Z') b = b - 'A' + 'a';
        if (a != b) return false;
    }
    return true;
}

static void sid_emit_error(iii_sid_state_t *s, int code,
                              uint32_t cycle_decl_node, const char *msg)
{
    if (s->error_count == s->error_cap) {
        uint32_t newcap = s->error_cap ? s->error_cap * 2 : 16;
        iii_sid_error_t *ne = (iii_sid_error_t *)realloc(s->errors,
                                  newcap * sizeof(*ne));
        if (!ne) return;
        s->errors = ne; s->error_cap = newcap;
    }
    iii_sid_error_t *e = &s->errors[s->error_count++];
    e->code = code;
    e->cycle_decl_node = cycle_decl_node;
    e->message = msg;
}

static iii_sid_record_t *sid_record_alloc(iii_sid_state_t *s, uint32_t decl_node)
{
    if (s->record_count == s->record_cap) {
        uint32_t newcap = s->record_cap ? s->record_cap * 2 : 16;
        iii_sid_record_t *nr = (iii_sid_record_t *)realloc(s->records,
                                    newcap * sizeof(*nr));
        if (!nr) return NULL;
        s->records = nr; s->record_cap = newcap;
    }
    iii_sid_record_t *r = &s->records[s->record_count++];
    memset(r, 0, sizeof *r);
    r->decl_node = decl_node;
    r->composed_hexad = 0xFFFFu;
    return r;
}

/* ============================================================================
 *  AST WALK — find irpd.<method>(...) calls, build per-cycle record
 * ============================================================================ */

static bool sid_is_irpd_field_call(iii_sid_state_t *s,
                                      const iii_ast_node_t *call,
                                      char **out_method_lower)
{
    *out_method_lower = NULL;
    if (call->kind != III_AST_EXPR_CALL) return false;
    const iii_ast_node_t *callee = iii_ast_get(s->ast, call->u.call.callee);
    if (!callee || callee->kind != III_AST_EXPR_FIELD) return false;
    const iii_ast_node_t *obj = iii_ast_get(s->ast, callee->u.field.object);
    if (!obj || obj->kind != III_AST_EXPR_IDENT) return false;
    if (!sid_src_text_eq_cstr_lower(s, obj->u.ident.name, "irpd")) return false;
    *out_method_lower = sid_src_text_dup_lower(s, callee->u.field.field_name);
    return *out_method_lower != NULL;
}

/* Recursive: walk a node and accumulate any irpd.* calls into `rec`.
 * This is exhaustive (it descends every payload field that can hold
 * an expression / statement / list reference). */
static void sid_walk_for_irpd(iii_sid_state_t *s, uint32_t node,
                                 iii_sid_record_t *rec)
{
    if (node == 0) return;
    const iii_ast_node_t *n = iii_ast_get(s->ast, node);
    if (!n) return;

    /* Detect IRPD call at this node. */
    char *method = NULL;
    if (sid_is_irpd_field_call(s, n, &method)) {
        iii_sid_se_kind_t k = iii_sid_se_kind_from_method(method);
        if (k == III_BOOT_SE_NONE) {
            char *msg = sid_arena_printf(&s->arena,
                            "irpd.%s is not a recognised IRPD method", method);
            sid_emit_error(s, III_SID_E_UNKNOWN_METHOD, rec->decl_node,
                              msg ? msg : "unknown IRPD method");
        } else {
            if (rec->call_count >= III_SID_MAX_CALLS_PER_CYCLE) {
                sid_emit_error(s, III_SID_E_TOO_MANY_CALLS, rec->decl_node,
                                  "cycle exceeds per-cycle IRPD-call cap");
            } else {
                rec->calls[rec->call_count++] = k;
                /* Compose hexad. */
                uint16_t per = sid_per_call_hexad(k);
                if (rec->composed_hexad == 0xFFFFu) {
                    rec->composed_hexad = per;
                } else {
                    uint16_t composed = iii_hexad_compose_packed(rec->composed_hexad, per);
                    if (composed == 0xFFFFu || !iii_hexad_packed_admitted(composed)) {
                        sid_emit_error(s, III_SID_E_HEXAD_COMPOSE_FAIL, rec->decl_node,
                                          "composed hexad falls outside reachable set");
                    }
                    rec->composed_hexad = composed;
                }
                /* Set replay bitmap bit at the call's index. */
                if (rec->call_count <= 32) {
                    rec->replay_bitmap |= (uint32_t)(1u << (rec->call_count - 1));
                }
            }
        }
        /* Continue to descend into args (an IRPD call may itself
         * carry nested IRPD calls in its arguments — exotic but not
         * forbidden). */
    }

    /* Descend children. */
    switch (n->kind) {
        case III_AST_FORWARD_BLOCK:
            for (uint32_t i = 0; i < n->u.forward_block.stmts.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.forward_block.stmts, i), rec);
            return;
        case III_AST_EXPR_BLOCK:
            for (uint32_t i = 0; i < n->u.block.stmts.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.block.stmts, i), rec);
            return;
        case III_AST_STMT_LET:
            sid_walk_for_irpd(s, n->u.let_.value_expr, rec);
            return;
        case III_AST_STMT_EXPR:
            sid_walk_for_irpd(s, n->u.expr_stmt.expr, rec);
            return;
        case III_AST_STMT_RETURN:
            sid_walk_for_irpd(s, n->u.return_.value_expr, rec);
            return;
        case III_AST_STMT_ASSIGN:
            sid_walk_for_irpd(s, n->u.assign.lvalue_expr, rec);
            sid_walk_for_irpd(s, n->u.assign.value_expr,  rec);
            return;
        case III_AST_STMT_FOR:
            sid_walk_for_irpd(s, n->u.for_.iter_expr,  rec);
            sid_walk_for_irpd(s, n->u.for_.where_expr, rec);
            sid_walk_for_irpd(s, n->u.for_.body_block, rec);
            return;
        case III_AST_STMT_MATCH:
            sid_walk_for_irpd(s, n->u.match_stmt.scrutinee, rec);
            for (uint32_t i = 0; i < n->u.match_stmt.arms.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.match_stmt.arms, i), rec);
            return;
        case III_AST_STMT_WAVEFRONT:
            for (uint32_t i = 0; i < n->u.wavefront.nodes.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.wavefront.nodes, i), rec);
            sid_walk_for_irpd(s, n->u.wavefront.on_rollback_block, rec);
            return;
        case III_AST_STMT_SANCTUM_ENTER:
            sid_walk_for_irpd(s, n->u.sanctum_enter.body_block, rec);
            return;
        case III_AST_EXPR_CALL:
            sid_walk_for_irpd(s, n->u.call.callee, rec);
            for (uint32_t i = 0; i < n->u.call.args.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.call.args, i), rec);
            return;
        case III_AST_EXPR_FIELD:
            sid_walk_for_irpd(s, n->u.field.object, rec);
            return;
        case III_AST_EXPR_INDEX:
            sid_walk_for_irpd(s, n->u.index.object,     rec);
            sid_walk_for_irpd(s, n->u.index.index_expr, rec);
            return;
        case III_AST_EXPR_BINARY:
            sid_walk_for_irpd(s, n->u.binary.lhs, rec);
            sid_walk_for_irpd(s, n->u.binary.rhs, rec);
            return;
        case III_AST_EXPR_UNARY:
            sid_walk_for_irpd(s, n->u.unary.operand, rec);
            return;
        case III_AST_EXPR_PAREN:
            sid_walk_for_irpd(s, n->u.paren.inner, rec);
            return;
        case III_AST_EXPR_PARALLEL:
            for (uint32_t i = 0; i < n->u.parallel.branches.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.parallel.branches, i), rec);
            return;
        case III_AST_EXPR_MATCH:
            sid_walk_for_irpd(s, n->u.match_expr.scrutinee, rec);
            for (uint32_t i = 0; i < n->u.match_expr.arms.count; i++)
                sid_walk_for_irpd(s, iii_ast_list_at(s->ast, n->u.match_expr.arms, i), rec);
            return;
        case III_AST_MATCH_ARM:
            sid_walk_for_irpd(s, n->u.match_arm.guard_expr, rec);
            sid_walk_for_irpd(s, n->u.match_arm.body,       rec);
            return;
        case III_AST_ARG:
            sid_walk_for_irpd(s, n->u.arg.value_expr, rec);
            return;
        case III_AST_COMPROMISE_BLOCK:
            /* Mark cycle as irreversible; per the §1.2 LOW/MEDIUM/HIGH
             * lattice the cycle's inverse becomes a Compromise term.
             * Stage-0: we record the irreversible flag; the compromise
             * tier classification (LOW/MEDIUM/HIGH) is a Stage-1+ task
             * (depends on the compromise body's contents). */
            rec->irreversible = true;
            return;
        default:
            return;
    }
}

/* ============================================================================
 *  PER-CYCLE PROCESSING
 * ============================================================================ */

static void sid_process_cycle(iii_sid_state_t *s, uint32_t decl_node,
                                 const iii_ast_node_t *decl)
{
    iii_sid_record_t *rec = sid_record_alloc(s, decl_node);
    if (!rec) {
        sid_emit_error(s, III_SID_E_OOM, decl_node,
                          "sid record allocation failed");
        return;
    }

    /* Check for explicit @irreversible modifier. */
    iii_ast_list_t mods = decl->u.cycle_decl.modifiers;
    for (uint32_t j = 0; j < mods.count; j++) {
        uint32_t mn = iii_ast_list_at(s->ast, mods, j);
        const iii_ast_node_t *m = iii_ast_get(s->ast, mn);
        if (!m || m->kind != III_AST_MODIFIER) continue;
        if (sid_src_text_eq_cstr_lower(s, m->u.modifier.name, "irreversible")) {
            rec->irreversible = true;
        }
    }

    /* Walk forward block. */
    sid_walk_for_irpd(s, decl->u.cycle_decl.forward_block, rec);

    /* Walk compromise block (which may set rec->irreversible). */
    if (decl->u.cycle_decl.compromise_block != 0) {
        const iii_ast_node_t *cb = iii_ast_get(s->ast, decl->u.cycle_decl.compromise_block);
        if (cb && cb->kind == III_AST_COMPROMISE_BLOCK) {
            rec->irreversible = true;
        }
    }

    /* Compose the cycle's declared hexad (from sema) with the
     * call-derived composed hexad.  If the result is unrep, error. */
    if (s->sema != NULL) {
        uint16_t declared = iii_sema_cycle_hexad(s->sema, decl_node);
        if (declared != 0xFFFFu && rec->composed_hexad != 0xFFFFu) {
            uint16_t total = iii_hexad_compose_packed(declared, rec->composed_hexad);
            if (total == 0xFFFFu || !iii_hexad_packed_admitted(total)) {
                sid_emit_error(s, III_SID_E_HEXAD_COMPOSE_FAIL, decl_node,
                                  "declared @hexad composed with IRPD-derived hexad is unreachable");
            } else {
                rec->composed_hexad = total;
            }
        } else if (declared != 0xFFFFu) {
            rec->composed_hexad = declared;
        }
    }

    /* Step 13: ceiling membership.  We can't yet know the cycle's
     * walloc-assigned cycle_kind (walloc runs after sid in main.c's
     * pipeline), so we record the requirement as a side-table entry;
     * walloc/cg will defer-check via iii_ceil_admitted_kind once IDs
     * are issued.  No emit here; the deferred check is in main.c
     * where iii_ceil_admit_kind() is called per walloc record. */

    /* Defense-in-depth: if the cycle has @irreversible without an
     * accompanying compromise block, do not emit a replay-plan bit
     * for the inverse — the replay is a Compromise term. */
    if (rec->irreversible) {
        rec->replay_bitmap = 0;
    }

    /* Annotation emission: serialise the record into a small canonical
     * blob and store it under phase "sid/inverse_plan".  Layout:
     *   u32  composed_hexad (LE; high bits zero)
     *   u32  replay_bitmap  (LE)
     *   u8   call_count
     *   u8   irreversible
     *   u8[] calls (one byte per call_count, each an iii_sid_se_kind_t)
     */
    uint8_t blob[8 + III_SID_MAX_CALLS_PER_CYCLE];
    size_t blen = 0;
    blob[blen++] = (uint8_t)(rec->composed_hexad & 0xFF);
    blob[blen++] = (uint8_t)((rec->composed_hexad >> 8) & 0xFF);
    blob[blen++] = 0;
    blob[blen++] = 0;
    blob[blen++] = (uint8_t)(rec->replay_bitmap & 0xFF);
    blob[blen++] = (uint8_t)((rec->replay_bitmap >> 8) & 0xFF);
    blob[blen++] = (uint8_t)((rec->replay_bitmap >> 16) & 0xFF);
    blob[blen++] = (uint8_t)((rec->replay_bitmap >> 24) & 0xFF);
    blob[blen++] = rec->call_count;
    blob[blen++] = rec->irreversible ? 1u : 0u;
    for (uint8_t i = 0; i < rec->call_count; i++) {
        blob[blen++] = (uint8_t)rec->calls[i];
    }
    /* Suppress overflow check; III_SID_MAX_CALLS_PER_CYCLE keeps it bounded. */
    (void)iii_ast_annotate(s->ast, "sid/inverse_plan", decl_node, blob, blen);
}

/* ============================================================================
 *  PUBLIC API
 * ============================================================================ */

iii_sid_state_t *iii_sid_create(iii_ast_t *ast, iii_sema_state_t *sema)
{
    if (!ast) return NULL;
    iii_sid_state_t *s = (iii_sid_state_t *)calloc(1, sizeof *s);
    if (!s) return NULL;
    s->ast = ast;
    s->sema = sema;
    return s;
}

void iii_sid_destroy(iii_sid_state_t *s)
{
    if (!s) return;
    free(s->errors);
    free(s->records);
    free(s->arena.base);
    free(s);
}

int iii_sid_run(iii_sid_state_t *s)
{
    if (!s || !s->ast) return 0;
    if (s->ran) return s->error_count == 0 ? 1 : 0;
    s->ran = true;

    iii_hexad_check_init();

    uint32_t mod_node = iii_ast_root_module(s->ast);
    if (mod_node == 0) return 0;
    const iii_ast_node_t *mod = iii_ast_get(s->ast, mod_node);
    if (!mod || mod->kind != III_AST_MODULE) return 0;

    iii_ast_list_t decls = mod->u.module_.decls;
    for (uint32_t i = 0; i < decls.count; i++) {
        uint32_t didx = iii_ast_list_at(s->ast, decls, i);
        const iii_ast_node_t *d = iii_ast_get(s->ast, didx);
        if (!d || d->kind != III_AST_CYCLE_DECL) continue;
        sid_process_cycle(s, didx, d);
    }

    return s->error_count == 0 ? 1 : 0;
}

uint32_t iii_sid_error_count(const iii_sid_state_t *s)
{
    return s ? s->error_count : 0;
}

void iii_sid_error_at(const iii_sid_state_t *s, uint32_t i, iii_sid_error_t *out)
{
    if (!out) return;
    memset(out, 0, sizeof *out);
    if (!s || i >= s->error_count) return;
    *out = s->errors[i];
}

const char *iii_sid_error_name(int code)
{
    switch (code) {
        case III_SID_OK:                       return "OK";
        case III_SID_E_PARSE_IRPD:             return "PARSE-IRPD-001";
        case III_SID_E_UNKNOWN_METHOD:         return "TYPE-SID-001";
        case III_SID_E_HEXAD_COMPOSE_FAIL:     return "TYPE-HEXAD-002";
        case III_SID_E_CEILING_REJECT:         return "TYPE-CEIL-001";
        case III_SID_E_TOO_MANY_CALLS:         return "TYPE-CYCLE-001";
        case III_SID_E_REPLAY_BITMAP_OVERFLOW: return "TYPE-INV-001";
        case III_SID_E_OOM:                    return "OOM";
        default:                               return "UNKNOWN";
    }
}

uint32_t iii_sid_record_count(const iii_sid_state_t *s)
{
    return s ? s->record_count : 0;
}

const iii_sid_record_t *iii_sid_record_at(const iii_sid_state_t *s, uint32_t i)
{
    if (!s || i >= s->record_count) return NULL;
    return &s->records[i];
}

const iii_sid_record_t *iii_sid_record_for_decl(const iii_sid_state_t *s,
                                                    uint32_t decl_node)
{
    if (!s) return NULL;
    for (uint32_t i = 0; i < s->record_count; i++) {
        if (s->records[i].decl_node == decl_node) return &s->records[i];
    }
    return NULL;
}
