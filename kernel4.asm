; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: kernel boot - c kernel
; Filename: kernel4.asm
; ------------------------------------------------------------------------------
[BITS 16]
;   org 0x8000		; code start address

%include 'macros.inc'

extern k_setVideoMode_320x200   ; video16.asm
extern k_plotPixel_fast         ; video16.asm
extern k_setVideoMode_80x25     ; video16.asm
extern k_drawline

section .text
    jmp RealMode

section .data
shutdown_cmd equ 0xfe   ; shutdown cmd for kbc

resetidtr:  dw 0x0400 - 1 ; limit portion
hose_idtr:  dd 0,0,0      ; hosed value & base address for idtr

section .text
global RealMode
RealMode:
    setup_segments

    call set_input_flag_0

    add sp, -0x40		        ; make room for input buffer (64 chars)
    write_string msg_welcome2, loop_start

loop_start:
    set_input_flag 1
    write_string prompt, next    ; show prompt
next:
    set_input_flag 0

    mov di, sp			    ; get input
    call get_string
    jcxz loop_start		    ; blank line? -> yes, ignore it

    get_command cmd_hi   ,  .helloworld
    get_command cmd_help ,  .help
    get_command cmd_exit ,  .exit
    get_command cmd_video,  .video
    get_command cmd_pm   ,  .pm

               write_string msg_badcommand,  loop_start		; unknow command
.helloworld:   write_string msg_helloworld,  loop_start
.help:         write_string msg_help      ,  loop_start

.video:
    save_all_registers
    call k_setVideoMode_320x200
    call k_plotPixel_fast
    call k_drawline

    get_any_key    
    
    call k_setVideoMode_80x25
    restore_all_registers
    jmp RealMode
    
.exit:
    write_string msg_exit, $
    get_any_key
    pc_reboot

.pm:
    call clrscr
    write_string msg_pm, $
    call Waitingloop

    cli				; clear interrupts

    lgdt [gdtr]			; load gdt via gdtr (see file: gtd.asm)

; we actually only need to do this ONCE, but for now it doesn't hurt to do this more often when
; switching between RM and PM
    in al, 0x92 		; switch A20 gate via fast A20 port 92
    cmp al, 0xff		; if it reads 0xff, nothing's implemented on this port
    je .no_fast_A20

    or al, 2			; set A20 gate bit (bit: 1)
    and al, ~1			; clear init_now bit (don't reset pc ,,,)
    out 0x92, al
    jmp .A20_done

.no_fast_A20:			; no fast shortcut -> use the slow kbc ...
    call empty_8042

    mov al, 0xd1		; kbc command: write to output port
    out 0x64, al
    call empty_8042

    mov al, 0xdf		; writing this to kbc output port enables A20
    out 0x60, al
    call empty_8042

.A20_done:
    mov eax, cr0		; switch over to protected mode
    or al, 1			; set bit 0 of cr0 register
    mov cr0, eax		;

    jmp 0x8:ProtectedMode	; http://www.nasm.us/doc/nasmdo10.html#section-10.1

empty_8042:
    call Waitingloop
    in al, 0x64
    cmp al, 0xff		; .. no real kbc at all?
    je .done 

    test al, 1			; something in input buffer
    jz .no_output
    call Waitingloop
    in al, 0x60			; yes, read buffer
    jmp empty_8042		; and try again

.no_output:
    test al, 2			; command buffer empty?
    jnz empty_8042		; no, we can't send anything new till it's empty
.done:
    ret

set_input_flag_0:
    mov al, byte 0
    mov byte [input_flag], al
    ret
set_input_flag_1:
    mov al, byte 1
    mov byte [input_flag], al
    ret

print_string:
    mov ah, 0x0e
.loop_start:
    lodsb			; grab a byte from si
    test al, al			; test al
    jz .done			; if the result is zero, get out
    int 0x10
    jmp .loop_start
.done:
    mov al, byte [input_flag]
    cmp al, byte 1
    je .donedone

    sti
    mov ah, 0x0e
    mov al, 5
    add al, 5
    add al, 3
    int 0x10
    sub al, 3
    int 0x10

.donedone:
    ret

get_string:
    xor cx, cx
.loop_start:
    xor ax, ax
    int 0x16			; wait for keypress
    cmp al, 8			; backspace pressed?
    je .backspace		; yes, handle it
    cmp al, 13			; enter pressed?
    je .done			; yes, we are done
    cmp cl, 63			; 63 chars inputted?
    je .loop_start		; yes, only let in backspace and enter
    mov ah, 0x0e		;
    int 0x10			; print character
    stosb			; put char in buffer
    inc cx
    jmp .loop_start

.backspace:
    jcxz .loop_start		; zero? (start of the string) if yes, ignore the key
    dec di
    mov byte [di], 0		; delete char
    dec cx			; decrement counter as well
    mov ah, 0x0e
    int 0x10			; backspace on the screen
    mov al, ' '			;
    int 0x10			; blank char out
    mov al, 8
    int 0x10			; backspace again
    jmp .loop_start		; go to the main loop

.done:
    mov byte [di], 0		; null terminate
    mov ax, 0x0e0d
    int 0x10
    mov al, 0x0a
    int 0x10			; new line
    ret

strcmp:
.loop_start:
    mov al, [si]		; grab a byte from si register
    cmp al, [di]		; are si and di equal?
    jne .done			; no, we are done

    test al, al			; zero?
    jz .done			; yes, we are done

    inc di			; increment di
    inc si			; increment si
    jmp .loop_start		; loop!

.done:
    ret

clrscr:
    mov ax, 0x0600
    xor cx, cx
    mov dx, 0x174f
    mov bh, 0x07
    int 0x10
    ret

; --------------------------------------------
; protected mode ...
; --------------------------------------------
[bits 32]
;extern RealEntry	; this is in the C file
ProtectedMode:
    mov ax, 0x10
    mov ds, ax			; data descriptor
    mov ss, ax
    mov es, ax
    xor eax, eax
    mov fs, ax
    mov gs, ax
    mov esp, 0x200000		; set stack below 2 MB limit

    call clrscr_32
    mov ah,  0x01
.endlessloop:
    call Waitingloop
    inc ah
    and ah, 0x0f
    mov esi, msg_pm2   ; 'OS currently uses Protected Mode.'
    call PutStr_32
    cmp dword [PutStr_Ptr], 25 * 80 * 2 + 0xB8000
    jb .endlessloop
    mov dword [PutStr_Ptr], 0xB8000  ; text pointer wrap-arround

;    call RealEntry  ; ->-> C-kernel
    jmp $

Waitingloop:
    mov ebx, 0x9ffff
.loop_start:
    dec ebx
    jnz .loop_start
    ret

PutStr_32:     
    mov edi, [PutStr_Ptr]
.nextchar:
    lodsb
    test al, al         
    jz .end     
    stosw
    jmp .nextchar 
  .end:
    mov [PutStr_Ptr], edi
    ret

clrscr_32:
    mov edi, 0xb8000
    mov [PutStr_Ptr], edi
    mov ecx, 40 * 25
    mov eax, 0x07200720 ; two times: 0x07 => white text & black background 0x20 => Space
    rep stosd
    ret

section .data
PutStr_Ptr dd 0xb8000

msg_welcome2:	db "kernel loaded, ready for input.",   0
msg_helloworld: db "Hello from PC!",			0
msg_badcommand: db "Bad command entered.",		0

prompt: 	db "ram://",0

cmd_help:	db "help",	0
cmd_hi: 	db "hi",	0
cmd_exit:	db "exit",  0
cmd_video:  db "video", 0
cmd_pm: 	db "pm",    0

msg_help:	db "Commands: hi, help, video, pm, exit",		0
msg_exit:	db "Reboot starts now. Enter keystroke, please.",	0
msg_pm: 	db "Switch-over to Protected Mode.",			0
msg_pm2:	db "OS currently uses Protected Mode.", 		0

idt_real:   dw 0x3ff    ; 256 entries; each 4b = 1K
            dd 0        ; Real Mode 
savecr0:    dd 0

input_flag:	db 0

%include "gdt.inc"

