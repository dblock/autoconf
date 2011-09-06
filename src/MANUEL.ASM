.MODEL tiny
.code

pushx      macro r1, r2, r3, r4, r5, r6, r7, r8
	   ifnb <r1>
	   push r1                
	   pushx r2, r3, r4, r5, r6, r7, r8
	   endif
endm

popx       macro r1, r2, r3, r4, r5, r6, r7, r8
	   ifnb <r1>
	   pop r1                 
	   popx r2, r3, r4, r5, r6, r7, r8
	   endif
endm

init proc
        call    type_matic
	call    video_detect

        call    page_one_address
        call    twenty
        mov     dx,cs:[page1_beginning]
        cmp     dx,3500
        jb      ntofifty
        call    fifty
        mov     cs:[to_twenty_flag],0
ntofifty:

	call    efface_ecran
	call    push_cursor
	mov     dx,offset hlp_msg               
	mov     cs:[msgoffset],dx
	call    mulpages_msg_affiche
	call    pop_cursor
	call    efface_ecran
	mov     ah,0
	mov     al,cs:[video_mode]
	int     10h
        call    fifty
        cmp     cs:[to_twenty_flag],1
        jne     to_twenty
        call    twenty
to_twenty:
        mov     ah,4Ch
        int     21h
init endp

twenty proc
	mov ah,11h
        mov al,14h
	xor bx,bx
	int 10h
	mov cs:[@twenty],1
	mov cs:[@fifty],0
	ret
twenty endp

fifty proc
	mov ah,11h
	mov al,12h
	xor bx,bx
	int 10h
	mov cs:[@twenty],0
	mov cs:[@fifty],1
	ret
fifty endp

read_key proc
        ret
read_key endp

type_matic proc
;INTERRUPT 16h, Fonction 03h : D‚finir le taux de r‚p‚tition...
;           AH= 03h
;           AL= 05h
;           BH= Ralentissement jusqu'… la mise en place de la r‚p‚tition
;           BL= Taux de r‚p‚tition
;        BH peut etre ‚gal … :
;         00b : 3/4 de sec
;         01b : 1/2 sec
;         10b : 3/4 de sec
;         11b: 1 sec
;        BL: de 01h … 1Fh
	pushx   ax,bx
	mov     ah,3h
	mov     al,5h
        mov     bh,0
	mov     bl,1
	int     16h
	popx    bx,ax
	ret
type_matic endp


push_cursor proc
	pushx ax,bx,cx,dx
	mov ah,1
	mov ch,50
	mov cl,50
	int 10h
	popx dx,cx,bx,ax
	ret
push_cursor endp

pop_cursor proc
	pushx ax,bx,cx,dx
	mov ch,6
	mov cl,7
	mov ah,1
	int 10h
	popx dx,cx,bx,ax
	ret
pop_cursor endp

efface_ecran proc
	pushx   ax,bx,cx,dx
	sub     dx,dx
	mov     ah,2
	mov     bh,cs:[curpage]
	int     10h
	mov     ah,9
	mov     cx,2000         ;*2
	cmp     cs:[@fifty],1        
	jne     eff@fifty
	mov     cx,4080
    eff@fifty:
	mov     al,' '
	mov     bl,7
	int     10h
	popx    dx,cx,bx,ax
	ret
efface_ecran endp 

video_detect proc        
	pushx   ax,di,si,ds,es          ; Store registers
	push    cs
	pop     ds
	mov     di, CGASeg              ; move offset of CGA to DI
	mov     ah, 0Fh                 ; INT 10 get vid mode func
	int     10h                     ; get the video mode
	xor     ah, ah                  ; clear the AH reg
	mov     cs:[video_mode],al      ; place mode into VideoMode
	cmp     al, 7                   ; Is this a mono screen?
	jne     NotMono                 ; if not jump to NotMono
	mov     di,MonoSeg              ; move offset of mono to DI
	mov     cs:[SnowCheck], 0       ; NEVER CHECK RETRACE ON MONO!
	jmp     GVM_Done
   NotMono:                                ; Process CGA/EGA/VGA adap.
	call    EGAInstalled            ; Check for EGA adap.
	rcr     al, 1                   ; Move bit 1 to carry flag
	jc      GVM_Done                ; If EGA then no snow check
	mov     cs:[SnowCheck],1        ; Not EGA so set snow check
   GVM_Done:
	mov     cs:[v_mode],di          ; Move DI to base of screen
	popx    es,ds,si,di,ax          ; Restore regs
	ret
video_detect endp

EGAInstalled proc
	; Checks if EGA
	; Output:  AL = 1 if EGA Adapter is found / 0 if not
	pushx   bx,cx           ; Store used registers
	mov     ax, 1200h       ; BIOS INT 10 function 12h
	mov     bx, 10h         ; sub-func 10h (Get EGA info)
	mov     cx, 0FFFFh      ; lite all bits of CX
	int     10h             ; call INT 10
	xor     ax, ax          ; Clear AX reg
	cmp     cx, 0FFFFh      ; If CX not modified by INT call
	je      EI_Done         ;   then this is not an EGA
	inc     AL              ; Increment AL to show this is EGA
   EI_Done:
	popx    cx,bx           ; Restore regs
	ret
EGAInstalled endp

char_redo proc
	inc     bx
	mov     dl,es:[bx]      ;get next caracter, the number of chars
        xor     dl,cs:[xor_byte]
        sub     dl,cs:[increment_byte]
	inc     bx              ;next caracter, the letter itself
	mov     cl,es:[bx]
	sub     cl,100          ;correct the counter
	ret     
char_redo endp

beep    proc    
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	mov     al,10110110b           ; select 8253
	mov     dx,43h                 ; control port address
	out     dx,al
	dec     dx                      ; timer 2 address
	mov     ax,cs:[beep_div]
	out     dx,al                  ; low byte of divisor
	xchg    ah,al
	out     dx,al                  ; high byte of divisor
	mov     dx,61h
	in      al, dx                  ; get current value of control bits
        push    ax
	or      al,3
	out     dx,al                  ; turn speaker on
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Wait for desired duration by monitoring time-of-day 18 Hz clock
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±        
	mov     bx,cs:[timer_low]
	mov     cx,-1
beeplp: mov     ax,cs:[timer_low]
	sub     ax, bx
	cmp     ax,cs:[beep_len]
	jg      beepover
	loop    beeplp
beepover:
	; Turn off speaker
        pop     ax
	and     al,not 3               ; turn speaker off
	out     dx,al
	popx    ds,es,di,si,dx,cx,bx,ax
	ret
beep  endp

params  struc
	attrib               db      7
	c_c                  dw      0
	wrtpos               dw      ?
	line_count           db      0
	absmsg_pos           dw      ?
	ab_escape            db      0
params ends

conv_min proc
	cmp     al,'A'
	jb      no_conv_min
	cmp     al,'Z'
	ja      no_conv_min
	add     al,'a'-'A'
   no_conv_min:
	ret
conv_min endp

conv_maj proc
	cmp     al,'a'
	jb      cm_no_conv
	cmp     al,'z'
	ja      cm_no_conv
	sub     al,'a'-'A'
   cm_no_conv:
	ret
conv_maj endp

page_one_address proc
        pushx   ax,bx,cx,dx,es,di

        mov     bh,1
        mov     ah,3
        int     10h

        push    dx
	mov     ah,5                    ;change page
        mov     al,1                    ;to page 0 
	int     10h

        mov     bh,1
	mov     ah,3
	int     10h
        mov     bh,1
        xor     dx,dx
        mov     ah,2
        int     10h
        mov     ah,2
        mov     dl,'ÿ'
        int     21h
        mov     dl,'W'
        int     21h
        mov     dl,'A'
        int     21h
        mov     dl,'I'
        int     21h
        mov     dl,'T'
        int     21h

	mov     ax,cs:[v_mode]
        add     ax,100h
	xor     di,di
        mov     es,ax

   poa_notyet:
        add     di,2
        mov     al,es:[di]
        cmp     al,'ÿ'
        jne     poa_notyet

        push    di
        add     di,2
        mov     al,es:[di]
        cmp     al,'W'
        jne     poa_notyet_restart
        add     di,2
        mov     al,es:[di]
        cmp     al,'A'
        jne     poa_notyet_restart
        pop     di
        mov     cs:[page1_beginning],di
        jmp     poa_yesyet
   poa_notyet_restart:
        pop     di
        jmp     poa_notyet
   poa_yesyet:
	mov     ah,5                    ;change page
        mov     al,0                    ;to page 0 
	int     10h

        pop     dx
        mov     ah,2
        int     10h
        popx    di,es,dx,cx,bx,ax
        ret
page_one_address endp


elite_translate proc
        ret
elite_translate endp


page1_beginning                 dw      ?
hlp                             params  <7,0,?,0,?,0>
MonoSeg                         EQU     0B000h          ; Mono screen segment
CGASeg                          EQU     0B800h          ; CGA screen segment
SnowCheck                       DB      0               ; Check for retrace 1/0
Video_Mode                      DB      0               ; Current BIOS INT 10 vid mode
v_mode                          dw      CGASeg
msgoffset                       dw      ?
curpage                         db      0
eof_help                        db      0
@twenty                         db      1
@fifty                          db      0
message_mono                    db      0
extatr                          db      7
increment_byte                  db      0
xor_byte                        db      11101000b
ScrY                            dw      0
PanY                            db      0
beep_div                        equ     1300            ; fairly close to IBM beep
beep_len                        equ     3               ; 3/18 sec- shorter than IBM
timer_low                       dw      ?       ; low word of time-of-day counter (18.2 hz)
to_twenty_flag                  db      1

input_1                 equ 03dah   ; input status #1 register
vert_retrace            equ 08h     ; input_1: vertical retrace bit

include help.inc
include autocon2.inc


end






