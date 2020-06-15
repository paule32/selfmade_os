OUTPUT_FORMAT("binary")
ENTRY(RealMode)
SECTIONS
{
    .text ( 0x7e00 + 1 ): {
        kernel4.o
        video16.o
        ckernel.o
    }
    .data       : { *(.data)   }
    .bss        : { *(.bss)    }
}
