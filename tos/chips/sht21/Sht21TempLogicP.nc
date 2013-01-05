#include "Sht21.h"
module Sht21TempLogicP
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
			buffer[0] = SHT21_TEMP;
			#ifdef STS21_MODE
			err = call I2CPacket.write(I2C_START | I2C_STOP, STS21_ADDRESS, 1, buffer);
			#else
			err = call I2CPacket.write(I2C_START | I2C_STOP, SHT21_ADDRESS, 1, buffer);
			#endif
		}
		else
		{
			#ifdef STS21_MODE
			err = call I2CPacket.read(I2C_START | I2C_STOP, STS21_ADDRESS, 2, buffer);
			#else
			err = call I2CPacket.read(I2C_START | I2C_STOP, SHT21_ADDRESS, 2, buffer);
			#endif
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
		uint16_t oldTempData = 0xffff;
		error_t oldError;
		
		call BusPowerManager.releasePower();
		atomic 
		{
			oldError = err;
			if( oldError == SUCCESS )
				oldTempData =  *((nx_uint16_t*)buffer);
		}
		
		state = S_IDLE;
		signal Read.readDone(oldError, oldTempData);
	}
	
	event void BusPowerManager.powerOff(){}
}
