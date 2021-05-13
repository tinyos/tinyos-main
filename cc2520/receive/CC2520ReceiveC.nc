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
 * @version $Revision: 1.3 $ $Date: 2008/06/17 07:28:24 $
 */

configuration CC2520ReceiveC {

  provides interface StdControl;
  provides interface CC2520Receive;
  provides interface Receive;
  provides interface ReceiveIndicator as PacketIndicator;

  uses interface CC2520Transmit as Send;	
}

implementation {
  components MainC;
  components CC2520ReceiveP;
  components CC2520PacketC;
  components new CC2520SpiC() as Spi;
  components CC2520ControlC;
  
  components HplCC2520PinsC as Pins;
  components HplCC2520InterruptsC as InterruptsC;

  components LedsC as Leds;
  CC2520ReceiveP.Leds -> Leds;

  StdControl = CC2520ReceiveP;
  CC2520Receive = CC2520ReceiveP;
  Send = CC2520ReceiveP;	
  Receive = CC2520ReceiveP;
  PacketIndicator = CC2520ReceiveP.PacketIndicator;

  MainC.SoftwareInit -> CC2520ReceiveP;
  
  CC2520ReceiveP.CSN -> Pins.CSN;
  CC2520ReceiveP.FIFO -> Pins.FIFO;
  CC2520ReceiveP.FIFOP -> Pins.FIFOP;
  CC2520ReceiveP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
  CC2520ReceiveP.SpiResource -> Spi;
  CC2520ReceiveP.RXFIFO -> Spi.RXFIFO;
  CC2520ReceiveP.SFLUSHRX -> Spi.SFLUSHRX;
  CC2520ReceiveP.SACK -> Spi.SACK;
  CC2520ReceiveP.SACKPEND -> Spi.SACKPEND;
  CC2520ReceiveP.CC2520Packet -> CC2520PacketC;
  CC2520ReceiveP.CC2520PacketBody -> CC2520PacketC;
  CC2520ReceiveP.PacketTimeStamp -> CC2520PacketC;
  CC2520ReceiveP.CC2520Config -> CC2520ControlC;

  #ifdef CC2520_HW_SECURITY
  CC2520ReceiveP.RXFRAME  -> Spi.RXFRAME;
  CC2520ReceiveP.RXNonce  -> Spi.RXNONCE;
  CC2520ReceiveP.SNOP     -> Spi.SNOP;

  components new HplCC2520SpiC();
  CC2520ReceiveP.SpiByte -> HplCC2520SpiC;

  components CC2520ActiveMessageC;
  CC2520ReceiveP.AMPacket -> CC2520ActiveMessageC;
  #endif

}
