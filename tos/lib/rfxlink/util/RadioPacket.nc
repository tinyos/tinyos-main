/*
 * Copyright (c) 2007, Vanderbilt University
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

#include <message.h>

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
	 * after the header.
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
