/* AUTOMATIC GENERATED - DONT EDIT IT !!! */ 
OUTPUT_FORMAT("binary") 
ENTRY(RealMode) 
SECTIONS
{
	.text (0x7c00 + 0x280) : { 
		kernel4.o 
		video16.o 
	} 
	.data : { *(.data) } 
	.bss  : { *(.bss)  } 
}

