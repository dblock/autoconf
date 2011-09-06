code segment
        assume cs:code
        org 100h

        start:
                xor ax,ax
                mov ah,0Ch
                int 21h
                mov ah,4Ch
                int 21h
code ends
end start

