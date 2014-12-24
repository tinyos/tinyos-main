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
 * Also implements router solicitations and router advertisements. These allow
 * nodes to discover routers if they are not using RPL.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */
#include <lib6lowpan/ip.h>
#include <lib6lowpan/lib6lowpan.h>

#include "blip_printf.h"
#include "neighbor_discovery.h"

module IPNeighborDiscoveryP {
  provides {
    interface IPForward;
    interface NeighborDiscovery;
    interface StdControl;
  }
  uses {
    interface IP as IP_RS;
    interface IP as IP_RA;
    interface IP as IP_NS;
    interface IP as IP_NA;

    interface Timer<TMilli> as RSTimer;

    interface Random;

    interface ForwardingTable;
    interface IPLower;
    interface IPAddress;
    interface Ieee154Address;

#if BLIP_ADDR_AUTOCONF
    interface SetIPAddress;
    interface LocalIeeeEui64;
#endif

  }
} implementation {

#define compare_ipv6(node1, node2) \
  (!memcmp((node1), (node2), sizeof(struct in6_addr)))
#define ADD_SECTION(SRC, LEN) ip_memcpy(cur, (uint8_t *)(SRC), LEN);\
  cur += (LEN); length += (LEN);

  struct in6_addr ALL_ROUTERS_ADDR;

  // Global prefix for this network
  struct in6_addr prefix;
  uint8_t prefix_length = 0;
  uint32_t prefix_valid_lifetime = 0;     // in seconds
  uint32_t prefix_preferred_lifetime = 0; // in seconds
  bool prefix_exists = FALSE;

  uint16_t rs_transmission_count = 0;

  command error_t StdControl.start() {

    inet_pton6(IPV6_ADDR_ALL_ROUTERS, &ALL_ROUTERS_ADDR);

    memset(&prefix, 0, sizeof(struct in6_addr));

#if BLIP_SEND_ROUTER_SOLICITATIONS
    // Set timer to send RS messages
    printf("IPNeighborDiscovery - start timer to send router solicitations\n");
    call RSTimer.startOneShot(call Random.rand32() % RTR_SOLICITATION_INTERVAL);
#endif

    return SUCCESS;
  }

  command error_t StdControl.stop () {
    call RSTimer.stop();

    return SUCCESS;
  }

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
      memcpy(ctx->s6_addr, me.s6_addr, 8);
      return 64;
    } else {
      return 0;
    }
  }

  command error_t NeighborDiscovery.resolveAddress(struct in6_addr *addr,
                                                   ieee154_addr_t *link_addr) {

    if (addr->s6_addr16[0] == htons(0xfe80)) {
      if (addr->s6_addr16[5] == htons(0x00FF) &&
          addr->s6_addr16[6] == htons(0xFE00)) {
        /* U bit must not be set if a short address is in use */
          link_addr->ieee_mode = IEEE154_ADDR_SHORT;
          link_addr->i_saddr = htole16(ntohs(addr->s6_addr16[7]));
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

  /*****************************************************************************
   ** PREFIX functions
   ****************************************************************************/
  command bool NeighborDiscovery.havePrefix() {
    return prefix_exists;
  }

  command void NeighborDiscovery.setPrefix(struct in6_addr* newprefix,
    uint8_t length, uint32_t valid_lifetime, uint32_t preferred_lifetime) {
    // Check if the prefix has changed
    if (!compare_ipv6(newprefix, &prefix) || (length != prefix_length)) {
      ip_memcpy((uint8_t*) &prefix, (uint8_t*) newprefix,
        sizeof(struct in6_addr));
      prefix_length = length;
      prefix_valid_lifetime = valid_lifetime;
      prefix_preferred_lifetime = preferred_lifetime;
      prefix_exists = TRUE;
    }
  }

  command struct in6_addr* NeighborDiscovery.getPrefix() {
    if (!prefix_exists) return NULL;
    return &prefix;
  }

  command uint8_t NeighborDiscovery.getPrefixLength() {
    return prefix_length;
  }


  /*****************************************************************************
   ** Router solicitation and advertisement functions
   ****************************************************************************/

  // Returns the length of the added option
  uint8_t add_sllao (uint8_t* data) {
    struct nd_option_slla_t sllao;

    sllao.type = ND6_OPT_SLLAO;
    sllao.option_length = 2; // length in multiples of 8 octets, need 10 bytes
                             // so we must round up to 16.
    sllao.ll_addr = call Ieee154Address.getExtAddr();

    ip_memcpy(data, (uint8_t*) &sllao, sizeof(struct nd_option_slla_t));
    memset(data+sizeof(struct nd_option_slla_t), 0,
      16-sizeof(struct nd_option_slla_t));
    return 16;
  }

  task void send_rs_task () {
    struct nd_router_solicitation_t msg;

    struct ip6_packet pkt;
    struct ip_iovec   v[1];

    uint8_t sllao_len;
    uint8_t data[60];
    uint8_t* cur = data;
    uint16_t length = 0;

    // Constructing a router solicitation message is straightforward. Mostly
    // just setting the ICMP header correctly.
    msg.icmpv6.type = ICMP_TYPE_ROUTER_SOL;
    msg.icmpv6.code = ICMPV6_CODE_RS;
    msg.icmpv6.checksum = 0;
    msg.reserved = 0;
    ADD_SECTION(&msg, sizeof(struct nd_router_solicitation_t));

    sllao_len = add_sllao(cur);
    cur += sllao_len;
    length += sllao_len;

    v[0].iov_base = data;
    v[0].iov_len = length;
    v[0].iov_next = NULL;

    pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    pkt.ip6_hdr.ip6_plen = htons(length);

    pkt.ip6_data = &v[0];

    printf("ND: Sending router solicitation\n");

    memcpy(&pkt.ip6_hdr.ip6_dst, &ALL_ROUTERS_ADDR, 16);
    call IPAddress.getLLAddr(&pkt.ip6_hdr.ip6_src);
    call IP_RS.send(&pkt);
  }

  void send_ra (ieee154_laddr_t* ll_addr) {
#if BLIP_SEND_ROUTER_ADVERTISEMENTS
    struct nd_router_advertisement_t ra;

    struct ip6_packet pkt;
    struct ip_iovec   v[1];

    uint8_t sllao_len;
    uint8_t data[120];
    uint8_t* cur = data;
    uint16_t length = 0;

    printf("IPNeighborDiscovery - RA - send\n");

    ra.icmpv6.type = ICMP_TYPE_ROUTER_ADV;
    ra.icmpv6.code = ICMPV6_CODE_RA;
    ra.icmpv6.checksum = 0;
    ra.hop_limit = 16;
    ra.flags_reserved = 0;
    ra.flags_reserved |= RA_FLAG_MANAGED_ADDR_CONF << ND6_RADV_M_SHIFT;
    ra.flags_reserved |= RA_FLAG_OTHER_CONF << ND6_RADV_O_SHIFT;
    ra.router_lifetime = RTR_LIFETIME;
    ra.reachable_time = 0; // unspecified at this point...
    ra.retransmit_time = 0; // unspecified at this point...
    ADD_SECTION(&ra, sizeof(struct nd_router_advertisement_t));

    sllao_len = add_sllao(cur);
    cur += sllao_len;
    length += sllao_len;

    if (prefix_exists) {
      struct nd_option_prefix_info_t po;

      po.type = ND6_OPT_PREFIX;
      po.option_length = 4;
      po.prefix_length = prefix_length;
      po.flags_reserved = 0;
      po.flags_reserved |= 0 << ND6_OPT_PREFIX_L_SHIFT;
      po.flags_reserved |= 1 << ND6_OPT_PREFIX_A_SHIFT;
      po.valid_lifetime = prefix_valid_lifetime;
      po.preferred_lifetime = prefix_preferred_lifetime;
      po.reserved2 = 0;
      ip_memcpy((uint8_t*) &po.prefix, (uint8_t*) &prefix,
        sizeof(struct in6_addr));
      ADD_SECTION(&po, sizeof(struct nd_option_prefix_info_t));
    }

    v[0].iov_base = data;
    v[0].iov_len = length;
    v[0].iov_next = NULL;

    pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    pkt.ip6_hdr.ip6_plen = htons(length);

    pkt.ip6_data = &v[0];

    if (ll_addr) {
      // Send unicast RA to the link local address
      memset(pkt.ip6_hdr.ip6_dst.s6_addr16, 0, sizeof(struct in6_addr));
      pkt.ip6_hdr.ip6_dst.s6_addr16[0] = htons(0xfe80);
      pkt.ip6_hdr.ip6_dst.s6_addr[8] = ll_addr->data[7];
      pkt.ip6_hdr.ip6_dst.s6_addr[9] = ll_addr->data[6];
      pkt.ip6_hdr.ip6_dst.s6_addr[10] = ll_addr->data[5];
      pkt.ip6_hdr.ip6_dst.s6_addr[11] = ll_addr->data[4];
      pkt.ip6_hdr.ip6_dst.s6_addr[12] = ll_addr->data[3];
      pkt.ip6_hdr.ip6_dst.s6_addr[13] = ll_addr->data[2];
      pkt.ip6_hdr.ip6_dst.s6_addr[14] = ll_addr->data[1];
      pkt.ip6_hdr.ip6_dst.s6_addr[15] = ll_addr->data[0];
      pkt.ip6_hdr.ip6_dst.s6_addr[8] ^= 0x2;
    } else {
      // Send multicast RA
      memcpy(&pkt.ip6_hdr.ip6_dst, &ALL_ROUTERS_ADDR, 16);
    }

    call IPAddress.getLLAddr(&pkt.ip6_hdr.ip6_src);
    call IP_RA.send(&pkt);
#endif
  }

  event void RSTimer.fired () {
    rs_transmission_count++;

    if (rs_transmission_count >= MAX_RTR_SOLICITATIONS) {
      // Hit the maximum amount of RS messages we're allowed to send quickly,
      // move to a slower rate
      call RSTimer.startOneShot(MAX_RTR_SOLICITATION_INTERVAL);
    } else {
      call RSTimer.startOneShot(RTR_SOLICITATION_INTERVAL);
    }

    post send_rs_task();
  }

  event void IP_NS.recv(struct ip6_hdr *hdr,
                        void *packet,
                        size_t len,
                        struct ip6_metadata *meta) {

    struct nd_neighbor_solicitation_t* ns;
    uint8_t* cur = (uint8_t*) packet;
    uint8_t type;
    uint8_t olen;

    ns = (struct nd_neighbor_solicitation_t*) packet;

    if (len < sizeof(struct nd_neighbor_solicitation_t)) {
      // Drop this packet
      return;

    }

    // Check to see if the SLLAO option is present
    cur += sizeof(struct nd_neighbor_solicitation_t);
    len -= sizeof(struct nd_neighbor_solicitation_t);

    if (len > 1) {
      // Get the type byte of the first option
      type = *cur;
      olen = *(cur+1) << 3;

      if (len >= olen && type == ND6_OPT_SLLAO) {
        struct nd_option_slla_t* sllao = (struct nd_option_slla_t*) cur;

        // TODO: handle this
      }
    }


    // Generate a response Neighbor Advertisement

    {
      struct nd_neighbor_advertisement_t na;

      struct ip6_packet pkt;
      struct ip_iovec   v[1];

      uint8_t data[120];
      uint16_t length = 0;
      cur = data;

      na.icmpv6.type = ICMP_TYPE_NEIGHBOR_ADV;
      na.icmpv6.code = ICMPV6_CODE_NS;
      na.icmpv6.checksum = 0;
      na.flags = 0;
      na.flags |= (1 << ND6_NADV_R_SHIFT);
      na.flags |= (1 << ND6_NADV_S_SHIFT);
      na.flags |= (1 << ND6_NADV_O_SHIFT);
      na.reserved1 = 0;
      na.reserved2 = 0;
      ip_memcpy((uint8_t*) &na.target_address, (uint8_t*) &ns->target_address,
        sizeof(struct in6_addr));
      ADD_SECTION(&na, sizeof(struct nd_neighbor_advertisement_t));

      v[0].iov_base = data;
      v[0].iov_len = length;
      v[0].iov_next = NULL;

      pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
      pkt.ip6_hdr.ip6_plen = htons(length);

      pkt.ip6_data = &v[0];

      ip_memcpy((uint8_t*) &pkt.ip6_hdr.ip6_dst, (uint8_t*) &hdr->ip6_src,
        sizeof(struct in6_addr));
      call IPAddress.getLLAddr(&pkt.ip6_hdr.ip6_src);
      call IP_NA.send(&pkt);
    }
  }

  event void IP_NA.recv(struct ip6_hdr *hdr,
                        void *packet,
                        size_t len,
                        struct ip6_metadata *meta) {
  }

  event void IP_RS.recv(struct ip6_hdr *hdr,
                        void *packet,
                        size_t len,
                        struct ip6_metadata *meta) {

    struct nd_option_slla_t* sllao;
    uint8_t* cur = (uint8_t*) packet;
    uint8_t type;
    uint8_t olen;

    printf("IPNeighborDiscovery - RS - recv\n");

    if (len <= sizeof(struct nd_router_solicitation_t)) {
      // There needs to be at least one option attached to this RS
      return;
    }

    // Skip the base of the packet (no unique information)
    cur += sizeof(struct nd_router_solicitation_t);
    len -= sizeof(struct nd_router_solicitation_t);

    while (TRUE) {
      if (len < 2) return;

      // Get the type byte of the first option
      type = *cur;
      olen = *(cur+1) << 3;

      if (len < olen) return;

      if (type == ND6_OPT_SLLAO) break;

      cur += olen;
      len -= olen;
    }

    // At this point cur is pointing at the SLLAO option
    sllao = (struct nd_option_slla_t*) cur;
    // TODO: handle this

    // Send a unicast RA in response to the RS
    send_ra(&sllao->ll_addr);
  }

  event void IP_RA.recv(struct ip6_hdr *hdr,
                        void *packet,
                        size_t len,
                        struct ip6_metadata *meta) {

    struct nd_router_advertisement_t* ra;
    uint8_t* cur = (uint8_t*) packet;
    uint8_t type;
    uint8_t olen;

    printf("IPNeighborDiscovery - RA recv\n");

    if (len < sizeof(struct nd_router_advertisement_t)) return;
    ra = (struct nd_router_advertisement_t*) packet;

    // TODO: update the hop limit we use on outgoing packets
    // hop_limit = ra->hop_limit;

    // Don't care if any DHCPv6 is available

    if (ra->router_lifetime != 0) {
      // TODO: use this
    }

    if (ra->reachable_time != 0) {
      // TODO: use this
    }

    // TODO: used with neighbor solicitations
    // ra->retransmit_time

    cur += sizeof(struct nd_router_advertisement_t);
    len -= sizeof(struct nd_router_advertisement_t);

    // Iterate through all options
    while (TRUE) {
      if (len < 2) break;

      // Get the type byte of the first option
      type = *cur;
      olen = *(cur+1) << 3;

      if (len < olen) return;

      switch (type) {
        case ND6_OPT_SLLAO: {
          struct route_entry* entry;
          // add to nbr cache

          entry = call ForwardingTable.lookupRoute(NULL, 0);

          if (entry == NULL) {
            // For now, just add this router as the default route
            // if we don't already have a default route
            call ForwardingTable.addRoute(NULL,
                                          0,
                                          &hdr->ip6_src,
                                          ROUTE_IFACE_154);
          }

          break;
        }

        case ND6_OPT_PREFIX: {
          struct nd_option_prefix_info_t* pio;
          uint8_t A;
          pio = (struct nd_option_prefix_info_t*) cur;

          printf("IPNeighborDiscovery - RA - got prefix\n");

  //        L currently unused
  //        L = (pio->flags_reserved & ND6_OPT_PREFIX_L_MASK) >>
  //            ND6_OPT_PREFIX_L_SHIFT;
          A = (pio->flags_reserved & ND6_OPT_PREFIX_A_MASK) >>
              ND6_OPT_PREFIX_A_SHIFT;

          if (A && pio->prefix_length > 0) {
            call NeighborDiscovery.setPrefix(&pio->prefix, pio->prefix_length,
              pio->valid_lifetime, pio->preferred_lifetime);

#if BLIP_ADDR_AUTOCONF
            {
              struct in6_addr newaddr;
              ieee154_laddr_t ext;

              // Update IP address
              memcpy(&newaddr, &pio->prefix, pio->prefix_length/8);
              ext = call LocalIeeeEui64.getId();
              memcpy(newaddr.s6_addr+8, ext.data, 8);
              newaddr.s6_addr[8] ^= 0x2;
              call SetIPAddress.setAddress(&newaddr);
            }
#endif
          }
          break;
        }

        case ND6_OPT_MTU:
          // TODO: update MTU
          break;

        default:
          // Ignore unknown messages
          break;
      }

      cur += olen;
      len -= olen;
    }

    call RSTimer.stop();

  }


  /**************** Send and Receive path of the stack ****************/
  /* this is where the translation to L2 addresses take place         */

  command error_t IPForward.send(struct in6_addr *next,
                                 struct ip6_packet *msg,
                                 void *ptr) {
    struct ieee154_frame_addr fr_addr;
    struct in6_addr local_addr;
    fr_addr.ieee_dstpan = call Ieee154Address.getPanId();
    call IPAddress.getLLAddr(&local_addr);

    // printf("IPNeighborDiscovery - send - next: ");
    // printf_in6addr(next);
    // printf(" - ll source: ");
    // printf_in6addr(&local_addr);
    // printf("\n");
    // iov_print(msg->ip6_data);

    if (call NeighborDiscovery.resolveAddress(&local_addr, &fr_addr.ieee_src) !=
        SUCCESS) {
      printf("IPND - local address resolution failed\n");
      return FAIL;
    }

    if (call NeighborDiscovery.resolveAddress(next, &fr_addr.ieee_dst) !=
        SUCCESS) {
      printf("IPND - next-hop address resolution failed\n");
      return FAIL;
    }
    printf("IPNeighborDiscovery: Converting to 15.4 addresses\n");
    printf(  "  source: "); printf_ieee154addr(&fr_addr.ieee_src);
    printf("\n  dest:   "); printf_ieee154addr(&fr_addr.ieee_dst);
    printf("\n");

    return call IPLower.send(&fr_addr, msg, ptr);
  }

  event void IPLower.recv(struct ip6_hdr *iph,
                          void *payload,
                          struct ip6_metadata *meta) {
    signal IPForward.recv(iph, payload, meta);
  }

  event void IPLower.sendDone(struct send_info *status) {
    signal IPForward.sendDone(status);
  }

  event void Ieee154Address.changed() {}
  event void IPAddress.changed(bool global_valid) {}
}
