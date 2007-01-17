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
 * @version $Revision: 1.6 $ $Date: 2007-01-17 05:24:52 $
 */

#include "Timer.h"

module CC2420ControlP {

  provides interface Init;
  provides interface Resource;
  provides interface CC2420Config;
  provides interface CC2420Power;

  uses interface Alarm<T32khz,uint32_t> as StartupTimer;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as RSTN;
  uses interface GeneralIO as VREN;
  uses interface GpioInterrupt as InterruptCCA;

  uses interface Resource as SpiResource;
  uses interface CC2420Ram as PANID;
  uses interface CC2420Register as FSCTRL;
  uses interface CC2420Register as IOCFG0;
  uses interface CC2420Register as IOCFG1;
  uses interface CC2420Register as MDMCTRL0;
  uses interface CC2420Register as MDMCTRL1;
  uses interface CC2420Register as RXCTRL1;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SXOSCOFF;
  uses interface CC2420Strobe as SXOSCON;
  uses interface AMPacket;

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

  uint8_t m_channel = CC2420_DEF_CHANNEL;
  uint8_t m_tx_power = CC2420_DEF_RFPOWER;
  uint16_t m_pan = TOS_AM_GROUP;
  uint16_t m_short_addr;
  bool m_sync_busy;
  task void syncDone_task();

  norace cc2420_control_state_t m_state = S_VREG_STOPPED;

  command error_t Init.init() {
    call CSN.makeOutput();
    call RSTN.makeOutput();
    call VREN.makeOutput();
    m_short_addr = call AMPacket.address();
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest() {
    error_t error = call SpiResource.immediateRequest();
    if ( error == SUCCESS )
      call CSN.clr();
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

  event void SpiResource.granted() {
    call CSN.clr();
    signal Resource.granted();
  }

  async command error_t CC2420Power.startVReg() {
    atomic {
      if ( m_state != S_VREG_STOPPED )
	return FAIL;
      m_state = S_VREG_STARTING;
    }
    call VREN.set();
    call StartupTimer.start( CC2420_TIME_VREN );
    return SUCCESS;
  }

  async event void StartupTimer.fired() {
    if ( m_state == S_VREG_STARTING ) {
      m_state = S_VREG_STARTED;
      call RSTN.clr();
      call RSTN.set();
      signal CC2420Power.startVRegDone();
    }
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
      if ( m_state != S_VREG_STARTED )
	return FAIL;
	
      m_state = S_XOSC_STARTING;
      call IOCFG1.write( CC2420_SFDMUX_XOSC16M_STABLE << 
			 CC2420_IOCFG1_CCAMUX );
      call InterruptCCA.enableRisingEdge();
      call SXOSCON.strobe();
      call IOCFG0.write( ( 1 << CC2420_IOCFG0_FIFOP_POLARITY ) |
			 ( 127 << CC2420_IOCFG0_FIFOP_THR ) );
      call FSCTRL.write( ( 1 << CC2420_FSCTRL_LOCK_THR ) |
			 ( ( (m_channel - 11)*5+357 ) 
			   << CC2420_FSCTRL_FREQ ) );
      call MDMCTRL0.write( ( 1 << CC2420_MDMCTRL0_RESERVED_FRAME_MODE ) |
			   ( 1 << CC2420_MDMCTRL0_ADR_DECODE ) |
			   ( 2 << CC2420_MDMCTRL0_CCA_HYST ) |
			   ( 3 << CC2420_MDMCTRL0_CCA_MOD ) |
			   ( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
			   ( 1 << CC2420_MDMCTRL0_AUTOACK ) |
			   ( 2 << CC2420_MDMCTRL0_PREAMBLE_LENGTH ) );
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

  async event void InterruptCCA.fired() {
    nxle_uint16_t id[ 2 ];
    m_state = S_XOSC_STARTED;
    id[ 0 ] = m_pan;
    id[ 1 ] = m_short_addr;
    call InterruptCCA.disable();
    call IOCFG1.write( 0 );
    call PANID.write( 0, (uint8_t*)&id, 4 );
    call CSN.set();
    call CSN.clr();
    signal CC2420Power.startOscillatorDone();
  }

  async command error_t CC2420Power.stopOscillator() {
    atomic {
      if ( m_state != S_XOSC_STARTED )
	return FAIL;
      m_state = S_VREG_STARTED;
      call SXOSCOFF.strobe();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rxOn() {
    atomic {
      if ( m_state != S_XOSC_STARTED )
	return FAIL;
      call SRXON.strobe();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rfOff() {
    atomic {  
      if ( m_state != S_XOSC_STARTED )
	return FAIL;
      call SRFOFF.strobe();
    }
    return SUCCESS;
  }

  command uint8_t CC2420Config.getChannel() {
    atomic return m_channel;
  }

  command void CC2420Config.setChannel( uint8_t channel ) {
    atomic m_channel = channel;
  }

  command uint16_t CC2420Config.getShortAddr() {
    atomic return m_short_addr;
  }

  command void CC2420Config.setShortAddr( uint16_t addr ) {
    atomic m_short_addr = addr;
  }

  command uint16_t CC2420Config.getPanAddr() {
    return m_pan;
  }

  command void CC2420Config.setPanAddr( uint16_t pan ) {
    atomic m_pan = pan;
  }

  command error_t CC2420Config.sync() {
    atomic {
      if ( m_sync_busy )
        return FAIL;
      m_sync_busy = TRUE;
      if ( m_state == S_XOSC_STARTED )
        call SyncResource.request();
      else
        post syncDone_task();
    }
    return SUCCESS;
  }

  event void SyncResource.granted() {

    nxle_uint16_t id[ 2 ];
    uint8_t channel;

    atomic {
      channel = m_channel;
      id[ 0 ] = m_pan;
      id[ 1 ] = m_short_addr;
    }

    call CSN.clr();
    call SRFOFF.strobe();
    call FSCTRL.write( ( 1 << CC2420_FSCTRL_LOCK_THR ) |
		       ( ( (channel - 11)*5+357 ) << CC2420_FSCTRL_FREQ ) );
    call PANID.write( 0, (uint8_t*)id, sizeof( id ) );
    call CSN.set();
    call CSN.clr();
    call SRXON.strobe();
    call CSN.set();
    call SyncResource.release();
    
    post syncDone_task();
    
  }

  task void syncDone_task() {
    atomic m_sync_busy = FALSE;
    signal CC2420Config.syncDone( SUCCESS );
  }

  default event void CC2420Config.syncDone( error_t error ) {}

}
