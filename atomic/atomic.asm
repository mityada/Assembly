section .text
	global _f

_f:
	push ebx
	mov ebx, [esp + 8]
	mov ecx, [esp + 12]
.loop:
	mov eax, [ebx]
	mov edx, eax
	or edx, ecx
	lock cmpxchg [ebx], edx
	jnz .loop

	pop ebx
	ret
