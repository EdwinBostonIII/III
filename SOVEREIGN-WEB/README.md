# III-SOVEREIGN-WEB — Federation as Network Protocol

**Spec:** `DOCS/III-SOVEREIGN-WEB.md` (Wave 7, items 54-62)

IOMMU-mediated transport, witness-tagged packets (IPv4 option 0xCC / IPv6
hop-by-hop), AH-trailer (RFC 4302) with HMAC-SHA-256, replay window,
peer registration / discovery, Trinity-tier outbound, NDIS-style
passthrough for non-witness packets, cross-peer chain replication, and a
network cap discipline.

## Test

```
$ ./build/iii_sovereign_web_test
=== 24 passed, 0 failed ===
```

## Conformance (§10)

| Code | Status |
| --- | --- |
| C-SW-1 | ✅ option-type 0xCC, length 35 binds 32-byte witness mhash |
| C-SW-2 | ✅ AH HMAC-SHA-256 over body || mhash || src || dst || ts |
| C-SW-3 | ✅ replay window 64-slot bitmap |
| C-SW-4 | ✅ outbound rejects tier-0 with REJECT_TIER0 |
| C-SW-5 | ✅ inbound dispatcher: NON_III / VALID / INVALID_AH / REPLAY |
| C-SW-6 | ✅ replicate rejects non-monotonic witness sequences |
| C-SW-7 | ✅ AH SPI carries suite identifier in high byte (PRE_QUANTUM/PQC/HYBRID) |
