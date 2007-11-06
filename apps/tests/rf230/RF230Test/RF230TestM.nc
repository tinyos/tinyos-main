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

#include <Tasklet.h>

module RF230TestM
{
	uses
	{
		interface Leds;
		interface Boot;
		interface DiagMsg;
		interface SplitControl;
		interface Timer<TMilli> as Timer;

		interface RadioState;
		interface AMSend[am_id_t id];
	}
}

implementation
{
	task void serialPowerUp()
	{
		if( call SplitControl.start() != SUCCESS )
			post serialPowerUp();
	}

	event void SplitControl.startDone(error_t error)
	{
		if( error != SUCCESS )
			post serialPowerUp();
		else
			call Timer.startPeriodic(1000);
	}

	event void SplitControl.stopDone(error_t error)
	{
	}

	event void Boot.booted()
	{
		call Leds.led0On();
		post serialPowerUp();
	}

	message_t testMsg;

	void testStateTransitions(uint8_t seqNo)
	{
		seqNo &= 15;

		if( seqNo == 1 )
			call RadioState.standby();
		else if( seqNo == 2 )
			call RadioState.turnOff();
		else if( seqNo == 3 )
			call RadioState.standby();
		else if( seqNo == 4 )
			call RadioState.turnOn();
		else if( seqNo == 5 )
			call RadioState.turnOff();
		else if( seqNo == 6 )
			call RadioState.turnOn();
		else if( seqNo == 7 )
		{
			*(uint16_t*)(call AMSend.getPayload[111](&testMsg)) = seqNo;
			call AMSend.send[111](0xFFFF, &testMsg, 2);
		}
	}

	void testTransmission(uint8_t seqNo)
	{
		uint8_t seqMod = seqNo & 15;

		if( seqMod == 1 )
			call RadioState.turnOn();
		else if( 2 <= seqMod && seqMod <= 14 )
		{
			*(uint16_t*)(call AMSend.getPayload[111](&testMsg)) = seqNo;
			call AMSend.send[111](0xFFFF, &testMsg, 2);
		}
		else if( seqMod == 15 )
			call RadioState.turnOff();
	}

	tasklet_async event void RadioState.done()
	{
	}

	event void AMSend.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	norace uint8_t payload[3];
	norace uint8_t receiveLength;
	norace uint8_t receiveData[10];
	norace error_t receiveError;

	task void reportReceive()
	{
		if( call DiagMsg.record() )
		{
			call DiagMsg.hex8s(receiveData, receiveLength);
			call DiagMsg.uint8(receiveError);
			call DiagMsg.send();
		}
	}

	uint8_t seqNo;
	event void Timer.fired()
	{
		++seqNo;
//		testStateTransitions(seqNo);
		testTransmission(seqNo);
	}
}
