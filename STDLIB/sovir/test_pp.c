#include <stdint.h>
/* ccsv SEED-DDC : conditional compilation (#ifdef/#ifndef/#if 0/#else/#endif/#undef). Each active branch adds a
 * power of 2 (sum 31); any mis-stripped branch leaks +1000 (detectable). Seed: 40 #ifdef, 23 #ifndef, 1 `#if 0`. */
#define A 1
#define C 1
int main() {
    int r = 0;
#ifdef A
    r = r + 1;
#endif
#ifdef B
    r = r + 1000;
#endif
#ifndef B
    r = r + 2;
#endif
#if 0
    r = r + 1000;
#endif
#ifdef A
    r = r + 4;
#else
    r = r + 1000;
#endif
#ifdef B
    r = r + 1000;
#else
    r = r + 8;
#endif
#ifdef A
  #ifdef C
    r = r + 16;
  #endif
  #ifdef B
    r = r + 1000;
  #endif
#endif
#undef A
#ifdef A
    r = r + 1000;
#endif
    if (r != 31) { return 1; }
    return 99;
}
