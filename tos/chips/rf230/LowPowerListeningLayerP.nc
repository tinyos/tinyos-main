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

#include <RadioAssert.h>

module LowPowerListeningLayerP
{
	provides
	{
		interface SplitControl;
		interface Send;
		interface Receive;

		interface LowPowerListening;
	}

	uses
	{
		interface SplitControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;

		interface PacketField<uint16_t> as PacketSleepInterval;
		interface Timer<TMilli>;
	}
}

implementation
{
	enum
	{
		// minimum wakeup time to catch a transmission in milliseconds
		LISTEN_WAKEUP = 6,	// use xxxL if LISTEN_WAKEUP * 10000 > 65535

		// extra wakeup time after receiving a message in milliseconds
		AFTER_RECEIVE = 10,

		// extra wakeup time after transmitting a message in milliseconds
		AFTER_TRANSMIT = 10,

		MIN_SLEEP = 2,		// the minimum sleep interval in milliseconds
		MAX_SLEEP = 30000,	// the maximum sleep interval in milliseconds
		MIN_DUTY = 2,		// the minimum duty cycle
	};

	uint16_t rxSleepInterval;

/*----------------- state machine -----------------*/

	enum
	{
		STATE_OFF = 0,		// timer off, radio off
		STATE_SLEEP = 1,	// timer on, radio off
		STATE_LISTEN = 2,	// timer on/off, radio on
		STATE_SEND = 3,		// timer on/off, radio on

		STATE_OFF_TO_LISTEN = 10,
		STATE_SLEEP_TO_LISTEN = 11,
		STATE_SLEEP_TO_SEND = 12,
		STATE_SLEEP_TO_OFF = 13,
		STATE_LISTEN_TO_SLEEP_1 = 14,	// we go back to listen if a message arrives in this state
		STATE_LISTEN_TO_SLEEP_2 = 15,
		STATE_LISTEN_TO_OFF = 16,
		STATE_SEND_DONE = 17,
	};

	uint8_t state;

	message_t* txMsg;
	uint8_t txLen;

	task void transition()
	{
		error_t error;

		if( state == STATE_OFF_TO_LISTEN || state == STATE_SLEEP_TO_LISTEN || state == STATE_SLEEP_TO_SEND )
		{
			error = call SubControl.start();
			ASSERT( error == SUCCESS || error == EBUSY );

			if( error != SUCCESS )
				post transition();
		}
		else if( state == STATE_LISTEN_TO_OFF || state == STATE_LISTEN_TO_SLEEP_1 )
		{
			error = call SubControl.stop();
			ASSERT( error == SUCCESS || error == EBUSY );

			if( error != SUCCESS )
				post transition();
			else if( state == STATE_LISTEN_TO_SLEEP_1 )
				state = STATE_LISTEN_TO_SLEEP_2;
		}
		else if( state == STATE_SLEEP_TO_OFF )
		{
			state = STATE_OFF;
			signal SplitControl.stopDone(SUCCESS);
		}
		else if( state == STATE_SEND )
		{
			error = call SubSend.send(txMsg, txLen);
			if( error == SUCCESS )
				state = STATE_SEND_DONE;
			else
			{
				state = STATE_LISTEN;
				if( rxSleepInterval > 0 )
					call Timer.startOneShot(AFTER_TRANSMIT);

				signal Send.sendDone(txMsg, error);
			}
		}
		else if( state == STATE_LISTEN )
		{
			if( rxSleepInterval > 0 )
				call Timer.startOneShot(LISTEN_WAKEUP);
		}
		else if( state == STATE_SLEEP )
		{
			if( rxSleepInterval > 0 )
				call Timer.startOneShot(rxSleepInterval);
			else
			{
				state = STATE_SLEEP_TO_LISTEN;
				post transition();
			}
		}
	}

	command error_t SplitControl.start()
	{
		if( state != STATE_OFF )
			return EALREADY;

		state = STATE_OFF_TO_LISTEN;
		post transition();

		return SUCCESS;
	}

	event void SubControl.startDone(error_t error)
	{
		ASSERT( error == SUCCESS || error == EBUSY );
		ASSERT( state == STATE_OFF_TO_LISTEN || state == STATE_SLEEP_TO_LISTEN || state == STATE_SLEEP_TO_SEND );

		if( error == SUCCESS )
		{
			if( state == STATE_OFF_TO_LISTEN )
				signal SplitControl.startDone(SUCCESS);
			else if( state == STATE_SLEEP_TO_SEND )
				state = STATE_SEND;
			else
				state = STATE_LISTEN;
		}

		post transition();
	}

	command error_t SplitControl.stop()
	{
		if( state == STATE_OFF )
			return EALREADY;
		else if( state != STATE_LISTEN || state != STATE_SLEEP )
			return EBUSY;

		call Timer.stop();
		if( state == STATE_SLEEP )
			state = STATE_SLEEP_TO_OFF;
		else
			state = STATE_LISTEN_TO_OFF;

		post transition();

		return SUCCESS;
	}

	event void SubControl.stopDone(error_t error)
	{
		ASSERT( error == SUCCESS || error == EBUSY );
		ASSERT( state == STATE_LISTEN_TO_SLEEP_2 || state == STATE_LISTEN_TO_OFF );

		if( error == SUCCESS )
		{
			if( state == STATE_LISTEN_TO_OFF )
				state = STATE_SLEEP_TO_OFF;
			else
				state = STATE_SLEEP;
		}

		post transition();
	}

	event void Timer.fired()
	{
		ASSERT( state == STATE_LISTEN || state == STATE_SLEEP );

		if( state == STATE_LISTEN )
			state = STATE_LISTEN_TO_SLEEP_1;
		else
			state = STATE_SLEEP_TO_LISTEN;

		post transition();
	}

	void rxSleepIntervalChanged()
	{
		if( rxSleepInterval == 0 )
		{
			call Timer.stop();
			if( state == STATE_SLEEP )
				state = STATE_SLEEP_TO_LISTEN;
		}

		post transition();
	}

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len)
	{
		if( state == STATE_LISTEN_TO_SLEEP_1 )
			state = STATE_LISTEN;

		if( state == STATE_LISTEN && rxSleepInterval > 0 )
			call Timer.startOneShot(AFTER_RECEIVE);

		return signal Receive.receive(msg, payload, len);
	}

	command error_t Send.send(message_t* msg, uint8_t len)
	{
		if( state == STATE_LISTEN || state == STATE_SLEEP )
			call Timer.stop();

		if( state == STATE_LISTEN || state == STATE_LISTEN_TO_SLEEP_1 )
		{
			state = STATE_SEND;
			post transition();
		}
		else if( state == STATE_SLEEP )
		{
			state = STATE_SLEEP_TO_SEND;
			post transition();
		}
		else if( state == STATE_SLEEP_TO_LISTEN )
			state = STATE_SLEEP_TO_SEND;
		else
			return EBUSY;

		txMsg = msg;
		txLen = len;
	}

	command error_t Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		ASSERT( state == STATE_SEND_DONE );

		state = STATE_LISTEN;
		if( rxSleepInterval > 0 )
			call Timer.startOneShot(AFTER_TRANSMIT);

		signal Send.sendDone(msg, error);
	}

	command uint8_t Send.maxPayloadLength()
	{
		return call SubSend.maxPayloadLength();
	}

	command void* Send.getPayload(message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload(msg, len);
	}

/*----------------- LowPowerListening -----------------*/

	command uint16_t LowPowerListening.dutyCycleToSleepInterval(uint16_t dutyCycle)
	{
		if( dutyCycle >= 10000 )
			return 0;
		else if( dutyCycle <= MIN_DUTY  )
			return MAX_SLEEP;

		return ((10000 * LISTEN_WAKEUP) / dutyCycle) - LISTEN_WAKEUP;
	}

	command uint16_t LowPowerListening.sleepIntervalToDutyCycle(uint16_t sleepInterval)
	{
		if( sleepInterval < MIN_SLEEP )
			return 10000;
		else if( sleepInterval >= MAX_SLEEP )
			return MIN_DUTY;

		return (10000 * LISTEN_WAKEUP) / (LISTEN_WAKEUP + sleepInterval);
	}

	command void LowPowerListening.setLocalSleepInterval(uint16_t sleepInterval)
    {
		if( sleepInterval < MIN_SLEEP )
			sleepInterval = 0;
		else if( sleepInterval > MAX_SLEEP )
			sleepInterval = MAX_SLEEP;

		rxSleepInterval = sleepInterval;
		rxSleepIntervalChanged();
	}

	command uint16_t LowPowerListening.getLocalSleepInterval()
    {	
		return rxSleepInterval;
	}

	command void LowPowerListening.setLocalDutyCycle(uint16_t dutyCycle)
	{
		call LowPowerListening.setLocalSleepInterval(
			call LowPowerListening.dutyCycleToSleepInterval(dutyCycle));
	}

	command uint16_t LowPowerListening.getLocalDutyCycle()
	{
		return call LowPowerListening.sleepIntervalToDutyCycle(rxSleepInterval);
	}

	command void LowPowerListening.setRxSleepInterval(message_t *msg, uint16_t sleepInterval)
	{
		if( sleepInterval < MIN_SLEEP )
			sleepInterval = 0;
		else if( sleepInterval > MAX_SLEEP )
			sleepInterval = MAX_SLEEP;

		call PacketSleepInterval.set(msg, sleepInterval);
	}

	command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg)
    {
		if( ! call PacketSleepInterval.isSet(msg) )
			return 0;

		return call PacketSleepInterval.get(msg);
	}

	command void LowPowerListening.setRxDutyCycle(message_t *msg, uint16_t dutyCycle)
    {
		call PacketSleepInterval.set(msg, 
			call LowPowerListening.dutyCycleToSleepInterval(dutyCycle));
	}

	command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg)
    {
		if( ! call PacketSleepInterval.isSet(msg) )
			return 10000;

		return call LowPowerListening.sleepIntervalToDutyCycle(
			call PacketSleepInterval.get(msg));
	}
}
