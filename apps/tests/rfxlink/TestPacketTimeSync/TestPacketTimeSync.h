/*
 * Copyright (c) 2002-2011, Vanderbilt University
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
 
#ifndef TEST_PACKET_TIMESYNC_H
#define TEST_PACKET_TIMESYNC_H

typedef nx_struct ping_msg {
  nx_uint16_t pinger;
  nx_uint32_t ping_counter;
  nx_uint32_t ping_event_time;
  nx_uint32_t prev_ping_counter;
  nx_uint8_t  prev_ping_tx_timestamp_is_valid;
  nx_uint32_t prev_ping_tx_timestamp;
} ping_msg_t;

typedef nx_struct real_ping_msg {
  nx_uint16_t pinger;
  nx_uint32_t ping_counter;
  nx_uint32_t ping_event_time;
  nx_uint32_t prev_ping_counter;
  nx_uint8_t  prev_ping_tx_timestamp_is_valid;
  nx_uint32_t prev_ping_tx_timestamp;
  nx_uint32_t am_id;	// am-over-am am id
} real_ping_msg_t;

typedef nx_struct pong_msg {
  nx_uint16_t ponger;
  nx_uint16_t pinger;
  nx_uint32_t ping_counter;
  nx_uint32_t ping_event_time;
  nx_uint8_t  ping_rx_timestamp_is_valid;
  nx_uint8_t  ping_event_time_is_valid;
  nx_uint32_t ping_rx_timestamp;
} pong_msg_t;


enum {
  AM_PING_MSG = 16,
  AM_REAL_PING_MSG = 0x3d, // packettimesync am id
  AM_PONG_MSG = 17,
};

#endif
