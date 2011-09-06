locals

ProgramSize     equ     2000h

FileName        db      'SCREEN.DAT',0
FileHandle      dw      0       ; DOS file handle
MenuListBx      dw      ?

TypeMenuSel     struc
XPos    dw      ?       ;+0
YPos    dw      ?       ;+2
LenX    dw      ?       ;+4
LenY    dw      ?       ;+6
Id      dw      ?       ;+8 config id (A, F1, etc...)
Son     dw      ?       ;+10 =1 if menu entry has a subconfig
        ends
TMenuSelSize    equ     12

MaxDeep         equ     20      ; deepest level available
MaxGroups       equ     255
MaxMenuSel      equ     50      ; 1 per line
MenuLen         dw      0
MenuList        TypeMenuSel     MaxMenuSel dup (<0,0,0>)

CurMenuPos      dw      0       ; current position in menu list (0..MenuLen-1)
CurDisPos       dw      0
ScrLen          dw      25
ImageLen        dw      0

NbGroups        dw      0
TGroupInfo      struc
GroupId         dw      0       ; +0 equivalent to group's father
GroupOffset     dd      0       ; +2
                ends
TGroupInfoSize  equ     6

GroupInfoList   TGroupInfo      MaxGroups dup (<0,0>) ; might want to allocate
                                                      ; this instead...

GroupPos        dw      0
GroupBackTrace  dw      MaxDeep dup (0000h)

ScreenLen       dw      25*80*2

ImagePtr        dw      0       ; buffer for image

Exit            db      0       ; boolean exit variable, 0=no exit
ChangeGroup     db      0       ; boolean variable, 1=change
NewGroup        dw      0       ; ID of group to change to

DOSErrorMsgs    label   word
                dw      offset DOSError1
                dw      offset DOSError2
                dw      offset DOSError3
                dw      offset DOSError4
                dw      offset DOSError5
                dw      offset DOSError6
                dw      offset DOSError7
                dw      offset DOSError8
                dw      offset DOSError9
                dw      offset DefaultError
                dw      offset DefaultError
                dw      offset DOSError12
                dw      offset DataError
                dw      offset DOSError14

; Called after a DOS error, displays error messages and does some other stuff
; Input : AX = DOS error code
TreatError      proc
        dec     ax
        shl     ax, 1
        mov     di, ax
        mov     bx, DOSErrorMsgs[di]
	call    newing
        call    slam_enter
        stc
        ret
TreatError      endp

AllocImage      proc
        mov     ax, 8000h       
        mov     [ImagePtr], ax
        ret
AllocImage      endp

;哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌
;                              SUBROUTINE
;苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘苘

; Loads display from current data file and displays it to the screen
LoadImage       proc

        call    AllocImage

; First let's read the number of lines data...
        mov     bx, [FileHandle]
        mov     cx, 2
        mov     dx, offset ScreenLen
        mov     ah, 3Fh                 ; read file to buffer
        int     21h
        jc      @@TreatError

@@LoadScreen:
        mov     ax, [ScreenLen]
        mov     [ImageLen], ax
        shl     ax, 1
        mov     cx, 80
        mul     cx      ; this implies a maximum of 65536/160=409 lines !!!
        mov     cx, ax
        push    ds
        mov     ax, [ImagePtr]
        mov     ds, ax
        mov     dx, 0
        mov     ah, 3Fh                 ; read file to buffer (here screen!)
        int     21h
        pop     ds
        jc      @@TreatError
        cmp     ax, cx                  ; did we read the right number of bytes?
        je      @@ItsOK
        mov     ax, 13
        jmp     @@TreatError
@@ItsOK:
        ret
@@TreatError:
        call    TreatError
        ret
LoadImage       endp

; Might have to be changed to add stuff for menus that don't exist...
DisplayScreen   proc
        push    es
        mov     ax, cs:[v_mode]
        mov     es, ax

        mov     ax, [CurDisPos]
        mov     cx, 160
        mul     cx
        mov     si, ax
        mov     ax, [ScrLen]
        mov     cx, 160
        mul     cx
        mov     cx, ax

        push    ds
        mov     ax, [ImagePtr]
        mov     ds, ax
        xor     di, di
        rep     movsb
        pop     ds

        pop     es
        ret
DisplayScreen   endp

; Loads menu selection from current data file
LoadSelections  proc
        mov     bx, [FileHandle]
        mov     cx, 1                   ; maximum 255 entries
        mov     dx, offset MenuLen
        mov     ah, 3Fh                 ; read file to buffer
        int     21h
        jc      @@TreatError

        mov     ax, [MenuLen]
        mov     cx, TMenuSelSize        ; structure size
        mul     cx
        mov     cx, ax
        mov     dx, offset MenuList     ; point to start of list

        mov     ah, 3Fh
        int     21h
        jc      @@TreatError

        cmp     ax, cx
        je      @@ItsOK
        mov     ax, 13
        jmp     @@TreatError
@@ItsOK:
        ret
@@TreatError:
        call    TreatError
        ret
LoadSelections  endp

OpenFile        proc
        mov     ax, 3D00h       ; open file for read-only
        mov     dx, offset FileName
        int     21h
        jc      @@TreatError
        mov     [FileHandle], ax
        ret
@@TreatError:
        mov     [FileHandle], 0
        call    TreatError
        ret
OpenFile        endp

CloseFile       proc
        mov     ah, 3Eh
        mov     bx, [FileHandle]
        int     21h
        jc      @@TreatError
        ret
@@TreatError:
        call    TreatError
CloseFile       endp

Hightlight      proc
        mov     ax, [CurMenuPos]
        mov     cx, TMenuSelSize
        mul     cx
        mov     bx, ax

        push    es
        mov     ax, cs:[v_mode] 
        mov     es, ax

        mov     ax, MenuList[bx].Id
        mov     cs:[MenuListBx],bx
        mov     ax, MenuList[bx].YPos      ; Get YPos
        sub     ax, [CurDisPos]
        mov     cx, 160
        mul     cx
        mov     cx, MenuList[bx].XPos
        add     ax, cx
        add     ax, cx
        inc     ax
        ; now AX contains position to start hightlighting...
        mov     di, ax
        mov     cx, MenuList[bx].LenY
@@NextLine:
        push    cx
        mov     cx, MenuList[bx].LenX      ; Get len
        mov     al, 0FFh

        push    di
@@NextByte:
        xor     es:[byte ptr di], al
        inc     di
        inc     di
        loop    @@NextByte

        pop     di
        add     di, 160
        pop     cx
        loop    @@NextLine
        pop     es
        ret
Hightlight      endp

IdleAnimate     proc
        ret
IdleAnimate     endp

ProcessKey      proc
        xor     ax,ax
        mov     ah,0Ch
        int     21h                     ;clear the keyboard buffer
@@WaitLoop:
        call    IdleAnimate             ; animate something while waiting
        mov     ax, 0100h
        int     16h
        jc      @@WaitLoop

        xor     ax,ax
        int     16h

        push    ax
        call    HightLight              ; unhighlight the current position
        pop     ax

        cmp     ax, 4800h               ; arrow up
        jne     @@NextTest1
        dec     [CurMenuPos]
        jmp     @@DoClipping
@@NextTest1:
        cmp     ax, 5000h               ; arrow down
        jne     @@NextTest2
        inc     [CurMenuPos]
        jmp     @@DoClipping
@@NextTest2:
        cmp     ax, 4D00h               ; arrow right
        jne     @@NextTest3
        mov     ax, [CurMenuPos]
        mov     cx, TMenuSelSize
        mul     cx
        mov     bx, ax
        mov     ax, MenuList[bx].Son
        cmp     ax, 0
        je      @@DoClipping            ; no son available
        mov     [ChangeGroup], 1
        mov     [NewGroup], ax
        inc     [GroupPos]
        mov     bx, [GroupPos]
        shl     bx, 1
        mov     GroupBackTrace[bx], ax
        jmp     @@DoClipping
@@NextTest3:
        cmp     ax, 4B00h               ; arrow left
        jne     @@NextTest4
        cmp     [GroupPos], 0
        jle     @@DoClipping
        mov     bx, [GroupPos]
        shl     bx, 1
        mov     GroupBackTrace[bx], 0
        dec     [GroupPos]
        mov     ax, GroupBackTrace[bx-2]
        mov     [NewGroup], ax
        mov     [ChangeGroup], 1
        jmp     @@DoClipping
@@NextTest4:
        cmp     al,13
        jne     @@DoClipping
         mov    bx,cs:[MenuListBx]
         mov    ax,MenuList[bx].Id
         mov    cs:[ext],0
         cmp    ah,1
         jne    @@not_ext_choose
         mov    cs:[ext],1
@@not_ext_choose:
         mov    cs:[config],al

        lds    bx,cs:[dword ptr req_ofs]       ;initialisation
        lds    si,[bx+18]                      ; si <- CONFIG.SYS position
        call   verifie_config
        jc     @@DoClipping

        mov     cs:[chosenlist],1
        mov     [Exit], 1
        jmp     @@ExitProc

@@DoClipping:
        ; Now some clipping
        cmp     [CurMenuPos],0
        jge     @@BelowOk
        mov     ax, [MenuLen]
        dec     ax
        mov     [CurMenuPos], ax
        jmp     @@CheckScroll
@@BelowOk:
        mov     ax, [MenuLen]
        dec     ax
        cmp     [CurMenuPos], ax
        jle     @@CheckScroll
        mov     [CurMenuPos], 0

@@CheckScroll:
        mov     ax, [CurMenuPos]
        mov     cx, TMenuSelSize
        mul     cx
        mov     bx, ax

        mov     ax, MenuList[bx].YPos      ; Get YPos
        add     ax, MenuList[bx].LenY
        cmp     ax, [ScrLen]
        jbe     @@SkipFix1
        sub     ax, [ScrLen]
        mov     [CurDisPos], ax
        call    DisplayScreen
@@SkipFix1:
        mov     ax, MenuList[bx].YPos
        cmp     ax, [CurDisPos]
        jae     @@SkipFix2
        mov     [CurDisPos], ax
        call    DisplayScreen
@@SkipFix2:
@@ExitProc:
        ret
ProcessKey      endp

; Input:
;   AL = 0 : from start of file
;        1 : from actual pos
;        2 : from end of file
;   CX:DX  : longint for seek (CX high, DX low)
; Ouput:
;   DX:AX  : longint for file pos
FSeek   proc
        mov     ah, 42h         ; Seek in file
        mov     bx, [FileHandle]
        int     21h
        jc      @@TreatError
        ret
@@TreatError:
        cmp     ax, 1
        jne     @@SkipFix
        mov     ax, 14
@@SkipFix:
        call    TreatError
        ret
FSeek   endp

LoadGroupInfo   proc
        mov     al, 2
        mov     cx, 0FFFFh
        mov     dx, 2
        neg     dx

        call    FSeek

; First let's read the number of groups...
        mov     bx, [FileHandle]
        mov     cx, 2
        mov     dx, offset NbGroups
        mov     ah, 3Fh                 ; read file to buffer
        int     21h
        jc      @@TreatError

        movzx   eax, NbGroups
        mov     ecx, TGroupInfoSize
        mul     ecx
        mov     ebx, eax
        add     ebx, 2
        neg     ebx
        mov     dx, bx
        shr     ebx, 16
        mov     cx, bx
        mov     al, 2
        call    FSeek

        mov     ax, [NbGroups]
        mov     cx, TGroupInfoSize        ; structure size
        mul     cx
        mov     cx, ax
        mov     dx, offset GroupInfoList     ; point to start of list

        mov     ah, 3Fh
        int     21h
        jc      @@TreatError

        cmp     ax, cx
        je      @@ItsOK
        mov     ax, 13
        jmp     @@TreatError
@@ItsOK:

        mov     al, 0
        mov     cx, 0
        mov     dx, 0
        call    FSeek                   ; go to beginning of file

        ret

@@TreatError:
        call    TreatError
        ret
LoadGroupInfo   endp

; Input : AX = id to search
; Output : EAX = offset in file = 0FFFFFFFFh if it wasn't found !
SearchGroup     proc
        mov     cx, [NbGroups]
        mov     bx, 0
@@SearchLoop:
        mov     dx, GroupInfoList[bx].GroupId
        cmp     ax, dx
        je      @@FoundIt
        add     bx, TGroupInfoSize
        loop    @@SearchLoop
        mov     eax, 0FFFFFFFFh         ; returned if it wasn't found
        ret
@@FoundIt:
        mov     eax, GroupInfoList[bx].GroupOffset
        ret
SearchGroup     endp

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
; iLOOM 1.0
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
iloom    proc
        clc
        pushx   ax,bx,cx,dx,es,si,di,ds
        cmp     cs:[@fifty],1
        jne     il_nfifty
        mov     ax,50*80*2
        mov     cs:[ScreenLen],ax
        mov     cs:[ScrLen],50
   il_nfifty:
        call    force_efface_ecran
        push    cs
        pop     ds
@@ProcessGroup:

        mov     [CurMenuPos], 0
        mov     [ChangeGroup], 0

        mov     ax, NewGroup
        call    SearchGroup
        cmp     eax, 0FFFFFFFFh
        jne     @@GroupFound
        jmp     iloom_exit
@@GroupFound:
        mov     dx, ax
        shr     eax, 16
        mov     cx, ax
        mov     al, 0
        call    FSeek

        call    LoadSelections
        jc      iloom_exit
        call    LoadImage
        jc      iloom_exit

        call    DisplayScreen
        jc      iloom_exit

@@KeyLoop:
        call    Hightlight      ; hightlight current line
        jc      iloom_exit
        call    ProcessKey
        jc      iloom_exit

        cmp     [ChangeGroup], 0
        je      @@SkipProcessGroup
        jmp     @@ProcessGroup
@@SkipProcessGroup:

        cmp     [Exit], 0
        je      @@KeyLoop

        call    CloseFile
iloom_exit:
        popx    ds,di,si,es,dx,cx,bx,ax
        call    force_efface_ecran
        clc
        ret
iloom   endp

; Filename format is :
;
;   Group 1
;   Group 2
;   ...
;   GroupInfoList
;   NumberOfGroups (word)
;
; where a group is structured as follow:
;
; offset
;
;  +00 - Number of menu selections (byte)
;  +01 - X pos for menu selection 1 (word)
;  +03 - Y pos for menu selection 1
;  +05 - X Length of selection 1
;  +07 - Y Length of selection 1
;  +09 - Id of selection 1 (if hibyte = 1 then it's an extended key)
;  +11 - Son of selection 1 (if nonzero, contains son group number)
;  +13 - X pos for menu slection 2
;   ...
;
; After all the menu selection are read...
;
;   beginning of screen data.
;   00 - number of lines in file
;   01 - attribute for pos 0,0
;   02 - character for pos 0,0
;   03 - attribute for pos 1,0
;   04 - character for pos 1,0
;   etc... until completition at 80xnumber of lines
;
; GroupInfoList format :
;
;   GroupInfo1
;   GroupInfo2
;   ...
;
; GroupInfo format :
;
;  +00 - word, id for group
;  +04 - dword, offset in file for the corresponding group
;

