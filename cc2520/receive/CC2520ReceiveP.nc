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
 * @version $Revision: 1.16 $ $Date: 2008/07/25 16:27:52 $
 */

#include "IEEE802154.h"
#include "message.h"
#include "AM.h"

#ifndef FLAG_FIELD
#define FLAG_FIELD	FLAG_ENC			//M = 4 L = 2
#endif

#ifndef SECURITY_CONTROL
#define SECURITY_CONTROL SEC_ENC	//MIC-64	
#endif

module CC2520ReceiveP @safe() {

  provides interface Init;
  provides interface StdControl;
  provides interface CC2520Receive;
  provides interface Receive;
  provides interface ReceiveIndicator as PacketIndicator;

  uses interface GeneralIO as CSN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;

  uses interface Resource as SpiResource;
  uses interface CC2520Fifo as RXFIFO;
  uses interface CC2520Strobe as SACK;
  uses interface CC2520Strobe as SACKPEND;
  uses interface CC2520Strobe as SFLUSHRX;
  uses interface CC2520Transmit as Send;
  uses interface CC2520Packet;
  uses interface CC2520PacketBody;
  uses interface CC2520Config;
  uses interface PacketTimeStamp<T32khz,uint32_t>;
  #ifdef CC2520_HW_SECURITY
  uses interface CC2520Ram as RXFRAME;
  uses interface CC2520Ram as RXNonce;
  uses interface CC2520Strobe as SNOP;
  uses interface SpiByte;
  uses interface AMPacket;
  #endif


  uses interface Leds;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_RX_LENGTH,
    S_RX_FCF,
    S_RX_PAYLOAD,
  } cc2520_receive_state_t;

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
    SACK_HEADER_LENGTH = 7,
    //SACK_HEADER_LENGTH = 2,
  };

  uint32_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];

  uint8_t m_timestamp_head;
  
  uint8_t m_timestamp_size;
  
  /** Number of packets we missed because we were doing something else */
  uint8_t m_missed_packets;
  
  /** TRUE if we are receiving a valid packet into the stack */
  bool receivingPacket;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;
  
  norace uint8_t m_bytes_left;
  
  norace message_t* ONE_NOK m_p_rx_buf;

  message_t m_rx_buf;
  message_t ack_buf;
 
  #ifdef CC2520_HW_SECURITY	
  static uint8_t nonceRx[16];
  #endif
  
  cc2520_receive_state_t m_state;
  
  /***************** Prototypes ****************/
  void reset_state();
  void beginReceive();
  void receive();
  void waitForNextPacket();
  void flush();
  #ifdef CC2520_HW_SECURITY
  error_t acquireSpiResource(void);
  void decryptPacket(void);
  uint8_t getMICLength(uint8_t securityLevel);
  void initNonce(void);
  #endif
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
  async command void CC2520Receive.sfd( uint32_t time ) {
    if ( m_timestamp_size < TIMESTAMP_QUEUE_SIZE ) {
      uint8_t tail =  ( ( m_timestamp_head + m_timestamp_size ) % 
                        TIMESTAMP_QUEUE_SIZE );
      m_timestamp_queue[ tail ] = time;
      m_timestamp_size++;
    }
	
  }

  async command void CC2520Receive.sfd_dropped() {
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
	//call Leds.led0On();
    if ( m_state == S_STARTED ) {
      m_state = S_RX_LENGTH;
      beginReceive();
	
    } else {
      m_missed_packets++;
    }
  }
  
  
  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    receive();
  }
  
  /***************** RXFIFO Events ****************/
  /**
   * We received some bytes from the SPI bus.  Process them in the context
   * of the state we're in.  Remember the length byte is not part of the length
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
                                    error_t error ) {
    cc2520_header_t* header = call CC2520PacketBody.getHeader( m_p_rx_buf );
    uint8_t tmpLen __DEPUTY_UNUSED__ = sizeof(message_t) - (offsetof(message_t, data) - sizeof(cc2520_header_t));
    uint8_t* COUNT(tmpLen) buf = TCAST(uint8_t* COUNT(tmpLen), header);
    rxFrameLength = buf[ 0 ];

    switch( m_state ) {

    case S_RX_LENGTH:
      m_state = S_RX_FCF;
	
      if ( rxFrameLength + 1 > m_bytes_left ) {
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
      if(call CC2520Config.isAutoAckEnabled() && !call CC2520Config.isHwAutoAckDefault()) {
        if (((( header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1)
            && ((header->dest == call CC2520Config.getShortAddr())
                || (header->dest == AM_BROADCAST_ADDR))
            && ((( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA)) {
          // CSn flippage cuts off our FIFO; SACK and begin reading again
          call CSN.set();
          call CSN.clr();
          call SACK.strobe();
          call Leds.led1Toggle();
          call CSN.set();
          call CSN.clr();
          call RXFIFO.beginRead(buf + 1 + SACK_HEADER_LENGTH, 
              rxFrameLength - SACK_HEADER_LENGTH);
//          call CSN.set();
//	 	  call CSN.clr();
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
/*     
      if ( m_timestamp_size ) {
        if ( rxFrameLength > 10 ) {
          call PacketTimeStamp.set(m_p_rx_buf, m_timestamp_queue[ m_timestamp_head ]);
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;
        }
      } else {
        call PacketTimeStamp.clear(m_p_rx_buf);
      }
*/      
      // We may have received an ack that should be processed by Transmit
      // buf[rxFrameLength] >> 7 checks the CRC
      if ( ( buf[ rxFrameLength ] >> 7 ) && rx_buf ) {
        uint8_t type = ( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7;
      //  if ( type == IEEE154_TYPE_ACK )
        // call Leds.led0Toggle();

        signal CC2520Receive.receive( type, m_p_rx_buf );
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
    cc2520_metadata_t* metadata = call CC2520PacketBody.getMetadata( m_p_rx_buf );
    cc2520_header_t* header = call CC2520PacketBody.getHeader( m_p_rx_buf);
    uint8_t length = header->length;
    uint8_t tmpLen __DEPUTY_UNUSED__ = sizeof(message_t) - (offsetof(message_t, data) - sizeof(cc2520_header_t));
    uint8_t* COUNT(tmpLen) buf = TCAST(uint8_t* COUNT(tmpLen), header);
    metadata->crc = buf[ length ] >> 7;
    metadata->lqi = buf[ length ] & 0x7f;
    metadata->rssi = buf[ length - 1 ];
    
    if (passesAddressCheck(m_p_rx_buf) && length >= CC2520_SIZE) {
		if(((header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1) {
		  cc2520_header_t* ack_hdr = call CC2520PacketBody.getHeader(&ack_buf);	
		  ack_hdr->length  = 3 + CC2520_SIZE;
    	  ack_hdr->fcf = (IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE); 
		  ack_hdr->dsn = header->dsn;
		  call Send.send(&ack_buf, 1);
		}
      #ifdef CC2520_HW_SECURITY
	decryptPacket();
      #endif
      m_p_rx_buf = signal Receive.receive( m_p_rx_buf, m_p_rx_buf->data, 
					   length - CC2520_SIZE);
    }
    
    atomic receivingPacket = FALSE;
    waitForNextPacket();
	
  }
  
  /****************** CC2420Config Events ****************/
  event void CC2520Config.syncDone( error_t error ) {
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
    reset_state();
    call CSN.set();
    call CSN.clr();
    call SFLUSHRX.strobe();
//     call CSN.set();
//	 call CSN.clr();
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
    call RXFIFO.beginRead( (uint8_t*)(call CC2520PacketBody.getHeader( m_p_rx_buf )), 1 );
    //call CSN.set();
   
  }

 
  /*
   * Decrypt the received packet
   */
   #ifdef CC2520_HW_SECURITY

   error_t acquireSpiResource() {

    error_t error = call SpiResource.immediateRequest();

    if ( error != SUCCESS ) {
	//	printf("\nspi error:%d",error);printfflush();
      call SpiResource.request();
    }
    return error;
  }

   uint8_t getMICLength(uint8_t securityLevel) {
	
	if(securityLevel == SEC_MIC_32 || securityLevel == SEC_ENC_MIC_32) 	
		return 4;
	else if(securityLevel == SEC_MIC_64 || securityLevel == SEC_ENC_MIC_64)
		return 8;
	else if(securityLevel == SEC_ENC_MIC_128 || securityLevel == SEC_ENC_MIC_128)
		return 16;
	return 0;
  }

   void reverseArray(uint8_t *ptr,uint8_t length)
   {
	uint8_t i,tmp;
	for(i=0; i< length/2;i++)
	{
		tmp = ptr[i];
		ptr[i] = ptr[length -i];
		ptr[length-i] = tmp;	
	}	
   }


   void initNonce(void)
   {
	uint8_t i;
	cc2520_header_t* header = call CC2520PacketBody.getHeader( m_p_rx_buf);
	for(i=0;i<NONCE_SIZE;i++)
    	{
		nonceRx[i] = 0;
    	}
	nonceRx[0] = FLAG_FIELD;
	nonceRx[7] = (uint8_t)((call AMPacket.source( m_p_rx_buf)) >> 8);
	nonceRx[8] = (uint8_t)(call AMPacket.source( m_p_rx_buf) & 0xff);
	nonceRx[13] = SECURITY_CONTROL;	
	nonceRx[15] = 0x01;	

	reverseArray(nonceRx, 16);
	call CSN.clr();
	call RXNonce.write(0, nonceRx, 16);
	call CSN.set();
   }

   void decryptPacket(void)
   {
	cc2520_header_t* header = call CC2520PacketBody.getHeader( m_p_rx_buf);
	uint8_t *ptr = (uint8_t *)header;
	uint8_t micLength 	= getMICLength(header->secHdr.secLevel);
	uint8_t decryptLength  = header->length - CC2520_SIZE - micLength;
	uint8_t authLength	= CC2520_SIZE - MAC_FOOTER_SIZE;
	uint8_t length		= header->length;

	acquireSpiResource();
	call CSN.clr();
	call RXFRAME.write(0, ptr,header->length);		
	call CSN.set();	
	

	initNonce();
	
	call CSN.clr();
	call SpiByte.write(CC2520_CMD_UCCM | HIGH_PRIORITY);
	call SpiByte.write(CC2520_RAM_KEY0/16);
	call SpiByte.write(decryptLength);
	call SpiByte.write(CC2520_RAM_RXNONCE/16);
        call SpiByte.write((HI_UINT16(CC2520_RAM_RXFRAME+1)<<4)|HI_UINT16(0));
    	call SpiByte.write(LO_UINT16(CC2520_RAM_RXFRAME+1));
    	call SpiByte.write(LO_UINT16(0));	//For Inline Security
    	call SpiByte.write(authLength);
    	call SpiByte.write(micLength);
	call CSN.set();

	call CSN.clr();	
	while(call SNOP.strobe() & 0x08);
	call CSN.set();

	header->dsn = 0xff;

	call CSN.clr();
	call RXFRAME.read(0, ptr, length);
	call CSN.set();
	
	call SpiResource.release();

   }
   #endif



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
        
        beginReceive();
        
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
    cc2520_header_t *header = call CC2520PacketBody.getHeader( msg );
        int mode = (header->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 3;
	  ieee_eui64_t *ext_addr; 

    if(!(call CC2520Config.isAddressRecognitionEnabled())) {

      return TRUE;
    }
    if (mode == IEEE154_ADDR_SHORT) {
      return (header->dest == call CC2520Config.getShortAddr()
              || header->dest == IEEE154_BROADCAST_ADDR);
    } else if (mode == IEEE154_ADDR_EXT) {

      ieee_eui64_t local_addr = (call CC2520Config.getExtAddr());
	
      ext_addr = TCAST(ieee_eui64_t* ONE, &header->dest);
	// printf("\n link layer address:");
    //  printf_buf(ext_addr,8);
      return (memcmp(ext_addr->data, local_addr.data, IEEE_EUI64_LENGTH) == 0);
    } else {
      /* reject frames with either no address or invalid type */
      return FALSE;
    }
  }

  async event void Send.sendDone(message_t *p_msg, error_t error) { return; }

}

