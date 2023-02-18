.186
.model tiny
.code
locals __
org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

VIDMEM equ 0b800h	; Video memory address segment

x equ 48d		; Output position on screen
y equ 13d		;

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


INPUT_NUM equ 0a9fh		; Number to show in three representations


Start:		LoadVideoES

		mov ax, INPUT_NUM
		call DecPrint

		mov ax, INPUT_NUM
		call HexPrint

		mov ax, INPUT_NUM
		call BinPrint

		Exit 0


;----------------------------------------
; Prints binary represintation
;----------------------------------------
; Entry:	AX = Number to print
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr: 	AX, BX, CX, DX
;----------------------------------------

BinPrint	proc

		mov cx, 16d
		mov bx, (80d * (y + 1) + x) * 2

__Next:		mov dx, ax		
		and dx, 1
		add dx, '0'

		mov es:[bx], dl

		sub bx, 2
		shr ax, 1

		loop __Next

		ret
		endp

;-----------------------------------------


;-----------------------------------------
; Prints heximal representation
;-----------------------------------------
; Entry:	AX = Number to print
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	AX, BX, CX, DX, SI
;-----------------------------------------

HexPrint	proc

		mov cx, 4d
		mov bx, (80d * y + x) * 2

__Next:		mov si, ax
		and si, 000fh
		
		mov dl, trans[si]

		mov es:[bx], dl

		sub bx, 2
		shr ax, 4
		
        	loop __Next

		ret
		endp

;-----------------------------------------


;-----------------------------------------
; Prints decimal representation
;-----------------------------------------
; Entry:	AX = Number to print
; Exit:		None
; Assumes:	ES = VIDMEM
; Destr:	AX, BX, CX, DX, SI
;-----------------------------------------

DecPrint	proc

		mov si, 10d

		mov cx, 5d
		mov bx, (80d * (y - 1) + x) * 2

__Next:     	xor dx, dx

		div si
		add dl, '0'

		mov es:[bx], dl

		sub bx, 2
		
        	loop __Next

		ret
		endp

;-----------------------------------------


.data

trans db "0123456789ABCDEF", '$'

end		Start
