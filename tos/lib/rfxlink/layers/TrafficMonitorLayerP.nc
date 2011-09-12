/*
 * Copyright (c) 2007-2011, Vanderbilt University
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
 *
 * Author: Miklos Maroti
 */

#include "Tasklet.h"

generic module TrafficMonitorLayerP()
{
	provides
	{
		interface RadioSend;
		interface RadioReceive;
		interface RadioState;
		interface TrafficMonitor;
	}

	uses
	{
		interface TrafficMonitorConfig;
		interface RadioSend as SubSend;
		interface RadioReceive as SubReceive;
		interface RadioState as SubState;
		interface LocalTime<TMilli>;

#ifdef RADIO_DEBUG
		interface Boot;
		interface Timer<TMilli> as Timer;
		interface DiagMsg;
#endif
	}
}

implementation
{
// ------- Send

	tasklet_async event void SubSend.ready()
	{
		signal RadioSend.ready();
	}

	uint32_t txMessages;
	uint32_t txBytes;
	uint32_t txErrors;

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		error_t error;

		error = call SubSend.send(msg);

		if( error == SUCCESS )
		{
			uint16_t bytes = call TrafficMonitorConfig.getBytes(msg);

			atomic
			{
				txMessages += 1;
				txBytes += bytes;
			}
		}
		else
			atomic txErrors += 1;

		return error;
	}

	tasklet_async event void SubSend.sendDone(error_t error)
	{
		if( error != SUCCESS )
			atomic txErrors += 1;

		signal RadioSend.sendDone(error);
	}

	async command uint32_t TrafficMonitor.getTxMessages()
	{
		atomic return txMessages;
	}

	async command uint32_t TrafficMonitor.getTxBytes()
	{
		atomic return txBytes;
	}

	async command uint32_t TrafficMonitor.getTxErrors()
	{
		atomic return txErrors;
	}

// ------- Receive

	uint32_t rxMessages;
	uint32_t rxBytes;

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		return signal RadioReceive.header(msg);
	}

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		uint16_t bytes = call TrafficMonitorConfig.getBytes(msg);

		atomic
		{
			rxMessages += 1;
			rxBytes += bytes;
		}

		return signal RadioReceive.receive(msg);
	}

	async command uint32_t TrafficMonitor.getRxMessages()
	{
		atomic return rxMessages;
	}

	async command uint32_t TrafficMonitor.getRxBytes()
	{
		atomic return rxBytes;
	}

// ------- Start/Stop

	enum
	{
		RADIO_OFF = 0,
		RADIO_ON = 1,
		RADIO_ON_2_OFF = 2,
	};

	uint8_t radioState;
	uint32_t radioStart;

	uint32_t activeTime;
	uint32_t startCount;

	tasklet_async command error_t RadioState.turnOn()
	{
		uint32_t localTime = call LocalTime.get();
		error_t error = call SubState.turnOn();

		atomic
		{
			if( radioState == RADIO_OFF && error == SUCCESS )
			{
				radioStart = localTime;
				radioState = RADIO_ON;
				startCount++;
			}
		}

		return error;
	}

	tasklet_async command error_t RadioState.turnOff()
	{
		error_t error = call SubState.turnOff();

		atomic
		{
			if( radioState == RADIO_ON && error == SUCCESS )
				radioState = RADIO_ON_2_OFF;
		}

		return error;
	}

	tasklet_async command error_t RadioState.standby()
	{
		error_t error = call SubState.standby();

		atomic
		{
			if( radioState == RADIO_ON && error == SUCCESS )
				radioState = RADIO_ON_2_OFF;
		}

		return error;
	}


	tasklet_async event void SubState.done()
	{
		uint32_t localTime = call LocalTime.get();

		atomic
		{
			if( radioState == RADIO_ON_2_OFF )
			{
				activeTime += localTime - radioStart;
				radioState = RADIO_OFF;
			}
		}

		signal RadioState.done();
	}

	tasklet_async command error_t RadioState.setChannel(uint8_t channel)
	{
		return call SubState.setChannel(channel);
	}

	tasklet_async command uint8_t RadioState.getChannel()
	{
		return call SubState.getChannel();
	}

	async command uint32_t TrafficMonitor.getStartCount()
	{
		atomic return startCount;
	}

	async command uint32_t TrafficMonitor.getActiveTime()
	{
		uint32_t atime, localTime;
		
		localTime = call LocalTime.get();

		atomic
		{
			atime = activeTime;
			if( radioState != RADIO_OFF )
				atime += localTime - radioStart;
		}

		return atime;
	}

	async command uint32_t TrafficMonitor.getCurrentTime()
	{
		return call LocalTime.get();
	}

// ------- Debug

#ifdef RADIO_DEBUG
	event void Boot.booted()
	{
		// print out statistics every second
		call Timer.startPeriodic(1024);
	}

	event void Timer.fired()
	{
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("rfx");
			call DiagMsg.uint16(call TrafficMonitor.getStartCount());
			call DiagMsg.uint32(call TrafficMonitor.getActiveTime());
			call DiagMsg.uint16(call TrafficMonitor.getTxMessages());
			call DiagMsg.uint16(call TrafficMonitor.getRxMessages());
			call DiagMsg.uint16(call TrafficMonitor.getTxBytes());
			call DiagMsg.uint16(call TrafficMonitor.getRxBytes());
			call DiagMsg.uint16(call TrafficMonitor.getTxErrors());
			call DiagMsg.send();
		}
	}
#endif
}
