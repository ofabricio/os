use16

; Load DH sectors from drive DL into ES:BX.
disk_load:
    pusha
    push dx

    mov ah, 0x02    ; 0x02 = int 0x13 function "Read Disk Sectors": https://stanislavs.org/helppc/int_13-2.html
    mov al, dh      ; Number of sectors to read (1 to 128). Caller sets it.
    mov cl, 2       ; Sector number (1 to 17).
                    ; 1 is our boot sector, 2 is the first 'available' sector.
    mov ch, 0       ; Track/Cylinder number (0 to 1023).
    ; DL = drive number. Caller sets it as a parameter and gets it from BIOS.
    ; (0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2)
    mov dh, 0x00    ; Head number (0x0 .. 0xF)

    ; [ES:BX] = pointer to buffer where the data will be stored. Caller sets it.
    int 0x13        ; BIOS disk interrupt
    jc .disk_error

    ; 0x13 return:
    ; AH = status (see INT 13 disk status: https://stanislavs.org/helppc/int_13-1.html)
    ; AL = number of sectors read
    ; CF = 0 if successful
    ;    = 1 if error

    pop dx
    cmp al, dh
    jne .sectors_error
    popa
    ret

.disk_error:
    mov bx, .DISK_ERROR
    call print
    call printnl
    mov dx, ax          ; AH = error code
    call print_hex      ; See the code at http://stanislavs.org/helppc/int_13-1.html
    jmp .disk_loop

.sectors_error:
    mov bx, .SECTORS_ERROR
    call print

.disk_loop:
    jmp $


.DISK_ERROR: db "Disk read error", 0
.SECTORS_ERROR: db "Incorrect number of sectors read", 0
