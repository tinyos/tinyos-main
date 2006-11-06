/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Types and definitions for the Dallas DS2745 I2C Battery Monitor
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2006-11-06 11:57:09 $
 */

#ifndef _DS2745_H
#define _DS2745_H

#define DS2745_PTR_SC		(0x01)
#define DS2745_PTR_TEMPMSB	(0x0A)
#define DS2745_PTR_TEMPLSB	(0x0B)
#define DS2745_PTR_VOLTMSB	(0x0C)
#define DS2745_PTR_VOLTLSB	(0x0D)
#define DS2745_PTR_CURRMSB	(0x0E)
#define DS2745_PTR_CURRLSB	(0x0F)
#define DS2745_PTR_ACCURMSB	(0x10)
#define DS2745_PTR_ACCURLSB	(0x11)
#define DS2745_PTR_OFFSETBIAS	(0x61)
#define DS2745_PTR_ACCBIAS	(0x62)

#define DS2745_SC_PORF		(1 << 6)
#define DS2745_SC_SMOD		(1 << 5)
#define DS2745_SC_NBEN		(1 << 4)
#define DS2745_SC_PIO		(1 << 3)
#define DS2745_SC_FQ(_x)	(((_x) & 0x3))

#endif /* _DS2745_H */
