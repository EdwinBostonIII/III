#include <stdio.h>
/* arbitrary-precision 100! in C (global digit array + putchar output), compiled by ccsv -> SVIR -> sovereign x86. */
int digits[512];
int main() {
    digits[0] = 1;
    int len = 1;
    int k = 2;
    while (k <= 100) {
        int carry = 0;
        int i = 0;
        while (i < len) {
            int prod = digits[i] * k + carry;
            digits[i] = prod % 10;
            carry = prod / 10;
            i = i + 1;
        }
        while (carry > 0) {
            digits[len] = carry % 10;
            carry = carry / 10;
            len = len + 1;
        }
        k = k + 1;
    }
    int j = len - 1;
    while (j >= 0) { putchar(48 + digits[j]); j = j - 1; }
    putchar(10);
    return 99;
}
