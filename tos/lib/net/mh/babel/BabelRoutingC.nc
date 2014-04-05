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
 * The Babel routing protocol 
 *  - provides interface for Multihop packet forwarder (RouteSelect) 
 *  - using the Active Message layer (AMReceiverC,AMSenderC) for routing protocol exchange (protocol id AM_BABEL)
 *
 * @author Martin Cerveny
 */

#include "Timer.h"
#define NEW_PRINTF_SEMANTICS 1
#include "printf.h"

#include "Babel.h"
#include "Babel_private.h"

configuration BabelRoutingC {
	// L3
	provides interface RouteSelect;
	// infos
	provides interface TableReader as NeighborTable;
	provides interface TableReader as RoutingTable;	
	// L3 packet from forwarding engine
	uses interface Packet;
	uses interface AMPacket;
}

implementation {
	components BabelRoutingM, MainC;
	components new TimerMilliC() as Timer;

	RouteSelect = BabelRoutingM.RouteSelect;
	Packet = BabelRoutingM.L3Packet;
	AMPacket = BabelRoutingM.L3AMPacket;
	
	MainC<-BabelRoutingM.Boot;

	BabelRoutingM.Timer->Timer;

	components new AMSenderC(AM_BABEL);
	components new AMReceiverC(AM_BABEL);

	BabelRoutingM.Packet->AMSenderC;
	BabelRoutingM.AMPacket->AMSenderC;
	BabelRoutingM.AMSend->AMSenderC;
	BabelRoutingM.Receive->AMReceiverC;

	components ActiveMessageC, LocalIeeeEui64C, ActiveMessageAddressC;

	BabelRoutingM.AMControl->ActiveMessageC;
	BabelRoutingM.PacketRSSI->ActiveMessageC.PacketRSSI;
	BabelRoutingM.PacketLinkQuality->ActiveMessageC.PacketLinkQuality;

	BabelRoutingM.LocalIeeeEui64->LocalIeeeEui64C;

	BabelRoutingM.ActiveMessageAddress->ActiveMessageAddressC;

	// table read
		
	NeighborTable = BabelRoutingM.NeighborTable;
	RoutingTable = BabelRoutingM.RoutingTable;
	
	// debug led support
	components new TimerMilliC() as TimerLed;
	BabelRoutingM.TimerLed->TimerLed;
	components LedsC;
	BabelRoutingM.Leds->LedsC;
}