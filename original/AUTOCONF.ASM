; Transcribed from Science & Vie Micro no. 88 (November 1991), pp. 227-233.
; Original program by Julien Pommier. OCR-derived transcription; consult the PDF scan.

CODE SEGMENT
ASSUME CS:CODE
ORG 0000H
                                                ; Données du header
driver_suiv             dw      -1
                        dw      -1
attribut                dw      8004h
req                     dw      offset sys_request
run                     dw      offset init
nom_device              db      'NUL     '
new_device              proc far
nreq:
        or      es:word ptr [bx+3],0100h
nrun:
        ret
new_device              endp
fin_residant            label near              ; on perd 32 octets
                                                ; avec un dos < 3.3
req_ofs                 dw      ?
req_seg                 dw      ?
sys_request             proc far
        mov     cs:[req_ofs],bx                 ; memorise l'adresse
        mov     cs:[req_seg],es                 ; request header
        ret
sys_request             endp
init                    proc far
        cld
        push    ax                              ; sauve les registres
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        push    ds
        push    cs
        pop     ds
        mov     dx,offset msg
        mov     ah,9
        int     21h
        call    init_driver
        lds     bx,cs:[dword ptr req_ofs]
        lds     si,[bx+18]                      ; adresse des parametres
        call    analyse_param                   ; analyse les parametres
        call    cherche_fin_config              ; recherche la fin du config
        call    lit_configuration               ; lit la configuration
        call    compacte_config                 ; trie les commandes
        call    clean_and_move                  ; nettoie toute la zone de config.
        mov     al,cs:[config]                  ; inscrit le numéro de configuration
        sub     al,'A'-1                        ; dans le vecteur d'interruption Ofah
        sub     bx,bx
        mov     ds,bx
        mov     ds:[0FAh*4],al
        pop     ds
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
init                    endp
init_driver             proc                    ; seulement si DOS < 3.3
        lds     bx,dword ptr cs:[req_ofs]
        mov     word ptr [bx+14],0              ; pour ne pas laisser le
        mov     word ptr [bx+16],cs             ; driver resident
        push    bx
        mov     ah,30h                          ; lit la version dos
        int     21h
        pop     bx
        cmp     al,3
        ja      no_tsr
        cmp     ah,21
        ja      no_tsr                          ; teste si dos supérieur a 3.21
        mov     word ptr [bx+14],offset fin_residant  ; sinon, le driver
        mov     cs:[run],offset nrun            ; remplacera l'ancien driver NUL
        mov     cs:[req],offset nreq
no_tsr:
        ret
init_driver             endp
ligne_suiv              proc
nextc:
        lodsb                                   ; lit un caractere
        cmp     al,10                           ; saut de ligne ?
        jne     nextc
nextc2:
        lodsb                                   ; boucle tant qu'il y a des sauts
        cmp     al,10
        je      nextc2
        dec     si
        ret
ligne_suiv              endp
verifie_config          proc
        push    si
        mov     bl,al                           ; sauve le caractere de laconfig.
v_next:
        call    ligne_suiv                      ; cherche device=*
        lodsb
        cmp     al,'D'
        jne     v_next
        lodsb
        cmp     al,'$'
        je      v_config_nok
        cmp     al,'*'
        jne     v_next
        lodsb
        cmp     al,bl
        je      v_config_ok
        jmp     v_next                          ; la config. n'existe pas
v_config_nok:
        stc
        pop     si
        ret
v_config_ok:
        clc
        pop     si
        ret
verifie_config          endp
affiche_config_name     proc
        mov     dx,si
acn_suiv:                                       ; cherche la fin de ligne
        lodsb
        cmp     al,10
        jne     acn_suiv
        mov     ax,'$'*256 +13                  ; ecrit le retour a la ligne et
        xchg    [si],ax                         ; le caractere $ (qui signale au dos
        push    ax                              ; de la chaine de caracteres)
        mov     ah,9
        int     21h
        pop     ax
        mov     [si],ax
        mov     si,dx
        ret
affiche_config_name     endp
conv_maj                proc
        cmp     al,'a'
        jb      cm_no_conv
        cmp     al,'z'
        ja      cm_no_conv
        sub     al,'a'-'A'
cm_no_conv:
        ret
conv_maj                endp
find_switch             proc
fs_car_suiv:
        lodsb
        cmp     al,'/'
        je      fs_switch
        cmp     al,' '
        jae     fs_car_suiv
        stc                                     ; stc si fin de la ligne
        ret
fs_switch:
        clc
        ret
find_switch             endp
analyse_param           proc
        push    si
ap_switch:
        call    find_switch
        jc      ap_fin
        lodsb
        call    conv_maj
        cmp     al,'T'
        jne     no_delai_sw
        lodsb
        sub     al,'0'
        cmp     al,9
        ja      ap_err
        mov     ah,18                           ; car il y a 18,2 tics d'horloge /sec.
        mul     ah
        mov     cs:[key_delai],ax
        jmp     ap_switch
no_delai_sw:
        cmp     al,'Q'
        jne     no_qwerty_sw
        mov     cs:[qwerty_clav],1
        jmp     ap_switch
no_qwerty_sw:
        cmp     al,'S'
        jne     ap_err
        mov     cs:[sauve_cfg],1
        jmp     ap_switch
ap_fin:
        pop     si
        ret
ap_err:
        mov     dx,offset sw_err_msg
        push    ds
        push    cs
        pop     ds
        mov     ah,9
        int     21h
        pop     ds
        pop     si
        ret
analyse_param           endp
cherche_fin_config      proc
        push    si
        call    ligne_suiv
cfc_suiv:
        call    ligne_suiv
        cmp     word ptr [si],'$D'
        jne     cfc_suiv
        inc     si
        inc     si
        mov     cs:[fin_config],si
        pop     si
        ret
cherche_fin_config      endp
liste_configuration     proc
        push    si
list_suiv:
        call    ligne_suiv
        lodsb
        cmp     al,'D'                          ; => device
        jne     list_suiv
        lodsb
        cmp     al,'$'                          ; fin ?
        je      fin_list
        cmp     al,'*'
        jne     list_suiv
        lodsb
        mov     dl,al
        mov     ah,2
        int     21h                             ; affiche la lettre
        mov     dl,'-'
        int     21h
        call    affiche_config_name             ; affiche la configuration
        jmp     list_suiv                       ; correspondante
fin_list:
        pop     si
        ret
liste_configuration     endp
lit_ecrit_cfg           proc
        push    ds
        push    cs
        pop     ds
        mov     ah,19h                          ; retourne unité active dans al
        int     21h                             ; (0 -> A,1 -> B)
        add     al,'A'
        mov     bx,offset cfg_file_name
        mov     [bx],al
        mov     dx,offset cfg_file_name
        or      cx,cx
        jne     lit_cfg
        mov     ah,3Ch                          ; création du fichier
        xor     cx,cx                           ; pas d'attribut particulier
        int     21h
        jc      lec_fin
        mov     bx,ax                           ; handle du fichier
                                                ; mov   ah,40h                         ; ecriture
        jmp     lec_exec
lit_cfg:
        mov     ax,3D00h                        ; ouverture
        int     21h
        jc      lec_fin
        mov     bx,ax
        mov     ah,3Fh                          ; lecture
lec_exec:
        mov     dx,offset config                ; depuis la variable config
        mov     cx,1                            ; d'un octet
        int     21h
        mov     ah,3Eh                          ; fermeture
        int     21h
lec_fin:
        pop     ds
        ret
lit_ecrit_cfg           endp
lit_configuration       proc
                                                ;- attente de la pression d'une touche
        mov     ah,0
        int     1Ah                             ; charge dans dx le nombre de tops
attend_touche:                                  ; d'horloge (18,2 par seconde)
        mov     ah,1
        int     16h                             ; teste la présence d'un
                                                ; caractere
        jnz     lit_config_car
        mov     ah,0
        push    ax
        int     1Ah                             ; lit l'heure actuelle
        mov     cx,dx
        pop     ax
        sub     cx,ax
        cmp     cx,cs:[key_delai]               ; le délai s'est-il écoulé ?
        jb      attend_touche
        jmp     config_defaut                   ; config par défaut -> 'A' ou
                                                ; dans autoconf.dat
lit_config_car:
        sub     ah,ah                           ; lit la touche
        int     16h
        cmp     al,13                           ; la touche entrée permet de
                                                ; charger la configuration
        jne     lconf_no_entre                  ; précédente
config_defaut:
        cmp     cs:[sauve_cfg],0                ; lire dans autoconf.dat
        jz      lconf_fin
        mov     cx,1
        call    lit_ecrit_cfg                   ; fonction de lecture
        jmp     lconf_fin
lconf_no_entre:
        cmp     al,' '
        jne     no_config_list                  ; affichage de la liste
        call    liste_configuration             ; des configurations
        jmp     lit_config_car
no_config_list:
        cmp     cs:[qwerty_clav],1              ; utilisation d'un clavier qwerty?
        je      no_convert
        push    ds
        push    si
        call    azerty_convert                  ; non : transformation
                                                ; des caracteres comme Z,A,M...
        pop     si
        pop     ds
no_convert:
        call    conv_maj                        ; convertit en majuscules
        cmp     al,'A'
        jb      lconf_err                       ; ce n'est pas une lettre
        cmp     al,'Z'
        ja      lconf_err
        call    verifie_config                  ; la lettre est-elle valide ?
        jnc     config_ok
                                                ; affiche le message d'erreur
lconf_err:
        mov     dx,offset err_msg
        push    ds
        push    cs
        pop     ds
        mov     ah,9h
        int     21h
        pop     ds
        jmp     lconf_fin
config_ok:
        mov     cs:[config],al                  ; sauve le numéro de
                                                ; configuration
        cmp     cs:[sauve_cfg],0
        je      lconf_fin
        xor     cx,cx                           ; fonction d'écriture
        call    lit_ecrit_cfg                   ; inscrit la configuration sur
                                                ; le disque
lconf_fin:
        ret
lit_configuration       endp
compacte_config         proc
        mov     cs:[dans_config],1              ; tout ce qui suit autoconf est
                                                ; execute jusqu'au
        call    ligne_suiv                      ; premier device=*
        mov     cs:[debut_ligne],si
        mov     cs:[prem_ligne],si
compacte_lsuiv:
        lodsb                                   ; charge le premier octet de la
                                                ; liste :
        cmp     al,'D'                          ; le type de fonction (D = device)
        jne     no_special_cmd
        lodsb                                   ;
        cmp     al,'$'
        jz      fin_compacte                    ; on atteint la fin du config.sys
        cmp     al,'*'
        jne     no_special_cmd
        lodsb                                   ; c'est donc le début
                                                ; d'un nouveau bloc
        mov     cs:[dans_config],0              ; de configuration
        cmp     al,cs:[config]
        jne     no_special_cmd
        mov     cs:[dans_config],1              ; config = 1 si c'est le bon
        call    affiche_config_name             ; affichage du nom de la
                                                ; configuration
        jmp     copie_ligne                     ; on efface cependant la
                                                ; directive device=*
no_special_cmd:
        cmp     cs:[dans_config],0              ; est-ce que l'on garde
                                                ; les commandes
        jne     nomodif                         ; pointées par si ?
copie_ligne:                                    ; non :
        mov     di,cs:[debut_ligne]             ; on recopie la ligne suivante
        call    ligne_suiv                      ; sur la zone pointée par
                                                ; debut_ligne
        mov     cx,cs:[fin_config]
        sub     cx,si
        push    ds
        pop     es
        rep     movsb
        mov     si,cs:[debut_ligne]             ; réinitialise si au début de la
                                                ; ligne
        jmp     compacte_lsuiv
nomodif:                                        ; on est dans la bonne configuration
        call    ligne_suiv
        mov     cs:[debut_ligne],si             ; réactualise debut_ligne
        jmp     compacte_lsuiv
fin_compacte:
        ret
compacte_config         endp
clean_and_move          proc
        mov     si,cs:[debut_ligne]             ; pointe sur la fin des données
raccorde:                                       ; conservées
        dec     si                              ; cherche la fin de la ligne
                                                ; precedente
        cmp     byte ptr [si],10                ; pour supprimer les sauts de ligne
        je      raccorde
        cmp     byte ptr [si],13
        je      raccorde
        mov     di,cs:[fin_config]
        dec     di
        mov     cx,si
        sub     cx,cs:[prem_ligne]              ; déplacement des données
                                                ; conservées du début du
        add     cx,3                            ; config vers la fin
        std                                     ; en inversant la direction
                                                ; (si et di
        rep     movsb                           ; diminuent)
        cld
        mov     cx,cs:[prem_ligne]
        sub     cx,3
cleanall:                                       ; remplissage de la zone
                                                ; inutilisée par des espaces
        mov     byte ptr [di],' '               ; (c'est plus propre
        dec     di                              ; et supprime les sauts de ligne)
        cmp     di,cx
        ja      cleanall
        ret
clean_and_move          endp
azerty_convert          proc
        push    ax
        push    cs
        pop     ds
        mov     si,offset convert_tab
test_suiv:
        lodsb                                   ; charge un scan code
        inc     si
        or      al,al                           ; teste la fin du tableau
        jz      fin_convert
        cmp     ah,al                           ; compare les scan codes
        jne     test_suiv
        dec     si
        lodsb                                   ; charge le code ascii
        inc     sp                              ; pas de pop ax
        inc     sp
        ret
fin_convert:
        pop     ax
        ret
azerty_convert          endp
config                  db      'A'             ; mémorise la configuration demandée (A par défaut)
key_delai               dw      0               ; attente d'un caractere en 18e de sec.
dans_config             db      ?
debut_ligne             dw      ?
prem_ligne              dw      ?
fin_config              dw      ?               ; pointe sur la fin de la config
qwerty_clav             db      0               ; 0 => azerty par défaut
sauve_cfg               db      0               ; 0 => pas de sauvegarde par
                                                ; defaut
convert_tab             db      010h,'A'        ; conversions azerty vers qwerty
                        db      011h,'Z'
                        db      01Eh,'Q'
                        db      02Ch,'W'
                        db      033h,'M'
                        db      0               ; fin du tableau
cfg_file_name           db      'A:\AUTOCONF.DAT',0
err_msg                 db      7,'Erreur : configuration inexistante',13,10,'$'
sw_err_msg              db      7,'autoconf.sys : mauvaises options',13,10,'$'
msg                     db      13,10
                        db      '_________________________________________________________________________',13,10
                        db      '                         AUTOCONF.SYS : configurations multiples',13,10
                        db      '                                1991  S.V.M.',13,10
                        db      '        Appuyez sur espace pour avoir la liste des configurations',13,10
                        db      '_________________________________________________________________________',13,10,'$'
CODE ENDS
END
