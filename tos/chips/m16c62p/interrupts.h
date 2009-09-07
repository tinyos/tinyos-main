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
 * M16C interrupt id defines.
 *
 * @author Per Lindgren
 * @author Johan Eriksson
 * @author Johan Nordlander
 * @author Simon Aittamaa.
 */

#ifndef M16C_INTERRUPTS_H_
#define M16C_INTERRUPTS_H_

/* Software interrupts - bound to peripheral hardware */

#define M16C_BRK		0
#define M16C_INT3		4
#define M16C_TMRB5		5
#define M16C_TMRB4		6
#define M16C_UART1_BCD		6
#define M16C_TMRB3		7
#define M16C_UART0_BCD		7
#define M16C_INT5		8
#define M16C_SI_O4		8
#define M16C_INT4		9
#define M16C_SI_O3		9
#define M16C_UART2_BCD		10
#define M16C_DMA0		11
#define M16C_DMA1		12
#define M16C_KEY		13
#define M16C_AD			14
#define M16C_UART2_NACK		15
#define M16C_UART2_ACK		16
#define M16C_UART0_NACK		17
#define M16C_UART0_ACK		18
#define M16C_UART1_NACK		19
#define M16C_UART1_ACK		20
#define M16C_TMRA0		21
#define M16C_TMRA1		22
#define M16C_TMRA2		23
#define M16C_TMRA3		24
#define M16C_TMRA4		25
#define M16C_TMRB0		26
#define M16C_TMRB1		27
#define M16C_TMRB2		28
#define M16C_INT0		29
#define M16C_INT1		30
#define M16C_INT2		31

/* Software interrupts - not bound to peripheral hardware */

#define M16C_SINT0		32
#define M16C_SINT1		33
#define M16C_SINT2		34
#define M16C_SINT3		35
#define M16C_SINT4		36
#define M16C_SINT5		37
#define M16C_SINT6		38
#define M16C_SINT7		39
#define M16C_SINT8		40
#define M16C_SINT9		41
#define M16C_SINT10		42
#define M16C_SINT11		43
#define M16C_SINT12		44
#define M16C_SINT13		45
#define M16C_SINT14		46
#define M16C_SINT15		47
#define M16C_SINT16		48
#define M16C_SINT17		49
#define M16C_SINT18		50
#define M16C_SINT19		51
#define M16C_SINT20		52
#define M16C_SINT21		53
#define M16C_SINT22		54
#define M16C_SINT23		55
#define M16C_SINT24		56
#define M16C_SINT25		57
#define M16C_SINT26		58
#define M16C_SINT27		59
#define M16C_SINT28		60
#define M16C_SINT29		61
#define M16C_SINT30		62
#define M16C_SINT31		63

/* Interrupt macro */
#define _M16C_INTERRUPT(id) _vector_##id
#define M16C_INTERRUPT(id) \
	void __attribute__((interrupt)) _M16C_INTERRUPT(id)(void)

#endif


