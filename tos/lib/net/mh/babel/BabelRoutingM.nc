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
 * The Babel routing protocol implementation module.
 * Handles send and receive Babel protocol messages.
 * Implements "am_address" collision detection and renumbering.
 *
 * @author Martin Cerveny
 */

#include "Timer.h"
#include "MH.h"
#include "Babel.h"
#include "Babel_private.h"

#include "printfsyslog.h"

// define facilities and define facilities name

// BASIC facility - generic facility
#define BABEL_BASIC_FACILITY (1<<0)
#define BABEL_BASIC_NAME ""
// SEND facility - prepare and send BABEL messages
#define BABEL_SEND_FACILITY (1<<1)
#define BABEL_SEND_NAME "S"
// RECEIVE facility - receive nad process BABEL messages
#define BABEL_RECEIVE_FACILITY (1<<2)
#define BABEL_RECEIVE_NAME "R"
// ROUTE facility - route decision procees (called from MultiHop/RouteSelect)
#define BABEL_ROUTE_FACILITY (1<<3)
#define BABEL_ROUTE_NAME "R"
// TIMER facility - timer processing (regular updates and timeout)
#define BABEL_TIMER_FACILITY (1<<4)
#define BABEL_TIMER_NAME "T"

// define severity filter per facility and define facility filter mask

#define BABEL_BASIC_SEVERITY LOG_DEBUG
#define BABEL_SEND_SEVERITY LOG_DEBUG
#define BABEL_RECEIVE_SEVERITY LOG_DEBUG
#define BABEL_ROUTE_SEVERITY LOG_DEBUG
#define BABEL_TIMER_SEVERITY LOG_DEBUG

//#define BABEL_FACILITY_MASK (BABEL_BASIC_FACILITY | BABEL_SEND_FACILITY | BABEL_RECEIVE_FACILITY | BABEL_ROUTE_FACILITY | BABEL_TIMER_FACILITY)
#define BABEL_FACILITY_MASK (BABEL_BASIC_FACILITY | BABEL_ROUTE_FACILITY | BABEL_TIMER_FACILITY)
//#define BABEL_FACILITY_MASK (0)

// local macros

#define BABEL_D(facility, ...) prinfsyslog(BABEL, BABEL_ ## facility, LOG_DEBUG, __VA_ARGS__)
#define BABEL_D_inline(facility, ...) prinfsyslog_inline(BABEL, BABEL_ ## facility, LOG_DEBUG, __VA_ARGS__)
#define BABEL_D_flush(facility) prinfsyslog_flush(BABEL, BABEL_ ## facility, LOG_DEBUG)
#define BABEL_E(facility, ...) prinfsyslog(BABEL, BABEL_ ## facility, LOG_ERR, __VA_ARGS__)
#define BABEL_E_flush(facility) prinfsyslog_flush(BABEL, BABEL_ ## facility, LOG_ERR)
#define BABEL_N(facility, ...) prinfsyslog(BABEL, BABEL_ ## facility, LOG_NOTICE, __VA_ARGS__)

module BabelRoutingM {
	// export
	provides interface RouteSelect;

	provides interface TableReader as NeighborTable;
	provides interface TableReader as RoutingTable;

	uses interface Timer<TMilli> as Timer;
	uses interface Boot;
	uses interface LocalIeeeEui64;

	// L2
	uses interface Packet;
	uses interface AMPacket;

	uses interface AMSend;
	uses interface Receive;

	uses interface SplitControl as AMControl;
	uses interface PacketField<uint8_t> as PacketRSSI;
	uses interface PacketField<uint8_t> as PacketLinkQuality;
	uses interface ActiveMessageAddress;

	// L3
	uses interface Packet as L3Packet;
	uses interface AMPacket as L3AMPacket;

	uses interface Leds;
	uses interface Timer<TMilli> as TimerLed;
}
implementation {
	// global state and tables

	NetDB ndb[BABEL_NDB_SIZE]; // sorted by dest_nodeid
	uint8_t cnt_ndb = 0; // size of ndb
	uint8_t self; // my position in ndb
	NeighborDB neighdb[BABEL_NEIGHDB_SIZE]; // sorted by neigh_nodeid
	uint8_t cnt_neighdb = 0; // size of neighdb
	AckDB ackdb[BABEL_ACKDB_SIZE]; // FIFO
	uint8_t cnt_ackdb = 0; // size of ackdb

	// local state

	uint16_t hello_seqno = 0;
	uint16_t hello_interval = BABEL_HELLO_INTERVAL / 8;
	uint16_t hello_timer = BABEL_HELLO_INTERVAL / 8;

	uint16_t nonce = 0;

	uint8_t pending;

	uint8_t wait_cnt = 0;

	// packet for sending BABEL messages

	bool busy = FALSE;
	message_t pkt;

	// Initialization and support function

	event void Boot.booted() {

		self = 0;
		cnt_ndb++;
		memset(&ndb[self], 0, sizeof(ndb[0]));
		ndb[self].dest_nodeid = call ActiveMessageAddress.amAddress();
		ndb[self].eui = call LocalIeeeEui64.getId();
		ndb[self].flags |= BABEL_FLAG_UPDATE;
		pending |= BABEL_PENDING_HELLO | BABEL_PENDING_UPDATE | BABEL_PENDING_RT_REQUEST_WILD;

		call AMControl.start();
	}

	uint8_t getLqi(message_t * msg) {
		if(call PacketLinkQuality.isSet(msg))
			return call PacketLinkQuality.get(msg);
		else
			return 0;
	}

	uint8_t getRssi(message_t * msg) {
		if(call PacketRSSI.isSet(msg))
			return call PacketRSSI.get(msg);
		else
			return 0;
	}

	void send();

	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
			call Timer.startPeriodic(10);
			// first send delayed (addr change)
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	uint16_t seqnodiff(uint16_t seqnew, uint16_t seqold) {
		if(seqnew > seqold)
			return seqnew - seqold;
		else
			return seqnew + (~ seqold);
	}

	bool seqnograter(uint16_t seqnew, uint16_t seqold, uint16_t maxdiff) {
		uint16_t sq = seqnodiff(seqnew, seqold);
		return(sq > 0)&&(sq < maxdiff);
	}

	uint16_t linkcost(uint16_t hello_history) {
		uint16_t cost = BABEL_LINK_COST * (0x8000 / (((hello_history & 0x8000) >> 2) + ((hello_history & 0x4000) >> 1) + (hello_history & 0x3fff) + 1));
		if(cost > 0x0fff)
			cost = BABEL_INFINITY;
		return cost;
	}

	// database ndb function

	bool insert_ndb(NetDB * data) {
		uint8_t b = 0, e = cnt_ndb, m = 0;

		if(cnt_ndb == (sizeof(ndb) / sizeof(ndb[0])))
			return FALSE;

		while(e > b) {
			m = (b + e) / 2;
			if(ndb[m].dest_nodeid > data->dest_nodeid)
				e = m;
			else
				b = m + 1;
		}

		if(self >= b)
			self++;
		memmove(&ndb[b + 1], &ndb[b], sizeof(ndb[0]) * (cnt_ndb - b));
		memcpy(&ndb[b], data, sizeof(ndb[0]));
		cnt_ndb++;
		return TRUE;
	}

	void remove_ndb(uint8_t idx) {
		memmove(&ndb[idx], &ndb[idx + 1], sizeof(ndb[0]) * (cnt_ndb - idx - 1));
		if(self > idx)
			self--;
		cnt_ndb--;
	}

	uint8_t search_ndb(am_addr_t nodeid) {
		uint8_t b = 0, e = cnt_ndb;

		while(e > b) {
			uint8_t m = (b + e) / 2;

			if(ndb[m].dest_nodeid == nodeid)
				return m;
			if(ndb[m].dest_nodeid > nodeid)
				e = m;
			else
				b = m + 1;
		}
		return BABEL_NOT_FOUND;
	}

	// database neighdb function

	bool insert_neighdb(NeighborDB * data) {
		uint8_t b = 0, e = cnt_neighdb, m = 0;

		if(cnt_neighdb == (sizeof(neighdb) / sizeof(neighdb[0])))
			return FALSE;

		while(e > b) {
			m = (b + e) / 2;
			if(neighdb[m].neigh_nodeid > data->neigh_nodeid)
				e = m;
			else
				b = m + 1;
		}

		memmove(&neighdb[b + 1], &neighdb[b], sizeof(neighdb[0]) * (cnt_neighdb - b));
		memcpy(&neighdb[b], data, sizeof(neighdb[0]));
		cnt_neighdb++;
		return TRUE;
	}

	void remove_neighdb(uint8_t idx) {
		memmove(&neighdb[idx], &neighdb[idx + 1], sizeof(neighdb[0]) * (cnt_neighdb - idx - 1));
		cnt_neighdb--;
	}

	uint8_t search_neighdb(am_addr_t nodeid) {
		uint8_t b = 0, e = cnt_neighdb;

		while(e > b) {
			uint8_t m = (b + e) / 2;

			if(neighdb[m].neigh_nodeid == nodeid)
				return m;
			if(neighdb[m].neigh_nodeid > nodeid)
				e = m;
			else
				b = m + 1;
		}
		return BABEL_NOT_FOUND;
	}

	// compute metric for BABEL

	uint16_t metric(uint16_t m, uint16_t nexthop_nodeid) {
		uint8_t idx;
		uint16_t rx_cost, tx_cost;
		uint32_t etx;

		if(m == BABEL_INFINITY)
			return BABEL_INFINITY;
		idx = search_neighdb(nexthop_nodeid);
		if(idx == BABEL_NOT_FOUND)
			return BABEL_INFINITY;
		tx_cost = neighdb[idx].ihu_tx_cost;
		if(tx_cost == BABEL_INFINITY)
			return BABEL_INFINITY;
		rx_cost = linkcost(neighdb[idx].hello_history);
		if(rx_cost == BABEL_INFINITY)
			return BABEL_INFINITY;
		etx = (uint32_t) tx_cost * rx_cost;
		if(etx >= BABEL_INFINITY)
			return BABEL_INFINITY;
		return m + etx + BABEL_RT_COST;
	}

	// process one "send" request (check variable pending)

	void send() {
		if(( ! busy)&&(pending)) {
			void * bptr, *aptr;
			uint8_t i;

			aptr = bptr = call Packet.getPayload(&pkt, BABEL_WRITE_MSG_MAX);
			if(bptr) {
				uint16_t destaddr;

				BABEL_WRITE_MSG_BEGIN(bptr, aptr);
				BABEL_D(SEND, "txbegin == ");

				if(ndb[self].dest_nodeid != call ActiveMessageAddress.amAddress()) {
					BABEL_D_inline(SEND, "nh - L2=%04X DB=%04X - ", call ActiveMessageAddress.amAddress(), ndb[self].dest_nodeid);
					BABEL_WRITE_MSG_NH(bptr, aptr, ndb[self].dest_nodeid);
				}

				if(pending & BABEL_PENDING_ACK) {
					// pending ack response (unicast send)
					// TODO: unused/untested				
					BABEL_D_inline(SEND, "ack - ");
					if(cnt_ackdb) {
						destaddr = ackdb[0].nodeid;

						BABEL_WRITE_MSG_ACK(bptr, aptr, ackdb[0].nonce);
						memmove(&ackdb[0], &ackdb[1], sizeof(ackdb[0]) * (cnt_ackdb - 1));
						if( ! (--cnt_ackdb))
							pending &= ~BABEL_PENDING_ACK;
					}
					else
						pending &= ~BABEL_PENDING_ACK;
				}
				else {
					destaddr = AM_BROADCAST_ADDR;

					if(pending & BABEL_ADDR_CHANGED) {
						BABEL_D_inline(SEND, "upd: addrchange - ");
						for(i = 0; i < cnt_ndb;) {
							BABEL_D_inline(SEND, "upd: dest=%04X retract - ", ndb[i].dest_nodeid);
							if(BABEL_WRITE_MSG_ROUTER_ID(bptr, aptr, ndb[i].eui)&& BABEL_WRITE_MSG_UPDATE(bptr, aptr, 1, ndb[i].seqno, BABEL_INFINITY, ndb[i].dest_nodeid)) {
								if(i != self)
									remove_ndb(i);
								else
									i++;
							}
						}
						if(i == 1) {
							// change own address after full route update and reload routing table
							ndb[self].dest_nodeid = call ActiveMessageAddress.amAddress();
							ndb[self].flags |= BABEL_FLAG_UPDATE;
							pending &= ~BABEL_ADDR_CHANGED;
							pending |= BABEL_PENDING_HELLO | BABEL_PENDING_UPDATE | BABEL_PENDING_RT_REQUEST_WILD;
						}
					}
					else {
						// process hello_timer
						if(pending & BABEL_PENDING_HELLO) {
							BABEL_D_inline(SEND, "hello h_seq=%04X - ", hello_seqno);
							pending &= ~BABEL_PENDING_HELLO;
							if(hello_interval < BABEL_HELLO_INTERVAL) {
								hello_interval *= 2;
								if(hello_interval > BABEL_HELLO_INTERVAL)
									hello_interval = BABEL_HELLO_INTERVAL;
							}
							BABEL_WRITE_MSG_HELLO(bptr, aptr, hello_seqno, hello_interval);
							if((hello_seqno % BABEL_HELLO_PER_IHU) == 0) {
								for(i = 0; i < cnt_neighdb; i++) {
									BABEL_D_inline(SEND, "ihu %04X - ", neighdb[i].neigh_nodeid);
									if( ! BABEL_WRITE_MSG_IHU(bptr, aptr, linkcost(neighdb[i].hello_history), BABEL_HELLO_PER_IHU * hello_interval, neighdb[i].neigh_nodeid)) {
										BABEL_D_inline(SEND, "\n");
										BABEL_E(SEND, "ihu packet tx overflow error\n");
										break;
									}
								}
							}
							if((hello_seqno % BABEL_HELLO_PER_UPDATE) == 0) {
								for(i = 0; i < cnt_ndb; i++)
									ndb[i].flags |= BABEL_FLAG_UPDATE;
								pending |= BABEL_PENDING_UPDATE;
							}
						}

						// request full route resync
						if(pending & BABEL_PENDING_RT_REQUEST_WILD) {
							BABEL_D_inline(SEND, "upd all - ");
							if(BABEL_WRITE_MSG_RT_REQUEST(bptr, aptr, BABEL_RT_WILD)) {
								pending &= ~ BABEL_PENDING_RT_REQUEST_WILD;
							}
						}

						// process route update (maybe more messages)
						if(pending & BABEL_PENDING_UPDATE) {
							bool more = FALSE;
							BABEL_D_inline(SEND, "upd - ");
							for(i = 0; i < cnt_ndb; i++) {
								if(ndb[i].flags & BABEL_FLAG_UPDATE) {
									BABEL_D_inline(SEND, "upd: dest=%04X seq=%04X metr=%04X - ", ndb[i].dest_nodeid, ndb[i].seqno, (ndb[i].flags & BABEL_FLAG_RETRACTION ? BABEL_INFINITY
											: ndb[i].metric));
									if(BABEL_WRITE_MSG_ROUTER_ID(bptr, aptr, ndb[i].eui)&& BABEL_WRITE_MSG_UPDATE(bptr, aptr, BABEL_HELLO_PER_UPDATE * hello_interval, ndb[i].seqno,
											(ndb[i].flags & BABEL_FLAG_RETRACTION ? BABEL_INFINITY : ndb[i].metric), ndb[i].dest_nodeid)) {
										ndb[i].flags &= ~ BABEL_FLAG_UPDATE;
									}
									else {
										more = TRUE;
										break;
									}
								}
							}
							if( ! more)
								pending &= ~ BABEL_PENDING_UPDATE;
						}

						// process sq request (maybe more messages)
						if(pending & BABEL_PENDING_SQ_REQUEST) {
							bool more = FALSE;
							BABEL_D_inline(SEND, "sqrq - ");
							for(i = 0; i < cnt_ndb; i++) {
								if(ndb[i].flags & BABEL_FLAG_SQ_REQEST) {
									if(BABEL_WRITE_MSG_SQ_REQUEST(bptr, aptr, ndb[i].pending_seqno, ndb[i].pending_hopcount, ndb[i].eui, ndb[i].dest_nodeid)) {
										ndb[i].flags &= ~ BABEL_FLAG_SQ_REQEST;
										BABEL_D_inline(SEND, "sqrq: dest=%04X seq=%04X - ", ndb[i].dest_nodeid, ndb[i].pending_seqno);
									}
									else {
										more = TRUE;
										break;
									}
								}
							}
							if( ! more)
								pending &= ~ BABEL_PENDING_SQ_REQUEST;
						}

						// process rt request (maybe more messages)
						if(pending & BABEL_PENDING_RT_REQUEST) {
							bool more = FALSE;
							BABEL_D_inline(SEND, "rtreq - ");
							for(i = 0; i < cnt_ndb; i++) {
								if(ndb[i].flags & BABEL_FLAG_RT_REQUEST) {
									if(BABEL_WRITE_MSG_RT_REQUEST(bptr, aptr, ndb[i].dest_nodeid)) {
										BABEL_D_inline(SEND, "rtreq: %04X - ", ndb[i].dest_nodeid);
										ndb[i].flags &= ~ BABEL_FLAG_RT_REQUEST;
									}
									else {
										more = TRUE;
										break;
									}
								}
							}
							if( ! more)
								pending &= ~ BABEL_PENDING_RT_REQUEST;
						}
					}

					// finish message and send
					if(BABEL_WRITE_MSG_END(bptr, aptr)) {
						if(call AMSend.send(destaddr, &pkt, aptr - bptr) == SUCCESS) {
							busy = TRUE;
							BABEL_D_inline(SEND, "== %04X\n", destaddr);
						}
						else {
							BABEL_D_inline(SEND, "== %04X ( txerr )\n", destaddr);
						}
					}
					else
						BABEL_E(SEND, "msg len error\n");
					BABEL_D_flush(SEND);
				}
			}
		}
	}

	event void AMSend.sendDone(message_t * msg, error_t error) {
		if(&pkt == msg) {
			busy = FALSE;
			if(error == SUCCESS) {
				BABEL_D(SEND, "txdone\n");
				BABEL_D_flush(SEND);
			}
			else {
				BABEL_E(SEND, "txdone err %d\n", error);
				BABEL_E_flush(SEND);
			}
			send();
		}
		else {
			BABEL_E(SEND, "txdone err\n");
			BABEL_E_flush(SEND);
		}
	}

	event void TimerLed.fired() {
		call Leds.led0Off();
	}

	event message_t * Receive.receive(message_t * msg, void * payload, uint8_t len) {
		bool send_immediate = FALSE;
		void * bptr = payload, *aptr = payload;

		if(len < 4) {
			BABEL_E(RECEIVE, "packet too small\n");
			BABEL_E_flush(RECEIVE);
			return msg;
		}

		call Leds.led0On();
		call TimerLed.startOneShot(10);

		BABEL_D(RECEIVE, "rxbegin %04X == ", call AMPacket.source(msg));

		if(BABEL_READ_MSG_BEGIN(bptr, aptr, len)) {
			bool err = FALSE;
			ieee_eui64_t last_eui;
			uint16_t last_nodeid = call AMPacket.source(msg);

			uint8_t neighdb_idx = search_neighdb(last_nodeid);
			if(neighdb_idx != BABEL_NOT_FOUND) {
				// do some average smoothing
				//TODO: recompute by http://www.hindawi.com/journals/jcnc/2012/790374/
				neighdb[neighdb_idx].lqi /= 2;
				neighdb[neighdb_idx].lqi += getLqi(msg) / 2;
				neighdb[neighdb_idx].rssi /= 2;
				neighdb[neighdb_idx].rssi += getRssi(msg) / 2;
			}

			while(( ! err)&&( ! BABEL_READ_MSG_END(bptr, aptr, len))) {
				switch(*(nx_uint8_t * ) aptr) {
					case BABEL_PAD1 : // 4.4.1.  Pad1
					{
						BABEL_D_inline(RECEIVE, "PAD1 - ");
						if( ! BABEL_READ_MSG_PAD1(bptr, aptr, len)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "PAD0 error\n");
						}
						break;
					}
					case BABEL_PADN : // 4.4.2.  PadN
					{
						BABEL_D_inline(RECEIVE, "PADN - ");
						if( ! BABEL_READ_MSG_PADN(bptr, aptr, len)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "PADN error\n");
						}
						break;
					}
					case BABEL_ACK_REQ : //  4.4.3.  Acknowledgement Request
					{
						// TODO: unused/untested
						uint16_t _nonce, _interval;
						BABEL_D_inline(RECEIVE, "ACKRQ %04X - ", last_nodeid);
						if( ! BABEL_READ_MSG_ACK_REQ(bptr, aptr, len, _nonce, _interval)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "ACK REQ error\n");
						}
						else {
							uint8_t i;
							BABEL_D_inline(RECEIVE, "ackrq: non=%04X - ", _nonce);
							for(i = 0; i < cnt_ackdb; i++){	// ignore duplicities
								if((ackdb[i].nodeid == last_nodeid)&&(ackdb[i].nonce == _nonce))
									break;
							}
							if(i == cnt_ackdb) {
								if(cnt_ackdb < sizeof(ackdb)) {
									cnt_ackdb++;
									ackdb[i].nodeid = last_nodeid;
									ackdb[i].nonce = _nonce;
									pending |= BABEL_PENDING_ACK;
									send_immediate = TRUE;
								}
								else {
									err = TRUE;
									BABEL_D_inline(RECEIVE, "\n");
									BABEL_E(RECEIVE, "ackdb overflow error\n");
									break;
								}
							}
						}
						break;
					}
					case BABEL_ACK : //  4.4.4.  Acknowledgement
					{
						// TODO: unused/untested
						uint16_t _nonce;
						BABEL_D_inline(RECEIVE, "ACK - ");
						if( ! BABEL_READ_MSG_ACK(bptr, aptr, len, _nonce)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "ACK error\n");
						}
						else {
							// TODO: process ack response
							BABEL_D_inline(RECEIVE, "ack: non=%04X (UNPROCESSED) - ", _nonce);
						}
						break;
					}
					case BABEL_HELLO : // 4.4.5.  Hello
					{
						uint16_t _seqno, _interval;
						BABEL_D_inline(RECEIVE, "HELLO - ");
						if( ! BABEL_READ_MSG_HELLO(bptr, aptr, len, _seqno, _interval)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "HELLO error\n");
						}
						else {
							BABEL_D_inline(RECEIVE, "hello: h_seq=%04X - ", _seqno);
							if(neighdb_idx != BABEL_NOT_FOUND) {
								uint16_t hello_history = neighdb[neighdb_idx].hello_history;
								uint8_t hello_timer_lost = 0, i;
								uint16_t hello_seqno_lost;

								// count hello lost by expired hellp_timer
								for(i = 0; i < 16; i++) {
									if( ! (hello_history & 0x8000))
										hello_timer_lost++;
									else
										break;
									hello_history <<= 1;
								}

								// eval seqno
								hello_seqno_lost = seqnodiff(_seqno, neighdb[neighdb_idx].hello_seqno);

								if(hello_seqno_lost > 16){ // large lost
									neighdb[neighdb_idx].hello_history = 0;
								}
								else {
									if(hello_timer_lost < hello_seqno_lost) {
										neighdb[neighdb_idx].hello_history >>= hello_seqno_lost - hello_timer_lost;
									}
									else {
										neighdb[neighdb_idx].hello_history <<= hello_timer_lost - hello_seqno_lost;
									}
								}

								neighdb[neighdb_idx].hello_history |= 0x8000;
								neighdb[neighdb_idx].hello_seqno = _seqno;
								neighdb[neighdb_idx].hello_timer = 2 * _interval;
								BABEL_D_inline(RECEIVE, "hello: history=%04X - ", neighdb[neighdb_idx].hello_history);
							}
							else {
								NeighborDB data;

								data.neigh_nodeid = last_nodeid;
								data.hello_history = 0x8000;
								data.hello_seqno = _seqno;
								data.hello_timer = 2 * _interval;
								data.hello_interval = _interval;
								data.ihu_tx_cost = BABEL_INFINITY;
								data.ihu_timer = 0;
								data.lqi = getLqi(msg);
								data.rssi = getRssi(msg);

								if(insert_neighdb(&data)) {
									uint8_t i;
									BABEL_D_inline(RECEIVE, "hello: new - ");
									for(i = 0; i < cnt_ndb; i++)
										ndb[i].flags |= BABEL_FLAG_UPDATE;
									pending |= BABEL_PENDING_HELLO | BABEL_PENDING_UPDATE;
									hello_interval = BABEL_HELLO_INTERVAL / 8;
									neighdb_idx = search_neighdb(last_nodeid);
								}
								else {
									err = TRUE;
									BABEL_D_inline(RECEIVE, "\n");
									BABEL_E(RECEIVE, "neighdb overflow rx error\n");
									break;
								}
							}
						}
						break;
					}
					case BABEL_IHU : // 4.4.6.  IHU
					{
						uint16_t _cost, _interval, _nodeid;
						BABEL_D_inline(RECEIVE, "IHU - ");
						if( ! BABEL_READ_MSG_IHU(bptr, aptr, len, _cost, _interval, _nodeid)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "IHU error\n");
						}
						else {
							if(_nodeid == ndb[self].dest_nodeid){	// process only our IHU message data
								BABEL_D_inline(RECEIVE, "ihu: my txcost %d - ", _cost);
								if(neighdb_idx != BABEL_NOT_FOUND) {
									neighdb[neighdb_idx].ihu_tx_cost = _cost;
									neighdb[neighdb_idx].ihu_timer = _interval * BABEL_IHU_THRESHOLD;
								}
								else {
									NeighborDB data;

									data.neigh_nodeid = last_nodeid;
									data.hello_history = 0x0000;
									data.hello_seqno = 0;
									data.hello_timer = 0;
									data.hello_interval = 0;
									data.ihu_tx_cost = _cost;
									data.ihu_timer = _interval * BABEL_IHU_THRESHOLD;
									data.lqi = getLqi(msg);
									data.rssi = getRssi(msg);

									if(insert_neighdb(&data)) {
										uint8_t i;
										BABEL_D_inline(RECEIVE, "ihu: new neigh - ");
										for(i = 0; i < cnt_ndb; i++)
											ndb[i].flags |= BABEL_FLAG_UPDATE;
										pending |= BABEL_PENDING_HELLO | BABEL_PENDING_UPDATE;
										hello_interval = BABEL_HELLO_INTERVAL / 8;
										neighdb_idx = search_neighdb(last_nodeid);
									}
									else {
										err = TRUE;
										BABEL_D_inline(RECEIVE, "\n");
										BABEL_E(RECEIVE, "neighdb overflow error\n");
										break;
									}
								}
							}
						}
						break;
					}
					case BABEL_ROUTER_ID : // 4.4.7.  Router-Id
					{
						BABEL_D_inline(RECEIVE, "RTID - ");
						if( ! BABEL_READ_MSG_ROUTER_ID(bptr, aptr, len, last_eui)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "ROUTERID error\n");
						}
						break;
					}
					case BABEL_NH : // 4.4.8.  Next Hop
					{
						uint16_t _last_nodeid;

						BABEL_D_inline(RECEIVE, "NH - ");
						if( ! BABEL_READ_MSG_NH(bptr, aptr, len, _last_nodeid)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "NH error\n");
							break;
						}
						BABEL_D_inline(RECEIVE, "nh=%04X - ", _last_nodeid);

						if(_last_nodeid != last_nodeid) {
							BABEL_D_inline(RECEIVE, "nh updated - ");

							last_nodeid = _last_nodeid;
							neighdb_idx = search_neighdb(last_nodeid);
							if(neighdb_idx != BABEL_NOT_FOUND) {
								// do some average smoothing
								//TODO: recompute by http://www.hindawi.com/journals/jcnc/2012/790374/
								neighdb[neighdb_idx].lqi /= 2;
								neighdb[neighdb_idx].lqi += getLqi(msg) / 2;
								neighdb[neighdb_idx].rssi /= 2;
								neighdb[neighdb_idx].rssi += getRssi(msg) / 2;
							}
						}
						break;
					}
					case BABEL_UPDATE : // 4.4.9.  Update
					{
						uint16_t _interval, _seqno, _metric, _destnodeid;
						BABEL_D_inline(RECEIVE, "UPD - ");
						if( ! BABEL_READ_MSG_UPDATE(bptr, aptr, len, _interval, _seqno, _metric, _destnodeid)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "UPDATE error\n");
						}
						else {
							uint16_t idx;
							BABEL_D_inline(RECEIVE, "upd: dest=%04X seq=%04X metr=%04X - ", _destnodeid, _seqno, _metric);
							if(_destnodeid == ndb[self].dest_nodeid){// reverse echo ?
								BABEL_D_inline(RECEIVE, "upd: me  -");
								if(*(uint64_t * )&last_eui < *(uint64_t * )&ndb[self].eui) {
									// someone else has my nodeid, change my nodeid
									am_addr_t new_nodeid = ndb[self].dest_nodeid + 1;
									while((search_ndb(new_nodeid) != BABEL_NOT_FOUND) || (new_nodeid == 0xffff) || (new_nodeid == 0))
										new_nodeid++;
									call ActiveMessageAddress.setAddress(TOS_AM_GROUP, new_nodeid);
									BABEL_N(BASIC, "NODEID collision, new nodeid %04X\n", new_nodeid);
									break;
								}
								if(((*(uint64_t * )&last_eui == *(uint64_t * )&ndb[self].eui))&& seqnograter(_seqno, ndb[self].seqno, BABEL_SEQNO_GRATER)) {
									// boot sequence sync to network
									ndb[self].seqno = _seqno + 1;
									ndb[self].flags |= BABEL_FLAG_UPDATE;
									pending |= BABEL_PENDING_UPDATE;
									send_immediate = TRUE;
									BABEL_D_inline(RECEIVE, "upd: my NEW seq=%04X -", ndb[self].seqno);
								}
								break;
							}
							else {
								if((*(uint64_t * )&last_eui == *(uint64_t * )&ndb[self].eui)) {
									BABEL_D_inline(RECEIVE, "upd: me with different nodeid, ignore - ");
									break;
								}
							}
							idx = search_ndb(_destnodeid);
							if(idx != BABEL_NOT_FOUND) {
								uint16_t m = metric(_metric, last_nodeid);

								if((_metric != BABEL_INFINITY)&&(_seqno == ndb[idx].seqno)&&((m & BABEL_RT_MINOR_BITS_MASK) == (ndb[idx].metric & BABEL_RT_MINOR_BITS_MASK))&&(ndb[idx]
										.nexthop_nodeid == last_nodeid)&&(*(uint64_t * )&ndb[idx].eui == *(uint64_t * )&last_eui)) {
									// equals (seqno, metric, eui), update status for route
									ndb[idx].timer = _interval * BABEL_RT_THRESHOLD;
									ndb[idx].flags &= ~BABEL_FLAG_UNFEASIBLE;
									ndb[idx].flags &= ~(BABEL_FLAG_RT_SWITCH | BABEL_FLAG_RETRACTION);
									BABEL_D_inline(RECEIVE, "upd: update - ");
								}
								else {
									if(_metric == BABEL_INFINITY) {
										// received retracted
										if(last_nodeid == ndb[idx].nexthop_nodeid) {
											if(*(uint64_t * )&ndb[idx].eui != *(uint64_t * )&last_eui) {
												// changing eui, cancel sq request
												ndb[idx].eui = last_eui;
												ndb[idx].pending_timer = 0;
												ndb[idx].flags &= ~BABEL_FLAG_SQ_REQEST;
											}
											if(ndb[idx].seqno < _seqno)
												ndb[idx].seqno = _seqno;
											// send rt request, after timeout try, sq request if any unfeasible received, and go to retracted
											ndb[idx].nexthop_nodeid = BABEL_NODEID_UNDEF; // switch to PHASE 2
											ndb[idx].timer = BABEL_RT_REQUEST_HOLD;
											ndb[idx].flags |= BABEL_FLAG_RT_REQUEST;
											ndb[idx].flags &= ~(BABEL_FLAG_RT_SWITCH | BABEL_FLAG_RETRACTION);
											pending |= BABEL_PENDING_RT_REQUEST;
											send_immediate = TRUE;
											BABEL_D_inline(RECEIVE, "upd: retracted - ");
										}
										else {
											BABEL_D_inline(RECEIVE, "upd: NH(%04X) not match ndb(%04X) ignore - ", last_nodeid, ndb[idx].nexthop_nodeid);
										}
									}
									else {// test feasible
										if(seqnograter(_seqno, ndb[idx].seqno, BABEL_SEQNO_GRATER) || ((_seqno == ndb[idx].seqno)&&(m < ndb[idx].metric))) {
											// feasible - update status for route
											if(*(uint64_t * )&ndb[idx].eui != *(uint64_t * )&last_eui) {
												// changing eui, cancel sq request
												ndb[idx].eui = last_eui;
												ndb[idx].pending_timer = 0;
												ndb[idx].flags &= ~BABEL_FLAG_SQ_REQEST;
												BABEL_D_inline(RECEIVE, "upd: remote changed EUI - ");
											}
											if((ndb[idx].pending_timer > 0)&&(seqnodiff(_seqno, ndb[idx].pending_seqno) < BABEL_SEQNO_GRATER)) {
												// this is response to sq request (_seqno >= pending_seqno), cancel sq request
												ndb[idx].pending_timer = 0;
												ndb[idx].flags &= ~BABEL_FLAG_SQ_REQEST;
												BABEL_D_inline(RECEIVE, "upd: response to rqsq - ");
											}
											ndb[idx].seqno = _seqno;
											ndb[idx].metric = m;
											ndb[idx].nexthop_nodeid = last_nodeid;
											ndb[idx].timer = _interval * BABEL_RT_THRESHOLD;
											ndb[idx].flags |= BABEL_FLAG_UPDATE;
											ndb[idx].flags &= ~BABEL_FLAG_UNFEASIBLE;
											ndb[idx].flags &= ~(BABEL_FLAG_RT_SWITCH | BABEL_FLAG_RETRACTION);
											pending |= BABEL_PENDING_UPDATE;
											send_immediate = TRUE;
											BABEL_D_inline(RECEIVE, "upd: feasible - ");
										}
										else {
											// not feasible
											ndb[idx].flags |= BABEL_FLAG_UNFEASIBLE;
											BABEL_D_inline(RECEIVE, "upd: unfeasible - ");
										}
									}
								}
							}
							else {
								// new entry, 3.5.4. /2
								if(_metric != BABEL_INFINITY) {
									NetDB data;

									memset(&data, 0, sizeof(data));
									data.dest_nodeid = _destnodeid;
									data.eui = last_eui;
									data.seqno = _seqno;
									data.metric = metric(_metric, last_nodeid);
									data.nexthop_nodeid = last_nodeid;
									data.timer = _interval * BABEL_RT_THRESHOLD;
									data.flags |= BABEL_FLAG_UPDATE;

									if(insert_ndb(&data)) {
										pending |= BABEL_PENDING_UPDATE;
										send_immediate = TRUE;
										BABEL_D_inline(RECEIVE, "upd: new - ");
									}
									else {
										err = TRUE;
										BABEL_D_inline(RECEIVE, "\n");
										BABEL_E(RECEIVE, "ndb overflow error\n");
										break;
									}

								}
							}
						}
						break;
					}
					case BABEL_RT_REQUEST : // 4.4.10.  Route Request
					{
						uint16_t _destnodeid;
						BABEL_D_inline(RECEIVE, "RTRQ - ");
						if( ! BABEL_READ_MSG_RT_REQUEST(bptr, aptr, len, _destnodeid)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "RT REQUEST error\n");
						}
						else {
							if(_destnodeid == BABEL_RT_WILD) {
								uint8_t i;
								BABEL_D_inline(RECEIVE, "rtrq: all - ");
								for(i = 0; i < cnt_ndb; i++)
									ndb[i].flags |= BABEL_FLAG_UPDATE;
							}
							else {
								uint8_t idx = search_ndb(_destnodeid);
								if(idx != BABEL_NOT_FOUND) {
									BABEL_D_inline(RECEIVE, "rtrq: dest=%04X - ", _destnodeid);
									ndb[idx].flags |= BABEL_FLAG_UPDATE;
								}
								else {
									// TODO: send retraction route 3.8.1.1/1
									// ??? what about loop ?
									BABEL_D_inline(RECEIVE, "rtrq: unknown (RETRACTION NOT SEND) - ");
								}
							}
							pending |= BABEL_PENDING_UPDATE;
							send_immediate = TRUE;
						}
						break;
					}
					case BABEL_SQ_REQUEST : // 4.4.11.  Seqno Request
					{
						uint16_t _seqno, _destnodeid;
						uint8_t _hopcount;
						ieee_eui64_t _eui;
						BABEL_D_inline(RECEIVE, "SQRQ - ");
						if( ! BABEL_READ_MSG_SQ_REQUEST(bptr, aptr, len, _seqno, _hopcount, _eui, _destnodeid)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "SQ REQUEST error\n");
						}
						else {
							BABEL_D_inline(RECEIVE, "sqrq: dest=%04X seq=%04X - ", _destnodeid, _seqno);
							if(_destnodeid == ndb[self].dest_nodeid){ // is for me
								if(*(uint64_t * )&_eui < *(uint64_t * )&ndb[self].eui) {
									am_addr_t new_nodeid = ndb[self].dest_nodeid + 1;
									while((search_ndb(new_nodeid) != BABEL_NOT_FOUND) || (new_nodeid == 0xffff) || (new_nodeid == 0))
										new_nodeid++;
									call ActiveMessageAddress.setAddress(TOS_AM_GROUP, new_nodeid);
									BABEL_N(BASIC, "NODEID collision, new nodeid %04X\n", new_nodeid);
									break;
								}
								if(seqnograter(_seqno, ndb[self].seqno, BABEL_SEQNO_GRATER))
									ndb[self].seqno++;
								ndb[self].flags |= BABEL_FLAG_UPDATE;
								pending |= BABEL_PENDING_UPDATE;
								send_immediate = TRUE;
								BABEL_D_inline(RECEIVE, "sqrq: my NEW seq=%04X - ", ndb[self].seqno);
							}
							else {
								uint8_t idx = search_ndb(_destnodeid);
								if(idx != BABEL_NOT_FOUND) {
									// 3.8.1.2. /1
									if((ndb[idx].flags & BABEL_FLAG_RETRACTION) || (ndb[idx].metric == BABEL_INFINITY))
										break;

									// 3.8.1.2. /2-3
									if(seqnograter(ndb[idx].seqno, _seqno, BABEL_SEQNO_GRATER)){ // have newer in table than requested
										ndb[idx].flags |= BABEL_FLAG_UPDATE;
										pending |= BABEL_PENDING_UPDATE;
										send_immediate = TRUE;
										BABEL_D_inline(RECEIVE, "sqrq: update - ");
										break;
									}

									// 3.8.1.2. /4-7, send with broadcast, hopcount barriers infinite broadcast loop
									if(_hopcount >= 2) {
										_hopcount--;
										// add new or updated sq request
										if((ndb[idx].pending_timer == 0) || seqnograter(_seqno, ndb[idx].pending_seqno, BABEL_SEQNO_GRATER) || ((ndb[idx].pending_seqno == _seqno)&&(ndb[idx]
												.pending_hopcount < _hopcount))) {
											BABEL_D_inline(RECEIVE, "sqrq: forward - ");
											ndb[idx].pending_seqno = _seqno;
											ndb[idx].pending_hopcount = _hopcount;
											ndb[idx].pending_timer = BABEL_SQ_REQUEST_RETRY * BABEL_SQ_REQUEST_RETRY_INTERVAL;
											ndb[idx].flags |= BABEL_FLAG_SQ_REQEST;
											pending |= BABEL_PENDING_SQ_REQUEST;
											send_immediate = TRUE;
										}
										break;
									}
									break;
								}
							}
						}
						break;
					}
					default : {
						BABEL_D_inline(RECEIVE, "uknown - ");
						if( ! BABEL_READ_MSG_UNKNOWN(bptr, aptr, len)) {
							err = TRUE;
							BABEL_D_inline(RECEIVE, "\n");
							BABEL_E(RECEIVE, "TLV error\n");
						}
						break;
					}
				}
			}
		}

		BABEL_D_inline(RECEIVE, " (node rssi %d)\n", getRssi(msg));
		BABEL_D_flush(RECEIVE);

		if(send_immediate)
			send(); // or post ?

		return msg;
	}

	event void Timer.fired() {
		uint8_t i;

		// process neighdb timers

		for(i = 0; i < cnt_neighdb; i++) {
			if(neighdb[i].hello_timer)
				if( ! (--neighdb[i].hello_timer)){	// nonfatal lost "hello"
				neighdb[i].hello_timer = neighdb[i].hello_interval;
				neighdb[i].hello_history >>= 1;
				BABEL_D(TIMER, "lost hello %04X\n", neighdb[i].neigh_nodeid);
				BABEL_D_flush(TIMER);
			}
			if(neighdb[i].ihu_timer)
				if( ! (--neighdb[i].ihu_timer)){	// fatal too many lost "ihu"
				neighdb[i].ihu_tx_cost = BABEL_INFINITY;
				BABEL_D(TIMER, "lost ihu %04X\n", neighdb[i].neigh_nodeid);
				BABEL_D_flush(TIMER);
			}
			if((neighdb[i].ihu_tx_cost == BABEL_INFINITY)&&(neighdb[i].hello_history == 0)){ // neighbor lost
				uint8_t j;
				BABEL_D(TIMER, "neighdb delete %04X\n", neighdb[i].neigh_nodeid);
				BABEL_D_flush(TIMER);
				// try to switch neigbor in route tables
				for(j = 0; j < cnt_ndb; j++) {
					if(ndb[j].nexthop_nodeid == neighdb[i].neigh_nodeid){ // request update routing
						// switch to PHASE 2
						ndb[j].nexthop_nodeid = BABEL_NODEID_UNDEF;
						ndb[j].timer = BABEL_RT_REQUEST_HOLD;
						ndb[j].flags |= BABEL_FLAG_RT_REQUEST;
						ndb[i].flags &= ~(BABEL_FLAG_RT_SWITCH | BABEL_FLAG_RETRACTION);
						pending |= BABEL_PENDING_RT_REQUEST;
					}
				}
				// delete neigbor
				remove_neighdb(i);
				i--;
			}
		}

		// process ndb timers

		for(i = 0; i < cnt_ndb; i++) {
			if(ndb[i].timer) {
				ndb[i].timer--;
				if(ndb[i].nexthop_nodeid != BABEL_NODEID_UNDEF) {

					if( ! ndb[i].timer){ // route update timeout

						// PHASE 1: try to change to other feasible route (next_node switch)
						// BABEL_FLAG_RT_SWITCH

						if( ! (ndb[i].flags & BABEL_FLAG_RT_SWITCH)) {
							// try to switch route to the next on fly
							// TODO: use free entry in routing table to hold alternative feasible routers and use it here
							ndb[i].timer = BABEL_RT_SWITCH_HOLD;
							ndb[i].flags |= BABEL_FLAG_RT_SWITCH;
							ndb[i].metric |= BABEL_RT_MINOR_BITS_MASK;
						}
						else {
							// SWITCH TO PHASE 2
							// try to switch route to other next_node unsuccessful
							ndb[i].nexthop_nodeid = BABEL_NODEID_UNDEF;
							ndb[i].timer = BABEL_RT_REQUEST_HOLD;
							ndb[i].flags &= ~(BABEL_FLAG_RT_SWITCH | BABEL_FLAG_RETRACTION);
						}
						ndb[i].flags |= BABEL_FLAG_RT_REQUEST;
						pending |= BABEL_PENDING_RT_REQUEST;
					}
				}
				else {

					// PHASE 2: try to find other route with "Request Route"
					// BABEL_NODEID_UNDEF

					if( ! (ndb[i].flags & BABEL_FLAG_RETRACTION)) {
						// RT request processing (BABEL_RT_REQUEST_HOLD)
						if(ndb[i].timer) {
							if((ndb[i].timer % BABEL_RT_REQUEST_RETRY_INTERVAL) == 0) {
								// retry RT request
								ndb[i].flags |= BABEL_FLAG_RT_REQUEST;
								pending |= BABEL_PENDING_RT_REQUEST;
							}
						}
						else {
							// SWITCH TO PHASE 3
							// RT request unsuccessful
							if(ndb[i].flags & BABEL_FLAG_UNFEASIBLE){ // try to find feasible route with seqno increment if unfeasible exists
								// some unfeasible try SQ request
								// ??? overwrite pending
								ndb[i].pending_seqno = ndb[i].seqno + 1;
								ndb[i].pending_hopcount = BABEL_SQ_REQUEST_HOPCOUNT;
								ndb[i].pending_timer = BABEL_SQ_REQUEST_RETRY * BABEL_SQ_REQUEST_RETRY_INTERVAL;
								ndb[i].flags |= BABEL_FLAG_SQ_REQEST;
								pending |= BABEL_PENDING_SQ_REQUEST;
								BABEL_D(TIMER, "sqreq dest=%04X seq=%04X\n", ndb[i].dest_nodeid, ndb[i].pending_seqno);
							}
							ndb[i].timer = BABEL_RT_RETRACTION_HOLD;
							// send retraction
							ndb[i].flags |= BABEL_FLAG_UPDATE | BABEL_FLAG_RETRACTION;
							pending |= BABEL_PENDING_UPDATE;
						}
					}
					else {

						// PHASE 3: push retract and wait for "Seqno Request" response
						// BABEL_NODEID_UNDEF && BABEL_FLAG_RETRACTION

						if(ndb[i].timer) {
							if((ndb[i].timer % BABEL_RT_RETRACTION_RETRY_INTERVAL) == 0) {
								// send retraction
								ndb[i].flags |= BABEL_FLAG_UPDATE;
								pending |= BABEL_PENDING_UPDATE;
							}
						}
						else {

							// PHASE 4: delete
							// last hold timeout, delete from route table (BABEL_RT_REQUEST_HOLD+BABEL_RT_REQUEST_HOLD), 3.5.5. Hold Time

							BABEL_D(TIMER, "route delete %04X\n", ndb[i].dest_nodeid);
							remove_ndb(i);
							i--;
						}
					}
				}
			}

			if(ndb[i].pending_timer) {
				if(( ! (--ndb[i].pending_timer))&&(ndb[i].pending_timer % BABEL_SQ_REQUEST_RETRY_INTERVAL) == 0) {
					// retry SQ request
					ndb[i].flags |= BABEL_FLAG_SQ_REQEST;
					pending |= BABEL_PENDING_SQ_REQUEST;
				}
			}
		}

		// process global timer for hello, ihu and periodic update

		if( ! (--hello_timer)) {
			hello_timer = hello_interval;
			hello_seqno++;
			pending |= BABEL_PENDING_HELLO;
		}

		// process pending triggers
		send();
	}

	command mh_action_t RouteSelect.selectRoute(message_t * msg) {

		BABEL_D(ROUTE, "route query: ");
		if(call L3AMPacket.isForMe(msg)) {
			BABEL_D_inline(ROUTE, "RECEIVE\n");
			return MH_RECEIVE;
		}
		else {
			am_addr_t dest_nodeid;
			uint8_t idx;

			dest_nodeid = call L3AMPacket.destination(msg);
			// TODO: where handle broadcast destination ?
			idx = search_ndb(dest_nodeid);

			if(idx == BABEL_NOT_FOUND) {
				BABEL_D_inline(ROUTE, "DISCARD %04X\n", dest_nodeid);
				return MH_DISCARD;
			}
			if(ndb[idx].nexthop_nodeid == BABEL_NODEID_UNDEF) {
				if(wait_cnt++ > 2) {
					ndb[idx].flags |= BABEL_FLAG_RT_REQUEST;
					pending |= BABEL_PENDING_RT_REQUEST;
					wait_cnt = 0;
				}
				BABEL_D_inline(ROUTE, "WAIT %04X (%04X %04X)\n", dest_nodeid, ndb[idx].nexthop_nodeid, ndb[idx].flags);
				return MH_WAIT;
			}

			call AMPacket.setDestination(msg, ndb[idx].nexthop_nodeid);
			BABEL_D_inline(ROUTE, "ROUTE to %04X through %04X\n", dest_nodeid, ndb[idx].nexthop_nodeid);
			return MH_SEND;
		}
	}

	// address change reaction

	task void addrchanged() {
		BABEL_D(BASIC, "addr changed %04X\n", call ActiveMessageAddress.amAddress());

		pending |= BABEL_ADDR_CHANGED;
		if(call Timer.isRunning())
			// already initialized
		send();
	}

	async event void ActiveMessageAddress.changed() {
		post addrchanged();
	}

	// table API

	command error_t NeighborTable.rowFirst(void * row, uint8_t rowptrsize) {
		if(rowptrsize < sizeof(am_addr_t))
			return ESIZE;
		if(cnt_neighdb == 0)
			return ELAST;
		*(am_addr_t * ) row = neighdb[0].neigh_nodeid;
		return SUCCESS;
	}

	command error_t NeighborTable.rowNext(void * row, uint8_t rowptrsize) {
		uint8_t idx;
		if(rowptrsize < sizeof(am_addr_t))
			return ESIZE;
		idx = search_neighdb(*(am_addr_t * ) row);
		if(idx != BABEL_NOT_FOUND) {
			idx++;
			if(idx == cnt_neighdb)
				return ELAST;
			else {
				*(am_addr_t * ) row = neighdb[idx].neigh_nodeid;
				return SUCCESS;
			}
		}
		else
			return FAIL;
	}

	command error_t NeighborTable.colRead(void * row, uint8_t col_id, void * col, uint8_t colptrsize) {
		uint8_t idx;
		idx = search_neighdb(*(am_addr_t * ) row);
		if(idx == BABEL_NOT_FOUND)
			return FAIL;
		switch(col_id) {
			case BABEL_NB_NODEID : {
				if(colptrsize < sizeof(am_addr_t))
					return ESIZE;
				*(am_addr_t * ) col = neighdb[idx].neigh_nodeid;
				return SUCCESS;
			}
			case BABEL_NB_COST : {
				if(colptrsize < sizeof(uint16_t))
					return ESIZE;
				*(uint16_t * ) col = metric(0, idx);
				return SUCCESS;
			}
			case BABEL_NB_LQI : {
				if(colptrsize < sizeof(uint8_t))
					return ESIZE;
				*(uint8_t * ) col = neighdb[idx].lqi;
				return SUCCESS;
			}
			case BABEL_NB_RSSI : {
				if(colptrsize < sizeof(uint8_t))
					return ESIZE;
				*(uint8_t * ) col = neighdb[idx].rssi;
				return SUCCESS;
			}
			default : return FAIL;
		}
	}

	command error_t RoutingTable.rowFirst(void * row, uint8_t rowptrsize) {
		if(rowptrsize < sizeof(am_addr_t))
			return ESIZE;
		if(cnt_ndb == 0)
			return ELAST;
		*(am_addr_t * ) row = ndb[0].dest_nodeid;
		return SUCCESS;
	}

	command error_t RoutingTable.rowNext(void * row, uint8_t rowptrsize) {
		uint8_t idx;
		if(rowptrsize < sizeof(am_addr_t))
			return ESIZE;
		idx = search_ndb(*(am_addr_t * ) row);
		if(idx != BABEL_NOT_FOUND) {
			idx++;
			if(idx == cnt_ndb)
				return ELAST;
			else {
				*(am_addr_t * ) row = ndb[idx].dest_nodeid;
				return SUCCESS;
			}
		}
		else
			return FAIL;
	}

	command error_t RoutingTable.colRead(void * row, uint8_t col_id, void * col, uint8_t colptrsize) {
		uint8_t idx;
		idx = search_ndb(*(am_addr_t * ) row);
		if(idx == BABEL_NOT_FOUND)
			return FAIL;
		switch(col_id) {
			case BABEL_RT_NODEID : {
				if(colptrsize < sizeof(am_addr_t))
					return ESIZE;
				*(am_addr_t * ) col = ndb[idx].dest_nodeid;
				return SUCCESS;
			}
			case BABEL_RT_EUI : {
				if(colptrsize < sizeof(ieee_eui64_t))
					return ESIZE;
				*(ieee_eui64_t * ) col = ndb[idx].eui;
				return SUCCESS;
			}
			case BABEL_RT_METRIC : {
				if(colptrsize < sizeof(uint16_t))
					return ESIZE;
				*(uint16_t * ) col = ndb[idx].metric; // last known metric no retraction
				return SUCCESS;
			}
			case BABEL_RT_NEXT : {
				if(colptrsize < sizeof(am_addr_t))
					return ESIZE;
				*(am_addr_t * ) col = ndb[idx].nexthop_nodeid;
				return SUCCESS;
			}
			default : return FAIL;
		}
	}
}