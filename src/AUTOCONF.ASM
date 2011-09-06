;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; AUTOCONF.ASM - configurations multiples par Daniel Doubrovkine - Suisse
; AUTOCONF.SYS module...All rights reserved, etc...
; since you got this code, know that it is not destributable and I don't
; guarantee anything!
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

.model small                     ;very little model
.code
.386

affiche macro message                           ;modif 7.07.94
        push    bx
	mov     bx,offset message
	call    newing
        pop     bx
endm

pushx macro r1, r2, r3, r4, r5, r6, r7, r8      ;that's a usefull macro
	ifnb <r1>                               ;stolen it from the source
        push r1                                 ;of a 3D vector engine...
	pushx r2, r3, r4, r5, r6, r7, r8        ;pushx + 8 registers
	endif
endm

popx macro r1, r2, r3, r4, r5, r6, r7, r8
	ifnb <r1>
        pop r1  
	popx r2, r3, r4, r5, r6, r7, r8
	endif
endm

vv macro chartocompare,messagetoshow
	mov     dl,chartocompare
	mov     bx,offset messagetoshow
	call    question_abrev
endm

ORG 0000h

driver_suiv     dw      -1                      ;link with next driver's offset
                dw      -1                      ;link with next driver's segment
                                                ;(last driver in chain                                                ;(last driver in chain)
attribut        dw      8004h                   ;device attribute word
                                                ;(driver attribute, may be:
                                ;0001h           ; standard input device
                                ;0002h           ; standard output device
                                ;0004h           ; NUL device
                                ;0008h           ; clOCK$ device
                                ;0               ; DOS block device (bit 13)
                                ;2000h           ; non-DOS block device (bit 13)
                                ;4000h           ; IOCTL functions supported
                                ;0               ; block device (bit 15)
                                ;8000h           ; character device (bit 15)
        ;       dw      ?            ;number of devices or device name
req             dw      offset sys_request      ;offset to store request header <0bc07>
run             dw      offset init             ;offset for process interrupt <0bc12>
                                        
nom_device      db      'NUL    '
        ;       db      7 dup ( ? )  ;filler for block device

include autoconf.inc
include help.inc
include iloom.inc

new_device proc
        nreq:   or      es:word ptr [bx+3],0100h        
        nrun:   ret                                     
new_device endp

fin_residant label near

req_ofs         dw      ?
req_seg         dw      ?

sys_request proc far
        mov     cs:[req_ofs],bx                         ;request header offset  <0bc03>
        mov     cs:[req_seg],es                         ;request header segment <0bc05>
	ret
sys_request endp

init proc far
	sub      ax,ax                          ;clear ax
	mov      ds,ax                          ;null the segment
	mov      al,ds:[0EAh*4+2]               ;integrity rerun check
	cmp      al,255
	jne      no_recovery
	mov      al,ds:[byte ptr 0EAh*4]        ;read from memory
        cmp      al,'*'                         ;is it an escape
        je       no_recovery                    ;so start ending the prog
   not_second_escape:                           ;by far and quick jumps
	cmp      al,'˝'
	jne      not_list_address
	call     get_history
	mov      cs:[to_be_made],1
	mov      cs:[second],1
	xor      ax,ax                          ;clear buffer
	mov      ah,0Ch                         ;sub ax,ax: avoid calling ah,16h
	int      21h
	jmp      no_recovery
   not_list_address:
	cmp      al,'F'                         ;is it an extended config
	jne      ip_not_ext                     ;so jump to normal
	mov      cs:[ext],1                     ;set extended flag
	jmp      ext_do                         ;do extended config
   ip_not_ext:
	cmp      al,252                         ;normal configuration?
	jne      no_recovery                    ;if memory was overwritten or
   ext_do:                                      ;something, AUTOCONF will just
	mov      al,ds:[byte ptr 0EAh*4+1]      ;rerun completely
	mov      cs:[config],al                 ;read the configuration
	mov      cs:[second],1                  ;it is the second run
	xor      ax,ax                          ;clear buffer
	mov      ah,0Ch                         ;sub ax,ax: avoid calling ah,16h
	int      21h
   no_recovery:
	cld
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	call    video_detect
        push    cs
        pop     ds
	call    init_driver
	mov     ah,1
	int     16h
	cmp     al,'.'
	je      do_skip
	cmp     cs:[skip_configuration],1
	je      do_skip
        mov     ah,1
	call    forbidden_keys
	int     16h
        cmp     al,'*'  ;1Bh                          ;in case escape was used
        je      @@end_prog                      ;or dollar error occured...
	mov     ah,1                            ;key in the buffer?
	int     16h                                          
	jz      normal_execute                  ;no, continue
	mov     cs:[ext_depend],1
        cmp     al,'*'  
	jne     normal_execute                  ;no, continue
	sub     bx,bx
	mov     ds,bx
        mov     al,'*'  ;1Bh
	mov     ds:[0EAh*4],al
	mov     al,255
	mov     ds:[0EAh*4+2],al
	jmp     do_skip_temp
    do_skip:
	call    @skip_configurations
    do_skip_temp:
	popx    ds,es,di,si,dx,cx,bx,ax         ;restore registers
        affiche ended
        ret
   @@end_prog:
	jmp     end_prog
   normal_execute:                          
	lds     bx,cs:[dword ptr req_ofs]       ;initialisation
	lds     si,[bx+18]                      ; si <- CONFIG.SYS position
	call    type_matic
	call    verifie_fichier_ok              ;verifiy for DEVICE=$
	cmp     cs:[erreur_dollar],1            ;error -> end program
	je      @@end_prog
	cmp     cs:[second],1
	je      no_derl
	call    derived_liste_config
   no_derl:
	cmp     cs:[to_be_made],1
	jne     no_no_make
	call    derived_liste_config
   no_no_make:
	call    analyse_param                   ;analyse parameters
        cmp     cs:[message_mono],1
        jne     no_no_color
        mov     cs:[cnf_dsig_color],7
   no_no_color:
        call    define_timer
        call    analyse_wait
	cmp     cs:[fatal_error],1      ;esC pressed somewhere
	je      @@end_prog                ;-> end program
	cmp     cs:[force_fifty],1
	jne     no_ffifty
	call    fifty
   no_ffifty:
	call    reboot_it
        call    msg_or_not                      ;messages routines
	call    running_chicago
	call    cherche_fin_config              ;look for the multconf end
	cmp     cs:[second],1
	jne     no_recovery_two
	mov     cs:[message_ou_pas],1
   no_recovery_two:
        call    save_config
	call    lit_configuration               ;read the choosed config
	call    pop_cursor
	cmp     cs:[skip_configuration],1
	jne     dont_skip
	call    @skip_configurations
	popx    ds,es,di,si,dx,cx,bx,ax         ;restore registers
        affiche ended
        ret
   dont_skip:
	cmp     cs:[fatal_error],1
	je      end_prog
	cmp     cs:[to_be_made],1
	jne     nottobe
	call    verify_sub
	jnc     not_bad

	mov     cs:[sub_level],1
	call    clean_history
	call    liste_configuration

    not_bad:
	call    make_address
   nottobe:
	cmp     cs:[made_address],1
	je      cleaned
	call    compacte_config                 ;give the ..ing DOS what
	call    clean_and_move                  ;it wants
        mov     cs:[simpleminded],1
        call    setenvvar
   cleaned: 
	cmp     cs:[made_address],1
	jne     dontname
	cmp     cs:[second],1
	je      dontname
        cmp     cs:[message_title],1
        je      yestitle
        cmp     cs:[message_ou_pas],1
        je      dontname
   yestitle:
        push    si
	mov     si,cs:[start_address]
        call    acn_derived
        pop     si
   dontname:
	mov     al,cs:[config]                  ;
	sub     al,'A'-1
   end_prog:
        cmp     cs:[rw_lc_mix],1
        jne     naffiche_lsd
        affiche lsd_msg
   naffiche_lsd:
        call    running_chicago_msg
	sub     bx,bx
	mov     ds,bx
	mov     ah,1
	int     16h                             ;something in the buffer
	jz      suite_et_fin                    ;-> no, end
	mov     ah,0Ch                          ;else clear it
	int     21h
   suite_et_fin:
	cmp     cs:[erreur_dollar],1            ;check if a dollar error 
	jne     sf_not_err_doll                 ;has occured, if yes, just
	popx    ds,es,di,si,dx,cx,bx,ax         ;quit!
        affiche ended
        ret                                     ;restore registers and end
   sf_not_err_doll:
	sub     bx,bx
	mov     ds,bx
	mov     al,cs:[config]
	mov     ds:[0EAh*4+1],al
	mov     al,'F'
	cmp     cs:[ext],1
	je      putext
	mov     al,252
   putext:       
	cmp     cs:[made_address],1
	jne     putext_@
	mov     al,'˝'
   putext_@:
	mov     ds:[0EAh*4],al
	mov     al,255                   ;successgull run
	mov     ds:[0EAh*4+2],al
	xor     cx,cx                   ;write_file

	cmp     cs:[made_address],1
	je      read_and_write
	cmp     cs:[theres_key],0
	je      read_and_write
	call    clean_history
   read_and_write:
	call    lit_ecrit_cfg
        popx    ds,es,di,si,dx,cx,bx,ax
	call    f4_force
        affiche ended
        ret                                     ;restore registers and end
init endp                      ;since used from CONFIG.SYS

init_driver proc
        push    ax                      ;need in case of escape
	lds     bx,dword ptr cs:[req_ofs]       ;verify the DOS rubbish
	mov     word ptr [bx+14],0              ;version -> stay resident
	mov     word ptr [bx+16],cs             ;or not 
        push    bx                              ;who uses DOS 3.2 ????
	mov     ah,30h
	int     21h
        pop     bx
        cmp     al,3
        jb      yes_tsr
        cmp     al,3
        jne     no_tsr
        cmp     ah,21
        ja      no_tsr
   yes_tsr:
	mov     word ptr [bx+14],offset fin_residant
	mov     cs:[run],offset nrun
	mov     cs:[req],offset nreq
   no_tsr:
        cmp     al,cs:[critical_version]
	jb      no_reinit
	mov     al,3
	mov     ah,0
	int     10h
   no_reinit:
        pop     ax
	ret
init_driver endp

@skip_configurations proc
        lds     bx,cs:[dword ptr req_ofs]       ;initialisation
	lds     si,[bx+18]                      ; si <- CONFIG.SYS position
        mov     cs:[start_address],si
        call    clean_upper
        call    cherche_fin_config
        mov     cs:[end_address],si
	call    clean_lower
	mov     ah,2
	mov     dl,10
	int     21h
	mov     dl,13
	int     21h
	affiche skiping_message
        mov     ah,2
	mov     dl,10
	int     21h
	mov     dl,13
	int     21h
	mov     dl,10
	int     21h
        mov     cs:[config],'.'
        mov     cs:[ext],0
        call    setenvvar
        ret
@skip_configurations endp

f4_force proc
	pushx   ax,cx
	cmp     cs:[do_f4],1
	jne     f4_ok
	cmp     cs:[second],1
	je      f4_ok
	mov     ah,30h
	int     21h
        cmp     al,cs:[critical_version]
	jae     f4_ok
	mov     cl,0
	mov     ch,62
	mov     ah,5
	int     16h
	cmp     al,0
	jne     f4_ok
    f4_ok:
	popx    cx,ax
	ret
f4_force endp
						;do not end through int 21h
ligne_suiv proc                                         ;jump a line in
   next_line:                                              ;CONFIG.SYS
	lodsb                           ;next char
	cmp     al,10                   ;ENTER?
	jne     next_line               ;NO -> loop
   next_line2:                             ;right, enter, but does the line 
	lodsb                           ;contain something?
	cmp     al,10                   ;ENTER now? -> doesn't have an text
	je      next_line2              ;loop to next line
	dec     si                      ;pointer on last char before the line
	ret
ligne_suiv endp

ligne_prec proc                                         ;jump a line in
   prev_line:                                              ;CONFIG.SYS
	sub     si,2                    ;next char
	lodsb
	cmp     al,10                   ;ENTER?
	jne     prev_line               ;NO -> loop
	ret
ligne_prec endp

verifie_config proc
	cmp     cs:[show_conf_choose],1
	je      vx_exit
	cmp     cs:[made_address],1
	je      vx_exit
	cmp     cs:[to_be_made],1
	je      vx_exit
	cmp     cs:[chosenlist],1
	je      vx_exit
	cmp     cs:[chosen_list],1
	jne     vc_do
   vx_exit:
	clc
	ret
   vc_do:
	pushx   ax,si                   ;save the pointer
	mov     bl,al                   ;bl<-al choosed conf in bl
        cmp     bl,' '
        je      v_config_ok
   v_next:
	call    ligne_suiv              ;next line
        call    rubbish_skip
        jc      v_next
        cmp     al,'D'                  ;D... evice?
	jne     v_next                  ;no -> again
        call    rubbish_skip
        jc      v_next
	cmp     al,'$'                  ;Device=$ ? (d$ out of device=$)
	je      v_config_nok            ;device=$ -> no config found like that
	cmp     al,'*'                  ;else: device=*...?
	jne     v_next                  ;no -> again

        call    rubbish_skip
        jc      v_next
	cmp     cs:[ext],1
	jne     not_ext_conf
	cmp     al,'F'
	jne     v_next                  ;not_ext_conf
        call    rubbish_skip
        jc      v_next
   not_ext_conf:        
	cmp     al,'F'
	jne     not_ext_possible
        lodsb
	cmp     al,'0'
	jb      couldbe_ok_
	cmp     al,'9'
	ja      couldbe_ok_
	jmp     v_next
   couldbe_ok_:
	dec     si
	mov     al,'F'
   not_ext_possible:
	cmp     al,bl                   ;choosed conf=this one
	je      v_config_ok             ;yes -> fine
	jmp     v_next                  ;no -> next config
   v_config_nok:
	stc                             ;set carry flag
	popx     si,ax                  ;config not found
	ret                             ;restore CONFIG.SYS position
   v_config_ok:
	clc                             ;remove carry flag
	popx     si,ax                  ;restore CONFIG.SYS position
	ret                             ;config found
verifie_config endp

conv_maj proc
	cmp     al,'a'
	jb      cm_no_conv
	cmp     al,'z'
	ja      cm_no_conv
	sub     al,'a'-'A'
   cm_no_conv:
	ret
conv_maj endp

conv_min proc
	cmp     al,'A'
	jb      no_conv_min
	cmp     al,'Z'
	ja      no_conv_min
	add     al,'a'-'A'
   no_conv_min:
	ret
conv_min endp

msg_or_not proc
        call    compile_date
	cmp     cs:[second],1
	je      theveryend
	cmp     cs:[message_ou_pas],1
	je      no_showmsg
	call    efface_ecran
	affiche msg_mon
        call    dateandtime
	call    bonjour_bonsoir
	jmp     theveryend
   no_showmsg:
	jmp     theveryend
   theveryend:        
   	ret
msg_or_not endp

dateandtime proc
        pushx   ax,bx,cx,dx

        mov     ah,3
        mov     bh,0
        int     10h
        dec     dh
        mov     dl,37
        mov     ah,2
        int     10h

        mov     ah,2Ah
        int     21h
        mov     cs:[annee],cx
        mov     cs:[semaine],al
        dec     dh
        mov     cs:[mois],dh
        mov     byte ptr cs:[jour],dl

        mov     al,cs:[curpage]
        mov     ah,cs:[c_color]
         push    ax
        mov     cs:[curpage],0
        cmp     cs:[message_mono],1
        mov     cs:[c_color],7
        je      dat_mono
        mov     cs:[c_color],''
    dat_mono:

        ;jour de la semaine
        pushx   ax,bx,cx,dx,es
        call    advance_with_char
        mov     bx,offset cs:[semaine_text]
        mov     cl,cs:[semaine]
        mov     al,10
        mul     cl
        add     bx,ax
        mov     ah,2
        push    cs
        pop     es
        call    dtextro
        popx    es,dx,cx,bx,ax

        ;date
        call    advance_with_char
        mov     dx,cs:[jour]
        call    write_decimal
        call    advance_with_char
        ;mois
        pushx   ax,bx,cx,dx,es
        mov     bx,offset cs:[mois_text]
        mov     cl,cs:[mois]
        mov     al,10
        mul     cl
        add     bx,ax
        mov     ah,2
        push    cs
        pop     es
        call    dtextro
        popx    es,dx,cx,bx,ax
        ;annee
        call    advance_with_char
        mov     dx,cs:[annee]
        call    write_decimal

        ;time
        mov     ah,2Ch
        int     21h
        mov     byte ptr cs:[heures],ch
        mov     byte ptr cs:[minutes],cl

        call    advance_with_char
        mov     dx,cs:[heures]
        call    write_decimal
        mov     ah,2
        mov     dl,':'
        int     21h
        
        mov     dx,cs:[minutes]
        cmp     dx,10
        jae     min_wd
        mov     dx,0
        call    write_decimal
        mov     dx,cs:[minutes]
    min_wd:
        call    write_decimal
        call    advance_with_char
        mov     ah,2
        mov     dl,10
        int     21h
        mov     dl,13
        int     21h

        pop     ax
        mov     cs:[curpage],al
        mov     cs:[c_color],ah
        popx    dx,cx,bx,ax
        ret
dateandtime endp

dtextro proc
    dt_rewrite:
        mov     dl,es:[bx]
	xor     dl,cs:[xor_byte]
	sub     dl,cs:[increment_byte]                           ;decode...
        call    elite_translate
        inc     bx
        int     21h
        cmp     dl,','
        je      dt_norewrite
        jmp     dt_rewrite
    dt_norewrite:
        ret
dtextro endp

find_switch proc
	dec si
   fs_car_suiv:
	lodsb
	cmp     al,'/'
	je      fs_switch
	cmp     al,'-'
	je      fs_switch
	cmp     al,10                           ;' '
	je      fs_end
	cmp     al,13
	je      fs_end
	jmp     fs_car_suiv
   fs_end:        
	stc
	ret
   fs_switch:
	clc
	ret
find_switch endp

analyse_param proc 
	cmp cs:[second],1
	jne not_second_switch
	ret
   not_second_switch:
	pushx   ax,si
   ap_switch:
	call    find_switch
	jnc     ap_sw_temp
	jmp     ap_fin
   ap_sw_temp:
	lodsb
	call    conv_maj
	cmp     al,'/'
	je      ap_switch
	cmp     al,'-'
	je      ap_switch
	cmp     al,'C'
	jne     ap_not_c
        push    si
	lodsb
	mov     cs:[c_color],al
        pop     si
	jmp     ap_switch
   ap_not_c:
        cmp     al,'F'
        jne     ap_not_f
        push    si
        lodsb
        mov     cs:[cnf_dsig_color],al
        pop     si
        jmp     ap_switch
   ap_not_f:
        cmp     al,'O'
	jne     not_chicago_buffer
	mov     cs:[do_f4],1
	jmp     ap_switch
   not_chicago_buffer:
	cmp     al,'H'
	jne     ap_not_h
	call    def_conf_chicago
	jmp     ap_switch
   ap_not_h:
        cmp     al,'6'
        jne     ap_not_6
        mov     cs:[video_50_add],3920
        mov     cs:[force_fifty],1
        jmp     ap_switch
   ap_not_6:
	cmp     al,'5'
	jne     ap_not_5
	mov     cs:[force_fifty],1
        mov     cs:[video_50_add],4160
	jmp     ap_switch
   ap_not_5:
	cmp     al,'P'
	jne     clav_fr
	mov     cs:[message_ou_pas],1
	jmp     ap_switch
   clav_fr:     
	cmp     al,'J'
	jne     config_par_defaut
	call    toujours_attendre
	jmp     ap_switch
   config_par_defaut:
	cmp     al,'D'
	jne     efface_ou_pas
	call    def_conf
	jmp     ap_switch
   efface_ou_pas:
	cmp     al,'N'
	jne     ecran_mono
	mov     cs:[pas_eff_ecran],1
	jmp     ap_switch
   ecran_mono:        
	cmp     al,'E'
	jne     wait_delay
	mov     cs:[message_mono],1
	jmp     ap_switch
   wait_delay:
	cmp     al,'T'
	jne     swiss_kbd
	call    prepare_timer
	jmp     ap_switch
   ap_fin:
	call    any_errors
	popx    si,ax
	ret
   swiss_kbd:
        cmp     al,'X'
        jne     no_disable
        mov     cs:[disable_esc],1
        jmp     ap_switch
   no_disable:
	cmp     al,'K'
	jne     slash_s
	cmp     cs:[doconv],1
	jne     kbd_nerror
	affiche kbd_extraparam
	mov     cs:[switch_error],1
	jmp     ap_switch
   kbd_nerror:
	mov     cs:[doconv],1
	call    @keyboards
        push    bx
	call    mov@bx
        pop     bx
	jmp     ap_switch
   slash_s:
	cmp     al,'S'
	jne     ap_m
	mov     cs:[last_conf],1
	jmp     ap_switch
   ap_m:        
	cmp     al,'G'                  ;messages gÇnants
	jne     ap_ng
	mov     cs:[ap_gen],1
	jmp     ap_switch
   ap_ng:        
        cmp     al,'I'
        jne     ap_ni
        mov     cs:[inline_off],1
        jmp     ap_switch
   ap_ni:
        cmp     al,'L'
        jne     ap_nl
        mov     cs:[message_title],1
        jmp     ap_switch
   ap_nl:
        cmp     al,'B'
        jne     ap_yesfiles
        mov     cs:[read_write_nodat],1
        jmp     ap_switch
   ap_yesfiles:
        cmp     al,'Z'
        jne     ap_nelite
        mov     cs:[elite_msg],1
        push    si
        lodsb
        cmp     al,'Z'
        jne     ap_nelitez
        mov     cs:[elite_msg],2
      ap_nelitez:
        pop     si
        jmp     ap_switch
   ap_nelite:
        cmp     al,'V'
        jne     ap_notv
        mov     cs:[no_envvar],1
        jmp     ap_switch
   ap_notv:
	cmp     al,'M'
	jne     ap_err
	call    new_message_routine
	jmp     ap_switch
   ap_err: 
	mov     cs:[switch_error],1
	affiche sw_err_switch
	mov     ah,2
	mov     dl,al
        call    elite_translate
	int     21h
	affiche passage_msg
	jmp     ap_switch
analyse_param endp

;±±±±±±± /J[][] ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± version 2.62 ±±±±
; check for always_wait options for Chicago and DOS
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
toujours_attendre proc
        pushx    si,cx
        mov      cx,2
   ta_looping:
	lodsb
        cmp     al,'C'
	jne     ta_chicago
	mov     cs:[chicago_always_wait],1
        jmp     ta_doloop
   ta_chicago:
	cmp     al,'D'
	jne     ta_ndos
	mov     cs:[toujours_wait],1
        jmp     ta_doloop
   ta_ndos:
        cmp     al,' '
        jbe     ta_dowait
        cmp     al,'/'
        je      ta_dowait
        cmp     al,'-'
        je      ta_dowait

        cmp     cx,2
        jne     ta_doloop
        affiche j_error_msg
        mov     cs:[switch_error],1
   ta_doloop:
        loop    ta_looping
	popx    cx,si
	ret
   ta_dowait:
        mov     cs:[toujours_wait],1
        mov     cs:[chicago_always_wait],1
        popx    cx,si
        ret
toujours_attendre endp

prepare_timer proc 
        push    si
pt_next:
        lodsb                                                   
        cmp     al,'C'                                           
        jne     pt_not_chicago
        mov     cl,'C'
        lodsb
        sub     al,'0'
	cmp     al,9
        jbe     npt_error
        jmp     pt_error
    npt_error:
	mov     ah,18
	mul     ah
        mov     cs:[chicago_key_delai],ax

        lodsb
        call    conv_maj
        cmp     al,'U'
        jne     pt_ch_not_u
        mov     cs:[chicago_waitu],1
        inc     si
pt_ch_not_u:
        dec     si

        jmp     pt_next
pt_not_chicago:                                                 
        cmp     al,'D'
        jne     pt_not_dos
        mov     cl,'C'
        lodsb
        sub     al,'0'
	cmp     al,9
        ja      pt_error
	mov     ah,18
	mul     ah
        mov     cs:[dos_key_delai],ax

        lodsb
        call    conv_maj                                        
        cmp     al,'U'
        jne     pt_dos_not_u
        mov     cs:[dos_waitu],1
        inc     si
pt_dos_not_u:
        dec     si

        jmp     pt_next
pt_not_dos:
        cmp     al,'/'
        jbe     pt_exit

        sub     al,'0'
	cmp     al,9
        ja      pt_error_nocl
	mov     ah,18
        mul     ah
        mov     cs:[dos_key_delai],ax
        mov     cs:[chicago_key_delai],ax

        lodsb
        call    conv_maj
        cmp     al,'U'
        jne     pt_dosch_not_u
        mov     cs:[dos_waitu],1
        mov     cs:[chicago_waitu],1
        inc     si
pt_dosch_not_u:
        dec     si

        jmp     pt_exit
pt_error_nocl:
        mov     cl,0
pt_error:
	mov     cs:[switch_error],1
        affiche timer_error_msg

        mov     ah,2
        push    ax
        mov     dl,cl
        int     21h
        pop     ax

        add     al,'0'
        mov     dl,al
        int     21h
	affiche passage_msg
pt_exit:
        pop     si
        ret
prepare_timer endp

define_timer proc
        pushx   ax,bx,cx,dx
	mov     ah,30h
	int     21h
        cmp     al,cs:[critical_version]
        jb      dt_not_chicago
        mov     ax,cs:[chicago_key_delai]
        cmp     ax,0
        je      dt_end
        mov     cs:[key_delai],ax
        mov     cs:[prepared_timer],1
        jmp     dt_end
  dt_not_chicago:
        mov     ax,cs:[dos_key_delai]
        cmp     ax,0
        je      dt_end
        mov     cs:[key_delai],ax
        mov     cs:[prepared_timer],1
  dt_end:
        popx    dx,cx,bx,ax
        ret
define_timer endp

def_conf_chicago proc
	lodsb
	cmp     al,'F'
	jne     dcc_not_ext_f
	lodsb
	cmp     al,'0'
	jb      dcc_not_ext_ff
	cmp     al,'9'
	ja      dcc_not_ext_ff 
        cmp     cs:[ext_depend],1
	jne     dcc_no_depend
	ret
   dcc_no_depend:
        mov     cs:[ext_chicago],1
	mov     cs:[config_chicago],al
	mov     cs:[chicago_default],1
	ret
   dcc_not_ext_ff:
	mov     al,'F'
   dcc_not_ext_f:
	dec     si
	cmp     cs:[ext_depend],1
	jne     dcc_no_depend_
	ret
   dcc_no_depend_:
	mov     cs:[chicago_default],1
	mov     cs:[config_chicago],al
        mov     cs:[ext_chicago],0
	ret
def_conf_chicago endp 

def_conf proc
	lodsb
	cmp     al,'F'
	jne     not_ext_f
	lodsb
	cmp     al,'0'
	jb      not_ext_ff
	cmp     al,'9'
	ja      not_ext_ff 
	cmp     cs:[ext_depend],1
	jne     no_depend
	ret
   no_depend:
	mov     cs:[ext],1
	mov     cs:[config_ext],1
	mov     cs:[config],al
	ret
   not_ext_ff:
	mov     al,'F'
   not_ext_f:
	dec     si
	cmp     cs:[ext_depend],1
	jne     no_depend_
	ret
   no_depend_:
	mov     cs:[config],al
	ret
def_conf endp 

any_errors proc
	cmp     cs:[switch_error],1
	jne     no_switch_error
	affiche sw_err_msg
   no_switch_error:        
	cmp     cs:[custom_error],1
	jne     no_switch_custom
	affiche custom_msg_error_b
   yes_switch_error:
        call    slam_enter
        cmp     al,''
	jne     swerr_nohelp
	mov     cs:[anyerrors_help],1
	call    hlp_help
	mov     cs:[anyerrors_help],0
   swerr_nohelp:
        mov     cs:[attend_timer],1
        mov     cs:[toujours_wait],1
	ret
   no_switch_custom:        
	cmp     cs:[switch_error],1
	je      yes_switch_error


        cmp     cs:[read_write_nodat],1
        jne     no_rw_possible
        cmp     cs:[last_conf],1
        jne     no_rw_possible
        mov     cs:[last_conf],0
        mov     cs:[rw_lc_mix],1
   no_rw_possible:
        ret
any_errors endp

verifie_fichier_ok proc
	pushx   si,ax,bx,cx,dx
	call    ligne_suiv
	mov     cx,32000
suiv_cfc:
	dec     cx
	jz      error_config
	call    ligne_suiv
        call    rubbish_skip
        jc      suiv_cfc
	cmp     al,'D'
	jne     suiv_cfc
        call    rubbish_skip
	cmp     al,'$'                  ;cmp     word ptr [si],'$D'
	jne     suiv_cfc
	popx    dx,cx,bx,ax,si
	ret
   error_config:        
	mov     cs:[erreur_dollar],1
	popx    dx,cx,bx,ax,si
	call    dollar_error        
	ret
verifie_fichier_ok endp

cherche_fin_config proc
        push    si
   suiv_cf:
	call    ligne_suiv
        call    rubbish_skip
	cmp     al,'D'
	jne     suiv_cf
        call    rubbish_skip
        cmp     al,'$'                  ;cmp     word ptr [si],'$D'
	jne     suiv_cf
	inc     si
	mov     cs:[fin_config],si
        pop     si
	ret
cherche_fin_config endp 

detruit_fichier proc
        pushx   ax,bx,cx,dx
        push    ds
	push    cs
	pop     ds
	mov     ah,19h
	int     21h
	add     al,'A'
	mov     bx,offset cfg_file_name
	mov     [bx],al
	mov     dx,offset cfg_file_name
	mov     ah,41h
	int     21h
	pop     ds
        popx    dx,cx,bx,ax
	ret
detruit_fichier endp

lit_ecrit_cfg proc
	pushx   ax,bx,cx,ds,cs
        pop     ds
	mov     al,'*'
	mov     bx,offset config_string
	mov     [bx],al
	cmp     cs:[ext],1
	jne     not_ext
	mov     al,'F'
	mov     [bx],al
   not_ext:
	mov     dl,cs:[config]
	mov     [bx+1],dl
	popx    ds,cx,bx,ax
	
	pushx   cx,ds,cs
        pop     ds
	mov     ah,19h                  ;perifÇrique actuel
	int     21h
	add     al,'A'
	mov     bx,offset cfg_file_name
	mov     [bx],al                         ;lecteur actuel, 1 char
	mov     dx,offset cfg_file_name
	or      cx,cx                           ;lecture ou ecriture
	jne     lit_cfg

        cmp     cs:[read_write_nodat],1
        jne     lit_ecrit_now
        call    detruit_fichier
        popx    ds,cx
        ret
   lit_ecrit_now:

        mov     ah,3Ch
	xor     cx,cx
	mov     cx,00000010b                    ;attribut cachÇ
	int     21h
        jc      lec_fin
        jnc     lec_nerror
        jmp     lec_error_3wh       ;fin
   lec_nerror:
	mov     bx,ax
	mov     ah,40h

	pushx   ax,bx,cx,dx,es,ds
        push    cs
        pop     ds
	mov     ah,40h
	mov     dx,offset cs:[configs_history]
	mov     cx,20
	int     21h
        push    cs
        pop     ds
	mov     ah,40h
	mov     dx,offset cs:[configs_ext_history]
	mov     cx,20
	int     21h
        push    cs
        pop     ds
	mov     ah,40h
	mov     dx,offset cs:[sub_level]
	mov     cx,1
	int     21h
	popx    ds,es,dx,cx,bx,ax

	jmp     lec_exec
   lit_cfg:
	mov     ax,3D00h
	int     21h
        ;jc      lec_error_3lh       ;fin
        jc      lec_fin
	mov     bx,ax
	mov     ah,3Fh

	pushx   ax,bx,cx,dx,es,ds
        push    cs
        pop     ds
	mov     ah,3Fh
	mov     dx,offset cs:[configs_history]
	mov     cx,20
	int     21h
        push    cs
        pop     ds
	mov     ah,3Fh
	mov     dx,offset cs:[configs_ext_history]
	mov     cx,20
	int     21h
	mov     ah,3Fh
	mov     dx,offset cs:[sub_level]
	mov     cx,1
	int     21h
	popx    ds,es,dx,cx,bx,ax

   lec_exec:
        push    cs
        pop     ds
	mov     dx,offset cs:[config_string]
	mov     cx,2
	int     21h
        jc      lec_error_3wwh
        jc      lec_fin
	mov     ah,3Eh
	int     21h
        jc      lec_error_3ch
   lec_fin:
	popx    ds,cx
	ret
   lec_error_3wh:
        cmp     cs:[read_write_nodat],1
        je      lec_fin
	affiche error_creating
	jmp     lec_fin
   lec_error_3lh:
        cmp     cs:[read_write_nodat],1
        je      lec_fin
	affiche error_opening
	jmp     lec_fin
   lec_error_3ch:
        cmp     cs:[read_write_nodat],1
        je      lec_fin
	affiche error_closing
	jmp     lec_fin
   lec_error_3wwh:
        cmp     cs:[read_write_nodat],1
        je      lec_fin
        affiche error_readwrite
	jmp     lec_fin
lit_ecrit_cfg endp

lit_configuration proc
	call    push_cursor
	cmp     cs:[second],1
	je      lc_no_special_error
	cmp     cs:[num_confs],0
	jne     lc_no_special_error
	call    lc_special_error_
	ret
   lc_no_special_error:                 ;was there a key pressed manwhile?
        mov     ah,1                    
        call    forbidden_keys          
	int     16h
        jz      nlconf@@
        mov     cs:[attend_timer],0
        jmp     @lconf_no_entre         
   nlconf@@:
	mov     ah,0
	int     1Ah
	mov     cs:[timer],dx
	cmp     cs:[in_chicago],1
	jne     do_not_chicago
	cmp     cs:[chicago_always_wait],1
	je      do_the_list
	jmp     attend_touche
   do_not_chicago:
	cmp     cs:[toujours_wait],1
	je      do_the_list
	jmp     attend_touche
   do_the_list:
	mov     al,' '
	jmp     lconf_no_entre
   attend_touche:
	cmp     cs:[second],1
	jne     next_touche
	mov     al,cs:[config]
	jmp     lconf_no_entre
   next_touche:        
        mov     ah,1                    ;never allow delay between key
	call    forbidden_keys          ;pressed and key verified
	int     16h
	jz      nlconf@
        jmp     @lconf_no_entre         ;key pressed -> forbidden?
   nlconf@:
	mov     ah,0                    ;-> key pressed -> jump or not
        push    dx                      ;if mov ah,1 inside
	int     1Ah                     ;key pressed -> forbidden ->KEY 
	mov     cx,dx                   ;CAN BE PResSED, since parallel intr.
        pop     dx
	call    parallel_timer
	sub     cx,dx
        call    print_delai
        cmp     cx,cs:[key_delai]
	jb      next_touche
	cmp     cs:[last_conf],1
	je      last_config

	cmp     cs:[rebooted],1
        je      last_config

        mov     al,cs:[config_ext]
        cmp     cs:[in_chicago],1
        jne     nchicago_ext_cnf
        cmp     cs:[chicago_default],1
        jne     nchicago_ext_cnf
        mov     al,cs:[ext_chicago]
   nchicago_ext_cnf:
	cmp     cs:[rebooted],1
        je      @reboot_config
	mov     cs:[ext],al
   @reboot_config:
	mov     al,cs:[config]
	jmp     no_conv_at_all
   last_config:
        mov     cl,1
        call    lit_ecrit_cfg
	call    lit_ecrit_config
        cmp     cs:[sub_level],1
        ja      special_last
	call    conv_maj
	call    verifie_config
	jc      error_last
	jmp     no_conv_at_all
   special_last:
	call    derived_liste_config
	call    verify_sub
	jc      error_last
	mov     cs:[made_address],1
	mov     cs:[to_be_made],1
	jmp     no_conv_at_all
   error_last:
	mov     cs:[sub_level],1
	call    clean_history
	call    derived_liste_config
	affiche error_last_msg
	mov     cs:[enter_count],3
	call    liste_configuration
	jmp     lconf_no_entre
   lit_config_car:
	mov     ah,0
	int     16h
	jmp     lconf_no_entre
   @lconf_no_entre:
	mov     cs:[ext],0
   lconf_no_entre:
	call    treat_ext
        cmp     al,0
        jne     @not_enter
        ret
   @not_enter:
	cmp     cs:[skip_configuration],1
	je      sk_exit
        cmp     al,'.'
	jne     @not_point
	mov     cs:[skip_configuration],1
   sk_exit:
	ret
   @not_point:
        cmp     al,'*'  ;1Bh
	jne     not_escape
        mov     cs:[fatal_error],1
	ret
   not_escape:                             ;test if the configuration is a Fkey
	cmp     cs:[ext],1                 ;c'est-Ö-dire dÇjÖ Fkey
	je      not_extended_conf
	call    treat_ext
   not_extended_conf:
	cmp     al,08h
	jne     no_help
	call    hlp_help
	jmp     lconf_no_entre
   no_help:
	cmp     al,' '
	jne     no_config_list
   	mov     cs:[enter_count],0
	mov     cs:[sub_level],1
	call    clean_history
	call    liste_configuration
	jmp     lconf_no_entre
   no_config_list:
	call    convert_keyb
   no_conv_at_all:                
        push    ax
	call    first_column
	affiche spassage_msg
	call    first_column
        pop     ax
	call    conv_maj
        cmp     cs:[message_title],1
        je      yes_key_affiche
	cmp     cs:[message_ou_pas],1
	je      no_key_affiche
   yes_key_affiche:
	affiche passage_msg
        cmp     cs:[skip_configuration],1
	je      no_key_affiche
        cmp     cs:[ext],1
	jne     no_f_key
        pushx   ax,bx,cx
        mov     al,'F'
        mov     bh,0
	mov     ah,9
        mov     cx,1
        mov     bl,cs:[cnf_dsig_color]
	int     10h
        call    advance_char
        popx    cx,bx,ax
   no_f_key:
        pushx   ax,bx,cx,dx
        mov     bh,0
	mov     ah,9
        mov     cx,1
        mov     bl,cs:[cnf_dsig_color]
	int     10h
        call    advance_char
        popx    dx,cx,bx,ax
   no_key_affiche:
	cmp     al,'.'
	jne     not_point_press
	mov     cs:[skip_configuration],1
	ret
   not_point_press:
        cmp     al,'*'  ;1Bh
	jne     not_escape_config
	mov     cs:[fatal_error],1
	ret
   not_escape_config:
	mov     cs:[temp_key],al
	call    verifie_config          ;should be better
	jc      config_error
	call    conv_maj
	mov     cs:[config],al
	ret
   config_error:
	call    force_efface_ecran
	affiche err_msg_new
	cmp     cs:[ext],1
	jne     no_ext_err
	pushx   ax,dx
	mov     ah,2
	mov     dl,'F'
        call    elite_translate
	int     21h
	popx    dx,ax
   no_ext_err:
	mov     ah,2
	mov     dl,cs:[temp_key]
        call    elite_translate
	int     21h
	affiche err_msg_old
	mov     cs:[enter_count],7
	mov     cs:[sub_level],1
	call    clean_history
	call    liste_configuration
	jmp     lconf_no_entre
lit_configuration endp

clean_history proc
	pushx   ax,bx,cx,dx,es,ds,si,di
	mov     bx,offset cs:[configs_history]
        push    cs
        pop     es
	mov     cx,20
      ch_cnf:
	mov     byte ptr es:[bx],0
	inc     bx
	dec     cx
	jnz     ch_cnf
	mov     cx,20
	mov     bx,offset cs:[configs_ext_history]
      ch_ext:
	mov     byte ptr es:[bx],0
	inc     bx
	dec     cx
	jnz     ch_ext
	popx    di,si,ds,es,dx,cx,bx,ax
	ret
clean_history endp

lc_special_error_ proc
	affiche special_error_msg
        call    slam_enter
        mov     cs:[config],'*' ;1Bh
        mov     al,'*'  ;1Bh
	mov     cs:[fatal_error],1
	ret
lc_special_error_ endp

forbidden_keys proc
	int     16h
	jz      fk_rien
        cmp     al,1Bh
        je      fk_clear_buff
        cmp     al,13
	je      fk_clear_buff
	cmp     al,9                    ;tabulator
	je      fk_clear_buff
	cmp     al,0                    ;extend key?
	jne     fk_rien
	cmp     ah,59                   ;F1...
	jb      fk_clear_buff
	cmp     ah,68                   ;F10
	ja      fk_clear_buff
   fk_rien:        
	mov     cs:[theres_key],1
	mov     ah,1
	ret
   fk_clear_buff:
	xor     ax,ax
	mov     ah,0Ch
	int     21h
	mov     ah,1
	ret
forbidden_keys endp

treat_ext proc
	cmp     al,0                    ;extend key?
	jne     nothing_ext
	mov     cs:[ext],1
	mov     al,ah
	sub     al,10
	cmp     al,':'     
	jne     nothing_ext
	mov     al,'0'      
	mov     cs:[config],al
	ret
   nothing_ext:
	mov     cs:[config],al
	ret
treat_ext endp

dollar_error proc
	pushx   ax,bx,cx,dx
	affiche msg_err_dollar
        call    slam_enter
        cmp     al,8
	jne     no_hlp
	call    hlp_help
   no_hlp:
	mov     ah,30h
	int     21h
	cmp     al,6
	jae     dos_6
	affiche msg_reboot_not6
        call    slam_enter
	call    conv_maj
	cmp     al,'R'
	jne     no_r
	call reboot
   no_r:
       sub     bx,bx                    ;this is to simulate esCAPE if
       mov     ds,bx                    ;AUTOCONF is ever to restart with
       mov     al,'*'   ;1Bh                   ;for ex. DOSDATA
       mov     ds:[0EAh*4],al
	popx    dx,cx,bx,ax
	ret
   dos_6:
	affiche msg_reboot_6
        call    slam_enter
	call    conv_maj
	cmp     al,'R'
	jne     no_r
	call    reboot
dollar_error endp

reboot proc
	mov si,40h
	mov es,si
	mov es:word ptr [0072h],1234h
	cli
	db 0EAh
	dw 0000h,0FFFFh
reboot endp

compacte_config proc
        mov     cs:[dans_config],1
	call    ligne_suiv
	mov     cs:[prem_ligne],si
	mov     cs:[debut_ligne],si
   compacte_lsuiv:
        call    rubbish_skip
	cmp     al,'D'
	jne     no_special_cmd
  
        call    rubbish_skip

	cmp     al,'$'
	jnz     nfin_compacte
	jmp     fin_compacte
    nfin_compacte:
	cmp     al,'*'
	jne     no_special_cmd
        cmp     cs:[made_one],1
        je      fin_compacte

	mov     cs:[dans_config],0
        call    rubbish_skip
	
	cmp     cs:[ext],1              
	jne     not_ext_conf_dans
	
	cmp     al,'F'
	jne     no_special_cmd 
	lodsb
	jmp     not_ext_conf2
   not_ext_conf_dans:
	cmp     al,'F'
	jne     not_ext_conf2
	lodsb
	cmp     al,'0'
	jb      couldbe_ok
	cmp     al,'9'
	ja      couldbe_ok
	jmp     no_special_cmd
   couldbe_ok:
	dec     si
	mov     al,'F'
   not_ext_conf2:
	cmp     al,cs:[config]
	jne     no_special_cmd
   well_conf:     
        mov     cs:[made_one],1
	mov     cs:[dans_config],1
        cmp     cs:[message_title],1
        je      yes_title@
	cmp     cs:[message_ou_pas],1
	je      copie_ligne
	cmp     cs:[skip_configuration],1
	je      copie_ligne
   yes_title@:
	call    acn_derived
	jmp     copie_ligne
   no_special_cmd:
	cmp     cs:[dans_config],0
	jne     nomodif
   copie_ligne:
	mov     di,cs:[debut_ligne]
	call    ligne_suiv
	mov     cx,cs:[fin_config]
	sub     cx,si
        push    ds
        pop     es
	rep     movsb
	mov     si,cs:[debut_ligne]
	jmp     compacte_lsuiv
   nomodif:
	call    ligne_suiv
	mov     cs:[debut_ligne],si
	jmp     compacte_lsuiv
   fin_compacte:
        ret
compacte_config endp

clean_and_move proc
	mov     si,cs:[debut_ligne]
   raccorde:
	dec     si
	cmp     byte ptr [si],10
	je      raccorde
	mov     di,cs:[fin_config]
	dec     di
	mov     cx,si
	sub     cx,cs:[prem_ligne]
	add     cx,3
	std
	rep     movsb
	cld
        mov     cx,cs:[prem_ligne]
	sub     cx,3
   cleanall:
        mov     byte ptr [di],' '
	dec     di
	cmp     di,cx
	ja      cleanall
        ret
clean_and_move endp

bonjour_bonsoir proc
	pushx   ax,bx,cx,dx
	mov     ah,2Ch
	int     21h
	cmp     ch,17
	ja      soir
	cmp     ch,8
	jb      matin_bonheur
	affiche msg_matin
	popx    dx,cx,bx,ax
	ret
   soir:
	cmp     ch,22
	ja      stop_working
	affiche msg_soir
	popx    dx,cx,bx,ax
	ret
   stop_working:
	affiche msg_stop_working
	popx    dx,cx,bx,ax
	ret
   matin_bonheur:
	cmp     ch,4
	jb      stop_working
	affiche msg_matin_bonheur
	popx    dx,cx,bx,ax
	ret
bonjour_bonsoir endp

type_matic proc
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;INTERRUPT 16h, Fonction 03h : DÇfinir le taux de rÇpÇtition...
;           ah= 03h
;           al= 05h
;           bh= Ralentissement jusqu'Ö la mise en place de la rÇpÇtition
;           bl= Taux de rÇpÇtition
;        bh peut etre Çgal Ö :
;         00b : 3/4 de sec
;         01b : 1/2 sec
;         10b : 3/4 de sec
;         11b: 1 sec
;        bl: de 01h Ö 1Fh
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±        
	pushx   ax,bx,bp,sp,es,ds
	mov     ah,3h
	mov     al,5h
	mov     bh,0
	mov     bl,1
	int     16h
	popx    ds,es,sp,bp,bx,ax
	ret
type_matic endp

new_message_routine proc                ; new routine for custom messages
	pushx   bx,cx,dx
        push    cs
        pop     es
        mov     cs:[crochet],0
	lodsb
	mov     cs:[thesipos],si
	cmp     al,'['
	jne     not_mul
	mov     cs:[crochet],1
	lodsb
	mov     cs:[thesipos],si
        push    ax
   rollon:                                
	lodsb
	cmp     al,']'
	jne     rollon
        pop     ax
   not_mul:
	cmp     al,'1'
	jne     not_msg_matin_bonheur
	
	mov     bx,offset msg_matin_bonheur     ;--------------------------
   nmmat_for_msg_matin_bonheur:                 
	call    new_find_switch                 ; matin bonheur to be modified
	jnc     the_message_end                 
        call    msg_encoder
	mov     es:[bx],al
	inc     bx                              
	jmp     nmmat_for_msg_matin_bonheur     ;-------------------------
		
   not_msg_matin_bonheur:
	
	cmp     al,'2'
	jne     not_msg_matin
	
	mov     bx,offset msg_matin             ;--------------------------
   nmmat_for_msg_matin:                         
	call    new_find_switch                 ; matin to be modified
	jnc     the_message_end                 
        call    msg_encoder
        mov     es:[bx],al
	inc     bx                              
	jmp     nmmat_for_msg_matin             ;-------------------------

   not_msg_matin:
	cmp     al,'3'
	jne     not_msg_soir
	
	mov     bx,offset msg_soir
   nmmat_for_msg_soir:
	call    new_find_switch
	jnc     the_message_end
        call    msg_encoder
	mov     es:[bx],al
	inc     bx
	jmp     nmmat_for_msg_soir
   not_msg_soir:
	
	cmp     al,'4'
	jne     message_error
	
	mov     bx,offset msg_stop_working      ;--------------------------
   nmmat_for_msg_stop_working:                  
	call    new_find_switch                 ; msg_soir to be modified
	jnc     the_message_end                 
        call    msg_encoder
        mov     es:[bx],al
	inc     bx                              
	jmp     nmmat_for_msg_stop_working      ;-------------------------
   message_error:
	call    error_custom_msg
	cmp     cs:[crochet],1
	je      yes_crochet
   message_error_loop:
	call    new_find_switch
	jc      message_error_loop
	jmp     rollback
   the_message_end:    
	mov     al,13
	mov     es:[bx],al
	inc     bx
	mov     al,10
	mov     es:[bx],al
	inc     bx
	mov     al,255
	mov     es:[bx],al
	mov     cs:[caps],1
   rollback:        
	cmp     cs:[crochet],1
	je      yes_crochet
	mov     si,cs:[thesipos]
	jmp     pas_crochet
   yes_crochet:
	mov     si,cs:[thesipos]
	lodsb
	cmp     al,']'
	je      pas_crochet
	mov     cs:[thesipos],si
        push    ax
	jmp     rollon
   pas_crochet:
	popx    dx,cx,bx
	ret
new_message_routine endp

msg_encoder proc
        cmp     al,' '
        jb      me_nop
        cmp     al,240
        ja      me_nop
        add     al,cs:[increment_byte]
	xor     al,cs:[xor_byte]
     me_nop:
        ret
msg_encoder endp

error_custom_msg proc
	pushx   ax,bx,cx,dx
	affiche custom_msg_error_a
	mov     dl,al
        call    elite_translate
	mov     ah,2
	int     21h
	affiche passage_msg
	mov     cs:[toujours_wait],1
	mov     cs:[custom_error],1
	popx    dx,cx,bx,ax
	ret
error_custom_msg endp

new_find_switch proc                    ; new proc for finding the switch or
	jmp     switch__                ;enter for new_message routin
   new_switch_suiv:                     ;tuesday,23rd November 1993
        mov     al,' '
        call    msg_encoder
        mov     es:[bx],al
	inc     bx
   switch__:
	lodsb
	cmp     al,'#'
	jne     no_return_toput
	mov     dl,al
	lodsb
	cmp     dl,al
	jne     not_dbl
	jmp     no_return_toput
   not_dbl:
	dec     si
	mov     al,10
	mov     es:[bx],al
	inc     bx
        mov     al,13
	stc
	ret
   no_return_toput:
        call    new_majmin
	cmp     al,10
	je      a_new_switch
	cmp     al,13
	je      a_new_switch
	cmp     al,'/'
	je      new_switch
	cmp     al,'-'
	je      new_switch
	cmp     al,' '
	je      new_switch_suiv
	stc
	ret
   a_new_switch:
	clc 
	ret
   new_switch:
	mov dl,al
	lodsb
	cmp al,dl
	jne no_repeats
	stc
	ret
   no_repeats:
	clc 
	ret
new_find_switch endp

new_majmin proc                                 ; new maj-min convert for 
	cmp     al,'|'                          ;personalized messages
	jne     no_change_majmin                ;tuesday 23rd November 1993
	lodsb                                   
	cmp     cs:[caps],1
	je      change_tomin
	mov     cs:[caps],1
	jmp     no_change_majmin
   change_tomin:
	mov     cs:[caps],0
   no_change_majmin:
	cmp     cs:[caps],1
	jne     minuscules
	call    conv_maj
	ret
   minuscules:
	call    conv_min
	ret
new_majmin endp

newing proc
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
        push    cs                              ;es=cs
        pop     es
	mov     cs:[liste.c_c],0
	mov     dl,es:[bx]                      ;le premier caractäre -> dl
        cmp     dl,252  ;''
	jne     np_always                       ;erreurs, etc--> toujours aff.
	inc     bx                              ;caractäre suivant
	mov     dl,es:[bx]                      ;
	cmp     cs:[message_ou_pas],1           ;afficher?
	jne     np_always                       ;oui->np_always
	popx    ds,es,di,si,dx,cx,bx,ax         ;sinon retour
	mov     cs:[liste.attrib],7
	ret
   np_always:
        cmp     dl,7
	jne     not_beep
	call    beep
	jmp     np_next_char
   not_beep:
	cmp     dl,10
	jne     np_not_enter_count
	call    affiche_buffer
	cmp     cs:[liste.ab_escape],1
	je      np_end
	cmp     cs:[skip_configuration],1
	je      np_end
	mov     dl,13
	mov     ah,2
	int     21h
	mov     dl,10
	int     21h
	inc     cs:[liste.line_count]
   np_next_char:
	inc     bx
	mov     dl,es:[bx]
	jmp     np_always
   np_not_enter_count:
	cmp     dl,'˝'                          ;code COULEUR?
	jne     np_no_color                     ; NON, ne pas changer l'attribut 

        mov     al,dl
        inc     bx
        mov     dl,es:[bx]
        cmp     al,dl
        jne     not_dbl_color
        mov     dl,253
        jmp     np_no_color
   not_dbl_color:
        dec     bx
   np_make_color:

        inc     bx                              ;caractäre suivant
	mov     dl,es:[bx]                      ;dans dl
	cmp     cs:[message_mono],1             ;message monochrome?
	jne     np_change_color                 ;non, alors garder la couleur
	mov     dl,7                            ;attribut blanc monochrome
   np_change_color:
	mov     cs:[liste.attrib],dl                  ;attribut couleur
	jmp     np_next_char
   np_no_color:        
	cmp     dl,255                          ;fin du message?
	jne     np_naffiche                      ;ou->afficher le message
	call    affiche_buffer
   np_end:        
	mov     cs:[liste.line_count],0
	popx    ds,es,di,si,dx,cx,bx,ax
	mov     cs:[liste.attrib],7
	ret
   np_naffiche:        
        cmp     dl,32   ;28                           ;decodeur
        jb      np_no_dec
	cmp     dl,39
	je      np_no_dec
        cmp     dl,253
        je      np_no_dec
	cmp     dl,254
	je      np_no_dec
	xor     dl,cs:[xor_byte]
	sub     dl,cs:[increment_byte]
   np_no_dec:
	cmp     dl,254                          ;˛ compressed same char
	jne     np_not_lines
	call    char_redo
   cr_reroll:    
	call    WaitVSync
	call    save_c_buffer   ;reroll the chars
	dec     cl              ;to 0
	jnz     cr_reroll       ;no->jump
	inc     bx
	mov     dl,es:[bx]
	jmp     np_always        
   np_not_lines:
	cmp     dl,23                           ;en dessous de 33 (23) 13
	ja      np_never_color                  ;couleur
	call    affiche_buffer        
	cmp     cs:[liste.ab_escape],1
	je      np_end
	cmp     cs:[skip_configuration],1
	je      np_end
        call    elite_translate
	mov     ah,2
	int     21h
	inc     bx
	mov     dl,es:[bx]
	jmp     np_always
   np_never_color:        
	call    save_c_buffer
	inc     bx
	mov     dl,es:[bx]
	jmp     np_always
newing endp

char_redo proc
	inc     bx
	mov     dl,es:[bx]      ;get next caracter, the number of chars
        cmp     dl,32
        jb      cr_noxor
        xor     dl,cs:[xor_byte]
	sub     dl,cs:[increment_byte]
   cr_noxor:
	inc     bx              ;next caracter, the letter itself
	mov     cl,es:[bx]
	sub     cl,100          ;correct the counter
	ret     
char_redo endp

save_c_buffer proc
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
        push    cs
        pop     es
	cmp     cs:[liste.c_c],0
	jne     sc_not_again
	mov     bx,offset wrtstr
	mov     cs:[liste.wrtpos],bx
   sc_not_again:
	mov     bx,cs:[liste.wrtpos]
        call    elite_translate
	mov     es:[bx],dl
	inc     bx
	mov     al,cs:[liste.attrib]        
	mov     es:[bx],al
	inc     bx
	mov     cs:[liste.wrtpos],bx
	inc     cs:[liste.c_c]
	popx    ds,es,di,si,dx,cx,bx,ax
	ret
save_c_buffer endp

affiche_buffer proc
	mov     cs:[liste.ab_escape],0
	mov     cs:[liste.absmsg_pos],bx
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
        push    cs
        pop     es
	mov     bp,offset wrtstr
	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	mov     cx,cs:[liste.c_c]
	mov     al,3        
	mov     ah,13h
	int     10h
	mov     cs:[liste.c_c],0
	popx    ds,es,di,si,dx,cx,bx,ax
	mov     bx,cs:[liste.absmsg_pos]
	ret
affiche_buffer endp

goto_special_config proc
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; GOes TO A SPECIal CONFIGURATION, INclUdiNG IT'S DEPTH
; needs:
; cs:[TOP_CONFIG]
; cs:[TOP_EXT]
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	mov     al,cs:[top_config]
	mov     bl,al                   ;bl<-al choosed conf in bl
   gsc_v_next:
	call    ligne_suiv              ;next line
        call    rubbish_skip
        cmp     al,'D'                  ;D... evice?
	jne     gsc_v_next                  ;no -> again
   gsc_v_char:        
        call    rubbish_skip
        cmp     al,'$'
        je      gsc_v_config_ok
        cmp     al,'*'                  ;else: device=*...?
	jne     gsc_v_next                  ;no -> again

	call    which_level
	mov     ch,cs:[need_level]
	cmp     cs:[this_level],ch
	jne     gsc_v_next
	mov     ch,0
   gsc_again:
	inc     ch
        call    rubbish_skip
        jc      gsc_v_next
	cmp     ch,cs:[need_level]
	jnae    gsc_again
	cmp     cs:[top_ext],1
	jne     gsc_not_ext_conf
	cmp     al,'F'
	jne     gsc_v_next                  ;not_ext_conf
	lodsb
	jmp     gsc_not_ext_conf
   gsc_not_ext_conf:        
	cmp     al,'F'
	jne     gsc_not_ext_possible
	lodsb
	cmp     al,'0'
	jb      gsc_couldbe_ok_
	cmp     al,'9'
	ja      gsc_couldbe_ok_
	jmp     gsc_v_next
   gsc_couldbe_ok_:
	dec     si
	mov     al,'F'
   gsc_not_ext_possible:
	cmp     al,bl                   ;choosed conf=this one
	je      gsc_v_config_ok             ;yes -> fine
	jmp     gsc_v_next                  ;no -> next config
   gsc_v_config_ok:
	ret
goto_special_config endp

moveto_needed_conf proc
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; uses goto_special_config to make the correct move towards the correct
; sub configuration in the right depth
;       needs:
; prem_ligne
; sub_level
; configs_ext_history
; need_level
; configs_history
; top_config
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	pushx   ax,bx,cx,dx
	mov     cs:[need_level],1
	cmp     cs:[sub_level],1
	jne     next_level
	popx    dx,cx,bx,ax
	ret
   next_level:
        push    cs
        pop     es
	mov     bx,offset cs:[configs_ext_history]
	mov     cl,0
      reinc@@@@:
	inc     bx
	inc     cl
	cmp     cl,cs:[need_level]
	jne     reinc@@@@
	mov     al,es:[bx]
	mov     cs:[top_ext],al

        push    cs
        pop     es
	mov     bx,offset cs:[configs_history]
	mov     cl,0
      reinc@@@:
	inc     bx
	inc     cl
	cmp     cl,cs:[need_level]
	jne     reinc@@@
	mov     al,es:[bx]

	cmp     al,0
	je      no_need_anymore
	mov     cs:[top_config],al
	call    goto_special_config
	inc     cs:[need_level]
	jmp     next_level
   no_need_anymore:
	popx    dx,cx,bx,ax
	ret
moveto_needed_conf endp 

derived_liste_config proc
	mov     cs:[ext_list],'/'
	mov     cs:[ext_put],0
        mov     cs:[alpha_letter],32
	pushx   ax,bx,cx,dx,si

        call    moveto_needed_conf

	mov     cs:[group_address],si
        push    cs
        pop     es
	mov     cs:[num_confs],0
	mov     bx,offset cs:[configs_string]
   yes_alpha:
        mov     cs:[in_config],0
	cmp     cs:[ext_list],'9'
	ja      lc_no_ext_inc
	inc     cs:[ext_list]
        push    si
	jmp     list_suiv
   lc_no_ext_inc:
        mov     cs:[in_config],0
	inc     cs:[alpha_letter]
	cmp     cs:[alpha_letter],255
	jne     nfin_list
	jmp     fin_list
   nfin_list:
        push    si
   list_suiv:
	call    ligne_suiv
        call    rubbish_skip
        jc      list_suiv

	cmp     al,'D'
	jne     list_suiv
        call    rubbish_skip
        jc      list_suiv
        
        cmp     al,'$'
	jne     lc_temp_id0
   no_alpha@:
	jmp     no_alpha
   lc_temp_id0:
	cmp     al,'*'
	jne     list_suiv

        cmp     cs:[in_config],1
        je      no_alpha@

	call    which_level
	mov     ch,cs:[sub_level]
	cmp     cs:[this_level],ch
	jb      no_alpha@
	cmp     cs:[this_level],ch
	jne     list_suiv
	mov     ch,0
   lc_again:
	inc     ch
        call    rubbish_skip
        jc      list_suiv
	cmp     ch,cs:[sub_level]
	jnae    lc_again

	cmp     al,'F'
	jne     not_ext_alpha
	lodsb
	cmp     al,'0'
	jb      not_ext_alpha_f
	cmp     al,'9'
	ja      not_ext_alpha_f
	
	cmp     cs:[ext_list],'9'
	ja      list_suiv       ;not_ext_alpha_f
	
	cmp     al,cs:[ext_list]        ;[alpha_letter]
	jne     list_suiv
	mov     dl,al
	mov     al,'F'
	call    save_configs_string
	mov     al,dl
	mov     cs:[ext_put],1
	jmp     lc_ex_list      ;not_ext_alpha
   not_ext_alpha_f:        
	mov     al,'F'
	dec     si
   not_ext_alpha:
	mov     cs:[ext_put],0
	cmp     al,cs:[alpha_letter]
	je      lc_ex_list
	jmp     list_suiv
   lc_ex_list:        
	call    nconf
	call    save_configs_string
	cmp     cs:[ext_put],1
	je      no_space
	mov     al,' '
	call    save_configs_string
   no_space:        
	mov     cs:[ext_put],0
	mov     al,''
	call    save_configs_string
	cmp     cs:[num_confs],1
	jne     lc_nzero
	mov     al,'˙'
	call    save_configs_string
   lc_nzero:
	call    ps_derived_liste_config
	jnc     lc_dontcare
	mov     al,''
	call    save_configs_string
        lodsb
   lc_dontcare:
        mov     cs:[in_config],1
        call    affiche_config_name
	mov     cs:[caps],1
	jmp     list_suiv
   no_alpha:
        pop     si
	jmp     yes_alpha
   fin_list:
	sub     bx,2
	mov     al,255
	call    save_configs_string
	mov     cs:[the_first],1
	popx    si,dx,cx,bx,ax
	ret
derived_liste_config endp

ps_derived_liste_config proc
	pushx   ax,bx,cx,dx,si
   psd_next_line:
	call    ligne_suiv
        call    rubbish_skip
	cmp     al,'D'
	jne     psd_next_line
        call    rubbish_skip
        jc      psd_next_line
	cmp     al,'$'                  ;Device=$ ? (d$ out of device=$)
	je      psd_no            ;device=$ -> no config found like that
	cmp     al,'*'                  ;else: device=*...?
	jne     psd_next_line                  ;no -> again

	call    which_level
	mov     ch,cs:[need_level]
	cmp     cs:[this_level],ch
	jbe     psd_no
	jmp     psd_yes
psd_no:
	popx    si,dx,cx,bx,ax
	clc
	ret
psd_yes:
	popx    si,dx,cx,bx,ax
	stc
	ret
ps_derived_liste_config endp

lefts proc near
        push    cx
	mov     bh,0
	mov     ah,3
	int     10h
	mov     ah,2
	mov     dl,76
	int     10h  
	mov     ah,2
        pop     cx
	mov     dl,cl
	int     21h
	call    first_column
	ret
lefts endp

lefts_get_gr proc near
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ah,2
	mov     dl,76
	int     10h
	mov     ah,8
	int     10h
	mov     cs:[lettergleft],al
	ret
lefts_get_gr endp

leftsput_gr proc near
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ah,2
	mov     dl,76
	int     10h
	mov     ah,2
	mov     dl,cs:[lettergleft]
	int     21h
	ret
leftsput_gr endp


which_level proc
        push    si
	mov     cs:[this_level],0
wl_inc:
	cmp     al,'*'
	jne     no_level
	inc     cs:[this_level]
        call    rubbish_skip
        jc      bad_level
	jmp     wl_inc
no_level:
        pop     si
	ret
bad_level:
        mov     cs:[this_level],-1
        pop     si
        ret
which_level endp

nconf proc
        push    ax
	inc     cs:[num_confs]
	cmp     cs:[num_confs],26
	jne     lc_npage
	mov     al,249  ;˘
	call    save_configs_string
   lc_npage:
	cmp     cs:[num_confs],51
	jne     lc_npage@
	mov     al,248  ;¯
	call    save_configs_string
   lc_npage@:
        pop     ax
	ret
nconf endp

liste_configuration proc
        
        call   page_one_address
        cmp    cs:[iloom_enabled],1
        jne    lc_group_not_found

;±U±N±D±E±R±±C±O±N±S±T±R±U±C±T±I±O±N±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;iLOOM 1.0
; now working: - main menu existance is checked and shown if exists.
;              - existant configurations can be correctly selected.
; to do:
;              #1 verification for profound lists (update verify_sub)
;              #2 sub-groups & reality correspondance
;              #3 sub-groups' config chooser
;                 
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;±iLOOM 1.0 integration - read and update ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
         pushx   ax,bx,cx,dx,es,si,di,ds

         push   cs
         pop    ds
         call    OpenFile
         jc      restart_liste_now@
         call    LoadGroupInfo
         mov     cs:[NewGroup],0        ;main group
     restart_liste_now@:
         popx    ds,di,si,es,dx,cx,bx,ax                               

   restart_liste_now:
        cmp    cs:[iloom_enabled],1
        jne    lc_group_not_found

;± check for main group in the file ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
         mov     ax, NewGroup
         call    SearchGroup
         cmp     eax, 0FFFFFFFFh
         je      lc_group_not_found
         call    iloom
         cmp     cs:[chosenlist],1
         je      rln_exit
         jmp     restart_liste_now
      rln_exit:
         mov    bx,cs:[MenuListBx]
         mov    ax,MenuList[bx].Id
         mov    cs:[config],al
         mov    cs:[ext],0
         mov    al,cs:[config]
         call   verifie_config
         jc     restart_liste_now
         ret      
;± normal procedure, now totally independent from iLOOM ±±±±±±±±±±±±±±±±±±±±±

   lc_group_not_found:
        call    first_column
	clc
        mov     cs:[lend],0
        cmp     cs:[message_mono],1
        je      dlc_lc
        mov     al,cs:[cnf_dsig_color]
        mov     cs:[l_color],al
   dlc_lc:
	cmp     cs:[ap_gen],1
	je      dlc_no_msg
        cmp     cs:[message_ou_pas],1
        je      dlc_no_msg
	add     cs:[enter_count],7
	affiche msg_choosec
   dlc_no_msg:
	mov     cs:[ext],0
	call    push_cursor
        push    cs
        pop     es
   dlc_beg:        
        mov     cs:[lbeg],1
	mov     bx,offset configs_string
   dlc_start:        
	inc     bx
	mov     al,es:[bx]
	cmp     al,250
	jne     dlc_not_250
	mov     cs:[lbeg],1
	jmp     dlc_start
   dlc_not_250:
	call    effectif_config
	cmp     al,13
	jne     dlc_not_inc_enter
        inc     cs:[enter_count]
        cmp     cs:[message_mono],1
        je      dlc_not_inc_enter
        mov     ch,cs:[cnf_dsig_color]
        mov     cs:[l_color],ch
   dlc_not_inc_enter:
	cmp     cs:[force_fifty],1
	jne     dlc@fif   
	cmp     cs:[enter_count],50
	jne     dlc_not_enter     
	mov     cs:[enter_count],0
	jmp     dlc_end
   dlc@fif:
	cmp     cs:[enter_count],25  
	jne     dlc_not_enter
	mov     cs:[enter_count],0
	jmp     dlc_end
   dlc_not_enter:        
	mov     cs:[end_achived],1
   dlc_not_beg:
	cmp     al,255
	jne     dlc_nend
	mov     cs:[lend],1
	jmp     dlc_end
   dlc_nend:
	mov     cs:[end_achived],0
	cmp     al,240
	jne     dlc_nottwofive
	mov     al,255
        mov     cs:[l_color],7
   dlc_nottwofive:
        ;--------------------
        cmp     al,253
        jne     dlc_nocolor
        inc     bx
        mov     al,es:[bx]
        cmp     cs:[message_mono],1
        je      dlc_color@
        mov     cs:[l_color],al
   dlc_color@:
        jmp     dlc_start
   dlc_nocolor:
        ;--------------------
        cmp     al,32
        jae     dlc_color
   dlc_nocolor_two:
        mov     ah,2
        mov     dl,al
        call    elite_translate
        int     21h
        jmp     dlc_start
   dlc_color:
        cmp     al,240
        jae     dlc_nocolor_two
        pushx   ax,bx,cx
        mov     dl,al
        call    elite_translate
        mov     al,dl
        mov     bh,0
	mov     ah,9
        mov     cx,1
        mov     bl,cs:[l_color]
	int     10h
        call    advance_char
        popx    cx,bx,ax
        jmp     dlc_start
   dlc_end:       
	call    get_last_pos
	pushx   bx,cx,dx
	call    beg_pos_plus
	call    high_light
	cmp     cs:[restart_liste],1
	jne     @restart_liste_now
	mov     cs:[restart_liste],0
	popx    dx,cx,bx
	jmp     restart_liste_now
@restart_liste_now:

	cmp     cs:[first_line],1
	je      dlc_first_line
	cmp     cs:[last_line],1
	je      dlc_last_line
	call    pop_cursor
	
	cmp     cs:[show_conf_choose],1
	jne     dlc_not_tab
	mov     ax,cs:[scm_ch_conf]
	mov     cs:[config],al
	mov     cs:[ext],ah
   dlc_not_tab:
	mov     cs:[from_list],0
	popx    dx,cx,bx
	ret
   dlc_temp_beg:
	jmp     dlc_beg
   dlc_last_line:
	popx    dx,cx,bx
	mov     cs:[enter_count],24 
	cmp     cs:[force_fifty],1
	jne     dlc@@fifty
	mov     cs:[enter_count],49
   dlc@@fifty:
	cmp     cs:[end_achived],1
	je      dlc_end@
	mov     cs:[lend],0
	jmp     dlc_start
   dlc_end@:
	jmp     dlc_end
   dlc_first_line:        
	popx    dx,cx,bx
	call    force_efface_ecran
	mov     cs:[enter_count],0
	mov     cs:[lbeg],0
   dlc_again_dec:
	dec     bx        
	call    isit_beginning
	jc      dlc_temp_beg
	mov     al,es:[bx]
	cmp     al,13 
	jne     dlc_again_dec
	inc     cs:[enter_count]        
	cmp     cs:[force_fifty],1
	jne     dlc@@@fifty
	cmp     cs:[enter_count],50
	je      dlc_again_dec_
	jmp     dlc_again_dec
   dlc@@@fifty:
	cmp     cs:[enter_count],25 
	jne     dlc_again_dec 
   dlc_again_dec_:        
	dec     bx
	call    isit_beginning
	jc      dlc_temp_beg
	mov     al,es:[bx]
	cmp     al,240
	jne     dlc_again_dec_
	sub     bx,3  
	mov     cs:[enter_count],0
	mov     cs:[lend],0
	mov     cs:[lbeg],0
	jmp     dlc_start
liste_configuration endp

effectif_config proc
        cmp     cs:[@fifty],1
	je      ec_five
	cmp     al,'¯'  ;249
	je      ec_@end
	cmp     al,'˘'  ;249
	jne     ec_end
	mov     cs:[lbeg],0
   ec_five:
	cmp     al,'˘'
	je      ec_@end
	cmp     al,'¯'  ;249
	jne     ec_end
	mov     cs:[lbeg],0
   ec_@end:        
	inc     bx
	mov     al,es:[bx]
   ec_end:
	ret
effectif_config endp

beg_pos_plus proc
	cmp     cs:[last_line],1
	jne     bp_first_line
	ret
bp_first_line:
        push    bx
	mov     ah,2
	mov     bh,cs:[curpage]
	mov     dh,1 
	mov     dl,0
	int     10h
        pop     bx
	ret
beg_pos_plus endp

force_efface_ecran proc
	pushx   ax,bx,cx,dx
	mov     dl,cs:[pas_eff_ecran]
        push    dx
	mov     cs:[pas_eff_ecran],0
	call    efface_ecran
        pop     dx
	mov     cs:[pas_eff_ecran],dl
	popx    dx,cx,bx,ax
	ret
force_efface_ecran endp        

isit_beginning proc
	pushx   ax,bx,cx,dx
	cmp     bx,offset configs_string
	jne     not_yet
	popx    dx,cx,bx,ax
	mov     cs:[enter_count],0
	stc
	ret
not_yet:
	popx    dx,cx,bx,ax
	clc
	ret
isit_beginning endp

get_last_pos proc
	pushx   bx,ax,dx
	mov     ah,3
	mov     bh,cs:[curpage]
	int     10h
	mov     cs:[last_pos],dx
	popx    dx,ax,bx
	ret
get_last_pos endp

save_configs_string proc
	cmp     al,'|'
	je      save_ok
	cmp     al,13
	je      save_reset
	cmp     al,10
	je      save_reset
	inc     cs:[count]
	cmp     cs:[count],80
	jnae    save_ok
	ret
   save_ok:
	inc     bx
	mov     es:[bx],al
	ret
   save_reset:
	mov     cs:[count],0
	jmp     save_ok
save_configs_string endp

high_light proc
        mov     cs:[first_line],0
	mov     cs:[last_line],0
	jmp     hl_start
   hl_again:
	cmp     cs:[restart_liste],1
	je      hl_fl
	cmp     cs:[first_line],1
	je      hl_fl
	cmp     cs:[last_line],1
	jne     hl_start
   hl_fl:        
	ret
   hl_start:
        mov     bh,0
	mov     ah,3
	int     10h
   not_new_config:
	cmp     cs:[incdec],1
	jne     decrement
	add     dh,2
   decrement:
	cmp     cs:[incdec],2
	jne     decrement_
	inc     dh
   decrement_:
	dec     dh
	call    verify_dh_position
	mov     dl,2 ;1
	mov     ah,2
	int     10h
	mov     ah,8
	int     10h
	
	cmp     al,255
	jne     not_new_config
       
	mov     bh,cs:[curpage]
	mov     dl,0        
	mov     ah,2
	int     10h
        call    lightline
        mov     dl,0
	mov     ah,2
	int     10h
        push    ax
	jmp     cursor_mov
   cursor_aigre:
	mov     cs:[chosenlist],0
	call    beep
   cursor_mov:
        pop     ax
	mov     cs:[ext],0

	call    cursor_movement

	jc      hl_again
	cmp     cs:[chosenlist],1
	je      cursor_noaigre
	cmp     cs:[skip_configuration],1
	je      cursor_noaigre
        cmp     al,'*';1Bh
	je      cursor_noaigre
	cmp     al,'.'
	je      cursor_noaigre
	cmp     al,8
	je      cursor_help
        push    ax
	call    treat_ext
	call    convert_keyb
	call    verify_sub
	jc      cursor_aigre
        mov     cs:[chosen_list],1
	call    make_address
	call    light_selected_conf
        pop     ax
   cursor_noaigre:
        push    ax                      ;a config has been selected
	mov     dx,cs:[last_pos]
	mov     bh,cs:[curpage]
	mov     ah,2
	int     10h
	mov     cs:[liste.attrib],7
	affiche passage_msg
	mov     cs:[letterr],' '
	mov     cs:[letterg],' '
	mov     cs:[lettergleft],' '
        call    make_line_color
        call    darkline
        pop     ax
	cmp     cs:[chosenlist],1
	jne     cursor_aigreur
	mov     al,cs:[config]
	mov     ah,cs:[ext]
    cursor_aigreur:
	ret
   cursor_help:
	mov     cs:[from_list],1
	call    hlp_help
	mov     cs:[restart_liste],1
	mov     cs:[enter_count],0
	ret
high_light endp

clean_upper proc
	pushx   ax,bx,cx,dx,si
	lds     bx,cs:[dword ptr req_ofs]       ;initialisation
	lds     si,[bx+18]                      ; si <- CONFIG.SYS position
	mov     cx,si
        push    ds
        pop     es
	mov     di,cs:[start_address]
	call    ligne_prec
   racroche:
	dec     di
	cmp     byte ptr es:[di],10
	je      racroche
   cleanit:
        mov     byte ptr [di],0
        ;' '
        dec     di
        cmp     di,cx
        ja      cleanit
	popx    si,dx,cx,bx,ax
	ret
clean_upper endp

find_finish proc
	pushx   ax,bx,cx,dx
	mov     si,cs:[start_address]
    ff_next:
	call    ligne_suiv
        call    rubbish_skip
        jc      ff_next
	cmp     al,'D'
	jne     ff_next
        call    rubbish_skip
        jc      ff_next
	cmp     al,'$'
	je      ff_finish@
	cmp     al,'*'
	jne     ff_next
	jmp     ff_finish
    ff_finish@:
	call    ligne_prec
    ff_finish:
	call    ligne_prec
	mov     cs:[end_address],si
	popx    dx,cx,bx,ax
	ret
find_finish endp

setenvvar    proc
        cmp     cs:[no_envvar],1
        jne     snv_next
        ret
     snv_next:
        pushx   ax,bx,cx,dx
	mov     ah,30h
	int     21h
        cmp     al,6
        jae     snv_ok
        popx    dx,cx,bx,ax
        affiche dos_five_set
        call    slam_enter
        ret
     snv_ok:
        popx    dx,cx,bx,ax

        pushx   ax,bx,cx,dx,es,si,di
        mov     si,cs:[fin_config]
        call    ligne_suiv
        mov     cx,si
        mov     si,cs:[fin_config]
        sub     cx,si
        mov     cs:[stack_length],cx
     ms_clean:
        mov     byte ptr [si],10
        inc     si
        loop    ms_clean
        popx    di,si,es,dx,cx,bx,ax

        cmp     cs:[simpleminded],1
        jne     ms_complicated_shit

        ;ds:[si] -> es:[di]

        pushx  ax,bx,cx,dx,es,ds

        push   cs
        pop    es
        cld
        mov    di,offset cs:[setstr]
        add    di,7

        mov    al,cs:[config]
        cmp    cs:[ext],1
        jne    ms_next

        mov    al,'F'
        stosb
ms_next:
        mov    al,cs:[config]
        stosb
        mov    al,10
        stosb

        push   ds
        pop    es
        push   cs
        pop    ds
        cld
        mov    si,offset cs:[setstr]
        mov    di,cs:[fin_config]
        mov    cx,10
        rep    movsb

        popx   ds,es,dx,cx,bx,ax
        mov    cs:[setstr_length],10
        call   verifie_stack
        ret

ms_complicated_shit:
        pushx   ax,bx,cx,dx,es,si,di,ds
        pushx   ax,cx,dx,es,si,di,ds

        mov     di,offset cs:[configs_history]
        mov     si,offset cs:[configs_ext_history]
        mov     bx,offset cs:[setstrhard]
        pushx   cs,cs
        popx    es,ds
    msc_next:
        inc     si
        inc     di
        mov     al,es:[di]
        cmp     al,0
        je      msc_out
        mov     al,ds:[si]
        cmp     al,1
        jne     msc_notext
        mov     al,'F'
        mov     es:[bx],al
        inc     bx
        inc     cs:[setstr_length]
    msc_notext:
        mov     al,es:[di]
        mov     es:[bx],al
        inc     bx
        mov     al,'_'
        mov     es:[bx],al
        inc     bx
        add     cs:[setstr_length],2
        jmp     msc_next
    msc_out:

        mov     al,cs:[config]
        cmp     cs:[ext],1
        jne     msc_next@
        mov     al,'F'
        mov     es:[bx],al
        inc     bx
        inc     cs:[setstr_length]
msc_next@:
        mov     al,cs:[config]
        mov     es:[bx],al
        inc     bx
        inc     cs:[setstr_length]
        mov     al,10
        mov     es:[bx],al
        inc     bx
        inc     cs:[setstr_length]
        popx    ds,di,si,es,dx,cx,ax

        push    ds
        pop     es
        push    cs
        pop     ds
        cld
        mov     si,offset cs:[setstr]
        mov     di,cs:[fin_config]
        mov     cx,10
        rep     movsb
        sub     di,3
        mov     cx,bx
        mov     bx,offset cs:[setstrhard]
        sub     cx,bx
        rep     movsb
        add     cs:[setstr_length],10
msc_exitr:
        call    verifie_stack
        popx    ds,di,si,es,dx,cx,bx,ax
        ret
setenvvar    endp

verifie_stack proc
        pushx   ax,bx,cx,dx
        mov     ax,cs:[stack_length]
        mov     bx,cs:[setstr_length]
        cmp     ax,bx
        ja      vs_noproblemo

        mov     cs:[curpage],0
        affiche stack_error_msg
        mov     al,cs:[c_color]

        push    ax
        mov     cs:[c_color],15
        mov     dx,cs:[stack_length]
        call    write_decimal
        affiche stack_error_msg2
        mov     dx,cs:[setstr_length]
        call    write_decimal
        affiche stack_error_msg3
        call    slam_enter
        pop     ax
        mov     cs:[c_color],al
   vs_noproblemo:
        popx    dx,cx,bx,ax
        ret
verifie_stack endp

clean_lower proc
	pushx   ax,bx,cx,dx,si
	call    find_finish
	mov     si,cs:[end_address]
	mov     cx,si
        push    ds
        pop     es
	call    cherche_fin_config
        push    si
	mov     si,cs:[fin_config]
        call    ligne_suiv
	mov     di,si
        pop     si
   cl_racroche:
	dec      di
   cl_cleanit:
        mov     byte ptr [di],10
        dec     di
        cmp     di,cx
        jae     cl_cleanit
	popx    si,dx,cx,bx,ax
	ret
clean_lower endp

make_address proc
	call    clean_upper
	call    clean_lower
	call    make_history
        call    setenvvar 
	mov     cs:[made_address],1
	ret
make_address endp

make_history proc
	pushx   ax,bx,cx,dx,es,ds,si,di

	pushx   cs,cs
	popx    es,ds
	mov     di,offset cs:[tobestored_buffer]

	mov     al,cs:[sub_level]
	mov     es:[di],al
	inc     di
	mov     al,cs:[config]
	mov     es:[di],al
	inc     di
	mov     al,cs:[ext]
	mov     es:[di],al
	inc     di

	mov     si,offset cs:[configs_history]
	mov     cx,10
	rep     movsb
	mov     cx,10
	mov     si,offset cs:[configs_ext_history]
	rep     movsb

	mov     di,offset [0EAh*4+4]               ;integrity rerun check
	xor     ax,ax
	mov     es,ax
        push    cs
        pop     ds
	mov     si,offset cs:[tobestored_buffer]
	mov     cx,50
	rep     movsb
	popx    di,si,ds,es,dx,cx,bx,ax
	ret
make_history endp

get_history proc
	pushx   ax,bx,cx,dx,es,ds,si,di
	mov     si,offset [0EAh*4+4]               ;integrity rerun check
	xor     ax,ax
	mov     ds,ax
        push    cs
        pop     es
	mov     di,offset cs:[tobestored_buffer]
	mov     cx,50
	rep     movsb

	pushx   cs,cs
	popx    es,ds
	mov     si,offset cs:[tobestored_buffer]

	mov     al,es:[si]
	mov     cs:[sub_level],al
	inc     si
	mov     al,es:[si]
	mov     cs:[config],al
	inc     si
	mov     al,es:[si]
	mov     cs:[ext],al
	inc     si

	mov     di,offset cs:[configs_history]
	mov     cx,10
	rep     movsb
	mov     cx,10
	mov     di,offset cs:[configs_ext_history]
	rep     movsb
	popx    di,si,ds,es,dx,cx,bx,ax
	ret
get_history endp

verify_sub proc
	pushx   ax,bx,cx,dx,si
	mov     si,cs:[group_address]
	mov     bl,al
   vs_nline:
	call    ligne_suiv
        call    rubbish_skip
	cmp     al,'D'
	jne     vs_nline
        call    rubbish_skip
        cmp     al,'$'                  ;Device=$ ? (d$ out of device=$)
	je      vs_v_config_nok           ;device=$ -> no config found like that
	cmp     al,'*'                  ;else: device=*...?
	jne     vs_nline

	call    which_level
	mov     cl,cs:[this_level]
	cmp     cl,cs:[need_level]
	jb      vs_v_config_nok
        cmp     cl,cs:[need_level]
	jne     vs_nline

	mov     cl,0
    vs_next_star:
        call    rubbish_skip
        jc      vs_nline
	inc     cl
	cmp     cl,cs:[need_level]
	jb      vs_next_star
        
	cmp     cs:[ext],1
	jne     vs_not_ext_conf
	cmp     al,'F'
	jne     vs_nline                  ;not_ext_conf
	lodsb
   vs_not_ext_conf:
	cmp     al,'F'
	jne     vs_not_ext_possible
	lodsb
	cmp     al,'0'
	jb      vs_couldbe_ok_
	cmp     al,'9'
	ja      vs_couldbe_ok_
	jmp     vs_nline
   vs_couldbe_ok_:
	dec     si
	mov     al,'F'
   vs_not_ext_possible:
	cmp     al,bl                   ;choosed conf=this one
	je      vs_v_config_ok             ;yes -> fine
	jmp     vs_nline                  ;no -> next config
   vs_v_config_nok:
	popx     si,dx,cx,bx,ax                  ;config not found
	stc                             ;set carry flag
	ret                             ;restore CONFIG.SYS position
   vs_v_config_ok:
	clc                             ;remove carry flag
        mov     cs:[start_address],si
	popx    si,dx,cx,bx,ax                  ;config not found
	ret                             ;config found
verify_sub endp 

light_selected_conf proc
	pushx   ax,bx,cx,dx
	mov     cl,cs:[ext]
        push    cx
	call    treat_ext       ;m
	mov     al,cs:[config]
	mov     cl,al
	cmp     cs:[ext],1
	jne     not_ext_nc
	mov     cl,'F'
   not_ext_nc:
        call    darkline     ;la couleur de la ligne Ö non_highlight
        call    make_line_color
        pushx   ax,bx,cx,dx,es,ds,si
        cld
        mov     di,offset cs:[line_color]
        push    cs
        pop     es
        mov     cx,80
        mov     al,' '
        mov     ah,7
        rep     stosw
        popx    si,ds,es,dx,cx,bx,ax
        ;-----------------
        mov     dh,-1
	mov     dl,0
   reread:        
	mov     bh,cs:[curpage]
	mov     dl,0
	inc     dh
	cmp     cs:[@fifty],1
	jne     lsc_fif
	cmp     dh,51
	je      cc_end
	jmp     lsc_@fif
   lsc_fif:
	cmp     dh,26
	je      cc_end
   lsc_@fif:
	mov     ah,2                        ;placer en coin gauche haut
	int     10h

	mov     ah,8
	int     10h

	cmp     al,cl
	jne     reread          ;not the probably good conf->redo

	cmp     cs:[ext],1
	jne     not_ext_cn2
	mov     ah,2
	inc     dl
	int     10h
	mov     ah,8
	int     10h
	cmp     al,cs:[config]
	jne     reread
	mov     dl,0
   not_ext_cn2:
	cmp     cs:[ext],1
	je      ext_config_@
	;-----------------------------
	mov     ah,2
	mov     dl,1
	int     10h
	mov     ah,8
	int     10h
	cmp     al,' '
	jne     reread
	mov     dl,0
   ext_config_@:
	add     dl,2
	mov     ah,2
	int     10h
	mov     ah,8
	int     10h
	cmp     al,255          ;la configuration
	jne     reread
	call    lightline
   cc_end:
        pop  cx
	mov  cs:[ext],cl
	popx dx,cx,bx,ax
	ret
light_selected_conf endp

darkline proc
        pushx   ax,bx,cx,dx,es
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ax,dx           ;al ligne ah colonne
	inc     al
	inc     ah
	mov     cl,7
        call    restore_line_color
	mov     cl,' '
	call    @ups
	mov     cl,' '
	call    @dns
	mov     cl,' '
	call    lefts
	call    put_gr
	call    leftsput_gr
	call    first_column
	popx    es,dx,cx,bx,ax
	ret
darkline endp

lightline proc
	pushx   ax,bx,cx,dx,es
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ax,dx           ;al ligne ah colonne
	mov     al,1            ;first_column
	inc     ah
        call    save_line_color
        mov     cl,cs:[c_color]
        call    fill_atribute
	call    lefts_get_gr
	call    get_gr
	cmp     cs:[sub_level],1
	jbe     sublev_dontcare
	mov     cl,''
	call    lefts
   sublev_dontcare:
	cmp     cs:[lbeg],0
	jne     nlbeg
	mov     cl,''
	call    @ups
   nlbeg:
	cmp     cs:[lend],0
	jne     nlend
	mov     cl,''
	call    @dns
   nlend:
	call    first_column
	popx    es,dx,cx,bx,ax
	ret
lightline endp

verify_dh_position proc
	cmp     cs:[@fifty],1
	jne     vdp_not_fifty
	cmp     dh,50
	jne     not_beg
	mov     cs:[incdec],0
	ret  
   vdp_not_fifty:
	cmp     dh,25 
	jne     not_beg
	mov     cs:[incdec],0
	ret
   not_beg:
	cmp     dh,0 
	jne     not_end
	mov     cs:[incdec],1
   not_end:
	ret
verify_dh_position endp

macro_movement proc
        cmp     cs:[help_call],1
        je      mv_help
        cmp     cs:[macro_counter],512
        jb      mv_up
        ja      mv_down
        clc
        ret
      mv_help:
        mov     al,8
        stc
        ret
      mv_up:
        mov     al,0
        mov     ah,48h
        inc     cs:[macro_counter]
        stc
        ret
      mv_down:
        mov     al,0
        mov     ah,50h
        dec     cs:[macro_counter]
        stc
        ret
macro_movement endp

cursor_movement proc
        mov     cs:[timer_position],77
        cmp     cs:[the_first],1
	jne     cm_here
	mov     cs:[the_first],0
	jmp     yes_home ;up
   cm_here:        
	cmp     cs:[beglist_jump],1
        jne     @yes_home
        jmp     yes_home
   @yes_home:
	mov     cs:[incdec],0
	xor     ax,ax
	mov     ah,0Ch
	int     21h

        cmp     cs:[attend_timer],1
        jne     cm_again
        call    get_gr
        call    attend_timer_routine
        jc      cm_keyy
        call    restore_config
        mov     al,cs:[config]
        call    put_gr
        mov     cs:[attend_timer],0
        call    verify_sub
        jc      n_attend_timer
        call    light_selected_conf
	mov     cs:[chosenlist],1
	mov     cs:[to_be_made],1
        clc     
        ret
   cm_keyy:
        call    put_gr
        jmp     cm_keyy@
   n_attend_timer:
        call    beep
   cm_again:        
        call    macro_movement
        jc      cm_keyy@
        mov     ah,0
	int     16h
   cm_keyy@:
        mov     cs:[attend_timer],0

        cmp     al,0
        jne     cm_notpressext  ;was it an extended key, since INS and DEL 

        cmp     ah,52h          ;are forbidden!
        je      cm_again
        cmp     ah,53h
        je      cm_again
   cm_notpressext:
        cmp     al,'.'
        jne     cm_notpoint
	mov     cs:[skip_configuration],1
	clc
	ret
   cm_notpoint:
        call    conv_maj
        cmp     al,9
        jne     not_list
	call    show_conf
	cmp     cs:[skip_configuration],1
	jne     cm_nskip
	clc
	ret
   cm_nskip:
	cmp     cs:[show_conf_choose],1
        je      cm_here@@
        jmp     cm_here
   cm_here@@:
	mov     cs:[chosenlist],1
	mov     cs:[to_be_made],1
	clc
	ret
   not_list:
        cmp     ah,48h ;fleche haut
	je      yes_up
        cmp     ah,4Bh
        je      yes_left

        cmp     ah,47h
	je      yes_home
        cmp     ah,49h
        je      yes_home
        cmp     ah,4Fh
        je      yes_end
        cmp     ah,51h
        je      yes_end
	jmp     cm_notup
   yes_home:
	mov     cs:[beglist_jump],0
	call    darkline
	call    beg_pos_plus
	stc        
	ret
   yes_left:
	call    cm_left
	jnc     cm_again@
	ret
   yes_end:
	call    end_pos_plus
	stc
	ret
   yes_up:
	call    darkline
	call    isit_first_line
	stc        
	ret
   cm_notup:
        cmp     ah,50h ;fleche bas
        je      cm_dn
        cmp     ah,4Dh
	jne     cm_notdn
	call    cm_right
	jnc     cm_again@
	ret
   cm_again@:
	jmp     cm_again
   cm_dn:
	call    darkline
	call    isit_last_line
	stc
	ret
   cm_notdn:
        cmp     al,13
        je      cm_choose
        cmp     al,32        
        je      cm_choose
	clc
	ret
   cm_choose:        
	mov     cs:[ext],0
	call    first_column
	mov     ah,8
	int     10h
	cmp     al,'F'
	jne     not_ext_
	mov     ah,3
	int     10h
	inc     dl
	mov     ah,2
	int     10h
	mov     ah,8
	int     10h
	cmp     al,'0'
	jb      not_extt
	cmp     al,'9'
	ja      not_extt
	mov     cs:[ext],1
	jmp     not_ext_
   not_extt:
	mov     al,'F'
   not_ext_:
	mov     cs:[chosenlist],1
	mov     cs:[config],al
	mov     cs:[to_be_made],1
	clc
	ret
cursor_movement endp 

affiche_level proc
	pushx   ax,bx,cx,dx

	mov     bh,0
	mov     ah,3
	int     10h
	mov     ah,2
	mov     dl,50    
	int     10h
	
	mov     ah,2
	mov     dl,cs:[sub_level]
	add     dl,'0'
	int     21h
	mov     ah,0
	int     16h
	xor     ax,ax
	mov     ah,0Ch
	int     21h

	call    first_column

	popx    dx,cx,bx,ax
	ret
affiche_level endp

cm_right proc
	pushx   ax,bx,cx,dx

	inc     cs:[sub_level]
	call    thisline_conf

        push    cx
        push    cs
        pop     es
	mov     bx,offset cs:[configs_history]
	mov     cl,0
	dec     bx
      reinc@:
	inc     bx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     reinc@
        pop     cx
	mov     es:[bx],cl

        push    cs
        pop     es
	mov     bx,offset cs:[configs_ext_history]
	mov     cl,0
	dec     bx
      @@reinc@:
	inc     bx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     @@reinc@
	mov     cl,cs:[ext]
	mov     es:[bx],cl
	mov     dx,cs:[group_address]
        push    dx
	call    derived_liste_config
        pop     dx
	mov     cs:[the_first],0
	cmp     cs:[num_confs],0
	jne     cm_restart_liste
	mov     cs:[group_address],dx
        push    cs
        pop     es
	mov     bx,offset cs:[configs_history]
	mov     cl,0
	dec     bx
      reinc@@:
	inc     bx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     reinc@@
	mov     cl,0
	mov     es:[bx],cl

        push    cs
        pop     es
	mov     bx,offset cs:[configs_ext_history]
	mov     cl,0
	dec     bx
      @reinc@:
	inc     bx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     @reinc@
	mov     cl,0
	mov     es:[bx],cl

	dec     cs:[sub_level]
	dec     cs:[need_level]
	popx    dx,cx,bx,ax
	clc
	ret
   cm_restart_liste:
	mov     cs:[ext],ch
	mov     ch,cs:[sub_level]
	mov     cs:[top_level],ch
	mov     cs:[restart_liste],1
	mov     cs:[enter_count],0
	call    force_efface_ecran
	stc
	popx    dx,cx,bx,ax
	ret
cm_right endp

cm_left proc
	cmp     cs:[sub_level],1
	je      cml_no_restart
	pushx   ax,bx,cx,dx
	mov     cl,cs:[ext]
        push    cx

        push    cs
        pop     es
	mov     bx,offset cs:[configs_history]
	mov     cl,0
	dec     bx
      l_reinc@:
	inc     bx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     l_reinc@
	mov     cl,0
	mov     es:[bx],cl
	dec     cs:[sub_level]
	call    derived_liste_config
	mov     cs:[the_first],0
	cmp     cs:[num_confs],0
	jne     cml_restart_liste

        push    cs
        pop     es
	mov     bx,offset cs:[configs_history]
	mov     cl,0
      l_reinc@@:
	inc     bx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     l_reinc@@
	mov     cl,0
	mov     es:[bx],cl

        push    cs
        pop     es
	mov     bx,offset cs:[configs_ext_history]
	mov     cl,0
	dec     bx
      @cml_reinc@:
	inc     bx
	inc     dx
	inc     cl
	cmp     cl,cs:[sub_level]
	jne     @cml_reinc@
	mov     cl,cs:[ext]
	mov     es:[bx],cl
	dec     cs:[sub_level]
        pop     cx
	mov     cs:[ext],cl
	popx    dx,cx,bx,ax
   cml_no_restart:
	clc
	ret
   cml_restart_liste:
	mov     cs:[ext],ch
	mov     ch,cs:[sub_level]
	mov     cs:[top_level],ch
	mov     cs:[restart_liste],1
	mov     cs:[enter_count],0
	call    force_efface_ecran
	stc
        pop     cx
	mov     cs:[ext],cl
	popx    dx,cx,bx,ax
	ret
cm_left endp


first_column proc
	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	mov     ah,2
	mov     dl,0    
	int     10h
	ret
first_column endp

isit_first_line proc
	pushx   ax,bx,cx,dx
	mov     cs:[first_line],0
	mov     ah,3
	mov     bh,cs:[curpage]
	int     10h
	cmp     dh,0 
	jne     ifl_no
	mov     cs:[first_line],1
   ifl_no:
	popx    dx,cx,bx,ax
	ret
isit_first_line endp

isit_last_line proc
	pushx   ax,bx,cx,dx
	mov     cs:[last_line],0
	mov     ah,3
	mov     bh,cs:[curpage]
	int     10h
	cmp     cs:[force_fifty],1
	jne     ifl@fifty
	cmp     dh,49
	je      ifl_yes
	jmp     ifl_no_last
   ifl@fifty:     
	cmp     dh,24
	jne     ifl_no_last
   ifl_yes:     
	mov     cs:[last_line],1
	
	call    darkline        

	mov     cs:[incdec],2
	popx    dx,cx,bx,ax
	ret
   ifl_no_last:
	
	call    darkline        

	mov     cs:[incdec],1
	popx    dx,cx,bx,ax
	ret
isit_last_line endp

end_pos_plus proc
	call    darkline
        push    bx
	mov     ah,2
	mov     bh,cs:[curpage]
	mov     dh,25
	cmp     cs:[force_fifty],1
	jne     epp@fifty
	mov     dh,50
   epp@fifty:
	mov     dl,0
	int     10h
        pop     bx
	ret
end_pos_plus endp

affiche_config_name proc                ;configuration name
	mov     cs:[caps],1
        push    si                      ;save CONFIG.SYS position
   acn_suiv:
	lodsb                           ;next char
	cmp     cs:[caps],1             ;last letter written in caps?
	je      min_max                 ;change there
	cmp     al,'|'                  ;change char?
	je      back_conv               ;change [caps]
	call    conv_min                ;convert char to min
	jmp     no_back_conv            ;DOS REAds alL IN CAPS!!! 
   min_max:
	cmp     al,'|'                  ;change char
	jne     no_back_conv            ;no -> leave it alone
	lodsb                           ;next char
	mov     cs:[caps],0             ;->min
	call    conv_min                ;convert to min
	jmp     no_back_conv            
   back_conv:
	lodsb                           ;next char
	mov     cs:[caps],1             ;change to caps
   no_back_conv:        
	cmp     al,'#'
	je      end_name
	cmp     al,13
	je      end_name
	cmp     al,10                   ;enter
	je      end_name
	call    save_configs_string     ;put char to string
	jmp     acn_suiv                ;no -> jump
   end_name:        
	mov     al,13
	call    save_configs_string     ;put char to string
	mov     al,10
	call    save_configs_string     ;put char to string
   continue_name:
        pop     si                      ;restore...
	mov     cs:[caps],1             ;caps to one
	ret
affiche_config_name endp

acn_derived proc
	mov     cs:[caps],1
	mov     cs:[count],0
        push    si
   acn_suiv_der:
	lodsb
	cmp     cs:[caps],1
	je      min_max_der
	cmp     al,'|'        
	je      back_conv_der
	call    conv_min
	jmp     no_back_conv_der
   min_max_der:
	cmp     al,'|'        
	jne     no_back_conv_der
	lodsb
	mov     cs:[caps],0
	call    conv_min
	jmp     no_back_conv_der
   back_conv_der:
	lodsb
	mov     cs:[caps],1
   no_back_conv_der:        
	cmp     al,'#'
	je      return_tonextline_der
	inc     cs:[count]
	cmp     cs:[count],79
	jne     no_enter_der
	jmp     return_tonextline_b_der
   return_tonextline_der:
	lodsb
   return_tonextline_b_der:
	pushx           ax,bx,cx,dx
	affiche         passage_msg
	mov             dl,' '
	int             21h
	int             21h
	popx            dx,cx,bx,ax
	mov             cs:[count],3
   no_enter_der:
        cmp     al,253
        jne     acn_dlc_nocolor
        lodsb
        cmp     cs:[message_mono],1
        je      acn_suiv_der
        mov     cs:[l_color],al
        jmp     acn_suiv_der
   acn_dlc_nocolor:
        cmp     al,32
        jae     acn_dlc_color
   acn_dlc_nocolor_two:
        mov     ah,2
        mov     dl,al
        call    elite_translate
        int     21h
        jmp     acn_dlc_start
   acn_dlc_color:
        cmp     al,240
        jae     acn_dlc_nocolor_two
        pushx   ax,bx,cx
        mov     dl,al
        call    elite_translate
        mov     al,dl
        mov     bh,0
	mov     ah,9
        mov     cx,1
        mov     bl,cs:[l_color]
	int     10h
        call    advance_char
        popx    cx,bx,ax
  acn_dlc_start:
	cmp     al,10
        jne     @acn_suiv_der
   continue_name_der:
	mov     dx,si

        mov     al,' '
        mov     bh,0
	mov     ah,9
        mov     cx,1
        mov     bl,7
	int     10h

        pop     si
	mov     cs:[caps],1
	mov     cs:[count],0
        ret
  @acn_suiv_der:
        jmp     acn_suiv_der
acn_derived endp

push_cursor proc
	pushx ax,cx
	mov ah,1
        mov cx,5050
	int 10h
	popx cx,ax
	ret
push_cursor endp

pop_cursor proc
	pushx ax,cx
	mov ch,6
	mov cl,7
	mov ah,1
	int 10h
	popx cx,ax
	ret
pop_cursor endp

lit_ecrit_config proc
	pushx   bx,dx,cx,cs
        pop     es                                      ;es=cs
	mov     bx,offset cs:[config_string]
	mov     al,es:[bx]
	mov     cs:[ext],0
	cmp     al,'*'
	je      lc_not_etoile
        cmp     al,'$'
        je      lc_not_etoile
	mov     cs:[ext],1
   lc_not_etoile:
	mov     al,es:[bx+1]
	mov     cs:[config],al
	popx    cx,dx,bx
	ret
lit_ecrit_config endp

efface_ecran proc
	cmp     cs:[pas_eff_ecran],1
	jne     @eff
	ret
    @eff:
	pushx   ax,bx,cx,dx
	sub     dx,dx
	mov     ah,2
	mov     bh,cs:[curpage]
	int     10h
	mov     ah,9
	mov     cx,2000         ;*2
	cmp     cs:[@fifty],1        
	jne     eff@fifty
	mov     cx,4000         ;80
    eff@fifty:
	mov     al,' '
	mov     bl,7
	int     10h
	popx    dx,cx,bx,ax
	ret
efface_ecran endp 

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Beep speaker; period given by beep_div, duration by beep_len.
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
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

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;TOTalLY NEW ROUTINE FOR WRITING THE CONFIGURATION ON SCREEN
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
chrcnt proc
        pushx  bx,dx,cs
        pop    es                              ;es=cs
        mov    bx,cs:[cnf_counter]
        call   elite_translate
        mov    es:[bx],dl
	inc    bx
	mov    cs:[cnf_counter],bx
	popx   dx,bx
	ret
chrcnt endp

thisline_conf proc
	call    first_column                    ;premiäre colonne
	mov     ah,8                            ;dans le CONFIG.SYS
	mov     bh,cs:[curpage]                 ;lire le caractäre dans la
	int     10h                             ;liste Ö la page actuelle de
        call    conv_maj
	cmp     al,'F'                          ;l'Çcran
	jne     rscv_notext                      ;configuration Çtendue?
	mov     ah,3                            ;si oui, alors vÇrifier si
	int     10h                             ;c'est la bonne entre 1 et 10
	inc     dl
	mov     ah,2
	int     10h
	mov     ah,8
	int     10h
	cmp     al,'0'
	jb      rscnot_extt
	cmp     al,'9'
	ja      rscnot_extt
	mov     cs:[ext],1
	jmp     rscv_notext
   rscnot_extt:
	mov     al,'F'                  ;non, c'est une configuration F
   rscv_notext:
	mov     cl,al                   ;cl<-al choosed conf in cl
	;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	;retURNS cl FOR chOSEN CONFIG AND EXTendED FLAG SET OR NOT 
	ret
thisline_conf endp

show_conf proc                          
        mov     cs:[at_top],0
        mov     cs:[at_bottom],0
        mov     cs:[at_extremmum],0
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	mov     cl,cs:[message_mono]
        push    cx
	mov     cs:[show_conf_choose],0
        push    cs                              ;es=cs
        pop     es
	mov     bx,offset cs:[cnf_contents]
	mov     cs:[cnf_counter],bx
	mov     si,cs:[prem_ligne]              ;dÇbut des configs multiples
	call    thisline_conf
	mov     cs:[config],cl
   rscv_nextt:
	call    show_conf_prog
	call    sc_movements
        jc      rscv_nextt
        cmp     ax,-1
        je      rscv_nextt
	mov     cs:[ext],0
	mov     ah,5                    ;change page
	mov     al,0                    ;to page 0 
	int     10h
        pop     cx
	mov     cs:[message_mono],cl
	cmp     cs:[force_fifty],1
	jne     rscv_@@fifty
	call    fifty
   rscv_@@fifty:        
	popx    ds,es,di,si,dx,cx,bx,ax ;restore registers and return
	ret
show_conf endp

sc_movements proc
	jmp     scm_notbeg
    scm_beg:
        call    beep                    ;this beep means there's something
        mov     ax,-1                   ;wrong with the verif in scm_movements
        mov     cs:[at_extremmum],1
        clc
        ret
    scm_notbeg:
	cmp     al,0
	je      scm_ext
	cmp     al,13
	je      scm_choose        
	cmp     al,'.'
	je      scm_point
	cmp     al,9
	jne     scm_beg
	clc
	ret
   scm_point:
	mov     cs:[skip_configuration],1
	clc
	ret
   scm_choose:
	mov     cs:[show_conf_choose],1
	mov     al,cs:[config]
	mov     ah,cs:[ext]
	mov     cs:[scm_ch_conf],ax
	clc
	ret
   scm_ext:
	cmp     ah,49h
	je      scm_previous
	cmp     ah,51h
	je      scm_next
	jmp     scm_beg
   scm_previous:
	;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	; PREVIOUS CONFIGURATION IN LIST - prepare page

        mov     cs:[at_bottom],0
        cmp     cs:[at_top],1
        je      scm_beg

        call    anyconf_before?

        cmp     cs:[at_top],1
        je      scm_beg
        jmp     scm_exit


	;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	; NEXT CONFIGURATION IN LIST - prepare page
    scm_next:
        mov     cs:[at_top],0
        cmp     cs:[at_bottom],1
        je      scm_beg

        call    anyconf_after?

        cmp     cs:[at_bottom],1
        je      scm_beg
        jmp     scm_exit
   scm_exit:
	;note: preserve cl from destruction before exit
	mov     cl,al
	mov     cs:[config],al
        push    cs                              ;es=cs
        pop     es
	mov     bx,offset cs:[cnf_contents]
	mov     cs:[cnf_counter],bx
	mov     si,cs:[prem_ligne]              ;dÇbut des configs multiples
	stc
	ret
sc_movements endp

anyconf_before? proc
        pushx   ax,bx,cx,dx,si,di,es,ds
        mov     al,cs:[config]                  ;configuration sur place
	cmp     cs:[ext],1                      ;Çtendue?
        je      ab_scm_@deext                      ;oui->jump
   ab_scm_decay:        
	dec     al
	cmp     al,0
        je      ab_scm_nomoredec
	mov     si,cs:[prem_ligne]              ;dÇbut des configs multiples
	call    verify_sub
        jc      ab_scm_decay
        jmp     ab_scm_exit
   ab_scm_nomoredec:
	mov     al,':'  ;one after 9
	mov     cl,cs:[ext]
        push    cx
	mov     cs:[ext],1
        jmp     ab_scm_deext
   ab_scm_@deext:
	mov     cl,cs:[ext]
        push    cx                              ;sauver cx
    ab_scm_deext:
	dec     al                              ;configuration prÇcÇdente
	cmp     al,'/'                          ;one before 0 -> plus de 
        je      ab_scm_noext                       ;configs comme áa
	mov     si,cs:[prem_ligne]              ;dÇbut des configs multiples
	call    verify_sub
        jc      ab_scm_deext
        pop     cx
	mov     cs:[ext],1
        jmp     ab_scm_exit
    ab_scm_noext:
        pop     cx
        mov     cs:[ext],cl
        mov     cs:[at_top],1
        popx    ds,es,di,si,dx,cx,bx,ax
        ret
    ab_scm_exit:
        mov     cs:[at_top],0
        popx    ds,es,di,si,dx,cx,bx
        pop     cx      ;instead of ax
        ret
anyconf_before? endp

anyconf_after? proc
        pushx   ax,bx,cx,dx,si,di,es,ds
	mov     al,cs:[config]
	mov     cl,cs:[ext]
	cmp     cs:[ext],0
        je      af_scm_@noinc              ;scm_encay
    af_scm_enext:
	inc     al
	cmp     al,':'  ;one before 0
        je      af_scm_noinc
	mov     si,cs:[prem_ligne]              ;dÇbut des configs multiples
	call    verify_sub
        jc      af_scm_enext
        jmp     af_scm_exit
    af_scm_noinc:
	mov     cl,cs:[ext]
	mov     cs:[ext],0
	mov     al,0
    af_scm_@noinc:
        push    cx
    af_scm_encay:        
	inc     al
	cmp     al,255
        je      af_scm_nomoreinc
	mov     si,cs:[prem_ligne]              ;dÇbut des configs multiples
	call    verify_sub
        jc      af_scm_encay
        pop     cx
        jmp     af_scm_exit
    af_scm_nomoreinc:
        pop     cx
	mov     cs:[ext],cl
        mov     cs:[at_bottom],1
        popx    ds,es,di,si,dx,cx,bx,ax
        ret

    af_scm_exit:
        mov     cs:[at_bottom],0
        popx    ds,es,di,si,dx,cx,bx
        pop     cx      ;instead of ax
        ret
anyconf_after? endp

racn_derived proc
	cmp     cs:[ext],1
	je      racn_not_ext
	mov     dl,' '
	call    chrcnt
   racn_not_ext:
	mov     dl,253
	call    chrcnt
	mov     dl,''          ;9
	call    chrcnt
	mov     cs:[caps],1
	mov     cs:[count],3
        push    si
   racn_next:
	lodsb
	cmp     al,'|'
	jne     racn_not_change_case
	cmp     cs:[caps],1
	je      change_to_low
	mov     cs:[caps],1
	jmp     racn_next
  change_to_low:
	mov     cs:[caps],0
	jmp     racn_next
  racn_not_change_case:
	cmp     cs:[caps],1
	je      conv_to_caps
	call    conv_min
	jmp     conv_to_min
conv_to_caps:
	call    conv_maj
conv_to_min:
	cmp     al,0
	jne     racn_not_zero
	mov     al,' '
racn_not_zero:
	mov     dl,al
	call    chrcnt
	cmp     dl,10
	jne     racn_next
	jmp     racn_toutcourt
racn_end:
	call    ligne_suiv
racn_toutcourt:
	mov     dx,si
        pop     si
	mov     cs:[caps],1
	ret
racn_derived endp

question_abrev proc
	;dl->caracter to compare
	;bx->offset of the message
	cmp     al,128
	ja      qa_superieur
	cmp     al,dl
	jne     qa_notit
        mov     cs:[addspace],0
qa_isgood:
        
        push    dx
        call    movtostring
        pop     dx

        cmp     cs:[addspace],1
        je      qa_nspace
        push    dx
        mov     dl,' '
        call    chrcnt
        pop     dx
qa_nspace:
        ;stack for eventual question add
        push    dx
        mov     dl,253
        call    chrcnt
        mov     dl,7
        call    chrcnt
        mov     dl,253
        call    chrcnt
        mov     dl,7
        call    chrcnt
        pop     dx
        ;-------------------------------

        cmp     dl,'Z'
        jne     qa_nz
        mov     dl,13
        call    chrcnt
qa_nz:
	mov     cs:[liste.attrib],7
qa_notit:       
	ret
qa_superieur:
        mov     cs:[addspace],0
        sub     dl,128
	cmp     dl,al        
	jne     qa_notit
        push    bx
	mov     bx,offset questionmsg
	call    movtostring
        mov     cs:[addspace],1
        pop     bx
	jmp     qa_isgood
question_abrev endp

movtostring proc
        push    cs                              ;es=cs
        pop     es
   motoreloacte:
	mov     dl,es:[bx]        
	cmp     dl,255
	je      movtoend
	cmp     dl,32
        jb      movto_nodec
	cmp     dl,240
	ja      movto_nodec
        xor     dl,cs:[xor_byte]
        sub     dl,cs:[increment_byte]
   movto_nodec:
	call    chrcnt
	inc     bx
	jmp     motoreloacte
   movtoend:
        mov     dl,253
        call    chrcnt
        mov     dl,7
        call    chrcnt
	ret
movtostring endp

config_abrev proc                       ;abreviations via DOS DEVICes, etc..
	vv 'N',numlockmsg
	vv 'R',menucolormsg
	vv 'A',menudefaultmsg
	vv 'E',menuitemmsg
	vv 'O',submenumsg
        vv 'Z',illegalmsg
	vv 'B',buffersmsg
	vv 'Q',countrymsg
	vv 'D',devicemsg
	vv 'U',devicehighmsg
	vv 'H',dosmsg
	vv 'P',driveparmmsg
	vv 'X',fcbsmsg
	vv 'F',filesmsg
	vv 'I',installmsg
	vv 'W',installhighmsg
	vv 'L',lastdrivemsg
	vv 'S',shellmsg
	vv 'K',stacksmsg
	vv '1',switchesmsg        
	vv 'C',breakmsg
	vv '0',remmsg
	vv 'V',setmsg
	ret
config_abrev endp

reboot_it proc
	cmp     cs:[switch_error],1
        je      rt_end@
	cmp     cs:[custom_error],1
        je      rt_end@
	cmp     cs:[second],1
        je      rt_end@
   rt_notsec:
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	mov     cl,1
	call    lit_ecrit_cfg
        push    cs
        pop     es                                      ;es=cs
	mov     bx,offset cs:[config_string]
	mov     al,es:[bx]
	cmp     al,'$'          ;not extended ctrl
	je      rt_reboot_norm
	cmp     al,'ú'          ;extended ctrl
	je      rt_reboot
	popx    ds,es,di,si,dx,cx,bx,ax
	ret
rt_end@:
        jmp     rt_end
rt_reboot:
	mov     cs:[ext],1
	jmp     rt_booz
rt_reboot_norm:
	mov     cs:[ext],0
rt_booz:
	mov     cs:[chicago_always_wait],0
	mov     cs:[toujours_wait],0
	mov     cs:[last_conf],0
	mov     cs:[rebooted],1

	mov     al,es:[bx+1]
	call    conv_maj

        cmp     al,' '
        jne     rt_nlist
        mov     cs:[rebooted],0
        mov     cs:[chicago_always_wait],1
        mov     cs:[toujours_wait],1
        mov     cs:[chicago_key_delai],0
        mov     cs:[dos_key_delai],0
   rt_nlist:
	mov     cs:[config],al
	popx    ds,es,di,si,dx,cx,bx,ax
   rt_end:        
	ret
reboot_it endp


twenty proc                             ;sets a 25 line mode
	pushx   ax,bx
	mov     ah,11h
	mov     al,14h  
	xor     bx,bx
	int     10h
	mov     cs:[@twenty],1
	mov     cs:[@fifty],0
	call    push_cursor
	popx    bx,ax
	ret
twenty endp



fifty proc                              ;sets a 50 line mode
	pushx   ax,bx
	mov ah,11h
	mov al,12h
	xor bx,bx
	int 10h
	mov cs:[@twenty],0
	mov cs:[@fifty],1
	call push_cursor
	popx    bx,ax
	ret
fifty endp

show_conf_prog proc
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;Here I have the chosen configuration in cl and the ext correctly set        
;the config.sys position is at the very beginning
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
        mov     cs:[already_lined],0
	mov     si,cs:[group_address]
        cmp     cs:[at_extremmum],1
        je      scp_beg
        mov     cs:[inline_totals],0
   scp_beg:
        call    ligne_suiv         ;next line in CONFIG.SYS
        call    rubbish_skip
	cmp     al,'D'          ;is it DEVICE
	jne     scp_beg         ;no, then next line
        call    rubbish_skip
        jc      scp_beg
        cmp     al,'$'          ;well, that's all we managed to find?
	jne     scp_notend      
   scp_terminate:
	call    scp@termin
        ret                     ;make a preparation call here!
   scp_notend:
	cmp     al,'*'          ;a configuration?
	jne     scp_beg         ;no, beginning

	call    which_level
	mov     ch,cs:[sub_level]
	cmp     cs:[this_level],ch
	jb      scp_terminate
	cmp     cs:[this_level],ch
	jne     scp_beg

        push    cx
	mov     cl,0
    @ext_star:
        call    rubbish_skip
        inc     cl
	cmp     cl,cs:[this_level]
	jb      @ext_star
        pop     cx

	cmp     cs:[ext],1
	jne     scp_not_ext
	cmp     al,'F'          ;it is just an error
	jne     scp_beg         ;since in list, no need to recheck
	lodsb
   scp_not_ext:
	cmp     al,cl           ;is it the right configuration?
	jne     scp_beg
	cmp     al,'F'                        
	jne     scp_nspecial
	lodsb
	cmp     al,'0'
	jb      scp_n@special
	cmp     al,'9'
	jbe     scp_beg
   scp_n@special:
	dec     si
   scp_nspecial:                ;here I am on the position of THE config!
        call    scp@name        ;write name to buffer

        mov     cs:[inline_si_address],si
   scp_@@:
        call    rubbish_skip

        cmp     al,10
        jne     scp_asusual
        call    ligne_suiv
        jmp     scp_@@
   scp_asusual:

        cmp     cs:[at_extremmum],1
        je      inline_not_count

        pushx   ax,bx,cx,dx,es
        mov     bx,offset cs:[inline_thisconfig]
        add     bx,cs:[inline_totals]
        push    cs
        pop     es
        mov     es:[bx],al
        popx    es,dx,cx,bx,ax

        inc     cs:[inline_totals]

    inline_not_count:

	mov     dl,al           ;current caracter in dl
	cmp     al,'D'          ;is it DEVICE?
	jne     scp_abrev

	lodsb
	sub     si,2
	cmp     al,'$'
	jne     scp_nend

        cmp     cs:[at_extremmum],1
        je      inline_not_count@

        dec     cs:[inline_totals]

  inline_not_count@:

	call    scp@termin
        ret                     ;call finish routine here!
   scp_nend:
	cmp     al,'*'
	jne     scp_@abrev

        cmp     cs:[at_extremmum],1
        je      scp_terminate
        dec     cs:[inline_totals]
        jmp     scp_terminate   ;do not accept doubles any longer
;
;        call    ligne_prec
;        jmp     scp_beg
   scp_@abrev:
        call    rubbish_skip
        jc      scp_@@     
   scp_abrev:
        call    config_abrev            ;see if abreviation
	cmp     al,'Z'
        jne     rsc_next
        call    ligne_suiv
	mov     dl,10
	call    chrcnt
	jmp     scp_@@
   scp_beg@:
        jmp     scp_beg
   rsc_next:                
        lodsb

        mov     dl,al                   ;no->write
	call    chrcnt
	cmp     al,10                   ;was it a line
        je      scp_@@@                  ;recheck everything
	jmp     rsc_next                 ;jump to next caracter
scp_@@@:
        jmp     scp_@@
show_conf_prog endp

scp@name proc                           ;writes the name and line to buffer
	cmp     cs:[already_lined],0
	je      no_lined_scp
	mov     dl,10
	call    chrcnt
no_lined_scp:
	mov     dl,253
	call    chrcnt        
	mov     dl,''
	call    chrcnt
	cmp     cs:[ext],1              
	jne     rscnot_f                 ;while checking for extended or not
	mov     dl,'F'
	call    chrcnt
   rscnot_f:
	mov     dl,cl
	call    chrcnt
	call    racn_derived             ;write config's name on screen
	mov     si,dx                   ;in acn_derived, si was overwritten
	mov     dl,253
	call    chrcnt        
	mov     dl,''
	call    chrcnt
	cmp     cs:[already_lined],1
	je      no_lined
	mov     cs:[already_lined],1

        push    bx
        mov     bx,cs:[cnf_counter]
        mov     cs:[cnf_name],bx
        pop     bx

        push    bx
	mov     bx,offset linemsg
	call    movtostring
        pop     bx
no_lined:
	mov     dl,10
	call    chrcnt
	ret
scp@name endp

scp@termin proc
   rsc_end:
	mov     dl,255
	call    chrcnt        
	mov     dl,255
	call    chrcnt        
	mov     cs:[curpage],1          ;change page to 1
        call    efface_page1_ecran
	mov     ah,5                   
	mov     al,cs:[curpage]        
	int     10h
   rsc_scrolling:
	call    show_scrolling
	mov     cs:[curpage],0          ;reset the page to 0
	ret
scp@termin endp 

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
        mov     dl,'ˇ'
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
        cmp     al,'ˇ'
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

;±±±±±±± video_detect & EgaInstalled ±±±±±±±±±±±±±±±±±±±±±±±±±±± 3.07.94 ±±±
; Video detect routines for CGA support
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
video_detect proc        
        pushx   ax,di,si,ds,es,bx          ; Store registers
        push    cs
        pop     ds
	mov     di, CGASeg              ; move offset of CGA to di
	mov     ah, 0Fh                 ; INT 10 get vid mode func
	int     10h                     ; get the video mode
	xor     ah, ah                  ; clear the ah reg
	mov     cs:[video_mode],al      ; place mode into VideoMode
	cmp     al, 7                   ; Is this a mono screen?
	jne     NotMono                 ; if not jump to NotMono
	mov     di,MonoSeg              ; move offset of mono to di
   NotMono:                                ; Process CGA/EGA/VGA adap.
	mov     cs:[v_mode],di          ; Move di to base of screen
        popx    bx,es,ds,si,di,ax          ; Restore regs
	ret
video_detect endp

;±±±±±±± MoveXY_di ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 5.07.94 ±±±
; This procedure moves to the offset indicated by an X & Y cusor location.
; In:  ah = Row
;      al = Column
; Out: di = Memory Offset
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
MoveXY_di proc
                push    cx              ; Save cx
		xor     cl, cl          ; Clear cl
		mov     ch, ah          ; cx = Row * 256
		dec     ch              ; cx = (Row - 1) {0-24 Based}
		shr     cx, 1           ; cx = Row * 128
		mov     di, cx          ; Store in di
		shr     di, 1           ; di = Row * 64
		shr     di, 1           ; di = Row * 32
		add     di, cx          ; di = (Row * 128)+(Row * 32) {Row*160}
		xor     ch, ch          ; Clear ch register
		mov     cl, al          ; cx = Columns
		dec     cx              ; Make 0-79
		shl     cx, 1           ; Account for attribute
		add     di, cx          ; di = (Row * 160) + (Col * 2)
                pop     cx              ; Restore cx register
		ret
MoveXY_di endp

;±±±±±±± fill_atribute ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 5.07.94 ±±±±
; In:   ah = Row
;       al = Column
; Out:  di = Memory Offset, created by moveXY_di
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
fill_atribute proc        
        push    di
	mov     al,1
	call    moveXY_di               ;create memory offset
	mov     ax,cs:[v_mode]
	mov     es,ax
	mov     al,cl                   ;al color
	mov     cx,80
    fa_next:        
	inc     di
	stosb
	dec     cx
	jnz     fa_next
        pop     di
	ret
    fa_@@next:
	mov     cx,80
    fa_@next:
	inc     di
	stosb
	dec     cx
	jnz     fa_@next
        pop     di
	ret
fill_atribute endp

read_key proc
        call    convert_keyb
        ret
read_key endp

;±±±±±±± convert_keyb ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 6.07.94 ±±
; universal key convert procedure
; In:   al = In Key
; Out:  al = Converted key                        
; Ignoring when chosen from a list or US keyboard
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
convert_keyb proc
	cmp     cs:[chosenlist],1
	je      cs_buy
	cmp     cs:[doconv],0
	jne     cs_conv
   cs_buy:        
	ret   
   cs_conv:
	call    conv_maj
	mov     cs:[char@conv],al
	pushx   bx,dx,cx
        push    cs
        pop     es
	mov     bx,offset US
   cs_nextchar:
	mov     al,es:[bx]
	cmp     al,255
	je      cs_noconv
	inc     bx
	cmp     cs:[char@conv],al
	jne     cs_nextchar
	mov     dx,offset US
	sub     bx,dx
	mov     dx,bx   ;dans dx<-position Ö rajouter
	call    mov@bx
	add     bx,dx
	dec     bx
	mov     al,es:[bx]
	mov     cs:[char@conv],al
   cs_noconv:
	popx    cx,dx,bx
	mov     al,cs:[char@conv]
	ret
convert_keyb endp


;±±±±±±± mov@bx ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 6.07.94 ±±
; universal key convert procedure, move into bx the destination string
; In:   cs:[keyb], the chosen keyboard: one word
; Out:  bx = pointer to string                    
; Error: bad keyboard value specified
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
mov@bx proc
	cmp     cs:[@keyb],'BE'
	jne     @BE
	mov     bx,offset be
	jmp     bx@end
   @BE:
	cmp     cs:[@keyb],'BR'
	jne     @BR
	mov     bx,offset us
	jmp     bx@end
   @BR:
	cmp     cs:[@keyb],'CF'
	jne     @CF
	mov     bx,offset CF
	jmp     bx@end
   @CF:
	cmp     cs:[@keyb],'CZ'
	jne     @CZ
	mov     bx,offset CZ
	jmp     bx@end
   @CZ:
	cmp     cs:[@keyb],'SL'
	jne     @SL
	mov     bx,offset SL
	jmp     bx@end
   @SL:
	cmp     cs:[@keyb],'US'
	jne     @US
	mov     bx,offset US
	jmp     bx@end
   @US:
	cmp     cs:[@keyb],'DK'
	jne     @DK
	mov     bx,offset DK
	jmp     bx@end
   @DK:
	cmp     cs:[@keyb],'SU'
	jne     @SU
	mov     bx,offset SU
	jmp     bx@end
   @SU:
	cmp     cs:[@keyb],'FR'
	jne     @FR
	mov     bx,offset FR
	jmp     bx@end
   @FR:
	cmp     cs:[@keyb],'GR'
	jne     @GR
	mov     bx,offset GR
	jmp     bx@end
   @GR:
	cmp     cs:[@keyb],'HU'
	jne     @HU
	mov     bx,offset HU
	jmp     bx@end
   @HU:
	cmp     cs:[@keyb],'IT'
	jne     @IT
	mov     bx,offset IT
	jmp     bx@end
   @IT:
	cmp     cs:[@keyb],'LA'
	jne     @LA
	mov     bx,offset LA
	jmp     bx@end
   @LA:
	cmp     cs:[@keyb],'NL'
	jne     @NL
	mov     bx,offset NL
	jmp     bx@end
   @NL:
	cmp     cs:[@keyb],'NO'
	jne     @NO
	mov     bx,offset NO
	jmp     bx@end
   @NO:
	cmp     cs:[@keyb],'PL'
	jne     @PL
	mov     bx,offset PL
	jmp     bx@end
   @PL:
	cmp     cs:[@keyb],'PO'
	jne     @PO
	mov     bx,offset PO
	jmp     bx@end
   @PO:
	cmp     cs:[@keyb],'SP'
	jne     @SP
	mov     bx,offset sp@
	jmp     bx@end
   @SP:
	cmp     cs:[@keyb],'SV'
	jne     @SV
	mov     bx,offset SV
	jmp     bx@end
   @SV:
	cmp     cs:[@keyb],'SF'
	jne     @SF
	mov     bx,offset SF
	jmp     bx@end
   @SF:
	cmp     cs:[@keyb],'UK'
	jne     @UK
	mov     bx,offset UK
	jmp     bx@end
   @UK:
	cmp     cs:[@keyb],'YU'
	jne     @error
	mov     bx,offset YU
	jmp     bx@end
   bx@end:
	ret
   @error:
	affiche kbd_invalidparam
	mov     cs:[switch_error],1
	mov     cs:[@keyb],'US'
	mov     bx,offset us
	ret
mov@bx endp

; ±±±±±± @keyboards ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 6.07.94 ±±
; universal key convert procedure, first called routine
; mode into cs:[@keyb] the chosen keyboard
; al is modified, si is maintained
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
@keyboards proc
        push    si
	lodsb
	mov     ah,al
	lodsb
	mov     cs:[@keyb],ax
        pop     si
	ret
@keyboards endp

; ±±±±±± @ups      ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 8.07.94 ±±
; outputs on the same line at the end the up caracter
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
@ups proc
        push    cx
	mov     bh,0
	mov     ah,3
	int     10h
	mov     ah,2
	mov     dl,77
	int     10h  
        mov     ah,2
        pop     cx
	mov     dl,cl
	int     21h
	call    first_column
	ret
@ups endp

; ±±±±±± @dns      ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± 8.07.94 ±±
; outputs on the same line at the end the down caracter
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
@dns proc
        push    cx
	mov     bh,0
	mov     ah,3
	int     10h
	mov     ah,2
	mov     dl,78
	int     10h
	mov     ah,2
        pop     cx
	mov     dl,cl
	int     21h
	call    first_column
	ret
@dns endp

get_gr proc
        pushx   ax,bx,cx,dx
        mov     bh,0
	mov     ah,3        
	int     10h
	mov     ah,2
	mov     dl,77
	int     10h
	mov     ah,8
	int     10h
	mov     cs:[letterg],al
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ah,2
	mov     dl,78
	int     10h
	mov     ah,8
	int     10h
	mov     cs:[letterr],al
        popx    dx,cx,bx,ax
	ret
get_gr endp

put_gr proc
        pushx   ax,bx,cx,dx
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ah,2
	mov     dl,77
	int     10h
	mov     ah,2
	mov     dl,cs:[letterg]
	int     21h
	mov     bh,0
	mov     ah,3        
	int     10h
	mov     ah,2
	mov     dl,78
	int     10h
	mov     ah,2
	mov     dl,cs:[letterr]
	int     21h
        popx    dx,cx,bx,ax
        ret
put_gr endp

print_delai proc
        pushx   ax,bx,cx,dx
	cmp     cs:[waitu],1
        je      pd_notprint
        ;cx - ticks to transform
        mov     ax,cs:[key_delai]
        sub     ax,cx
        mov     ch,18
        div     ch
        cmp     ax,cs:[last_ch_second]
        je      pd_notprint
        push    dx
	mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	mov     ah,2
        mov     dl,cs:[timer_position]
	int     10h
        pop     dx
        mov     cs:[last_ch_second],ax
        mov     dl,byte ptr cs:[last_ch_second]
        add     dl,'0'
        mov     ah,2
        int     21h
        mov     ah,3
        mov     bh,cs:[curpage]
        int     10h
        mov     dl,0
        mov     ah,2
        int     10h
pd_notprint:
        popx    dx,cx,bx,ax
        ret
print_delai endp

parallel_timer proc
	pushx   ax,bx,dx,cx
	cmp     cs:[waitu],1
	je      pt_no
	mov     ah,0
	int     1Ah                     ;key pressed -> forbidden ->KEY 
	sub     dx,cs:[timer]
	cmp     dx,2
	jnae    pt_no
	mov     ah,0
	int     1Ah
	mov     cs:[timer],dx
	call    first_column
        push    cs
        pop     es
	mov     bx,cs:[ch_offset]
	inc     bx
	mov     dl,es:[bx]
	cmp     dl,255    
	jne     n255
	mov     bx,offset cs:[ch_string]
	mov     dl,es:[bx]
    n255:
	mov     cs:[ch_offset],bx
	mov     ah,2
	int     21h

        pushx   ax,bx,cx,dx
        mov     bh,cs:[curpage]
	mov     ah,3
	int     10h
	mov     ah,2
        mov     dl,2
	int     10h
        popx    dx,cx,bx,ax
	mov     ah,2
	int     21h

    pt_no:        
	popx    cx,dx,bx,ax
	ret
parallel_timer endp

params  struc
	attrib               db      7
	c_c                  dw      0
	wrtpos               dw      ?
	line_count           db      0
	absmsg_pos           dw      ?
	ab_escape            db      0
params ends

;±±±±±±± chICAGO ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± version 2.61 ±
; Is DOS 7.xx running?
;       check through standard DOS int 21h fnct 30h
;       set the in_chicago flag, redo the configuration if chICAGO default
;       and warn if newer version.
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
running_chicago proc
	pushx   bx,cx,dx
	mov     ah,30h
	int     21h
        cmp     al,cs:[critical_version]
	jb      rc_not_chicago
	mov     cs:[in_chicago],1
        cmp     cs:[rebooted],1
        je      rc_not_chicago
        cmp     cs:[chicago_default],1
        jne     rc_not_chicago_default
	mov     al,cs:[config_chicago]
	mov     cs:[config],al
	mov     ah,cs:[ext_chicago]
	mov     cs:[ext],ah
  rc_not_chicago:
        popx    dx,cx,bx
	ret
  rc_not_chicago_default:
        mov     cs:[config],'A'
        mov     cs:[config_chicago],'A'
        mov     cs:[ext],0
        mov     cs:[ext_chicago],0
        mov     cs:[chicago_default],1
	jmp     rc_not_chicago
running_chicago endp

running_chicago_msg proc
	pushx   bx,cx,dx
	mov     ah,30h
	int     21h
        cmp     al,cs:[critical_version]
        jb      rcm_not_chicago
	mov     cs:[in_chicago],1
	cmp     ah,0
        ja      rcm_warning
	affiche running_chicago_message
        jmp     rcm_not_chicago
  rcm_warning:
	affiche warning_chicago
  rcm_not_chicago:
        popx    dx,cx,bx
	ret
running_chicago_msg endp

;±±±±±±± TABULATOR ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± version 2.62 ±
; caller: scp@termin
; Show the configuration contained in cnf_contents on screen page 1
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
show_scrolling proc
        pushx   bx,cx,dx,si,di,es,ds         ;preserve registers

	mov     cs:[movin_offset],0
	mov     cs:[scroll_exit],0
	mov     cs:[movin_offset_end],0
	mov     bx,offset cs:[cnf_contents]
	dec     bx
@sc_begin:
	cmp     cs:[scroll_exit],0
	je      @sc_noexit
	popx    ds,es,di,si,dx,cx,bx
	ret
@sc_noexit:
	mov     cs:[scroll_page],bx
	mov     cs:[scroll_numchars],1
	mov     cs:[scroll_numlines],0
	mov     ax,cs:[v_mode]
        add     ax,100h
	xor     di,di
	mov     es,ax
        mov     di,cs:[page1_beginning]
	mov     ah,7
	mov     cs:[temp_pos],es
	call    WaitVSync
        mov     dl,10
	call    horizontal_scrolling
	mov     cs:[movin_offset_end],0
muledit_redo:
        push    cs
        pop     es
	inc     bx
	mov     dl,es:[bx]
	mov     es,cs:[temp_pos]
	mov     al,dl
	mov     cs:[scroll_end],0
	call    filter_chars
	jc      @sc_begin
	stosw
        mov     cs:[temp_pos],es
	call    horizontal_scrolling
	cmp     dl,255
	jne     muledit_redo
	mov     cs:[scroll_numlines],25
	cmp     cs:[@fifty],1
	jne     sc_nepe_50
	mov     cs:[scroll_numlines],50
sc_nepe_50:
	mov     cs:[scroll_end],1
        call    filter_chars
	jmp     @sc_begin
show_scrolling endp

horizontal_scrolling proc
        push    es
        cmp     dl,10
	jne     hzs_exit

	mov     cx,cs:[movin_offset]
	cmp     cx,0
	je      hzs_exit
        push    cs
        pop     es
hzs_next:
	inc     bx
	mov     dl,es:[bx]
        cmp     dl,10
        je      hzs_dec
        cmp     dl,255
	je      hzs_exit
        cmp     dl,240
	ja      hzs_filter
	dec     cx
	jnz     hzs_next
hzs_exit:
        pop  es
	ret
hzs_dec:
        pop     es
	dec     bx
	ret
hzs_filter:
	cmp     dl,'˝'
	jne     hzs_not_color
        push    cs
        pop     es
	inc     bx
	cmp     cs:[message_mono],1
	je      hzs_not_color
	mov     ah,es:[bx]
hzs_not_color:
	jmp     hzs_next
horizontal_scrolling endp

;±±±±±±± TABULATOR ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± version 2.62 ±
; caller: show_scrolling
; filter the caracters, going through show_scrolling to screen, in order to
; check for colors, ends and pages...
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
filter_chars proc
fc_beginning:
        cmp     al,255
	jne     fc_n255
        mov     al,0    ;' '
	jmp     fc_aln13 
fc_n255:
        cmp     al,13
        jne     fc_n13
        mov     al,0    ;' '
	jmp     fc_aln13
fc_n13:
        cmp     al,'˝'
	jne     fc_not_color
        push    cs
        pop     es
	inc     bx
	cmp     cs:[message_mono],1
	je      fc_blackwhite
	mov     ah,es:[bx]
fc_blackwhite:
	inc     bx
	mov     al,es:[bx]
	mov     es,cs:[temp_pos]
	jmp     fc_beginning
fc_not_color:
        cmp     al,10
	jne     fc_aln13
        mov     al,' '
        cmp     cs:[scroll_numchars],0
        je      fc_aln13
        mov     cx,80
	sub     cx,cs:[scroll_numchars]
        mov     al,' '
	rep     stosw
        mov     cs:[scroll_numchars],0
	inc     cs:[scroll_numlines]
   fc_aln13:
        inc     cs:[scroll_numchars]
        cmp     cs:[scroll_numchars],81
	jne     fc_not80
        call    move_to_nextline
	mov     cs:[movin_offset_end],1
	inc     cs:[scroll_numlines]
	mov     cs:[scroll_numchars],0
	call    horizontal_scrolling
	jmp     fc_beginning
   fc_not80:
	cmp     cS:[@fifty],1
	jne     fc_not_50
	cmp     cs:[scroll_numlines],50
	jne     fc_not_25
	mov     cs:[scroll_numlines],0
        call    scr_movements
	stc
	ret
   fc_not_50:
	cmp     cs:[scroll_numlines],25
	jne     fc_not_25
	mov     cs:[scroll_numlines],0
        call    scr_movements
	stc
	ret
   fc_not_25:
	clc
	ret
filter_chars endp

move_to_nextline proc
        push    es
        push    cs
        pop     es
mtn_not_ret:
	inc     bx
	mov     al,es:[bx]
	cmp     al,10
        je      mtn_ret
	cmp     al,255
	je      mtn_ret_255
	jmp     mtn_not_ret
mtn_ret:
        mov     dl,10
mtn_ret_255:
        pop     es
	ret
move_to_nextline endp

scr_movements proc
        push    ax
        mov     al,cs:[config]
        mov     ah,cs:[ext]
        push    ax
        call    anyconf_after?
        pop     ax
        mov     cs:[config],al
        mov     cs:[ext],ah
        pop     ax

        push    ax
        mov     al,cs:[config]
        mov     ah,cs:[ext]
        push    ax
        call    anyconf_before?
        pop     ax
        mov     cs:[config],al
        mov     cs:[ext],ah
        pop     ax

        mov     cs:[at_extremmum],0
scr_beg:
        call    scr_inLINE_statusline
        xor     ax,ax
	mov     ah,0Ch
	int     21h
	mov     ah,0
	int     16h
        call    convert_keyb
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; breakthrough inLINE disabler v 001
        cmp     al,'E'
        je      scr_inLINE
        cmp     al,'e'
        je      scr_inLINE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
        cmp     al,8
        je      scr_help
        cmp     al,0
	je      scr_arrows
	cmp     al,9
	je      scr_exit
	cmp     al,13
	je      scr_exit
	cmp     al,' '
	je      scr_color
	cmp     al,'.'
	je      scr_exit
        cmp     al,1Bh
	je      scr_exit_tab
        cmp     al,'?'
        je      scr_question
	jmp     scr_beg
scr_help:
        mov     cs:[help_call],1
        jmp     scr_exit_tab
scr_question:
        cmp     cs:[inline_enabled],1
        jne     scr_beg
        call    inline_question_mark
        ret
scr_inLINE:
        ;cs:[inline_totals] contains the total number of lines of the config
        cmp     cs:[inline_off],1
        je      scr_beg
        call    scr_inLINE_process
        jc      scr_beg
        stc
        ret
scr_color:
        cmp     cs:[inline_enabled],1
        jne     scr_thecolor
        call    inline_disable_line
        ret
scr_thecolor:
        call    scr_toggle_color
	ret
scr_exit_tab:
	mov     al,9
scr_exit:
        mov     cs:[inline_enabled],0
        call    push_cursor
        mov     cs:[scroll_exit],1
	ret
scr_arrows:
	cmp     ah,48h
	je      @scroll_up
	cmp     ah,4Bh
	je      @scroll_left
	cmp     ah,49h          ;page up
        je      scr_top
	cmp     ah,51h          ;page dn
        je      scr_bottom
	cmp     ah,4Dh
	je      @scroll_right
	cmp     ah,50h
	je      @scroll_down
	cmp     ah,47h
	je      @scroll_home
	jmp     scr_beg
scr_top:
        cmp     cs:[at_top],1
        je      scr_beg
        dec     cs:[macro_counter]
        jmp     scr_exit
scr_bottom:
        cmp     cs:[at_bottom],1
        je      scr_beg
        inc     cs:[macro_counter]
        jmp     scr_exit
@scroll_home:
	call    scroll_tohome_proc
        jc      scr_beg@@
	ret
@scroll_left:
	call    scroll_left_proc
        jc      scr_beg@@
	ret
@scroll_right:
	call    scroll_right_proc
        jc      scr_beg@@
	ret
@scroll_down:
	call    scroll_down_proc
        jc      scr_beg@@
	ret
@scroll_up:
	call    scroll_up_proc
        jc      scr_beg@@
	ret
scr_beg@@:
        jmp     scr_beg
scr_movements endp


;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; breakthrough inline question enabler/disabler, 13.09.95
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
inline_question_mark proc
        pushx   cx,ax,bx,dx,es,ds,si,di

        mov     si,cs:[inline_si_address]
        mov     cx,cs:[inline_position]
        call    ligne_prec
   iqm_nenter:
        lodsb
        cmp     al,10
        jne     iqm_nenter
   iqm_nnline:
        lodsb
        cmp     al,10
        je      iqm_nnline
        dec     si
        loop    iqm_nenter

        pushx   es,ds,ax,si
        push    cs
        pop     es
        mov     cx,cs:[inline_position]
        add     cx,3
        mov     bx,offset cs:[cnf_contents]
   iqm_nline:
        inc     bx
        mov     al,es:[bx]
        cmp     al,10
        jne     iqm_nline
        loop    iqm_nline
        inc     bx
        mov     cs:[cnf_counter],bx
        popx    si,ax,ds,es

        mov     al,ds:[si]
        
        cmp     al,'Z'
        je      iqm_exit

        cmp     al,128
        jb      iqm_enable
        sub     al,128
        mov     ds:[si],al

        push    bx
        call    iqm_define_line
        call    movtostring

        mov     dl,253
        call    chrcnt
        mov     dl,7
        call    chrcnt
        mov     dl,253
        call    chrcnt
        mov     dl,7
        call    chrcnt
        pop     bx
        mov     dl,0
        call    chrcnt

        jmp     iqm_exit
iqm_enable:
        add     al,128
        mov     ds:[si],al

        sub     al,128

        pushx   ax,bx
        mov     bx,offset questionmsg
        call    movtostring
        popx    bx,ax
        push    bx
        call    iqm_define_line
        call    movtostring
        pop     bx
iqm_exit:
        popx    di,si,ds,es,dx,bx,ax,cx

	call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]

        ret
inline_question_mark endp


iqm_define_line proc
        mov     bx,offset numlockmsg
        cmp     al,'N'
        je      iqm_correct
        mov     bx,offset buffersmsg
        cmp     al,'B'
        je      iqm_correct
        mov     bx,offset countrymsg
        cmp     al,'Q'
        je      iqm_correct
        mov     bx,offset devicemsg
        cmp     al,'D'
        je      iqm_correct
        mov     bx,offset devicehighmsg
        cmp     al,'U'
        je      iqm_correct
        mov     bx,offset driveparmmsg
        cmp     al,'P'
        je      iqm_correct
        mov     bx,offset fcbsmsg
        cmp     al,'X'
        je      iqm_correct
        mov     bx,offset filesmsg
        cmp     al,'F'
        je      iqm_correct
        mov     bx,offset installmsg
        cmp     al,'I'
        je      iqm_correct
        mov     bx,offset installhighmsg
        cmp     al,'W'
        je      iqm_correct
        mov     bx,offset lastdrivemsg
        cmp     al,'L'
        je      iqm_correct
        mov     bx,offset shellmsg
        cmp     al,'S'
        je      iqm_correct
        mov     bx,offset stacksmsg
        cmp     al,'K'
        je      iqm_correct
        mov     bx,offset breakmsg
        cmp     al,'C'
        je      iqm_correct
        mov     bx,offset remmsg
        cmp     al,'0'
        je      iqm_correct
        mov     bx,offset setmsg
        cmp     al,'V'
        je      iqm_correct
        mov     bx,offset switchesmsg
        cmp     al,'1'
        je      iqm_correct
        mov     bx,offset dosmsg
        cmp     al,'H'
        je      iqm_correct
        mov     bx,offset illegalmsg
iqm_correct:
        ret
iqm_define_line endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; breakthrough inline disabler, 13.09.95
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
inline_disable_line proc
        pushx   cx,ax,bx,dx,es,ds,si,di
        mov     si,cs:[inline_si_address]
        mov     cx,cs:[inline_position]
        call    ligne_prec
   idl_nenter:
        lodsb
        cmp     al,10
        jne     idl_nenter
   idl_nnline:
        lodsb
        cmp     al,10
        je      idl_nnline
        dec     si
        loop    idl_nenter

        mov     al,ds:[si]
        cmp     al,'Z'
        je      idl_beep@
        cmp     al,'0'
        je      idl_reenable@
        cmp     al,128+'0'
        je      idl_reenable@

        mov     al,'0'
        mov     cs:[ir_enabled],0
   idl_continue:
        mov     ds:[si],al

        push    cs
        pop     es
        mov     cx,cs:[inline_position]
        add     cx,3
        mov     bx,offset cs:[cnf_contents]

   idl_nline:
        inc     bx
        mov     al,es:[bx]
        cmp     al,10
        jne     idl_nline
        loop    idl_nline

        inc     bx
        mov     cs:[cnf_counter],bx
        inc     bx
        mov     al,'?'
        cmp     es:[bx+1],al
        jne     nquest_idl
        mov     al,'Û'
        mov     es:[bx+1],al
        mov     al,7
        mov     es:[bx+2],al
        add     cs:[cnf_counter],2
   nquest_idl:
        cmp     cs:[ir_enabled],1
        je      idl_input

        push    bx
        mov     bx,offset remmsg
        call    movtostring
        pop     bx
        jmp     idl_exit
   idl_beep@:
        jmp     idl_beep
   idl_reenable@:
        jmp     idl_reenable
   idl_input:
        push    ax
        mov     al,128
        cmp     cs:[ir_chosen],al
        jbe     idl_normal
        push    bx
        mov     bx,offset questionmsg
        call    movtostring
        pop     bx
   idl_normal:
        pop     ax

        mov     cs:[ir_enabled],0
        push    bx
        mov     bx,cs:[enable_msg]
        call    movtostring
        pop     bx
        jmp     idl_exit
   idl_exit:
        popx    di,si,ds,es,dx,bx,ax,cx
	call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]
        ret
   idl_beep:
        call    beep
        jmp     idl_exit
   idl_reenable:
        mov     bx,offset cs:[inline_thisconfig]
        add     bx,cs:[inline_position]
        dec     bx
        push    cs
        pop     es
        mov     al,es:[bx]
        cmp     al,'0'
        je      ir_doit
        cmp     al,128+'0'
        je      ir_doit
        pushx   ax,bx,cx,dx,si
        jmp     ir_autochoose

ir_doit:
        pushx   ax,bx,cx,dx,si
        mov     cs:[curpage],1
ir_restart:
        mov     ah,3
        mov     bh,1
        int     10h
        mov     ah,2
        mov     dl,0
        int     10h
        cmp     cs:[inline_reenable],1
        je      ir_1
        cmp     cs:[inline_reenable],2
        je      ir_2
        affiche reenable_msg3
        jmp     ir_wait
ir_1:
        affiche reenable_msg1
        jmp     ir_wait
ir_2:
        affiche reenable_msg2
        jmp     ir_wait
ir_wait:
        xor     ax,ax
        int     16h

        cmp     al,0
        jne     ir_choose

        cmp     ah,48h 
        je      ir_decpage
        cmp     ah,4Bh
        je      ir_decpage
        cmp     ah,50h 
        je      ir_incpage
        cmp     ah,4Dh
        je      ir_incpage
        call    beep
        jmp     ir_restart
ir_incpage:
        cmp     cs:[inline_reenable],3
        jae     ir_first
        inc     cs:[inline_reenable]
        jmp     ir_restart
ir_decpage:
        cmp     cs:[inline_reenable],1
        jbe     ir_last
        dec     cs:[inline_reenable]
        jmp     ir_restart
ir_last:
        mov     cs:[inline_reenable],3
        jmp     ir_restart
ir_first:
        mov     cs:[inline_reenable],1
        jmp     ir_restart
ir_correct@:
        jmp     ir_correct
ir_choose:
        call    conv_maj
ir_autochoose:
        mov     cs:[inline_question_flag],0
        cmp     al,128
        jbe     ir_noquest
        sub     al,128
        mov     cs:[inline_question_flag],1
ir_noquest:
        pushx   bx,si
        mov     bx,offset numlockmsg
        cmp     al,'N'
        je      ir_correct@
        mov     bx,offset buffersmsg
        cmp     al,'B'
        je      ir_correct@
        mov     bx,offset countrymsg
        cmp     al,'Q'
        je      ir_correct@
        mov     bx,offset dosmsg
        cmp     al,'H'
        je      ir_correct
        mov     bx,offset devicemsg
        cmp     al,'D'
        je      ir_correct
        mov     bx,offset devicehighmsg
        cmp     al,'U'
        je      ir_correct
        mov     bx,offset driveparmmsg
        cmp     al,'P'
        je      ir_correct
        mov     bx,offset fcbsmsg
        cmp     al,'X'
        je      ir_correct
        mov     bx,offset filesmsg
        cmp     al,'F'
        je      ir_correct
        mov     bx,offset installmsg
        cmp     al,'I'
        je      ir_correct
        mov     bx,offset installhighmsg
        cmp     al,'W'
        je      ir_correct
        mov     bx,offset lastdrivemsg
        cmp     al,'L'
        je      ir_correct
        mov     bx,offset shellmsg
        cmp     al,'S'
        je      ir_correct
        mov     bx,offset stacksmsg
        cmp     al,'K'
        je      ir_correct
        mov     bx,offset breakmsg
        cmp     al,'C'
        je      ir_correct
        mov     bx,offset remmsg
        cmp     al,'0'
        je      ir_correct
        mov     bx,offset setmsg
        cmp     al,'V'
        je      ir_correct
        mov     bx,offset switchesmsg
        cmp     al,'1'
        je      ir_correct

        popx    si,bx
        mov     ah,3
        mov     bh,1
        int     10h
        mov     ah,2
        mov     dl,0
        int     10h
        popx    si,dx,cx,bx,ax
        jmp     idl_beep
ir_correct:
        mov     cs:[enable_msg],bx
        popx    si,bx
        
        mov     cs:[ir_chosen],al
        ;put the cursor back
ir_finish:
        mov     ah,3
        mov     bh,1
        int     10h
        mov     ah,2
        mov     dl,0
        int     10h
        popx    si,dx,cx,bx,ax
        mov     al,cs:[ir_chosen]
        cmp     cs:[inline_question_flag],1
        jne     ir_nquestion
        add     al,128
        mov     cs:[ir_chosen],al
ir_nquestion:
        mov     cs:[ir_enabled],1
        jmp     idl_continue
inline_disable_line endp

scr_inLINE_statusline proc
        cmp     cs:[inline_enabled],1
        jne     scris_exit
        pushx   ax,bx,dx,cx,si
        mov     ah,3
        mov     bh,1
        int     10h

        pushx   ax,dx
        mov     ah,2
        mov     dh,12
        mov     dl,65
        mov     bh,1
        int     10h

        call    inline_num2string
        popx    dx,ax
        mov     ah,2
        mov     bh,1
        int     10h
        popx    si,cx,dx,bx,ax
   scris_exit:
        ret
scr_inLINE_statusline endp


;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; breakthrough inLINE disabler v 001
scr_inLINE_process proc
        clc
        cmp     cs:[inline_totals],0
        jne     scr_inline_notzero
        stc
        ret
scr_inline_notzero:
        cmp     cs:[inline_enabled],1
        jne     scr_inLINE_enable
        call    inline_hide_cursor
        ret
scr_inLINE_enable:
        mov     cs:[inline_enabled],1
        mov     cs:[inline_position],1
        call    inline_put_cursor
	ret
scr_inLINE_process endp

inline_put_cursor proc
        push    bx
        mov     bx,cs:[cnf_name]
        mov     cs:[cnf_counter],bx
        mov     bx,offset linemsg2
	call    movtostring
        pop     bx

        mov     cs:[movin_offset],0
        call    efface_page1_ecran
	mov     bx,offset cs:[cnf_contents]
        dec     bx

        pushx   ax,bx,cx,dx,es
        call    pop_cursor
        mov     bh,1
        mov     ah,2
        mov     dh,4
        mov     dl,0
        int     10h
        popx    es,dx,cx,bx,ax
	ret
inline_put_cursor endp

inline_hide_cursor proc
        push    bx
        mov     bx,cs:[cnf_name]
        mov     cs:[cnf_counter],bx
        mov     bx,offset linemsg
	call    movtostring
        pop     bx

	mov     cs:[movin_offset],0
        mov     cs:[inline_enabled],0
        call    push_cursor
        call    efface_page1_ecran
	mov     bx,offset cs:[cnf_contents]
        dec     bx
        ret
inline_hide_cursor endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

scroll_tohome_proc proc
        cmp     cs:[inline_enabled],1
        jne     sth_ret
        stc
        ret
sth_ret:
	mov     cs:[movin_offset],0
	call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]
        clc
	ret
scroll_tohome_proc endp

scroll_left_proc proc
        cmp     cs:[inline_enabled],1
        je      slp_beep
        cmp     cs:[movin_offset],0
	je      slp_beep
	dec     cs:[movin_offset]
	call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]
        clc
	ret
slp_beep:
        ;call    beep
        stc
        ret
scroll_left_proc endp

scroll_right_proc proc
        cmp     cs:[inline_enabled],1
        je      slp_ret_beep
        cmp     cs:[movin_offset_end],0
	je      slp_ret_beep
	inc     cs:[movin_offset]
	call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]
        clc
	ret
slp_ret_beep:
        ;call    beep
        stc
        ret
scroll_right_proc endp

scr_toggle_color proc
	mov     bx,cs:[scroll_page]
	cmp     cs:[message_mono],1
	jne     scrt_tocolor
	mov     cs:[message_mono],0
	ret
scrt_tocolor:
	mov     cs:[message_mono],1
	ret
scr_toggle_color endp

scroll_up_proc proc
        clc
        cmp     cs:[inline_enabled],1
        jne     sup_inline_ignore
        cmp     cs:[inline_position],1
        ja      sup_inline_staythere
        pushx   ax,bx,cx,dx
        mov     ah,3
        mov     bh,1
        int     10h
        cmp     dh,0
        jne     sup_nottop
        popx    dx,cx,bx,ax
        call    efface_page1_ecran
        mov     bh,1
        mov     ah,2
        mov     dh,4
        mov     dl,0
        int     10h
        jmp     scroll_up_end
     sup_nottop:
        popx    dx,cx,bx,ax
        stc
        ret
sup_inline_staythere:
        mov     ah,3
        mov     bh,1
        int     10h

        dec     cs:[inline_position]
        cmp     dh,0
        je      sup_inline_ignore

        mov     bh,1
        mov     ah,2
        dec     dh
        int     10h
        stc
        ret
sup_inline_ignore:
;normal scroll up routine

	mov     bx,cs:[scroll_page]
	dec     bx
	cmp     bx,offset cs:[cnf_contents]
        ja      sup_dontworry
        stc
        ret
sup_dontworry:
        call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]
@@scroll_up:
	dec     bx
	cmp     bx,offset cs:[cnf_contents]
	jbe     scroll_up_end
	mov     dl,es:[bx]
        cmp     dl,10
	jne     @@scroll_up
        clc
        ret
scroll_up_end:
	mov     bx,offset cs:[cnf_contents]
	dec     bx
        clc
        ret
scroll_up_proc endp

scroll_down_proc proc
        clc
        mov     ax,cs:[inline_totals]
        cmp     cs:[inline_enabled],1
        jne     sdp_inline_ignore
        cmp     cs:[inline_position],ax
        jne     sdp_inline_staythere
        stc
        ret
sdp_inline_staythere:
        mov     ah,3
        mov     bh,1
        int     10h

        mov     ah,24
        cmp     cs:[@fifty],1
        jne     sdp_nfifty
        add     ah,25
sdp_nfifty:
        inc     cs:[inline_position]
        cmp     ah,dh
        je      sdp_inline_ignore

        mov     bh,1
        mov     ah,2
        inc     dh
        int     10h
sdp_redo:
        stc
        ret
sdp_inline_ignore:
        cmp     cs:[scroll_end],1
        je      sdp_redo
	call    efface_page1_ecran
        push    cs
        pop     es
	mov     bx,cs:[scroll_page]
@@scroll_down:
	inc     bx
	mov     dl,es:[bx]
        cmp     dl,10
	jne     @@scroll_down
        clc
	ret
scroll_down_proc endp

efface_page1_ecran proc
	pushx   ax,bx,cx,dx,si,di,es,ds         ;preserve registers
	mov     ax,cs:[v_mode]
        add     ax,100h
	mov     cx,2000
	xor     di,di
;        add     di,cs:[video_25_add]
        cmp     cs:[@fifty],1
        jne     nepe_50
;        add     di,cs:[video_50_add]       ;4160
        add     cx,cx
nepe_50:
        mov     di,cs:[page1_beginning]
	mov     es,ax
	xor     ax,ax
	rep     stosw
	popx    ds,es,di,si,dx,cx,bx,ax
	ret
efface_page1_ecran endp

;±±±±±±± WaitVSync ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± ?.09.94 ±±
; Wait for vertical retrace by LOOM
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

WaitVSync       proc
		cmp     cs:[hlp_buffer],1
		jne     @@sd_nowait
		mov     dx, input_1         ; input status #1 register
; wait for any current retrace to end
	@@sd_wait0:
		in      al, dx              ; get vga status
		and     al, vert_retrace    ; in display mode yet?
		jnz     @@sd_wait0          ; if not, wait for it
					    ; wait for the start of the next vertical retrace
	@@sd_wait1:
		in      al, dx              ; get vga status
		and     al, vert_retrace    ; vertical retrace start?
		jz      @@sd_wait1          ; if not, wait for it
	@@sd_nowait:
		ret
WaitVSync endp

hlp_help proc
        mov        cs:[help_call],0
	mov        dx,offset hlp_msg
	mov        cs:[msgoffset],dx
	mov        dl,cs:[message_mono]
        push       dx
	mov        cs:[hlp_buffer],1
	call       mulpages_msg_affiche
	mov        cs:[hlp_buffer],0
        pop        dx
	mov        cs:[message_mono],dl
	mov        ah,0
	mov        al,cs:[video_mode]
	int        10h
	mov        cs:[@fifty],0
	cmp        cs:[force_fifty],1
	jne        hlp_nff
	call       fifty
	jmp        hlp_fif
   hlp_nff:
	pushx   ax,bx
	mov     ah,11h
	mov     al,4h  
	xor     bx,bx
	int     10h
	mov     cs:[@twenty],1
	mov     cs:[@fifty],0
	call    push_cursor
	popx    bx,ax
   hlp_fif:
	cmp        cs:[anyerrors_help],1
	je         hlp_nolist        
	cmp        cs:[from_list],1
	je         hlp_nolist
	cmp        cs:[erreur_dollar],1
	jne        hlp_norm
   hlp_nolist:
	call       pop_cursor
	call       force_efface_ecran
	ret
   hlp_norm:      
	call       force_efface_ecran
	mov        cs:[enter_count],0
	call       liste_configuration
	call       pop_cursor
	ret
hlp_help endp


;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; pause...asking to press a key...stosb changes color
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
slam_enter proc
        call    push_cursor
        pushx   bx,cx,dx
        affiche slam_key_msg
        xor     ax,ax
        mov     ah,0Ch
        int     21h

        mov     bh,0
	mov     ah,3        
	int     10h
        mov     es,cs:[v_mode]
        mov     ax,160
        mul     dh
        mov     di,ax
        inc     di
        push    di
        mov     cs:[n_color],8
   sl_next:
        mov     cx,30
        cmp     cs:[n_color],15
        je      sl_next_color
        mov     cs:[n_color],15
        pop     di
        push    di
        jmp     sl_loop
   sl_next_color:
        mov     cs:[n_color],8
        pop     di
        push    di
   sl_loop:
        push    cx
        mov     ah,0
	int     1Ah                     ;key pressed -> forbidden ->KEY 
	sub     dx,cs:[timer]
        pop     cx
        cmp     dx,1
        jnae    @pt_no
        push    cx
	mov     ah,0
	int     1Ah
	mov     cs:[timer],dx
        pop     cx

        mov     al,cs:[n_color]
        stosb
        inc     di
        dec     cx
    @pt_no:
        inc     cx
        xor     ax,ax
        mov     ah,1
        int     16h
        jnz     sl_out
        loop    sl_loop
        jmp     sl_next
   sl_out:
        pop     di
        push    ax
        dec     di
        mov     cx,80
        mov     al,' '
        mov     ah,7
        rep     stosw
        mov     ah,2
        mov     dl,10
        int     21h
        mov     ah,2
        mov     dl,13
        int     21h
        pop     ax
        popx    dx,cx,bx
        call    pop_cursor
        ret
slam_enter endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; returns carry if a key was pressed, otherwise returns no carry after
; timed out.
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
attend_timer_routine proc
        pushx   bx,cx,dx
        clc
	mov     ah,0                    ;-> key pressed -> jump or not
	int     1Ah                     ;key pressed -> forbidden ->KEY 
   atr_next:
        mov     ah,1
        int     16h
        jz      atr_no_key
        stc
        popx    dx,cx,bx
        ret
    atr_no_key:
        mov     ah,0                    ;-> key pressed -> jump or not
        push    dx                      ;if mov ah,1 inside
	int     1Ah                     ;key pressed -> forbidden ->KEY 
	mov     cx,dx                   ;CAN BE PResSED, since parallel intr.
        pop     dx
        sub     cx,dx
        push    ax
        mov     ax,cs:[key_timer]
        mov     cs:[key_delai],ax
        call    print_delai
        pop     ax
        cmp     cx,cs:[key_timer]
        jb      atr_next
        popx    dx,cx,bx
        ret
attend_timer_routine endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; set carry if this version of DOS should be timered, combination of /J & /T
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
define_attendre proc
        clc
        pushx   ax,bx,cx,dx
	mov     ah,30h
	int     21h
        cmp     al,cs:[critical_version]
        jb      dw_not_chicago
        mov     al,cs:[chicago_waitu]
        mov     cs:[waitu],al
        mov     ax,cs:[chicago_key_delai]
        cmp     ax,0
        je      dw_end
        cmp     cs:[chicago_always_wait],0
        je      dw_end
        jmp     dw_carry
  dw_not_chicago:
        mov     al,cs:[dos_waitu]
        mov     cs:[waitu],al
        mov     ax,cs:[dos_key_delai]
        cmp     ax,0
        je      dw_end
        cmp     cs:[toujours_wait],0
        je      dw_end
        jmp     dw_carry
  dw_carry:
        stc
  dw_end:
        popx    dx,cx,bx,ax
        ret
define_attendre endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; TRANSFORMER LE KEY_DELAY EN KEY_TIMER?
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
analyse_wait proc
        cmp     cs:[attend_timer],1
        je      attend_void
        cmp     cs:[prepared_timer],1
        jne     npreap
        call    define_attendre
        jnc     npreap
        mov     cs:[attend_timer],1
        push    ax
        mov     ax,cs:[key_delai]
        mov     cs:[key_timer],ax
        mov     cs:[key_delai],0
        pop     ax
    npreap:
        ret
    attend_void:
        mov     cs:[attend_timer],0
        ret
analyse_wait endp

save_config proc
        push    ax
        mov     al,cs:[config]
        mov     cs:[@save_config],al
        mov     al,cs:[ext]
        mov     cs:[@save_ext],al
        pop     ax
        ret
save_config endp

restore_config proc
        push    ax
        mov     al,cs:[@save_config]
        mov     cs:[config],al
        mov     al,cs:[@save_ext]
        mov     cs:[ext],al
        pop     ax
        ret
restore_config endp

advance_with_char proc
        pushx   ax,bx,cx,dx
        mov     ah,9
        mov     bh,0
        mov     cx,1
        mov     bl,7
        mov     al,' '
        int     10h
        mov     ah,3
        mov     bh,0
        int     10h
        inc     dl
        mov     ah,2
        int     10h
        popx    dx,cx,bx,ax
        ret
advance_with_char endp

advance_char proc
        pushx   ax,bx,cx,dx
        mov     ah,3
        mov     bh,0
        int     10h
        inc     dl
        mov     ah,2
        int     10h
        popx    dx,cx,bx,ax
        ret
advance_char endp

save_line_color proc
        pushx   ax,bx,cx,dx,es,ds,si
        cld
;               In:  ah = Row
;               al = Column
;               Out: di = Memory Offset
        call    MoveXY_di
        mov     ax,cs:[v_mode]
        mov     ds,ax
        push    cs
        pop     es
        mov     si,di
        mov     di,offset cs:[line_color]
        mov     cx,160
        rep     movsb
        popx    si,ds,es,dx,cx,bx,ax
        ret
save_line_color endp

restore_line_color proc
        pushx   ax,bx,cx,dx,es,ds,si
        mov     ah,dh
        inc     ah
        mov     al,1
        ; In:  ah = Row
        ;      al = Column
        ; Out: di = Memory Offset
        call    MoveXY_di
	mov     ax,cs:[v_mode]
        mov     es,ax
        push    cs
        pop     ds
        mov     si,offset cs:[line_color]
        mov     cx,160
        rep     movsb
        popx    si,ds,es,dx,cx,bx,ax
        ret
restore_line_color endp

inline_num2string proc
                pushx   ax,bx,cx,dx,es
                mov     dl,'['
                call    write_char
                mov     dx,cs:[inline_position]
                call    write_decimal
                mov     dl,'/'
                call    write_char
                mov     dx,cs:[inline_totals]
                call    write_decimal
                mov     dl,']'
                call    write_char
                mov     ah,3
                mov     bh,1
                int     10h
                mov     ch,80
                sub     ch,dl
                mov     ah,2
                mov     dl,' '
        inp_next:
                call    write_char
                dec     ch
                jnz     inp_next
                popx    es,dx,cx,bx,ax
		ret			; Return dx:ax = ASCII number
inline_num2string endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; This procedure prints a character on the screen using the DOS         ;
; function call.                                                        ;
; On entry:     dl      Byte to print on screen.                        ;
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
write_char      proc
        pushx    ax,bx,cx,dx      

        mov     ah,9                    ;Call for character output
        mov     bh,cs:[curpage]
        mov     cx,1
        mov     al,dl
        mov     bl,cs:[c_color]
        cmp     dl,' '
        jne     wc_nspace
        mov     bl,7
wc_nspace:
        int     10h
        mov     ah,3
        mov     bh,cs:[curpage]
        int     10h
        inc     dl
        mov     bh,cs:[curpage]
        mov     ah,2
        int     10h
        popx    dx,cx,bx,ax                      ;Restore old value in ax

	ret                             ;And return
write_char      endp

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; This procedure writes a 16-bit, unsigned number in decimal notation.  ;
; On entry:     dx      N : 16-bit, unsigned number.                    ;
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
write_decimal   proc
        push    ax                      ;Save registers used here
        push    cx
        push    dx
        push    si
        mov     ax,dx
        mov     si,10                   ;Will divide by 10 using si
        xor     cx,cx                   ;Count of digits placed on stack
non_zero:
        xor     dx,dx                   ;Set upper word of N to 0
        diV     si                      ;Calculate N/10 and (N mod 10)
        push    dx                      ;push one digit onto the stack
        inc     cx                      ;One more digit added
        OR      ax,ax                   ;N = 0 yet?
        jne     non_zero                ;Nope, continue
write_digit_loop:
        pop     dx                      ;Get the digits in reverse order

        push    dx                      ;Save registers used
        cmp     dl,10                   ;Is this nibble <10?
	jae     hex_letter              ;No, convert to a letter
        add     dl,"0"                  ;Yes, convert to a digit
        jmp     write_digit       ;Now write this character
   hex_letter:
        add     dl,"A"-10               ;Convert to hex letter
   write_digit:
        call    write_char              ;Display the letter on the screen
        pop     dx                      ;Restore old value of dx

        loop    write_digit_loop
end_decimal:
        pop     si
        pop     dx
        pop     cx
        pop     ax
        ret
write_decimal   endp

elite_translate proc
        pushx   bx,cx,ax
        mov     al,dl
        cmp     cs:[elite_msg],1
        jne     et_firstend
        call    conv_maj
        cmp     al,'A'
        je      et_tomin
        cmp     al,'E'
        je      et_tomin
        cmp     al,'U'
        je      et_tomin
        cmp     al,'I'
        je      et_tomin
        cmp     al,'O'
        je      et_tomin
        cmp     al,'Y'
        je      et_tomin
        jmp     et_end
   et_tomin:
        call    conv_min
        jmp     et_end

   et_firstend:
        cmp     cs:[elite_msg],2
        jne     et_end
        call    conv_min
        cmp     al,'a'
        je      et_tomin@
        cmp     al,'e'
        je      et_tomin@
        cmp     al,'u'
        je      et_tomin@
        cmp     al,'i'
        je      et_tomin@
        cmp     al,'o'
        je      et_tomin@
        cmp     al,'y'
        je      et_tomin@
        jmp     et_end
   et_tomin@:
        call    conv_maj
   et_end:
        mov     dl,al
        popx    ax,cx,bx
        ret
elite_translate endp

compile_date proc
        pushx   ax,bx,cx,dx,es,ds,si,di

        push    cs
        pop     ds
        push    cs
        pop     es
        mov     si,offset cs:[version_info]
        mov     di,offset cs:[msg_mon]
        add     di,173

    compile_it_a:
        mov     dl,ds:[si]
        cmp     dl,0
        je      compile_it_a_end
        cmp     dl,128
        ja      cd_ndec
        cmp     dl,32
        jb      cd_ndec
        xor     dl,cs:[xor_byte]
    cd_ndec:
        mov     ds:[si],dl
        movsb
        jmp     compile_it_a
    compile_it_a_end:

        push    cs
        pop     ds
        push    cs
        pop     es
        mov     si,offset cs:[compiled_date]
        mov     cx,8
    compile_it:
        mov     dl,ds:[si]
        cmp     dl,0
        je      compile_it_end
        cmp     dl,128
        ja      cd_ndec@
        cmp     dl,32
        jb      cd_ndec@
	xor     dl,cs:[xor_byte]
    cd_ndec@:
        mov     ds:[si],dl
        movsb
        jmp     compile_it
    compile_it_end:
        popx    di,si,ds,es,dx,cx,bx,ax
        ret
compile_date endp

rubbish_skip proc
   rs_next:
        lodsb
        cmp     al,10
        je      rs_exit
        cmp     al,' '
        jbe     rs_next
        clc
        ret
   rs_exit:
        dec     si
        stc
        ret
rubbish_skip endp 

make_line_color proc
        pushx   ax,bx,cx,dx,es,ds,si
        cld
        mov     di,offset cs:[line_color]
        push    cs
        pop     es
        mov     cx,80
        mov     al,' '
        mov     ah,7
        rep     stosw
        popx    si,ds,es,dx,cx,bx,ax
        ret
make_line_color endp

compiled_date           db      'assembl.: 11/01/96 (14:26)'
                        db      '  ˝',0
inline_si_address       dw      ?
line_color              db      200 dup (7)
timer_position          db      1
last_ch_second          dw      0
@save_config            db      0
@save_ext               db      0
scroll_color            db      0
scroll_end              db      0
scroll_page             dw      ?
scroll_exit             db      0
scr_numlines            dw      0
scr_numchars            dw      0
scroll_numchars         dw      0
scroll_numlines         dw      0
waitu                   db      0
chicago_waitu           db      0
dos_waitu               db      0
ch_string               db      '˙˘˛€˛˘ˇ'
ch_offset               dw      offset ch_string
timer                   dw      ?
hlp                     params  <7,0,?,0,?,0>
liste                   params  <7,0,?,0,?,0>
@keyb                   dw      'US'
char@conv               db      ?
doconv                  db      0
MonoSeg                 equ     0B000h          ; Mono screen segment
CGASeg                  equ     0B800h          ; CGA screen segment
VideoMode               DB      0               ; Current BIOS INT 10 vid mode
v_mode                  dw      CGASeg
incdec                  db      0
custom_error            db      0
config                  db      'A'
key_delai               dw      0
key_timer               dw      0
dans_config             db      ?
debut_ligne             dw      ?
prem_ligne              dw      ?
fin_config              dw      ?
message_ou_pas          db      0
toujours_wait           db      0
message_mono            db      0
pas_eff_ecran           db      0
erreur_dollar           db      0
last_conf               db      0
caps                    db      1
cfg_file_name           db      'A:\AUTOCONF.DAT',0
count                   db      0
crochet                 db      0
fatal_error             db      0
temp_key                db      ?
switch_error            db      0
last_pos                dw      ?
first_line              db      0
enter_count             db      0
last_line               db      0
end_achived             db      0
the_first               db      0
alpha_letter            db      0
c_color                 db      127
n_color                 db      1
beglist_jump            db      1
second                  db      0
thesipos                dw      ?
ext                     db      0
ext_put                 db      0
ext_list                db      '/'
config_string           db      '*A'
ext_depend              db      0
msgoffset               dw      ?
anyerrors_help          db      0
cnf_counter             dw      ?
beep_div                equ     1300            ; fairly close to IBM beep
beep_len                equ     3               ; 3/18 sec- shorter than IBM
curpage                 db      0
chosenlist              db      0
num_confs               db      0
show_conf_choose        db      0
scm_ch_conf             dw      ?
eof_help                db      0
ap_gen                  db      0
@twenty                 db      1
@fifty                  db      0
video_mode              db      ?
force_fifty             db      0
timer_low               dw      ?       ; low word of time-of-day counter (18.2 hz)
lbeg                    db      0
lend                    db      0
letterr                 db      ' '
letterg                 db      ' '
lettergleft             db      ' '
ext_chicago             db      0
config_chicago          db      0
chicago_default         db      0
do_f4                   db      0
skip_configuration      db      0
config_ext              db      0
temp_pos                dw      ?
input_1                 equ     03dah   ; input status #1 register
vert_retrace            equ     08h     ; input_1: vertical retrace bit
hlp_buffer              db      0
chicago_always_wait     db      0
in_chicago              db      0
movin_offset            dw      0
movin_offset_end        dw      0
already_lined           db      0
wrtstr                  db      2000 dup (?)
configs_string          db      7000 dup (?)
cnf_contents            db      7000 dup (?)
configs_history         db      15 dup (0)
configs_ext_history     db      15 dup (0)
tobestored_buffer       db      50 dup (0)
top_level               db      1
sub_level               db      1
this_level              db      0
top_config              db      'A'
top_ext                 db      0
need_level              db      1
restart_liste           db      0
group_address           dw      ?
chosen_list             db      0
start_address           dw      ?
end_address             dw      ?
made_address            db      0
from_list               db      0
to_be_made              db      0
theres_key              db      0
increment_byte          db      0
xor_byte                db      11101000b
prepared_timer          db      0
jattendre               db      0
attend_timer            db      0
chicago_key_delai       dw      0
dos_key_delai           dw      0
l_color                 db      7
cnf_dsig_color          db      7
disable_esc             db      0
inline_enabled          db      0
inline_position         dw      0
inline_totals           dw      0
simpleminded            db      0
setstr                  db      10,'VCONF=XX',10
setstrhard              db      200 dup (0)
setstr_length           dw      0
stack_length            dw      0
annee                   dw      0
mois                    db      0
jour                    dw      0
heures                  dw      0
minutes                 dw      0
semaine                 db      0
video_information       db      64 dup (?)
inline_thisconfig       db      1000 dup (0)
inline_off              db      0
inline_reenable         db      1
ir_chosen               db      0
cnf_name                dw      0
message_title           db      0
read_write_nodat        db      0
rw_lc_mix               db      0
addspace                db      0
enable_msg              dw      offset remmsg
ir_enabled              db      0
inline_question_flag    db      0
video_25_add            dw      0
video_50_add            dw      4160
page1_beginning         dw      ?
bootit_list             db      0
rebooted                db      0
elite_msg               db      0
be                      db      '<>¸1234567890¯_AZERTYUIOP˘*QSDFGHJKLM%ú>WXCVBN?./+˝&Ç"''(ıä!áÖ)-^$MóÊ<;:=ˇ'
cf                      db      'ÆØ|!"/$%?&*()_+QWERTYUIOP^§ASDFGHJKL:`>ØZXCVBNM''.ê#1234567890-=^•;`<Æ,.Çˇ'
cz                      db      '&*¯1234567890%ÛQWERTZUIOP/(ASDFGHJKL" `*YXCVBNM?:_;+234567890=''[);''\&,.-ˇ'
sl                      db      '&*¯1234567890%ÛQWERTZUIOP/(ASDFGHJKL" )*YXCVBNM?:_;+234567890=''[ ;''\&,.-ˇ'
dk                      db      '<>ı!"#œ%&/()=?`QWERTYUIOPè^ASDFGHJKLíù*>ZXCVBNM;:_´1234567890+ÔÜ˘ëõ''<,.-ˇ'
su                      db      '<>´!"#œ%&/()=?`QWERTYUIOPè^ASDFGHJKLôé*>ZXCVBNM;:_ı1234567890+ÔÜ˘îÑ''<,.-ˇ'
fr                      db      '<>¯1234567890¯+AZERTYUIOP˘úQSDFGHJKLM%Ê>WXCVBN?./_˝&Ç"''(-ä_áÖ)=^$Mó*<;:!ˇ'
gr                      db      '<>¯!" $%&/()=?`QWERTZUIOPö*ASDFGHJKLôé''>YXCVBNM;:_^1234567890·''Å+îÑ#<,.-ˇ'
hu                      db      '\|¯''"+%/=()ôö+QWERTZUIOP{ ASDFGHJKL:"||YXCVBNM?:_0123456789îÅ=[ ;''\\,.-ˇ'
it                      db      '<>|!"ú$%&/()=?^QWERTYUIOPÇ*ASDFGHJKLá¯ >ZXCVBNM;:_\1234567890''çä+ïÖó<,.-ˇ'
la                      db      '<>¯!"#$%&/()=?≠QWERTYUIOP˘*ASDFGHJKL•[]>ZXCVBNM;:_|1234567890''®Ô+§{}<,.-ˇ'
nl                      db      '][¯!"#$%&_()''?~QWERTYUIOP^≥ASDFGHJKLÒ`>[ZXCVBNM;:=@1234567890/¯˘*+''<],.-ˇ'
no                      db      '<>ı!"#œ%&/()=?`QWERTYUIOPè^ASDFGHJKLùí*>ZXCVBNM;:_|1234567890+\Ü˘õë''<,.-ˇ'
pl                      db      '<>˙!"# %&/()=?*QWERTZUIOP{ ASDFGHJKL:"|>YXCVBNM;:_˛1234567890+''[ ;''\<,.-ˇ'
po                      db      '<>~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:"||ZXCVBNM<>?`1234567890-=[];''\\,./ˇ'
sp@                     db      '<>¶!"˙$%&/()=?®QWERTYUIOP^*ASDFGHJKL•˘Ä>ZXCVBNM;:_ß1234567890''≠`+§Ôá<,.-ˇ'
sv                      db      '<>´!"# %&/()=?`QWERTYUIOPè^ASDFGHJKLôé*>ZXCVBNM;:_¯1234567890+''Ü˛îÑ''<,.-ˇ'
sf                      db      '<>¯+"*á%&/()=?`QWERTZUIOPÅ!ASDFGHJKLîÑú>YXCVBNM;:_ı1234567890''^ä˘ÇÖ$<,.-ˇ'
sg                      db      '<>¯+"*á%&/()=?`QWERTZUIOPä!ASDFGHJKLÇÖú>YXCVBNM;:_ı1234567890''^Å˘îÑ$<,.-ˇ'
uk                      db      '\|™!"ú$%^&*()_+QWERTYUIOP{}ASDFGHJKL:@~|ZXCVBNM<>?`1234567890-=[];''#\,./ˇ'
us                      db      '\|~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:"||ZXCVBNM<>?`1234567890-=[];''\\,./ˇ'
yu                      db      '<>˘!"#$%&/()=?*QWERTZUIOP  ASDFGHJKL   >YXCVBNM;:_˜1234567890''+     <,.-ˇ'
version_info            db      '3.00.00 ˝',0
critical_version        db      7
no_envvar               db      0
extatr                  db      7
at_top                  db      0
at_bottom               db      0
at_extremmum            db      0
macro_counter           dw      512
in_config               db      0
made_one                db      0
help_call               db      0
iloom_enabled           db      0

end                                     ;oh finally the end...

ˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇ§lêl  Q!          ! ˚ëãvÎää¡¿¯òãÿÄ·∞“‡FÄ< uÁ^_…¬  »
  WVã~ãEâFˆãEâF¯äEàF˝äEàF¸h™j WËl%HuÈø@@uÈºWh∏KË˛¸ãÉ˛&uÈßtVËf\ˆuÕâv˙ˆ∏Kt3ˇÎmˇvˇvËe¸ˇ6JË•ãÿâF˛äG*‰ã¯*‚ˆÿã^,äOã^*ÌO;¡v†‚ãœ*¡˛»Îˇˇˇ