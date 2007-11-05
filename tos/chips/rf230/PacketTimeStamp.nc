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

interface PacketTimeStamp<precision_tag, size_type>
{
	/**
	 * Returns TRUE if the time stamp stored in the message is valid. Under
	 * special circumstances the radio chip might not be able to correctly
	 * assign a precise time value to an incoming packet (e.g. under very 
	 * heavy traffic multiple interrupts can occur before they could be 
	 * serviced, and even if capture registers are used, it is not possible 
	 * to get the time stamp for the first or last unserviced event), in
	 * which case the time stamp value should not be used.
	 */
	async command bool isSet(message_t* msg);

	/**
	 * Return the time stamp for the given message. Please check with the 
	 * isSet command if this value can be relied upon. If this command is
	 * called after transmission, then the transmit time of the packet
	 * is returned (the time when the frame synchronization byte was 
	 * transmitted). If this command is called after the message is received,
	 * the tne receive time of the message is returned.
	 */
	async command size_type get(message_t* msg);

	/**
	 * Sets the isSet flag to FALSE.
	 */
	async command void clear(message_t* msg);

	/**
	 * Sets the isSet false to TRUE and the time stamp value to the 
	 * specified value.
	 */
	async command void set(message_t* msg, size_type value);
}
