@echo off
cmpdate
del /Q *.zip

copy /Q bootit.fr bootit.cpp
bcc -Ie:\prog\bc\include -Le:\prog\bc\lib bootit.cpp

tasm /t clrbuf.asm
tasm /t clrbuff.asm
tlink /t clrbuf
tlink clrbuff
c:\dos\EXE2bin clrbuff clrbuf.sys
del clrbuff.exe
del /Q *.obj
del /Q *.map


code2 autoconf.fr2 autocon2.inc
tasm /t manuel
tlink manuel
del /Q *.tm?
code2 autoconf.fr
tasm /t autoconf
tlink autoconf
c:\dos\EXE2bin autoconf autoconf.sys
copy /Q autoconf.sys c:\utils
del /Q *.obj 
del /Q *.map 
del /Q autoconf.exe
del /Q *.tm?

cd readconf
bcc -Ie:\prog\bc\include -Le:\prog\bc\lib readconf.fr
del /Q *.obj
del /Q *.map
cd..

copy /Q file_id.f file_id.diz

pkunzip \prog\daniel\extrakt\acfcnvf.zip *.exe *.cnv
pkzip acnf3b1f.zip autoconf.sys manuel.exe whatsnew.fr bootit.exe clrbuf.sys clrbuf.com file_id.diz 
pkzip acnf3b1f.zip acf2dos.exe dos2acf.exe notesrel.cnv unrf.exe readconf\readconf.exe

copy /Q bootit.eng bootit.cpp
bcc -Ie:\prog\bc\include -Le:\prog\bc\lib bootit.cpp


code2 autoconf.en2 autoconf.inc
copy /Q manuel.asm manual.asm
tasm /t manual
tlink manual
del /Q manual.asm
del /Q *.obj
del /Q *.map
del /Q *.tm?
code2 autoconf.eng
tasm /t autoconf
tlink autoconf
c:\dos\EXE2bin autoconf autoconf.sys
copy /Q autoconf.sys c:\utils
del /Q *.obj 
del /Q *.map 
del /Q autoconf.exe
del /Q *.tm?

cd readconf
bcc -Ie:\prog\bc\include -Le:\prog\bc\lib readconf.eng
del /Q *.obj
del /Q *.map
cd..

copy /Q file_id.e file_id.diz

copy /Q acf2dos.exe C:\utils
copy /Q dos2acf.exe c:\utils
copy /Q unrf.exe c:\utils
del /Q acf2dos.exe
del /Q dos2acf.exe
del /Q unrf.exe

pkunzip \prog\daniel\extrakt\acfcnve.zip *.exe *.cnv
pkzip acnf3b1e.zip autoconf.sys manual.exe whatsnew.eng bootit.exe clrbuf.sys clrbuf.com file_id.diz 
pkzip acnf3b1e.zip relnotes.cnv acf2dos.exe dos2acf.exe unrf.exe readconf\readconf.exe

del /Q file_id.diz
del /Q bootit.cpp
del /Q acf2dos.exe
del /Q dos2acf.exe
del /Q unrf.exe
del /Q *.cnv
copy /Q manuel.exe c:\utils
copy /Q bootit.exe c:\utils
del  /Q *.bak

pkunzip -t acnf3b1e.zip
pkunzip -t acnf3b1f.zip
