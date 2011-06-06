/**
 * Neighbor Discovery for blip
 *
 * In IPv6, neighbor discovery resolves IPv6 addresses which have been
 * determined to be on-link to their associated link-layer addresses.
 * This simple component follows the advice of 6lowpan-nd, which
 * states that link-local addresses are derived from the associated
 * link-layer addressed deterministically.  Therefore, we can do a
 * very simple translation between the two types of addresses.
 *
 * In the future, implementors could consider adding more complicated
 * address resolution mechanisms here.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */
#include <lib6lowpan/ip.h>

#include "blip_printf.h"

module IPNeighborDiscoveryP {
  provides {
    interface IPForward;
    interface NeighborDiscovery;
  } 
  uses {
    interface IPLower;
    interface IPAddress;
    interface Ieee154Address;
  }
} implementation {

  command int NeighborDiscovery.matchContext(struct in6_addr *addr, 
                                             uint8_t *ctx) {
    struct in6_addr me;
    if (!(call IPAddress.getGlobalAddr(&me))) return 0;
    if (memcmp(me.s6_addr, addr->s6_addr, 8) == 0) {
      *ctx = 0;
      return 64;
    } else {
      return 0;
    }
  }

  command int NeighborDiscovery.getContext(uint8_t context, 
                                           struct in6_addr *ctx) {
    struct in6_addr me;
    if (!(call IPAddress.getGlobalAddr(&me))) return 0;
    if (context == 0) {
      // memset(ctx->s6_addr, 0, 8);
      // ctx->s6_addr16[0] = htons(0xaaaa);
      memcpy(ctx->s6_addr, me.s6_addr, 8);
      return 64;
    } else {
      return 0;
    }
  }

  command error_t NeighborDiscovery.resolveAddress(struct in6_addr *addr,
                                                   ieee154_addr_t *link_addr) {
    ieee154_panid_t panid = letohs(call Ieee154Address.getPanId());

    if (addr->s6_addr16[0] == htons(0xfe80)) {
      if (addr->s6_addr16[5] == htons(0x00FF) &&
          addr->s6_addr16[6] == htons(0xFE00)) {
        /* U bit must not be set if a short address is in use */
        if (ntohs(addr->s6_addr16[4]) == (panid & ~0x0200)) {
          link_addr->ieee_mode = IEEE154_ADDR_SHORT;
          link_addr->i_saddr = htole16(ntohs(addr->s6_addr16[7]));
        } else {
          return FAIL;
        }
      } else {
        int i;
        link_addr->ieee_mode = IEEE154_ADDR_EXT;
        for (i = 0; i < 8; i++)
          link_addr->i_laddr.data[i] = addr->s6_addr[15 - i];
        link_addr->i_laddr.data[7] ^= 0x2;    /* toggle U/L */
      }
      return SUCCESS;
    } else if (addr->s6_addr[0] == 0xff) {
      /* LL - multicast */
      if ((addr->s6_addr[1] & 0x0f) == 0x02) {
        link_addr->ieee_mode = IEEE154_ADDR_SHORT;
        link_addr->i_saddr   = IEEE154_BROADCAST_ADDR;
        return SUCCESS;
      }
    }
    /* only resolve Link-Local addresses */
    return FAIL;
  }

  /**************** Send and Receive path of the stack ****************/
  /* this is where the translation to L2 addresses take place         */

  command error_t IPForward.send(struct in6_addr *next, struct ip6_packet *msg, void *ptr) {
    struct ieee154_frame_addr fr_addr;
    struct in6_addr local_addr;
    fr_addr.ieee_dstpan = call Ieee154Address.getPanId();
    call IPAddress.getLLAddr(&local_addr);

    printf("IPNeighborDiscovery - send - next: ");
    printf_in6addr(next);
    printf(" - ll source: ");
    printf_in6addr(&local_addr);
    printf("\n");
    // iov_print(msg->ip6_data);

    if (call NeighborDiscovery.resolveAddress(&local_addr, &fr_addr.ieee_src) != SUCCESS) {
      printf("IPND - local address resolution failed\n");
      return FAIL;
    }

    if (call NeighborDiscovery.resolveAddress(next, &fr_addr.ieee_dst) != SUCCESS) {
      printf("IPND - next-hop address resolution failed\n");
      return FAIL;
    }
    printf("l2 source: "); printf_buf(fr_addr.ieee_src.i_laddr.data, 8);
    printf("l2 dest: "); printf_buf(fr_addr.ieee_dst.i_laddr.data, 8);
    printf("\n");

    return call IPLower.send(&fr_addr, msg, ptr);
  }

  event void IPLower.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta) {
    signal IPForward.recv(iph, payload, meta);
  }

  event void IPLower.sendDone(struct send_info *status) {
    signal IPForward.sendDone(status);
  }

  event void Ieee154Address.changed() {}
  event void IPAddress.changed(bool global_valid) {}
}
