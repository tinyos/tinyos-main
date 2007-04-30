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
 * Implementation of basic SPI primitives for the ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.7 $ $Date: 2007-04-30 17:24:26 $
 */

generic configuration CC2420SpiC() {

  provides interface SplitControl;
  provides interface Resource;

  // commands
  provides interface CC2420Strobe as SFLUSHRX;
  provides interface CC2420Strobe as SFLUSHTX;
  provides interface CC2420Strobe as SNOP;
  provides interface CC2420Strobe as SRXON;
  provides interface CC2420Strobe as SRFOFF;
  provides interface CC2420Strobe as STXON;
  provides interface CC2420Strobe as STXONCCA;
  provides interface CC2420Strobe as SXOSCON;
  provides interface CC2420Strobe as SXOSCOFF;
  
  provides interface CC2420Strobe as SACK;

  // registers
  provides interface CC2420Register as FSCTRL;
  provides interface CC2420Register as IOCFG0;
  provides interface CC2420Register as IOCFG1;
  provides interface CC2420Register as MDMCTRL0;
  provides interface CC2420Register as MDMCTRL1;
  provides interface CC2420Register as TXCTRL;
  provides interface CC2420Register as RXCTRL1;
  provides interface CC2420Register as RSSI;

  // ram
  provides interface CC2420Ram as IEEEADR;
  provides interface CC2420Ram as PANID;
  provides interface CC2420Ram as SHORTADR;
  provides interface CC2420Ram as TXFIFO_RAM;

  // fifos
  provides interface CC2420Fifo as RXFIFO;
  provides interface CC2420Fifo as TXFIFO;

}

implementation {

  enum {
    CLIENT_ID = unique( "CC2420Spi.Resource" ),
  };

  components HplCC2420PinsC as Pins;
  components CC2420SpiP as Spi;
  
  Resource = Spi.Resource[ CLIENT_ID ];
  SplitControl = Spi.SplitControl;
  
  // commands
  SFLUSHRX = Spi.Strobe[ CC2420_SFLUSHRX ];
  SFLUSHTX = Spi.Strobe[ CC2420_SFLUSHTX ];
  SNOP = Spi.Strobe[ CC2420_SNOP ];
  SRXON = Spi.Strobe[ CC2420_SRXON ];
  SRFOFF = Spi.Strobe[ CC2420_SRFOFF ];
  STXON = Spi.Strobe[ CC2420_STXON ];
  STXONCCA = Spi.Strobe[ CC2420_STXONCCA ];
  SXOSCON = Spi.Strobe[ CC2420_SXOSCON ];
  SXOSCOFF = Spi.Strobe[ CC2420_SXOSCOFF ];
  
  SACK = Spi.Strobe[ CC2420_SACK ];

  // registers
  FSCTRL = Spi.Reg[ CC2420_FSCTRL ];
  IOCFG0 = Spi.Reg[ CC2420_IOCFG0 ];
  IOCFG1 = Spi.Reg[ CC2420_IOCFG1 ];
  MDMCTRL0 = Spi.Reg[ CC2420_MDMCTRL0 ];
  MDMCTRL1 = Spi.Reg[ CC2420_MDMCTRL1 ];
  TXCTRL = Spi.Reg[ CC2420_TXCTRL ];
  RXCTRL1 = Spi.Reg[ CC2420_RXCTRL1 ];
  RSSI = Spi.Reg[ CC2420_RSSI ];

  // ram
  IEEEADR = Spi.Ram[ CC2420_RAM_IEEEADR ];
  PANID = Spi.Ram[ CC2420_RAM_PANID ];
  SHORTADR = Spi.Ram[ CC2420_RAM_SHORTADR ];
  TXFIFO_RAM = Spi.Ram[ CC2420_RAM_TXFIFO ];

  // fifos
  RXFIFO = Spi.Fifo[ CC2420_RXFIFO ];
  TXFIFO = Spi.Fifo[ CC2420_TXFIFO ];

}

