/*
 * Copyright (c) 2011 University of Utah. 
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
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 */

configuration Sam3sDacC
{
  provides
  {
    interface StdControl;
    interface Sam3sDac;
  }
}
implementation
{
  components Sam3sDacP as DacP,
             LedsC, NoLedsC,
             HplNVICC,
             HplSam3sClockC,
             HplSam3sGeneralIOC;

  StdControl = DacP;
  Sam3sDac = DacP;

  DacP.DacInterrupt -> HplNVICC.DACCInterrupt;
  DacP.DacPin0 -> HplSam3sGeneralIOC.HplPioB13;
  DacP.DacPin1 -> HplSam3sGeneralIOC.HplPioB14;
  DacP.DacClockControl -> HplSam3sClockC.DACCCntl;
  DacP.ClockConfig -> HplSam3sClockC;

  components McuSleepC;
  DacP.DacInterruptWrapper -> McuSleepC;

  components HplSam3sPdcC;
  DacP.HplPdc -> HplSam3sPdcC.DacPdcControl;

  components Sam3sPwmC;
  DacP.PwmControl -> Sam3sPwmC;
  DacP.Pwm -> Sam3sPwmC;

  DacP.Leds -> NoLedsC;
}
