/*
 * Copyright (c) 2009, Vanderbilt University
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

interface BareSend
{
	/**
	 * Starts the transmission of the given message. This command must not
	 * be called while another send is in progress (so one must wait for the
	 * sendDone event). Returns EBUSY if a reception is in progress or for
	 * some other reason the request cannot be temporarily satisfied (e.g.
	 * the SPI bus access could not be acquired). In this case the send 
	 * command could be retried from a task. Returns SUCCESS if the 
	 * transmission could be started. In this case sendDone will be fired.
	 */
	command error_t send(message_t* msg);
	
	/**
	 * Signals the completion of the send command, exactly once for each 
	 * successfull send command. If the returned error code is SUCCESS, then 
	 * the message was sent (may not have been acknowledged), otherwise 
	 * the message was not transmitted over the air.
	 */
	event void sendDone(message_t* msg, error_t error);

	/**
	 * Cancel a requested transmission. Returns SUCCESS if the 
	 * transmission was cancelled properly (not sent in its
	 * entirety). Note that the component may not know
	 * if the send was successfully cancelled, if the radio is
	 * handling much of the logic; in this case, a component
	 * should be conservative and return an appropriate error code.
	 */
	command error_t cancel(message_t* msg);
}
