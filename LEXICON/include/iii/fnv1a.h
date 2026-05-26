/* Hand-rolled FNV-1a 32-bit. */
#ifndef III_FNV1A_H
#define III_FNV1A_H
#include <stdint.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
uint32_t iii_fnv1a32(const uint8_t *data, size_t len);
#ifdef __cplusplus
}
#endif
#endif
