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
 *
 *
 * @author Thomas Schmid
 */

#include <RadioConfig.h>

configuration HplCC2520C
{
    provides
    {

      interface GeneralIO as CCA;
      interface GeneralIO as CSN;
      interface GeneralIO as FIFO;
      interface GeneralIO as FIFOP;
      interface GeneralIO as RSTN;
      interface GeneralIO as SFD;
      interface GeneralIO as VREN;
      interface GpioCapture as SfdCapture;
      interface GpioInterrupt as FifopInterrupt;
      interface GpioInterrupt as FifoInterrupt;

      interface SpiByte;
      interface SpiPacket;


      interface Resource as SpiResource;

      //interface FastSpiByte;

      //interface GeneralIO as SLP_TR;
      //interface GeneralIO as RSTN;

      //interface GpioCapture as IRQ;
      interface Alarm<TRadio, uint16_t> as Alarm;
      interface LocalTime<TRadio> as LocalTimeRadio;
    }
}

implementation
{
  components new Sam3Spi2C() as SpiC;
  SpiResource = SpiC;
  SpiByte = SpiC;
  SpiPacket = SpiC;

  components CC2520SpiConfigC as RadioSpiConfigC;
  RadioSpiConfigC.Init <- SpiC;
  RadioSpiConfigC.ResourceConfigure <- SpiC;
  RadioSpiConfigC.HplSam3SpiChipSelConfig -> SpiC;

  /*
    components HplSam3sGeneralIOC as IO;
    SLP_TR = IO.PioC22;
    RSTN = IO.PioC27;
    SELN = IO.PioA19;
    
    components HplSam3sGeneralIOC;
    IRQ = HplSam3sGeneralIOC.CapturePioB1;
  */

  components HplSam3sGeneralIOC as IO;

  CCA    = IO.PioA25; // need to remove R26 & R36!
  CSN    = IO.PioB2;
  FIFO   = IO.PioA24; // need to remove R27 & R37!
  FIFOP  = IO.PioA16;
  RSTN   = IO.PioA18;
  SFD    = IO.PioA15;
  VREN   = IO.PioA17;

  components new GpioCaptureC() as SfdCaptureC;
  components HplSam3TCC;
  SfdCapture = SfdCaptureC;
  SfdCaptureC.TCCapture -> HplSam3TCC.TC1Capture; // TIOA1
  SfdCaptureC.GeneralIO -> IO.HplPioA15;

  FifopInterrupt = IO.InterruptPioA16;
  FifoInterrupt = IO.InterruptPioA24;

  components new AlarmTMicro16C() as AlarmC;
  Alarm = AlarmC;
    
  components LocalTimeMicroC;
  LocalTimeRadio = LocalTimeMicroC;
}

