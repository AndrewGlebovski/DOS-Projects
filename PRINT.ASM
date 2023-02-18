.model tiny

.code

org 100h

Start:		mov bx, 0b800h
		mov es, bx

		mov bx, (80d * 12d + 32d) * 2 
		mov cl, cs:[80h]

		cmp cl, 0h
		
		je Skip

		mov si, 81h
		mov ah, 01h

Next:		mov al, cs:[si]
		mov es:[bx], ax

		add si, 1
		add bx, 2
		add ah, 1

		loop Next

Skip:		mov ax, 4c00h
		int 21h

end 		Start
