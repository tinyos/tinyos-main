/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "FlashVolumeManager.h"
#include "StorageVolumes.h"

generic module FlashVolumeManagerP()
{
  uses {
    interface Boot;
    interface SplitControl as SerialSplitControl;
    interface BlockRead;
    interface BlockWrite;
    interface AMSend as SerialAMSender;
    interface Receive as SerialAMReceiver;
    interface Leds;
    interface DynamicLoader;
  }
}

implementation
{
  message_t serialMsg;
  storage_addr_t dumpAddr = 0;
  
  event void Boot.booted() {
    while (call SerialSplitControl.start() != SUCCESS);
  }
  
  event void SerialSplitControl.startDone(error_t error)
  {
    if (error != SUCCESS) {
      while (call SerialSplitControl.start() != SUCCESS);
    }
  }
    
  void sendReply(error_t error, storage_len_t len)
  {
    SerialReplyPacket *srpkt = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    if (error == SUCCESS) {
      srpkt->error = SERIALMSG_SUCCESS;
    } else {
      srpkt->error = SERIALMSG_FAIL;
    }
    call SerialAMSender.send(AM_BROADCAST_ADDR, &serialMsg, len);
  }
  
  event void BlockRead.readDone(storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    sendReply(error, len + sizeof(SerialReplyPacket));
  }
  
  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error)
  {
    if (error == SUCCESS) {
      SerialReplyPacket *srpkt = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
      srpkt->data[1] = crc & 0xFF;
      srpkt->data[0] = (crc >> 8) & 0xFF;
    }
    sendReply(error, 2 + sizeof(SerialReplyPacket));
  }
  
  event void BlockWrite.writeDone(storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    if (error != SUCCESS) {
      call Leds.led1On();
    }
    sendReply(error, sizeof(SerialReplyPacket));
  }
  
  event void BlockWrite.eraseDone(error_t error) {
    sendReply(error, sizeof(SerialReplyPacket));
  }
    
  event message_t* SerialAMReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    uint16_t i;
    error_t error = SUCCESS;
    SerialReqPacket *srpkt = (SerialReqPacket *)payload;
    SerialReplyPacket *serialMsg_payload = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    
    switch (srpkt->msg_type) {
      case SERIALMSG_ERASE :
        error = call BlockWrite.erase();
        if (error != SUCCESS) {
          sendReply(error, sizeof(SerialReplyPacket));
        }
        break;
      case SERIALMSG_WRITE :
        call Leds.led2On();
        error = call BlockWrite.write(srpkt->offset, srpkt->data, srpkt->len);
        if (error != SUCCESS) {
          sendReply(error, sizeof(SerialReplyPacket));
          call Leds.led0On();
        }
        break;
      case SERIALMSG_READ :
        error = call BlockRead.read(srpkt->offset, serialMsg_payload->data, srpkt->len);
        if (error != SUCCESS) {
          sendReply(error, sizeof(SerialReplyPacket));
        }
        break;
      case SERIALMSG_CRC :
        error = call BlockRead.computeCrc(srpkt->offset, srpkt->len, 0);
        if (error != SUCCESS) {
          sendReply(error, sizeof(SerialReplyPacket));
        }
        break;
      case SERIALMSG_LEDS:
        call Leds.set(7);
        for (i = 0; i < 2000; i++) {}
        call Leds.set(0);
        break;
      case SERIALMSG_RUN :
        error = call DynamicLoader.loadFromFlash(VOLUME_MICROEXEIMAGE);
        if (error != SUCCESS)
          sendReply(error, sizeof(SerialReplyPacket));
        break;
    }
    
    return msg;
  }
  
  event void DynamicLoader.loadFromFlashDone(uint8_t volumeId, tosthread_t id, error_t error) {
    sendReply(error, sizeof(SerialReplyPacket));
  }
  
  event void DynamicLoader.loadFromMemoryDone(void *addr, tosthread_t id, error_t error) {}
  event void BlockWrite.syncDone(error_t error) {}
  event void SerialAMSender.sendDone(message_t* msg, error_t error) {}
  event void SerialSplitControl.stopDone(error_t error) {} 
}
