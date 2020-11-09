format binary as 'img'

; At boot time the CPU runs in 16-bit real mode.
; Let's generate only 16-bit code from here on.
use16

BOOTSECTOR_OFFSET   = 0x7C00
PM_STACK_OFFSET     = 0x7C00        ; Protected Mode Stack offset.
KERNEL_OFFSET       = 0x7E00

; Typical lower memory layout after boot:
;
;      0x0 +-----------------------------------+
;          |   Interrupt Vector Table (1 kb)   |
;    0x400 +-----------------------------------+
;          |     BIOS Data Area (256 bytes)    |
;    0x500 +-----------------------------------+
;          |           Free (~30kb)            | <- This code stack is here.
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
org BOOTSECTOR_OFFSET       ; 0000h:7C00h

    boot_drive db 0x90      ; Store the boot drive number since DL may get overwritten.
    mov [boot_drive], dl    ; BIOS sets the boot drive in DL on boot.

    ; Init segments.
    xor ax, ax
    mov ds, ax
    mov ss, ax

    ; Init stack.
    mov bp, BOOTSECTOR_OFFSET ; Alloc stack in Free space below boot sector.
    mov sp, bp

    ; Read kernel from disk.
    mov ax, KERNEL_OFFSET shr 4 ; 07E0h -> 7E00h:0000h. We change the segment so that
    mov es, ax                  ; we can load 65kb. If we used 0000h:7E00h there would
                                ; be only ~30kb (7E00h - FFFFh) available in the segment.
    mov bx, 0               ; Offset [es:bx] to where the data loaded from disk will be stored in memory.
    mov al, 64              ; Read 64 sectors (~33kb). Need more sectors? Then: https://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)#LBA_in_Extended_Mode
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
    mov ebp, PM_STACK_OFFSET ; Update stack position.
    mov esp, ebp

    call enable_long_mode
    call set_gdt_64

    jmp CODE_SEG:lm_entrypoint


use64
lm_entrypoint:

    jmp kernel         ; Give control to the kernel


use16
include 'diskload.asm'
include 'print_int.asm'
;include 'print_32bits.asm'
use32
include 'gdt.asm'
include 'longmode.asm'

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
