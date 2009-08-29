/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Original TinyOS T-Frames use a packet header that is not compatible with
 * other 6LowPAN networks.  They do not include the network byte 
 * responsible for identifying the packing as being sourced from a TinyOS
 * network.
 *
 * TinyOS I-Frames are interoperability packets that do include a network
 * byte as defined by 6LowPAN specifications.  The I-Frame header type is
 * the default packet header used in TinyOS networks.
 *
 * Since either packet header is acceptable, this layer must do some 
 * preprocessing (sorry) to figure out whether or not it needs to include 
 * the functionality to process I-frames.  If I-Frames are used, then
 * the network byte is added on the way out and checked on the way in.
 * If the packet came from a network different from a TinyOS network, the
 * user may access it through the DispatchP's NonTinyosReceive[] Receive 
 * interface and process it in a different radio stack.
 *
 * If T-Frames are used instead, this layer is simply pass-through wiring to the
 * layer beneath.  
 *
 * Define "CC2420_IFRAME_TYPE" to use the interoperability frame and 
 * this layer
 * 
 * @author David Moss
 */
 
#include "CC2420.h"
#include "Ieee154.h"

configuration CC2420TinyosNetworkC {
  provides {
    interface Resource[uint8_t clientId];
    interface Send;
    interface Receive;

    interface Send as ActiveSend;
    interface Receive as ActiveReceive;
  }
  
  uses {
    interface Receive as SubReceive;
    interface Send as SubSend;
  }
}

implementation {

  enum {
    TINYOS_N_NETWORKS = uniqueCount(IEEE154_SEND_CLIENT),
  };

  components MainC;
  components CC2420TinyosNetworkP;
  components CC2420PacketC;
  components new FcfsResourceQueueC(TINYOS_N_NETWORKS);

  CC2420TinyosNetworkP.BareSend = Send;
  CC2420TinyosNetworkP.BareReceive = Receive;
  CC2420TinyosNetworkP.SubSend = SubSend;
  CC2420TinyosNetworkP.SubReceive = SubReceive;
  CC2420TinyosNetworkP.Resource = Resource;
  CC2420TinyosNetworkP.ActiveSend = ActiveSend;
  CC2420TinyosNetworkP.ActiveReceive = ActiveReceive;

  CC2420TinyosNetworkP.CC2420Packet -> CC2420PacketC;
  CC2420TinyosNetworkP.CC2420PacketBody -> CC2420PacketC;
  CC2420TinyosNetworkP.Queue -> FcfsResourceQueueC;

  MainC.SoftwareInit -> FcfsResourceQueueC;
}

