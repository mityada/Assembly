section .data
	mode_read db "rb", 0
	mode_write db "wb", 0
	no_mmx db "Your CPU does not support MMX ^ ^", 10, 0
	usage db "Usage: bitmap in1.bmp in2.bmp out.bmp", 10, 0
	file_error db "Can not open file.", 10, 0
	file_format db "Unsupported file format.", 10, 0
	bmp_info db "%s", 10, "Width: %i", 10, "Height: %i", 10, "BPP: %i", 10, "Compression: %i", 10, 0
	white db 255, 255, 255, 255

	SEEK_SET equ 0
	SEEK_CUR equ 1

section .bss
	file_in_1 resd 1
	file_in_2 resd 1
	file_out resd 1
	bmp_header_1 resb 14
	dib_header_1 resb 40
	bmp_header_2 resb 14
	dib_header_2 resb 40
	bmp_header resb 14
	dib_header resb 40
	pixel_array_1 resd 1
	pixel_array_2 resd 1
	pixel_1 resd 1
	pixel_2 resd 1

section .text
	global _start
	extern fopen
	extern fclose
	extern fread
	extern fwrite
	extern fseek
	extern printf
	extern memcpy
	extern exit

_start:
	mov eax, 1
	cpuid
	test edx, 1 << 23
	jnz _mmx_ok
	push no_mmx
	call _die
_mmx_ok:

	cmp dword [esp], 4
	je _usage_ok
	push usage
	call _die
_usage_ok:

	mov eax, [esp + 8]
	push bmp_header_1
	push file_in_1
	push eax
	call _load_bitmap
	add esp, 12

	mov eax, [esp + 12]
	push bmp_header_2
	push file_in_2
	push eax
	call _load_bitmap
	add esp, 12

	push 54
	push bmp_header_1
	push bmp_header
	call memcpy
	add esp, 12

	mov dword [bmp_header + 10], 54 ; pixel array offset

	mov eax, [dib_header_2 + 4]
	cmp eax, [dib_header + 4]
	jge _width_greater
	mov [dib_header + 4], eax
_width_greater:

	mov eax, [dib_header_2 + 8]
	cmp eax, [dib_header + 8]
	jge _height_greater
	mov [dib_header + 8], eax
_height_greater:

	mov eax, [esp + 16]
	push bmp_header
	push file_out
	push eax
	call _create_bitmap
	add esp, 12

	push SEEK_SET
	mov eax, [bmp_header_1 + 10]
	push eax
	mov eax, [file_in_1]
	push eax
	call fseek
	add esp, 12

	push SEEK_SET
	mov eax, [bmp_header_2 + 10]
	push eax
	mov eax, [file_in_2]
	push eax
	call fseek
	add esp, 12

	mov edi, [dib_header + 8]
_loop_height:
	mov esi, [dib_header + 4]
_loop_width:
	mov eax, [file_in_1]
	push eax
	push 3
	push 1
	push pixel_1
	call fread
	add esp, 16

	mov eax, [file_in_2]
	push eax
	push 3
	push 1
	push pixel_2
	call fread
	add esp, 16

	mov eax, [pixel_2]
	push eax
	mov eax, [pixel_1]
	push eax
	call _multiply
	add esp, 8
	mov [pixel_1], eax

	mov eax, [file_out]
	push eax
	push 3
	push 1
	push pixel_1
	call fwrite
	add esp, 16

	dec esi
	jnz _loop_width

	mov eax, [dib_header_1 + 4]
	mov ecx, eax
	and ecx, 3
	sub eax, [dib_header + 4]
	lea eax, [eax + eax * 2]
	lea eax, [eax + ecx]
	push SEEK_CUR
	push eax
	mov eax, [file_in_1]
	push eax
	call fseek
	add esp, 12

	mov eax, [dib_header_2 + 4]
	mov ecx, eax
	and ecx, 3
	sub eax, [dib_header + 4]
	lea eax, [eax + eax * 2]
	lea eax, [eax + ecx]
	push SEEK_CUR
	push eax
	mov eax, [file_in_2]
	push eax
	call fseek
	add esp, 12

	mov eax, [file_out]
	push eax
	mov eax, [dib_header + 4]
	and eax, 3
	push eax
	push 1
	push pixel_1
	call fwrite
	add esp, 16

	dec edi
	jnz _loop_height

	mov eax, [file_in_1]
	push eax
	call fclose

	mov eax, [file_in_2]
	mov [esp], eax
	call fclose

	mov eax, [file_out]
	mov [esp], eax
	call fclose
	add esp, 4

	call _exit

_load_bitmap:
	mov eax, [esp + 4]
	push mode_read
	push eax
	call fopen
	add esp, 8

	test eax, eax
	jnz _open_ok
	push file_error
	call _die

_open_ok:
	mov ecx, [esp + 8]
	mov [ecx], eax

	push eax			; file stream
	push 54				; count
	push 1				; size
	mov eax, [esp + 12 + 12]	; bitmap header
	push eax
	call fread
	add esp, 16

	mov eax, [esp + 12]
	cmp word [eax], "BM"		; file type
	jne _format_error
	cmp dword [eax + 14 + 16], 0	; compression
	jne _format_error
	cmp word [eax + 14 + 14], 24	; bits per pixel
	je _format_ok
_format_error:
	push file_format
	call _die
_format_ok:

	mov edx, [esp + 4]	; file name
	mov ecx, [esp + 12]
	add ecx, 14		; dib header
	mov eax, [ecx + 16]	; compression
	push eax
	mov eax, [ecx + 14]	; bits per pixel
	push eax
	mov eax, [ecx + 8]	; height
	push eax
	mov eax, [ecx + 4]	; width
	push eax
	push edx
	push bmp_info
	call printf
	add esp, 24

	ret

_create_bitmap:
	mov eax, [esp + 4]
	push mode_write
	push eax
	call fopen
	add esp, 8

	test eax, eax
	jnz _create_ok
	push file_error
	call _die

_create_ok:
	mov ecx, [esp + 8]
	mov [ecx], eax

	push eax			; file stream
	push 54				; count
	push 1				; size
	mov eax, [esp + 12 + 12]	; bitmap header
	push eax
	call fwrite
	add esp, 16

	mov edx, [esp + 4]	; file name
	mov ecx, [esp + 12]
	add ecx, 14		; dib header
	mov eax, [ecx + 16]	; compression
	push eax
	mov eax, [ecx + 14]	; bits per pixel
	push eax
	mov eax, [ecx + 8]	; height
	push eax
	mov eax, [ecx + 4]	; width
	push eax
	push edx
	push bmp_info
	call printf
	add esp, 24

	ret

_multiply:
	movd mm1, [esp + 4]
	mov dword [esp + 4], 0
        movd mm2, [esp + 4]
        movd mm3, [esp + 4]
        punpcklbw mm1, mm3
        punpcklbw mm2, [esp + 8]
        pmulhuw mm1, mm2
        packuswb mm1, mm3
        movd [esp + 4], mm1
	mov eax, [esp + 4]

	ret

_die:
	mov eax, [esp + 4]
	push eax
	call printf
	add esp, 4

_exit:
	push 0
	call exit
