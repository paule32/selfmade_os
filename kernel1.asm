; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: kernel boot from sector 0 of disk
; Filename: kernel1.asm
;
; Compile:  $ nasm kernel1.asm -f bin -o kernel1.bin
; ------------------------------------------------------------------------------
BITS 16
    mov ax, 0x07c0		; data transfer from boot-medium to addr: 0x7c00
    mov ds, ax			; load data segment
    mov es, ax

    pusha
    mov ah, 0x00		; text mode 80x25 16 colors
    mov al, 0x03		; set/clear screen
    int 0x10			; video port interrupt call
    popa

    mov si, welcome
    call print_string

loop:
    mov si, prompt		; set string addr. "prompt" into si register
    call print_string		; display/print string

    mov di, buffer
    call get_string

    mov si, buffer
    cmp byte [si], 0		; blank line ?
    je loop			; yes, ignore it

    mov si, buffer
    mov di, cmd_hi		; "hi" command
    call strcmp
    jc .helloworld

    mov si, buffer
    mov di, cmd_help		; "help" command
    call strcmp
    jc .help

    mov si, msg_badcommand
    call print_string
    jmp loop

.helloworld:
    mov si, msg_helloworld
    call print_string
    jmp loop

.help:
    mov si, msg_help
    call print_string
    jmp loop

print_string:
    lodsb			; grab a byte from si register

    or al, al			; logical or al register by itself
    jz .done			; if the result is zero, get out

    mov ah, 0x0e		; print out the character
    int 0x10			; video port

    jmp print_string		; next byte from si register

.done:
    ret				; return to caller

strcmp:
.loop:
    mov al, [si]		; grab a byte from si register
    mov bl, [di]		; grab a byte from di
    cmp al, bl			; are they equal?
    jne .notequal		; nope, we are done

    cmp al, 0			; are both bytes (they were equal before) null?
    je .done			; yes, we are done

    inc di			; increment di, next byte
    inc si			; increment si, next byte
    jmp .loop			; next byte, .loop again!

.notequal:
    clc				; not equal, clear the carry flag
    ret

.done:
    stc				; equal, set the carry flag
    ret

get_string:
    xor cl, cl

.loop:
    mov ah, 0
    int 0x16			; wait for keypress

    cmp al, 0x08		; backspace pressed?
    je .backspace		; yes, handle it

    cmp al, 0x0d		; enter pressed?
    je .done			; yes, we are done

    cmp cl, 63			; 63 chars inputted?
    je .loop			; yes, only let in backspace and enter

    mov ah, 0x0e
    int 0x10			; print out character

    stosb			; put character in buffer
    inc cl			; increase byte
    jmp .loop

.backspace:
    cmp cl, 0			; beginning of string?
    je .loop			; yes, ignore the key

    dec di
    mov byte [di], 0		; delete character
    dec cl			; decrement counter as well

    mov ah, 0x0e
    mov al, 0x08
    int 0x10			; backspace on the screen

    mov al, ' '
    int 0x10			; puts blank character out

    mov al, 0x08
    int 0x10			; backspace again

    jmp .loop			; go to the main loop

.done:
    mov al, 0			; null terminator
    stosb			; store single byte

    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a		; newline
    int 0x10
    ret

welcome:		db "Welcome to My OS! (c) 2020 Jens Kallup - paule32", 0x0d, 0x0a, 0
msg_helloworld: 	db "Hello from PC!",		0x0d, 0x0a, 0
msg_badcommand: 	db "Bad command entered.",	0x0d, 0x0a, 0
msg_help:		db "MyOS commands: hi, help",   0x0d, 0x0a, 0
cmd_help:		db "help",	0
cmd_hi: 		db "hi",	0
prompt: 		db "ram://",	0

buffer: times 64 db 0
	times 510 - ($ - $$) db 0

db 0x55 	; end of boot sector
db 0xaa 	; ...
