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

#include "Ieee154.h"
#include "message.h"

/**
 * This interface encapsulates IEEE 802.15.4 intrapan data frames with 
 * 16-bit destination pan, source and destination addresses. It also 
 * supports 6LowPan interoperability mode, and acknowledgement frames.
 * Note, that this interface does not support the CRC-16 value, which
 * should be verified before the data can be trusted.
 */
interface Ieee154PacketLayer
{
	/**
	 * Returns the frame control field. This method should not be used, 
	 * isDataFrame and isAckFrame should be used instead.
	 */
	async command uint16_t getFCF(message_t* msg);

	/**
	 * Sets the frame control field. This method should not be used, 
	 * createDataFrame and createAckFrame should be used instead.
	 */
	async command void setFCF(message_t* msg, uint16_t fcf);

	/**
	 * Returns TRUE if the message is a data frame supported by 
	 * this interface (based on the value of the FCF).
	 */
	async command bool isDataFrame(message_t* msg);

	/**
	 * Sets the FCF to create a data frame supported by this interface.
	 * You may call setAckRequired and setFramePending commands after this.
	 */
	async command void createDataFrame(message_t* msg);

	/**
	 * Returns TRUE if the message is an acknowledgement frame supported
	 * by this interface (based on the value of the FCF).
	 */
	async command bool isAckFrame(message_t* msg);

	/**
	 * Sets the FCF to create an acknowledgement frame supported by
	 * this interface. You may call setFramePending after this.
	 */
	async command void createAckFrame(message_t* msg);

	/**
	 * Creates an acknowledgement packet for the given data packet.
	 * This also sets the DSN value. The data message must be a 
	 * data frame, the ack message will be overwritten.
	 */
	async command void createAckReply(message_t* data, message_t* ack);

	/**
	 * Returns TRUE if the acknowledgement packet corresponds to the
	 * data packet. The data message must be a data packet.
	 */
	async command bool verifyAckReply(message_t* data, message_t* ack);

	/**
	 * Returns TRUE if the ACK required field is set in the FCF.
	 */
	async command bool getAckRequired(message_t* msg);

	/**
	 * Sets the ACK required field in the FCF, should never be set
	 * for acknowledgement frames.
	 */
	async command void setAckRequired(message_t* msg, bool ack);

	/**
	 * Returns TRUE if the frame pending field is set in the FCF.
	 */
	async command bool getFramePending(message_t* msg);

	/**
	 * Sets the frame pending field in the FCF.
	 */
	async command void setFramePending(message_t* msg, bool pending);

	/**
	 * Returns the data sequence number
	 */
	async command uint8_t getDSN(message_t* msg);

	/**
	 * Sets the data sequence number
	 */
	async command void setDSN(message_t* msg, uint8_t dsn);

	/**
	 * returns the destination PAN id, values <= 255 are tinyos groups,
	 * valid only for data frames
	 */
	async command uint16_t getDestPan(message_t* msg);

	/**
	 * Sets the destination PAN id, valid only for data frames
	 */
	async command void setDestPan(message_t* msg, uint16_t pan);

	/**
	 * Returns the destination address, valid only for data frames
	 */
	async command uint16_t getDestAddr(message_t* msg);

	/**
	 * Sets the destination address, valid only for data frames
	 */
	async command void setDestAddr(message_t* msg, uint16_t addr);

	/**
	 * Returns the source address, valid only for data frames
	 */
	async command uint16_t getSrcAddr(message_t* msg);

	/**
	 * Sets the source address, valid only for data frames
	 */
	async command void setSrcAddr(message_t* msg, uint16_t addr);

	/**
	 * Returns TRUE if the packet is a data packet, the ACK_REQ field
	 * is set and the destination address is not the broadcast address.
	 */
	async command bool requiresAckWait(message_t* msg);

	/**
	 * Returns TRUE if the packet is a data packet, the ACK_REQ field
	 * is set and the destionation address is this node.
	 */
	async command bool requiresAckReply(message_t* msg);

	/**
	 * Returns the local pan id (AM group)
	 */
	async command ieee154_panid_t localPan();

	/**
	 * Returns the local address of the node (AM address)
	 */
	async command ieee154_saddr_t localAddr();

	/**
	 * Returns TRUE if the destionation of this message is either 0xFFFF
	 * or is the local address of the node, and the pan address is the
	 * local one.
	 */
	async command bool isForMe(message_t* msg);
}
