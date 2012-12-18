/*
 * Copyright (c) 2012 Sestosenso
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Sestosenso nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * SESTOSENSO OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
* Core component that allows the use of the digital outputs
* on the MDA 300 and 320 sensorboards.
* 
* This component does the following steps to set the digital
* output pins:
*   1. Request resource
*   2. Resource granted -> Write data through I2C bus
*   3. Write done -> Release resource and Signal done
* 
* @author Christopher Leung
* @modified June 5, 2008
* @author Franco Di Persio, Sestosenso
* @modified September 2012
*/

module MDA3XXDigOutputP {
	provides {
		interface DigOutput;
		interface Notify<bool>; 	//add to activate the interrupt: May 22, 2012
	}
	uses {
		interface Leds; // as DebugLeds;
		interface I2CPacket<TI2CBasicAddr>;
		interface Resource;
		interface GeneralIO;	//add to activate the interrupt: May 22, 2012
    	interface GpioInterrupt;	//add to activate the interrupt: May 22, 2012

    	interface Timer<TMilli> as Digital_impuls_Timer;
		
	}
}
implementation {
	uint8_t I2C_data = 0xFF;	// Pin values
	uint8_t I2C_send;			// Buffer
	uint8_t I2C_read[2];		//could be 3... and then the lenght should be 3 also at the: call I2CPacket.read(...,...,3,...)... but it is enough 2.
	bool idle = TRUE;
	bool read = FALSE;
		
	norace bool m_pinHigh;
	uint8_t	impuls_count;
	
	task void sendEvent();	//add for checking the Interrupt
	
	task void writeToI2C() {
		I2C_send = I2C_data;
		if ((call I2CPacket.write(I2C_START|I2C_STOP, 63, 1, (uint8_t*) &I2C_send)) != SUCCESS)
			post writeToI2C();
	}
	
	task void readToI2C() {		
		if ((call I2CPacket.read(I2C_START|I2C_STOP, 63, 2, (uint8_t*) &I2C_read)) != SUCCESS)
			post readToI2C();
	}
	
	task void signalReadyToSet() {
		signal DigOutput.readyToSet();
		idle = TRUE;
	}
	
	task void signalReadyToRead() {
		signal DigOutput.readyToRead();
		idle = TRUE;
	}
	
	
	/**
	 * Sets all the pins.
	 *
	 * @param value Value to be set on the pins.
	 * 
	 * @return SUCCESS if the component is free.
	 */
	command error_t DigOutput.setAll(uint8_t value) {
		if (idle) {
			idle = FALSE;
			read = FALSE;
			I2C_data = value;
			call Resource.request();
			return SUCCESS;
		}
		return FAIL;
	}
	
	/**
	 * Reads all the pins.
	 *
	 * @param none
	 * 
	 * @return SUCCESS if the component is free.
	 */
	command error_t DigOutput.requestRead() {
		if (idle) {
			idle = FALSE;
			read = TRUE;
			//I2C_data = value;
			call Resource.request();
			return SUCCESS;
		}
		return FAIL;
	}
	
	/**
	 * Sets select pins.
	 *
	 * @param pins Pins to be set.
	 * @param value Values to be set on selected pins.
	 *
	 * @return SUCCESS if the component is free.
	 */
	command error_t DigOutput.set(uint8_t pins, uint8_t value) {
		uint8_t temp_I2C_data;
		if (idle) {
			temp_I2C_data = I2C_data;
			temp_I2C_data &= ~(~value<<pins);
			
			idle = FALSE;
			read = FALSE;
			I2C_data = temp_I2C_data;
			call Resource.request();
			return SUCCESS;
		}
		return FAIL;
	}
	
	/**
	 * Gets the pin values.
	 *
	 * @note If get() is called during a write operation,
	 * the value that is being written will be returned.
	 *
	 * @return Pin values
	 */
	command uint8_t DigOutput.get() {
		uint8_t temp_I2C_data;
		temp_I2C_data = I2C_data;
		return I2C_data;
	}
	
	/**
	 * Gets the pin values.
	 *
	 * @return Pin data value
	 */
	command uint8_t DigOutput.read() {
		uint8_t temp_I2C_read;
		temp_I2C_read = I2C_read[1];
		return temp_I2C_read;
	}
	
	event void Resource.granted() {
		if (read){
			post readToI2C();
		}else{
			post writeToI2C();
		}
	}
	
	async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
		call Resource.release();
		post signalReadyToRead();
		if (error != SUCCESS) call Leds.led2Toggle();
	}
	
	async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
		call Resource.release();
		post signalReadyToSet();
		if (error != SUCCESS) call Leds.led2Toggle();
	}
										
	command error_t Notify.enable() {	//add to activate the interrupt: May 22, 2012
		atomic impuls_count = 0;
		/* Pin needs to be an input */
		call GeneralIO.makeInput();
		/* Trigger on falling edge to assure the fiability in LPL*/
		return call GpioInterrupt.enableFallingEdge();
	}
 
  	command error_t Notify.disable() {
	  	return call GpioInterrupt.disable();
  	}
 
    /* Input changed, signal user (in a task) and update interrupt detection */
    
  	async event void GpioInterrupt.fired() {
			post sendEvent();
  	}
  	
  	task void sendEvent() {
		if (idle) {
			idle = FALSE;
			read = TRUE;
			call Resource.request();
		}
		call Digital_impuls_Timer.startOneShot(DIGITAL_TIMER);
    }
    
    event void Digital_impuls_Timer.fired() {
	    atomic impuls_count = 0;
	    idle = FALSE;
		read = TRUE;
		call Resource.request();
    }
	
}
