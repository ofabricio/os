%define PAGE_PRESENT    1 << 0
%define PAGE_WRITE      1 << 1

; See: https://wiki.osdev.org/Entering_Long_Mode_Directly
; See: https://wiki.osdev.org/Paging

%include 'gdt.asm'
%include 'print.asm'

use16

ALIGN 4
IDT:
    .Length     dw 0
    .Base       dd 0


; Function to switch directly to Long Mode from Real Mode.
; Identity maps the first 2MiB.
;
;   In: ES:EDI    Should point to a valid page-aligned 16KiB buffer, for the PML4, PDPT, PD and a PT.
;   In: SS:ESP    Should point to memory that can be used as a small (1 uint32_t) stack
EnableLongMode:

    call CheckLongMode

    cld

    ; Zero out the 16KiB buffer.
    ; Since we are doing a rep stosd, count should be bytes/4.   
    push di                           ; REP STOSD alters DI.
    mov ecx, 0x1000
    xor eax, eax
    cld
    rep stosd
    pop di                            ; Get DI back.

    ; Build the Page Map Level 4.
    ; es:di points to the Page Map Level 4 table.
    lea eax, [es:di + 0x1000]         ; Put the address of the Page Directory Pointer Table in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writable flag.
    mov [es:di], eax                  ; Store the value of EAX as the first PML4E.

    ; Build the Page Directory Pointer Table.
    lea eax, [es:di + 0x2000]         ; Put the address of the Page Directory in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writable flag.
    mov [es:di + 0x1000], eax         ; Store the value of EAX as the first PDPTE.

    ; Build the Page Directory.
    lea eax, [es:di + 0x3000]         ; Put the address of the Page Table in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writeable flag.
    mov [es:di + 0x2000], eax         ; Store to value of EAX as the first PDE.

    push di                           ; Save DI for the time being.
    lea di, [di + 0x3000]             ; Point DI to the page table.
    mov eax, PAGE_PRESENT | PAGE_WRITE; Move the flags into EAX - and point it to 0x0000.

    ; Build the Page Table.
.LoopPageTable:
    mov [es:di], eax
    add eax, 0x1000
    add di, 8
    cmp eax, 0x200000       ; If we did all 2MiB, end.
    jb .LoopPageTable

    pop di                  ; Restore DI.

    ; Disable IRQs
    mov al, 0xFF            ; Out 0xFF to 0xA1 and 0x21 to disable all IRQs.
    out 0xA1, al
    out 0x21, al

    ; cli     ; We must switch off interrupts until we have
    ;         ; set-up the protected mode interrupt vector
    ;         ; otherwise interrupts will run riot.

    nop
    nop

    lidt [IDT]              ; Load a zero length IDT so that any NMI causes a triple fault.

    ; Enter Long Mode.

    mov eax, 10100000b      ; Set the PAE and PGE bit.
    mov cr4, eax

    mov edx, edi            ; Point CR3 at the PML4.
    mov cr3, edx

    mov ecx, 0xC0000080     ; Read from the EFER MSR. 
    rdmsr

    or eax, 0x00000100      ; Set the LME bit.
    wrmsr

    lgdt [GDT.Descriptor]   ; Load GDT.Pointer defined below.

    ; Enable paging
    mov ebx, cr0            ; Activate long mode by enabling
    or ebx, 0x80000001       ; paging and protection simultaneously.
    mov cr0, ebx

    ret


; Checks wheter CPU supports Long Mode or not.
;
;   Out: ret    Returns if Long Mode is supported.
;   Out: hlt    Halts and print a message if LM is not supported.
CheckLongMode:

    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    pushfd              ; Copy FLAGS in to EAX via stack.
    pop eax
    mov ecx, eax        ; Copy to ECX as well for comparing later on.

    xor eax, 1 << 21    ; Flip the ID bit

    push eax            ; Copy EAX to FLAGS via the stack
    popfd

    pushfd              ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit
    ; back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit wasn't
    ; flipped, and CPUID isn't supported.
    xor eax, ecx
    jz .NoLongMode

    ; Now that CPUID is available we have to check whether long mode can be used or not.
    ; Long mode can only be detected using the extended functions of CPUID (> 0x80000000),
    ; so we have to check if the function that determines whether long mode is available
    ; or not is actually available:

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .NoLongMode          ; It is less, there is no long mode.

    ; Now that we know that extended function is available we can use it to detect long mode:
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29       ; Test if the LM-bit, which is bit 29, is set.
    jz .NoLongMode          ; They aren't, there is no long mode.

    ret
.NoLongMode:
    mov si, NoLongModeMsg
    call Print
    hlt

NoLongModeMsg db 'error: LM not supported', 0xA, 0xD, 0
