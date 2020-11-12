%ifndef __DISKLOAD__
%define __DISKLOAD__

%include 'print.asm'

use16

; Load DH sectors from drive DL into ES:BX.
;
;    In: AL      Number of sectors to read.
;    In: DL      Drive number (0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2).
;    In: [ES:BX] Address where the data will be stored.
disk_load:
    push ax

    mov ah, 0x02    ; 0x02 = int 0x13 function "Read Disk Sectors": https://stanislavs.org/helppc/int_13-2.html
    mov ch, 0       ; Track/Cylinder number (0 to 1023).
    mov cl, 2       ; Sector number (1 to 17).
                    ; 1 is our boot sector, 2 is the first 'available' sector.
    mov dh, 0x00    ; Head number (0x0 .. 0xF)
    ; Caller sets AL, DL and [ES:BX]
    int 0x13        ; BIOS disk interrupt
    jc .disk_error

    ; 0x13 return:
    ; AH = status (see INT 13 disk status: https://stanislavs.org/helppc/int_13-1.html)
    ; AL = number of sectors read
    ; CF = 0 if successful
    ;    = 1 if error

    pop cx
    cmp al, cl
    jne .sectors_error
    ret

.disk_error:
    mov si, .DISK_ERROR
    call Print
    mov bx, ax          ; AH = error code
    call PrintHex       ; See the code at http://stanislavs.org/helppc/int_13-1.html
    hlt

.sectors_error:
    mov si, .SECTORS_ERROR
    call Print
    hlt

.DISK_ERROR db "Disk read error", 0xA, 0xD, 0
.SECTORS_ERROR db "Incorrect number of sectors read", 0xA, 0xD, 0

%endif
