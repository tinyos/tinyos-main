/**
 * Reliable Packet Link Functionality
 * @author David Moss
 * @author Jon Wyant
 */
 
#include "CC2420.h"

module PacketLinkP {
  provides {
    interface Send;
    interface PacketLink;
  }
  
  uses {
    interface Send as SubSend;
    interface State as SendState;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as DelayTimer;
    interface AMPacket;
    interface CC2420PacketBody;
  }
}

implementation {
  
  /** The message currently being sent */
  message_t *currentSendMsg;
  
  /** Length of the current send message */
  uint8_t currentSendLen;
  
  /** The length of the current send message */
  uint16_t totalRetries;

  /**
   * Send States
   */
  enum {
    S_IDLE,
    S_SENDING,
  };
  
  
  /***************** Prototypes ***************/
  task void send();
  void signalDone(error_t error);
    
  /***************** PacketLink Commands ***************/
  /**
   * Set the maximum number of times attempt message delivery
   * Default is 0
   * @param msg
   * @param maxRetries the maximum number of attempts to deliver
   *     the message
   */
  command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
    (call CC2420PacketBody.getMetadata(msg))->maxRetries = maxRetries;
  }

  /**
   * Set a delay between each retry attempt
   * @param msg
   * @param retryDelay the delay betweeen retry attempts, in milliseconds
   */
  command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) {
    (call CC2420PacketBody.getMetadata(msg))->retryDelay = retryDelay;
  }

  /** 
   * @return the maximum number of retry attempts for this message
   */
  command uint16_t PacketLink.getRetries(message_t *msg) {
    return (call CC2420PacketBody.getMetadata(msg))->maxRetries;
  }

  /**
   * @return the delay between retry attempts in ms for this message
   */
  command uint16_t PacketLink.getRetryDelay(message_t *msg) {
    return (call CC2420PacketBody.getMetadata(msg))->retryDelay;
  }

  /**
   * @return TRUE if the message was delivered.
   */
  command bool PacketLink.wasDelivered(message_t *msg) {
    return call PacketAcknowledgements.wasAcked(msg);
  }
  
  /***************** Send Commands ***************/
  /**
   * Each call to this send command gives the message a single
   * DSN that does not change for every copy of the message
   * sent out.  For messages that are not acknowledged, such as
   * a broadcast address message, the receiving end does not
   * signal receive() more than once for that message.
   */
  command error_t Send.send(message_t *msg, uint8_t len) {
    error_t error;
    dbg("PacketLink", "PacketLink: Send.send: msg %p of len %d for %d with %d retries requested and %d delay.\n", 
	msg, len, call AMPacket.destination(msg), call PacketLink.getRetries(msg), call PacketLink.getRetryDelay(msg));
    if(call SendState.requestState(S_SENDING) == SUCCESS) {
    
      currentSendMsg = msg;
      currentSendLen = len;
      totalRetries = 0;

			dbg("PacketLink", "Retries: %d\n", call PacketLink.getRetries(msg));

      if(call PacketLink.getRetries(msg) > 0) {
        call PacketAcknowledgements.requestAck(msg);
      }
     
      dbg("PacketLink", "PacketLink: Send.send: try to send: %p of len %d.\n", msg, len);
      if((error = call SubSend.send(msg, len)) != SUCCESS) {
        call SendState.toIdle();
      }
      
      return error;
    }
    return EBUSY;
  }

  command error_t Send.cancel(message_t *msg) {
    if(currentSendMsg == msg) {
      call SendState.toIdle();
      return call SubSend.cancel(msg);
    }
    
    return FAIL;
  }
  
  
  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void *Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }
  
  
  /***************** SubSend Events ***************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
    dbg("PacketLink", "PacketLink: SubSend.sendDone: msg %p for %d, ack %d, error %d, retries so far %d.\n", 
	msg, call AMPacket.destination(msg), call PacketAcknowledgements.wasAcked(msg), error, totalRetries);
    if(call SendState.getState() == S_SENDING) {
      totalRetries++;
      if(call PacketAcknowledgements.wasAcked(msg)) {
	dbg("PacketLink", "PacketLink: SubSend.sendDone: send of %p succeeded.\n", msg);
        signalDone(SUCCESS);
        return;
        
      } else if(totalRetries < call PacketLink.getRetries(currentSendMsg)) {
        
        if(call PacketLink.getRetryDelay(currentSendMsg) > 0) {
	  dbg("PacketLink", "PacketLink: SubSend.sendDone: schedule a retry for %p after %d.\n", 
	      msg, call PacketLink.getRetryDelay(currentSendMsg));
          // Resend after some delay
          call DelayTimer.startOneShot(call PacketLink.getRetryDelay(currentSendMsg));
          
        } else {
          // Resend immediately
          post send();
        }
        
        return;
      }
    }
    
    dbg("PacketLink", "PacketLink: SubSend.sendDone: sending of message %p failed.\n", msg);
    signalDone(FAIL);
  }
  
  
  /***************** Timer Events ****************/  
  /**
   * When this timer is running, that means we're sending repeating messages
   * to a node that is receive check duty cycling.
   */
  event void DelayTimer.fired() {
    if(call SendState.getState() == S_SENDING) {
      post send();
    }
  }
  
  /***************** Tasks ***************/
  task void send() {
    error_t error;
		dbg("PacketLink", "Retries 2: %d\n", call PacketLink.getRetries(currentSendMsg));
    if(call PacketLink.getRetries(currentSendMsg) > 0) {
      call PacketAcknowledgements.requestAck(currentSendMsg);
    }
    dbg("PacketLink", "PacketLink: try to send: %p of len %d.\n", currentSendMsg, currentSendLen);
    error = call SubSend.send(currentSendMsg, currentSendLen);
    if(error == EBUSY) {
      post send();
    } else if(error != SUCCESS) {
      signalDone(error);
    }
  }
  
  /***************** Functions ***************/  
  void signalDone(error_t error) {
    call DelayTimer.stop();
    call SendState.toIdle();
    signal Send.sendDone(currentSendMsg, error);
  }
}

