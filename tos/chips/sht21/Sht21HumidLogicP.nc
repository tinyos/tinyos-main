/*
 * Copyright (c) 2013 Unicomp Ltd.
 * Copiright (c) 2013 University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 */

/*
 * Author: Andras Biro <bbandi86@gmail.com>
 * Author: Gabor Salamon <gabor.salamon@unicomp.hu>
 */

#include "Sht21.h"
module Sht21HumidLogicP
{
	provides interface Read<uint16_t>;
	provides interface Init;
	uses interface I2CPacket<TI2CBasicAddr> as I2CPacket;
	uses interface Resource as I2CResource;
	uses interface Timer<TMilli>;
	uses interface BusPowerManager;
}
implementation
{
	enum{
		S_IDLE,
		S_COMMAND,
		S_READ,
	};
	
	norace error_t err;
	uint8_t buffer[2];
	uint8_t state = S_IDLE;
	
	task void signalDone();
	task void waitTask();
	
	command error_t Init.init(){
		call BusPowerManager.configure(SHT21_RESET_WAIT, SHT21_RESET_WAIT);
		return SUCCESS;
	}
	
	command error_t Read.read()
	{
		if( state != S_IDLE )
			return EALREADY;
		
		state = S_COMMAND;
		call BusPowerManager.requestPower();
		if( call BusPowerManager.isPowerOn() )
			return call I2CResource.request();
		else
			return SUCCESS;
	}
	
	event void BusPowerManager.powerOn()
	{
		if( state != S_IDLE )
		{
			err = call I2CResource.request();
			if ( err != SUCCESS )
				post signalDone();
		}
	}
	
	event void I2CResource.granted()
	{
		if( state == S_COMMAND )
		{
			buffer[0] = SHT21_HUMID;
			err = call I2CPacket.write(I2C_START | I2C_STOP, SHT21_ADDRESS, 1, buffer);
		}
		else
		{
			err = call I2CPacket.read(I2C_START | I2C_STOP, SHT21_ADDRESS, 2, buffer);
		}
		
		if(err != SUCCESS)
			post signalDone();
	}
	
	async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data)
	{
		call I2CResource.release();
		
		err = error;		
		if(err == SUCCESS)
		{
			post waitTask();
		}
		else 
		{
			post signalDone();
		}
	}
	
	task void waitTask()
	{
		state = S_READ;
		call Timer.startOneShot(SHT21_WAIT);
	}
	
	event void Timer.fired()
	{
		err = call I2CResource.request();
		
		if(err != SUCCESS)
			post signalDone();
	}
	
	async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data)
	{
		call I2CResource.release();
		err = error;		
		
		post signalDone();
	}
	
	task void signalDone()
	{
		uint16_t oldHumidData = 0xffff;
		error_t oldError;
		
		call BusPowerManager.releasePower();
		atomic 
		{
			oldError = err;
			if( oldError == SUCCESS )
				oldHumidData = ((uint16_t)buffer[0] << 8) | buffer[1];
		}
		
		state = S_IDLE;
		signal Read.readDone(oldError, oldHumidData);
	}
	
	event void BusPowerManager.powerOff(){}
}
