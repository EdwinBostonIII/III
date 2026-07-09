/* probe12.c -- LOCAL-ARRAY NAME-SCOPE falsifier (the emit.c cmd[256/2048] killer):
 *   ccsv registered local arrays TU-wide BY NAME: every same-named local resolved
 *   (base AND sizeof) to the FIRST registration.  emit.c declares cmd[256] (audit),
 *   cmd[1024], cmd[2048] (iii_emit_assemble), cmd[16384] (link) -- assemble's
 *   `sizeof cmd` read 256, so iii_emit_appendf's overflow check tripped the moment
 *   the gcc command crossed 256 chars (out-path >= 77 chars) -> E_CMD_OVERFLOW ->
 *   "assemble failed" -> EMIT_FAIL 16 with a complete .s on disk and no system() call.
 *   Mirrors: same-named char arrays in two fns (64 first, then 512), sizeof through
 *   both (paren and paren-less), the appendf shape crossing 256 formatted chars,
 *   cross-fn storage isolation for a second name, and local-shadows-global.
 *   66 = first-declared fn's own sizeof wrong (over-correction guard)
 *   61 = second fn: sizeof collapsed to the first registration / appendf tripped
 *   64 = callee's same-named local aliased the caller's storage
 *   65 = a local write leaked into the same-named file-scope global
 *   99 = all green (gcc oracle) */
#include <stdarg.h>
#include <stdio.h>

static int gsh[4] = {7, 7, 7, 7};
static char LONGBUF[400];

static int apf(char *buf, size_t cap, size_t *off, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf + *off, cap - *off, fmt, ap);
    va_end(ap);
    if (n < 0) return -1;
    if ((size_t)n >= cap - *off) return -1;
    *off += (size_t)n;
    return 0;
}

static int f_small(void)
{
    char cmd[64];
    cmd[0] = 'x';
    if (sizeof(cmd) != 64) return 1;
    if (sizeof cmd != 64) return 1;
    if (cmd[0] != 'x') return 1;
    return 0;
}

static int f_big(void)
{
    char cmd[512];
    size_t off = 0;
    if (sizeof(cmd) != 512) return 1;
    if (sizeof cmd != 512) return 1;
    if (apf(cmd, sizeof cmd, &off, "gcc -o \"%s\" \"%s\"", LONGBUF, LONGBUF) != 0) return 2;
    if (off < 300) return 3;
    if (cmd[0] != 'g') return 4;
    return 0;
}

static int f_iso2(void)
{
    char iso[16];
    int i = 0;
    while (i < 16) { iso[i] = 'B'; i = i + 1; }
    if (iso[7] != 'B') return 1;
    return 0;
}

static int f_iso1(void)
{
    char iso[16];
    int i = 0;
    while (i < 16) { iso[i] = 'A'; i = i + 1; }
    if (f_iso2() != 0) return 1;
    if (iso[7] != 'A') return 2;
    return 0;
}

static int f_shadow(void)
{
    char gsh[8];
    gsh[0] = 65;
    if (gsh[0] != 65) return 1;
    return 0;
}

int main(void)
{
    int i = 0;
    while (i < 180) { LONGBUF[i] = 'p'; i = i + 1; }
    LONGBUF[180] = 0;
    if (f_small() != 0) return 66;
    if (f_big() != 0) return 61;
    if (f_iso1() != 0) return 64;
    if (f_shadow() != 0) return 65;
    if (gsh[0] != 7) return 65;
    if (gsh[3] != 7) return 65;
    return 99;
}
