/*
 * Copyright (c) 2007 Matus Harvan
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * The structures are based on the ones from FreeBSD header files
 * in /usr/include/netinet6/, which are distributed unred the following
 * copyright:
 *
 * Copyright (C) 1995, 1996, 1997, and 1998 WIDE Project.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the project nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * Copyright (c) 1982, 1986, 1990, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Header file for the 6lowpan/IPv6 stack.
 */

#ifndef __IP_INTERNAL_H__
#define __IP_INTERNAL_H__

enum {
    HW_ADDR_SHORT,
    HW_ADDR_LONG
};

typedef struct hw_addr {
    uint8_t type; // HW_ADDR_SHORT | HW_ADDR_LONG
    union {
	uint8_t addr_short[2];
	uint8_t addr_long[8];
    };
} hw_addr_t;

/* number of packets in SendPktPool */
#define SEND_PKTS 1

/* number of fragment reassembly buffers */
#define FRAG_BUFS 1

/* timeout for discarding a fragment reassembly buffer
 * 60 seconds max in 6lowpan draft */
#define FRAG_TIMEOUT 10

/* number of fragments per reassembled datagram */
#define FRAGS_PER_DATAGRAM 15

/* fragment reassembmly buffer size */
#define FRAG_BUF_SIZE 1280

/* default IPv6 Hop Limit for outgoing packets (except Neighbor Discovery) */
#define IP_HOP_LIMIT 64

#define LOWPAN_MTU 1280
#define LOWPAN_OVERHEAD 17
// 16 bytes opt. headers and 1 byte dispatch
#define LINK_DATA_MTU 100
// 802.15.4 space left after the 802.15.4 header: 128 - xx = 102 bytes max


/* size of app_data buffer */
#define LOWPAN_APP_DATA_LEN FRAG_BUF_SIZE
/* maximum length of 6lowpan headers */
//#define LOWPAN_HEADER_LEN 49
#define LOWPAN_HEADER_LEN 102

/* flag marking an unused fragment reassembly buffer/structure */
#define FRAG_FREE 0xFF

/* 6lowpan dispatch values */
#define DISPATCH_UNCOMPRESSED_IPV6 0x41
#define DISPATCH_COMPRESSED_IPV6 0x42

#define DISPATCH_FIRST_FRAG 0xC0
#define DISPATCH_SUBSEQ_FRAG 0xE0
#define DISPATCH_FRAG_MASK 0xF8

#define DISPATCH_BC0 0x50

#define DISPATCH_MESH 0x80
#define DISPATCH_MESH_MASK 0xC0
#define DISPATCH_MESH_O_FLAG 0x20
#define DISPATCH_MESH_F_FLAG 0x10
#define DISPATCH_MESH_HOPSLEFT_MASK 0x0F

enum {
    /* lowpan_pkt_t.app_data_dealloc */
    APP_DATA_DEALLOC_FALSE=0,
    APP_DATA_DEALLOC_TRUE=1,

    /* lowpan_pkt_t.notify_num */
    LOWPAN_PKT_NO_NOTIFY = 0,

    /* HC1 encoding */
    HC1_SRC_PREFIX_MASK = 0x80,
    HC1_SRC_PREFIX_LINKLOCAL = 0x80,
    HC1_SRC_PREFIX_INLINE = 0,
    HC1_SRC_IFACEID_MASK = 0x40,
    HC1_SRC_IFACEID_COMRP = 0x40,
    HC1_SRC_IFACEID_INLINE = 0,

    HC1_DST_PREFIX_MASK = 0x20,
    HC1_DST_PREFIX_LINKLOCAL = 0x20,
    HC1_DST_PREFIX_INLINE = 0,
    HC1_DST_IFACEID_MASK = 0x10,
    HC1_DST_IFACEID_COMRP = 0x10,
    HC1_DST_IFACEID_INLINE = 0,

    HC1_TCFL_MASK = 0x08,
    HC1_TCFL_ZERO = 0x08,
    HC1_TCFL_INLINE = 0,

    HC1_NEXTHDR_MASK = 0x06,
    HC1_NEXTHDR_INLINE = 0,
    HC1_NEXTHDR_UDP = 0x02,
    HC1_NEXTHDR_ICMP = 0x04,
    HC1_NEXTHDR_TCP = 0x06,

    HC1_HC2_MASK = 0x01,
    HC1_HC2_PRESENT = 0x01,
    HC1_HC2_NONE = 0,

    HC2_UDP_P_VALUE = 0x61616,

    HC2_UDP_SRC_PORT_MASK = 0x80,
    HC2_UDP_SRC_PORT_COMPR = 0x80,
    HC2_UDP_SRC_PORT_INLINE = 0,

    HC2_UDP_DST_PORT_MASK = 0x40,
    HC2_UDP_DST_PORT_COMPR = 0x40,
    HC2_UDP_DST_PORT_INLINE = 0,

    HC2_UDP_LEN_MASK = 0x20,
    HC2_UDP_LEN_COMPR = 0x20,
    HC2_UDP_LEN_INLINE = 0
};

/* used for fragment reassembly */
typedef struct _frag_info_t {
    uint8_t offset;
    uint8_t len;
    struct _frag_info_t *next;
} frag_info_t;

/* used for fragment reassembly */
typedef struct _app_data_t {
    uint8_t buf[LOWPAN_MTU];
} app_data_t;

/* used for fragment reassembly */
typedef struct _frag_buf_t {
    uint8_t *buf;          /* usually a pointer to app_data_t */
    hw_addr_t hw_src_addr;
    hw_addr_t hw_dst_addr;
    uint16_t dgram_tag;    /* network byte order */
    uint16_t dgram_size;   /* host byte order */
    uint8_t frag_timeout;  /* discarded when zero is reached
			    * FRAG_FREE means not used at the moment */

    frag_info_t *frag_list; /* sorted by offset in decreasing order */
} frag_buf_t;

/*
 * sending - application provides app_data and clears app_data_dealloc
 *         - a pointer to app_data is returned in sendDone to do deallocation
 * receiving with fragment reassembly
 *           - IPP provides app_data and sets app_data_dealloc
 *           - header_begin is set to point into app_data
 *             and the received packet is put into app_data
 * receiving without fragment reassembly
 *           - the complete 802.15.4 frame is put into header
 *             (802.15.4 header is left out) and heade_begin points into header
 */
typedef struct _lowpan_pkt_t {
    /* buffers */
    uint8_t  *app_data;         /* buffer for application data */
    uint16_t  app_data_len;     /* how much data is in the buffer */
    uint8_t  *app_data_begin;   /* start of the data in the buffer */
    uint8_t   app_data_dealloc; /* shall IPC deallocate the app_data buffer?
                           /* APP_DATA_DEALLOC_FALSE | APP_DATA_DEALLOC_TRUE */

    uint8_t header[LINK_DATA_MTU]; /* buffer for the header (tx)
                                    * or unfragmented 802.15.4 frame (rx) */
    uint16_t  header_len;          /* how much data is in the buffer */
    uint8_t *header_begin;         /* start of the data in the buffer */

    /* fragmentation */
    uint16_t dgram_tag;     /* network byte order */
    uint16_t dgram_size;    /* host byte order */
    uint8_t dgram_offset;   /* offset where next fragment starts (tx)
                             * (in multiples of 8 bytes) */
    /* IP addresses */
    ip6_addr_t ip_src_addr; /* needed for ND and usefull elsewhere */ 
    ip6_addr_t ip_dst_addr; /* both IP addresses filled in by ipv6*_input */
    /* 802.15.4 addresses */
    hw_addr_t hw_src_addr; 
    hw_addr_t hw_dst_addr;  /* 802.15.4 MAC addresses
			     * needed for fragment identification
			     * needed for 6lowpan IPv6 header decompression
			     * contains mesh header entries if applicable
			     */
    /* to notify app with sendDone */
    uint8_t notify_num;     /* num of UDPClient + 1, 0 means o not notify */

    struct _lowpan_pkt_t *next;
} lowpan_pkt_t;

enum {
    FRAG_NONE = 0,
    FRAG_6LOWPAN = 1,
    FRAG_IPV6 = 2,

    ND_DONE = 0,
    ND_TODO = 1,
    ND_SENT = 2,
 };

struct lowpan_mesh_hdr {
    uint8_t dispatch; // dispatch and flags
    // address length depends on flags in dispatch
};

struct lowpan_broadcast_hdr {
    uint8_t dispatch;
    uint8_t seq_no; // sequence number
};

struct lowpan_frag_hdr {
    union {
	uint8_t dispatch;
	uint16_t dgram_size;
	uint8_t dgram_size8[2];
    };
    uint16_t dgram_tag;
};

/*
 * Definition for internet protocol version 6.
 * RFC 2460
 */

struct ip6_hdr {
    union {
	uint8_t  vtc;    /* 4 bits version, 8 bits class label*/
	uint32_t flow;   /* 20 bits flow label at the end */
    };
    uint16_t  plen;      /* payload length */
    uint8_t   nxt_hdr;       /* next header */
    uint8_t   hlim;      /* hop limit */
    ip6_addr_t src_addr; /* source address */
    ip6_addr_t dst_addr; /* destination address */
} /* __attribute__((packed))*/;

#define IPV6_VERSION            0x60
#define IPV6_VERSION_MASK       0xf0

/*
 * Extension Headers
 */

struct  ip6_ext {
        uint8_t ip6e_nxt;
        uint8_t ip6e_len;
};


struct  icmp6_hdr {
        uint8_t        type;     /* type field */
        uint8_t        code;     /* code field */
        uint16_t       cksum;    /* checksum field */
};

enum {
    ICMP_TYPE_ECHO_DEST_UNREACH     = 1,
    ICMP_TYPE_ECHO_PKT_TOO_BIG      = 129,
    ICMP_TYPE_ECHO_TIME_EXCEEDED    = 129,
    ICMP_TYPE_ECHO_PARAM_PROBLEM    = 129,
    ICMP_TYPE_ECHO_REQUEST          = 128,
    ICMP_TYPE_ECHO_REPLY            = 129,
    ICMP_TYPE_NEIGHBOR_SOL          = 135,
    ICMP_TYPE_NEIGHBOR_ADV          = 136,
    ICMP_NEIGHBOR_HOPLIMIT          = 255
};

/*
 * Udp protocol header.
 * Per RFC 768, September, 1981.
 */
struct udp_hdr {
    uint16_t srcport;               /* source port */
    uint16_t dstport;               /* destination port */
    uint16_t len;                   /* udp length */
    uint16_t chksum;                /* udp checksum */
};

enum {
    //NEXT_HEADER_ICMP = 1,
    NEXT_HEADER_TCP = 6,
    NEXT_HEADER_UDP = 17,
    NEXT_HEADER_ICMP6 = 58
};


struct udp_conn {
    ip6_addr_t ripaddr;   /* IP address of the remote peer. */
    uint16_t  lport;      /* local port number (network byte order) */
    uint16_t  rport;      /* remote port number (network byte order) */
};


/* // from uip-1.0/uip/uip-neighbor.c */
/* #define NEIGHBOR_MAX_TIME 128 */

/* #ifndef NEIGHBOR_ENTRIES */
/* #define NEIGHBOR_ENTRIES 8 */
/* #endif */

/* struct neighbor_entry { */
/*   ip6_addr_t ip_addr; */
/*   struct hw_addr hw_addr; */
/*   uint8_t time; */
/* }; */
/* struct neighbor_entry neighbor_entries[NEIGHBOR_ENTRIES]; */

#endif /* __IP_INTERNAL_H__ */
