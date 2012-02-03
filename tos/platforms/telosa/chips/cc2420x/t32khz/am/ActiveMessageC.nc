/*
 * Copyright (c) 2011, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */ 

#include <RadioConfig.h>

configuration ActiveMessageC
{
	provides
	{
		interface SplitControl;

		interface AMSend[uint8_t id];
		interface Receive[uint8_t id];
		interface Receive as Snoop[uint8_t id];
		interface SendNotifier[am_id_t id];

		interface Packet;
		interface AMPacket;

		interface PacketAcknowledgements;
		interface LowPowerListening;
		interface PacketLink;
		interface RadioChannel;

		interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	components CC2420XActiveMessageC as MessageC;

	SplitControl = MessageC;

	AMSend = MessageC;
	Receive = MessageC.Receive;
	Snoop = MessageC.Snoop;
	SendNotifier = MessageC;

	Packet = MessageC;
	AMPacket = MessageC;

	PacketAcknowledgements = MessageC;
	LowPowerListening = MessageC;
	PacketLink = MessageC;
	RadioChannel = MessageC;

	PacketTimeStampMilli = MessageC.PacketTimeStampMilli;
	PacketTimeStamp32khz = MessageC.PacketTimeStampRadio;
}
