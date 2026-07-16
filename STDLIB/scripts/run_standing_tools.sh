#!/usr/bin/env bash
# STDLIB/scripts/run_standing_tools.sh -- THE EVERGREEN GUARANTEE for III's runnable capability surface.
#
# "A capability that can only be exercised by hand-writing a driver for each input is a demo with good
# manners" (III-STANDING-TOOLS.md).  III ships TEN committed tool binaries.  This gate rebuilds EVERY
# one from source via its leaf script (pinned iiis-2 + committed archive; bootstrap untouched) and
# exercises it on ONE canonical known-answer input -- so a change that silently breaks any tool reddens
# here, and the whole surface stays runnable.  Known answers are derived from external truth (FIPS
# vectors, closed-form signs, the faculty's own rules), never from the tool's own output.
#
# Exit: 0 every tool builds + passes its smoke check | 1 a tool broke | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$III_ROOT/COMPILER/BOOT"
W="$III_ROOT/STDLIB/build/standing_tools"
mkdir -p "$W"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
C="$III_ROOT/COMPILED"
say() { printf '%s\n' "$*"; }
FAIL=0

build() {   # build_script tool-name
    if bash "$BOOT/$1" >/dev/null 2>&1 && [[ -x "$C/$2$BIN_SUFFIX" ]]; then return 0; fi
    say "RED [$2] build failed ($1)"; FAIL=1; return 1
}
expect_exit() {   # label want-exit  cmd...
    local label="$1"; local want="$2"; shift 2
    "$@" >/dev/null 2>&1; local got=$?
    if [[ "$got" == "$want" ]]; then say "PASS $label (exit $got)"; else say "RED  $label want=$want got=$got"; FAIL=1; fi
}

say "[standing] == iii-prove: prove/refute over ALL 2^64 =="
if build build_iii_prove.sh iii-prove; then
    cat > "$W/pa.iii" << 'IIIEOF'
module pa
fn mul10(x: u64) -> u64 @export { return x * 10u64 }
fn xor2(x: u64) -> u64 @export { return x ^ 2u64 }
IIIEOF
    cat > "$W/pb.iii" << 'IIIEOF'
module pb
fn shadd(x: u64) -> u64 @export { return (x << 3u64) + (x << 1u64) }
fn add2(x: u64) -> u64 @export { return x + 2u64 }
IIIEOF
    expect_exit "prove x*10 == (x<<3)+(x<<1)  PROVEN" 0 "$C/iii-prove$BIN_SUFFIX" "$W/pa.iii" mul10 "$W/pb.iii" shadd
    expect_exit "prove x^2 == x+2  REFUTED"          1 "$C/iii-prove$BIN_SUFFIX" "$W/pa.iii" xor2 "$W/pb.iii" add2
fi

say "[standing] == iii-crypto: SHA-256 FIPS vector =="
if build build_iii_crypto.sh iii-crypto; then
    printf 'abc' > "$W/abc.txt"
    H="$("$C/iii-crypto$BIN_SUFFIX" hash "$W/abc.txt" 2>/dev/null | tr -d '\r\n ' )"
    if [[ "$H" == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" ]]; then
        say "PASS sha256(\"abc\") == the FIPS-180 vector"
    else say "RED  sha256(\"abc\") = $H"; FAIL=1; fi
fi

say "[standing] == iii-exact: exact sign of sums of surds (no float) =="
if build build_iii_exact.sh iii-exact; then
    expect_exit "sign(sqrt2) = POS"                 2 "$C/iii-exact$BIN_SUFFIX" "1 2"
    expect_exit "sign(2sqrt2+3sqrt2-5sqrt2) = ZERO" 0 "$C/iii-exact$BIN_SUFFIX" "2 2 3 2 -5 2"
fi

say "[standing] == iii-typecheck: hexad reachability as a TYPE =="
if build build_iii_typecheck.sh iii-typecheck; then
    expect_exit "--reach 40 (first reachable) PROVEN" 0 "$C/iii-typecheck$BIN_SUFFIX" --reach 40
    expect_exit "--reach 0  (bricking) REFUSED"       4 "$C/iii-typecheck$BIN_SUFFIX" --reach 0
fi

say "[standing] == iii_eval: the definitional bearer =="
if build build_iii_eval.sh iii_eval; then
    cat > "$W/probe42.iii" << 'IIIEOF'
module probe42
fn main() -> i32 { let mut s : u64 = 0u64  let mut i : u64 = 1u64  while i <= 8u64 { s = s + i  i = i + 1u64 }  return (s % 100u64) as i32 }
IIIEOF
    expect_exit "eval sum(1..8)%100 = 36" 36 "$C/iii_eval$BIN_SUFFIX" "$W/probe42.iii"
fi

say "[standing] == iii-events: route V (event-primary) =="
if build build_iii_events.sh iii-events; then
    expect_exit "--quiet sum(1..8)%100 = 36 (route V == eval == native)" 36 "$C/iii-events$BIN_SUFFIX" --quiet "$W/probe42.iii"
    expect_exit "--diff self == identical (exit 0)"                        0 "$C/iii-events$BIN_SUFFIX" --diff "$W/probe42.iii" "$W/probe42.iii"
fi

say "[standing] == iii-intent: the Oracle of Rejection =="
if build build_iii_intent.sh iii-intent; then
    expect_exit "'lock the database' RESOLVED"          0 "$C/iii-intent$BIN_SUFFIX" "lock the database"
    expect_exit "'encrypt the network port' CONTRADICTION" 1 "$C/iii-intent$BIN_SUFFIX" "encrypt the network port"
fi

say "[standing] == iii-hexad: the asymmetric ternary safety ground =="
if build build_iii_hexad.sh iii-hexad; then
    CNT="$("$C/iii-hexad$BIN_SUFFIX" --count 2>/dev/null | grep -o '= [0-9]*' | head -1 | tr -dc '0-9')"
    if [[ "$CNT" == "144" ]]; then say "PASS --count = 144"; else say "RED --count = $CNT"; FAIL=1; fi
    expect_exit "N P P P P P (structural NEG) BRICKING" 1 "$C/iii-hexad$BIN_SUFFIX" N P P P P P
    expect_exit "P P P P P P (all POS) ADMITTED"        0 "$C/iii-hexad$BIN_SUFFIX" P P P P P P
fi

say "[standing] == iii-testament: the AUTARKEIA spine emitter =="
if build build_iii_testament.sh iii-testament; then
    # keygen is DETERMINISTIC in the seed FILE: same 96-byte seed -> byte-identical SLH-DSA-SHA2-256s
    # keypair, always.  That determinism (external truth: FIPS-205 deterministic keygen) is the KAT.
    printf '%-96.96s' 'AUTARKEIA-TESTAMENT-STANDING-SMOKE-SEED' > "$W/tst_seed.bin"   # pad-to-96/truncate-at-96: EXACTLY 96 B by construction
    "$C/iii-testament$BIN_SUFFIX" keygen "$W/tst_seed.bin" "$W/tst_pk1.bin" "$W/tst_sk1.bin" >/dev/null 2>&1
    "$C/iii-testament$BIN_SUFFIX" keygen "$W/tst_seed.bin" "$W/tst_pk2.bin" "$W/tst_sk2.bin" >/dev/null 2>&1
    if cmp -s "$W/tst_pk1.bin" "$W/tst_pk2.bin" && cmp -s "$W/tst_sk1.bin" "$W/tst_sk2.bin" \
       && [[ "$(wc -c < "$W/tst_pk1.bin")" -eq 64 && "$(wc -c < "$W/tst_sk1.bin")" -eq 128 ]]; then
        say "PASS keygen deterministic (same seed -> identical pk64+sk128)"
    else say "RED  keygen determinism/sizes"; FAIL=1; fi
fi

say "[standing] == iii-witness: the stranger's testament verifier =="
if build build_iii_witness.sh iii-witness; then
    # a malformed file must be REFUSED as format (exit 10) -- the witness trusts nothing it is handed.
    printf 'not a testament at all -- too short and no IIITSTMT magic' > "$W/garbage.bin"
    expect_exit "malformed input REFUSED as format" 10 "$C/iii-witness$BIN_SUFFIX" verify "$W/garbage.bin"
    # and if the committed canonical testament exists, Tier-1 verify it (signature + internal chain).
    if [[ -f "$III_ROOT/STDLIB/testament/testament.dat" && -f "$III_ROOT/STDLIB/testament/testament.pk" ]]; then
        expect_exit "committed testament.dat Tier-1 VALID" 0 "$C/iii-witness$BIN_SUFFIX" verify \
            "$III_ROOT/STDLIB/testament/testament.dat" "$III_ROOT/STDLIB/testament/testament.pk"
    fi
fi

# CROSS-TOOL CONSISTENCY: iii-hexad and iii-typecheck --reach share the hexad_reach faculty -- they must
# agree on hexad admissibility.  hexad 40 (packed) admitted <=> --reach 40 PROVEN.  A genuine two-tool
# check that the safety algebra is ONE object seen through two surfaces.
say "[standing] == cross-tool: iii-hexad reachability == iii-typecheck --reach =="
if [[ -x "$C/iii-hexad$BIN_SUFFIX" && -x "$C/iii-typecheck$BIN_SUFFIX" ]]; then
    # hexad id 40 = 0b...; unpack: 40 base-3 = trits.  Rather than reconstruct, use --reach as the oracle
    # and confirm iii-hexad agrees on a KNOWN-admitted (all-POS = id 728) and known-bricking (id 0).
    "$C/iii-typecheck$BIN_SUFFIX" --reach 728 >/dev/null 2>&1; R728=$?
    "$C/iii-hexad$BIN_SUFFIX" P P P P P P >/dev/null 2>&1; H728=$?   # all-POS packs to 728, admitted=0
    "$C/iii-typecheck$BIN_SUFFIX" --reach 0 >/dev/null 2>&1; R0=$?
    "$C/iii-hexad$BIN_SUFFIX" N N N N N N >/dev/null 2>&1; H0=$?     # all-NEG packs to 0, bricking=1
    # --reach: 0 PROVEN / 4 REFUSED ; iii-hexad: 0 ADMITTED / 1 BRICKING.  Map and compare.
    ok=1
    [[ "$R728" == "0" && "$H728" == "0" ]] || ok=0     # both say admitted
    [[ "$R0" == "4" && "$H0" == "1" ]] || ok=0         # both say not-admitted
    if [[ $ok -eq 1 ]]; then say "PASS iii-hexad and iii-typecheck --reach agree (id 728 admitted, id 0 bricking)"; else say "RED cross-tool: reach728=$R728 hex728=$H728 reach0=$R0 hex0=$H0"; FAIL=1; fi
fi

if [[ $FAIL -ne 0 ]]; then echo "[standing] RED -- a tool broke"; exit 1; fi
echo "[standing] GREEN: all 8 tools build from source and pass their known-answer smoke checks + cross-tool consistency"
exit 0
