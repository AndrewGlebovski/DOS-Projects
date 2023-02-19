.186

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

VIDMEM equ 0b800h	; Video memory address segment


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


Start:		LoadVideoES
		
		; Cmd args = <x> <y> <width> <height> <style-id>

		mov si, 82h

		call ReadInt
		mov bl, al

		call ReadInt
		mov bh, al

		call ReadInt
		mov dl, al

		call ReadInt
		mov dh, al
		
		mov ax, bx 
            	;mov dx, 0a28h
		mov cx, 0c0ch
		mov di, offset set1

            	call FramePrt

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

		pop BX		; Return to start value

		ret
		endp

;----------------------------------------

;----------------------------------------
; Draws beautiful frame
;----------------------------------------
; Entry:	AH = Y, AL = X, DH = Height, DL = Width,
;		DI = pattern address, CH = Frame Color, CL = Font color
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr: 	AX, BX, CX, DX, SI
;----------------------------------------

FramePrt	proc

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

.data

set1 db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h
set2 db 03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h

end		Start
