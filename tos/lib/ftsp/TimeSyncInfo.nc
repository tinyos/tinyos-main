/*
 * Copyright (c) 2002, Vanderbilt University
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
