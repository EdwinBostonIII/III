/* lex_runtime.c — runtime helpers for lex.iii (CP-030+).
 *
 * Companion C-side stubs for things iiis-0 cannot express directly:
 *   - malloc / free wrappers
 *   - byte/word/qword read/write at addr+off (since iiis-0's ptr deref
 *     of malloc'd memory is restricted to the iii_emit_buf_read_u8_c
 *     primitive in emit_accessors.c)
 *   - LE u32 / u64 read+write helpers (avoids 8-line OR-shift chains
 *     in the .iii — the dialect rejects multi-line binary expressions).
 *
 * No allocations beyond what callers explicitly request via
 * iii_lex_malloc_c.  No globals.  All helpers are pure functions of
 * their arguments (with side-effects only on the buffer the caller
 * passed).  Stage-2 byte-equivalence depends on this.
 */

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>

/* ??? SHA-256 (FIPS 180-4) hand-rolled, NIH ?????????????????????????
 * Multi-instance: caller allocates the 112-byte state struct (laid
 * out so its fields remain accessible from the .iii via the offsets
 * exposed in lex.iii: III_SHA256_OFF_H/_TOTAL_BITS/_BUF/_BUF_USED).
 *
 * Hoisted out of lex.iii because iiis-0's codegen has bugs in the
 * per-round arithmetic when many u32 let-mut locals are combined
 * with chained shifts and intra-module function calls; same trap
 * was hit in cg_rm1 (CP-028) and resolved the same way.
 */

#define III_SHA256_OFF_H          0
#define III_SHA256_OFF_TOTAL_BITS 32
#define III_SHA256_OFF_BUF        40
#define III_SHA256_OFF_BUF_USED   104
#define III_SHA256_STATE_BYTES    112

static const uint32_t III_SHA256_K_C[64] = {
0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static inline uint32_t rotr32_c(uint32_t x, uint32_t n){ return (x>>n)|(x<<(32u-n)); }

static void sha256_compress_c(uint8_t *state, const uint8_t *block) {
    uint32_t W[64];
    for (int i=0;i<16;i++){
        W[i] = ((uint32_t)block[i*4+0]<<24)
             | ((uint32_t)block[i*4+1]<<16)
             | ((uint32_t)block[i*4+2]<< 8)
             |  (uint32_t)block[i*4+3];
    }
    for (int i=16;i<64;i++){
        uint32_t s0 = rotr32_c(W[i-15],7) ^ rotr32_c(W[i-15],18) ^ (W[i-15]>>3);
        uint32_t s1 = rotr32_c(W[i-2],17) ^ rotr32_c(W[i-2],19) ^ (W[i-2]>>10);
        W[i] = W[i-16] + s0 + W[i-7] + s1;
    }
    uint32_t h[8];
    memcpy(h, state + III_SHA256_OFF_H, 32);
    uint32_t a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
    for (int k=0;k<64;k++){
        uint32_t S1 = rotr32_c(e,6)^rotr32_c(e,11)^rotr32_c(e,25);
        uint32_t ch = (e&f)^((~e)&g);
        uint32_t t1 = hh + S1 + ch + III_SHA256_K_C[k] + W[k];
        uint32_t S0 = rotr32_c(a,2)^rotr32_c(a,13)^rotr32_c(a,22);
        uint32_t mj = (a&b)^(a&c)^(b&c);
        uint32_t t2 = S0 + mj;
        hh=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    h[0]+=a; h[1]+=b; h[2]+=c; h[3]+=d; h[4]+=e; h[5]+=f; h[6]+=g; h[7]+=hh;
    memcpy(state + III_SHA256_OFF_H, h, 32);
}

uint32_t iii_sha256_init(uint64_t s_addr) {
    uint8_t *s = (uint8_t*)(uintptr_t)s_addr;
    static const uint32_t H0[8] = {
        0x6a09e667u,0xbb67ae85u,0x3c6ef372u,0xa54ff53au,
        0x510e527fu,0x9b05688cu,0x1f83d9abu,0x5be0cd19u };
    memcpy(s + III_SHA256_OFF_H, H0, 32);
    *(uint64_t*)(s + III_SHA256_OFF_TOTAL_BITS) = 0;
    *(uint64_t*)(s + III_SHA256_OFF_BUF_USED)   = 0;
    return 0u;
}

uint32_t iii_sha256_update(uint64_t s_addr, uint64_t data_addr, uint64_t n) {
    uint8_t *s    = (uint8_t*)(uintptr_t)s_addr;
    const uint8_t *p = (const uint8_t*)(uintptr_t)data_addr;
    uint64_t *bits = (uint64_t*)(s + III_SHA256_OFF_TOTAL_BITS);
    uint64_t *used = (uint64_t*)(s + III_SHA256_OFF_BUF_USED);
    uint8_t  *buf  = s + III_SHA256_OFF_BUF;
    *bits += n * 8u;
    if (*used) {
        size_t fill = 64u - (size_t)*used;
        if (n < fill) { memcpy(buf + *used, p, (size_t)n); *used += n; return 0u; }
        memcpy(buf + *used, p, fill);
        sha256_compress_c(s, buf);
        p += fill; n -= fill; *used = 0;
    }
    while (n >= 64) { sha256_compress_c(s, p); p += 64; n -= 64; }
    if (n) { memcpy(buf, p, (size_t)n); *used = n; }
    return 0u;
}

uint32_t iii_sha256_update_u8(uint64_t s, uint32_t v) {
    uint8_t b = (uint8_t)v; return iii_sha256_update(s, (uint64_t)(uintptr_t)&b, 1);
}
uint32_t iii_sha256_update_u16(uint64_t s, uint32_t v) {
    uint8_t b[2] = { (uint8_t)v, (uint8_t)(v>>8) };
    return iii_sha256_update(s, (uint64_t)(uintptr_t)b, 2);
}
uint32_t iii_sha256_update_u32(uint64_t s, uint32_t v) {
    uint8_t b[4] = { (uint8_t)v, (uint8_t)(v>>8), (uint8_t)(v>>16), (uint8_t)(v>>24) };
    return iii_sha256_update(s, (uint64_t)(uintptr_t)b, 4);
}
uint32_t iii_sha256_update_u64(uint64_t s_addr, uint64_t v) {
    uint8_t b[8];
    for (int i=0;i<8;i++) b[i] = (uint8_t)(v >> (i*8));
    return iii_sha256_update(s_addr, (uint64_t)(uintptr_t)b, 8);
}

uint32_t iii_sha256_final(uint64_t s_addr, uint64_t out32_addr) {
    uint8_t *s    = (uint8_t*)(uintptr_t)s_addr;
    uint8_t *out  = (uint8_t*)(uintptr_t)out32_addr;
    uint64_t bits = *(uint64_t*)(s + III_SHA256_OFF_TOTAL_BITS);
    uint64_t used = *(uint64_t*)(s + III_SHA256_OFF_BUF_USED);
    uint8_t  *buf = s + III_SHA256_OFF_BUF;
    buf[used++] = 0x80;
    if (used > 56) {
        while (used < 64) buf[used++] = 0;
        sha256_compress_c(s, buf);
        used = 0;
    }
    while (used < 56) buf[used++] = 0;
    for (int i=7;i>=0;i--) buf[used++] = (uint8_t)(bits >> (i*8));
    sha256_compress_c(s, buf);
    /* h[0..7] BE into out */
    for (int i=0;i<8;i++){
        uint32_t v = *(uint32_t*)(s + III_SHA256_OFF_H + i*4);
        out[i*4+0] = (uint8_t)(v>>24);
        out[i*4+1] = (uint8_t)(v>>16);
        out[i*4+2] = (uint8_t)(v>> 8);
        out[i*4+3] = (uint8_t) v;
    }
    return 0u;
}

/* --- FILE* stream helpers (for ast.iii serialize/deserialize/debug_dump) ---
 * Thin wrappers over libc stdio; the .iii layer owns the byte-format logic and
 * delegates only the raw stream primitive (NIH-clean, libc-only per Contract
 * C2).  FILE* is carried as an opaque uint64_t handle. */
uint64_t iii_lex_fwrite_c(uint64_t ptr, uint64_t n, uint64_t file) {
    return (uint64_t)fwrite((const void*)(uintptr_t)ptr, 1, (size_t)n, (FILE*)(uintptr_t)file);
}
uint64_t iii_lex_fread_c(uint64_t ptr, uint64_t n, uint64_t file) {
    return (uint64_t)fread((void*)(uintptr_t)ptr, 1, (size_t)n, (FILE*)(uintptr_t)file);
}
uint64_t iii_lex_tmpfile_c(void) {
    return (uint64_t)(uintptr_t)tmpfile();
}
int64_t iii_lex_ftell_c(uint64_t file) {
    return (int64_t)ftell((FILE*)(uintptr_t)file);
}
uint32_t iii_lex_rewind_c(uint64_t file) {
    rewind((FILE*)(uintptr_t)file);
    return 0u;
}
uint32_t iii_lex_fclose_c(uint64_t file) {
    return (uint32_t)fclose((FILE*)(uintptr_t)file);
}
uint32_t iii_lex_fputs_c(uint64_t str, uint64_t file) {
    return (uint32_t)(fputs((const char*)(uintptr_t)str, (FILE*)(uintptr_t)file) >= 0 ? 0u : 1u);
}
uint32_t iii_lex_fputc_c(uint32_t ch, uint64_t file) {
    return (uint32_t)(fputc((int)(ch & 0xFFu), (FILE*)(uintptr_t)file) == (int)(ch & 0xFFu) ? 0u : 1u);
}

/* --- main.iii orchestrator runtime helpers (RITCHIE Stage 2.4) ---
 * fopen takes a MODE CODE (not a string) because .iii string literals are
 * not NUL-terminated; the C side maps the code to a real mode literal.
 *   mode: 0="rb"  1="wb"  2="w"
 * Returns the FILE* as an opaque uint64_t handle, or 0 on failure. */
uint64_t iii_lex_fopen_c(uint64_t path, uint32_t mode) {
    const char *m = (mode == 0u) ? "rb" : (mode == 1u) ? "wb" : "w";
    return (uint64_t)(uintptr_t)fopen((const char*)(uintptr_t)path, m);
}
/* whence: 0=SEEK_SET  2=SEEK_END.  Returns 0 on success, 1 on failure. */
uint32_t iii_lex_fseek_c(uint64_t file, int64_t off, uint32_t whence) {
    int w = (whence == 2u) ? SEEK_END : SEEK_SET;
    return (uint32_t)(fseek((FILE*)(uintptr_t)file, (long)off, w) == 0 ? 0u : 1u);
}
uint64_t iii_lex_stderr_c(void) { return (uint64_t)(uintptr_t)stderr; }
uint64_t iii_lex_stdout_c(void) { return (uint64_t)(uintptr_t)stdout; }

/* SOURCE_DATE_EPOCH parse — byte-identical to main.c::iii_read_source_date_epoch:
 * digits only, else 0; absent/empty → 0. */
int64_t iii_lex_getenv_sde_c(void) {
    const char *s = getenv("SOURCE_DATE_EPOCH");
    if (!s || !*s) return 0;
    int64_t v = 0;
    for (const char *p = s; *p; p++) {
        if (*p < '0' || *p > '9') return 0;
        v = v * 10 + (*p - '0');
    }
    return v;
}
/* clock() in integer milliseconds (stderr verbose timing only; ADR-027:
 * timing is NEVER mhashed, so integer ms is sufficient). */
uint64_t iii_lex_clock_ms_c(void) {
    return (uint64_t)((double)clock() * 1000.0 / (double)CLOCKS_PER_SEC);
}
/* install a signal handler (handler is a fn-pointer-as-u64). */
uint32_t iii_lex_signal_c(uint32_t sig, uint64_t handler) {
    void (*h)(int) = (void (*)(int))(uintptr_t)handler;
    signal((int)sig, h);
    return 0u;
}
/* immediate process termination without atexit/stdio flush (mirrors _exit). */
uint32_t iii_lex_exit_c(uint32_t code) {
    _Exit((int)code);
    return 0u;
}
