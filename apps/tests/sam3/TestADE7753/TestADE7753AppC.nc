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
 * Test application for the ADE7753 chip. It implements a simple power meter
 * that retrieves the real energy from the ADE7753 chip once a second.
 *
 * @author Thomas Schmid
 * @date   March 2011
 */
 
#include "TestADE7753.h"

configuration TestADE7753AppC {}
implementation {
  components MainC, TestADE7753C as App, LedsC;
  components new AMSenderC(AM_TESTADE7753_MSG);
  components new AMReceiverC(AM_TESTADE7753_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;

  components new Sam3Spi3C() as SpiC;
  components ACMeterC as Meter;

  Meter.SpiPacket -> SpiC;
  Meter.SpiResource -> SpiC;

  components SpiConfigC;
  SpiConfigC.Init <- SpiC;
  SpiConfigC.ResourceConfigure <- SpiC;
  SpiConfigC.HplSam3SpiChipSelConfig -> SpiC;

  components HplSam3sGeneralIOC as IO;

  Meter.CSN -> IO.PioA22;
  Meter.RelayIO -> IO.PioA23;

  App.MeterControl -> Meter;
  App.ReadEnergy -> Meter;
  App.RelayConfig -> Meter;
  App.GainConfig -> Meter;
  App.GetPeriod32 -> Meter;
}
