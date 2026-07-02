#!/usr/bin/env bash
# run_stoma_kats.sh -- gate for the STOMA sovereign-CLI organ family (DOCS/III-STOMA-PLAN.md).
# DISJOINT standalone gate (concurrent-writer law): compiles the stoma_* organs once, then each
# corpus KAT compiles+links+runs for its TRUE exit code (99 = pass).  kernel32-only organs.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
OUT="$III/STDLIB/build/stoma_kats"
mkdir -p "$OUT"
pass=0; fail=0

ORGANS="stoma_con"
for m in $ORGANS; do
    "$I2" "$A/$m.iii" --compile-only --out "$OUT/$m.o" 2>"$OUT/$m.c.log" \
        || { echo "FAIL $m : organ compile"; tail -3 "$OUT/$m.c.log"; exit 1; }
done

run() {
    local name="$1" want="$2"; shift 2
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" \
        || { echo "FAIL  $name : compile"; tail -3 "$OUT/$name.c.log"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" \
        || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head -3; fail=$((fail+1)); return; }
    timeout 60 "$OUT/$name.exe" >"$OUT/$name.run.log" 2>&1
    local rc=$?
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1));
    else echo "FAIL  $name : exit $rc (want $want)"; tail -2 "$OUT/$name.run.log"; fail=$((fail+1)); fi
}

run 2455_stoma_con 99 "$OUT/stoma_con.o"

echo "=== STOMA KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
