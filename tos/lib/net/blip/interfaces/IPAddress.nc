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
#include <lib6lowpan/6lowpan.h>

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
   * @return TRUE if the address is assigned to a local interface
   */
  command bool isLocalAddress(struct in6_addr *addr);

  /**
   * @return TRUE of the address is a link local address not requiring
   * routing.
   */
  command bool isLLAddress(struct in6_addr *addr);

  command error_t removeAddress();

  /* Get the link-local Address of the node with the interface identifier be taken from the EUI-64 */

  command bool getEUILLAddress(struct in6_addr *addr);

  event void changed(bool valid);

}
