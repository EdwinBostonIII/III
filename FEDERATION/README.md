# III-FEDERATION — Tier-Gated Outbound & Replication

**Doc-ID:** B2 / R1.B2
**Spec:** `DOCS/III-FEDERATION.md`

Tier model (transient < host_file < federation < constitutional), tier-gated
outbound (effective tier = MIN of all contributing module tiers), quorum
specifications (3/2, 5/3, unanimous), peer table with DRTM-rooted federation
keys, fusion-tier rule.

## Test

```
$ ./build/iii_federation_test
=== 29 passed, 0 failed ===
```

## Conformance (§7)

| Code | Status |
| --- | --- |
| C-FED-1 | ✅ tier-gated outbound: transient effective tier = REJECT_TIER0 |
| C-FED-2 | ✅ cross-tier fusion sets `requires_amend=true` |
| C-FED-3 | ✅ quorum signature presence checked (zero signature rejects) |
| C-FED-5 | ✅ unanimous quorum requires every live peer's agreement |
