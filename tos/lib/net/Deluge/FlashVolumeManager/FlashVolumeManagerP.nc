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

generic module FlashVolumeManagerP()
{
  uses {
    interface BlockRead[uint8_t imgNum];
    interface BlockWrite[uint8_t imgNum];
    interface Resource;
    interface ArbiterInfo;
    interface AMSend as SerialAMSender;
    interface Receive as SerialAMReceiver;
    interface Timer<TMilli> as TimeoutTimer;
    interface Leds;
  }
}

implementation
{
  typedef nx_struct SerialReqPacket {
    nx_uint8_t cmd;
    nx_uint8_t imgNum;
    nx_uint16_t offset;
    nx_uint16_t len;
    nx_uint8_t data[0];
  } SerialReqPacket;
  
  typedef nx_struct SerialReplyPacket {
    nx_uint8_t error;
    nx_uint8_t data[0];
  } SerialReplyPacket;


  enum {
    CMD_ERASE = 0,
    CMD_WRITE = 1,
    CMD_READ  = 2,
    CMD_CRC   = 3,
    CMD_ADDR  = 4,
    CMD_SYNC  = 5,
    CMD_IDENT = 6
  };

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
  uint8_t buffer[TOSH_DATA_LENGTH];    // Temporary buffer for "write" operation
  uint8_t currentImgNum = 0xFF;      // Image number to reprogram
  uint8_t state = S_IDLE;              // Manager state for multiplexing "done" events

  nx_struct ShortIdent {
    nx_uint8_t name[16];
    //nx_uint8_t username[16];
    //nx_uint8_t hostname[16];
    nx_uint32_t timestamp;
    nx_uint32_t uidhash;
    nx_uint16_t nodeid;
  };

  uint8_t imgNum2volumeId[] = {
    VOLUME_GOLDENIMAGE,
    VOLUME_DELUGE1,
    VOLUME_DELUGE2,
    VOLUME_DELUGE3
  };
  
  void sendReply(error_t error, storage_len_t len)
  {
    SerialReplyPacket *reply = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    if (reply == NULL) {
      return;
    }
    reply->error = error;
    call SerialAMSender.send(AM_BROADCAST_ADDR, &serialMsg, len);
  }
  
  event void BlockRead.readDone[uint8_t imgNum](storage_addr_t addr, 
				void* buf, 
				storage_len_t len, 
				error_t error)
  {
    if (state == S_READ) {
      SerialReplyPacket *reply = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
      if (reply == NULL) {
	return;
      }
      if (buf == reply->data) {
        state = S_IDLE;
        sendReply(error, len + sizeof(SerialReplyPacket));
      }
    }
  }
  
  event void BlockRead.computeCrcDone[uint8_t imgNum](storage_addr_t addr, 
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
  
  event void BlockWrite.writeDone[uint8_t imgNum](storage_addr_t addr, 
				  void* buf, 
				  storage_len_t len, 
				  error_t error)
  {
    if (state == S_WRITE && buf == buffer) {
      state = S_IDLE;
      sendReply(error, sizeof(SerialReplyPacket));
    }
  }
  
  event void BlockWrite.eraseDone[uint8_t imgNum](error_t error)
  {
    if (state == S_ERASE) {
      call BlockWrite.sync[imgNum]();
    }
  }
  
  event void BlockWrite.syncDone[uint8_t imgNum](error_t error)
  {
    if (state == S_ERASE || state == S_SYNC) {
      state = S_IDLE;
      sendReply(error, sizeof(SerialReplyPacket));
    }
  }
  
 
  event message_t* SerialAMReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    error_t error = SUCCESS;
    SerialReqPacket *request = (SerialReqPacket *)payload;
    SerialReplyPacket *reply = (SerialReplyPacket *)call SerialAMSender.getPayload(&serialMsg, sizeof(SerialReplyPacket));
    nx_struct ShortIdent *shortIdent;
    uint8_t imgNum = 0xFF;

    if (reply == NULL) {
      return msg;
    }

    if (state != S_IDLE) {
      return msg;
    }

    // Converts the image number that the user wants to the real image number
    imgNum = imgNum2volumeId[request->imgNum];
    
    if (imgNum != 0xFF) {
      error = SUCCESS;
      // We ask for a reservation only for erase and write.
      switch (request->cmd) {
	case CMD_ERASE:
	case CMD_WRITE:
	  if (!call Resource.isOwner()) {
	    error = call Resource.immediateRequest();
	  }
      }
      if (error == SUCCESS) {
	call Leds.led1On();
	call TimeoutTimer.startOneShot(2*1024);
	currentImgNum = imgNum;
	switch (request->cmd) {
        case CMD_ERASE:    // === Erases a volume ===
          state = S_ERASE;
          error = call BlockWrite.erase[imgNum]();
          break;
        case CMD_WRITE:    // === Writes to a volume ===
          state = S_WRITE;
          memcpy(buffer, request->data, request->len);
          error = call BlockWrite.write[imgNum](request->offset,
						 buffer,
						 request->len);
          break;
        case CMD_READ:     // === Reads a portion of a volume ===
          state = S_READ;
          error = call BlockRead.read[imgNum](request->offset,
					       reply->data,
					       request->len);
          break;
        case CMD_CRC:      // === Computes CRC over a portion of a volume ===
          state = S_CRC;
          error = call BlockRead.computeCrc[imgNum](request->offset,
						     request->len, 0);
          break;
        case CMD_SYNC:     // === Sync the flash ===
          state = S_SYNC;
          error = call BlockWrite.sync[imgNum]();
	  break;
        case CMD_IDENT:
	  shortIdent = (nx_struct ShortIdent*)&reply->data;
	  memset(shortIdent, 0, sizeof(nx_struct ShortIdent));
	  memcpy(shortIdent->name, IDENT_APPNAME, sizeof(IDENT_APPNAME));
	  //memcpy(shortIdent->username, IDENT_USER_ID, sizeof(IDENT_USER_ID));
	  //memcpy(shortIdent->hostname, IDENT_HOSTNAME, sizeof(IDENT_HOSTNAME));
          shortIdent->timestamp = IDENT_TIMESTAMP;
          shortIdent->uidhash  = IDENT_UIDHASH;
          shortIdent->nodeid = TOS_NODE_ID;
	  sendReply(SUCCESS, sizeof(SerialReplyPacket) + sizeof(nx_struct ShortIdent));
	  break;
	}
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

  event void TimeoutTimer.fired()
  {
    // Release the resource.
    if (state == S_IDLE && call Resource.isOwner()) {
      call Leds.led1Off();
      call Resource.release();
    }
    if (state == S_IDLE && !call ArbiterInfo.inUse()) {
      call Leds.led1Off();
    }
  }

  event void SerialAMSender.sendDone(message_t* msg, error_t error) {}
  event void Resource.granted() {}

  default command error_t BlockWrite.write[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }
  default command error_t BlockWrite.sync[uint8_t imgNum]() { return FAIL; }
  default command error_t BlockRead.read[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.computeCrc[uint8_t imgNum](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }

  default async command error_t Resource.immediateRequest() { return FAIL; }
  default async command error_t Resource.release() { return FAIL; }
  default async command bool Resource.isOwner() { return FAIL; }
}
