;THIS IS A SOURSE FOR SAMPLE SYS FILES RUN FROM CONFIG SYS BY DEVICE=
;pointer si is after launched line
;                                       parts by Daniel Doubrovkine

;----------------------------------------------------------------------------
; This code is so simple I just couldn't beleive it. So forget about all
; books on assembler, cause this DOES ALWAYS WORK and is the shortest way
; to do it!
;----------------------------------------------------------------------------

.MODEL tiny                     ;very little model
.CODE

pushx macro r1, r2, r3, r4, r5, r6, r7, r8      ;that's a usefull macro
	ifnb <r1>                               ;stolen it from the source
	push r1                                 ;of a 3D vector engine...
	pushx r2, r3, r4, r5, r6, r7, r8        ;pushx + 8 registers max
	endif                                   
endm                                            ;assembled depending from
						;pushed quantity
popx macro r1, r2, r3, r4, r5, r6, r7, r8
	ifnb <r1>
	pop r1  
	popx r2, r3, r4, r5, r6, r7, r8
	endif
endm

ORG 0000h               ;INDESPENSABLE, SINCE OTHERWISE IT STUCKS

driver_suiv     dw      -1                      ;ALL THIS IS NECESSARY FOR
		dw      -1                      ;DOS COMPATIBILITY AND 
attribut        dw      8004h                   ;CONFLICT AVOID, if you remove
req             dw      offset sys_request      ;it will stuck the machine
run             dw      offset init             ;CRAZY DOS!!!!
nom_device      db      'NUL    '

new_device proc
	nreq:   or      es:word ptr [bx+3],0100h        ;STORE SEGMENT ADRESSES
	nrun:   ret                                     ;bla bla bla
new_device endp

fin_residant label near

;immidiate variables

req_ofs         dw      ?
req_seg         dw      ?

sys_request proc far
	mov     cs:[req_ofs],bx
	mov     cs:[req_seg],es
	ret
sys_request endp

init proc far
	;HERE IF YOU CHECK FOR A KEY, IN AL YOU'LL HAVE THE PRESSED ONE
	;BEFORE THIS DEVICE LOADED
	cld
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	push    cs
	pop     ds                              ;have the correct segment
						;in ds
	call    init_driver                     ;initialize driver (.SYS)
	lds     bx,cs:[dword ptr req_ofs]       ;required offset, CONFIG.SYS
	
        xor ax,ax
        mov ah,0Ch
        int 21h

	popx    ds,es,di,si,dx,cx,bx,ax         ;quit!
	ret                                     ;restore registers and end
init endp                                       ;since used from CONFIG.SYS
						;do not end through int 21h
init_driver proc
	lds     bx,dword ptr cs:[req_ofs]       ;verify the DOS rubbish
	mov     word ptr [bx+14],0              ;version -> stay resident
	mov     word ptr [bx+16],cs             ;or not 
	push    bx                              ;who uses DOS 3.2 ????
	mov     ah,30h
	int     21h                             ;HAS TO STAY RESIDENT BEFORE
	pop     bx                              ;DOS 3.2, cause otherwise
	cmp     al,3                            ;IT WILL GO CRAZY
	ja      no_tsr
	cmp     ah,21
	ja      no_tsr
	mov     word ptr [bx+14],offset fin_residant
	mov     cs:[run],offset nrun
	mov     cs:[req],offset nreq
   no_tsr:
	ret
init_driver endp

;all these vars should be checked by cs:[var]

var     db      ?

END                     ;oh finally the end...

