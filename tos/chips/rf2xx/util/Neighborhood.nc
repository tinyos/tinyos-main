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
