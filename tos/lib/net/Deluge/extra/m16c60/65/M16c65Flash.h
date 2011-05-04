/*
 * Copyright (c) 2011 Lulea University of Technology
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Defines for the program flash blocks for M16c/65.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Renesas
 */
 
#ifndef __M16C65FLASH_H__
#define __M16C65FLASH_H__

// User Block Area
typedef enum
{
M16C65_BLOCK_0 = 0,		// 64KB: 0xF0000 - 0xFFFFF
M16C65_BLOCK_1 = 1,		// 64KB: 0xE0000 - 0xEFFFF
M16C65_BLOCK_2 = 2,		// 64KB: 0xD0000 - 0xDFFFF
M16C65_BLOCK_3 = 3,		// 64KB: 0xC0000 - 0xCFFFF
M16C65_BLOCK_4 = 4,		// 64KB: 0xB0000 - 0xBFFFF
M16C65_BLOCK_5 = 5,		// 64KB: 0xA0000 - 0xAFFFF
M16C65_BLOCK_6 = 6,		// 64KB: 0x90000 - 0x9FFFF
M16C65_BLOCK_7 = 7,		// 64KB: 0x80000 - 0x8FFFF

// Data Block Area
M16C65_BLOCK_A = 13		// 4KB: F000 - FFFF
} M16C65_BLOCK;

const unsigned long m16c65_block_start_addresses[8] =
	{0xF0000,0xE0000,0xD0000,0xC0000,0xB0000,0xA0000,0x90000,0x80000 };
		
const unsigned long m16c65_block_end_addresses[8] =
	{0xFFFFF,0xEFFFF,0xDFFFF,0xCFFFF,0xBFFFF,0xAFFFF,0x9FFFF,0x8FFFF };

#endif  // __M16C65FLASH_H__
