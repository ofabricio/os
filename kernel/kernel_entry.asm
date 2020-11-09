format ELF64

section '.text' executable

public _start
_start:

extrn main

    call main
    hlt
