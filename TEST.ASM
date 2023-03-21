.model tiny
.code
org 100h

Start:	mov ax, 0aaaah
	mov bx, 0bbbbh
	mov cx, 0cccch
	mov dx, 0ddddh
	mov si, 5151h
	mov di, 0d1d1h

Next:	in al, 60h
	cmp al, 1
	jne Next

	ret

end 	Start

