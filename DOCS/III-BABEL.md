# III-BABEL — Cross-Process Intent Transport

**Status: FROZEN.** Part of FROZEN SPECIFICATION III-RES-FROZEN-001 (§11). Cross-reference: ADR-RES-007.

## 1. Concept

A **Babel envelope** is a self-describing document carrying an intent crystal, optional payload, and the metadata necessary to **resolve** the intent on the receiver. Babel is the natural application of the resolver foundation: once `pattern`/`intent`/`resolve` exist, transmitting them across processes is a thin codec.

Two equivalent serialisations: JSON (human-readable), CBOR (binary-efficient). Round-trips bit-equal via slots 21/22 with a verified equivalence cert.

## 2. JSON Envelope Schema

```json
{
  "babel_version":   1,
  "domain":          "<utf8 ≤ 64 bytes>",
  "intent_crystal":  {
    "id":         "<hex16>",
    "site_hash":  "<hex64>",
    "cap_id":     "<hex16>",
    "cause":      "<hex16>",
    "k_fixed":    "<u64-as-decimal-string>",
    "msg_hash":   "<hex64>",
    "mac":        "<hex32>"
  },
  "intent": {
    "goal_kind":             "<u8-as-decimal-string>",
    "partial_args":          ["<u64-decimal>", ...],
    "required_guarantees":   "<u32-decimal>",
    "expected_hexad_kind":   "<u8-decimal>",
    "arena_intent":          "<hex16>"
  },
  "payload_form":    "<u32-decimal>",
  "payload_bytes":   "<base64>",
  "provenance_root": "<hex64>",
  "send_epoch":      "<u64-decimal>",
  "envelope_mhash":  "<hex64>"
}
```

`babel_version = 1`. There is no version 2 in this spec.

## 3. CBOR Form

Same field names, same field shapes, CBOR-encoded. Round-trips with JSON via the equivalence cert minted at boot for slots 21 (`tp_babel_cbor_json`) and 22 (`tp_babel_json_cbor`).

## 4. Envelope mhash

Domain `"BABEL_ENV_V1\0\0\0\0"` (16 bytes, NUL-padded). Hash covers all fields except `envelope_mhash` itself, in byte-stable JSON ordering (sorted lexicographically by field name).

## 5. HTTP Transport

Optional header `X-III-Intent-Crystal: <hex16>` carries a 64-bit intent_crystal_id. When the body is a Babel envelope, content-type is `application/x-iii-babel+json` or `application/x-iii-babel+cbor`.

## 6. Receiver Protocol

```
1. Receive bytes.
2. transform(<receiver-form>, FORM_BABEL_JSON, bytes, ctx).
3. Verify envelope_mhash.
4. Reconstitute crystal locally; mac is provenance-only across processes.
5. resolve() on receiver's local registry.
6. Encode response envelope.
```

### Cross-Process MAC

The crystal MAC is HMAC-SHA256 over the body using a **per-process sealed sub-key**. Sender and receiver have different sub-keys, so the MAC fails on the receiver. This is documented design:

- Receivers MUST verify `envelope_mhash` (covers crystal contents).
- Receivers MUST NOT trust the MAC for authority decisions.
- Receivers treat the crystal as **provenance-only** (advisory information about origin).

To grant authority across processes, the federation must arrange for a shared seal — out of scope for this spec.

## 7. Capabilities

Senders need `CAP_RIGHT_TRANSFORM_RUN` (§0.9). Receivers need `CAP_RIGHT_RESOLVE_INVOKE` to dispatch on the local registry. Without these, the operations refuse.

## 8. Domains

The `domain` field in the envelope namespaces intents to prevent cross-application collision. Examples:

- `iii.codegen.lower_call`
- `iii.transform.bulk_convert`
- `iii.audit.replay`
- `<vendor>.<app>.<intent>`

A receiver may filter the registry by domain via `pattern_set_filter_by_domain(global_set, "iii.codegen.*")`. Filtering is itself a deterministic function — no learning, no telemetry.

## 9. End-To-End Example

```
Process A:
  1. Build intent_t* via intent_new(INTENT_FORM); set fields.
  2. Mint local crystal_id via crystal_mint(...).
  3. babel_encode_json(intent, crystal_id, dst_buf, dst_cap) → bytes.
  4. HTTP POST with body and X-III-Intent-Crystal header.

Process B:
  1. Receive HTTP request.
  2. Parse body via transform(FORM_RAW_BIN, FORM_BABEL_JSON, ...).
  3. Extract intent_t and crystal fields.
  4. Verify envelope_mhash; reject if mismatch.
  5. Reconstitute local intent_ptr via babel_intent_receive(...).
  6. resolve(g_pattern_set, intent_ptr, ctx) → result.
  7. Encode response envelope; send back.

Process A:
  8. Receive response.
  9. Decode; extract result.
  10. Witness chains on both sides record the exchange.
```

## 10. Verification

- Corpus 55 (round-trip): JSON → bytes → JSON byte-equal.
- Corpus 56 (HTTP extraction): client sets header, server reads header back.
- Corpus 57 (mhash stability): two encodes of same intent → same envelope_mhash.
- Corpus 58 (unknown version): receiver rejects envelope with `babel_version: 2`.
- §V.B0014 (end-to-end two-process): both sides' witness mhashes match.

## 11. Cross-Reference

- ADR-RES-007 (rationale).
- FROZEN SPEC §11 (envelope spec).
- FROZEN SPEC §Z.C.11.full (codec source).
- FROZEN SPEC §Z.C.12.full (intent binding source).
