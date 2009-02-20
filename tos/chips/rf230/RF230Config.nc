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

/**
 * This interface needs to be implemented by the MAC to control the behaviour 
 * of the RF230LayerC component.
 */
interface RF230Config
{
	/**
	 * Returns the length of the PHY payload (including the FCF field).
	 * This value must be in the range [3, 127].
	 */
	async command uint8_t getLength(message_t* msg);

	/**
	 * Sets the length of the PHY payload.
	 */
	async command void setLength(message_t* msg, uint8_t len);

	/**
	 * Returns a pointer to the start of the PHY payload that contains 
	 * getLength()-2 number of bytes. The FCF field (CRC-16) is not stored,
	 * but automatically appended / verified.
	 */
	async command uint8_t* getPayload(message_t* msg);

	/**
	 * Gets the number of bytes we should read before the RadioReceive.header
	 * event is fired. If the length of the packet is less than this amount, 
	 * then that event is fired earlier. The header length must be at least one.
	 */
	async command uint8_t getHeaderLength();

	/**
	 * Returns the maximum PHY length that can be set via the setLength command
	 */
	async command uint8_t getMaxLength();

	/**
	 * This command is used at power up to set the default channel.
	 * The default CC2420 channel is 26.
	 */
	async command uint8_t getDefaultChannel();

	/**
	 * Returns TRUE if before sending this message we should make sure that
	 * the channel is clear via a very basic (and quick) RSSI check.
	 */
	async command bool requiresRssiCca(message_t* msg);
}
