format ELF64

section '.text' executable

public main
main:

    mov eax, 0xB8000
    mov rbx, 0x5050505050505050
    mov qword [eax], rbx

    ret
