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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

/**
 * TODO
 **/

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#endif

configuration AppPlugtestSync1C
{
}
implementation
{
#ifdef NEW_PRINTF_SEMANTICS
  components PrintfC;
  components SerialStartC;
#endif
  components MainC, PlugtestSync1C as App;
  App -> MainC.Boot;

  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  components TknTschC as Tsch;
  App.TknTschInit -> Tsch.TknTschInit;
  App.TschMode -> Tsch.TknTschMlmeTschMode;
  App.MLME_SCAN -> Tsch.TknTschMlmeScan;
  App.MLME_BEACON -> Tsch.TknTschMlmeBeacon;
  App.MLME_BEACON_NOTIFY -> Tsch.TknTschMlmeBeaconNotify;
  App.TknTschInformationElement -> Tsch;
  App.TknTschFrames -> Tsch;
  App.PhyTx -> Tsch;
  App.MCPS_DATA -> Tsch;
  App.PacketPayload -> Tsch;
  App.MLME_SET -> Tsch;
  App.MLME_GET -> Tsch;
  App.PLME_SET -> Tsch;

  components Plain154FrameC;
  App.Frame -> Plain154FrameC;
  components Plain154MetadataC;
  App.Metadata -> Plain154MetadataC;

  components new PoolC(message_t, 10) as MsgPool;
  Tsch.AdvMsgPool -> MsgPool;
  //Tsch.TxMsgPool -> MsgPool;
  Tsch.RxMsgPool -> MsgPool;
  App.RxMsgPool -> MsgPool;

}
