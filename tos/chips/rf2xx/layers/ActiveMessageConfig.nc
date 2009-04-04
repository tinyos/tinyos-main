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

#include <ActiveMessageLayer.h>

interface ActiveMessageConfig
{
	/**
	 * This command is called when the message first enters the radio stack
	 * via the Send.send command. This should clear the packet if the user
	 * forgot to do so (or return EINVAL to be strict).
	 */
	command error_t checkPacket(message_t* msg);

	/**
	 * Returns a pointer to the ActiveMessage header field in the message
	 */
	command activemessage_header_t* getHeader(message_t* msg);

	/** Same as AMPacket.destination */
	command am_addr_t destination(message_t* msg);

	/** Same as AMPacket.setDestination */
	command void setDestination(message_t* msg, am_addr_t addr);

	/** Same as AMPacket.source */
	command am_addr_t source(message_t* msg);

	/** Same as AMPacket.setSource */
	command void setSource(message_t* msg, am_addr_t addr);

	/** Same as AMPacket.group */
	command am_group_t group(message_t* msg);

	/** Same as AMPacket.setGroup */
	command void setGroup(message_t* msg, am_group_t grp);
}
