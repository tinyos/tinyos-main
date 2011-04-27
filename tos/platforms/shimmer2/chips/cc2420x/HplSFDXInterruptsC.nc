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
 * @version $Revision: 1.1 $ $Date: 2011-04-27 19:36:45 $
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

configuration HplSFDXInterruptsC {
  provides interface GpioCapture as SfdCapture;
  provides interface GpioInterrupt as InterruptSFD;
}

implementation {
  components HplMsp430InterruptC;
  components new Msp430InterruptC() as InterruptSFDC;

  InterruptSFDC.HplInterrupt -> HplMsp430InterruptC.Port10;

  components HplCC2420XInterruptsP;
  components Counter32khz16C;
  components new GpioCaptureC() as SfdCaptureC;

  SfdCapture = HplCC2420XInterruptsP.SfdCapture;

  HplCC2420XInterruptsP.InterruptSFD ->  InterruptSFDC.Interrupt;
  HplCC2420XInterruptsP.Counter      -> Counter32khz16C;

  InterruptSFD = InterruptSFDC.Interrupt;
  
  components LedsC;
  HplCC2420XInterruptsP.Leds      -> LedsC;
  
}
