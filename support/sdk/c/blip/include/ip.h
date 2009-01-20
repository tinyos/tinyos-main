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

/*
 * define message structures for internet communication
 *
 */

#ifdef PC
#include <linux/if_tun.h>
#include <netinet/in.h>
#endif

#include "6lowpan.h"

enum {
  /*
   * The time, in binary milliseconds, after which we stop waiting for
   * fragments and report a failed receive.  We 
   */
  FRAG_EXPIRE_TIME = 4096,
};


#ifndef PC
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
  uint16_t sin6_port;
  struct in6_addr sin6_addr;
};
#endif

/*
 * Definition for internet protocol version 6.
 * RFC 2460
 */
struct ip6_hdr {
  uint8_t   vlfc[4];
  uint16_t  plen;          /* payload length */
  uint8_t   nxt_hdr;       /* next header */
  uint8_t   hlim;          /* hop limit */
  struct in6_addr ip6_src; /* source address */
  struct in6_addr ip6_dst; /* destination address */
} __attribute__((packed));

#define IPV6_VERSION            0x6
#define IPV6_VERSION_MASK       0xf0


/*
 * Extension Headers
 */

struct ip6_ext {
  uint8_t nxt_hdr;
  uint8_t len;
  uint8_t data[0];
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
 */
struct ip_metadata {
  hw_addr_t sender;
  uint8_t   lqi;
  uint8_t   padding[1];
};

struct flow_match {
  cmpr_ip6_addr_t src;
  cmpr_ip6_addr_t dest; // Need to make this more extensible at some point
  cmpr_ip6_addr_t prev_hop;
};

struct rinstall_header {
  struct ip6_ext ext;
  uint16_t flags;
  struct flow_match match;
  uint8_t path_len;
  uint8_t current;
  cmpr_ip6_addr_t path[0];
};

enum {
  R_SRC_FULL_PATH_INSTALL_MASK = 0x01,
  R_DEST_FULL_PATH_INSTALL_MASK = 0x02,
  R_HOP_BY_HOP_PATH_INSTALL_MASK = 0x04,
  R_REVERSE_PATH_INSTALL_MASK = 0x08,
  R_SRC_FULL_PATH_UNINSTALL_MASK = 0x10,
  R_DEST_FULL_PATH_UNINSTALL_MASK = 0x20,
  R_HOP_BY_HOP_PATH_UNINSTALL_MASK = 0x40,
  R_REVERSE_PATH_UNINSTALL_MASK = 0x80,
};

#define IS_FULL_SRC_INSTALL(r) (((r)->flags & R_SRC_FULL_PATH_INSTALL_MASK) == R_SRC_FULL_PATH_INSTALL_MASK)
#define IS_FULL_DST_INSTALL(r) (((r)->flags & R_DEST_FULL_PATH_INSTALL_MASK) == R_DEST_FULL_PATH_INSTALL_MASK)
#define IS_HOP_INSTALL(r) (((r)->flags & R_HOP_BY_HOP_PATH_INSTALL_MASK) == R_HOP_BY_HOP_PATH_INSTALL_MASK)
#define IS_REV_INSTALL(r) (((r)->flags & R_REVERSE_PATH_INSTALL_MASK) == R_REVERSE_PATH_INSTALL_MASK)
#define IS_FULL_SRC_UNINSTALL(r) (((r)->flags & R_SRC_FULL_PATH_UNINSTALL_MASK) == R_SRC_FULL_PATH_UNINSTALL_MASK)
#define IS_FULL_DST_UNINSTALL(r) (((r)->flags & R_DEST_FULL_PATH_UNINSTALL_MASK) == R_DEST_FULL_PATH_UNINSTALL_MASK)
#define IS_HOP_UNINSTALL(r) (((r)->flags & R_HOP_BY_HOP_PATH_UNINSTALL_MASK) == R_HOP_BY_HOP_PATH_UNINSTALL_MASK)
#define IS_REV_UNINSTALL(r) (((r)->flags & R_REVERSE_PATH_UNINSTALL_MASK) == R_REVERSE_PATH_UNINSTALL_MASK)

enum {
  T_INVAL_NEIGH =  0xef,
  T_SET_NEIGH = 0xee,
};

struct flow_id {
  uint16_t src;
  uint16_t dst;
  uint16_t id;
  uint16_t seq;
  uint16_t nxt_hdr;
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
struct generic_header {
#ifdef PC
  int payload_malloced:1;
#endif
  uint8_t len;
  union {
    // this could be an eumeration of all the valid headers we can have here.
    struct ip6_ext *ext;
    struct source_header *sh;
    struct udp_hdr *udp;
    struct tcp_hdr *tcp;
    struct rinstall_header *rih;
    struct topology_header *th;
    uint8_t *data;
  } hdr;
  struct generic_header *next;
};

struct split_ip_msg {
  struct generic_header *headers;
  uint16_t data_len;
  uint8_t *data;
#ifdef PC
  struct ip_metadata metadata;
#ifdef DBG_TRACK_FLOWS
  struct flow_id id;
#endif
  // this must be last so we can read() straight into the end of the buffer.
  struct tun_pi pi;
#endif
  struct ip6_hdr hdr;
  uint8_t next[0];
};

/*
 * parse a string representation of an IPv6 address
 */ 
void inet_pton6(char *addr, struct in6_addr *dest);

#endif
