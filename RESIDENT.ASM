.286

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

		push ax bx cx si es

        	SetVIDMEM
        	mov bx, 160 * 1 + 71 * 2

        	call HexPrint

		pop es si cx bx ax

		; Jump to previous int

        	db 0eah

OldInt9ofs 	dw 0
OldInt9seg 	dw 0

		iret
		endp

;-----------------------------------------

;-----------------------------------------
; Prints heximal representation
;-----------------------------------------
; Entry:	AX = Number to print, BX = vidmem offset
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	AX, BX, CX, SI
;-----------------------------------------

HexPrint	proc

		mov cl, 4d

__Next:		mov si, ax
		and si, 000fh
		
		mov ch, cs:hex_code[si]
		mov es:[bx], ch
		mov byte ptr es:[bx+1], 4eh

		sub bx, 2
		shr ax, 4
		
		dec cl
		cmp cl, 0
		jne __Next

		ret
		endp

;-----------------------------------------

hex_code 	db "0123456789ABCDEF"

EOP:

end		Start
