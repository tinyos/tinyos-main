/**
 * Active Message Implementation.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type and renamed the instances to distinguish from DIP.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

module AMDhvP {
  provides interface Init;
  provides interface DhvSend;
  provides interface DhvReceive as DhvDataReceive;
  provides interface DhvReceive as DhvVectorReceive;
  provides interface DhvReceive as DhvSummaryReceive;
  provides interface DhvReceive as DhvHSumReceive;
  provides interface DhvReceive as DhvVBitReceive;

  uses interface AMSend as NetAMSend;
  uses interface Receive as NetReceive;
  uses interface Boot;
}

implementation {
  message_t am_msg;
  uint32_t send_count;
  bool busy;

  event void Boot.booted() {
    send_count = 0;
  }


  command error_t Init.init() {
    busy = FALSE;
    return SUCCESS;
  }

  command error_t DhvSend.send(uint8_t len) {
    error_t err;
    dhv_msg_t* dmsg;
    uint8_t type;

    dmsg = (dhv_msg_t *) (&am_msg)->data;
    type = dmsg->type;

    send_count = send_count + 1;

    switch(type){
      case ID_DHV_SUMMARY: 
        dbg("AMDhvP", "Sending SUMMARY : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
      case ID_DHV_VBIT: 
        dbg("AMDhvP", "Sending VBIT : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
      case ID_DHV_HSUM: 
        dbg("AMDhvP", "Sending HSUM : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
      case ID_DHV_VECTOR: 
        dbg("AMDhvP", "Sending VECTOR : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
      case ID_DHV_VECTOR_REQ: 
        dbg("AMDhvP", "Sending VECTOR_REQ : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
      case ID_DHV_DATA: 
        dbg("AMDhvP", "Sending DATA : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
      default : 
        dbg("AMDhvP", "Sending UNKNOWN : length %d  count %d at %s \n", len, send_count, sim_time_string());
        break;
    }
    err = call NetAMSend.send(AM_BROADCAST_ADDR, &am_msg, len);

    if(err == SUCCESS) {
      busy = TRUE;
    }else{
      dbg("AMDhvP", "Send failed \n");
    }

    return err;
  }

  command void* DhvSend.getPayloadPtr() {
    // returns NULL if message is busy
    if(busy) {
      return NULL;
    }
    return call NetAMSend.getPayload(&am_msg, 0);
  }

  command uint8_t DhvSend.maxPayloadLength() {
    return call NetAMSend.maxPayloadLength();
  }

  event void NetAMSend.sendDone(message_t* msg, error_t err) {
    //dbg("AMDhvP", "Data send successfully in the air\n");
    if(msg == &am_msg) {
      busy = FALSE;
    }
  }

  event message_t* NetReceive.receive(message_t* msg, void* payload,
      uint8_t len) {
    dhv_msg_t* dmsg;
    uint8_t type;

    dmsg = (dhv_msg_t*) payload;
    type = dmsg->type;
    switch(type) {
      case ID_DHV_DATA:

        dbg("AMDhvPReceive", "Receive DATA : length %d at %s  \n",len,  sim_time_string() );
        signal DhvDataReceive.receive(dmsg->content, len);
        break;
      case ID_DHV_VECTOR:

        dbg("AMDhvPReceive", "Receive VECTOR : length %d at %s \n",len,  sim_time_string() );
        signal DhvVectorReceive.receive(dmsg, len);
        break;
      case ID_DHV_SUMMARY:

        dbg("AMDhvPReceive", "Receive SUMMARY : length %d at %s \n", len, sim_time_string() );
        signal DhvSummaryReceive.receive(dmsg->content, len);
        break;
      case ID_DHV_HSUM:
        dbg("AMDhvPReceive", "Receive HSUM length %d at %s \n", len, sim_time_string());
        signal DhvHSumReceive.receive(dmsg->content, len);
        break;  
      case ID_DHV_VBIT:

        dbg("AMDhvPReceive", "Receive VBIT : length %d at %s \n", len, sim_time_string());
        signal DhvVBitReceive.receive(dmsg->content, len);
        break;

      case ID_DHV_VECTOR_REQ:

        dbg("AMDhvPReceive", "Receive VECTOR_REQ : length %d at %s \n", len, sim_time_string());
        signal DhvVectorReceive.receive(dmsg, len);
        break;
    }
    return msg;
  }
}
