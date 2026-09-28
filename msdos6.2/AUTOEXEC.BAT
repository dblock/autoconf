@ECHO OFF
CLS
ECHO.
ECHO  MS-DOS 6.22 multiple-configuration demonstration
ECHO.
ECHO  The %CONFIG% configuration has been selected and applied.
IF "%CONFIG%"=="A" ECHO  A - Minimal DOS
IF "%CONFIG%"=="B" ECHO  B - DOOM
IF "%CONFIG%"=="C" ECHO  C - Windows 95
ECHO.
VER
ECHO.
