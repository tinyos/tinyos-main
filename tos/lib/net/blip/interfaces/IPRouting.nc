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
  
#ifdef CENTRALIZED_ROUTING
  // command error_t installFlowEntry(struct rinstall_header* rih, bool isMine);

  command void clearFlows();
#endif

}
