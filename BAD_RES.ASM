.286

.model tiny

.code

locals __

org 100h


_MACROS_ equ nop	; Signals about macros begin and end in byte code

HasAccess	equ 025bh	; HasAccess vairable offset in CRACK.ASM
ReturnAddress	equ 0122h	; Specific return address after buffered input call


Start:  	xor bx, bx
        	mov es, bx
        	mov bx, 21 * 4

        	cli     ; disable int handle

        	; set int21 and save previous
            	mov ax, es:[bx]
        	mov OldInt21ofs, ax
        	mov es:[bx], offset NewInt21

            	mov ax, es:[bx+2]
        	mov OldInt21seg, ax
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
; Keyboard interrupt that cracks program on BufferedInput
;-----------------------------------------
; Entry:	None
; Exit:		None
; Destr:	None
;-----------------------------------------

NewInt21	proc

		pushf
		push cs
		push offset __NewInt

		db 0eah

OldInt21ofs 	dw 0
OldInt21seg 	dw 0

__NewInt:	cmp ah, 4fh
		je __Crack
		
		iret

__Crack:	mov byte ptr ss:[HasAccess], 0ffh

		add sp, 2
		push ReturnAddress

		iret
		endp

;-----------------------------------------

EOP:

end		Start

