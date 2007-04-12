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
  */
#ifndef CC2420NOACKLPL_H
#define CC2420NOACKLPL_H

/**
 * Low Power Listening Send States
 */
typedef enum {
  S_LPL_NOT_SENDING,    // DEFAULT
  S_LPL_FIRST_MESSAGE,  // 1. Initial backoffs, no acks, full CCA
  S_LPL_LAST_MESSAGE,   // 3. No backoffs, acknowledgement request, no CCA
} lpl_sendstate_t;

/**
 * Amount of time, in milliseconds, to keep the radio on after
 * a successful receive addressed to this node
 * You don't want this too fast, or the off timer can accidentally
 * fire due to delays in the system.  The radio would shut off and
 * possibly need to turn back on again immediately, which can lock up
 * the CC2420 if it's in the middle of doing something.
 */
#ifndef DELAY_AFTER_RECEIVE
#define DELAY_AFTER_RECEIVE 100
#endif


/**
 * This is a measured value of the time in ms the radio is actually on
 * We round this up to err on the side of better performance ratios
 */
#ifndef DUTY_ON_TIME
#define DUTY_ON_TIME 1
#endif

/**
 * The maximum number of CCA checks performed on each wakeup.
 * The value is relative to the speed of transmission and speed of the
 * microcontroller executing the receive check loop. If the transmission
 * is ultimately back-to-back without break or the microcontroller
 * is slow, we can do less samples. If the microcontroller is very 
 * fast, we must do more samples.  Keep in mind the datasheet also
 * specifies that the CCA pin is valid after 8 symbol periods of
 * the radio being on.
 */
#ifndef MAX_LPL_CCA_CHECKS

#if defined(PLATFORM_TELOSB)
#define MAX_LPL_CCA_CHECKS 12
#else
#define MAX_LPL_CCA_CHECKS 12
#endif

#endif

/**
 * The minimum number of samples that must be taken in CC2420DutyCycleP
 * that show the channel is not clear before a detection event is issued
 */
#ifndef MIN_SAMPLES_BEFORE_DETECT
#define MIN_SAMPLES_BEFORE_DETECT 1
#endif

#endif

