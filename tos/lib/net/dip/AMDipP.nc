
module AMDipP {
  provides interface Init;

  provides interface DipSend;
  provides interface DipReceive as DipDataReceive;
  provides interface DipReceive as DipVectorReceive;
  provides interface DipReceive as DipSummaryReceive;

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
    dbg("AMDipP", "ActiveMessageC started!\n");
  }

  event void AMSplitControl.stopDone(error_t err) { }

  command error_t Init.init() {
    busy = FALSE;
    return SUCCESS;
  }

  command error_t DipSend.send(uint8_t len) {
    error_t err;
    dbg("AMDipP", "Attempting to send data in the air\n");
    err = call NetAMSend.send(AM_BROADCAST_ADDR, &am_msg, len);
    if(err == SUCCESS) {
      busy = TRUE;
    }
    return err;
  }

  command void* DipSend.getPayloadPtr() {
    // returns NULL if message is busy
    if(busy) {
      return NULL;
    }
    return call NetAMSend.getPayload(&am_msg, 0);
  }

  command uint8_t DipSend.maxPayloadLength() {
    return call NetAMSend.maxPayloadLength();
  }

  event void NetAMSend.sendDone(message_t* msg, error_t err) {
    dbg("AMDipP", "Data send successfully in the air\n");
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
      signal DipDataReceive.receive(dmsg->content, len);
      break;
    case ID_DIP_VECTOR:
      signal DipVectorReceive.receive(dmsg->content, len);
      break;
    case ID_DIP_SUMMARY:
      signal DipSummaryReceive.receive(dmsg->content, len);
      break;
    }
    return msg;
  }

}
