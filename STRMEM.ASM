.186

.model tiny

.code

locals __

org 100h

Start:		push offset Str1

		call StrLen

		mov ax, 4c00h
		int 21h


;----------------------------------------
; Prints string length
;----------------------------------------
; Entry:	p1 = str address
; Exit:		BX
; Destr:	AX, BX, SI
;----------------------------------------

StrLen		proc

		push bp
		mov bp, sp

		mov si, [bp+4] 	; p1

__Next:		lodsb
		inc bx
		cmp al, '$'
		jne __Next  

		dec bx

		pop bp

		ret
		endp

;----------------------------------------

;----------------------------------------
; Finds character position in buffer
;----------------------------------------
; Entry:	p1 = buf address, p2 = char to find, p3 = count
; Exit:		SI or AX = 1 if not found
; Destr:	AX, CX, SI
;----------------------------------------

MemChr		proc

		push bp
		mov bp, sp

		mov si, [bp+8] 	; p1
		mov ax, [bp+6]	; p2
		shl ax, 8d
		mov cx, [bp+4]	; p3

__Next:		lodsb

		cmp al, ah
		je __Finish

		loop __Next

		mov ax, 1h

__Finish:	pop bp

		ret
		endp

;----------------------------------------

;----------------------------------------
; Finds character position in string
;----------------------------------------
; Entry:	p1 = str address, p2 = char to find
; Exit:		SI or AX = 1 if no char found
; Destr:	AX, SI
;----------------------------------------

StrChr		proc

		push bp
		mov bp, sp

		mov si, [bp+6] 	; p1
		mov ax, [bp+4]	; p2
		shl ax, 8d

__Next:		lodsb

		cmp al, '$'
		je __NotFound

		cmp al, ah
		jne __Next

		jmp __Finish

__NotFound:	mov ax, 1h

__Finish:	pop bp

		ret
		endp

;----------------------------------------

;----------------------------------------
; Copies p3 bytes from origin to destination
;----------------------------------------
; Entry:	p1 = org, p2 = dest, p3 = count
; Exit:		None
; Assumes:	ES = dest segment
; Destr:	CX, SI, DI
;----------------------------------------

MemCpy		proc

		push bp
		mov bp, sp

		mov si, [bp+8] 	; p1
		mov di, [bp+6]	; p2
		mov cx, [bp+4]	; p3

		ret movsb

		pop bp

		ret
		endp

;----------------------------------------

;----------------------------------------
; Copies str1 to str2
;----------------------------------------
; Entry:	p1 = org, p2 = dest
; Exit:		None
; Assumes:	ES = dest segment
; Destr:	AX, SI, DI
;----------------------------------------

StrCpy		proc

		push bp
		mov bp, sp

		mov si, [bp+4] 	; p1
		mov di, [bp+6]	; p2

__Next:		lodsb
		stosb

		cmp al, '$'
		jne __Next

		pop bp

		ret
		endp

;----------------------------------------


;----------------------------------------
; Sets first p3 chars in buffer to p2
;----------------------------------------
; Entry:	p1 = buf address, p2 = char, p3 = count
; Exit:		None
; Destr:	AX, CX, DI
;----------------------------------------

MemSet		proc

		push bp
		mov bp, sp

		mov di, [bp+4] 	; p1
		mov ax, [bp+6]	; p2
		mov cx, [bp+8]	; p3

		ret stosb

		pop bp

		ret
		endp

;----------------------------------------

;----------------------------------------
; Compares p3 bytes in buffer 1 and buffer 2
;----------------------------------------
; Entry:	p1 = buf1 address, p2 = buf2 address, p3 = count
; Exit:		AX = 0 if equal
; Assumes:	ES = str2 segment
; Destr:	AX, CX, SI, DI
;----------------------------------------

MemCmp		proc

		push bp
		mov bp, sp

		mov ax, 0h

		mov si, [bp+4] 	; p1
		mov di, [bp+6]	; p2
		mov cx, [bp+8]	; p3

__Next:		cmpsb
		
		jne __NotEqual
		
		loop __Next

		jmp __Finish

__NotEqual:	mov ax, 1h

__Finish:	pop bp

		ret
		endp

;----------------------------------------

.data

Str1 		db "Hello", '$'
Str2		db "World", '$'

end 		Start
