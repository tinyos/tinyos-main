/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * MViz demo application using the collection layer. 
 * See README.txt file in this directory and TEP 119: Collection.
 *
 * @author David Gay
 * @author Kyle Jamieson
 * @author Philip Levis
 */

#include "MViz.h"

module MVizC @safe(){
  uses {
    // Interfaces for initialization:
    interface Boot;
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;
    interface StdControl as RoutingControl;
    
    // Interfaces for communication, multihop and serial:
    interface Send;
    interface Receive as Snoop;
    interface Receive;
    interface AMSend as SerialSend;
    interface CollectionPacket;
    interface RootControl;

    // Miscalleny:
    interface Timer<TMilli>;
    interface Read<uint16_t>;
    interface Leds;
    interface CtpInfo;
    interface LinkEstimator;
    interface Random;
  }
}

implementation {
  task void uartSendTask();
  static void startTimer();
  static void fatal_problem();
  static void report_problem();
  static void report_sent();
  static void report_received();

  uint8_t uartlen;
  message_t sendbuf;
  message_t uartbuf;
  bool sendbusy=FALSE, uartbusy=FALSE;

  /* Current local state - interval, version and accumulated readings */
  mviz_msg_t local;

  uint8_t reading; /* 0 to NREADINGS */

  /* When we head an Oscilloscope message, we check it's sample count. If
     it's ahead of ours, we "jump" forwards (set our count to the received
     count). However, we must then suppress our next count increment. This
     is a very simple form of "time" synchronization (for an abstract
     notion of time). */
  bool suppress_count_change;

  // 
  // On bootup, initialize radio and serial communications, and our
  // own state variables.
  //
  event void Boot.booted() {
    local.interval = DEFAULT_INTERVAL;
    local.origin = TOS_NODE_ID;

    // Beginning our initialization phases:
    if (call RadioControl.start() != SUCCESS)
      fatal_problem();

    if (call RoutingControl.start() != SUCCESS)
      fatal_problem();
  }

  event void RadioControl.startDone(error_t error) {
    if (error != SUCCESS)
      fatal_problem();

    if (sizeof(local) > call Send.maxPayloadLength())
      fatal_problem();

    if (call SerialControl.start() != SUCCESS)
      fatal_problem();
  }

  event void SerialControl.startDone(error_t error) {
    if (error != SUCCESS)
      fatal_problem();

    // This is how to set yourself as a root to the collection layer:
    if (local.origin % 500 == 0)
      call RootControl.setRoot();

    startTimer();
  }

  static void startTimer() {
    call Timer.startPeriodic(local.interval);
    reading = 0;
  }

  event void RadioControl.stopDone(error_t error) { }
  event void SerialControl.stopDone(error_t error) { }

  //
  // Only the root will receive messages from this interface; its job
  // is to forward them to the serial uart for processing on the pc
  // connected to the sensor network.
  //
  event message_t*
  Receive.receive(message_t* msg, void *payload, uint8_t len) {
    if (uartbusy == FALSE) {
      mviz_msg_t* in = (mviz_msg_t*)payload;
      mviz_msg_t* out = (mviz_msg_t*)call SerialSend.getPayload(&uartbuf, sizeof(mviz_msg_t));
      if (out == NULL) {
	return msg;
      }
      else {
	memcpy(out, in, sizeof(mviz_msg_t));
      }
      uartbusy = TRUE;
      uartlen = sizeof(mviz_msg_t);
      post uartSendTask();
    }

    return msg;
  }

  task void uartSendTask() {
    if (call SerialSend.send(0xffff, &uartbuf, uartlen) != SUCCESS) {
      uartbusy = FALSE;
    }
  }
  //
  // Overhearing other traffic in the network.
  //
  event message_t* 
  Snoop.receive(message_t* msg, void* payload, uint8_t len) {
    mviz_msg_t *omsg = payload;

    report_received();

    // If we receive a newer version, update our interval. 
    if (omsg->version > local.version) {
      local.version = omsg->version;
      local.interval = omsg->interval;
      startTimer();
    }

    // If we hear from a future count, jump ahead but suppress our own
    // change.
    if (omsg->count > local.count) {
      local.count = omsg->count;
      suppress_count_change = TRUE;
    }

    return msg;
  }

  /* At each sample period:
     - if local sample buffer is full, send accumulated samples
     - read next sample
  */
  event void Timer.fired() {
    if (!sendbusy) {
      mviz_msg_t *o = (mviz_msg_t *)call Send.getPayload(&sendbuf, sizeof(mviz_msg_t));
      if (o == NULL) {
	fatal_problem();
	return;
      }
      memcpy(o, &local, sizeof(local));
      if (call Send.send(&sendbuf, sizeof(local)) == SUCCESS)
	sendbusy = TRUE;
      else
	report_problem();
    }
    
    reading = 0;
    /* Part 2 of cheap "time sync": increment our count if we didn't
       jump ahead. */
    if (!suppress_count_change)
      local.count++;
    suppress_count_change = FALSE;
    call Timer.stop();
    call Timer.startPeriodic(local.interval);    
    if (call Read.read() != SUCCESS)
      fatal_problem();
  }

  event void Send.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      report_sent();
    else
      report_problem();

    sendbusy = FALSE;
  }

  event void Read.readDone(error_t result, uint16_t data) {
    uint16_t val;
    if (result != SUCCESS) {
      data = 0xffff;
      report_problem();
    }
    local.reading = data;
    call CtpInfo.getEtx(&val);
    local.link_route_value = val;
    call CtpInfo.getParent(&val);
    local.link_route_addr = val;
    local.link_route_value = call LinkEstimator.getLinkQuality(local.link_route_addr);
  }
  event void LinkEstimator.evicted(am_addr_t addr){}
  
  event void SerialSend.sendDone(message_t *msg, error_t error) {
    uartbusy = FALSE;
  }

  // Use LEDs to report various status issues.
  static void fatal_problem() { 
    call Leds.led0On(); 
    call Leds.led1On();
    call Leds.led2On();
    call Timer.stop();
  }

  static void report_problem() { call Leds.led0Toggle(); }
  static void report_sent() { call Leds.led1Toggle(); }
  static void report_received() { call Leds.led2Toggle(); }
}
