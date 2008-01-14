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
 * @version $Revision: 1.5 $ $Date: 2008-01-14 22:18:19 $
 */

#include "IEEE802154.h"

module CC2420ReceiveP {

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
  
  uses interface Leds;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_RX_LENGTH,
    S_RX_FCF,
    S_RX_PAYLOAD,
  } cc2420_receive_state_t;

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
    SACK_HEADER_LENGTH = 7,
  };

  uint16_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];
  
  uint8_t m_timestamp_head;
  
  uint8_t m_timestamp_size;
  
  /** Number of packets we missed because we were doing something else */
  uint8_t m_missed_packets;
  
  /** TRUE if we are receiving a valid packet into the stack */
  bool receivingPacket;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;
  
  norace uint8_t m_bytes_left;
  
  norace message_t* m_p_rx_buf;

  message_t m_rx_buf;
  
  cc2420_receive_state_t m_state;
  
  /***************** Prototypes ****************/
  void reset_state();
  void beginReceive();
  void receive();
  void waitForNextPacket();
  void flush();
  
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
  async command void CC2420Receive.sfd( uint16_t time ) {
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
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_p_rx_buf );
    cc2420_metadata_t* metadata = call CC2420PacketBody.getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*) header;
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
      
      if ( m_timestamp_size ) {
        if ( rxFrameLength > 10 ) {
          metadata->time = m_timestamp_queue[ m_timestamp_head ];
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;
        }
      } else {
        metadata->time = 0xffff;
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
    uint8_t* buf = (uint8_t*) call CC2420PacketBody.getHeader( m_p_rx_buf );;
    
    metadata->crc = buf[ rxFrameLength ] >> 7;
    metadata->rssi = buf[ rxFrameLength - 1 ];
    metadata->lqi = buf[ rxFrameLength ] & 0x7f;
    m_p_rx_buf = signal Receive.receive( m_p_rx_buf, m_p_rx_buf->data, 
                                         rxFrameLength );

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

}
