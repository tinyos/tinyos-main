/*
 * Copyright (c) 2002, Vanderbilt University
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
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 */

#if defined(TIMESYNCMSG_H)
#else
#define TIMESYNCMSG_H

typedef nx_struct TimeSyncMsg
{
	nx_uint16_t	rootID;		// the node id of the synchronization root
	nx_uint16_t	nodeID;		// the node if of the sender
	nx_uint8_t	seqNum;		// sequence number for the root

	/* This field is initially set to the offset between global time and local
	 * time. The TimeStamping component will add the current local time when the
	 * message is actually transmitted. Thus the receiver will receive the
	 * global time of the sender when the message is actually sent. */
	nx_uint32_t	globalTime;

	//just for convenience
	nx_uint32_t 	localTime;
} TimeSyncMsg;

enum {
    AM_TIMESYNCMSG = 0xAA,
    TIMESYNCMSG_LEN = sizeof(TimeSyncMsg) - sizeof(nx_uint32_t),
    TS_TIMER_MODE = 0,      // see TimeSyncMode interface
    TS_USER_MODE = 1,       // see TimeSyncMode interface
};

#endif
