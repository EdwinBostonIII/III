@echo off
REM III TYPES — build script (Windows / mingw-w64 gcc).
setlocal
cd /d %~dp0..
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -Iinclude -I..\LEXICON\include -I..\GRAMMAR\include
set LDFLAGS=-Wl,--allow-multiple-definition
if not exist build\obj mkdir build\obj

for %%F in (errors hexad cic type_repr bidir) do (
    echo CC src\%%F.c
    gcc %CFLAGS% -c src\%%F.c -o build\obj\%%F.o || exit /b 1
)

echo AR libiii_types.a
ar rcs build\libiii_types.a build\obj\errors.o build\obj\hexad.o build\obj\cic.o build\obj\type_repr.o build\obj\bidir.o || exit /b 1

echo CC tools\iii_types_tool.c
gcc %CFLAGS% tools\iii_types_tool.c build\libiii_types.a ..\LEXICON\build\libiii_lex.a %LDFLAGS% -o build\iii_types_tool.exe || exit /b 1

echo CC tests\test_main.c
gcc %CFLAGS% tests\test_main.c build\libiii_types.a ..\GRAMMAR\build\libiii_grammar.a ..\LEXICON\build\libiii_lex.a %LDFLAGS% -o build\iii_types_test.exe || exit /b 1

echo === build OK ===
endlocal
