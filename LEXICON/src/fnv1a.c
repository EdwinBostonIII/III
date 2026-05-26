#include "iii/fnv1a.h"
uint32_t iii_fnv1a32(const uint8_t *data, size_t len) {
    uint32_t h = 0x811C9DC5U;
    for (size_t i = 0; i < len; i++) {
        h ^= data[i];
        h *= 0x01000193U;
    }
    return h;
}
