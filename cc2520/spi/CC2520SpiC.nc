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
 * Implementation of basic SPI primitives for the ChipCon CC2520 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2008/05/28 16:39:53 $
 */

generic configuration CC2520SpiC() {

  provides interface Resource;
  provides interface ChipSpiResource;

  // commands
  provides interface CC2520Strobe as SNOP;
  provides interface CC2520Strobe as SXOSCON;
  provides interface CC2520Strobe as STXCAL;
  provides interface CC2520Strobe as SRXON;
  provides interface CC2520Strobe as STXON;
  provides interface CC2520Strobe as STXONCCA;
  provides interface CC2520Strobe as SRFOFF;
  provides interface CC2520Strobe as SXOSCOFF;
  provides interface CC2520Strobe as SFLUSHRX;
  provides interface CC2520Strobe as SFLUSHTX;
  provides interface CC2520Strobe as SACK;
  provides interface CC2520Strobe as SACKPEND;
  //provides interface CC2520Strobe as SRXDEC;
  //provides interface CC2520Strobe as STXENC;
  //provides interface CC2520Strobe as SAES;

  // registers
  //provides interface CC2520Register as MAIN;
  provides interface CC2520Register as MDMCTRL0;
  provides interface CC2520Register as MDMCTRL1;
  provides interface CC2520Register as RSSI;
  
  //provides interface CC2520Register as TXCTRL;
  provides interface CC2520Register as RXCTRL;
  
  provides interface CC2520Register as FSCTRL;
  
  provides interface CC2520Register as FRMCTRL1;
  provides interface CC2520Register as RXENABLE1;
   
 
  provides interface CC2520Register as CCACTRL0;
  provides interface CC2520Register as AGCCTRL1;
  provides interface CC2520Register as FSCAL1;
  provides interface CC2520Register as TXPOWER;
  provides interface CC2520Register as FREQCTRL;
  provides interface CC2520Register as ADCTEST0;
  provides interface CC2520Register as ADCTEST1;
  provides interface CC2520Register as ADCTEST2;
  
  provides interface CC2520Register as FRMCTRL0;
  provides interface CC2520Register as EXTCLOCK;
  provides interface CC2520Register as GPIOCTRL0;
  provides interface CC2520Register as GPIOCTRL1;
  provides interface CC2520Register as GPIOCTRL2;
  provides interface CC2520Register as GPIOCTRL3;
  provides interface CC2520Register as GPIOCTRL4;
  provides interface CC2520Register as GPIOCTRL5;

  provides interface CC2520Register as GPIOPOLARITY;
  provides interface CC2520Register as EXCFLAG0;
  provides interface CC2520Register as EXCFLAG1;
  provides interface CC2520Register as EXCFLAG2;
  provides interface CC2520Register as FSMSTAT1;

  provides interface CC2520Register as FRMFILT0;
  provides interface CC2520Register as FRMFILT1;
  provides interface CC2520Register as FIFOPCTRL;

  //provides interface CC2520Register as SYNCWORD;
  //provides interface CC2520Register as RXCTRL1;
  //provides interface CC2520Register as SECCTRL0;
  //provides interface CC2520Register as SECCTRL1;
  //provides interface CC2520Register as BATTMON;
  //provides interface CC2520Register as IOCFG0;
  //provides interface CC2520Register as IOCFG1;
  // provides interface CC2520Register as MANFIDL;
  //provides interface CC2520Register as MANFIDH;
  //provides interface CC2520Register as FSMTC;
  //provides interface CC2520Register as MANAND;
  //provides interface CC2520Register as MANOR;
 // provides interface CC2520Register as AGCCTRL;

  // ram
  provides interface CC2520Ram as IEEEADR;
  provides interface CC2520Ram as PANID;
  provides interface CC2520Ram as SHORTADR;
  provides interface CC2520Ram as TXFIFO_RAM;

  //Security in RAM
#ifdef CC2520_HW_SECURITY
  provides interface CC2520Ram as KEY;
  provides interface CC2520Ram as TXNONCE;
  provides interface CC2520Ram as RXNONCE;
  provides interface CC2520Ram as RXFRAME;
  provides interface CC2520Ram as TXFRAME;
#endif
  // fifos
  provides interface CC2520Fifo as RXFIFO;
  provides interface CC2520Fifo as TXFIFO;

}

implementation {

  enum {
    CLIENT_ID = unique( "CC2520Spi.Resource" ),
  };
  
  components HplCC2520PinsC as Pins;
  components CC2520SpiWireC as Spi;
  
  ChipSpiResource = Spi.ChipSpiResource;
  Resource = Spi.Resource[ CLIENT_ID ];
  
  // commands
  SNOP		= Spi.Strobe[ CC2520_CMD_SNOP ];
  SXOSCON 	= Spi.Strobe[ CC2520_CMD_SXOSCON ];
  STXCAL 	= Spi.Strobe[ CC2520_CMD_STXCAL  ];
  SRXON 	= Spi.Strobe[ CC2520_CMD_SRXON ];
  STXON 	= Spi.Strobe[ CC2520_CMD_STXON ];
  STXONCCA 	= Spi.Strobe[ CC2520_CMD_STXONCCA ];
  SRFOFF 	= Spi.Strobe [ CC2520_CMD_SRFOFF  ];
  SXOSCOFF 	= Spi.Strobe[ CC2520_CMD_SXOSCOFF  ];
  SFLUSHRX 	= Spi.Strobe[ CC2520_CMD_SFLUSHRX ];
  SFLUSHTX 	= Spi.Strobe[ CC2520_CMD_SFLUSHTX  ];
  SACK 		= Spi.Strobe[ CC2520_CMD_SACK  ];
  SACKPEND 	= Spi.Strobe[ CC2520_CMD_SACKPEND ];
  //SRXDEC = Spi.Strobe[ CC2520_SRXDEC ];
  //STXENC = Spi.Strobe[ CC2520_STXENC ];
  //SAES = Spi.Strobe[ CC2520_SAES ];
  
  // registers
  //MAIN = Spi.Reg[ CC2520_MAIN ];

  MDMCTRL0 	= Spi.Reg[ CC2520_MDMCTRL0 ];
  MDMCTRL1 	= Spi.Reg[ CC2520_MDMCTRL1 ];
  RSSI 		= Spi.Reg[ CC2520_RSSI ];
  //SYNCWORD = Spi.Reg[ CC2520_SYNCWORD ];
  //TXCTRL = Spi.Reg[ CC2520_TXCTRL ];
  //RXCTRL0 = Spi.Reg[ CC2520_RXCTRL0 ];
  //RXCTRL1 = Spi.Reg[ CC2520_RXCTRL1 ];
  //FSCTRL = Spi.Reg[ CC2520_FSCTRL ];
  //SECCTRL0 = Spi.Reg[ CC2520_SECCTRL0 ];
  //SECCTRL1 = Spi.Reg[ CC2520_SECCTRL1 ];
  //BATTMON = Spi.Reg[ CC2520_BATTMON ];
  //IOCFG0 = Spi.Reg[ CC2520_IOCFG0 ];
  //IOCFG1 = Spi.Reg[ CC2520_IOCFG1 ];
  //MANFIDL = Spi.Reg[ CC2520_MANFIDL ];
  //MANFIDH = Spi.Reg[ CC2520_MANFIDH ];
  //FSMTC = Spi.Reg[ CC2520_FSMTC ];
  //MANAND = Spi.Reg[ CC2520_MANAND ];
  //MANOR = Spi.Reg[ CC2520_MANOR ];
  //AGCCTRL = Spi.Reg[ CC2520_AGCCTRL ];
  RXCTRL	= Spi.Reg[ CC2520_RXCTRL ];
  FSCTRL	= Spi.Reg[ CC2520_FSCTRL  ];
  FSCAL1	= Spi.Reg[ CC2520_FSCAL1 ];
  TXPOWER	= Spi.Reg[ CC2520_TXPOWER  ];
  FREQCTRL	= Spi.Reg[ CC2520_FREQCTRL ];
  ADCTEST0	= Spi.Reg[ CC2520_ADCTEST0 ];
  ADCTEST1	= Spi.Reg[ CC2520_ADCTEST1 ];
  ADCTEST2	= Spi.Reg[ CC2520_ADCTEST2 ];
  FRMCTRL0	= Spi.Reg[ CC2520_FRMCTRL0 ];


  FRMCTRL1	= Spi.Reg[ CC2520_FRMCTRL1 ];
  RXENABLE1	= Spi.Reg[ CC2520_RXENABLE1 ];



  CCACTRL0	= Spi.Reg[ CC2520_CCACTRL0 ];
  AGCCTRL1	= Spi.Reg[ CC2520_AGCCTRL1 ];

  EXTCLOCK	= Spi.Reg[ CC2520_EXTCLOCK ];
  GPIOCTRL0	= Spi.Reg[ CC2520_GPIOCTRL0 ];
  GPIOCTRL1	= Spi.Reg[ CC2520_GPIOCTRL1 ];
  GPIOCTRL2	= Spi.Reg[ CC2520_GPIOCTRL2 ];
  GPIOCTRL3	= Spi.Reg[ CC2520_GPIOCTRL3 ];
  GPIOCTRL4	= Spi.Reg[ CC2520_GPIOCTRL4 ];
  GPIOCTRL5	= Spi.Reg[ CC2520_GPIOCTRL5 ];
  // newly Added
  GPIOPOLARITY  = Spi.Reg[ CC2520_GPIOPOLARITY];//CC2520_GPIOPOLARITY ];
  FRMFILT0	= Spi.Reg[ CC2520_FRMFILT0];
  FRMFILT1	= Spi.Reg[ CC2520_FRMFILT1];
  FIFOPCTRL	= Spi.Reg[ CC2520_FIFOPCTRL];


  EXCFLAG0  	= Spi.Reg[ CC2520_EXCFLAG0];
  EXCFLAG1  	= Spi.Reg[ CC2520_EXCFLAG1];
  EXCFLAG2  	= Spi.Reg[ CC2520_EXCFLAG2];
  FSMSTAT1      = Spi.Reg[ CC2520_FSMSTAT1];
  // ram
  IEEEADR = Spi.Ram[ CC2520_RAM_IEEEADR ];
  PANID = Spi.Ram[ CC2520_RAM_PANID ];
  SHORTADR = Spi.Ram[ CC2520_RAM_SHORTADR ];
  TXFIFO_RAM = Spi.Ram[ CC2520_RAM_TXFIFO];

  #ifdef CC2520_HW_SECURITY
  //Security
  KEY	= Spi.Ram[ CC2520_RAM_KEY0];
  TXNONCE = Spi.Ram[ CC2520_RAM_TXNONCE];
  RXNONCE = Spi.Ram[ CC2520_RAM_RXNONCE];
  RXFRAME = Spi.Ram[ CC2520_RAM_RXFRAME];
  TXFRAME = Spi.Ram[ CC2520_RAM_TXFRAME];
  #endif

  // fifos
  RXFIFO = Spi.Fifo[ CC2520_CMD_RXBUF ];
  TXFIFO = Spi.Fifo[ CC2520_CMD_TXBUF ];

 
}

