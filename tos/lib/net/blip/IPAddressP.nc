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
  uses {
    interface CC2420Config;
    interface LocalIeeeEui64;
  }
} implementation {

  command bool IPAddress.getLLAddr(struct in6_addr *addr) {
    // ieee_eui64_t eui = call LocalIeeeEui64.getId();
    // memcpy(&addr->s6_addr[8], eui.data, 8);
    ieee154_panid_t panid = call CC2420Config.getPanAddr();
    ieee154_saddr_t saddr = call CC2420Config.getShortAddr();

    memclr(addr->s6_addr, 16);
    addr->s6_addr16[0] = htons(0xfe80);
    addr->s6_addr16[4] = htons(panid);
    addr->s6_addr16[5] = ntohs(0x00FF);
    addr->s6_addr16[6] = ntohs(0xFE00);
    addr->s6_addr16[7] = htons(saddr);

    return TRUE;
  }

  command bool IPAddress.getGlobalAddr(struct in6_addr *addr) {
    return FALSE;
  }

  command bool IPAddress.setSource(struct ip6_hdr *hdr) {
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

    return call IPAddress.getLLAddr(&hdr->ip6_src);
  }

  command error_t IPAddress.resolveAddress(struct in6_addr *addr, ieee154_addr_t *link_addr) {
    ieee154_panid_t panid = call CC2420Config.getPanAddr();

    if (addr->s6_addr16[0] == htons(0xfe80)) {
      if (addr->s6_addr16[5] == htons(0x00FF) &&
          addr->s6_addr16[6] == htons(0xFE00)) {
        if (ntohs(addr->s6_addr16[4]) == panid) {
          link_addr->ieee_mode = IEEE154_ADDR_SHORT;
          link_addr->i_saddr = htole16(ntohs(addr->s6_addr16[7]));
        } else {
          return FAIL;
        }
      } else {
        link_addr->ieee_mode = IEEE154_ADDR_EXT;
        memcpy(link_addr->i_laddr.data, &addr->s6_addr[8], 8);
      }
      return SUCCESS;
    } else if (addr->s6_addr[0] == 0xff) {
      /* LL - multicast */
      if ((addr->s6_addr[1] & 0x0f) == 0x02) {
        link_addr->ieee_mode = IEEE154_ADDR_SHORT;
        link_addr->i_saddr   = IEEE154_BROADCAST_ADDR;
        return TRUE;
      }
    }
    /* only resolve Link-Local addresses */
    return FAIL;
  }

  command bool IPAddress.isLocalAddress(struct in6_addr *addr) {
    ieee_eui64_t eui = call LocalIeeeEui64.getId();
    ieee154_panid_t panid = call CC2420Config.getPanAddr();
    ieee154_saddr_t saddr = call CC2420Config.getShortAddr();

    if (addr->s6_addr16[0] == htons(0xfe80)) {
      // link-local
      if (addr->s6_addr16[5] == ntohs(0x00FF) &&
          addr->s6_addr16[6] == ntohs(0xFE00)) {
        if (ntohs(addr->s6_addr16[4]) == panid && 
            ntohs(addr->s6_addr16[7]) == saddr) {
          return TRUE;
        } else {
          return FALSE;
        }
      } else {
        if (memcmp(&addr->s6_addr[8], eui.data, 8) == 0) {
          return TRUE;
        }
      }
    } else if (addr->s6_addr[0] == 0xff) {
      // multicast
      if ((addr->s6_addr[1] & 0x0f) <= 2) {
        // accept all LL multicast messages
        return TRUE;
      }
    }
    return FALSE;
  }

  event void CC2420Config.syncDone( error_t err ) {

  }

}
