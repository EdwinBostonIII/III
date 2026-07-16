#!/usr/bin/env bash
# run_iform_kats.sh -- STANDALONE gate for III's sovereign NIH image substrate:
#   iform.iii            (.ixr = III eXact Raster: lossless 32-bit ARGB, embedded FNV integrity sig, generator bind)
#   iscene.iii           (.isc = III Scene: resolution-INDEPENDENT exact master on the aether_lens exact ray-cast core)
#   2199_iform.iii       (proves .ixr supersedes .bmp: lossless-alpha round-trip, self-verify, tamper-detect, header, bind, determinism)
#   2200_iscene.iii      (proves .isc supersedes a raster: resolution-independence, lossless generator round-trip, .ixr binding)
# Kept DISJOINT from the other aether gates so concurrent edits cannot collide.  kernel32-only I/O -- no image library.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
OUT="$(mktemp -d)"
pass=0; fail=0

"$I2" "$A/iform.iii" --compile-only --out "$OUT/iform.o" 2>"$OUT/iform.log" || { echo "FAIL iform compile"; cat "$OUT/iform.log"; exit 1; }
echo "PASS  iform           : compiles (.ixr sovereign exact-raster container -- kernel32-only, no image library)"
for m in sqrt_sum_sign kfield aether_lens iscene; do
    "$I2" "$A/$m.iii" --compile-only --out "$OUT/$m.o" 2>"$OUT/$m.log" || { echo "FAIL $m compile"; cat "$OUT/$m.log"; exit 1; }
done
echo "PASS  iscene          : compiles (.isc resolution-independent scene master on the aether_lens exact core)"

# run <corpus-name> <want-exit> <workdir> <link objs...>
run() {
    local name="$1" want="$2" wd="$3"; shift 3
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" || { echo "FAIL  $name : compile"; sed -n '1,20p' "$OUT/$name.c.log"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head; fail=$((fail+1)); return; }
    local st="$OUT/${name}.run.exe"; cp "$OUT/$name.exe" "$st"
    ( cd "$wd" && timeout 120 "$st" ); local rc=$?
    rm -f "$st"
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1)); else echo "FAIL  $name : exit $rc (want $want)"; fail=$((fail+1)); fi
}

run 2199_iform   99 "$OUT" "$OUT/iform.o"   # .ixr proven superior to .bmp: lossless-alpha RT + self-verify + tamper-detect + bind + determinism
run 2200_iscene  99 "$OUT" "$OUT/iscene.o" "$OUT/iform.o" "$OUT/aether_lens.o" "$OUT/sqrt_sum_sign.o" "$OUT/kfield.o" "$LIB"   # .isc master: resolution-independence + lossless generator round-trip + .ixr generator-binding

echo "=== III-FORM gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
