/*
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
 *
 * @author Tim Bormann <tinyos-code@tkn.tu-berlin.de>
 * @author Sanjeet Raj Pandey <tinyos-code@tkn.tu-berlin.de>
 * @author Sonali Deo <tinyos-code@tkn.tu-berlin.de>
 * @author Jasper Buesch <tinyos-code@tkn.tu-berlin.de>
 * @author Moksha Birk <tinyos-code@tkn.tu-berlin.de>
 */

#include "IEEE802154.h"
#include <Ieee154.h>
#include "Timer.h"
#include "plain154_types.h"
#include "plain154_values.h"
#include "plain154_message_structs.h"
#include "IeeeEui64.h"

// If frames with set ext. dest. address should request an acknowledgment
 #define AUTO_REQ_ACK_EXT TRUE

/*#define ENABLE_PRINTF*/

#ifndef MAX_RETRANSMITS
#define MAX_RETRANSMITS 3
#endif

#define ENABLE_ADDRESS_FILTERING
#define MAX_ACK_WAIT_DURATION_SYMBOLS 54 // = turnaround time (12symbols) + backoff (20symb) + ACK len (5 bytes * 2) + preamble (12symbols)
#define MAX_ACK_WAIT_DURATION_32KHZ (MAX_ACK_WAIT_DURATION_SYMBOLS/2)
#define ACK_DELAY_SYMBOLS 12

#ifndef ENABLE_PRINTF
  #define DBG(...)
  #define DBG_1ARG(fmt, arg1)
#else
  #ifndef NEW_PRINTF_SEMANTICS
    #define NEW_PRINTF_SEMANTICS
  #endif
  #include "printf.h"
  #define DBG(fmt) printf(fmt); printfflush()
  #define DBG_1ARG(fmt, arg1) printf(fmt, arg1); printfflush()
#endif


module TknTschBareP {
  provides {
    interface SplitControl;
    interface Send as BareSend;
    interface Receive as BareReceive;
    interface Packet as BarePacket;
    interface GetSet<uint8_t> as RadioChannel;
  }
  uses {
    interface Ieee154Address;
    interface Plain154Frame;
    interface Packet as Plain154Packet;
    //interface BlipPacketTransform;
    interface Queue<message_t *> as RxQueue;
    interface Pool<message_t> as RxMessagePool;
    //interface Timer<T32khz, uint32_t> as RetransmissionTimer;
    interface TknTschMcpsData as MCPS_DATA;
    interface Plain154PlmeSet;
    interface Plain154PlmeGet;
    interface BlipTschPan;
    interface Plain154PhyOff;
  }
}

implementation {

  // ----- Declarations -------------

  void init();
  unsigned short crc16_data(const unsigned char *data, int len, unsigned short acc);
  inline unsigned short crc16_add(unsigned char b, unsigned short acc);
  void signalDone( error_t err );


  void task deliverQueuedMsg();
  void task signalSendDone();
  void task signalSendDoneFail();
  void task enqueueRxedMsg();

  // --------------------------------

  norace uint8_t m_waitingForConfirmation;
  uint8_t m_expectedDsn;
  uint8_t m_lastDsnRecv;
  uint8_t m_channel;
  norace bool m_rxMsgBufferFree;
  message_t* m_txMsg_ptr;
  message_t m_txMsg;
  message_t* m_rxMsgBuffer;
  norace bool m_txFrameLock;
  norace error_t m_txError;
  norace uint32_t m_recvTime;

  norace ieee154_panid_t m_panID;
  norace ieee154_saddr_t m_saddr;
  norace ieee154_laddr_t m_laddr;

  // ---------------------------------------------------

  void init() {
    atomic {
      m_waitingForConfirmation = FALSE;
      m_channel = call Plain154PlmeGet.phyCurrentChannel();
      call Plain154PlmeSet.phyCurrentChannel(m_channel);
      m_rxMsgBufferFree = TRUE;
      //m_rxMsgBuffer = call RxMessagePool.get();
      m_txFrameLock = FALSE;

      m_panID = call Ieee154Address.getPanId();
      m_saddr = call Ieee154Address.getShortAddr();
      m_laddr = call Ieee154Address.getExtAddr();
    }
  }


  // ---------------------------------------------------

  command error_t SplitControl.start() {
    uint8_t ret;

    init();

#ifdef IS_COORDINATOR
    ret = call BlipTschPan.start();
#else
    ret = call BlipTschPan.join();
#endif

    if (ret == TKNTSCH_SUCCESS) {
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command error_t SplitControl.stop() {
    call BlipTschPan.shutdown();
    return SUCCESS;
  }

  event void BlipTschPan.joinDone(tkntsch_status_t status) {
    signal SplitControl.startDone((status == TKNTSCH_SUCCESS) ? SUCCESS : FAIL);
  }

  event void BlipTschPan.startDone(tkntsch_status_t status) {
    signal SplitControl.startDone((status == TKNTSCH_SUCCESS) ? SUCCESS : FAIL);
  }

  event void BlipTschPan.shutdownDone(tkntsch_status_t status) {
    signal SplitControl.stopDone((status == TKNTSCH_SUCCESS) ? SUCCESS : FAIL);
  }

  async event void Plain154PhyOff.offDone() {}


  command void RadioChannel.set(uint8_t val ) {
    m_channel = val;
    call Plain154PlmeSet.phyCurrentChannel(m_channel);
  }

  command uint8_t RadioChannel.get() {
    return m_channel;
  }


  event void MCPS_DATA.indication(
      message_t* msg,
      uint8_t mpduLinkQuality,
      uint8_t SecurityLevel,
      uint8_t KeyIdMode,
      plain154_sec_keysource_t KeySource,
      uint8_t KeyIndex
    )
  {
    int i;
    plain154_header_t* header;
    header = call Plain154Frame.getHeader(msg);

    DBG_1ARG("Received a DATA frame with DSN %.2X\n", call Plain154Frame.getDSN(header));
/*    for (i = 0; i < sizeof(message_t); i++) {
    DBG_1ARG("%.2X ", ((uint8_t*) msg)[i]);
    }
    DBG("\n");
*/
    if (m_rxMsgBufferFree == FALSE) {
      // there is yet another packet waiting to be enqueued
      DBG("TschBare: Dropping RX frame: The buffer is occupied\n");
      atomic call RxMessagePool.put(msg);
      return;
    }

  #ifdef ENABLE_ADDRESS_FILTERING
    #warning "TknTschBareP uses address filtering"
    // Address filtering
    if (call Plain154Frame.getDstAddrMode(header) == PLAIN154_ADDR_NOT_PRESENT) {
      DBG("TschBare: Dropping RX frame: Filter: no dst addr\n");
      atomic call RxMessagePool.put(msg);
      return;
    }

    if (call Plain154Frame.getFrameType(header) != PLAIN154_FRAMETYPE_DATA) {
      // we are nothing else but data frames at or after this point
      DBG("TschBare: Dropping RX frame: Filter: not a data frame\n");
      atomic call RxMessagePool.put(msg);
      return;
    }


    if (call Plain154Frame.getDstAddrMode(header) == PLAIN154_ADDR_SHORT) {
      // destination address is in short format
      plain154_address_t dst;
      uint16_t sAddr;
      call Plain154Frame.getDstAddr(header,&dst);
      sAddr = dst.shortAddress;
      if ((m_saddr != 0xffff) && (sAddr != 0xffff) && (sAddr != m_saddr)) {
        DBG("TschBare: Dropping RX frame: Filter: short dst addr mismatch\n");
        atomic call RxMessagePool.put(msg);
        return;
      }
    } else if (call Plain154Frame.getDstAddrMode(header) == PLAIN154_ADDR_EXTENDED) {
      // destination address is in extended address format
      plain154_address_t dst;
      ieee_eui64_t eAddr;
      call Plain154Frame.getDstAddr(header,&dst);
      memcpy(eAddr.data, &(dst.extendedAddress), 8);
      for (i = 0; i < 7; i++){
        if (eAddr.data[7-i] != m_laddr.data[i]) {
          DBG("TschBare: Dropping RX frame: Filter: extended dst addr mismatch\n");
          atomic call RxMessagePool.put(msg);
          return;
        }
      }
    } else { // reserved dest. address formats
      DBG("TschBare: Dropping RX frame: Filter: reserved dst addr\n");
      atomic call RxMessagePool.put(msg);
      return;
    }

    // PAN ID filtering
    if (m_panID != 0xffff) {
      uint16_t panID;
      call Plain154Frame.getDstPANId(header, &panID);
      if (panID != 0xffff) {
        if (m_panID != panID){
          DBG("TschBare: Dropping RX frame: Filter: PAN ID mismatch\n");
          atomic call RxMessagePool.put(msg);
          return;
        }
      }
    }
  #endif

    m_rxMsgBufferFree = FALSE;
    m_rxMsgBuffer = msg;

    post enqueueRxedMsg();
  }


  // ----- BareSend interface --------------------------

  command error_t BareSend.send(message_t* msg, uint8_t len) {
    //uint8_t* msg_ptr = (uint8_t *) msg;
    plain154_header_t* header;
    plain154_address_t dstAddr; //, srcAddr;
    uint8_t srcMode = 0, dstMode = 0;
    uint16_t srcPan = 0, dstPan = 0;

    uint8_t *payload, payloadlen;
    uint8_t *from_data;
    //uint16_t u16_tmp;
    uint8_t *tmp, data_index;
    uint8_t handle, ret = 0;
    plain154_header_hints_t hints;

    atomic {
      if (m_txFrameLock) {
        return EBUSY;
      }
      m_txFrameLock = TRUE;
      m_txMsg_ptr = msg;
    }

    from_data = ((uint8_t *) msg) + 1;
    data_index = 0;

    // copy the FCF so the Plain154Frame interface can be used safely
    header = call Plain154Frame.getHeader(&m_txMsg);
    header->fcf1 = from_data[data_index++];
    header->fcf2 = from_data[data_index++];

    ret = call Plain154Frame.getHeaderHints(header, &hints);
    if (ret != SUCCESS) return FAIL;

    // use BLIPs DSN as the handle for now
    if (hints.hasDsn == TRUE) {
      handle = from_data[data_index++];
    }
    else {
      data_index++;
      handle = 0;
    }

    // copy destination PAN ID if existant
    if (hints.hasDstPanId == TRUE) {
      dstPan = from_data[data_index] | (from_data[data_index+1] << 8);
      data_index += 2;
    }
    if (hints.hasDstAddr == TRUE) {
      dstMode = call Plain154Frame.getDstAddrMode(header);
      tmp = (uint8_t *) &dstAddr;
      if (dstMode == PLAIN154_ADDR_SHORT) {
        dstAddr.shortAddress = from_data[data_index] | (from_data[data_index+1] << 8);
        data_index += 2;
      } else if (dstMode == PLAIN154_ADDR_EXTENDED) {
        // NOTE reading from a little-endian byte stream and writing manually
        //      into a big-endian variable (on Jennic!)
        tmp[7] = from_data[data_index + 0];
        tmp[6] = from_data[data_index + 1];
        tmp[5] = from_data[data_index + 2];
        tmp[4] = from_data[data_index + 3];
        tmp[3] = from_data[data_index + 4];
        tmp[2] = from_data[data_index + 5];
        tmp[1] = from_data[data_index + 6];
        tmp[0] = from_data[data_index + 7];
        data_index += 8;
      } else {
        return FAIL;
      }
    }
    if (hints.hasSrcPanId == TRUE) {
      srcPan = from_data[data_index] | (from_data[data_index+1] << 8);
      data_index += 2;
    }
    // TODO the MCPS-DATA interface doesn't allow to pass the src address but data_index has to be adjusted
    if (hints.hasSrcAddr == TRUE) {
      srcMode = call Plain154Frame.getSrcAddrMode(header);
      //tmp = (uint8_t *) &srcAddr;
      if (srcMode == PLAIN154_ADDR_SHORT) {
        //srcAddr.shortAddress = from_data[data_index] | (from_data[data_index+1] << 8);
        data_index += 2;
      } else if (srcMode == PLAIN154_ADDR_EXTENDED) {
        //memcpy(tmp, &from_data[data_index], 8);
        data_index += 8;
      } else {
        return FAIL;
      }
    }

    // move any header IEs
    if (call Plain154Frame.isIEListPresent(header)) {
      DBG("[WARNING] BLIP is sending a frame with IEs...\n");
    }

    // copy payload
    payloadlen = ((uint8_t *) msg)[0] - data_index - 2; // two bytes CRC
    payload = call Plain154Packet.getPayload(&m_txMsg, payloadlen);
    if (payload == NULL) {
      DBG("Could not allocate enough payload space!\n");
    }
    memcpy(payload, &from_data[data_index], payloadlen);

    call Plain154Packet.setPayloadLength(&m_txMsg, payloadlen);

#ifdef AUTO_REQ_ACK_EXT
    //if ((from_data[1] & 0xCC) == 0xCC) {
    //  call Plain154Frame.setAckRequested(header);
    //}

    // don't send ACK request when doing a broadcast
    if (hints.hasDstAddr == TRUE) {
      if (dstMode == PLAIN154_ADDR_SHORT) {
        if (dstAddr.shortAddress == 0xffff) {
          call Plain154Frame.setAckRequest(header, FALSE);
        }
        else {
          call Plain154Frame.setAckRequest(header, TRUE);
        }
      }
      else {
        call Plain154Frame.setAckRequest(header, TRUE);
      }
    }
#endif

    ret = call MCPS_DATA.request (
        srcMode,
        dstMode,
        dstPan, // pan id
        &dstAddr,
        &m_txMsg,
        handle, // handle
        call Plain154Frame.isAckRequested(header), // ACK?
        0, 0, 0, 0 // security...
      );
    if (ret == TKNTSCH_SUCCESS) return SUCCESS;
    else return FAIL;
  }

  event void MCPS_DATA.confirm(
      uint8_t msduHandle,
      plain154_status_t status
    )
  {
    if (status != PLAIN154_SUCCESS) {
      post signalSendDoneFail();
    }
    else {
      post signalSendDone();
    }
  }

  command error_t BareSend.cancel(message_t* msg) {
    return FAIL;
  }

  command uint8_t BareSend.maxPayloadLength() {
    return call BarePacket.maxPayloadLength();
  }

  command void* BareSend.getPayload(message_t* msg, uint8_t len) {
    return call BarePacket.getPayload(msg, len);
  }

  // ----- BarePacket interface --------------------

  enum {
    // size of the footer (FCS field)
    MAC_FOOTER_SIZE = sizeof( uint16_t ),
  };

  command void BarePacket.clear(message_t *msg) {
    memset(msg, 0, sizeof(message_t));
  }

  command uint8_t BarePacket.payloadLength(message_t *msg) {
    // retrieve the length byte of a BLIP message
    uint8_t phy_hdr = ((uint8_t*)msg)[0];
    return phy_hdr + 1 - MAC_FOOTER_SIZE; //== PHR+MHR+MSDU
  }

  command void BarePacket.setPayloadLength(message_t* msg, uint8_t len) {
    uint8_t* phy_hdr = (uint8_t*)msg;
    *phy_hdr = len - 1 + MAC_FOOTER_SIZE; //== MHR+MSDU+MFT
  }

  command uint8_t BarePacket.maxPayloadLength() {
    return sizeof(message_header_t) + TOSH_DATA_LENGTH - MAC_FOOTER_SIZE;
  }

  command void* BarePacket.getPayload(message_t* msg, uint8_t len) {
    return (void*)msg;
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
    DBG("Enqueueing packet to rx queue.");
    if (call RxMessagePool.empty()) {
      // nothing left in pool, we have to wait for now
      post enqueueRxedMsg();  // repost to try again later
      DBG(".");
      return;
    }
    atomic {
      call RxQueue.enqueue(m_rxMsgBuffer);
      //m_rxMsgBuffer = call RxMessagePool.get();
      m_rxMsgBufferFree = TRUE;
    }
    DBG("\n");
    post deliverQueuedMsg();
  }


  task void deliverQueuedMsg() {
    message_t* msg, *ret_msg;
    uint8_t tmp_msg[sizeof(message_t)], *ptmp_msg = &tmp_msg[0];
    uint8_t payloadlen, *payload;

    plain154_header_t *header;
    uint8_t *from_payload;
    uint8_t u8_tmp, *ptr, data_index, hdrlen;
    uint16_t u16_tmp;
    uint16_t checksum;
    uint8_t* to_phdr = ptmp_msg;

    atomic {
      if (call RxQueue.size() == 0)
        return;

      msg = call RxQueue.dequeue();
      if (m_rxMsgBufferFree == FALSE) {
        // here we have to check if there is yet another packet waiting
        // that couldn't be enqueued right after reception
        // because there was no entity left in the pool
        call RxQueue.enqueue(m_rxMsgBuffer);
        ////m_rxMsgBuffer = call RxMessagePool.get();
        m_rxMsgBufferFree = TRUE;
        post deliverQueuedMsg(); // repost ourselves since one task call was left uncalled before
      }
    }

    // transform the message to the format BLIP expects
    data_index = 0;
    ptr = ptmp_msg + 1;
    header = call Plain154Frame.getHeader(msg);
    from_payload = call Plain154Packet.getPayload(msg, 0);
    payloadlen = header->payloadlen;

    if(call Plain154Frame.getActualHeaderLength(header, &hdrlen) != SUCCESS) {
      DBG("TknTschBare: Parsing error, dropping frame!\n");
      atomic call RxMessagePool.put(msg);
      return;
    }

    *to_phdr = hdrlen + payloadlen + 2;  // plus 2 byte CRC
    // copy FCF and DSN
    ptr[data_index++] = header->fcf1;
    ptr[data_index++] = header->fcf2;
    ptr[data_index++] = header->dsn;

    // copy destination PAN ID
    if (call Plain154Frame.getDstPANId(header, &u16_tmp) == SUCCESS) {
      ptr[data_index] = (uint8_t) u16_tmp;
      ptr[data_index+1] = (uint8_t) (u16_tmp >> 8);
      data_index += 2;
    }

    // copy destination address
    u8_tmp = call Plain154Frame.getDstAddrMode(header);
    if (u8_tmp > PLAIN154_ADDR_NOT_PRESENT) {
      uint8_t *t;
      t = (uint8_t *) &(header->dest.short_addr);
      if (u8_tmp == PLAIN154_ADDR_SHORT) {
        ptr[data_index] = t[0];
        ptr[data_index+1] = t[1];
        data_index += 2;
      } else if (u8_tmp == PLAIN154_ADDR_EXTENDED) {
        memcpy(&ptr[data_index], t, 8);
        data_index += 8;
      } else {
        DBG("TknTschBare: Parsing error, dropping frame!\n");
        atomic call RxMessagePool.put(msg);
        return;
      }
    }

    // copy source PAN ID
    if (call Plain154Frame.getSrcPANId(header, &u16_tmp) == SUCCESS) {
      ptr[data_index] = (uint8_t) u16_tmp;
      ptr[data_index+1] = (uint8_t) (u16_tmp >> 8);
      data_index += 2;
    }

    // copy source address
    u8_tmp = call Plain154Frame.getSrcAddrMode(header);
    if (u8_tmp > PLAIN154_ADDR_NOT_PRESENT) {
      uint8_t *t;
      t = (uint8_t *) &(header->src.short_addr);
      if (u8_tmp == PLAIN154_ADDR_SHORT) {
        ptr[data_index] = t[0];
        ptr[data_index+1] = t[1];
        data_index += 2;
      } else if (u8_tmp == PLAIN154_ADDR_EXTENDED) {
        memcpy(&ptr[data_index], t, 8);
        data_index += 8;
      } else {
        DBG("TknTschBare: Parsing error, dropping frame!\n");
        atomic call RxMessagePool.put(msg);
        return;
      }
    }

    // copy payload
    memcpy(&ptr[data_index], from_payload, payloadlen);
    data_index += payloadlen;

    // set the FCS
    checksum = crc16_data((void*) ptr, *to_phdr-2, 0);
    ptr[data_index] = checksum;
    ptr[data_index+1] = (checksum >> 8) & 0xff;
    data_index += 2;

    // copy the transformed frame back to the given buffer
    memcpy((uint8_t*)msg, ptmp_msg, sizeof(message_t));

    //DBG("Delivering packet to upper layers...\n");
    payloadlen = call BarePacket.payloadLength(msg);
    payload = call BarePacket.getPayload(msg, 0);
    ret_msg = signal BareReceive.receive(msg,
        (void*) payload,
        payloadlen
      );

    atomic call RxMessagePool.put(ret_msg);
  }


  task void signalSendDone() {
    m_txFrameLock = FALSE;
    signal BareSend.sendDone(m_txMsg_ptr, SUCCESS);
  }


  task void signalSendDoneFail() {
    m_txFrameLock = FALSE;
    signal BareSend.sendDone(m_txMsg_ptr, FAIL);
  }


  // ----- CRC functions --------------------------------
  // The following two functions have been taken from Contiki to calculate the packet's
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

    for (i = 0; i < len; ++i) {
      acc = crc16_add(*data, acc);
      ++data;
    }
    return acc;
  }

}
