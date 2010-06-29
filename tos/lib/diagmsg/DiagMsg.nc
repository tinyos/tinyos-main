/*
 * Copyright (c) 2002-2007, Vanderbilt University
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

/**
 * The DiagMsg interface allows messages to be sent back to the base station
 * containing several values and their type information, like in 
 * <code>printf(...)</code>. The base station must be connected to a PC using 
 * a serial cable. On the PC a Java application (net.tinyos.util.DiagMsg) 
 * decodes the message and displays its content using the correct type 
 * information. See the implementation for the format of the message.
 */
interface DiagMsg
{
	/**
	 * Initiates the recording of a new DiagMsg. It returns FALSE if
	 * the component is busy recording or sending another message.
	 */
	async command bool record();

	/**
	 * Adds a new value to the end of the message. If the message 
	 * cannot hold more information, then the new value is simply dropped.
	 */
	async command void int8(int8_t value);
	async command void uint8(uint8_t value);
	async command void hex8(uint8_t value);
	async command void int16(int16_t value);
	async command void uint16(uint16_t value);
	async command void hex16(uint16_t value);
	async command void int32(int32_t value);
	async command void int64(int64_t value);
	async command void uint64(uint64_t value);
	async command void uint32(uint32_t value);
	async command void hex32(uint32_t value);
	async command void real(float value);
	async command void chr(char value);

	/**
	 * Adds an array of values to the end of the message. 
	 * The maximum length of the array is <code>15</code>.
	 * If the message cannot hold all elements of the array,
	 * then no value is stored.
	 */
	async command void int8s(const int8_t *value, uint8_t len);
	async command void uint8s(const uint8_t *value, uint8_t len);
	async command void hex8s(const uint8_t *value, uint8_t len);
	async command void int16s(const int16_t *value, uint8_t len);
	async command void uint16s(const uint16_t *value, uint8_t len);
	async command void hex16s(const uint16_t *value, uint8_t len);
	async command void int32s(const int32_t *value, uint8_t len);
	async command void uint32s(const uint32_t *value, uint8_t len);
	async command void hex32s(const uint32_t *value, uint8_t len);
	async command void int64s(const int64_t *value, uint8_t len);
	async command void uint64s(const uint64_t *value, uint8_t len);
	async command void reals(const float *value, uint8_t len);
	async command void chrs(const char *value, uint8_t len);

	/**
	 * This is a shorthand method for <code>chrs</code>
	 */
	async command void str(const char* value);

	/**
	 * Initiates the sending of the recorded message. 
	 */
	async command void send();
}
