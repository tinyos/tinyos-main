/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
// $Id: BaseStationP.nc,v 1.2 2009-08-09 23:36:05 sdhsdh Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * @author David Gay
 * Revision:	$Id: BaseStationP.nc,v 1.2 2009-08-09 23:36:05 sdhsdh Exp $
 */
  
/* 
 * BaseStationP bridges packets between a serial channel and the radio.
 * Messages moving from serial to radio will be tagged with the group
 * ID compiled into the TOSBase, and messages moving from radio to
 * serial will be filtered by that same group id.
 */

#ifndef SIM
#include "CC2420.h"
#endif
#include "AM.h"
#include "Serial.h"
#include "devconf.h"
#include "lib6lowpan.h"

module BaseStationP {
  uses {
    interface Boot;
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;

    interface Send as UartSend;
    interface Ieee154Send as RadioSend;

    interface Receive as UartReceive;
    interface Receive as RadioReceive;
    interface Packet as RadioPacket;

    interface Send as ConfigureSend;
    interface Receive as ConfigureReceive;
    interface Timer<TMilli> as ConfigureTimer;
    interface IPAddress;


    interface Ieee154Packet as RadioIeeePacket;

    interface PacketLink;
    interface LowPowerListening;
    interface CC2420Config;

    interface Leds;

    interface Reset;
  }
}

implementation
{
  enum {
    UART_QUEUE_LEN = 10,
    RADIO_QUEUE_LEN = 10,
  };

  uint16_t radioRetries = BLIP_L2_RETRIES;
  uint16_t radioDelay   = 30;

  uint16_t serial_read;
  uint16_t radio_read;
  uint16_t serial_fail;
  uint16_t radio_fail;

  bool echo_busy;
  message_t echo_buf;
  config_reply_t *reply;

  message_t  uartQueueBufs[UART_QUEUE_LEN];
  message_t  *uartQueue[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartFull;

  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  *radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  task void uartSendTask();
  task void radioSendTask();

  void dropBlink() {
    call Leds.led2Toggle();
  }

  void failBlink() {
    call Leds.led2Toggle();
  }

#ifndef SIM
#define CHECK_NODE_ID if (0) return
#else
#define CHECK_NODE_ID if (TOS_NODE_ID != BASESTATION_ID) return
#endif
  task void configureReply() {
    if (echo_busy) return;

    reply->addr = call IPAddress.getShortAddr();
    reply->serial_read = serial_read;
    reply->radio_read = radio_read;
    reply->serial_fail = serial_fail;
    reply->radio_fail = radio_fail;

    echo_busy = TRUE;
    // delay sending the reply for a bit
    // the pc seems to usually drop the packet if we don't do this; 
    call ConfigureTimer.startOneShot(100);
  }

  event void Boot.booted() {
    uint8_t i;

    CHECK_NODE_ID;

    for (i = 0; i < UART_QUEUE_LEN; i++)
      uartQueue[i] = &uartQueueBufs[i];
    uartIn = uartOut = 0;
    uartBusy = FALSE;
    uartFull = TRUE;

    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = TRUE;

    echo_busy = FALSE;
    serial_read = 0;
    radio_read = 0;
    serial_fail = 0;
    radio_fail = 0;

    call RadioControl.start();
    call SerialControl.start();

    reply = (config_reply_t *)(&(echo_buf.data));
  }

  event void RadioControl.startDone(error_t error) {
    CHECK_NODE_ID;
    if (error == SUCCESS) {
      radioFull = FALSE;
#ifdef LPL_SLEEP_INTERVAL
      // SDH : can actually leave the base on full time in most cases.
      // call LowPowerListening.setLocalSleepInterval(LPL_SLEEP_INTERVAL);
#endif
    }
  }

  event void SerialControl.startDone(error_t error) {
    CHECK_NODE_ID;
    if (error == SUCCESS) {
      uartFull = FALSE;
    }
    reply->error = CONFIG_ERROR_BOOTED;
    post configureReply();
  }

  event void SerialControl.stopDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}

  uint8_t count = 0;

  message_t* receive(message_t* msg, void* payload, uint8_t len);
  
  event message_t *RadioReceive.receive(message_t *msg,
                                           void *payload,
                                           uint8_t len) {
    CHECK_NODE_ID NULL;
    dbg("base", "radio message received (%i)\n", len);
    return receive(msg, payload, len);
  }

  message_t* receive(message_t *msg, void *payload, uint8_t len) {
    message_t *ret = msg;
    CHECK_NODE_ID NULL;

    atomic {
      if (!uartFull)
	{
	  ret = uartQueue[uartIn];
	  uartQueue[uartIn] = msg;

	  uartIn = (uartIn + 1) % UART_QUEUE_LEN;
	
	  if (uartIn == uartOut)
	    uartFull = TRUE;

	  if (!uartBusy)
	    {
	      post uartSendTask();
	      uartBusy = TRUE;
	    }
	}
      else
	dropBlink();
    }
    
    return ret;
  }

  task void uartSendTask() {
    uint8_t len;
    message_t* msg;
    atomic
      if (uartIn == uartOut && !uartFull)
	{
	  uartBusy = FALSE;
	  return;
	}

    msg = uartQueue[uartOut];

    // Since we're forwarding fully formed radio packets, we can use
    // these headers.
    len = call RadioPacket.payloadLength(msg);

    if (call UartSend.send(uartQueue[uartOut], len) == SUCCESS) {
      call Leds.led1Toggle();
    }    else
      {
	failBlink();
	post uartSendTask();
      }
  }

  event void UartSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	if (msg == uartQueue[uartOut])
	  {
	    if (++uartOut >= UART_QUEUE_LEN)
	      uartOut = 0;
	    if (uartFull)
	      uartFull = FALSE;
	  }
    post uartSendTask();

  }

  event message_t *UartReceive.receive(message_t *msg,
                                       void *payload,
                                       uint8_t len) {
    message_t *ret = msg;
    bool reflectToken = FALSE;
    CHECK_NODE_ID msg;
    dbg("base", "uartreceive len %i of 0x%x\n", len, call SerialAMPacket.destination(msg));
#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
    WDTCTL = WDT_ARST_1000;
#endif

    atomic
      if (!radioFull)
	{
	  reflectToken = TRUE;
	  ret = radioQueue[radioIn];
	  radioQueue[radioIn] = msg;
	  if (++radioIn >= RADIO_QUEUE_LEN)
	    radioIn = 0;
	  if (radioIn == radioOut)
	    radioFull = TRUE;

	  if (!radioBusy)
	    {
	      post radioSendTask();
	      radioBusy = TRUE;
	    }
	}
      else
        dbg("base", "no enqueue\n");
// 	dropBlink();

    if (reflectToken) {
      //call UartTokenReceive.ReflectToken(Token);
    }
    
    return ret;
  }

  task void radioSendTask() {
    uint8_t len;
    ieee154_saddr_t addr;
    message_t* msg;
    
    dbg ("base", "radioSendTask()\n");
    atomic
      if (radioIn == radioOut && !radioFull)
	{
	  radioBusy = FALSE;
	  return;
	}

    msg = radioQueue[radioOut];
    len = call RadioPacket.payloadLength(msg);
    addr = call RadioIeeePacket.destination(msg);

    if (addr != 0xFFFF) {
      call PacketLink.setRetries(msg, radioRetries);
      call PacketLink.setRetryDelay(msg, radioDelay);
    } else {
      call PacketLink.setRetries(msg, 0);
    }
#ifdef LPL_SLEEP_INTERVAL
    call LowPowerListening.setRxSleepInterval(msg, LPL_SLEEP_INTERVAL);
#endif
    dbg("base", "radio send to: 0x%x len: %i\n", addr, len);
    if (call RadioSend.send(addr, msg, len) == SUCCESS)
      call Leds.led0Toggle();
    else
      {
	failBlink();
	post radioSendTask();
      }
  }

  event void RadioSend.sendDone(message_t* msg, error_t error) {
    CHECK_NODE_ID;
    dbg("base", "sendDone()\n");
    
    //if (!call PacketLink.wasDelivered(msg))
    // failBlink();
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	if (msg == radioQueue[radioOut])
	  {
	    if (++radioOut >= RADIO_QUEUE_LEN)
	      radioOut = 0;
	    if (radioFull)
	      radioFull = FALSE;
	  }
    
    post radioSendTask();
  }

#ifndef SIM
  event message_t *ConfigureReceive.receive(message_t *msg,
                                            void *payload,
                                            uint8_t len) {
    config_cmd_t *cmd;
    uint8_t error = CONFIG_ERROR_OK;
#if defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
    WDTCTL = WDT_ARST_1000;
#endif

    if (len != sizeof(config_cmd_t) || msg == NULL) return msg;
    // don't parse the message if we can't reply

    cmd = (config_cmd_t *)&msg->data;

    switch (cmd->cmd) {
    case CONFIG_ECHO:
      break;
    case CONFIG_SET_PARM:
      call CC2420Config.setChannel(cmd->rf.channel);
      // IPAddress calls sync() for you, I think, so we'll put it second 
      call IPAddress.setShortAddr(cmd->rf.addr);
      call CC2420Config.sync();
      radioRetries = cmd->retx.retries;
      radioDelay   = cmd->retx.delay;
      break;
    case CONFIG_REBOOT:
      call Reset.reset();
      break;
    case CONFIG_KEEPALIVE:
      return msg;
    }
    if (!echo_busy) {
      reply->error = error;
      post configureReply();
    }
    return msg;
  }


  event void CC2420Config.syncDone(error_t error) {

  }

  event void ConfigureSend.sendDone(message_t *msg, error_t error) {
    echo_busy = FALSE;
  }

  event void ConfigureTimer.fired() {
    call Leds.led2Toggle();
    if (call ConfigureSend.send(&echo_buf, sizeof(config_reply_t)) != SUCCESS)
      echo_busy = FALSE;
  }
#endif
}  
