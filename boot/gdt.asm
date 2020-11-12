%ifndef __GDT__
%define __GDT__

; GDT definition for 64-bits.
;
; Global Descriptor Table (GDT) is an array of descriptors
; to specify system wide resource.
;
; See more: https://stackoverflow.com/a/37556305/1124350
;           https://wiki.osdev.org/GDT_Tutorial

GDT:

    ; Null descriptor (0x00).
    dq 0

    ; Code-Segment Descriptor (0x08).
    ;   Base = 0x00000000
    ;   Limit (length) = 0 (Limit is ignored in 64-bits mode).
.Code:
    dw 0         ; Seg Limit (Length), bits 0-15
    dw 0         ; Base address, bits 0-15
    db 0         ; Base address, bits 16-23
    db 10011010b ; = 0x9A
                 ; 1001b -> 1st flags: (present)1 (privilege)00 (descriptor type)1
                 ; 1010b -> Type flags: (code)1 (conforming)0 (readable)1 (accessed)0
    db 00100000b ; 0010b -> 2nd flags: (granularity)0 (32-bit default)0 (64-bit segment)1 (AVL)0
                 ; 1111b -> Seg Limit (bits 16-19)
    db 0         ; Base address, bits 24-31

    ; Data-Segment Descriptor (0x10).
    ;   Base = 0x00000000
    ;   Limit (length) = 0 (Limit is ignored in 64-bits mode).
.Data:
    dw 0         ; Seg Limit (Length), bits 0-15
    dw 0         ; Base address, bits 0-15
    db 0         ; Base address, bits 16-23
    db 10010010b ; = 0x92
                 ; 1001b -> 1st flags: (present)1 (privilege)00 (descriptor type)1
                 ; 0010b -> Type flags: (code)0 (conforming)0 (read/write)1 (accessed)0
    db 00100000b ; 0010b -> 2nd flags: (granularity)0 (32-bit default)0 (64-bit segment)1 (AVL)0
                 ; 1111b -> Seg Limit (bits 16-19)
    db 0         ; Base address, bits 24-31

ALIGN 4          ; Padding to make the "address of the GDT" field
    dw 0         ; aligned on a 4-byte boundary.

.Descriptor:
    ; Size:
    ;       The size is the size of the table subtracted by 1.
    ;       This is because the maximum value of size is 65535,
    ;       while the GDT can be up to 65536 bytes (a maximum of 8192 entries).
    ;       Further no GDT can have a size of 0.
    ; Base addres:
    ;       Linear address of the table itself, which means that paging applies.
    dw $ - GDT - 1      ; 16-bit Size (Limit) of GDT.
    dd GDT              ; 32-bit Base address of GDT (CPU will zero extend to 64-bit).

; Define some handy constants for the GDT segment descriptor offsets, which
; are what segment registers must contain when in protected mode. For example,
; when we set DS = 0x10 in PM, the CPU knows that we mean it to use the
; segment described at offset 0x10 (i.e. 16 bytes) in our GDT, which in our
; case is the DATA Segment (0x0 -> NULL; 0x08 -> CODE; 0x10 -> DATA)
CODE_SEG equ .Code - GDT    ; 0x08
DATA_SEG equ .Data - GDT    ; 0x10

%endif
