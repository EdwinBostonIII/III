#!/usr/bin/env bash
# COMPILER/BOOT/seal_xii_horizons.sh -- XII MPHF horizon-seeding pipeline.
# Per the gospel Stage-6 gate: "the MPHF is seeded with real horizon master
# hashes and xii_chd_verify_collision_free returns zero."
#
# Builds gen_xii_horizons (which derives the 144 real horizon master hashes
# from the canonical horizon definitions, seeds the CHD minimal perfect hash,
# constructs it, and verifies it is collision-free), runs it, and seals the
# deterministic seed golden to COMPILED/xii_horizons.mhash.golden.
#
# Exit 0 = seeded + collision-free; non-zero = failure.
set -uo pipefail
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
BOOT="$REPO/COMPILER/BOOT"
LIB="$REPO/STDLIB/build/iii/libiii_native.a"
COMPILED="$REPO/COMPILED"
TOOL="$COMPILED/gen_xii_horizons.exe"
GOLDEN="$COMPILED/xii_horizons.mhash.golden"

if [ ! -f "$LIB" ]; then
    echo "[seal-horizons] FATAL: libiii_native.a not built; run STDLIB build first" >&2
    exit 1
fi

echo "[seal-horizons] building seeder"
gcc -O2 -DNDEBUG -ffile-prefix-map="$PWD"=. -frandom-seed=gen_xii_horizons \
    "$BOOT/gen_xii_horizons.c" "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o "$TOOL" \
    || { echo "[seal-horizons] build FAIL" >&2; exit 2; }

echo "[seal-horizons] seeding 144 real horizon master hashes + constructing + verifying"
cp "$TOOL" "${TOOL}.run" 2>/dev/null || true
"${TOOL}.run" "$GOLDEN"
rc=$?
if [ $rc -ne 0 ]; then
    echo "[seal-horizons] FAIL (rc=$rc)" >&2
    exit 3
fi
echo "[seal-horizons] OK: MPHF seeded collision-free; golden -> $GOLDEN"
exit 0
