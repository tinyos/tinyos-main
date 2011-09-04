/*
 * Copyright (c) 2010, University of Szeged
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

generic module AtmegaCompareP(typedef precision_tag, typedef size_type @integer(), uint8_t mode, uint16_t mindt)
{
	provides
	{
		interface Init @exactlyonce();
		interface Alarm<precision_tag, size_type>;
	}

	uses
	{
		interface AtmegaCounter<size_type>;
		interface AtmegaCompare<size_type>;
	}
}

implementation
{
	command error_t Init.init()
	{
		call AtmegaCompare.stop();
		call AtmegaCompare.setMode(mode);

		return SUCCESS;
	}

	default async event void Alarm.fired() { }

	// called in atomic context
	async event void AtmegaCompare.fired()
	{
		call AtmegaCompare.stop();
		signal Alarm.fired();
	}

	async command void Alarm.stop()
	{
		call AtmegaCompare.stop();
	}

	async command bool Alarm.isRunning()
	{
		return call AtmegaCompare.isOn();
	}

	// callers make sure that time is always in the future
	void setAlarm(size_type time)
	{
		call AtmegaCompare.set(time);
		call AtmegaCompare.reset();
		call AtmegaCompare.start();
	}

	async command void Alarm.startAt(size_type nt0, size_type ndt)
	{
		atomic
		{
			// current time + time needed to set alarm
			size_type n = call AtmegaCounter.get() + mindt;

			// if alarm is set in the future, where n-nt0 is the time passed since nt0
			if( (size_type)(n - nt0) < ndt )
				n = nt0 + ndt;

			setAlarm(n);
		}
	}

	async command void Alarm.start(size_type ndt)
	{
		atomic
		{
			size_type n = call AtmegaCounter.get();

			// calculate the next alarm
			n += (mindt > ndt) ? mindt : ndt;

			setAlarm(n);
		}
	}

	async command size_type Alarm.getNow()
	{
		return call AtmegaCounter.get();
	}

	async command size_type Alarm.getAlarm()
	{
		return call AtmegaCompare.get();
	}

	async event void AtmegaCounter.overflow() { }
}
