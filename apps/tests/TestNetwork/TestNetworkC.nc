/**
 * TestNetworkC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination. The default send rate is every 10s.
 *
 * See TEP118: Dissemination and TEP 119: Collection for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.7 $ $Date: 2007-09-13 23:10:20 $
 */

#include <Timer.h>
#include "TestNetwork.h"
#include "CtpDebugMsg.h"

module TestNetworkC {
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface SplitControl as SerialControl;
  uses interface StdControl as RoutingControl;
  uses interface StdControl as DisseminationControl;
  uses interface DisseminationValue<uint16_t> as DisseminationPeriod;
  uses interface Send;
  uses interface Leds;
  uses interface Read<uint16_t> as ReadSensor;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
  uses interface AMSend as UARTSend;
  uses interface CollectionPacket;
  uses interface CtpInfo;
  uses interface CtpCongestion;
  uses interface Random;
  uses interface Queue<message_t*>;
  uses interface Pool<message_t>;
  uses interface CollectionDebug;
  uses interface AMPacket;
}
implementation {
  task void uartEchoTask();
  message_t packet;
  message_t uartpacket;
  message_t* recvPtr = &uartpacket;
  uint8_t msglen;
  bool sendBusy = FALSE;
  bool uartbusy = FALSE;
  bool firstTimer = TRUE;
  uint16_t seqno;
  enum {
    SEND_INTERVAL = 8192
  };

  event void ReadSensor.readDone(error_t err, uint16_t val) { }  

  event void Boot.booted() {
    call SerialControl.start();
  }
  event void SerialControl.startDone(error_t err) {
    call RadioControl.start();
  }
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      call DisseminationControl.start();
      call RoutingControl.start();
      if (TOS_NODE_ID % 500 == 0) {
	call RootControl.setRoot();
      }
      seqno = 0;
        call Timer.startOneShot(call Random.rand16() & 0x1ff);
    }
  }

  event void RadioControl.stopDone(error_t err) {}
  event void SerialControl.stopDone(error_t err) {}	

  void failedSend() {
    dbg("App", "%s: Send failed.\n", __FUNCTION__);
    call CollectionDebug.logEvent(NET_C_DBG_1);
  }

   
  void sendMessage() {
    TestNetworkMsg* msg = (TestNetworkMsg*)call Send.getPayload(&packet, sizeof(TestNetworkMsg));
    uint16_t metric;
    am_addr_t parent;

    call CtpInfo.getParent(&parent);
    call CtpInfo.getEtx(&metric);

    msg->source = TOS_NODE_ID;
    msg->seqno = seqno;
    msg->data = 0xCAFE;
    msg->parent = parent;
    msg->hopcount = 0;
    msg->metric = metric;

    if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      failedSend();
      call Leds.led0On();
      dbg("TestNetworkC", "%s: Transmission failed.\n", __FUNCTION__);
    }
    else {
      sendBusy = TRUE;
      seqno++; 
      dbg("TestNetworkC", "%s: Transmission succeeded.\n", __FUNCTION__);
    }
  }

 
  event void Timer.fired() {
    uint16_t nextInt;
    call Leds.led0Toggle();
    dbg("TestNetworkC", "TestNetworkC: Timer fired.\n");
    nextInt = call Random.rand16() % SEND_INTERVAL;
    nextInt += SEND_INTERVAL >> 1;
    call Timer.startOneShot(nextInt);
    if (!sendBusy)
	sendMessage();
  }

  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
	//      call Leds.led0On();
    }
    sendBusy = FALSE;
    dbg("TestNetworkC", "Send completed.\n");
  }
  
  event void DisseminationPeriod.changed() {
    const uint16_t* newVal = call DisseminationPeriod.get();
    call Timer.stop();
    call Timer.startPeriodic(*newVal);
  }

  event message_t* 
  Receive.receive(message_t* msg, void* payload, uint8_t len) {
    dbg("TestNetworkC", "Received packet at %s from node %hhu.\n", sim_time_string(), call CollectionPacket.getOrigin(msg));
    call Leds.led1Toggle();    
    if (!call Pool.size() <= (TEST_NETWORK_QUEUE_SIZE < 4)? 1:3)  {
      call CtpCongestion.setClientCongested(TRUE);
    }
    if (!call Pool.empty() && call Queue.size() < call Queue.maxSize()) {
      message_t* tmp = call Pool.get();
      call Queue.enqueue(msg);
      if (!uartbusy) {
        post uartEchoTask();
      }
      return tmp;
    }
    return msg;
 }

 task void uartEchoTask() {
    dbg("Traffic", "Sending packet to UART.\n");
   if (call Queue.empty()) {
     return;
   }
   else if (!uartbusy) {
     message_t* msg = call Queue.dequeue();
     dbg("Traffic", "Sending packet to UART.\n");
     if (call UARTSend.send(0xffff, msg, call Packet.payloadLength(msg)) == SUCCESS) {
       uartbusy = TRUE;
     }
     else {
      call CollectionDebug.logEventMsg(NET_C_DBG_2,
				       call CollectionPacket.getSequenceNumber(msg),
				       call CollectionPacket.getOrigin(msg),
				       call AMPacket.destination(msg));
     }
   }
 }

  event void UARTSend.sendDone(message_t *msg, error_t error) {
    dbg("Traffic", "UART send done.\n");
    uartbusy = FALSE;
    call Pool.put(msg);
    if (!call Queue.empty()) {
      post uartEchoTask();
    } 
    else {
        call CtpCongestion.setClientCongested(FALSE);
    }
  }

  /* Default implementations for CollectionDebug calls.
   * These allow CollectionDebug not to be wired to anything if debugging
   * is not desired. */

    default command error_t CollectionDebug.logEvent(uint8_t type) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        return SUCCESS;
    }
 
}
