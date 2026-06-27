#!/usr/bin/env bash
# UNIVERSALITY GATE (DOCS/III-EIDOS plan Phase 3.3) -- "point the compiler at ANYTHING."
#
# Generates K RANDOM, un-pre-shaped constants and, for each, compiles a program (with the NEW e-graph-wired
# iiis-2) that checks the e-graph's optimized form against the compiler's OWN unoptimized reference -- ON THE
# CPU, over the wrap edges:
#   gmul(x) = x * C   (constant C -> e-graph synthesizes+proves the shift form)   vs
#   fmul(x,C) = x * C (C a runtime param -> plain imul, the reference)
#   gdiv(x) = x / C   (constant C -> magic mulhi>>s, GM-bound-proven)             vs
#   fdiv(x,C) = x / C (C a runtime param -> plain divq, the reference)
# If the optimized form EVER diverges from the reference for any sampled x, the program returns != 99 and the
# gate reddens, printing the offending constant.  This is the operator's standard: the proof is the compiler
# running on inputs the operator (here: $RANDOM) chose, not a hand-picked example.  No self-authored checker --
# the reference is the compiler's own imul/divq.
set -uo pipefail
III="${III_ROOT:-/c/Users/Edwin Boston/OneDrive/Desktop/III}"
IIIS="${IIIS:-$III/COMPILED/iiis-2.exe}"
OUT="${OUT_DIR:-/tmp}/univ_$$"; mkdir -p "$OUT"
K="${K:-32}"
log() { echo "[univ] $*"; }
is_pow2() { local v=$1; (( v >= 2 && (v & (v-1)) == 0 )); }

PASS=0; FAIL=0; FAILED=""
i=0
while (( i < K )); do
    # random non-pow2 constant in [3, ~2^31); mix small and large.
    C=$(( (RANDOM<<16 | RANDOM) % 2147483629 + 3 ))
    if is_pow2 "$C"; then i=$((i+1)); continue; fi
    cm1=$((C-1)); cp1=$((C+1)); cbig=$((C*1000+7))
    src="$OUT/u_$C.iii"
    cat > "$src" <<EOF
module univ_$C
fn fmul(x: u64, c: u64) -> u64 { return x * c }
fn gmul(x: u64) -> u64 { return x * ${C}u64 }
fn fdiv(x: u64, c: u64) -> u64 { return x / c }
fn gdiv(x: u64) -> u64 { return x / ${C}u64 }
var XS : [u64; 16]
fn main() -> u64 {
    XS[0u64]=0u64 XS[1u64]=1u64 XS[2u64]=2u64 XS[3u64]=255u64 XS[4u64]=65536u64
    XS[5u64]=4294967295u64 XS[6u64]=4294967296u64 XS[7u64]=9223372036854775807u64
    XS[8u64]=9223372036854775808u64 XS[9u64]=18446744073709551614u64 XS[10u64]=18446744073709551615u64
    XS[11u64]=12345678901234567890u64 XS[12u64]=${cm1}u64 XS[13u64]=${C}u64 XS[14u64]=${cp1}u64 XS[15u64]=${cbig}u64
    let mut k : u64 = 0u64
    while k < 16u64 {
        let x : u64 = XS[k]
        if gmul(x) != fmul(x, ${C}u64) { return 1u64 }
        if gdiv(x) != fdiv(x, ${C}u64) { return 2u64 }
        k = k + 1u64
    }
    return 99u64
}
EOF
    obj="$OUT/u_$C.o"; exe="$OUT/u_$C.exe"
    if ! ( cd "$OUT" && "$IIIS" "u_$C.iii" --compile-only --out "$obj" >/dev/null 2>&1 ); then
        FAIL=$((FAIL+1)); FAILED="$FAILED ${C}(compile)"; i=$((i+1)); continue
    fi
    gcc "$obj" -lws2_32 -lkernel32 -o "$exe" >/dev/null 2>&1
    st="/tmp/u_${C}_$$.exe"; cp "$exe" "$st" 2>/dev/null
    "$st"; rc=$?; rm -f "$st"
    if [ "$rc" -eq 99 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); FAILED="$FAILED ${C}(rc=$rc)"; fi
    i=$((i+1))
done
log "universality: $PASS passed, $FAIL failed (random constants, e-graph form vs imul/divq reference on the CPU)"
if [ "$FAIL" -gt 0 ]; then log "FAILED constants:$FAILED"; exit 1; fi
log "GATE PASS: every random constant's optimized lowering matches the unoptimized reference for all sampled x."
exit 0
