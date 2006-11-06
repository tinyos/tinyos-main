/* $Id: PXA27X_UARTREG.h,v 1.2 2006-11-06 11:57:12 scipio Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

/* 
 * Helper macros to make programming the HplPXA27xUARTP component easier
 */

#ifndef _PXA27X_UARTREG_H
#define _PXA27X_UARTREG_H

#define UARTRBR(_base) _PXAREG_OFFSET(_base,0)
#define UARTTHR(_base) _PXAREG_OFFSET(_base,0)
#define UARTIER(_base) _PXAREG_OFFSET(_base,0x04)
#define UARTIIR(_base) _PXAREG_OFFSET(_base,0x08)
#define UARTFCR(_base) _PXAREG_OFFSET(_base,0x08)
#define UARTLCR(_base) _PXAREG_OFFSET(_base,0x0C)
#define UARTMCR(_base) _PXAREG_OFFSET(_base,0x10)
#define UARTLSR(_base) _PXAREG_OFFSET(_base,0x14)
#define UARTMSR(_base) _PXAREG_OFFSET(_base,0x18)
#define UARTSPR(_base) _PXAREG_OFFSET(_base,0x1C)
#define UARTISR(_base) _PXAREG_OFFSET(_base,0x20)
#define UARTFOR(_base) _PXAREG_OFFSET(_base,0x24)
#define UARTABR(_base) _PXAREG_OFFSET(_base,0x28)
#define UARTACR(_base) _PXAREG_OFFSET(_base,0x2C)

#define UARTDLL(_base) _PXAREG_OFFSET(_base,0)
#define UARTDLH(_base) _PXAREG_OFFSET(_base,0x04)

#endif /* _PXA27X_UARTREG_H */

