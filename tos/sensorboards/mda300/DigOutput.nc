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
* Interface for using the digital output pins on the MDA
* 300 and 320 sensorboards.
* 
* @author Christopher Leung
* @modified May 21, 2008
*/

interface DigOutput {	
	/**
	 * Sets all the pins.
	 *
	 * @param value Value to be set on the pins.
	 * 
	 * @return SUCCESS if the component is free.
	 */
	command error_t setAll (uint8_t value);
	
	/**
	 * Sets select pins.
	 *
	 * @param pins Pins to be set.
	 * @param value Values to be set on selected pins.
	 *
	 * @return SUCCESS if the component is free.
	 */
	command error_t set (uint8_t pins, uint8_t value);
	
	/**
	 * Reads all the pins.
	 *
	 * @param none
	 * 
	 * @return SUCCESS if the component is free.
	 */
	command error_t requestRead();
	
	/**
	 * Gets the pin values.
	 *
	 * @note If get() is called during a write operation,
	 * the value that is being written will be returned.
	 *
	 * @return Pin values
	 */
	command uint8_t get ();
	
	/**
	 * Gets the pin values.
	 *
	 * @return Pin data value
	 */
	command uint8_t read();
	
	/**
	 * Notification that the pins have been set.
	 */
	event void readyToSet ();
	
	/**
	 * Notification that the pins are ready to be read.
	 */
	event void readyToRead();
}
