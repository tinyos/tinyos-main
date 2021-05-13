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

#ifdef CC2520_HW_SECURITY
	#define LOW_PRIORITY	0
	#define HIGH_PRIORITY	1
#endif

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
#ifdef CC2520_HW_SECURITY
  uses interface CC2520Ram as TXFRAME;
  uses interface SpiByte;
  uses interface CC2520Key;
  uses interface CC2520Ram as TXNonce;
#endif
  uses interface CC2520Register as TXPOWER;
  uses interface CC2520Register as EXCFLAG1;
  uses interface CC2520Strobe as SNOP;
  uses interface CC2520Strobe as STXON;
  uses interface CC2520Strobe as STXONCCA;
  uses interface CC2520Strobe as SFLUSHTX;
  //uses interface CC2520Register as MDMCTRL1;

  uses interface CC2520Receive;
  uses interface Leds;
  
#if defined(LCD_DEBUG)
  uses interface Lcd;
#endif
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
    CC2520_ABORT_PERIOD = 200 //320
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
  
  #ifdef CC2520_HW_SECURITY
  uint8_t read_memory[60];
  void encryptTXFIFO(void);
  uint8_t getMICLength(uint8_t SecurityLevel) ;
#endif


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
      //if(PRINTF_ENABLED)	

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
	//if(PRINTF_ENABLED)	
	//printf("\n Transmit stoped..");
    }
    return SUCCESS;
  }


  /**************** Send Commands ****************/
  async command error_t Send.send( message_t* ONE p_msg, bool useCca ) {
	//if(PRINTF_ENABLED)		
	//printf("\n Send_TransmitP");printfflush();
    //return send( p_msg, useCca );
	return send(p_msg,useCca);
  }

  async command error_t Send.resend(bool useCca) {
	//if(PRINTF_ENABLED)		
	//printf("\n Resend_TransmitP");
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
	//if(PRINTF_ENABLED)	
	//printf("\n Send.modify");
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
    //if(PRINTF_ENABLED)	
  //  printf("\n Sfd Captured_Tx");printfflush();

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
		// if(PRINTF_ENABLED)	
		 //printf("\n S_SFD2");
        }

        if ( (call CC2520PacketBody.getHeader( m_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          // This is an ack packet, don't release the chip's SPI bus lock.
          abortSpiRelease = TRUE;
        }
        releaseSpiResource();
	//if(PRINTF_ENABLED)	
	//printf("\n Backoff Timer Stoped");
        call BackoffTimer.stop();

        
        if ( ( ( (call CC2520PacketBody.getHeader( m_msg ))->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7 ) == IEEE154_TYPE_DATA ) {
          call PacketTimeStamp.set(m_msg, time32);
        }
        
        if ( call SFD.get() ) {
	   //if(PRINTF_ENABLED)	
	  // printf("\n SFD.get1");
          break;
        }
        /** Fall Through because the next interrupt was already received */
        
      case S_EFD:
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();

        //printf("\n S_EFD");
        if ( (call CC2520PacketBody.getHeader( m_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          m_state = S_ACK_WAIT;
          call BackoffTimer.start( CC2520_ACK_WAIT_DELAY );
        } else {
//	call Leds.led0Toggle();
          signalDone(SUCCESS);
        }
	//if(PRINTF_ENABLED)	
        //printf("\n S_EFD.get2");
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
	   //if(PRINTF_ENABLED)	
           //printf("\n Sfd default");
          if ( call SFD.get() ) {
            // wait for the next interrupt before moving on
            return;
          }
        }
	//if(PRINTF_ENABLED)	
       // printf("\n Sfd default1");
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
	//if(PRINTF_ENABLED)	
	//printf("\n cc2520 receive_Tx");
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
    //printf("\n spi granted");printfflush();
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
 //   printf("\n TXFIFO writeDone");printfflush();
    call CSN.set();

    if ( m_state == S_CANCEL ) {
      atomic {
        call CSN.clr();
        call SFLUSHTX.strobe();
        call CSN.set();
	//printf("\n TX FIFO SFLUSH");
      }
	
      releaseSpiResource();
      m_state = S_STARTED;
	//printf("\n State Started");
      signal Send.sendDone( m_msg, ECANCEL );
      
    } else if ( !m_cca ) {

      atomic {
        m_state = S_BEGIN_TRANSMIT;
	//printf("\n State Begin");
	
      }

      attemptSend();
	//printf("\n TX FIFO attempt send");
      	//printfflush();
    } else {

      releaseSpiResource();
      atomic {
        m_state = S_SAMPLE_CCA;
	//printf("\n State CCA");
      }
      
      signal RadioBackoff.requestInitialBackoff(m_msg);
	
        call BackoffTimer.start(myInitialBackoff);
	//printf("\n TX FIFO back offTimer");
	//printfflush();
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
         //  printf("\nbackoff_Timer");  
        } else {

          congestionBackoff();
		//printf("\n CCA Congestion");
        }
        break;
        
      case S_BEGIN_TRANSMIT:
      case S_CANCEL:
        if ( acquireSpiResource() == SUCCESS ) {
          attemptSend();
	
		//printf("\n backoff_Send"); 
        }else{
		//printf("\n failed to get the resource");
		//printfflush();
	}
        break;
        
      case S_ACK_WAIT:

        signalDone( SUCCESS );
		//printf("\n attempt Sucess"); printfflush();
        break;

      case S_SFD:
        // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
        // jiffies. Assume something is wrong.
        call SFLUSHTX.strobe();
        call CaptureSFD.captureRisingEdge();
        releaseSpiResource();

        signalDone( ERETRY );
	 //printf("\n S_SFD");  printfflush();
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
	//printf("\n ECANCEL");

        return ECANCEL;
      }
      
      if ( m_state != S_STARTED ) {
	//printf("\n FAIL");
	
        return FAIL;
      }
      
      m_state = S_LOAD;
      m_cca = cca;
      m_msg = p_msg;
      totalCcaChecks = 0;
    }
    

    if ( acquireSpiResource() == SUCCESS ) {

      #ifdef CC2520_HW_SECURITY
	encryptTXFIFO();
      #endif
      loadTXFIFO();

	 
    }else{
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
    //printf("\n ReSend");
    atomic {
      if (m_state == S_CANCEL) {
	call CSN.set();
	call CSN.clr();
        call SFLUSHTX.strobe();
        releaseSpiResource();
        call CSN.set();
        m_state = S_STARTED;
       // printf("\n S_CANCEL");
        signal Send.sendDone( m_msg, ECANCEL );
        return;
      }
     // printf("\n STXONCCA");
      call CSN.set();
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
	//printf("\n Tx status: %x",(call SNOP.strobe()));printfflush();
     call CSN.set();
    if ( congestion ) {
      totalCcaChecks = 0;
      releaseSpiResource();
      congestionBackoff();
	
    } else {
      call BackoffTimer.start(CC2520_ABORT_PERIOD);
	//printf("\n Start BackoffTimer");printfflush();
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
	//	printf("\nspi error:%d",error);printfflush();
      call SpiResource.request();
    }
    return error;
  }

  error_t releaseSpiResource() {
    call SpiResource.release();
    return SUCCESS;
  }

  #ifdef CC2520_HW_SECURITY

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

  void readFrame()
  {
	uint8_t i;
	cc2520_header_t* header = call CC2520PacketBody.getHeader( m_msg );
	memset(read_memory,0,sizeof(read_memory));
	call CSN.clr();
	call TXFRAME.read(0, read_memory, header->length);
	call CSN.set();	
	//printf("Packet After Encryption\n");
	//for(i=0;i<header->length;i++)
	//	printf("%x\t",read_memory[i]);
	//printfflush();
  }



  void encryptTXFIFO(void) {
	cc2520_header_t* header = call CC2520PacketBody.getHeader( m_msg );
	uint8_t *ptr = (uint8_t *)header;
	//uint32_t frame_counter = header->secHdr.frameCounter;
	uint8_t micLength 	= getMICLength(header->secHdr.secLevel);
	uint8_t encryptLength  = header->length - CC2520_SIZE - micLength;
	uint8_t authLength	= CC2520_SIZE - MAC_FOOTER_SIZE;

	/*
	 * Step1 : Load the frame in the CC2520 RAM with MEMWR instructions
	 */
	
	call CSN.clr();
	call TXFRAME.write(0, ptr,header->length-micLength-1);		
	call CSN.set();

	/*Step 2: Perform the CCM operation on the address the frame was loaded to +1(excluding the length byte)*/
	/*
	 * CCM Instruction:
	 *
	 * CCM(uint8_t p, uint8_t k, uint8_t c, uint8_t n, uint16_t a,uint16_t e,
	 * uint8_t f, uint8_t m)
	 *
	 *  p --> priority (Either 0 or 1)
	 *  k --> Pointer to 128 bit Key Address. The key is stored in reversed byte 
	 * 	  order starting at address 16 * k
	 *  c --> Number of bytes to authenticate and encrypt, typically the frame 
	 *	  payload. Encrypt and authenticate c bytes starting at address a+f. 		 * 	  If c = 0 it will only authenticate, no encryption is
 	 *	  performed
	 *  n --> Pointer to 128 bit concatenation of flags,nonce and counter.Note
	 *	  that this value is stored in reverse byte order.value = addr/16
	 *
	 *  a --> Frame buffer,the whole frame except the length field
	 * 
	 *  e --> Pointer to start of output data.set to 0 for inline authentication/
	 *	  encryption
	 * 
	 *  f --> Authenticate F bytes of plaintext starting at address A.This
	 *	  parameter is also used to calculate the starting address of the c 		 *	  bytes that will be both encrypted and authenticated
	 *   m -->  Mic length
	 *
	 */
	call CSN.clr();
	call SpiByte.write(CC2520_CMD_CCM | HIGH_PRIORITY);
	call SpiByte.write(CC2520_RAM_KEY0/16);
    	call SpiByte.write(encryptLength);
    	call SpiByte.write(CC2520_RAM_TXNONCE/16);
    	call SpiByte.write((HI_UINT16(CC2520_RAM_TXFRAME+1)<<4)|HI_UINT16(0));
    	call SpiByte.write(LO_UINT16(CC2520_RAM_TXFRAME+1));
    	call SpiByte.write(LO_UINT16(0));	//For Inline Security
    	call SpiByte.write(authLength);
    	call SpiByte.write(micLength);
	call CSN.set();
	call CSN.clr();
	while(call SNOP.strobe() & 0x08);
	call CSN.set();

	call CSN.clr();
	call TXFRAME.read(0, (uint8_t *)header, header->length-1);
	call CSN.set();	
	
	/*Step3 :Move the frame to the TXFIFO with the TXBUFCP Instruction*/
	/* Not working this instruction so we are reading directly from RAM
	and writing into FIFO */
	/*call CSN.clr();
	call SpiByte.write(CC2520_CMD_TXBUFCP | HIGH_PRIORITY);	
	call SpiByte.write(header->length-1);	
	call SpiByte.write(HI_UINT16(CC2520_RAM_TXFRAME));
	call SpiByte.write(LO_UINT16(CC2520_RAM_TXFRAME));
	call CSN.set();*/
	/* Wait for the instruction to execute*/	
	/*	
	call CSN.clr();
	while(call SNOP.strobe() & 0x08);
	call CSN.set();
	*/
  }

  event void CC2520Key.setKeyDone(uint8_t status)
  {
  }

  event void CC2520Key.getKeyDone(uint8_t status, uint8_t *ptr)
  {
  }

  #endif
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
	//printf("\n Transmit Power 0 :  %x",tx_power );
    if ( !tx_power ) {
      tx_power = CC2520_DEF_RFPOWER;
      
     // printf("\n Defined Power 0 :  %x",CC2520_DEF_RFPOWER );
    }
    
    call CSN.clr();
    
    if ( m_tx_power != tx_power ) {
     /* call TXPOWER.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
                         ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
                         ( 1 << CC2420_TXCTRL_RESERVED ) |
                         ( (tx_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );*/
        //call TXPOWER.write( (tx_power));
	//printf("\n Transmit Power 1 :  %x",CC2520_DEF_RFPOWER );
	//printf("\n M Transmit Power 2 :  %x",m_tx_power );
    }
    //printf("\n Transmit Power 3 :  %x",tx_power );
   //printf("\n M Transmit Power 4 :  %x",m_tx_power );

    m_tx_power = tx_power;
    
    {
      uint8_t tmpLen __DEPUTY_UNUSED__ = header->length - 1;
      call TXFIFO.write(TCAST(uint8_t * COUNT(tmpLen), header), header->length - 1);
	//printf("\n write in the txfifo");printfflush();
    }
  }
  
  void signalDone( error_t err ) {
    atomic m_state = S_STARTED;
    abortSpiRelease = FALSE;
  //  printf("\n attempting to release chipspi");printfflush();
    call ChipSpiResource.attemptRelease();
    signal Send.sendDone( m_msg, err );
  }
}

