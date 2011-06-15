/*
 * Copyright (c) 2011 Lulea University of Technology
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
 * - Neither the name of the copyright holders nor the names of
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

  components HplM16c60GeneralIOC as IOs;
  components new SoftwareSpiC() as Spi,
             new NoArbiterC();
  SpiResource = NoArbiterC;
  Spi.MISO -> IOs.PortP10;
  Spi.MOSI -> IOs.PortP11;
  Spi.SCLK -> IOs.PortP33;
  FastSpiByte = Spi;

  HplRF230P.PortVCC -> IOs.PortP77;
  HplRF230P.PortIRQ -> IOs.PortP83;
  HplRF230P.MISO -> IOs.PortP10;
  HplRF230P.MOSI -> IOs.PortP11;
  HplRF230P.SCLK -> IOs.PortP33;

  SLP_TR = IOs.PortP07;
  RSTN = IOs.PortP43;
  SELN = IOs.PortP35;

  components  HplM16c60InterruptC as Irqs,
      new M16c60InterruptC() as Irq;
  HplRF230P.GIRQ -> Irq;
  Irq -> Irqs.Int1;

  components AlarmRF23016C as AlarmRF230;
  HplRF230P.Alarm -> AlarmRF230;
  Alarm = AlarmRF230;

  components PlatformP;
  PlatformP.SubInit -> HplRF230P.PlatformInit;
    
  components LocalTimeMicroC;
  LocalTimeRadio = LocalTimeMicroC;
}
