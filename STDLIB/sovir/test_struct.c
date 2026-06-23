#include <stdio.h>
struct Point { int x; int y; int z; };
struct Point g;
int main() {
    g.x = 100000;
    g.y = 200000;
    g.z = g.x + g.y;            /* 300000 */
    if (g.x != 100000) { return 1; }
    if (g.z != 300000) { return 2; }
    g.x = g.x * 2;             /* 200000 */
    if (g.x != 200000) { return 3; }
    return 99;
}
