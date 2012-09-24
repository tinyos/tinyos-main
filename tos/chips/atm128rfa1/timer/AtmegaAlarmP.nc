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

generic module AtmegaAlarmP(typedef precision_tag, typedef size_type @integer(), uint8_t mode, uint16_t mindt)
{
	provides
	{
		interface Init @exactlyonce();
		interface Alarm<precision_tag, size_type>;
	}

	uses
	{
		interface HplAtmegaCounter<size_type>;
		interface HplAtmegaCompare<size_type>;
	}
}

implementation
{
	command error_t Init.init()
	{
		call HplAtmegaCompare.stop();
		call HplAtmegaCompare.setMode(mode);

		return SUCCESS;
	}

	default async event void Alarm.fired() { }

	// called in atomic context
	async event void HplAtmegaCompare.fired()
	{
		call HplAtmegaCompare.stop();
		signal Alarm.fired();
	}

	async command void Alarm.stop()
	{
		call HplAtmegaCompare.stop();
	}

	async command bool Alarm.isRunning()
	{
		return call HplAtmegaCompare.isOn();
	}

	// callers make sure that time is always in the future
	void setAlarm(size_type time)
	{
		call HplAtmegaCompare.set(time);
		call HplAtmegaCompare.reset();
		call HplAtmegaCompare.start();
	}

	async command void Alarm.startAt(size_type nt0, size_type ndt)
	{
		atomic
		{
			// current time + time needed to set alarm
			size_type n = call HplAtmegaCounter.get() + mindt;

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
			size_type n = call HplAtmegaCounter.get();

			// calculate the next alarm
			n += (mindt > ndt) ? mindt : ndt;

			setAlarm(n);
		}
	}

	async command size_type Alarm.getNow()
	{
		return call HplAtmegaCounter.get();
	}

	async command size_type Alarm.getAlarm()
	{
		return call HplAtmegaCompare.get();
	}

	async event void HplAtmegaCounter.overflow() { }
}
