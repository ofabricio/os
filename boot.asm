format binary as 'img'

; At boot time the CPU runs in 16-bit real mode.
; Let's generate only 16-bit code from here on.
use16

; Typical lower memory layout after boot:
;
;          |                Free               |
; 0x100000 +-----------------------------------+
;          |          BIOS (~262 kb)           |
;  0xC0000 +-----------------------------------+
;          |       Video Memory (~131 kb)      |
;  0xA0000 +-----------------------------------+
;          |  Extendend BIOS Data Area (1 kb)  |
;  0x9FC00 +-----------------------------------+
;          |           Free (~622 kb)          |
;   0x7E00 +-----------------------------------+
;          |  Loaded Boot Sector (512 bytes)   | <- This code first sector is automatically loaded here by BIOS.
;   0x7C00 +-----------------------------------+
;          |           Free (~30kb)            | <- This code stack is here.
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
org 0x7C00  ; 0000h:7C00h

KERNEL_OFFSET = 0x7E00

    boot_drive db 0x90      ; Store the boot drive number since DL may get overwritten
    mov [boot_drive], dl    ; BIOS sets the boot drive in DL on boot.
                            ; Let's save it since it may get overwritten.

    ; Init segments.
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; Init stack.
    mov bp, 0x7C00          ; Alloc 512 bytes for stack in Free space above boot sector.
    mov sp, bp

    ; Read kernel from disk.
    mov bx, KERNEL_OFFSET   ; Address to where the data loaded from disk will be stored in memory.
    mov dh, 15              ; Read 15 sectors.
    mov dl, [boot_drive]
    call disk_load

    ; Enable A20 Line.

    in al, 0x92
    or al, 2
    out 0x92, al

    ; Switching to PM.

    cli     ; We must switch off interrupts until we have
            ; set-up the protected mode interrupt vector
            ; otherwise interrupts will run riot.

    lgdt [gdt_descriptor] ; Load our global descriptor table, which defines
                          ; the protected mode segments (e.g. for code and data)

    mov eax, cr0          ; To make the switch to protected mode, we set
    or eax, 1             ; the first bit of CR0, a control register.
    mov cr0, eax

    jmp CODE_SEG:pm_entrypoint  ; Make a far jump (i.e. to a new segment) to our 32-bit
                                ; code. This also forces the CPU to flush its cache of
                                ; pre-fetched and real-mode decoded instructions,
                                ; which can cause problems.

use32
pm_entrypoint:

    ; Initialise registers and the stack once in PM.
    mov ax, DATA_SEG    ; Now in PM, our old segments are meaningless,
    mov ds, ax          ; so we point our segment registers to the
    mov ss, ax          ; data selector we defined in our GDT.
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000    ; Update our stack position so it is right
    mov esp, ebp        ; at the top of the free space.

    ; Enter Long Mode.
    call detect_CPUID
    call detect_Long_Mode
    call setup_identity_paging
    call set_gdt_64

    jmp CODE_SEG:lm_entrypoint


use64
lm_entrypoint:

    jmp kernel         ; Give control to the kernel


include 'diskload.asm'
include 'print_int.asm'
;include 'print_32bits.asm'
use32
include 'gdt.asm'
include 'cpuid.asm'

    ; Fill this sector up (510 bytes)
    rb 510 - ($ - $$)

    ; BIOS signature at end of the boot sector (2 bytes)
    dw 0xAA55

; ---
;       Here's the end of the Sector 1 (512 bytes) and the start of Sector 2,
;       which is loaded in KERNEL_OFFSET in memory.
; ---

use64
org KERNEL_OFFSET

kernel:

    mov edi, 0xB8000
    mov rax, 0x1F201F201F201F20
    mov ecx, 500
    rep stosq                     ; Clear the screen.

    ; mov ebx, msg_prot_mode
    ; call print_string_pm

    hlt

    ; msg_prot_mode db "Landed in 32-bit Protected Mode", 0
