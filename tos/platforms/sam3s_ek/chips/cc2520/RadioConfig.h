/*
 * Copyright (c) 2010, Vanderbilt University
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
 * Author: Janos Sallai, Miklos Maroti
 * Author: Thomas Schmid (adapted for CC2520)
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
#include <message.h>
//#include <CC2520DriverLayer.h>

/* This is the default value of the PA_POWER field of the TXCTL register. */
#ifndef CC2520_DEF_RFPOWER
#define CC2520_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the FSCTRL register. */
#ifndef CC2520_DEF_CHANNEL
#define CC2520_DEF_CHANNEL	26
#endif

/* The number of microseconds a sending mote will wait for an acknowledgement */
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	800
#endif

/**
 * This is the timer type of the radio alarm interface
 */
typedef TMicro TRadio;
typedef uint16_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond .
 *
 * Removed three '0s because of overflow...
 */
#define RADIO_ALARM_MICROSEC    48000 / 2 / 1000

enum cc2520_timing_enums {
  CC2520_SYMBOL_TIME = 16 * RADIO_ALARM_MICROSEC, // 16us
  IDLE_2_RX_ON_TIME = 12 * CC2520_SYMBOL_TIME,
  PD_2_IDLE_TIME = 860 * RADIO_ALARM_MICROSEC, // .86ms
};


/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
// FIXME: this needs to be calibrated
#define RADIO_ALARM_MILLI_EXP	(5)

/**
 * This sets the number of neighbors the radio stack stores information (like sequence number)
 */
#define CC2520_NEIGHBORHOOD_SIZE 5

/**
 * Make PACKET_LINK automaticaly enabled for Ieee154MessageC
 */
#if !defined(TFRAMES_ENABLED) && !defined(PACKET_LINK)
#define PACKET_LINK
#endif

#endif//__RADIOCONFIG_H__
