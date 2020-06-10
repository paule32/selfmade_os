; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: bootloader
; Filename: bootloader.asm
; ------------------------------------------------------------------------------
[bits 16]
    org 0x7c00			; set up start address

    ; setup a stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax

    ; read kernel from disk
    mov [bootdrive], dl

    ; clear/reset screen
;    pusha
;    mov ah, 0x00                ; text mode 80x25 16 colors
;    mov al, 0x03                ; set/clear screen
;    int 0x10                    ; video port interrupt call
;    popa

load_kernel:
    xor ax, ax			; mov ax, 0  => function "reset"
    int 0x13
    jc load_kernel		; trouble? try again

    mov bx, (0x7c00 + 512)

    ; set parameters for reading function
    ; 8-Bit-wise for better overview
    mov dl, [bootdrive]	; select boot drive
    mov al, 10			; read 10 sectors
    mov ch, 0			; cylinder = 0
    mov cl, 2			; sector   = 2
    mov dh, 0			; head     = 0
    mov ah, 2			; function "read"
    int 0x13			; bios interrupt call
    jc load_kernel		; trouble? try again

    mov si, msg_welcome
    call print_string

    mov si, msg_load
    call print_string

    ; jump to kernel
    jmp bx

print_string:
    mov ah, 0x0e
.loop:
    lodsb		; grab a byte from si
    test al, al 	; null?
    jz .done		; if result is zero, get out
    int 0x10		; otherwise, print out the char.
    jmp .loop
.done:
    ret

; data
bootdrive:      db 0
msg_welcome:    db "Welcome to My OS! (c) 2020 Jens Kallup - paule32", 13,10, 0
msg_load:       db "loading kernel ...", 13,10, 0

times 510-($ - $$) nop

; boot sector signature
db 0x55 	; end of boot sector
db 0xaa 	; ...
