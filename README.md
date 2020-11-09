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

Check [boot.asm](boot/boot.asm)

## Emulator

Use either [bochs](http://bochs.sourceforge.net) or [qemu](https://www.qemu.org/download) emulators to run this code.
See tutorial [here]() on how to set them up.

## Code

The code is in [FASM](https://flatassembler.net) syntax.

## Windows cross-compiler

First install WSL:

1. Open Windows Store. Seach "Ubuntu LTS" and install it.
1. Go to "Turn Windows feature on or off" and enable "Windows Subsystem for Linux". Restart the computer.

Open Ubuntu terminal and:

```
sudo apt update
sudo apt install -y \
                 build-essential \
                 bison \
                 flex \
                 libgmp3-dev \
                 libmpc-dev \
                 libmpfr-dev \
                 textinfo

export PREFIX="/usr/local/x86_64elfgcc"
export PATH="$PREFIX/bin:$PATH"
export TARGET=x86_64-elf

mkdir /tmp/src
cd /tmp/src
curl -O http://ftp.gnu.org/gnu/binutils/binutils-2.35.1.tar.gz
curl -O http://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz
tar xf binutils-2.35.1.tar.gz
tar xf gcc-10.2.0.tar.gz

mkdir binutils-build
cd binutils-build
../binutils-2.35.1/configure --target=$TARGET --prefix=$PREFIX --enable-interwork --enable-multilib --disable-nls --disable-werr 2>&1 | \
   tee binutils-build.log
sudo make all install 2>&1 | tee make.log

cd /tmp/src
mkdir gcc-build
cd gcc-build
../gcc-10.2.0/configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-libssp --enable-language=c++ --without-headers 2>&1 | \
   tee gcc-build.log
sudo make all-gcc
sudo make all-target-libgcc
sudo make install-gcc
sudo make install-target-libgcc

# Binaries are installed in:
# ls /usr/local/x86_64elfgcc/bin
```
