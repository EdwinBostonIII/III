@echo off
REM Windows build for III lexicon (MSVC cl.exe).
setlocal
cd /d "%~dp0\.."
if not exist build\obj mkdir build\obj
set CFLAGS=/nologo /W3 /O2 /Iinclude /D_CRT_SECURE_NO_WARNINGS
echo [1/3] compiling library
for %%f in (src\*.c) do (
    cl %CFLAGS% /c %%f /Fobuild\obj\%%~nf.obj || goto :error
)
lib /nologo /OUT:build\iii_lex.lib build\obj\*.obj || goto :error

echo [2/3] linking tool
cl %CFLAGS% tools\iii_lex_tool.c build\iii_lex.lib /Fobuild\obj\iii_lex_tool.obj /Febuild\iii_lex_tool.exe /link /SUBSYSTEM:CONSOLE || goto :error

echo [3/3] linking tests
cl %CFLAGS% tests\*.c build\iii_lex.lib /Fobuild\obj\ /Febuild\iii_lex_test.exe /link /SUBSYSTEM:CONSOLE || goto :error
echo OK
exit /b 0
:error
echo BUILD FAILED
exit /b 1
