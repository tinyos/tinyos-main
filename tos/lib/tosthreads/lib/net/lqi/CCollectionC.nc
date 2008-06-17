/*
 * Copyright (c) 2008 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "tosthread_collection.h"
#include "MultiHopLqi.h"

configuration CCollectionC {}

implementation {
  components CCollectionP as CCP;
  components BlockingCollectionReceiverP;
  components BlockingCollectionSnooperP;
  components BlockingCollectionSenderP;
  components BlockingCollectionControlC;
  
  //Allocate enough room in the message queue for all message types.
  //This number needs to be 255-1-12 because 
  //(1) The max number that can be provided to the Queue underneath for its size is 255
  //(2) uniqueN() will give you values from 0..N constituting N+1 unique numbers
  //(3) there are 12 spaces reserved in the send queue in CtpP for forwarding messages.
  //I don't like this implementation, but it will do for now....
  enum {
   FIRST_CLIENT = uniqueN(UQ_LQI_CLIENT, 255-1-12),
  };
  
  CCP.BlockingReceive -> BlockingCollectionReceiverP;
  CCP.BlockingSnoop -> BlockingCollectionSnooperP;
  CCP.BlockingSend -> BlockingCollectionSenderP;
  CCP.RoutingControl -> BlockingCollectionControlC;
  
  components CollectionC;
  CCP.Packet -> CollectionC;
  CCP.CollectionPacket -> CollectionC;
  CCP.RootControl -> CollectionC;
  CollectionC.CollectionId -> CCP;
}
