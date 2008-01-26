
module TestDIPP {
  uses interface Leds;
  uses interface StdControl;

  /*
  uses interface DisseminationUpdate<uint16_t> as DisseminationUpdate1;
  uses interface DisseminationValue<uint16_t> as DisseminationValue1;
  */

  // ... INTERFACES

  uses interface Boot;
  uses interface AMSend as SerialSend;
  uses interface SplitControl as SerialControl;
}

implementation {
  typedef nx_struct dip_test_msg_t {
    nx_am_addr_t id;
    nx_uint8_t count;
    nx_uint8_t isOk;
  } dip_test_msg_t;

  message_t m_test;

  uint8_t okbit = 1;
  uint16_t data;
  uint8_t count = 0;
  /*
  uint8_t newcount = N;
  */
  // ... NEWCOUNT

  void bookkeep();

  event void SerialControl.startDone(error_t err) {
    call StdControl.start();
    if(TOS_NODE_ID == 0) {
      data = 0xBEEF;
      dbg("TestDIPP","Updating data items\n");
      /*
      call DisseminationUpdate1.change(&data);
      */
      // ... CHANGES
    }
  }
  
  event void SerialControl.stopDone(error_t err) {
    
  }

  event void Boot.booted() {
    call SerialControl.start();
    dbg("TestDIPP", "Booted at %s\n", sim_time_string());
  }
  /*
  event void DisseminationValue1.changed() {
    uint16_t val = *(uint16_t*) call DisseminationValue1.get();
    if(val != 0xBEEF) { return; }
    bookkeep();
  }
  */

  // ... EVENTS

  void bookkeep() {
    dip_test_msg_t* testmsg;

    if(count < newcount) {
      count++;
    }
    dbg("TestDIPP", "Got an update, %u complete now at %s\n", count, sim_time_string());
    call Leds.led0Toggle();

    testmsg = (dip_test_msg_t*) call SerialSend.getPayload(&m_test, 0);
    testmsg->id = TOS_NODE_ID;
    testmsg->count = count;
    testmsg->isOk = okbit;
    call SerialSend.send(0, &m_test, sizeof(dip_test_msg_t));
    

    if(newcount == count) {
      call Leds.set(7);
    }
    
  }

  event void SerialSend.sendDone(message_t* message, error_t err) {

  }
}
