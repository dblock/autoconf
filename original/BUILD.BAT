@echo off
JWASMR -Zm -bin -FoAUTOCONF.SYS AUTOCONF.ASM
if errorlevel 1 goto error

JWASMR -Zm -bin -FoREADCONF.COM READCONF.ASM
if errorlevel 1 goto error

echo Built AUTOCONF.SYS and READCONF.COM.
goto end

:error
echo Build failed.

:end
