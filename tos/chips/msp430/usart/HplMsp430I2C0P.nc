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
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:08 $
 */

module HplMsp430I2C0P {
  
  provides interface HplMsp430I2C as HplI2C;
  
  uses interface HplMsp430Usart as HplUsart;
  uses interface HplMsp430GeneralIO as SIMO;
  uses interface HplMsp430GeneralIO as UCLK;
  
}

implementation {
  
  MSP430REG_NORACE(U0CTL);
  MSP430REG_NORACE(I2CTCTL);
  MSP430REG_NORACE(I2CDR);
  MSP430REG_NORACE(I2CSA);
  MSP430REG_NORACE(I2CIE);

  async command bool HplI2C.isI2C() {
    atomic return ((U0CTL & I2C) && (U0CTL & SYNC) && (U0CTL & I2CEN));
  }
  
  async command void HplI2C.clearModeI2C() {
    atomic {
      U0CTL &= ~(I2C | SYNC | I2CEN);
      call HplUsart.resetUsart(TRUE);
    }
  }
  
  async command void HplI2C.setModeI2C( msp430_i2c_config_t* config ) {
    
    call HplUsart.disableUart();
    call HplUsart.disableSpi();
    call SIMO.makeInput();
    call SIMO.selectModuleFunc();
    call UCLK.makeInput();
    call UCLK.selectModuleFunc();
    
    atomic {
      
      U0CTL &= ~(I2C | I2CEN | SYNC);
      U0CTL = SWRST;
      U0CTL |= SYNC | I2C;
      U0CTL &= ~I2CEN;
      
      U0CTL |= ( ( config->rxdmaen << 7 ) |
                 ( config->txdmaen << 6 ) |
                 ( config->xa << 4 ) |
                 ( config->listen << 3 ) );
      I2CTCTL = 0;
      I2CTCTL = ( ( config->i2cword << 7 ) |
		  ( config->i2crm << 6 ) |
		  ( config->i2cssel << 4 ) );
      I2CPSC = config->i2cpsc;
      I2CSCLH = config->i2csclh;
      I2CSCLL = config->i2cscll;
      I2COA = config->i2coa;
      U0CTL |= I2CEN;
      
    }
    
  }
  
  // U0CTL
  async command void HplI2C.setMasterMode() { U0CTL |= MST; }
  async command void HplI2C.setSlaveMode() { U0CTL &= ~MST; }
  
  async command void HplI2C.enableI2C() { U0CTL |= I2CEN; }
  async command void HplI2C.disableI2C() { U0CTL &= ~I2CEN; }
  
  // I2CTCTL
  async command bool HplI2C.getWordMode() {
    return ( I2CTCTL & I2CWORD ) != 0;
  }
  
  async command void HplI2C.setWordMode( bool mode ) {
    I2CTCTL |= ( mode & 0x1 ) << 7;
  }
  
  async command bool HplI2C.getRepeatMode() {
    return ( I2CTCTL & I2CRM ) != 0;
  }
  
  async command void HplI2C.setRepeatMode( bool mode ) { 
    I2CTCTL |= ( mode & 0x1 ) << 6;;
  }
  
  async command uint8_t HplI2C.getClockSource() {
    return ( I2CTCTL >> 4 ) & 0x3;;
  }
  
  async command void HplI2C.setClockSource( uint8_t src ) {
    atomic I2CTCTL = ( ( src & 0x3 ) << 4 ) | I2CTCTL;
  }
  
  async command bool HplI2C.getTransmitReceiveMode() { 
    return ( I2CTCTL & I2CTRX ) != 0; 
  }
  
  async command void HplI2C.setTransmitMode() { I2CTCTL |= I2CTRX; }
  async command void HplI2C.setReceiveMode() { I2CTCTL &= ~I2CTRX; }
  
  async command bool HplI2C.getStartByte() { return (I2CTCTL & I2CSTB) != 0; }
  async command void HplI2C.setStartByte() { I2CTCTL |= I2CSTB; }
  
  async command bool HplI2C.getStopBit() { return (I2CTCTL & I2CSTP) != 0; }
  async command void HplI2C.setStopBit() { I2CTCTL |= I2CSTP; }
  
  async command bool HplI2C.getStartBit() { return (I2CTCTL & I2CSTT) != 0; }
  async command void HplI2C.setStartBit() { I2CTCTL |= I2CSTT; }
  
  // I2CDR
  async command uint8_t HplI2C.getData() { return I2CDR; }
  async command void HplI2C.setData( uint8_t v ) { I2CDR = v; }
  
  // I2CNDAT
  async command uint8_t HplI2C.getTransferByteCount() { return I2CNDAT; }
  async command void HplI2C.setTransferByteCount( uint8_t v ) { I2CNDAT = v; }
  
  // I2CPSC
  async command uint8_t HplI2C.getClockPrescaler() { return I2CPSC; }
  async command void HplI2C.setClockPrescaler( uint8_t v ) { I2CPSC = v; }
  
  // I2CSCLH and I2CSCLL
  async command uint16_t HplI2C.getShiftClock() {
    uint16_t shift;
    atomic {
      shift = I2CSCLH;
      shift <<= 8;
      shift |= I2CSCLL;
    }
    return shift;
  }
  
  async command void HplI2C.setShiftClock( uint16_t shift ) {
    atomic {
      I2CSCLH = shift >> 8;
      I2CSCLL = shift;
    }
  }
  
  // I2COA
  async command uint16_t HplI2C.getOwnAddress() { return I2COA; }
  async command void HplI2C.setOwnAddress( uint16_t addr ) { I2COA = addr; }
  
  // I2CSA
  async command uint16_t HplI2C.getSlaveAddress() { return I2CSA; }
  async command void HplI2C.setSlaveAddress( uint16_t addr ) { I2CSA = addr; }
  
  // I2CIE
  async command void HplI2C.disableStartDetect() { I2CIE &= ~STTIE; }
  async command void HplI2C.enableStartDetect() { I2CIE |= STTIE; }
  
  async command void HplI2C.disableGeneralCall() { I2CIE &= ~GCIE; }
  async command void HplI2C.enableGeneralCall() { I2CIE |= GCIE; }
  
  async command void HplI2C.disableTransmitReady() { I2CIE &= ~TXRDYIE; }
  async command void HplI2C.enableTransmitReady() { I2CIE |= TXRDYIE; }
  
  async command void HplI2C.disableReceiveReady() { I2CIE &= ~RXRDYIE; }
  async command void HplI2C.enableReceiveReady() { I2CIE |= RXRDYIE; }
  
  async command void HplI2C.disableAccessReady() { I2CIE &= ~ARDYIE; }
  async command void HplI2C.enableAccessReady() { I2CIE |= ARDYIE; }
  
  async command void HplI2C.disableOwnAddress() { I2CIE &= ~OAIE; }
  async command void HplI2C.enableOwnAddress() { I2CIE |= OAIE; }

  async command void HplI2C.disableNoAck() { I2CIE &= ~NACKIE; }
  async command void HplI2C.enableNoAck() { I2CIE |= NACKIE; }
  
  async command void HplI2C.disableArbitrationLost() { I2CIE &= ~ALIE; }
  async command void HplI2C.enableArbitrationLost() { I2CIE |= ALIE; }
  
  // I2CIFG
  async command bool HplI2C.isStartDetectPending() {
    return ( I2CIFG & STTIFG ) != 0;
  }
  
  async command bool HplI2C.isGeneralCallPending() {
    return ( I2CIFG & GCIFG ) != 0;
  }
  
  async command bool HplI2C.isTransmitReadyPending() {
    return ( I2CIFG & TXRDYIFG ) != 0;
  }
  
  async command bool HplI2C.isReceiveReadyPending() {
    return ( I2CIFG & RXRDYIFG ) != 0;
  }
  
  async command bool HplI2C.isAccessReadyPending() {
    return ( I2CIFG & ARDYIFG ) != 0;
  }
  
  async command bool HplI2C.isOwnAddressPending() {
    return ( I2CIFG & OAIFG ) != 0;
  }
  
  async command bool HplI2C.isNoAckPending() {
    return ( I2CIFG & NACKIFG ) != 0;
  }
  
  async command bool HplI2C.isArbitrationLostPending() {
    return ( I2CIFG & ALIFG ) != 0;
  }
  
  // I2CIV
  async command uint8_t HplI2C.getIV() {
    return I2CIV;
  }
  
}
