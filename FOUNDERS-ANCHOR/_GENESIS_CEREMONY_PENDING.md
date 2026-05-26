# FOUNDERS-ANCHOR — Genesis Ceremony PENDING

**Status:** the Founders-Anchor (logical ring R-3, the Skynet-prevention root of
trust) carries **intentional fail-loud placeholders** until the air-gapped
genesis ceremony is performed. This file documents them so they are never
mistaken for real key material. (RITCHIE Convergence Stage 1.17.)

## The two placeholders

| Artifact | Current state | Why |
|---|---|---|
| `III_FOUNDERS_ANCHOR_PUBLIC_KEY_DEFAULT[32]` (`src/founders_anchor.c:17-21`) | **all `0xCC` bytes** | A deliberately invalid Ed25519 public key. Any real verification against it fails loudly — the substrate cannot accidentally accept a forged Founders cosignature against a placeholder anchor. |
| `anchor_seed.TESTONLY.bin` (64 bytes) | **ASCII tombstone** (not real entropy) | A non-secret stand-in so test code has a file to open; the `.TESTONLY.` infix marks it as never-production. The real seed is generated air-gapped and **never committed**. |

## Why they are placeholders (not bugs)

The Founders-Anchor public key and seed are **constitutional key material**.
They cannot be invented by a coding step — they must be produced by the
**air-gapped genesis ceremony** (a once-in-a-substrate-lifetime event) on a
device with no network and no shared storage, with the seed carried only on
physical media. Committing a real key into source, or generating one in an
ordinary build, would defeat the entire R-3 root-of-trust model.

Per Contract C4 (no placeholders in source unless they are fail-loud and
documented): these are fail-loud (`0xCC` verification always fails;
`.TESTONLY.` is explicit) and now documented here.

## When they are replaced

| Step | Action |
|---|---|
| **RITCHIE Stage 6.1** | Define the air-gapped XII-ζ Ω1..Ω12 ceremony procedure (`DOCS/XII-CEREMONY-PROCEDURE.md`). |
| **RITCHIE Stage 6.2 / 10.1–10.3** | Operator generates the real entropy seed air-gapped, derives the Ed25519 pubkey, commits **only** `anchor_pubkey.bin` (32 bytes) + updates `III_FOUNDERS_ANCHOR_PUBLIC_KEY_DEFAULT`. The seed stays off-device. |
| **RITCHIE Stage 10.4–10.8** | Full ceremony + final XII_R1 seal. |

Until then, the `0xCC` pubkey and `.TESTONLY.` seed are the correct, intended,
fail-loud state.

## Pointers

| To learn… | Read |
|---|---|
| …the ceremony procedure | `DOCS/CONVERGENCE-AUDIT.md` Stage 6.1 / 10 (when written) |
| …the R-3 anchor model | `DOCS/III-FOUNDERS-ANCHOR.md` (D5) |
| …the amend/cosign surface | `FOUNDERS-ANCHOR/src/founders_anchor.c` |
