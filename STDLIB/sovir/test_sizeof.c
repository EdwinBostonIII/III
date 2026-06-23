#include <stdint.h>
struct Pt { int x; int y; int z; };
typedef struct Pt Point;
static int arr[10];
static uint8_t buf[20];
int main() {
    int n = sizeof(arr) / sizeof(arr[0]);     if (n != 10) { return 1; }   /* array length (size-agnostic) */
    int m = sizeof(buf) / sizeof(buf[0]);     if (m != 20) { return 2; }   /* byte-array length */
    int f = sizeof(struct Pt) / sizeof(int);  if (f != 3) { return 3; }    /* # int fields (size-agnostic) */
    int q = sizeof(Point) / sizeof(int);      if (q != 3) { return 4; }    /* typedef name */
    int sum = 0;
    for (int i = 0; i < n; i++) { arr[i] = i*i; sum = sum + arr[i]; }       /* sum i^2, i=0..9 = 285 */
    if (sum != 285) { return 5; }
    return 99;
}
