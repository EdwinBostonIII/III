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
