/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
/**
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Per Lindgren
 * @author Johan Eriksson
 * @author Johan Nordlander
 * @author Simon Aittamaa
 */

ENTRY(_start)

MEMORY {
	ram (rw) : o = 0x0000400, l = 31k
	flash (rx) : o = 0x00a0000, l = 384k
}

/* Provide any vector symbols not defined. */
PROVIDE(__vector_0 = __vector_default);
PROVIDE(__vector_1 = __vector_default);
PROVIDE(__vector_2 = __vector_default);
PROVIDE(__vector_3 = __vector_default);
PROVIDE(__vector_4 = __vector_default);
PROVIDE(__vector_5 = __vector_default);
PROVIDE(__vector_6 = __vector_default);
PROVIDE(__vector_7 = __vector_default);
PROVIDE(__vector_8 = __vector_default);
PROVIDE(__vector_9 = __vector_default);
PROVIDE(__vector_10 = __vector_default);
PROVIDE(__vector_11 = __vector_default);
PROVIDE(__vector_12 = __vector_default);
PROVIDE(__vector_13 = __vector_default);
PROVIDE(__vector_14 = __vector_default);
PROVIDE(__vector_15 = __vector_default);
PROVIDE(__vector_16 = __vector_default);
PROVIDE(__vector_17 = __vector_default);
PROVIDE(__vector_18 = __vector_default);
PROVIDE(__vector_19 = __vector_default);
PROVIDE(__vector_20 = __vector_default);
PROVIDE(__vector_21 = __vector_default);
PROVIDE(__vector_22 = __vector_default);
PROVIDE(__vector_23 = __vector_default);
PROVIDE(__vector_24 = __vector_default);
PROVIDE(__vector_25 = __vector_default);
PROVIDE(__vector_26 = __vector_default);
PROVIDE(__vector_27 = __vector_default);
PROVIDE(__vector_28 = __vector_default);
PROVIDE(__vector_29 = __vector_default);
PROVIDE(__vector_30 = __vector_default);
PROVIDE(__vector_31 = __vector_default);
PROVIDE(__vector_32 = __vector_default);
PROVIDE(__vector_33 = __vector_default);
PROVIDE(__vector_34 = __vector_default);
PROVIDE(__vector_35 = __vector_default);
PROVIDE(__vector_36 = __vector_default);
PROVIDE(__vector_37 = __vector_default);
PROVIDE(__vector_38 = __vector_default);
PROVIDE(__vector_39 = __vector_default);
PROVIDE(__vector_40 = __vector_default);
PROVIDE(__vector_41 = __vector_default);
PROVIDE(__vector_42 = __vector_default);
PROVIDE(__vector_43 = __vector_default);
PROVIDE(__vector_44 = __vector_default);
PROVIDE(__vector_45 = __vector_default);
PROVIDE(__vector_46 = __vector_default);
PROVIDE(__vector_47 = __vector_default);
PROVIDE(__vector_48 = __vector_default);
PROVIDE(__vector_49 = __vector_default);
PROVIDE(__vector_50 = __vector_default);
PROVIDE(__vector_51 = __vector_default);
PROVIDE(__vector_52 = __vector_default);
PROVIDE(__vector_53 = __vector_default);
PROVIDE(__vector_54 = __vector_default);
PROVIDE(__vector_55 = __vector_default);
PROVIDE(__vector_56 = __vector_default);
PROVIDE(__vector_57 = __vector_default);
PROVIDE(__vector_58 = __vector_default);
PROVIDE(__vector_59 = __vector_default);
PROVIDE(__vector_60 = __vector_default);
PROVIDE(__vector_61 = __vector_default);
PROVIDE(__vector_62 = __vector_default);
PROVIDE(__vector_63 = __vector_default);

SECTIONS {
	/*
	 * Ram starts at 0x400 but for some reason it does not allow med to
	 * start placing data at 0x400 since it's not into the ram... Life
	 * is great.
	 */
	__ram_start = 0x500;
	__ram_end = 0x400 + 31k - 1;
        
        .start : {
                *(.init0);
        } > flash

	.data __ram_start :	{
		*(.data);
		*(.rodata);		/* Do NOT place in '.text'. */
		*(.rodata.*);	/* Do NOT place in '.text'. */
		*(.plt);		/* Do NOT place in '.text'. */
	} > ram AT > flash

	__data_start = LOADADDR(.data);
	__data_size = SIZEOF(.data);

	.bss : {
		*(.bss);
		*(COMMON);
	} > ram

	__bss_start = ADDR(.bss);
	__bss_size = SIZEOF(.bss);
        
	.text /*0xc0000*/: {
		*(.text);
		*(.vectors_variable);
	} > flash

        .bootargs /*boot_args_address*/ : {
                *(.boot_args);
        } > flash

	PROVIDE(_end = __bss_start + __bss_size);
	
	/* User Stack Pointer */
	.ustack 0x00007000 :
	{
		_ustack = .;
	} > ram
	
	/* Interrupt Stack Pointer */
	.istack 0x00008000 :
	{
		_istack = .;
	} > ram
	
	/* Vector offset is fixed. */
	.vectors 0x000FFFDC : {
		*(.vectors_fixed);
	} > flash
}
