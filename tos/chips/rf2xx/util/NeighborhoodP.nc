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

#include <Neighborhood.h>

module NeighborhoodP
{
	provides
	{
		interface Init;
		interface Neighborhood;
		interface NeighborhoodFlag[uint8_t bit];
	}
}

implementation
{
	tasklet_norace am_addr_t nodes[NEIGHBORHOOD_SIZE];
	tasklet_norace uint8_t ages[NEIGHBORHOOD_SIZE];
	tasklet_norace uint8_t flags[NEIGHBORHOOD_SIZE];
	tasklet_norace uint8_t time;
	tasklet_norace uint8_t last;

	command error_t Init.init()
	{
		uint8_t i;

		for(i = 0; i < NEIGHBORHOOD_SIZE; ++i)
			nodes[i] = AM_BROADCAST_ADDR;
	
		return SUCCESS;
	}

	inline tasklet_async command am_addr_t Neighborhood.getNode(uint8_t index)
	{
		return nodes[index];
	}

	inline tasklet_async command uint8_t Neighborhood.getAge(uint8_t index)
	{
		return time - ages[index];
	}

	tasklet_async uint8_t command Neighborhood.getIndex(am_addr_t node)
	{
		uint8_t i;

		if( nodes[last] == node )
			return last;

		for(i = 0; i < NEIGHBORHOOD_SIZE; ++i)
		{
			if( nodes[i] == node )
			{
				last = i;
				break;
			}
		}

		return i;
	}

	tasklet_async uint8_t command Neighborhood.insertNode(am_addr_t node)
	{
		uint8_t i;
		uint8_t maxAge;

		if( nodes[last] == node )
		{
			if( ages[last] == time )
				return last;

			ages[last] = ++time;
			maxAge = 0x80;
		}
		else
		{
			uint8_t oldest = 0;
			maxAge = 0;

			for(i = 0; i < NEIGHBORHOOD_SIZE; ++i)
			{
				uint8_t age;

				if( nodes[i] == node )
				{
					last = i;
					if( ages[i] == time )
						return i;

					ages[i] = ++time;
					maxAge = 0x80;
					break;
				}

				age = time - ages[i];
				if( age > maxAge )
				{
					maxAge = age;
					oldest = i;
				}
			}

			if( i == NEIGHBORHOOD_SIZE )
			{
				signal Neighborhood.evicted(oldest);

				last = oldest;
				nodes[oldest] = node;
				ages[oldest] = ++time;
				flags[oldest] = 0;
			}
		}

		if( (time & 0x7F) == 0x7F && maxAge >= 0x7F )
		{
			for(i = 0; i < NEIGHBORHOOD_SIZE; ++i)
			{
				if( (ages[i] | 0x7F) != time )
					ages[i] = time & 0x80;
			}
		}

		return last;
	}

	inline tasklet_async command bool NeighborhoodFlag.get[uint8_t bit](uint8_t index)
	{
		return flags[index] & (1 << bit);
	}

	inline tasklet_async command void NeighborhoodFlag.set[uint8_t bit](uint8_t index)
	{
		flags[index] |= (1 << bit);
	}

	inline tasklet_async command void NeighborhoodFlag.clear[uint8_t bit](uint8_t index)
	{
		flags[index] &= ~(1 << bit);
	}

	tasklet_async command void NeighborhoodFlag.clearAll[uint8_t bit]()
	{
		uint8_t i;

		bit = ~(1 << bit);

		for(i = 0; i < NEIGHBORHOOD_SIZE; ++i)
			flags[i] &= bit;
	}
}
