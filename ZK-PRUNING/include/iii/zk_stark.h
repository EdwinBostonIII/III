/* III ZK-PRUNING — NIH FRI-based STARK.
 *
 * STARK works in a separate NTT-friendly prime field, distinct from the
 * SNARK pairing field, so that we have a high-2-adicity modulus for the
 * Cooley–Tukey radix-2 transform.
 *
 *   q = 998244353 = 119 · 2^23 + 1   (2-adicity 23)
 *   primitive root g = 3
 *
 * sf_t = uint32_t scalar; multiplications use uint64_t.
 */
#ifndef III_ZK_STARK_H
#define III_ZK_STARK_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define IIIZK_STARK_Q  ((uint32_t)998244353u)
#define IIIZK_STARK_G  ((uint32_t)3u)

typedef uint32_t sf_t;

sf_t sf_add(sf_t x, sf_t y);
sf_t sf_sub(sf_t x, sf_t y);
sf_t sf_neg(sf_t x);
sf_t sf_mul(sf_t x, sf_t y);
sf_t sf_pow(sf_t x, uint64_t e);
sf_t sf_inv(sf_t x);
sf_t sf_root_of_unity(uint32_t n);

#define STARK_BLOWUP         4u
#define STARK_FRI_QUERIES    16u
#define STARK_MAX_DOMAIN     1024u
#define STARK_MAX_LOG        16u
#define STARK_MAX_FRI_LAYERS 12u

typedef struct {
    sf_t    *coeffs;
    uint32_t n;
} poly_t;

void  poly_init(poly_t *p, uint32_t n);
void  poly_free(poly_t *p);
sf_t  poly_eval(const poly_t *p, sf_t x);
void  ntt(sf_t *a, uint32_t n, sf_t omega);
void  intt(sf_t *a, uint32_t n, sf_t omega);

typedef struct {
    uint8_t (*nodes)[32];
    uint32_t n;
} merkle_t;

void     merkle_build (merkle_t *m, const sf_t *leaves, uint32_t n);
void     merkle_free  (merkle_t *m);
void     merkle_root  (const merkle_t *m, uint8_t out[32]);
uint32_t merkle_open  (const merkle_t *m, uint32_t idx, uint8_t (*proof)[32]);
int      merkle_verify(const uint8_t root[32], uint32_t n, uint32_t idx,
                       sf_t leaf, const uint8_t (*proof)[32], uint32_t proof_len);

typedef sf_t (*air_transition_fn)(sf_t prev, sf_t c);

typedef struct {
    uint32_t          trace_len;
    sf_t              c;
    sf_t              x0;
    sf_t              xN;
    air_transition_fn T;
} air_t;

sf_t air_square_plus_c(sf_t prev, sf_t c);

typedef struct {
    uint8_t  trace_root[32];
    uint8_t  cp_root[32];
    uint8_t  fri_roots[STARK_MAX_FRI_LAYERS][32];
    uint32_t fri_layers;
    sf_t     fri_final;

    uint32_t queries[STARK_FRI_QUERIES];

    sf_t     trace_q     [STARK_FRI_QUERIES];
    sf_t     trace_q_next[STARK_FRI_QUERIES];
    sf_t     cp_q        [STARK_FRI_QUERIES];

    uint8_t  trace_path     [STARK_FRI_QUERIES][STARK_MAX_LOG][32];
    uint8_t  trace_next_path[STARK_FRI_QUERIES][STARK_MAX_LOG][32];
    uint8_t  cp_path        [STARK_FRI_QUERIES][STARK_MAX_LOG][32];

    sf_t     fri_q  [STARK_FRI_QUERIES][STARK_MAX_FRI_LAYERS];
    sf_t     fri_sib[STARK_FRI_QUERIES][STARK_MAX_FRI_LAYERS];
    uint8_t  fri_path[STARK_FRI_QUERIES][STARK_MAX_FRI_LAYERS][STARK_MAX_LOG][32];
    uint32_t fri_layer_size[STARK_MAX_FRI_LAYERS];

    uint32_t domain_size;
    uint32_t trace_len;
    sf_t     c;
    sf_t     x0;
    sf_t     xN;
} stark_proof_t;

int stark_prove (const air_t *air, stark_proof_t *out);
int stark_verify(const air_t *air, const stark_proof_t *pi);

#ifdef __cplusplus
}
#endif
#endif
