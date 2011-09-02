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
 * - Neither the name of the copyright holders nor the names of
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

#include "message.h"

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
