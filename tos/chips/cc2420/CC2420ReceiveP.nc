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
 * @version $Revision: 1.5 $ $Date: 2007-04-12 17:11:12 $
 */

module CC2420ReceiveP {

  provides interface Init;
  provides interface StdControl;
  provides interface CC2420Receive;
  provides interface Receive;

  uses interface GeneralIO as CSN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SACK;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Packet;
  
  uses interface Leds;
  uses async command am_addr_t amAddress();
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_RX_HEADER,
    S_RX_PAYLOAD,
  } cc2420_receive_state_t;

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
  };

  uint16_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];
  
  uint8_t m_timestamp_head;
  
  uint8_t m_timestamp_size;
  
  uint8_t m_missed_packets;

  bool fallingEdgeEnabled;
  
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
    fallingEdgeEnabled = FALSE;
    m_p_rx_buf = &m_rx_buf;
    return SUCCESS;
  }

  /***************** StdControl ****************/
  command error_t StdControl.start() {
    atomic {
      reset_state();
      m_state = S_STARTED;
        
      // Warning: MicaZ problems have been encountered with the following line
      // after it follows a .disable command
      call InterruptFIFOP.enableFallingEdge();
    }
    return SUCCESS;
  }


  
  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      reset_state();
      
      call SpiResource.release();
      
      // Warning: MicaZ problems have been encountered with the following line
      // followed by a re-enable.  The re-enable doesn't occur.
      call InterruptFIFOP.disable();
    }
    return SUCCESS;
  }

  /***************** Receive Commands ****************/
  command void* Receive.getPayload(message_t* m, uint8_t* len) {
    if (len != NULL) {
      *len = ((uint8_t*) (call CC2420Packet.getHeader( m_p_rx_buf )))[0];
    }
    return m->data;
  }

  command uint8_t Receive.payloadLength(message_t* m) {
    uint8_t* buf = (uint8_t*)(call CC2420Packet.getHeader( m_p_rx_buf ));
    return buf[0];
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
   * of the state we're in
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
                                    error_t error ) {
    cc2420_header_t* header = call CC2420Packet.getHeader( m_p_rx_buf );
    cc2420_metadata_t* metadata = call CC2420Packet.getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*) header;
    uint8_t length = buf[ 0 ];

    switch( m_state ) {

    case S_RX_HEADER:
      m_state = S_RX_PAYLOAD;
      if ( length + 1 > m_bytes_left ) {
        flush();
        
      } else {
        if ( !call FIFO.get() && !call FIFOP.get() ) {
          m_bytes_left -= length + 1;
        }
        
        if(length <= MAC_PACKET_SIZE) {
          if(length > 0) {
            // Length is in bounds; read in this packet
            call RXFIFO.continueRead((uint8_t*)(call CC2420Packet.getHeader(
                m_p_rx_buf )) + 1, length);
                
          } else {
            // Length == 0; start reading the next packet
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
      
    case S_RX_PAYLOAD:
      call CSN.set();
      
#ifndef CC2420_NO_ACKNOWLEDGEMENTS
      // Sorry about the preprocessing stuff. BaseStation depends on it.
      if (((( header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1) 
          && (header->dest == call amAddress())
          && ((( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA)) {
        call CSN.clr();
        call SACK.strobe();
        call CSN.set();
      }
#endif
      
      call SpiResource.release();
      
      if ( m_timestamp_size ) {
        if ( length > 10 ) {
          metadata->time = m_timestamp_queue[ m_timestamp_head ];
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;
        }
      } else {
        metadata->time = 0xffff;
      }
      
      // We may have received an ack that should be processed by Transmit
      if ( ( buf[ length ] >> 7 ) && rx_buf ) {
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
    cc2420_header_t* header = call CC2420Packet.getHeader( m_p_rx_buf );
    cc2420_metadata_t* metadata = call CC2420Packet.getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*)header;
    uint8_t length = buf[ 0 ];
    
    metadata->crc = buf[ length ] >> 7;
    metadata->rssi = buf[ length - 1 ];
    metadata->lqi = buf[ length ] & 0x7f;
    m_p_rx_buf = signal Receive.receive( m_p_rx_buf, m_p_rx_buf->data, 
                                         length );

    waitForNextPacket();
  }

  
  /****************** Functions ****************/
  /**
   * Attempt to acquire the SPI bus to receive a packet.
   */
  void beginReceive() { 
    m_state = S_RX_HEADER;
    
    if ( call SpiResource.immediateRequest() == SUCCESS ) {
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
    call RXFIFO.beginRead( (uint8_t*)(call CC2420Packet.getHeader( m_p_rx_buf )), 1 );
  }


  /**
   * Determine if there's a packet ready to go, or if we should do nothing
   * until the next packet arrives
   */
  void waitForNextPacket() {
    atomic {
      if ( m_state == S_STOPPED ) {
        return;
      }

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
      }
    }
  }
  
  /**
   * Reset this component
   */
  void reset_state() {
    m_bytes_left = RXFIFO_SIZE;
    m_timestamp_head = 0;
    m_timestamp_size = 0;
    m_missed_packets = 0;
  }

}
