# XII Ceremony Procedure (Phase XII-ζ Ω12 — Founders-Anchor Genesis + Lattice Sealing)

Per `DOCS/III-XII.md` §24.6–§25 and the III Convergence Gospel V1 Stage 6.

This document is the **step-by-step operator procedure** for enacting the XII
ceremony: generating the real Founders-Anchor keypair, sealing the 882-cell
Lattice, signing the Manifest, computing `XII_R1`, seeding the MPHF, and
verifying the result. It is the operator-attestation companion to the
deterministic build scripts.

In a production deployment the seed and private key are generated and held
**entirely off-device** (HSM / air-gapped sanctum) and never touch the build
host. The single-host enactment below seals them in
`FOUNDERS-ANCHOR/SEALED_OPERATOR_SECRET/`, marked non-distributable, and the
operator attests (by signing this procedure's completion in the ledger) that
the privkey was wiped after manifest signing. Only the **public** key is
committed.

## Determinism preamble (every step)

```
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0
```

All artifacts are byte-deterministic given the same sealed seed. Re-running any
step reproduces identical bytes; the only non-reproducible input is the one-time
physical entropy draw in Step 1.

## Steps

1. **Draw the anchor seed (one-time, physical entropy).**
   `bash COMPILER/BOOT/seal_xii_horizons.sh` is independent; for the seed:
   build and run `gen_anchor_seed` (links the native lib), which draws 48 bytes
   of RDSEED/RDRAND physical entropy + a 16-byte nonce through the §4.7
   HMAC-DRBG-SHA-512 and writes a 64-byte seed.
   ```
   gcc -O2 COMPILER/BOOT/gen_anchor_seed.c STDLIB/build/iii/libiii_native.a \
       -lws2_32 -lkernel32 -lmsvcrt -o gen_anchor_seed
   ./gen_anchor_seed FOUNDERS-ANCHOR/SEALED_OPERATOR_SECRET/anchor_seed.bin
   ```
   Seal the seed off-device (production) or in `SEALED_OPERATOR_SECRET/`
   (single-host enactment, non-distributable).

2. **Enact the seal ceremony.** `bash COMPILER/BOOT/seal_xii_final.sh` runs,
   in order, the eight ceremony sub-steps (each tool links the native lib):
   1. Build the generator/signing tools (idempotent; deterministic flags).
   2. `gen_trinity_certs` → the 12 Trinity admit certs + 56-byte `trinity_admit.bin`.
   3. `gen_xii_anchor_keypair` reads the sealed seed → `SHA-256` → Ed25519
      keypair: commits `FOUNDERS-ANCHOR/anchor_pubkey.bin`, emits the temporary
      privkey.
   4. `gen_xii_lattice` → `COMPILED/xii_lattice.bin` (882 cells = 126 productive
      horizons × 7 ISA targets, each a real machine-code payload with a 48-byte
      `cell_mhash` record) + `xii_lattice.mhash.golden`.
   5. `gen_xii_manifest` → `xii_manifest.bin` (1040 bytes): embeds `anchor_pubkey`
      at 0x310, `trinity_admit` at 0x370, `R1.mhash` at 0x010, the 22 crystal
      seals, and `xii_manifest.mhash.presig`.
   6. `sign_xii_manifest` signs `manifest[0x000..0x32F]` with the anchor privkey
      (via `ed25519_sign_c4`, combined seed‖pubkey), patches the 64-byte
      signature at 0x330, and writes the post-sig `xii_manifest.mhash.golden`.
   7. Wipe the privkey (zeroed then unlinked — sanctum hygiene).
   8. `gen_xii_r1` → `DOCS/XII_R1.mhash` =
      `SHA-256(R1 ‖ manifest.mhash ‖ lattice.mhash ‖ horizon_reach.mhash)`.

3. **Update the embedded default + ceremony attestation.** Set
   `III_FOUNDERS_ANCHOR_PUBLIC_KEY_DEFAULT` in `FOUNDERS-ANCHOR/src/founders_anchor.c`
   to the committed `anchor_pubkey.bin` bytes (verify a sign+verify round-trip
   with the derived key first).

4. **Seed the MPHF horizons.** `bash COMPILER/BOOT/seal_xii_horizons.sh` derives
   the 144 real horizon master hashes (SHA-256 of each horizon's canonical
   definition: `id ‖ primary_op ‖ ct_kind ‖ productivity`), seeds the CHD
   minimal perfect hash, constructs it, and asserts
   `xii_chd_verify_collision_free() == 0`; seals `xii_horizons.mhash.golden`.

## Verification gates (the ceremony is complete only when all hold)

- `DOCS/XII_R1.mhash` is non-zero.
- `FOUNDERS-ANCHOR/anchor_pubkey.bin` is the real ceremony value (not `0xCC`).
- `COMPILED/xii_lattice.bin` has 882 cells, every payload real machine code with
  matching `cell_mhash`; replaying `gen_xii_lattice` is byte-identical.
- `xii_manifest.bin` (1040 bytes) is signed by the real anchor; `verify_xii_manifest`
  reports VALID.
- `bash STDLIB/scripts/run_xii_antidrift.sh` returns OK on all 8 checks.
- The MPHF is collision-free over the 144 real horizon master hashes.
- The 12 ceremony certs and the 56-byte `trinity_admit` are present and non-zero;
  their master hashes are ledgered in `DOCS/MHASH-LEDGER.md`.

## Re-enactment

Steps 2–4 are idempotent and deterministic: given the same sealed seed they
reproduce byte-identical `xii_lattice.bin`, `xii_manifest.bin`, `XII_R1.mhash`,
and `xii_horizons.mhash.golden`. Step 1 is performed exactly once; the resulting
public key is the permanent root of trust.
