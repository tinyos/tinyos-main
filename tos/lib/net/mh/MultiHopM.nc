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
 * The Multihop Active Message layer implementation module.
 * Handles received packets of a certain protocol
 * in a multihop context.  The component uses a route selector to
 * determine if the packet should be forwarded or passed to the upper
 * layer. If the packet is forwarded, the next hop is given by the
 * route selector.
 *
 * @author Martin Cerveny
 */

#include "MH.h"
#include "MH_private.h"

#include "debugserial.h"
#if 0 // debug this module
#define xdbg_MH(s,args...) printf(#s ": " args)
#define xdbg_inline_MH(s, args...) printf(args)
#define xdbg_flush_MH(s) printfflush()
#else
#define xdbg_MH(s,args...)
#define xdbg_inline_MH(s, args...)
#define xdbg_flush_MH(s)
#endif

module MultiHopM {
	provides {
		// for the upper layer (L4)
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Intercept[am_id_t id];
		interface PacketAcknowledgements as Acks;
		// L3		
		interface Packet;
		interface AMPacket;
		// other
		interface Init as SoftwareInit;
	}
	uses {
		// external route solver
		interface RouteSelect;
		// L2
		interface AMPacket as SubAMPacket;
		interface Packet as SubPacket;
		interface AMSend as SubSend;
		interface Receive as SubReceive;
		// other
		interface Timer<TMilli>;
	    interface Leds;
	}
}

implementation {

	typedef struct mh_fwd {
		message_t * msg; // pointer to buffer
		uint8_t msg_wait; // timer for fwd message retry
		bool free; // buffer is free buffer
	} mh_fwd_t;

	message_t fwd_msgs[MH_FORWARDING_BUFERS]; // initial free buffers (exchanged with L2)
	mh_fwd_t fwd[MH_FORWARDING_BUFERS]; // free buffers management for message forwarding

	message_t * send_msg = NULL; // actual L4 message
	uint8_t send_msg_wait = 0; // timer for L4 message retry
	bool send_canceled = FALSE; // L4 message send was cancelled

	message_t * subsend_msg = NULL; // subsending message
	bool subsend_fwd_sent = FALSE; // alternate (1:1) sending of local and forward messages

	// SoftwareInit 
	// setup free buffers for forwarding

	command error_t SoftwareInit.init() {
		int i;
		for(i = 0; i < MH_FORWARDING_BUFERS; i++) {
			fwd[i].msg = fwd_msgs + i;
			fwd[i].msg_wait = 0;
			fwd[i].free = TRUE;
		}
		return SUCCESS;
	}

	// try to send messages (L4 and fwd), called from expired timer, SubSend.sendDone, received new messge for fwd

	void send(bool from_timer) {
		uint8_t i;

		// try to send "forward message"

		for(i = 0; i < MH_FORWARDING_BUFERS; i++) {
			if( ! (from_timer || (subsend_msg == NULL))) 
				break;
			if(( ! fwd[i].free)&&(fwd[i].msg_wait % MH_WAIT_BEFORE_RETRY == 0)&&(fwd[i].msg != subsend_msg)) {
				switch(call RouteSelect.selectRoute(fwd[i].msg)) {
					case MH_SEND : {
						fwd[i].msg_wait = 0;
						if((subsend_msg == NULL)&&( (!subsend_fwd_sent) || (send_msg == NULL) || (send_msg_wait > 0))) {
							error_t err;
							subsend_msg = fwd[i].msg;
							subsend_fwd_sent = TRUE;
							xdbg(MH, "send: fwd sent type %u\n", call AMPacket.type(subsend_msg));
							err = call SubSend.send(call SubAMPacket.destination(subsend_msg), subsend_msg, call SubPacket.payloadLength(subsend_msg));
							if(err != SUCCESS) {
								fwd[i].free = TRUE;
								subsend_msg = NULL;
								subsend_fwd_sent = FALSE;
								xdbg(MH, "send: fwd sent err\n");
							}
							break;
						}
						xdbg(MH, "send: fwd subsend busy\n");
						break;
					}
					case MH_WAIT : {
						if(fwd[i].msg_wait == 0) {
							message_t * _msg = fwd[i].msg;
							// move buffer to keep in order delivery
							memmove(fwd + i, fwd + i + 1, (MH_FORWARDING_BUFERS - i - 1) * sizeof(mh_fwd_t));
							i--; // again this entry after move
							fwd[MH_FORWARDING_BUFERS - 1].msg = _msg;
							fwd[MH_FORWARDING_BUFERS - 1].free = TRUE;
							fwd[MH_FORWARDING_BUFERS - 1].msg_wait = 0;
							xdbg(MH, "send: fwd discarding, no more retry - %04X\n", call AMPacket.destination(_msg));
							break;
						}
						else {
							xdbg(MH, "send: fwd retry route later - %04X\n", call AMPacket.destination(fwd[i].msg));
							break;
						}
					}
					case MH_DISCARD : ;
					default : {
						message_t * _msg = fwd[i].msg;
						// move buffer to keep in order delivery
						memmove(fwd + i, fwd + i + 1, (MH_FORWARDING_BUFERS - i - 1) * sizeof(mh_fwd_t));
						i--; // again this entry after move
						fwd[MH_FORWARDING_BUFERS - 1].msg = _msg;
						fwd[MH_FORWARDING_BUFERS - 1].free = TRUE;
						fwd[MH_FORWARDING_BUFERS - 1].msg_wait = 0;
						xdbg(MH, "send: fwd discarding - %04X\n", call AMPacket.destination(_msg));
						break;
					}
				}
			}
		}

		// try to send "L4 message"

		if((send_msg != NULL)&&( ! send_canceled)&&(send_msg_wait % MH_WAIT_BEFORE_RETRY == 0)&&(send_msg != subsend_msg)&&(from_timer || (subsend_msg == NULL))) {
			switch(call RouteSelect.selectRoute(send_msg)) {
				case MH_SEND : {
					send_msg_wait = 0;
					if(subsend_msg == NULL) {
						error_t err;
						subsend_msg = send_msg;
						subsend_fwd_sent = FALSE;
						xdbg(MH, "send: sent type %u\n", call AMPacket.type(subsend_msg));
						err = call SubSend.send(call SubAMPacket.destination(subsend_msg), subsend_msg, call SubPacket.payloadLength(subsend_msg));
						if(err != SUCCESS) {
							message_t * _msg = send_msg;
							subsend_msg = NULL;
							send_msg = NULL;
							signal AMSend.sendDone[call AMPacket.type(_msg)](_msg, FAIL);
							xdbg(MH, "send: sent err\n");
						}
						break;
					}
					xdbg(MH, "send: subsend busy\n");
					break;
				}
				case MH_WAIT : {
					if(send_msg_wait == 0) {
						message_t * _msg = send_msg;
						send_msg = NULL;
						xdbg(MH, "send: discarding, no more retry - %04X\n", call AMPacket.destination(_msg));
						signal AMSend.sendDone[call AMPacket.type(_msg)](_msg, FAIL);
						break;
					}
					else {
						xdbg(MH, "send: retry route later - %04X\n", call AMPacket.destination(send_msg));
						break;
					}
				}
				case MH_DISCARD : ;
				default : {
					message_t * _msg = send_msg;
					send_msg = NULL;
					send_msg_wait = 0;
					xdbg(MH, "send: discarding - %04X\n", call AMPacket.destination(_msg));
					signal AMSend.sendDone[call AMPacket.type(_msg)](_msg, FAIL);
					break;
				}
			}
		}

		// stop timer if not needed

		if(send_msg_wait == 0) {
			for(i = 0; i < MH_FORWARDING_BUFERS; i++) {
				if(fwd[i].msg_wait > 0) 
					break;
			}
			if(i == MH_FORWARDING_BUFERS) 
				call Timer.stop();
		}
		xdbg_flush(MH);
	}

	// AMSend (L4)

	command error_t AMSend.send[am_id_t am](am_addr_t destination, message_t * msg, uint8_t len) {
		if(send_msg) 
			return EBUSY;

		call AMPacket.setType(msg, am);
		call AMPacket.setDestination(msg, destination);
		call AMPacket.setSource(msg, call AMPacket.address());
		call Packet.setPayloadLength(msg, len);

		switch(call RouteSelect.selectRoute(msg)) {
			case MH_SEND : {
				send_msg = msg;
				if(subsend_msg == NULL) {
					error_t err;
					subsend_msg = msg;
					subsend_fwd_sent = FALSE;
					xdbg(MH, "amsend: sent type %u\n", am);
					err = call SubSend.send(call SubAMPacket.destination(subsend_msg), subsend_msg, call SubPacket.payloadLength(subsend_msg));
					if(err != SUCCESS) {
						xdbg(MH, "amsend: sent err\n");
						subsend_msg = NULL;
						send_msg = NULL;
					}
					return err;
				}
				xdbg(MH, "amsend: subsend busy\n");
				xdbg_flush(MH);
				return SUCCESS;
			}
			case MH_WAIT : {
				send_msg = msg;
				send_msg_wait = MH_WAIT_BEFORE_RETRY * MH_RETRIES;
				if( ! call Timer.isRunning()) 
					call Timer.startPeriodic(MH_TIMER_CYCLE);
				xdbg(MH, "amsend: retry route later - %04X\n", destination);
				xdbg_flush(MH);
				return SUCCESS;
			}
			default : {
				// send to self ?
				xdbg(MH, "amsend: discarding - %04X\n", destination);
				return FAIL;
			}
		}
	}

	task void CancelTask() {
		message_t * _msg = send_msg;
		send_msg = NULL;
		send_msg_wait = 0;
		send_canceled = FALSE;
		signal AMSend.sendDone[call AMPacket.type(_msg)](_msg, ECANCEL);
		send(FALSE);
	}

	command error_t AMSend.cancel[am_id_t am](message_t * msg) {
		if(send_msg != msg) 
			return FAIL;
		if(send_msg == subsend_msg){ // live
			return call SubSend.cancel(subsend_msg);
		}
		else {
			if( ! send_canceled){ // waiting
				send_canceled = TRUE;
				post CancelTask();
			}
			return SUCCESS;
		}
	}

	command void * AMSend.getPayload[am_id_t am](message_t * msg, uint8_t len) {
		return call Packet.getPayload(msg, len);
	}

	command uint8_t AMSend.maxPayloadLength[am_id_t am]() {
		return call Packet.maxPayloadLength();
	}

	// SubSend

	event void SubSend.sendDone(message_t * msg, error_t e) {
		xdbg(MH, "subsend done\n");

		if(subsend_msg != msg) {
			xdbg(MH, "subsend: wrong msg\n");
			xdbg_flush(MH);
			return;
		}

		subsend_msg = NULL;
		if(send_msg == msg) {
			xdbg(MH, "subsend: signaling upper sendDone\n");
			send_msg = NULL;
			signal AMSend.sendDone[call AMPacket.type(msg)](msg, e);
		}
		else {
			uint8_t i;
			for(i = 0; i < MH_FORWARDING_BUFERS; i++) {
				if(fwd[i].msg == msg) {
					// move buffer to keep in order delivery
					memmove(fwd + i, fwd + i + 1, (MH_FORWARDING_BUFERS - i - 1) * sizeof(mh_fwd_t));
					fwd[MH_FORWARDING_BUFERS - 1].msg = msg;
					fwd[MH_FORWARDING_BUFERS - 1].free = TRUE;
					fwd[MH_FORWARDING_BUFERS - 1].msg_wait = 0;
					break;
				}
			}

		}

		send(FALSE);
	}

	// SubReceive

	uint8_t fwd_getfree(){ // find first free
		uint8_t i, candidate = MH_FORWARDING_BUFERS, candidate_min_wait = ~0;
		for(i = 0; i < MH_FORWARDING_BUFERS; i++) {
			if(fwd[i].free) 
				break;
			if((fwd[i].msg_wait > 0)&&(fwd[i].msg_wait < candidate_min_wait)) {
				candidate_min_wait = fwd[i].msg_wait;
				candidate = i;
			}
		}
		if((i == MH_FORWARDING_BUFERS)&&(candidate != MH_FORWARDING_BUFERS)){// drop longest waiting candidate
			message_t * _msg = fwd[candidate].msg;
			// move buffer to keep in order delivery
			memmove(fwd + candidate, fwd + candidate + 1, (MH_FORWARDING_BUFERS - candidate - 1) * sizeof(mh_fwd_t));
			i = MH_FORWARDING_BUFERS - 1; // point to free entry
			fwd[MH_FORWARDING_BUFERS - 1].msg = _msg;
			fwd[MH_FORWARDING_BUFERS - 1].free = TRUE;
			fwd[MH_FORWARDING_BUFERS - 1].msg_wait = 0;
		}
		return i; // MH_FORWARDING_BUFERS == no free
	}

	event message_t * SubReceive.receive(message_t * msg, void * payload, uint8_t len) {
		xdbg(MH, "subrecieve from %04X\n", call SubAMPacket.source(msg));
		
		if (len < sizeof(mhpacket_header_t)) {
			xdbg(MH, "subrecieve: packet too small\n");
			xdbg_flush(MH);
			return msg;
		}

		switch(call RouteSelect.selectRoute(msg)) {
			case MH_SEND : {
				if(signal Intercept.forward[call AMPacket.type(msg)](msg, payload + sizeof(mhpacket_header_t), len - sizeof(mhpacket_header_t))) {
					uint8_t fwd_free = fwd_getfree();
					message_t * fwd_free_msg;
					if(fwd_free == MH_FORWARDING_BUFERS) {
						xdbg(MH, "subrecieve: fwd discarding, no free buffers\n");
						xdbg_flush(MH);
						return msg;
					}
					fwd_free_msg = fwd[fwd_free].msg;
					fwd[fwd_free].msg = msg;
					fwd[fwd_free].free = FALSE;
					fwd[fwd_free].msg_wait = 0;
					if((subsend_msg == NULL)&&((!subsend_fwd_sent) || (send_msg == NULL) || (send_msg_wait > 0))) {
						subsend_msg = msg;
						subsend_fwd_sent = TRUE;
						xdbg(MH, "subrecieve: fwd sent\n");
						if(call SubSend.send(call SubAMPacket.destination(msg), msg, len) != SUCCESS) {
							fwd[fwd_free].free = TRUE;
							subsend_msg = NULL;
							subsend_fwd_sent = FALSE;
							xdbg(MH, "subrecieve: fwd sent error\n");
						}
					}
					else {
						xdbg(MH, "subrecieve: fwd subsend busy.\n");
					}
					xdbg_flush(MH);
					return fwd_free_msg;
				}
				return msg;
			}

			case MH_RECEIVE : {
				xdbg(MH, "subrecieve: signaling upper receive type %u\n",call AMPacket.type(msg));
				return signal Receive.receive[call AMPacket.type(msg)](msg, payload + sizeof(mhpacket_header_t), len - sizeof(mhpacket_header_t));
			}

			case MH_WAIT : {
				if(signal Intercept.forward[call AMPacket.type(msg)](msg, payload + sizeof(mhpacket_header_t), len - sizeof(mhpacket_header_t))) {
					uint8_t fwd_free = fwd_getfree();
					message_t * fwd_free_msg;
					if(fwd_free == MH_FORWARDING_BUFERS) {
						xdbg(MH, "subrecieve: fwd discarding, no free buffers\n");
						xdbg_flush(MH);
						return msg;
					}
					fwd_free_msg = fwd[fwd_free].msg;
					fwd[fwd_free].msg = msg;
					fwd[fwd_free].free = FALSE;
					fwd[fwd_free].msg_wait = MH_WAIT_BEFORE_RETRY * MH_RETRIES;
					if( ! call Timer.isRunning()) 
						call Timer.startPeriodic(MH_TIMER_CYCLE);
					return fwd_free_msg;
				}
				return msg;
			}
			default : {
				xdbg(MH, "subrecieve: fwd discarding\n");
				xdbg_flush(MH);
				return msg;
			}
		}
	}

	// Timer

	event void Timer.fired() {
		uint8_t i;
		if(send_msg_wait > 0) 
			send_msg_wait--;

		for(i = 0; i < MH_FORWARDING_BUFERS; i++) {
			if(fwd[i].msg_wait > 0) 
				fwd[i].msg_wait--;
		}
		send(TRUE);
	}

	// Packet

	command void Packet.clear(message_t * msg) {
		void * p = call SubPacket.getPayload(msg, sizeof(mhpacket_header_t));
		call SubPacket.clear(msg);
		if( ! p) {
			memset(p, sizeof(mhpacket_header_t), 0);
		}
	}

	command void * Packet.getPayload(message_t * msg, uint8_t len) {
		void * p = call SubPacket.getPayload(msg, len + sizeof(mhpacket_header_t));
		if( ! p) 
			return NULL;
		return(void * )(p + sizeof(mhpacket_header_t));
	}

	command uint8_t Packet.maxPayloadLength() {
		uint8_t len = call SubPacket.maxPayloadLength();
		if(len < sizeof(mhpacket_header_t)) 
			return 0; // packet size not for header maybe static check ?
		return len - sizeof(mhpacket_header_t);
	}

	command uint8_t Packet.payloadLength(message_t * amsg) {
		uint8_t len = call SubPacket.payloadLength(amsg);
		if(len < sizeof(mhpacket_header_t)) 
			return 0; // malformed msg ?
		return len - sizeof(mhpacket_header_t);
	}

	command void Packet.setPayloadLength(message_t * amsg, uint8_t len) {
		call SubPacket.setPayloadLength(amsg, len + sizeof(mhpacket_header_t));
	}

	// AMPacket

	command am_addr_t AMPacket.address() {
		return call SubAMPacket.address();
	}

	command am_addr_t AMPacket.destination(message_t * amsg) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		if( ! mhhdr) 
			return 0; // malformed msg ?
		return mhhdr->dest;
	}

	command am_addr_t AMPacket.source(message_t * amsg) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		if( ! mhhdr) 
			return 0; // malformed msg ?
		return mhhdr->src;
	}

	command void AMPacket.setDestination(message_t * amsg, am_addr_t addr) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		if( ! mhhdr) 
			return; // malformed msg ?
		mhhdr->dest = addr;
	}

	command void AMPacket.setSource(message_t * amsg, am_addr_t addr) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		if( ! mhhdr) 
			return; // malformed msg ?
		mhhdr->src = addr;
	}

	command bool AMPacket.isForMe(message_t * amsg) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		if( ! mhhdr) 
			return FALSE; // malformed msg ?
		return((mhhdr->dest == call AMPacket.address()) || (mhhdr->dest == AM_BROADCAST_ADDR));
	}

	command am_id_t AMPacket.type(message_t * amsg) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		if( ! mhhdr) 
			return 0; // malformed msg ?
		return mhhdr->type;
	}

	command void AMPacket.setType(message_t * amsg, am_id_t t) {
		mhpacket_header_t * mhhdr = call SubPacket.getPayload(amsg, sizeof(mhpacket_header_t));
		call SubAMPacket.setType(amsg, AM_MH);
		if( ! mhhdr) 
			return; // malformed msg ?
		mhhdr->type = t;
	}

	command am_group_t AMPacket.group(message_t * amsg) {
		return call SubAMPacket.group(amsg);
	}

	command void AMPacket.setGroup(message_t * amsg, am_group_t grp) {
		call SubAMPacket.setGroup(amsg, grp);
	}

	command am_group_t AMPacket.localGroup() {
		return call SubAMPacket.localGroup();
	}

	// default event handling

	default event message_t * Receive.receive[am_id_t am](message_t * msg, void * payload, uint8_t len) {
		return msg;
	}

	default event void AMSend.sendDone[am_id_t am](message_t * msg, error_t e) {
	}

	default event bool Intercept.forward[am_id_t am](message_t * msg, void * payload, uint8_t len) {
		return TRUE;
	}

	// TODO: L3 ACKS not implemented

	async command error_t Acks.requestAck(message_t * msg) {
		return FAIL;

	}

	async command error_t Acks.noAck(message_t * msg) {
		return FAIL;
	}

	async command bool Acks.wasAcked(message_t * msg) {
		return FALSE;
	}

}
