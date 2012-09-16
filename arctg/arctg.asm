section .data
	x dd 0.5
	divider dd 1
	format db "arctg(%f) = %f", 10, 0

section .text
	global _start
	extern printf

_start:
	fld dword [x]
	fld ST0
	fld ST0
	fmul ST0
	mov ecx, 1000
_loop:
	fld ST0
	fmul ST2
	fchs
	fst ST2
	add dword [divider], 2
	fidiv dword [divider]
	faddp ST3, ST0

	dec ecx
	jnz _loop

	sub esp, 8
	fincstp
	fincstp
	fstp qword [esp]
	sub esp, 8
	fld dword [x]
	fstp qword [esp]
	push format
	call printf
	add esp, 20

	mov eax, 1
	xor ebx, ebx
	int 0x80
