/* ============================================================================
 * III-CYCLES — witness.c
 *
 * §4 of III-CYCLES.md.  The XiiWitness is a 128-byte struct.  For every
 * cycle invocation the runtime executes the 8-step emission protocol:
 *
 *   1. Capture predecessor mhash from per-CPU chain head.
 *   2. Compute step_kind from registered XII_STEP_KIND_*.
 *   3. Fill the struct (predecessor, zeroed successor slot, fields).
 *   4. BLAKE3 over the 128-byte struct (successor field zeroed during hash).
 *   5. HMAC-SHA-256 over BLAKE3 hash with per-CPU sub-key → successor mhash.
 *   6. Write successor into struct.
 *   7. Append to per-CPU forward+inverse rings (BCWL-indexed via bcwl.c).
 *   8. Atomic update of chain head; emit to audit spine on commit boundary.
 *
 * The 128-byte layout is byte-exact per spec §4.1; we serialise to LE for
 * the embedded fields except the two 32-byte mhashes which are raw bytes.
 * ============================================================================
 */
#include "cycles_internal.h"
#include <stdlib.h>
#include <string.h>

struct iii_witness_emitter {
    uint32_t cpu_id;
    uint32_t cycle_seq;
    uint8_t  chain_head[32];
    uint8_t  subkey[32];
    bool     subkey_set;
    uint64_t emit_count;
    /* The forward and inverse rings live in the BCWL; we don't duplicate them
     * here.  Tests can register a BCWL via the public emit functions. */
};

iii_witness_emitter_t *iii_witness_emitter_create(uint32_t cpu_id) {
    iii_witness_emitter_t *e = (iii_witness_emitter_t *)calloc(1, sizeof(*e));
    if (!e) return NULL;
    e->cpu_id     = cpu_id;
    e->cycle_seq  = 0;
    e->emit_count = 0;
    /* Default subkey from a derivation of cpu_id (deterministic, for tests). */
    iii_witness_derive_subkey((const uint8_t *)"III-DEFAULT-MASTER-KEY-32-BYTES!", cpu_id, 0, e->subkey);
    e->subkey_set = true;
    return e;
}

void iii_witness_emitter_destroy(iii_witness_emitter_t *e) {
    if (!e) return;
    memset(e, 0, sizeof(*e));
    free(e);
}

void iii_witness_emitter_set_subkey(iii_witness_emitter_t *e,
                                    const uint8_t          subkey[32])
{
    if (!e) return;
    memcpy(e->subkey, subkey, 32);
    e->subkey_set = true;
}

uint64_t iii_witness_emitter_count(const iii_witness_emitter_t *e) {
    return e ? e->emit_count : 0u;
}

/* §4.4 — HKDF-SHA-256 sub-key derivation.
 *   sub_key[cpu] = HKDF-SHA256(
 *       master = sanctum_master_key,
 *       salt   = "III-WITNESS-CHAIN-V1",
 *       info   = "cpu=" || cpu_id || ",epoch=" || current_epoch
 *   )
 */
void iii_witness_derive_subkey(const uint8_t  master[32],
                               uint32_t       cpu_id,
                               uint64_t       epoch,
                               uint8_t        out_subkey[32])
{
    static const uint8_t salt[] = "III-WITNESS-CHAIN-V1";
    /* info encoding: "cpu=<le-bytes>,epoch=<le-bytes>" */
    uint8_t info[5 + 4 + 7 + 8];
    memcpy(info, "cpu=", 4);                    /* 0..3 */
    info[4] = (uint8_t)(cpu_id);
    info[5] = (uint8_t)(cpu_id >> 8);
    info[6] = (uint8_t)(cpu_id >> 16);
    info[7] = (uint8_t)(cpu_id >> 24);
    memcpy(info + 8, ",epoch=", 7);              /* 8..14 */
    for (unsigned i = 0; i < 8; ++i) info[15 + i] = (uint8_t)(epoch >> (i * 8));

    iii_hkdf_sha256(master, 32,
                    salt, sizeof(salt) - 1,
                    info, sizeof(info),
                    out_subkey, 32);
}

/* Serialise the 128-byte XiiWitness into a buffer for hashing. */
static void serialise_witness(const iii_xii_witness_t *w, uint8_t buf[128]) {
    memcpy(buf,        w->predecessor_mhash, 32);
    memcpy(buf + 0x20, w->successor_mhash,   32);

    /* Little-endian for embedded fields. */
    buf[0x40] = (uint8_t)(w->step_kind);
    buf[0x41] = (uint8_t)(w->step_kind >> 8);
    buf[0x42] = (uint8_t)(w->step_kind >> 16);
    buf[0x43] = (uint8_t)(w->step_kind >> 24);

    buf[0x44] = (uint8_t)(w->cycle_seq);
    buf[0x45] = (uint8_t)(w->cycle_seq >> 8);
    buf[0x46] = (uint8_t)(w->cycle_seq >> 16);
    buf[0x47] = (uint8_t)(w->cycle_seq >> 24);

    for (unsigned i = 0; i < 8; ++i) buf[0x48 + i] = (uint8_t)(w->chronos_tsc >> (i * 8));

    for (unsigned i = 0; i < 4; ++i) buf[0x50 + i] = (uint8_t)(w->cost_q14            >> (i * 8));
    for (unsigned i = 0; i < 4; ++i) buf[0x54 + i] = (uint8_t)(w->capability_bind     >> (i * 8));
    for (unsigned i = 0; i < 4; ++i) buf[0x58 + i] = (uint8_t)(w->adversariality_class>> (i * 8));
    for (unsigned i = 0; i < 4; ++i) buf[0x5C + i] = (uint8_t)(w->federation_route    >> (i * 8));
    for (unsigned i = 0; i < 4; ++i) buf[0x60 + i] = (uint8_t)(w->plan_anchor_id      >> (i * 8));
    for (unsigned i = 0; i < 4; ++i) buf[0x64 + i] = (uint8_t)(w->flags               >> (i * 8));

    buf[0x68] = (uint8_t)(w->hexad_packed);
    buf[0x69] = (uint8_t)(w->hexad_packed >> 8);

    memcpy(buf + 0x6A, w->hmac_tail, 22);
}

void iii_witness_emit(iii_witness_emitter_t       *e,
                      const iii_witness_request_t *req,
                      iii_xii_witness_t           *out)
{
    if (!e || !req || !out) return;

    /* Step 1 — capture predecessor. */
    memcpy(out->predecessor_mhash, e->chain_head, 32);

    /* Step 2 — step_kind. */
    out->step_kind = (uint32_t)req->step_kind;

    /* Step 3 — fill the struct; successor mhash slot left zeroed for Step 4 BLAKE3. */
    e->cycle_seq++;
    out->cycle_seq            = e->cycle_seq;
    out->chronos_tsc          = req->chronos_tsc;
    out->cost_q14             = req->cost_q14;
    out->capability_bind      = req->capability_bind;
    out->adversariality_class = req->adversariality_class;
    out->federation_route     = req->federation_route;
    out->plan_anchor_id       = req->plan_anchor_id;
    out->flags                = req->flags;
    out->hexad_packed         = req->hexad_packed;
    memset(out->hmac_tail,        0, 22);
    memset(out->successor_mhash,  0, 32);

    /* Step 4 — BLAKE3 over the 128-byte struct (successor zeroed). */
    uint8_t buf[128];
    serialise_witness(out, buf);
    uint8_t blake[32];
    iii_blake3(buf, 128, blake);

    /* Step 5 — HMAC-SHA-256 over BLAKE3 hash with sub-key → successor. */
    uint8_t hmac[32];
    iii_hmac_sha256(e->subkey, 32, blake, 32, hmac);

    /* Step 6 — write successor into the struct. */
    memcpy(out->successor_mhash, hmac, 32);
    memcpy(out->hmac_tail,       hmac + 10, 22); /* tail bytes for fast verify */

    /* Step 7 — caller wires this into the BCWL. */
    /* Step 8 — atomic update of chain head. */
    memcpy(e->chain_head, out->successor_mhash, 32);
    e->emit_count++;
}

void iii_witness_emit_inverse(iii_witness_emitter_t       *e,
                              const iii_xii_witness_t     *forward,
                              uint16_t                     inverse_step_kind,
                              iii_xii_witness_t           *out)
{
    if (!e || !forward || !out) return;
    iii_witness_request_t r;
    memset(&r, 0, sizeof(r));
    r.step_kind            = inverse_step_kind;
    r.chronos_tsc          = forward->chronos_tsc;
    r.cost_q14             = forward->cost_q14;
    r.capability_bind      = forward->capability_bind;
    r.adversariality_class = forward->adversariality_class;
    r.federation_route     = forward->federation_route;
    r.plan_anchor_id       = forward->plan_anchor_id;
    r.flags                = forward->flags;
    r.hexad_packed         = forward->hexad_packed;
    iii_witness_emit(e, &r, out);
}
