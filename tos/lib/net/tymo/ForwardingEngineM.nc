/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing.h"

/**
 * ForwardingEngineM - Handles received packets of a certain protocol
 * in a multihop context.  The component uses a route selector to
 * determine if the packet should be forwarded or passed to the upper
 * layer. If the packet is forwarded, the next hop is given by the
 * route selector.
 *
 * @author Romain Thouvenin
 */

//TODO probably need a lot of cleaning, and to be moved elsewhere
generic module ForwardingEngineM () {
  provides { //For the upper layer
    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface LinkMonitor;
  }
  uses {
    interface RouteSelect;
    interface AMSend as SubSend;
    interface AMPacket;
    interface Packet as PPacket; 
    interface Packet as SubPacket;
    interface PacketAcknowledgements as Acks;
    interface Receive as SubReceive;
    interface Timer<TMilli>;
  }

  provides interface MHControl;
}

implementation {
  message_t buf; //first available, do NOT use it
  message_t * avail = &buf;
  message_t * waiting;
  uint8_t typebuf;
  uint8_t lenWaiting;
  uint8_t amWaiting = 0;
  am_addr_t bufAddr;
  am_addr_t * addrWaiting;
  bool lockAvail, lockWaiting;
  uint32_t wait_time;
  bool acks;

  enum {
    WAIT_BEFORE_RETRY = 100,
    MAX_WAIT = 10 * WAIT_BEFORE_RETRY
  };

  command error_t AMSend.send[uint8_t am](am_addr_t addr, message_t * msg, uint8_t len){
    switch(call RouteSelect.selectRoute(msg, &addr, &am)){
    case FW_SEND:
      call PPacket.setPayloadLength(msg, len);
      acks = DYMO_LINK_FEEDBACK && (call Acks.requestAck(msg) == SUCCESS);
      typebuf = am;
      return call SubSend.send(call AMPacket.destination(msg), msg, call SubPacket.payloadLength(msg));

    case FW_WAIT: 
      atomic {
	if(lockWaiting)
	  return EBUSY;
	lockWaiting = TRUE;
      }
      waiting = msg;
      amWaiting = am;
      call PPacket.setPayloadLength(msg, len);
      lenWaiting = call SubPacket.payloadLength(msg);
      bufAddr = addr;
      addrWaiting = &bufAddr;
      wait_time = 0;
      call Timer.startOneShot(WAIT_BEFORE_RETRY); 
      dbg("fwe", "FE: I'll retry later.\n");
      return SUCCESS;
      
    default: //We don't allow sending to oneself
      return FAIL; 
    }
  }

  event message_t * SubReceive.receive(message_t * msg, void * payload, uint8_t len){
    dbg("fwe", "FE: Received a message from %u\n", call AMPacket.source(msg));
    signal MHControl.msgReceived(msg);
    switch(call RouteSelect.selectRoute(msg, NULL, &typebuf)){
    case FW_SEND:
      atomic {
	if (lockAvail) {
          dbg("fwe", "FE: Discarding a received message because no avail buffer.\n");
	  return msg;
        }
	lockAvail = TRUE;
      }
      if ( signal Intercept.forward[typebuf](msg, call PPacket.getPayload(msg, call PPacket.payloadLength(msg)), call PPacket.payloadLength(msg)) ) {
          acks = DYMO_LINK_FEEDBACK && (call Acks.requestAck(msg) == SUCCESS);
	  call SubSend.send(call AMPacket.destination(msg), msg, len);
      }
      return avail;

    case FW_RECEIVE:
      dbg("fwe", "FE: Received a message, signaling to upper layer.\n");
      payload = call PPacket.getPayload(msg, call PPacket.payloadLength(msg));
      return signal Receive.receive[typebuf](msg, payload, call PPacket.payloadLength(msg));

    case FW_WAIT:
      atomic {
	if(lockAvail || lockWaiting) {
          dbg("fwe", "FE: Discarding a received message because no avail or wait buffer.\n");
	  return msg;
        }
	lockAvail = lockWaiting = TRUE;
      }
      waiting = msg;
      lenWaiting = len;
      addrWaiting = NULL;
      wait_time = 0;
      call Timer.startOneShot(WAIT_BEFORE_RETRY);
      return avail;

    default:
      dbg("fwe", "FE: Discarding a received message because I don't know what to do.\n");
      return msg;
    }
  }

  event void SubSend.sendDone(message_t * msg, error_t e){
    dbg("fwe", "FE: Sending done...\n");
    if ((e == SUCCESS) && acks) {
      if( !(call Acks.wasAcked(msg)) ){
	e = FAIL;
	dbg("fwe", "FE: The message was not acked => FAIL.\n");
	signal MHControl.sendFailed(msg, 2);
	signal LinkMonitor.brokenLink(call AMPacket.destination(msg));
      }
    } else if (e != SUCCESS) {
      dbg("fwe", "FE: ...but failed!\n");
      signal MHControl.sendFailed(msg, 1);
    }
    
    if (lockAvail) {
      avail = msg;
      atomic {
	lockAvail = FALSE;
      }
      dbg("fwe", "FE: No need to signal sendDone.\n");
    } else {
      dbg("fwe", "FE: Signaling sendDone.\n");
      if (amWaiting) {
         signal AMSend.sendDone[amWaiting](msg, e);
         amWaiting = 0;
      } else {
         signal AMSend.sendDone[typebuf](msg, e);
      }
      atomic {
	lockWaiting = FALSE;
      }
    }
  }

  event void Timer.fired(){
    switch(call RouteSelect.selectRoute(waiting, addrWaiting, &amWaiting)){
    case FW_SEND:
      dbg("fwe", "FE: I'm retrying to send my message.\n");
      if (addrWaiting) {
	call SubSend.send(call AMPacket.destination(waiting), waiting, lenWaiting);
      } else if ( signal Intercept.forward[amWaiting](waiting, 
				      call PPacket.getPayload(waiting, call PPacket.payloadLength(waiting)), 
				      call PPacket.payloadLength(waiting)) ) {
	call SubSend.send(call AMPacket.destination(waiting), waiting, lenWaiting);
      }
      call Timer.stop();
      break;

    case FW_WAIT:
      dbg("fwe", "FE: I'll retry later again.\n");
      wait_time += call Timer.getdt();
      if(wait_time < MAX_WAIT){
	call Timer.startOneShot(wait_time);
	break;
      }
      //else: Continue to default

    default:
      if(addrWaiting)
	signal AMSend.sendDone[amWaiting](waiting, FAIL);
      if(lockAvail){
	avail = waiting;
	atomic {
	  lockAvail = FALSE;
	}
      }
      atomic {
	lockWaiting = FALSE;
      }
    }
  }

  command error_t AMSend.cancel[uint8_t am](message_t *msg){
    if(lockWaiting){
      call Timer.stop();
      atomic {
	lockWaiting = FALSE;
      }
      return SUCCESS;
    } else {
      return call SubSend.cancel(msg);
    }
  }

  command void * AMSend.getPayload[uint8_t am](message_t *msg, uint8_t len){
    return call PPacket.getPayload(msg, len);
  }

  command uint8_t AMSend.maxPayloadLength[uint8_t am](){
    return call PPacket.maxPayloadLength();
  }


  /*** defaults ***/

 default event message_t * Receive.receive[uint8_t am](message_t * msg, void * payload, uint8_t len){
   return msg;
 }

 default event void AMSend.sendDone[uint8_t am](message_t * msg, error_t e){}

 default event bool Intercept.forward[uint8_t am](message_t * msg, void * payload, uint8_t len){
   return TRUE;
 }

 default event void MHControl.msgReceived(message_t * msg){ }

 default event void MHControl.sendFailed(message_t * msg, uint8_t why){ }

 default event void LinkMonitor.brokenLink(addr_t neighbor){ }
}
