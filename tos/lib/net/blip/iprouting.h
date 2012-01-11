#ifndef _IPROUTING_H_
#define _IPROUTING_H_

#include <lib6lowpan/ip.h>

enum {
  ROUTE_INVAL_KEY = -1,
};

#ifndef ROUTE_TABLE_SZ 
#define ROUTE_TABLE_SZ 20
#endif

enum {
  ROUTE_IFACE_ALL = 0,
  ROUTE_IFACE_154 = 1,
  ROUTE_IFACE_PPP = 2,
};

enum {
  ROUTE_DROP_NOROUTE,
  ROUTE_DROP_HLIM,
};

typedef int route_key_t;

struct route_entry {
  int valid:1;                  /* table entry is valid */
  route_key_t key;              /* a key used to identify this entry */
  struct in6_addr prefix;       /* destination */
  uint8_t prefixlen;            /* how many bits of the destination to match on */
  struct in6_addr next_hop;     /* next hop (must be an on-link address) */
  uint8_t ifindex;              /* interface index to send the packet out on */
};

#endif
