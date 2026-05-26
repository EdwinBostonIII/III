/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\link.c
 *
 * III Stage-0 Linker.  Verifies closure-pinned imports and emits a
 * deterministic linkage manifest.  Strict NIH (libc only) per
 * ADR-021.  See link.h for the deepening citations D1..D15.
 */
#include "link.h"
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#define III_LINK_MAX_MODULES   1024u
#define III_LINK_MAX_DEPS        64u   /* per module */
#define III_LINK_MAX_EXPORTS    256u   /* per module */
#define III_LINK_MAX_ERRORS      64u
#define III_LINK_NAME_CAP       256u
#define III_LINK_SYM_CAP        256u

/* ════════════════════════════════════════════════════════════════════
 * D12: SHA-256 — NIH FIPS-180-4.  Minimal, no external deps.
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    uint32_t s[8];
    uint64_t bits;
    uint8_t  buf[64];
    uint32_t len;
} iii_sha256_t;

static const uint32_t III_K256[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static inline uint32_t iii_rotr32(uint32_t x, uint32_t n){return (x>>n)|(x<<(32u-n));}

static void iii_sha256_compress(iii_sha256_t *h, const uint8_t b[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)b[i*4]<<24) | ((uint32_t)b[i*4+1]<<16) |
               ((uint32_t)b[i*4+2]<<8) |  (uint32_t)b[i*4+3];
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_rotr32(w[i-15],7)^iii_rotr32(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1 = iii_rotr32(w[i-2],17)^iii_rotr32(w[i-2],19)^(w[i-2]>>10);
        w[i] = w[i-16]+s0+w[i-7]+s1;
    }
    uint32_t a=h->s[0],bb=h->s[1],c=h->s[2],d=h->s[3];
    uint32_t e=h->s[4],f=h->s[5],g=h->s[6],hh=h->s[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_rotr32(e,6)^iii_rotr32(e,11)^iii_rotr32(e,25);
        uint32_t ch = (e&f)^(~e&g);
        uint32_t t1 = hh+S1+ch+III_K256[i]+w[i];
        uint32_t S0 = iii_rotr32(a,2)^iii_rotr32(a,13)^iii_rotr32(a,22);
        uint32_t mj = (a&bb)^(a&c)^(bb&c);
        uint32_t t2 = S0+mj;
        hh=g; g=f; f=e; e=d+t1; d=c; c=bb; bb=a; a=t1+t2;
    }
    h->s[0]+=a; h->s[1]+=bb; h->s[2]+=c; h->s[3]+=d;
    h->s[4]+=e; h->s[5]+=f; h->s[6]+=g; h->s[7]+=hh;
}

static void iii_sha256_init(iii_sha256_t *h)
{
    static const uint32_t IV[8] = {
        0x6a09e667u,0xbb67ae85u,0x3c6ef372u,0xa54ff53au,
        0x510e527fu,0x9b05688cu,0x1f83d9abu,0x5be0cd19u
    };
    memcpy(h->s, IV, sizeof(IV));
    h->bits = 0; h->len = 0;
}

static void iii_sha256_update(iii_sha256_t *h, const void *data, size_t n)
{
    const uint8_t *p = (const uint8_t *)data;
    h->bits += (uint64_t)n * 8u;
    while (n) {
        uint32_t take = 64u - h->len;
        if (take > n) take = (uint32_t)n;
        memcpy(h->buf + h->len, p, take);
        h->len += take; p += take; n -= take;
        if (h->len == 64) { iii_sha256_compress(h, h->buf); h->len = 0; }
    }
}

static void iii_sha256_final(iii_sha256_t *h, uint8_t out[32])
{
    h->buf[h->len++] = 0x80;
    if (h->len > 56) {
        while (h->len < 64) h->buf[h->len++] = 0;
        iii_sha256_compress(h, h->buf); h->len = 0;
    }
    while (h->len < 56) h->buf[h->len++] = 0;
    uint64_t bits = h->bits;
    for (int i = 7; i >= 0; i--) h->buf[56 + i] = (uint8_t)(bits & 0xff), bits >>= 8;
    iii_sha256_compress(h, h->buf);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(h->s[i] >> 24);
        out[i*4+1] = (uint8_t)(h->s[i] >> 16);
        out[i*4+2] = (uint8_t)(h->s[i] >> 8);
        out[i*4+3] = (uint8_t)(h->s[i]);
    }
}

/* ════════════════════════════════════════════════════════════════════
 * Internal data model
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    char           sym[III_LINK_SYM_CAP];
    iii_visibility_t vis;
    uint64_t       addr_token;
} iii_link_export_t;

typedef struct {
    char     name[III_LINK_NAME_CAP];
    uint8_t  local_mhash[32];
    uint8_t  closure_mhash[32];
    bool     closure_done;
    bool     closure_in_progress;   /* memo guard */

    /* direct dependencies, resolved lazily by name */
    uint32_t dep_count;
    char     dep_names[III_LINK_MAX_DEPS][III_LINK_NAME_CAP];
    int32_t  dep_idx[III_LINK_MAX_DEPS];   /* -1 until resolved */

    /* exports */
    uint32_t export_count;
    iii_link_export_t exports[III_LINK_MAX_EXPORTS];

    /* Tarjan scratch (D2) */
    int32_t  scc_index;
    int32_t  scc_lowlink;
    bool     scc_onstack;
} iii_link_module_t;

struct iii_link_state {
    iii_link_module_t modules[III_LINK_MAX_MODULES];
    uint32_t          mod_count;

    iii_link_error_t  errors[III_LINK_MAX_ERRORS];
    uint32_t          error_count;

    /* manifest (D4) */
    uint8_t  *manifest;
    size_t    manifest_len;

    /* audit */
    iii_link_audit_fn audit_fn;
    void             *audit_ud;

    /* state machine */
    bool     phase_b_started;     /* D3 */
    bool     finalized;
    bool     sealed;              /* D14 */
};

/* ════════════════════════════════════════════════════════════════════
 * Helpers
 * ════════════════════════════════════════════════════════════════ */

/* D15: spec — record an error, with optional witness payload. */
static void iii_link_record(iii_link_state_t *l,
                            int code, uint32_t use_node, const char *msg,
                            uint32_t witness_count,
                            const uint8_t witness_mhash[32])
{
    if (l->error_count >= III_LINK_MAX_ERRORS) return;
    iii_link_error_t *e = &l->errors[l->error_count++];
    e->code = code;
    e->message = msg;
    e->use_node = use_node;
    e->witness_count = witness_count;
    if (witness_mhash) memcpy(e->witness_mhash, witness_mhash, 32);
    else               memset(e->witness_mhash, 0, 32);
}

static int32_t iii_link_find_module(const iii_link_state_t *l, const char *qname)
{
    for (uint32_t i = 0; i < l->mod_count; i++) {
        if (strcmp(l->modules[i].name, qname) == 0) return (int32_t)i;
    }
    return -1;
}

static void iii_link_copy_str(char *dst, size_t cap, const char *src)
{
    size_t n = strlen(src);
    if (n >= cap) n = cap - 1;
    memcpy(dst, src, n);
    dst[n] = '\0';
}

/* Sorted insert of a 32-byte mhash into a fixed array (ascending lex).
 * Returns false if duplicate (caller's choice to dedup or not). */
static bool iii_link_sorted_insert_mhash(uint8_t arr[][32], uint32_t *count,
                                         uint32_t cap, const uint8_t v[32])
{
    uint32_t i = 0;
    for (; i < *count; i++) {
        int cmp = memcmp(v, arr[i], 32);
        if (cmp == 0) return false;
        if (cmp < 0)  break;
    }
    if (*count >= cap) return false;
    for (uint32_t j = *count; j > i; j--) memcpy(arr[j], arr[j-1], 32);
    memcpy(arr[i], v, 32);
    (*count)++;
    return true;
}

/* ════════════════════════════════════════════════════════════════════
 * Lifecycle
 * ════════════════════════════════════════════════════════════════ */

iii_link_state_t *iii_link_create(void)
{
    iii_link_state_t *l = (iii_link_state_t *)calloc(1, sizeof(*l));
    return l;
}

void iii_link_destroy(iii_link_state_t *l)
{
    if (!l) return;
    if (l->manifest) free(l->manifest);
    free(l);
}

/* ════════════════════════════════════════════════════════════════════
 * Registration (Phase A — D3)
 * ════════════════════════════════════════════════════════════════ */

int iii_link_register_module(iii_link_state_t *l,
                             const char *qualified_name,
                             const uint8_t closure_root[32])
{
    if (!l || !qualified_name || !closure_root) return III_LINK_E_NULL_ARG;
    if (l->sealed)            return III_LINK_E_SEALED;
    if (l->phase_b_started)   return III_LINK_E_PHASE;

    int32_t idx = iii_link_find_module(l, qualified_name);
    if (idx < 0) {
        if (l->mod_count >= III_LINK_MAX_MODULES) return III_LINK_E_TOO_MANY;
        idx = (int32_t)l->mod_count++;
        memset(&l->modules[idx], 0, sizeof(l->modules[idx]));
        iii_link_copy_str(l->modules[idx].name, III_LINK_NAME_CAP, qualified_name);
        l->modules[idx].scc_index = -1;
        l->modules[idx].scc_lowlink = -1;
        for (uint32_t i = 0; i < III_LINK_MAX_DEPS; i++)
            l->modules[idx].dep_idx[i] = -1;
    }
    /* Legacy path: the supplied root IS the closure (no dep info). */
    memcpy(l->modules[idx].local_mhash,   closure_root, 32);
    memcpy(l->modules[idx].closure_mhash, closure_root, 32);
    l->modules[idx].closure_done = true;
    l->modules[idx].dep_count = 0;
    return III_LINK_OK;
}

int iii_link_register_module_ex(iii_link_state_t *l,
                                const char *qualified_name,
                                const uint8_t local_mhash[32],
                                uint32_t dep_count,
                                const char *const dep_qualified_names[],
                                uint32_t export_count,
                                const char *const export_symbols[],
                                const iii_visibility_t *export_visibility,
                                const uint64_t *export_addr_tokens)
{
    if (!l || !qualified_name || !local_mhash) return III_LINK_E_NULL_ARG;
    if (l->sealed)          return III_LINK_E_SEALED;
    if (l->phase_b_started) return III_LINK_E_PHASE;
    if (dep_count    > III_LINK_MAX_DEPS    ||
        export_count > III_LINK_MAX_EXPORTS) return III_LINK_E_TOO_MANY;
    if (dep_count    && !dep_qualified_names) return III_LINK_E_NULL_ARG;
    if (export_count && (!export_symbols || !export_visibility ||
                         !export_addr_tokens)) return III_LINK_E_NULL_ARG;

    int32_t idx = iii_link_find_module(l, qualified_name);
    if (idx < 0) {
        if (l->mod_count >= III_LINK_MAX_MODULES) return III_LINK_E_TOO_MANY;
        idx = (int32_t)l->mod_count++;
        memset(&l->modules[idx], 0, sizeof(l->modules[idx]));
        iii_link_copy_str(l->modules[idx].name, III_LINK_NAME_CAP, qualified_name);
    }
    iii_link_module_t *m = &l->modules[idx];
    memcpy(m->local_mhash, local_mhash, 32);
    m->closure_done = false;
    m->closure_in_progress = false;
    m->scc_index = -1; m->scc_lowlink = -1; m->scc_onstack = false;

    m->dep_count = dep_count;
    for (uint32_t i = 0; i < dep_count; i++) {
        iii_link_copy_str(m->dep_names[i], III_LINK_NAME_CAP, dep_qualified_names[i]);
        m->dep_idx[i] = -1;   /* resolved in finalize */
    }
    for (uint32_t i = dep_count; i < III_LINK_MAX_DEPS; i++) m->dep_idx[i] = -1;

    m->export_count = export_count;
    for (uint32_t i = 0; i < export_count; i++) {
        iii_link_copy_str(m->exports[i].sym, III_LINK_SYM_CAP, export_symbols[i]);
        m->exports[i].vis        = export_visibility[i];
        m->exports[i].addr_token = export_addr_tokens[i];
    }
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * D2: Tarjan 1972 SCC.  Cite: SIAM J. Comput. 1(2), 1972.
 * Iterative formulation to avoid C-stack overflow on large graphs.
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    int32_t v;
    uint32_t next_succ;   /* next dep index to consider */
} iii_link_scc_frame_t;

static int iii_link_run_tarjan(iii_link_state_t *l)
{
    int32_t index = 0;
    int32_t stack[III_LINK_MAX_MODULES];
    uint32_t stack_top = 0;
    iii_link_scc_frame_t call[III_LINK_MAX_MODULES];
    uint32_t call_top = 0;

    for (uint32_t start = 0; start < l->mod_count; start++) {
        if (l->modules[start].scc_index >= 0) continue;
        call[call_top].v = (int32_t)start;
        call[call_top].next_succ = 0;
        call_top++;
        l->modules[start].scc_index = index;
        l->modules[start].scc_lowlink = index;
        index++;
        stack[stack_top++] = (int32_t)start;
        l->modules[start].scc_onstack = true;

        while (call_top) {
            iii_link_scc_frame_t *fr = &call[call_top - 1];
            iii_link_module_t *vm = &l->modules[fr->v];
            if (fr->next_succ < vm->dep_count) {
                uint32_t k = fr->next_succ++;
                int32_t  w = vm->dep_idx[k];
                if (w < 0) continue;     /* unresolved dep — handled later */
                iii_link_module_t *wm = &l->modules[w];
                if (wm->scc_index < 0) {
                    wm->scc_index = index;
                    wm->scc_lowlink = index;
                    index++;
                    stack[stack_top++] = w;
                    wm->scc_onstack = true;
                    if (call_top >= III_LINK_MAX_MODULES) return III_LINK_E_TOO_MANY;
                    call[call_top].v = w;
                    call[call_top].next_succ = 0;
                    call_top++;
                } else if (wm->scc_onstack) {
                    if (wm->scc_index < vm->scc_lowlink)
                        vm->scc_lowlink = wm->scc_index;
                }
            } else {
                /* finished v: pop SCC if root */
                if (vm->scc_lowlink == vm->scc_index) {
                    /* Collect SCC. If it has > 1 element OR a self-loop, refuse. */
                    uint32_t scc_size = 0;
                    int32_t  members[III_LINK_MAX_MODULES];
                    int32_t  w;
                    do {
                        w = stack[--stack_top];
                        l->modules[w].scc_onstack = false;
                        members[scc_size++] = w;
                    } while (w != fr->v);

                    bool self_loop = false;
                    if (scc_size == 1) {
                        iii_link_module_t *m = &l->modules[members[0]];
                        for (uint32_t k = 0; k < m->dep_count; k++)
                            if (m->dep_idx[k] == members[0]) { self_loop = true; break; }
                    }
                    if (scc_size > 1 || self_loop) {
                        /* D2: cycle witness = first member's local_mhash */
                        iii_link_record(l, III_LINK_E_CYCLE, 0,
                                        "Tarjan 1972: cyclic import closure",
                                        scc_size,
                                        l->modules[members[0]].local_mhash);
                        return III_LINK_E_CYCLE;
                    }
                }
                /* propagate lowlink to parent */
                call_top--;
                if (call_top) {
                    iii_link_scc_frame_t *pr = &call[call_top - 1];
                    iii_link_module_t *pm = &l->modules[pr->v];
                    if (vm->scc_lowlink < pm->scc_lowlink)
                        pm->scc_lowlink = vm->scc_lowlink;
                }
            }
        }
    }
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * D1: Merkle linkage closure mhash (memoized recursion).
 *     closure_mhash = SHA-256( "III_LINK_v1" || local_mhash ||
 *                              sorted(direct_dep_closure_mhashes) )
 * ════════════════════════════════════════════════════════════════ */
static int iii_link_compute_closure(iii_link_state_t *l, int32_t idx)
{
    iii_link_module_t *m = &l->modules[idx];
    if (m->closure_done)        return III_LINK_OK;
    if (m->closure_in_progress) return III_LINK_E_CYCLE; /* should be unreachable post-Tarjan */
    m->closure_in_progress = true;

    uint8_t sorted[III_LINK_MAX_DEPS][32];
    uint32_t scount = 0;

    for (uint32_t i = 0; i < m->dep_count; i++) {
        int32_t w = m->dep_idx[i];
        if (w < 0) {
            m->closure_in_progress = false;
            return III_LINK_E_UNKNOWN_MODULE;
        }
        int rc = iii_link_compute_closure(l, w);
        if (rc != III_LINK_OK) { m->closure_in_progress = false; return rc; }
        (void)iii_link_sorted_insert_mhash(sorted, &scount,
                                           III_LINK_MAX_DEPS,
                                           l->modules[w].closure_mhash);
    }

    iii_sha256_t h;
    iii_sha256_init(&h);
    iii_sha256_update(&h, III_LINK_DOMAIN_TAG, sizeof(III_LINK_DOMAIN_TAG) - 1);
    iii_sha256_update(&h, m->local_mhash, 32);
    for (uint32_t i = 0; i < scount; i++) iii_sha256_update(&h, sorted[i], 32);
    iii_sha256_final(&h, m->closure_mhash);

    m->closure_done = true;
    m->closure_in_progress = false;
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * D7: Symbol-collision detection.
 *     If two modules export the same symbol AND both are reachable
 *     in some module's closure, that's a collision.  We approximate
 *     conservatively by checking the global export table; any duplicate
 *     across modules is refused.  This is correct under the V0 rule
 *     that all registered modules participate in the link.
 * ════════════════════════════════════════════════════════════════ */
static int iii_link_check_collisions(iii_link_state_t *l)
{
    for (uint32_t i = 0; i < l->mod_count; i++) {
        const iii_link_module_t *mi = &l->modules[i];
        for (uint32_t a = 0; a < mi->export_count; a++) {
            for (uint32_t j = i + 1; j < l->mod_count; j++) {
                const iii_link_module_t *mj = &l->modules[j];
                for (uint32_t b = 0; b < mj->export_count; b++) {
                    if (strcmp(mi->exports[a].sym, mj->exports[b].sym) == 0) {
                        iii_link_record(l, III_LINK_E_COLLISION, 0,
                                        "symbol defined in two modules",
                                        2, mi->local_mhash);
                        return III_LINK_E_COLLISION;
                    }
                }
            }
        }
    }
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * D6: Manifest emission (transactional, sorted, footer-hashed).
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    int32_t   mod_idx;
    uint32_t  exp_idx;
} iii_link_man_ent_t;

static int iii_link_cmp_entry(const void *pa, const void *pb,
                              const iii_link_state_t *l)
{
    const iii_link_man_ent_t *a = (const iii_link_man_ent_t *)pa;
    const iii_link_man_ent_t *b = (const iii_link_man_ent_t *)pb;
    int c = memcmp(l->modules[a->mod_idx].local_mhash,
                   l->modules[b->mod_idx].local_mhash, 32);
    if (c) return c;
    return strcmp(l->modules[a->mod_idx].exports[a->exp_idx].sym,
                  l->modules[b->mod_idx].exports[b->exp_idx].sym);
}

/* Insertion sort (small N, deterministic, NIH). */
static void iii_link_sort_entries(iii_link_man_ent_t *e, uint32_t n,
                                  const iii_link_state_t *l)
{
    for (uint32_t i = 1; i < n; i++) {
        iii_link_man_ent_t key = e[i];
        uint32_t j = i;
        while (j > 0 && iii_link_cmp_entry(&e[j-1], &key, l) > 0) {
            e[j] = e[j-1]; j--;
        }
        e[j] = key;
    }
}

static void iii_link_put_u32_le(uint8_t *p, uint32_t v)
{
    p[0]=(uint8_t)v; p[1]=(uint8_t)(v>>8); p[2]=(uint8_t)(v>>16); p[3]=(uint8_t)(v>>24);
}
static void iii_link_put_u64_le(uint8_t *p, uint64_t v)
{
    for (int i = 0; i < 8; i++) p[i] = (uint8_t)(v >> (i*8));
}

static int iii_link_build_manifest(iii_link_state_t *l)
{
    uint32_t total = 0;
    for (uint32_t i = 0; i < l->mod_count; i++) total += l->modules[i].export_count;

    iii_link_man_ent_t *ents = NULL;
    if (total) {
        ents = (iii_link_man_ent_t *)calloc(total, sizeof(*ents));
        if (!ents) return III_LINK_E_OOM;
        uint32_t k = 0;
        for (uint32_t i = 0; i < l->mod_count; i++)
            for (uint32_t j = 0; j < l->modules[i].export_count; j++)
                ents[k++] = (iii_link_man_ent_t){ .mod_idx = (int32_t)i, .exp_idx = j };
        iii_link_sort_entries(ents, total, l);   /* D5 */
    }

    /* Compute size. */
    size_t entries_bytes = 0;
    for (uint32_t i = 0; i < total; i++) {
        size_t sl = strlen(l->modules[ents[i].mod_idx]
                           .exports[ents[i].exp_idx].sym);
        if (sl > III_LINK_MAX_SYM_LEN) { free(ents); return III_LINK_E_INTERNAL; }
        entries_bytes += 32 + 4 + sl + 8;
    }
    size_t total_bytes = III_LINK_HEADER_BYTES + entries_bytes + III_LINK_FOOTER_BYTES;

    /* D4: build into a temp buffer; only commit on success. */
    uint8_t *tmp = (uint8_t *)calloc(1, total_bytes ? total_bytes : 1);
    if (!tmp) { free(ents); return III_LINK_E_OOM; }

    iii_link_put_u32_le(tmp + 0,  III_LINK_MANIFEST_V1);
    iii_link_put_u32_le(tmp + 4,  III_LINK_MANIFEST_VER);
    iii_link_put_u32_le(tmp + 8,  total);
    iii_link_put_u32_le(tmp + 12, 0u);

    size_t off = III_LINK_HEADER_BYTES;
    for (uint32_t i = 0; i < total; i++) {
        iii_link_module_t *mm = &l->modules[ents[i].mod_idx];
        iii_link_export_t *ex = &mm->exports[ents[i].exp_idx];
        size_t sl = strlen(ex->sym);
        memcpy(tmp + off, mm->local_mhash, 32);     off += 32;
        iii_link_put_u32_le(tmp + off, (uint32_t)sl); off += 4;
        memcpy(tmp + off, ex->sym, sl);             off += sl;
        iii_link_put_u64_le(tmp + off, ex->addr_token); off += 8;

        if (l->audit_fn) {
            l->audit_fn(mm->local_mhash, ex->sym,
                        mm->local_mhash, ex->addr_token, l->audit_ud);
        }
    }

    /* D6 footer: SHA-256( "III_LINK_v1\0footer" || header || entries ) */
    iii_sha256_t h; iii_sha256_init(&h);
    static const char FOOTER_TAG[] = "III_LINK_v1\0footer";
    iii_sha256_update(&h, FOOTER_TAG, sizeof(FOOTER_TAG) - 1);
    iii_sha256_update(&h, tmp, off);
    iii_sha256_final(&h, tmp + off);

    /* commit */
    if (l->manifest) free(l->manifest);
    l->manifest = tmp;
    l->manifest_len = total_bytes;
    free(ents);
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * Phase B — finalize (D3)
 * ════════════════════════════════════════════════════════════════ */

int iii_link_finalize(iii_link_state_t *l)
{
    if (!l) return III_LINK_E_NULL_ARG;
    if (l->sealed) return III_LINK_E_SEALED;
    l->phase_b_started = true;

    /* Resolve dep names → indices (D3 boundary: all headers known). */
    for (uint32_t i = 0; i < l->mod_count; i++) {
        iii_link_module_t *m = &l->modules[i];
        for (uint32_t k = 0; k < m->dep_count; k++) {
            int32_t w = iii_link_find_module(l, m->dep_names[k]);
            if (w < 0) {
                iii_link_record(l, III_LINK_E_UNKNOWN_MODULE, 0,
                                "direct dep not registered", 0, NULL);
                return III_LINK_E_UNKNOWN_MODULE;
            }
            m->dep_idx[k] = w;
        }
    }

    /* Tarjan first (D2) — refuse cycles BEFORE closure mhashing. */
    int rc = iii_link_run_tarjan(l);
    if (rc != III_LINK_OK) return rc;

    /* Reset onstack flags (already done) and compute closures (D1). */
    for (uint32_t i = 0; i < l->mod_count; i++) {
        if (!l->modules[i].closure_done) {
            rc = iii_link_compute_closure(l, (int32_t)i);
            if (rc != III_LINK_OK) {
                iii_link_record(l, rc, 0,
                                "closure mhash computation failed", 0, NULL);
                return rc;
            }
        }
    }

    /* Symbol collision sweep (D7). */
    rc = iii_link_check_collisions(l);
    if (rc != III_LINK_OK) return rc;

    /* Build manifest (D4/D5/D6) — transactional. */
    rc = iii_link_build_manifest(l);
    if (rc != III_LINK_OK) {
        if (l->manifest) { free(l->manifest); l->manifest = NULL; l->manifest_len = 0; }
        iii_link_record(l, rc, 0, "manifest build failed", 0, NULL);
        return rc;
    }

    l->finalized = true;
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * Verify @closure(...) pins on AST use-decls (legacy entry point).
 * Now also enforces visibility (D8): if the importer module is in the
 * state's table, we look up the imported symbol's visibility and refuse
 * PRIVATE imports across module boundaries.
 * ════════════════════════════════════════════════════════════════ */

/* Same-package test: equal up to the last '.' segment. */
static bool iii_link_same_package(const char *a, const char *b)
{
    const char *ad = strrchr(a, '.');
    const char *bd = strrchr(b, '.');
    size_t alen = ad ? (size_t)(ad - a) : 0;
    size_t blen = bd ? (size_t)(bd - b) : 0;
    if (alen != blen) return false;
    return memcmp(a, b, alen) == 0;
}

int iii_link_verify_imports(iii_link_state_t *l, iii_ast_t *ast)
{
    if (!l || !ast) return III_LINK_E_NULL_ARG;
    if (l->sealed) return III_LINK_E_SEALED;

    uint32_t root_idx = iii_ast_root_module(ast);
    const iii_ast_node_t *mod = iii_ast_get(ast, root_idx);
    if (!mod || mod->kind != III_AST_MODULE) return III_LINK_E_INTERNAL;

    const uint8_t *src = iii_ast_source_buf(ast);
    char importer_qname[III_LINK_NAME_CAP] = {0};
    {
        size_t qn = mod->u.module_.name.length;
        if (qn >= sizeof(importer_qname)) qn = sizeof(importer_qname) - 1;
        memcpy(importer_qname, src + mod->u.module_.name.offset, qn);
    }

    for (uint32_t i = 0; i < mod->u.module_.uses.count; i++) {
        uint32_t uid = iii_ast_list_at(ast, mod->u.module_.uses, i);
        const iii_ast_node_t *u = iii_ast_get(ast, uid);
        if (!u || u->kind != III_AST_USE) continue;

        char qname[III_LINK_NAME_CAP];
        size_t qlen = u->u.use_.qualified_name.length;
        if (qlen >= sizeof(qname)) qlen = sizeof(qname) - 1;
        memcpy(qname, src + u->u.use_.qualified_name.offset, qlen);
        qname[qlen] = '\0';

        /* D9: closure pin (where present). */
        if (u->u.use_.closure_mhash_node != 0) {
            const iii_ast_node_t *mh =
                iii_ast_get(ast, u->u.use_.closure_mhash_node);
            if (mh && mh->kind == III_AST_EXPR_MHASH) {
                int32_t midx = iii_link_find_module(l, qname);
                if (midx < 0) {
                    iii_link_record(l, III_LINK_E_UNKNOWN_MODULE, uid,
                                    "imported module's closure_root is not registered; cannot verify pin",
                                    0, NULL);
                } else {
                    /* Use closure_mhash if computed, else local_mhash (legacy). */
                    const uint8_t *root = l->modules[midx].closure_done
                                          ? l->modules[midx].closure_mhash
                                          : l->modules[midx].local_mhash;
                    if (memcmp(root, mh->u.mhash_.mhash, 32) != 0) {
                        iii_link_record(l, III_LINK_E_CLOSURE_MISMATCH, uid,
                                        "use-decl @closure pin does not match the imported module's actual closure_root",
                                        0, mh->u.mhash_.mhash);
                    }
                }
            }
        }

        /* D8: visibility — only meaningful if both modules are
         * registered AND the imported module declared exports.
         * We treat the use-decl as importing every export of the
         * named module (Stage-0 approximation; selectors are a
         * later-stage concern). */
        int32_t midx = iii_link_find_module(l, qname);
        if (midx >= 0) {
            const iii_link_module_t *defm = &l->modules[midx];
            for (uint32_t e = 0; e < defm->export_count; e++) {
                iii_visibility_t v = defm->exports[e].vis;
                bool same_mod = (strcmp(importer_qname, qname) == 0);
                bool same_pkg = iii_link_same_package(importer_qname, qname);
                bool ok = false;
                switch (v) {
                    case III_VIS_PRIVATE:   ok = same_mod; break;
                    case III_VIS_MODULE:    ok = same_pkg; break;
                    case III_VIS_PUBLIC:    ok = true;     break;
                    case III_VIS_FEDERATED: ok = true;     break; /* importer-side check is out of scope here */
                }
                if (!ok) {
                    iii_link_record(l, III_LINK_E_VISIBILITY, uid,
                                    "import refused by visibility lattice",
                                    (uint32_t)v, defm->local_mhash);
                    break; /* one error per use is enough */
                }
            }
        }
    }
    return l->error_count == 0 ? III_LINK_OK : III_LINK_E_CLOSURE_MISMATCH;
}

/* ════════════════════════════════════════════════════════════════════
 * Pin-check (D9) — public entry
 * ════════════════════════════════════════════════════════════════ */

int iii_link_pin_check(const iii_link_state_t *l,
                       const char *qualified_name,
                       const uint8_t prior_local[32],
                       const uint8_t prior_closure[32])
{
    if (!l || !qualified_name || !prior_local || !prior_closure)
        return III_LINK_E_NULL_ARG;
    int32_t idx = iii_link_find_module(l, qualified_name);
    if (idx < 0) return III_LINK_E_UNKNOWN_MODULE;
    const iii_link_module_t *m = &l->modules[idx];
    if (memcmp(m->local_mhash, prior_local, 32) != 0) {
        /* Different source — pin doesn't apply; not our concern. */
        return III_LINK_OK;
    }
    if (!m->closure_done) return III_LINK_E_PHASE;
    if (memcmp(m->closure_mhash, prior_closure, 32) != 0)
        return III_LINK_E_PIN_MISMATCH;
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * Manifest accessors / self-check (D11)
 * ════════════════════════════════════════════════════════════════ */

int iii_link_get_manifest(const iii_link_state_t *l,
                          const uint8_t **out_buf,
                          size_t *out_len)
{
    if (!l || !out_buf || !out_len) return III_LINK_E_NULL_ARG;
    *out_buf = l->manifest;
    *out_len = l->manifest_len;
    return l->manifest ? III_LINK_OK : III_LINK_E_BAD_MANIFEST;
}

int iii_link_verify_manifest(const uint8_t *buf, size_t len)
{
    if (!buf) return III_LINK_E_NULL_ARG;
    if (len < (size_t)(III_LINK_HEADER_BYTES + III_LINK_FOOTER_BYTES))
        return III_LINK_E_BAD_MANIFEST;
    uint32_t magic = (uint32_t)buf[0] | ((uint32_t)buf[1]<<8) |
                     ((uint32_t)buf[2]<<16) | ((uint32_t)buf[3]<<24);
    uint32_t ver   = (uint32_t)buf[4] | ((uint32_t)buf[5]<<8) |
                     ((uint32_t)buf[6]<<16) | ((uint32_t)buf[7]<<24);
    uint32_t cnt   = (uint32_t)buf[8] | ((uint32_t)buf[9]<<8) |
                     ((uint32_t)buf[10]<<16) | ((uint32_t)buf[11]<<24);
    if (magic != III_LINK_MANIFEST_V1)  return III_LINK_E_BAD_MANIFEST;
    if (ver   != III_LINK_MANIFEST_VER) return III_LINK_E_BAD_MANIFEST;

    /* Walk entries and validate framing + sort order. */
    size_t off = III_LINK_HEADER_BYTES;
    uint8_t prev_mhash[32]; memset(prev_mhash, 0, 32);
    char    prev_sym[III_LINK_SYM_CAP]; prev_sym[0] = '\0';
    bool    have_prev = false;

    for (uint32_t i = 0; i < cnt; i++) {
        if (off + 32 + 4 > len - III_LINK_FOOTER_BYTES) return III_LINK_E_BAD_MANIFEST;
        const uint8_t *mh = buf + off; off += 32;
        uint32_t sl = (uint32_t)buf[off] | ((uint32_t)buf[off+1]<<8) |
                      ((uint32_t)buf[off+2]<<16) | ((uint32_t)buf[off+3]<<24);
        off += 4;
        if (sl > III_LINK_MAX_SYM_LEN) return III_LINK_E_BAD_MANIFEST;
        if (off + sl + 8 > len - III_LINK_FOOTER_BYTES) return III_LINK_E_BAD_MANIFEST;
        const uint8_t *sym = buf + off; off += sl;
        off += 8; /* addr_token */

        if (have_prev) {
            int c = memcmp(mh, prev_mhash, 32);
            if (c < 0) return III_LINK_E_BAD_MANIFEST;
            if (c == 0) {
                /* compare sym lex */
                size_t plen = strlen(prev_sym);
                size_t cmp_n = plen < sl ? plen : sl;
                int sc = memcmp(prev_sym, sym, cmp_n);
                if (sc > 0 || (sc == 0 && sl <= plen)) return III_LINK_E_BAD_MANIFEST;
            }
        }
        memcpy(prev_mhash, mh, 32);
        size_t cp = sl < (III_LINK_SYM_CAP - 1) ? sl : (III_LINK_SYM_CAP - 1);
        memcpy(prev_sym, sym, cp); prev_sym[cp] = '\0';
        have_prev = true;
    }
    if (off != len - III_LINK_FOOTER_BYTES) return III_LINK_E_BAD_MANIFEST;

    iii_sha256_t h; iii_sha256_init(&h);
    static const char FOOTER_TAG[] = "III_LINK_v1\0footer";
    iii_sha256_update(&h, FOOTER_TAG, sizeof(FOOTER_TAG) - 1);
    iii_sha256_update(&h, buf, off);
    uint8_t footer[32]; iii_sha256_final(&h, footer);
    if (memcmp(footer, buf + off, 32) != 0) return III_LINK_E_BAD_MANIFEST;
    return III_LINK_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * Audit / seal / errors / closure query
 * ════════════════════════════════════════════════════════════════ */

void iii_link_set_audit_sink(iii_link_state_t *l,
                             iii_link_audit_fn fn,
                             void *user_data)
{
    if (!l) return;
    l->audit_fn = fn;
    l->audit_ud = user_data;
}

int iii_link_seal(iii_link_state_t *l)
{
    if (!l) return III_LINK_E_NULL_ARG;
    l->sealed = true;
    return III_LINK_OK;
}
bool iii_link_is_sealed(const iii_link_state_t *l)
{
    return l ? l->sealed : false;
}

uint32_t iii_link_error_count(const iii_link_state_t *l)
{
    return l ? l->error_count : 0;
}
void iii_link_error_at(const iii_link_state_t *l,
                       uint32_t i, iii_link_error_t *out)
{
    if (!l || !out) return;
    if (i >= l->error_count) { memset(out, 0, sizeof(*out)); return; }
    *out = l->errors[i];
}

int iii_link_get_closure_mhash(const iii_link_state_t *l,
                               const char *qualified_name,
                               uint8_t out[32])
{
    if (!l || !qualified_name || !out) return III_LINK_E_NULL_ARG;
    int32_t idx = iii_link_find_module(l, qualified_name);
    if (idx < 0) return III_LINK_E_UNKNOWN_MODULE;
    if (!l->modules[idx].closure_done) return III_LINK_E_PHASE;
    memcpy(out, l->modules[idx].closure_mhash, 32);
    return III_LINK_OK;
}
