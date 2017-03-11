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

#ifndef BABEL_H
#define BABEL_H

// ------------------------------- IMPLEMENTATION CONSTANTS

#ifndef BABEL_LINK_COST
#define BABEL_LINK_COST 1 // basic link cost
#endif
#ifndef BABEL_HELLO_INTERVAL
#define BABEL_HELLO_INTERVAL 100 // normal hello interval in 10ms interval (100Hz) (when changing BABEL_HELLO_INTERVAL/8 is used with *2 slow down every other run) 
#endif
#ifndef BABEL_HELLO_PER_IHU
#define BABEL_HELLO_PER_IHU 3 // send ihu every "BABEL_HELLO_PER_IHU" hello timer (modulo seqno)
#endif
#ifndef BABEL_HELLO_PER_UPDATE
#define BABEL_HELLO_PER_UPDATE 10 // send infrequent route update every "BABEL_HELLO_PER_UPDATE" hello timer (modulo seqno)
#endif
#ifndef BABEL_IHU_THRESHOLD
#define BABEL_IHU_THRESHOLD 4 // ihu_interval * "BABEL_IHU_THRESHOLD" ihu data threshold
#endif
#ifndef BABEL_WRITE_MSG_MAX
#define BABEL_WRITE_MSG_MAX (TOSH_DATA_LENGTH-20) // maximum size of babel message
#endif
#ifndef BABEL_SQ_REQUEST_RETRY
#define BABEL_SQ_REQUEST_RETRY 3 // retry of SQ request
#endif
#ifndef BABEL_SQ_REQUEST_RETRY_INTERVAL
#define BABEL_SQ_REQUEST_RETRY_INTERVAL 5 // retry timeout of SQ request
#endif
#ifndef BABEL_SQ_REQUEST_HOPCOUNT
#define BABEL_SQ_REQUEST_HOPCOUNT 16 // maximum hopcount for SQ request (net diameter)
#endif
#ifndef BABEL_RT_THRESHOLD
#define BABEL_RT_THRESHOLD 3 // update_interval * "BABEL_RT_THRESHOLD" hold the same route without update
#endif
#ifndef BABEL_RT_SWITCH_HOLD
#define BABEL_RT_SWITCH_HOLD 20 // try to switch next
#endif
#ifndef BABEL_RT_REQUEST_RETRY
#define BABEL_RT_REQUEST_RETRY 3 // retry of RT request
#endif
#ifndef BABEL_RT_REQUEST_RETRY_INTERVAL
#define BABEL_RT_REQUEST_RETRY_INTERVAL 5 // retry timeout of RT request
#endif
#ifndef BABEL_RT_REQUEST_HOLD
#define BABEL_RT_REQUEST_HOLD (BABEL_RT_REQUEST_RETRY*BABEL_RT_REQUEST_RETRY_INTERVAL) // try to find new next
#endif
#ifndef BABEL_RT_RETRACTION_RETRY
#define BABEL_RT_RETRACTION_RETRY 2 // retry of retract update
#endif
#ifndef BABEL_RT_RETRACTION_RETRY_INTERVAL
#define BABEL_RT_RETRACTION_RETRY_INTERVAL 15 // interval of retract update
#endif
#ifndef BABEL_RT_RETRACTION_HOLD
#define BABEL_RT_RETRACTION_HOLD (BABEL_RT_RETRACTION_RETRY*BABEL_RT_RETRACTION_RETRY_INTERVAL * 2) // hold retracted route (sq request may be pending)
#endif
#ifndef BABEL_RT_MINOR_BITS
#define BABEL_RT_MINOR_BITS 4 // maximum allowed diff for link quality fluctuation
#endif
#ifndef BABEL_RT_MINOR_BITS_MASK
#define BABEL_RT_MINOR_BITS_MASK ((1<<BABEL_RT_MINOR_BITS)-1)
#endif
#ifndef BABEL_RT_COST
#define BABEL_RT_COST (1<<BABEL_RT_MINOR_BITS) // basic route cost 
#endif

// ------------------------------- Table sizes

#ifndef BABEL_NEIGHDB_SIZE
#define BABEL_NEIGHDB_SIZE 16
#endif
#ifndef BABEL_NDB_SIZE
#define BABEL_NDB_SIZE 16
#endif
#ifndef BABEL_ACKDB_SIZE
#define BABEL_ACKDB_SIZE 4
#endif

// ------------------------------- Table reader implementation constants

// NeighborTable
#define BABEL_NB_NODEID 0 // am_addr_t, index
#define BABEL_NB_COST 1 // uint16_t
#define BABEL_NB_LQI 2 // uint8_t
#define BABEL_NB_RSSI 3 // uint8_t

// RoutingTable
#define BABEL_RT_NODEID 0 // am_addr_t, index
#define BABEL_RT_EUI 1 // ieee_eui64_t
#define BABEL_RT_METRIC 2 // uint16_t
#define BABEL_RT_NEXT 3 // am_addr_t

#endif /* BABEL_H */
