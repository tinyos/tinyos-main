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
* author Charles Elliott
* @modified May 21, 2008
* 
*/

interface MDA300ADC {
	/**
	 * Selects the ADC to read.
	 * ADDRESS + -
	 * 0x00 -> 0 1
	 * 0x10 -> 2 3
	 * 0x20 -> 4 5
	 * 0x30 -> 6 7
	 * 0x40 -> 1 0
	 * 0x50 -> 3 2
	 * 0x60 -> 5 4
	 * 0x70 -> 7 6
	 * 0x80 -> 0 COM
	 * 0x90 -> 1 COM
	 * 0xA0 -> 2 COM
	 * 0xB0 -> 3 COM
	 * 0xC0 -> 4 COM
	 * 0xD0 -> 5 COM
	 * 0xE0 -> 6 COM
	 * 0xF0 -> 7 COM
	 * bits 2 and 3 are power down selection 
	 * bits 0 and 1 are unused               
	 *
	 * @param value channel selected.
	 * 
	 * @return SUCCESS if the component is free.	 
	 */	 
	command error_t selectPin(uint8_t pin);
	
	/**
	 * Gets the channel selected.
	 *
	 * @note If get() is called during a write operation,
	 * the value that is being written will be returned.
	 *
	 * @return selected channel
	 */
	command uint8_t get ();
	
	command error_t requestRead();
	
	/**
	 * Gets the channel value.
	 *
	 * @return data value
	 */
	command uint16_t read();
	
	/**
	 * Notification that the channel is ready to be read.
	 */
	event void readyToRead();
	
	event void readyToSet();
}
