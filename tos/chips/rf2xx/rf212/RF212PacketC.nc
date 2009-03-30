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

configuration RF212PacketC
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
#ifdef PACKET_LINK
		interface PacketData<packet_link_metadata_t> as PaketLinkMetadata;
#endif
	}
}

implementation
{
	components RF212PacketP, IEEE154Packet2C, LocalTimeMicroC, LocalTimeMilliC;

	RF212PacketP.IEEE154Packet2 -> IEEE154Packet2C;
	RF212PacketP.LocalTimeRadio -> LocalTimeMicroC;
	RF212PacketP.LocalTimeMilli -> LocalTimeMilliC;

	Packet = RF212PacketP;
	AMPacket = IEEE154Packet2C;

	PacketAcknowledgements	= RF212PacketP;
	PacketLinkQuality	= RF212PacketP.PacketLinkQuality;
	PacketTransmitPower	= RF212PacketP.PacketTransmitPower;
	PacketRSSI		= RF212PacketP.PacketRSSI;
	PacketSleepInterval	= RF212PacketP.PacketSleepInterval;
	PacketTimeSyncOffset	= RF212PacketP.PacketTimeSyncOffset;

	PacketTimeStampRadio	= RF212PacketP;
	PacketTimeStampMilli	= RF212PacketP;

#ifdef PACKET_LINK
	PaketLinkMetadata	= RF212PacketP;
#endif
}
