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

#include <RadioConfig.h>
#include <TimeStampingLayer.h>

module TimeStampingLayerP
{
	provides
	{
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface RadioPacket;
	}

	uses
	{
		interface PacketFlag as TimeStampFlag;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface LocalTime<TMilli> as LocalTimeMilli;

		interface RadioPacket as SubPacket;
	}
}

implementation
{
	timestamp_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

/*----------------- PacketTimeStampRadio -----------------*/
	
	async command bool PacketTimeStampRadio.isValid(message_t* msg)
	{
		return call TimeStampFlag.get(msg);
	}

	async command uint32_t PacketTimeStampRadio.timestamp(message_t* msg)
	{
		return getMeta(msg)->timestamp;
	}

	async command void PacketTimeStampRadio.clear(message_t* msg)
	{
		call TimeStampFlag.clear(msg);
	}

	async command void PacketTimeStampRadio.set(message_t* msg, uint32_t value)
	{
		call TimeStampFlag.set(msg);
		getMeta(msg)->timestamp = value;
	}

/*----------------- PacketTimeStampMilli -----------------*/

	async command bool PacketTimeStampMilli.isValid(message_t* msg)
	{
		return call PacketTimeStampRadio.isValid(msg);
	}

	async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg)
	{
		int32_t offset = call PacketTimeStampRadio.timestamp(msg) - call LocalTimeRadio.get();

		return (offset >> RADIO_ALARM_MILLI_EXP) + call LocalTimeMilli.get();
	}

	async command void PacketTimeStampMilli.clear(message_t* msg)
	{
		call PacketTimeStampRadio.clear(msg);
	}

	async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value)
	{
		int32_t offset = (value - call LocalTimeMilli.get()) << RADIO_ALARM_MILLI_EXP;

		call PacketTimeStampRadio.set(msg, offset + call LocalTimeRadio.get());
	}

/*----------------- RadioPacket -----------------*/
	
	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg);
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length);
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength();
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg) + sizeof(timestamp_metadata_t);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		// all flags are automatically cleared
		call SubPacket.clear(msg);
	}
}
