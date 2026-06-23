#include <stdio.h>
int sum_via_ptr(int *a, int n) {           /* pointer param + p[i] (8-byte cells) */
    int s = 0;
    int i = 0;
    while (i < n) { s = s + a[i]; i = i + 1; }
    return s;
}
int main() {
    int buf[8];                            /* LOCAL int array */
    int i = 0;
    while (i < 8) { buf[i] = i * 1000000; i = i + 1; }   /* values > 255 -> need 8-byte cells */
    int *p = &buf[3];                      /* pointer to an array element */
    *p = 999999999;                        /* deref store (~1e9, won't fit a byte) */
    int total = sum_via_ptr(&buf[0], 8);
    int nl = '\n';                         /* char literal */
    if (buf[3] != 999999999) { return 1; }
    if (buf[5] != 5000000) { return 2; }
    if (total != 1024999999) { return 3; }
    if (nl != 10) { return 4; }
    return 99;
}
