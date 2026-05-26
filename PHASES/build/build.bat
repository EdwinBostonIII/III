@echo off
REM ============================================================================
REM III-PHASES — build script (Windows / MinGW)
REM ============================================================================
setlocal EnableExtensions

set ROOT=%~dp0..
set CC=gcc
set CFLAGS=-std=c11 -Wall -Wextra -Werror -O2 -I"%ROOT%\include" -I"%ROOT%\src"
set OBJDIR=%~dp0obj
set BUILDDIR=%~dp0
set OUT_LIB=%BUILDDIR%libiii_phases.a
set OUT_TEST=%BUILDDIR%iii_phases_test.exe
set OUT_TOOL=%BUILDDIR%iii_phases_tool.exe

if not exist "%OBJDIR%" mkdir "%OBJDIR%"

set OBJS=
for %%f in (mhash ring_lattice phase_poly marshal promotion epistemic_phase ghost_phase predictive runtime r1_a7) do (
    %CC% %CFLAGS% -c "%ROOT%\src\%%f.c" -o "%OBJDIR%\%%f.o" || goto :err
    set OBJS=!OBJS! "%OBJDIR%\%%f.o"
)
setlocal EnableDelayedExpansion
set OBJS=
for %%f in (mhash ring_lattice phase_poly marshal promotion epistemic_phase ghost_phase predictive runtime r1_a7) do (
    set OBJS=!OBJS! "%OBJDIR%\%%f.o"
)

ar rcs "%OUT_LIB%" !OBJS! || goto :err
%CC% %CFLAGS% "%ROOT%\tests\test_phases.c" "%OUT_LIB%" -o "%OUT_TEST%" || goto :err
%CC% %CFLAGS% "%ROOT%\tools\iii_phases_tool.c" "%OUT_LIB%" -o "%OUT_TOOL%" || goto :err

echo Build OK.
echo   %OUT_LIB%
echo   %OUT_TEST%
echo   %OUT_TOOL%
exit /b 0

:err
echo Build FAILED.
exit /b 1
