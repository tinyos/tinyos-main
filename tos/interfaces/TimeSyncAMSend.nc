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
 */

/**
  * @author Philip Levis
  * @author Miklos Maroti
  *
  * @see TimeSyncPacket
  */

#include <TinyError.h>
#include <message.h>
#include <AM.h>

interface TimeSyncAMSend<precision_tag, size_type>
{
	/**
	* This command sends a regular message just like <tt>AMSend.send</tt>, but
	* it also performs sender-receiver time synchronization. The <tt>event_time</tt>
	* parameter holds the time of some event as expressed in the local clock of
	* the sender. The receiver can obtain the time of this event (expressed in its
	* own local time) via the <tt>TimeSyncPacket</tt> interface.
	*
	* @param addr         address to which to send the packet
	* @param msg          the packet
	* @param len          the length of the data in the packet payload
	* @param event_time	  the synchronization point to be transfered with the message
	* @return             SUCCESS if the request to send succeeded and a
	*                     sendDone will be signaled later, EBUSY if the
	*                     abstraction cannot send now but will be able to
	*                     later, or FAIL if the communication layer is not
	*                     in a state that can send (e.g., off).
  * @see sendDone
	*/
  command error_t send(am_addr_t addr, message_t* msg, uint8_t len, size_type event_time);

	/**
	* Cancel a requested transmission. Returns SUCCESS if the
	* transmission was canceled properly (not sent in its
	* entirety). Note that the component may not know
	* if the send was successfully canceled, if the radio is
	* handling much of the logic; in this case, a component
	* should be conservative and return an appropriate error code.
	* A successful call to cancel must always result in a
	* sendFailed event, and never a sendSucceeded event.
	*
	* @param  msg     the packet whose transmission should be cancelled.
	* @return SUCCESS if the transmission was cancelled, FAIL otherwise.
	* @see    sendDone
	*/
	command error_t cancel(message_t* msg);

	/**
	* Signaled in response to an accepted send request. <tt>msg</tt> is
	* the message buffer sent, and <tt>error</tt> indicates whether
	* the send was successful.
	*
	* @param  msg   the packet which was submitted as a send request
	* @param  error SUCCESS if it was sent successfully, FAIL if it was not,
	*               ECANCEL if it was cancelled
	* @see send
	* @see cancel
	*/
	event void sendDone(message_t* msg, error_t error);

	/**
	* Return the maximum payload length that this communication layer
	* can provide. This command behaves identically to
	* <tt>Packet.maxPayloadLength</tt> and is included in this
	* interface as a convenience.
	*
	* @return the maximum payload length
	*/
	command uint8_t maxPayloadLength();

	/**
	* Return a pointer to a protocol's payload region in a packet.
	* This command behaves identically to <tt>Packet.getPayload</tt>
	* (minus the length parameter) and is included in this interface
	* as a convenience.
	*
	* @param  msg    the packet
	* @return        the payload of the packet
	*/
	command void* getPayload(message_t* msg, uint8_t len);
}
