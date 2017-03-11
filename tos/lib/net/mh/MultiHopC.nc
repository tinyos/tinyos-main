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
 * The Multihop Active Message layer 
 *  - provides same interface as Active Message to application (L3,L4)
 *  - using the Active Message layer (AMReceiverC,AMSenderC) as a transport link protocol (L2) (protocol id AM_MH)
 *  - using external implementation of some routing protocol (RouteSelect)
 *
 * @author Martin Cerveny
 */

#include "MH.h"
#include "MH_private.h"

configuration MultiHopC {
	provides {
		// L4
		interface AMSend as AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Intercept[am_id_t id];
		interface PacketAcknowledgements as Acks;

		// L3 (used in RouteSelect) 
		interface AMPacket;
		interface Packet;

		// other
		interface SplitControl;
	}
	uses {
		interface RouteSelect;
	}
}

implementation {
	components MultiHopM;

	// provides
	// L4
	AMSend = MultiHopM.AMSend;
	Receive = MultiHopM.Receive;
	Intercept = MultiHopM.Intercept;
	Acks = MultiHopM.Acks;

	// L3
	AMPacket = MultiHopM.AMPacket;
	Packet = MultiHopM.Packet;

	// other 
	MultiHopM.RouteSelect = RouteSelect;

	// other
	SplitControl = ActiveMessageC.SplitControl;

	// internal
	components ActiveMessageC;
	components new AMReceiverC(AM_MH) as MHReceiver;
	components new AMSenderC(AM_MH) as MHSender;

	// L2
	MultiHopM.SubAMPacket->ActiveMessageC.AMPacket;
	MultiHopM.SubPacket->ActiveMessageC.Packet;
	MultiHopM.SubSend->MHSender;
	MultiHopM.SubReceive->MHReceiver;

	// other
	components new TimerMilliC();
	components MainC;
	MultiHopM.Timer->TimerMilliC;
	MainC.SoftwareInit->MultiHopM;
	
	// debug led support
	components LedsC;
	MultiHopM.Leds->LedsC;
}