/*
 * Copyright (c) 2009 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

configuration HilSam3UartC
{
	provides
	{
		interface StdControl;
		interface UartByte;
		interface UartStream;
	}
}
implementation
{
	components HilSam3UartP;
	StdControl = HilSam3UartP;
	UartByte = HilSam3UartP;
	UartStream = HilSam3UartP;

	components HplSam3UartC;
	HilSam3UartP.HplSam3UartInterrupts -> HplSam3UartC;
	HilSam3UartP.HplSam3UartStatus -> HplSam3UartC;
	HilSam3UartP.HplSam3UartControl -> HplSam3UartC;
	HilSam3UartP.HplSam3UartConfig -> HplSam3UartC;

#ifdef THREADS
	components PlatformInterruptC;
	HplSam3UartC.PlatformInterrupt -> PlatformInterruptC;
#endif

	components MainC;
	MainC.SoftwareInit -> HilSam3UartP.Init;

	components HplNVICC;
	HilSam3UartP.UartIrqControl -> HplNVICC.DBGUInterrupt;

	components HplSam3uGeneralIOC;
	HilSam3UartP.UartPin1 -> HplSam3uGeneralIOC.HplPioA11;
	HilSam3UartP.UartPin2 -> HplSam3uGeneralIOC.HplPioA12;

	components HplSam3uClockC;
	HilSam3UartP.UartClockControl -> HplSam3uClockC.DBGUPPCntl;
	HilSam3UartP.ClockConfig -> HplSam3uClockC;
}
