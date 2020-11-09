# all: kernel.bin

# os-image: boot.img kernel.bin
# 	copy /b boot.img + kernel.bin os.img

# boot.img: boot.img
# 	FASM.EXE boot.asm

# kernel.bin: test/kernel_entry.o test/kernel.o
# 	ld -o kernel.bin -Ttext 0x1000 test/kernel_entry.o test/kernel.o --oformat binary

# kernel.o: test/kernel.c
# 	gcc -ffreestanding -c test/kernel.c -o test/kernel.o

# kernel_entry.o: test/kernel_entry.asm
# 	FASM.EXE test/kernel_entry.asm


all: os-image

os-image: bin\boot.bin
	copy /b bin\boot.bin bin\os.img

boot:
	FASM.EXE boot\boot.asm bin\boot.bin
