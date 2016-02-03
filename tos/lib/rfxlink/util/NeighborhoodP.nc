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

generic module NeighborhoodP(uint8_t size)
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
	tasklet_norace am_addr_t nodes[size];
	tasklet_norace uint8_t ages[size];
	tasklet_norace uint8_t flags[size];
	tasklet_norace uint8_t time;
	tasklet_norace uint8_t last;

	command error_t Init.init()
	{
		uint8_t i;

		for(i = 0; i < size; ++i)
			nodes[i] = AM_BROADCAST_ADDR;
	
		return SUCCESS;
	}

	inline tasklet_async command am_addr_t Neighborhood.getNode(uint8_t idx)
	{
		return nodes[idx];
	}

	inline tasklet_async command uint8_t Neighborhood.getAge(uint8_t idx)
	{
		return time - ages[idx];
	}

	tasklet_async uint8_t command Neighborhood.getIndex(am_addr_t node)
	{
		uint8_t i;

		if( nodes[last] == node )
			return last;

		for(i = 0; i < size; ++i)
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

			for(i = 0; i < size; ++i)
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

			if( i == size )
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
			for(i = 0; i < size; ++i)
			{
				if( (ages[i] | 0x7F) != time )
					ages[i] = time & 0x80;
			}
		}

		return last;
	}

	inline tasklet_async command bool NeighborhoodFlag.get[uint8_t bit](uint8_t idx)
	{
		return flags[idx] & (1 << bit);
	}

	inline tasklet_async command void NeighborhoodFlag.set[uint8_t bit](uint8_t idx)
	{
		flags[idx] |= (1 << bit);
	}

	inline tasklet_async command void NeighborhoodFlag.clear[uint8_t bit](uint8_t idx)
	{
		flags[idx] &= ~(1 << bit);
	}

	tasklet_async command void NeighborhoodFlag.clearAll[uint8_t bit]()
	{
		uint8_t i;

		bit = ~(1 << bit);

		for(i = 0; i < size; ++i)
			flags[i] &= bit;
	}
}
