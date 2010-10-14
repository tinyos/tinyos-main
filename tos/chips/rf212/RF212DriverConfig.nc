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
