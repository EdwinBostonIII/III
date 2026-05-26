@echo off
setlocal enabledelayedexpansion
cd /d %~dp0..
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -Iinclude -I..\LEXICON\include
set SRC=src\closure.c src\hal_dispatch.c src\hal_x86_64.c src\hal_armv8.c src\hal_riscv_h.c src\hal_intel_vmx.c src\hal_power9.c
if not exist build\obj mkdir build\obj
for %%f in (%SRC%) do (
    set N=%%~nf
    gcc %CFLAGS% -c %%f -o build\obj\!N!.o || exit /b 1
)
ar rcs build\libiii_portability.a build\obj\closure.o build\obj\hal_dispatch.o build\obj\hal_x86_64.o build\obj\hal_armv8.o build\obj\hal_riscv_h.o build\obj\hal_intel_vmx.o build\obj\hal_power9.o || exit /b 1
gcc %CFLAGS% tools\iii_port_tool.c build\libiii_portability.a ..\LEXICON\build\libiii_lex.a -o build\iii_port_tool.exe || exit /b 1
gcc %CFLAGS% tests\iii_port_test.c build\libiii_portability.a ..\LEXICON\build\libiii_lex.a -o build\iii_port_test.exe || exit /b 1
echo BUILD OK
