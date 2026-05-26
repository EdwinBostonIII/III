/* ============================================================================
 * III-CYCLES — internal definitions
 * ============================================================================
 */
#ifndef III_CYCLES_INTERNAL_H
#define III_CYCLES_INTERNAL_H

#include "iii/cycles.h"
#include <stdint.h>
#include <stddef.h>

/* ----------------------------------------------------------------------------
 * Capacity bounds.
 * ---------------------------------------------------------------------------- */
#define III_CYCLES_TABLE_CAP            8192u
#define III_WITNESS_RING_CAP            65536u
#define III_BCWL_BLOOM_BITS             4096u
#define III_BCWL_BLOOM_HASHES           4u
#define III_BCWL_BUCKETS                16u
#define III_BCWL_MAX_WITNESSES          65536u
#define III_BCWL_RADIX_FANOUT           16u
#define III_WAVEFRONT_MAX_EFFECTS       64u

/* ----------------------------------------------------------------------------
 * SHA-256 / HMAC-SHA-256 / HKDF-SHA-256 / BLAKE3 primitives.
 * ---------------------------------------------------------------------------- */
void iii_sha256(const void *data, size_t len, uint8_t out[32]);
void iii_hmac_sha256(const uint8_t *key, size_t key_len,
                     const uint8_t *msg, size_t msg_len,
                     uint8_t        out[32]);
void iii_hkdf_sha256(const uint8_t *ikm,  size_t ikm_len,
                     const uint8_t *salt, size_t salt_len,
                     const uint8_t *info, size_t info_len,
                     uint8_t       *okm,  size_t okm_len);
void iii_blake3(const uint8_t *data, size_t len, uint8_t out[32]);

#endif /* III_CYCLES_INTERNAL_H */
