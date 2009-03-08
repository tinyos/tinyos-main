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

configuration RF2xxPacketC
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
		interface PacketField<uint8_t> as PacketTimeSyncOffset;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	components RF2xxPacketP, IEEE154PacketC, LocalTimeMicroC, LocalTimeMilliC;

	RF2xxPacketP.IEEE154Packet -> IEEE154PacketC;
	RF2xxPacketP.LocalTimeRadio -> LocalTimeMicroC;
	RF2xxPacketP.LocalTimeMilli -> LocalTimeMilliC;

	Packet = RF2xxPacketP;
	AMPacket = IEEE154PacketC;

	PacketAcknowledgements	= RF2xxPacketP;
	PacketLinkQuality	= RF2xxPacketP.PacketLinkQuality;
	PacketTransmitPower	= RF2xxPacketP.PacketTransmitPower;
	PacketRSSI		= RF2xxPacketP.PacketRSSI;
	PacketSleepInterval	= RF2xxPacketP.PacketSleepInterval;
	PacketTimeSyncOffset	= RF2xxPacketP.PacketTimeSyncOffset;

	PacketTimeStampRadio	= RF2xxPacketP;
	PacketTimeStampMilli	= RF2xxPacketP;
}
