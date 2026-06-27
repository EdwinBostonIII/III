/* test_globalinc.c -- behavioral gate for global-scalar mutation statements that were SILENTLY DROPPED
 * (the NAME++ / x op= e statement handlers emitted only for locals; a global fell through to a no-op):
 *   g++ / g-- (post-inc/dec) AND g += / -= / *= (compound-assign).  Plus the seed-shaped global-index loop. */
static int g;
static unsigned char gb;
static int gidx;
static int out[8];
int main(void) {
    g = 5;
    g++; g++; g--;                 /* 6  -- global post-inc/dec */
    g += 4; g -= 1; g *= 2;        /* 6 -> 10 -> 9 -> 18  -- global compound-assign */
    gb = 10; gb++;                 /* 11 */
    gb += 5;                       /* 16 */
    gidx = 0;
    int i;
    for (i = 0; i < 4; i++) { out[gidx] = i + 100; gidx++; }   /* global index advances */
    if (g != 18) return 1;
    if (gb != 16) return 2;
    if (out[0] != 100) return 3;
    if (out[3] != 103) return 4;
    if (gidx != 4) return 5;
    return 99;
}
