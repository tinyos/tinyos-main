/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * HPL implementation of interrupts and captures for the ChipCon
 * CC2420 radio connected to a TI MSP430 processor.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2010-01-20 18:17:32 $
 */
/**
 * Ported to the SHIMMER platform. 
 *
 * @author Konrad Lorincz
 * @date May 14, 2008
 * re-written to use interrupt-driven sfd capture; 
 * shimmer2 does not have sfd wired to a timer pin
 * @author Steve Ayer
 * @date January, 2010
 */

configuration HplCC2420InterruptsC {

  provides interface GpioCapture as CaptureSFD;
  provides interface GpioInterrupt as InterruptSFD;

  provides interface GpioInterrupt as InterruptCCA;
  provides interface GpioInterrupt as InterruptFIFOP;

}

implementation {

  components HplMsp430InterruptC;
  components new Msp430InterruptC() as InterruptCCAC;
  components new Msp430InterruptC() as InterruptFIFOPC;
  components new Msp430InterruptC() as InterruptSFDC;

  InterruptCCAC.HplInterrupt -> HplMsp430InterruptC.Port27;
  InterruptFIFOPC.HplInterrupt -> HplMsp430InterruptC.Port12;
  InterruptSFDC.HplInterrupt -> HplMsp430InterruptC.Port10;

  components HplCC2420InterruptsP;
  components Counter32khz16C;
  components new GpioCaptureC() as CaptureSFDC;
  components HplCC2420PinsC;

  CaptureSFD = HplCC2420InterruptsP.CaptureSFD;

  HplCC2420InterruptsP.InterruptSFD ->  InterruptSFDC.Interrupt;
  HplCC2420InterruptsP.Counter      -> Counter32khz16C;

  InterruptCCA = InterruptCCAC.Interrupt;
  InterruptFIFOP = InterruptFIFOPC.Interrupt;
  InterruptSFD = InterruptSFDC.Interrupt;
}
