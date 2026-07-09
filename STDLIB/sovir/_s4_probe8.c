/* probe8.c -- vsnprintf RETURN-COUNT falsifier (the cg_r3 emit_line/cg_writef killer):
 *   the ccsv builtin formatted into buf but returned CONSTANT 0 -> cg_write_bytes(buf, 0)
 *   wrote nothing -> every formatted .s line emitted as a bare newline (.text EMPTY).
 *   Mirrors emit_line's exact shape: 2 named params + varargs, va_start, vsnprintf(buf,
 *   sizeof buf, fmt, ap), then the RETURN VALUE gates the copy-out.
 *   60 = literal fmt: n wrong          61 = literal fmt: content wrong
 *   62 = %u fmt: n wrong               63 = %u fmt: content wrong
 *   64 = %% collapse wrong             65 = %llx (ll modifier) wrong
 *   66 = %s wrong                      99 = all green (gcc oracle) */
#include <stdarg.h>
#include <stdio.h>
static char OUT[64];
static int elp(char *dst, const char *fmt, ...)
{
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    if (n < 0) return -1;
    if ((size_t)n >= sizeof buf) n = (int)sizeof buf - 1;
    {
        int i = 0;
        while (i < n) { dst[i] = buf[i]; i = i + 1; }
        dst[n] = 0;
    }
    return n;
}
int main(void)
{
    int n = elp(OUT, "    pushq rbp");
    if (n != 13) return 60;
    if (OUT[4] != 'p') return 61;
    if (OUT[12] != 'p') return 61;
    n = elp(OUT, "    subq $%u, rsp", 1024u);
    if (n != 19) return 62;              /* "    subq $1024, rsp" */
    if (OUT[10] != '1') return 63;
    if (OUT[13] != '4') return 63;
    n = elp(OUT, "a%%b");
    if (n != 3) return 64;               /* "a%b" */
    if (OUT[1] != '%') return 64;
    n = elp(OUT, "$0x%llx", (unsigned long long)0x7);
    if (n != 4) return 65;               /* "$0x7" */
    if (OUT[3] != '7') return 65;
    n = elp(OUT, "[%s]", "main");
    if (n != 6) return 66;               /* "[main]" */
    if (OUT[1] != 'm') return 66;
    return 99;
}
