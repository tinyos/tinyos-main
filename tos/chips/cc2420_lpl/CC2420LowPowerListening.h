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
  * @author David Moss
  */
#ifndef CC2420LOWPOWERLISTENING_H
#define CC2420LOWPOWERLISTENING_H

#include "CC2420DutyCycle.h"

/**
 * The default duty period is usually 0, which is the equivalent of
 * ONE_MESSAGE (below), which tells the node to transmit the message
 * one time without expecting receiver duty cycling.
 */
#ifndef DEFAULT_TRANSMIT_PERIOD
#define DEFAULT_TRANSMIT_PERIOD DEFAULT_DUTY_PERIOD
#endif

/**
 * Amount of time, in milliseconds, to keep the radio on after
 * a successful receive addressed to this node
 */
#ifndef DELAY_AFTER_RECEIVE
#define DELAY_AFTER_RECEIVE 50
#endif

/**
 * Value used to indicate the message being sent should be transmitted
 * one time
 */
#ifndef ONE_MESSAGE
#define ONE_MESSAGE 0
#endif

#endif

