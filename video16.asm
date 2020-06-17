; ------------------------------------------------------------------------------
; Copyright (c) 2020 Jens Kallup - paule32 - non-profit
; all rights reserved.
; for non-commercial use only!
;
; Function: 16-bit video stuff
; Filename: video.asm
; ------------------------------------------------------------------------------
[bits 16]
section .text

global k_setVideoMode_320x200
k_setVideoMode_320x200:
    mov ah, 0x00            ; function 0x00 = mode set
    mov al, 0x13            ; 256-color graphics
    int 0x10                ; video controller

;----------
    call k_drawlinetest
;----------
    
    ret                     ; return to caller

global k_setVideoMode_80x25
k_setVideoMode_80x25:
    mov ah, 0x00            ; function 0x00 = mode set
    mov al, 0x03            ; 16-color text
    int 0x10                ; video controller
    ret                     ; return to caller

global k_plotPixel_16_slow
k_plotPixel_16_slow:
    mov ah, 0x0c            ; function 0x0c = pixel plot
    mov al, [pixel_color]   ; color of pixel
    mov cx, [xpos]          ; x location, from 0..319
    mov dx, [ypos]          ; y location, from 0..199
    int 0x10                ; video controller
    ret                     ; return to caller

; [ ypos * screen_width + x ] = color
global k_plotPixel_fast    
k_plotPixel_fast:
    mov ax, 0xa000          ; video memory
    mov es, ax              ; prepare stage
    mov ax, (190 * 320 + 10)  ; position
    mov di, ax              ; setup pos.
    mov dl, [pixel_color]   ; setup color: yellow
    mov [es:di], dx         ; draw pixel
    int 0x10                ; video controller
    ret

; --------------------------------------------------------------
; change to a vga resolution ...
; --------------------------------------------------------------
; BIOS interrupt 0x13 - AH = 00
; al (hex)  | video mode
; ----------+---------------------------------------------------
;  0        | text 40 x 25 16 grey
;  1        | text 40 x 25 16 color
;  2        | text 80 x 25 16 grey
;  3        | text 80 x 25 16 color
;  4        | graph (CGA) 320 x 200 color
;  5        | graph (CGA) 320 x 200 black / white
;  6        | graph (CGA) 640 x 200 black / white
;  7        | text 80 x 25 black / white (MDA, Hercules)
; ...       | ...
; 0f        | graph (EGA,VGA) 640x350 grey
; 10        | graph (EGA,VGA) 640x350 16 colors
; 11        | graph (VGA) 2 colors
; 12        | graph (VGA) 16 colors
; 13        | graph (VGA) 256 colors

; int 0x10 AX = 0x4f02
;          BX = mode
; BX (hex)  | video mode
; ----------+--------------------------------------------------
; 0x100     | graph  640x400  256-colors
; 0x101     | graph  640x480  256-colors
; 0x102     | graph  800x600   16-colors
; 0x103     | graph  800x600  256-colors
; 0x104     | graph 1024x768   16-colors
; 0x105     | graph 1024x768  256-colors
; 0x106     | graph 1280x1024  16-colors
; 0x107     | graph 1280x1024 256-colors
; 0x108     | text 80x60
; 0x109     | text 132x25
; 0x10a     | text 132x43
; 0x10b     | text 132x50
; 0x10c     | text 132x60

; -------------------------------------------------------------
; write to the video memory ...
;
; +---+---+---+---+---+---+---+---+
; | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
; +---+---+---+---+---+---+---+---+
;                   |   |   |   |
;                   |   |   |    +----- blue
;                   |   |   +---------- green
;                   |   +-------------- red
;                   +------------------ intens.
global k_writeVGA
k_writeVGA:
    mov ax, 012h        ; VGA mode
    int 10h             ; 640 x 480 16 colors.
    mov ax, 0xa000
    mov es, ax          ; ES points to the video memory.
    mov dx, 0x3C4       ; dx = indexregister
    mov ax, 0F02h       ; INDEX = MASK MAP, 
    out dx, ax          ; write all the bitplanes.
    mov di, 0           ; DI pointer in the video memory.
    mov cx, 38400       ; (640 * 480)/8 = 38400
    mov ax, 0FFh        ; write to every pixel.
    rep stosb           ; fill the screen
    ret
    
;------------------------------------------
; Modify the palette of one color.
; BX = color number
; ch = green 
; cl = blue 
; dh = red 
;------------------------------------------
global k_modify_palette
k_modify_palette:
    push ax
    mov bh,0
    mov ax,0x1007
    int 0x10
    mov bl,bh
    mov bh,0
    mov ax,0x1010
    int 0x10
    pop ax
    ret

; -----------------------------------------------
; draw a pixel at x,y location ...
; -----------------------------------------------
i_drawpixel :
    mov es, word [vga_memory]
    mov ax, word [xpos]     ; get x co-ordinate
    mov bx, word [ypos]     ; get y co-ordinate
  
    xor  di, di
    add  di, word [screen_width]
    imul di, bx

    add di, ax              ; set x co-ordinate by increasing index(di) by X value
    mov ax, word[pixel_color]     ; get the color from pixel color memory
    mov [es:di], ax         ; plot the pixel with index(di) and pixel color(ax)
 
    ret

; ----------------------------------------
; test-code for k_drawline ...
; ----------------------------------------
k_drawlinetest:
    mov ax, word [YELLOW]
    mov word [LINE_COLOR], ax
  
    mov dword [X1], 32
    mov dword [Y1], 22
    mov dword [X2], 133
    mov dword [Y2], 100
    call k_drawline
    ret

global k_drawline
k_drawline:
    ; calculate difference of x points
    mov ecx, dword [X2]
    sub ecx, dword [X1]
    mov dword [_DX], ecx

    ; calculate difference of y points
    mov ecx, dword [Y2]
    sub ecx, dword [Y1]
    mov dword [_DY], ecx
	
    ; check if Y1 & Y2 are equal
    mov eax, dword [Y1]
    mov ebx, dword [Y2]
    cmp eax, ebx
    je .y_equals

    ; check if X1 & X2 are equal
    mov eax, dword [X1]
    mov ebx, dword [X2]
    cmp eax, ebx
    je .x_equals
	
    ; check if _DX <= _DY
    mov ecx, dword [_DX]
    cmp ecx, dword [_DY]
    jle .dx_is_less
	
.x_equals:
    ; is X1 & X2 are equal _STEP to _DY
    mov ecx, dword [_DY]
    mov dword [_STEP], ecx
    jmp .done

.y_equals:
.dx_is_less:
    ; if _DX is greater than _DY or Y1 & Y2 are equal then 
    ; set _STEP to _DX
    mov ecx, dword [_DX]
    mov dword [_STEP], ecx
	
.done:
    ; _DX = _DX / _STEP
    xor edx, edx
    mov eax, dword [_DX]
    mov ebx, dword [_STEP]
    div ebx
    mov dword [_DX], eax

    ; _DY = _DY / _STEP
    xor edx, edx
    mov eax, dword [_DY]
    mov ebx, dword [_STEP]
    div ebx
    mov dword [_DY], eax

    ; set co-ordinate _X = X1
    mov eax, dword [X1]
    mov dword [xpos], eax

    ; set co-ordinate _Y = Y1
    mov eax, dword [Y1]
    mov dword [ypos], eax

    ; set counter ecx to _STEP
    mov ecx, 0

.line_loop:
    ; stop when ecx > _STEP
    cmp ecx, dword [_STEP]
    jg .exit
  
    mov eax, dword [xpos]      ; get x co-ordinate
    mov ebx, dword [ypos]      ; get y co-ordinate
  
    ; clear destination index register for use as index in 
    ; video memory pointed by es register
    xor di, di

    add di, word [screen_width]
    imul di, bx

    ; set x co-ordinate by increasing index(di) by X value
    add di, ax

    ; get the color from PIXEL_COLOR memory
    mov ax, word [LINE_COLOR]
  
    ; plot the pixel with index(di) and pixel color(ax)
    mov [es:di], ax

    ; increase _X by _DX
    mov eax, dword [xpos]
    add eax, dword [_DX]
    mov dword [xpos], eax

    ; increase _Y by _DY
    mov eax, dword [ypos]
    add eax, dword [_DY]
    mov dword [ypos], eax

    ; increase _STEP
    inc ecx

    ; and continue loop
    jmp .line_loop 

.exit:
	ret

; ------------------------------------------------------------
section .data
pixel_color:    db 14	; yellow

vga_memory:     dw 0xa000
screen_width:   dw 320
screen_height:  dw 200
num_colors:     db 16

; ----------------------------------  
; 8-bit colors ...
; ----------------------------------
BLACK:          dw 0x00
BLUE:           dw 0x01
GREEN:          dw 0x02
CYAN:           dw 0x03
RED:            dw 0x04
MAGENTA:        dw 0x05
BROWN:          dw 0x06
GRAY:           dw 0x07
DARK_GRAY:      dw 0x08 
BRIGHT_BLUE:    dw 0x09
BRIGHT_GREEN:   dw 0x0a
BRIGHT_CYAN:    dw 0x0b
BRIGHT_RED:     dw 0x0c
BRIGHT_MAGENTA: dw 0x0d 
YELLOW:         dw 0x0e
WHITE           dw 0x0f

LINE_COLOR:     dw 14
  
section .bss
; ------------------------------------------
; line points(x1, y1, x2, y2)
; ------------------------------------------
X1: resd 1
Y1: resd 1
X2: resd 1
Y2: resd 1

; ----------------------------------------------------------
; line co-ordinates (difference in points and its slope)
; ----------------------------------------------------------
_DX:    resd 1
_DY:    resd 1
_STEP:  resd 1


section .data
xpos:           dd 0
ypos:           dd 0

