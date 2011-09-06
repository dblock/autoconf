@echo off
cmpdate

back
rem path=%path%;c:\dos;
if "%1"=="f" goto codeitf
if "%1"=="e" goto codeite
goto dontcode

:codeitf
code2 autoconf.fr 
goto code
:codeite
code2 autoconf.eng
:code

rem echo Assembling AUTOCONF.ASM - main prog
rem echo Assembling AUTOCONF.INC - coded file

del *.tm? 

:dontcode
tasm autoconf 
tlink autoconf
c:\dos\exe2bin autoconf autoconf.sys

c autoconf.sys c:\utils
del *.obj 
del *.map 
del autoconf.exe 
rem smartdrv/c


