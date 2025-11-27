/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
 /**
  * @author David Moss
  * @author Tony O'Donovan
  */
#ifndef DEFAULTLPL_H
#define DEFAULTLPL_H

/**
 * Low Power Listening Send States
 */
typedef enum {
  S_LPL_NOT_SENDING,    // DEFAULT
  S_LPL_FIRST_MESSAGE,  // 1. Sending the first message
  S_LPL_SENDING,        // 2. Sending all other messages
  S_LPL_CLEAN_UP,       // 3. Clean up the transmission
} lpl_sendstate_t;


/**
 * Amount of time, in milliseconds, to keep the radio on after
 * a successful receive addressed to this node
 */
#ifndef DELAY_AFTER_RECEIVE
#define DELAY_AFTER_RECEIVE 100
#endif

/**
 * This is a measured value of the time in ms the radio is actually on
 * We round this up to err on the side of better performance ratios
 * This includes the acknowledgement wait period and backoffs,
 * which can typically be much longer than the transmission.
 * 
 * Measured by Tony O'Donovan
 */
#ifndef DUTY_ON_TIME
#define DUTY_ON_TIME 11 
#endif

/**
 * The maximum number of CCA checks performed on each wakeup.
 * If there are too few, the receiver may wake up between messages
 * and not detect the transmitter.
 *
 * The on-time had to increase from the original version to allow multiple
 * transmitters to co-exist.  This is due to using ack's, which then requires us
 * to extend the backoff period.  In networks that transmit frequently, possibly
 * with multiple transmitters, this power scheme makes sense.  
 *
 * In networks that transmit very infrequently or without multiple transmitters,
 * it makes more sense to go with no acks and no backoffs and make the
 * receive check as short as possible.
 */
#ifndef MAX_LPL_CCA_CHECKS

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_TMOTE)
#define MAX_LPL_CCA_CHECKS 400
#else
#define MAX_LPL_CCA_CHECKS 400
#endif

#endif

/**
 * The minimum number of samples that must be taken in CC2420DutyCycleP
 * that show the channel is not clear before a detection event is issued
 */
#ifndef MIN_SAMPLES_BEFORE_DETECT
#define MIN_SAMPLES_BEFORE_DETECT 3
#endif

#endif

