#ifndef FORWARDING_ENGINE_H
#define FORWARDING_ENGINE_H

/*
 * Copyright (c) 2006 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <AM.h>
#include <message.h>

/**
 * Author: Philip Levis
 * Author: Kyle Jamieson 
 * Author: Omprakash Gnawali
 * Author: Rodrigo Fonseca
 */

/* 
 * These timings are in milliseconds, and are used by
 * ForwardingEngineP. Each pair of values represents a range of
 * [OFFSET - (OFFSET + WINDOW)]. The ForwardingEngine uses these
 * values to determine when to send the next packet after an
 * event. FAIL refers to a send fail (an error from the radio below),
 * NOACK refers to the previous packet not being acknowledged,
 * OK refers to an acknowledged packet, and LOOPY refers to when
 * a loop is detected.
 *
 * These timings are defined in terms of packet times. Currently,
 * two values are defined: for CC2420-based platforms (4ms) and
 * all other platfoms (32ms). 
 */

enum {
#if PLATFORM_MICAZ || PLATFORM_TELOSA || PLATFORM_TELOSB || PLATFORM_TMOTE || PLATFORM_INTELMOTE2 || PLATFORM_SHIMMER || PLATFORM_IRIS
  FORWARD_PACKET_TIME = 7,
#else
  FORWARD_PACKET_TIME = 32,
#endif
};

enum {
  SENDDONE_OK_OFFSET        = FORWARD_PACKET_TIME,
  SENDDONE_OK_WINDOW        = FORWARD_PACKET_TIME,
  SENDDONE_NOACK_OFFSET     = FORWARD_PACKET_TIME,
  SENDDONE_NOACK_WINDOW     = FORWARD_PACKET_TIME,
  SENDDONE_FAIL_OFFSET      = FORWARD_PACKET_TIME  << 2,
  SENDDONE_FAIL_WINDOW      = SENDDONE_FAIL_OFFSET,
  LOOPY_OFFSET              = FORWARD_PACKET_TIME  << 2,
  LOOPY_WINDOW              = LOOPY_OFFSET,
  CONGESTED_WAIT_OFFSET     = FORWARD_PACKET_TIME  << 2,
  CONGESTED_WAIT_WINDOW     = CONGESTED_WAIT_OFFSET,
  NO_ROUTE_RETRY            = 10000
};


/* 
 * The number of times the ForwardingEngine will try to 
 * transmit a packet before giving up if the link layer
 * supports acknowledgments. If the link layer does
 * not support acknowledgments it sends the packet once.
 */
enum {
  MAX_RETRIES = 30
};

/*
 * The network header that the ForwardingEngine introduces.
 * This header will change for the TinyOS 2.0 full release 
 * (it needs several optimizations).
 */
typedef nx_struct {
  nx_uint8_t control;
  nx_am_addr_t origin;
  nx_uint8_t seqno;
  nx_uint8_t collectid;
  nx_uint16_t gradient;
} network_header_t;

/*
 * An element in the ForwardingEngine send queue.
 * The client field keeps track of which send client 
 * submitted the packet or if the packet is being forwarded
 * from another node (client == 255). Retries keeps track
 * of how many times the packet has been transmitted.
 */
typedef struct {
  message_t * ONE_NOK msg;
  uint8_t client;
  uint8_t retries;
} fe_queue_entry_t;

#endif
