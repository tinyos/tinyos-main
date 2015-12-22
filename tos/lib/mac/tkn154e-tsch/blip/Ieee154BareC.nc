/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
   *
 * @author Tim Bormann <tinyos-code@tkn.tu-berlin.de>
 * @author Sonali Deo <tinyos-code@tkn.tu-berlin.de>
 * @author Jasper Buesch <tinyos-code@tkn.tu-berlin.de>
 */


/*
 * Provides an abstraction layer for complete access to an 802.15.4 packet
 * buffer. Packets provided to this module will be interpreted as 802.15.4
 * frames and will have the sequence number set. Higher layers must set all
 * other fields, including the 802.15.4 header and length byte, but not the
 * last 2 byte crc.
 *
 * Using this interface does not, however, preclude one from using other mac
 * layer modules, including the PacketLink component or LPL. Using those
 * interfaces from RadioPacketMetadataC.nc will continue to work. Using this
 * module just ensures one has free reign over the entire contents of the
 * 802.15.4 packet.
 *
 */

#warning "with Blip over TKN-TSCH"

#include "tkntsch_types.h"

#ifndef RX_QUEUE_SIZE
#define RX_QUEUE_SIZE 10
#endif

#ifndef ADV_QUEUE_SIZE
#define ADV_QUEUE_SIZE 5
#endif

configuration Ieee154BareC {
  provides {
    interface SplitControl;

    interface Packet as BarePacket;
    interface Send as BareSend;
    interface Receive as BareReceive;
  }
}

implementation {
  components new QueueC(message_t*, RX_QUEUE_SIZE) as RxQueue;
  TknTschBareP.RxQueue -> RxQueue;

  components new PoolC(message_t, RX_QUEUE_SIZE) as RxMessagePool;
  TknTschBareP.RxMessagePool -> RxMessagePool;

  components new PoolC(message_t, ADV_QUEUE_SIZE) as AdvMessagePool;

  SplitControl = TknTschBareP.SplitControl;

  components TknTschC as Tsch;
  Tsch.RxMsgPool -> RxMessagePool;
  Tsch.AdvMsgPool -> AdvMessagePool;

  components BlipTschPanP;
  components new TimerMilliC() as Timer;
  BlipTschPanP.BeaconTimer -> Timer;
  BlipTschPanP.TknTschInit -> Tsch.TknTschInit;
  BlipTschPanP.TschMode -> Tsch.TknTschMlmeTschMode;
  BlipTschPanP.MLME_SCAN -> Tsch.TknTschMlmeScan;
  BlipTschPanP.MLME_BEACON -> Tsch.TknTschMlmeBeacon;
  BlipTschPanP.MLME_BEACON_NOTIFY -> Tsch.TknTschMlmeBeaconNotify;
  BlipTschPanP.TknTschInformationElement -> Tsch;
  BlipTschPanP.TknTschFrames -> Tsch;
  BlipTschPanP.PLME_SET -> Tsch;
  BlipTschPanP.MLME_SET -> Tsch;
  BlipTschPanP.MLME_GET -> Tsch;
  BlipTschPanP.PacketPayload -> Tsch.Packet;

  components TknTschBareP;
  BarePacket = TknTschBareP;
  TknTschBareP.BlipTschPan -> BlipTschPanP;
  TknTschBareP.Plain154Packet -> Tsch.Packet;
  TknTschBareP.Plain154PlmeSet -> Tsch;
  TknTschBareP.Plain154PlmeGet -> Tsch;
  TknTschBareP.MCPS_DATA -> Tsch;

  components UniqueSendC;
  components UniqueReceiveC;

  BareSend = UniqueSendC;
  UniqueSendC.SubSend -> TknTschBareP.BareSend;
  BareReceive = UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive -> TknTschBareP.BareReceive;

  components Ieee154AddressC;
  TknTschBareP.Ieee154Address -> Ieee154AddressC.Ieee154Address;

  components Plain154FrameC;
  TknTschBareP.Plain154Frame -> Plain154FrameC;
  BlipTschPanP.Frame -> Plain154FrameC;

  components Plain154MetadataC;
  BlipTschPanP.Metadata -> Plain154MetadataC;

  components new TimerMilliC() as TimeParentTimer;
  BlipTschPanP.TimeParentTimer -> TimeParentTimer;
  components RPLOFC;
  BlipTschPanP.RPLOF -> RPLOFC.RPLOF;

  //components BlipPacketTransformC;
  //TknTschBareP.BlipPacketTransform -> BlipPacketTransformC;
}
