.286

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

VIDMEM equ 0b800h	; Video memory address segment


SCREEN_W equ 80		; Screen width


FRAME_X equ 30		; X coordinate of top left corner
FRAME_Y equ 8		; Y coordinate of top left corner
FRAME_W equ 20		; Frame width
FRAME_H equ 5		; Frame height


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

		; read input into buffer
Start:  	mov ah, 0ah
		mov dx, offset Input
		int 21h

		; input size check
		mov ch, Input[1]
		mov cl, 08h

		cmp ch, cl
		jb BadInput

		; input and password comparsion
		mov si, offset Input + 2
		mov di, offset Password
		mov cx, 08h 

		call StrCmp

		cmp ax, 0
		jne BadInput

		call YesAccess

		; exit 0
        	mov ax, 4c00h
        	int 21h

BadInput:	call NoAccess

        	; exit 0
        	mov ax, 4c00h
        	int 21h


;----------------------------------------
; Draws 'ACCESS GRANTED'
;----------------------------------------
; Entry:	None
; Exit:		None
; Destr:	AX, BX, CX, DX, SI, DI, ES
;----------------------------------------

YesAccess	proc

		SetVIDMEM

		; Print green frame
		mov bx, (SCREEN_W * FRAME_Y + FRAME_X) * 2
		mov dl, FRAME_W
		mov dh, FRAME_H
		mov ch, 02h
		mov di, offset FrameStyle
		call FramePrt

		; Print text
		mov bx, (SCREEN_W * (FRAME_Y + 2) + FRAME_X + 2) * 2
            	mov si, offset Success
		mov ch, 02h
		call StrPrt

		; Waiting for user to press escape
__Next:		in al, 60h

		cmp al, 1
		jne __Next

		ret
		endp

;----------------------------------------


;----------------------------------------
; Draws 'ACCESS DENIED'
;----------------------------------------
; Entry:	None
; Exit:		None
; Destr:	AX, BX, CX, DX, SI, DI, ES
;----------------------------------------

NoAccess	proc

		SetVIDMEM

		; Print green frame
		mov bx, (SCREEN_W * FRAME_Y + FRAME_X) * 2
		mov dl, FRAME_W
		mov dh, FRAME_H
		mov ch, 04h
		mov di, offset FrameStyle
		call FramePrt

		; Print text
		mov bx, (SCREEN_W * (FRAME_Y + 2) + FRAME_X + 2) * 2
            	mov si, offset Fail
		mov ch, 04h
		call StrPrt

		; Waiting for user to press escape
__Next:		in al, 60h

		cmp al, 1
		jne __Next

		ret
		endp

;----------------------------------------


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
		mov ah, di[4]
		mov al, di[5]
		mov dh, di[0]

		call RowPrt

		add bx, SCREEN_W * 2

		; draw middle rows of the frame
		mov ah, di[2]
		mov al, di[3]
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
		add bx, SCREEN_W * 2

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


;------------------------------------------
; Prints string to screen
;------------------------------------------
; Entry:	SI = string address, BX = vidmem address, CH = font color
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	CX, SI, BX
;------------------------------------------

StrPrt		proc

		mov cl, [si]
		jmp __Test

__Next:		mov es:[bx], cx
		
		add bx, 2
        	inc si

		mov cl, [si]

__Test:		cmp cl, '$'
		jne __Next

		ret
		endp

;------------------------------------------


;------------------------------------------
; Compares two strings
;------------------------------------------
; Entry:	SI = first string, DI = second string, CX = size
; Exit:		AX = 0 if string match, 1 otherwise 
; Destr:	AX, CX, SI, DI
;------------------------------------------

StrCmp		proc

__Next:		mov al, [si]
		mov ah, [di]

		cmp al, ah
		je __Equal

		mov ax, 1
		ret

__Equal:	inc si
		inc di

		loop __Next

		mov ax, 0

		ret
		endp

;------------------------------------------


.data

Input		db 14h, 10 dup(0)

Password	db "12345678", '$'

Success		db "ACCESS GRANTED!", '$'
Fail		db "ACCESS DENIED!", '$'

FrameStyle 	db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h

end		Start
