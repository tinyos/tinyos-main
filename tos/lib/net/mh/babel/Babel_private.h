/*
 * Copyright (c) 2012 Martin Cerveny
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Private headers.
 * 
 * @author Martin Cerveny
 */ 
 
#ifndef BABEL_PRIVATE_H
#define BABEL_PRIVATE_H

#include "IeeeEui64.h"

enum {
	AM_BABEL = (0x80 + 80)
};

// ------------------------------- PROTOCOL CONSTANTS

#define BABEL_PAD1 0 // 4.4.1.  Pad1
#define BABEL_PADN 1 // 4.4.2.  PadN
#define BABEL_ACK_REQ 2 //  4.4.3.  Acknowledgement Request
#define BABEL_ACK 3 //  4.4.4.  Acknowledgement
#define BABEL_HELLO 4 // 4.4.5.  Hello
#define BABEL_IHU 5 // 4.4.6.  IHU ("I Heard You")
#define BABEL_ROUTER_ID 6 // 4.4.7.  Router-Id
#define BABEL_NH 7 // ? 4.4.8.  Next Hop
#define BABEL_UPDATE 8 // 4.4.9.  Update
#define BABEL_RT_REQUEST 9 // 4.4.10.  Route Request
#define BABEL_SQ_REQUEST 10 // 4.4.11.  Seqno Request

#define BABEL_AE_WILD 0 // AE 0: wildcard address.  The value is 0 octets long.
#define BABEL_AE_INET4 1 // AE 1: IPv4 address.  Compression is allowed. 4 octets or less.
#define BABEL_AE_INET6 2 // AE 2: IPv6 address.  Compression is allowed. 16 octets or less.
#define BABEL_AE_INET6_LOCAL // AE 3: link-local IPv6 address.  The value is 8 octets long, a prefix of fe80::/64 is implied.
#define BABEL_AE_AM 63 // AE 63: ActiveMessage address (short 802.15.4 address). No compression.  The value is 2 octets.

#define BABEL_UNDEF 0
#define BABEL_INFINITY 0xffff

#define BABEL_NODEID_UNDEF 0xffff

#define BABEL_NOT_FOUND 0xff

#define BABEL_PLEN 16 // flat routing without prefix, equals to "nodeid" size
#define BABEL_OMITTED 0 // unsupported update compression
#define BABEL_FLAGS 0 // unsupported compression and route id

#define BABEL_RT_WILD 0xffff // wildcard for all route table update (BABEL_AE_WILD is send)

#define BABEL_SEQNO_GRATER 0x1000 // grater but not sequence lost (1/16 in  modulo)

#define BABEL_FLAG_UPDATE 0x01 // pending route update request to send (or periodic update) (flag reset by update send)
#define BABEL_FLAG_SQ_REQEST 0x02 // pending seqno request (flag reset by sq request send or received update with geater seqno)
#define BABEL_FLAG_RT_REQUEST 0x04 // pending rt request (lost neigbor) (flag reset by rt request send or received update for nexthop_nodeid)
#define BABEL_FLAG_UNFEASIBLE 0x08 // at least one unfeasible route received (prepare pro sq request) (reset by known update received) 
#define BABEL_FLAG_RT_SWITCH 0x10 // try to switch next
#define BABEL_FLAG_RETRACTION 0x20 // route retraction

#define BABEL_PENDING_HELLO 0x01 // pending hello, ihu, periodic route update trigger
#define BABEL_PENDING_ACK 0x02 // pending ack response
#define BABEL_PENDING_UPDATE 0x04 // pending update to send
#define BABEL_PENDING_SQ_REQUEST 0x08 // pending forward of seqno request
#define BABEL_PENDING_RT_REQUEST 0x10 // pending request for update 
#define BABEL_PENDING_RT_REQUEST_WILD 0x20 // pending request for wild update
#define BABEL_ADDR_CHANGED 0x40 // address change, drop all routing table and inform all

// ------------------------------- STRUCTS

typedef struct NetDB {
	// 3.2.4.  The Source Table 	
	am_addr_t dest_nodeid; // destination nodeid
	ieee_eui64_t eui; // destination EUI
	uint16_t seqno; // the sequence number with which this route was advertised
	
	// 3.2.6. The Table of Pending Requests
	uint16_t pending_seqno; // pending seqno
	uint8_t pending_timer; // retries reminding (BABEL_SQ_RETRY_INTERVAL*BABEL_SQ_RETRY)
	uint8_t pending_hopcount; // hopcount reminding
	
	// 3.2.5.  The Route Table
	uint16_t metric; // the metric of this route
	am_addr_t nexthop_nodeid; // the next-hop address of this route
	
	uint8_t flags; // various flags
	uint16_t timer;	// 
} NetDB;

typedef struct NeighborDB {
	// 3.2.3.  The Neighbor Table
	am_addr_t neigh_nodeid; // neighbor node id
	uint16_t hello_history; // bitfield of received(1)/missing(0) past hellos 
	uint16_t hello_seqno; // expected hello sequence received from remote node
	uint16_t hello_timer; // local decrementing timer of expected next hello message (first 2*hello_interval, next hello_interval)
	uint16_t hello_interval; // advertised hello interval received from remote node
	uint16_t ihu_tx_cost; // forward tx cost learned from ihu received from remote node
	uint16_t ihu_timer; // local decrementing timer of expiration of ihu data (BABEL_IHU_THRESHOLD*received ihu_interval)
	uint8_t lqi; // receiving lqi
	uint8_t rssi; // receiving rssi
} NeighborDB;

typedef struct AckDB {
	// used for send responses
	uint16_t nodeid; // remote node id
	uint16_t nonce; // ack nonce
} AckDB;

// ------------------------------- READ

// b - pointer to begin of message
// a - actual processing pointer
// len - received message length

#define BABEL_COMPARE(a,t,v) (a+=sizeof(t), (*((t *)(a-sizeof(t))) == (v)))
#define BABEL_CHECKLEN(b,a,len) ((*(nx_uint8_t *)a<=len-(a-b)-1 ))
#define BABEL_SKIP(a,t) (a+=sizeof(t))
#define BABEL_SKIPBACK(a,t) (a-=sizeof(t))
#define BABEL_GET(a,t,v) (v=*((t *)a), a+=sizeof(t))

#define BABEL_READ_MSG_BEGIN(b,a,len) \
(BABEL_COMPARE(a,nx_uint8_t,42) && \
BABEL_COMPARE(a,nx_uint8_t,2) && \
BABEL_COMPARE(a,nx_uint16_t,len-(sizeof(nx_uint8_t)*2+sizeof(nx_uint16_t))))

#define BABEL_READ_MSG_END(b,a,len) \
(len==(a-b))

#define BABEL_READ_MSG_PAD1(b,a,len) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_PAD1))

#define BABEL_READ_MSG_PADN(b,a,len) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_PADN) && \
BABEL_CHECKLEN(b,a,len) && \
(a+=*(nx_uint8_t * )a, \
TRUE))

#define BABEL_READ_MSG_ACK_REQ(b,a,len,nonce,interval) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_ACK_REQ) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,6) && \
(BABEL_SKIP(a, nx_uint16_t), \
BABEL_GET(a, nx_uint16_t, nonce), \
BABEL_GET(a, nx_uint16_t, interval), \
TRUE))

#define BABEL_READ_MSG_ACK(b,a,len,nonce) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_ACK) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,2) && \
(BABEL_GET(a, nx_uint16_t, nonce), \
TRUE))

#define BABEL_READ_MSG_HELLO(b,a,len,seqno,interval) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_HELLO) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,6) && \
(BABEL_SKIP(a, nx_uint16_t), \
BABEL_GET(a, nx_uint16_t, seqno), \
BABEL_GET(a, nx_uint16_t, interval), \
TRUE))

#define BABEL_READ_MSG_IHU(b,a,len,cost,interval,neigh_addr) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_IHU) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,8) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_AE_AM) && \
(BABEL_SKIP(a, nx_uint8_t), \
BABEL_GET(a, nx_uint16_t, cost), \
BABEL_GET(a, nx_uint16_t, interval), \
BABEL_GET(a, nx_am_addr_t, neigh_addr), \
TRUE))

#define BABEL_READ_MSG_ROUTER_ID(b,a,len,eui) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_ROUTER_ID) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,10) && \
(sizeof(eui) == sizeof(nx_uint64_t)) && \
(BABEL_SKIP(a, nx_uint16_t), \
BABEL_GET(a, nx_uint64_t, (*(uint64_t *)&eui)), \
TRUE))

#define BABEL_READ_MSG_NH(b,a,len,nexthop_addr) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_NH) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,4) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_AE_AM) && \
(BABEL_SKIP(a, nx_uint8_t), \
BABEL_GET(a, nx_am_addr_t, nexthop_addr), \
TRUE))

#define BABEL_READ_MSG_UPDATE(b,a,len,interval,seqno,metric,dest_addr) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_UPDATE) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,12) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_AE_AM) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_FLAGS) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_PLEN) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_OMITTED) && \
(BABEL_GET(a, nx_uint16_t, interval), \
BABEL_GET(a, nx_uint16_t, seqno), \
BABEL_GET(a, nx_uint16_t, metric), \
BABEL_GET(a, nx_am_addr_t, dest_addr), \
TRUE))

#define BABEL_READ_MSG_RT_REQUEST(b,a,len,dest_addr) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_RT_REQUEST) && \
BABEL_CHECKLEN(b,a,len) && \
(BABEL_COMPARE(a,nx_uint8_t,4)? \
BABEL_COMPARE(a,nx_uint8_t,BABEL_AE_AM) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_PLEN) && \
(BABEL_GET(a, nx_am_addr_t, dest_addr), \
TRUE) : \
(BABEL_SKIPBACK(a,nx_uint8_t), TRUE ) && \
BABEL_COMPARE(a,nx_uint8_t,2) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_AE_WILD) && \
BABEL_COMPARE(a,nx_uint8_t,0) && \
( dest_addr=BABEL_RT_WILD, \
TRUE )))

#define BABEL_READ_MSG_SQ_REQUEST(b,a,len,seqno,hopcount,eui,dest_addr) \
(BABEL_COMPARE(a,nx_uint8_t,BABEL_SQ_REQUEST) && \
BABEL_CHECKLEN(b,a,len) && \
BABEL_COMPARE(a,nx_uint8_t,16) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_AE_AM) && \
BABEL_COMPARE(a,nx_uint8_t,BABEL_PLEN) && \
(BABEL_GET(a, nx_uint16_t, seqno), \
BABEL_GET(a, nx_uint8_t, hopcount), \
BABEL_SKIP(a, nx_uint8_t), \
BABEL_GET(a, nx_uint64_t, *(uint64_t *)&eui), \
BABEL_GET(a, nx_am_addr_t, dest_addr), \
TRUE))

#define BABEL_READ_MSG_UNKNOWN(b,a,len) \
((BABEL_SKIP(a, nx_uint8_t), TRUE) && \
BABEL_CHECKLEN(b,a,len) && \
(a+=*(nx_uint8_t * )a, \
TRUE))

// ------------------------------- WRITE

// b - pointer to begin of message
// a - actual processing pointer

#define BABEL_SET(a,t,v) (*((t *)a) = (v), a+=sizeof(t))

#define BABEL_WRITE_MSG_BEGIN(b,a) \
( BABEL_SET(a, nx_uint8_t, 42), \
BABEL_SET(a, nx_uint8_t, 2), \
BABEL_SET(a, nx_uint16_t, BABEL_UNDEF))

#define BABEL_WRITE_MSG_END(b,a) \
((a - b < BABEL_WRITE_MSG_MAX) ? \
*((nx_uint16_t * ) (b+sizeof(uint8_t)*2))=a-b-(sizeof(nx_uint8_t)*2+sizeof(nx_uint16_t)), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_PAD1(b,a) \
(((a + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_PAD1), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_PADN(b,a,n) \
(((a + n + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_PADN), \
BABEL_SET(a, nx_uint8_t, n), \
memset(a, BABEL_UNDEF, n), \
a+=n, \
TRUE : FALSE)

#define BABEL_WRITE_MSG_ACK_REQ(b,a,nonce,interval) \
(((a + 6 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_ACK_REQ), \
BABEL_SET(a, nx_uint8_t, 6), \
BABEL_SET(a, nx_uint16_t, BABEL_UNDEF), \
BABEL_SET(a, nx_uint16_t, nonce), \
BABEL_SET(a, nx_uint16_t, interval), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_ACK(b,a,nonce) \
(((a + 2 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_ACK), \
BABEL_SET(a, nx_uint8_t, 2), \
BABEL_SET(a, nx_uint16_t, nonce), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_HELLO(b,a,seqno,interval) \
(((a + 6 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_HELLO), \
BABEL_SET(a, nx_uint8_t, 6), \
BABEL_SET(a, nx_uint16_t, BABEL_UNDEF), \
BABEL_SET(a, nx_uint16_t, seqno), \
BABEL_SET(a, nx_uint16_t, interval), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_IHU(b,a,rxcost,interval,neigh_addr) \
(((a + 8 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_IHU), \
BABEL_SET(a, nx_uint8_t, 8), \
BABEL_SET(a, nx_uint8_t, BABEL_AE_AM), \
BABEL_SET(a, nx_uint8_t, BABEL_UNDEF), \
BABEL_SET(a, nx_uint16_t, rxcost), \
BABEL_SET(a, nx_uint16_t, interval), \
BABEL_SET(a, nx_am_addr_t, neigh_addr), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_ROUTER_ID(b,a,eui) \
(((a + 10 + 2) - b < BABEL_WRITE_MSG_MAX && \
(sizeof(eui) == sizeof(nx_uint64_t))) ? \
BABEL_SET(a, nx_uint8_t, BABEL_ROUTER_ID), \
BABEL_SET(a, nx_uint8_t, 10), \
BABEL_SET(a, nx_uint16_t, BABEL_UNDEF), \
BABEL_SET(a, nx_uint64_t, *(uint64_t *)&eui), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_NH(b,a,nexthop_addr) \
(((a + 4 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_NH), \
BABEL_SET(a, nx_uint8_t, 4), \
BABEL_SET(a, nx_uint8_t, BABEL_AE_AM), \
BABEL_SET(a, nx_uint8_t, BABEL_UNDEF), \
BABEL_SET(a, nx_am_addr_t, nexthop_addr), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_UPDATE(b,a,interval,seqno,metric,dest_addr) \
(((a + 12 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_UPDATE), \
BABEL_SET(a, nx_uint8_t, 12), \
BABEL_SET(a, nx_uint8_t, BABEL_AE_AM), \
BABEL_SET(a, nx_uint8_t, BABEL_FLAGS), \
BABEL_SET(a, nx_uint8_t, BABEL_PLEN), \
BABEL_SET(a, nx_uint8_t, BABEL_OMITTED), \
BABEL_SET(a, nx_uint16_t, interval), \
BABEL_SET(a, nx_uint16_t, seqno), \
BABEL_SET(a, nx_uint16_t, metric), \
BABEL_SET(a, nx_am_addr_t, dest_addr), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_RT_REQUEST(b,a,dest_addr) \
(((a + (dest_addr==BABEL_RT_WILD?2:4) + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_RT_REQUEST), \
BABEL_SET(a, nx_uint8_t, (dest_addr==BABEL_RT_WILD?2:4)), \
BABEL_SET(a, nx_uint8_t, (dest_addr==BABEL_RT_WILD?BABEL_AE_WILD:BABEL_AE_AM)), \
BABEL_SET(a, nx_uint8_t, (dest_addr==BABEL_RT_WILD?0:BABEL_PLEN)), \
(dest_addr==BABEL_RT_WILD?0:BABEL_SET(a, nx_am_addr_t, dest_addr)), \
TRUE : FALSE)

#define BABEL_WRITE_MSG_SQ_REQUEST(b,a,seqno,hopcount,eui,dest_addr) \
(((a + 16 + 2) - b < BABEL_WRITE_MSG_MAX) ? \
BABEL_SET(a, nx_uint8_t, BABEL_SQ_REQUEST), \
BABEL_SET(a, nx_uint8_t, 16), \
BABEL_SET(a, nx_uint8_t, BABEL_AE_AM), \
BABEL_SET(a, nx_uint8_t, BABEL_PLEN), \
BABEL_SET(a, nx_uint16_t, seqno), \
BABEL_SET(a, nx_uint8_t, hopcount), \
BABEL_SET(a, nx_uint8_t, BABEL_UNDEF), \
BABEL_SET(a, nx_uint64_t, *(uint64_t *)&eui), \
BABEL_SET(a, nx_am_addr_t, dest_addr), \
TRUE : FALSE)

#endif /* BABEL_PRIVATE_H */
