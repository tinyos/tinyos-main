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

generic module AtmegaTransformCounterC(typedef to_size_t @integer(),
	typedef from_size_t @integer(), int bitshift)
{
	provides interface HplAtmegaCounter<to_size_t>;
	uses interface HplAtmegaCounter<from_size_t> as SubCounter;
}

/**
 * This component allows you to store and manipulate high and low
 * bits of an integer. You can freely use positive or negative 
 * bitshifts.
 *
 * The layout of to_size_t:
 * +------------------------------------+-------------------------------+
 * | high bits stored by this component | low bits stored in subcounter |
 * +------------------------------------+-------------------------------+
 *
 * The layout of from_size_t:
 * +-------------------------------+-----------------------------+
 * | low bits stored in subcounter | bitshift many discaded bits |
 * +-------------------------------+-----------------------------+
 *
 * The layout of high_bytes:
 * +------------------------------------+------------------+
 * | high bits stored by this component | always zero bits | 
 * +------------------------------------+------------------+
 */

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
		HIGH_SIZE = HIGH_BITS <= 0 ? -1
			: HIGH_BITS <= 8 ? 1
			: HIGH_BITS <= 16 ? 2
			: HIGH_BITS <= 32 ? 4
			: -1,
		
		// number of zero bits in high_bytes
		ZERO_BITS = HIGH_SIZE * 8 - HIGH_BITS,

		// the representation of one in high_bytes
		INCREMENT = 1ul << ZERO_BITS,
	};

	uint8_t high_bytes[HIGH_SIZE];

	inline bool isNotNegative(from_size_t low)
	{
		if( FROM_SIZE == 1 )
			return (int8_t)low >= (FROM_SIZE == 1 ? 0 : 1);
		else if( FROM_SIZE == 2 )
			return (int16_t)low >= (FROM_SIZE == 2 ? 0 : 1);
		else if( FROM_SIZE == 4 )
			return (int32_t)low >= (FROM_SIZE == 4 ? 0 : 1);
	}

	async command to_size_t HplAtmegaCounter.get()
	{
		from_size_t low;
		to_size_t value;

		uint8_t high8;
		uint16_t high16;
		uint32_t high32;

		atomic
		{
			low = call SubCounter.get();

			if( HIGH_SIZE == 1 )
			{
				high8 = *(uint8_t*)high_bytes;
				if( isNotNegative(low) && call SubCounter.test() )
					high8 += INCREMENT;
			}
			else if( HIGH_SIZE == 2 )
			{
				high16 = *(uint16_t*)high_bytes;
				if( isNotNegative(low) && call SubCounter.test() )
					high16 += INCREMENT;
			}
			else if( HIGH_SIZE == 4 )
			{
				high32 = *(uint32_t*)high_bytes;
				if( isNotNegative(low) && call SubCounter.test() )
					high32 += INCREMENT;
			}
		}

		if( HIGH_SIZE == 1 )
			value = high8;
		else if( HIGH_SIZE == 2 )
			value = high16;
		else
			value = high32;

		value <<= LOW_BITS - ZERO_BITS;
		value |= low >> BITSHIFT;
		return value;
	}

	async command void HplAtmegaCounter.set(to_size_t value)
	{
	}

	default async event void HplAtmegaCounter.overflow() { }

	// WARNING: This event MUST be executed in atomic context, it 
	// does not help if we put the body inside an atomic block
	async event void SubCounter.overflow()
	{
		bool overflow;

		if( HIGH_SIZE == 1 )
			overflow = ((*(uint8_t*)high_bytes += INCREMENT) == 0);
		else if( HIGH_SIZE == 2 )
			overflow = ((*(uint16_t*)high_bytes += INCREMENT) == 0);
		else if( HIGH_SIZE == 4 )
			overflow = ((*(uint32_t*)high_bytes += INCREMENT) == 0);

		if( overflow )
			signal HplAtmegaCounter.overflow();
	}

	// WARNING: This event MUST be executed in atomic context, it 
	// does not help if we put the body inside an atomic block
	async command bool HplAtmegaCounter.test()
	{
		return call SubCounter.test() && high_bytes[0] == -1;
	}

	async command void HplAtmegaCounter.reset()
	{
		call SubCounter.reset();
	}

	async command void HplAtmegaCounter.start()
	{
		call SubCounter.start();
	}

	async command void HplAtmegaCounter.stop()
	{
		call SubCounter.stop();
	}

	async command bool HplAtmegaCounter.isOn()
	{
		return call SubCounter.isOn();
	}

	async command void HplAtmegaCounter.setMode(uint8_t mode)
	{
		call SubCounter.setMode(mode);
	}

	async command uint8_t HplAtmegaCounter.getMode()
	{
		return call SubCounter.getMode();
	}
}
