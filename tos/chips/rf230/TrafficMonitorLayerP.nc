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
 * PROVIDE MAINTENANCE, SUPPORT, reportS, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#include <Tasklet.h>

/*
 * You have to make sure that the maximum channel time in one report
 * period times (1 << TRAFFIC_MONITOR_DECAY) is less than 65535.
 */
#ifndef TRAFFIC_MONITOR_DECAY
#define TRAFFIC_MONITOR_DECAY	3
#endif

module TrafficMonitorLayerP
{
	provides
	{
		interface RadioSend;
		interface RadioReceive;
		interface RadioState;
	}

	uses
	{
		interface TrafficMonitorConfig;
		interface RadioSend as SubSend;
		interface RadioReceive as SubReceive;
		interface RadioState as SubState;
		interface Timer<TMilli> as Timer;
		interface Neighborhood;
		interface NeighborhoodFlag;
		interface Tasklet;
#ifdef RF230_DEBUG
		interface DiagMsg;
#endif
	}
}

implementation
{
	tasklet_norace message_t *txMsg;
	tasklet_norace uint8_t neighborCount;

	tasklet_norace uint16_t txAverage;
	tasklet_norace uint16_t rxAverage;
	tasklet_norace uint8_t neighborAverage;
	tasklet_norace uint8_t errorAverage;

	enum
	{
		// the maximum average value
		TRAFFIC_MONITOR_UINT8_MAX = 1 << (7-TRAFFIC_MONITOR_DECAY),

		// the unsignificant bits of the averaged values
		TRAFFIC_MONITOR_MASK = (1 << TRAFFIC_MONITOR_DECAY) - 1,

		// to get the ceiling integer value
		TRAFFIC_MONITOR_ROUND_UP = (1 << TRAFFIC_MONITOR_DECAY) - 1,
	};

	tasklet_async event void SubSend.ready()
	{
		signal RadioSend.ready();
	}

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		txMsg = msg;
		return call SubSend.send(msg);
	}

	tasklet_async event void SubSend.sendDone(error_t error)
	{
		if( error == SUCCESS )
			txAverage += call TrafficMonitorConfig.getChannelTime(txMsg);

		signal RadioSend.sendDone(error);
	}

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		return signal RadioReceive.header(msg);
	}

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		uint8_t index;

		rxAverage += call TrafficMonitorConfig.getChannelTime(msg);

		index = call Neighborhood.insertNode(call TrafficMonitorConfig.getSender(msg));
		if( ! call NeighborhoodFlag.get(index) )
		{
			if( neighborCount < TRAFFIC_MONITOR_UINT8_MAX )
			{
				++neighborCount;
				call NeighborhoodFlag.set(index);
			}
		}

		return signal RadioReceive.receive(msg);
	}

	tasklet_async event void TrafficMonitorConfig.channelError()
	{
		if( errorAverage < 255 )
			++errorAverage;
	}

	uint8_t debugCounter;

	event void Timer.fired()
	{
		uint8_t fraction;

		call Tasklet.suspend();

		txAverage -= (txAverage >> TRAFFIC_MONITOR_DECAY);
		rxAverage -= (rxAverage >> TRAFFIC_MONITOR_DECAY);
		errorAverage -= (errorAverage >> TRAFFIC_MONITOR_DECAY);

		// we could get stuck in the [1,7] range with no neighbors, so be more precise
		fraction = neighborAverage >> TRAFFIC_MONITOR_DECAY;
		if( fraction == neighborCount && (neighborAverage & TRAFFIC_MONITOR_MASK) != 0 )
			--neighborAverage;
		else
			neighborAverage += neighborCount - fraction;

		call NeighborhoodFlag.clearAll();
		neighborCount = 0;

		call TrafficMonitorConfig.timerTick();

		call Tasklet.resume();

#ifdef RF230_DEBUG
		if( ++debugCounter >= 10 && call DiagMsg.record() )
		{
			debugCounter = 0;

			call DiagMsg.str("traffic");
			call DiagMsg.uint16(signal TrafficMonitorConfig.getTransmitAverage());
			call DiagMsg.uint16(signal TrafficMonitorConfig.getReceiveAverage());
			call DiagMsg.uint8(signal TrafficMonitorConfig.getNeighborAverage());
			call DiagMsg.uint8(signal TrafficMonitorConfig.getErrorAverage());
			call DiagMsg.send();
		}
#endif
	}

	tasklet_async event void Tasklet.run()
	{
	}

	tasklet_async event uint16_t TrafficMonitorConfig.getTransmitAverage()
	{
		return txAverage >> TRAFFIC_MONITOR_DECAY;
	}

	tasklet_async event uint16_t TrafficMonitorConfig.getReceiveAverage()
	{
		return rxAverage >> TRAFFIC_MONITOR_DECAY;
	}

	tasklet_async event uint8_t TrafficMonitorConfig.getNeighborAverage()
	{
		return (neighborAverage + TRAFFIC_MONITOR_ROUND_UP) >> TRAFFIC_MONITOR_DECAY;
	}

	tasklet_async event uint8_t TrafficMonitorConfig.getErrorAverage()
	{
		return errorAverage >> TRAFFIC_MONITOR_DECAY;
	}

	tasklet_async event void Neighborhood.evicted(uint8_t index) { }

	enum
	{
		RADIO_CMD_NONE = 0,
		RADIO_CMD_TURNON = 1,
		RADIO_CMD_TURNOFF = 2,
	};
	tasklet_norace uint8_t radioCmd;

	tasklet_async command error_t RadioState.turnOff()
	{
		radioCmd = RADIO_CMD_TURNOFF;
		return call SubState.turnOff();
	}

	tasklet_async command error_t RadioState.standby()
	{
		radioCmd = RADIO_CMD_TURNOFF;
		return call SubState.standby();
	}

	tasklet_async command error_t RadioState.turnOn()
	{
		radioCmd = RADIO_CMD_TURNON;
		return call SubState.turnOn();
	}

	tasklet_async command error_t RadioState.setChannel(uint8_t channel)
	{
		radioCmd = RADIO_CMD_NONE;
		return call SubState.setChannel(channel);
	}

	task void startStopTimer()
	{
		if( radioCmd == RADIO_CMD_TURNON )
			call Timer.startPeriodic(call TrafficMonitorConfig.getUpdatePeriod());
		else if( radioCmd == RADIO_CMD_TURNOFF )
			call Timer.stop();
	}

	tasklet_async event void SubState.done()
	{
		post startStopTimer();
		signal RadioState.done();
	}
}
