/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */

/*
 * @author Henri Dubois-Ferriere
 *
 */
module XE1205SendReceiveP {
    provides interface Send;
    provides interface Packet;
    provides interface PacketAcknowledgements;
    provides interface Receive;
    provides interface SplitControl @atleastonce();;

    uses interface XE1205PhyRxTx;
    uses interface SplitControl as PhySplitControl;
}
implementation {

  #include "crc.h"
  #include "xe1205debug.h"

#define min(X, Y)  ((X) < (Y) ? (X) : (Y))

  // Phy header definition. This is not seen by anything above us.
  typedef nx_struct xe1205_phy_header_t {
    nx_uint8_t whitening;
    nx_uint8_t length;
  } xe1205_phy_header_t;
  
  xe1205_phy_header_t txPhyHdr;
  norace xe1205_phy_header_t rxPhyHdr; // we don't accept an incoming packet until previous one has been copied into local buf

  norace message_t *txMsgPtr=NULL;   // message under transmission (non-null until after sendDone).
  norace char txBuf[16];             // buffer used to pass outgoing bytes to Phy

  norace uint8_t *rxBufPtr=NULL;     // pointer to raw frame received from Phy
  message_t rxMsg;                   // for rx path buffer swapping with upper modules
  message_t *rxMsgPtr=&rxMsg; 

  norace uint8_t txIndex, txLen;     // State for packet transmissions
  norace uint16_t txRunningCRC;      // Crc for outgoing pkts is computed incrementally

  norace uint8_t txWhiteByte;

  uint8_t const pktPreamble[] = {
    0x55, 0x55, 0x55,
    (data_pattern >> 16) & 0xff, (data_pattern >> 8) & 0xff, data_pattern & 0xff
  };


  xe1205_header_t* getHeader( message_t* msg ) {
    return (xe1205_header_t*)( msg->data - sizeof(xe1205_header_t) );
  }

  xe1205_footer_t* getFooter(message_t* msg) {
    return (xe1205_footer_t*)(msg->footer);
  }
  
  xe1205_metadata_t* getMetadata(message_t* msg) {
    return (xe1205_metadata_t*)((uint8_t*)msg->footer + sizeof(xe1205_footer_t));
  }
  

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* m) {
    return call Packet.getPayload(m, NULL);
  }

  command void* Receive.getPayload(message_t* m, uint8_t* len) {
    return call Packet.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength(message_t* m) {
    return call Packet.payloadLength(m);
  }


  command error_t SplitControl.start() {
    error_t err;
    err = call PhySplitControl.start();

    return err;
  }

  command error_t SplitControl.stop() {
    error_t err;

    // One could also argue that this is split phase so should cope and do the right thing.
    // Or one could argue that whatever the phy is doing underneath just gets interrupted.
    if (call XE1205PhyRxTx.busy()) return EBUSY;

    err = call PhySplitControl.stop();

    return err;

  }

  event void PhySplitControl.startDone(error_t error) {
    signal SplitControl.startDone(error);
  }

  event void PhySplitControl.stopDone(error_t error) { 
    signal SplitControl.stopDone(error);
  }



  command error_t Send.cancel(message_t* msg) {
    /* Cancel is unsupported for now. */
    return FAIL;
  }

  void checkCrcAndUnwhiten(uint8_t* msg, uint8_t white, uint8_t len) {
    uint16_t crc = 0;
    uint8_t i, b;
    uint8_t* uwPtr = (uint8_t*) getHeader(rxMsgPtr);
    for(i = 0; i < sizeof(xe1205_header_t) + len; i++) {
      b = msg[i] ^ white;
      uwPtr[i] = b;
      crc = crcByte(crc, b);
    }
    getFooter(rxMsgPtr)->crc = (crc == (msg[i] | (msg[i+1] << 8)));
  }

  void updateCRCAndWhiten(char* src, char* dst, uint8_t len)
  {
    uint8_t i;
    for(i=0; i < len; i++) {
      txRunningCRC = crcByte(txRunningCRC, src[i]); 
      dst[i] = src[i] ^ txWhiteByte;
    }
  }


  command error_t Send.send(message_t* msg, uint8_t len) {
    error_t err;

    if (txMsgPtr) return EBUSY;

    if (call XE1205PhyRxTx.busy()) return EBUSY;
    if (call XE1205PhyRxTx.off()) return EOFF;


    txWhiteByte++;
    txPhyHdr.whitening = txWhiteByte;
    txPhyHdr.length = len;
    txRunningCRC=0;
    getMetadata(msg)->length = len; 

    txIndex = min(sizeof(xe1205_header_t) + len + sizeof(xe1205_footer_t), 
	    sizeof(txBuf) - sizeof(pktPreamble) - sizeof(xe1205_phy_header_t));
    txLen = len + sizeof(xe1205_header_t) + sizeof(xe1205_footer_t);
    if (txIndex == txLen - 1) txIndex--; // don't send a single last byte

    memcpy(txBuf, pktPreamble, sizeof(pktPreamble));
    memcpy(txBuf + sizeof(pktPreamble), &txPhyHdr, sizeof(txPhyHdr));
    
    if (txIndex == txLen) {    // slap on CRC if we're already at end of packet
      updateCRCAndWhiten((char*) getHeader(msg), 
			 txBuf + sizeof(pktPreamble) + sizeof(xe1205_phy_header_t),
			 sizeof(xe1205_header_t) + len); 
      txBuf[sizeof(pktPreamble) + sizeof(xe1205_phy_header_t) + txLen - 2] = txRunningCRC & 0xff; 
      txBuf[sizeof(pktPreamble) + sizeof(xe1205_phy_header_t) + txLen - 1] = txRunningCRC >> 8; 
    } else {
      updateCRCAndWhiten((char*) getHeader(msg), 
			 txBuf + sizeof(pktPreamble) + sizeof(xe1205_phy_header_t),
			 txIndex);
    }
    
    
    txMsgPtr = msg;

    // note that the continue send can come in before this instruction returns .
    err = call XE1205PhyRxTx.sendFrame(txBuf, txIndex + sizeof(pktPreamble) + sizeof(xe1205_phy_header_t));
    if (err != SUCCESS) txMsgPtr = NULL; 
    
    return err;
  }


  task void sendDoneTask() {
    signal Send.sendDone(txMsgPtr, SUCCESS);
    txMsgPtr = NULL;
  }

 

  async event char* XE1205PhyRxTx.continueSend(uint8_t* len) __attribute__ ((noinline))
  {
    uint8_t curIndex = txIndex;
    uint8_t l = min(txLen - txIndex, sizeof(txBuf));
    if (txIndex + l == txLen - 1) l--; // don't send a single last byte

    *len = l;
    if (!l) return NULL;

    txIndex += l;

    // if we're at end of packet, slap on CRC
    if (txIndex == txLen) {
      updateCRCAndWhiten(&((char*) (getHeader(txMsgPtr)))[curIndex], txBuf, l - 2);
      txBuf[l - 2] = txRunningCRC & 0xff; 
      txBuf[l - 1] = txRunningCRC >> 8; 
    } else {
      updateCRCAndWhiten(((char*) getHeader(txMsgPtr)) + curIndex, txBuf, l);
    }
    

    return txBuf;
  }


  uint8_t sendDones = 0;
  async event void XE1205PhyRxTx.sendFrameDone() __attribute__ ((noinline)) {
    sendDones++;
    if (post sendDoneTask() != SUCCESS)
      xe1205check(2, FAIL);
  }

  command void Packet.clear(message_t* msg) {
    memset(msg, 0, sizeof(message_t));
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return getMetadata(msg)->length;
  }
 
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    getMetadata(msg)->length  = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    if (len != NULL) {
      *len = getMetadata(msg)->length;
    }
    return (void*)msg->data;
  }

  async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
    xe1205_metadata_t* md = getMetadata(msg); // xxx this should move to header or footer, leaving it here for now for 1.x compat
    md->ack = 1;                              
    return SUCCESS;
  }

  async command error_t PacketAcknowledgements.noAck(message_t* msg) {
    xe1205_metadata_t* md = getMetadata(msg);
    md->ack = 1;
    return SUCCESS;
  }

  async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
    xe1205_metadata_t* md = getMetadata(msg);
    return md->ack;
  }

  default event void Send.sendDone(message_t* msg, error_t error) { }

  async event uint8_t XE1205PhyRxTx.rxFrameBegin(char* data, uint8_t len)  __attribute__ ((noinline)) {

    uint8_t datalen;

    memcpy(&rxPhyHdr, data, sizeof(xe1205_phy_header_t));
    datalen = rxPhyHdr.length;
    if (datalen > TOSH_DATA_LENGTH || rxBufPtr) return len;
    
    return datalen + sizeof(xe1205_header_t) + sizeof(xe1205_footer_t) + sizeof(xe1205_phy_header_t);
  }

  task void signalPacketReceived()   __attribute__ ((noinline)) {

    checkCrcAndUnwhiten(rxBufPtr, rxPhyHdr.whitening, rxPhyHdr.length);
    if (!getFooter(rxMsgPtr)->crc) {
      atomic rxBufPtr = NULL;
      return;
    }
    getMetadata((message_t*) rxMsgPtr)->length = rxPhyHdr.length;

    atomic rxBufPtr = NULL;
    rxMsgPtr =  signal Receive.receive(rxMsgPtr, rxMsgPtr->data, getMetadata(rxMsgPtr)->length);
  }


  uint32_t nrxmsgs;
  async event void XE1205PhyRxTx.rxFrameEnd(char* data, uint8_t len, error_t status)   __attribute__ ((noinline)) {
    if (status != SUCCESS) return;
    //    nrxmsgs++;
    if (rxBufPtr) return; // this could happen whenever rxFrameBegin was called with rxBufPtr still active
    rxBufPtr = (data + sizeof(xe1205_phy_header_t));
    xe1205check(1, post signalPacketReceived());
  }

}

