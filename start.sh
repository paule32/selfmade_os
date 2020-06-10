#!/bin/bash
# -----------------------------------------------------------------------------
# Copyright (c) 2020 Jens Kallup - paule32 - non-profit
# all rights reserved.
# for non-commercial use only!
#
# This file is part of MyOs
# -----------------------------------------------------------------------------
echo "start qemu vm ..."
qemu-system-i386 -d in_asm -smp 2 -M pc -k de \
    -drive format=raw,file=boot4.bin,index=0,if=floppy \
    -vga std		\
    -localtime  	\
    -m 512		-name "MyOS 2020" > log.txt
