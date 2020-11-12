# Build the OS with kernel in c.

all: os-image

os-image: clean boot.bin kernel.bin
	cat bin/boot.bin bin/kernel.bin > bin/os.img

kernel.bin: kernel_entry.o kernel.o
	x86_64-elf-ld -T linker.ld
	objcopy -j .text -O binary bin/kernel.elf bin/kernel.bin

kernel.asm.o:
	nasm kernel/kernel.asm -f elf64 -o bin/kernel.o

kernel.o: kernel/kernel.c
	x86_64-elf-gcc -m64 -ffreestanding -nostdlib -mno-red-zone -c $^ -o bin/kernel.o

kernel_entry.o: kernel/kernel_entry.asm
	nasm $^ -f elf64 -o bin/kernel_entry.o

boot.bin:
	nasm -i boot/ -f bin boot/boot.asm -o bin/boot.bin

clean:
	rm -f bin/*.elf bin/*.bin bin/*.o bin/*.img

boot-only: boot.bin
	cp bin/boot.bin bin/os.img

# Useful commands:
# objdump -b binary -m i386:x86-64 -M intel -D bin/kernel.bin
# hexdump bin/kernel.bin
