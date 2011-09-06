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

#ifndef MESSAGES_H
#define MESSAGES_H

#include "BenchmarkCore.h"

enum {
  // AM Type identifiers
  
  AM_TESTMSG_T      = 101,
  
  AM_CTRLMSG_T      = 102,
  AM_SYNCMSG_T      = 103,
  AM_SETUPMSG_T     = 104,
  
  AM_DATAMSG_T      = 105,

  // Control / Response message types
  SETUP_BASE        = 0,
  
  CTRL_SETUP_SYN    = 5,
  SYNC_SETUP_ACK    = 6,

  CTRL_START        = 10,
  CTRL_RESET        = 20,

  CTRL_STAT_REQ     = 30,
  DATA_STAT_OK      = 31,

  CTRL_PROFILE_REQ  = 40,
  DATA_PROFILE_OK   = 41
};


typedef nx_struct testmsg_t {
  nx_uint8_t    edgeid;           // On which edge this message is intended to propagate through
  nx_seq_base_t msgid;            // The auto-increment id of the message on the preset edge
} testmsg_t;


typedef nx_struct ctrlmsg_t {
  nx_uint8_t    type;             // Control type
  nx_uint8_t    data_req_idx;     // The requested stat-edge pair index in the requesting stage
} ctrlmsg_t;

typedef nx_struct syncmsg_t {
  nx_uint8_t    type;
  nx_uint8_t    edgecnt;          // How many edges are in the current benchmark?
  nx_uint8_t    maxmoteid;        // How many motes are in the current benchmark?
} syncmsg_t;

typedef nx_struct setupmsg_t {
  nx_uint8_t    type;
  setup_t       config;
} setupmsg_t;

typedef nx_struct datamsg_t {
  nx_uint8_t    type;             // Response type
  nx_uint8_t    data_idx;         // The requested stat-edge pair index in the requesting stage
  nx_union {
    stat_t      stat;             // The requested stat structure in the requesting stage
    profile_t   profile;          // The profile of the mote
  } payload;
} datamsg_t;


#endif

