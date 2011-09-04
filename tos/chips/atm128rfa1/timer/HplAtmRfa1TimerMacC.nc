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

#include "HplAtmRfa1Timer.h"

configuration HplAtmRfa1TimerMacC
{
	provides
	{
		interface AtmegaCounter<uint32_t> as Counter;
		interface AtmegaCompare<uint32_t> as Compare[uint8_t id];
		interface AtmegaCapture<uint32_t> as SfdCapture;
	}
}

implementation
{
	components HplAtmRfa1TimerMacP;

	Counter = HplAtmRfa1TimerMacP;
	Compare[0] = HplAtmRfa1TimerMacP.CompareA;
	Compare[1] = HplAtmRfa1TimerMacP.CompareB;
	Compare[2] = HplAtmRfa1TimerMacP.CompareC;
	SfdCapture = HplAtmRfa1TimerMacP.SfdCapture;

	components McuSleepC;
	HplAtmRfa1TimerMacP.McuPowerState -> McuSleepC;
	HplAtmRfa1TimerMacP.McuPowerOverride <- McuSleepC;
}
