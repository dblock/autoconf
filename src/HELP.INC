;-------------------------------------------------------------
;HELP MESSAGE ROUTINES, EXTENSIVE AUTOCONF EXTERNAL PROCEDURES
;-------------------------------------------------------------
mulpages_msg_affiche proc
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	mov     cs:[hlp.ab_escape],0             ;all the necessary 
	mov     cs:[hlp.c_c],0                   ;var to 0
	mov     cs:[hlp.attrib],7
	mov     cs:[hlp.wrtpos],0
	mov     cs:[hlp.absmsg_pos],0
	call    push_cursor                     ;hide the cursor
	push    cs                              ;es=cs
	pop     es
	mov     bx,cs:[msgoffset]               ;the help message vector
	mov     dl,es:[bx]                      ;the first caracter in dl
   hlpnp_always:        
	cmp     cs:[hlp.ab_escape],1             ;was escape pressed during
	jne     @@end                       ;page wait -> end help
	popx    ds,es,di,si,dx,cx,bx,ax         ;this is the end
	ret
	
   @@end:
	cmp     dl,10                           ;enter
	jne     hlpnp_not_enter_count
   hlpnp_next_char:
	inc     bx                              ;next caracter in dl via vecrtor
	mov     dl,es:[bx]
	jmp     hlpnp_always
   hlpnp_not_enter_count:
        cmp     dl,252  ;''
	jne     hlpnp_nothing_special
	mov     cs:[hlp.attrib],7
	cmp     cs:[message_mono],1
	jne     hlpnp_next_char
	mov     cs:[hlp.attrib],0
	jmp     hlpnp_next_char
   hlpnp_nothing_special:
	cmp     dl,'ý'                          ;is it a color code
	jne     hlpnp_no_color                  ;no-> don't change color var
	inc     bx                              ;next caracter 
	mov     dl,es:[bx]                      ;in dl
        cmp     dl,'ý'
        jne     @hlpnp_no_dec
        jmp     hlpnp_no_dec
   @hlpnp_no_dec:
	mov     cs:[hlp.attrib],7
	cmp     cs:[message_mono],1
	je      hlpnp_next_char
	mov     cs:[hlp.attrib],dl               ;this is the color (silly ansi)
	jmp     hlpnp_next_char                 ;next caracter
   hlpnp_no_color:
	cmp     dl,''                          ;is it the end of the hlp?
	jne     hlpnp_naffiche                  ;have a break
	mov     dl,']'
        call    Retrace
        call    hlpsave_c_buffer
	
	call    hlpext_affiche
	cmp     cs:[@fifty],1
	jne     page@fifty
	cmp     cs:[hlp.c_c],1920*2+80        ;isit whole page written?
	je      hlpnot_page
	jmp     page@ffity
   page@fifty:        
	cmp     cs:[hlp.c_c],1920        ;*2        ;isit whole page written?
	je      hlpnot_page
   page@ffity:
	call    hlpabm_hhend
	xor     di,di                           ;restore 0 screen posistion
	mov     cs:[hlp.wrtpos],di               ;save di write possition
	mov     cs:[hlp.c_c],0                   ;null caracters
	jmp     hlpnp_next_char
   hlpnot_page:
	call    hlp_not_pageprc
	jmp     hlpnp_next_char                 ;next caracter since no exit
   hlpnp_end:        
	popx    ds,es,di,si,dx,cx,bx,ax         ;this is the end
	ret
   hlpnp_naffiche:        
        cmp     dl,28                           ;decoder from silly code
        jb      hlpnp_no_dec                    ;never decode enters, etc...
        cmp     dl,39                           ;since stored as written
        je      hlpnp_no_dec
        cmp     dl,254
        je      hlpnp_no_dec
        xor     dl,cs:[xor_byte]
        sub     dl,cs:[increment_byte]
        call    elite_translate
   hlpnp_no_dec:
        cmp     dl,254                          ;þ compressed same char
	jne     hlpnp_not_lines
	call    char_redo
   hlpcr_reroll:    
        call    hlpsave_c_buffer   ;reroll the chars
        dec     cl                 ;to 0
	jnz     hlpcr_reroll       ;no->jump
	inc     bx
	mov     dl,es:[bx]
        jmp     hlpnp_always        
   hlpnp_not_lines:        
	cmp     cs:[hlp.ab_escape],1
	je      hlpnp_end
        call    hlpsave_c_buffer
	inc     bx
	mov     dl,es:[bx]
	jmp     hlpnp_always
mulpages_msg_affiche endp

hlp_not_pageprc proc        
	mov     cs:[hlp.absmsg_pos],bx           ;save the hlp_pos
	xor     di,di                           ;restore 0 screen posistion
	mov     bx,cs:[hlp.absmsg_pos]           ;for stosw, move pos in bx
	mov     cs:[hlp.wrtpos],di               ;save di write possition
	mov     cs:[hlp.c_c],0                   ;null caracters
	mov     cs:[eof_help],1
	call    hlp_ab_movements
	mov     cs:[eof_help],0
	ret
hlp_not_pageprc endp

hlpsave_c_buffer proc
	pushx   ax,cx,dx,si,di,es,ds         ;preserve registers
	mov     ax,cs:[v_mode]
	mov     di,cs:[hlp.wrtpos]            ;direct VGA memory fill with
	mov     es,ax
	mov     ah,cs:[hlp.attrib]
	mov     cx,1
	mov     al,dl
	stosw
	mov     cs:[hlp.wrtpos],di
	inc     cs:[hlp.c_c]
	cmp     dl,']'
	je      hlpab_n2
	
	cmp     cs:[@fifty],1
	jne     abn@fifty
	cmp     cs:[hlp.c_c],1920*2+80
	je      hlpno_scb
	jmp     hlpab_n2
     abn@fifty:
	cmp     cs:[hlp.c_c],1920        ;*2
	jne     hlpab_n2
     hlpno_scb:        
	call    hlp_affiche_buffer
	mov     bx,cs:[hlp.absmsg_pos]
     hlpab_n2:
	popx    ds,es,di,si,dx,cx,ax
	ret
hlpsave_c_buffer endp

hlp_ab_movements proc
	mov     bx,cs:[hlp.absmsg_pos]
        cmp     cs:[search_mode],1
        jne     hlpabm_beg
        call    search_highlight
        cmp     cs:[thispage_ok],1
        je      hlpabm_beg
        cmp     bx,cs:[search_asbefore]
        je      hlpabm_beg_zero
        mov     cs:[search_asbefore],bx
        cmp     cs:[search_indirection],1
        je      hlpabm_haut
        jmp     hlpabm_bas
    hlpabm_beg_zero:
        mov     cs:[search_mode],0
    hlpabm_beg:
        mov     cs:[search_asbefore],0
	sub     ax,ax
	mov     ah,0Ch
	int     21h
	mov     ah,0
	int     16h
	cmp     al,' '
	je      color_toggle
	cmp     al,1Bh
        jne     nhlp_abm_esc
        jmp     hlp_abm_esc
    nhlp_abm_esc:
	cmp     al,9       ;tabulator
	je      tweak_mode
	cmp     al,0
	jne     hlpabm_beg
	mov     al,ah
        cmp     al,53h
        jne     nsearch_algo@
        mov     cs:[search_mode],0
        jmp     search_algo@
    nsearch_algo@:
        cmp     al,52h
        jne     nsearch_algo
        jmp     search_algo
    nsearch_algo:
        cmp     al,48h          ;fleche haut
	je      hlpabm_haut
	cmp     al,4Bh          ;fleche gauche
	je      hlpabm_haut
	cmp     al,49h          ;PgUp
	je      hlpabm_pgup
	cmp     al,47h          ;Home
        jne     hlpabm_home@
        jmp     hlpabm_home
  hlpabm_home@:
	cmp     cs:[eof_help],1
	je      hlpabm_beg      ;new
	cmp     al,50h          ;fleche bas
	je      hlpabm_bas
	cmp     al,4Dh          ;fleche droite
	je      hlpabm_bas
	cmp     al,51h          ;PgDn
	je      hlpabm_pgdn
	cmp     al,4Fh          ;End
	je      hlpabm_end
	jmp     hlpabm_beg
   tweak_mode:
	call    set_tweaked_mode
	ret
   color_toggle:
	call    @color_toggle
	ret
   hlpabm_haut:
        mov     cs:[search_indirection],1
        call    @hlp_abm_haut
	ret
   hlpabm_bas:
        mov     cs:[search_indirection],0
        mov     cs:[hlp.line_count],23
	cmp     cs:[@fifty],1
	jne     hb_n@fifty
	mov     cs:[hlp.line_count],48
   hb_n@fifty:
	call    hlpabm_hline
        ret
   hlpabm_end:
	call    hlpabm_hhend
	ret
   hlpabm_pgup:
        mov     cs:[search_indirection],1
	mov     cs:[hlp.line_count],48
	cmp     cs:[@fifty],1
	jne     hg_n@fifty
	mov     cs:[hlp.line_count],98 ;6
   hg_n@fifty:
	call    hlpabm_hline
	ret
	ret
   hlp_abm_esc:
	mov     cs:[hlp.ab_escape],1
	ret
   hlpabm_pgdn:
        mov     cs:[search_indirection],0
        call    efface_ecran
	mov     cs:[hlp.attrib],7
	xor     di,di
	mov     cs:[hlp.wrtpos],di
	ret        
   hlpabm_home:
	mov     bx,cs:[msgoffset]       ;offset hlp_msg newnewnewn
	dec     bx
	mov     cs:[hlp.absmsg_pos],bx
	sub     di,cs:[hlp.c_c]
	sub     di,cs:[hlp.c_c]
	mov     cs:[hlp.wrtpos],di
	ret
   search_algo:
        call    search_stupid
   search_algo@:
        mov     cs:[hlp.line_count],24   ;50
	cmp     cs:[@fifty],1
        jne     hhh_n@fifty
        mov     cs:[hlp.line_count],49
   hhh_n@fifty:
	call    hlpabm_hline
        ret
hlp_ab_movements endp

	
@hlp_abm_haut proc
	mov     cs:[hlp.line_count],25   ;50
	cmp     cs:[@fifty],1
	jne     hh_n@fifty
	mov     cs:[hlp.line_count],50
   hh_n@fifty:
	call    hlpabm_hline
	ret
@hlp_abm_haut endp

set_tweaked_mode proc
	call    efface_ecran
	cmp     cs:[@twenty],1
	je      stm_fifty
	call    twenty
	mov     cs:[hlp.line_count],49
	call    hlpabm_hline
	call    push_cursor
	ret
stm_fifty:
	call    fifty
	mov     cs:[hlp.line_count],24   
	call    hlpabm_hline
	call    push_cursor
	ret
set_tweaked_mode endp

hlpabm_hhend proc
	push    cs                              ;es=cs
	pop     es
	mov     al,''
	mov     bx,cs:[hlp.absmsg_pos]
     hlphhend_again:
	inc     bx
	cmp     es:[bx],al
	jne     hlphhend_again
	mov     cs:[hlp.absmsg_pos],bx
	
	mov     cs:[hlp.line_count],24
	cmp     cs:[@fifty],1
	jne     he_n@fifty
	mov     cs:[hlp.line_count],49
   he_n@fifty:
	call    hlpabm_hline
	ret
hlpabm_hhend endp

hlpabm_hline proc
	mov     cs:[hlp.attrib],7
	push    cs                              ;es=cs
	pop     es
	mov     dl,10
	mov     bx,cs:[hlp.absmsg_pos]
   hlpabm_haut_again:        
	dec     bx
	cmp     bx,cs:[msgoffset]       ;offset hlp_msg newnewnewn
	je      hlpabm_line_beg
	cmp     es:[bx],dl
	jne     hlpabm_haut_again
	dec     cs:[hlp.line_count]
	jnz     hlpabm_haut_again
	mov     cs:[hlp.absmsg_pos],bx
	sub     di,cs:[hlp.c_c]
	sub     di,cs:[hlp.c_c]
	mov     cs:[hlp.wrtpos],di
	ret
   hlpabm_line_beg:
	dec     bx
	mov     cs:[hlp.absmsg_pos],bx
	mov     cs:[hlp.attrib],7
	sub     di,cs:[hlp.c_c]
	sub     di,cs:[hlp.c_c]
	mov     cs:[hlp.wrtpos],di
        ret
hlpabm_hline endp

hlp_affiche_buffer proc
	mov     cs:[hlp.ab_escape],0
	mov     cs:[hlp.absmsg_pos],bx
	pushx   ax,cx,dx,si,di,es,ds         ;preserve registers
	call    hlpext_affiche
	mov     cs:[hlp.attrib],7
	call    hlp_ab_movements
	mov     cs:[hlp.c_c],0
	popx    ds,es,di,si,dx,cx,ax
	mov     bx,cs:[hlp.absmsg_pos]
	ret
hlp_affiche_buffer endp

hlpext_affiche proc
	pushx   ax,bx,cx,dx
	mov     bh,cs:[curpage]
	mov     ah,2
	mov     dl,0
	mov     dh,24
	cmp     cs:[@fifty],1
	jne     ext@fifty
	mov     dh,49
   ext@fifty:
	int     10h
	push    cs                              ;es=cs
	pop     es
        mov     bx,offset press_a_extended_key
        cmp     cs:[search_mode],1
        jne     hlpext_nsearch
        mov     bx,offset press_search
   hlpext_nsearch:
	mov     cl,80
   hlpext_a:
	mov     al,es:[bx]
	cmp     al,'ý'
	jne     hxt_ncol
	inc     bx
	mov     al,es:[bx]
	mov     cs:[extatr],7
	inc     bx                              ;next caracter, keep bw
	cmp     cs:[message_mono],1
	je      hlpext_a
	mov     cs:[extatr],al
	jmp     hlpext_a
   hxt_ncol:
        cmp     al,32
        jb      hlpext_nosub

        xor     al,cs:[xor_byte]
        sub     al,cs:[increment_byte]
        
   hlpext_nosub:
	pushx   cx,bx
	mov     cx,1
	mov     ah,09h
	mov     bl,cs:[extatr]
	mov     bh,cs:[curpage]
	int     10h
	push    dx
	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	inc     dl
	mov     ah,2
	int     10h
	popx    dx,bx,cx
	inc     bx
	dec     cl
	jnz     hlpext_a
	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	mov     dl,0
	mov     ah,2
	int     10h
	popx    dx,cx,bx,ax
	ret
hlpext_affiche endp

@color_toggle proc       
	cmp     cs:[message_mono],1
	jne     @@mn
	mov     cs:[message_mono],0
	jmp     @@nm
     @@mn:
	mov     cs:[message_mono],1
     @@nm:
	call    efface_ecran
	cmp     cs:[@twenty],1
	je      @stm_fifty
	mov     cs:[hlp.line_count],49
	call    hlpabm_hline
	call    push_cursor
	ret
   @stm_fifty:
	mov     cs:[hlp.line_count],24   
	call    hlpabm_hline
	call    push_cursor
	ret
@color_toggle endp

Retrace         PROC
                pushx ax,dx
                mov dx,3dah
Vert1:
                in al,dx
                test al,8
                jz vert1
vert2:
                in al,dx
                test al,8
                jnz vert2
                popx dx,ax
                ret
Retrace         ENDP


search_stupid proc
        pushx   ax,bx,cx,dx
        mov     ah,3
        mov     bh,cs:[curpage]
        int     10h
        pushx   ax,bx,cx,dx
	mov     bh,cs:[curpage]
	mov     ah,2
	mov     dl,0
	mov     dh,24
	cmp     cs:[@fifty],1
        jne     ss_ext@fifty
	mov     dh,49
   ss_ext@fifty:
	int     10h
	push    cs                              ;es=cs
	pop     es
        mov     bx,offset search_stupid_msg
	mov     cl,80
   ss_hlpext_a:
	mov     al,es:[bx]
        cmp     al,'ý'
        jne     ss_hxt_ncol
	inc     bx
	mov     al,es:[bx]
	mov     cs:[extatr],7
	inc     bx                              ;next caracter, keep bw
	cmp     cs:[message_mono],1
        je      ss_hlpext_a
	mov     cs:[extatr],al
        jmp     ss_hlpext_a
   ss_hxt_ncol:
        cmp     al,32
        jb      ss_hlpext_nosub

        xor     al,cs:[xor_byte]
        sub     al,cs:[increment_byte]
        
   ss_hlpext_nosub:
	pushx   cx,bx
	mov     cx,1
	mov     ah,09h
	mov     bl,cs:[extatr]
	mov     bh,cs:[curpage]
	int     10h
	push    dx
	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	inc     dl
	mov     ah,2
	int     10h
	popx    dx,bx,cx
	inc     bx
	dec     cl
        jnz     ss_hlpext_a

	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
        mov     dl,13
	mov     ah,2
	int     10h
        call    pop_cursor
        call    read_string
	popx    dx,cx,bx,ax
        mov     ah,2
        mov     bh,cs:[curpage]
        int     10h
        popx    dx,cx,bx,ax
        call    push_cursor
        call    hlpext_affiche
	ret
search_stupid endp

read_string proc
        pushx   ax,bx,cx,dx
        mov     cs:[search_counter],0
        mov     cs:[search_mode],0
        mov     bx,offset cs:[search_string]
    rs_next_char:
        xor     ax,ax
        mov     ah,0Ch
        int     21h
        xor     ax,ax
        int     16h

        call    read_key

        cmp     al,0Dh
        je      rs_end_saisie
        cmp     al,8
        je      rs_erase

        cmp     al,1Bh
        je      rs_end_esc
        cmp     al,' '
        jb      rs_next_char

        inc     cs:[search_counter]
        cmp     cs:[search_counter],66
        je      rs_end_beep

        push    cs
        pop     es
        push    ax
        call    conv_maj
        mov     es:[bx],al
        pop     ax
        inc     bx

        mov     ah,2
        mov     dl,al
        int     21h
        jmp     rs_next_char
    rs_erase:
        cmp     cs:[search_counter],0
        je      rs_next_char
        pushx   ax,bx,dx
        mov     ah,3
        mov     bh,cs:[curpage]
        int     10h
        mov     ah,2
        dec     dl
        int     10h
        mov     ah,2
        mov     dl,' '
        int     21h
        mov     ah,3
        mov     bh,cs:[curpage]
        int     10h
        mov     ah,2
        dec     dl
        int     10h
        popx    dx,bx,ax
        dec     cs:[search_counter]
        dec     bx
        jmp     rs_next_char
    rs_end_beep:
        call    beep
        dec     cs:[search_counter]
        jmp     rs_next_char
    rs_end_saisie:
        mov     al,0
        mov     es:[bx],al
        mov     cs:[search_mode],1
    rs_end:
        popx    dx,cx,bx,ax
        ret
    rs_end_esc:
        mov     cs:[search_mode],0
        jmp     rs_end
read_string endp

search_highlight proc
        pushx   ax,bx,cx,dx,es,di,si,ds
        mov     cs:[thispage_ok],0
	mov     ax,cs:[v_mode]
        mov     ds,ax
        xor     si,si
        mov     cx,2000
        cmp     cs:[@fifty],1
        jne     sh_nfifty
        add     cx,2160
sh_nfifty:
sh_next:
        mov     al,ds:[si]
        add     si,2
        dec     cx
        cmp     cx,0
        je      sh_end

        push    cs
        pop     es
        mov     bx,offset cs:[search_string]
        call    conv_maj
        cmp     es:[bx],al
        jne     sh_next

        mov     cs:[search_begpos],si

     found_next_char:
        inc     bx
        mov     al,ds:[si]
        call    conv_maj
        add     si,2
        dec     cx
        cmp     cx,0
        je      sh_end
        cmp     al,es:[bx]
        je      found_next_char
        mov     al,0
        cmp     al,es:[bx]
        jne     nfound_char

        mov     si,cs:[search_begpos]

        pushx   ax,si,ds,cx
        mov     cx,cs:[search_counter]
   sh_color:
        mov     al,'Š'
        mov     ds:[si-1],al
        add     si,2
        loop    sh_color
        mov     cs:[thispage_ok],1
        popx    cx,ds,si,ax


        jmp     sh_next
   nfound_char:
        mov     si,cs:[search_begpos]
        jmp     sh_next
  sh_end:
        popx    ds,si,di,es,dx,cx,bx,ax
        ret
search_highlight endp

search_indirection              db      0
search_mode                     db      0
search_counter                  dw      0
search_string                   db      80 dup (0)
search_begpos                   dw      0
thispage_ok                     db      0
search_asbefore                 dw      0

