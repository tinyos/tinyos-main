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
 * @author Jeongyeup Paek <jpaek@enl.usc.edu>
 **/

#include "SerialLoader.h"

module SerialLoaderP
{
  uses {
    interface Boot;
    interface SplitControl as SerialSplitControl;
    interface AMSend as SerialAMSender;
    interface Receive as SerialAMReceiver;
    interface Leds;
    interface DynamicLoader;
    interface BigCrc;
  }
}
implementation
{
  message_t serialMsg;
  uint32_t dumpAddr = 0;
  
  uint8_t image[MAX_BIN_SIZE];

  event void Boot.booted()
  {
    call SerialSplitControl.start();
  }
  
  event void SerialSplitControl.startDone(error_t error)
  {
    if (error != SUCCESS) {
      call SerialSplitControl.start();
    }
  }
  
  event void SerialSplitControl.stopDone(error_t error) {}
  
  void sendReply(error_t error, uint8_t len)
  {
    SerialReplyPacket *srpkt = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    if (error == SUCCESS) {
      srpkt->error = SERIALMSG_SUCCESS;
    } else {
      srpkt->error = SERIALMSG_FAIL;
    }
    call SerialAMSender.send(AM_BROADCAST_ADDR, &serialMsg, len);
  }
  
  
  event void SerialAMSender.sendDone(message_t* msg, error_t error) {}
  
  error_t write_image(uint16_t offset, void *data, uint16_t len) {
    if ((offset + len > MAX_BIN_SIZE) || (data == NULL))
      return FAIL;
    memcpy(&image[offset], data, len);
    return SUCCESS;
  }

  error_t read_image(uint16_t offset, void *readbuf, uint16_t len) {
    if ((offset + len > MAX_BIN_SIZE) || (readbuf == NULL))
      return FAIL;
    memcpy(readbuf, &image[offset], len);
    return SUCCESS;
  }

  event void DynamicLoader.loadFromFlashDone(uint8_t volumeId, tosthread_t id, error_t error) {}
  event void DynamicLoader.loadFromMemoryDone(void *addr, tosthread_t id, error_t error) {
    sendReply(error, sizeof(SerialReplyPacket));
  }

  event void BigCrc.computeCrcDone(void* buf, uint16_t len, uint16_t crc, error_t error)
  {
    SerialReplyPacket *srpkt = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
        
    srpkt->data[1] = crc & 0xFF;
    srpkt->data[0] = (crc >> 8) & 0xFF;
    sendReply(SUCCESS, 2 + sizeof(SerialReplyPacket));
  }

  void sendCrcReply(uint16_t offset, uint16_t len)
  {
    call BigCrc.computeCrc(&(image[offset]), len);
  }


  event message_t* SerialAMReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    uint16_t i;
    error_t error = FAIL;
    SerialReqPacket *srpkt = (SerialReqPacket *)payload;
    SerialReplyPacket *serialMsg_payload = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    
    switch (srpkt->msg_type) {
      case SERIALMSG_ERASE :
        for (i = 0; i < MAX_BIN_SIZE; i++) { image[i] = 0; }
        call Leds.set(7);
        for (i = 0; i < 2000; i++) {}
        call Leds.set(0);
        sendReply(SUCCESS, sizeof(SerialReplyPacket));
        break;
      case SERIALMSG_RUN :
        error = call DynamicLoader.loadFromMemory(image);
        if (error != SUCCESS)
          sendReply(error, sizeof(SerialReplyPacket));
        break;
      case SERIALMSG_WRITE :
        error = write_image(srpkt->offset, srpkt->data, srpkt->len);
        if (error != SUCCESS)
          call Leds.led0On();
        sendReply(error, sizeof(SerialReplyPacket));
        break;
      case SERIALMSG_READ :
        error = read_image(srpkt->offset, serialMsg_payload->data, srpkt->len);
        if (error != SUCCESS)
          sendReply(error, sizeof(SerialReplyPacket));
        else
          sendReply(error, len + sizeof(SerialReplyPacket));
        break;
      case SERIALMSG_LEDS:
        call Leds.set(7);
        for (i = 0; i < 2000; i++) {}
        call Leds.set(0);
        break;
      case SERIALMSG_CRC :
        sendCrcReply(srpkt->offset, srpkt->len);
        break;
    }
    
    return msg;
  }
}

