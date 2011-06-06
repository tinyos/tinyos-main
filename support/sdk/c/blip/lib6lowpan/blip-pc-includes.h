#ifndef _BLIP_PC_INCLUDES_H_
#define _BLIP_PC_INCLUDES_H_

#include <stddef.h>
#include <string.h>
#include <stdio.h>

#if HAVE_CONFIG_H
#include "config.h"
#endif

#if HAVE_STDINT_H
# include <stdint.h>
#else
# if HAVE_INTTYPES_H
#  include <inttypes.h>
# else
#  error "no int types found!"
#endif
#endif // int types

#if HAVE_LINUX_IF_TUN_H
# include <linux/if_tun.h>
#else
// # error "TUN device not supported on this platform"
struct tun_pi {
  uint32_t af;
};
#endif

#if HAVE_NET_IF_H

// OSX prerequisites
#if HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#if HAVE_NET_ROUTE_H
#include <net/route.h>
#endif

# include <net/if.h> // for IFNAMSIZ
#else
# error "no IFNAMSIZE defined"
#endif


#if HAVE_NETINET_IN_H
# include <netinet/in.h>
#if ! HAVE_IN6_ADDR_S6_ADDR
# define s6_addr16 __u6_addr.__u6_addr16
# endif 
#else
# error "no netinet/in.h"
#endif

#if HAVE_ARPA_INET_H
# include <arpa/inet.h>
# include "nwbyte.h"
#else
# error "no htons routines!"
#endif

#include <ctype.h>

#endif
