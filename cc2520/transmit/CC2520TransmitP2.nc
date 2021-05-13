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
 * @version $Revision: 1.9 $ $Date: 2008/07/11 19:21:23 $
 */

#include "CC2520.h"
#include "CC2520TimeSyncMessage.h"
#include "crc.h"
#include "message.h"
#include "printf.h"

module CC2520TransmitP @safe() {

  provides interface Init;
  provides interface StdControl;
  provides interface CC2520Transmit as Send;
  provides interface RadioBackoff;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;
  
  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface CC2520Packet;
  uses interface CC2520PacketBody;
  uses interface PacketTimeStamp<T32khz,uint32_t>;
  uses interface PacketTimeSyncOffset;
  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

  uses interface Resource as SpiResource;
  uses interface ChipSpiResource;
  uses interface CC2520Fifo as TXFIFO;
  uses interface CC2520Ram as TXFIFO_RAM;
  uses interface CC2520Register as TXPOWER;
  uses interface CC2520Strobe as SNOP;
  uses interface CC2520Strobe as STXON;
  uses interface CC2520Strobe as STXONCCA;
  uses interface CC2520Strobe as SFLUSHTX;
  //uses interface CC2520Register as MDMCTRL1;

  uses interface CC2520Receive;
  
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_LOAD,
    S_SAMPLE_CCA,
    S_BEGIN_TRANSMIT,
    S_SFD,
    S_EFD,
    S_ACK_WAIT,
    S_CANCEL,
  } cc2520_transmit_state_t;

  // This specifies how many jiffies the stack should wait after a
  // TXACTIVE to receive an SFD interrupt before assuming something is
  // wrong and aborting the send. There seems to be a condition
  // on the micaZ where the SFD interrupt is never handled.
  enum {
    CC2520_ABORT_PERIOD = 320
  };
  
  norace message_t * ONE_NOK m_msg;
  
  norace bool m_cca;
  
  norace uint8_t m_tx_power;
  
  cc2520_transmit_state_t m_state = S_STOPPED;
  
  bool m_receiving = FALSE;
  
  uint16_t m_prev_time;
  
  /** Byte reception/transmission indicator */
  bool sfdHigh;
  
  /** Let the CC2420 driver keep a lock on the SPI while waiting for an ack */
  bool abortSpiRelease;
  
  /** Total CCA checks that showed no activity before the NoAck LPL send */
  norace int8_t totalCcaChecks;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;
  

  /***************** Prototypes ****************/
  error_t send( message_t * ONE p_msg, bool cca );
  error_t resend( bool cca );
  void loadTXFIFO();
  void attemptSend();
  void congestionBackoff();
  error_t acquireSpiResource();
  error_t releaseSpiResource();
  void signalDone( error_t err );
  
  
  /***************** Init Commands *****************/
  command error_t Init.init() {
    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
    return SUCCESS;
  }

  /***************** StdControl Commands ****************/
  command error_t StdControl.start() {
    atomic {
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
      abortSpiRelease = FALSE;
      m_tx_power = 0;
      printf("\n Transmit init..");
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call BackoffTimer.stop();
      call CaptureSFD.disable();
      call SpiResource.release();  // REMOVE
      call CSN.set();
	printf("\n Transmit stoped..");
    }
    return SUCCESS;
  }


  /**************** Send Commands ****************/
  async command error_t Send.send( message_t* ONE p_msg, bool useCca ) {
    return send( p_msg, useCca );
  }

  async command error_t Send.resend(bool useCca) {
    return resend( useCca );
  }

  async command error_t Send.cancel() {
    atomic {
      switch( m_state ) {
      case S_LOAD:
      case S_SAMPLE_CCA:
      case S_BEGIN_TRANSMIT:
        m_state = S_CANCEL;
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
	printf("\n Send.modify");
    return SUCCESS;
  }
  
  /***************** Indicator Commands ****************/
  command bool EnergyIndicator.isReceiving() {
    return !(call CCA.get());
  }
  
  command bool ByteIndicator.isReceiving() {
    bool high;
    atomic high = sfdHigh;
    return high;
  }
  

  /***************** RadioBackoff Commands ****************/
  /**
   * Must be called within a requestInitialBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setInitialBackoff(uint16_t backoffTime) {
    myInitialBackoff = backoffTime + 1;
  }
  
  /**
   * Must be called within a requestCongestionBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setCongestionBackoff(uint16_t backoffTime) {
    myCongestionBackoff = backoffTime + 1;
  }
  
  async command void RadioBackoff.setCca(bool useCca) {
  }
  
  
  inline uint32_t time16to32(uint16_t time, uint32_t recent_time)
  {
    if ((recent_time&0xFFFF)<time)
      return ((recent_time-0x10000UL)&0xFFFF0000UL)|time;
    else
      return (recent_time&0xFFFF0000UL)|time;
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
    uint32_t time32 = time16to32(time, call BackoffTimer.getNow());
    printf("\n Sfd Captured");
    atomic {
      switch( m_state ) {
        
      case S_SFD:
        m_state = S_EFD;
        sfdHigh = TRUE;
        call CaptureSFD.captureFallingEdge();
        call PacketTimeStamp.set(m_msg, time32);
        if (call PacketTimeSyncOffset.isSet(m_msg)) {
           nx_uint8_t *taddr = m_msg->data + (call PacketTimeSyncOffset.get(m_msg) - sizeof(cc2520_header_t));
           timesync_radio_t *timesync = (timesync_radio_t*)taddr;
           // set timesync event time as the offset between the event time and the SFD interrupt time (TEP  133)
           *timesync  -= time32;
           call CSN.clr();
           call TXFIFO_RAM.write( call PacketTimeSyncOffset.get(m_msg), (uint8_t*)timesync, sizeof(timesync_radio_t) );
           call CSN.set();
		 printf("\n S_SFD");
        }

        if ( (call CC2520PacketBody.getHeader( m_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          // This is an ack packet, don't release the chip's SPI bus lock.
          abortSpiRelease = TRUE;
        }
        releaseSpiResource();
	printf("\n Stop Backoff Timer");
        call BackoffTimer.stop();

        
        if ( ( ( (call CC2520PacketBody.getHeader( m_msg ))->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7 ) == IEEE154_TYPE_DATA ) {
          call PacketTimeStamp.set(m_msg, time32);
        }
        
        if ( call SFD.get() ) {
	   printf("\n S_SFD1");
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      case S_EFD:
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        
        if ( (call CC2520PacketBody.getHeader( m_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          m_state = S_ACK_WAIT;
          call BackoffTimer.start( CC2520_ACK_WAIT_DELAY );
        } else {
          signalDone(SUCCESS);
        }
        printf("\n S_EFD.get1");
        if ( !call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      default:
        if ( !m_receiving ) {
          sfdHigh = TRUE;
          call CaptureSFD.captureFallingEdge();
          call CC2520Receive.sfd( time32 );
          m_receiving = TRUE;
          m_prev_time = time;
           printf("\n Sfd default");
          if ( call SFD.get() ) {
            // wait for the next interrupt before moving on
            return;
          }
        }
        
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();
        m_receiving = FALSE;
        if ( time - m_prev_time < 10 ) {
          call CC2520Receive.sfd_dropped();
	  if (m_msg)
	    call PacketTimeStamp.clear(m_msg);
        }
        break;
      
      }
    }
  }

  /***************** ChipSpiResource Events ****************/
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
  async event void CC2520Receive.receive( uint8_t type, message_t* ack_msg ) {
    cc2520_header_t* ack_header;
    cc2520_header_t* msg_header;
    cc2520_metadata_t* msg_metadata;
    uint8_t* ack_buf;
    uint8_t length;

    if ( type == IEEE154_TYPE_ACK && m_msg) {
      ack_header = call CC2520PacketBody.getHeader( ack_msg );
      msg_header = call CC2520PacketBody.getHeader( m_msg );

      
      if ( m_state == S_ACK_WAIT && msg_header->dsn == ack_header->dsn ) {
        call BackoffTimer.stop();
        
        msg_metadata = call CC2520PacketBody.getMetadata( m_msg );
        ack_buf = (uint8_t *) ack_header;
        length = ack_header->length;
        
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
      
    case S_CANCEL:
      call CSN.clr();
      call SFLUSHTX.strobe();
      call CSN.set();
      releaseSpiResource();
      atomic {
        m_state = S_STARTED;
      }
	
      signal Send.sendDone( m_msg, ECANCEL );
      break;
      
    default:
      releaseSpiResource();
      break;
    }
  }
  
  /***************** TXFIFO Events ****************/
  /**
   * The TXFIFO is used to load packets into the transmit buffer on the
   * chip
   */
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,
                                     error_t error ) {
    printf("\n TXFIFO writeDone");
    call CSN.set();
    if ( m_state == S_CANCEL ) {
      atomic {
        call CSN.clr();
        call SFLUSHTX.strobe();
        call CSN.set();
	printf("\n TX FIFO SFLUSH");
      }
      releaseSpiResource();
      m_state = S_STARTED;
      signal Send.sendDone( m_msg, ECANCEL );
      
    } else if ( !m_cca ) {
      atomic {
        m_state = S_BEGIN_TRANSMIT;
      }
      attemptSend();
	printf("\n TX FIFO attempt send");
      
    } else {
      releaseSpiResource();
      atomic {
        m_state = S_SAMPLE_CCA;
      }
      
      signal RadioBackoff.requestInitialBackoff(m_msg);
	printf("\n TX FIFO back offTimer");
        call BackoffTimer.start(myInitialBackoff);
    }
  }

  
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, 
      error_t error ) {
  }
  
  
  /***************** Timer Events ****************/
  /**
   * The backoff timer is mainly used to wait for a moment before trying
   * to send a packet again. But we also use it to timeout the wait for
   * an acknowledgement, and timeout the wait for an SFD interrupt when
   * we should have gotten one.
   */
  async event void BackoffTimer.fired() {
    atomic {
      switch( m_state ) {
        
      case S_SAMPLE_CCA : 
        // sample CCA and wait a little longer if free, just in case we
        // sampled during the ack turn-around window
        if ( call CCA.get() ) {
          m_state = S_BEGIN_TRANSMIT;
          call BackoffTimer.start( CC2520_TIME_ACK_TURNAROUND );
           printf("\n Backoff Timer");  
        } else {
          congestionBackoff();
        }
        break;
        
      case S_BEGIN_TRANSMIT:
      case S_CANCEL:
        if ( acquireSpiResource() == SUCCESS ) {
          attemptSend();
		printf("\n backoff_attempt Send"); 
        }
        break;
        
      case S_ACK_WAIT:
        signalDone( SUCCESS );
		printf("\n attempt Sucess"); 
        break;

      case S_SFD:
        // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
        // jiffies. Assume something is wrong.
        call SFLUSHTX.strobe();
        call CaptureSFD.captureRisingEdge();
        releaseSpiResource();
        signalDone( ERETRY );
	 printf("\n Backoff S_SFD");  
        break;

      default:
        break;
      }
    }
  }
      
  /***************** Functions ****************/
  /**
   * Set up a message to be sent. First load it into the outbound tx buffer
   * on the chip, then attempt to send it.
   * @param *p_msg Pointer to the message that needs to be sent
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  error_t send( message_t* ONE p_msg, bool cca ) {
    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }
      
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      
      m_state = S_LOAD;
      m_cca = cca;
      m_msg = p_msg;
      totalCcaChecks = 0;
    }
    
    if ( acquireSpiResource() == SUCCESS ) {
	
      printf("\n LoadTXFIFO");
      loadTXFIFO();
	 
    }

    return SUCCESS;
  }
  
  /**
   * Resend a packet that already exists in the outbound tx buffer on the
   * chip
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  error_t resend( bool cca ) {

    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }
      
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      
      m_cca = cca;
      m_state = cca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
      totalCcaChecks = 0;
    }
    
    if(m_cca) {
      signal RadioBackoff.requestInitialBackoff(m_msg);
      call BackoffTimer.start( myInitialBackoff );
      
    } else if ( acquireSpiResource() == SUCCESS ) {
      attemptSend();
    }
    
    return SUCCESS;
  }
  
  /**
   * Attempt to send the packet we have loaded into the tx buffer on 
   * the radio chip.  The STXONCCA will send the packet immediately if
   * the channel is clear.  If we're not concerned about whether or not
   * the channel is clear (i.e. m_cca == FALSE), then STXON will send the
   * packet without checking for a clear channel.
   *
   * If the packet didn't get sent, then congestion == TRUE.  In that case,
   * we reset the backoff timer and try again in a moment.
   *
   * If the packet got sent, we should expect an SFD interrupt to take
   * over, signifying the packet is getting sent.
   */
  void attemptSend() {
    uint8_t status;
    bool congestion = TRUE;
    printf("\n void attemptSend");
    atomic {
      if (m_state == S_CANCEL) {
	call CSN.set();
	call CSN.clr();
        call SFLUSHTX.strobe();
        releaseSpiResource();
        call CSN.set();
        m_state = S_STARTED;
        printf("\n S_CANCEL");
        signal Send.sendDone( m_msg, ECANCEL );
        return;
      }
      
      
      call CSN.clr();

      status = m_cca ? call STXONCCA.strobe() : call STXON.strobe();
      call CSN.set();
      call CSN.clr();
      if ( !( status & CC2520_STATUS_TX_ACTIVE ) ) {
        status = call SNOP.strobe();
        if ( status & CC2520_STATUS_TX_ACTIVE ) {
          congestion = FALSE;
        }
      }
      
      m_state = congestion ? S_SAMPLE_CCA : S_SFD;
      call CSN.set();
    }
    
      call CSN.clr();
	printf("\n Tx status: %x",(call SNOP.strobe()));
      call CSN.set();
    if ( congestion ) {
      totalCcaChecks = 0;
      releaseSpiResource();
      congestionBackoff();
    } else {
      call BackoffTimer.start(CC2520_ABORT_PERIOD);
	printf("\n Start BackoffTimer");
    }
  }
  
  
  /**  
   * Congestion Backoff
   */
  void congestionBackoff() {
    atomic {
      signal RadioBackoff.requestCongestionBackoff(m_msg);
      call BackoffTimer.start(myCongestionBackoff);
    }
  }
  
  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
  }

  error_t releaseSpiResource() {
    call SpiResource.release();
    return SUCCESS;
  }


  /** 
   * Setup the packet transmission power and load the tx fifo buffer on
   * the chip with our outbound packet.  
   *
   * Warning: the tx_power metadata might not be initialized and
   * could be a value other than 0 on boot.  Verification is needed here
   * to make sure the value won't overstep its bounds in the TXCTRL register
   * and is transmitting at max power by default.
   *
   * It should be possible to manually calculate the packet's CRC here and
   * tack it onto the end of the header + payload when loading into the TXFIFO,
   * so the continuous modulation low power listening strategy will continually
   * deliver valid packets.  This would increase receive reliability for
   * mobile nodes and lossy connections.  The crcByte() function should use
   * the same CRC polynomial as the CC2420's AUTOCRC functionality.
   */
  void loadTXFIFO() {
    cc2520_header_t* header = call CC2520PacketBody.getHeader( m_msg );
    uint8_t tx_power = (call CC2520PacketBody.getMetadata( m_msg ))->tx_power;

    if ( !tx_power ) {
      tx_power = CC2520_DEF_RFPOWER;
    }
    
    call CSN.clr();
    
    if ( m_tx_power != tx_power ) {
     /* call TXPOWER.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
                         ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
                         ( 1 << CC2420_TXCTRL_RESERVED ) |
                         ( (tx_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );*/
        call TXPOWER.write( (tx_power));
	printf("\n Transmit Power :  %x",tx_power );
    }
    
    m_tx_power = tx_power;
    
    {
      uint8_t tmpLen __DEPUTY_UNUSED__ = header->length - 1;
      call TXFIFO.write(TCAST(uint8_t * COUNT(tmpLen), header), header->length - 1);
    }
  }
  
  void signalDone( error_t err ) {
    atomic m_state = S_STARTED;
    abortSpiRelease = FALSE;
    
    call ChipSpiResource.attemptRelease();
     printf("\n msg" );
    signal Send.sendDone( m_msg, err );
  }
}

