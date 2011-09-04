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

generic module AtmegaTransformCounterP(typedef to_size_t @integer(),
	typedef from_size_t @integer())
{
	provides interface AtmegaCounter<to_size_t>;

	uses
	{
		interface AtmegaCounter<from_size_t> as SubCounter;
		interface HighBits<to_size_t, from_size_t>;
	}
}

implementation
{
	async command to_size_t AtmegaCounter.get()
	{
		to_size_t value;
		from_size_t counter;
/*
		atomic
		{
			counter = call SubCounter.get();
			value = call HighBits.get();

			if( call SubCounter.test() )
			{
				counter = call SubCounter.get();
				value += call HighBits.convertHigh(1);
			}
		}

		value |= call HighBits.convertLow(counter);
*/

		uint8_t increment = 0;

		atomic
		{
			counter = call SubCounter.get();

			if( call SubCounter.test() )
			{
				increment = 1;
				counter = call SubCounter.get();
			}

			value = call HighBits.getXXX(counter, increment);
		}
		
		return value;
	}

	async command void AtmegaCounter.set(to_size_t value)
	{
		from_size_t counter;

		atomic
		{
			counter = call HighBits.set(value);
			call SubCounter.set(counter);
		}
	}

	default async event void AtmegaCounter.overflow() { }

	// WARNING: This event MUST be executed in atomic context, it 
	// does not help if we put the body inside an atomic block
	async event void SubCounter.overflow()
	{
		if( call HighBits.add(1) )
			signal AtmegaCounter.overflow();
	}

	// WARNING: This event MUST be executed in atomic context, it 
	// does not help if we put the body inside an atomic block
	async command bool AtmegaCounter.test()
	{
		return call SubCounter.test() && call HighBits.equals(-1);
	}

	async command void AtmegaCounter.reset()
	{
		call SubCounter.reset();
	}

	async command void AtmegaCounter.start()
	{
		call SubCounter.start();
	}

	async command void AtmegaCounter.stop()
	{
		call SubCounter.stop();
	}

	async command bool AtmegaCounter.isOn()
	{
		return call SubCounter.isOn();
	}

	async command void AtmegaCounter.setMode(uint8_t mode)
	{
		call SubCounter.setMode(mode);
	}

	async command uint8_t AtmegaCounter.getMode()
	{
		return call SubCounter.getMode();
	}
}
