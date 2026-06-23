#include <stdint.h>
int main() {
    int a = 1, b = 2, c = 3;
    if (a + b + c != 6) { return 1; }
    uint32_t x = 0x10, y = 0x20, z = 0x30;
    if ((x | y | z) != 0x30) { return 2; }
    int p = 5, q;                            /* mixed init + uninit */
    q = p * 2;  if (q != 10) { return 3; }
    int arr[3], n = 3;                       /* array + scalar in one decl */
    for (int i = 0; i < n; i++) { arr[i] = i * 10; }
    if (arr[2] != 20) { return 4; }
    uint32_t e0 = 1, e1 = 2, e2 = 3, e3 = 4, e4 = 5, e5 = 6, e6 = 7, e7 = 8;   /* 8-way like cl_sha_block */
    if (e0 + e7 != 9) { return 5; }
    return 99;
}
