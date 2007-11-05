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
#include <RadioAssert.h>

module TaskletC
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

				ASSERT( state == 0x81 );
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
