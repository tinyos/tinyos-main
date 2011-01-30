/*
 * Copyright (c) 2009 Stanford University.
 * All rights reserved.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * Linker script to run code in Flash 0.
 * Start-up code copies data into SRAM 0 and zeroes BSS segment.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 * @author Thomas Schmid
 */

/* Output format is always little endian, irrespective of -EL or -EB flags */
OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
/* Output architecture is ARM */
OUTPUT_ARCH(arm)
/* The first program instruction is the __init() start-up code */
ENTRY(__init)

/* The IRQ vector table is put at the beginning of SRAM 0 */
/* We reserve 0x100 bytes by setting the SRAM 0 base address below accordingly */
_vect_start = 0x20000000;

/* Stack at the end of SRAM 0 */
_estack = 0x20007ffc;

/* Don't relocate the vector table */
/*PROVIDE (__relocate_vector = 0);*/

/* We have the SAM3U4E with 2 x 128K Flash and 48K SRAM.
 * SRAM is 32K SRAM 0 and 16K SRAM 1.
 * Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 2, p. 28, p. 29 */
MEMORY
{
	sram0  (W!RX) : org = 0x20000000, len = 0x08000 /* SRAM 0, 32K (- 0x100 vector table) */
	sram1  (W!RX) : org = 0x20080000, len = 0x04000 /* SRAM 1, 16K */
	flash0 (W!RX) : org = 0x00080000, len = 0x20000 /* Flash 0, 128K */
	flash1 (W!RX) : org = 0x00100000, len = 0x20000 /* Flash 1, 128K */
}

SECTIONS
{
	/* Text is linked into Flash 0 */
	.text :
	{
		. = ALIGN(4);
		_stext = .;
        /* KEEP(*(.boot*)) */
        KEEP(*(.vectors))
        *(.init*)
		*(.text*)
        *(.fini*)
		*(.rodata*)
		*(.glue_7) /* ARM/Thumb interworking code */
		*(.glue_7t) /* ARM/Thumb interworking code */
		. = ALIGN(4);
		_etext = .;
	} > flash0

	/* Data will be loaded into RAM by start-up code */
	.data : AT (_etext)
	{
		. = ALIGN(4);
		_sdata = .;
        _svect = .;
        KEEP(*(.vectors)) /* Interrupt vector table in first 204 bytes */
        _evect = .;
		*(.ramfunc) /* functions linked into RAM */
		*(.data.*)
		*(.data)
		. = ALIGN(4);
		_edata = .;
	} > sram0

	/* BSS will be zeroed by start-up code */
	.bss (NOLOAD) : {
		. = ALIGN(4);
		_sbss = .;
		*(.bss.*)
		*(.bss)
		. = ALIGN(4);
	} > sram0
	/* _ebss should be inside .bss, but for some reason, it then is not defined
	 * at the end of the BSS section. This leads to non-zeroed BSS data, since the
	 * start-up code uses that symbol. For now, this workaround is OK and does no
	 * harm.
	 */
	_ebss = .;
}
end = .;
