/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
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
 * Mulle specific wiring of the HplRF230C configuration.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
 
#include <RadioConfig.h>

configuration HplRF230C
{
  provides
  {
    interface GeneralIO as SELN;
    interface Resource as SpiResource;
    interface SpiByte;
    interface FastSpiByte;

    interface GeneralIO as SLP_TR;
    interface GeneralIO as RSTN;

    interface GpioCapture as IRQ;
    interface Alarm<TRadio, uint16_t> as Alarm;
    interface LocalTime<TRadio> as LocalTimeRadio;
  }
}
implementation
{
  components HplRF230P;
  IRQ = HplRF230P.IRQ;

  components new SoftSpiRF230C() as Spi;
  HplRF230P.Spi -> Spi;
  SpiResource = Spi;
  SpiByte = Spi;
  FastSpiByte = HplRF230P.FastSpiByte;

  components HplM16c62pGeneralIOC as IOs;
  HplRF230P.PortVCC -> IOs.PortP77;
  HplRF230P.PortIRQ -> IOs.PortP83;
  SLP_TR = IOs.PortP07;
  RSTN = IOs.PortP43;
  SELN = IOs.PortP35;

  components  HplM16c62pInterruptC as Irqs,
      new M16c62pInterruptC() as Irq;
  HplRF230P.GIRQ -> Irq;
  Irq -> Irqs.Int1;

  components AlarmRF23016C as AlarmRF230;
  HplRF230P.Alarm -> AlarmRF230;
  Alarm = AlarmRF230;

  components RealMainP;
  RealMainP.PlatformInit -> HplRF230P.PlatformInit;
    
  components LocalTimeMicroC;
  LocalTimeRadio = LocalTimeMicroC;
}
