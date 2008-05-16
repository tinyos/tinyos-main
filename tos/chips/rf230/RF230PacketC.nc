/*
 * Copyright (c) 2007, Vanderbilt University
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
 * Author: Miklos Maroti
 */

#include <HplRF230.h>

configuration RF230PacketC
{
	provides
	{
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint16_t> as PacketSleepInterval;

		interface PacketTimeStamp<TRF230, uint16_t>;
		interface PacketLastTouch;

		async event void lastTouch(message_t* msg);
	}
}

implementation
{
	components RF230PacketP, IEEE154PacketC;

	RF230PacketP.IEEE154Packet -> IEEE154PacketC;

	Packet = RF230PacketP;
	AMPacket = IEEE154PacketC;
	PacketAcknowledgements = RF230PacketP;
	PacketLinkQuality = RF230PacketP.PacketLinkQuality;
	PacketTransmitPower = RF230PacketP.PacketTransmitPower;
	PacketRSSI = RF230PacketP.PacketRSSI;
	PacketSleepInterval = RF230PacketP.PacketSleepInterval;
	PacketTimeStamp = RF230PacketP;

	PacketLastTouch = RF230PacketP;
	lastTouch = RF230PacketP;
}
