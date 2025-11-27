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
 * Implementation for configuring a ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2008/05/14 21:33:07 $
 */

#include "CC2520.h"
#include "IEEE802154.h"

configuration CC2520ControlC {

  provides interface Resource;
  provides interface CC2520Config;
  provides interface CC2520Power;
  provides interface Read<uint16_t> as ReadRssi;
  
}

implementation {
  
  components CC2520ControlP;
  Resource = CC2520ControlP;
  CC2520Config = CC2520ControlP;
  CC2520Power = CC2520ControlP;
  ReadRssi = CC2520ControlP;

  components MainC;
  MainC.SoftwareInit -> CC2520ControlP;
  
  components AlarmMultiplexC as Alarm;
  CC2520ControlP.StartupTimer -> Alarm;

  components HplCC2520PinsC as Pins;
  CC2520ControlP.CSN -> Pins.CSN;
  CC2520ControlP.RSTN -> Pins.RSTN;
  CC2520ControlP.VREN -> Pins.VREN;

  components HplCC2520InterruptsC as Interrupts;
  CC2520ControlP.InterruptCCA -> Interrupts.InterruptCCA;

  components new CC2520SpiC() as Spi;
  CC2520ControlP.SpiResource -> Spi;
  CC2520ControlP.SRXON 	  -> Spi.SRXON;
  CC2520ControlP.SRFOFF   -> Spi.SRFOFF;
  CC2520ControlP.SXOSCON  -> Spi.SXOSCON;
  CC2520ControlP.SXOSCOFF -> Spi.SXOSCOFF;
  
  CC2520ControlP.SNOP -> Spi.SNOP;
  
  CC2520ControlP.FSCTRL   -> Spi.FSCTRL;


  //CC2420ControlP.IOCFG0 -> Spi.IOCFG0;
  //CC2420ControlP.IOCFG1 -> Spi.IOCFG1;
  
  // Newly Added on 15-11-10 Lijo ******************/
 
  CC2520ControlP.TXPOWER  ->  Spi.TXPOWER;
  //CC2520ControlP.TXCTRL   ->  Spi.TXCTRL;  
  
  CC2520ControlP.FREQCTRL   -> Spi.FREQCTRL;
  
  CC2520ControlP.CCACTRL0   -> Spi.CCACTRL0;
 
  CC2520ControlP.AGCCTRL1   -> Spi.AGCCTRL1;


  CC2520ControlP.RXCTRL   ->  Spi.RXCTRL;
  CC2520ControlP.FSCAL1   ->  Spi.FSCAL1;
 
  
  CC2520ControlP.ADCTEST0 ->  Spi.ADCTEST0;
  CC2520ControlP.ADCTEST1 ->  Spi.ADCTEST1;
  CC2520ControlP.ADCTEST2 ->  Spi.ADCTEST2;
  
  CC2520ControlP.FRMCTRL0 ->  Spi.FRMCTRL0;
  CC2520ControlP.EXTCLOCK ->  Spi.EXTCLOCK;
  
  CC2520ControlP.GPIOCTRL0 -> Spi.GPIOCTRL0;
  CC2520ControlP.GPIOCTRL1 -> Spi.GPIOCTRL1;
  CC2520ControlP.GPIOCTRL2 -> Spi.GPIOCTRL2;
  CC2520ControlP.GPIOCTRL3 -> Spi.GPIOCTRL3;
  CC2520ControlP.GPIOCTRL4 -> Spi.GPIOCTRL4;
  CC2520ControlP.GPIOCTRL5 -> Spi.GPIOCTRL5;

  CC2520ControlP.GPIOPOLARITY -> Spi.GPIOPOLARITY;

  CC2520ControlP.FRMCTRL1  ->  Spi.FRMCTRL1;
  
  CC2520ControlP.FRMFILT0  ->  Spi.FRMFILT0;
  CC2520ControlP.FRMFILT1  ->  Spi.FRMFILT1;
  CC2520ControlP.FIFOPCTRL  ->  Spi.FIFOPCTRL;
  //*************************************************/



  CC2520ControlP.MDMCTRL0 -> Spi.MDMCTRL0;
  CC2520ControlP.MDMCTRL1 -> Spi.MDMCTRL1;

  CC2520ControlP.PANID -> Spi.PANID;
  //CC2520ControlP.RXCTRL1 -> Spi.RXCTRL1;
  CC2520ControlP.RSSI  -> Spi.RSSI;

  components new CC2520SpiC() as SyncSpiC;
  CC2520ControlP.SyncResource -> SyncSpiC;

  components new CC2520SpiC() as RssiResource;
  CC2520ControlP.RssiResource -> RssiResource;
  
  components ActiveMessageAddressC;
  CC2520ControlP.ActiveMessageAddress -> ActiveMessageAddressC;

  components LedsC as Leds;
  CC2520ControlP.Leds -> Leds;
	components LocalIeeeEui64C;
  CC2520ControlP.LocalIeeeEui64 -> LocalIeeeEui64C;

}

