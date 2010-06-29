/* $Id: LinkEstimator.h,v 1.5 2010-06-29 22:07:47 scipio Exp $ */
/*
 * Copyright (c) 2006 University of Southern California.
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
 *
 */

#ifndef LINK_ESITIMATOR_H
#define LINK_ESITIMATOR_H
/*
 @ author Omprakash Gnawali
 @ Created: June 08, 2006
 */

// Number of entries in the neighbor table
#define NEIGHBOR_TABLE_SIZE 10

// Masks for the flag field in the link estimation header
enum {
  // use last four bits to keep track of
  // how many footer entries there are
  NUM_ENTRIES_FLAG = 15,
};

// The first byte of each outgoing packet is a control byte
// Bits 4..7 reserved for routing and other protocols
// Bits 0..3 is used by the link estimator to encode the
//   number of linkest entries in the packet

// link estimator header added to
// every message passing through the link estimator
typedef nx_struct linkest_header {
  nx_uint8_t flags;
  nx_uint8_t seq;
} linkest_header_t;


// for outgoing link estimator message
// so that we can compute bi-directional quality
typedef nx_struct neighbor_stat_entry {
  nx_am_addr_t ll_addr;
  nx_uint8_t inquality;
} neighbor_stat_entry_t;

// we put the above neighbor entry in the footer
typedef nx_struct linkest_footer {
  neighbor_stat_entry_t neighborList[1];
} linkest_footer_t;


// Flags for the neighbor table entry
enum {
  VALID_ENTRY = 0x1, 
  // A link becomes mature after BLQ_PKT_WINDOW
  // packets are received and an estimate is computed
  MATURE_ENTRY = 0x2,
  // Flag to indicate that this link has received the
  // first sequence number
  INIT_ENTRY = 0x4,
  // The upper layer has requested that this link be pinned
  // Useful if we don't want to lose the root from the table
  PINNED_ENTRY = 0x8
};


// neighbor table entry
typedef struct neighbor_table_entry {
  // link layer address of the neighbor
  am_addr_t ll_addr;
  // last beacon sequence number received from this neighbor
  uint8_t lastseq;
  // number of beacons received after last beacon estimator update
  // the update happens every BLQ_PKT_WINDOW beacon packets
  uint8_t rcvcnt;
  // number of beacon packets missed after last beacon estimator update
  uint8_t failcnt;
  // flags to describe the state of this entry
  uint8_t flags;
  // inbound qualities in the range [1..255]
  // 1 bad, 255 good
  uint8_t inquality;
  // ETX for the link to this neighbor. This is the quality returned to
  // the users of the link estimator
  uint16_t etx;
  // Number of data packets successfully sent (ack'd) to this neighbor
  // since the last data estimator update round. This update happens
  // every DLQ_PKT_WINDOW data packets
  uint8_t data_success;
  // The total number of data packets transmission attempt to this neighbor
  // since the last data estimator update round.
  uint8_t data_total;
} neighbor_table_entry_t;


#endif
