.286

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

VIDMEM equ 0b800h	; Video memory address segment

X equ 65		; X coordinate of top left corner
Y equ 2			; Y coordinate of top left corner
SCR_WIDTH equ 80	; Screen width

REG_COUNT equ 6		; Amount of registers to print

FRAME_COLOR equ 0ch	; Frame color
FONT_COLOR equ 0ch	; Text color

;----------------------------------------
; Loads ES with video segment address
;----------------------------------------
; Entry:	None
; Exit:		ES = 0b800h
; Destr:	BX
;----------------------------------------

SetVIDMEM	macro

		_MACROS_

		mov bx, VIDMEM
		mov es, bx

		_MACROS_

		endm

;----------------------------------------


Start:  	xor bx, bx
        	mov es, bx
        	mov bx, 9 * 4

        	cli     ; disable int handle

        	; set int and save previous
        
            	mov ax, es:[bx]
        	mov OldInt9ofs, ax
        	mov es:[bx], offset NewInt9

            	mov ax, es:[bx+2]
        	mov OldInt9seg, ax
        	mov ax, cs
        	mov es:[bx+2], ax

        	sti      ; enable int handle

        	; make program residential

        	mov ax, 3100h
        	mov dx, offset EOP
 		shr dx, 4
        	inc dx
        	int 21h
        

;-----------------------------------------
; Addition to int09 that prints AX to screen
;-----------------------------------------
; Entry:	None
; Exit:		None
; Destr:	None
;-----------------------------------------

NewInt9		proc

		; Save AX
		push ax

		; Read scancode from PPI
		in al, 60h
		cmp al, 29h
		je __CallNewInt

		; Jump to previous int
		pop ax

		db 0eah

OldInt9ofs 	dw 0
OldInt9seg 	dw 0

        	jmp __Finish

		; Confirmation for PPI
__CallNewInt:	in al, 61h
		or al, 80h
		out 61h, al
		and al, not 80h
		out 61h, al

		; Confirmation for INTC
		mov al, 20h
		out 20h, al

		; Restore AX
		pop ax

		; Save stack start before pushing
		push bp
		mov bp, sp

		; Save registers
		push ax bx cx dx si di es

        	SetVIDMEM

		; Print frame
		mov bx, (SCR_WIDTH * (Y - 1) + X - 1) * 2
		mov dl, 7 + 1 * 2
		mov dh, REG_COUNT + 2
		mov ch, FRAME_COLOR
		mov di, offset pattern
		call FramePrt

		; Set some addresses
        	mov bx, (SCR_WIDTH * Y + X) * 2
            	mov si, offset reg_names

		_MACROS_

		rept REG_COUNT	; Print for registers from stack

            	call PrtStr	; Print register name

		mov ax, [bp]

            	call HexPrint	; Print register value

		add bp, 2			; Get next element in stack
		add bx, (SCR_WIDTH - 7) * 2	; To new line

		endm

		_MACROS_

		; Restore registers
		pop es di si dx cx bx ax

		; Restore bp
		pop bp

__Finish:	iret
		endp

;-----------------------------------------

reg_names   	db "ax bx cx dx si di "

;-----------------------------------------
; Prints heximal representation
;-----------------------------------------
; Entry:	AX = Number to print, BX = vidmem offset
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	BX, CX, DI
;-----------------------------------------

HexPrint	proc

		mov cl, 4

__Next:		dec cl

		mov di, ax
		shr di, cl
		and di, 0fh		

		mov ch, cs:hex_code[di]
		mov es:[bx], ch
		mov byte ptr es:[bx+1], FONT_COLOR

		add bx, 2
		
		cmp cl, 0
		jne __Next

		ret
		endp

;-----------------------------------------


;------------------------------------------
; Prints string to screen
;------------------------------------------
; Entry:	SI = str address, BX = vidmem address
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	CX, SI, BX
;------------------------------------------

PrtStr		proc

            	mov ch, 03

__Next:		mov cl, cs:[si]
		mov es:[bx], cl
		mov byte ptr es:[bx+1], FONT_COLOR
		
		add bx, 2
        	inc si
        	dec ch
        	cmp ch, 0
		jne __Next

		ret
		endp

;------------------------------------------


hex_code 	db "0123456789ABCDEF"

;----------------------------------------
; Draws frame row in specific pattern
;----------------------------------------
; Entry:	AH = frst chr, AL = lst chr, BX = vidmem offset, 
;		DH = mdl chr, DL = attr, CX = size
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	CX
;----------------------------------------

RowPrt		proc

		push bx		; Save start pointer

		; Draw first character
		mov es:[bx], AH
		mov es:[bx+1], DL
		
		add BX, 2d
		sub CX, 2d

		; Draw middle characters
__MdlPrt:	mov es:[bx], DH
		mov es:[bx+1], DL

		add BX, 2d

		loop __MdlPrt

		; Draw last character
		mov es:[bx], AL
		mov es:[bx+1], DL

		pop BX		; Restore BX pointer

		ret
		endp

;----------------------------------------

;----------------------------------------
; Draws beautiful frame
;----------------------------------------
; Entry:	BX = vidmem address, DH = Height, DL = Width,
;		DI = pattern address, CH = Frame Color
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr: 	AX, BX, CX, DX, SI
;----------------------------------------

FramePrt	proc           
    
		; si = width
		mov si, dx
		and si, 00ffh

		push dx

		mov dl, ch 	; Set color

		; draw upper row of the frame
		mov cx, si
		mov ah, cs:di[4]
		mov al, cs:di[5]
		mov dh, cs:di[0]

		call RowPrt

		add bx, 80d * 2d

		; draw middle rows of the frame
		mov ah, cs:di[2]
		mov al, cs:di[3]
		mov dh, 20h

		; outer loop as frame height
		pop cx
		shr cx, 8
		sub cx, 2d

__PrtRow:	push cx

		; inner procedure loop param
		mov cx, si

		call RowPrt

		pop cx
		add bx, 80d * 2d

		loop __PrtRow

		; draw lower row of the frame
		mov cx, si
		mov ah, cs:di[6]
		mov al, cs:di[7]
		mov dh, cs:di[1]

		call RowPrt

		ret
		endp

;-----------------------------------------

pattern 	db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h

EOP:

end		Start
