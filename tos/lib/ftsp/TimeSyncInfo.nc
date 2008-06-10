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

interface TimeSyncInfo
{
	/**
	 * Returns current offset of the local time wrt global time.
	 */
	async command uint32_t getOffset();

	/**
	 * Returns current skew of the local time wrt global time.
	 * This value is normalized to 0.0 (1.0 is subtracted) to get maximum 
	 * representation precision.
	 */
	async command float getSkew();

	/**
	 * Returns the local time of the last synchronization point. This 
	 * value is close to the current local time and updated when a new
	 * time synchronization message arrives.
	 */
	async command uint32_t getSyncPoint();

	/**
	 * Returns the current root to which this node is synchronized. 
	 */
	async command uint16_t getRootID();

	/**
	 * Returns the latest seq number seen from the current root.
	 */
	async command uint8_t getSeqNum();

	/**
	 * Returns the number of entries stored currently in the 
	 * regerssion table.
	 */
	async command uint8_t getNumEntries();

	/**
	 * Returns the value of heartBeats variable. 
	 */
	async command uint8_t getHeartBeats();
}
