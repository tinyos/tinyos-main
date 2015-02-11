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
 * Implementation of the transmit path for the ChipCon CC2520 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2008/06/17 07:28:24 $
 */

#include "IEEE802154.h"

configuration CC2520TransmitC {

  provides {
    interface StdControl;
    interface CC2520Transmit;
    interface RadioBackoff;
    interface ReceiveIndicator as EnergyIndicator;
    interface ReceiveIndicator as ByteIndicator;
  }
}

implementation {

  components CC2520TransmitP;
  StdControl = CC2520TransmitP;
  CC2520Transmit = CC2520TransmitP;
  RadioBackoff = CC2520TransmitP;
  EnergyIndicator = CC2520TransmitP.EnergyIndicator;
  ByteIndicator = CC2520TransmitP.ByteIndicator;

  components MainC;
  MainC.SoftwareInit -> CC2520TransmitP;
  MainC.SoftwareInit -> Alarm;
  
  components AlarmMultiplexC as Alarm;
  CC2520TransmitP.BackoffTimer -> Alarm;

  components HplCC2520PinsC as Pins;
  CC2520TransmitP.CCA -> Pins.CCA;
  CC2520TransmitP.CSN -> Pins.CSN;
  CC2520TransmitP.SFD -> Pins.SFD;

  components HplCC2520InterruptsC as Interrupts;
  CC2520TransmitP.CaptureSFD -> Interrupts.CaptureSFD;

  components new CC2520SpiC() as Spi;
  CC2520TransmitP.SpiResource -> Spi;
  CC2520TransmitP.ChipSpiResource -> Spi;
  CC2520TransmitP.SNOP        -> Spi.SNOP;
  CC2520TransmitP.STXON       -> Spi.STXON;
  CC2520TransmitP.STXONCCA    -> Spi.STXONCCA;
  CC2520TransmitP.SFLUSHTX    -> Spi.SFLUSHTX;
  CC2520TransmitP.TXPOWER      -> Spi.TXPOWER;
  CC2520TransmitP.EXCFLAG1     -> Spi.EXCFLAG1;
  CC2520TransmitP.TXFIFO      -> Spi.TXFIFO;
  CC2520TransmitP.TXFIFO_RAM  -> Spi.TXFIFO_RAM;
#ifdef CC2520_HW_SECURITY
  CC2520TransmitP.TXFRAME     -> Spi.TXFRAME;
  CC2520TransmitP.TXNonce     -> Spi.TXNONCE;

  components new HplCC2520SpiC();
  CC2520TransmitP.SpiByte -> HplCC2520SpiC;
  
  components CC2520KeyC;
  CC2520TransmitP.CC2520Key -> CC2520KeyC;	

  
#endif
 // CC2520TransmitP.MDMCTRL1    -> Spi.MDMCTRL1;
  
  components CC2520ReceiveC;
  CC2520TransmitP.CC2520Receive -> CC2520ReceiveC;
  
  components CC2520PacketC;
  CC2520TransmitP.CC2520Packet -> CC2520PacketC;
  CC2520TransmitP.CC2520PacketBody -> CC2520PacketC;
  CC2520TransmitP.PacketTimeStamp -> CC2520PacketC;
  CC2520TransmitP.PacketTimeSyncOffset -> CC2520PacketC;


  components LedsC;
  CC2520TransmitP.Leds -> LedsC;

  #if defined(LCD_DEBUG)
	components LcdC;
	CC2520TransmitP.Lcd -> LcdC;
  #endif
  
}
