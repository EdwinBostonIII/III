@echo off
rem III Grammar - Windows build script (mingw-w64 gcc).
setlocal enabledelayedexpansion

set ROOT=%~dp0..
set III=%ROOT%\..
set LEX=%III%\LEXICON
set GRAM=%ROOT%
set BUILD=%GRAM%\build
set OBJ=%BUILD%\obj

if not defined CC set CC=gcc
if not defined AR set AR=ar
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -I"%GRAM%\include" -I"%LEX%\include"
rem --allow-multiple-definition: workaround for Agent-C duplicate
rem `iiip_parse_qualified_name` in parse_module.c+parse_type.c.
set LDFLAGS=-Wl,--allow-multiple-definition

if not exist "%OBJ%"        mkdir "%OBJ%"
if not exist "%OBJ%\tests"  mkdir "%OBJ%\tests"

if not exist "%LEX%\build\libiii_lex.a" (
    echo ERROR: %LEX%\build\libiii_lex.a missing.  Build LEXICON first.
    exit /b 1
)

echo ==^> Compiling GRAMMAR sources
for %%F in ("%GRAM%\src\*.c") do (
    %CC% %CFLAGS% -c "%%F" -o "%OBJ%\%%~nF.o" || exit /b 1
)

echo ==^> Archiving libiii_grammar.a
if exist "%BUILD%\libiii_grammar.a" del "%BUILD%\libiii_grammar.a"
%AR% rcs "%BUILD%\libiii_grammar.a" "%OBJ%\*.o" || exit /b 1

if exist "%GRAM%\tools\iii_parse_tool.c" (
    echo ==^> Linking iii_parse_tool.exe
    %CC% %CFLAGS% -o "%BUILD%\iii_parse_tool.exe" ^
        "%GRAM%\tools\iii_parse_tool.c" ^
        "%BUILD%\libiii_grammar.a" ^
        "%LEX%\build\libiii_lex.a" ^
        %LDFLAGS% || exit /b 1
)

if exist "%GRAM%\tests\test_main.c" (
    echo ==^> Compiling tests
    set TEST_OBJS=
    for %%F in ("%GRAM%\tests\*.c") do (
        %CC% %CFLAGS% -c "%%F" -o "%OBJ%\tests\%%~nF.o" || exit /b 1
        set TEST_OBJS=!TEST_OBJS! "%OBJ%\tests\%%~nF.o"
    )
    echo ==^> Linking iii_grammar_test.exe
    %CC% %CFLAGS% -o "%BUILD%\iii_grammar_test.exe" ^
        !TEST_OBJS! ^
        "%BUILD%\libiii_grammar.a" ^
        "%LEX%\build\libiii_lex.a" ^
        %LDFLAGS% || exit /b 1
)

echo ==^> Done.
echo   lib:  %BUILD%\libiii_grammar.a
if exist "%BUILD%\iii_parse_tool.exe"   echo   tool: %BUILD%\iii_parse_tool.exe
if exist "%BUILD%\iii_grammar_test.exe" echo   test: %BUILD%\iii_grammar_test.exe
exit /b 0
