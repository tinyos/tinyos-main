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

configuration HplAtmegaExtInterruptC
{
	provides interface HplAtmegaExtInterrupt[uint8_t vector];
}

implementation
{
	components HplAtmegaExtInterruptSigP, McuSleepC;

	HplAtmegaExtInterruptSigP.McuPowerOverride <- McuSleepC;
	HplAtmegaExtInterruptSigP.McuPowerState -> McuSleepC;

	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF0, (uint8_t)&EIMSK, INT0, (uint8_t)&EICRA, ISC00) as Int0P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF1, (uint8_t)&EIMSK, INT1, (uint8_t)&EICRA, ISC10) as Int1P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF2, (uint8_t)&EIMSK, INT2, (uint8_t)&EICRA, ISC20) as Int2P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF3, (uint8_t)&EIMSK, INT3, (uint8_t)&EICRA, ISC30) as Int3P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF4, (uint8_t)&EIMSK, INT4, (uint8_t)&EICRB, ISC40) as Int4P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF5, (uint8_t)&EIMSK, INT5, (uint8_t)&EICRB, ISC50) as Int5P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF6, (uint8_t)&EIMSK, INT6, (uint8_t)&EICRB, ISC60) as Int6P;
	components new HplAtmegaExtInterruptP((uint8_t)&EIFR, INTF7, (uint8_t)&EIMSK, INT7, (uint8_t)&EICRB, ISC70) as Int7P;

	HplAtmegaExtInterrupt[0] = Int0P;
	HplAtmegaExtInterrupt[1] = Int1P;
	HplAtmegaExtInterrupt[2] = Int2P;
	HplAtmegaExtInterrupt[3] = Int3P;
	HplAtmegaExtInterrupt[4] = Int4P;
	HplAtmegaExtInterrupt[5] = Int5P;
	HplAtmegaExtInterrupt[6] = Int6P;
	HplAtmegaExtInterrupt[7] = Int7P;

	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[0] <- Int0P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[1] <- Int1P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[2] <- Int2P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[3] <- Int3P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[4] <- Int4P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[5] <- Int5P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[6] <- Int6P;
	HplAtmegaExtInterruptSigP.HplAtmegaExtInterruptSig[7] <- Int7P;
}
