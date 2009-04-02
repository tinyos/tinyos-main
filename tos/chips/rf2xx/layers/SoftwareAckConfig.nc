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
