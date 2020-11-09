use32

VIDEO_MEMORY        = 0xB8000

WHITE_ON_BLACK      = 0x0F      ; The color byte for each character.

; Print a string. The string must end with zero '\0'.
;
;    In: EBX      Address of the first character.
print_string_pm:
    pusha
    mov edx, VIDEO_MEMORY

.loop:
    mov al, [ebx]
    mov ah, WHITE_ON_BLACK

    cmp al, 0       ; Check if end of string.
    je @f

    mov [edx], ax   ; Store character + attribute in video memory.
    add ebx, 1      ; Next char.
    add edx, 2      ; Next video memory position.

    jmp .loop

@@: popa
    ret
