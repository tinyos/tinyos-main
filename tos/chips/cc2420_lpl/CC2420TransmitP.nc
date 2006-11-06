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
 * @version $Revision: 1.2 $ $Date: 2006-11-06 11:57:09 $
 */
 
#include "IEEE802154.h"

module CC2420TransmitP {

  provides interface Init;
  provides interface AsyncStdControl;
  provides interface CC2420Transmit as Send;
  provides interface CsmaBackoff;
  provides interface RadioTimeStamping as TimeStamp;
  provides interface CC2420Cca;
  
  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;

#ifdef PLATFORM_MICAZ
  uses interface Timer<TMilli> as WatchdogTimer;
#endif

  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Ram as TXFIFO_RAM;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as STXONCCA;
  uses interface CC2420Strobe as SFLUSHTX;

  uses interface CC2420Receive;
  uses interface Leds;

}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_LOAD,
    S_SAMPLE_CCA,
    S_SAMPLE_CCA_ONLY,
    S_BEGIN_TRANSMIT,
    S_SFD,
    S_EFD,
    S_ACK_WAIT,
    S_CANCEL,
  } cc2420_transmit_state_t;

  // This specifies how many jiffies the stack should wait after a
  // TXACTIVE to receive an SFD interrupt before assuming something is
  // wrong and aborting the send. There seems to be a condition
  // on the micaZ where the SFD interrupt is never handled.
  enum {
    CC2420_ABORT_PERIOD = 320
  };
  
  norace message_t* m_msg;
  
  norace bool m_cca;
  
  norace uint8_t m_tx_power;
  
  cc2420_transmit_state_t m_state = S_STOPPED;
  
  bool m_receiving = FALSE;
  
  uint16_t m_prev_time;


  /***************** Prototypes ****************/
  void loadTXFIFO();
  void attemptSend();
  cc2420_header_t* getHeader( message_t* msg );
  cc2420_metadata_t* getMetadata( message_t* msg );
  void startBackoffTimer(uint16_t time);
  void stopBackoffTimer();
  error_t acquireSpiResource();
  void releaseSpiResource();
  void signalDone(error_t err);
  void congestionBackoff();
  error_t send( message_t* p_msg, bool cca );
  error_t resend( bool cca );
  
#ifdef PLATFORM_MICAZ
  task void startWatchdogTimer();
  task void stopWatchdogTimer();
#endif


  /***************** Init Commands ****************/
  command error_t Init.init() {
    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
    return SUCCESS;
  }

  /***************** AsyncStdControl Commands ****************/
  async command error_t AsyncStdControl.start() {
    atomic {
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
      m_tx_power = 0;
    }
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      stopBackoffTimer();
      call CaptureSFD.disable();
    }
    return SUCCESS;
  }

  /***************** Send Commands ****************/
  async command error_t Send.sendCCA( message_t* p_msg ) {
    return send( p_msg, TRUE );
  }

  async command error_t Send.send( message_t* p_msg ) {
    return send( p_msg, FALSE );
  }

  async command error_t Send.resendCCA() {
    return resend( TRUE );
  }

  async command error_t Send.resend() {
    return resend( FALSE );
  }

  async command error_t Send.cancel() {
    stopBackoffTimer();

    atomic {
      switch( m_state ) {
      case S_LOAD:
        m_state = S_CANCEL;
        break;
        
      case S_SAMPLE_CCA: 
      case S_BEGIN_TRANSMIT:
        m_state = S_STARTED;
        break;
      
      default:
        // cancel not allowed while radio is busy transmitting
        return FAIL;
      }
    }

    return SUCCESS;
  }

  async command error_t Send.modify( uint8_t offset, uint8_t* buf, 
                                     uint8_t len ) {
    call CSN.clr();
    call TXFIFO_RAM.write( offset, buf, len );
    call CSN.set();
    return SUCCESS;
  }

  /***************** CC2420Cca Commands ****************/
  /**
   * @return TRUE if the CCA pin shows a clear channel
   */
  command bool CC2420Cca.isChannelClear() {
    return call CCA.get();
  }
  
  /***************** CaptureSFD Events ****************/
  async event void CaptureSFD.captured( uint16_t time ) {

    atomic {
      switch( m_state ) {
        
      case S_SFD:
        call CaptureSFD.captureFallingEdge();
        signal TimeStamp.transmittedSFD( time, m_msg );
        releaseSpiResource();
        stopBackoffTimer();
        m_state = S_EFD;
        if ( ( ( getHeader( m_msg )->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7 ) == 
             IEEE154_TYPE_DATA )
          getMetadata( m_msg )->time = time;
        if ( call SFD.get() )
          break;
        
      case S_EFD:
        call CaptureSFD.captureRisingEdge();
        if ( getHeader( m_msg )->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          m_state = S_ACK_WAIT;
          startBackoffTimer( CC2420_ACK_WAIT_DELAY );
        }
        else {
          signalDone(SUCCESS);
        }
        if ( !call SFD.get() )
          break;
        
      default:
        if ( !m_receiving ) {
          call CaptureSFD.captureFallingEdge();
          signal TimeStamp.receivedSFD( time );
          call CC2420Receive.sfd( time );
          m_receiving = TRUE;
          m_prev_time = time;
          if ( call SFD.get() )
            return;
        }
        if ( m_receiving ) {
          call CaptureSFD.captureRisingEdge();
          m_receiving = FALSE;
          if ( time - m_prev_time < 10 )
            call CC2420Receive.sfd_dropped();
        }
        break;
      
      }
    }
  }

  /***************** CC2420Receive Events ****************/
  async event void CC2420Receive.receive( uint8_t type, message_t* ack_msg ) {

    if ( type == IEEE154_TYPE_ACK ) {
      cc2420_header_t* ack_header = getHeader( ack_msg );
      cc2420_header_t* msg_header = getHeader( m_msg );
      cc2420_metadata_t* msg_metadata = getMetadata( m_msg );
      uint8_t* ack_buf = (uint8_t*)ack_header;
      uint8_t length = ack_header->length;
      
      if ( m_state == S_ACK_WAIT &&
           msg_header->dsn == ack_header->dsn ) {
        stopBackoffTimer();
        msg_metadata->ack = TRUE;
        msg_metadata->rssi = ack_buf[ length - 1 ];
        msg_metadata->lqi = ack_buf[ length ] & 0x7f;
        signalDone(SUCCESS);
      }
    }
  }

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    uint8_t cur_state;

    atomic {
      cur_state = m_state;
    }

    switch( cur_state ) {
      case S_LOAD: 
        loadTXFIFO(); 
        break;
      
      case S_BEGIN_TRANSMIT: 
        attemptSend(); 
        break;
      
      default: 
        releaseSpiResource(); 
        break;
    }
  }

  /***************** TXFIFO Events ****************/
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, 
      error_t error ) {
  }


  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,
                                     error_t error ) {
    call CSN.set();

    if ( m_state == S_CANCEL ) {
      m_state = S_STARTED;
    }
    else if ( !m_cca ) {
      m_state = S_BEGIN_TRANSMIT;
      attemptSend();
    }
    else {
      releaseSpiResource();
      m_state = S_SAMPLE_CCA;
      startBackoffTimer( signal CsmaBackoff.initial( m_msg ) + 1);
    }
  }
  
  /***************** Timer Events ****************/
  async event void BackoffTimer.fired() {

    atomic {
      switch( m_state ) {        
      case S_SAMPLE_CCA :
        // sample CCA and wait a little longer if free, just in case we
        // sampled during the ack turn-around window
        if ( call CCA.get() ) {
          m_state = S_BEGIN_TRANSMIT;
          startBackoffTimer( CC2420_TIME_ACK_TURNAROUND );
        }
        else {
          congestionBackoff();
        }
        break;
        
      case S_BEGIN_TRANSMIT :
        if ( acquireSpiResource() == SUCCESS )
          attemptSend();
        break;
        
      case S_ACK_WAIT :
        signalDone( SUCCESS );
        break;
        
#ifdef PLATFORM_MICAZ
      case S_SFD:
        // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
        // jiffies. Assume something is wrong.
        call SFLUSHTX.strobe();
        call CaptureSFD.disable();
        call CaptureSFD.captureRisingEdge();
        signalDone( ERETRY );
        break;
#endif
      default:
        break;
      }
    }
  }
  
    
#ifdef PLATFORM_MICAZ
  event void WatchdogTimer.fired() {
    atomic m_state = S_STARTED;
    releaseSpiResource();
    signalDone(ERETRY);
  }
#endif
  
  
  /***************** Functions ****************/
  /**
   * Send a message with or without CCA
   */
  error_t send( message_t* p_msg, bool cca ) {
    atomic {
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      
      m_state = S_LOAD;
      m_cca = cca;
      m_msg = p_msg;
    }

#ifdef PLATFORM_MICAZ
    post startWatchdogTimer();
#endif

    if ( acquireSpiResource() == SUCCESS ) {
      loadTXFIFO();
    }
    // Else, we wait for the SpiResource.granted event..
    
    return SUCCESS;
  }
  
  /**
   * Resend a message with or without CCA
   */
  error_t resend( bool cca ) {
    atomic {
      if ( m_state != S_STARTED )
        return FAIL;
      m_cca = cca;
      m_state = cca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
    }

#ifdef PLATFORM_MICAZ
    post startWatchdogTimer();
#endif

    if ( m_cca ) {
      startBackoffTimer( signal CsmaBackoff.initial( m_msg ) );
    }
    else if ( acquireSpiResource() == SUCCESS ) {
      attemptSend();
    }
    
    return SUCCESS;
  }
  
  /**
   * Attempt to send a message
   */
  void attemptSend() {
    uint8_t status;
    bool congestion = TRUE;

    call CSN.clr();

    status = m_cca ? call STXONCCA.strobe() : call STXON.strobe();
    if ( !( status & CC2420_STATUS_TX_ACTIVE ) ) {
      status = call SNOP.strobe();
      if ( status & CC2420_STATUS_TX_ACTIVE )
        congestion = FALSE;
    }
    atomic m_state = congestion ? S_SAMPLE_CCA : S_SFD;
    
    call CSN.set();

    if ( congestion ) {
      releaseSpiResource();
      congestionBackoff();
    }
#ifdef PLATFORM_MICAZ
    else {
      startBackoffTimer(CC2420_ABORT_PERIOD);
    }
#endif
  }
  
  
  /**
   * Get the CC2420 message header
   */
  cc2420_header_t* getHeader( message_t* msg ) {
    return (cc2420_header_t*)( msg->data - sizeof( cc2420_header_t ) );
  }

  /**
   * Get the CC2420 message metadata
   */
  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }
  
#ifdef PLATFORM_MICAZ
  /**
   * Start the watchdog timer
   */
  task void startWatchdogTimer() {
    call WatchdogTimer.startOneShot(50);
  }
  
  /**
   * Stop the watchdog timer
   */
  task void stopWatchdogTimer() {
    call WatchdogTimer.stop();
  }
#endif
  
  /**
   * Start the backoff timer
   */
  void startBackoffTimer(uint16_t time) {
    call BackoffTimer.start(time);
  }

  /** 
   * Stop the backoff timer
   */
  void stopBackoffTimer() {
    call BackoffTimer.stop();
  }

  /**
   * Acquire the SPI bus resource immediately, or defer it till later
   */
  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
  }

  /**
   * Release the SPI resource
   */
  void releaseSpiResource() {
    call SpiResource.release();
  }

  /**
   * Signal done
   */
  void signalDone( error_t err ) {
    atomic m_state = S_STARTED;

#ifdef PLATFORM_MICAZ
    post stopWatchdogTimer();
#endif

    signal Send.sendDone( m_msg, err );
  }

  /**  
   * Congestion Backoff
   */
  void congestionBackoff() {
    atomic {
      startBackoffTimer(signal CsmaBackoff.congestion( m_msg ) + 1);
    }
  }
  
  /**
   * Load TX FIFO
   */
  void loadTXFIFO() {
    cc2420_header_t* header = getHeader( m_msg );
    uint8_t tx_power = getMetadata( m_msg )->tx_power;
    
    if ( !tx_power )
      tx_power = CC2420_DEF_RFPOWER;
    call CSN.clr();
    if ( m_tx_power != tx_power )
      call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
                         ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
                         ( 1 << CC2420_TXCTRL_RESERVED ) |
                         ( tx_power << CC2420_TXCTRL_PA_LEVEL ) );
    m_tx_power = tx_power;
    call TXFIFO.write( (uint8_t*)header, header->length - 1 );
  }
   
  /***************** Defaults ****************/
  default async event void TimeStamp.transmittedSFD( uint16_t time, message_t* p_msg ) {}
  default async event void TimeStamp.receivedSFD( uint16_t time ) {}

}
