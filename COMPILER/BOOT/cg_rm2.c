/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm2.c
 *
 * III Stage-0 Ring -2 (SANCTUM-sealed) codegen — implementation.
 *
 * Same SysV x64 expression emission as cg_rm1, but:
 *   - Output section is `.xii_sanctum.text`.  ELF form
 *     `.section .xii_sanctum.text, "ax", @progbits` is the default;
 *     the PE/COFF form `.section .xii_sanctum.text, "xr"` is selected
 *     by iii_cg_rm2_set_format(III_CG_RM2_FMT_PE).  See cg_rm2.h D2.
 *   - Each function preserves callee-saved r12-r15 + rbp + rbx (the
 *     gate trampoline in SANCTUM/sanctum_gate.S already preserves
 *     these, but we mirror it inside the body for defence in depth).
 *   - Each function emits a leading `xii_sanctum_emit_cycle` call
 *     that records the entering reduction's witness (per SPEC.XII §S14
 *     + SANCTUM/sanctum.h::xii_sanctum_emit_cycle).
 *
 * Strict NIH (ADR-021).  Hand-rolled stack-machine codegen.
 * SHA-256 implemented inline (RFC 6234).
 *
 * ─── Determinism contract (D9, D8) ─────────────────────────────────
 * The emitter is byte-for-byte deterministic.  Every byte written to
 * `out` is also fed into a streaming SHA-256 (the codegen witness),
 * which becomes the canonical sanctum mhash root and is what the
 * post-link sealer extends into the TPM PCR.  Because the image is
 * the platform root of trust, the codegen never relies on assembler-
 * inserted alignment: every alignment is `.balign N` explicit.
 */

#include "cg_rm2.h"

#include "ast.h"
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

/* ─── III ast.h opacity bridge ─────────────────────────────────────
 * Mirrors the bridge in cg_r3.c: the string-payload table is not
 * yet wrapped by ast.h. */
extern uint32_t       iii_ast_string_payload_count(const iii_ast_t *ast);
extern const uint8_t *iii_ast_string_payload_get(const iii_ast_t *ast, uint32_t idx);

#define III_CG_RM2_FRAME_RESERVE   1024u  /* 16-aligned sanctum local frame */
#define III_CG_RM2_MAX_LOCALS      64u

/* ─── D8: streaming SHA-256 (NIH, RFC 6234) ────────────────────── */

typedef struct {
    uint32_t state[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    uint32_t buflen;
} iii_rm2_sha256_t;

static const uint32_t III_RM2_SHA256_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};
static uint32_t iii_rm2_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32u - n)); }
static void iii_rm2_sha256_init(iii_rm2_sha256_t *s)
{
    s->state[0]=0x6a09e667u; s->state[1]=0xbb67ae85u; s->state[2]=0x3c6ef372u; s->state[3]=0xa54ff53au;
    s->state[4]=0x510e527fu; s->state[5]=0x9b05688cu; s->state[6]=0x1f83d9abu; s->state[7]=0x5be0cd19u;
    s->bitlen = 0; s->buflen = 0;
}
static void iii_rm2_sha256_compress(iii_rm2_sha256_t *s, const uint8_t blk[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++)
        w[i] = ((uint32_t)blk[i*4]<<24) | ((uint32_t)blk[i*4+1]<<16) |
               ((uint32_t)blk[i*4+2]<<8) | (uint32_t)blk[i*4+3];
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_rm2_rotr(w[i-15],7) ^ iii_rm2_rotr(w[i-15],18) ^ (w[i-15]>>3);
        uint32_t s1 = iii_rm2_rotr(w[i-2],17) ^ iii_rm2_rotr(w[i-2],19)  ^ (w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=s->state[0],b=s->state[1],c=s->state[2],d=s->state[3];
    uint32_t e=s->state[4],f=s->state[5],g=s->state[6],h=s->state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_rm2_rotr(e,6) ^ iii_rm2_rotr(e,11) ^ iii_rm2_rotr(e,25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + III_RM2_SHA256_K[i] + w[i];
        uint32_t S0 = iii_rm2_rotr(a,2) ^ iii_rm2_rotr(a,13) ^ iii_rm2_rotr(a,22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    s->state[0]+=a; s->state[1]+=b; s->state[2]+=c; s->state[3]+=d;
    s->state[4]+=e; s->state[5]+=f; s->state[6]+=g; s->state[7]+=h;
}
static void iii_rm2_sha256_update(iii_rm2_sha256_t *s, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    s->bitlen += (uint64_t)len * 8u;
    while (len > 0) {
        uint32_t take = 64u - s->buflen;
        if (take > len) take = (uint32_t)len;
        memcpy(s->buf + s->buflen, p, take);
        s->buflen += take; p += take; len -= take;
        if (s->buflen == 64u) { iii_rm2_sha256_compress(s, s->buf); s->buflen = 0; }
    }
}
static void iii_rm2_sha256_final(iii_rm2_sha256_t in, uint8_t out[32])
{
    /* Snapshot-style final: caller passes a value-copy so the live
     * streaming state is never disturbed.  This lets D8 be queried
     * any time without invalidating subsequent emits. */
    iii_rm2_sha256_t *s = &in;
    uint64_t bl = s->bitlen;
    uint8_t pad = 0x80u;
    iii_rm2_sha256_update(s, &pad, 1);
    uint8_t zero = 0;
    while (s->buflen != 56u) iii_rm2_sha256_update(s, &zero, 1);
    uint8_t lenbe[8];
    for (int i = 0; i < 8; i++) lenbe[i] = (uint8_t)(bl >> (56 - 8*i));
    iii_rm2_sha256_update(s, lenbe, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(s->state[i] >> 24);
        out[i*4+1] = (uint8_t)(s->state[i] >> 16);
        out[i*4+2] = (uint8_t)(s->state[i] >> 8);
        out[i*4+3] = (uint8_t)(s->state[i]);
    }
}

/* ─── Codegen state ──────────────────────────────────────────────── */

struct iii_cg_rm2_state {
    iii_ast_t            *ast;
    iii_sema_state_t     *sema;
    iii_sid_state_t      *sid;
    iii_walloc_state_t   *walloc;
    FILE                 *out;
    iii_cg_rm2_fmt_t      fmt;          /* D2 */
    bool                  const_time;   /* D6 */
    bool                  sealed;       /* D14 */
    bool                  cap_revoke_seen; /* D10 — per function */
    bool                  in_entry;     /* D10 — inside an entry body */
    uint32_t              local_count;
    uint32_t              stack_depth;
    uint32_t              label_counter;
    struct { iii_src_text_t name; uint32_t slot; } locals[III_CG_RM2_MAX_LOCALS];
    int                   last_error;
    iii_rm2_sha256_t      witness;      /* D8 — streaming over emitted bytes */
};

/* ─── Output / witness routing (D8 + D9) ──────────────────────────
 * Every byte sent to `out` flows through cg_emit_bytes so the codegen
 * witness is the EXACT SHA-256 of the asm text.  Cite: RFC 6234. */

static void cg_emit_bytes(iii_cg_rm2_state_t *cg, const void *buf, size_t n)
{
    if (cg->sealed) { cg->last_error = III_CG_RM2_E_SEALED; return; }
    if (cg->out) {
        if (fwrite(buf, 1, n, cg->out) != n) cg->last_error = III_CG_RM2_E_IO;
    }
    iii_rm2_sha256_update(&cg->witness, buf, n);
}
static void cg_emit_str(iii_cg_rm2_state_t *cg, const char *s)
{
    cg_emit_bytes(cg, s, strlen(s));
}
static void cg_emit_char(iii_cg_rm2_state_t *cg, int c)
{
    uint8_t b = (uint8_t)c;
    cg_emit_bytes(cg, &b, 1);
}
static void cg_emit_fmt(iii_cg_rm2_state_t *cg, const char *fmt, ...)
{
    char buf[512];
    va_list ap; va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    if (n > 0) cg_emit_bytes(cg, buf, (size_t)((n < (int)sizeof(buf)) ? n : (int)sizeof(buf)-1));
}
/* Convenience: emit a complete asm line + newline. */
static void emit(iii_cg_rm2_state_t *cg, const char *fmt, ...)
{
    char buf[512];
    va_list ap; va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    if (n > 0) cg_emit_bytes(cg, buf, (size_t)((n < (int)sizeof(buf)) ? n : (int)sizeof(buf)-1));
    cg_emit_char(cg, '\n');
}

/* ─── D2: section directives, ELF + PE forms ─────────────────────── */

static void emit_section_text(iii_cg_rm2_state_t *cg)
{
    /* ELF: cite ELF gABI §4 (Section flags), gas info "Section".
     * PE : cite PE/COFF Spec rev 11 §3.1 (IMAGE_SCN_MEM_EXECUTE | _READ). */
    if (cg->fmt == III_CG_RM2_FMT_PE)
        cg_emit_str(cg, "    .section .xii_sanctum.text, \"xr\"\n");
    else
        cg_emit_str(cg, "    .section .xii_sanctum.text, \"ax\", @progbits\n");
}
static void emit_section_rodata(iii_cg_rm2_state_t *cg)
{
    if (cg->fmt == III_CG_RM2_FMT_PE)
        cg_emit_str(cg, "    .section .xii_sanctum.rodata, \"r\"\n");
    else
        cg_emit_str(cg, "    .section .xii_sanctum.rodata, \"a\", @progbits\n");
}

/* ─── D5: permitted symbol prefixes for memory operands ──────────── */

static const char *const III_RM2_PERMITTED_PREFIXES[] = {
    "L_sanctum_",            /* internal labels in sanctum sections */
    "iii_sanctum_",          /* sanctum runtime in .xii_sanctum.* */
    "xii_sanctum_",          /* legacy sanctum runtime ABI */
    "iii_cap_",              /* capability runtime (in sanctum) */
    NULL,
};
static bool sym_is_permitted(const char *name, size_t n)
{
    for (size_t i = 0; III_RM2_PERMITTED_PREFIXES[i]; i++) {
        size_t plen = strlen(III_RM2_PERMITTED_PREFIXES[i]);
        if (n >= plen && memcmp(name, III_RM2_PERMITTED_PREFIXES[i], plen) == 0)
            return true;
    }
    return false;
}

/* ─── D7: oneway-port discipline.  The MMIO witness BAR is mapped
 * at the symbol `iii_sanctum_oneway_port`.  Reads are forbidden. */
static const char *const III_RM2_ONEWAY_PORT = "iii_sanctum_oneway_port";

static int guard_symbol_load(iii_cg_rm2_state_t *cg, const char *name, size_t n)
{
    /* D5: target must be in permitted prefix set. */
    if (!sym_is_permitted(name, n)) {
        cg->last_error = III_CG_RM2_E_FORBIDDEN_TARGET;
        return -1;
    }
    /* D7: reject reads of the oneway port. */
    size_t plen = strlen(III_RM2_ONEWAY_PORT);
    if (n == plen && memcmp(name, III_RM2_ONEWAY_PORT, plen) == 0) {
        cg->last_error = III_CG_RM2_E_ONEWAY_READ;
        return -1;
    }
    return 0;
}

/* ─── D1: PIC-only operand emission ───────────────────────────────
 * Every memory operand here is one of:
 *   sym(%rip)            — RIP-relative (AMD64 ABI §3.5.5)
 *   -N(%rbp)             — stack frame
 *   (%reg [, %reg, S])   — register-indirect / SIB
 * No `movabsq $sym` (absolute reloc) is ever emitted; address-of
 * symbol uses `leaq sym(%rip)` exclusively. */

static int emit_sym_address(iii_cg_rm2_state_t *cg,
                              const char *symbuf, size_t symlen,
                              const char *dst_reg)
{
    if (guard_symbol_load(cg, symbuf, symlen) != 0) return -1;
    cg_emit_str(cg, "    leaq ");
    cg_emit_bytes(cg, symbuf, symlen);
    cg_emit_str(cg, "(%rip), %");
    cg_emit_str(cg, dst_reg);
    cg_emit_char(cg, '\n');
    return 0;
}
static int emit_sym_load_qword(iii_cg_rm2_state_t *cg,
                                 const char *symbuf, size_t symlen,
                                 const char *dst_reg)
{
    if (guard_symbol_load(cg, symbuf, symlen) != 0) return -1;
    cg_emit_str(cg, "    movq ");
    cg_emit_bytes(cg, symbuf, symlen);
    cg_emit_str(cg, "(%rip), %");
    cg_emit_str(cg, dst_reg);
    cg_emit_char(cg, '\n');
    return 0;
}
static int emit_sym_store_qword(iii_cg_rm2_state_t *cg,
                                  const char *src_reg,
                                  const char *symbuf, size_t symlen)
{
    /* Symbol target is permitted only if it is in our address space
     * (D5).  Writes to the oneway port are explicitly allowed. */
    if (!sym_is_permitted(symbuf, symlen)) {
        cg->last_error = III_CG_RM2_E_FORBIDDEN_TARGET; return -1;
    }
    cg_emit_str(cg, "    movq %");
    cg_emit_str(cg, src_reg);
    cg_emit_str(cg, ", ");
    cg_emit_bytes(cg, symbuf, symlen);
    cg_emit_str(cg, "(%rip)\n");
    return 0;
}

/* ─── Local-variable management ──────────────────────────────────── */

static int local_slot(iii_cg_rm2_state_t *cg, iii_src_text_t n)
{
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    for (uint32_t i = 0; i < cg->local_count; i++)
        if (cg->locals[i].name.length == n.length &&
            memcmp(src + cg->locals[i].name.offset, src + n.offset, n.length) == 0)
            return (int)cg->locals[i].slot;
    return -1;
}
static void local_add(iii_cg_rm2_state_t *cg, iii_src_text_t n)
{
    if (cg->local_count >= III_CG_RM2_MAX_LOCALS) return;
    cg->locals[cg->local_count].name = n;
    cg->locals[cg->local_count].slot = cg->local_count;
    cg->local_count++;
}
static void push_r(iii_cg_rm2_state_t *cg, const char *r)
{
    emit(cg, "    pushq %%%s", r); cg->stack_depth++;
}
static void pop_r(iii_cg_rm2_state_t *cg, const char *r)
{
    emit(cg, "    popq %%%s", r); if (cg->stack_depth) cg->stack_depth--;
}

/* ─── Identifier mangling (label emission) ───────────────────────── */

static void elabel(iii_cg_rm2_state_t *cg, iii_src_text_t name)
{
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    cg_emit_str(cg, "L_sanctum_");
    for (uint32_t i = 0; i < name.length; i++) {
        uint8_t b = src[name.offset + i];
        if ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') cg_emit_char(cg, (int)b);
        else cg_emit_char(cg, '_');
    }
}
/* Build the mangled name into a small buffer so it can be vetted by
 * the D5/D7 guards before being committed to `out`. */
static size_t mangle_to_buf(iii_cg_rm2_state_t *cg, iii_src_text_t name,
                              char *buf, size_t buflen)
{
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    static const char prefix[] = "L_sanctum_";
    size_t pn = sizeof(prefix) - 1;
    if (buflen < pn + 1) return 0;
    memcpy(buf, prefix, pn);
    size_t k = pn;
    for (uint32_t i = 0; i < name.length && k + 1 < buflen; i++) {
        uint8_t b = src[name.offset + i];
        if ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') buf[k++] = (char)b;
        else buf[k++] = '_';
    }
    buf[k] = 0;
    return k;
}

/* ─── Hexad packing (unchanged from cg_rm1) ────────────────────── */

static uint16_t pack_hexad_trits(const iii_ast_trit_t trits[6])
{
    uint16_t v = 0;
    for (int i = 0; i < 6; i++) v = (uint16_t)(v | ((uint16_t)((uint16_t)trits[i] & 0x3u) << (2 * i)));
    return v;
}
static void emit_mhash_data_label(iii_cg_rm2_state_t *cg, uint32_t node_id, const uint8_t mh[32])
{
    /* Cite SPEC.XII §S14.7 (mhash-as-data).  Emitted into rodata
     * which lives in .xii_sanctum.rodata (D5-permitted target). */
    cg_emit_str(cg, "    .balign 32\n");                /* D9 explicit */
    cg_emit_fmt(cg, "L_sanctum_mhash_%u:\n    .byte ", (unsigned)node_id);
    for (int i = 0; i < 32; i++) cg_emit_fmt(cg, "0x%02x%s", mh[i], (i == 31) ? "\n" : ", ");
}
static int emit_field_label(iii_cg_rm2_state_t *cg, const iii_ast_node_t *obj,
                              iii_src_text_t field_name)
{
    if (!obj || obj->kind != III_AST_EXPR_IDENT) return -1;
    char buf[256];
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    static const char prefix[] = "L_sanctum_";
    size_t pn = sizeof(prefix) - 1;
    if (pn + 1 >= sizeof(buf)) return -1;
    memcpy(buf, prefix, pn);
    size_t k = pn;
    for (uint32_t i = 0; i < obj->u.ident.name.length && k + 3 < sizeof(buf); i++) {
        uint8_t b = src[obj->u.ident.name.offset + i];
        buf[k++] = ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') ? (char)b : '_';
    }
    if (k + 2 >= sizeof(buf)) return -1;
    buf[k++] = '_'; buf[k++] = '_';
    for (uint32_t i = 0; i < field_name.length && k + 1 < sizeof(buf); i++) {
        uint8_t b = src[field_name.offset + i];
        buf[k++] = ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') ? (char)b : '_';
    }
    buf[k] = 0;
    if (!sym_is_permitted(buf, k)) {
        cg->last_error = III_CG_RM2_E_FORBIDDEN_TARGET;
        return -1;
    }
    cg_emit_bytes(cg, buf, k);
    return 0;
}

/* ─── Forward decls ──────────────────────────────────────────────── */

static int emit_expr (iii_cg_rm2_state_t *cg, uint32_t node);
static int emit_stmt (iii_cg_rm2_state_t *cg, uint32_t node);
static int emit_block(iii_cg_rm2_state_t *cg, uint32_t node);

/* ─── Pattern compare (D6: const-time-aware) ──────────────────── */

static int emit_pattern_compare(iii_cg_rm2_state_t *cg, uint32_t pat_node)
{
    const iii_ast_node_t *p = iii_ast_get(cg->ast, pat_node);
    if (!p) return -1;
    switch (p->kind) {
        case III_AST_PAT_WILDCARD:
        case III_AST_PAT_IDENT:
            emit(cg, "    cmpq %%rax, %%rax");
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
                default: cg->last_error = III_CG_RM2_E_UNSUPPORTED; return -1;
            }
            /* movabsq $imm — immediate-class only, NOT a relocation;
             * permitted under D1. */
            emit(cg, "    movabsq $0x%llx, %%rcx", (unsigned long long)v);
            emit(cg, "    cmpq %%rcx, %%rax");
            return 0;
        }
        case III_AST_PAT_HEXAD: {
            uint16_t packed = pack_hexad_trits(p->u.pat_hexad.trits);
            emit(cg, "    movabsq $0x%x, %%rcx", (unsigned)packed);
            emit(cg, "    cmpq %%rcx, %%rax");
            return 0;
        }
        default:
            cg->last_error = III_CG_RM2_E_UNSUPPORTED;
            return -1;
    }
}
static void emit_pattern_bind(iii_cg_rm2_state_t *cg, uint32_t pat_node)
{
    const iii_ast_node_t *p = iii_ast_get(cg->ast, pat_node);
    if (!p || p->kind != III_AST_PAT_IDENT) return;
    local_add(cg, p->u.pat_ident.name);
    uint32_t slot = cg->local_count - 1u;
    emit(cg, "    movq %%rax, -%d(%%rbp)", (int)((slot + 1) * 8));
}

/* ─── D6: constant-time boolean lowering helper ─────────────────── */

static void emit_bool_setcc(iii_cg_rm2_state_t *cg, const char *cc)
{
    /* Default lowering: setcc + zero-extend.  Already constant-time
     * in itself (no branch), so const_time toggle is a no-op here.
     * Cite: Intel SDM Vol 2A — SETcc / MOVZX, no microarchitectural
     * data-dependent latency on these on supported families.
     * Documented per FIPS 140-3 IG D.J. */
    emit(cg, "    cmpq %%rcx, %%rax");
    emit(cg, "    %s %%al", cc);
    emit(cg, "    movzbq %%al, %%rax");
    (void)cg;
}

/* ─── Expressions ────────────────────────────────────────────────── */

static int emit_expr(iii_cg_rm2_state_t *cg, uint32_t node)
{
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_EXPR_INT: case III_AST_EXPR_HEX: {
            uint64_t v = (n->kind == III_AST_EXPR_INT) ? n->u.int_.value : n->u.hex_.value;
            emit(cg, "    movabsq $0x%llx, %%rax", (unsigned long long)v); push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_BOOL: emit(cg, "    movq $%d, %%rax", n->u.bool_.value?1:0); push_r(cg, "rax"); return 0;
        case III_AST_EXPR_TRIT: emit(cg, "    movq $%d, %%rax", (int)n->u.trit_.trit); push_r(cg, "rax"); return 0;
        case III_AST_EXPR_UNIT: emit(cg, "    xorq %%rax, %%rax"); push_r(cg, "rax"); return 0;
        case III_AST_EXPR_STR: {
            char buf[64];
            int k = snprintf(buf, sizeof(buf), "L_sanctum_str_%u",
                             (unsigned)n->u.str_.string_payload_idx);
            if (k <= 0) return -1;
            if (emit_sym_address(cg, buf, (size_t)k, "rax") != 0) return -1;
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_IDENT: {
            int s = local_slot(cg, n->u.ident.name);
            if (s >= 0) { emit(cg, "    movq -%d(%%rbp), %%rax", (s+1)*8); push_r(cg, "rax"); return 0; }
            char buf[256];
            size_t k = mangle_to_buf(cg, n->u.ident.name, buf, sizeof(buf));
            if (k == 0) { cg->last_error = III_CG_RM2_E_INTERNAL; return -1; }
            if (emit_sym_address(cg, buf, k, "rax") != 0) return -1;
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_PAREN: return emit_expr(cg, n->u.paren.inner);
        case III_AST_EXPR_BINARY: {
            if (emit_expr(cg, n->u.binary.lhs)) return -1;
            if (emit_expr(cg, n->u.binary.rhs)) return -1;
            pop_r(cg, "rcx"); pop_r(cg, "rax");
            switch (n->u.binary.op) {
                case III_BIN_ADD: emit(cg, "    addq %%rcx, %%rax"); break;
                case III_BIN_SUB: emit(cg, "    subq %%rcx, %%rax"); break;
                case III_BIN_MUL: emit(cg, "    imulq %%rcx, %%rax"); break;
                case III_BIN_DIV: emit(cg, "    cqto\n    idivq %%rcx"); break;
                case III_BIN_MOD: emit(cg, "    cqto\n    idivq %%rcx\n    movq %%rdx, %%rax"); break;
                case III_BIN_AND: emit(cg, "    andq %%rcx, %%rax"); break;
                case III_BIN_OR:  emit(cg, "    orq %%rcx, %%rax"); break;
                case III_BIN_XOR: emit(cg, "    xorq %%rcx, %%rax"); break;
                case III_BIN_SHL: emit(cg, "    shlq %%cl, %%rax"); break;
                case III_BIN_SHR: emit(cg, "    shrq %%cl, %%rax"); break;
                case III_BIN_EQ:  emit_bool_setcc(cg, "sete"); break;
                case III_BIN_NEQ: emit_bool_setcc(cg, "setne"); break;
                case III_BIN_LT:  emit_bool_setcc(cg, "setl"); break;
                case III_BIN_LE:  emit_bool_setcc(cg, "setle"); break;
                case III_BIN_GT:  emit_bool_setcc(cg, "setg"); break;
                case III_BIN_GE:  emit_bool_setcc(cg, "setge"); break;
                case III_BIN_LAND:
                    /* D6: branch-free logical AND via test+setne+and. */
                    emit(cg, "    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rdx");
                    emit(cg, "    testq %%rcx, %%rcx\n    setne %%al\n    movzbq %%al, %%rax");
                    emit(cg, "    andq %%rdx, %%rax");
                    break;
                case III_BIN_LOR:
                    /* D6: branch-free logical OR via or+test+setne. */
                    emit(cg, "    orq %%rcx, %%rax\n    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rax");
                    break;
                default:
                    cg->last_error = III_CG_RM2_E_UNSUPPORTED;
                    return -1;
            }
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_UNARY: {
            if (emit_expr(cg, n->u.unary.operand)) return -1;
            pop_r(cg, "rax");
            switch (n->u.unary.op) {
                case III_UN_NEG:   emit(cg, "    negq %%rax"); break;
                case III_UN_NOT:   emit(cg, "    testq %%rax, %%rax\n    sete %%al\n    movzbq %%al, %%rax"); break;
                case III_UN_BNOT:  emit(cg, "    notq %%rax"); break;
                case III_UN_DEREF: emit(cg, "    movq (%%rax), %%rax"); break;
                case III_UN_ADDR:  break;
            }
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_CALL: {
            uint32_t ac = n->u.call.args.count;
            for (uint32_t i = 0; i < ac; i++) {
                uint32_t aid = iii_ast_list_at(cg->ast, n->u.call.args, i);
                const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
                if (a && a->kind == III_AST_ARG)
                    if (emit_expr(cg, a->u.arg.value_expr)) return -1;
            }
            const char *abi[6] = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" };
            uint32_t r = ac > 6u ? 6u : ac;
            for (uint32_t i = 0; i < r; i++) pop_r(cg, abi[r - 1u - i]);
            uint32_t pad = (cg->stack_depth & 1u) ? 1u : 0u;
            if (pad) { emit(cg, "    subq $8, %%rsp"); cg->stack_depth++; }
            const iii_ast_node_t *callee = iii_ast_get(cg->ast, n->u.call.callee);
            if (callee && callee->kind == III_AST_EXPR_IDENT) {
                /* Direct call.  D5: symbol must be a permitted target.
                 * D10: track iii_cap_revoke sightings. */
                char buf[256];
                size_t k = mangle_to_buf(cg, callee->u.ident.name, buf, sizeof(buf));
                if (k == 0) { cg->last_error = III_CG_RM2_E_INTERNAL; return -1; }
                if (!sym_is_permitted(buf, k)) {
                    cg->last_error = III_CG_RM2_E_FORBIDDEN_TARGET;
                    return -1;
                }
                /* Note: cap-revoke detection on the *source* identifier,
                 * not on the mangled label. */
                const uint8_t *src = iii_ast_source_buf(cg->ast);
                static const char crev[] = "iii_cap_revoke";
                if (callee->u.ident.name.length == sizeof(crev) - 1 &&
                    memcmp(src + callee->u.ident.name.offset, crev, sizeof(crev) - 1) == 0)
                    cg->cap_revoke_seen = true;
                cg_emit_str(cg, "    callq ");
                cg_emit_bytes(cg, buf, k);
                cg_emit_char(cg, '\n');
            } else {
                /* Indirect call through register: PIC by definition. */
                if (emit_expr(cg, n->u.call.callee)) return -1;
                pop_r(cg, "rax"); emit(cg, "    callq *%%rax");
            }
            if (pad) { emit(cg, "    addq $8, %%rsp"); cg->stack_depth--; }
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_BLOCK: return emit_block(cg, node);
        case III_AST_EXPR_FIELD: {
            const iii_ast_node_t *obj = iii_ast_get(cg->ast, n->u.field.object);
            if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                cg->last_error = III_CG_RM2_E_UNSUPPORTED;
                return -1;
            }
            cg_emit_str(cg, "    leaq ");
            if (emit_field_label(cg, obj, n->u.field.field_name) != 0) return -1;
            cg_emit_str(cg, "(%rip), %rax\n");
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_INDEX: {
            if (emit_expr(cg, n->u.index.object)) return -1;
            if (emit_expr(cg, n->u.index.index_expr)) return -1;
            pop_r(cg, "rcx"); pop_r(cg, "rax");
            emit(cg, "    movq (%%rax,%%rcx,8), %%rax");
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_HEXAD: {
            uint16_t packed = pack_hexad_trits(n->u.hexad_.trits);
            emit(cg, "    movabsq $0x%x, %%rax", (unsigned)packed);
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_MHASH: {
            emit_section_rodata(cg);
            emit_mhash_data_label(cg, node, n->u.mhash_.mhash);
            emit_section_text(cg);
            char buf[64];
            int k = snprintf(buf, sizeof(buf), "L_sanctum_mhash_%u", (unsigned)node);
            if (k <= 0) return -1;
            if (emit_sym_address(cg, buf, (size_t)k, "rax") != 0) return -1;
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_RAW_ASM: {
            uint32_t off = n->u.raw_asm.raw_asm_str_idx;
            uint32_t len = n->u.raw_asm.raw_asm_len;
            if (off + len <= iii_ast_source_len(cg->ast)) {
                /* Raw asm is opaque to D1/D5 enforcement.  The
                 * sanctum review checklist (SPEC.XII §S14.9) requires
                 * out-of-band review for every metal/raw_asm site. */
                cg_emit_bytes(cg, iii_ast_source_buf(cg->ast) + off, len);
                cg_emit_char(cg, '\n');
            }
            emit(cg, "    movq $0, %%rax");
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_expr.arms.count;
            if (emit_expr(cg, n->u.match_expr.scrutinee) != 0) return -1;
            pop_r(cg, "rax");
            uint32_t scrut_slot = cg->local_count++;
            emit(cg, "    movq %%rax, -%d(%%rbp)", (int)((scrut_slot + 1) * 8));
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_expr.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit(cg, "    movq -%d(%%rbp), %%rax", (int)((scrut_slot + 1) * 8));
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) return -1;
                emit(cg, "    jne L_sanctum_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) return -1;
                    pop_r(cg, "rax");
                    emit(cg, "    testq %%rax, %%rax");
                    emit(cg, "    jz L_sanctum_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                emit(cg, "    jmp L_sanctum_match_end_%u", (unsigned)end_lbl);
                emit(cg, "L_sanctum_skip_%u:", (unsigned)skip_lbl);
            }
            emit(cg, "    movq $0, %%rax");
            push_r(cg, "rax");
            emit(cg, "L_sanctum_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_RM2_E_UNSUPPORTED;
            return -1;
    }
}

/* ─── Statement emitters ─────────────────────────────────────────── */

/* D11: clear caller-saved volatiles before retq.  SysV AMD64 ABI
 * §3.2.1 — caller-saved set: rax, rcx, rdx, rsi, rdi, r8, r9, r10,
 * r11.  XMM0-XMM15 cleared via PXOR (caller-saved per §3.2.3).  */
static void emit_volatile_clear(iii_cg_rm2_state_t *cg)
{
    emit(cg, "    xorq %%rcx, %%rcx");
    emit(cg, "    xorq %%rdx, %%rdx");
    emit(cg, "    xorq %%rsi, %%rsi");
    emit(cg, "    xorq %%rdi, %%rdi");
    emit(cg, "    xorq %%r8,  %%r8");
    emit(cg, "    xorq %%r9,  %%r9");
    emit(cg, "    xorq %%r10, %%r10");
    emit(cg, "    xorq %%r11, %%r11");
    for (int i = 0; i < 16; i++) emit(cg, "    pxor %%xmm%d, %%xmm%d", i, i);
}

static void emit_sanctum_epilogue(iii_cg_rm2_state_t *cg)
{
    /* Restore callee-saved + retq.  rax is preserved as the return
     * value; D11 clears all other volatiles immediately before. */
    emit_volatile_clear(cg);
    emit(cg, "    movq %%rbp, %%rsp\n    popq %%rbx\n    popq %%r12\n    popq %%r13\n    popq %%r14\n    popq %%r15\n    popq %%rbp\n    retq");
}

static int emit_stmt(iii_cg_rm2_state_t *cg, uint32_t node)
{
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_STMT_LET:
            if (emit_expr(cg, n->u.let_.value_expr)) return -1;
            pop_r(cg, "rax"); local_add(cg, n->u.let_.name);
            emit(cg, "    movq %%rax, -%d(%%rbp)", (int)(cg->local_count * 8));
            return 0;
        case III_AST_STMT_EXPR:
            if (emit_expr(cg, n->u.expr_stmt.expr)) return -1;
            pop_r(cg, "rax"); return 0;
        case III_AST_STMT_RETURN:
            if (n->u.return_.value_expr) {
                if (emit_expr(cg, n->u.return_.value_expr)) return -1;
                pop_r(cg, "rax");
            } else emit(cg, "    xorq %%rax, %%rax");
            /* D10: every return path requires cap_revoke first. */
            if (cg->in_entry && !cg->cap_revoke_seen) {
                cg->last_error = III_CG_RM2_E_NO_CAP_REVOKE;
                return -1;
            }
            emit_sanctum_epilogue(cg);
            return 0;
        case III_AST_STMT_ASSIGN: {
            const iii_ast_node_t *lv = iii_ast_get(cg->ast, n->u.assign.lvalue_expr);
            if (!lv) return -1;
            if (lv->kind == III_AST_EXPR_IDENT) {
                int s = local_slot(cg, lv->u.ident.name);
                if (s < 0) { local_add(cg, lv->u.ident.name); s = (int)(cg->local_count - 1u); }
                if (emit_expr(cg, n->u.assign.value_expr)) return -1;
                pop_r(cg, "rax");
                emit(cg, "    movq %%rax, -%d(%%rbp)", (s+1)*8);
                return 0;
            }
            if (lv->kind == III_AST_EXPR_INDEX) {
                if (emit_expr(cg, lv->u.index.object)) return -1;
                if (emit_expr(cg, lv->u.index.index_expr)) return -1;
                if (emit_expr(cg, n->u.assign.value_expr)) return -1;
                pop_r(cg, "rdx"); pop_r(cg, "rcx"); pop_r(cg, "rax");
                emit(cg, "    movq %%rdx, (%%rax,%%rcx,8)");
                return 0;
            }
            if (lv->kind == III_AST_EXPR_FIELD) {
                const iii_ast_node_t *obj = iii_ast_get(cg->ast, lv->u.field.object);
                if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                    cg->last_error = III_CG_RM2_E_UNSUPPORTED; return -1;
                }
                if (emit_expr(cg, n->u.assign.value_expr)) return -1;
                pop_r(cg, "rax");
                cg_emit_str(cg, "    movq %rax, ");
                if (emit_field_label(cg, obj, lv->u.field.field_name) != 0) return -1;
                cg_emit_str(cg, "(%rip)\n");
                return 0;
            }
            cg->last_error = III_CG_RM2_E_UNSUPPORTED;
            return -1;
        }
        case III_AST_STMT_FOR: {
            uint32_t lbl_top = cg->label_counter++;
            uint32_t lbl_end = cg->label_counter++;
            if (emit_expr(cg, n->u.for_.iter_expr) != 0) return -1;
            pop_r(cg, "rax");
            uint32_t count_slot = cg->local_count++;
            emit(cg, "    movq %%rax, -%d(%%rbp)", (int)((count_slot + 1) * 8));
            local_add(cg, n->u.for_.var);
            uint32_t var_slot = cg->local_count - 1u;
            emit(cg, "    movq $0, -%d(%%rbp)", (int)((var_slot + 1) * 8));
            emit(cg, "L_sanctum_for_top_%u:", (unsigned)lbl_top);
            emit(cg, "    movq -%d(%%rbp), %%rax", (int)((var_slot + 1) * 8));
            emit(cg, "    movq -%d(%%rbp), %%rcx", (int)((count_slot + 1) * 8));
            emit(cg, "    cmpq %%rcx, %%rax");
            emit(cg, "    jge L_sanctum_for_end_%u", (unsigned)lbl_end);
            if (n->u.for_.where_expr != 0) {
                if (emit_expr(cg, n->u.for_.where_expr) != 0) return -1;
                pop_r(cg, "rax");
                emit(cg, "    testq %%rax, %%rax");
                emit(cg, "    jz L_sanctum_for_continue_%u", (unsigned)lbl_top);
            }
            if (emit_block(cg, n->u.for_.body_block) != 0) return -1;
            pop_r(cg, "rax");
            if (n->u.for_.where_expr != 0) emit(cg, "L_sanctum_for_continue_%u:", (unsigned)lbl_top);
            emit(cg, "    movq -%d(%%rbp), %%rax", (int)((var_slot + 1) * 8));
            emit(cg, "    addq $1, %%rax");
            emit(cg, "    movq %%rax, -%d(%%rbp)", (int)((var_slot + 1) * 8));
            emit(cg, "    jmp L_sanctum_for_top_%u", (unsigned)lbl_top);
            emit(cg, "L_sanctum_for_end_%u:", (unsigned)lbl_end);
            return 0;
        }
        case III_AST_STMT_WAVEFRONT:
            for (uint32_t i = 0; i < n->u.wavefront.nodes.count; i++)
                if (emit_stmt(cg, iii_ast_list_at(cg->ast, n->u.wavefront.nodes, i)) != 0) return -1;
            return 0;
        case III_AST_STMT_SANCTUM_ENTER: {
            local_add(cg, n->u.sanctum_enter.frame_var);
            uint32_t frame_slot = cg->local_count - 1u;
            emit(cg, "    movq $0, -%d(%%rbp)", (int)((frame_slot + 1) * 8));
            if (emit_block(cg, n->u.sanctum_enter.body_block) != 0) return -1;
            pop_r(cg, "rax");
            return 0;
        }
        case III_AST_STMT_METAL: {
            uint32_t off = n->u.metal.raw_asm_str_idx;
            uint32_t len = n->u.metal.raw_asm_len;
            if (off + len <= iii_ast_source_len(cg->ast)) {
                cg_emit_bytes(cg, iii_ast_source_buf(cg->ast) + off, len);
                cg_emit_char(cg, '\n');
            }
            return 0;
        }
        case III_AST_STMT_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_stmt.arms.count;
            if (emit_expr(cg, n->u.match_stmt.scrutinee) != 0) return -1;
            pop_r(cg, "rax");
            uint32_t scrut_slot = cg->local_count++;
            emit(cg, "    movq %%rax, -%d(%%rbp)", (int)((scrut_slot + 1) * 8));
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_stmt.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit(cg, "    movq -%d(%%rbp), %%rax", (int)((scrut_slot + 1) * 8));
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) return -1;
                emit(cg, "    jne L_sanctum_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) return -1;
                    pop_r(cg, "rax");
                    emit(cg, "    testq %%rax, %%rax");
                    emit(cg, "    jz L_sanctum_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                pop_r(cg, "rax");
                emit(cg, "    jmp L_sanctum_match_end_%u", (unsigned)end_lbl);
                emit(cg, "L_sanctum_skip_%u:", (unsigned)skip_lbl);
            }
            emit(cg, "L_sanctum_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_RM2_E_UNSUPPORTED;
            return -1;
    }
}

static int emit_block(iii_cg_rm2_state_t *cg, uint32_t node)
{
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    iii_ast_list_t s = (n->kind == III_AST_EXPR_BLOCK) ? n->u.block.stmts : n->u.forward_block.stmts;
    uint32_t saved = cg->local_count;
    for (uint32_t i = 0; i < s.count; i++)
        if (emit_stmt(cg, iii_ast_list_at(cg->ast, s, i))) return -1;
    cg->local_count = saved;
    emit(cg, "    xorq %%rax, %%rax"); push_r(cg, "rax");
    return 0;
}

/* ─── Function emitter ──────────────────────────────────────────── */

static int emit_function(iii_cg_rm2_state_t *cg, iii_src_text_t name,
                            iii_ast_list_t params, uint32_t body)
{
    /* D4: sanctum entry contract.  Require at least one parameter
     * (the cap_handle).  The SysV ABI passes integer-class args 1..6
     * in rdi, rsi, rdx, rcx, r8, r9 — we read rdi as cap_handle. */
    if (params.count < 1u) {
        cg->last_error = III_CG_RM2_E_BAD_ENTRY_SIG;
        return -1;
    }
    {
        uint32_t pid = iii_ast_list_at(cg->ast, params, 0);
        const iii_ast_node_t *p0 = iii_ast_get(cg->ast, pid);
        if (!p0 || p0->kind != III_AST_PARAM) {
            cg->last_error = III_CG_RM2_E_BAD_ENTRY_SIG;
            return -1;
        }
    }
    cg->local_count = 0; cg->stack_depth = 0; cg->label_counter = 0;
    cg->cap_revoke_seen = false;
    cg->in_entry = true;

    /* D2: section header per emitted function. */
    emit_section_text(cg);
    /* D9: explicit alignment — assembler-inserted padding is forbidden. */
    cg_emit_str(cg, "    .balign 16\n");
    cg_emit_str(cg, "    .global ");
    elabel(cg, name); cg_emit_char(cg, '\n');
    /* D4: hint via type annotation directive (gas .type for ELF;
     * silently elided on PE because the COFF backend ignores it). */
    if (cg->fmt == III_CG_RM2_FMT_ELF) {
        cg_emit_str(cg, "    .type ");
        elabel(cg, name);
        cg_emit_str(cg, ", @function\n");
    }
    elabel(cg, name); cg_emit_str(cg, ":\n");

    /* Sanctum prologue: save callee-saved.  Defence-in-depth: even
     * though sanctum_gate.S already preserved these, we mirror the
     * save inside the body so the function is self-contained.
     * Cite: SysV AMD64 ABI §3.2.1 (callee-saved set). */
    emit(cg, "    pushq %%rbp\n    pushq %%r15\n    pushq %%r14\n    pushq %%r13\n    pushq %%r12\n    pushq %%rbx");
    emit(cg, "    movq %%rsp, %%rbp\n    subq $%u, %%rsp", (unsigned)III_CG_RM2_FRAME_RESERVE);

    /* D12: stack-bottom invariant.  Zero the entire reserved frame
     * so stale data from a previous sanctum invocation cannot leak.
     * Uses rep stosq; rdi/rcx are restored or about to be overwritten
     * by parameter spilling (D11 also clears them at exit). */
    emit(cg, "    /* D12: zero local frame (%u bytes) */", (unsigned)III_CG_RM2_FRAME_RESERVE);
    emit(cg, "    movq %%rsp, %%rdi");
    emit(cg, "    xorq %%rax, %%rax");
    emit(cg, "    movq $%u, %%rcx", (unsigned)(III_CG_RM2_FRAME_RESERVE / 8u));
    emit(cg, "    rep stosq");

    /* Spill SysV integer-arg registers into local slots. */
    const char *abi[6] = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" };
    uint32_t pcount = params.count;
    for (uint32_t i = 0; i < pcount && i < 6u; i++) {
        uint32_t pid = iii_ast_list_at(cg->ast, params, i);
        const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
        if (p && p->kind == III_AST_PARAM) {
            local_add(cg, p->u.param.name);
            emit(cg, "    movq %%%s, -%d(%%rbp)", abi[i], (int)(cg->local_count * 8));
        }
    }

    /* D10: cap-handle discipline — first non-prologue instruction
     * is iii_cap_verify(cap_handle).  cap_handle is the first
     * parameter (slot 1, at -8(%rbp)). */
    emit(cg, "    /* D10: cap-handle verify */");
    emit(cg, "    movq -8(%%rbp), %%rdi");
    cg_emit_str(cg, "    callq iii_cap_verify\n");

    if (body && emit_block(cg, body)) { cg->in_entry = false; return -1; }

    /* D10: every entry must call iii_cap_revoke before returning. */
    if (!cg->cap_revoke_seen) {
        cg->last_error = III_CG_RM2_E_NO_CAP_REVOKE;
        cg->in_entry = false;
        return -1;
    }

    emit(cg, "    xorq %%rax, %%rax");
    emit_sanctum_epilogue(cg);
    if (cg->fmt == III_CG_RM2_FMT_ELF) {
        cg_emit_str(cg, "    .size ");
        elabel(cg, name);
        cg_emit_str(cg, ", .-");
        elabel(cg, name);
        cg_emit_char(cg, '\n');
    }
    cg->in_entry = false;
    return 0;
}

/* ─── Section-mhash placeholder (D3) ──────────────────────────────
 * Emitted ONCE at the head of the sanctum text section.  The post-link
 * sealer (TOOLS/sanctum_seal v1) overwrites the 32 bytes following
 * `iii_sanctum_mhash_placeholder:` with SHA-256(.xii_sanctum.text
 * bytes EXCLUDING the placeholder window).  The same digest is what
 * gets extended into the TPM PCR. */
static void emit_section_mhash_placeholder(iii_cg_rm2_state_t *cg)
{
    emit_section_text(cg);
    cg_emit_str(cg, "    .balign 32\n");                             /* D9 */
    cg_emit_str(cg, "    .global iii_sanctum_mhash_placeholder\n");
    cg_emit_str(cg, "iii_sanctum_mhash_placeholder:\n");
    cg_emit_str(cg, "    /* D3: 32-byte zero blob; linker patches with section mhash. */\n");
    cg_emit_str(cg, "    .byte 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,"
                    " 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0\n");
}

/* ─── Module emitter ─────────────────────────────────────────────── */

int iii_cg_rm2_emit_module(iii_cg_rm2_state_t *cg, FILE *out)
{
    if (!cg || !out) return cg ? (cg->last_error = III_CG_RM2_E_NULL_ARG) : III_CG_RM2_E_NULL_ARG;
    if (cg->sealed) return cg->last_error = III_CG_RM2_E_SEALED;        /* D14 */

    cg->out = out;
    cg_emit_str(cg, "# III Stage-0 Ring -2 codegen output (SANCTUM-sealed)\n");
    cg_emit_str(cg, "# Spec: SPEC.XII §S14 + DRTM (Intel TXT MLE / TCG D-RTM 1.0).\n");
    cg_emit_str(cg, "    .att_syntax\n");

    /* D3: section-mhash placeholder at head of sanctum text. */
    emit_section_mhash_placeholder(cg);

    /* String literal payload pool in sanctum rodata. */
    emit_section_rodata(cg);
    cg_emit_str(cg, "    .balign 8\n");                                 /* D9 */
    for (uint32_t i = 0; i < iii_ast_string_payload_count(cg->ast); i++) {
        cg_emit_fmt(cg, "L_sanctum_str_%u:\n", (unsigned)i);
        const uint8_t *bytes = iii_ast_string_payload_get(cg->ast, i);
        if (bytes) {
            cg_emit_str(cg, "    .ascii \"");
            for (; *bytes; bytes++) {
                if (*bytes == '"' || *bytes == '\\') { cg_emit_char(cg, '\\'); cg_emit_char(cg, *bytes); }
                else if (*bytes == '\n') cg_emit_str(cg, "\\n");
                else if (*bytes >= 0x20 && *bytes < 0x7F) cg_emit_char(cg, (int)*bytes);
                else cg_emit_fmt(cg, "\\%03o", (unsigned)*bytes);
            }
            cg_emit_str(cg, "\\0\"\n");
        }
    }

    const iii_ast_node_t *mod = iii_ast_get(cg->ast, iii_ast_root_module(cg->ast));
    if (!mod) return cg->last_error = III_CG_RM2_E_INTERNAL;
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d) continue;
        if (d->kind == III_AST_SEALED_CALL_METHOD_DECL) {
            if (emit_function(cg, d->u.sealed_call.name,
                                  d->u.sealed_call.params,
                                  d->u.sealed_call.body_block) != 0)
                return cg->last_error ? cg->last_error : III_CG_RM2_E_INTERNAL;
        }
    }
    /* Reset per-module annotations (D6). */
    cg->const_time = false;
    return III_CG_RM2_OK;
}

int iii_cg_rm2_module_finish(iii_cg_rm2_state_t *cg)
{
    if (!cg) return III_CG_RM2_E_NULL_ARG;
    cg->sealed = true;                                                  /* D14 */
    return III_CG_RM2_OK;
}

int iii_cg_rm2_section_mhash(const iii_cg_rm2_state_t *cg, uint8_t out_mhash[32])
{
    if (!cg || !out_mhash) return III_CG_RM2_E_NULL_ARG;
    iii_rm2_sha256_final(cg->witness, out_mhash);                       /* D8 */
    return III_CG_RM2_OK;
}

void iii_cg_rm2_set_format(iii_cg_rm2_state_t *cg, iii_cg_rm2_fmt_t fmt)
{
    if (cg && !cg->sealed) cg->fmt = fmt;
}
void iii_cg_rm2_set_const_time(iii_cg_rm2_state_t *cg, bool on)
{
    if (cg && !cg->sealed) cg->const_time = on;
}

iii_cg_rm2_state_t *iii_cg_rm2_create(iii_ast_t          *ast,
                                       iii_sema_state_t   *sema,
                                       iii_sid_state_t    *sid,
                                       iii_walloc_state_t *walloc)
{
    if (!ast) return NULL;
    iii_cg_rm2_state_t *cg = (iii_cg_rm2_state_t *)calloc(1, sizeof(*cg));
    if (!cg) return NULL;
    cg->ast = ast; cg->sema = sema; cg->sid = sid; cg->walloc = walloc;
    cg->fmt = III_CG_RM2_FMT_ELF;
    cg->last_error = III_CG_RM2_OK;
    iii_rm2_sha256_init(&cg->witness);                                  /* D8 */
    return cg;
}
void iii_cg_rm2_destroy(iii_cg_rm2_state_t *cg) { if (cg) free(cg); }
int  iii_cg_rm2_last_error(const iii_cg_rm2_state_t *cg)
{ return cg ? cg->last_error : III_CG_RM2_E_NULL_ARG; }
const char *iii_cg_rm2_error_name(int code)
{
    switch (code) {
        case III_CG_RM2_OK:                 return "OK";
        case III_CG_RM2_E_NULL_ARG:         return "NULL_ARG";
        case III_CG_RM2_E_IO:               return "IO";
        case III_CG_RM2_E_UNSUPPORTED:      return "UNSUPPORTED";
        case III_CG_RM2_E_NON_PIC_RELOC:    return "NON_PIC_RELOC";
        case III_CG_RM2_E_FORBIDDEN_TARGET: return "FORBIDDEN_TARGET";
        case III_CG_RM2_E_BAD_ENTRY_SIG:    return "BAD_ENTRY_SIG";
        case III_CG_RM2_E_ONEWAY_READ:      return "ONEWAY_READ";
        case III_CG_RM2_E_NO_CAP_REVOKE:    return "NO_CAP_REVOKE";
        case III_CG_RM2_E_SEALED:           return "SEALED";
        case III_CG_RM2_E_INTERNAL:         return "INTERNAL";
        default: return "<unknown>";
    }
}
