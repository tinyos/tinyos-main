/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: Intersema5534LogicP.nc,v 1.2 2010-06-29 22:07:56 scipio Exp $
 */


#include "Intersema5534.h"

generic module Intersema5534LogicP()
{
	provides interface Read<uint16_t> as Temp;
	provides interface Read<uint16_t> as Press;
	provides interface Calibration as Cal;
	uses interface Timer<TMilli> as Timer;
	uses interface GeneralIO as SPI_CLK;
	uses interface GeneralIO as SPI_SI;
	uses interface GeneralIO as SPI_SO;
}
implementation
{
	enum{
		IDLE=0,
		CALIB,
		TEMP,
		PRESS,
	};
	uint8_t state=IDLE;
	uint8_t timeout=0;
	uint16_t calibration[4];
	uint16_t reading;
	
	void write_bit(bool);
	uint8_t read_bit();
	uint16_t spi_word(uint8_t);
	uint16_t data_read();
	void pulse_clock();
	void spi_reset();
	void sense();
	
	task void SPITask();
	task void gotInterrupt();
	
	command error_t Cal.getData(){
		if(state==IDLE){
			state=CALIB;
			post SPITask();
			return SUCCESS;
		}
		return FAIL;
	}
	
	command error_t Press.read() {
		if (state == IDLE) {
			state = PRESS;
			post SPITask();
			return SUCCESS;
	    	}
    		return FAIL;
	}

	command error_t Temp.read() {
		if (state == IDLE) {
			state = TEMP;
			post SPITask();
			return SUCCESS;
		}
		return FAIL;
	}	
	
	task void SPITask() {
		uint8_t i;
		if(state==CALIB){
			atomic {
				for (i = 0; i < 4; i++) {
					// reset the device
					spi_reset();
					calibration[i] = spi_word(i+1);
				}
			}
			// send the calibration data up to the application
			state = IDLE; 
			signal Cal.dataReady(SUCCESS, calibration);
		}else{
			atomic {
				// reset the device
				spi_reset();
				// grab the sensor reading and store it locally
				sense();
			}
		}
	}
	
	void task gotInterrupt() {
		uint16_t l_reading;
		atomic {
			reading = data_read();
		}
		l_reading = reading;

		// give the application the sensor data
		if (state == TEMP) {
			state = IDLE;
			signal Temp.readDone(SUCCESS,l_reading);
		}
		else if (state == PRESS) {
			state = IDLE;
			signal Press.readDone(SUCCESS,l_reading);
		}
	}
		
	uint16_t data_read() {
		uint16_t result = 0,tresult = 0;
		uint8_t i;
		TOSH_wait();
		for (i = 0; i < 16; i++) {
			tresult = (uint16_t)read_bit();
			tresult = tresult << (15-i);
			result += tresult;
		}
		return result;      
	}
	
	void pulse_clock() {
		TOSH_wait();
		TOSH_wait();
		call SPI_CLK.set();
		TOSH_wait();
		TOSH_wait();
		call SPI_CLK.clr();
	}
	
	void write_bit(bool bit) {
		if (bit)
			call SPI_SO.set();
		else
			call SPI_SO.clr();
			pulse_clock();
	}
	
	uint8_t read_bit() {
		uint8_t i;
		call SPI_SO.clr();
		call SPI_CLK.set();
		TOSH_wait();
		TOSH_wait();
		i = call SPI_SI.get();
		call SPI_CLK.clr();
		return i;
	}
		
	uint16_t spi_word(uint8_t num) {
		uint8_t i;
		TOSH_wait();
		TOSH_wait();
		// write first byte
		for (i = 0; i < 3; i++) {
			write_bit(TRUE);
		}
		write_bit(FALSE);
		write_bit(TRUE);
		if (num == 1) {
			write_bit(FALSE);
			write_bit(TRUE);
			write_bit(FALSE);
			write_bit(TRUE);
		}
		else if (num == 2) {
			write_bit(FALSE);
			write_bit(TRUE);
			write_bit(TRUE);
			write_bit(FALSE);
		}
		else if (num == 3) {
			write_bit(TRUE);
			write_bit(FALSE);
			write_bit(FALSE);
			write_bit(TRUE);
		}
		else if (num == 4) {
			write_bit(TRUE);
			write_bit(FALSE);
			write_bit(TRUE);
			write_bit(FALSE);
		}
		for (i = 0; i < 4; i++){ 
			write_bit(FALSE);
		}
		TOSH_wait();
		return data_read();
	}
	
	void spi_reset() {
		uint8_t i = 0;
		for (i = 0; i < 21; i++) {
			if (i < 16) {
				if ((i % 2) == 0)
					write_bit(TRUE);
				else
					write_bit(FALSE);
			}
			else
				write_bit(FALSE);
		} 
	}
	
	void sense() {
		uint8_t i;
		TOSH_wait();
		TOSH_wait();
		// write first byte
		for (i = 0; i < 3; i++) {
			write_bit(TRUE);
		}
		if (state == PRESS) {
			write_bit(TRUE);
			write_bit(FALSE);
			write_bit(TRUE);
			write_bit(FALSE);
		}
		else if (state == TEMP) {
			write_bit(TRUE);
			write_bit(FALSE);
			write_bit(FALSE);
			write_bit(TRUE);
		}
		for (i = 0; i < 5; i++) {
			write_bit(FALSE);
		}
		timeout = 0;
		call Timer.startOneShot(36);
	}

	event void Timer.fired() {
		if (call SPI_SI.get() == 1) {
		      	timeout++;
			if (timeout > PRESSURE_TIMEOUT_TRIES) {
				if (state == PRESS) {
					state = IDLE;
					signal Press.readDone( FAIL, 0 );
					return;
				}else if (state == TEMP) {
					state = IDLE;
					signal Temp.readDone( FAIL, 0 );
					return;
				}
			}
      			call Timer.startOneShot(20);
	    	} 
		else 
			post gotInterrupt();
	}
}
