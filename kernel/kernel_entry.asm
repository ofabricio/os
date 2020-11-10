use64

section	.text

global _start:
_start:

extern main

    call main
    hlt
