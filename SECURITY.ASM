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


; Password: 12345678, Hash: D9B1h

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


		; Read input into buffer
Start:  	mov ah, 0ah
		mov dx, offset Input
		int 21h

		; Canary broken
		cmp [Canary], 0BEEFh
		jne BadInput
		
		; Input and password hash comparsion
		mov si, offset Input + 2
		mov cx, 08h	; POSSIBLE BUFFER OVERFLOW!!!
		call GNUHash

		cmp ax, [Password]
		jne BadInput

		; Print result
		mov si, offset Success
		mov cx, 0202h

		call TextInFrame

        	; Exit 0
        	mov ax, 4c00h
        	int 21h

		; Print result
BadInput:	mov si, offset Fail
		mov cx, 0404h

		call TextInFrame

		; Exit 0
        	mov ax, 4c00h
        	int 21h


;----------------------------------------
; Print frame with text inside
;----------------------------------------
; Entry:	SI = text, CH = frame color, CL = text color
; Exit:		None
; Destr:	AX, BX, CX, DX, SI, DI, ES
;----------------------------------------

TextInFrame	proc

		; Save text offset and color
		push si
		push cx

		SetVIDMEM

		; Print green frame
		mov bx, (SCREEN_W * FRAME_Y + FRAME_X) * 2
		mov dl, FRAME_W
		mov dh, FRAME_H
		mov di, offset FrameStyle
		call FramePrt

		; Restore text offset and color
		pop cx
		pop si

		; Print text
		mov bx, (SCREEN_W * (FRAME_Y + 2) + FRAME_X + 2) * 2
		shl cx, 8
		call StrPrt

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
; Calculates GNU hash sum
;------------------------------------------
; Entry:	SI = pointer, CX = size
; Exit:		AX = hash sum
; Destr:	AX, BX, CX, SI
;------------------------------------------

GNUHash		proc
		
		mov ax, 5381
		mov bx, 33

__Next:		mul bx
		adc al, byte ptr [si]

		inc si

		loop __Next

		ret
		endp

;------------------------------------------


.data

		; MAX LENGTH IS BIGGER THAN BUFFER SIZE, POSSIBLE OVERFLOW!!!
Input		db 16h, 0, 9 dup(0)	; Max length, Length, Buffer
Canary		dw 0BEEFh
Password	dw 0d9b1h

Success		db "ACCESS GRANTED!", '$'
Fail		db "ACCESS DENIED!", '$'

FrameStyle 	db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h

end		Start

