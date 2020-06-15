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


# --------------------------------------------------------------------
# example part: 4
# compile kernel files ...
# --------------------------------------------------------------------
nasm bootloader2.asm -f bin  -o bootloader2.bin
#
nasm kernel4.asm -f aout -o kernel4.o
nasm video16.asm -f aout -o video16.o
# -------------------------------------------------------------------
# prepare decoder + data image ...
# -------------------------------------------------------------------
nasm lzma.asm  -f aout -o lzma.o
ld  -melf_i386 -e RealMode -o lzma.bin -T boot4.ld

cat bootloader2.bin  > boot4.bin
cat lzma.bin        >> boot4.bin

sz=$(du -b boot4.bin | awk '{ print $1 }')
sz=$(echo "ibase=10; obase=16; ${sz}" | bc)
#
echo -e \
    "/* AUTOMATIC GENERATED - DONT EDIT IT !!! */"  \
    "\nOUTPUT_FORMAT(\"binary\")" \
    "\nENTRY(RealMode)"           \
    "\nSECTIONS\n{\n\t.text (0x7c00 + 0x${sz}) : {" \
    "\n\t\tkernel4.o"		\
    "\n\t\tvideo16.o"		\
    "\n\t}"			\
    "\n\t.data : { *(.data) }"	\
    "\n\t.bss  : { *(.bss)  }"	\
    "\n}\n" \
>   kernel4.ld
# --------------------------------------------------------------------
# create, and compress kenrel.bin
# --------------------------------------------------------------------
ld  -melf_i386 -e RealMode -o kernel.bin -T kernel4.ld
lz4 -z -9 kernel.bin -f       kernel.bin.lz4

# -------------------------------------------------------------------
# final part: 4
# create boot image ...
# -------------------------------------------------------------------
cat kernel.bin.lz4  >> boot4.bin


# part: final
#echo "make cd.iso ..."
#genisoimage -o myos.iso -R -J -D -copyright "(c) 2020 Jens Kallup - non-profit" \
#    kernel1.bin
