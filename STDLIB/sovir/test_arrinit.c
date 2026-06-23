#include <stdint.h>
static const uint32_t K[8] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5 };
static uint32_t rotr(uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); }   /* return is width-masked */
int main() {
    uint32_t s = 0;
    for (int i = 0; i < 8; i++) { s = s + K[i]; }   /* sum an initialised const table */
    if (s != 601620834) { return 1; }
    uint32_t r = rotr(305419896, 8);
    if (r != 2014458966) { return 2; }
    if (rotr(305419896, 8) != 2014458966) { return 3; }   /* rotr used DIRECTLY -> needs return masking */
    return 99;
}
