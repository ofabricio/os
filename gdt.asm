use16

gdt_start:
    ; The GDT starts with a null 8-byte.
    dd 0x0
    dd 0x0

; GDT for code segment. base = 0x00000000, limit (lenght) = 0xFFFFF
; 1st flags: (present)1 (privilege)00 (descriptor type)1 -> 1001b
; type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
; 2nd flags: (granularity)1 (32-bit default)1 (64-bit segment)0 (AVL)0 -> 1100b
gdt_code:
    dw 0xFFFF    ; Seg Limit (Length), bits 0-15
    dw 0x0       ; Base address, bits 0-15
    db 0x0       ; Base address, bits 16-23
    db 10011010b ; 1st flags, type flags
    db 11001111b ; 2nd flags, Limit (bits 16-19)
    db 0x0       ; Base address, bits 24-31

; GDT for data segment.
; Same as code segment except for the type flags:
; type flags: (code)0 (expand down)0 (writable)1 (accessed)0 -> 0010b
gdt_data:
    dw 0xFFFF    ; Seg Limit (Length), bits 0-15
    dw 0x0       ; Base address, bits 0-15
    db 0x0       ; Base address, bits 16-23
    db 10010010b ; 1st flags, type flags
    db 11001111b ; 2nd flags, Limit (bits 16-19)
    db 0x0       ; Base address, bits 24-31

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of GDT, always one less of its true size
    dd gdt_start               ; Start address of GDT

; Define some handy constants for the GDT segment descriptor offsets, which
; are what segment registers must contain when in protected mode. For example,
; when we set DS = 0x10 in PM, the CPU knows that we mean it to use the
; segment described at offset 0x10 (i.e. 16 bytes) in our GDT, which in our
; case is the DATA segment (0x0 -> NULL; 0x08 -> CODE; 0x10 -> DATA)
CODE_SEG = gdt_code - gdt_start
DATA_SEG = gdt_data - gdt_start