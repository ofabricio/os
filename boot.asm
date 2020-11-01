format binary as 'img'

; At boot time the CPU runs in 16-bit real mode.
; Let's generate only 16-bit code from here on.
use16

; Typical lower memory layout after boot:
;
;          |                Free               |
; 0x100000 +-----------------------------------+
;          |           BIOS (256 kb)           |
;  0xC0000 +-----------------------------------+
;          |       Video Memory (128 kb)       |
;  0xA0000 +-----------------------------------+
;          | Extendend BIOS Data Area (639 kb) |
;  0x9FC00 +-----------------------------------+
;          |           Free (638 kb)           | <- This code stack is here.
;   0x7E00 +-----------------------------------+
;          |  Loaded Boot Sector (512 bytes)   | <- This code is loaded here.
;   0x7C00 +-----------------------------------+
;          |                                   |
;    0x500 +-----------------------------------+
;          |     BIOS Data Area (256 bytes)    |
;    0x400 +-----------------------------------+
;          |   Interrupt Vector Table (1 kb)   |
;      0x0 +-----------------------------------+
;
; The BIOS copies this 512 bytes boot sector to the address 0x7C00 and runs it.
;
; All the labels defined within this directive and the value of $ symbol
; are affected as if it was put at the given address.
org 0x7C00

    ; Init stack.
    mov bp, 0x7E00 + 512    ; Alloc 512 bytes for stack in Free space above boot sector.
    mov sp, bp

    ; BIOS sets DL to the drive number before calling the bootloader.
    mov bx, 0x9000          ; ES:BX = 0x0000:0x9000 = 0x9000
    mov dh, 2               ; Read 2 sectors.
    call disk_load

    ; Debug: print the first bytes of each loaded sector
    mov bx, [0x9000]
    call print_hex
    call printnl
    mov bx, [0x9000 + 512]
    call print_hex

    hlt


include 'diskload.asm'
include 'print_int.asm'

    ; Fill this sector up (510 bytes)
    rb 510 - ($ - $$)

    ; BIOS signature at end of the boot sector (2 bytes)
    dw 0xAA55

; -- Fill up some bytes just to check if we loaded these sectors.

    ; Boot sector = sector 1 of cyl 0 of head 0 of hdd 0
    times 256 dw 0xAA02     ; Sector 2 (512 bytes)
    times 256 dw 0xBB03     ; Sector 3 (512 bytes)
