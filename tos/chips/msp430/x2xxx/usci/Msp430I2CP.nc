/*
 * Copyright (c) 2012 Zolertia Labs
 * Copyright (c) 2012 Instituto Tecnológico de Galicia (ITG)
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009-2010 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Xavier Orduña <xorduna@dexmatech.com>
 * @author Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 * @author Antonio Lignan <alinan@zolertia.com>
 * @author Carlos Giraldo <cgiraldo@itg.es>
 */

#include <I2C.h>

generic module Msp430I2CP() {
  provides {
    interface Resource[ uint8_t id ];
    interface ResourceConfigure[ uint8_t id ];
    interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;
  }
  uses {
    interface Resource as UsciResource[ uint8_t id ];
    interface Msp430I2CConfigure[ uint8_t id ];
    interface HplMsp430UsciB as UsciB;
    interface HplMsp430UsciInterrupts as Interrupts;
  }
}

implementation {
  enum {
    /* Due to different versions of msp430-gcc toolchain this value has 
     * been incremented (200 in v.3.2.3, 800 in v.4.5.3), it is currently
     * functional but this has to be addressed  */

    TIMEOUT = 1200,
  };

  norace uint8_t* m_buf;
  norace uint8_t m_len;
  norace uint8_t m_pos;
  norace i2c_flags_t m_flags;

  void nextRead();
  void nextWrite();
  void signalDone( error_t error );

  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    return call UsciResource.immediateRequest[ id ]();
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call UsciResource.request[ id ]();
  }

  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    return call UsciResource.isOwner[ id ]();
  }

  async command error_t Resource.release[ uint8_t id ]() {
    return call UsciResource.release[ id ]();
  }

  async command void ResourceConfigure.configure[ uint8_t id ]() {
    call UsciB.setModeI2C(call Msp430I2CConfigure.getConfig[id]());
  }

  async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
    call UsciB.disableI2C();
  }

  event void UsciResource.granted[ uint8_t id ]() {
    signal Resource.granted[ id ]();
  }

  default async command error_t UsciResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t UsciResource.immediateRequest[ uint8_t id ]() { return FAIL; }
  default async command error_t UsciResource.release[ uint8_t id ]() {return FAIL;}
  default event void Resource.granted[ uint8_t id ]() {}

  default async command msp430_i2c_union_config_t* Msp430I2CConfigure.getConfig[uint8_t id]() {
    return (msp430_i2c_union_config_t *) &msp430_i2c_default_config;
  }

  async command error_t I2CBasicAddr.read( i2c_flags_t flags,
					   uint16_t addr, uint8_t len, 
					   uint8_t* buf ) {
    uint16_t i = 0;
    m_buf = buf;
    m_len = len;
    m_flags = flags;
    m_pos = 0;

    call UsciB.setReceiveMode();
    call UsciB.setSlaveAddress(addr);
    call UsciB.enableRxIntr();

    if ( flags & I2C_START ) {
     while(call UsciB.getStopBit()){
       if(i>=TIMEOUT) { 
         return EBUSY;
       }
       i++;
     }
     call UsciB.setTXStart();

     if (m_len == 1){
       if ( m_flags & I2C_STOP ) {
         while (call UsciB.getStartBit()){
           if(i>=TIMEOUT) { 
             return EBUSY;
           }
           i++;
         }
         call UsciB.setTXStop();
       }
     }
    } else {
      nextRead();
    }
    return SUCCESS;
  }

  async command error_t I2CBasicAddr.write( i2c_flags_t flags,
					    uint16_t addr, uint8_t len,
					    uint8_t* buf ) {
    uint16_t i = 0;
    m_buf = buf;
    m_len = len;
    m_flags = flags;
    m_pos = 0;
    while((call UsciB.getUstat()) & UCBBUSY) {
      if(i>=TIMEOUT) {
        return FAIL;
      }
      i++;
    }
    
    call UsciB.setTransmitMode();
    call UsciB.setSlaveAddress(addr);
    call UsciB.enableTxIntr(); 
    
    if ( flags & I2C_START ) {
      while(call UsciB.getStopBit()){
        if(i>=TIMEOUT) {
          return EBUSY;
        }
        i++;
      }
      i=0;

      while((call UsciB.getUstat()) & UCBBUSY) {
        if(i>=TIMEOUT) {
          return FAIL;
        }
        i++;
      }
      call UsciB.setTXStart();
    } else {
      nextWrite();
    }
    return SUCCESS;
  }

  void nextRead() {
    uint16_t i=0;

    #ifdef USCI_X2XXX_DELAY
     for(i=0xffff;i!=0;i--) asm("nop"); //software delay (aprox 25msec on z1)
    #endif

    m_buf[m_pos ++ ] = call UsciB.rx();
    if (m_pos == m_len-1){
      if ( m_flags & I2C_STOP ) {
        call UsciB.setTXStop();
      }
    }
    if ( m_pos == m_len ) {
      if ( m_flags & I2C_STOP ) {
        while(!call UsciB.getStopBit()){
          if(i>=TIMEOUT) { 
            signalDone( EBUSY );
            return;
          }
          i++;
        }
        signalDone( SUCCESS );
      } else {
        signalDone( SUCCESS );
      }
    }
  }

  void nextWrite() {
    uint16_t i = 0;

    #ifdef USCI_X2XXX_DELAY
      for(i=0xffff;i!=0;i--) asm("nop"); //software delay (aprox 25msec on z1)
    #endif

    if ( ( m_pos == m_len) && ( m_flags & I2C_STOP ) ) {
      call UsciB.setTXStop();
      while(call UsciB.getStopBit()){
        if(i>=TIMEOUT) {
          signalDone( EBUSY );
          return;
        }
        i++;
      }
      signalDone( SUCCESS );
    } else { 
      if((call UsciB.getUstat()) == ( UCBBUSY | UCNACKIFG | UCSCLLOW)) {
        signal I2CBasicAddr.writeDone( FAIL, call UsciB.getSlaveAddress(), m_len, m_buf );
        return;
      }
      call UsciB.tx( m_buf[ m_pos++ ] );
    }
  }

  async event void Interrupts.txDone(){
    call UsciB.clrTxIntr();
    if (call UsciB.getTransmitReceiveMode())
      nextWrite();
    else
      nextRead();
  }

  async event void Interrupts.rxDone(uint8_t data){
    call UsciB.clrRxIntr();
    if (call UsciB.getTransmitReceiveMode())
      nextWrite();
    else
      nextRead();
  }

  void signalDone(error_t error) {
    call UsciB.clrIntr();
    call UsciB.disableIntr();
    if (call UsciB.getTransmitReceiveMode())
      signal I2CBasicAddr.writeDone(error, call UsciB.getSlaveAddress(), m_len, m_buf);
    else
      signal I2CBasicAddr.readDone(error, call UsciB.getSlaveAddress(), m_len, m_buf);
  }
  default async command error_t UsciResource.isOwner[ uint8_t id ]() { return FAIL; }

}
