/* $Id: LinkEstimator.h,v 1.4 2006-12-12 18:23:29 vlahan Exp $ */
/*
 * "Copyright (c) 2006 University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE,
 * SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
  // MAXAGE-inage gives the number of update rounds we haven't been able
  // update the inbound beacon estimator
  uint8_t inage;
  // MAXAGE-outage gives the number of update rounds we haven't received
  // the outbound link quality
  uint8_t outage;
  // inbound and outbound link qualities in the range [1..255]
  // 1 bad, 255 good
  uint8_t inquality;
  uint8_t outquality;
  // EETX for the link to this neighbor. This is the quality returned to
  // the users of the link estimator
  uint16_t eetx;
  // Number of data packets successfully sent (ack'd) to this neighbor
  // since the last data estimator update round. This update happens
  // every DLQ_PKT_WINDOW data packets
  uint8_t data_success;
  // The total number of data packets transmission attempt to this neighbor
  // since the last data estimator update round.
  uint8_t data_total;
} neighbor_table_entry_t;


#endif
