/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
#ifndef _IPDISPATCH_H_
#define _IPDISPATCH_H_

#include <message.h>

enum {
  N_RECONSTRUCTIONS = 3,        /* number of concurrent reconstructions */
  N_CONCURRENT_SENDS = 3,       /* number of concurrent sends */
  N_FRAGMENTS = 12,             /* number of link-layer fragments to buffer */
};

struct send_info {
  void   *upper_data;           /* reference to the data field of IPLower.send */
  uint8_t link_fragments;       /* how many fragments the packet was split into */
  uint8_t link_transmissions;   /* how many total link transmissions were required */
  uint8_t link_fragment_attempts; /* how many fragments we tried  */
  bool    failed;               /* weather the link reported that the transmission succeed*/
  uint8_t _refcount;
};

struct send_entry {
  struct send_info *info;
  message_t  *msg;
};

#ifndef BLIP_L2_RETRIES
#define BLIP_L2_RETRIES 5
#endif

#ifndef BLIP_L2_DELAY
#define BLIP_L2_DELAY 103
#endif

#endif
