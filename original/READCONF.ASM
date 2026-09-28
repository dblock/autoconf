; Transcribed from Science & Vie Micro no. 88 (November 1991), pp. 227-233.
; Original program by Julien Pommier. OCR-derived transcription; consult the PDF scan.

CODE SEGMENT
ASSUME CS:CODE
ORG 100H
start:
        sub     ax,ax
        mov     ds,ax
        mov     al,ds:[byte ptr 0FAh*4]
        mov     ah,4Ch
        int     21h
CODE ENDS
END START
