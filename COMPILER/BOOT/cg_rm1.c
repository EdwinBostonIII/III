/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm1.c
 *
 * III Stage-0 Ring -1 (bare-metal hypervisor) codegen.
 *
 * SysV x64 ABI per "System V Application Binary Interface — AMD64
 * Architecture Processor Supplement" §3.2: integer args 1..6 in
 * rdi/rsi/rdx/rcx/r8/r9; no shadow space; callee-saved rbp, rbx,
 * r12-r15.  Identity-mapped paging; no host libc in emitted image.
 * Witness emission writes directly to the per-CPU forward ring
 * pinned at HV bring-up.
 *
 * Stack-machine codegen (same strategy as cg_r3) but with SysV
 * register order, no shadow-space reservation, and a battery of
 * Ring -1-specific deepenings (D1..D14, see cg_rm1.h header).
 *
 * Strict NIH per ADR-021: the *emitted* image links no host libc;
 * the *codegen* itself uses host stdio/stdlib/string only at boot
 * stage (Stage 0).  Stage 1+ replaces this with III itself.
 */
#include "cg_rm1.h"

#include "ast_internal.h"   /* direct AST field access for label/source helpers */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

/* ════════════════════════════════════════════════════════════════════
 *   D9 — NIH SHA-256.  RFC 6234.  Used to checksum the emitted asm
 *   byte stream for codegen reproducibility.  Boot-stage only — the
 *   host build links this; the emitted HV image does not.
 * ════════════════════════════════════════════════════════════════════ */

typedef struct {
    uint32_t h[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    uint32_t buflen;
} iii_sha256_ctx_t;

static const uint32_t III_SHA256_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,
    0x923f82a4u,0xab1c5ed5u,0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,
    0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,0xe49b69c1u,0xefbe4786u,
    0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,
    0x06ca6351u,0x14292967u,0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,
    0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,0xa2bfe8a1u,0xa81a664bu,
    0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,
    0x5b9cca4fu,0x682e6ff3u,0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,
    0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static void iii_sha256_init(iii_sha256_ctx_t *c) {
    c->h[0]=0x6a09e667u; c->h[1]=0xbb67ae85u; c->h[2]=0x3c6ef372u; c->h[3]=0xa54ff53au;
    c->h[4]=0x510e527fu; c->h[5]=0x9b05688cu; c->h[6]=0x1f83d9abu; c->h[7]=0x5be0cd19u;
    c->bitlen = 0; c->buflen = 0;
}

static uint32_t iii_rotr32(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }

static void iii_sha256_compress(iii_sha256_ctx_t *c, const uint8_t *blk) {
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)blk[i*4]<<24)|((uint32_t)blk[i*4+1]<<16)|
               ((uint32_t)blk[i*4+2]<<8)|(uint32_t)blk[i*4+3];
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_rotr32(w[i-15],7)^iii_rotr32(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1 = iii_rotr32(w[i-2],17)^iii_rotr32(w[i-2],19)^(w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_rotr32(e,6)^iii_rotr32(e,11)^iii_rotr32(e,25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + III_SHA256_K[i] + w[i];
        uint32_t S0 = iii_rotr32(a,2)^iii_rotr32(a,13)^iii_rotr32(a,22);
        uint32_t mj = (a & b) ^ (a & cc) ^ (b & cc);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1;
        d = cc; cc = b; b = a; a = t1 + t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g;  c->h[7]+=h;
}

static void iii_sha256_update(iii_sha256_ctx_t *c, const void *data, size_t len) {
    const uint8_t *p = (const uint8_t *)data;
    c->bitlen += (uint64_t)len * 8u;
    while (len > 0) {
        size_t take = 64u - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += (uint32_t)take; p += take; len -= take;
        if (c->buflen == 64u) { iii_sha256_compress(c, c->buf); c->buflen = 0; }
    }
}

static void iii_sha256_final(iii_sha256_ctx_t *c, uint8_t out[32]) {
    c->buf[c->buflen++] = 0x80;
    if (c->buflen > 56u) {
        while (c->buflen < 64u) c->buf[c->buflen++] = 0;
        iii_sha256_compress(c, c->buf); c->buflen = 0;
    }
    while (c->buflen < 56u) c->buf[c->buflen++] = 0;
    for (int i = 7; i >= 0; i--) c->buf[c->buflen++] = (uint8_t)(c->bitlen >> (i * 8));
    iii_sha256_compress(c, c->buf);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(c->h[i] >> 24);
        out[i*4+1] = (uint8_t)(c->h[i] >> 16);
        out[i*4+2] = (uint8_t)(c->h[i] >> 8);
        out[i*4+3] = (uint8_t)(c->h[i]);
    }
}

/* ════════════════════════════════════════════════════════════════════
 *   Codegen state.
 * ════════════════════════════════════════════════════════════════════ */

struct iii_cg_rm1_state {
    iii_ast_t          *ast;
    iii_sema_state_t   *sema;
    iii_sid_state_t    *sid;
    iii_walloc_state_t *walloc;
    FILE               *out;
    uint32_t            local_count;
    uint32_t            stack_depth;
    uint32_t            label_counter;
    struct { iii_src_text_t name; uint32_t slot; } locals[64];
    int                 last_error;

    /* D6 ring-wall: name of the cycle currently being emitted.  Used to
     * decide whether ring0_/ring3_ targets are reachable (only from
     * authorized gateway cycles). */
    iii_src_text_t      cur_cycle_name;

    /* D11 stack-canary state for the current cycle. */
    bool                cur_cycle_canary;
    uint32_t            cur_cycle_canary_slot;

    /* D12 SVM bracket balance counter; must reach 0 at end of module. */
    int32_t             svm_bracket_depth;

    /* D9 SHA-256 over emitted asm byte stream. */
    iii_sha256_ctx_t    asm_sha;
    uint8_t             asm_digest[32];
    bool                asm_digest_valid;
};

/* ════════════════════════════════════════════════════════════════════
 *   Emission primitives.  Every fputs/fputc/fprintf to cg->out goes
 *   through iii_emit_raw() / iii_emit_line() so D9 SHA-256 sees every
 *   byte exactly once.
 * ════════════════════════════════════════════════════════════════════ */

static void iii_emit_raw(iii_cg_rm1_state_t *cg, const void *p, size_t n) {
    if (cg->out && n) fwrite(p, 1, n, cg->out);
    iii_sha256_update(&cg->asm_sha, p, n);
}

static void iii_emit_str(iii_cg_rm1_state_t *cg, const char *s) {
    iii_emit_raw(cg, s, strlen(s));
}

static void iii_emit_chr(iii_cg_rm1_state_t *cg, int ch) {
    uint8_t b = (uint8_t)ch;
    iii_emit_raw(cg, &b, 1);
}

static void emit(iii_cg_rm1_state_t *cg, const char *fmt, ...) {
    /* Buffered formatted line emit.  4 KiB scratch is sufficient for
     * any single asm line we produce.  Determinism: vsnprintf with
     * fixed locale (C locale assumed). */
    char scratch[4096];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(scratch, sizeof scratch, fmt, ap);
    va_end(ap);
    if (n < 0) { cg->last_error = III_CG_RM1_E_IO; return; }
    if ((size_t)n > sizeof scratch - 1u) n = (int)(sizeof scratch - 1u);
    iii_emit_raw(cg, scratch, (size_t)n);
    iii_emit_chr(cg, '\n');
}

static void elabel(iii_cg_rm1_state_t *cg, iii_src_text_t name) {
    iii_emit_str(cg, "L_hv_");
    for (uint32_t i = 0; i < name.length; i++) {
        uint8_t b = cg->ast->source_buf[name.offset + i];
        if ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') iii_emit_chr(cg, (int)b);
        else iii_emit_chr(cg, '_');
    }
}

/* ════════════════════════════════════════════════════════════════════
 *   D6 — Ring-wall.  An authorized gateway cycle is one whose name
 *   begins with vmexit_, hcall_, or vmrun_.  A target whose name
 *   begins with ring0_ or ring3_ is a ring-cross.  Refuse the latter
 *   from non-gateways.
 * ════════════════════════════════════════════════════════════════════ */

static bool name_starts_with(const iii_ast_t *ast, iii_src_text_t n, const char *pfx) {
    size_t plen = strlen(pfx);
    if (n.length < plen) return false;
    return memcmp(ast->source_buf + n.offset, pfx, plen) == 0;
}

static bool is_authorized_gateway(const iii_cg_rm1_state_t *cg) {
    if (cg->cur_cycle_name.length == 0) return false;
    return name_starts_with(cg->ast, cg->cur_cycle_name, "vmexit_") ||
           name_starts_with(cg->ast, cg->cur_cycle_name, "hcall_")  ||
           name_starts_with(cg->ast, cg->cur_cycle_name, "vmrun_");
}

static bool is_ring_cross_target(const iii_ast_t *ast, iii_src_text_t n) {
    return name_starts_with(ast, n, "ring0_") || name_starts_with(ast, n, "ring3_");
}

/* ════════════════════════════════════════════════════════════════════
 *   D1 — SysV x64 ABI alignment assertion.  Caller-side rsp must be
 *   16-byte aligned at the CALL boundary (SysV §3.2.2).  We track an
 *   8-byte slot counter and require it even.
 * ════════════════════════════════════════════════════════════════════ */

static int abi_assert_call_aligned(iii_cg_rm1_state_t *cg) {
    if ((cg->stack_depth & 1u) != 0u) {
        cg->last_error = III_CG_RM1_E_ABI_ALIGN;
        return -1;
    }
    return 0;
}

/* ════════════════════════════════════════════════════════════════════
 *   Locals + push/pop helpers.
 * ════════════════════════════════════════════════════════════════════ */

static int local_slot(iii_cg_rm1_state_t *cg, iii_src_text_t n) {
    for (uint32_t i = 0; i < cg->local_count; i++)
        if (cg->locals[i].name.length == n.length &&
            memcmp(cg->ast->source_buf + cg->locals[i].name.offset,
                   cg->ast->source_buf + n.offset, n.length) == 0)
            return (int)cg->locals[i].slot;
    return -1;
}

static void local_add(iii_cg_rm1_state_t *cg, iii_src_text_t n) {
    if (cg->local_count >= 64u) return;
    cg->locals[cg->local_count].name = n;
    cg->locals[cg->local_count].slot = cg->local_count;
    cg->local_count++;
}

static void push_r(iii_cg_rm1_state_t *cg, const char *r) { emit(cg, "    pushq %%%s", r); cg->stack_depth++; }
static void pop_r (iii_cg_rm1_state_t *cg, const char *r) { emit(cg, "    popq %%%s", r); if (cg->stack_depth) cg->stack_depth--; }

/* ─── Hexad packing ──────────────────────────────────────────────── */

static uint16_t pack_hexad_trits(const iii_ast_trit_t trits[6]) {
    uint16_t v = 0;
    for (int i = 0; i < 6; i++) v = (uint16_t)(v | ((uint16_t)((uint16_t)trits[i] & 0x3u) << (2 * i)));
    return v;
}

static void emit_mhash_data_label(iii_cg_rm1_state_t *cg, uint32_t node_id, const uint8_t mh[32]) {
    emit(cg, "L_hv_mhash_%u:", (unsigned)node_id);
    iii_emit_str(cg, "    .byte ");
    for (int i = 0; i < 32; i++) {
        char buf[8];
        int n = snprintf(buf, sizeof buf, "0x%02x%s", mh[i], (i == 31) ? "" : ", ");
        iii_emit_raw(cg, buf, (size_t)n);
    }
    iii_emit_chr(cg, '\n');
}

static int emit_field_label(iii_cg_rm1_state_t *cg, const iii_ast_node_t *obj,
                            iii_src_text_t field_name) {
    if (!obj || obj->kind != III_AST_EXPR_IDENT) return -1;
    iii_emit_str(cg, "L_hv_");
    for (uint32_t i = 0; i < obj->u.ident.name.length; i++) {
        uint8_t b = cg->ast->source_buf[obj->u.ident.name.offset + i];
        if ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') iii_emit_chr(cg, (int)b);
        else iii_emit_chr(cg, '_');
    }
    iii_emit_str(cg, "__");
    for (uint32_t i = 0; i < field_name.length; i++) {
        uint8_t b = cg->ast->source_buf[field_name.offset + i];
        if ((b>='A'&&b<='Z')||(b>='a'&&b<='z')||(b>='0'&&b<='9')||b=='_') iii_emit_chr(cg, (int)b);
        else iii_emit_chr(cg, '_');
    }
    return 0;
}

/* ════════════════════════════════════════════════════════════════════
 *   D8 — Witness emission helper.  Calls iii_witness_emit_hv with the
 *   cycle's witness ID.  Bare-metal: target writes into the static
 *   ring `__iii_hv_witness_ring`.
 * ════════════════════════════════════════════════════════════════════ */

static void emit_witness_call(iii_cg_rm1_state_t *cg, uint32_t wid, const char *phase) {
    /* Save caller-saved that we use; clobber rdi only, then restore. */
    emit(cg, "    # D8 witness %s wid=0x%x", phase, (unsigned)wid);
    emit(cg, "    pushq %%rax");                 cg->stack_depth++;
    emit(cg, "    pushq %%rdi");                 cg->stack_depth++;
    if ((cg->stack_depth & 1u) != 0u) {
        emit(cg, "    subq $8, %%rsp");          cg->stack_depth++;
    }
    emit(cg, "    movabsq $0x%x, %%rdi", (unsigned)wid);
    if (abi_assert_call_aligned(cg) != 0) return;
    emit(cg, "    callq iii_witness_emit_hv");
    if (((cg->stack_depth - 2u) & 1u) != 0u) {
        emit(cg, "    addq $8, %%rsp");          if (cg->stack_depth) cg->stack_depth--;
    }
    emit(cg, "    popq %%rdi");                  if (cg->stack_depth) cg->stack_depth--;
    emit(cg, "    popq %%rax");                  if (cg->stack_depth) cg->stack_depth--;
}

/* ════════════════════════════════════════════════════════════════════
 *   D3 — VMX/SVM CPUID dispatch stub.
 *     Intel SDM Vol. 2A "CPUID — CPU Identification", leaf 1, ECX bit 5.
 *     AMD APM   Vol. 3 §3.3, CPUID leaf 8000_0001h, ECX bit 2.
 * ════════════════════════════════════════════════════════════════════ */

static void emit_vmx_svm_dispatch(iii_cg_rm1_state_t *cg) {
    emit(cg, "    .text");
    emit(cg, "    .global iii_hv_vmx_svm_dispatch");
    emit(cg, "iii_hv_vmx_svm_dispatch:");
    emit(cg, "    # D3 CPUID(1).ECX[5] = VMX (Intel SDM Vol.2A CPUID)");
    emit(cg, "    movl $1, %%eax");
    emit(cg, "    xorl %%ecx, %%ecx");
    emit(cg, "    cpuid");
    emit(cg, "    btl  $5, %%ecx");
    emit(cg, "    jc   iii_hv_path_vmx");
    emit(cg, "    # D3 CPUID(0x80000001).ECX[2] = SVM (AMD APM Vol.3 §3.3)");
    emit(cg, "    movl $0x80000001, %%eax");
    emit(cg, "    xorl %%ecx, %%ecx");
    emit(cg, "    cpuid");
    emit(cg, "    btl  $2, %%ecx");
    emit(cg, "    jc   iii_hv_path_svm");
    emit(cg, "    # Neither VMX nor SVM available — halt.");
    emit(cg, "    cli");
    emit(cg, "iii_hv_dispatch_halt:");
    emit(cg, "    hlt");
    emit(cg, "    jmp  iii_hv_dispatch_halt");
}

/* ════════════════════════════════════════════════════════════════════
 *   D2 — Bare-metal startup contract.  Entry receives control with
 *   no usable stack.  Set rsp from linker symbol __iii_hv_stack_top
 *   then jump to iii_hv_main.
 * ════════════════════════════════════════════════════════════════════ */

static void emit_bare_metal_entry(iii_cg_rm1_state_t *cg) {
    emit(cg, "    .text");
    emit(cg, "    .global iii_hv_entry");
    emit(cg, "iii_hv_entry:");
    emit(cg, "    # D2 stack-pointer setup; D10 deterministic .align");
    emit(cg, "    .align 16, 0x90");
    emit(cg, "    leaq __iii_hv_stack_top(%%rip), %%rsp");
    emit(cg, "    xorq %%rbp, %%rbp");
    emit(cg, "    cld");
    emit(cg, "    jmp  iii_hv_main");
}

/* ════════════════════════════════════════════════════════════════════
 *   D5 — EPT / NPT identity-mapped page tables for the first 4 GiB,
 *   2 MiB large pages.
 *     Intel SDM Vol. 3 §28.2.2  EPT paging-structure entries.
 *     AMD   APM  Vol. 2 §15.25  Nested paging.
 *
 *   Layout: 1 PML4 (4 KiB) + 1 PDPT (4 KiB) + 4 PD (16 KiB)
 *   PDE bits: P=1 PS=1 W=1 (and R,X for EPT).  We emit both flavours;
 *   the loader chooses which to publish based on D3 dispatch result.
 * ════════════════════════════════════════════════════════════════════ */

static void emit_slat_tables(iii_cg_rm1_state_t *cg) {
    emit(cg, "    .section .rodata.iii_hv_slat,\"a\",@progbits");
    emit(cg, "    .align 4096, 0");

    /* PML4: one entry pointing at PDPT.  EPT bits: bit0=R bit1=W bit2=X bit7 reserved. */
    emit(cg, "iii_hv_slat_pml4:");
    emit(cg, "    .quad iii_hv_slat_pdpt + 0x07");
    emit(cg, "    .fill 511, 8, 0");

    /* PDPT: 4 entries (covering 4 × 1 GiB), each pointing at one PD. */
    emit(cg, "    .align 4096, 0");
    emit(cg, "iii_hv_slat_pdpt:");
    emit(cg, "    .quad iii_hv_slat_pd0 + 0x07");
    emit(cg, "    .quad iii_hv_slat_pd1 + 0x07");
    emit(cg, "    .quad iii_hv_slat_pd2 + 0x07");
    emit(cg, "    .quad iii_hv_slat_pd3 + 0x07");
    emit(cg, "    .fill 508, 8, 0");

    /* 4× PD, each 512 entries × 2 MiB = 1 GiB identity-mapped.
     * EPT large-page bits: R|W|X|MemType(WB=6)|IPAT(0)|PS=1.  Composite
     * low bits: 0x07 (RWX) | (6<<3) (WB) | (1<<7) (PS) = 0xB7.
     * NPT shares the layout but uses x86 paging bits (P|RW|US|PS = 0x83).
     * The loader patches in the AMD variant if D3 selected SVM. */
    for (int g = 0; g < 4; g++) {
        emit(cg, "    .align 4096, 0");
        emit(cg, "iii_hv_slat_pd%d:", g);
        for (int e = 0; e < 512; e++) {
            unsigned long long phys = ((unsigned long long)g << 30) + ((unsigned long long)e << 21);
            emit(cg, "    .quad 0x%llx", phys | 0xB7ull);
        }
    }
}

/* ════════════════════════════════════════════════════════════════════
 *   D7 — VM-exit dispatch table.  Cycles named vmexit_NN_<name> are
 *   indexed by NN into iii_hv_vmexit_table[].
 *     Intel SDM Vol. 3 Appendix C "VMX Basic Exit Reasons" (0..69).
 *     AMD   APM  Vol. 2 §15.7    Intercept exit codes.
 * ════════════════════════════════════════════════════════════════════ */

#define III_HV_VMEXIT_TABLE_ENTRIES 256u

static int parse_vmexit_index(const iii_ast_t *ast, iii_src_text_t n, uint32_t *out) {
    const char *pfx = "vmexit_";
    size_t plen = strlen(pfx);
    if (n.length <= plen) return -1;
    if (memcmp(ast->source_buf + n.offset, pfx, plen) != 0) return -1;
    uint32_t v = 0;
    size_t i = plen;
    bool any = false;
    while (i < n.length) {
        uint8_t b = ast->source_buf[n.offset + i];
        if (b >= '0' && b <= '9') { v = v * 10u + (uint32_t)(b - '0'); any = true; i++; }
        else break;
    }
    if (!any || v >= III_HV_VMEXIT_TABLE_ENTRIES) return -1;
    *out = v;
    return 0;
}

static void emit_vmexit_dispatch_table(iii_cg_rm1_state_t *cg) {
    /* Walk the module, collect vmexit_NN_ cycles, build a table indexed
     * by NN; missing slots get the default trampoline. */
    const iii_ast_node_t *mod = iii_ast_get(cg->ast, cg->ast->root_module);
    if (!mod) return;

    /* Slot -> (name offset, name length).  length==0 means empty slot. */
    iii_src_text_t slots[III_HV_VMEXIT_TABLE_ENTRIES];
    memset(slots, 0, sizeof slots);
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d || d->kind != III_AST_CYCLE_DECL) continue;
        uint32_t idx;
        if (parse_vmexit_index(cg->ast, d->u.cycle_decl.name, &idx) == 0)
            slots[idx] = d->u.cycle_decl.name;
    }

    emit(cg, "    .section .rodata.iii_hv_vmexit_table,\"a\",@progbits");
    emit(cg, "    .align 16, 0");
    emit(cg, "    .global iii_hv_vmexit_table");
    emit(cg, "iii_hv_vmexit_table:");
    for (uint32_t i = 0; i < III_HV_VMEXIT_TABLE_ENTRIES; i++) {
        if (slots[i].length == 0) {
            emit(cg, "    .quad iii_hv_vmexit_default");
        } else {
            iii_emit_str(cg, "    .quad ");
            elabel(cg, slots[i]);
            iii_emit_chr(cg, '\n');
        }
    }
}

/* ════════════════════════════════════════════════════════════════════
 *   D12 — SVM safety bracket.  AMD APM Vol. 3 §15.5.
 *   D13 — VMX safety bracket.  Intel SDM Vol. 3 §26.1.
 *   These are emitted on demand by raw-asm cycles named svm_vmrun /
 *   vmx_vmrun (recognized by name), or via @vmrun_bracket attribute
 *   in a future AST revision.  For now they are exposed to other
 *   units as static-callable helpers in the emitted module.
 * ════════════════════════════════════════════════════════════════════ */

static void emit_svm_vmrun_bracket(iii_cg_rm1_state_t *cg) {
    cg->svm_bracket_depth++;
    emit(cg, "    .text");
    emit(cg, "    .global iii_hv_svm_vmrun_bracket");
    emit(cg, "iii_hv_svm_vmrun_bracket:");
    emit(cg, "    # D12 AMD APM Vol.3 §15.5 — clgi;vmload;vmrun;vmsave;stgi");
    emit(cg, "    # rdi = phys addr of host VMCB save, rsi = phys addr of guest VMCB");
    emit(cg, "    pushq %%rbx");
    emit(cg, "    movq  %%rdi, %%rbx     # host  VMCB phys");
    emit(cg, "    movq  %%rsi, %%rax     # guest VMCB phys");
    emit(cg, "    clgi");
    emit(cg, "    vmload %%rbx           # host save area");
    emit(cg, "    vmrun  %%rax           # enter guest");
    emit(cg, "    vmsave %%rbx           # host save area");
    emit(cg, "    stgi");
    emit(cg, "    popq  %%rbx");
    emit(cg, "    retq");
    cg->svm_bracket_depth--;
}

static void emit_vmx_vmrun_bracket(iii_cg_rm1_state_t *cg) {
    emit(cg, "    .text");
    emit(cg, "    .global iii_hv_vmx_vmrun_bracket");
    emit(cg, "iii_hv_vmx_vmrun_bracket:");
    emit(cg, "    # D13 Intel SDM Vol.3 §26.1 — VMLAUNCH on first entry, VMRESUME after");
    emit(cg, "    # Per-VCPU launched flag at __iii_hv_vcpu_launched (1 byte/VCPU).");
    emit(cg, "    # rdi = VCPU index.");
    emit(cg, "    leaq __iii_hv_vcpu_launched(%%rip), %%rax");
    emit(cg, "    movb (%%rax,%%rdi,1), %%cl");
    emit(cg, "    testb %%cl, %%cl");
    emit(cg, "    jne  iii_hv_vmx_do_resume");
    emit(cg, "    movb $1, (%%rax,%%rdi,1)");
    emit(cg, "    vmlaunch");
    emit(cg, "    jmp  iii_hv_vmx_post");
    emit(cg, "iii_hv_vmx_do_resume:");
    emit(cg, "    vmresume");
    emit(cg, "iii_hv_vmx_post:");
    emit(cg, "    retq");
}

/* ════════════════════════════════════════════════════════════════════
 *   Expression / statement / block emission.  Mirrors the LOGOS
 *   parent (cg_r3 / cg_rm1) with III_* enum names and SysV ABI.
 * ════════════════════════════════════════════════════════════════════ */

static int emit_expr(iii_cg_rm1_state_t *cg, uint32_t node);
static int emit_stmt(iii_cg_rm1_state_t *cg, uint32_t node);
static int emit_block(iii_cg_rm1_state_t *cg, uint32_t node);

static int emit_pattern_compare(iii_cg_rm1_state_t *cg, uint32_t pat_node) {
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
                default: cg->last_error = III_CG_RM1_E_UNSUPPORTED; return -1;
            }
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
            cg->last_error = III_CG_RM1_E_UNSUPPORTED;
            return -1;
    }
}

static void emit_pattern_bind(iii_cg_rm1_state_t *cg, uint32_t pat_node) {
    const iii_ast_node_t *p = iii_ast_get(cg->ast, pat_node);
    if (!p || p->kind != III_AST_PAT_IDENT) return;
    local_add(cg, p->u.pat_ident.name);
    uint32_t slot = cg->local_count - 1u;
    emit(cg, "    movq %%rax, -%d(%%rbp)", (slot + 1) * 8);
}

static int emit_expr(iii_cg_rm1_state_t *cg, uint32_t node) {
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_EXPR_INT: case III_AST_EXPR_HEX: {
            uint64_t v = (n->kind == III_AST_EXPR_INT) ? n->u.int_.value : n->u.hex_.value;
            emit(cg, "    movabsq $0x%llx, %%rax", (unsigned long long)v);
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_BOOL: emit(cg, "    movq $%d, %%rax", n->u.bool_.value?1:0); push_r(cg, "rax"); return 0;
        case III_AST_EXPR_TRIT: emit(cg, "    movq $%d, %%rax", (int)n->u.trit_.trit); push_r(cg, "rax"); return 0;
        case III_AST_EXPR_UNIT: emit(cg, "    xorq %%rax, %%rax"); push_r(cg, "rax"); return 0;
        case III_AST_EXPR_STR: {
            emit(cg, "    leaq L_hv_str_%u(%%rip), %%rax", (unsigned)n->u.str_.string_payload_idx);
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_IDENT: {
            int s = local_slot(cg, n->u.ident.name);
            if (s >= 0) { emit(cg, "    movq -%d(%%rbp), %%rax", (s+1)*8); push_r(cg, "rax"); return 0; }
            iii_emit_str(cg, "    leaq ");
            elabel(cg, n->u.ident.name);
            iii_emit_str(cg, "(%rip), %rax\n");
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
                case III_BIN_EQ:  emit(cg, "    cmpq %%rcx, %%rax\n    sete %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_NEQ: emit(cg, "    cmpq %%rcx, %%rax\n    setne %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_LT:  emit(cg, "    cmpq %%rcx, %%rax\n    setl %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_LE:  emit(cg, "    cmpq %%rcx, %%rax\n    setle %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_GT:  emit(cg, "    cmpq %%rcx, %%rax\n    setg %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_GE:  emit(cg, "    cmpq %%rcx, %%rax\n    setge %%al\n    movzbq %%al, %%rax"); break;
                case III_BIN_LAND: emit(cg, "    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rdx\n    testq %%rcx, %%rcx\n    setne %%al\n    movzbq %%al, %%rax\n    andq %%rdx, %%rax"); break;
                case III_BIN_LOR:  emit(cg, "    orq %%rcx, %%rax\n    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rax"); break;
                default:
                    cg->last_error = III_CG_RM1_E_UNSUPPORTED;
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
            /* SysV: first 6 ints in rdi, rsi, rdx, rcx, r8, r9 (§3.2.3). */
            const char *abi[6] = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" };
            uint32_t reg_args = ac > 6u ? 6u : ac;
            for (uint32_t i = 0; i < reg_args; i++) pop_r(cg, abi[reg_args - 1u - i]);
            uint32_t pad = (cg->stack_depth & 1u) ? 1u : 0u;
            if (pad) { emit(cg, "    subq $8, %%rsp"); cg->stack_depth++; }
            const iii_ast_node_t *callee = iii_ast_get(cg->ast, n->u.call.callee);
            if (callee && callee->kind == III_AST_EXPR_IDENT) {
                /* D6 ring-wall. */
                if (is_ring_cross_target(cg->ast, callee->u.ident.name) &&
                    !is_authorized_gateway(cg)) {
                    cg->last_error = III_CG_RM1_E_RING_WALL;
                    return -1;
                }
                /* D1 SysV alignment assertion at the CALL boundary. */
                if (abi_assert_call_aligned(cg) != 0) return -1;
                iii_emit_str(cg, "    callq ");
                elabel(cg, callee->u.ident.name);
                iii_emit_chr(cg, '\n');
            } else {
                if (emit_expr(cg, n->u.call.callee)) return -1;
                pop_r(cg, "rax");
                if (abi_assert_call_aligned(cg) != 0) return -1;
                emit(cg, "    callq *%%rax");
            }
            if (pad) { emit(cg, "    addq $8, %%rsp"); cg->stack_depth--; }
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_BLOCK: return emit_block(cg, node);
        case III_AST_EXPR_FIELD: {
            const iii_ast_node_t *obj = iii_ast_get(cg->ast, n->u.field.object);
            if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                cg->last_error = III_CG_RM1_E_UNSUPPORTED;
                return -1;
            }
            iii_emit_str(cg, "    leaq ");
            if (emit_field_label(cg, obj, n->u.field.field_name) != 0) {
                cg->last_error = III_CG_RM1_E_UNSUPPORTED;
                return -1;
            }
            iii_emit_str(cg, "(%rip), %rax\n");
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
            iii_emit_str(cg, "    .section .rodata\n");
            emit_mhash_data_label(cg, node, n->u.mhash_.mhash);
            iii_emit_str(cg, "    .text\n");
            emit(cg, "    leaq L_hv_mhash_%u(%%rip), %%rax", (unsigned)node);
            push_r(cg, "rax"); return 0;
        }
        case III_AST_EXPR_RAW_ASM: {
            uint32_t off = n->u.raw_asm.raw_asm_str_idx;
            uint32_t len = n->u.raw_asm.raw_asm_len;
            if (off + len <= cg->ast->source_len) {
                iii_emit_raw(cg, cg->ast->source_buf + off, len);
                iii_emit_chr(cg, '\n');
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
            emit(cg, "    movq %%rax, -%d(%%rbp)", (scrut_slot + 1) * 8);
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_expr.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit(cg, "    movq -%d(%%rbp), %%rax", (scrut_slot + 1) * 8);
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) return -1;
                emit(cg, "    jne L_hv_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) return -1;
                    pop_r(cg, "rax");
                    emit(cg, "    testq %%rax, %%rax");
                    emit(cg, "    jz L_hv_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                emit(cg, "    jmp L_hv_match_end_%u", (unsigned)end_lbl);
                emit(cg, "L_hv_skip_%u:", (unsigned)skip_lbl);
            }
            emit(cg, "    movq $0, %%rax");
            push_r(cg, "rax");
            emit(cg, "L_hv_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_RM1_E_UNSUPPORTED;
            return -1;
    }
}

static int emit_stmt(iii_cg_rm1_state_t *cg, uint32_t node) {
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_STMT_LET:
            if (emit_expr(cg, n->u.let_.value_expr)) return -1;
            pop_r(cg, "rax"); local_add(cg, n->u.let_.name);
            emit(cg, "    movq %%rax, -%d(%%rbp)", cg->local_count * 8);
            return 0;
        case III_AST_STMT_EXPR:
            if (emit_expr(cg, n->u.expr_stmt.expr)) return -1;
            pop_r(cg, "rax"); return 0;
        case III_AST_STMT_RETURN:
            if (n->u.return_.value_expr) {
                if (emit_expr(cg, n->u.return_.value_expr)) return -1;
                pop_r(cg, "rax");
            } else emit(cg, "    xorq %%rax, %%rax");
            /* D11 canary check before epilogue. */
            if (cg->cur_cycle_canary) {
                emit(cg, "    # D11 canary check");
                emit(cg, "    movq -%d(%%rbp), %%rcx", (cg->cur_cycle_canary_slot + 1) * 8);
                emit(cg, "    movq __iii_hv_canary_seed(%%rip), %%rdx");
                emit(cg, "    cmpq %%rdx, %%rcx");
                emit(cg, "    jne  __iii_hv_canary_fail");
            }
            emit(cg, "    movq %%rbp, %%rsp\n    popq %%rbp\n    retq");
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
                    cg->last_error = III_CG_RM1_E_UNSUPPORTED;
                    return -1;
                }
                if (emit_expr(cg, n->u.assign.value_expr)) return -1;
                pop_r(cg, "rax");
                iii_emit_str(cg, "    movq %rax, ");
                if (emit_field_label(cg, obj, lv->u.field.field_name) != 0) {
                    cg->last_error = III_CG_RM1_E_UNSUPPORTED;
                    return -1;
                }
                iii_emit_str(cg, "(%rip)\n");
                return 0;
            }
            cg->last_error = III_CG_RM1_E_UNSUPPORTED;
            return -1;
        }
        case III_AST_STMT_FOR: {
            uint32_t lbl_top = cg->label_counter++;
            uint32_t lbl_end = cg->label_counter++;
            if (emit_expr(cg, n->u.for_.iter_expr) != 0) return -1;
            pop_r(cg, "rax");
            uint32_t count_slot = cg->local_count++;
            emit(cg, "    movq %%rax, -%d(%%rbp)", (count_slot + 1) * 8);
            local_add(cg, n->u.for_.var);
            uint32_t var_slot = cg->local_count - 1u;
            emit(cg, "    movq $0, -%d(%%rbp)", (var_slot + 1) * 8);
            emit(cg, "L_hv_for_top_%u:", (unsigned)lbl_top);
            emit(cg, "    movq -%d(%%rbp), %%rax", (var_slot + 1) * 8);
            emit(cg, "    movq -%d(%%rbp), %%rcx", (count_slot + 1) * 8);
            emit(cg, "    cmpq %%rcx, %%rax");
            emit(cg, "    jge L_hv_for_end_%u", (unsigned)lbl_end);
            if (n->u.for_.where_expr != 0) {
                if (emit_expr(cg, n->u.for_.where_expr) != 0) return -1;
                pop_r(cg, "rax");
                emit(cg, "    testq %%rax, %%rax");
                emit(cg, "    jz L_hv_for_continue_%u", (unsigned)lbl_top);
            }
            if (emit_block(cg, n->u.for_.body_block) != 0) return -1;
            pop_r(cg, "rax");
            if (n->u.for_.where_expr != 0) emit(cg, "L_hv_for_continue_%u:", (unsigned)lbl_top);
            emit(cg, "    movq -%d(%%rbp), %%rax", (var_slot + 1) * 8);
            emit(cg, "    addq $1, %%rax");
            emit(cg, "    movq %%rax, -%d(%%rbp)", (var_slot + 1) * 8);
            emit(cg, "    jmp L_hv_for_top_%u", (unsigned)lbl_top);
            emit(cg, "L_hv_for_end_%u:", (unsigned)lbl_end);
            return 0;
        }
        case III_AST_STMT_WAVEFRONT:
            for (uint32_t i = 0; i < n->u.wavefront.nodes.count; i++)
                if (emit_stmt(cg, iii_ast_list_at(cg->ast, n->u.wavefront.nodes, i)) != 0) return -1;
            return 0;
        case III_AST_STMT_SANCTUM_ENTER:
            /* sanctum_enter is R-2 only; reject at R-1. */
            cg->last_error = III_CG_RM1_E_UNSUPPORTED;
            return -1;
        case III_AST_STMT_METAL: {
            uint32_t off = n->u.metal.raw_asm_str_idx;
            uint32_t len = n->u.metal.raw_asm_len;
            if (off + len <= cg->ast->source_len) {
                iii_emit_raw(cg, cg->ast->source_buf + off, len);
                iii_emit_chr(cg, '\n');
            }
            return 0;
        }
        case III_AST_STMT_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_stmt.arms.count;
            if (emit_expr(cg, n->u.match_stmt.scrutinee) != 0) return -1;
            pop_r(cg, "rax");
            uint32_t scrut_slot = cg->local_count++;
            emit(cg, "    movq %%rax, -%d(%%rbp)", (scrut_slot + 1) * 8);
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_stmt.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit(cg, "    movq -%d(%%rbp), %%rax", (scrut_slot + 1) * 8);
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) return -1;
                emit(cg, "    jne L_hv_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) return -1;
                    pop_r(cg, "rax");
                    emit(cg, "    testq %%rax, %%rax");
                    emit(cg, "    jz L_hv_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                pop_r(cg, "rax");
                emit(cg, "    jmp L_hv_match_end_%u", (unsigned)end_lbl);
                emit(cg, "L_hv_skip_%u:", (unsigned)skip_lbl);
            }
            emit(cg, "L_hv_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_RM1_E_UNSUPPORTED;
            return -1;
    }
}

static int emit_block(iii_cg_rm1_state_t *cg, uint32_t node) {
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

/* ════════════════════════════════════════════════════════════════════
 *   Function / cycle prologue + epilogue.  SysV §3.2.2 stack frame.
 * ════════════════════════════════════════════════════════════════════ */

static int emit_function(iii_cg_rm1_state_t *cg, iii_src_text_t name,
                         iii_ast_list_t params, uint32_t body, uint32_t witness_id) {
    cg->local_count = 0; cg->stack_depth = 0; cg->label_counter = 0;
    cg->cur_cycle_name = name;
    /* D11 canary detection by name convention. */
    cg->cur_cycle_canary = name_starts_with(cg->ast, name, "canary_");
    cg->cur_cycle_canary_slot = 0;

    iii_emit_str(cg, "    .text\n    .global ");
    elabel(cg, name); iii_emit_chr(cg, '\n');
    elabel(cg, name); iii_emit_str(cg, ":\n");
    /* D10 deterministic alignment: pad with NOP (0x90) to 16 bytes. */
    emit(cg, "    .align 16, 0x90");
    emit(cg, "    pushq %%rbp\n    movq %%rsp, %%rbp\n    subq $1024, %%rsp");
    /* SysV §3.2.3 — first 6 ints in rdi,rsi,rdx,rcx,r8,r9. */
    const char *abi[6] = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" };
    uint32_t pcount = params.count;
    for (uint32_t i = 0; i < pcount && i < 6u; i++) {
        uint32_t pid = iii_ast_list_at(cg->ast, params, i);
        const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
        if (p && p->kind == III_AST_PARAM) {
            local_add(cg, p->u.param.name);
            emit(cg, "    movq %%%s, -%d(%%rbp)", abi[i], cg->local_count * 8);
        }
    }
    /* D11 install canary into highest local slot. */
    if (cg->cur_cycle_canary) {
        cg->cur_cycle_canary_slot = cg->local_count++;
        emit(cg, "    # D11 canary install");
        emit(cg, "    movq __iii_hv_canary_seed(%%rip), %%rax");
        emit(cg, "    movq %%rax, -%d(%%rbp)", (cg->cur_cycle_canary_slot + 1) * 8);
    }
    /* D8 witness entry. */
    if (witness_id) emit_witness_call(cg, witness_id, "entry");

    if (body && emit_block(cg, body)) return -1;

    /* D8 witness exit. */
    if (witness_id) emit_witness_call(cg, witness_id, "exit");
    /* D11 canary check at fall-through epilogue. */
    if (cg->cur_cycle_canary) {
        emit(cg, "    # D11 canary check (fall-through)");
        emit(cg, "    movq -%d(%%rbp), %%rcx", (cg->cur_cycle_canary_slot + 1) * 8);
        emit(cg, "    movq __iii_hv_canary_seed(%%rip), %%rdx");
        emit(cg, "    cmpq %%rdx, %%rcx");
        emit(cg, "    jne  __iii_hv_canary_fail");
    }
    emit(cg, "    xorq %%rax, %%rax\n    movq %%rbp, %%rsp\n    popq %%rbp\n    retq");
    cg->cur_cycle_name = (iii_src_text_t){0,0};
    cg->cur_cycle_canary = false;
    return 0;
}

/* ════════════════════════════════════════════════════════════════════
 *   Module-level emit.  Order:
 *     1. Banner + att_syntax
 *     2. String pool (.rodata)
 *     3. D2 bare-metal entry thunk
 *     4. D3 VMX/SVM CPUID dispatch stub
 *     5. D12/D13 VMRUN bracket helpers
 *     6. AST cycles + functions
 *     7. D7 vmexit dispatch table
 *     8. D5 SLAT identity-map tables
 *     9. D8 BSS witness ring + D2 stack BSS + D11 canary seed BSS
 *    10. D9 SHA-256 digest comment trailer
 * ════════════════════════════════════════════════════════════════════ */

int iii_cg_rm1_emit_module(iii_cg_rm1_state_t *cg, FILE *out) {
    if (!cg || !out) return III_CG_RM1_E_NULL_ARG;
    cg->out = out;
    cg->stack_depth = 0;
    cg->svm_bracket_depth = 0;
    cg->asm_digest_valid = false;
    iii_sha256_init(&cg->asm_sha);

    iii_emit_str(cg, "# III Stage-0 Ring -1 codegen output (iiis-0 freestanding HV)\n");
    iii_emit_str(cg, "# SysV AMD64 ABI; bare-metal; no host CRT.\n");
    iii_emit_str(cg, "    .att_syntax\n");

    /* String literal payload pool. */
    iii_emit_str(cg, "    .section .rodata\n");
    for (uint32_t i = 0; i < cg->ast->string_payload_count; i++) {
        emit(cg, "L_hv_str_%u:", (unsigned)i);
        const uint8_t *bytes = cg->ast->string_payloads[i];
        if (bytes) {
            iii_emit_str(cg, "    .ascii \"");
            for (; *bytes; bytes++) {
                if (*bytes == '"' || *bytes == '\\') { iii_emit_chr(cg, '\\'); iii_emit_chr(cg, (int)*bytes); }
                else if (*bytes == '\n') iii_emit_str(cg, "\\n");
                else if (*bytes >= 0x20 && *bytes < 0x7F) iii_emit_chr(cg, (int)*bytes);
                else { char tmp[8]; int n = snprintf(tmp, sizeof tmp, "\\%03o", (unsigned)*bytes); iii_emit_raw(cg, tmp, (size_t)n); }
            }
            iii_emit_str(cg, "\\0\"\n");
        }
    }

    emit_bare_metal_entry(cg);
    emit_vmx_svm_dispatch(cg);
    emit_svm_vmrun_bracket(cg);
    emit_vmx_vmrun_bracket(cg);

    const iii_ast_node_t *mod = iii_ast_get(cg->ast, cg->ast->root_module);
    if (!mod) return III_CG_RM1_E_INTERNAL;

    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d) continue;
        switch (d->kind) {
            case III_AST_FN_DECL:
                if (emit_function(cg, d->u.fn_decl.name, d->u.fn_decl.params,
                                  d->u.fn_decl.body_block, 0)) return III_CG_RM1_E_INTERNAL;
                break;
            case III_AST_CYCLE_DECL: {
                /* D8 witness id derivation: walloc supplies it; if walloc is
                 * absent (Stage-0 unit tests) we synthesize a deterministic
                 * id from the cycle index + 1 so the witness ring slot is
                 * still uniquely addressable. */
                uint32_t wid = (uint32_t)(0xC1C00000u | (i + 1u));
                if (emit_function(cg, d->u.cycle_decl.name, d->u.cycle_decl.params,
                                  d->u.cycle_decl.forward_block, wid)) return III_CG_RM1_E_INTERNAL;
                break;
            }
            default: break;
        }
    }

    emit_vmexit_dispatch_table(cg);
    emit_slat_tables(cg);

    /* D2 BSS: 16 KiB stack ending at __iii_hv_stack_top.
     * D8 BSS: witness ring buffer (4096 × 8 bytes = 32 KiB).
     * D11 BSS: canary seed quadword + canary fail trampoline.
     * D13 BSS: per-VCPU launched flag (256 VCPUs). */
    iii_emit_str(cg, "    .section .bss.iii_hv,\"aw\",@nobits\n");
    emit(cg, "    .align 4096, 0");
    emit(cg, "    .global __iii_hv_stack_bottom");
    emit(cg, "__iii_hv_stack_bottom:");
    emit(cg, "    .skip 16384");
    emit(cg, "    .global __iii_hv_stack_top");
    emit(cg, "__iii_hv_stack_top:");
    emit(cg, "    .align 64, 0");
    emit(cg, "    .global __iii_hv_witness_ring");
    emit(cg, "__iii_hv_witness_ring:");
    emit(cg, "    .skip 32768");
    emit(cg, "    .global __iii_hv_witness_ring_end");
    emit(cg, "__iii_hv_witness_ring_end:");
    emit(cg, "    .align 64, 0");
    emit(cg, "    .global __iii_hv_vcpu_launched");
    emit(cg, "__iii_hv_vcpu_launched:");
    emit(cg, "    .skip 256");

    iii_emit_str(cg, "    .section .data.iii_hv,\"aw\",@progbits\n");
    emit(cg, "    .align 8, 0");
    emit(cg, "    .global __iii_hv_canary_seed");
    emit(cg, "__iii_hv_canary_seed:");
    /* Deterministic seed (D10).  The runtime's bring-up code may overwrite
     * with a per-boot RDRAND value before any canary'd cycle runs. */
    emit(cg, "    .quad 0x3141592653589793");

    /* D11 canary fail trampoline — halt forever. */
    iii_emit_str(cg, "    .text\n");
    emit(cg, "    .global __iii_hv_canary_fail");
    emit(cg, "__iii_hv_canary_fail:");
    emit(cg, "    cli");
    emit(cg, "1:  hlt");
    emit(cg, "    jmp 1b");

    /* D7 default vmexit handler (halts; populated tables override). */
    emit(cg, "    .global iii_hv_vmexit_default");
    emit(cg, "iii_hv_vmexit_default:");
    emit(cg, "    cli");
    emit(cg, "1:  hlt");
    emit(cg, "    jmp 1b");

    /* D12 bracket balance check. */
    if (cg->svm_bracket_depth != 0) {
        cg->last_error = III_CG_RM1_E_BRACKET;
        return III_CG_RM1_E_BRACKET;
    }

    /* D9 finalize SHA-256 — but DON'T let the trailer line itself feed
     * the digest (would be a chicken-and-egg).  Snapshot first, then
     * write the trailer with raw fwrite (bypassing the digest update). */
    iii_sha256_ctx_t snapshot = cg->asm_sha;
    iii_sha256_final(&snapshot, cg->asm_digest);
    cg->asm_digest_valid = true;

    char trailer[128];
    int tn = snprintf(trailer, sizeof trailer, "# III_CG_RM1_ASM_SHA256: ");
    if (cg->out && tn > 0) fwrite(trailer, 1, (size_t)tn, cg->out);
    for (int i = 0; i < 32; i++) {
        char hx[3]; snprintf(hx, sizeof hx, "%02x", cg->asm_digest[i]);
        if (cg->out) fwrite(hx, 1, 2, cg->out);
    }
    if (cg->out) fputc('\n', cg->out);

    return III_CG_RM1_OK;
}

/* ════════════════════════════════════════════════════════════════════
 *   Lifecycle + accessors.
 * ════════════════════════════════════════════════════════════════════ */

iii_cg_rm1_state_t *iii_cg_rm1_create(iii_ast_t *ast, iii_sema_state_t *sema,
                                       iii_sid_state_t *sid, iii_walloc_state_t *walloc) {
    if (!ast) return NULL;
    iii_cg_rm1_state_t *cg = (iii_cg_rm1_state_t *)calloc(1, sizeof(*cg));
    if (!cg) return NULL;
    cg->ast = ast; cg->sema = sema; cg->sid = sid; cg->walloc = walloc;
    cg->last_error = III_CG_RM1_OK;
    cg->asm_digest_valid = false;
    cg->svm_bracket_depth = 0;
    return cg;
}

void iii_cg_rm1_destroy(iii_cg_rm1_state_t *cg) { if (cg) free(cg); }

int  iii_cg_rm1_last_error(const iii_cg_rm1_state_t *cg) {
    return cg ? cg->last_error : III_CG_RM1_E_NULL_ARG;
}

const char *iii_cg_rm1_error_name(int code) {
    switch (code) {
        case III_CG_RM1_OK:           return "OK";
        case III_CG_RM1_E_NULL_ARG:   return "NULL_ARG";
        case III_CG_RM1_E_IO:         return "IO";
        case III_CG_RM1_E_UNSUPPORTED:return "UNSUPPORTED";
        case III_CG_RM1_E_ABI_ALIGN:  return "ABI_ALIGN";
        case III_CG_RM1_E_RING_WALL:  return "RING_WALL";
        case III_CG_RM1_E_BRACKET:    return "BRACKET";
        default: return "<unknown>";
    }
}

const uint8_t *iii_cg_rm1_asm_sha256(const iii_cg_rm1_state_t *cg) {
    if (!cg || !cg->asm_digest_valid) return NULL;
    return cg->asm_digest;
}
