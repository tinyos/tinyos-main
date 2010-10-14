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

#include <Tasklet.h>

interface SoftwareAckConfig
{
	/**
	 * Returns the acknowledgement timeout (in the radio clock units),
	 * in which a sent packet must be acknowledged.
	 */
	async command uint16_t getAckTimeout();

	/**
	 * Sets the flag in the message indicating to the receiver whether
	 * the message should be acknowledged.
	 */
	async command void setAckRequired(message_t* msg, bool ack);
	 
	/**
	 * Returns TRUE if the layer should wait for a software acknowledgement
	 * to be received after this packet was transmitted.
	 */
	async command bool requiresAckWait(message_t* msg);

	/**
	 * Returns TRUE if the received packet is an acknowledgement packet.
	 * The AckedSend layer will filter out all received acknowledgement
	 * packets and uses  only the matching one for the acknowledgement.
	 */
	async command bool isAckPacket(message_t* msg);

	/**
	 * Returns TRUE if the acknowledgement packet corresponds to the
	 * data packet. The acknowledgement packect was already verified 
	 * to be a valid acknowledgement packet via the isAckPacket command.
	 */
	async command bool verifyAckPacket(message_t* data, message_t* ack);

	/**
	 * Returns TRUE if the received packet needs software acknowledgements
	 * to be sent back to the sender.
	 */
	async command bool requiresAckReply(message_t* msg);

	/**
	 * Creates an acknowledgement packet for the given data packet.
	 */
	async command void createAckPacket(message_t* data, message_t* ack);

	/**
	 * This command is called when a sent packet did not receive an
	 * acknowledgement.
	 */
	tasklet_async command void reportChannelError();
}
