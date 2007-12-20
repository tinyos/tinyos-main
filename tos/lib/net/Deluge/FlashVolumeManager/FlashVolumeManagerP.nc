/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#include "FlashVolumeManager.h"

generic module FlashVolumeManagerP()
{
#ifdef DELUGE
  provides {
    interface Notify<uint8_t> as DissNotify;
    interface Notify<uint8_t> as ReprogNotify;
  }
#endif
  uses {
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
#ifdef DELUGE
    interface DelugeStorage[uint8_t img_num];
    interface NetProg;
    interface Timer<TMilli> as Timer;
#endif
    interface AMSend as SerialAMSender;
    interface Receive as SerialAMReceiver;
    interface Leds;
  }
}

implementation
{
  // States for keeping track of split-phase events
  enum {
    S_IDLE,
    S_ERASE,
    S_WRITE,
    S_READ,
    S_CRC,
    S_REPROG,
    S_SYNC,
  };
  
  message_t serialMsg;
  uint8_t buffer[TOSH_DATA_LENGTH];   // Temporary buffer for "write" operation
  uint8_t img_num_reboot = 0xFF;       // Image number to reprogram
  uint8_t state = S_IDLE;              // Manager state for multiplexing "done" events
  
  /**
   * Replies to the PC request with operation results
   */
  void sendReply(error_t error, storage_len_t len)
  {
    SerialReplyPacket *srpkt = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    if (srpkt == NULL) {
      return;
    }
    if (error == SUCCESS) {
      srpkt->error = SERIALMSG_SUCCESS;
    } else {
      srpkt->error = SERIALMSG_FAIL;
    }
    call SerialAMSender.send(AM_BROADCAST_ADDR, &serialMsg, len);
  }
  
  event void BlockRead.readDone[uint8_t img_num](storage_addr_t addr, 
				void* buf, 
				storage_len_t len, 
				error_t error)
  {
    if (state == S_READ) {
      SerialReplyPacket *serialMsg_payload = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
      if (serialMsg_payload == NULL) {
	return;
      }
      if (buf == serialMsg_payload->data) {
        state = S_IDLE;
        sendReply(error, len + sizeof(SerialReplyPacket));
      }
    }
  }
  
  event void BlockRead.computeCrcDone[uint8_t img_num](storage_addr_t addr, 
				      storage_len_t len, 
				      uint16_t crc, 
				      error_t error)
  {
    if (state == S_CRC) {
      state = S_IDLE;
      
      if (error == SUCCESS) {
        SerialReplyPacket *srpkt = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
	if (srpkt == NULL) {
	  return;
	}
        srpkt->data[1] = crc & 0xFF;
        srpkt->data[0] = (crc >> 8) & 0xFF;
      }
      sendReply(error, 2 + sizeof(SerialReplyPacket));
    }
  }
  
  event void BlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, 
				  void* buf, 
				  storage_len_t len, 
				  error_t error)
  {
    if (state == S_WRITE && buf == buffer) {
      state = S_IDLE;
      sendReply(error, sizeof(SerialReplyPacket));
    }
  }
  
  event void BlockWrite.eraseDone[uint8_t img_num](error_t error)
  {
    if (state == S_ERASE) {
      call BlockWrite.sync[img_num]();
    }
  }
  
  event void BlockWrite.syncDone[uint8_t img_num](error_t error)
  {
    if (state == S_ERASE || state == S_SYNC) {
      state = S_IDLE;
      sendReply(error, sizeof(SerialReplyPacket));
    }
  }
  
  event void SerialAMSender.sendDone(message_t* msg, error_t error) {}
  
  event message_t* SerialAMReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    error_t error = SUCCESS;
    SerialReqPacket *srpkt = (SerialReqPacket *)payload;
    SerialReplyPacket *serialMsg_payload =
      (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    uint8_t img_num = 0xFF;

    if (serialMsg_payload == NULL) {
      return msg;
    }
    // Converts the image number that the user wants to the real image number
    switch (srpkt->img_num) {
      case 0:
        img_num = VOLUME_GOLDENIMAGE;
        break;
      case 1:
        img_num = VOLUME_DELUGE1;
        break;
      case 2:
        img_num = VOLUME_DELUGE2;
        break;
      case 3:
        img_num = VOLUME_DELUGE3;
        break;
    }
    
    if (img_num != 0xFF) {
      switch (srpkt->msg_type) {
        case SERIALMSG_ERASE:    // === Erases a volume ===
          state = S_ERASE;
          error = call BlockWrite.erase[img_num]();
          break;
        case SERIALMSG_WRITE:    // === Writes to a volume ===
          state = S_WRITE;
          memcpy(buffer, srpkt->data, srpkt->len);
          error = call BlockWrite.write[img_num](srpkt->offset,
                                                        buffer,
                                                        srpkt->len);
          break;
        case SERIALMSG_READ:     // === Reads a portion of a volume ===
          state = S_READ;
          error = call BlockRead.read[img_num](srpkt->offset,
                                                      serialMsg_payload->data,
                                                      srpkt->len);
          break;
        case SERIALMSG_CRC:      // === Computes CRC over a portion of a volume ===
          state = S_CRC;
          error = call BlockRead.computeCrc[img_num](srpkt->offset,
                                                            srpkt->len, 0);
          break;
        case SERIALMSG_SYNC:     // === Sync the flash ===
          state = S_SYNC;
          error = call BlockWrite.sync[img_num]();
	  break;
  #ifdef DELUGE
        case SERIALMSG_ADDR:     // === Gets the physical starting address of a volume ===
          *(nx_uint32_t*)(&serialMsg_payload->data) =
                                  (uint32_t)call DelugeStorage.getPhysicalAddress[img_num](0);
          sendReply(SUCCESS, sizeof(SerialReplyPacket) + 4);
          break;
        case SERIALMSG_REPROG_BS:   // === Reprograms only the base station ===
          state = S_REPROG;
          sendReply(SUCCESS, sizeof(SerialReplyPacket));
          img_num_reboot = img_num;
          call Timer.startOneShot(1024);
          break;
        case SERIALMSG_DISS:     // === Starts disseminating a volume ===
          signal DissNotify.notify(img_num);   // Notifies Deluge to start disseminate
          sendReply(SUCCESS, sizeof(SerialReplyPacket));
          break;
        case SERIALMSG_REPROG:   // === Reprograms the network (except the base station) ===
          signal ReprogNotify.notify(img_num);
          sendReply(SUCCESS, sizeof(SerialReplyPacket));
          break;
        case SERIALMSG_IDENT:
	  // This is not send using nx_uint32 in order to maintain
	  // consistency with data from the Deluge image.
          *(uint32_t*)(&serialMsg_payload->data) = IDENT_UID_HASH;
	  sendReply(SUCCESS, sizeof(SerialReplyPacket) + 4);
	  break;
  #endif
      }
    } else {
      error = FAIL;
    }
    
    // If a split-phase operation fails when being requested, signals the failure now
    if (error != SUCCESS) {
      state = S_IDLE;
      sendReply(error, sizeof(SerialReplyPacket));
    }
    
    return msg;
  }

#ifdef DELUGE
  event void Timer.fired()
  {
    // Reboots and reprograms
    call NetProg.programImgAndReboot(img_num_reboot);
  }
  
  command error_t DissNotify.enable() { return SUCCESS; }
  command error_t DissNotify.disable() { return SUCCESS; }
  command error_t ReprogNotify.enable() { return SUCCESS; }
  command error_t ReprogNotify.disable() { return SUCCESS; }
  
  default command storage_addr_t DelugeStorage.getPhysicalAddress[uint8_t img_num](storage_addr_t addr) { return 0; }
#endif

  default command error_t BlockWrite.write[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockWrite.erase[uint8_t img_num]() { return FAIL; }
  default command error_t BlockWrite.sync[uint8_t img_num]() { return FAIL; }
  default command error_t BlockRead.read[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.computeCrc[uint8_t img_num](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
}
