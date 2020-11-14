BITS 64

GLOBAL _start:

EXTERN main

SECTION .text

_start:

    call main
    hlt
