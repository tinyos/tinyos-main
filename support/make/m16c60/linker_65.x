/*--------------------------------------------------------------------------------*/
/*
 * Copyright (c) 2010 Eistec AB.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 *--------------------------------------------------------------------------------*/

MEMORY
{

  RAM (wx) : ORIGIN = 0x00400, LENGTH =  47K
  DBG (rx) : ORIGIN = 0x13000, LENGTH =   4K
  ROM (rx) : ORIGIN = 0x80000, LENGTH = 512K

}

__ram = 0x00400; __ram_size =  47K; __ram_end = __ram + __ram_size;
__rom = 0x80000; __rom_size = 512K; __rom_end = __rom + __rom_size;

__ustack = __ram_end - 0x00200;         /* Size of interrupt stack.               */
__istack = __ram_end;

PROVIDE(__vector_0 = __vector_72);
PROVIDE(__vector_1 = __vector_72);
PROVIDE(__vector_2 = __vector_72);
PROVIDE(__vector_3 = __vector_72);
PROVIDE(__vector_4 = __vector_72);
PROVIDE(__vector_5 = __vector_72);
PROVIDE(__vector_6 = __vector_72);
PROVIDE(__vector_7 = __vector_72);
PROVIDE(__vector_8 = __vector_72);
PROVIDE(__vector_9 = __vector_72);
PROVIDE(__vector_10 = __vector_72);
PROVIDE(__vector_11 = __vector_72);
PROVIDE(__vector_12 = __vector_72);
PROVIDE(__vector_13 = __vector_72);
PROVIDE(__vector_14 = __vector_72);
PROVIDE(__vector_15 = __vector_72);
PROVIDE(__vector_16 = __vector_72);
PROVIDE(__vector_17 = __vector_72);
PROVIDE(__vector_18 = __vector_72);
PROVIDE(__vector_19 = __vector_72);
PROVIDE(__vector_20 = __vector_72);
PROVIDE(__vector_21 = __vector_72);
PROVIDE(__vector_22 = __vector_72);
PROVIDE(__vector_23 = __vector_72);
PROVIDE(__vector_24 = __vector_72);
PROVIDE(__vector_25 = __vector_72);
PROVIDE(__vector_26 = __vector_72);
PROVIDE(__vector_27 = __vector_72);
PROVIDE(__vector_28 = __vector_72);
PROVIDE(__vector_29 = __vector_72);
PROVIDE(__vector_30 = __vector_72);
PROVIDE(__vector_31 = __vector_72);
PROVIDE(__vector_32 = __vector_72);
PROVIDE(__vector_33 = __vector_72);
PROVIDE(__vector_34 = __vector_72);
PROVIDE(__vector_35 = __vector_72);
PROVIDE(__vector_36 = __vector_72);
PROVIDE(__vector_37 = __vector_72);
PROVIDE(__vector_38 = __vector_72);
PROVIDE(__vector_39 = __vector_72);
PROVIDE(__vector_40 = __vector_72);
PROVIDE(__vector_41 = __vector_72);
PROVIDE(__vector_42 = __vector_72);
PROVIDE(__vector_43 = __vector_72);
PROVIDE(__vector_44 = __vector_72);
PROVIDE(__vector_45 = __vector_72);
PROVIDE(__vector_46 = __vector_72);
PROVIDE(__vector_47 = __vector_72);
PROVIDE(__vector_48 = __vector_72);
PROVIDE(__vector_49 = __vector_72);
PROVIDE(__vector_50 = __vector_72);
PROVIDE(__vector_51 = __vector_72);
PROVIDE(__vector_52 = __vector_72);
PROVIDE(__vector_53 = __vector_72);
PROVIDE(__vector_54 = __vector_72);
PROVIDE(__vector_55 = __vector_72);
PROVIDE(__vector_56 = __vector_72);
PROVIDE(__vector_57 = __vector_72);
PROVIDE(__vector_58 = __vector_72);
PROVIDE(__vector_59 = __vector_72);
PROVIDE(__vector_60 = __vector_72);
PROVIDE(__vector_61 = __vector_72);
PROVIDE(__vector_62 = __vector_72);
PROVIDE(__vector_63 = __vector_72);
PROVIDE(__vector_64 = __vector_72);
PROVIDE(__vector_65 = __vector_72);
PROVIDE(__vector_66 = __vector_72);
PROVIDE(__vector_67 = __vector_72);
PROVIDE(__vector_68 = __vector_72);
PROVIDE(__vector_69 = __vector_72);
PROVIDE(__vector_70 = __vector_72);
PROVIDE(__vector_71 = __vector_72);
PROVIDE(_watchdog = __vector_72);

SECTIONS
{
  
      .start : {
            *(.init0);
    } > ROM AT > ROM
  
  .data :
  {
    *(.data)
    *(.data.*)
    *(.rodata)
    *(.rodata.*)
    *(.plt)
    *(.eh_frame_hdr)
    *(.eh_frame)
  } > RAM AT > ROM
  
  __data_rom_start = LOADADDR(.data);
  __data_start = ADDR(.data);
  __data_count = SIZEOF(.data);
  
  .bss :
  {
    *(.bss)
    *(COMMON)
  } > RAM AT > RAM
  
  __bss_start = ADDR(.bss);
  __bss_count = SIZEOF(.bss);
  
  PROVIDE(_end = .);                    /* Provide heap pointer for sbrk().       */
  
  .text :
  {
    *(.init)
    *(.fini)
    *(.text)
    *(.text.*)
    __rvectors = .;                     /* ensure faster interrupt execution.     */
    *(.rvectors)
  } > ROM AT > ROM
  
  .debugger 0x13000 : AT(0x13000)       /* On-chip debugger monitor area.         */
  {
    __debugger = .;
    *(.debugger)
  }
  
  .fvectors 0xFFFDC : AT(0xFFFDC)       /* Fixed vector table.                    */
  {                                     /* Must be placed on address 0xFFFDC.     */
    __fvectors = .;
    *(.fvectors)
  }
  
}
