#!/usr/bin/env bash
# mlkem_c2sp_kat_gate.sh -- ML-KEM-768 against the OFFICIAL C2SP/CCTV FIPS-203 accumulated vector
# (independence-closure F).  This is the de-facto FIPS-203 conformance KAT (Go crypto, BoringSSL gate on it).
#
# The KAT harness (corpus/1944) is VERIFIED CORRECT independently of the module:
#   * its DRBG (SHAKE-128 empty) stream starts 7f9c2ba4e88f827d616045507605853e == the published C2SP stream
#   * its inline incremental SHAKE-128 (DRBG squeeze + accumulator absorb) == numera/shake128 byte-for-byte
#   * its protocol matches the C2SP "accumulated" spec verbatim (draw d,z,m,ct(1088); accumulate ek,dk,
#     ct',k1,k2 over 10000 iters; the ML-KEM-768 digest is f7db260e1137a742e05fe0db9525012812b004d29040a5b606aad3d134b548d3)
#
# STATUS (2026-07): GREEN.  The module reproduces the official C2SP digest byte-for-byte over all 10000
# iterations -> ML-KEM-768 is byte-FIPS-203-compatible.  The sole divergence was in K-PKE.KeyGen's G input:
# the ported Kyber-round-3 code appended the dimension byte (G(d||k)); FIPS-203 ML-KEM uses G(d) with NO
# trailing byte.  Localized against the C2SP/CCTV intermediate vector (SHA3-512(d) == rho||sigma exactly)
# and fixed in mlkem.iii (kem_kpke_keygen).  Wired as bootstrap_from_clean stage 10.
#
# Exit 0 = module MATCHES the official C2SP digest (byte-FIPS-203-compatible); 3 = DIVERGES (a REGRESSION);
#          2 = a keygen/encaps/decaps error; 4 = environment.
set -u
export LC_ALL=C
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
W="$(mktemp -d "${TMPDIR:-/tmp}/mlkemkat.XXXXXX")"
trap 'rm -rf "$W"' EXIT
say(){ printf '[mlkem-c2sp] %s\n' "$*"; }

[ -x "$IIIS" ] || { say "FAIL: missing $IIIS"; exit 4; }
[ -f "$LIB" ]  || { say "FAIL: missing $LIB"; exit 4; }
command -v gcc >/dev/null 2>&1 || { say "SKIP: gcc absent (needed to link the KAT driver)"; exit 0; }

"$IIIS" "$ROOT/STDLIB/corpus/2490_mlkem_c2sp_kat.iii" --compile-only --out "$W/kat.o" >/dev/null 2>&1 || { say "FAIL: KAT compile"; exit 4; }
gcc "$W/kat.o" "$LIB" -lkernel32 -o "$W/kat.exe" 2>/dev/null || { say "FAIL: KAT link"; exit 4; }
say "running the official C2SP ML-KEM-768 accumulated KAT (10000 iterations, ~30-60s)..."
"$W/kat.exe"; rc=$?
case "$rc" in
  99) say "GATE GREEN -- module reproduces the official C2SP FIPS-203 ML-KEM-768 digest (byte-compatible)"; exit 0 ;;
  1)  say "REGRESSION -- module's accumulated digest != official f7db260e...; ML-KEM byte-compat BROKE.";
      say "            (was fixed by the G(d) no-k-byte correction in kem_kpke_keygen; check that + encode/NTT/compress)."; exit 3 ;;
  2)  say "FAIL -- a keygen/encaps/decaps op returned an error"; exit 2 ;;
  *)  say "FAIL -- unexpected KAT exit $rc"; exit 2 ;;
esac
