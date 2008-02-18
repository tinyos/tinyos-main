module LoopBackM {
  provides {
    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
  }
  uses {
    interface AMSend as SubSend[uint8_t id];
    interface Receive as SubReceive[uint8_t id];
    interface AMPacket;
    interface Packet;
  }
}
implementation {

  message_t first_avail;
  message_t * avail = &first_avail;

  message_t * buf_msg;
  uint8_t buf_am;

  task void sendDoneTask(){
    signal AMSend.sendDone[buf_am](buf_msg, SUCCESS);
  }

  command error_t AMSend.send[uint8_t am](am_addr_t addr, message_t *msg, uint8_t len){ //TODO set acks
    if(addr == call AMPacket.address()){
      buf_am = am;
      buf_msg = msg;
      *avail = *msg;
      dbg("lo", "LO: I am sending the buffer %p.\n", avail);
      dbg("lo", "LO: its length is %hhu.\n", len);
      call Packet.setPayloadLength(avail, len);
      call AMPacket.setDestination(avail, addr);
      call AMPacket.setSource(avail, addr);
      post sendDoneTask();
      avail = signal Receive.receive[call AMPacket.type(msg)](
				 avail, 
				 call Packet.getPayload(avail, len),
				 len);
      return SUCCESS;
    } else {
      return call SubSend.send[am](addr, msg, len);
    }
  }

  command error_t AMSend.cancel[uint8_t am](message_t *msg){
    if(call AMPacket.destination(msg) == call AMPacket.address()){
      return FAIL;
    } else {
      return call SubSend.cancel[am](msg);
    }
  }

  command void * AMSend.getPayload[uint8_t am](message_t *msg, uint8_t len){
    return call SubSend.getPayload[am](msg, len);
  }

  command uint8_t AMSend.maxPayloadLength[uint8_t am](){
    return call SubSend.maxPayloadLength[am]();
  }

  event void SubSend.sendDone[uint8_t am](message_t *msg, error_t error){
    signal AMSend.sendDone[am](msg, error);
  }


  event message_t * SubReceive.receive[uint8_t am](message_t *msg, void *payload, uint8_t len){
    return signal Receive.receive[am](msg, payload, len);
  }

 default event void AMSend.sendDone[uint8_t am](message_t *msg, error_t error){ }

 default event message_t * Receive.receive[uint8_t am](message_t *msg, void *payload, uint8_t len){ return msg; }

}
