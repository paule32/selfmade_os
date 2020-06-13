OUTPUT_FORMAT("binary")
ENTRY(RealMode)
SECTIONS
{
    .text (0x7c00 + 512): {
        kernel4.o
        video16.o
        ckernel.o
    }
    .data       : { *(.data)   }
    .bss        : { *(.bss)    }
}
