/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
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
*/

/**
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "imgNum2volumeId.h"

generic module DelugeManagerP()
{
  uses {
    interface DisseminationUpdate<DelugeCmd>;
    interface AMSend as SerialAMSender;
    interface Receive as SerialAMReceiver;
    interface Timer<TMilli> as DelayTimer;
    interface NetProg;
    interface Leds;
    interface StorageMap[uint8_t volumeId];
    interface DelugeMetadata;
    interface ObjectTransfer;
    interface DelugeVolumeManager;
    interface Resource;
    command void stop();
  }
}

implementation
{
  typedef nx_struct SerialReqPacket {
    nx_uint8_t cmd;
    nx_uint8_t imgNum;
  } SerialReqPacket;
  
  typedef nx_struct SerialReplyPacket {
    nx_uint8_t error;
  } SerialReplyPacket;

  message_t serialMsg;
  DelugeCmd delugeCmd;

  void sendReply(error_t error)
  {
    uint8_t len = sizeof(SerialReplyPacket);
    SerialReplyPacket *reply = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, len);
    if (reply == NULL) {
      return;
    }
    reply->error = error;
    call SerialAMSender.send(AM_BROADCAST_ADDR, &serialMsg, len);
  }

  event message_t* SerialAMReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    SerialReqPacket *request = (SerialReqPacket *)payload;
    memset(&delugeCmd, 0, sizeof(DelugeCmd));
    call stop();
    delugeCmd.type = request->cmd;
    // Converts the image number that the user wants to the real image number
    request->imgNum = imgNum2volumeId(request->imgNum);

    switch (request->cmd) {
    case DELUGE_CMD_STOP:
      call DisseminationUpdate.change(&delugeCmd);
    case DELUGE_CMD_LOCAL_STOP:
      sendReply(SUCCESS);
      call Resource.release();
      break;
    case DELUGE_CMD_ONLY_DISSEMINATE:
    case DELUGE_CMD_DISSEMINATE_AND_REPROGRAM:
      if (request->imgNum != NON_DELUGE_VOLUME &&
	  (call Resource.isOwner() || 
	   call Resource.immediateRequest() == SUCCESS)) {
	call DelugeMetadata.read(request->imgNum);
      } else {
	sendReply(FAIL);
      }
      break;
    case DELUGE_CMD_REPROGRAM:
    case DELUGE_CMD_REBOOT:
      if (request->imgNum == NON_DELUGE_VOLUME) {
	sendReply(FAIL);
	break;
      }
      delugeCmd.imgNum = request->imgNum;
      call DelayTimer.startOneShot(1024);
      sendReply(SUCCESS);
      break;
    }
    return msg;
  }

  event void DelayTimer.fired()
  {
    switch (delugeCmd.type) {
    case DELUGE_CMD_REPROGRAM:
      call NetProg.programImageAndReboot(call StorageMap.getPhysicalAddress[delugeCmd.imgNum](0));
      break;
    case DELUGE_CMD_REBOOT:
      call NetProg.reboot();
      break;
    }
  }

  event void DelugeMetadata.readDone(uint8_t imgNum, DelugeIdent* ident, error_t error)
  {
    delugeCmd.imgNum = imgNum;
    sendReply(error);
    if (error != SUCCESS) {
      return;
    }
    switch (delugeCmd.type) {
    case DELUGE_CMD_ONLY_DISSEMINATE:
    case DELUGE_CMD_DISSEMINATE_AND_REPROGRAM:
      delugeCmd.uidhash = ident->uidhash;
      delugeCmd.size = ident->size;
      call DisseminationUpdate.change(&delugeCmd);
      call ObjectTransfer.publish(delugeCmd.uidhash, delugeCmd.size, delugeCmd.imgNum);
      break;
    }    
  }

  event void Resource.granted() {}
  event void ObjectTransfer.receiveDone(error_t error) {}
  event void SerialAMSender.sendDone(message_t* msg, error_t error) {}
  event void DelugeVolumeManager.eraseDone(uint8_t imgNum) {}
}
