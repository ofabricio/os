%ifndef __PRINT__
%define __PRINT__

use16

; Prints a string.
;   In: [ES:SI]     Pointer to the first charater.
Print:
    cld
    pushad
.b: lodsb           ; Load the value at [ES:SI] in AL.
    test al, al     ; If AL is the terminator character, stop printing.
    je .f                  	
    mov ah, 0x0E	; https://stanislavs.org/helppc/int_10-e.html
    int 0x10
    jmp .b          ; Loop till the null character not found.
.f: popad
    ret

; Collection of functions to print characters with
; BIOS INT instructions in 16-bits real mode.

; Prints BX in hexadecimal.
PrintHex:
    push bx
    call val_to_hex_str
    mov si, HEX_OUT
    call Print
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
    jle .f
    add al,  7      ; 65 (ASCII 'A') - 48 (ASCII '0') - 10 (0x0A offset) = 7
.f: add al, 48      ; 48 = ASCII '0'

    ; Move result to output.
    mov [di], al
    dec di
    shr bx, 4       ; Prepare next nibble.

    ; Repeat while CX != 0.
    dec cx
    jnz .next_nibble

    popa
    ret

HEX_OUT db '0x0000', 0

%endif
