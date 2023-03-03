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

		; Set vidmem and reg_names start address
        	mov bx, (SCR_WIDTH * Y + X) * 2
            	mov si, offset reg_names

		_MACROS_

		rept 6		; Print for registers from stack

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
		mov byte ptr es:[bx+1], 4eh

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
		mov byte ptr es:[bx+1], 4eh
		
		add bx, 2
        	inc si
        	dec ch
        	cmp ch, 0
		jne __Next

		ret
		endp

;------------------------------------------


hex_code 	db "0123456789ABCDEF"
reg_names   	db "ax bx cx dx si di "

EOP:

end		Start
