/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in so1urce and binary forms, with or without
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
 * Types and definitions for the Taos TSL256x sensor
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:16 $
 */

#ifndef _TSL256X_H
#define _TSL256X_H

#define TSL256X_PTR_CONTROL	(0x0)
#define TSL256X_PTR_TIMING	(0x1)
#define TSL256X_PTR_THRESHLOWLOW	(0x2)
#define TSL256X_PTR_THRESHLOWHIGH	(0x3)
#define TSL256X_PTR_THRESHHIGHLOW	(0x4)
#define TSL256X_PTR_THRESHHIGHIGH	(0x5)
#define TSL256X_PTR_INTERRUPT	(0x6)
#define TSL256X_PTR_CRC		(0x8)
#define TSL256X_PTR_ID		(0xA)
#define TSL256X_PTR_DATA0LOW	(0xC)
#define TSL256X_PTR_DATA0HIGH	(0xD)
#define TSL256X_PTR_DATA1LOW	(0xE)
#define TSL256X_PTR_DATA1HIGH	(0xF)

#define TSL256X_COMMAND_CMD	(1<<7)
#define TSL256X_COMMAND_CLEAR	(1<<6)
#define TSL256X_COMMAND_WORD	(1<<5)
#define TSL256X_COMMAND_BLOCK	(1<<4)
#define TSL256X_COMMAND_ADDRESS(_x) ((_x) & 0xF)

#define TSL256X_CONTROL_POWER_ON (0x3)
#define TSL256X_CONTROL_POWER_OFF (0x0)

#define TSL256X_TIMING_GAIN	(1<<4)
#define TSL256X_TIMING_MANUAL	(1<<3)
#define TSL256X_TIMING_INTEG(_x) ((_x) & 0x3)

#define TSL256X_INTERRUPT_INTR(_x) (((_x) & 0x3) << 4)
#define TSL256X_INTERRUPT_PERSIST(_x) ((_x) & 0xF)


#endif /* _TSL256X_H */
