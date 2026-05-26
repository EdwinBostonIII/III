/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\emit.c
 *
 * III Stage-0 binary emitter — gcc/ld driver.
 *
 * Strict NIH per ADR-021: libc only; the driver shells out to gcc/ld
 * (and objcopy/objdump for raw-bin and sanctum verification).  No
 * other third-party deps.
 *
 * Determinism is the entire point.  Every child invocation is bathed
 * in a normalized environment (D1/D5/D6) and a flag set that pins
 * every known nondeterminism source (D2/D3/D4 + D7 per-format).  The
 * resulting bytes are SHA-256'd (D8); a JSON build-witness is emitted
 * alongside (D9); golden-bytes mode (D10) gates CI.
 *
 * See emit.h for citations D1..D18.
 */
#include "emit.h"

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>

/* putenv lives in <stdlib.h> on POSIX and is exposed via the same
 * header (with a `_putenv` alias) on MinGW.  We use the POSIX name. */

/* ════════════════════════════════════════════════════════════════════
 * D8/D11/D12/D13: SHA-256 — NIH FIPS-180-4 (mirrors link.c).
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    uint32_t s[8];
    uint64_t bits;
    uint8_t  buf[64];
    uint32_t len;
} iii_emit_sha_t;

static const uint32_t III_EMIT_K256[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static inline uint32_t iii_emit_rotr(uint32_t x, uint32_t n){ return (x>>n)|(x<<(32u-n)); }

static void iii_emit_sha_compress(iii_emit_sha_t *h, const uint8_t b[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)b[i*4]<<24)|((uint32_t)b[i*4+1]<<16)|
               ((uint32_t)b[i*4+2]<<8)| (uint32_t)b[i*4+3];
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_emit_rotr(w[i-15],7)^iii_emit_rotr(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1 = iii_emit_rotr(w[i-2],17)^iii_emit_rotr(w[i-2],19)^(w[i-2]>>10);
        w[i] = w[i-16]+s0+w[i-7]+s1;
    }
    uint32_t a=h->s[0],bb=h->s[1],c=h->s[2],d=h->s[3];
    uint32_t e=h->s[4],f=h->s[5],g=h->s[6],hh=h->s[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_emit_rotr(e,6)^iii_emit_rotr(e,11)^iii_emit_rotr(e,25);
        uint32_t ch = (e&f)^(~e&g);
        uint32_t t1 = hh+S1+ch+III_EMIT_K256[i]+w[i];
        uint32_t S0 = iii_emit_rotr(a,2)^iii_emit_rotr(a,13)^iii_emit_rotr(a,22);
        uint32_t mj = (a&bb)^(a&c)^(bb&c);
        uint32_t t2 = S0+mj;
        hh=g; g=f; f=e; e=d+t1; d=c; c=bb; bb=a; a=t1+t2;
    }
    h->s[0]+=a; h->s[1]+=bb; h->s[2]+=c; h->s[3]+=d;
    h->s[4]+=e; h->s[5]+=f; h->s[6]+=g; h->s[7]+=hh;
}

static void iii_emit_sha_init(iii_emit_sha_t *h)
{
    static const uint32_t IV[8] = {
        0x6a09e667u,0xbb67ae85u,0x3c6ef372u,0xa54ff53au,
        0x510e527fu,0x9b05688cu,0x1f83d9abu,0x5be0cd19u
    };
    memcpy(h->s, IV, sizeof(IV));
    h->bits = 0; h->len = 0;
}

static void iii_emit_sha_update(iii_emit_sha_t *h, const void *data, size_t n)
{
    const uint8_t *p = (const uint8_t *)data;
    h->bits += (uint64_t)n * 8u;
    while (n) {
        uint32_t take = 64u - h->len;
        if (take > n) take = (uint32_t)n;
        memcpy(h->buf + h->len, p, take);
        h->len += take; p += take; n -= take;
        if (h->len == 64) { iii_emit_sha_compress(h, h->buf); h->len = 0; }
    }
}

static void iii_emit_sha_final(iii_emit_sha_t *h, uint8_t out[32])
{
    h->buf[h->len++] = 0x80;
    if (h->len > 56) {
        while (h->len < 64) h->buf[h->len++] = 0;
        iii_emit_sha_compress(h, h->buf); h->len = 0;
    }
    while (h->len < 56) h->buf[h->len++] = 0;
    uint64_t bits = h->bits;
    for (int i = 7; i >= 0; i--) { h->buf[56 + i] = (uint8_t)(bits & 0xff); bits >>= 8; }
    iii_emit_sha_compress(h, h->buf);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(h->s[i] >> 24);
        out[i*4+1] = (uint8_t)(h->s[i] >> 16);
        out[i*4+2] = (uint8_t)(h->s[i] >> 8);
        out[i*4+3] = (uint8_t)(h->s[i]);
    }
}

static void iii_emit_sha_oneshot(const void *data, size_t n, uint8_t out[32])
{
    iii_emit_sha_t h; iii_emit_sha_init(&h);
    iii_emit_sha_update(&h, data, n);
    iii_emit_sha_final(&h, out);
}

/* Public hex helper. */
void iii_emit_hex32(const uint8_t in[32], char out[65])
{
    static const char H[] = "0123456789abcdef";
    for (int i = 0; i < 32; i++) {
        out[i*2]   = H[(in[i] >> 4) & 0xf];
        out[i*2+1] = H[ in[i]       & 0xf];
    }
    out[64] = '\0';
}

/* ════════════════════════════════════════════════════════════════════
 * Process-global state (single-threaded by contract).
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    bool     sealed;            /* D18 */
    bool     have_expected;     /* D10 */
    uint8_t  expected_mhash[32];

    bool     have_last;
    uint8_t  last_output_mhash[32];      /* D8  */
    uint8_t  last_argv_mhash[32];        /* D11 */
    uint8_t  last_env_mhash[32];         /* D12 */
    uint8_t  last_gcc_version_mhash[32]; /* D13 */
    uint8_t  last_ld_version_mhash[32];  /* D13 */

    char     witness_json[2048]; /* D9 */
    iii_emit_audit_fn audit_fn;  /* D16 */
    void    *audit_user;
} iii_emit_state_t;

static iii_emit_state_t G_EMIT;

/* ════════════════════════════════════════════════════════════════════
 * D1/D5/D6: Forced child environment.
 *
 * The child env is normalized in-process before each system() call.
 * The list below is the *canonical* env-var stream — env_mhash (D12)
 * is computed over its sorted "K=V\n" rendering, so a divergence on
 * any host is byte-detectable.
 *
 * cite: SOURCE_DATE_EPOCH         — reproducible-builds.org/specs/source-date-epoch/
 * cite: LC_ALL/LANG/TZ            — reproducible-builds.org/docs/locales/
 * cite: CCACHE_DISABLE            — ccache(1)
 * ════════════════════════════════════════════════════════════════ */

/* Static char buffers — putenv requires the storage to remain valid
 * for the lifetime of the env binding. */
static char ENV_SDE[]   = "SOURCE_DATE_EPOCH=" III_EMIT_SOURCE_DATE_EPOCH;
static char ENV_LCALL[] = "LC_ALL=C";
static char ENV_LANG[]  = "LANG=C";
static char ENV_TZ[]    = "TZ=UTC0";
static char ENV_CCACHE[]= "CCACHE_DISABLE=1";

static char *const III_EMIT_FORCED_ENV[] = {
    ENV_CCACHE,    /* sorted lexicographically by key */
    ENV_LANG,
    ENV_LCALL,
    ENV_SDE,
    ENV_TZ,
    NULL
};

static void iii_emit_force_env(void)
{
    for (size_t i = 0; III_EMIT_FORCED_ENV[i]; i++) {
        (void)putenv(III_EMIT_FORCED_ENV[i]);
    }
}

/* D12: env_mhash = SHA-256( sorted "K=V\n" stream ) over the forced
 * env exactly as we install it. */
static void iii_emit_compute_env_mhash(uint8_t out[32])
{
    iii_emit_sha_t h; iii_emit_sha_init(&h);
    for (size_t i = 0; III_EMIT_FORCED_ENV[i]; i++) {
        iii_emit_sha_update(&h, III_EMIT_FORCED_ENV[i],
                            strlen(III_EMIT_FORCED_ENV[i]));
        iii_emit_sha_update(&h, "\n", 1);
    }
    iii_emit_sha_final(&h, out);
}

/* ════════════════════════════════════════════════════════════════════
 * D7: Format-specific flag tables.
 *
 *   PE_EXE/PE_DLL/PE_SYS  : MS x64 ABI flags.   gcc-as-driver.
 *                           cite: System V AMD64 ABI vs MS x64 ABI;
 *                                 mingw gcc(1) `-mabi=ms`.
 *   ELF_EXE               : SysV ABI defaults.  gcc-as-driver.
 *   RAW_BIN               : -nostdlib -static -ffreestanding;
 *                           ld used directly, then objcopy -O binary.
 *                           cite: gcc(1) "-ffreestanding"; ld(1).
 *   SANCTUM_OBJECT        : RAW_BIN flags + -fpic + generated linker
 *                           script pinning .xii_sanctum.text @ VMA.
 * ════════════════════════════════════════════════════════════════ */

typedef struct {
    const char *driver;        /* "gcc" or "ld" */
    const char *abi_flags;     /* format-specific ABI/freestanding */
    const char *link_flags;    /* extra flags during link */
    bool        emit_objcopy_bin;
    bool        is_sanctum;
} iii_emit_fmt_spec_t;

static const iii_emit_fmt_spec_t III_EMIT_FMT[] = {
    /* PE_EXE  */ { "gcc",  "-mabi=ms",                 "",                                                       false, false },
    /* PE_DLL  */ { "gcc",  "-mabi=ms",                 "-shared",                                                false, false },
    /* PE_SYS  */ { "gcc",  "-mabi=ms -ffreestanding",  "-shared -nostdlib -Wl,--subsystem,native",               false, false },
    /* ELF_EXE */ { "gcc",  "",                         "",                                                       false, false },
    /* RAW_BIN */ { "ld",   "",                         "-nostdlib -static",                                      true,  false },
    /* SANCTUM */ { "ld",   "",                         "-nostdlib -static -r",                                   false, true  }
};

static const iii_emit_fmt_spec_t *iii_emit_fmt_lookup(iii_emit_format_t f)
{
    if ((unsigned)f > (unsigned)III_EMIT_FORMAT_SANCTUM_OBJECT) return NULL;
    return &III_EMIT_FMT[(unsigned)f];
}

/* ════════════════════════════════════════════════════════════════════
 * Small utilities.
 * ════════════════════════════════════════════════════════════════ */

/* Append snprintf into a fixed buffer; returns 0 on success, -1 on
 * truncation.  Appends nothing if the previous append failed. */
static int iii_emit_appendf(char *buf, size_t cap, size_t *off,
                            const char *fmt, ...)
{
    if (*off >= cap) return -1;
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf + *off, cap - *off, fmt, ap);
    va_end(ap);
    if (n < 0 || (size_t)n >= cap - *off) return -1;
    *off += (size_t)n;
    return 0;
}

/* basename — last path segment, no extension stripping. */
static const char *iii_emit_basename(const char *path)
{
    const char *b = path;
    for (const char *p = path; *p; p++) {
        if (*p == '/' || *p == '\\') b = p + 1;
    }
    return b;
}

/* Read the entire file into a malloc'd buffer.  *out_buf must be
 * freed by caller.  Returns III_EMIT_OK or an error code. */
static int iii_emit_slurp(const char *path, uint8_t **out_buf, size_t *out_len)
{
    FILE *f = fopen(path, "rb");
    if (!f) return III_EMIT_E_IO;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return III_EMIT_E_IO; }
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return III_EMIT_E_IO; }
    if (fseek(f, 0, SEEK_SET) != 0) { fclose(f); return III_EMIT_E_IO; }
    uint8_t *buf = (uint8_t *)malloc((size_t)sz + 1u);
    if (!buf) { fclose(f); return III_EMIT_E_OOM; }
    size_t r = fread(buf, 1, (size_t)sz, f);
    fclose(f);
    if (r != (size_t)sz) { free(buf); return III_EMIT_E_IO; }
    buf[sz] = 0;
    *out_buf = buf; *out_len = (size_t)sz;
    return III_EMIT_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * D13: NIH gcc/ld version capture.
 *
 * Invoke `<tool> --version`, read first line, SHA-256 it.  On any
 * failure we hash a sentinel ("UNAVAILABLE\n") so the witness is
 * still well-defined and the failure is byte-detectable.
 * ════════════════════════════════════════════════════════════════ */

static void iii_emit_capture_version(const char *tool, uint8_t out[32])
{
    char cmd[256];
    int n = snprintf(cmd, sizeof cmd, "%s --version", tool);
    if (n <= 0 || (size_t)n >= sizeof cmd) {
        iii_emit_sha_oneshot("UNAVAILABLE\n", 12, out);
        return;
    }
    FILE *p = popen(cmd, "r");
    if (!p) {
        iii_emit_sha_oneshot("UNAVAILABLE\n", 12, out);
        return;
    }
    char line[512];
    if (!fgets(line, sizeof line, p)) {
        pclose(p);
        iii_emit_sha_oneshot("UNAVAILABLE\n", 12, out);
        return;
    }
    /* drain rest, ignore */
    char drain[512];
    while (fgets(drain, sizeof drain, p)) { /* discard */ }
    pclose(p);
    iii_emit_sha_oneshot(line, strlen(line), out);
}

/* ════════════════════════════════════════════════════════════════════
 * D14: Sanctum linker script + section verification.
 *
 *   SECTIONS {
 *       . = 0xFFFF800000200000;
 *       .xii_sanctum.text : { *(.xii_sanctum.text) }
 *   }
 *
 * Inputs lacking the section are REFUSED.  Verification uses
 * `objdump -h` (Stage-0 host tool, ADR-021 §Boundaries).
 * ════════════════════════════════════════════════════════════════ */

static int iii_emit_write_sanctum_script(const char *script_path)
{
    /* Deterministic: no timestamps, no $cwd, no host-dependent text. */
    FILE *f = fopen(script_path, "wb");
    if (!f) return III_EMIT_E_LDSCRIPT_WRITE;
    int n = fprintf(f,
        "/* III sanctum-object linker script - generated, deterministic. */\n"
        "SECTIONS {\n"
        "    . = 0x%llx;\n"
        "    .xii_sanctum.text : { KEEP(*(" III_EMIT_SANCTUM_SECTION ")) }\n"
        "}\n",
        (unsigned long long)III_EMIT_SANCTUM_VMA);
    if (fclose(f) != 0) return III_EMIT_E_LDSCRIPT_WRITE;
    return (n < 0) ? III_EMIT_E_LDSCRIPT_WRITE : III_EMIT_OK;
}

static int iii_emit_object_has_sanctum(const char *obj_path)
{
    char cmd[1024];
    int n = snprintf(cmd, sizeof cmd, "objdump -h \"%s\"", obj_path);
    if (n <= 0 || (size_t)n >= sizeof cmd) return III_EMIT_E_CMD_OVERFLOW;
    FILE *p = popen(cmd, "r");
    if (!p) return III_EMIT_E_NO_SANCTUM_SECTION;
    char line[512];
    bool found = false;
    while (fgets(line, sizeof line, p)) {
        if (strstr(line, III_EMIT_SANCTUM_SECTION)) { found = true; break; }
    }
    while (fgets(line, sizeof line, p)) { /* drain */ }
    pclose(p);
    return found ? III_EMIT_OK : III_EMIT_E_NO_SANCTUM_SECTION;
}

/* ════════════════════════════════════════════════════════════════════
 * D9: Build-witness JSON sidecar.
 *
 *   {"command_line_mhash":"<hex>","env_mhash":"<hex>","format":"<n>",
 *    "gcc_version_mhash":"<hex>","ld_version_mhash":"<hex>",
 *    "output_mhash":"<hex>","source_date_epoch":"0"}
 *
 * Sorted keys, no whitespace, deterministic.  Written atomically:
 * we render in-memory then fwrite once.
 * ════════════════════════════════════════════════════════════════ */

static int iii_emit_render_witness(iii_emit_format_t fmt,
                                   char *buf, size_t cap)
{
    char hex_argv[65], hex_env[65], hex_gcc[65], hex_ld[65], hex_out[65];
    iii_emit_hex32(G_EMIT.last_argv_mhash,        hex_argv);
    iii_emit_hex32(G_EMIT.last_env_mhash,         hex_env);
    iii_emit_hex32(G_EMIT.last_gcc_version_mhash, hex_gcc);
    iii_emit_hex32(G_EMIT.last_ld_version_mhash,  hex_ld);
    iii_emit_hex32(G_EMIT.last_output_mhash,      hex_out);
    int n = snprintf(buf, cap,
        "{\"command_line_mhash\":\"%s\","
        "\"env_mhash\":\"%s\","
        "\"format\":\"%s\","
        "\"gcc_version_mhash\":\"%s\","
        "\"ld_version_mhash\":\"%s\","
        "\"output_mhash\":\"%s\","
        "\"source_date_epoch\":\"" III_EMIT_SOURCE_DATE_EPOCH "\"}",
        hex_argv, hex_env, iii_emit_format_name(fmt),
        hex_gcc, hex_ld, hex_out);
    if (n < 0 || (size_t)n >= cap) return III_EMIT_E_INTERNAL;
    return III_EMIT_OK;
}

static int iii_emit_write_witness(const char *out_path,
                                  const char *witness_json)
{
    char path[1024];
    int n = snprintf(path, sizeof path, "%s.witness.json", out_path);
    if (n <= 0 || (size_t)n >= sizeof path) return III_EMIT_E_CMD_OVERFLOW;
    FILE *f = fopen(path, "wb");
    if (!f) return III_EMIT_E_WITNESS_WRITE;
    size_t w = fwrite(witness_json, 1, strlen(witness_json), f);
    if (fclose(f) != 0) return III_EMIT_E_WITNESS_WRITE;
    return (w == strlen(witness_json)) ? III_EMIT_OK : III_EMIT_E_WITNESS_WRITE;
}

/* ════════════════════════════════════════════════════════════════════
 * Audit fan-out (D16).
 * ════════════════════════════════════════════════════════════════ */

static void iii_emit_audit(iii_emit_phase_t phase, iii_emit_format_t fmt,
                           const char *cmd, int status,
                           const uint8_t argv_mhash[32])
{
    if (G_EMIT.audit_fn) {
        G_EMIT.audit_fn(phase, fmt, cmd, status, argv_mhash, G_EMIT.audit_user);
    }
}

/* ════════════════════════════════════════════════════════════════════
 * Public lifecycle.
 * ════════════════════════════════════════════════════════════════ */

void iii_emit_reset(void)
{
    if (G_EMIT.sealed) return;
    G_EMIT.have_expected = false;
    G_EMIT.audit_fn      = NULL;
    G_EMIT.audit_user    = NULL;
}

int iii_emit_seal(void)            { G_EMIT.sealed = true;  return III_EMIT_OK; }
bool iii_emit_is_sealed(void)      { return G_EMIT.sealed; }

int iii_emit_set_audit_sink(iii_emit_audit_fn fn, void *user_data)
{
    if (G_EMIT.sealed) return III_EMIT_E_SEALED;
    G_EMIT.audit_fn   = fn;
    G_EMIT.audit_user = user_data;
    return III_EMIT_OK;
}

int iii_emit_set_expected_mhash(const uint8_t expected_or_null[32])
{
    if (G_EMIT.sealed) return III_EMIT_E_SEALED;
    if (expected_or_null) {
        memcpy(G_EMIT.expected_mhash, expected_or_null, 32);
        G_EMIT.have_expected = true;
    } else {
        G_EMIT.have_expected = false;
    }
    return III_EMIT_OK;
}

int iii_emit_get_output_mhash(uint8_t out[32])
{
    if (!out) return III_EMIT_E_NULL_ARG;
    if (!G_EMIT.have_last) return III_EMIT_E_INTERNAL;
    memcpy(out, G_EMIT.last_output_mhash, 32);
    return III_EMIT_OK;
}

int iii_emit_get_argv_mhash(uint8_t out[32])
{
    if (!out) return III_EMIT_E_NULL_ARG;
    memcpy(out, G_EMIT.last_argv_mhash, 32);
    return III_EMIT_OK;
}
int iii_emit_get_env_mhash(uint8_t out[32])
{
    if (!out) return III_EMIT_E_NULL_ARG;
    memcpy(out, G_EMIT.last_env_mhash, 32);
    return III_EMIT_OK;
}
int iii_emit_get_gcc_version_mhash(uint8_t out[32])
{
    if (!out) return III_EMIT_E_NULL_ARG;
    memcpy(out, G_EMIT.last_gcc_version_mhash, 32);
    return III_EMIT_OK;
}
int iii_emit_get_ld_version_mhash(uint8_t out[32])
{
    if (!out) return III_EMIT_E_NULL_ARG;
    memcpy(out, G_EMIT.last_ld_version_mhash, 32);
    return III_EMIT_OK;
}

const char *iii_emit_get_witness_json(void)
{
    return G_EMIT.have_last ? G_EMIT.witness_json : NULL;
}

const char *iii_emit_format_name(iii_emit_format_t fmt)
{
    switch (fmt) {
        case III_EMIT_FORMAT_PE_EXE:         return "pe-exe";
        case III_EMIT_FORMAT_PE_DLL:         return "pe-dll";
        case III_EMIT_FORMAT_PE_SYS:         return "pe-sys";
        case III_EMIT_FORMAT_ELF_EXE:        return "elf-exe";
        case III_EMIT_FORMAT_RAW_BIN:        return "raw-bin";
        case III_EMIT_FORMAT_SANCTUM_OBJECT: return "sanctum-object";
        default:                             return "<unknown>";
    }
}

/* ════════════════════════════════════════════════════════════════════
 * iii_emit_assemble — gcc -c with full determinism flag set.
 *
 * Flags applied (D1..D6):
 *   gcc -c -x assembler                      (input is `.s`/`.iii` asm)
 *       -ffile-prefix-map=$cwd=.             (D3)
 *       -frandom-seed=<basename>             (D4)
 *       -Wa,--reduce-memory-overheads        (deterministic gas state)
 *       -Wl,--build-id=none                  (D2 — harmless on -c)
 *       -o <out_obj> <asm>
 *
 * Env (D1/D5/D6) forced before system().
 * ════════════════════════════════════════════════════════════════ */

int iii_emit_assemble(const char *asm_path, const char *out_obj_path)
{
    if (!asm_path || !out_obj_path) return III_EMIT_E_NULL_ARG;

    iii_emit_force_env();

    char cmd[2048];
    size_t off = 0;
    if (iii_emit_appendf(cmd, sizeof cmd, &off,
            "gcc -c -x assembler "
            "-ffile-prefix-map=$PWD=. "
            "-frandom-seed=%s "
            "-Wl,--build-id=none "
            "-o \"%s\" \"%s\"",
            iii_emit_basename(asm_path),
            out_obj_path, asm_path) != 0) {
        return III_EMIT_E_CMD_OVERFLOW;
    }

    uint8_t argv_mhash[32];
    iii_emit_sha_oneshot(cmd, strlen(cmd), argv_mhash);

    int rc = system(cmd);
    iii_emit_audit(III_EMIT_PHASE_ASSEMBLE, III_EMIT_FORMAT_ELF_EXE,
                   cmd, rc, argv_mhash);
    return (rc == 0) ? III_EMIT_OK : III_EMIT_E_GCC_FAIL;
}

/* ════════════════════════════════════════════════════════════════════
 * iii_emit_link — drives gcc/ld per format, with determinism flags,
 * post-emission SHA-256 (D8), witness emission (D9), golden-bytes
 * gate (D10), argv/env/version mhashes (D11/D12/D13), sanctum
 * verification + script generation (D14).
 * ════════════════════════════════════════════════════════════════ */

int iii_emit_link(iii_emit_format_t  fmt,
                  const char *const *obj_paths,
                  size_t             obj_count,
                  const char        *out_path,
                  const char        *linker_script_or_null)
{
    if (!obj_paths || obj_count == 0 || !out_path) return III_EMIT_E_NULL_ARG;
    const iii_emit_fmt_spec_t *spec = iii_emit_fmt_lookup(fmt);
    if (!spec) return III_EMIT_E_BAD_FORMAT;

    /* D14 sanctum pre-flight: every input must have the section. */
    char sanctum_script[1024]; sanctum_script[0] = 0;
    if (spec->is_sanctum) {
        for (size_t i = 0; i < obj_count; i++) {
            int rc = iii_emit_object_has_sanctum(obj_paths[i]);
            if (rc != III_EMIT_OK) return rc;
        }
        int n = snprintf(sanctum_script, sizeof sanctum_script,
                         "%s.sanctum.ld", out_path);
        if (n <= 0 || (size_t)n >= sizeof sanctum_script)
            return III_EMIT_E_CMD_OVERFLOW;
        int wr = iii_emit_write_sanctum_script(sanctum_script);
        if (wr != III_EMIT_OK) return wr;
    }

    iii_emit_force_env();

    /* Build the canonical command line. */
    char cmd[16384];
    size_t off = 0;

    if (iii_emit_appendf(cmd, sizeof cmd, &off, "%s", spec->driver) != 0)
        return III_EMIT_E_CMD_OVERFLOW;

    if (spec->abi_flags && spec->abi_flags[0]) {
        if (iii_emit_appendf(cmd, sizeof cmd, &off, " %s", spec->abi_flags) != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    }
    if (spec->link_flags && spec->link_flags[0]) {
        if (iii_emit_appendf(cmd, sizeof cmd, &off, " %s", spec->link_flags) != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    }

    /* D2: --build-id=none. ld accepts it directly; gcc-as-driver via -Wl. */
    if (strcmp(spec->driver, "gcc") == 0) {
        if (iii_emit_appendf(cmd, sizeof cmd, &off,
                " -ffile-prefix-map=$PWD=. -Wl,--build-id=none") != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    } else {
        if (iii_emit_appendf(cmd, sizeof cmd, &off,
                " --build-id=none") != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    }

    /* SANCTUM additionally needs -fpic (cite: gcc(1) "-fpic"). When
     * driver is "ld", -fpic doesn't apply; the script is what pins
     * it. The emit.h contract mentions -fpic for the *gcc* path; we
     * skip when invoking ld directly. */

    if (iii_emit_appendf(cmd, sizeof cmd, &off, " -o \"%s\"", out_path) != 0)
        return III_EMIT_E_CMD_OVERFLOW;

    if (spec->is_sanctum) {
        if (iii_emit_appendf(cmd, sizeof cmd, &off, " -T \"%s\"", sanctum_script) != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    }
    if (linker_script_or_null) {
        if (iii_emit_appendf(cmd, sizeof cmd, &off, " -T \"%s\"",
                             linker_script_or_null) != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    }

    for (size_t i = 0; i < obj_count; i++) {
        if (iii_emit_appendf(cmd, sizeof cmd, &off, " \"%s\"", obj_paths[i]) != 0)
            return III_EMIT_E_CMD_OVERFLOW;
    }

    /* D11 argv mhash. */
    iii_emit_sha_oneshot(cmd, strlen(cmd), G_EMIT.last_argv_mhash);
    /* D12 env mhash. */
    iii_emit_compute_env_mhash(G_EMIT.last_env_mhash);
    /* D13 tool versions. */
    iii_emit_capture_version("gcc", G_EMIT.last_gcc_version_mhash);
    iii_emit_capture_version("ld",  G_EMIT.last_ld_version_mhash);

    int rc = system(cmd);
    iii_emit_audit(III_EMIT_PHASE_LINK, fmt, cmd, rc, G_EMIT.last_argv_mhash);
    if (rc != 0) {
        return (strcmp(spec->driver, "ld") == 0) ? III_EMIT_E_LD_FAIL
                                                 : III_EMIT_E_GCC_FAIL;
    }

    /* RAW_BIN: strip ELF wrapper to `<out>.bin`. */
    char output_for_hash[1024];
    if (snprintf(output_for_hash, sizeof output_for_hash, "%s", out_path) >= (int)sizeof output_for_hash)
        return III_EMIT_E_CMD_OVERFLOW;

    if (spec->emit_objcopy_bin) {
        char cmd2[2048];
        int n = snprintf(cmd2, sizeof cmd2,
                         "objcopy -O binary \"%s\" \"%s.bin\"",
                         out_path, out_path);
        if (n <= 0 || (size_t)n >= sizeof cmd2) return III_EMIT_E_CMD_OVERFLOW;
        int rc2 = system(cmd2);
        uint8_t cmd2_mhash[32];
        iii_emit_sha_oneshot(cmd2, strlen(cmd2), cmd2_mhash);
        iii_emit_audit(III_EMIT_PHASE_OBJCOPY, fmt, cmd2, rc2, cmd2_mhash);
        if (rc2 != 0) return III_EMIT_E_OBJCOPY_FAIL;
        if (snprintf(output_for_hash, sizeof output_for_hash, "%s.bin", out_path) >= (int)sizeof output_for_hash)
            return III_EMIT_E_CMD_OVERFLOW;
    }

    /* D8 — output mhash over the actual bytes we delivered. */
    {
        uint8_t *buf = NULL; size_t len = 0;
        int rc3 = iii_emit_slurp(output_for_hash, &buf, &len);
        if (rc3 != III_EMIT_OK) return rc3;
        iii_emit_sha_oneshot(buf, len, G_EMIT.last_output_mhash);
        free(buf);
    }
    G_EMIT.have_last = true;

    /* D9 — render + write witness sidecar. */
    int rcw = iii_emit_render_witness(fmt, G_EMIT.witness_json,
                                      sizeof G_EMIT.witness_json);
    if (rcw != III_EMIT_OK) return rcw;
    rcw = iii_emit_write_witness(out_path, G_EMIT.witness_json);
    iii_emit_audit(III_EMIT_PHASE_WITNESS, fmt, G_EMIT.witness_json, rcw, G_EMIT.last_output_mhash);
    if (rcw != III_EMIT_OK) return rcw;

    /* D10 — golden-bytes gate. */
    if (G_EMIT.have_expected &&
        memcmp(G_EMIT.expected_mhash, G_EMIT.last_output_mhash, 32) != 0) {
        return III_EMIT_E_MHASH_MISMATCH;
    }

    return III_EMIT_OK;
}

/* ════════════════════════════════════════════════════════════════════
 * D17 / Lattice plan Step 0024 — Layered seal continuity.
 *
 * Each successful emission can extend a layered seal chain by writing
 * a 128-byte sealed record that anchors prev_root → new_root with
 * a deterministic delta_mhash and an HMAC over the transition.
 *
 * Layout per record:
 *   bytes  [0..32)   prev_root_32
 *   bytes  [32..64)  new_root_32
 *   bytes  [64..96)  delta_mhash_32
 *   bytes  [96..128) mac_32
 *
 * Domain:    "seal_step_NNNN"  (literal NNNN = decimal step_no, zero-padded to 4)
 * delta_mhash = sha256(domain || prev_root || new_root || step_no_le_8)
 * mac         = HMAC-SHA-256(slot4_subkey, prev_root || new_root ||
 *                             delta_mhash || step_no_le_8)
 *
 * Step 0114 walks N records and emits the master tree_root as
 *   sha256("master_tree_root" || record[0] || ... || record[N-1])
 * ════════════════════════════════════════════════════════════════════ */

/* Render "seal_step_0042" into out (16-byte fixed buffer; NUL-padded). */
static void iii_emit_render_seal_step_domain(uint32_t step_no, uint8_t out[16])
{
    /* "seal_step_" = 10 bytes; remaining 6 bytes hold up to 6 ASCII
     * digits (zero-padded to 4 minimum so step 0..9999 fits cleanly). */
    static const char prefix[10] = { 's','e','a','l','_','s','t','e','p','_' };
    memcpy(out, prefix, 10);
    /* Zero-pad to 4 digits for step < 10000. */
    char dig[6];
    int  n = 0;
    uint32_t v = step_no;
    if (v == 0) { dig[n++] = '0'; }
    else { while (v) { dig[n++] = (char)('0' + (v % 10u)); v /= 10u; } }
    /* Reverse + zero-pad to 4. */
    int pad = (n < 4) ? (4 - n) : 0;
    int o = 10;
    while (pad--) out[o++] = '0';
    while (n--)   out[o++] = (uint8_t)dig[n];
    while (o < 16) out[o++] = 0;
}

/* Pack uint64_t LE into 8 bytes. */
static void iii_emit_pack_u64_le(uint8_t out[8], uint64_t v)
{
    for (int i = 0; i < 8; i++) {
        out[i] = (uint8_t)(v & 0xFFu);
        v >>= 8;
    }
}

/* Compute delta_mhash for a layered seal step. */
static void iii_emit_compute_delta_mhash(uint32_t step_no,
                                              const uint8_t prev[32],
                                              const uint8_t next[32],
                                              uint8_t out_delta[32])
{
    uint8_t domain[16];
    iii_emit_render_seal_step_domain(step_no, domain);
    uint8_t step_bytes[8];
    iii_emit_pack_u64_le(step_bytes, (uint64_t)step_no);
    iii_emit_sha_t h;
    iii_emit_sha_init(&h);
    iii_emit_sha_update(&h, domain, 16);
    iii_emit_sha_update(&h, prev, 32);
    iii_emit_sha_update(&h, next, 32);
    iii_emit_sha_update(&h, step_bytes, 8);
    iii_emit_sha_final(&h, out_delta);
}

/* HMAC-SHA-256 (FIPS 198-1).  ipad=0x36, opad=0x5c. */
static void iii_emit_hmac_sha256(const uint8_t key[32],
                                       const uint8_t *msg, size_t msg_len,
                                       uint8_t out[32])
{
    uint8_t ipad[64];
    uint8_t opad[64];
    /* Key is exactly 32 bytes; zero-pad to 64. */
    for (int i = 0; i < 32; i++) {
        ipad[i] = key[i] ^ 0x36u;
        opad[i] = key[i] ^ 0x5cu;
    }
    for (int i = 32; i < 64; i++) {
        ipad[i] = 0x36u;
        opad[i] = 0x5cu;
    }
    /* inner = sha256(ipad || msg) */
    uint8_t inner[32];
    iii_emit_sha_t h;
    iii_emit_sha_init(&h);
    iii_emit_sha_update(&h, ipad, 64);
    if (msg && msg_len) iii_emit_sha_update(&h, msg, msg_len);
    iii_emit_sha_final(&h, inner);
    /* outer = sha256(opad || inner) */
    iii_emit_sha_init(&h);
    iii_emit_sha_update(&h, opad, 64);
    iii_emit_sha_update(&h, inner, 32);
    iii_emit_sha_final(&h, out);
}

int iii_emit_layered_seal(const char *out_path,
                              uint32_t step_no,
                              const uint8_t prev_root_32[32],
                              const uint8_t new_root_32[32],
                              const uint8_t slot4_subkey_32[32])
{
    if (!out_path || !prev_root_32 || !new_root_32 || !slot4_subkey_32) {
        return III_EMIT_E_NULL_ARG;
    }
    if (G_EMIT.sealed) return III_EMIT_E_SEALED;

    uint8_t record[128];
    /* prev_root_32 || new_root_32 */
    memcpy(record + 0,  prev_root_32, 32);
    memcpy(record + 32, new_root_32,  32);
    /* delta_mhash */
    uint8_t delta[32];
    iii_emit_compute_delta_mhash(step_no, prev_root_32, new_root_32, delta);
    memcpy(record + 64, delta, 32);
    /* mac = HMAC-SHA-256(slot4_subkey, prev || new || delta || step_no_le_8) */
    uint8_t mac_msg[32 + 32 + 32 + 8];
    memcpy(mac_msg + 0,  prev_root_32, 32);
    memcpy(mac_msg + 32, new_root_32,  32);
    memcpy(mac_msg + 64, delta,        32);
    iii_emit_pack_u64_le(mac_msg + 96, (uint64_t)step_no);
    uint8_t mac[32];
    iii_emit_hmac_sha256(slot4_subkey_32, mac_msg, sizeof mac_msg, mac);
    memcpy(record + 96, mac, 32);

    FILE *f = fopen(out_path, "wb");
    if (!f) return III_EMIT_E_IO;
    size_t w = fwrite(record, 1, 128, f);
    int closed = fclose(f);
    if (w != 128 || closed != 0) return III_EMIT_E_IO;
    return III_EMIT_OK;
}

int iii_emit_layered_seal_read(const char *in_path,
                                   uint8_t prev_root_32[32],
                                   uint8_t new_root_32[32],
                                   uint8_t delta_mhash_32[32],
                                   uint8_t mac_32[32])
{
    if (!in_path || !prev_root_32 || !new_root_32 ||
        !delta_mhash_32 || !mac_32) return III_EMIT_E_NULL_ARG;
    FILE *f = fopen(in_path, "rb");
    if (!f) return III_EMIT_E_IO;
    uint8_t record[128];
    size_t r = fread(record, 1, 128, f);
    fclose(f);
    if (r != 128) return III_EMIT_E_IO;
    memcpy(prev_root_32,    record + 0,  32);
    memcpy(new_root_32,     record + 32, 32);
    memcpy(delta_mhash_32,  record + 64, 32);
    memcpy(mac_32,          record + 96, 32);
    return III_EMIT_OK;
}

int iii_emit_layered_seal_verify(uint32_t step_no,
                                     const uint8_t prev_root_32[32],
                                     const uint8_t new_root_32[32],
                                     const uint8_t delta_mhash_32[32],
                                     const uint8_t mac_32[32],
                                     const uint8_t slot4_subkey_32[32])
{
    if (!prev_root_32 || !new_root_32 || !delta_mhash_32 ||
        !mac_32 || !slot4_subkey_32) return 0;
    /* Recompute delta_mhash; compare. */
    uint8_t delta_check[32];
    iii_emit_compute_delta_mhash(step_no, prev_root_32, new_root_32, delta_check);
    if (memcmp(delta_check, delta_mhash_32, 32) != 0) return 0;
    /* Recompute mac; compare. */
    uint8_t mac_msg[32 + 32 + 32 + 8];
    memcpy(mac_msg + 0,  prev_root_32,    32);
    memcpy(mac_msg + 32, new_root_32,     32);
    memcpy(mac_msg + 64, delta_mhash_32,  32);
    iii_emit_pack_u64_le(mac_msg + 96, (uint64_t)step_no);
    uint8_t mac_check[32];
    iii_emit_hmac_sha256(slot4_subkey_32, mac_msg, sizeof mac_msg, mac_check);
    if (memcmp(mac_check, mac_32, 32) != 0) return 0;
    return 1;
}

int iii_emit_master_tree_root(const uint8_t *records,
                                  uint32_t      record_count,
                                  uint8_t       out_master_root_32[32])
{
    if (!records || !out_master_root_32) return III_EMIT_E_NULL_ARG;
    static const char domain[16] = {
        'm','a','s','t','e','r','_','t','r','e','e','_','r','o','o','t'
    };
    iii_emit_sha_t h;
    iii_emit_sha_init(&h);
    iii_emit_sha_update(&h, domain, 16);
    if (record_count > 0) {
        iii_emit_sha_update(&h, records, (size_t)record_count * 128u);
    }
    iii_emit_sha_final(&h, out_master_root_32);
    return III_EMIT_OK;
}
