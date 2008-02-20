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

interface PacketTimeSynch<precision_tag, size_type>
{
	/**
	 * The recveiver should call this method to ensure that the received 
	 * message contains an embedded timestamp and that is correct (for the 
	 * same reason as for PacketTimeStamp.isSet). If this method returns 
	 * TRUE, then the eventTime returned by the get command is correct,
	 * and reflects the event time in the local clock of the receiver.
	 */
	async command bool isSet(message_t* msg);

	/**
	 * This command should be called by the receiver. The time stamp of the
	 * received message is added to the embedded time difference to get the
	 * eventTime as measured by the clock of the receiver. The caller should
	 * call the isSet command before to make sure that the returned time is
	 * correct.
	 */
	async command size_type get(message_t* msg);

	/**
	 * Clears the time stamp in the message. 
	 */
	async command void clear(message_t* msg);

	/**
	 * This command should be called by the sender on packets used for sender- 
	 * receiver time synchronization. The eventTime parameter should be as 
	 * close to the current time as possible (precision and size of the stamp 
	 * permitting) to avoid large time synchronization errors resulting from
	 * the time skew between the clocks of the sender and receiver. The
	 * time difference between the sending time and eventTime is stored in 
	 * the message just before it is transmitted over the air.
	 */
	async command void set(message_t* msg, size_type eventTime);
}
