/**
 * TestNetworkC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination. The default send rate is every 10s.
 *
 * See TEP118: Dissemination and TEP 119: Collection for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.2 $ $Date: 2006-07-12 16:59:23 $
 */

#include <Timer.h>
#include "TestNetwork.h"

module TestNetworkC {
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface SplitControl as SerialControl;
  uses interface StdControl as RoutingControl;
  uses interface DisseminationValue<uint16_t> as DisseminationPeriod;
  uses interface Send;
  uses interface Leds;
  uses interface Read<uint16_t> as ReadSensor;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
  uses interface AMSend as UARTSend;
  uses interface CollectionPacket;
  uses interface TreeRoutingInspect;
  uses interface Random;
}
implementation {
  task void uartEchoTask();
  message_t packet;
  message_t uartpacket;
  message_t* recvPtr = &uartpacket;
  uint8_t msglen;
  bool busy = FALSE, uartbusy = FALSE;
  bool firstTimer = TRUE;
  uint16_t seqno;
  
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
  
  event void Timer.fired() {
    call Leds.led0Toggle();
    dbg("TestNetworkC", "TestNetworkC: Timer fired.\n");
    if (firstTimer) {
      firstTimer = FALSE;
      call Timer.startPeriodic(1024);
    }
    if (busy || call ReadSensor.read() != SUCCESS) {
      signal ReadSensor.readDone(SUCCESS, 0);
      return;
    }
    busy = TRUE;
  }

  void failedSend() {
    dbg("App", "%s: Send failed.\n", __FUNCTION__);
  }
  
  event void ReadSensor.readDone(error_t err, uint16_t val) {
    TestNetworkMsg* msg = (TestNetworkMsg*)call Send.getPayload(&packet);
    uint8_t hopcount;
    uint16_t metric;
    am_addr_t parent;

    call TreeRoutingInspect.getParent(&parent);
    call TreeRoutingInspect.getHopcount(&hopcount);
    call TreeRoutingInspect.getMetric(&metric);

    msg->source = TOS_NODE_ID;
    msg->seqno = seqno;
    msg->data = val;
    msg->parent = parent;
    msg->hopcount = hopcount;
    msg->metric = metric;

    if (err != SUCCESS) {
      dbg("App", "%s: read done failed.\n", __FUNCTION__);
      busy = FALSE;
    }
    if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      failedSend();
      call Leds.led0On();
      dbg("TestNetworkC", "%s: Transmission failed.\n", __FUNCTION__);
    }
    else {
      seqno++; 
      dbg("TestNetworkC", "%s: Transmission succeeded.\n", __FUNCTION__);

    }
  }

  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
	//      call Leds.led0On();
    }
    else {
      busy = FALSE;
    }
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
    if (!uartbusy) {
      message_t* tmp = recvPtr;
      recvPtr = msg;
      uartbusy = TRUE;
      msglen = len + 4;
      post uartEchoTask();
      call Leds.led2Toggle();
      return tmp;
    }
    return msg;
  }

  task void uartEchoTask() {
    dbg("Traffic", "Sending packet to UART.\n");
    if (call UARTSend.send(0xffff, recvPtr, msglen) != SUCCESS) {
      uartbusy = FALSE;
    }
  }

  event void UARTSend.sendDone(message_t *msg, error_t error) {
    dbg("Traffic", "UART send done.\n");
    uartbusy = FALSE;
  }
}
