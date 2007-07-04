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
 * @version $Revision: 1.1 $ $Date: 2007-07-04 00:37:14 $
 */

#include "CC2420.h"
#include "IEEE802154.h"

configuration CC2420ControlC {

  provides interface Resource;
  provides interface CC2420Config;
  provides interface CC2420Power;
  provides interface Read<uint16_t> as ReadRssi;
  
}

implementation {
  
  components CC2420ControlP;
  Resource = CC2420ControlP;
  CC2420Config = CC2420ControlP;
  CC2420Power = CC2420ControlP;
  ReadRssi = CC2420ControlP;

  components MainC;
  MainC.SoftwareInit -> CC2420ControlP;
  
  components CC2420ActiveMessageC;
  CC2420ControlP.AMPacket -> CC2420ActiveMessageC;
  
  components AlarmMultiplexC as Alarm;
  CC2420ControlP.StartupTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  CC2420ControlP.CSN -> Pins.CSN;
  CC2420ControlP.RSTN -> Pins.RSTN;
  CC2420ControlP.VREN -> Pins.VREN;

  components HplCC2420InterruptsC as Interrupts;
  CC2420ControlP.InterruptCCA -> Interrupts.InterruptCCA;

  components new CC2420SpiC() as Spi;
  CC2420ControlP.SpiResource -> Spi;
  CC2420ControlP.SRXON -> Spi.SRXON;
  CC2420ControlP.SRFOFF -> Spi.SRFOFF;
  CC2420ControlP.SXOSCON -> Spi.SXOSCON;
  CC2420ControlP.SXOSCOFF -> Spi.SXOSCOFF;
  CC2420ControlP.FSCTRL -> Spi.FSCTRL;
  CC2420ControlP.IOCFG0 -> Spi.IOCFG0;
  CC2420ControlP.IOCFG1 -> Spi.IOCFG1;
  CC2420ControlP.MDMCTRL0 -> Spi.MDMCTRL0;
  CC2420ControlP.MDMCTRL1 -> Spi.MDMCTRL1;
  CC2420ControlP.PANID -> Spi.PANID;
  CC2420ControlP.RXCTRL1 -> Spi.RXCTRL1;
  CC2420ControlP.RSSI  -> Spi.RSSI;

  components new CC2420SpiC() as SyncSpiC;
  CC2420ControlP.SyncResource -> SyncSpiC;

  components new CC2420SpiC() as RssiResource;
  CC2420ControlP.RssiResource -> RssiResource;
  
  components ActiveMessageAddressC;
  CC2420ControlP.ActiveMessageAddress -> ActiveMessageAddressC;

}

