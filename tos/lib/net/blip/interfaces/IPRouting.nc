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

/*
 *  This interface presents the interface to the IP routing engine.
 *  Related interfaces are the forwarding engine, which implements
 *     the routing decision whare are communicated by this interface, 
 *     and the ICMP interface, which deals with sending and receiving 
 *     ICMP traffic.
 *
 */

#include "IPDispatch.h"

interface IPRouting {
  /*
   * returns weather or not the node should consume a packet addressed
   * to a given address.  Interprets link-local and global addresses,
   * and manages multicast group membership.
   */
  command bool isForMe(struct ip6_hdr *a);

  /*
   * returns a policy for sending this message to someone else.
   *   the send policy includes the layer 2 address, number of retransmissions,
   *     and spacing between them.
   *
   */ 
  command error_t getNextHop(struct ip6_hdr   *hdr, 
                             struct ip6_route *routing_hdr,
                             ieee154_saddr_t prev_hop,
                             send_policy_t *ret);


  /*
   * returns the currently configured default IP hop limit.
   *
   */
  command uint8_t getHopLimit();

  command uint16_t getQuality();

  /*
   * 
   *
   */
  command void reportAdvertisement(ieee154_saddr_t neigh, uint8_t hops, 
                                             uint8_t lqi, uint16_t cost);

  /*
   * informs the router of a reception from a neighbor, along with the 
   *  the rssi of the received packet.
   *
   */
  command void reportReception(ieee154_saddr_t neigh, uint8_t lqi);

  /*
   * @returns TRUE if the routing engine has established a default route.
   */
  command bool hasRoute();

  command struct ip6_route *insertRoutingHeader(struct split_ip_msg *msg);
  
  command void reset();

#ifdef CENTRALIZED_ROUTING
  // command error_t installFlowEntry(struct rinstall_header* rih, bool isMine);

  command void clearFlows();
#endif

}
