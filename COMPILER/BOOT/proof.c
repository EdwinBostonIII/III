/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\proof.c
 *
 * III Stage-0 Proof Certificate Emitter — implementation.
 *
 * Per top-level decl: emit a 32-byte SHA-256 over the canonical bytes
 * of (kind, name, modifier set, hexad, ring, tier, epoch, body
 * mhash).  Stored as AST annotation phase "proof/cert_mhash".
 *
 * Strict NIH: only stdlib + ast.h + sema.h + hexad_check.h.  Hand-rolled
 * SHA-256 lives in this TU (parity with the per-TU SHA-256 strategy
 * the rest of BOOT uses).
 */

#include "proof.h"
#include "hexad_check.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

/* ============================================================================
 *  PRIVATE SHA-256 (FIPS 180-4 §6.2) — same as hexad_check.c / ceiling.c
 * ============================================================================ */

typedef struct {
    uint32_t h[8];
    uint64_t bits;
    uint8_t  buf[64];
    size_t   buflen;
} pf_sha_t;

static const uint32_t PF_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};
static uint32_t pf_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32 - n)); }
static void pf_init(pf_sha_t *c) {
    c->h[0]=0x6a09e667u; c->h[1]=0xbb67ae85u; c->h[2]=0x3c6ef372u; c->h[3]=0xa54ff53au;
    c->h[4]=0x510e527fu; c->h[5]=0x9b05688cu; c->h[6]=0x1f83d9abu; c->h[7]=0x5be0cd19u;
    c->bits = 0; c->buflen = 0;
}
static void pf_block(pf_sha_t *c, const uint8_t blk[64]) {
    uint32_t w[64];
    for (int i = 0; i < 16; i++)
        w[i] = ((uint32_t)blk[i*4]<<24)|((uint32_t)blk[i*4+1]<<16)|
               ((uint32_t)blk[i*4+2]<<8)|((uint32_t)blk[i*4+3]);
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = pf_rotr(w[i-15],7)^pf_rotr(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1 = pf_rotr(w[i-2],17)^pf_rotr(w[i-2],19)^(w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = pf_rotr(e,6)^pf_rotr(e,11)^pf_rotr(e,25);
        uint32_t ch = (e&f)^(~e&g);
        uint32_t t1 = h + S1 + ch + PF_K[i] + w[i];
        uint32_t S0 = pf_rotr(a,2)^pf_rotr(a,13)^pf_rotr(a,22);
        uint32_t mj = (a&b)^(a&cc)^(b&cc);
        uint32_t t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=cc; cc=b; b=a; a=t1+t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g; c->h[7]+=h;
}
static void pf_update(pf_sha_t *c, const void *data, size_t len) {
    const uint8_t *p = (const uint8_t *)data;
    c->bits += (uint64_t)len * 8;
    while (len) {
        size_t take = 64 - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take; p += take; len -= take;
        if (c->buflen == 64) { pf_block(c, c->buf); c->buflen = 0; }
    }
}
static void pf_final(pf_sha_t *c, uint8_t out[32]) {
    uint64_t bits = c->bits;
    uint8_t pad = 0x80;
    pf_update(c, &pad, 1);
    uint8_t zero = 0;
    while (c->buflen != 56) pf_update(c, &zero, 1);
    uint8_t lenbe[8];
    for (int i = 0; i < 8; i++) lenbe[i] = (uint8_t)(bits >> (56 - 8*i));
    pf_update(c, lenbe, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(c->h[i] >> 24);
        out[i*4+1] = (uint8_t)(c->h[i] >> 16);
        out[i*4+2] = (uint8_t)(c->h[i] >> 8);
        out[i*4+3] = (uint8_t)(c->h[i]);
    }
}
static void pf_update_u32(pf_sha_t *c, uint32_t v)
{
    uint8_t b[4] = {
        (uint8_t)(v & 0xFF),
        (uint8_t)((v >> 8) & 0xFF),
        (uint8_t)((v >> 16) & 0xFF),
        (uint8_t)((v >> 24) & 0xFF)
    };
    pf_update(c, b, 4);
}
static void pf_update_u64(pf_sha_t *c, uint64_t v)
{
    uint8_t b[8];
    for (int i = 0; i < 8; i++) b[i] = (uint8_t)((v >> (8 * i)) & 0xFF);
    pf_update(c, b, 8);
}

/* ============================================================================
 *  ARENA / ERROR QUEUE / CERT TABLE
 * ============================================================================ */

typedef struct {
    uint8_t *base;
    size_t   used;
    size_t   cap;
} pf_arena_t;

static char *pf_arena_strdup(pf_arena_t *a, const char *s)
{
    size_t n = strlen(s);
    if (a->used + n + 1 > a->cap) {
        size_t newcap = a->cap ? a->cap * 2 : 1024;
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

static char *pf_arena_printf(pf_arena_t *a, const char *fmt, ...)
{
    char tmp[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(tmp, sizeof tmp, fmt, ap);
    va_end(ap);
    if (n < 0) return NULL;
    return pf_arena_strdup(a, tmp);
}

typedef struct {
    uint32_t decl_node;
    uint8_t  cert[32];
} pf_cert_entry_t;

struct iii_proof_state {
    iii_ast_t          *ast;
    iii_sema_state_t   *sema;     /* may be NULL */

    pf_arena_t          arena;

    iii_proof_error_t  *errors;
    uint32_t            error_count;
    uint32_t            error_cap;

    pf_cert_entry_t    *certs;
    uint32_t            cert_count;
    uint32_t            cert_cap;

    bool                ran;
};

/* ============================================================================
 *  HELPERS
 * ============================================================================ */

static iii_src_text_t pf_decl_name(const iii_ast_node_t *d)
{
    iii_src_text_t empty = { 0, 0 };
    if (!d) return empty;
    switch (d->kind) {
        case III_AST_CYCLE_DECL:                return d->u.cycle_decl.name;
        case III_AST_FN_DECL:                   return d->u.fn_decl.name;
        case III_AST_TYPE_DECL:                 return d->u.type_decl.name;
        case III_AST_CONST_DECL:                return d->u.const_decl.name;
        case III_AST_EXTERN_DECL:               return d->u.extern_decl.name;
        case III_AST_MOBIUS_CANDIDATE_DECL:     return d->u.mobius_candidate.name;
        case III_AST_SCHEMA_DECL:               return d->u.schema_decl.name;
        case III_AST_SEALED_CALL_METHOD_DECL:   return d->u.sealed_call.name;
        default:                                return empty;
    }
}

static void pf_emit_error(iii_proof_state_t *p, int code, uint32_t decl_node,
                            const char *msg)
{
    if (p->error_count == p->error_cap) {
        uint32_t newcap = p->error_cap ? p->error_cap * 2 : 16;
        iii_proof_error_t *ne = (iii_proof_error_t *)realloc(p->errors,
                                    newcap * sizeof(*ne));
        if (!ne) return;
        p->errors = ne; p->error_cap = newcap;
    }
    iii_proof_error_t *e = &p->errors[p->error_count++];
    e->code = code;
    e->decl_node = decl_node;
    e->message = msg;
}

static int pf_record_cert(iii_proof_state_t *p, uint32_t decl_node,
                            const uint8_t cert[32])
{
    if (p->cert_count == p->cert_cap) {
        uint32_t newcap = p->cert_cap ? p->cert_cap * 2 : 32;
        pf_cert_entry_t *ne = (pf_cert_entry_t *)realloc(p->certs,
                                    newcap * sizeof(*ne));
        if (!ne) return -1;
        p->certs = ne; p->cert_cap = newcap;
    }
    p->certs[p->cert_count].decl_node = decl_node;
    memcpy(p->certs[p->cert_count].cert, cert, 32);
    p->cert_count++;
    return 0;
}

/* ============================================================================
 *  ERROR-NODE WALKER (defense in depth — catch sema-recovered nodes)
 * ============================================================================ */

static bool pf_subtree_has_error_node(iii_proof_state_t *p, uint32_t node)
{
    if (node == 0) return false;
    const iii_ast_node_t *n = iii_ast_get(p->ast, node);
    if (!n) return false;
    if (n->kind == III_AST_ERROR_NODE) return true;

    /* Limited recursion: only follow the obvious child slots.  A
     * fuller traversal would use iii_ast_walk_pre but Stage-0 keeps
     * this small.  */
    switch (n->kind) {
        case III_AST_FORWARD_BLOCK:
            for (uint32_t i = 0; i < n->u.forward_block.stmts.count; i++)
                if (pf_subtree_has_error_node(p, iii_ast_list_at(p->ast, n->u.forward_block.stmts, i)))
                    return true;
            return false;
        case III_AST_EXPR_BLOCK:
            for (uint32_t i = 0; i < n->u.block.stmts.count; i++)
                if (pf_subtree_has_error_node(p, iii_ast_list_at(p->ast, n->u.block.stmts, i)))
                    return true;
            return false;
        case III_AST_STMT_LET:
            return pf_subtree_has_error_node(p, n->u.let_.value_expr);
        case III_AST_STMT_EXPR:
            return pf_subtree_has_error_node(p, n->u.expr_stmt.expr);
        case III_AST_STMT_RETURN:
            return pf_subtree_has_error_node(p, n->u.return_.value_expr);
        case III_AST_STMT_ASSIGN:
            return pf_subtree_has_error_node(p, n->u.assign.lvalue_expr)
                || pf_subtree_has_error_node(p, n->u.assign.value_expr);
        case III_AST_EXPR_CALL:
            if (pf_subtree_has_error_node(p, n->u.call.callee)) return true;
            for (uint32_t i = 0; i < n->u.call.args.count; i++)
                if (pf_subtree_has_error_node(p, iii_ast_list_at(p->ast, n->u.call.args, i)))
                    return true;
            return false;
        case III_AST_EXPR_FIELD:
            return pf_subtree_has_error_node(p, n->u.field.object);
        case III_AST_EXPR_INDEX:
            return pf_subtree_has_error_node(p, n->u.index.object)
                || pf_subtree_has_error_node(p, n->u.index.index_expr);
        case III_AST_EXPR_BINARY:
            return pf_subtree_has_error_node(p, n->u.binary.lhs)
                || pf_subtree_has_error_node(p, n->u.binary.rhs);
        case III_AST_EXPR_UNARY:
            return pf_subtree_has_error_node(p, n->u.unary.operand);
        case III_AST_EXPR_PAREN:
            return pf_subtree_has_error_node(p, n->u.paren.inner);
        case III_AST_ARG:
            return pf_subtree_has_error_node(p, n->u.arg.value_expr);
        default:
            return false;
    }
}

/* ============================================================================
 *  CERTIFICATE EMISSION (per decl)
 * ============================================================================ */

/* Compute a 32-byte SHA-256 over the canonical bytes of the decl:
 *   "III_PROOF_v1\0"
 *   u32 kind
 *   u32 name_len
 *   bytes name
 *   u32 hexad_packed (or 0xFFFFFFFFu if N/A)
 *   u32 ring_mask    (or 0)
 *   u32 tier_kind    (or 0xFFFFFFFFu if N/A)
 *   u64 epoch_value  (0 if N/A)
 *   u8[32] subtree_mhash (from iii_ast_node_mhash; zeros if missing)
 */
static void pf_compute_cert(iii_proof_state_t *p, uint32_t decl_node,
                              const iii_ast_node_t *d, uint8_t out[32])
{
    pf_sha_t c;
    pf_init(&c);

    static const char DOMAIN[] = "III_PROOF_v1";
    pf_update(&c, DOMAIN, sizeof DOMAIN); /* includes the NUL */

    pf_update_u32(&c, (uint32_t)d->kind);

    iii_src_text_t name_t = pf_decl_name(d);
    pf_update_u32(&c, name_t.length);
    if (name_t.length > 0) {
        const uint8_t *src = iii_ast_source_buf(p->ast);
        size_t slen = iii_ast_source_len(p->ast);
        if (src && name_t.offset + name_t.length <= slen) {
            pf_update(&c, src + name_t.offset, name_t.length);
        }
    }

    /* Resolved sema annotations (cycle decls only). */
    uint16_t hexad = 0xFFFFu;
    unsigned ring  = 0;
    if (p->sema && d->kind == III_AST_CYCLE_DECL) {
        hexad = iii_sema_cycle_hexad(p->sema, decl_node);
        ring  = iii_sema_cycle_ring_mask(p->sema, decl_node);
    }
    pf_update_u32(&c, hexad == 0xFFFFu ? 0xFFFFFFFFu : (uint32_t)hexad);
    pf_update_u32(&c, ring);
    /* Tier and epoch are in sema's anno table; we don't expose getters
     * for those today, so they are folded as zero — which is stable
     * across runs.  Stage-1 will widen the certificate's input. */
    pf_update_u32(&c, 0xFFFFFFFFu);     /* tier_kind sentinel */
    pf_update_u64(&c, 0u);              /* epoch_value */

    /* Subtree mhash from ast.h's per-node A1 mhash.  This brings the
     * full body bytes (modifiers, params, return type, forward block,
     * compromise block) into the cert via the AST's own canonical
     * representation. */
    const uint8_t *node_mh = iii_ast_node_mhash(p->ast, decl_node);
    if (node_mh) {
        pf_update(&c, node_mh, 32);
    } else {
        uint8_t z[32] = { 0 };
        pf_update(&c, z, 32);
    }

    pf_final(&c, out);
}

static void pf_process_decl(iii_proof_state_t *p, uint32_t decl_node,
                              const iii_ast_node_t *d)
{
    /* Skip ERROR_NODE — sema already reported it; we don't certify. */
    if (d->kind == III_AST_ERROR_NODE) {
        pf_emit_error(p, III_PROOF_E_ERROR_NODE, decl_node,
                        "decl is a parser-recovery error node");
        return;
    }

    /* Defense-in-depth recursive ERROR_NODE check on subtrees. */
    if (pf_subtree_has_error_node(p, decl_node)) {
        char *msg = pf_arena_printf(&p->arena,
                        "subtree of decl node %u contains an error node",
                        decl_node);
        pf_emit_error(p, III_PROOF_E_ERROR_NODE, decl_node,
                        msg ? msg : "subtree contains error node");
        return;
    }

    /* Defense-in-depth hexad re-check on cycle decls. */
    if (d->kind == III_AST_CYCLE_DECL && p->sema) {
        uint16_t h = iii_sema_cycle_hexad(p->sema, decl_node);
        if (h != 0xFFFFu && !iii_hexad_packed_admitted(h)) {
            pf_emit_error(p, III_PROOF_E_HEXAD_UNREP, decl_node,
                            "cycle hexad fails defense-in-depth admission");
            /* Continue: we still emit a cert (zero-valued for the
             * hexad slot via 0xFFFFFFFFu sentinel) so the caller can
             * see the cycle in the cert table, marked unrep. */
        }
        unsigned ring = iii_sema_cycle_ring_mask(p->sema, decl_node);
        if (ring != 0 && (ring & ~III_RING_ANY) != 0) {
            pf_emit_error(p, III_PROOF_E_RING_MALFORMED, decl_node,
                            "cycle ring set has bits outside the four-ring lattice");
        }
    }

    /* Compute and emit certificate. */
    uint8_t cert[32];
    pf_compute_cert(p, decl_node, d, cert);
    pf_record_cert(p, decl_node, cert);
    (void)iii_ast_annotate(p->ast, "proof/cert_mhash", decl_node, cert, 32);
}

/* ============================================================================
 *  PUBLIC API
 * ============================================================================ */

iii_proof_state_t *iii_proof_create(iii_ast_t *ast, iii_sema_state_t *sema)
{
    if (!ast) return NULL;
    iii_proof_state_t *p = (iii_proof_state_t *)calloc(1, sizeof *p);
    if (!p) return NULL;
    p->ast = ast;
    p->sema = sema;
    return p;
}

void iii_proof_destroy(iii_proof_state_t *p)
{
    if (!p) return;
    free(p->errors);
    free(p->certs);
    free(p->arena.base);
    free(p);
}

int iii_proof_run(iii_proof_state_t *p)
{
    if (!p || !p->ast) return 0;
    if (p->ran) return p->error_count == 0 ? 1 : 0;
    p->ran = true;

    iii_hexad_check_init();

    uint32_t mod_node = iii_ast_root_module(p->ast);
    if (mod_node == 0) return 0;
    const iii_ast_node_t *mod = iii_ast_get(p->ast, mod_node);
    if (!mod || mod->kind != III_AST_MODULE) return 0;

    iii_ast_list_t decls = mod->u.module_.decls;
    for (uint32_t i = 0; i < decls.count; i++) {
        uint32_t didx = iii_ast_list_at(p->ast, decls, i);
        const iii_ast_node_t *d = iii_ast_get(p->ast, didx);
        if (!d) continue;
        pf_process_decl(p, didx, d);
    }

    return p->error_count == 0 ? 1 : 0;
}

uint32_t iii_proof_error_count(const iii_proof_state_t *p)
{
    return p ? p->error_count : 0;
}

void iii_proof_error_at(const iii_proof_state_t *p, uint32_t i,
                            iii_proof_error_t *out)
{
    if (!out) return;
    memset(out, 0, sizeof *out);
    if (!p || i >= p->error_count) return;
    *out = p->errors[i];
}

const char *iii_proof_error_name(int code)
{
    switch (code) {
        case III_PROOF_OK:               return "OK";
        case III_PROOF_E_HEXAD_UNREP:    return "PROOF-HEXAD-001";
        case III_PROOF_E_RING_MALFORMED: return "PROOF-RING-001";
        case III_PROOF_E_ERROR_NODE:     return "PROOF-ERROR-001";
        case III_PROOF_E_OOM:            return "OOM";
        default:                         return "UNKNOWN";
    }
}

bool iii_proof_cert_for_decl(const iii_proof_state_t *p, uint32_t decl_node,
                                uint8_t out[32])
{
    if (!p || !out) return false;
    for (uint32_t i = 0; i < p->cert_count; i++) {
        if (p->certs[i].decl_node == decl_node) {
            memcpy(out, p->certs[i].cert, 32);
            return true;
        }
    }
    return false;
}

void iii_proof_aggregate_root(const iii_proof_state_t *p, uint8_t out[32])
{
    if (!out) return;
    if (!p || p->cert_count == 0) {
        memset(out, 0, 32);
        return;
    }
    pf_sha_t c;
    pf_init(&c);
    static const char DOMAIN[] = "III_PROOF_AGGREGATE_v1";
    pf_update(&c, DOMAIN, sizeof DOMAIN);
    for (uint32_t i = 0; i < p->cert_count; i++) {
        pf_update_u32(&c, p->certs[i].decl_node);
        pf_update(&c, p->certs[i].cert, 32);
    }
    pf_final(&c, out);
}
