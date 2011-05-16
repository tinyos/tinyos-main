/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2009-03-04 18:31:04 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * This configuration combines CC2420ControlC and CC2420TransmitC
 * and uses only one instance of CC2420SpiC.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Jan-Hinrich Hauer
 * @version $Revision: 1.4 $ $Date: 2009-03-04 18:31:04 $
 */

#include "CC2420.h"

configuration CC2420ControlTransmitC {

  provides {
    // CC2420ControlC
    interface Resource;
    interface CC2420Config;
    interface CC2420Power;

    // CC2420TransmitC
    interface AsyncStdControl as TxControl;
    interface CC2420Tx;
  } uses {
    // CC2420ControlC
    interface Alarm<T62500hz,uint32_t> as StartupAlarm;
    interface FrameUtility;

    // CC2420TransmitC
    interface Alarm<T62500hz,uint32_t> as AckAlarm;
    interface CaptureTime;
  }
}

implementation {
  
  // CC2420ControlC
  components CC2420ControlP;
  Resource = CC2420ControlP;
  CC2420Config = CC2420ControlP;
  CC2420Power = CC2420ControlP;
  FrameUtility = CC2420ControlP;

  components MainC;
  MainC.SoftwareInit -> CC2420ControlP;
  CC2420ControlP.StartupAlarm = StartupAlarm;

  components HplCC2420PinsC as Pins;
  CC2420ControlP.CSN -> Pins.CSN;
  CC2420ControlP.RSTN -> Pins.RSTN;
  CC2420ControlP.VREN -> Pins.VREN;
  CC2420ControlP.FIFO -> Pins.FIFO;

  components HplCC2420InterruptsC as Interrupts;
  CC2420ControlP.InterruptCCA -> Interrupts.InterruptCCA;

  components new CC2420SpiC() as Spi;
  CC2420ControlP.SpiResource -> Spi;
  CC2420ControlP.SRXON -> Spi.SRXON;
  CC2420ControlP.SACKPEND -> Spi.SACKPEND;
  CC2420ControlP.SRFOFF -> Spi.SRFOFF;
  CC2420ControlP.SXOSCON -> Spi.SXOSCON;
  CC2420ControlP.SXOSCOFF -> Spi.SXOSCOFF;
  CC2420ControlP.FSCTRL -> Spi.FSCTRL;
  CC2420ControlP.IOCFG0 -> Spi.IOCFG0;
  CC2420ControlP.IOCFG1 -> Spi.IOCFG1;
  CC2420ControlP.MDMCTRL0 -> Spi.MDMCTRL0;
  CC2420ControlP.MDMCTRL1 -> Spi.MDMCTRL1;
/*  CC2420ControlP.PANID -> Spi.PANID;*/
  CC2420ControlP.TXCTRL      -> Spi.TXCTRL;
  CC2420ControlP.IEEEADR -> Spi.IEEEADR;
  CC2420ControlP.RXCTRL1 -> Spi.RXCTRL1;
  CC2420ControlP.SFLUSHRX-> Spi.SFLUSHRX;
  CC2420ControlP.RSSI  -> Spi.RSSI;
  CC2420ControlP.RXFIFO_REGISTER -> Spi.RXFIFO_REGISTER;
  CC2420ControlP.SNOP -> Spi.SNOP;

  // CC2420TransmitC
  components CC2420TransmitP;
  TxControl = CC2420TransmitP;
  CC2420Tx = CC2420TransmitP;
  AckAlarm = CC2420TransmitP;
  CaptureTime = CC2420TransmitP;

  MainC.SoftwareInit -> CC2420TransmitP;
  CC2420TransmitP.CCA -> Pins.CCA;
  CC2420TransmitP.CSN -> Pins.CSN;
  CC2420TransmitP.SFD -> Pins.SFD;
  CC2420TransmitP.CaptureSFD -> Interrupts.CaptureSFD;
  CC2420TransmitP.FIFOP -> Pins.FIFOP;
  CC2420TransmitP.FIFO -> Pins.FIFO;

  CC2420TransmitP.ChipSpiResource -> Spi;
  CC2420TransmitP.SNOP        -> Spi.SNOP;
  CC2420TransmitP.STXON       -> Spi.STXON;
  CC2420TransmitP.STXONCCA    -> Spi.STXONCCA;
  CC2420TransmitP.SFLUSHTX    -> Spi.SFLUSHTX;
  CC2420TransmitP.TXCTRL      -> Spi.TXCTRL;
  CC2420TransmitP.TXFIFO      -> Spi.TXFIFO;
  CC2420TransmitP.TXFIFO_RAM  -> Spi.TXFIFO_RAM;
  CC2420TransmitP.MDMCTRL1    -> Spi.MDMCTRL1;
  CC2420TransmitP.SRXON -> Spi.SRXON;
  CC2420TransmitP.SRFOFF -> Spi.SRFOFF;
  CC2420TransmitP.SFLUSHRX-> Spi.SFLUSHRX;
  CC2420TransmitP.SACKPEND -> Spi.SACKPEND;
  
  components CC2420ReceiveC;
  CC2420TransmitP.CC2420Receive -> CC2420ReceiveC;
}

