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

	/**
	 * This command is periodically called when the timer is fired and
	 * the averages are updated
	 */
	tasklet_async command void timerTick();
}
