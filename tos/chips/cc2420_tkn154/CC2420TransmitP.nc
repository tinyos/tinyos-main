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
 * @author Jung Il Choi Initial SACK implementation
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 *
 * IMPORTANT: this module does not use the SPI Resource interface,
 * instead the caller must take care of the resource arbitration
 * (i.e. the caller must own the resource before calling commands
 * like CC2420Tx.loadTXFIFO())
 * Note: on TelosB there seems to be a problem if BackoffAlarm
 * is virtualized - i.e. BackoffAlarm should be a dedicated Alarm.
 *
 * @version $Revision: 1.4 $ $Date: 2009-03-04 18:31:11 $
 */

#include "CC2420.h"
#include "crc.h"
#include "message.h"

module CC2420TransmitP {

  provides interface Init;
  provides interface AsyncStdControl;
  provides interface CC2420Tx;
  uses interface Alarm<T62500hz,uint32_t> as BackoffAlarm;
  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;

  uses interface ChipSpiResource;
  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Ram as TXFIFO_RAM;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as STXONCCA;
  uses interface CC2420Strobe as SFLUSHTX;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Strobe as SACKPEND;
  uses interface CC2420Register as MDMCTRL1;
  uses interface CaptureTime;
  uses interface ReferenceTime;

  uses interface CC2420Receive;
  uses interface Leds;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_LOAD,
    S_READY_TX,
    S_SFD,
    S_EFD,
    S_ACK_WAIT,
  } cc2420_transmit_state_t;

  // This specifies how many symbols the stack should wait after a
  // TXACTIVE to receive an SFD interrupt before assuming something is
  // wrong and aborting the send. There seems to be a condition
  // on the micaZ where the SFD interrupt is never handled.
  enum {
    CC2420_ABORT_PERIOD = 320*3,
  };
  
  norace ieee154_txframe_t *m_frame;
  ieee154_timestamp_t m_timestamp;
  
  cc2420_transmit_state_t m_state = S_STOPPED;
  
  bool m_receiving = FALSE;
  
  uint16_t m_prev_time;
  
  /** Byte reception/transmission indicator */
  bool sfdHigh;
  
  /** Let the CC2420 driver keep a lock on the SPI while waiting for an ack */
  norace bool abortSpiRelease;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;
  norace uint32_t alarmStartTime;
  

  /***************** Prototypes ****************/
  void signalDone( bool ackFramePending, error_t err );
  
  /***************** Init Commands *****************/
  command error_t Init.init() {
    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
    return SUCCESS;
  }

  /***************** AsyncStdControl Commands ****************/
  async command error_t AsyncStdControl.start() {
    atomic {
      if (m_state == S_STARTED)
        return EALREADY;
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
    }
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call BackoffAlarm.stop();
      call CaptureSFD.disable();
      call CSN.set();
    }
    return SUCCESS;
  }


  /**************** Load/Send Commands ****************/

  async command error_t CC2420Tx.loadTXFIFO(ieee154_txframe_t *data) 
  {
    atomic {
      if ( m_state != S_STARTED )
        return FAIL;
      m_state = S_LOAD;
      m_frame = data;
      m_frame->header->length = m_frame->headerLen + m_frame->payloadLen + 2; // 2 for CRC
      call CSN.set();
      call CSN.clr();
      call SFLUSHTX.strobe(); // flush out anything that was in TXFIFO
      call CSN.set();
      call CSN.clr();
      call TXFIFO.write( &(m_frame->header->length), 1 );
    }
    return SUCCESS;
  }   

  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error) 
  {
    atomic {
      call CSN.set();
      if (tx_buf == &(m_frame->header->length)){
        call CSN.clr();
        call TXFIFO.write( m_frame->header->mhr, m_frame->headerLen );
        return;
      } else if (tx_buf == m_frame->header->mhr) {
        call CSN.clr();
        call TXFIFO.write( m_frame->payload, m_frame->payloadLen );
        return;
      }
    }
    m_state = S_READY_TX;
    signal CC2420Tx.loadTXFIFODone(m_frame, error);
  }

  async command error_t CC2420Tx.send(bool cca)
  {
    cc2420_status_t status;
    bool congestion = TRUE;

    atomic {
      if (m_state != S_READY_TX)
        return EOFF;
      call CSN.set();
      call CSN.clr();

      // DEBUG
      //P2OUT |= 0x40;      // P2.6 high
      status = cca ? call STXONCCA.strobe() : call STXON.strobe();
      //status = call STXON.strobe();
      //U0TXBUF = 0x04; // strobe STXON
      //while (!(IFG1 & URXIFG0));
      //status = U0RXBUF;
      //call CSN.set();

      if ( !( status & CC2420_STATUS_TX_ACTIVE ) ) {
        status = call SNOP.strobe();
        if ( status & CC2420_STATUS_TX_ACTIVE ) {
          congestion = FALSE;
        }
      }
      
      call CSN.set();
      // DEBUG: on telosb SFD is connected to Pin P4.1
      //if (!congestion) {while (!(P4IN & 0x02)) ;  P6OUT &= ~0x80;}

      if (congestion){
        return FAIL; // channel busy
      } else {
        m_state = S_SFD;
        m_frame->metadata->timestamp = IEEE154_INVALID_TIMESTAMP; // pessimistic
        call BackoffAlarm.start(CC2420_ABORT_PERIOD); 
        return SUCCESS;
      }
    }
  }
  
  /**
   * The CaptureSFD event is actually an interrupt from the capture pin
   * which is connected to timing circuitry and timer modules.  This
   * type of interrupt allows us to see what time (being some relative value)
   * the event occurred, and lets us accurately timestamp our packets.  This
   * allows higher levels in our system to synchronize with other nodes.
   *
   * Because the SFD events can occur so quickly, and the interrupts go
   * in both directions, we set up the interrupt but check the SFD pin to
   * determine if that interrupt condition has already been met - meaning,
   * we should fall through and continue executing code where that interrupt
   * would have picked up and executed had our microcontroller been fast enough.
   */
  async event void CaptureSFD.captured( uint16_t time ) {
    //P2OUT &= ~0x40;      // debug: P2.6 low
    atomic {
      switch( m_state ) {
        
      case S_SFD:
        m_state = S_EFD;
        sfdHigh = TRUE;
        call CaptureSFD.captureFallingEdge();
        // timestamp denotes time of first bit (chip) of PPDU on the channel
        // offset: -10 for 5 bytes (preamble+SFD)
        if (call CaptureTime.convert(time, &m_timestamp, -10) == SUCCESS) 
          m_frame->metadata->timestamp = call ReferenceTime.toLocalTime(&m_timestamp);
        call BackoffAlarm.stop();
        if ( call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      case S_EFD:
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        signal CC2420Tx.transmissionStarted(m_frame);
        if ( (m_frame->header->mhr)[0] & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          // wait for the ACK
          m_state = S_ACK_WAIT;
          alarmStartTime = call BackoffAlarm.getNow();
          // we need to have *completely* received the ACK, 32+22 symbols
          // should theroretically be enough, but there can be delays in 
          // servicing the FIFOP interrupt, so we use 100 symbols here
          call BackoffAlarm.start( 100 ); 
        } else {
          signalDone(FALSE, SUCCESS);
        }
        
        if ( !call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      default:
        // The CC2420 is in receive mode.
        if ( !m_receiving ) {
          sfdHigh = TRUE;
          call CaptureSFD.captureFallingEdge();
          call CaptureTime.convert(time, &m_timestamp, -10);
          call CC2420Receive.sfd( &m_timestamp );
          m_receiving = TRUE;
          m_prev_time = time;
          if ( call SFD.get() ) {
            // wait for the next interrupt before moving on
            return;
          }
          // if we move on, then the timestamp will be invalid!
        }
        
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        m_receiving = FALSE;
        if (!call CaptureTime.isValidTimestamp(m_prev_time, time))
          call CC2420Receive.sfd_dropped();
        break;
      
      }
    }
  }
   
  async command bool CC2420Tx.cca()
  {
    return call CCA.get();
  }

  async command error_t CC2420Tx.modify( uint8_t offset, uint8_t* buf, uint8_t len ) 
  {
    call CSN.set();
    call CSN.clr();
    call TXFIFO_RAM.write( offset, buf, len );
    call CSN.set();
    return SUCCESS;
  }
  
  async command void CC2420Tx.lockChipSpi()
  {
    abortSpiRelease = TRUE;
  }

  async command void CC2420Tx.unlockChipSpi()
  {
    abortSpiRelease = FALSE;
  }

  async event void ChipSpiResource.releasing() {
    if(abortSpiRelease) {
      call ChipSpiResource.abortRelease();
    }
  }
  
  
  /***************** CC2420Receive Events ****************/
  /**
   * If the packet we just received was an ack that we were expecting,
   * our send is complete.
   */
  async event void CC2420Receive.receive(  uint8_t type, message_t *ackFrame ){
    atomic {
      if ( type == IEEE154_TYPE_ACK ) {
        if (  m_state == S_ACK_WAIT && 
            m_frame->header->mhr[2] == ((ieee154_header_t*) ackFrame->header)->mhr[2] ) { // compare seqno
          call BackoffAlarm.stop();
          signalDone(( ((ieee154_header_t*) ackFrame->header)->mhr[0] & 0x10) ? TRUE: FALSE, SUCCESS);
        }
      }
    }
  }
  
  async event void BackoffAlarm.fired() {
    atomic {
      switch( m_state ) {

        case S_SFD:
        case S_EFD: // fall through
          // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
          // jiffies. Assume something is wrong.
          atomic {
            call CSN.set();
            call CSN.clr();
            call SFLUSHTX.strobe();
            call CSN.set();
          }
          signalDone( FALSE, ERETRY );
          break;

        case S_ACK_WAIT:
          /*        signalDone( SUCCESS );*/
          signalDone( FALSE, ENOACK );
          break;


        default:
          break;
      }
    }
  }

  void signalDone( bool ackFramePending, error_t err ) {
    ieee154_timestamp_t *txTime = &m_timestamp;
    atomic m_state = S_STARTED;
    if (m_frame->metadata->timestamp == IEEE154_INVALID_TIMESTAMP)
      txTime = NULL;
    signal CC2420Tx.sendDone( m_frame, txTime, ackFramePending, err );
    call ChipSpiResource.attemptRelease();
  }

  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, 
      error_t error ) {
  }
}

