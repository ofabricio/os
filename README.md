My Operating System.

## The boot process

When you start your computer:

- The BIOS loads the first 512 bytes from the boot device.
- The BIOS checks for the value `0x55AA` at the end.
- The BIOS moves the 512 bytes to the address `0x7C00` and runs it.

That 512 bytes is known as a boot loader.

## The boot loader purpose

- It loads the actual operating system code into memory.
- It changes the CPU into protected mode.
- It then runs the operating system code.

## Note

- At boot time the CPU runs in 16 bit real mode.

## Boot loader code

Check [boot.asm](boot.asm)

## Emulator

Use either [bochs](http://bochs.sourceforge.net) or [qemu](https://www.qemu.org/download) emulators to run this code.
See tutorial [here]() on how to set them up.

## Code

The code is in [FASM](https://flatassembler.net) syntax.
