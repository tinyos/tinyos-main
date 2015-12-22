/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 * @author Sanjeet Raj Pandey <code@tkn.tu-berlin.de>
 * @author Sonali Deo <code@tkn.tu-berlin.de>
 * @author Jasper Buesch <code@tkn.tu-berlin.de>
 */


#include "IEEE802154.h"
#include <Ieee154.h>
#include <MMAC.h>
#include <Jn516.h>
#include "Timer.h"

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#endif

// If frames with set ext. dest. address should request an acknowledgment
// #define AUTO_REQ_ACK_EXT TRUE

// #define ENABLE_PRINTF

#ifndef MAX_RETRANSMITS
#define MAX_RETRANSMITS 3
#endif

#ifndef ENABLE_ADDRESS_FILTERING
#define ENABLE_ADDRESS_FILTERING TRUE
#endif

#ifndef JN516_DEF_CHANNEL
#define JN516_DEF_CHANNEL 11
#endif

#define MAX_ACK_WAIT_DURATION_SYMBOLS 54 // = turnaround time (12symbols) + backoff (20symb) + ACK len (5 bytes * 2) + preamble (12symbols)
#define MAX_ACK_WAIT_DURATION_32KHZ (MAX_ACK_WAIT_DURATION_SYMBOLS/2)
#define ACK_DELAY_SYMBOLS 12

#ifndef ENABLE_PRINTF
  #define PRINTF(x)
#else
  #define PRINTF(x) printf(x); printfflush()
#endif


module Ieee154BareP {
  provides {
    interface SplitControl;
    interface Send as BareSend;
    interface Receive as BareReceive;
    interface GetSet<uint8_t> as RadioChannel;
  }
  uses {
    interface Ieee154Address;
    interface Jn516PacketBody;
    interface Jn516PacketTransform;
    interface Queue<message_t *> as RxQueue;
    interface Pool<message_t> as RxMessagePool;
    interface Alarm<T32khz, uint32_t> as RetransmissionAlarms;
  }
}

implementation {

  // ----- Declarations -------------

  void init();
  void RadioCallback(uint32_t bitmap) @hwevent() ;
  unsigned short crc16_data(const unsigned char *data, int len, unsigned short acc);
  inline unsigned short crc16_add(unsigned char b, unsigned short acc);
  void signalDone( error_t err );
  void send_ack(message_t* msg) @spontaneous();


  void task startRadio();
  void task stopRadio();
  void task deliverQueuedMsg();
  void task signalSendDone();
  void task signalSendDoneFail();
  void task enqueueRxedMsg();

  #define CONTINUE_RECEIVING_AND_RETURN()  vMMAC_StartPhyReceive(&m_rxFrame, E_MMAC_RX_START_NOW);return

  // --------------------------------

  norace uint8_t m_waitingForAck;
  uint8_t m_expectedDsn;
  uint8_t m_lastDsnRecv;
  uint8_t m_channel;
  uint8_t m_retransmissionCnt;
  norace bool m_rxMsgBufferFree;
  message_t* m_txMsg;
  message_t* m_rxMsgBuffer;
  tsPhyFrame m_txFrame;
  norace bool m_txFrameLock;
  norace tsPhyFrame m_txAckFrame;
  norace tsPhyFrame m_rxFrame;
  norace error_t m_txError;
  norace uint32_t m_recvTime;
  norace bool m_ackSending;

  norace ieee154_panid_t m_panID;
  norace ieee154_saddr_t m_saddr;
  norace ieee154_laddr_t m_laddr;

  // ---------------------------------------------------

  void init() {
    atomic {
      m_waitingForAck = FALSE;
      m_channel = JN516_DEF_CHANNEL;
      m_retransmissionCnt = 0;
      m_rxMsgBufferFree = TRUE;
      m_rxMsgBuffer = call RxMessagePool.get();
      m_ackSending = FALSE;
      m_txFrameLock = FALSE;

      m_panID = call Ieee154Address.getPanId();
      m_saddr = call Ieee154Address.getShortAddr();
      m_laddr = call Ieee154Address.getExtAddr();
    }
  }


  // ---------------------------------------------------

  command error_t SplitControl.start() {
    init();
    post startRadio();
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    post stopRadio();
    return SUCCESS;
  }

  command void RadioChannel.set(uint8_t val ) {
    m_channel = val;
    vMMAC_SetChannel(m_channel);
  }

  command uint8_t RadioChannel.get() {
    return m_channel;
  }


  // ----- Callback function from JN516's MMAC lib ---

  void RadioCallback(uint32_t bitmap) @hwevent() {
    uint32_t errors = 0xFFFFFFFF;
    uint8_t payloadLen;
    uint8_t* ptr;
    uint8_t* lengthFieldPtr;
    uint8_t* payloadPtr;
    uint16_t hdr;

    // ---- TX interrupt section ----
    if(bitmap & E_MMAC_INT_TX_COMPLETE) {
      errors = u32MMAC_GetTxErrors();
      if(errors == 0) {
        m_txError = SUCCESS;
      } else {
        m_txError = FAIL;
      }
      if (m_ackSending == FALSE) {
        if (m_waitingForAck == FALSE) {
          post signalSendDone();
        }
      }
      if (m_ackSending == TRUE) {
        m_ackSending = FALSE;
      }
      if (m_waitingForAck) { // now we need to wait for the ACK
        call RetransmissionAlarms.start(MAX_ACK_WAIT_DURATION_32KHZ);
      }
    }

    // ---- RX interrupt section ----
    if (bitmap & E_MMAC_INT_RX_COMPLETE) {
      m_recvTime = u32MMAC_GetTime();
      ptr = m_rxFrame.uPayload.au8Byte;

      errors = u32MMAC_GetRxErrors();
      // TODO: Handle any error that might harm us...

      if (crc16_data( m_rxFrame.uPayload.au8Byte, m_rxFrame.u8PayloadLength, 0) != 0x0000) {
        CONTINUE_RECEIVING_AND_RETURN();
      }

      ptr = m_rxFrame.uPayload.au8Byte;

      // If we are waiting for an achnowledgement to arrive
      if (m_waitingForAck) {
        if ((ptr[0] & IEEE154_TYPE_MASK) == IEEE154_TYPE_ACK) {
          if (ptr[2] == m_expectedDsn) {
            m_waitingForAck = FALSE;
            //post stopRetranmissionTimer();
            call RetransmissionAlarms.stop();
            post signalSendDone();
          }
        }
        CONTINUE_RECEIVING_AND_RETURN();
      }

      if (m_rxMsgBufferFree == FALSE) {
        // there is yet another packet waiting to be enqueued
        CONTINUE_RECEIVING_AND_RETURN();
      }

      #ifdef ENABLE_ADDRESS_FILTERING
      hdr = ptr[0] + (ptr[1] << 8);
      // Address filtering
      if ( (hdr & (IEEE154_ADDR_MASK << IEEE154_FCF_DEST_ADDR_MODE)) ==
                (IEEE154_ADDR_NONE << IEEE154_FCF_DEST_ADDR_MODE)){
        CONTINUE_RECEIVING_AND_RETURN();
      }

      if ( (hdr & IEEE154_TYPE_MASK) != IEEE154_TYPE_DATA) {
        // we are nothing else but data frames at or after this point
        CONTINUE_RECEIVING_AND_RETURN();
      }

      if ( (hdr & (IEEE154_ADDR_MASK << IEEE154_FCF_DEST_ADDR_MODE)) ==
                (IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE)) {
          // destination address is in short format
          uint16_t sAddr = ptr[5] + (ptr[6] << 8);  // needed to avoid unaligned access
          if ((m_saddr != 0xffff) && (sAddr != 0xffff) && (sAddr != m_saddr)) {
            CONTINUE_RECEIVING_AND_RETURN();
          }
      } else if ( (hdr & (IEEE154_ADDR_MASK << IEEE154_FCF_DEST_ADDR_MODE)) ==
                (IEEE154_ADDR_EXT << IEEE154_FCF_DEST_ADDR_MODE)) {
          // destination address is in extended address format
          uint8_t i;
          for (i=0; i<6; i++){
            if (ptr[i+5] != m_laddr.data[i]) {  // needed to avoid unaligned access
              CONTINUE_RECEIVING_AND_RETURN();
            }
          }
      } else { // reserved dest. address formats
          CONTINUE_RECEIVING_AND_RETURN();
      }

      // PAN ID filtering
      if (m_panID != 0xffff) {
        uint16_t panID = ptr[3] + (ptr[4] << 8); // needed to avoid unaligned access
        if (panID != 0xffff) {
          if (m_panID != panID){
            CONTINUE_RECEIVING_AND_RETURN();
          }
        }
      }
      #endif

      m_rxMsgBufferFree = FALSE;

      lengthFieldPtr = (uint8_t *) m_rxMsgBuffer;
      payloadPtr = ((uint8_t *) m_rxMsgBuffer) + 1;  // first byte holds the length of payload

      payloadLen = m_rxFrame.u8PayloadLength - 2;  // strip checksum bytes
      *lengthFieldPtr = payloadLen;
      memcpy( payloadPtr, m_rxFrame.uPayload.au8Byte, payloadLen);

      post enqueueRxedMsg();

      if (hdr & (1 << IEEE154_FCF_ACK_REQ)) {
        send_ack(m_rxMsgBuffer);
        if (m_ackSending)
          return;  // don't enable the radio receive mode
      }
    }

    vMMAC_StartPhyReceive(&m_rxFrame, E_MMAC_RX_START_NOW);
  }


  // ----- BareSend interface --------------------------

  command error_t BareSend.send(message_t* msg, uint8_t len) {
    uint8_t payload_len = len - 1; // the first byte is length
    uint16_t checksum;
    uint8_t* msgPtr = (uint8_t*) &((call Jn516PacketBody.getHeader(msg))->fcf);

    atomic {
      if (m_waitingForAck) {
        // the previous sending attempt is not finished yet
        return EBUSY;
      }
      if (m_txFrameLock) {
        return EBUSY;
      }
      m_txFrameLock = TRUE;
      m_txMsg = msg;
    }

    memcpy(m_txFrame.uPayload.au8Byte, msgPtr, payload_len);

    #ifdef AUTO_REQ_ACK_EXT
    if ((m_txFrame.uPayload.au8Byte[1] & 0xCC) == 0xCC) {
      m_txFrame.uPayload.au8Byte[0]  |= (1 << IEEE154_FCF_ACK_REQ);
      ((uint8_t *) msg)[1] |= (1 << IEEE154_FCF_ACK_REQ);
    }
    #endif

    checksum = crc16_data((void*) msgPtr, payload_len, 0);
    m_txFrame.uPayload.au8Byte[payload_len] = checksum;
    m_txFrame.uPayload.au8Byte[payload_len+1] = (checksum >> 8) & 0xff;
    m_txFrame.u8PayloadLength = payload_len + 2;

    if ((call Jn516PacketBody.getHeader(msg))->fcf & (1 << IEEE154_FCF_ACK_REQ)) {
      atomic {
        m_expectedDsn = (call Jn516PacketBody.getHeader(msg))->dsn;
        m_waitingForAck = TRUE;
        m_retransmissionCnt = 0;
      }
    }

    vMMAC_StartPhyTransmit(&m_txFrame, E_MMAC_TX_START_NOW | E_MMAC_TX_NO_CCA);
    return SUCCESS;
  }


  // ----- RetranmissionTimer interface ----------------

  async event void RetransmissionAlarms.fired() {
      if (m_waitingForAck == FALSE) // race condition prevention
        return;
      m_retransmissionCnt++;
      if (m_retransmissionCnt < MAX_RETRANSMITS) {
        PRINTF("Retransmit.fired: sending again\n");
        vMMAC_StartPhyTransmit(&m_txFrame, E_MMAC_TX_START_NOW | E_MMAC_TX_NO_CCA);
      } else {
        m_waitingForAck = FALSE;
        vMMAC_StartPhyReceive(&m_rxFrame, E_MMAC_RX_START_NOW);
        post signalSendDoneFail();
      }
  }


  // ----- BareSend interface --------------------------

  command error_t BareSend.cancel(message_t* msg) {
    return FAIL;
  }

  command uint8_t BareSend.maxPayloadLength() {
    return TOSH_DATA_LENGTH + sizeof(jn516_header_t);
  }

  command void* BareSend.getPayload(message_t* msg, uint8_t len) {
    #ifndef TFRAMES_ENABLED
     jn516_header_t *hdr = call Jn516PacketBody.getHeader(msg);
     return hdr;
    #else
     return NULL;
    #endif
  }


  // ----- Ieee154Address interface --------------------

  event void Ieee154Address.changed() {
    atomic {
      m_panID = call Ieee154Address.getPanId();
      m_saddr = call Ieee154Address.getShortAddr();
      m_laddr = call Ieee154Address.getExtAddr();
    }
  }


  // ----- Tasks ---------------------------------------

  task void enqueueRxedMsg() {
    PRINTF("Enqueueing packet to rx queue. \n");
    if (call RxMessagePool.empty()) {
      // nothing left in pool, we have to wait for now
      post enqueueRxedMsg();  // repost to try again later
      return;
    }
    call RxQueue.enqueue(m_rxMsgBuffer);
    atomic {
      m_rxMsgBuffer = call RxMessagePool.get();
      m_rxMsgBufferFree = TRUE;
    }
    post deliverQueuedMsg();
  }


  task void deliverQueuedMsg() {
    message_t* msg;
    uint8_t len;
    atomic {
      if (call RxQueue.size() == 0)
        return;
      msg = call RxQueue.dequeue();
      if (m_rxMsgBufferFree == FALSE) {
        // here we have to check if there is yet another packet waiting
        // that couldn't be enqueued right after reception
        // because there was no entity left in the pool
        call RxQueue.enqueue(m_rxMsgBuffer);
        m_rxMsgBuffer = call RxMessagePool.get();
        m_rxMsgBufferFree = TRUE;
        post deliverQueuedMsg(); // repost ourselves since one task call was left uncalled before
      }
      len = (call Jn516PacketBody.getHeader(msg))->length + 1;  // the length field also belongs to the message given to upper layerss
      PRINTF("Delivering packet to upper layers..\n");
      signal BareReceive.receive(msg, (void*) (call BareSend.getPayload(msg, 0)), len);
      call RxMessagePool.put(msg);
    }
  }


  task void signalSendDone() {
    PRINTF("Signaling senddone to upper layers \n");
    m_txFrameLock = FALSE;
    signal BareSend.sendDone(m_txMsg, SUCCESS);
  }


  task void signalSendDoneFail() {
    PRINTF("Signaling senddone failure to upper layers \n");
    m_txFrameLock = FALSE;
    signal BareSend.sendDone(m_txMsg, FAIL);
  }


  task void startRadio() {
    vMMAC_Enable();
    vMMAC_EnableInterrupts(RadioCallback);
    vMMAC_ConfigureRadio();
    vMMAC_SetChannel(m_channel);
    vMMAC_StartPhyReceive(&m_rxFrame, E_MMAC_RX_START_NOW);
    signal SplitControl.startDone(SUCCESS);
  }


  task void stopRadio() {
    vMMAC_RadioOff();
    signal SplitControl.stopDone(SUCCESS);
  }


  // ---------------------------------------------------

  void send_ack(message_t* msg)  @spontaneous() {
    uint16_t ack_checksum;
    uint32_t now = u32MMAC_GetTime();

    m_txAckFrame.uPayload.au8Byte[0] = IEEE154_TYPE_ACK;
    m_txAckFrame.uPayload.au8Byte[1] = 0;
    m_txAckFrame.uPayload.au8Byte[2] = (call Jn516PacketBody.getHeader(msg))->dsn;

    ack_checksum = crc16_data((void*) m_txAckFrame.uPayload.au8Byte, 3, 0);
    m_txAckFrame.uPayload.au8Byte[3] = (uint8_t) ack_checksum;
    m_txAckFrame.uPayload.au8Byte[4] = (uint8_t) (ack_checksum >> 8);
    m_txAckFrame.u8PayloadLength = 5;

    if (now > (m_recvTime + MAX_ACK_WAIT_DURATION_SYMBOLS - 22)) {
      // took us too long and we cannot send the frame in time to get it received
      // we need to turn on the radio + preamble + the frame itself (22) is an approximation for this
      PRINTF("ACK send pending, but too much time has past. Aborting sending.\n");
      m_ackSending = FALSE;
      return;
    }
    if (now >= (m_recvTime + ACK_DELAY_SYMBOLS -1)) {
      vMMAC_StartPhyTransmit(&m_txAckFrame, E_MMAC_TX_START_NOW | E_MMAC_TX_NO_CCA);
    } else { // send as soon as possible
      vMMAC_SetTxStartTime(m_recvTime + ACK_DELAY_SYMBOLS);
      vMMAC_StartPhyTransmit(&m_txAckFrame, E_MMAC_TX_DELAY_START | E_MMAC_TX_NO_CCA);
    }
    m_ackSending = TRUE;
  }


  // ----- CRC functions --------------------------------
  // The following two function has been taken from Contiki to calculate the packet's
  // CRC in software in order to be able to use the vMMAC_StartPhyTransmit(..), which
  // doesn't set the CRC

  inline unsigned short crc16_add(unsigned char b, unsigned short acc) {
   acc ^= b;
   acc  = (acc >> 8) | (acc << 8);
   acc ^= (acc & 0xff00) << 4;
   acc ^= (acc >> 8) >> 4;
   acc ^= (acc & 0xff00) >> 5;
   return acc;
  }

  unsigned short crc16_data(const unsigned char *data, int len, unsigned short acc) {
   uint8_t i;

   for(i = 0; i < len; ++i) {
    acc = crc16_add(*data, acc);
    ++data;
   }
   return acc;
  }

}
