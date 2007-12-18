
module AMDIPP {
  provides interface Init;

  provides interface DIPSend;
  provides interface DIPReceive as DIPDataReceive;
  provides interface DIPReceive as DIPVectorReceive;
  provides interface DIPReceive as DIPSummaryReceive;

  uses interface AMSend as NetAMSend;
  uses interface Receive as NetReceive;

  uses interface SplitControl as AMSplitControl;
  uses interface Boot;
}

implementation {
  message_t am_msg;
  bool busy;

  event void Boot.booted() {
    call AMSplitControl.start();
  }

  event void AMSplitControl.startDone(error_t err) {
    if(err != SUCCESS) {
      call AMSplitControl.start();
      return;
    }
    dbg("AMDIPP", "ActiveMessageC started!\n");
  }

  event void AMSplitControl.stopDone(error_t err) { }

  command error_t Init.init() {
    busy = FALSE;
    return SUCCESS;
  }

  command error_t DIPSend.send(uint8_t len) {
    error_t err;
    dbg("AMDIPP", "Attempting to send data in the air\n");
    err = call NetAMSend.send(AM_BROADCAST_ADDR, &am_msg, len);
    if(err == SUCCESS) {
      busy = TRUE;
    }
    return err;
  }

  command void* DIPSend.getPayloadPtr() {
    // returns NULL if message is busy
    if(busy) {
      return NULL;
    }
    return call NetAMSend.getPayload(&am_msg, 0);
  }

  command uint8_t DIPSend.maxPayloadLength() {
    return call NetAMSend.maxPayloadLength();
  }

  event void NetAMSend.sendDone(message_t* msg, error_t err) {
    dbg("AMDIPP", "Data send successfully in the air\n");
    if(msg == &am_msg) {
      busy = FALSE;
    }
  }

  event message_t* NetReceive.receive(message_t* msg, void* payload,
				      uint8_t len) {
    dip_msg_t* dmsg;
    uint8_t type;

    dmsg = (dip_msg_t*) payload;
    type = dmsg->type;
    switch(type) {
    case ID_DIP_DATA:
      signal DIPDataReceive.receive(dmsg->content, len);
      break;
    case ID_DIP_VECTOR:
      signal DIPVectorReceive.receive(dmsg->content, len);
      break;
    case ID_DIP_SUMMARY:
      signal DIPSummaryReceive.receive(dmsg->content, len);
      break;
    }
    return msg;
  }

}
