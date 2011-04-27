/*
 * Copyright (c) 2011, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */ 

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
#include <CC2420XDriverLayer.h>
//#include <util/crc16.h>

#define RADIO_DEBUG
#define RADIO_DEBUG_MESSAGES
#define RADIO_DEBUG_IRQ

/* This is the default value of the PA_POWER field of the TXCTL register. */
#ifndef CC2420X_DEF_RFPOWER
#define CC2420X_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the FSCTRL register. */
#ifndef CC2420X_DEF_CHANNEL
#define CC2420X_DEF_CHANNEL	11
#endif

/* The number of microseconds a sending micaz mote will wait for an acknowledgement */
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	800
#endif

/**
 * This is the timer type of the radio alarm interface
 */
typedef TMicro TRadio;
typedef uint16_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond (0.9216).
 * We use integers and no parentheses just to make deputy happy.
 * Ok, further hacks were required for deputy, I removed 00 from the
 * beginning and end to be able to handle longer wait periods.
 */
#define RADIO_ALARM_MICROSEC	1

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	10

#endif//__RADIOCONFIG_H__
