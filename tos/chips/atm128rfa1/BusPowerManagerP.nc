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

generic module BusPowerManagerP(bool highIsOn, bool initPin)
{
	provides interface BusPowerManager;
	uses interface Timer<TMilli>;
	uses interface GeneralIO;
	provides interface Init;
}

implementation
{
	uint16_t maxStartup;
	uint16_t maxKeepAlive;

	uint8_t counter;
	enum
	{
		COUNTER_MASK = 0x7F,
		COUNTER_TIMER = 0x80,	// timer is running
	};
	
	command error_t Init.init(){
		call GeneralIO.makeOutput();
		if(initPin){
			if( highIsOn )
				call GeneralIO.clr();
			else
				call GeneralIO.set();
		}
		return SUCCESS;
	}

	command void BusPowerManager.configure(uint16_t startup, uint16_t keepalive)
	{
		if( maxStartup < startup )
			maxStartup = startup;

		if( maxKeepAlive < keepalive )
			maxKeepAlive = keepalive;
	}
	
	command void BusPowerManager.requestPower()
	{
		++counter;
		if( counter == 1 )	// bus is off
		{
			if( highIsOn )
				call GeneralIO.set();
			else
				call GeneralIO.clr();
			call Timer.startOneShot(maxStartup);
			counter = 1 | COUNTER_TIMER;
		}
		else if( counter == (1 | COUNTER_TIMER) )	// during keepalive
		{
			call Timer.stop();
			counter = 1;
		}
	}

	command void BusPowerManager.releasePower()
	{
		--counter;
		if( counter == 0 )	// bus is on
		{
			call Timer.startOneShot(maxKeepAlive);
			counter = COUNTER_TIMER;
		}
		else if( counter == 0 + COUNTER_TIMER) // during startup
		{
			if( highIsOn )
				call GeneralIO.clr();
			else
				call GeneralIO.set();

			call Timer.stop();
			counter = 0;
		}
	}

	event void Timer.fired()
	{
		counter &= COUNTER_MASK;
		if( counter == 0 )
		{
			if( highIsOn )
				call GeneralIO.clr();
			else
				call GeneralIO.set();
			signal BusPowerManager.powerOff();
		}
		else {
			signal BusPowerManager.powerOn();
		}
	}
}
