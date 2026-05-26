#!/bin/sh
# III Grammar — POSIX build script.
# Builds: libiii_grammar.a, iii_parse_tool, iii_grammar_test.
# Requires: gcc, ar.  Depends on LEXICON having been built.
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
III_DIR="$(cd "$ROOT_DIR/.." && pwd)"
LEX_DIR="$III_DIR/LEXICON"
GRAM_DIR="$ROOT_DIR"
BUILD_DIR="$GRAM_DIR/build"
OBJ_DIR="$BUILD_DIR/obj"

CC=${CC:-gcc}
AR=${AR:-ar}
CFLAGS="-std=c11 -Wall -Wextra -Wpedantic -Werror -O2 -I$GRAM_DIR/include -I$LEX_DIR/include"
LDFLAGS=""

# Detect Windows (MSYS / Cygwin / MinGW) for .exe suffix.
EXE=""
case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*|Windows_NT) EXE=".exe" ;;
esac

mkdir -p "$OBJ_DIR" "$OBJ_DIR/tests"

# 1) Build LEXICON if missing.
if [ ! -f "$LEX_DIR/build/libiii_lex.a" ]; then
    echo "==> Building LEXICON dependency"
    if [ -x "$LEX_DIR/build/build.sh" ]; then
        ( cd "$LEX_DIR" && sh build/build.sh )
    else
        echo "ERROR: $LEX_DIR/build/libiii_lex.a missing and no build.sh found" >&2
        exit 1
    fi
fi

# 2) Compile every src/*.c into obj/*.o.
echo "==> Compiling GRAMMAR sources"
for src in "$GRAM_DIR/src/"*.c; do
    [ -f "$src" ] || continue
    base="$(basename "$src" .c)"
    $CC $CFLAGS -c "$src" -o "$OBJ_DIR/$base.o"
done

# 3) Archive into libiii_grammar.a.
echo "==> Archiving libiii_grammar.a"
rm -f "$BUILD_DIR/libiii_grammar.a"
$AR rcs "$BUILD_DIR/libiii_grammar.a" "$OBJ_DIR/"*.o

# 4) Compile + link the tool.
if [ -f "$GRAM_DIR/tools/iii_parse_tool.c" ]; then
    echo "==> Linking iii_parse_tool"
    $CC $CFLAGS -o "$BUILD_DIR/iii_parse_tool$EXE" \
        "$GRAM_DIR/tools/iii_parse_tool.c" \
        "$BUILD_DIR/libiii_grammar.a" \
        "$LEX_DIR/build/libiii_lex.a" \
        $LDFLAGS
fi

# 5) Compile + link the test runner.
if ls "$GRAM_DIR/tests/"*.c >/dev/null 2>&1; then
    echo "==> Compiling tests"
    TEST_OBJS=""
    for src in "$GRAM_DIR/tests/"*.c; do
        base="$(basename "$src" .c)"
        $CC $CFLAGS -c "$src" -o "$OBJ_DIR/tests/$base.o"
        TEST_OBJS="$TEST_OBJS $OBJ_DIR/tests/$base.o"
    done
    echo "==> Linking iii_grammar_test"
    $CC $CFLAGS -o "$BUILD_DIR/iii_grammar_test$EXE" \
        $TEST_OBJS \
        "$BUILD_DIR/libiii_grammar.a" \
        "$LEX_DIR/build/libiii_lex.a" \
        $LDFLAGS
fi

echo "==> Done."
echo "  lib:  $BUILD_DIR/libiii_grammar.a"
[ -f "$BUILD_DIR/iii_parse_tool$EXE"   ] && echo "  tool: $BUILD_DIR/iii_parse_tool$EXE"
[ -f "$BUILD_DIR/iii_grammar_test$EXE" ] && echo "  test: $BUILD_DIR/iii_grammar_test$EXE"
