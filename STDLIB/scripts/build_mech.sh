#!/usr/bin/env bash
# build_mech.sh -- build III MECH (mech.exe): the exact 4-bar mechanism workbench.
# Compiles the app + its exact-math organs with the in-tree iiis-2 and links one native exe.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
LIB="$III/STDLIB/build/iii/libiii_native.a"
O="${MECH_OUT:-$(mktemp -d)}"
mkdir -p "$O"

MODS="mech fourbar sturm sqrt_sum_sign kfield cyclotomic_se3 q23_sign verb_geom"

for m in $MODS; do
    "$I2" "$A/$m.iii" --compile-only --out "$O/$m.o" 2>"$O/$m.log" || { echo "FAIL compile $m"; cat "$O/$m.log"; exit 1; }
done
echo "compile: all modules OK"

gcc "$O/mech.o" "$O/fourbar.o" "$O/sturm.o" "$O/sqrt_sum_sign.o" "$O/kfield.o" \
    "$O/cyclotomic_se3.o" "$O/q23_sign.o" "$O/verb_geom.o" \
    "$LIB" -lkernel32 -o "$III/mech.exe" 2>"$O/link.log" \
    || { echo "FAIL link"; grep -i "undefined" "$O/link.log" | head -20; exit 1; }
echo "link: mech.exe OK"
ls -la "$III/mech.exe"
