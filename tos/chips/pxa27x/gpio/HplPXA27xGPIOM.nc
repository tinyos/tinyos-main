// $Id: HplPXA27xGPIOM.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

//@author Phil Buonadonna
module HplPXA27xGPIOM {

  provides {
    interface Init;
    interface HplPXA27xGPIOPin[uint8_t pin];
    interface HplPXA27xGPIO;
  }
  uses {
    interface HplPXA27xInterrupt as GPIOIrq0;
    interface HplPXA27xInterrupt as GPIOIrq1;
    interface HplPXA27xInterrupt as GPIOIrq;   // GPIO 2 - 120 only
  }
}

implementation {

  bool gfInitialized = FALSE;

  command error_t Init.init() 
  {
    bool isInited;

    atomic {
      isInited = gfInitialized;
      gfInitialized = TRUE;
    }

    if (!isInited) {
      call GPIOIrq0.allocate();
      call GPIOIrq1.allocate();
      call GPIOIrq.allocate();
      call GPIOIrq0.enable();
      call GPIOIrq1.enable();
      call GPIOIrq.enable();   
    }
    return SUCCESS;
  }

  async command bool HplPXA27xGPIOPin.getGPLRbit[uint8_t pin]() 
  {
    return ((GPLR(pin) & _GPIO_bit(pin)) != 0);
  }

  async command void HplPXA27xGPIOPin.setGPDRbit[uint8_t pin](bool dir) 
  {
    if (dir) {
      GPDR(pin) |= _GPIO_bit(pin);
    }
    else {
      GPDR(pin) &= ~(_GPIO_bit(pin));
    }
    return;
  }

  async command bool HplPXA27xGPIOPin.getGPDRbit[uint8_t pin]() 
  {
    return ((GPDR(pin) & _GPIO_bit(pin)) != 0);
  }

  async command void HplPXA27xGPIOPin.setGPSRbit[uint8_t pin]() 
  {
    GPSR(pin) = _GPIO_bit(pin);
    return;
  }

  async command void HplPXA27xGPIOPin.setGPCRbit[uint8_t pin]() 
  {
    GPCR(pin) = _GPIO_bit(pin);
    return;
  }

  async command void HplPXA27xGPIOPin.setGRERbit[uint8_t pin](bool flag) 
  {
    if (flag) {
      GRER(pin) |= _GPIO_bit(pin);
    }
    else {
      GRER(pin) &= ~(_GPIO_bit(pin));
    }
    return;
  }

  async command bool HplPXA27xGPIOPin.getGRERbit[uint8_t pin]() 
  {
    return ((GRER(pin) & _GPIO_bit(pin)) != 0);
  }

  async command void HplPXA27xGPIOPin.setGFERbit[uint8_t pin](bool flag) 
  {
    if (flag) {
      GFER(pin) |= _GPIO_bit(pin);
    }
    else {
      GFER(pin) &= ~(_GPIO_bit(pin));
    }
    return;
  }

  async command bool HplPXA27xGPIOPin.getGFERbit[uint8_t pin]() 
  {
    return ((GFER(pin) & _GPIO_bit(pin)) != 0);
  }

  async command bool HplPXA27xGPIOPin.getGEDRbit[uint8_t pin]() 
  {
    return ((GEDR(pin) & _GPIO_bit(pin)) != 0);
  }

  async command bool HplPXA27xGPIOPin.clearGEDRbit[uint8_t pin]() 
  {
    bool flag;
    flag = ((GEDR(pin) & _GPIO_bit(pin)) != 0);
    GEDR(pin) = _GPIO_bit(pin);
    return flag;
  }

  async command void HplPXA27xGPIOPin.setGAFRpin[uint8_t pin](uint8_t func) 
  {
    func &= 0x3;
    _GPIO_setaltfn(pin,func);
    return;
  }

  async command uint8_t HplPXA27xGPIOPin.getGAFRpin[uint8_t pin]() 
  {
    return (_GPIO_getaltfun(pin));
  }

  default async event void HplPXA27xGPIOPin.interruptGPIOPin[uint8_t pin]() 
  {
    call HplPXA27xGPIOPin.clearGEDRbit[pin]();
    return;
  }

  async command void HplPXA27xGPIO.setGPLR0(uint32_t val) {GPLR0 = val;}
  async command uint32_t HplPXA27xGPIO.getGPLR0() {return GPLR0;}
  async command void HplPXA27xGPIO.setGPLR1(uint32_t val) {GPLR1 = val;}
  async command uint32_t HplPXA27xGPIO.getGPLR1() {return GPLR1;}
  async command void HplPXA27xGPIO.setGPLR2(uint32_t val) {GPLR2 = val;}
  async command uint32_t HplPXA27xGPIO.getGPLR2() {return GPLR2;}
  async command void HplPXA27xGPIO.setGPLR3(uint32_t val) {GPLR3 = val;}
  async command uint32_t HplPXA27xGPIO.getGPLR3() {return GPLR3;}

  async command void HplPXA27xGPIO.setGPDR0(uint32_t val) {GPDR0 = val;}
  async command uint32_t HplPXA27xGPIO.getGPDR0() {return GPDR0;}
  async command void HplPXA27xGPIO.setGPDR1(uint32_t val) {GPDR1 = val;}
  async command uint32_t HplPXA27xGPIO.getGPDR1() {return GPDR1;}
  async command void HplPXA27xGPIO.setGPDR2(uint32_t val) {GPDR2 = val;}
  async command uint32_t HplPXA27xGPIO.getGPDR2() {return GPDR2;}
  async command void HplPXA27xGPIO.setGPDR3(uint32_t val) {GPDR3 = val;}
  async command uint32_t HplPXA27xGPIO.getGPDR3() {return GPDR3;}

  async command void HplPXA27xGPIO.setGPSR0(uint32_t val) {GPSR0 = val;}
  async command uint32_t HplPXA27xGPIO.getGPSR0() {return GPSR0;}
  async command void HplPXA27xGPIO.setGPSR1(uint32_t val) {GPSR1 = val;}
  async command uint32_t HplPXA27xGPIO.getGPSR1() {return GPSR1;}
  async command void HplPXA27xGPIO.setGPSR2(uint32_t val) {GPSR2 = val;}
  async command uint32_t HplPXA27xGPIO.getGPSR2() {return GPSR2;}
  async command void HplPXA27xGPIO.setGPSR3(uint32_t val) {GPSR3 = val;}
  async command uint32_t HplPXA27xGPIO.getGPSR3() {return GPSR3;}

  async command void HplPXA27xGPIO.setGPCR0(uint32_t val) {GPCR0 = val;}
  async command uint32_t HplPXA27xGPIO.getGPCR0() {return GPCR0;}
  async command void HplPXA27xGPIO.setGPCR1(uint32_t val) {GPCR1 = val;}
  async command uint32_t HplPXA27xGPIO.getGPCR1() {return GPCR1;}
  async command void HplPXA27xGPIO.setGPCR2(uint32_t val) {GPCR2 = val;}
  async command uint32_t HplPXA27xGPIO.getGPCR2() {return GPCR2;}
  async command void HplPXA27xGPIO.setGPCR3(uint32_t val) {GPCR3 = val;}
  async command uint32_t HplPXA27xGPIO.getGPCR3() {return GPCR3;}

  async command void HplPXA27xGPIO.setGRER0(uint32_t val) {GRER0 = val;}
  async command uint32_t HplPXA27xGPIO.getGRER0() {return GRER0;}
  async command void HplPXA27xGPIO.setGRER1(uint32_t val) {GRER1 = val;}
  async command uint32_t HplPXA27xGPIO.getGRER1() {return GRER1;}
  async command void HplPXA27xGPIO.setGRER2(uint32_t val) {GRER2 = val;}
  async command uint32_t HplPXA27xGPIO.getGRER2() {return GRER2;}
  async command void HplPXA27xGPIO.setGRER3(uint32_t val) {GRER3 = val;}
  async command uint32_t HplPXA27xGPIO.getGRER3() {return GRER3;}

  async command void HplPXA27xGPIO.setGFER0(uint32_t val) {GFER0 = val;}
  async command uint32_t HplPXA27xGPIO.getGFER0() {return GFER0;}
  async command void HplPXA27xGPIO.setGFER1(uint32_t val) {GFER1 = val;}
  async command uint32_t HplPXA27xGPIO.getGFER1() {return GFER1;}
  async command void HplPXA27xGPIO.setGFER2(uint32_t val) {GFER2 = val;}
  async command uint32_t HplPXA27xGPIO.getGFER2() {return GFER2;}
  async command void HplPXA27xGPIO.setGFER3(uint32_t val) {GFER3 = val;}
  async command uint32_t HplPXA27xGPIO.getGFER3() {return GFER3;}

  async command void HplPXA27xGPIO.setGEDR0(uint32_t val) {GEDR0 = val;}
  async command uint32_t HplPXA27xGPIO.getGEDR0() {return GEDR0;}
  async command void HplPXA27xGPIO.setGEDR1(uint32_t val) {GEDR1 = val;}
  async command uint32_t HplPXA27xGPIO.getGEDR1() {return GEDR1;}
  async command void HplPXA27xGPIO.setGEDR2(uint32_t val) {GEDR2 = val;}
  async command uint32_t HplPXA27xGPIO.getGEDR2() {return GEDR2;}
  async command void HplPXA27xGPIO.setGEDR3(uint32_t val) {GEDR3 = val;}
  async command uint32_t HplPXA27xGPIO.getGEDR3() {return GEDR3;}
 
  async command void HplPXA27xGPIO.setGAFR0_L(uint32_t val) {GAFR0_L = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR0_L() {return GAFR0_L;}
  async command void HplPXA27xGPIO.setGAFR0_U(uint32_t val) {GAFR0_U = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR0_U() {return GAFR0_U;}

  async command void HplPXA27xGPIO.setGAFR1_L(uint32_t val) {GAFR1_L = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR1_L() {return GAFR1_L;}
  async command void HplPXA27xGPIO.setGAFR1_U(uint32_t val) {GAFR1_U = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR1_U() {return GAFR1_U;}

  async command void HplPXA27xGPIO.setGAFR2_L(uint32_t val) {GAFR2_L = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR2_L() {return GAFR2_L;}
  async command void HplPXA27xGPIO.setGAFR2_U(uint32_t val) {GAFR2_U = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR2_U() {return GAFR2_U;}

  async command void HplPXA27xGPIO.setGAFR3_L(uint32_t val) {GAFR3_L = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR3_L() {return GAFR3_L;}
  async command void HplPXA27xGPIO.setGAFR3_U(uint32_t val) {GAFR3_U = val;}
  async command uint32_t HplPXA27xGPIO.getGAFR3_U() {return GAFR3_U;}
 
  default async event void HplPXA27xGPIO.fired() {
    return;
  }

  async event void GPIOIrq.fired() 
  {

    uint32_t DetectReg;
    uint8_t pin;

    signal HplPXA27xGPIO.fired(); 

    // Mask off GPIO 0 and 1 (handled by direct IRQs)
    atomic DetectReg = (GEDR0 & ~((1<<1) | (1<<0))); 

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal HplPXA27xGPIOPin.interruptGPIOPin[pin]();
      DetectReg &= ~(1 << pin);
    }

    atomic DetectReg = GEDR1;

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal HplPXA27xGPIOPin.interruptGPIOPin[(pin+32)]();
      DetectReg &= ~(1 << pin);
    }

    atomic DetectReg = GEDR2;

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal HplPXA27xGPIOPin.interruptGPIOPin[(pin+64)]();
      DetectReg &= ~(1 << pin);
    }

    atomic DetectReg = GEDR3;

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal HplPXA27xGPIOPin.interruptGPIOPin[(pin+96)]();
      DetectReg &= ~(1 << pin);
    }

    return;
  }

  async event void GPIOIrq0.fired()
  {
    signal HplPXA27xGPIOPin.interruptGPIOPin[0]();
  }

  async event void GPIOIrq1.fired() 
  {
    signal HplPXA27xGPIOPin.interruptGPIOPin[1]();
  } 

}
