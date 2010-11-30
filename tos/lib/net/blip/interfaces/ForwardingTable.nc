
#include <iprouting.h>

interface ForwardingTable {

  /**
   * Insert a forwarding-table mapping for the given prefix, with the
   * given next-hop.
   */
  command route_key_t addRoute(const uint8_t *prefix, int prefix_len_bits,
                               struct in6_addr *next_hop, uint8_t ifindex);

  /**
   * Remove a routing table entry previously inserted using addRoute
   */
  command error_t delRoute(route_key_t key);

  command struct route_entry *lookupRoute(const uint8_t *prefix, int prefix_len_bits);

  command struct route_entry *lookupRouteKey(route_key_t key);

  command struct route_entry *getTable(int *size);
}
