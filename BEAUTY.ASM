.model tiny
.code
org 100h

Start:		mov bx, 0b800h
		mov es, bx

		xor bx, bx
		mov cx, 80d * 25d

Next:		mov BYTE PTR ES:[bx], 03d
        	mov BYTE PTR ES:[bx+1], 4eh	

		add bx, 2

		loop Next

		mov ax, 4c00h
		int 21h

end		Start
