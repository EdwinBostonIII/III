/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\witness_alloc.c
 *
 * III Stage-0 Witness Identifier Allocator — implementation.
 *
 * Strict NIH (libc only).  Deterministic across rebuilds: the
 * assignment is a pure function of the AST's module-decl-list
 * source order plus the module name string.
 *
 * SPEC CITATIONS
 * --------------
 *   xii_witness.h byte layout:
 *     bytes 64..67   step_kind             (XII_STEP_KIND_*)
 *     bytes 72..79   cycle_seq             (monotonic)
 *     bytes 94..95   plan_section_anchor   (16-bit forensic)
 *
 *   cycle-types.h reserved bands (CHARIOT-side):
 *     0x0000          NONE
 *     0x0010-0x002F   page-class cycles
 *     0x0030-0x004F   MSR-class cycles
 *     0x0050-0x006F   topology cycles
 *     0x0070-0x008F   domain cycles
 *     0x0090-0x00AF   composed cycles
 *     0x00B0-0x00CF   bringup-stage cycles
 *     0x00D0-0x00EF   vmexit-handler cycles
 *     0x00F0-0x01D3   subsystem cycles (MNEME, IOMMU, ...)
 *
 *   III's allocations sit at and above 0x0200, leaving 0x01D4..0x01FF
 *   free for late CHARIOT additions before colliding with III.
 */

#include "witness_alloc.h"

#include "ast.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

/* ─── State ────────────────────────────────────────────────────────── */

#define III_WALLOC_INIT_CAP   256u

struct iii_walloc_state {
    iii_walloc_record_t *records;
    uint32_t             count;
    uint32_t             cap;

    uint32_t             next_cycle_kind;     /* uint32_t to detect overflow past 0xFFFF */
    uint16_t             module_plan_anchor;  /* current run's anchor */
    bool                 sealed;

    iii_walloc_audit_fn  audit_fn;
    void                *audit_user;
};

/* ─── Reserved-range table ─────────────────────────────────────────── */

static const iii_walloc_reserved_range_t kReservedRanges[] = {
    { 0x0000u, 0x0000u, "NONE"     },
    { 0x0010u, 0x002Fu, "PAGE"     },
    { 0x0030u, 0x004Fu, "MSR"      },
    { 0x0050u, 0x006Fu, "TOPO"     },
    { 0x0070u, 0x008Fu, "DOMAIN"   },
    { 0x0090u, 0x00AFu, "COMPOSED" },
    { 0x00B0u, 0x00CFu, "BRINGUP"  },
    { 0x00D0u, 0x00EFu, "VMEXIT"   },
    { 0x00F0u, 0x01FFu, "SUBSYS"   },
};

const iii_walloc_reserved_range_t *iii_walloc_reserved_ranges(uint32_t *out_count)
{
    if (out_count) {
        *out_count = (uint32_t)(sizeof(kReservedRanges) / sizeof(kReservedRanges[0]));
    }
    return kReservedRanges;
}

static bool kind_is_reserved(uint16_t k)
{
    for (size_t i = 0; i < sizeof(kReservedRanges)/sizeof(kReservedRanges[0]); i++) {
        if (k >= kReservedRanges[i].lo && k <= kReservedRanges[i].hi) return true;
    }
    return false;
}

/* ─── Lifecycle ────────────────────────────────────────────────────── */

iii_walloc_state_t *iii_walloc_create(void)
{
    iii_walloc_state_t *st = (iii_walloc_state_t *)calloc(1, sizeof(*st));
    if (!st) return NULL;
    st->records = (iii_walloc_record_t *)calloc(III_WALLOC_INIT_CAP, sizeof(iii_walloc_record_t));
    if (!st->records) { free(st); return NULL; }
    st->cap                = III_WALLOC_INIT_CAP;
    st->count              = 0u;
    st->next_cycle_kind    = III_WALLOC_CYCLE_KIND_BASE;
    st->module_plan_anchor = III_WALLOC_PLAN_ANCHOR_BASE;
    st->sealed             = false;
    return st;
}

void iii_walloc_destroy(iii_walloc_state_t *st)
{
    if (!st) return;
    free(st->records);
    free(st);
}

void iii_walloc_set_audit(iii_walloc_state_t *st, iii_walloc_audit_fn fn, void *user)
{
    if (!st) return;
    st->audit_fn   = fn;
    st->audit_user = user;
}

/* ─── Helpers ──────────────────────────────────────────────────────── */

static int grow_records(iii_walloc_state_t *st)
{
    uint32_t new_cap = st->cap * 2u;
    if (new_cap < st->cap) return III_WALLOC_E_OOM;
    iii_walloc_record_t *p =
        (iii_walloc_record_t *)realloc(st->records, (size_t)new_cap * sizeof(*p));
    if (!p) return III_WALLOC_E_OOM;
    /* zero the fresh tail */
    memset(p + st->cap, 0, (size_t)(new_cap - st->cap) * sizeof(*p));
    st->records = p;
    st->cap     = new_cap;
    return III_WALLOC_OK;
}

/* Deterministic per-module plan_anchor: FNV-1a-style reduction over
 * the module name bytes, masked into the 0x0C00..0x0CFF window.
 * Re-running on the same module string is bit-identical. */
static uint16_t derive_plan_anchor(const uint8_t *name, uint32_t len)
{
    uint32_t h = III_WALLOC_PLAN_ANCHOR_BASE;
    for (uint32_t i = 0; i < len; i++) {
        h = (h * 31u) ^ (uint32_t)name[i];
    }
    return (uint16_t)(III_WALLOC_PLAN_ANCHOR_BASE | (h & 0xFFu));
}

static bool decl_kind_is_witnessable(iii_ast_kind_t k)
{
    return k == III_AST_CYCLE_DECL
        || k == III_AST_MOBIUS_CANDIDATE_DECL
        || k == III_AST_SEALED_CALL_METHOD_DECL;
}

/* Extract the name iii_src_text_t for a witnessable decl kind. */
static bool decl_name(const iii_ast_node_t *d, iii_src_text_t *out)
{
    switch (d->kind) {
    case III_AST_CYCLE_DECL:              *out = d->u.cycle_decl.name;        return true;
    case III_AST_MOBIUS_CANDIDATE_DECL:   *out = d->u.mobius_candidate.name;  return true;
    case III_AST_SEALED_CALL_METHOD_DECL: *out = d->u.sealed_call.name;       return true;
    default: return false;
    }
}

/* ─── Allocation ───────────────────────────────────────────────────── */

int iii_walloc_run(iii_walloc_state_t *st, iii_ast_t *ast)
{
    if (!st || !ast) return III_WALLOC_E_NULL_ARG;
    if (st->sealed)   return III_WALLOC_E_SEALED;

    uint32_t root = iii_ast_root_module(ast);
    const iii_ast_node_t *mod = iii_ast_get(ast, root);
    if (!mod || mod->kind != III_AST_MODULE) return III_WALLOC_E_INVALID_AST;

    const uint8_t *src = iii_ast_source_buf(ast);
    if (!src) return III_WALLOC_E_INVALID_AST;

    st->module_plan_anchor =
        derive_plan_anchor(src + mod->u.module_.name.offset, mod->u.module_.name.length);

    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(ast, did);
        if (!d) continue;
        if (!decl_kind_is_witnessable(d->kind)) continue;

        if (st->next_cycle_kind > 0xFFFFu ||
            (st->next_cycle_kind - III_WALLOC_CYCLE_KIND_BASE) >= III_WALLOC_MAX_CYCLES) {
            return III_WALLOC_E_EXHAUSTED;
        }
        uint16_t k = (uint16_t)st->next_cycle_kind;
        if (kind_is_reserved(k)) return III_WALLOC_E_RESERVED_RANGE;

        /* Defensive: monotonic counter makes intra-state collisions
         * impossible, but verify anyway — cheap, catches future
         * refactors that reorder allocation. */
        for (uint32_t j = 0; j < st->count; j++) {
            if (st->records[j].cycle_kind == k) return III_WALLOC_E_DUPLICATE;
        }

        if (st->count >= st->cap) {
            int rc = grow_records(st);
            if (rc != III_WALLOC_OK) return rc;
        }

        iii_src_text_t name = (iii_src_text_t){0,0};
        (void)decl_name(d, &name);

        iii_walloc_record_t *r = &st->records[st->count++];
        r->decl_node   = did;
        r->name_off    = name.offset;
        r->name_len    = name.length;
        r->cycle_kind  = k;
        r->step_kind   = ((uint32_t)III_WALLOC_STEP_CATEGORY_CYCLE << 16) | (uint32_t)k;
        r->plan_anchor = st->module_plan_anchor;

        st->next_cycle_kind++;

        if (st->audit_fn) {
            iii_ast_position_t pos;
            uint32_t s = 0u, e = 0u;
            if (iii_ast_position_first(ast, did, &pos)) {
                /* Span surrogate: position byte; end is unknown at this
                 * pass, so we report (byte, byte) — consumers should
                 * treat as a point-position when end == start. */
                /* The discriminated iii_ast_position_t carries the
                 * byte offset for physical positions; we take a
                 * best-effort projection.  Audit callbacks that need
                 * full spans should walk the AST themselves. */
                (void)pos;
            }
            st->audit_fn(st->audit_user,
                         r->cycle_kind, r->plan_anchor,
                         r->name_off,   r->name_len,
                         s, e);
        }
    }
    return III_WALLOC_OK;
}

int iii_walloc_seal(iii_walloc_state_t *st)
{
    if (!st) return III_WALLOC_E_NULL_ARG;
    st->sealed = true;
    return III_WALLOC_OK;
}

bool iii_walloc_is_sealed(const iii_walloc_state_t *st)
{
    return st ? st->sealed : false;
}

/* ─── Read-back ────────────────────────────────────────────────────── */

const iii_walloc_record_t *iii_walloc_lookup(const iii_walloc_state_t *st,
                                             uint32_t decl_node)
{
    if (!st) return NULL;
    for (uint32_t i = 0; i < st->count; i++) {
        if (st->records[i].decl_node == decl_node) return &st->records[i];
    }
    return NULL;
}

uint32_t iii_walloc_record_count(const iii_walloc_state_t *st)
{
    return st ? st->count : 0u;
}

const iii_walloc_record_t *iii_walloc_record_at(const iii_walloc_state_t *st,
                                                uint32_t i)
{
    if (!st || i >= st->count) return NULL;
    return &st->records[i];
}

/* ─── Manifest emission ────────────────────────────────────────────── */

static int rec_cmp(const void *a, const void *b)
{
    const iii_walloc_record_t *ra = (const iii_walloc_record_t *)a;
    const iii_walloc_record_t *rb = (const iii_walloc_record_t *)b;
    if (ra->cycle_kind < rb->cycle_kind) return -1;
    if (ra->cycle_kind > rb->cycle_kind) return  1;
    return 0;
}

static char hex_nibble(unsigned v) { return (char)((v < 10) ? ('0' + v) : ('a' + v - 10)); }

static size_t emit_hex(char *buf, size_t cap, size_t pos, uint32_t v, int width)
{
    for (int i = width - 1; i >= 0; i--) {
        char c = hex_nibble((v >> (i * 4)) & 0xFu);
        if (buf && pos < cap) buf[pos] = c;
        pos++;
    }
    return pos;
}

static size_t emit_byte(char *buf, size_t cap, size_t pos, char c)
{
    if (buf && pos < cap) buf[pos] = c;
    return pos + 1;
}

size_t iii_walloc_emit_manifest(const iii_walloc_state_t *st,
                                const iii_ast_t          *ast,
                                char                     *buf,
                                size_t                    cap)
{
    if (!st || !ast) return 0;

    /* Sort a working copy by cycle_kind ascending for deterministic
     * cross-TU diffability. */
    iii_walloc_record_t *sorted = (iii_walloc_record_t *)
        malloc((size_t)st->count * sizeof(iii_walloc_record_t));
    if (!sorted && st->count > 0) return 0;
    if (st->count > 0) {
        memcpy(sorted, st->records, (size_t)st->count * sizeof(iii_walloc_record_t));
        qsort(sorted, st->count, sizeof(iii_walloc_record_t), rec_cmp);
    }

    const uint8_t *src = iii_ast_source_buf(ast);
    size_t pos = 0;
    for (uint32_t i = 0; i < st->count; i++) {
        const iii_walloc_record_t *r = &sorted[i];
        pos = emit_hex(buf, cap, pos, r->cycle_kind, 4);
        pos = emit_byte(buf, cap, pos, ' ');
        pos = emit_hex(buf, cap, pos, r->step_kind, 8);
        pos = emit_byte(buf, cap, pos, ' ');
        pos = emit_hex(buf, cap, pos, r->plan_anchor, 4);
        pos = emit_byte(buf, cap, pos, ' ');
        if (src) {
            for (uint32_t j = 0; j < r->name_len; j++) {
                pos = emit_byte(buf, cap, pos, (char)src[r->name_off + j]);
            }
        }
        pos = emit_byte(buf, cap, pos, '\n');
    }
    if (buf && cap > 0) buf[(pos < cap) ? pos : (cap - 1)] = '\0';

    free(sorted);
    return pos;
}

/* ─── SHA-256 (FIPS 180-4) — strict NIH, scoped to this TU ─────────── */

typedef struct {
    uint32_t h[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    size_t   buflen;
} sha256_ctx_t;

static const uint32_t K256[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static uint32_t rotr32(uint32_t x, unsigned n) { return (x >> n) | (x << (32u - n)); }

static void sha256_init(sha256_ctx_t *c)
{
    c->h[0]=0x6a09e667u; c->h[1]=0xbb67ae85u; c->h[2]=0x3c6ef372u; c->h[3]=0xa54ff53au;
    c->h[4]=0x510e527fu; c->h[5]=0x9b05688cu; c->h[6]=0x1f83d9abu; c->h[7]=0x5be0cd19u;
    c->bitlen = 0; c->buflen = 0;
}

static void sha256_block(sha256_ctx_t *c, const uint8_t *p)
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] =  ((uint32_t)p[i*4+0] << 24)
             |  ((uint32_t)p[i*4+1] << 16)
             |  ((uint32_t)p[i*4+2] <<  8)
             |  ((uint32_t)p[i*4+3]      );
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr32(w[i-15], 7) ^ rotr32(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = rotr32(w[i-2], 17) ^ rotr32(w[i-2],  19) ^ (w[i-2]  >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = rotr32(e,6) ^ rotr32(e,11) ^ rotr32(e,25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + K256[i] + w[i];
        uint32_t S0 = rotr32(a,2) ^ rotr32(a,13) ^ rotr32(a,22);
        uint32_t mj = (a & b) ^ (a & cc) ^ (b & cc);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1; d = cc; cc = b; b = a; a = t1 + t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g;  c->h[7]+=h;
}

static void sha256_update(sha256_ctx_t *c, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    c->bitlen += (uint64_t)len * 8u;
    while (len) {
        size_t take = 64u - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take; p += take; len -= take;
        if (c->buflen == 64u) { sha256_block(c, c->buf); c->buflen = 0; }
    }
}

static void sha256_final(sha256_ctx_t *c, uint8_t out[32])
{
    uint64_t bits = c->bitlen;
    uint8_t pad = 0x80u;
    sha256_update(c, &pad, 1);
    uint8_t z = 0x00u;
    while (c->buflen != 56u) sha256_update(c, &z, 1);
    uint8_t lenbuf[8];
    for (int i = 0; i < 8; i++) lenbuf[i] = (uint8_t)(bits >> (56 - i*8));
    sha256_update(c, lenbuf, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4+0] = (uint8_t)(c->h[i] >> 24);
        out[i*4+1] = (uint8_t)(c->h[i] >> 16);
        out[i*4+2] = (uint8_t)(c->h[i] >>  8);
        out[i*4+3] = (uint8_t)(c->h[i]      );
    }
}

static void absorb_u32_be(sha256_ctx_t *c, uint32_t v)
{
    uint8_t b[4] = {
        (uint8_t)(v >> 24), (uint8_t)(v >> 16),
        (uint8_t)(v >>  8), (uint8_t)(v      )
    };
    sha256_update(c, b, 4);
}

void iii_walloc_anchor_mhash(const iii_walloc_state_t *st,
                             const iii_ast_t          *ast,
                             uint8_t                   out[32])
{
    sha256_ctx_t c;
    sha256_init(&c);
    if (!st || !out) { if (out) memset(out, 0, 32); return; }
    const uint8_t *src = ast ? iii_ast_source_buf(ast) : NULL;

    /* Domain separation tag.  Versioned so a later layout change
     * yields a different mhash on the same input. */
    static const char tag[] = "III_WALLOC_v1";
    sha256_update(&c, tag, sizeof(tag) - 1);

    for (uint32_t i = 0; i < st->count; i++) {
        const iii_walloc_record_t *r = &st->records[i];
        absorb_u32_be(&c, (uint32_t)r->cycle_kind);
        absorb_u32_be(&c, r->name_off);
        absorb_u32_be(&c, r->name_len);
        if (src) sha256_update(&c, src + r->name_off, r->name_len);
    }
    sha256_final(&c, out);
}

/* ─── Reproducibility self-check ───────────────────────────────────── */

int iii_walloc_verify(const iii_walloc_state_t *st, const iii_ast_t *ast)
{
    if (!st || !ast) return III_WALLOC_E_NULL_ARG;
    uint32_t root = iii_ast_root_module(ast);
    const iii_ast_node_t *mod = iii_ast_get(ast, root);
    if (!mod || mod->kind != III_AST_MODULE) return III_WALLOC_E_INVALID_AST;
    const uint8_t *src = iii_ast_source_buf(ast);
    if (!src) return III_WALLOC_E_INVALID_AST;

    uint16_t expected_anchor =
        derive_plan_anchor(src + mod->u.module_.name.offset, mod->u.module_.name.length);

    uint32_t seen = 0u;
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(ast, did);
        if (!d || !decl_kind_is_witnessable(d->kind)) continue;

        const iii_walloc_record_t *r = iii_walloc_lookup(st, did);
        if (!r) return III_WALLOC_E_MISMATCH;
        if (r->plan_anchor != expected_anchor) return III_WALLOC_E_MISMATCH;
        uint32_t expect_step =
            ((uint32_t)III_WALLOC_STEP_CATEGORY_CYCLE << 16) | (uint32_t)r->cycle_kind;
        if (r->step_kind != expect_step) return III_WALLOC_E_MISMATCH;
        if (kind_is_reserved(r->cycle_kind)) return III_WALLOC_E_RESERVED_RANGE;

        iii_src_text_t name = (iii_src_text_t){0,0};
        (void)decl_name(d, &name);
        if (r->name_off != name.offset || r->name_len != name.length) {
            return III_WALLOC_E_MISMATCH;
        }
        seen++;
    }
    /* The state may legitimately hold records from other modules in
     * cross-TU runs; we only require that this module's decls are
     * fully covered. */
    (void)seen;
    return III_WALLOC_OK;
}
