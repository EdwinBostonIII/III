#!/usr/bin/env bash
# COMPILER/BOOT/seal_xii_final.sh -- Phase XII-ζ Final Seal Ceremony.
# Per DOCS/III-XII.md S24.6 + S25.
#
# Ceremony ordering (required so the Anchor signature covers the real bytes
# at 0x310 anchor_pubkey and 0x370 trinity_admit, not zero placeholders):
#
#   1. Build all generator/signing tools (idempotent).
#   2. Generate the 12 Trinity admit certs + trinity_admit.bin.
#   3. Generate the Founders-Anchor Ed25519 keypair from the sealed seed.
#   4. Generate the Lattice (xii_lattice.bin + xii_lattice.mhash.golden).
#   5. Generate the Manifest. gen_xii_manifest reads:
#        - 22 sealed source files for the crystal seals
#        - FOUNDERS-ANCHOR/anchor_pubkey.bin into 0x310
#        - ceremonies/trinity_admit.bin into 0x370
#        - DOCS/R1.mhash into 0x010
#      Writes xii_manifest.bin + xii_manifest.mhash.presig.
#   6. Sign the Manifest. sign_xii_manifest reads manifest[0..0x32F], signs
#      with the Anchor privkey, patches sig at 0x330, then writes the
#      POST-SIG xii_manifest.mhash.golden.
#   7. Wipe the privkey file.
#   8. Compute XII_R1 from the post-sig manifest mhash + lattice mhash +
#      horizon_reach hash + R1 hash.
#
# Determinism: LC_ALL=C TZ=UTC0 SOURCE_DATE_EPOCH=0 -- every artifact is
# byte-deterministic given the same inputs.

set -euo pipefail
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
COMPILED="$REPO/COMPILED"
BOOT="$REPO/COMPILER/BOOT"

mkdir -p "$COMPILED" "$REPO/DOCS" "$BOOT/ceremonies" "$REPO/FOUNDERS-ANCHOR"

GEN_MANIFEST="$COMPILED/gen_xii_manifest"
GEN_LATTICE="$COMPILED/gen_xii_lattice"
GEN_R1="$COMPILED/gen_xii_r1"
GEN_TRINITY="$COMPILED/gen_trinity_certs"
GEN_ANCHOR_KG="$COMPILED/gen_xii_anchor_keypair"
SIGN_TOOL="$COMPILED/sign_xii_manifest"

# Native SHA-256 object built by the III stdlib pipeline.
SHA_OBJ=""
if [ -f "$REPO/STDLIB/build/iii/numera/sha256.iii.o" ]; then
    SHA_OBJ="$REPO/STDLIB/build/iii/numera/sha256.iii.o"
fi
# Ed25519 object (needed by sign + anchor-kg).
ED25519_OBJ=""
if [ -f "$REPO/STDLIB/build/iii/numera/crypt_ed25519.iii.o" ]; then
    ED25519_OBJ="$REPO/STDLIB/build/iii/numera/crypt_ed25519.iii.o"
fi

# Link every ceremony tool against the full native lib: it resolves the
# entire .iii closure (sha256, ed25519/fe25519, xii_emit_gen + kernels +
# horizons, drbg, cpufeat) instead of the prior hand-picked .o set that
# silently under-linked gen_xii_lattice (xii_emit_gen/kernel/horizon) and the
# crypto tools (ed25519's fe25519/sha512 closure).
LIB_NATIVE="$REPO/STDLIB/build/iii/libiii_native.a"
build_gen() {
    local name="$1"
    local out="$2"
    # 3rd arg (legacy per-tool obj) is now subsumed by the lib; ignored.
    if [ ! -x "$out" ] || [ "$BOOT/${name}.c" -nt "$out" ] || [ "$LIB_NATIVE" -nt "$out" ]; then
        echo "[seal-xii] compiling $name"
        if [ ! -f "$LIB_NATIVE" ]; then
            echo "[seal-xii] FATAL: libiii_native.a not built; run STDLIB build first" >&2
            return 1
        fi
        # Quote "$PWD": the repo path contains a space, which would split the
        # -ffile-prefix-map argument and abort the compile.
        gcc -O2 -DNDEBUG -ffile-prefix-map="$PWD"=. -frandom-seed="$name" \
            "$BOOT/${name}.c" "$LIB_NATIVE" -lws2_32 -lkernel32 -lmsvcrt -o "$out"
    fi
    return 0
}

# Step 1: build tools.
build_gen "gen_xii_manifest"        "$GEN_MANIFEST"
build_gen "gen_xii_lattice"         "$GEN_LATTICE"
build_gen "gen_xii_r1"              "$GEN_R1"
build_gen "gen_trinity_certs"       "$GEN_TRINITY"
build_gen "gen_xii_anchor_keypair"  "$GEN_ANCHOR_KG" "$ED25519_OBJ"
build_gen "sign_xii_manifest"       "$SIGN_TOOL"     "$ED25519_OBJ"

# Step 2: Trinity admit certs (12 certs + trinity_admit.bin).
echo "[seal-xii] step 2: Trinity admit certs"
"$GEN_TRINITY" "$REPO"

# Step 3: Founders-Anchor keypair from sealed seed.
# Real ceremony seed (§4.7 HW-entropy DRBG output), sealed operator-held per ADR.
SEED="$REPO/FOUNDERS-ANCHOR/SEALED_OPERATOR_SECRET/anchor_seed.bin"
PUBKEY="$REPO/FOUNDERS-ANCHOR/anchor_pubkey.bin"
PRIVKEY="$REPO/FOUNDERS-ANCHOR/anchor_privkey.tmp.bin"

echo "[seal-xii] step 3: Founders-Anchor keypair"
if [ ! -f "$SEED" ]; then
    echo "[seal-xii] FATAL: missing seed at $SEED" >&2
    exit 1
fi
# Regenerate only if the seed has changed (or the pubkey/privkey is missing).
if [ ! -f "$PUBKEY" ] || [ "$SEED" -nt "$PUBKEY" ]; then
    "$GEN_ANCHOR_KG" "$SEED" "$PUBKEY" "$PRIVKEY"
fi

# Step 4: Lattice.
echo "[seal-xii] step 4: Lattice"
"$GEN_LATTICE" "$REPO"

# Step 5: Manifest -- captures REAL pubkey + admit bytes before signing.
echo "[seal-xii] step 5: Manifest"
"$GEN_MANIFEST" "$REPO"

# Step 6: Sign Manifest (covers pubkey + admit + every seal).
echo "[seal-xii] step 6: Founders-Anchor signature"
if [ ! -f "$PRIVKEY" ]; then
    echo "[seal-xii] FATAL: privkey missing; was it wiped before signing?" >&2
    exit 1
fi
"$SIGN_TOOL" "$BOOT/xii_manifest.bin" "$PRIVKEY" "$BOOT/xii_manifest.mhash.golden"
touch "$BOOT/xii_anchor_signed.flag"

# Step 7: Wipe privkey (sanctum hygiene).
echo "[seal-xii] step 7: wipe privkey"
if [ -f "$PRIVKEY" ]; then
    # Overwrite with zeros, then unlink. `dd` is portable; `shred` is GNU-only.
    dd if=/dev/zero of="$PRIVKEY" bs=1 count=64 conv=notrunc 2>/dev/null || true
    rm -f "$PRIVKEY"
fi

# Step 8: XII_R1 composite root.
echo "[seal-xii] step 8: XII_R1"
"$GEN_R1" "$REPO"

if [ -f "$REPO/DOCS/XII_R1.mhash" ]; then
    echo "[seal-xii] XII_R1: $(cat "$REPO/DOCS/XII_R1.mhash" | tr -d '[:space:]')"
    echo "[seal-xii] FINAL SEAL COMPLETE"
else
    echo "[seal-xii] FATAL: XII_R1 not produced" >&2
    exit 2
fi
exit 0
