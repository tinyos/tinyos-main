/*
 * Copyright (c) 2007, Vanderbilt University
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
			*(uint16_t*)(call AMSend.getPayload[111](
                    &testMsg,
			        call AMSend.maxPayloadLength[111]())) = seqNo;
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
			*(uint16_t*)(call AMSend.getPayload[111](
                    &testMsg,
                    call AMSend.maxPayloadLength[111]())) = seqNo;
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
