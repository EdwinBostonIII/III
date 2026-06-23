#include <stdio.h>
int main() {
    char *s = "III sovereign C, no gcc\n";
    int i = 0;
    while (s[i] != 0) { putchar(s[i]); i = i + 1; }
    return 99;
}
