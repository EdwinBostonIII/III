/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\main.c
 *
 * III Stage-0 Compiler (iiis-0) — CLI orchestrator entry point.
 *
 * Pipeline (per ADR-021 §"Stage 0 boundaries"):
 *   read source(s) → SHA-256 source mhash → lex → parse → ast → sema
 *                  → sid → walloc → cg_<ring> → link verify
 *                  → emit assemble + link → SHA-256 output mhash
 *                  → seal orchestrator → optional build-witness JSON
 *
 * Strict NIH per ADR-021: only libc on the build host.  No third-party
 * libraries are linked.  A small SHA-256 implementation lives in this
 * translation unit (private, static) so the orchestrator does not pull
 * in any external crypto (ADR-021 §"Stage 0 may use libc only").
 *
 * Determinism (ADR-027 §"Reproducible builds"):
 *   - SOURCE_DATE_EPOCH is honored (default "0").
 *   - --reproducibility-check runs the full pipeline twice with cleared
 *     output state; the two output mhashes must be byte-identical.
 *   - Build-witness JSON is canonicalized (keys sorted, no whitespace).
 *
 * Public API preserved modulo nomenclature rename (logos_* → iii_*,
 * LGS_* → III_*, "logoss-0" → "iiis-0", `.lgs` → `.iii`).
 *
 * Usage:
 *   iiis-0 <source.iii> [--ring R3|R0|R-1|R-2|3|0|-1|-2]
 *                       [--out <path>] [--emit-asm-only]
 *                       [--reproducibility-check] [--emit-witness]
 *                       [--print-mhash] [--diag=json]
 *                       [-v|-vv|-vvv] [--version] [--help]
 */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <ctype.h>

#include "lex.h"
#include "ast.h"
#include "parse.h"
#include "sema.h"
#include "sid.h"
#include "proof.h"
#include "hexad_check.h"
#include "acc.h"
#include "ceiling.h"
#include "witness_alloc.h"
#include "cg_r3.h"
#include "cg_r0.h"
#include "cg_rm1.h"
#include "cg_rm2.h"
#include "link.h"
#include "emit.h"

/* ─── Versioning (ADR-021 §"Tool versioning") ──────────────────────── */

#define III_IIIS0_VERSION_MAJOR 0
#define III_IIIS0_VERSION_MINOR 1
#define III_IIIS0_VERSION_PATCH 0

#ifndef III_IIIS0_GIT_SHA
#define III_IIIS0_GIT_SHA "unknown"
#endif

/* ─── Stable structured exit codes (deepening D1) ─────────────────────
 * These values are CONTRACT.  Tests, CI scripts, and downstream tools
 * pin against these numbers; do not renumber. */

#define III_EXIT_OK              0
#define III_EXIT_USAGE           2
#define III_EXIT_LEX_FAIL        10
#define III_EXIT_PARSE_FAIL      11
#define III_EXIT_SEMA_FAIL       12
#define III_EXIT_WALLOC_FAIL     13
#define III_EXIT_CG_FAIL         14
#define III_EXIT_LINK_FAIL       15
#define III_EXIT_EMIT_FAIL       16
#define III_EXIT_REPRO_MISMATCH  17
#define III_EXIT_INTERNAL        50
#define III_EXIT_OOM             99

/* ─── Ring choice ─────────────────────────────────────────────────── */

typedef enum {
    III_RING_CHOICE_R3  = 1,
    III_RING_CHOICE_R0  = 2,
    III_RING_CHOICE_RM1 = 3,
    III_RING_CHOICE_RM2 = 4
} iii_ring_choice_t;

/* ─── Diagnostic mode ─────────────────────────────────────────────── */

typedef enum {
    III_DIAG_TEXT = 0,
    III_DIAG_JSON = 1
} iii_diag_mode_t;

/* ─── Orchestrator-wide state (D17 lock-and-seal) ─────────────────── */

typedef struct {
    iii_ring_choice_t ring;
    const char       *out_path;
    bool              emit_asm_only;
    bool              compile_only;       /* stop after assemble; emit .o */
    bool              link_mode;          /* positional args are .o, link to exe */
    bool              repro_check;
    bool              emit_witness;
    bool              print_mhash;
    iii_diag_mode_t   diag;
    int               verbose;
    bool              ring_explicit;

    /* Witness sink. */
    uint8_t           argv_mhash[32];
    uint8_t           output_mhash[32];
    bool              output_mhash_valid;
    int64_t           source_date_epoch;

    /* Source files (for now: 1; struct kept open for include expansion). */
    const char       *source_path;
    uint8_t           source_mhash[32];
    bool              source_mhash_valid;

    /* Tool version mhashes (gcc -v, ld -v) — captured by emit layer. */
    uint8_t           gcc_version_mhash[32];
    uint8_t           ld_version_mhash[32];
    bool              gcc_version_mhash_valid;
    bool              ld_version_mhash_valid;

    /* Sealed flag: post-pipeline writes refused. */
    bool              sealed;
} iii_orchestrator_t;

/* The single static orchestrator instance — accessible to signal
 * handlers so they can flush a partial witness on abort. */
static iii_orchestrator_t g_orch;

/* ─── Verbose macros (D8: stderr ONLY; stdout reserved) ──────────── */

static int g_verbose = 0;

#define III_VLOG(LEVEL, ...) do { \
    if (g_verbose >= (LEVEL)) { \
        fprintf(stderr, "[iiis-0:v%d] ", (LEVEL)); \
        fprintf(stderr, __VA_ARGS__); \
        fputc('\n', stderr); \
    } \
} while (0)

/* ─── OOM handler (D13) ──────────────────────────────────────────── */

static void iii_oom_die(const char *what)
{
    fprintf(stderr, "iiis-0: OUT OF MEMORY allocating %s\n",
            what ? what : "(unknown)");
    exit(III_EXIT_OOM);
}

/* xmalloc: any NULL return aborts with III_EXIT_OOM (D13).
 * Spec: ADR-021 §"NIH preservation" — libc allocators on the host. */
static void *iii_xmalloc(size_t n, const char *what)
{
    if (n == 0) n = 1;
    void *p = malloc(n);
    if (!p) iii_oom_die(what);
    return p;
}

/* ─── SHA-256 (private, static) — for argv/source/output mhash ─────
 * Spec: FIPS 180-4 §6.2.  Strict NIH: no external crypto deps. */

typedef struct {
    uint32_t h[8];
    uint64_t bits;
    uint8_t  buf[64];
    size_t   buflen;
} iii_sha256_ctx_t;

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

static uint32_t iii_sha_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32 - n)); }

static void iii_sha256_init(iii_sha256_ctx_t *c)
{
    c->h[0]=0x6a09e667u; c->h[1]=0xbb67ae85u; c->h[2]=0x3c6ef372u; c->h[3]=0xa54ff53au;
    c->h[4]=0x510e527fu; c->h[5]=0x9b05688cu; c->h[6]=0x1f83d9abu; c->h[7]=0x5be0cd19u;
    c->bits = 0; c->buflen = 0;
}

static void iii_sha256_block(iii_sha256_ctx_t *c, const uint8_t blk[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)blk[i*4]<<24)|((uint32_t)blk[i*4+1]<<16)|
               ((uint32_t)blk[i*4+2]<<8)|((uint32_t)blk[i*4+3]);
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_sha_rotr(w[i-15],7) ^ iii_sha_rotr(w[i-15],18) ^ (w[i-15] >> 3);
        uint32_t s1 = iii_sha_rotr(w[i-2],17) ^ iii_sha_rotr(w[i-2],19)  ^ (w[i-2]  >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_sha_rotr(e,6) ^ iii_sha_rotr(e,11) ^ iii_sha_rotr(e,25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + III_SHA256_K[i] + w[i];
        uint32_t S0 = iii_sha_rotr(a,2) ^ iii_sha_rotr(a,13) ^ iii_sha_rotr(a,22);
        uint32_t mj = (a & b) ^ (a & cc) ^ (b & cc);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1; d = cc; cc = b; b = a; a = t1 + t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g;  c->h[7]+=h;
}

static void iii_sha256_update(iii_sha256_ctx_t *c, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    c->bits += (uint64_t)len * 8;
    while (len) {
        size_t take = 64 - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take; p += take; len -= take;
        if (c->buflen == 64) {
            iii_sha256_block(c, c->buf);
            c->buflen = 0;
        }
    }
}

static void iii_sha256_final(iii_sha256_ctx_t *c, uint8_t out[32])
{
    uint64_t bits = c->bits;
    uint8_t pad = 0x80;
    iii_sha256_update(c, &pad, 1);
    uint8_t zero = 0;
    while (c->buflen != 56) iii_sha256_update(c, &zero, 1);
    uint8_t lenbe[8];
    for (int i = 0; i < 8; i++) lenbe[i] = (uint8_t)(bits >> (56 - 8*i));
    iii_sha256_update(c, lenbe, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(c->h[i] >> 24);
        out[i*4+1] = (uint8_t)(c->h[i] >> 16);
        out[i*4+2] = (uint8_t)(c->h[i] >> 8);
        out[i*4+3] = (uint8_t)(c->h[i]);
    }
}

static void iii_mhash_buf(const void *data, size_t len, uint8_t out[32])
{
    iii_sha256_ctx_t c;
    iii_sha256_init(&c);
    iii_sha256_update(&c, data, len);
    iii_sha256_final(&c, out);
}

/* SHA-256 a file by path; returns 0 on success, -1 on I/O failure. */
static int iii_mhash_file(const char *path, uint8_t out[32])
{
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    iii_sha256_ctx_t c;
    iii_sha256_init(&c);
    uint8_t buf[8192];
    for (;;) {
        size_t n = fread(buf, 1, sizeof(buf), f);
        if (n) iii_sha256_update(&c, buf, n);
        if (n < sizeof(buf)) {
            if (ferror(f)) { fclose(f); return -1; }
            break;
        }
    }
    fclose(f);
    iii_sha256_final(&c, out);
    return 0;
}

static void iii_mhash_to_hex(const uint8_t in[32], char out[65])
{
    static const char hex[] = "0123456789abcdef";
    for (int i = 0; i < 32; i++) {
        out[i*2]   = hex[(in[i] >> 4) & 0xF];
        out[i*2+1] = hex[ in[i]       & 0xF];
    }
    out[64] = 0;
}

/* ─── File I/O (libc only) ────────────────────────────────────────── */

static int iii_read_file(const char *path, uint8_t **out_bytes, size_t *out_len)
{
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return -1; }
    long size = ftell(f);
    if (size < 0) { fclose(f); return -1; }
    if (fseek(f, 0, SEEK_SET) != 0) { fclose(f); return -1; }
    uint8_t *buf = (uint8_t *)iii_xmalloc((size_t)size + 1, "source buffer");
    size_t r = fread(buf, 1, (size_t)size, f);
    fclose(f);
    if (r != (size_t)size) { free(buf); return -1; }
    buf[size] = 0;
    *out_bytes = buf;
    *out_len = (size_t)size;
    return 0;
}

/* ─── Argv canonicalization + mhash (D2) ──────────────────────────────
 * Canonical form: argv[0] (the tool basename) + argv[1..] joined with
 * a single 0x1F (US) separator; no environment, no PWD.  The basename
 * is used (not full path) so the same invocation hashes identically
 * regardless of where iiis-0 was launched from. */

static const char *iii_basename(const char *p)
{
    const char *b = p;
    for (const char *q = p; *q; q++) {
        if (*q == '/' || *q == '\\') b = q + 1;
    }
    return b;
}

static void iii_argv_canon_mhash(int argc, char **argv, uint8_t out[32])
{
    iii_sha256_ctx_t c;
    iii_sha256_init(&c);
    const char *prog = (argc > 0) ? iii_basename(argv[0]) : "iiis-0";
    iii_sha256_update(&c, prog, strlen(prog));
    uint8_t sep = 0x1F;
    for (int i = 1; i < argc; i++) {
        iii_sha256_update(&c, &sep, 1);
        iii_sha256_update(&c, argv[i], strlen(argv[i]));
    }
    iii_sha256_final(&c, out);
}

/* ─── SOURCE_DATE_EPOCH parse (ADR-027) ───────────────────────────── */

static int64_t iii_read_source_date_epoch(void)
{
    const char *s = getenv("SOURCE_DATE_EPOCH");
    if (!s || !*s) return 0;
    int64_t v = 0;
    for (const char *p = s; *p; p++) {
        if (*p < '0' || *p > '9') return 0;
        v = v * 10 + (*p - '0');
    }
    return v;
}

/* ─── JSON-emit primitives (canonical, no whitespace) (D6) ──────────── */

static void iii_json_emit_string(FILE *f, const char *s)
{
    fputc('"', f);
    for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
        switch (*p) {
            case '"':  fputs("\\\"", f); break;
            case '\\': fputs("\\\\", f); break;
            case '\b': fputs("\\b", f);  break;
            case '\f': fputs("\\f", f);  break;
            case '\n': fputs("\\n", f);  break;
            case '\r': fputs("\\r", f);  break;
            case '\t': fputs("\\t", f);  break;
            default:
                if (*p < 0x20) fprintf(f, "\\u%04x", (unsigned)*p);
                else fputc((int)*p, f);
        }
    }
    fputc('"', f);
}

static void iii_json_emit_hex32(FILE *f, const uint8_t in[32])
{
    char hex[65];
    iii_mhash_to_hex(in, hex);
    iii_json_emit_string(f, hex);
}

/* ─── Diagnostic emission (D9) ────────────────────────────────────── */

static void iii_diag_lex(const iii_lex_state_t *lex)
{
    iii_lex_error_t e;
    iii_lex_error_info((iii_lex_state_t *)lex, &e);
    if (e.code == III_LEX_OK) return;
    if (g_orch.diag == III_DIAG_JSON) {
        fprintf(stderr,
            "{\"phase\":\"lex\",\"code\":%d,\"line\":%u,\"col\":%u,\"message\":",
            e.code, e.line, e.col);
        iii_json_emit_string(stderr, e.message ? e.message : "");
        fputs("}\n", stderr);
    } else {
        fprintf(stderr, "lex error %d at %u:%u: %s\n",
                e.code, e.line, e.col, e.message ? e.message : "(no message)");
    }
}

static void iii_diag_parse(iii_parse_state_t *p)
{
    uint32_t n = iii_parse_error_count(p);
    for (uint32_t i = 0; i < n; i++) {
        iii_parse_error_t pe;
        iii_parse_error_at(p, i, &pe);
        if (g_orch.diag == III_DIAG_JSON) {
            fprintf(stderr,
                "{\"phase\":\"parse\",\"code\":\"%s\",\"line\":%u,\"col\":%u,\"message\":",
                iii_parse_error_name(pe.code), pe.line, pe.col);
            iii_json_emit_string(stderr, pe.message ? pe.message : "");
            fputs("}\n", stderr);
        } else {
            fprintf(stderr, "parse error %s at %u:%u: %s\n",
                    iii_parse_error_name(pe.code), pe.line, pe.col,
                    pe.message ? pe.message : "(no message)");
        }
    }
}

static void iii_diag_sema(const iii_sema_state_t *s)
{
    uint32_t n = iii_sema_error_count(s);
    for (uint32_t i = 0; i < n; i++) {
        iii_sema_error_t se;
        iii_sema_error_at(s, i, &se);
        if (g_orch.diag == III_DIAG_JSON) {
            fprintf(stderr,
                "{\"phase\":\"sema\",\"code\":\"%s\",\"line\":%u,\"col\":%u,\"hexad\":%u,\"message\":",
                iii_sema_error_name(se.code), se.line, se.col, (unsigned)se.hexad);
            iii_json_emit_string(stderr, se.message ? se.message : "");
            fputs("}\n", stderr);
        } else {
            fprintf(stderr, "sema error %s at %u:%u (hexad=0x%04x): %s\n",
                    iii_sema_error_name(se.code), se.line, se.col, se.hexad,
                    se.message ? se.message : "(no message)");
        }
    }
}

static void iii_diag_sid(const iii_sid_state_t *s)
{
    uint32_t n = iii_sid_error_count(s);
    for (uint32_t i = 0; i < n; i++) {
        iii_sid_error_t se;
        iii_sid_error_at(s, i, &se);
        if (g_orch.diag == III_DIAG_JSON) {
            fprintf(stderr,
                "{\"phase\":\"sid\",\"code\":\"%s\",\"cycle_decl_node\":%u,\"message\":",
                iii_sid_error_name(se.code), se.cycle_decl_node);
            iii_json_emit_string(stderr, se.message ? se.message : "");
            fputs("}\n", stderr);
        } else {
            fprintf(stderr, "sid error %s on cycle node %u: %s\n",
                    iii_sid_error_name(se.code), se.cycle_decl_node,
                    se.message ? se.message : "(no message)");
        }
    }
}

/* ─── Ring auto-detect (D7) ────────────────────────────────────────────
 * Linear pre-order scan of AST node pool, tracking the most recently
 * seen CYCLE_DECL.  Each RING_SET node carries a ring mask; if any
 * ring bit conflicts with the explicit --ring (when provided), we
 * REFUSE with III_EXIT_USAGE and name the offending cycle.  When --ring
 * was not provided, we infer from the first encountered RING_SET.
 *
 * Spec source: TELOS-GRAMMAR.bnf §"@ring modifier" + ADR-021 ring
 * separation invariants.  */

static unsigned iii_ring_choice_to_bit(iii_ring_choice_t r)
{
    switch (r) {
        case III_RING_CHOICE_R3:  return III_RING_R3;
        case III_RING_CHOICE_R0:  return III_RING_R0;
        case III_RING_CHOICE_RM1: return III_RING_RM1;
        case III_RING_CHOICE_RM2: return III_RING_RM2;
    }
    return 0;
}

static const char *iii_ring_choice_name(iii_ring_choice_t r)
{
    switch (r) {
        case III_RING_CHOICE_R3:  return "R3";
        case III_RING_CHOICE_R0:  return "R0";
        case III_RING_CHOICE_RM1: return "R-1";
        case III_RING_CHOICE_RM2: return "R-2";
    }
    return "?";
}

static iii_ring_choice_t iii_ring_choice_from_bit(unsigned bit)
{
    if (bit & III_RING_RM2) return III_RING_CHOICE_RM2;
    if (bit & III_RING_RM1) return III_RING_CHOICE_RM1;
    if (bit & III_RING_R0)  return III_RING_CHOICE_R0;
    return III_RING_CHOICE_R3;
}

/* Returns 0 on success, nonzero (III_EXIT_USAGE) on conflict.
 * Updates *out_ring if the orchestrator had not explicitly set --ring
 * and the AST carries a ring annotation. */
static int iii_ring_autodetect(const iii_ast_t       *ast,
                               bool                   ring_explicit,
                               iii_ring_choice_t     *io_ring)
{
    size_t n = iii_ast_node_count(ast);
    uint32_t    cur_cycle_node = (uint32_t)-1;
    unsigned    explicit_bit  = ring_explicit ? iii_ring_choice_to_bit(*io_ring) : 0;
    bool        any_seen      = false;
    unsigned    inferred_bit  = 0;

    for (size_t idx = 0; idx < n; idx++) {
        const iii_ast_node_t *node = iii_ast_get(ast, (uint32_t)idx);
        if (!node) continue;
        if (node->kind == III_AST_CYCLE_DECL) {
            /* Track most-recent cycle so a RING_SET error can name it
             * by source-relative node index.  The src_text payload is
             * an (offset,length) pair into the source buffer, not a
             * NUL-terminated string, so we report the node index. */
            cur_cycle_node = (uint32_t)idx;
        } else if (node->kind == III_AST_RING_SET) {
            unsigned mask = node->u.ring_set.mask;
            any_seen = true;
            if (ring_explicit) {
                if ((mask & explicit_bit) == 0) {
                    fprintf(stderr,
                        "iiis-0: ring mismatch — cycle (decl node %u) "
                        "declares @ring(mask=0x%x) but --ring=%s requested\n",
                        cur_cycle_node, mask, iii_ring_choice_name(*io_ring));
                    return III_EXIT_USAGE;
                }
            } else if (inferred_bit == 0) {
                inferred_bit = mask;
            } else if ((inferred_bit & mask) == 0) {
                fprintf(stderr,
                    "iiis-0: incompatible @ring annotations across cycles "
                    "(decl node %u mask=0x%x vs prior 0x%x); pass --ring explicitly\n",
                    cur_cycle_node, mask, inferred_bit);
                return III_EXIT_USAGE;
            } else {
                inferred_bit &= mask;
            }
        }
    }

    if (!ring_explicit && any_seen && inferred_bit != 0) {
        *io_ring = iii_ring_choice_from_bit(inferred_bit);
        III_VLOG(1, "ring auto-detected from @ring annotation: %s",
                 iii_ring_choice_name(*io_ring));
    }
    return 0;
}

/* ─── Build-witness JSON emitter (D6) ──────────────────────────────────
 * Schema: {tool, version, argv_mhash, source_files:[{path,mhash}],
 *          output_path, output_mhash, ring, format,
 *          source_date_epoch, gcc_version_mhash, ld_version_mhash}.
 * Keys emitted in lexicographic order; no whitespace. */

static const char *iii_format_name(iii_emit_format_t f)
{
    switch (f) {
        case III_EMIT_FORMAT_PE_EXE:         return "pe_exe";
        case III_EMIT_FORMAT_PE_DLL:         return "pe_dll";
        case III_EMIT_FORMAT_PE_SYS:         return "pe_sys";
        case III_EMIT_FORMAT_ELF_EXE:        return "elf_exe";
        case III_EMIT_FORMAT_RAW_BIN:        return "raw_bin";
        case III_EMIT_FORMAT_SANCTUM_OBJECT: return "sanctum_object";
    }
    return "unknown";
}

static int iii_witness_write(const char *witness_path,
                             iii_emit_format_t fmt)
{
    if (g_orch.sealed) {
        /* Refuse witness writes after seal (D17). */
        fprintf(stderr, "iiis-0: witness write refused (orchestrator sealed)\n");
        return III_EXIT_INTERNAL;
    }
    FILE *w = fopen(witness_path, "wb");
    if (!w) {
        fprintf(stderr, "iiis-0: cannot open witness sink %s\n", witness_path);
        return III_EXIT_EMIT_FAIL;
    }
    char ver[64];
    snprintf(ver, sizeof(ver), "%d.%d.%d",
             III_IIIS0_VERSION_MAJOR, III_IIIS0_VERSION_MINOR, III_IIIS0_VERSION_PATCH);

    /* Keys in sorted order: argv_mhash, format, gcc_version_mhash,
     * ld_version_mhash, output_mhash, output_path, ring,
     * source_date_epoch, source_files, tool, version. */
    fputc('{', w);
    fputs("\"argv_mhash\":", w);     iii_json_emit_hex32(w, g_orch.argv_mhash);
    fputs(",\"format\":", w);        iii_json_emit_string(w, iii_format_name(fmt));
    fputs(",\"gcc_version_mhash\":", w);
    if (g_orch.gcc_version_mhash_valid) iii_json_emit_hex32(w, g_orch.gcc_version_mhash);
    else fputs("null", w);
    fputs(",\"ld_version_mhash\":", w);
    if (g_orch.ld_version_mhash_valid) iii_json_emit_hex32(w, g_orch.ld_version_mhash);
    else fputs("null", w);
    fputs(",\"output_mhash\":", w);
    if (g_orch.output_mhash_valid) iii_json_emit_hex32(w, g_orch.output_mhash);
    else fputs("null", w);
    fputs(",\"output_path\":", w);   iii_json_emit_string(w, g_orch.out_path ? g_orch.out_path : "");
    fputs(",\"ring\":", w);          iii_json_emit_string(w, iii_ring_choice_name(g_orch.ring));
    fprintf(w, ",\"source_date_epoch\":%lld", (long long)g_orch.source_date_epoch);
    fputs(",\"source_files\":[", w);
    /* Single source for now. */
    fputc('{', w);
    fputs("\"mhash\":", w);
    if (g_orch.source_mhash_valid) iii_json_emit_hex32(w, g_orch.source_mhash);
    else fputs("null", w);
    fputs(",\"path\":", w);          iii_json_emit_string(w, g_orch.source_path ? g_orch.source_path : "");
    fputc('}', w);
    fputc(']', w);
    fputs(",\"tool\":\"iiis-0\"", w);
    fputs(",\"version\":", w);       iii_json_emit_string(w, ver);
    fputc('}', w);
    fclose(w);
    III_VLOG(1, "wrote build-witness: %s", witness_path);
    return III_EXIT_OK;
}

/* ─── Phase timing (D8: hierarchical at -vv/-vvv) ─────────────────── */

static double iii_now_ms(void)
{
    /* clock() is libc-only and deterministic enough for stderr timing.
     * Spec: ADR-027 §"Timing on stderr only — never mhashed". */
    return (double)clock() * 1000.0 / (double)CLOCKS_PER_SEC;
}

#define III_PHASE_BEGIN(NAME) \
    double _t_##NAME = iii_now_ms(); III_VLOG(2, "phase %s: begin", #NAME)
#define III_PHASE_END(NAME) \
    III_VLOG(2, "phase %s: end (%.2f ms)", #NAME, iii_now_ms() - _t_##NAME)

/* ─── Signal handlers (D12) ──────────────────────────────────────────
 * On SIGINT/SIGTERM, attempt to flush a partial witness (best-effort),
 * then exit III_EXIT_INTERNAL.  Async-signal-safety is RESPECTED:
 * we only set the volatile flag; real flush happens on next safe
 * point in main, except that here we accept a small risk of using
 * stdio because Stage 0 is host-only debugging. */

static volatile sig_atomic_t g_sig_caught = 0;

static void iii_sig_handler(int sig)
{
    g_sig_caught = sig;
    /* Best-effort: write a one-line stderr note and a partial witness
     * to "<out>.partial.witness.json" then exit. */
    const char *note = "iiis-0: caught signal, flushing partial witness\n";
    /* write(2) would be async-safe, but POSIX-only.  We use fputs
     * here, accepting the documented Stage-0 risk. */
    fputs(note, stderr);
    if (g_orch.out_path) {
        char path[2048];
        int n = snprintf(path, sizeof(path), "%s.partial.witness.json", g_orch.out_path);
        if (n > 0 && (size_t)n < sizeof(path)) {
            /* Forge a witness with whatever is currently in g_orch. */
            (void)iii_witness_write(path, III_EMIT_FORMAT_PE_EXE);
        }
    }
    _exit(III_EXIT_INTERNAL);
}

static void iii_install_signals(void)
{
    signal(SIGINT,  iii_sig_handler);
    signal(SIGTERM, iii_sig_handler);
}

/* ─── Pipeline runner ─────────────────────────────────────────────── */

static int iii_run_pipeline(const char       *src_path,
                            iii_ring_choice_t ring_in,
                            const char       *out_path,
                            bool              emit_asm_only,
                            bool              compile_only,
                            bool              ring_explicit,
                            uint8_t           output_mhash_out[32],
                            bool             *output_mhash_valid_out)
{
    *output_mhash_valid_out = false;

    /* ── Read + mhash source ───────────────────────────────────────── */
    III_PHASE_BEGIN(read);
    uint8_t *bytes = NULL;
    size_t   len = 0;
    if (iii_read_file(src_path, &bytes, &len) != 0) {
        fprintf(stderr, "iiis-0: cannot read %s\n", src_path);
        return III_EXIT_USAGE;
    }
    iii_mhash_buf(bytes, len, g_orch.source_mhash);
    g_orch.source_mhash_valid = true;
    III_PHASE_END(read);

    /* ── Lex + parse ───────────────────────────────────────────────── */
    III_PHASE_BEGIN(lex);
    iii_lex_state_t *lex = iii_lex_create(bytes, len, src_path);
    if (!lex) { fprintf(stderr, "iiis-0: lex create failed\n");
                free(bytes); return III_EXIT_LEX_FAIL; }
    iii_ast_t *ast = iii_ast_create(bytes, len, src_path);
    if (!ast) { fprintf(stderr, "iiis-0: ast create failed\n");
                iii_lex_destroy(lex); free(bytes); return III_EXIT_INTERNAL; }
    iii_parse_state_t *p = iii_parse_create(lex, ast);
    if (!p)   { fprintf(stderr, "iiis-0: parse create failed\n");
                iii_ast_destroy(ast); iii_lex_destroy(lex); free(bytes); return III_EXIT_INTERNAL; }
    int parse_ok = iii_parse_module(p);
    iii_diag_lex(lex);
    iii_diag_parse(p);
    III_PHASE_END(lex);
    if (!parse_ok) {
        iii_parse_destroy(p); iii_ast_destroy(ast); iii_lex_destroy(lex);
        free(bytes); return III_EXIT_PARSE_FAIL;
    }

    /* ── Ring auto-detect / verify (D7) ────────────────────────────── */
    iii_ring_choice_t ring = ring_in;
    int rc_ring = iii_ring_autodetect(ast, ring_explicit, &ring);
    if (rc_ring != 0) {
        iii_parse_destroy(p); iii_ast_destroy(ast); iii_lex_destroy(lex);
        free(bytes); return rc_ring;
    }
    g_orch.ring = ring;

    /* ── Sema + sid ────────────────────────────────────────────────── */
    III_PHASE_BEGIN(sema);
    iii_hexad_check_init();
    iii_acc_init_permissive();
    iii_ceil_init_denied();

    iii_sema_state_t *sema = iii_sema_create(ast);
    int sema_ok = iii_sema_run(sema);
    iii_diag_sema(sema);
    III_PHASE_END(sema);
    if (!sema_ok) {
        iii_sema_destroy(sema);
        iii_parse_destroy(p); iii_ast_destroy(ast); iii_lex_destroy(lex);
        free(bytes); return III_EXIT_SEMA_FAIL;
    }

    III_PHASE_BEGIN(sid);
    iii_sid_state_t *sid = iii_sid_create(ast, sema);
    int sid_ok = iii_sid_run(sid);
    iii_diag_sid(sid);
    III_PHASE_END(sid);
    if (!sid_ok) {
        iii_sid_destroy(sid); iii_sema_destroy(sema);
        iii_parse_destroy(p); iii_ast_destroy(ast); iii_lex_destroy(lex);
        free(bytes); return III_EXIT_SEMA_FAIL;
    }

    /* ── Witness allocation ─────────────────────────────────────────── */
    III_PHASE_BEGIN(walloc);
    iii_walloc_state_t *wa = iii_walloc_create();
    if (!wa) iii_oom_die("walloc state");
    if (iii_walloc_run(wa, ast) != 0) {
        fprintf(stderr, "iiis-0: witness allocation failed\n");
        iii_walloc_destroy(wa); iii_sid_destroy(sid); iii_sema_destroy(sema);
        iii_parse_destroy(p); iii_ast_destroy(ast); iii_lex_destroy(lex);
        free(bytes); return III_EXIT_WALLOC_FAIL;
    }
    for (uint32_t i = 0; i < iii_walloc_record_count(wa); i++) {
        const iii_walloc_record_t *r = iii_walloc_record_at(wa, i);
        iii_ceil_admit_kind(r->cycle_kind);
    }
    III_PHASE_END(walloc);

    /* ── Link verification ──────────────────────────────────────────── */
    III_PHASE_BEGIN(link);
    iii_link_state_t *lnk = iii_link_create();
    if (!lnk) iii_oom_die("link state");
    (void)iii_link_verify_imports(lnk, ast);
    {
        uint32_t ne = iii_link_error_count(lnk);
        bool hard_fail = false;
        for (uint32_t i = 0; i < ne; i++) {
            iii_link_error_t le;
            iii_link_error_at(lnk, i, &le);
            if (le.code == III_LINK_E_CLOSURE_MISMATCH) {
                fprintf(stderr, "link error: %s\n",
                        le.message ? le.message : "closure mismatch");
                hard_fail = true;
            }
        }
        if (hard_fail) {
            iii_link_destroy(lnk); iii_walloc_destroy(wa);
            iii_sid_destroy(sid); iii_sema_destroy(sema);
            iii_parse_destroy(p); iii_ast_destroy(ast); iii_lex_destroy(lex);
            free(bytes); return III_EXIT_LINK_FAIL;
        }
    }
    III_PHASE_END(link);

    /* ── Codegen ────────────────────────────────────────────────────── */
    III_PHASE_BEGIN(cg);
    char asm_path[1024];
    snprintf(asm_path, sizeof(asm_path), "%s.s", out_path);
    FILE *asm_out = fopen(asm_path, "w");
    if (!asm_out) {
        fprintf(stderr, "iiis-0: cannot open %s for write\n", asm_path);
        iii_link_destroy(lnk); iii_walloc_destroy(wa); iii_sid_destroy(sid);
        iii_sema_destroy(sema); iii_parse_destroy(p); iii_ast_destroy(ast);
        iii_lex_destroy(lex); free(bytes); return III_EXIT_EMIT_FAIL;
    }
    int cg_rc = 0;
    switch (ring) {
        case III_RING_CHOICE_R3: {
            iii_cg_r3_state_t *cg = iii_cg_r3_create(ast, sema, sid, wa);
            cg_rc = iii_cg_r3_emit_module(cg, asm_out);
            iii_cg_r3_destroy(cg);
            break;
        }
        case III_RING_CHOICE_R0: {
            iii_cg_r0_state_t *cg = iii_cg_r0_create(ast, sema, sid, wa);
            cg_rc = iii_cg_r0_emit_module(cg, asm_out);
            iii_cg_r0_destroy(cg);
            break;
        }
        case III_RING_CHOICE_RM1: {
            iii_cg_rm1_state_t *cg = iii_cg_rm1_create(ast, sema, sid, wa);
            cg_rc = iii_cg_rm1_emit_module(cg, asm_out);
            iii_cg_rm1_destroy(cg);
            break;
        }
        case III_RING_CHOICE_RM2: {
            iii_cg_rm2_state_t *cg = iii_cg_rm2_create(ast, sema, sid, wa);
            cg_rc = iii_cg_rm2_emit_module(cg, asm_out);
            iii_cg_rm2_destroy(cg);
            break;
        }
    }
    fclose(asm_out);
    III_PHASE_END(cg);
    if (cg_rc != 0) {
        fprintf(stderr, "iiis-0: codegen failed (rc=%d)\n", cg_rc);
        iii_link_destroy(lnk); iii_walloc_destroy(wa); iii_sid_destroy(sid);
        iii_sema_destroy(sema); iii_parse_destroy(p); iii_ast_destroy(ast);
        iii_lex_destroy(lex); free(bytes); return III_EXIT_CG_FAIL;
    }

    /* ── Emit (assemble + link) unless asm-only or compile-only ─────── */
    iii_emit_format_t fmt = III_EMIT_FORMAT_PE_EXE;
    switch (ring) {
        case III_RING_CHOICE_R3:  fmt = III_EMIT_FORMAT_PE_EXE; break;
        case III_RING_CHOICE_R0:  fmt = III_EMIT_FORMAT_PE_SYS; break;
        case III_RING_CHOICE_RM1: fmt = III_EMIT_FORMAT_RAW_BIN; break;
        case III_RING_CHOICE_RM2: fmt = III_EMIT_FORMAT_SANCTUM_OBJECT; break;
    }
    int emit_rc = III_EXIT_OK;
    if (emit_asm_only) {
        /* In asm-only mode the asm file IS the output. */
        if (iii_mhash_file(asm_path, output_mhash_out) == 0) {
            *output_mhash_valid_out = true;
        }
    } else if (compile_only) {
        /* In compile-only mode the .o is the output (no link). */
        III_PHASE_BEGIN(emit);
        if (iii_emit_assemble(asm_path, out_path) != 0) {
            fprintf(stderr, "iiis-0: assemble failed\n");
            emit_rc = III_EXIT_EMIT_FAIL;
        }
        III_PHASE_END(emit);
        if (emit_rc == III_EXIT_OK) {
            if (iii_mhash_file(out_path, output_mhash_out) == 0) {
                *output_mhash_valid_out = true;
            } else {
                fprintf(stderr, "iiis-0: cannot mhash output %s\n", out_path);
                emit_rc = III_EXIT_EMIT_FAIL;
            }
        }
    } else {
        III_PHASE_BEGIN(emit);
        char obj_path[1024];
        snprintf(obj_path, sizeof(obj_path), "%s.o", out_path);
        if (iii_emit_assemble(asm_path, obj_path) != 0) {
            fprintf(stderr, "iiis-0: assemble failed\n");
            emit_rc = III_EXIT_EMIT_FAIL;
        } else {
            const char *objs[1] = { obj_path };
            if (iii_emit_link(fmt, objs, 1, out_path, NULL) != 0) {
                fprintf(stderr, "iiis-0: link failed\n");
                emit_rc = III_EXIT_LINK_FAIL;
            }
        }
        III_PHASE_END(emit);

        /* mhash the produced binary. */
        if (emit_rc == III_EXIT_OK) {
            if (iii_mhash_file(out_path, output_mhash_out) == 0) {
                *output_mhash_valid_out = true;
            } else {
                fprintf(stderr, "iiis-0: cannot mhash output %s\n", out_path);
                emit_rc = III_EXIT_EMIT_FAIL;
            }
        }
    }

    /* ── Lock-and-seal phase outputs (D17) ──────────────────────────── */
    (void)iii_walloc_seal(wa);
    (void)iii_link_seal(lnk);

    /* ── Cleanup ────────────────────────────────────────────────────── */
    iii_link_destroy(lnk);
    iii_walloc_destroy(wa);
    iii_sid_destroy(sid);
    iii_sema_destroy(sema);
    iii_parse_destroy(p);
    iii_ast_destroy(ast);
    iii_lex_destroy(lex);
    free(bytes);
    return emit_rc;
}

/* ─── --version / --help ──────────────────────────────────────────── */

/* ─── Link-only driver: input is a list of pre-assembled .o, output is exe.
 *     Used by the `--link` mode for staged multi-TU builds. */
static int iii_run_link_only(const char *const *objs, int n_objs,
                             iii_emit_format_t fmt, const char *out_path,
                             uint8_t output_mhash_out[32],
                             bool   *output_mhash_valid_out)
{
    *output_mhash_valid_out = false;
    if (n_objs <= 0) {
        fprintf(stderr, "iiis-0: --link requires at least one .o input\n");
        return III_EXIT_USAGE;
    }
    III_PHASE_BEGIN(emit);
    int rc = iii_emit_link(fmt, objs, (size_t)n_objs, out_path, NULL);
    III_PHASE_END(emit);
    if (rc != 0) {
        fprintf(stderr, "iiis-0: link failed (rc=%d)\n", rc);
        return III_EXIT_LINK_FAIL;
    }
    if (iii_mhash_file(out_path, output_mhash_out) == 0) {
        *output_mhash_valid_out = true;
    } else {
        fprintf(stderr, "iiis-0: cannot mhash output %s\n", out_path);
        return III_EXIT_EMIT_FAIL;
    }
    return III_EXIT_OK;
}

static void iii_print_version(void)
{
    fprintf(stdout, "iiis-0 v%d.%d.%d (commit %s)\n",
            III_IIIS0_VERSION_MAJOR, III_IIIS0_VERSION_MINOR,
            III_IIIS0_VERSION_PATCH, III_IIIS0_GIT_SHA);
}

static void iii_print_help(void)
{
    fputs(
        "iiis-0 — III Stage-0 compiler (CLI orchestrator)\n"
        "\n"
        "Usage:\n"
        "  iiis-0 <source.iii> [options]                  (single-source compile+link)\n"
        "  iiis-0 <a.iii> <b.iii> ... --compile-only      (multi-source compile to .o)\n"
        "  iiis-0 --link <a.o> <b.o> ... --out <exe>      (link-only)\n"
        "\n"
        "Options:\n"
        "  --ring R3|R0|R-1|R-2  Target ring (alias: --ring=3|0|-1|-2). Auto-\n"
        "                        detected from @ring(...) annotations if omitted.\n"
        "  --out <path>          Output path. Default: <source>.<ext>.\n"
        "  --emit-asm-only       Stop after codegen; do NOT assemble or link.\n"
        "  --compile-only        Stop after assemble; emit .o; do NOT link.\n"
        "  --link                Link mode: positional args are .o files.\n"
        "  --emit-witness        Write build-witness JSON sidecar at <out>.witness.json.\n"
        "  --reproducibility-check  Run pipeline twice; assert byte-identical mhash.\n"
        "  --print-mhash         Print output SHA-256 mhash to stdout and exit.\n"
        "  --diag=json           Emit parser/sema/link diagnostics as JSONL on stderr.\n"
        "  -v, -vv, -vvv         Verbose phase-timing on stderr.\n"
        "  --version             Print version to stdout.\n"
        "  --help                Print this help.\n"
        "\n"
        "Exit codes:\n"
        "  0   ok\n"
        "  2   usage error\n"
        "  10  lex failure\n"
        "  11  parse failure\n"
        "  12  sema failure\n"
        "  13  walloc failure\n"
        "  14  codegen failure\n"
        "  15  link failure\n"
        "  16  emit failure\n"
        "  17  reproducibility mismatch\n"
        "  50  internal error\n"
        "  99  out of memory\n",
        stdout);
}

/* ─── Argv parsing ────────────────────────────────────────────────── */

static int iii_parse_ring_arg(const char *r, iii_ring_choice_t *out)
{
    if (!strcmp(r, "R3")  || !strcmp(r, "3"))   { *out = III_RING_CHOICE_R3;  return 0; }
    if (!strcmp(r, "R0")  || !strcmp(r, "0"))   { *out = III_RING_CHOICE_R0;  return 0; }
    if (!strcmp(r, "R-1") || !strcmp(r, "-1"))  { *out = III_RING_CHOICE_RM1; return 0; }
    if (!strcmp(r, "R-2") || !strcmp(r, "-2"))  { *out = III_RING_CHOICE_RM2; return 0; }
    return -1;
}

int main(int argc, char **argv)
{
    /* Defaults. */
    g_orch.ring               = III_RING_CHOICE_R3;
    g_orch.out_path           = NULL;
    g_orch.emit_asm_only      = false;
    g_orch.compile_only       = false;
    g_orch.link_mode          = false;
    g_orch.repro_check        = false;
    g_orch.emit_witness       = false;
    g_orch.print_mhash        = false;
    g_orch.diag               = III_DIAG_TEXT;
    g_orch.verbose            = 0;
    g_orch.ring_explicit      = false;
    g_orch.source_date_epoch  = iii_read_source_date_epoch();
    g_orch.output_mhash_valid = false;
    g_orch.source_mhash_valid = false;
    g_orch.gcc_version_mhash_valid = false;
    g_orch.ld_version_mhash_valid  = false;
    g_orch.sealed             = false;

    iii_install_signals();

    /* Argv mhash (D2) covers the entire argument vector. */
    iii_argv_canon_mhash(argc, argv, g_orch.argv_mhash);

    /* Pre-scan for --version / --help: those bypass usage requirements. */
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--version")) { iii_print_version(); return III_EXIT_OK; }
        if (!strcmp(argv[i], "--help")    || !strcmp(argv[i], "-h")) {
            iii_print_help(); return III_EXIT_OK;
        }
    }

    if (argc < 2) { iii_print_help(); return III_EXIT_USAGE; }

    /* Collect all positional args; flags consume their value args inline. */
    const char **positionals = (const char **)iii_xmalloc(
        (size_t)argc * sizeof(*positionals), "positionals");
    int n_positionals = 0;

    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (a[0] != '-') {
            positionals[n_positionals++] = a;
        } else if (!strcmp(a, "--ring") && i + 1 < argc) {
            if (iii_parse_ring_arg(argv[++i], &g_orch.ring) != 0) {
                fprintf(stderr, "iiis-0: unknown ring '%s'\n", argv[i]);
                free(positionals);
                return III_EXIT_USAGE;
            }
            g_orch.ring_explicit = true;
        } else if (!strncmp(a, "--ring=", 7)) {
            if (iii_parse_ring_arg(a + 7, &g_orch.ring) != 0) {
                fprintf(stderr, "iiis-0: unknown ring '%s'\n", a + 7);
                free(positionals);
                return III_EXIT_USAGE;
            }
            g_orch.ring_explicit = true;
        } else if (!strcmp(a, "--out") && i + 1 < argc) {
            g_orch.out_path = argv[++i];
        } else if (!strcmp(a, "--reproducibility-check")) {
            g_orch.repro_check = true;
        } else if (!strcmp(a, "--emit-asm-only")) {
            g_orch.emit_asm_only = true;
        } else if (!strcmp(a, "--compile-only")) {
            g_orch.compile_only = true;
        } else if (!strcmp(a, "--link")) {
            g_orch.link_mode = true;
        } else if (!strcmp(a, "--emit-witness")) {
            g_orch.emit_witness = true;
        } else if (!strcmp(a, "--print-mhash")) {
            g_orch.print_mhash = true;
        } else if (!strcmp(a, "--diag=json")) {
            g_orch.diag = III_DIAG_JSON;
        } else if (!strcmp(a, "-v"))   { g_orch.verbose = 1; g_verbose = 1; }
        else if   (!strcmp(a, "-vv"))  { g_orch.verbose = 2; g_verbose = 2; }
        else if   (!strcmp(a, "-vvv")) { g_orch.verbose = 3; g_verbose = 3; }
        else {
            fprintf(stderr, "iiis-0: unknown argument '%s'\n", a);
            free(positionals);
            return III_EXIT_USAGE;
        }
    }

    if (n_positionals == 0) {
        fprintf(stderr, "iiis-0: missing input file(s)\n");
        free(positionals);
        return III_EXIT_USAGE;
    }

#ifdef IIIS_XII_ENABLED
    /* Phase XII-zeta runtime hook: if xii_lattice.bin exists alongside
     * the binary (or at XII_LATTICE_PATH), populate the omnia::xii_lattice
     * in-memory store with the sealed cells.  Missing file is graceful
     * (returns 0, runtime continues with empty Lattice).  A truncated or
     * mhash-mismatched file is a hard error -- a tampered Lattice cannot
     * be trusted at codegen time. */
    {
        extern int xii_lattice_load_into_store(const char *explicit_path,
                                               const char *argv0);
        int n_cells = xii_lattice_load_into_store(NULL, argv[0]);
        if (n_cells < 0) {
            fprintf(stderr,
                    "iiis-2: xii_lattice integrity failure (rc=%d); "
                    "refusing to compile against a tampered Lattice\n",
                    -n_cells);
            free(positionals);
            return III_EXIT_USAGE;
        }
        if (n_cells > 0 && g_orch.verbose >= 1) {
            fprintf(stderr, "iiis-2: loaded %d XII Lattice cells\n", n_cells);
        }
    }
#endif

    /* Mutually-exclusive mode flags. */
    if (g_orch.link_mode && (g_orch.compile_only || g_orch.emit_asm_only ||
                              g_orch.repro_check)) {
        fprintf(stderr,
                "iiis-0: --link cannot be combined with --compile-only, "
                "--emit-asm-only, or --reproducibility-check\n");
        free(positionals);
        return III_EXIT_USAGE;
    }

    /* ── Mode dispatch ──────────────────────────────────────────────── */

    /* ─── --link mode: pure linker, no source pipeline ──────────────── */
    if (g_orch.link_mode) {
        if (!g_orch.out_path) {
            fprintf(stderr, "iiis-0: --link requires --out <exe>\n");
            free(positionals);
            return III_EXIT_USAGE;
        }
        iii_emit_format_t fmt = III_EMIT_FORMAT_PE_EXE;
        switch (g_orch.ring) {
            case III_RING_CHOICE_R3:  fmt = III_EMIT_FORMAT_PE_EXE; break;
            case III_RING_CHOICE_R0:  fmt = III_EMIT_FORMAT_PE_SYS; break;
            case III_RING_CHOICE_RM1: fmt = III_EMIT_FORMAT_RAW_BIN; break;
            case III_RING_CHOICE_RM2: fmt = III_EMIT_FORMAT_SANCTUM_OBJECT; break;
        }
        uint8_t out_mh[32];
        bool    out_mh_ok = false;
        int rc = iii_run_link_only(positionals, n_positionals, fmt,
                                   g_orch.out_path, out_mh, &out_mh_ok);
        if (rc != III_EXIT_OK) { free(positionals); return rc; }
        if (out_mh_ok) {
            memcpy(g_orch.output_mhash, out_mh, 32);
            g_orch.output_mhash_valid = true;
        }
        if (g_orch.print_mhash && g_orch.output_mhash_valid) {
            char hex[65];
            iii_mhash_to_hex(g_orch.output_mhash, hex);
            fputs(hex, stdout); fputc('\n', stdout);
        }
        g_orch.sealed = true;
        free(positionals);
        return III_EXIT_OK;
    }

    /* ─── Multi-source compile-only: each src.iii → its own .o ─────── */
    if (n_positionals > 1) {
        if (!g_orch.compile_only) {
            fprintf(stderr,
                    "iiis-0: multiple sources require --compile-only\n");
            free(positionals);
            return III_EXIT_USAGE;
        }
        if (g_orch.out_path) {
            fprintf(stderr,
                    "iiis-0: --out is not permitted with multiple sources; "
                    "outputs default to <src>.o\n");
            free(positionals);
            return III_EXIT_USAGE;
        }
        if (g_orch.repro_check || g_orch.emit_witness || g_orch.print_mhash) {
            fprintf(stderr,
                    "iiis-0: --reproducibility-check / --emit-witness / "
                    "--print-mhash require single source\n");
            free(positionals);
            return III_EXIT_USAGE;
        }
        int multi_rc = III_EXIT_OK;
        for (int i = 0; i < n_positionals; i++) {
            const char *src = positionals[i];
            char this_out[1024];
            snprintf(this_out, sizeof(this_out), "%s.o", src);
            uint8_t mh[32]; bool mh_ok = false;
            g_orch.source_path = src;
            III_VLOG(1, "compile %s -> %s", src, this_out);
            int rc = iii_run_pipeline(src, g_orch.ring, this_out,
                                      false, true,
                                      g_orch.ring_explicit, mh, &mh_ok);
            if (rc != III_EXIT_OK) { multi_rc = rc; break; }
        }
        free(positionals);
        g_orch.sealed = true;
        return multi_rc;
    }

    /* ─── Single-source mode (legacy path) ──────────────────────────── */
    const char *src_path = positionals[0];
    free(positionals);
    char default_out[1024];
    g_orch.source_path = src_path;

    if (!g_orch.out_path) {
        const char *suffix = ".exe";
        if (g_orch.compile_only) {
            suffix = ".o";
        } else {
            switch (g_orch.ring) {
                case III_RING_CHOICE_R3:  suffix = ".exe"; break;
                case III_RING_CHOICE_R0:  suffix = ".sys"; break;
                case III_RING_CHOICE_RM1: suffix = ".bin"; break;
                case III_RING_CHOICE_RM2: suffix = ".sanctum.o"; break;
            }
        }
        snprintf(default_out, sizeof(default_out), "%s%s", src_path, suffix);
        g_orch.out_path = default_out;
    }

    III_VLOG(1, "iiis-0 starting: src=%s ring=%s out=%s",
             src_path, iii_ring_choice_name(g_orch.ring), g_orch.out_path);

    /* ── First pipeline run ─────────────────────────────────────────── */
    uint8_t out_mh1[32];
    bool    out_mh1_ok = false;
    int rc = iii_run_pipeline(src_path, g_orch.ring, g_orch.out_path,
                              g_orch.emit_asm_only, g_orch.compile_only,
                              g_orch.ring_explicit,
                              out_mh1, &out_mh1_ok);
    if (rc != III_EXIT_OK) return rc;
    if (out_mh1_ok) {
        memcpy(g_orch.output_mhash, out_mh1, 32);
        g_orch.output_mhash_valid = true;
    }

    /* ── Reproducibility check (D3) ─────────────────────────────────── */
    if (g_orch.repro_check) {
        char repro_out[2048];
        int n = snprintf(repro_out, sizeof(repro_out), "%s.repro", g_orch.out_path);
        if (n <= 0 || (size_t)n >= sizeof(repro_out)) {
            fprintf(stderr, "iiis-0: --reproducibility-check output path too long\n");
            return III_EXIT_USAGE;
        }
        uint8_t out_mh2[32];
        bool    out_mh2_ok = false;
        int rc2 = iii_run_pipeline(src_path, g_orch.ring, repro_out,
                                   g_orch.emit_asm_only, g_orch.compile_only,
                                   g_orch.ring_explicit,
                                   out_mh2, &out_mh2_ok);
        if (rc2 != III_EXIT_OK) return rc2;
        if (!out_mh1_ok || !out_mh2_ok || memcmp(out_mh1, out_mh2, 32) != 0) {
            fprintf(stderr, "iiis-0: REPRODUCIBILITY CHECK FAILED — mhash differs\n");
            return III_EXIT_REPRO_MISMATCH;
        }
        III_VLOG(1, "reproducibility check PASSED");
        fprintf(stderr, "iiis-0: reproducibility check PASSED\n");
    }

    /* ── Build-witness sidecar (D5) ─────────────────────────────────── */
    if (g_orch.emit_witness) {
        iii_emit_format_t fmt = III_EMIT_FORMAT_PE_EXE;
        switch (g_orch.ring) {
            case III_RING_CHOICE_R3:  fmt = III_EMIT_FORMAT_PE_EXE; break;
            case III_RING_CHOICE_R0:  fmt = III_EMIT_FORMAT_PE_SYS; break;
            case III_RING_CHOICE_RM1: fmt = III_EMIT_FORMAT_RAW_BIN; break;
            case III_RING_CHOICE_RM2: fmt = III_EMIT_FORMAT_SANCTUM_OBJECT; break;
        }
        char wp[2048];
        snprintf(wp, sizeof(wp), "%s.witness.json", g_orch.out_path);
        int wrc = iii_witness_write(wp, fmt);
        if (wrc != III_EXIT_OK) return wrc;
    }

    /* ── --print-mhash composes well with shell pipelines (D11) ─────── */
    if (g_orch.print_mhash) {
        if (!g_orch.output_mhash_valid) {
            fprintf(stderr, "iiis-0: output mhash unavailable\n");
            return III_EXIT_INTERNAL;
        }
        char hex[65];
        iii_mhash_to_hex(g_orch.output_mhash, hex);
        fputs(hex, stdout);
        fputc('\n', stdout);
    }

    /* ── Lock-and-seal orchestrator (D17) ───────────────────────────── */
    g_orch.sealed = true;
    III_VLOG(1, "orchestrator sealed; exit=%d", III_EXIT_OK);

    return III_EXIT_OK;
}
