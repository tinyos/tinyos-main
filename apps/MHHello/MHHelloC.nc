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
 * Implementation of application.
 * 
 * @author Martin Cerveny
 **/ 

#include "Timer.h"
#define NEW_PRINTF_SEMANTICS 1
#include "printf.h"

#include "IeeeEui64.h"
#include "MH.h"
#include "Babel.h"

module MHHelloC {
	uses interface Timer<TMilli> as Timer;
	uses interface Leds;
	uses interface Boot;

	uses interface LocalIeeeEui64;

	uses interface ActiveMessageAddress;

	// L3/L4
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface TableReader as RoutingTable;
	uses interface SplitControl as MHControl;

	// L2
	uses interface AMPacket as SubAMPacket;
}
implementation {

	uint16_t mhcnt = 0; // incrementing counter
	bool mhbusy = FALSE; // busy send layer flag
	message_t mhpkt; // send packet
	am_addr_t row = AM_BROADCAST_ADDR; // row pointer in routing table, initialized with invalid unicast address  

	event void Boot.booted() {
		uint16_t nodeid;
		ieee_eui64_t eui;

		// set unique short address (if not unique babel reassign address)
		eui = call LocalIeeeEui64.getId();
		nodeid = (eui.data[0] | (eui.data[1] << 8)) ^ (eui.data[2] | (eui.data[3] << 8)) ^ (eui.data[4] | (eui.data[5] << 8)) ^ (eui.data[6] | (eui.data[7] << 8));
		if(( ! nodeid) || ( ! (~nodeid))) 
			nodeid = 1;
		call ActiveMessageAddress.setAddress(TOS_AM_GROUP, nodeid);

		printf("APPL: EUI %02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X NODEID %04X\n", eui.data[7], eui.data[6], eui.data[5], eui.data[4], eui.data[3], eui.data[2], eui
				.data[1], eui.data[0], nodeid);
		printfflush();

		call MHControl.start();
	}

	event void MHControl.startDone(error_t err) {
		if(err == SUCCESS) {
			printf("APPL: started\n");
			call Timer.startPeriodic(200);
		}
		else {
			printf("APPL start error\n");
		}
		printfflush();
	}

	event void MHControl.stopDone(error_t err) {
	}

	async event void ActiveMessageAddress.changed() {
	}

	event void AMSend.sendDone(message_t * msg, error_t error) {
		if(&mhpkt == msg) {
			mhbusy = FALSE;
			printf("APPL: txdone %d\n", error);
			printfflush();
			call Leds.led2Off();
		}
	}

	event message_t * Receive.receive(message_t * msg, void * payload, uint8_t len) {

		if(len == sizeof(uint16_t)) {
			uint16_t * btrpkt = (uint16_t * ) payload;
			
			call Leds.led1On();
			printf("APPL: rxdone: cnt %u L3: %04X L2: %04X\n", *btrpkt, call AMPacket.source(msg), call SubAMPacket.source(msg));
			printfflush();
			call Leds.led1Off();
		}
		return msg;
	}

	event void Timer.fired() {

		if( ! mhbusy) {
			am_addr_t addr;
			uint16_t * btrpkt;

			if(call RoutingTable.rowNext(&row, sizeof(row)) != SUCCESS) {
				if(call RoutingTable.rowFirst(&row, sizeof(row)) != SUCCESS) {
					printf("APPL: empty routing table\n");
					return;
				}
				else 
					mhcnt++;
			}
			if(call RoutingTable.colRead(&row, BABEL_RT_NODEID, &addr, sizeof(addr)) != SUCCESS) {
				printf("APPL: fail to read nodeid\n");
				return;
			}
			if(addr == call ActiveMessageAddress.amAddress()) {
				return;
			}

			btrpkt = (uint16_t * )(call Packet.getPayload(&mhpkt, sizeof(uint16_t)));
			*btrpkt = mhcnt;
			call Leds.led2On();
			printf("APPL: tx cnt %u node %04X\n", mhcnt, addr);
			if(call AMSend.send(addr, &mhpkt, sizeof(uint16_t)) == SUCCESS) {
				mhbusy = TRUE;
			}
			printfflush();
		}
	}

}