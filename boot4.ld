OUTPUT_FORMAT("binary")
ENTRY(RealMode)
SECTIONS
{
    .text (0x7c00 + 512): {
	lzma.o
	ckernel.bin.lz4.o
    }
    .data       : { *(.data)   }
    .bss        : { *(.bss)    }
}
