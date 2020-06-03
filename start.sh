#!/bin/bash
# -----------------------------------------------------------------------------
# Copyright (c) 2020 Jens Kallup - paule32 - non-profit
# all rights reserved.
# for non-commercial use only!
#
# This file is part of MyOs
# -----------------------------------------------------------------------------
echo "start qemu vm ..."
qemu-system-x86_64 -smp 4 -M pc -k de \
    -drive format=raw,file=boot4.bin,index=0,if=floppy \
    -vga std		\
    -localtime  	\
    -m 512		-name "MyOS 2020"
