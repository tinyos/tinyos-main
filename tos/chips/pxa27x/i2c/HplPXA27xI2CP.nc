/* $Id: HplPXA27xI2CP.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * The Private Hpl Interface for the I2C components. Handles enabling of the 
 * clock for the interface.  It DOES NOT affect the I2C_IUE bit of the ICR
 * register.
 * 
 * @param dev The I2C to use. 0 = Standard I2c, 1 = Power I2C
 *
 * @author Phil Buonadonna
 */

generic module HplPXA27xI2CP(uint8_t dev)
{
  provides interface Init;
  provides interface HplPXA27xI2C as I2C; 

  uses interface HplPXA27xInterrupt as I2CIrq;

}

implementation
{
  bool m_fInit = FALSE;

  command error_t Init.init() {
    bool isInited;

    atomic {
      isInited = m_fInit;
      m_fInit = TRUE;
    }

    if (!isInited) {
      switch(dev) {
      case 0:
	CKEN |= CKEN14_I2C;
	ICR = 0;
	break;
      case 1:
	CKEN |= CKEN15_PMI2C;
	PICR = 0;
	break;
      default:
	break;
      }
      call I2CIrq.allocate();
      call I2CIrq.enable();
    }

    return SUCCESS;
  }

  async command uint32_t I2C.getIBMR() { 
    switch(dev) {
    case 0: return IBMR; break;
    case 1: return PIBMR; break;
    default: return 0;
    }
  }

  async command void I2C.setIDBR(uint32_t val) {
    switch(dev) {
    case 0: IDBR = val; break;
    case 1: PIDBR = val; break;
    default: break;
    }
    return;
  }

  async command uint32_t I2C.getIDBR() { 
    switch(dev) {
    case 0: return IDBR; break;
    case 1: return PIDBR; break;
    default: return 0;
    }
  }

  async command void I2C.setICR(uint32_t val) {
    switch(dev) {
    case 0: ICR = val; break;
    case 1: PICR = val; break;
    default: break;
    }
    return;
  }

  async command uint32_t I2C.getICR() { 
    switch(dev) {
    case 0: return ICR; break;
    case 1: return PICR; break;
    default: return 0;
    }
  }

 async command void I2C.setISR(uint32_t val) { 
    switch(dev) {
    case 0: ISR = val; break;
    case 1: PISR = val; break;
    default: break;
    }
  }

 async command uint32_t I2C.getISR() { 
    switch(dev) {
    case 0: return ISR; break;
    case 1: return PISR; break;
    default: return 0;
    }
  }

  async command void I2C.setISAR(uint32_t val) {
    switch(dev) {
    case 0: ISAR = val; break;
    case 1: PISAR = val; break;
    default: break;
    }
    return;
  }

  async command uint32_t I2C.getISAR() { 
    switch(dev) {
    case 0: return ISAR; break;
    case 1: return PISAR; break;
    default: return 0;
    }
  }

  async event void I2CIrq.fired() {
    
    signal I2C.interruptI2C();
    return;
  }

  default async event void I2C.interruptI2C() { 
    return;
  }
}
