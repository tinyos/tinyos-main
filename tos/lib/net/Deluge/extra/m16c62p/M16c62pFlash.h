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
 * Defines for the program flash blocks.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Renesas
 */
 
#ifndef __M16C62PFLASH_H__
#define __M16C62PFLASH_H__

// User Block Area
typedef enum
{
M16C62P_BLOCK_0 = 0,		//  4KB: 0xFF000 - 0xFFFFF
M16C62P_BLOCK_1 = 1,		//  4KB: 0xFE000 - 0xFEFFF
M16C62P_BLOCK_2 = 2,		//  8KB: 0xFC000 - 0xFDFFF
M16C62P_BLOCK_3 = 3,		//  8KB: 0xFA000 - 0xFBFFF
M16C62P_BLOCK_4 = 4,		//  8KB: 0xF8000 - 0xF9FFF
M16C62P_BLOCK_5 = 5,		// 32KB: 0xF0000 - 0xF7FFF
M16C62P_BLOCK_6 = 6,		// 64KB: 0xE0000 - 0xEFFFF
M16C62P_BLOCK_7 = 7,		// 64KB: 0xD0000 - 0xDFFFF
M16C62P_BLOCK_8 = 8,		// 64KB: 0xC0000 - 0xCFFFF
M16C62P_BLOCK_9 = 9,		// 64KB: 0xB0000 - 0xBFFFF
M16C62P_BLOCK_10 = 10,		// 64KB: 0xA0000 - 0xAFFFF
M16C62P_BLOCK_11 = 11,		// 64KB: 0x90000 - 0x9FFFF
M16C62P_BLOCK_12 = 12,		// 64KB: 0x80000 - 0x8FFFF

// Data Block Area
M16C62P_BLOCK_A = 13		// 4KB: F000 - FFFF
} M16C62P_BLOCK;

const unsigned long m16c62p_block_start_addresses[14] =
	{0xFF000,0xFE000,0xFC000,0xFA000,0xF8000,0xF0000,0xE0000,0xD0000,0xC0000,
		0xB0000,0xA0000,0x90000,0x80000,0xF000 };
		
const unsigned long m16c62p_block_end_addresses[14] =
	{0xFFFFF,0xFEFFF,0xFDFFF,0xFBFFF,0xF9FFF,0xF7FFF,0xEFFFF,0xDFFFF,0xCFFFF,
		0xBFFFF,0xAFFFF,0x9FFFF,0x8FFFF,0xFFFF };

#endif  // __M16C62PFLASH_H__