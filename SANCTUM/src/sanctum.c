/* ============================================================================
 * III-SANCTUM — sanctum.c
 *
 * The 8-step Sealed-Cycle Box, the Trinity admission, the 10 sealed slots,
 * the DRTM relaunch, the Phantom NVRAM (PFS), Phoenix bookmarks, CRCC key
 * export, chronos epoch advance, the compromise quote, and the §5.5
 * predictive-specialisation bookkeeping.
 * ============================================================================
 */
#include "sanctum_internal.h"
#include <stdlib.h>
#include <string.h>

/* ----------------------------------------------------------------------------
 * Names.
 * ---------------------------------------------------------------------------- */

const char *iii_sanctum_seal_name(iii_sanctum_seal_t s) {
    switch (s) {
        case III_SEAL_INVALID:           return "INVALID";
        case III_SEAL_DRTM_RELAUNCH:     return "drtm_relaunch";
        case III_SEAL_PFS_VAR_SET:       return "pfs_var_set";
        case III_SEAL_PFS_DENY_QUOTE:    return "pfs_deny_quote";
        case III_SEAL_CRCC_KEY_EXPORT:   return "crcc_key_export";
        case III_SEAL_PHOENIX_EMERGENCY: return "phoenix_emergency";
        case III_SEAL_CHRONOS_SET_EPOCH: return "chronos_set_epoch";
        case III_SEAL_COMPROMISE_QUOTE:  return "compromise_quote";
        case III_SEAL_PHOENIX_BOOKMARK:  return "phoenix_bookmark";
        case III_SEAL_COMPILE_MODULE:    return "compile_module";
        default:                         return "unknown";
    }
}

const char *iii_sanctum_step_kind_name(iii_sanctum_step_kind_t k) {
    switch (k) {
        case XII_STEP_KIND_SANCTUM_INVALID_REJECT:  return "sanctum-invalid-reject";
        case XII_STEP_KIND_DRTM_RELAUNCH:            return "drtm-relaunch";
        case XII_STEP_KIND_PFS_VAR_SET:              return "pfs-var-set";
        case XII_STEP_KIND_PFS_DENY_QUOTE:           return "pfs-deny-quote";
        case XII_STEP_KIND_CRCC_KEY_EXPORT:          return "crcc-key-export";
        case XII_STEP_KIND_PHOENIX_EMERGENCY:        return "phoenix-emergency";
        case XII_STEP_KIND_CHRONOS_SET_EPOCH:        return "chronos-set-epoch";
        case XII_STEP_KIND_COMPROMISE_QUOTE:         return "compromise-quote";
        case XII_STEP_KIND_PHOENIX_BOOKMARK:         return "phoenix-bookmark";
        case XII_STEP_KIND_SANCTUM_COMPILE_MODULE:   return "sanctum-compile-module";
        case XII_STEP_KIND_SANCTUM_INTENT_MINT:      return "sanctum-intent-mint";
        case XII_STEP_KIND_SANCTUM_GATE_ENTER:       return "sanctum-gate-enter";
        case XII_STEP_KIND_SANCTUM_PKRU_REWRITE:     return "sanctum-pkru-rewrite";
        case XII_STEP_KIND_SANCTUM_DISPATCH:         return "sanctum-dispatch";
        case XII_STEP_KIND_SANCTUM_BODY:             return "sanctum-body";
        case XII_STEP_KIND_SANCTUM_EXIT:             return "sanctum-exit";
        case XII_STEP_KIND_SANCTUM_TRINITY_REJECT:   return "sanctum-trinity-reject";
        case XII_STEP_KIND_SANCTUM_SPECIALIZE:       return "sanctum-specialize";
        case XII_STEP_KIND_SANCTUM_DESPECIALIZE:     return "sanctum-despecialize";
        default:                                     return "unknown";
    }
}

const char *iii_sanctum_box_step_name(iii_sanctum_box_step_t s) {
    switch (s) {
        case III_BOX_STEP_NONE:           return "none";
        case III_BOX_STEP_INTENT_MINT:    return "01-intent-mint";
        case III_BOX_STEP_LOAD_INTENT:    return "02-load-intent";
        case III_BOX_STEP_INTENT_WITNESS: return "03-intent-witness";
        case III_BOX_STEP_TRAMPOLINE:     return "04-trampoline";
        case III_BOX_STEP_PKRU_REWRITE:   return "05-pkru-rewrite";
        case III_BOX_STEP_DISPATCH:       return "06-dispatch";
        case III_BOX_STEP_BODY:           return "07-body";
        case III_BOX_STEP_EXIT:           return "08-exit";
        default:                          return "unknown";
    }
}

const char *iii_sanctum_status_name(iii_sanctum_status_t s) {
    switch (s) {
        case III_SANCTUM_OK:                  return "ok";
        case III_SANCTUM_E_INVALID_SEAL:      return "invalid-seal";
        case III_SANCTUM_E_TRINITY_REJECT:    return "trinity-reject";
        case III_SANCTUM_E_NOT_BOUND:         return "seal-not-bound";
        case III_SANCTUM_E_BODY_FAILED:       return "body-failed";
        case III_SANCTUM_E_FRAME_EXHAUSTED:   return "frame-exhausted";
        case III_SANCTUM_E_PFS_FULL:          return "pfs-full";
        case III_SANCTUM_E_PFS_DENIED:        return "pfs-denied";
        case III_SANCTUM_E_PFS_NOT_FOUND:     return "pfs-not-found";
        case III_SANCTUM_E_PHOENIX_FULL:      return "phoenix-full";
        case III_SANCTUM_E_RATE_CAP:          return "rate-cap";
        case III_SANCTUM_E_INVALID:           return "invalid";
        default:                              return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * §3 — Trinity admission.  All four conjuncts must be valid for admission.
 * ---------------------------------------------------------------------------- */

void iii_trinity_admit(const iii_trinity_admit_in_t *in,
                       iii_trinity_admit_out_t      *out)
{
    memset(out, 0, sizeof(*out));
    if (!in) { return; }
    out->rejected_intent         = !in->intent_valid;
    out->rejected_cap            = !in->cap_valid;
    out->rejected_causality      = !in->causality_valid;
    out->rejected_sanctum_state  = !in->sanctum_state_valid;

    if (in->intent_valid && in->cap_valid && in->causality_valid && in->sanctum_state_valid) {
        out->admitted = true;
        /* Convergence point = SHA-256 of the four conjuncts' identity bytes,
         * truncated to 64 bits. */
        uint8_t buf[32 + 8 + 16 + 8 + 8];
        memcpy(buf,        in->intent.operator_consent_mhash, 32);
        for (unsigned i = 0; i < 8; ++i) buf[32+i] = (uint8_t)(in->intent.cap_id >> (i*8));
        memcpy(buf + 40,   in->intent.causality_witness, 16);
        for (unsigned i = 0; i < 8; ++i) buf[56+i] = (uint8_t)(in->intent.sanctum_frame_id >> (i*8));
        for (unsigned i = 0; i < 8; ++i) buf[64+i] = (uint8_t)(in->convergence_hint >> (i*8));
        uint8_t h[32];
        iii_sha256(buf, sizeof(buf), h);
        out->convergence_point =
            ((uint64_t)h[0])       | ((uint64_t)h[1] << 8)  |
            ((uint64_t)h[2] << 16) | ((uint64_t)h[3] << 24) |
            ((uint64_t)h[4] << 32) | ((uint64_t)h[5] << 40) |
            ((uint64_t)h[6] << 48) | ((uint64_t)h[7] << 56);
    }
}

/* ----------------------------------------------------------------------------
 * Runtime lifecycle
 * ---------------------------------------------------------------------------- */

#define III_SANCTUM_QUOTE_INITIAL_CAP  64u

iii_sanctum_runtime_t *iii_sanctum_runtime_create(void) {
    iii_sanctum_runtime_t *rt = (iii_sanctum_runtime_t *)calloc(1, sizeof(*rt));
    if (!rt) return NULL;

    rt->quotes      = (iii_drtm_quote_t *)calloc(III_SANCTUM_QUOTE_INITIAL_CAP, sizeof(iii_drtm_quote_t));
    rt->quote_count = 0;
    rt->quote_cap   = III_SANCTUM_QUOTE_INITIAL_CAP;
    rt->pfs         = (iii_pfs_entry_t *)calloc(III_PFS_ENTRIES_MAX, sizeof(iii_pfs_entry_t));
    rt->phoenix     = (iii_phoenix_bookmark_t *)calloc(III_PHOENIX_MAX_BOOKMARKS, sizeof(iii_phoenix_bookmark_t));
    if (!rt->quotes || !rt->pfs || !rt->phoenix) {
        free(rt->quotes); free(rt->pfs); free(rt->phoenix); free(rt);
        return NULL;
    }
    rt->phoenix_next_id = 1;
    rt->next_frame_id   = 1;
    rt->epoch           = 0;

    /* Slot 0 is bound at create-time to the structural-guard reject body. */
    rt->seals[III_SEAL_INVALID].bound = true;
    rt->seals[III_SEAL_INVALID].fn    = NULL;  /* never called; iii_sanctum_call rejects directly */
    rt->seals[III_SEAL_INVALID].user  = NULL;

    /* Default master subkey from a fixed string — caller can supply via
     * drtm_relaunch which rotates the subkey. */
    iii_sha256("III-SANCTUM-MASTER-V1", 21, rt->master_subkey);

    /* Default silicon fingerprint — userland sanctum runtimes derive this
     * deterministically from a constant tag.  In Ring-2 deployments the
     * runtime overrides via iii_sanctum_runtime_set_fingerprint() with the
     * CPUID + DMI hash supplied by the PORTABILITY HAL. */
    iii_sha256("III-SILICON-FP", 14, rt->silicon_fingerprint);

    return rt;
}

void iii_sanctum_runtime_destroy(iii_sanctum_runtime_t *rt) {
    if (!rt) return;
    free(rt->quotes);
    free(rt->pfs);
    free(rt->phoenix);
    memset(rt, 0, sizeof(*rt));
    free(rt);
}

void iii_sanctum_runtime_set_fingerprint(iii_sanctum_runtime_t *rt,
                                         const uint8_t          fingerprint[32]) {
    if (!rt || !fingerprint) return;
    memcpy(rt->silicon_fingerprint, fingerprint, 32);
}

uint64_t iii_sanctum_runtime_call_count(const iii_sanctum_runtime_t *rt) {
    return rt ? rt->call_count : 0u;
}

bool iii_sanctum_runtime_bind_seal(iii_sanctum_runtime_t  *rt,
                                   iii_sanctum_seal_t      seal,
                                   iii_sanctum_seal_fn     fn,
                                   void                   *user)
{
    if (!rt || !fn) return false;
    if ((unsigned)seal >= XII_SANCTUM_SEAL_COUNT) return false;
    if (seal == III_SEAL_INVALID) return false;        /* §1.1 — slot 0 is reserved */
    if (rt->seals[seal].bound) return false;            /* TYPE-SEAL-002 collision  */
    rt->seals[seal].bound = true;
    rt->seals[seal].fn    = fn;
    rt->seals[seal].user  = user;
    return true;
}

/* ----------------------------------------------------------------------------
 * §2 — sealed dispatch.  Always executes the 8 box steps; the trace records
 * which executed; the trampoline's hardenings are recorded as flags.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_call(iii_sanctum_runtime_t            *rt,
                                      const iii_sanctum_call_request_t *req,
                                      iii_sanctum_call_trace_t         *out_trace)
{
    iii_sanctum_call_trace_t trace;
    memset(&trace, 0, sizeof(trace));
    if (out_trace) memset(out_trace, 0, sizeof(*out_trace));

    if (!rt || !req) return III_SANCTUM_E_INVALID;
    if ((unsigned)req->seal >= XII_SANCTUM_SEAL_COUNT) return III_SANCTUM_E_INVALID_SEAL;

    /* Slot 0 is the structural-guard — rejected immediately. */
    if (req->seal == III_SEAL_INVALID) {
        if (out_trace) *out_trace = trace;
        return III_SANCTUM_E_INVALID_SEAL;
    }

    if (!rt->seals[req->seal].bound) {
        if (out_trace) *out_trace = trace;
        return III_SANCTUM_E_NOT_BOUND;
    }

    /* Step 1 — mint intent token (callers supply it; we accept and trace). */
    trace.executed[III_BOX_STEP_INTENT_MINT] = true;

    /* Step 2 — load intent token into registers (modelled). */
    trace.executed[III_BOX_STEP_LOAD_INTENT] = true;

    /* Step 3 — emit intent-mint witness (modelled). */
    trace.executed[III_BOX_STEP_INTENT_WITNESS] = true;

    /* §3 — Trinity admission. */
    iii_trinity_admit_in_t  ti;
    memset(&ti, 0, sizeof(ti));
    ti.seal                 = req->seal;
    ti.intent               = req->intent;
    ti.intent_valid         = req->intent_valid;
    ti.cap_valid            = req->cap_valid;
    ti.causality_valid      = req->causality_valid;
    ti.sanctum_state_valid  = req->sanctum_state_valid;
    iii_trinity_admit(&ti, &trace.trinity);
    if (!trace.trinity.admitted) {
        if (out_trace) *out_trace = trace;
        return III_SANCTUM_E_TRINITY_REJECT;
    }

    /* Step 4 — trampoline hardening (IBPB + VERW + SSBD + RSP swap + GPR save). */
    trace.executed[III_BOX_STEP_TRAMPOLINE] = true;
    trace.hardening.ibpb_executed = true;
    trace.hardening.verw_executed = true;
    trace.hardening.ssbd_executed = true;
    trace.hardening.rsp_swapped   = true;
    trace.hardening.gpr_saved     = true;

    /* Step 5 — PKRU rewrite. */
    trace.executed[III_BOX_STEP_PKRU_REWRITE] = true;

    /* Step 6 — dispatch.  Look up the slot's body. */
    trace.executed[III_BOX_STEP_DISPATCH] = true;

    /* §5.5 — specialised path takes the same dispatch but is recorded so the
     * caller can verify hot-path use. */
    trace.specialized_path = rt->seals[req->seal].specialized;

    /* Step 7 — execute body. */
    trace.executed[III_BOX_STEP_BODY] = true;
    int body_rc = rt->seals[req->seal].fn(rt, req->args_in, req->args_out, rt->seals[req->seal].user);
    if (body_rc != 0) {
        /* Body failed — still emit Step 8 (exit) and unwind. */
        trace.executed[III_BOX_STEP_EXIT] = true;
        rt->seals[req->seal].call_count++;
        rt->call_count++;
        if (out_trace) *out_trace = trace;
        return III_SANCTUM_E_BODY_FAILED;
    }

    /* Step 8 — exit (PKRU restore, GPR restore, RSP swap-back, return). */
    trace.executed[III_BOX_STEP_EXIT] = true;

    rt->seals[req->seal].call_count++;
    rt->call_count++;
    if (out_trace) *out_trace = trace;
    return III_SANCTUM_OK;
}

/* ----------------------------------------------------------------------------
 * §4 — DRTM relaunch.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_drtm_relaunch(iii_sanctum_runtime_t *rt,
                                               bool                   promote_compiler,
                                               iii_drtm_quote_t      *out_quote)
{
    if (!rt) return III_SANCTUM_E_INVALID;

    /* Grow quote buffer if needed. */
    if (rt->quote_count >= rt->quote_cap) {
        size_t newcap = rt->quote_cap * 2u;
        iii_drtm_quote_t *nq = (iii_drtm_quote_t *)realloc(rt->quotes, newcap * sizeof(iii_drtm_quote_t));
        if (!nq) return III_SANCTUM_E_INVALID;
        rt->quotes    = nq;
        rt->quote_cap = newcap;
    }

    /* New epoch. */
    rt->epoch++;

    /* Recompute PFS mhash by SHA-256 of all (key, value) entries serialised. */
    uint8_t pfs_mhash[32];
    {
        uint8_t buf[III_PFS_ENTRIES_MAX * (III_PFS_KEY_MAX + III_PFS_VALUE_MAX + 9)];
        size_t  pos = 0;
        for (size_t i = 0; i < rt->pfs_count; ++i) {
            const iii_pfs_entry_t *e = &rt->pfs[i];
            size_t kl = strnlen(e->key, III_PFS_KEY_MAX);
            buf[pos++] = (uint8_t)kl;
            memcpy(buf + pos, e->key, kl);
            pos += kl;
            buf[pos++] = (uint8_t)(e->value_len);
            buf[pos++] = (uint8_t)(e->value_len >> 8);
            memcpy(buf + pos, e->value, e->value_len);
            pos += e->value_len;
            buf[pos++] = e->denied ? 1u : 0u;
        }
        iii_sha256(buf, pos, pfs_mhash);
    }

    iii_drtm_quote_t *q = &rt->quotes[rt->quote_count];
    memset(q, 0, sizeof(*q));
    memcpy(q->silicon_fingerprint,    rt->silicon_fingerprint,      32);
    memcpy(q->spec_root_R1,           rt->spec_root_R1,             32);
    memcpy(q->cycle_table_mhash,      rt->cycle_table_mhash,        32);
    memcpy(q->hexad_bitmap_mhash,     rt->hexad_bitmap_mhash,       32);
    memcpy(q->observatory_snapshot_mhash, rt->observatory_mhash,    32);
    memcpy(q->phantom_nvram_mhash,    pfs_mhash,                    32);
    memcpy(q->federation_members_mhash, rt->federation_members_mhash, 32);
    if (rt->quote_count > 0) {
        /* The prior quote's mhash is the SHA-256 of its bytes. */
        iii_sha256(&rt->quotes[rt->quote_count - 1], sizeof(iii_drtm_quote_t), q->prior_quote_mhash);
    }
    q->epoch = rt->epoch;
    rt->quote_count++;

    /* Rotate master subkey via HKDF with new epoch. */
    uint8_t info[16];
    memcpy(info, "epoch=", 6);
    for (unsigned i = 0; i < 8; ++i) info[6+i] = (uint8_t)(rt->epoch >> (i*8));
    iii_hkdf_sha256(rt->master_subkey, 32, NULL, 0, info, 14, rt->master_subkey, 32);

    /* §4 step 6 — promote compiler is a flag the caller can set; no real
     * effect at the modelling level beyond recording.  We could record this
     * in a separate field but for now we just note the call. */
    (void)promote_compiler;

    if (out_quote) *out_quote = *q;
    return III_SANCTUM_OK;
}

uint64_t iii_sanctum_runtime_epoch(const iii_sanctum_runtime_t *rt) {
    return rt ? rt->epoch : 0u;
}

size_t iii_sanctum_runtime_quote_count(const iii_sanctum_runtime_t *rt) {
    return rt ? rt->quote_count : 0u;
}

bool iii_sanctum_runtime_quote_at(const iii_sanctum_runtime_t *rt, size_t idx, iii_drtm_quote_t *out) {
    if (!rt || !out || idx >= rt->quote_count) return false;
    *out = rt->quotes[idx];
    return true;
}

/* ----------------------------------------------------------------------------
 * §1 slot 2/3 — Phantom NVRAM.
 * ---------------------------------------------------------------------------- */

static iii_pfs_entry_t *pfs_find(iii_sanctum_runtime_t *rt, const char *key) {
    for (size_t i = 0; i < rt->pfs_count; ++i) {
        if (strncmp(rt->pfs[i].key, key, III_PFS_KEY_MAX) == 0) return &rt->pfs[i];
    }
    return NULL;
}

iii_sanctum_status_t iii_sanctum_pfs_set(iii_sanctum_runtime_t *rt,
                                         const char            *key,
                                         const uint8_t         *value,
                                         size_t                 value_len)
{
    if (!rt || !key) return III_SANCTUM_E_INVALID;
    if (value_len > III_PFS_VALUE_MAX) return III_SANCTUM_E_INVALID;

    iii_pfs_entry_t *e = pfs_find(rt, key);
    if (e) {
        if (e->denied) return III_SANCTUM_E_PFS_DENIED;
    } else {
        if (rt->pfs_count >= III_PFS_ENTRIES_MAX) return III_SANCTUM_E_PFS_FULL;
        e = &rt->pfs[rt->pfs_count++];
        memset(e, 0, sizeof(*e));
        size_t kl = strnlen(key, III_PFS_KEY_MAX - 1u);
        memcpy(e->key, key, kl);
        e->key[kl] = '\0';
    }
    if (value && value_len > 0) memcpy(e->value, value, value_len);
    e->value_len = value_len;
    return III_SANCTUM_OK;
}

iii_sanctum_status_t iii_sanctum_pfs_get(iii_sanctum_runtime_t *rt,
                                         const char            *key,
                                         uint8_t               *out_value,
                                         size_t                 cap,
                                         size_t                *out_len)
{
    if (!rt || !key) return III_SANCTUM_E_INVALID;
    iii_pfs_entry_t *e = pfs_find(rt, key);
    if (!e) return III_SANCTUM_E_PFS_NOT_FOUND;
    if (e->denied) return III_SANCTUM_E_PFS_DENIED;
    size_t take = (e->value_len < cap) ? e->value_len : cap;
    if (out_value && take > 0) memcpy(out_value, e->value, take);
    if (out_len) *out_len = e->value_len;
    return III_SANCTUM_OK;
}

iii_sanctum_status_t iii_sanctum_pfs_deny(iii_sanctum_runtime_t *rt, const char *key) {
    if (!rt || !key) return III_SANCTUM_E_INVALID;
    iii_pfs_entry_t *e = pfs_find(rt, key);
    if (!e) {
        if (rt->pfs_count >= III_PFS_ENTRIES_MAX) return III_SANCTUM_E_PFS_FULL;
        e = &rt->pfs[rt->pfs_count++];
        memset(e, 0, sizeof(*e));
        size_t kl = strnlen(key, III_PFS_KEY_MAX - 1u);
        memcpy(e->key, key, kl);
        e->key[kl] = '\0';
    }
    e->denied = true;
    return III_SANCTUM_OK;
}

size_t iii_sanctum_runtime_pfs_count(const iii_sanctum_runtime_t *rt) {
    return rt ? rt->pfs_count : 0u;
}

/* ----------------------------------------------------------------------------
 * §1 slot 5/8 — Phoenix bookmarks.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_phoenix_save(iii_sanctum_runtime_t *rt,
                                              bool                   emergency,
                                              const uint8_t         *payload,
                                              size_t                 payload_len,
                                              uint64_t              *out_id)
{
    if (!rt) return III_SANCTUM_E_INVALID;
    if (payload_len > III_PHOENIX_PAYLOAD_MAX) return III_SANCTUM_E_INVALID;
    if (rt->phoenix_count >= III_PHOENIX_MAX_BOOKMARKS) return III_SANCTUM_E_PHOENIX_FULL;

    iii_phoenix_bookmark_t *b = &rt->phoenix[rt->phoenix_count++];
    memset(b, 0, sizeof(*b));
    b->bookmark_id = rt->phoenix_next_id++;
    b->epoch       = rt->epoch;
    b->emergency   = emergency;
    if (payload && payload_len > 0) memcpy(b->payload, payload, payload_len);
    b->payload_len = payload_len;

    /* mhash = SHA-256(id || epoch || emergency || payload) */
    uint8_t buf[8 + 8 + 1 + III_PHOENIX_PAYLOAD_MAX];
    for (unsigned i = 0; i < 8; ++i) buf[i]     = (uint8_t)(b->bookmark_id >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[8+i]   = (uint8_t)(b->epoch       >> (i*8));
    buf[16] = b->emergency ? 1u : 0u;
    if (b->payload_len > 0) memcpy(buf + 17, b->payload, b->payload_len);
    iii_sha256(buf, 17 + b->payload_len, b->mhash);

    if (out_id) *out_id = b->bookmark_id;
    return III_SANCTUM_OK;
}

iii_sanctum_status_t iii_sanctum_phoenix_restore(iii_sanctum_runtime_t *rt,
                                                 uint64_t               id,
                                                 iii_phoenix_bookmark_t *out)
{
    if (!rt || !out) return III_SANCTUM_E_INVALID;
    for (size_t i = 0; i < rt->phoenix_count; ++i) {
        if (rt->phoenix[i].bookmark_id == id) {
            *out = rt->phoenix[i];
            return III_SANCTUM_OK;
        }
    }
    return III_SANCTUM_E_INVALID;
}

size_t iii_sanctum_runtime_phoenix_count(const iii_sanctum_runtime_t *rt) {
    return rt ? rt->phoenix_count : 0u;
}

/* ----------------------------------------------------------------------------
 * §1 slot 4 — CRCC key export.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_crcc_export(iii_sanctum_runtime_t *rt,
                                             uint64_t               cycle_root_id,
                                             uint8_t                out_key[32])
{
    if (!rt || !out_key) return III_SANCTUM_E_INVALID;
    uint8_t info[16];
    memcpy(info, "crcc=", 5);
    for (unsigned i = 0; i < 8; ++i) info[5+i] = (uint8_t)(cycle_root_id >> (i*8));
    iii_hkdf_sha256(rt->master_subkey, 32, NULL, 0, info, 13, out_key, 32);
    return III_SANCTUM_OK;
}

/* ----------------------------------------------------------------------------
 * §1 slot 6 — chronos epoch advance.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_chronos_advance(iii_sanctum_runtime_t *rt) {
    if (!rt) return III_SANCTUM_E_INVALID;
    rt->epoch++;
    return III_SANCTUM_OK;
}

/* ----------------------------------------------------------------------------
 * §1 slot 7 — compromise quote.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_compromise_quote(iii_sanctum_runtime_t *rt,
                                                  uint16_t               tier,
                                                  const uint8_t         *evidence,
                                                  size_t                 evidence_len,
                                                  iii_drtm_quote_t      *out_quote)
{
    if (!rt || !out_quote) return III_SANCTUM_E_INVALID;
    if (tier == 0 || tier > 3) return III_SANCTUM_E_INVALID;

    /* Build a quote whose pad encodes (tier || sha256(evidence)). */
    iii_sanctum_status_t st = iii_sanctum_drtm_relaunch(rt, false, out_quote);
    if (st != III_SANCTUM_OK) return st;

    out_quote->pad[0] = (uint8_t)tier;
    out_quote->pad[1] = (uint8_t)(tier >> 8);
    if (evidence && evidence_len > 0) {
        uint8_t h[32];
        iii_sha256(evidence, evidence_len, h);
        memcpy(out_quote->pad + 2, h, 32);
    }
    return III_SANCTUM_OK;
}

/* ----------------------------------------------------------------------------
 * §5.5 — specialisation.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_specialize(iii_sanctum_runtime_t *rt, iii_sanctum_seal_t seal) {
    if (!rt) return III_SANCTUM_E_INVALID;
    if ((unsigned)seal >= XII_SANCTUM_SEAL_COUNT) return III_SANCTUM_E_INVALID_SEAL;
    if (seal == III_SEAL_INVALID) return III_SANCTUM_E_INVALID_SEAL;
    if (!rt->seals[seal].bound) return III_SANCTUM_E_NOT_BOUND;
    rt->seals[seal].specialized = true;
    return III_SANCTUM_OK;
}

iii_sanctum_status_t iii_sanctum_despecialize(iii_sanctum_runtime_t *rt, iii_sanctum_seal_t seal) {
    if (!rt) return III_SANCTUM_E_INVALID;
    if ((unsigned)seal >= XII_SANCTUM_SEAL_COUNT) return III_SANCTUM_E_INVALID_SEAL;
    if (seal == III_SEAL_INVALID) return III_SANCTUM_E_INVALID_SEAL;
    if (!rt->seals[seal].bound) return III_SANCTUM_E_NOT_BOUND;
    rt->seals[seal].specialized = false;
    return III_SANCTUM_OK;
}

bool iii_sanctum_is_specialized(const iii_sanctum_runtime_t *rt, iii_sanctum_seal_t seal) {
    if (!rt) return false;
    if ((unsigned)seal >= XII_SANCTUM_SEAL_COUNT) return false;
    return rt->seals[seal].specialized;
}
