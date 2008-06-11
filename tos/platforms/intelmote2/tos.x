OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm",
	      "elf32-littlearm")
OUTPUT_ARCH(arm)
MEMORY
{
  text   (rx)   : ORIGIN = 0, LENGTH = 64M
  data   (rw!x) : ORIGIN = 0x5c000000, LENGTH = 256K
}
SECTIONS
{
  .text           :
  {
    *(.vectors)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    *(.rodata.*)
    *(.rodata)    
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.glue_7t) *(.glue_7)
    KEEP (*(.fini))
  } >text
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  .data           : AT (ADDR(.text) + SIZEOF(.text))
  {
    __data_start = . ;
    *(.data .data.* .gnu.linkonce.d.*)
    *(.gnu.linkonce.d*)
    _edata = .;
    PROVIDE (edata = .);
  } > data
  .bss SIZEOF(.data) + ADDR(.data) :
  {
    __bss_start = .;
    __bss_start__ = .;
   *(.dynbss)
   *(.bss .bss.* .gnu.linkonce.b.*)
   *(COMMON)
    _end = .;
    _bss_end__ = . ; __bss_end__ = . ; __end__ = . ;
    PROVIDE (end = .);
  } >data
   __data_load_start = LOADADDR(.data);
   __data_load_end = __data_load_start + SIZEOF(.data);
  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
    .stack         0x80000 :
  {
    _stack = .;
    *(.stack)
  }
  /DISCARD/ : { *(.note.GNU-stack) }
}
