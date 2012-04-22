section .data
	newline db 10

section .text
	global _start

_start:
	pop esi

_loop:
	mov ebx, 1
	call _strlen
	mov edx, eax
	mov eax, 4
	pop ecx
	int 0x80

	mov eax, 4
	mov ebx, 1
	mov ecx, newline
	mov edx, 1
	int 0x80

	dec esi
	jnz _loop

_exit:

	mov eax, 1
	mov ebx, 0
	int 0x80

_strlen:
	mov ecx, [esp + 4]
	xor eax, eax
_strlen_loop:
	cmp byte [ecx], 0
	jz _strlen_end
	inc eax
	inc ecx
	jmp _strlen_loop

_strlen_end:
	ret
