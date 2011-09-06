/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

#ifndef BENCHMARK_CORE_H
#define BENCHMARK_CORE_H

#if MAX_EDGE_COUNT <= 8
  typedef uint8_t pending_t;
#elif MAX_EDGE_COUNT <= 16
  typedef uint16_t pending_t;
#elif MAX_EDGE_COUNT <= 32
  typedef uint32_t pending_t;
#elif MAX_EDGE_COUNT <= 64
  typedef uint64_t pending_t;
#else
  #error "MAX_EDGE_COUNT is set too high! The current limit is 64!"
#endif
typedef pending_t edgeaddr_t;

enum {
	MAX_TIMER_COUNT	= 4,
	
  // Policy flags
  GLOBAL_USE_ACK           = 1<<0,
  GLOBAL_USE_BCAST         = 1<<1,
  
  GLOBAL_USE_MAC_LPL       = 1<<2,
  GLOBAL_USE_MAC_PLINK     = 1<<3,
  
  // Sending flags
  SEND_ON_REQ     = 0,
  SEND_ON_INIT    = 1,
  SEND_ON_TIMER   = 2,

  STOP_ON_ACK     = 1<<0,
  STOP_ON_TIMER   = 1<<1,
  
  NEED_ACK = 1,
  
  INFINITE = 0,
};

typedef struct flag_t {
  uint8_t       start_trigger : 3; // When to start sending messages
  uint8_t       stop_trigger  : 2; // When to stop an infinite sending loop
  uint8_t       need_ack      : 1; // ACK is needed?
  uint8_t       inf_loop_on   : 1; // Whether an infinite sending loop is active
  uint8_t       reserved      : 1; // Reserved for future expansion
} flag_t;

typedef struct timerset_t {
  uint8_t       start;
  uint8_t       stop;
} timerset_t;

typedef struct num_t {
  uint8_t       send_num;         // How many messages to transmit in general
  uint8_t       left_num;         // How many messages are left to transmit
} num_t;

// Base types for message counting / message sequence values
#ifdef USE_32_BITS
typedef uint32_t    seq_base_t;
typedef nx_uint32_t nx_seq_base_t;
#else
typedef uint16_t    seq_base_t;
typedef nx_uint16_t nx_seq_base_t;
#endif

typedef struct edge_t {
  uint16_t      sender;           // Sender end of the edge
  uint16_t      receiver;         // Receiver end of the edge
  timerset_t    timers;           // Timers associated to this edge
  flag_t        policy;           // Sending policies, settings, triggers
  num_t         nums;             // Message counters
  edgeaddr_t    reply_on;         // The edge bitmask used when sending on reception
  seq_base_t    nextmsgid;        // The message id to send (on send side)/consecutive to receive (on receive side)
} edge_t;

// Stats type
typedef nx_struct stat_t {
  nx_seq_base_t    triggerCount;
  nx_seq_base_t    backlogCount;
  nx_seq_base_t    resendCount;

  nx_seq_base_t    sendCount;
  nx_seq_base_t    sendSuccessCount;
  nx_seq_base_t    sendFailCount;

  nx_seq_base_t    sendDoneCount;
  nx_seq_base_t    sendDoneSuccessCount;
  nx_seq_base_t    sendDoneFailCount;

  nx_seq_base_t    wasAckedCount;
  nx_seq_base_t    notAckedCount;

  nx_seq_base_t    receiveCount;
  nx_seq_base_t    consecutiveCount;
  nx_seq_base_t    duplicateCount;
  nx_seq_base_t    forwardCount;
  nx_seq_base_t    missedCount;
  nx_seq_base_t    wrongCount;

  nx_uint8_t       remainedCount;
} stat_t;

typedef nx_struct profile_t {
     
  nx_int32_t  min_atomic;
  nx_int32_t  min_interrupt;
  nx_int32_t  min_latency;
  
  nx_int32_t  max_atomic;
  nx_int32_t  max_interrupt;
  nx_int32_t  max_latency;
  
  nx_uint32_t  rtx_time;
  nx_uint32_t  rstart_count;
  nx_uint32_t  rx_bytes;
  nx_uint32_t  tx_bytes;
  nx_uint32_t  rx_msgs;
  
  nx_uint16_t   debug;  
} profile_t;

typedef nx_struct timersetup_t {
  nx_uint8_t    isoneshot;
  nx_uint32_t   delay;
  nx_uint32_t   period_msec;
} timersetup_t;

// Where the MAC settings are located in the mac_setup_t type?
enum {
  // Extend the size of this struct if necessary for new MAC-s.
  MAC_SETUP_LENGTH = 2,

  LPL_WAKEUP_OFFSET = 0,
  
  PLINK_RETRIES_OFFSET = 0,
  PLINK_DELAY_OFFSET = 1
};

typedef nx_uint16_t mac_setup_t[MAC_SETUP_LENGTH];

// Basic setup type
typedef nx_struct setup_t {
  nx_uint8_t    problem_idx;      // The problem we should test
  
  nx_uint32_t   pre_run_msec;
  nx_uint32_t   runtime_msec;     // How long should we run the test?
  nx_uint32_t   post_run_msec;
  
  nx_uint8_t    flags;            // Global flags ( such as BCAST, ACK, LPL, PLINK )
  timersetup_t  timers[MAX_TIMER_COUNT];
  
  // Mac protocol-specific settings
  mac_setup_t   mac_setup;
} setup_t;

#endif
