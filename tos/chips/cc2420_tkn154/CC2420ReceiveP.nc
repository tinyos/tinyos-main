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
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @version $Revision: 1.4 $ $Date: 2009-05-05 16:56:49 $
 */
module CC2420ReceiveP {

  provides interface Init;
  provides interface CC2420AsyncSplitControl as AsyncSplitControl; 
  provides interface CC2420Receive;
  provides interface CC2420Rx;

  uses interface GeneralIO as CSN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SACK;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SACKPEND; 
  uses interface CC2420Register as MDMCTRL1;
  uses interface ReferenceTime;
  uses interface FrameUtility;
  uses interface CC2420Config;
  uses interface CC2420Ram as RXFIFO_RAM;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTING,
    S_STARTED,
    S_RX_LENGTH,
    S_RX_FCF,
    S_RX_HEADER,
    S_RX_PAYLOAD,
  } cc2420_receive_state_t;

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
    //SACK_HEADER_LENGTH = 7,
    SACK_HEADER_LENGTH = 3,
  };

  ieee154_timestamp_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];
  ieee154_timestamp_t m_timestamp;
  norace bool m_timestampValid;
  
  uint8_t m_timestamp_head;
  
  uint8_t m_timestamp_size;
  
  /** Number of packets we missed because we were doing something else */
  uint8_t m_missed_packets;
  
  /** TRUE if we are receiving a valid packet into the stack */
  norace bool receivingPacket;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;
  
  norace uint8_t m_bytes_left;

  // norace message_t* m_p_rx_buf;

  // message_t m_rx_buf;
  
  cc2420_receive_state_t m_state;
  
  // new packet format:
  message_t m_frame;
  norace message_t *m_rxFramePtr;
  norace uint8_t m_mhrLen;
  uint8_t m_dummy;
  norace bool m_stop;
  
  /***************** Prototypes ****************/
  void reset_state();
  void beginReceive();
  void receive();
  void waitForNextPacket();
  void flush();
  void switchToUnbufferedMode();
  void switchToBufferedMode();
  void continueStart();
  void continueStop();
  task void stopContinueTask();
  
  task void receiveDone_task();
  
  /***************** Init Commands ****************/
  command error_t Init.init() {
    m_rxFramePtr = &m_frame;
    atomic m_state = S_STOPPED;
    return SUCCESS;
  }

  /***************** AsyncSplitControl ****************/
  /* NOTE: AsyncSplitControl does not switch the state of the radio 
   * hardware (i.e. it does not put the radio in Rx mode, this has to
   * be done by the caller through a separate interface/component). 
   */

  /** 
   * AsyncSplitControl.start should be called before radio
   * is switched to Rx mode (or at least early enough before
   * a packet has been received, i.e. before FIFOP changes)
   */
  async command error_t AsyncSplitControl.start()
  {
    atomic {
      if ( !call FIFO.get() && !call FIFOP.get() ){
        // RXFIFO has some data (remember: FIFOP is inverted)
        // the problem is that this messses up the timestamping
        // so why don't we flush here ourselves? 
        // because we don't own the SPI...
        return FAIL; 
      }
      ASSERT(m_state == S_STOPPED);
      reset_state();
      m_state = S_STARTED;
      call InterruptFIFOP.enableFallingEdge(); // ready!
    }
    return SUCCESS;
  }

  /* AsyncSplitControl.stop:
   *
   * IMPORTANT: when AsyncSplitControl.stop is called, 
   * then either
   * 1) the radio MUST still be in RxMode
   * 2) it was never put in RxMode after  
   *    AsyncSplitControl.start() was called
   *
   * => The radio may be switched off only *after* the
   * stopDone() event was signalled.
   */
  async command error_t AsyncSplitControl.stop()
  {
    atomic {
      if (m_state == S_STOPPED)
        return EALREADY;
      else {
        m_stop = TRUE;
        call InterruptFIFOP.disable();
        if (!receivingPacket)
          continueStop(); // it is safe to stop now
        // else continueStop will be called after 
        // current Rx operation is finished
      }
    }
    return SUCCESS;
  }

  void continueStop()
  {
    atomic {
      if (!m_stop){
        return;
      }
      m_stop = FALSE;
      m_state = S_STOPPED;
    }
    post stopContinueTask();
  }

  task void stopContinueTask()
  {
    ASSERT(receivingPacket != TRUE);
    call SpiResource.release(); // may fail
    atomic m_state = S_STOPPED;
    signal AsyncSplitControl.stopDone(SUCCESS);
  }

  /***************** CC2420Receive Commands ****************/
  /**
   * Start frame delimiter signifies the beginning/end of a packet
   * See the CC2420 datasheet for details.
   */
  async command void CC2420Receive.sfd( ieee154_timestamp_t *time ) {
    if (m_state == S_STOPPED)
      return;
    if ( m_timestamp_size < TIMESTAMP_QUEUE_SIZE ) {
      uint8_t tail =  ( ( m_timestamp_head + m_timestamp_size ) % 
                        TIMESTAMP_QUEUE_SIZE );
      memcpy(&m_timestamp_queue[ tail ], time, sizeof(ieee154_timestamp_t) );
      m_timestamp_size++;
    }
  }

  async command void CC2420Receive.sfd_dropped() {
    if (m_state == S_STOPPED)
      return;    
    if ( m_timestamp_size ) {
      m_timestamp_size--;
    }
  }
  
  /***************** InterruptFIFOP Events ****************/
  async event void InterruptFIFOP.fired() {
    atomic {
      if ( m_state == S_STARTED ) {
        beginReceive();

      } else {
        m_missed_packets++;
      }
    }
  }
  
  
  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    atomic {
      switch (m_state)
      {
        case S_STOPPED: ASSERT(0); break; // this should never happen!
        default: receive();
      }
    }
  }
  
  /***************** RXFIFO Events ****************/
  /**
   * We received some bytes from the SPI bus.  Process them in the context
   * of the state we're in.  Remember the length byte is not part of the length
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
                                    error_t error ) {
    uint8_t* buf;

   atomic {
    buf = (uint8_t*) &((ieee154_header_t*) m_rxFramePtr->header)->length; 
    rxFrameLength = ((ieee154_header_t*) m_rxFramePtr->header)->length;

     switch( m_state ) {

    case S_RX_LENGTH:
      m_state = S_RX_FCF;
      if ( rxFrameLength + 1 > m_bytes_left ) {
        // Length of this packet is bigger than the RXFIFO, flush it out.
        flush();
        
      } else {
        if ( !call FIFO.get() && !call FIFOP.get() ) {
          //m_bytes_left -= rxFrameLength + 1;
          flush(); 
        }
        
        //if(rxFrameLength <= MAC_PACKET_SIZE) {
        if(rxFrameLength <= (sizeof(ieee154_header_t) - 1 + TOSH_DATA_LENGTH + 2)){
          if(rxFrameLength > 0) {
            if(rxFrameLength > SACK_HEADER_LENGTH) {
              // This packet has an FCF byte plus at least one more byte to read
              call RXFIFO.continueRead(buf + 1, SACK_HEADER_LENGTH);
              
            } else {
              // This is really a bad packet, skip FCF and get it out of here.
              flush(); 
              //m_state = S_RX_PAYLOAD;
              //call RXFIFO.continueRead(buf + 1, rxFrameLength);
            }
                            
          } else {
            // Length == 0; start reading the next packet
            flush();  
/*            atomic receivingPacket = FALSE;*/
/*            call CSN.set();*/
/*            call SpiResource.release();*/
/*            waitForNextPacket();*/
          }
          
        } else {
          // Length is too large; we have to flush the entire Rx FIFO
          flush();
        }
      }
      break;
      
    case S_RX_FCF:
      if (call FrameUtility.getMHRLength(buf[1], buf[2], &m_mhrLen) != SUCCESS ||
          m_mhrLen > rxFrameLength - 2) {
        // header size incorrect
        flush();
        break;
      } else if (m_mhrLen > SACK_HEADER_LENGTH) {
        m_state = S_RX_HEADER;
        call RXFIFO.continueRead(buf + 1 + SACK_HEADER_LENGTH, 
          m_mhrLen - SACK_HEADER_LENGTH);
        break;
      } else {
        // complete header has been read: fall through
      }
      // fall through

    case S_RX_HEADER:
      // JH: we are either using HW ACKs (normal receive mode) or don't ACK any
      // packets (promiscuous mode)
      // Didn't flip CSn, we're ok to continue reading.
      if ((rxFrameLength - m_mhrLen - 2) > TOSH_DATA_LENGTH) // 2 for CRC
        flush();
      else {
        m_state = S_RX_PAYLOAD;
        call RXFIFO.continueRead((uint8_t*) m_rxFramePtr->data, rxFrameLength - m_mhrLen);
      }
      break;
    
    case S_RX_PAYLOAD:
      call CSN.set();
      
      if(!m_missed_packets) {
        // Release the SPI only if there are no more frames to download
        call SpiResource.release();
      }
      
      if ( m_timestamp_size ) {
        if ( rxFrameLength > 4 ) {
          //((ieee154_metadata_t*) m_rxFramePtr->metadata)->timestamp = m_timestamp_queue[ m_timestamp_head ];
          memcpy(&m_timestamp, &m_timestamp_queue[ m_timestamp_head ], sizeof(ieee154_timestamp_t) );
          m_timestampValid = TRUE;
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;
        }
      } else {
/*        metadata->time = 0xffff;*/
        m_timestampValid = FALSE;
        //((ieee154_metadata_t*) m_rxFramePtr->metadata)->timestamp = IEEE154_INVALID_TIMESTAMP;
      }
      
      // We may have received an ack that should be processed by Transmit
      // buf[rxFrameLength] >> 7 checks the CRC
      if ( ( m_rxFramePtr->data[ rxFrameLength - m_mhrLen - 1 ] >> 7 ) && rx_buf ) {
        uint8_t type = ((ieee154_header_t*) m_rxFramePtr->header)->mhr[0] & 0x07;
/*        signal CC2420Receive.receive( type, m_p_rx_buf );*/
        signal CC2420Receive.receive( type, m_rxFramePtr );
/*        if ( type == IEEE154_TYPE_DATA ) {*/
        if ( (type != IEEE154_TYPE_ACK || call CC2420Config.isPromiscuousModeEnabled())
            && !m_stop) { 
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
      if (m_stop){
        continueStop();
        return;
      }
      break;
      
    }
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
    uint8_t payloadLen = ((ieee154_header_t*) m_rxFramePtr->header)->length - m_mhrLen - 2;
    ieee154_metadata_t *metadata = (ieee154_metadata_t*) m_rxFramePtr->metadata;

    atomic ASSERT(m_state != S_STOPPED);
    ((ieee154_header_t*) m_rxFramePtr->header)->length = m_rxFramePtr->data[payloadLen+1] & 0x7f; // temp. LQI
    metadata->rssi = m_rxFramePtr->data[payloadLen];
    metadata->linkQuality = ((ieee154_header_t*) m_rxFramePtr->header)->length; // copy back
    ((ieee154_header_t*) m_rxFramePtr->header)->length = payloadLen;
    if (m_timestampValid)
      metadata->timestamp = call ReferenceTime.toLocalTime(&m_timestamp);
    else
      metadata->timestamp = IEEE154_INVALID_TIMESTAMP;
    m_rxFramePtr = signal CC2420Rx.received(m_rxFramePtr, &m_timestamp);

/*    cc2420_metadata_t* metadata = call CC2420PacketBody.getMetadata( m_p_rx_buf );*/
/*    uint8_t* buf = (uint8_t*) call CC2420PacketBody.getHeader( m_p_rx_buf );;*/
/*    */
/*    metadata->crc = buf[ rxFrameLength ] >> 7;*/
/*    metadata->rssi = buf[ rxFrameLength - 1 ];*/
/*    metadata->lqi = buf[ rxFrameLength ] & 0x7f;*/
    // async event message_t* receiveDone( message_t *data );

/*    m_p_rx_buf = signal Receive.receive( m_rxFramePtrm_p_rx_buf, m_p_rx_buf->data, */
/*                                         rxFrameLength );*/

    atomic receivingPacket = FALSE;
    waitForNextPacket();
  }
  
  
  /****************** Functions ****************/
  /**
   * Attempt to acquire the SPI bus to receive a packet.
   */
  void beginReceive() { 
    atomic {
      if (m_state == S_STOPPED || m_stop){
        return;
      }
      m_state = S_RX_LENGTH;
      receivingPacket = TRUE;
    
      if(call SpiResource.isOwner()) {
        receive();

      } else if (call SpiResource.immediateRequest() == SUCCESS) {
        receive();

      } else {
        call SpiResource.request();
      }
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
    call CSN.set();
    call CSN.clr();
    //call RXFIFO.beginRead( (uint8_t*)(call CC2420PacketBody.getHeader( m_p_rx_buf )), 1 );
    call RXFIFO.beginRead( &((ieee154_header_t*) m_rxFramePtr->header)->length, 1 );
  }


  /**
   * Determine if there's a packet ready to go, or if we should do nothing
   * until the next packet arrives
   */
  void waitForNextPacket() {
    atomic {
      if ( m_state == S_STOPPED) {
        call SpiResource.release();
        return;
      }
      receivingPacket = FALSE;
      if (m_stop){
        continueStop();
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
