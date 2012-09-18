section .bss
	buffer resb 255

section .text
	global _start

_start:
	push 239
	push buffer
	call _inttostr
	add esp, 8

	mov eax, 4
	mov ebx, 1
	mov ecx, buffer
	mov edx, 255
	int 0x80

	mov eax, 1
	mov ebx, 0
	int 0x80

_inttostr:
	push ebx
	push esi
	mov esi, [esp + 12]
	mov eax, [esp + 16]
	xor ecx, ecx
_loop:
	xor edx, edx
	mov ebx, 10
	div ebx
	add edx, 48
	inc ecx
	push edx
	test eax, eax
	jnz _loop

_loop2:
	pop edx
	mov [esi], dl
	add esi, 1
	dec ecx
	test ecx, ecx
	jnz _loop2

	mov ecx, 10
	mov [esi], ecx
	add esi, 1
	mov ecx, 0
	mov [esi], ecx
	add esi, 1

	pop esi
	pop ebx

	ret
