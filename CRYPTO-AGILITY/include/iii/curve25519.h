/* Hand-rolled X25519 per RFC 7748. */
#ifndef III_CURVE25519_H
#define III_CURVE25519_H
#include <stdint.h>

void iii_x25519_scalarmult(uint8_t out[32], const uint8_t scalar[32], const uint8_t point[32]);
void iii_x25519_base(uint8_t out[32], const uint8_t scalar[32]);

#endif
