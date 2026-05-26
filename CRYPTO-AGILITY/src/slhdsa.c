/* FIPS 205 SLH-DSA (SPHINCS+) reference implementation, hand-rolled.
 * SHA-256-based parameter sets {128s, 192s, 256s}. Hash truncated to n bytes.
 *
 * Components: WOTS+ one-time signatures, Merkle trees, FORS few-time signatures,
 * hypertree of d Merkle trees of WOTS+ public keys.
 *
 * Hashing scheme (simple SHA-256 variant):
 *   F(SK_seed, ADRS, M)       = SHA256(PK_seed || pad || ADRS || M) [n bytes]
 *   H(SK_seed, ADRS, M1||M2)  = same with M1||M2
 *   T_l(...)                  = same with concatenation of l n-byte values
 *   PRF(SK_seed, ADRS)        = SHA256(SK_seed || pad || ADRS) [n bytes]
 *   PRF_msg(SK_prf, opt_rand, M) = SHA256(SK_prf || opt_rand || M) [n bytes]
 *   H_msg(R, PK, M, len)      = MGF1-SHA256
 */
#include "iii/slhdsa.h"
#include "iii/sha3.h"
#include <string.h>

/* SHA-256 forward declaration to avoid pulling lex header (we link against it). */
extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

/* ---- Parameters ---- */
typedef struct {
    int n;       /* security parameter (bytes) */
    int h;       /* total tree height */
    int d;       /* number of layers */
    int hp;      /* h/d */
    int a;       /* FORS tree height */
    int kf;      /* number of FORS trees */
    int w;       /* WOTS+ chunking parameter (always 16 here) */
    int len1, len2, len; /* WOTS+ chain count */
    size_t sig_bytes;
} slh_params;

static int slh_lengths(int n, int *len1, int *len2, int *len) {
    *len1 = 8 * n / 4; /* w=16 => log2(w)=4 */
    /* len2 = floor(log(len1*(w-1))/log(w)) + 1 */
    int max = *len1 * 15;
    int l = 1; int v = 16;
    while (v <= max) { v *= 16; l++; }
    *len2 = l;
    *len = *len1 + *len2;
    return 0;
}

static int slh_get_params(iii_slh_level_t lv, slh_params *P) {
    memset(P, 0, sizeof *P);
    P->w = 16;
    if (lv == III_SLH_128S) {
        P->n=16; P->h=63; P->d=7;  P->hp=9; P->a=12; P->kf=14;
    } else if (lv == III_SLH_192S) {
        P->n=24; P->h=63; P->d=7;  P->hp=9; P->a=14; P->kf=17;
    } else if (lv == III_SLH_256S) {
        P->n=32; P->h=64; P->d=8;  P->hp=8; P->a=14; P->kf=22;
    } else return -1;
    slh_lengths(P->n, &P->len1, &P->len2, &P->len);
    /* Signature size: n (R) + kf*(n + a*n) + d*(len*n + hp*n) */
    P->sig_bytes = (size_t)P->n
                 + (size_t)P->kf * (P->n + (size_t)P->a * P->n)
                 + (size_t)P->d * ((size_t)P->len * P->n + (size_t)P->hp * P->n);
    return 0;
}

void iii_slhdsa_sizes(iii_slh_level_t lv, size_t *pk, size_t *sk, size_t *sig) {
    slh_params P; if (slh_get_params(lv, &P) < 0) { if(pk)*pk=0; if(sk)*sk=0; if(sig)*sig=0; return; }
    if (pk)  *pk = 2 * P.n;
    if (sk)  *sk = 4 * P.n;
    if (sig) *sig = P.sig_bytes;
}

/* ---- ADRS structure (FIPS 205 §4.2). 32 bytes: layer(4) | tree(12) | type(4) | tree_addr/keypair(4) | chain/leaf(4) | hash_addr(4). */
typedef uint8_t ADRS_t[32];
enum { ADRS_WOTS_HASH=0, ADRS_WOTS_PK=1, ADRS_TREE=2, ADRS_FORS_TREE=3, ADRS_FORS_ROOTS=4, ADRS_WOTS_PRF=5, ADRS_FORS_PRF=6 };

static void adrs_zero(ADRS_t a) { memset(a, 0, 32); }
static void adrs_set_layer(ADRS_t a, uint32_t v) { a[0] = (uint8_t)(v >> 24); a[1] = (uint8_t)(v >> 16); a[2] = (uint8_t)(v >> 8); a[3] = (uint8_t)v; }
static void adrs_set_tree(ADRS_t a, uint64_t v) { for (int i = 0; i < 8; i++) a[4 + 4 + i] = (uint8_t)(v >> (8*(7-i))); /* offsets 8..15 (high 4 bytes of 12 are 0) */ }
static void adrs_set_type(ADRS_t a, uint32_t t) {
    a[16] = (uint8_t)(t >> 24); a[17] = (uint8_t)(t >> 16); a[18] = (uint8_t)(t >> 8); a[19] = (uint8_t)t;
    /* clear last 12 bytes when changing type */
    memset(a + 20, 0, 12);
}
static void adrs_set_keypair(ADRS_t a, uint32_t v) { a[20] = (uint8_t)(v>>24); a[21]=(uint8_t)(v>>16); a[22]=(uint8_t)(v>>8); a[23]=(uint8_t)v; }
static void adrs_set_chain(ADRS_t a, uint32_t v) { a[24] = (uint8_t)(v>>24); a[25]=(uint8_t)(v>>16); a[26]=(uint8_t)(v>>8); a[27]=(uint8_t)v; }
static void adrs_set_hash(ADRS_t a, uint32_t v) { a[28]=(uint8_t)(v>>24); a[29]=(uint8_t)(v>>16); a[30]=(uint8_t)(v>>8); a[31]=(uint8_t)v; }
static void adrs_set_tree_height(ADRS_t a, uint32_t v) { adrs_set_chain(a, v); }
static void adrs_set_tree_index(ADRS_t a, uint32_t v) { adrs_set_hash(a, v); }
/* ---- Hash primitives (truncated SHA-256) ---- */
static void H_n(uint8_t *out, int n,
                const uint8_t *seed, size_t seedlen,
                const uint8_t adrs[32],
                const uint8_t *msg, size_t msglen) {
    /* PK_seed || ADRS_compressed(22 bytes per FIPS 205) || msg.
     * For simplicity here, use full 32-byte ADRS. */
    iii_keccak_ctx_t c; (void)c;
    uint8_t h[32];
    /* Use SHA-256 over (seed || adrs || msg) */
    uint8_t *buf = (uint8_t*)__builtin_alloca(seedlen + 32 + msglen);
    memcpy(buf, seed, seedlen);
    memcpy(buf + seedlen, adrs, 32);
    memcpy(buf + seedlen + 32, msg, msglen);
    iii_sha256(buf, seedlen + 32 + msglen, h);
    memcpy(out, h, n);
}

static void PRF(uint8_t *out, int n, const uint8_t *pkseed, const uint8_t *skseed, const uint8_t adrs[32]) {
    /* SHA-256(PK_seed || ADRS || SK_seed) truncated */
    uint8_t buf[32 + 32 + 32];
    memcpy(buf, pkseed, n);
    memcpy(buf + n, adrs, 32);
    memcpy(buf + n + 32, skseed, n);
    uint8_t h[32]; iii_sha256(buf, (size_t)n + 32 + n, h);
    memcpy(out, h, n);
}

static void PRF_msg(uint8_t *out, int n, const uint8_t *skprf, const uint8_t *opt_rand, const uint8_t *msg, size_t msglen) {
    uint8_t *buf = (uint8_t*)__builtin_alloca((size_t)n + n + msglen);
    memcpy(buf, skprf, n);
    memcpy(buf + n, opt_rand, n);
    memcpy(buf + 2*n, msg, msglen);
    uint8_t h[32]; iii_sha256(buf, (size_t)2*n + msglen, h);
    memcpy(out, h, n);
}

/* H_msg uses SHAKE-256 to produce m bytes. */
static void H_msg(uint8_t *out, size_t outlen,
                  const uint8_t *R, int n,
                  const uint8_t *pk, size_t pklen,
                  const uint8_t *msg, size_t msglen) {
    iii_keccak_ctx_t c; iii_keccak_init(&c, 136, 0x1f);
    iii_keccak_absorb(&c, R, n);
    iii_keccak_absorb(&c, pk, pklen);
    iii_keccak_absorb(&c, msg, msglen);
    iii_keccak_finalize(&c);
    iii_keccak_squeeze(&c, out, outlen);
}

/* ---- WOTS+ ---- */
static void wots_chain(uint8_t *out, int n, const uint8_t *in, int start, int steps,
                       const uint8_t *pkseed, ADRS_t adrs) {
    memcpy(out, in, n);
    for (int i = start; i < start + steps; i++) {
        adrs_set_hash(adrs, (uint32_t)i);
        H_n(out, n, pkseed, n, adrs, out, n);
    }
}

static void wots_pkgen(uint8_t *pk_out, int n, int len,
                       const uint8_t *skseed, const uint8_t *pkseed, ADRS_t adrs) {
    uint8_t *chains = (uint8_t*)__builtin_alloca((size_t)len * n);
    ADRS_t skadrs; memcpy(skadrs, adrs, 32);
    adrs_set_type(skadrs, ADRS_WOTS_PRF);
    adrs_set_keypair(skadrs, ((uint32_t)adrs[20]<<24)|((uint32_t)adrs[21]<<16)|((uint32_t)adrs[22]<<8)|adrs[23]);
    for (int i = 0; i < len; i++) {
        uint8_t sk_i[32];
        adrs_set_chain(skadrs, (uint32_t)i);
        adrs_set_hash(skadrs, 0);
        PRF(sk_i, n, pkseed, skseed, skadrs);
        ADRS_t hashadrs; memcpy(hashadrs, adrs, 32);
        adrs_set_chain(hashadrs, (uint32_t)i);
        wots_chain(chains + (size_t)i * n, n, sk_i, 0, 15, pkseed, hashadrs);
    }
    /* PK = T_len(PK_seed, adrs_pk, chains) */
    ADRS_t pk_adrs; memcpy(pk_adrs, adrs, 32);
    adrs_set_type(pk_adrs, ADRS_WOTS_PK);
    H_n(pk_out, n, pkseed, n, pk_adrs, chains, (size_t)len * n);
}

static void wots_chain_lengths(int *lengths, int n, int len1, int len2, const uint8_t *msg) {
    /* base_w(M) for first len1, then checksum csum spread over len2 */
    int csum = 0;
    for (int i = 0; i < n; i++) {
        lengths[2*i]   = msg[i] >> 4;
        lengths[2*i+1] = msg[i] & 0x0f;
    }
    for (int i = 0; i < len1; i++) csum += 15 - lengths[i];
    csum <<= (8 - ((len2 * 4) % 8)) % 8;
    int csum_bytes = (len2 * 4 + 7) / 8;
    uint8_t cs[8] = {0};
    for (int i = csum_bytes - 1; i >= 0; i--) { cs[i] = (uint8_t)(csum & 0xff); csum >>= 8; }
    for (int i = 0; i < len2; i++) {
        if (i % 2 == 0) lengths[len1 + i] = cs[i/2] >> 4;
        else            lengths[len1 + i] = cs[i/2] & 0x0f;
    }
}

static void wots_sign(uint8_t *sig, int n, int len, int len1, int len2,
                      const uint8_t *msg,
                      const uint8_t *skseed, const uint8_t *pkseed, ADRS_t adrs) {
    int lengths[100]; /* len <= 67 for n<=32, w=16 */
    wots_chain_lengths(lengths, n, len1, len2, msg);
    ADRS_t skadrs; memcpy(skadrs, adrs, 32);
    adrs_set_type(skadrs, ADRS_WOTS_PRF);
    uint32_t kp = ((uint32_t)adrs[20]<<24)|((uint32_t)adrs[21]<<16)|((uint32_t)adrs[22]<<8)|adrs[23];
    adrs_set_keypair(skadrs, kp);
    for (int i = 0; i < len; i++) {
        uint8_t sk_i[32];
        adrs_set_chain(skadrs, (uint32_t)i);
        adrs_set_hash(skadrs, 0);
        PRF(sk_i, n, pkseed, skseed, skadrs);
        ADRS_t h; memcpy(h, adrs, 32);
        adrs_set_chain(h, (uint32_t)i);
        wots_chain(sig + (size_t)i * n, n, sk_i, 0, lengths[i], pkseed, h);
    }
}

static void wots_pk_from_sig(uint8_t *pk_out, int n, int len, int len1, int len2,
                              const uint8_t *sig, const uint8_t *msg,
                              const uint8_t *pkseed, ADRS_t adrs) {
    int lengths[100];
    wots_chain_lengths(lengths, n, len1, len2, msg);
    uint8_t *chains = (uint8_t*)__builtin_alloca((size_t)len * n);
    for (int i = 0; i < len; i++) {
        ADRS_t h; memcpy(h, adrs, 32);
        adrs_set_chain(h, (uint32_t)i);
        wots_chain(chains + (size_t)i * n, n, sig + (size_t)i * n, lengths[i], 15 - lengths[i], pkseed, h);
    }
    ADRS_t pk_adrs; memcpy(pk_adrs, adrs, 32);
    adrs_set_type(pk_adrs, ADRS_WOTS_PK);
    H_n(pk_out, n, pkseed, n, pk_adrs, chains, (size_t)len * n);
}


static void compute_root_from_path(uint8_t *root, int n, int height, uint32_t leaf_idx,
                                   const uint8_t *leaf, const uint8_t *auth,
                                   const uint8_t *pkseed, uint32_t layer, uint64_t tree, int is_fors) {
    uint8_t cur[32]; memcpy(cur, leaf, n);
    for (int h = 0; h < height; h++) {
        ADRS_t a; adrs_zero(a);
        adrs_set_layer(a, layer);
        adrs_set_tree(a, tree);
        adrs_set_type(a, is_fors ? ADRS_FORS_TREE : ADRS_TREE);
        adrs_set_tree_height(a, (uint32_t)(h + 1));
        adrs_set_tree_index(a, (leaf_idx >> (h + 1)));
        uint8_t cat[64];
        if ((leaf_idx >> h) & 1) {
            memcpy(cat, auth + (size_t)h * n, n);
            memcpy(cat + n, cur, n);
        } else {
            memcpy(cat, cur, n);
            memcpy(cat + n, auth + (size_t)h * n, n);
        }
        H_n(cur, n, pkseed, n, a, cat, (size_t)2 * n);
    }
    memcpy(root, cur, n);
}

/* ---- FORS ---- */
static void fors_indices(uint32_t *idx, int kf, int a, const uint8_t *digest) {
    /* extract kf indices of a bits each from digest */
    int bit = 0;
    for (int i = 0; i < kf; i++) {
        uint32_t v = 0;
        for (int b = 0; b < a; b++) {
            int byte = bit / 8, off = 7 - (bit % 8);
            v = (v << 1) | (uint32_t)((digest[byte] >> off) & 1);
            bit++;
        }
        idx[i] = v;
    }
}

static void fors_sign_and_root(uint8_t *sig_out, uint8_t *root_out,
                               int n, int a, int kf,
                               const uint8_t *digest,
                               const uint8_t *skseed, const uint8_t *pkseed,
                               uint32_t layer, uint64_t tree) {
    uint32_t idx[64]; fors_indices(idx, kf, a, digest);
    uint8_t roots[64 * 32]; /* up to 22 * 32 bytes */
    for (int t = 0; t < kf; t++) {
        uint32_t leaf_offset = (uint32_t)t << a;
        uint32_t leaf_idx = idx[t];
        /* sign: SK_i || auth path */
        uint8_t sk_i[32];
        ADRS_t skadrs; adrs_zero(skadrs);
        adrs_set_layer(skadrs, layer);
        adrs_set_tree(skadrs, tree);
        adrs_set_type(skadrs, ADRS_FORS_PRF);
        adrs_set_tree_height(skadrs, 0);
        adrs_set_tree_index(skadrs, leaf_offset + leaf_idx);
        PRF(sk_i, n, pkseed, skseed, skadrs);
        memcpy(sig_out + (size_t)t * (n + (size_t)a * n), sk_i, n);

        /* compute auth path naively */
        uint8_t *auth = sig_out + (size_t)t * (n + (size_t)a * n) + n;
        for (int h = 0; h < a; h++) {
            uint32_t sibling_idx = (leaf_idx >> h) ^ 1;
            uint8_t node[32];
            /* compute subtree root at height h, index sibling_idx */
            int subleaves = 1 << h;
            uint32_t sublo = leaf_offset + (sibling_idx << h);
            /* recursive treehash */
            uint8_t *stack = (uint8_t*)__builtin_alloca((size_t)(h + 2) * n);
            int *hh = (int*)__builtin_alloca((size_t)(h + 2) * sizeof(int));
            int top = 0;
            for (int j = 0; j < subleaves; j++) {
                uint8_t leaf[32], sk_j[32];
                ADRS_t la; adrs_zero(la);
                adrs_set_layer(la, layer);
                adrs_set_tree(la, tree);
                adrs_set_type(la, ADRS_FORS_TREE);
                adrs_set_tree_height(la, 0);
                adrs_set_tree_index(la, sublo + j);
                ADRS_t lp; memcpy(lp, la, 32); adrs_set_type(lp, ADRS_FORS_PRF);
                adrs_set_tree_index(lp, sublo + j);
                PRF(sk_j, n, pkseed, skseed, lp);
                H_n(leaf, n, pkseed, n, la, sk_j, n);
                memcpy(stack + (size_t)top * n, leaf, n);
                hh[top] = 0; top++;
                while (top >= 2 && hh[top-1] == hh[top-2]) {
                    ADRS_t pa; adrs_zero(pa);
                    adrs_set_layer(pa, layer);
                    adrs_set_tree(pa, tree);
                    adrs_set_type(pa, ADRS_FORS_TREE);
                    adrs_set_tree_height(pa, (uint32_t)(hh[top-1] + 1));
                    uint32_t parent_idx = (sublo + j) >> (hh[top-1] + 1);
                    adrs_set_tree_index(pa, parent_idx);
                    uint8_t cat[64];
                    memcpy(cat, stack + (size_t)(top-2)*n, n);
                    memcpy(cat + n, stack + (size_t)(top-1)*n, n);
                    H_n(stack + (size_t)(top-2)*n, n, pkseed, n, pa, cat, (size_t)2*n);
                    top--; hh[top-1]++;
                }
            }
            memcpy(node, stack, n);
            memcpy(auth + (size_t)h * n, node, n);
        }

        /* compute root of tree t */
        uint8_t leaf[32];
        ADRS_t la; adrs_zero(la);
        adrs_set_layer(la, layer); adrs_set_tree(la, tree);
        adrs_set_type(la, ADRS_FORS_TREE);
        adrs_set_tree_height(la, 0);
        adrs_set_tree_index(la, leaf_offset + leaf_idx);
        H_n(leaf, n, pkseed, n, la, sk_i, n);
        compute_root_from_path(roots + (size_t)t * n, n, a, leaf_offset + leaf_idx,
                               leaf, auth, pkseed, layer, tree, 1);
    }
    /* root_out = T_kf(PK_seed, ADRS_FORS_ROOTS, roots) */
    ADRS_t r; adrs_zero(r);
    adrs_set_layer(r, layer); adrs_set_tree(r, tree);
    adrs_set_type(r, ADRS_FORS_ROOTS);
    H_n(root_out, n, pkseed, n, r, roots, (size_t)kf * n);
}

static void fors_pk_from_sig(uint8_t *pk_out, int n, int a, int kf,
                             const uint8_t *sig, const uint8_t *digest,
                             const uint8_t *pkseed,
                             uint32_t layer, uint64_t tree) {
    uint32_t idx[64]; fors_indices(idx, kf, a, digest);
    uint8_t roots[64 * 32];
    for (int t = 0; t < kf; t++) {
        const uint8_t *sk_i = sig + (size_t)t * (n + (size_t)a * n);
        const uint8_t *auth = sk_i + n;
        uint32_t leaf_offset = (uint32_t)t << a;
        uint32_t leaf_idx = idx[t];
        uint8_t leaf[32];
        ADRS_t la; adrs_zero(la);
        adrs_set_layer(la, layer); adrs_set_tree(la, tree);
        adrs_set_type(la, ADRS_FORS_TREE);
        adrs_set_tree_height(la, 0);
        adrs_set_tree_index(la, leaf_offset + leaf_idx);
        H_n(leaf, n, pkseed, n, la, sk_i, n);
        compute_root_from_path(roots + (size_t)t * n, n, a, leaf_offset + leaf_idx,
                               leaf, auth, pkseed, layer, tree, 1);
    }
    ADRS_t r; adrs_zero(r);
    adrs_set_layer(r, layer); adrs_set_tree(r, tree);
    adrs_set_type(r, ADRS_FORS_ROOTS);
    H_n(pk_out, n, pkseed, n, r, roots, (size_t)kf * n);
}

/* ---- XMSS / Hypertree helpers ---- */
static void xmss_sign_and_root(uint8_t *sig_out, uint8_t *root_out,
                               const slh_params *P,
                               const uint8_t *msg /* n bytes */,
                               const uint8_t *skseed, const uint8_t *pkseed,
                               uint32_t layer, uint64_t tree, uint32_t leaf_idx) {
    /* WOTS sig */
    ADRS_t adrs; adrs_zero(adrs);
    adrs_set_layer(adrs, layer); adrs_set_tree(adrs, tree);
    adrs_set_type(adrs, ADRS_WOTS_HASH);
    adrs_set_keypair(adrs, leaf_idx);
    wots_sign(sig_out, P->n, P->len, P->len1, P->len2, msg, skseed, pkseed, adrs);

    /* WOTS leaf = wots_pkgen */
    uint8_t leaf[32];
    wots_pkgen(leaf, P->n, P->len, skseed, pkseed, adrs);

    /* auth path */
    uint8_t *auth = sig_out + (size_t)P->len * P->n;
    int height = P->hp;
    for (int h = 0; h < height; h++) {
        uint32_t sibling_lo = ((leaf_idx >> h) ^ 1) << h;
        uint32_t sibling_hi = sibling_lo + (1 << h);
        /* compute root of subtree at this offset */
        uint8_t *stack = (uint8_t*)__builtin_alloca((size_t)(h + 2) * P->n);
        int *hh = (int*)__builtin_alloca((size_t)(h + 2) * sizeof(int));
        int top = 0;
        for (uint32_t j = sibling_lo; j < sibling_hi; j++) {
            uint8_t lf[32];
            ADRS_t wadrs; adrs_zero(wadrs);
            adrs_set_layer(wadrs, layer); adrs_set_tree(wadrs, tree);
            adrs_set_type(wadrs, ADRS_WOTS_HASH);
            adrs_set_keypair(wadrs, j);
            wots_pkgen(lf, P->n, P->len, skseed, pkseed, wadrs);
            memcpy(stack + (size_t)top * P->n, lf, P->n);
            hh[top] = 0; top++;
            while (top >= 2 && hh[top-1] == hh[top-2]) {
                ADRS_t pa; adrs_zero(pa);
                adrs_set_layer(pa, layer); adrs_set_tree(pa, tree);
                adrs_set_type(pa, ADRS_TREE);
                adrs_set_tree_height(pa, (uint32_t)(hh[top-1] + 1));
                adrs_set_tree_index(pa, j >> (hh[top-1] + 1));
                uint8_t cat[64];
                memcpy(cat, stack + (size_t)(top-2)*P->n, P->n);
                memcpy(cat + P->n, stack + (size_t)(top-1)*P->n, P->n);
                H_n(stack + (size_t)(top-2)*P->n, P->n, pkseed, P->n, pa, cat, (size_t)2*P->n);
                top--; hh[top-1]++;
            }
        }
        memcpy(auth + (size_t)h * P->n, stack, P->n);
    }

    /* compute root */
    compute_root_from_path(root_out, P->n, height, leaf_idx, leaf, auth, pkseed, layer, tree, 0);
}

static void xmss_pk_from_sig(uint8_t *root_out, const slh_params *P,
                             const uint8_t *msg,
                             const uint8_t *sig,
                             const uint8_t *pkseed,
                             uint32_t layer, uint64_t tree, uint32_t leaf_idx) {
    /* recompute wots pk from sig and message, then climb auth path */
    ADRS_t adrs; adrs_zero(adrs);
    adrs_set_layer(adrs, layer); adrs_set_tree(adrs, tree);
    adrs_set_type(adrs, ADRS_WOTS_HASH);
    adrs_set_keypair(adrs, leaf_idx);
    uint8_t leaf[32];
    wots_pk_from_sig(leaf, P->n, P->len, P->len1, P->len2, sig, msg, pkseed, adrs);
    const uint8_t *auth = sig + (size_t)P->len * P->n;
    compute_root_from_path(root_out, P->n, P->hp, leaf_idx, leaf, auth, pkseed, layer, tree, 0);
}

/* ---- Top-level keygen / sign / verify ---- */
int iii_slhdsa_keygen(iii_slh_level_t lv, const uint8_t *seed,
                      uint8_t *pk, uint8_t *sk) {
    slh_params P; if (slh_get_params(lv, &P) < 0) return -1;
    /* seed: SK_seed (n) || SK_prf (n) || PK_seed (n) */
    const uint8_t *skseed = seed;
    const uint8_t *skprf  = seed + P.n;
    const uint8_t *pkseed = seed + 2*P.n;

    /* Compute root of top-layer tree: layer = d-1, tree = 0 */
    uint8_t root[32];
    /* dummy WOTS sig discard */
    uint8_t *dummy = (uint8_t*)__builtin_alloca((size_t)P.len * P.n + (size_t)P.hp * P.n);
    /* synthetic message: zero-bytes of length n */
    uint8_t msg0[32] = {0};
    /* The XMSS root depends on the structure of all leaves; we just compute it via a
     * "compute root only" by using the auth-path trick with a dummy leaf_idx=0.
     * For correctness we'll use the full tree by computing root via building all leaves. */
    /* Build all 2^hp leaves and tree-hash. */
    uint32_t leaves = 1u << P.hp;
    uint8_t *stack = (uint8_t*)__builtin_alloca((size_t)(P.hp + 2) * P.n);
    int *hh = (int*)__builtin_alloca((size_t)(P.hp + 2) * sizeof(int));
    int top = 0;
    for (uint32_t j = 0; j < leaves; j++) {
        uint8_t lf[32];
        ADRS_t wadrs; adrs_zero(wadrs);
        adrs_set_layer(wadrs, (uint32_t)(P.d - 1));
        adrs_set_tree(wadrs, 0);
        adrs_set_type(wadrs, ADRS_WOTS_HASH);
        adrs_set_keypair(wadrs, j);
        wots_pkgen(lf, P.n, P.len, skseed, pkseed, wadrs);
        memcpy(stack + (size_t)top * P.n, lf, P.n);
        hh[top] = 0; top++;
        while (top >= 2 && hh[top-1] == hh[top-2]) {
            ADRS_t pa; adrs_zero(pa);
            adrs_set_layer(pa, (uint32_t)(P.d - 1));
            adrs_set_tree(pa, 0);
            adrs_set_type(pa, ADRS_TREE);
            adrs_set_tree_height(pa, (uint32_t)(hh[top-1] + 1));
            adrs_set_tree_index(pa, j >> (hh[top-1] + 1));
            uint8_t cat[64];
            memcpy(cat, stack + (size_t)(top-2)*P.n, P.n);
            memcpy(cat + P.n, stack + (size_t)(top-1)*P.n, P.n);
            H_n(stack + (size_t)(top-2)*P.n, P.n, pkseed, P.n, pa, cat, (size_t)2*P.n);
            top--; hh[top-1]++;
        }
    }
    memcpy(root, stack, P.n);
    (void)dummy; (void)msg0; (void)skprf;

    /* pk = pkseed || root */
    memcpy(pk, pkseed, P.n);
    memcpy(pk + P.n, root, P.n);
    /* sk = skseed || skprf || pkseed || root */
    memcpy(sk, skseed, P.n);
    memcpy(sk + P.n, skprf, P.n);
    memcpy(sk + 2*P.n, pkseed, P.n);
    memcpy(sk + 3*P.n, root, P.n);
    return 0;
}

int iii_slhdsa_sign(iii_slh_level_t lv, const uint8_t *sk,
                    const uint8_t *msg, size_t msglen,
                    uint8_t *sig, size_t *siglen) {
    slh_params P; if (slh_get_params(lv, &P) < 0) return -1;
    const uint8_t *skseed = sk;
    const uint8_t *skprf  = sk + P.n;
    const uint8_t *pkseed = sk + 2*P.n;
    const uint8_t *root   = sk + 3*P.n;
    uint8_t pk[64]; memcpy(pk, pkseed, P.n); memcpy(pk + P.n, root, P.n);

    /* R = PRF_msg(SK_prf, opt_rand=PK_seed, msg) */
    uint8_t R[32];
    PRF_msg(R, P.n, skprf, pkseed, msg, msglen);
    memcpy(sig, R, P.n);

    /* digest = H_msg(R, PK, msg, m_bytes) where m_bytes = ceil(kf*a/8) + ceil((h - h/d)/8) + ceil((h/d)/8) */
    int top_bits = P.h - P.hp;
    int leaf_bits = P.hp;
    size_t md_len = (size_t)((P.kf * P.a + 7) / 8) + (size_t)((top_bits + 7) / 8) + (size_t)((leaf_bits + 7) / 8);
    uint8_t *digest = (uint8_t*)__builtin_alloca(md_len);
    H_msg(digest, md_len, R, P.n, pk, (size_t)2 * P.n, msg, msglen);

    const uint8_t *md = digest;
    const uint8_t *tree_idx_bytes = digest + (P.kf * P.a + 7) / 8;
    const uint8_t *leaf_idx_bytes = tree_idx_bytes + (top_bits + 7) / 8;

    uint64_t tree_idx = 0;
    int tib = (top_bits + 7) / 8;
    for (int i = 0; i < tib; i++) tree_idx = (tree_idx << 8) | tree_idx_bytes[i];
    /* mask to top_bits */
    tree_idx &= (top_bits == 64) ? ~0ULL : ((1ULL << top_bits) - 1);

    uint32_t leaf_idx = 0;
    int lib = (leaf_bits + 7) / 8;
    for (int i = 0; i < lib; i++) leaf_idx = (leaf_idx << 8) | leaf_idx_bytes[i];
    leaf_idx &= ((1U << leaf_bits) - 1);

    /* FORS sign at layer 0, tree = tree_idx */
    uint8_t *p = sig + P.n;
    uint8_t fors_root[32];
    fors_sign_and_root(p, fors_root, P.n, P.a, P.kf, md, skseed, pkseed,
                       0 /* layer */, tree_idx /* tree (FORS uses ADRS tree) */);
    p += (size_t)P.kf * (P.n + (size_t)P.a * P.n);

    /* Hypertree sign: starts at layer 0, signs fors_root, climbs up. */
    uint8_t cur_msg[32]; memcpy(cur_msg, fors_root, P.n);
    uint64_t cur_tree = tree_idx;
    uint32_t cur_leaf = leaf_idx;
    /* Actually per FIPS 205: the FORS instance is at (layer=0, tree=tree_idx, keypair=leaf_idx).
     * The bottom-layer XMSS signs fors_root using leaf_idx within tree_idx.
     * Then the upper layers sign the previous root. */
    uint8_t next_root[32];
    for (int layer = 0; layer < P.d; layer++) {
        xmss_sign_and_root(p, next_root, &P, cur_msg, skseed, pkseed,
                           (uint32_t)layer, cur_tree, cur_leaf);
        p += (size_t)P.len * P.n + (size_t)P.hp * P.n;
        memcpy(cur_msg, next_root, P.n);
        /* shift indices */
        cur_leaf = (uint32_t)(cur_tree & ((1ULL << P.hp) - 1));
        cur_tree >>= P.hp;
    }

    *siglen = P.sig_bytes;
    return 0;
}

int iii_slhdsa_verify(iii_slh_level_t lv, const uint8_t *pk,
                      const uint8_t *msg, size_t msglen,
                      const uint8_t *sig, size_t siglen) {
    slh_params P; if (slh_get_params(lv, &P) < 0) return -1;
    if (siglen != P.sig_bytes) return -1;
    const uint8_t *pkseed = pk;
    const uint8_t *root   = pk + P.n;
    const uint8_t *R      = sig;

    int top_bits = P.h - P.hp;
    int leaf_bits = P.hp;
    size_t md_len = (size_t)((P.kf * P.a + 7) / 8) + (size_t)((top_bits + 7) / 8) + (size_t)((leaf_bits + 7) / 8);
    uint8_t *digest = (uint8_t*)__builtin_alloca(md_len);
    H_msg(digest, md_len, R, P.n, pk, (size_t)2 * P.n, msg, msglen);

    const uint8_t *md = digest;
    const uint8_t *tib = digest + (P.kf * P.a + 7) / 8;
    const uint8_t *lib = tib + (top_bits + 7) / 8;

    uint64_t tree_idx = 0;
    int tibl = (top_bits + 7) / 8;
    for (int i = 0; i < tibl; i++) tree_idx = (tree_idx << 8) | tib[i];
    tree_idx &= (top_bits == 64) ? ~0ULL : ((1ULL << top_bits) - 1);
    uint32_t leaf_idx = 0;
    int libl = (leaf_bits + 7) / 8;
    for (int i = 0; i < libl; i++) leaf_idx = (leaf_idx << 8) | lib[i];
    leaf_idx &= ((1U << leaf_bits) - 1);

    const uint8_t *p = sig + P.n;
    uint8_t fors_root[32];
    fors_pk_from_sig(fors_root, P.n, P.a, P.kf, p, md, pkseed, 0, tree_idx);
    p += (size_t)P.kf * (P.n + (size_t)P.a * P.n);

    uint8_t cur[32]; memcpy(cur, fors_root, P.n);
    uint64_t cur_tree = tree_idx;
    uint32_t cur_leaf = leaf_idx;
    uint8_t next[32];
    for (int layer = 0; layer < P.d; layer++) {
        xmss_pk_from_sig(next, &P, cur, p, pkseed, (uint32_t)layer, cur_tree, cur_leaf);
        p += (size_t)P.len * P.n + (size_t)P.hp * P.n;
        memcpy(cur, next, P.n);
        cur_leaf = (uint32_t)(cur_tree & ((1ULL << P.hp) - 1));
        cur_tree >>= P.hp;
    }
    int diff = 0;
    for (int i = 0; i < P.n; i++) diff |= cur[i] ^ root[i];
    return diff == 0 ? 0 : -1;
}
