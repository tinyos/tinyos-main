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
    dbg("UniqueSend", "UniqueSend: Send.send: msg %p of len %d.\n", msg, len);
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
    dbg("UniqueSend", "UniqueSend: SubSend.sendDone: msg %p, error %d.\n", msg, error);
    call State.toIdle();
    signal Send.sendDone(msg, error);
  }
  
}

