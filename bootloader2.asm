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
    mov sp, 0x7c00      ; set stack ptr to 0x7c09
    mov si, sp          ; si now 0x7c00
    
    mov [bootdrive], dl
    mov bx, ( 0x7c00 + 512 )

    push ax
    pop  es             ; es now 0000:7c00
    push ax
    pop  ds             ; ds now 0000:7c00
 
    sti                 ; allow int's

    ; clear/reset screen
    pusha
    mov ah, 0x00                ; text mode 80x25 16 colors
    mov al, 0x03                ; set/clear screen
    int 0x10                    ; video port interrupt call
    popa

    mov di, boot_sector_signature       ; point to signature
    cmp word [di], 0xaa55               ; is it correct ?
    jnz boot_error

; read kernel from disk
load_kernel:
    xor ax, ax			; mov ax, 0  => function "reset"
    int 0x13
    jc load_kernel		; trouble? try again

    ; set parameters for reading function
    ; 8-Bit-wise for better overview
    mov dl, [bootdrive]	; select boot drive
    mov al, 5			; read 5 sectors
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

    ; jump to boot stage 2 ...
;   mov bx, ( 0x7c00 + 512 )
    jmp bx

    hlt
    jmp $

boot_error:
    mov si, msg_boot_error
    call print_string
    hlt
    jmp $                   ; for ever - reset

print_string:
    mov ah, 0x0e
.loop:
    lodsb		; grab a byte from si
    test al, al 	; null?
    jz .done		; if result is zero, get out
    int 0x10		; otherwise, print out the char.
    jmp .loop
.done:
    mov ah, 0x0e
    mov al, 5
    add al, 5
    add al, 3
    int 0x10
    sub al, 3
    int 0x10
    ret

; data
bootdrive:      db 0
msg_welcome:    db "Welcome to My OS! (c) 2020 Jens Kallup - paule32", 0
msg_load:       db "loading kernel ...", 0
msg_boot_error: db "invalid boot signature!", 0
msg_team:       db "TEAM: #amiga-dresden.de", 0

times 510-($ - $$) hlt

boot_sector_signature:
db 0x55 	; end of boot sector
db 0xaa 	; ...
