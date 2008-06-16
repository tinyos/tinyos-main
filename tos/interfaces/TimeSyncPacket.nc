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

interface TimeSyncPacket<precision_tag, size_type>
{
	/**
	 * Returns TRUE if the value returned by <tt>getTime</tt> can be trusted.
	 * Under certain circumstances the received message cannot be properly
	 * time stamped, so the sender-receiver synchronization cannot be finished
	 * on the receiver side. In this case, this command returns FALSE.
	 * This command MUST BE called only on the receiver side and only for
	 * messages transmitted via the TimeSyncSend interface. It is recommended
	 * that this command be called from the receive event handler.
	 */
	command bool isValid(message_t* msg);

	/**
	 * This command should be called by the receiver of a message. The time
	 * of the synchronization event is returned as expressed in the local
	 * clock of the caller. This command MUST BE called only on the receiver
	 * side and only for messages transmitted via the TimeSyncSend interface.
	 * It is recommended that this command be called from the receive event
	 * handler.
	 */
	command size_type eventTime(message_t* msg);
}
