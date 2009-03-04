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
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @version $Revision: 1.3 $ $Date: 2009-03-04 18:31:03 $
 */

#include "Timer.h"
#include "AM.h"
#include "TKN154_PIB.h"

module CC2420ControlP {

  provides interface Init;
  provides interface Resource;
  provides interface CC2420Config;
  provides interface CC2420Power;

  uses interface Alarm<T62500hz,uint32_t> as StartupAlarm;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as RSTN;
  uses interface GeneralIO as VREN;
  uses interface GpioInterrupt as InterruptCCA;
  uses interface GeneralIO as FIFO;

  uses interface CC2420Ram as IEEEADR;
  uses interface CC2420Register as FSCTRL;
  uses interface CC2420Register as IOCFG0;
  uses interface CC2420Register as IOCFG1;
  uses interface CC2420Register as MDMCTRL0;
  uses interface CC2420Register as MDMCTRL1;
  uses interface CC2420Register as RXCTRL1;
  uses interface CC2420Register as RSSI;
  uses interface CC2420Register as RXFIFO_REGISTER;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SXOSCOFF;
  uses interface CC2420Strobe as SXOSCON;
  uses interface CC2420Strobe as SACKPEND;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Register as TXCTRL;
  uses interface AMPacket;
  uses interface Resource as SpiResource;
  uses interface FrameUtility;
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
  uint16_t m_pan;
  uint16_t m_short_addr;
  bool autoAckEnabled;
  bool hwAutoAckDefault;
  bool addressRecognition;
  bool acceptReservedFrames;
  bool m_isPanCoord;
  uint8_t m_CCAMode;
  uint8_t m_txPower;

  bool m_needsSync;

  norace cc2420_control_state_t m_state = S_VREG_STOPPED;
  
  /***************** Prototypes ****************/

  void writeFsctrl();
  void writeMdmctrl0();
  void writeId();
  void writeTxPower();

  /***************** Init Commands ****************/
  command error_t Init.init() {
    call CSN.makeOutput();
    call RSTN.makeOutput();
    call VREN.makeOutput();
    autoAckEnabled = TRUE;
    hwAutoAckDefault = TRUE;
    addressRecognition = TRUE;
    acceptReservedFrames = FALSE;
    m_needsSync = FALSE;
    return SUCCESS;
  }

  /***************** Resource Commands ****************/
  /* This module never actively requests the SPI resource,
   * instead the caller MUST request the SPI through this module
   * before it calls any of the provided commands and it must
   * release it afterwards (the caller can call multiple  
   * commands in this module before it releases the SPI, though).
   */ 
  async command error_t Resource.immediateRequest() {
    error_t error = call SpiResource.immediateRequest();
    if ( error == SUCCESS ) {
/*      call CSN.clr();*/
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
/*      call CSN.set();*/
      return call SpiResource.release();
    }
  }

  event void SpiResource.granted() {
/*    call CSN.clr();*/
    signal Resource.granted();
  }

  void switchToUnbufferedMode()
  {
    uint16_t mdmctrol1;
    call CSN.set();
    call CSN.clr();
    call MDMCTRL1.read(&mdmctrol1);
    call CSN.set();
    mdmctrol1 &= ~0x0003;
    mdmctrol1 |= 0x0000;
    call CSN.clr();
    call MDMCTRL1.write(mdmctrol1);
    call CSN.set();
  }

  void switchToBufferedMode()
  {
    uint16_t mdmctrol1;
    call CSN.set();
    call CSN.clr();
    call MDMCTRL1.read(&mdmctrol1);
    mdmctrol1 &= ~0x03;
    call MDMCTRL1.write(mdmctrol1);
    call CSN.set();
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
    call StartupAlarm.start( CC2420_TIME_VREN * 2 ); // JH: changed from 32khz jiffies
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
      call CSN.set();
      call CSN.clr();
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
      call CSN.set();
    }
    return SUCCESS;
  }


  async command error_t CC2420Power.stopOscillator() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTED;
      call CSN.set();
      call CSN.clr();
      call SXOSCOFF.strobe();
      call CSN.set();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rxOn() {
    atomic {
      if ( !call SpiResource.isOwner() )
        return FAIL;
      call CSN.set();
      call CSN.clr();
      call SRXON.strobe();
      call SACKPEND.strobe();  // JH: ACKs need the pending bit set
      call CSN.set();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rfOff() {
    atomic {
      if ( !call SpiResource.isOwner() )
        return FAIL;
      call CSN.set();
      call CSN.clr();
      call SRFOFF.strobe();
      call CSN.set();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.flushRxFifo()
  {
    uint16_t dummy;
    atomic {
      if ( !call SpiResource.isOwner() )
        return FAIL;
      if ( call FIFO.get() ){ // check if there is something in the RXFIFO
        // SFLUSHRX: "Flush the RX FIFO buffer and reset the demodulator. 
        // Always read at least one byte from the RXFIFO before 
        // issuing the SFLUSHRX command strobe" (CC2420 Datasheet)
        call CSN.clr();
        call RXFIFO_REGISTER.read(&dummy); // reading the byte
        call CSN.set();
        call CSN.clr();
        // "SFLUSHRX command strobe should be issued twice to ensure 
        // that the SFD pin goes back to its idle state." (CC2420 Datasheet)
        call SFLUSHRX.strobe();
        call SFLUSHRX.strobe();
        call CSN.set();
      }
    }
    return SUCCESS;
  }
  
  /***************** CC2420Config Commands ****************/
  command uint8_t CC2420Config.getChannel() {
    atomic return m_channel;
  }

  command void CC2420Config.setChannel( uint8_t channel ) {
    atomic {
      m_needsSync = TRUE;
      m_channel = channel;
    }
  }

  async command uint16_t CC2420Config.getShortAddr() {
    atomic return m_short_addr;
  }

  command void CC2420Config.setShortAddr( uint16_t addr ) {
    atomic {
      m_needsSync = TRUE;
      m_short_addr = addr;
    }
  }

  async command uint16_t CC2420Config.getPanAddr() {
    atomic return m_pan;
  }

  command void CC2420Config.setPanAddr( uint16_t pan ) {
    atomic {
      m_needsSync = TRUE;
      m_pan = pan;
    }
  }

  async command bool CC2420Config.getPanCoordinator() {
    atomic return m_isPanCoord;
  }

  command void CC2420Config.setPanCoordinator( bool pCoord ) {
    atomic {
      m_needsSync = TRUE;
      m_isPanCoord = pCoord;
    }
  }

  command void CC2420Config.setPromiscuousMode(bool on)
  {
    atomic {
      m_needsSync = TRUE;
      if (on){
        addressRecognition = FALSE;
        acceptReservedFrames = TRUE;
        autoAckEnabled = FALSE;
      } else {
        addressRecognition = TRUE;
        acceptReservedFrames = FALSE;
        autoAckEnabled = TRUE;
      }
    }
  }

  async command bool CC2420Config.isPromiscuousModeEnabled()
  {
    return acceptReservedFrames;
  }

  async command uint8_t CC2420Config.getCCAMode()
  {
    atomic return m_CCAMode;
  }

  command void CC2420Config.setCCAMode(uint8_t mode)
  {
    atomic {
      m_needsSync = TRUE;
      m_CCAMode = mode;
    }
  }

  async command uint8_t CC2420Config.getTxPower()
  {
    atomic return m_txPower;
  }

  command void CC2420Config.setTxPower(uint8_t txPower)
  {
    atomic {
      m_needsSync = TRUE;
      m_txPower = txPower;
    }
  }

  async command bool CC2420Config.needsSync(){
    atomic return m_needsSync;
  }

  /**
   * Sync must be called to commit software parameters configured on
   * the microcontroller (through the CC2420Config interface) to the
   * CC2420 radio chip.
   */
  async command error_t CC2420Config.sync() {
    atomic {
      if ( !call SpiResource.isOwner() )
        return FAIL;
      if (m_needsSync){
        call CSN.set();
        call CSN.clr();
        call SRFOFF.strobe();
        call CSN.set();
        call CSN.clr();
        writeFsctrl();
        writeMdmctrl0();
        writeTxPower();
        call CSN.set();
        call CSN.clr();
        writeId();
        call CSN.set();
        m_needsSync = FALSE;
      }
    }
    return SUCCESS;
  }

  /***************** ReadRssi Commands ****************/
  
  async command error_t CC2420Power.rssi(int8_t *rssi) {
    uint16_t data;
    cc2420_status_t status;
    atomic {
      if ( !call SpiResource.isOwner() )
        return FAIL;
      call CSN.set();
      call CSN.clr();
      status = call RSSI.read(&data);
      call CSN.set();
      if ((status & 0x02)){
        *rssi = (data & 0x00FF);
        return SUCCESS;
      } else
        return FAIL;
    }
  }
  
  /***************** StartupAlarm Events ****************/
  async event void StartupAlarm.fired() {
    if ( m_state == S_VREG_STARTING ) {
      cc2420_status_t status;
      do {
       status = call SNOP.strobe();  
      } while (!(status & CC2420_STATUS_XOSC16M_STABLE));
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
    call CSN.set();
    call CSN.clr();
    call IOCFG1.write( 0 );
    writeId();
    call CSN.set();
    signal CC2420Power.startOscillatorDone();
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
   */
  void writeMdmctrl0() {
    atomic {
      uint8_t _acceptReservedFrames = (acceptReservedFrames ? 1: 0);
      uint8_t _panCoord = (m_isPanCoord ? 1: 0);
      uint8_t _addressRecognition = (addressRecognition ? 1: 0);
      uint8_t _autoAck = ((autoAckEnabled && hwAutoAckDefault) ? 1 : 0);
      call MDMCTRL0.write( ( _acceptReservedFrames << CC2420_MDMCTRL0_RESERVED_FRAME_MODE ) |
          ( _panCoord << CC2420_MDMCTRL0_PAN_COORDINATOR ) | 
          ( _addressRecognition << CC2420_MDMCTRL0_ADR_DECODE ) |
          ( 2 << CC2420_MDMCTRL0_CCA_HYST ) |
          ( m_CCAMode << CC2420_MDMCTRL0_CCA_MOD ) |
          ( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
          ( _autoAck << CC2420_MDMCTRL0_AUTOACK ) |
          ( 2 << CC2420_MDMCTRL0_PREAMBLE_LENGTH ) );
    }
    // Jon Green:
    // MDMCTRL1.CORR_THR is defaulted to 20 instead of 0 like the datasheet says
    // If we add in changes to MDMCTRL1, be sure to include this fix.
  }
  
  /**
   * Write the IEEEADR register
   */
  void writeId() {
    uint16_t bcnAccept = 0;
    nxle_uint16_t id[ 6 ];

    atomic {
      call FrameUtility.copyLocalExtendedAddressLE((uint8_t*) &id);
      id[ 4 ] = m_pan;
      id[ 5 ] = m_short_addr;
    }
    if (m_pan == 0xFFFF)
      bcnAccept = 1;
    
    
    call IOCFG0.write( (bcnAccept << CC2420_IOCFG0_BCN_ACCEPT) |
        ( 1 << CC2420_IOCFG0_FIFOP_POLARITY ) |
          ( 127 << CC2420_IOCFG0_FIFOP_THR ) );
    // ext.adr, PANID and short adr are located at consecutive addresses in RAM
    call IEEEADR.write(0, (uint8_t*)&id, sizeof(id));
  }

  void writeTxPower(){
    call TXCTRL.write( 
        ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
        ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
        ( 1 << CC2420_TXCTRL_RESERVED ) |
      ( (m_txPower & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );
  }
}
