; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: bootloader
; Filename: bootloader.asm
; ------------------------------------------------------------------------------
BITS 16
    org 0x7c00			; set up start address

    ; setup a stack
    mov ax, 0x9000		; address of the stack ss:sp
    mov ss, ax			; ss = 0x9000 (stack segment)
    xor sp, sp			; sp = 0x0000 (stack pointer)

    mov [bootdrive], dl 	; boot drive form dl
    call load_kernel		; load kernel

    ; clear/reset screen
    pusha
    mov ah, 0x00		; text mode 80x25 16 colors
    mov al, 0x03		; set/clear screen
    int 0x10			; video port interrupt call
    popa

    ; show loading message
    mov si, msg_welcome
    call print_string
    ;
    mov si, msg_load
    call print_string

    ; jump to kernel
    jmp 0x1000:0x0000		; address of kernel

print_string:
    lodsb			; grab a byte from si register

    or al, al			; logical or al register by itself
    jz .done			; if the result is zero, get out

    mov ah, 0x0e		; print out the character
    int 0x10			; video port

    jmp print_string		; next byte from si register

.done:
    ret				; return to caller

load_kernel:
    mov dl, [bootdrive] 	; select boot drive
    xor ax, ax  		; mox ax, 0 => function "reset"
    int 0x13
    jc load_kernel		; trouble? try again

load_kernel1:
    mov ax, 0x1000
    mov es, ax			; es:bx = 0x10000
    xor bx, bx			; mov bx, 0

    ; set parameter for reading function
    ; 8-Bit-wise for better overview
    mov dl, [bootdrive]		; select boot drive
    mov al, 10			; read 10 sectors
    mov ch, 0			; cylinder = 0
    mov cl, 2			; sector   = 2
    mov dh, 0			; head     = 0
    mov ah, 2			; function "read"
    int 0x13			; bios interrupt call
    jc load_kernel1		; trouble? try again

    ret

bootdrive:	db 0
msg_welcome:    db "Welcome to My OS! (c) 2020 Jens Kallup - paule32", 0x0d, 0x0a, 0
msg_load:	db "loading kernel ...", 0x0d, 0x0a, 0

times 510-($ - $$) hlt

; boot sector signature
db 0x55 	; end of boot sector
db 0xaa 	; ...
