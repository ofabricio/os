OUTPUT_FORMAT(elf64-x86-64)

ENTRY(_start)

INPUT
(
    bin/kernel_entry.o
    bin/kernel.o
)

OUTPUT
(
    bin/kernel.elf
)

SECTIONS
{
    . = 0x8000;

    .text :
    {
        *(.text)
    }
}
