
#include <lib6lowpan/ip.h>

interface NeighborDiscovery {

  /**
   * Map the IPv6 address to a link-layer address.
   * @return FAIL if the address cannot be resolved, either becasue 
   * it is not known or because the given IPv6 address is not on the link.
   */
  command error_t resolveAddress(struct in6_addr *addr, ieee154_addr_t *link_addr);

  /**
   * Match 
   */
  command int matchContext(struct in6_addr *addr, uint8_t *ctx);
  command int getContext(uint8_t context, struct in6_addr *ctx);
}
