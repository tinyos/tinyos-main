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
#include <6lowpan.h>

interface IPAddress {

  /**
   * Get the preferred link-local interface for this node
   */
  command bool getLLAddr(struct in6_addr *addr);

  /** 
   * Get the preferred global IPv6 address for this node
   */
  command bool getGlobalAddr(struct in6_addr *addr);

  /**
   * Choose a source address for a packet originating at this node.
   */
  command bool setSource(struct ip6_hdr *hdr);

  /**
   * Map the IPv6 address to a link-layer address.
   * @return FAIL if the address cannot be resolved, either becasue 
   * it is not known or because the given IPv6 address is not on the link.
   */
  command error_t resolveAddress(struct in6_addr *addr, ieee154_addr_t *link_addr);

  /**
   * @return TRUE if the address is assigned to a local interface
   */
  command bool isLocalAddress(struct in6_addr *addr);
}
