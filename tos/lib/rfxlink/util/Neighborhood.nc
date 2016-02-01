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

#include <AM.h>
#include <Tasklet.h>

/**
 * Every component maintains its own neighborhood data. The Neighboorhood
 * component maintains only the nodeids and ages of the neighbors, and
 * evicts old entries from the table when necessary.
 */
interface Neighborhood
{
	/**
	 * Returns the index of the neighbor in the table. If the node was not 
	 * found in the table, then the value NEIGHBORHOOD is  returned, 
	 * otherwise an index in the range [0, NEIGHBORHOOD-1] is returned.
	 */
	tasklet_async command uint8_t getIndex(am_addr_t id);

	/**
	 * Returns the age of the given entry. The age is incremented by one
	 * every time a new node is inserted into the neighborhood table that
	 * is not already at the very end. If the age would get too large to
	 * fit into a byte, then it is periodically reset to a smaller value.
	 */
	tasklet_async command uint8_t getAge(uint8_t idx);

	/**
	 * Returns the node address for the given entry.
	 */
	tasklet_async command am_addr_t getNode(uint8_t idx);

	/**
	 * Adds a new node into the neighborhood table. If this node was already
	 * in the table, then it is just brought to the front (its age is reset
	 * to zero). If the node was not in the table, then the oldest is evicted
	 * and its entry is replaced with this node. The index of the entry
	 * is returned in the range [0, NEIGHBORHOOD-1]. 
	 */
	tasklet_async command uint8_t insertNode(am_addr_t id);

	/**
	 * This event is fired when the oldest entry is replaced with a new
	 * node. The same interface is used by many users, so all of them
	 * will receive this event and can clear the corresponding entry.
	 * After this event is fired, all flags for this entry are cleared
	 * (see the NeighborhoodFlag interface)
	 */
	tasklet_async event void evicted(uint8_t idx);
}
