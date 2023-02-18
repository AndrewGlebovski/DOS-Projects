.model tiny

.code

org 100h

Start:			mov ah, 09h 
			mov dx, offset HelloWorld

			int 21h

			mov ax, 4c00h
			
			int 21h

.data

HelloWorld:		db 'Hello', 2ch, 20h, 'World', 21h, '$' 

end Start