@echo off
REM III CONSTANTS — gcc (MinGW) build for Windows.
setlocal
cd /d "%~dp0"
if not exist obj mkdir obj

set CC=gcc
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -I..\include -I..\..\LEXICON\include
set LEX_LIB=..\..\LEXICON\build\libiii_lex.a

echo [1/3] compiling library
for %%f in (..\src\*.c) do (
    %CC% %CFLAGS% -c %%f -o obj\%%~nf.o || goto :error
)
ar rcs libiii_constants.a obj\*.o || goto :error

echo [2/3] linking tool
%CC% %CFLAGS% ..\tools\iii_constants_tool.c libiii_constants.a %LEX_LIB% -o iii_constants_tool.exe || goto :error

echo [3/3] linking tests
%CC% %CFLAGS% ..\tests\test_constants.c libiii_constants.a %LEX_LIB% -o iii_constants_test.exe || goto :error

echo OK
exit /b 0
:error
echo BUILD FAILED
exit /b 1
