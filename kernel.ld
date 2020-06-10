OUTPUT_FORMAT("binary")
ENTRY(RealMode)
SECTIONS
{
    .text (0x7c00 + 512): {
        kernel4.o (.text)
        ckernel.o (.text)
    }
    .data       : { *(.data)   }
    .bss        : { *(.bss)    }
}
