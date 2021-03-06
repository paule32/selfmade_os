; Decompresses Y. Collet's LZ4 compressed stream data in 16-bit real mode.
; Optimized for 8088/8086 CPUs.
;
; Code by Trixter/Hornet (trixter@oldskool.org) on 2013-01-05
; Updated 2019-06-17 -- thanks to Peter Ferrie, Terje Mathsen,
; and Axel Kern for suggestions and improvements!
;
; Updated 2019-06-30: Fixed an alignment bug in lz4_decompress_small
; Updated 2020-03-14: Speed updates: Pavel Zagrebin
; Updated 2020-06-12: Convert to nasm (linux): Jens Kallup - paule32

[bits 16]
; this is the start point; behind the boot mbr/sector 1

section .text
global RealMode
RealMode:
    ; setup a stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax
    
    xor ax, ax
    int 0x16
    
;   decompsize := lz4_decompress(inbuf,outbuf);
    
    mov ax, end_of_lz4              ; 0x7c00 + 512 + image size; sector 2
    mov word [lzmaBuffer_src], ax   ; decompress kernel (behind mbr)
    mov word [ds:si], ax            ; encoded image memory location
    mov word [lzmaBuffer_dst], ax   ; ...
    
    call lz4_decompress_small       ; decompress data

; this part
push ax
    mov ax, 3
    int 0x10
pop ax
; is execute fine


; but he here, i don't know ...
    mov ax, [es:di]
    jmp ax                          ; jump to start application
    hlt                             ; should be never reached
    
;---------------------------------------------------------------
; function lz4_decompress(inb,outb:pointer):word;
;
; Decompresses an LZ4 stream file with a compressed chunk 64K or less in size.
; Input:
;   DS:SI Location of source data.  DWORD magic header and DWORD chunk size
;         must be intact; it is best to load the entire LZ4 file into this
;         location before calling this code.
;
; Output:
;   ES:DI Decompressed data.  If using an entire 64K segment, decompression
;         is "safe" because overruns will wrap around the segment.
;   AX    Size of decompressed data.
;
; Trashes AX, BX, CX, DX, SI, DI
;         ...so preserve what you need before calling this code.
;---------------------------------------------------------------
; function lz4_decompress_small(inb,outb:pointer):word; assembler;
;
; Same as LZ4_Decompress but optimized for size, not speed. Still pretty fast,
; although roughly 30% slower than lz4_decompress and RLE sequences are not
; optimally handled.  Same Input, Output, and Trashes as lz4_decompress.
; Minus the Turbo Pascal preamble/postamble, assembles to 78 bytes.
;---------------------------------------------------------------
lz4_decompress_small:
        push    ds              ;preserve compiler assumptions
        les     di, [lzmaBuffer_dst]       ;load target buffer
        lds     si, [lzmaBuffer_src]       ;load source buffer
        cld                     ;make strings copy forward
        lodsw
        lodsw                   ;skip magic number, smaller than "add si,4"
        lodsw                   ;load chunk size low 16-bit word
        xchg    bx,ax           ;BX = size of compressed chunk
        add     bx,si           ;BX = threshold to stop decompression
        lodsw                   ;load chunk size high 16-bit word
        or      ax,ax           ;is high word non-zero?
        jnz     @@done          ;If so, chunk too big or malformed, abort
@@parsetoken:                   ;CX=0 here because of REP at end of loop
        lodsb                   ;grab token to AL
        mov     dx,ax           ;preserve packed token in DX
@@copyliterals:
        mov     cx,4            ;set full CX reg to ensure CH is 0
        shr     al,cl           ;unpack upper 4 bits
        call    buildfullcount  ;build full literal count if necessary
@@doliteralcopy:                  ;src and dst might overlap so do this by bytes
        rep     movsb           ;if cx=0 nothing happens

;At this point, we might be done; all LZ4 data ends with five literals and the
;offset token is ignored.  If we're at the end of our compressed chunk, stop.

        cmp     si,bx           ;are we at the end of our compressed chunk?
        jae     @@done          ;if so, jump to exit; otherwise, process match
@@copymatches:
        lodsw                   ;AX = match offset
        xchg    dx,ax           ;AX = packed token, DX = match offset
        and     al,0Fh          ;unpack match length token
        call    buildfullcount  ;build full match count if necessary
@@domatchcopy:
        push    ds
        push    si              ;ds:si saved, xchg with ax would destroy ah
        mov     si,di
        sub     si,dx
        push    es
        pop     ds              ;ds:si points at match; es:di points at dest
        add     cx,4            ;minmatch = 4
                                ;Can't use MOVSWx2 because [es:di+1] is unknown
        rep     movsb           ;copy match run if any left
        pop     si
        pop     ds              ;ds:si restored
        jmp     @@parsetoken

buildfullcount:
                                ;CH has to be 0 here to ensure AH remains 0
        cmp     al,0Fh          ;test if unpacked literal length token is 15?
        xchg    cx,ax           ;CX = unpacked literal length token; flags unchanged
        jne     builddone       ;if AL was not 15, we have nothing to build
buildloop:
        lodsb                   ;load a byte
        add     cx,ax           ;add it to the full count
        cmp     al,0FFh         ;was it FF?
        je      buildloop       ;if so, keep going
builddone:
        retn

@@done:
        sub     di,word [lzmaBuffer_dst] ; subtract original offset from where we are now
        xchg    ax,di           ;AX = decompressed size
        pop     ds              ;restore compiler assumptions
        ret


section .data
 lzmaBuffer_src: dw 0   ; decode: source of buffer pointer
 lzmaBuffer_dst: dw 0   ; decode: destination

section .text
end_of_lz4:
