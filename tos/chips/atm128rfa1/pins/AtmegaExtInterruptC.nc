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

configuration AtmegaExtInterruptC
{
	provides interface GpioInterrupt[uint8_t vector];
}

implementation
{
	components HplAtmegaExtInterruptC;

	components new AtmegaExtInterruptP(FALSE) as Int0P;
	components new AtmegaExtInterruptP(FALSE) as Int1P;
	components new AtmegaExtInterruptP(FALSE) as Int2P;
	components new AtmegaExtInterruptP(FALSE) as Int3P;
	components new AtmegaExtInterruptP(TRUE) as Int4P;
	components new AtmegaExtInterruptP(TRUE) as Int5P;
	components new AtmegaExtInterruptP(TRUE) as Int6P;
	components new AtmegaExtInterruptP(TRUE) as Int7P;

	GpioInterrupt[0] = Int0P;
	GpioInterrupt[1] = Int1P;
	GpioInterrupt[2] = Int2P;
	GpioInterrupt[3] = Int3P;
	GpioInterrupt[4] = Int4P;
	GpioInterrupt[5] = Int5P;
	GpioInterrupt[6] = Int6P;
	GpioInterrupt[7] = Int7P;

	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[0] <- Int0P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[1] <- Int1P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[2] <- Int2P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[3] <- Int3P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[4] <- Int4P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[5] <- Int5P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[6] <- Int6P;
	HplAtmegaExtInterruptC.HplAtmegaExtInterrupt[7] <- Int7P;
}
