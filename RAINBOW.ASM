.model tiny

.code

org 100h

Start:		mov bx, 0b800h
		mov es, bx

		mov bx, (80d * 12d + 32d) * 2 
		mov cx, msg_len
		mov si, offset msg
		mov ah, 01h

Next:		mov al, ds:[si]
		mov es:[bx], ax

		add si, 1
		add bx, 2
		add ah, 1 

		loop Next

		mov ax, 4c00h
		int 21h

.data
msg		db "WHAT THE FUCK"
msg_len		equ $ - msg

end 		Start
