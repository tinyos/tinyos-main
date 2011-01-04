/*
 * Copyright (c) 2010 Johns Hopkins University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Doug Carlson
 */

#include "SourceRouteEngine.h"

generic configuration SourceRouteEngineC(am_id_t AMId) {
  provides {
    interface StdControl;
    interface SourceRouteSend[uint8_t client];
    interface SourceRoutePacket;
    interface Receive[sourceroute_id_t id];
  }
  uses {
    interface SourceRouteId[uint8_t client];
  }
}
implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_SRP_CLIENT),
    FORWARD_COUNT = 12,
    QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
  };
  components MainC;

  components new AMSenderC(AMId) as SubSend;
  components new AMReceiverC(AMId) as SubReceive;
  components ActiveMessageC; 

  components SourceRouteEngineP as Engine;
  
  components new QueueC(srf_queue_entry_t*, QUEUE_SIZE) as SendQueue;
  components new PoolC(srf_queue_entry_t, FORWARD_COUNT) as QEntryPool;
  components new PoolC(message_t, FORWARD_COUNT) as MessagePool;

  Engine.SubReceive -> SubReceive;
  Engine.SubSend -> SubSend;
  Engine.SubControl -> ActiveMessageC;
  Engine.SendQueue -> SendQueue;
  Engine.QEntryPool -> QEntryPool;
  Engine.MessagePool -> MessagePool;
  MainC.SoftwareInit -> Engine.Init;

  StdControl = Engine;
  SourceRouteSend = Engine;
  SourceRoutePacket = Engine;
  Receive = Engine;

  Engine.SourceRouteId = SourceRouteId;

}
