/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_r0.c
 *
 * III Stage-0 Ring 0 (Windows kernel-mode) codegen — implementation.
 *
 * Architecture: the Stage-0 Ring-0 codegen reuses the stack-machine
 * expression emission strategy from cg_r3 (Microsoft x64 ABI is the
 * same for kernel and user mode on Windows) but emits Ring-0-specific
 * prologue/epilogue, IRQL discipline at privileged sites, audit-bus
 * routing for witness emission, and DriverEntry as the entry point.
 *
 * The deepenings (D1..D14) over the LOGOS source are documented inline.
 * Citations: WDK ("Writing a DriverEntry routine", "Writing Dispatch
 * Routines", "Managing Hardware Priorities"), MS x64 ABI §"Exception
 * Handling", PE/COFF Spec §6 ("Section Table"), ADR-024 (witness bus).
 *
 * Strict NIH.  Hand-emitted gas-syntax mnemonics.  No CRT calls inside
 * the emitted .sys image — only Ke* / Mm* / Io* / Rtl* and the III
 * substrate symbols (xii_irpd_*, iii_witness_emit_kernel).
 */

#include "cg_r0.h"

#include "ast.h"
#include "ast_internal.h"   /* direct AST field access for label/source helpers */
#include "sema.h"
#include "sid.h"
#include "witness_alloc.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

/* ─── SHA-256 (D10): streaming hash over the emitted asm stream ─── */
/* Reference: FIPS 180-4 §6.2.  Strict NIH; libc-only on host build. */

typedef struct {
    uint32_t h[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    size_t   buflen;
} iii_sha256_t;

static const uint32_t IIIK[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static uint32_t rotr32(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }

static void iii_sha256_init(iii_sha256_t *s)
{
    s->h[0]=0x6a09e667u; s->h[1]=0xbb67ae85u; s->h[2]=0x3c6ef372u; s->h[3]=0xa54ff53au;
    s->h[4]=0x510e527fu; s->h[5]=0x9b05688cu; s->h[6]=0x1f83d9abu; s->h[7]=0x5be0cd19u;
    s->bitlen = 0; s->buflen = 0;
}

static void iii_sha256_block(iii_sha256_t *s, const uint8_t b[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)b[i*4] << 24) | ((uint32_t)b[i*4+1] << 16) |
               ((uint32_t)b[i*4+2] << 8) | (uint32_t)b[i*4+3];
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr32(w[i-15],7) ^ rotr32(w[i-15],18) ^ (w[i-15] >> 3);
        uint32_t s1 = rotr32(w[i-2],17) ^ rotr32(w[i-2],19)  ^ (w[i-2]  >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=s->h[0], bb=s->h[1], c=s->h[2], d=s->h[3],
             e=s->h[4], f=s->h[5], g=s->h[6], h=s->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = rotr32(e,6) ^ rotr32(e,11) ^ rotr32(e,25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + IIIK[i] + w[i];
        uint32_t S0 = rotr32(a,2) ^ rotr32(a,13) ^ rotr32(a,22);
        uint32_t mj = (a & bb) ^ (a & c) ^ (bb & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1; d = c; c = bb; bb = a; a = t1 + t2;
    }
    s->h[0]+=a; s->h[1]+=bb; s->h[2]+=c; s->h[3]+=d;
    s->h[4]+=e; s->h[5]+=f;  s->h[6]+=g; s->h[7]+=h;
}

static void iii_sha256_update(iii_sha256_t *s, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    s->bitlen += (uint64_t)len * 8u;
    while (len) {
        size_t take = 64u - s->buflen;
        if (take > len) take = len;
        memcpy(s->buf + s->buflen, p, take);
        s->buflen += take; p += take; len -= take;
        if (s->buflen == 64u) { iii_sha256_block(s, s->buf); s->buflen = 0; }
    }
}

static void iii_sha256_final(iii_sha256_t *s, uint8_t out[32])
{
    uint64_t bl = s->bitlen;
    s->buf[s->buflen++] = 0x80u;
    if (s->buflen > 56u) {
        while (s->buflen < 64u) s->buf[s->buflen++] = 0u;
        iii_sha256_block(s, s->buf); s->buflen = 0;
    }
    while (s->buflen < 56u) s->buf[s->buflen++] = 0u;
    for (int i = 7; i >= 0; i--) s->buf[s->buflen++] = (uint8_t)(bl >> (i*8));
    iii_sha256_block(s, s->buf);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(s->h[i] >> 24);
        out[i*4+1] = (uint8_t)(s->h[i] >> 16);
        out[i*4+2] = (uint8_t)(s->h[i] >> 8);
        out[i*4+3] = (uint8_t)(s->h[i]);
    }
}

/* ─── State ──────────────────────────────────────────────────────── */

#define III_CG_R0_MAX_IRP   28u   /* IRP_MJ_MAXIMUM_FUNCTION + 1 = 0x1c */
#define III_CG_R0_LOCALS    64u
#define III_CG_R0_FRAME     1024u /* default reserved frame bytes */

struct iii_cg_r0_state {
    iii_ast_t          *ast;
    iii_sema_state_t   *sema;
    iii_sid_state_t    *sid;
    iii_walloc_state_t *walloc;

    FILE                 *out;
    uint32_t              local_count;
    uint32_t              stack_depth;
    uint32_t              label_counter;
    uint32_t              frame_bytes;     /* D13 */

    struct {
        iii_src_text_t name;
        uint32_t       slot;
    } locals[III_CG_R0_LOCALS];

    /* D2: IRP dispatch table — index = IRP_MJ_*, payload = name node id */
    uint32_t irp_handlers[III_CG_R0_MAX_IRP];

    /* Per-emit context for IRQL/ring/sec checks (D3,D5,D14). */
    int      cur_max_irql;   /* -1 if unset */
    int      cur_ring;       /* 0 default; -1 unset */
    bool     cur_paged;      /* D4 */
    bool     cur_secmem;     /* D14 */
    bool     cur_returns_ntstatus;
    bool     emitted_explicit_return;

    /* D10: streaming SHA-256 over the asm stream. */
    iii_sha256_t hash;
    uint8_t      witness[32];
    bool         witness_finalized;

    int                   last_error;
};

/* ─── Output sink (D10 hashes everything we emit) ────────────────── */

static void iii_emit_raw(iii_cg_r0_state_t *cg, const char *s, size_t n)
{
    if (cg->out) fwrite(s, 1, n, cg->out);
    iii_sha256_update(&cg->hash, s, n);
}

static void iii_emit_str(iii_cg_r0_state_t *cg, const char *s)
{
    iii_emit_raw(cg, s, strlen(s));
}

static void iii_emit_ch(iii_cg_r0_state_t *cg, int ch)
{
    uint8_t b = (uint8_t)ch;
    iii_emit_raw(cg, (const char *)&b, 1);
}

static void emit_line(iii_cg_r0_state_t *cg, const char *fmt, ...)
{
    /* Bounded local buffer — no heap inside the emit loop. */
    char buf[1024];
    va_list ap; va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    if (n < 0) { cg->last_error = III_CG_R0_E_IO; return; }
    if ((size_t)n > sizeof(buf) - 1) n = (int)sizeof(buf) - 1;
    iii_emit_raw(cg, buf, (size_t)n);
    iii_emit_ch(cg, '\n');
}

/* ─── Identifier helpers ─────────────────────────────────────────── */

static void emit_decl_label(iii_cg_r0_state_t *cg, iii_src_text_t name)
{
    iii_emit_str(cg, "L_");
    for (uint32_t i = 0; i < name.length; i++) {
        uint8_t b = cg->ast->source_buf[name.offset + i];
        if ((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
            (b >= '0' && b <= '9') || b == '_') iii_emit_ch(cg, (int)b);
        else iii_emit_ch(cg, '_');
    }
}

static bool name_eq(const iii_cg_r0_state_t *cg, iii_src_text_t a, const char *s)
{
    size_t n = strlen(s);
    if (a.length != n) return false;
    return memcmp(cg->ast->source_buf + a.offset, s, n) == 0;
}

static int local_lookup_slot(iii_cg_r0_state_t *cg, iii_src_text_t name)
{
    for (uint32_t i = 0; i < cg->local_count; i++) {
        if (cg->locals[i].name.length == name.length &&
            memcmp(cg->ast->source_buf + cg->locals[i].name.offset,
                   cg->ast->source_buf + name.offset, name.length) == 0)
            return (int)cg->locals[i].slot;
    }
    return -1;
}

static void local_add(iii_cg_r0_state_t *cg, iii_src_text_t name)
{
    if (cg->local_count >= III_CG_R0_LOCALS) return;
    cg->locals[cg->local_count].name = name;
    cg->locals[cg->local_count].slot = cg->local_count;
    cg->local_count++;
}

static void stack_push(iii_cg_r0_state_t *cg, const char *r)
{ emit_line(cg, "    pushq %%%s", r); cg->stack_depth++; }
static void stack_pop(iii_cg_r0_state_t *cg, const char *r)
{ emit_line(cg, "    popq %%%s", r); if (cg->stack_depth) cg->stack_depth--; }

/* ─── Hexad packing ──────────────────────────────────────────────── */

static uint16_t pack_hexad_trits(const iii_ast_trit_t trits[6])
{
    uint16_t v = 0;
    for (int i = 0; i < 6; i++)
        v = (uint16_t)(v | ((uint16_t)((uint16_t)trits[i] & 0x3u) << (2 * i)));
    return v;
}

static void emit_mhash_data_label(iii_cg_r0_state_t *cg, uint32_t node_id, const uint8_t mh[32])
{
    char tmp[64];
    int n = snprintf(tmp, sizeof(tmp), "L_mhash_%u:\n    .byte ", (unsigned)node_id);
    iii_emit_raw(cg, tmp, (size_t)n);
    for (int i = 0; i < 32; i++) {
        n = snprintf(tmp, sizeof(tmp), "0x%02x%s", mh[i], (i == 31) ? "\n" : ", ");
        iii_emit_raw(cg, tmp, (size_t)n);
    }
}

static int emit_field_label(iii_cg_r0_state_t *cg,
                            const iii_ast_node_t *obj,
                            iii_src_text_t field_name)
{
    if (!obj || obj->kind != III_AST_EXPR_IDENT) return -1;
    iii_emit_str(cg, "L_");
    for (uint32_t i = 0; i < obj->u.ident.name.length; i++) {
        uint8_t b = cg->ast->source_buf[obj->u.ident.name.offset + i];
        if ((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
            (b >= '0' && b <= '9') || b == '_') iii_emit_ch(cg, (int)b);
        else iii_emit_ch(cg, '_');
    }
    iii_emit_str(cg, "__");
    for (uint32_t i = 0; i < field_name.length; i++) {
        uint8_t b = cg->ast->source_buf[field_name.offset + i];
        if ((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
            (b >= '0' && b <= '9') || b == '_') iii_emit_ch(cg, (int)b);
        else iii_emit_ch(cg, '_');
    }
    return 0;
}

/* ─── Modifier scanning (D2/D3/D4/D5/D6/D14) ─────────────────────── */
/* We keep modifier semantics localised: scan an iii_ast_list_t of
 * modifiers and answer questions about it.  Cite: III modifier shape
 * iii_modifier_payload_t {name, args, ring_mask, ...}. */

static const iii_ast_node_t *mod_find(iii_cg_r0_state_t *cg,
                                      iii_ast_list_t mods,
                                      const char *name)
{
    for (uint32_t i = 0; i < mods.count; i++) {
        uint32_t mid = iii_ast_list_at(cg->ast, mods, i);
        const iii_ast_node_t *m = iii_ast_get(cg->ast, mid);
        if (!m || m->kind != III_AST_MODIFIER) continue;
        if (name_eq(cg, m->u.modifier.name, name)) return m;
    }
    return NULL;
}

/* Best-effort: extract first integer literal arg from a modifier. */
static int mod_first_int(iii_cg_r0_state_t *cg, const iii_ast_node_t *m, int dflt)
{
    if (!m) return dflt;
    for (uint32_t i = 0; i < m->u.modifier.args.count; i++) {
        uint32_t aid = iii_ast_list_at(cg->ast, m->u.modifier.args, i);
        const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
        if (!a) continue;
        if (a->kind == III_AST_EXPR_INT) return (int)a->u.int_.value;
        if (a->kind == III_AST_EXPR_HEX) return (int)a->u.hex_.value;
        if (a->kind == III_AST_EXPR_IDENT) {
            /* Permit IRP_MJ_* / DISPATCH_LEVEL symbolic names — emit
             * verbatim by returning a sentinel; caller must consult
             * the ident text directly when needed. */
            return -2;
        }
    }
    return dflt;
}

/* Map IRP_MJ_<x> identifier text to its numeric major code.
 * Cite: WDK <wdm.h> IRP_MJ_* enumerants. */
static int irp_mj_lookup(const char *s, size_t n)
{
    struct { const char *k; int v; } tab[] = {
        {"IRP_MJ_CREATE", 0x00},
        {"IRP_MJ_CREATE_NAMED_PIPE", 0x01},
        {"IRP_MJ_CLOSE", 0x02},
        {"IRP_MJ_READ", 0x03},
        {"IRP_MJ_WRITE", 0x04},
        {"IRP_MJ_QUERY_INFORMATION", 0x05},
        {"IRP_MJ_SET_INFORMATION", 0x06},
        {"IRP_MJ_QUERY_EA", 0x07},
        {"IRP_MJ_SET_EA", 0x08},
        {"IRP_MJ_FLUSH_BUFFERS", 0x09},
        {"IRP_MJ_QUERY_VOLUME_INFORMATION", 0x0a},
        {"IRP_MJ_SET_VOLUME_INFORMATION", 0x0b},
        {"IRP_MJ_DIRECTORY_CONTROL", 0x0c},
        {"IRP_MJ_FILE_SYSTEM_CONTROL", 0x0d},
        {"IRP_MJ_DEVICE_CONTROL", 0x0e},
        {"IRP_MJ_INTERNAL_DEVICE_CONTROL", 0x0f},
        {"IRP_MJ_SHUTDOWN", 0x10},
        {"IRP_MJ_LOCK_CONTROL", 0x11},
        {"IRP_MJ_CLEANUP", 0x12},
        {"IRP_MJ_CREATE_MAILSLOT", 0x13},
        {"IRP_MJ_QUERY_SECURITY", 0x14},
        {"IRP_MJ_SET_SECURITY", 0x15},
        {"IRP_MJ_POWER", 0x16},
        {"IRP_MJ_SYSTEM_CONTROL", 0x17},
        {"IRP_MJ_DEVICE_CHANGE", 0x18},
        {"IRP_MJ_QUERY_QUOTA", 0x19},
        {"IRP_MJ_SET_QUOTA", 0x1a},
        {"IRP_MJ_PNP", 0x1b},
    };
    for (size_t i = 0; i < sizeof(tab)/sizeof(tab[0]); i++) {
        size_t kn = strlen(tab[i].k);
        if (kn == n && memcmp(tab[i].k, s, n) == 0) return tab[i].v;
    }
    return -1;
}

/* D3: high-IRQL-only kernel APIs.  A call from a cycle whose declared
 * @irql_max(N) is below the API's required level must be rejected.
 * Required level: PASSIVE=0, APC=1, DISPATCH=2, DIRQL=variable.
 * We default cur_max_irql=DISPATCH (2). */
static int kernel_api_min_irql(const char *s, size_t n)
{
    /* Returns the *minimum* IRQL the caller is required to be AT
     * MOST; i.e., this is the api's IRQL_REQUIRES_MAX(). */
    struct { const char *k; int v; } tab[] = {
        {"KeWaitForSingleObject",        1}, /* APC_LEVEL */
        {"KeWaitForMultipleObjects",     1},
        {"ExAllocatePool2",              2},
        {"ExAllocatePoolWithTag",        2},
        {"ExFreePoolWithTag",            2},
        {"MmAllocateNonCachedMemory",    1},
        {"MmFreeNonCachedMemory",        1},
        {"IoCreateDevice",               0}, /* PASSIVE only */
        {"IoCreateSymbolicLink",         0},
        {"IoDeleteDevice",               0},
        {"IoDeleteSymbolicLink",         0},
        {"ZwCreateFile",                 0},
        {"ZwClose",                      0},
        {"PsCreateSystemThread",         1},
        {"KeStallExecutionProcessor",    31}, /* HIGH_LEVEL ok */
        {"KeAcquireSpinLock",            2},
        {"KeReleaseSpinLock",            2},
        {"KeGetCurrentIrql",             31},
        {"KeRaiseIrql",                  31},
        {"KeLowerIrql",                  31},
        {"RtlCopyMemory",                31},
        {"RtlZeroMemory",                31},
        {"iii_witness_emit_kernel",      31}, /* D9 contract */
        {"xii_irpd_emit_audit_hook",     2},
    };
    for (size_t i = 0; i < sizeof(tab)/sizeof(tab[0]); i++) {
        size_t kn = strlen(tab[i].k);
        if (kn == n && memcmp(tab[i].k, s, n) == 0) return tab[i].v;
    }
    return -1; /* unknown; do not constrain */
}

/* D5: ring detection on a *callee* decl.  Find the @ring(...)
 * modifier and check whether it permits R0.  Returns true if the
 * symbol is callable from R0. */
static bool ring_ok_for_r0(iii_cg_r0_state_t *cg, iii_ast_list_t mods)
{
    const iii_ast_node_t *m = mod_find(cg, mods, "ring");
    if (!m) return true; /* unannotated → permitted */
    /* III parser pre-resolves @ring into modifier.ring_mask bits. */
    uint32_t mask = m->u.modifier.ring_mask;
    if (mask == 0) return true; /* parser failed to resolve; be lenient */
    /* Convention: bit 0 = R0, bit 1 = R3, bit 2 = Rm1 (ADR-027). */
    return (mask & 0x1u) != 0u;
}

/* ─── Decl-table lookup (used by D5) ─────────────────────────────── */

static const iii_ast_node_t *find_decl_by_name(iii_cg_r0_state_t *cg,
                                               iii_src_text_t name,
                                               iii_ast_list_t *out_mods)
{
    const iii_ast_node_t *mod = iii_ast_get(cg->ast, cg->ast->root_module);
    if (!mod) return NULL;
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d) continue;
        iii_src_text_t dn; iii_ast_list_t dm = {0};
        switch (d->kind) {
            case III_AST_FN_DECL:    dn = d->u.fn_decl.name;    dm = d->u.fn_decl.modifiers;    break;
            case III_AST_CYCLE_DECL: dn = d->u.cycle_decl.name; dm = d->u.cycle_decl.modifiers; break;
            default: continue;
        }
        if (dn.length == name.length &&
            memcmp(cg->ast->source_buf + dn.offset,
                   cg->ast->source_buf + name.offset, name.length) == 0) {
            if (out_mods) *out_mods = dm;
            return d;
        }
    }
    return NULL;
}

/* ─── Forward decls ──────────────────────────────────────────────── */

static int emit_expr(iii_cg_r0_state_t *cg, uint32_t node);
static int emit_stmt(iii_cg_r0_state_t *cg, uint32_t node);
static int emit_block(iii_cg_r0_state_t *cg, uint32_t block_node);

static int emit_pattern_compare(iii_cg_r0_state_t *cg, uint32_t pat_node)
{
    const iii_ast_node_t *p = iii_ast_get(cg->ast, pat_node);
    if (!p) return -1;
    switch (p->kind) {
        case III_AST_PAT_WILDCARD:
        case III_AST_PAT_IDENT:
            emit_line(cg, "    cmpq %%rax, %%rax");
            return 0;
        case III_AST_PAT_LITERAL: {
            const iii_ast_node_t *lit = iii_ast_get(cg->ast, p->u.pat_literal.literal_node);
            if (!lit) return -1;
            uint64_t v = 0;
            switch (lit->kind) {
                case III_AST_EXPR_INT:  v = lit->u.int_.value; break;
                case III_AST_EXPR_HEX:  v = lit->u.hex_.value; break;
                case III_AST_EXPR_BOOL: v = lit->u.bool_.value ? 1u : 0u; break;
                case III_AST_EXPR_TRIT: v = (uint64_t)lit->u.trit_.trit; break;
                default: cg->last_error = III_CG_R0_E_UNSUPPORTED; return -1;
            }
            emit_line(cg, "    movabsq $0x%llx, %%rcx", (unsigned long long)v);
            emit_line(cg, "    cmpq %%rcx, %%rax");
            return 0;
        }
        case III_AST_PAT_HEXAD: {
            uint16_t packed = pack_hexad_trits(p->u.pat_hexad.trits);
            emit_line(cg, "    movabsq $0x%x, %%rcx", (unsigned)packed);
            emit_line(cg, "    cmpq %%rcx, %%rax");
            return 0;
        }
        case III_AST_PAT_TUPLE:
        default:
            cg->last_error = III_CG_R0_E_UNSUPPORTED;
            return -1;
    }
}

static void emit_pattern_bind(iii_cg_r0_state_t *cg, uint32_t pat_node)
{
    const iii_ast_node_t *p = iii_ast_get(cg->ast, pat_node);
    if (!p || p->kind != III_AST_PAT_IDENT) return;
    local_add(cg, p->u.pat_ident.name);
    uint32_t slot = cg->local_count - 1u;
    emit_line(cg, "    movq %%rax, -%d(%%rbp)", (slot + 1) * 8);
}

/* ─── D5+D3: validate a CALL site ─────────────────────────────────
 * Cite: WDK §"Managing Hardware Priorities", §"Driver Layering". */
static int validate_call_target(iii_cg_r0_state_t *cg, iii_src_text_t name)
{
    /* Ring-wall (D5). */
    iii_ast_list_t mods = {0};
    const iii_ast_node_t *callee = find_decl_by_name(cg, name, &mods);
    if (callee && !ring_ok_for_r0(cg, mods)) {
        cg->last_error = III_CG_R0_E_RING_WALL;
        emit_line(cg, "# III_CG_R0_E_RING_WALL: refused R3/R-1 callee");
        return -1;
    }
    /* IRQL discipline (D3). */
    const char *cs = (const char *)(cg->ast->source_buf + name.offset);
    int api_max = kernel_api_min_irql(cs, name.length);
    if (api_max >= 0 && cg->cur_max_irql >= 0 && cg->cur_max_irql > api_max) {
        cg->last_error = III_CG_R0_E_IRQL_VIOLATION;
        emit_line(cg, "# III_CG_R0_E_IRQL_VIOLATION: caller@IRQL=%d > callee_max=%d",
                  cg->cur_max_irql, api_max);
        return -1;
    }
    return 0;
}

/* ─── Expression emission (mirrors cg_r3 stack machine) ──────────── */

static int emit_expr(iii_cg_r0_state_t *cg, uint32_t node)
{
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_EXPR_INT:
        case III_AST_EXPR_HEX: {
            uint64_t v = (n->kind == III_AST_EXPR_INT) ? n->u.int_.value : n->u.hex_.value;
            emit_line(cg, "    movabsq $0x%llx, %%rax", (unsigned long long)v);
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_BOOL: emit_line(cg, "    movq $%d, %%rax", n->u.bool_.value?1:0); stack_push(cg,"rax"); return 0;
        case III_AST_EXPR_TRIT: emit_line(cg, "    movq $%d, %%rax", (int)n->u.trit_.trit); stack_push(cg,"rax"); return 0;
        case III_AST_EXPR_UNIT: emit_line(cg, "    xorq %%rax, %%rax"); stack_push(cg,"rax"); return 0;
        case III_AST_EXPR_STR:
            emit_line(cg, "    leaq L_str_%u(%%rip), %%rax", (unsigned)n->u.str_.string_payload_idx);
            stack_push(cg, "rax");
            return 0;
        case III_AST_EXPR_IDENT: {
            int slot = local_lookup_slot(cg, n->u.ident.name);
            if (slot >= 0) {
                emit_line(cg, "    movq -%d(%%rbp), %%rax", (slot+1)*8);
                stack_push(cg, "rax");
                return 0;
            }
            iii_emit_str(cg, "    leaq ");
            emit_decl_label(cg, n->u.ident.name);
            iii_emit_str(cg, "(%rip), %rax\n");
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_PAREN: return emit_expr(cg, n->u.paren.inner);
        case III_AST_EXPR_BINARY: {
            if (emit_expr(cg, n->u.binary.lhs) != 0) return -1;
            if (emit_expr(cg, n->u.binary.rhs) != 0) return -1;
            stack_pop(cg, "rcx"); stack_pop(cg, "rax");
            switch (n->u.binary.op) {
                case III_BIN_ADD: emit_line(cg, "    addq %%rcx, %%rax"); break;
                case III_BIN_SUB: emit_line(cg, "    subq %%rcx, %%rax"); break;
                case III_BIN_MUL: emit_line(cg, "    imulq %%rcx, %%rax"); break;
                case III_BIN_DIV: emit_line(cg, "    cqto\n    idivq %%rcx"); break;
                case III_BIN_MOD: emit_line(cg, "    cqto\n    idivq %%rcx\n    movq %%rdx, %%rax"); break;
                case III_BIN_AND: emit_line(cg, "    andq %%rcx, %%rax"); break;
                case III_BIN_OR:  emit_line(cg, "    orq %%rcx, %%rax"); break;
                case III_BIN_XOR: emit_line(cg, "    xorq %%rcx, %%rax"); break;
                case III_BIN_SHL: emit_line(cg, "    shlq %%cl, %%rax"); break;
                case III_BIN_SHR: emit_line(cg, "    shrq %%cl, %%rax"); break;
                case III_BIN_EQ:  emit_line(cg, "    cmpq %%rcx, %%rax\n    sete %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_NEQ: emit_line(cg, "    cmpq %%rcx, %%rax\n    setne %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_LT:  emit_line(cg, "    cmpq %%rcx, %%rax\n    setl %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_LE:  emit_line(cg, "    cmpq %%rcx, %%rax\n    setle %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_GT:  emit_line(cg, "    cmpq %%rcx, %%rax\n    setg %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_GE:  emit_line(cg, "    cmpq %%rcx, %%rax\n    setge %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_LAND: emit_line(cg, "    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rdx\n    testq %%rcx, %%rcx\n    setne %%al\n    movzbq %%al, %%rax\n    andq %%rdx, %%rax"); break;
                case III_BIN_LOR:  emit_line(cg, "    orq %%rcx, %%rax\n    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_IN:
                case III_BIN_COMPOSE:
                default:
                    cg->last_error = III_CG_R0_E_UNSUPPORTED;
                    return -1;
            }
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_UNARY: {
            if (emit_expr(cg, n->u.unary.operand) != 0) return -1;
            stack_pop(cg, "rax");
            switch (n->u.unary.op) {
                case III_UN_NEG:   emit_line(cg, "    negq %%rax"); break;
                case III_UN_NOT:   emit_line(cg, "    testq %%rax, %%rax\n    sete %%al\n    movzbq %%al, %%rax"); break;
                case III_UN_BNOT:  emit_line(cg, "    notq %%rax"); break;
                case III_UN_DEREF: emit_line(cg, "    movq (%%rax), %%rax"); break;
                case III_UN_ADDR:  /* See cg_r3 for proper lvalue path. */ break;
            }
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_CALL: {
            const iii_ast_node_t *callee = iii_ast_get(cg->ast, n->u.call.callee);
            uint32_t arg_count = n->u.call.args.count;
            for (uint32_t i = 0; i < arg_count; i++) {
                uint32_t aid = iii_ast_list_at(cg->ast, n->u.call.args, i);
                const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
                if (a && a->kind == III_AST_ARG)
                    if (emit_expr(cg, a->u.arg.value_expr) != 0) return -1;
            }
            const char *abi[4] = { "rcx", "rdx", "r8", "r9" };
            uint32_t reg_args = arg_count > 4u ? 4u : arg_count;
            for (uint32_t i = 0; i < reg_args; i++) stack_pop(cg, abi[reg_args - 1u - i]);
            uint32_t pre = cg->stack_depth;
            uint32_t pad = ((pre + 4u) & 1u) ? 1u : 0u;
            if (pad) { emit_line(cg, "    subq $8, %%rsp"); cg->stack_depth++; }
            emit_line(cg, "    subq $32, %%rsp /* shadow (MS x64 ABI §2.2.2) */");
            cg->stack_depth += 4;
            if (callee && callee->kind == III_AST_EXPR_IDENT) {
                /* D3+D5 gates. */
                if (validate_call_target(cg, callee->u.ident.name) != 0) return -1;
                iii_emit_str(cg, "    callq ");
                emit_decl_label(cg, callee->u.ident.name);
                iii_emit_ch(cg, '\n');
            } else {
                if (emit_expr(cg, n->u.call.callee) != 0) return -1;
                stack_pop(cg, "rax");
                emit_line(cg, "    callq *%%rax");
            }
            emit_line(cg, "    addq $32, %%rsp"); cg->stack_depth -= 4;
            if (pad) { emit_line(cg, "    addq $8, %%rsp"); cg->stack_depth--; }
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_BLOCK: return emit_block(cg, node);
        case III_AST_EXPR_FIELD: {
            const iii_ast_node_t *obj = iii_ast_get(cg->ast, n->u.field.object);
            if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                cg->last_error = III_CG_R0_E_UNSUPPORTED;
                return -1;
            }
            iii_emit_str(cg, "    leaq ");
            if (emit_field_label(cg, obj, n->u.field.field_name) != 0) {
                cg->last_error = III_CG_R0_E_UNSUPPORTED;
                return -1;
            }
            iii_emit_str(cg, "(%rip), %rax\n");
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_INDEX: {
            if (emit_expr(cg, n->u.index.object) != 0) return -1;
            if (emit_expr(cg, n->u.index.index_expr) != 0) return -1;
            stack_pop(cg, "rcx"); stack_pop(cg, "rax");
            emit_line(cg, "    movq (%%rax,%%rcx,8), %%rax");
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_HEXAD: {
            uint16_t packed = pack_hexad_trits(n->u.hexad_.trits);
            emit_line(cg, "    movabsq $0x%x, %%rax", (unsigned)packed);
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_MHASH: {
            iii_emit_str(cg, "    .section .rdata\n");
            emit_mhash_data_label(cg, node, n->u.mhash_.mhash);
            iii_emit_str(cg, "    .text\n");
            emit_line(cg, "    leaq L_mhash_%u(%%rip), %%rax", (unsigned)node);
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_RAW_ASM: {
            uint32_t off = n->u.raw_asm.raw_asm_str_idx;
            uint32_t len = n->u.raw_asm.raw_asm_len;
            if (off + len <= cg->ast->source_len) {
                iii_emit_raw(cg, (const char *)(cg->ast->source_buf + off), len);
                iii_emit_ch(cg, '\n');
            }
            emit_line(cg, "    movq $0, %%rax");
            stack_push(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_expr.arms.count;
            if (emit_expr(cg, n->u.match_expr.scrutinee) != 0) return -1;
            stack_pop(cg, "rax");
            uint32_t scrut_slot = cg->local_count++;
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (scrut_slot + 1) * 8);
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_expr.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit_line(cg, "    movq -%d(%%rbp), %%rax", (scrut_slot + 1) * 8);
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) return -1;
                emit_line(cg, "    jne L_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) return -1;
                    stack_pop(cg, "rax");
                    emit_line(cg, "    testq %%rax, %%rax");
                    emit_line(cg, "    jz L_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                emit_line(cg, "    jmp L_match_end_%u", (unsigned)end_lbl);
                emit_line(cg, "L_skip_%u:", (unsigned)skip_lbl);
            }
            emit_line(cg, "    movq $0, %%rax");
            stack_push(cg, "rax");
            emit_line(cg, "L_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_R0_E_UNSUPPORTED;
            return -1;
    }
}

/* ─── Statement emission ─────────────────────────────────────────── */

static int emit_stmt(iii_cg_r0_state_t *cg, uint32_t node)
{
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_STMT_LET:
            if (emit_expr(cg, n->u.let_.value_expr) != 0) return -1;
            stack_pop(cg, "rax");
            local_add(cg, n->u.let_.name);
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", cg->local_count * 8);
            return 0;
        case III_AST_STMT_EXPR:
            if (emit_expr(cg, n->u.expr_stmt.expr) != 0) return -1;
            stack_pop(cg, "rax");
            return 0;
        case III_AST_STMT_RETURN:
            /* D7: explicit return — taken to be NTSTATUS-correct. */
            if (n->u.return_.value_expr) {
                if (emit_expr(cg, n->u.return_.value_expr) != 0) return -1;
                stack_pop(cg, "rax");
            } else {
                emit_line(cg, "    movabsq $0x00000000, %%rax  /* STATUS_SUCCESS */");
            }
            cg->emitted_explicit_return = true;
            /* D14: if @secmem, fence stores before return. */
            if (cg->cur_secmem) emit_line(cg, "    sfence");
            /* D9: witness exit.  BUG-2 fix: two pushes keep %rsp 16-byte aligned across the call. */
            emit_line(cg, "    /* witness exit (D9, ADR-024) */");
            emit_line(cg, "    pushq %%rax");
            emit_line(cg, "    pushq %%rax");
            emit_line(cg, "    movq $2, %%rcx  /* IIIW_EXIT */");
            emit_line(cg, "    subq $32, %%rsp");
            emit_line(cg, "    callq iii_witness_emit_kernel");
            emit_line(cg, "    addq $32, %%rsp");
            emit_line(cg, "    popq %%rax");
            emit_line(cg, "    popq %%rax");
            emit_line(cg, "    movq %%rbp, %%rsp\n    popq %%rbp\n    retq");
            return 0;
        case III_AST_STMT_ASSIGN: {
            const iii_ast_node_t *lv = iii_ast_get(cg->ast, n->u.assign.lvalue_expr);
            if (!lv) return -1;
            if (lv->kind == III_AST_EXPR_IDENT) {
                int slot = local_lookup_slot(cg, lv->u.ident.name);
                if (slot < 0) { local_add(cg, lv->u.ident.name); slot = (int)(cg->local_count - 1u); }
                if (emit_expr(cg, n->u.assign.value_expr) != 0) return -1;
                stack_pop(cg, "rax");
                /* D14: cache-bypassing store for sec-mem cycles. */
                if (cg->cur_secmem)
                    emit_line(cg, "    movntiq %%rax, -%d(%%rbp)  /* D14 secmem */", (slot+1)*8);
                else
                    emit_line(cg, "    movq %%rax, -%d(%%rbp)", (slot+1)*8);
                return 0;
            }
            if (lv->kind == III_AST_EXPR_INDEX) {
                if (emit_expr(cg, lv->u.index.object) != 0) return -1;
                if (emit_expr(cg, lv->u.index.index_expr) != 0) return -1;
                if (emit_expr(cg, n->u.assign.value_expr) != 0) return -1;
                stack_pop(cg, "rdx"); stack_pop(cg, "rcx"); stack_pop(cg, "rax");
                if (cg->cur_secmem)
                    emit_line(cg, "    movntiq %%rdx, (%%rax,%%rcx,8)  /* D14 secmem */");
                else
                    emit_line(cg, "    movq %%rdx, (%%rax,%%rcx,8)");
                return 0;
            }
            if (lv->kind == III_AST_EXPR_FIELD) {
                const iii_ast_node_t *obj = iii_ast_get(cg->ast, lv->u.field.object);
                if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                    cg->last_error = III_CG_R0_E_UNSUPPORTED;
                    return -1;
                }
                if (emit_expr(cg, n->u.assign.value_expr) != 0) return -1;
                stack_pop(cg, "rax");
                iii_emit_str(cg, cg->cur_secmem
                    ? "    movntiq %rax, "
                    : "    movq %rax, ");
                if (emit_field_label(cg, obj, lv->u.field.field_name) != 0) {
                    cg->last_error = III_CG_R0_E_UNSUPPORTED;
                    return -1;
                }
                iii_emit_str(cg, "(%rip)\n");
                return 0;
            }
            cg->last_error = III_CG_R0_E_UNSUPPORTED;
            return -1;
        }
        case III_AST_STMT_FOR: {
            uint32_t lbl_top = cg->label_counter++;
            uint32_t lbl_end = cg->label_counter++;
            if (emit_expr(cg, n->u.for_.iter_expr) != 0) return -1;
            stack_pop(cg, "rax");
            uint32_t count_slot = cg->local_count++;
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (count_slot + 1) * 8);
            local_add(cg, n->u.for_.var);
            uint32_t var_slot = cg->local_count - 1u;
            emit_line(cg, "    movq $0, -%d(%%rbp)", (var_slot + 1) * 8);
            emit_line(cg, "L_for_top_%u:", (unsigned)lbl_top);
            emit_line(cg, "    movq -%d(%%rbp), %%rax", (var_slot + 1) * 8);
            emit_line(cg, "    movq -%d(%%rbp), %%rcx", (count_slot + 1) * 8);
            emit_line(cg, "    cmpq %%rcx, %%rax");
            emit_line(cg, "    jge L_for_end_%u", (unsigned)lbl_end);
            if (n->u.for_.where_expr != 0) {
                if (emit_expr(cg, n->u.for_.where_expr) != 0) return -1;
                stack_pop(cg, "rax");
                emit_line(cg, "    testq %%rax, %%rax");
                emit_line(cg, "    jz L_for_continue_%u", (unsigned)lbl_top);
            }
            if (emit_block(cg, n->u.for_.body_block) != 0) return -1;
            stack_pop(cg, "rax");
            if (n->u.for_.where_expr != 0)
                emit_line(cg, "L_for_continue_%u:", (unsigned)lbl_top);
            emit_line(cg, "    movq -%d(%%rbp), %%rax", (var_slot + 1) * 8);
            emit_line(cg, "    addq $1, %%rax");
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (var_slot + 1) * 8);
            emit_line(cg, "    jmp L_for_top_%u", (unsigned)lbl_top);
            emit_line(cg, "L_for_end_%u:", (unsigned)lbl_end);
            return 0;
        }
        case III_AST_STMT_WAVEFRONT:
            for (uint32_t i = 0; i < n->u.wavefront.nodes.count; i++)
                if (emit_stmt(cg, iii_ast_list_at(cg->ast, n->u.wavefront.nodes, i)) != 0) return -1;
            return 0;
        case III_AST_STMT_SANCTUM_ENTER:
            cg->last_error = III_CG_R0_E_UNSUPPORTED;
            return -1;
        case III_AST_STMT_METAL: {
            uint32_t off = n->u.metal.raw_asm_str_idx;
            uint32_t len = n->u.metal.raw_asm_len;
            if (off + len <= cg->ast->source_len) {
                iii_emit_raw(cg, (const char *)(cg->ast->source_buf + off), len);
                iii_emit_ch(cg, '\n');
            }
            return 0;
        }
        case III_AST_STMT_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_stmt.arms.count;
            if (emit_expr(cg, n->u.match_stmt.scrutinee) != 0) return -1;
            stack_pop(cg, "rax");
            uint32_t scrut_slot = cg->local_count++;
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (scrut_slot + 1) * 8);
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_stmt.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit_line(cg, "    movq -%d(%%rbp), %%rax", (scrut_slot + 1) * 8);
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) return -1;
                emit_line(cg, "    jne L_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) return -1;
                    stack_pop(cg, "rax");
                    emit_line(cg, "    testq %%rax, %%rax");
                    emit_line(cg, "    jz L_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                stack_pop(cg, "rax");
                emit_line(cg, "    jmp L_match_end_%u", (unsigned)end_lbl);
                emit_line(cg, "L_skip_%u:", (unsigned)skip_lbl);
            }
            emit_line(cg, "L_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_R0_E_UNSUPPORTED;
            return -1;
    }
}

static int emit_block(iii_cg_r0_state_t *cg, uint32_t block_node)
{
    const iii_ast_node_t *n = iii_ast_get(cg->ast, block_node);
    if (!n) return -1;
    iii_ast_list_t stmts = (n->kind == III_AST_EXPR_BLOCK)
                            ? n->u.block.stmts : n->u.forward_block.stmts;
    uint32_t saved = cg->local_count;
    for (uint32_t i = 0; i < stmts.count; i++)
        if (emit_stmt(cg, iii_ast_list_at(cg->ast, stmts, i)) != 0) return -1;
    cg->local_count = saved;
    emit_line(cg, "    xorq %%rax, %%rax");
    stack_push(cg, "rax");
    return 0;
}

/* ─── Function emission ───────────────────────────────────────────
 * D1: DriverEntry signature contract.
 * D4: section selection (INIT / PAGE / .text).  PE/COFF Spec §6.
 * D6: SAL passthrough comments per parameter.
 * D7: NTSTATUS return discipline (fall-through → STATUS_SUCCESS).
 * D8: SEH unwind brackets.  MS x64 ABI §"Exception Handling".
 * D9: witness entry/exit.
 * D13: stack-budget warning.  Cite: WDK §"Kernel-Mode Stack Size". */

static const char *select_section(iii_cg_r0_state_t *cg,
                                  bool is_driver_entry,
                                  iii_ast_list_t mods)
{
    if (is_driver_entry) return "INIT";   /* D4: discardable post-init */
    if (mod_find(cg, mods, "paged")) return "PAGE";
    return ".text";
}

static void compute_function_attributes(iii_cg_r0_state_t *cg, iii_ast_list_t mods)
{
    cg->cur_max_irql = 2; /* DISPATCH_LEVEL by default */
    const iii_ast_node_t *m = mod_find(cg, mods, "irql_max");
    if (m) {
        int v = mod_first_int(cg, m, 2);
        if (v == -2) {
            /* Symbolic: inspect first arg ident text. */
            for (uint32_t i = 0; i < m->u.modifier.args.count; i++) {
                uint32_t aid = iii_ast_list_at(cg->ast, m->u.modifier.args, i);
                const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
                if (!a || a->kind != III_AST_EXPR_IDENT) continue;
                if (name_eq(cg, a->u.ident.name, "PASSIVE_LEVEL")) v = 0;
                else if (name_eq(cg, a->u.ident.name, "APC_LEVEL")) v = 1;
                else if (name_eq(cg, a->u.ident.name, "DISPATCH_LEVEL")) v = 2;
                else if (name_eq(cg, a->u.ident.name, "HIGH_LEVEL")) v = 31;
                break;
            }
            if (v == -2) v = 2;
        }
        cg->cur_max_irql = v;
    }
    cg->cur_paged   = mod_find(cg, mods, "paged") != NULL;
    cg->cur_secmem  = mod_find(cg, mods, "secmem") != NULL;
    cg->cur_returns_ntstatus = true; /* R0 cycles default to NTSTATUS */
}

static void emit_param_sal(iii_cg_r0_state_t *cg, const iii_ast_node_t *p)
{
    /* D6: scan param's type_node for @sal modifiers (best-effort,
     * since III parameters carry SAL via their type's modifier list). */
    const iii_ast_node_t *t = iii_ast_get(cg->ast, p->u.param.type_node);
    if (!t) return;
    iii_ast_list_t mods = {0};
    switch (t->kind) {
        case III_AST_TYPE_REF:   mods = t->u.type_ref.modifiers; break;
        case III_AST_TYPE_PTR:   mods = t->u.type_ptr.modifiers; break;
        case III_AST_TYPE_ARRAY: mods = t->u.type_array.modifiers; break;
        case III_AST_TYPE_TUPLE: mods = t->u.type_tuple.modifiers; break;
        case III_AST_TYPE_FN:    mods = t->u.type_fn.modifiers; break;
        default: return;
    }
    const iii_ast_node_t *sal = mod_find(cg, mods, "sal");
    if (!sal) return;
    iii_emit_str(cg, "    /* SAL: ");
    for (uint32_t i = 0; i < sal->u.modifier.args.count; i++) {
        uint32_t aid = iii_ast_list_at(cg->ast, sal->u.modifier.args, i);
        const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
        if (!a || a->kind != III_AST_EXPR_STR) continue;
        emit_line(cg, "%.*s ",
                  (int)a->u.str_.string_len,
                  cg->ast->string_payloads[a->u.str_.string_payload_idx]);
    }
    iii_emit_str(cg, " */\n");
}

static int emit_function(iii_cg_r0_state_t *cg,
                         iii_src_text_t name,
                         iii_ast_list_t params,
                         uint32_t body,
                         iii_ast_list_t mods)
{
    cg->local_count = 0;
    cg->stack_depth = 0;
    cg->label_counter = 0;
    cg->frame_bytes = III_CG_R0_FRAME;
    cg->emitted_explicit_return = false;

    compute_function_attributes(cg, mods);

    bool is_driver_entry = name_eq(cg, name, "driver_entry") ||
                           (mod_find(cg, mods, "entry") != NULL);

    /* D1: DriverEntry signature contract. */
    if (is_driver_entry && params.count != 2u) {
        cg->last_error = III_CG_R0_E_SIG_MISMATCH;
        emit_line(cg, "# III_CG_R0_E_SIG_MISMATCH: DriverEntry must take "
                      "(PDRIVER_OBJECT, PUNICODE_STRING)");
        return -1;
    }

    /* D4: section directive. */
    const char *sec = select_section(cg, is_driver_entry, mods);
    emit_line(cg, "    .section %s,\"xr\"  /* PE/COFF §6 */", sec);

    /* D3: IRQL header comment. */
    emit_line(cg, "    /* IRQL_REQUIRES_MAX(%d) */", cg->cur_max_irql);

    /* D6: SAL per-parameter comments. */
    for (uint32_t i = 0; i < params.count; i++) {
        uint32_t pid = iii_ast_list_at(cg->ast, params, i);
        const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
        if (p && p->kind == III_AST_PARAM) emit_param_sal(cg, p);
    }

    /* Reproducibility flag (D12) only for entry / table-managed sites. */
    iii_emit_str(cg, "    .global "); emit_decl_label(cg, name); iii_emit_ch(cg, '\n');
    if (is_driver_entry) {
        iii_emit_str(cg, "    .global DriverEntry\n");
        iii_emit_str(cg, "    /* D12: DriverEntry kept via .global (GNU as / PE-COFF) */\n");
        iii_emit_str(cg, "DriverEntry:\n");
    }
    emit_decl_label(cg, name);
    iii_emit_str(cg, ":\n");

    /* D8: SEH unwind start. */
    iii_emit_str(cg, "    .seh_proc "); emit_decl_label(cg, name); iii_emit_ch(cg, '\n');

    emit_line(cg, "    pushq %%rbp");
    iii_emit_str(cg, "    .seh_pushreg %rbp\n");
    emit_line(cg, "    movq %%rsp, %%rbp");
    emit_line(cg, "    subq $%u, %%rsp", (unsigned)cg->frame_bytes);
    iii_emit_str(cg, "    .seh_stackalloc 1024\n");
    iii_emit_str(cg, "    .seh_endprologue\n");

    /* D13: stack budget warning (assembler-time). */
    emit_line(cg, "    .if %u > 2048", (unsigned)cg->frame_bytes);
    emit_line(cg, "    .warning \"III_CG_R0: frame > 2KB on 12KB kernel stack\"");
    emit_line(cg, "    .endif");

    /* D14: secmem entry fence. */
    if (cg->cur_secmem) emit_line(cg, "    mfence  /* D14 secmem entry */");

    /* BUG-1 fix: spill the MS x64 params (rcx,rdx,r8,r9) to their frame slots BEFORE the
       witness ENTER call, which repurposes %rcx for IIIW_ENTER and may clobber volatiles. */
    const char *abi[4] = { "rcx", "rdx", "r8", "r9" };
    uint32_t pcount = params.count;
    for (uint32_t i = 0; i < pcount && i < 4u; i++) {
        uint32_t pid = iii_ast_list_at(cg->ast, params, i);
        const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
        if (p && p->kind == III_AST_PARAM) {
            local_add(cg, p->u.param.name);
            emit_line(cg, "    movq %%%s, -%d(%%rbp)", abi[i], cg->local_count * 8);
        }
    }

    /* D9: witness enter. */
    emit_line(cg, "    /* witness enter (D9, ADR-024) */");
    emit_line(cg, "    movq $1, %%rcx  /* IIIW_ENTER */");
    emit_line(cg, "    subq $32, %%rsp");
    emit_line(cg, "    callq iii_witness_emit_kernel");
    emit_line(cg, "    addq $32, %%rsp");

    if (body && emit_block(cg, body) != 0) return -1;

    /* D7: fall-through epilogue with explicit STATUS_SUCCESS. */
    if (!cg->emitted_explicit_return) {
        emit_line(cg, "    /* D7: fall-through → STATUS_SUCCESS */");
        emit_line(cg, "    movabsq $0x00000000, %%rax  /* STATUS_SUCCESS */");
    }
    if (cg->cur_secmem) emit_line(cg, "    sfence  /* D14 secmem exit */");

    /* D9: witness exit on fall-through.  BUG-2 fix: two pushes keep %rsp 16-byte aligned. */
    emit_line(cg, "    pushq %%rax");
    emit_line(cg, "    pushq %%rax");
    emit_line(cg, "    movq $2, %%rcx  /* IIIW_EXIT */");
    emit_line(cg, "    subq $32, %%rsp");
    emit_line(cg, "    callq iii_witness_emit_kernel");
    emit_line(cg, "    addq $32, %%rsp");
    emit_line(cg, "    popq %%rax");
    emit_line(cg, "    popq %%rax");

    emit_line(cg, "    movq %%rbp, %%rsp\n    popq %%rbp\n    retq");
    iii_emit_str(cg, "    .seh_endproc\n");
    return 0;
}

/* ─── D2: scan modifiers for @irp_handler and record dispatch entry */

static int record_irp_handler(iii_cg_r0_state_t *cg,
                              iii_src_text_t name,
                              iii_ast_list_t mods)
{
    const iii_ast_node_t *m = mod_find(cg, mods, "irp_handler");
    if (!m) return 0;
    int mj = -1;
    for (uint32_t i = 0; i < m->u.modifier.args.count; i++) {
        uint32_t aid = iii_ast_list_at(cg->ast, m->u.modifier.args, i);
        const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
        if (!a) continue;
        if (a->kind == III_AST_EXPR_IDENT) {
            mj = irp_mj_lookup((const char *)(cg->ast->source_buf + a->u.ident.name.offset),
                               a->u.ident.name.length);
            if (mj >= 0) break;
        } else if (a->kind == III_AST_EXPR_INT) {
            mj = (int)a->u.int_.value; break;
        } else if (a->kind == III_AST_EXPR_HEX) {
            mj = (int)a->u.hex_.value; break;
        }
    }
    if (mj < 0 || mj >= (int)III_CG_R0_MAX_IRP) {
        cg->last_error = III_CG_R0_E_UNSUPPORTED;
        return -1;
    }
    if (cg->irp_handlers[mj] != 0u) {
        cg->last_error = III_CG_R0_E_IRP_DUP;
        return -1;
    }
    /* Encode as offset+1 of name into source_buf via a sentinel cell.
     * We piggy-back on a side-table by allocating an indirection: store
     * a tag that the emit pass will resolve by re-walking decls. */
    cg->irp_handlers[mj] = name.offset | 0x80000000u;
    /* length is recoverable from the decl walk. */
    return 0;
}

/* D2: emit the dispatch table.  Cite: WDK §"Writing Dispatch Routines". */
static void emit_irp_dispatch_table(iii_cg_r0_state_t *cg)
{
    iii_emit_str(cg, "    .section .rdata,\"dr\"  /* D2: IRP dispatch */\n");
    iii_emit_str(cg, "    .global _iii_IrpDispatchTable\n");
    iii_emit_str(cg, "    /* D12: _iii_IrpDispatchTable kept via .global */\n");
    iii_emit_str(cg, "_iii_IrpDispatchTable:\n");
    const iii_ast_node_t *mod = iii_ast_get(cg->ast, cg->ast->root_module);
    for (uint32_t i = 0; i < III_CG_R0_MAX_IRP; i++) {
        if (cg->irp_handlers[i] == 0u) {
            emit_line(cg, "    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x%02x */", i);
            continue;
        }
        uint32_t name_off = cg->irp_handlers[i] & 0x7fffffffu;
        /* Resolve length by walking decls and matching offset. */
        uint32_t name_len = 0;
        for (uint32_t d = 0; d < mod->u.module_.decls.count; d++) {
            uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, d);
            const iii_ast_node_t *dn = iii_ast_get(cg->ast, did);
            if (!dn) continue;
            iii_src_text_t n = {0};
            switch (dn->kind) {
                case III_AST_FN_DECL: n = dn->u.fn_decl.name; break;
                case III_AST_CYCLE_DECL: n = dn->u.cycle_decl.name; break;
                default: continue;
            }
            if (n.offset == name_off) { name_len = n.length; break; }
        }
        iii_emit_str(cg, "    .quad ");
        iii_src_text_t fake = { name_off, name_len };
        emit_decl_label(cg, fake);
        emit_line(cg, "  /* IRP_MJ=0x%02x */", i);
    }

    /* Default fallback (D2): _iii_IrpNotImplemented returns
     * STATUS_NOT_SUPPORTED (0xC00000BB). */
    iii_emit_str(cg, "    .section .text\n");
    iii_emit_str(cg, "    .global _iii_IrpNotImplemented\n");
    iii_emit_str(cg, "    .weak _iii_IrpNotImplemented  /* D12 (GNU as) */\n");
    iii_emit_str(cg, "_iii_IrpNotImplemented:\n");
    iii_emit_str(cg, "    .seh_proc _iii_IrpNotImplemented\n");
    iii_emit_str(cg, "    .seh_endprologue\n");
    iii_emit_str(cg, "    movabsq $0xC00000BB, %rax  /* STATUS_NOT_SUPPORTED */\n");
    iii_emit_str(cg, "    retq\n");
    iii_emit_str(cg, "    .seh_endproc\n");
}

/* ─── Module emission ────────────────────────────────────────────── */

int iii_cg_r0_emit_module(iii_cg_r0_state_t *cg, FILE *out)
{
    if (!cg || !out) return III_CG_R0_E_NULL_ARG;
    cg->out = out;
    iii_sha256_init(&cg->hash);
    cg->witness_finalized = false;
    for (uint32_t i = 0; i < III_CG_R0_MAX_IRP; i++) cg->irp_handlers[i] = 0u;

    iii_emit_str(cg, "# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)\n");
    iii_emit_str(cg, "# Output binary: iiis-0.sys\n");
    iii_emit_str(cg, "    .att_syntax\n");

    /* String literal payload pool. */
    iii_emit_str(cg, "    .section .rdata,\"dr\"\n");
    for (uint32_t i = 0; i < cg->ast->string_payload_count; i++) {
        emit_line(cg, "L_str_%u:", (unsigned)i);
        const uint8_t *bytes = cg->ast->string_payloads[i];
        if (bytes) {
            iii_emit_str(cg, "    .ascii \"");
            for (; *bytes; bytes++) {
                char tmp[8];
                if (*bytes == '"' || *bytes == '\\') { iii_emit_ch(cg, '\\'); iii_emit_ch(cg, *bytes); }
                else if (*bytes == '\n') iii_emit_str(cg, "\\n");
                else if (*bytes >= 0x20 && *bytes < 0x7F) iii_emit_ch(cg, (int)*bytes);
                else { int n = snprintf(tmp, sizeof(tmp), "\\%03o", (unsigned)*bytes);
                       iii_emit_raw(cg, tmp, (size_t)n); }
            }
            iii_emit_str(cg, "\\0\"\n");
        }
    }

    const iii_ast_node_t *mod = iii_ast_get(cg->ast, cg->ast->root_module);
    if (!mod) return III_CG_R0_E_INTERNAL;

    /* Pass 1: harvest @irp_handler annotations (D2). */
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d) continue;
        if (d->kind == III_AST_FN_DECL)
            (void)record_irp_handler(cg, d->u.fn_decl.name, d->u.fn_decl.modifiers);
        else if (d->kind == III_AST_CYCLE_DECL)
            (void)record_irp_handler(cg, d->u.cycle_decl.name, d->u.cycle_decl.modifiers);
        if (cg->last_error == III_CG_R0_E_IRP_DUP) return III_CG_R0_E_IRP_DUP;
    }

    /* Pass 2: emit functions. */
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d) continue;
        switch (d->kind) {
            case III_AST_FN_DECL:
                if (emit_function(cg, d->u.fn_decl.name,
                                  d->u.fn_decl.params,
                                  d->u.fn_decl.body_block,
                                  d->u.fn_decl.modifiers) != 0)
                    return cg->last_error ? cg->last_error : III_CG_R0_E_INTERNAL;
                break;
            case III_AST_CYCLE_DECL:
                if (emit_function(cg, d->u.cycle_decl.name,
                                  d->u.cycle_decl.params,
                                  d->u.cycle_decl.forward_block,
                                  d->u.cycle_decl.modifiers) != 0)
                    return cg->last_error ? cg->last_error : III_CG_R0_E_INTERNAL;
                break;
            case III_AST_SEALED_CALL_METHOD_DECL: {
                /* Sealed-call methods host the seal dispatch entries. */
                iii_ast_list_t empty = {0,0};
                if (emit_function(cg, d->u.sealed_call.name,
                                  d->u.sealed_call.params,
                                  d->u.sealed_call.body_block,
                                  empty) != 0)
                    return cg->last_error ? cg->last_error : III_CG_R0_E_INTERNAL;
                break;
            }
            default: break;
        }
    }

    /* D2: dispatch table after all handlers exist. */
    emit_irp_dispatch_table(cg);

    /* D10: finalize witness. */
    iii_sha256_final(&cg->hash, cg->witness);
    cg->witness_finalized = true;

    return III_CG_R0_OK;
}

/* ─── Lifecycle / accessors ──────────────────────────────────────── */

iii_cg_r0_state_t *iii_cg_r0_create(iii_ast_t *ast,
                                    iii_sema_state_t *sema,
                                    iii_sid_state_t *sid,
                                    iii_walloc_state_t *walloc)
{
    if (!ast) return NULL;
    iii_cg_r0_state_t *cg = (iii_cg_r0_state_t *)calloc(1, sizeof(*cg));
    if (!cg) return NULL;
    cg->ast = ast; cg->sema = sema; cg->sid = sid; cg->walloc = walloc;
    cg->last_error = III_CG_R0_OK;
    cg->cur_max_irql = -1;
    cg->cur_ring = 0;
    return cg;
}

void iii_cg_r0_destroy(iii_cg_r0_state_t *cg) { if (cg) free(cg); }

int iii_cg_r0_get_witness(const iii_cg_r0_state_t *cg, uint8_t out32[32])
{
    if (!cg || !out32) return III_CG_R0_E_NULL_ARG;
    if (!cg->witness_finalized) return III_CG_R0_E_INTERNAL;
    memcpy(out32, cg->witness, 32);
    return III_CG_R0_OK;
}

int iii_cg_r0_last_error(const iii_cg_r0_state_t *cg)
{
    return cg ? cg->last_error : III_CG_R0_E_NULL_ARG;
}

const char *iii_cg_r0_error_name(int code)
{
    switch (code) {
        case III_CG_R0_OK:                  return "OK";
        case III_CG_R0_E_NULL_ARG:          return "NULL_ARG";
        case III_CG_R0_E_IO:                return "IO";
        case III_CG_R0_E_UNSUPPORTED:       return "UNSUPPORTED";
        case III_CG_R0_E_SIG_MISMATCH:      return "SIG_MISMATCH";
        case III_CG_R0_E_IRP_DUP:           return "IRP_DUP";
        case III_CG_R0_E_IRQL_VIOLATION:    return "IRQL_VIOLATION";
        case III_CG_R0_E_RING_WALL:         return "RING_WALL";
        case III_CG_R0_E_RETURN_DISCIPLINE: return "RETURN_DISCIPLINE";
        case III_CG_R0_E_STACK_OVER:        return "STACK_OVER";
        case III_CG_R0_E_INTERNAL:          return "INTERNAL";
        default:                            return "<unknown>";
    }
}
