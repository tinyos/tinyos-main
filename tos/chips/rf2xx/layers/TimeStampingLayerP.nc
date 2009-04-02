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
	}

	uses
	{
		interface PacketFlag as TimeStampFlag;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface LocalTime<TMilli> as LocalTimeMilli;

		interface PacketData<timestamp_metadata_t> as PacketTimeStampMetadata;
	}
}

implementation
{
	async command bool PacketTimeStampRadio.isValid(message_t* msg)
	{
		return call TimeStampFlag.get(msg);
	}

	async command uint32_t PacketTimeStampRadio.timestamp(message_t* msg)
	{
		return (call PacketTimeStampMetadata.get(msg))->timestamp;
	}

	async command void PacketTimeStampRadio.clear(message_t* msg)
	{
		call TimeStampFlag.clear(msg);
	}

	async command void PacketTimeStampRadio.set(message_t* msg, uint32_t value)
	{
		call TimeStampFlag.set(msg);
		(call PacketTimeStampMetadata.get(msg))->timestamp = value;
	}

	async event void PacketTimeStampMetadata.clear(message_t* msg)
	{
	}

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
}
