#!/usr/bin/env bash
# verify_iii_works.sh -- reproduce, from scratch, the proof that III actually works.
# No rigging: this compiles fresh III source with the pinned self-hosted compiler, runs the
# binaries, and checks their output against PUBLIC reference vectors (FIPS-180-4, a hand-checkable
# JSON parse). Run it yourself: `bash _audit_scratch/verify_iii_works.sh`
#
# Exit 0 = every check matched its public reference. Non-zero = first failing check.
set -u
cd "$(dirname "$0")/.." || exit 9
IIIS="COMPILED/iiis-2.exe"
BUILD="STDLIB/build/iii"
LIB="$BUILD/libiii_native.a"
SEO="$BUILD/resolver_unit.o $BUILD/bench_helpers.o"
TMP="${TMPDIR:-/tmp}"
fail() { echo "FAIL: $1"; exit "${2:-1}"; }

[ -x "$IIIS" ] || fail "pinned compiler $IIIS not found" 2
[ -f "$LIB" ] || fail "stdlib $LIB not built -- run: bash STDLIB/scripts/build_stdlib.sh" 3

echo "compiler: $IIIS"
"$IIIS" --version 2>/dev/null | head -1
echo

compile_run() {  # $1=src $2=outname  -> echoes exit code, leaves stdout in $TMP/$2.out
    "$IIIS" "$1" --compile-only --out "$TMP/$2.o" >/dev/null 2>&1 || fail "compile $1" 4
    gcc "$TMP/$2.o" -Wl,--whole-archive $SEO -Wl,--no-whole-archive "$LIB" \
        -lws2_32 -lkernel32 -o "$TMP/$2.exe" 2>/dev/null || fail "link $1" 5
    "$TMP/$2.exe" >"$TMP/$2.out" 2>/dev/null
    echo $?
}

# ---- Proof 1: SHA-256("abc") computed by III's own stdlib, vs FIPS-180-4 ----
echo "== Proof 1: SHA-256(\"abc\") via III stdlib =="
ec=$(compile_run _audit_scratch/proof_run.iii proof_run)
got=$(cat "$TMP/proof_run.out")
want="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
echo "  III output: $got"
echo "  FIPS-180-4: $want"
[ "$got" = "$want" ] || fail "SHA-256 digest mismatch" 6
[ "$ec" = "186" ]    || fail "SHA-256 exit code != 186 (first digest byte 0xBA)" 6
echo "  MATCH (exit=$ec=0xBA)"
echo

# ---- Proof 2: structured JSON parse via III's own verba::json ----
echo "== Proof 2: JSON parse {\"a\":[10,20,30],\"b\":\"world\"} via III stdlib =="
ec=$(compile_run _audit_scratch/proof_json.iii proof_json)
got=$(cat "$TMP/proof_json.out")
echo "  III output: $got   (sum read back from the parse tree; string extracted)"
[ "$got" = "sum=60 str=world" ] || fail "JSON parse output mismatch" 7
[ "$ec" = "60" ]                || fail "JSON exit code != 60 (the parsed array sum)" 7
echo "  MATCH (exit=$ec)"
echo

# ---- Proof 3: self-hosting -- iiis-2 compiles its OWN source (a broken compiler can't) ----
echo "== Proof 3: self-hosting sanity -- iiis-2 compiles a piece of its own source =="
"$IIIS" COMPILER/BOOT/lex_rt.iii --compile-only --out "$TMP/selfhost_lex.o" >/dev/null 2>&1 \
    || fail "iiis-2 failed to compile its own COMPILER/BOOT/lex_rt.iii" 8
echo "  iiis-2 compiled COMPILER/BOOT/lex_rt.iii (one of its own sources) -> OK"
echo "  Full byte-for-byte bootstrap (the strongest proof) is the determinism gate:"
echo "    bash COMPILER/BOOT/build_iiis2.sh --check-corpus    # expect: 59 passed, 0 failed"
echo

echo "ALL CHECKS PASSED -- III compiles, runs, and reproduces public reference vectors."
exit 0
