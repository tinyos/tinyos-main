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

#include <ActiveMessageLayer.h>

interface ActiveMessageConfig
{
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

	/**
	 * Check if the packet is properly formatted, and if the user 
	 * forgot to call Packet.clear then format it properly.
	 * Return SUCCESS if the frame is now properly set up, 
	 * or FAIL of the send operation should be aborted.
	 */
	command error_t checkFrame(message_t* msg);
}
