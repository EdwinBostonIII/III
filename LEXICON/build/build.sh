#!/usr/bin/env bash
# Unix build for III lexicon.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/obj
CFLAGS="-std=c11 -Wall -Wextra -Wno-unused-parameter -O2 -Iinclude"
SRC=$(ls src/*.c)
echo "[1/3] compiling library"
for f in $SRC; do
    o="build/obj/$(basename "$f" .c).o"
    cc $CFLAGS -c "$f" -o "$o"
done
ar rcs build/libiii_lex.a build/obj/*.o

echo "[2/3] linking tool"
cc $CFLAGS tools/iii_lex_tool.c -o build/iii_lex_tool build/libiii_lex.a

echo "[3/3] linking tests"
cc $CFLAGS tests/*.c -o build/iii_lex_test build/libiii_lex.a

echo "OK"
