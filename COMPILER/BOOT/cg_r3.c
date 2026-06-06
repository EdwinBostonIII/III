/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_r3.c
 *
 * III Stage-0 Ring 3 Codegen — implementation.
 *
 * Stack-machine codegen for x86_64 / Microsoft x64 ABI / Windows PE.
 *
 * Calling convention (Microsoft x64, summary, MS x64 ABI §6):
 *   - Integer arg 1..4: rcx, rdx, r8, r9.        (§6.1.4)
 *   - Integer args 5+: stack at [rsp+0x20], [rsp+0x28], etc.
 *   - 32-byte shadow space reserved by caller (rsp - 0x20).  (§6.4.4)
 *   - Stack must be 16-byte aligned at the call site (so rsp ≡ 8
 *     (mod 16) immediately after a call returns).               (§6.4)
 *   - Return value in rax (integer) or xmm0 (float).
 *   - Callee-saved (non-volatile): rbx, rbp, rdi, rsi, r12-r15,
 *     xmm6-xmm15.                                               (§6.1)
 *   - Volatile (caller-saved): rax, rcx, rdx, r8, r9, r10, r11,
 *     xmm0-xmm5.                                                (§6.1)
 *
 * Strict NIH (ADR-021): hand-emitted gas-syntax mnemonics; no asmjit,
 * no LLVM, no libgccjit.  SHA-256 (witness) is implemented inline.
 */

#include "cg_r3.h"

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
 *
 * III's ast.h treats `iii_ast_t` as opaque and exposes accessors.
 * The string-payload table is not yet wrapped; until ast.h grows
 * iii_ast_string_payload_count() / iii_ast_string_payload_get() the
 * codegen forward-declares the expected signatures here.  When ast.h
 * adds these, this block becomes a no-op redeclaration. */
extern uint32_t       iii_ast_string_payload_count(const iii_ast_t *ast);
extern const uint8_t *iii_ast_string_payload_get(const iii_ast_t *ast, uint32_t idx);

#define III_CG_R3_LOCAL_RESERVE   1024u   /* Stage-0 fixed frame size; 16-aligned */
#define III_CG_R3_SHADOW_BYTES    32u     /* MS x64 ABI §6.4.4 */
#define III_CG_R3_MAX_LABELS      4096u   /* per-function label-uniqueness set */

/* ─── D5: streaming SHA-256 (NIH, RFC 6234) ───────────────────────── */

typedef struct {
    uint32_t state[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    uint32_t buflen;
} iii_sha256_t;

static const uint32_t III_SHA256_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static uint32_t iii_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32u - n)); }

static void iii_sha256_init(iii_sha256_t *s)
{
    s->state[0]=0x6a09e667u; s->state[1]=0xbb67ae85u; s->state[2]=0x3c6ef372u; s->state[3]=0xa54ff53au;
    s->state[4]=0x510e527fu; s->state[5]=0x9b05688cu; s->state[6]=0x1f83d9abu; s->state[7]=0x5be0cd19u;
    s->bitlen = 0; s->buflen = 0;
}

static void iii_sha256_compress(iii_sha256_t *s, const uint8_t blk[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)blk[i*4]<<24) | ((uint32_t)blk[i*4+1]<<16) |
               ((uint32_t)blk[i*4+2]<<8) | (uint32_t)blk[i*4+3];
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_rotr(w[i-15],7) ^ iii_rotr(w[i-15],18) ^ (w[i-15]>>3);
        uint32_t s1 = iii_rotr(w[i-2],17) ^ iii_rotr(w[i-2],19)  ^ (w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=s->state[0],b=s->state[1],c=s->state[2],d=s->state[3];
    uint32_t e=s->state[4],f=s->state[5],g=s->state[6],h=s->state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_rotr(e,6) ^ iii_rotr(e,11) ^ iii_rotr(e,25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + III_SHA256_K[i] + w[i];
        uint32_t S0 = iii_rotr(a,2) ^ iii_rotr(a,13) ^ iii_rotr(a,22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    s->state[0]+=a; s->state[1]+=b; s->state[2]+=c; s->state[3]+=d;
    s->state[4]+=e; s->state[5]+=f; s->state[6]+=g; s->state[7]+=h;
}

static void iii_sha256_update(iii_sha256_t *s, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    s->bitlen += (uint64_t)len * 8u;
    while (len > 0) {
        uint32_t take = 64u - s->buflen;
        if (take > len) take = (uint32_t)len;
        memcpy(s->buf + s->buflen, p, take);
        s->buflen += take; p += take; len -= take;
        if (s->buflen == 64u) { iii_sha256_compress(s, s->buf); s->buflen = 0; }
    }
}

static void iii_sha256_final(iii_sha256_t *s, uint8_t out[32])
{
    uint64_t bl = s->bitlen;
    uint8_t pad = 0x80u;
    iii_sha256_update(s, &pad, 1);
    uint8_t zero = 0;
    while (s->buflen != 56u) iii_sha256_update(s, &zero, 1);
    uint8_t lenbe[8];
    for (int i = 0; i < 8; i++) lenbe[i] = (uint8_t)(bl >> (56 - 8*i));
    iii_sha256_update(s, lenbe, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(s->state[i] >> 24);
        out[i*4+1] = (uint8_t)(s->state[i] >> 16);
        out[i*4+2] = (uint8_t)(s->state[i] >> 8);
        out[i*4+3] = (uint8_t)(s->state[i]);
    }
}

/* ─── State ───────────────────────────────────────────────────────── */

struct iii_cg_r3_state {
    iii_ast_t          *ast;
    iii_sema_state_t   *sema;
    iii_sid_state_t    *sid;
    iii_walloc_state_t *walloc;

    FILE                 *out;

    /* D5: witness sponge over every emitted byte. */
    iii_sha256_t          witness;

    /* D14: optional expected witness. */
    bool                  has_expected_witness;
    uint8_t               expected_witness[32];

    /* Per-function context. */
    uint32_t              cur_decl_node;
    bool                  cur_is_cycle;          /* D8: cycle vs plain fn */
    bool                  cur_export;            /* @export: emit unmangled symbol */
    uint32_t              local_count;           /* parameters + lets */
    uint32_t              stack_depth;           /* expression-stack depth in 8-byte slots */
    uint32_t              max_stack_depth;       /* peak — sizes the prologue's reserve */
    uint32_t              label_counter;         /* unique label per function */

    /* D7: per-function defining-label set; rejects duplicates. */
    uint32_t              defined_labels[III_CG_R3_MAX_LABELS];
    uint32_t              defined_label_count;

    /* iiis-2 — loop-target stack.  Each STMT_LOOP push (continue_lbl,
     * break_lbl); STMT_BREAK/CONTINUE consult the top.  Max nesting
     * depth is small (16); over-nested loops fail codegen rather than
     * silently truncating.  Plain (compile-error) — not a runtime trap. */
    struct {
        uint32_t continue_lbl;
        uint32_t break_lbl;
    } loop_stack[16];
    uint32_t loop_depth;

    /* Local name → slot index table (slot 0 = first parameter, deepest). */
    struct {
        iii_src_text_t name;
        uint32_t       slot;
    } locals[64];

    /* Phase C.6 multi-statement narrowing: per-local static-fp map.
     *
     * When a `let fp = resolve(set, intent, ctx)` is recognised as
     * statically resolvable to a known dispatch fn (via the PE
     * classifier), we record (slot_idx → fn_name) here. A NULL entry
     * means the slot is NOT statically resolved.
     *
     * Subsequent EXPR_CALL emissions whose callee is an EXPR_IDENT
     * bound to a slot in this map MAY be lowered to a 5-byte direct
     * `callq <fn_name>` (E8 rel32), eliding the indirect dispatch
     * through the function-pointer.
     *
     * Hard cap of 128 slots tracked: lets past the cap fall back to
     * normal indirect-call codegen (no PE narrowing). The map is
     * reset in emit_function() at the start of each function's body.
     *
     * Mandate 7 (Win-Win): static lookup, no thresholds, no counters.
     * Mandate 9 (Anti-Bloat): 128 ptrs × 8 bytes = 1 KiB per cg state.
     */
    const char           *pe_static_fp[128];

    /* D11: error recovery. */
    int                   last_error;
    uint32_t              error_count;
};

/* ─── Output helpers (every byte tees into the witness sponge) ────── */

static void cg_write_bytes(iii_cg_r3_state_t *cg, const void *buf, size_t n)
{
    if (cg->out && n) fwrite(buf, 1, n, cg->out);
    iii_sha256_update(&cg->witness, buf, n);
}

static void cg_write_str(iii_cg_r3_state_t *cg, const char *s)
{
    if (!s) return;
    cg_write_bytes(cg, s, strlen(s));
}

static void cg_write_char(iii_cg_r3_state_t *cg, int c)
{
    uint8_t b = (uint8_t)c;
    cg_write_bytes(cg, &b, 1);
}

static void cg_writef(iii_cg_r3_state_t *cg, const char *fmt, ...)
{
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    if (n < 0) return;
    if ((size_t)n >= sizeof buf) n = (int)sizeof buf - 1;
    cg_write_bytes(cg, buf, (size_t)n);
}

static void emit_line(iii_cg_r3_state_t *cg, const char *fmt, ...)
{
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    if (n < 0) return;
    if ((size_t)n >= sizeof buf) n = (int)sizeof buf - 1;
    cg_write_bytes(cg, buf, (size_t)n);
    cg_write_char(cg, '\n');
}

/* ─── D3: register volatility (MS x64 ABI §6.1) ───────────────────── */

bool iii_cg_r3_is_volatile(const char *reg)
{
    if (!reg) return false;
    /* Volatile (caller-saved) integer + xmm registers. */
    static const char *vol[] = {
        "rax","rcx","rdx","r8","r9","r10","r11",
        "eax","ecx","edx","r8d","r9d","r10d","r11d",
        "ax","cx","dx","r8w","r9w","r10w","r11w",
        "al","cl","dl","r8b","r9b","r10b","r11b",
        "xmm0","xmm1","xmm2","xmm3","xmm4","xmm5",
        NULL
    };
    for (int i = 0; vol[i]; i++) if (strcmp(reg, vol[i]) == 0) return true;
    return false;
}

/* ─── D6: opcode-info table ───────────────────────────────────────── */

typedef enum {
    III_OPF_NONE        = 0,
    III_OPF_FLAGS       = 1u << 0,   /* writes EFLAGS */
    III_OPF_BRANCH      = 1u << 1,   /* control transfer */
    III_OPF_MEM         = 1u << 2,   /* may touch memory */
    III_OPF_CALL        = 1u << 3    /* CALL / RET */
} iii_op_flags_t;

typedef struct {
    const char *mnemonic;
    uint32_t    flags;
} iii_op_info_t;

static const iii_op_info_t III_OP_TABLE[] = {
    { "movq",   III_OPF_MEM },
    { "movabsq",III_OPF_NONE },
    { "movzbq", III_OPF_NONE },
    { "leaq",   III_OPF_NONE },
    { "pushq",  III_OPF_MEM },
    { "popq",   III_OPF_MEM },
    { "addq",   III_OPF_FLAGS },
    { "subq",   III_OPF_FLAGS },
    { "imulq",  III_OPF_FLAGS },
    { "idivq",  III_OPF_FLAGS },
    { "andq",   III_OPF_FLAGS },
    { "orq",    III_OPF_FLAGS },
    { "xorq",   III_OPF_FLAGS },
    { "notq",   III_OPF_NONE },
    { "negq",   III_OPF_FLAGS },
    { "shlq",   III_OPF_FLAGS },
    { "shrq",   III_OPF_FLAGS },
    { "cqto",   III_OPF_NONE },
    { "cmpq",   III_OPF_FLAGS },
    { "testq",  III_OPF_FLAGS },
    { "sete",   III_OPF_NONE },
    { "setne",  III_OPF_NONE },
    { "setl",   III_OPF_NONE },
    { "setle",  III_OPF_NONE },
    { "setg",   III_OPF_NONE },
    { "setge",  III_OPF_NONE },
    { "jmp",    III_OPF_BRANCH },
    { "je",     III_OPF_BRANCH },
    { "jne",    III_OPF_BRANCH },
    { "jz",     III_OPF_BRANCH },
    { "jnz",    III_OPF_BRANCH },
    { "jl",     III_OPF_BRANCH },
    { "jge",    III_OPF_BRANCH },
    { "callq",  III_OPF_BRANCH | III_OPF_CALL },
    { "retq",   III_OPF_BRANCH | III_OPF_CALL },
    { NULL, 0 }
};

static const iii_op_info_t *op_lookup(const char *m)
{
    if (!m) return NULL;
    for (int i = 0; III_OP_TABLE[i].mnemonic; i++) {
        if (strcmp(III_OP_TABLE[i].mnemonic, m) == 0) return &III_OP_TABLE[i];
    }
    return NULL;
}

int iii_cg_r3_emit(iii_cg_r3_state_t *cg, const char *mnemonic, const char *operands)
{
    if (!cg || !mnemonic) return III_CG_R3_E_NULL_ARG;
    if (!op_lookup(mnemonic)) {
        cg->last_error = III_CG_R3_E_UNSUPPORTED;
        cg->error_count++;
        return III_CG_R3_E_UNSUPPORTED;
    }
    cg_write_str(cg, "    ");
    cg_write_str(cg, mnemonic);
    if (operands && *operands) {
        cg_write_char(cg, ' ');
        cg_write_str(cg, operands);
    }
    cg_write_char(cg, '\n');
    return III_CG_R3_OK;
}

/* ─── Sanitise an identifier into a label-safe form ───────────────── */

/* Phase 3 Step 3: extract the first u64 argument of a named @-modifier.
 * Returns true and fills *out_value on success; false on absence or
 * non-integer argument.  Used by emit_function to read the @cap_required
 * mask before emitting the runtime capability-check prologue. */
/* iiis-2 feature 4 — resolve a TYPE_REF's name to a TYPE_DECL in the
 * current module's top-level decls.  Returns the TYPE_DECL's node id
 * or 0 if not found.  Used by type-alias modifier resolution: when a
 * TYPE_REF has no inline modifiers, this helper finds its alias decl
 * so we can chase the alias chain.
 *
 * O(N) over module decl count, but type aliases are rare in module
 * scope, and the lookup only fires when the inline modifier check
 * yields no match.  Stage-2+ adds a name-keyed table. */
static uint32_t type_ref_resolve_decl(iii_cg_r3_state_t *cg,
                                       const iii_ast_node_t *type_ref)
{
    if (!type_ref || type_ref->kind != III_AST_TYPE_REF) return 0;
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    if (!src) return 0;
    iii_src_text_t nm = type_ref->u.type_ref.name;
    if (nm.length == 0) return 0;
    const iii_ast_node_t *mod =
        iii_ast_get(cg->ast, iii_ast_root_module(cg->ast));
    if (!mod || mod->kind != III_AST_MODULE) return 0;
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d || d->kind != III_AST_TYPE_DECL) continue;
        iii_src_text_t dn = d->u.type_decl.name;
        if (dn.length != nm.length) continue;
        if (memcmp(src + dn.offset, src + nm.offset, nm.length) != 0)
            continue;
        return did;
    }
    return 0;
}

/* Forward decl: fn_modifier_extract_u64 is defined below; the alias
 * resolver immediately above this calls it. */
static bool fn_modifier_extract_u64(iii_cg_r3_state_t *cg,
                                    iii_ast_list_t mods,
                                    const char *wanted, uint32_t wanted_len,
                                    uint64_t *out_value);

/* iiis-2 feature 4 — extract a modifier-u64 from a TYPE_REF, chasing
 * type-alias chains.  Equivalent to fn_modifier_extract_u64 on the
 * type_ref's inline modifiers, plus a fallback: if the inline list
 * has no match AND the type_ref resolves to a TYPE_DECL, also check
 * the TYPE_DECL's modifiers.  This lets `type IntentForm = u64
 * @hexad_kind(1u64)` flow its annotation through every binding that
 * declares type IntentForm without further inline annotation.
 *
 * Multi-hop alias resolution (Stage 3.6): walks the alias chain to a
 * fixpoint, so `type C = B`, `type B = A`, `type A = u64 @hexad_kind(K)`
 * flows K through every binding declared `: C`.  Depth-bounded at 8
 * (mirrors the ABI alias-resolution bound) so a cyclic alias like
 * `type A = B; type B = A` terminates.  cg_r3.iii mirrors this exactly. */
static bool type_node_extract_u64(iii_cg_r3_state_t *cg,
                                  uint32_t type_node,
                                  const char *wanted, uint32_t wanted_len,
                                  uint64_t *out_value)
{
    if (!out_value) return false;
    const iii_ast_node_t *t = iii_ast_get(cg->ast, type_node);
    if (!t || t->kind != III_AST_TYPE_REF) return false;
    /* Pass 1: inline modifiers on the TYPE_REF. */
    if (fn_modifier_extract_u64(cg, t->u.type_ref.modifiers,
                                wanted, wanted_len, out_value))
        return true;
    /* Walk the alias chain.  Each hop: resolve the current TYPE_REF's
     * name to a TYPE_DECL, check its modifiers and its rhs_type's inline
     * modifiers, then descend to the rhs's named type. */
    const iii_ast_node_t *cur = t;
    for (uint32_t depth = 0; depth < 8u; depth++) {
        uint32_t alias_decl = type_ref_resolve_decl(cg, cur);
        if (alias_decl == 0) return false;
        const iii_ast_node_t *ad = iii_ast_get(cg->ast, alias_decl);
        if (!ad || ad->kind != III_AST_TYPE_DECL) return false;
        if (fn_modifier_extract_u64(cg, ad->u.type_decl.modifiers,
                                    wanted, wanted_len, out_value))
            return true;
        const iii_ast_node_t *rhs = iii_ast_get(cg->ast, ad->u.type_decl.rhs_type);
        if (!rhs || rhs->kind != III_AST_TYPE_REF) return false;
        if (fn_modifier_extract_u64(cg, rhs->u.type_ref.modifiers,
                                    wanted, wanted_len, out_value))
            return true;
        /* Multi-hop: continue down to the rhs's named type. */
        cur = rhs;
    }
    return false;
}

static bool fn_modifier_extract_u64(iii_cg_r3_state_t *cg,
                                    iii_ast_list_t mods,
                                    const char *wanted, uint32_t wanted_len,
                                    uint64_t *out_value)
{
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    if (!src || !out_value) return false;
    for (uint32_t i = 0; i < mods.count; i++) {
        uint32_t mid = iii_ast_list_at(cg->ast, mods, i);
        const iii_ast_node_t *m = iii_ast_get(cg->ast, mid);
        if (!m || m->kind != III_AST_MODIFIER) continue;
        if (m->u.modifier.name.length != wanted_len) continue;
        if (memcmp(src + m->u.modifier.name.offset, wanted, wanted_len) != 0) continue;
        if (m->u.modifier.args.count == 0) return false;
        uint32_t aid = iii_ast_list_at(cg->ast, m->u.modifier.args, 0);
        const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
        if (!a) return false;
        /* ARG nodes wrap an expression — unwrap if present. */
        if (a->kind == III_AST_ARG) {
            a = iii_ast_get(cg->ast, a->u.arg.value_expr);
            if (!a) return false;
        }
        if (a->kind == III_AST_EXPR_INT) { *out_value = a->u.int_.value; return true; }
        if (a->kind == III_AST_EXPR_HEX) { *out_value = a->u.hex_.value; return true; }
        return false;
    }
    return false;
}

/* Returns true iff the modifier list contains a modifier whose name's
 * source text equals `wanted` (e.g., "export").  Used to detect
 * @export, @inline, etc. on top-level declarations. */
static bool fn_modifiers_contain(iii_cg_r3_state_t *cg,
                                 iii_ast_list_t mods,
                                 const char *wanted, uint32_t wanted_len)
{
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    if (!src) return false;
    for (uint32_t i = 0; i < mods.count; i++) {
        uint32_t mid = iii_ast_list_at(cg->ast, mods, i);
        const iii_ast_node_t *m = iii_ast_get(cg->ast, mid);
        if (!m || m->kind != III_AST_MODIFIER) continue;
        if (m->u.modifier.name.length != wanted_len) continue;
        if (memcmp(src + m->u.modifier.name.offset, wanted, wanted_len) == 0) {
            return true;
        }
    }
    return false;
}

/* True when the decl_node carries an @export modifier (currently only
 * meaningful for FN_DECL — exported fns emit under the unmangled
 * symbol name so other TUs can resolve them at link time). */
static bool decl_is_exported(iii_cg_r3_state_t *cg, uint32_t decl_node)
{
    if (decl_node == 0) return false;
    const iii_ast_node_t *d = iii_ast_get(cg->ast, decl_node);
    if (!d || d->kind != III_AST_FN_DECL) return false;
    return fn_modifiers_contain(cg, d->u.fn_decl.modifiers, "export", 6);
}

/* Map a TYPE_REF primitive name → byte width.  Returns 0 if unknown
 * (caller should fall back to 8-byte uniform).  Recognises the
 * Stage-0 fixed-width primitives only (u8/i8/bool, u16/i16,
 * u32/i32, u64/i64). */
static uint32_t type_ref_byte_size(iii_cg_r3_state_t *cg, const iii_ast_node_t *tref)
{
    if (!tref || tref->kind != III_AST_TYPE_REF) return 0;
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    if (!src) return 0;
    iii_src_text_t in = tref->u.type_ref.name;
    if (in.length == 0 || in.length > 4) return 0;
    char buf[8]; memcpy(buf, src + in.offset, in.length); buf[in.length] = 0;
    if (strcmp(buf, "u8")   == 0 || strcmp(buf, "i8")  == 0 || strcmp(buf, "bool") == 0) return 1;
    if (strcmp(buf, "u16")  == 0 || strcmp(buf, "i16") == 0) return 2;
    if (strcmp(buf, "u32")  == 0 || strcmp(buf, "i32") == 0) return 4;
    if (strcmp(buf, "u64")  == 0 || strcmp(buf, "i64") == 0) return 8;
    return 0;
}

/* Compute the element byte width for a TYPE_ARRAY node.  Falls back to
 * 8 (Stage-0 u64-uniform default) if the inner type is not a known
 * fixed-width primitive. */
static uint32_t array_elem_byte_size(iii_cg_r3_state_t *cg, const iii_ast_node_t *tarr)
{
    if (!tarr || tarr->kind != III_AST_TYPE_ARRAY) return 8;
    const iii_ast_node_t *inner = iii_ast_get(cg->ast, tarr->u.type_array.inner);
    uint32_t w = type_ref_byte_size(cg, inner);
    return (w == 0) ? 8u : w;
}

/* Choose the GAS data directive for a given element byte width. */
static const char *gas_data_directive(uint32_t width)
{
    switch (width) {
        case 1: return ".byte";
        case 2: return ".short";
        case 4: return ".long";
        default: return ".quad";
    }
}

/* ─── Phase C.6: Partial Evaluator (PE) narrowing helpers ─────────────
 *
 * The PE inspects every call to `resolve(set, intent, ctx)` at codegen
 * time and tries to replace it with a direct load of the dispatch_fp
 * when the `intent` argument is provably static (constructed by an
 * intent_form / intent_act / intent_convey call with literal args).
 *
 * Single source of truth: COMPILER/BOOT/iii_compositions.def, regenerated
 * into iii_compositions.h (this header) and STDLIB/iii/omnia/prespec.iii's
 * bulk-reg block by COMPILER/BOOT/gen_compositions.sh on every iiis-0
 * build. Drift between cg_r3 and prespec is structurally impossible.
 *
 * Mandate 7 compliance: this is a STATIC mapping (compile-time table),
 * not adaptive learning. No counts, no thresholds, no observation.
 */
#include "iii_compositions.h"

/* Forward decls for the PE classification + emission helpers. */
static int  cg_r3_pe_classify_intent_arg(iii_cg_r3_state_t *cg,
                                            uint32_t intent_arg_node,
                                            const char **out_dispatch_name);
static int  cg_r3_pe_emit_direct_load(iii_cg_r3_state_t *cg, const char *fn_name);

/* Phase C.6 multi-statement narrowing: per-local static-fp recorder/lookup.
 * cg_r3_pe_record_static_fp(cg, slot_idx, fn_name)
 *   Record that the local at `slot_idx` holds a statically-resolved
 *   function pointer to `fn_name`. Out-of-range slot_idx is a no-op
 *   (silent fall-back to non-PE codegen for that slot).
 *
 * cg_r3_pe_get_static_fp(cg, slot_idx)
 *   Return the recorded fn_name for a slot, or NULL if not statically
 *   resolved (or out of range).
 *
 * Storage lives in iii_cg_r3_state_t::pe_static_fp[128]; it's reset in
 * emit_function() so each function starts clean. */
static void        cg_r3_pe_record_static_fp(iii_cg_r3_state_t *cg,
                                             uint32_t slot_idx,
                                             const char *fn_name);
static const char *cg_r3_pe_get_static_fp(iii_cg_r3_state_t *cg,
                                          uint32_t slot_idx);

/* Emit `name` with all non-ident bytes substituted to '_'. */
static void emit_raw_symbol(iii_cg_r3_state_t *cg, iii_src_text_t name)
{
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    if (!src) return;
    for (uint32_t i = 0; i < name.length; i++) {
        uint8_t b = src[name.offset + i];
        if ((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
            (b >= '0' && b <= '9') || b == '_') {
            cg_write_char(cg, (int)b);
        } else {
            cg_write_char(cg, '_');
        }
    }
}

static void emit_decl_label(iii_cg_r3_state_t *cg, iii_src_text_t name)
{
    /* Entry-point exception: the function literally named `main` is
     * emitted UNPREFIXED so the host linker (ld on PE/COFF, ELF, or
     * Mach-O) can find it as the program entry point.  Every other
     * declaration carries the `L_` prefix so III-namespace symbols
     * cannot collide with libc / Win32 / kernel-side symbol names.
     *
     * @export functions and their call sites bypass this helper and
     * emit via emit_raw_symbol() instead — see emit_function() and
     * the call-site dispatch below. */
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    bool is_main = (src && name.length == 4
                    && src[name.offset + 0] == 'm'
                    && src[name.offset + 1] == 'a'
                    && src[name.offset + 2] == 'i'
                    && src[name.offset + 3] == 'n');
    if (!is_main) {
        cg_write_str(cg, "L_");
    }
    emit_raw_symbol(cg, name);
}

/* ─── D7: defining-label uniqueness set ───────────────────────────── */

static int label_define(iii_cg_r3_state_t *cg, uint32_t lbl)
{
    for (uint32_t i = 0; i < cg->defined_label_count; i++) {
        if (cg->defined_labels[i] == lbl) {
            cg->last_error = III_CG_R3_E_DUP_LABEL;
            cg->error_count++;
            return -1;
        }
    }
    if (cg->defined_label_count < III_CG_R3_MAX_LABELS) {
        cg->defined_labels[cg->defined_label_count++] = lbl;
    }
    return 0;
}

/* ─── Local-name table ────────────────────────────────────────────── */

static int local_lookup_slot(iii_cg_r3_state_t *cg, iii_src_text_t name)
{
    for (uint32_t i = 0; i < cg->local_count; i++) {
        if (cg->locals[i].name.length == name.length &&
            memcmp(iii_ast_source_buf(cg->ast) + cg->locals[i].name.offset,
                   iii_ast_source_buf(cg->ast) + name.offset,
                   name.length) == 0) {
            return (int)cg->locals[i].slot;
        }
    }
    return -1;
}

static void local_add(iii_cg_r3_state_t *cg, iii_src_text_t name)
{
    if (cg->local_count >= 64u) return;  /* arity cap */
    cg->locals[cg->local_count].name = name;
    cg->locals[cg->local_count].slot = cg->local_count;
    cg->local_count++;
}

/* ─── Stack-machine helpers ───────────────────────────────────────── */

static void stack_push_reg(iii_cg_r3_state_t *cg, const char *reg)
{
    emit_line(cg, "    pushq %%%s", reg);
    cg->stack_depth += 1;
    if (cg->stack_depth > cg->max_stack_depth) cg->max_stack_depth = cg->stack_depth;
}

static void stack_pop_reg(iii_cg_r3_state_t *cg, const char *reg)
{
    emit_line(cg, "    popq %%%s", reg);
    if (cg->stack_depth > 0) cg->stack_depth -= 1;
}

/* ─── Forward decls ───────────────────────────────────────────────── */

static int emit_expr(iii_cg_r3_state_t *cg, uint32_t node);
static int emit_stmt(iii_cg_r3_state_t *cg, uint32_t node);
static int emit_block(iii_cg_r3_state_t *cg, uint32_t block_node);

/* Recursive type-signedness inference for binary-compare codegen.
 * Returns true when the expression at `node` resolves to a signed
 * integer type (i8/i16/i32/i64/isize), false otherwise.  This drives
 * the choice of set* opcode for `<`/`<=`/`>`/`>=` in the binary-cmp
 * case: signed types use setl/setle/setg/setge, unsigned use the
 * setb/setbe/seta/setae family.  Without this, `5i64 < -1i64` returns
 * the wrong answer because cmpq + setb treats both as unsigned u64,
 * making -1i64 the largest possible value. */
static bool type_name_is_signed(const char *name)
{
    if (!name) return false;
    if (strcmp(name, "i8")    == 0) return true;
    if (strcmp(name, "i16")   == 0) return true;
    if (strcmp(name, "i32")   == 0) return true;
    if (strcmp(name, "i64")   == 0) return true;
    if (strcmp(name, "isize") == 0) return true;
    return false;
}

/* True iff `name` is a 32-bit integer type (u32/i32).  A 32-bit
 * left-shift must be truncated to 32 bits (language: `x << k` is mod
 * 2^32); codegen otherwise emits a 64-bit shlq whose high bits leak
 * (the sha256.iii `& 0xFFFFFFFF` mask was working around exactly
 * this).  Conservative: only a PROVABLY-32-bit shift is narrowed, so
 * all other codegen is byte-identical to before. */
static bool type_name_is_u32(const char *name)
{
    if (!name) return false;
    if (strcmp(name, "u32") == 0) return true;
    if (strcmp(name, "i32") == 0) return true;
    return false;
}

static bool type_node_is_signed(const iii_ast_t *ast, uint32_t type_node_id)
{
    if (!type_node_id) return false;
    const iii_ast_node_t *t = iii_ast_get(ast, type_node_id);
    if (!t) return false;
    if (t->kind != III_AST_TYPE_REF) return false;
    const uint8_t *src = iii_ast_source_buf(ast);
    iii_src_text_t nm = t->u.type_ref.name;
    if (!src) return false;
    if (nm.length > 8) return false;
    char buf[16];
    for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
    buf[nm.length] = 0;
    return type_name_is_signed(buf);
}

static bool type_node_is_u32(const iii_ast_t *ast, uint32_t type_node_id)
{
    if (!type_node_id) return false;
    const iii_ast_node_t *t = iii_ast_get(ast, type_node_id);
    if (!t) return false;
    if (t->kind != III_AST_TYPE_REF) return false;
    const uint8_t *src = iii_ast_source_buf(ast);
    iii_src_text_t nm = t->u.type_ref.name;
    if (!src) return false;
    if (nm.length > 8) return false;
    char buf[16];
    for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
    buf[nm.length] = 0;
    return type_name_is_u32(buf);
}

/* Pointer/array element width in bytes (1/2/4/8) for indexed access.
 * Drives both load (movb/movw/movl/movq + zero/sign-extend) and store
 * (movb/movw/movl/movq + correct scale).  Defaults to 8 for unknown
 * types preserving legacy behavior for u64/i64 and pointer-of-pointer.
 *
 * Without this, `*u32 indexed write` emits 8-byte movq with scale=8,
 * overwriting the adjacent 4-byte slot and skipping every other element
 * on stride.  Same family bug as the signed-compare trap. */
/* Variant: pointer_element_width given an inner-type node directly
 * (not via a binder).  Used by the TYPE_ARRAY case in STMT_LET to size
 * stack arrays. */
static int pointer_element_width_for_inner(iii_cg_r3_state_t *cg, uint32_t inner_type_id)
{
    if (!inner_type_id) return 8;
    const iii_ast_node_t *inner = iii_ast_get(cg->ast, inner_type_id);
    if (!inner || inner->kind != III_AST_TYPE_REF) return 8;
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    iii_src_text_t in = inner->u.type_ref.name;
    if (!src) return 8;
    if (in.length > 5) return 8;
    char buf[8];
    for (uint32_t i = 0; i < in.length; i++) buf[i] = (char)src[in.offset + i];
    buf[in.length] = 0;
    if (strcmp(buf, "u8")   == 0 || strcmp(buf, "i8")   == 0 || strcmp(buf, "bool") == 0) return 1;
    if (strcmp(buf, "u16")  == 0 || strcmp(buf, "i16")  == 0) return 2;
    if (strcmp(buf, "u32")  == 0 || strcmp(buf, "i32")  == 0 || strcmp(buf, "q14") == 0) return 4;
    return 8;
}

static int pointer_element_width(iii_cg_r3_state_t *cg, uint32_t obj_node_id)
{
    if (!obj_node_id) return 8;
    const iii_ast_node_t *obj = iii_ast_get(cg->ast, obj_node_id);
    if (!obj) return 8;
    if (obj->kind != III_AST_EXPR_IDENT) return 8;
    uint32_t bid = iii_ast_node_binder_id(cg->ast, obj_node_id);
    if (!bid) return 8;
    const iii_ast_node_t *binder = iii_ast_get(cg->ast, bid);
    if (!binder) return 8;
    uint32_t tnode = 0;
    if      (binder->kind == III_AST_STMT_LET)   tnode = binder->u.let_.type_node;
    else if (binder->kind == III_AST_PARAM)      tnode = binder->u.param.type_node;
    else if (binder->kind == III_AST_VAR_DECL)   tnode = binder->u.var_decl.type_node;
    if (!tnode) return 8;
    const iii_ast_node_t *t = iii_ast_get(cg->ast, tnode);
    if (!t) return 8;
    const iii_ast_node_t *inner = NULL;
    if      (t->kind == III_AST_TYPE_PTR)   inner = iii_ast_get(cg->ast, t->u.type_ptr.inner);
    else if (t->kind == III_AST_TYPE_ARRAY) inner = iii_ast_get(cg->ast, t->u.type_array.inner);
    if (!inner || inner->kind != III_AST_TYPE_REF) return 8;
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    iii_src_text_t in = inner->u.type_ref.name;
    if (!src) return 8;
    if (in.length > 5) return 8;
    char buf[8];
    for (uint32_t i = 0; i < in.length; i++) buf[i] = (char)src[in.offset + i];
    buf[in.length] = 0;
    if (strcmp(buf, "u8")   == 0 || strcmp(buf, "i8")   == 0 || strcmp(buf, "bool") == 0) return 1;
    if (strcmp(buf, "u16")  == 0 || strcmp(buf, "i16")  == 0) return 2;
    if (strcmp(buf, "u32")  == 0 || strcmp(buf, "i32")  == 0 || strcmp(buf, "q14") == 0) return 4;
    return 8;
}

static bool element_is_signed_int(iii_cg_r3_state_t *cg, uint32_t obj_node_id)
{
    if (!obj_node_id) return false;
    const iii_ast_node_t *obj = iii_ast_get(cg->ast, obj_node_id);
    if (!obj || obj->kind != III_AST_EXPR_IDENT) return false;
    uint32_t bid = iii_ast_node_binder_id(cg->ast, obj_node_id);
    if (!bid) return false;
    const iii_ast_node_t *binder = iii_ast_get(cg->ast, bid);
    if (!binder) return false;
    uint32_t tnode = 0;
    if      (binder->kind == III_AST_STMT_LET)   tnode = binder->u.let_.type_node;
    else if (binder->kind == III_AST_PARAM)      tnode = binder->u.param.type_node;
    else if (binder->kind == III_AST_VAR_DECL)   tnode = binder->u.var_decl.type_node;
    if (!tnode) return false;
    const iii_ast_node_t *t = iii_ast_get(cg->ast, tnode);
    if (!t) return false;
    const iii_ast_node_t *inner = NULL;
    if      (t->kind == III_AST_TYPE_PTR)   inner = iii_ast_get(cg->ast, t->u.type_ptr.inner);
    else if (t->kind == III_AST_TYPE_ARRAY) inner = iii_ast_get(cg->ast, t->u.type_array.inner);
    if (!inner || inner->kind != III_AST_TYPE_REF) return false;
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    iii_src_text_t in = inner->u.type_ref.name;
    if (!src || in.length > 5) return false;
    char buf[8];
    for (uint32_t i = 0; i < in.length; i++) buf[i] = (char)src[in.offset + i];
    buf[in.length] = 0;
    return type_name_is_signed(buf);
}

static bool expr_is_signed(iii_cg_r3_state_t *cg, uint32_t node_id)
{
    if (!node_id) return false;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node_id);
    if (!n) return false;
    switch (n->kind) {
        case III_AST_EXPR_PAREN:
            return expr_is_signed(cg, n->u.paren.inner);
        case III_AST_EXPR_CAST: {
            const iii_ast_node_t *t = iii_ast_get(cg->ast, n->u.cast_.target_type);
            if (!t || t->kind != III_AST_TYPE_REF) return false;
            const uint8_t *src = iii_ast_source_buf(cg->ast);
            iii_src_text_t nm = t->u.type_ref.name;
            if (!src || nm.length > 8) return false;
            char buf[16];
            for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
            buf[nm.length] = 0;
            return type_name_is_signed(buf);
        }
        case III_AST_EXPR_IDENT: {
            uint32_t bid = iii_ast_node_binder_id(cg->ast, node_id);
            if (!bid) return false;
            const iii_ast_node_t *b = iii_ast_get(cg->ast, bid);
            if (!b) return false;
            uint32_t tn = 0;
            if      (b->kind == III_AST_PARAM)      tn = b->u.param.type_node;
            else if (b->kind == III_AST_STMT_LET)   tn = b->u.let_.type_node;
            else if (b->kind == III_AST_VAR_DECL)   tn = b->u.var_decl.type_node;
            else if (b->kind == III_AST_CONST_DECL) tn = b->u.const_decl.type_node;
            return type_node_is_signed(cg->ast, tn);
        }
        case III_AST_EXPR_BINARY:
            /* Arithmetic on signed operands stays signed. */
            return expr_is_signed(cg, n->u.binary.lhs)
                || expr_is_signed(cg, n->u.binary.rhs);
        case III_AST_EXPR_UNARY:
            return expr_is_signed(cg, n->u.unary.operand);
        default:
            /* EXPR_INT/EXPR_HEX/etc. default to unsigned today (literal
             * suffix not preserved into AST yet — when it is, this case
             * will read from the payload). */
            return false;
    }
}

/* True iff `node_id`'s static type is a 32-bit integer (u32/i32).
 * Mirrors expr_is_signed's recursion exactly, except the BINARY case
 * follows the LHS only: an iii binary expression's result width is its
 * operand width (operands are same-typed in well-formed iii), so the
 * shift/arith result is 32-bit iff the lhs is.  Conservative: anything
 * not PROVABLY 32-bit returns false (no narrowing → byte-identical to
 * prior codegen for every non-u32 case). */
static bool expr_is_u32(iii_cg_r3_state_t *cg, uint32_t node_id)
{
    if (!node_id) return false;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node_id);
    if (!n) return false;
    switch (n->kind) {
        case III_AST_EXPR_PAREN:
            return expr_is_u32(cg, n->u.paren.inner);
        case III_AST_EXPR_CAST: {
            const iii_ast_node_t *t = iii_ast_get(cg->ast, n->u.cast_.target_type);
            if (!t || t->kind != III_AST_TYPE_REF) return false;
            const uint8_t *src = iii_ast_source_buf(cg->ast);
            iii_src_text_t nm = t->u.type_ref.name;
            if (!src || nm.length > 8) return false;
            char buf[16];
            for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
            buf[nm.length] = 0;
            return type_name_is_u32(buf);
        }
        case III_AST_EXPR_IDENT: {
            uint32_t bid = iii_ast_node_binder_id(cg->ast, node_id);
            if (!bid) return false;
            const iii_ast_node_t *b = iii_ast_get(cg->ast, bid);
            if (!b) return false;
            uint32_t tn = 0;
            if      (b->kind == III_AST_PARAM)      tn = b->u.param.type_node;
            else if (b->kind == III_AST_STMT_LET)   tn = b->u.let_.type_node;
            else if (b->kind == III_AST_VAR_DECL)   tn = b->u.var_decl.type_node;
            else if (b->kind == III_AST_CONST_DECL) tn = b->u.const_decl.type_node;
            return type_node_is_u32(cg->ast, tn);
        }
        case III_AST_EXPR_BINARY:
            return expr_is_u32(cg, n->u.binary.lhs);
        case III_AST_EXPR_UNARY:
            return expr_is_u32(cg, n->u.unary.operand);
        default:
            return false;
    }
}

/* ─── Hexad packing ───────────────────────────────────────────────── */

/* Each trit takes 2 bits; six trits pack into the low 12 bits of a u16. */
static uint16_t pack_hexad_trits(const iii_ast_trit_t trits[6])
{
    uint16_t v = 0;
    for (int i = 0; i < 6; i++) {
        v = (uint16_t)(v | ((uint16_t)((uint16_t)trits[i] & 0x3u) << (2 * i)));
    }
    return v;
}

/* ─── MHASH literal pool ──────────────────────────────────────────── */

/* MHASH literals are emitted as 32-byte data labels in .rodata.  Each
 * AST mhash node receives a deterministic label `L_mhash_<node_id>`. */
static void emit_mhash_data_label(iii_cg_r3_state_t *cg, uint32_t node_id, const uint8_t mh[32])
{
    cg_writef(cg, "L_mhash_%u:\n    .byte ", (unsigned)node_id);
    for (int i = 0; i < 32; i++) {
        cg_writef(cg, "0x%02x%s", mh[i], (i == 31) ? "\n" : ", ");
    }
}

/* ─── Field-access label mangling ─────────────────────────────────── */

/* Stage-0 lowers `obj.field` (where obj is an identifier) into a
 * link-time-resolved symbol `L_<obj>__<field>`.  The std library and
 * extern declarations are expected to provide these symbols.  Nested
 * field access (a.b.c) is rejected at codegen as Stage-0 cannot
 * resolve nested field offsets without sema-side type information. */
static int emit_field_label(iii_cg_r3_state_t *cg,
                            const iii_ast_node_t *obj,
                            iii_src_text_t field_name)
{
    if (!obj || obj->kind != III_AST_EXPR_IDENT) return -1;
    cg_write_str(cg, "L_");
    for (uint32_t i = 0; i < obj->u.ident.name.length; i++) {
        uint8_t b = iii_ast_source_buf(cg->ast)[obj->u.ident.name.offset + i];
        if ((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
            (b >= '0' && b <= '9') || b == '_') {
            cg_write_char(cg, (int)b);
        } else {
            cg_write_char(cg, '_');
        }
    }
    cg_write_str(cg, "__");
    for (uint32_t i = 0; i < field_name.length; i++) {
        uint8_t b = iii_ast_source_buf(cg->ast)[field_name.offset + i];
        if ((b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') ||
            (b >= '0' && b <= '9') || b == '_') {
            cg_write_char(cg, (int)b);
        } else {
            cg_write_char(cg, '_');
        }
    }
    return 0;
}

/* ─── D1/D2: ABI-conformance assertion before CALL ───────────────────
 *
 * MS x64 ABI §6.4: the stack pointer must be 16-byte aligned at the
 * call boundary (rsp ≡ 0 (mod 16) right before CALL; the CALL itself
 * pushes the 8-byte return address making rsp ≡ 8 (mod 16) on entry
 * to the callee).  Our `stack_depth` counter is in 8-byte slots; with
 * the 32-byte shadow space (4 slots) added per CALL plus any optional
 * 1-slot pad, we require:  (stack_depth + 4 + pad) % 2 == 0.
 *
 * MS x64 ABI §6.4.4: every CALL must have 32 bytes of shadow space
 * reserved by the caller for callee scratch.
 */
static int abi_assert_call_alignment(iii_cg_r3_state_t *cg, uint32_t total_slots)
{
    if ((total_slots & 1u) != 0u) {
        cg->last_error = III_CG_R3_E_ABI_ALIGN;
        cg->error_count++;
        cg_writef(cg, "    # III_CG_R3_E_ABI_ALIGN: total_slots=%u (must be even)\n",
                  (unsigned)total_slots);
        return -1;
    }
    /* iiis-1 bit-identity: ABI-OK comment removed.  The alignment
     * invariant is asserted by the (total_slots & 1u32) check above;
     * a successful return means slots are 16-aligned.  No need to
     * emit a runtime-dynamic comment that diverges between compilers. */
    return 0;
}

/* ─── Pattern compare ─────────────────────────────────────────────── */

/* Generate a comparison that sets ZF=1 iff the value in %rax matches
 * the given pattern.  Called with %rax = scrutinee value. */
static int emit_pattern_compare(iii_cg_r3_state_t *cg, uint32_t pat_node)
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
                default:
                    cg->last_error = III_CG_R3_E_UNSUPPORTED;
                    cg->error_count++;
                    return -1;
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
            cg->last_error = III_CG_R3_E_UNSUPPORTED;
            cg->error_count++;
            return -1;
    }
}

/* Bind a PAT_IDENT to a fresh local with the value currently in %rax. */
static void emit_pattern_bind(iii_cg_r3_state_t *cg, uint32_t pat_node)
{
    const iii_ast_node_t *p = iii_ast_get(cg->ast, pat_node);
    if (!p || p->kind != III_AST_PAT_IDENT) return;
    local_add(cg, p->u.pat_ident.name);
    uint32_t slot = cg->local_count - 1u;
    emit_line(cg, "    movq %%rax, -%d(%%rbp)", (slot + 1) * 8);
}

/* ─── Expression codegen (stack machine) ──────────────────────────── */

/* STRENGTH REDUCTION test (dual of cg_r3.iii's r3_mul_pow2_k -- IDENTICAL logic so the emitted
 * assembly is byte-for-byte the same, keeping iiis-0 == iiis-2): if op is MUL and rhs is a constant
 * integer literal equal to 2^k (k in 1..63), return k; else 0.  Sound: x*2^k == x<<k (mod 2^64),
 * signed + unsigned.  Kernel-justified (sov_isa proves mul(x,2)==shl(x,1)). */
static int mul_pow2_k(iii_cg_r3_state_t *cg, const iii_ast_node_t *n)
{
    if (n->u.binary.op != III_BIN_MUL) return 0;
    const iii_ast_node_t *rhs = iii_ast_get(cg->ast, n->u.binary.rhs);
    if (!rhs || rhs->kind != III_AST_EXPR_INT) return 0;
    uint64_t v = rhs->u.int_.value;
    if (v < 2) return 0;
    if ((v & (v - 1)) != 0) return 0;
    int k = 0; uint64_t t = v;
    while (t > 1) { t >>= 1; k++; }
    return k;
}

static int emit_expr(iii_cg_r3_state_t *cg, uint32_t node)
{
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    switch (n->kind) {
        case III_AST_EXPR_INT:
        case III_AST_EXPR_HEX: {
            uint64_t v = (n->kind == III_AST_EXPR_INT) ? n->u.int_.value : n->u.hex_.value;
            emit_line(cg, "    movabsq $0x%llx, %%rax", (unsigned long long)v);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_BOOL: {
            emit_line(cg, "    movq $%d, %%rax", n->u.bool_.value ? 1 : 0);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_TRIT: {
            emit_line(cg, "    movq $%d, %%rax", (int)n->u.trit_.trit);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_UNIT: {
            emit_line(cg, "    movq $0, %%rax");
            stack_push_reg(cg, "rax");
            return 0;
        }
        /* F4 — cast.  Stage-1 is u64-uniform; the cast is a value-
         * preserving no-op for same-width types and a narrowing
         * truncation for u8/u16/u32 (movzbq/movzwq/movl-implicit-zero).
         * We inspect the target type's name to decide; unknown types
         * pass through unchanged (Stage-1+ width tracking adds rigor).
         * LOAD-BEARING: a sign-aware variant (tried + reverted 2026-06-04) reddened corpus
         * 1113/1114 via the compiler's own bit-31 `as i32` self-host sites.  Keep zero-extend. */
        case III_AST_EXPR_CAST: {
            if (emit_expr(cg, n->u.cast_.value_expr) != 0) return -1;
            stack_pop_reg(cg, "rax");
            const iii_ast_node_t *t = iii_ast_get(cg->ast, n->u.cast_.target_type);
            if (t && t->kind == III_AST_TYPE_REF) {
                const uint8_t *src = iii_ast_source_buf(cg->ast);
                iii_src_text_t nm = t->u.type_ref.name;
                if (src && nm.length <= 8) {
                    char buf[16];
                    for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
                    buf[nm.length] = 0;
                    if (strcmp(buf, "u8") == 0 || strcmp(buf, "i8") == 0) {
                        emit_line(cg, "    movzbq %%al, %%rax");
                    } else if (strcmp(buf, "u16") == 0 || strcmp(buf, "i16") == 0) {
                        emit_line(cg, "    movzwq %%ax, %%rax");
                    } else if (strcmp(buf, "u32") == 0 || strcmp(buf, "i32") == 0) {
                        emit_line(cg, "    movl %%eax, %%eax");
                    }
                    /* u64/i64/usize/isize/bool/Phase: no-op. */
                }
            }
            stack_push_reg(cg, "rax");
            return 0;
        }
        /* F5 — sizeof.  If sema resolved it (.resolved != 0) emit the
         * literal; otherwise inspect the target_type name for builtin
         * widths.  Unknown types resolve to 8 (the u64 default). */
        case III_AST_EXPR_SIZEOF: {
            uint64_t v = n->u.sizeof_.resolved;
            if (v == 0) {
                v = 8;      /* default u64 width */
                const iii_ast_node_t *t = iii_ast_get(cg->ast, n->u.sizeof_.target_type);
                if (t && t->kind == III_AST_TYPE_REF) {
                    const uint8_t *src = iii_ast_source_buf(cg->ast);
                    iii_src_text_t nm = t->u.type_ref.name;
                    if (src && nm.length <= 8) {
                        char buf[16];
                        for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
                        buf[nm.length] = 0;
                        if      (strcmp(buf, "u8") == 0  || strcmp(buf, "i8") == 0  || strcmp(buf, "bool") == 0) v = 1;
                        else if (strcmp(buf, "u16") == 0 || strcmp(buf, "i16") == 0) v = 2;
                        else if (strcmp(buf, "u32") == 0 || strcmp(buf, "i32") == 0 || strcmp(buf, "q14") == 0) v = 4;
                        else if (strcmp(buf, "mhash") == 0)                          v = 32;
                        /* else: 8 */
                    }
                }
            }
            emit_line(cg, "    movabsq $0x%llx, %%rax", (unsigned long long)v);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_IDENT: {
            int slot = local_lookup_slot(cg, n->u.ident.name);
            if (slot >= 0) {
                /* Width-aware local load: zero/sign-extend narrow types
                 * into rax via mov[zs]bq / mov[zs]wq / movl.  Without
                 * this, plain movq reads 8 bytes from the slot,
                 * preserving any garbage in the high 4 bytes for a u32
                 * local that was assigned from a register with dirty
                 * upper bits (the u32-in-u64-slot trap).
                 *
                 * Fallback to movq for u64/i64/usize/isize and any type
                 * we can't classify.  Existing-behavior preserving. */
                uint32_t bid = iii_ast_node_binder_id(cg->ast, node);
                const iii_ast_node_t *b = bid ? iii_ast_get(cg->ast, bid) : NULL;
                uint32_t tn = 0;
                if      (b && b->kind == III_AST_PARAM)    tn = b->u.param.type_node;
                else if (b && b->kind == III_AST_STMT_LET) tn = b->u.let_.type_node;
                const iii_ast_node_t *t = tn ? iii_ast_get(cg->ast, tn) : NULL;
                /* Array-typed local: ident evaluates to the base address
                 * of the reserved stack region (leaq -offset(%rbp), %rax),
                 * NOT the value at the first slot.  Mirrors module-level
                 * array decay behaviour. */
                if (t && t->kind == III_AST_TYPE_ARRAY) {
                    emit_line(cg, "    leaq -%d(%%rbp), %%rax",
                              (slot + 1) * 8);
                    stack_push_reg(cg, "rax");
                    return 0;
                }
                const char *mov_op = "movq";
                if (t && t->kind == III_AST_TYPE_REF) {
                    const uint8_t *src = iii_ast_source_buf(cg->ast);
                    iii_src_text_t tn_name = t->u.type_ref.name;
                    if (src && tn_name.length <= 6) {
                        char buf[8];
                        for (uint32_t i = 0; i < tn_name.length; i++) {
                            buf[i] = (char)src[tn_name.offset + i];
                        }
                        buf[tn_name.length] = 0;
                        if      (strcmp(buf, "u8") == 0 || strcmp(buf, "bool") == 0) mov_op = "movzbq";
                        else if (strcmp(buf, "i8") == 0)                             mov_op = "movsbq";
                        else if (strcmp(buf, "u16") == 0)                            mov_op = "movzwq";
                        else if (strcmp(buf, "i16") == 0)                            mov_op = "movswq";
                        else if (strcmp(buf, "u32") == 0)                            mov_op = "movl";
                        else if (strcmp(buf, "i32") == 0)                            mov_op = "movslq";
                    }
                }
                if (strcmp(mov_op, "movl") == 0) {
                    /* movl into %eax auto-zeros high 32 bits of %rax. */
                    emit_line(cg, "    movl -%d(%%rbp), %%eax",
                              (slot + 1) * 8);
                } else if (strcmp(mov_op, "movq") == 0) {
                    emit_line(cg, "    movq -%d(%%rbp), %%rax", (slot + 1) * 8);
                } else {
                    /* movzbq/movsbq/movzwq/movswq/movslq read narrow then extend. */
                    emit_line(cg, "    %s -%d(%%rbp), %%rax", mov_op, (slot + 1) * 8);
                }
                stack_push_reg(cg, "rax");
                return 0;
            }
            /* Top-level binder.  If sema resolved this ident to a
             * CONST_DECL, emit a load (the .rodata entry holds the
             * value).  Otherwise treat it as a function/variable
             * symbol and emit an address-of (leaq).  binder_id is
             * the decl's AST node index, set by sema. */
            uint32_t bid = iii_ast_node_binder_id(cg->ast, node);
            const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
            /* Array-typed VAR_DECLs decay to pointer (address-of); all
             * other VAR/CONST_DECL bindings load the value. */
            bool is_array_var = false;
            if (binder && binder->kind == III_AST_VAR_DECL) {
                const iii_ast_node_t *t = iii_ast_get(cg->ast, binder->u.var_decl.type_node);
                if (t && t->kind == III_AST_TYPE_ARRAY) is_array_var = true;
            }
            if (binder && (binder->kind == III_AST_CONST_DECL ||
                            (binder->kind == III_AST_VAR_DECL && !is_array_var))) {
                /* Width-aware load: zero/sign-extend narrow types into
                 * rax.  Without this, movq reads 8 bytes including 7
                 * bytes of adjacent BSS, contaminating compares with
                 * garbage from sibling vars. */
                const char *mov_op = "movq";
                uint32_t tnode_id = 0;
                if (binder->kind == III_AST_VAR_DECL)        tnode_id = binder->u.var_decl.type_node;
                else if (binder->kind == III_AST_CONST_DECL) tnode_id = binder->u.const_decl.type_node;
                const iii_ast_node_t *t = tnode_id ? iii_ast_get(cg->ast, tnode_id) : NULL;
                if (t && t->kind == III_AST_TYPE_REF) {
                    const uint8_t *src = iii_ast_source_buf(cg->ast);
                    iii_src_text_t tn = t->u.type_ref.name;
                    if (src && tn.length <= 6) {
                        char tbuf[8];
                        memcpy(tbuf, src + tn.offset, tn.length);
                        tbuf[tn.length] = 0;
                        if (strcmp(tbuf, "u8") == 0 || strcmp(tbuf, "bool") == 0) {
                            mov_op = "movzbq";
                        } else if (strcmp(tbuf, "i8") == 0) {
                            mov_op = "movsbq";
                        } else if (strcmp(tbuf, "u16") == 0) {
                            mov_op = "movzwq";
                        } else if (strcmp(tbuf, "i16") == 0) {
                            mov_op = "movswq";
                        } else if (strcmp(tbuf, "u32") == 0) {
                            mov_op = "movl"; /* implicit zero-extend to rax */
                        } else if (strcmp(tbuf, "i32") == 0) {
                            mov_op = "movslq";
                        }
                    }
                }
                cg_write_str(cg, "    ");
                cg_write_str(cg, mov_op);
                cg_write_str(cg, " ");
                emit_decl_label(cg, n->u.ident.name);
                if (strcmp(mov_op, "movl") == 0) {
                    cg_write_str(cg, "(%rip), %eax\n");
                } else {
                    cg_write_str(cg, "(%rip), %rax\n");
                }
            } else {
                /* For function-typed bindings, the bare-ident as
                 * fn-pointer-take must emit the RAW @export symbol when
                 * the function is @export-tagged.  Otherwise the leaq
                 * targets L_<name> which the linker leaves UNDEFINED
                 * (the actual exported function has no L_ prefix) ->
                 * indirect calls to garbage -> SEGV.  Mirror the
                 * @export-aware emission used by the unary-& operator. */
                bool fn_emit_raw = false;
                if (binder) {
                    if (binder->kind == III_AST_EXTERN_DECL) {
                        fn_emit_raw = true;
                    } else if (binder->kind == III_AST_FN_DECL) {
                        fn_emit_raw = fn_modifiers_contain(cg, binder->u.fn_decl.modifiers, "export", 6);
                    }
                }
                cg_write_str(cg, "    leaq ");
                if (fn_emit_raw) {
                    emit_raw_symbol(cg, n->u.ident.name);
                } else {
                    emit_decl_label(cg, n->u.ident.name);
                }
                cg_write_str(cg, "(%rip), %rax\n");
            }
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_PAREN:
            return emit_expr(cg, n->u.paren.inner);
        case III_AST_EXPR_BINARY: {
            int srk = mul_pow2_k(cg, n);
            if (srk != 0) {
                /* STRENGTH REDUCTION (the live self-optimizer; dual-implemented byte-identically in
                 * cg_r3.iii): mul by a constant 2^k becomes an immediate shift -- emit only the lhs,
                 * skip loading the constant + the imul.  Sound: mul(x,2^k) == shl(x,k). */
                if (emit_expr(cg, n->u.binary.lhs) != 0) return -1;
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    shlq $%d, %%rax", srk);
                if (expr_is_u32(cg, n->u.binary.lhs))
                    emit_line(cg, "    movl %%eax, %%eax");
                stack_push_reg(cg, "rax");
                return 0;
            }
            if (emit_expr(cg, n->u.binary.lhs) != 0) return -1;
            if (emit_expr(cg, n->u.binary.rhs) != 0) return -1;
            stack_pop_reg(cg, "rcx");   /* rhs */
            stack_pop_reg(cg, "rax");   /* lhs */
            switch (n->u.binary.op) {
                case III_BIN_ADD:
                    emit_line(cg, "    addq %%rcx, %%rax");
                    /* u32 mod-2^32: truncate the 64-bit result (matches the
                     * shlq case below + the sha256.iii/blake2s.iii mask). */
                    if (expr_is_u32(cg, n->u.binary.lhs))
                        emit_line(cg, "    movl %%eax, %%eax");
                    break;
                case III_BIN_SUB:
                    emit_line(cg, "    subq %%rcx, %%rax");
                    if (expr_is_u32(cg, n->u.binary.lhs))
                        emit_line(cg, "    movl %%eax, %%eax");
                    break;
                case III_BIN_MUL:
                    emit_line(cg, "    imulq %%rcx, %%rax");
                    if (expr_is_u32(cg, n->u.binary.lhs))
                        emit_line(cg, "    movl %%eax, %%eax");
                    break;
                case III_BIN_DIV: emit_line(cg, "    cqto\n    idivq %%rcx"); break;
                case III_BIN_MOD: emit_line(cg, "    cqto\n    idivq %%rcx\n    movq %%rdx, %%rax"); break;
                case III_BIN_AND: emit_line(cg, "    andq %%rcx, %%rax"); break;
                case III_BIN_OR:  emit_line(cg, "    orq %%rcx, %%rax");  break;
                case III_BIN_XOR: emit_line(cg, "    xorq %%rcx, %%rax"); break;
                case III_BIN_SHL:
                    emit_line(cg, "    shlq %%cl, %%rax");
                    /* A 32-bit shift is mod 2^32: truncate the 64-bit
                     * shlq result.  movl %eax,%eax zero-extends eax
                     * into rax, clearing bits 63..32 that a u32 `<<`
                     * must not carry (the sha256.iii mask workaround). */
                    if (expr_is_u32(cg, n->u.binary.lhs))
                        emit_line(cg, "    movl %%eax, %%eax");
                    break;
                case III_BIN_SHR: emit_line(cg, "    shrq %%cl, %%rax");  break;
                case III_BIN_EQ:
                case III_BIN_NEQ:
                case III_BIN_LT:
                case III_BIN_LE:
                case III_BIN_GT:
                case III_BIN_GE: {
                    /* Type-aware comparison: if either operand has a
                     * signed integer type (i8/i16/i32/i64/isize), use
                     * signed set* opcodes; otherwise unsigned.  Without
                     * this, signed `< / <= / > / >=` produce silent wrong
                     * answers for negative values (e.g. -5i64 < 1i64
                     * returns false because both are compared as u64).
                     *
                     * EQ/NEQ are bit-pattern compares — same opcode for
                     * signed and unsigned, so unaffected. */
                    bool sgn = expr_is_signed(cg, n->u.binary.lhs)
                            || expr_is_signed(cg, n->u.binary.rhs);
                    const char *setcc = "sete";
                    switch (n->u.binary.op) {
                        case III_BIN_EQ:  setcc = "sete";  break;
                        case III_BIN_NEQ: setcc = "setne"; break;
                        case III_BIN_LT:  setcc = sgn ? "setl"  : "setb";  break;
                        case III_BIN_LE:  setcc = sgn ? "setle" : "setbe"; break;
                        case III_BIN_GT:  setcc = sgn ? "setg"  : "seta";  break;
                        case III_BIN_GE:  setcc = sgn ? "setge" : "setae"; break;
                        default: break;
                    }
                    emit_line(cg, "    cmpq %%rcx, %%rax");
                    emit_line(cg, "    %s %%al", setcc);
                    emit_line(cg, "    movzbq %%al, %%rax");
                    break;
                }
                case III_BIN_LAND:
                    emit_line(cg, "    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rdx\n"
                                  "    testq %%rcx, %%rcx\n    setne %%al\n    movzbq %%al, %%rax\n"
                                  "    andq %%rdx, %%rax");
                    break;
                case III_BIN_LOR:
                    emit_line(cg, "    orq %%rcx, %%rax\n    testq %%rax, %%rax\n    setne %%al\n    movzbq %%al, %%rax");
                    break;
                case III_BIN_IN:
                case III_BIN_COMPOSE:
                default:
                    /* `in` and `compose` are substrate-level operators
                     * that require runtime cycle-table dispatch; Stage-0
                     * cannot lower them.  Sema must reject sources that
                     * reach this codegen path. */
                    cg->last_error = III_CG_R3_E_UNSUPPORTED;
                    cg->error_count++;
                    return -1;
            }
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_UNARY: {
            /* F6 — addr-of needs the LVALUE address, not the loaded
             * value.  Special-case BEFORE the generic operand emission
             * (which would load through the address). */
            if (n->u.unary.op == III_UN_ADDR) {
                const iii_ast_node_t *o = iii_ast_get(cg->ast, n->u.unary.operand);
                if (o && o->kind == III_AST_EXPR_IDENT) {
                    int slot = local_lookup_slot(cg, o->u.ident.name);
                    if (slot >= 0) {
                        emit_line(cg, "    leaq -%d(%%rbp), %%rax", (slot + 1) * 8);
                    } else {
                        /* Determine the correct symbol name: exported
                         * functions and externs use the raw symbol;
                         * everything else uses the L_-prefixed one. */
                        uint32_t bid = iii_ast_node_binder_id(cg->ast, n->u.unary.operand);
                        const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
                        bool emit_raw = false;
                        if (binder) {
                            if (binder->kind == III_AST_EXTERN_DECL) {
                                emit_raw = true;
                            } else if (binder->kind == III_AST_FN_DECL) {
                                emit_raw = fn_modifiers_contain(cg, binder->u.fn_decl.modifiers, "export", 6);
                            }
                        }
                        cg_write_str(cg, "    leaq ");
                        if (emit_raw) {
                            emit_raw_symbol(cg, o->u.ident.name);
                        } else {
                            emit_decl_label(cg, o->u.ident.name);
                        }
                        cg_write_str(cg, "(%rip), %rax\n");
                    }
                    stack_push_reg(cg, "rax");
                    return 0;
                }
                /* &X[i] — operand is EXPR_INDEX.  Emit base + scaled
                 * index *as an address* (LEA) instead of falling into
                 * the rvalue path which would dereference and push the
                 * loaded byte/word as a fake pointer (root cause of the
                 * walloc.iii sentinel-zero crash). */
                if (o && o->kind == III_AST_EXPR_INDEX) {
                    /* Mirror the byte_index detection from EXPR_INDEX. */
                    const iii_ast_node_t *iobj = iii_ast_get(cg->ast, o->u.index.object);
                    bool byte_index = (iobj && iobj->kind == III_AST_EXPR_STR);
                    if (!byte_index && iobj && iobj->kind == III_AST_EXPR_IDENT) {
                        uint32_t bid = iii_ast_node_binder_id(cg->ast, o->u.index.object);
                        const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
                        uint32_t tnode = 0;
                        if (binder && binder->kind == III_AST_STMT_LET)   tnode = binder->u.let_.type_node;
                        else if (binder && binder->kind == III_AST_PARAM) tnode = binder->u.param.type_node;
                        else if (binder && binder->kind == III_AST_VAR_DECL) tnode = binder->u.var_decl.type_node;
                        const iii_ast_node_t *t = tnode ? iii_ast_get(cg->ast, tnode) : NULL;
                        const iii_ast_node_t *inner = NULL;
                        if (t && t->kind == III_AST_TYPE_PTR)
                            inner = iii_ast_get(cg->ast, t->u.type_ptr.inner);
                        else if (t && t->kind == III_AST_TYPE_ARRAY)
                            inner = iii_ast_get(cg->ast, t->u.type_array.inner);
                        if (inner && inner->kind == III_AST_TYPE_REF) {
                            const uint8_t *src = iii_ast_source_buf(cg->ast);
                            iii_src_text_t in = inner->u.type_ref.name;
                            if (src && in.length <= 4) {
                                char buf[8];
                                memcpy(buf, src + in.offset, in.length);
                                buf[in.length] = 0;
                                if (strcmp(buf, "u8") == 0 || strcmp(buf, "i8") == 0 || strcmp(buf, "bool") == 0)
                                    byte_index = true;
                            }
                        }
                    }
                    /* Push base address */
                    if (iobj && iobj->kind == III_AST_EXPR_IDENT) {
                        int slot = local_lookup_slot(cg, iobj->u.ident.name);
                        if (slot >= 0) {
                            emit_line(cg, "    leaq -%d(%%rbp), %%rax", (slot + 1) * 8);
                        } else {
                            cg_write_str(cg, "    leaq ");
                            emit_decl_label(cg, iobj->u.ident.name);
                            cg_write_str(cg, "(%rip), %rax\n");
                        }
                        stack_push_reg(cg, "rax");
                    } else {
                        if (emit_expr(cg, o->u.index.object) != 0) return -1;
                    }
                    /* Push index */
                    if (emit_expr(cg, o->u.index.index_expr) != 0) return -1;
                    stack_pop_reg(cg, "rcx");
                    stack_pop_reg(cg, "rax");
                    if (byte_index)
                        emit_line(cg, "    leaq (%%rax,%%rcx,1), %%rax");
                    else
                        emit_line(cg, "    leaq (%%rax,%%rcx,8), %%rax");
                    stack_push_reg(cg, "rax");
                    return 0;
                }
                /* Fallback: take the (rvalue) and assert in codegen
                 * comments — Stage-1+ proper lvalue analysis catches
                 * misuse like `&(a + b)` at sema time. */
                if (emit_expr(cg, n->u.unary.operand) != 0) return -1;
                /* operand is on stack; the "address" is itself the
                 * top-of-stack value treated as a pointer.  Caller
                 * beware. */
                return 0;
            }
            if (emit_expr(cg, n->u.unary.operand) != 0) return -1;
            stack_pop_reg(cg, "rax");
            switch (n->u.unary.op) {
                case III_UN_NEG:   emit_line(cg, "    negq %%rax"); break;
                case III_UN_NOT:   emit_line(cg, "    testq %%rax, %%rax\n    sete %%al\n    movzbq %%al, %%rax"); break;
                case III_UN_BNOT:  emit_line(cg, "    notq %%rax"); break;
                case III_UN_DEREF: emit_line(cg, "    movq (%%rax), %%rax"); break;
                case III_UN_ADDR:  break; /* unreachable; handled above */
            }
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_CALL: {
            /* Phase 3 Step 3 STATIC CAP-FLOW CHECK (iiis-1 type-system).
             *
             * When BOTH the enclosing fn and the callee fn declare
             * `@cap_required(MASK)`, the caller's MASK_Y must be a
             * superset of the callee's MASK_X: (MASK_Y & MASK_X) == MASK_X.
             * Otherwise the caller is trying to dispatch capabilities it
             * has not declared — a structural type-system violation that
             * we reject at compile time before runtime ever sees it.
             *
             * Mandate 7 compliance: the check is purely structural —
             * static integer operations over declared metadata.  No
             * observation, no learning, no runtime state involved.
             *
             * Caller without @cap_required is permitted (runtime gate at
             * the callee's prologue still applies); the static check is
             * a TIGHTENING for fns that opt into the cap-typed regime. */
            {
                const iii_ast_node_t *callee_id = iii_ast_get(cg->ast, n->u.call.callee);
                if (callee_id && callee_id->kind == III_AST_EXPR_IDENT) {
                    uint32_t bid_chk = iii_ast_node_binder_id(cg->ast, n->u.call.callee);
                    const iii_ast_node_t *callee_decl = bid_chk ? iii_ast_get(cg->ast, bid_chk) : NULL;
                    const iii_ast_node_t *caller_decl = (cg->cur_decl_node != 0)
                        ? iii_ast_get(cg->ast, cg->cur_decl_node) : NULL;
                    if (callee_decl && callee_decl->kind == III_AST_FN_DECL &&
                        caller_decl && caller_decl->kind == III_AST_FN_DECL) {
                        uint64_t callee_mask = 0;
                        uint64_t caller_mask = 0;
                        bool callee_has = fn_modifier_extract_u64(
                            cg, callee_decl->u.fn_decl.modifiers,
                            "cap_required", 12, &callee_mask);
                        bool caller_has = fn_modifier_extract_u64(
                            cg, caller_decl->u.fn_decl.modifiers,
                            "cap_required", 12, &caller_mask);
                        if (callee_has && caller_has) {
                            if ((caller_mask & callee_mask) != callee_mask) {
                                /* Cap-flow violation: caller's mask is
                                 * insufficient to cover callee's required
                                 * rights.  Emit a compile error and
                                 * surface a comment marker in the asm so
                                 * the violation is locatable. */
                                cg->last_error = III_CG_R3_E_INTERNAL;
                                cg->error_count++;
                                cg_writef(cg,
                                    "    # III_CAP_FLOW_VIOLATION: "
                                    "caller mask 0x%llx insufficient for "
                                    "callee mask 0x%llx (missing 0x%llx)\n",
                                    (unsigned long long)caller_mask,
                                    (unsigned long long)callee_mask,
                                    (unsigned long long)(callee_mask & ~caller_mask));
                                return -1;
                            }
                        }

                        /* Phase 3 Step 3 STATIC K-BUDGET-FLOOR CHECK
                         * (iiis-1 K-value propagation).
                         *
                         * @k_max(N) declares a K-floor: the callee runs
                         * only when ctx.kchain_id has current K >= N.
                         * A caller declaring @k_max(N_A) can execute at
                         * K as low as N_A.  If it calls a callee with
                         * @k_max(N_B) and N_A < N_B, there exists an
                         * entry point where the caller has K=N_A < N_B
                         * and the callee MUST deny.  This is a
                         * structurally-unreachable success path -- the
                         * codegen rejects it as dead-on-arrival.
                         *
                         * If N_A >= N_B, every execution path has K at
                         * call time >= N_A >= N_B, so the callee's
                         * runtime check is structurally guaranteed to
                         * succeed (modulo kchain_compose intervening
                         * decreases between entry and call site; those
                         * are Stage-2+ flow-analysis concerns).
                         *
                         * Mandate 7 clean: pure integer comparison. */
                        uint64_t callee_kmin = 0;
                        uint64_t caller_kmin = 0;
                        bool callee_k = fn_modifier_extract_u64(
                            cg, callee_decl->u.fn_decl.modifiers,
                            "k_max", 5, &callee_kmin);
                        bool caller_k = fn_modifier_extract_u64(
                            cg, caller_decl->u.fn_decl.modifiers,
                            "k_max", 5, &caller_kmin);
                        if (callee_k && caller_k) {
                            if (caller_kmin < callee_kmin) {
                                cg->last_error = III_CG_R3_E_INTERNAL;
                                cg->error_count++;
                                cg_writef(cg,
                                    "    # III_K_FLOOR_VIOLATION: "
                                    "caller floor %llu below callee "
                                    "floor %llu (deficit %llu)\n",
                                    (unsigned long long)caller_kmin,
                                    (unsigned long long)callee_kmin,
                                    (unsigned long long)(callee_kmin - caller_kmin));
                                return -1;
                            }
                        }
                    }

                    /* Phase 3 Step 3 STATIC INTENT-KIND CHECK (iiis-1
                     * first-class intent types).
                     *
                     * When a callee fn parameter declares an inline
                     * `@hexad_kind(K_p)` annotation on the parameter's
                     * type expression, AND the actual argument is an
                     * ident bound to a let/param/var whose declared
                     * type also carries `@hexad_kind(K_a)`, the kinds
                     * MUST match.  Mismatches are rejected at codegen
                     * with the marker `III_INTENT_KIND_VIOLATION`.
                     *
                     * Args that are literals, non-ident exprs, or whose
                     * binding type has no kind annotation are NOT
                     * rejected by this static check -- the runtime gate
                     * at the callee (via `ctx.hexad_kind`) still
                     * applies.  This is a TIGHTENING for explicitly
                     * typed flows; legacy untyped flows are unaffected.
                     *
                     * Mandate 7 clean: pure structural integer-equality
                     * check over declared metadata. */
                    if (callee_decl && callee_decl->kind == III_AST_FN_DECL) {
                        iii_ast_list_t params = callee_decl->u.fn_decl.params;
                        iii_ast_list_t args   = n->u.call.args;
                        uint32_t check_count = (params.count < args.count)
                            ? params.count : args.count;
                        for (uint32_t i = 0; i < check_count; i++) {
                            uint32_t pid = iii_ast_list_at(cg->ast, params, i);
                            const iii_ast_node_t *param = iii_ast_get(cg->ast, pid);
                            if (!param || param->kind != III_AST_PARAM) continue;
                            const iii_ast_node_t *ptype =
                                iii_ast_get(cg->ast, param->u.param.type_node);
                            if (!ptype || ptype->kind != III_AST_TYPE_REF) continue;
                            uint64_t pkind = 0;
                            /* iiis-2 type-alias chase: try inline modifiers
                             * first; if not found, resolve TYPE_REF to its
                             * TYPE_DECL and check that decl's annotations. */
                            if (!type_node_extract_u64(
                                    cg, param->u.param.type_node,
                                    "hexad_kind", 10, &pkind))
                                continue;

                            uint32_t aid = iii_ast_list_at(cg->ast, args, i);
                            const iii_ast_node_t *arg = iii_ast_get(cg->ast, aid);
                            if (!arg || arg->kind != III_AST_ARG) continue;
                            uint32_t aexpr = arg->u.arg.value_expr;
                            const iii_ast_node_t *avex = iii_ast_get(cg->ast, aexpr);
                            if (!avex) continue;
                            uint64_t akind = 0;
                            bool akind_known = false;
                            if (avex->kind == III_AST_EXPR_IDENT) {
                                uint32_t abid = iii_ast_node_binder_id(cg->ast, aexpr);
                                const iii_ast_node_t *abinder = abid
                                    ? iii_ast_get(cg->ast, abid) : NULL;
                                if (!abinder) continue;
                                uint32_t arg_type_node = 0;
                                if (abinder->kind == III_AST_STMT_LET)
                                    arg_type_node = abinder->u.let_.type_node;
                                else if (abinder->kind == III_AST_PARAM)
                                    arg_type_node = abinder->u.param.type_node;
                                else if (abinder->kind == III_AST_VAR_DECL)
                                    arg_type_node = abinder->u.var_decl.type_node;
                                else continue;
                                const iii_ast_node_t *atype =
                                    iii_ast_get(cg->ast, arg_type_node);
                                if (!atype || atype->kind != III_AST_TYPE_REF)
                                    continue;
                                /* iiis-2 type-alias chase. */
                                if (!type_node_extract_u64(
                                        cg, arg_type_node,
                                        "hexad_kind", 10, &akind))
                                    continue;
                                akind_known = true;
                            } else if (avex->kind == III_AST_EXPR_CALL) {
                                /* Phase 3 Step 3 cross-check: when the arg
                                 * is a direct CALL whose callee declares
                                 * `@returns_hexad(K_r)`, propagate K_r as
                                 * the effective kind of the arg.  This
                                 * closes the gap between
                                 * `let x = fn_with_return_kind(); call(...x)`
                                 * (covered by binding-type check) and
                                 * `call(fn_with_return_kind())` (covered
                                 * here without intermediate binding). */
                                const iii_ast_node_t *inner_callee_id =
                                    iii_ast_get(cg->ast, avex->u.call.callee);
                                if (!inner_callee_id ||
                                    inner_callee_id->kind != III_AST_EXPR_IDENT)
                                    continue;
                                uint32_t inner_bid = iii_ast_node_binder_id(
                                    cg->ast, avex->u.call.callee);
                                const iii_ast_node_t *inner_decl = inner_bid
                                    ? iii_ast_get(cg->ast, inner_bid) : NULL;
                                if (!inner_decl ||
                                    inner_decl->kind != III_AST_FN_DECL)
                                    continue;
                                if (!fn_modifier_extract_u64(
                                        cg, inner_decl->u.fn_decl.modifiers,
                                        "returns_hexad", 13, &akind))
                                    continue;
                                akind_known = true;
                            }
                            if (!akind_known) continue;
                            if (akind != pkind) {
                                cg->last_error = III_CG_R3_E_INTERNAL;
                                cg->error_count++;
                                cg_writef(cg,
                                    "    # III_INTENT_KIND_VIOLATION: "
                                    "arg %u kind 0x%llx does not match "
                                    "param kind 0x%llx\n",
                                    (unsigned)i,
                                    (unsigned long long)akind,
                                    (unsigned long long)pkind);
                                return -1;
                            }
                        }
                    }
                }
            }

            /* Phase C.6 PE: try static-intent narrowing before the
             * generic call emission. When the callee is `resolve` and
             * the intent argument is provably static (constructed by
             * intent_form/intent_act/intent_convey with a literal that
             * matches PE_TABLE), replace the call with a direct
             * `leaq <dispatch_fp>(%rip), %rax; pushq %rax`. */
            {
                const iii_ast_node_t *pe_callee = iii_ast_get(cg->ast, n->u.call.callee);
                if (pe_callee && pe_callee->kind == III_AST_EXPR_IDENT) {
                    const uint8_t *psrc = iii_ast_source_buf(cg->ast);
                    iii_src_text_t pcn = pe_callee->u.ident.name;
                    if (psrc && pcn.length == 7 && memcmp(psrc + pcn.offset, "resolve", 7) == 0) {
                        if (n->u.call.args.count == 3) {
                            uint32_t intent_arg_id = iii_ast_list_at(cg->ast, n->u.call.args, 1);
                            const char *fn_name = NULL;
                            if (cg_r3_pe_classify_intent_arg(cg, intent_arg_id, &fn_name) == 1
                                    && fn_name != NULL) {
                                /* Static-intent shortcut. Skip the entire
                                 * runtime resolve() dispatch chain. */
                                return cg_r3_pe_emit_direct_load(cg, fn_name);
                            }
                        }
                    }
                }
            }
            /* MS x64 ABI §6.4: caller passes args in rcx,rdx,r8,r9
             * then on the stack at [rsp+0x20+]; allocates 32 bytes of
             * shadow space; rsp must be 16-aligned at the CALL site.
             *
             * Strategy:
             *   1. Compute alignment pad up-front and push it FIRST,
             *      so the stack args we leave behind don't get
             *      displaced by a late pad.
             *   2. Evaluate args in REVERSE source order — arg1 ends
             *      up on top of stack (popped first into rcx), arg2
             *      next (rdx), arg3 (r8), arg4 (r9), and arg5..argN
             *      are left on stack with arg5 nearest the top.
             *   3. Sub $0x20 shadow.  Now [rsp+0x20+i*8] = arg(5+i)
             *      exactly as the ABI requires.
             *   4. After call, addq $0x20 (unshadow) +
             *      addq $stack_args*8 (discard stack args) +
             *      addq $8 if pad.
             *
             * Reverse arg-eval is permitted: III makes no guarantee
             * about left-to-right argument evaluation order. */
            uint32_t arg_count = n->u.call.args.count;
            uint32_t reg_args  = arg_count > 4u ? 4u : arg_count;
            uint32_t stack_args = (arg_count > 4u) ? (arg_count - 4u) : 0u;
            uint32_t shadow_slots = III_CG_R3_SHADOW_BYTES / 8u;  /* = 4 */
            uint32_t pre_call_stack = cg->stack_depth;
            /* At call time: depth = pre + pad + stack_args + shadow_slots.
             * shadow_slots is even (4), so need (pre + pad + stack_args) even. */
            uint32_t align_pad = ((pre_call_stack + stack_args) & 1u) ? 1u : 0u;
            if (align_pad) {
                emit_line(cg, "    subq $8, %%rsp");
                cg->stack_depth += 1;
            }
            for (int32_t i = (int32_t)arg_count - 1; i >= 0; i--) {
                uint32_t aid = iii_ast_list_at(cg->ast, n->u.call.args, (uint32_t)i);
                const iii_ast_node_t *a = iii_ast_get(cg->ast, aid);
                if (a && a->kind == III_AST_ARG) {
                    if (emit_expr(cg, a->u.arg.value_expr) != 0) return -1;
                }
            }
            const char *abi_regs[4] = { "rcx", "rdx", "r8", "r9" };
            for (uint32_t i = 0; i < reg_args; i++) {
                stack_pop_reg(cg, abi_regs[i]);
            }
            emit_line(cg, "    subq $%u, %%rsp",
                      (unsigned)III_CG_R3_SHADOW_BYTES);
            cg->stack_depth += shadow_slots;
            /* D1: assert ABI alignment immediately before CALL emission. */
            (void)abi_assert_call_alignment(cg, cg->stack_depth);
            /* Resolve the callee.  Three cases:
             *   1. EXPR_IDENT bound to FN_DECL/EXTERN_DECL: direct call
             *   2. EXPR_IDENT bound to a local/var (function pointer):
             *      load the value as an address and indirect-call
             *   3. Any other expression: evaluate, take TOS as ptr,
             *      indirect-call (closure / member-fn / etc.)
             *
             * Phase C.6 multi-statement narrowing: case 2's local-bound
             * fn-pointer can be elided to a 5-byte direct callq when
             * the slot was previously recorded as statically-resolved
             * (via STMT_LET seeing a `let fp = resolve(set, intent, ctx)`
             * with static intent). The recorded fn_name is consulted
             * via cg_r3_pe_get_static_fp(); a non-NULL result means we
             * can bypass the indirect dispatch entirely. */
            const iii_ast_node_t *callee = iii_ast_get(cg->ast, n->u.call.callee);
            bool direct_call = false;
            bool pe_direct_call = false;       /* Phase C.6: PE-narrowed local */
            const char *pe_direct_fn = NULL;   /* Phase C.6: target fn_name */
            if (callee && callee->kind == III_AST_EXPR_IDENT) {
                int slot = local_lookup_slot(cg, callee->u.ident.name);
                if (slot < 0) {
                    /* No local — assume it's a top-level fn/extern decl. */
                    direct_call = true;
                } else {
                    /* Phase C.6 multi-statement narrowing: callee is a
                     * local; check the static_fp map. If recorded, the
                     * local holds a statically-known dispatch fn — emit
                     * a direct callq rather than load+callq*. */
                    const char *fn = cg_r3_pe_get_static_fp(cg, (uint32_t)slot);
                    if (fn != NULL) {
                        pe_direct_call = true;
                        pe_direct_fn = fn;
                    }
                }
            }
            /* Detect extern: extern symbols link from libc / win32 /
             * kernel-side namespaces and MUST be emitted UNPREFIXED
             * (no `L_` prefix).  Sema sets binder_id to the decl_node
             * for top-level decls; inspect the kind to decide.
             *
             * Cross-TU iii→iii calls also use the unprefixed form when
             * the callee's FN_DECL carries @export — the callee's
             * definition emits unmangled so we must too. */
            bool extern_call = false;
            bool exported_call = false;
            uint32_t callee_return_type = 0;
            if (direct_call) {
                uint32_t bid = iii_ast_node_binder_id(cg->ast, n->u.call.callee);
                const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
                if (binder && binder->kind == III_AST_EXTERN_DECL) {
                    extern_call = true;
                    callee_return_type = binder->u.extern_decl.return_type;
                } else if (binder && binder->kind == III_AST_FN_DECL) {
                    if (fn_modifiers_contain(cg, binder->u.fn_decl.modifiers,
                                             "export", 6)) {
                        exported_call = true;
                    }
                    callee_return_type = binder->u.fn_decl.return_type;
                }
            }
            if (pe_direct_call) {
                /* Phase C.6 multi-statement narrowing: emit a 5-byte
                 * direct callq (E8 rel32) to the recorded dispatch fn,
                 * eliding the indirect dispatch entirely. The
                 * dispatch_fp_name table in iii_compositions.h
                 * always references unmangled symbols (sha256_oneshot,
                 * x25519, etc.) — these are linked from STDLIB extern
                 * decls and do not carry the L_ prefix. */
                cg_write_str(cg, "    # III_PE_DIRECT_CALL ");
                cg_write_str(cg, pe_direct_fn);
                cg_write_char(cg, '\n');
                cg_write_str(cg, "    callq ");
                cg_write_str(cg, pe_direct_fn);
                cg_write_char(cg, '\n');
            } else if (direct_call) {
                cg_write_str(cg, "    callq ");
                if (extern_call || exported_call) {
                    /* Raw symbol name, no L_ prefix. */
                    emit_raw_symbol(cg, callee->u.ident.name);
                } else {
                    emit_decl_label(cg, callee->u.ident.name);
                }
                cg_write_char(cg, '\n');
            } else {
                if (emit_expr(cg, n->u.call.callee) != 0) return -1;
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    callq *%%rax");
            }
            emit_line(cg, "    addq $%u, %%rsp",
                      (unsigned)III_CG_R3_SHADOW_BYTES);
            cg->stack_depth -= shadow_slots;
            if (align_pad) {
                emit_line(cg, "    addq $8, %%rsp");
                cg->stack_depth -= 1;
            }
            if (stack_args > 0u) {
                emit_line(cg, "    addq $%u, %%rsp",
                          (unsigned)(stack_args * 8u));
                cg->stack_depth -= stack_args;
            }
            /* MS x64 ABI: callees that declare a return type narrower
             * than 64 bits are NOT required to clear the high bits of
             * RAX (gcc routinely leaves struct-return high half intact
             * even when only the low half is the formal return value).
             * iiis-0 stores RAX as 8 bytes everywhere, so a uint32_t
             * return with a junk high half corrupts every downstream
             * u32 sink.  Zero/sign-extend at the boundary based on the
             * callee's declared return type. */
            if (callee_return_type != 0) {
                const iii_ast_node_t *rt = iii_ast_get(cg->ast, callee_return_type);
                if (rt && rt->kind == III_AST_TYPE_REF) {
                    const uint8_t *src = iii_ast_source_buf(cg->ast);
                    iii_src_text_t nm = rt->u.type_ref.name;
                    if (src && nm.length <= 8) {
                        char buf[16];
                        for (uint32_t i = 0; i < nm.length; i++) buf[i] = (char)src[nm.offset + i];
                        buf[nm.length] = 0;
                        if (strcmp(buf, "u8") == 0 || strcmp(buf, "bool") == 0) {
                            emit_line(cg, "    movzbq %%al, %%rax");
                        } else if (strcmp(buf, "i8") == 0) {
                            emit_line(cg, "    movsbq %%al, %%rax");
                        } else if (strcmp(buf, "u16") == 0) {
                            emit_line(cg, "    movzwq %%ax, %%rax");
                        } else if (strcmp(buf, "i16") == 0) {
                            emit_line(cg, "    movswq %%ax, %%rax");
                        } else if (strcmp(buf, "u32") == 0) {
                            emit_line(cg, "    movl %%eax, %%eax");
                        } else if (strcmp(buf, "i32") == 0) {
                            emit_line(cg, "    movslq %%eax, %%rax");
                        }
                        /* u64/i64/usize/isize/Phase/ptr: full 64-bit, no-op. */
                    }
                }
            }
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_BLOCK:
            return emit_block(cg, node);
        case III_AST_EXPR_FIELD: {
            const iii_ast_node_t *obj = iii_ast_get(cg->ast, n->u.field.object);
            if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                cg->last_error = III_CG_R3_E_UNSUPPORTED;
                cg->error_count++;
                return -1;
            }
            /* F8.5 — if the object is a local variable whose declared
             * type is a struct, compute the field's stack offset and
             * load the value.  Otherwise fall back to the legacy
             * flat-globals path (`L_<obj>__<field>`) for compatibility
             * with sources that pre-translate fields to globals. */
            int base_slot = local_lookup_slot(cg, obj->u.ident.name);
            if (base_slot >= 0 && cg->sema) {
                /* We don't yet track per-local types; do a lookup of
                 * the IDENT's binder via sema's binder_id side-table.
                 * For locals, sema sets binder_id to the AST node of
                 * the let stmt.  The let's type_node tells us the
                 * declared type. */
                uint32_t obj_node = n->u.field.object;
                uint32_t bid = iii_ast_node_binder_id(cg->ast, obj_node);
                const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
                uint32_t type_node = 0;
                if (binder && binder->kind == III_AST_STMT_LET)   type_node = binder->u.let_.type_node;
                else if (binder && binder->kind == III_AST_PARAM) type_node = binder->u.param.type_node;
                const iii_ast_node_t *type_n = type_node ? iii_ast_get(cg->ast, type_node) : NULL;
                if (type_n && type_n->kind == III_AST_TYPE_REF) {
                    const uint8_t *src = iii_ast_source_buf(cg->ast);
                    iii_src_text_t tname = type_n->u.type_ref.name;
                    if (src && tname.length < 64) {
                        char tnm[64];
                        memcpy(tnm, src + tname.offset, tname.length);
                        tnm[tname.length] = 0;
                        uint32_t struct_decl = iii_sema_struct_decl_for_name(cg->sema, tnm);
                        if (struct_decl != 0) {
                            iii_src_text_t fname = n->u.field.field_name;
                            char fnm[64];
                            if (src && fname.length < 64) {
                                memcpy(fnm, src + fname.offset, fname.length);
                                fnm[fname.length] = 0;
                                int32_t field_off = iii_sema_struct_field_slot(cg->sema, struct_decl, fnm);
                                if (field_off >= 0) {
                                    /* Local at -((base_slot + 1) * 8); field at
                                     * an offset of `field_off` slots BEYOND the
                                     * base.  Field N → -((base_slot + 1 + N) * 8). */
                                    emit_line(cg, "    movq -%d(%%rbp), %%rax",
                                                (base_slot + 1 + (int)field_off) * 8);
                                    stack_push_reg(cg, "rax");
                                    return 0;
                                }
                            }
                        }
                    }
                }
            }
            cg_write_str(cg, "    leaq ");
            if (emit_field_label(cg, obj, n->u.field.field_name) != 0) {
                cg->last_error = III_CG_R3_E_UNSUPPORTED;
                cg->error_count++;
                return -1;
            }
            cg_write_str(cg, "(%rip), %rax\n");
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_INDEX: {
            /* Element width discipline:
             *   - If the object is a string literal (EXPR_STR): u8 bytes,
             *     scale=1 + movzbq.
             *   - If the object is an EXPR_IDENT whose binder declares
             *     a `*u8` (TYPE_PTR with inner u8): scale=1 + movzbq.
             *   - Otherwise: u64 words, scale=8 + movq.
             *
             * F-A1 ADR-B12: explicit type-driven dispatch.  The
             * ident's binder is fetched via iii_ast_node_binder_id;
             * the binder's declared type is inspected through
             * TYPE_PTR.inner → TYPE_REF.name == "u8" / "i8" / "bool".
             * Stage-2+ widens to per-element-width tracking via a
             * full type kernel; until then this two-class dispatch
             * unblocks all C-port heap-byte access patterns. */
            const iii_ast_node_t *obj = iii_ast_get(cg->ast, n->u.index.object);
            bool byte_index = (obj && obj->kind == III_AST_EXPR_STR);
            if (!byte_index && obj && obj->kind == III_AST_EXPR_IDENT) {
                uint32_t obj_node = n->u.index.object;
                uint32_t bid = iii_ast_node_binder_id(cg->ast, obj_node);
                const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
                uint32_t tnode = 0;
                if (binder && binder->kind == III_AST_STMT_LET)   tnode = binder->u.let_.type_node;
                else if (binder && binder->kind == III_AST_PARAM) tnode = binder->u.param.type_node;
                else if (binder && binder->kind == III_AST_VAR_DECL) tnode = binder->u.var_decl.type_node;
                const iii_ast_node_t *t = tnode ? iii_ast_get(cg->ast, tnode) : NULL;
                /* Pointer-to-byte case: TYPE_PTR with inner TYPE_REF "u8"/"i8"/"bool". */
                if (t && t->kind == III_AST_TYPE_PTR) {
                    const iii_ast_node_t *inner = iii_ast_get(cg->ast, t->u.type_ptr.inner);
                    if (inner && inner->kind == III_AST_TYPE_REF) {
                        const uint8_t *src = iii_ast_source_buf(cg->ast);
                        iii_src_text_t in = inner->u.type_ref.name;
                        if (src && in.length <= 4) {
                            char buf[8];
                            memcpy(buf, src + in.offset, in.length);
                            buf[in.length] = 0;
                            if (strcmp(buf, "u8") == 0 || strcmp(buf, "i8") == 0 || strcmp(buf, "bool") == 0) {
                                byte_index = true;
                            }
                        }
                    }
                }
                /* Array-of-byte case: TYPE_ARRAY with inner u8/i8/bool. */
                if (!byte_index && t && t->kind == III_AST_TYPE_ARRAY) {
                    const iii_ast_node_t *inner = iii_ast_get(cg->ast, t->u.type_array.inner);
                    if (inner && inner->kind == III_AST_TYPE_REF) {
                        const uint8_t *src = iii_ast_source_buf(cg->ast);
                        iii_src_text_t in = inner->u.type_ref.name;
                        if (src && in.length <= 4) {
                            char buf[8];
                            memcpy(buf, src + in.offset, in.length);
                            buf[in.length] = 0;
                            if (strcmp(buf, "u8") == 0 || strcmp(buf, "i8") == 0 || strcmp(buf, "bool") == 0) {
                                byte_index = true;
                            }
                        }
                    }
                }
            }
            /* Width-aware indexed read.  Uses pointer_element_width to
             * pick 1/2/4/8-byte access; falls back to the legacy
             * 8-byte movq when the element type cannot be determined. */
            int el_width = pointer_element_width(cg, n->u.index.object);
            bool el_signed = element_is_signed_int(cg, n->u.index.object);
            if (emit_expr(cg, n->u.index.object) != 0) return -1;
            if (emit_expr(cg, n->u.index.index_expr) != 0) return -1;
            stack_pop_reg(cg, "rcx");  /* index */
            stack_pop_reg(cg, "rax");  /* object base */
            if (byte_index || el_width == 1) {
                if (el_signed) emit_line(cg, "    movsbq (%%rax,%%rcx,1), %%rax");
                else           emit_line(cg, "    movzbq (%%rax,%%rcx,1), %%rax");
            } else if (el_width == 2) {
                if (el_signed) emit_line(cg, "    movswq (%%rax,%%rcx,2), %%rax");
                else           emit_line(cg, "    movzwq (%%rax,%%rcx,2), %%rax");
            } else if (el_width == 4) {
                if (el_signed) emit_line(cg, "    movslq (%%rax,%%rcx,4), %%rax");
                else           emit_line(cg, "    movl (%%rax,%%rcx,4), %%eax");
            } else {
                emit_line(cg, "    movq (%%rax,%%rcx,8), %%rax");
            }
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_STR: {
            emit_line(cg, "    leaq L_str_%u(%%rip), %%rax",
                      (unsigned)n->u.str_.string_payload_idx);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_HEXAD: {
            uint16_t packed = pack_hexad_trits(n->u.hexad_.trits);
            emit_line(cg, "    movabsq $0x%x, %%rax", (unsigned)packed);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_MHASH: {
            cg_write_str(cg, "    .section .rodata\n");
            emit_mhash_data_label(cg, node, n->u.mhash_.mhash);
            cg_write_str(cg, "    .text\n");
            emit_line(cg, "    leaq L_mhash_%u(%%rip), %%rax", (unsigned)node);
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_RAW_ASM: {
            uint32_t off = n->u.raw_asm.raw_asm_str_idx;
            uint32_t len = n->u.raw_asm.raw_asm_len;
            if (off + len <= iii_ast_source_len(cg->ast)) {
                cg_write_bytes(cg, iii_ast_source_buf(cg->ast) + off, len);
                cg_write_char(cg, '\n');
            }
            emit_line(cg, "    movq $0, %%rax");
            stack_push_reg(cg, "rax");
            return 0;
        }
        case III_AST_EXPR_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_expr.arms.count;
            if (emit_expr(cg, n->u.match_expr.scrutinee) != 0) return -1;
            stack_pop_reg(cg, "rax");
            uint32_t scrut_slot = cg->local_count;
            cg->local_count++;
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
                    stack_pop_reg(cg, "rax");
                    emit_line(cg, "    testq %%rax, %%rax");
                    emit_line(cg, "    jz L_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) return -1;
                emit_line(cg, "    jmp L_match_end_%u", (unsigned)end_lbl);
                if (label_define(cg, skip_lbl) != 0) return -1;
                emit_line(cg, "L_skip_%u:", (unsigned)skip_lbl);
            }
            emit_line(cg, "    movq $0, %%rax");
            stack_push_reg(cg, "rax");
            if (label_define(cg, end_lbl) != 0) return -1;
            emit_line(cg, "L_match_end_%u:", (unsigned)end_lbl);
            return 0;
        }
        default:
            cg->last_error = III_CG_R3_E_UNSUPPORTED;
            cg->error_count++;
            return -1;
    }
}

/* ─── Statement codegen ───────────────────────────────────────────── */

static int emit_stmt(iii_cg_r3_state_t *cg, uint32_t node)
{
    if (node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(cg->ast, node);
    if (!n) return -1;
    int rc = 0;
    switch (n->kind) {
        case III_AST_STMT_LET: {
            /* F8.5 — if the let's declared type is a TYPE_REF whose
             * name resolves to a STRUCT_DECL, reserve N slots for the
             * struct instance.  If value_expr is 0 (no initializer),
             * we leave the slots zero-uninitialised (they're inside
             * the 1024-byte locals reserve which is not zeroed in the
             * prologue; consumers must field-write before reading).
             * Stage-2+ adds proper initializer expressions for structs. */
            const iii_ast_node_t *let_type = iii_ast_get(cg->ast, n->u.let_.type_node);
            /* Phase 3 Step 1: local [T; N] array support.  When the let's
             * type is TYPE_ARRAY, reserve ceil(N*sizeof(T)/8) adjacent
             * slots within the 1024-byte locals reserve.  No initializer
             * is required; the slots remain zero from the prior call's
             * SP movement (cleared by `subq $1024, %rsp` only if
             * downstream relies on it — for now uninit until written). */
            if (let_type && let_type->kind == III_AST_TYPE_ARRAY) {
                uint32_t elem_count = (uint32_t)let_type->u.type_array.count;
                int elem_width = pointer_element_width_for_inner(cg, let_type->u.type_array.inner);
                uint32_t total_bytes = elem_count * (uint32_t)elem_width;
                uint32_t total_slots = (total_bytes + 7u) / 8u;
                if (total_slots == 0) total_slots = 1;
                /* [array-frame-fix] Reserve the (nslots-1) EXTRA slots FIRST, then add the named
                 * local LAST, so the array IDENT resolves to the BOTTOM slot of its reserved
                 * region.  The existing array-decay `leaq -(slot+1)*8(%rbp)` then computes a[0]'s
                 * address = the region base, so a[i]=base+i*stride grows UP through the reserved
                 * region instead of UP PAST %rbp (which smashed the saved rbp + return address --
                 * the local-array runtime-index SEGFAULT).  Mirrored byte-identically in cg_r3.iii. */
                for (uint32_t extra = 1; extra < total_slots; extra++) {
                    cg->local_count++;
                }
                local_add(cg, n->u.let_.name);
                /* No initializer for array lets is permitted; if one
                 * was supplied (e.g. `let buf : [u8;16] = [0u8; 16]`)
                 * evaluate-and-discard.  Repeat-initializer codegen is
                 * Stage-2+ work. */
                if (n->u.let_.value_expr != 0) {
                    if (emit_expr(cg, n->u.let_.value_expr) != 0) { rc = -1; break; }
                    stack_pop_reg(cg, "rax");
                }
                break;
            }
            if (let_type && let_type->kind == III_AST_TYPE_REF && cg->sema) {
                /* Resolve the type name to a STRUCT_DECL via sema. */
                const uint8_t *src = iii_ast_source_buf(cg->ast);
                if (src && let_type->u.type_ref.name.length < 64) {
                    char tmp[64];
                    uint32_t nl = let_type->u.type_ref.name.length;
                    memcpy(tmp, src + let_type->u.type_ref.name.offset, nl);
                    tmp[nl] = 0;
                    uint32_t struct_decl = iii_sema_struct_decl_for_name(cg->sema, tmp);
                    if (struct_decl != 0) {
                        uint32_t nslots = iii_sema_struct_size_slots(cg->sema, struct_decl);
                        if (nslots > 0) {
                            /* Reserve nslots locals starting at the next slot.  The
                             * binder name gets the first slot (0); fields are at
                             * +0, +1, ..., +(nslots-1). */
                            local_add(cg, n->u.let_.name);
                            uint32_t base_slot = cg->local_count - 1u;
                            for (uint32_t extra = 1; extra < nslots; extra++) {
                                cg->local_count++;     /* reserve adjacent slots */
                            }
                            (void)base_slot;
                            /* No initializer: leave slots uninitialised.
                             * If value_expr is set, it would need to be a
                             * struct-shaped initializer (Stage-2+).  For
                             * now skip evaluation. */
                            if (n->u.let_.value_expr != 0) {
                                /* Evaluate and discard the initializer to
                                 * preserve side effects. */
                                if (emit_expr(cg, n->u.let_.value_expr) != 0) { rc = -1; break; }
                                stack_pop_reg(cg, "rax");
                            }
                            break;
                        }
                    }
                }
            }
            /* Phase 3 Step 3 STATIC RETURN-KIND CHECK (iiis-1 fourth
             * propagation rule).
             *
             * When this let-binding's type declares `@hexad_kind(K_l)`
             * AND the value expression is a direct call to a fn whose
             * declaration carries `@returns_hexad(K_r)`, codegen
             * asserts `K_l == K_r`.  Mismatch → rc=14 with marker
             * `# III_RETURN_KIND_VIOLATION: let kind 0xK_l does not
             * match callee return kind 0xK_r`.
             *
             * Why `@returns_hexad` rather than overloading
             * `@hexad_kind`?  `@hexad_kind` on a fn-level annotation
             * means "ctx.hexad_kind must equal K at entry" (a CALLER
             * gate).  `@returns_hexad` means "the returned value's
             * kind is K" (a CALLEE assertion about its output).
             * Distinct semantics → distinct names.
             *
             * Mandate 7 clean: pure integer equality. */
            if (let_type && let_type->kind == III_AST_TYPE_REF
                && n->u.let_.value_expr != 0) {
                uint64_t let_kind = 0;
                /* iiis-2 type-alias chase for the let's declared type. */
                if (type_node_extract_u64(
                        cg, n->u.let_.type_node,
                        "hexad_kind", 10, &let_kind)) {
                    const iii_ast_node_t *init =
                        iii_ast_get(cg->ast, n->u.let_.value_expr);
                    if (init && init->kind == III_AST_EXPR_CALL) {
                        const iii_ast_node_t *icallee =
                            iii_ast_get(cg->ast, init->u.call.callee);
                        if (icallee && icallee->kind == III_AST_EXPR_IDENT) {
                            uint32_t bid_rk = iii_ast_node_binder_id(
                                cg->ast, init->u.call.callee);
                            const iii_ast_node_t *cdecl = bid_rk
                                ? iii_ast_get(cg->ast, bid_rk) : NULL;
                            if (cdecl && cdecl->kind == III_AST_FN_DECL) {
                                uint64_t ret_kind = 0;
                                if (fn_modifier_extract_u64(
                                        cg, cdecl->u.fn_decl.modifiers,
                                        "returns_hexad", 13, &ret_kind)) {
                                    if (let_kind != ret_kind) {
                                        cg->last_error = III_CG_R3_E_INTERNAL;
                                        cg->error_count++;
                                        cg_writef(cg,
                                            "    # III_RETURN_KIND_VIOLATION: "
                                            "let kind 0x%llx does not match "
                                            "callee return kind 0x%llx\n",
                                            (unsigned long long)let_kind,
                                            (unsigned long long)ret_kind);
                                        rc = -1; break;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (emit_expr(cg, n->u.let_.value_expr) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            local_add(cg, n->u.let_.name);
            uint32_t slot = cg->local_count - 1u;
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (slot + 1) * 8);
            /* Phase C.6 multi-statement narrowing: detect a let whose
             * initializer is a static-resolvable resolve() call and
             * record the slot -> dispatch-fn mapping. The PE in
             * EXPR_CALL has already replaced the runtime resolve() with
             * a `leaq <fn>(%rip), %rax` direct load (so the slot now
             * holds the function-pointer value), but we additionally
             * record the symbol so any later EXPR_CALL whose callee is
             * THIS local can be lowered to a 5-byte direct callq.
             *
             * Mandate 1 (K-Value Chain): the slot holds the same value
             * regardless of whether the indirect-call elision fires; we
             * preserve the runtime contract under all PE outcomes.
             * Mandate 7 (Win-Win): pure compile-time narrowing, no
             * thresholds. */
            if (n->u.let_.value_expr != 0) {
                const iii_ast_node_t *init = iii_ast_get(cg->ast,
                                                         n->u.let_.value_expr);
                if (init && init->kind == III_AST_EXPR_CALL) {
                    const iii_ast_node_t *icallee = iii_ast_get(cg->ast,
                                                                init->u.call.callee);
                    if (icallee && icallee->kind == III_AST_EXPR_IDENT) {
                        const uint8_t *isrc = iii_ast_source_buf(cg->ast);
                        iii_src_text_t icn = icallee->u.ident.name;
                        if (isrc && icn.length == 7
                                && memcmp(isrc + icn.offset, "resolve", 7) == 0
                                && init->u.call.args.count == 3) {
                            uint32_t intent_arg_id = iii_ast_list_at(
                                cg->ast, init->u.call.args, 1);
                            const char *fn_name = NULL;
                            if (cg_r3_pe_classify_intent_arg(
                                    cg, intent_arg_id, &fn_name) == 1
                                    && fn_name != NULL) {
                                cg_r3_pe_record_static_fp(cg, slot, fn_name);
                                cg_writef(cg,
                                    "    # III_PE_RECORD slot=%u -> %s\n",
                                    (unsigned)slot, fn_name);
                            }
                        }
                    }
                }
            }
            break;
        }
        case III_AST_STMT_EXPR: {
            if (emit_expr(cg, n->u.expr_stmt.expr) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            break;
        }
        case III_AST_STMT_RETURN: {
            if (n->u.return_.value_expr != 0) {
                if (emit_expr(cg, n->u.return_.value_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
            } else {
                emit_line(cg, "    movq $0, %%rax");
            }
            /* D8: cycle witness exit marker fires before epilogue. */
            if (cg->cur_is_cycle) {
                cg_write_str(cg, "    # III_CYCLE_WITNESS_EXIT\n");
            }
            emit_line(cg, "    movq %%rbp, %%rsp");
            emit_line(cg, "    popq %%rbp");
            emit_line(cg, "    retq");
            break;
        }
        case III_AST_STMT_ASSIGN: {
            const iii_ast_node_t *lv = iii_ast_get(cg->ast, n->u.assign.lvalue_expr);
            if (!lv) { rc = -1; break; }
            if (lv->kind == III_AST_EXPR_IDENT) {
                /* If the ident resolves to a top-level VAR_DECL, emit a
                 * global store via the symbol address.  Otherwise (or
                 * if no binder is set), treat as a local store, adding
                 * the local if it's a fresh name (Stage-0 implicit
                 * declaration). */
                uint32_t bid = iii_ast_node_binder_id(cg->ast,
                                  n->u.assign.lvalue_expr);
                const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
                if (binder && binder->kind == III_AST_VAR_DECL) {
                    if (emit_expr(cg, n->u.assign.value_expr) != 0) { rc = -1; break; }
                    stack_pop_reg(cg, "rax");
                    /* Width-aware store: probe the var's declared type
                     * and emit movb/movw/movl/movq with the matching
                     * register name.  Without this, all global stores
                     * use movq (8 bytes) -- writing 7 bytes of garbage
                     * into adjacent BSS for any u8/u16/u32 var.  This
                     * is the root cause of the call_context_init_set
                     * SEGV (3 consecutive u8 vars, each store overflows
                     * its successors). */
                    const char *src_reg = "%rax";
                    const iii_ast_node_t *t = iii_ast_get(cg->ast, binder->u.var_decl.type_node);
                    /* Default width: 8 bytes (movq). */
                    const char *mov_op = "movq";
                    if (t && t->kind == III_AST_TYPE_REF) {
                        const uint8_t *src = iii_ast_source_buf(cg->ast);
                        iii_src_text_t tn = t->u.type_ref.name;
                        if (src && tn.length <= 6) {
                            char tbuf[8];
                            memcpy(tbuf, src + tn.offset, tn.length);
                            tbuf[tn.length] = 0;
                            if (strcmp(tbuf, "u8") == 0 || strcmp(tbuf, "i8") == 0 || strcmp(tbuf, "bool") == 0) {
                                mov_op = "movb"; src_reg = "%al";
                            } else if (strcmp(tbuf, "u16") == 0 || strcmp(tbuf, "i16") == 0) {
                                mov_op = "movw"; src_reg = "%ax";
                            } else if (strcmp(tbuf, "u32") == 0 || strcmp(tbuf, "i32") == 0) {
                                mov_op = "movl"; src_reg = "%eax";
                            }
                        }
                    }
                    cg_write_str(cg, "    ");
                    cg_write_str(cg, mov_op);
                    cg_write_str(cg, " ");
                    cg_write_str(cg, src_reg);
                    cg_write_str(cg, ", ");
                    emit_decl_label(cg, lv->u.ident.name);
                    cg_write_str(cg, "(%rip)\n");
                    break;
                }
                int slot = local_lookup_slot(cg, lv->u.ident.name);
                if (slot < 0) {
                    local_add(cg, lv->u.ident.name);
                    slot = (int)(cg->local_count - 1u);
                }
                if (emit_expr(cg, n->u.assign.value_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    movq %%rax, -%d(%%rbp)", (slot + 1) * 8);
                break;
            }
            if (lv->kind == III_AST_EXPR_INDEX) {
                /* Width-aware indexed store: dispatch on pointer/array
                 * element width via pointer_element_width.  Falls back
                 * to the legacy 8-byte movq when type can't be inferred.
                 * This fixes the *u32-store-width trap (writing a u32
                 * via *u32 pointer was emitting movq with scale=8,
                 * clobbering the adjacent slot AND skipping elements
                 * on stride). */
                int el_width = pointer_element_width(cg, lv->u.index.object);
                if (emit_expr(cg, lv->u.index.object) != 0) { rc = -1; break; }
                if (emit_expr(cg, lv->u.index.index_expr) != 0) { rc = -1; break; }
                if (emit_expr(cg, n->u.assign.value_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rdx");
                stack_pop_reg(cg, "rcx");
                stack_pop_reg(cg, "rax");
                if (el_width == 1) {
                    emit_line(cg, "    movb %%dl, (%%rax,%%rcx,1)");
                } else if (el_width == 2) {
                    emit_line(cg, "    movw %%dx, (%%rax,%%rcx,2)");
                } else if (el_width == 4) {
                    emit_line(cg, "    movl %%edx, (%%rax,%%rcx,4)");
                } else {
                    emit_line(cg, "    movq %%rdx, (%%rax,%%rcx,8)");
                }
                break;
            }
            /* F6 — `*ptr = rhs`: store rhs at the address held in ptr. */
            if (lv->kind == III_AST_EXPR_UNARY && lv->u.unary.op == III_UN_DEREF) {
                if (emit_expr(cg, lv->u.unary.operand) != 0) { rc = -1; break; }
                if (emit_expr(cg, n->u.assign.value_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rdx");   /* rhs value */
                stack_pop_reg(cg, "rax");   /* ptr */
                emit_line(cg, "    movq %%rdx, (%%rax)");
                break;
            }
            if (lv->kind == III_AST_EXPR_FIELD) {
                const iii_ast_node_t *obj = iii_ast_get(cg->ast, lv->u.field.object);
                if (!obj || obj->kind != III_AST_EXPR_IDENT) {
                    cg->last_error = III_CG_R3_E_UNSUPPORTED;
                    cg->error_count++;
                    rc = -1; break;
                }
                /* F8.5 — struct field write on a stack-local struct. */
                int base_slot_w = local_lookup_slot(cg, obj->u.ident.name);
                if (base_slot_w >= 0 && cg->sema) {
                    uint32_t obj_node_w = lv->u.field.object;
                    uint32_t bid_w = iii_ast_node_binder_id(cg->ast, obj_node_w);
                    const iii_ast_node_t *binder_w = bid_w ? iii_ast_get(cg->ast, bid_w) : NULL;
                    uint32_t type_node_w = 0;
                    if (binder_w && binder_w->kind == III_AST_STMT_LET)   type_node_w = binder_w->u.let_.type_node;
                    else if (binder_w && binder_w->kind == III_AST_PARAM) type_node_w = binder_w->u.param.type_node;
                    const iii_ast_node_t *type_n_w = type_node_w ? iii_ast_get(cg->ast, type_node_w) : NULL;
                    if (type_n_w && type_n_w->kind == III_AST_TYPE_REF) {
                        const uint8_t *src_w = iii_ast_source_buf(cg->ast);
                        iii_src_text_t tname_w = type_n_w->u.type_ref.name;
                        if (src_w && tname_w.length < 64) {
                            char tnm_w[64];
                            memcpy(tnm_w, src_w + tname_w.offset, tname_w.length);
                            tnm_w[tname_w.length] = 0;
                            uint32_t struct_decl_w = iii_sema_struct_decl_for_name(cg->sema, tnm_w);
                            if (struct_decl_w != 0) {
                                iii_src_text_t fname_w = lv->u.field.field_name;
                                char fnm_w[64];
                                if (src_w && fname_w.length < 64) {
                                    memcpy(fnm_w, src_w + fname_w.offset, fname_w.length);
                                    fnm_w[fname_w.length] = 0;
                                    int32_t field_off_w = iii_sema_struct_field_slot(cg->sema, struct_decl_w, fnm_w);
                                    if (field_off_w >= 0) {
                                        if (emit_expr(cg, n->u.assign.value_expr) != 0) { rc = -1; break; }
                                        stack_pop_reg(cg, "rax");
                                        emit_line(cg, "    movq %%rax, -%d(%%rbp)",
                                                  (base_slot_w + 1 + (int)field_off_w) * 8);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                /* Fallback: legacy global-symbol write. */
                if (emit_expr(cg, n->u.assign.value_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                cg_write_str(cg, "    movq %rax, ");
                if (emit_field_label(cg, obj, lv->u.field.field_name) != 0) {
                    cg->last_error = III_CG_R3_E_UNSUPPORTED;
                    cg->error_count++;
                    rc = -1; break;
                }
                cg_write_str(cg, "(%rip)\n");
                break;
            }
            cg->last_error = III_CG_R3_E_UNSUPPORTED;
            cg->error_count++;
            rc = -1;
            break;
        }
        case III_AST_STMT_FOR: {
            uint32_t lbl_top = cg->label_counter++;
            uint32_t lbl_end = cg->label_counter++;
            const iii_ast_node_t *iter_node = iii_ast_get(cg->ast, n->u.for_.iter_expr);
            uint32_t count_slot;
            uint32_t var_slot;
            if (iter_node && iter_node->kind == III_AST_EXPR_RANGE) {
                /* F3 — `for v in lo..hi`: lo evaluates once into v's slot,
                 * hi evaluates once into a count slot; loop test `v < hi`. */
                if (emit_expr(cg, iter_node->u.range_.hi) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                count_slot = cg->local_count++;
                emit_line(cg, "    movq %%rax, -%d(%%rbp)", (count_slot + 1) * 8);
                if (emit_expr(cg, iter_node->u.range_.lo) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                local_add(cg, n->u.for_.var);
                var_slot = cg->local_count - 1u;
                emit_line(cg, "    movq %%rax, -%d(%%rbp)", (var_slot + 1) * 8);
            } else {
                /* Legacy form: `for v in <count_expr>` loops 0..count. */
                if (emit_expr(cg, n->u.for_.iter_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                count_slot = cg->local_count++;
                emit_line(cg, "    movq %%rax, -%d(%%rbp)", (count_slot + 1) * 8);
                local_add(cg, n->u.for_.var);
                var_slot = cg->local_count - 1u;
                emit_line(cg, "    movq $0, -%d(%%rbp)", (var_slot + 1) * 8);
            }
            if (label_define(cg, lbl_top) != 0) { rc = -1; break; }
            emit_line(cg, "L_for_top_%u:", (unsigned)lbl_top);
            emit_line(cg, "    movq -%d(%%rbp), %%rax", (var_slot + 1) * 8);
            emit_line(cg, "    movq -%d(%%rbp), %%rcx", (count_slot + 1) * 8);
            emit_line(cg, "    cmpq %%rcx, %%rax");
            emit_line(cg, "    jge L_for_end_%u", (unsigned)lbl_end);
            if (n->u.for_.where_expr != 0) {
                if (emit_expr(cg, n->u.for_.where_expr) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    testq %%rax, %%rax");
                emit_line(cg, "    jz L_for_continue_%u", (unsigned)lbl_top);
            }
            if (emit_block(cg, n->u.for_.body_block) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            if (n->u.for_.where_expr != 0) {
                emit_line(cg, "L_for_continue_%u:", (unsigned)lbl_top);
            }
            emit_line(cg, "    movq -%d(%%rbp), %%rax", (var_slot + 1) * 8);
            emit_line(cg, "    addq $1, %%rax");
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (var_slot + 1) * 8);
            emit_line(cg, "    jmp L_for_top_%u", (unsigned)lbl_top);
            if (label_define(cg, lbl_end) != 0) { rc = -1; break; }
            emit_line(cg, "L_for_end_%u:", (unsigned)lbl_end);
            break;
        }
        /* F1 — if/else.  cond → branch to else_block (or end if no else)
         * on zero, otherwise fall through to then_block. */
        case III_AST_STMT_IF: {
            uint32_t lbl_else = cg->label_counter++;
            uint32_t lbl_end  = cg->label_counter++;
            if (emit_expr(cg, n->u.if_.cond) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            emit_line(cg, "    testq %%rax, %%rax");
            if (n->u.if_.else_block != 0) {
                emit_line(cg, "    jz L_if_else_%u", (unsigned)lbl_else);
            } else {
                emit_line(cg, "    jz L_if_end_%u", (unsigned)lbl_end);
            }
            if (emit_block(cg, n->u.if_.then_block) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            if (n->u.if_.else_block != 0) {
                emit_line(cg, "    jmp L_if_end_%u", (unsigned)lbl_end);
                if (label_define(cg, lbl_else) != 0) { rc = -1; break; }
                emit_line(cg, "L_if_else_%u:", (unsigned)lbl_else);
                /* else_block is either an EXPR_BLOCK or a nested STMT_IF
                 * (the `else if` cascade case).  Both paths are statements
                 * that emit_stmt handles. */
                const iii_ast_node_t *eb = iii_ast_get(cg->ast, n->u.if_.else_block);
                if (eb && eb->kind == III_AST_STMT_IF) {
                    if (emit_stmt(cg, n->u.if_.else_block) != 0) { rc = -1; break; }
                } else {
                    if (emit_block(cg, n->u.if_.else_block) != 0) { rc = -1; break; }
                    stack_pop_reg(cg, "rax");
                }
            }
            if (label_define(cg, lbl_end) != 0) { rc = -1; break; }
            emit_line(cg, "L_if_end_%u:", (unsigned)lbl_end);
            break;
        }
        /* F2 — while.  cond → if zero, jump to end; else execute body
         * and jump back to top. */
        case III_AST_STMT_WHILE: {
            /* iiis-2 unified loop labels: use L_loop_top_<id> /
             * L_loop_end_<id> for both STMT_WHILE and STMT_LOOP so
             * STMT_BREAK / STMT_CONTINUE inside a WHILE resolve to the
             * same label-naming scheme as inside a LOOP.  Label
             * uniqueness still flows from cg->label_counter. */
            uint32_t lbl_top = cg->label_counter++;
            uint32_t lbl_end = cg->label_counter++;
            if (cg->loop_depth >= 16u) {
                cg->last_error = III_CG_R3_E_INTERNAL; cg->error_count++;
                cg_writef(cg, "    # III_LOOP_NEST_OVERFLOW: depth >= 16\n");
                rc = -1; break;
            }
            cg->loop_stack[cg->loop_depth].continue_lbl = lbl_top;
            cg->loop_stack[cg->loop_depth].break_lbl    = lbl_end;
            cg->loop_depth++;
            if (label_define(cg, lbl_top) != 0) { rc = -1; break; }
            emit_line(cg, "L_loop_top_%u:", (unsigned)lbl_top);
            if (emit_expr(cg, n->u.while_.cond) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            emit_line(cg, "    testq %%rax, %%rax");
            emit_line(cg, "    jz L_loop_end_%u", (unsigned)lbl_end);
            if (emit_block(cg, n->u.while_.body_block) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            emit_line(cg, "    jmp L_loop_top_%u", (unsigned)lbl_top);
            if (label_define(cg, lbl_end) != 0) { rc = -1; break; }
            emit_line(cg, "L_loop_end_%u:", (unsigned)lbl_end);
            cg->loop_depth--;
            break;
        }
        case III_AST_STMT_LOOP: {
            /* iiis-2 — unconditional loop: emit top-label, body, jmp
             * back to top, end-label.  break/continue inside resolve
             * via the loop_stack. */
            uint32_t lbl_top = cg->label_counter++;
            uint32_t lbl_end = cg->label_counter++;
            if (cg->loop_depth >= 16u) {
                cg->last_error = III_CG_R3_E_INTERNAL; cg->error_count++;
                cg_writef(cg, "    # III_LOOP_NEST_OVERFLOW: depth >= 16\n");
                rc = -1; break;
            }
            cg->loop_stack[cg->loop_depth].continue_lbl = lbl_top;
            cg->loop_stack[cg->loop_depth].break_lbl    = lbl_end;
            cg->loop_depth++;
            if (label_define(cg, lbl_top) != 0) { rc = -1; break; }
            emit_line(cg, "L_loop_top_%u:", (unsigned)lbl_top);
            if (emit_block(cg, n->u.loop_.body_block) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            emit_line(cg, "    jmp L_loop_top_%u", (unsigned)lbl_top);
            if (label_define(cg, lbl_end) != 0) { rc = -1; break; }
            emit_line(cg, "L_loop_end_%u:", (unsigned)lbl_end);
            cg->loop_depth--;
            break;
        }
        case III_AST_STMT_BREAK: {
            /* iiis-2 — `break` outside any loop is a codegen error. */
            if (cg->loop_depth == 0u) {
                cg->last_error = III_CG_R3_E_INTERNAL; cg->error_count++;
                cg_writef(cg, "    # III_BREAK_OUTSIDE_LOOP\n");
                rc = -1; break;
            }
            uint32_t lbl = cg->loop_stack[cg->loop_depth - 1u].break_lbl;
            /* Label format depends on which loop kind allocated it,
             * but we emit a unified `L_loop_end_<id>` regardless --
             * both STMT_WHILE and STMT_LOOP emit jumps to break_lbl,
             * the actual label definition is at the loop's tail.  We
             * use the more general format that both define. */
            emit_line(cg, "    jmp L_loop_end_%u", (unsigned)lbl);
            break;
        }
        case III_AST_STMT_CONTINUE: {
            if (cg->loop_depth == 0u) {
                cg->last_error = III_CG_R3_E_INTERNAL; cg->error_count++;
                cg_writef(cg, "    # III_CONTINUE_OUTSIDE_LOOP\n");
                rc = -1; break;
            }
            uint32_t lbl = cg->loop_stack[cg->loop_depth - 1u].continue_lbl;
            emit_line(cg, "    jmp L_loop_top_%u", (unsigned)lbl);
            break;
        }
        case III_AST_STMT_WAVEFRONT: {
            for (uint32_t i = 0; i < n->u.wavefront.nodes.count; i++) {
                uint32_t inner = iii_ast_list_at(cg->ast, n->u.wavefront.nodes, i);
                if (emit_stmt(cg, inner) != 0) { rc = -1; break; }
            }
            break;
        }
        case III_AST_STMT_SANCTUM_ENTER: {
            /* sanctum_enter |frame| { body } — at R3 sema rejects this;
             * if reached, signal unsupported.  At R-2 codegen handles
             * it (see cg_rm2.c). */
            cg->last_error = III_CG_R3_E_UNSUPPORTED;
            cg->error_count++;
            rc = -1;
            break;
        }
        case III_AST_STMT_METAL: {
            /* At R3 sema must reject metal{} (privileged surface), but
             * if it leaks through, codegen still emits the bytes — they
             * are the source's authority.  Operator's discipline. */
            uint32_t off = n->u.metal.raw_asm_str_idx;
            uint32_t len = n->u.metal.raw_asm_len;
            if (off + len <= iii_ast_source_len(cg->ast)) {
                cg_write_bytes(cg, iii_ast_source_buf(cg->ast) + off, len);
                cg_write_char(cg, '\n');
            }
            break;
        }
        case III_AST_STMT_MATCH: {
            uint32_t end_lbl = cg->label_counter++;
            uint32_t arm_count = n->u.match_stmt.arms.count;
            if (emit_expr(cg, n->u.match_stmt.scrutinee) != 0) { rc = -1; break; }
            stack_pop_reg(cg, "rax");
            uint32_t scrut_slot = cg->local_count++;
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (scrut_slot + 1) * 8);
            for (uint32_t i = 0; i < arm_count; i++) {
                uint32_t arm_id = iii_ast_list_at(cg->ast, n->u.match_stmt.arms, i);
                const iii_ast_node_t *arm = iii_ast_get(cg->ast, arm_id);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t skip_lbl = cg->label_counter++;
                emit_line(cg, "    movq -%d(%%rbp), %%rax", (scrut_slot + 1) * 8);
                if (emit_pattern_compare(cg, arm->u.match_arm.pattern) != 0) { rc = -1; break; }
                emit_line(cg, "    jne L_skip_%u", (unsigned)skip_lbl);
                emit_pattern_bind(cg, arm->u.match_arm.pattern);
                if (arm->u.match_arm.guard_expr != 0) {
                    if (emit_expr(cg, arm->u.match_arm.guard_expr) != 0) { rc = -1; break; }
                    stack_pop_reg(cg, "rax");
                    emit_line(cg, "    testq %%rax, %%rax");
                    emit_line(cg, "    jz L_skip_%u", (unsigned)skip_lbl);
                }
                if (emit_expr(cg, arm->u.match_arm.body) != 0) { rc = -1; break; }
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    jmp L_match_end_%u", (unsigned)end_lbl);
                if (label_define(cg, skip_lbl) != 0) { rc = -1; break; }
                emit_line(cg, "L_skip_%u:", (unsigned)skip_lbl);
            }
            if (rc == 0 && label_define(cg, end_lbl) != 0) { rc = -1; break; }
            emit_line(cg, "L_match_end_%u:", (unsigned)end_lbl);
            break;
        }
        default:
            cg->last_error = III_CG_R3_E_UNSUPPORTED;
            cg->error_count++;
            rc = -1;
            break;
    }
#ifdef III_CG_R3_DEBUG
    /* D13: per-statement stack-depth invariant.  Every push must be
     * matched by a pop — at statement boundary depth must be 0. */
    cg_writef(cg, "    # stack_depth=%u\n", (unsigned)cg->stack_depth);
    if (cg->stack_depth != 0u) {
        cg_writef(cg, "    .error \"III_CG_R3_DEBUG: stack_depth=%u != 0\"\n",
                  (unsigned)cg->stack_depth);
    }
#endif
    return rc;
}

static int emit_block(iii_cg_r3_state_t *cg, uint32_t block_node)
{
    const iii_ast_node_t *n = iii_ast_get(cg->ast, block_node);
    if (!n) return -1;
    if (n->kind != III_AST_EXPR_BLOCK && n->kind != III_AST_FORWARD_BLOCK) return -1;
    iii_ast_list_t stmts = (n->kind == III_AST_EXPR_BLOCK)
                              ? n->u.block.stmts : n->u.forward_block.stmts;
    uint32_t saved_locals = cg->local_count;
    int rc = 0;
    for (uint32_t i = 0; i < stmts.count; i++) {
        uint32_t sid = iii_ast_list_at(cg->ast, stmts, i);
        if (emit_stmt(cg, sid) != 0) {
            /* D11: record but continue. */
            rc = -1;
        }
    }
    cg->local_count = saved_locals;
    emit_line(cg, "    movq $0, %%rax");
    stack_push_reg(cg, "rax");
    return rc;
}

/* ─── Phase C.6: PE classifier + emitter ──────────────────────────────
 *
 * cg_r3_pe_classify_intent_arg(cg, intent_arg_node, out_dispatch_name):
 *   Traces the intent argument back to its construction. If it is a
 *   `let intent = intent_form(LITERAL)` (or sibling intent_X(...)),
 *   and LITERAL matches a PE_TABLE entry, returns 1 with
 *   *out_dispatch_name = the dispatch_fp's symbol. Otherwise 0.
 *
 * The trace is intentionally narrow: only direct local-let bindings
 * with a literal first arg are classified static. Anything more
 * complex (passing params, computed values, member access, etc.)
 * stays dynamic.
 */
/* iiis-2 cross-function PE: delegate to the externally-callable
 * classifier in iii_cg_pe_iiis1.c (single source of truth shared with
 * iiis-1).  Forward declaration. */
extern const char *iii_cg_pe_classify_intent(const iii_ast_t *ast,
                                              uint32_t intent_arg_node);

static int cg_r3_pe_classify_intent_arg(iii_cg_r3_state_t *cg,
                                            uint32_t intent_arg_node,
                                            const char **out_dispatch_name)
{
    if (out_dispatch_name) *out_dispatch_name = NULL;
    if (!cg || !cg->ast || intent_arg_node == 0) return 0;
    /* Single source of truth: iii_cg_pe_iiis1.c.  Handles both the
     * iiis-1 direct + let-bound-literal cases AND the iiis-2 cross-fn
     * recursive case. */
    const char *name = iii_cg_pe_classify_intent(cg->ast, intent_arg_node);
    if (!name) return 0;
    if (out_dispatch_name) *out_dispatch_name = name;
    return 1;
}

/* Legacy body retained but unreachable (replaced by delegation above).
 * Kept as comment-block documentation of the algorithm; the active
 * implementation is in iii_cg_pe_iiis1.c::classify_intent_bounded. */
#if 0
static int cg_r3_pe_classify_intent_arg_LEGACY(iii_cg_r3_state_t *cg,
                                            uint32_t intent_arg_node,
                                            const char **out_dispatch_name)
{
    if (out_dispatch_name) *out_dispatch_name = NULL;
    if (!cg || !cg->ast || intent_arg_node == 0) return 0;

    /* The argument inside an EXPR_ARG wrapper may be the intent itself
     * (we are passed the inner value_expr). Resolve EXPR_ARG -> value. */
    const iii_ast_node_t *a = iii_ast_get(cg->ast, intent_arg_node);
    if (!a) return 0;
    if (a->kind == III_AST_ARG) {
        intent_arg_node = a->u.arg.value_expr;
        a = iii_ast_get(cg->ast, intent_arg_node);
        if (!a) return 0;
    }

    /* Case 1: direct call (intent_X(literal, ...) inline as the arg). */
    const iii_ast_node_t *call_node = NULL;
    if (a->kind == III_AST_EXPR_CALL) {
        call_node = a;
    }

    /* Case 2: identifier bound to a let with intent_X(literal) initializer. */
    if (!call_node && a->kind == III_AST_EXPR_IDENT) {
        uint32_t bid = iii_ast_node_binder_id(cg->ast, intent_arg_node);
        const iii_ast_node_t *binder = bid ? iii_ast_get(cg->ast, bid) : NULL;
        if (binder && binder->kind == III_AST_STMT_LET) {
            uint32_t init_id = binder->u.let_.value_expr;
            const iii_ast_node_t *init = init_id ? iii_ast_get(cg->ast, init_id) : NULL;
            if (init && init->kind == III_AST_EXPR_CALL) {
                call_node = init;
            }
        }
    }

    if (!call_node) return 0;

    /* The call's callee must be one of the intent_X constructors.
     * For the v1.0 PE we recognise intent_form, intent_act,
     * intent_convey. The decisive factor is the FIRST literal
     * argument (form_id / state_id / src_handle). */
    const iii_ast_node_t *callee = iii_ast_get(cg->ast, call_node->u.call.callee);
    if (!callee || callee->kind != III_AST_EXPR_IDENT) return 0;
    const uint8_t *src = iii_ast_source_buf(cg->ast);
    if (!src) return 0;
    iii_src_text_t cn = callee->u.ident.name;
    char buf[24];
    if (cn.length >= sizeof(buf)) return 0;
    memcpy(buf, src + cn.offset, cn.length);
    buf[cn.length] = 0;

    uint8_t expect_primitive = 0;
    if (strcmp(buf, "intent_form") == 0)    expect_primitive = 1;
    else if (strcmp(buf, "intent_convey") == 0) expect_primitive = 3;
    else if (strcmp(buf, "intent_act") == 0)    expect_primitive = 5;
    else return 0;

    /* First arg must be a u64 literal. */
    iii_ast_list_t cargs = call_node->u.call.args;
    if (cargs.count == 0) return 0;
    uint32_t a0 = iii_ast_list_at(cg->ast, cargs, 0);
    const iii_ast_node_t *a0n = a0 ? iii_ast_get(cg->ast, a0) : NULL;
    if (!a0n || a0n->kind != III_AST_ARG) return 0;
    const iii_ast_node_t *vexpr = iii_ast_get(cg->ast, a0n->u.arg.value_expr);
    if (!vexpr || vexpr->kind != III_AST_EXPR_INT) return 0;
    uint64_t literal = (uint64_t)vexpr->u.int_.value;

    /* Look up III_COMPOSITION_TABLE by (primitive_id, literal_form_id).
     * Single source of truth: regenerated from iii_compositions.def on
     * every iiis-0 build. */
    for (size_t i = 0; i < III_COMPOSITION_TABLE_LEN; i++) {
        if (III_COMPOSITION_TABLE[i].primitive_id == expect_primitive &&
            III_COMPOSITION_TABLE[i].literal_form_id == literal) {
            if (out_dispatch_name) *out_dispatch_name = III_COMPOSITION_TABLE[i].dispatch_fp_name;
            return 1;
        }
    }
    return 0;
}
#endif /* end legacy cg_r3_pe_classify_intent_arg body */

/* Emit a direct fn-pointer load: `leaq <fn_name>(%rip), %rax; pushq %rax`.
 * This replaces a `resolve(set, intent, ctx)` call when the intent is
 * provably static. The result on the stack is the dispatch_fp address;
 * the caller may indirect-call through it. */
static int cg_r3_pe_emit_direct_load(iii_cg_r3_state_t *cg, const char *fn_name)
{
    if (!cg || !fn_name) return -1;
    cg_write_str(cg, "    # III_PE_DIRECT_LOAD ");
    cg_write_str(cg, fn_name);
    cg_write_char(cg, '\n');
    cg_write_str(cg, "    leaq ");
    cg_write_str(cg, fn_name);
    cg_write_str(cg, "(%rip), %rax\n");
    stack_push_reg(cg, "rax");
    return 0;
}

/* Phase C.6 multi-statement narrowing: record (slot_idx -> fn_name).
 *
 * Called from STMT_LET emission when the let's initializer is a
 * static-resolvable resolve() call. Out-of-range slot_idx (>= 128) is
 * a silent no-op — the let still gets the address loaded into the slot
 * via the existing PE direct-load, so reads of the local still work;
 * we just don't get the indirect-call elision for that slot. */
static void cg_r3_pe_record_static_fp(iii_cg_r3_state_t *cg,
                                      uint32_t slot_idx,
                                      const char *fn_name)
{
    if (!cg || !fn_name) return;
    if (slot_idx >= (uint32_t)(sizeof(cg->pe_static_fp) / sizeof(cg->pe_static_fp[0]))) {
        return;  /* past the per-fn cap; emit normally (no PE) */
    }
    cg->pe_static_fp[slot_idx] = fn_name;
}

/* Phase C.6 multi-statement narrowing: lookup recorded fn_name for slot.
 *
 * Returns the recorded symbol name (interned in iii_compositions.h's
 * static table — lifetime is the program's; safe to store as raw ptr)
 * or NULL if the slot isn't statically resolved. */
static const char *cg_r3_pe_get_static_fp(iii_cg_r3_state_t *cg,
                                          uint32_t slot_idx)
{
    if (!cg) return NULL;
    if (slot_idx >= (uint32_t)(sizeof(cg->pe_static_fp) / sizeof(cg->pe_static_fp[0]))) {
        return NULL;
    }
    return cg->pe_static_fp[slot_idx];
}

/* ─── Function emit ───────────────────────────────────────────────── */

static int emit_function(iii_cg_r3_state_t *cg,
                         uint32_t decl_node,
                         iii_src_text_t name,
                         iii_ast_list_t params,
                         uint32_t body_node,
                         bool is_cycle)
{
    cg->cur_decl_node = decl_node;
    cg->cur_is_cycle = is_cycle;
    cg->cur_export = decl_is_exported(cg, decl_node);
    cg->local_count = 0;
    cg->stack_depth = 0;
    cg->max_stack_depth = 0;
    /* Phase C.6 multi-statement narrowing: reset per-function PE state.
     * Each function starts with no statically-resolved local slots; the
     * STMT_LET emission populates this map as it discovers them. */
    {
        size_t _pe_idx;
        for (_pe_idx = 0;
             _pe_idx < sizeof(cg->pe_static_fp) / sizeof(cg->pe_static_fp[0]);
             _pe_idx++) {
            cg->pe_static_fp[_pe_idx] = NULL;
        }
    }
    /* label_counter is module-wide, not per-function: resetting it
     * per function would cause duplicate label names across functions
     * (e.g. L_if_end_1 in fn A and fn B).  We keep accumulating so
     * every emitted control-flow label is module-globally unique.  */
    cg->defined_label_count = 0;

    /* D9: ring-3 note section so a linker-stage tool can reject any
     * ring-3 reference to a ring-0 symbol.  Cross-ring transitions
     * must go through documented gateways.
     *
     * PE/COFF gas section-attribute syntax: `.section name, "flags"`
     * where flags include r/w/x/n (info, not loaded).  ELF's "@note"
     * type-attribute is not accepted on PE/COFF; use the "n" flag
     * instead so the section is recognised as info-only on Windows
     * targets.  Linux/ELF builds also accept this flag. */
    cg_write_str(cg, "    .section .iii.ring3,\"n\"\n    .asciz \"");
    for (uint32_t i = 0; i < name.length; i++) {
        uint8_t b = iii_ast_source_buf(cg->ast)[name.offset + i];
        if (b == '"' || b == '\\') cg_write_char(cg, '_');
        else cg_write_char(cg, (int)b);
    }
    cg_write_str(cg, "\"\n");

    /* .text always; .global <name> ONLY when @export -- a non-@export fn becomes a
     * module-LOCAL symbol so private helpers no longer leak into the global link
     * namespace.  Must stay byte-identical to cg_r3.iii (the --check-corpus gate). */
    cg_write_str(cg, "    .text\n");
    {
        /* the entry point `main` is always global (host linker finds it), even
         * though it is non-@export -- mirrors cg_r3.iii's r3_glob check. */
        const uint8_t *src_m = iii_ast_source_buf(cg->ast);
        bool is_main_fn = (src_m && name.length == 4
                           && src_m[name.offset + 0] == 'm' && src_m[name.offset + 1] == 'a'
                           && src_m[name.offset + 2] == 'i' && src_m[name.offset + 3] == 'n');
        if (cg->cur_export || is_main_fn) {
            cg_write_str(cg, "    .global ");
            emit_raw_symbol(cg, name);
            cg_write_char(cg, '\n');
        }
    }

    /* D4: SEH unwind-info bracket.  Windows x64 unwind spec requires
     * pushreg → stackalloc → setframe → endprologue ordering. */
    cg_write_str(cg, "    .seh_proc ");
    if (cg->cur_export) emit_raw_symbol(cg, name); else emit_decl_label(cg, name);
    cg_write_char(cg, '\n');

    if (cg->cur_export) emit_raw_symbol(cg, name); else emit_decl_label(cg, name);
    cg_write_str(cg, ":\n");

    /* Prologue.  At entry rsp ≡ 8 (mod 16) (callq pushed return addr).
     * pushq %rbp aligns; subq $LOCAL_RESERVE keeps it aligned
     * (LOCAL_RESERVE is a multiple of 16).
     *
     * SEH-frame discipline (Windows x64 unwind spec):
     *   .seh_setframe's FrameOffset field is bounded to [0, 240]
     *   (encoded as a 4-bit nibble × 16).  We therefore set rbp =
     *   rsp BEFORE allocating locals — putting rbp at offset 0 from
     *   the post-pushq rsp — and only THEN reserve locals.  Locals
     *   live at -((slot+1)*8)(%rbp), the same addresses they had
     *   under the old rbp = rsp + LOCAL_RESERVE convention. */
    emit_line(cg, "    pushq %%rbp");
    cg_write_str(cg, "    .seh_pushreg %rbp\n");
    emit_line(cg, "    movq %%rsp, %%rbp");
    cg_write_str(cg, "    .seh_setframe %rbp, 0\n");
    emit_line(cg, "    subq $%u, %%rsp",
              (unsigned)III_CG_R3_LOCAL_RESERVE);
    cg_writef(cg, "    .seh_stackalloc %u\n", (unsigned)III_CG_R3_LOCAL_RESERVE);
    cg_write_str(cg, "    .seh_endprologue\n");

    /* D8: cycle witness entry marker, after frame is established. */
    if (is_cycle) {
        cg_write_str(cg, "    # III_CYCLE_WITNESS_ENTER\n");
    }

    /* Lattice plan Step 0022: @dynamic ripple-stub at function entry.
     *
     * If this decl carries @dynamic(ripple = auto | manual) — NOT off —
     * emit a 3-instruction sequence that calls ripple_execute_native
     * with (crystal_id, mode_byte).  The crystal_id at Stage-0 is the
     * decl_node index (deterministic per AST); Stage-1 promotes it to
     * a real crystal_mint result.
     *
     *   movabsq $<crystal_id>, %rcx     ; 10 bytes
     *   movl    $<mode>, %edx           ;  5 bytes
     *   callq   ripple_execute_native   ;  5 bytes (rel32)
     *
     * The stub is BEFORE parameter spill so it sees an undisturbed
     * caller frame (rcx/rdx contain ripple args, not user params).
     * Parameter spill below restores user rcx/rdx by reading from the
     * caller's shadow space and stack-arg region — but for stage-0,
     * we only spill from the registers we expect to hold params.  To
     * keep param-passing semantics intact for the FIRST four params,
     * the stub instead emits AFTER the spill so user rcx/rdx are
     * already saved into local slots before being clobbered.
     *
     * Trade-off: this means the stub fires only AFTER the function
     * has spilled, which is fine because @dynamic dispatch is a
     * notification, not a return-value transformation. */
    bool emit_dynamic_stub = false;
    uint8_t dynamic_mode = 0;
    if (cg->sema && iii_sema_anno_has_dynamic(cg->sema, decl_node)) {
        dynamic_mode = iii_sema_anno_dynamic_ripple_mode(cg->sema, decl_node);
        if (dynamic_mode != III_SEMA_DYNAMIC_RIPPLE_UNSET &&
            dynamic_mode != III_SEMA_DYNAMIC_RIPPLE_OFF) {
            emit_dynamic_stub = true;
        }
    }

    /* Spill parameters (rcx, rdx, r8, r9) into local slots 0..3. */
    const char *abi_regs[4] = { "rcx", "rdx", "r8", "r9" };
    uint32_t pcount = params.count;
    for (uint32_t i = 0; i < pcount && i < 4u; i++) {
        uint32_t pid = iii_ast_list_at(cg->ast, params, i);
        const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
        if (p && p->kind == III_AST_PARAM) {
            local_add(cg, p->u.param.name);
            uint32_t slot = cg->local_count - 1u;
            emit_line(cg, "    movq %%%s, -%d(%%rbp)", abi_regs[i], (slot + 1) * 8);
        }
    }
    for (uint32_t i = 4; i < pcount; i++) {
        uint32_t pid = iii_ast_list_at(cg->ast, params, i);
        const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
        if (p && p->kind == III_AST_PARAM) {
            local_add(cg, p->u.param.name);
            uint32_t slot = cg->local_count - 1u;
            /* MS x64 ABI §6.4 + §6.4.4: stack args live at
             *   [rbp + 16   + 0x20 (shadow) + 0x08 * (i-4)]
             * = [rbp + 48 + 0x08 * (i-4)]
             * because the callee's rbp points at the saved-rbp slot
             * (per the SEH-frame discipline established in the
             * prologue), the return address is at rbp+8, the
             * caller-reserved 32-byte shadow region is at rbp+16..47,
             * and the caller-pushed stack args 4+ start at rbp+48.
             * The previous `16 + (i-4)*8` formula loaded from the
             * SHADOW slot of arg 0/1/etc. — undefined data. */
            emit_line(cg, "    movq %d(%%rbp), %%rax", 48 + (int)(i - 4) * 8);
            emit_line(cg, "    movq %%rax, -%d(%%rbp)", (slot + 1) * 8);
        }
    }

    /* Emit @dynamic ripple stub AFTER parameter spill (see rationale
     * above).  Stub is 3 instructions; ripple_execute_native is in
     * omnia/ripple.iii and is link-time resolved by the standard
     * linker chain. */
    if (emit_dynamic_stub) {
        cg_write_str(cg, "    # III_DYNAMIC_RIPPLE_STUB (lattice Step 0022)\n");
        emit_line(cg, "    movabsq $%u, %%rcx", (unsigned)decl_node);
        emit_line(cg, "    movl $%u, %%edx", (unsigned)dynamic_mode);
        emit_line(cg, "    callq ripple_execute_native");
    }

    /* Phase 3 Step 3: iiis-1 runtime annotation enforcement.  Two
     * features land in v1.0:
     *
     *   @cap_required(MASK) — verifies ctx.cap_id holds MASK rights
     *     via cap_verify_rights.  Denied → 0xFFFF...FFFF sentinel.
     *
     *   @k_max(N) — verifies kchain_current(ctx.kchain_id) >= N before
     *     fn body executes.  Insufficient → 0xFFFF...FFFF sentinel.
     *
     * Both checks require a `ctx: u64` parameter; without it, the
     * annotation is silently inactive (semantic check failure path,
     * could be promoted to compile-time error in Stage-2+).
     *
     * Mandate 7: both checks use sealed input (ctx fields, declared
     * MASK/N) — no observation, no learning.  Same sentinel value
     * is used for both denial modes so the external observer cannot
     * distinguish "wrong cap" from "insufficient K" from "fn doesn't
     * exist" — privacy preserved across all denial channels. */
    if (decl_node != 0) {
        const iii_ast_node_t *d = iii_ast_get(cg->ast, decl_node);
        if (d && d->kind == III_AST_FN_DECL) {
            uint64_t required_mask = 0;
            uint64_t k_max_value = 0;
            uint64_t hexad_value = 0;
            bool has_cap = fn_modifier_extract_u64(cg, d->u.fn_decl.modifiers,
                                                    "cap_required", 12, &required_mask);
            bool has_kmax = fn_modifier_extract_u64(cg, d->u.fn_decl.modifiers,
                                                    "k_max", 5, &k_max_value);
            bool has_hexad = fn_modifier_extract_u64(cg, d->u.fn_decl.modifiers,
                                                    "hexad_kind", 10, &hexad_value);
            if (has_cap || has_kmax || has_hexad) {
                /* Locate the `ctx` parameter slot. */
                int ctx_slot = -1;
                for (uint32_t i = 0; i < pcount; i++) {
                    uint32_t pid = iii_ast_list_at(cg->ast, params, i);
                    const iii_ast_node_t *p = iii_ast_get(cg->ast, pid);
                    if (p && p->kind == III_AST_PARAM &&
                        p->u.param.name.length == 3) {
                        const uint8_t *src = iii_ast_source_buf(cg->ast);
                        if (src && memcmp(src + p->u.param.name.offset, "ctx", 3) == 0) {
                            ctx_slot = (int)i;
                            break;
                        }
                    }
                }
                if (ctx_slot >= 0) {
                    /* @cap_required check first (cheaper than the
                     * kchain lookup). */
                    if (has_cap) {
                        cg_write_str(cg, "    # III_CAP_REQUIRED_CHECK (Phase 3 Step 3)\n");
                        emit_line(cg, "    movq -%d(%%rbp), %%rcx", (ctx_slot + 1) * 8);
                        emit_line(cg, "    subq $32, %%rsp");
                        emit_line(cg, "    callq call_context_cap_id");
                        emit_line(cg, "    addq $32, %%rsp");
                        emit_line(cg, "    movq %%rax, %%rcx");
                        emit_line(cg, "    movabsq $0x%llx, %%rdx",
                                  (unsigned long long)required_mask);
                        emit_line(cg, "    subq $32, %%rsp");
                        emit_line(cg, "    callq cap_verify_rights");
                        emit_line(cg, "    addq $32, %%rsp");
                        emit_line(cg, "    testb %%al, %%al");
                        emit_line(cg, "    jnz L_cap_ok_%u", (unsigned)decl_node);
                        emit_line(cg, "    movq $0xFFFFFFFFFFFFFFFF, %%rax");
                        emit_line(cg, "    movq %%rbp, %%rsp");
                        emit_line(cg, "    popq %%rbp");
                        emit_line(cg, "    retq");
                        emit_line(cg, "L_cap_ok_%u:", (unsigned)decl_node);
                    }
                    /* @hexad_kind(K) check: ctx.hexad_kind must equal K
                     * (strict equality for v1.0; future Stage-2 widens to
                     * hexad_adjacent for compositional flexibility).  K
                     * is the numeric hexad code 1..7 per
                     * sanctus/calculus_v1.iii constants. */
                    if (has_hexad) {
                        cg_write_str(cg, "    # III_HEXAD_KIND_CHECK (Phase 3 Step 3)\n");
                        emit_line(cg, "    movq -%d(%%rbp), %%rcx", (ctx_slot + 1) * 8);
                        emit_line(cg, "    subq $32, %%rsp");
                        emit_line(cg, "    callq call_context_hexad_kind");
                        emit_line(cg, "    addq $32, %%rsp");
                        /* rax holds hexad u8 (zero-ext low byte).
                         * Compare against declared kind. */
                        emit_line(cg, "    movzbq %%al, %%rax");
                        emit_line(cg, "    movabsq $0x%llx, %%rcx",
                                  (unsigned long long)hexad_value);
                        emit_line(cg, "    cmpq %%rcx, %%rax");
                        emit_line(cg, "    je L_hexad_ok_%u", (unsigned)decl_node);
                        emit_line(cg, "    movq $0xFFFFFFFFFFFFFFFF, %%rax");
                        emit_line(cg, "    movq %%rbp, %%rsp");
                        emit_line(cg, "    popq %%rbp");
                        emit_line(cg, "    retq");
                        emit_line(cg, "L_hexad_ok_%u:", (unsigned)decl_node);
                    }
                    /* @k_max check: kchain_current(kchain_id) >= N. */
                    if (has_kmax) {
                        cg_write_str(cg, "    # III_K_MAX_CHECK (Phase 3 Step 3)\n");
                        /* Get kchain_id from ctx (u8). */
                        emit_line(cg, "    movq -%d(%%rbp), %%rcx", (ctx_slot + 1) * 8);
                        emit_line(cg, "    subq $32, %%rsp");
                        emit_line(cg, "    callq call_context_kchain_id");
                        emit_line(cg, "    addq $32, %%rsp");
                        /* rax holds kchain_id u8 (zero-ext low byte).
                         * Pass as u64 to kchain_current. */
                        emit_line(cg, "    movzbq %%al, %%rcx");
                        emit_line(cg, "    subq $32, %%rsp");
                        emit_line(cg, "    callq kchain_current");
                        emit_line(cg, "    addq $32, %%rsp");
                        /* rax holds current K (fixed-point 1e-9).
                         * Compare against declared k_max_value. */
                        emit_line(cg, "    movabsq $0x%llx, %%rcx",
                                  (unsigned long long)k_max_value);
                        emit_line(cg, "    cmpq %%rcx, %%rax");
                        /* Unsigned: rax (current K) must be >= rcx (k_max
                         * requirement).  setae == jae jump-if-above-equal. */
                        emit_line(cg, "    jae L_kmax_ok_%u", (unsigned)decl_node);
                        emit_line(cg, "    movq $0xFFFFFFFFFFFFFFFF, %%rax");
                        emit_line(cg, "    movq %%rbp, %%rsp");
                        emit_line(cg, "    popq %%rbp");
                        emit_line(cg, "    retq");
                        emit_line(cg, "L_kmax_ok_%u:", (unsigned)decl_node);
                    }
                }
            }
        }
    }

    int rc = 0;
#ifdef IIIS_XII_ENABLED
    /* XII pre-pass (per DOCS/III-XII.md S14.4): if the function carries
     * fusion-call AST nodes or the @lattice annotation, route body
     * emission through xii_canonicalise + LDIL-aware emitter. The
     * adapter functions live in COMPILER/BOOT/cg_r3_xii.c. */
    extern int  xii_enabled_for_node(iii_cg_r3_state_t *cg, uint32_t fn_node);
    extern int  r3_pe_canonicalise_node(iii_cg_r3_state_t *cg, uint32_t fn_node);
    extern int  r3_pe_lattice_emit_node(iii_cg_r3_state_t *cg, uint32_t fn_node, uint32_t circ);
    extern uint32_t r3_compute_circ_node(iii_cg_r3_state_t *cg, uint32_t fn_node);

    if (body_node != 0 && xii_enabled_for_node(cg, decl_node)) {
        if (r3_pe_canonicalise_node(cg, body_node) != 0) rc = -1;
        if (rc == 0) {
            uint32_t circ = r3_compute_circ_node(cg, decl_node);
            if (r3_pe_lattice_emit_node(cg, body_node, circ) != 0) rc = -1;
        }
    } else
#endif
    if (body_node != 0 && emit_block(cg, body_node) != 0) {
        rc = -1;  /* D11: don't bail the module */
    }

    /* D8: cycle witness exit marker before implicit epilogue. */
    if (is_cycle) {
        cg_write_str(cg, "    # III_CYCLE_WITNESS_EXIT\n");
    }
    /* Epilogue (if body did not return). */
    emit_line(cg, "    movq $0, %%rax");
    emit_line(cg, "    movq %%rbp, %%rsp");
    emit_line(cg, "    popq %%rbp");
    emit_line(cg, "    retq");

    cg_write_str(cg, "    .seh_endproc\n");
    return rc;
}

/* ─── Module emit ─────────────────────────────────────────────────── */

int iii_cg_r3_emit_module(iii_cg_r3_state_t *cg, FILE *out)
{
    if (!cg || !out) return III_CG_R3_E_NULL_ARG;
    cg->out = out;
    /* Reset witness for this emission. */
    iii_sha256_init(&cg->witness);
    cg->last_error = III_CG_R3_OK;
    cg->error_count = 0;

    /* Section / format header — gas Microsoft x64. */
    cg_write_str(cg, "# III Stage-0 Ring-3 codegen output\n");
    cg_write_str(cg, "# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target\n");
    cg_write_str(cg, "    .att_syntax\n");
    /* D10: stable .file directive; per-stmt .loc emitted when AST
     * positions are available (best-effort under Stage-0 boot). */
    cg_write_str(cg, "    .file 1 \"<iii-source>\"\n");

    /* String literal pool — one .rodata label per interned payload. */
    cg_write_str(cg, "    .section .rodata\n");
    for (uint32_t i = 0; i < iii_ast_string_payload_count(cg->ast); i++) {
        cg_writef(cg, "L_str_%u:\n", (unsigned)i);
        const uint8_t *bytes = iii_ast_string_payload_get(cg->ast, i);
        if (bytes) {
            cg_write_str(cg, "    .ascii \"");
            for (; *bytes; bytes++) {
                if (*bytes == '"' || *bytes == '\\') {
                    cg_write_char(cg, '\\');
                    cg_write_char(cg, *bytes);
                } else if (*bytes == '\n') {
                    cg_write_str(cg, "\\n");
                } else if (*bytes >= 0x20 && *bytes < 0x7F) {
                    cg_write_char(cg, (int)*bytes);
                } else {
                    cg_writef(cg, "\\%03o", (unsigned)*bytes);
                }
            }
            cg_write_str(cg, "\\0\"\n");
        }
    }

    /* Constant decls + mutable globals — emit data-section slots.
     *   const NAME: T = <int|hex>     → .rodata + .quad
     *   var   NAME: T = <int|hex>     → .data   + .quad (mutable global)
     *   var   NAME: T                 → .bss    + .zero 8 (default zero)
     * Stage-0 supports literal initializers only; Stage-1+ adds
     * constant folding for expressions. */
    const iii_ast_node_t *mod0 = iii_ast_get(cg->ast, iii_ast_root_module(cg->ast));
    if (mod0 && mod0->kind == III_AST_MODULE) {
        /* current_section: 0=none, 1=.rodata, 2=.data, 3=.bss.
         * gas leaves the previously-opened section "current" until a
         * new `.section` directive switches it; emitting bytes in the
         * wrong section produces the "non-zero in .bss" assembler
         * error.  We re-issue `.section X` whenever current != X. */
        int current_section = 0;
        for (uint32_t i = 0; i < mod0->u.module_.decls.count; i++) {
            uint32_t did = iii_ast_list_at(cg->ast, mod0->u.module_.decls, i);
            const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
            if (!d) continue;
            if (d->kind == III_AST_CONST_DECL) {
                const iii_ast_node_t *v = iii_ast_get(cg->ast, d->u.const_decl.value_expr);
                if (!v) continue;
                if (v->kind == III_AST_EXPR_PARALLEL) {
                    /* Array literal const → .rodata, one element per
                     * branch, sized by the declared element width
                     * (u8 → .byte, u16 → .short, u32 → .long, default
                     * .quad).  Honoring the declared width is required
                     * for byte-accurate string/blob layout. */
                    const iii_ast_node_t *vt_c = iii_ast_get(cg->ast, d->u.const_decl.type_node);
                    uint32_t ew_c = (vt_c && vt_c->kind == III_AST_TYPE_ARRAY)
                                    ? array_elem_byte_size(cg, vt_c) : 8u;
                    const char *dir_c = gas_data_directive(ew_c);
                    if (current_section != 1) {
                        cg_write_str(cg, "    .section .rodata\n");
                        current_section = 1;
                    }
                    /* Stage 3.18: const symbols are module-LOCAL (no .global).
                     * A module-scope const is private -- iii_const_decl_payload_t
                     * has no modifiers field, so a const cannot be @export, and
                     * consts are never cross-referenced (the tp_* "cross-refs"
                     * are to same-named functions, symbol `<name>`, not the const
                     * `L_<name>`).  Local symbols let two modules share a const
                     * name without a link collision; intra-module RIP-relative
                     * refs still resolve within the .o. */
                    emit_decl_label(cg, d->u.const_decl.name);
                    cg_write_str(cg, ":\n");
                    for (uint32_t k = 0; k < v->u.parallel.branches.count; k++) {
                        uint32_t eid = iii_ast_list_at(cg->ast, v->u.parallel.branches, k);
                        const iii_ast_node_t *e = iii_ast_get(cg->ast, eid);
                        uint64_t ev = 0;
                        if (e && e->kind == III_AST_EXPR_INT)      ev = e->u.int_.value;
                        else if (e && e->kind == III_AST_EXPR_HEX) ev = e->u.hex_.value;
                        cg_writef(cg, "    %s 0x%llx\n", dir_c, (unsigned long long)ev);
                    }
                    continue;
                }
                uint64_t lit = 0;
                if (v->kind == III_AST_EXPR_INT)      lit = v->u.int_.value;
                else if (v->kind == III_AST_EXPR_HEX) lit = v->u.hex_.value;
                else if (v->kind == III_AST_EXPR_UNARY && v->u.unary.op == III_UN_NEG) {
                    /* Stage-0 fold: `const X: iN = -<lit>` */
                    const iii_ast_node_t *inner = iii_ast_get(cg->ast, v->u.unary.operand);
                    uint64_t base = 0;
                    if (inner && inner->kind == III_AST_EXPR_INT)      base = inner->u.int_.value;
                    else if (inner && inner->kind == III_AST_EXPR_HEX) base = inner->u.hex_.value;
                    else continue;
                    lit = (uint64_t)(0ull - base);
                }
                else continue;
                if (current_section != 1) {
                    cg_write_str(cg, "    .section .rodata\n");
                    current_section = 1;
                }
                /* Stage 3.18: const symbols are module-LOCAL (no .global) -- see
                 * the array-const note above. */
                emit_decl_label(cg, d->u.const_decl.name);
                cg_writef(cg, ":\n    .quad 0x%llx\n", (unsigned long long)lit);
            } else if (d->kind == III_AST_VAR_DECL) {
                if (d->u.var_decl.init_expr != 0) {
                    const iii_ast_node_t *v = iii_ast_get(cg->ast, d->u.var_decl.init_expr);
                    uint64_t lit = 0;
                    bool ok_scalar = false;
                    bool ok_array  = false;
                    if (v && v->kind == III_AST_EXPR_INT)      { lit = v->u.int_.value; ok_scalar = true; }
                    else if (v && v->kind == III_AST_EXPR_HEX) { lit = v->u.hex_.value; ok_scalar = true; }
                    else if (v && v->kind == III_AST_EXPR_PARALLEL) ok_array = true;
                    if (ok_scalar) {
                        if (current_section != 2) {
                            cg_write_str(cg, "    .section .data\n");
                            current_section = 2;
                        }
                        cg_write_str(cg, "    .global ");
                        emit_decl_label(cg, d->u.var_decl.name);
                        cg_write_str(cg, "\n");
                        emit_decl_label(cg, d->u.var_decl.name);
                        cg_writef(cg, ":\n    .quad 0x%llx\n", (unsigned long long)lit);
                        continue;
                    }
                    if (ok_array) {
                        if (current_section != 2) {
                            cg_write_str(cg, "    .section .data\n");
                            current_section = 2;
                        }
                        const iii_ast_node_t *vt_d = iii_ast_get(cg->ast, d->u.var_decl.type_node);
                        uint32_t ew_d = (vt_d && vt_d->kind == III_AST_TYPE_ARRAY)
                                        ? array_elem_byte_size(cg, vt_d) : 8u;
                        const char *dir_d = gas_data_directive(ew_d);
                        cg_write_str(cg, "    .global ");
                        emit_decl_label(cg, d->u.var_decl.name);
                        cg_write_str(cg, "\n");
                        emit_decl_label(cg, d->u.var_decl.name);
                        cg_write_str(cg, ":\n");
                        for (uint32_t k = 0; k < v->u.parallel.branches.count; k++) {
                            uint32_t eid = iii_ast_list_at(cg->ast, v->u.parallel.branches, k);
                            const iii_ast_node_t *e = iii_ast_get(cg->ast, eid);
                            uint64_t ev = 0;
                            if (e && e->kind == III_AST_EXPR_INT)      ev = e->u.int_.value;
                            else if (e && e->kind == III_AST_EXPR_HEX) ev = e->u.hex_.value;
                            cg_writef(cg, "    %s 0x%llx\n", dir_d, (unsigned long long)ev);
                        }
                        continue;
                    }
                    /* Non-literal initializer — fall through to .bss. */
                }
                if (current_section != 3) {
                    cg_write_str(cg, "    .section .bss\n");
                    current_section = 3;
                }
                /* BSS sizing.  cg_r3's array index/store logic uses
                 * an 8-byte stride uniformly (Stage-0 simplification),
                 * so .bss must be sized at count*8 even when the
                 * declared element width is smaller — otherwise reads
                 * of `[u32;N]`/`[u16;N]` past the byte-narrow extent
                 * spill into adjacent BSS.  The data-section literal
                 * path above honors element width because that is
                 * required for byte-accurate string/blob initializers
                 * consumed via `&X as u64` byte arithmetic; bss arrays
                 * are not consumed that way (they hold runtime state
                 * accessed via the indexed-store/load instructions). */
                uint64_t byte_size = 8;
                const iii_ast_node_t *vt = iii_ast_get(cg->ast, d->u.var_decl.type_node);
                if (vt && vt->kind == III_AST_TYPE_ARRAY) {
                    byte_size = (uint64_t)vt->u.type_array.count * 8u;
                }
                cg_write_str(cg, "    .global ");
                emit_decl_label(cg, d->u.var_decl.name);
                cg_write_str(cg, "\n");
                emit_decl_label(cg, d->u.var_decl.name);
                cg_writef(cg, ":\n    .zero %llu\n", (unsigned long long)byte_size);
            }
        }
    }

    /* Function emission. */
    const iii_ast_node_t *mod = iii_ast_get(cg->ast, iii_ast_root_module(cg->ast));
    if (!mod || mod->kind != III_AST_MODULE) return III_CG_R3_E_INTERNAL;
    int first_err = III_CG_R3_OK;
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(cg->ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(cg->ast, did);
        if (!d) continue;
        switch (d->kind) {
            case III_AST_FN_DECL:
                if (emit_function(cg, did, d->u.fn_decl.name,
                                  d->u.fn_decl.params, d->u.fn_decl.body_block,
                                  /*is_cycle=*/false) != 0) {
                    if (first_err == III_CG_R3_OK) first_err = cg->last_error
                        ? cg->last_error : III_CG_R3_E_INTERNAL;
                    /* D11: keep walking. */
                }
                break;
            case III_AST_CYCLE_DECL: {
                if (emit_function(cg, did, d->u.cycle_decl.name,
                                  d->u.cycle_decl.params, d->u.cycle_decl.forward_block,
                                  /*is_cycle=*/true) != 0) {
                    if (first_err == III_CG_R3_OK) first_err = cg->last_error
                        ? cg->last_error : III_CG_R3_E_INTERNAL;
                }
                break;
            }
            case III_AST_SEALED_CALL_METHOD_DECL:
                /* Sealed-call methods are R-2-only by construction; R3
                 * does not materialise them.  Sema rejects R3 invocation
                 * sites; the decl itself is permitted in any module
                 * (declarative form) but its body is never emitted at R3. */
                break;
            default:
                /* Skip type/const/extern/mobius/schema in cg_r3 — these
                 * are not function-emitting decls. */
                break;
        }
    }

    /* D14: per-emit reproducibility audit. */
    if (cg->has_expected_witness) {
        uint8_t got[32];
        iii_sha256_t snapshot = cg->witness;
        iii_sha256_final(&snapshot, got);
        if (memcmp(got, cg->expected_witness, 32) != 0) {
            cg->last_error = III_CG_R3_E_WITNESS_MISMATCH;
            cg->error_count++;
            if (first_err == III_CG_R3_OK) first_err = III_CG_R3_E_WITNESS_MISMATCH;
        }
    }

    return first_err;
}

/* ─── Witness API ─────────────────────────────────────────────────── */

int iii_cg_r3_get_witness(const iii_cg_r3_state_t *cg, uint8_t out32[32])
{
    if (!cg || !out32) return III_CG_R3_E_NULL_ARG;
    /* Snapshot — don't mutate the live sponge. */
    iii_sha256_t snapshot = cg->witness;
    iii_sha256_final(&snapshot, out32);
    return III_CG_R3_OK;
}

void iii_cg_r3_set_expected_witness(iii_cg_r3_state_t *cg,
                                    const uint8_t expected_mh32[32])
{
    if (!cg) return;
    if (expected_mh32) {
        memcpy(cg->expected_witness, expected_mh32, 32);
        cg->has_expected_witness = true;
    } else {
        cg->has_expected_witness = false;
    }
}

/* ─── Lifecycle / error info ──────────────────────────────────────── */

iii_cg_r3_state_t *iii_cg_r3_create(iii_ast_t *ast,
                                    iii_sema_state_t *sema,
                                    iii_sid_state_t *sid,
                                    iii_walloc_state_t *walloc)
{
    if (!ast) return NULL;
    iii_cg_r3_state_t *cg = (iii_cg_r3_state_t *)calloc(1, sizeof(*cg));
    if (!cg) return NULL;
    cg->ast = ast;
    cg->sema = sema;
    cg->sid = sid;
    cg->walloc = walloc;
    cg->last_error = III_CG_R3_OK;
    iii_sha256_init(&cg->witness);
    return cg;
}

void iii_cg_r3_destroy(iii_cg_r3_state_t *cg)
{
    if (!cg) return;
    free(cg);
}

int iii_cg_r3_last_error(const iii_cg_r3_state_t *cg)
{
    return cg ? cg->last_error : III_CG_R3_E_NULL_ARG;
}

int iii_cg_r3_error_count(const iii_cg_r3_state_t *cg)
{
    return cg ? (int)cg->error_count : 0;
}

const char *iii_cg_r3_error_name(int code)
{
    switch (code) {
        case III_CG_R3_OK:                 return "OK";
        case III_CG_R3_E_NULL_ARG:         return "NULL_ARG";
        case III_CG_R3_E_IO:               return "IO";
        case III_CG_R3_E_UNSUPPORTED:      return "UNSUPPORTED";
        case III_CG_R3_E_ABI_ALIGN:        return "ABI_ALIGN";
        case III_CG_R3_E_DUP_LABEL:        return "DUP_LABEL";
        case III_CG_R3_E_WITNESS_MISMATCH: return "WITNESS_MISMATCH";
        case III_CG_R3_E_INTERNAL:         return "INTERNAL";
        default: return "<unknown>";
    }
}
