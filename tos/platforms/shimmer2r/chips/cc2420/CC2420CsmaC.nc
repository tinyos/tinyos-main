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
 * Basic implementation of a CSMA MAC for the ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2012-07-26 17:51:39 $
 *
 * mods to provide CC2420RxState interface, which allows application 
 * to disable radio reception and/or cca for manual control of high-density
 * synchronization routines
 * @author Steve Ayer
 * @date   March, 2012
 */

#include "CC2420.h"
#include "IEEE802154.h"

configuration CC2420CsmaC {

  provides interface SplitControl;
  provides interface Send;
  provides interface Receive;
  provides interface RadioBackoff;
  provides interface CC2420RxState;
}

implementation {

  components CC2420CsmaP as CsmaP;
  RadioBackoff = CsmaP;
  SplitControl = CsmaP;
  Send = CsmaP;
  CC2420RxState = CsmaP;

  components CC2420ControlC;
  CsmaP.Resource -> CC2420ControlC;
  CsmaP.CC2420Power -> CC2420ControlC;

  components CC2420TransmitC;
  CsmaP.SubControl -> CC2420TransmitC;
  CsmaP.CC2420Transmit -> CC2420TransmitC;
  CsmaP.SubBackoff -> CC2420TransmitC;

  components CC2420ReceiveC;
  Receive = CC2420ReceiveC;
  CsmaP.SubControl -> CC2420ReceiveC;

  components CC2420PacketC;
  CsmaP.CC2420Packet -> CC2420PacketC;
  CsmaP.CC2420PacketBody -> CC2420PacketC;
  
  components RandomC;
  CsmaP.Random -> RandomC;

  components new StateC();
  CsmaP.SplitControlState -> StateC;
  
  components LedsC as Leds;
  CsmaP.Leds -> Leds;
  
}
