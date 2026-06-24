#include <stdint.h>
#include <string.h>
#include <stdbool.h>
static uint8_t buf[16];
int main() {
    memset(buf, 0xAB, 16);
    if (buf[0] != 0xAB) { return 1; }
    if (buf[15] != 0xAB) { return 2; }
    memset(buf, 0, 8);
    if (buf[0] != 0) { return 3; }
    if (buf[8] != 0xAB) { return 4; }       /* unchanged */
    bool a = true;  if (a != 1) { return 5; }
    bool b = false; if (b != 0) { return 6; }
    int *p = NULL;  if (p != 0) { return 7; }
    return 99;
}
