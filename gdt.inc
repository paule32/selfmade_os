; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: gdt - global descriptor table
; Filename: gdt.asm
; ------------------------------------------------------------------------------
[BITS 16]

NULL_Desc:
    dd 0
    dd 0

CODE_Desc:
    dw 0xffff		; segment length  bits 0-15 ("limit")
    dw 0		; segment base    byte 0,1
    db 0		; segment base    byte 2
    db 10011010b	; access rights
    db 11001111b	; bit 7-4: 4 flag bits: granularity, default operator size bit,
			; 2 bits available for OS
			; bit 3-0: segment length bits 16-19
    db 0		; segment base    byte 3

DATA_Desc:
    dw 0xffff		; segment length: bits 0-15
    dw 0		; segment base:   byte 0,1
    db 0		; segment base:   byte 2
    db 10010010b	; 
    db 11001111b	;
    db 0		; segment base   byte 3

gdtr:
Limit:  dw 24		; length of GDT
Base:	dd NULL_Desc	; base of GDT (linear address: RM Offset + Seg << 4 )
