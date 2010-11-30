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

#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/6lowpan.h>

module IPAddressP {
  provides {
    interface IPAddress;
  }
  uses {
    interface Ieee154Address;
  }
} implementation {
  bool m_valid_addr = FALSE, m_short_addr = FALSE;
  struct in6_addr m_addr;

  command bool IPAddress.getLLAddr(struct in6_addr *addr) {
    ieee154_panid_t panid = call Ieee154Address.getPanId();
    ieee154_saddr_t saddr = call Ieee154Address.getShortAddr();
    ieee154_laddr_t laddr = call Ieee154Address.getExtAddr();

    memclr(addr->s6_addr, 16);
    addr->s6_addr16[0] = htons(0xfe80);
    if (m_short_addr) {
      addr->s6_addr16[4] = htons(panid);
      addr->s6_addr16[5] = htons(0x00FF);
      addr->s6_addr16[6] = htons(0xFE00);
      addr->s6_addr16[7] = htons(saddr);
    } else {
      memcpy(&addr->s6_addr[8], laddr.data, 8);
    }

    return TRUE;
  }

  command bool IPAddress.getGlobalAddr(struct in6_addr *addr) {
    *addr = m_addr;
    return m_valid_addr;
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

    if (type == LOCAL) {
      return call IPAddress.getLLAddr(&hdr->ip6_src);
    } else {
      return call IPAddress.getGlobalAddr(&hdr->ip6_src);
    }
  }

  command bool IPAddress.isLocalAddress(struct in6_addr *addr) {
    ieee154_panid_t panid = call Ieee154Address.getPanId();
    ieee154_saddr_t saddr = call Ieee154Address.getShortAddr();
    ieee154_laddr_t eui = call Ieee154Address.getExtAddr();

    if (addr->s6_addr16[0] == htons(0xfe80)) {
      // link-local
      if (m_short_addr && 
          addr->s6_addr16[5] == ntohs(0x00FF) &&
          addr->s6_addr16[6] == ntohs(0xFE00)) {
        if (ntohs(addr->s6_addr16[4]) == panid && 
            ntohs(addr->s6_addr16[7]) == saddr) {
          return TRUE;
        } else {
          return FALSE;
        }
      } 
      if (memcmp(&addr->s6_addr[8], eui.data, 8) == 0) {
        return TRUE;
      }
    } else if (addr->s6_addr[0] == 0xff) {
      // multicast
      if ((addr->s6_addr[1] & 0x0f) <= 2) {
        // accept all LL multicast messages
        return TRUE;
      }
    } else if (memcmp(addr->s6_addr, m_addr.s6_addr, 16) == 0) {
      return TRUE;
    }
    return FALSE;
  }

  /* Check if the address needs routing or of it's link local in scope
   */
  command bool IPAddress.isLLAddress(struct in6_addr *addr) {
    if (addr->s6_addr16[0] == htons(0xfe80) ||
        (addr->s6_addr[0] == 0xff &&
         (addr->s6_addr[1] & 0x0f) <= 2))
      return TRUE;
    return FALSE;
  }

  command error_t IPAddress.setAddress(struct in6_addr *addr) {
    m_addr = *addr;
    if (m_addr.s6_addr[8] == 0 &&
        m_addr.s6_addr[9] == 0 &&
        m_addr.s6_addr[10] == 0 &&
        m_addr.s6_addr[11] == 0 &&
        m_addr.s6_addr[12] == 0 &&
        m_addr.s6_addr[13] == 0) {
      call Ieee154Address.setShortAddr(ntohs(m_addr.s6_addr16[7]));
      m_short_addr = TRUE;
    } else {
      call Ieee154Address.setShortAddr(0);
      m_short_addr = FALSE;
    }

    m_valid_addr = TRUE;
    signal IPAddress.changed(TRUE);
    return SUCCESS;
  }

  command error_t IPAddress.removeAddress() {
    m_valid_addr = FALSE;
    m_short_addr = FALSE;
    signal IPAddress.changed(FALSE);
    return SUCCESS;
  }

  event void Ieee154Address.changed() {}

}
