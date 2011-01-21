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
 * Implementation of the receive path for the ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @version $Revision: 1.2 $ $Date: 2009-03-04 18:31:04 $
 */

configuration CC2420ReceiveC {

  provides interface CC2420AsyncSplitControl;
  provides interface CC2420Receive; // to CC2420TransmitP for ACK
  provides interface CC2420Rx;      // to the driver
  uses interface FrameUtility;
  uses interface CC2420Config;
}

implementation {
  components MainC;
  components CC2420ReceiveP;
  components new CC2420SpiC() as Spi;
  
  components HplCC2420PinsC as Pins;
  components HplCC2420InterruptsC as InterruptsC;

  CC2420AsyncSplitControl = CC2420ReceiveP;
  CC2420Receive = CC2420ReceiveP;
  CC2420Rx = CC2420ReceiveP;
  FrameUtility = CC2420ReceiveP;
  CC2420Config = CC2420ReceiveP;

  MainC.SoftwareInit -> CC2420ReceiveP;
  
  CC2420ReceiveP.CSN -> Pins.CSN;
  CC2420ReceiveP.FIFO -> Pins.FIFO;
  CC2420ReceiveP.FIFOP -> Pins.FIFOP;
  CC2420ReceiveP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
  CC2420ReceiveP.SpiResource -> Spi;
  CC2420ReceiveP.RXFIFO -> Spi.RXFIFO;
  CC2420ReceiveP.SFLUSHRX -> Spi.SFLUSHRX;
  CC2420ReceiveP.SACK -> Spi.SACK;
  CC2420ReceiveP.SACKPEND -> Spi.SACKPEND;
  CC2420ReceiveP.SRXON -> Spi.SRXON;
  CC2420ReceiveP.MDMCTRL1 -> Spi.MDMCTRL1;

}
