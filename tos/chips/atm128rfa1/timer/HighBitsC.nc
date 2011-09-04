/*
 * Copyright (c) 2011, University of Szeged
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

/**
 * This component allows you to store and manipulate high and low
 * bits of an integer. You can freely use positive or negative 
 * bitshifts.
 *
 * The layout of to_size_t:
 * +------------------------------------+-----------------------------+
 * | high bits stored by this component | low bits given in arguments |
 * +------------------------------------+-----------------------------+
 *
 * The layout of from_size_t:
 * +-----------------------------+-----------------------------+
 * | low bits given in arguments | bitshift many discaded bits |
 * +-----------------------------+-----------------------------+
 *
 * The layout of high_bytes_t:
 * +------------------------------------+-------------+
 * | high bits stored by this component | always zero |
 * +------------------------------------+-------------+
 */
generic module HighBitsC(typedef to_size_t @integer(), typedef from_size_t @integer(), int8_t bitshift)
{
	provides interface HighBits<to_size_t, from_size_t>;
}

implementation
{
	enum
	{
		FROM_SIZE = sizeof(from_size_t),
		TO_SIZE = sizeof(to_size_t),
		BITSHIFT = bitshift,

		// the number of bits stored in memory
		HIGH_BITS = 8 * (TO_SIZE - FROM_SIZE) + BITSHIFT,

		// the number of bits obtained from user
		LOW_BITS = 8 * FROM_SIZE - BITSHIFT,

		// compile time checks
		TOO_SMALL_HIGHBITS_SHIFT = 1 / (HIGH_BITS > 0),
		TOO_LARGE_HIGHBITS_SHIFT = 1 / (LOW_BITS > 0),

		// number of bytes required to store high bits
		HIGH_SIZE = HIGH_BITS < 0 ? -1
			: HIGH_BITS == 0 ? 0
			: HIGH_BITS <= 8 ? 1
			: HIGH_BITS <= 16 ? 2
			: HIGH_BITS <= 32 ? 4
			: -1,
		
		// number of zero bits in high_bytes
		HIGH_ZEROS = 8 * HIGH_SIZE - HIGH_BITS,

		// shifts to align high_bytes into to_size
		HIGH_SHIFTS = 8 * (TO_SIZE - HIGH_SIZE),
	};

	uint8_t high_bytes[HIGH_SIZE];

	typedef union reg32_t
	{
		uint32_t full;
		struct 
		{
			uint16_t low;
			uint16_t high;
		};
	} reg32_t;

	async command to_size_t HighBits.getXXX(from_size_t low, int8_t increment)
	{
		to_size_t value;

		if( HIGH_SIZE == 2 )
		{
			reg32_t reg;
			reg.high = *(uint16_t*)high_bytes;
			reg.high += (int16_t)increment;
			reg.low = low;

			value = reg.full;
		}
		else
			value = 0;

		return value;
	}

	async command to_size_t HighBits.get()
	{
		to_size_t value;

		if( HIGH_SIZE == 1 )
		{
			uint8_t high = *(uint8_t*)high_bytes;
			value = ((to_size_t)high) << (HIGH_SIZE == 1 ? HIGH_SHIFTS : 0);
		}
		else if( HIGH_SIZE == 2 )
		{
			uint16_t high = *(uint16_t*)high_bytes;
			value = ((to_size_t)high) << (HIGH_SIZE == 2 ? HIGH_SHIFTS : 0);
		}
		else if( HIGH_SIZE == 4 )
		{
			uint32_t high = *(uint32_t*)high_bytes;
			value = ((to_size_t)high) << (HIGH_SIZE == 4 ? HIGH_SHIFTS : 0);
		}
		else
			value = 0;

		return value;

	}

	async command bool HighBits.add(int8_t high)
	{
		if( HIGH_SIZE == 1 )
		{
			return (*(uint8_t*)high_bytes += high << HIGH_ZEROS) == 0;
		}
		else if( HIGH_SIZE == 2 )
		{
			return (*(uint16_t*)high_bytes += ((int16_t)high) << HIGH_ZEROS) == 0;
		}
		else if( HIGH_SIZE == 4 )
		{
			return (*(uint32_t*)high_bytes += ((int32_t)high) << HIGH_ZEROS) == 0;
		}
		else
			return TRUE;
	}

	async command bool HighBits.equals(int8_t high)
	{
		if( HIGH_SIZE == 1 )
		{
			return (*(uint8_t*)high_bytes) + (high << HIGH_ZEROS) == 0;
		}
		else if( HIGH_SIZE == 2 )
		{
			return (*(uint16_t*)high_bytes) + (((int16_t)high) << HIGH_ZEROS) == 0;
		}
		else if( HIGH_SIZE == 4 )
		{
			return (*(uint32_t*)high_bytes) + (((int32_t)high) << HIGH_ZEROS) == 0;
		}
		else
			return TRUE;
	}

	async command to_size_t HighBits.convertLow(from_size_t low)
	{
		to_size_t value;

		if( BITSHIFT > 0 )
			value = ((to_size_t)low) >> (BITSHIFT > 0 ? BITSHIFT : 0);
		else if( BITSHIFT < 0 )
			value = ((to_size_t)low) << (BITSHIFT < 0 ? -BITSHIFT : 0);
		else
			value = (to_size_t)low;

		return value;
	}

	inline async command to_size_t HighBits.convertHigh(int8_t high)
	{
		if( TO_SIZE == 1 )
		{
			return ((int8_t)high) << (TO_SIZE == 1 ? LOW_BITS : 0);
		}
		else if( TO_SIZE == 2 )
		{
			return ((int16_t)high) << (TO_SIZE == 2 ? LOW_BITS : 0);
		}
		else if( TO_SIZE == 4 )
		{
			return ((int32_t)high) << (TO_SIZE == 4 ? LOW_BITS : 0);
		}
		else
			return 0;
	}

	async command from_size_t HighBits.set(to_size_t value)
	{
		// TODO: implement it
		return 0;
	}
}
