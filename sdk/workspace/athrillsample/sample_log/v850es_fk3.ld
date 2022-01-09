

OUTPUT_FORMAT("elf32-v850-rh850","elf32-v850-rh850","elf32-v850-rh850")
OUTPUT_ARCH(v850-rh850)


MEMORY
{
	INTROM(raxi) : org = 0x00000000, len = 512k
	INTRAM(wax)  : org = 0x05FF7000, len = 10240k
	MMAP(wax)    : org = 0x07FF0000, len = 10240k
};

PROVIDE(__stack = 0);
PROVIDE(software_init_hook = 0);
PROVIDE(_software_term_hook = 0);
PROVIDE(hardware_init_hook = 0);
PROVIDE(hardware_term_hook = 0);

SECTIONS
{
	.vector : AT(0)
	{
		*(.vectors)
	} > INTROM

	.text :
	{
		__text = . ;
		*(.text)
		_etext = . ;
	} > INTROM

	.call_table_data ALIGN (4) :
	{
	PROVIDE(__ctbp = .);
	*(.call_table_data)
	} > INTROM

	.call_table_text :
	{
	*(.call_table_text)
	} > INTROM

	. = ALIGN(4);
	.rodata : {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
        *(.data.rel.ro)
        . = ALIGN(4);
        __init_array_start = .;
        *(SORT(.init_array.*))
        *(.init_array)
        __init_array_end = .;
        __fini_array_start = .;
        *(SORT(.fini_array.*))
        *(.fini_array)
        __fini_array_end = .;
	 } > INTROM

	_textend = .;

	. = ALIGN(4);
	__idata_start = . ;

	.data	:  AT(__idata_start)
	{
		. = ALIGN(4);
		__data_start = . ;
		*(.data)
		. = ALIGN(4);
		_edata	=  . ;
	} > INTRAM

	__idata_end = __idata_start + SIZEOF(.data);

	.bss	   :
	{
	  . = ALIGN(4);
	  __bss_start = .;
	  *(.bss)
	  *(COMMON)
	  . = ALIGN(4);
	  __bss_end = .;
	} > INTRAM

	.sdata ALIGN (4) :
	{
		PROVIDE (__gp = . + 0x8000);
		*(.sdata)
	} > INTRAM

	.tdata ALIGN (4) :
	{
		PROVIDE (__ep = .);
		*(.tbyte)
		*(.tcommon_byte)
		*(.tdata)
		*(.tbss)
		*(.tcommon)
	} > INTRAM

	.mmap_section :
	{
		. = ALIGN(4);
		*(.mmap_section)
		. = ALIGN(4);
	} > MMAP

	.comment 0 : { *(.comment) }
	.debug			0 : { *(.debug) }
	.line			0 : { *(.line) }
	.debug_srcinfo	0 : { *(.debug_srcinfo) }
	.debug_sfnames	0 : { *(.debug_sfnames) }
	.debug_aranges	0 : { *(.debug_aranges) }
	.debug_pubnames 0 : { *(.debug_pubnames) }
}
