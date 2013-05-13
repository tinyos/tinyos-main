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

configuration PlatformC
{
	provides interface Init;
	// TODO: this should be moved to McuInit, but HplAtm128UartC wants it here
	provides interface Atm128Calibrate;
	uses interface Init as LedsInit;
}
implementation
{
	components PlatformP, McuInitC, MeasureClockC, Stm25pOffC, RF212OffC;
	components HplStm25pPinsC, HplRF212C;
	components HplAtm128GeneralIOC as GPIO;
	components BoardInitC;
  
	Init = PlatformP;
	Atm128Calibrate = MeasureClockC;

	LedsInit = PlatformP.LedsInit;
	PlatformP.McuInit -> McuInitC;

	PlatformP.Stm25pInit -> Stm25pOffC;
	PlatformP.RF212Init -> RF212OffC;
	PlatformP.BoardInit -> BoardInitC;
  #ifndef DISABLE_SERIAL_AUTO
    #warning SERIAL AUTO CONTROL ENABLED!
    components SerialAutoControlC;
  #endif
  #ifndef DISABLE_SERIAL_RESET
    #warning SERIAL RESET ENABLED!
    components SerialResetC;
  #endif
}
