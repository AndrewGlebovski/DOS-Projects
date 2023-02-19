.186

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

VIDMEM equ 0b800h	; Video memory address segment

SET_CNT equ 2

;----------------------------------------
; Loads ES with video segment address
;----------------------------------------
; Entry:	None
; Exit:		ES = 0b800h
; Destr:	BX
;----------------------------------------

LoadVideoES	macro

		_MACROS_

		mov bx, VIDMEM
		mov es, bx

		_MACROS_

		endm

;----------------------------------------


;----------------------------------------
; Exit to DOS
;----------------------------------------
; Entry: 	None
; Exit:		None
; Destr:	AX
;----------------------------------------

Exit		macro code
		
		_MACROS_		

		mov ax, 4c00h or code
		int 21h

		_MACROS_

		endm

;----------------------------------------


; cmd format = <x> <y> <w> <h> <stl-id> [usr-stl] [frame-clr] [font-clr] <msg>

Start:		LoadVideoES

		mov si, 82h

		call ReadInt
		mov bl, al

		call ReadInt
		mov bh, al

		call ReadInt
		mov dl, al

		call ReadInt
		mov dh, al

		push bx
		push dx

		mov al, cs:[si]
		sub al, '0'
		add si, 2d

		cmp al, SET_CNT
		jb Predef		; user choose to set custom symbols

		mov di, offset si	; WORKS ONLY CAUSE PSP AND DATA
		add si, 9		; ARE IN THE SAME SEGMENT

		call ReadInt
		mov dh, al
		
		call ReadInt
		mov dl, al

		mov cx, dx

		jmp Prt

Predef:	 	mov cx, 0c0ch	; user choose predefined set of symbols

		xor bx, bx
		mov bl, al
		shl bx, 3

		lea di, set0[bx]

Prt:           	pop dx
		pop ax

		call CalcBX

		push si		; Save some params for message output
		push bx
		push cx

		call FramePrt

		; print string time

		pop cx
		pop di
		pop si
		
		add di, 163d * 2d	; Skip two lines and two symbols
		mov al, cl

		xor cx, cx		; Calculates message length
		mov cl, cs:[80h]
		add cx, 81h
		sub cx, offset si		

		call PrtStr

		Exit 0


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
		mov ah, di[4]
		mov al, di[5]
		mov dh, di[0]

		call RowPrt

		add bx, 80d * 2d

		; draw middle rows of the frame
		mov ah, di[2]
		mov al, di[3]
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
		mov ah, di[6]
		mov al, di[7]
		mov dh, di[1]

		call RowPrt

		ret
		endp

;-----------------------------------------

;-----------------------------------------
; Reads number from cmd args
;-----------------------------------------
; Entry:	SI = String address
; Exit:		AX
; Destr:	AX, CX, SI
;-----------------------------------------

ReadInt		proc

		mov CH, 10d
		xor AX, AX

__Next:		mov CL, CS:[SI]
		inc SI

		cmp CL, '0'
		jb __Skip

		cmp CL, '9' 
		ja __Skip		

		sub CL, '0'
		mul CH
		adc AL, CL

		jmp __Next

__Skip:		ret
		endp

;------------------------------------------

;------------------------------------------
; Prints string to screen
;------------------------------------------
; Entry:	SI = str address, DI = vidmem address, CX = size, AL = color
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	AX, CX, SI, DI
;------------------------------------------

PrtStr		proc

		push DI

__Next:		mov ah, cs:[si]
		inc si

		cmp ah, '\'
		je __NewLine

		mov es:[di], ah		; Draw actual symbol
		mov es:[di+1], al
		
		add di, 2d
		loop __Next

		jmp __Finish 

__NewLine:	pop di			; '\' symbol is not printed
		add di, 80d * 2d
		push di			; Save value to restore it next time

		loop __Next

__Finish:	pop DI

		ret
		endp

;------------------------------------------

;------------------------------------------
; Calculates vidmem address by x and y
;------------------------------------------
; Entry: 	AH = y, AL = x
; Exit:		BX
; Destr:	BX
;------------------------------------------

CalcBX		proc
		
		xor bx, bx

		; bx = (ah * 80d + al) * 2d
		push ax
		shr ax, 8
		mov bl, 80d
		mul bl
		mov bx, ax
		pop ax
        	adc bl, al
		shl bx, 1   

		ret
		endp

;------------------------------------------

.data

set0 db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h
set1 db 8 dup(03h)

end		Start
