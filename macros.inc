; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: macro stuff, to reduce write space/time
; Filename: macro,inc
; ------------------------------------------------------------------------------
[BITS 16]

%define save_all_registers    pusha
%define restore_all_registers popa

%define pc_reboot jmp 0xffff:0x0000

; implements the print_string call
%macro write_string 2
    mov si, %1
    call print_string
    jmp %2
%endmacro

; setup segments
%macro setup_segments 0
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov sp, ax
%endmacro

%macro get_command 2
    mov si, sp
    mov di, %1      ; command
    call strcmp     ; compare
    je      %2      ; equal? -> jump dst
%endmacro

%macro set_input_flag 1
    call set_input_flag_%1
%endmacro

;; wait for any key stroke ...
%macro get_any_key 0
    xor ax, ax
    int 0x16
%endmacro

