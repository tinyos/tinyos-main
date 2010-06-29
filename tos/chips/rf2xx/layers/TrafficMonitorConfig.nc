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

#include <Tasklet.h>

interface TrafficMonitorConfig
{
	/**
	 * Returns the frequency (in milliseconds) when the traffic averages
	 * should be updated. 
	 */
	async command uint16_t getUpdatePeriod();

	/**
	 * Returns the amount of time this message has occupied the channel.
	 */
	async command uint16_t getChannelTime(message_t* msg);

	/**
	 * Returns the sender address of the message so we can calculate the
	 * average number of neighbors that send messages per update period.
	 */
	async command am_addr_t getSender(message_t* msg);

	/**
	 * This event should be fired if we notice some anomalies in the operation
	 * of the channel, such as not receiving acknowledgements, missing
	 * sequence numbers or packets with corrupted CRC.
	 */
	tasklet_async event void channelError();

	/**
	 * Returns the averaged (exponential decay) transmit channel time 
	 * during one update period.
	 */
	tasklet_async event uint16_t getTransmitAverage();

	/**
	 * Returns the averaged (exponential decay) receive channel time 
	 * during one update period.
	 */
	tasklet_async event uint16_t getReceiveAverage();

	/**
	 * Returns the averaged (exponential decay) number of neighbors 
	 * whose messages this component receives during one update period.
	 */
	tasklet_async event uint8_t getNeighborAverage();

	/**
	 * Returns the averaged error events during one update period.
	 */
	tasklet_async event uint8_t getErrorAverage();
}
