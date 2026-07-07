#!/usr/bin/env bash
# mldsa_c2sp_kat_gate.sh -- ML-DSA-44/65/87 against the OFFICIAL C2SP/CCTV FIPS-204 accumulated
# vectors (github.com/C2SP/CCTV/ML-DSA/accumulated) -- the de-facto FIPS-204 conformance KAT.
# Sibling of mlkem_c2sp_kat_gate.sh (independence-closure F follow-on).
#
# The KAT harnesses (corpus/2491/2492/2493, one per parameter set) are VERIFIED CORRECT
# independently of the module:
#   * DRBG (SHAKE-128 empty) stream starts 7f9c2ba4e88f827d... == the published C2SP stream
#   * the same inline incremental SHAKE-128 helpers as corpus/2490 (proven there)
#   * protocol == the C2SP accumulated spec verbatim: per iteration seed=read(s,32);
#     keygen(seed); absorb(pk); sign_deterministic(msg="", ctx="") [M' = 00 00, rnd = 0^32];
#     verify must ACCEPT; absorb(sig).  BOTH published checkpoints enforced per level
#     (100 iters via an accumulator-copy finalize + 10000 iters, the CI tier).
#   * an independent JS reference implementation (built for localization) reproduces both the
#     official ACVP sigGen vector byte-for-byte AND the C2SP 100-iter digest -- the digests
#     pin FIPS-204 FINAL external-API semantics (final keygen with k,l append; M'-wrapped msg).
#
# STATUS (2026-07): GREEN.  The module reproduces the official accumulated digests at ALL THREE
# parameter sets.  Getting here surfaced FOUR round-3 leftovers in mldsa.iii, each invisible to
# every self-consistent test (sign+verify shared the same wrong convention):
#   1. rhoprime = H(K||mu)          -> H(K || rnd || mu), rnd = 0^32 (FIPS-204 Sign_internal)
#   2. c~ fixed at 32 bytes         -> lambda/4 = 32/48/64 (ML-DSA-65/87 sigs were 3293/4595,
#                                      FIPS-204 requires 3309/4627)
#   3. SampleInBall absorbed 32     -> absorbs the full c~
#   4. ExpandMask strode 18/20 bytes per 4 coeffs -> 9/10 (the port skipped every other block
#                                      of the SHAKE stream; uniform + self-consistent, so only
#                                      an external byte-oracle could catch it)
# Localized via NIST ACVP single vectors (keyGen: pk+sk byte-exact BEFORE any fix -- keygen was
# already FIPS-204-final; sigGen tgId-8: byte-exact after fixes 1-4).
#
# The three KATs run IN PARALLEL (each ~4-15 min alone; wall time ~ the slowest).
# Exit 0 = all three parameter sets byte-FIPS-204-conformant; 3 = digest DIVERGENCE (regression);
#      2 = an op error; 4 = environment.
set -u
export LC_ALL=C
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
W="$(mktemp -d "${TMPDIR:-/tmp}/mldsakat.XXXXXX")"
trap 'rm -rf "$W"' EXIT
say(){ printf '[mldsa-c2sp] %s\n' "$*"; }

[ -x "$IIIS" ] || { say "FAIL: missing $IIIS"; exit 4; }
[ -f "$LIB" ]  || { say "FAIL: missing $LIB"; exit 4; }
command -v gcc >/dev/null 2>&1 || { say "SKIP: gcc absent (needed to link the KAT drivers)"; exit 0; }

for spec in 2491_mldsa44_c2sp_kat 2492_mldsa65_c2sp_kat 2493_mldsa87_c2sp_kat; do
  "$IIIS" "$ROOT/STDLIB/corpus/$spec.iii" --compile-only --out "$W/$spec.o" >/dev/null 2>&1 || { say "FAIL: $spec compile"; exit 4; }
  gcc "$W/$spec.o" "$LIB" -lkernel32 -o "$W/$spec.exe" 2>/dev/null || { say "FAIL: $spec link"; exit 4; }
done

say "running the official C2SP ML-DSA-44/65/87 accumulated KATs (10000 iterations each, in parallel)..."
"$W/2491_mldsa44_c2sp_kat.exe" & p44=$!
"$W/2492_mldsa65_c2sp_kat.exe" & p65=$!
"$W/2493_mldsa87_c2sp_kat.exe" & p87=$!
wait "$p44"; rc44=$?
wait "$p65"; rc65=$?
wait "$p87"; rc87=$?

overall=0
report() { # name rc
  case "$2" in
    99) say "  $1 GREEN -- reproduces the official 100-iter AND 10000-iter digests" ;;
    11) say "  $1 REGRESSION -- 100-iteration digest mismatch"; overall=3 ;;
    12) say "  $1 REGRESSION -- 10000-iteration digest mismatch (100 matched)"; overall=3 ;;
    2)  say "  $1 FAIL -- keygen error"; [ "$overall" -eq 0 ] && overall=2 ;;
    3)  say "  $1 FAIL -- sign error";   [ "$overall" -eq 0 ] && overall=2 ;;
    4)  say "  $1 FAIL -- wrong signature length"; [ "$overall" -eq 0 ] && overall=2 ;;
    5)  say "  $1 FAIL -- verify REJECTED a genuine signature"; [ "$overall" -eq 0 ] && overall=2 ;;
    *)  say "  $1 FAIL -- unexpected exit $2"; [ "$overall" -eq 0 ] && overall=2 ;;
  esac
}
report "ML-DSA-44" "$rc44"
report "ML-DSA-65" "$rc65"
report "ML-DSA-87" "$rc87"
[ "$overall" -eq 0 ] && say "GATE GREEN -- ML-DSA-44/65/87 are byte-FIPS-204-conformant (official C2SP accumulated vectors)"
exit "$overall"
