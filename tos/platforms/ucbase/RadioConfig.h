/*
 * Copyright (c) 2007, Vanderbilt University
 * Copyright (c) 2010, Univeristy of Szeged
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
 * - Neither the name of the copyright holder nor the names of
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
 *
 * Author: Miklos Maroti
 * Author: Andras Biro
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <RFA1DriverLayer.h>
#include "TimerConfig.h"

enum
{
	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RFA1_CCA_MODE_VALUE = CCA_CS<<CCA_MODE0,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RFA1_CCA_THRES_VALUE = 0xC7,	//TODO to avr-libc values
	
	RFA1_PA_BUF_LT=3<<PA_BUF_LT0,
	RFA1_PA_LT=0<<PA_LT0,
};

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RFA1_DEF_RFPOWER
#define RFA1_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RFA1_DEF_CHANNEL
#define RFA1_DEF_CHANNEL	26
#endif

/* The number of microseconds a sending mote will wait for an acknowledgement */
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	1000
#endif

/**
 * This is the timer type of the radio alarm interface
 */
typedef T62khz TRadio;
typedef uint32_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond
 */
#define RADIO_ALARM_MICROSEC	0.0625

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	6

/**
 * This sets the number of neighbors the radio stack stores information (like sequence number)
 */
#define RFA1_NEIGHBORHOOD_SIZE 5

#endif//__RADIOCONFIG_H__
