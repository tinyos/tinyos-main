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
/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Reliable Packet Link Functionality
 * @author David Moss
 * @author Jon Wyant
 * @author Miklos Maroti
 */

#include <PacketLinkLayer.h>

module PacketLinkLayerP {
  provides {
    interface Send;
    interface PacketLink;
    interface RadioPacket;
  }

  uses {
    interface Send as SubSend;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as DelayTimer;
    interface RadioPacket as SubPacket;
  }
}

implementation {

  /** The message currently being sent */
  message_t *currentSendMsg;

  /** Length of the current send message */
  uint8_t currentSendLen;

  /** The length of the current send message */
  uint16_t totalRetries;

  /***************** Prototypes ***************/

  task void send();
  void signalDone(error_t error);


  /***************** PacketLink Commands ***************/

  link_metadata_t* getMeta(message_t* msg) {
    return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
  }

  /**
   * Set the maximum number of times attempt message delivery
   * Default is 0
   * @param msg
   * @param maxRetries the maximum number of attempts to deliver
   *     the message
   */
  command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
    getMeta(msg)->maxRetries = maxRetries;
  }

  /**
   * Set a delay between each retry attempt
   * @param msg
   * @param retryDelay the delay betweeen retry attempts, in milliseconds
   */
  command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) {
    getMeta(msg)->retryDelay = retryDelay;
  }

  /**
   * @return the maximum number of retry attempts for this message
   */
  command uint16_t PacketLink.getRetries(message_t *msg) {
    return getMeta(msg)->maxRetries;
  }

  /**
   * @return the delay between retry attempts in ms for this message
   */
  command uint16_t PacketLink.getRetryDelay(message_t *msg) {
    return getMeta(msg)->retryDelay;
  }

  /**
   * @return TRUE if the message was delivered.
   */
  command bool PacketLink.wasDelivered(message_t *msg) {
    return call PacketAcknowledgements.wasAcked(msg);
  }

  /***************** Send Commands ***************/
  /**
   * Each call to this send command gives the message a single
   * DSN that does not change for every copy of the message
   * sent out.  For messages that are not acknowledged, such as
   * a broadcast address message, the receiving end does not
   * signal receive() more than once for that message.
   */
  command error_t Send.send(message_t *msg, uint8_t len) {
    error_t error = EBUSY;
    if(currentSendMsg == NULL) {

      if(call PacketLink.getRetries(msg) > 0) {
        call PacketAcknowledgements.requestAck(msg);
      }

      if((error = call SubSend.send(msg, len)) == SUCCESS) {
        currentSendMsg = msg;
        currentSendLen = len;
        totalRetries = 0;
      }
    }
    return error;
  }

  command error_t Send.cancel(message_t *msg) {
    if(currentSendMsg == msg) {
      currentSendMsg = NULL;
      return call SubSend.cancel(msg);
    }

    return FAIL;
  }


  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void *Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }

  /***************** SubSend Events ***************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
    totalRetries++;

    if(call PacketAcknowledgements.wasAcked(msg)) {
      signalDone(SUCCESS);
      return;

    } else if(totalRetries < call PacketLink.getRetries(currentSendMsg)) {

      if(call PacketLink.getRetryDelay(currentSendMsg) > 0) {
        // Resend after some delay
        call DelayTimer.startOneShot(call PacketLink.getRetryDelay(currentSendMsg));
      } else {
        // Resend immediately
        post send();
      }

      return;
    }

    signalDone(error);
  }

  /***************** Timer Events ****************/
  /**
   * When this timer is running, that means we're sending repeating messages
   * to a node that is receive check duty cycling.
   */
  event void DelayTimer.fired() {
    if(currentSendMsg != NULL) {
      post send();
    }
  }

  /***************** Tasks ***************/
  task void send() {
    if(call PacketLink.getRetries(currentSendMsg) > 0) {
      call PacketAcknowledgements.requestAck(currentSendMsg);
    }

    if(call SubSend.send(currentSendMsg, currentSendLen) != SUCCESS) {
      post send();
    }
  }

  /***************** Functions ***************/
  void signalDone(error_t error) {
    message_t* msg = currentSendMsg;
    currentSendMsg = NULL;

    // AT: A bit of a hack to be able to keep track of the number of retries
    // printfUART("Signaling done with total retries at 0x%x\n", totalRetries);

    call DelayTimer.stop();
    call PacketLink.setRetries(msg, totalRetries);
    signal Send.sendDone(msg, error);
  }

  /***************** Functions ***************/
  async command uint8_t RadioPacket.headerLength(message_t* msg) {
    return call SubPacket.headerLength(msg);
  }

  async command uint8_t RadioPacket.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg);
  }

  async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
    call SubPacket.setPayloadLength(msg, length);
  }

  async command uint8_t RadioPacket.maxPayloadLength() {
    return call SubPacket.maxPayloadLength();
  }

  async command uint8_t RadioPacket.metadataLength(message_t* msg) {
    return call SubPacket.metadataLength(msg) + sizeof(link_metadata_t);
  }

  async command void RadioPacket.clear(message_t* msg) {
    getMeta(msg)->maxRetries = 0;
    call SubPacket.clear(msg);
  }
}
