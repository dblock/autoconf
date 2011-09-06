@echo off
code2 autoconf.fr2 autocon2.inc
tasm manuel
tlink manuel

code2 autoconf.en2 autocon2.inc
copy manuel.asm manual.asm
tasm manual
tlink manual
del manual.asm
del *.obj
del *.map
c manuel.exe c:\utils
