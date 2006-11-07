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
 * Types and definitions for the Maxim 136x general purpose ADC chip
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:30:55 $
 */

#ifndef _MAX136X_H
#define _MAX136X_H

#define MAX136X_CONFIG_SCAN(_x)		(((_x) & 0x3) << 5)
#define MAX136X_CONFIG_CS(_x)		(((_x) & 0xF) << 1)
#define MAX136X_CONFIG_SE		(1 << 0)

#define MAX136X_SETUP_REFAIN3SEL(_x)	(((_x) & 0x3) << 5)
#define MAX136X_SETUP_INTREFOFF		(1 << 4)
#define MAX136X_SETUP_EXTCLK		(1 << 3)
#define MAX136X_SETUP_BIP		(1 << 2)
#define MAX136X_SETUP_NRESET		(1 << 1)
#define MAX136X_SETUP_MONSETUP		(1 << 0)

#define MAX136X_MONITOR_DELAY(_x)       (((_x) & 0x7) << 1)
#define MAX136X_MONITOR_INTEN           (1 << 0)

typedef uint16_t max136x_data_t;

typedef enum {
  MAX136X_SCAN_RANGE = 0,
  MAX136X_SCAN_REPEATED = 1,
  MAX136X_SCAN_SINGLE = 3,
} max136x_scanflag_t;

typedef enum {
  MAX136X_SEL_VDDREF,  		// SEL1 = 0, SEL0 = 0
  MAX136X_SEL_EXTREF,		// SEL1 = 0, SEL0 = 1
  MAX136X_SEL_INTREF_AIN3IN,	// SEL1 = 1, SEL0 = 0
  MAX136X_SEL_INTREF_AIN3OUT	// SEL1 = 1, SEL0 = 1
} max136x_selflag_t;

typedef enum {
  MAX136X_DELAY_133_0,
  MAX136X_DELAY_66_5,
  MAX136X_DELAY_33_3,
  MAX136X_DELAY_16_6,
  MAX136X_DELAY_8_3,
  MAX136X_DELAY_4_2,
  MAX136X_DELAY_2_0,
  MAX136X_DELAY_1_0
} max136x_delayflag_t;


#endif /* _MAX136X_H */
