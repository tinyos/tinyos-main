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

interface PacketLastTouch
{
	/**
	 * Requests the touch event to be called back just before the message
	 * transmission starts.
	 */
	async command void request(message_t* msg);

	/**
	 * Cancels any pending requests.
	 */
	async command void cancel(message_t* msg);

	/**
	 * Returns TRUE if the touch callback is already scheduled.
	 */
	async command bool isPending(message_t* msg);

	/**
	 * This event is called by the MAC layer when the tranmission of the
	 * message starts (the SFD byte is already transmitted and the packet
	 * is already time stamped). In this method the packet payload can be
	 * updated. This method MUST do absolutely minimal processing, and 
	 * should complete in 1-2 microseconds.
	 */
	async event void touch(message_t* msg);
}
