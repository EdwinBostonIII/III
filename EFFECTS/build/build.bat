@echo off
REM III EFFECTS — build script (Windows / mingw-w64 gcc).
REM RITCHIE Stage 1.22: authored to match TYPES/HEXAD; builds the library,
REM the conformance test, AND iii_effects_tool.exe (which had source but was
REM never built). Links against LEXICON (lex/sha256/arena) + GRAMMAR
REM (parser/parse_arena) + the EFFECTS library itself.
setlocal
cd /d %~dp0..
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -Iinclude -I..\LEXICON\include -I..\GRAMMAR\include -I..\TYPES\include
set LDFLAGS=-Wl,--allow-multiple-definition
if not exist build\obj mkdir build\obj

echo CC src\effects.c
gcc %CFLAGS% -c src\effects.c -o build\obj\effects.o || exit /b 1

echo AR libiii_effects.a
ar rcs build\libiii_effects.a build\obj\effects.o || exit /b 1

echo CC tools\iii_effects_tool.c
gcc %CFLAGS% tools\iii_effects_tool.c build\libiii_effects.a ..\TYPES\build\libiii_types.a ..\GRAMMAR\build\libiii_grammar.a ..\LEXICON\build\libiii_lex.a %LDFLAGS% -o build\iii_effects_tool.exe || exit /b 1

echo CC tests\test_effects.c
gcc %CFLAGS% tests\test_effects.c build\libiii_effects.a ..\TYPES\build\libiii_types.a ..\GRAMMAR\build\libiii_grammar.a ..\LEXICON\build\libiii_lex.a %LDFLAGS% -o build\iii_effects_test.exe || exit /b 1

echo === build OK ===
endlocal
