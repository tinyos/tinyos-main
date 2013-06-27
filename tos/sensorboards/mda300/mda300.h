/*
 * Copyright (c) 2012 Sestosenso
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
 * - Neither the name of the Sestosenso nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * SESTOSENSO OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
 /**
 *
 * @author Franco Di Persio, Sestosenso
 * @modified September 2012
 */

#ifndef _MDA300_H
#define _MDA300_H

#define UQ_ADC_RESOURCE "mda300.ADC"
#define UQ_DIO_RESOURCE "mda300.DIO"
#define UQ_SHT15_RESOURCE "mda300.SHT15"
#define UQ_ARBITER_RESOURCE "mda300.arbiter"

#define UQ_HUM_RESOURCE "mda300.photo"
#define UQ_TEMP_RESOURCE "mda300.temp"
#define UQ_HUMTEMP_RESOURCE "mda300.phototemp"


enum
{
  TOS_SHT15_DATA_POT_ADDR = 0x5A,
  TOS_SHT15_CLK_POT_ADDR = 0x58,
};

enum
{
  DIGITAL_TIMER = 500,	//This timer has to be higher of the time taken by the digital impuls, but not so high for avoiding to reduce the measurable digital frequency
};

// debug leds
//#define _DEBUG_LEDS
#ifdef _DEBUG_LEDS
#define DEBUG_LEDS(X)         X.DebugLeds -> LedsC
#else
#define DEBUG_LEDS(X)         X.DebugLeds -> NoLedsC
#endif
#endif /* _MDA300_H */

