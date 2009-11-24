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

module RadioCountToDiagP
{
	uses
	{
		interface Boot;
		interface DiagMsg;

		interface Timer<TMilli> as SendTimer;
		interface Timer<TMilli> as ReportTimer;

		interface Receive;
		interface AMSend;
		interface PacketAcknowledgements;
		interface AMPacket;
		interface Packet;

		interface SplitControl as SerialControl;
		interface SplitControl as RadioControl;

		interface ActiveMessageAddress;
		interface LowPowerListening;

		interface Leds;
	}
}

#ifndef SEND_PERIOD
#define SEND_PERIOD 20
#endif

#ifndef SLEEP_INTERVAL
#define SLEEP_INTERVAL	50
#endif

implementation
{
	task void radioPowerUp()
	{
		if( call RadioControl.start() != SUCCESS )
			post radioPowerUp();
	}

	event void RadioControl.startDone(error_t error)
	{
		if( error != SUCCESS )
			post radioPowerUp();
		else
		{
#ifdef LOW_POWER_LISTENING
			call LowPowerListening.setLocalWakeupInterval(SLEEP_INTERVAL);
#endif		
			call SendTimer.startPeriodic(SEND_PERIOD);
			call ReportTimer.startPeriodic(1000);
		}
	}

	event void RadioControl.stopDone(error_t error)
	{
	}
	
	task void serialPowerUp()
	{
		if( call SerialControl.start() != SUCCESS )
			post serialPowerUp();
	}

	event void SerialControl.startDone(error_t error)
	{
		if( error != SUCCESS )
			post serialPowerUp();
		else
			post radioPowerUp();
	}

	event void SerialControl.stopDone(error_t error)
	{
	}

	event void Boot.booted()
	{
		post serialPowerUp();
	}

	async event void ActiveMessageAddress.changed()
	{
	}

	uint32_t sendCount;
	uint32_t sendDoneSuccess;
	uint32_t sendDoneError;
	uint32_t ackedCount;
	uint32_t ackedError;
	uint32_t receiveCount;
	uint32_t receiveMissed;

	event void ReportTimer.fired()
	{
		call Leds.led0Toggle();

		if( call DiagMsg.record() )
		{
			call DiagMsg.uint16(sendCount);
			call DiagMsg.uint16(sendDoneSuccess);
			call DiagMsg.uint16(sendDoneError);
			call DiagMsg.uint16(ackedCount);
			call DiagMsg.uint16(ackedError);
			call DiagMsg.uint16(receiveCount);
			call DiagMsg.uint16(receiveMissed);
			call DiagMsg.send();
		}
	}

	message_t txMsg;

	typedef struct ping_t
	{
		uint8_t seqNo;
		uint8_t stuff[27];
	} ping_t;

	event void SendTimer.fired()
	{
		uint16_t addr;

		call Leds.led1Toggle();
		
		call Packet.clear(&txMsg);
		call PacketAcknowledgements.requestAck(&txMsg);
#ifdef LOW_POWER_LISTENING
		call LowPowerListening.setRemoteWakeupInterval(&txMsg, SLEEP_INTERVAL);
#endif

		addr = call ActiveMessageAddress.amAddress();
		if( addr == 2 )
			addr = 3;
		else if( addr == 3 )
			addr = 2;
		else
			addr = AM_BROADCAST_ADDR;

		if( call AMSend.send(addr, &txMsg, sizeof(ping_t)) == SUCCESS )
			++sendCount;
	}

	event void AMSend.sendDone(message_t* msg, error_t error)
	{
		if( error == SUCCESS )
		{
			ping_t* ping = (ping_t*)txMsg.data;
			++(ping->seqNo);

			++sendDoneSuccess;

			if( call PacketAcknowledgements.wasAcked(&txMsg) )
				++ackedCount;
			else
				++ackedError;
		}
		else
			++sendDoneError;
	}

	uint8_t rxSeqNo;

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		ping_t* ping = (ping_t*)(msg->data);

		++receiveCount;
		receiveMissed += (uint8_t)(ping->seqNo - rxSeqNo - 1);
		rxSeqNo = ping->seqNo;

		return msg;
	}
}
