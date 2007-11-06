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
