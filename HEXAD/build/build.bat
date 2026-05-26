@echo off
REM III HEXAD — build (Windows / mingw-w64 gcc).
setlocal
cd /d %~dp0..
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -Iinclude -I..\LEXICON\include -I..\TYPES\include
set LDFLAGS=

if not exist build\obj mkdir build\obj

for %%F in (hexad_algebra hexad_reach hexad_pfs hexad_dynamic hexad_epistemic hexad_mobius types_bridge) do (
    echo CC src\%%F.c
    gcc %CFLAGS% -c src\%%F.c -o build\obj\%%F.o || exit /b 1
)

echo AR libiii_hexad.a
ar rcs build\libiii_hexad.a ^
    build\obj\hexad_algebra.o ^
    build\obj\hexad_reach.o ^
    build\obj\hexad_pfs.o ^
    build\obj\hexad_dynamic.o ^
    build\obj\hexad_epistemic.o ^
    build\obj\hexad_mobius.o ^
    build\obj\types_bridge.o || exit /b 1

echo CC tools\iii_hexad_tool.c
gcc %CFLAGS% tools\iii_hexad_tool.c build\libiii_hexad.a ..\TYPES\build\libiii_types.a ..\LEXICON\build\libiii_lex.a %LDFLAGS% -o build\iii_hexad_tool.exe || exit /b 1

echo CC tests\hexad_test.c
gcc %CFLAGS% tests\hexad_test.c build\libiii_hexad.a ..\TYPES\build\libiii_types.a ..\LEXICON\build\libiii_lex.a %LDFLAGS% -o build\iii_hexad_test.exe || exit /b 1

echo === build OK ===
endlocal
