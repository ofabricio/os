; Collection of functions to print characters with
; BIOS INT instructions in 16-bits real mode.

; Prints BX in hexadecimal.
print_hex:
    push bx
    call val_to_hex_str
    mov bx, HEX_OUT
    call print
    pop bx
    ret


; Converts BX into hexadecimal string.
;
;   In:  BX
;   Out: HEX_OUT
;
; Algorithm:
;   For each nibble in BX, add ASCII offset and
;   move it to the corresponding position in HEX_OUT.
;   Example: BX = 0x1234 -> HEX_OUT = '0x1234\0'
val_to_hex_str:
    pusha
    mov di, HEX_OUT + 5
    mov cx, 4

    ; Add ASCII offset.
.next_nibble:
    mov ax, bx      ; BX comes from the caller.
    and al, 0x0F
    cmp al, 0x09    ; 0x01 to 0x09 jump; 0x0A to 0x0F no jump
    jle @f
    add al,  7      ; 65 (ASCII 'A') - 48 (ASCII '0') - 10 (0x0A offset) = 7
@@: add al, 48      ; 48 = ASCII '0'

    ; Move result to output.
    mov [di], al
    dec di
    shr bx, 4       ; Prepare next nibble.

    ; Repeat while CX != 0.
    dec cx
    jnz .next_nibble

    popa
    ret


; Print a zero-terminated string pointed by BX.
print:
    push bx
@@: mov al, [bx]
    cmp al, 0
    je @f
    mov ah, 0x0E
    int 0x10
    add bx, 1
    jmp @b
@@: pop bx
    ret


; Print a new line character '\r\n'.
printnl:
    mov ah, 0x0E ; https://stanislavs.org/helppc/int_10-e.html
    mov al, 0x0D ; '\r'
    int 0x10
    mov al, 0x0A ; '\n'
    int 0x10
    ret


HEX_OUT db '0x0000', 0
