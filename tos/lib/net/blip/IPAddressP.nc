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


  command ieee154_saddr_t IPAddress.getShortAddr() {
    return TOS_NODE_ID;
  }

  command void IPAddress.setShortAddr(ieee154_saddr_t newAddr) {
    TOS_NODE_ID = newAddr;
#ifndef SIM
    call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), newAddr);
#else
    call setAmAddress(newAddr);
#endif
  }

  command void IPAddress.getLLAddr(struct in6_addr *addr) {
    __my_address.s6_addr16[7] = htons(TOS_NODE_ID);
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

  command void IPAddress.setSource(struct ip6_hdr *hdr) {
    enum { LOCAL, GLOBAL } type = GLOBAL;
      
    if (hdr->ip6_dst.s6_addr[0] == 0xff) {
      // link-local multicast sent from local address
      if ((hdr->ip6_dst.s6_addr[1] & 0x0f) <= 0x2) {
        type = LOCAL;
      }
    } else if (hdr->ip6_dst.s6_addr[0] == 0xfe) {
      // link-local destinations sent from link-local
      if ((hdr->ip6_dst.s6_addr[1] & 0xf0) <= 0x80) {
        type = LOCAL;
      }
    }

    if (type == GLOBAL && call IPAddress.haveAddress()) {
      call IPAddress.getIPAddr(&hdr->ip6_src);
    } else {
      call IPAddress.getLLAddr(&hdr->ip6_src);
    }

  }


#ifndef SIM
  async event void ActiveMessageAddress.changed() {

  }
#endif

}
