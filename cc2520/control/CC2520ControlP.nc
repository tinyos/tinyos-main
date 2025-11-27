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
 * @author Urs Hunkeler (ReadRssi implementation)
 * @version $Revision: 1.7 $ $Date: 2008/06/24 04:07:28 $
 */

#include "Timer.h"
#include "CC2520.h"

// IEEE 802.15.4 defined constants (2.4 GHz logical channels)
#define MIN_CHANNEL 			    11    // 2405 MHz
#define MAX_CHANNEL                         26    // 2480 MHz
#define CHANNEL_SPACING                     5     // MHz

module CC2520ControlP @safe() {

  provides interface Init;
  provides interface Resource;
  provides interface CC2520Config;
  provides interface CC2520Power;
  provides interface Read<uint16_t> as ReadRssi;

  uses interface Alarm<T32khz,uint32_t> as StartupTimer;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as RSTN;
  uses interface GeneralIO as VREN;
  uses interface GpioInterrupt as InterruptCCA;
  uses interface ActiveMessageAddress;

  uses interface CC2520Ram as PANID;

  uses interface CC2520Register as FSCTRL;
  //uses interface CC2420Register as IOCFG0;
  //uses interface CC2420Register as IOCFG1;

  uses interface CC2520Register as MDMCTRL0;
  uses interface CC2520Register as MDMCTRL1;
  uses interface CC2520Register as RXCTRL;
  uses interface CC2520Register as RSSI;
  
  // Newly Added on 15-11-10 Lijo ******************/

  uses interface CC2520Register as AGCCTRL1;
  uses interface CC2520Register as TXPOWER;
  uses interface CC2520Register as CCACTRL0;
  uses interface CC2520Register as FSCAL1;
  uses interface CC2520Register as FRMCTRL1;

  uses interface CC2520Register as FREQCTRL;

  uses interface CC2520Register as ADCTEST0;
  uses interface CC2520Register as ADCTEST1;
  uses interface CC2520Register as ADCTEST2;

  uses interface CC2520Register as FRMCTRL0;
  uses interface CC2520Register as EXTCLOCK;

  uses interface CC2520Register as GPIOCTRL0;
  uses interface CC2520Register as GPIOCTRL1;
  uses interface CC2520Register as GPIOCTRL2;
  uses interface CC2520Register as GPIOCTRL3;
  uses interface CC2520Register as GPIOCTRL4;
  uses interface CC2520Register as GPIOCTRL5;
  uses interface CC2520Register as GPIOPOLARITY;

  uses interface CC2520Register as FRMFILT0;
  uses interface CC2520Register as FRMFILT1;
  uses interface CC2520Register as FIFOPCTRL;
 

 //*************************************************/
 uses interface CC2520Strobe as SRXON;
  uses interface CC2520Strobe as SRFOFF;
  uses interface CC2520Strobe as SXOSCOFF;
  uses interface CC2520Strobe as SXOSCON;
  uses interface CC2520Strobe as SNOP;

  uses interface Resource as SpiResource;
  uses interface Resource as RssiResource;
  uses interface Resource as SyncResource;

  uses interface Leds;
    uses interface LocalIeeeEui64;
}

implementation {

  typedef enum {
    S_VREG_STOPPED,
    S_VREG_STARTING,
    S_VREG_STARTED,
    S_XOSC_STARTING,
    S_XOSC_STARTED,
  } cc2520_control_state_t;

  uint8_t m_channel;
  
  uint8_t m_tx_power;
  
  uint16_t m_pan;
  
  // temporary LIjo..
  uint16_t *data1;

  uint16_t m_short_addr;

   ieee_eui64_t m_ext_addr;
  
  bool m_sync_busy;
  
  /** TRUE if acknowledgments are enabled */
  bool autoAckEnabled;
  
  /** TRUE if acknowledgments are generated in hardware only */
  bool hwAutoAckDefault;
  
  /** TRUE if software or hardware address recognition is enabled */
  bool addressRecognition;
  
  /** TRUE if address recognition should also be performed in hardware */
  bool hwAddressRecognition;
  
  norace cc2520_control_state_t m_state = S_VREG_STOPPED;
  
  /***************** Prototypes ****************/

  void writeFreqctrl();
  void Write_Default_Registers_Value();
  void writeId();

  task void sync();
  task void syncDone();
    
  /***************** Init Commands ****************/
  command error_t Init.init() {
      int i, t;
    call CSN.makeOutput();
    call RSTN.makeOutput();
    call VREN.makeOutput();
    
    m_short_addr = call ActiveMessageAddress.amAddress();
    m_pan = call ActiveMessageAddress.amGroup();
    m_tx_power = CC2520_DEF_RFPOWER;
    m_channel = CC2520_DEF_CHANNEL;
        m_ext_addr = call LocalIeeeEui64.getId();
	    for (i = 0; i < 4; i++) {
      t = m_ext_addr.data[i];
      m_ext_addr.data[i] = m_ext_addr.data[7-i];
      m_ext_addr.data[7-i] = t;
    }

    
#if defined(CC2520_NO_ADDRESS_RECOGNITION)
    addressRecognition = FALSE;
#else
    addressRecognition = TRUE;
#endif
    
#if defined(CC2520_HW_ADDRESS_RECOGNITION)
    hwAddressRecognition = TRUE;
#else
    hwAddressRecognition = FALSE;
#endif
    
    
#if defined(CC2520_NO_ACKNOWLEDGEMENTS)
    autoAckEnabled = FALSE;
#else
    autoAckEnabled = TRUE;
#endif
    
#if defined(CC2520_HW_ACKNOWLEDGEMENTS)
    hwAutoAckDefault = TRUE;
    hwAddressRecognition = TRUE;
#else
    hwAutoAckDefault = FALSE;
#endif
    
    
    return SUCCESS;
  }

  /***************** Resource Commands ****************/
  async command error_t Resource.immediateRequest() {
    error_t error = call SpiResource.immediateRequest();
    if ( error == SUCCESS ) {
      call CSN.clr();
	
    }
	
    return error;
  }

  async command error_t Resource.request() {
	return call SpiResource.request();
  }

  async command uint8_t Resource.isOwner() {
    return call SpiResource.isOwner();
  }

  async command error_t Resource.release() {
    atomic {
      call CSN.set();
	
      return call SpiResource.release();
    }
  }

  /***************** CC2420Power Commands ****************/
  async command error_t CC2520Power.startVReg() {
    uint8_t i;
	atomic {
      if ( m_state != S_VREG_STOPPED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTING;
    }

     /*
	// CSN is active low
        call CSN.set();

        // start up voltage regulator
        call VREN.clr();
        call VREN.set();
        // do a reset
        call RSTN.clr();
        // hold line low for Tdres
        call BusyWait.wait( 200 ); // typical .1ms VR startup time

        call RSTN.set();
        // wait another .2ms for xosc to stabilize
        call BusyWait.wait( 200 );

	
	*/
    // Newly Added on 15-11-10 Lijo ************************/
   
    if(m_state == S_VREG_STARTING)
    {
	//printf("Vreg starting ..");
  	//printfflush();
    }
    call RSTN.clr();
    call CSN.clr();
    call VREN.clr();
    for(i=0;i<0xFF;i++);
    //call CSN.set(); 
    call VREN.set();
    
    call RSTN.clr();
    
   
    //********************************************************
    for(i=0;i<0xFF;i++);
    for(i=0;i<0xFF;i++);
    call StartupTimer.start( CC2520_TIME_VREN );
    call RSTN.set();

    for(i=0;i<0xFF;i++);
    for(i=0;i<0xFF;i++);
     call CSN.set(); 	
    return SUCCESS;
  }

  async command error_t CC2520Power.stopVReg() {
    m_state = S_VREG_STOPPED;
    
    
    call RSTN.clr();
    call VREN.clr();
    call RSTN.set();
    return SUCCESS;
  }

  async command error_t CC2520Power.startOscillator() {
    uint8_t i;
	atomic {
      if ( m_state != S_VREG_STARTED ) {
        return FAIL;
      }
      
      m_state = S_XOSC_STARTING;
      
  // printf("\n start the oscillator");
    //  printfflush();

      // Waiting for the Crystal Oscillator to Stabilize.	
      
    for(i=0;i<0xFF;i++);
    for(i=0;i<0xFF;i++);

      
                         
      call InterruptCCA.enableRisingEdge();

      call CSN.clr(); 
      call SXOSCON.strobe();    
      call CSN.set(); 

        call CSN.clr(); 
	call SNOP.strobe();		
     	call CSN.set();  	
     
        
     
     
      Write_Default_Registers_Value();

      writeFreqctrl();

       

       call CSN.clr();       
       	call SNOP.strobe();
       call CSN.set(); 
     
         
     	call CSN.clr();       
       	call SRXON.strobe();
       call CSN.set();
	    
   

	
      call CSN.clr(); 
       call SNOP.strobe();
         call CSN.set(); 
      
    
	
     } 
   
    	
    return SUCCESS;
  }


  async command error_t CC2520Power.stopOscillator() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTED;
      call CSN.clr();
      call SXOSCOFF.strobe();
      call CSN.set();
	
    }
    return SUCCESS;
  }

  async command error_t CC2520Power.rxOn() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
	call CSN.clr();
        call SRXON.strobe();
	call CSN.set();
      
    }
    return SUCCESS;
  }

  async command error_t CC2520Power.rfOff() {
    atomic {  
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
        call CSN.clr();
       call SRFOFF.strobe();
       call CSN.set();
       
    }
    return SUCCESS;
  }

  
  /***************** CC2420Config Commands ****************/
  command uint8_t CC2520Config.getChannel() {
    atomic return m_channel;
  }

  command void CC2520Config.setChannel( uint8_t channel ) {
	
    atomic m_channel = channel;
  }

  async command uint16_t CC2520Config.getShortAddr() {
    atomic return m_short_addr;
  }

  command void CC2520Config.setShortAddr( uint16_t addr ) {
    atomic m_short_addr = addr;
  }

   command ieee_eui64_t CC2520Config.getExtAddr() {
    return m_ext_addr;
  }


  async command uint16_t CC2520Config.getPanAddr() {
    atomic return m_pan;
  }

  command void CC2520Config.setPanAddr( uint16_t pan ) {
    atomic m_pan = pan;
  }

  /**
   * Sync must be called to commit software parameters configured on
   * the microcontroller (through the CC2420Config interface) to the
   * CC2420 radio chip.
   */
  command error_t CC2520Config.sync() {
    atomic {
      if ( m_sync_busy ) {
        return FAIL;
      }
      
      m_sync_busy = TRUE;
      if ( m_state == S_XOSC_STARTED ) {
        call SyncResource.request();
      } else {
        post syncDone();
      }
    }
	
    return SUCCESS;
  }

  /**
   * @param enableAddressRecognition TRUE to turn address recognition on
   * @param useHwAddressRecognition TRUE to perform address recognition first
   *     in hardware. This doesn't affect software address recognition. The
   *     driver must sync with the chip after changing this value.
   */
  command void CC2520Config.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
    atomic {
      addressRecognition = enableAddressRecognition;
      hwAddressRecognition = useHwAddressRecognition;
    }
  }
  
  /**
   * @return TRUE if address recognition is enabled
   */
  async command bool CC2520Config.isAddressRecognitionEnabled() {
    atomic return addressRecognition;
  }
  
  /**
   * @return TRUE if address recognition is performed first in hardware.
   */
  async command bool CC2520Config.isHwAddressRecognitionDefault() {
    atomic return hwAddressRecognition;
  }
  
  
  /**
   * Sync must be called for acknowledgement changes to take effect
   * @param enableAutoAck TRUE to enable auto acknowledgements
   * @param hwAutoAck TRUE to default to hardware auto acks, FALSE to
   *     default to software auto acknowledgements
   */
  command void CC2520Config.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
    atomic autoAckEnabled = enableAutoAck;
    atomic hwAutoAckDefault = hwAutoAck;
  }
  
  /**
   * @return TRUE if hardware auto acks are the default, FALSE if software
   *     acks are the default
   */
  async command bool CC2520Config.isHwAutoAckDefault() {
    atomic return hwAutoAckDefault;    
  }
  
  /**
   * @return TRUE if auto acks are enabled
   */
  async command bool CC2520Config.isAutoAckEnabled() {
    atomic return autoAckEnabled;
  }
  
  /***************** ReadRssi Commands ****************/
  command error_t ReadRssi.read() { 
    return call RssiResource.request();
  }
  
  /***************** Spi Resources Events ****************/
  event void SyncResource.granted() {
    
    call CSN.clr();
    call SRFOFF.strobe();
    call CSN.set();
    
   
    writeFreqctrl();
    Write_Default_Registers_Value();
    writeId();
    
    call CSN.clr();
    call SRXON.strobe();
    call CSN.set();

    call SyncResource.release();
    post syncDone();

   
	
  }

  event void SpiResource.granted() {
    call CSN.clr();
    
    signal Resource.granted();
  }

  event void RssiResource.granted() { 
    uint16_t data;
    call CSN.clr();
    call RSSI.read(&data);
    call CSN.set();
    
    call RssiResource.release();
    data += 0x7f;
    data &= 0x00ff;
    signal ReadRssi.readDone(SUCCESS, data); 
  }
  
  /***************** StartupTimer Events ****************/
  async event void StartupTimer.fired() {
    if ( m_state == S_VREG_STARTING ) {
      m_state = S_VREG_STARTED;
      //call RSTN.clr();
      //call RSTN.set();
      signal CC2520Power.startVRegDone();
    }
  }

  /***************** InterruptCCA Events ****************/
  async event void InterruptCCA.fired() {
    m_state = S_XOSC_STARTED;
    call InterruptCCA.disable();
  
     writeId();
     #ifdef PRINTF
		printf("cca interrupt fired");printfflush();
     #endif
     signal CC2520Power.startOscillatorDone();
	
  }
 
  /***************** ActiveMessageAddress Events ****************/
  async event void ActiveMessageAddress.changed() {
    atomic {
      m_short_addr = call ActiveMessageAddress.amAddress();
      m_pan = call ActiveMessageAddress.amGroup();
    }
    
    post sync();
  }
  
  /***************** Tasks ****************/
  /**
   * Attempt to synchronize our current settings with the CC2420
   */
  task void sync() {
    call CC2520Config.sync();
  }
  
  task void syncDone() {
    atomic m_sync_busy = FALSE;
    signal CC2520Config.syncDone( SUCCESS );
  }
  
 
  /***************** Functions ****************/
  /**
   * Write teh FSCTRL register
   */
  void writeFreqctrl() {
    uint8_t channel;
    
    atomic {
      channel = m_channel;
    }
   
    call CSN.set();
    call CSN.clr();
    call FREQCTRL.write(MIN_CHANNEL + ((channel - MIN_CHANNEL)*CHANNEL_SPACING));
    call CSN.set(); 
  }

  /**
   * Write the Default_Register_Values register
   * Disabling hardware address recognition improves acknowledgment success
   * rate and low power communications reliability by causing the local node
   * to do work while the real destination node of the packet is acknowledging.
   */
void Write_Default_Registers_Value() {
	uint8_t ret_value;
        uint16_t data;
		call CSN.set();
                call CSN.clr();
		
		switch ((CC2520_DEF_RFPOWER))
		{
		case 0x1F :     				
				call TXPOWER.write(0xF7);	// 5dbm		Powerlevel 31
				
				break;
		case 0x1B :
				call TXPOWER.write(0xF2);	// 3dbm		Powerlevel 27
				break;
		case 0x17 :
				call TXPOWER.write(0xAB);	// 2dbm		Powerlevel 23
				
				break;
		case 0x13 :
				call TXPOWER.write(0x13);	// 1 dbm	Powerlevel 19
				
				break;
		case 0x0F :
				call TXPOWER.write(0x32);	// 0 dbm	Powerlevel 15
				
				break;
		case 0x0B :
				call TXPOWER.write(0x81);	// -2 dbm	Powerlevel 11
				
				break;
		case 0x07 :
				call TXPOWER.write(0x88);	// -4 dbm	Powerlevel 07
				
				break;
		case 0x03 :
				call TXPOWER.write(0x2C);	// -7 dbm 	Powerlevel 03
				
				
				break;
		case 0x01 :
				call TXPOWER.write(0x03);   	// -18 dbm	Powerlevel 01
				
				
				break;
		default :
				call TXPOWER.write(0xF7);	// Powerlevel default
				
				break;
	
		
		}
	
            
		call CSN.set(); 
		

		call CSN.clr();  
		call TXPOWER.write(0xF7);
		call CSN.set(); 


		call CSN.clr();  
                call CCACTRL0.write(0x1A); // 0xF8
		call CSN.set(); 

		call CSN.clr();  
		call MDMCTRL0.write(0x85);
		call CSN.set(); 

		call CSN.clr();  		
		call MDMCTRL1.write(0x14); // 0x14
		call CSN.set(); 

		call CSN.clr();  
		call RXCTRL.write(0x3F);
		call CSN.set(); 

		call CSN.clr();  
		call FSCTRL.write(0x5A);
		call CSN.set(); 


		call CSN.clr();  
		call FSCAL1.write(0x2B); // 0x03
		call CSN.set(); 


		call CSN.clr();  		
		call AGCCTRL1.write(0x11);
		call CSN.set(); 

		call CSN.clr();  
		call ADCTEST0.write(0x10);
		call CSN.set(); 

		call CSN.clr();  
		call ADCTEST1.write(0x0E);
		 call CSN.set(); 

		call CSN.clr();  
		call ADCTEST2.write(0x03);
		call CSN.set(); 		

		call CSN.clr();  
		call FRMCTRL0.write(0x40); // changed from 0x40
		call CSN.set(); 

		call CSN.clr();  
		call EXTCLOCK.write(0x00);
		call CSN.set(); 

		call CSN.clr();  		
		call GPIOCTRL1.write(CC2520_GPIO_FIFO);
		call CSN.set(); 
		

		call CSN.clr();  
		call GPIOCTRL4.write(CC2520_GPIO_FIFOP);
		call CSN.set(); 

		call CSN.clr();  
		call GPIOCTRL2.write(CC2520_GPIO_CCA);// CC2520_GPIO_SAMPLED_CCA
		call CSN.set(); 
		
		call CSN.clr();  
		call GPIOCTRL0.write(CC2520_GPIO_SFD);
		call CSN.set();  
		
                call CSN.clr();  
		call GPIOPOLARITY.write(0x0F);
		call CSN.set();



		call CSN.clr();  		
		call SNOP.strobe();
		 call CSN.set();

		call CSN.clr();   
	        call MDMCTRL1.read(data1);
		call CSN.set(); 

		call CSN.clr();  
		call FRMFILT0.write(0xc0); // changed from 0xc0
		call CSN.set(); 
		
		
		call CSN.clr();  
		call FRMCTRL1.write(0x03); // 0x48 0x60
		call CSN.set(); 
		
		call CSN.clr();  
		call FIFOPCTRL.write(0x7F); // 0x48 0x60
		call CSN.set(); 
                
		call CSN.clr();  
		ret_value =0x00;
                ret_value = call SNOP.strobe();
                call CSN.set(); 
	
  }






  
  
  /**
   * Write the PANID register
   */
  void writeId() {
    nxle_uint16_t id[ 2 ];

    atomic {
      id[ 0 ] = m_pan;
      id[ 1 ] = m_short_addr;
    }
    call CSN.set(); 
    call CSN.clr();  
    
    call PANID.write(0, (uint8_t*)&id, sizeof(id));
    call CSN.set(); 
  }


  
  /***************** Defaults ****************/
  default event void CC2520Config.syncDone( error_t error ) {
  }

  default event void ReadRssi.readDone(error_t error, uint16_t data) {
  }
  
}
