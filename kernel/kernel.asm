use64

section	.text

global main:
main:

    ; Clean the screen with a blue color.
    mov edi, 0xB8000
    mov rcx, 500                ; Since we are clearing uint64_t over here, we put the count as Count/4.
    mov rax, 0x1F201F201F201F20 ; Blue background, white foreground, blank spaces.
    rep stosq                   ; Clear the entire screen. 

    ; Display "Hello World!"
    mov edi, 0xB8000
    mov rax, 0x1F6C1F6C1F651F48    
    mov [edi],rax
    mov rax, 0x1F6F1F571F201F6F
    mov [edi + 8], rax
    mov rax, 0x1F211F641F6C1F72
    mov [edi + 16], rax

    ret
