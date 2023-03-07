.286

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

VIDMEM equ 0b800h	; Video memory address segment

X equ 65		; X coordinate of top left corner
Y equ 2			; Y coordinate of top left corner
SCREEN_W equ 80		; Screen width

REG_CNT equ 13		; Amount of registers to print

FRAME_COLOR equ 0ch	; Frame color
FONT_COLOR equ 30h	; Text color

FRAME_W equ 7		; Frame width
FRAME_H equ REG_CNT	; Frame height

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
        	mov bx, 8 * 4

        	cli     ; disable int handle

        	; set int8 and save previous
            	mov ax, es:[bx]
        	mov OldInt8ofs, ax
        	mov es:[bx], offset NewInt8

            	mov ax, es:[bx+2]
        	mov OldInt8seg, ax
        	mov ax, cs
        	mov es:[bx+2], ax

		; set int9 and save previous
		mov ax, es:[bx+4]
        	mov OldInt9ofs, ax
        	mov es:[bx+4], offset NewInt9

            	mov ax, es:[bx+6]
        	mov OldInt9seg, ax
        	mov ax, cs
        	mov es:[bx+6], ax

        	sti      ; enable int handle

        	; make program residential
        	mov ax, 3100h
        	mov dx, offset EOP
 		shr dx, 4
        	inc dx
        	int 21h
        

;-----------------------------------------
; Keyboard interrupt that enables/disables registers print if '~' pressed
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

		; Change RegPrtOn to opposite value
		not cs:[RegPrtOn]

		; Check if print disables
		cmp cs:[RegPrtOn], 0
		jne __Skip

		; Save registers
		push cx si di es

		; Restore vidmem on disabling
		SetVIDMEM
		mov si, (SCREEN_W * Y + X) * 2
		mov di, offset SaveBuf
		call LoadVidMem

		; Restore registers
		pop es di si cx

		; Restore AX
__Skip:		pop ax

__Finish:	iret
		endp

;-----------------------------------------


;-----------------------------------------
; Checks differences between VidMem and DrawBuf and write them in SaveBuf
;-----------------------------------------
; Entry:	SI = vidmem offset
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	AX, CX, SI, DI
;-----------------------------------------

SaveBufUpdate	proc

		xor di, di
		mov ch, FRAME_H
		mov cl, FRAME_W * 2

__Next:		mov ah, es:[si]

		cmp cs:DrawBuf[di], ah
		je __Skip

		mov cs:SaveBuf[di], ah

__Skip:		inc si
		inc di

		dec cl
		cmp cl, 0
		jne __Next

		add si, (SCREEN_W - FRAME_W) * 2
		mov cl, FRAME_W * 2

		dec ch
		cmp ch, 0
		jne __Next

		ret
		endp

;-----------------------------------------


;-----------------------------------------
; Copies buffer to video memory
;-----------------------------------------
; Entry:	SI = vidmem offset, DI = buffer address
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	AX, CX, SI, DI
;-----------------------------------------

LoadVidMem	proc

		mov ch, FRAME_H
		mov cl, FRAME_W * 2

__Next:		mov ah, cs:[di]
		mov es:[si], ah

		inc si
		inc di

		dec cl
		cmp cl, 0
		jne __Next

		add si, (SCREEN_W - FRAME_W) * 2
		mov cl, FRAME_W * 2

		dec ch
		cmp ch, 0
		jne __Next

		ret
		endp

;-----------------------------------------


;-----------------------------------------
; Timer interrupt that prints all register if 'RegPrtOn' is FF
;-----------------------------------------
; Entry:	None
; Exit:		None
; Destr:	None
;-----------------------------------------

NewInt8		proc

		cmp cs:[RegPrtOn], 0ffh
		je __CallNewInt

		; Far jump to previous int
__CallOldInt:	db 0eah

		OldInt8ofs 	dw 0
		OldInt8seg 	dw 0

		iret

		; Save stack start before pushing
__CallNewInt:	push bp
		mov bp, sp
		sub bp, 2

		; Save registers
		push ax bx cx dx si di es

		; Save buffer update
		SetVIDMEM
		mov si, (SCREEN_W * Y + X) * 2
		call SaveBufUpdate

		; Switch from vidmem to code segment 
		mov ax, cs
		mov es, ax

		; Set some addresses
        	mov bx, (offset DrawBuf)
            	mov si, offset RegNames

		_MACROS_

		rept REG_CNT	; Repeat for REG_CNT registers stored in stack

		mov ch, 03h

            	call PrtStr	; Print register name
		
		mov ch, 04h
		mov di, si
		mov si, offset RegValues

		call PrtStr	; Print register value

		mov si, di

		add bx, (FRAME_W - 7) * 2	; To new line

		endm

		_MACROS_

		; Copy draw buffer to vidmem
		SetVIDMEM
		mov si, (SCREEN_W * Y + X) * 2
		mov di, offset DrawBuf
		call LoadVidMem

		; Restore registers
		pop es di si dx cx bx ax

		; Restore bp
		pop bp

		; Jmp to previous int handler and return
		jmp __CallOldInt

		endp

;-----------------------------------------


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
		shr di, cl
		shr di, cl
		shr di, cl

		and di, 0fh

		mov ch, cs:HexCode[di]
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
; Entry:	SI = str address, BX = vidmem address, CH = string size
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	CX, SI, BX
;------------------------------------------

PrtStr		proc

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
		mov es:[bx], ah
		mov es:[bx+1], dl
		
		add bx, 2
		sub cx, 2

		; Draw middle characters
__MdlPrt:	mov es:[bx], dh
		mov es:[bx+1], dl

		add bx, 2

		loop __MdlPrt

		; Draw last character
		mov es:[bx], al
		mov es:[bx+1], dl

		pop bx		; Restore BX pointer

		ret
		endp

;----------------------------------------


;----------------------------------------
; Draws beautiful frame
;----------------------------------------
; Entry:	BX = vidmem address, DH = Height, DL = Width,
;		DI = style address, CH = Frame Color
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

		add bx, FRAME_W * 2

		; draw middle rows of the frame
		mov ah, cs:di[2]
		mov al, cs:di[3]
		mov dh, 20h

		; outer loop as frame height
		pop cx
		shr cx, 8
		sub cx, 2

__PrtRow:	push cx

		; inner procedure loop param
		mov cx, si

		call RowPrt

		pop cx
		add bx, FRAME_W * 2

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


RegPrtOn	db 0ffh

DrawBuf		db FRAME_W * FRAME_H * 2 dup(0)
SaveBuf		db FRAME_W * FRAME_H * 2 dup(0)

RegNames   	db "ax bx cx dx si di bp sp ds es ss cs ip "
RegValues	db 03h, 03h, 03h, 03h

HexCode 	db "0123456789ABCDEF"

FrameStyle 	db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h

EOP:

end		Start
