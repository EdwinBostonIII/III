# ADR-RES-013 — Witness Format For Resolution

## Status

FROZEN.

## Context

The witness chain (existing 56-byte entry per `sanctus/witness.iii`) is shared across all III subsystems. Resolution outcomes need domain-separation so an auditor can identify the outcome class by inspecting the mhash inputs.

## Decision

Five mhash domain strings (FROZEN SPEC §0.10), each exactly 16 bytes (NUL-padded as needed):

| Domain | Hex bytes | Outcome |
|--------|-----------|---------|
| `DOM_RESOLVE_OK` | 49 49 49 5F 52 45 53 4F 4C 56 45 5F 4F 4B 00 00 | Successful dispatch |
| `DOM_RESOLVE_FAIL` | 49 49 49 5F 52 45 53 4F 4C 56 45 5F 46 41 49 4C | No-match / unify-fail / dispatch-fault / cap-denied / etc. |
| `DOM_RESOLVE_AMBIG` | 49 49 49 5F 52 45 53 4F 4C 56 45 5F 41 4D 42 47 | Persistent ambiguity (registry corruption) |
| `DOM_RESOLVE_KUF` | 49 49 49 5F 52 45 53 4F 4C 56 45 5F 4B 55 46 00 | K-chain underflow |
| `DOM_RESOLVE_TAMPER` | 49 49 49 5F 52 45 53 4F 4C 56 45 5F 54 41 4D 50 | Set/intent/ctx tamper detection |

Domain strings are inputs to SHA-256 in `sanctus_mhash_compose5`.

### Witness Entry Structure

The existing 56-byte entry (mhash[32], cap_id:u64, epoch:u64, k_fixed:u64) is unchanged. The mhash field is computed per the table above with payload shapes per §8.1:

```
OK:     mhash = SHA256( DOM_RESOLVE_OK || pattern_id_le8 || intent_id_le8 || ctx_digest_32 || binding_digest_32 || score_le4 )
FAIL:   mhash = SHA256( DOM_RESOLVE_FAIL || intent_id_le8 || ctx_digest_32 || failure_code_le4 || candidate_count_le4 )
AMBIG:  mhash = SHA256( DOM_RESOLVE_AMBIG || intent_id_le8 || ctx_digest_32 || a_id_le8 || b_id_le8 || score_le4 )
KUF:    mhash = SHA256( DOM_RESOLVE_KUF || pattern_id_le8 || intent_id_le8 || k_pre_le8 || k_post_le8 || floor_le8 )
TAMPER: mhash = SHA256( DOM_RESOLVE_TAMPER || which_le1 || id_le8 || expected_mhash_32 || observed_mhash_32 )
```

5 shapes. No 6th.

### Side-Channel For Replay

A side-table (`replay_side_table_*` accessors in `omnia/resolver_replay.iii`) holds the inputs needed to recompute each OK witness mhash. Side-table entries are written by `witness_append_resolution()` during normal `resolve()` calls; readable by the replay tool only.

The recursion_depth side-channel uses the high 16 bits of the `epoch` slot in `call_context_t` — documented exception to "no spare bits". This is an ergonomic choice: the depth fits, the epoch field has no other use within the resolver, and storing it elsewhere would require extending the layout.

## Consequences

- Auditor identifies outcome class by recomputing the hash with each candidate domain.
- Five distinct hash inputs prevent collision across outcome categories.
- Replay reproduces every OK witness from recorded inputs.

## Alternatives Refused

### Single Domain With Sub-Tag In Payload

Refused: sub-tags in the payload would conflict with future field additions; explicit domain separation is robust.

### Six Or More Domains (one per error code)

Refused per HC-1 #14 (closed set). Five suffice for the outcome categories defined.

### No Domain Separation; Pure Hash Of Concatenated Fields

Refused: SHA-256 is a domain-extension family; without a domain, two inputs producing the same hash byte-pattern (low probability but non-zero) would be ambiguous.

## Audit

- §0.10 carries the byte values verbatim.
- §8.1 carries the payload shapes.
- §Z.C.2 (resolver.iii) carries the constants verbatim.
- §V.G0009 verifies forbidden-vocabulary lint includes the domain strings as exempt.

## Lineage

Authored: step R0013 of §I. Closed.
