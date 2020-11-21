; At boot time the CPU runs in 16-bit real mode.
; Let's generate only 16-bit code from here on.
use16

BOOTSECTOR   equ 0x7C00
PM_STACK     equ 0x7C00             ; Protected Mode Stack offset.
FREESPACE    equ BOOTSECTOR + 512   ; 0x7E00
KERNEL       equ FREESPACE + 512    ; 0x8000

; Typical lower memory layout after boot:
;
;      0x0 +-----------------------------------+
;          |   Interrupt Vector Table (1 kb)   |
;    0x400 +-----------------------------------+
;          |     BIOS Data Area (256 bytes)    |
;    0x500 +-----------------------------------+
;          |           Free (~30kb)            | <- Boot sector stack is here.
;   0x7C00 +-----------------------------------+
;          |  Loaded Boot Sector (512 bytes)   | <- This code first sector is automatically loaded here by BIOS.
;   0x7E00 +-----------------------------------+
;          |           Free (~622 kb)          | <- Kernel is loaded here.
;  0x9FC00 +-----------------------------------+
;          |  Extendend BIOS Data Area (1 kb)  |
;  0xA0000 +-----------------------------------+
;          |       Video Memory (~131 kb)      |
;  0xC0000 +-----------------------------------+
;          |          BIOS (~262 kb)           |
; 0x100000 +-----------------------------------+
;          |                Free               |
;
; The BIOS copies this 512 bytes boot sector to the address 0x7C00 and runs it.
;
; All the labels defined within this directive and the value of $ symbol
; are affected as if it was put at the given address.
org BOOTSECTOR              ; 0000h:7C00h

Main:

    jmp 0x0000:.FlushCS     ; Some BIOS' may load us at 0x0000:0x7C00 while other may load us at 0x07C0:0x0000.
                            ; Do a far jump to fix this issue, and reload CS to 0x0000.

.FlushCS:
    BootDrive db 0x90       ; Store the boot drive number since DL may get overwritten.
    mov [BootDrive], dl     ; BIOS sets the boot drive in DL on boot.

    ; Init segments.
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Init stack.
    mov bp, BOOTSECTOR      ; Set the stack in the Free space below the boot sector.
    mov sp, bp

    ; Read kernel from disk.
    mov bx, FREESPACE       ; Offset [ES:BX] to where the data loaded from disk will be stored in memory.
    mov al, 2               ; Read up to 2 sectors (1kb) starting from Sector2 (because Sector1 is boot sector).
    mov dl, [BootDrive]
    call disk_load

    jmp FREESPACE


%include 'diskload.asm'


    ; Fill this sector up (510 bytes)
    times 510 - ($ - $$) db 0

    ; BIOS signature at end of the boot sector (2 bytes)
    dw 0xAA55

; ---
;   Here's the end of Sector 1 (512 bytes) and start of Sector 2 (512 bytes).
;   Setup code offset is here.
; ---

    ; The "jmp FREESPACE" above will land here.

FreeSpace:

    ; mov bx, $
    ; call PrintHex
    ; hlt

    ; Enable A20 Line.

    in al, 0x92
    or al, 2
    out 0x92, al

    ; Switch to LM.

    mov edi, 0x1000          ; Page Table address.
    call EnableLongMode

    jmp CODE_SEG:LongMode    ; Load CS with 64-bit segment and flush the instruction cache.
                             ; Make a far jump (i.e. to a new segment) to our 64-bit
                             ; code. This also forces the CPU to flush its cache of
                             ; pre-fetched and real-mode decoded instructions,
                             ; which can cause problems.


%include 'gdt.asm'
%include 'longmode.asm'


use64
LongMode:

    mov ax, DATA_SEG
    mov ds, ax          ; DS is ignored in Long Mode
    mov es, ax          ; ES is ignored in Long Mode
    mov fs, ax
    mov gs, ax
    mov ss, ax          ; SS is ignored in Long Mode
    mov ebp, PM_STACK ; Update stack position.
    mov esp, ebp

    ; Give control to the kernel
    jmp KERNEL

    ; Fill this sector up (512 bytes)
    times 512 - ($ - FreeSpace) db 0

; ---
;   Here's the end of Sector 2 (512 bytes) and start of Sector 3 (512 bytes).
;   Kernel offset is here.
; ---
