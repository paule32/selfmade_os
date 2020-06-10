#!/bin/bash
# -----------------------------------------------------------------------------
# Copyright (c) 2020 Jens Kallup - paule32 - non-profit
# all rights reserved.
# for non-commercial use only!
#
# This file is part of MyOs
# -----------------------------------------------------------------------------
echo "compile files..."
# part: 1
nasm kernel1.asm    -f bin -o boot1.bin

# part: 2
nasm kernel2.asm     -f bin -o kernel2.bin
nasm bootloader1.asm -f bin -o bootloader1.bin
cat bootloader1.bin > boot2.bin
cat kernel2.bin    >> boot2.bin

# part: 3
nasm bootloader2.asm -f bin -o bootloader2.bin
nasm kernel3.asm     -f bin -o kernel3.bin
#gdt.inc
cat bootloader2.bin > boot3.bin
cat kernel3.bin    >> boot3.bin

# part: 4
nasm bootloader2.asm -f bin  -o bootloader2.bin
nasm kernel4.asm     -f aout -o kernel4.o
#gcc -m32 -O3 -fno-plt -fno-pic -nostdlib -ffreestanding -c ckernel.c -o ckernel.o
ld  -melf_i386 -e RealMode -o ckernel.bin -T kernel.ld
#cp a.out ckernel.bin
#rm -rf a.out
cat bootloader2.bin > boot4.bin
cat ckernel.bin    >> boot4.bin

# part: final
echo "make cd.iso ..."
#genisoimage -o myos.iso -R -J -D -copyright "(c) 2020 Jens Kallup - non-profit" \
#    kernel1.bin
