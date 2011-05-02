/*
 * Copyright (c) 2011, University of Szeged
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
 * - Neither the name of the copyright holder nor the names of
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
 *
 * Author: Miklos Maroti
 */

// Shift is positive, if TOther has less precision (is slower) than TRadio
generic module TimeConverterLayerC(typedef TOther, int8_t shift)
{
	provides
	{
		interface TimeSyncAMSend<TOther, uint32_t> as TimeSyncAMSendOther[am_id_t id];
		interface TimeSyncPacket<TOther, uint32_t> as TimeSyncPacketOther;
		interface PacketTimeStamp<TOther, uint32_t> as PacketTimeStampOther;
	}

	uses
	{
		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface LocalTime<TOther> as LocalTimeOther;
	}
}

implementation
{
	// Converts TRadio time to TOther time
	uint32_t convertRadioToOther(uint32_t radioTime)
	{
		uint32_t localTimeRadio, localTimeOther;
		int32_t elapsedTime;

		atomic
		{
			localTimeRadio = call LocalTimeRadio.get();
			localTimeOther = call LocalTimeOther.get();
		}

		elapsedTime = radioTime - localTimeRadio;

		if( shift > 0 )
			elapsedTime >>= shift;
		else if( shift < 0 )
			elapsedTime <<= -shift;

		return elapsedTime + localTimeOther;
	}

	// Converts TOther time to TRadio time
	uint32_t convertOtherToRadio(uint32_t otherTime)
	{
		uint32_t localTimeRadio, localTimeOther;
		int32_t elapsedTime;

		atomic
		{
			localTimeRadio = call LocalTimeRadio.get();
			localTimeOther = call LocalTimeOther.get();
		}

		elapsedTime = otherTime - localTimeOther;

		if( shift > 0 )
			elapsedTime <<= shift;
		else if( shift < 0 )
			elapsedTime >>= -shift;

		return elapsedTime + localTimeRadio;
	}

/*----------------- PacketTimeStampOther -----------------*/

	async command bool PacketTimeStampOther.isValid(message_t* msg)
	{
		return call PacketTimeStampRadio.isValid(msg);
	}

	async command uint32_t PacketTimeStampOther.timestamp(message_t* msg)
	{
		return convertRadioToOther(call PacketTimeStampRadio.timestamp(msg));
	}

	async command void PacketTimeStampOther.clear(message_t* msg)
	{
		call PacketTimeStampRadio.clear(msg);
	}

	async command void PacketTimeStampOther.set(message_t* msg, uint32_t value)
	{
		call PacketTimeStampRadio.set(msg, convertOtherToRadio(value));
	}

/*----------------- TimeSyncAMSendOther -----------------*/

	command error_t TimeSyncAMSendOther.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t eventTime)
	{
		return call TimeSyncAMSendRadio.send[id](addr, msg, len, convertOtherToRadio(eventTime));
	}

	event void TimeSyncAMSendRadio.sendDone[am_id_t id](message_t* msg, error_t error)
	{
		signal TimeSyncAMSendOther.sendDone[id](msg, error);
	}

	command error_t TimeSyncAMSendOther.cancel[am_id_t id](message_t* msg)
	{
		return call TimeSyncAMSendRadio.cancel[id](msg);
	}

	default event void TimeSyncAMSendOther.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	command uint8_t TimeSyncAMSendOther.maxPayloadLength[am_id_t id]()
	{
		return call TimeSyncAMSendRadio.maxPayloadLength[id]();
	}

	command void* TimeSyncAMSendOther.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call TimeSyncAMSendRadio.getPayload[id](msg, len);
	}

/*----------------- TimeSyncPacketOther -----------------*/

	command bool TimeSyncPacketOther.isValid(message_t* msg)
	{
		return call TimeSyncPacketRadio.isValid(msg);
	}

	command uint32_t TimeSyncPacketOther.eventTime(message_t* msg)
	{
		return convertRadioToOther(call TimeSyncPacketRadio.eventTime(msg));
	}
}
