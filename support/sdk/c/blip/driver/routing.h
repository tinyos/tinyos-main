/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
#ifndef __ROUTING_H_
#define __ROUTING_H_

#include <lib6lowpan/ip.h>
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
