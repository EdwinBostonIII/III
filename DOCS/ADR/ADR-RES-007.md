# ADR-RES-007 — Babel Envelope Format

## Status

FROZEN.

## Context

Cross-process intent transport requires a stable, self-describing envelope. The user's binding directive states "every packet is a babel_file or carries an intent crystal" — Babel is the natural application of the resolver foundation.

## Decision

Two equivalent serialisations:

### JSON Form

12 top-level fields (§11.1):

```json
{
  "babel_version":   1,
  "domain":          "<utf8 ≤ 64 bytes>",
  "intent_crystal":  { "id": "...", "site_hash": "...", "cap_id": "...", "cause": "...", "k_fixed": "...", "msg_hash": "...", "mac": "..." },
  "intent":          { "goal_kind": "...", "partial_args": [...], "required_guarantees": "...", "expected_hexad_kind": "...", "arena_intent": "..." },
  "payload_form":    "<u32-decimal>",
  "payload_bytes":   "<base64>",
  "provenance_root": "<hex64>",
  "send_epoch":      "<u64-decimal>",
  "envelope_mhash":  "<hex64>"
}
```

`babel_version = 1`. There is no version 2.

### CBOR Form

Same field names, same field shapes, CBOR-encoded for efficiency. Round-trips with JSON via slots 21/22 (`tp_babel_cbor_json`/`tp_babel_json_cbor`) with verified equivalence cert.

## Envelope mhash

Domain `"BABEL_ENV_V1"` (16 bytes, NUL-padded). Hash covers all fields except `envelope_mhash` itself, in byte-stable JSON ordering (sorted lexicographically by field name).

## Receiver Protocol

1. Receive bytes.
2. `transform(<receiver-form>, FORM_BABEL_JSON, bytes, ctx)`.
3. Verify `envelope_mhash`.
4. Reconstitute crystal locally; mac is provenance-only across processes (sealed sub-key differs).
5. `resolve()` on receiver's local registry.
6. Encode response envelope.

## Consequences

- Receiver verifies envelope before acting; tampering caught at step 3.
- Cross-process MAC mismatch is documented design (§11.3 step 4): receivers treat the crystal as advisory, NOT authority.
- The format is byte-stable; same Babel envelope produces same `envelope_mhash` on every host.

## Alternatives Refused

### Protocol Buffers

Refused per HC-3 (no third-party deps).

### Free-Form Text

Refused: not deterministically hashable across implementations.

### Binary-Only

Refused: JSON is human-readable for forensics; CBOR exists for efficiency where size matters. Both are required.

### Multi-Version Support

Refused per HC-1 #14 (no future patterns/transforms). `babel_version = 1` forever in this spec.

## Audit

- §11 carries the envelope spec.
- §Z.C.11.full carries the codec source.
- Corpus 55–58 verify round-trip and rejection of unknown versions.

## Lineage

Authored: step R0007 of §I. Closed.
