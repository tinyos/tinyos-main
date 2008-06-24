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
 * This layer is responsible for supplying a unique data sequence number (dsn)
 * to each outgoing message.
 * @author David Moss
 */
 
module UniqueSendP @safe() {
  provides {
    interface Send;
    interface Init;
  }
  
  uses {
    interface Send as SubSend;
    interface State;
    interface Random;
    interface CC2420PacketBody;
  }
}

implementation {

  uint8_t localSendId;
  
  enum {
    S_IDLE,
    S_SENDING,
  };
  
  /***************** Init Commands ****************/
  command error_t Init.init() {
    localSendId = call Random.rand16();
    return SUCCESS;
  }

  /***************** Send Commands ****************/
  /**
   * Each call to this send command gives the message a single
   * DSN that does not change for every copy of the message
   * sent out.  For messages that are not acknowledged, such as
   * a broadcast address message, the receiving end does not
   * signal receive() more than once for that message.
   */
  command error_t Send.send(message_t *msg, uint8_t len) {
    error_t error;
    if(call State.requestState(S_SENDING) == SUCCESS) {
      (call CC2420PacketBody.getHeader(msg))->dsn = localSendId++;
      
      if((error = call SubSend.send(msg, len)) != SUCCESS) {
        call State.toIdle();
      }
      
      return error;
    }
    
    return EBUSY;
  }

  command error_t Send.cancel(message_t *msg) {
    return call SubSend.cancel(msg);
  }
  
  
  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void *Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }
  
  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t *msg, error_t error) {
    call State.toIdle();
    signal Send.sendDone(msg, error);
  }
  
}

