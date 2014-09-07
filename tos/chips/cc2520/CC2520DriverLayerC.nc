/*
 * Copyright (c) 2010, Vanderbilt University
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
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Fix formatting.
 */

/**
 * Author: Janos Sallai, Miklos Maroti
 * Author: Thomas Schmid (adapted to CC2520)
 */

#include <RadioConfig.h>
#include <CC2520DriverLayer.h>

configuration CC2520DriverLayerC {
  provides {
    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioCCA;
    interface RadioPacket;

    interface PacketField<uint8_t> as PacketTransmitPower;
    interface PacketField<uint8_t> as PacketRSSI;
    interface PacketField<uint8_t> as PacketTimeSyncOffset;
    interface PacketField<uint8_t> as PacketLinkQuality;
    //interface PacketField<uint8_t> as AckReceived;

    interface LocalTime<TRadio> as LocalTimeRadio;
    interface Alarm<TRadio, tradio_size>;

    interface PacketAcknowledgements;
  }
  uses {
    interface CC2520DriverConfig as Config;
    interface PacketTimeStamp<TRadio, uint32_t>;

    interface PacketFlag as TransmitPowerFlag;
    interface PacketFlag as RSSIFlag;    
    interface PacketFlag as TimeSyncFlag; 
    interface PacketFlag as AckReceivedFlag;
    interface RadioAlarm;     
    interface Tasklet;
  }
}

implementation {
  components CC2520DriverLayerP as DriverLayerP,
    BusyWaitMicroC,
    MainC,
    HplCC2520C as HplC;

  MainC.SoftwareInit -> DriverLayerP.SoftwareInit;

  RadioState = DriverLayerP;
  RadioSend = DriverLayerP;
  RadioReceive = DriverLayerP;
  RadioCCA = DriverLayerP;
  RadioPacket = DriverLayerP;
  PacketAcknowledgements = DriverLayerP;

  LocalTimeRadio = HplC;
  Config = DriverLayerP;

  DriverLayerP.VREN -> HplC.VREN;
  DriverLayerP.CSN -> HplC.CSN;
  DriverLayerP.CCA -> HplC.CCA;
  DriverLayerP.RSTN -> HplC.RSTN;
  DriverLayerP.FIFO -> HplC.FIFO;
  DriverLayerP.FIFOP -> HplC.FIFOP;
  DriverLayerP.SFD -> HplC.SFD;

  PacketTransmitPower = DriverLayerP.PacketTransmitPower;
  DriverLayerP.TransmitPowerFlag = TransmitPowerFlag;

  PacketRSSI = DriverLayerP.PacketRSSI;
  DriverLayerP.RSSIFlag = RSSIFlag;

  PacketTimeSyncOffset = DriverLayerP.PacketTimeSyncOffset;
  DriverLayerP.TimeSyncFlag = TimeSyncFlag;

/*
  AckReceived = DriverLayerP.AckReceived;
  components new CC2520MetadataFlagC() as AckFlagC;
  DriverLayerP.AckFlag -> AckFlagC;
*/

  AckReceivedFlag = DriverLayerP.AckReceivedFlag;

  PacketLinkQuality = DriverLayerP.PacketLinkQuality;
  PacketTimeStamp = DriverLayerP.PacketTimeStamp;

  RadioAlarm = DriverLayerP.RadioAlarm;
  Alarm = HplC.Alarm;

  DriverLayerP.SpiResource -> HplC.SpiResource;
  DriverLayerP.SpiByte -> HplC;

  DriverLayerP.SfdCapture -> HplC;
  DriverLayerP.FifopInterrupt -> HplC.FifopInterrupt;
  DriverLayerP.FifoInterrupt -> HplC.FifoInterrupt;

  Tasklet = DriverLayerP.Tasklet;
  DriverLayerP.BusyWait -> BusyWaitMicroC;

  DriverLayerP.LocalTime-> HplC.LocalTimeRadio;

#ifdef RADIO_DEBUG_MESSAGES
  components DiagMsgC;
  DriverLayerP.DiagMsg -> DiagMsgC;
#endif

  components LedsC, NoLedsC;
  DriverLayerP.Leds -> NoLedsC;

#ifdef RADIO_LCD_DEBUG
  components LcdC;
  DriverLayerP.Draw -> LcdC;
#endif

  components CC2520SecurityP;
  DriverLayerP.CC2520Security -> CC2520SecurityP;
}
