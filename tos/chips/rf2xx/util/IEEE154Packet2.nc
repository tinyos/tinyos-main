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

#include <IEEE154Packet2.h>
#include <message.h>

/**
 * This interface encapsulates IEEE 802.15.4 intrapan data frames with 
 * 16-bit destination pan, source and destination addresses. It also 
 * supports 6LowPan interoperability mode, and acknowledgement frames.
 * Note, that this interface does not support the CRC-16 value, which
 * should be verified before the data can be trusted.
 */
interface IEEE154Packet2
{
	/**
	 * Returns the IEEE 802.15.4 header including the length field.
	 */
	async command ieee154_header_t* getHeader(message_t* msg);

	/**
	 * Returns the raw value (unadjusted) of the length field
	 */
	async command uint8_t getLength(message_t* msg);

	/**
	 * Sets the length field
	 */
	async command void setLength(message_t* msg, uint8_t length);

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

#ifndef TFRAMES_ENABLED

	/**
	 * Returns the value of the 6LowPan network field.
	 */
	async command uint8_t get6LowPan(message_t* msg);

	/**
	 * Sets the value of the 6LowPan network field.
	 */
	async command void set6LowPan(message_t* msg, uint8_t network);

#endif

	/**
	 * Returns the active message type of the message
	 */
	async command am_id_t getType(message_t* msg);

	/**
	 * Sets the active message type
	 */
	async command void setType(message_t* msg, am_id_t type);

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
}
