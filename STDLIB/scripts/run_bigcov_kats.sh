#!/usr/bin/env bash
# run_bigcov_kats.sh -- gate for the BIGINT-backed full-resolution symmetric 2D coverage (ui_exact_big.iii).
# Distinct from run_ui_kats because it links libiii_native.a (for numera/bigint + memoria/arena).
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/ui_exact_big.iii" --compile-only --out "$OUT/ui_exact_big.o" 2>"$OUT/big.log" || { echo "FAIL ui_exact_big compile"; cat "$OUT/big.log"; exit 1; }

run() {
    local name="$1" want="$2"
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$OUT/ui_exact_big.o" "$LIB" -lws2_32 -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    timeout 120 "$st"; local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2103_bsign_big 99

echo "=== BIGINT-COVERAGE KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
