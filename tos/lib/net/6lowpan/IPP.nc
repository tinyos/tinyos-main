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
 * Parts of the 6lowpan implementation design were inspired Andrew
 * Christian's port of Adam Dunkel's uIP to TinyOS 1.x. This work is
 * distributed under the following copyrights:
 *
 * Copyright (c) 2001-2003, Adam Dunkels.
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
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.  
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  
 *
 * Copyright (c) 2005, Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

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
 * The actual implementaion of the 6lowpan/IPv6 stack lives in this file.
 */

#include "IP.h"
#include "IP_internal.h"
#include "message.h"
#ifdef ENABLE_PRINTF_DEBUG
#include "printf.h"
#endif /* ENABLE_PRINTF_DEBUG */

module IPP {
    provides {
	interface SplitControl as IPControl;
	interface IP;
	interface UDPClient[uint8_t i];
    }
    uses {
	interface Timer<TMilli> as Timer;
	interface Pool<lowpan_pkt_t> as SendPktPool;
	interface Pool<app_data_t> as AppDataPool;
	interface Pool<frag_info_t> as FragInfoPool;

	interface SplitControl as MessageControl;
	interface Receive;
	interface AMSend;
	interface Packet;
	interface AMPacket;

#ifdef ENABLE_PRINTF_DEBUG
	interface PrintfFlush;
	interface SplitControl as PrintfControl;
#endif /* ENABLE_PRINTF_DEBUG */

	interface Leds;
    }
}
 
implementation { 
    /* global variables */
  enum {
    COUNT_UDP_CLIENT = uniqueCount("UDPClient"),
    COUNT_UDP_CONNS  = COUNT_UDP_CLIENT
  };
    
    ip6_addr_t global_addr;       
    ip6_addr_t linklocal_addr;       

    uint16_t g_dgram_tag = 0;
    uint16_t uip_len, uip_slen;
    uint8_t  uip_flags;     /* The uip_flags variable is used for
			     communication between the TCP/IP stack
			     and the application program. */

    message_t g_msg; // AM for sending
    lowpan_pkt_t rx_pkt; // packet used for receiving
    //struct lowpan_pkt send_pkt[SEND_PKTS]; // packets to be sent
    lowpan_pkt_t *send_queue; // packets to be sent - queue

    frag_buf_t frag_bufs[FRAG_BUFS]; // fragment reassembly buffers

    struct udp_conn udp_conns[COUNT_UDP_CONNS];
    static uint16_t lastport;       /* Keeps track of the last port used for
				       a new connection. */
    static int g_send_pending = 0;

    // Pre-declare
    // clear all fields, set app_data = NULL
    void lowpan_pkt_clear(lowpan_pkt_t *pkt);
    int ip6_addr_cmp(const ip6_addr_t *a, const ip6_addr_t *b);

    static void dump_serial_packet(const unsigned char *packet, const int len);
/*---------------------------------------------------------------------------*/
/* from http://www.nabble.com/memcpy-assumes-16-bit-alignment--t712619.html */
void * 
my_memcpy(void *dst0, const void *src0, size_t len) 
{ 
        char *dst = (char *)dst0; 
        const char *src = (const char *)src0; 
        void *ret = dst0; 

        for (; len > 0; len--) 
                *dst++ = *src++; 

        return ret; 
}

/*
 * Use this function for copying/setting/memset() 16-bit values
 * on the MSP430 !!!
 *
 * The mspgcc compiler geenrates broken code when doing memset with 16
 * bit values, i.e. things go wrong if they are not aligned at 16-bit
 * boundaries. See
 * http://www.nabble.com/msp430-gcc-generating-unaligned-access.-t2261862.html
 * and page 25 in http://www.eecs.harvard.edu/~konrad/projects/motetrack/mspgcc-manual-20031127.pdf for details.
 */
/* use when DST may be UNALIGNED */
inline void set_16t(void *dst, uint16_t val)
{
    *((uint8_t*)dst) = *((uint8_t*)&val);
    *(((uint8_t*)dst)+1) = *(((uint8_t*)&val)+1);
    //memcpy((uint8_t*)dst, (uint8_t*)&val, sizeof(uint8_t));
    //memcpy(((uint8_t*)dst)+1, ((uint8_t*)&val)+1, sizeof(uint8_t));
}

/* use when SRC may be UNALIGNED */
inline uint16_t get_16t(void *val)
{
    uint16_t tmp;
    *((uint8_t*)&tmp) = *((uint8_t*)val);
    *(((uint8_t*)&tmp)+1) = *(((uint8_t*)val)+1);
    //memcpy((uint8_t*)&tmp, (uint8_t*)val, sizeof(uint8_t));
    //memcpy(((uint8_t*)&tmp)+1, ((uint8_t*)val)+1, sizeof(uint8_t));
    return tmp;
}

  inline uint16_t htons( uint16_t val )
  {
    // The MSB is little-endian; network order is big
    return ((val & 0xff) << 8) | ((val & 0xff00) >> 8);
  }

  inline uint16_t ntohs( uint16_t val )
  {
    // The MSB is little-endian; network order is big
    return ((val & 0xff) << 8) | ((val & 0xff00) >> 8);
  }

  inline void htonl( uint32_t val, uint8_t *dest )
  {
    dest[0] = (val & 0xff000000) >> 24;
    dest[1] = (val & 0x00ff0000) >> 16;
    dest[2] = (val & 0x0000ff00) >> 8;
    dest[3] = (val & 0x000000ff);
  }

  inline uint32_t ntohl( uint8_t *src )
  {
    return (((uint32_t) src[0]) << 24) | (((uint32_t) src[1]) << 16) |
      (((uint32_t) src[2]) << 8) | (((uint32_t) src[3]));
  }

    /*
  inline void uip_pack_ipaddr( ip6_addr_t *addr, uint8_t *new_addr) 
  {
      memcpy(addr, new_addr, sizeof(addr));
  }

  // Unpack the IP address into an array of octet
  inline void uip_unpack_ipaddr( uint8_t *in, uint8_t *out )
  {
      memcpy(out, in, sizeof(ip6_addr_t));
  }
    */
/*---------------------------------------------------------------------------*/
    
    /* This should be optimized for aligned and unaligned case */
    static uint16_t ip_chksum(const uint8_t *buf, uint16_t len,
			      uint16_t acc)
    {
	uint16_t v;
	
	for (; len > 1; len -= 2) {
	    v = (((uint16_t) buf[1]) << 8) | ((uint16_t) buf[0]);
	    
	    if ( (acc += v) < v ) acc++;
	    buf += 2;
    }
	
	// add an odd byte (note we pad with 0)
	if (len) {
	    v = (uint16_t) buf[0];
	    if ( (acc += v) < v ) acc++;
	}
	
	return acc;
    }
    
    /* 
     * IPv6 checksum of the pseudo-header (RFC 2460, Sec 8.1)
     * src_addr and dst_addr are in nerwork byte order
     * len is in host byte order (will internally be converted)
     */
    static uint16_t ipv6_chksum(const ip6_addr_t* src_addr,
				const ip6_addr_t* dst_addr,
				const uint8_t next_header,
				const uint16_t upper_layer_len,
				uint16_t acc)
    {
	uint16_t tmp;
	
	/* source address */
	acc =  ip_chksum((const uint8_t *) src_addr, sizeof(*src_addr), acc);

	/* destination address */
	acc =  ip_chksum((const uint8_t *) dst_addr, sizeof(*dst_addr), acc);

	/* upper-layer packet length */
	tmp = htons(upper_layer_len);
	acc = ip_chksum((const uint8_t *) &tmp, sizeof(tmp), acc);

	/* next header */
	tmp = htons(next_header);
	acc = ip_chksum((const uint8_t *) &tmp, sizeof(tmp), acc);
	
	return acc;
    }

    /* same as above, but including the uppel-layer buffer */
    static uint16_t ipv6_chksum_data(const ip6_addr_t* src_addr,
				     const ip6_addr_t* dst_addr, 
				     const uint8_t next_header,
				     const uint8_t *data, uint16_t data_len,
				     uint16_t acc)
    {
	/* upper-layer payload */
	acc = ip_chksum(data, data_len, acc);
	
	return ipv6_chksum(src_addr, dst_addr, next_header, data_len, acc);
    }
/*---------------------------------------------------------------------------*/
    bool ipv6_addr_is_zero(const ip6_addr_t *addr)
    {
	int i;
	for (i=0;i<16;i++) {
	    if (addr->addr[i]) {
		return FALSE;
	    }
	}
	return TRUE;
    }

    bool ipv6_addr_is_linklocal_unicast(const ip6_addr_t *addr)
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
	    return TRUE;
	else
	    return FALSE;
    }
    
//TODO: prepend pan_id once we have a proper 802.15.4 stack
void ipv6_iface_id_from_am_addr(am_addr_t am_addr, uint8_t *host_part)
{
    memset(host_part, 0, 6);
    host_part[4] = 0xFF;
    host_part[5] = 0xFE;
    host_part += 6;
    set_16t(host_part, htons(am_addr));
}

void ipv6_iface_id_from_hw_addr(hw_addr_t *hw_addr, uint8_t *host_part)
{
    if (hw_addr->type == HW_ADDR_SHORT) {
	memset(host_part, 0, 6);
	host_part[4] = 0xFF;
	host_part[5] = 0xFE;
	host_part[7] = hw_addr->addr_short[0];
	host_part[8] = hw_addr->addr_short[1];
	//ipv6_iface_id_from_am_addr(hw_addr->addr_short, host_part);
    } else {
	//TODO
    }
}
    
bool ipv6_addr_is_linklocal_multicast(const ip6_addr_t *addr)
{
    if (addr->addr[0] == 0xFF
	&& addr->addr[1] == 0x02)
	return TRUE;
    else
	return FALSE;
}

bool ipv6_addr_is_linklocal(const ip6_addr_t *addr)
{
    return (ipv6_addr_is_linklocal_unicast(addr)
	    || ipv6_addr_is_linklocal_multicast(addr));
}

bool ipv6_addr_is_linklocal_allnodes(const ip6_addr_t *addr)
{
    //TODO: interface-local addr FF01::1
    if (   addr->addr[0] == 0xFF
	   && addr->addr[1] == 0x02
	   && addr->addr[2] == 0
	   && addr->addr[3] == 0
	   && addr->addr[4] == 0
	   && addr->addr[5] == 0
	   && addr->addr[6] == 0
	   && addr->addr[7] == 0
	   && addr->addr[8] == 0
	   && addr->addr[9] == 0
	   && addr->addr[10] == 0
	   && addr->addr[11] == 0
	   && addr->addr[12] == 0
	   && addr->addr[13] == 0
	   && addr->addr[14] == 0
	    && addr->addr[15] == 0x01
	   )
	return TRUE;
    else
	return FALSE;
}

bool ipv6_addr_is_solicited_node_multicast_prefix(const ip6_addr_t *addr)
{
//       Solicited-Node Address:  FF02:0:0:0:0:1:FFXX:XXXX

//    Solicited-Node multicast address are computed as a function of a
//    node's unicast and anycast addresses.  A Solicited-Node multicast
//    address is formed by taking the low-order 24 bits of an address
//    (unicast or anycast) and appending those bits to the prefix
//    FF02:0:0:0:0:1:FF00::/104 resulting in a multicast address in the
//    range

//          FF02:0:0:0:0:1:FF00:0000

//    to

//          FF02:0:0:0:0:1:FFFF:FFFF

    if (   addr->addr[0] == 0xFF
	   && addr->addr[1] == 0x02
	   && addr->addr[2] == 0
	   && addr->addr[3] == 0
	   && addr->addr[4] == 0
	   && addr->addr[5] == 0
	   && addr->addr[6] == 0
	   && addr->addr[7] == 0
	   && addr->addr[8] == 0
	   && addr->addr[9] == 0
	   && addr->addr[10] == 0
	   && addr->addr[11] == 0x01
	   && addr->addr[12] == 0xFF
	   )
	return TRUE;
    else
	return FALSE;
}

uint8_t cmp_ipv6_addr(const ip6_addr_t *addr1, const ip6_addr_t *addr2)
{
    return memcmp(addr1, addr2, sizeof(ip6_addr_t));
}

uint8_t ipv6_addr_is_for_me(const ip6_addr_t *addr)
{
    //TODO: loopback addr (::1)
    //TODO: interface-local addr FF01::1
    if (cmp_ipv6_addr(addr, &global_addr) == 0 ||
	cmp_ipv6_addr(addr, &linklocal_addr) == 0 ||
	ipv6_addr_is_linklocal_allnodes(addr) ||
	(ipv6_addr_is_solicited_node_multicast_prefix(addr)
	 && (((addr->addr[13] == global_addr.addr[13])
	      && (addr->addr[14] == global_addr.addr[14])
	      && (addr->addr[15] == global_addr.addr[15])
	      ) ||
	     ((addr->addr[13] == linklocal_addr.addr[13])
		  && (addr->addr[14] == linklocal_addr.addr[14])
	      && (addr->addr[15] == linklocal_addr.addr[15])
	      )
	     )
	 )
	)
	return 1;
    else
	return 0;
}

/* determine the right src_addr given a dst_addr */
ip6_addr_t * determine_src_ipv6_addr(const ip6_addr_t *dst_addr)
{
    if (ipv6_addr_is_linklocal(dst_addr)) {
	return &linklocal_addr;
    } else {
	return &global_addr;
    }
}

uint8_t cmp_hw_addr(const hw_addr_t *addr1, const hw_addr_t *addr2)
{
    // for short addresses compare only the first two bytes
    if (addr1->type == HW_ADDR_SHORT && addr2->type == HW_ADDR_SHORT) {
	return memcmp(addr1->addr_short, addr2->addr_short, 2);
    } else {
	return memcmp(addr1, addr2, sizeof(hw_addr_t));
    }
}

uint8_t hw_addr_is_broadcat(const hw_addr_t *hw_addr)
{
    if (hw_addr->type == HW_ADDR_SHORT
	&& hw_addr->addr_short[0] == 0xFF
	&& hw_addr->addr_short[1] == 0xFF)
	return 1;
    // TODO: long address
    else return 0;
}

uint8_t hw_addr_is_for_me(const hw_addr_t *addr)
{
    am_addr_t am_addr = call AMPacket.address();
    if (hw_addr_is_broadcat(addr) ||
	(addr->addr_short[0] == (uint8_t) am_addr
	 && addr->addr_short[1] == (uint8_t) (am_addr >> 8))
	)
	return 1;
    else
	return 0;
}
/*---------------------------------------------------------------------------*/

void increment_g_dgram_tag()
{
    uint16_t tmp = ntohs(g_dgram_tag);
    if (tmp == 0xFFFF)
	tmp = 0;
    else
	tmp++;
    g_dgram_tag = htons(tmp);
}

void lowpan_pkt_clear(lowpan_pkt_t *pkt)
{
    memset(pkt, 0, sizeof(*pkt));
    pkt->header_begin = pkt->header + sizeof(pkt->header);
}

/*
void frag_buf_clear(frag_buf_t *frag_buf)
{
    memset(frag_buf, 0, sizeof(*frag_buf));
    frag_buf->buf_begin = frag_buf->buf;
}
*/

frag_buf_t * find_fragment(hw_addr_t *hw_src_addr, hw_addr_t *hw_dst_addr,
			   uint16_t dgram_size, uint16_t dgram_tag)
{
    int i;
    for (i = 0; i< FRAG_BUFS; i++) {
	//printf("find_frag\n");
	if (frag_bufs[i].frag_timeout != FRAG_FREE) {
	    //printf("find: [%d] %d\n", i, frag_bufs[i].frag_timeout);
	    /*
	  printf("find: tag: 0x%04X, size: %d\n",
		 get_16t(&frag_bufs[i].dgram_tag),
		 ntohs(get_16t(&frag_bufs[i].dgram_size)));
	    */
	    if (   get_16t(&(frag_bufs[i].dgram_tag)) == dgram_tag
		&& get_16t(&(frag_bufs[i].dgram_size)) == dgram_size
		&& cmp_hw_addr(&frag_bufs[i].hw_src_addr, hw_src_addr) == 0
		&& cmp_hw_addr(&frag_bufs[i].hw_dst_addr, hw_dst_addr) == 0
		) {
		return &(frag_bufs[i]);
	    }
	} else {
	    //printf("find: [%d] FREE\n", i);
	}
    }
    return NULL;
}

void free_frag_list(frag_info_t *p)
{
    frag_info_t *q;
    while (p) {
	q = p->next;
	call FragInfoPool.put(p);
	p = q;
    }
}
/*---------------------------------------------------------------------------*/
  
    void ip_init()
    {
	//int i;
	lastport = 1024;
	memset(udp_conns, 0, sizeof(udp_conns));
	//memset(&global_addr, 0, sizeof(global_addr));
	memset(&linklocal_addr, 0, sizeof(linklocal_addr));
	memset(frag_bufs, 0, sizeof(frag_bufs));
	/*
	for(i=0;i<FAG_BUFS,i++) {
	    frag_buf_clear(frag_bufs[i]);
	}
	*/
    }

    uint16_t udp_assign_port()
    {
	int c;
	
	/* Find an unused local port. */
    again:
	++lastport;
	
	if (lastport >= 32000) {
	    lastport = 4096;
	}
	
	for (c = 0; c < COUNT_UDP_CONNS; ++c) {
	    if (udp_conns[c].lport == lastport) {
		goto again;
	    }
	}
	
	return lastport;
    }    

/* ========================= IPv6 - output ================================= */
task void sendTask()
{
    lowpan_pkt_t *pkt = send_queue;
    struct lowpan_frag_hdr *frag_hdr;
    uint8_t *payload;
    uint8_t frame_len;
    uint8_t len; /* length of the fragment just being sent
		  * excluding the 6lowpan optional headers */
    uint8_t remaining_len; /* how much more data can we fit 
			    * into this fragment */

    uint8_t *tmp_cpy_buf; /* simplifies memcpy */
    uint8_t tmp_cpy_len; /* simplifies memcpy */

    if (!pkt || g_send_pending) {
	return;
    }
    
    //len = pkt->header_len + pkt->app_data_len - pkt->dgram_offset*8;
    if (pkt->header_len + pkt->app_data_len <= LINK_DATA_MTU) {
	/* fragmentation not needed */
	frame_len = pkt->header_len + pkt->app_data_len;
	/* prepare the AM */
	call Packet.clear(&g_msg);
	call Packet.setPayloadLength(&g_msg, frame_len);
	payload = call Packet.getPayload(&g_msg, frame_len);
	// memset(payload, 0 , payload_len);
	// should check payload_len here
	
	/* copy header */
	if (pkt->header_begin && pkt->header_len)
	    memcpy(payload, pkt->header_begin, pkt->header_len);
	payload += pkt->header_len;

	/* copy app_data */
	if (pkt->app_data_begin && pkt->app_data_len)
	    memcpy(payload, pkt->app_data_begin, pkt->app_data_len);

    } else {
	/* do fragmentation */
	if (pkt->dgram_offset == 0) {
	    /* first fragment */
	    increment_g_dgram_tag();
	    set_16t(&pkt->dgram_size,
		    htons(pkt->header_len + pkt->app_data_len));
	    
	    /* align fragment length at an 8-byte multiple */
	    len = LINK_DATA_MTU - sizeof(struct lowpan_frag_hdr);
	    len -= len%8;
	    frame_len = len + sizeof(struct lowpan_frag_hdr);
	} else {
	    /* subsequent fragment */
	    if (pkt->header_len + pkt->app_data_len - pkt->dgram_offset*8
		<= LINK_DATA_MTU - sizeof(struct lowpan_frag_hdr)
		- sizeof(uint8_t)) {
		/* last fragment -- does not have to be aligned
		 * at an 8-byte multiple */
		len = pkt->header_len + pkt->app_data_len
		    - pkt->dgram_offset*8;
	    } else {
		/* align fragment length at an 8-byte multiple */
		len = LINK_DATA_MTU - sizeof(struct lowpan_frag_hdr)
		    - sizeof(uint8_t);
		len -= len%8;
	    }
	    frame_len = len + sizeof(struct lowpan_frag_hdr)
		+ sizeof(uint8_t);
	}
    
	/* prepare the AM */
	call Packet.clear(&g_msg);
	call Packet.setPayloadLength(&g_msg,frame_len);
	payload = call Packet.getPayload(&g_msg, frame_len);
	remaining_len = frame_len;
	if (remaining_len != frame_len) {
	    //TODO: report an error
#ifdef ENABLE_PRINTF_DEBUG
	    printf("payload length does not match requested length\n");
	    call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	    return;
	}

	/* fill in the fragment header */
	frag_hdr = (struct lowpan_frag_hdr *) payload;
	set_16t(&frag_hdr->dgram_size, pkt->dgram_size);
	set_16t(&frag_hdr->dgram_tag, g_dgram_tag);
	payload += sizeof(struct lowpan_frag_hdr);
	remaining_len -= sizeof(struct lowpan_frag_hdr);
	
	if (pkt->dgram_offset == 0) {
	    /* first fragment */
	    frag_hdr->dispatch |= DISPATCH_FIRST_FRAG;
	} else {
	    /* subsequent fragment */
	    frag_hdr->dispatch |= DISPATCH_SUBSEQ_FRAG;
	    *payload = pkt->dgram_offset;
	    payload += sizeof(uint8_t);
	}

	/* copy header */
	if (pkt->header_begin
	    && pkt->header_len
	    && pkt->header_len > pkt->dgram_offset*8
	       /* don't copy the header if offset is beyond it*/
	    ) {
	    /* determine what has to be copied */
	    tmp_cpy_buf = pkt->header_begin + pkt->dgram_offset*8;
	    tmp_cpy_len = min(pkt->header_len - pkt->dgram_offset*8,
			  remaining_len);
	    /* copy it */
	    memcpy(payload, tmp_cpy_buf, tmp_cpy_len);
	    payload += tmp_cpy_len;
	    remaining_len -= tmp_cpy_len;
	}
	
	/* copy app_data */
	if (remaining_len
	    && pkt->app_data_begin
	    && pkt->app_data_len
	    ) {
	    /* determine what has to be copied */
	    if (pkt->dgram_offset*8 > pkt->header_len) {
		tmp_cpy_buf = pkt->app_data_begin
		              + pkt->dgram_offset*8 - pkt->header_len;
	    } else {
		/* header has been copied only now, offset not yet updated */
		tmp_cpy_buf = pkt->app_data_begin;
	    }
	    tmp_cpy_len = min(remaining_len,
			      pkt->app_data_len
			      - (pkt->dgram_offset*8 - pkt->header_len));
	    /* copy it */
	    memcpy(payload, tmp_cpy_buf, tmp_cpy_len);
	    payload += tmp_cpy_len;
	    remaining_len -= tmp_cpy_len;
	}
		
	/* update the offset - in 8-byte multiples */
	pkt->dgram_offset += len/8;
	if (len%8) {
	    /* last fragment with a special length */
	    pkt->dgram_offset++;
	}
    }

    /* send the AM */
    g_send_pending = 1;
    call AMSend.send(AM_BROADCAST_ADDR, &g_msg, frame_len);
    //call AMSend.send(0x12, &g_msg, frame_len);
}

event void AMSend.sendDone(message_t* msg, error_t error)
{
    uint16_t len;
    lowpan_pkt_t *pkt = send_queue;

    g_send_pending = 0;

    if (!send_queue) {
	// somethign really went wrong...
	return;
    }

    len = pkt->header_len + pkt->app_data_len;
    if (len <= LINK_DATA_MTU || pkt->dgram_offset*8 >= len){
	/* packet has been completely sent, we can move on to the next one */

	/* UDPClient.sendDone notification */
	if (send_queue->notify_num != LOWPAN_PKT_NO_NOTIFY) {
	    signal UDPClient.sendDone[send_queue->notify_num - 1]
		(SUCCESS, send_queue->app_data);
	}

	/* deallocation of app_data (fragment reassembly buffer) */
	if (send_queue->app_data_dealloc == APP_DATA_DEALLOC_TRUE
	    && send_queue->app_data) {
	    call AppDataPool.put((app_data_t*) send_queue->app_data);
	    send_queue->app_data = NULL;
	}
	
	pkt = send_queue->next;
	call SendPktPool.put(send_queue);
	send_queue = pkt;
    }
    if (send_queue) {
	post sendTask();
    }
}

void ipv6_output_uncompressed(lowpan_pkt_t *pkt, const uint8_t next_header)
{
    struct ip6_hdr *hdr;
    lowpan_pkt_t *p;

    pkt->header_begin -= sizeof(struct ip6_hdr);
    pkt->header_len += sizeof(struct ip6_hdr);
    hdr = (struct ip6_hdr *) pkt->header_begin;

    /* fill in the IPv6 header */
    hdr->vtc = IPV6_VERSION; /* IPv6 version */
    /* payload length */
    set_16t(&hdr->plen, htons(pkt->header_len + pkt->app_data_len
			      - sizeof(struct ip6_hdr)));
    
    hdr->nxt_hdr = next_header;
    hdr->hlim = IP_HOP_LIMIT; /* hop limit */
    
    memcpy(&hdr->src_addr, &pkt->ip_src_addr, sizeof(hdr->src_addr));
    memcpy(&hdr->dst_addr, &pkt->ip_dst_addr, sizeof(hdr->dst_addr));

    /* set 6lowpan dispatch value */
    pkt->header_begin -= sizeof(uint8_t);
    pkt->header_len += sizeof(uint8_t);
    *(pkt->header_begin) = DISPATCH_UNCOMPRESSED_IPV6;

    //TODO: check if neighbor is information available
    //  if yes
    //    fill in hw_addr
    //    append to send_queue
    //  else
    //    append to neighbor_queue
    //    request ND, add an entry into the neighbor table

    /* append pkt to send queue */
    if(!send_queue) {
	send_queue = pkt;
    } else {
	for(p=send_queue; p->next; p=p->next);
	p->next = pkt;
    }

    /* schedule sendTask */
    post sendTask();
}

/* determines length of the inline carried fields for the HC1 encoding
 * the return value is the number of bits, bot bytes !!!
 */
int get_hc1_length(uint8_t hc1_enc)
{
    int len = 0;
    /* Hop Limit always carried inline */
    len += 8;
    
    /* source IP address */
    if ((hc1_enc & HC1_SRC_PREFIX_MASK) == HC1_SRC_PREFIX_INLINE)
	len += 64;
     
    if ((hc1_enc & HC1_SRC_IFACEID_MASK) == HC1_SRC_IFACEID_INLINE)
	len += 64;

    /* destination IP address */
    if ((hc1_enc & HC1_DST_PREFIX_MASK) == HC1_DST_PREFIX_INLINE)
	len += 64;
     
    if ((hc1_enc & HC1_DST_IFACEID_MASK) == HC1_DST_IFACEID_INLINE)
	len += 64;

    /* Traffic Class and Flow Label */
    if ((hc1_enc & HC1_TCFL_MASK) == HC1_TCFL_INLINE)
	len += 24;

    /* Next Header */
    if ((hc1_enc & HC1_NEXTHDR_MASK) == HC1_NEXTHDR_INLINE)
	len += 8;

    return len;
}

void ipv6_compressed_output(lowpan_pkt_t *pkt, const uint8_t next_header,
			    uint8_t hc2_enc, bool hc2_present)
{
    lowpan_pkt_t *p;
    uint8_t hc1_enc = 0;

    /* HC2 compression */
    if (hc2_present) {
	hc1_enc |= HC1_HC2_PRESENT;
    } else {    
	hc1_enc |= HC1_HC2_NONE;
    }

    /* next header */
    switch (next_header) {
    case NEXT_HEADER_UDP:
	hc1_enc |= HC1_NEXTHDR_UDP;
	break;
    case NEXT_HEADER_ICMP6:
	hc1_enc |= HC1_NEXTHDR_ICMP;
	break;
    case NEXT_HEADER_TCP:
	hc1_enc |= HC1_NEXTHDR_TCP;
	break;
    default:
	hc1_enc |= HC1_NEXTHDR_INLINE;

	pkt->header_begin -= sizeof(next_header);
	pkt->header_len += sizeof(next_header);
	*(pkt->header_begin) = next_header;
	break;
    }

    /* we're always sending packets with TC anf FL zero */
    hc1_enc |= HC1_TCFL_ZERO;
    
    /* destination address interface identifier */
    hc1_enc |= HC1_DST_IFACEID_INLINE;
    
    pkt->header_begin -= 8;
    pkt->header_len += 8;
    memcpy(pkt->header_begin, ((void*)&(pkt->ip_dst_addr)) + 8, 8);

    /* destination address prefix */
    if (ipv6_addr_is_linklocal_unicast(&pkt->ip_dst_addr)) {
	hc1_enc |= HC1_DST_PREFIX_LINKLOCAL;
    } else {
	hc1_enc |= HC1_DST_PREFIX_INLINE;

	pkt->header_begin -= 8;
	pkt->header_len += 8;
	memcpy(pkt->header_begin, &(pkt->ip_dst_addr), 8);
    }

    /* source address interface identifier */
    hc1_enc |= HC1_SRC_IFACEID_INLINE;
    
    pkt->header_begin -= 8;
    pkt->header_len += 8;
    memcpy(pkt->header_begin, ((void*)&(pkt->ip_src_addr)) + 8, 8);

    /* source address prefix */
    if (ipv6_addr_is_linklocal_unicast(&pkt->ip_src_addr)) {
	hc1_enc |= HC1_SRC_PREFIX_LINKLOCAL;
    } else {
	hc1_enc |= HC1_SRC_PREFIX_INLINE;

	pkt->header_begin -= 8;
	pkt->header_len += 8;
	memcpy(pkt->header_begin, &(pkt->ip_src_addr), 8);
    }

    /* Hop Limit */
    pkt->header_begin -= sizeof(uint8_t);
    pkt->header_len += sizeof(uint8_t);
    *pkt->header_begin = IP_HOP_LIMIT;
    
    /* HC2 encoding field */
    if (hc2_present) {
	pkt->header_begin -= sizeof(uint8_t);
	pkt->header_len += sizeof(uint8_t);
	*(pkt->header_begin) = hc2_enc;
    }

    /* HC1 encoding field */
    pkt->header_begin -= sizeof(uint8_t);
    pkt->header_len += sizeof(uint8_t);
    *(pkt->header_begin) = hc1_enc;

    /* set 6lowpan dispatch value */
    pkt->header_begin -= sizeof(uint8_t);
    pkt->header_len += sizeof(uint8_t);
    *(pkt->header_begin) = DISPATCH_COMPRESSED_IPV6;

    /* append pkt to send queue */
    if(!send_queue) {
	send_queue = pkt;
    } else {
	for(p=send_queue; p->next; p=p->next);
	p->next = pkt;
    }

    /* schedule sendTask */
    post sendTask();
}

void icmpv6_output(lowpan_pkt_t *pkt,
		   uint8_t type, uint8_t code)
{
    struct icmp6_hdr *hdr;
    uint16_t cksum = 0;
    /* fill in the source address if not set */
    if (ipv6_addr_is_zero(&pkt->ip_src_addr)) {
	memcpy(&pkt->ip_src_addr,
	       determine_src_ipv6_addr(&pkt->ip_dst_addr),
	       sizeof(pkt->ip_src_addr));
    }

    /* fill in the ICMPv6 header */
    pkt->header_begin -= sizeof(struct icmp6_hdr);
    pkt->header_len += sizeof(struct icmp6_hdr);
    hdr = (struct icmp6_hdr *) pkt->header_begin;

    hdr->type = type;
    hdr->code = code;

    /* calculate the  checksum */
    set_16t(&hdr->cksum, 0);
    cksum = ipv6_chksum(&pkt->ip_src_addr, &pkt->ip_dst_addr,
			NEXT_HEADER_ICMP6,
			pkt->header_len + pkt->app_data_len, cksum);
    cksum = ip_chksum((void*)hdr, sizeof(struct icmp6_hdr), cksum);
    cksum = ip_chksum(pkt->app_data_begin, pkt->app_data_len,
			   cksum);
    cksum = ~cksum;
    set_16t(&hdr->cksum, cksum);
    
    ipv6_compressed_output(pkt, NEXT_HEADER_ICMP6, 0, FALSE);
}

error_t udp_uncompressed_output(void* buf, uint16_t len,
				const ip6_addr_t *src_addr,
				const ip6_addr_t *dst_addr,
				uint16_t src_port,
				uint16_t dst_port,
				uint8_t udp_client_num)
{
    struct udp_hdr *hdr;
    lowpan_pkt_t *pkt;
    uint16_t cksum = 0;

    if (!dst_addr) return FAIL;

    pkt = call SendPktPool.get();
    if (!pkt) return FAIL;

    lowpan_pkt_clear(pkt);
    
    /* set the UDPCliemt number to allow for signalling sendDone */
    pkt->notify_num = udp_client_num;

    /* set application data */
    pkt->app_data = buf;
    pkt->app_data_begin = buf;
    pkt->app_data_len = len;
    
    /* set IP addresses */
    memcpy(&pkt->ip_dst_addr, dst_addr, sizeof(pkt->ip_dst_addr));
    if (src_addr) {
	memcpy(&pkt->ip_src_addr, src_addr, sizeof(pkt->ip_src_addr));
    } else {
	memcpy(&pkt->ip_src_addr,
	       determine_src_ipv6_addr(dst_addr),
	       sizeof(pkt->ip_src_addr));
    }

    /* fill in the UDP header */
    pkt->header_begin -= sizeof(struct udp_hdr);
    pkt->header_len += sizeof(struct udp_hdr);
    hdr = (struct udp_hdr *) pkt->header_begin;
    /* src port */
    set_16t(&hdr->srcport, src_port);
    /* dst port */
    set_16t(&hdr->dstport, dst_port);
    /* length */
    set_16t(&hdr->len,htons(len + sizeof(struct udp_hdr)));
    /* checksum */
    set_16t(&hdr->chksum, 0);
    cksum = ip_chksum((uint8_t*) hdr, sizeof(struct udp_hdr), cksum);
    cksum = ipv6_chksum(&pkt->ip_dst_addr,
			&pkt->ip_src_addr,
			NEXT_HEADER_UDP,
			sizeof(struct udp_hdr) + len, cksum);
    cksum = ip_chksum(buf, len, cksum);
    if (cksum != 0xFFFF) {
	cksum = ~cksum;
    }
    set_16t(&hdr->chksum, cksum);

    ipv6_compressed_output(pkt, NEXT_HEADER_UDP, 0, FALSE);

    return SUCCESS;
}

error_t udp_compressed_output(void* buf, uint16_t len,
			      const ip6_addr_t *src_addr,
			      const ip6_addr_t *dst_addr,
			      uint16_t src_port,
			      uint16_t dst_port,
			      uint8_t udp_client_num)
{
    lowpan_pkt_t *pkt;
    uint16_t cksum = 0;
    uint16_t hc2_enc = 0;
    uint16_t udp_len = htons(len + sizeof(struct udp_hdr));

    if (!dst_addr) return FAIL;

    pkt = call SendPktPool.get();
    if (!pkt) return FAIL;

    lowpan_pkt_clear(pkt);
    
    /* set the UDPCliemt number to allow for signalling sendDone */
    pkt->notify_num = udp_client_num;

    /* set application data */
    pkt->app_data = buf;
    pkt->app_data_begin = buf;
    pkt->app_data_len = len;
    
    /* set IP addresses */
    memcpy(&pkt->ip_dst_addr, dst_addr, sizeof(pkt->ip_dst_addr));
    if (src_addr) {
	memcpy(&pkt->ip_src_addr, src_addr, sizeof(pkt->ip_src_addr));
    } else {
	memcpy(&pkt->ip_src_addr,
	       determine_src_ipv6_addr(dst_addr),
	       sizeof(pkt->ip_src_addr));
    }

    /* Checksum */
    cksum = 0;
    cksum = ip_chksum((void*) &src_port, sizeof(src_port), cksum);
    cksum = ip_chksum((void*) &dst_port, sizeof(src_port), cksum);
    cksum = ip_chksum((void*) &udp_len, sizeof(udp_len), cksum);
    cksum = ipv6_chksum(&pkt->ip_dst_addr,
			&pkt->ip_src_addr,
			NEXT_HEADER_UDP,
			sizeof(struct udp_hdr) + len, cksum);
    cksum = ip_chksum(buf, len, cksum);
    if (cksum != 0xFFFF) {
	cksum = ~cksum;
    }

    /* HC_UDP encoding */
    /* Checksum */
    pkt->header_begin -= sizeof(cksum);
    pkt->header_len += sizeof(cksum);
    set_16t(pkt->header_begin, cksum);

    /* Length */
    //hc2_enc |= HC2_UDP_LEN_COMPR;
    hc2_enc |= HC2_UDP_LEN_INLINE;
    pkt->header_begin -= sizeof(udp_len);
    pkt->header_len += sizeof(udp_len);
    set_16t(pkt->header_begin, udp_len);

    /* Destination Port */
    hc2_enc |= HC2_UDP_DST_PORT_INLINE;
    pkt->header_begin -= sizeof(dst_port);
    pkt->header_len += sizeof(dst_port);
    set_16t(pkt->header_begin, dst_port);

    /* Source Port */
    hc2_enc |= HC2_UDP_SRC_PORT_INLINE;
    pkt->header_begin -= sizeof(src_port);
    pkt->header_len += sizeof(src_port);
    set_16t(pkt->header_begin, src_port);
    
    ipv6_compressed_output(pkt, NEXT_HEADER_UDP, hc2_enc, TRUE);

    return SUCCESS;
}
/* ========================== IPv6 - input ================================= */
void icmpv6_input(uint8_t* buf, uint16_t len)
{
    lowpan_pkt_t *pkt;
    struct icmp6_hdr *hdr = (struct icmp6_hdr *)buf;

    /* Compute and check the IP header checksum. */
    if (ipv6_chksum_data(&rx_pkt.ip_src_addr, &rx_pkt.ip_dst_addr,
		    NEXT_HEADER_ICMP6, buf, len, 0)
	!= 0xffff) {
#ifdef ENABLE_PRINTF_DEBUG
	printf("icmpv6_input(): checksum failed\n");
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	call Leds.led0Toggle();
	return;
    }

    buf += sizeof(struct icmp6_hdr);
    len -= sizeof(struct icmp6_hdr);
    
    switch (hdr->type) {
    case ICMP_TYPE_ECHO_REQUEST:
	/* ICMP code has to be 0 */
	if (hdr->code != 0) {
	    return;
	}
	
	call Leds.led2Toggle();
 	/* send back an ICMP ECHO REPLY */

	/* allocate a packet for the reply */
	pkt = call SendPktPool.get();
	if (!pkt) {
#ifdef ENABLE_PRINTF_DEBUG
	    printf("icmpv6_input() - failed to alloc pkt\n");
	    call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	    return;
	}
	lowpan_pkt_clear(pkt);
	
	/* copy/set ICMP data */
	if (rx_pkt.app_data) {
	    /* fragment reassembly took place - ICMP data is in app_data buf */
	    pkt->app_data = rx_pkt.app_data;
	    pkt->app_data_begin = buf;
	    pkt->app_data_len = len;
	    pkt->app_data_dealloc = rx_pkt.app_data_dealloc;

	    rx_pkt.app_data_dealloc = APP_DATA_DEALLOC_FALSE;
	    rx_pkt.app_data = NULL;
	} else {
	    /* there is no app_data buf, everything fits into the header buf */
	    pkt->header_begin -= len;
	    my_memcpy(pkt->header_begin, buf, len);
	    pkt->app_data_begin = pkt->header_begin;
	    pkt->app_data_len = len;
	}
	
	/* set destination address */
	memcpy(&pkt->ip_dst_addr, &rx_pkt.ip_src_addr,
	       sizeof(pkt->ip_dst_addr));
	// source address determined automatically

	icmpv6_output(pkt, ICMP_TYPE_ECHO_REPLY, 0);
	break;
    case ICMP_TYPE_ECHO_REPLY:
	break;
	
    }
}

/* UDP input processing. */
void udp_input(uint8_t* buf, uint16_t len)
{
    struct udp_conn *conn;
    int c;
    struct udp_hdr *hdr = (struct udp_hdr *)buf;
    
    /* Compute and check the IP header checksum. */
    if (ipv6_chksum_data(&rx_pkt.ip_src_addr, &rx_pkt.ip_dst_addr,
		    NEXT_HEADER_UDP, buf, len, 0)
	!= 0xffff) {
#ifdef ENABLE_PRINTF_DEBUG
	printf("udp_input(): checksum failed\n");
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	call Leds.led0Toggle();
	return;
    }

    if (htons(len) != hdr->len) {
#ifdef ENABLE_PRINTF_DEBUG
	printf("length check failed\n");
	printf("reported length: %d\n", len);
	printf("UDP header len: %d\n", ntohs(hdr->len));
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	return;
    }
    /* Scan the list of UDP sockets and look for one that is accepting
       this port */
    for (c = 0, conn = udp_conns; c < COUNT_UDP_CONNS; c++, conn++) {
	/*
	printf("lport: 0x%X\n", conn->lport);
	printf("rport: 0x%X\n", conn->rport);
	printf("conn->ripaddr: ");
	dump_serial_packet(&(conn->ripaddr), sizeof(ip6_addr_t));
	printf("src_addr: ");
	dump_serial_packet(src_addr, sizeof(ip6_addr_t));
	*/
	if ( (conn->lport != 0 && conn->lport == hdr->dstport) &&
	     (conn->rport == 0 || conn->rport == hdr->srcport) &&
	     (ipv6_addr_is_zero(&(conn->ripaddr)) ||
	      (cmp_ipv6_addr(&conn->ripaddr, &rx_pkt.ip_src_addr) == 0))
	     )
	    goto udp_match_found;
    }
#ifdef ENABLE_PRINTF_DEBUG
    printf("udp_input(): no connection matched - dropping UDP packet\n");
    call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
    return;
    
 udp_match_found:
    len -= sizeof(struct udp_hdr);
    if (len > 0) {
	signal UDPClient.receive[c](&rx_pkt.ip_src_addr, ntohs(hdr->srcport),
				    buf+sizeof(struct udp_hdr), len);
    }
}

void udp_input_compressed(uint8_t* buf, uint16_t len, uint8_t hc2_enc)
{
    struct udp_conn *conn;
    int c;
    uint16_t src_port;
    uint16_t dst_port;
    uint16_t chksum;
    uint16_t tmp_chksum;
    uint16_t tmp_len;
    
    /* UDP Source Port */
    if ((hc2_enc & HC2_UDP_SRC_PORT_MASK) == HC2_UDP_SRC_PORT_INLINE) {
	src_port = get_16t(buf);
	buf += sizeof(src_port);
	len -= sizeof(src_port);
    } else {
	//TODO
	return;
    }

    /* UDP Destination Port */
    if ((hc2_enc & HC2_UDP_DST_PORT_MASK) == HC2_UDP_DST_PORT_INLINE) {
	dst_port = get_16t(buf);
	buf += sizeof(dst_port);
	len -= sizeof(dst_port);
    } else {
	//TODO
	return;
    }

    /* UDP Length */
    if ((hc2_enc & HC2_UDP_LEN_MASK) == HC2_UDP_LEN_INLINE) {
	/* check the length */
	if (ntohs(get_16t(buf)) != len + sizeof(uint16_t)*2) {
#ifdef ENABLE_PRINTF_DEBUG
	    printf("length check failed\n");
	    printf("reported length: %d\n", len + sizeof(uint16_t)*2);
	    printf("UDP header len: %d\n", ntohs(get_16t(buf)));
	    call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	    return;
	}
	buf += sizeof(uint16_t);
	len -= sizeof(uint16_t);
    }
	
    /* Checksum */
    chksum = get_16t(buf);
    buf += sizeof(chksum);
    len -= sizeof(chksum);

    /* --- end of decompression --- */

    /* Compute and check the IP header checksum. */
    tmp_chksum = 0;
    /* IPv6 pseaudo header */
    tmp_chksum = ipv6_chksum(&rx_pkt.ip_src_addr, &rx_pkt.ip_dst_addr,
			     NEXT_HEADER_UDP,
			     /* len is only app data, so add UDP header
			      * length to get the length for chksum */
			     len + sizeof(struct udp_hdr),
			     tmp_chksum);
    /* UDP header */
    tmp_len = htons(len + sizeof(struct udp_hdr));
    tmp_chksum = ip_chksum((void*) &src_port, sizeof(src_port), tmp_chksum);
    tmp_chksum = ip_chksum((void*) &dst_port, sizeof(src_port), tmp_chksum);
    tmp_chksum = ip_chksum((void*) &chksum, sizeof(chksum), tmp_chksum);
    tmp_chksum = ip_chksum((void*) &tmp_len, sizeof(len), tmp_chksum);
    /* UDP payload - application data */
    tmp_chksum = ip_chksum(buf, len, tmp_chksum);

    if (tmp_chksum != 0xffff) {
#ifdef ENABLE_PRINTF_DEBUG
	printf("udp_input_compressed(): checksum failed\n");
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	call Leds.led0Toggle();
	return;
    }

//     printf("udp_input_compressed()\n");
//     printf("src_port: 0x%X\n", src_port);
//     printf("dst_port: 0x%X\n", dst_port);
//     printf("len (app_data): %d\n", len);
//     call PrintfFlush.flush();

    /* Scan the list of UDP sockets and look for one that is accepting
       this port */
    for (c = 0, conn = udp_conns; c < COUNT_UDP_CONNS; c++, conn++) {
	/*
	printf("lport: 0x%X\n", conn->lport);
	printf("rport: 0x%X\n", conn->rport);
	printf("conn->ripaddr: ");
	dump_serial_packet(&(conn->ripaddr), sizeof(ip6_addr_t));
	printf("src_addr: ");
	dump_serial_packet(&rx_pkt.ip_src_addr, sizeof(ip6_addr_t));
	*/
	if ( (conn->lport != 0 && conn->lport == dst_port) &&
	     (conn->rport == 0 || conn->rport == src_port) &&
	     (ipv6_addr_is_zero(&(conn->ripaddr)) ||
	      (cmp_ipv6_addr(&conn->ripaddr, &rx_pkt.ip_src_addr) == 0))
	     )
	    goto udp_match_found;
    }
#ifdef ENABLE_PRINTF_DEBUG
    printf("udp_input_compressed(): "\
	   "no connection matched - dropping UDP packet\n");
    call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
    return;
    
 udp_match_found:
    if (len > 0) {
	signal UDPClient.receive[c](&rx_pkt.ip_src_addr, ntohs(src_port),
				    buf, len);
    }
}

/* processed the IPv6 header (uncompressed) */
void ipv6_input_uncompressed(uint8_t* buf, uint16_t len)
{
    struct ip6_hdr *hdr = (struct ip6_hdr *) buf;

    /* check the version */
    if ((hdr->vtc & IPV6_VERSION_MASK) != 0x60) {
#ifdef ENABLE_PRINTF_DEBUG
	printf("IP version check failed (%X)\n",
	       hdr->vtc & IPV6_VERSION_MASK);
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	return;
    }
    
    /* Hop Limit */
    if (! hdr->hlim) {
	/* Hop Limit reached zero */
#ifdef ENABLE_PRINTF_DEBUG
	printf("Hop Limit reached zero\n");
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	return;
    }

    /* check dst IP address */
    if (! ipv6_addr_is_for_me(&hdr->dst_addr)) {
	return;
    }

    /* Check the size of the packet. If the size reported to us in
     * uip_len doesn't match the size reported in the IP header, there
     * has been a transmission error and we drop the packet.
     */
    if ( hdr->plen != htons(len - sizeof(struct ip6_hdr))) {
#ifdef ENABLE_PRINTF_DEBUG
	printf("length check failed\n");
	printf("l2 reported length: %d\n", len - sizeof(struct ip6_hdr));
	printf("IPv6 header plen: %d (network byte order: 0x%X\n",
	       ntohs(hdr->plen), hdr->plen);
	//((hdr->plen & 0xff00) >> 8) & ((hdr->plen & 0xff) << 8));
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	return;
    }
    
    /* copy IP addresses to rx_pkt */
    memcpy(&rx_pkt.ip_src_addr, &(hdr->src_addr), sizeof(rx_pkt.ip_src_addr));
    memcpy(&rx_pkt.ip_dst_addr, &(hdr->dst_addr), sizeof(rx_pkt.ip_dst_addr));

    /* multipex on next header */
    switch (hdr->nxt_hdr) {
    case NEXT_HEADER_ICMP6:
	icmpv6_input(buf + sizeof(struct ip6_hdr),
		     len - sizeof(struct ip6_hdr));
	break;
    case NEXT_HEADER_UDP:
	udp_input(buf + sizeof(struct ip6_hdr),
		  len - sizeof(struct ip6_hdr));
	break;
	/*
    case NEXT_HEADER_TCP:
	break;
	*/
    default:
#ifdef ENABLE_PRINTF_DEBUG
	printf("unknown IPv6 next header: 0x%X\n", hdr->nxt_hdr);
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	break;
    }
}

/* processed the IPv6 header (uncompressed) */
void ipv6_input_compressed(uint8_t* buf, uint16_t len)
{
    struct ip6_hdr *ip_hdr = (struct ip6_hdr *) buf;

    uint8_t hc1_enc;
    uint8_t hc2_enc = 0;
    uint8_t next_header;

    /*
    printf("nxt_hdr: 0x%X\n", hdr->nxt_hdr);
    dump_serial_packet(buf, len);
    call PrintfFlush.flush();
    */

    hc1_enc = *buf;
    buf += sizeof(hc1_enc);
    len -= sizeof(hc1_enc);

    /* HC2 encoding follows HC1 encoding */
    if ((hc1_enc & HC1_HC2_MASK) == HC1_HC2_PRESENT) {
	hc2_enc = *buf;
	buf += sizeof(hc2_enc);
	len -= sizeof(hc2_enc);
    }

    /* Hop Limit */
    if (*buf) {
	buf += sizeof(ip_hdr->hlim);
	len -= sizeof(ip_hdr->hlim);
    } else {
	/* Hop Limit reached zero */
	return;
    }

    /* source IP address */
    if ((hc1_enc & HC1_SRC_PREFIX_MASK) == HC1_SRC_PREFIX_INLINE) {
	memcpy(&rx_pkt.ip_src_addr, buf, sizeof(rx_pkt.ip_src_addr)/2);
	buf += sizeof(rx_pkt.ip_src_addr)/2;
	len -= sizeof(rx_pkt.ip_src_addr)/2;
    } else {
	/* linl-local prefix */
	memset(&rx_pkt.ip_src_addr, 0, sizeof(rx_pkt.ip_src_addr)/2);
	rx_pkt.ip_src_addr.addr[0] = 0xFE;
	rx_pkt.ip_src_addr.addr[1] = 0x80;
    }
     
    if ((hc1_enc & HC1_SRC_IFACEID_MASK) == HC1_SRC_IFACEID_INLINE) {
	memcpy(((void*)&rx_pkt.ip_src_addr) + sizeof(rx_pkt.ip_src_addr)/2,
	       buf, sizeof(rx_pkt.ip_src_addr)/2);
	buf += sizeof(rx_pkt.ip_src_addr)/2;
	len -= sizeof(rx_pkt.ip_src_addr)/2;
    }

    /* destination IP address */
    if ((hc1_enc & HC1_DST_PREFIX_MASK) == HC1_DST_PREFIX_INLINE) {
	memcpy(&rx_pkt.ip_dst_addr, buf, sizeof(rx_pkt.ip_dst_addr)/2);
	buf += sizeof(rx_pkt.ip_dst_addr)/2;
	len -= sizeof(rx_pkt.ip_dst_addr)/2;
    } else {
	/* linl-local prefix */
	memset(&rx_pkt.ip_dst_addr, 0, sizeof(rx_pkt.ip_dst_addr)/2);
	rx_pkt.ip_dst_addr.addr[0] = 0xFE;
	rx_pkt.ip_dst_addr.addr[1] = 0x80;
    }
     
    if ((hc1_enc & HC1_DST_IFACEID_MASK) == HC1_DST_IFACEID_INLINE) {
	memcpy(((void*)&rx_pkt.ip_dst_addr) + sizeof(rx_pkt.ip_dst_addr)/2,
	       buf, sizeof(rx_pkt.ip_dst_addr)/2);
	buf += sizeof(rx_pkt.ip_dst_addr)/2;
	len -= sizeof(rx_pkt.ip_dst_addr)/2;
    }

    /* check dst IP address */
    if (! ipv6_addr_is_for_me(&rx_pkt.ip_dst_addr)) {
	/*
	printf("IP address check failed\n");
	dump_serial_packet(hdr->dst_addr.addr, sizeof(hdr->dst_addr.addr));
	call PrintfFlush.flush();
	*/
	return;
    }

    /* Traffic Class and Flow Label */
    if ((hc1_enc & HC1_TCFL_MASK) == HC1_TCFL_INLINE) {
	//TODO
	return;
    }

    /* Next Header */
    switch (hc1_enc & HC1_NEXTHDR_MASK) {
    case HC1_NEXTHDR_INLINE:
	next_header = *buf;
	buf += sizeof(uint8_t);
	len -= sizeof(uint8_t);
	break;
    case HC1_NEXTHDR_UDP:
	next_header = NEXT_HEADER_UDP;
	break;
    case HC1_NEXTHDR_ICMP:
	next_header = NEXT_HEADER_ICMP6;
	break;
    case HC1_NEXTHDR_TCP:
	next_header = NEXT_HEADER_TCP;
	break;
    default:
#ifdef ENABLE_PRINTF_DEBUG
	printf("unknown next header HC1 encoding\n");
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	return;
    }
    
    /* multipex on the next header */
    switch (next_header) {
    case NEXT_HEADER_ICMP6:
	icmpv6_input(buf, len);
	break;
    case NEXT_HEADER_UDP:
	/* HC_UDP compression */
	if ((hc1_enc & HC1_HC2_MASK) == HC1_HC2_PRESENT
	    && (hc1_enc & HC1_NEXTHDR_MASK) == HC1_NEXTHDR_UDP) {
	    udp_input_compressed(buf, len, hc2_enc);
	    break;
	} else {
	    udp_input(buf, len);
	    break;
	}
	/*
    case NEXT_HEADER_TCP:
	break;
	*/
    default:
#ifdef ENABLE_PRINTF_DEBUG
	printf("unknown IPv6 next header: 0x%X\n", next_header);
	call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	break;
    }
}

/* call the right fct for processing the IPv6 header */
void layer3_input(uint8_t *buf, uint16_t len)
{
    uint8_t *dispatch = buf;
    buf++;
    len--;

    /* uncompressed IPv6 */
    if (*dispatch == DISPATCH_UNCOMPRESSED_IPV6) {
	ipv6_input_uncompressed(buf, len);
    }
    /* LOWPAN_HC1 compressed IPv6 */
    else if (*dispatch == DISPATCH_COMPRESSED_IPV6) {
	//call Leds.led1Toggle();
 	return ipv6_input_compressed(buf, len);
    }
    /* unknown dispatch value if we got here */
    else {
	//TODO: report an error
    }
}

/* process the optional 6lowpan headers */
void lowpan_input(uint8_t* buf, uint8_t len )
{
      uint8_t *dispatch;
      struct lowpan_broadcast_hdr *bc_hdr;
      struct lowpan_frag_hdr *frag_hdr;
      int i;

      frag_buf_t *frag;
      uint16_t dgram_tag;
      uint16_t dgram_size;
      uint8_t dgram_offset;
      frag_info_t *p;
      frag_info_t **q;
      uint8_t last_frag;

      dispatch = buf;
      /* --- 6lowpan optional headers --- */
      /* Mesh Addressing header */
      if ( (*dispatch & DISPATCH_MESH_MASK) == DISPATCH_MESH) {
	  // check if we're the final recipient in the mesh addressing header
	  buf++;
	  len--;

	  /* Hops Left */
	  if ((*dispatch & 0x0F) == 0) {
	      goto discard_packet;
	  }

	  /* Final Destination Address */
	  if (*dispatch & DISPATCH_MESH_F_FLAG) {
	      rx_pkt.hw_dst_addr.type = HW_ADDR_LONG;
	      memcpy(&rx_pkt.hw_dst_addr.addr_long, buf,
		     sizeof(rx_pkt.hw_dst_addr.addr_long));
	      buf += sizeof(rx_pkt.hw_dst_addr.addr_long);
	      len -= sizeof(rx_pkt.hw_dst_addr.addr_long);
	  } else {
	      rx_pkt.hw_dst_addr.type = HW_ADDR_SHORT;
	      memcpy(&rx_pkt.hw_dst_addr.addr_short, buf,
		     sizeof(rx_pkt.hw_dst_addr.addr_short));
	      buf += sizeof(rx_pkt.hw_dst_addr.addr_short);
	      len -= sizeof(rx_pkt.hw_dst_addr.addr_short);
	  }

	  /* check if we're the recipient */
	  if (! hw_addr_is_for_me(&rx_pkt.hw_dst_addr)) {
	      // TODO: if mesh forwarding enabled, then forward
	      goto discard_packet;
	  }

	  /* Originator Address */
	  if (*dispatch & DISPATCH_MESH_O_FLAG) {
	      rx_pkt.hw_src_addr.type = HW_ADDR_LONG;
	      memcpy(&rx_pkt.hw_src_addr.addr_long, buf,
		     sizeof(rx_pkt.hw_src_addr.addr_long));
	      buf += sizeof(rx_pkt.hw_src_addr.addr_long);
	      len -= sizeof(rx_pkt.hw_src_addr.addr_long);
	  } else {
	      rx_pkt.hw_src_addr.type = HW_ADDR_SHORT;
	      memcpy(rx_pkt.hw_src_addr.addr_short, buf,
		     sizeof(rx_pkt.hw_src_addr.addr_short));
	      buf += sizeof(rx_pkt.hw_src_addr.addr_short);
	      len -= sizeof(rx_pkt.hw_src_addr.addr_short);
	  }

	  dispatch = buf;
      }
      if (*dispatch == DISPATCH_BC0) { /* Broadcast header */
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
	  dgram_tag = get_16t(&frag_hdr->dgram_tag);
	  //dgram_size = get_16t(&frag_hdr->dgram_size);
	  //dgram_size &= htons(0x07FF);
	  dgram_size = frag_hdr->dgram_size8[1];
	  dgram_size += (frag_hdr->dgram_size8[0] & 0x07) << 8;
	  dgram_size = htons(dgram_size);
	  if ((*dispatch & DISPATCH_FRAG_MASK) == DISPATCH_SUBSEQ_FRAG) {
	      dgram_offset = *buf;
	      buf += 1;
	      len -= 1;
	  } else {
	      dgram_offset = 0;
	  }

#ifdef ENABLE_PRINTF_DEBUG
	  printf("off: %d\n", dgram_offset);
#endif /* ENABLE_PRINTF_DEBUG */
	  /*
	  printf("off: %d, f_b[%d] %d\n",
		 dgram_offset, 0, frag_bufs[0].frag_timeout);
	  */
	  frag = find_fragment(&rx_pkt.hw_src_addr, &rx_pkt.hw_dst_addr,
			       dgram_size, dgram_tag);
	  /*
	  if (frag) {
	      printf("frag found\n");
	  } else {
	      printf("frag NOT found\n");
	  }
	  */
	  if (frag) {
	      /* fragment reassembly buffer found */
	      /* check for overlap */
	      //TODO: ENABLE THIS PART !!!
// 	      for (p = frag->frag_list; p; p=p->next) {
// 		  if (dgram_offset == p->offset){
// 		      if (len == p->len) {
// 			  /* same offset, same len => discard this duplicate */
// 			  goto discard_packet;
// 		      } else {
// 			  /* same offset, but different len */
// 			  goto frag_overlap;
// 		      }
// 		  } else if (dgram_offset > p->offset
// 			     && dgram_offset < p->offset + p->len/8
// 			     ) {
// 		      /* offset inside another frag*/
// 		      goto frag_overlap;
// 		  }
// 	      }
	      /* no overlap found */
	      //printf("frag found: %d\n", frag->frag_timeout);
	      goto frag_reassemble;
	  } else {
	      /* fragment reassembly buffer not found - set up a new one */
	      // no match found -- need a new frag_buf_t
	      for (i = 0; i< FRAG_BUFS; i++) {
		  if (frag_bufs[i].frag_timeout == FRAG_FREE
		      && call AppDataPool.empty() == FALSE) {
		      frag = &frag_bufs[i];
		      set_16t(&frag->dgram_tag, get_16t(&frag_hdr->dgram_tag));
		      set_16t(&frag->dgram_size, dgram_size);
		      memcpy(&frag->hw_src_addr, &rx_pkt.hw_src_addr,
			     sizeof(frag->hw_src_addr));
		      memcpy(&frag->hw_dst_addr, &rx_pkt.hw_dst_addr,
			     sizeof(frag->hw_dst_addr));
		      frag->frag_timeout = FRAG_TIMEOUT;
		      frag->buf = (uint8_t *) call AppDataPool.get();
		      frag->frag_list = NULL;
		      /*
		      printf("new frag_buf[%d] %d\n", i,
			     frag_bufs[i].frag_timeout);
		      printf("frag pool size: %d\n", call FragInfoPool.size());
		      call PrintfFlush.flush();
		      */
		      goto frag_reassemble;
		  }
	      }
	      // no free slot for reassembling fragments
#ifdef ENABLE_PRINTF_DEBUG
	      printf("no free slot - discarding frag\n");
	      call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	      goto discard_packet;
	  }
	  
      frag_overlap:
	  /* overlap - discard previous frags
	   * and restart fragment reassembly
	   */
	  free_frag_list(frag->frag_list);
	  frag->frag_list = NULL;
	  frag->frag_timeout = FRAG_TIMEOUT;
	  goto frag_reassemble;
	  
      frag_reassemble:
	  /*
	  printf("tag: 0x%04X, size: %d, off: %d, t: %d\n",
		 get_16t(&frag->dgram_tag),
		 ntohs(get_16t(&frag->dgram_size)),
		 dgram_offset,
		 frag->frag_timeout);
	  //printf("f_b[%d] %d\n", 0, frag_bufs[0].frag_timeout);
	  if (dgram_offset > 0) {
	      call PrintfFlush.flush();
	  }
	  */
	  /* copy buf data */
	  //if (dgram_offset*8 + len <= sizeof(frag->buf)) {
	  if (dgram_offset*8 + len <= FRAG_BUF_SIZE) {
	      memcpy(frag->buf + (dgram_offset*8), buf, len);
	  } else {
	      call Leds.led0Toggle();
	  }
	  
	  /* update frag_info */
	  p = call FragInfoPool.get();
	  if (!p) {
	      //out of memory - fragment reassembly failing
	      //TODO
	      call Leds.led0Toggle();
#ifdef ENABLE_PRINTF_DEBUG
	      printf("FAILED to alloc frag_info_t\n");
	      call PrintfFlush.flush();
#endif /* ENABLE_PRINTF_DEBUG */
	  } else {
	      p->offset = dgram_offset;
	      p->len = len;
	      
	      /* insert frag_info into the orderer list */
	      if (frag->frag_list) {
		  for(q = &(frag->frag_list); (*q)->next; q=&((*q)->next)) {
		      if (p->offset > (*q)->offset) {
			  break;
		      }
		  }
		  p->next = *q;
		  *q = p;
	      } else {
		  p->next = frag->frag_list;
		  frag->frag_list = p;
	      }
	  }

#ifdef ENABLE_PRINTF_DEBUG
	  if (dgram_offset > 20) {
	      printf("frag_list:\n");
	      //ntohs(get_16t(&frag->dgram_tag)),
	      //ntohs(get_16t(&frag->dgram_size)));
	      for (p=frag->frag_list;p;p=p->next) {
		  printf("off: %d, len: %d\n", p->offset, p->len);
	      }
	      call PrintfFlush.flush();
	  }
#endif /* ENABLE_PRINTF_DEBUG */

	  /* check if this is not the last fragment */
	  if (!dgram_offset) {
	      /* the first fragment cannot be the last one */
	      last_frag = 0;
	  } else {
	      last_frag=1;
	      dgram_offset = ntohs(dgram_size)/8;
	      for(p=frag->frag_list; p && dgram_offset; p=p->next) {
		  //debug("dgram_offset: %d, p->offset: %d, p->len: %d\n",
		  //  dgram_offset, p->offset, p->len);
		  if (p->offset + p->len/8 != dgram_offset) {
		      //debug("offset mismatch - not the last fragment\n");
		      last_frag = 0;
		      break;
		  }
		    dgram_offset = p->offset;
	      }
	  }
	  
	  if (last_frag) {
	      call Leds.led1Toggle();
	      /* prepare the complete packet to be passed up*/
	      lowpan_pkt_clear(&rx_pkt);
	      rx_pkt.app_data = frag->buf;
	      rx_pkt.app_data_dealloc = APP_DATA_DEALLOC_TRUE;
	      rx_pkt.header_begin = frag->buf;
	      rx_pkt.header_len = ntohs(dgram_size);

	      //debug("dumping reassembled datagram...\n");
	      //dump_serial_packet(pkt->buf_begin, pkt->len);

	      /* pass up the packet */
	      layer3_input(rx_pkt.header_begin, rx_pkt.header_len);
	      
	      /* deallocate all fragment info */
	      free_frag_list(frag->frag_list);
	      frag->frag_list = NULL;
	      frag->frag_timeout = FRAG_FREE;
     	      if (rx_pkt.app_data_dealloc == APP_DATA_DEALLOC_TRUE
		  && rx_pkt.app_data) {
		  /* deallocate the frag_buf */
		  call AppDataPool.put((app_data_t *) rx_pkt.app_data);
	      }
	  } else {
	      /* packet not yet complete */
	      return;
	  }
	  dispatch = buf;
      } else {
	  /* no fragmentation */

	  /* pass up the complete packet */
	  lowpan_pkt_clear(&rx_pkt);
	  rx_pkt.header_begin = buf;
	  rx_pkt.header_len = len;
	  layer3_input(buf, len);
      }
      
      
 discard_packet:
      // deallocate pkt
      // update stats
}

/* Receive an AM from the lower layer */
event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
{
    am_addr_t am_addr;
    
    //call Leds.led0Toggle();
    
    /* 802.15.4 source address */
    rx_pkt.hw_src_addr.type = HW_ADDR_SHORT;
    am_addr = call AMPacket.source(msg);
    memcpy(&rx_pkt.hw_src_addr.addr_short, &am_addr, sizeof(am_addr_t));
    
    /* 802.15.4 destination address */
    rx_pkt.hw_dst_addr.type = HW_ADDR_SHORT;
    am_addr = call AMPacket.destination(msg);
    memcpy(&rx_pkt.hw_dst_addr.addr_short, &am_addr, sizeof(am_addr_t));
    
    lowpan_input(payload, len);
    return msg;
}

/******************************************
 *  Interface StdControl
 ******************************************/
  
command error_t IPControl.start() 
{
#ifdef ENABLE_PRINTF_DEBUG
    call PrintfControl.start();
#endif /* ENABLE_PRINTF_DEBUG */
    ip_init();
    linklocal_addr.addr[0] = 0xfe;
    linklocal_addr.addr[1] = 0x80;
    ipv6_iface_id_from_am_addr(call AMPacket.address(),
			       &(linklocal_addr.addr[8]));
    //set_16t((uint16_t *)&(linklocal_addr.addr[14]), am_addr);
    call MessageControl.start();
    return SUCCESS;
}

event void MessageControl.startDone(error_t err) {
    if (err == SUCCESS) {
	signal IPControl.startDone(err);
	call Timer.startPeriodic(1024); /* fire every second */
    }
    else {
	call MessageControl.start();
    }
}

command error_t IPControl.stop()
{
    call MessageControl.stop();
    call Timer.stop();      
#ifdef ENABLE_PRINTF_DEBUG
    call PrintfControl.stop();
#endif /* ENABLE_PRINTF_DEBUG */
    return SUCCESS;
}

event void MessageControl.stopDone(error_t err) {
    signal IPControl.stopDone(err);
}

/******************************************
 *  IP Interface
 ******************************************/
command void IP.getAddress(ip6_addr_t *addr)
{
    addr =  &global_addr;
    //uip_unpack_ipaddr( uip_global_addr, addr->addr );
}

command void IP.setAddress(const ip6_addr_t *addr)
{
    memcpy(&global_addr, addr, sizeof(*addr));
    //uip_pack_ipaddr(uip_global_addr,octet1,octet2,octet3,octet4);
}

command void IP.setAddressAutoconf(const ip6_addr_t *addr)
{
    memcpy(&global_addr, addr, sizeof(*addr));
    ipv6_iface_id_from_am_addr(call AMPacket.address(),
			       &(global_addr.addr[8]));
    //set_16t((uint16_t *)&(global_addr.addr[14]), am_addr);
}

/*****************************
 *  UDP functions
 *****************************/
command error_t UDPClient.listen[uint8_t num](uint16_t port)
{
    if (port) {
	memset(&udp_conns[num].ripaddr, 0,
	       sizeof(udp_conns[num].ripaddr));
	set_16t(&udp_conns[num].lport, htons(port));
    } else {
	set_16t(&udp_conns[num].lport, 0);
    }
    return SUCCESS;
}

command error_t
UDPClient.connect[uint8_t num](const ip6_addr_t *addr, const uint16_t port)
{
    struct udp_conn *conn = &udp_conns[num];
    
    if (addr && port) {
	memcpy(&conn->ripaddr, addr, sizeof(conn->ripaddr));
	set_16t(&conn->rport, htons(port));
    }
    else {
	memset(&conn->ripaddr, 0 , sizeof(conn->ripaddr));
	set_16t(&conn->rport, 0);
    }

    return SUCCESS;
}

command error_t
UDPClient.sendTo[uint8_t num](const ip6_addr_t *addr, uint16_t port,
			      const uint8_t *buf, uint16_t len)
{
    if (udp_conns[num].lport == 0) {
	set_16t(&udp_conns[num].lport, htons(udp_assign_port()));
    }
    return udp_compressed_output(buf, len,
				 NULL, addr,
				 udp_conns[num].lport, htons(port), num+1);
}

command error_t UDPClient.send[uint8_t num]( const uint8_t *buf, uint16_t len )
{
    if (udp_conns[num].rport == 0
	|| ipv6_addr_is_zero(&udp_conns[num].ripaddr))
	return FAIL;
    return call UDPClient.sendTo[num](&(udp_conns[num].ripaddr),
				      udp_conns[num].rport,
				      buf, len);
}

default event void
UDPClient.sendDone[uint8_t num](error_t result, void* buf)
{
}

default event void
UDPClient.receive[uint8_t num](const ip6_addr_t *addr, uint16_t port, 
			       uint8_t *buf, uint16_t len)
{
}

/******************************************
 *  Printf Timer
 ******************************************/
#ifdef ENABLE_PRINTF_DEBUG
event void PrintfFlush.flushDone(error_t error) {}
event void PrintfControl.startDone(error_t error) {}
event void PrintfControl.stopDone(error_t error) {}
static void dump_serial_packet(const unsigned char *packet, const int len)
{
    int i;
    printf("len: %d\n", len);
    //call PrintfFlush.flush();
    if (!packet) {
	printf("packet is NULL");
    } else {
	for (i = 0; i < len; i++)
	    printf("%02x ", packet[i]);
    }
    printf("\n");
    //call PrintfFlush.flush();
}
#endif /* ENABLE_PRINTF_DEBUG */
#ifndef ENABLE_PRINTF_DEBUG
static void dump_serial_packet(const unsigned char *packet, const int len)
{}
#endif /* ENABLE_PRINTF_DEBUG */

/******************************************
 *  Interface Timer
 ******************************************/

event void Timer.fired() {
    int i=0;

    /* heartbeat led */
    //call Leds.led0Toggle();
    
    /* discard timed-out and not yet assembled fragmented packet */
    for (i=0;i<FRAG_BUFS; i++) {
	if (frag_bufs[i].frag_timeout != FRAG_FREE) {
	    if (frag_bufs[i].frag_timeout > 0) {
		frag_bufs[i].frag_timeout--;
	    } else {
		/* fragment reassembly timed out */
		frag_bufs[i].frag_timeout = FRAG_FREE;
		free_frag_list(frag_bufs[i].frag_list);
		if (frag_bufs[i].buf) {
		    call AppDataPool.put((app_data_t *) frag_bufs[i].buf);
		}
		//call Leds.led0Toggle();
	    }
	}
    }
    
    //TODO: check for timed-out ND request and resend/give up and mark as such
    //TODO: check outgoing pkts queue and schedule ND or sending
    /*
      counter++;
      if (locked) {
      return;
      }
      else {
      //Packet.clear(&test_packet);
      uint8_t* data=(uint8_t*) call Packet.getPayload(&test_packet,NULL);
      if (call Packet.maxPayloadLength() < 1) {
      return;
      }
      
      data[0] = counter;
      call AMPacket.setSource(&test_packet, 0x14);
      if (call AMSend.send(3, &test_packet, 1) == SUCCESS) {
      //      if (call AMSend.send(AM_BROADCAST_ADDR, &test_packet, sizeof(test_serial_msg_t)) == SUCCESS) {
      locked = TRUE;
      }
      }
    */
}

}
