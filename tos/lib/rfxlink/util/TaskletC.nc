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

/*
 * Marcin K Szczodrak: update Tasklet to generic
 */

#include <Tasklet.h>
#include <RadioAssert.h>

generic module TaskletC()
{
	provides interface Tasklet;
}

implementation
{
#ifdef TASKLET_IS_TASK

	task void tasklet()
	{
		signal Tasklet.run();
	}

	inline async command void Tasklet.schedule()
	{
		post tasklet();
	}

	inline command void Tasklet.suspend()
	{
	}

	inline command void Tasklet.resume()
	{
	}

#else
	
	/**
	 * The lower 7 bits contain the number of suspends plus one if the run 
	 * event is currently beeing executed. The highest bit is set if the run 
	 * event needs to be called again when the suspend count goes down to zero.
	 */
	uint8_t state;

	void doit()
	{
		for(;;)
		{
			signal Tasklet.run();

			atomic
			{
				if( state == 1 )
				{
					state = 0;
					return;
				}

				RADIO_ASSERT( state == 0x81 );
				state = 1;
			}
		}
	}

	inline command void Tasklet.suspend()
	{
		atomic ++state;
	}

	command void Tasklet.resume()
	{
		atomic
		{
			if( --state != 0x80 )
				return;

			state = 1;
		}

		doit();
	}

	async command void Tasklet.schedule()
	{
		atomic
		{
			if( state != 0 )
			{
				state |= 0x80;
				return;
			}

			state = 1;
		}

		doit();
	}

#endif
}
