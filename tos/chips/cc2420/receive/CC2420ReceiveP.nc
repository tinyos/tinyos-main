/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Jung Il Choi
 * @author JeongGil Ko
 * @author Razvan Musaloiu-E
 * @version $Revision: 1.20 $ $Date: 2009-08-29 00:06:42 $
 */

#include "IEEE802154.h"
#include "message.h"
#include "AM.h"

module CC2420ReceiveP @safe() {

  provides interface Init;
  provides interface StdControl;
  provides interface CC2420Receive;
  provides interface Receive;
  provides interface ReceiveIndicator as PacketIndicator;

  uses interface GeneralIO as CSN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SACK;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Packet;
  uses interface CC2420PacketBody;
  uses interface CC2420Config;
  uses interface PacketTimeStamp<T32khz,uint32_t>;

  uses interface CC2420Strobe as SRXDEC;
  uses interface CC2420Register as SECCTRL0;
  uses interface CC2420Register as SECCTRL1;
  uses interface CC2420Ram as KEY0;
  uses interface CC2420Ram as KEY1;
  uses interface CC2420Ram as RXNONCE;
  uses interface CC2420Ram as RXFIFO_RAM;
  uses interface CC2420Strobe as SNOP;

  uses interface Leds;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_RX_LENGTH,
    S_RX_DEC,
    S_RX_DEC_WAIT,
    S_RX_FCF,
    S_RX_PAYLOAD,
  } cc2420_receive_state_t;

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
    SACK_HEADER_LENGTH = 7,
  };

  uint32_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];

  uint8_t m_timestamp_head;
  
  uint8_t m_timestamp_size;
  
  /** Number of packets we missed because we were doing something else */
#ifdef CC2420_HW_SECURITY
  norace uint8_t m_missed_packets;
#else
  uint8_t m_missed_packets;
#endif

  /** TRUE if we are receiving a valid packet into the stack */
  bool receivingPacket;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;
  
  norace uint8_t m_bytes_left;
  
  norace message_t* ONE_NOK m_p_rx_buf;

  message_t m_rx_buf;
#ifdef CC2420_HW_SECURITY
  norace cc2420_receive_state_t m_state;
  norace uint8_t packetLength = 0;
  norace uint8_t pos = 0;
  norace uint8_t secHdrPos = 0;
  uint8_t nonceValue[16] = {0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01};
  norace uint8_t skip;
  norace uint8_t securityOn = 0;
  norace uint8_t authentication = 0;
  norace uint8_t micLength = 0;
  uint8_t flush_flag = 0;
  uint16_t startTime = 0;

  void beginDec();
  void dec();
#else
  cc2420_receive_state_t m_state;
#endif

  /***************** Prototypes ****************/
  void reset_state();
  void beginReceive();
  void receive();
  void waitForNextPacket();
  void flush();
  bool passesAddressCheck(message_t * ONE msg);

  task void receiveDone_task();

  /***************** Init Commands ****************/
  command error_t Init.init() {
    m_p_rx_buf = &m_rx_buf;
    return SUCCESS;
  }

  /***************** StdControl ****************/
  command error_t StdControl.start() {
    atomic {
      reset_state();
      m_state = S_STARTED;
      atomic receivingPacket = FALSE;
      /* Note:
         We use the falling edge because the FIFOP polarity is reversed. 
         This is done in CC2420Power.startOscillator from CC2420ControlP.nc.
       */
      call InterruptFIFOP.enableFallingEdge();
    }
    return SUCCESS;
  }
  
  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      reset_state();
      call CSN.set();
      call InterruptFIFOP.disable();
    }
    return SUCCESS;
  }

  /***************** CC2420Receive Commands ****************/
  /**
   * Start frame delimiter signifies the beginning/end of a packet
   * See the CC2420 datasheet for details.
   */
  async command void CC2420Receive.sfd( uint32_t time ) {
    if ( m_timestamp_size < TIMESTAMP_QUEUE_SIZE ) {
      uint8_t tail =  ( ( m_timestamp_head + m_timestamp_size ) % 
                        TIMESTAMP_QUEUE_SIZE );
      m_timestamp_queue[ tail ] = time;
      m_timestamp_size++;
    }
  }

  async command void CC2420Receive.sfd_dropped() {
    if ( m_timestamp_size ) {
      m_timestamp_size--;
    }
  }

  /***************** PacketIndicator Commands ****************/
  command bool PacketIndicator.isReceiving() {
    bool receiving;
    atomic {
      receiving = receivingPacket;
    }
    return receiving;
  }
  
  
  /***************** InterruptFIFOP Events ****************/
  async event void InterruptFIFOP.fired() {
    if ( m_state == S_STARTED ) {
#ifndef CC2420_HW_SECURITY
      m_state = S_RX_LENGTH;
      beginReceive();
#else
      m_state = S_RX_DEC;
      atomic receivingPacket = TRUE;
      beginDec();
#endif
    } else {
      m_missed_packets++;
    }
  }

  /*****************Decryption Options*********************/
#ifdef CC2420_HW_SECURITY
  task void waitTask(){

    if(SECURITYLOCK == 1){
      post waitTask();
    }else{
      m_state = S_RX_DEC;
      beginDec();
    }
  }

  void beginDec(){
    if(call SpiResource.isOwner()) {
      dec();
    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      dec();
    } else {
      call SpiResource.request();
    }
  }

  norace uint8_t decLoopCount = 0;

  task void waitDecTask(){

    cc2420_status_t status;

    call CSN.clr();
    status = call SNOP.strobe();
    call CSN.set();

    atomic decLoopCount ++;

    if(decLoopCount > 10){
      call CSN.clr();
      atomic call SECCTRL0.write((0 << CC2420_SECCTRL0_SEC_MODE) |
				 (0 << CC2420_SECCTRL0_SEC_M) |
				 (0 << CC2420_SECCTRL0_SEC_RXKEYSEL) |
				 (1 << CC2420_SECCTRL0_SEC_CBC_HEAD) |
				 (1 << CC2420_SECCTRL0_RXFIFO_PROTECTION)) ;
      call CSN.set();
      SECURITYLOCK = 0;
      call SpiResource.release();
      atomic flush_flag = 1;
      beginReceive();
    }else if(status & CC2420_STATUS_ENC_BUSY){
      post waitDecTask();
    }else{
      call CSN.clr();
      atomic call SECCTRL0.write((0 << CC2420_SECCTRL0_SEC_MODE) |
				 (0 << CC2420_SECCTRL0_SEC_M) |
				 (0 << CC2420_SECCTRL0_SEC_RXKEYSEL) |
				 (1 << CC2420_SECCTRL0_SEC_CBC_HEAD) |
				 (1 << CC2420_SECCTRL0_RXFIFO_PROTECTION)) ;
      call CSN.set();
      SECURITYLOCK = 0;
      call SpiResource.release();
      beginReceive();
    }

  }

  void waitDec(){
    cc2420_status_t status;
    call CSN.clr();
    status = call SNOP.strobe();
    call CSN.set();

    if(status & CC2420_STATUS_ENC_BUSY){
      atomic decLoopCount = 1;
      post waitDecTask();
    }else{
      call CSN.clr();
      atomic call SECCTRL0.write((0 << CC2420_SECCTRL0_SEC_MODE) |
				 (0 << CC2420_SECCTRL0_SEC_M) |
				 (0 << CC2420_SECCTRL0_SEC_RXKEYSEL) |
				 (1 << CC2420_SECCTRL0_SEC_CBC_HEAD) |
				 (1 << CC2420_SECCTRL0_RXFIFO_PROTECTION)) ;
      call CSN.set();
      SECURITYLOCK = 0;
      call SpiResource.release();
      beginReceive();
    }
  }

  void dec(){
    cc2420_header_t header;
    security_header_t secHdr;
    uint8_t mode, key, temp, crc;

    atomic pos = (packetLength+pos)%RXFIFO_SIZE;
    atomic secHdrPos = (pos+10)%RXFIFO_SIZE;

    if (pos + 3 > RXFIFO_SIZE){
      temp = RXFIFO_SIZE - pos;
      call CSN.clr();
      atomic call RXFIFO_RAM.read(pos,(uint8_t*)&header, temp);
      call CSN.set();
      call CSN.clr();
      atomic call RXFIFO_RAM.read(0,(uint8_t*)&header+temp, 3-temp);
      call CSN.set();
    }else{
      call CSN.clr();
      atomic call RXFIFO_RAM.read(pos,(uint8_t*)&header, 3);
      call CSN.set();
    }

    packetLength = header.length+1;

    if(packetLength == 6){ // ACK packet
      m_state = S_RX_LENGTH;
      call SpiResource.release();
      beginReceive();
      return;
    }

    if (pos + sizeof(cc2420_header_t) > RXFIFO_SIZE){
      temp = RXFIFO_SIZE - pos;
      call CSN.clr();
      atomic call RXFIFO_RAM.read(pos,(uint8_t*)&header, temp);
      call CSN.set();
      call CSN.clr();
      atomic call RXFIFO_RAM.read(0,(uint8_t*)&header+temp, sizeof(cc2420_header_t)-temp);
      call CSN.set();
    }else{
      call CSN.clr();
      atomic call RXFIFO_RAM.read(pos,(uint8_t*)&header, sizeof(cc2420_header_t));
      call CSN.set();
    }

    if (pos+header.length+1 > RXFIFO_SIZE){
      temp = header.length - (RXFIFO_SIZE - pos);
      call CSN.clr();
      atomic call RXFIFO_RAM.read(temp,&crc, 1);
      call CSN.set();
    }else{
      call CSN.clr();
      atomic call RXFIFO_RAM.read(pos+header.length,&crc, 1);
      call CSN.set();
    }

    if(header.length+1 > RXFIFO_SIZE || !(crc << 7)){
      atomic flush_flag = 1;
      m_state = S_RX_LENGTH;
      call SpiResource.release();
      beginReceive();
      return;
    }
    if( (header.fcf & (1 << IEEE154_FCF_SECURITY_ENABLED)) && (crc << 7) ){
      if(call CC2420Config.isAddressRecognitionEnabled()){
	if(!(header.dest==call CC2420Config.getShortAddr() || header.dest==AM_BROADCAST_ADDR)){
	  packetLength = header.length + 1;
	  m_state = S_RX_LENGTH;
	  call SpiResource.release();
	  beginReceive();
	  return;
	}
      }
      if(SECURITYLOCK == 1){
	call SpiResource.release();
	post waitTask();
	return;
      }else{
	//We are going to decrypt so lock the registers
	atomic SECURITYLOCK = 1;

	if (secHdrPos + sizeof(security_header_t) > RXFIFO_SIZE){
	  temp = RXFIFO_SIZE - secHdrPos;
	  call CSN.clr();
	  atomic call RXFIFO_RAM.read(secHdrPos,(uint8_t*)&secHdr, temp);
	  call CSN.set();
	  call CSN.clr();
	  atomic call RXFIFO_RAM.read(0,(uint8_t*)&secHdr+temp, sizeof(security_header_t) - temp);
	  call CSN.set();
	} else {
	  call CSN.clr();
	  atomic call RXFIFO_RAM.read(secHdrPos,(uint8_t*)&secHdr, sizeof(security_header_t));
	  call CSN.set();
	}

	key = secHdr.keyID[0];

	if (secHdr.secLevel == NO_SEC){
	  mode = CC2420_NO_SEC;
	  micLength = 0;
	}else if (secHdr.secLevel == CBC_MAC_4){
	  mode = CC2420_CBC_MAC;
	  micLength = 4;
	}else if (secHdr.secLevel == CBC_MAC_8){
	  mode = CC2420_CBC_MAC;
	  micLength = 8;
	}else if (secHdr.secLevel == CBC_MAC_16){
	  mode = CC2420_CBC_MAC;
	  micLength = 16;
	}else if (secHdr.secLevel == CTR){
	  mode = CC2420_CTR;
	  micLength = 0;
	}else if (secHdr.secLevel == CCM_4){
	  mode = CC2420_CCM;
	  micLength = 4;
	}else if (secHdr.secLevel == CCM_8){
	  mode = CC2420_CCM;
	  micLength = 8;
	}else if (secHdr.secLevel == CCM_16){
	  mode = CC2420_CCM;
	  micLength = 16;
	}else{
	  atomic SECURITYLOCK = 0;
	  packetLength = header.length + 1;
	  m_state = S_RX_LENGTH;
	  call SpiResource.release();
	  beginReceive();
	  return;
	}

	if(mode < 4 && mode > 0) { // if mode is valid
  
	  securityOn = 1;

	  memcpy(&nonceValue[3], &(secHdr.frameCounter), 4);
	  skip = secHdr.reserved;

	  if(mode == CC2420_CBC_MAC || mode == CC2420_CCM){
	    authentication = 1;
	    call CSN.clr();
	    atomic call SECCTRL0.write((mode << CC2420_SECCTRL0_SEC_MODE) |
				       ((micLength-2)/2 << CC2420_SECCTRL0_SEC_M) |
				       (key << CC2420_SECCTRL0_SEC_RXKEYSEL) |
				       (1 << CC2420_SECCTRL0_SEC_CBC_HEAD) |
				       (1 << CC2420_SECCTRL0_RXFIFO_PROTECTION)) ;
	    call CSN.set();
	  }else{
	    call CSN.clr();
	    atomic call SECCTRL0.write((mode << CC2420_SECCTRL0_SEC_MODE) |
				       (1 << CC2420_SECCTRL0_SEC_M) |
				       (key << CC2420_SECCTRL0_SEC_RXKEYSEL) |
				       (1 << CC2420_SECCTRL0_SEC_CBC_HEAD) |
				       (1 << CC2420_SECCTRL0_RXFIFO_PROTECTION)) ;
	    call CSN.set();
	  }

	  call CSN.clr();
#ifndef TFRAMES_ENABLED
	  atomic call SECCTRL1.write(skip+11+sizeof(security_header_t))+((skip+11+sizeof(security_header_t))<<8);
#else
	  atomic call SECCTRL1.write(skip+10+sizeof(security_header_t))+((skip+10+sizeof(security_header_t))<<8);
#endif
	  call CSN.set();

	  call CSN.clr();
	  atomic call RXNONCE.write(0, nonceValue, 16);
	  call CSN.set();

	  call CSN.clr();
	  atomic call SRXDEC.strobe();
	  call CSN.set();

	  atomic decLoopCount = 0;
	  post waitDecTask();
	  return;

	}else{
	  atomic SECURITYLOCK = 0;
	  packetLength = header.length + 1;
	  m_state = S_RX_LENGTH;
	  call SpiResource.release();
	  beginReceive();
	  return;
	}
      }
    }else{
      packetLength = header.length + 1;
      m_state = S_RX_LENGTH;
      call SpiResource.release();
      beginReceive();
      return;
    }
  }
#endif
  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
#ifdef CC2420_HW_SECURITY
    if(m_state == S_RX_DEC){
      dec();
    }else{
      receive();
    }
#else
    receive();
#endif
  }
  
  /***************** RXFIFO Events ****************/
  /**
   * We received some bytes from the SPI bus.  Process them in the context
   * of the state we're in.  Remember the length byte is not part of the length
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
                                    error_t error ) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_p_rx_buf );
    uint8_t tmpLen __DEPUTY_UNUSED__ = sizeof(message_t) - (offsetof(message_t, data) - sizeof(cc2420_header_t));
    uint8_t* COUNT(tmpLen) buf = TCAST(uint8_t* COUNT(tmpLen), header);
    rxFrameLength = buf[ 0 ];

    switch( m_state ) {

    case S_RX_LENGTH:
      m_state = S_RX_FCF;
#ifdef CC2420_HW_SECURITY
      packetLength = rxFrameLength+1;
#endif
      if ( rxFrameLength + 1 > m_bytes_left
#ifdef CC2420_HW_SECURITY
           || flush_flag == 1
#endif
           ) {
        // Length of this packet is bigger than the RXFIFO, flush it out.
        flush();
        
      } else {
        if ( !call FIFO.get() && !call FIFOP.get() ) {
          m_bytes_left -= rxFrameLength + 1;
        }
        
        if(rxFrameLength <= MAC_PACKET_SIZE) {
          if(rxFrameLength > 0) {
            if(rxFrameLength > SACK_HEADER_LENGTH) {
              // This packet has an FCF byte plus at least one more byte to read
              call RXFIFO.continueRead(buf + 1, SACK_HEADER_LENGTH);
              
            } else {
              // This is really a bad packet, skip FCF and get it out of here.
              m_state = S_RX_PAYLOAD;
              call RXFIFO.continueRead(buf + 1, rxFrameLength);
            }
                            
          } else {
            // Length == 0; start reading the next packet
            atomic receivingPacket = FALSE;
            call CSN.set();
            call SpiResource.release();
            waitForNextPacket();
          }
          
        } else {
          // Length is too large; we have to flush the entire Rx FIFO
          flush();
        }
      }
      break;
      
    case S_RX_FCF:
      m_state = S_RX_PAYLOAD;
      
      /*
       * The destination address check here is not completely optimized. If you 
       * are seeing issues with dropped acknowledgements, try removing
       * the address check and decreasing SACK_HEADER_LENGTH to 2.
       * The length byte and the FCF byte are the only two bytes required
       * to know that the packet is valid and requested an ack.  The destination
       * address is useful when we want to sniff packets from other transmitters
       * while acknowledging packets that were destined for our local address.
       */
      if(call CC2420Config.isAutoAckEnabled() && !call CC2420Config.isHwAutoAckDefault()) {
        if (((( header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1)
            && ((header->dest == call CC2420Config.getShortAddr())
                || (header->dest == AM_BROADCAST_ADDR))
            && ((( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA)) {
          // CSn flippage cuts off our FIFO; SACK and begin reading again
          call CSN.set();
          call CSN.clr();
          call SACK.strobe();
          call CSN.set();
          call CSN.clr();
	  call RXFIFO.beginRead(buf + 1 + SACK_HEADER_LENGTH,
				rxFrameLength - SACK_HEADER_LENGTH);
          return;
        }
      }
      // Didn't flip CSn, we're ok to continue reading.
      call RXFIFO.continueRead(buf + 1 + SACK_HEADER_LENGTH, 
			       rxFrameLength - SACK_HEADER_LENGTH);
      break;

    case S_RX_PAYLOAD:

      call CSN.set();
      if(!m_missed_packets) {
        // Release the SPI only if there are no more frames to download
        call SpiResource.release();
      }
      
      //new packet is buffered up, or we don't have timestamp in fifo, or ack
      if ( ( m_missed_packets && call FIFO.get() ) || !call FIFOP.get()
            || !m_timestamp_size
            || rxFrameLength <= 10) {
        call PacketTimeStamp.clear(m_p_rx_buf);
      }
      else {
          if (m_timestamp_size==1)
            call PacketTimeStamp.set(m_p_rx_buf, m_timestamp_queue[ m_timestamp_head ]);
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;

          if (m_timestamp_size>0) {
            call PacketTimeStamp.clear(m_p_rx_buf);
            m_timestamp_head = 0;
            m_timestamp_size = 0;
          }
      }

      // We may have received an ack that should be processed by Transmit
      // buf[rxFrameLength] >> 7 checks the CRC
      if ( ( buf[ rxFrameLength ] >> 7 ) && rx_buf ) {
        uint8_t type = ( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7;
        signal CC2420Receive.receive( type, m_p_rx_buf );
        if ( type == IEEE154_TYPE_DATA ) {
          post receiveDone_task();
          return;
        }
      }
      
      waitForNextPacket();
      break;

    default:
      atomic receivingPacket = FALSE;
      call CSN.set();
      call SpiResource.release();
      break;
      
    }
    
  }

  async event void RXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
  }  
  
  /***************** Tasks *****************/
  /**
   * Fill in metadata details, pass the packet up the stack, and
   * get the next packet.
   */
  task void receiveDone_task() {
    cc2420_metadata_t* metadata = call CC2420PacketBody.getMetadata( m_p_rx_buf );
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_p_rx_buf);
    uint8_t length = header->length;
    uint8_t tmpLen __DEPUTY_UNUSED__ = sizeof(message_t) - (offsetof(message_t, data) - sizeof(cc2420_header_t));
    uint8_t* COUNT(tmpLen) buf = TCAST(uint8_t* COUNT(tmpLen), header);

    metadata->crc = buf[ length ] >> 7;
    metadata->lqi = buf[ length ] & 0x7f;
    metadata->rssi = buf[ length - 1 ];

    if (passesAddressCheck(m_p_rx_buf) && length >= CC2420_SIZE) {
#ifdef CC2420_HW_SECURITY
      if(securityOn == 1){
	if(m_missed_packets > 0){
	  m_missed_packets --;
	}
	if(authentication){
	  length -= micLength;
	}
      }
      micLength = 0;
      securityOn = 0;
      authentication = 0;
#endif
      m_p_rx_buf = signal Receive.receive( m_p_rx_buf, CC2420_PAYLOAD(m_p_rx_buf),
					   length - CC2420_SIZE);
    }
    atomic receivingPacket = FALSE;
    waitForNextPacket();
  }

  /****************** CC2420Config Events ****************/
  event void CC2420Config.syncDone( error_t error ) {
  }
  
  /****************** Functions ****************/
  /**
   * Attempt to acquire the SPI bus to receive a packet.
   */
  void beginReceive() { 
    m_state = S_RX_LENGTH;
    atomic receivingPacket = TRUE;
    if(call SpiResource.isOwner()) {
      receive();
      
    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      receive();
      
    } else {
      call SpiResource.request();
    }
  }
  
  /**
   * Flush out the Rx FIFO
   */
  void flush() {
#ifdef CC2420_HW_SECURITY
    flush_flag = 0;
    pos =0;
    packetLength =0;
    micLength = 0;
    securityOn = 0;
    authentication = 0;
#endif
    reset_state();

    call CSN.set();
    call CSN.clr();
    call SFLUSHRX.strobe();
    call SFLUSHRX.strobe();
    call CSN.set();
    call SpiResource.release();
    waitForNextPacket();
  }
  
  /**
   * The first byte of each packet is the length byte.  Read in that single
   * byte, and then read in the rest of the packet.  The CC2420 could contain
   * multiple packets that have been buffered up, so if something goes wrong, 
   * we necessarily want to flush out the FIFO unless we have to.
   */
  void receive() {
    call CSN.clr();
    call RXFIFO.beginRead( (uint8_t*)(call CC2420PacketBody.getHeader( m_p_rx_buf )), 1 );
  }


  /**
   * Determine if there's a packet ready to go, or if we should do nothing
   * until the next packet arrives
   */
  void waitForNextPacket() {
    atomic {
      if ( m_state == S_STOPPED ) {
        call SpiResource.release();
        return;
      }
      
      atomic receivingPacket = FALSE;
      
      /*
       * The FIFOP pin here is high when there are 0 bytes in the RX FIFO
       * and goes low as soon as there are bytes in the RX FIFO.  The pin
       * is inverted from what the datasheet says, and its threshold is 127.
       * Whenever the FIFOP line goes low, as you can see from the interrupt
       * handler elsewhere in this module, it means we received a new packet.
       * If the line stays low without generating an interrupt, that means
       * there's still more data to be received.
       */

      if ( ( m_missed_packets && call FIFO.get() ) || !call FIFOP.get() ) {
        // A new packet is buffered up and ready to go
        if ( m_missed_packets ) {
          m_missed_packets--;
        }
#ifdef CC2420_HW_SECURITY
	call SpiResource.release();
	m_state = S_RX_DEC;
	beginDec();
#else
	beginReceive();
#endif

      } else {
        // Wait for the next packet to arrive
        m_state = S_STARTED;
        m_missed_packets = 0;
        call SpiResource.release();
      }
    }
  }
  
  /**
   * Reset this component
   */
  void reset_state() {
    m_bytes_left = RXFIFO_SIZE;
    atomic receivingPacket = FALSE;
    m_timestamp_head = 0;
    m_timestamp_size = 0;
    m_missed_packets = 0;
  }

  /**
   * @return TRUE if the given message passes address recognition
   */
  bool passesAddressCheck(message_t *msg) {
    cc2420_header_t *header = call CC2420PacketBody.getHeader( msg );
    
    if(!(call CC2420Config.isAddressRecognitionEnabled())) {
      return TRUE;
    }
    
    return (header->dest == call CC2420Config.getShortAddr()
        || header->dest == AM_BROADCAST_ADDR);
  }

}
