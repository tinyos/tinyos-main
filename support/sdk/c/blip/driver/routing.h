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
#ifndef __ROUTING_H_
#define __ROUTING_H_

#include <ip.h>
#include <string.h>
#include "nwstate.h"
#include "config.h"

enum {
  ROUTE_NO_ROUTE,
  ROUTE_ONEHOP,
  ROUTE_MHOP,
  ROUTE_SOURCE,
  ROUTE_WORMHOLE,
};

// the maximum size of a set of topology entries we send out over the network
#define ROUTMSGSIZ 1400

enum {
  RMSG_TOPOLOGY = 1,
};

struct routing_message {
  uint16_t type;
  uint16_t source;
  char    data[0];
};

int routing_init(struct config *c, char *tun_dev);

/* 
 * handles for  the blocking loop
 */
int routing_add_fds(fd_set *fds);
int routing_process(fd_set *fds);


/*
 * @returns: truth value indicating if the destination of the packet
 * is a single hop, and requires no source route.
 */
int routing_is_onehop(struct split_ip_msg  *msg);


/*
 * Copys the IP message at orig to the empty one at ret, inserting
 * necessary routing information.
 */
uint8_t routing_insert_route(struct split_ip_msg *orig);

/*
 * Returns the address of the next router this packet should be send to.
 */
ieee154_saddr_t routing_get_nexthop(struct split_ip_msg *msg);


/*
 * Called for all reconstructed packets off serial.
 * allows the router to inpect and remove any extra headers in the message.
 */
int routing_add_report(node_id_t reporter, struct tlv_hdr *tlv);

 
uint16_t routing_get_seqno();

uint16_t routing_incr_seqno();

#endif 
