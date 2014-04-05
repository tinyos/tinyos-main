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
#ifndef _IP_H_
#define _IP_H_

#include <string.h>

#include "lib6lowpan-includes.h"

/*
 * define message structures for internet communication
 *
 */

// HAVE_NETINET_IN_H ifdef removed since it is getting defined in libcoap
// and breaks CoAPBlip
// only needed for blip1.0 and ip-driver, because those were run on the
// host computer

#if ! PC
// update to use netinet/in definition of an IPv6 address; this is a
//  lot more elegent.
struct in6_addr
  {
    union
      {
	uint8_t	u6_addr8[16];
	uint16_t u6_addr16[8];
	uint32_t u6_addr32[4];
      } in6_u;
#define s6_addr			in6_u.u6_addr8
#define s6_addr16		in6_u.u6_addr16
#define s6_addr32		in6_u.u6_addr32
  };

struct sockaddr_in6 {
  uint16_t       sin6_port;
  struct in6_addr sin6_addr;
};
#else
#include <netinet/in.h>
#endif

/*
 * Definition for internet protocol version 6.
 * RFC 2460
 *      @(#)ip.h        8.1 (Berkeley) 6/10/93
 */
struct ip6_hdr {
  union {
    struct ip6_hdrctl {
      uint32_t ip6_un1_flow; /* 20 bits of flow-ID */
      uint16_t ip6_un1_plen; /* payload length */
      uint8_t  ip6_un1_nxt;  /* next header */
      uint8_t  ip6_un1_hlim; /* hop limit */
    } ip6_un1;
    uint8_t ip6_un2_vfc;   /* 4 bits version, top 4 bits class */
  } ip6_ctlun;
  struct in6_addr ip6_src; /* source address */
  struct in6_addr ip6_dst; /* destination address */
} __attribute__((packed));

#define ip6_vfc         ip6_ctlun.ip6_un2_vfc
#define ip6_flow        ip6_ctlun.ip6_un1.ip6_un1_flow
#define ip6_plen        ip6_ctlun.ip6_un1.ip6_un1_plen
#define ip6_nxt         ip6_ctlun.ip6_un1.ip6_un1_nxt
#define ip6_hlim        ip6_ctlun.ip6_un1.ip6_un1_hlim
#define ip6_hops        ip6_ctlun.ip6_un1.ip6_un1_hlim

#define IPV6_VERSION            0x60
#define IPV6_VERSION_MASK       0xf0

#if BYTE_ORDER == BIG_ENDIAN
#define IPV6_FLOWINFO_MASK      0x0fffffff      /* flow info (28 bits) */
#define IPV6_FLOWLABEL_MASK     0x000fffff      /* flow label (20 bits) */
#else
#if BYTE_ORDER == LITTLE_ENDIAN
#define IPV6_FLOWINFO_MASK      0xffffff0f      /* flow info (28 bits) */
#define IPV6_FLOWLABEL_MASK     0xffff0f00      /* flow label (20 bits) */
#endif /* LITTLE_ENDIAN */
#endif
#if 1
/* ECN bits proposed by Sally Floyd */
#define IP6TOS_CE               0x01    /* congestion experienced */
#define IP6TOS_ECT              0x02    /* ECN-capable transport */
#endif

/*
 * Extension Headers
 */
struct ip6_ext {
  uint8_t ip6e_nxt;
  uint8_t ip6e_len;
};

struct tlv_hdr {
  uint8_t type;
  uint8_t len;
};
/*
 * IP protocol numbers
 */
enum {
  IANA_ICMP = 58,
  IANA_UDP = 17,
  IANA_TCP = 6,


  // IPV6 defined extention header types.  All other next header
  // values are supposed to be transport protocols, with TLVs used
  IPV6_HOP = 0,
  IPV6_IPV6 = 41,
  IPV6_ROUTING = 43,
  IPV6_FRAG = 44,
  IPV6_AUTH = 51,
  IPV6_SEC = 50,
  IPV6_NONEXT = 59,
  IPV6_DEST = 60,
  IPV6_MOBILITY = 135,

  IPV6_TLV_PAD1 = 0,
  IPV6_TLV_PADN = 1,
};
#define EXTENSION_HEADER(X) ((X) == IPV6_HOP || (X) == IPV6_ROUTING || (X) == IPV6_DEST)
#define COMPRESSIBLE_TRANSPORT(X) ((X) == IANA_UDP)

/* interface id */
struct in6_iid {
  uint8_t data[8];
};

/*
 * icmp
 */
struct  icmp6_hdr {
  uint8_t        type;     /* type field */
  uint8_t        code;     /* code field */
  uint16_t       cksum;    /* checksum field */
};

enum {
    ICMP_TYPE_ECHO_DEST_UNREACH     = 1,
    ICMP_TYPE_ECHO_PKT_TOO_BIG      = 2,
    ICMP_TYPE_ECHO_TIME_EXCEEDED    = 3,
    ICMP_TYPE_ECHO_PARAM_PROBLEM    = 4,
    ICMP_TYPE_ECHO_REQUEST          = 128,
    ICMP_TYPE_ECHO_REPLY            = 129,
    ICMP_TYPE_ROUTER_SOL            = 133,
    ICMP_TYPE_ROUTER_ADV            = 134,
    ICMP_TYPE_NEIGHBOR_SOL          = 135,
    ICMP_TYPE_NEIGHBOR_ADV          = 136,
    ICMP_TYPE_RPL_CONTROL           = 155,
    ICMP_NEIGHBOR_HOPLIMIT          = 255,

    ICMP_CODE_HOPLIMIT_EXCEEDED     = 0,
    ICMP_CODE_ASSEMBLY_EXCEEDED     = 1,
};

/*
 * UDP protocol header.
 */
struct udp_hdr {
    uint16_t srcport;               /* source port */
    uint16_t dstport;               /* destination port */
    uint16_t len;                   /* udp length */
    uint16_t chksum;                /* udp checksum */
};

/*
 * TCP transport headers and flags
 */
enum {
  TCP_FLAG_FIN = 0x1,
  TCP_FLAG_SYN = 0x2,
  TCP_FLAG_RST = 0x4,
  TCP_FLAG_PSH = 0x8,
  TCP_FLAG_ACK = 0x10,
  TCP_FLAG_URG = 0x20,
  TCP_FLAG_ECE = 0x40,
  TCP_FLAG_CWR = 0x80,
};

struct tcp_hdr {
  uint16_t srcport;
  uint16_t dstport;
  uint32_t seqno;
  uint32_t ackno;
  uint8_t offset;
  uint8_t flags;
  uint16_t window;
  uint16_t chksum;
  uint16_t urgent;
};

/*
 * IP metadata and routing structures
 *
 * The metadata contains L2 information that upper layers may be
 * interested in for one reason or another.
 */
struct ip6_metadata {
  ieee154_addr_t sender;
  // platforms commonly provide one or both of these indicators
  uint8_t   lqi;
  uint8_t   rssi;
};


/*
 * These are data structures to hold IP messages.  We used a linked
 * list of headers so that we can easily add extra headers with no
 * copy; similar to the linux iovec's or BSD mbuf structs.
 * Every split_ip_msg contains a full IPv6 header (40 bytes), but it
 * is placed at the end of the struct so that we can read() a message
 * straight into one of these structs, and then just set up the header
 * chain.
 *
 * Due to the way fragmentation is currently implemented, the total
 * length of the data referenced from this chain must not be longer
 * then what can fit into a single fragment.  This is a limitation of
 * the current fragmentation code, but is perfectly usable in most
 * cases.
 */

struct ip6_packet {
  int ip6_inputif;
  struct ip_iovec  *ip6_data;
  struct ip6_hdr ip6_hdr;
};
#define IP6PKT_TRANSPORT 0xff

#ifndef NO_LIB6LOWPAN_ASCII
/*
 * parse a string representation of an IPv6 address
 */
void inet_pton6(char *addr, struct in6_addr *dest);
int  inet_ntop6(struct in6_addr *addr, char *buf, int cnt);
#endif


#define POINTER_DIFF(AP, BP) (((char *)AP) - ((char *)BP))
#define POINTER_SUM(AP, B) (((char *)AP) + (B))

#endif

