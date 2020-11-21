BITS 64

SECTION .text

GLOBAL main
main:

    ; Clean the screen with a blue color.
    mov edi, 0xB8000
    mov rcx, 500                ; 500 = 80 cols * 25 rows * 2 bytes / 8 u64
    mov rax, 0x1F201F201F201F20 ; Blue background, white foreground.
    rep stosq

    ; Display "Hello World!"
    mov edi, 0xB8000
    mov rax, 0x1F6C1F6C1F651F48
    mov [edi], rax
    mov rax, 0x1F6F1F571F201F6F
    mov [edi + 8], rax
    mov rax, 0x1F211F641F6C1F72
    mov [edi + 16], rax

    ret
