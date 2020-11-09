use32

; Source: https://wiki.osdev.org/Setting_Up_Long_Mode

enable_long_mode:
    call detect_CPUID
    call detect_Long_Mode
    call setup_identity_paging
    ret


; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
; in the FLAGS register. If we can flip it, CPUID is available.
detect_CPUID:
 
    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax
 
    ; Copy to ECX as well for comparing later on
    mov ecx, eax
 
    ; Flip the ID bit
    xor eax, 1 shl 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd
 
    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax
 
    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit
    ; back if it was ever flipped).
    push ecx
    popfd
 
    ; Compare EAX and ECX. If they are equal then that means the bit wasn't
    ; flipped, and CPUID isn't supported.
    xor eax, ecx
    jz .no_CPUID
    ret
.no_CPUID:
    hlt


; Now that CPUID is available we have to check whether long mode can be used or not.
; Long mode can only be detected using the extended functions of CPUID (> 0x80000000),
; so we have to check if the function that determines whether long mode is available
; or not is actually available:
detect_Long_Mode:
    ; mov eax, 0x80000000
    ; cpuid
    ; cmp eax, 0x80000001
    ; jb .no_long_mode       ; It is less, there is no long mode.

    ; Now that we know that extended function is available we can use it to detect long mode:
    mov eax, 0x80000001
    cpuid
    test edx, 1 shl 29      ; Test if the LM-bit, which is bit 29, is set.
    jz .no_long_mode       ; They aren't, there is no long mode.
    ret
.no_long_mode:
    hlt


; Setup Identity Paging, i.e, physical memory is mapped identically to the virtual memory.
; PML4T[0] -> PDPT
; PDPT[0] -> PDT
; PDT[0] -> PT
; PT -> 0x00000000 - 0x00200000
setup_identity_paging:
    ; Clear the page tables.
    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax

    ; mov ecx, 4096
    ; rep stosd          ; Clear the memory.
    ; mov edi, cr3

    ; Now that the page are clear we're going to set up the tables,
    ; the page tables are going to be located at these addresses:
    ; PML4T - 0x1000
    ; PDPT  - 0x2000
    ; PDT   - 0x3000
    ; PT    - 0x4000
    ; So lets make PML4T[0] point to the PDPT and so on:
    mov dword [edi], 0x2003
    add edi, 0x1000
    mov dword [edi], 0x3003
    add edi, 0x1000
    mov dword [edi], 0x4003
    add edi, 0x1000
    ; If you haven't noticed already, I used a three.
    ; This simply means that the first two bits should be set.
    ; These bits indicate that the page is present and that it is readable as well as writable.
    ; Now all that's left to do is identity map the first two megabytes:
    mov ebx, 0x00000003
    mov ecx, 512
.set_next_entry:
    mov dword [edi], ebx
    add ebx, 0x1000
    add edi, 8
    loop .set_next_entry

    ; Now we should enable PAE-paging by setting the PAE-bit in the fourth control register:
    mov eax, cr4
    or eax, 1 shl 5      ; Set the PAE-bit, which is the 6th bit (bit 5).
    mov cr4, eax
    ; Now paging is set up, but it isn't enabled yet.
    ; We will enable it in the next lines.

    ; Entering compatibility mode:
    mov ecx, 0xC0000080          ; 0xC0000080 is the EFER MSR.
    rdmsr                        ; Read from the model-specific register.
    or eax, 1 shl 8               ; Set the LM-bit which is the 9th bit (bit 8).
    wrmsr                        ; Write to the model-specific register.

    ; Enable paging:
    mov eax, cr0
    or eax, 1 shl 31              ; Set the PG-bit, which is the 32nd bit (bit 31).
    mov cr0, eax

    ret
