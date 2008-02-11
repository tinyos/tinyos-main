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
 * @version $Revision: 1.1 $ $Date: 2008-02-11 17:41:25 $
 */

module CC2420TransmitP {

  provides interface Init;
  provides interface StdControl;

 provides interface Sendframe;

  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;

  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

  uses interface Resource as SpiResource;
  uses interface ChipSpiResource;
  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Ram as TXFIFO_RAM;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as STXONCCA;
  uses interface CC2420Strobe as SFLUSHTX;
  uses interface CC2420Register as MDMCTRL1;


  uses interface Leds;
}

implementation {

  /** Byte reception/transmission indicator */
  bool sfdHigh;


  /***************** Prototypes ****************/

  void attemptSend();

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
	}
	
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic {

      call CaptureSFD.disable();
      call SpiResource.release();  // REMOVE
      call CSN.set();
    }
    return SUCCESS;
  }
  
  
/**************** Send Commands ****************/

	async command error_t Sendframe.send(uint8_t* frame, uint8_t frame_length)
	{
		//printfUART("Send Command\n", ""); 
    
		if ( acquireSpiResource() == SUCCESS ) {
			call CSN.clr();
		
			call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
							 ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
							 ( 1 << CC2420_TXCTRL_RESERVED ) |
							 ( (CC2420_DEF_RFPOWER & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );
	
		
			call TXFIFO.write( (uint8_t*)frame, frame_length);

		}
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
 
  }

  /***************** ChipSpiResource Events ****************/
  async event void ChipSpiResource.releasing() {
  }
  

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
   
      attemptSend();
     
  }
  
  /***************** TXFIFO Events ****************/
  /**
   * The TXFIFO is used to load packets into the transmit buffer on the
   * chip
   */
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,error_t error ) 
  {

    call CSN.set();
	attemptSend();
     
  }

  
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len,error_t error ) {
  }
  
      
  /***************** Functions ****************/
  
 
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
  


   //printfUART("attempt Send Command\n", ""); 

    atomic {
	
      
      call CSN.clr();

       call STXON.strobe();
     
      call CSN.set();
	  
    releaseSpiResource();
	}
    

	signalDone(SUCCESS);
		
  }
  
  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
   
    //printfUART("acquire spi\n", ""); 
	if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
  }

  error_t releaseSpiResource() {
    call SpiResource.release();
    return SUCCESS;
  }

    
  void signalDone( error_t err ) {

    call ChipSpiResource.attemptRelease();
    signal Sendframe.sendDone( err );
  }

}

