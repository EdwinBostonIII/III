@echo off
REM Build LEGACY-INGESTION with gcc.
setlocal
cd /d "%~dp0\.."
if not exist build\obj mkdir build\obj
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -Iinclude -I..\LEXICON\include
set LEXLIB=..\LEXICON\build\libiii_lex.a

echo [1/4] compiling library
for %%f in (src\*.c) do (
    gcc %CFLAGS% -c %%f -o build\obj\%%~nf.o || goto :error
)
echo [2/4] archiving libiii_legacy.a
ar rcs build\libiii_legacy.a build\obj\detect.o build\obj\elf.o build\obj\pe.o build\obj\macho.o build\obj\coff.o build\obj\normalize.o build\obj\syscall.o build\obj\sandbox.o || goto :error

echo [3/4] linking tool
gcc %CFLAGS% tools\iii_legacy_tool.c build\libiii_legacy.a %LEXLIB% -o build\iii_legacy_tool.exe || goto :error

echo [4/4] linking tests
gcc %CFLAGS% tests\test_main.c tests\fixtures.c build\libiii_legacy.a %LEXLIB% -o build\iii_legacy_test.exe || goto :error

echo OK
exit /b 0
:error
echo BUILD FAILED
exit /b 1
