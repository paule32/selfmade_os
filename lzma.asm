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
    
    mov ax, end_of_lz4              ; 0x7c00 + 512 + image size; sector 2
    mov word [lzmaBuffer_src], ax   ; decompress kernel (behind mbr)
    mov word [ds:si], ax            ; encoded image memory location
    mov word [lzmaBuffer_dst], ax   ; ...
    
    call lz4_decompress             ; decompress data

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
;Pavel Zagrebin is credited with the following speedups:
; Changing the end-of-file comparison to self-modifying offset
; push ds;pop ds->mov ds,bp
; adc cx,cx;rep movsb->jnc
; NOTE:  I can't explain it, but with no extraneous background interrupts,
; timings are taking longer than normal on my IBM 5160.  So, we have to
; reset our timing numbers here:
; Old timings:          shuttle  85038 text 45720 robotron 307796 ---
; After Pavel's speedups:
; New timings:          shuttle  81982 text 43664 robotron 296081 +++
; ---------------------------------------------------------------------------

section .text
global lz4_decompress
lz4_decompress:
        push    ds                  ;preserve compiler assumptions
        les     di,[lzmaBuffer_dst]  ;load target buffer
        push    di              ;save original starting offset (in case != 0)
        lds     si,[lzmaBuffer_src]  ;load source buffer
        add     si,4            ;skip magic number
        cld                     ;make strings copy forward
        
;        mov     bx, SHR4table     ;prepare BX for XLAT later on
;        lodsw                   ;load chunk size low 16-bit word
;        mov     bp,ax           ;BP = size of compressed chunk
;        lodsw                   ;load chunk size high 16-bit word

        add     bp,si           ;BP = threshold to stop decompression
        or      ax,ax           ;is high word non-zero?
        jnz     done          ;If so, chunk too big or malformed, abort

starttoken:
        lodsb                   ;grab token to AL
        mov     dx,ax           ;preserve packed token in DX
;        cs   xlat            ;unpack upper 4 bits, faster than SHR reg,cl
    mov cl, 4
    shr al, cl
        mov     cx,ax           ;CX = unpacked literal length token
        jcxz    copymatches   ;if CX = 0, no literals; try matches
        cmp     al,0Fh          ;is it 15?
        jne     doliteralcopy1  ;if so, build full length, else start copying
build1stcount:                  ;this first count build is not the same
        lodsb                   ;fall-through jump as the one in the main loop
        add     cx,ax           ;because it is more likely that the very first
        cmp     al,0FFh         ;length is 15 or more
        je      build1stcount
doliteralcopy1:
        rep     movsb           ;src and dst might overlap so do this by bytes

;At this point, we might be done; all LZ4 data ends with five literals and the
;offset token is ignored.  If we're at the end of our compressed chunk, stop.

        cmp     si,bp           ;are we at the end of our compressed chunk?
        mov     word [cs:end_of_chunk+2],bp
                                ;self-modifying cmp si,xxxx
        mov     bp,ds           ;now we can use bp for restoring ds
        jae     done          ;if so, jump to exit; otherwise, process match

copymatches:
        lodsw                   ;AX = match offset
        xchg    dx,ax           ;AX = packed token, DX = match offset
        and     al,0Fh          ;unpack match length token
        cmp     al,0Fh          ;is it 15?
        xchg    cx,ax           ;(doesn't affect flags); don't need ax any more
        je      buildmcount     ;if not, start copying, otherwise build count

domatchcopy:
        cmp     dx,2            ;if match offset=1 or 2, we're repeating a value
        jbe     domatchfill     ;if so, perform RLE expansion optimally
        xchg    si,ax           ;ds:si saved
        mov     si,di
        sub     si,dx
        mov     dx,es
        mov     ds,dx           ;ds:si points at match; es:di points at dest
        movsw                   ;minimum match is 4 bytes; move them ourselves
        shr     cx,1
        jnc     even
        movsb
even:
        movsw
		rep     movsw           ;cx contains count-4 so copy the rest
        xchg    si,ax
        mov     ds,bp

parsetoken:                   ;CX always 0 here because of REP
        xchg    cx,ax           ;zero ah here to benefit other reg loads
        lodsb                   ;grab token to AL
        mov     dx,ax           ;preserve packed token in DX
copyliterals:                 ;next 5 lines are 8088-optimal, do not rearrange
;        cs xlat            ;unpack upper 4 bits, faster than SHR reg,cl
    mov cl, 4
    shr al, cl

        mov     cx,ax           ;CX = unpacked literal length token
        jcxz    copymatches   ;if CX = 0, no literals; try matches
        cmp     al,0Fh          ;is it 15?
        je      buildlcount     ;if so, build full length, else start copying
doliteralcopy:                ;src and dst might overlap so do this by bytes
        rep     movsb           ;if cx=0 nothing happens

;At this point, we might be done; all LZ4 data ends with five literals and the
;offset token is ignored.  If we're at the end of our compressed chunk, stop.

testformore:
end_of_chunk:
		cmp     si,256          ;this constant is patched with the end address
        jb      copymatches   ;if not, keep going
        jmp     done          ;if so, end

domatchfill:
        je      domatchfill2    ;if DX=2, RLE by word, else by byte
domatchfill1:
        mov     al,[es:di-1]    ;load byte we are filling with
        mov     ah,al           ;copy to ah so we can do 16-bit fills
        stosw                   ;minimum match is 4 bytes, so we fill four
        stosw
        inc     cx              ;round up for the shift
        shr     cx,1            ;CX = remaining (count+1)/2
        rep     stosw           ;includes odd byte - ok because LZ4 never ends with matches
        adc     di,-1           ;Adjust dest unless original count was even
        jmp     parsetoken    ;continue decompressing

domatchfill2:
        mov     ax,[es:di-2]    ;load word we are filling with
        stosw                   ;minimum match is 4 bytes, so we fill four
        stosw
        inc     cx              ;round up for the shift
        shr     cx,1            ;CX = remaining (count+1)/2
        rep     stosw           ;includes odd byte - ok because LZ4 never ends with matches
        adc     di,-1           ;Adjust dest unless original count was even
        jmp     parsetoken    ;continue decompressing

buildlcount:                    ;build full literal length count
        lodsb                   ;get next literal count byte
        add     cx,ax           ;increase count
        cmp     al,0FFh         ;more count bytes to read?
        je      buildlcount
        jmp     doliteralcopy

buildmcount:                    ;build full match length count - AX is 0
        lodsb                   ;get next literal count byte
        add     cx,ax           ;increase count
        cmp     al,0FFh         ;more count bytes to read?
        je      buildmcount
        jmp     domatchcopy

done:
        pop     ax              ;retrieve previous starting offset
        sub     di,ax           ;subtract prev offset from where we are now
        xchg    ax,di           ;AX = decompressed size
        pop     ds              ;restore compiler assumptions
        ret

section .data
 lzmaBuffer_src: dw 0   ; decode: source of buffer pointer
 lzmaBuffer_dst: dw 0   ; decode: destination

section .text
end_of_lz4:
