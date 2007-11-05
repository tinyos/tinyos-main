/*
 * Copyright (c) 2002-2007, Vanderbilt University
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
