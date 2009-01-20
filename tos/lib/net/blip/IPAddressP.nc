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

// defined in lib6lowpan
extern struct in6_addr __my_address;
extern uint8_t globalPrefix;

module IPAddressP {
  provides interface IPAddress;

#ifndef SIM
  uses interface ActiveMessageAddress;
#else 
  uses async command void setAmAddress(am_addr_t a);
#endif
} implementation {


  command hw_addr_t IPAddress.getShortAddr() {
    return TOS_NODE_ID;
  }

  command void IPAddress.setShortAddr(hw_addr_t newAddr) {
    TOS_NODE_ID = newAddr;
#ifndef SIM
    call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), newAddr);
#else
    call setAmAddress(newAddr);
#endif
  }

  command void IPAddress.getLLAddr(struct in6_addr *addr) {
    memcpy(addr->s6_addr, linklocal_prefix, 8);
    memcpy(&addr->s6_addr[8], &__my_address.s6_addr[8], 8);
  }

  command void IPAddress.getIPAddr(struct in6_addr *addr) {
    __my_address.s6_addr16[7] = htons(TOS_NODE_ID);
    memcpy(addr, &__my_address, 16);
  }

  command struct in6_addr *IPAddress.getPublicAddr() {
    __my_address.s6_addr16[7] = htons(TOS_NODE_ID);
    return &__my_address;
  }

  command void IPAddress.setPrefix(uint8_t *pfx) {
    ip_memclr(__my_address.s6_addr, sizeof(struct in6_addr));
    ip_memcpy(__my_address.s6_addr, pfx, 8);
    globalPrefix = 1;
  }

  command bool IPAddress.haveAddress() {
    return globalPrefix;
  }

#ifndef SIM
  async event void ActiveMessageAddress.changed() {

  }
#endif

}
