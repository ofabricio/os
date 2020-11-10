use64

section	.text

global main:
main:

    mov eax, 0xB8000
    mov rbx, 0x4840404040404040
    mov qword [eax], rbx

    ret
