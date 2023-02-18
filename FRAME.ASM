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

            	mov AX, 0a10h
            	mov DX, 0a28h

            	call FramePrt

		Exit 0


;----------------------------------------
; Draws beautiful frame
;----------------------------------------
; Entry:	AH = Y, AL = X, DH = Height, DL = Width
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr: 	AX, BX, CX, DX, SI
;----------------------------------------

FramePrt	proc
		
        	xor bx, bx

		push ax
		shr ax, 8
		mov bl, 80d
		mul bl
		mov bx, ax
		pop ax
		
		xor cx, cx
		mov cl, al
        	add bx, cx
        	
		shl bx, 1

        	xor si, si

		xor cx, cx
        	mov cl, dh

__ClrCol:	push cx
        	push bx                
    
		xor cx, cx
        	mov cl, dl

__ClrRow:	mov byte ptr es:[si + bx], 20h
        
        	add bx, 2 

        	loop __ClrRow

        	add si, 80d * 2d
        
        	pop bx
        	pop cx 

        	loop __ClrCol

		push bx
		mov cl, dl 

		mov ah, symbols[0]
		mov al, symbols[1]

__PrtRow:	mov byte ptr es:[bx], ah
		mov byte ptr es:[si + bx], al
		
		add bx, 2

		loop __PrtRow

		pop si

		mov cl, dh

		mov dh, symbols[4]
		mov dl, symbols[5]

		mov es:[bx], dl
		mov es:[si], dh

		mov ah, symbols[2]
		mov al, symbols[3]

__PrtCol:	add si, 80d * 2d
		add bx, 80d * 2d

		mov byte ptr es:[si], ah
		mov byte ptr es:[bx], al

		loop __PrtCol

		mov dh, symbols[6]
		mov dl, symbols[7]

		mov es:[si], dh
		mov es:[bx], dl 

		ret
		endp

;-----------------------------------------

.data

symbols db 0c4h, 0c4h, 0b3h, 0b3h, 0dah, 0bfh, 0c0h, 0d9h

end		Start
