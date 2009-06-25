/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#include "message.h"
#include "crc.h"
#include "CC1000Const.h"
#include "Timer.h"
#include "CC1000TimeSyncMessage.h"

/**
 * A rewrite of the low-power-listening CC1000 radio stack.
 * This file contains the send and receive logic for the CC1000 radio.
 * It does not do any media-access control. It requests the channel
 * via the ready-to-send event (rts) and starts transmission on reception
 * of the clear-to-send command (cts). It listens for packets if the
 * listen() command is called, and stops listening when off() is called.
 * <p>
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces which must be provided
 * by the platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 * @author Marco Langerwisch (Packet timestamping)
 */
  
module CC1000SendReceiveP @safe() {
  provides {
    interface Init;
    interface StdControl;
    interface Send;
    interface Receive;
    interface Packet;
    interface ByteRadio;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
  }
  uses {
    //interface PowerManagement;
    interface CC1000Control;
    interface HplCC1000Spi;
    interface CC1000Squelch;
    interface ReadNow<uint16_t> as RssiRx;
    async command am_addr_t amAddress();

    interface LocalTime<T32khz> as LocalTime32khz;
    interface LocalTime<TMilli> as LocalTimeMilli;
  }
}
implementation 
{
#ifdef PLATFORM_MICA2
  // estimated calibration, 19.2 Kbps data, Manchester Encoding, time in jiffies (32768 Hz)
  static const int8_t BIT_CORRECTION[8] = { 27, 28, 30, 32, 34, 36, 38, 40 };
#else
  // other platforms not calibrated yet
  static const uint8_t BIT_CORRECTION[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
#endif

  enum {
    OFF_STATE,

    INACTIVE_STATE,		/* Not listening, but will accept sends */

    LISTEN_STATE,		/* Listening for packets */

    /* Reception states */
    SYNC_STATE,
    RX_STATE,
    RECEIVED_STATE,
    SENDING_ACK,

    /* Transmission states */
    TXPREAMBLE_STATE,
    TXSYNC_STATE,
    TXDATA_STATE,
    TXCRC_STATE,
    TXFLUSH_STATE,
    TXWAITFORACK_STATE,
    TXREADACK_STATE,
    TXDONE_STATE,
  };

  enum {
    SYNC_BYTE1 =	0x33,
    SYNC_BYTE2 =	0xcc,
    SYNC_WORD =		SYNC_BYTE1 << 8 | SYNC_BYTE2,
    ACK_BYTE1 =		0xba,
    ACK_BYTE2 =		0x83,
    ACK_WORD = 		ACK_BYTE1 << 8 | ACK_BYTE2,
    ACK_LENGTH =	16,
    MAX_ACK_WAIT =	18
  };

  uint8_t radioState;
  struct {
    uint8_t ack : 1; 		/* acks enabled? */
    uint8_t txBusy : 1;		/* send pending? */
    uint8_t invert : 1;		/* data inverted? (see cc1000 datasheet) */
    uint8_t rxBitOffset : 3;	/* bit-offset of received bytes */
  } f; // f for flags
  uint16_t count;
  uint16_t runningCrc;

  uint16_t rxShiftBuf;
  message_t rxBuf;
  message_t * ONE rxBufPtr = &rxBuf;

  uint16_t preambleLength;
  message_t * ONE_NOK txBufPtr;
  uint8_t nextTxByte;

  const_uint8_t ackCode[5] = { 0xab, ACK_BYTE1, ACK_BYTE2, 0xaa, 0xaa };

  /* Packet structure accessor functions. Note that everything is
   * relative to the data field. */
  cc1000_header_t * ONE getHeader(message_t * ONE amsg) {
    return TCAST(cc1000_header_t * ONE, (uint8_t *)amsg + offsetof(message_t, data) - sizeof(cc1000_header_t));
  }

  cc1000_footer_t *getFooter(message_t * ONE amsg) {
    return (cc1000_footer_t *)(amsg->footer);
  }
  
  cc1000_metadata_t * ONE getMetadata(message_t * ONE amsg) {
    return TCAST(cc1000_metadata_t * ONE, (uint8_t *)amsg + offsetof(message_t, footer) + sizeof(cc1000_footer_t));
  }
  
  /* State transition functions */
  /*----------------------------*/

  void enterOffState() {
    radioState = OFF_STATE;
  }

  void enterInactiveState() {
    radioState = INACTIVE_STATE;
  }

  void enterListenState() {
    radioState = LISTEN_STATE;
    count = 0;
  }

  void enterSyncState() {
    radioState = SYNC_STATE;
    count = 0;
    rxShiftBuf = 0;
  }

  void enterRxState() {
    cc1000_header_t *header = getHeader(rxBufPtr);
    radioState = RX_STATE;
    header->length = sizeof rxBufPtr->data;
    count = sizeof(message_header_t) - sizeof(cc1000_header_t);
    runningCrc = 0;
  }

  void enterReceivedState() {
    radioState = RECEIVED_STATE;
  }

  void enterAckState() {
    radioState = SENDING_ACK;
    count = 0;
  }

  void enterTxPreambleState() {
    radioState = TXPREAMBLE_STATE;
    count = 0;
    runningCrc = 0;
    nextTxByte = 0xaa;
  }

  void enterTxSyncState() {
    radioState = TXSYNC_STATE;
  }

  void enterTxDataState() {
    radioState = TXDATA_STATE;
    // The count increment happens before the first byte is read from the
    // packet, so we subtract one from the real packet start point to
    // compensate.
    count = (sizeof(message_header_t) - sizeof(cc1000_header_t)) -1; 
  }

  void enterTxCrcState() {
    radioState = TXCRC_STATE;
  }
    
  void enterTxFlushState() {
    radioState = TXFLUSH_STATE;
    count = 0;
  }
    
  void enterTxWaitForAckState() {
    radioState = TXWAITFORACK_STATE;
    count = 0;
  }
    
  void enterTxReadAckState() {
    radioState = TXREADACK_STATE;
    rxShiftBuf = 0;
    count = 0;
  }
    
  void enterTxDoneState() {
    radioState = TXDONE_STATE;
  }

  command error_t Init.init() {
    f.ack = TRUE; /* We always ack, for now at least */
    call HplCC1000Spi.initSlave();
    return SUCCESS;
  }

  command error_t StdControl.start() {
    atomic 
      {
	enterInactiveState();
	f.txBusy = FALSE;
	f.invert = call CC1000Control.getLOStatus();
      }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic enterOffState();
    return SUCCESS;
  }

  /* Send side. Outside requests, SPI handlers for each state */
  /*----------------------------------------------------------*/

  command error_t Send.send(message_t *msg, uint8_t len) {
    atomic
      {
	if (f.txBusy || radioState == OFF_STATE)
	  return FAIL;
	else {
	  cc1000_header_t *header = getHeader(msg);
          cc1000_metadata_t *metadata = getMetadata(msg);

	  f.txBusy = TRUE;
	  header->length = len;
	  txBufPtr = msg;

          metadata->timesync = FALSE;
          metadata->timestamp = CC1000_INVALID_TIMESTAMP;
	}
      }
    signal ByteRadio.rts(msg);

    return SUCCESS;
  }

  async command void ByteRadio.cts() {
    /* We're set to go! Start with our exciting preamble... */
    enterTxPreambleState();
    call HplCC1000Spi.writeByte(0xaa);
    call CC1000Control.txMode();
    call HplCC1000Spi.txMode();
  }

  command error_t Send.cancel(message_t *msg) {
    /* We simply ignore cancellations. */
    return FAIL;
  }

  void sendNextByte() {
    call HplCC1000Spi.writeByte(nextTxByte);
    count++;
  }

  void txPreamble() {
    sendNextByte();
    if (count >= preambleLength)
      {
	nextTxByte = SYNC_BYTE1;
	enterTxSyncState();
      }
  }

  void txSync() {
    sendNextByte();
    nextTxByte = SYNC_BYTE2;
    enterTxDataState();
  }

  void txData() {
    cc1000_header_t *txHeader = getHeader(txBufPtr);
    sendNextByte();

    if (nextTxByte == SYNC_BYTE2) {
      // SYNC_WORD has just been sent
      uint32_t time32khz = call LocalTime32khz.get();
      call PacketTimeStamp32khz.set(txBufPtr, time32khz);

      if (call PacketTimeSyncOffset.isSet(txBufPtr)) {
        timesync_radio_t *timesync = (timesync_radio_t*)((void*)txBufPtr + call PacketTimeSyncOffset.get(txBufPtr));
        // set timesync event time as the offset between the event time and the SFD interrupt time (TEP 133)
        *timesync  -= time32khz;
      }
    }
    
    if (count < txHeader->length + sizeof(message_header_t))
      {
	nextTxByte = ((uint8_t *)txBufPtr)[count];
	runningCrc = crcByte(runningCrc, nextTxByte);
      }
    else
      {
	nextTxByte = runningCrc;
	enterTxCrcState();
      }
  }

  void txCrc() {
    sendNextByte();
    nextTxByte = runningCrc >> 8;
    enterTxFlushState();
  }

  void txFlush() {
    sendNextByte();
    if (count > 3)
      if (f.ack)
	enterTxWaitForAckState();
      else
	{
	  call HplCC1000Spi.rxMode();
	  call CC1000Control.rxMode();
	  enterTxDoneState();
	}
  }

  void txWaitForAck() {
    sendNextByte();
    if (count == 1)
      {
	call HplCC1000Spi.rxMode();
	call CC1000Control.rxMode();
      }
    else if (count > 3)
      enterTxReadAckState();
  }

  void txReadAck(uint8_t in) {
    uint8_t i;

    sendNextByte();

    for (i = 0; i < 8; i ++)
      {
	rxShiftBuf <<= 1;
	if (in & 0x80)
	  rxShiftBuf |=  0x1;
	in <<= 1;

	if (rxShiftBuf == ACK_WORD)
	  {
	    getMetadata(txBufPtr)->metadataBits |= CC1000_ACK_BIT;
	    enterTxDoneState();
	    return;
	  }
      }
    if (count >= MAX_ACK_WAIT)
      {
	getMetadata(txBufPtr)->metadataBits &= ~CC1000_ACK_BIT;
	enterTxDoneState();
      }
  }

  task void signalPacketSent() {
    message_t *pBuf;

    atomic
      {
	pBuf = txBufPtr;
	f.txBusy = FALSE;
	enterListenState();
      }
    signal Send.sendDone(pBuf, SUCCESS);
  }

  void txDone() {
    post signalPacketSent();
    signal ByteRadio.sendDone();
  }

  /* Receive */
  /*---------*/

  void packetReceived();
  void packetReceiveDone();

  async command void ByteRadio.listen() {
    enterListenState();
    call CC1000Control.rxMode();
    call HplCC1000Spi.rxMode();
    call HplCC1000Spi.enableIntr();
  }

  async command void ByteRadio.off() {
    enterInactiveState();
    call HplCC1000Spi.disableIntr();
  }

  void listenData(uint8_t in) {
    bool preamble = in == 0xaa || in == 0x55;

    // Look for enough preamble bytes
    if (preamble)
      {
	count++;
	if (count > CC1K_ValidPrecursor)
	  enterSyncState();
      }
    else
      count = 0;

    signal ByteRadio.idleByte(preamble);
  }

  void syncData(uint8_t in) {
    // draw in the preamble bytes and look for a sync byte
    // save the data in a short with last byte received as msbyte
    //    and current byte received as the lsbyte.
    // use a bit shift compare to find the byte boundary for the sync byte
    // retain the shift value and use it to collect all of the packet data
    // check for data inversion, and restore proper polarity 
    // XXX-PB: Don't do this.

    if (in == 0xaa || in == 0x55)
      // It is actually possible to have the LAST BIT of the incoming
      // data be part of the Sync Byte.  SO, we need to store that
      // However, the next byte should definitely not have this pattern.
      // XXX-PB: Do we need to check for excessive preamble?
      rxShiftBuf = in << 8;
    else if (count++ == 0)
      rxShiftBuf |= in;
    else if (count <= 6)
      {
	// TODO: Modify to be tolerant of bad bits in the preamble...
        uint32_t time;
	uint16_t tmp;
	uint8_t i;

        time = call LocalTime32khz.get();

	// bit shift the data in with previous sample to find sync
	tmp = rxShiftBuf;
	rxShiftBuf = rxShiftBuf << 8 | in;

	for(i = 0; i < 8; i++)
	  {
	    tmp <<= 1;
	    if (in & 0x80)
	      tmp  |=  0x1;
	    in <<= 1;
	    // check for sync bytes
	    if (tmp == SYNC_WORD)
	      {
		enterRxState();
		signal ByteRadio.rx();
		f.rxBitOffset = 7 - i;
                // correct receive time according to bit offset and set timestamp
                time -= BIT_CORRECTION[f.rxBitOffset];
                call PacketTimeStamp32khz.set(rxBufPtr, time);

		call RssiRx.read();
	      }
	  }
      }
    else // We didn't find it after a reasonable number of tries, so....
      enterListenState();
  }
  
  async event void RssiRx.readDone(error_t result, uint16_t data) {
    cc1000_metadata_t *rxMetadata = getMetadata(rxBufPtr);

    if (result != SUCCESS)
      rxMetadata->strength_or_preamble = 0;
    else
      rxMetadata->strength_or_preamble = data;
  }

  void rxData(uint8_t in) {
    uint8_t nextByte;
    cc1000_header_t *rxHeader = getHeader(rxBufPtr);
    uint8_t rxLength = rxHeader->length;

    // Reject invalid length packets
    if (rxLength > TOSH_DATA_LENGTH)
      {
	// The packet's screwed up, so just dump it
	enterListenState();
	signal ByteRadio.rxDone();
	return;
      }

    rxShiftBuf = rxShiftBuf << 8 | in;
    nextByte = rxShiftBuf >> f.rxBitOffset;
    ((uint8_t *COUNT(sizeof(message_t)))rxBufPtr)[count++] = nextByte;

    // Adjust rxLength to correspond to the corresponding offset in message_t
    rxLength += offsetof(message_t, data);
    if (count <= rxLength)
      runningCrc = crcByte(runningCrc, nextByte);

    // Jump to CRC when we reach the end of data
    if (count == rxLength) {
      count = offsetof(message_t, footer) + offsetof(cc1000_footer_t, crc);
    }

    if (count == (offsetof(message_t, footer) + sizeof(cc1000_footer_t)))
      packetReceived();
  }

  void packetReceived() {
    cc1000_footer_t *rxFooter = getFooter(rxBufPtr);
    cc1000_header_t *rxHeader = getHeader(rxBufPtr);
    // Packet filtering based on bad CRC's is done at higher layers.
    // So sayeth the TOS weenies.
    rxFooter->crc = (rxFooter->crc == runningCrc);

    if (f.ack &&
	rxFooter->crc &&
	rxHeader->dest == call amAddress())
      {
	enterAckState();
	call CC1000Control.txMode();
	call HplCC1000Spi.txMode();
	call HplCC1000Spi.writeByte(0xaa);
      }
    else
      packetReceiveDone();
  }

  void ackData(uint8_t in) {
    if (++count >= ACK_LENGTH)
      { 
	call CC1000Control.rxMode();
	call HplCC1000Spi.rxMode();
	packetReceiveDone();
      }
    else if (count >= ACK_LENGTH - sizeof ackCode)
      call HplCC1000Spi.writeByte(read_uint8_t(&ackCode[count + sizeof ackCode - ACK_LENGTH]));
  }

  task void signalPacketReceived() {
    message_t *pBuf;
    cc1000_header_t *pHeader;
    atomic
      {
	if (radioState != RECEIVED_STATE)
	  return;

	pBuf = rxBufPtr;
      }
    pHeader = getHeader(pBuf);
    pBuf = signal Receive.receive(pBuf, pBuf->data, pHeader->length);
    atomic
      {
	if (pBuf) 
	  rxBufPtr = pBuf;
	if (radioState == RECEIVED_STATE) // receiver might've done something
	  enterListenState();
	signal ByteRadio.rxDone();
      }
  }

  void packetReceiveDone() {
    uint16_t snr;

    snr = (uint16_t) getMetadata(rxBufPtr)->strength_or_preamble;
    /* Higher signal strengths have lower voltages. So see if we're
       CC1000_WHITE_BIT_THRESH *below* the noise floor. */
    if ((snr + CC1000_WHITE_BIT_THRESH) < ((call CC1000Squelch.get()))) {
      getMetadata(rxBufPtr)->metadataBits |= CC1000_WHITE_BIT;
    }
    else {
      getMetadata(rxBufPtr)->metadataBits &= ~CC1000_WHITE_BIT;
    }
    
    post signalPacketReceived();
    enterReceivedState();
  }

  async event void HplCC1000Spi.dataReady(uint8_t data) {
    if (f.invert)
      data = ~data;

    switch (radioState)
      {
      default: break;
      case TXPREAMBLE_STATE: txPreamble(); break;
      case TXSYNC_STATE: txSync(); break;
      case TXDATA_STATE: txData(); break;
      case TXCRC_STATE: txCrc(); break;
      case TXFLUSH_STATE: txFlush(); break;
      case TXWAITFORACK_STATE: txWaitForAck(); break;
      case TXREADACK_STATE: txReadAck(data); break;
      case TXDONE_STATE: txDone(); break;

      case LISTEN_STATE: listenData(data); break;
      case SYNC_STATE: syncData(data); break;
      case RX_STATE: rxData(data); break;
      case SENDING_ACK: ackData(data); break;
      }
  }

  /* Interaction with rest of stack */
  /*--------------------------------*/

  async command void ByteRadio.setPreambleLength(uint16_t bytes) {
    atomic preambleLength = bytes;
  }

  async command uint16_t ByteRadio.getPreambleLength() {
    atomic return preambleLength;
  }

  async command message_t *ByteRadio.getTxMessage() {
    return txBufPtr;
  }

  async command bool ByteRadio.syncing() {
    return radioState == SYNC_STATE;
  }

  /* Abstract packet layout */

  command void Packet.clear(message_t *msg) {
    memset(getHeader(msg), 0x0, sizeof(cc1000_header_t));
    memset(getFooter(msg), 0x0, sizeof(cc1000_footer_t));
    memset(getMetadata(msg), 0x0, sizeof(cc1000_metadata_t));
  }

  command uint8_t Packet.payloadLength(message_t *msg) {
    cc1000_header_t *header = getHeader(msg);
    return header->length;
  }
 
  command void Packet.setPayloadLength(message_t *msg, uint8_t len) {
    getHeader(msg)->length  = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  command void* Packet.getPayload(message_t *msg, uint8_t len) {
    if (len <= TOSH_DATA_LENGTH) {
      return (void* COUNT_NOK(len))msg->data;
    }
    else {
      return NULL;
    }
  }

  async command error_t PacketAcknowledgements.requestAck(message_t *msg) {
    return SUCCESS;		/* We always ack. */
  }

  async command error_t PacketAcknowledgements.noAck(message_t *msg) {
    return FAIL;		/* We always ack */
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t *m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  async command bool PacketAcknowledgements.wasAcked(message_t *msg) {
    return getMetadata(msg)->metadataBits & CC1000_ACK_BIT;
  }

  async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
    return getMetadata(msg)->metadataBits & CC1000_WHITE_BIT;
  }

  /***************** PacketTimeStamp32khz Commands ****************/
  async command bool PacketTimeStamp32khz.isValid(message_t* msg)
  {
    return (getMetadata(msg)->timestamp != CC1000_INVALID_TIMESTAMP);
  }

  async command uint32_t PacketTimeStamp32khz.timestamp(message_t* msg)
  {
    return getMetadata(msg)->timestamp;
  }

  async command void PacketTimeStamp32khz.clear(message_t* msg)
  {
    getMetadata(msg)->timesync = FALSE;
    getMetadata(msg)->timestamp = CC1000_INVALID_TIMESTAMP;
  }

  async command void PacketTimeStamp32khz.set(message_t* msg, uint32_t value)
  {
    getMetadata(msg)->timestamp = value;
  }

  /***************** PacketTimeStampMilli Commands ****************/
  // over the air value is always T32khz
  async command bool PacketTimeStampMilli.isValid(message_t* msg)
  {
    return call PacketTimeStamp32khz.isValid(msg);
  }

  async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg)
  {
    int32_t offset = call PacketTimeStamp32khz.timestamp(msg) - call LocalTime32khz.get();
    return (offset >> 5) + call LocalTimeMilli.get();
  }

  async command void PacketTimeStampMilli.clear(message_t* msg)
  {
    call PacketTimeStamp32khz.clear(msg);
  }

  async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value)
  {
    int32_t offset = (value - call LocalTimeMilli.get()) << 5;
    call PacketTimeStamp32khz.set(msg, offset + call LocalTime32khz.get());
  }

  /*----------------- PacketTimeSyncOffset -----------------*/
  async command bool PacketTimeSyncOffset.isSet(message_t* msg)
  {
    return getMetadata(msg)->timesync;
  }

  async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
  {
    return sizeof(cc1000_header_t) + getHeader(msg)->length - sizeof(timesync_radio_t);
  }

  async command void PacketTimeSyncOffset.set(message_t* msg)
  {
    getMetadata(msg)->timesync = TRUE;
  }

  async command void PacketTimeSyncOffset.cancel(message_t* msg)
  {
    getMetadata(msg)->timesync = FALSE;
  }
}
