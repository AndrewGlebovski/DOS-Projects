.286

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

HasAccess	equ 025bh	; HasAccess vairable offset in CRACK.ASM
ReturnAddress	equ 0122h	; Specific return address if '~' was pressed


Start:  	xor bx, bx
        	mov es, bx
        	mov bx, 9 * 4

        	cli     ; disable int handle

        	; set int9 and save previous
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
; Keyboard interrupt that cracks program when '~' pressed
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

		iret

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

		mov byte ptr ss:[HasAccess], 0ffh

		add sp, 2
		push ReturnAddress

		iret
		endp

;-----------------------------------------

EOP:

end		Start

