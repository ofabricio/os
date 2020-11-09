# Build the OS with kernel in c.

all: os-image

os-image: boot.bin kernel.bin
	cat bin/boot.bin bin/kernel.bin > bin/os.img

kernel.bin: kernel_entry.o kernel.o
	x86_64-elf-ld --oformat binary -Ttext 0x7E00 bin/kernel_entry.o bin/kernel.o -o bin/kernel.bin

kernel.o: kernel/kernel.c
	x86_64-elf-gcc -m64 -ffreestanding -c $^ -o bin/kernel.o
	objcopy --remove-section .eh_frame bin/kernel.o

kernel_entry.o: kernel/kernel_entry.asm
	fasm.x64 $^ bin/kernel_entry.o

boot.bin:
	fasm.x64 boot/boot.asm bin/boot.bin

clean:
	rm bin/*.bin bin/*.o bin/*.img

boot-only: boot.bin
	cp bin/boot.bin bin/os.img

# Useful commands:
# objdump -b binary -m i386:x86-64 -M intel -D bin/kernel.bin
# hexdump bin/kernel.bin
