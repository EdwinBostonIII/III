#!/usr/bin/env bash
# Build + run the cg_sha FIPS KAT (the standalone proof cg_sha.iii line 22 promised).
# iiis-2 compiles cg_sha.iii + cgsha_kat.iii -> link -> run.  exit 99 = pass.
set -euo pipefail
export LC_ALL=C TZ=UTC0 SOURCE_DATE_EPOCH=0
cd "$(dirname "$0")/../.."                 # III root
IIIS="COMPILED/iiis-2.exe"
CC="${CC:-gcc}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/cgsha-kat.XXXXXX")"
trap '[[ -n "${TMP:-}" && -d "$TMP" ]] && rm -rf "$TMP" || true' EXIT

"./$IIIS" COMPILER/BOOT/cg_sha.iii    --compile-only --out "$TMP/cg_sha.o"
"./$IIIS" COMPILER/BOOT/cgsha_kat.iii --compile-only --out "$TMP/cgsha_kat.o"
"$CC" -o "$TMP/cgsha_kat.exe" "$TMP/cgsha_kat.o" "$TMP/cg_sha.o"

set +e
"$TMP/cgsha_kat.exe"
rc=$?
set -e
echo "[cgsha_kat] exit=$rc (99 = FIPS abc + non-destructive-snapshot PASS)"
if [[ "$rc" -eq 99 ]]; then echo "CGSHA KAT PASS"; exit 0; else echo "CGSHA KAT FAIL (rc=$rc)"; exit 1; fi
