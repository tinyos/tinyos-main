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
 * @version $Revision: 1.7 $ $Date: 2008-06-24 04:07:28 $
 */

#include "Timer.h"

module CC2420ControlP @safe() {

  provides interface Init;
  provides interface Resource;
  provides interface CC2420Config;
  provides interface CC2420Power;
  provides interface Read<uint16_t> as ReadRssi;

  uses interface Alarm<T32khz,uint32_t> as StartupTimer;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as RSTN;
  uses interface GeneralIO as VREN;
  uses interface GpioInterrupt as InterruptCCA;
  uses interface ActiveMessageAddress;

  uses interface CC2420Ram as PANID;
  uses interface CC2420Register as FSCTRL;
  uses interface CC2420Register as IOCFG0;
  uses interface CC2420Register as IOCFG1;
  uses interface CC2420Register as MDMCTRL0;
  uses interface CC2420Register as MDMCTRL1;
  uses interface CC2420Register as RXCTRL1;
  uses interface CC2420Register as RSSI;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SXOSCOFF;
  uses interface CC2420Strobe as SXOSCON;
  
  uses interface Resource as SpiResource;
  uses interface Resource as RssiResource;
  uses interface Resource as SyncResource;

  uses interface Leds;

}

implementation {

  typedef enum {
    S_VREG_STOPPED,
    S_VREG_STARTING,
    S_VREG_STARTED,
    S_XOSC_STARTING,
    S_XOSC_STARTED,
  } cc2420_control_state_t;

  uint8_t m_channel;
  
  uint8_t m_tx_power;
  
  uint16_t m_pan;
  
  uint16_t m_short_addr;
  
  bool m_sync_busy;
  
  /** TRUE if acknowledgments are enabled */
  bool autoAckEnabled;
  
  /** TRUE if acknowledgments are generated in hardware only */
  bool hwAutoAckDefault;
  
  /** TRUE if software or hardware address recognition is enabled */
  bool addressRecognition;
  
  /** TRUE if address recognition should also be performed in hardware */
  bool hwAddressRecognition;
  
  norace cc2420_control_state_t m_state = S_VREG_STOPPED;
  
  /***************** Prototypes ****************/

  void writeFsctrl();
  void writeMdmctrl0();
  void writeId();

  task void sync();
  task void syncDone();
    
  /***************** Init Commands ****************/
  command error_t Init.init() {
    call CSN.makeOutput();
    call RSTN.makeOutput();
    call VREN.makeOutput();
    
    m_short_addr = call ActiveMessageAddress.amAddress();
    m_pan = call ActiveMessageAddress.amGroup();
    m_tx_power = CC2420_DEF_RFPOWER;
    m_channel = CC2420_DEF_CHANNEL;
    
    
#if defined(CC2420_NO_ADDRESS_RECOGNITION)
    addressRecognition = FALSE;
#else
    addressRecognition = TRUE;
#endif
    
#if defined(CC2420_HW_ADDRESS_RECOGNITION)
    hwAddressRecognition = TRUE;
#else
    hwAddressRecognition = FALSE;
#endif
    
    
#if defined(CC2420_NO_ACKNOWLEDGEMENTS)
    autoAckEnabled = FALSE;
#else
    autoAckEnabled = TRUE;
#endif
    
#if defined(CC2420_HW_ACKNOWLEDGEMENTS)
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
  async command error_t CC2420Power.startVReg() {
    atomic {
      if ( m_state != S_VREG_STOPPED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTING;
    }
    call VREN.set();
    call StartupTimer.start( CC2420_TIME_VREN );
    return SUCCESS;
  }

  async command error_t CC2420Power.stopVReg() {
    m_state = S_VREG_STOPPED;
    call RSTN.clr();
    call VREN.clr();
    call RSTN.set();
    return SUCCESS;
  }

  async command error_t CC2420Power.startOscillator() {
    atomic {
      if ( m_state != S_VREG_STARTED ) {
        return FAIL;
      }
        
      m_state = S_XOSC_STARTING;
      call IOCFG1.write( CC2420_SFDMUX_XOSC16M_STABLE << 
                         CC2420_IOCFG1_CCAMUX );
                         
      call InterruptCCA.enableRisingEdge();
      call SXOSCON.strobe();
      
      call IOCFG0.write( ( 1 << CC2420_IOCFG0_FIFOP_POLARITY ) |
          ( 127 << CC2420_IOCFG0_FIFOP_THR ) );
                         
      writeFsctrl();
      writeMdmctrl0();
  
      call RXCTRL1.write( ( 1 << CC2420_RXCTRL1_RXBPF_LOCUR ) |
          ( 1 << CC2420_RXCTRL1_LOW_LOWGAIN ) |
          ( 1 << CC2420_RXCTRL1_HIGH_HGM ) |
          ( 1 << CC2420_RXCTRL1_LNA_CAP_ARRAY ) |
          ( 1 << CC2420_RXCTRL1_RXMIX_TAIL ) |
          ( 1 << CC2420_RXCTRL1_RXMIX_VCM ) |
          ( 2 << CC2420_RXCTRL1_RXMIX_CURRENT ) );
    }
    return SUCCESS;
  }


  async command error_t CC2420Power.stopOscillator() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTED;
      call SXOSCOFF.strobe();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rxOn() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      call SRXON.strobe();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rfOff() {
    atomic {  
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      call SRFOFF.strobe();
    }
    return SUCCESS;
  }

  
  /***************** CC2420Config Commands ****************/
  command uint8_t CC2420Config.getChannel() {
    atomic return m_channel;
  }

  command void CC2420Config.setChannel( uint8_t channel ) {
    atomic m_channel = channel;
  }

  async command uint16_t CC2420Config.getShortAddr() {
    atomic return m_short_addr;
  }

  command void CC2420Config.setShortAddr( uint16_t addr ) {
    atomic m_short_addr = addr;
  }

  async command uint16_t CC2420Config.getPanAddr() {
    atomic return m_pan;
  }

  command void CC2420Config.setPanAddr( uint16_t pan ) {
    atomic m_pan = pan;
  }

  /**
   * Sync must be called to commit software parameters configured on
   * the microcontroller (through the CC2420Config interface) to the
   * CC2420 radio chip.
   */
  command error_t CC2420Config.sync() {
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
  command void CC2420Config.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
    atomic {
      addressRecognition = enableAddressRecognition;
      hwAddressRecognition = useHwAddressRecognition;
    }
  }
  
  /**
   * @return TRUE if address recognition is enabled
   */
  async command bool CC2420Config.isAddressRecognitionEnabled() {
    atomic return addressRecognition;
  }
  
  /**
   * @return TRUE if address recognition is performed first in hardware.
   */
  async command bool CC2420Config.isHwAddressRecognitionDefault() {
    atomic return hwAddressRecognition;
  }
  
  
  /**
   * Sync must be called for acknowledgement changes to take effect
   * @param enableAutoAck TRUE to enable auto acknowledgements
   * @param hwAutoAck TRUE to default to hardware auto acks, FALSE to
   *     default to software auto acknowledgements
   */
  command void CC2420Config.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
    atomic autoAckEnabled = enableAutoAck;
    atomic hwAutoAckDefault = hwAutoAck;
  }
  
  /**
   * @return TRUE if hardware auto acks are the default, FALSE if software
   *     acks are the default
   */
  async command bool CC2420Config.isHwAutoAckDefault() {
    atomic return hwAutoAckDefault;    
  }
  
  /**
   * @return TRUE if auto acks are enabled
   */
  async command bool CC2420Config.isAutoAckEnabled() {
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
    writeFsctrl();
    writeMdmctrl0();
    writeId();
    call CSN.set();
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
      call RSTN.clr();
      call RSTN.set();
      signal CC2420Power.startVRegDone();
    }
  }

  /***************** InterruptCCA Events ****************/
  async event void InterruptCCA.fired() {
    m_state = S_XOSC_STARTED;
    call InterruptCCA.disable();
    call IOCFG1.write( 0 );
    writeId();
    call CSN.set();
    call CSN.clr();
    signal CC2420Power.startOscillatorDone();
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
    call CC2420Config.sync();
  }
  
  task void syncDone() {
    atomic m_sync_busy = FALSE;
    signal CC2420Config.syncDone( SUCCESS );
  }
  
  
  /***************** Functions ****************/
  /**
   * Write teh FSCTRL register
   */
  void writeFsctrl() {
    uint8_t channel;
    
    atomic {
      channel = m_channel;
    }
    
    call FSCTRL.write( ( 1 << CC2420_FSCTRL_LOCK_THR ) |
          ( ( (channel - 11)*5+357 ) << CC2420_FSCTRL_FREQ ) );
  }

  /**
   * Write the MDMCTRL0 register
   * Disabling hardware address recognition improves acknowledgment success
   * rate and low power communications reliability by causing the local node
   * to do work while the real destination node of the packet is acknowledging.
   */
  void writeMdmctrl0() {
    atomic {
      call MDMCTRL0.write( ( 1 << CC2420_MDMCTRL0_RESERVED_FRAME_MODE ) |
          ( (addressRecognition && hwAddressRecognition) << CC2420_MDMCTRL0_ADR_DECODE ) |
          ( 2 << CC2420_MDMCTRL0_CCA_HYST ) |
          ( 3 << CC2420_MDMCTRL0_CCA_MOD ) |
          ( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
          ( (autoAckEnabled && hwAutoAckDefault) << CC2420_MDMCTRL0_AUTOACK ) |
          ( 0 << CC2420_MDMCTRL0_AUTOACK ) |
          ( 2 << CC2420_MDMCTRL0_PREAMBLE_LENGTH ) );
    }
    // Jon Green:
    // MDMCTRL1.CORR_THR is defaulted to 20 instead of 0 like the datasheet says
    // If we add in changes to MDMCTRL1, be sure to include this fix.
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
    
    call PANID.write(0, (uint8_t*)&id, sizeof(id));
  }


  
  /***************** Defaults ****************/
  default event void CC2420Config.syncDone( error_t error ) {
  }

  default event void ReadRssi.readDone(error_t error, uint16_t data) {
  }
  
}
