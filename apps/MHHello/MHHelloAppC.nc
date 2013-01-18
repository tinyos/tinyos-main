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
 * The application sends periodically unicast hello packet to all known destinations.
 * Packet is send/received with multihop (MHSenderC/MHReceiverC).
 * Routing to multihop engine is provided by babel routing protocol (BabelRoutingC).
 * All destination is enumerated from routing table of babel routing protocol (BabelRoutingC.RoutingTable).
 *
 * @author Martin Cerveny
 **/ 

configuration MHHelloAppC {
}
implementation {
	components MainC, MHHelloC, LedsC;
	components new TimerMilliC() as Timer;

	MHHelloC->MainC.Boot;

	MHHelloC.Timer->Timer;
	MHHelloC.Leds->LedsC;

	components SerialPrintfC;

	components LocalIeeeEui64C;
	MHHelloC.LocalIeeeEui64->LocalIeeeEui64C;

	components ActiveMessageAddressC;
	MHHelloC.ActiveMessageAddress->ActiveMessageAddressC;

	// L4
	components new MHSenderC(0x80+1);
	MHHelloC.Packet->MHSenderC;
	MHHelloC.AMPacket->MHSenderC;
	MHHelloC.AMSend->MHSenderC;
	components new MHReceiverC(0x80+1);
	MHHelloC.Receive -> MHReceiverC;

	// routing (need L3 packet access)
	components BabelRoutingC;
	components MultiHopC;
	BabelRoutingC.RouteSelect<-MultiHopC.RouteSelect;
	BabelRoutingC.Packet->MultiHopC.Packet;
	BabelRoutingC.AMPacket->MultiHopC.AMPacket;

	// other
	MHHelloC.RoutingTable->BabelRoutingC.RoutingTable;
	MHHelloC.MHControl->MultiHopC.SplitControl;
	
	components ActiveMessageC;
	MHHelloC.SubAMPacket -> ActiveMessageC.AMPacket;
}
