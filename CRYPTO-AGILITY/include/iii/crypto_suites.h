/* Suite identifiers for III crypto agility (DOCS/III-CRYPTO-AGILITY.md §4). */
#ifndef III_CRYPTO_SUITES_H
#define III_CRYPTO_SUITES_H
#include <stdint.h>

typedef uint64_t iii_suite_id_t;

/* Catalogue suite-class field (bits 0..15). Concrete primitive suites get
 * their own suite_id values used at the API surface; the catalogue rows
 * (0x0001/0x0100/0x0200/0x0300) are composites described in spec §3. */
enum {
    /* Classical / pre-quantum */
    III_SUITE_AES_256_GCM        = 0x0001,
    III_SUITE_CHACHA20_POLY1305  = 0x0002,
    III_SUITE_ED25519            = 0x0003,
    III_SUITE_X25519             = 0x0004,
    III_SUITE_ECDSA_P256         = 0x0005,
    III_SUITE_ECDSA_P384         = 0x0006,
    III_SUITE_RSA_3072           = 0x0007,
    III_SUITE_RSA_4096           = 0x0008,

    /* Post-quantum KEM (FIPS 203 ML-KEM, formerly Kyber) */
    III_SUITE_ML_KEM_512         = 0x0101,
    III_SUITE_ML_KEM_768         = 0x0102,
    III_SUITE_ML_KEM_1024        = 0x0103,

    /* Post-quantum Sign (FIPS 204 ML-DSA, formerly Dilithium) */
    III_SUITE_ML_DSA_44          = 0x0111,
    III_SUITE_ML_DSA_65          = 0x0112,
    III_SUITE_ML_DSA_87          = 0x0113,

    /* Post-quantum Sign (FIPS 205 SLH-DSA, formerly SPHINCS+) */
    III_SUITE_SLH_DSA_128S       = 0x0121,
    III_SUITE_SLH_DSA_192S       = 0x0122,
    III_SUITE_SLH_DSA_256S       = 0x0123,

    /* Composite catalogue rows from spec §3 */
    III_SUITE_CATALOGUE_PREQ     = 0x0001,
    III_SUITE_CATALOGUE_PQ_STRONG = 0x0100,
    III_SUITE_CATALOGUE_PQ_LIGHT  = 0x0200,
    III_SUITE_CATALOGUE_HYBRID    = 0x0300
};

#endif
