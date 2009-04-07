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

interface RF212DriverConfig
{
	/**
	 * Returns the length of a dummy header to align the payload properly.
	 */
	async command uint8_t headerLength(message_t* msg);

	/**
	 * Returns the maximum length of the PHY payload including the 
	 * length field but not counting the FCF field.
	 */
	async command uint8_t maxPayloadLength();

	/**
	 * Returns the length of a dummy metadata section to align the
	 * metadata section properly.
	 */
	async command uint8_t metadataLength(message_t* msg);

	/**
	 * Gets the number of bytes we should read before the RadioReceive.header
	 * event is fired. If the length of the packet is less than this amount, 
	 * then that event is fired earlier. The header length must be at least one.
	 */
	async command uint8_t headerPreloadLength();

	/**
	 * Returns TRUE if before sending this message we should make sure that
	 * the channel is clear via a very basic (and quick) RSSI check.
	 */
	async command bool requiresRssiCca(message_t* msg);
}
