@echo off
setlocal
cd /d "%~dp0\..\.."
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -IABI/include -ILEXICON/include -IGRAMMAR/include
set OBJDIR=ABI\build\obj
if not exist %OBJDIR% mkdir %OBJDIR%

echo == compiling library ==
for %%f in (ABI\src\abi_helpers.c ABI\src\abi_validate.c ABI\src\abi_lower.c ABI\src\abi_marshal.c) do (
    gcc %CFLAGS% -c %%f -o %OBJDIR%\%%~nf.o || goto :err
)

echo == archiving libiii_abi.a ==
ar rcs ABI\build\libiii_abi.a %OBJDIR%\abi_helpers.o %OBJDIR%\abi_validate.o %OBJDIR%\abi_lower.o %OBJDIR%\abi_marshal.o || goto :err

echo == building tool ==
gcc %CFLAGS% ABI\tools\iii_abi_tool.c ABI\build\libiii_abi.a GRAMMAR\build\libiii_grammar.a LEXICON\build\libiii_lex.a -Wl,--allow-multiple-definition -o ABI\build\iii_abi_tool.exe || goto :err

echo == building tests ==
gcc %CFLAGS% ABI\tests\test_abi.c ABI\build\libiii_abi.a GRAMMAR\build\libiii_grammar.a LEXICON\build\libiii_lex.a -Wl,--allow-multiple-definition -o ABI\build\iii_abi_test.exe || goto :err

echo == OK ==
exit /b 0
:err
echo == BUILD FAILED ==
exit /b 1
