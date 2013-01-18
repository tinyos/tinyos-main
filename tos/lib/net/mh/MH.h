/*
 * Copyright (c) 2012 Martin Cerveny
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
 * - Neither the name of the copyright holders nor the names of
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
 */
 
 /**
 * Public headers.
 * 
 * @author Martin Cerveny
 */ 
 
 
#ifndef MH_H
#define MH_H

typedef enum { // response of external implementation of routing protocols.
	MH_SEND, //Put the message in the sending queue
	MH_RECEIVE, //Give the message to the upper layer
	MH_WAIT, //Retry later
	MH_DISCARD, //Discard the message
} mh_action_t;

// actual constants for algorithm (can be overridden)

#ifndef MH_TIMER_CYCLE
#define MH_TIMER_CYCLE 	10 // timer periodic cycle in millis
#endif
#ifndef MH_WAIT_BEFORE_RETRY
#define MH_WAIT_BEFORE_RETRY 10 // retry timer (in MH_TIMER_CYCLE ticks)
#endif
#ifndef MH_RETRIES
#define MH_RETRIES 5 // retry count
#endif

#ifndef MH_FORWARDING_BUFERS
#define MH_FORWARDING_BUFERS 4 // number of buffers for packet forwarding
#endif

#endif /* MH_H */
