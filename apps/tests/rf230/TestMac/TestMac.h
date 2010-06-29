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

#ifndef __TESTMAC_H__
#define __TESTMAC_H__

/**
 * SEND_RATE the rate in milliseconds a source message should be sent out,
 * if this value is 0, then the message is sent from a task as fast as it can.
 * Set this value to -1 for turning off source messages.
 *
 * SEND_SOURCE the id of the source message. Each ping message contains a source
 * identifier and a sequence number. 
 *
 * SEND_TARGET the active message address of the source messages sent out by 
 * this node. Use AM_BROADCAST_ADDR to broadcast the message.
 *
 * SEND_ACK if it is set to 1, then packet acknowledgements are requested,
 * otherwise set it to 0
 *
 * SOURCE_COUNT the number of data sources in the network whose progress we 
 * need to monitor.
 */

// everybody transmit as fast as we can for up to five nodes with IDs 0 through 4
#if TESTCASE == 0
#define SOURCE_COUNT	5
#define SEND_TARGET		AM_BROADCAST_ADDR
#define SEND_SOURCE		TOS_NODE_ID
#define SEND_RATE		0
#define SEND_ACK		1

// one node sending message to another as fast as it can
#elif TESTCASE == 1
#define SOURCE_COUNT	2
#define SEND_TARGET		1
#define SEND_SOURCE		(TOS_NODE_ID == 0 ? 0 : -1)
#define SEND_RATE		(TOS_NODE_ID == 0 ? 0 : -1)
#define SEND_ACK		1

// two nodes sending messages to one another 200 msgs per second
#elif TESTCASE == 2
#define SOURCE_COUNT	2
#define SEND_TARGET		((TOS_NODE_ID+1) % SOURCE_COUNT)
#define SEND_SOURCE		TOS_NODE_ID
#define SEND_RATE		5
#define SEND_ACK		1

// two nodes sending messages to one another as fast as they can
#elif TESTCASE == 3
#define SOURCE_COUNT	2
#define SEND_TARGET		((TOS_NODE_ID+1) % SOURCE_COUNT)
#define SEND_SOURCE		TOS_NODE_ID
#define SEND_RATE		0
#define SEND_ACK		1

// three nodes sending messages to one another as fast as they can
#elif TESTCASE == 4
#define SOURCE_COUNT	3
#define SEND_TARGET		((TOS_NODE_ID+1) % SOURCE_COUNT)
#define SEND_SOURCE		TOS_NODE_ID
#define SEND_RATE		0
#define SEND_ACK		1

#endif

#endif//__TESTMAC_H__
