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

interface RadioPacket
{
	/**
	 * This command returns the length of the header. The header
	 * starts at the first byte of the message_t structure 
	 * (some layers may add dummy bytes to allign the payload to
	 * the msg->data section).
	 */
	async command uint8_t headerLength(message_t* msg);

	/**
	 * Returns the length of the payload. The payload starts right
	 * after th header.
	 */
	async command uint8_t payloadLength(message_t* msg);

	/**
	 * Sets the length of the payload.
	 */
	async command void setPayloadLength(message_t* msg, uint8_t length);

	/**
	 * Returns the maximum length that can be set for this message.
	 */
	async command uint8_t maxPayloadLength();

	/**
	 * Returns the length of the metadata section. The metadata section
	 * is at the very end of the message_t structure and grows downwards.
	 */
	async command uint8_t metadataLength(message_t* msg);

	/**
	 * Clears all metadata and sets all default values in the headers.
	 */
	async command void clear(message_t* msg);
}
