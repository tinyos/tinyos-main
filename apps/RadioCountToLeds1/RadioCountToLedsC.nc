/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "Timer.h"
#include "RadioCountToLeds.h"
#include "printf.h"
/**
 * Implementation of the RadioCountToLeds application. RadioCountToLeds
 * maintains a 4Hz counter, broadcasting its value in an AM packet
 * every time it gets updated. A RadioCountToLeds node that hears a counter
 * displays the bottom three bits on its LEDs. This application is a useful
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

module RadioCountToLedsC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Timer<TMilli> as SendTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface CC2520Key;
    interface CC2520PacketBody;

    interface PacketLink;
  }
}
implementation {

  message_t packet;
  uint8_t key[16] = {0x98,0x67,0x7F,0xAF,0xD6,0xAD,0xB7,0x0C,0x59,0xE8,0xD9,0x47,0xC9,0x71,0x15,0x0F};
  uint8_t keyReady = 0; // should be set to 1 when key setting is done

  bool locked;
  uint16_t counter = 0;

  event void Boot.booted()
  {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err)
  {
    if (err == SUCCESS) {
      call CC2520Key.setKey(key);
 //     if(TOS_NODE_ID == 1)
	//call MilliTimer.startPeriodic(4096);
    } else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err)
  {
  }
  event void CC2520Key.setKeyDone(uint8_t status)
  {
	keyReady = 1;
  }

  event void CC2520Key.getKeyDone(uint8_t status, uint8_t *ptr)
  {
  }

  event void SendTimer.fired()
  {
     if (call AMSend.send(AM_BROADCAST_ADDR, &packet, 
		sizeof(radio_count_msg_t)) == SUCCESS) {
	locked = TRUE;
	//printf("SendTimer fired\n");
	//printfflush();
     }


  }

    uint8_t getMICLength(uint8_t securityLevel) {
	if(securityLevel == SEC_MIC_32 || securityLevel == SEC_ENC_MIC_32) 	
		return 4;
	else if(securityLevel == SEC_MIC_64 || securityLevel == SEC_ENC_MIC_64)
		return 8;
	else if(securityLevel == SEC_ENC_MIC_128 || securityLevel == SEC_ENC_MIC_128)
		return 16;
	return 0;
  	}

   void readBefore()
   {
	uint8_t i;
	cc2520_header_t* header = call CC2520PacketBody.getHeader( &packet );
	uint8_t *ptr = (uint8_t *)header;
	uint8_t micLength 	= getMICLength(header->secHdr.secLevel);
	uint8_t encryptLength  = header->length - CC2520_SIZE - micLength;
	printf("Packet Before Encryption\n");
	printf("header Length:%x\n", header->length);
	printf("MIC Length:%x\t%x\n",micLength,encryptLength);
	for(i=0;i<header->length - micLength -1;i++) {
		printf("%x\t",ptr[i]);
	}
	printfflush();
   }

  event void MilliTimer.fired()
  {
    int ret;
    counter++;
	//printf("MilliTimer fired\n");
	//printfflush();
    dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else if(keyReady == 1) {

      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));

      if (rcm == NULL) {
	return;
      }

      rcm->counter = counter;
      //call CC2420Security.setCtr(&packet, 0, 0);
      //call CC2420Security.setCbcMac(&packet, 0, 0, 16);
      //call CC2420Security.setCcm(&packet, 1, 0, 16);
      call PacketLink.setRetries(&packet, 1);
      //call SendTimer.startOneShot(5000);
	//readBefore();
	ret= call AMSend.send(AM_BROADCAST_ADDR, &packet, 
		sizeof(radio_count_msg_t));
	printf("return:%x\n",ret);
	printfflush();
     }
  }

  event message_t* Receive.receive(message_t* bufPtr,
				   void* payload, uint8_t len)
  {
    dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
	printf("counter:%x\n",rcm->counter);
	printfflush();
      if (rcm->counter & 0x1) {
	call Leds.led0On();
      }
      else {
	call Leds.led0Off();
      }
      if (rcm->counter & 0x2) {
	call Leds.led1On();
      }
      else {
	call Leds.led1Off();
      }
      if (rcm->counter & 0x4) {
	call Leds.led2On();
      }
      else {
	call Leds.led2Off();
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error)
  {
	printf("AMSend sendDone:%x\n",error);
	printfflush();
    if (&packet == msg) {
      locked = FALSE;
    }
  }

}
