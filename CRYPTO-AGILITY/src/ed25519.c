/* ============================================================================
 * Ed25519 — RFC 8032 implementation, NIH (no third-party crypto library).
 *
 * Field GF(p), p = 2^255 - 19.  Elements stored as 32 bytes little-endian.
 * Curve: -x^2 + y^2 = 1 + d·x²·y², d = -121665/121666.
 * Base point B has order L = 2^252 + 27742317777372353535851937790883648493.
 *
 * Field arithmetic uses BigInt32-style 32-byte LE buffers with carry-based
 * add / mul / reduce.  Slow but correct.  Verified against RFC 8032 §7.1
 * known-answer vectors before shipping.
 * ============================================================================
 */
#include "iii/ed25519.h"
#include "iii/sha2.h"
#include <string.h>

/* ----------------------------------------------------------------------------
 * Field element: 32 bytes LE, value < 2*p (sometimes).  Reduction normalises
 * to canonical form < p.
 * ---------------------------------------------------------------------------- */
typedef uint8_t fe[32];

static void fe_copy(fe r, const fe a) { memcpy(r, a, 32); }
static void fe_zero(fe r) { memset(r, 0, 32); }
static void fe_one (fe r) { fe_zero(r); r[0] = 1; }

/* a < b ? */
static int fe_lt_bytes(const fe a, const fe b) {
    for (int i = 31; i >= 0; --i) {
        if (a[i] != b[i]) return a[i] < b[i];
    }
    return 0;
}

/* p = 2^255 - 19, LE bytes. */
static const fe fe_p = {
    0xed, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f
};

/* Reduce r modulo p, where r < 2p (i.e., subtract p once if r >= p). */
static void fe_reduce(fe r) {
    if (!fe_lt_bytes(r, fe_p)) {
        unsigned borrow = 0;
        for (int i = 0; i < 32; ++i) {
            int v = (int)r[i] - (int)fe_p[i] - (int)borrow;
            if (v < 0) { v += 256; borrow = 1; } else borrow = 0;
            r[i] = (uint8_t)v;
        }
    }
}

/* r = a + b mod p */
static void fe_add(fe r, const fe a, const fe b) {
    unsigned carry = 0;
    for (int i = 0; i < 32; ++i) {
        unsigned s = (unsigned)a[i] + b[i] + carry;
        r[i] = (uint8_t)s;
        carry = s >> 8;
    }
    /* a, b < p < 2^255, so r < 2p+1. Reduce. */
    fe_reduce(r);
    /* If carry escaped (r ≥ 2^255), subtract p. */
    if (carry) {
        unsigned borrow = 0;
        for (int i = 0; i < 32; ++i) {
            int v = (int)r[i] - (int)fe_p[i] - (int)borrow;
            if (v < 0) { v += 256; borrow = 1; } else borrow = 0;
            r[i] = (uint8_t)v;
        }
    }
    fe_reduce(r);
}

/* r = a - b mod p */
static void fe_sub(fe r, const fe a, const fe b) {
    /* Compute a + (p - b) to avoid signed underflow. */
    fe pmb;
    unsigned borrow = 0;
    for (int i = 0; i < 32; ++i) {
        int v = (int)fe_p[i] - (int)b[i] - (int)borrow;
        if (v < 0) { v += 256; borrow = 1; } else borrow = 0;
        pmb[i] = (uint8_t)v;
    }
    fe_add(r, a, pmb);
}

/* r = a * b mod p, schoolbook. */
static void fe_mul(fe r, const fe a, const fe b) {
    uint64_t prod[64] = {0};
    for (int i = 0; i < 32; ++i) {
        uint64_t carry = 0;
        for (int j = 0; j < 32; ++j) {
            uint64_t v = prod[i + j] + (uint64_t)a[i] * b[j] + carry;
            prod[i + j] = v & 0xFFu;
            carry = v >> 8;
        }
        int k = i + 32;
        while (carry) {
            uint64_t v = prod[k] + carry;
            prod[k] = v & 0xFFu;
            carry = v >> 8;
            k++;
        }
    }
    /* Reduce mod p = 2^255 - 19 :
     * Split the 64-byte product into low (bytes 0..31, value < 2^256) and
     * high (bytes 32..63).  Then 2^256 ≡ 2·19 mod p (since 2^255 = 19, so
     * 2^256 = 2·2^255 = 38 mod p).  But our high bits start at 2^256, so
     * each high byte at position 32+k contributes 2^(8(32+k)) = 2^256 · 2^(8k)
     * = 38 · 2^(8k) mod p.  Apply iteratively. */
    /* Pull the top 256 bits down. */
    uint64_t carry = 0;
    /* First pass: replace prod[32+k] with prod[k] += 38 * prod[32+k] (k=0..31). */
    for (int i = 0; i < 32; ++i) {
        uint64_t v = prod[i] + carry + 38ull * prod[32 + i];
        prod[i] = v & 0xFFu;
        carry = v >> 8;
        prod[32 + i] = 0;
    }
    /* Carry now sits at position 32 (= 2^256).  Multiply by 19 (since 2^256 ≡ 38 ≡ 2·19 mod p,
     * but we only need to fold one more time since the carry is small). */
    /* Actually carry is from 32-byte sum, can be up to ~38 * 256 = ~10000, fits in 16 bits. */
    {
        uint64_t v = prod[0] + 38ull * carry;
        prod[0] = v & 0xFFu;
        uint64_t c2 = v >> 8;
        for (int i = 1; i < 32 && c2; ++i) {
            v = prod[i] + c2;
            prod[i] = v & 0xFFu;
            c2 = v >> 8;
        }
        /* Any further carry: bit 256 is 38 mod p — but bit-256 carry from a single
         * 38·carry pass should be tiny; iterate a few more times if needed. */
        if (c2) {
            uint64_t v3 = prod[0] + 38ull * c2;
            prod[0] = v3 & 0xFFu;
            uint64_t c3 = v3 >> 8;
            for (int i = 1; i < 32 && c3; ++i) {
                v3 = prod[i] + c3;
                prod[i] = v3 & 0xFFu;
                c3 = v3 >> 8;
            }
        }
    }
    for (int i = 0; i < 32; ++i) r[i] = (uint8_t)prod[i];
    fe_reduce(r);
}

static void fe_sq(fe r, const fe a) { fe_mul(r, a, a); }

/* a^(p-2) by repeated squaring (Fermat for inverse). */
static void fe_inv(fe r, const fe a) {
    /* Exponent = p - 2 = 2^255 - 21.  We use addition-chain via square-and-multiply. */
    fe pm2;
    /* p - 2 in LE: ed - 2 = eb at byte 0, rest as p. */
    fe_copy(pm2, fe_p);
    pm2[0] -= 2u;
    /* Compute r = a^pm2 by left-to-right square-and-multiply. */
    fe acc; fe_one(acc);
    int started = 0;
    for (int i = 31; i >= 0; --i) {
        for (int b = 7; b >= 0; --b) {
            if (started) { fe t; fe_sq(t, acc); fe_copy(acc, t); }
            if ((pm2[i] >> b) & 1u) {
                if (started) { fe t; fe_mul(t, acc, a); fe_copy(acc, t); }
                else { fe_copy(acc, a); started = 1; }
            }
        }
    }
    fe_copy(r, acc);
}

/* a^((p-5)/8): used for square root in Ed25519 */
static void fe_pow_p58(fe r, const fe a) {
    /* (p-5)/8 = 2^252 - 3.  LE: 0xfd, 0xff..., 0x0f */
    static const fe e = {
        0xfd, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x0f
    };
    fe acc; fe_one(acc);
    int started = 0;
    for (int i = 31; i >= 0; --i) {
        for (int b = 7; b >= 0; --b) {
            if (started) { fe t; fe_sq(t, acc); fe_copy(acc, t); }
            if ((e[i] >> b) & 1u) {
                if (started) { fe t; fe_mul(t, acc, a); fe_copy(acc, t); }
                else { fe_copy(acc, a); started = 1; }
            }
        }
    }
    fe_copy(r, acc);
}

static int fe_iszero(const fe a) {
    uint8_t r = 0;
    for (int i = 0; i < 32; ++i) r |= a[i];
    return r == 0;
}

/* ----------------------------------------------------------------------------
 * Curve constants (Ed25519).
 * ---------------------------------------------------------------------------- */
/* d = -121665/121666 mod p */
static const fe ed_d = {
    0xa3, 0x78, 0x59, 0x13, 0xca, 0x4d, 0xeb, 0x75,
    0xab, 0xd8, 0x41, 0x41, 0x4d, 0x0a, 0x70, 0x00,
    0x98, 0xe8, 0x79, 0x77, 0x79, 0x40, 0xc7, 0x8c,
    0x73, 0xfe, 0x6f, 0x2b, 0xee, 0x6c, 0x03, 0x52
};
/* sqrt(-1) mod p */
static const fe ed_sqrtm1 = {
    0xb0, 0xa0, 0x0e, 0x4a, 0x27, 0x1b, 0xee, 0xc4,
    0x78, 0xe4, 0x2f, 0xad, 0x06, 0x18, 0x43, 0x2f,
    0xa7, 0xd7, 0xfb, 0x3d, 0x99, 0x00, 0x4d, 0x2b,
    0x0b, 0xdf, 0xc1, 0x4f, 0x80, 0x24, 0x83, 0x2b
};
/* Base point B: y = 4/5 mod p, x recovered. */
static const fe ed_By = {
    0x58, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
    0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
    0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
    0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66
};
static const fe ed_Bx = {
    0x1a, 0xd5, 0x25, 0x8f, 0x60, 0x2d, 0x56, 0xc9,
    0xb2, 0xa7, 0x25, 0x95, 0x60, 0xc7, 0x2c, 0x69,
    0x5c, 0xdc, 0xd6, 0xfd, 0x31, 0xe2, 0xa4, 0xc0,
    0xfe, 0x53, 0x6e, 0xcd, 0xd3, 0x36, 0x69, 0x21
};

/* ----------------------------------------------------------------------------
 * Group: extended Edwards (X, Y, Z, T) with x*y = T*Z and T = x*y.
 * ---------------------------------------------------------------------------- */
typedef struct { fe X, Y, Z, T; } ge;

static void ge_zero(ge *p) {
    fe_zero(p->X); fe_one(p->Y); fe_one(p->Z); fe_zero(p->T);
}

static void ge_basepoint(ge *p) {
    fe_copy(p->X, ed_Bx);
    fe_copy(p->Y, ed_By);
    fe_one(p->Z);
    fe_mul(p->T, ed_Bx, ed_By);
}

/* Extended Edwards addition (RFC 8032 §5.1.4 / Hisil et al.). */
static void ge_add(ge *r, const ge *a, const ge *b) {
    fe A, B, C, D, E, F, G, H, t1, t2;
    fe_sub(t1, a->Y, a->X);
    fe_sub(t2, b->Y, b->X);
    fe_mul(A, t1, t2);
    fe_add(t1, a->Y, a->X);
    fe_add(t2, b->Y, b->X);
    fe_mul(B, t1, t2);
    fe_mul(C, a->T, b->T);
    fe_add(t1, ed_d, ed_d);
    fe_mul(C, C, t1);
    fe_mul(D, a->Z, b->Z);
    fe_add(D, D, D);
    fe_sub(E, B, A);
    fe_sub(F, D, C);
    fe_add(G, D, C);
    fe_add(H, B, A);
    fe_mul(r->X, E, F);
    fe_mul(r->Y, G, H);
    fe_mul(r->T, E, H);
    fe_mul(r->Z, F, G);
}

/* Doubling on extended Edwards. */
static void ge_dbl(ge *r, const ge *a) {
    fe A, B, C, D, E, G, F, H, t;
    fe_sq(A, a->X);
    fe_sq(B, a->Y);
    fe_sq(C, a->Z);
    fe_add(C, C, C);
    fe_zero(D);
    fe_sub(D, D, A);    /* D = -A */
    fe_add(t, a->X, a->Y);
    fe_sq(t, t);
    fe_sub(t, t, A);
    fe_sub(E, t, B);
    fe_add(G, D, B);
    fe_sub(F, G, C);
    fe_sub(H, D, B);
    fe_mul(r->X, E, F);
    fe_mul(r->Y, G, H);
    fe_mul(r->T, E, H);
    fe_mul(r->Z, F, G);
}

/* r = -p (negate X and T). */
static void ge_neg(ge *r, const ge *a) {
    fe_zero(r->X); fe_sub(r->X, r->X, a->X);
    fe_copy(r->Y, a->Y);
    fe_copy(r->Z, a->Z);
    fe_zero(r->T); fe_sub(r->T, r->T, a->T);
}

/* Compress to 32 bytes: encode y, then OR sign-of-x into bit 255. */
static void ge_compress(uint8_t out[32], const ge *p) {
    fe x, y, zinv;
    fe_inv(zinv, p->Z);
    fe_mul(x, p->X, zinv);
    fe_mul(y, p->Y, zinv);
    fe_reduce(x); fe_reduce(y);
    memcpy(out, y, 32);
    out[31] |= (uint8_t)((x[0] & 1u) << 7);
}

/* Decompress 32-byte encoding to (X, Y, Z, T) point.  Returns 0 on success. */
static int ge_decompress(ge *p, const uint8_t in[32]) {
    fe y, x, u, v, vxx, ck;
    fe_copy(y, in);
    int sign = (y[31] >> 7) & 1;
    y[31] &= 0x7Fu;
    fe_reduce(y);
    /* u = y^2 - 1, v = d*y^2 + 1 */
    fe_sq(u, y);
    fe_mul(v, u, ed_d);
    {
        fe one; fe_one(one);
        fe_sub(u, u, one);
        fe_add(v, v, one);
    }
    /* x = u*v^3 * (u*v^7)^((p-5)/8) */
    fe v3, v7, t;
    fe_sq(v3, v); fe_mul(v3, v3, v);     /* v^3 */
    fe_sq(v7, v3); fe_mul(v7, v7, v);    /* v^7 */
    fe_mul(t, u, v7);
    fe_pow_p58(t, t);
    fe_mul(x, u, v3);
    fe_mul(x, x, t);
    /* Check vx² = ±u */
    fe_sq(vxx, x);
    fe_mul(vxx, vxx, v);
    fe_sub(ck, vxx, u);
    if (!fe_iszero(ck)) {
        fe_add(ck, vxx, u);
        if (!fe_iszero(ck)) return -1;
        /* Multiply by sqrt(-1). */
        fe_mul(x, x, ed_sqrtm1);
    }
    /* Adjust sign. */
    fe_reduce(x);
    if ((x[0] & 1u) != (unsigned)sign) {
        fe nx; fe_zero(nx); fe_sub(nx, nx, x); fe_copy(x, nx);
    }
    fe_copy(p->X, x);
    fe_copy(p->Y, y);
    fe_one(p->Z);
    fe_mul(p->T, x, y);
    return 0;
}

/* Scalar multiply with double-and-add (variable-time; OK for verify). */
static void ge_scalar_mul(ge *r, const uint8_t scalar[32], const ge *p) {
    ge acc; ge_zero(&acc);
    int started = 0;
    for (int i = 31; i >= 0; --i) {
        for (int b = 7; b >= 0; --b) {
            if (started) { ge t; ge_dbl(&t, &acc); acc = t; }
            if ((scalar[i] >> b) & 1u) {
                if (started) { ge t; ge_add(&t, &acc, p); acc = t; }
                else { acc = *p; started = 1; }
            }
        }
    }
    if (!started) ge_zero(&acc);
    *r = acc;
}

/* Double-scalar mult: r = a·A + b·B (variable-time). */
static void ge_double_scalar_mul(ge *r,
                                 const uint8_t a[32], const ge *A,
                                 const uint8_t b[32], const ge *B) {
    ge acc; ge_zero(&acc);
    int started = 0;
    for (int i = 31; i >= 0; --i) {
        for (int bit = 7; bit >= 0; --bit) {
            if (started) { ge t; ge_dbl(&t, &acc); acc = t; }
            unsigned ab = (a[i] >> bit) & 1u;
            unsigned bb = (b[i] >> bit) & 1u;
            if (ab) {
                if (started) { ge t; ge_add(&t, &acc, A); acc = t; }
                else { acc = *A; started = 1; }
            }
            if (bb) {
                if (started) { ge t; ge_add(&t, &acc, B); acc = t; }
                else { acc = *B; started = 1; }
            }
        }
    }
    if (!started) ge_zero(&acc);
    *r = acc;
}

/* ----------------------------------------------------------------------------
 * Scalar arithmetic mod L = 2^252 + 27742317777372353535851937790883648493.
 * ---------------------------------------------------------------------------- */
static const uint8_t L_bytes[32] = {
    0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
    0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10
};

/* Reduce 64-byte LE input modulo L. */
static void sc_reduce(uint8_t out[32], const uint8_t in[64]);
void iii_ed25519_sc_reduce(uint8_t out[32], const uint8_t in[64]) { sc_reduce(out, in); }
static void sc_reduce(uint8_t out[32], const uint8_t in[64]) {
    /* Convert to int64 limbs (we just use byte arithmetic). */
    /* Iteratively subtract L shifted by k bytes while r >= L<<k.  Simple,
     * O(n²) but correct.  Iterate shift from 32 down to 0. */
    uint8_t r[64]; memcpy(r, in, 64);
    for (int shift = 32; shift >= 0; --shift) {
        for (;;) {
            /* Compare r >= L << (shift*8): construct lhs = L<<shift in 64 bytes,
             * then compare from MSB. */
            int ge = 1;
            for (int i = 63; i >= 0; --i) {
                int li = i - shift;
                uint8_t lb = (li >= 0 && li < 32) ? L_bytes[li] : 0;
                if (r[i] != lb) { ge = (r[i] > lb); break; }
            }
            if (!ge) break;
            unsigned borrow = 0;
            for (int i = 0; i < 64; ++i) {
                int li = i - shift;
                int lb = (li >= 0 && li < 32) ? (int)L_bytes[li] : 0;
                int v = (int)r[i] - lb - (int)borrow;
                if (v < 0) { v += 256; borrow = 1; } else borrow = 0;
                r[i] = (uint8_t)v;
            }
        }
    }
    memcpy(out, r, 32);
}

/* out = a*b + c mod L */
static void sc_muladd(uint8_t out[32],
                      const uint8_t a[32],
                      const uint8_t b[32],
                      const uint8_t c[32]) {
    uint16_t prod[64] = {0};
    for (int i = 0; i < 32; ++i) {
        uint32_t carry = 0;
        for (int j = 0; j < 32; ++j) {
            uint32_t v = (uint32_t)prod[i + j] + (uint32_t)a[i] * b[j] + carry;
            prod[i + j] = (uint16_t)(v & 0xFFu);
            carry = v >> 8;
        }
        int k = i + 32;
        while (carry) {
            uint32_t v = prod[k] + carry;
            prod[k] = (uint16_t)(v & 0xFFu);
            carry = v >> 8;
            k++;
        }
    }
    /* Add c, zero-extended. */
    uint32_t carry = 0;
    for (int i = 0; i < 32; ++i) {
        uint32_t v = prod[i] + c[i] + carry;
        prod[i] = (uint16_t)(v & 0xFFu);
        carry = v >> 8;
    }
    for (int k = 32; carry; ++k) {
        uint32_t v = prod[k] + carry;
        prod[k] = (uint16_t)(v & 0xFFu);
        carry = v >> 8;
    }
    uint8_t buf[64];
    for (int i = 0; i < 64; ++i) buf[i] = (uint8_t)prod[i];
    sc_reduce(out, buf);
}

/* ----------------------------------------------------------------------------
 * Public API.
 * ---------------------------------------------------------------------------- */

void iii_ed25519_keygen(uint8_t pk[32], const uint8_t seed[32]) {
    uint8_t h[64];
    iii_sha512(seed, 32, h);
    h[0]  &= 248u;
    h[31] &= 127u;
    h[31] |= 64u;
    ge B, A;
    ge_basepoint(&B);
    ge_scalar_mul(&A, h, &B);
    ge_compress(pk, &A);
}

void iii_ed25519_sign(uint8_t sig[64],
                      const uint8_t *msg, size_t msglen,
                      const uint8_t pk[32], const uint8_t seed[32])
{
    uint8_t h[64], r_hash[64], k_hash[64];
    iii_sha512(seed, 32, h);
    uint8_t a[32]; memcpy(a, h, 32);
    a[0]  &= 248u; a[31] &= 127u; a[31] |= 64u;

    /* r = SHA-512(prefix || M) reduced mod L */
    iii_sha512_ctx_t c;
    iii_sha512_init(&c);
    iii_sha512_update(&c, h + 32, 32);
    iii_sha512_update(&c, msg, msglen);
    iii_sha512_final(&c, r_hash);
    uint8_t r_red[32]; sc_reduce(r_red, r_hash);

    /* R = r * B */
    ge B, R;
    ge_basepoint(&B);
    ge_scalar_mul(&R, r_red, &B);
    uint8_t R_packed[32]; ge_compress(R_packed, &R);

    /* k = SHA-512(R || A || M) reduced mod L */
    iii_sha512_init(&c);
    iii_sha512_update(&c, R_packed, 32);
    iii_sha512_update(&c, pk,        32);
    iii_sha512_update(&c, msg,       msglen);
    iii_sha512_final(&c, k_hash);
    uint8_t k_red[32]; sc_reduce(k_red, k_hash);

    /* S = (r + k * a) mod L */
    uint8_t S[32];
    sc_muladd(S, k_red, a, r_red);

    memcpy(sig,      R_packed, 32);
    memcpy(sig + 32, S,        32);
}

int iii_ed25519_verify(const uint8_t sig[64],
                       const uint8_t *msg, size_t msglen,
                       const uint8_t pk[32])
{
    /* S < L? */
    int ge_test = 1;
    for (int i = 31; i >= 0; --i) {
        if (sig[32 + i] != L_bytes[i]) { if (sig[32 + i] > L_bytes[i]) return -1; break; }
        if (i == 0) ge_test = 0;
    }
    (void)ge_test;

    /* Decode pk and R. */
    ge A; if (ge_decompress(&A, pk) != 0) return -1;
    ge R; if (ge_decompress(&R, sig) != 0) return -1;
    (void)R;

    /* k = SHA-512(R || A || M) reduced mod L */
    uint8_t k_hash[64], k_red[32];
    iii_sha512_ctx_t c;
    iii_sha512_init(&c);
    iii_sha512_update(&c, sig,  32);
    iii_sha512_update(&c, pk,   32);
    iii_sha512_update(&c, msg,  msglen);
    iii_sha512_final(&c, k_hash);
    sc_reduce(k_red, k_hash);

    /* Want: S * B = R + k * A.  Compute P = S*B - k*A and check encodes to R. */
    ge B, negA, P;
    ge_basepoint(&B);
    ge_neg(&negA, &A);
    ge_double_scalar_mul(&P, k_red, &negA, sig + 32, &B);

    uint8_t check[32];
    ge_compress(check, &P);
    return memcmp(check, sig, 32) == 0 ? 0 : -1;
}
