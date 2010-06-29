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

interface PacketTimeStamp<precision_tag, size_type>
{
	/**
	 * @param 'message_t *ONE msg' Message to examine.
	 *
	 * Returns TRUE if the time stamp of the message is valid. Under special
	 * circumstances the radio chip might not be able to correctly assign a
	 * precise time value to an incoming packet (e.g. under very heavy traffic
	 * multiple interrupts can occur before they could be serviced, and even
	 * if capture registers are used, it is not possible to get the time stamp
	 * for the first or last unserviced event), in which case the time stamp
	 * value should not be used. It is recommended that the isValid command be
	 * called from the receive or sendDone event handler.
	 */
  async command bool isValid(message_t* msg);

	/**
	 * @param 'message_t *ONE msg' Message to get timestamp from.
	 *
	 * Return the time stamp for the given message. Please check with the
	 * isValid command if this value can be relied upon. If this command is
	 * called after transmission, then the transmit time of the packet
	 * is returned (the time when the frame synchronization byte was
	 * transmitted). If this command is called after the message is received,
	 * the tne receive time of the message is returned. It is recommended that
	 * the timestamp command be called only from the receive or sendDone event
	 * handler.
	 */
  async command size_type timestamp(message_t* msg);

	/**
	 * @param 'message_t *ONE msg' Message to modify.
	 *
	 * Sets the isValid flag to FALSE.
	 */
  async command void clear(message_t* msg);

	/**
	 * @param 'message_t *ONE msg' Message to modify.
	 *
	 * Sets the isValid flag to TRUE and the time stamp value to the
	 * specified value.
	 */
  async command void set(message_t* msg, size_type value);
}
