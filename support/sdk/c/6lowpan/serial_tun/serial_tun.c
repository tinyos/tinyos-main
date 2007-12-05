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

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <netdb.h>

#include <stdarg.h>

#include "tun_dev.h"
#include "serialsource.h"
#include "serialpacket.h"
#include "6lowpan.h"

#define min(a,b) ( (a>b) ? b : a )
#define max(a,b) ( (a>b) ? a : b )

static char *msgs[] = {
  "unknown_packet_type",
  "ack_timeout"	,
  "sync"	,
  "too_long"	,
  "too_short"	,
  "bad_sync"	,
  "bad_crc"	,
  "closed"	,
  "no_memory"	,
  "unix_error"
};

/* global variables */
lowpan_pkt_t *fragments = NULL; /* fragment reassembly of received frames */
//lowpan_pkt_t *send_queue = NULL;
int g_send_pending = 0;

hw_addr_t hw_addr;

serial_source ser_src;
int tun_fd = 0; /* tunnel device */
//int ser_fd = 0; /* serial device */

uint16_t g_dgram_tag = 0; /* datagram_tag for sending fragmented packets */

/* ------------------------------------------------------------------------- */
/* function pre-declarations */
int serial_output_am_payload(uint8_t *buf, int len,
			     const hw_addr_t *hw_src_addr,
			     const hw_addr_t *hw_dst_addr);

int serial_input_layer3(uint8_t *buf, int len,
			const hw_addr_t *hw_src_addr,
			const hw_addr_t *hw_dst_addr);

int serial_input_ipv6_uncompressed(uint8_t *buf, int len,
				   const hw_addr_t *hw_src_addr,
				   const hw_addr_t *hw_dst_addr);

int serial_input_ipv6_compressed(uint8_t *buf, int len,
				 const hw_addr_t *hw_src_addr,
				 const hw_addr_t *hw_dst_addr);

/* ------------------------------------------------------------------------- */
/* utility functions */
int get_ser_fd()
{
    return serial_source_fd(ser_src);
}

void increment_g_dgram_tag()
{
    uint16_t tmp = ntohs(g_dgram_tag);
    if (tmp == 0xFFFF) {
	tmp = 0;
    } else {
	tmp++;
    }
    g_dgram_tag = htons(tmp);
}

void stderr_msg(serial_source_msg problem)
{
  fprintf(stderr, "Note: %s\n", msgs[problem]);
}

int
debug(const char *fmt, ...)
{
    int result;
    va_list ap;
    va_start(ap, fmt);
    result = vfprintf(stderr, fmt, ap);
    va_end(ap);
    return result;
}

/* from contiki-2.x/tools/tunslip.c */
int
ssystem(const char *fmt, ...)
{
  char cmd[128];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(cmd, sizeof(cmd), fmt, ap);
  va_end(ap);
  printf("%s\n", cmd);
  fflush(stdout);
  return system(cmd);
}

/* print char* in hex format */
void dump_serial_packet(const unsigned char *packet, const int len) {
    int i;
    printf("len: %d\n", len);
    if (!packet)
	return;
    for (i = 0; i < len; i++) {
	printf("%02x ", packet[i]);
	//printf("%02x(%c) ", packet[i], packet[i]);
	//printf("%c", packet[i]);
    }
    putchar('\n');
/*     printf("---\n"); */
/*     for (i = 0; i < len; i++) { */
/* 	printf("%c", packet[i]); */
/*     } */
/*     putchar('\n'); */
/*     printf("---\n"); */
}

/* ------------------------------------------------------------------------- */
/* ip6_addr_t and hw_addr_t utility functions */
int ipv6_addr_is_zero(const ip6_addr_t *addr)
{
    int i;
    for (i=0;i<16;i++) {
	if (addr->addr[i]) {
	    return 0;
	}
    }
    return 1;
}

int ipv6_addr_is_linklocal_unicast(const ip6_addr_t *addr)
{
    if (   addr->addr[0] == 0xFE
	   && addr->addr[1] == 0x80
	   && addr->addr[2] == 0
	   && addr->addr[3] == 0
	   && addr->addr[4] == 0
	   && addr->addr[5] == 0
	   && addr->addr[6] == 0
	   && addr->addr[7] == 0
	   )
	return 1;
    else
	return 0;
}

int cmp_ipv6_addr(const ip6_addr_t *addr1, const ip6_addr_t *addr2)
{
    return memcmp(addr1, addr2, sizeof(ip6_addr_t));
}

int cmp_hw_addr(const hw_addr_t *addr1, const hw_addr_t *addr2)
{
    // for short addresses compare only the first two bytes
    if (addr1->type == HW_ADDR_SHORT && addr2->type == HW_ADDR_SHORT) {
	return memcmp(addr1->addr_short, addr2->addr_short,
		      sizeof(addr1->addr_short));
    } else {
	return memcmp(addr1, addr2, sizeof(hw_addr_t));
    }
}

int hw_addr_is_broadcat(const hw_addr_t *hw_addr)
{
    if (hw_addr->type == HW_ADDR_SHORT
	&& hw_addr->addr_short[0] == 0xFF  && hw_addr->addr_short[1] == 0xFF)
	return 1;
    // TODO: long address
    else return 0;
}

/* ------------------------------------------------------------------------- */
/* more utility functions */
void clear_pkt(lowpan_pkt_t *pkt)
{
    memset(pkt, 0, sizeof(*pkt));
    pkt->buf_begin = pkt->buf + LOWPAN_OVERHEAD;
}

void free_frag_list(frag_info_t *p)
{
    frag_info_t *q;
    while (p) {
	q = p->next;
	free(p);
	p = q;
    }
}

void free_lowpan_pkt(lowpan_pkt_t *pkt)
{
    lowpan_pkt_t *p;
    lowpan_pkt_t **q;

    if (!fragments) return;
    for(q=&fragments; *q; q=&(*q)->next) {
	if (*q == pkt) {
	    p = *q;
	    *q = p->next;
	    free_frag_list(p->frag_list);
	    free(p);
	    return;
	}
    }
}

lowpan_pkt_t * find_fragment(hw_addr_t *hw_src_addr, hw_addr_t *hw_dst_addr,
			     uint16_t dgram_size, uint16_t dgram_tag)
{
    lowpan_pkt_t *p;
    for(p=fragments; p; p=p->next) {
	if ((p->dgram_tag == dgram_tag)
	    && (p->dgram_size == dgram_size)
	    && cmp_hw_addr(&p->hw_src_addr, hw_src_addr) == 0
	    && cmp_hw_addr(&p->hw_dst_addr, hw_dst_addr) == 0
	    ) {
	    return p;
	}
    }
    return NULL;
}
/* ------------------------------------------------------------------------- */
/* HC1 and HC2 compression and decompresstion functions */

/* the caller has to free() new_buf */
int lowpan_decompress(uint8_t *buf, int len,
		       const hw_addr_t *hw_src_addr,
		       const hw_addr_t *hw_dst_addr,
		       uint8_t **new_buf, int *new_len)
{
    uint8_t hc1_enc;
    uint8_t hc2_enc;
    struct ip6_hdr *ip_hdr = NULL;
    struct udp_hdr *udp_hdr = NULL;
    
    *new_buf = malloc(len + sizeof(*ip_hdr) + sizeof(*udp_hdr));
    if (!*new_buf) {
	fprintf(stderr, "%s: out of memory\n", __func__);
	*new_len = 0;
	return 1;
    }
    hc1_enc = *buf;
    buf += sizeof(hc1_enc);
    len -= sizeof(hc1_enc);

    /* HC2 encoding follows HC1 encoding */
    if ((hc1_enc & HC1_HC2_MASK) == HC1_HC2_PRESENT) {
	hc2_enc = *buf;
	buf += sizeof(hc2_enc);
	len -= sizeof(hc2_enc);
    }

    /* IP header fields */
    ip_hdr = (struct ip6_hdr *) *new_buf;
    memset(ip_hdr, 0, sizeof(struct ip6_hdr));

    ip_hdr->vtc |= IPV6_VERSION;

    ip_hdr->hlim = *buf;
    buf += sizeof(ip_hdr->hlim);
    len -= sizeof(ip_hdr->hlim);

    /* source IP address */
    if ((hc1_enc & HC1_SRC_PREFIX_MASK) == HC1_SRC_PREFIX_INLINE) {
	memcpy(&ip_hdr->src_addr, buf, sizeof(ip_hdr->src_addr)/2);
	buf += sizeof(ip_hdr->src_addr)/2;
	len -= sizeof(ip_hdr->src_addr)/2;
    } else {
	ip_hdr->src_addr.addr[0] = 0xFE;
	ip_hdr->src_addr.addr[1] = 0x80;
    }
     
    if ((hc1_enc & HC1_SRC_IFACEID_MASK) == HC1_SRC_IFACEID_INLINE) {
	memcpy(((void*)&ip_hdr->src_addr) + sizeof(ip_hdr->src_addr)/2,
	       buf, sizeof(ip_hdr->src_addr)/2);
	buf += sizeof(ip_hdr->src_addr)/2;
	len -= sizeof(ip_hdr->src_addr)/2;
    }

    /* destination IP address */
    if ((hc1_enc & HC1_DST_PREFIX_MASK) == HC1_DST_PREFIX_INLINE) {
	memcpy(&ip_hdr->dst_addr, buf, sizeof(ip_hdr->dst_addr)/2);
	buf += sizeof(ip_hdr->dst_addr)/2;
	len -= sizeof(ip_hdr->dst_addr)/2;
    } else {
	ip_hdr->dst_addr.addr[0] = 0xFE;
	ip_hdr->dst_addr.addr[1] = 0x80;
    }
     
    if ((hc1_enc & HC1_DST_IFACEID_MASK) == HC1_DST_IFACEID_INLINE) {
	memcpy(((void*)&ip_hdr->dst_addr) + sizeof(ip_hdr->dst_addr)/2,
	       buf, sizeof(ip_hdr->dst_addr)/2);
	buf += sizeof(ip_hdr->dst_addr)/2;
	len -= sizeof(ip_hdr->dst_addr)/2;
    }

    /* Traffic Class and Flow Label */
    if ((hc1_enc & HC1_TCFL_MASK) == HC1_TCFL_INLINE) {
	//TODO
    }

    /* Next Header */
    switch (hc1_enc & HC1_NEXTHDR_MASK) {
    case HC1_NEXTHDR_INLINE:
	ip_hdr->nxt_hdr = *buf;
	buf += sizeof(ip_hdr->nxt_hdr);
	len -= sizeof(ip_hdr->nxt_hdr);
	break;
    case HC1_NEXTHDR_UDP:
	ip_hdr->nxt_hdr = NEXT_HEADER_UDP;
	break;
    case HC1_NEXTHDR_ICMP:
	ip_hdr->nxt_hdr = NEXT_HEADER_ICMP6;
	break;
    case HC1_NEXTHDR_TCP:
	ip_hdr->nxt_hdr = NEXT_HEADER_TCP;
	break;
    default:
	fprintf(stderr, "unknown next header HC1 encoding\n");
	break;
    }
    
    /* HC_UDP compression */
    if ((hc1_enc & HC1_HC2_MASK) == HC1_HC2_PRESENT
	&& (hc1_enc & HC1_NEXTHDR_MASK) == HC1_NEXTHDR_UDP) {
	
	udp_hdr = (struct udp_hdr *) ((*new_buf) + sizeof(struct ip6_hdr));
	//udp_hdr = (struct udp_hdr *) (ip_hdr + 1);
	memset(udp_hdr, 0, sizeof(struct udp_hdr));

	/* UDP Source Port */
	if ((hc2_enc & HC2_UDP_SRC_PORT_MASK) == HC2_UDP_SRC_PORT_INLINE) {
	    memcpy(&udp_hdr->src_port, buf, sizeof(udp_hdr->src_port));
	    buf += sizeof(udp_hdr->src_port);
	    len -= sizeof(udp_hdr->src_port);
	} else {
	    //TODO
	}

	/* UDP Destination Port */
	if ((hc2_enc & HC2_UDP_DST_PORT_MASK) == HC2_UDP_DST_PORT_INLINE) {
	    memcpy(&udp_hdr->dst_port, buf, sizeof(udp_hdr->dst_port));
	    buf += sizeof(udp_hdr->dst_port);
	    len -= sizeof(udp_hdr->dst_port);
	} else {
	    //TODO
	}

	/* UDP Length */
	if ((hc2_enc & HC2_UDP_LEN_MASK) == HC2_UDP_LEN_INLINE) {
	    memcpy(&udp_hdr->len, buf, sizeof(udp_hdr->len));
	    buf += sizeof(udp_hdr->len);
	    len -= sizeof(udp_hdr->len);
	} else {
	    udp_hdr->len = len - sizeof(udp_hdr->chksum)
		+ sizeof(struct udp_hdr);
	}
	
	/* Checksum */
	memcpy(&udp_hdr->chksum, buf, sizeof(udp_hdr->chksum));
	buf += sizeof(udp_hdr->chksum);
	len -= sizeof(udp_hdr->chksum);
	
	/* IPv6 Payload Length */
	ip_hdr->plen = htons(len + sizeof(struct udp_hdr));
	
	memcpy((*new_buf) + sizeof(struct ip6_hdr) + sizeof(struct udp_hdr),
	       buf, len);
	*new_len = len + sizeof(struct ip6_hdr) + sizeof(struct udp_hdr);
    } else {
    /* IPv6 Payload Length */
    ip_hdr->plen = htons(len);

    memcpy((*new_buf) + sizeof(struct ip6_hdr), buf, len);
    *new_len = len + sizeof(struct ip6_hdr);
    }
    
    return 0;
}

/* assuming there is space available in from of buf_begin */
int lowpan_compress(uint8_t **buf_begin, int *len,
		     const hw_addr_t *hw_src_addr,
		     const hw_addr_t *hw_dst_addr)
{
    uint8_t *hc1_enc;
    uint8_t *hc2_enc;
    struct ip6_hdr *ip_hdr = NULL;
    struct udp_hdr *udp_hdr = NULL;
    
    uint8_t new_buf[sizeof(struct ip6_hdr) + sizeof(struct udp_hdr) + 5];
    uint8_t *new_buf_p = new_buf;
    int new_len = 0;

    debug("%s\n", __func__);

    ip_hdr = (struct ip6_hdr *) *buf_begin;
    udp_hdr = (struct udp_hdr *) ((*buf_begin) + sizeof(struct ip6_hdr));

    /* check if this is an IPv6 packet */
    if ((ip_hdr->vtc & IPV6_VERSION_MASK) != IPV6_VERSION) {
	debug("IP version check failed - not an IPv6 packet\n");
	return 0;
    }
    
    /* set 6lowpan dispatch value */
    *new_buf_p = DISPATCH_COMPRESSED_IPV6;
    new_buf_p += sizeof(uint8_t);
    new_len += sizeof(uint8_t);

    /* HC1 encoding field */
    hc1_enc = new_buf_p;
    new_buf_p += sizeof(uint8_t);
    new_len += sizeof(uint8_t);
    *hc1_enc = 0;

    /* does HC2 follow after HC1? */
    if (ip_hdr->nxt_hdr == NEXT_HEADER_UDP) {
	*hc1_enc |= HC1_HC2_PRESENT;

	/* HC2 encoding field */
	hc2_enc = new_buf_p;
	new_buf_p += sizeof(uint8_t);
	new_len += sizeof(uint8_t);
	*hc2_enc = 0;
    } else {    
	*hc1_enc |= HC1_HC2_NONE;
    }

    /* Hop Limit */
    *new_buf_p = ip_hdr->hlim;
    new_buf_p += sizeof(uint8_t);
    new_len += sizeof(uint8_t);

    /* source address prefix */
    //TODO: fails checksum on the mote !!!
    if (ipv6_addr_is_linklocal_unicast(&ip_hdr->src_addr)) {
	*hc1_enc |= HC1_SRC_PREFIX_LINKLOCAL;
    } else {
	*hc1_enc |= HC1_SRC_PREFIX_INLINE;

	memcpy(new_buf_p, &(ip_hdr->src_addr), 8);
	new_buf_p += 8;
	new_len += 8;
    }

    /* source address interface identifier */
    *hc1_enc |= HC1_SRC_IFACEID_INLINE;
    
    memcpy(new_buf_p, ((void*)&(ip_hdr->src_addr)) + 8, 8);
    new_buf_p += 8;
    new_len += 8;

    /* destination address prefix */
    if (ipv6_addr_is_linklocal_unicast(&ip_hdr->dst_addr)) {
	*hc1_enc |= HC1_DST_PREFIX_LINKLOCAL;
    } else {
	*hc1_enc |= HC1_DST_PREFIX_INLINE;

	memcpy(new_buf_p, &(ip_hdr->dst_addr), 8);
	new_buf_p += 8;
	new_len += 8;
    }

    /* destination address interface identifier */
    *hc1_enc |= HC1_DST_IFACEID_INLINE;
    
    memcpy(new_buf_p, ((void*)&(ip_hdr->dst_addr)) + 8, 8);
    new_buf_p += 8;
    new_len += 8;

    /* we're always sending packets with TC anf FL zero */
    *hc1_enc |= HC1_TCFL_ZERO;
    
    /* next header */
    switch (ip_hdr->nxt_hdr) {
    case NEXT_HEADER_UDP:
	*hc1_enc |= HC1_NEXTHDR_UDP;
	break;
    case NEXT_HEADER_ICMP6:
	*hc1_enc |= HC1_NEXTHDR_ICMP;
	break;
    case NEXT_HEADER_TCP:
	*hc1_enc |= HC1_NEXTHDR_TCP;
	break;
    default:
	*hc1_enc |= HC1_NEXTHDR_INLINE;

	*new_buf_p = ip_hdr->nxt_hdr;
	new_buf_p += sizeof(ip_hdr->nxt_hdr);
	new_len += sizeof(ip_hdr->nxt_hdr);
	break;
    }
    
    /* HC_UDP encoding */
    if ((*hc1_enc & HC1_HC2_MASK) == HC1_HC2_PRESENT
	&& (*hc1_enc & HC1_NEXTHDR_MASK) == HC1_NEXTHDR_UDP) {
	
	/* Source Port */
	*hc2_enc |= HC2_UDP_SRC_PORT_INLINE;
	memcpy(new_buf_p, &udp_hdr->src_port, sizeof(udp_hdr->src_port));
	new_buf_p += sizeof(udp_hdr->src_port);
	new_len += sizeof(udp_hdr->src_port);
	
	/* Destination Port */
	*hc2_enc |= HC2_UDP_DST_PORT_INLINE;
	memcpy(new_buf_p, &udp_hdr->dst_port, sizeof(udp_hdr->dst_port));
	new_buf_p += sizeof(udp_hdr->dst_port);
	new_len += sizeof(udp_hdr->dst_port);

	/* Length */
	//*hc2_enc |= HC2_UDP_LEN_COMPR;
	*hc2_enc |= HC2_UDP_LEN_INLINE;
	memcpy(new_buf_p, &udp_hdr->len, sizeof(udp_hdr->len));
	new_buf_p += sizeof(udp_hdr->len);
	new_len += sizeof(udp_hdr->len);

	/* Checksum */
	memcpy(new_buf_p, &udp_hdr->chksum, sizeof(udp_hdr->chksum));
	new_buf_p += sizeof(udp_hdr->chksum);
	new_len += sizeof(udp_hdr->chksum);

	/* replace the IP and UDP headers with the compressed ones */
	*len += new_len;
	*len -= sizeof(struct ip6_hdr);
	*len -= sizeof(struct udp_hdr);
	*buf_begin += sizeof(struct ip6_hdr);
	*buf_begin += sizeof(struct udp_hdr);
	*buf_begin -= new_len;
	memcpy(*buf_begin, new_buf, new_len);
    } else {
	/* replace the IP header with the compressed one */
	*len += new_len;
	*len -= sizeof(struct ip6_hdr);
	*buf_begin += sizeof(struct ip6_hdr);
	*buf_begin -= new_len;
	memcpy(*buf_begin, new_buf, new_len);
    }

    return 0;
}

/* ------------------------------------------------------------------------- */
/* handling of data arriving on the tun interface */

/*
 * encapsulate buf as an Active Message payload
 * fragments packets if needed
 */
int serial_output_am_payload(uint8_t *buf, int len,
			     const hw_addr_t *hw_src_addr,
			     const hw_addr_t *hw_dst_addr)
{
    am_packet_t AMpacket;
    int result;
    
    //debug("%s: dumping buf (len: %d)...\n", __func__, len);
    //dump_serial_packet(buf, len);

    if (len > LINK_DATA_MTU) {
	fprintf(stderr, "%s: requested to send more than LINK_DATA_MTU"\
		"(%d bytes)\n", __func__, len);
	// TODO: maybe we should send the fisr LINK_DATA_MTU bytes
	//       and only print a warning
	return -1;
    }
    memset(&AMpacket, 0, sizeof(AMpacket));
    AMpacket.pkt_type = 0;
    // TODO: make the dst addr handling more general
    //AMpacket.dst = htons(0x14);
    AMpacket.dst = htons(0xFFFF);
    //AMpacket.src = htons(0x12);
    // TODO: make the src addr handling more general
    memcpy(&AMpacket.src, hw_addr.addr_short, 2);
    AMpacket.group = 0;
    AMpacket.type = 0x41;
    AMpacket.length = min(len,LINK_DATA_MTU);
    //AMpacket.data = buf;
    memcpy(AMpacket.data, buf, AMpacket.length);
    
    len = AMpacket.length + 8; // data + header

    debug("sending to serial port...\n");
    dump_serial_packet((unsigned char *)&AMpacket, len);

    result = write_serial_packet(ser_src, &AMpacket, len);
    /*
     * Returns: 0 if packet successfully written, 1 if successfully
     * written but not acknowledged, -1 otherwise
     */
    debug("write_serial_packet returned %d\n", result);

    if (result < 0) {
	perror ("sendto");
	return -1;
    }
    return len;
}

/*
 * read data from the tun device and send it to the serial port
 * does also fragmentation
 */
int tun_input()
{
    uint8_t buf[LOWPAN_MTU + LOWPAN_OVERHEAD];
    uint8_t *buf_begin = buf + LOWPAN_OVERHEAD;
    int len;
    int result;
    
    struct lowpan_frag_hdr *frag_hdr;
    uint8_t dgram_offset = 0;
    uint16_t dgram_size;
    hw_addr_t hw_dst_addr;
    uint8_t frag_len; /* length of the fragment just being sent */

    uint8_t *frame_begin; /* begin of the frame payload */
    uint8_t frame_len; /* length of the frame payload */
    
    len = tun_read (tun_fd, (char*) buf_begin, LOWPAN_MTU);
    if (len <= 0) {
	perror ("read");
	return 0;
    }
    printf("data on tun interface\n");

    /* set 802.15.4 destination address */
    hw_dst_addr.type = HW_ADDR_SHORT;
    hw_dst_addr.addr_short[0] =0xFF;
    hw_dst_addr.addr_short[1] =0xFF;
    
    /* HC compression */
    lowpan_compress(&buf_begin, &len,
		    &hw_addr, &hw_dst_addr);

    /* prepend dispatch */
/*     buf_begin--; */
/*     *buf_begin = DISPATCH_UNCOMPRESSED_IPV6;  */
/*     len++; */

    /* determine if fragmentation is needed */
    if (len > LINK_DATA_MTU) {
	/* fragmentation needed */
	increment_g_dgram_tag();
	dgram_size = htons(len);
	
	/* first fragment */
	debug("first fragment... (len: %d, offset: %d)\n",
	      len, dgram_offset);
	/* fragment heder */
	frame_begin = buf_begin - sizeof(struct lowpan_frag_hdr);
	frag_hdr = (struct lowpan_frag_hdr *) frame_begin;
	frag_hdr->dgram_size = dgram_size;
	frag_hdr->dispatch |= DISPATCH_FIRST_FRAG;
	frag_hdr->dgram_tag = g_dgram_tag;
	/* align fragment length at an 8-byte multiple */
	frag_len = LINK_DATA_MTU - sizeof(struct lowpan_frag_hdr);
	frag_len -= frag_len%8;
	frame_len = frag_len + sizeof(struct lowpan_frag_hdr);
	result = serial_output_am_payload(frame_begin, frame_len,
					  &hw_addr, &hw_dst_addr);
	if (result < 0) {
	    perror("serial_output_am_payload() failed\n");
	    return -1;
	}
	buf_begin += frag_len;
	len -= frag_len;
	dgram_offset += frag_len/8; /* in 8-byte multiples */
    
	/* subseq fragment */
	while (len > 0) {
	    usleep(10000); /* workaround to prevent loosing fragments */
	    debug("subsequent fragment... (len: %d, offset: %d)\n",
		  len, dgram_offset);
	    /* dgram_offset */
	    frame_begin = buf_begin - sizeof(uint8_t);
	    *(frame_begin) = dgram_offset;
	    /* fragment heder */
	    frame_begin -= sizeof(struct lowpan_frag_hdr);
	    frag_hdr = (struct lowpan_frag_hdr *) frame_begin;
	    frag_hdr->dgram_size = dgram_size;
	    frag_hdr->dispatch |= DISPATCH_SUBSEQ_FRAG;
	    frag_hdr->dgram_tag = g_dgram_tag;
	    if (len <= LINK_DATA_MTU  - sizeof(struct lowpan_frag_hdr)
		- sizeof(uint8_t)) {
		/*
		 * last fragment does not have to be aligned
		 * at an 8-byte multiple
		 */
		frag_len = len;
	    } else {
		/* align fragment length at an 8-byte multiple */
		frag_len = LINK_DATA_MTU - sizeof(struct lowpan_frag_hdr)
		           - sizeof(uint8_t);
		frag_len -= frag_len%8;
	    }
	    frame_len = frag_len + sizeof(struct lowpan_frag_hdr)
		                 + sizeof(uint8_t);
	    result = serial_output_am_payload(frame_begin, frame_len,
					      &hw_addr, &hw_dst_addr);
	    if (result < 0) {
		perror("serial_output_am_payload() failed\n");
		//return -1;
	    }
	    buf_begin += frag_len;
	    len -= frag_len;
	    dgram_offset += frag_len/8; /* in 8-byte multiples */
	}
	return 1;

    } else {
	/* no need for fragmentation */
	serial_output_am_payload(buf_begin, len,
				 &hw_addr, &hw_dst_addr);
	return 1;
    }

}

/* ------------------------------------------------------------------------- */
/* handling of data arriving on the serial port */

/* 
 * read data on serial port and send it to the tun interface
 * does fragment reassembly
 */
int serial_input()
{
    int result = 0;

    void *ser_data; /* data read from serial port */
    int ser_len;    /* length of data read from serial port */
    uint8_t *buf;
    int len;

    am_packet_t *AMpacket;
    struct hw_addr hw_src_addr;
    struct hw_addr hw_dst_addr;
    uint8_t *dispatch;
    struct lowpan_broadcast_hdr *bc_hdr;
    struct lowpan_frag_hdr *frag_hdr;

    uint16_t dgram_tag;
    uint16_t dgram_size;
    uint8_t dgram_offset;
    struct timeval tv;
    frag_info_t *p;
    frag_info_t **q;
    int last_frag;
    lowpan_pkt_t *pkt;

    printf("serial_input()\n");
    /* read data from serial port */
    ser_data = read_serial_packet(ser_src, &ser_len);

    /* process the packet we have received */
    if (ser_len && ser_data) {
	printf("dumping data on serial port...\n");
	dump_serial_packet(ser_data, ser_len);
	AMpacket = ser_data;

	/* copy 802.15.4 addresses */
	// TODO: check if I got the byte ordering right
	hw_src_addr.type = HW_ADDR_SHORT;
	memcpy(hw_src_addr.addr_short, &AMpacket->src,
	       sizeof(hw_src_addr.addr_short));
	hw_dst_addr.type = HW_ADDR_SHORT;
	memcpy(hw_dst_addr.addr_short, &AMpacket->dst,
	       sizeof(hw_dst_addr.addr_short));

	/* --- 6lowpan optional headers --- */
	buf = AMpacket->data;
	len = AMpacket->length;
	if (len != ser_len - 8) {
	    fprintf(stderr,
		    "warning: mismatch between AMpacket->length(%d)"\
		    " and ser_len - 8(%d)", AMpacket->length, ser_len - 8);
	}
	// TODO: check if length has a sensible value
	dispatch = AMpacket->data;
	/* Mesh Addressing header */
	if ( (*dispatch & DISPATCH_MESH_MASK) == DISPATCH_MESH) {
	    /* move over the dispatch field */
	    buf += sizeof(*dispatch);
	    len -= sizeof(*dispatch);

	    /* Hops Left */
	    if ((*dispatch & 0x0F) == 0) {
	      goto discard_packet;
	    }
	    
	    /* Final Destination Address */
	    if (*dispatch & DISPATCH_MESH_F_FLAG) {
		hw_dst_addr.type = HW_ADDR_LONG;
		memcpy(&hw_dst_addr.addr_long, buf,
		       sizeof(hw_dst_addr.addr_long));
		buf += sizeof(hw_dst_addr.addr_long);
		len -= sizeof(hw_dst_addr.addr_long);
	    } else {
		hw_dst_addr.type = HW_ADDR_SHORT;
		memcpy(&hw_dst_addr.addr_short, buf,
		       sizeof(hw_dst_addr.addr_short));
		buf += sizeof(hw_dst_addr.addr_short);
		len -= sizeof(hw_dst_addr.addr_short);
	    }
	    
	    /* check if we're the recipient */
	    if (cmp_hw_addr(&hw_dst_addr, &hw_addr) != 0
		&& !hw_addr_is_broadcat(&hw_dst_addr)) {
		// TODO: if mesh forwarding enabled, then forward
		goto discard_packet;
	    }
	    
	    /* Originator Address */
	    if (*dispatch & DISPATCH_MESH_O_FLAG) {
		hw_src_addr.type = HW_ADDR_LONG;
		memcpy(&hw_src_addr.addr_long, buf,
		       sizeof(hw_src_addr.addr_long));
		buf += sizeof(hw_src_addr.addr_long);
		len -= sizeof(hw_src_addr.addr_long);
	    } else {
		hw_src_addr.type = HW_ADDR_SHORT;
		memcpy(&hw_src_addr.addr_short, buf,
		       sizeof(hw_src_addr.addr_short));
		buf += sizeof(hw_src_addr.addr_short);
		len -= sizeof(hw_src_addr.addr_short);
	    }
	    
	    dispatch = buf;
	}
	/* Broadcast header */
	if (*dispatch == DISPATCH_BC0) {
	    bc_hdr = (struct lowpan_broadcast_hdr *) buf;
	    // do something usefull with bc_hdr->seq_no...
	    
	    buf += (sizeof(struct lowpan_broadcast_hdr));
	    len -= (sizeof(struct lowpan_broadcast_hdr));
	    dispatch = buf;
	}

	/* fragment header */
	if ((*dispatch & DISPATCH_FRAG_MASK)
	    == DISPATCH_FIRST_FRAG
	    || (*dispatch & DISPATCH_FRAG_MASK)
	    == DISPATCH_SUBSEQ_FRAG
	    ) {
	    frag_hdr = (struct lowpan_frag_hdr *) buf;
	    buf += sizeof(struct lowpan_frag_hdr);
	    len -= sizeof(struct lowpan_frag_hdr);

	    /* collect information about the fragment */
	    dgram_tag = frag_hdr->dgram_tag;
	    dgram_size = frag_hdr->dgram_size & htons(0x07FF);
	    //dgram_size = frag_hdr->dgram_size8[1];
	    //dgram_size += ((uint16_t) (frag_hdr->dgram_size8[0] & 0x07)) << 8;
	    if ((*dispatch & DISPATCH_FRAG_MASK) == DISPATCH_SUBSEQ_FRAG) {
		dgram_offset = *buf;
		buf += 1;
		len -= 1;
	    } else {
		dgram_offset = 0;
	    }
	    
	    debug("fragment reassembly: tag: 0x%04X, size: %d, offset: %d"\
		  "(*8=%d)\n",
		  ntohs(dgram_tag), ntohs(dgram_size),
		  dgram_offset, dgram_offset*8);

	    pkt = find_fragment(&hw_src_addr, &hw_dst_addr,
				dgram_size, dgram_tag);
	    if (pkt) {
		debug("found an existing reassembly buffer\n");
		/* fragment reassembly buffer found */
		/* check for overlap */
		for (p = pkt->frag_list; p; p=p->next) {
		    if (dgram_offset == p->offset && len == p->len) {
			/* duplicate - discard it */
			result = 0;
			goto discard_packet;
		    } else if ((dgram_offset == p->offset && len < p->len) ||
			       (dgram_offset > p->offset
				&& dgram_offset < p->offset + p->len/8)
			       ) {
			goto frag_overlap;
		    }
		}
		/* no overlap found */
		goto frag_reassemble;
	    } else {
		debug("starting a new reassembly buffer\n");
		/* fragment reassembly buffer not found - set up a new one */
		pkt = malloc(sizeof(lowpan_pkt_t));
		if (!pkt) {
		    // no free slot for reassembling fragments
		    fprintf(stderr, "out of memory - dropping a fragment\n");
		    result = -1;
		    goto discard_packet;
		}
		pkt->next = fragments;
		fragments = pkt;
		clear_pkt(pkt);
		memcpy(&pkt->hw_src_addr, &hw_src_addr, sizeof(hw_src_addr));
		memcpy(&pkt->hw_dst_addr, &hw_dst_addr, sizeof(hw_dst_addr));
		pkt->dgram_tag = dgram_tag;
		pkt->dgram_size = dgram_size;
		gettimeofday(&tv, NULL);
		pkt->frag_timeout = tv.tv_sec + FRAG_TIMEOUT;
		goto frag_reassemble;
	    }
	    
	frag_overlap:
	    /* overlap - discard previous frags
	     * and restart freagment reassembly
	     */
	    free_frag_list(pkt->frag_list);
	    pkt->frag_list = NULL;
	    /* not sure if we want to clear the whole buf */
	    //memset(&pkt->buf, 0, sizeof(pkt->buf));
	    gettimeofday(&tv, NULL);
	    pkt->frag_timeout = tv.tv_sec + FRAG_TIMEOUT;
	    goto frag_reassemble;
	    
	frag_reassemble:
	    /* copy buf data */
	    debug("dgram_offset: %d\n", dgram_offset);
	    memcpy(pkt->buf_begin + dgram_offset*8, buf, len);
	    //TODO: make sure a large len does not cause a buffer overflow

	    /* update frag_info */
	    p = malloc(sizeof(frag_info_t));
	    if (!p) {
		fprintf(stderr, "out of memory - fragment "\
			"reassembly failing\n");
	    } else {
		p->offset = dgram_offset;
		p->len = len;

		/* insert frag_info into the orderer list */
		if (pkt->frag_list) {
		    for(q = &(pkt->frag_list); (*q)->next; q=&((*q)->next)) {
			if (p->offset > (*q)->offset) {
			    break;
			}
		    }
		    if ((*q)) {
			debug("inserting frag_info before offset %d\n",
			      (*q)->offset);
		    } else {
			debug("inserting frag_info at the beginning/end\n");
		    }

		    p->next = *q;
		    *q = p;
		} else {
		    debug("inserting frag_info to the beginning "
			  "of the list\n");
		    p->next = pkt->frag_list;
		    pkt->frag_list = p;
		}
	    }

	    /* check if this is not the last fragment */
	    if (!dgram_offset) {
		/* the first fragment cannot be the last one */
		last_frag = 0;
	    } else {
		debug("checking last_frag...\n");
		last_frag=1;
		dgram_offset = ntohs(dgram_size)/8;
		for(p=pkt->frag_list; p && dgram_offset; p=p->next) {
		    debug("dgram_offset: %d, p->offset: %d, p->len: %d\n",
			  dgram_offset, p->offset, p->len);
		    if (p->offset + p->len/8 != dgram_offset) {
			debug("offset mismatch - not the last fragment\n");
			last_frag = 0;
			break;
		    }
		    dgram_offset = p->offset;
		}
	    }

	    if (last_frag) {
		debug("last fragment, reassembly done\n");
		pkt->len = ntohs(dgram_size);
		
		debug("dumping reassembled datagram...\n");
		dump_serial_packet(pkt->buf_begin, pkt->len);
		
		/* pass up the complete packet */
		result = serial_input_layer3(pkt->buf_begin, pkt->len,
					     &hw_src_addr, &hw_dst_addr);
		/* deallocate pkt and all fragment info */
		free_lowpan_pkt(pkt);
	    } else {
		result = 0;
	    }
	} else { /* no fragment header present */
	    result =  serial_input_layer3(buf, len,
					  &hw_src_addr, &hw_dst_addr);
	}
	
    } else {
	//printf("no data on serial port, but FD trigerred select\n");
    }
 discard_packet:
    if (ser_data) {
	free(ser_data);
    }
    if (ser_data && ser_len > 0) {
	return 1;
    } else {
	return 0;
    }
    //return result;
}

int serial_input_layer3(uint8_t *buf, int len,
			const hw_addr_t *hw_src_addr,
			const hw_addr_t *hw_dst_addr)
{
    uint8_t *dispatch = buf;
    //debug("%s()\n", __func__);
    //dump_serial_packet(buf, len);

    if (len <= 0) return 1;

    /* uncompressed IPv6 */
    if (*dispatch == 0x41) {
	return serial_input_ipv6_uncompressed(buf+1, len-1,
					      hw_src_addr, hw_dst_addr);

    }
    /* LOWPAN_HC1 compressed IPv6 */
    else if (*dispatch == 0x42) {
	return serial_input_ipv6_compressed(buf+1, len-1,
					    hw_src_addr, hw_dst_addr);
    }
    /* unknown dispatch value if we got here */
    else {
	debug("unknown dispatch value: %X\n", *dispatch);
	return tun_write(tun_fd, (char*) buf+1, len-1);
    }
}

int serial_input_ipv6_uncompressed(uint8_t *buf, int len,
				   const hw_addr_t *hw_src_addr,
				   const hw_addr_t *hw_dst_addr)
{
    debug("%s()\n", __func__);
    //dump_serial_packet(buf, len);
    // TODO: update neighbor table
    return tun_write(tun_fd, (char*) buf, len);
}

int serial_input_ipv6_compressed(uint8_t *buf, int len,
				 const hw_addr_t *hw_src_addr,
				 const hw_addr_t *hw_dst_addr)
{
    int ret=0;
    int new_len;
    uint8_t *new_buf;

    debug("%s()\n", __func__);
    if (0 == lowpan_decompress(buf, len,
			       hw_src_addr, hw_dst_addr,
			       &new_buf, &new_len)
	) {
	// TODO: update neighbor table
	buf = new_buf;
	len = new_len;
	ret =  tun_write(tun_fd, (char*) buf, len);
	
	if (new_buf && new_len) {
	    free(new_buf);
	}
    }
    
    return ret;
}

/* ------------------------------------------------------------------------- */

void timer_fired()
{
    struct timeval tv;
    lowpan_pkt_t *p;
    lowpan_pkt_t **q;

    /* time out old fragments */
    (void) gettimeofday(&tv, NULL);
    for(q = &fragments; *q; ) {
	if ((*q)->frag_timeout > tv.tv_sec) {
	    p = (*q)->next;
	    free(*q);
	    *q = p;
	} else {
	    q = &((*q)->next);
	}
    }
    // TODO: ND retransmission
    // TODO: neighbor table timeouts
}

/* shifts data between the serial port and the tun interface */
int serial_tunnel(serial_source ser_src, int tun_fd) {
    //int result;
    fd_set fs;
    
    while (1) {
	FD_ZERO (&fs);
	FD_SET (tun_fd, &fs);
	FD_SET (serial_source_fd(ser_src), &fs);

	select (tun_fd>serial_source_fd(ser_src)?
		tun_fd+1 : serial_source_fd(ser_src)+1,
		&fs, NULL, NULL, NULL);

	debug("--- select() fired ---\n");

	/* data available on tunnel device */
	if (FD_ISSET (tun_fd, &fs)) {
	    //result = tun_input();
	    while( tun_input() );
	}
	
	/* data available on serial port */
	if (FD_ISSET (serial_source_fd(ser_src), &fs)) {
	    /* more packets may be queued so process them all */
	    while (serial_input());
	    /* using serial_source_empty() seems to make select()
	     * fire way too often, so the above solution is better */
	    //while(! serial_source_empty(ser_src)) {
	    //result = serial_input();
		//}
	}
	/* end of data available */
    }
    /* end of while(1) */
    
    return 0;
}

int main(int argc, char **argv) {
    char dev[16];
    
    if (argc != 3)
	{
	    fprintf(stderr, "Usage: %s <device> <rate>\n", argv[0]);
	    exit(2);
	}
    
    hw_addr.type = HW_ADDR_SHORT;
    hw_addr.addr_short[0] = 0x00; // network byte order
    hw_addr.addr_short[1] = 0x12;

    /* create the tunnel device */
    dev[0] = 0;
    tun_fd = tun_open(dev);
    if (tun_fd < 1) {
	printf("Could not create tunnel device. Fatal.\n");
		return 1;
    }
    else {
	printf("Created tunnel device: %s\n", dev);
    }
    
    /* open the serial port */
    ser_src = open_serial_source(argv[1], platform_baud_rate(argv[2]),
				 1, stderr_msg);
    /* 0 - blocking reads
     * 1 - non-blocking reads
     */
    
    if (!ser_src) {
	debug("Couldn't open serial port at %s:%s\n",
		argv[1], argv[2]);
	exit(1);
    }
    
    /* set up the tun interface */
    printf("\n");
    ssystem("ifconfig tun0 up");
    ssystem("ifconfig tun0 mtu 1280");
    ssystem("ifconfig tun0 inet6 add 2001:0638:0709:1234::fffe:12/64");
    ssystem("ifconfig tun0 inet6 add fe80::fffe:12/64");
    printf("\n");

    printf("try:\n\tsudo ping6 -s 0 2001:0638:0709:1234::fffe:14\n"
	   "\tnc6 -u 2001:0638:0709:1234::fffe:14 1234\n\n");

    /* start tunneling */
    serial_tunnel(ser_src, tun_fd);
    
    /* clean up */
    close_serial_source(ser_src);
    //close(ser_fd);
    tun_close(tun_fd, dev);
    return 0;
}
