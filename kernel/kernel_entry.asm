BITS 64

SECTION .text

EXTERN main

GLOBAL _start
_start:

    call main
    hlt
